function Invoke-ImmichMethod
{
    <#
    .DESCRIPTION
        Invokes command
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Headers
        Headers
    .PARAMETER QueryParameters
        Query parameters
    .PARAMETER BodyParameters
        Body parameters
    .PARAMETER Method
        Method
    .PARAMETER RelativeURI
        RelativePath
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
        $Parameters.BodyParameters = $BodyParameters
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
