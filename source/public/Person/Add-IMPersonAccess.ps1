function Add-IMPersonAccess
{
    <#
    .SYNOPSIS
        Shares people with other users
    .DESCRIPTION
        Gives the specified users access to people with the specified role. Existing access
        for the same users is updated to the new role. Use -PersonId to share specific people,
        or -Everyone to share all people owned by the current user.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER PersonId
        The UUID(s) of the person/people to share. Accepts multiple values.
    .PARAMETER Everyone
        Share all people owned by the current user instead of specific people.
    .PARAMETER SharedWithId
        The UUID(s) of the user(s) to give access to.
    .PARAMETER Role
        The access role to grant: read, write or admin.
    .EXAMPLE
        Add-IMPersonAccess -PersonId 'bf973405-3f2a-48d2-a687-2ed4167164be' -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role read

        Gives the user read access to the specified person.
    .EXAMPLE
        Add-IMPersonAccess -Everyone -SharedWithId '9c4e0006-3a2b-4967-94b6-7e8bb8490a12' -Role write

        Gives the user write access to all people owned by the current user.
    .NOTES
        Supports -WhatIf and -Confirm.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Everyone', Justification = 'Everyone selects the parameter set and is read through ParameterSetName.')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Person')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'Person')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $PersonId,

        [Parameter(Mandatory, ParameterSetName = 'Everyone')]
        [switch]
        $Everyone,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $SharedWithId,

        [Parameter(Mandatory)]
        [ValidateSet('read', 'write', 'admin')]
        [string]
        $Role
    )

    process
    {
        $BodyParameters = @{
            role          = $Role
            sharedWithIds = @($SharedWithId)
        }

        if ($PSCmdlet.ParameterSetName -eq 'Everyone')
        {
            $BodyParameters.type = 'everyone'
            $Target = 'everyone'
        }
        else
        {
            $BodyParameters.personIds = @($PersonId)
            $Target = $PersonId -join ','
        }

        if ($PSCmdlet.ShouldProcess("$Target shared with $($SharedWithId -join ',') as $Role", 'PUT'))
        {
            Invoke-ImmichApiUpsertPeopleUsers -Body $BodyParameters -ImmichSession $Session
        }
    }
}
#endregion
