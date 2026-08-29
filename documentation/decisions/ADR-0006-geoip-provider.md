# ADR-0006 — Geo-IP Enrichment Provider

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Context:** ADR-0005 (D42) requires signup and login IP addresses to be enriched with country, region, city, ASN, ISP and timezone on `users`, `sessions` and `auth_events`. `Requirement.MD` §4.2 requires every third-party integration to sit behind a provider-agnostic interface with its vendor chosen in its own ADR. Geo-IP had no such record.

---

## Decisions

### 1. Interface first

A `GeoIPService` interface in `apps/backend/internal/platform/geoip/`, alongside `NotificationService` and `GeocodingService` per the §4.2 policy:

```go
type GeoIPService interface {
    Lookup(ctx context.Context, ip netip.Addr) (*GeoInfo, error)
}

type GeoInfo struct {
    CountryCode string  // ISO 3166-1 alpha-2
    Region      string
    City        string
    ASN         int
    ISP         string
    Timezone    string  // IANA
}
```

The adapter is selected by environment variable, so the vendor swaps with no code change.

### 2. MVP adapter — MaxMind GeoLite2, local database file

The `GeoLite2-City` and `GeoLite2-ASN` `.mmdb` files are bundled with the backend deployment and read in-process via `github.com/oschwald/maxminddb-golang`.

**Why a local file rather than a lookup API:**

- **No PII egress.** A hosted API would mean transmitting every user's IP address to a third party on every login — a data-protection exposure taken on for a non-essential signal.
- **No latency on the auth path.** Enrichment is a memory-mapped read of roughly 50 µs, not a network round trip that could add tens of milliseconds to every login.
- **No availability coupling.** A vendor outage cannot slow or fail authentication.
- **No per-query cost or rate limit.**

Cost: the `.mmdb` files are ~70 MB in the container image and need a periodic refresh (MaxMind publishes weekly). Staleness degrades accuracy gradually and never breaks anything, so a monthly refresh in the deployment pipeline is sufficient.

**Licensing:** GeoLite2 is free under MaxMind's EULA and requires an account for downloads. The commercial GeoIP2 databases are drop-in replacements behind the same interface should accuracy warrant it.

### 3. Enrichment is best-effort and never blocks authentication

Every geo column is nullable. A missing database file, a lookup error, a private-range or loopback address, or an unmapped IP **must** result in the event being written with geo fields NULL. Authentication succeeds or fails on credentials alone; a geo-IP failure is logged as a warning, never surfaced to the user, and never returned as an error.

### 4. Accuracy is treated as a signal, not evidence

MaxMind self-reports roughly 50–70% accuracy at city level within a 50 km radius, and materially better at country and ASN level. This data supports "this login looks unusual" prompts and forensic grouping. It is **not** evidence of a user's location and must never appear in a survey report, a claim record, or any regulatory artifact.

Note the distinction from `GeocodingService` (ADR-0002), which serves Stage 4 risk-location verification. That path uses **device GPS**, is evidentiary, and is entirely separate from this one. Geo-IP must never substitute for GPS in `site_visits`.

---

## Consequences

- `apps/backend/internal/platform/geoip/` ships with the MaxMind adapter and a no-op adapter for local development and tests, so no developer needs the database files to run the suite.
- The deployment pipeline gains a monthly `.mmdb` refresh step.
- `physical-schema.md` §6 and §10 geo columns stay nullable by contract, not by accident.
- Should data-residency requirements later forbid bundling the files, the interface allows an in-region hosted adapter without touching the auth path.
