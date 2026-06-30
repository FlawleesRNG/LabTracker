# Instalador Windows do LabTracker

Esta pasta prepara o instalador Windows do LabTracker usando Inno Setup.

O instalador inclui todos os arquivos da build Flutter em:

```powershell
build\windows\x64\runner\Release
```

Nao envie apenas `labtracker.exe`. O app tambem precisa das DLLs, da pasta `data` e dos arquivos dos plugins.

## Requisitos

1. Instale o Inno Setup 6.
2. Tenha o Flutter configurado para Windows.
3. Gere a build release antes de compilar o instalador.

## Gerar build Windows com Supabase

Na raiz do projeto:

```powershell
cd C:\Users\Flawlees\Documents\labtracker

$env:SUPABASE_URL="https://pfxpdnewmpihryzdqogs.supabase.co"
$env:SUPABASE_ANON_KEY="sb_publishable_7jdBSaikvrTQNW9jptxFvQ_EyN5noMy"

flutter build windows --release --dart-define="SUPABASE_URL=$env:SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY"
```

## Compilar pelo Inno Setup

1. Abra o Inno Setup.
2. Abra o arquivo `installer\labtracker_installer.iss`.
3. Clique em `Compile`.
4. O instalador sera gerado em:

```powershell
installer\LabTracker_Alpha_v0.1.0_Setup.exe
```

## Script automatico

Voce tambem pode usar:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\build_installer.ps1
```

O script:

1. vai para a raiz do projeto;
2. fecha `labtracker.exe`, se estiver aberto;
3. roda `flutter build windows --release` com Supabase;
4. verifica se `labtracker.exe` foi gerado;
5. tenta encontrar o `ISCC.exe`;
6. compila o instalador se o Inno Setup estiver instalado.

Se o Inno Setup nao estiver instalado, o script mostra uma mensagem e voce pode compilar manualmente o `.iss`.

## O que o instalador faz

- permite escolher onde instalar;
- instala todos os arquivos da pasta `Release`;
- cria atalho no Menu Iniciar;
- permite criar atalho na Area de Trabalho;
- permite iniciar o LabTracker com o Windows, opcional e desligado por padrao;
- cria desinstalador automaticamente;
- remove atalhos e a entrada de iniciar com Windows ao desinstalar.

## Dados locais

O desinstalador nao remove dados locais do usuario em AppData, Documents, SharedPreferences, SQLite, Hive ou outros locais de dados. Nesta alpha, ele remove apenas os arquivos instalados pelo instalador.
