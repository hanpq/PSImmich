function Rename-IMAPIKey
{
    <#
    .DESCRIPTION
        Sets name of an apikey
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the id of the API key to update
    .PARAMETER name
        Defines a new name for the apikey
    .EXAMPLE
        Rename-IMAPIKey

        Sets name of an apikey
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
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
