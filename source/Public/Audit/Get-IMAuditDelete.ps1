function Get-IMAuditDelete
{
    <#
    .DESCRIPTION
        Retreives Immich audit deletes
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER after
        asd
    .PARAMETER entityType
        asd
    .PARAMETER userId
        asd
    .EXAMPLE
        Get-IMAuditDelete

        Retreives Immich audit deletes
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $userId,

        [Parameter(Mandatory)]
        [datetime]
        $after,

        [Parameter(Mandatory)]
        [ValidateSet('ASSET', 'ALBUM')]
        [string]
        $entityType
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'userId', 'after', 'entityType')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/audit/deletes' -ImmichSession:$Session -QueryParameters:$QueryParameters
    }

}
#endregion
