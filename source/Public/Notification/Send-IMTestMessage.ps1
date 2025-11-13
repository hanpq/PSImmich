function Send-IMTestMessage
{
    <#
    .DESCRIPTION
        Send a SMTP test message
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER enabled
        Unknown, defaults to true
    .PARAMETER from
        Defines the from address
    .PARAMETER replyTo
        Defines the replyto address
    .PARAMETER hostname
        Defines the smtp host
    .PARAMETER ignoreCert
        Defines if certificate validation should be skipped
    .PARAMETER password
        Defines the password
    .PARAMETER port
        Defines port
    .PARAMETER username
        Defines the username
    .EXAMPLE
        Send-IMTestMessage

        Send a SMTP test message
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ApiParameter('enabled')]
        [boolean]
        $enabled = $true,

        [Parameter(Mandatory)]
        [ApiParameter('from')]
        [string]
        $from,

        [Parameter(Mandatory)]
        [ApiParameter('replyTo')]
        [string]
        $replyto,

        [Parameter(Mandatory)]
        [ApiParameter('transport.host')]
        [string]
        $hostname,

        [Parameter()]
        [ApiParameter('transport.ignoreCert')]
        [boolean]
        $ignoreCert = $false,

        [Parameter(Mandatory)]
        [ApiParameter('transport.password')]
        [securestring]
        $Password,

        [Parameter()]
        [ApiParameter('transport.port')]
        [int]
        $port = 25,

        [Parameter()]
        [ApiParameter('transport.username')]
        [string]
        $username = ''
    )

    begin
    {
        # Use enhanced ConvertTo-ApiParameters with dot-notation support for nested objects
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

        # Handle special SecureString conversion for transport.password
        if ($PSBoundParameters.ContainsKey('Password') -and $BodyParameters.ContainsKey('transport'))
        {
            $BodyParameters.transport.password = $Password | ConvertFromSecureString
        }
    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/admin/notifications/test-email' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
