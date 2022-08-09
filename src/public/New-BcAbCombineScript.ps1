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

    $templates = @{
        'Windows' = @{
            IfCombine = Get-Template -Name osCommand-WindowsIfCombine
            IfParam   = Get-Template -Name osCommand-WindowsIfParam
            Else      = Get-Template -Name osCommand-WindowsElse
        }
        'Linux'   = @{
            IfCombine = Get-Template -Name osCommand-LinuxIfCombine
            IfParam   = Get-Template -Name osCommand-LinuxIfParam
            Else      = Get-Template -Name osCommand-LinuxElse
        }
    }

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

    $mainIf = $templates[$OperatingSystem]['IfCombine'] -replace '"?\{exists\}"?', ($Parameters.GetIsEmptyStatement($OperatingSystem) -join $orStatement[$OperatingSystem])

    $ifArr = foreach ($param in $Parameters | Where-Object { $_.Name -ne 'Parameters' }) {
        ($templates[$OperatingSystem]['IfParam'] -replace '\{param\}', $Param.Name) -replace '"?\{value\}"?', "`"$($param.GetValue($OperatingSystem))`""
    }

    $mcSplat.Parameters = $DefaultParameters

    (($mainIf -replace '"?\{if\}"?', ($ifArr -join "`n"))) `
        -replace '"?\{command\}"?', $Command `
        -replace '"?\{else\}"?', (($templates[$OperatingSystem]['Else'] -replace '"?\{action\}"?', (makeCommand @mcSplat)) -join "`n")
}