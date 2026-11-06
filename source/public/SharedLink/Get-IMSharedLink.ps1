function Get-IMSharedLink
{
    <#
    .SYNOPSIS
        Retrieves shared links for asset sharing.
    .DESCRIPTION
        Gets shared links that allow external access to assets and albums.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific shared link ID to retrieve.
    .PARAMETER AlbumId
        Filter by album ID to get album shared links.
    .EXAMPLE
        Get-IMSharedLink

        Gets all shared links.
    .EXAMPLE
        Get-IMSharedLink -Id 'link-id'

        Gets specific shared link details.
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
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('albumId')]
        $AlbumId
    )

    begin
    {
        if ($PSCmdlet.ParameterSetName -eq 'list')
        {
            $QueryParameters = @{}
            $QueryParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
        }
    }

    process
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
        }
    }
}
#endregion
