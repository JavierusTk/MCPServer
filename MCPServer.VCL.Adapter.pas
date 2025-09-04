unit MCPServer.VCL.Adapter;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  MCPServer.Engine,
  MCPServer.Config;

type
  TMCPLogEvent = procedure(Sender: TObject; const Level, Message: string) of object;
  TMCPStatusEvent = procedure(Sender: TObject) of object;
  TMCPErrorEvent = procedure(Sender: TObject; const Error: Exception) of object;
  TMCPRequestEvent = procedure(Sender: TObject; const Method, Params: string) of object;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TMCPEngineVCL = class(TComponent)
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
    procedure LogToListView(AListView: TListView; const Level, Message: string);
    procedure LogToRichEdit(ARichEdit: TRichEdit; const Level, Message: string);
    
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

  TMCPLogHelper = class
  public
    class procedure AddToMemo(AMemo: TMemo; const Text: string);
    class procedure AddToListBox(AListBox: TListBox; const Text: string);
    class procedure AddToListView(AListView: TListView; const Level, Message: string);
    class procedure AddToRichEdit(ARichEdit: TRichEdit; const Text: string; const Level: string = 'INFO');
  end;

implementation

uses
  Vcl.Graphics,
  Winapi.Windows,
  Winapi.Messages;

{ TMCPEngineVCL }

constructor TMCPEngineVCL.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  FConfig := TMCPConfig.Create;
  FEngine := TMCPEngine.Create;
  FAutoStart := False;
  
  SetupEventHandlers;
end;

destructor TMCPEngineVCL.Destroy;
begin
  if FEngine.Active then
    FEngine.Stop;
    
  FEngine.Free;
  FConfig.Free;
  
  inherited;
end;

procedure TMCPEngineVCL.Loaded;
begin
  inherited;
  
  if FAutoStart and not (csDesigning in ComponentState) then
    Start;
end;

procedure TMCPEngineVCL.SetupEventHandlers;
begin
  FEngine.OnLog := HandleLog;
  FEngine.OnStarted := HandleStarted;
  FEngine.OnStopped := HandleStopped;
  FEngine.OnError := HandleError;
  FEngine.OnRequest := HandleRequest;
end;

procedure TMCPEngineVCL.HandleLog(const Level, Message: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, Level, Message);
end;

procedure TMCPEngineVCL.HandleStarted;
begin
  if Assigned(FOnStarted) then
    FOnStarted(Self);
end;

procedure TMCPEngineVCL.HandleStopped;
begin
  if Assigned(FOnStopped) then
    FOnStopped(Self);
end;

procedure TMCPEngineVCL.HandleError(const Error: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, Error);
end;

procedure TMCPEngineVCL.HandleRequest(const Method, Params: string);
begin
  if Assigned(FOnRequest) then
    FOnRequest(Self, Method, Params);
end;

function TMCPEngineVCL.GetPort: Word;
begin
  Result := FEngine.Port;
end;

procedure TMCPEngineVCL.SetPort(const Value: Word);
begin
  if csDesigning in ComponentState then
  begin
    FConfig.Port := Value;
    Exit;
  end;
  
  FEngine.Port := Value;
  FConfig.Port := Value;
end;

function TMCPEngineVCL.GetHost: string;
begin
  Result := FEngine.Host;
end;

procedure TMCPEngineVCL.SetHost(const Value: string);
begin
  if csDesigning in ComponentState then
  begin
    FConfig.Host := Value;
    Exit;
  end;
  
  FEngine.Host := Value;
  FConfig.Host := Value;
end;

function TMCPEngineVCL.GetServerName: string;
begin
  Result := FEngine.ServerName;
end;

procedure TMCPEngineVCL.SetServerName(const Value: string);
begin
  FEngine.ServerName := Value;
  FConfig.ServerName := Value;
end;

function TMCPEngineVCL.GetServerVersion: string;
begin
  Result := FEngine.ServerVersion;
end;

procedure TMCPEngineVCL.SetServerVersion(const Value: string);
begin
  FEngine.ServerVersion := Value;
  FConfig.ServerVersion := Value;
end;

function TMCPEngineVCL.GetActive: Boolean;
begin
  if csDesigning in ComponentState then
    Result := False
  else
    Result := FEngine.Active;
end;

function TMCPEngineVCL.GetEnableCORS: Boolean;
begin
  Result := FEngine.EnableCORS;
end;

procedure TMCPEngineVCL.SetEnableCORS(const Value: Boolean);
begin
  FEngine.EnableCORS := Value;
  FConfig.EnableCORS := Value;
end;

function TMCPEngineVCL.GetCORSOrigins: string;
begin
  Result := FEngine.CORSOrigins;
end;

procedure TMCPEngineVCL.SetCORSOrigins(const Value: string);
begin
  FEngine.CORSOrigins := Value;
  FConfig.CORSOrigins.DelimitedText := Value;
end;

procedure TMCPEngineVCL.Start;
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

procedure TMCPEngineVCL.Stop;
begin
  if csDesigning in ComponentState then
    Exit;
    
  FEngine.Stop;
end;

function TMCPEngineVCL.GetRegisteredTools: TArray<string>;
begin
  Result := FEngine.GetRegisteredTools;
end;

function TMCPEngineVCL.GetRegisteredResources: TArray<string>;
begin
  Result := FEngine.GetRegisteredResources;
end;

function TMCPEngineVCL.IsToolRegistered(const ToolName: string): Boolean;
begin
  Result := FEngine.IsToolRegistered(ToolName);
end;

function TMCPEngineVCL.IsResourceRegistered(const ResourceURI: string): Boolean;
begin
  Result := FEngine.IsResourceRegistered(ResourceURI);
end;

procedure TMCPEngineVCL.LogToMemo(AMemo: TMemo; const Level, Message: string);
begin
  TMCPLogHelper.AddToMemo(AMemo, Format('[%s] %s', [Level, Message]));
end;

procedure TMCPEngineVCL.LogToListBox(AListBox: TListBox; const Level, Message: string);
begin
  TMCPLogHelper.AddToListBox(AListBox, Format('[%s] %s', [Level, Message]));
end;

procedure TMCPEngineVCL.LogToListView(AListView: TListView; const Level, Message: string);
begin
  TMCPLogHelper.AddToListView(AListView, Level, Message);
end;

procedure TMCPEngineVCL.LogToRichEdit(ARichEdit: TRichEdit; const Level, Message: string);
begin
  TMCPLogHelper.AddToRichEdit(ARichEdit, Message, Level);
end;

{ TMCPLogHelper }

class procedure TMCPLogHelper.AddToMemo(AMemo: TMemo; const Text: string);
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

class procedure TMCPLogHelper.AddToListBox(AListBox: TListBox; const Text: string);
begin
  if not Assigned(AListBox) then
    Exit;
    
  TThread.Queue(nil, procedure
  begin
    AListBox.Items.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + Text);
    
    // Auto-scroll to bottom
    AListBox.ItemIndex := AListBox.Items.Count - 1;
    
    // Limit items to prevent memory issues
    while AListBox.Items.Count > 500 do
      AListBox.Items.Delete(0);
  end);
end;

class procedure TMCPLogHelper.AddToListView(AListView: TListView; const Level, Message: string);
var
  Item: TListItem;
begin
  if not Assigned(AListView) then
    Exit;
    
  TThread.Queue(nil, procedure
  begin
    Item := AListView.Items.Add;
    Item.Caption := FormatDateTime('hh:nn:ss', Now);
    Item.SubItems.Add(Level);
    Item.SubItems.Add(Message);
    
    // Color-code by level
    if Level = 'ERROR' then
      Item.ImageIndex := 0
    else if Level = 'WARN' then
      Item.ImageIndex := 1
    else if Level = 'INFO' then
      Item.ImageIndex := 2
    else
      Item.ImageIndex := 3;
    
    // Auto-scroll to bottom
    Item.MakeVisible(True);
    
    // Limit items to prevent memory issues
    while AListView.Items.Count > 500 do
      AListView.Items.Delete(0);
  end);
end;

class procedure TMCPLogHelper.AddToRichEdit(ARichEdit: TRichEdit; const Text: string; const Level: string);
var
  Color: TColor;
begin
  if not Assigned(ARichEdit) then
    Exit;
    
  TThread.Queue(nil, procedure
  begin
    // Determine color based on level
    if Level = 'ERROR' then
      Color := clRed
    else if Level = 'WARN' then
      Color := clOlive
    else if Level = 'DEBUG' then
      Color := clGray
    else
      Color := clBlack;
    
    // Add timestamp
    ARichEdit.SelStart := Length(ARichEdit.Text);
    ARichEdit.SelAttributes.Color := clGray;
    ARichEdit.SelText := FormatDateTime('hh:nn:ss ', Now);
    
    // Add level
    ARichEdit.SelAttributes.Color := Color;
    ARichEdit.SelAttributes.Style := [fsBold];
    ARichEdit.SelText := '[' + Level + '] ';
    
    // Add message
    ARichEdit.SelAttributes.Color := clBlack;
    ARichEdit.SelAttributes.Style := [];
    ARichEdit.SelText := Text + #13#10;
    
    // Auto-scroll to bottom
    ARichEdit.SelStart := Length(ARichEdit.Text);
    ARichEdit.SelLength := 0;
    SendMessage(ARichEdit.Handle, EM_SCROLLCARET, 0, 0);
    
    // Limit text to prevent memory issues
    if ARichEdit.Lines.Count > 1000 then
    begin
      ARichEdit.Lines.BeginUpdate;
      try
        while ARichEdit.Lines.Count > 500 do
          ARichEdit.Lines.Delete(0);
      finally
        ARichEdit.Lines.EndUpdate;
      end;
    end;
  end);
end;

end.