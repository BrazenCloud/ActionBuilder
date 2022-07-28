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
                'windows' {
                    Get-Content $PSScriptRoot\templates\osCommand\windows.ps1 -Raw
                }
                'Linux' {
                    Get-Content $PSScriptRoot\templates\osCommand\linux.sh -Raw
                }
            }
        }
    }
}