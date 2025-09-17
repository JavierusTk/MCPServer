# Implementation Document: Windows OutputDebugString MCP Server

## Overview
Create an MCP server that captures Windows OutputDebugString messages and exposes them to LLMs for real-time monitoring, analysis, and troubleshooting. This server will act as a programmatic replacement for tools like DebugView, allowing AI assistants to analyze debug output from Windows applications.

## Core Functionality Requirements

### Windows OutputDebugString Capture Mechanism
The server must implement the standard Windows debug output capture using:
- **Shared Memory**: `DBWIN_BUFFER` (4096 bytes total)
- **Synchronization Events**: 
  - `DBWIN_BUFFER_READY`: Signals buffer is ready for new data
  - `DBWIN_DATA_READY`: Signals new data is available
- **Mutex**: `DBWIN_BUFFER_MUTEX` for thread-safe access

### Data Structure
```pascal
type
  TDebugMessage = record
    ProcessId: DWORD;
    ProcessName: string;  // Resolved from PID
    Timestamp: TDateTime;
    Message: string;
    ThreadId: DWORD;      // If available
  end;
```

## MCP Server Tools to Implement

### 1. `start_debug_capture`
**Purpose**: Begin capturing OutputDebugString messages
**Parameters**:
```json
{
  "buffer_size": 10000,           // Max messages to keep in memory
  "auto_resolve_process_names": true,  // Resolve PIDs to process names
  "filter_current_process": false      // Include messages from server itself
}
```
**Returns**:
```json
{
  "success": true,
  "session_id": "uuid-string",
  "status": "capturing"
}
```

### 2. `stop_debug_capture`
**Purpose**: Stop capturing debug messages
**Parameters**:
```json
{
  "session_id": "uuid-string"
}
```
**Returns**:
```json
{
  "success": true,
  "messages_captured": 1523,
  "duration_seconds": 45.7
}
```

### 3. `get_debug_messages`
**Purpose**: Retrieve captured debug messages with filtering
**Parameters**:
```json
{
  "session_id": "uuid-string",
  "limit": 100,                    // Max messages to return
  "offset": 0,                     // Pagination offset
  "since_timestamp": "2025-01-15T10:30:00Z",  // Optional
  "process_id": 1234,              // Optional filter
  "process_name": "myapp.exe",     // Optional filter
  "message_contains": "error",     // Optional text filter
  "message_regex": "\\d{4}-\\d{2}-\\d{2}"  // Optional regex filter
}
```
**Returns**:
```json
{
  "messages": [
    {
      "process_id": 1234,
      "process_name": "myapp.exe",
      "timestamp": "2025-01-15T10:30:15.123Z",
      "message": "Error: Connection failed",
      "thread_id": 5678
    }
  ],
  "total_count": 1523,
  "filtered_count": 15
}
```

### 4. `get_process_summary`
**Purpose**: Get statistics about processes generating debug output
**Parameters**:
```json
{
  "session_id": "uuid-string",
  "time_window_minutes": 60        // Optional, defaults to all time
}
```
**Returns**:
```json
{
  "processes": [
    {
      "process_id": 1234,
      "process_name": "myapp.exe",
      "message_count": 456,
      "first_seen": "2025-01-15T10:00:00Z",
      "last_seen": "2025-01-15T10:30:00Z",
      "avg_messages_per_minute": 7.6
    }
  ]
}
```

### 5. `search_messages`
**Purpose**: Advanced search through captured messages
**Parameters**:
```json
{
  "session_id": "uuid-string",
  "query": "exception OR error",   // Search query
  "case_sensitive": false,
  "search_type": "text",          // "text", "regex", or "fuzzy"
  "max_results": 50,
  "group_by": "process_name"      // Optional grouping
}
```
**Returns**:
```json
{
  "results": [
    {
      "process_name": "myapp.exe",
      "matches": [
        {
          "message": "Exception in thread main",
          "timestamp": "2025-01-15T10:30:15Z",
          "process_id": 1234,
          "match_positions": [0, 9]  // Highlight positions
        }
      ]
    }
  ],
  "total_matches": 23
}
```

### 6. `export_messages`
**Purpose**: Export captured messages to file
**Parameters**:
```json
{
  "session_id": "uuid-string",
  "format": "csv",                // "csv", "json", "txt"
  "filename": "debug_log.csv",
  "filters": {
    "process_name": "myapp.exe",
    "since_timestamp": "2025-01-15T10:00:00Z"
  }
}
```
**Returns**:
```json
{
  "success": true,
  "file_path": "C:\\temp\\debug_log.csv",
  "record_count": 456,
  "file_size_bytes": 98304
}
```

### 7. `get_capture_status`
**Purpose**: Get current capture session information
**Parameters**:
```json
{
  "session_id": "uuid-string"
}
```
**Returns**:
```json
{
  "status": "capturing",          // "capturing", "stopped", "error"
  "start_time": "2025-01-15T10:00:00Z",
  "messages_captured": 1523,
  "buffer_usage_percent": 67.3,
  "capture_rate_per_second": 2.1,
  "active_processes": ["myapp.exe", "service.exe"]
}
```

### 8. `pause_capture` / `resume_capture`
**Purpose**: Temporarily pause/resume capture without losing session
**Parameters**:
```json
{
  "session_id": "uuid-string"
}
```

## Implementation Details

### Core Capture Implementation (Delphi)
```pascal
type
  TOutputDebugStringCapture = class
  private
    FMutex: THandle;
    FBufferReadyEvent: THandle;
    FDataReadyEvent: THandle;
    FSharedBuffer: Pointer;
    FCaptureThread: TThread;
    FMessages: TList<TDebugMessage>;
    FOnMessageReceived: TNotifyEvent;
    FMaxBufferSize: Integer;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    function StartCapture: Boolean;
    procedure StopCapture;
    function IsCapturing: Boolean;
    
    procedure GetMessages(const AFilter: TMessageFilter; 
                         out Messages: TArray<TDebugMessage>);
    procedure ClearMessages;
    
    property OnMessageReceived: TNotifyEvent read FOnMessageReceived 
                                             write FOnMessageReceived;
    property MaxBufferSize: Integer read FMaxBufferSize write FMaxBufferSize;
  end;
```

### Key Implementation Steps

1. **Initialize Shared Resources**:
   ```pascal
   FMutex := CreateMutex(nil, False, 'DBWIN_BUFFER_MUTEX');
   FBufferReadyEvent := CreateEvent(nil, False, True, 'DBWIN_BUFFER_READY');
   FDataReadyEvent := CreateEvent(nil, False, False, 'DBWIN_DATA_READY');
   FSharedBuffer := CreateFileMapping(INVALID_HANDLE_VALUE, nil, 
                                     PAGE_READWRITE, 0, 4096, 'DBWIN_BUFFER');
   ```

2. **Capture Loop** (in separate thread):
   ```pascal
   while not Terminated do
   begin
     WaitForSingleObject(FDataReadyEvent, INFINITE);
     WaitForSingleObject(FMutex, INFINITE);
     try
       // Read from shared buffer
       ProcessId := PDWord(FSharedBuffer)^;
       Message := PAnsiChar(PByte(FSharedBuffer) + SizeOf(DWORD));
       // Store message with timestamp
     finally
       SetEvent(FBufferReadyEvent);
       ReleaseMutex(FMutex);
     end;
   end;
   ```

3. **Process Name Resolution**:
   ```pascal
   function GetProcessName(ProcessId: DWORD): string;
   var
     Handle: THandle;
     ModuleName: array[0..MAX_PATH] of Char;
   begin
     Handle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, 
                          False, ProcessId);
     try
       if GetModuleFileNameEx(Handle, 0, ModuleName, Length(ModuleName)) > 0 then
         Result := ExtractFileName(ModuleName)
       else
         Result := Format('PID_%d', [ProcessId]);
     finally
       CloseHandle(Handle);
     end;
   end;
   ```

## Threading and Performance Considerations

- **Capture Thread**: Dedicated thread for message capture to avoid blocking MCP responses
- **Message Buffer**: Circular buffer with configurable size to prevent memory issues
- **Batch Processing**: Group messages for bulk processing to improve performance
- **Process Name Caching**: Cache process names to avoid repeated system calls

## Error Handling

- **Capture Initialization Failures**: Return appropriate error codes and messages
- **Process Access Denied**: Handle cases where process names can't be resolved
- **Buffer Overflow**: Implement circular buffer or message dropping strategies
- **System Resource Limitations**: Graceful degradation when system limits are reached

## Security Considerations

- **Administrator Privileges**: May require elevated privileges to capture from all processes
- **Process Filtering**: Allow filtering to capture only from specific processes
- **Data Sanitization**: Ensure captured messages don't contain sensitive data before exposing to LLM

## Testing Requirements

1. **Unit Tests**: Test message filtering, process name resolution, buffer management
2. **Integration Tests**: Test with actual applications generating OutputDebugString calls
3. **Performance Tests**: Verify performance with high-volume debug output
4. **Error Scenarios**: Test behavior when capture resources are unavailable

This implementation will provide LLMs with powerful capabilities to monitor, analyze, and troubleshoot Windows applications through their debug output in real-time.