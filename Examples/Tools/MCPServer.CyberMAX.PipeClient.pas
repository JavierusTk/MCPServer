unit MCPServer.CyberMAX.PipeClient;

{
  Shared named pipe client for communicating with CyberMAX MCP Server.

  This module provides reusable functions for all CyberMAX MCP tools to
  communicate with the running CyberMAX process via named pipes.
}

interface

uses
  System.SysUtils,
  System.JSON,
  Winapi.Windows;

type
  /// <summary>
  /// Result of a pipe client operation
  /// </summary>
  TCyberMAXPipeResult = record
    Success: Boolean;
    ErrorMessage: string;
    JSONResponse: TJSONValue;
    constructor Create(ASuccess: Boolean; const AErrorMessage: string; AJSONResponse: TJSONValue);
  end;

/// <summary>
/// Execute a tool on CyberMAX via named pipe
/// </summary>
/// <param name="ToolName">Name of the CyberMAX tool to execute</param>
/// <param name="Params">Parameters as JSON object (can be nil)</param>
/// <returns>Pipe result with success status and response</returns>
function ExecuteCyberMAXTool(const ToolName: string; Params: TJSONObject): TCyberMAXPipeResult;

/// <summary>
/// Check if CyberMAX is running and accessible via pipe
/// </summary>
function IsCyberMAXRunning: Boolean;

const
  PIPE_NAME = '\\.\pipe\CyberMAX_MCP_Request';
  PIPE_TIMEOUT_MS = 5000;

implementation

var
  RequestIDCounter: Integer = 1;

{ TCyberMAXPipeResult }

constructor TCyberMAXPipeResult.Create(ASuccess: Boolean;
  const AErrorMessage: string; AJSONResponse: TJSONValue);
begin
  Success := ASuccess;
  ErrorMessage := AErrorMessage;
  JSONResponse := AJSONResponse;
end;

function ConnectToPipe: THandle;
var
  StartTime: DWORD;
begin
  StartTime := GetTickCount;

  // Try to connect with timeout
  while True do
  begin
    Result := CreateFile(
      PChar(PIPE_NAME),
      GENERIC_READ or GENERIC_WRITE,
      0,
      nil,
      OPEN_EXISTING,
      0,
      0
    );

    if Result <> INVALID_HANDLE_VALUE then
      Exit; // Connected successfully

    // Check if pipe is busy and wait
    if GetLastError = ERROR_PIPE_BUSY then
    begin
      if GetTickCount - StartTime > PIPE_TIMEOUT_MS then
        Exit; // Timeout

      if not WaitNamedPipe(PChar(PIPE_NAME), 1000) then
        Sleep(100);
    end
    else
      Exit; // Other error - give up
  end;
end;

function ExecuteCyberMAXTool(const ToolName: string; Params: TJSONObject): TCyberMAXPipeResult;
var
  PipeHandle: THandle;
  Request: AnsiString;
  Response: AnsiString;
  Buffer: array[0..65535] of AnsiChar;
  BytesWritten: DWORD;
  BytesRead: DWORD;
  JSONRequest: TJSONObject;
  JSONResponse: TJSONValue;
  ResultValue: TJSONValue;
  ErrorValue: TJSONValue;
begin
  // Default failure result
  Result := TCyberMAXPipeResult.Create(False, 'Unknown error', nil);

  // Connect to pipe
  PipeHandle := ConnectToPipe;
  if PipeHandle = INVALID_HANDLE_VALUE then
  begin
    Result.ErrorMessage := 'Cannot connect to CyberMAX. Make sure CyberMAX is running with MCP server enabled.';
    Exit;
  end;

  try
    // Build JSON-RPC request
    JSONRequest := TJSONObject.Create;
    try
      JSONRequest.AddPair('jsonrpc', '2.0');
      JSONRequest.AddPair('id', TJSONNumber.Create(AtomicIncrement(RequestIDCounter)));
      JSONRequest.AddPair('method', ToolName);

      if Assigned(Params) then
        JSONRequest.AddPair('params', TJSONObject(Params.Clone))
      else
        JSONRequest.AddPair('params', TJSONObject.Create);

      Request := AnsiString(JSONRequest.ToString);
    finally
      JSONRequest.Free;
    end;

    // Send request
    if not WriteFile(PipeHandle, Request[1], Length(Request), BytesWritten, nil) then
    begin
      Result.ErrorMessage := 'Failed to send request to CyberMAX (Error: ' + IntToStr(GetLastError) + ')';
      Exit;
    end;

    FlushFileBuffers(PipeHandle);

    // Read response
    FillChar(Buffer, SizeOf(Buffer), 0);
    if not ReadFile(PipeHandle, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) then
    begin
      Result.ErrorMessage := 'Failed to read response from CyberMAX (Error: ' + IntToStr(GetLastError) + ')';
      Exit;
    end;

    SetString(Response, PAnsiChar(@Buffer[0]), BytesRead);

    // Parse response
    JSONResponse := nil;
    try
      JSONResponse := TJSONObject.ParseJSONValue(string(Response));
      if not Assigned(JSONResponse) then
      begin
        Result.ErrorMessage := 'Invalid JSON response from CyberMAX';
        Exit;
      end;

      if not (JSONResponse is TJSONObject) then
      begin
        Result.ErrorMessage := 'Response is not a JSON object';
        JSONResponse.Free;
        Exit;
      end;

      // Check for error in response
      ErrorValue := TJSONObject(JSONResponse).GetValue('error');
      if Assigned(ErrorValue) then
      begin
        if ErrorValue is TJSONObject then
          Result.ErrorMessage := TJSONObject(ErrorValue).GetValue<string>('message', 'Unknown error from CyberMAX')
        else
          Result.ErrorMessage := 'Error from CyberMAX: ' + ErrorValue.ToString;
        JSONResponse.Free;
        Exit;
      end;

      // Get result value
      ResultValue := TJSONObject(JSONResponse).GetValue('result');
      if not Assigned(ResultValue) then
      begin
        Result.ErrorMessage := 'No result in response from CyberMAX';
        JSONResponse.Free;
        Exit;
      end;

      // Success - return the result
      Result.Success := True;
      Result.ErrorMessage := '';
      Result.JSONResponse := ResultValue.Clone as TJSONValue;

    finally
      if Assigned(JSONResponse) then
        JSONResponse.Free;
    end;

  finally
    CloseHandle(PipeHandle);
  end;
end;

function IsCyberMAXRunning: Boolean;
var
  PipeHandle: THandle;
begin
  PipeHandle := CreateFile(
    PChar(PIPE_NAME),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    0,
    0
  );

  Result := PipeHandle <> INVALID_HANDLE_VALUE;

  if Result then
    CloseHandle(PipeHandle);
end;

end.
