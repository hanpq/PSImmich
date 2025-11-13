function New-IMPerson
{
    <#
    .DESCRIPTION
        Adds a new Immich person
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER birthDate
        Defines a birthdate for the person
    .PARAMETER isHidden
        Defines if the person is hidden
    .PARAMETER name
        Defines the name of the person
    .EXAMPLE
        New-IMPerson -Name 'John Smith'

        Adds a new Immich person
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
        $Name,

        [Parameter()]
        [ApiParameter('isHidden')]
        [switch]
        $IsHidden,

        [Parameter()]
        [ApiParameter('birthDate')]
        [datetime]
        $BirthDate
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
    InvokeImmichRestMethod -Method Post -RelativePath '/people' -ImmichSession:$Session -Body:$BodyParameters
}
#endregion
