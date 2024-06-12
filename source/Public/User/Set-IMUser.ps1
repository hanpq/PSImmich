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
        [string]
        $Email,

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
        $StorageLabel
    )

    BEGIN
    {
        $Body = @{}
        $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'Email', 'Name', 'Password', 'QuotaSizeInBytes', 'ShouldChangePassword', 'StorageLabel' -NameMapping @{
                Email                = 'email'
                Name                 = 'name'
                Password             = 'password'
                QuotaSizeInBytes     = 'quotaSizeInBytes'
                ShouldChangePassword = 'shouldChangePassword'
                StorageLabel         = 'storageLabel'
            })
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem,'Set')) {
                InvokeImmichRestMethod -Method PUT -RelativePath "/admin/users/$PSItem" -ImmichSession:$Session -Body $Body
            }
        }
    }

}
#endregion
