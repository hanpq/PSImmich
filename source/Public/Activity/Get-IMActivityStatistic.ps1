﻿function Get-IMActivityStatistic
{
    <#
    .DESCRIPTION
        Retreives album activity
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER albumId
        Defines an album to retreive activity statistics for.
    .PARAMETER assetId
        Defines a specific asset to retreive activities for.
    .EXAMPLE
        Get-IMActivityStatistic -albumId 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retreives activity statistics for the album
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $albumId,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $assetId
    )

    BEGIN
    {
        $QueryParameters = @{}
        $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'albumId', 'assetId')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Get -RelativePath '/activity/statistics' -ImmichSession:$Session -QueryParameters $QueryParameters
    }

}
#endregion
