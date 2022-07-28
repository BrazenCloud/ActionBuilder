Function Export-BcAction {
    [cmdletbinding()]
    param (
        [string]$ConfigPath,
        [string]$OutPath,
        [switch]$ClearOutputFolders
    )
    [hashtable[]]$json = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
    foreach ($actionHt in $json) {
        $action = switch ($json.ActionType) {
            'OSCommand' {
                $splat = @{
                    Name                       = $null -ne $actionHt.Name ? $actionHt.Name : $null
                    Description                = $null -ne $actionHt.Description ? $actionHt.Description : $null
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
        if ($ClearOutputFolders.IsPresent) {
            if (Test-Path "$OutPath\$($actionHt.Name)") {
                Get-ChildItem "$OutPath\$($actionHt.Name)" -Recurse -File | ForEach-Object {
                    Remove-Item $_ -Force
                }
                Get-ChildItem "$OutPath\$($actionHt.Name)" -Recurse -Directory | ForEach-Object {
                    Remove-Item $_ -Force
                }
            }
        }
        $action.Export("$OutPath\$($actionHt.Name)")
    }
}