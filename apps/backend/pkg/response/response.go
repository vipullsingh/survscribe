// Package response implements the ADR-0004 JSON envelopes.
//
// Every endpoint answers with exactly one of these shapes. Handlers never write a bare
// object: a client that has to guess whether the body is the payload or a wrapper around
// it cannot be written once and trusted, and the React Native client parses these
// envelopes generically before any endpoint-specific code runs.
package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Code is a stable, machine-readable error code. Clients branch on this, never on
// Message, which is prose and may be reworded or localised at any time.
type Code string

const (
	CodeValidationFailed        Code = "VALIDATION_FAILED"
	CodeUnauthenticated         Code = "UNAUTHENTICATED"
	CodeTokenExpired            Code = "TOKEN_EXPIRED"
	CodeTokenReuseDetected      Code = "TOKEN_REUSE_DETECTED"
	CodePermissionDenied        Code = "PERMISSION_DENIED"
	CodeStoreScopeViolation     Code = "STORE_SCOPE_VIOLATION"
	CodeClaimGrantRequired      Code = "CLAIM_GRANT_REQUIRED"
	CodeNotFound                Code = "NOT_FOUND"
	CodeConflict                Code = "CONFLICT"
	CodeSyncConflict            Code = "SYNC_CONFLICT"
	CodeStagePrecondition       Code = "STAGE_PRECONDITION_FAILED"
	CodeApprovalGateNotMet      Code = "APPROVAL_GATE_NOT_SATISFIED"
	CodeAuditGateFailed         Code = "AUDIT_GATE_FAILED"
	CodeDeductionRemarkRequired Code = "DEDUCTION_REMARK_REQUIRED"
	CodeGPSAccuracyRejected     Code = "GPS_ACCURACY_REJECTED"
	CodeAccountLocked           Code = "ACCOUNT_LOCKED"
	CodeOTPInvalid              Code = "OTP_INVALID"
	CodeOTPExpired              Code = "OTP_EXPIRED"
	CodeRateLimited             Code = "RATE_LIMITED"
	CodeOfflineGraceExpired     Code = "OFFLINE_GRACE_EXPIRED"
	CodePayloadTooLarge         Code = "PAYLOAD_TOO_LARGE"
	CodeInternalError           Code = "INTERNAL_ERROR"
)

// Meta carries pagination for list endpoints (ADR-0004 section 2).
type Meta struct {
	Page  int `json:"page"`
	Limit int `json:"limit"`
	Total int `json:"total"`
}

// Detail is one field-level validation failure.
type Detail struct {
	Field string `json:"field"`
	Issue string `json:"issue"`
}

// Error is the error object inside a failure envelope.
type Error struct {
	Code    Code     `json:"code"`
	Message string   `json:"message"`
	Details []Detail `json:"details,omitempty"`
}

// Envelope is the single response shape for the whole API.
//
// Data, Error and Meta are all rendered even when null, because a client that can rely
// on the keys always being present needs no defensive checks.
type Envelope struct {
	Success bool  `json:"success"`
	Data    any   `json:"data"`
	Error   *Error `json:"error"`
	Meta    *Meta `json:"meta"`
}

// OK writes a success envelope with no pagination.
func OK(c *gin.Context, status int, data any) {
	c.JSON(status, Envelope{Success: true, Data: data, Error: nil, Meta: nil})
}

// List writes a success envelope carrying pagination metadata.
func List(c *gin.Context, data any, meta Meta) {
	c.JSON(http.StatusOK, Envelope{Success: true, Data: data, Error: nil, Meta: &meta})
}

// NoContent ends a request that has nothing to return.
func NoContent(c *gin.Context) { c.Status(http.StatusNoContent) }

// Fail writes an error envelope and aborts the handler chain.
//
// It aborts rather than returning so that a handler which forgets its own `return` after
// calling Fail cannot go on to write a second body.
func Fail(c *gin.Context, status int, code Code, message string, details ...Detail) {
	c.AbortWithStatusJSON(status, Envelope{
		Success: false,
		Data:    nil,
		Error:   &Error{Code: code, Message: message, Details: details},
		Meta:    nil,
	})
}

// Common failures, named so handlers do not re-derive the status/code pairing.

func Unauthenticated(c *gin.Context, message string) {
	Fail(c, http.StatusUnauthorized, CodeUnauthenticated, message)
}

func Forbidden(c *gin.Context, code Code, message string) {
	Fail(c, http.StatusForbidden, code, message)
}

func NotFound(c *gin.Context, message string) {
	Fail(c, http.StatusNotFound, CodeNotFound, message)
}

func Conflict(c *gin.Context, code Code, message string) {
	Fail(c, http.StatusConflict, code, message)
}

func ValidationFailed(c *gin.Context, message string, details ...Detail) {
	Fail(c, http.StatusUnprocessableEntity, CodeValidationFailed, message, details...)
}

// InternalError reports a server fault.
//
// The message is fixed and carries no detail on purpose: an internal error string can
// contain a query fragment, a file path or a column value, and this API handles insurance
// claim data. The real error goes to the structured log under the request ID, which is
// returned in the X-Request-ID header so a support engineer can find it.
func InternalError(c *gin.Context) {
	Fail(c, http.StatusInternalServerError, CodeInternalError,
		"An unexpected error occurred. Quote the X-Request-ID header when reporting this.")
}
