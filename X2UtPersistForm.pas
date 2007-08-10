{
  :: X2UtPersistForm provides functions to read and write form settings.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtPersistForm;

interface
uses
  Classes,
  Forms,
  Windows,

  X2UtPersistIntf;

  
type
  TX2FormPosSettings = class(TPersistent)
  private
    FHeight:      Integer;
    FLeft:        Integer;
    FMaximized:   Boolean;
    FTop:         Integer;
    FWidth:       Integer;
    
    function GetBounds(): TRect;
    procedure SetBounds(const Value: TRect);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure Assign(Source: TPersistent); override;

    property Bounds:    TRect   read GetBounds  write SetBounds;
  published
    property Maximized: Boolean read FMaximized write FMaximized;
    property Left:      Integer read FLeft      write FLeft;
    property Top:       Integer read FTop       write FTop;
    property Width:     Integer read FWidth     write FWidth;
    property Height:    Integer read FHeight    write FHeight;
  end;


  procedure ReadFormPos(const AReader: IX2PersistReader; const AForm: TCustomForm);
  procedure WriteFormPos(const AWriter: IX2PersistWriter; const AForm: TCustomForm);


implementation
uses
  MultiMon,
  SysUtils,
  Types,

  X2UtMisc;


type
  TProtectedCustomForm = class(TCustomForm);



procedure ReadFormPos(const AReader: IX2PersistReader; const AForm: TCustomForm);
var
  formPos:    TX2FormPosSettings;

begin
  formPos := TX2FormPosSettings.Create();
  try
    formPos.Assign(AForm);
    AReader.Read(formPos);
    AForm.Assign(formPos);
  finally
    FreeAndNil(formPos);
  end;
end;


procedure WriteFormPos(const AWriter: IX2PersistWriter; const AForm: TCustomForm);
var
  formPos:    TX2FormPosSettings;

begin
  formPos := TX2FormPosSettings.Create();
  try
    formPos.Assign(AForm);
    AWriter.Write(formPos);
  finally
    FreeAndNil(formPos);
  end;
end;


{ TX2FormPosSettings }
procedure TX2FormPosSettings.Assign(Source: TPersistent);
var
  sourceForm:   TProtectedCustomForm;
  placement:    TWindowPlacement;

begin
  if Source is TCustomForm then
  begin
    sourceForm  := TProtectedCustomForm(Source);
    FMaximized  := (sourceForm.WindowState = wsMaximized);

    FillChar(placement, SizeOf(TWindowPlacement), #0);
    placement.length  := SizeOf(TWindowPlacement);

    { Get the form's normal position independant of the maximized state }
    if GetWindowPlacement(sourceForm.Handle, @placement) then
      SetBounds(placement.rcNormalPosition);
  end else
    inherited;
end;


procedure TX2FormPosSettings.AssignTo(Dest: TPersistent);
var
  destForm:     TProtectedCustomForm;
  boundsRect:   TRect;

begin
  if Dest is TCustomForm then
  begin
    destForm    := TProtectedCustomForm(Dest);
    boundsRect  := Self.Bounds;

    { Make sure the window is at least partially visible }
    if MonitorFromRect(@boundsRect, MONITOR_DEFAULTTONULL) <> 0 then
    begin
      if FMaximized then
      begin
        destForm.WindowState  := wsMaximized;
      end else
      begin
        destForm.WindowState  := wsNormal;
        destForm.Position     := poDesigned;
        destForm.BoundsRect   := boundsRect;
      end;
    end;
  end else
    inherited;
end;


function TX2FormPosSettings.GetBounds(): TRect;
begin
  Result  := Rect(FLeft, FTop, FLeft + FWidth, FTop + FHeight);
end;


procedure TX2FormPosSettings.SetBounds(const Value: TRect);
begin
  FLeft   := Value.Left;
  FTop    := Value.Top;
  FWidth  := RectWidth(Value);
  FHeight := RectHeight(Value);
end;

end.
