function Set-IMMemory
{
    <#
    .DESCRIPTION
        Updates an Immich memory
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines memory to update
    .PARAMETER isSaved
        Defines if the memory is saved
    .PARAMETER importPaths
        Defines import paths
    .PARAMETER memoryAt
        Defines the memoryAt datetime
    .PARAMETER seenAt
        Defines the seenAt datetime
    .EXAMPLE
        Set-IMMemory -id <memoryid> -memoryAt "2024-01-01 00:00:00"

        Update an Immich memory
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter()]
        [boolean]
        $isSaved,

        [Parameter()]
        [datetime]
        $MemoryAt,

        [Parameter()]
        [datetime]
        $SeenAt

    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'isSaved', 'MemoryAt', 'SeenAt')
    }

    PROCESS
    {
        $id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/memories/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
