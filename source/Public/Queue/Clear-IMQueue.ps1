function Clear-IMQueue
{
    <#
    .SYNOPSIS
        Clears all jobs from an Immich queue
    .DESCRIPTION
        Removes all jobs from a specific queue, including waiting, active, completed, and failed jobs.
        This is useful for clearing stuck jobs or resetting queue state during maintenance.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Name
        The name of the queue to clear. Required parameter.
        Valid queue names include: thumbnailGeneration, metadataExtraction, videoConversion,
        faceDetection, facialRecognition, smartSearch, duplicateDetection, backgroundTask,
        storageTemplateMigration, migration, search, sidecar, library, notifications, backupDatabase, ocr, workflow
    .PARAMETER Force
        Force removal of jobs without additional confirmation prompts.
    .EXAMPLE
        Clear-IMQueue -Name thumbnailGeneration

        Clears all jobs from the thumbnail generation queue.
    .EXAMPLE
        Clear-IMQueue -Name duplicateDetection -Force

        Forcefully clears all jobs from the duplicate detection queue without confirmation.
    .EXAMPLE
        @('faceDetection', 'facialRecognition') | Clear-IMQueue -Force

        Clears multiple queues via pipeline input.
    .NOTES
        This function requires admin privileges. Use with caution as cleared jobs cannot be recovered.
        Currently running jobs may not be immediately stopped but will not be restarted.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidateSet('thumbnailGeneration', 'metadataExtraction', 'videoConversion', 'faceDetection',
            'facialRecognition', 'smartSearch', 'duplicateDetection', 'backgroundTask',
            'storageTemplateMigration', 'migration', 'search', 'sidecar', 'library',
            'notifications', 'backupDatabase', 'ocr', 'workflow')]
        [string]
        $Name,

        [Parameter()]
        [ApiParameter('force')]
        [switch]
        $Force
    )

    process
    {
        if ($PSCmdlet.ShouldProcess($Name, 'Clear all queue jobs'))
        {
            $Body = @{}
            $Body += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

            InvokeImmichRestMethod -Method DELETE -RelativePath "/queues/$Name/jobs" -ImmichSession:$Session -Body $Body
        }
    }
}
#endregion
