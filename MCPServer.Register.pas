unit MCPServer.Register;

interface

uses
  DesignIntf,
  DesignEditors,
  System.Classes,
  System.SysUtils,
  Vcl.Dialogs,
  MCPServer.VCL.Adapter,
  MCPServer.FMX.Adapter;

procedure Register;

implementation

type
  // Property editor for server status (read-only)
  TServerStatusProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

  // Component editor for quick actions
  TMCPEngineComponentEditor = class(TComponentEditor)
  protected
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

procedure Register;
begin
  // Register VCL component in the 'MCP Server' palette
  RegisterComponents('MCP Server', [TMCPEngineVCL]);
  
  // Register FMX component in the 'MCP Server' palette
  RegisterComponents('MCP Server', [TMCPEngineFMX]);
  
  // Register component editor for VCL context menu actions
  RegisterComponentEditor(TMCPEngineVCL, TMCPEngineComponentEditor);
  
  // Register property editors for VCL
  RegisterPropertyEditor(TypeInfo(Boolean), TMCPEngineVCL, 'Active', TServerStatusProperty);
  
  // Register property editors for FMX
  RegisterPropertyEditor(TypeInfo(Boolean), TMCPEngineFMX, 'Active', TServerStatusProperty);
end;

function TServerStatusProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly, paDisplayReadOnly];
end;

function TServerStatusProperty.GetValue: string;
var
  Component: TMCPEngineVCL;
begin
  Component := GetComponent(0) as TMCPEngineVCL;
  if Component.Active then
    Result := 'Running'
  else
    Result := 'Stopped';
end;

function TMCPEngineComponentEditor.GetVerbCount: Integer;
begin
  Result := 3;
end;

function TMCPEngineComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Start MCP Server';
    1: Result := 'Stop MCP Server';
    2: Result := '-';
  else
    Result := '';
  end;
end;

procedure TMCPEngineComponentEditor.ExecuteVerb(Index: Integer);
var
  MCPEngine: TMCPEngineVCL;
begin
  MCPEngine := Component as TMCPEngineVCL;
  
  case Index of
    0: // Start server
      begin
        if not MCPEngine.Active then
        begin
          try
            MCPEngine.Start;
            ShowMessage('MCP Server started on port ' + IntToStr(MCPEngine.Port));
          except
            on E: Exception do
              ShowMessage('Failed to start server: ' + E.Message);
          end;
        end
        else
          ShowMessage('Server is already running');
      end;
      
    1: // Stop server
      begin
        if MCPEngine.Active then
        begin
          try
            MCPEngine.Stop;
            ShowMessage('MCP Server stopped');
          except
            on E: Exception do
              ShowMessage('Failed to stop server: ' + E.Message);
          end;
        end
        else
          ShowMessage('Server is not running');
      end;
  end;
  
  Designer.Modified;
end;

end.
