unit X2UtService;

interface
uses
  X2UtService.Intf;


type
  TX2Service = class(TObject)
  public
    class function Run(AService: IX2Service): IX2ServiceContext;
  end;


  function IsUserInteractive: Boolean;


implementation
uses
  System.SysUtils,
  Winapi.Windows,

  X2UtService.GUIContext,
  X2UtService.ServiceContext;



function IsUserInteractive: Boolean;
var
  windowStation: HWINSTA;
  userObject: TUserObjectFlags;
  lengthNeeded: Cardinal;

begin
  Result := True;

  windowStation := GetProcessWindowStation;
  if windowStation <> 0 then
  begin
    lengthNeeded := 0;
    FillChar(userObject, SizeOf(userObject), 0);

    if GetUserObjectInformation(windowStation, UOI_FLAGS, @userObject, SizeOf(userObject), lengthNeeded) and
       ((userObject.dwFlags and WSF_VISIBLE) = 0) then
    begin
      Result := False;
    end;
  end;
end;



{ TX2Service }
class function TX2Service.Run(AService: IX2Service): IX2ServiceContext;
begin
  if TX2ServiceContextService.IsInstallUninstall or (not IsUserInteractive) then
    Result := TX2ServiceContextService.Create(AService)
  else
    Result := TX2ServiceContextGUI.Create(AService);
end;

end.
