program ExampleVCLApp;

uses
  Vcl.Forms,
  ExampleVCLMain in 'ExampleVCLMain.pas' {MainForm},
  // Core MCP units
  MCPServer.Types in '..\Delphi-MCP-Server\src\Protocol\MCPServer.Types.pas',
  MCPServer.Serializer in '..\Delphi-MCP-Server\src\Protocol\MCPServer.Serializer.pas',
  MCPServer.Schema.Generator in '..\Delphi-MCP-Server\src\Protocol\MCPServer.Schema.Generator.pas',
  MCPServer.Logger in '..\Delphi-MCP-Server\src\Core\MCPServer.Logger.pas',
  MCPServer.Settings in '..\Delphi-MCP-Server\src\Core\MCPServer.Settings.pas',
  MCPServer.Registration in '..\Delphi-MCP-Server\src\Core\MCPServer.Registration.pas',
  MCPServer.ManagerRegistry in '..\Delphi-MCP-Server\src\Core\MCPServer.ManagerRegistry.pas',
  MCPServer.Tool.Base in '..\Delphi-MCP-Server\src\Tools\MCPServer.Tool.Base.pas',
  MCPServer.Resource.Base in '..\Delphi-MCP-Server\src\Resources\MCPServer.Resource.Base.pas',
  MCPServer.IdHTTPServer in '..\Delphi-MCP-Server\src\Server\MCPServer.IdHTTPServer.pas',
  MCPServer.CoreManager in '..\Delphi-MCP-Server\src\Managers\MCPServer.CoreManager.pas',
  MCPServer.ToolsManager in '..\Delphi-MCP-Server\src\Managers\MCPServer.ToolsManager.pas',
  MCPServer.ResourcesManager in '..\Delphi-MCP-Server\src\Managers\MCPServer.ResourcesManager.pas',
  MCPServer.Resource.Server in '..\Delphi-MCP-Server\src\Resources\MCPServer.Resource.Server.pas',
  // Our MCP Engine
  MCPServer.Engine in 'MCPServer.Engine.pas',
  MCPServer.Config in 'MCPServer.Config.pas',
  MCPServer.VCL.Adapter in 'MCPServer.VCL.Adapter.pas',
  // Custom tools
  MCPServer.Tool.HelloCyberMax in 'Tools\MCPServer.Tool.HelloCyberMax.pas',
  MCPServer.Tool.CyberEcho in 'Tools\MCPServer.Tool.CyberEcho.pas',
  MCPServer.Tool.CyberTime in 'Tools\MCPServer.Tool.CyberTime.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.