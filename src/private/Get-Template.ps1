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
                'WindowsIf' {
                    Get-Content $PSScriptRoot\templates\osCommand\if.ps1 -Raw
                }
                'LinuxIf' {
                    Get-Content $PSScriptRoot\templates\osCommand\if.sh -Raw
                }
                'LinuxJq' {
                    Get-Content $PSScriptRoot\templates\osCommand\jq.sh -Raw
                }
            }
        }
    }
}