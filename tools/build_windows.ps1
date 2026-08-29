# Build script for Ashes of the Brave (Windows Desktop)
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Godot = ''

function Invoke-GodotExport {
  param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [Parameter(Mandatory=$true)][string]$OutPath
  )

  $stdout = Join-Path $env:TEMP ("godot_export_{0}.out.log" -f [Guid]::NewGuid().ToString('N'))
  $stderr = Join-Path $env:TEMP ("godot_export_{0}.err.log" -f [Guid]::NewGuid().ToString('N'))

  # Godot's Windows binary is a GUI-subsystem executable. The call operator can
  # return before the process exits, so use Start-Process -Wait to synchronize.
  $arguments = @(
    '--headless',
    '--path', "`"$ProjectRoot`"",
    '--export-release',
    '"Windows Desktop"',
    "`"$OutPath`""
  )
  $process = Start-Process -FilePath $Godot -ArgumentList $arguments `
    -Wait -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr

  $exitCode = $process.ExitCode
  if ($exitCode -ne 0 -or -not (Test-Path -LiteralPath $OutPath)) {
    Write-Output "Godot stdout: $stdout"
    Write-Output "Godot stderr: $stderr"
    if (Test-Path -LiteralPath $stdout) { Get-Content -LiteralPath $stdout -Tail 40 }
    if (Test-Path -LiteralPath $stderr) { Get-Content -LiteralPath $stderr -Tail 40 }
  }
  return $exitCode
}

# 1) 发现 Godot
foreach ($candidate in @('D:\Godot\godot.exe', 'D:\Godot\Godot_v4.7.2-stable_win64.exe')) {
  if (Test-Path -LiteralPath $candidate) { $Godot = $candidate; break }
}
if ($Godot -eq '') {
  $cmd = Get-Command godot -ErrorAction SilentlyContinue
  if ($cmd) { $Godot = $cmd.Source }
}
if ($Godot -eq '') { Write-Error 'Godot not found'; exit 1 }

# 2) 检查 Export Templates
$version = (& $Godot --version 2>&1 | Out-String).Trim()
$tpl = Join-Path $env:APPDATA 'Godot\export_templates'
if (-not (Test-Path -LiteralPath $tpl)) { Write-Error "Export templates missing: $tpl"; exit 1 }
$installed = Get-ChildItem -LiteralPath $tpl -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
if ($installed -notcontains '4.7.2.stable') { Write-Error 'Godot 4.7.2 export templates not installed'; exit 1 }

# 3) 导出前清理并关闭运行中的实例
Get-Process -Name TheBrave -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
$out = Join-Path $ProjectRoot 'builds\windows\TheBrave.exe'
foreach ($f in @($out, "$out.tmp")) { try { if (Test-Path -LiteralPath $f) { [System.IO.File]::Delete($f) } } catch {} }

$exportOk = $false
$exportExit = -1
for ($attempt = 1; $attempt -le 2; $attempt++) {
  $exportExit = Invoke-GodotExport -Godot $Godot -ProjectRoot $ProjectRoot -OutPath $out
  $exists = $false
  for ($i = 0; $i -lt 40; $i++) {
    if ((Test-Path -LiteralPath $out) -and (Get-Item -LiteralPath $out).Length -gt 0) {
      $exists = $true
      break
    }
    Start-Sleep -Milliseconds 500
  }
  if ($exportExit -eq 0 -and $exists) { $exportOk = $true; break }
  Start-Sleep -Seconds 1
}
if (-not $exportOk) { Write-Error "EXE not produced (last Godot exit code: $exportExit)"; exit 1 }

# 4) Manifest
$manifest = [ordered]@{
  game_name = 'Ashes of the Brave'
  version = '0.3.0'
  platform = 'windows'
  architecture = 'x86_64'
  build_time = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  git_commit = (& git -C $ProjectRoot rev-parse --short HEAD 2>$null)
  godot_version = $version
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $ProjectRoot 'builds\windows\build_manifest.json') -Encoding UTF8
$zip = Join-Path $ProjectRoot 'builds\releases\TheBrave_0.3.0_PlayablePrototype_Windows.zip'
Compress-Archive -LiteralPath @($out, (Join-Path $ProjectRoot 'builds\windows\build_manifest.json')) -DestinationPath $zip -Force
Write-Output 'BUILD SUCCESS'
exit 0
