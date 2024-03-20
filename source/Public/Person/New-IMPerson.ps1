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
        [string]
        $Name,

        [Parameter()]
        [switch]
        $IsHidden,

        [Parameter()]
        [datetime]
        $BirthDate
    )

    $Body = @{}
    $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'BirthDate', 'IsHidden', 'Name' -namemapping @{BirthDate = 'birthDate'; IsHidden = 'isHidden'; Name = 'name' })
    InvokeImmichRestMethod -Method Post -RelativePath '/person' -ImmichSession:$Session -Body:$Body
}
#endregion
