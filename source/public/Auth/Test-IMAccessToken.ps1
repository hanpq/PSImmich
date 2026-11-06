function Test-IMAccessToken
{
    <#
    .SYNOPSIS
        Tests the validity of an Immich access token
    .DESCRIPTION
        Verifies that the provided access token is valid and can be used for authentication with the Immich server.
        Returns a boolean value indicating whether the token is valid.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
        If not specified, uses the default session.
    .EXAMPLE
        Test-IMAccessToken

        Tests the validity of the access token in the default session.
    .EXAMPLE
        Test-IMAccessToken -Session $MySession

        Tests the validity of the access token in a specific session.
    .EXAMPLE
        if (Test-IMAccessToken) { Write-Host 'Token is valid' } else { Write-Host 'Token is invalid' }

        Uses the return value to conditionally execute code based on token validity.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/auth/validateToken' -ImmichSession:$Session
    if ($Result)
    {
        return $Result.AuthStatus
    }
    else
    {
        return $false
    }
}
#endregion
