unit FMain;

interface
uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  X2UtSingleInstance;

type
  TfrmMain = class(TForm, IX2InstanceNotifier)
    lblAppPath:                 TLabel;
    lblAppPathValue:            TLabel;
    lblAppVersion:              TLabel;
    lblAppVersionValue:         TLabel;
    lblInstances:               TLabel;
    lblOSVersion:               TLabel;
    lblOSVersionValue:          TLabel;
    lstInstances:               TListBox;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  protected
    // IX2InstanceNotifier implementation
    procedure OnInstance(const ACmdLine: String);
  end;

implementation
uses
  X2UtApp,
  X2UtOS;

{$R *.dfm}

{=============================== TfrmMain
  Initialization
========================================}
procedure TfrmMain.FormCreate;
begin
  lblAppPathValue.Caption     := App.Path;
  lblAppVersionValue.Caption  := App.FormatVersion();
  lblOSVersionValue.Caption   := OS.FormatVersion();

  RegisterInstance(Self);
end;

procedure TfrmMain.FormDestroy;
begin
  UnregisterInstance(Self);
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
