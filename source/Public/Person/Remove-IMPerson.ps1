function Remove-IMPerson
{
    <#
    .SYNOPSIS
        Removes people from Immich
    .DESCRIPTION
        Removes one or more people from Immich. This function uses the bulk delete endpoint
        to efficiently remove multiple people. When people are removed, all associated face
        detections and person data will be permanently deleted.
    .PARAMETER Session
        Optionally define an Immich session object to use. This is useful when you are connected to more than one Immich instance.
    .PARAMETER Ids
        The UUID(s) of the person/people to remove. Accepts pipeline input and multiple values.
        These are the person IDs returned by Get-IMPerson.
    .EXAMPLE
        Remove-IMPerson -Ids 'person-uuid'

        Removes the specified person with confirmation prompt.
    .EXAMPLE
        @('person1-uuid', 'person2-uuid') | Remove-IMPerson

        Removes multiple people via pipeline.
    .EXAMPLE
        Get-IMPerson | Where-Object {$_.name -eq ''} | Remove-IMPerson -Confirm:$false

        Removes all unnamed people without confirmation prompts.
    .EXAMPLE
        Remove-IMPerson -Ids 'person-uuid' -WhatIf

        Shows what would be removed without actually performing the deletion.
    .NOTES
        This cmdlet supports ShouldProcess and will prompt for confirmation before removing people.
        Removing a person will permanently delete all associated face detections and person data.
        This action cannot be undone.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        [Alias('id')]
        $Ids
    )

    begin
    {
        $BodyParameters = @{
            ids = @()
        }
    }

    process
    {
        $Ids | ForEach-Object {
            $BodyParameters.ids += $psitem
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess(($BodyParameters.ids -join ','), 'DELETE'))
        {
            InvokeImmichRestMethod -Method Delete -RelativePath '/people' -ImmichSession:$Session -Body:$BodyParameters
        }
    }

}
#endregion
