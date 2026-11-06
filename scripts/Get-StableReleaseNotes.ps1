[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]$Changelog,

    [Parameter(Mandatory)]
    [string]$PullRequestBody,

    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$newline = if ($Changelog.Contains("`r`n")) { "`r`n" } else { "`n" }
$text = $Changelog.Replace("`r`n", "`n")
$headings = [regex]::Matches($text, '(?m)^## (?<heading>[^\n]+)(?:\n|$)')
$releases = @(
    for ($i = 0; $i -lt $headings.Count; $i++)
    {
        $heading = $headings[$i]
        $match = [regex]::Match($heading.Groups['heading'].Value, '^\[?(?<version>\d+\.\d+\.\d+(?:-[A-Za-z][A-Za-z0-9]*)?)\]?(?=[ (]|$)')
        if ($match.Success)
        {
            $end = if ($i + 1 -lt $headings.Count) { $headings[$i + 1].Index } else { $text.Length }
            [pscustomobject]@{
                Version = $match.Groups['version'].Value
                Heading = $heading.Value.TrimEnd()
                Start   = $heading.Index
                End     = $end
                Notes   = $text.Substring($heading.Index + $heading.Length, $end - $heading.Index - $heading.Length)
            }
        }
        elseif ($heading.Groups['heading'].Value -ne '[Unreleased]')
        {
            throw "Unrecognized changelog heading: $($heading.Value.Trim())"
        }
    }
)

if ($releases.Count -eq 0 -or $releases[0].Version -ne $Version)
{
    throw "The first changelog release must match the tracked stable version '$Version'."
}

$result = [pscustomobject]@{
    Changelog       = $Changelog
    PullRequestBody = $PullRequestBody
    RolledUp        = $false
}
if ($releases.Count -lt 2 -or $releases[1].Version -notlike '*-*')
{
    return $result
}

$previousStable = 1
while ($previousStable -lt $releases.Count -and $releases[$previousStable].Version -like '*-*')
{
    $previousStable++
}
if ($previousStable -eq $releases.Count)
{
    throw 'Cannot roll up prerelease notes without a previous stable changelog entry.'
}
if ([version]$releases[$previousStable].Version -ge [version]$Version)
{
    throw 'The previous stable version must be older than the proposed release.'
}

$comparePattern = '\((?<prefix>https://[^ )]+/compare/)(?<base>[^ )]+)\.\.\.(?<tag>[^ )]+)\)'
$compare = [regex]::Match($releases[0].Heading, $comparePattern)
$oldestCompare = [regex]::Match($releases[$previousStable - 1].Heading, $comparePattern)
if (-not $compare.Success -or -not $oldestCompare.Success -or
    $compare.Groups['tag'].Value -cnotmatch "^v?$([regex]::Escape($Version))$" -or
    $oldestCompare.Groups['base'].Value -cnotmatch "^v?$([regex]::Escape($releases[$previousStable].Version))$" -or
    $compare.Groups['prefix'].Value -cne $oldestCompare.Groups['prefix'].Value)
{
    throw 'Cannot identify a consistent previous-stable comparison link.'
}

$groups = [ordered]@{ '' = [System.Collections.Generic.List[string]]::new() }
for ($i = 0; $i -lt $previousStable; $i++)
{
    $parts = [regex]::Split($releases[$i].Notes, '(?m)^### ([^\n]+)\n')
    for ($part = 0; $part -lt $parts.Count; $part += 2)
    {
        $title = if ($part -eq 0) { '' } else { $parts[$part - 1].Trim() }
        $content = $parts[$part].Trim()
        if (-not $content)
        {
            continue
        }
        if (-not $groups.Contains($title))
        {
            $groups[$title] = [System.Collections.Generic.List[string]]::new()
        }
        # Keep continuation paragraphs with their bullet, including breaking-change explanations.
        $entries = @(
            foreach ($block in [regex]::Split($content, '(?m)(?=^(?:\*|-|\d+\.) )'))
            {
                if ($block -match '\A(?:\*|-|\d+\.) ')
                {
                    $block
                }
                else
                {
                    [regex]::Split($block.Trim(), '\n[ \t]*\n')
                }
            }
        )
        foreach ($entry in $entries)
        {
            $entry = $entry.Trim()
            if ($entry -and -not $groups[$title].Contains($entry))
            {
                $groups[$title].Add($entry)
            }
        }
    }
}

$header = $releases[0].Heading.Replace($compare.Value,
    "($($compare.Groups['prefix'].Value)$($oldestCompare.Groups['base'].Value)...$($compare.Groups['tag'].Value))")
$sections = @($header)
foreach ($title in $groups.Keys)
{
    if ($groups[$title].Count -eq 0)
    {
        continue
    }
    $content = $groups[$title] -join "`n`n"
    $sections += if ($title) { "### $title`n`n$content" } else { $content }
}
$notes = $sections -join "`n`n"

$bodyNewline = if ($PullRequestBody.Contains("`r`n")) { "`r`n" } else { "`n" }
$body = $PullRequestBody.Replace("`r`n", "`n")
$delimiters = [regex]::Matches($body, '(?m)^---[ \t]*(?:\n|$)')
if ($delimiters.Count -ne 2)
{
    throw 'Expected exactly two Release Please PR body delimiters.'
}
$notesStart = $delimiters[0].Index + $delimiters[0].Length
$bodyNotes = $body.Substring($notesStart, $delimiters[1].Index - $notesStart).Trim()
if ($bodyNotes -notmatch "\A## \[?$([regex]::Escape($Version))\]?(?=[ (]|$)")
{
    throw 'The Release Please PR body must contain a single matching stable release.'
}

$result.Changelog = ($text.Substring(0, $releases[0].Start) + $notes + "`n`n" +
    $text.Substring($releases[0].End)).Replace("`n", $newline)
$result.PullRequestBody = ($body.Substring(0, $notesStart) + "`n`n$notes`n`n" +
    $body.Substring($delimiters[1].Index)).Replace("`n", $bodyNewline)
$result.RolledUp = $true
$result
