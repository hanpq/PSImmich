function Get-IMLibrary
{
    <#
    .SYNOPSIS
        Retrieves Immich libraries
    .DESCRIPTION
        Retrieves one or more libraries from Immich. Libraries are collections of assets that can be
        managed separately with different settings, permissions, and storage locations.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Id
        The UUID(s) of specific library(ies) to retrieve. Accepts pipeline input and multiple values.
    .PARAMETER OwnerId
        Retrieves libraries owned by a specific user UUID. Only applicable when listing libraries.
    .PARAMETER IncludeStatistics
        Includes detailed statistics (asset counts, sizes, etc.) in the returned library objects.
        Only applicable when retrieving specific libraries by ID.
    .EXAMPLE
        Get-IMLibrary

        Retrieves all libraries accessible to the current user.
    .EXAMPLE
        Get-IMLibrary -Id 'library-uuid' -IncludeStatistics

        Retrieves a specific library with detailed statistics.
    .EXAMPLE
        Get-IMLibrary -OwnerId 'user-uuid'

        Retrieves all libraries owned by a specific user.
    .EXAMPLE
        Get-IMLibrary | Where-Object {$_.type -eq 'EXTERNAL'}

        Retrieves only external libraries (those that scan existing folders).
    .NOTES
        Libraries can be either UPLOAD (for uploading new assets) or EXTERNAL (for scanning existing folders).
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter(ParameterSetName = 'id')]
        [switch]
        $IncludeStatistics,

        [Parameter(ParameterSetName = 'list')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $ownerId
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $id | ForEach-Object {
                $CurrentID = $PSItem
                $Result = InvokeImmichRestMethod -Method Get -RelativePath "/libraries/$CurrentID" -ImmichSession:$Session
                if ($IncludeStatistics)
                {
                    $Stats = InvokeImmichRestMethod -Method GET -RelativePath "/libraries/$CurrentID/statistics" -ImmichSession:$Session
                    $Result | Add-Member -MemberType NoteProperty -Name 'Statistics' -Value $Stats
                }
                $Result
            }
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            if ($ownerId)
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/libraries' -ImmichSession:$Session | Where-Object { $_.ownerid -eq $ownerid }
            }
            else
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/libraries' -ImmichSession:$Session
            }
        }
    }
}
#endregion
