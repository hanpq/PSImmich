function Start-IMAssetJob
{
    <#
    .DESCRIPTION
        Start Immich asset job
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the asset id that the job should target. Accepts pipeline input.
    .PARAMETER JobName
        Defines the job to be started
    .EXAMPLE
        Start-IMAssetJob

        Start Immich asset job
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter(Mandatory)]
        [ValidateSet('regenerate-thumbnail', 'refresh-metadata', 'transcode-video')]
        [string]
        $JobName
    )

    BEGIN
    {
        $BodyParameters = @{
            assetIds = @()
        }
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'JobName' -NameMapping @{JobName = 'name' })
    }

    PROCESS
    {
        $id | ForEach-Object {
            $BodyParameters.assetIds += $psitem
        }
    }

    END
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.assetIds -join ','), 'RUN JOB'))
        {
            InvokeImmichRestMethod -Method POST -RelativePath '/asset/jobs' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
