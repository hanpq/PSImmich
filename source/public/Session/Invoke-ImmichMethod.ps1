function Invoke-ImmichMethod
{
    <#
    .SYNOPSIS
        Invokes custom Immich API methods.
    .DESCRIPTION
        Makes direct API calls to Immich endpoints with custom parameters and headers.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Headers
        Custom HTTP headers for the request.
    .PARAMETER QueryParameters
        URL query parameters as hashtable.
    .PARAMETER BodyParameters
        Request body parameters.
    .PARAMETER Method
        HTTP method (GET, POST, PUT, DELETE, etc.).
    .PARAMETER RelativeURI
        API endpoint path relative to server URL.
    .PARAMETER ContentType
        ContentType
    .PARAMETER OutFilePath
        OutFilePath
    .EXAMPLE
        Invoke-ImmichMethod

        Retreives all Immich server info properties
    #>

    [CmdletBinding()]
    param(
        [Parameter()][ImmichSession]$Session = $null,

        [Parameter()][hashtable]$Headers,

        [Parameter()][hashtable]$QueryParameters,

        [Parameter()][hashtable]$BodyParameters,

        [Parameter()][string]$Method,

        [Parameter()][string]$RelativeURI,

        [Parameter()][string]$ContentType = 'application/json',

        [Parameter()][system.io.fileinfo]$OutFilePath
    )

    $Parameters = @{
        Method       = $Method
        RelativePath = $RelativeURI
        ContentType  = $ContentType
    }

    if ($QueryParameters)
    {
        $Parameters.QueryParameters = $QueryParameters
    }

    if ($BodyParameters)
    {
        $Parameters.Body = $BodyParameters
    }
    if ($Headers)
    {
        $Parameters.Headers = $Headers
    }
    if ($OutFilePath)
    {
        $Parameters.OutFilePath = $OutFilePath
    }

    InvokeImmichRestMethod @Parameters -ImmichSession:$Session

}
#endregion
