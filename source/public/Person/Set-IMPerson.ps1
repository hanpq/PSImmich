function Set-IMPerson
{
    <#
    .SYNOPSIS
        Updates person information and settings.
    .DESCRIPTION
        Modifies person details like name, birth date, visibility, and face thumbnail.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Person ID to update.
    .PARAMETER BirthDate
        Person's birth date.
    .PARAMETER FaceAssetId
        Asset ID to use as person's face thumbnail.
    .PARAMETER IsHidden
        Set to $true to hide person from interface.
    .PARAMETER Name
        Display name for the person.
    .PARAMETER Color
        Avatar color for the person. One of: primary, pink, red, yellow, blue, green, purple, orange, gray, amber.
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
        [ApiParameter('avatarColor')]
        [ValidateSet('primary', 'pink', 'red', 'yellow', 'blue', 'green', 'purple', 'orange', 'gray', 'amber')]
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

    begin
    {
        $ObjectArray = [array]@()
    }

    process
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            $BodyParameters = @{}
            $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name
            if ($PSBoundParameters.ContainsKey('BirthDate'))
            {
                # Date-only value: a serialized DateTime is shifted to UTC and can land on the previous day.
                $BodyParameters.birthDate = $BirthDate.ToString('yyyy-MM-dd')
            }
            $BodyParameters.id = $CurrentID
            $ObjectArray += $BodyParameters
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess(($ObjectArray.id -join ','), 'PUT'))
        {
            $BodyResult = @{
                people = $ObjectArray
            }
            Invoke-ImmichApiUpdatePeople -Body $BodyResult -ImmichSession $Session
        }
    }

}
#endregion
