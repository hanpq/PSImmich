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

## Deprecated route replacement map (3.3.6)

Replacements were found by matching request-body properties and sibling paths
in `api.3.3.6.json`. Descriptions in the spec do not name replacements. Each
row is a **candidate** until its DTO delta is checked and a test covers it.

| Deprecated route | Candidate replacement | Evidence | Source usage | Status |
| --- | --- | --- | --- | --- |
| `POST /people/{id}/merge` | `POST /people/merge` | Body `ids`, bulk form | Merge-IMPerson | Migrated (`9257eae`) |
| `PUT /people/{id}` | `PUT /people` (`PeopleUpdateDto`) | Bulk form with required item `id` | Not called (Set-IMPerson already uses `PUT /people`) | No source change needed |
| `POST /partners/{id}` | `POST /partners` (`PartnerCreateDto.sharedWithId`) | Sibling path | Not called (Add-IMPartner uses `POST /partners`) | No source change needed |
| `PUT /tags/{id}` | `PUT /tags` (`TagUpsertDto`) | Bulk form | Set-IMTag, Set-IMAsset | Verify DTO, then migrate |
| `GET /system-config`, `PUT /system-config`, `GET /system-config/defaults` | `GET /admin/config`, `PUT /admin/config`, `GET /admin/config/defaults` | 22 identical body properties | Get-IMServer, Set-IMServer | Strong match. Verify response DTO, then migrate |
| `GET /server/config` | Split: `GET /public/config` (`loginPageMessage`, `oauth`), `GET /config` (`machineLearning.facialRecognition.minFaces`), `GET /admin/config` | No single DTO | Get-IMServer | Design decision needed (see below) |
| `GET /jobs`, `PUT /jobs/{name}` | `GET /queues`, `PUT /queues/{name}` | `QueueResponseDto`, `QueueUpdateDto` (`isPaused` only) | Get-IMJob, Start/Suspend/Resume/Clear-IMJob | Partial. `start`/`stop`/`force` commands have no verified field mapping (see below) |
| `POST /search/large-assets` | None confirmed (`POST /search/metadata` is a body-match candidate only) | No size-sort field verified | Get-IMTopLargestAsset | Decision needed (see below) |
| `GET /server/features` | None found | `ServerFeaturesDto` is served only by this route | Get-IMServer | Retain with reason unless maintainer decides otherwise |

Routes with **no replacement found** by body or sibling matching. Under the
deprecation policy these are **retained** while they remain in the spec:

- `PUT /admin/users/{id}` (`updateUserAdmin`; verified in the spec as this same
  operation, so it has no separate successor. Set-IMUser is retained; the
  maintainer still needs to confirm this)
- `PUT /admin/users/{id}/preferences`
- `PUT /api-keys/{id}` (Rename-IMAPIKey)
- `PUT /assets`, `PUT /assets/{id}` (Set-IMAsset, Copy-IMAssetInfo)
- `PUT /libraries/{id}` (Set-IMLibrary)
- `PUT /memories/{id}` (Set-IMMemory)
- `PUT /stacks/{id}` (Set-IMStack)
- `PUT /workflows/{id}` (Set-IMWorkflow)
- `PUT /sessions/{id}` (not called by source)
- `PUT /users/me`, `PUT /users/me/preferences` (not called by source)

Their create (`POST`) counterparts are close matches, but no PUT replacement
exists in the spec. The analyzer's `REMOVE` label is not an instruction to delete.
Policy: deprecated routes stay in use while present in the spec. The Immich app
itself still uses deprecated routes, so deprecation alone is not a removal reason.

### Maintainer decisions

1. Retain all no-replacement routes above while they remain in the spec.
   Open: confirm the `PUT /admin/users/{id}` treatment.
2. `Get-IMServer` config split: separate parameter sets per endpoint
   (`/public/config`, `/config`, `/admin/config`).
3. `Get-IMJob` start/stop/force: map to `/queues` (`queues-only`).
4. `Get-IMTopLargestAsset`: the maintainer chose removal in an earlier answer.
   Under the new policy this route is still in the spec, so confirm before deleting.

## Reconciliation of the 279 target operations

| Bucket | Count | Source |
| --- | ---: | --- |
| Covered by the analyzer (not verified) | 140 | Analyzer summary |
| Excluded (`exclusions.json`) | 63 | Includes 4 stale entries |
| Work items (18 REMOVE, 58 IMPLEMENT) | 76 | Analyzer |
| Total | 279 | 140 + 63 + 76 |

The analyzer's counts are not parity evidence. The per-operation ledger
(one status per row) is **not yet written**. Until it is, the upgrade is not
complete under section 4 of the upgrade skill.

## Route coverage baseline (generated internal layer)

Measured with `.\tools\Get-ImmichApiCoverage.ps1` against `api.3.3.6.json`:

| Status | Count |
| --- | ---: |
| Excluded (`exclusions.json`, method and path) | 59 |
| Tested (generated function named under `tests/Unit`) | 2 |
| Reachable (generated function used by module source) | 4 |
| Unreachable | 214 |
| Total | 279 |

Wired for 6 of 220 non-excluded operations (2.7%). This is a route metric, not
parameter or contract parity. The 214 unreachable operations are the backlog.
The largest unreachable domains are admin (30), assets (19), server (14), people
(12) and albums (12). 20 unreachable operations are deprecated; each needs the
replacement-or-retain decision under the maintainer policy before implementation.

## Next handoff

Continue on branch `upgrade/immich-3.3.6`. Committed batches:

- `f1ad1fe fix(server): read theme from the public config endpoint`. `GET /server/theme` was removed. `Get-IMServer -Theme` now calls `GET /public/config` and returns `.theme`, whose `customCss` matches the old `ServerThemeDto`.
- `9257eae fix(person): migrate person merging to the bulk endpoint`. `POST /people/{id}/merge` is deprecated. `Merge-IMPerson` now calls `POST /people/merge` with `ids` ordered target first.

Validation: `.\build.ps1 -Task Build` passes. `.\build.ps1 -Task Test -TestSuite Module` has 8 failing QA gates on the branch base. They are for `Clear-IMQueue`, `Get-IMQueue`, `Get-IMQueueJob`, `Set-IMQueue`, `Get-IMUserSession` and `Get-IMUserStatistics` (missing unit tests and script-analyzer results), and are not caused by these batches. All unit tests for the changed cmdlets pass.

Carried-over uncommitted worktree edits (`.github/copilot-instructions.md`, `BUILDING.md`, `.github/skills/`) were not made for this assessment and must be reviewed separately before commit. [UPGRADE-3.4.0.md](UPGRADE-3.4.0.md) is preserved as historical evidence.

Implementation batches on `upgrade/immich-3.3.6` (each validated with the module unit/QA suite;
8 baseline QA failures for Queue, UserSession and UserStatistics remain unchanged):

- `feat!` job queue batch (pending commit): `Get-IMJob` now calls `GET /queues` and returns `statistics`
  instead of `jobCounts`. `Suspend-IMJob`/`Resume-IMJob` call `PUT /queues/{name}` with `isPaused`.
  `Clear-IMJob` calls `DELETE /queues/{name}/jobs` with `failed = $false` by default (previously
  `command = empty`). `-FailedOnly` keeps deprecated `PUT /jobs/{name}` `clear-failed`, because the
  queues API cannot clear failed jobs alone. `-Force` on the three cmdlets warns and has no effect
  (no `force` in `QueueUpdateDto`/`QueueDeleteDto`). `Start-IMJob` is unchanged (no replacement).
  Validation: `.\build.ps1 -Task Test -TestSuite Module` passed (1810 passed, 0 failed, 39 skipped).
  Pre-existing, not changed: `Clear-IMQueue` sends `force` to `DELETE /queues/{name}/jobs`, which
  `QueueDeleteDto` does not define.
- `f1ad1fe` fix(server): read theme from the public config endpoint
- `9257eae` fix(person): migrate person merging to the bulk endpoint
- `7f56875` fix(api): send booleans and ISO 8601 datetimes for Immich 3.3.6
- `03ba477` test(integration): align expectations with Immich 3.3.6
- `f7810da` fix(search): page metadata and smart search and send memory dates for Immich 3.3.6

Live integration history (demo server version verified as 3.3.6, sequential runs only):

- Initial run: 181 passed, 30 failed of 229.
- After `7f56875`/`03ba477`: 14 failed.
- After `f7810da`: 11 failed of 229. All remaining failures are album-related and deferred:
  `Get-IMAlbum -IncludeAssets`/`list-id with assets`/`list-shared-false`, `Set-IMAsset` and
  `Set-IMAlbum` add/remove readbacks, `Copy-IMAssetInfo` (3 tests), and `Add-IMAlbumUser`/
  `Set-IMAlbumUser` (live shared-user state). They wait for the album-ID search filter
  (`SearchFilter` on `POST /search/smart`) and the 3.3.6 `GET /albums/{id}` change, which has no
  `withoutAssets` parameter and no `assets` property.

Verified 3.3.6 causes fixed: boolean body values were strings; datetimes lacked an offset
(HTTP 400); `nextPage` is a string but `page` must be an integer; memory `for` is date-only;
`Get-IMServer` config/features and asset single-ID properties changed.

Cleanup: during the first live run the failed `New-IMUser` test left user `test@domain.com`.
With maintainer approval it was soft-deleted (`DELETE /admin/users/{id}`, 200). It is still in
the 7-day trash; a permanent purge needs `-Force` or the server trash policy and has not been
done. Pre-existing demo data (`TestAlbum`, the other two users) was not touched.

Next actionable items, in order:

1. Deprecated-but-present reads remain: `/server/config`, `/server/features`, `/system-config`, `/system-config/defaults`, and `/jobs`. Decide whether to migrate them to `/admin/config`, `/config` or `/queues` (DTO comparison first).
2. `POST /search/large-assets` (deprecated) versus `/search/metadata` (`Get-IMTopLargestAsset`).
3. Audit schema deltas for the representative contracts listed above against `api.3.3.6.json`.
4. Repair the parameter validator path normalization before using it as a gate.

Manual PR creation, review, merge and release remain with the maintainer.
