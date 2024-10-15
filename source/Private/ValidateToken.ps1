function ValidateToken
{
    <#
    .DESCRIPTION
        Helper function to validate immich token
    .PARAMETER Type
        Defines the type of authentication to be performed, credential or accesstoken
    .PARAMETER APIUrl
        Defines the immich api url
    .PARAMETER Secret
        Defines the secret to use.
    .EXAMPLE
        ValidateToken -Type 'AccessToken' -ApiURL 'https://immich.contoso.com/api' -Secret (ConvertTo-SecureString -String 'token' -AsPlainText -Force)
    #>
    param (
        $Type,
        $APIUrl,
        $Secret
    )

    switch ($Type)
    {
        'Credential'
        {
            $Result = Invoke-RestMethod -Method Post -Uri "$($ApiUrl)/auth/validateToken" -Headers @{Authorization = "Bearer $(ConvertFromSecureString -SecureString $Secret)" } | Select-Object -Property AuthStatus
            return $Result
        }
        'AccessToken'
        {
            $Result = Invoke-RestMethod -Method Post -Uri "$($ApiUrl)/auth/validateToken" -Headers @{'X-API-Key' = "$(ConvertFromSecureString -SecureString $Secret)" } | Select-Object -Property AuthStatus
            return $Result
        }
    }
}
