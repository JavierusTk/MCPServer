unit MCPServer.Config;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TMCPConfig = class
  private
    FPort: Word;
    FHost: string;
    FServerName: string;
    FServerVersion: string;
    FEndpoint: string;
    FEnableCORS: Boolean;
    FCORSOrigins: TStrings;
    FEnableSSL: Boolean;
    FSSLCertFile: string;
    FSSLKeyFile: string;
    FLogLevel: string;
    FMaxConnections: Integer;
    procedure SetCORSOrigins(const Value: TStrings);
  public
    constructor Create;
    destructor Destroy; override;
    
    function WithPort(APort: Word): TMCPConfig;
    function WithHost(const AHost: string): TMCPConfig;
    function WithServerName(const AName: string): TMCPConfig;
    function WithServerVersion(const AVersion: string): TMCPConfig;
    function WithEndpoint(const AEndpoint: string): TMCPConfig;
    function WithCORS(AEnabled: Boolean): TMCPConfig;
    function WithCORSOrigin(const AOrigin: string): TMCPConfig;
    function WithSSL(AEnabled: Boolean): TMCPConfig;
    function WithSSLCerts(const ACertFile, AKeyFile: string): TMCPConfig;
    function WithLogLevel(const ALevel: string): TMCPConfig;
    function WithMaxConnections(AMax: Integer): TMCPConfig;
    
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromStrings(const AStrings: TStrings);
    procedure SaveToStrings(const AStrings: TStrings);
    
    function GetCORSOriginsString: string;
    
    class function Default: TMCPConfig;
    
    property Port: Word read FPort write FPort;
    property Host: string read FHost write FHost;
    property ServerName: string read FServerName write FServerName;
    property ServerVersion: string read FServerVersion write FServerVersion;
    property Endpoint: string read FEndpoint write FEndpoint;
    property EnableCORS: Boolean read FEnableCORS write FEnableCORS;
    property CORSOrigins: TStrings read FCORSOrigins write SetCORSOrigins;
    property EnableSSL: Boolean read FEnableSSL write FEnableSSL;
    property SSLCertFile: string read FSSLCertFile write FSSLCertFile;
    property SSLKeyFile: string read FSSLKeyFile write FSSLKeyFile;
    property LogLevel: string read FLogLevel write FLogLevel;
    property MaxConnections: Integer read FMaxConnections write FMaxConnections;
  end;

implementation

uses
  System.IniFiles,
  System.IOUtils;

{ TMCPConfig }

constructor TMCPConfig.Create;
begin
  inherited Create;
  FCORSOrigins := TStringList.Create;
  
  FPort := 3001;
  FHost := 'localhost';
  FServerName := 'Delphi MCP Server';
  FServerVersion := '1.0.0';
  FEndpoint := '/mcp';
  FEnableCORS := True;
  FCORSOrigins.Add('http://localhost');
  FCORSOrigins.Add('http://127.0.0.1');
  FCORSOrigins.Add('https://localhost');
  FCORSOrigins.Add('https://127.0.0.1');
  FEnableSSL := False;
  FSSLCertFile := '';
  FSSLKeyFile := '';
  FLogLevel := 'INFO';
  FMaxConnections := 10;
end;

destructor TMCPConfig.Destroy;
begin
  FCORSOrigins.Free;
  inherited;
end;

procedure TMCPConfig.SetCORSOrigins(const Value: TStrings);
begin
  FCORSOrigins.Assign(Value);
end;

function TMCPConfig.WithPort(APort: Word): TMCPConfig;
begin
  FPort := APort;
  Result := Self;
end;

function TMCPConfig.WithHost(const AHost: string): TMCPConfig;
begin
  FHost := AHost;
  Result := Self;
end;

function TMCPConfig.WithServerName(const AName: string): TMCPConfig;
begin
  FServerName := AName;
  Result := Self;
end;

function TMCPConfig.WithServerVersion(const AVersion: string): TMCPConfig;
begin
  FServerVersion := AVersion;
  Result := Self;
end;

function TMCPConfig.WithEndpoint(const AEndpoint: string): TMCPConfig;
begin
  FEndpoint := AEndpoint;
  Result := Self;
end;

function TMCPConfig.WithCORS(AEnabled: Boolean): TMCPConfig;
begin
  FEnableCORS := AEnabled;
  Result := Self;
end;

function TMCPConfig.WithCORSOrigin(const AOrigin: string): TMCPConfig;
begin
  if FCORSOrigins.IndexOf(AOrigin) = -1 then
    FCORSOrigins.Add(AOrigin);
  Result := Self;
end;

function TMCPConfig.WithSSL(AEnabled: Boolean): TMCPConfig;
begin
  FEnableSSL := AEnabled;
  Result := Self;
end;

function TMCPConfig.WithSSLCerts(const ACertFile, AKeyFile: string): TMCPConfig;
begin
  FSSLCertFile := ACertFile;
  FSSLKeyFile := AKeyFile;
  FEnableSSL := True;
  Result := Self;
end;

function TMCPConfig.WithLogLevel(const ALevel: string): TMCPConfig;
begin
  FLogLevel := ALevel;
  Result := Self;
end;

function TMCPConfig.WithMaxConnections(AMax: Integer): TMCPConfig;
begin
  FMaxConnections := AMax;
  Result := Self;
end;

procedure TMCPConfig.LoadFromFile(const AFileName: string);
var
  Ini: TIniFile;
  Origins: string;
  OriginList: TStringList;
begin
  if not TFile.Exists(AFileName) then
    Exit;
    
  Ini := TIniFile.Create(AFileName);
  try
    FPort := Ini.ReadInteger('Server', 'Port', FPort);
    FHost := Ini.ReadString('Server', 'Host', FHost);
    FServerName := Ini.ReadString('MCP', 'ServerName', FServerName);
    FServerVersion := Ini.ReadString('MCP', 'ServerVersion', FServerVersion);
    FEndpoint := Ini.ReadString('Server', 'Endpoint', FEndpoint);
    FMaxConnections := Ini.ReadInteger('Server', 'MaxConnections', FMaxConnections);
    
    FEnableCORS := Ini.ReadBool('CORS', 'Enabled', FEnableCORS);
    Origins := Ini.ReadString('CORS', 'AllowedOrigins', '');
    if Origins <> '' then
    begin
      OriginList := TStringList.Create;
      try
        OriginList.Delimiter := ',';
        OriginList.StrictDelimiter := True;
        OriginList.DelimitedText := Origins;
        FCORSOrigins.Assign(OriginList);
      finally
        OriginList.Free;
      end;
    end;
    
    FEnableSSL := Ini.ReadBool('SSL', 'Enabled', FEnableSSL);
    FSSLCertFile := Ini.ReadString('SSL', 'CertFile', FSSLCertFile);
    FSSLKeyFile := Ini.ReadString('SSL', 'KeyFile', FSSLKeyFile);
    
    FLogLevel := Ini.ReadString('Logging', 'LogLevel', FLogLevel);
  finally
    Ini.Free;
  end;
end;

procedure TMCPConfig.SaveToFile(const AFileName: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AFileName);
  try
    Ini.WriteInteger('Server', 'Port', FPort);
    Ini.WriteString('Server', 'Host', FHost);
    Ini.WriteString('Server', 'Endpoint', FEndpoint);
    Ini.WriteInteger('Server', 'MaxConnections', FMaxConnections);
    
    Ini.WriteString('MCP', 'ServerName', FServerName);
    Ini.WriteString('MCP', 'ServerVersion', FServerVersion);
    Ini.WriteString('MCP', 'ProtocolVersion', '2024-11-05');
    
    Ini.WriteBool('CORS', 'Enabled', FEnableCORS);
    Ini.WriteString('CORS', 'AllowedOrigins', GetCORSOriginsString);
    
    Ini.WriteBool('SSL', 'Enabled', FEnableSSL);
    Ini.WriteString('SSL', 'CertFile', FSSLCertFile);
    Ini.WriteString('SSL', 'KeyFile', FSSLKeyFile);
    
    Ini.WriteString('Logging', 'LogLevel', FLogLevel);
  finally
    Ini.Free;
  end;
end;

procedure TMCPConfig.LoadFromStrings(const AStrings: TStrings);
var
  i: Integer;
  Key, Value: string;
begin
  for i := 0 to AStrings.Count - 1 do
  begin
    Key := Trim(AStrings.Names[i]);
    Value := Trim(AStrings.ValueFromIndex[i]);
    
    if SameText(Key, 'Port') then
      FPort := StrToIntDef(Value, FPort)
    else if SameText(Key, 'Host') then
      FHost := Value
    else if SameText(Key, 'ServerName') then
      FServerName := Value
    else if SameText(Key, 'ServerVersion') then
      FServerVersion := Value
    else if SameText(Key, 'Endpoint') then
      FEndpoint := Value
    else if SameText(Key, 'EnableCORS') then
      FEnableCORS := StrToBoolDef(Value, FEnableCORS)
    else if SameText(Key, 'CORSOrigins') then
    begin
      FCORSOrigins.Delimiter := ',';
      FCORSOrigins.StrictDelimiter := True;
      FCORSOrigins.DelimitedText := Value;
    end
    else if SameText(Key, 'EnableSSL') then
      FEnableSSL := StrToBoolDef(Value, FEnableSSL)
    else if SameText(Key, 'SSLCertFile') then
      FSSLCertFile := Value
    else if SameText(Key, 'SSLKeyFile') then
      FSSLKeyFile := Value
    else if SameText(Key, 'LogLevel') then
      FLogLevel := Value
    else if SameText(Key, 'MaxConnections') then
      FMaxConnections := StrToIntDef(Value, FMaxConnections);
  end;
end;

procedure TMCPConfig.SaveToStrings(const AStrings: TStrings);
begin
  AStrings.Clear;
  AStrings.Add('Port=' + IntToStr(FPort));
  AStrings.Add('Host=' + FHost);
  AStrings.Add('ServerName=' + FServerName);
  AStrings.Add('ServerVersion=' + FServerVersion);
  AStrings.Add('Endpoint=' + FEndpoint);
  AStrings.Add('EnableCORS=' + BoolToStr(FEnableCORS, True));
  AStrings.Add('CORSOrigins=' + GetCORSOriginsString);
  AStrings.Add('EnableSSL=' + BoolToStr(FEnableSSL, True));
  AStrings.Add('SSLCertFile=' + FSSLCertFile);
  AStrings.Add('SSLKeyFile=' + FSSLKeyFile);
  AStrings.Add('LogLevel=' + FLogLevel);
  AStrings.Add('MaxConnections=' + IntToStr(FMaxConnections));
end;

function TMCPConfig.GetCORSOriginsString: string;
begin
  FCORSOrigins.Delimiter := ',';
  FCORSOrigins.StrictDelimiter := True;
  Result := FCORSOrigins.DelimitedText;
end;

class function TMCPConfig.Default: TMCPConfig;
begin
  Result := TMCPConfig.Create;
end;

end.