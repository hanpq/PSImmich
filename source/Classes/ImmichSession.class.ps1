[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'JWT token retreived in plain text')]
class ImmichSession
{
    [string]$BaseUri
    [string]$AuthMethod
    [securestring]$AccessToken
    [pscredential]$Credential
    [securestring]$JWT
    [string]$APIUri
    [string]$ImmichVersion
    [string]$SessionID

    ImmichSession ([string]$BaseUri, [securestring]$AccessToken)
    {
        Write-Debug -Message 'ImmichSession.Class; Running constructor accesstoken'
        $this.SessionID = (New-Guid).Guid
        $this.BaseUri = $BaseUri
        $this.APIUri = "$BaseUri/api"
        $this.AuthMethod = 'AccessToken'
        $this.AccessToken = $AccessToken
        $this.GetStatus()
        Write-Verbose -Message "Connected to Immich instance at $($this.BaseUri) with AccessToken"
    }

    ImmichSession ([string]$BaseUri, [pscredential]$Credential)
    {
        Write-Debug -Message 'ImmichSession.Class; Running constructor credential'
        $this.SessionID = (New-Guid).Guid
        $this.BaseUri = $BaseUri
        $this.APIUri = "$BaseUri/api"
        $this.AuthMethod = 'Credential'
        $this.Credential = $Credential
        $this.AuthenticateCredential()
        $this.GetStatus()
        Write-Verbose -Message "Connected to Immich instance at $($this.BaseUri) with Credentials"
    }

    hidden AuthenticateCredential()
    {
        $BodyObject = @{
            password = $this.Credential.GetNetworkCredential().Password
            email    = $this.Credential.Username
        }
        $JWTResponse = InvokeImmichRestMethod -NoAuth -Method:'Post' -ImmichSession $this -RelativePath '/auth/login' -Body $BodyObject
        $this.JWT = ConvertTo-SecureString -String $JWTResponse.accessToken -AsPlainText -Force
        $this.AccessToken = ConvertTo-SecureString -String $JWTResponse.accessToken -AsPlainText -Force
        Remove-Variable -Name JWTResponse
    }

    hidden GetStatus()
    {
        $Status = InvokeImmichRestMethod -Method:'Get' -ImmichSession $this -RelativePath '/server-info/version'
        $this.ImmichVersion = "$($Status.Major).$($Status.Minor).$($Status.Patch)"
        Remove-Variable -Name Status
    }
}
