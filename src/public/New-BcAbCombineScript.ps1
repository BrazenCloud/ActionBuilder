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

    $templates = Get-Template -All

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

    $customParam = if ($Parameters.Name -contains 'Custom Parameters') {
        $param = $Parameters | Where-Object { $_.Name -eq 'Custom Parameters' }
        $condition = if ($param.Type -eq 2) {
            $param.GetIsTrueStatement($OperatingSystem)
        } elseif ($param.Type -eq 0) {
            $param.GetIsEmptyStatement($OperatingSystem)
        }
        $mcSplat.Parameters = $param.GetValue($OperatingSystem)
        $templates[$OperatingSystem]['if']['combineCustomParam'].Replace('{condition}', $condition).Replace('{command}', (makeCommand @mcSplat))
    } else {
        $null
    }

    $statements = foreach ($param in $Parameters | Where-Object { $_.Name -ne 'Custom Parameters' }) {
        if ($param.Type -eq 2) {
            $param.GetIsTrueStatement($OperatingSystem)
        } elseif ($param.Type -eq 0) {
            $param.GetIsEmptyStatement($OperatingSystem)
        }
    }
    $mainIf = $templates[$OperatingSystem]['if']['combine'] -replace '\{exists\}', ($statements -join $orStatement[$OperatingSystem])

    $ifArr = foreach ($param in $Parameters | Where-Object { $_.Name -ne 'Custom Parameters' }) {
        if ($param.Type -eq 2) {
            $templates[$OperatingSystem]['if']['if'].Replace('{condition}', $Param.GetIsTrueStatement($OperatingSystem)) -replace '{command}', ($OperatingSystem -eq 'Linux' ? "arr+=(""$($param.GetValue($OperatingSystem))"")" : "`"$($param.GetValue($OperatingSystem))`"")
        } elseif ($param.Type -eq 0) {
            $templates[$OperatingSystem]['if']['string'].Replace('{param}', $Param.Name) -replace '{command}', ($OperatingSystem -eq 'Linux' ? "arr+=(""$($param.GetValue($OperatingSystem))"")" : "`"$($param.GetValue($OperatingSystem))`"")
        }
    }

    $mcSplat.Parameters = $OperatingSystem -eq 'Windows' ? '$arr' : '${arr[*]}'
    $out = (($mainIf -replace '\{if\}', ($ifArr -join "`n"))) `
        -replace '\{command\}', (makeCommand @mcSplat) `
        -replace '\{customParam\}', $customParam
    
    $mcSplat['Parameters'] = $DefaultParameters
    $out -replace '\{else\}', (($templates[$OperatingSystem]['if']['else'] -replace '\{command\}', (makeCommand @mcSplat)) -join "`n")
}