﻿function Start-IMLibraryScan
{
    <#
    .DESCRIPTION
        Start library scan job
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER id
        Defines a specific library id to be cleaned up
    .PARAMETER refreshAllFiles
        asd
    .PARAMETER refreshModifiedFiles
        asd
    .EXAMPLE
        Start-IMLibraryScan

        Start library scan job
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'FP')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'FP')]
    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $id,

        [Parameter()]
        [boolean]
        $refreshAllFiles = $false,

        [Parameter()]
        [boolean]
        $refreshModifiedFiles = $true
    )

    PROCESS
    {
        $id | ForEach-Object {
            $CurrentID = $PSItem
            InvokeImmichRestMethod -Method POST -RelativePath "/library/$CurrentID/scan" -ImmichSession:$Session
        }

    }
}
#endregion
