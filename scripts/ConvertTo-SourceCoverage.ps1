[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]
    $ReportPath,

    [Parameter(Mandatory)]
    [string]
    $BuiltModulePath,

    [Parameter(Mandatory)]
    [string]
    $SourceDirectory
)

$ErrorActionPreference = 'Stop'

function Add-CoverageCounter
{
    param([System.Xml.XmlElement]$Parent)

    $lines = @($Parent.SelectNodes('.//line'))
    $counters = @(
        @{ Type = 'INSTRUCTION'; Missed = ($lines | Measure-Object -Property mi -Sum).Sum; Covered = ($lines | Measure-Object -Property ci -Sum).Sum }
        @{ Type = 'BRANCH'; Missed = ($lines | Measure-Object -Property mb -Sum).Sum; Covered = ($lines | Measure-Object -Property cb -Sum).Sum }
        @{ Type = 'LINE'; Missed = @($lines | Where-Object { [int]$_.ci -eq 0 }).Count; Covered = @($lines | Where-Object { [int]$_.ci -gt 0 }).Count }
    )
    foreach ($counter in $counters)
    {
        $element = $Parent.OwnerDocument.CreateElement('counter')
        $element.SetAttribute('type', $counter.Type)
        $element.SetAttribute('missed', [string][long]$counter.Missed)
        $element.SetAttribute('covered', [string][long]$counter.Covered)
        $null = $Parent.AppendChild($element)
    }
}

[xml]$inputReport = Get-Content -LiteralPath $ReportPath -Raw -ErrorAction Stop
$sourceFiles = @($inputReport.SelectNodes('/report/package/sourcefile'))
if ($sourceFiles.Count -ne 1 -or $sourceFiles[0].name -ne (Split-Path -Leaf $BuiltModulePath))
{
    throw 'Expected a JaCoCo coverage report for exactly the built module.'
}

# ModuleBuilder records the original file and line offsets in the merged module's regions.
$mappedLines = @($sourceFiles[0].SelectNodes('line') | ForEach-Object {
        [pscustomobject]@{
            File         = $BuiltModulePath
            Line         = [int]$_.nr
            CoverageLine = $_
        }
    } | ConvertTo-SourceLineNumber -Passthru)
$sourceLines = @(
    foreach ($mapping in $mappedLines)
    {
        $relativePath = $mapping.SourceFile -replace '^\.[\\/]', '' -replace '\\', '/'
        if ($relativePath -notmatch '^(Private|Public)/')
        {
            continue
        }
        $sourcePath = Join-Path $SourceDirectory $relativePath
        if ($mapping.SourceLineNumber -lt 1 -or -not (Test-Path -LiteralPath $sourcePath -PathType Leaf))
        {
            throw "Invalid source coverage mapping: '$relativePath' at line $($mapping.SourceLineNumber)."
        }
        [pscustomobject]@{
            RelativePath = $relativePath
            LineNumber   = $mapping.SourceLineNumber
            CoverageLine = $mapping.CoverageLine
        }
    }
)
if ($sourceLines.Count -eq 0)
{
    throw 'No coverage lines mapped to source/Public or source/Private.'
}

$report = [System.Xml.XmlDocument]::new()
$root = $report.CreateElement('report')
$root.SetAttribute('name', 'PowerShell source coverage')
$null = $report.AppendChild($root)
foreach ($session in $inputReport.SelectNodes('/report/sessioninfo'))
{
    $null = $root.AppendChild($report.ImportNode($session, $true))
}

foreach ($directory in $sourceLines | Group-Object { Split-Path -Parent $_.RelativePath } | Sort-Object Name)
{
    $package = $report.CreateElement('package')
    $package.SetAttribute('name', ('source/' + ($directory.Name -replace '\\', '/')))
    $null = $root.AppendChild($package)
    foreach ($file in $directory.Group | Group-Object RelativePath | Sort-Object Name)
    {
        $sourceFile = $report.CreateElement('sourcefile')
        $sourceFile.SetAttribute('name', (Split-Path -Leaf $file.Name))
        $null = $package.AppendChild($sourceFile)
        foreach ($line in $file.Group | Sort-Object LineNumber)
        {
            $element = $report.ImportNode($line.CoverageLine, $true)
            $element.SetAttribute('nr', [string]$line.LineNumber)
            $null = $sourceFile.AppendChild($element)
        }
        Add-CoverageCounter -Parent $sourceFile
    }
    Add-CoverageCounter -Parent $package
}
Add-CoverageCounter -Parent $root
$report.Save($ReportPath)
