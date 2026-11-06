[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repository,

    [Parameter(Mandatory)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$PullRequestNumber,

    [Parameter(Mandatory)]
    [string]$MergeSha
)

$ErrorActionPreference = 'Stop'
if (-not $env:GH_TOKEN -or -not $env:GITHUB_API_URL)
{
    throw 'GH_TOKEN and GITHUB_API_URL are required.'
}
$headers = @{
    Authorization = "Bearer $env:GH_TOKEN"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}
$api = "$env:GITHUB_API_URL/repos/$Repository"
$author = Invoke-RestMethod -Uri "$env:GITHUB_API_URL/user" -Headers $headers
$pr = Invoke-RestMethod -Uri "$api/pulls/$PullRequestNumber" -Headers $headers
if (-not $author.login -or $pr.user.login -cne $author.login -or
    $pr.state -ne 'closed' -or -not $pr.merged_at -or $pr.merge_commit_sha -cne $MergeSha -or
    $pr.base.ref -cne 'main' -or $pr.base.repo.full_name -cne $Repository -or
    $pr.head.repo.full_name -cne $Repository -or $pr.head.ref -cne 'release-please--branches--main' -or
    'autorelease: pending' -notin $pr.labels.name -or
    $pr.body -notlike ':robot: I have created a release *' -or
    $pr.body -notmatch 'This PR was generated with \[Release Please\]')
{
    throw 'Expected a merged, same-repository Release Please PR authored by the release token owner.'
}

# Invoke-RestMethod emits a JSON array as one object; ForEach-Object unrolls it.
$files = @(Invoke-RestMethod -Uri "$api/pulls/$PullRequestNumber/files?per_page=100" -Headers $headers | ForEach-Object { $_ })
if ($files.Count -ne 3 -or $pr.changed_files -ne 3 -or
    @($files | Where-Object {
        $_.filename -notin @('.release-please-manifest.json', 'version.txt', 'CHANGELOG.md') -or
        $_.status -notin @('modified', 'added')
    }).Count -gt 0)
{
    throw 'Release PRs may change only the manifest, version.txt and CHANGELOG.md.'
}

function Get-TrackedReleaseVersion
{
    param([string]$Sha)

    $file = Invoke-RestMethod -Uri "$api/contents/.release-please-manifest.json?ref=$sha" -Headers $headers
    if ($file.encoding -ne 'base64')
    {
        throw 'Expected a base64 release manifest.'
    }
    ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($file.content)) | ConvertFrom-Json).'.'
}
$versions = @(
    Get-TrackedReleaseVersion -Sha $pr.head.sha
    Get-TrackedReleaseVersion -Sha $MergeSha
)
if ($versions.Count -ne 2 -or $versions[0] -cne $versions[1] -or
    $versions[0] -cnotmatch '^\d+\.\d+\.\d+(?:-beta[0-9]{3,})?$' -or
    $pr.title -cne "chore(main): release $($versions[0])" -or
    $pr.body -notmatch "(?m)^## \[?$([regex]::Escape($versions[0]))(?:\]|\s|$)")
{
    throw 'Release title, body and immutable head/merge manifests must agree.'
}
$channel = if ($versions[0] -match '-') { 'beta' } else { 'stable' }
if (('stable-promotion' -in $pr.labels.name) -ne ($channel -eq 'stable'))
{
    throw 'Stable promotion label must agree with the immutable release version.'
}
if ($channel -eq 'stable')
{
    # Main may have advanced while the promotion PR was awaiting review.
    $commit = Invoke-RestMethod -Uri "$api/git/commits/$MergeSha" -Headers $headers
    $parentSha = @($commit.parents)[0].sha
    if (-not $parentSha)
    {
        throw 'Cannot identify main immediately before the stable promotion merge.'
    }
    $betaVersion = Get-TrackedReleaseVersion -Sha $parentSha
    if ($betaVersion -cnotmatch "^$([regex]::Escape($versions[0]))-beta[0-9]{3,}$")
    {
        throw 'A stable promotion must merge directly on top of its published beta.'
    }
    $betaTag = "v$betaVersion"
    $betaCommit = Invoke-RestMethod -Uri "$api/commits/$betaTag" -Headers $headers
    $betaRelease = Invoke-RestMethod -Uri "$api/releases/tags/$betaTag" -Headers $headers
    if ($betaCommit.sha -cne $parentSha -or $betaRelease.tag_name -cne $betaTag -or
        $betaRelease.draft -or -not $betaRelease.published_at -or -not $betaRelease.prerelease)
    {
        throw 'Main advanced beyond the published beta while stable promotion was pending. Prepare a new beta first.'
    }
}

# Release Please scans all merged pending PRs, not just the triggering PR.
$page = 1
do
{
    $pending = @(Invoke-RestMethod -Uri "$api/issues?state=closed&labels=autorelease%3A%20pending&per_page=100&page=$page" -Headers $headers | ForEach-Object { $_ })
    foreach ($issue in $pending)
    {
        if ($issue.pull_request -and $issue.number -ne $PullRequestNumber)
        {
            $other = Invoke-RestMethod -Uri "$api/pulls/$($issue.number)" -Headers $headers
            if ($other.merged_at -and $other.base.ref -ceq 'main')
            {
                throw "Another merged release PR #$($issue.number) is pending. Resolve it before finalizing this channel."
            }
        }
    }
    $page++
} while ($pending.Count -eq 100)

$channel
