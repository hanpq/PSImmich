function Connect-Immich
{
    <#
    .DESCRIPTION
        Connect to a Immich instance
    .PARAMETER BaseURL
        Defines the base URL to the portainer instance

        -BaseURL 'https://portainer.contoso.com'
    .PARAMETER AccessToken
        Connects to portainer using a access token. This AccessToken can be generated from the Immich Web GUI.

        -AccessToken 'ptr_ABoR54bB1NUc4aNY0F2PhppP1tVDu2Husr3vEbPUsw5'
    .PARAMETER Credential
        Connect to portainer using username and password. Parameter accepts a PSCredentials object

        -Credential (Get-Credential)
    .PARAMETER PassThru
        This parameter will cause the function to return a ImmichSession object that can be stored in a variable and referensed with the -Session parameter on most cmdlets.

        -PassThru
    .EXAMPLE
        Connect-Immich -BaseURL 'https://portainer.contoso.com' -AccessToken 'ptr_ABoR54bB1NUc4aNY0F2PhppP1tVDu2Husr3vEbPUsw5='

        Connect using access token
    .EXAMPLE
        Connect-Immich -BaseURL 'https://portainer.contoso.com' -Credentials (Get-Credential)

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
