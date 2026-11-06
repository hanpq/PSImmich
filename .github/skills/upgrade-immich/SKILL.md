---
name: upgrade-immich
description: "Use when upgrading PSImmich to a new Immich release, assessing API feature parity, comparing OpenAPI versions, or updating cmdlets for changed endpoints and DTOs."
---

# Upgrade PSImmich for an Immich release

This is the repeatable upgrade instruction document for contributors and AI
assistants. Read [Copilot instructions](../../copilot-instructions.md) and
[BUILDING.md](../../../BUILDING.md) first. Invoke this workflow with
`/upgrade-immich`, specifying the target Immich version and whether to assess or
implement. If unspecified, clarify scope before making API or release changes.

The first worked assessment is [3.4.0](../../../api/UPGRADE-3.4.0.md).
It is provisional: the local spec describes `3.4.0-rc.2`, not final `3.4.0`.

## 1. Record the upgrade inputs

Work from the repository root in PowerShell. Preserve existing worktree edits.
Before changing upgrade files, verify the current branch with
`git branch --show-current`. Develop each new Immich version on a dedicated
branch such as `upgrade/immich-3.4.0`, never directly on `main`. Create the
branch from the agreed baseline before the first edit (`git switch -c
upgrade/immich-3.4.0`), or continue the existing branch for that upgrade.
Do not reset, discard, or commit unrelated work to move onto the branch.
If the baseline or existing branch ownership is unclear, ask before proceeding.

The maintainer will manually create the upgrade PR, verify it, merge it, and
subsequently initiate the release when satisfied. The assistant's responsibility
is implementation, validation, coherent batch commits and a review handoff;
do not open a PR, merge, tag, prepare or publish a release as part of an upgrade.
Push the branch only when requested.

Record the following in a version-specific assessment under `api/`:

| Input | Required evidence |
| --- | --- |
| Baseline | Last supported Immich spec, tracked module version, Git commit |
| Branch | Dedicated upgrade branch and its agreed baseline commit |
| Target | Immich release/tag, release notes URL, embedded `info.version` |
| Spec provenance | Upstream commit, download URL, local SHA256 |
| Scope | Assessment only or implementation; endpoint exclusions and rationale |
| Compatibility | Target-only or supported older servers; intended breaking changes |
| Validation | Exact commands, results, skipped checks and blockers |

Do not assume the newest local spec is the supported baseline. Check
[release metadata](../../../.release-please-manifest.json),
[version.txt](../../../version.txt), the
[source manifest](../../../source/PSImmich.psd1), README compatibility claims,
and previous assessments. The release version and supported API version are
related but are not interchangeable: module patch releases can advance
independently.

## 2. Verify and acquire the authoritative target

1. Verify that the requested release exists in
   [Immich releases](https://github.com/immich-app/immich/releases).
2. Resolve its tag to an immutable commit. Obtain
   `open-api/immich-openapi-specs.json` from that commit, not `main` or a moving
   documentation page. Confirm the path at the tag if upstream reorganizes it.
3. Download to a temporary location first. Parse JSON and verify `info.version`.
   A filename such as `api.3.4.0.json` is not evidence of a final release.
4. Compare any existing candidate with upstream. Byte hashes can differ because
   of formatting; compare parsed objects recursively, with unordered object keys
   and ordered arrays, before deciding there is a contract difference.
5. Preserve historical specs. Add the verified target as `api\api.<version>.json`
   and record its provenance in the assessment.

Example, after obtaining a real immutable `$UpstreamCommit` and choosing
`$DownloadedSpec` as a scratch filename. Also set `$ComparisonReport` to a
scratch Markdown filename before running the comparison in the next section:

```powershell
$TargetVersion = '3.4.0'
$BaselineVersion = '2.3.1'
$OldSpec = ".\api\api.$BaselineVersion.json"
$NewSpec = ".\api\api.$TargetVersion.json"
$SpecUrl = "https://raw.githubusercontent.com/immich-app/immich/$UpstreamCommit/open-api/immich-openapi-specs.json"
# Download to a deliberately chosen scratch path, not over an existing spec.
Invoke-WebRequest -Uri $SpecUrl -OutFile $DownloadedSpec
$DownloadedVersion = (Get-Content -LiteralPath $DownloadedSpec -Raw |
    ConvertFrom-Json).info.version
if ($DownloadedVersion -cne $TargetVersion) {
    throw "Requested $TargetVersion but downloaded $DownloadedVersion."
}
Get-FileHash -LiteralPath $DownloadedSpec -Algorithm SHA256
```

If a final tag/spec is unavailable, explicitly mark the assessment provisional.
Do not relabel an RC, bump release metadata, or claim final-version parity.

## 3. Inventory changes using the existing tools

Read the tools before relying on their output; their limitations may change.
Use explicitly selected old/new specs:

```powershell
.\api\Compare-OpenApiSpecs.ps1 `
    -OldSpecPath $OldSpec -NewSpecPath $NewSpec `
    -ExclusionsPath .\api\exclusions.json -OutputPath $ComparisonReport
```

Choose `$ComparisonReport` in a scratch directory with a `.md` extension.
Capture console output separately. In the current implementation:

- File output is Markdown, not JSON. It ignores exclusions and reports raw
  removals separately from deprecation changes.
- Console output applies exclusions and classifies newly deprecated operations
  as removals. Its counts therefore differ from the file.
- `-IncludeSchemas` is accepted but unused; it does **not** compare DTO schemas.
- Parameter comparison is limited to names, required flags, direct types and
  descriptions. It does not establish request/response contract parity.

Independently enumerate valid HTTP methods under `paths`. Use `METHOD /path`
as the endpoint key; do not count path-item metadata as operations. Record raw
added, physically removed, common, and deprecated operations separately.
An endpoint can be deprecated yet still present and usable.

Run implementation discovery:

```powershell
.\api\Analyze-PSImmichAPI.ps1
```

This script has no spec-selection parameter. It selects the most recently
modified `api.*.json`, not the highest version. Confirm its printed filename
and embedded version before using the output. If it selects the wrong spec,
stop relying on that run; use an explicit-spec inventory or deliberately
improve the tool with tests. Do not alter historical timestamps to hide this.

The analyzer's `Work Items Summary` is the **required backlog**, not optional
noise. Every `REMOVE` (deprecated but still implemented) and `IMPLEMENT`
(missing) entry must end in one of: an implemented and tested batch, an
explicit exclusion with a reason approved by the maintainer, or a `blocked`
row with an owner. Do not start implementation until every entry has a ledger
row (section 4). Analyzer output is a starting point, not proof: it can miss
dynamic/splatted calls and cannot detect source calls to endpoints physically
absent from the target, so also run the inventory in section 4.5.

Parameter-mapping preflight:

```powershell
.\tools\Validate-ApiParameters.ps1 `
    -Path .\source\public -OpenApiSpec $NewSpec
```

This writes a timestamped CSV in the current directory and exits 1 for invalid
mappings. For scratch output, invoke it in a separate PowerShell process from
the scratch directory, passing absolute `-Path` and `-OpenApiSpec` paths.
Always inspect `TotalOperations` and `FoundInOperations`, not just the exit
code. Currently it compares slashless source paths with slash-prefixed OpenAPI
paths without normalizing them, and cannot resolve splats or arbitrary
expressions. Zero matched operations indicates inconclusive analysis, not
proof that every parameter is wrong. It also cannot detect API properties
that have no PowerShell parameter at all.

## 4. Build the actionable parity ledger

**Gate:** do not begin implementation until every target operation has a row
with one status, and every analyzer `REMOVE`/`IMPLEMENT` item is covered by a
row. The analyzer's counts (covered, excluded, work items) must reconcile to
the spec's total operation count; record the reconciliation in the assessment.
Record the scope as full parity with the target unless the maintainer narrows it.

For **every target operation**, assign one status:
`verified`, `needs-change`, `missing`, `excluded`, or `blocked`.
Track removed baseline operations separately. A useful row is:

| Method/path + operationId | Cmdlet/parameter set | Contract delta | Action | Unit/live evidence | Status |
| --- | --- | --- | --- | --- | --- |
| Exact endpoint identity | Existing or proposed surface | Query/body/response/auth differences | Implement, migrate, retain, exclude | Test names and results | One explicit status |

Use operation IDs and release notes to recognize relocated/replaced endpoints,
but verify their DTOs instead of assuming a path rename is sufficient.

**Deprecated routes: find the replacement first.** Immich usually replaces a
deprecated route rather than deleting its functionality. For each deprecated
operation still used by source, determine its replacement before deciding
anything:

1. Compare request body property names and response DTOs against non-deprecated
   operations in the same spec (for example, `PUT /system-config` and
   `PUT /admin/config` share the same 22 properties).
2. Check sibling methods on the same path and new paths in the same domain
   (`/queues` for `/jobs`, `/public/config` and `/config` for `/server/config`).
3. Read the replacement's schema and confirm which fields moved, were split
   across DTOs, or were dropped. Record the mapping as old operation → new
   operation, with the field-level delta.
4. If a replacement exists, implement it and migrate the cmdlet, keeping the
   public UX where possible; document any user-visible change.
5. If no replacement exists, **keep the route and its cmdlets**. Deprecation
   alone is never a reason to remove functionality: the Immich app itself may
   still depend on a deprecated route. Record the reason in the assessment and
   revisit when the spec adds a replacement or removes the route.
6. Removal is allowed only when the route is physically absent from the target
   spec. Then remove the functionality, or ask the maintainer if no equivalent
   exists, and record the user impact.

Descriptions in the spec rarely name the replacement; do not rely on them.
Track removed baseline operations separately from the target ledger.

Audit [exclusions.json](../../../api/exclusions.json) against the target.
Count only exact method/path exclusions still present. An exclusion means a
deliberate scope decision, not implemented functionality. Review browser
authentication, streaming, sync, and internal endpoints with the user rather
than excluding them just to improve a badge. If another cmdlet provides the
feature, name it and test equivalent behavior; document that direct endpoint
coverage is still excluded. Report both full-API and agreed-scope gaps.

For every changed **and unchanged** endpoint used by the module:

1. Compare path/query parameters, inherited parameters, request bodies,
   response status codes/content types, security requirements and permissions.
2. Resolve `$ref` transitively, including nested objects, arrays, `allOf`,
   `oneOf` and `anyOf`. Compare added/removed schemas and properties, `required`,
   enums, formats, bounds, defaults, nullability and read/write-only rules.
3. Map changes to `[ApiParameter]` attributes, `ValidateSet`/validation,
   parameter sets, paging, body construction, upload/download handling,
   returned types, format views and comment-based help.
4. Check release notes for behavior not represented by OpenAPI.
5. Inventory all source REST calls too, so physically removed endpoints are
   caught even when the analyzer reports no work for them.

Report verified coverage as `verified / eligible target operations`.
Report excluded, deprecated, missing, blocked and unverified counts separately.
Never use the analyzer's printed "working correctly" count as a parity gate:
it subtracts all exclusions and work items, including deprecations, without
proving request/response behavior.

## 5. Implement in bounded, testable batches

Assessment-only requests stop after the ledger and ordered backlog.
For implementation, start only after the section 4 gate is met, then prioritize:

1. Existing cmdlets broken by removals or contract changes.
2. Migration away from deprecated routes to their verified replacements while
   preserving intended UX.
3. Missing read operations, then create/update/delete and asset workflows.
4. Cross-cutting schema, permissions, authentication, pagination and binary
   transport work.

Working a priority tier does not end the upgrade. Advance to the next tier
until every backlog row is resolved as section 6a requires.

Split these priorities into coherent feature/change batches, not one large
upgrade commit or a commit per file. For each batch:

1. Define its user-visible outcome and affected endpoint/DTO ledger rows.
2. Implement the complete change with its directly related tests and help.
3. Run relevant tests and inspect the diff. Do not commit a batch as complete
   while its tests fail; record unrelated baseline failures explicitly.
4. Stage only that batch's files/hunks and create a meaningful Conventional
   Commit on the upgrade branch before starting the next batch.
5. Record the commit, exact validation results and remaining work in the
   assessment/handoff.

Commit messages are release inputs: describe the feature or fix, not the batch
number or API version alone. Examples:

```text
feat(api-key): add API key rotation
fix(person): migrate person merging to the bulk endpoint
feat(asset): add asset edit lifecycle commands
```

Use `!` and a `BREAKING CHANGE:` footer for actual breaking changes; keep
documentation-only or test-only work under the corresponding types. Preserve
required commit trailers. An assessment-only request does not authorize
implementation commits.

Release Please generates changelog entries from releasable commits that reach
`main`. Preserve these batch commits when merging the upgrade PR. Prefer a
merge commit for a multi-batch upgrade; squash-merging the entire branch into
one title loses the individual feature/fix subjects. If squash is required,
agree a commit-preserving approach (for example separate PRs per batch) with
the maintainer rather than assuming the branch history will be summarized.

Use [source/public](../../../source/public) domain folders. Reuse
`InvokeImmichRestMethod`, `ConvertTo-ApiParameters`, session handling and
`[ApiParameter('apiName')]` conventions. Combine related routes with natural
PowerShell parameter sets rather than generating one cmdlet per endpoint.
Preserve explicit and default sessions, pipeline binding and return shapes.
Surface errors through repository-standard handling; do not silently drop new
fields or return success-shaped fallbacks.

Migration decisions must specify old-to-new endpoint/DTO mappings and any
breaking user impact. Do not remove a cmdlet merely because its route is
deprecated. Move to a replacement only when one is clearly the successor;
keep deprecated routes that have no replacement; remove functionality only
when its route is physically absent from the target spec. If older-server support is required, use verified
version/capability handling and test both branches; do not guess fallback behavior.

Add `ShouldProcess` to destructive operations. Obtain approval for live
database restore/delete, maintenance changes, account changes and similar
high-impact tests. Use disposable test resources; never mutate unrelated data.

## 6. Verify each batch and then the complete upgrade

Follow [BUILDING.md](../../../BUILDING.md), not obsolete Sampler commands:

```powershell
.\build.ps1 -Task Build
.\build.ps1 -Task Test -TestSuite Module
.\build.ps1 -Task Test -TestSuite Infrastructure
.\build.ps1
```

`Verify` (the default) builds and runs unit, QA and infrastructure tests.
`-Tasks`, `-PesterTag`, `-PesterPath`, and task `pack` are not supported.
For individual tests, first build; use the pinned Pester from
`output\RequiredModules`, expose `output` on `PSModulePath`, and configure
Pester's `Run.Path` and `Filter.FullName` or `Filter.Tag` directly. Check that
tests were actually selected and executed. This does not replace the final
full verification or its coverage conversion.

Use [Get-IMLibrary tests](../../../tests/Unit/Public/Public.Tests.ps1) as a
pattern, locating the current block rather than relying on historical line
numbers. Test every affected parameter set and mock all network access.
Assert exact method/path/query/body, omitted versus explicit false/zero/null,
arrays and nesting, session forwarding, pipeline binding, validation,
empty/error responses, pagination and output shape. Placeholder tests are
not evidence of parity.

Live integration rules (mandatory when a live instance is used):

- Use only the maintainer's authorized demo instance dedicated to integration
  tests. Confirm its version with `GET /server/version` before running tests and
  record it; it must match the target release.
- Check that `PSIMMICHURI` and `PSIMMICHAPIKEY` are set (names only, never print
  values). If they are missing, pause and ask the maintainer to add them.
- Never run integration tests concurrently or in parallel. Run one suite at a
  time and wait for it to finish, including before any retry.
- Tests must revert every state change they make. Create only disposable
  resources, clean them up in `AfterAll`/`finally` blocks, and never modify
  pre-existing assets, users, settings or jobs. If a test cannot restore state,
  stop and report it.
- Do not send credentials or demo-instance details to third-party services or
  commit them to the repository.

Only with an authorized disposable target-version server, set `PSIMMICHURI`,
`PSIMMICHAPIKEY`, `PSIMMICHUSER`, and `PSIMMICHPASSWORD` securely and run:

```powershell
.\build.ps1 -Task Test -TestSuite Integration
```

Record the actual server version and skipped scenarios. Keep credentials out
of reports. Exercise lifecycle cleanup while preserving pre-existing assets.
Default local verification excludes live integration.

Re-run endpoint and contract inventories after implementation. Require:

- Every eligible nondeprecated target endpoint has verified cmdlet behavior.
- Every removed route used by source has a tested migration or documented
  intentional removal.
- Every relevant DTO/property/enum/auth change has been checked.
- No unresolved blockers are hidden by exclusions or rounded coverage.
- Full build/tests pass, and live claims have real target-version evidence.
- CI covers the project's supported PowerShell/platform matrix.

If live validation or final-spec verification is unavailable, report that
limitation instead of calling the upgrade fully verified.

## 6a. Definition of done

An upgrade is complete only when every item below is true, and the handoff
states each one with evidence:

1. The target spec is verified (`info.version`, commit, SHA256) and committed.
2. Every analyzer `REMOVE` and `IMPLEMENT` item, and every eligible
   non-deprecated target endpoint, is `verified`, `excluded` with a reason that
   the maintainer has approved, or `blocked` with an owner. No `needs-change`,
   `missing` or unreviewed `covered` rows remain. An exclusion added by the
   assistant alone does not count.
3. Every route physically removed from the target spec and used by source has a
   tested migration to a verified replacement, or a maintainer-approved removal
   with user impact noted.
4. Every deprecated route used by source is either migrated to a verified
   successor (a replacement that the spec or release notes present as its
   successor) or retained with a recorded reason. Analyzer `REMOVE` labels are
   not instructions to delete.
5. `.\build.ps1 -Task Build` and `.\build.ps1 -Task Test -TestSuite Module` pass,
   apart from failures recorded as pre-existing with their cause.
6. Live integration tests pass against an authorized target-version demo
   instance, run one at a time, with state restored afterwards.
7. README compatibility and coverage figures are updated, and the assessment
   records the batch commits, test results and remaining scope decisions.
8. The maintainer has been told that PR creation, review, merge and release remain theirs.

## 7. Document and release deliberately

Update source help, examples, affected format/type handling, README supported
Immich versions and reproducible coverage figures. Express user-facing
features/fixes/breaking changes in batch commit messages. Release Please
automatically generates [CHANGELOG.md](../../../CHANGELOG.md) during release
preparation; do not manually duplicate planned release entries during upgrade
implementation. Keep internal test/process details out of user-facing entries.

Use Conventional Commits and follow the current
[release process](../../../BUILDING.md). During routine API work, do not
manually edit `.release-please-manifest.json`, `version.txt`, channel labels
or generated `output` files. Release Please prepares metadata; the build
derives version/prerelease data from tracked metadata and stamps the built
manifest. Coordinate the desired Immich major/minor target in the release PR
rather than assuming normal semantic-release increments will select it.

After reviewing and manually creating/merging the upgrade PR, the maintainer
initiates beta preparation through **Actions > Prepare release > beta**,
reviews the version, generated changelog, notes and CI, and merges the release
PR to publish. Stable promotion uses
**Prepare release > stable** only after the latest beta is published and
`main` has no intervening commits. Let workflows enforce tag, version,
prerelease flag and built-manifest consistency. These are maintainer-controlled
steps, not actions for the assistant to execute during the upgrade.

When the intended version is not the normal Conventional Commit increment,
review the `Release-As` footer guidance in BUILDING.md with the maintainer and
verify the resulting beta release PR version. Do not use a dummy feature/fix
commit or hand-edit metadata to force the target.

Comment-based source help is the documentation source of truth. The
`scripts\Update-Docs.ps1` publishing path requires a checked-out documentation
repository and `DOCS_GITHUB_TOKEN`; run it only when documentation publishing
is authorized, not as a prerequisite for a local assessment.

## 8. Improve this process after every upgrade

Append a dated learning to the version assessment: observed problem, verified
cause, effective solution and supporting command/test. Promote durable lessons
into this workflow, replacing outdated guidance rather than accumulating
contradictions. Keep counts, work status and version-specific mappings in the
assessment, not in always-on Copilot instructions.

The handoff should identify the upgrade branch, batch commits and user-facing
summaries, next actionable batch, blockers, exact tests run and remaining scope
decisions. State that manual PR review/creation, merge and release remain with
the maintainer so another session can continue without repeating discovery.
