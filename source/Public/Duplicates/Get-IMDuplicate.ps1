function Get-IMDuplicate
{
    <#
    .DESCRIPTION
        Retreives Immich asset duplicate
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Get-IMDuplicate

        Retreives Immich asset duplicate
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    InvokeImmichRestMethod -Method Get -RelativePath "/duplicates" -ImmichSession:$Session | AddCustomType -Type IMAssetDuplicate

}
#endregion
