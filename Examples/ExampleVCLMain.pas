unit ExampleVCLMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  MCPServer.Engine;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    btnStart: TButton;
    btnStop: TButton;
    edtPort: TEdit;
    Label1: TLabel;
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    MemoLog: TMemo;
    TabSheet2: TTabSheet;
    ListBoxTools: TListBox;
    Label2: TLabel;
    edtHost: TEdit;
    Label3: TLabel;
    btnRefreshTools: TButton;
    GroupBox1: TGroupBox;
    MemoInstructions: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnRefreshToolsClick(Sender: TObject);
  private
    FMCPEngine: TMCPEngineVCL;
    procedure UpdateUI;
    procedure OnMCPLog(Sender: TObject; const Level, Message: string);
    procedure OnMCPStarted(Sender: TObject);
    procedure OnMCPStopped(Sender: TObject);
    procedure OnMCPError(Sender: TObject; const Error: Exception);
    procedure RefreshToolsList;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Create the MCP Engine VCL component
  FMCPEngine := TMCPEngineVCL.Create(Self);
  FMCPEngine.OnLog := OnMCPLog;
  FMCPEngine.OnStarted := OnMCPStarted;
  FMCPEngine.OnStopped := OnMCPStopped;
  FMCPEngine.OnError := OnMCPError;
  
  // Set default values
  edtPort.Text := '3001';
  edtHost.Text := 'localhost';
  
  // Setup instructions
  MemoInstructions.Lines.Clear;
  MemoInstructions.Lines.Add('MCP Server VCL Example');
  MemoInstructions.Lines.Add('======================');
  MemoInstructions.Lines.Add('');
  MemoInstructions.Lines.Add('1. Enter port and host');
  MemoInstructions.Lines.Add('2. Click Start to run the MCP server');
  MemoInstructions.Lines.Add('3. Connect from Claude Code:');
  MemoInstructions.Lines.Add('');
  MemoInstructions.Lines.Add('claude mcp add vcl-example \');
  MemoInstructions.Lines.Add('  http://localhost:3001/mcp \');
  MemoInstructions.Lines.Add('  --scope user -t http');
  MemoInstructions.Lines.Add('');
  MemoInstructions.Lines.Add('4. Use the tools in Claude Code');
  MemoInstructions.Lines.Add('5. Watch the logs in the Log tab');
  
  UpdateUI;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if FMCPEngine.Active then
    FMCPEngine.Stop;
  FMCPEngine.Free;
end;

procedure TMainForm.btnStartClick(Sender: TObject);
begin
  try
    FMCPEngine.Port := StrToIntDef(edtPort.Text, 3001);
    FMCPEngine.Host := edtHost.Text;
    FMCPEngine.ServerName := 'VCL Example MCP Server';
    FMCPEngine.ServerVersion := '1.0.0';
    FMCPEngine.Start;
    
    RefreshToolsList;
    UpdateUI;
    
    // Update instructions with actual connection string
    MemoInstructions.Lines[7] := Format('claude mcp add vcl-example \', []);
    MemoInstructions.Lines[8] := Format('  http://%s:%s/mcp \', [edtHost.Text, edtPort.Text]);
    
  except
    on E: Exception do
    begin
      ShowMessage('Failed to start server: ' + E.Message);
      UpdateUI;
    end;
  end;
end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
  try
    FMCPEngine.Stop;
    UpdateUI;
  except
    on E: Exception do
    begin
      ShowMessage('Failed to stop server: ' + E.Message);
      UpdateUI;
    end;
  end;
end;

procedure TMainForm.btnRefreshToolsClick(Sender: TObject);
begin
  RefreshToolsList;
end;

procedure TMainForm.RefreshToolsList;
var
  Tools: TArray<string>;
  Tool: string;
begin
  ListBoxTools.Items.Clear;
  
  if not FMCPEngine.Active then
  begin
    ListBoxTools.Items.Add('(Server not running)');
    Exit;
  end;
  
  Tools := FMCPEngine.GetRegisteredTools;
  
  if Length(Tools) = 0 then
  begin
    ListBoxTools.Items.Add('(No tools registered)');
  end
  else
  begin
    for Tool in Tools do
      ListBoxTools.Items.Add('• ' + Tool);
  end;
end;

procedure TMainForm.UpdateUI;
begin
  btnStart.Enabled := not FMCPEngine.Active;
  btnStop.Enabled := FMCPEngine.Active;
  edtPort.Enabled := not FMCPEngine.Active;
  edtHost.Enabled := not FMCPEngine.Active;
  
  if FMCPEngine.Active then
  begin
    StatusBar1.SimpleText := Format('Server running on %s:%d', 
      [FMCPEngine.Host, FMCPEngine.Port]);
    StatusBar1.Color := clMoneyGreen;
  end
  else
  begin
    StatusBar1.SimpleText := 'Server stopped';
    StatusBar1.Color := clBtnFace;
  end;
end;

procedure TMainForm.OnMCPLog(Sender: TObject; const Level, Message: string);
begin
  FMCPEngine.LogToMemo(MemoLog, Level, Message);
end;

procedure TMainForm.OnMCPStarted(Sender: TObject);
begin
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('=== SERVER STARTED ===');
  MemoLog.Lines.Add('');
  UpdateUI;
end;

procedure TMainForm.OnMCPStopped(Sender: TObject);
begin
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('=== SERVER STOPPED ===');
  MemoLog.Lines.Add('');
  UpdateUI;
end;

procedure TMainForm.OnMCPError(Sender: TObject; const Error: Exception);
begin
  MemoLog.Lines.Add('');
  MemoLog.Lines.Add('!!! ERROR: ' + Error.Message);
  MemoLog.Lines.Add('');
  ShowMessage('MCP Error: ' + Error.Message);
end;

end.