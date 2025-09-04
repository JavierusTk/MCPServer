unit MCPServer.Tool.HelloCyberMax;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  MCPServer.Tool.Base,
  MCPServer.Types;

type
  THelloCyberMaxParams = class
    // No parameters needed for this tool
  end;

  THelloCyberMaxTool = class(TMCPToolBase<THelloCyberMaxParams>)
  private
    function GetAvailableModules: string;
  protected
    function ExecuteWithParams(const Params: THelloCyberMaxParams): string; override;
  public
    constructor Create; override;
  end;

implementation

uses
  MCPServer.Registration;

{ THelloCyberMaxTool }

constructor THelloCyberMaxTool.Create;
begin
  inherited;
  FName := 'hello_cybermax';
  FDescription := 'Get a greeting from CyberMAX MCP Server and list available modules';
end;

function THelloCyberMaxTool.GetAvailableModules: string;
var
  Modules: TStringList;
begin
  Modules := TStringList.Create;
  try
    // Check which CyberMAX modules exist
    if TDirectory.Exists('W:\TCConta') then
      Modules.Add('  - TCConta (Contabilidad/Accounting)');
      
    if TDirectory.Exists('W:\Gestion2000') then
      Modules.Add('  - Gestion2000 (Ventas y Compras/Sales & Purchasing)');
      
    if TDirectory.Exists('W:\Almacen') then
      Modules.Add('  - Almacen (Warehouse Management)');
      
    if TDirectory.Exists('W:\Producción') then
      Modules.Add('  - Producción (Manufacturing)');
      
    if TDirectory.Exists('W:\Proyectos') then
      Modules.Add('  - Proyectos (Project Management)');
      
    if TDirectory.Exists('W:\Personal') then
      Modules.Add('  - Personal (Human Resources)');
      
    if TDirectory.Exists('W:\CRM') then
      Modules.Add('  - CRM (Customer Relationship Management)');
      
    if TDirectory.Exists('W:\Clientes\EOLO') then
      Modules.Add('  - EOLO (Aviation Framework)');
      
    if Modules.Count = 0 then
      Result := 'No CyberMAX modules found in standard locations.'
    else
      Result := 'Available CyberMAX Modules:' + sLineBreak + Modules.Text;
  finally
    Modules.Free;
  end;
end;

function THelloCyberMaxTool.ExecuteWithParams(const Params: THelloCyberMaxParams): string;
var
  Response: TStringList;
begin
  Response := TStringList.Create;
  try
    Response.Add('========================================');
    Response.Add('¡Hola desde CyberMAX MCP Server!');
    Response.Add('========================================');
    Response.Add('');
    Response.Add('This is a Model Context Protocol server');
    Response.Add('designed to explore and document the');
    Response.Add('CyberMAX ERP system.');
    Response.Add('');
    Response.Add('Server Version: 1.0.0');
    Response.Add('MCP Protocol: 2024-11-05');
    Response.Add('');
    Response.Add(GetAvailableModules);
    Response.Add('');
    Response.Add('Ready to assist with CyberMAX exploration!');
    Response.Add('========================================');
    
    Result := Response.Text;
  finally
    Response.Free;
  end;
end;

initialization
  TMCPRegistry.RegisterTool('hello_cybermax',
    function: IMCPTool
    begin
      Result := THelloCyberMaxTool.Create;
    end
  );

end.