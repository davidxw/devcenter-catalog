# Script for batch installing Visual Studio Code extensions
# Specify extensions to be checked & installed by modifying $extensions
param(
    [Parameter(Mandatory)]
    [string]
    $extensions
)

$profilePath = [System.Environment]::GetFolderPath("UserProfile")

$vsCodeCli = "$profilePath\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd"

if(-not (Test-Path $vsCodeCli))
{
    throw "Could not find VS Code to install extensions. Exiting ..."
    exit 1
}

Invoke-Expression "& '$vsCodeCli' --list-extensions" -OutVariable output | Out-Null
$installed = $output -split "\s"
$requiredExtensions = $extensions -split ","

foreach ($ext in $requiredExtensions) {
    if ($installed.Contains($ext)) {
        Write-Host $ext "already installed." -ForegroundColor Gray
    } else {
        Write-Host "Installing" $ext "..." -ForegroundColor White
        $cmd = "$vsCodeCli --install-extension $ext"
        Invoke-Expression $cmd
    }
}