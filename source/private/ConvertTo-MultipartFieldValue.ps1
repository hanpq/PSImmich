function ConvertTo-MultipartFieldValue
{
    <#
    .DESCRIPTION
        Converts a multipart form field value to its string form. Immich only accepts lowercase
        'true' and 'false' for boolean form fields, so booleans and switches are not written as
        PowerShell's 'True' and 'False'.
    .PARAMETER Value
        The form field value.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Ignored, internal function')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value
    )

    if ($Value -is [bool] -or $Value -is [System.Management.Automation.SwitchParameter])
    {
        return ([bool]$Value).ToString().ToLowerInvariant()
    }

    return $Value.ToString()
}
