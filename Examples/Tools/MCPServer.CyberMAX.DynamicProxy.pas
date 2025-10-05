unit MCPServer.CyberMAX.DynamicProxy;

{
  Dynamic MCP Tool Proxy for CyberMAX

  This module discovers all tools registered in CyberMAX's runtime registry
  and dynamically registers them with the HTTP MCP server. This eliminates
  the need for hardcoded tool implementations - tools are discovered at runtime.

  Architecture:
    1. Query CyberMAX 'list-tools' on startup
    2. Parse tool metadata (name, description, schema)
    3. Dynamically register each tool with HTTP MCP server
    4. Forward all tool calls to CyberMAX via named pipe
}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  MCPServer.Tool.Base,
  MCPServer.Types,
  MCPServer.Logger;

type
  /// <summary>
  /// Dynamic tool that forwards execution to CyberMAX
  /// </summary>
  TCyberMAXDynamicTool = class(TMCPToolBase<TJSONObject>, IMCPTool)
  private
    FCyberMAXToolName: string;
    FInputSchema: TJSONObject;  // Schema from CyberMAX (owned)
    // Custom implementations for IMCPTool interface
    function CustomGetInputSchema: TJSONObject;
    function CustomExecute(const Arguments: TJSONObject): string;
  protected
    function ExecuteWithParams(const Params: TJSONObject): string; override;
  public
    constructor Create(const AToolName, ADescription: string; ASchema: TJSONObject = nil); reintroduce;
    destructor Destroy; override;

    // Map interface methods to our custom implementations
    function IMCPTool.GetInputSchema = CustomGetInputSchema;
    function IMCPTool.Execute = CustomExecute;
  end;

/// <summary>
/// Discover and register all CyberMAX tools dynamically
/// </summary>
/// <returns>Number of tools registered</returns>
function RegisterAllCyberMAXTools: Integer;

/// <summary>
/// Get count of registered CyberMAX tools
/// </summary>
function GetCyberMAXToolCount: Integer;

implementation

uses
  System.StrUtils,
  MCPServer.Registration,
  MCPServer.CyberMAX.PipeClient;

var
  CyberMAXToolCount: Integer = 0;

{ TCyberMAXDynamicTool }

constructor TCyberMAXDynamicTool.Create(const AToolName, ADescription: string; ASchema: TJSONObject = nil);
begin
  inherited Create;
  FCyberMAXToolName := AToolName;
  FName := AToolName;
  FDescription := ADescription;
  FInputSchema := ASchema;  // Store schema (takes ownership if provided)

  if Assigned(FInputSchema) then
    OutputDebugString(PChar('[TOOL] Created ' + FName + ' WITH schema: ' + FInputSchema.ToJSON))
  else
    OutputDebugString(PChar('[TOOL] Created ' + FName + ' WITHOUT schema'));
end;

destructor TCyberMAXDynamicTool.Destroy;
begin
  // Free the schema if we own it
  if Assigned(FInputSchema) then
    FInputSchema.Free;
  inherited;
end;

function TCyberMAXDynamicTool.CustomGetInputSchema: TJSONObject;
begin
  // If we have a schema from CyberMAX, return a clone
  // (caller expects to own the returned object)
  if Assigned(FInputSchema) then
  begin
    Result := TJSONObject(FInputSchema.Clone);
    OutputDebugString(PChar('[MCP] CustomGetInputSchema CALLED for ' + FName + ' - Returning: ' + Result.ToJSON));
  end
  else
  begin
    OutputDebugString(PChar('[MCP] CustomGetInputSchema CALLED for ' + FName + ' - NO SCHEMA, using fallback'));
    // Fall back to parent's auto-generated schema (for TJSONObject)
    Result := inherited GetInputSchema;
    OutputDebugString(PChar('[MCP] Fallback schema: ' + Result.ToJSON));
  end;
end;

function TCyberMAXDynamicTool.CustomExecute(const Arguments: TJSONObject): string;
begin
  // Bypass TMCPSerializer.Deserialize<TJSONObject> which creates empty objects
  // We need to pass the Arguments directly to ExecuteWithParams
  OutputDebugString(PChar('[EXEC] CustomExecute CALLED for ' + FName + ' with Arguments: ' +
    IfThen(Assigned(Arguments), Arguments.ToJSON, 'NULL')));
  Result := ExecuteWithParams(Arguments);
end;

function TCyberMAXDynamicTool.ExecuteWithParams(const Params: TJSONObject): string;
var
  PipeResult: TCyberMAXPipeResult;
begin
  // Log tool execution
  if Assigned(Params) then
    OutputDebugString(PChar('[EXEC] ExecuteWithParams CALLED for ' + FName + ' with params: ' + Params.ToJSON))
  else
    OutputDebugString(PChar('[EXEC] ExecuteWithParams CALLED for ' + FName + ' with NULL params'));

  // Check if CyberMAX is running
  if not IsCyberMAXRunning then
  begin
    Result := 'Error: CyberMAX is not running or MCP server is not enabled. ' +
      'Please start CyberMAX (RELEASE build) and restart this MCP server.';
    OutputDebugString(PChar('[EXEC] CyberMAX not running'));
    Exit;
  end;

  // Forward to CyberMAX via pipe
  OutputDebugString(PChar('[EXEC] Forwarding to CyberMAX: ' + FCyberMAXToolName));
  PipeResult := ExecuteCyberMAXTool(FCyberMAXToolName, Params);
  try
    if not PipeResult.Success then
    begin
      Result := 'Error from CyberMAX: ' + PipeResult.ErrorMessage;
      Exit;
    end;

    // Return the result
    if Assigned(PipeResult.JSONResponse) then
    begin
      if PipeResult.JSONResponse is TJSONObject then
        Result := TJSONObject(PipeResult.JSONResponse).Format(2)
      else if PipeResult.JSONResponse is TJSONArray then
        Result := TJSONArray(PipeResult.JSONResponse).Format(2)
      else
        Result := PipeResult.JSONResponse.ToString;
    end
    else
      Result := 'Tool executed successfully (no data returned)';

  finally
    if Assigned(PipeResult.JSONResponse) then
      PipeResult.JSONResponse.Free;
  end;
end;

function RegisterAllCyberMAXTools: Integer;
var
  PipeResult: TCyberMAXPipeResult;
  ToolsObj: TJSONObject;
  ToolsArray: TJSONArray;
  I: Integer;
  ToolObj: TJSONObject;
  ToolName, ToolDescription, Category, Module: string;
  SchemaObj: TJSONObject;
  SchemaClone: TJSONObject;
begin
  Result := 0;
  CyberMAXToolCount := 0;

  OutputDebugString(PChar('[STARTUP] ========== REGISTERING CYBERMAX TOOLS =========='));
  TLogger.Info('Discovering CyberMAX tools...');

  // Check if CyberMAX is running
  if not IsCyberMAXRunning then
  begin
    TLogger.Warning('CyberMAX is not running - tools cannot be discovered');
    TLogger.Warning('Start CyberMAX.exe (RELEASE build) and restart this server');
    Exit;
  end;

  // Query list-tools from CyberMAX
  PipeResult := ExecuteCyberMAXTool('list-tools', nil);
  try
    if not PipeResult.Success then
    begin
      TLogger.Error('Failed to discover CyberMAX tools: ' + PipeResult.ErrorMessage);
      Exit;
    end;

    if not Assigned(PipeResult.JSONResponse) then
    begin
      TLogger.Error('No response from CyberMAX list-tools');
      Exit;
    end;

    if not (PipeResult.JSONResponse is TJSONObject) then
    begin
      TLogger.Error('Invalid response from CyberMAX list-tools (not a JSON object)');
      Exit;
    end;

    ToolsObj := TJSONObject(PipeResult.JSONResponse);

    // Get tools array
    if not ToolsObj.TryGetValue<TJSONArray>('tools', ToolsArray) then
    begin
      TLogger.Error('No tools array in CyberMAX list-tools response');
      Exit;
    end;

    TLogger.Info('Found ' + ToolsArray.Count.ToString + ' tools in CyberMAX registry');

    // Register each tool dynamically
    for I := 0 to ToolsArray.Count - 1 do
    begin
      if not (ToolsArray.Items[I] is TJSONObject) then
        Continue;

      ToolObj := TJSONObject(ToolsArray.Items[I]);

      // Extract tool metadata
      if not ToolObj.TryGetValue<string>('name', ToolName) then
        Continue;

      ToolDescription := ToolObj.GetValue<string>('description', 'CyberMAX tool');
      Category := ToolObj.GetValue<string>('category', 'general');
      Module := ToolObj.GetValue<string>('module', 'core');

      // Extract schema if present (clone it to preserve original)
      SchemaClone := nil;
      if ToolObj.TryGetValue<TJSONObject>('schema', SchemaObj) then
      begin
        if Assigned(SchemaObj) then
        begin
          SchemaClone := TJSONObject(SchemaObj.Clone);
          OutputDebugString(PChar('[BRIDGE] Extracted schema for ' + ToolName + ': ' + SchemaClone.ToJSON));
        end;
      end
      else
        OutputDebugString(PChar('[BRIDGE] NO SCHEMA found for ' + ToolName));

      // Register the tool dynamically
      // IMPORTANT: Factory must CLONE schema on each call since each instance takes ownership
      try
        TMCPRegistry.RegisterTool(ToolName,
          (function(const AName, ADesc: string; ASchema: TJSONObject): TMCPToolFactory
          begin
            Result := function: IMCPTool
            var
              SchemaForInstance: TJSONObject;
            begin
              // Clone schema for this instance (each tool instance needs its own copy)
              if Assigned(ASchema) then
                SchemaForInstance := TJSONObject(ASchema.Clone)
              else
                SchemaForInstance := nil;
              Result := TCyberMAXDynamicTool.Create(AName, ADesc, SchemaForInstance);
            end;
          end)(ToolName, ToolDescription, SchemaClone)  // Immediate invocation with current values
        );

        if Assigned(SchemaClone) then
        begin
          TLogger.Info('  Registered: ' + ToolName + ' (' + Category + ', ' + Module + ') [with schema]');
          OutputDebugString(PChar('[STARTUP] Registered tool: ' + ToolName + ' WITH SCHEMA'));
        end
        else
        begin
          TLogger.Info('  Registered: ' + ToolName + ' (' + Category + ', ' + Module + ')');
          OutputDebugString(PChar('[STARTUP] Registered tool: ' + ToolName + ' WITHOUT SCHEMA'));
        end;
        Inc(Result);

      except
        on E: Exception do
          TLogger.Error('Failed to register tool ' + ToolName + ': ' + E.Message);
      end;
    end;

    CyberMAXToolCount := Result;
    TLogger.Info('Successfully registered ' + Result.ToString + ' CyberMAX tools');
    OutputDebugString(PChar('[STARTUP] ========== REGISTRATION COMPLETE: ' + Result.ToString + ' tools =========='));

  finally
    if Assigned(PipeResult.JSONResponse) then
      PipeResult.JSONResponse.Free;
  end;
end;

function GetCyberMAXToolCount: Integer;
begin
  Result := CyberMAXToolCount;
end;

end.
