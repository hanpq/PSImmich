function Get-IMPerson
{
    <#
    .DESCRIPTION
        Retreives Immich person
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific person to be retreived
    .PARAMETER withHidden
        Defines if hidden should be returned or not. Do not specify if either should be returned.
    .PARAMETER IncludeStatistics
        Defines if statistics should be returned for the person
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
        [ApiParameter('withHidden')]
        [switch]
        $WithHidden,

        [Parameter(ParameterSetName = 'id')]
        [switch]
        $IncludeStatistics
    )

    BEGIN
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
        }
    }

    PROCESS
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/people' -ImmichSession:$Session -QueryParameters $QueryParameters
            }
            'id'
            {
                $Person = InvokeImmichRestMethod -Method Get -RelativePath "/people/$id" -ImmichSession:$Session -QueryParameters $QueryParameters
                if ($IncludeStatistics)
                {
                    $PersonStats = InvokeImmichRestMethod -Method Get -RelativePath "/people/$id/statistics" -ImmichSession:$Session
                    $Person | Add-Member -MemberType NoteProperty -Name AssetCount -Value $PersonStats.assets
                }
                $Person
            }
        }
    }
}
#endregion
