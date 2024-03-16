function Test-IMAccessToken
{
    <#
    .DESCRIPTION
        Verifies that the provided access token is valid
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .EXAMPLE
        Test-IMAccessToken

        Verifies that the provided access token is valid
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
