// Package server wires configuration, logging, the database and the HTTP router into a
// runnable service.
package server

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/vipullsingh/survscribe/backend/internal/config"
	"github.com/vipullsingh/survscribe/backend/internal/handler"
	"github.com/vipullsingh/survscribe/backend/internal/repository"
)

// Server is the running API.
type Server struct {
	cfg  *config.Config
	log  *slog.Logger
	db   *repository.DB
	http *http.Server
}

// New builds the server and its routes.
func New(cfg *config.Config, log *slog.Logger, db *repository.DB) *Server {
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}

	// Gin's own logger writes unstructured text to stdout, which would interleave with
	// the slog JSON stream and make the logs unparseable. AccessLog replaces it.
	engine := gin.New()
	engine.RedirectTrailingSlash = false
	engine.HandleMethodNotAllowed = true

	// Order matters: RequestID first so every later line and every error envelope can be
	// correlated, Recovery before the handlers so a panic still produces an envelope.
	// Authenticate -> StoreScope -> RequirePermission join this chain in sprint_0003
	// (identity-and-rbac.md section 3).
	engine.Use(
		RequestID(!cfg.IsProduction()),
		RealIP(),
		Recovery(log),
		AccessLog(log),
	)
	engine.NoRoute(NotFound())
	engine.NoMethod(MethodNotAllowed())

	health := handler.NewHealth(db, cfg.Version)

	// /healthz sits outside /api/v1 so an orchestrator probe does not move when the API
	// version does.
	engine.GET("/healthz", health.Check)

	v1 := engine.Group("/api/v1")
	v1.GET("/healthz", health.Check)

	return &Server{
		cfg: cfg,
		log: log,
		db:  db,
		http: &http.Server{
			Addr:              cfg.HTTPAddr,
			Handler:           engine,
			ReadHeaderTimeout: 10 * time.Second,
			ReadTimeout:       60 * time.Second,
			// Generous: the FSR .docx export has a 5-second budget for 50 photo plates
			// (CR-NF5) and chunked media uploads run long on a field connection.
			WriteTimeout: 120 * time.Second,
			IdleTimeout:  120 * time.Second,
		},
	}
}

// Run serves until ctx is cancelled, then drains in-flight requests.
//
// A hard stop would abandon a chunked media upload mid-stream, and a field device on a
// poor connection may take a while to finish one.
func (s *Server) Run(ctx context.Context) error {
	errCh := make(chan error, 1)

	go func() {
		s.log.Info("http server listening", slog.String("addr", s.cfg.HTTPAddr))
		if err := s.http.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
		s.log.Info("shutdown signal received, draining",
			slog.Duration("timeout", s.cfg.ShutdownTimeout))
		shutdownCtx, cancel := context.WithTimeout(context.Background(), s.cfg.ShutdownTimeout)
		defer cancel()
		return s.http.Shutdown(shutdownCtx)
	}
}

// Handler exposes the router for tests.
func (s *Server) Handler() http.Handler { return s.http.Handler }
