unit X2UtService.GUIContext.Form;

interface
uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Winapi.Messages,

  X2UtService.Intf;


const
  CM_AFTERSHOW = WM_USER + 1;

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

    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtControlCodeChange(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FContext: IX2ServiceContext;
    FService: IX2Service;
  protected
    procedure DoShow; override;

    procedure CMAfterShow(var Msg: TMessage); message CM_AFTERSHOW;

    function GetControlCode: Byte;
  public
    property Context: IX2ServiceContext read FContext write FContext;
    property Service: IX2Service read FService write FService;
  end;


implementation
uses
  System.Math,
  System.SysUtils,
  Vcl.Graphics,
  Winapi.Windows;


{$R *.dfm}


const
  StatusColorStarting = $00B0FFB0;
  StatusColorStarted = clGreen;
  StatusColorStopping = $008080FF;
  StatusColorStopped = clRed;


// #ToDo1 -oMvR: 21-10-2016: separate service handling out to thread to prevent blocking of the UI


{ TX2ServiceContextGUIForm }
procedure TX2ServiceContextGUIForm.DoShow;
begin
  inherited DoShow;

  PostMessage(Self.Handle, CM_AFTERSHOW, 0, 0);
end;


procedure TX2ServiceContextGUIForm.CMAfterShow(var Msg: TMessage);
begin
  shpStatus.Brush.Color := StatusColorStarting;
  lblStatus.Caption := 'Starting...';
  Application.ProcessMessages;

  if Service.Start(Context) then
  begin
    shpStatus.Brush.Color := StatusColorStarted;
    lblStatus.Caption := 'Started';
  end else
  begin
    shpStatus.Brush.Color := StatusColorStopped;
    lblStatus.Caption := 'Failed to start';
  end;
end;


procedure TX2ServiceContextGUIForm.edtControlCodeChange(Sender: TObject);
begin
  edtControlCode.Text := IntToStr(GetControlCode);
end;


procedure TX2ServiceContextGUIForm.btnSendClick(Sender: TObject);
begin
  Service.DoCustomControl(GetControlCode);
end;


procedure TX2ServiceContextGUIForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;


procedure TX2ServiceContextGUIForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  shpStatus.Brush.Color := StatusColorStopping;
  lblStatus.Caption := 'Stopping...';
  Application.ProcessMessages;

  CanClose := Service.Stop;

  if not CanClose then
    lblStatus.Caption := 'Failed to stop';
end;


function TX2ServiceContextGUIForm.GetControlCode: Byte;
begin
  Result := Byte(Min(Max(StrToIntDef(edtControlCode.Text, 0), 128), 255));
end;

end.
