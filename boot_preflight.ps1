param(
    [string]$DeviceRoot = ".",
    [string]$FastbootPath = ""
)

$ErrorActionPreference = "Stop"

function Read-HexPrefix {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Count
    )

    $bytes = Get-Content -Path $Path -Encoding Byte -TotalCount $Count
    return ($bytes | ForEach-Object { $_.ToString("X2") }) -join " "
}

function Assert-Exists {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required file: $Path"
    }
}

$root = (Resolve-Path -LiteralPath $DeviceRoot).Path
$kernelPath = Join-Path $root "prebuilt\\kernel"
$dtbPath = Join-Path $root "dtb\\dtb.img"
$dtboPath = Join-Path $root "dtb\\dtbo.img"

Assert-Exists -Path $kernelPath
Assert-Exists -Path $dtbPath
Assert-Exists -Path $dtboPath

$kernel8 = Read-HexPrefix -Path $kernelPath -Count 8
$kernel4 = (($kernel8 -split " ")[0..3]) -join " "
$dtb4 = Read-HexPrefix -Path $dtbPath -Count 4
$dtbo4 = Read-HexPrefix -Path $dtboPath -Count 4

Write-Host "Kernel prefix (8 bytes): $kernel8"
Write-Host "DTB prefix (4 bytes): $dtb4"
Write-Host "DTBO prefix (4 bytes): $dtbo4"

if ($kernel8 -eq "41 4E 44 52 4F 49 44 21") {
    throw "Invalid kernel artifact: boot image header (ANDROID!) detected in prebuilt\\kernel"
}

if ($kernel4 -ne "4D 5A 00 91") {
    throw "Invalid kernel artifact: expected raw kernel prefix 4D 5A 00 91, got $kernel4"
}

Write-Host "Kernel preflight passed (raw kernel signature is valid)."

$fastbootCmd = $null
$fastboot = Get-Command fastboot -ErrorAction SilentlyContinue
if ($fastboot) {
    $fastbootCmd = $fastboot.Source
} elseif ($FastbootPath -and (Test-Path -LiteralPath $FastbootPath)) {
    $fastbootCmd = (Resolve-Path -LiteralPath $FastbootPath).Path
}

if (-not $fastbootCmd) {
    Write-Host "fastboot not found in PATH; keeping default separate-recovery config."
    Write-Host "Probe later with: fastboot getvar partition-size:recovery"
    if ($FastbootPath) {
        Write-Host "Tip: pass -FastbootPath with full path to fastboot.exe"
    }
    exit 0
}

$probeOutput = & $fastbootCmd getvar partition-size:recovery 2>&1
$probeText = ($probeOutput | Out-String).Trim()
Write-Host ""
Write-Host "fastboot probe output:"
Write-Host $probeText
Write-Host ""

if ($probeText -match "partition-size:recovery:\s*0x0\b") {
    Write-Host "Result: recovery partition absent."
    Write-Host "Action: set BOARD_USES_RECOVERY_AS_BOOT := true and remove recovery from AB_OTA_PARTITIONS."
} elseif ($probeText -match "partition-size:recovery:\s*0x[0-9a-fA-F]+") {
    Write-Host "Result: recovery partition exists."
    Write-Host "Action: keep separate recovery configuration (current default)."
} else {
    Write-Host "Result: unable to determine recovery partition from probe output."
    Write-Host "Action: keep current default until a clear fastboot value is available."
}
