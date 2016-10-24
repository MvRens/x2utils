unit X2UtService.ServiceContext;

interface
uses
  X2UtService.Intf;


type
  TX2ServiceContextService = class(TInterfacedObject, IX2ServiceContext)
  protected
    procedure StartService(AService: IX2Service); virtual;
  public
    class function IsInstallUninstall: Boolean;

    constructor Create(AService: IX2Service);

    { IX2ServiceContext }
    function GetMode: TX2ServiceMode;
  end;


implementation
uses
  System.Classes,
  System.SysUtils,
  Vcl.SvcMgr,

  X2UtElevation;


type
  TX2ServiceModule = class(TService)
  private
    FContext: IX2ServiceContext;
    FService: IX2Service;
  protected
    function GetServiceController: TServiceController; override;

    procedure HandleStart(Sender: TService; var Started: Boolean); virtual;
    procedure HandleStop(Sender: TService; var Stopped: Boolean); virtual;

    function DoCustomControl(CtrlCode: Cardinal): Boolean; override;

    property Context: IX2ServiceContext read FContext;
    property Service: IX2Service read FService;
  public
    constructor Create(AOwner: TComponent; AContext: IX2ServiceContext; AService: IX2Service); reintroduce;
  end;


var
  ServiceModuleInstance: TX2ServiceModule;


procedure ServiceController(CtrlCode: Cardinal); stdcall;
begin
  if Assigned(ServiceModuleInstance) then
    ServiceModuleInstance.Controller(CtrlCode);
end;



{ TX2ServiceContextService }
class function TX2ServiceContextService.IsInstallUninstall: Boolean;
begin
  Result := FindCmdLineSwitch('install', ['-', '/'], True) or
            FindCmdLineSwitch('uninstall', ['-', '/'], True);
end;


constructor TX2ServiceContextService.Create(AService: IX2Service);
begin
  inherited Create;

  if IsInstallUninstall and (not IsElevated) then
    raise Exception.Create('Elevation is required for install or uninstall');

  StartService(AService);
end;


function TX2ServiceContextService.GetMode: TX2ServiceMode;
begin
  Result := smService;
end;


procedure TX2ServiceContextService.StartService(AService: IX2Service);
begin
  if Assigned(ServiceModuleInstance) then
    raise EInvalidOperation.Create('An instance of TX2ServiceContextService is already running');

  Application.Initialize;
  ServiceModuleInstance := TX2ServiceModule.Create(Application, Self, AService);
  try
    ServiceModuleInstance.DisplayName := AService.DisplayName;
    ServiceModuleInstance.Name := AService.ServiceName;

    Application.Run;
  finally
    ServiceModuleInstance := nil;
  end;
end;


{ TX2ServiceModule }
constructor TX2ServiceModule.Create(AOwner: TComponent; AContext: IX2ServiceContext; AService: IX2Service);
begin
  // Skip default constructor to prevent DFM streaming
  CreateNew(AOwner);

  FContext := AContext;
  FService := AService;

  OnStart := HandleStart;
  OnStop := HandleStop;
end;


function TX2ServiceModule.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;


function TX2ServiceModule.DoCustomControl(CtrlCode: Cardinal): Boolean;
begin
  Result := True;

  if (CtrlCode >= 128) and (CtrlCode <= 255) then
    Result := Service.DoCustomControl(Byte(CtrlCode));
end;


procedure TX2ServiceModule.HandleStart(Sender: TService; var Started: Boolean);
begin
  Started := Service.Start(Context);
end;


procedure TX2ServiceModule.HandleStop(Sender: TService; var Stopped: Boolean);
begin
  Stopped := Service.Stop;
end;

end.
