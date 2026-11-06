function Copy-IMAssetInfo
{
    <#
    .SYNOPSIS
        Copies asset information from one asset to another
    .DESCRIPTION
        Copies various properties and associations like albums, tags, shared links, sidecar data,
        and stack information from a source asset to a target asset. This is useful for
        synchronizing metadata between similar assets or transferring properties during
        asset management workflows.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER SourceId
        The UUID of the source asset from which to copy information. This parameter is mandatory.
    .PARAMETER TargetId
        The UUID of the target asset to which information will be copied. This parameter is mandatory.
    .PARAMETER Albums
        Copy album associations from source to target asset. If no switches are specified, all information is copied.
    .PARAMETER Metadata
        Copy metadata from source to target asset. If no switches are specified, all information is copied.
    .PARAMETER SharedLinks
        Copy shared link associations from source to target asset. If no switches are specified, all information is copied.
    .PARAMETER Sidecar
        Copy sidecar data from source to target asset. If no switches are specified, all information is copied.
    .PARAMETER Stack
        Copy stack information from source to target asset. If no switches are specified, all information is copied.
    .EXAMPLE
        Copy-IMAssetInfo -SourceId 'source-uuid' -TargetId 'target-uuid'

        Copies all available information from the source asset to the target asset.
    .EXAMPLE
        Copy-IMAssetInfo -SourceId 'source-uuid' -TargetId 'target-uuid' -Albums -Metadata

        Copies only album associations and metadata from source to target asset.
    .EXAMPLE
        Copy-IMAssetInfo -SourceId 'source-uuid' -TargetId 'target-uuid' -Albums:$false

        Copies all information except albums from source to target asset.
    .EXAMPLE
        'target1-uuid', 'target2-uuid' | ForEach-Object { Copy-IMAssetInfo -SourceId 'source-uuid' -TargetId $_ }

        Copies information from one source asset to multiple target assets.
    .NOTES
        This cmdlet uses the PUT /assets/copy endpoint which supports selective copying of asset properties.
        All copy options default to $true, meaning all information is copied unless specifically disabled.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, retreived through PSBoundParameters')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('sourceId')]
        [string]
        $SourceId,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('targetId')]
        [string]
        $TargetId,

        [Parameter()]
        [ApiParameter('albums')]
        [switch]
        $Albums,

        [Parameter()]
        [ApiParameter('metadata')]
        [switch]
        $Metadata,

        [Parameter()]
        [ApiParameter('sharedLinks')]
        [switch]
        $SharedLinks,

        [Parameter()]
        [ApiParameter('sidecar')]
        [switch]
        $Sidecar,

        [Parameter()]
        [ApiParameter('stack')]
        [switch]
        $Stack
    )

    process
    {
        if ($PSCmdlet.ShouldProcess("Copy asset information from $SourceId to $TargetId", 'Copy Asset Information'))
        {
            # Check if only SourceId and TargetId are specified (and optionally Session)
            $switchParams = @('Albums', 'Metadata', 'SharedLinks', 'Sidecar', 'Stack')
            $specifiedSwitches = $switchParams | Where-Object { $PSBoundParameters.ContainsKey($_) }

            # If no specific switches are specified, copy everything (default behavior)
            if ($specifiedSwitches.Count -eq 0)
            {
                $PSBoundParameters.Albums = $true
                $PSBoundParameters.Metadata = $true
                $PSBoundParameters.SharedLinks = $true
                $PSBoundParameters.Sidecar = $true
                $PSBoundParameters.Stack = $true
            }

            $BodyParameters = @{}
            $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

            InvokeImmichRestMethod -Method PUT -RelativePath '/assets/copy' -ImmichSession:$Session -Body $BodyParameters
        }
    }
}
