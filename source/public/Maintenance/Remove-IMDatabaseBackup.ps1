function Remove-IMDatabaseBackup
{
    <#
    .SYNOPSIS
        Removes Immich database backups
    .DESCRIPTION
        Deletes one or more database backup files from the Immich server. Backups are identified by their file name, as returned by Get-IMDatabaseBackup.
        This permanently deletes the backup files on the server.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Filename
        The file name of the database backup to remove. Accepts pipeline input, for example from Get-IMDatabaseBackup.
    .EXAMPLE
        Remove-IMDatabaseBackup -Filename 'immich-db-backup-20260101T000000-v3.3.6-pg14.sql.gz'

        Removes the specified database backup from the server.
    .EXAMPLE
        Get-IMDatabaseBackup | Where-Object { $_.filesize -lt 1MB } | Remove-IMDatabaseBackup -WhatIf

        Shows which small database backups would be removed without removing them.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]
        $Filename
    )

    process
    {
        if ($PSCmdlet.ShouldProcess(($Filename -join ', '), 'Remove database backup'))
        {
            Invoke-ImmichApiDeleteDatabaseBackup -Body @{ backups = @($Filename) } -ImmichSession $Session
        }
    }
}
