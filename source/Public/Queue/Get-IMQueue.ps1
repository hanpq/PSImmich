function Get-IMQueue
{
    <#
    .SYNOPSIS
        Retrieves Immich queue information
    .DESCRIPTION
        Retrieves information about one or more queues from Immich. Queues handle background processing
        tasks like thumbnail generation, metadata extraction, face detection, and more.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Name
        The name of a specific queue to retrieve. When not specified, returns all queues.
        Valid queue names include: thumbnailGeneration, metadataExtraction, videoConversion,
        faceDetection, facialRecognition, smartSearch, duplicateDetection, backgroundTask,
        storageTemplateMigration, migration, search, sidecar, library, notifications, backupDatabase, ocr, workflow
    .EXAMPLE
        Get-IMQueue

        Retrieves information for all queues.
    .EXAMPLE
        Get-IMQueue -Name thumbnailGeneration

        Retrieves information for the thumbnail generation queue.
    .EXAMPLE
        Get-IMQueue -Name faceDetection, facialRecognition

        Retrieves information for multiple specific queues.
    .NOTES
        This function requires admin privileges. Queue information includes status, job counts, and processing statistics.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'name', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidateSet('thumbnailGeneration', 'metadataExtraction', 'videoConversion', 'faceDetection',
            'facialRecognition', 'smartSearch', 'duplicateDetection', 'backgroundTask',
            'storageTemplateMigration', 'migration', 'search', 'sidecar', 'library',
            'notifications', 'backupDatabase', 'ocr', 'workflow')]
        [string[]]
        $Name
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'name')
        {
            $Name | ForEach-Object {
                $CurrentName = $PSItem
                $Result = InvokeImmichRestMethod -Method GET -RelativePath "/queues/$CurrentName" -ImmichSession:$Session
                $Result | AddCustomType IMQueue
            }
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $Result = InvokeImmichRestMethod -Method GET -RelativePath '/queues' -ImmichSession:$Session
            $Result | AddCustomType IMQueue
        }
    }
}
#endregion
