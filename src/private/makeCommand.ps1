function makeCommand {
    [OutputType('String')]
    param (
        [string]$Command,
        [validateSet('Windows', 'Linux')]
        [string]$OS,
        [switch]$Redirect,
        [string]$Parameters,
        [BcParameter[]]$RequiredParameters
    )
    if ($Parameters.Length -gt 0) {
        $Command = "$Command $Parameters"
    }

    if ($RequiredParameters.Count -gt 0) {
        $reqStr = ($RequiredParameters | ForEach-Object { $_.GetValue($OS) }) -join " "
        $Command = "$Command $reqStr"
    }

    switch ($OS) {
        'Windows' {
            if ($Redirect.IsPresent) {
                $Command = "$Command | Out-File ..\results\out.txt -Append"
            }
        }
        'Linux' {
            if ($Redirect.IsPresent) {
                $Command = "$Command >> ../results/out.txt"
            }
        }
    }
    $Command
}