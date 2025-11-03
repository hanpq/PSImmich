function Get-IMStack
{
    <#
    .DESCRIPTION
        Retrieves Immich stack information
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines the stack to get
    .PARAMETER PrimaryAssetId
        Only returns stacks that contain the specified primary asset
    .EXAMPLE
        Get-IMStack

        Retrieves all Immich stacks
    .EXAMPLE
        Get-IMStack -Id <stackId>

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

    BEGIN
    {
        $QueryParameters = @{}
        if ($PrimaryAssetId)
        {
            $QueryParameters.primaryAssetId = $PrimaryAssetId
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/stacks' -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMStack
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/stacks/$Id" -ImmichSession:$Session | AddCustomType IMStack
            }
        }
    }
}
