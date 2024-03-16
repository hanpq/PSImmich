function Get-IMPerson
{
    <#
    .DESCRIPTION
        Retreives Immich person
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific person id to be retreived
    .PARAMETER withHidden
        Defines if hidden should be returned or not. Do not specify if either should be returned.
    .EXAMPLE
        Get-IMPerson

        Retreives Immich person
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id,

        [Parameter(ParameterSetName = 'list')]
        [switch]
        $withHidden
    )

    BEGIN
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'withHidden')
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/person' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/person/$id" -ImmichSession:$Session -QueryParameters $QueryParameters
            }
        }
    }
}
#endregion
