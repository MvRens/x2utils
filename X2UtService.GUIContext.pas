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
begin
  with TX2ServiceContextGUIForm.Create(nil) do
  try
    Caption := AService.DisplayName;
    Service := AService;

    ShowModal;
  finally
    Free;
  end;
end;

end.
