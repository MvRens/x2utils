object frmMain: TfrmMain
  Left = 339
  Top = 239
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'X'#178'Utils Test'
  ClientHeight = 245
  ClientWidth = 455
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblAppPath: TLabel
    Left = 8
    Top = 12
    Width = 79
    Height = 13
    Caption = 'Application path:'
  end
  object lblAppVersion: TLabel
    Left = 8
    Top = 36
    Width = 92
    Height = 13
    Caption = 'Application version:'
  end
  object lblOSVersion: TLabel
    Left = 8
    Top = 60
    Width = 55
    Height = 13
    Caption = 'OS version:'
  end
  object lblAppPathValue: TLabel
    Left = 112
    Top = 12
    Width = 337
    Height = 13
    AutoSize = False
    Caption = '<unknown>'
  end
  object lblAppVersionValue: TLabel
    Left = 112
    Top = 36
    Width = 337
    Height = 13
    AutoSize = False
    Caption = '<unknown>'
  end
  object lblOSVersionValue: TLabel
    Left = 112
    Top = 60
    Width = 337
    Height = 13
    AutoSize = False
    Caption = '<unknown>'
  end
  object lblInstances: TLabel
    Left = 8
    Top = 128
    Width = 49
    Height = 13
    Caption = 'Instances:'
  end
  object lblFormatSize: TLabel
    Left = 8
    Top = 204
    Width = 56
    Height = 13
    Caption = 'Format size:'
  end
  object lblFormatSizeValue: TLabel
    Left = 244
    Top = 204
    Width = 205
    Height = 13
    AutoSize = False
    Caption = '<unknown>'
  end
  object lblComCtlVersionValue: TLabel
    Left = 112
    Top = 84
    Width = 333
    Height = 13
    AutoSize = False
    Caption = '<unknown>'
  end
  object lblComCtlVersion: TLabel
    Left = 8
    Top = 84
    Width = 73
    Height = 13
    Caption = 'ComCtl version:'
  end
  object lstInstances: TListBox
    Left = 112
    Top = 128
    Width = 337
    Height = 65
    ItemHeight = 13
    TabOrder = 0
  end
  object txtSize: TEdit
    Left = 112
    Top = 200
    Width = 121
    Height = 21
    TabOrder = 1
    OnChange = txtSizeChange
  end
  object chkBytes: TCheckBox
    Left = 112
    Top = 224
    Width = 97
    Height = 17
    Caption = '&Keep bytes'
    TabOrder = 2
    OnClick = txtSizeChange
  end
  object chkXPManifest: TCheckBox
    Left = 112
    Top = 104
    Width = 337
    Height = 17
    Caption = 'XP Manifest'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
end
