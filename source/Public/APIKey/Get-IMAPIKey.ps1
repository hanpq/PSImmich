function Get-IMAPIKey
{
    <#
    .DESCRIPTION
        Retreives api keys
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines an api key id to get
    .EXAMPLE
        Get-IMAPIKey

        Retreives all api keys
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Session', Justification = 'FP')]
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
            switch ($PSCmdlet.ParameterSetName)
            {
                'list'
                {
                    InvokeImmichRestMethod -Method Get -RelativePath '/api-keys' -ImmichSession:$Session
                }
                'id'
                {
                    InvokeImmichRestMethod -Method Get -RelativePath "/api-keys/$CurrentID" -ImmichSession:$Session
                }
            }
        }
    }

}
#endregion
