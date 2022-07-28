Function Export-BcAction {
    [cmdletbinding()]
    param (
        [string]$ConfigPath,
        [string]$OutPath
    )
    $json = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
    switch ($json.ActionType) {
        'OSCommand' {
            $splat = @{
                Name                       = $null -ne $json.Name ? $json.Name : $null
                Command                    = $null -ne $json.Command ? $json.Command : $null
                ActionParameters           = $null -ne $json.ActionParameters ? $json.ActionParameters : $null
                DefaultParameters          = $null -ne $json.DefaultParameters ? $json.DefaultParameters : $null
                IncludeParametersParameter = $null -ne $json.IncludeParametersParameter ? $json.IncludeParametersParameter : $null
                RedirectCommandOutput      = $null -ne $json.RedirectCommandOutput ? $json.RedirectCommandOutput : $null
                Windows                    = $json.OperatingSystems -contains 'Windows'
                Linux                      = $json.OperatingSystems -contains 'Linux'
                OutPath                    = $OutPath
            }
            New-BcOsCommandAction @splat
        }
        default {
            Write-Warning "Unsupported ActionType"
        }
    }
}