function Get-IMSharedLink
{
    <#
    .DESCRIPTION
        Retreives Immich shared link
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific shared link id to be retreived
    .PARAMETER password
        ...
    .PARAMETER token
        ...
    .PARAMETER Me
        Defines that the currently connected users information is retreived.
    .EXAMPLE
        Get-IMSharedLink

        Retreives Immich shared link
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

        [Parameter(ParameterSetName = 'me')]
        [securestring]
        $password,

        [Parameter(ParameterSetName = 'me')]
        [string]
        $token,

        [Parameter(Mandatory, ParameterSetName = 'me')]
        [switch]
        $Me
    )

    BEGIN
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'password', 'token')
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/shared-links' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                $id | ForEach-Object {
                    InvokeImmichRestMethod -Method Get -RelativePath "/shared-links/$PSItem" -ImmichSession:$Session
                }
            }
            'me'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/shared-links/me' -ImmichSession:$Session
            }
        }
    }
}
#endregion
