function Suspend-IMJob
{
    <#
    .SYNOPSIS
        Suspends Immich background jobs
    .DESCRIPTION
        Temporarily suspends processing of specific job types in Immich. Suspended jobs will not process
        new items but existing running jobs may continue. Use Resume-IMJob to restart processing.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Job
        The type of job to suspend. Valid values include thumbnailGeneration, metadataExtraction,
        videoConversion, faceDetection, and other background job types.
    .PARAMETER Force
        Retained for compatibility. The queues API has no force option, so this parameter has no effect and a warning is written.
    .EXAMPLE
        Suspend-IMJob -Job 'thumbnailGeneration'

        Suspends thumbnail generation processing.
    .EXAMPLE
        Suspend-IMJob -Job 'videoConversion'

        Suspends video conversion jobs.
    .EXAMPLE
        @('faceDetection', 'duplicateDetection') | ForEach-Object { Suspend-IMJob -Job $_ }

        Suspends multiple job types.
    .NOTES
        Suspended jobs can be resumed using Resume-IMJob. Use Get-IMJob to monitor job queue status.
        Suspending jobs is useful during maintenance windows or when system resources are needed elsewhere.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding()]
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
            'notifications'
        )]
        [string[]]
        $Job,

        [Parameter()]
        [switch]
        $Force
    )

    if ($Force)
    {
        Write-Warning 'The -Force parameter has no effect: the queues API does not support forced suspension.'
    }

    $Job | ForEach-Object {
        $CurrentJob = $PSItem
        $Body = @{
            isPaused = $true
        }
        InvokeImmichRestMethod -Method PUT -RelativePath "/queues/$CurrentJob" -ImmichSession:$Session -Body:$Body
    }
}
#endregion
