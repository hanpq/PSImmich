function Export-IMPersonThumbnail
{
    <#
    .SYNOPSIS
        Exports person thumbnail image to file.
    .DESCRIPTION
        Downloads the thumbnail image for a person identified by face recognition.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Person ID to export thumbnail for.
    .PARAMETER Path
        Directory path for saving the thumbnail file.
    .EXAMPLE
        Export-IMPersonThumbnail -Id 'bf973405-3f2a-48d2-a687-2ed4167164be' -Path 'C:\Downloads'

        Exports person thumbnail to Downloads folder.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id,

        [Parameter()]
        [System.IO.DirectoryInfo]
        $Path
    )

    process
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            $OutputPath = Join-Path -Path $Path -ChildPath "$($CurrentID).jpeg"
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $SavedProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
            }
            InvokeImmichRestMethod -Method Get -RelativePath "/people/$CurrentID/thumbnail" -ImmichSession:$Session -ContentType 'application/octet-stream' -OutFilePath $OutputPath
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }

}
#endregion
