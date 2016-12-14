unit X2UtService.GUIContext;

interface
uses
  X2UtService.Intf;


type
  TX2ServiceContextGUI = class(TInterfacedObject, IX2ServiceContext)
  protected
    procedure StartService(AService: IX2Service); virtual;
  public
    constructor Create(AService: IX2Service);

    { IX2ServiceContext }
    function GetMode: TX2ServiceMode;
  end;


implementation
uses
  Vcl.Forms,

  X2UtService.GUIContext.Form;


{ TX2ServiceContextGUI }
constructor TX2ServiceContextGUI.Create(AService: IX2Service);
begin
  inherited Create;

  StartService(AService);
end;


function TX2ServiceContextGUI.GetMode: TX2ServiceMode;
begin
  Result := smInteractive;
end;


procedure TX2ServiceContextGUI.StartService(AService: IX2Service);
var
  serviceForm: TX2ServiceContextGUIForm;

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;

  Application.CreateForm(TX2ServiceContextGUIForm, serviceForm);
  serviceForm.Caption := AService.DisplayName;
  serviceForm.Context := Self;
  serviceForm.Service := AService;

  Application.Run;
end;

end.
