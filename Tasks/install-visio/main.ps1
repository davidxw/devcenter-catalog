# install visio

$FilePath="$env:temp\odt.exe"
$ExtractPath="$env:temp\odtExtract"

mkdir $ExtractPath

Invoke-WebRequest -Uri "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17126-20132.exe" -Outfile $FilePath

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

Write-Host "[${env:username}] Start to install $FilePath ..."

$process = Start-Process -FilePath $FilePath -ArgumentList `
    "/extractPath $($ExtractPath)", `
    "/passive", `
    "/norestart" `
    -NoNewWindow -Wait -PassThru

Write-Host "[${env:username}] End to install $FilePath ..."

#### create configuration file and run office install 
Write-Host "[${env:username}] ODT extract to $ExtractPath, PLACEHOLDER FOR VISIO INSTALL"
    
return $process.ExitCode