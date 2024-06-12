function Get-IMLibrary
{
    <#
    .DESCRIPTION
        Retreives Immich library
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific library id to be retreived
    .PARAMETER ownerId
        Retreive libraries for a user
    .PARAMETER IncludeStatistics
        Includes statistics for the library in the return object
    .EXAMPLE
        Get-IMLibrary

        Retreives Immich library
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

    PROCESS
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

    END
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
