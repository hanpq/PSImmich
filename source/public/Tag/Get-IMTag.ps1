function Get-IMTag
{
    <#
    .SYNOPSIS
        Retrieves asset tags.
    .DESCRIPTION
        Gets tags used for organizing and categorizing assets.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific tag ID to retrieve.
    .EXAMPLE
        Get-IMTag

        Gets all available tags.
    .EXAMPLE
        Get-IMTag -Id 'tag-id'

        Gets specific tag details.
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

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'id')
        {
            $id | ForEach-Object {
                $CurrentID = $PSItem
                Invoke-ImmichApiGetTagById -Id $CurrentID -ImmichSession $Session
            }
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            Invoke-ImmichApiGetAllTags -ImmichSession $Session
        }
    }
}
#endregion
