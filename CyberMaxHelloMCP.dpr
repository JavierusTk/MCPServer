program CyberMaxHelloMCP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.SyncObjs,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  // Core units from base repository
  MCPServer.Types in '..\Delphi-MCP-Server\src\Protocol\MCPServer.Types.pas',
  MCPServer.Serializer in '..\Delphi-MCP-Server\src\Protocol\MCPServer.Serializer.pas',
  MCPServer.Schema.Generator in '..\Delphi-MCP-Server\src\Protocol\MCPServer.Schema.Generator.pas',
  MCPServer.Logger in '..\Delphi-MCP-Server\src\Core\MCPServer.Logger.pas',
  MCPServer.Settings in '..\Delphi-MCP-Server\src\Core\MCPServer.Settings.pas',
  MCPServer.Registration in '..\Delphi-MCP-Server\src\Core\MCPServer.Registration.pas',
  MCPServer.ManagerRegistry in '..\Delphi-MCP-Server\src\Core\MCPServer.ManagerRegistry.pas',
  MCPServer.Tool.Base in '..\Delphi-MCP-Server\src\Tools\MCPServer.Tool.Base.pas',
  MCPServer.Resource.Base in '..\Delphi-MCP-Server\src\Resources\MCPServer.Resource.Base.pas',
  MCPServer.IdHTTPServer in '..\Delphi-MCP-Server\src\Server\MCPServer.IdHTTPServer.pas',
  MCPServer.CoreManager in '..\Delphi-MCP-Server\src\Managers\MCPServer.CoreManager.pas',
  MCPServer.ToolsManager in '..\Delphi-MCP-Server\src\Managers\MCPServer.ToolsManager.pas',
  MCPServer.ResourcesManager in '..\Delphi-MCP-Server\src\Managers\MCPServer.ResourcesManager.pas',
  MCPServer.Resource.Server in '..\Delphi-MCP-Server\src\Resources\MCPServer.Resource.Server.pas',
  // Our custom tools for CyberMAX
  MCPServer.Tool.HelloCyberMax in 'Tools\MCPServer.Tool.HelloCyberMax.pas',
  MCPServer.Tool.CyberEcho in 'Tools\MCPServer.Tool.CyberEcho.pas',
  MCPServer.Tool.CyberTime in 'Tools\MCPServer.Tool.CyberTime.pas';

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