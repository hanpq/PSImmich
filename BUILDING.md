# Building and releasing PSImmich

For new Immich versions, follow the [repeatable API upgrade workflow](.github/skills/upgrade-immich/SKILL.md). Keep release-specific gaps and validation evidence in an assessment, starting with [3.4.0](api/UPGRADE-3.4.0.md).

## Develop and verify

From the repository root, run the full build and test suite:

```powershell
./build.ps1
```

The default `Verify` task builds the module from `source/` and runs unit, QA and build infrastructure tests. Live integration tests are a separate suite and require an Immich instance. To run one task:

```powershell
./build.ps1 -Task Build
./build.ps1 -Task Test
./build.ps1 -Task Package
```

Import the generated module from `output/PSImmich/<version>/` to try it locally. Make changes in `source/`, not generated output under `output/`.

Local tests run unit, QA and infrastructure suites by default. Use `-Task Test -TestSuite Module` for unit/QA tests or `-Task Test -TestSuite Infrastructure` for build/release tests. For a subset of module tests, add `-Tag`, for example `-Task Test -TestSuite Module -Tag 'Get-IMStack','New-IMStack'`; each unit Describe is tagged with `Unit` and its cmdlet name. Tag-filtered runs skip code coverage. Run `-Task Test -TestSuite Integration` against a live Immich instance after setting `PSIMMICHURI`, `PSIMMICHAPIKEY`, `PSIMMICHUSER` and `PSIMMICHPASSWORD`. CI runs module tests with coverage across all supported platforms, infrastructure tests once on Linux PowerShell 7, and live integration tests on same-repository PRs and pushes when these four secrets are set. Fork PRs skip live integration tests. Release publishing runs the module suite.

Coverage instruments the built module that the tests execute, then uses ModuleBuilder's source mappings to report the original `source/public` and `source/private` files in `output/testResults/JaCoCo_coverage.xml`. The module test run fails if coverage is below the configured target (currently 1%).

The QA suite in `tests/QA/module.tests.ps1` reports each file-quality check separately. It discovers source files and reads unit-test files once per run, and parses each function file once in its context's `BeforeAll`. Keep these shared inputs read-only so individual checks remain independent.

Stable-promotion tests mock Git and the GitHub API. They use temporary release-metadata files without initializing repositories or creating commits and tags; these are unit tests, not Git integration tests.

### VS Code shortcuts

- **Ctrl+Shift+B** runs `Verify` (build and tests). **Tasks: Run Task** also offers `build`, `test`, and `package`; `test` rebuilds first.
- Select **PowerShell Debug Module (build first)** and press **F5**. It builds, then runs [ModuleDebug.ps1](ModuleDebug.ps1) in a temporary PowerShell console, avoiding stale module state. Keep manual end-user scenarios and breakpoints in that script.
- To step into module functions, set breakpoints in the generated `output/PSImmich/<version>/PSImmich.psm1` after building. Rebuilds replace this file; edit only `source/`.

Tasks require PowerShell 7 (`pwsh` on PATH). Debugging requires the VS Code PowerShell extension and uses its selected PowerShell session.

## Submit a change

1. Make and test your change on a branch, never directly on `main`. For an Immich upgrade, use a dedicated branch such as `upgrade/immich-3.4.0` and commit each coherent feature/change batch with its related tests and help.
2. Open a pull request against `main`. CI runs for pull requests and pushes to `main`. Pushes that only change release metadata (`.release-please-manifest.json`, `version.txt`, `CHANGELOG.md`), such as merged release PRs, skip CI on `main` because the PR and the release workflow already test them.
3. Use a Conventional Commit title for changes that should trigger a release. `feat:` requests a minor release; `fix:` and `perf:` request a patch; `!` or a `BREAKING CHANGE:` footer requests a major release. `docs:`, `test:`, and `chore:` do not trigger releases.
4. For a single-change PR, squash-merge using the Conventional Commit PR title. For a multi-batch Immich upgrade, preserve the individual Conventional Commits, preferably with a merge commit, so Release Please can summarize each feature/fix. Squashing the entire upgrade into one commit loses the individual batch subjects; if squash is required, agree an alternative such as separate PRs per batch. This guidance is for development PRs; stable-promotion release PRs have their own merge restrictions below.

For Immich upgrades, the maintainer manually creates the development PR, verifies and merges it, then initiates release preparation only after confirming everything is OK. The assistant implements and validates batches on the upgrade branch and provides a commit/test handoff; it does not open or merge PRs, prepare releases or publish. Pushes require a request. Release Please generates the changelog from releasable commits during release preparation; do not manually duplicate those entries during upgrade development.

## Release channel cheat sheet

| How it starts | Channel | What happens |
| --- | --- | --- |
| Ordinary PR or push to `main` | None | CI only; no release preparation or PR refresh. |
| **Actions → Prepare release → Run workflow → `beta`** (from `main`) | Beta | Opens or explicitly refreshes the beta release PR when conventional commits warrant one; never creates a tag or release. |
| **Actions → Prepare release → Run workflow → `stable`** (from `main`) | Stable promotion | Opens a stable promotion PR for the latest published beta, including with zero new commits. |
| Merge the release PR | Its recorded channel | Finalizes the tag/GitHub release only; never prepares another PR. |

Review the release PR version and notes, wait for CI, and merge it to publish. The release PR remains the gate for both channels. A stable promotion requires the latest beta to be published and `main` to have no commits after that beta; merge any pending beta release first. It creates a metadata-only release PR, so no config toggle or dummy fix commit is needed. Stable notes roll up beta entries since the previous stable release; beta entries remain in the changelog. Missing or unrecognized release boundaries fail the workflow instead of silently omitting notes.

Keep `main` at that beta until the stable promotion merges, using squash or a merge commit (not rebase). Finalization rechecks the merge's first parent against the published beta tag; intervening changes fail closed instead of silently releasing untested changes as stable.

An open stable promotion blocks manual beta preparation. Re-running stable preparation leaves an existing promotion unchanged; close it to start over. Ordinary pushes never rewrite release PRs.

Merged-PR finalization requires the same-repository release branch, pending label, generated bot metadata, and the author matching the dedicated `RELEASE_PLEASE_TOKEN` owner's login (a user/PAT token). Only the three release metadata files may change. The title, body, immutable head/merge manifests and `stable-promotion` label must agree before selecting the checked-in channel configuration. Do not edit channel labels or release metadata by hand. Finalization checks out trusted `main`, never the PR head, and refuses other merged pending releases rather than publishing them in the wrong channel. Resolve stale pending labels before retrying a failed finalization.

`RELEASE_PLEASE_TOKEN` needs repository contents, issues and pull-request write access. It creates release PRs and releases so their events can trigger CI and publishing (unlike the default Actions token). The workflow has no default token permissions; its gated jobs grant the Actions token only contents-read access for checkout.

The release workflow checks that the immutable tag, tracked version, GitHub prerelease flag, and built module manifest agree before publishing.

The release workflow builds and tests the tag, attaches a ZIP to the GitHub release, and publishes the module to the PowerShell Gallery. Do not edit `.release-please-manifest.json` or toggle release configuration during routine development.

Prereleases use padded labels such as `beta001`. Users must opt in when installing, for example:

```powershell
Install-Module PSImmich -AllowPrerelease
```

## Update build dependencies

1. Change the intended module version in [RequiredModules.psd1](RequiredModules.psd1).
2. Restore the pinned dependencies and verify the build:

```powershell
./build.ps1 -Task InstallDependencies
./build.ps1
```

The build uses these pinned dependencies from `output/RequiredModules`; you do not need to install them separately.

## Pipeline customizations

- `source/format/` is copied into the built module alongside `en-US` and `include`; the generic kit build script and its build test have been extended to preserve the existing formatting assets.
- Live integration tests use a dedicated `Integration` suite and a same-repository CI job with Immich credentials. Default local verification excludes the live suite; fork PRs do not receive those secrets.
- The legacy README test-count badge and its update task were removed. The module is published to the PowerShell Gallery and optionally ProGet, with Linux, macOS, Windows PowerShell 7 and Windows PowerShell 5.1 CI targets.

Release metadata starts at the last published stable release, 2.3.1. The previously listed 2.3.2 changes are staged under the planned 2.3.3 heading in the Unreleased section. To skip the unpublished 2.3.2 release, put a `Release-As: 2.3.3` footer on the **next releasable** `fix:` commit (not the migration commit). Release Please generates notes from the commits since 2.3.1, not from manually staged changelog text; review its first beta PR to confirm the version and notes before merging.

On this workstation, Desktop validation fails before tests because .NET Framework refuses to load the pinned PSScriptAnalyzer DLL from the D: drive (0x80131515, interpreted as a network location). PowerShell 7 module validation currently reports eight unrelated QA failures: six public cmdlets without unit-test blocks, and analyzer warnings on `Get-IMUserStatistics` and `Set-IMQueue`. The infrastructure suite passes.

Pipeline kit: hanpq/PSLogs@ca723099f0daee74603a2168df589e95f07bed34
