{
  :: Implements hashes with Variant values.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtHashesVariants;

interface
uses
  Variants,

  X2UtHashes;

type
  {
    :$ Variant value class.
  }
  TX2HashVariantManager = class(TX2CustomHashManager)
  public
    procedure Finalize(var AData: Pointer); override;

    function DataSize(const AData: Pointer): Cardinal; override;

    function ToPointer(const AValue: Variant): Pointer; overload;
    function ToValue(const AData: Pointer): Variant; overload;

    function Compare(const AData: Pointer; const AValue: Pointer;
                     const ASize: Cardinal): Boolean; override;
  end;

  {
    :$ Pointer-to-Variant hash.
  }
  TX2PVHash     = class(TX2CustomPointerHash)
  private
    function GetCurrentValue(): Variant;
    function GetValue(Key: Pointer): Variant;
    procedure SetValue(Key: Pointer; const Value: Variant);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: Pointer]:    Variant read GetValue write SetValue; default;
  end;

  {
    :$ Integer-to-Variant hash.
  }
  TX2IVHash     = class(TX2CustomIntegerHash)
  private
    function GetCurrentValue(): Variant;
    function GetValue(Key: Integer): Variant;
    procedure SetValue(Key: Integer; const Value: Variant);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: Integer]:    Variant read GetValue write SetValue; default;
  end;

  {
    :$ Object-to-Variant hash.
  }
  TX2OVHash     = class(TX2CustomObjectHash)
  private
    function GetCurrentValue(): Variant;
    function GetValue(Key: TObject): Variant;
    procedure SetValue(Key: TObject; const Value: Variant);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: TObject]:    Variant read GetValue write SetValue; default;
  end;

  {
    :$ String-to-Variant hash.
  }
  TX2SVHash     = class(TX2CustomStringHash)
  private
    function GetCurrentValue(): Variant;
    function GetValue(Key: String): Variant;
    procedure SetValue(Key: String; const Value: Variant);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: String]:     Variant read GetValue write SetValue; default;
  end;

implementation

{========================================
  TX2HashVariantManager
========================================}
function TX2HashVariantManager.DataSize(const AData: Pointer): Cardinal;
begin
  Result  := SizeOf(Variant);
end;

procedure TX2HashVariantManager.Finalize(var AData: Pointer);
begin
  if AData <> nil then
    Dispose(PVariant(AData));

  inherited;
end;

function TX2HashVariantManager.ToPointer(const AValue: Variant): Pointer;
begin
  New(PVariant(Result));
  PVariant(Result)^ := AValue;
end;

function TX2HashVariantManager.ToValue(const AData: Pointer): Variant;
begin
  Result  := PVariant(AData)^;
end;

function TX2HashVariantManager.Compare(const AData, AValue: Pointer;
                                       const ASize: Cardinal): Boolean;
begin
  Result  := (VarCompareValue(PVariant(AData)^, PVariant(AValue)^) = vrEqual);
end;


{========================================
  TX2PVHash
========================================}
function TX2PVHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create();
end;

function TX2PVHash.GetCurrentValue(): Variant;
begin
  CursorRequired();
  Result  := TX2HashVariantManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2PVHash.GetValue(Key: Pointer): Variant;
var
  pItem:      PX2HashValue;

begin
  Result  := Unassigned;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashVariantManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2PVHash.SetValue(Key: Pointer; const Value: Variant);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashVariantManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2IVHash
========================================}
function TX2IVHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create();
end;

function TX2IVHash.GetCurrentValue(): Variant;
begin
  CursorRequired();
  Result  := TX2HashVariantManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2IVHash.GetValue(Key: Integer): Variant;
var
  pItem:      PX2HashValue;

begin
  Result  := Unassigned;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashVariantManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2IVHash.SetValue(Key: Integer; const Value: Variant);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashVariantManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2OVHash
========================================}
function TX2OVHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create();
end;

function TX2OVHash.GetCurrentValue(): Variant;
begin
  CursorRequired();
  Result  := TX2HashVariantManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2OVHash.GetValue(Key: TObject): Variant;
var
  pItem:      PX2HashValue;

begin
  Result  := Unassigned;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashVariantManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2OVHash.SetValue(Key: TObject; const Value: Variant);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashVariantManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2SVHash
========================================}
function TX2SVHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create();
end;

function TX2SVHash.GetCurrentValue(): Variant;
begin
  CursorRequired();
  Result  := TX2HashVariantManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2SVHash.GetValue(Key: String): Variant;
var
  pItem:      PX2HashValue;

begin
  Result  := Unassigned;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashVariantManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2SVHash.SetValue(Key: String; const Value: Variant);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashVariantManager(ValueManager).ToPointer(Value));
end;

end.
