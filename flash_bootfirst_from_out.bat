@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="" (
  echo Usage:
  echo   %~nx0 ^<OUT_PRODUCT_DIR^> [FASTBOOT_EXE]
  echo Example:
  echo   %~nx0 C:\android\out\target\product\ruan
  exit /B 1
)

set "OUT_DIR=%~1"
set "FASTBOOT_EXE=%~2"

if "%FASTBOOT_EXE%"=="" (
  set "FASTBOOT_EXE=C:\Users\Admin\Downloads\ruan_in_global_images_OS2.0.207.0.VFSINXM_20260131.0000.00_15.0_in_4227b50145\ruan_in_global_images_OS2.0.207.0.VFSINXM_15.0\fastboot.exe"
)

if not exist "%FASTBOOT_EXE%" (
  echo [ERROR] fastboot not found: %FASTBOOT_EXE%
  exit /B 1
)

if not exist "%OUT_DIR%\boot.img" (
  echo [ERROR] Missing %OUT_DIR%\boot.img
  exit /B 1
)
if not exist "%OUT_DIR%\vendor_boot.img" (
  echo [ERROR] Missing %OUT_DIR%\vendor_boot.img
  exit /B 1
)
if not exist "%OUT_DIR%\dtbo.img" (
  echo [ERROR] Missing %OUT_DIR%\dtbo.img
  exit /B 1
)
if not exist "%OUT_DIR%\vbmeta.img" (
  echo [ERROR] Missing %OUT_DIR%\vbmeta.img
  exit /B 1
)

echo [INFO] Checking connected device product...
"%FASTBOOT_EXE%" getvar product 2>&1 | findstr /r /c:"^product: *ruan" >nul
if errorlevel 1 (
  echo [ERROR] Connected fastboot device is not ruan ^(or no device found^).
  exit /B 1
)

set "HAS_RECOVERY=0"
for /f "tokens=2 delims=: " %%A in ('"%FASTBOOT_EXE%" getvar partition-size:recovery 2^>^&1 ^| findstr /r /c:"partition-size:recovery"') do (
  set "REC_SIZE_HEX=%%A"
)
if /I not "!REC_SIZE_HEX!"=="0x0" if not "!REC_SIZE_HEX!"=="" set "HAS_RECOVERY=1"

echo [INFO] Flashing dtbo...
"%FASTBOOT_EXE%" flash dtbo_a "%OUT_DIR%\dtbo.img" || exit /B 1
"%FASTBOOT_EXE%" flash dtbo_b "%OUT_DIR%\dtbo.img" || exit /B 1

echo [INFO] Flashing vendor_boot...
"%FASTBOOT_EXE%" flash vendor_boot_a "%OUT_DIR%\vendor_boot.img" || exit /B 1
"%FASTBOOT_EXE%" flash vendor_boot_b "%OUT_DIR%\vendor_boot.img" || exit /B 1

echo [INFO] Flashing boot...
"%FASTBOOT_EXE%" flash boot_a "%OUT_DIR%\boot.img" || exit /B 1
"%FASTBOOT_EXE%" flash boot_b "%OUT_DIR%\boot.img" || exit /B 1

echo [INFO] Flashing vbmeta with verity/verification disabled...
"%FASTBOOT_EXE%" --disable-verity --disable-verification flash vbmeta_a "%OUT_DIR%\vbmeta.img" || exit /B 1
"%FASTBOOT_EXE%" --disable-verity --disable-verification flash vbmeta_b "%OUT_DIR%\vbmeta.img" || exit /B 1

if "%HAS_RECOVERY%"=="1" (
  if exist "%OUT_DIR%\recovery.img" (
    echo [INFO] Recovery partition detected ^(!REC_SIZE_HEX!^). Flashing recovery...
    "%FASTBOOT_EXE%" flash recovery_a "%OUT_DIR%\recovery.img" || exit /B 1
    "%FASTBOOT_EXE%" flash recovery_b "%OUT_DIR%\recovery.img" || exit /B 1
  ) else (
    echo [WARN] Recovery partition exists but %OUT_DIR%\recovery.img is missing. Skipping recovery flash.
  )
) else (
  echo [INFO] Recovery partition not present ^(or probe unavailable^). Skipping recovery flash.
)

echo [INFO] Setting active slot to a and rebooting...
"%FASTBOOT_EXE%" set_active a || exit /B 1
"%FASTBOOT_EXE%" reboot || exit /B 1

echo [DONE] Boot-first flash sequence completed.
exit /B 0
