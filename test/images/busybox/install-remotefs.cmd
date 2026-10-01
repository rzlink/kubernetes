@rem Copyright 2026 The Kubernetes Authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.

@echo off

@rem RemoteFS is already available in the older Nano Server variants. Installing
@rem it only on LTSC 2025 avoids changing those images unnecessarily.
if /I not "%~1"=="ltsc2025" exit /b 0

@rem Installation and configuration run in separate Docker layers so that the
@rem configuration is verified from a fresh container after Windows servicing.
if /I "%~2"=="install" goto install
if /I "%~2"=="configure" goto configure
exit /b 87

:install
dism.exe /online /add-capability /capabilityname:Microsoft.NanoServer.RemoteFS.Client /norestart /quiet
set "exitCode=%ERRORLEVEL%"

@rem DISM code 3010 means that installation succeeded and a restart is required.
@rem Windows container image builds cannot reboot, so the next layer validates
@rem that the required SMB redirector was installed successfully.
if not "%exitCode%"=="0" if not "%exitCode%"=="3010" exit /b %exitCode%
exit /b 0

:configure
@rem Workstation depends on the SMB 2.0 redirector provided by RemoteFS.
sc.exe qc MRxSmb20 >nul
if errorlevel 1 exit /b %ERRORLEVEL%

sc.exe config LanmanWorkstation start= auto
exit /b %ERRORLEVEL%
