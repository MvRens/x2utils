{
  :: X2UtHashes contains a base class for hashes (also known as associative
  :: arrays), as well as various default implementations.
  ::
  :: The useable implementations have a naming convention of TX2<tt>Hash,
  :: where <tt> are two characters representing the key and value types,
  :: according to the following table:
  ::
  :: P  = Pointer
  :: I  = Integer
  :: O  = Object
  :: S  = String
  ::
  :: For example; TX2SOHash indicates that it uses String keys to identify
  :: Object values.
  ::
  :: As of Delphi 2006, all default hashes support the for...in structure.
  :: To enumerate all keys, use "for x in Hash". As of yet, there is no
  :: direct support for value enumeration yet; you can use
  :: First/Next/CurrentValue for that.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtHashes;

{$I X2UtCompilerVersion.inc}

interface
uses
  Classes,
  SysUtils;

const
  // Do NOT change these values unless you really know
  // what you are doing!
  LeafSize    = 256;
  BucketSize  = 8;

type
  //:$ Raised when the cursor is not available
  EX2HashNoCursor = class(Exception);

  // Forward declarations
  TX2CustomHash   = class;


  {$IFDEF D2005PLUS}
  {$REGION 'Internal hash structures'}
  {$ENDIF}
  {
    :$ Internal representation of a hash item.
  }
  PX2HashCookie = Pointer;

  PX2HashItem   = ^TX2HashItem;
  TX2HashItem   = record
    ID:             Cardinal;
  end;


  PX2HashBucket = ^TX2HashBucket;
  TX2HashBucket = record
    ID:             Cardinal;
    Level:          Integer;
    Count:          Integer;
    Items:          array[0..Pred(LeafSize)] of PX2HashItem;
  end;


  PX2HashValue  = ^TX2HashValue;
  TX2HashValue  = record
    ID:             Cardinal;
    Next:           PX2HashValue;
    Key:            PX2HashCookie;
    Value:          PX2HashCookie;
  end;


  TX2BucketPath = record
    Bucket:         PX2HashBucket;
    Index:          Integer;
  end;


  PX2HashStringCookie = ^TX2HashStringCookie;
  TX2HashStringCookie = record
    Length: Cardinal;
    Value: PChar;
  end;


  {
    :$ Default cursor implementation.

    :: Traverses the hash tree from top-to-bottom, left-to-right.
  }
  TX2HashCursor = class(TObject)
  private
    FBucketPath:  array of TX2BucketPath;
    FCurrent:     PX2HashValue;
  protected
    function GetCurrent: PX2HashValue; virtual;
  public
    constructor Create(const ABucket: PX2HashBucket); virtual;

    procedure First; virtual;
    function Next: Boolean; virtual;

    property Current: PX2HashValue read GetCurrent;
  end;
  {$IFDEF D2005PLUS}
  {$ENDREGION}


  {$REGION 'Internal value managers'}
  {$ENDIF}
  {
    :$ Base value manager.
  }
  TX2CustomHashManager = class(TObject)
  protected
    procedure FreeCookie(var ACookie: PX2HashCookie); virtual;

    function Hash(ACookie: PX2HashCookie): Cardinal; virtual; abstract;
    function Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean; virtual; abstract;
    function Clone(const ACookie: PX2HashCookie): PX2HashCookie; virtual; abstract;
  end;


  TX2HashPointerManager = class(TX2CustomHashManager)
  protected
    function CreateCookie(const AValue: Pointer): PX2HashCookie; overload;
    function GetValue(const ACookie: PX2HashCookie): Pointer; overload;

    function Hash(ACookie: PX2HashCookie): Cardinal; override;
    function Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean; override;
    function Clone(const ACookie: PX2HashCookie): PX2HashCookie; override;
  end;


  {
    :$ Integer value class.
  }
  TX2HashIntegerManager = class(TX2CustomHashManager)
  protected
    function CreateCookie(const AValue: Integer): PX2HashCookie; overload;
    function GetValue(const ACookie: PX2HashCookie): Integer; overload;

    function Hash(ACookie: PX2HashCookie): Cardinal; override;
    function Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean; override;
    function Clone(const ACookie: PX2HashCookie): PX2HashCookie; override;
  end;


  {
    :$ Object value class.
  }
  TX2HashObjectManager = class(TX2CustomHashManager)
  private
    FOwnsObjects: Boolean;
  protected
    procedure FreeCookie(var ACookie: PX2HashCookie); override;

    function CreateCookie(const AValue: TObject): PX2HashCookie; overload;
    function GetValue(const ACookie: PX2HashCookie): TObject; overload;

    function Hash(ACookie: PX2HashCookie): Cardinal; override;
    function Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean; override;
    function Clone(const ACookie: PX2HashCookie): PX2HashCookie; override;

    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  end;


  {
    :$ String value class.
  }
  TX2HashStringManager = class(TX2CustomHashManager)
  protected
    procedure FreeCookie(var ACookie: PX2HashCookie); override;

    function CreateCookie(const AValue: string): PX2HashCookie; overload;
    function GetValue(const ACookie: PX2HashCookie): string; overload;

    function Hash(ACookie: PX2HashCookie): Cardinal; override;
    function Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean; override;
    function Clone(const ACookie: PX2HashCookie): PX2HashCookie; override;
  end;
  {$IFDEF D2005PLUS}
  {$ENDREGION}


  {$REGION 'Delphi 2006 enumerator support'}
  {$ENDIF}
  {
    :$ Base enumerator class.
  }
  TX2HashEnumerator = class(TObject)
  private
    FCursor:      TX2HashCursor;
    FManager:     TX2CustomHashManager;
    FEnumKeys:    Boolean;

    function GetCursor: PX2HashCookie;
  protected
    property Manager:   TX2CustomHashManager  read FManager;
    property Cursor:    PX2HashCookie         read GetCursor;
  public
    constructor Create(const AHash: TX2CustomHash;
                       const AEnumKeys: Boolean);
    destructor Destroy; override;

    function MoveNext: Boolean;
  end;


  {
    :$ Enumerator for pointer values.
  }
  TX2HashPointerEnumerator  = class(TX2HashEnumerator)
  private
    function GetCurrent: Pointer;
  public
    property Current: Pointer read GetCurrent;
  end;


  {
    :$ Enumerator for integer values.
  }
  TX2HashIntegerEnumerator  = class(TX2HashEnumerator)
  private
    function GetCurrent: Integer;
  public
    property Current: Integer read GetCurrent;
  end;


  {
    :$ Enumerator for object values.
  }
  TX2HashObjectEnumerator   = class(TX2HashEnumerator)
  private
    function GetCurrent: TObject;
  public
    property Current: TObject read GetCurrent;
  end;


  {
    :$ Enumerator for string values
  }
  TX2HashStringEnumerator   = class(TX2HashEnumerator)
  private
    function GetCurrent: String;
  public
    property Current: String read GetCurrent;
  end;
  {$IFDEF D2005PLUS}
  {$ENDREGION}


  {$REGION 'Abstract hash implementation'}
  {$ENDIF}
  {
    :$ Hash implementation.
  }
  TX2CustomHash = class(TPersistent)
  private
    FRoot:              PX2HashBucket;
    FCount:             Integer;

    FCursor:            TX2HashCursor;
    FKeyManager:        TX2CustomHashManager;
    FValueManager:      TX2CustomHashManager;
  protected
    function CreateCursor: TX2HashCursor; virtual;
    function CreateKeyManager: TX2CustomHashManager; virtual; abstract;
    function CreateValueManager: TX2CustomHashManager; virtual; abstract;
    procedure InvalidateCursor;

    function CursorRequired(const ARaiseException: Boolean = True): Boolean;

    function InternalFind(const ABucket: PX2HashBucket;
                          const AHash: Cardinal; const AKey: PX2HashCookie;
                          const AAllowCreate: Boolean;
                          const AExisting: PX2HashValue = nil): PX2HashValue;
    function InternalDelete(const ABucket: PX2HashBucket;
                            const AHash: Cardinal; const AKey: PX2HashCookie): Boolean;

    { :$ AKey will be freed by these methods, so make sure to pass a Clone
      :$ if you need it afterwards! }
    function Find(const AKey: PX2HashCookie; const AAllowCreate: Boolean): PX2HashValue; overload;
    function Exists(const AKey: PX2HashCookie): Boolean; overload;
    function Delete(const AKey: PX2HashCookie): Boolean; overload;

    procedure SetValue(const AValue: PX2HashValue; const AData: Pointer);

    property Cursor:        TX2HashCursor         read FCursor;
    property KeyManager:    TX2CustomHashManager  read FKeyManager;
    property ValueManager:  TX2CustomHashManager  read FValueManager;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Clear;

    procedure First;
    function Next: Boolean;

    property Count: Integer read FCount;
  end;
  {$IFDEF D2005PLUS}
  {$ENDREGION}


  {$REGION 'Base hash classes'}
  {$ENDIF}
  {
    :$ Base hash implementation for pointer keys.
  }
  TX2CustomPointerHash  = class(TX2CustomHash)
  private
    function GetCurrentKey: Pointer;
    function GetKeyManager: TX2HashPointerManager;
  protected
    function CreateKeyManager: TX2CustomHashManager; override;
    function Find(const AKey: Pointer; const AAllowCreate: Boolean): PX2HashValue; overload;

    property KeyManager: TX2HashPointerManager read GetKeyManager;
  public
    function GetEnumerator: TX2HashPointerEnumerator;

    function Exists(const AKey: Pointer): Boolean; overload;
    function Delete(const AKey: Pointer): Boolean; overload;

    property CurrentKey: Pointer read GetCurrentKey;
  end;


  {
    :$ Base hash implementation for integer keys.
  }
  TX2CustomIntegerHash  = class(TX2CustomHash)
  private
    function GetCurrentKey: Integer;
    function GetKeyManager: TX2HashIntegerManager;
  protected
    function CreateKeyManager: TX2CustomHashManager; override;
    function Find(const AKey: Integer; const AAllowCreate: Boolean): PX2HashValue; overload;

    property KeyManager: TX2HashIntegerManager read GetKeyManager;
  public
    function GetEnumerator: TX2HashIntegerEnumerator;

    function Exists(const AKey: Integer): Boolean; overload;
    function Delete(const AKey: Integer): Boolean; overload;

    property CurrentKey: Integer read GetCurrentKey;
  end;


  {
    :$ Base hash implementation for object keys.
  }
  TX2CustomObjectHash  = class(TX2CustomHash)
  private
    function GetCurrentKey: TObject;
    function GetKeyManager: TX2HashObjectManager;
  protected
    function CreateKeyManager: TX2CustomHashManager; override;
    function Find(const AKey: TObject; const AAllowCreate: Boolean): PX2HashValue; overload;

    property KeyManager:  TX2HashObjectManager  read GetKeyManager;
  public
    function GetEnumerator: TX2HashObjectEnumerator;

    function Exists(const AKey: TObject): Boolean; overload;
    function Delete(const AKey: TObject): Boolean; overload;

    property CurrentKey: TObject read GetCurrentKey;
  end;


  {
    :$ Base hash implementation for string keys.
  }
  TX2CustomStringHash = class(TX2CustomHash)
  protected
    function GetCurrentKey: String;
  private
    function GetKeyManager: TX2HashStringManager;
  protected
    function CreateKeyManager: TX2CustomHashManager; override;
    function Find(const AKey: String; const AAllowCreate: Boolean): PX2HashValue; overload;

    property KeyManager: TX2HashStringManager read GetKeyManager;
  public
    function GetEnumerator: TX2HashStringEnumerator;

    function Exists(const AKey: String): Boolean; overload;
    function Delete(const AKey: String): Boolean; overload;

    property CurrentKey: String  read GetCurrentKey;
  end;
  {$IFDEF D2005PLUS}
  {$ENDREGION}


  {$REGION 'Concrete hash classes'}
  {$ENDIF}
  {
    :$ Pointer-to-Pointer hash.
  }
  TX2PPHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue: Pointer;
    function GetValue(Key: Pointer): Pointer;
    procedure SetValue(Key: Pointer; const Value: Pointer);
  private
    function GetValueManager: TX2HashPointerManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashPointerManager read GetValueManager;
  public
    property CurrentValue:          Pointer read GetCurrentValue;
    property Values[Key: Pointer]:  Pointer read GetValue write SetValue; default;
  end;


  {
    :$ Pointer-to-Integer hash.
  }
  TX2PIHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue: Integer;
    function GetValue(Key: Pointer): Integer;
    procedure SetValue(Key: Pointer; const Value: Integer);
  private
    function GetValueManager: TX2HashIntegerManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashIntegerManager read GetValueManager;
  public
    property CurrentValue:          Integer read GetCurrentValue;
    property Values[Key: Pointer]:  Integer read GetValue write SetValue; default;
  end;


  {
    :$ Pointer-to-Object hash.
  }
  TX2POHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue: TObject;
    function GetOwnsObjects: Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: Pointer): TObject;
    procedure SetValue(Key: Pointer; const Value: TObject);
  private
    function GetValueManager: TX2HashObjectManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashObjectManager read GetValueManager;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:          TObject read GetCurrentValue;
    property OwnsObjects:           Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: Pointer]:  TObject read GetValue write SetValue; default;
  end;


  {
    :$ Pointer-to-String hash.
  }
  TX2PSHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue: String;
    function GetValue(Key: Pointer): String;
    procedure SetValue(Key: Pointer; const Value: String);
  private
    function GetValueManager: TX2HashStringManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashStringManager read GetValueManager;
  public
    property CurrentValue:          String  read GetCurrentValue;
    property Values[Key: Pointer]:  String  read GetValue write SetValue; default;
  end;


  {
    :$ Integer-to-Pointer hash.
  }
  TX2IPHash     = class(TX2CustomIntegerHash)
  protected
    function GetCurrentValue: Pointer;
    function GetValue(Key: Integer): Pointer;
    procedure SetValue(Key: Integer; const Value: Pointer);
  private
    function GetValueManager: TX2HashPointerManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashPointerManager read GetValueManager;
  public
    property CurrentValue:          Pointer read GetCurrentValue;
    property Values[Key: Integer]:  Pointer read GetValue write SetValue; default;
  end;


  {
    :$ Integer-to-Integer hash.
  }
  TX2IIHash     = class(TX2CustomIntegerHash)
  protected
    function GetCurrentValue: Integer;
    function GetValue(Key: Integer): Integer;
    procedure SetValue(Key: Integer; const Value: Integer);
  private
    function GetValueManager: TX2HashIntegerManager;
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashIntegerManager read GetValueManager;
  public
    property CurrentValue:          Integer read GetCurrentValue;
    property Values[Key: Integer]:  Integer read GetValue write SetValue; default;
  end;


  {
    :$ Integer-to-Object hash.
  }
  TX2IOHash     = class(TX2CustomIntegerHash)
  private
    function GetValueManager: TX2HashObjectManager;
  protected
    function GetCurrentValue: TObject;
    function GetOwnsObjects: Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: Integer): TObject;
    procedure SetValue(Key: Integer; const Value: TObject);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashObjectManager read GetValueManager;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:          TObject read GetCurrentValue;
    property OwnsObjects:           Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: Integer]:  TObject read GetValue write SetValue; default;
  end;


  {
    :$ Integer-to-String hash.
  }
  TX2ISHash     = class(TX2CustomIntegerHash)
  private
    function GetValueManager: TX2HashStringManager;
  protected
    function GetCurrentValue: String;
    function GetValue(Key: Integer): String;
    procedure SetValue(Key: Integer; const Value: String);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashStringManager read GetValueManager;
  public
    property CurrentValue:          String read GetCurrentValue;
    property Values[Key: Integer]:  String read GetValue write SetValue; default;
  end;


  {
    :$ Object-to-Pointer hash.
  }
  TX2OPHash     = class(TX2CustomObjectHash)
  private
    function GetValueManager: TX2HashPointerManager;
  protected
    function GetCurrentValue: Pointer;
    function GetValue(Key: TObject): Pointer;
    procedure SetValue(Key: TObject; const Value: Pointer);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashPointerManager read GetValueManager;
  public
    property CurrentValue:          Pointer read GetCurrentValue;
    property Values[Key: TObject]:  Pointer read GetValue write SetValue; default;
  end;


  {
    :$ Object-to-Integer hash.
  }
  TX2OIHash     = class(TX2CustomObjectHash)
  private
    function GetValueManager: TX2HashIntegerManager;
  protected
    function GetCurrentValue: Integer;
    function GetValue(Key: TObject): Integer;
    procedure SetValue(Key: TObject; const Value: Integer);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashIntegerManager read GetValueManager;
  public
    property CurrentValue:          Integer read GetCurrentValue;
    property Values[Key: TObject]:  Integer read GetValue write SetValue; default;
  end;


  {
    :$ Object-to-Object hash.
  }
  TX2OOHash     = class(TX2CustomObjectHash)
  private
    function GetValueManager: TX2HashObjectManager;
  protected
    function GetCurrentValue: TObject;
    function GetOwnsObjects: Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: TObject): TObject;
    procedure SetValue(Key: TObject; const Value: TObject);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashObjectManager read GetValueManager;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:          TObject read GetCurrentValue;
    property OwnsObjects:           Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: TObject]:  TObject read GetValue       write SetValue; default;
  end;


  {
    :$ Object-to-String hash.
  }
  TX2OSHash     = class(TX2CustomObjectHash)
  private
    function GetValueManager: TX2HashStringManager;
  protected
    function GetCurrentValue: String;
    function GetValue(Key: TObject): String;
    procedure SetValue(Key: TObject; const Value: String);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashStringManager read GetValueManager;
  public
    property CurrentValue:          String  read GetCurrentValue;
    property Values[Key: TObject]:  String  read GetValue write SetValue; default;
  end;


  {
    :$ String-to-Pointer hash.
  }
  TX2SPHash     = class(TX2CustomStringHash)
  private
    function GetValueManager: TX2HashPointerManager;
  protected
    function GetCurrentValue: Pointer;
    function GetValue(Key: String): Pointer;
    procedure SetValue(Key: String; const Value: Pointer);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashPointerManager read GetValueManager;
  public
    property CurrentValue:        Pointer read GetCurrentValue;
    property Values[Key: String]: Pointer read GetValue write SetValue; default;
  end;


  {
    :$ String-to-Integer hash.
  }
  TX2SIHash     = class(TX2CustomStringHash)
  private
    function GetValueManager: TX2HashIntegerManager;
  protected
    function GetCurrentValue: Integer;
    function GetValue(Key: String): Integer;
    procedure SetValue(Key: String; const Value: Integer);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashIntegerManager read GetValueManager;
  public
    property CurrentValue:        Integer read GetCurrentValue;
    property Values[Key: String]: Integer read GetValue write SetValue; default;
  end;


  {
    :$ String-to-Object hash.
  }
  TX2SOHash     = class(TX2CustomStringHash)
  private
    function GetValueManager: TX2HashObjectManager;
  protected
    function GetCurrentValue: TObject;
    function GetOwnsObjects: Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: String): TObject;
    procedure SetValue(Key: String; const Value: TObject);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashObjectManager read GetValueManager;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:        TObject read GetCurrentValue;
    property OwnsObjects:         Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: String]: TObject read GetValue write SetValue; default;
  end;


  {
    :$ String-to-String hash.
  }
  TX2SSHash     = class(TX2CustomStringHash)
  private
    function GetValueManager: TX2HashStringManager;
  protected
    function GetCurrentValue: String;
    function GetValue(Key: String): String;
    procedure SetValue(Key: String; const Value: String);
  protected
    function CreateValueManager: TX2CustomHashManager; override;

    property ValueManager: TX2HashStringManager read GetValueManager;
  public
    property CurrentValue:        String read GetCurrentValue;
    property Values[Key: String]: String read GetValue write SetValue; default;
  end;
  {$IFDEF D2005PLUS}
  {$ENDREGION}
  {$ENDIF}


implementation
const
  HIDBucket   = 1;
  HIDValue    = 2;

  CRC32Poly   = $edb88320;

var
  CRC32Table:   array[Byte] of Cardinal;


{========================================
  CRC32
========================================}
procedure CRC32Init;
var
  iItem:      Integer;
  iPoly:      Integer;
  iValue:     Cardinal;

begin
  for iItem := 255 downto 0 do
  begin
    iValue := iItem;

    for iPoly := 8 downto 1 do
      if (iValue and $1) <> 0 then
        iValue := (iValue shr $1) xor CRC32Poly
      else
        iValue := iValue shr $1;

    CRC32Table[iItem] := iValue;
  end;
end;


function CRC32(const AKey: Pointer; const ASize: Cardinal): Cardinal; overload;
var
  iByte:      Integer;
  pByte:      ^Byte;

begin
  Result := $FFFFFFFF;
  pByte := AKey;

  for iByte := Pred(ASize) downto 0 do
  begin
    Result := (((Result shr 8) and $00FFFFFF) xor
                (CRC32Table[(Result xor pByte^) and $FF]));
    Inc(pByte);
  end;
end;


function CRC32(const AKey: string): Cardinal; overload;
begin
  Result := CRC32(PChar(AKey), Length(AKey) * SizeOf(Char));
end;


{$IFDEF D2005PLUS}
{$REGION 'Internal hash structures'}
{$ENDIF}
{========================================
  TX2HashCursor
========================================}
constructor TX2HashCursor.Create(const ABucket: PX2HashBucket);
begin
  inherited Create;

  SetLength(FBucketPath, 1);
  with FBucketPath[0] do
  begin
    Bucket := ABucket;
    Index := 0;
  end;

  FCurrent := nil;
end;


function TX2HashCursor.GetCurrent: PX2HashValue;
begin
  Result := FCurrent;
end;


procedure TX2HashCursor.First;
begin
  if Length(FBucketPath) > 1 then
    SetLength(FBucketPath, 1);

  FBucketPath[0].Index := 0;
  FCurrent := nil;
end;


function TX2HashCursor.Next: Boolean;
var
  bFound:     Boolean;
  iIndex:     Integer;
  pBucket:    PX2HashBucket;
  pItem:      PX2HashItem;

begin
  Result := False;
  iIndex := High(FBucketPath);
  if iIndex = -1 then
    exit;

  if Assigned(FCurrent) and Assigned(FCurrent^.Next) then
  begin
    FCurrent := FCurrent^.Next;
    Result := True;
    exit;
  end;

  repeat
    pBucket := FBucketPath[iIndex].Bucket;
    bFound := False;

    while FBucketPath[iIndex].Index < LeafSize do
    begin
      pItem := pBucket^.Items[FBucketPath[iIndex].Index];

      if pItem = nil then
        Inc(FBucketPath[iIndex].Index)
      else
        case pItem^.ID of
          HIDBucket:
            begin
              // Bucket, continue down the path
              Inc(iIndex);
              SetLength(FBucketPath, iIndex + 1);
              with FBucketPath[iIndex] do
              begin
                Bucket := PX2HashBucket(pItem);
                Index := 0;
              end;
              bFound := True;
              break;
            end;
          HIDValue:
            begin
              // Got a value
              FCurrent := PX2HashValue(pItem);
              Result := True;
              Inc(FBucketPath[iIndex].Index);
              exit;
            end;
        end;
    end;

    if not bFound then
      // Nothing found
      if iIndex > 0 then
      begin
        // Go up in the bucket path
        SetLength(FBucketPath, iIndex);
        Dec(iIndex);
        Inc(FBucketPath[iIndex].Index);
      end else
        // No more items
        break;
  until False;
end;
{$IFDEF D2005PLUS}
{$ENDREGION}


{$REGION 'Internal value managers'}
{$ENDIF}
{========================================
  TX2CustomHashManager
========================================}
procedure TX2CustomHashManager.FreeCookie(var ACookie: Pointer);
begin
  ACookie := nil;
end;


{========================================
  TX2HashPointerManager
========================================}
function TX2HashPointerManager.CreateCookie(const AValue: Pointer): PX2HashCookie;
begin
  Result := AValue;
end;


function TX2HashPointerManager.GetValue(const ACookie: PX2HashCookie): Pointer;
begin
  Result := ACookie;
end;


function TX2HashPointerManager.Hash(ACookie: PX2HashCookie): Cardinal;
var
  value: Pointer;

begin
  value := GetValue(ACookie);
  Result := CRC32(@value, SizeOf(Pointer));
end;


function TX2HashPointerManager.Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean;
begin
  Result := (GetValue(ACookie1) = GetValue(ACookie2));
end;


function TX2HashPointerManager.Clone(const ACookie: PX2HashCookie): PX2HashCookie;
begin
  Result := ACookie;
end;


{========================================
  TX2HashIntegerManager
========================================}
function TX2HashIntegerManager.CreateCookie(const AValue: Integer): PX2HashCookie;
begin
  Result := PX2HashCookie(AValue);
end;


function TX2HashIntegerManager.GetValue(const ACookie: PX2HashCookie): Integer;
begin
  Result := Integer(ACookie);
end;


function TX2HashIntegerManager.Hash(ACookie: PX2HashCookie): Cardinal;
var
  value: Integer;

begin
  value := GetValue(ACookie);
  Result := CRC32(@value, SizeOf(Integer));
end;


function TX2HashIntegerManager.Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean;
begin
  Result := (GetValue(ACookie1) = GetValue(ACookie2));
end;


function TX2HashIntegerManager.Clone(const ACookie: PX2HashCookie): PX2HashCookie;
begin
  Result := ACookie;
end;


{========================================
  TX2HashObjectManager
========================================}
procedure TX2HashObjectManager.FreeCookie(var ACookie: PX2HashCookie);
begin
  if Assigned(ACookie) and (FOwnsObjects) then
    GetValue(ACookie).Free;

  inherited;
end;


function TX2HashObjectManager.CreateCookie(const AValue: TObject): PX2HashCookie;
begin
  Result := PX2HashCookie(AValue);
end;


function TX2HashObjectManager.GetValue(const ACookie: PX2HashCookie): TObject;
begin
  Result := TObject(ACookie);
end;


function TX2HashObjectManager.Hash(ACookie: PX2HashCookie): Cardinal;
var
  value: TObject;

begin
  value := GetValue(ACookie);
  Result := CRC32(@value, SizeOf(TObject));
end;


function TX2HashObjectManager.Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean;
begin
  Result := (GetValue(ACookie1) = GetValue(ACookie2));
end;


function TX2HashObjectManager.Clone(const ACookie: PX2HashCookie): PX2HashCookie;
begin
  Result := ACookie;
end;


{========================================
  TX2HashStringManager
========================================}
procedure TX2HashStringManager.FreeCookie(var ACookie: PX2HashCookie);
var
  stringCookie: PX2HashStringCookie;

begin
  if Assigned(ACookie) then
  begin
    stringCookie := ACookie;

    if stringCookie^.Length > 0 then
      FreeMem(stringCookie^.Value, Succ(stringCookie^.Length));

    Dispose(stringCookie);
  end;

  inherited;
end;


function TX2HashStringManager.CreateCookie(const AValue: string): PX2HashCookie;
var
  stringCookie: PX2HashStringCookie;

begin
  New(stringCookie);
  stringCookie^.Length := Length(AValue);

  GetMem(stringCookie^.Value, Succ(Length(AValue)) * SizeOf(Char));
  StrPCopy(stringCookie^.Value, AValue);

  Result := stringCookie;
end;


function TX2HashStringManager.GetValue(const ACookie: PX2HashCookie): string;
var
  stringCookie: PX2HashStringCookie;

begin
  Result := '';
  if Assigned(ACookie) then
  begin
    stringCookie := ACookie;
    if stringCookie^.Length > 0 then
    begin
      SetLength(Result, stringCookie^.Length);
      Move(stringCookie^.Value^, Result[1], stringCookie^.Length * SizeOf(Char));
    end;
  end;
end;


function TX2HashStringManager.Hash(ACookie: PX2HashCookie): Cardinal;
var
  stringCookie: PX2HashStringCookie;

begin
  Result := 0;
  if Assigned(ACookie) then
  begin
    stringCookie := ACookie;
    Result := CRC32(stringCookie^.Value);
  end;
end;


function TX2HashStringManager.Compare(const ACookie1, ACookie2: PX2HashCookie): Boolean;
begin
  Result := (GetValue(ACookie1) = GetValue(ACookie2));
end;


function TX2HashStringManager.Clone(const ACookie: PX2HashCookie): PX2HashCookie;
begin
  Result := CreateCookie(GetValue(ACookie));
end;
{$IFDEF D2005PLUS}
{$ENDREGION}


{$REGION 'Abstract hash implementation'}
{$ENDIF}
{========================== TX2CustomHash
  Initialization
========================================}
constructor TX2CustomHash.Create;
begin
  inherited;

  FKeyManager := CreateKeyManager;
  FValueManager := CreateValueManager;
end;


destructor TX2CustomHash.Destroy;
begin
  Clear;
  FreeAndNil(FValueManager);
  FreeAndNil(FKeyManager);
  FreeAndNil(FCursor);

  inherited;
end;


function TX2CustomHash.CreateCursor: TX2HashCursor;
begin
  Result := nil;
  if Assigned(FRoot) then
    Result := TX2HashCursor.Create(FRoot);
end;


procedure TX2CustomHash.InvalidateCursor;
begin
  FreeAndNil(FCursor);
end;


{========================== TX2CustomHash
  Item Management
========================================}
function ROR(const AValue: Cardinal; const AShift: Byte = 8): Cardinal;
asm
  MOV cl, dl
  ROR eax, cl
end;


function TX2CustomHash.CursorRequired(const ARaiseException: Boolean): Boolean;
begin
  Result := True;
  if not Assigned(FCursor) then
    if Assigned(FRoot) then
      FCursor := CreateCursor
    else
    begin
      Result := False;
      if ARaiseException then
        raise EX2HashNoCursor.Create('Cursor not available!');
    end;
end;


function TX2CustomHash.InternalFind(const ABucket: PX2HashBucket;
                                    const AHash: Cardinal; const AKey: PX2HashCookie;
                                    const AAllowCreate: Boolean;
                                    const AExisting: PX2HashValue): PX2HashValue;
  function CreateValue: PX2HashValue;
  begin
    if AExisting = nil then
    begin
      GetMem(Result, SizeOf(TX2HashValue));
      FillChar(Result^, SizeOf(TX2HashValue), #0);

      Result^.ID := HIDValue;
      Result^.Key := KeyManager.Clone(AKey);
      Inc(FCount);
    end else
      Result := AExisting;

    InvalidateCursor;
  end;

var
  bucketCount: Integer;
  bucketIndex: Integer;
  bucket: PX2HashBucket;
  key: Pointer;
  nextValue: PX2HashValue;
  value: PX2HashValue;

begin
  Result := nil;
  bucketIndex := (AHash and $FF);

  if ABucket^.Items[bucketIndex] = nil then
  begin
    if AAllowCreate then
    begin
      // New value
      Result := CreateValue;
      ABucket^.Items[bucketIndex] := PX2HashItem(Result);
      Inc(ABucket^.Count);
    end;
  end else
    case ABucket^.Items[bucketIndex]^.ID of
      HIDBucket:
        // Bucket, continue down
        Result := InternalFind(PX2HashBucket(ABucket^.Items[bucketIndex]),
                               ROR(AHash), AKey, AAllowCreate);
      HIDValue:
        begin
          bucketCount := 0;
          value := PX2HashValue(ABucket^.Items[bucketIndex]);
          while Assigned(value) do
          begin
            if KeyManager.Compare(value^.Key, AKey) then
            begin
              // Found existing key
              Result := value;
              exit;
            end;

            value := value^.Next;
            Inc(bucketCount);
          end;

          if AAllowCreate then
            if (bucketCount >= BucketSize) then
            begin
              // Bucket full
              GetMem(bucket, SizeOf(TX2HashBucket));
              FillChar(bucket^, SizeOf(TX2HashBucket), #0);
              bucket^.ID := HIDBucket;
              bucket^.Level := ABucket^.Level + 1;

              value := PX2HashValue(ABucket^.Items[bucketIndex]);
              while Assigned(value) do
              begin
                // Transfer item
                key := KeyManager.Clone(value^.Key);
                nextValue := value^.Next;
                value^.Next := nil;

                InternalFind(bucket, ROR(KeyManager.Hash(key), bucket^.Level * 8),
                             key, True, value);

                value := nextValue;
              end;

              Result := InternalFind(bucket, ROR(AHash), AKey, True);
              ABucket^.Items[bucketIndex] := PX2HashItem(bucket);
            end else
            begin
              // New value
              Result := CreateValue;
              Result^.Next := PX2HashValue(ABucket^.Items[bucketIndex]);
              ABucket^.Items[bucketIndex] := PX2HashItem(Result);
            end;
        end;
    end;
end;


function TX2CustomHash.InternalDelete(const ABucket: PX2HashBucket;
                                      const AHash: Cardinal;
                                      const AKey: PX2HashCookie): Boolean;
var
  iIndex:     Integer;
  pBucket:    PX2HashBucket;
  pPrev:      PX2HashValue;
  pValue:     PX2HashValue;

begin
  Result := False;
  iIndex := (AHash and $FF);

  if Assigned(ABucket^.Items[iIndex]) then
    case ABucket^.Items[iIndex]^.ID of
      HIDBucket:
        begin
          // Bucket, continue down
          pBucket := PX2HashBucket(ABucket^.Items[iIndex]);
          Result := InternalDelete(pBucket, ROR(AHash), AKey);

          if pBucket^.Count = 0 then
          begin
            FreeMem(pBucket, SizeOf(TX2HashBucket));
            ABucket^.Items[iIndex] := nil;
          end;
        end;
      HIDValue:
        begin
          pPrev := nil;
          pValue := PX2HashValue(ABucket^.Items[iIndex]);
          while Assigned(pValue) do
          begin
            if KeyManager.Compare(pValue^.Key, AKey) then
            begin
              // Found key
              if pPrev = nil then
              begin
                ABucket^.Items[iIndex] := PX2HashItem(pValue^.Next);
                if ABucket^.Items[iIndex] = nil then
                  Dec(ABucket^.Count);
              end else
                pPrev^.Next := pValue^.Next;

              KeyManager.FreeCookie(pValue^.Key);
              ValueManager.FreeCookie(pValue^.Value);
              FreeMem(pValue, SizeOf(TX2HashValue));
              Dec(FCount);

              Result := True;
              exit;
            end;

            pPrev := pValue;
            pValue := pValue^.Next;
          end;
        end;
    end;
end;


function TX2CustomHash.Find(const AKey: PX2HashCookie; const AAllowCreate: Boolean): PX2HashValue;
var
  cookie: PX2HashCookie;
  
begin
  Result := nil;
  try
    if not Assigned(FRoot) then
      if AAllowCreate then
      begin
        // Create root bucket
        GetMem(FRoot, SizeOf(TX2HashBucket));
        FillChar(FRoot^, SizeOf(TX2HashBucket), #0);
        FRoot^.ID := HIDBucket;
      end else
        exit;

    Result := InternalFind(FRoot, KeyManager.Hash(AKey), AKey, AAllowCreate);
  finally
    cookie := AKey;
    KeyManager.FreeCookie(cookie);
  end;
end;


procedure TX2CustomHash.Clear;
  procedure DestroyBucket(const ABucket: PX2HashBucket);
  var
    iItem:        Integer;
    pNext:        PX2HashValue;
    pValue:       PX2HashValue;

  begin
    for iItem := Pred(LeafSize) downto 0 do
      if Assigned(ABucket^.Items[iItem]) then
        case ABucket^.Items[iItem].ID of
          HIDBucket:
            DestroyBucket(PX2HashBucket(ABucket^.Items[iItem]));
          HIDValue:
            begin
              pValue := PX2HashValue(ABucket^.Items[iItem]);
              repeat
                KeyManager.FreeCookie(pValue^.Key);
                ValueManager.FreeCookie(pValue^.Value);

                pNext := pValue^.Next;
                FreeMem(pValue, SizeOf(TX2HashValue));
                pValue := pNext;
              until pValue = nil;
            end;
        end;

    FreeMem(ABucket, SizeOf(TX2HashBucket));
  end;

begin
  if Assigned(FRoot) then
  begin
    DestroyBucket(FRoot);
    InvalidateCursor;
    FCount := 0;
    FRoot := nil;
  end;
end;


function TX2CustomHash.Exists(const AKey: PX2HashCookie): Boolean;
begin
  Result := Assigned(Find(AKey, False));
end;


function TX2CustomHash.Delete(const AKey: PX2HashCookie): Boolean;
var
  cookie: PX2HashCookie;
  
begin
  try
    Result := False;
    if not Assigned(FRoot) then
      exit;

    Result := InternalDelete(FRoot, KeyManager.Hash(AKey), AKey);
    if Result then
      InvalidateCursor;
  finally
    cookie := AKey;
    KeyManager.FreeCookie(cookie);
  end;
end;


procedure TX2CustomHash.SetValue(const AValue: PX2HashValue;
                                 const AData: Pointer);
begin
  ValueManager.FreeCookie(AValue^.Value);
  AValue^.Value := AData;
end;


procedure TX2CustomHash.First;
begin
  if not CursorRequired(False) then
    exit;

  Cursor.First;
end;


function TX2CustomHash.Next: Boolean;
begin
  Result := False;
  if not CursorRequired(False) then
    exit;

  Result := Cursor.Next;
end;
{$IFDEF D2005PLUS}
{$ENDREGION}


{$REGION 'Delphi 2006 enumerator support'}
{$ENDIF}
{========================================
  TX2HashEnumerator
========================================}
constructor TX2HashEnumerator.Create(const AHash: TX2CustomHash;
                                     const AEnumKeys: Boolean);
begin
  inherited Create;

  FEnumKeys := AEnumKeys;
  if AEnumKeys then
    FManager := AHash.KeyManager
  else
    FManager := AHash.ValueManager;

  FCursor := AHash.CreateCursor;
end;


destructor TX2HashEnumerator.Destroy;
begin
  FreeAndNil(FCursor);

  inherited;
end;


function TX2HashEnumerator.GetCursor: PX2HashCookie;
begin
  if FEnumKeys then
    Result := FCursor.Current^.Key
  else
    Result := FCursor.Current^.Value;
end;


function TX2HashEnumerator.MoveNext: Boolean;
begin
  Result := False;
  if Assigned(FCursor) then
    Result := FCursor.Next;
end;


{ TX2HashPointerEnumerator }
function TX2HashPointerEnumerator.GetCurrent: Pointer;
begin
  Result := TX2HashPointerManager(Manager).GetValue(Cursor);
end;


{ TX2HashIntegerEnumerator }
function TX2HashIntegerEnumerator.GetCurrent: Integer;
begin
  Result := TX2HashIntegerManager(Manager).GetValue(Cursor);
end;


{ TX2HashObjectEnumerator }
function TX2HashObjectEnumerator.GetCurrent: TObject;
begin
  Result := TX2HashObjectManager(Manager).GetValue(Cursor);
end;


{ TX2HashStringEnumerator }
function TX2HashStringEnumerator.GetCurrent: String;
begin
  Result := TX2HashStringManager(Manager).GetValue(Cursor);
end;
{$IFDEF D2005PLUS}
{$ENDREGION}


{$REGION 'Base hash classes'}
{$ENDIF}
{========================================
  TX2CustomPointerHash
========================================}
function TX2CustomPointerHash.CreateKeyManager: TX2CustomHashManager;
begin
  Result := TX2HashPointerManager.Create;
end;


function TX2CustomPointerHash.GetCurrentKey: Pointer;
begin
  CursorRequired;
  Result := KeyManager.GetValue(Cursor.Current^.Key);
end;


function TX2CustomPointerHash.GetEnumerator: TX2HashPointerEnumerator;
begin
  Result := TX2HashPointerEnumerator.Create(Self, True);
end;


function TX2CustomPointerHash.Find(const AKey: Pointer;
                                   const AAllowCreate: Boolean): PX2HashValue;
begin
  Result := inherited Find(KeyManager.CreateCookie(AKey), AAllowCreate);
end;


function TX2CustomPointerHash.Exists(const AKey: Pointer): Boolean;
begin
  Result := inherited Exists(KeyManager.CreateCookie(AKey));
end;


function TX2CustomPointerHash.Delete(const AKey: Pointer): Boolean;
begin
  Result := inherited Delete(KeyManager.CreateCookie(AKey));
end;


function TX2CustomPointerHash.GetKeyManager: TX2HashPointerManager;
begin
  Result := TX2HashPointerManager(inherited KeyManager);
end;


{========================================
  TX2CustomIntegerHash
========================================}
function TX2CustomIntegerHash.CreateKeyManager: TX2CustomHashManager;
begin
  Result := TX2HashIntegerManager.Create;
end;


function TX2CustomIntegerHash.GetCurrentKey: Integer;
begin
  CursorRequired;
  Result := KeyManager.GetValue(Cursor.Current^.Key);
end;


function TX2CustomIntegerHash.GetEnumerator: TX2HashIntegerEnumerator;
begin
  Result := TX2HashIntegerEnumerator.Create(Self, True);
end;


function TX2CustomIntegerHash.Find(const AKey: Integer;
                                   const AAllowCreate: Boolean): PX2HashValue;
begin
  Result := inherited Find(KeyManager.CreateCookie(AKey), AAllowCreate);
end;


function TX2CustomIntegerHash.Exists(const AKey: Integer): Boolean;
begin
  Result := inherited Exists(KeyManager.CreateCookie(AKey));
end;


function TX2CustomIntegerHash.Delete(const AKey: Integer): Boolean;
begin
  Result := inherited Delete(KeyManager.CreateCookie(AKey));
end;


function TX2CustomIntegerHash.GetKeyManager: TX2HashIntegerManager;
begin
  Result := TX2HashIntegerManager(inherited KeyManager);
end;


{========================================
  TX2CustomObjectHash
========================================}
function TX2CustomObjectHash.CreateKeyManager: TX2CustomHashManager;
begin
  Result := TX2HashObjectManager.Create;
end;


function TX2CustomObjectHash.GetCurrentKey: TObject;
begin
  CursorRequired;
  Result := KeyManager.GetValue(Cursor.Current^.Key);
end;


function TX2CustomObjectHash.GetEnumerator: TX2HashObjectEnumerator;
begin
  Result := TX2HashObjectEnumerator.Create(Self, True);
end;


function TX2CustomObjectHash.Find(const AKey: TObject;
                                  const AAllowCreate: Boolean): PX2HashValue;
begin
  Result := inherited Find(KeyManager.CreateCookie(AKey), AAllowCreate);
end;


function TX2CustomObjectHash.Exists(const AKey: TObject): Boolean;
begin
  Result := inherited Exists(KeyManager.CreateCookie(AKey));
end;


function TX2CustomObjectHash.Delete(const AKey: TObject): Boolean;
begin
  Result := inherited Delete(KeyManager.CreateCookie(AKey));
end;


function TX2CustomObjectHash.GetKeyManager: TX2HashObjectManager;
begin
  Result := TX2HashObjectManager(inherited KeyManager);
end;


{========================================
  TX2CustomStringHash
========================================}
function TX2CustomStringHash.CreateKeyManager: TX2CustomHashManager;
begin
  Result := TX2HashStringManager.Create;
end;


function TX2CustomStringHash.GetCurrentKey: String;
begin
  CursorRequired;
  Result := TX2HashStringManager(KeyManager).GetValue(Cursor.Current^.Key);
end;


function TX2CustomStringHash.GetEnumerator: TX2HashStringEnumerator;
begin
  Result := TX2HashStringEnumerator.Create(Self, True);
end;


function TX2CustomStringHash.Find(const AKey: String;
                                  const AAllowCreate: Boolean): PX2HashValue;
begin
  Result := inherited Find(KeyManager.CreateCookie(AKey), AAllowCreate);
end;


function TX2CustomStringHash.Exists(const AKey: String): Boolean;
begin
  Result := inherited Exists(KeyManager.CreateCookie(AKey));
end;


function TX2CustomStringHash.Delete(const AKey: String): Boolean;
begin
  Result := inherited Delete(KeyManager.CreateCookie(AKey));
end;


function TX2CustomStringHash.GetKeyManager: TX2HashStringManager;
begin
  Result := TX2HashStringManager(inherited KeyManager);
end;
{$IFDEF D2005PLUS}
{$ENDREGION}


{$REGION 'Concrete hash classes'}
{$ENDIF}
{========================================
  TX2PPHash
========================================}
function TX2PPHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashPointerManager.Create;
end;


function TX2PPHash.GetCurrentValue: Pointer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2PPHash.GetValue(Key: Pointer): Pointer;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2PPHash.SetValue(Key: Pointer; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2PPHash.GetValueManager: TX2HashPointerManager;
begin
  Result := TX2HashPointerManager(inherited ValueManager);
end;


{========================================
  TX2PIHash
========================================}
function TX2PIHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashIntegerManager.Create;
end;


function TX2PIHash.GetCurrentValue: Integer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2PIHash.GetValue(Key: Pointer): Integer;
var
  item: PX2HashValue;

begin
  Result := 0;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2PIHash.SetValue(Key: Pointer; const Value: Integer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2PIHash.GetValueManager: TX2HashIntegerManager;
begin
  Result := TX2HashIntegerManager(inherited ValueManager);
end;


{========================================
  TX2POHash
========================================}
constructor TX2POHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create;
  OwnsObjects := AOwnsObjects;
end;


function TX2POHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashObjectManager.Create;
end;


function TX2POHash.GetCurrentValue: TObject;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2POHash.GetOwnsObjects: Boolean;
begin
  Result := ValueManager.OwnsObjects;
end;


procedure TX2POHash.SetOwnsObjects(const Value: Boolean);
begin
  ValueManager.OwnsObjects := Value;
end;


function TX2POHash.GetValue(Key: Pointer): TObject;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2POHash.SetValue(Key: Pointer; const Value: TObject);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2POHash.GetValueManager: TX2HashObjectManager;
begin
  Result := TX2HashObjectManager(inherited ValueManager);
end;


{========================================
  TX2PSHash
========================================}
function TX2PSHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashStringManager.Create;
end;


function TX2PSHash.GetCurrentValue: String;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2PSHash.GetValue(Key: Pointer): String;
var
  item: PX2HashValue;

begin
  Result := '';
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2PSHash.SetValue(Key: Pointer; const Value: String);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2PSHash.GetValueManager: TX2HashStringManager;
begin
  Result := TX2HashStringManager(inherited ValueManager);
end;


{========================================
  TX2IPHash
========================================}
function TX2IPHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashPointerManager.Create;
end;


function TX2IPHash.GetCurrentValue: Pointer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2IPHash.GetValue(Key: Integer): Pointer;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2IPHash.SetValue(Key: Integer; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2IPHash.GetValueManager: TX2HashPointerManager;
begin
  Result := TX2HashPointerManager(inherited ValueManager);
end;


{========================================
  TX2IIHash
========================================}
function TX2IIHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashIntegerManager.Create;
end;


function TX2IIHash.GetCurrentValue: Integer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2IIHash.GetValue(Key: Integer): Integer;
var
  item: PX2HashValue;

begin
  Result := 0;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2IIHash.SetValue(Key: Integer; const Value: Integer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2IIHash.GetValueManager: TX2HashIntegerManager;
begin
  Result := TX2HashIntegerManager(inherited ValueManager);
end;


{========================================
  TX2IOHash
========================================}
constructor TX2IOHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create;
  OwnsObjects := AOwnsObjects;
end;


function TX2IOHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashObjectManager.Create;
end;

function TX2IOHash.GetCurrentValue: TObject;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2IOHash.GetOwnsObjects: Boolean;
begin
  Result := ValueManager.OwnsObjects;
end;


procedure TX2IOHash.SetOwnsObjects(const Value: Boolean);
begin
  ValueManager.OwnsObjects := Value;
end;


function TX2IOHash.GetValue(Key: Integer): TObject;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2IOHash.SetValue(Key: Integer; const Value: TObject);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2IOHash.GetValueManager: TX2HashObjectManager;
begin
  Result := TX2HashObjectManager(inherited ValueManager);
end;


{========================================
  TX2ISHash
========================================}
function TX2ISHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashStringManager.Create;
end;


function TX2ISHash.GetCurrentValue: String;
begin
  Result := TX2HashStringManager(ValueManager).GetValue(Cursor.Current^.Value);
end;


function TX2ISHash.GetValue(Key: Integer): String;
var
  item: PX2HashValue;

begin
  Result := '';
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2ISHash.SetValue(Key: Integer; const Value: String);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2ISHash.GetValueManager: TX2HashStringManager;
begin
  Result := TX2HashStringManager(inherited ValueManager);
end;


{========================================
  TX2OPHash
========================================}
function TX2OPHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashPointerManager.Create;
end;


function TX2OPHash.GetCurrentValue: Pointer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2OPHash.GetValue(Key: TObject): Pointer;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2OPHash.SetValue(Key: TObject; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2OPHash.GetValueManager: TX2HashPointerManager;
begin
  Result := TX2HashPointerManager(inherited ValueManager);
end;


{========================================
  TX2OIHash
========================================}
function TX2OIHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashIntegerManager.Create;
end;


function TX2OIHash.GetCurrentValue: Integer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2OIHash.GetValue(Key: TObject): Integer;
var
  item: PX2HashValue;

begin
  Result := 0;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2OIHash.SetValue(Key: TObject; const Value: Integer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2OIHash.GetValueManager: TX2HashIntegerManager;
begin
  Result := TX2HashIntegerManager(inherited ValueManager);
end;


{========================================
  TX2OOHash
========================================}
constructor TX2OOHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create;
  OwnsObjects := AOwnsObjects;
end;


function TX2OOHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashObjectManager.Create;
end;


function TX2OOHash.GetCurrentValue: TObject;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2OOHash.GetOwnsObjects: Boolean;
begin
  Result := ValueManager.OwnsObjects;
end;


procedure TX2OOHash.SetOwnsObjects(const Value: Boolean);
begin
  TX2HashObjectManager(ValueManager).OwnsObjects := Value;
end;


function TX2OOHash.GetValue(Key: TObject): TObject;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2OOHash.SetValue(Key: TObject; const Value: TObject);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2OOHash.GetValueManager: TX2HashObjectManager;
begin
  Result := TX2HashObjectManager(inherited ValueManager);
end;


{========================================
  TX2OSHash
========================================}
function TX2OSHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashStringManager.Create;
end;


function TX2OSHash.GetCurrentValue: String;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2OSHash.GetValue(Key: TObject): String;
var
  item: PX2HashValue;

begin
  Result := '';
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2OSHash.SetValue(Key: TObject; const Value: String);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2OSHash.GetValueManager: TX2HashStringManager;
begin
  Result := TX2HashStringManager(inherited ValueManager);
end;


{========================================
  TX2SPHash
========================================}
function TX2SPHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashPointerManager.Create;
end;


function TX2SPHash.GetCurrentValue: Pointer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2SPHash.GetValue(Key: String): Pointer;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2SPHash.SetValue(Key: String; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2SPHash.GetValueManager: TX2HashPointerManager;
begin
  Result := TX2HashPointerManager(inherited ValueManager);
end;


{========================================
  TX2SIHash
========================================}
function TX2SIHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashIntegerManager.Create;
end;


function TX2SIHash.GetCurrentValue: Integer;
begin
  CursorRequired;
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2SIHash.GetValue(Key: String): Integer;
var
  item: PX2HashValue;

begin
  Result := 0;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2SIHash.SetValue(Key: String; const Value: Integer);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2SIHash.GetValueManager: TX2HashIntegerManager;
begin
  Result := TX2HashIntegerManager(inherited ValueManager);
end;


{========================================
  TX2SOHash
========================================}
constructor TX2SOHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create;
  OwnsObjects := AOwnsObjects;
end;


function TX2SOHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashObjectManager.Create;
end;


function TX2SOHash.GetCurrentValue: TObject;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2SOHash.GetOwnsObjects: Boolean;
begin
  Result := ValueManager.OwnsObjects;
end;


procedure TX2SOHash.SetOwnsObjects(const Value: Boolean);
begin
  TX2HashObjectManager(ValueManager).OwnsObjects := Value;
end;


function TX2SOHash.GetValue(Key: String): TObject;
var
  item: PX2HashValue;

begin
  Result := nil;
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2SOHash.SetValue(Key: String; const Value: TObject);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2SOHash.GetValueManager: TX2HashObjectManager;
begin
  Result := TX2HashObjectManager(inherited ValueManager);
end;


{========================================
  TX2SSHash
========================================}
function TX2SSHash.CreateValueManager: TX2CustomHashManager;
begin
  Result := TX2HashStringManager.Create;
end;


function TX2SSHash.GetCurrentValue: String;
begin
  Result := ValueManager.GetValue(Cursor.Current^.Value);
end;


function TX2SSHash.GetValue(Key: String): String;
var
  item: PX2HashValue;

begin
  Result := '';
  item := Find(Key, False);
  if Assigned(item) then
    Result := ValueManager.GetValue(item^.Value);
end;


procedure TX2SSHash.SetValue(Key: String; const Value: String);
begin
  inherited SetValue(Find(Key, True), ValueManager.CreateCookie(Value));
end;


function TX2SSHash.GetValueManager: TX2HashStringManager;
begin
  Result := TX2HashStringManager(inherited ValueManager);
end;
{$IFDEF D2005PLUS}
{$ENDREGION}
{$ENDIF}


initialization
  CRC32Init;

end.

