# PSImmich Copilot Instructions

## Project Overview
PSImmich is a PowerShell API wrapper module for the Immich photo management system. The project follows PowerShell module development best practices with automated build/test pipelines and comprehensive API coverage tracking.

## Meta-Instructions for Copilot Enhancement
**Continuous Improvement**: While working on this project, actively identify opportunities to enhance these copilot instructions. When you encounter:
- **New development patterns** that work well and should be standardized
- **Common pitfalls** that future development should avoid
- **Workflow improvements** discovered during implementation
- **Missing documentation** for existing processes or architectural decisions
- **Best practices** that emerge from successful implementations

**Suggest specific additions or updates** to this copilot instructions file. Frame suggestions as concrete text additions with clear reasoning for why the improvement would benefit future development sessions. This creates a self-improving documentation system where each development session can contribute to better guidance for subsequent work.

**Documentation Scope**: Focus suggestions on actionable guidance that would help an AI assistant (or human developer) work more effectively with this specific codebase, rather than general PowerShell or software development advice.

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
- **Unit Tests**: Pester 5 framework with comprehensive test coverage goal - currently has placeholder tests for all cmdlets in `tests/Unit/Public/Public.Tests.ps1`
- **Integration Tests**: Real API calls in `tests/Integration/integration.tests.ps1`
- **QA Tests**: Module-level quality tests in `tests/QA/module.tests.ps1`

### Test Execution Guidelines
**CRITICAL**: Always run tests after making code changes to verify functionality and catch regressions early.

#### When to Run Tests
- **Immediately after creating/modifying any function**: Run targeted tests to verify changes work as expected
- **Before completing any development session**: Run full test suite to ensure no regressions introduced
- **After fixing test failures**: Re-run specific failing tests to confirm fixes work
- **During active development**: Use targeted test tags to focus on current work area

#### Test Running Commands
```powershell
# Run all tests (comprehensive verification)
./build.ps1 -Tasks test

# Run specific test categories using tags
./build.ps1 -Tasks test -PesterTag "ConvertTo-ApiParameters"     # Single function
./build.ps1 -Tasks test -PesterTag "Get-IMLibrary"              # Specific cmdlet
./build.ps1 -Tasks test -PesterTag "Unit"                       # All unit tests
./build.ps1 -Tasks test -PesterTag "Integration"                # Integration tests only

# Run tests for specific file/context (when working on particular areas)
./build.ps1 -Tasks test -PesterPath "tests/Unit/Private/Private.Tests.ps1"
./build.ps1 -Tasks test -PesterPath "tests/Unit/Public/Public.Tests.ps1"
```

#### Test Execution Workflow
1. **Start with Targeted Tests**: When working on specific functions, use tags to run only relevant tests for faster feedback
2. **Verify Fixes Immediately**: After fixing a failing test, re-run that specific test to confirm the fix works
3. **Full Test Suite Before Completion**: Always run full test suite before considering work complete
4. **Check Test Output**: Pay attention to test timing, coverage reports, and any warnings in output
5. **Handle Test Failures Promptly**: Don't proceed with new development if tests are failing - fix them first

#### Common Test Failure Patterns and Solutions
- **Mock Parameter Mismatches**: Check `ParameterFilter` blocks match actual mock parameter names (e.g., `$Name` vs `$CommandName`)
- **Reflection-Based Function Testing**: Complex functions using `Get-Command` require sophisticated mocking with `GetType().Name` simulation
- **Pester 5 Syntax**: Use `Should -Invoke` instead of deprecated `Assert-MockCalled`; ensure proper parameter filter syntax
- **Build Process Errors**: InvokeBuild version compatibility issues may require dependency version pinning
- **Coverage Conversion Failures**: Module structure changes may require build system adjustments

#### Test Development Best Practices
- **Mock Realistically**: Use actual API response structures in mocks, not minimal test data
- **Test Edge Cases**: Include validation failures, empty inputs, and boundary conditions
- **Verify All Parameter Sets**: Each parameter set should have dedicated test contexts
- **Cache Testing**: For performance-critical functions with caching, verify cache behavior works correctly
- **Session Parameter Testing**: Ensure explicit session parameters are properly passed through to underlying functions

#### Unit Testing Standards
**Goal**: Achieve comprehensive unit test coverage for all public cmdlets, replacing placeholder "Should be true" tests with robust, isolated testing.

**Current State**: Quality gate ensures unit test blocks exist for all cmdlets, but most contain only placeholder tests. `Get-IMLibrary` serves as the reference implementation for comprehensive unit testing patterns.

**Unit Test Requirements**:
- **Complete Isolation**: Mock all external dependencies, especially `InvokeImmichRestMethod` calls
- **Parameter Set Coverage**: Test all parameter sets (e.g., 'list', 'id', 'random') individually
- **Pipeline Support**: Test both `ValueFromPipeline` and `ValueFromPipelineByPropertyName` functionality
- **Parameter Validation**: Test both valid inputs and validation failures (e.g., invalid GUIDs)
- **Edge Cases**: Test multiple IDs, empty results, optional switches (like `IncludeStatistics`)
- **Session Handling**: Verify session parameters are passed correctly to underlying functions
- **Pester 5 Syntax**: Use `Should -Invoke` instead of deprecated `Assert-MockCalled`

**Mock Pattern**: Mock `InvokeImmichRestMethod` with switch-based responses that return realistic data structures matching actual API responses. Use regex patterns for RelativePath matching to handle dynamic IDs.

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
- **Unit Test Implementation**: When implementing new cmdlets, create comprehensive unit tests following the `Get-IMLibrary` pattern instead of placeholder tests
- **Changelog Focus**: Only include user-facing changes in changelog - omit test updates, integration test changes, and internal test improvements

### Unit Testing Implementation Workflow
When creating or updating cmdlets, follow this testing approach:

1. **Mock Setup**: Create comprehensive mocks for `InvokeImmichRestMethod` with realistic API response data
2. **Parameter Set Testing**: Write separate test contexts for each parameter set (list, id, etc.)
3. **Validation Testing**: Test parameter validation patterns, especially GUID formats and required parameters
4. **Pipeline Testing**: Verify pipeline input works correctly for both direct values and property names
5. **Session Testing**: Ensure session parameters are properly passed through to REST method calls
6. **Error Scenarios**: Test invalid inputs to ensure proper parameter validation occurs

**Reference Implementation**: Use `tests/Unit/Public/Public.Tests.ps1` around lines 312-536 (`Get-IMLibrary` tests) as the template for comprehensive unit test structure and patterns.
