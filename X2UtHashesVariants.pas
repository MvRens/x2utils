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
    procedure FreeCookie(var ACookie: PX2HashCookie); override;

    function CreateCookie(const AValue: Variant): PX2HashCookie; overload;
    function GetValue(const ACookie: PX2HashCookie): Variant; overload;

    function Hash(ACookie: PX2HashCookie): Cardinal; override;
    function Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean; override;
    function Clone(const ACookie: PX2HashCookie): PX2HashCookie; override;
  end;


  {
    :$ Pointer-to-Variant hash.
  }
  TX2PVHash     = class(TX2CustomPointerHash)
  private
    function GetCurrentValue: Variant;
    function GetValue(Key: Pointer): Variant;
    procedure SetValue(Key: Pointer; const Value: Variant);
    function GetValueManager: TX2HashVariantManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashVariantManager read GetValueManager;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: Pointer]:    Variant read GetValue write SetValue; default;
  end;


  {
    :$ Integer-to-Variant hash.
  }
  TX2IVHash     = class(TX2CustomIntegerHash)
  private
    function GetCurrentValue: Variant;
    function GetValue(Key: Integer): Variant;
    procedure SetValue(Key: Integer; const Value: Variant);
    function GetValueManager: TX2HashVariantManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashVariantManager read GetValueManager;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: Integer]:    Variant read GetValue write SetValue; default;
  end;


  {
    :$ Object-to-Variant hash.
  }
  TX2OVHash     = class(TX2CustomObjectHash)
  private
    function GetCurrentValue: Variant;
    function GetValue(Key: TObject): Variant;
    procedure SetValue(Key: TObject; const Value: Variant);
    function GetValueManager: TX2HashVariantManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashVariantManager read GetValueManager;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: TObject]:    Variant read GetValue write SetValue; default;
  end;


  {
    :$ String-to-Variant hash.
  }
  TX2SVHash     = class(TX2CustomStringHash)
  private
    function GetCurrentValue: Variant;
    function GetValue(Key: String): Variant;
    procedure SetValue(Key: String; const Value: Variant);
    function GetValueManager: TX2HashVariantManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashVariantManager read GetValueManager;
  public
    property CurrentValue:            Variant read GetCurrentValue;
    property Values[Key: String]:     Variant read GetValue write SetValue; default;
  end;


implementation
uses
  SysUtils;


{========================================
  TX2HashVariantManager
========================================}
procedure TX2HashVariantManager.FreeCookie(var ACookie: PX2HashCookie);
var
  variantCookie: PVariant;

begin
  if Assigned(ACookie) then
  begin
    variantCookie := ACookie;
    VarClear(variantCookie^);
    
    Dispose(variantCookie);
  end;

  inherited;
end;


function TX2HashVariantManager.CreateCookie(const AValue: Variant): PX2HashCookie;
var
  variantCookie: PVariant;

begin
  New(variantCookie);
  VarCopy(variantCookie^, AValue);

  Result := variantCookie;
end;


function TX2HashVariantManager.GetValue(const ACookie: PX2HashCookie): Variant;
begin
  VarCopy(Result, PVariant(ACookie)^);
end;


function TX2HashVariantManager.Hash(ACookie: PX2HashCookie): Cardinal;
begin
  { For now, this manager is only used for Values, which aren't hashed. }
  raise Exception.Create('Hash method is not supported for Variants');  
end;


function TX2HashVariantManager.Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean;
begin
  Result := (VarCompareValue(PVariant(ACookie1)^, PVariant(ACookie2)^) = vrEqual);
end;


function TX2HashVariantManager.Clone(const ACookie: PX2HashCookie): PX2HashCookie;
begin
  Result := CreateCookie(PVariant(ACookie)^);
end;

//
//function TX2HashVariantManager.ToValue(const AData: Pointer): Variant;
//begin
//  Result  := PVariant(AData)^;
//end;
//
//
//function TX2HashVariantManager.Compare(const AData, AValue: Pointer;
//                                       const ASize: Cardinal): Boolean;
//begin
//  Result  := (VarCompareValue(PVariant(AData)^, PVariant(AValue)^) = vrEqual);
//end;


{========================================
  TX2PVHash
========================================}
function TX2PVHash.CreateValueManager: TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create;
end;


function TX2PVHash.GetCurrentValue: Variant;
begin
  CursorRequired;
  Result  := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2PVHash.GetValue(Key: Pointer): Variant;
var
  item: PX2HashValue;

begin
  Result := Unassigned;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2PVHash.SetValue(Key: Pointer; const Value: Variant);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2PVHash.GetValueManager: TX2HashVariantManager;
begin
  Result := TX2HashVariantManager(inherited ValueManager);
end;


{========================================
  TX2IVHash
========================================}
function TX2IVHash.CreateValueManager: TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create;
end;


function TX2IVHash.GetCurrentValue: Variant;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2IVHash.GetValue(Key: Integer): Variant;
var
  item: PX2HashValue;

begin
  Result := Unassigned;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2IVHash.SetValue(Key: Integer; const Value: Variant);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2IVHash.GetValueManager: TX2HashVariantManager;
begin
  Result := TX2HashVariantManager(inherited ValueManager);
end;


{========================================
  TX2OVHash
========================================}
function TX2OVHash.CreateValueManager: TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create;
end;


function TX2OVHash.GetCurrentValue: Variant;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2OVHash.GetValue(Key: TObject): Variant;
var
  item: PX2HashValue;

begin
  Result := Unassigned;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2OVHash.SetValue(Key: TObject; const Value: Variant);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2OVHash.GetValueManager: TX2HashVariantManager;
begin
  Result := TX2HashVariantManager(inherited ValueManager);
end;


{========================================
  TX2SVHash
========================================}
function TX2SVHash.CreateValueManager: TX2CustomHashManager;
begin
  Result  := TX2HashVariantManager.Create;
end;


function TX2SVHash.GetCurrentValue: Variant;
begin
  CursorRequired;
  Result  := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2SVHash.GetValue(Key: String): Variant;
var
  item: PX2HashValue;

begin
  Result := Unassigned;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2SVHash.SetValue(Key: String; const Value: Variant);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2SVHash.GetValueManager: TX2HashVariantManager;
begin
  Result := TX2HashVariantManager(inherited ValueManager);
end;

end.
