class BcParameter {
    [string]$Name
    [ValidateRange(0, 3)]
    [int]$Type
    [string]$DefaultValue
    [string]$Description
    [bool]$IsOptional
    [string]$Value

    BcParameter() {
        $this.IsOptional = $true
    }

    [string]ToString(
        [bool]$Compress
    ) {
        return ($this | ConvertTo-Json -Compress:$Compress)
    }
    [string] GetWindowsIsEmptyStatement() {
        return "`$settings.'$($this.Name)'.ToString().Length -gt 0"
    }
    [string] GetLinuxIsEmptyStatement() {
        return "[ ! -z ""`$$($this.GetBashParameterName())"" ]"
    }
    [string] GetIsEmptyStatement(
        [string]$OperatingSystem
    ) {
        if ($OperatingSystem -eq 'Windows') {
            return $this.GetWindowsIsEmptyStatement()
        } elseif ($OperatingSystem -eq 'Linux') {
            return $this.GetLinuxIsEmptyStatement()
        } else {
            Throw "Unsupported OS value: '$OperatingSystem'"
        }
    }
    [string] GetWindowsIsTrueStatement() {
        return "`$settings.'$($this.Name)'.ToString() -eq 'true'"
    }
    [string] GetLinuxIsTrueStatement() {
        return "[ `${$($this.GetBashParameterName())} == ""true"" ]"
    }
    [string] GetIsTrueStatement (
        [string]$OperatingSystem
    ) {
        if ($OperatingSystem -eq 'Windows') {
            return $this.GetWindowsIsTrueStatement()
        } elseif ($OperatingSystem -eq 'Linux') {
            return $this.GetLinuxIsTrueStatement()
        } else {
            Throw "Unsupported OS value: '$OperatingSystem'"
        }
    }
    [string] GetLinuxValue() {
        if ($this.Type -eq 0) {
            if ($this.Value.Length -gt 0) {
                return $this.Value -replace "\{value\}", "`$$($this.GetBashParameterName())"
            } else {
                return "`$$($this.GetBashParameterName())"
            }
        } else {
            return $this.Value
        }
    }
    [string] GetWindowsValue() {
        if ($this.Type -eq 0) {
            if ($this.Value.Length -gt 0) {
                return $this.Value -replace "\{value\}", "`$(`$settings.'$($this.Name)')"
            } else {
                return "`$(`$settings.'$($this.Name)')"
            }
        } else {
            return $this.Value
        }
    }
    [string] GetValue(
        [string]$OperatingSystem
    ) {
        if ($OperatingSystem -eq 'Windows') {
            return $this.GetWindowsValue()
        } elseif ($OperatingSystem -eq 'Linux') {
            return $this.GetLinuxValue()
        } else {
            Throw "Unsupported OS value: '$OperatingSystem'"
        }
    }
    [string] GetBashParameterName() {
        return $this.Name -replace '[^a-zA-Z0-9_]', ''
    }
}