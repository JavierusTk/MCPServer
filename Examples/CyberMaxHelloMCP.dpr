program CyberMaxHelloMCP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF }
  System.SyncObjs,
  MCPServer.IdHTTPServer in 'W:\Delphi-MCP-Server\src\Server\MCPServer.IdHTTPServer.pas',
  MCPServer.Logger in 'W:\Delphi-MCP-Server\src\Core\MCPServer.Logger.pas',
  MCPServer.ManagerRegistry in 'W:\Delphi-MCP-Server\src\Core\MCPServer.ManagerRegistry.pas',
  MCPServer.Settings in 'W:\Delphi-MCP-Server\src\Core\MCPServer.Settings.pas',
  MCPServer.Types in 'W:\Delphi-MCP-Server\src\Protocol\MCPServer.Types.pas',
  MCPServer.ResourcesManager in 'W:\Delphi-MCP-Server\src\Managers\MCPServer.ResourcesManager.pas',
  MCPServer.Resource.Server in 'W:\Delphi-MCP-Server\src\Resources\MCPServer.Resource.Server.pas',
  MCPServer.CoreManager in 'W:\Delphi-MCP-Server\src\Managers\MCPServer.CoreManager.pas',
  MCPServer.ToolsManager in 'W:\Delphi-MCP-Server\src\Managers\MCPServer.ToolsManager.pas',
  MCPServer.Tool.HelloCyberMax in 'Tools\MCPServer.Tool.HelloCyberMax.pas',
  MCPServer.Tool.CyberEcho in 'Tools\MCPServer.Tool.CyberEcho.pas',
  MCPServer.Tool.CyberTime in 'Tools\MCPServer.Tool.CyberTime.pas',
  MCPServer.DebugCapture.Types in 'Tools\MCPServer.DebugCapture.Types.pas',
  MCPServer.DebugCapture.Core in 'Tools\MCPServer.DebugCapture.Core.pas',
  MCPServer.Tool.StartDebugCapture in 'Tools\MCPServer.Tool.StartDebugCapture.pas',
  MCPServer.Tool.StopDebugCapture in 'Tools\MCPServer.Tool.StopDebugCapture.pas',
  MCPServer.Tool.GetDebugMessages in 'Tools\MCPServer.Tool.GetDebugMessages.pas',
  MCPServer.Tool.GetProcessSummary in 'Tools\MCPServer.Tool.GetProcessSummary.pas',
  MCPServer.Tool.GetCaptureStatus in 'Tools\MCPServer.Tool.GetCaptureStatus.pas',
  MCPServer.Tool.PauseResumeCapture in 'Tools\MCPServer.Tool.PauseResumeCapture.pas',
  MCPServer.CyberMAX.PipeClient in 'Tools\MCPServer.CyberMAX.PipeClient.pas',
  MCPServer.CyberMAX.DynamicProxy in 'Tools\MCPServer.CyberMAX.DynamicProxy.pas';

var
  Server: TMCPIdHTTPServer;
  Settings: TMCPSettings;
  ManagerRegistry: IMCPManagerRegistry;
  CoreManager: IMCPCapabilityManager;
  ToolsManager: IMCPCapabilityManager;
  ResourcesManager: IMCPCapabilityManager;
  ShutdownEvent: TEvent;

{$IFDEF MSWINDOWS}
function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  Result := True;
  case dwCtrlType of
    CTRL_C_EVENT,
    CTRL_BREAK_EVENT,
    CTRL_CLOSE_EVENT,
    CTRL_LOGOFF_EVENT,
    CTRL_SHUTDOWN_EVENT:
    begin
      TLogger.Info('Shutdown signal received');
      if Assigned(ShutdownEvent) then
        ShutdownEvent.SetEvent;
    end;
  end;
end;
{$ENDIF}

procedure RunServer;
begin
  // Load settings
  Settings := TMCPSettings.Create;
  Settings.Port:=3001;
  
  WriteLn('========================================');
  WriteLn(' CyberMAX MCP Server - Hello World v1.0');
  WriteLn('========================================');
  WriteLn('Model Context Protocol Server for CyberMAX ERP');
  WriteLn('');
  
  TLogger.Info('Starting CyberMAX MCP Server...');
  TLogger.Info('Listening on port ' + Settings.Port.ToString);

  // Discover and register CyberMAX tools dynamically BEFORE creating ToolsManager
  TLogger.Info('Discovering CyberMAX tools...');
  var CyberMAXToolCount := RegisterAllCyberMAXTools;

  // Create managers (ToolsManager will pick up the dynamically registered tools)
  ManagerRegistry := TMCPManagerRegistry.Create;
  CoreManager := TMCPCoreManager.Create(Settings);
  ToolsManager := TMCPToolsManager.Create;
  ResourcesManager := TMCPResourcesManager.Create;

  // Register managers
  ManagerRegistry.RegisterManager(CoreManager);
  ManagerRegistry.RegisterManager(ToolsManager);
  ManagerRegistry.RegisterManager(ResourcesManager);
  if CyberMAXToolCount > 0 then
    TLogger.Info('Registered ' + CyberMAXToolCount.ToString + ' CyberMAX tools')
  else
    TLogger.Warning('No CyberMAX tools registered (CyberMAX may not be running)');

  // Create and configure server
  Server := TMCPIdHTTPServer.Create(nil);
  try
    Server.Settings := Settings;
    Server.ManagerRegistry := ManagerRegistry;
    Server.CoreManager := CoreManager;

    // Start server
    Server.Start;
    
    WriteLn('Server started successfully!');
    WriteLn('');
    WriteLn('Available tools:');
    WriteLn('  Basic Tools:');
    WriteLn('    - hello_cybermax        : Get greeting and CyberMAX info');
    WriteLn('    - cyber_echo           : Echo back your message');
    WriteLn('    - cyber_time           : Get current system time');
    WriteLn('');
    WriteLn('  Debug Capture Tools:');
    WriteLn('    - start_debug_capture  : Start capturing OutputDebugString');
    WriteLn('    - stop_debug_capture   : Stop capture session');
    WriteLn('    - get_debug_messages   : Retrieve captured messages');
    WriteLn('    - get_process_summary  : Get process statistics');
    WriteLn('    - get_capture_status   : Get session information');
    WriteLn('    - pause_resume_capture : Pause/resume capture');
    WriteLn('');
    if CyberMAXToolCount > 0 then
    begin
      WriteLn('  CyberMAX Tools: ' + CyberMAXToolCount.ToString + ' tools discovered and registered');
      WriteLn('    (All CyberMAX tools are dynamically discovered from running instance)');
      WriteLn('    Use MCP tools/list endpoint or list-tools to see all available tools');
    end
    else
    begin
      WriteLn('  CyberMAX Tools: Not available');
      WriteLn('    Start CyberMAX.exe (RELEASE build) and restart this server to enable');
    end;
    WriteLn('');
    WriteLn('Press CTRL+C to stop...');
    WriteLn('========================================');
    
    // Wait for shutdown signal
    ShutdownEvent.WaitFor(INFINITE);
    
    // Graceful shutdown
    TLogger.Info('Shutting down server...');
    Server.Stop;
    TLogger.Info('Server stopped successfully');
  finally
    Server.Free;
    Settings.Free;
  end;
end;

begin
  // Configure logger
  TLogger.LogToConsole := True;
  TLogger.MinLogLevel := TLogLevel.Info;
  
  ReportMemoryLeaksOnShutdown := True;
  IsMultiThread := True;
  
  // Create shutdown event
  ShutdownEvent := TEvent.Create(nil, True, False, '');
  try
    // Set up signal handlers
    {$IFDEF MSWINDOWS}
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
    {$ENDIF}
    
    try
      TServerStatusResource.Initialize;
      RunServer;
    except
      on E: Exception do
      begin
        WriteLn('ERROR: ' + E.Message);
        TLogger.Error(E);
      end;
    end;
    
    {$IFDEF MSWINDOWS}
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, False);
    {$ENDIF}
  finally
    ShutdownEvent.Free;
  end;
end.