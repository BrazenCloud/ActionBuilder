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
                Windows                    = $null -ne $json.Windows ? $json.Windows : $null
                Linux                      = $null -ne $json.Linux ? $json.Linux : $null
                OutPath                    = "C:\tmp\action-$($action.Name)"
            }
            New-BcOsCommandAction @splat
        }
        default {
            Write-Warning "Unsupported ActionType"
        }
    }
}