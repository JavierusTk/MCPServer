# CyberMAX MCP Server Setup Guide

## Overview

This guide shows how to configure Claude Code to control CyberMAX autonomously via the Model Context Protocol (MCP).

## Architecture

```
┌──────────────────┐
│   Claude Code    │  AI Assistant
│    (claude.ai)   │
└────────┬─────────┘
         │ MCP over HTTP
         ▼
┌──────────────────┐
│CyberMaxHelloMCP  │  MCP Server (port 3001)
│     (.exe)       │
└────────┬─────────┘
         │ Named Pipe: \\.\pipe\CyberMAX_MCP_Request
         ▼
┌──────────────────┐
│  CyberMAX.exe    │  ERP System with MCP Server Thread
│  (RELEASE build) │
└──────────────────┘
```

## Prerequisites

1. **CyberMAX** built in RELEASE configuration (MCP server is only enabled in RELEASE builds)
2. **CyberMaxHelloMCP.exe** compiled from `/mnt/w/MCPServer/Examples/`
3. **Claude Code** installed and configured

## Step 1: Start CyberMAX

CyberMAX must be running with the MCP server enabled:

```bash
# Make sure CyberMAX is compiled in RELEASE mode
cd /mnt/w
./CyberMAX.exe
```

**Verify MCP Server is Running:**
- The named pipe `\\.\pipe\CyberMAX_MCP_Request` should be accessible
- Check debug output for "MCP server started" message

## Step 2: Start CyberMaxHelloMCP Server

The MCP server acts as a bridge between Claude Code and CyberMAX:

```bash
cd /mnt/w/MCPServer/Examples
./CyberMaxHelloMCP.exe
```

**Expected Output:**
```
========================================
 CyberMAX MCP Server - Hello World v1.0
========================================
Model Context Protocol Server for CyberMAX ERP

Server started successfully!

Available tools:
  Basic Tools:
    - hello_cybermax        : Get greeting and CyberMAX info
    - cyber_echo           : Echo back your message
    - cyber_time           : Get current system time

  Debug Capture Tools:
    - start_debug_capture  : Start capturing OutputDebugString
    ...

  CyberMAX Control Tools (requires running CyberMAX):
    Visual Inspection:
      - cybermax_take_screenshot      : Capture screenshots
      - cybermax_get_form_info        : Get form structure
      - cybermax_list_open_forms      : List all open forms
    Control Interaction:
      - cybermax_set_control_value    : Set values in controls
      - cybermax_click_button         : Click buttons
      - cybermax_select_combo_item    : Select ComboBox items
      - cybermax_select_tab           : Switch tabs
      - cybermax_close_form           : Close forms
      - cybermax_set_focus            : Set control focus
    Discovery & Execution:
      - cybermax_list_internals       : List all registered Internals
      - cybermax_execute_internal     : Execute forms/reports/operations
      - cybermax_get_application_state: Get current app state
    Command Processor:
      - cybermax_execute_command      : Execute Command Processor commands
      - cybermax_list_commands        : List available commands
      - cybermax_get_execution_state  : Check execution status

Press CTRL+C to stop...
========================================
```

The server is now listening on **port 3001**.

## Step 3: Configure Claude Code

### Get Your WSL IP Address

From WSL terminal:

```bash
ip route | grep default | awk '{print $3}'
```

Example output: `172.24.48.1`

### Add MCP Server to Claude Code

Open Claude Code settings and add the MCP server configuration:

**~/.claude/mcp_servers.json** (or use Claude Code UI):

```json
{
  "mcpServers": {
    "cybermax": {
      "type": "http",
      "url": "http://172.24.48.1:3001/mcp",
      "description": "CyberMAX ERP Automation"
    }
  }
}
```

**Replace `172.24.48.1` with your actual WSL IP address.**

## Step 4: Verify Connection

In Claude Code, the tools should appear as:

- `mcp__cybermax__take-screenshot`
- `mcp__cybermax__execute-internal`
- `mcp__cybermax__list-internals`
- `mcp__cybermax__list-tools`
- etc.

**Note:** The exact list of tools depends on which CyberMAX modules are loaded. The bridge **dynamically discovers** all tools registered in CyberMAX's runtime registry.

### Test the Connection

Ask Claude Code:

> "Use the list-tools tool to show me all available CyberMAX operations"

Claude should be able to call the tool and display all registered tools from CyberMAX.

## Available Tools (Dynamic Discovery)

The bridge uses **dynamic tool discovery** - all tools are automatically discovered from CyberMAX's runtime registry. The exact tools available depend on which modules are loaded.

### Core Tools (Always Available)

**Visual Inspection:**
- `take-screenshot` - Capture screenshots of screen/forms/controls
- `get-form-info` - Get form structure via RTTI introspection
- `list-open-forms` - List all open forms

**Control Interaction:**
- `set-control-value` - Set values in controls
- `click-button` - Click buttons
- `select-combo-item` - Select ComboBox items
- `select-tab` - Switch tabs
- `close-form` - Close forms
- `set-focus` - Set control focus

**Discovery & Execution:**
- `list-internals` - List all registered Internals (413+)
- `execute-internal` - Execute forms/reports/operations
- `get-application-state` - Get current app state
- `list-tools` - List all available MCP tools

**Command Processor:**
- `execute-command` - Execute Command Processor commands (100+ available)
- `list-commands` - List available commands

**State Management:**
- `get-execution-state` - Check execution status (busy/idle)

### Module Tools (Dynamically Added)

When modules are loaded, they can register additional tools:

**TCConta Module:**
- `get-conta-balance` - Get account balances
- `close-accounting-period` - Close accounting periods
- etc.

**Almacen Module:**
- `check-stock-level` - Check inventory levels
- `get-stock-movements` - Get movement history
- etc.

**Produccion Module:**
- `get-production-status` - Get production order status
- `check-material-availability` - Check materials
- etc.

**To see all available tools:**
Use the `list-tools` tool to get the complete, current list of all registered tools from the running CyberMAX instance.

## Example Autonomous Workflows

### 1. Execute Internal and Inspect Form

```
Claude: Use execute-internal with code="SYSTEM.AYUDA.ACERCADE"
Claude: Use get-form-info with form="active"
Claude: Use take-screenshot with target="active", output="C:\Temp\about.png"
Claude: Use execute-command with command="SALIR"
```

### 2. List and Filter Data

```
Claude: Use execute-internal with code="CLIENTES"
Claude: Use list-commands (to see available commands)
Claude: Use execute-command with command="FILTRO.FORMULA|Activo=1"
Claude: Use execute-command with command="FILTRO.APLICAR"
Claude: Use take-screenshot with target="active"
```

### 3. Navigate and Export

```
Claude: Use execute-command with command="MENU|Reports|Sales Report"
Claude: Use execute-command with command="RANGOFECHAS.PERIODO|ESTEMES"
Claude: Use execute-command with command="EXPORTAR.EXCEL|C:\Reports\sales.xlsx"
```

### 4. Discover Available Tools

```
Claude: Use list-tools
  → Returns all tools with descriptions, categories, and modules
  → Shows which modules have registered tools
  → Provides complete tool inventory
```

## Troubleshooting

### "Cannot connect to CyberMAX" Error

**Causes:**
1. CyberMAX is not running
2. CyberMAX built in DEBUG mode (MCP server disabled)
3. Named pipe not accessible

**Solutions:**
- Ensure CyberMAX is running
- Rebuild CyberMAX in RELEASE configuration
- Check `/mnt/w/CyberDebug.txt` for MCP server startup messages

### "Connection refused" from Claude Code

**Causes:**
1. CyberMaxHelloMCP.exe is not running
2. Wrong IP address in configuration
3. Firewall blocking port 3001

**Solutions:**
- Verify CyberMaxHelloMCP.exe is running and shows "Server started successfully!"
- Double-check WSL IP address: `ip route | grep default | awk '{print $3}'`
- Check Windows Firewall settings for port 3001

### Tools Not Appearing in Claude Code

**Causes:**
1. MCP server configuration incorrect
2. Claude Code not restarted after config change

**Solutions:**
- Verify `mcp_servers.json` syntax
- Restart Claude Code
- Check Claude Code logs for connection errors

## Advanced Usage

### Command Processor Commands

The `cybermax_execute_command` tool supports 100+ commands:

- **Menu Navigation**: `MENU|File|Open`, `MENU|Reports|*Sales|Monthly`
- **Filters**: `FILTRO.FORMULA|expression`, `FILTRO.APLICAR`, `FILTRO.QUITAR`
- **Date Ranges**: `RANGOFECHAS.PERIODO|ESTEMES`, `RANGOFECHAS.DESDE|01/01/2024`
- **Export**: `EXPORTAR.SQL|query`, `EXPORTAR.EXCEL|file.xlsx`
- **SQL**: `EJECUTAR.SQL|UPDATE table SET field=value`
- **Email**: `EMAIL.COMENZAR`, `EMAIL.ASUNTO|subject`, `EMAIL.ENVIAR`
- **Loops**: `REPETIR.SQL|query`, `REPETIR.INICIO`, `REPETIR.FIN`
- **Variables**: `VARIABLE|NAME=value`
- **Form Control**: `OK`, `CANCEL`, `SALIR`

See `_DEVDOCS/COMMAND-PROCESSOR-SYSTEM.md` for complete command reference.

### Screenshot Targets

The `take-screenshot` tool supports multiple capture modes:

- `screen` or `full` - Full desktop
- `active` or `focus` - Active form window
- `FormName` - Specific form by name
- `wincontrol` - Focused control (exact bounds)
- `wincontrol+20` - Focused control with 20px margin
- `wincontrol.parent` - Parent of focused control
- `wincontrol.parent.parent+40` - Grandparent with margin

## Architecture Details

### Named Pipe Communication

- **Pipe Name**: `\\.\pipe\CyberMAX_MCP_Request`
- **Protocol**: JSON-RPC 2.0
- **Timeout**: 5 seconds
- **Thread Safety**: All VCL access via `TThread.Synchronize`

### Non-Blocking Execution

- `execute-internal` queues operations via command processor
- Forms execute during `Application.OnIdle`
- Modal dialogs don't block MCP server
- Use `get-execution-state` to check status

### Dynamic Tool Discovery

- Bridge queries CyberMAX `list-tools` on startup
- All registered tools are automatically exposed via HTTP MCP
- Module tools appear automatically when modules are loaded
- No bridge code changes needed when adding new tools

### Error Handling

All tools return structured responses:
- Success: Operation result with data
- Failure: Error message from CyberMAX or connection issues

## Related Documentation

- **Dynamic Proxy Architecture**: `CYBERMAX-DYNAMIC-PROXY.md` - **READ THIS** to understand the dynamic discovery system
- **CyberMAX MCP Implementation**: `/mnt/w/AUTO-TOOLING.md`
- **Development Roadmap**: `/mnt/w/_DEVDOCS/MCP-DEVELOPMENT-ROADMAP.md`
- **Command Processor System**: `/mnt/w/_DEVDOCS/COMMAND-PROCESSOR-SYSTEM.md`
- **CyberMAX Architecture**: `/mnt/w/CLAUDE.md`
- **Internals System**: `/mnt/w/CyberMAX-Internals.md`
- **Tool Registry Architecture**: `/mnt/w/_DEVDOCS/MCP-REGISTRY-ARCHITECTURE.md`
- **Module Registration Example**: `/mnt/w/_DEVDOCS/MCP-MODULE-REGISTRATION-EXAMPLE.md`

---

**Version**: 1.0
**Last Updated**: 2025-01-04
**Status**: Production Ready
