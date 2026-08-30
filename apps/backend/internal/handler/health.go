// Package handler holds HTTP handlers. Handlers parse and validate input, delegate to a
// service, and render an envelope. They contain no business rules -- in particular no
// loss-assessment arithmetic, which lives in the deterministic engine.
package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/vipullsingh/survscribe/backend/internal/repository"
	"github.com/vipullsingh/survscribe/backend/pkg/response"
)

// Health answers GET /healthz.
type Health struct {
	db      *repository.DB
	version string
}

// NewHealth builds the health handler.
func NewHealth(db *repository.DB, version string) *Health {
	return &Health{db: db, version: version}
}

type healthStatus struct {
	Status   string `json:"status"`
	Version  string `json:"version"`
	Database string `json:"database"`
}

// Check reports process liveness and database reachability.
//
// A database that cannot be reached returns 503, not 200 with a "degraded" body: this
// endpoint is what a load balancer or orchestrator polls, and an instance that cannot
// serve a single claim request should be taken out of rotation rather than left to
// return errors. The envelope is still used, so even a failing health check parses the
// same way as every other response.
func (h *Health) Check(c *gin.Context) {
	status := healthStatus{Status: "ok", Version: h.version, Database: "up"}

	if err := h.db.Ping(c.Request.Context()); err != nil {
		status.Status = "degraded"
		status.Database = "down"
		c.JSON(http.StatusServiceUnavailable, response.Envelope{
			Success: true, Data: status, Error: nil, Meta: nil,
		})
		return
	}

	response.OK(c, http.StatusOK, status)
}
