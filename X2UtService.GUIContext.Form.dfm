object X2ServiceContextGUIForm: TX2ServiceContextGUIForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'X2ServiceContextGUIForm'
  ClientHeight = 204
  ClientWidth = 439
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    439
    204)
  PixelsPerInch = 96
  TextHeight = 13
  object btnClose: TButton
    Left = 8
    Top = 171
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '&Close'
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object gbStatus: TGroupBox
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 423
    Height = 57
    Margins.Left = 8
    Margins.Top = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alTop
    Caption = ' Status '
    TabOrder = 1
    ExplicitWidth = 358
    object lblStatus: TLabel
      Left = 34
      Top = 26
      Width = 50
      Height = 13
      Caption = 'Starting...'
    end
    object shpStatus: TShape
      Left = 12
      Top = 24
      Width = 16
      Height = 16
      Brush.Color = 33023
      Shape = stCircle
    end
  end
  object gbCustomControl: TGroupBox
    AlignWithMargins = True
    Left = 8
    Top = 73
    Width = 423
    Height = 88
    Margins.Left = 8
    Margins.Top = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alTop
    Caption = ' Custom control '
    TabOrder = 2
    ExplicitWidth = 358
    DesignSize = (
      423
      88)
    object lblControlCode: TLabel
      Left = 12
      Top = 27
      Width = 25
      Height = 13
      Caption = 'Code'
    end
    object edtControlCode: TEdit
      Left = 72
      Top = 24
      Width = 256
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = '128'
      OnChange = edtControlCodeChange
      ExplicitWidth = 191
    end
    object btnSend: TButton
      Left = 334
      Top = 24
      Width = 75
      Height = 21
      Anchors = [akTop, akRight]
      Caption = '&Send'
      TabOrder = 1
      OnClick = btnSendClick
      ExplicitLeft = 269
    end
    object cmbControlCodePredefined: TComboBox
      Left = 72
      Top = 51
      Width = 256
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      ExplicitWidth = 220
    end
    object btnSendPredefined: TButton
      Left = 334
      Top = 51
      Width = 75
      Height = 21
      Anchors = [akTop, akRight]
      Caption = '&Send'
      TabOrder = 3
      OnClick = btnSendPredefinedClick
      ExplicitLeft = 269
    end
  end
end
