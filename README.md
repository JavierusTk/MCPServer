# MCP Server

Model Context Protocol (MCP) server for integration with Claude Code.

[Versión en español](README-ES.md) | [CyberMAX ERP Information](CYBERMAX.md)

## Description

This Delphi-based MCP server provides:
- Integration with Claude Code via Model Context Protocol
- Basic "Hello World" demonstration tools
- Advanced Windows OutputDebugString capture and analysis tools
- Reusable non-visual components for building MCP servers

## Project Structure

```
/mnt/w/MCPserver/
├── MCPServerCore.dproj       # RTL-only core package
├── MCPServerDesign.dproj     # Package with visual components
├── MCPServerDesign.VCL.dpk   # VCL package for IDE
├── MCPServerDesign.FMX.dpk   # FMX package for IDE
├── MCPServer.Engine.pas      # Main server engine
├── MCPServer.Adapter.pas     # Adapter for non-visual components
├── MCPServer.Config.pas      # Configuration with builder pattern
├── MCPServer.Register.pas    # Component registration in IDE
├── README.md                 # This documentation
├── README-ES.md              # Spanish documentation
├── CLAUDE.md                 # Guide for Claude Code
├── settings.ini              # Server configuration
└── Examples/                 # Examples and tools
    ├── CyberMaxHelloMCP.dpr/dproj    # Basic standalone example
    ├── ExampleMCPEngine.dpr/dproj    # Example with TMCPEngine
    ├── ExampleVCLApp.dpr/dproj       # VCL application example
    └── Tools/                        # MCP tools
        ├── MCPServer.Tool.HelloCyberMax.pas
        ├── MCPServer.Tool.CyberEcho.pas
        ├── MCPServer.Tool.CyberTime.pas
        ├── MCPServer.Tool.StartDebugCapture.pas
        ├── MCPServer.Tool.StopDebugCapture.pas
        ├── MCPServer.Tool.GetDebugMessages.pas
        ├── MCPServer.Tool.GetProcessSummary.pas
        ├── MCPServer.Tool.GetCaptureStatus.pas
        ├── MCPServer.Tool.PauseResumeCapture.pas
        ├── MCPServer.DebugCapture.Core.pas
        └── MCPServer.DebugCapture.Types.pas
```

## Available Tools

### Basic Tools

#### 1. hello_cybermax
Returns a welcome message from the MCP server.

**Parameters:** None

**Example response:**
```
¡Hola desde CyberMAX MCP Server!
Server Version: 1.0.0
MCP Protocol: 2024-11-05
Ready to assist!
```

#### 2. cyber_echo
Echoes back the sent message, optionally in uppercase.

**Parameters:**
- `message` (string, required): The message to echo back
- `uppercase` (boolean, optional): If true, returns the message in uppercase

#### 3. cyber_time
Returns the current system time with customizable formatting.

**Parameters:**
- `format` (string, optional): Date/time format
- `includemilliseconds` (boolean, optional): Include milliseconds
- `timezone` (string, optional): Timezone offset

### Debug Capture Tools

**Note:** No administrator privileges required! The debug capture uses session-local objects to capture OutputDebugString messages from user applications in your Windows session.

#### 4. start_debug_capture
Starts a Windows OutputDebugString message capture session.

**Parameters:**
- `sessionname` (string, optional): Descriptive session name
- `processfilter` (string, optional): Filter by process name
- `messagefilter` (string, optional): Filter messages containing this text
- `maxmessages` (integer, optional): Maximum message limit (default: 10000)
- `includesystem` (boolean, optional): Include system processes

**Returns:** Session ID to use with other tools

#### 5. stop_debug_capture
Stops an active capture session.

**Parameters:**
- `sessionid` (string, required): ID of the session to stop

#### 6. get_debug_messages
Retrieves captured messages with optional filters.

**Parameters:**
- `sessionid` (string, required): Session ID
- `limit` (integer, optional): Maximum messages to return (default: 100)
- `offset` (integer, optional): Offset for pagination
- `sincetimestamp` (string, optional): Filter from this date/time
- `processid` (integer, optional): Filter by PID
- `processname` (string, optional): Filter by process name
- `messagecontains` (string, optional): Filter messages containing text
- `messageregex` (string, optional): Filter with regular expression

#### 7. get_process_summary
Gets statistics of processes that have emitted messages.

**Parameters:**
- `sessionid` (string, required): Session ID

#### 8. get_capture_status
Gets capture session status information.

**Parameters:**
- `sessionid` (string, required): Session ID

#### 9. pause_resume_capture
Pauses or resumes message capture.

**Parameters:**
- `sessionid` (string, required): Session ID
- `pause` (boolean, required): true to pause, false to resume

## Server Configuration

### settings.ini
```ini
[Server]
Port=3001
Host=localhost
Transport=http
MaxConnections=10
AllowedOrigins=http://localhost,http://127.0.0.1,https://localhost,https://127.0.0.1

[Logging]
LogLevel=INFO
LogFile=mcp_server.log
ConsoleLog=True

[MCP]
ProtocolVersion=2024-11-05
ServerName=MCP Server
ServerVersion=1.0.0
```

**Important note:** Default port is 3001 (changed from 3000 to avoid conflicts).

## Compilation

### Prerequisites
- RAD Studio 12 (Delphi 29.0)
- Base Delphi-MCP-Server repository cloned at `/mnt/w/Delphi-MCP-Server`
- TaurusTLS_RT in runtime packages

### Building the Projects

#### Option 1: Standalone Example (CyberMaxHelloMCP)
```
Compilar Examples/CyberMaxHelloMCP.dproj
```

#### Option 2: Example with TMCPEngine
```
Compilar Examples/ExampleMCPEngine.dproj
```

#### Option 3: VCL Application
```
Compilar Examples/ExampleVCLApp.dproj
```

#### Building the Packages (for component development)
```
Compilar MCPServerCore.dproj       # RTL-only package
Compilar MCPServerDesign.dproj     # Package with visual components
```

**Note:** The compiler-agent requires the .dproj file

## Running the Server

### Run CyberMaxHelloMCP (basic example)
```bash
cd /mnt/w/MCPserver/Examples
./CyberMaxHelloMCP.exe
```

### Run ExampleMCPEngine (with advanced configuration)
```bash
cd /mnt/w/MCPserver/Examples
./ExampleMCPEngine.exe
```

The server will display:
```
========================================
 CyberMAX MCP Server - Hello World v1.0
========================================
Server started successfully!

Available tools:
  Basic Tools:
    - hello_cybermax        : Get greeting and CyberMAX info
    - cyber_echo           : Echo back your message
    - cyber_time           : Get current system time

  Debug Capture Tools:
    - start_debug_capture  : Start capturing OutputDebugString
    - stop_debug_capture   : Stop capture session
    - get_debug_messages   : Retrieve captured messages
    - get_process_summary  : Get process statistics
    - get_capture_status   : Get session information
    - pause_resume_capture : Pause/resume capture

Press CTRL+C to stop...
```

## Configuring Claude Code

### 1. Determine Windows System IP

From WSL, run:
```bash
ip route | grep default | awk '{print $3}'
# Or verify with: hostname -I
```

In this case, the IP is: `192.168.0.89`

### 2. Configure Claude Code

The MCP server uses HTTP transport with the `/mcp` endpoint. Claude Code requires command-line configuration.

#### Recommended method - `mcp add` command:
```bash
claude mcp add cybermax-hello http://192.168.0.89:3001/mcp --scope user -t http
```

**Important parameters:**
- `cybermax-hello`: MCP server name
- `http://192.168.0.89:3001/mcp`: Complete URL with endpoint
- `--scope user`: Configuration scope (user, project, or local)
- `-t http`: HTTP transport type (required for remote servers)

#### Alternative method - Interactive `/config` command:
```bash
# Within Claude Code, use:
/config

# Then manually add the server
```

**Important notes:**
- The `--mcp-config` flag has a known bug in version v1.0.73 and doesn't work correctly
- For remote HTTP servers, ALWAYS specify `-t http`
- Must use the `/mcp` endpoint (not just IP and port)
- Correct format is: `http://IP:PORT/mcp`

### 3. Verify Connection

Once configured, tools will appear with the prefix `mcp__cybermax-hello__`:
- `mcp__cybermax-hello__hello_cybermax`
- `mcp__cybermax-hello__cyber_echo`
- `mcp__cybermax-hello__cyber_time`

To verify the server is available:
```bash
# List configured MCP servers
claude mcp list

# Or within Claude Code
/mcp
```

## Technical Architecture

### Main Components

#### TMCPEngine
Main non-visual component that encapsulates all MCP server functionality:
- Automatic server lifecycle management
- Configuration via published properties
- Events for logging and control
- Auto-registration of tools
- CORS support

#### TMCPAdapter
Adapter component allowing TMCPEngine use in VCL/FMX applications:
- Published properties for design-time configuration
- Events visible in Object Inspector
- Delphi IDE integration

#### TMCPConfig
Configuration class with builder pattern:
```pascal
Config := TMCPConfig.Create
  .WithPort(3001)
  .WithHost('localhost')
  .WithServerName('MCP Server')
  .WithCORS(True);
```

### Tool Pattern

Each tool implements:

1. **Parameter class** with RTTI attributes for schema generation
2. **Tool class** extending `TMCPToolBase<TParams>`
3. **Automatic registration** in initialization section

### Error Handling

The server implements robust error handling:
- Parameter validation before processing
- Explicit initialization of optional values in constructors
- Direct property usage without unnecessary complexity

Correct example in cyber_echo:
```pascal
// Initialization in constructor
constructor TCyberEchoParams.Create;
begin
  inherited;
  FMessage := '';
  FUpperCase := False;  // Explicit even though Delphi initializes to False
end;

// Direct and simple property usage
if Params.UpperCase then
  ProcessedMessage := System.SysUtils.UpperCase(Params.Message)
else
  ProcessedMessage := Params.Message;
```

**Important note:**
- Don't use try-except for reading simple properties
- Don't copy property values to local variables unnecessarily
- Delphi automatically initializes: Boolean→False, Integer→0, String→''

## Use Cases

### Windows Application Debugging
Debug capture tools enable:
- Real-time monitoring of OutputDebugString messages
- Process or message content filtering
- Non-invasive application behavior analysis
- Debugging intermittent production issues

## Developing New Tools

To add a new tool:

1. Create parameter class with schema attributes
2. Implement tool extending `TMCPToolBase<TParams>`
3. Register in initialization section
4. Tool is automatically discovered via RTTI

Minimal example:
```pascal
type
  TMyParams = class
    [SchemaDescription('Parameter description')]
    property MyParam: string read FMyParam write FMyParam;
  end;

  TMyTool = class(TMCPToolBase<TMyParams>)
  protected
    function ExecuteWithParams(const Params: TMyParams): string; override;
  public
    constructor Create; override;
  end;

initialization
  TMCPRegistry.RegisterTool('my_tool', function: IMCPTool
    begin Result := TMyTool.Create; end);
```

## Troubleshooting

### Port in Use
If port 3001 is in use:
1. Change in `settings.ini`
2. Update configuration in Claude Code

### Access Violation
If Access Violation errors appear:
1. Verify initialization of optional parameters
2. Add constructors with default values
3. Implement defensive property handling

### Server Not Visible in Claude Code
1. Verify it uses HTTP transport (not stdio)
2. Confirm `/mcp` endpoint
3. Use Windows system IP, not localhost from WSL
4. Check Windows firewall

### Hung Process
```bash
# From WSL
taskkill.exe /IM CyberMaxHelloMCP.exe /F

# Or find and kill process
ps aux | grep CyberMax
kill -9 [PID]
```

## Logs and Debugging

Server logs show:
- Initialization and configuration
- Each received JSON-RPC request
- Claude Code Session ID
- Sent responses
- Errors and exceptions

Log example:
```
[2025-09-03 13:17:14.906] [INFO ] Request: {"method":"tools/call","params":{"name":"cyber_echo",...}}
[2025-09-03 13:17:14.906] [INFO ] Session ID from header: {ADB063D4-752F-4795-A98D-0E843FDF2AA4}
[2025-09-03 13:17:14.906] [INFO ] MCP CallTool called for tool: cyber_echo
[2025-09-03 13:17:14.906] [INFO ] Response: {"jsonrpc":"2.0","id":3,"result":{...}}
```

## Technical Notes

- **Platform:** Windows (debug capture requires Windows APIs)
- **Privileges:** No admin rights needed for debug capture - uses session-local objects
- **Conflict Detection:** Automatically detects and reports if DebugView or other debuggers are running
- **Encoding:** UTF-8 for new files
- **Protocol:** MCP over JSON-RPC 2.0
- **RTTI:** Automatic tool discovery via attributes
- **Thread-safe:** Debug capture in separate thread with full synchronization
- **CORS:** Configurable for development

---
Last updated: 2025-09-17
MCP Server v2.0.0