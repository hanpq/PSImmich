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
        [boolean]
        $enabled = $true,

        [Parameter(Mandatory)]
        [string]
        $from,

        [Parameter(Mandatory)]
        [string]
        $replyto,

        [Parameter(Mandatory)]
        [string]
        $hostname,

        [Parameter()]
        [boolean]
        $ignoreCert = $false,

        [Parameter(Mandatory)]
        [securestring]
        $Password,

        [Parameter()]
        [int]
        $port = 25,

        [Parameter()]
        [string]
        $username = ''
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'enabled', 'from', 'replyTo')
        $BodyParameters.transport = [hashtable]@{
            host       = $hostname
            ignoreCert = $ignoreCert
            password   = $password
            port       = $port
            username   = $username
        }
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/notifications/test-email' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
