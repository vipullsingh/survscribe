package server_test

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/vipullsingh/survscribe/backend/internal/config"
	"github.com/vipullsingh/survscribe/backend/internal/repository"
	"github.com/vipullsingh/survscribe/backend/internal/server"
	"github.com/vipullsingh/survscribe/backend/pkg/response"
)

// newTestServer builds a server with no database connection.
//
// That is deliberate rather than a shortcut: these tests cover routing, the response
// envelope and the degraded health path, none of which should need Postgres to run. A
// unit test suite that cannot run without a database is a suite developers skip.
func newTestServer(t *testing.T) http.Handler {
	t.Helper()
	cfg := &config.Config{
		Env:      config.EnvTest,
		HTTPAddr: ":0",
		Version:  "test",
	}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	return server.New(cfg, log, &repository.DB{}).Handler()
}

func decode(t *testing.T, rec *httptest.ResponseRecorder) response.Envelope {
	t.Helper()
	var env response.Envelope
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &env),
		"response body must be a JSON envelope, got: %s", rec.Body.String())
	return env
}

func TestHealthzReportsDegradedWithoutDatabase(t *testing.T) {
	h := newTestServer(t)

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	// An instance that cannot reach Postgres cannot serve a claim request, so it must
	// fail its probe rather than report itself healthy.
	assert.Equal(t, http.StatusServiceUnavailable, rec.Code)

	env := decode(t, rec)
	data, ok := env.Data.(map[string]any)
	require.True(t, ok, "data should be the health object")
	assert.Equal(t, "degraded", data["status"])
	assert.Equal(t, "down", data["database"])
	assert.Equal(t, "test", data["version"])
}

func TestHealthzIsAlsoMountedUnderAPIV1(t *testing.T) {
	h := newTestServer(t)

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/healthz", nil))

	assert.Equal(t, http.StatusServiceUnavailable, rec.Code)
	assert.NotEmpty(t, decode(t, rec).Data)
}

func TestEveryResponseCarriesARequestID(t *testing.T) {
	h := newTestServer(t)

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	// audit_log.request_id correlates a change to the call that made it; the header is
	// how a support engineer gets from a user report to the log line.
	assert.NotEmpty(t, rec.Header().Get("X-Request-ID"))
}

func TestUnknownRouteReturnsAnEnvelopeNotGinsPlainText(t *testing.T) {
	h := newTestServer(t)

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/no-such-thing", nil))

	assert.Equal(t, http.StatusNotFound, rec.Code)

	env := decode(t, rec)
	assert.False(t, env.Success)
	assert.Nil(t, env.Data)
	require.NotNil(t, env.Error)
	assert.Equal(t, response.CodeNotFound, env.Error.Code)
}

func TestUnsupportedMethodReturnsAnEnvelope(t *testing.T) {
	h := newTestServer(t)

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/healthz", nil))

	assert.Equal(t, http.StatusMethodNotAllowed, rec.Code)
	assert.False(t, decode(t, rec).Success)
}

func TestErrorEnvelopeRendersAllFourKeys(t *testing.T) {
	h := newTestServer(t)

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/no-such-thing", nil))

	// The client parses envelopes generically, so the keys must always be present --
	// including when their value is null. omitempty on any of them would break that.
	var raw map[string]json.RawMessage
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &raw))
	for _, key := range []string{"success", "data", "error", "meta"} {
		assert.Contains(t, raw, key, "envelope must always render %q", key)
	}
}
