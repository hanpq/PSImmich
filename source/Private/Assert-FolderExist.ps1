function Assert-FolderExist
{
    <#
    .SYNOPSIS
        Verify and create folder
    .DESCRIPTION
        Verifies that a folder path exists, if not it will create it
    .PARAMETER Path
        Defines the path to be validated
    .EXAMPLE
        'C:\Temp' | Assert-FolderExist

        This will verify that the path exists and if it does not the folder will be created
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Path
    )

    process
    {
        $exists = Test-Path -Path $Path -PathType Container
        if (!$exists)
        {
            $null = New-Item -Path $Path -ItemType Directory
        }
    }
}
