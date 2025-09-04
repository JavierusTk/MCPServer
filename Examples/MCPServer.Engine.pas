unit MCPServer.Engine;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  MCPServer.Types,
  MCPServer.Settings,
  MCPServer.Logger,
  MCPServer.Registration,
  MCPServer.ManagerRegistry,
  MCPServer.IdHTTPServer,
  MCPServer.CoreManager,
  MCPServer.ToolsManager,
  MCPServer.ResourcesManager,
  MCPServer.Resource.Server;

type
  TMCPLogProc = reference to procedure(const Level: string; const Message: string);
  TMCPEventProc = reference to procedure;
  TMCPErrorProc = reference to procedure(const Error: Exception);
  TMCPRequestProc = reference to procedure(const Method: string; const Params: string);

  TMCPEngine = class
  private
    FServer: TMCPIdHTTPServer;
    FSettings: TMCPSettings;
    FManagerRegistry: IMCPManagerRegistry;
    FCoreManager: IMCPCapabilityManager;
    FToolsManager: IMCPCapabilityManager;
    FResourcesManager: IMCPCapabilityManager;
    FActive: Boolean;
    FPort: Word;
    FHost: string;
    FServerName: string;
    FServerVersion: string;
    FOnStarted: TMCPEventProc;
    FOnStopped: TMCPEventProc;
    FOnError: TMCPErrorProc;
    FOnRequest: TMCPRequestProc;
    FOnLog: TMCPLogProc;
    FAutoRegisterTools: Boolean;
    FEnableCORS: Boolean;
    FCORSOrigins: string;
    procedure SetPort(const Value: Word);
    procedure SetHost(const Value: string);
    procedure SetServerName(const Value: string);
    procedure SetServerVersion(const Value: string);
    procedure DoLog(const Level: string; const Message: string);
    procedure DoStarted;
    procedure DoStopped;
    procedure DoError(const E: Exception);
    procedure InitializeLogger;
    procedure UpdateSettings;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    
    function GetRegisteredTools: TArray<string>;
    function GetRegisteredResources: TArray<string>;
    function IsToolRegistered(const ToolName: string): Boolean;
    function IsResourceRegistered(const ResourceURI: string): Boolean;
    
    property Active: Boolean read FActive;
    property Port: Word read FPort write SetPort;
    property Host: string read FHost write SetHost;
    property ServerName: string read FServerName write SetServerName;
    property ServerVersion: string read FServerVersion write SetServerVersion;
    property AutoRegisterTools: Boolean read FAutoRegisterTools write FAutoRegisterTools;
    property EnableCORS: Boolean read FEnableCORS write FEnableCORS;
    property CORSOrigins: string read FCORSOrigins write FCORSOrigins;
    
    property OnStarted: TMCPEventProc read FOnStarted write FOnStarted;
    property OnStopped: TMCPEventProc read FOnStopped write FOnStopped;
    property OnError: TMCPErrorProc read FOnError write FOnError;
    property OnRequest: TMCPRequestProc read FOnRequest write FOnRequest;
    property OnLog: TMCPLogProc read FOnLog write FOnLog;
  end;

implementation

{ TMCPEngine }

constructor TMCPEngine.Create;
begin
  inherited Create;
  
  FActive := False;
  FPort := 3001;
  FHost := 'localhost';
  FServerName := 'Delphi MCP Server';
  FServerVersion := '1.0.0';
  FAutoRegisterTools := True;
  FEnableCORS := True;
  FCORSOrigins := 'http://localhost,http://127.0.0.1,https://localhost,https://127.0.0.1';
  
  InitializeLogger;
  
  FSettings := TMCPSettings.Create('');
  UpdateSettings;
  
  IsMultiThread := True;
  
  DoLog('INFO', 'MCP Engine created');
end;

destructor TMCPEngine.Destroy;
begin
  if FActive then
    Stop;
    
  FServer.Free;
  FSettings.Free;
  
  DoLog('INFO', 'MCP Engine destroyed');
  
  inherited;
end;

procedure TMCPEngine.InitializeLogger;
begin
  TLogger.LogToConsole := False;
  TLogger.LogToFile := False;
  TLogger.MinLogLevel := TLogLevel.Info;
  
  TLogger.OnLogMessage := procedure(const Message: string)
  begin
    var Level := 'INFO';
    if Message.Contains('[DEBUG]') then Level := 'DEBUG'
    else if Message.Contains('[WARN]') then Level := 'WARN'
    else if Message.Contains('[ERROR]') then Level := 'ERROR';
    
    DoLog(Level, Message);
  end;
end;

procedure TMCPEngine.UpdateSettings;
begin
  if Assigned(FSettings) then
  begin
    FSettings.Port := FPort;
    FSettings.Host := FHost;
    FSettings.ServerName := FServerName;
    FSettings.ServerVersion := FServerVersion;
    FSettings.CorsEnabled := FEnableCORS;
    FSettings.CorsAllowedOrigins := FCORSOrigins;
  end;
end;

procedure TMCPEngine.SetPort(const Value: Word);
begin
  if FActive then
    raise Exception.Create('Cannot change port while server is active');
  FPort := Value;
  UpdateSettings;
end;

procedure TMCPEngine.SetHost(const Value: string);
begin
  if FActive then
    raise Exception.Create('Cannot change host while server is active');
  FHost := Value;
  UpdateSettings;
end;

procedure TMCPEngine.SetServerName(const Value: string);
begin
  FServerName := Value;
  UpdateSettings;
end;

procedure TMCPEngine.SetServerVersion(const Value: string);
begin
  FServerVersion := Value;
  UpdateSettings;
end;

procedure TMCPEngine.Start;
begin
  if FActive then
    Exit;
    
  try
    DoLog('INFO', Format('Starting MCP Engine on %s:%d', [FHost, FPort]));
    
    UpdateSettings;
    
    FManagerRegistry := TMCPManagerRegistry.Create;
    FCoreManager := TMCPCoreManager.Create(FSettings);
    FToolsManager := TMCPToolsManager.Create;
    FResourcesManager := TMCPResourcesManager.Create;
    
    FManagerRegistry.RegisterManager(FCoreManager);
    FManagerRegistry.RegisterManager(FToolsManager);
    FManagerRegistry.RegisterManager(FResourcesManager);
    
    FServer := TMCPIdHTTPServer.Create(nil);
    FServer.Settings := FSettings;
    FServer.ManagerRegistry := FManagerRegistry;
    FServer.CoreManager := FCoreManager;
    
    TServerStatusResource.Initialize;
    
    FServer.Start;
    FActive := True;
    
    DoLog('INFO', 'MCP Engine started successfully');
    DoStarted;
    
  except
    on E: Exception do
    begin
      DoLog('ERROR', 'Failed to start MCP Engine: ' + E.Message);
      DoError(E);
      raise;
    end;
  end;
end;

procedure TMCPEngine.Stop;
begin
  if not FActive then
    Exit;
    
  try
    DoLog('INFO', 'Stopping MCP Engine');
    
    FServer.Stop;
    FActive := False;
    
    FreeAndNil(FServer);
    FManagerRegistry := nil;
    FCoreManager := nil;
    FToolsManager := nil;
    FResourcesManager := nil;
    
    DoLog('INFO', 'MCP Engine stopped');
    DoStopped;
    
  except
    on E: Exception do
    begin
      DoLog('ERROR', 'Error stopping MCP Engine: ' + E.Message);
      DoError(E);
      raise;
    end;
  end;
end;

function TMCPEngine.GetRegisteredTools: TArray<string>;
begin
  Result := TMCPRegistry.GetToolNames;
end;

function TMCPEngine.GetRegisteredResources: TArray<string>;
begin
  Result := TMCPRegistry.GetResourceURIs;
end;

function TMCPEngine.IsToolRegistered(const ToolName: string): Boolean;
begin
  Result := TMCPRegistry.HasTool(ToolName);
end;

function TMCPEngine.IsResourceRegistered(const ResourceURI: string): Boolean;
begin
  Result := TMCPRegistry.HasResource(ResourceURI);
end;

procedure TMCPEngine.DoLog(const Level: string; const Message: string);
begin
  if Assigned(FOnLog) then
  begin
    if TThread.CurrentThread.ThreadID = MainThreadID then
      FOnLog(Level, Message)
    else
      TThread.Queue(nil, procedure
      begin
        if Assigned(FOnLog) then
          FOnLog(Level, Message);
      end);
  end;
end;

procedure TMCPEngine.DoStarted;
begin
  if Assigned(FOnStarted) then
  begin
    if TThread.CurrentThread.ThreadID = MainThreadID then
      FOnStarted()
    else
      TThread.Queue(nil, procedure
      begin
        if Assigned(FOnStarted) then
          FOnStarted();
      end);
  end;
end;

procedure TMCPEngine.DoStopped;
begin
  if Assigned(FOnStopped) then
  begin
    if TThread.CurrentThread.ThreadID = MainThreadID then
      FOnStopped()
    else
      TThread.Queue(nil, procedure
      begin
        if Assigned(FOnStopped) then
          FOnStopped();
      end);
  end;
end;

procedure TMCPEngine.DoError(const E: Exception);
begin
  if Assigned(FOnError) then
  begin
    if TThread.CurrentThread.ThreadID = MainThreadID then
      FOnError(E)
    else
      TThread.Queue(nil, procedure
      begin
        if Assigned(FOnError) then
          FOnError(E);
      end);
  end;
end;

end.