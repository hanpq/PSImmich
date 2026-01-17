function Set-IMQueue
{
    <#
    .SYNOPSIS
        Updates Immich queue settings
    .DESCRIPTION
        Updates the configuration of a specific queue, such as pausing or resuming queue processing.
        This is useful for temporarily stopping processing tasks or managing system resources.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Name
        The name of the queue to update. Required parameter.
        Valid queue names include: thumbnailGeneration, metadataExtraction, videoConversion,
        faceDetection, facialRecognition, smartSearch, duplicateDetection, backgroundTask,
        storageTemplateMigration, migration, search, sidecar, library, notifications, backupDatabase, ocr, workflow
    .PARAMETER IsPaused
        Whether the queue should be paused (true) or active (false).
    .EXAMPLE
        Set-IMQueue -Name thumbnailGeneration -IsPaused $true

        Pauses the thumbnail generation queue.
    .EXAMPLE
        Set-IMQueue -Name faceDetection -IsPaused $false

        Resumes the face detection queue.
    .EXAMPLE
        @('thumbnailGeneration', 'videoConversion') | Set-IMQueue -IsPaused $true

        Pauses multiple queues via pipeline input.
    .NOTES
        This function requires admin privileges. Pausing a queue will prevent new jobs from being processed
        but will not stop currently running jobs.
    #>

    [CmdletBinding(SupportsShouldProcess)]
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

        [Parameter(Mandatory)]
        [ApiParameter('isPaused')]
        [bool]
        $IsPaused
    )

    process
    {
        $StatusText = if ($IsPaused)
        {
            'pause' 
        }
        else
        {
            'resume' 
        }
        if ($PSCmdlet.ShouldProcess($Name, "$StatusText queue"))
        {
            $Body = @{}
            $Body += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

            $Result = InvokeImmichRestMethod -Method PUT -RelativePath "/queues/$Name" -ImmichSession:$Session -Body $Body
            $Result | AddCustomType IMQueue
        }
    }
}
#endregion
