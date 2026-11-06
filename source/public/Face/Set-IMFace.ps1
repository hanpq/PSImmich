function Set-IMFace
{
    <#
    .SYNOPSIS
        Reassigns a face detection to a different person
    .DESCRIPTION
        Reassigns a face detection to another person by updating the person association.
        This is useful for correcting misidentified faces or organizing face detections under the correct person.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER PersonId
        The UUID of the person to assign the face to. This is the target person who will be associated with the face.
    .PARAMETER FaceId
        The UUID of the face detection to reassign. This face will be moved from its current person association to the specified person.
    .EXAMPLE
        Set-IMFace -PersonId 'person-uuid' -FaceId 'face-uuid'

        Reassigns the specified face detection to the target person.
    .EXAMPLE
        Get-IMFace -Id 'asset-uuid' | Where-Object {$_.person -eq $null} |
        ForEach-Object { Set-IMFace -PersonId 'target-person-uuid' -FaceId $_.id }

        Finds all unidentified faces in an asset and assigns them to a specific person.
    .EXAMPLE
        $FaceIds = @('face1-uuid', 'face2-uuid', 'face3-uuid')
        $FaceIds | ForEach-Object { Set-IMFace -PersonId 'person-uuid' -FaceId $_ }

        Reassigns multiple face detections to the same person.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before reassigning faces.
        The operation moves the face from its current person association (if any) to the specified person.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PersonId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $FaceId
    )

    process
    {
        $ConfirmationMessage = "Reassign face '$FaceId' to person '$PersonId'"
        $WhatIfDescription = 'Would reassign face to person'
        $ConfirmCaption = 'Reassign Face'

        if ($PSCmdlet.ShouldProcess($ConfirmationMessage, $WhatIfDescription, $ConfirmCaption))
        {
            $Body = @{
                id = $FaceId
            }

            InvokeImmichRestMethod -Method PUT -RelativePath "/faces/$PersonId" -ImmichSession $Session -Body $Body
        }
    }
}
#endregion
