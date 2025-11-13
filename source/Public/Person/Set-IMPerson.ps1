function Set-IMPerson
{
    <#
    .DESCRIPTION
        Updates an Immich asset
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines the person to update
    .PARAMETER BirthDate
        Defines birth date
    .PARAMETER FaceAssetId
        Defines an face asset id
    .PARAMETER IsHidden
        Defines if the person should be hidden
    .PARAMETER Name
        Defines the name of the person
    .PARAMETER Color
        Defines the color associated with the person
    .PARAMETER IsFavorite
        Defines if the person is marked as favorite
    .EXAMPLE
        Set-IMPerson -id <personid> -Name 'John Smith'

        Update an Immich asset
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
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
        [ApiParameter('birthDate')]
        [datetime]
        $BirthDate,

        [Parameter()]
        [ApiParameter('color')]
        [string]
        $Color,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [boolean]
        $IsFavorite,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('featureFaceAssetId')]
        [string]
        $FaceAssetId,

        [Parameter()]
        [ApiParameter('isHidden')]
        [boolean]
        $IsHidden,

        [Parameter()]
        [ApiParameter('name')]
        [string]
        $Name

    )

    BEGIN
    {
        $ObjectArray = [array]@()
    }

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            $BodyParameters = @{}
            $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
            $BodyParameters.id = $CurrentID
            $ObjectArray += $BodyParameters
        }
    }

    END
    {
        if ($PSCmdlet.ShouldProcess(($ObjectArray.id -join ','), 'PUT'))
        {
            $BodyResult = @{
                people = $ObjectArray
            }
            InvokeImmichRestMethod -Method Put -RelativePath '/people' -ImmichSession:$Session -Body:$BodyResult
        }
    }

}
#endregion
