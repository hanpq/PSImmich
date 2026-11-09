function Save-IMIntegrityReport
{
    <#
    .SYNOPSIS
        Downloads Immich storage integrity reports to local storage
    .DESCRIPTION
        Downloads either the file for a single integrity report item, or the CSV export of all items of one report type. The Path parameter is the full destination file path, because the server does not provide a usable file name for these downloads.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the integrity report item whose file to download. Accepts pipeline input. Used by the file parameter set.
    .PARAMETER Type
        The integrity report type to export as CSV. Used by the csv parameter set.
    .PARAMETER Path
        The full path of the local file to write.
    .EXAMPLE
        Save-IMIntegrityReport -Type 'checksum_mismatch' -Path 'C:\Reports\checksum-mismatch.csv'

        Exports all checksum mismatch report items to a CSV file.
    .EXAMPLE
        Get-IMIntegrityReport -Type 'missing_file' | Select-Object -ExpandProperty items | Save-IMIntegrityReport -Path 'C:\Reports\missing.txt'

        Downloads the file of the first missing file report item. Save each item to a unique path when you need more than one file.
    #>

    [CmdletBinding(DefaultParameterSetName = 'file')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'file', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(Mandatory, ParameterSetName = 'csv')]
        [ValidateSet('untracked_file', 'missing_file', 'checksum_mismatch')]
        [string]
        $Type,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $Path
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'file'
            {
                Invoke-ImmichApiGetIntegrityReportFile -Id $Id -OutFilePath $Path -ImmichSession $Session
            }
            'csv'
            {
                Invoke-ImmichApiGetIntegrityReportCsv -Type $Type -OutFilePath $Path -ImmichSession $Session
            }
        }
    }
}
