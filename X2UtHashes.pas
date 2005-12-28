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

  {$REGION 'Internal hash structures'}
  {
    :$ Internal representation of a hash item.
  }
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
    Key:            Pointer;
    Value:          Pointer;
  end;

  TX2BucketPath = record
    Bucket:         PX2HashBucket;
    Index:          Integer;
  end;

  {
    :$ Default cursor implementation.

    :: Traverses the hash trie from top-to-bottom, left-to-right.
  }
  TX2HashCursor = class(TObject)
  private
    FBucketPath:        array of TX2BucketPath;
    FCurrent:           PX2HashValue;
  protected
    function GetCurrent(): PX2HashValue; virtual;
  public
    constructor Create(const ABucket: PX2HashBucket); virtual;

    procedure First(); virtual;
    function Next(): Boolean; virtual;

    property Current:       PX2HashValue  read GetCurrent;
  end;
  {$ENDREGION}

  {$REGION 'Internal value managers'}
  {
    :$ Base value manager.
  }
  TX2CustomHashManager  = class(TObject)
  protected
    procedure Initialize(var AData: Pointer); virtual;
    procedure Finalize(var AData: Pointer); virtual;

    function DataSize(const AData: Pointer): Cardinal; virtual;
    function DataPointer(const AData: Pointer): Pointer; virtual;

    function ToPointer(const AValue: Pointer; const ASize: Cardinal): Pointer; overload; virtual;
    function ToValue(const AData: Pointer; var AValue): Cardinal; overload; virtual;

    function Compare(const AData: Pointer; const AValue: Pointer;
                     const ASize: Cardinal): Boolean; virtual;
  end;

  TX2HashPointerManager = class(TX2CustomHashManager)
  protected
    function ToPointer(const AValue: Pointer): Pointer; overload;
    function ToValue(const AData: Pointer): Pointer; overload;
  end;

  {
    :$ Integer value class.
  }
  TX2HashIntegerManager = class(TX2CustomHashManager)
  protected
    function ToPointer(const AValue: Integer): Pointer; overload;
    function ToValue(const AData: Pointer): Integer; overload;
  end;

  {
    :$ Object value class.
  }
  TX2HashObjectManager  = class(TX2CustomHashManager)
  private
    FOwnsObjects:     Boolean;
  protected
    procedure Finalize(var AData: Pointer); override;

    function ToPointer(const AValue: TObject): Pointer; overload;
    function ToValue(const AData: Pointer): TObject; overload;

    property OwnsObjects:     Boolean read FOwnsObjects write FOwnsObjects;
  end;

  {
    :$ String value class.
  }
  TX2HashStringManager  = class(TX2CustomHashManager)
  protected
    procedure Finalize(var AData: Pointer); override;

    function DataSize(const AData: Pointer): Cardinal; override;
    function DataPointer(const AData: Pointer): Pointer; override;

    function ToPointer(const AValue: Pointer; const ASize: Cardinal): Pointer; override;
    function ToValue(const AData: Pointer; var AValue): Cardinal; override;
    function ToPointer(const AValue: String): Pointer; overload;
    function ToValue(const AData: Pointer): String; overload;

    function Compare(const AData: Pointer; const AValue: Pointer;
                     const ASize: Cardinal): Boolean; override;
  end;
  {$ENDREGION}

  {$REGION 'Delphi 2006 enumerator support'}
  {
    :$ Base enumerator class.
  }
  TX2HashEnumerator         = class(TObject)
  private
    FCursor:      TX2HashCursor;
    FManager:     TX2CustomHashManager;
    FEnumKeys:    Boolean;

    function GetCursor(): Pointer;
  protected
    property Manager:   TX2CustomHashManager  read FManager;
    property Cursor:    Pointer               read GetCursor;
  public
    constructor Create(const AHash: TX2CustomHash;
                       const AEnumKeys: Boolean);
    destructor Destroy(); override;

    function MoveNext(): Boolean;
  end;

  {
    :$ Enumerator for pointer values.
  }
  TX2HashPointerEnumerator  = class(TX2HashEnumerator)
  private
    function GetCurrent: Pointer;
  public
    property Current:     Pointer read GetCurrent;
  end;

  {
    :$ Enumerator for integer values.
  }
  TX2HashIntegerEnumerator  = class(TX2HashEnumerator)
  private
    function GetCurrent: Integer;
  public
    property Current:     Integer read GetCurrent;
  end;

  {
    :$ Enumerator for object values.
  }
  TX2HashObjectEnumerator   = class(TX2HashEnumerator)
  private
    function GetCurrent: TObject;
  public
    property Current:     TObject read GetCurrent;
  end;

  {
    :$ Enumerator for string values
  }
  TX2HashStringEnumerator   = class(TX2HashEnumerator)
  private
    function GetCurrent(): String;
  public
    property Current:     String  read GetCurrent;
  end;
  {$ENDREGION}

  {$REGION 'Abstract hash implementation'}
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

    FKeys:              TObject;
    FValues:            TObject;
  protected
    function CreateCursor(): TX2HashCursor; virtual;
    function CreateKeyManager(): TX2CustomHashManager; virtual; abstract;
    function CreateValueManager(): TX2CustomHashManager; virtual; abstract;
    procedure InvalidateCursor();

    function Hash(const AKey: Pointer; const ASize: Cardinal): Cardinal; virtual;
    function CursorRequired(const ARaiseException: Boolean = True): Boolean;

    function InternalFind(const ABucket: PX2HashBucket;
                          const AHash: Cardinal; const AKey: Pointer;
                          const ASize: Cardinal;
                          const AAllowCreate: Boolean;
                          const AExisting: PX2HashValue = nil): PX2HashValue;
    function InternalDelete(const ABucket: PX2HashBucket;
                            const AHash: Cardinal; const AKey: Pointer;
                            const ASize: Cardinal): Boolean;

    function Find(const AKey: Pointer; const ASize: Cardinal;
                  const AAllowCreate: Boolean): PX2HashValue; overload;
    function Exists(const AKey: Pointer; const ASize: Cardinal): Boolean; overload;
    function Delete(const AKey: Pointer; const ASize: Cardinal): Boolean; overload;

    procedure SetValue(const AValue: PX2HashValue; const AData: Pointer);

    property Cursor:            TX2HashCursor         read FCursor;
    property KeyManager:        TX2CustomHashManager  read FKeyManager;
    property ValueManager:      TX2CustomHashManager  read FValueManager;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Clear();

    procedure First();
    function Next(): Boolean;

    property Count:     Integer read FCount;
  end;
  {$ENDREGION}

  {$REGION 'Base hash classes'}
  {
    :$ Base hash implementation for pointer keys.
  }
  TX2CustomPointerHash  = class(TX2CustomHash)
  private
    function GetCurrentKey(): Pointer;
  protected
    function CreateKeyManager(): TX2CustomHashManager; override;
    function Find(const AKey: Pointer;
                  const AAllowCreate: Boolean): PX2HashValue; overload;
  public
    function GetEnumerator(): TX2HashPointerEnumerator;

    function Exists(const AKey: Pointer): Boolean; overload;
    function Delete(const AKey: Pointer): Boolean; overload;

    property CurrentKey:      Pointer read GetCurrentKey;
  end;

  {
    :$ Base hash implementation for integer keys.
  }
  TX2CustomIntegerHash  = class(TX2CustomHash)
  private
    function GetCurrentKey(): Integer;
  protected
    function CreateKeyManager(): TX2CustomHashManager; override;
    function Find(const AKey: Integer;
                  const AAllowCreate: Boolean): PX2HashValue; overload;
  public
    function GetEnumerator(): TX2HashIntegerEnumerator;

    function Exists(const AKey: Integer): Boolean; overload;
    function Delete(const AKey: Integer): Boolean; overload;

    property CurrentKey:      Integer read GetCurrentKey;
  end;

  {
    :$ Base hash implementation for object keys.
  }
  TX2CustomObjectHash  = class(TX2CustomHash)
  private
    function GetCurrentKey(): TObject;
  protected
    function CreateKeyManager(): TX2CustomHashManager; override;
    function Find(const AKey: TObject;
                  const AAllowCreate: Boolean): PX2HashValue; overload;
  public
    function GetEnumerator(): TX2HashObjectEnumerator;

    function Exists(const AKey: TObject): Boolean; overload;
    function Delete(const AKey: TObject): Boolean; overload;

    property CurrentKey:      TObject read GetCurrentKey;
  end;

  {
    :$ Base hash implementation for string keys.
  }
  TX2CustomStringHash = class(TX2CustomHash)
  protected
    function GetCurrentKey(): String;
  protected
    function CreateKeyManager(): TX2CustomHashManager; override;
    function Find(const AKey: String;
                  const AAllowCreate: Boolean): PX2HashValue; overload;
  public
    function GetEnumerator(): TX2HashStringEnumerator;

    function Exists(const AKey: String): Boolean; overload;
    function Delete(const AKey: String): Boolean; overload;

    property CurrentKey:      String  read GetCurrentKey;
  end;
  {$ENDREGION}

  {$REGION 'Concrete hash classes'}
  {
    :$ Pointer-to-Pointer hash.
  }
  TX2PPHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue(): Pointer;
    function GetValue(Key: Pointer): Pointer;
    procedure SetValue(Key: Pointer; const Value: Pointer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Pointer read GetCurrentValue;
    property Values[Key: Pointer]:    Pointer read GetValue write SetValue; default;
  end;

  {
    :$ Pointer-to-Integer hash.
  }
  TX2PIHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue(): Integer;
    function GetValue(Key: Pointer): Integer;
    procedure SetValue(Key: Pointer; const Value: Integer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Integer read GetCurrentValue;
    property Values[Key: Pointer]:    Integer read GetValue write SetValue; default;
  end;

  {
    :$ Pointer-to-Object hash.
  }
  TX2POHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue(): TObject;
    function GetOwnsObjects(): Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: Pointer): TObject;
    procedure SetValue(Key: Pointer; const Value: TObject);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:            TObject read GetCurrentValue;
    property OwnsObjects:             Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: Pointer]:    TObject read GetValue       write SetValue; default;
  end;

  {
    :$ Pointer-to-String hash.
  }
  TX2PSHash     = class(TX2CustomPointerHash)
  protected
    function GetCurrentValue(): String;
    function GetValue(Key: Pointer): String;
    procedure SetValue(Key: Pointer; const Value: String);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            String  read GetCurrentValue;
    property Values[Key: Pointer]:    String  read GetValue write SetValue; default;
  end;

  {
    :$ Integer-to-Pointer hash.
  }
  TX2IPHash     = class(TX2CustomIntegerHash)
  protected
    function GetCurrentValue(): Pointer;
    function GetValue(Key: Integer): Pointer;
    procedure SetValue(Key: Integer; const Value: Pointer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Pointer read GetCurrentValue;
    property Values[Key: Integer]:    Pointer read GetValue write SetValue; default;
  end;

  {
    :$ Integer-to-Integer hash.
  }
  TX2IIHash     = class(TX2CustomIntegerHash)
  protected
    function GetCurrentValue(): Integer;
    function GetValue(Key: Integer): Integer;
    procedure SetValue(Key: Integer; const Value: Integer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Integer read GetCurrentValue;
    property Values[Key: Integer]:    Integer read GetValue write SetValue; default;
  end;

  {
    :$ Integer-to-Object hash.
  }
  TX2IOHash     = class(TX2CustomIntegerHash)
  protected
    function GetCurrentValue(): TObject;
    function GetOwnsObjects(): Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: Integer): TObject;
    procedure SetValue(Key: Integer; const Value: TObject);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:            TObject read GetCurrentValue;
    property OwnsObjects:             Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: Integer]:    TObject read GetValue       write SetValue; default;
  end;

  {
    :$ Integer-to-String hash.
  }
  TX2ISHash     = class(TX2CustomIntegerHash)
  protected
    function GetCurrentValue(): String;
    function GetValue(Key: Integer): String;
    procedure SetValue(Key: Integer; const Value: String);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            String  read GetCurrentValue;
    property Values[Key: Integer]:    String  read GetValue write SetValue; default;
  end;

  {
    :$ Object-to-Pointer hash.
  }
  TX2OPHash     = class(TX2CustomObjectHash)
  protected
    function GetCurrentValue(): Pointer;
    function GetValue(Key: TObject): Pointer;
    procedure SetValue(Key: TObject; const Value: Pointer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Pointer read GetCurrentValue;
    property Values[Key: TObject]:    Pointer read GetValue write SetValue; default;
  end;

  {
    :$ Object-to-Integer hash.
  }
  TX2OIHash     = class(TX2CustomObjectHash)
  protected
    function GetCurrentValue(): Integer;
    function GetValue(Key: TObject): Integer;
    procedure SetValue(Key: TObject; const Value: Integer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Integer read GetCurrentValue;
    property Values[Key: TObject]:    Integer read GetValue write SetValue; default;
  end;

  {
    :$ Object-to-Object hash.
  }
  TX2OOHash     = class(TX2CustomObjectHash)
  protected
    function GetCurrentValue(): TObject;
    function GetOwnsObjects(): Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: TObject): TObject;
    procedure SetValue(Key: TObject; const Value: TObject);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:            TObject read GetCurrentValue;
    property OwnsObjects:             Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: TObject]:    TObject read GetValue       write SetValue; default;
  end;

  {
    :$ Object-to-String hash.
  }
  TX2OSHash     = class(TX2CustomObjectHash)
  protected
    function GetCurrentValue(): String;
    function GetValue(Key: TObject): String;
    procedure SetValue(Key: TObject; const Value: String);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            String  read GetCurrentValue;
    property Values[Key: TObject]:    String  read GetValue write SetValue; default;
  end;

  {
    :$ String-to-Pointer hash.
  }
  TX2SPHash     = class(TX2CustomStringHash)
  protected
    function GetCurrentValue(): Pointer;
    function GetValue(Key: String): Pointer;
    procedure SetValue(Key: String; const Value: Pointer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Pointer read GetCurrentValue;
    property Values[Key: String]:     Pointer read GetValue write SetValue; default;
  end;

  {
    :$ String-to-Integer hash.
  }
  TX2SIHash     = class(TX2CustomStringHash)
  protected
    function GetCurrentValue(): Integer;
    function GetValue(Key: String): Integer;
    procedure SetValue(Key: String; const Value: Integer);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            Integer read GetCurrentValue;
    property Values[Key: String]:     Integer read GetValue write SetValue; default;
  end;

  {
    :$ String-to-Object hash.
  }
  TX2SOHash     = class(TX2CustomStringHash)
  protected
    function GetCurrentValue(): TObject;
    function GetOwnsObjects(): Boolean;
    procedure SetOwnsObjects(const Value: Boolean);
    function GetValue(Key: String): TObject;
    procedure SetValue(Key: String; const Value: TObject);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    constructor Create(const AOwnsObjects: Boolean = False); reintroduce;

    property CurrentValue:            TObject read GetCurrentValue;
    property OwnsObjects:             Boolean read GetOwnsObjects write SetOwnsObjects;
    property Values[Key: String]:     TObject read GetValue       write SetValue; default;
  end;

  {
    :$ String-to-String hash.
  }
  TX2SSHash     = class(TX2CustomStringHash)
  protected
    function GetCurrentValue(): String;
    function GetValue(Key: String): String;
    procedure SetValue(Key: String; const Value: String);
  protected
    function CreateValueManager(): TX2CustomHashManager; override;
  public
    property CurrentValue:            String  read GetCurrentValue;
    property Values[Key: String]:     String  read GetValue write SetValue; default;
  end;
  {$ENDREGION}

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
procedure CRC32Init();
var
  iItem:      Integer;
  iPoly:      Integer;
  iValue:     Cardinal;

begin
  for iItem := 255 downto 0 do
  begin
    iValue  := iItem;

    for iPoly := 8 downto 1 do
      if (iValue and $1) <> 0 then
        iValue  := (iValue shr $1) xor CRC32Poly
      else
        iValue  := iValue shr $1;

    CRC32Table[iItem] := iValue;
  end;
end;

function CRC32(const AKey: Pointer; const ASize: Cardinal): Cardinal;
var
  iByte:      Integer;
  pByte:      ^Byte;

begin
  Result  := $FFFFFFFF;
  pByte   := AKey;

  for iByte := Pred(ASize) downto 0 do
  begin
    Result  := (((Result shr 8) and $00FFFFFF) xor
                (CRC32Table[(Result xor pByte^) and $FF]));
    Inc(pByte);
  end;
end;


{$REGION 'Internal hash structures'}
{========================================
  TX2HashCursor
========================================}
constructor TX2HashCursor.Create(const ABucket: PX2HashBucket);
begin
  inherited Create();

  SetLength(FBucketPath, 1);
  with FBucketPath[0] do
  begin
    Bucket  := ABucket;
    Index   := 0;
  end;

  FCurrent  := nil;
end;

function TX2HashCursor.GetCurrent(): PX2HashValue;
begin
  Result  := FCurrent;
end;


procedure TX2HashCursor.First();
begin
  if Length(FBucketPath) > 1 then
    SetLength(FBucketPath, 1);

  FBucketPath[0].Index  := 0;
  FCurrent              := nil;
end;

function TX2HashCursor.Next(): Boolean;
var
  bFound:     Boolean;
  iIndex:     Integer;
  pBucket:    PX2HashBucket;
  pItem:      PX2HashItem;

begin
  Result  := False;
  iIndex  := High(FBucketPath);
  if iIndex = -1 then
    exit;

  if (FCurrent <> nil) and (FCurrent^.Next <> nil) then
  begin
    FCurrent  := FCurrent^.Next;
    Result    := True;
    exit;
  end;

  repeat
    pBucket := FBucketPath[iIndex].Bucket;
    bFound  := False;

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
                Bucket  := PX2HashBucket(pItem);
                Index   := 0;
              end;
              bFound  := True;
              break;
            end;
          HIDValue:
            begin
              // Got a value
              FCurrent  := PX2HashValue(pItem);
              Result    := True;
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
{$ENDREGION}


{$REGION 'Internal value managers'}
{========================================
  TX2CustomHashManager
========================================}
procedure TX2CustomHashManager.Initialize(var AData: Pointer);
begin
  AData := nil;
end;

procedure TX2CustomHashManager.Finalize(var AData: Pointer);
begin
  AData := nil;
end;

function TX2CustomHashManager.DataSize(const AData: Pointer): Cardinal;
begin
  Result  := SizeOf(Pointer);
end;

function TX2CustomHashManager.DataPointer(const AData: Pointer): Pointer;
begin
  Result  := AData;
end;

function TX2CustomHashManager.ToPointer(const AValue: Pointer;
                                        const ASize: Cardinal): Pointer;
begin
  Result  := Pointer(AValue^);
end;

function TX2CustomHashManager.ToValue(const AData: Pointer;
                                      var AValue): Cardinal;
begin
  Result          := DataSize(AData);
  Pointer(AValue) := AData;
end;

function TX2CustomHashManager.Compare(const AData: Pointer; const AValue: Pointer;
                                      const ASize: Cardinal): Boolean;
begin
  Result  := (Pointer(AValue^) = AData);
end;


{========================================
  TX2HashPointerManager
========================================}
function TX2HashPointerManager.ToPointer(const AValue: Pointer): Pointer;
begin
  Result  := ToPointer(@AValue, SizeOf(Pointer));
end;

function TX2HashPointerManager.ToValue(const AData: Pointer): Pointer;
begin
  ToValue(AData, Result);
end;


{========================================
  TX2HashIntegerManager
========================================}
function TX2HashIntegerManager.ToPointer(const AValue: Integer): Pointer;
begin
  Result  := ToPointer(@AValue, SizeOf(Integer));
end;

function TX2HashIntegerManager.ToValue(const AData: Pointer): Integer;
begin
  ToValue(AData, Result);
end;


{========================================
  TX2HashObjectManager
========================================}
procedure TX2HashObjectManager.Finalize(var AData: Pointer);
begin
  if (AData <> nil) and (FOwnsObjects) then
    TObject(AData).Free();

  inherited;
end;

function TX2HashObjectManager.ToPointer(const AValue: TObject): Pointer;
begin
  Result  := ToPointer(@AValue, SizeOf(Integer));
end;

function TX2HashObjectManager.ToValue(const AData: Pointer): TObject;
begin
  ToValue(AData, Result);
end;


{========================================
  TX2HashStringManager
========================================}
procedure TX2HashStringManager.Finalize(var AData: Pointer);
begin
  if AData <> nil then
    FreeMem(AData, PCardinal(AData)^ + SizeOf(Cardinal));
    
  inherited;
end;

function TX2HashStringManager.DataSize(const AData: Pointer): Cardinal;
begin
  Result  := PCardinal(AData)^;
end;

function TX2HashStringManager.DataPointer(const AData: Pointer): Pointer;
begin
  Result  := AData;
  Inc(PCardinal(Result));
end;

function TX2HashStringManager.ToPointer(const AValue: Pointer;
                                        const ASize: Cardinal): Pointer;
var
  pData:      Pointer;

begin
  // Add a 4-byte Length to the start, emulating AnsiStrings
  // (except for the reference counting) 
  GetMem(Result, ASize + SizeOf(Cardinal));
  PCardinal(Result)^  := ASize;
  pData               := Result;
  Inc(PCardinal(pData));
  Move(AValue^, pData^, ASize);
end;

function TX2HashStringManager.ToValue(const AData: Pointer;
                                      var AValue): Cardinal;
var
  pData:      Pointer;
  
begin
  Result  := DataSize(AData);
  pData   := DataPointer(AData);

  SetLength(String(AValue), Result);
  if Result > 0 then
    Move(pData^, PChar(String(AValue))^, Result);
end;

function TX2HashStringManager.ToPointer(const AValue: String): Pointer;
begin
  Result  := ToPointer(PChar(AValue), Length(AValue));
end;


function TX2HashStringManager.ToValue(const AData: Pointer): String;
begin
  ToValue(AData, Result);
end;

function TX2HashStringManager.Compare(const AData: Pointer; const AValue: Pointer;
                                      const ASize: Cardinal): Boolean;
var
  pSource:      PChar;

begin
  Result  := False;
  if ASize <> PCardinal(AData)^ then
    exit;

  pSource := AData;
  Inc(PCardinal(pSource));

  Result  := CompareMem(pSource, AValue, ASize);
end;
{$ENDREGION}


{$REGION 'Abstract hash implementation'}
{========================== TX2CustomHash
  Initialization
========================================}
constructor TX2CustomHash.Create();
begin
  inherited;

  FKeyManager   := CreateKeyManager();
  FValueManager := CreateValueManager();
end;

destructor TX2CustomHash.Destroy();
begin
  Clear();
  FreeAndNil(FValueManager);
  FreeAndNil(FKeyManager);
  FreeAndNil(FCursor);

  inherited;
end;


function TX2CustomHash.CreateCursor(): TX2HashCursor;
begin
  Result  := nil;
  if Assigned(FRoot) then
    Result  := TX2HashCursor.Create(FRoot);
end;

procedure TX2CustomHash.InvalidateCursor();
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

function TX2CustomHash.Hash(const AKey: Pointer; const ASize: Cardinal): Cardinal;
begin
  Result  := CRC32(AKey, ASize);
end;

function TX2CustomHash.CursorRequired(const ARaiseException: Boolean): Boolean;
begin
  Result  := True;
  if not Assigned(FCursor) then
    if Assigned(FRoot) then
      FCursor := CreateCursor()
    else
    begin
      Result  := False;
      if ARaiseException then
        raise EX2HashNoCursor.Create('Cursor not available!');
    end;
end;


function TX2CustomHash.InternalFind(const ABucket: PX2HashBucket;
                                    const AHash: Cardinal; const AKey: Pointer;
                                    const ASize: Cardinal;
                                    const AAllowCreate: Boolean;
                                    const AExisting: PX2HashValue): PX2HashValue;
  function CreateValue(): PX2HashValue;
  begin
    if AExisting = nil then
    begin
      GetMem(Result, SizeOf(TX2HashValue));
      FillChar(Result^, SizeOf(TX2HashValue), #0);

      Result^.ID  := HIDValue;
      Result^.Key := FKeyManager.ToPointer(AKey, ASize);
      Inc(FCount);
    end else
      Result      := AExisting;

    InvalidateCursor();
  end;

var
  iCount:     Integer;
  iIndex:     Integer;
  iKey:       Integer;
  pBucket:    PX2HashBucket;
  pKey:       Pointer;
  pNext:      PX2HashValue;
  pValue:     PX2HashValue;

begin
  Result  := nil;
  iIndex  := (AHash and $FF);

  if ABucket^.Items[iIndex] = nil then
  begin
    if AAllowCreate then
    begin
      // New value
      Result                  := CreateValue();
      ABucket^.Items[iIndex]  := PX2HashItem(Result);
      Inc(ABucket^.Count);
    end;
  end else
    case ABucket^.Items[iIndex]^.ID of
      HIDBucket:
        // Bucket, continue down
        Result  := InternalFind(PX2HashBucket(ABucket^.Items[iIndex]),
                                ROR(AHash), AKey, ASize, AAllowCreate);
      HIDValue:
        begin
          iCount  := 0;
          pValue  := PX2HashValue(ABucket^.Items[iIndex]);
          while pValue <> nil do
          begin
            if FKeyManager.Compare(pValue^.Key, AKey, ASize) then
            begin
              // Found existing key
              Result  := pValue;
              exit;
            end;

            pValue  := pValue^.Next;
            Inc(iCount);
          end;

          if AAllowCreate then
            if (iCount >= BucketSize) then
            begin
              // Bucket full
              GetMem(pBucket, SizeOf(TX2HashBucket));
              FillChar(pBucket^, SizeOf(TX2HashBucket), #0);
              pBucket^.ID     := HIDBucket;
              pBucket^.Level  := ABucket^.Level + 1;

              pValue          := PX2HashValue(ABucket^.Items[iIndex]);
              while pValue <> nil do
              begin
                // Transfer item
                iKey          := FKeyManager.DataSize(pValue^.Key);
                pKey          := FKeyManager.DataPointer(pValue^.Key);
                pNext         := pValue^.Next;
                pValue^.Next  := nil;

                InternalFind(pBucket, ROR(Hash(pKey, iKey), pBucket^.Level * 8),
                             pKey, iKey, True, pValue);


                pValue        := pNext;
              end;

              Result                  := InternalFind(pBucket, ROR(AHash), AKey, ASize, True);
              ABucket^.Items[iIndex]  := PX2HashItem(pBucket);
            end else
            begin
              // New value
              Result                  := CreateValue();
              Result^.Next            := PX2HashValue(ABucket^.Items[iIndex]);
              ABucket^.Items[iIndex]  := PX2HashItem(Result);
            end;
        end;
    end;
end;

function TX2CustomHash.InternalDelete(const ABucket: PX2HashBucket;
                                      const AHash: Cardinal;
                                      const AKey: Pointer;
                                      const ASize: Cardinal): Boolean;
var
  iIndex:     Integer;
  pBucket:    PX2HashBucket;
  pPrev:      PX2HashValue;
  pValue:     PX2HashValue;

begin
  Result  := False;
  iIndex  := (AHash and $FF);

  if ABucket^.Items[iIndex] <> nil then
    case ABucket^.Items[iIndex]^.ID of
      HIDBucket:
        begin
          // Bucket, continue down
          pBucket := PX2HashBucket(ABucket^.Items[iIndex]);
          Result  := InternalDelete(pBucket, ROR(AHash), AKey, ASize);

          if pBucket^.Count = 0 then
          begin
            FreeMem(pBucket, SizeOf(TX2HashBucket));
            ABucket^.Items[iIndex]  := nil;
          end;
        end;
      HIDValue:
        begin
          pPrev   := nil;
          pValue  := PX2HashValue(ABucket^.Items[iIndex]);
          while pValue <> nil do
          begin
            if FKeyManager.Compare(pValue^.Key, AKey, ASize) then
            begin
              // Found key
              if pPrev = nil then
              begin
                ABucket^.Items[iIndex]  := PX2HashItem(pValue^.Next);
                if ABucket^.Items[iIndex] = nil then
                  Dec(ABucket^.Count);
              end else
                pPrev^.Next := pValue^.Next;

              FKeyManager.Finalize(pValue^.Key);
              FValueManager.Finalize(pValue^.Value);
              FreeMem(pValue, SizeOf(TX2HashValue));
              Dec(FCount);

              Result  := True;
              exit;
            end;

            pPrev   := pValue;
            pValue  := pValue^.Next;
          end;
        end;
    end;
end;


function TX2CustomHash.Find(const AKey: Pointer; const ASize: Cardinal;
                            const AAllowCreate: Boolean): PX2HashValue;
begin
  Result  := nil;
  if not Assigned(FRoot) then
    if AAllowCreate then
    begin
      // Create root bucket
      GetMem(FRoot, SizeOf(TX2HashBucket));
      FillChar(FRoot^, SizeOf(TX2HashBucket), #0);
      FRoot^.ID := HIDBucket;
    end else
      exit;

  Result  := InternalFind(FRoot, Hash(AKey, ASize), AKey, ASize,
                          AAllowCreate);
end;


procedure TX2CustomHash.Clear();
  procedure DestroyBucket(const ABucket: PX2HashBucket);
  var
    iItem:        Integer;
    pNext:        PX2HashValue;
    pValue:       PX2HashValue;

  begin
    for iItem := Pred(LeafSize) downto 0 do
      if ABucket^.Items[iItem] <> nil then
        case ABucket^.Items[iItem].ID of
          HIDBucket:
            DestroyBucket(PX2HashBucket(ABucket^.Items[iItem]));
          HIDValue:
            begin
              pValue  := PX2HashValue(ABucket^.Items[iItem]);
              repeat
                FKeyManager.Finalize(pValue^.Key);
                FValueManager.Finalize(pValue^.Value);

                pNext   := pValue^.Next;
                FreeMem(pValue, SizeOf(TX2HashValue));
                pValue  := pNext;
              until pValue = nil;
            end;
        end;

    FreeMem(ABucket, SizeOf(TX2HashBucket));
  end;

begin
  if FRoot <> nil then
  begin
    DestroyBucket(FRoot);
    FCount  := 0;
    FRoot   := nil;
  end;
end;


function TX2CustomHash.Exists(const AKey: Pointer;
                              const ASize: Cardinal): Boolean;
begin
  Result  := (Assigned(FRoot) and (Find(AKey, ASize, False) <> nil));
end;

function TX2CustomHash.Delete(const AKey: Pointer;
                              const ASize: Cardinal): Boolean;
begin
  Result  := False;
  if not Assigned(FRoot) then
    exit;

  Result  := InternalDelete(FRoot, Hash(AKey, ASize), AKey, ASize);
  if Result then
    InvalidateCursor();
end;


procedure TX2CustomHash.SetValue(const AValue: PX2HashValue;
                                 const AData: Pointer);
begin
  ValueManager.Finalize(AValue^.Value);
  AValue^.Value := AData;
end;



procedure TX2CustomHash.First();
begin
  if not CursorRequired(False) then
    exit;

  Cursor.First();
end;

function TX2CustomHash.Next(): Boolean;
begin
  Result  := False;
  if not CursorRequired(False) then
    exit;

  Result  := Cursor.Next();
end;
{$ENDREGION}


{$REGION 'Delphi 2006 enumerator support'}
{========================================
  TX2HashEnumerator
========================================}
constructor TX2HashEnumerator.Create(const AHash: TX2CustomHash;
                                     const AEnumKeys: Boolean);
begin
  inherited Create();

  FEnumKeys := AEnumKeys;
  if AEnumKeys then
    FManager  := AHash.KeyManager
  else
    FManager  := AHash.ValueManager;

  FCursor   := AHash.CreateCursor();
end;

destructor TX2HashEnumerator.Destroy();
begin
  FreeAndNil(FCursor);

  inherited;
end;

function TX2HashEnumerator.GetCursor(): Pointer;
begin
  if FEnumKeys then
    Result  := FCursor.Current^.Key
  else
    Result  := FCursor.Current^.Value;
end;

function TX2HashEnumerator.MoveNext(): Boolean;
begin
  Result  := False;
  if Assigned(FCursor) then
    Result  := FCursor.Next();
end;


{ TX2HashPointerEnumerator }
function TX2HashPointerEnumerator.GetCurrent(): Pointer;
begin
  Result  := TX2HashPointerManager(Manager).ToValue(Cursor);
end;

{ TX2HashIntegerEnumerator }
function TX2HashIntegerEnumerator.GetCurrent(): Integer;
begin
  Result  := TX2HashIntegerManager(Manager).ToValue(Cursor);
end;

{ TX2HashObjectEnumerator }
function TX2HashObjectEnumerator.GetCurrent(): TObject;
begin
  Result  := TX2HashObjectManager(Manager).ToValue(Cursor);
end;

{ TX2HashStringEnumerator }
function TX2HashStringEnumerator.GetCurrent(): String;
begin
  Result  := TX2HashStringManager(Manager).ToValue(Cursor);
end;
{$ENDREGION}


{$REGION 'Base hash classes'}
{========================================
  TX2CustomPointerHash
========================================}
function TX2CustomPointerHash.CreateKeyManager(): TX2CustomHashManager;
begin
  Result  := TX2HashPointerManager.Create();
end;

function TX2CustomPointerHash.GetCurrentKey(): Pointer;
begin
  CursorRequired();
  Result  := TX2HashPointerManager(KeyManager).ToValue(Cursor.Current^.Key);
end;

function TX2CustomPointerHash.GetEnumerator(): TX2HashPointerEnumerator;
begin
  Result  := TX2HashPointerEnumerator.Create(Self, True);
end;

function TX2CustomPointerHash.Find(const AKey: Pointer;
                                   const AAllowCreate: Boolean): PX2HashValue;
begin
  Result  := inherited Find(@AKey, SizeOf(Pointer), AAllowCreate);
end;

function TX2CustomPointerHash.Exists(const AKey: Pointer): Boolean;
begin
  Result  := inherited Exists(@AKey, SizeOf(Pointer));
end;

function TX2CustomPointerHash.Delete(const AKey: Pointer): Boolean;
begin
  Result  := inherited Delete(@AKey, SizeOf(Pointer));
end;


{========================================
  TX2CustomIntegerHash
========================================}
function TX2CustomIntegerHash.CreateKeyManager(): TX2CustomHashManager;
begin
  Result  := TX2HashIntegerManager.Create();
end;

function TX2CustomIntegerHash.GetCurrentKey(): Integer;
begin
  CursorRequired();
  Result  := TX2HashIntegerManager(KeyManager).ToValue(Cursor.Current^.Key);
end;

function TX2CustomIntegerHash.GetEnumerator(): TX2HashIntegerEnumerator;
begin
  Result  := TX2HashIntegerEnumerator.Create(Self, True);
end;

function TX2CustomIntegerHash.Find(const AKey: Integer;
                                   const AAllowCreate: Boolean): PX2HashValue;
begin
  Result  := inherited Find(@AKey, SizeOf(Pointer), AAllowCreate);
end;

function TX2CustomIntegerHash.Exists(const AKey: Integer): Boolean;
begin
  Result  := inherited Exists(@AKey, SizeOf(Pointer));
end;

function TX2CustomIntegerHash.Delete(const AKey: Integer): Boolean;
begin
  Result  := inherited Delete(@AKey, SizeOf(Pointer));
end;


{========================================
  TX2CustomObjectHash
========================================}
function TX2CustomObjectHash.CreateKeyManager(): TX2CustomHashManager;
begin
  Result  := TX2HashObjectManager.Create();
end;

function TX2CustomObjectHash.GetCurrentKey(): TObject;
begin
  CursorRequired();
  Result  := TX2HashObjectManager(KeyManager).ToValue(Cursor.Current^.Key);
end;

function TX2CustomObjectHash.GetEnumerator(): TX2HashObjectEnumerator;
begin
  Result  := TX2HashObjectEnumerator.Create(Self, True);
end;

function TX2CustomObjectHash.Find(const AKey: TObject;
                                  const AAllowCreate: Boolean): PX2HashValue;
begin
  Result  := inherited Find(@AKey, SizeOf(Pointer), AAllowCreate);
end;

function TX2CustomObjectHash.Exists(const AKey: TObject): Boolean;
begin
  Result  := inherited Exists(@AKey, SizeOf(Pointer));
end;

function TX2CustomObjectHash.Delete(const AKey: TObject): Boolean;
begin
  Result  := inherited Delete(@AKey, SizeOf(Pointer));
end;


{========================================
  TX2CustomStringHash
========================================}
function TX2CustomStringHash.CreateKeyManager(): TX2CustomHashManager;
begin
  Result  := TX2HashStringManager.Create();
end;

function TX2CustomStringHash.GetCurrentKey(): String;
begin
  CursorRequired();
  Result  := TX2HashStringManager(KeyManager).ToValue(Cursor.Current^.Key);
end;


function TX2CustomStringHash.GetEnumerator(): TX2HashStringEnumerator;
begin
  Result  := TX2HashStringEnumerator.Create(Self, True);
end;

function TX2CustomStringHash.Find(const AKey: String;
                                  const AAllowCreate: Boolean): PX2HashValue;
begin
  Result  := inherited Find(PChar(AKey), Length(AKey), AAllowCreate);
end;

function TX2CustomStringHash.Exists(const AKey: String): Boolean;
begin
  Result  := inherited Exists(PChar(AKey), Length(AKey));
end;

function TX2CustomStringHash.Delete(const AKey: String): Boolean;
begin
  Result  := inherited Delete(PChar(AKey), Length(AKey));
end;
{$ENDREGION}


{$REGION 'Concrete hash classes'}
{========================================
  TX2PPHash
========================================}
function TX2PPHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashPointerManager.Create();
end;

function TX2PPHash.GetCurrentValue(): Pointer;
begin
  CursorRequired();
  Result  := TX2HashPointerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2PPHash.GetValue(Key: Pointer): Pointer;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashPointerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2PPHash.SetValue(Key: Pointer; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashPointerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2PIHash
========================================}
function TX2PIHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashIntegerManager.Create();
end;

function TX2PIHash.GetCurrentValue(): Integer;
begin
  CursorRequired();
  Result  := TX2HashIntegerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2PIHash.GetValue(Key: Pointer): Integer;
var
  pItem:      PX2HashValue;

begin
  Result  := 0;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashIntegerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2PIHash.SetValue(Key: Pointer; const Value: Integer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashIntegerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2POHash
========================================}
constructor TX2POHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create();
  OwnsObjects := AOwnsObjects;
end;

function TX2POHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashObjectManager.Create();
end;

function TX2POHash.GetCurrentValue(): TObject;
begin
  Result  := TX2HashObjectManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2POHash.GetOwnsObjects(): Boolean;
begin
  Result  := TX2HashObjectManager(ValueManager).OwnsObjects;
end;

procedure TX2POHash.SetOwnsObjects(const Value: Boolean);
begin
  TX2HashObjectManager(ValueManager).OwnsObjects  := Value;
end;

function TX2POHash.GetValue(Key: Pointer): TObject;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashObjectManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2POHash.SetValue(Key: Pointer; const Value: TObject);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashObjectManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2PSHash
========================================}
function TX2PSHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashStringManager.Create();
end;

function TX2PSHash.GetCurrentValue(): String;
begin
  Result  := TX2HashStringManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2PSHash.GetValue(Key: Pointer): String;
var
  pItem:      PX2HashValue;

begin
  Result  := '';
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashStringManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2PSHash.SetValue(Key: Pointer; const Value: String);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashStringManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2IPHash
========================================}
function TX2IPHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashPointerManager.Create();
end;

function TX2IPHash.GetCurrentValue(): Pointer;
begin
  CursorRequired();
  Result  := TX2HashPointerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2IPHash.GetValue(Key: Integer): Pointer;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashPointerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2IPHash.SetValue(Key: Integer; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashPointerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2IIHash
========================================}
function TX2IIHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashIntegerManager.Create();
end;

function TX2IIHash.GetCurrentValue(): Integer;
begin
  CursorRequired();
  Result  := TX2HashIntegerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2IIHash.GetValue(Key: Integer): Integer;
var
  pItem:      PX2HashValue;

begin
  Result  := 0;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashIntegerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2IIHash.SetValue(Key: Integer; const Value: Integer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashIntegerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2IOHash
========================================}
constructor TX2IOHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create();
  OwnsObjects := AOwnsObjects;
end;

function TX2IOHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashObjectManager.Create();
end;

function TX2IOHash.GetCurrentValue(): TObject;
begin
  Result  := TX2HashObjectManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2IOHash.GetOwnsObjects(): Boolean;
begin
  Result  := TX2HashObjectManager(ValueManager).OwnsObjects;
end;

procedure TX2IOHash.SetOwnsObjects(const Value: Boolean);
begin
  TX2HashObjectManager(ValueManager).OwnsObjects  := Value;
end;

function TX2IOHash.GetValue(Key: Integer): TObject;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashObjectManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2IOHash.SetValue(Key: Integer; const Value: TObject);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashObjectManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2ISHash
========================================}
function TX2ISHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashStringManager.Create();
end;

function TX2ISHash.GetCurrentValue(): String;
begin
  Result  := TX2HashStringManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2ISHash.GetValue(Key: Integer): String;
var
  pItem:      PX2HashValue;

begin
  Result  := '';
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashStringManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2ISHash.SetValue(Key: Integer; const Value: String);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashStringManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2OPHash
========================================}
function TX2OPHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashPointerManager.Create();
end;

function TX2OPHash.GetCurrentValue(): Pointer;
begin
  CursorRequired();
  Result  := TX2HashPointerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2OPHash.GetValue(Key: TObject): Pointer;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashPointerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2OPHash.SetValue(Key: TObject; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashPointerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2OIHash
========================================}
function TX2OIHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashIntegerManager.Create();
end;

function TX2OIHash.GetCurrentValue(): Integer;
begin
  CursorRequired();
  Result  := TX2HashIntegerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2OIHash.GetValue(Key: TObject): Integer;
var
  pItem:      PX2HashValue;

begin
  Result  := 0;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashIntegerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2OIHash.SetValue(Key: TObject; const Value: Integer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashIntegerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2OOHash
========================================}
constructor TX2OOHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create();
  OwnsObjects := AOwnsObjects;
end;

function TX2OOHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashObjectManager.Create();
end;

function TX2OOHash.GetCurrentValue(): TObject;
begin
  Result  := TX2HashObjectManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2OOHash.GetOwnsObjects(): Boolean;
begin
  Result  := TX2HashObjectManager(ValueManager).OwnsObjects;
end;

procedure TX2OOHash.SetOwnsObjects(const Value: Boolean);
begin
  TX2HashObjectManager(ValueManager).OwnsObjects  := Value;
end;

function TX2OOHash.GetValue(Key: TObject): TObject;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashObjectManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2OOHash.SetValue(Key: TObject; const Value: TObject);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashObjectManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2OSHash
========================================}
function TX2OSHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashStringManager.Create();
end;

function TX2OSHash.GetCurrentValue(): String;
begin
  Result  := TX2HashStringManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2OSHash.GetValue(Key: TObject): String;
var
  pItem:      PX2HashValue;

begin
  Result  := '';
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashStringManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2OSHash.SetValue(Key: TObject; const Value: String);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashStringManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2SPHash
========================================}
function TX2SPHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashPointerManager.Create();
end;

function TX2SPHash.GetCurrentValue(): Pointer;
begin
  CursorRequired();
  Result  := TX2HashPointerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2SPHash.GetValue(Key: String): Pointer;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashPointerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2SPHash.SetValue(Key: String; const Value: Pointer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashPointerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2SIHash
========================================}
function TX2SIHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashIntegerManager.Create();
end;

function TX2SIHash.GetCurrentValue(): Integer;
begin
  CursorRequired();
  Result  := TX2HashIntegerManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2SIHash.GetValue(Key: String): Integer;
var
  pItem:      PX2HashValue;

begin
  Result  := 0;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashIntegerManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2SIHash.SetValue(Key: String; const Value: Integer);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashIntegerManager(ValueManager).ToPointer(Value));
end;

{========================================
  TX2SOHash
========================================}
constructor TX2SOHash.Create(const AOwnsObjects: Boolean);
begin
  inherited Create();
  OwnsObjects := AOwnsObjects;
end;

function TX2SOHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashObjectManager.Create();
end;

function TX2SOHash.GetCurrentValue(): TObject;
begin
  Result  := TX2HashObjectManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2SOHash.GetOwnsObjects(): Boolean;
begin
  Result  := TX2HashObjectManager(ValueManager).OwnsObjects;
end;

procedure TX2SOHash.SetOwnsObjects(const Value: Boolean);
begin
  TX2HashObjectManager(ValueManager).OwnsObjects  := Value;
end;

function TX2SOHash.GetValue(Key: String): TObject;
var
  pItem:      PX2HashValue;

begin
  Result  := nil;
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashObjectManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2SOHash.SetValue(Key: String; const Value: TObject);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashObjectManager(ValueManager).ToPointer(Value));
end;


{========================================
  TX2SSHash
========================================}
function TX2SSHash.CreateValueManager(): TX2CustomHashManager;
begin
  Result  := TX2HashStringManager.Create();
end;

function TX2SSHash.GetCurrentValue(): String;
begin
  Result  := TX2HashStringManager(ValueManager).ToValue(Cursor.Current^.Value);
end;

function TX2SSHash.GetValue(Key: String): String;
var
  pItem:      PX2HashValue;

begin
  Result  := '';
  pItem   := Find(Key, False);
  if Assigned(pItem) then
    Result  := TX2HashStringManager(ValueManager).ToValue(pItem^.Value);
end;

procedure TX2SSHash.SetValue(Key: String; const Value: String);
begin
  inherited SetValue(Find(Key, True),
                     TX2HashStringManager(ValueManager).ToPointer(Value));
end;
{$ENDREGION}


initialization
  CRC32Init();

end.
