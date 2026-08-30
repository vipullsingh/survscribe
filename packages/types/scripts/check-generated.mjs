/**
 * Fails if src/schema.d.ts is out of date with respect to the OpenAPI contract.
 *
 * The whole point of generating types is that the client cannot believe something the
 * server does not implement. That guarantee is worth nothing if a stale schema.d.ts is
 * committed, so CI runs this and refuses a drifted tree.
 */
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { readFileSync, rmSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const pkgRoot = resolve(here, "..");

// Paths are RELATIVE and the child runs with cwd = pkgRoot. openapi-typescript's CLI
// resolves -o through `new URL(value, base)`, which rejects an absolute Windows path
// ("C:\...") outright. Relative paths work on every platform.
const SPEC = "../../documentation/architecture/api-contract/openapi.yaml";
const COMMITTED = "src/schema.d.ts";
const SCRATCH = ".schema-check.tmp.d.ts";

// Resolve the workspace's own openapi-typescript and run it with this Node binary rather
// than shelling out to npx: npx may not be on PATH in CI, resolves differently under
// pnpm's nested store, and would happily fetch a DIFFERENT version from the registry --
// which would mean comparing the committed types against the wrong generator.
const require = createRequire(import.meta.url);
const cli = require.resolve("openapi-typescript/bin/cli.js");

const scratchPath = resolve(pkgRoot, SCRATCH);

try {
  execFileSync(process.execPath, [cli, SPEC, "-o", SCRATCH], {
    cwd: pkgRoot,
    stdio: "pipe",
  });

  const committed = readFileSync(resolve(pkgRoot, COMMITTED), "utf8").replace(/\r\n/g, "\n");
  const fresh = readFileSync(scratchPath, "utf8").replace(/\r\n/g, "\n");

  if (committed !== fresh) {
    console.error(
      "\nsrc/schema.d.ts is stale.\n\n" +
        "The committed types no longer match " +
        "documentation/architecture/api-contract/openapi.yaml.\n" +
        "Run:  pnpm --filter @survscribe/types generate\n" +
        "and commit the result.\n",
    );
    process.exit(1);
  }

  console.error("schema.d.ts is up to date with the OpenAPI contract.");
} finally {
  rmSync(scratchPath, { force: true });
}
