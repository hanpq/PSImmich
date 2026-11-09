function Resume-IMJob
{
    <#
    .SYNOPSIS
        Resumes suspended Immich background jobs
    .DESCRIPTION
        Resumes processing of previously suspended job types in Immich. This allows the job queues
        to continue processing pending items and accept new jobs.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Job
        The type of job to resume. Valid values include thumbnailGeneration, metadataExtraction,
        videoConversion, faceDetection, and other background job types.
    .PARAMETER Force
        Retained for compatibility. The queues API has no force option, so this parameter has no effect and a warning is written.
    .EXAMPLE
        Resume-IMJob -Job 'thumbnailGeneration'

        Resumes thumbnail generation processing.
    .EXAMPLE
        Resume-IMJob -Job 'videoConversion'

        Resumes video conversion jobs.
    .EXAMPLE
        Get-IMJob | Where-Object {$_.isPaused} | ForEach-Object { Resume-IMJob -Job $_.name }

        Resumes all job types whose queues are paused.
    .NOTES
        Use this cmdlet to resume jobs that were previously suspended with Suspend-IMJob.
        Monitor job status with Get-IMJob to verify jobs are processing normally after resuming.
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
        Write-Warning 'The -Force parameter has no effect: the queues API does not support forced resumption.'
    }

    $Job | ForEach-Object {
        $CurrentJob = $PSItem
        $Body = @{
            isPaused = $false
        }
        Invoke-ImmichApiUpdateQueue -Name $CurrentJob -Body $Body -ImmichSession $Session
    }
}
#endregion
