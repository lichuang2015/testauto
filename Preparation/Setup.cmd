powershell -ExecutionPolicy ByPass -WindowStyle Maximized %~dp0Setup.ps1 -PauseAtEnd
@if errorlevel 1 @pause
