function Get-IMTag
{
    <#
    .DESCRIPTION
        Retreives Immich tag
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific tag id to be retreived
    .EXAMPLE
        Get-IMTag

        Retreives Immich tag
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id
    )

    PROCESS
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $id | ForEach-Object {
                $CurrentID = $PSItem
                InvokeImmichRestMethod -Method Get -RelativePath "/tags/$CurrentID" -ImmichSession:$Session
            }
        }
    }

    END
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/tags' -ImmichSession:$Session
        }
    }
}
#endregion
