function Clear-IMJob
{
    <#
    .SYNOPSIS
        Clears Immich job queues
    .DESCRIPTION
        Clears completed, failed, or all jobs from specific job queues in Immich. This helps manage
        job queue cleanup and removes old job entries that are no longer needed.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Job
        The type of job queue to clear. Valid values include thumbnailGeneration, metadataExtraction,
        videoConversion, faceDetection, and other job types.
    .PARAMETER Force
        Retained for compatibility. The queues API has no force option, so this parameter has no effect and a warning is written.
    .PARAMETER FailedOnly
        Clears only failed jobs from the queue, leaving completed and pending jobs intact. This uses the deprecated
        jobs API because the queues API cannot clear failed jobs without also clearing the queue.
    .EXAMPLE
        Clear-IMJob -Job 'thumbnailGeneration'

        Clears all jobs from the thumbnail generation queue.
    .EXAMPLE
        Clear-IMJob -Job 'faceDetection' -FailedOnly

        Clears only failed jobs from the face detection queue.
    .NOTES
        Use caution when clearing job queues as this may remove jobs that haven't completed yet.
        The FailedOnly parameter is recommended for routine maintenance.
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
        $FailedOnly,

        [Parameter()]
        [switch]
        $Force
    )

    if ($Force)
    {
        Write-Warning 'The -Force parameter has no effect: the queues API does not support forced clearing.'
    }

    $Job | ForEach-Object {
        $CurrentJob = $PSItem
        if ($FailedOnly)
        {
            $Body = @{ command = 'clear-failed' }
            InvokeImmichRestMethod -Method PUT -RelativePath "/jobs/$CurrentJob" -ImmichSession:$Session -Body:$Body
        }
        else
        {
            $Body = @{ failed = $false }
            InvokeImmichRestMethod -Method DELETE -RelativePath "/queues/$CurrentJob/jobs" -ImmichSession:$Session -Body:$Body
        }
    }
}
#endregion
