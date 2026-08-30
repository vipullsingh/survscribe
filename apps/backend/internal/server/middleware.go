package server

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/vipullsingh/survscribe/backend/pkg/response"
)

// Context keys. Typed constants rather than bare strings so a typo is a compile error.
const (
	ctxRequestID = "survscribe.request_id"
	ctxRealIP    = "survscribe.real_ip"
)

// RequestID assigns every request a correlation ID and echoes it in X-Request-ID.
//
// This is the identifier that ties an HTTP request to its structured log lines and to
// audit_log.request_id, so a disputed change to a loss figure can be traced back to the
// call that made it. An inbound X-Request-ID is honoured only in non-production: it lets
// a developer correlate across the mobile client and the API, but accepting a
// client-supplied ID in production would let a caller collide or forge trace identifiers.
func RequestID(trustInbound bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := ""
		if trustInbound {
			id = c.GetHeader("X-Request-ID")
		}
		if id == "" || len(id) > 64 {
			id = uuid.NewString()
		}
		c.Set(ctxRequestID, id)
		c.Header("X-Request-ID", id)
		c.Next()
	}
}

// RealIP records the client address for auth telemetry and geo-IP enrichment.
//
// It uses Gin's ClientIP, which honours X-Forwarded-For only for proxies the engine has
// been told to trust. Reading the header unconditionally would let any caller spoof the
// IP written into auth_events and audit_log, which are the tables an investigation
// relies on.
func RealIP() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set(ctxRealIP, c.ClientIP())
		c.Next()
	}
}

// RequestIDOf returns the correlation ID assigned to this request.
func RequestIDOf(c *gin.Context) string {
	if v, ok := c.Get(ctxRequestID); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// RealIPOf returns the resolved client IP.
func RealIPOf(c *gin.Context) string {
	if v, ok := c.Get(ctxRealIP); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// AccessLog emits one structured line per request.
//
// It logs the route template (c.FullPath()) rather than the raw URL. A raw path contains
// claim and document UUIDs, and this service's logs should not become a secondary,
// unaudited index of which claims were accessed -- that record belongs in audit_log,
// where SRS section 5.1 rule 3 requires it and where it is immutable.
func AccessLog(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		route := c.FullPath()
		if route == "" {
			route = "unmatched"
		}

		attrs := []any{
			slog.String("request_id", RequestIDOf(c)),
			slog.String("method", c.Request.Method),
			slog.String("route", route),
			slog.Int("status", c.Writer.Status()),
			slog.Duration("duration", time.Since(start)),
			slog.String("ip", RealIPOf(c)),
		}

		switch {
		case c.Writer.Status() >= 500:
			log.Error("request failed", attrs...)
		case c.Writer.Status() >= 400:
			log.Warn("request rejected", attrs...)
		default:
			log.Info("request", attrs...)
		}
	}
}

// Recovery converts a panic into a 500 error envelope.
//
// The panic value and stack go to the log under the request ID; the client gets the
// fixed INTERNAL_ERROR message with no detail. A stack trace in a response body would
// leak file paths and, in this domain, potentially claim data.
func Recovery(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				log.Error("panic recovered",
					slog.String("request_id", RequestIDOf(c)),
					slog.String("route", c.FullPath()),
					slog.Any("panic", r),
				)
				if !c.Writer.Written() {
					response.InternalError(c)
				} else {
					c.Abort()
				}
			}
		}()
		c.Next()
	}
}

// NotFound answers unmatched routes with the standard error envelope.
//
// Without it Gin returns a bare "404 page not found" text body, which breaks the
// invariant that every response the client sees is an envelope.
func NotFound() gin.HandlerFunc {
	return func(c *gin.Context) {
		response.Fail(c, http.StatusNotFound, response.CodeNotFound, "No such endpoint.")
	}
}

// MethodNotAllowed answers a known path with an unsupported method.
func MethodNotAllowed() gin.HandlerFunc {
	return func(c *gin.Context) {
		response.Fail(c, http.StatusMethodNotAllowed, response.CodeNotFound,
			"That method is not supported on this endpoint.")
	}
}
