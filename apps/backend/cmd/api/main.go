// Command api runs the SurvScribe HTTP API.
//
// It does exactly four things: load configuration, open the database, serve, and stop
// cleanly on a signal. In particular it does NOT apply migrations. Migrations are run
// deliberately by a human against a database they have named -- see
// apps/backend/migrations/README.md. A server that migrates on boot is how a schema gets
// changed by an autoscaler.
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/vipullsingh/survscribe/backend/internal/config"
	"github.com/vipullsingh/survscribe/backend/internal/repository"
	"github.com/vipullsingh/survscribe/backend/internal/server"
	"github.com/vipullsingh/survscribe/backend/pkg/logger"
)

func main() {
	if err := run(); err != nil {
		// Configuration and startup failures happen before the logger exists, so this
		// one message goes to stderr plainly.
		fmt.Fprintf(os.Stderr, "survscribe-api: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	log := logger.New(cfg.LogLevel, cfg.LogFormat, cfg.Version, string(cfg.Env))

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := repository.Connect(ctx, cfg)
	if err != nil {
		if cfg.Env == config.EnvDevelopment {
			log.Warn("database connection failed; continuing in local development offline mode", "error", err)
			db = &repository.DB{}
		} else {
			return fmt.Errorf("database: %w", err)
		}
	}
	defer db.Close()

	if db != nil && db.Pool != nil {
		log.Info("database connected",
			"max_conns", cfg.DBMaxConns,
			"min_conns", cfg.DBMinConns,
		)
	} else {
		log.Warn("running with in-memory / local standalone mode (database offline)")
	}

	return server.New(cfg, log, db).Run(ctx)
}
