function Remove-IMFace
{
    <#
    .SYNOPSIS
        Removes face detections from Immich
    .DESCRIPTION
        Deletes face detections identified by their IDs. Optionally can be force deleted to bypass normal deletion checks.
        Use this to clean up incorrect face detections or remove faces that should not be tracked.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of the face detection(s) to remove. Accepts pipeline input and multiple values.
    .PARAMETER Force
        Force delete the face detection, bypassing normal deletion checks.
    .EXAMPLE
        Remove-IMFace -Id 'face-uuid'

        Removes the specified face detection with confirmation prompt.
    .EXAMPLE
        @('face1-uuid', 'face2-uuid') | Remove-IMFace -Force

        Force removes multiple face detections via pipeline without confirmation.
    .EXAMPLE
        Get-IMFace -Id 'asset-uuid' | Where-Object {$_.person -eq $null} | Remove-IMFace

        Removes all unidentified face detections from an asset.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing face detections.
        Use caution with the -Force parameter as it bypasses safety checks.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP, parameter handled through PSBoundParameters')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $Id,

        [Parameter()]
        [ApiParameter('force')]
        [switch]
        $Force
    )

    process
    {
        $Id | ForEach-Object {
            $CurrentID = $PSItem

            if ($PSCmdlet.ShouldProcess($CurrentID, 'Remove Face Detection'))
            {
                $BodyParameters = @{}
                $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

                InvokeImmichRestMethod -Method DELETE -RelativePath "/faces/$CurrentID" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
