class BcAction {
    [BcManifest]$Manifest
    [BcParameter[]]$Parameters
    [BcRepository]$Repository
    [hashtable]$Execution
    [string]$WindowsScript
    [string]$LinuxScript
    [string[]]$ExtraFolders

    BcAction() {
        $this.Manifest = [BcManifest]::new()
        $this.Repository = [BcRepository]::new()
    }

    [bool] Test() {
        if ($null -eq $this.Manifest) {
            Write-Warning 'No manifest.'
            return $false
        }
        if ($null -eq $this.WindowsScript -and $null -eq $this.LinuxScript) {
            Write-Warning 'Missing a script.'
            return $false
        }
        return $true
    }

    Export(
        [string]$Path
    ) {
        if ($this.Test()) {
            if (Test-Path $Path -PathType Leaf) {
                Throw 'Path must be a directory.'
            }
            if (-not (Test-Path $Path)) {
                New-Item $Path -ItemType Directory -Force
            }

            $outDir = (Get-Item $Path).FullName

            # output the manifest
            $this.Manifest.Export("$outDir\manifest.txt", $true)

            # output the parameters
            if ($this.Parameters.Count -gt 0) {
                $this.Parameters | Select-Object -ExcludeProperty "Value" | ConvertTo-Json -AsArray | Out-File $outDir\parameters.json
            }

            # output the execution files, if exists
            if ($null -ne $this.Execution) {
                $this.Execution | ConvertTo-Json | Out-File $outDir\execution.json
            }

            # output the repository.json file
            $this.Repository | ConvertTo-Json | Out-File $outDir\repository.json

            # output the windows script, if exists
            if ($null -ne $this.WindowsScript) {
                if (-not (Test-Path $outDir\windows)) {
                    New-Item $outDir\windows -ItemType Directory
                }
                $this.WindowsScript | Out-File $outDir\windows\script.ps1
            }

            # output the linux script, if exists
            if ($null -ne $this.LinuxScript) {
                if (-not (Test-Path $outDir\linux)) {
                    New-Item $outDir\linux -ItemType Directory
                }
                $this.LinuxScript | Out-File $outDir\linux\script.sh
            }

            # copy the extra files, if present
            if ($this.ExtraFolders.Count -gt 0) {
                foreach ($dir in $this.ExtraFolders) {
                    if (Test-Path $dir) {
                        Copy-Item $dir -Destination $outDir
                    } else {
                        Write-Warning "Unable to copy '$($this.ExtraFolders)', path does not exist"
                    }
                }
            }
        } else {
            Throw 'Test failed. Be sure the action meets the minimum criteria of having both a manifest and at least a Windows or Linux script.'
        }

    }
}