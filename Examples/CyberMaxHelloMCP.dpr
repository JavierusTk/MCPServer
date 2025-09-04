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
  MCPServer.ToolsManager in 'W:\Delphi-MCP-Server\src\Managers\MCPServer.ToolsManager.pas';

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
  
  WriteLn('========================================');
  WriteLn(' CyberMAX MCP Server - Hello World v1.0');
  WriteLn('========================================');
  WriteLn('Model Context Protocol Server for CyberMAX ERP');
  WriteLn('');
  
  TLogger.Info('Starting CyberMAX MCP Server...');
  TLogger.Info('Listening on port ' + Settings.Port.ToString);
  
  // Create managers
  ManagerRegistry := TMCPManagerRegistry.Create;
  CoreManager := TMCPCoreManager.Create(Settings);
  ToolsManager := TMCPToolsManager.Create;
  ResourcesManager := TMCPResourcesManager.Create;
  
  // Register managers
  ManagerRegistry.RegisterManager(CoreManager);
  ManagerRegistry.RegisterManager(ToolsManager);
  ManagerRegistry.RegisterManager(ResourcesManager);
  
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
    WriteLn('  - hello_cybermax : Get greeting and CyberMAX info');
    WriteLn('  - cyber_echo     : Echo back your message');
    WriteLn('  - cyber_time     : Get current system time');
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