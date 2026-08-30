// Package repository owns database access.
//
// Every method that reads or writes an operational table takes store_id as its first
// scope argument, taken from the verified JWT and never from request input
// (identity-and-rbac.md section 3.2, CLAUDE.md section 14 constraint 11). That rule is
// enforced by convention at this layer and is the reason store_id is denormalised onto
// every workflow table: no repository method should need a join to establish scope.
package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/vipullsingh/survscribe/backend/internal/config"
)

// DB wraps the pgx connection pool.
type DB struct {
	Pool *pgxpool.Pool
}

// Connect opens the pool and verifies the database is actually reachable.
//
// pgxpool.New is lazy -- it does not connect until first use -- so a bad DATABASE_URL
// would otherwise surface as a failed request rather than a failed startup. The explicit
// Ping makes the process fail at boot, which is where a configuration error belongs.
func Connect(ctx context.Context, cfg *config.Config) (*DB, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		// Deliberately not wrapping the URL into the message: it carries the password.
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}

	poolCfg.MaxConns = cfg.DBMaxConns
	poolCfg.MinConns = cfg.DBMinConns
	poolCfg.HealthCheckPeriod = cfg.DBHealthCheckPeriod
	poolCfg.ConnConfig.ConnectTimeout = cfg.DBConnectTimeout

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("create connection pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, cfg.DBConnectTimeout)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}

	return &DB{Pool: pool}, nil
}

// Ping reports whether the database is currently reachable.
func (db *DB) Ping(ctx context.Context) error {
	if db == nil || db.Pool == nil {
		return config.ErrNotConfigured
	}
	return db.Pool.Ping(ctx)
}

// Close releases the pool.
func (db *DB) Close() {
	if db != nil && db.Pool != nil {
		db.Pool.Close()
	}
}
