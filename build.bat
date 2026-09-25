@echo off
:: Screen Translate Windows Compilation Script
:: Designed for harmonious usage in CMD/PowerShell environments

title Screen Translate Builder
color 0B
cls

:menu
echo ===================================================
echo             SCREEN TRANSLATE BUILDER
echo ===================================================
echo.
echo  [1] Generate Flutter Localization (gen-l10n)
echo  [2] Run Flutter Clean and Pub Get
echo  [3] Build APK (Release)
echo  [4] Build AppBundle (Release)
echo  [5] Full Release Build (L10n + APK + AAB)
echo  [6] Bump Version + Full Release (APK + AAB)
echo  [7] Publish to Google Play (test, build, upload, tag)
echo.
echo ===================================================
set /p opt="Please choose an option [1-7]: "

if "%opt%"=="1" goto gen_l10n
if "%opt%"=="2" goto flutter_clean
if "%opt%"=="3" goto build_apk
if "%opt%"=="4" goto build_bundle
if "%opt%"=="5" goto full_build
if "%opt%"=="6" goto bump_and_release
if "%opt%"=="7" goto publish
echo.
color 0C
echo Invalid option selected, please try again.
color 0B
pause
exit /b

:gen_l10n
echo.
echo ---------------------------------------------------
echo Generating Flutter Localizations...
echo ---------------------------------------------------
call flutter gen-l10n
echo.
pause
exit /b

:flutter_clean
echo.
echo ---------------------------------------------------
echo Running Flutter Clean and Pub Get...
echo ---------------------------------------------------
call flutter clean
call flutter pub get
echo.
pause
exit /b

:build_apk
echo.
echo ---------------------------------------------------
echo Building Release APK...
echo ---------------------------------------------------
python tools\build.py apk
if errorlevel 1 goto build_failed
echo.
pause
exit /b

:build_bundle
echo.
echo ---------------------------------------------------
echo Building Release AppBundle...
echo ---------------------------------------------------
python tools\build.py aab
if errorlevel 1 goto build_failed
echo.
pause
exit /b

:full_build
echo.
echo ---------------------------------------------------
echo Running Full Release Build...
echo ---------------------------------------------------
echo Step 1: Generating Flutter Localizations...
call flutter gen-l10n
echo Step 2: Building APK (Release)...
python tools\build.py apk
if errorlevel 1 goto build_failed
echo Step 3: Building AppBundle (Release)...
python tools\build.py aab
if errorlevel 1 goto build_failed
echo.
echo Full Build Completed Successfully!
echo.
pause
exit /b

:bump_and_release
echo.
echo ===================================================
echo             VERSION BUMP MENU
echo ===================================================
echo  [1] Bump Build Number ONLY (+1)
echo  [2] Bump Patch Version (1.0.x -^> 1.0.x+1)
echo  [3] Bump Minor Version (1.x.0)
echo  [4] Bump Major Version (x.0.0)
echo  [5] Cancel
echo.
set /p bump_opt="Choose bump type [1-5]: "

set BUMP_ARG=
if "%bump_opt%"=="1" set BUMP_ARG=build
if "%bump_opt%"=="2" set BUMP_ARG=patch
if "%bump_opt%"=="3" set BUMP_ARG=minor
if "%bump_opt%"=="4" set BUMP_ARG=major
if "%bump_opt%"=="5" exit /b

if "%BUMP_ARG%"=="" (
    echo Invalid option.
    goto bump_and_release
)

echo.
echo ---------------------------------------------------
echo Running Full Release Build with Version Bump...
echo ---------------------------------------------------
echo Step 1: Bumping version (%BUMP_ARG%)...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    python scripts\bump_version.py %BUMP_ARG%
) else (
    python3 --version >nul 2>&1
    if %errorlevel% equ 0 (
        python3 scripts\bump_version.py %BUMP_ARG%
    ) else (
        echo [ERROR] Python is not installed or not in PATH!
        pause
        goto menu
    )
)

echo Step 2: Generating Flutter Localizations...
call flutter gen-l10n

echo Step 3: Building APK (Release)...
python tools\build.py apk
if errorlevel 1 goto build_failed

echo Step 4: Building AppBundle (Release)...
python tools\build.py aab
if errorlevel 1 goto build_failed
echo.
echo Version Bump and Release Build Completed Successfully!
echo.
pause
exit /b

:publish
echo.
echo ---------------------------------------------------
echo Publish to Google Play (tools\release.py)
echo Needs PLAY_SERVICE_ACCOUNT_JSON; see tools\release.py --help
echo ---------------------------------------------------
set track=
set /p track="Track [internal/alpha/beta/production] (default internal): "
if "%track%"=="" set track=internal
set bump=
set /p bump="Bump version first? [build/patch/minor/major] (blank = no): "
set BUMP_FLAG=
if not "%bump%"=="" set BUMP_FLAG=--bump %bump%
python tools\release.py --track %track% %BUMP_FLAG%
echo.
pause
exit /b

:build_failed
echo.
echo [ERROR] Build failed - see the messages above.
echo.
pause
exit /b 1

:exit
echo.
echo Exiting Screen Translate Builder. Have a great day!
exit /b
