unit X2UtService.GUIContext.Form;

interface
uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Winapi.Messages,

  X2UtService.Intf;


type
  TX2ServiceContextGUIForm = class(TForm)
    btnClose: TButton;
    gbStatus: TGroupBox;
    lblStatus: TLabel;
    shpStatus: TShape;
    gbCustomControl: TGroupBox;
    lblControlCode: TLabel;
    edtControlCode: TEdit;
    btnSend: TButton;
    cmbControlCodePredefined: TComboBox;
    btnSendPredefined: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtControlCodeChange(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnSendPredefinedClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FContext: IX2ServiceContext;
    FService: IX2Service;
    FServiceThread: TThread;
    FAllowClose: Boolean;
  protected
    procedure DoShow; override;

    procedure UpdatePredefinedControlCodes; virtual;

    function GetControlCode: Byte;
    procedure SetStatus(const AMessage: string; AColor: TColor);

    property ServiceThread: TThread read FServiceThread;
  public
    destructor Destroy; override;
    
    property Context: IX2ServiceContext read FContext write FContext;
    property Service: IX2Service read FService write FService;
  end;


implementation
uses
  System.Generics.Collections,
  System.Math,
  System.SyncObjs,
  System.SysUtils,
  Winapi.Windows;


{$R *.dfm}


const
  StatusColorStarting = $00B0FFB0;
  StatusColorStarted = clGreen;
  StatusColorStopping = $008080FF;
  StatusColorStopped = clRed;


type
  TX2ServiceThread = class(TThread)
  private
    FContext: IX2ServiceContext;
    FService: IX2Service;
    FWakeEvent: TEvent;
    FSendCodeList: TList<Integer>;

    FOnStarted: TThreadProcedure;
    FOnStartFailed: TThreadProcedure;
    FOnStopped: TThreadProcedure;
    FOnStopFailed: TThreadProcedure;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;

    procedure FlushSendCodeList;

    property Context: IX2ServiceContext read FContext;
    property Service: IX2Service read FService;
    property WakeEvent: TEvent read FWakeEvent;
  public
    constructor Create(AContext: IX2ServiceContext; AService: IX2Service);
    destructor Destroy; override;

    procedure SendControlCode(ACode: Byte);

    property OnStarted: TThreadProcedure read FOnStarted write FOnStarted;
    property OnStartFailed: TThreadProcedure read FOnStartFailed write FOnStartFailed;
    property OnStopped: TThreadProcedure read FOnStopped write FOnStopped;
    property OnStopFailed: TThreadProcedure read FOnStopFailed write FOnStopFailed;
  end;



{ TX2ServiceContextGUIForm }
procedure TX2ServiceContextGUIForm.FormCreate(Sender: TObject);
begin
  btnClose.Left := (ClientWidth - btnClose.Width) div 2;
end;

destructor TX2ServiceContextGUIForm.Destroy;
begin
  if Assigned(FServiceThread) then
    FreeAndNil(FServiceThread);
  inherited Destroy;
end;

procedure TX2ServiceContextGUIForm.DoShow;
var
  serviceThread: TX2ServiceThread;
begin
  inherited DoShow;

  if not Assigned(FServiceThread) then
  begin
    UpdatePredefinedControlCodes;

    SetStatus('Starting...', StatusColorStarting);
    serviceThread := TX2ServiceThread.Create(Context, Service);
    serviceThread.OnStarted :=
      procedure
      begin
        SetStatus('Started', StatusColorStarted);
      end;

    serviceThread.OnStartFailed :=
      procedure
      begin
        SetStatus('Start failed', StatusColorStopped);
        FServiceThread := nil;
      end;

    serviceThread.OnStopped :=
      procedure
      begin
        SetStatus('Stopped', StatusColorStopped);

        FAllowClose := True;
        Close;
      end;

    serviceThread.OnStopFailed :=
      procedure
      begin
        SetStatus('Stop failed', StatusColorStarted);
      end;

    FServiceThread := serviceThread;
    FServiceThread.Start;
  end;
end;



procedure TX2ServiceContextGUIForm.edtControlCodeChange(Sender: TObject);
begin
  edtControlCode.Text := IntToStr(GetControlCode);
end;


procedure TX2ServiceContextGUIForm.btnSendClick(Sender: TObject);
begin
  (ServiceThread as TX2ServiceThread).SendControlCode(GetControlCode);
end;


procedure TX2ServiceContextGUIForm.btnSendPredefinedClick(Sender: TObject);
var
  code: Byte;

begin
  if cmbControlCodePredefined.ItemIndex > -1 then
  begin
    code := Byte(cmbControlCodePredefined.Items.Objects[cmbControlCodePredefined.ItemIndex]);
    (ServiceThread as TX2ServiceThread).SendControlCode(code);
  end;
end;


procedure TX2ServiceContextGUIForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;


procedure TX2ServiceContextGUIForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not FAllowClose then
  begin
    SetStatus('Stopping...', StatusColorStopping);
    CanClose := False;

    ServiceThread.Terminate;
  end;
end;


procedure TX2ServiceContextGUIForm.UpdatePredefinedControlCodes;
var
  serviceCustomControl: IX2ServiceCustomControl;

begin
  cmbControlCodePredefined.Items.Clear;

  if Supports(Service, IX2ServiceCustomControl, serviceCustomControl) then
  begin
    serviceCustomControl.EnumCustomControlCodes(
      procedure(ACode: Byte; const ADescription: string)
      begin
        cmbControlCodePredefined.Items.AddObject(Format('%s (%d)', [ADescription, ACode]), TObject(ACode));
      end);

    cmbControlCodePredefined.Enabled := True;
    cmbControlCodePredefined.ItemIndex := 0;
    btnSendPredefined.Enabled := cmbControlCodePredefined.Items.Count > 0;
  end else
  begin
    cmbControlCodePredefined.Enabled := False;
    btnSendPredefined.Enabled := False;
  end;
end;


function TX2ServiceContextGUIForm.GetControlCode: Byte;
begin
  Result := Byte(Min(Max(StrToIntDef(edtControlCode.Text, 0), 128), 255));
end;


procedure TX2ServiceContextGUIForm.SetStatus(const AMessage: string; AColor: TColor);
begin
  shpStatus.Brush.Color := AColor;
  lblStatus.Caption := AMessage;
end;


{ TX2ServiceThread }
constructor TX2ServiceThread.Create(AContext: IX2ServiceContext; AService: IX2Service);
begin
  inherited Create(True);

  FContext := AContext;
  FService := AService;

  FWakeEvent := TEvent.Create(nil, False, False, '');
  FSendCodeList := TList<Integer>.Create;
end;


destructor TX2ServiceThread.Destroy;
begin
  FreeAndNil(FWakeEvent);
  FreeAndNil(FSendCodeList);

  inherited Destroy;
end;


procedure TX2ServiceThread.Execute;
begin
  try
    Service.Start(Context);
  except
    if Assigned(FOnStartFailed) then
      Synchronize(FOnStartFailed);

    exit;
  end;

  if Assigned(FOnStarted) then
    Synchronize(FOnStarted);

  while True do
  begin
    try
      WakeEvent.WaitFor(INFINITE);

      if Terminated then
      begin
        Service.Stop;

        if Assigned(FOnStopped) then
          Synchronize(FOnStopped);

        break;
      end;

      FlushSendCodeList;
    except
      if Assigned(FOnStopFailed) then
        Synchronize(FOnStopFailed);
    end;
  end;
end;


procedure TX2ServiceThread.FlushSendCodeList;
var
  code: Byte;

begin
  System.TMonitor.Enter(FSendCodeList);
  try
    for code in FSendCodeList do
      Service.DoCustomControl(code);

    FSendCodeList.Clear;
  finally
    System.TMonitor.Exit(FSendCodeList);
  end;
end;


procedure TX2ServiceThread.TerminatedSet;
begin
  inherited TerminatedSet;

  WakeEvent.SetEvent;
end;


procedure TX2ServiceThread.SendControlCode(ACode: Byte);
begin
  System.TMonitor.Enter(FSendCodeList);
  try
    FSendCodeList.Add(ACode);
  finally
    System.TMonitor.Exit(FSendCodeList);
  end;

  WakeEvent.SetEvent;
end;

end.
