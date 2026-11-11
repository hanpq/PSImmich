# Immich 3.4.0 upgrade assessment

## Status and scope

**In progress; not a claim of API parity.** The operation ledger below is a
mechanical inventory, not completed human contract review. In particular,
`needs-change` means unreviewed as well as known changes; no rows are marked
verified based on static reachability alone.

| Input | Evidence |
| --- | --- |
| Baseline | Immich API [3.3.6](api.3.3.6.json); module release 3.3.7; baseline commit `85a7e73b8993b95a903e6d215c9c432a8b76ef75` |
| Branch | `update-3.4.0`, based on that commit |
| Target | [Immich v3.4.0](https://github.com/immich-app/immich/releases/tag/v3.4.0), published 2026-11-10; spec `info.version` is `3.4.0` |
| Provenance | Tag commit `0715bcf8dab4b91118d6184479e2be2767ef8294`; [immutable upstream spec](https://raw.githubusercontent.com/immich-app/immich/0715bcf8dab4b91118d6184479e2be2767ef8294/open-api/immich-openapi-specs.json). Local SHA256 `6DEBF0AE8D7A41498EF8C6D69621A320371CD7C2182E6EDDF42ECDB6C7595C6A`; upstream SHA256 `B5E5F82DDA2E378D53DD5FF852AA8F5D081FFEFECAE5564F42BEAB5589A3ED1A`. Parsed objects are recursively identical with unordered object keys and ordered arrays. |
| Compatibility | Target 3.4.x only, per maintainer decision. |
| Passkeys | Management only; maintainer explicitly deferred WebAuthn registration and authentication. The four deferred operations remain blocked, not counted as implemented. |
| Maintenance | Maintainer deferred rollback and the disabled maintenance lifecycle pending a separate safety investigation. |
| Exclusions | Existing exclusions retained; no new exclusions made. Prior exclusions need separate review against target. |

## Inventory and findings

- Valid HTTP-method inventory: 279 baseline operations, 287
  target operations, 8 added and 0 physically removed;
  279 common. All additions are passkey routes.
- The comparison tool reports 8 added, 0 removed and 14 modified in its raw
  report. All 14 modified routes ceased to be deprecated; no operations became
  newly deprecated. Its exclusion-aware console shows 10 modified. An
  independent comparison found 18 changed common operation objects: the same
  14 plus four permission-metadata changes.
- Corrected static reachability: 185 referenced by source and non-generated
  tests, 4 reachable without a direct test reference, 5 unreachable and 93
  excluded; 189/194 (97.4%) wired through the generated layer. The five
  unreachable entries include four deliberately deferred WebAuthn operations
  and `POST /assets`, which is reached through direct multipart transport by
  `Import-IMAsset` and is a static false negative. Existing exclusions total 97;
  93 match. Static references do not establish contract or behavior parity.
- Before fixing the coverage tool, generated route tests alone caused all 194
  non-excluded operations, including the deferred WebAuthn routes, to be
  reported as tested. That result is not a valid coverage or parity claim.
- Schema inventory: 15 added, 2 removed and 15 changed schema definitions.
  Important changes include `theme` removed from public and user config;
  new passkey/config fields; `jxl` image format; passkey and cluster-group
  permissions; workflow OCR trigger; maintenance rollback; and queue status
  metadata. Verify individual constraints, required properties, serialization
  and responses before implementing or claiming support.
- New WebAuthn DTO fields include unconstrained schemas. The generator was
  updated to preserve unconstrained values without silently accepting unknown
  validation keywords; target generation and generated tests now pass.
- The generated `PasskeyResponseDto.usedAt` is a non-nullable `datetime`, so
  its constructor cannot preserve a null last-used timestamp. The public
  passkey commands deliberately return raw response objects instead. Audit
  generated nullable value types across the module before changing their
  behavior globally.

### Changed baseline schema definitions

These are field-level comparison results, not a declaration of full behavioral
parity. New nested schemas are listed in the ledger where they are referenced.

| Schema | Change |
| --- | --- |
| `AdminConfigBackupsDto` | Optional `beta` boolean added. |
| `AdminConfigDto` | Required `passkey` configuration added. |
| `ImageFormat` | `jxl` enum value added. |
| `JobName` | `AuthChallengeCleanup` enum value added. |
| `MaintenanceAction` | `rollback` enum value added; interactive lifecycle deferred. |
| `MaintenanceStatusResponseDto` | Optional `futoBackupsJobId` added. |
| `Permission` | `clusterGroup.admin` and `passkey.read`, `passkey.update`, `passkey.delete` added. |
| `PublicConfigDto` | Required `theme` removed; required `ffmpeg`, `map` and `passkey` added. |
| `QueueStatisticsDto` | `paused` is marked deprecated; history notes paused jobs also appear as waiting. |
| `ServerFeaturesDto` | Required `backups` boolean added. |
| `ServerVersionResponseDto` | Required numeric `featureLevel` added; exposed by `Get-IMServer -Version`. |
| `SetMaintenanceModeDto` | Optional `rollbackRepositoryId` and `rollbackSnapshotId` added. |
| `UserConfigDto` | Required `theme` removed; required `notifications` and `passkey` added. |
| `UserConfigOAuthDto` | Optional `accountManagementUrl` string with empty default added. |
| `WorkflowTrigger` | `AssetOcrExtraction` enum value added. |

`PublicConfigThemeDto` and `UserConfigThemeDto` were removed. The target spec
also adds 15 definitions for passkeys, public/user configuration and server
feature levels. Several changes carry upstream `v4.0.0` history metadata even
though they appear in the authoritative 3.4.0 release spec; treat the recorded
metadata and the target server's actual behavior separately.

### Confirmed theme regression and migration

`Get-IMServer -Theme` reads `theme` from `GET /public/config`, but the 3.4.0
`PublicConfigDto` no longer includes that property. The cmdlet therefore no
longer has a defined theme value on the target contract. `AdminConfigDto` still contains `theme`. The old public and target admin theme
schemas both contain the same required `customCss` string. The maintainer chose
to retrieve the admin theme and document the new admin-configuration permission
requirement; this intentionally changes access for non-admin users.

The four operation permission metadata changes are:

- `POST /admin/notifications`, `/admin/notifications/templates/{name}` and
  `/admin/notifications/test-email`: `notification.create` was added.
- `POST /cluster-groups/{id}/regenerate-people`: `clusterGroup.read` changed to
  `clusterGroup.admin`.

The target `Permission` enum has 172 values. `New-IMAPIKey` now validates
against that exact enum; this intentionally rejects obsolete names such as
`admin.user.create` and `album.addAsset`. The OCR workflow trigger is accepted
by workflow and plugin-method cmdlets. The rollback action is blocked: existing
maintenance start/stop cmdlets are disabled, and the maintainer chose to defer
the safety investigation. The upstream implementation also applies conditional
validation for database-restore filenames that is not represented in OpenAPI.

## Validation so far

- `Compare-OpenApiSpecs.ps1` with explicit 3.3.6/3.4.0 inputs and existing
  exclusions: completed; report and console have different exclusion semantics.
- `Get-ImmichApiCoverage.ps1 -SpecPath .\api\api.3.4.0.json`: completed;
  static results above.
- `New-ImmichApiLayer.ps1 -SpecPath .\api\api.3.4.0.json -Check`: failed
  on unsupported typeless `PasskeyRegistrationFinishDto` field.
- `.\build.ps1`: the module built, then Pester reported 4,628 passed,
  1 failed, and 1,129 skipped. The single failure was the generated-layer
  consistency test caused by the generator error above; the build exited 1.
  Infrastructure verification was not reached.
- `.\build.ps1 -Task Test -TestSuite Module -Tag 'Get-IMServer'`: passed,
  29 tests including theme output, explicit session and propagated errors.
- `.\build.ps1` after the theme migration: module build succeeded; Pester
  reported 4,630 passed, 1 failed and 1,129 skipped. The same generated-layer
  consistency test failed; infrastructure verification was not reached.
- `.\tools\New-ImmichApiLayer.ps1 -SpecPath .\api\api.3.4.0.json -Check`:
  passed after regeneration.
- `.\build.ps1 -Task Test -TestSuite Module -Tag 'ImmichApiLayer','ImmichDtoLayer'`:
  1,158 passed.
- `.\build.ps1 -Task Test -TestSuite Module -Tag 'Get-IMPasskey','Rename-IMPasskey','Remove-IMPasskey','New-IMAPIKey'`:
  56 passed.
- `.\build.ps1 -Task Test -TestSuite Module -Tag 'Get-IMPluginMethod','Get-IMWorkflow','New-IMWorkflow','Set-IMWorkflow','Set-IMStack'`:
  80 passed.
- `.\build.ps1 -Task Test -TestSuite Module -Tag 'Get-IMServer'`: 30 passed
  after public-configuration support.
- `.\build.ps1 -Task Test -TestSuite Module -Tag 'New-IMAPIKey'`: 21 passed
  after permission enum alignment.
- `.\build.ps1 -Task Test -TestSuite Infrastructure -Tag 'ApiCoverage'`:
  1 passed.
- `.\build.ps1` after passkey implementation: passed; 4,734 passed and 1,161
  skipped, including module and infrastructure tests. This run preceded the
  later workflow, coverage, server and permission batches.
- `.\build.ps1` after the workflow, coverage, public configuration and
  permission batches: passed; 4,741 passed and 1,161 skipped. This run preceded
  the feature-level batch; its targeted `Get-IMServer` run passed 30 tests.
- `.\build.ps1` after the feature-level and maintenance-status batches: passed;
  4,742 passed, 1,161 skipped, with source instruction coverage 93.14%.
- Authorized demo server: version check first reported 3.3.6; after the
  maintainer upgraded it, 3.4.0 was confirmed. Approved read-only theme, public
  configuration and passkey listing checks passed. There were no existing
  passkeys, so read-by-ID was skipped.
- `.\build.ps1 -Task Test -TestSuite Integration -Tag 'Get-IMPasskey'`: approved
  read-only run against 3.4.0; 1 passed, 1 skipped (no passkey to retrieve).
  Rename and delete have not been tested live because no disposable passkey is
  available. The full integration suite was not run.

## Completed batch

- `cba77e4` `fix(server)!: retrieve theme from admin configuration`: migrates
  `Get-IMServer -Theme` to `GET /admin/config`. Unit/QA validation passed as
  above; approved read-only live check passed. Admin configuration permission
  is now required.
- `fa6e440` `feat(api)!: align generated contracts with Immich 3.4`.
- `2b9e467` `feat(passkey): manage existing passkeys`.
- `821cee9` `feat(workflow): support OCR extraction triggers`.
- `dea7754` `fix(coverage): exclude generated tests from reachability`.
- `fbc8594` `feat(server): expose public configuration`.
- `48e6ff9` `fix(api-key)!: align permissions with Immich 3.4`.
- `9f9b756` `test(passkey): verify read-only access on target servers`.
- `abacf5a` `feat(server): expose server feature level`.
- `7963a15` `test(maintenance): cover rollback status fields`; the targeted
  maintenance-status run passed 10 tests.

## Operation ledger

Counts: 189 unreviewed or partially reviewed/needs-change, 0
missing, 5 blocked, 93 existing exclusions,
0 verified; total 287. No removed routes require a separate row.
Rows list recursively referenced changed schemas, not proof of their effect.
Caller discovery is a static public-source name search and is not exhaustive
for direct transport calls. Unit/live behavior remains unverified for every row.

| Method and path | Operation ID | Public caller candidates | Detected contract delta | Action | Status |
| --- | --- | --- | --- | --- | --- |
| GET /activities | getActivities | Get-IMActivity | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /activities | createActivity | Add-IMActivity | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /activities/statistics | getActivityStatistics | Get-IMActivityStatistic | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /activities/{id} | deleteActivity | Remove-IMActivity | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /admin/auth/unlink-all | unlinkAllOAuthAccountsAdmin | No public caller found | No structural delta detected | Existing exclusion: Interactive web operation | excluded |
| GET /admin/config | getAdminConfig | Get-IMServer | DTO: AdminConfigBackupsDto, AdminConfigDto, AdminConfigPasskeyDto, ImageFormat | Review mappings and test behavior | needs-change |
| PUT /admin/config | updateAdminConfig | Set-IMServer | DTO: AdminConfigBackupsDto, AdminConfigDto, AdminConfigPasskeyDto, ImageFormat | Review mappings and test behavior | needs-change |
| GET /admin/config/defaults | getAdminConfigDefaults | Get-IMServer | DTO: AdminConfigBackupsDto, AdminConfigDto, AdminConfigPasskeyDto, ImageFormat | Review mappings and test behavior | needs-change |
| GET /admin/database-backups | listDatabaseBackups | Get-IMDatabaseBackup | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /admin/database-backups | deleteDatabaseBackup | Remove-IMDatabaseBackup | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /admin/database-backups/start-restore | startDatabaseRestoreFlow | No public caller found | No structural delta detected | Existing exclusion: Destructive database restore flow; not exposed without dedicated, disposable-target testing and explicit maintainer approval | excluded |
| POST /admin/database-backups/upload | uploadDatabaseBackup | No public caller found | No structural delta detected | Existing exclusion: Uploads a database dump to restore from; part of the destructive restore flow and not exposed without dedicated testing | excluded |
| GET /admin/database-backups/{filename} | downloadDatabaseBackup | Save-IMDatabaseBackup | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/integrity/report | getIntegrityReport | Get-IMIntegrityReport | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /admin/integrity/report/{id} | deleteIntegrityReport | Remove-IMIntegrityReport | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/integrity/report/{id}/file | getIntegrityReportFile | Save-IMIntegrityReport | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/integrity/report/{type}/csv | getIntegrityReportCsv | Save-IMIntegrityReport | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/integrity/summary | getIntegrityReportSummary | Get-IMIntegrityReport | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /admin/maintenance | setMaintenanceMode | Start-IMMaintenanceMode, Stop-IMMaintenanceMode | DTO: MaintenanceAction, SetMaintenanceModeDto | Disabled lifecycle and rollback deferred; owner: maintainer | blocked |
| GET /admin/maintenance/detect-install | detectPriorInstall | No public caller found | No structural delta detected | Existing exclusion: One-time install and onboarding detection used by the web setup wizard; not relevant after installation | excluded |
| POST /admin/maintenance/login | maintenanceLogin | No public caller found | No structural delta detected | Existing exclusion: Admin maintenance - not for interactive use | excluded |
| GET /admin/maintenance/status | getMaintenanceStatus | Get-IMMaintenanceStatus | DTO: MaintenanceAction, MaintenanceStatusResponseDto | Review mappings and test behavior | needs-change |
| POST /admin/notifications | createNotification | New-IMNotification | operation: x-immich-permission | Review mappings and test behavior | needs-change |
| POST /admin/notifications/templates/{name} | getNotificationTemplateAdmin | No public caller found | operation: x-immich-permission | Existing exclusion: Renders email notification template previews for the web admin UI | excluded |
| POST /admin/notifications/test-email | sendTestEmailAdmin | Send-IMTestMessage | operation: x-immich-permission | Review mappings and test behavior | needs-change |
| GET /admin/users | searchUsersAdmin | Get-IMUser | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /admin/users | createUserAdmin | New-IMUser | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/users/{id} | getUserAdmin | Get-IMUser | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /admin/users/{id} | updateUserAdmin | Set-IMUser | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| DELETE /admin/users/{id} | deleteUserAdmin | Remove-IMUser | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/users/{id}/calendar-heatmap | getUserCalendarHeatmapAdmin | No public caller found | No structural delta detected | Existing exclusion: Dashboard visualisation data (calendar heatmap) for the web UI | excluded |
| GET /admin/users/{id}/preferences | getUserPreferencesAdmin | Get-IMUserPreference | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /admin/users/{id}/preferences | updateUserPreferencesAdmin | Set-IMUserPreference | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| POST /admin/users/{id}/restore | restoreUserAdmin | Restore-IMUser | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/users/{id}/sessions | getUserSessionsAdmin | Get-IMUserSession | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /admin/users/{id}/statistics | getUserStatisticsAdmin | Get-IMUserStatistic | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /albums | getAllAlbums | Get-IMAlbum | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /albums | createAlbum | New-IMAlbum | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /albums/assets | addAssetsToAlbums | No public caller found | No structural delta detected | Existing exclusion: Functionality covered by Set-IMAsset -AddToAlbum parameter. This API is more efficient when adding multiple assets to multiple albums at the same time. | excluded |
| GET /albums/statistics | getAlbumStatistics | Get-IMAlbumStatistic | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /albums/{id} | getAlbumInfo | Get-IMAlbum | No structural delta detected | Review mappings and test behavior | needs-change |
| PATCH /albums/{id} | updateAlbumInfo | Rename-IMAlbum, Set-IMAlbum | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /albums/{id} | deleteAlbum | Remove-IMAlbum | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /albums/{id}/assets | addAssetsToAlbum | Set-IMAlbum, Set-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /albums/{id}/assets | removeAssetFromAlbum | Set-IMAlbum, Set-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /albums/{id}/map-markers | getAlbumMapMarkers | Get-IMAlbumMapMarker | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /albums/{id}/user/{userId} | updateAlbumUser | Set-IMAlbumUser | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /albums/{id}/user/{userId} | removeUserFromAlbum | Remove-IMAlbumUser | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /albums/{id}/users | addUsersToAlbum | Add-IMAlbumUser | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /api-keys | getApiKeys | Get-IMAPIKey | DTO: Permission | Review mappings and test behavior | needs-change |
| POST /api-keys | createApiKey | New-IMAPIKey | DTO: Permission | Review mappings and test behavior | needs-change |
| GET /api-keys/me | getMyApiKey | No public caller found | DTO: Permission | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| GET /api-keys/{id} | getApiKey | Get-IMAPIKey | DTO: Permission | Review mappings and test behavior | needs-change |
| PUT /api-keys/{id} | updateApiKey | Rename-IMAPIKey | operation: deprecated, tags, x-immich-history, x-immich-state; DTO: Permission | Review mappings and test behavior | needs-change |
| DELETE /api-keys/{id} | deleteApiKey | Remove-IMAPIKey | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /api-keys/{id}/rotate | rotateApiKey | Reset-IMAPIKey | DTO: Permission | Review mappings and test behavior | needs-change |
| GET /asset-files | searchAssetFiles | Get-IMAssetFile | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /asset-files/{id} | getAssetFile | Get-IMAssetFile, Save-IMAssetFile | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /asset-files/{id} | deleteAssetFile | No public caller found | No structural delta detected | Existing exclusion: Deleting generated asset derivatives (previews, thumbnails, sidecars) can break the server's media state; not exposed by the module | excluded |
| GET /asset-files/{id}/download | downloadAssetFile | Save-IMAssetFile | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /assets | uploadAsset | No public caller found | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /assets | updateAssets | Set-IMAsset | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| DELETE /assets | deleteAssets | Remove-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /assets/bulk-upload-check | checkBulkUpload | No public caller found | No structural delta detected | Existing exclusion: Mobile app specific | excluded |
| PUT /assets/copy | copyAsset | Copy-IMAssetInfo | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /assets/jobs | runAssetJobs | Start-IMVideoTranscode, Update-IMAssetMetadata, Update-IMAssetThumbnail | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /assets/metadata | updateBulkAssetMetadata | Set-IMAssetMetadata | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /assets/metadata | deleteBulkAssetMetadata | Remove-IMAssetMetadata | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /assets/statistics | getAssetStatistics | Get-IMAssetStatistic | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /assets/{id} | getAssetInfo | Get-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /assets/{id} | updateAsset | Set-IMAsset | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| GET /assets/{id}/edits | getAssetEdits | Get-IMAssetEdit | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /assets/{id}/edits | editAsset | Set-IMAssetEdit | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /assets/{id}/edits | removeAssetEdits | Remove-IMAssetEdit | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /assets/{id}/metadata | getAssetMetadata | No public caller found | No structural delta detected | Existing exclusion: Mobile sync exclusive - used for storing IcloudId for assets | excluded |
| PUT /assets/{id}/metadata | updateAssetMetadata | No public caller found | No structural delta detected | Existing exclusion: Mobile sync exclusive - used for storing IcloudId for assets | excluded |
| GET /assets/{id}/metadata/{key} | getAssetMetadataByKey | No public caller found | No structural delta detected | Existing exclusion: Mobile sync exclusive - used for storing IcloudId for assets | excluded |
| DELETE /assets/{id}/metadata/{key} | deleteAssetMetadata | No public caller found | No structural delta detected | Existing exclusion: Mobile sync exclusive - used for storing IcloudId for assets | excluded |
| GET /assets/{id}/ocr | getAssetOcr | Get-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /assets/{id}/original | downloadAsset | Save-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /assets/{id}/thumbnail | viewAsset | Export-IMAssetThumbnail | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /assets/{id}/video/playback | playAssetVideo | No public caller found | No structural delta detected | Existing exclusion: Video playback endpoint - not relevant for PowerShell module | excluded |
| GET /assets/{id}/video/stream/main.m3u8 | getMainPlaylist | No public caller found | No structural delta detected | Existing exclusion: HLS video streaming for the web player; not applicable to a PowerShell module | excluded |
| DELETE /assets/{id}/video/stream/{sessionId} | endSession | No public caller found | No structural delta detected | Existing exclusion: Ends an HLS streaming session for the web player; not applicable to a PowerShell module | excluded |
| GET /assets/{id}/video/stream/{sessionId}/{variantIndex}/playlist.m3u8 | getMediaPlaylist | No public caller found | No structural delta detected | Existing exclusion: HLS playlist for the web player; not applicable to a PowerShell module | excluded |
| GET /assets/{id}/video/stream/{sessionId}/{variantIndex}/{filename} | getSegment | No public caller found | No structural delta detected | Existing exclusion: HLS segment delivery for the web player; not applicable to a PowerShell module | excluded |
| POST /auth/admin-sign-up | signUpAdmin | No public caller found | No structural delta detected | Existing exclusion: Admin setup - not suitable for interactive use | excluded |
| POST /auth/change-password | changePassword | No public caller found | No structural delta detected | Existing exclusion: Interactive web operation | excluded |
| POST /auth/login | login | No public caller found | No structural delta detected | Existing exclusion: Login is handled by the ImmichSession class via Connect-Immich (source/classes/ImmichSession.class.ps1); not a user-facing endpoint | excluded |
| POST /auth/logout | logout | Disconnect-Immich | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /auth/pin-code | setupPinCode | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint for interactive web UI - not suitable for PowerShell automation | excluded |
| PUT /auth/pin-code | changePinCode | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint for interactive web UI - not suitable for PowerShell automation | excluded |
| DELETE /auth/pin-code | resetPinCode | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint for interactive web UI - not suitable for PowerShell automation | excluded |
| POST /auth/session/lock | lockAuthSession | No public caller found | No structural delta detected | Existing exclusion: Interactive web session management - not applicable for PowerShell automation | excluded |
| POST /auth/session/unlock | unlockAuthSession | No public caller found | No structural delta detected | Existing exclusion: Interactive web session management - not applicable for PowerShell automation | excluded |
| GET /auth/status | getAuthStatus | No public caller found | No structural delta detected | Existing exclusion: Interactive web session status - not applicable for PowerShell automation | excluded |
| POST /auth/validateToken | validateAccessToken | Test-IMAccessToken | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /cluster-groups/requests | getClusterGroupRequests | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| DELETE /cluster-groups/requests/{id} | deleteClusterGroupRequest | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| POST /cluster-groups/requests/{id}/accept | acceptClusterGroupRequest | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| POST /cluster-groups/{id}/leave | leaveClusterGroup | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| POST /cluster-groups/{id}/regenerate-people | clusterGroupRegeneratePeople | No public caller found | operation: x-immich-permission | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| GET /cluster-groups/{id}/requests | getClusterGroupRequestsForGroup | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| PUT /cluster-groups/{id}/requests | createClusterGroupRequest | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| GET /cluster-groups/{id}/users | getClusterGroupUsers | No public caller found | No structural delta detected | Existing exclusion: Server federation (cluster groups) is administered from the web UI; out of scope for the module | excluded |
| GET /config | getUserConfig | No public caller found | DTO: UserConfigDto, UserConfigNotificationsDto, UserConfigOAuthDto, UserConfigPasskeyDto, UserConfigSmtpDto, UserConfigThemeDto | Existing exclusion: User-facing web UI feature flags and login configuration; server settings are covered by Get-IMServer | excluded |
| GET /config/defaults | getUserConfigDefaults | No public caller found | DTO: UserConfigDto, UserConfigNotificationsDto, UserConfigOAuthDto, UserConfigPasskeyDto, UserConfigSmtpDto, UserConfigThemeDto | Existing exclusion: Web UI default feature configuration; server settings are covered by Get-IMServer | excluded |
| POST /download/archive | downloadArchive | No public caller found | No structural delta detected | Existing exclusion: Use Save-IMAsset instead | excluded |
| POST /download/info | getDownloadInfo | No public caller found | No structural delta detected | Existing exclusion: Web frontend specific | excluded |
| GET /duplicates | getAssetDuplicates | Get-IMDuplicate | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /duplicates | deleteDuplicates | Remove-IMDuplicate | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /duplicates/resolve | resolveDuplicates | Resolve-IMDuplicate | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /duplicates/{id} | deleteDuplicate | No public caller found | No structural delta detected | Existing exclusion: Batch-version of this api is implemented as Remove-IMDuplicate | excluded |
| GET /faces | getFaces | Get-IMFace | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /faces | createFace | New-IMFace | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /faces/{id} | reassignFacesById | Set-IMFace | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /faces/{id} | deleteFace | Remove-IMFace | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /jobs | getQueuesLegacy | No public caller found | DTO: QueueStatisticsDto | Existing exclusion: Deprecated; superseded by the queue endpoints covered by Get-IMQueue | excluded |
| POST /jobs | createJob | Start-IMJob | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /jobs/{name} | runQueueCommandLegacy | Clear-IMJob, Start-IMJob | DTO: QueueStatisticsDto | Review mappings and test behavior | needs-change |
| GET /libraries | getAllLibraries | Get-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /libraries | createLibrary | New-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /libraries/{id} | getLibrary | Get-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /libraries/{id} | updateLibrary | Set-IMLibrary | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| DELETE /libraries/{id} | deleteLibrary | Remove-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /libraries/{id}/scan | scanLibrary | Sync-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /libraries/{id}/statistics | getLibraryStatistics | Get-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /libraries/{id}/validate | validate | Test-IMLibrary | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /map/markers | getMapMarkers | Get-IMMapMarker | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /map/reverse-geocode | reverseGeocode | Convert-IMCoordinatesToLocation | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /memories | searchMemories | Get-IMMemory | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /memories | createMemory | New-IMMemory | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /memories/statistics | memoriesStatistics | Get-IMMemory | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /memories/{id} | getMemory | Get-IMMemory | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /memories/{id} | updateMemory | Set-IMMemory | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| DELETE /memories/{id} | deleteMemory | Remove-IMMemory | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /memories/{id}/assets | addMemoryAssets | Set-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /memories/{id}/assets | removeMemoryAssets | Set-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /notifications | getNotifications | No public caller found | No structural delta detected | Existing exclusion: Web application 'me' context only - not suitable for PowerShell automation | excluded |
| PUT /notifications | updateNotifications | No public caller found | No structural delta detected | Existing exclusion: Web application 'me' context only - not suitable for PowerShell automation | excluded |
| DELETE /notifications | deleteNotifications | No public caller found | No structural delta detected | Existing exclusion: Web application 'me' context only - not suitable for PowerShell automation | excluded |
| GET /notifications/{id} | getNotification | No public caller found | No structural delta detected | Existing exclusion: Web application 'me' context only - not suitable for PowerShell automation | excluded |
| PUT /notifications/{id} | updateNotification | No public caller found | No structural delta detected | Existing exclusion: Web application 'me' context only - not suitable for PowerShell automation | excluded |
| DELETE /notifications/{id} | deleteNotification | No public caller found | No structural delta detected | Existing exclusion: Web application 'me' context only - not suitable for PowerShell automation | excluded |
| POST /oauth/authorize | startOAuth | No public caller found | No structural delta detected | Existing exclusion: OIDC web flow - not for interactive use | excluded |
| POST /oauth/backchannel-logout | logoutOAuth | No public caller found | No structural delta detected | Existing exclusion: Identity provider back-channel logout callback; invoked by the IdP, not by a client | excluded |
| POST /oauth/callback | finishOAuth | No public caller found | No structural delta detected | Existing exclusion: OIDC web flow - not for interactive use | excluded |
| POST /oauth/link | linkOAuthAccount | No public caller found | No structural delta detected | Existing exclusion: OIDC web flow - not for interactive use | excluded |
| GET /oauth/mobile-redirect | redirectOAuthToMobile | No public caller found | No structural delta detected | Existing exclusion: Mobile app specific | excluded |
| POST /oauth/unlink | unlinkOAuthAccount | No public caller found | No structural delta detected | Existing exclusion: OIDC web flow - not for interactive use | excluded |
| GET /partners | getPartners | Get-IMPartner | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /partners | createPartner | Add-IMPartner | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /partners/{id} | createPartnerDeprecated | No public caller found | No structural delta detected | Existing exclusion: Deprecated; superseded by POST /partners, covered by Add-IMPartner | excluded |
| PUT /partners/{id} | updatePartner | Set-IMPartner | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /partners/{id} | removePartner | Remove-IMPartner | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /passkeys | searchPasskeys | Get-IMPasskey | New operation | Unit and read-only live listing passed; contract review remains | needs-change |
| POST /passkeys/authentication/finish | finishAuthentication | No public caller found | New operation | Deferred by maintainer; owner: maintainer | blocked |
| POST /passkeys/authentication/start | startAuthentication | No public caller found | New operation | Deferred by maintainer; owner: maintainer | blocked |
| POST /passkeys/registration/finish | finishRegistration | No public caller found | New operation | Deferred by maintainer; owner: maintainer | blocked |
| POST /passkeys/registration/start | startRegistration | No public caller found | New operation | Deferred by maintainer; owner: maintainer | blocked |
| GET /passkeys/{id} | getPasskey | Get-IMPasskey | New operation | Unit tests passed; live retrieval skipped without a passkey | needs-change |
| PATCH /passkeys/{id} | updatePasskey | Rename-IMPasskey | New operation | Unit tests passed; no disposable passkey for live test | needs-change |
| DELETE /passkeys/{id} | deletePasskey | Remove-IMPasskey | New operation | Unit tests passed; no disposable passkey for live test | needs-change |
| GET /people | getAllPeople | Get-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /people | createPerson | New-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /people | updatePeople | Set-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /people | deletePeople | Remove-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /people/merge | mergePeople | Merge-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /people/users | getUsersForPeople | Get-IMPersonAccess | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /people/users | upsertPeopleUsers | Add-IMPersonAccess | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /people/users | removeUsersFromPeople | Remove-IMPersonAccess | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /people/{id} | getPerson | Get-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /people/{id} | updatePerson | No public caller found | operation: deprecated, tags, x-immich-history, x-immich-state | Existing exclusion: Single item version of batch API | excluded |
| DELETE /people/{id} | deletePerson | No public caller found | No structural delta detected | Existing exclusion: Batch-version of this api is implemented as Remove-IMPerson | excluded |
| POST /people/{id}/merge | mergePersonLegacy | No public caller found | No structural delta detected | Existing exclusion: Deprecated; superseded by POST /people/merge, covered by the person merge cmdlet | excluded |
| PUT /people/{id}/reassign | reassignFaces | No public caller found | No structural delta detected | Existing exclusion: Unclear usage - no documentation | excluded |
| GET /people/{id}/statistics | getPersonStatistics | Get-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /people/{id}/thumbnail | getPersonThumbnail | Export-IMPersonThumbnail | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /plugins | searchPlugins | Get-IMPlugin | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /plugins/methods | searchPluginMethods | Get-IMPluginMethod | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| GET /plugins/templates | searchPluginTemplates | Get-IMPluginTemplate | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| GET /plugins/{id} | getPlugin | Get-IMPlugin | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /public/config | getPublicConfig | Get-IMServer -PublicConfiguration | DTO: PublicConfigDto, PublicConfigFFmpegDto, PublicConfigFFmpegRealtimeDto, PublicConfigMapDto, PublicConfigPasskeyDto, PublicConfigThemeDto | Unit and read-only live checks passed; complete contract review remains | needs-change |
| GET /public/config/defaults | getPublicConfigDefaults | No public caller found | DTO: PublicConfigDto, PublicConfigFFmpegDto, PublicConfigFFmpegRealtimeDto, PublicConfigMapDto, PublicConfigPasskeyDto, PublicConfigThemeDto | Existing exclusion: Public login-page defaults for the web UI; covered by Get-IMServer -Theme and public configuration | excluded |
| GET /queues | getQueues | Get-IMJob, Get-IMQueue | DTO: QueueStatisticsDto | Review mappings and test behavior | needs-change |
| GET /queues/{name} | getQueue | Get-IMQueue | DTO: QueueStatisticsDto | Review mappings and test behavior | needs-change |
| PUT /queues/{name} | updateQueue | Resume-IMJob, Suspend-IMJob, Set-IMQueue | DTO: QueueStatisticsDto | Review mappings and test behavior | needs-change |
| GET /queues/{name}/jobs | getQueueJobs | Get-IMQueueJob | DTO: JobName | Review mappings and test behavior | needs-change |
| DELETE /queues/{name}/jobs | emptyQueue | Clear-IMJob, Clear-IMQueue | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /search/cities | getAssetsByCity | No public caller found | No structural delta detected | Existing exclusion: Web places-page feature (one thumbnail per city); no PowerShell use case. Find-IMCity removed. | excluded |
| GET /search/explore | getExploreData | Find-IMExploreData | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /search/large-assets | searchLargeAssets | Get-IMTopLargestAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /search/metadata | searchAssets | Get-IMAlbum, Search-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /search/person | searchPerson | Find-IMPerson | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /search/places | searchPlaces | Find-IMPlace | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /search/random | searchRandom | Get-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /search/smart | searchSmart | Search-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /search/statistics | searchAssetStatistics | No public caller found | No structural delta detected | Existing exclusion: Unclear usefulness in our scenario, just returns a count, probably useful for web UI | excluded |
| GET /search/suggestions | getSearchSuggestions | No public caller found | No structural delta detected | Existing exclusion: Interactive search - not applicable for PowerShell | excluded |
| GET /server/about | getAboutInfo | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/apk-links | getApkLinks | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/config | getServerConfig | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/features | getServerFeatures | Get-IMServer | DTO: ServerFeaturesDto | Review mappings and test behavior | needs-change |
| GET /server/license | getServerLicense | Get-IMServerLicense | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /server/license | setServerLicense | Set-IMServerLicense | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /server/license | deleteServerLicense | Remove-IMServerLicense | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/media-types | getSupportedMediaTypes | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/ping | pingServer | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/statistics | getServerStatistics | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/storage | getStorage | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/version | getServerVersion | Get-IMServer -Version | DTO: ServerVersionResponseDto | Feature level exposed and unit tested; complete contract review remains | needs-change |
| GET /server/version-check | getVersionCheck | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /server/version-history | getVersionHistory | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /sessions | getSessions | Get-IMAuthSession | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /sessions | createSession | No public caller found | No structural delta detected | Existing exclusion: Not relevant for PowerShell module | excluded |
| DELETE /sessions | deleteAllSessions | Remove-IMAuthSession | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /sessions/{id} | updateSession | No public caller found | operation: deprecated, tags, x-immich-history, x-immich-state | Existing exclusion: Not relevant for PowerShell module | excluded |
| DELETE /sessions/{id} | deleteSession | Remove-IMAuthSession | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /sessions/{id}/lock | lockSession | No public caller found | No structural delta detected | Existing exclusion: Not relevant for PowerShell module | excluded |
| GET /shared-links | getAllSharedLinks | Get-IMSharedLink | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /shared-links | createSharedLink | New-IMSharedLink | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /shared-links/login | sharedLinkLogin | No public caller found | No structural delta detected | Existing exclusion: Creates an anonymous, password-protected shared-link session for the web viewer; outside the module's authenticated session model | excluded |
| GET /shared-links/me | getMySharedLink | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| GET /shared-links/{id} | getSharedLinkById | Get-IMSharedLink | No structural delta detected | Review mappings and test behavior | needs-change |
| PATCH /shared-links/{id} | updateSharedLink | Set-IMSharedLink | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /shared-links/{id} | removeSharedLink | Remove-IMSharedLink | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /shared-links/{id}/assets | addSharedLinkAssets | Add-IMSharedLinkAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /shared-links/{id}/assets | removeSharedLinkAssets | Remove-IMSharedLinkAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /stacks | searchStacks | Get-IMStack | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /stacks | createStack | New-IMStack | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /stacks | deleteStacks | Remove-IMStack | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /stacks/{id} | getStack | Get-IMStack | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /stacks/{id} | updateStack | Set-IMStack | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| DELETE /stacks/{id} | deleteStack | No public caller found | No structural delta detected | Existing exclusion: Redundant with bulk DELETE /stacks, which Remove-IMStack already uses | excluded |
| DELETE /stacks/{id}/assets/{assetId} | removeAssetFromStack | Remove-IMStackAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /sync/ack | getSyncAck | No public caller found | No structural delta detected | Existing exclusion: Internal sync mechanism - not for direct use | excluded |
| POST /sync/ack | sendSyncAck | No public caller found | No structural delta detected | Existing exclusion: Internal sync mechanism - not for direct use | excluded |
| DELETE /sync/ack | deleteSyncAck | No public caller found | No structural delta detected | Existing exclusion: Internal sync mechanism - not for direct use | excluded |
| POST /sync/stream | getSyncStream | No public caller found | No structural delta detected | Existing exclusion: Internal sync mechanism - not for direct use | excluded |
| GET /system-config | getConfig | No public caller found | DTO: AdminConfigBackupsDto, AdminConfigDto, AdminConfigPasskeyDto, ImageFormat | Existing exclusion: Deprecated; superseded by /admin/config, covered by Get-IMServer -AppliedSystemConfiguration | excluded |
| PUT /system-config | updateConfig | No public caller found | DTO: AdminConfigBackupsDto, AdminConfigDto, AdminConfigPasskeyDto, ImageFormat | Existing exclusion: Deprecated; superseded by /admin/config, covered by Set-IMServer | excluded |
| GET /system-config/defaults | getConfigDefaults | No public caller found | DTO: AdminConfigBackupsDto, AdminConfigDto, AdminConfigPasskeyDto, ImageFormat | Existing exclusion: Deprecated; superseded by /admin/config/defaults, covered by Get-IMServer -DefaultSystemConfiguration | excluded |
| GET /system-config/storage-template-options | getStorageTemplateOptions | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /system-metadata/admin-onboarding | getAdminOnboarding | No public caller found | No structural delta detected | Existing exclusion: Admin setup - web specific | excluded |
| POST /system-metadata/admin-onboarding | updateAdminOnboarding | No public caller found | No structural delta detected | Existing exclusion: Admin setup - web specific | excluded |
| GET /system-metadata/reverse-geocoding-state | getReverseGeocodingState | No public caller found | No structural delta detected | Existing exclusion: Internal state - unclear usage | excluded |
| GET /system-metadata/version-check-state | getVersionCheckState | Get-IMServer | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /tags | getAllTags | Get-IMTag | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /tags | createTag | New-IMTag | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /tags | upsertTags | No public caller found | No structural delta detected | Existing exclusion: Batch operation easily replicated in PowerShell | excluded |
| PUT /tags/assets | bulkTagAssets | No public caller found | No structural delta detected | Existing exclusion: Batch operation easily replicated in PowerShell | excluded |
| GET /tags/{id} | getTagById | Get-IMTag | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /tags/{id} | updateTag | Set-IMTag | operation: deprecated, tags, x-immich-history, x-immich-state | Review mappings and test behavior | needs-change |
| DELETE /tags/{id} | deleteTag | Remove-IMTag | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /tags/{id}/assets | tagAssets | Set-IMAsset, Set-IMTag | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /tags/{id}/assets | untagAssets | Set-IMAsset, Set-IMTag | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /timeline/bucket | getTimeBucket | Get-IMTimeBucket | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /timeline/buckets | getTimeBuckets | Get-IMTimeBucket | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /trash/empty | emptyTrash | Start-IMJob | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /trash/restore | restoreTrash | Restore-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| POST /trash/restore/assets | restoreAssets | Restore-IMAsset | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /users | searchUsers | No public caller found | No structural delta detected | Existing exclusion: End user API, PSImmich supports only admin operations, in this case through Get-IMUser and /admin/users | excluded |
| GET /users/me | getMyUser | Get-IMUser | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /users/me | updateMyUser | No public caller found | operation: deprecated, tags, x-immich-history, x-immich-state | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| GET /users/me/calendar-heatmap | getMyCalendarHeatmap | No public caller found | No structural delta detected | Existing exclusion: Dashboard visualisation data (calendar heatmap) for the web UI | excluded |
| GET /users/me/license | getUserLicense | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| PUT /users/me/license | setUserLicense | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| DELETE /users/me/license | deleteUserLicense | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| GET /users/me/onboarding | getUserOnboarding | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| PUT /users/me/onboarding | setUserOnboarding | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| DELETE /users/me/onboarding | deleteUserOnboarding | No public caller found | No structural delta detected | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| GET /users/me/preferences | getMyPreferences | Get-IMUserPreference | No structural delta detected | Review mappings and test behavior | needs-change |
| PUT /users/me/preferences | updateMyPreferences | No public caller found | operation: deprecated, tags, x-immich-history, x-immich-state | Existing exclusion: User-specific endpoint - admin-focused module excludes /me endpoints | excluded |
| POST /users/profile-image | createProfileImage | Add-IMMyProfilePicture | No structural delta detected | Review mappings and test behavior | needs-change |
| DELETE /users/profile-image | deleteProfileImage | Remove-IMMyProfilePicture | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /users/{id} | getUser | No public caller found | No structural delta detected | Existing exclusion: Single-user admin lookup; Get-IMUser (list) returns the same user data. Revisit if a direct lookup is needed for non-admin users | excluded |
| GET /users/{id}/profile-image | getProfileImage | Export-IMProfilePicture | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /view/folder | getAssetsByOriginalPath | Get-IMAssetFolder | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /view/folder/unique-paths | getUniqueOriginalPaths | Get-IMAssetFolder | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /workflows | searchWorkflows | Get-IMWorkflow | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| POST /workflows | createWorkflow | New-IMWorkflow | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| GET /workflows/triggers | getWorkflowTriggers | Get-IMWorkflowTrigger | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| GET /workflows/{id} | getWorkflow | Get-IMWorkflow | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| PUT /workflows/{id} | updateWorkflow | Set-IMWorkflow | operation: deprecated, tags, x-immich-history, x-immich-state; DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |
| DELETE /workflows/{id} | deleteWorkflow | Remove-IMWorkflow | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /workflows/{id}/logs | getWorkflowLogs | Get-IMWorkflowLog | No structural delta detected | Review mappings and test behavior | needs-change |
| GET /workflows/{id}/share | getWorkflowForShare | Get-IMWorkflow | DTO: WorkflowTrigger | Review mappings and test behavior | needs-change |

## Next actions

1. Review every remaining eligible ledger row and affected public parameter
   mapping, including nullable DTO properties and changed configuration fields.
2. Audit existing exclusions and direct REST calls; resolve the separately
   deferred maintenance and WebAuthn operations with the maintainer.
3. Rerun full verification after the latest batches and obtain explicit
   approval for each further live run. Create disposable passkeys before any
   live update/delete tests and restore state afterwards.
4. The maintainer retains PR creation, review, merge and release initiation.

## Learning (2026-11-11)

The local final-version spec differs in bytes from the upstream file because of
formatting. A recursive parsed-object comparison established equivalence without
mistaking a byte-hash mismatch for a contract mismatch. The same check should be
used before replacing a contributor's downloaded spec.
