[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'JWT token retreived in plain text')]
class ImmichSession
{
    [string]$BaseUri
    [string]$AuthMethod
    [securestring]$AccessToken
    [boolean]$AccessTokenValid
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

    ImmichSession (
        [string]$BaseUri,
        [string]$AuthMethod,
        [securestring]$AccessToken,
        [boolean]$AccessTokenValid,
        [pscredential]$Credential,
        [securestring]$JWT,
        [string]$ImmichVersion,
        [string]$SessionID
    )
    {
        Write-Debug -Message 'ImmichSession.Class; Running constructor manual'
        $this.BaseUri = $BaseUri
        $this.APIUri = "$BaseUri/api"
        $this.AuthMethod = $AuthMethod
        $this.AccessToken = $AccessToken
        $this.AccessTokenValid = $AccessTokenValid
        $this.Credential = $Credential
        $this.JWT = $JWT
        $this.ImmichVersion = $ImmichVersion
        $this.SessionID = $SessionID
    }

    ValidateToken()
    {
        try
        {
            if ($this.AuthMethod -eq 'Credential')
            {
                $Secret = $this.JWT
            }
            else
            {
                $Secret = $this.AccessToken
            }
            $Result = ValidateToken -Type $this.AuthMethod -ApiURL $this.ApiUri -Secret $Secret
        }
        catch
        {
            $this.AccessTokenValid = $false
            throw $_.Exception.message
        }
        if ($Result)
        {
            $this.AccessTokenValid = $true
        }
        else
        {
            $this.AccessTokenValid = $false
            throw 'AccessToken is not valid, please reconnect'
        }
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
        $this.ValidateToken()
        $Status = InvokeImmichRestMethod -Method:'Get' -ImmichSession $this -RelativePath '/server/version'
        $this.ImmichVersion = "$($Status.Major).$($Status.Minor).$($Status.Patch)"
        Remove-Variable -Name Status
    }

}
