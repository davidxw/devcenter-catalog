# Script for batch installing Visual Studio Code extensions
# Specify extensions to be checked & installed by modifying $extensions
param(
    [Parameter(Mandatory)]
    [string]
    $extensions
)

$cmd = "code --list-extensions"
Invoke-Expression $cmd -OutVariable output | Out-Null
$installed = $output -split "\s"
$requiredExtensions = $extensions -split ","

foreach ($ext in $requiredExtensions) {
    if ($installed.Contains($ext)) {
        Write-Host $ext "already installed." -ForegroundColor Gray
    } else {
        Write-Host "Installing" $ext "..." -ForegroundColor White
        code --install-extension $ext
    }
}