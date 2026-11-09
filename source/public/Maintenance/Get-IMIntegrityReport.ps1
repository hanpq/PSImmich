function Get-IMIntegrityReport
{
    <#
    .SYNOPSIS
        Retrieves Immich storage integrity reports
    .DESCRIPTION
        Retrieves the storage integrity report items for one report type, or the summary counts for all report types.
        Report types are untracked_file, missing_file and checksum_mismatch. The report output includes the next cursor when more items are available; pass it to -Cursor to retrieve the next page.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Type
        The integrity report type to list.
    .PARAMETER Cursor
        The cursor from a previous page of results, used to retrieve the next page.
    .PARAMETER Limit
        The maximum number of report items to return in one page.
    .PARAMETER Summary
        Retrieves the number of items for each integrity report type instead of the report items.
    .EXAMPLE
        Get-IMIntegrityReport -Summary

        Retrieves the number of untracked, missing and checksum mismatch items.
    .EXAMPLE
        Get-IMIntegrityReport -Type 'missing_file' -Limit 50

        Retrieves the first page of missing file report items.
    .EXAMPLE
        Get-IMIntegrityReport -Type 'untracked_file' | Select-Object -ExpandProperty items

        Retrieves the untracked file report items.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP switch parameters used to determine parameter sets')]
    [CmdletBinding(DefaultParameterSetName = 'report')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'report')]
        [ValidateSet('untracked_file', 'missing_file', 'checksum_mismatch')]
        [string]
        $Type,

        [Parameter(ParameterSetName = 'report')]
        [string]
        $Cursor,

        [Parameter(ParameterSetName = 'report')]
        [int]
        $Limit,

        [Parameter(Mandatory, ParameterSetName = 'summary')]
        [switch]
        $Summary
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'report'
            {
                $ApiParams = @{ Type = $Type; ImmichSession = $Session }
                if ($PSBoundParameters.ContainsKey('Cursor')) { $ApiParams.Cursor = $Cursor }
                if ($PSBoundParameters.ContainsKey('Limit')) { $ApiParams.Limit = $Limit }
                [IntegrityReportResponseDto]::new((Invoke-ImmichApiGetIntegrityReport @ApiParams))
            }
            'summary'
            {
                [IntegrityReportSummaryResponseDto]::new((Invoke-ImmichApiGetIntegrityReportSummary -ImmichSession $Session))
            }
        }
    }
}
