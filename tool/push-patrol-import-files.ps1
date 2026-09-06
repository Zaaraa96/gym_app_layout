# Copy import fixtures onto the connected Android device for flow 2c.
#
# From the repo root in PowerShell:
#   dart run tool/push_patrol_import_files.dart
#   .\tool\push-patrol-import-files.ps1
#
# Do not run push-patrol-import-files.sh from PowerShell — Windows treats .sh
# as a document and asks which app should open it.
$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root

function Find-Dart {
    $cmd = Get-Command dart -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutter) {
        $sdk = Join-Path (Split-Path (Split-Path $flutter.Source)) 'cache\dart-sdk\bin\dart.exe'
        if (Test-Path $sdk) { return $sdk }
    }
    return $null
}

$dart = Find-Dart
if (-not $dart) {
    Write-Error @"
dart was not found on PATH.

From PowerShell in the repo root, after Flutter is on PATH:

  dart run tool/push_patrol_import_files.dart

Do not run tool/push-patrol-import-files.sh in PowerShell — Windows will ask
which app should open it.
"@
}

& $dart run tool/push_patrol_import_files.dart @args
exit $LASTEXITCODE
