function New-IMAPIKey
{
    <#
    .DESCRIPTION
        Adds a new an api key
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER name
        Defines the name of the new album
    .EXAMPLE
        New-IMAPIKey

        Adds a new an api key
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [string]
        $name
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'name')
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method POST -RelativePath '/api-key' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
