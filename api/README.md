# PSImmich API Analysis Tools

This directory contains tools for analyzing PSImmich API coverage against OpenAPI specifications.

## Files

- **`Analyze-PSImmichAPI.ps1`** - Advanced API coverage analysis script
- **`exclusions.json`** - Configuration file for excluding web-frontend specific APIs
- **`api.2.2.0.json`** - OpenAPI specification for Immich v2.2.0 (target version)
- **`api.1.128.json`** - OpenAPI specification for Immich v1.128 (current version)

## Usage

### Basic Analysis
```powershell
# Analyze current coverage against v2.2.0 API
.\Analyze-PSImmichAPI.ps1 -ApiSpecFile "api.2.2.0.json"
```

### Comprehensive Analysis
```powershell
# Full analysis with parameters and folder validation
.\Analyze-PSImmichAPI.ps1 -ApiSpecFile "api.2.2.0.json" -ShowParameters -ShowFolderMismatches -ExportResults
```

### Custom Exclusions
```powershell
# Use custom exclusion configuration
.\Analyze-PSImmichAPI.ps1 -ApiSpecFile "api.2.2.0.json" -ExclusionConfigFile "my-exclusions.json"
```

## Script Features

### 1. API Coverage Analysis
- ✅ Identifies covered vs uncovered API endpoints
- ✅ Tracks deprecated APIs
- ✅ Shows coverage percentage excluding skipped APIs
- ✅ Color-coded console output (Green=Covered, Red=Uncovered, Gray=Skipped/Deprecated)

### 2. Parameter Analysis (`-ShowParameters`)
- ✅ Lists API parameters with required/optional status
- ✅ Compares against PowerShell function parameters
- ✅ Identifies missing parameter coverage

### 3. Folder Organization (`-ShowFolderMismatches`)
- ✅ Maps OpenAPI tags to suggested folder structure
- ✅ Identifies functions in incorrect folders
- ✅ Suggests reorganization based on API domains

### 4. Configurable Exclusions
- ✅ Skip web-frontend specific APIs
- ✅ Exclude mobile app specific endpoints  
- ✅ Handle special cases (login/logout mapped to Connect/Disconnect-Immich)
- ✅ JSON configuration for easy customization

### 5. Export Capabilities (`-ExportResults`)
- ✅ Export full results to CSV
- ✅ Separate export of uncovered APIs for prioritization
- ✅ Timestamped filenames for tracking progress

## Exclusion Configuration

The `exclusions.json` file contains two main sections:

### ExcludedPaths
APIs that are intentionally not implemented because they are:
- Web frontend specific (OAuth flows, admin signup)
- Mobile app specific (bulk upload checks)
- Streaming/interactive (video playback, search suggestions)
- Easily replicated in PowerShell (batch operations)

### ManualMappings  
APIs that are implemented but not detected by automatic analysis:
- `/auth/login` → `Connect-Immich`
- `/auth/logout` → `Disconnect-Immich`
- `/assets` POST → `Import-IMAsset`

## Tag to Folder Mappings

The script automatically maps OpenAPI tags to PowerShell folder structure:

| OpenAPI Tag    | PowerShell Folder |
| -------------- | ----------------- |
| Activities     | Activity          |
| Albums         | Album             |
| API Keys       | APIKey            |
| Assets         | Asset             |
| Authentication | Auth              |
| Downloads      | Asset             |
| Duplicates     | Duplicates        |
| Faces          | Face              |
| Jobs           | Job               |
| Libraries      | Library           |
| People         | Person            |
| Shared Links   | SharedLink        |
| System Config  | ServerConfig      |
| Users          | User              |

## Output Interpretation

### Coverage Statistics
- **Total APIs**: All endpoints in the OpenAPI spec
- **Covered**: Endpoints with corresponding PowerShell functions
- **Uncovered**: Endpoints missing PowerShell functions
- **Skipped**: Endpoints intentionally excluded
- **Deprecated**: Endpoints marked as deprecated in the API
- **Coverage %**: Covered / (Total - Skipped)

### Color Coding
- 🟢 **Green**: API is covered by a PowerShell function
- 🔴 **Red**: API is not covered (needs implementation)
- ⚫ **Gray**: API is skipped (excluded) or deprecated

## Upgrading from v1.128 to v2.2.0

1. **Run Analysis**: `.\Analyze-PSImmichAPI.ps1 -ApiSpecFile "api.2.2.0.json" -ExportResults`
2. **Review Uncovered**: Check the generated `api-uncovered-*.csv` file
3. **Prioritize**: Focus on core functionality APIs first
4. **Implement**: Create new functions following existing patterns
5. **Verify**: Re-run analysis to track progress
6. **Update Exclusions**: Add new web-specific APIs to `exclusions.json` as needed

## Best Practices

1. **Regular Analysis**: Run after each new function to track progress
2. **Export Results**: Keep CSV exports to track progress over time
3. **Review Exclusions**: Periodically review excluded APIs for relevance
4. **Validate Folders**: Use `-ShowFolderMismatches` to maintain organization
5. **Parameter Coverage**: Use `-ShowParameters` to ensure complete implementation
