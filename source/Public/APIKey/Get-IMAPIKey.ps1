function Get-IMAPIKey
{
    <#
    .SYNOPSIS
        Retrieves Immich API keys
    .DESCRIPTION
        Retrieves one or more API keys from the Immich server. Can retrieve all API keys or specific keys by ID.
        API keys are used for programmatic access to the Immich API.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of specific API key(s) to retrieve. Accepts pipeline input and multiple values.
    .EXAMPLE
        Get-IMAPIKey

        Retrieves all API keys for the current user.
    .EXAMPLE
        Get-IMAPIKey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves a specific API key by its ID.
    .EXAMPLE
        'key1-uuid','key2-uuid' | Get-IMAPIKey

        Retrieves multiple API keys by piping their IDs.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem
            switch ($PSCmdlet.ParameterSetName)
            {
                'list'
                {
                    InvokeImmichRestMethod -Method Get -RelativePath '/api-keys' -ImmichSession:$Session | AddCustomType IMAPIKey
                }
                'id'
                {
                    InvokeImmichRestMethod -Method Get -RelativePath "/api-keys/$CurrentID" -ImmichSession:$Session | AddCustomType IMAPIKey
                }
            }
        }
    }

}
#endregion
