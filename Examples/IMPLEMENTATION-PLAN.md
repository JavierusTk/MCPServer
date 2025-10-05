# Implementation Plan: MCP Server Connection with CyberMAX via Named Pipes

**Date**: 2025-10-05
**Status**: Analysis Complete - Ready for Implementation Review
**Current State**: Partially Implemented - Dynamic proxy architecture exists

---

## Executive Summary

The MCP server connection with CyberMAX **is already implemented** using a dynamic proxy architecture with Windows named pipes. This plan documents the existing implementation and proposes enhancements if needed.

### Current Architecture Status

✅ **ALREADY WORKING:**
- Named pipe client (`MCPServer.CyberMAX.PipeClient.pas`)
- Dynamic tool discovery (`MCPServer.CyberMAX.DynamicProxy.pas`)
- HTTP MCP server integration (`CyberMaxHelloMCP.dpr`)
- JSON-RPC 2.0 protocol over pipes
- Automatic tool registration from CyberMAX runtime registry

⏸️ **POTENTIALLY MISSING:**
- Testing/verification that all components work end-to-end
- Error handling edge cases
- Performance optimization
- Enhanced logging/diagnostics

---

## Architecture Overview

### Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code (AI)                         │
│              Uses MCP protocol over HTTP                    │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP POST to http://IP:3001/mcp
                     │ MCP JSON-RPC 2.0 requests
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           CyberMaxHelloMCP.exe (Bridge Server)              │
│                                                             │
│  [Startup Phase]                                            │
│  1. Start HTTP server on port 3001                          │
│  2. Call RegisterAllCyberMAXTools()                         │
│     - Connect to \\.\pipe\CyberMAX_MCP_Request              │
│     - Send: {"method":"list-tools","params":{}}             │
│     - Receive: {"tools":[{name,description,category},...]}  │
│     - Register each tool dynamically with MCP registry      │
│                                                             │
│  [Execution Phase]                                          │
│  - Receive MCP tool call from Claude Code                   │
│  - TCyberMAXDynamicTool.ExecuteWithParams()                 │
│     - Forward to CyberMAX via ExecuteCyberMAXTool()         │
│     - Return result to Claude Code                          │
└────────────────────┬────────────────────────────────────────┘
                     │ Named Pipe: \\.\pipe\CyberMAX_MCP_Request
                     │ JSON-RPC 2.0 messages
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              CyberMAX.exe (ERP Application)                 │
│                                                             │
│  [MCP Server Thread]                                        │
│  - TMCPServerThread (MCPServerThread.pas)                   │
│  - Listens on named pipe                                    │
│  - Receives JSON-RPC requests                               │
│  - Routes to MCPToolRegistry                                │
│  - Executes via TThread.Synchronize (main thread)           │
│  - Returns JSON-RPC responses                               │
│                                                             │
│  [Tool Registry]                                            │
│  - MCPToolRegistry (MCPToolRegistry.pas)                    │
│  - 16+ core tools registered                                │
│  - Module tools (TCConta, Almacen, etc.)                    │
│  - list-tools, execute-internal, take-screenshot, etc.      │
└─────────────────────────────────────────────────────────────┘
```

---

## Existing Implementation Details

### 1. Named Pipe Client (✅ Implemented)

**File**: `/mnt/w/MCPserver/Examples/Tools/MCPServer.CyberMAX.PipeClient.pas`

**Key Functions:**
```pascal
function ExecuteCyberMAXTool(const ToolName: string; Params: TJSONObject): TCyberMAXPipeResult;
function IsCyberMAXRunning: Boolean;
```

**Features:**
- Connects to `\\.\pipe\CyberMAX_MCP_Request`
- 5-second timeout with retry logic
- JSON-RPC 2.0 request/response handling
- Error detection and reporting
- Proper resource cleanup

**Protocol:**
```json
// Request
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "take-screenshot",
  "params": {"target": "active"}
}

// Response (Success)
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {"success": true, "image": "base64data..."}
}

// Response (Error)
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {"code": -32603, "message": "Tool not found"}
}
```

### 2. Dynamic Proxy (✅ Implemented)

**File**: `/mnt/w/MCPserver/Examples/Tools/MCPServer.CyberMAX.DynamicProxy.pas`

**Key Components:**

**TCyberMAXDynamicTool**: Generic tool wrapper
- Stores tool name and description
- Forwards all execution to CyberMAX via pipe
- No hardcoded tool logic

**RegisterAllCyberMAXTools()**: Discovery function
- Queries `list-tools` from CyberMAX
- Parses tool metadata
- Registers each tool with HTTP MCP server
- Returns count of registered tools

**Benefits:**
- ✅ Zero maintenance - tools discovered automatically
- ✅ Single source of truth (CyberMAX registry)
- ✅ Unlimited scalability (any number of tools)
- ✅ 88% code reduction vs. hardcoded approach

### 3. HTTP MCP Server Integration (✅ Implemented)

**File**: `/mnt/w/MCPserver/Examples/CyberMaxHelloMCP.dpr`

**Startup Sequence:**
```pascal
procedure RunServer;
begin
  // 1. Create HTTP server on port 3001
  Settings := TMCPSettings.Create;
  Settings.Port := 3001;

  // 2. Create managers
  ManagerRegistry := TMCPManagerRegistry.Create;
  CoreManager := TMCPCoreManager.Create(Settings);
  ToolsManager := TMCPToolsManager.Create;

  // 3. Discover CyberMAX tools dynamically
  var CyberMAXToolCount := RegisterAllCyberMAXTools;

  // 4. Start HTTP server
  Server := TMCPIdHTTPServer.Create(nil);
  Server.Start;

  // 5. Wait for shutdown signal
  ShutdownEvent.WaitFor(INFINITE);
end;
```

**Features:**
- Console application with signal handling
- CORS enabled for development
- Graceful shutdown
- Comprehensive logging

---

## Implementation Plan

### Phase 1: Verification & Testing (Recommended First Step)

**Goal**: Verify existing implementation works end-to-end

#### Tasks:

1. **Build Verification**
   - Compile CyberMAX in RELEASE mode (MCP server enabled)
   - Compile CyberMaxHelloMCP.exe
   - Verify no compilation errors

2. **Runtime Testing**
   - Start CyberMAX.exe
   - Verify pipe creation: `\\.\pipe\CyberMAX_MCP_Request`
   - Start CyberMaxHelloMCP.exe
   - Verify tool discovery (should show "Registered X tools")
   - Test basic tool execution via HTTP

3. **Tool Discovery Testing**
   ```bash
   # Test list-tools endpoint
   curl -X POST http://localhost:3001/mcp \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'

   # Expected: List of all discovered CyberMAX tools
   ```

4. **Tool Execution Testing**
   ```bash
   # Test execute tool
   curl -X POST http://localhost:3001/mcp \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"list-internals","arguments":{}}}'

   # Expected: List of 413+ Internals from CyberMAX
   ```

5. **Error Handling Testing**
   - Stop CyberMAX, try tool execution → Should report "CyberMAX not running"
   - Invalid tool name → Should report tool not found
   - Invalid parameters → Should report parameter errors

**Deliverables:**
- Test results document
- List of any bugs/issues found
- Performance metrics (latency, throughput)

**Estimated Time**: 2-4 hours

---

### Phase 2: Enhancement (Optional - Only if Issues Found)

**Goal**: Fix any issues identified in Phase 1

#### Potential Enhancements:

1. **Error Handling Improvements**
   - Better error messages
   - Retry logic for transient failures
   - Graceful degradation

2. **Performance Optimization**
   - Connection pooling for pipes
   - Parallel tool registration
   - Response caching

3. **Diagnostics & Logging**
   - Detailed pipe communication logs
   - Performance metrics
   - Health check endpoints

4. **Reconnection Logic**
   - Auto-reconnect when CyberMAX restarts
   - Tool re-discovery without bridge restart
   - Connection status monitoring

**Deliverables:**
- Enhanced pipe client with improvements
- Updated documentation
- New test cases

**Estimated Time**: 4-8 hours (if needed)

---

### Phase 3: Documentation & Integration

**Goal**: Document the system and integrate with Claude Code

#### Tasks:

1. **Documentation Updates**
   - Update `/mnt/w/MCPserver/CLAUDE.md` with pipe architecture
   - Update `/mnt/w/AUTO-TOOLING.md` with bridge details
   - Create troubleshooting guide
   - Document tool naming conventions

2. **Claude Code Integration**
   - Get WSL IP address: `ip route | grep default | awk '{print $3}'`
   - Configure MCP server in Claude Code settings
   - Test tool discovery from Claude Code
   - Test tool execution from Claude Code

3. **Example Workflows**
   - Create example automation scripts
   - Document common use cases
   - Create quickstart guide

**Deliverables:**
- Updated documentation
- Claude Code configuration guide
- Example workflows

**Estimated Time**: 2-3 hours

---

## Technical Specifications

### Named Pipe Configuration

```pascal
const
  PIPE_NAME = '\\.\pipe\CyberMAX_MCP_Request';
  PIPE_TIMEOUT_MS = 5000;  // 5 second timeout
  BUFFER_SIZE = 65536;      // 64KB buffer
```

**Pipe Properties:**
- Type: Duplex (bidirectional)
- Mode: Message mode with overlapped I/O
- Access: Local only (secure by default)
- Instances: Unlimited (multiple clients supported)

### JSON-RPC 2.0 Protocol

**Request Format:**
```json
{
  "jsonrpc": "2.0",
  "id": <number>,
  "method": "<tool-name>",
  "params": <object or null>
}
```

**Response Format (Success):**
```json
{
  "jsonrpc": "2.0",
  "id": <number>,
  "result": <any>
}
```

**Response Format (Error):**
```json
{
  "jsonrpc": "2.0",
  "id": <number>,
  "error": {
    "code": <number>,
    "message": <string>
  }
}
```

### Error Codes

| Code | Meaning | Cause |
|------|---------|-------|
| -32600 | Invalid Request | Malformed JSON or missing fields |
| -32601 | Method not found | Tool name not registered |
| -32602 | Invalid params | Parameter validation failed |
| -32603 | Internal error | Tool execution exception |
| -32000 | Server error | CyberMAX not running |

---

## Risk Assessment

### ✅ Low Risk

**Pipe Communication:**
- Proven pattern (VSCode-Switcher uses same approach)
- Well-tested Windows API
- Local-only (no network security concerns)

**Dynamic Discovery:**
- Implemented and appears functional
- Graceful fallback when CyberMAX not running
- No hardcoded dependencies

### ⚠️ Medium Risk

**Timeout Handling:**
- 5-second timeout may be too short for slow tools
- No configurable timeout per tool
- **Mitigation**: Make timeout configurable, add tool metadata for expected duration

**Error Propagation:**
- Nested error messages may be unclear
- Stack traces not preserved
- **Mitigation**: Enhanced error formatting, structured error objects

### ⚠️ Minor Risk

**Connection Management:**
- No connection pooling (creates new pipe per request)
- May be inefficient for high-frequency calls
- **Mitigation**: Optional connection pooling if performance issues found

**Tool Re-discovery:**
- Bridge must restart to discover new tools
- No hot-reload capability
- **Mitigation**: Add refresh endpoint or auto-detection

---

## Success Criteria

### ✅ Must Have

1. Bridge successfully discovers all CyberMAX tools
2. All discovered tools executable via HTTP MCP
3. Error messages clear and actionable
4. No crashes or memory leaks
5. Documentation complete and accurate

### ✅ Should Have

1. Response time < 100ms for simple tools
2. Graceful handling when CyberMAX stops/restarts
3. Comprehensive logging for debugging
4. Tool count displayed in startup banner

### ⭐ Nice to Have

1. Hot-reload when CyberMAX tools change
2. Connection pooling for performance
3. Metrics dashboard
4. Health check endpoint

---

## Testing Strategy

### Unit Tests

- Pipe client connection/disconnection
- JSON-RPC message serialization/deserialization
- Error handling for all error codes
- Tool registration edge cases

### Integration Tests

1. **CyberMAX Running**:
   - Start CyberMAX → Start Bridge → Verify tool discovery
   - Execute each tool category → Verify results
   - Stop CyberMAX → Verify error handling

2. **CyberMAX Not Running**:
   - Start Bridge without CyberMAX → Verify graceful degradation
   - Start CyberMAX after Bridge → Verify error messages

3. **Tool Execution**:
   - Execute all core tools (16+)
   - Execute module tools if available
   - Test with various parameter combinations
   - Test invalid parameters

### Performance Tests

- Latency: Execute 1000 simple tools, measure average response time
- Throughput: Concurrent tool executions, measure max throughput
- Memory: Monitor bridge memory usage over 1000 executions
- Stability: 24-hour stress test with random tool executions

### End-to-End Tests

1. **Claude Code Integration**:
   - Configure Claude Code with bridge URL
   - Verify tools appear in Claude Code
   - Execute tools from Claude Code conversation
   - Verify results displayed correctly

2. **Autonomous Workflows**:
   - Execute Internal → Screenshot → Close
   - List Internals → Filter → Execute
   - Complex multi-step operations

---

## Deployment Guide

### Prerequisites

1. **CyberMAX**:
   - Built in RELEASE configuration
   - MCP server enabled (conditional compilation)
   - Running and accessible

2. **Bridge**:
   - CyberMaxHelloMCP.exe compiled
   - Port 3001 available
   - No firewall blocking

3. **Claude Code**:
   - Installed and configured
   - WSL IP address known
   - MCP server config added

### Startup Sequence

```bash
# 1. Start CyberMAX (from Windows)
W:\CyberMAX.exe

# 2. Verify MCP server started
# Check debug output for "MCP server started"

# 3. Start Bridge (from WSL)
cd /mnt/w/MCPserver/Examples
./CyberMaxHelloMCP.exe

# 4. Verify tool discovery
# Should show "Registered X CyberMAX tools"

# 5. Configure Claude Code
# Add to ~/.claude/mcp_servers.json:
{
  "mcpServers": {
    "cybermax": {
      "type": "http",
      "url": "http://<WSL_IP>:3001/mcp"
    }
  }
}

# 6. Test from Claude Code
# Ask: "List all available CyberMAX tools"
```

### Troubleshooting

**Problem**: "Cannot connect to CyberMAX"
- ✓ Check CyberMAX is running
- ✓ Check RELEASE build (not DEBUG)
- ✓ Check debug output for pipe creation
- ✓ Verify pipe exists: `dir \\.\pipe\CyberMAX_MCP_Request`

**Problem**: "0 tools discovered"
- ✓ CyberMAX MCP server may not have started
- ✓ Check MenuControlPackage.dproj includes MCP units
- ✓ Check conditional compilation flags
- ✓ Check debug output for errors

**Problem**: "Connection refused" from Claude Code
- ✓ Bridge may not be running
- ✓ Wrong IP address in config
- ✓ Firewall blocking port 3001
- ✓ Get correct IP: `ip route | grep default | awk '{print $3}'`

---

## File Changes Required

### ✅ No Changes Needed (Already Implemented)

The following files already contain the complete implementation:

1. **MCPServer.CyberMAX.PipeClient.pas** - Pipe client (170 lines)
2. **MCPServer.CyberMAX.DynamicProxy.pas** - Dynamic proxy (214 lines)
3. **CyberMaxHelloMCP.dpr** - HTTP server integration (183 lines)

### 📝 Documentation Updates Only

1. **CYBERMAX-MCP-SETUP.md** - ✅ Already comprehensive (359 lines)
2. **CYBERMAX-DYNAMIC-PROXY.md** - ✅ Already detailed (696 lines)
3. **/mnt/w/MCPserver/CLAUDE.md** - Update with pipe architecture details
4. **/mnt/w/AUTO-TOOLING.md** - Already documents named pipe approach

### ⚠️ Optional Enhancements (Only if Issues Found)

If Phase 1 testing reveals issues:

1. **MCPServer.CyberMAX.PipeClient.pas**:
   - Add connection pooling
   - Configurable timeout
   - Enhanced error messages

2. **MCPServer.CyberMAX.DynamicProxy.pas**:
   - Hot-reload support
   - Tool metadata caching
   - Performance metrics

3. **CyberMaxHelloMCP.dpr**:
   - Health check endpoint
   - Metrics dashboard
   - Graceful reload command

---

## Next Steps

### Immediate Action (Recommended)

**Start with Phase 1: Verification & Testing**

1. Build both executables (CyberMAX + Bridge)
2. Test end-to-end communication
3. Document any issues found
4. Decide if Phase 2 enhancements are needed

### If Everything Works

**Skip to Phase 3: Documentation & Claude Code Integration**

1. Update documentation
2. Configure Claude Code
3. Create example workflows
4. **DONE** ✅

### If Issues Found

**Proceed with Phase 2: Enhancement**

1. Fix identified issues
2. Add missing features
3. Re-test
4. Then proceed to Phase 3

---

## Conclusion

The MCP server connection with CyberMAX **already has a solid implementation** using:

✅ Windows Named Pipes (proven, secure, local-only)
✅ JSON-RPC 2.0 protocol (standard, well-documented)
✅ Dynamic tool discovery (zero maintenance, unlimited scalability)
✅ Comprehensive error handling (graceful degradation)

**The implementation exists and appears architecturally sound.**

**Recommended Next Step**: Run Phase 1 verification tests to confirm everything works as designed, then proceed directly to Claude Code integration if no issues are found.

---

**Document Version**: 1.0
**Created**: 2025-10-05
**Status**: Ready for Review
**Estimated Total Time**: 8-15 hours (depending on issues found)
