# Immich 3.3.6 upgrade assessment

## Status and inputs

Assessment date: 2026-11-06. **Assessment only; no API implementation, commits
or release metadata changes were made.** The 3.4.0 release candidate assessment
is preserved in [UPGRADE-3.4.0.md](UPGRADE-3.4.0.md) as historical evidence.

Follow the [repeatable upgrade workflow](../.github/skills/upgrade-immich/SKILL.md)
when continuing this work.

| Input | Evidence |
| --- | --- |
| Baseline | Tracked module `2.3.1` ([version.txt](../version.txt), [release manifest](../.release-please-manifest.json)); comparison baseline [api.2.3.1.json](api.2.3.1.json); Git commit `ee943e98cb172732e1bcba8137f749d218049a40` (`main`) |
| Branch | `upgrade/immich-3.3.6` (renamed from `upgrade/immich-3.4.0`, which had no commits beyond `main`) |
| Target | Immich `v3.3.6`, the latest stable release per the [releases API](https://github.com/immich-app/immich/releases/tag/v3.3.6); tag resolves to commit `587f549f46f1cd1822a06e16dcccecef04ea4565`; embedded `info.version` = `3.3.6` |
| Spec provenance | `https://raw.githubusercontent.com/immich-app/immich/587f549f46f1cd1822a06e16dcccecef04ea4565/open-api/immich-openapi-specs.json`; local [api.3.3.6.json](api.3.3.6.json) SHA256 `B7F2A9C2543472A9B3A2F32ECE82F56CB4B5660D6745D05F2D7903DFB5BA974B` (byte-identical to the downloaded file) |
| Scope | Assessment only. Existing exclusions retained (user decision). |
| Compatibility | Target `3.3.6` only (user decision). Breaking changes will be documented. |
| Validation | See [Executed checks](#executed-checks-and-results) |

The release version and API version are not interchangeable. The module is
still `2.3.1`; any move to a 3.x module version is a maintainer release decision
made through Release Please and is not part of this assessment.

## Measured inventory

Counts were computed from the independent JSON inventory (valid HTTP methods
under `paths`, keyed `METHOD /path`) and [exclusions.json](exclusions.json).

| Measurement | Count | Interpretation |
| --- | ---: | --- |
| Baseline method/path operations (2.3.1) | 225 | Independent JSON inventory |
| Target method/path operations (3.3.6) | 279 | Independent JSON inventory |
| Raw added operations | 61 | Relative to baseline |
| Physically removed operations | 7 | Separate from deprecation |
| Newly deprecated common operations | 23 | Still present in target |
| Declared exclusions | 63 | Existing scope policy |
| Exclusions present in target | 59 | Four stale entries: `POST /download/asset/{id}`, `POST /assets/exist`, `POST /sync/delta-sync`, `POST /sync/full-sync` (the last three are also removed) |
| Target operations after exclusions | 220 | `279 - 59` |
| Deprecated target operations after exclusions | 20 | Migration candidates, not automatic deletions |
| Nondeprecated target operations after exclusions | 200 | Candidate parity denominator |
| Analyzer "missing" candidates | 60 | Require call-site and behavior verification |
| Analyzer "deprecated but implemented" | 19 | Migration candidates |
| Verified behavioral parity | Not measured | No unit or live verification performed |

The analyzer's printed "covered" count is not a parity numerator; it subtracts
exclusions and work items without verifying DTOs or behavior.

The comparison tool's exclusion-aware console summary reported **61 added /
23 removed / 29 modified**. Its "removed" bucket includes newly deprecated
operations, so it does not match the 7 physical removals above. Do not mix
these classifications.

## Confirmed source defect

| Source | Target change | Required action |
| --- | --- | --- |
| [Get-IMServer.ps1](../source/public/Server/Get-IMServer.ps1) line 205 calls `GET /server/theme` | Route physically removed in 3.3.6 | Confirmed breakage. Replacement must be determined from the target configuration/feature DTOs and release notes; do not assume a one-to-one mapping. |

## Physically removed routes

| Route | Source usage | Status |
| --- | --- | --- |
| `GET /assets/device/{deviceId}` | None found | No source defect found |
| `GET /assets/random` | None found | No source defect found; `RandomSearchDto` still changes (see below) |
| `GET /server/theme` | [Get-IMServer.ps1](../source/public/Server/Get-IMServer.ps1):205 | **Broken** |
| `PUT /assets/{id}/original` | None found (`GET /assets/{id}/original` in [Save-IMAsset.ps1](../source/public/Asset/Save-IMAsset.ps1):73 is a different, still-present method) | No source defect found |
| `POST /assets/exist` | Excluded (stale) | Exclusion no longer matches; still no implementation |
| `POST /sync/delta-sync`, `POST /sync/full-sync` | Excluded (stale) | Exclusion no longer matches |

Source-call inventory was a targeted grep for these routes. It has not been
exhaustively reconciled against every REST call in `source/`.

## Deprecated routes still implemented (analyzer)

| Route | Reported cmdlets | Assessment |
| --- | --- | --- |
| `PUT /admin/users/{id}` | Set-IMUser, Set-IMUserPreference | Review replacement and DTO |
| `PUT /admin/users/{id}/preferences` | Set-IMUserPreference | Review replacement |
| `PUT /api-keys/{id}` | Rename-IMAPIKey | Review replacement |
| `PUT /assets` | Set-IMAsset | Review bulk replacement |
| `PUT /assets/{id}` | Copy-IMAssetInfo, Set-IMAsset | Review replacement |
| `GET /jobs`, `PUT /jobs/{name}` | Get-IMJob, Clear-IMJob, Resume-IMJob, Start-IMJob, Suspend-IMJob | Reconcile with queue routes; preserve UX |
| `PUT /libraries/{id}` | Set-IMLibrary | Review replacement |
| `PUT /memories/{id}` | Set-IMMemory | Review replacement; `MemoryCreateDto` also changes |
| `POST /people/{id}/merge` | Merge-IMPerson | Migrate to `POST /people/merge`; verify DTO and semantics |
| `POST /search/large-assets` | Get-IMTopLargestAsset | Review `/search/metadata` ordering/paging |
| `GET /server/config`, `GET /server/features` | Get-IMServer | Compare DTO representations |
| `GET /system-config`, `PUT /system-config`, `GET /system-config/defaults` | Get-IMServer, Set-IMServer | Compare `/admin/config` and defaults DTOs |
| `PUT /stacks/{id}` | Set-IMStack | Review replacement |
| `PUT /tags/{id}` | Set-IMAsset, Set-IMTag | Review replacement |
| `PUT /workflows/{id}` | Set-IMWorkflow | Review replacement |

## Missing-operation candidates (analyzer, after exclusions)

These 60 rows are static-scan candidates. Each needs a cmdlet/parameter-set
mapping, DTO review and test evidence.

| Domain | Method path |
| --- | --- |
| Albums | `GET /albums/{id}/map-markers` |
| API keys | `POST /api-keys/{id}/rotate` |
| Asset files | `GET /asset-files`; `DELETE /asset-files/{id}`; `GET /asset-files/{id}`; `GET /asset-files/{id}/download` |
| Assets | `DELETE /assets/{id}/edits`; `GET /assets/{id}/edits`; `PUT /assets/{id}/edits`; `DELETE /assets/{id}/video/stream/{sessionId}`; `GET /assets/{id}/video/stream/{sessionId}/{variantIndex}/{filename}`; `GET /assets/{id}/video/stream/{sessionId}/{variantIndex}/playlist.m3u8`; `GET /assets/{id}/video/stream/main.m3u8`; `PUT /assets/metadata`; `DELETE /assets/metadata` |
| Authentication | `POST /oauth/backchannel-logout` |
| Cluster groups | `POST /cluster-groups/{id}/leave`; `POST /cluster-groups/{id}/regenerate-people`; `GET /cluster-groups/{id}/requests`; `PUT /cluster-groups/{id}/requests`; `GET /cluster-groups/{id}/users`; `GET /cluster-groups/requests`; `DELETE /cluster-groups/requests/{id}`; `POST /cluster-groups/requests/{id}/accept` |
| Config (admin) | `GET /admin/config`; `PUT /admin/config`; `GET /admin/config/defaults` |
| Config (public) | `GET /public/config`; `GET /public/config/defaults` |
| Config (user) | `GET /config`; `GET /config/defaults` |
| Database backups (admin) | `GET /admin/database-backups`; `DELETE /admin/database-backups`; `GET /admin/database-backups/{filename}`; `POST /admin/database-backups/start-restore`; `POST /admin/database-backups/upload` |
| Duplicates | `POST /duplicates/resolve` |
| Maintenance (admin) | `GET /admin/integrity/report`; `DELETE /admin/integrity/report/{id}`; `GET /admin/integrity/report/{id}/file`; `GET /admin/integrity/report/{type}/csv`; `GET /admin/integrity/summary`; `GET /admin/maintenance/detect-install`; `GET /admin/maintenance/status` |
| Notifications (admin) | `POST /admin/notifications`; `POST /admin/notifications/templates/{name}` |
| People | `POST /people/merge`; `GET /people/users`; `PUT /people/users`; `DELETE /people/users` |
| Plugins | `GET /plugins/methods`; `GET /plugins/templates` |
| Shared links | `POST /shared-links/login` |
| Users | `GET /users/me/calendar-heatmap` |
| Users (admin) | `GET /admin/users/{id}/calendar-heatmap` |
| Views | `GET /view/folder`; `GET /view/folder/unique-paths` |
| Workflows | `GET /workflows/{id}/logs`; `GET /workflows/{id}/share`; `GET /workflows/triggers` |

## Representative contract changes (not exhaustive)

Schema deltas were **not** audited for 3.3.6 in this pass. The following come
from the 3.4.0 RC review and must be re-verified against `api.3.3.6.json`
before any implementation:

- `MetadataSearchDto`, `SmartSearchDto`, `RandomSearchDto`: filter, paging and
  removed device fields.
- `AssetResponseDto`: removed `deviceAssetId`, `deviceId`, `unassignedFaces`.
- `PersonUpdateDto`, `PersonResponseDto`: user-related fields.
- `Permission`: API-key permission changes, including removal of `asset.replace`.

The 3.3.6 spec must be compared independently; RC-specific deltas were not
assumed to apply.

## Blockers and decisions for implementation

1. **Exclusions:** the 59 present exclusions are kept per user decision. Four
   entries are stale and should be removed in the implementation batch that
   touches them. Reassess whether `/sync/*`, streaming and backchannel routes
   remain intentionally excluded.
2. **Compatibility:** target 3.3.6 only. Older-server handling is out of scope.
3. **Analysis tooling:** `api/Analyze-PSImmichAPI.ps1` selects the most recently
   modified `api.*.json`; this run used `api.3.3.6.json` because it is the newest
   file written. `tools/Validate-ApiParameters.ps1` cannot match paths (see
   below), so the parameter contract must be checked manually.
4. **Live validation:** requires an authorized disposable 3.3.6 instance.

## Executed checks and results

| Check | Command or request | Result |
| --- | --- | --- |
| Release verification | `GET /repos/immich-app/immich/releases/tags/v3.3.6` and `GET /repos/immich-app/immich/git/refs/tags/v3.3.6` | Release exists; tag resolves to `587f549f46f1cd1822a06e16dcccecef04ea4565` |
| Spec download | `Invoke-WebRequest` to scratch directory `%TEMP%\psimmich-3.3.6\upstream-3.3.6.json` | Parsed `info.version` = `3.3.6`; 193 path items |
| Spec copy | `Copy-Item` of verified download to `api\api.3.3.6.json` | SHA256 matches download |
| Spec comparison | `.\api\Compare-OpenApiSpecs.ps1 -OldSpecPath .\api\api.2.3.1.json -NewSpecPath .\api\api.3.3.6.json -ExclusionsPath .\api\exclusions.json -OutputPath <scratch>\compare.md` | Completed; console summary 61 added / 23 removed / 29 modified (removed includes deprecations; not the raw inventory) |
| Operation inventory | PowerShell JSON traversal (see Measured inventory) | 225 baseline, 279 target, 59 exclusions present |
| Source discovery | `.\api\Analyze-PSImmichAPI.ps1` | Selected `api.3.3.6.json`; 19 deprecated-implemented, 60 missing candidates |
| Parameter preflight | `tools\Validate-ApiParameters.ps1 -Path <source\public> -OpenApiSpec <api.3.3.6.json>` from scratch directory | Exit 1; **0 matched operations** for every checked attribute; inconclusive because slashless source paths are not normalized to OpenAPI paths |
| Source route grep | Targeted `grep` for removed routes | Only `GET /server/theme` (Get-IMServer.ps1:205) is used by source |
| Documentation whitespace | `git --no-pager diff --check` on tracked changes; trailing-whitespace scan on new file | Tracked diff check passed (exit 0); new-file scan run as recorded in the handoff |
| Build, unit, QA, infrastructure, integration | Not run | Assessment-only scope; no behavioral verification claimed |

## Next handoff

Continue on branch `upgrade/immich-3.3.6`. Committed batches:

- `f1ad1fe fix(server): read theme from the public config endpoint`. `GET /server/theme` was removed. `Get-IMServer -Theme` now calls `GET /public/config` and returns `.theme`, whose `customCss` matches the old `ServerThemeDto`.
- `9257eae fix(person): migrate person merging to the bulk endpoint`. `POST /people/{id}/merge` is deprecated. `Merge-IMPerson` now calls `POST /people/merge` with `ids` ordered target first.

Validation: `.\build.ps1 -Task Build` passes. `.\build.ps1 -Task Test -TestSuite Module` has 8 failing QA gates on the branch base. They are for `Clear-IMQueue`, `Get-IMQueue`, `Get-IMQueueJob`, `Set-IMQueue`, `Get-IMUserSession` and `Get-IMUserStatistics` (missing unit tests and script-analyzer results), and are not caused by these batches. All unit tests for the changed cmdlets pass.

Carried-over uncommitted worktree edits (`.github/copilot-instructions.md`, `BUILDING.md`, `.github/skills/`) were not made for this assessment and must be reviewed separately before commit. [UPGRADE-3.4.0.md](UPGRADE-3.4.0.md) is preserved as historical evidence.

Next actionable items, in order:

1. Deprecated-but-present reads remain: `/server/config`, `/server/features`, `/system-config`, `/system-config/defaults`, and `/jobs`. Decide whether to migrate them to `/admin/config`, `/config` or `/queues` (DTO comparison first).
2. `POST /search/large-assets` (deprecated) versus `/search/metadata` (`Get-IMTopLargestAsset`).
3. Audit schema deltas for the representative contracts listed above against `api.3.3.6.json`.
4. Repair the parameter validator path normalization before using it as a gate.

Manual PR creation, review, merge and release remain with the maintainer.
