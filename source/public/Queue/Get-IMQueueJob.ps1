function Get-IMQueueJob
{
    <#
    .SYNOPSIS
        Retrieves jobs from an Immich queue
    .DESCRIPTION
        Retrieves a list of jobs from a specific queue, optionally filtered by job status.
        This is useful for monitoring queue processing, troubleshooting stuck jobs, or viewing job history.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Name
        The name of the queue to retrieve jobs from. Required parameter.
        Valid queue names include: thumbnailGeneration, metadataExtraction, videoConversion,
        faceDetection, facialRecognition, smartSearch, duplicateDetection, backgroundTask,
        storageTemplateMigration, migration, search, sidecar, library, notifications, backupDatabase, ocr, workflow
    .PARAMETER Status
        Filter jobs by their current status. Valid values include:
        waiting, active, completed, failed, delayed, paused
    .EXAMPLE
        Get-IMQueueJob -Name thumbnailGeneration

        Retrieves all jobs from the thumbnail generation queue.
    .EXAMPLE
        Get-IMQueueJob -Name faceDetection -Status failed

        Retrieves only failed jobs from the face detection queue.
    .EXAMPLE
        Get-IMQueueJob -Name videoConversion -Status active, waiting

        Retrieves active and waiting jobs from the video conversion queue.
    .NOTES
        This function requires admin privileges. Job information includes status, progress,
        creation time, and processing details.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidateSet('thumbnailGeneration', 'metadataExtraction', 'videoConversion', 'faceDetection',
            'facialRecognition', 'smartSearch', 'duplicateDetection', 'backgroundTask',
            'storageTemplateMigration', 'migration', 'search', 'sidecar', 'library',
            'notifications', 'backupDatabase', 'ocr', 'workflow')]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('waiting', 'active', 'completed', 'failed', 'delayed', 'paused')]
        [string[]]
        $Status
    )

    $RequestParameters = @{ Name = $Name; ImmichSession = $Session }
    if ($PSBoundParameters.ContainsKey('Status'))
    {
        $RequestParameters['Status'] = $Status
    }

    Invoke-ImmichApiGetQueueJobs @RequestParameters |
        ForEach-Object { [QueueJobResponseDto]::new($PSItem) }
}
#endregion
