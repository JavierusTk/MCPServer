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
  TCyberMAXDynamicTool = class(TMCPToolBase<TJSONObject>)
  private
    FCyberMAXToolName: string;
    FInputSchema: TJSONObject;  // Schema from CyberMAX (owned)
  protected
    function ExecuteWithParams(const Params: TJSONObject): string; override;
  public
    constructor Create(const AToolName, ADescription: string; ASchema: TJSONObject = nil); reintroduce;
    destructor Destroy; override;
    function GetInputSchema: TJSONObject; reintroduce;
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
  TLogger.Info('TCyberMAXDynamicTool.Create: Name="' + FName + '", CyberMAXName="' + FCyberMAXToolName + '", HasSchema=' + BoolToStr(Assigned(FInputSchema), True));
end;

destructor TCyberMAXDynamicTool.Destroy;
begin
  // Free the schema if we own it
  if Assigned(FInputSchema) then
    FInputSchema.Free;
  inherited;
end;

function TCyberMAXDynamicTool.GetInputSchema: TJSONObject;
begin
  // If we have a schema from CyberMAX, return a clone
  // (caller expects to own the returned object)
  if Assigned(FInputSchema) then
    Result := TJSONObject(FInputSchema.Clone)
  else
    // Fall back to parent's auto-generated schema (for TJSONObject)
    Result := inherited GetInputSchema;
end;

function TCyberMAXDynamicTool.ExecuteWithParams(const Params: TJSONObject): string;
var
  PipeResult: TCyberMAXPipeResult;
begin
  // Check if CyberMAX is running
  if not IsCyberMAXRunning then
  begin
    Result := 'Error: CyberMAX is not running or MCP server is not enabled. ' +
      'Please start CyberMAX (RELEASE build) and restart this MCP server.';
    Exit;
  end;

  // Forward to CyberMAX via pipe
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
          SchemaClone := TJSONObject(SchemaObj.Clone);
      end;

      // Register the tool dynamically
      // IMPORTANT: Use intermediate function to properly capture by value
      try
        TMCPRegistry.RegisterTool(ToolName,
          (function(const AName, ADesc: string; ASchema: TJSONObject): TMCPToolFactory
          begin
            Result := function: IMCPTool
            begin
              Result := TCyberMAXDynamicTool.Create(AName, ADesc, ASchema);
            end;
          end)(ToolName, ToolDescription, SchemaClone)  // Immediate invocation with current values
        );

        if Assigned(SchemaClone) then
          TLogger.Info('  Registered: ' + ToolName + ' (' + Category + ', ' + Module + ') [with schema]')
        else
          TLogger.Info('  Registered: ' + ToolName + ' (' + Category + ', ' + Module + ')');
        Inc(Result);

      except
        on E: Exception do
          TLogger.Error('Failed to register tool ' + ToolName + ': ' + E.Message);
      end;
    end;

    CyberMAXToolCount := Result;
    TLogger.Info('Successfully registered ' + Result.ToString + ' CyberMAX tools');

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
