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
        Accepted for compatibility but has no effect: the queues API does not support forced clearing,
        so a warning is written. To skip the confirmation prompt, use -Confirm:$false.
    .EXAMPLE
        Clear-IMQueue -Name thumbnailGeneration

        Clears all jobs from the thumbnail generation queue after confirmation.
    .EXAMPLE
        Clear-IMQueue -Name duplicateDetection -Confirm:$false

        Clears all jobs from the duplicate detection queue without a confirmation prompt.
    .EXAMPLE
        @('faceDetection', 'facialRecognition') | Clear-IMQueue -Confirm:$false

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
        [switch]
        $Force
    )

    process
    {
        if ($Force)
        {
            Write-Warning 'The -Force parameter has no effect: the queues API does not support forced clearing.'
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Clear all queue jobs'))
        {
            Invoke-ImmichApiEmptyQueue -Name $Name -Body @{ failed = $false } -ImmichSession $Session
        }
    }
}
#endregion
