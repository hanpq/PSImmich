function pslog
{
    <#
    .SYNOPSIS
        This is simple logging function that automatically log to file. Logging to console is maintained.
    .DESCRIPTION
        This is simple logging function that automatically log to file. Logging to console is maintained.
    .PARAMETER Severity
        Defines the type of log, valid vales are, Success,Info,Warning,Error,Verbose,Debug
    .PARAMETER Message
        Defines the message for the log entry
    .PARAMETER Source
        Defines a source, this is useful to separate log entries in categories for different stages of a process or for each function, defaults to default
    .PARAMETER Throw
        Specifies that when using severity error pslog will throw. This is useful in catch statements so that the terminating error is propagated upwards in the stack.
    .PARAMETER LogDirectoryOverride
        Defines a hardcoded log directory to write the log file to. This defaults to %appdatalocal%\<modulename\logs.
    .PARAMETER DoNotLogToConsole
        Specifies that logs should only be written to the log file and not to the console.
    .EXAMPLE
        pslog Verbose 'Successfully wrote to logfile'
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Sole purpose of function is logging, including console')]
    [cmdletbinding()]
    param(
        [parameter(Position = 0)]
        [ValidateSet('Success', 'Info', 'Warning', 'Error', 'Verbose', 'Debug')]
        [Alias('Type')]
        [string]
        $Severity,

        [parameter(Mandatory, Position = 1)]
        [string]
        $Message,

        [parameter(position = 2)]
        [string]
        $source = 'default',

        [parameter(Position = 3)]
        [switch]
        $Throw,

        [parameter(Position = 4)]
        [string]
        $LogDirectoryOverride,

        [parameter(Position = 5)]
        [switch]
        $DoNotLogToConsole
    )

    begin
    {
        if (-not $LogDirectoryOverride)
        {
            $localappdatapath = [Environment]::GetFolderPath('localapplicationdata') # ie C:\Users\<username>\AppData\Local
            $modulename = $MyInvocation.MyCommand.Module
            $logdir = "$localappdatapath\$modulename\logs"
        }
        else
        {
            $logdir = $LogDirectoryOverride
        }
        $logdir | Assert-FolderExist -Verbose:$VerbosePreference
        $timestamp = (Get-Date)
        $logfilename = ('{0}.log' -f $timestamp.ToString('yyy-MM-dd'))
        $timestampstring = $timestamp.ToString('yyyy-MM-ddThh:mm:ss.ffffzzz')
    }

    process
    {
        switch ($Severity)
        {
            'Success'
            {
                "$timestampstring`t$psitem`t$source`t$message" | Add-Content -Path "$logdir\$logfilename" -Encoding utf8 -WhatIf:$false
                if (-not $DoNotLogToConsole)
                {
                    Write-Host -Object "SUCCESS: $timestampstring`t$source`t$message" -ForegroundColor Green
                }
            }
            'Info'
            {
                "$timestampstring`t$psitem`t$source`t$message" | Add-Content -Path "$logdir\$logfilename" -Encoding utf8 -WhatIf:$false
                if (-not $DoNotLogToConsole)
                {
                    Write-Information -MessageData "$timestampstring`t$source`t$message"
                }
            }
            'Warning'
            {
                "$timestampstring`t$psitem`t$source`t$message" | Add-Content -Path "$logdir\$logfilename" -Encoding utf8 -WhatIf:$false
                if (-not $DoNotLogToConsole)
                {
                    Write-Warning -Message "$timestampstring`t$source`t$message"
                }
            }
            'Error'
            {
                "$timestampstring`t$psitem`t$source`t$message" | Add-Content -Path "$logdir\$logfilename" -Encoding utf8 -WhatIf:$false
                if (-not $DoNotLogToConsole)
                {
                    Write-Error -Message "$timestampstring`t$source`t$message"
                }
                if ($throw)
                {
                    throw
                }
            }
            'Verbose'
            {
                if ($VerbosePreference -ne 'SilentlyContinue')
                {
                    "$timestampstring`t$psitem`t$source`t$message" | Add-Content -Path "$logdir\$logfilename" -Encoding utf8 -WhatIf:$false
                }
                if (-not $DoNotLogToConsole)
                {
                    Write-Verbose -Message "$timestampstring`t$source`t$message"
                }
            }
            'Debug'
            {
                if ($DebugPreference -ne 'SilentlyContinue')
                {
                    "$timestampstring`t$psitem`t$source`t$message" | Add-Content -Path "$logdir\$logfilename" -Encoding utf8 -WhatIf:$false
                }
                if (-not $DoNotLogToConsole)
                {
                    Write-Debug -Message "$timestampstring`t$source`t$message"
                }
            }
        }
    }
}
