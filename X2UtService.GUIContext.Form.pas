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
    Shape1: TShape;
    gbCustomControl: TGroupBox;
    lblControlCode: TLabel;
    edtControlCode: TEdit;
    btnSend: TButton;

    procedure edtControlCodeChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FContext: IX2ServiceContext;
    FService: IX2Service;
  protected
    procedure DoShow; override;

    procedure CMAfterShow(var Msg: TMessage); message CM_AFTERSHOW;
  public
    property Context: IX2ServiceContext read FContext write FContext;
    property Service: IX2Service read FService write FService;
  end;


implementation
uses
  System.Math,
  System.SysUtils,
  Winapi.Windows;


{$R *.dfm}


// #ToDo1 -oMvR: 21-10-2016: separate service handling out to thread to prevent blocking of the UI


{ TX2ServiceContextGUIForm }
procedure TX2ServiceContextGUIForm.DoShow;
begin
  inherited DoShow;

  PostMessage(Self.Handle, CM_AFTERSHOW, 0, 0);
end;


procedure TX2ServiceContextGUIForm.CMAfterShow(var Msg: TMessage);
begin
  lblStatus.Caption := 'Starting...';
  lblStatus.Update;

  if Service.Start(Context) then
    lblStatus.Caption := 'Started'
  else
    lblStatus.Caption := 'Failed to start';
end;


procedure TX2ServiceContextGUIForm.edtControlCodeChange(Sender: TObject);
begin
  edtControlCode.Text := IntToStr(Min(Max(StrToIntDef(edtControlCode.Text, 0), 128), 255));
end;


procedure TX2ServiceContextGUIForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  lblStatus.Caption := 'Stopping...';
  lblStatus.Update;

  CanClose := Service.Stop;

  if not CanClose then
    lblStatus.Caption := 'Failed to stop';
end;

end.
