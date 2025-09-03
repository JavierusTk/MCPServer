unit MCPServer.Tool.CyberEcho;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  MCPServer.Tool.Base,
  MCPServer.Types;

type
  TCyberEchoParams = class
  private
    FMessage: string;
    FUpperCase: Boolean;
  public
    constructor Create;
    [SchemaDescription('The message to echo back')]
    property Message: string read FMessage write FMessage;
    
    [Optional]
    [SchemaDescription('Convert message to uppercase before echoing')]
    property UpperCase: Boolean read FUpperCase write FUpperCase;
  end;

  TCyberEchoTool = class(TMCPToolBase<TCyberEchoParams>)
  protected
    function ExecuteWithParams(const Params: TCyberEchoParams): string; override;
  public
    constructor Create; override;
  end;

implementation

uses
  MCPServer.Registration;

{ TCyberEchoParams }

constructor TCyberEchoParams.Create;
begin
  inherited;
  FMessage := '';
  FUpperCase := False;
end;

{ TCyberEchoTool }

constructor TCyberEchoTool.Create;
begin
  inherited;
  FName := 'cyber_echo';
  FDescription := 'Echo back the provided message, optionally in uppercase';
end;

function TCyberEchoTool.ExecuteWithParams(const Params: TCyberEchoParams): string;
var
  Response: TStringList;
  ProcessedMessage: string;
begin
  Response := TStringList.Create;
  try
    // Validate params
    if not Assigned(Params) then
    begin
      Result := 'Error: No parameters provided';
      Exit;
    end;
    
    if Params.Message = '' then
    begin
      Result := 'Error: No message provided to echo';
      Exit;
    end;
    
    // Process message based on UpperCase property
    if Params.UpperCase then
      ProcessedMessage := System.SysUtils.UpperCase(Params.Message)
    else
      ProcessedMessage := Params.Message;
    
    Response.Add('===== CyberMAX Echo Tool =====');
    Response.Add('');
    Response.Add('Original message: ' + Params.Message);
    if Params.UpperCase then
      Response.Add('Uppercase mode: Enabled')
    else
      Response.Add('Uppercase mode: Disabled');
    Response.Add('');
    Response.Add('Echo: ' + ProcessedMessage);
    Response.Add('');
    Response.Add('Message length: ' + IntToStr(Length(Params.Message)) + ' characters');
    Response.Add('Timestamp: ' + DateTimeToStr(Now));
    Response.Add('==============================');
    
    Result := Response.Text;
  finally
    Response.Free;
  end;
end;

initialization
  TMCPRegistry.RegisterTool('cyber_echo',
    function: IMCPTool
    begin
      Result := TCyberEchoTool.Create;
    end
  );

end.