﻿function New-IMUser
{
    <#
    .DESCRIPTION
        New Immich user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
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
        New-IMUser

        New Immich user
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','', Justification='FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $Email,

        [Parameter()]
        [boolean]
        $MemoriesEnabled = $true,

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [securestring]
        $Password,

        [Parameter()]
        [int64]
        $QuotaSizeInBytes,

        [Parameter()]
        [boolean]
        $ShouldChangePassword,

        [Parameter()]
        [string]
        $StorageLabel
    )

    $Body = @{}
    $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Email', 'MemoriesEnabled', 'Name', 'Password', 'QuotaSizeInBytes', 'ShouldChangePassword', 'StorageLabel' -NameMapping @{
            Email                = 'email'
            MemoriesEnabled      = 'memoriesEnabled'
            Name                 = 'name'
            Password             = 'password'
            QuotaSizeInBytes     = 'quotaSizeInBytes'
            ShouldChangePassword = 'shouldChangePassword'
            StorageLabel         = 'storageLabel'
        })

    InvokeImmichRestMethod -Method POST -RelativePath '/user' -ImmichSession:$Session -Body $Body

}
#endregion
