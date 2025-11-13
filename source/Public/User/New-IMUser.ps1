function New-IMUser
{
    <#
    .SYNOPSIS
        Creates a new Immich user account.
    .DESCRIPTION
        Adds new user with email, name, and notification preferences.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Email
        User email address for login.
    .PARAMETER Notify
        Send notification to user about account creation. Enabled by default.
    .PARAMETER Name
        Display name for the user account.
    .PARAMETER Password
        Defines the password for the user
    .PARAMETER QuotaSizeInBytes
        Defines quota for the user
    .PARAMETER ShouldChangePassword
        Defines that the user must change password on the next login
    .PARAMETER StorageLabel
        Defines the users storage label
    .EXAMPLE
        $Password = Read-Host -Prompt 'Password' -AsSecureString
        New-IMUser -Email 'testuser@domain.com' -Name 'Test User' -Password $Password

        Creates new Immich user
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('email')]
        [string]
        $Email,

        [Parameter()]
        [ApiParameter('notify')]
        [boolean]
        $Notify = $true,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]
        $Name,

        [Parameter(Mandatory)]
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

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    InvokeImmichRestMethod -Method POST -RelativePath '/admin/users' -ImmichSession:$Session -Body $BodyParameters

}
#endregion
