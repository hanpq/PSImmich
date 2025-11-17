function Add-IMMyProfilePicture
{
    <#
    .SYNOPSIS
        Sets current user's profile picture.
    .DESCRIPTION
        Uploads and sets profile picture for the currently authenticated user. Uses unified HttpClient
        implementation for reliable cross-platform multipart uploads.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER FilePath
        Path to image file for profile picture. Supports JPG, PNG, GIF formats.
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

    process
    {
        # Resolve session - same pattern as InvokeImmichRestMethod
        $FileInfo = Get-Item -Path $FilePath.FullName
        $Uri = "/users/profile-image"

        # Use unified HttpClient approach via private function
        $ResponseContent = Invoke-MultipartHttpUpload -Uri $Uri -Session:$Session -FormData @{} -FileInfo $FileInfo -FileFieldName 'file'

        $ResponseContent | ConvertFrom-Json
    }
}
