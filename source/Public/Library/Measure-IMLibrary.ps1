function Measure-IMLibrary
{
    <#
    .DESCRIPTION
        Get library statistics
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific library id to be cleaned up
    .EXAMPLE
        Measure-IMLibrary

        Get library statistics
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
        $id | ForEach-Object {
            $CurrentID = $PSItem
            InvokeImmichRestMethod -Method GET -RelativePath "/library/$CurrentID/statistics" -ImmichSession:$Session
        }

    }
}
#endregion
