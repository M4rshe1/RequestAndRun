$currentYear = (Get-Date).Year
clear-host
$banner = @"
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

Available runfiles:
--------------------------------------------------
"@

$runfiles = Invoke-RestMethod "$($BASE_URL)/files/$($TOKEN)"


Function Create-Menu (){

    Param(
        [Parameter(Mandatory=$True)][String]$MenuTitle,
        [Parameter(Mandatory=$True)][array]$MenuOptions
    )

    $MaxValue = $MenuOptions.count-1
    $Selection = 0
    $EnterPressed = $False

    Clear-Host

    While($EnterPressed -eq $False){

        Write-Host "$MenuTitle"

        For ($i=0; $i -le $MaxValue; $i++){

            If ($i -eq $Selection){
                Write-Host -BackgroundColor DarkGray -ForegroundColor White "[ $($MenuOptions[$i]) ]" -NoNewline
                Write-Host $runfiles.agents.$($MenuOptions[$i]).admin -NoNewline
                if ($runfiles.files.$($MenuOptions[$i]).admin -eq $true)
                {
                    Write-Host " A " -NoNewline -ForegroundColor DarkRed
                }
                Write-Host " - $($runfiles.files.$($MenuOptions[$i]).description) by $($runfiles.files.$($MenuOptions[$i]).author)"
            } Else {
                Write-Host "  $($MenuOptions[$i])  "
            }

        }

        $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch($KeyInput){
            13{
                $EnterPressed = $True
                Return $Selection
                Clear-Host
                break
            }

            38{
                If ($Selection -eq 0){
                    $Selection = $MaxValue
                } Else {
                    $Selection -= 1
                }
                Clear-Host
                break
            }

            40{
                If ($Selection -eq $MaxValue){
                    $Selection = 0
                } Else {
                    $Selection +=1
                }
                Clear-Host
                break
            }
            Default{
                Clear-Host
            }
        }
    }
}

$index = 1
$options = @()
$runfiles.names | ForEach-Object {
    if ($runfiles.agents.$_.Contains("powershell")) {
        $options += $_
    }
    $index++
}

$selection = Create-Menu -MenuTitle $banner -MenuOptions $options

clear-host
Write-Host "Running $fileName"
$url = "$($runfiles.base_url)/$($options[$selection])/powershell/$($TOKEN)"
$url | out-string

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and $runfiles.files.$($options[$selection]).admin -eq $true) {
    Start-Process -Verb runas powershell -ArgumentList "Invoke-RestMethod -Uri $url | Invoke-Expression" -Wait
}
else
{
    Invoke-RestMethod $url | Invoke-Expression
}

