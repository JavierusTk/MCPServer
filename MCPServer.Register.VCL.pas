unit MCPServer.Register.VCL;

interface

uses
  System.Classes,
  MCPServer.VCL.Adapter;

procedure Register;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  DesignIntf,
  DesignEditors,
  Vcl.Dialogs;

type
  // Property editor for server status (read-only)
  TServerStatusPropertyVCL = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

  // Property editor for Port with validation
  TPortPropertyVCL = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure SetValue(const Value: string); override;
  end;

  // Component editor for quick actions
  TMCPEngineVCLComponentEditor = class(TComponentEditor)
  protected
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  public
    procedure Edit; override;
  end;

{ Registration }

procedure Register;
begin
  // Register the VCL component in the 'MCP Server' palette
  RegisterComponents('MCP Server', [TMCPEngineVCL]);
  
  // Register component editor for context menu actions
  RegisterComponentEditor(TMCPEngineVCL, TMCPEngineVCLComponentEditor);
  
  // Register property editors
  RegisterPropertyEditor(TypeInfo(Boolean), TMCPEngineVCL, 'Active', TServerStatusPropertyVCL);
  RegisterPropertyEditor(TypeInfo(Word), TMCPEngineVCL, 'Port', TPortPropertyVCL);
end;

{ TServerStatusPropertyVCL }

function TServerStatusPropertyVCL.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly, paDisplayReadOnly];
end;

function TServerStatusPropertyVCL.GetValue: string;
var
  Component: TMCPEngineVCL;
begin
  Component := GetComponent(0) as TMCPEngineVCL;
  if Component.Active then
    Result := 'Running'
  else
    Result := 'Stopped';
end;

{ TPortPropertyVCL }

function TPortPropertyVCL.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
end;

procedure TPortPropertyVCL.SetValue(const Value: string);
var
  PortNum: Integer;
begin
  PortNum := StrToIntDef(Value, 0);
  if (PortNum < 1) or (PortNum > 65535) then
    raise Exception.Create('Port must be between 1 and 65535');
  inherited SetValue(Value);
end;

{ TMCPEngineVCLComponentEditor }

function TMCPEngineVCLComponentEditor.GetVerbCount: Integer;
begin
  Result := 5;
end;

function TMCPEngineVCLComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Start MCP Server';
    1: Result := 'Stop MCP Server';
    2: Result := '-';
    3: Result := 'Show Registered Tools...';
    4: Result := 'About MCP Server...';
  else
    Result := '';
  end;
end;

procedure TMCPEngineVCLComponentEditor.ExecuteVerb(Index: Integer);
var
  MCPEngine: TMCPEngineVCL;
  Tools: TArray<string>;
  ToolList: string;
  i: Integer;
begin
  MCPEngine := Component as TMCPEngineVCL;
  
  case Index of
    0: // Start server
      begin
        if not MCPEngine.Active then
        begin
          try
            MCPEngine.Start;
            ShowMessage('MCP Server started successfully on port ' + IntToStr(MCPEngine.Port));
          except
            on E: Exception do
              ShowMessage('Failed to start server: ' + E.Message);
          end;
        end
        else
          ShowMessage('Server is already running on port ' + IntToStr(MCPEngine.Port));
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
      
    3: // Show registered tools
      begin
        Tools := MCPEngine.GetRegisteredTools;
        if Length(Tools) > 0 then
        begin
          ToolList := 'Registered MCP Tools:'#13#10#13#10;
          for i := 0 to High(Tools) do
            ToolList := ToolList + '• ' + Tools[i] + #13#10;
        end
        else
          ToolList := 'No tools are currently registered.';
          
        ShowMessage(ToolList);
      end;
      
    4: // About
      begin
        ShowMessage('MCP Server VCL Component'#13#10 +
                    'Version: 1.0.0'#13#10#13#10 +
                    'Model Context Protocol Server for Delphi'#13#10 +
                    'Enables AI integration via Claude Code'#13#10#13#10 +
                    'Server Name: ' + MCPEngine.ServerName + #13#10 +
                    'Server Version: ' + MCPEngine.ServerVersion);
      end;
  end;
  
  if Index in [0, 1] then
    Designer.Modified;
end;

procedure TMCPEngineVCLComponentEditor.Edit;
begin
  ExecuteVerb(3); // Show tools by default on double-click
end;

end.