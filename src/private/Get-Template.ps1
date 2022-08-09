Function Get-Template {
    param (
        [string]$Name
    )
    switch ($Name.Split('-')[0]) {
        'parameters' {
            Get-Content $PSScriptRoot\templates\parameters.json
        }
        'osCommand' {
            switch ($Name.Split('-')[1]) {
                'Windows' {
                    Get-Content $PSScriptRoot\templates\osCommand\windows.ps1 -Raw
                }
                'Linux' {
                    Get-Content $PSScriptRoot\templates\osCommand\linux.sh -Raw
                }
                'WindowsIfBool' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifBool.ps1 -Raw
                }
                'WindowsIfString' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifString.ps1 -Raw
                }
                'LinuxIfBool' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifBool.sh -Raw
                }
                'LinuxIfString' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifString.sh -Raw
                }
                'LinuxJq' {
                    Get-Content $PSScriptRoot\templates\osCommand\jq.sh -Raw
                }
                'WindowsIf' {
                    Get-Content $PSScriptRoot\templates\osCommand\if.ps1
                }
                'WindowsIfCombine' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifCombine.ps1
                }
                'WindowsIfParam' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifParam.ps1
                }
                'WindowsElse' {
                    Get-Content $PSScriptRoot\templates\osCommand\else.ps1
                }
                'LinuxIfCombine' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifCombine.sh
                }
                'LinuxIfParam' {
                    Get-Content $PSScriptRoot\templates\osCommand\ifParam.sh
                }
                'LinuxElse' {
                    Get-Content $PSScriptRoot\templates\osCommand\else.sh
                }
            }
        }
    }
}