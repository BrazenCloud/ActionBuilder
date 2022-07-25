Function Export-BcAction {
    [cmdletbinding()]
    param (
        [string]$ConfigPath,
        [string]$OutPath
    )
    $json = Get-Content $ConfigPath | ConvertFrom-Json
    switch ($json.ActionType) {
        'OSCommand' {
            
        }
        default {
            Write-Warning "Unsupported ActionType"
        }
    }
}