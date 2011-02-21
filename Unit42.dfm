object Form42: TForm42
  Left = 0
  Top = 0
  Caption = 'Form42'
  ClientHeight = 606
  ClientWidth = 999
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object img1: TImage
    Left = 32
    Top = 32
    Width = 105
    Height = 105
    Stretch = True
  end
  object img2: TImage
    Left = 352
    Top = 32
    Width = 553
    Height = 361
  end
  object img3: TImage
    Left = 32
    Top = 160
    Width = 207
    Height = 217
    AutoSize = True
  end
  object btn1: TButton
    Left = 752
    Top = 496
    Width = 75
    Height = 25
    Caption = 'btn1'
    TabOrder = 0
    OnClick = btn1Click
  end
  object btn2: TButton
    Left = 752
    Top = 527
    Width = 75
    Height = 25
    Caption = 'btn2'
    TabOrder = 1
    OnClick = btn2Click
  end
  object btn3: TButton
    Left = 752
    Top = 560
    Width = 75
    Height = 25
    Caption = 'btn3'
    TabOrder = 2
    OnClick = btn3Click
  end
  object btn4: TButton
    Left = 24
    Top = 383
    Width = 75
    Height = 25
    Caption = 'Test1'
    TabOrder = 3
    OnClick = btn4Click
  end
  object Button1: TButton
    Left = 24
    Top = 414
    Width = 75
    Height = 25
    Caption = 'Test2'
    TabOrder = 4
    OnClick = Button1Click
  end
  object btn5: TButton
    Left = 143
    Top = 8
    Width = 209
    Height = 25
    Caption = 'Test Resize 4x8 B --> 512x512 B'
    TabOrder = 5
    OnClick = btn5Click
  end
  object rg1: TRadioGroup
    Left = 160
    Top = 47
    Width = 154
    Height = 107
    Caption = 'Wersje'
    ItemIndex = 0
    Items.Strings = (
      'ZrobBlinear1'
      'ZrobBlinear2'
      'ZrobBlinear3'
      'ZrobBlinear4'
      'ZrobBlinear5')
    TabOrder = 6
  end
  object btn6: TButton
    Left = 24
    Top = 445
    Width = 75
    Height = 25
    Caption = 'Test3'
    TabOrder = 7
    OnClick = btn6Click
  end
  object btn7: TButton
    Left = 24
    Top = 473
    Width = 75
    Height = 25
    Caption = 'Test4'
    TabOrder = 8
    OnClick = btn7Click
  end
  object btn8: TButton
    Left = 376
    Top = 456
    Width = 75
    Height = 25
    Caption = 'btn8'
    TabOrder = 9
    OnClick = btn8Click
  end
end
