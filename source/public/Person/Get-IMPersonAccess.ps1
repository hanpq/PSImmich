function Get-IMPersonAccess
{
    <#
    .SYNOPSIS
        Lists which users have access to people
    .DESCRIPTION
        Returns the sharing relationships for people. Each entry describes a person, the user
        that shared it, the user it was shared with, and the access role that was granted.
        All filters are optional and are combined.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Direction
        Limit the results to people shared by the current user (shared-by) or shared with the current user (shared-with).
    .PARAMETER PersonId
        Limit the results to the specified person ID.
    .PARAMETER Role
        Limit the results to the specified access role (read, write or admin).
    .PARAMETER SharedById
        Limit the results to access granted by the specified user ID.
    .PARAMETER SharedWithId
        Limit the results to access granted to the specified user ID.
    .EXAMPLE
        Get-IMPersonAccess

        Returns all people access relationships visible to the current user.
    .EXAMPLE
        Get-IMPersonAccess -Direction shared-by -Role admin

        Returns the admin grants the current user has given to other users.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ValidateSet('shared-by', 'shared-with')]
        [string]
        $Direction,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PersonId,

        [Parameter()]
        [ValidateSet('read', 'write', 'admin')]
        [string]
        $Role,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $SharedById,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $SharedWithId
    )

    process
    {
        $FilterParameters = @{}
        foreach ($Name in 'Direction', 'PersonId', 'Role', 'SharedById', 'SharedWithId')
        {
            if ($PSBoundParameters.ContainsKey($Name))
            {
                $FilterParameters[$Name] = $PSBoundParameters[$Name]
            }
        }

        Invoke-ImmichApiGetUsersForPeople @FilterParameters -ImmichSession $Session
    }
}
#endregion
