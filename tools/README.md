# Development Tools

## API Parameter Validation

### tools/Validate-ApiParameters.ps1

This utility validates that PowerShell function parameters decorated with `[ApiParameter]` attributes correspond to actual parameters in the OpenAPI specification.

**Purpose:** Development tool for ensuring API parameter mappings are correct during active development.

**Important:** This utility may produce false positives when:
- API parameters use complex nested structures not directly mapped  
- Custom parameter handling is implemented
- OpenAPI spec doesn't fully match implementation

**Usage:**
```powershell
# Validate all functions
.\tools\Validate-ApiParameters.ps1

# Validate specific function
.\tools\Validate-ApiParameters.ps1 -FunctionName "Set-IMUserPreference"

# Use custom paths
.\tools\Validate-ApiParameters.ps1 -Path "source\Public" -OpenApiSpec "api\api.2.2.0.json"
```

**Output:** 
- Console output with validation results
- CSV export with detailed results for analysis
- Exit code 0 for success, 1 for validation failures

**Why it's not a test:** This validation was moved from the QA test suite because it can generate false positives during active development, particularly when:
1. Working on complex nested parameter mappings
2. Implementing custom parameter transformations  
3. API specifications are evolving

The tool is designed for development validation rather than build gate enforcement.
