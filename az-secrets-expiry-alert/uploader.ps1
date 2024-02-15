$ResourceGroup = 'az-secrets-expiry-alert'
$StorageAccount = 'azsecretsexpiryaler18'
$logic_app_name = 'azure-app-notification18'

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Set path of workflow files
$localDir = (Get-Location).Path
$AdditionalDirectory = "artifact"
$CombinedPath = Join-Path -Path $localDir -ChildPath $AdditionalDirectory
Write-Host "Combined path: $CombinedPath"

# Get folders/workflows to upload
$directoryPath = "/site/wwwroot/"
$folders = Get-ChildItem -Path $CombinedPath -Directory -Recurse | Where-Object { $_.Name.StartsWith("secret-expiry-alert-workflow") }
if ($null -eq $folders) {
    Write-Host "No workflows found" -ForegroundColor Yellow
    return
}

# Get the storage account context
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context

# Get the file share
$fs = (Get-AZStorageShare -Context $ctx).Name

# Get current IP
$ip = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

try {
    # Open firewall
    Add-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroup -Name $StorageAccount -IPAddressOrRange $ip | Out-Null

    # Upload folders to file share
    foreach($folder in $folders)
    {
        Write-Host "Uploading workflow " -NoNewLine
        Write-Host $folder.Name -ForegroundColor Yellow -NoNewLine
        Write-Host "..." -NoNewLine
        $path = $directoryPath + $folder.Name

        Get-AzStorageShare -Context $ctx -Name $fs | New-AzStorageDirectory -Path $path -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Seconds 1

        # Upload files to file share
        $files = Get-ChildItem -Path $folder -Recurse -File
        foreach($file in $files)
        {
            $filePath = $path + "/" + $file.Name
            $fSrc = $file.FullName
            try {
                # Upload file
                Set-AzStorageFileContent -Context $ctx -ShareName $fs -Source $fSrc -Path $filePath -Force -ea Stop | Out-Null
            } catch {
                # Happens if file is locked, wait and try again
                Start-Sleep -Seconds 5
                Set-AzStorageFileContent -Context $ctx -ShareName $fs -Source $fSrc -Path $filePath -Force -ea Stop | Out-Null
            }
        }
        
        Write-Host 'Done' -ForegroundColor Green
    }
} finally {
    # Remove the firewall rule
    Remove-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroup -Name $StorageAccount -IPAddressOrRange $ip | Out-Null
}

$connectionfile = Get-ChildItem -Path $CombinedPath -File -Recurse | Where-Object { $_.Name.StartsWith("connections.json") }
if ($null -eq $connectionfile) {
    Write-Host "No connections.json found" -ForegroundColor Yellow
    return
}

#Uploading logic app connection file to storage account
Write-Host "Uploading connections.json" -NoNewLine
$SourceFilePath = $CombinedPath + "/" + $connectionfile.name
$DestinationFilePath = $directoryPath + $connectionfile.name
Set-AzStorageFileContent -ShareName $fs -Source $SourceFilePath -Path $DestinationFilePath -Context $ctx -Force -ea stop | Out-Null

# Update network rules to deny public access
Write-Host "Disable public access for storage" -NoNewLine
Set-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount -PublicNetworkAccess Disabled