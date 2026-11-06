function Rename-IMAPIKey
{
    <#
    .SYNOPSIS
        Renames an Immich API key
    .DESCRIPTION
        Updates the name of an existing API key. This helps maintain organized and descriptive names
        for API keys as their usage evolves.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID of the API key to rename. Accepts pipeline input.
    .PARAMETER Name
        The new name for the API key. Should be descriptive to help identify the key's purpose.
    .EXAMPLE
        Rename-IMAPIKey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Name 'Production Backup Script'

        Renames the specified API key to 'Production Backup Script'.
    .EXAMPLE
        Get-IMAPIKey | Where-Object {$_.name -eq 'temp'} | Rename-IMAPIKey -Name 'Mobile App Access'

        Finds an API key named 'temp' and renames it to 'Mobile App Access'.
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
        $Id,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]
        $Name

    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    }

    process
    {
        InvokeImmichRestMethod -Method PUT -RelativePath "/api-keys/$Id" -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
