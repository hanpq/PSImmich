function Rename-IMPasskey
{
    <#
    .SYNOPSIS
        Updates the name of a passkey.
    .DESCRIPTION
        Renames a passkey or clears its name. Requires the passkey.update permission.
        Responses are returned as received so nullable fields are preserved.
    .PARAMETER Session
        Optional Immich session to use instead of the default session.
    .PARAMETER Id
        UUID of the passkey. Accepts a value or an object from the pipeline.
    .PARAMETER Name
        New nonempty passkey name.
    .PARAMETER ClearName
        Clears the passkey name by sending an explicit null value.
    .EXAMPLE
        Rename-IMPasskey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' -Name 'Security key'

        Renames the specified passkey.
    .EXAMPLE
        Get-IMPasskey -Id 'bde7ceba-f301-4e9e-87a2-163937a2a3db' | Rename-IMPasskey -ClearName

        Clears the passkey's name.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'name')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(Mandatory, ParameterSetName = 'name')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'clear')]
        [ValidateScript({ $_ -eq $true })]
        [switch]
        $ClearName
    )

    process
    {
        if ($PSCmdlet.ShouldProcess($Id, 'Update passkey name'))
        {
            $Body = @{ name = $Name }
            if ($ClearName)
            {
                $Body.name = $null
            }
            Invoke-ImmichApiUpdatePasskey -Id $Id -Body $Body -ImmichSession $Session
        }
    }
}
