function Add-IMMyProfilePicture
{
    <#
    .DESCRIPTION
        Adds an Immich user profile picture
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER FilePath
        Defines the asset ids that should be removed. Accepts pipeline input.
    .EXAMPLE
        Add-IMMyProfilePicture -FilePath C:\avatar.jpg

        Add profile picture to current user
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, retreived through PSBoundParameters')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $FilePath
    )

    BEGIN
    {
        # Do not run on Windows Powershell
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            Write-Warning -Message 'Add-IMMyProfilePicture is not currently supported on Windows Powershell, please use Powershell Core on Windows instead.'
            break
        }
    }

    PROCESS
    {
            $FileInfo = Get-Item -Path $FilePath.FullName
            $Uri = "$($ImmichSession.ApiUri)/users/profile-image"
            $Header = @{
                'Accept'    = 'application/json'
                'x-api-key' = ConvertFromSecureString -SecureString $ImmichSession.AccessToken
            }
            $Form = @{}
            $Form += @{
                file      = $FileInfo
            }
            $Result = Invoke-WebRequest -Uri $Uri -Method Post -Headers $Header -Form $Form -ContentType 'multipart/form-data'
            $Result.Content | ConvertFrom-Json
    }
}
