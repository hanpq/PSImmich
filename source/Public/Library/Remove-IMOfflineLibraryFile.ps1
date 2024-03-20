function Remove-IMOfflineLibraryFile
{
    <#
    .DESCRIPTION
        Purge offline files in library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific library id to be cleaned up
    .EXAMPLE
        Remove-IMOfflineLibraryFile -id <libraryid>

        Purge offline files in library
    #>

    [CmdletBinding(DefaultParameterSetName = 'list', SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            if ($PSCmdlet.ShouldProcess($CurrentID, 'purge offline files'))
            {
                InvokeImmichRestMethod -Method POST -RelativePath "/library/$CurrentID/removeOffline" -ImmichSession:$Session
            }
        }

    }
}
#endregion
