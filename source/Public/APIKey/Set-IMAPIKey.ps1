function Set-IMAPIKey
{
    <#
    .DESCRIPTION
        Sets name of an apikey
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the id of the API key
    .PARAMETER name
        Defines the name of the new album
    .EXAMPLE
        Set-IMAPIKey

        Sets name of an apikey
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $id,

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
        InvokeImmichRestMethod -Method PUT -RelativePath "/api-key/$id" -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
