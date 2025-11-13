function Start-IMVideoTranscode
{
    <#
    .SYNOPSIS
        Starts video transcoding jobs for Immich assets
    .DESCRIPTION
        Initiates video transcoding jobs for one or more video assets, creating web-optimized versions
        for better streaming and compatibility. This is useful for reprocessing videos or generating
        transcoded versions when they are missing or corrupted.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the video asset(s) to transcode. Accepts pipeline input and multiple values.
    .EXAMPLE
        Start-IMVideoTranscode -Id 'video-asset-uuid'

        Starts transcoding for the specified video asset with confirmation prompt.
    .EXAMPLE
        Get-IMAsset | Where-Object {$_.type -eq 'VIDEO'} | Start-IMVideoTranscode

        Starts transcoding for all video assets in the library.
    .EXAMPLE
        @('video1-uuid', 'video2-uuid') | Start-IMVideoTranscode -Confirm:$false

        Starts transcoding for multiple video assets without confirmation.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before starting transcoding jobs.
        Transcoding is a CPU-intensive operation that may take significant time depending on video size and server resources.
        Only works with video assets; image assets will be ignored.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    begin
    {
        $BodyParameters = @{
            assetIds = @()
            name     = 'transcode-video'
        }
    }

    process
    {
        $Id | ForEach-Object {
            $BodyParameters.assetIds += $psitem
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.assetIds -join ','), 'Transcode videos'))
        {
            InvokeImmichRestMethod -Method POST -RelativePath '/assets/jobs' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
