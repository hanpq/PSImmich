function Get-IMStack
{
    <#
    .SYNOPSIS
        Retrieves asset stacks.
    .DESCRIPTION
        Gets stacks that group related assets together (like photo bursts or HDR sets).
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific stack ID to retrieve.
    .PARAMETER PrimaryAssetId
        Filter stacks by primary asset ID.
    .EXAMPLE
        Get-IMStack

        Gets all asset stacks.
    .EXAMPLE
        Get-IMStack -Id 'stack-id'

        Gets specific stack details.

        Retrieves a specific Immich stack by ID
    .EXAMPLE
        Get-IMStack -PrimaryAssetId <assetId>

        Retrieves stacks filtered by primary asset ID
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(ParameterSetName = 'list')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PrimaryAssetId
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                # Only bound parameters are passed, so an unset PrimaryAssetId is not sent as a query value.
                $SearchParameters = @{ ImmichSession = $Session }
                if ($PrimaryAssetId)
                {
                    $SearchParameters.PrimaryAssetId = $PrimaryAssetId
                }
                Invoke-ImmichApiSearchStacks @SearchParameters | ForEach-Object { [StackResponseDto]::new($PSItem) }
            }
            'id'
            {
                Invoke-ImmichApiGetStack -Id $Id -ImmichSession $Session | ForEach-Object { [StackResponseDto]::new($PSItem) }
            }
        }
    }
}
