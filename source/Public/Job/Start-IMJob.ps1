function Start-IMJob
{
    <#
    .DESCRIPTION
        Start immich job
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Job
        Defines the job type
    .PARAMETER Force
        Define force
    .EXAMPLE
        Start-IMJob -job 'thumbnailGeneration'

        Start thumbnail generation job
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidateSet(
            'thumbnailGeneration',
            'metadataExtraction',
            'videoConversion',
            'faceDetection',
            'facialRecognition',
            'smartSearch',
            'duplicateDetection',
            'backgroundTask',
            'storageTemplateMigration',
            'migration',
            'search',
            'sidecar',
            'library',
            'notifications',
            'emptyTrash',
            'person-cleanup',
            'tag-cleanup',
            'user-cleanup'
        )]
        [string[]]
        $Job,

        [Parameter()]
        [ApiParameter('force')]
        [switch]
        $Force
    )

    $Job | ForEach-Object {
        switch ($PSItem)
        {
            'emptyTrash'
            {
                if ($PSCmdlet.ShouldProcess('All assets in trash', 'REMOVE'))
                {
                    InvokeImmichRestMethod -Method POST -RelativePath '/trash/empty' -ImmichSession:$Session
                }
            }
            { @('person-cleanup', 'tag-cleanup', 'user-cleanup') -contains $PSItem }
            {
                if ($PSCmdlet.ShouldProcess("Start job: $($PSitem)", 'START'))
                {
                    $Body = @{
                        name = $PSitem
                    }
                    InvokeImmichRestMethod -Method POST -RelativePath '/jobs' -ImmichSession:$Session -Body:$Body
                }
            }
            default
            {
                if ($PSCmdlet.ShouldProcess("Start job: $($PSitem)", 'START'))
                {
                    $CurrentJob = $PSItem
                    $Body = @{
                        command = 'start'
                    }
                    $Body += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
                    InvokeImmichRestMethod -Method PUT -RelativePath "/jobs/$CurrentJob" -ImmichSession:$Session -Body:$Body
                }
            }
        }
    }
}
#endregion
