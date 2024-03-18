function Set-IMUser
{
    <#
    .DESCRIPTION
        Set Immich user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the user id to update
    .PARAMETER IsAdmin
        Defines if the user should be admin
    .PARAMETER AvatarColor
        Defines the avatar color for the user
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
        Set-IMUser

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
        [string]
        $Email,

        [Parameter()]
        [ValidateSet('primary', 'pink', 'red', 'yellow', 'blue', 'green', 'purple', 'orange', 'gray', 'amber')]
        [string]
        $AvatarColor,

        [Parameter()]
        [boolean]
        $MemoriesEnabled = $true,

        [Parameter()]
        [string]
        $Name,

        [Parameter()]
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
        $StorageLabel,

        [Parameter()]
        [boolean]
        $IsAdmin
    )

    BEGIN
    {
        $Body = @{}
        $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'IsAdmin', 'AvatarColor', 'Email', 'MemoriesEnabled', 'Name', 'Password', 'QuotaSizeInBytes', 'ShouldChangePassword', 'StorageLabel' -NameMapping @{
                Email                = 'email'
                MemoriesEnabled      = 'memoriesEnabled'
                Name                 = 'name'
                Password             = 'password'
                QuotaSizeInBytes     = 'quotaSizeInBytes'
                ShouldChangePassword = 'shouldChangePassword'
                StorageLabel         = 'storageLabel'
                AvatarColor          = 'avatarColor'
                IsAdmin              = 'isAdmin'
            })
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem,'Set')) {
                $Body.id = $PSItem
                InvokeImmichRestMethod -Method PUT -RelativePath '/user' -ImmichSession:$Session -Body $Body
            }
        }
    }

}
#endregion
