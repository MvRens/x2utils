object frmBTree: TfrmBTree
  Left = 199
  Top = 107
  Width = 603
  Height = 410
  Caption = 'Binary Tree Debug'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ocTree: TdxOrgChart
    Left = 0
    Top = 0
    Width = 595
    Height = 383
    DefaultNodeWidth = 50
    BorderStyle = bsNone
    Options = [ocSelect, ocRect3D]
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = True
    OnDblClick = ocTreeDblClick
  end
end
