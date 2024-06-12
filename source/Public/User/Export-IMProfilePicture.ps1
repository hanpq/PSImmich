function Export-IMProfilePicture
{
    <#
    .DESCRIPTION
        Export Immich profile picture
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the user id to retreive the profile picture for
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

    PROCESS
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
