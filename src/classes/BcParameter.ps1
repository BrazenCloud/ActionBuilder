class BcParameter {
    [string]$Name
    [ValidateRange(0, 3)]
    [int]$Type
    [string]$DefaultValue
    [string]$Description
    [bool]$IsOptional

    BcParameter() {
        $this.IsOptional = $true
    }

    [string]ToString(
        [bool]$Compress
    ) {
        return ($this | ConvertTo-Json -Compress:$Compress)
    }
}