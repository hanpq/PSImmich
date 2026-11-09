function Get-IMPluginTemplate
{
    <#
    .SYNOPSIS
        Retrieves Immich workflow templates provided by plugins
    .DESCRIPTION
        Retrieves the workflow templates that installed plugins provide. Each template is a predefined set of workflow steps that can be used as a starting point when creating a workflow.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .EXAMPLE
        Get-IMPluginTemplate

        Retrieves all workflow templates provided by installed plugins.
    .EXAMPLE
        Get-IMPluginTemplate | Where-Object { $PSItem.trigger -eq 'AssetCreate' }

        Retrieves the workflow templates that are triggered by asset creation.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null
    )

    process
    {
        Invoke-ImmichApiSearchPluginTemplates -ImmichSession $Session | ForEach-Object { [PluginTemplateResponseDto]::new($PSItem) }
    }
}
