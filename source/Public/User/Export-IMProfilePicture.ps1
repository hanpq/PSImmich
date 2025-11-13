function Export-IMProfilePicture
{
    <#
    .SYNOPSIS
        Exports user profile picture to file.
    .DESCRIPTION
        Downloads and saves user's profile picture to local file system.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to export profile picture for.
    .PARAMETER Path
        Defines the directory for the output file
    .EXAMPLE
        Export-IMProfilePicture -id <personid> -Path C:\download

        Export user profile picture
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
            InvokeImmichRestMethod -Method Get -RelativePath "/users/$CurrentID/profile-image" -ImmichSession:$Session -ContentType 'application/octet-stream' -OutFilePath $OutputPath
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                $global:ProgressPreference = $SavedProgressPreference
            }
        }
    }

}
#endregion
