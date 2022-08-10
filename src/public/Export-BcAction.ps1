Function Export-BcAction {
    [cmdletbinding()]
    param (
        [string]$ConfigPath,
        [string]$OutPath,
        [switch]$ClearOutputFolders
    )
    [hashtable[]]$json = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
    foreach ($actionHt in $json) {
        $h = Get-Help New-BcAbAction
        $splat = @{}
        foreach ($parameter in $h.parameters.parameter.Name) {
            $splat[$parameter] = $null -ne $actionHt.$parameter ? $actionHt.$parameter : $null
        }
        $action = New-BcAbAction @splat
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