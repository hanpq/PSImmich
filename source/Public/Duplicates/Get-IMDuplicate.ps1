function Get-IMDuplicate
{
    <#
    .SYNOPSIS
        Retrieves duplicate assets from Immich
    .DESCRIPTION
        Identifies and retrieves information about duplicate assets in the Immich library. This helps
        users identify redundant files that may be taking up unnecessary storage space.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMDuplicate

        Retrieves all duplicate assets in the library.
    .EXAMPLE
        $duplicates = Get-IMDuplicate
        $duplicates | Measure-Object | Select-Object -ExpandProperty Count

        Counts the total number of duplicate asset groups found.
    .EXAMPLE
        Get-IMDuplicate | ForEach-Object { Write-Host "Duplicate group with $($_.assets.Count) assets" }

        Displays information about each duplicate group.
    .EXAMPLE
        Get-IMDuplicate | Where-Object {$_.assets.Count -gt 2} | Select-Object -First 5

        Retrieves the first 5 duplicate groups that have more than 2 assets.
    .NOTES
        Duplicate detection is based on file content hash, not filename or metadata.
        This function returns duplicate groups, where each group contains multiple assets with identical content.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath '/duplicates' -ImmichSession:$Session | AddCustomType -Type IMAssetDuplicate

}
#endregion
