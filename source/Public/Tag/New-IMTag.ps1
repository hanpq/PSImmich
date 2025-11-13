function New-IMTag
{
    <#
    .DESCRIPTION
        Creates a new Immich tag
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER name
        Defines a name for the new tag
    .PARAMETER type
        Defines the type of tag to create. Valid values, OBJECT, FACE, CUSTOM
    .EXAMPLE
        New-IMTag -name 'Dogs' -type OBJECT

        Creates a new Immich tag
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ApiParameter('name')]
        [string]
        $Name
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    InvokeImmichRestMethod -Method Post -RelativePath '/tags' -ImmichSession:$Session -Body:$BodyParameters

}
#endregion
