unit MCPServer.Adapter;

interface

uses
  System.SysUtils,
  System.Classes,
  MCPServer.Engine,
  MCPServer.Config;

type
  TMCPLogEvent = procedure(Sender: TObject; const Level, Message: string) of object;
  TMCPStatusEvent = procedure(Sender: TObject) of object;
  TMCPErrorEvent = procedure(Sender: TObject; const Error: Exception) of object;
  TMCPRequestEvent = procedure(Sender: TObject; const Method, Params: string) of object;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX64 or pidLinux64 or pidAndroidArm32 or pidAndroidArm64 or pidiOSDevice64)]
  TMCPEngineServer = class(TComponent)
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

implementation


{ TMCPEngineServer }

constructor TMCPEngineServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  FConfig := TMCPConfig.Create;
  FEngine := TMCPEngine.Create;
  FAutoStart := False;
  
  SetupEventHandlers;
end;

destructor TMCPEngineServer.Destroy;
begin
  if FEngine.Active then
    FEngine.Stop;
    
  FEngine.Free;
  FConfig.Free;
  
  inherited;
end;

procedure TMCPEngineServer.Loaded;
begin
  inherited;
  
  if FAutoStart and not (csDesigning in ComponentState) then
    Start;
end;

procedure TMCPEngineServer.SetupEventHandlers;
begin
  FEngine.OnLog := HandleLog;
  FEngine.OnStarted := HandleStarted;
  FEngine.OnStopped := HandleStopped;
  FEngine.OnError := HandleError;
  FEngine.OnRequest := HandleRequest;
end;

procedure TMCPEngineServer.HandleLog(const Level, Message: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, Level, Message);
end;

procedure TMCPEngineServer.HandleStarted;
begin
  if Assigned(FOnStarted) then
    FOnStarted(Self);
end;

procedure TMCPEngineServer.HandleStopped;
begin
  if Assigned(FOnStopped) then
    FOnStopped(Self);
end;

procedure TMCPEngineServer.HandleError(const Error: Exception);
begin
  if Assigned(FOnError) then
    FOnError(Self, Error);
end;

procedure TMCPEngineServer.HandleRequest(const Method, Params: string);
begin
  if Assigned(FOnRequest) then
    FOnRequest(Self, Method, Params);
end;

function TMCPEngineServer.GetPort: Word;
begin
  Result := FEngine.Port;
end;

procedure TMCPEngineServer.SetPort(const Value: Word);
begin
  if csDesigning in ComponentState then
  begin
    FConfig.Port := Value;
    Exit;
  end;
  
  FEngine.Port := Value;
  FConfig.Port := Value;
end;

function TMCPEngineServer.GetHost: string;
begin
  Result := FEngine.Host;
end;

procedure TMCPEngineServer.SetHost(const Value: string);
begin
  if csDesigning in ComponentState then
  begin
    FConfig.Host := Value;
    Exit;
  end;
  
  FEngine.Host := Value;
  FConfig.Host := Value;
end;

function TMCPEngineServer.GetServerName: string;
begin
  Result := FEngine.ServerName;
end;

procedure TMCPEngineServer.SetServerName(const Value: string);
begin
  FEngine.ServerName := Value;
  FConfig.ServerName := Value;
end;

function TMCPEngineServer.GetServerVersion: string;
begin
  Result := FEngine.ServerVersion;
end;

procedure TMCPEngineServer.SetServerVersion(const Value: string);
begin
  FEngine.ServerVersion := Value;
  FConfig.ServerVersion := Value;
end;

function TMCPEngineServer.GetActive: Boolean;
begin
  if csDesigning in ComponentState then
    Result := False
  else
    Result := FEngine.Active;
end;

function TMCPEngineServer.GetEnableCORS: Boolean;
begin
  Result := FEngine.EnableCORS;
end;

procedure TMCPEngineServer.SetEnableCORS(const Value: Boolean);
begin
  FEngine.EnableCORS := Value;
  FConfig.EnableCORS := Value;
end;

function TMCPEngineServer.GetCORSOrigins: string;
begin
  Result := FEngine.CORSOrigins;
end;

procedure TMCPEngineServer.SetCORSOrigins(const Value: string);
begin
  FEngine.CORSOrigins := Value;
  FConfig.CORSOrigins.DelimitedText := Value;
end;

procedure TMCPEngineServer.Start;
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

procedure TMCPEngineServer.Stop;
begin
  if csDesigning in ComponentState then
    Exit;
    
  FEngine.Stop;
end;

function TMCPEngineServer.GetRegisteredTools: TArray<string>;
begin
  Result := FEngine.GetRegisteredTools;
end;

function TMCPEngineServer.GetRegisteredResources: TArray<string>;
begin
  Result := FEngine.GetRegisteredResources;
end;

function TMCPEngineServer.IsToolRegistered(const ToolName: string): Boolean;
begin
  Result := FEngine.IsToolRegistered(ToolName);
end;

function TMCPEngineServer.IsResourceRegistered(const ResourceURI: string): Boolean;
begin
  Result := FEngine.IsResourceRegistered(ResourceURI);
end;

end.
