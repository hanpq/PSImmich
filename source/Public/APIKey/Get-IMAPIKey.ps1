function Get-IMAPIKey
{
    <#
    .DESCRIPTION
        Retreives Immich api key
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines an api key id to query
    .EXAMPLE
        Get-IMAPIKey

        Retreives Immich api key
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]]
        $id
    )

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            switch ($PSCmdlet.ParameterSetName)
            {
                'list'
                {
                    InvokeImmichRestMethod -Method Get -RelativePath '/api-key' -ImmichSession:$Session
                }
                'id'
                {
                    InvokeImmichRestMethod -Method Get -RelativePath "/api-key/$CurrentID" -ImmichSession:$Session
                }
            }
        }
    }

}
#endregion
