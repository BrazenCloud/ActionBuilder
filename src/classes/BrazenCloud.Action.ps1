Class BcAction {
    [string]$Manifest
    [hashtable]$Parameters
    [hashtable]$Execution
    [string]$WindowsScript
    [string]$LinuxScript

    BcAction() {}

    [bool] Test() {
        if ($null -eq $this.Manifest) {
            return $false
        }
        if ($null -eq $this.WindowsScript -and $null -eq $this.LinuxScript) {
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
            $this.Manifest | Out-File $outDir\manifest.txt

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
                $this.LinuxScript | Out-File $outDir\windows\script.sh
            }

            # output the parameter and execution files, if exists
            foreach ($file in @('Parameters', 'Execution')) {
                if ($null -ne $this.$File) {
                    $this.$File | ConvertTo-Json | Out-File $outDir\$file.json
                }
            }
        } else {
            Throw 'Test failed. Be sure the action meets the minimum criteria of having both a manifest and at least a Windows or Linux script.'
        }

    }
}