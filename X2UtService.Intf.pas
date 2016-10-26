unit X2UtService.Intf;

interface
uses
  Classes;


type
  TX2ServiceMode = (smService, smInteractive);


  IX2ServiceContext = interface
    ['{0AC283A7-B46C-4E4E-8F36-F8AA1272E04B}']
    function GetMode: TX2ServiceMode;

    property Mode: TX2ServiceMode read GetMode;
  end;


  IX2Service = interface
    ['{C8597906-87B8-444E-847B-37A034F72FFC}']
    function GetServiceName: string;
    function GetDisplayName: string;


    { Called when the service starts. Return True if succesful.
      Storing a reference to AContext is allowed, but must be released when Stop is called. }
    function Start(AContext: IX2ServiceContext): Boolean;

    { Called when the service is about to stop.
      Return True if succesful. }
    function Stop: Boolean;

    { Called for control codes in the user-defined range of 128 to 255. }
    function DoCustomControl(ACode: Byte): Boolean;


    property ServiceName: string read GetServiceName;
    property DisplayName: string read GetDisplayName;
  end;



  TX2ServiceCustomControlProc = reference to procedure(ACode: Byte; const ADescription: string);

  { Implement this to enable discovery of supported custom control codes
    for use in interactive contexts. }
  IX2ServiceCustomControl = interface
    ['{D6363AC5-3DD5-4897-90A7-6F63D82B6A74}']
    procedure EnumCustomControlCodes(Yield: TX2ServiceCustomControlProc);
  end;


  TX2CustomService = class(TInterfacedObject, IX2Service)
  private
    FContext: IX2ServiceContext;
  protected
    property Context: IX2ServiceContext read FContext;
  public
    { IX2Service }
    function GetServiceName: string; virtual; abstract;
    function GetDisplayName: string; virtual; abstract;

    function Start(AContext: IX2ServiceContext): Boolean; virtual;
    function Stop: Boolean; virtual;

    function DoCustomControl(ACode: Byte): Boolean; virtual;
  end;



implementation


{ TX2CustomService }
function TX2CustomService.Start(AContext: IX2ServiceContext): Boolean;
begin
  FContext := AContext;
  Result := True;
end;


function TX2CustomService.Stop: Boolean;
begin
  FContext := nil;
  Result := True;
end;


function TX2CustomService.DoCustomControl(ACode: Byte): Boolean;
begin
  Result := True;
end;

end.
