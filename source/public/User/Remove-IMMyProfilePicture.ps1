function Remove-IMMyProfilePicture
{
    <#
    .SYNOPSIS
        Removes current user's profile picture.
    .DESCRIPTION
        Deletes profile picture for the currently authenticated user.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .EXAMPLE
        Remove-IMMyProfilePicture

        Removes your profile picture.

        Remove the profile picture of the connected user
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    if ($PSCmdlet.ShouldProcess('Remove profile picture'))
    {
        InvokeImmichRestMethod -Method DELETE -RelativePath '/users/profile-image' -ImmichSession:$Session
    }

}
#endregion
