program ExampleVCLApp;

uses
  Vcl.Forms,
  ExampleVCLMain in 'ExampleVCLMain.pas' {MainForm},
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