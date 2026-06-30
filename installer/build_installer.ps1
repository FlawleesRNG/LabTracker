[CmdletBinding()]
param(
    [string]$SupabaseUrl = "https://pfxpdnewmpihryzdqogs.supabase.co",
    [string]$SupabaseAnonKey = "sb_publishable_7jdBSaikvrTQNW9jptxFvQ_EyN5noMy",
    [string]$Flutter = "C:\src\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$releaseExe = Join-Path $projectRoot "build\windows\x64\runner\Release\labtracker.exe"
$installerScript = Join-Path $scriptDir "labtracker_installer.iss"
$setupExe = Join-Path $scriptDir "LabTracker_Alpha_v0.1.0_Setup.exe"

Set-Location $projectRoot

Write-Host "Fechando LabTracker se estiver aberto..."
Get-Process -Name "labtracker" -ErrorAction SilentlyContinue | Stop-Process -Force

if (-not (Test-Path $Flutter)) {
    throw "Flutter nao encontrado em '$Flutter'. Ajuste o parametro -Flutter ou use flutter no PATH."
}

Write-Host "Gerando build Windows release..."
& $Flutter build windows --release "--dart-define=SUPABASE_URL=$SupabaseUrl" "--dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey"

if (-not (Test-Path $releaseExe)) {
    throw "Build Windows nao encontrada em '$releaseExe'."
}

$isccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { $_ -and (Test-Path $_) }

$iscc = $isccCandidates | Select-Object -First 1

if (-not $iscc) {
    Write-Host ""
    Write-Host "Inno Setup nao encontrado. Instale o Inno Setup ou compile manualmente o arquivo installer\labtracker_installer.iss."
    Write-Host "Build Windows pronta em: $releaseExe"
    exit 1
}

Write-Host "Compilando instalador com Inno Setup..."
& $iscc $installerScript

if (-not (Test-Path $setupExe)) {
    throw "Instalador nao foi encontrado em '$setupExe'."
}

Write-Host "Instalador gerado: $setupExe"
