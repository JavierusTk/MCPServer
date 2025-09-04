unit MCPServer.FMX.Adapter;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Memo,
  FMX.ListBox,
  MCPServer.Engine,
  MCPServer.Config;

type
  TMCPLogEvent = procedure(Sender: TObject; const Level, Message: string) of object;
  TMCPStatusEvent = procedure(Sender: TObject) of object;
  TMCPErrorEvent = procedure(Sender: TObject; const Error: Exception) of object;
  TMCPRequestEvent = procedure(Sender: TObject; const Method, Params: string) of object;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidLinux64 or pidAndroidArm32 or pidAndroidArm64 or pidiOSDevice64)]
  TMCPEngineFMX = class(TComponent)
  private
    FEngine: TMCPEngine;
    FConfig: TMCPConfig;
    FAutoStart: Boolean;
    FOnLog: TMCPLogEvent;
    FOnStarted: TMCPStatusEvent;
    FOnStopped: TMCPStatusEvent;
    FOnError: TMCPErrorEvent;
    FOnRequest: TMCPRequestEvent;
    function GetPort: Word;
    function GetHost: string;
    function GetServerName: string;
    function GetServerVersion: string;
    function GetActive: Boolean;
    function GetEnableCORS: Boolean;
    function GetCORSOrigins: string;
    procedure SetPort(const Value: Word);
    procedure SetHost(const Value: string);
    procedure SetServerName(const Value: string);
    procedure SetServerVersion(const Value: string);
    procedure SetEnableCORS(const Value: Boolean);
    procedure SetCORSOrigins(const Value: string);
    procedure SetupEventHandlers;
    procedure HandleLog(const Level, Message: string);
    procedure HandleStarted;
    procedure HandleStopped;
    procedure HandleError(const Error: Exception);
    procedure HandleRequest(const Method, Params: string);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    
    function GetRegisteredTools: TArray<string>;
    function GetRegisteredResources: TArray<string>;
    function IsToolRegistered(const ToolName: string): Boolean;
    function IsResourceRegistered(const ResourceURI: string): Boolean;
    
    procedure LogToMemo(AMemo: TMemo; const Level, Message: string);
    procedure LogToListBox(AListBox: TListBox; const Level, Message: string);
    
    property Engine: TMCPEngine read FEngine;
    property Config: TMCPConfig read FConfig;
    property Active: Boolean read GetActive;
  published
    property Port: Word read GetPort write SetPort default 3001;
    property Host: string read GetHost write SetHost;
    property ServerName: string read GetServerName write SetServerName;
    property ServerVersion: string read GetServerVersion write SetServerVersion;
    property EnableCORS: Boolean read GetEnableCORS write SetEnableCORS default True;
    property CORSOrigins: string read GetCORSOrigins write SetCORSOrigins;
    property AutoStart: Boolean read FAutoStart write FAutoStart default False;
    
    property OnLog: TMCPLogEvent read FOnLog write FOnLog;
    property OnStarted: TMCPStatusEvent read FOnStarted write FOnStarted;
    property OnStopped: TMCPStatusEvent read FOnStopped write FOnStopped;
    property OnError: TMCPErrorEvent read FOnError write FOnError;
    property OnRequest: TMCPRequestEvent read FOnRequest write FOnRequest;
  end;

  TMCPLogHelperFMX = class
  public
    class procedure AddToMemo(AMemo: TMemo; const Text: string);
    class procedure AddToListBox(AListBox: TListBox; const Text: string);
  end;

implementation

uses
  System.UITypes,
  System.Types,
  FMX.Platform;

{ TMCPEngineFMX }

constructor TMCPEngineFMX.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  FConfig := TMCPConfig.Create;
  FEngine := TMCPEngine.Create;
  FAutoStart := False;
  
  SetupEventHandlers;
end;

destructor TMCPEngineFMX.Destroy;
begin
  if FEngine.Active then
    FEngine.Stop;
    
  FEngine.Free;
  FConfig.Free;
  
  inherited;
end;

procedure TMCPEngineFMX.Loaded;
begin
  inherited;
  
  if FAutoStart and not (csDesigning in ComponentState) then
    Start;
end;

procedure TMCPEngineFMX.SetupEventHandlers;
begin
  FEngine.OnLog := HandleLog;
  FEngine.OnStarted := HandleStarted;
  FEngine.OnStopped := HandleStopped;
  FEngine.OnError := HandleError;
  FEngine.OnRequest := HandleRequest;
end;

procedure TMCPEngineFMX.HandleLog(const Level, Message: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, Level, Message);
end;

procedure TMCPEngineFMX.HandleStarted;
begin
  if Assigned(FOnStarted) then
    FOnStarted(Self);
end;

procedure TMCPEngineFMX.HandleStopped;
begin
  if Assigned(FOnStopped) then
    FOnStopped(Self);
end;

procedure TMCPEngineFMX.HandleError(const Error: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, Error);
end;

procedure TMCPEngineFMX.HandleRequest(const Method, Params: string);
begin
  if Assigned(FOnRequest) then
    FOnRequest(Self, Method, Params);
end;

function TMCPEngineFMX.GetPort: Word;
begin
  Result := FEngine.Port;
end;

procedure TMCPEngineFMX.SetPort(const Value: Word);
begin
  if csDesigning in ComponentState then
  begin
    FConfig.Port := Value;
    Exit;
  end;
  
  FEngine.Port := Value;
  FConfig.Port := Value;
end;

function TMCPEngineFMX.GetHost: string;
begin
  Result := FEngine.Host;
end;

procedure TMCPEngineFMX.SetHost(const Value: string);
begin
  if csDesigning in ComponentState then
  begin
    FConfig.Host := Value;
    Exit;
  end;
  
  FEngine.Host := Value;
  FConfig.Host := Value;
end;

function TMCPEngineFMX.GetServerName: string;
begin
  Result := FEngine.ServerName;
end;

procedure TMCPEngineFMX.SetServerName(const Value: string);
begin
  FEngine.ServerName := Value;
  FConfig.ServerName := Value;
end;

function TMCPEngineFMX.GetServerVersion: string;
begin
  Result := FEngine.ServerVersion;
end;

procedure TMCPEngineFMX.SetServerVersion(const Value: string);
begin
  FEngine.ServerVersion := Value;
  FConfig.ServerVersion := Value;
end;

function TMCPEngineFMX.GetActive: Boolean;
begin
  if csDesigning in ComponentState then
    Result := False
  else
    Result := FEngine.Active;
end;

function TMCPEngineFMX.GetEnableCORS: Boolean;
begin
  Result := FEngine.EnableCORS;
end;

procedure TMCPEngineFMX.SetEnableCORS(const Value: Boolean);
begin
  FEngine.EnableCORS := Value;
  FConfig.EnableCORS := Value;
end;

function TMCPEngineFMX.GetCORSOrigins: string;
begin
  Result := FEngine.CORSOrigins;
end;

procedure TMCPEngineFMX.SetCORSOrigins(const Value: string);
begin
  FEngine.CORSOrigins := Value;
  FConfig.CORSOrigins.DelimitedText := Value;
end;

procedure TMCPEngineFMX.Start;
begin
  if csDesigning in ComponentState then
    Exit;
    
  FEngine.Port := FConfig.Port;
  FEngine.Host := FConfig.Host;
  FEngine.ServerName := FConfig.ServerName;
  FEngine.ServerVersion := FConfig.ServerVersion;
  FEngine.EnableCORS := FConfig.EnableCORS;
  FEngine.CORSOrigins := FConfig.GetCORSOriginsString;
  
  FEngine.Start;
end;

procedure TMCPEngineFMX.Stop;
begin
  if csDesigning in ComponentState then
    Exit;
    
  FEngine.Stop;
end;

function TMCPEngineFMX.GetRegisteredTools: TArray<string>;
begin
  Result := FEngine.GetRegisteredTools;
end;

function TMCPEngineFMX.GetRegisteredResources: TArray<string>;
begin
  Result := FEngine.GetRegisteredResources;
end;

function TMCPEngineFMX.IsToolRegistered(const ToolName: string): Boolean;
begin
  Result := FEngine.IsToolRegistered(ToolName);
end;

function TMCPEngineFMX.IsResourceRegistered(const ResourceURI: string): Boolean;
begin
  Result := FEngine.IsResourceRegistered(ResourceURI);
end;

procedure TMCPEngineFMX.LogToMemo(AMemo: TMemo; const Level, Message: string);
begin
  TMCPLogHelperFMX.AddToMemo(AMemo, Format('[%s] %s', [Level, Message]));
end;

procedure TMCPEngineFMX.LogToListBox(AListBox: TListBox; const Level, Message: string);
begin
  TMCPLogHelperFMX.AddToListBox(AListBox, Format('[%s] %s', [Level, Message]));
end;

{ TMCPLogHelperFMX }

class procedure TMCPLogHelperFMX.AddToMemo(AMemo: TMemo; const Text: string);
begin
  if not Assigned(AMemo) then
    Exit;
    
  TThread.Queue(nil, procedure
  begin
    AMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + Text);
    
    // Auto-scroll to bottom
    AMemo.SelStart := Length(AMemo.Text);
    AMemo.SelLength := 0;
    
    // Limit lines to prevent memory issues
    while AMemo.Lines.Count > 1000 do
      AMemo.Lines.Delete(0);
  end);
end;

class procedure TMCPLogHelperFMX.AddToListBox(AListBox: TListBox; const Text: string);
begin
  if not Assigned(AListBox) then
    Exit;
    
  TThread.Queue(nil, procedure
  var
    Item: TListBoxItem;
  begin
    Item := TListBoxItem.Create(AListBox);
    Item.Text := FormatDateTime('hh:nn:ss', Now) + ' ' + Text;
    Item.Parent := AListBox;
    
    // Auto-scroll to bottom
    AListBox.ItemIndex := AListBox.Items.Count - 1;
    
    // Limit items to prevent memory issues
    while AListBox.Count > 500 do
      AListBox.Items.Delete(0);
  end);
end;

end.