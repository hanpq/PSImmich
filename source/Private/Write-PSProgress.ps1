function Write-PSProgress
{
    <#
    .SYNOPSIS
        Wrapper for PSProgress
    .DESCRIPTION
        This function will automatically calculate items/sec, eta, time remaining
        as well as set the update frequency in case the there are a lot of items processing fast.
    .PARAMETER Activity
        Defines the activity name for the progressbar
    .PARAMETER Id
        Defines a unique ID for this progressbar, this is used when nesting progressbars
    .PARAMETER Target
        Defines a arbitrary text for the currently processed item
    .PARAMETER ParentId
        Defines the ID of a parent progress bar
    .PARAMETER Completed
        Explicitly tells powershell to set the progress bar as completed removing
        it from view. In some cases the progress bar will linger if this is not done.
    .PARAMETER Counter
        The currently processed items counter
    .PARAMETER Total
        The total number of items to process
    .PARAMETER StartTime
        Sets the start datetime for the progressbar, this is required to calculate items/sec, eta and time remaining
    .PARAMETER DisableDynamicUpdateFrquency
        Disables the dynamic update frequency function and every item will update the status of the progressbar
    .PARAMETER NoTimeStats
        Disables calculation of items/sec, eta and time remaining
    .EXAMPLE
        1..10000 | foreach-object -begin {$StartTime = Get-Date} -process {
            Write-PSProgress -Activity 'Looping' -Target $PSItem -Counter $PSItem -Total 10000 -StartTime $StartTime
        }
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Standard')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Completed')]
        [string]
        $Activity,

        [Parameter(Position = 1, ParameterSetName = 'Standard')]
        [Parameter(Position = 1, ParameterSetName = 'Completed')]
        [ValidateRange(0, 2147483647)]
        [int]
        $Id,

        [Parameter(Position = 2, ParameterSetName = 'Standard')]
        [string]
        $Target,

        [Parameter(Position = 3, ParameterSetName = 'Standard')]
        [Parameter(Position = 3, ParameterSetName = 'Completed')]
        [ValidateRange(-1, 2147483647)]
        [int]
        $ParentId,

        [Parameter(Position = 4, ParameterSetname = 'Completed')]
        [switch]
        $Completed,

        [Parameter(Mandatory = $true, Position = 5, ParameterSetName = 'Standard')]
        [long]
        $Counter,

        [Parameter(Mandatory = $true, Position = 6, ParameterSetName = 'Standard')]
        [long]
        $Total,

        [Parameter(Position = 7, ParameterSetName = 'Standard')]
        [datetime]
        $StartTime,

        [Parameter(Position = 8, ParameterSetName = 'Standard')]
        [switch]
        $DisableDynamicUpdateFrquency,

        [Parameter(Position = 9, ParameterSetName = 'Standard')]
        [switch]
        $NoTimeStats
    )

    # Define current timestamp
    $TimeStamp = (Get-Date)

    # Define a dynamic variable name for the global starttime variable
    $StartTimeVariableName = ('ProgressStartTime_{0}' -f $Activity.Replace(' ', ''))

    # Manage global start time variable
    if ($PSBoundParameters.ContainsKey('Completed') -and (Get-Variable -Name $StartTimeVariableName -Scope Global -ErrorAction SilentlyContinue))
    {
        # Remove the global starttime variable if the Completed switch parameter is users
        try
        {
            Remove-Variable -Name $StartTimeVariableName -ErrorAction Stop -Scope Global
        }
        catch
        {
            throw $_
        }
    }
    elseif (-not (Get-Variable -Name $StartTimeVariableName -Scope Global -ErrorAction SilentlyContinue))
    {
        # Global variable do not exist, create global variable
        if ($null -eq $StartTime)
        {
            # No start time defined with parameter, use current timestamp as starttime
            Set-Variable -Name $StartTimeVariableName -Value $TimeStamp -Scope Global
            $StartTime = $TimeStamp
        }
        else
        {
            # Start time defined with parameter, use that value as starttime
            Set-Variable -Name $StartTimeVariableName -Value $StartTime -Scope Global
        }
    }
    else
    {
        # Global start time variable is defined, collect and use it
        $StartTime = Get-Variable -Name $StartTimeVariableName -Scope Global -ErrorAction Stop -ValueOnly
    }

    # Define frequency threshold
    $Frequency = [Math]::Ceiling($Total / 100)
    switch ($PSCmdlet.ParameterSetName)
    {
        'Standard'
        {
            # Only update progress is any of the following is true
            # - DynamicUpdateFrequency is disabled
            # - Counter matches a mod of defined frequecy
            # - Counter is 0
            # - Counter is equal to Total (completed)
            if (($DisableDynamicUpdateFrquency) -or ($Counter % $Frequency -eq 0) -or ($Counter -eq 1) -or ($Counter -eq $Total))
            {

                # Calculations for both timestats and without
                $Percent = [Math]::Round(($Counter / $Total * 100), 0)

                # Define count progress string status
                $CountProgress = ('{0}/{1}' -f $Counter, $Total)

                # If percent would turn out to be more than 100 due to incorrect total assignment revert back to 100% to avoid that write-progress throws
                if ($Percent -gt 100)
                {
                    $Percent = 100
                }

                # Define write-progress splat hash
                $WriteProgressSplat = @{
                    Activity         = $Activity
                    PercentComplete  = $Percent
                    CurrentOperation = $Target
                }

                # Add ID if specified
                if ($Id)
                {
                    $WriteProgressSplat.Id = $Id
                }

                # Add ParentID if specified
                if ($ParentId)
                {
                    $WriteProgressSplat.ParentId = $ParentId
                }

                # Calculations for either timestats and without
                if ($NoTimeStats)
                {
                    $WriteProgressSplat.Status = ('{0} - {1}%' -f $CountProgress, $Percent)
                }
                else
                {
                    # Total seconds elapsed since start
                    $TotalSeconds = ($TimeStamp - $StartTime).TotalSeconds

                    # Calculate items per sec processed (IpS)
                    $ItemsPerSecond = ([Math]::Round(($Counter / $TotalSeconds), 2))

                    # Calculate seconds spent per processed item (for ETA)
                    $SecondsPerItem = if ($Counter -eq 0)
                    {
                        0
                    }
                    else
                    {
 ($TotalSeconds / $Counter)
                    }

                    # Calculate seconds remainging
                    $SecondsRemaing = ($Total - $Counter) * $SecondsPerItem
                    $WriteProgressSplat.SecondsRemaining = $SecondsRemaing

                    # Calculate ETA
                    $ETA = $(($Timestamp).AddSeconds($SecondsRemaing).ToShortTimeString())

                    # Add findings to write-progress splat hash
                    $WriteProgressSplat.Status = ('{0} - {1}% - ETA: {2} - IpS {3}' -f $CountProgress, $Percent, $ETA, $ItemsPerSecond)
                }

                # Call writeprogress
                Write-Progress @WriteProgressSplat
            }
        }
        'Completed'
        {
            Write-Progress -Activity $Activity -Id $Id -Completed
        }
    }
}
