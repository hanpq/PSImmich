function Get-IMUserStatistics
{
    <#
    .SYNOPSIS
        Retrieves user statistics.
    .DESCRIPTION
        Gets user statistics information from Immich server.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to get statistics for.
    .EXAMPLE
        Get-IMUserStatistics -Id 'user-id'

        Gets user statistics.

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, evaluated as part of parameterset check')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    process
    {
        $id | ForEach-Object {
            InvokeImmichRestMethod -Method Get -RelativePath "/admin/users/$PSItem/statistics" -ImmichSession:$Session | AddCustomType IMUserStatistics
        }
    }
}
#endregion
