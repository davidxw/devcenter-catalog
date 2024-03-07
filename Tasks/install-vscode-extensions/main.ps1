# Script for batch installing Visual Studio Code extensions
# Specify extensions to be checked & installed by modifying $extensions
param(
    [Parameter(Mandatory)]
    [string]
    $extensions
)

$profilePath = [System.Environment]::GetFolderPath("UserProfile")
$vsCodeExe = "$profilePath\AppData\Local\Programs\'Microsoft VS Code'\code.exe"


Invoke-Expression "$vsCodeExe --list-extensions" -OutVariable output | Out-Null
$installed = $output -split "\s"
$requiredExtensions = $extensions -split ","

foreach ($ext in $requiredExtensions) {
    if ($installed.Contains($ext)) {
        Write-Host $ext "already installed." -ForegroundColor Gray
    } else {
        Write-Host "Installing" $ext "..." -ForegroundColor White
        $cmd = "$vsCodeExe --install-extension $ext"
        Invoke-Expression $cmd
    }
}