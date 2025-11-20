function Start-IMJob
{
    <#
    .SYNOPSIS
        Starts Immich background jobs
    .DESCRIPTION
        Initiates various background processing jobs in Immich such as thumbnail generation, metadata extraction,
        face detection, and other system maintenance tasks. Jobs run asynchronously in the background.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Job
        The type of job to start. Valid values include thumbnailGeneration, metadataExtraction, videoConversion,
        faceDetection, facialRecognition, smartSearch, duplicateDetection, and others.
    .PARAMETER Force
        Forces the job to start even if similar jobs are already running or queued.
    .EXAMPLE
        Start-IMJob -Job 'thumbnailGeneration'

        Starts thumbnail generation for all assets missing thumbnails.
    .EXAMPLE
        Start-IMJob -Job 'faceDetection' -Force

        Forces face detection to run on all applicable assets.
    .EXAMPLE
        Start-IMJob -Job 'duplicateDetection'

        Starts duplicate detection analysis across the entire library.
    .EXAMPLE
        @('metadataExtraction', 'thumbnailGeneration') | ForEach-Object { Start-IMJob -Job $_ }

        Starts multiple job types sequentially.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before starting jobs.
        Jobs run in the background and progress can be monitored using Get-IMJob.
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
                        name = $CurrentJob
                    }
                    $Body += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
                    InvokeImmichRestMethod -Method POST -RelativePath '/jobs' -ImmichSession:$Session -Body:$Body
                }
            }
        }
    }
}
#endregion
