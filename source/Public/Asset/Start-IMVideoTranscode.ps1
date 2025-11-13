function Start-IMVideoTranscode
{
    <#
    .DESCRIPTION
        Recreates the transcoded version of the source video files
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the asset id that the job should target. Accepts pipeline input.
    .EXAMPLE
        Start-IMVideoTranscode

        Recreates the transcoded version of the source video files
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
