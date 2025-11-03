# PSImmich Copilot Instructions

## Project Overview
PSImmich is a PowerShell API wrapper module for the Immich photo management system. The project follows PowerShell module development best practices with automated build/test pipelines and comprehensive API coverage tracking.

## Architecture Patterns

### Module Structure
- **Source Organization**: `source/` contains the development structure; `output/` contains built artifacts
- **Function Categories**: Public functions organized by Immich API domains (`Album/`, `Asset/`, `Auth/`, etc.)
- **Session Management**: Global `$script:ImmichSession` variable with optional explicit session parameters
- **Class-Based Session**: `ImmichSession.class.ps1` handles authentication and API state

### Core Components
- **`InvokeImmichRestMethod`**: Centralized REST API handler in `source/Private/`
- **API Versioning**: JSON specs in `api/` directory track Immich API versions (e.g., `api.2.2.0.json`)
- **Session Class**: Handles both AccessToken and Credential authentication methods
- **ModuleBuilder**: Uses Sampler framework for build automation (`build.yaml`, `build.ps1`)
- **Version Coupling**: PowerShell module version matches the supported Immich App API version

### Function Conventions
```powershell
# Standard pattern for all public functions
function Get-IMAsset {
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [ImmichSession]$Session = $null,  # Optional explicit session
        # ... other parameters
    )
    # Function uses $script:ImmichSession if $Session not provided
}
```

### "PowerShell Way" API Translation
- **Multiple REST endpoints in one cmdlet**: Combine related APIs for intuitive PowerShell experience
- **Parameter-driven behavior**: Use parameter sets to switch between REST endpoints (e.g., no ID = list API, with ID = single object API)
- **Natural PowerShell patterns**: Make cmdlets behave like native PowerShell commands rather than direct REST translations

### Authentication Patterns
- **Session Creation**: `Connect-Immich` creates global session or returns session object with `-PassThru`
- **Multi-Instance**: Support multiple Immich instances via explicit session parameters
- **Token Security**: AccessTokens stored as SecureString, converted in constructors

## Development Workflows

### Build System
```powershell
# Primary build commands (use existing tasks)
./build.ps1                    # Default build + test
./build.ps1 -Tasks test        # Run tests only
./build.ps1 -Tasks pack        # Build + package for release
```

### API Development
- **API Tracking**: `api/api.ps1` compares implemented functions against OpenAPI specs
- **Coverage Metrics**: Badge shows API endpoint coverage (currently 80% - 131/172 endpoints)
- **New Functions**: Follow existing pattern in appropriate `source/Public/{Domain}/` folder
- **Version Strategy**: Module version directly corresponds to supported Immich App API version (e.g., PSImmich v2.2.0 supports Immich API v2.2.0)

### Testing Strategy
- **Unit Tests**: Pester 5 framework, mostly placeholder tests in `tests/Unit/Public/Public.Tests.ps1`
- **Integration Tests**: Real API calls in `tests/Integration/integration.tests.ps1`
- **QA Tests**: Module-level quality tests in `tests/QA/module.tests.ps1`

## Critical Patterns

### GUID Validation
```powershell
# Standard GUID validation pattern used throughout
[ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
[string]$id
```

### REST Method Invocation
```powershell
# Standard REST call pattern
$Result = InvokeImmichRestMethod -Method GET -RelativePath 'assets' -ImmichSession $ImmichSession
```

### Parameter Sets
Use parameter sets for different function modes (e.g., 'list', 'id', 'random', 'deviceid') to provide clear usage patterns. This enables consolidating multiple REST endpoints into single PowerShell cmdlets - for example, `Get-IMAsset` without parameters calls the list API, while `Get-IMAsset -id <guid>` calls the single asset API.

## Key Files for New Development
- **Function Template**: Reference `source/Public/Asset/Get-IMAsset.ps1` for standard patterns
- **Session Logic**: Extend `source/Classes/ImmichSession.class.ps1` for auth features
- **API Mapping**: Update `api/api.ps1` when adding new endpoints
- **Build Config**: `build.yaml` defines ModuleBuilder and Sampler tasks

## Integration Points
- **Immich API**: REST endpoints documented in versioned JSON files
- **PowerShell Gallery**: Automated publishing via GitHub Actions
- **Documentation**: Uses platyPS for help generation and Docusaurus integration
- **Code Coverage**: Codecov integration tracks test coverage metrics

When implementing new features, prioritize consistency with existing patterns over novel approaches. The codebase emphasizes predictable parameter naming, consistent error handling through `InvokeImmichRestMethod`, and comprehensive parameter validation.

## API Implementation Workflow

### Discovery and Analysis
- **OpenAPI Exploration**: Use `api/Analyze-PSImmichAPI.ps1` to identify uncovered endpoints and understand API structure
- **Schema Research**: Examine DTO schemas (e.g., `StackCreateDto`, `StackResponseDto`) in OpenAPI spec for parameter requirements
- **Endpoint Mapping**: Check for bulk vs individual operations (e.g., `DELETE /stacks` vs `DELETE /stacks/{id}`)

### Implementation Strategy
- **Start with Get Operations**: Implement retrieve functions first as they're safest for testing
- **Progressive Implementation**: Get → New → Set → Remove → Asset Management operations
- **Validation Patterns**: Use `ValidateScript` for complex validation (e.g., minimum array counts, multi-GUID validation)
- **Confirmation Support**: Add `ShouldProcess` for destructive operations with appropriate `ConfirmImpact` levels

### Integration Testing Approach
- **Use Existing Assets**: Prefer existing test asset IDs over creating new assets for reliability and speed
- **Full Lifecycle Testing**: Test Create → Read → Update → Delete workflows in sequence
- **Cleanup Strategy**: Clean up test artifacts but preserve existing assets
- **Edge Case Validation**: Test both success and failure scenarios (e.g., invalid parameters)

### API Coverage Verification
- **Coverage Tracking**: Run analyzer after implementation to verify endpoints are detected
- **Documentation Updates**: Update coverage metrics and changelog with user-facing changes
- **Pattern Consistency**: Ensure new cmdlets follow established naming and parameter conventions
- **Changelog Focus**: Only include user-facing changes in changelog - omit test updates, integration test changes, and internal test improvements
