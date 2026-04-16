param(
    [Parameter(Mandatory = $true)]
    [string]$RomImagesPath,
    [string]$DeviceRoot = ".",
    [switch]$SyncFromRom
)

$ErrorActionPreference = "Stop"

function Align-Up {
    param([int64]$Value, [int64]$Align)
    return [int64]([math]::Ceiling($Value / [double]$Align) * $Align)
}

function Hex-Bytes {
    param([byte[]]$Bytes, [int]$Count = 8)
    return (($Bytes[0..($Count - 1)] | ForEach-Object { $_.ToString("X2") }) -join " ")
}

function Sha256-Bytes {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
    } finally {
        $sha.Dispose()
    }
}

function Parse-BootImage {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 8)
    if ($magic -ne "ANDROID!") {
        throw "Invalid boot header magic in ${Path}: $magic"
    }

    $kernelSize = [BitConverter]::ToUInt32($bytes, 8)
    $ramdiskSize = [BitConverter]::ToUInt32($bytes, 12)
    $headerSize = [BitConverter]::ToUInt32($bytes, 20)
    $headerVersion = [BitConverter]::ToUInt32($bytes, 40)
    $signatureSize = [BitConverter]::ToUInt32($bytes, 1580)
    $pageSize = 4096
    $kernelOffset = Align-Up $headerSize $pageSize

    if ($kernelOffset + $kernelSize -gt $bytes.Length) {
        throw "Kernel payload out of bounds in $Path"
    }

    $kernelBytes = New-Object byte[] $kernelSize
    [Array]::Copy($bytes, $kernelOffset, $kernelBytes, 0, $kernelSize)

    [pscustomobject]@{
        Path          = $Path
        HeaderVersion = $headerVersion
        HeaderSize    = $headerSize
        KernelSize    = $kernelSize
        RamdiskSize   = $ramdiskSize
        SignatureSize = $signatureSize
        KernelBytes   = $kernelBytes
        KernelPrefix  = Hex-Bytes -Bytes $kernelBytes -Count 8
        KernelSha256  = Sha256-Bytes -Bytes $kernelBytes
    }
}

function Parse-VendorBootImage {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 8)
    if ($magic -ne "VNDRBOOT") {
        throw "Invalid vendor_boot header magic in ${Path}: $magic"
    }

    $headerVersion = [BitConverter]::ToUInt32($bytes, 8)
    $pageSize = [BitConverter]::ToUInt32($bytes, 12)
    $vendorRamdiskSize = [BitConverter]::ToUInt32($bytes, 24)
    $headerSize = [BitConverter]::ToUInt32($bytes, 2096)
    $dtbSize = [BitConverter]::ToUInt32($bytes, 2100)

    $dtbOffset = Align-Up $headerSize $pageSize
    $dtbOffset += Align-Up $vendorRamdiskSize $pageSize

    if ($dtbOffset + $dtbSize -gt $bytes.Length) {
        throw "DTB payload out of bounds in $Path"
    }

    $dtbBytes = New-Object byte[] $dtbSize
    [Array]::Copy($bytes, $dtbOffset, $dtbBytes, 0, $dtbSize)

    [pscustomobject]@{
        Path              = $Path
        HeaderVersion     = $headerVersion
        HeaderSize        = $headerSize
        PageSize          = $pageSize
        VendorRamdiskSize = $vendorRamdiskSize
        DtbSize           = $dtbSize
        DtbOffset         = $dtbOffset
        DtbBytes          = $dtbBytes
        DtbPrefix         = Hex-Bytes -Bytes $dtbBytes -Count 8
        DtbSha256         = Sha256-Bytes -Bytes $dtbBytes
    }
}

function Parse-RawprogramSize {
    param([string]$RawprogramPath, [string]$Label)
    [xml]$xml = Get-Content -LiteralPath $RawprogramPath
    $node = $xml.data.program | Where-Object { $_.label -eq $Label } | Select-Object -First 1
    if (-not $node) {
        throw "Label '$Label' not found in $RawprogramPath"
    }
    $sectors = [int64]$node.num_partition_sectors
    return $sectors * 4096
}

function Parse-BoardConfigValue {
    param([string]$BoardConfigPath, [string]$Name)
    $line = Select-String -Path $BoardConfigPath -Pattern "^\s*$Name\s*:=\s*([0-9]+)\s*$" | Select-Object -First 1
    if (-not $line) {
        throw "Missing numeric $Name in $BoardConfigPath"
    }
    return [int64]$line.Matches[0].Groups[1].Value
}

function Ensure-Exists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required path: $Path"
    }
}

$romImages = (Resolve-Path -LiteralPath $RomImagesPath).Path
$deviceRoot = (Resolve-Path -LiteralPath $DeviceRoot).Path

$bootImg = Join-Path $romImages "boot.img"
$vendorBootImg = Join-Path $romImages "vendor_boot.img"
$recoveryImg = Join-Path $romImages "recovery.img"
$dtboImg = Join-Path $romImages "dtbo.img"
$rawprogram0 = Join-Path $romImages "rawprogram0.xml"
$rawprogram4 = Join-Path $romImages "rawprogram4.xml"

$currentKernel = Join-Path $deviceRoot "prebuilt\\kernel"
$currentDtb = Join-Path $deviceRoot "dtb\\dtb.img"
$currentDtbo = Join-Path $deviceRoot "dtb\\dtbo.img"
$boardConfig = Join-Path $deviceRoot "BoardConfig.mk"

@($bootImg, $vendorBootImg, $recoveryImg, $dtboImg, $rawprogram0, $rawprogram4, $currentKernel, $currentDtb, $currentDtbo, $boardConfig) | ForEach-Object {
    Ensure-Exists -Path $_
}

$boot = Parse-BootImage -Path $bootImg
$recovery = Parse-BootImage -Path $recoveryImg
$vendorBoot = Parse-VendorBootImage -Path $vendorBootImg
$stockDtboBytes = [System.IO.File]::ReadAllBytes($dtboImg)
$stockDtboSha256 = Sha256-Bytes -Bytes $stockDtboBytes

$curKernelBytes = [System.IO.File]::ReadAllBytes($currentKernel)
$curDtbBytes = [System.IO.File]::ReadAllBytes($currentDtb)
$curDtboBytes = [System.IO.File]::ReadAllBytes($currentDtbo)

$curKernelSha256 = Sha256-Bytes -Bytes $curKernelBytes
$curDtbSha256 = Sha256-Bytes -Bytes $curDtbBytes
$curDtboSha256 = Sha256-Bytes -Bytes $curDtboBytes

Write-Host "Stock boot kernel   : $($boot.KernelSha256)  [$($boot.KernelPrefix)]"
Write-Host "Current prebuilt    : $curKernelSha256  [$(Hex-Bytes -Bytes $curKernelBytes -Count 8)]"
Write-Host "Stock vendor_boot dtb: $($vendorBoot.DtbSha256)  [$($vendorBoot.DtbPrefix)]"
Write-Host "Current dtb.img      : $curDtbSha256  [$(Hex-Bytes -Bytes $curDtbBytes -Count 8)]"
Write-Host "Stock dtbo.img       : $stockDtboSha256  [$(Hex-Bytes -Bytes $stockDtboBytes -Count 8)]"
Write-Host "Current dtbo.img     : $curDtboSha256  [$(Hex-Bytes -Bytes $curDtboBytes -Count 8)]"
Write-Host "Recovery kernel_size : $($recovery.KernelSize) (expected 0 for BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true)"
Write-Host ""

$kernelMatches = ($boot.KernelSha256 -eq $curKernelSha256)
$dtbMatches = ($vendorBoot.DtbSha256 -eq $curDtbSha256)
$dtboMatches = ($stockDtboSha256 -eq $curDtboSha256)

Write-Host "Kernel match: $kernelMatches"
Write-Host "DTB match   : $dtbMatches"
Write-Host "DTBO match  : $dtboMatches"

if ($SyncFromRom) {
    [System.IO.File]::WriteAllBytes($currentKernel, $boot.KernelBytes)
    [System.IO.File]::WriteAllBytes($currentDtb, $vendorBoot.DtbBytes)
    [System.IO.File]::WriteAllBytes($currentDtbo, $stockDtboBytes)
    Write-Host ""
    Write-Host "Synced prebuilt kernel/dtb/dtbo from stock ROM images."
}

$expectedBoot = Parse-RawprogramSize -RawprogramPath $rawprogram4 -Label "boot_a"
$expectedRecovery = Parse-RawprogramSize -RawprogramPath $rawprogram4 -Label "recovery_a"
$expectedVendorBoot = Parse-RawprogramSize -RawprogramPath $rawprogram4 -Label "vendor_boot_a"
$expectedDtbo = Parse-RawprogramSize -RawprogramPath $rawprogram4 -Label "dtbo_a"
$expectedSuper = Parse-RawprogramSize -RawprogramPath $rawprogram0 -Label "super"

$cfgBoot = Parse-BoardConfigValue -BoardConfigPath $boardConfig -Name "BOARD_BOOTIMAGE_PARTITION_SIZE"
$cfgRecovery = Parse-BoardConfigValue -BoardConfigPath $boardConfig -Name "BOARD_RECOVERYIMAGE_PARTITION_SIZE"
$cfgVendorBoot = Parse-BoardConfigValue -BoardConfigPath $boardConfig -Name "BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE"
$cfgDtbo = Parse-BoardConfigValue -BoardConfigPath $boardConfig -Name "BOARD_DTBOIMG_PARTITION_SIZE"
$cfgSuper = Parse-BoardConfigValue -BoardConfigPath $boardConfig -Name "BOARD_SUPER_PARTITION_SIZE"

Write-Host ""
Write-Host "Partition size checks (BoardConfig vs stock rawprogram):"
Write-Host "boot        : $cfgBoot vs $expectedBoot"
Write-Host "recovery    : $cfgRecovery vs $expectedRecovery"
Write-Host "vendor_boot : $cfgVendorBoot vs $expectedVendorBoot"
Write-Host "dtbo        : $cfgDtbo vs $expectedDtbo"
Write-Host "super       : $cfgSuper vs $expectedSuper"

$allSizeMatch = ($cfgBoot -eq $expectedBoot) -and ($cfgRecovery -eq $expectedRecovery) -and ($cfgVendorBoot -eq $expectedVendorBoot) -and ($cfgDtbo -eq $expectedDtbo) -and ($cfgSuper -eq $expectedSuper)
if (-not $allSizeMatch) {
    throw "Partition size mismatch detected; fix BoardConfig values before boot testing."
}

Write-Host ""
Write-Host "Stock alignment check PASSED."
