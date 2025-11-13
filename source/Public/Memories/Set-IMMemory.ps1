function Set-IMMemory
{
    <#
    .DESCRIPTION
        Updates an Immich memory
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines memory to update
    .PARAMETER IsSaved
        Defines if the memory is saved
    .PARAMETER MemoryAt
        Defines the memoryAt datetime
    .PARAMETER SeenAt
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
        $Id,

        [Parameter()]
        [ApiParameter('isSaved')]
        [boolean]
        $IsSaved,

        [Parameter()]
        [ApiParameter('memoryAt')]
        [datetime]
        $MemoryAt,

        [Parameter()]
        [ApiParameter('seenAt')]
        [datetime]
        $SeenAt

    )

    begin
    {
        $BodyParameters = @{}
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $Id | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem, 'Update'))
            {
                InvokeImmichRestMethod -Method PUT -RelativePath "/memories/$PSItem" -ImmichSession:$Session -Body:$BodyParameters
            }
        }
    }
}
#endregion
