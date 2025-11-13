function Remove-IMStack
{
    <#
    .SYNOPSIS
        Removes asset stacks.
    .DESCRIPTION
        Deletes stacks and ungroups the contained assets. Assets remain in library.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Stack ID(s) to remove. Supports multiple IDs for bulk deletion.
    .PARAMETER Force
        Suppresses confirmation prompt when specified.
    .EXAMPLE
        Remove-IMStack -Id 'stack-id'

        Removes stack after confirmation.

        Removes the specified stack
    .EXAMPLE
        Remove-IMStack -Id @('stack-1', 'stack-2') -Force

        Removes multiple stacks without confirmation
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidateScript({
                foreach ($stackId in $_)
                {
                    if ($stackId -notmatch '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')
                    {
                        throw "Invalid GUID format: $stackId"
                    }
                }
                $true
            })]
        [string[]]
        $Id,

        [Parameter()]
        [switch]
        $Force
    )

    begin
    {
        if ($Force)
        {
            $ConfirmPreference = 'None'
        }
        $BodyParameters = @{
            ids = @()
        }
    }

    process
    {
        $Id | ForEach-Object {
            $BodyParameters.ids += $psitem
        }
    }

    end
    {
        if ($BodyParameters.ids.Count -eq 0)
        {
            return
        }

        if ($PSCmdlet.ShouldProcess("Stacks: $($BodyParameters.ids -join ',')", 'DELETE'))
        {
            InvokeImmichRestMethod -Method Delete -RelativePath '/stacks' -ImmichSession:$Session -Body:$BodyParameters
        }
    }
}
