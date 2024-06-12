function Get-IMMemory
{
    <#
    .DESCRIPTION
        Retreives Immich memory
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific memory id to be retreived
    .EXAMPLE
        Get-IMMemory

        Retreives Immich memory
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
                InvokeImmichRestMethod -Method Get -RelativePath "/memories/$PSItem" -ImmichSession:$Session
            }
        }
    }

    END
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            InvokeImmichRestMethod -Method Get -RelativePath '/memories' -ImmichSession:$Session
        }
    }
}
#endregion
