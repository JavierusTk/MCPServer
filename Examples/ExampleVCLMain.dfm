object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MCP Server VCL Example'
  ClientHeight = 639
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 150
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 24
      Height = 13
      Caption = 'Port:'
    end
    object Label2: TLabel
      Left = 120
      Top = 16
      Width = 26
      Height = 13
      Caption = 'Host:'
    end
    object btnStart: TButton
      Left = 16
      Top = 48
      Width = 89
      Height = 25
      Caption = 'Start Server'
      TabOrder = 0
      OnClick = btnStartClick
    end
    object btnStop: TButton
      Left = 111
      Top = 48
      Width = 89
      Height = 25
      Caption = 'Stop Server'
      TabOrder = 1
      OnClick = btnStopClick
    end
    object edtPort: TEdit
      Left = 46
      Top = 13
      Width = 59
      Height = 21
      TabOrder = 2
      Text = '3001'
    end
    object edtHost: TEdit
      Left = 152
      Top = 13
      Width = 121
      Height = 21
      TabOrder = 3
      Text = 'localhost'
    end
    object GroupBox1: TGroupBox
      Left = 288
      Top = 8
      Width = 577
      Height = 121
      Caption = 'Connection Instructions'
      TabOrder = 4
      object MemoInstructions: TMemo
        Left = 8
        Top = 16
        Width = 561
        Height = 102
        BorderStyle = bsNone
        Color = clBtnFace
        Lines.Strings = (
          'Instructions will appear here...')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 620
    Width = 880
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = 'Server stopped'
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 150
    Width = 880
    Height = 470
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 2
    object TabSheet1: TTabSheet
      Caption = 'Log'
      object MemoLog: TMemo
        Left = 0
        Top = 0
        Width = 872
        Height = 442
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Tools'
      ImageIndex = 1
      object ListBoxTools: TListBox
        Left = 0
        Top = 41
        Width = 872
        Height = 401
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ItemHeight = 13
        ParentFont = False
        TabOrder = 0
      end
      object btnRefreshTools: TButton
        Left = 0
        Top = 0
        Width = 872
        Height = 41
        Align = alTop
        Caption = 'Refresh Tools List'
        TabOrder = 1
        OnClick = btnRefreshToolsClick
      end
    end
  end
end
