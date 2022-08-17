Function New-BcAbCombineScript {
    [cmdletbinding()]
    param (
        [BcParameter[]]$Parameters,
        [ValidateSet('Windows', 'Linux')]
        [string]$OperatingSystem,
        [string]$Command,
        [switch]$RedirectCommandOutput,
        [string]$DefaultParameters
    )

    $orStatement = @{
        Windows = ' -or '
        Linux   = ' || '
    }

    $mcSplat = @{
        Command    = $Command
        OS         = $OperatingSystem
        Redirect   = $RedirectCommandOutput.IsPresent
        Parameters = $DefaultParameters
    }

    # if the 'Custom Parameters' is present, make sure that is first in the script
    $customParam = if ($Parameters.Name -contains 'Custom Parameters') {
        $param = $Parameters | Where-Object { $_.Name -eq 'Custom Parameters' }
        $condition = if ($param.Type -eq 2) {
            $param.GetIsTrueStatement($OperatingSystem)
        } elseif ($param.Type -eq 0) {
            $param.GetIsEmptyStatement($OperatingSystem)
        }
        $mcSplat.Parameters = $param.GetValue($OperatingSystem)
        $templates[$OperatingSystem]['if']['combineCustomParam'] `
            -replace '{condition}', $condition `
            -replace '{command}', (makeCommand @mcSplat)
    } else {
        $null
    }

    # build the array of conditions. If any of them are true, then the ifs will run
    $statements = foreach ($param in $Parameters | Where-Object { $_.Name -ne 'Custom Parameters' }) {
        if ($param.Type -eq 2) {
            $param.GetIsTrueStatement($OperatingSystem)
        } elseif ($param.Type -eq 0) {
            $param.GetIsEmptyStatement($OperatingSystem)
        }
    }
    # Main if with the above conditions
    $mainIf = $templates[$OperatingSystem]['if']['combine'] `
        -replace '\{exists\}', ($statements -join $orStatement[$OperatingSystem])

    # build the internal if array
    $ifArr = foreach ($param in $Parameters | Where-Object { $_.Name -ne 'Custom Parameters' }) {
        if ($param.Type -eq 2) {
            $templates[$OperatingSystem]['if']['if'] `
                -replace '{condition}', $Param.GetIsTrueStatement($OperatingSystem) `
                -replace '{command}', ($OperatingSystem -eq 'Linux' ? "arr+=(""$($param.GetValue($OperatingSystem))"")" : "`"$($param.GetValue($OperatingSystem))`"")
        } elseif ($param.Type -eq 0) {
            $templates[$OperatingSystem]['if']['if'] `
                -replace '{condition}', $Param.GetIsEmptyStatement($OperatingSystem) `
                -replace '{command}', ($OperatingSystem -eq 'Linux' ? "arr+=(""$($param.GetValue($OperatingSystem))"")" : "`"$($param.GetValue($OperatingSystem))`"")
        }
    }

    # fix the spacing so that it looks nice
    $ifArr = foreach ($str in $ifArr) {
        $space = $OperatingSystem -eq 'Windows' ? '        ' : '    '
        $str -split '\n' -join "`n$space"
    }

    # Build the combine logic
    $mcSplat.Parameters = $OperatingSystem -eq 'Windows' ? '$arr' : '${arr[*]}'
    $out = ( ( $mainIf -replace '\{if\}', ($ifArr -join "`n$space") ) ) `
        -replace '\{command\}', (makeCommand @mcSplat) `
        -replace '\{customParam\}', $customParam
    # Add the else
    $mcSplat['Parameters'] = $DefaultParameters
    $out -replace '\{else\}', (
        ($templates[$OperatingSystem]['if']['else'] `
            -replace '\{command\}', (makeCommand @mcSplat)) -join "`n"
    )
}