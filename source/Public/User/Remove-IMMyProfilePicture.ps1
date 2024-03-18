function Remove-IMMyProfilePicture
{
    <#
    .DESCRIPTION
        Remove the profile picture of the connected user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Remove-IMMyProfilePicture

        Remove the profile picture of the connected user
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    if ($PSCmdlet.ShouldProcess('Remove profile picture')) {
        InvokeImmichRestMethod -Method DELETE -RelativePath '/user/profile-image' -ImmichSession:$Session
    }

}
#endregion
