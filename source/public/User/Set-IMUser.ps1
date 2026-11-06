function Set-IMUser
{
    <#
    .SYNOPSIS
        Updates user account settings.
    .DESCRIPTION
        Modifies user properties including admin status, avatar color, and other preferences.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        User ID to update.
    .PARAMETER IsAdmin
        Sets admin privileges for the user.
    .PARAMETER AvatarColor
        Sets avatar background color for the user.
    .PARAMETER email
        Defines a specific user id to be retreived
    .PARAMETER MemoriesEnabled
        Should Memories enabled. Enabled by default
    .PARAMETER Name
        Defines the name of the user
    .PARAMETER Password
        Defines the password for the user
    .PARAMETER QuotaSizeInBytes
        Defines quota for the user
    .PARAMETER ShouldChangePassword
        Defines that the user must change password on the next login
    .PARAMETER StorageLabel
        Defines the users storage label
    .EXAMPLE
        Set-IMUser -id <userid> -Name 'John Smith'

        Set Immich user
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter()]
        [ApiParameter('email')]
        [string]
        $Email,

        [Parameter()]
        [ApiParameter('name')]
        [string]
        $Name,

        [Parameter()]
        [ApiParameter('password')]
        [securestring]
        $Password,

        [Parameter()]
        [ApiParameter('quotaSizeInBytes')]
        [int64]
        $QuotaSizeInBytes,

        [Parameter()]
        [ApiParameter('shouldChangePassword')]
        [boolean]
        $ShouldChangePassword,

        [Parameter()]
        [ApiParameter('storageLabel')]
        [string]
        $StorageLabel
    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Set'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/admin/users/$PSItem" -ImmichSession:$Session -Body $BodyParameters
            }
        }
    }

}
#endregion
