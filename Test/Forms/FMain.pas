unit FMain;

interface
uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  SysUtils,
  X2UtSingleInstance;

type
  TfrmMain = class(TForm, IX2InstanceNotifier)
    chkBytes:                   TCheckBox;
    chkXPManifest:              TCheckBox;
    lblAppPath:                 TLabel;
    lblAppPathValue:            TLabel;
    lblAppVersion:              TLabel;
    lblAppVersionValue:         TLabel;
    lblComCtlVersion:           TLabel;
    lblComCtlVersionValue:      TLabel;
    lblFormatSize:              TLabel;
    lblFormatSizeValue:         TLabel;
    lblInstances:               TLabel;
    lblOSVersion:               TLabel;
    lblOSVersionValue:          TLabel;
    lstInstances:               TListBox;
    txtSize:                    TEdit;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure txtSizeChange(Sender: TObject);
  protected
    // IX2InstanceNotifier implementation
    procedure OnInstance(const ACmdLine: String);
  end;

implementation
uses
  X2UtApp,
  X2UtOS,
  X2UtStrings;

{$R *.dfm}

// If you have a WinXP.RES which holds the XP manifest, you will
// notice that the Common Controls version changes to 6 instead of 5.
{.$R WinXP.RES}

{=============================== TfrmMain
  Initialization
========================================}
procedure TfrmMain.FormCreate;
begin
  Randomize();

  lblAppPathValue.Caption       := App.Path;
  lblAppVersionValue.Caption    := App.FormatVersion();
  lblOSVersionValue.Caption     := OS.FormatVersion();

  with OS.ComCtlVersion do
    lblComCtlVersionValue.Caption := Format('%d.%d build %d', [Major, Minor,
                                                               Build]);

  chkXPManifest.Checked         := OS.XPManifest;
  txtSize.Text                  := IntToStr(Random(MaxInt));

  RegisterInstance(Self);
end;

procedure TfrmMain.FormDestroy;
begin
  UnregisterInstance(Self);
end;



procedure TfrmMain.txtSizeChange;
var
  iSize:        Int64;

begin
  if TryStrToInt64(txtSize.Text, iSize) then
    lblFormatSizeValue.Caption  := FormatSize(iSize, chkBytes.Checked)
  else
    lblFormatSizeValue.Caption  := 'Not a valid integer.';
end;


{=============================== TfrmMain
  IX2InstanceNotifier implementation
========================================}
procedure TfrmMain.OnInstance;
var
  iParam:         Integer;

begin
  lstInstances.Items.Add('New instance found:');

  for iParam  := 0 to ParamCountEx(ACmdLine) do
    lstInstances.Items.Add('  ' + ParamStrEx(ACmdLine, iParam));

  lstInstances.ItemIndex  := lstInstances.Items.Count - 1;
end;

end.
