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
    .PARAMETER type
        Defines which type of library to retreive
    .PARAMETER ownerId
        Retreive libraries for a user
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

        [Parameter(ParameterSetName = 'list')]
        [ValidateSet('UPLOAD', 'EXTERNAL')]
        [string]
        $type,

        [Parameter(ParameterSetName = 'list')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $ownerId

    )

    BEGIN
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'type')
        }
    }

    PROCESS
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $id | ForEach-Object {
                $CurrentID = $PSItem
                InvokeImmichRestMethod -Method Get -RelativePath "/library/$CurrentID" -ImmichSession:$Session
            }
        }
    }

    END
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            if ($ownerId)
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/library' -ImmichSession:$Session -QueryParameters $QueryParameters | Where-Object { $_.ownerid -eq $ownerid }
            }
            else
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/library' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
        }
    }
}
#endregion
