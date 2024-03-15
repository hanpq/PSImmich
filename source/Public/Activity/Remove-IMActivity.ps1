﻿function Remove-IMActivity
{
    <#
    .DESCRIPTION
        Removes a activity
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        Defines the activity id to be remove
    .EXAMPLE
        Remove-IMActivity

        Removes a activity
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $id
    )

    PROCESS
    {
        if ($PSCmdlet.ShouldProcess($id, 'DELETE')) {
            InvokeImmichRestMethod -Method DELETE -RelativePath "/activity/$id" -ImmichSession:$Session
        }
    }

}
#endregion
