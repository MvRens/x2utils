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
    lblAppPath:                 TLabel;
    lblAppPathValue:            TLabel;
    lblAppVersion:              TLabel;
    lblAppVersionValue:         TLabel;
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

{=============================== TfrmMain
  Initialization
========================================}
procedure TfrmMain.FormCreate;
begin
  Randomize();
  
  lblAppPathValue.Caption     := App.Path;
  lblAppVersionValue.Caption  := App.FormatVersion();
  lblOSVersionValue.Caption   := OS.FormatVersion();
  txtSize.Text                := IntToStr(Random(MaxInt));

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
