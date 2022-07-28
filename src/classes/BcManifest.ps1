class BcManifest {
    [string]$Header
    [string]$WindowsCommand
    [string]$LinuxCommand

    BcManifest() {
        $this.Header = 'COPY . .'
        $this.WindowsCommand = '"PowerShell.exe -ExecutionPolicy Bypass -File .\windows\script.ps1"'
        $this.LinuxCommand = 'linux/script.sh'
    }

    Export(
        [string]$Path,
        [bool]$Force
    ) {
        $str = "$($this.Header)`n$($this.WindowsCommand)`n$($this.WindowsCommand)"
        if ((Test-Path $path) -and -not $Force) {
            Throw 'File already exists. Use $Force to overwrite.'
        } else {
            $str | Out-File $Path -Force:$Force
        }
    }
}