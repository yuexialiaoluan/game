# Headless regression runner for Ashes of the Brave.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_all_tests.ps1
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Godot = ''
foreach ($candidate in @('D:\Godot\godot.exe', 'D:\Godot\Godot_v4.7.2-stable_win64.exe')) {
  if (Test-Path -LiteralPath $candidate) { $Godot = $candidate; break }
}
if ($Godot -eq '') {
  $cmd = Get-Command godot -ErrorAction SilentlyContinue
  if ($cmd) { $Godot = $cmd.Source }
}
if ($Godot -eq '') { Write-Error 'Godot not found'; exit 1 }

$excluded = @('game_start_placeholder.tscn')
$scenes = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'scenes\tests') -Filter *.tscn |
  Where-Object { $excluded -notcontains $_.Name } |
  Sort-Object Name

$totalFail = 0
$totalStderr = 0
$rows = New-Object System.Collections.Generic.List[object]

foreach ($sceneFile in $scenes) {
  $scene = 'res://scenes/tests/' + $sceneFile.Name
  $stdout = Join-Path $env:TEMP ('godot_test_{0}.out.log' -f [Guid]::NewGuid().ToString('N'))
  $stderr = Join-Path $env:TEMP ('godot_test_{0}.err.log' -f [Guid]::NewGuid().ToString('N'))
  $arguments = @(
    '--headless',
    '--path', "`"$ProjectRoot`"",
    '--quit-after', '900',
    "`"$scene`"",
    '--',
    '--validate'
  )
  $process = Start-Process -FilePath $Godot -ArgumentList $arguments `
    -Wait -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr

  $text = ''
  if (Test-Path -LiteralPath $stdout) { $text = Get-Content -LiteralPath $stdout -Raw }
  $errBytes = 0
  if (Test-Path -LiteralPath $stderr) { $errBytes = (Get-Item -LiteralPath $stderr).Length }

  $failures = -1
  $match = [regex]::Match($text, 'VALIDATION_DONE failures=(\d+)')
  if ($match.Success) { $failures = [int]$match.Groups[1].Value }
  if ($failures -lt 0) { $failures = 999 }

  $totalFail += $failures
  $totalStderr += $errBytes
  $rows.Add([pscustomobject]@{
    Scene = $sceneFile.BaseName
    Exit = $process.ExitCode
    Failures = $failures
    StderrBytes = $errBytes
  })

  Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue
}

$rows | Format-Table -AutoSize
Write-Output ("TOTAL_FAILS={0}" -f $totalFail)
Write-Output ("TOTAL_STDERR={0}" -f $totalStderr)
exit 0
