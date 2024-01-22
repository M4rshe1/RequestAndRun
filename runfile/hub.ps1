$currentYear = (Get-Date).Year
clear-host
Write-Host @"
  _____  _    _ _   _   ______ _ _
 |  __ \| |  | | \ | | |  ____(_) |
 | |__) | |  | |  \| | | |__   _| | ___ 
 |  _  /| |  | | . ' | |  __| | | |/ _ \
 | | \ \| |__| | |\  | | |    | | |  __/
 |_|  \_\\____/|_| \_| |_|    |_|_|\___| 


****************************************************************
* Copyright of Colin Heggli $currentYear                               *
* https://colin.heggli.dev                                     *
* https://github.com/M4rshe1                                   *
****************************************************************

"@

$runfiles = Invoke-RestMethod "127.0.0.1:8000/files/$($TOKEN)"

Write-Host "Available runfiles:"
Write-Host "-".PadRight(26, "-")
$index = 1
foreach ($name in $runfiles.names)
{
    if ($runfiles.agents.$name.Contains("powershell")) {
        Write-Host "$($name.PadRight(20) ) - [$index]"
    }
    $index++
}
Write-Host "-".PadRight(26, "-")
Write-Host "$('Quit'.PadRight(20) ) - [q]"
Write-Host ""
Write-Host "Select a runfile to run"
$selection = Read-Host ">> "
if ($selection -eq "" -or $selection -eq "q")
{
    exit
}
$selection = [int]$selection - 1
Write-Host $selection
if ($selection -lt 0 -or $selection -gt $runfiles.names.Length)
{
    Write-Host "Invalid selection"
    Read-Host "Press any key to exit..."
    exit
}
$fileName = $runfiles.names[$selection]
clear-host
Write-Host "Running $fileName"
$url = "$($runfiles.base_url)/$($fileName)/$($TOKEN)"
Invoke-WebRequest $url | Invoke-Expression
