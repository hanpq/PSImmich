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
        Forces the suspension without additional confirmation.
    .EXAMPLE
        Suspend-IMJob -Job 'thumbnailGeneration'

        Suspends thumbnail generation processing.
    .EXAMPLE
        Suspend-IMJob -Job 'videoConversion' -Force

        Forcibly suspends video conversion jobs.
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
        [ApiParameter('force')]
        [switch]
        $Force
    )

    $Job | ForEach-Object {
        $CurrentJob = $PSItem
        $Body = @{
            command = 'pause'
        }
        $Body += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
        InvokeImmichRestMethod -Method PUT -RelativePath "/jobs/$CurrentJob" -ImmichSession:$Session -Body:$Body
    }
}
#endregion
