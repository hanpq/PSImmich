function Get-IMDatabaseBackup
{
    <#
    .SYNOPSIS
        Lists Immich database backups
    .DESCRIPTION
        Retrieves the database backups stored on the Immich server, including their file names, sizes and time zones.
        Use the file names with Save-IMDatabaseBackup or Remove-IMDatabaseBackup.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMDatabaseBackup

        Lists all database backups on the Immich server.
    .EXAMPLE
        Get-IMDatabaseBackup | Sort-Object -Property filesize -Descending | Select-Object -First 1

        Shows the largest database backup.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    process
    {
        $Result = [DatabaseBackupListResponseDto]::new((Invoke-ImmichApiListDatabaseBackups -ImmichSession $Session))
        $Result.backups
    }
}
