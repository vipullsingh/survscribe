// Package logger builds the application's structured logger.
//
// Uses log/slog from the standard library rather than a third-party logger. The
// dependency is free, the output is structured, and there is nothing in this service's
// logging needs that justifies another module in the supply chain.
//
// One rule governs everything logged here: SurvScribe handles insurance claim data and
// authentication secrets. No password, refresh token, OTP code, or raw failed login
// identifier may ever reach a log line (CLAUDE.md section 14 constraint 17). Log
// identifiers and request IDs, not payloads.
package logger

import (
	"log/slog"
	"os"
	"strings"
)

// New returns a configured slog.Logger.
//
// format is "json" or "text"; level is debug, info, warn or error. An unrecognised value
// falls back to the safe end of the range rather than failing, because losing logging is
// a worse outcome than logging slightly more than intended -- config.Load has already
// rejected genuinely invalid values before this is called.
func New(level, format, version string, env string) *slog.Logger {
	var lvl slog.Level
	switch strings.ToLower(level) {
	case "debug":
		lvl = slog.LevelDebug
	case "warn":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	default:
		lvl = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{Level: lvl}

	var h slog.Handler
	if strings.ToLower(format) == "text" {
		h = slog.NewTextHandler(os.Stdout, opts)
	} else {
		h = slog.NewJSONHandler(os.Stdout, opts)
	}

	return slog.New(h).With(
		slog.String("service", "survscribe-api"),
		slog.String("version", version),
		slog.String("env", env),
	)
}
