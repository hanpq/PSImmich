function Get-IMPerson
{
    <#
    .SYNOPSIS
        Retrieves person records from face recognition.
    .DESCRIPTION
        Gets people identified by Immich's face recognition with optional filtering and statistics.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific person ID to retrieve. Supports pipeline input.
    .PARAMETER WithHidden
        Include or exclude hidden people. Omit to return all.
    .PARAMETER IncludeStatistics
        Include asset count and other statistics for each person.
    .EXAMPLE
        Get-IMPerson -IncludeStatistics

        Gets all people with asset counts.
    .EXAMPLE
        Get-IMPerson -Id 'bf973405-3f2a-48d2-a687-2ed4167164be'

        Gets specific person details.
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

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                $ApiArguments = @{ ImmichSession = $Session }
                if ($PSBoundParameters.ContainsKey('WithHidden')) { $ApiArguments.WithHidden = $WithHidden.IsPresent }
                Invoke-ImmichApiGetAllPeople @ApiArguments | ForEach-Object { [PersonResponseDto]::new($PSItem) }
            }
            'id'
            {
                $Person = [PersonResponseDto]::new((Invoke-ImmichApiGetPerson -Id $id -ImmichSession $Session))
                if ($IncludeStatistics)
                {
                    $PersonStats = Invoke-ImmichApiGetPersonStatistics -Id $id -ImmichSession $Session
                    $Person | Add-Member -MemberType NoteProperty -Name AssetCount -Value $PersonStats.assets
                }
                $Person
            }
        }
    }
}
#endregion
