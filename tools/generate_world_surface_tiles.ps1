param(
	[string]$Source = "assets/123/场景/Rasaks_Fantasy_Tileset/Fantasy/Tileset/Nature/A2_Nature_Rasak.png",
	[string]$Destination = "assets/environment/runtime"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Write-PaddedTile {
	param(
		[System.Drawing.Bitmap]$Atlas,
		[int]$SourceX,
		[int]$SourceY,
		[string]$Name
	)

	$tileSize = 48
	$padding = 4
	$outputSize = $tileSize + $padding * 2
	$output = New-Object System.Drawing.Bitmap $outputSize, $outputSize
	for ($y = 0; $y -lt $outputSize; $y++) {
		for ($x = 0; $x -lt $outputSize; $x++) {
			$sourceTileX = [Math]::Min([Math]::Max($x - $padding, 0), $tileSize - 1)
			$sourceTileY = [Math]::Min([Math]::Max($y - $padding, 0), $tileSize - 1)
			$output.SetPixel($x, $y, $Atlas.GetPixel($SourceX + $sourceTileX, $SourceY + $sourceTileY))
		}
	}
	$output.Save((Join-Path $Destination $Name), [System.Drawing.Imaging.ImageFormat]::Png)
	$output.Dispose()
}

$sourcePath = Join-Path $PSScriptRoot "..\\$Source"
$destinationPath = Join-Path $PSScriptRoot "..\\$Destination"
New-Item -ItemType Directory -Force -Path $destinationPath | Out-Null
$atlas = [System.Drawing.Bitmap]::FromFile((Resolve-Path $sourcePath))
try {
	Write-PaddedTile $atlas 0 0 "grass_tile.png"
	Write-PaddedTile $atlas 0 288 "farmland_tile.png"
	Write-PaddedTile $atlas 0 336 "road_dirt_tile.png"
	Write-PaddedTile $atlas 0 432 "water_tile.png"
} finally {
	$atlas.Dispose()
}
