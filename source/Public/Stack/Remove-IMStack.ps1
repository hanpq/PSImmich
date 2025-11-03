function Remove-IMStack
{
    <#
    .DESCRIPTION
        Removes Immich stack(s)
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        The stack ID(s) to remove. Can accept multiple IDs for bulk deletion.
    .PARAMETER Force
        Suppress confirmation prompt
    .EXAMPLE
        Remove-IMStack -Id <stackId>

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
            foreach ($stackId in $_) {
                if ($stackId -notmatch '^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$') {
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

    BEGIN
    {
        if ($Force)
        {
            $ConfirmPreference = 'None'
        }
    }

    PROCESS
    {
        if ($Id.Count -eq 1)
        {
            # Single stack deletion using individual endpoint
            if ($PSCmdlet.ShouldProcess("Stack $($Id[0])", "Remove"))
            {
                InvokeImmichRestMethod -Method Delete -RelativePath "/stacks/$($Id[0])" -ImmichSession:$Session
            }
        }
        else
        {
            # Multiple stacks deletion using bulk endpoint
            if ($PSCmdlet.ShouldProcess("$($Id.Count) stacks", "Remove"))
            {
                $BodyParameters = @{
                    ids = $Id
                }
                InvokeImmichRestMethod -Method Delete -RelativePath "/stacks" -ImmichSession:$Session -Body $BodyParameters
            }
        }
    }
}
