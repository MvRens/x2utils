program X2UtilsTest;

uses
  Forms,
  X2UtOS in '..\X2UtOS.pas',
  X2UtApp in '..\X2UtApp.pas',
  X2UtHandCursor in '..\X2UtHandCursor.pas',
  X2UtSingleInstance in '..\X2UtSingleInstance.pas',
  FMain in 'Forms\FMain.pas' {frmMain},
  X2UtStrings in '..\X2UtStrings.pas';

{$R *.res}

const
  CAppID  = '{DCAC19C4-1D7D-47C0-AD4E-2A1DA39824E0}';

var
  frmMain:    TfrmMain;

begin
  if not SingleInstance(CAppID) then
    exit;

  Application.Initialize;
  Application.Title := 'X²Utils Test';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
