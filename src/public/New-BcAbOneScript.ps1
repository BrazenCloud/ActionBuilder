Function New-BcAbOneScript {
    [cmdletbinding()]
    param (
        [BcParameter[]]$Parameters,
        [ValidateSet('Windows', 'Linux')]
        [string]$OperatingSystem,
        [string]$Command,
        [switch]$RedirectCommandOutput,
        [string]$DefaultParameters
    )

    $mcSplat = @{
        Command    = $Command
        OS         = $OperatingSystem
        Redirect   = $RedirectCommandOutput.IsPresent
        Parameters = $DefaultParameters
    }

    if ($Parameters.Name -contains 'Custom Parameters') {
        $firstParam = $Parameters | Where-Object { $_.Name -eq 'Custom Parameters' }
        $startingIndex = 0
    } else {
        $firstParam = $firstParam
        $startingIndex = 1
    }

    # Build the first if
    $out = if ($firstParam.Type -eq 2) {
        $mcSplat.Parameters = $firstParam.GetValue($OperatingSystem)
        $templates[$OperatingSystem]['if']['ifElse'] `
            -replace '\{condition\}', $firstParam.GetIsTrueStatement($OperatingSystem) `
            -replace '\{command\}', (makeCommand @mcSplat)
    } elseif ($firstParam.Type -eq 0) {
        $mcSplat.Parameters = $firstParam.GetValue($OperatingSystem)
        $templates[$OperatingSystem]['if']['ifElse'] `
            -replace '\{condition\}', $firstParam.GetIsEmptyStatement($OperatingSystem) `
            -replace '\{command\}', (makeCommand @mcSplat)
    }

    # Build the remaining ifs as the elseifelse
    for ($x = $startingIndex; $x -lt $Parameters.Count; $x++) {
        if ($Parameters[$x].Name -ne 'Custom Parameters') {
            # if this param has a default value, use it, else it must have come from the passed actionParameters var
            $ifStr = if ($Parameters[$x].Type -eq 2) {
                $mcSplat.Parameters = $Parameters[$x].GetValue($OperatingSystem)
                $templates[$OperatingSystem]['if']['elseIfElse'] `
                    -replace '\{condition\}', $Parameters[$x].GetIsTrueStatement($OperatingSystem) `
                    -replace '\{command\}', (makeCommand @mcSplat)
            } elseif ($Parameters[$x].Type -eq 0) {
                $mcSplat.Parameters = $Parameters[$x].GetValue($OperatingSystem)
                $templates[$OperatingSystem]['if']['elseIfElse'] `
                    -replace '\{condition\}', $Parameters[$x].GetIsEmptyStatement($OperatingSystem) `
                    -replace '\{command\}', (makeCommand @mcSplat)
            }
            $out = $out -replace '\{else\}', $ifStr
        }
    }
    # Build the final else statement
    if ($DefaultParameters.Length -gt 0) {
        $mcSplat.Parameters = $DefaultParameters
        $out = $out `
            -replace '\{else\}', $templates[$OperatingSystem]['if']['else'] `
            -replace '\{command\}', (makeCommand @mcSplat)
    } else {
        $mcSplat.Parameters = $null
        $out = $out `
            -replace '\{else\}', $templates[$OperatingSystem]['if']['else'] `
            -replace '\{command\}', (makeCommand @mcSplat)
    }
    $out
}