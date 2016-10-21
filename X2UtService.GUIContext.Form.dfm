object X2ServiceContextGUIForm: TX2ServiceContextGUIForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'X2ServiceContextGUIForm'
  ClientHeight = 177
  ClientWidth = 285
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  DesignSize = (
    285
    177)
  PixelsPerInch = 96
  TextHeight = 13
  object btnClose: TButton
    Left = 107
    Top = 144
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '&Close'
    TabOrder = 0
    ExplicitTop = 180
  end
  object gbStatus: TGroupBox
    AlignWithMargins = True
    Left = 8
    Top = 8
    Width = 269
    Height = 57
    Margins.Left = 8
    Margins.Top = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alTop
    Caption = ' Status '
    TabOrder = 1
    ExplicitWidth = 261
    object lblStatus: TLabel
      Left = 34
      Top = 26
      Width = 50
      Height = 13
      Caption = 'Starting...'
    end
    object Shape1: TShape
      Left = 12
      Top = 24
      Width = 16
      Height = 16
    end
  end
  object gbCustomControl: TGroupBox
    AlignWithMargins = True
    Left = 8
    Top = 73
    Width = 269
    Height = 60
    Margins.Left = 8
    Margins.Top = 8
    Margins.Right = 8
    Margins.Bottom = 0
    Align = alTop
    Caption = ' Custom control '
    TabOrder = 2
    DesignSize = (
      269
      60)
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
      Width = 102
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = '128'
      OnChange = edtControlCodeChange
      ExplicitWidth = 173
    end
    object btnSend: TButton
      Left = 180
      Top = 24
      Width = 75
      Height = 21
      Anchors = [akTop, akRight]
      Caption = '&Send'
      TabOrder = 1
      ExplicitLeft = 251
    end
  end
end
