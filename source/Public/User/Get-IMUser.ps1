function Get-IMUser
{
    <#
    .DESCRIPTION
        Retreives Immich user
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific user id to be retreived
    .PARAMETER isAll
        asd
    .PARAMETER Me
        Defines that the currently connected users information is retreived.
    .EXAMPLE
        Get-IMUser

        Retreives Immich user
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
        [boolean]
        $isAll,

        [Parameter(Mandatory,ParameterSetName = 'me')]
        [switch]
        $Me
    )

    BEGIN
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'isAll')
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/user' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                $id | ForEach-Object {
                    InvokeImmichRestMethod -Method Get -RelativePath "/user/info/$PSItem" -ImmichSession:$Session
                }
            }
            'me' {
                InvokeImmichRestMethod -Method Get -RelativePath '/user/me' -ImmichSession:$Session
            }
        }
    }
}
#endregion
