@echo off
rem Builds the testing results page for the report (section 5.5.1) and opens it.
rem It asks which tests to run (all, main parts, or project work only) and for a
rem Supabase access token (press Enter to skip the Supabase numbers).
rem
rem   tool\report\report.bat            asks
rem   tool\report\report.bat --all      all tests, no question
rem   tool\report\report.bat --main     main parts only
rem
rem More options at the top of tool\report\make_report.dart.
setlocal
cd /d "%~dp0..\.."
call dart run tool/report/make_report.dart %*
set RESULT=%ERRORLEVEL%
pause
exit /b %RESULT%
