function Send-IMTestMessage
{
    <#
    .SYNOPSIS
        Sends a test SMTP message to validate email notification configuration.
    .DESCRIPTION
        The Send-IMTestMessage function sends a test email message using the configured
        SMTP settings to validate that email notifications are working properly. This is
        useful for testing SMTP server connectivity, authentication, and configuration
        before relying on automated notifications from Immich.

        The function allows you to specify complete SMTP configuration parameters,
        including server details, authentication credentials, and message routing
        information to ensure proper email delivery functionality.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Enabled
        Controls whether SMTP functionality is enabled for the test. Defaults to $true.
        Set to $false to test configuration validation without actually sending mail.
    .PARAMETER From
        Specifies the sender email address that will appear in the 'From' field of the
        test message. This should be a valid email address that the SMTP server allows
        as a sender.
    .PARAMETER ReplyTo
        Specifies the reply-to email address for the test message. When recipients reply
        to the test message, their responses will be directed to this address.
    .PARAMETER Hostname
        Specifies the hostname or IP address of the SMTP server to use for sending
        the test message. This should be accessible from the Immich server.
    .PARAMETER IgnoreCert
        Controls whether SSL/TLS certificate validation should be skipped when connecting
        to the SMTP server. Set to $true to bypass certificate validation (useful for
        self-signed certificates), or $false for strict certificate validation.
    .PARAMETER Password
        Specifies the password for SMTP server authentication. This should be provided
        as a SecureString for security purposes when authenticating with the SMTP server.
    .PARAMETER Port
        Specifies the port number for SMTP server connection. Common values are 25 (plain),
        587 (TLS), 465 (SSL), or custom ports as configured by your SMTP provider.
    .PARAMETER Username
        Specifies the username for SMTP server authentication. This is typically an
        email address or account name required by the SMTP server for authentication.
    .EXAMPLE
        Send-IMTestMessage -Hostname 'smtp.gmail.com' -Port 587 -Username 'user@gmail.com' -From 'immich@example.com'

        Sends a test message using Gmail SMTP with TLS encryption.
    .EXAMPLE
        Send-IMTestMessage -Hostname 'localhost' -Port 25 -From 'immich@local.domain' -IgnoreCert $true

        Sends a test message using a local SMTP server without certificate validation.
    .EXAMPLE
        $smtpConfig = @{
            Hostname = 'mail.example.com'
            Port = 465
            Username = 'notifications@example.com'
            From = 'immich@example.com'
            ReplyTo = 'admin@example.com'
        }
        Send-IMTestMessage @smtpConfig

        Uses splatting to send a test message with comprehensive SMTP configuration.
    .NOTES
        Use this function to validate SMTP configuration before enabling automated notifications.
        Successful test messages indicate that the SMTP settings are correct and functional.
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
