@echo off

@rem Based on the installer found here: https://github.com/Sygil-Dev/sygil-webui
@rem This script will install git and all dependencies
@rem using micromamba (an 8mb static-linked single-file binary, conda replacement).
@rem This enables a user to install this project without manually installing conda and git.

echo WARNING: This script relies on Micromamba which may have issues on some systems when installed under a path with spaces.
echo          May also have issues with long paths.&& echo.

pause
cls
set "PACKAGES_TO_INSTALL=python=3.10.9 git"
set "CHANNEL=-c conda-forge -c pytorch"
cd /D "%~dp0"
set PATH=%PATH%;%SystemRoot%\system32

set MAMBA_ROOT_PREFIX=%cd%\installer_files\mamba
set INSTALL_ENV_DIR=%cd%\installer_files\env
set MICROMAMBA_DOWNLOAD_URL=https://github.com/mamba-org/micromamba-releases/releases/download/1.4.9-0/micromamba-win-64
set REPO_URL=https://github.com/chubays/DomRU_Telefone_Monthly_Report.git
set umamba_exists=F

@rem figure out whether git and conda needs to be installed
call "%MAMBA_ROOT_PREFIX%\micromamba.exe" --version >nul 2>&1
if "%ERRORLEVEL%" EQU "0" set umamba_exists=T

@rem (if necessary) install git and conda into a contained environment
if "%PACKAGES_TO_INSTALL%" NEQ "" (
    @rem download micromamba
    if "%umamba_exists%" == "F" (
        echo "Downloading Micromamba from %MICROMAMBA_DOWNLOAD_URL% to %MAMBA_ROOT_PREFIX%\micromamba.exe"

        mkdir "%MAMBA_ROOT_PREFIX%"
        call curl -Lk "%MICROMAMBA_DOWNLOAD_URL%" > "%MAMBA_ROOT_PREFIX%\micromamba.exe" || ( echo. && echo Micromamba failed to download. && goto end )

        @rem test the mamba binary
        echo Micromamba version:
        call "%MAMBA_ROOT_PREFIX%\micromamba.exe" --version || ( echo. && echo Micromamba not found. && goto end )
    )

    @rem create micromamba hook
    if not exist "%MAMBA_ROOT_PREFIX%\condabin\micromamba.bat" (
      call "%MAMBA_ROOT_PREFIX%\micromamba.exe" shell hook >nul 2>&1
    )

    @rem create the installer env
    if not exist "%INSTALL_ENV_DIR%" (
      echo Packages to install: %PACKAGES_TO_INSTALL%
      call "%MAMBA_ROOT_PREFIX%\micromamba.exe" create -y --prefix "%INSTALL_ENV_DIR%" %CHANNEL% %PACKAGES_TO_INSTALL% || ( echo. && echo Conda environment creation failed. && goto end )
    )
)

@rem check if conda environment was actually created
if not exist "%INSTALL_ENV_DIR%\python.exe" ( echo. && echo Conda environment is empty. && goto end )

@rem activate installer env
call "%MAMBA_ROOT_PREFIX%\condabin\micromamba.bat" activate "%INSTALL_ENV_DIR%" || ( echo. && echo MicroMamba hook not found. && goto end )

@rem clone the repository and install the pip requirements
if exist DomRU_Telefone_Monthly_Report\ (
  cd DomRU_Telefone_Monthly_Report
  git pull
) else (
  git clone %REPO_URL%
  cd DomRU_Telefone_Monthly_Report || goto end
)
call python -m pip install -r requirements.txt --upgrade

:end
pause