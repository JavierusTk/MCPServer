@echo off
echo ========================================
echo   CyberMAX MCP Server Launcher
echo ========================================
echo.
echo Starting CyberMAX Hello MCP Server...
echo.

REM Change to the server directory
cd /d W:\MCPServer

REM Start the server
CyberMaxHelloMCP.exe

REM If the server exits, pause to see any error messages
echo.
echo Server has stopped.
pause