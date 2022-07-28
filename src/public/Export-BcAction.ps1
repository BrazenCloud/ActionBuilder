Function Export-BcAction {
    [cmdletbinding()]
    param (
        [string]$ConfigPath,
        [string]$OutPath
    )
    [hashtable[]]$json = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
    foreach ($actionHt in $json) {
        $action = switch ($json.ActionType) {
            'OSCommand' {
                $splat = @{
                    Name                       = $null -ne $actionHt.Name ? $actionHt.Name : $null
                    Command                    = $null -ne $actionHt.Command ? $actionHt.Command : $null
                    ActionParameters           = $null -ne $actionHt.ActionParameters ? $actionHt.ActionParameters : $null
                    DefaultParameters          = $null -ne $actionHt.DefaultParameters ? $actionHt.DefaultParameters : $null
                    IncludeParametersParameter = $null -ne $actionHt.IncludeParametersParameter ? $actionHt.IncludeParametersParameter : $null
                    RedirectCommandOutput      = $null -ne $actionHt.RedirectCommandOutput ? $actionHt.RedirectCommandOutput : $null
                    Windows                    = $actionHt.OperatingSystems -contains 'Windows'
                    Linux                      = $actionHt.OperatingSystems -contains 'Linux'
                    OutPath                    = $OutPath
                }
                New-BcOsCommandAction @splat
            }
            default {
                Write-Warning "Unsupported ActionType"
            }
        }
        $action.Export("$OutPath\$($actionHt.Name)")
    }
}