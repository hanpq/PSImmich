function Remove-IMPersonAccess
{
    <#
    .SYNOPSIS
        Removes people access granted to other users
    .DESCRIPTION
        Revokes access that was previously granted to a user for a person. Accepts the output of
        Get-IMPersonAccess so that access can be revoked from the pipeline.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER PersonId
        The UUID of the person whose access should be revoked.
    .PARAMETER SharedWithId
        The UUID of the user whose access should be revoked.
    .PARAMETER SharedById
        The UUID of the user that originally granted the access. Optional.
    .EXAMPLE
        Remove-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'

        Revokes the user's access to the specified person, after confirmation.
    .EXAMPLE
        Get-IMPersonAccess -Direction shared-by | Remove-IMPersonAccess -Confirm:$false

        Revokes all access the current user has granted, without confirmation prompts.
    .NOTES
        Supports -WhatIf and -Confirm. This changes who can see people and cannot be undone automatically.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PersonId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $SharedWithId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $SharedById
    )

    process
    {
        $Entry = @{
            personId     = $PersonId
            sharedWithId = $SharedWithId
        }

        if ($PSBoundParameters.ContainsKey('SharedById'))
        {
            $Entry.sharedById = $SharedById
        }

        if ($PSCmdlet.ShouldProcess("$PersonId from $SharedWithId", 'DELETE'))
        {
            # The endpoint expects a JSON array even for a single entry, so the body is serialized here.
            $RawBody = ConvertTo-Json -InputObject @($Entry) -Depth 3
            Invoke-ImmichApiRemoveUsersFromPeople -RawBody $RawBody -ImmichSession $Session
        }
    }
}
#endregion
