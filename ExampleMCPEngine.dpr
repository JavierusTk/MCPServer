program ExampleMCPEngine;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.SyncObjs,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  MCPServer.Engine in 'MCPServer.Engine.pas',
  MCPServer.Config in 'MCPServer.Config.pas',
  MCPServer.Tool.HelloCyberMax in 'Tools\MCPServer.Tool.HelloCyberMax.pas',
  MCPServer.Tool.CyberEcho in 'Tools\MCPServer.Tool.CyberEcho.pas',
  MCPServer.Tool.CyberTime in 'Tools\MCPServer.Tool.CyberTime.pas';

var
  MCPEngine: TMCPEngine;
  ShutdownEvent: TEvent;
  Config: TMCPConfig;

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
      WriteLn('[INFO] Shutdown signal received');
      if Assigned(ShutdownEvent) then
        ShutdownEvent.SetEvent;
    end;
  end;
end;
{$ENDIF}

procedure RunExample;
var
  Tools: TArray<string>;
  Tool: string;
begin
  WriteLn('==========================================');
  WriteLn(' MCP Engine Example - RTL-Based Server');
  WriteLn('==========================================');
  WriteLn('');
  
  // Create configuration using builder pattern
  Config := TMCPConfig.Create
    .WithPort(3001)
    .WithHost('localhost')
    .WithServerName('Example MCP Server')
    .WithServerVersion('2.0.0')
    .WithCORS(True)
    .WithCORSOrigin('*');
  
  // Create and configure the MCP Engine
  MCPEngine := TMCPEngine.Create;
  try
    // Configure the engine
    MCPEngine.Port := Config.Port;
    MCPEngine.Host := Config.Host;
    MCPEngine.ServerName := Config.ServerName;
    MCPEngine.ServerVersion := Config.ServerVersion;
    
    // Set up event handlers using anonymous methods
    MCPEngine.OnLog := procedure(const Level, Message: string)
    begin
      WriteLn(Format('[%s] %s', [Level, Message]));
    end;
    
    MCPEngine.OnStarted := procedure
    begin
      WriteLn('');
      WriteLn('>>> Server started successfully! <<<');
      WriteLn('');
    end;
    
    MCPEngine.OnStopped := procedure
    begin
      WriteLn('');
      WriteLn('>>> Server stopped <<<');
    end;
    
    MCPEngine.OnError := procedure(const Error: Exception)
    begin
      WriteLn('');
      WriteLn('!!! ERROR: ' + Error.Message);
    end;
    
    // Start the server
    MCPEngine.Start;
    
    // Display registered tools
    WriteLn('Registered Tools:');
    Tools := MCPEngine.GetRegisteredTools;
    for Tool in Tools do
      WriteLn('  - ' + Tool);
    WriteLn('');
    
    WriteLn(Format('Server is running on http://%s:%d/mcp', 
      [MCPEngine.Host, MCPEngine.Port]));
    WriteLn('');
    WriteLn('To connect from Claude Code:');
    WriteLn(Format('  claude mcp add example-server http://%s:%d/mcp --scope user -t http',
      [MCPEngine.Host, MCPEngine.Port]));
    WriteLn('');
    WriteLn('Press CTRL+C to stop...');
    WriteLn('==========================================');
    
    // Wait for shutdown signal
    ShutdownEvent.WaitFor(INFINITE);
    
    // Stop the server
    MCPEngine.Stop;
    
  finally
    MCPEngine.Free;
    Config.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  
  // Create shutdown event
  ShutdownEvent := TEvent.Create(nil, True, False, '');
  try
    // Set up signal handlers
    {$IFDEF MSWINDOWS}
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
    {$ENDIF}
    
    try
      RunExample;
    except
      on E: Exception do
      begin
        WriteLn('FATAL ERROR: ' + E.Message);
        WriteLn('Press ENTER to exit...');
        ReadLn;
      end;
    end;
    
    {$IFDEF MSWINDOWS}
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, False);
    {$ENDIF}
  finally
    ShutdownEvent.Free;
  end;
end.