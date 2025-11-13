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
        Forces the resumption without additional confirmation.
    .EXAMPLE
        Resume-IMJob -Job 'thumbnailGeneration'

        Resumes thumbnail generation processing.
    .EXAMPLE
        Resume-IMJob -Job 'videoConversion' -Force

        Forcibly resumes video conversion jobs.
    .EXAMPLE
        Get-IMJob | Where-Object {$_.jobCounts.paused -gt 0} | ForEach-Object { Resume-IMJob -Job $_.name }

        Resumes all job types that have paused jobs.
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
        [ApiParameter('force')]
        [switch]
        $Force
    )

    $Job | ForEach-Object {
        $CurrentJob = $PSItem
        $Body = @{
            command = 'resume'
        }
        $Body += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
        InvokeImmichRestMethod -Method PUT -RelativePath "/jobs/$CurrentJob" -ImmichSession:$Session -Body:$Body
    }
}
#endregion
