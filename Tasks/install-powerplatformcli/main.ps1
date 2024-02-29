# download from https://aka.ms/PowerAppsCLI

$FilePath="$env:temp\PowerAppsCLI.msi"

Invoke-WebRequest -Uri "https://aka.ms/PowerAppsCLI" -Outfile $FilePath

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

Write-Host "[${env:username}] Start to install $FilePath ..."

$process = Start-Process -FilePath 'msiexec' -ArgumentList `
    "/i $($FilePath)", `
    "/qn", `
    "/norestart" `
    -NoNewWindow -Wait -PassThru

Write-Host "[${env:username}] End to install $FilePath ..."
    
return $process.ExitCode
