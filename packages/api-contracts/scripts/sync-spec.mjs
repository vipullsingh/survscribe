/**
 * Copies the frozen OpenAPI document into this package so it can be resolved as
 * `@survscribe/api-contracts/openapi.yaml` by tooling that cannot reach across the
 * repository (mock servers, contract-test runners, generated clients).
 *
 * The source of truth stays in documentation/. This is a build artifact, not a second
 * copy to edit. With `--check` it fails instead of writing, which is what CI runs.
 */
import { copyFileSync, existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const src = resolve(here, "../../../documentation/architecture/api-contract/openapi.yaml");
const dest = resolve(here, "../openapi.yaml");
const check = process.argv.includes("--check");

if (!existsSync(src)) {
  console.error(`Source contract not found: ${src}`);
  process.exit(1);
}

if (check) {
  if (!existsSync(dest)) {
    console.error(
      "openapi.yaml has not been synced. Run: pnpm --filter @survscribe/api-contracts sync",
    );
    process.exit(1);
  }
  const a = readFileSync(src, "utf8").replace(/\r\n/g, "\n");
  const b = readFileSync(dest, "utf8").replace(/\r\n/g, "\n");
  if (a !== b) {
    console.error("openapi.yaml is stale. Run: pnpm --filter @survscribe/api-contracts sync");
    process.exit(1);
  }
  console.log("openapi.yaml is in sync with the contract.");
} else {
  copyFileSync(src, dest);
  console.log(`Synced ${dest}`);
}
