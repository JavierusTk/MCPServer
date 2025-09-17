# MCP Debug Server Enhancement Proposals

## Executive Summary

This document outlines proposed enhancements for the CyberMAX MCP debug capture server to improve its usability for Large Language Models (LLMs) and AI assistants. Based on practical experience using the debug capture tools, these recommendations aim to reduce complexity, improve state management, and provide more intelligent filtering and analysis capabilities.

## Current Limitations Encountered

### 1. Session Management Challenges
- **Issue**: Session IDs are GUIDs that must be manually tracked between calls
- **Impact**: LLMs lose context when reconnecting or switching conversations
- **Example**: `{85D3D258-D54A-4B61-9837-6B608F7849EB}` is hard to remember/manage

### 2. Access Conflicts
- **Issue**: Error messages like "Failed to create DBWIN_BUFFER_READY event (Error: 5)" are cryptic
- **Impact**: Difficult to diagnose whether it's permissions, another debugger, or system issue
- **User Experience**: Multiple trial-and-error attempts needed

### 3. Limited Filtering Capabilities
- **Issue**: Can only filter by single process or basic text matching
- **Impact**: Retrieving relevant messages from noisy systems requires multiple queries
- **Example**: Can't easily get "all ERROR messages from GAN.exe OR AsignadorDeCarpetas.exe"

### 4. No Real-time Monitoring
- **Issue**: Must poll repeatedly to get new messages
- **Impact**: Inefficient for monitoring ongoing processes
- **LLM Cost**: Multiple API calls for continuous monitoring

## Proposed Enhancements

### 1. Smart Session Management

#### 1.1 Named Sessions
```json
// Current (difficult)
{
  "tool": "start_debug_capture",
  "result": {"session_id": "{85D3D258-D54A-4B61-9837-6B608F7849EB}"}
}

// Proposed (easier)
{
  "tool": "start_debug_capture",
  "params": {
    "session_name": "gan_invoice_debug",
    "auto_recover": true
  },
  "result": {"session_name": "gan_invoice_debug", "session_id": "..."}
}
```

#### 1.2 Session Discovery
```json
{
  "tool": "list_debug_sessions",
  "result": [
    {
      "session_name": "gan_invoice_debug",
      "session_id": "{85D3D258...}",
      "status": "active",
      "started": "2025-09-16T18:18:46Z",
      "messages_captured": 1250,
      "processes_monitored": ["GAN.exe", "bds.exe"]
    }
  ]
}
```

#### 1.3 Auto-Recovery
- Store session metadata in a persistent location
- Allow reconnection to existing sessions by name
- Automatic session recovery after MCP server restart

### 2. Enhanced Filtering and Search

#### 2.1 Multi-Process Filtering
```json
{
  "tool": "get_debug_messages",
  "params": {
    "session_name": "gan_invoice_debug",
    "process_names": ["GAN.exe", "AsignadorDeCarpetas.exe", "ProcesaImagenesVallas.exe"],
    "exclude_processes": ["MicrosoftSecurityApp.exe"],
    "limit": 100
  }
}
```

#### 2.2 Severity Level Detection
```json
{
  "tool": "get_debug_messages",
  "params": {
    "session_name": "gan_invoice_debug",
    "severity_levels": ["ERROR", "WARNING"],
    "auto_detect_severity": true
  }
}
```

Auto-detection patterns:
- ERROR: Contains "error", "exception", "fail", "fatal"
- WARNING: Contains "warning", "warn", "caution"
- INFO: Contains "info", "information", "notice"
- DEBUG: Everything else or contains "debug", "trace"

#### 2.3 Advanced Pattern Matching
```json
{
  "tool": "get_debug_messages",
  "params": {
    "filters": {
      "and": [
        {"process": {"in": ["GAN.exe", "bds.exe"]}},
        {"message": {"regex": "\\[PARALLEL\\].*failed"}},
        {"timestamp": {"after": "2025-09-16T18:00:00Z"}}
      ]
    }
  }
}
```

### 3. Real-time Monitoring Capabilities

#### 3.1 Tail Mode
```json
{
  "tool": "tail_debug_messages",
  "params": {
    "session_name": "gan_invoice_debug",
    "follow": true,
    "lines": 20,
    "poll_interval_ms": 500
  }
}
```

#### 3.2 Watch Patterns
```json
{
  "tool": "watch_for_patterns",
  "params": {
    "session_name": "gan_invoice_debug",
    "patterns": [
      {"name": "errors", "regex": "ERROR|EXCEPTION|FAILED"},
      {"name": "parallel", "regex": "\\[PARALLEL\\]"},
      {"name": "timeout", "regex": "timeout|timed out"}
    ],
    "callback_on_match": true
  }
}
```

#### 3.3 Delta Queries
```json
{
  "tool": "get_new_messages",
  "params": {
    "session_name": "gan_invoice_debug",
    "since_last_query": true  // Automatically tracks last query timestamp
  }
}
```

### 4. Intelligent Analysis Tools

#### 4.1 Message Aggregation
```json
{
  "tool": "get_message_summary",
  "params": {
    "session_name": "gan_invoice_debug",
    "group_by": ["process_name", "severity"],
    "time_window": "last_10_minutes"
  },
  "result": {
    "summary": [
      {
        "process": "GAN.exe",
        "severity": "ERROR",
        "count": 15,
        "first_seen": "18:20:15",
        "last_seen": "18:29:45",
        "sample_message": "[ERROR] Failed to load invoice..."
      }
    ]
  }
}
```

#### 4.2 Burst Detection
```json
{
  "tool": "detect_message_bursts",
  "params": {
    "session_name": "gan_invoice_debug",
    "threshold": 10,  // messages per second
    "window": 5       // seconds
  },
  "result": {
    "bursts": [
      {
        "start": "18:25:10",
        "end": "18:25:13",
        "message_count": 47,
        "process": "GAN.exe",
        "dominant_pattern": "[PARALLEL] Job failed"
      }
    ]
  }
}
```

#### 4.3 Pattern Extraction
```json
{
  "tool": "extract_patterns",
  "params": {
    "session_name": "gan_invoice_debug",
    "sample_size": 1000
  },
  "result": {
    "patterns": [
      {
        "template": "[{LEVEL}] {COMPONENT}: {MESSAGE}",
        "frequency": 450,
        "example": "[ERROR] TParallelBatchProcessor: Job 123 failed"
      },
      {
        "template": "Thread {ID}: {ACTION}",
        "frequency": 230,
        "example": "Thread 4567: Starting analysis"
      }
    ]
  }
}
```

### 5. LLM-Optimized Features

#### 5.1 Contextual State Management
```json
{
  "tool": "set_debug_context",
  "params": {
    "context_id": "invoice_processing_debug",
    "default_filters": {
      "processes": ["GAN.exe"],
      "severity": ["ERROR", "WARNING"],
      "exclude_patterns": ["MicrosoftSecurityApp"]
    },
    "persist": true
  }
}

// Subsequent calls use context automatically
{
  "tool": "get_debug_messages",
  "params": {
    "use_context": "invoice_processing_debug"
  }
}
```

#### 5.2 Structured Output Parsing
```json
{
  "tool": "parse_structured_messages",
  "params": {
    "session_name": "gan_invoice_debug",
    "format_hints": ["json", "stack_trace", "csv"]
  },
  "result": {
    "structured_messages": [
      {
        "type": "json",
        "process": "GAN.exe",
        "timestamp": "18:25:10",
        "parsed": {
          "error": "timeout",
          "job_id": 123,
          "retry_count": 2
        }
      }
    ]
  }
}
```

#### 5.3 Intelligent Summaries
```json
{
  "tool": "get_debug_insights",
  "params": {
    "session_name": "gan_invoice_debug",
    "analyze_last": "5_minutes"
  },
  "result": {
    "insights": {
      "summary": "High error rate detected in parallel processing",
      "key_issues": [
        "15 timeout errors in TParallelBatchProcessor",
        "Memory usage spike at 18:25:10",
        "3 processes crashed and restarted"
      ],
      "recommendations": [
        "Increase timeout values",
        "Check system resources",
        "Review parallel job configuration"
      ],
      "anomalies": [
        "Unusual burst of 47 messages at 18:25:10-13"
      ]
    }
  }
}
```

### 6. Improved Error Handling and Diagnostics

#### 6.1 Pre-flight Checks
```json
{
  "tool": "check_debug_availability",
  "result": {
    "available": false,
    "reason": "Another debugger is active",
    "details": {
      "blocking_process": "DbgView.exe",
      "pid": 5678,
      "solution": "Close DbgView.exe or run with --force flag"
    }
  }
}
```

#### 6.2 Detailed Error Messages
```json
// Current
{
  "error": "Failed to create DBWIN_BUFFER_READY event (Error: 5)"
}

// Proposed
{
  "error": {
    "code": "DEBUG_CAPTURE_BLOCKED",
    "message": "Cannot start debug capture",
    "reason": "Access denied - another debugger is active",
    "details": {
      "system_error": 5,
      "system_error_text": "ERROR_ACCESS_DENIED",
      "likely_cause": "DbgView.exe or IDE debugger is running"
    },
    "solutions": [
      "Close any running debuggers (DbgView, Visual Studio, Delphi IDE)",
      "Run MCP server as Administrator",
      "Use process-specific capture mode instead of global"
    ]
  }
}
```

#### 6.3 Fallback Modes
```json
{
  "tool": "start_debug_capture",
  "params": {
    "fallback_strategy": "process_specific",
    "target_processes": ["GAN.exe", "AsignadorDeCarpetas.exe"]
  }
}
```

## Implementation Priority

### Phase 1 - Core Improvements (High Priority)
1. **Named sessions** - Critical for LLM usability
2. **Session discovery** - Essential for reconnection
3. **Multi-process filtering** - Major efficiency gain
4. **Better error messages** - Improves debugging experience

### Phase 2 - Enhanced Functionality (Medium Priority)
1. **Delta queries** - Reduces API calls
2. **Message aggregation** - Simplifies analysis
3. **Severity detection** - Better filtering
4. **Pre-flight checks** - Prevents failed attempts

### Phase 3 - Advanced Features (Lower Priority)
1. **Pattern extraction** - Advanced analysis
2. **Burst detection** - Performance monitoring
3. **Structured parsing** - Data extraction
4. **Intelligent summaries** - AI-powered insights

## Benefits for LLM Integration

### Reduced Complexity
- Named sessions eliminate GUID management
- Context preservation reduces parameter repetition
- Smart defaults minimize required parameters

### Improved Efficiency
- Delta queries reduce redundant data transfer
- Aggregation provides quick overviews
- Filtering reduces noise in responses

### Better Error Recovery
- Clear error messages enable self-correction
- Fallback modes ensure functionality
- Pre-flight checks prevent wasted attempts

### Enhanced Analysis
- Pattern detection identifies issues automatically
- Severity classification prioritizes important messages
- Burst detection highlights anomalies

## Example Usage Comparison

### Current Workflow (Complex)
```javascript
// Step 1: Try to start capture (might fail)
start_debug_capture() // Error: Access denied

// Step 2: Try again after closing debuggers
start_debug_capture() // Returns: {session_id: "{GUID}"}

// Step 3: Remember GUID, poll for messages
get_debug_messages({session_id: "{GUID}", limit: 100})

// Step 4: Filter manually in LLM
// ... process messages to find errors ...

// Step 5: Poll again for new messages
get_debug_messages({session_id: "{GUID}", limit: 100, since: "timestamp"})
```

### Proposed Workflow (Simple)
```javascript
// Step 1: Check availability and start
check_debug_availability() // Tells us exactly what to do
start_debug_capture({session_name: "debug"}) // Works or provides clear guidance

// Step 2: Get relevant messages with smart filtering
get_debug_insights({session_name: "debug", severity: ["ERROR", "WARNING"]})

// Step 3: Monitor for new issues
watch_for_patterns({session_name: "debug", patterns: ["ERROR", "TIMEOUT"]})
```

## Conclusion

These enhancements would transform the MCP debug server from a basic capture tool into an intelligent debugging assistant. The improvements focus on:

1. **Simplifying state management** for LLMs
2. **Providing intelligent filtering** to reduce noise
3. **Enabling real-time monitoring** efficiently
4. **Offering clear error guidance** for self-correction
5. **Supporting advanced analysis** for complex debugging

Implementation of these features would significantly improve the debugging experience for both LLMs and human developers, making the tool more powerful while reducing complexity.

---
*Document created: September 16, 2025*
*Author: Claude (Anthropic)*
*Context: GAN Module - ganProveedoresFacturaRapida debugging session*