param(
    [string]$Alias = 'chanhung-upload'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot 'android'
$keystorePath = Join-Path $androidDir 'app\chanhung-erp-upload.jks'
$propertiesPath = Join-Path $androidDir 'key.properties'
$backupDir = Join-Path $env:USERPROFILE '.android'
$backupPath = Join-Path $backupDir 'chanhung-erp-upload-key.txt'
$keytool = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' } else { $null }

if (-not $keytool -or -not (Test-Path -LiteralPath $keytool)) {
    $keytoolCommand = Get-Command keytool.exe -ErrorAction SilentlyContinue
    $androidStudioKeytool = Join-Path $env:ProgramFiles 'Android\Android Studio\jbr\bin\keytool.exe'
    if ($keytoolCommand) {
        $keytool = $keytoolCommand.Source
    } elseif (Test-Path -LiteralPath $androidStudioKeytool) {
        $keytool = $androidStudioKeytool
    } else {
        throw 'keytool.exe was not found. Install a JDK or configure JAVA_HOME.'
    }
}

if (Test-Path -LiteralPath $keystorePath) {
    throw "Upload keystore already exists: $keystorePath"
}

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$password = -join ((1..32) | ForEach-Object { 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'.ToCharArray() | Get-Random })

& $keytool -genkeypair -v `
    -keystore $keystorePath `
    -storepass $password `
    -keypass $password `
    -alias $Alias `
    -keyalg RSA `
    -keysize 4096 `
    -validity 10000 `
    -dname 'CN=Chan Hung ERP, OU=Mobile, O=Chan Hung, L=Ho Chi Minh City, ST=Ho Chi Minh, C=VN'

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE"
}

@"
storePassword=$password
keyPassword=$password
keyAlias=$Alias
storeFile=chanhung-erp-upload.jks
"@ | Set-Content -LiteralPath $propertiesPath -Encoding ASCII

@"
Chan Hung ERP Android upload key
Keystore: $keystorePath
Alias: $Alias
Password: $password

Keep this file and the .jks file private. Both are required to sign future Google Play uploads.
"@ | Set-Content -LiteralPath $backupPath -Encoding UTF8

Write-Output "Created Android upload keystore: $keystorePath"
Write-Output "Saved private recovery details: $backupPath"
