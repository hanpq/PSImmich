function Get-IMPasskey
{
    <#
    .SYNOPSIS
        Retrieves passkeys for the current user.
    .DESCRIPTION
        Lists the current user's passkeys or retrieves specific passkeys by ID.
        Responses are returned as received so nullable fields are preserved.
        Requires the passkey.read permission.
    .PARAMETER Session
        Optional Immich session to use instead of the default session.
    .PARAMETER Id
        UUIDs of passkeys to retrieve. Accepts values or objects from the pipeline.
    .EXAMPLE
        Get-IMPasskey

        Lists passkeys for the current user.
    .EXAMPLE
        Get-IMPasskey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db'

        Retrieves one passkey.
    #>
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            Invoke-ImmichApiSearchPasskeys -ImmichSession $Session
        }
        else
        {
            foreach ($CurrentId in $Id)
            {
                Invoke-ImmichApiGetPasskey -Id $CurrentId -ImmichSession $Session
            }
        }
    }
}
