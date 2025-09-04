unit MCPServer.Register.FMX;

interface

uses
  System.Classes,
  MCPServer.FMX.Adapter;

procedure Register;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  DesignIntf,
  DesignEditors,
  FMX.Dialogs;

type
  // Property editor for server status (read-only)
  TServerStatusPropertyFMX = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

  // Property editor for Port with validation
  TPortPropertyFMX = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure SetValue(const Value: string); override;
  end;

  // Component editor for quick actions
  TMCPEngineFMXComponentEditor = class(TComponentEditor)
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
  // Register the FMX component in the 'MCP Server' palette
  RegisterComponents('MCP Server', [TMCPEngineFMX]);
  
  // Register component editor for context menu actions
  RegisterComponentEditor(TMCPEngineFMX, TMCPEngineFMXComponentEditor);
  
  // Register property editors
  RegisterPropertyEditor(TypeInfo(Boolean), TMCPEngineFMX, 'Active', TServerStatusPropertyFMX);
  RegisterPropertyEditor(TypeInfo(Word), TMCPEngineFMX, 'Port', TPortPropertyFMX);
end;

{ TServerStatusPropertyFMX }

function TServerStatusPropertyFMX.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly, paDisplayReadOnly];
end;

function TServerStatusPropertyFMX.GetValue: string;
var
  Component: TMCPEngineFMX;
begin
  Component := GetComponent(0) as TMCPEngineFMX;
  if Component.Active then
    Result := 'Running'
  else
    Result := 'Stopped';
end;

{ TPortPropertyFMX }

function TPortPropertyFMX.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
end;

procedure TPortPropertyFMX.SetValue(const Value: string);
var
  PortNum: Integer;
begin
  PortNum := StrToIntDef(Value, 0);
  if (PortNum < 1) or (PortNum > 65535) then
    raise Exception.Create('Port must be between 1 and 65535');
  inherited SetValue(Value);
end;

{ TMCPEngineFMXComponentEditor }

function TMCPEngineFMXComponentEditor.GetVerbCount: Integer;
begin
  Result := 5;
end;

function TMCPEngineFMXComponentEditor.GetVerb(Index: Integer): string;
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

procedure TMCPEngineFMXComponentEditor.ExecuteVerb(Index: Integer);
var
  MCPEngine: TMCPEngineFMX;
  Tools: TArray<string>;
  ToolList: string;
  i: Integer;
begin
  MCPEngine := Component as TMCPEngineFMX;
  
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
        ShowMessage('MCP Server FMX Component'#13#10 +
                    'Version: 1.0.0'#13#10#13#10 +
                    'Model Context Protocol Server for Delphi'#13#10 +
                    'Cross-Platform AI Integration via Claude Code'#13#10#13#10 +
                    'Server Name: ' + MCPEngine.ServerName + #13#10 +
                    'Server Version: ' + MCPEngine.ServerVersion + #13#10#13#10 +
                    'Platforms: Windows, macOS, Linux, Android, iOS');
      end;
  end;
  
  if Index in [0, 1] then
    Designer.Modified;
end;

procedure TMCPEngineFMXComponentEditor.Edit;
begin
  ExecuteVerb(3); // Show tools by default on double-click
end;

end.