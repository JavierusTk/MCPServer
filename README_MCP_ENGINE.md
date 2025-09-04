# MCP Engine - Easy MCP Server Integration for Delphi

## Overview

MCP Engine provides a simple, framework-agnostic way to add Model Context Protocol (MCP) server capabilities to any Delphi application. Built on pure RTL (Runtime Library), it works with VCL, FMX, console applications, Windows services, and more.

## Key Features

- **Framework Independent**: Pure RTL implementation - works with VCL, FMX, or no UI framework
- **Simple Integration**: Just a few lines of code to add MCP server to your app
- **Thread-Safe**: Built-in thread safety for UI applications
- **Event-Driven**: Use anonymous methods for event handling
- **Zero Configuration**: Sensible defaults, optional configuration
- **Optional VCL Adapter**: Design-time support and helper methods for VCL apps

## Architecture

```
┌─────────────────────────────────────────────┐
│           Your Application                  │
├─────────────────────────────────────────────┤
│     MCPServer.Engine (Pure RTL)             │
│     - TMCPEngine class                      │
│     - Event callbacks via anonymous methods │
│     - Thread-safe operation                 │
├─────────────────────────────────────────────┤
│     Optional Framework Adapters             │
│     - MCPServer.VCL.Adapter (VCL apps)      │
│     - MCPServer.FMX.Adapter (FMX apps)      │
├─────────────────────────────────────────────┤
│     MCP Protocol Core (from base repo)      │
│     - Protocol handling                     │
│     - Tool registration                     │
│     - HTTP server (Indy)                    │
└─────────────────────────────────────────────┘
```

## Quick Start

### 1. Console Application (Pure RTL)

```pascal
uses
  MCPServer.Engine,
  MCPServer.Tool.HelloCyberMax; // Tools auto-register

var
  MCPEngine: TMCPEngine;
begin
  MCPEngine := TMCPEngine.Create;
  try
    MCPEngine.Port := 3001;
    MCPEngine.OnLog := procedure(const Level, Message: string)
    begin
      WriteLn(Format('[%s] %s', [Level, Message]));
    end;
    MCPEngine.Start;
    
    // Keep running...
    ReadLn;
    
    MCPEngine.Stop;
  finally
    MCPEngine.Free;
  end;
end;
```

### 2. VCL Application (with optional adapter)

```pascal
uses
  MCPServer.Engine,
  MCPServer.VCL.Adapter;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FMCPEngine := TMCPEngineVCL.Create(Self);
  FMCPEngine.Port := 3001;
  FMCPEngine.OnLog := OnMCPLog;
  FMCPEngine.Start;
end;

procedure TMainForm.OnMCPLog(Sender: TObject; const Level, Message: string);
begin
  FMCPEngine.LogToMemo(Memo1, Level, Message);
end;
```

### 3. FMX Application (Pure RTL)

```pascal
uses
  MCPServer.Engine;

procedure TMainForm.StartMCPServer;
begin
  FMCPEngine := TMCPEngine.Create;
  FMCPEngine.Port := 3001;
  FMCPEngine.OnLog := procedure(const Level, Message: string)
  begin
    TThread.Queue(nil, procedure
    begin
      ListBox1.Items.Add(Format('[%s] %s', [Level, Message]));
    end);
  end;
  FMCPEngine.Start;
end;
```

## Components

### Core Classes (RTL-only)

#### TMCPEngine
The main engine class that manages the MCP server.

**Properties:**
- `Port: Word` - Server port (default: 3001)
- `Host: string` - Server host (default: 'localhost')
- `ServerName: string` - Server identification
- `ServerVersion: string` - Server version
- `Active: Boolean` - Read-only server status
- `EnableCORS: Boolean` - Enable CORS support
- `CORSOrigins: string` - Allowed CORS origins

**Methods:**
- `Start` - Start the MCP server
- `Stop` - Stop the MCP server
- `GetRegisteredTools: TArray<string>` - List registered tools
- `IsToolRegistered(name): Boolean` - Check if tool exists

**Events (via anonymous methods):**
- `OnLog: procedure(const Level, Message: string)`
- `OnStarted: procedure`
- `OnStopped: procedure`
- `OnError: procedure(const Error: Exception)`
- `OnRequest: procedure(const Method, Params: string)`

#### TMCPConfig
Configuration builder with fluent interface.

```pascal
Config := TMCPConfig.Create
  .WithPort(3001)
  .WithHost('localhost')
  .WithServerName('My MCP Server')
  .WithCORS(True)
  .WithCORSOrigin('*');
```

### Optional VCL Adapter

#### TMCPEngineVCL
VCL component wrapper for design-time support.

**Additional Features:**
- Drop on form at design-time
- Traditional VCL events (OnLog, OnStarted, etc.)
- Helper methods for common VCL controls
- `LogToMemo`, `LogToListBox`, `LogToRichEdit`

## File Structure

```
/mnt/w/MCPServer/
├── MCPServer.Engine.pas          # Core RTL engine
├── MCPServer.Config.pas          # Configuration builder
├── MCPServer.VCL.Adapter.pas     # Optional VCL wrapper
├── MCPServerCore.dpk             # RTL-only runtime package
├── ExampleMCPEngine.dpr          # Console app example
├── ExampleVCLApp.dpr             # VCL app example
└── Tools/                        # Your MCP tools
    ├── MCPServer.Tool.HelloCyberMax.pas
    ├── MCPServer.Tool.CyberEcho.pas
    └── MCPServer.Tool.CyberTime.pas
```

## Creating Custom Tools

Tools are automatically registered when their units are included:

```pascal
unit MCPServer.Tool.MyTool;

interface

uses
  MCPServer.Tool.Base,
  MCPServer.Registration;

type
  TMyToolParams = class
    [SchemaDescription('Input parameter')]
    property Input: string;
  end;

  TMyTool = class(TMCPToolBase<TMyToolParams>)
  protected
    function ExecuteWithParams(const Params: TMyToolParams): string; override;
  public
    constructor Create; override;
  end;

implementation

constructor TMyTool.Create;
begin
  inherited;
  FName := 'my_tool';
  FDescription := 'My custom tool';
end;

function TMyTool.ExecuteWithParams(const Params: TMyToolParams): string;
begin
  Result := 'Processed: ' + Params.Input;
end;

initialization
  TMCPRegistry.RegisterTool('my_tool', 
    function: IMCPTool
    begin
      Result := TMyTool.Create;
    end
  );

end.
```

## Integration Steps

### For Any Delphi Application:

1. **Add to uses clause:**
   ```pascal
   uses
     MCPServer.Engine,
     MCPServer.Config,
     // Your tool units (they auto-register)
     MCPServer.Tool.YourTool;
   ```

2. **Create and start engine:**
   ```pascal
   FEngine := TMCPEngine.Create;
   FEngine.Port := 3001;
   FEngine.Start;
   ```

3. **Handle events (optional):**
   ```pascal
   FEngine.OnLog := procedure(const Level, Message: string)
   begin
     // Your logging code
   end;
   ```

4. **Stop when done:**
   ```pascal
   FEngine.Stop;
   FEngine.Free;
   ```

## Connecting from Claude Code

Once your server is running:

```bash
claude mcp add my-server http://localhost:3001/mcp --scope user -t http
```

## Dependencies

- Delphi RAD Studio 12 or later
- Indy components (included with Delphi)
- TaurusTLS (for SSL support, optional)
- Base Delphi-MCP-Server repository

## Thread Safety

The engine handles thread safety automatically:
- Events are dispatched to main thread when needed
- Safe to call from any thread
- VCL/FMX controls updated safely

## Benefits Over Console-Only Approach

1. **Flexibility**: Use in any application type
2. **No Console Window**: Integrate into GUI apps seamlessly
3. **Easy Integration**: Just add unit, create object, call Start()
4. **Event-Driven**: React to server events in your app
5. **Design-Time Support**: VCL adapter for RAD development
6. **Reusable**: Same code for console, VCL, FMX, services

## License

Same as the base Delphi-MCP-Server project.

## Support

For issues or questions, refer to the main Delphi-MCP-Server repository.