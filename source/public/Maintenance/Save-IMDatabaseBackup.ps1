function Save-IMDatabaseBackup
{
    <#
    .SYNOPSIS
        Downloads Immich database backups to local storage
    .DESCRIPTION
        Downloads a database backup from the Immich server to a local directory. The file keeps the name it has on the server.
        Use Get-IMDatabaseBackup to find the file names.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Filename
        The file name of the database backup to download. Accepts pipeline input, for example from Get-IMDatabaseBackup.
    .PARAMETER Path
        The local directory where the downloaded backup will be saved.
    .EXAMPLE
        Save-IMDatabaseBackup -Filename 'immich-db-backup-20260101T000000-v3.3.6-pg14.sql.gz' -Path 'C:\Backups'

        Downloads the specified database backup to the C:\Backups directory.
    .EXAMPLE
        Get-IMDatabaseBackup | Save-IMDatabaseBackup -Path 'C:\Backups'

        Downloads all database backups on the server to a local folder.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $Filename,

        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo]
        $Path
    )

    process
    {
        $OutputPath = Join-Path -Path $Path.FullName -ChildPath $Filename

        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            $SavedProgressPreference = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
        }
        try
        {
            Invoke-ImmichApiDownloadDatabaseBackup -Filename $Filename -OutFilePath $OutputPath -ImmichSession $Session
        }
        finally
        {
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }
}
