function Connect-Immich
{
    <#
    .SYNOPSIS
        Establishes connection to Immich server.
    .DESCRIPTION
        Creates authenticated session using access token or credentials for API access.
    .PARAMETER BaseURL
        Immich server URL (e.g., 'https://immich.example.com').
    .PARAMETER AccessToken
        API access token generated from Immich web interface.
    .PARAMETER Credential
        Username/password credentials as PSCredential object.
    .PARAMETER PassThru
        Returns ImmichSession object for explicit session management.
    .EXAMPLE
        Connect-Immich -BaseURL 'https://immich.example.com' -AccessToken 'your-token'

        Connects using access token authentication.
    .EXAMPLE
        $session = Connect-Immich -BaseURL 'https://immich.example.com' -Credential (Get-Credential) -PassThru

        Connects with credentials and returns session object.

        -PassThru
    .EXAMPLE
        Connect-Immich -BaseURL 'https://immich.domain.com' -AccessToken 'ABoR54bB1NUc4aNY0F2PhppP1tVDu2Husr3vEbPUsw5'

        Connect using access token
    .EXAMPLE
        Connect-Immich -BaseURL 'https://immich.domain.com' -Credentials (Get-Credential)

        Connect using username and password
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'AccessToken')]

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BaseURL,
        [Parameter(ParameterSetName = 'AccessToken')][string]$AccessToken,
        [Parameter(ParameterSetName = 'Credentials')][pscredential]$Credential,
        [switch]$PassThru
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'AccessToken'
        {
            $AccessTokenSS = ConvertTo-SecureString -String $AccessToken -AsPlainText -Force
            Remove-Variable -Name AccessToken
            $script:ImmichSession = [ImmichSession]::New($BaseURL, $AccessTokenSS)
        }
        'Credentials'
        {
            $script:ImmichSession = [ImmichSession]::New($BaseURL, $Credential)
        }
    }

    if ($Passthru)
    {
        return $script:ImmichSession
    }
}
