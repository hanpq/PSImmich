# PSLogs pipeline kit: preserve optional Format assets

## Scenario

PSImmich's legacy ModuleBuilder configuration includes `CopyPaths: [en-US, include, Format]`. Its `source/Format/PSImmich.Format.ps1xml` supplies module formatting. The exported PSLogs kit only detects `en-US` and `include` in `Build-ProjectModule`, so copying it unchanged would omit formatting assets from built modules and release ZIPs.

## Changes made in PSImmich

- In `build.ps1`, `Build-ProjectModule` discovers `Format` alongside `en-US` and `include` when the directory exists and passes those paths to ModuleBuilder's `CopyPaths`. Projects without `Format` retain their existing behavior.
- In `tests/Build/Build.Tests.ps1`, the optional-source-parts test includes a fixture with `Format` and verifies the ModuleBuilder invocation receives all three paths.
- `BUILDING.md` records this deviation in **Pipeline customizations** so a future kit update will not remove it.

## Request for PSLogs

Update the canonical `build.ps1` and its `tests/Build/Build.Tests.ps1` test to preserve optional `source/Format/` in modules using this layout. Update the migration guide's accepted `CopyPaths` and stop-condition rules so `Format` is an allowed, preserved directory. Keep absent directories optional. Export a new tested kit after the change.

PSImmich also keeps live Immich integration tests in a separate `Integration` test suite and a same-repository CI job; those are service-specific deviations, not required for every module. Its default `Verify` does not run live tests, and CI does not expose secrets to fork PRs.
