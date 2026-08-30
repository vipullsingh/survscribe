// Package config loads runtime configuration from the environment.
//
// Every value is read once at startup and validated there, so a misconfigured process
// fails immediately and loudly rather than at the first request that happens to need the
// missing setting. Nothing here has a production-shaped default: an absent DATABASE_URL
// is an error, never a silent fallback to localhost.
package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Environment names the deployment context. It gates behaviour that must never be
// enabled outside development, such as verbose error bodies.
type Environment string

const (
	EnvDevelopment Environment = "development"
	EnvTest        Environment = "test"
	EnvStaging     Environment = "staging"
	EnvProduction  Environment = "production"
)

// Config is the fully resolved application configuration.
type Config struct {
	Env             Environment
	HTTPAddr        string
	ShutdownTimeout time.Duration

	DatabaseURL         string
	DBMaxConns          int32
	DBMinConns          int32
	DBConnectTimeout    time.Duration
	DBHealthCheckPeriod time.Duration

	LogLevel  string
	LogFormat string // "json" or "text"

	Version string
}

// Load reads configuration from the environment and validates it.
//
// It deliberately returns every problem it finds rather than the first, so a developer
// setting up the project sees the whole list once instead of playing whack-a-mole.
func Load() (*Config, error) {
	var problems []string

	cfg := &Config{
		Env:                 Environment(getenv("SURVSCRIBE_ENV", string(EnvDevelopment))),
		HTTPAddr:            getenv("HTTP_ADDR", ":8080"),
		ShutdownTimeout:     getdur("SHUTDOWN_TIMEOUT", 15*time.Second, &problems),
		DatabaseURL:         os.Getenv("DATABASE_URL"),
		DBMaxConns:          int32(getint("DB_MAX_CONNS", 20, &problems)),
		DBMinConns:          int32(getint("DB_MIN_CONNS", 2, &problems)),
		DBConnectTimeout:    getdur("DB_CONNECT_TIMEOUT", 10*time.Second, &problems),
		DBHealthCheckPeriod: getdur("DB_HEALTHCHECK_PERIOD", 30*time.Second, &problems),
		LogLevel:            strings.ToLower(getenv("LOG_LEVEL", "info")),
		LogFormat:           strings.ToLower(getenv("LOG_FORMAT", "json")),
		Version:             getenv("APP_VERSION", "0.1.0-dev"),
	}

	switch cfg.Env {
	case EnvDevelopment, EnvTest, EnvStaging, EnvProduction:
	default:
		problems = append(problems, fmt.Sprintf(
			"SURVSCRIBE_ENV %q is not one of development, test, staging, production", cfg.Env))
	}

	if cfg.DatabaseURL == "" && cfg.Env != EnvDevelopment && cfg.Env != EnvTest {
		problems = append(problems, "DATABASE_URL is required (see .env.example)")
	}

	if cfg.DBMinConns > cfg.DBMaxConns {
		problems = append(problems, fmt.Sprintf(
			"DB_MIN_CONNS (%d) exceeds DB_MAX_CONNS (%d)", cfg.DBMinConns, cfg.DBMaxConns))
	}

	switch cfg.LogFormat {
	case "json", "text":
	default:
		problems = append(problems, fmt.Sprintf("LOG_FORMAT %q must be json or text", cfg.LogFormat))
	}

	switch cfg.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		problems = append(problems, fmt.Sprintf(
			"LOG_LEVEL %q must be debug, info, warn or error", cfg.LogLevel))
	}

	if len(problems) > 0 {
		return nil, fmt.Errorf("invalid configuration:\n  - %s", strings.Join(problems, "\n  - "))
	}
	return cfg, nil
}

// IsProduction reports whether verbose diagnostics must be suppressed.
func (c *Config) IsProduction() bool { return c.Env == EnvProduction }

func getenv(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}

func getint(key string, def int, problems *[]string) int {
	raw, ok := os.LookupEnv(key)
	if !ok || raw == "" {
		return def
	}
	n, err := strconv.Atoi(raw)
	if err != nil {
		*problems = append(*problems, fmt.Sprintf("%s %q is not an integer", key, raw))
		return def
	}
	return n
}

func getdur(key string, def time.Duration, problems *[]string) time.Duration {
	raw, ok := os.LookupEnv(key)
	if !ok || raw == "" {
		return def
	}
	d, err := time.ParseDuration(raw)
	if err != nil {
		*problems = append(*problems, fmt.Sprintf("%s %q is not a duration (e.g. 15s, 2m)", key, raw))
		return def
	}
	return d
}

// ErrNotConfigured is returned by components asked to run without their configuration.
var ErrNotConfigured = errors.New("component is not configured")
