function makeCommand {
    [OutputType('String')]
    param (
        [string]$Command,
        [validateSet('Windows', 'Linux')]
        [string]$OS,
        [switch]$Redirect,
        [string]$Parameters
    )
    if ($Parameters.Length -gt 0) {
        $Command = "$Command $Parameters"
    }
    switch ($OS) {
        'Windows' {
            if ($Redirect.IsPresent) {
                $Command = "$Command | Out-File .\results\out.txt"
            }
        }
        'Linux' {
            if ($Redirect.IsPresent) {
                $Command = "$Command >> ./results/out.txt"
            }
        }
    }
    $Command
}