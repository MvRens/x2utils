{
  :: X2UtHashes contains a base class for hashes (also known as associative
  :: arrays), as well as various default implementations.
  ::
  :: This unit contains code based on Bob Jenkins' optimized hashing algorithm:
  ::    http://burtleburtle.net/bob/hash/doobs.html
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtHashes;

interface
uses
  SysUtils,
  X2UtBinaryTree;

type
  {
    :$ Internal representation of a hash item
  }
  PX2UtHashItem   = ^TX2UtHashItem;
  TX2UtHashItem   = record
    Prev:           PX2UtHashItem;
    Next:           PX2UtHashItem;
    Key:            String;
    Data:           record end;
  end;

  {
    :$ Internal hash list
  }
  PX2UtHashList   = ^TX2UtHashList;
  TX2UtHashList   = record
    Root:           PX2UtHashItem;
  end;
  
  {
    :$ Hash implementation

    :: This class implements a hash without knowing anything about
    :: the data it contains.
  }
  TX2UtCustomHash = class(TX2UtCustomBTree)
  private
    FHashCursor:        PX2UtHashItem;
    FHashDataSize:      Cardinal;
    FHashItemSize:      Cardinal;

    function GetCurrentKey(): String;
    function GetHashTotalSize(): Cardinal;
  protected
    function Hash(const AValue: String): Cardinal; virtual;

    function GetItemData(const AItem: PX2UtHashItem): Pointer; virtual;
    function LookupItem(const AKey: String;
                        out ANode: PX2UtBTreeNode;
                        const ACanCreate: Boolean = False;
                        const ASetCursor: Boolean = False): PX2UtHashItem;

    procedure FreeNode(var ANode: PX2UtBTreeNode); override;

    procedure ClearCursor(); override;
    function ValidCursor(const ARaiseError: Boolean = True): Boolean; override;

    procedure InitHashItem(var AItem: PX2UtHashItem); virtual;
    procedure FreeHashItem(var AItem: PX2UtHashItem); virtual;

    property HashCursor:        PX2UtHashItem   read FHashCursor    write FHashCursor;
    property HashItemSize:      Cardinal        read FHashItemSize;
    property HashTotalSize:     Cardinal        read GetHashTotalSize;
    property HashDataSize:      Cardinal        read FHashDataSize  write FHashDataSize;

    //:$ Returns the key at the current cursor location.
    property CurrentKey:        String          read GetCurrentKey;
  public
    constructor Create(); override;

    //:$ Deletes an item from the hash.
    procedure Delete(const AKey: String);

    function Next(): Boolean; override;

    //:$ Checks if a key exists in the hash.
    //:: If the ASetCursor parameter is set to True, the cursor will be
    //:: positioned at the item if it is found.
    function Exists(const AKey: String; const ASetCursor: Boolean = False): Boolean;
  end;

  {
    :$ Hash implementation for pointer values
  }
  TX2UtHash       = class(TX2UtCustomHash)
  private
    function GetItem(Key: String): Pointer;
    procedure SetItem(Key: String; const Value: Pointer);

    function GetCurrentValue(): Pointer;
  public
    constructor Create(); override;
    property CurrentKey;

    //:$ Gets or sets an item.
    property Items[Key: String]:        Pointer read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location.
    property CurrentValue:      Pointer         read GetCurrentValue;
  end;

  {
    :$ Hash implementation for integer values
  }
  TX2UtIntegerHash  = class(TX2UtHash)
  private
    function GetItem(Key: String): Integer;
    procedure SetItem(Key: String; const Value: Integer);

    function GetCurrentValue(): Integer;
  public
    //:$ Gets or sets an item.
    property Items[Key: String]:        Integer read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location.
    property CurrentValue:      Integer         read GetCurrentValue;
  end;


  {
    :$ Hash implementation for string values
  }
  TX2UtStringHash = class(TX2UtCustomHash)
  private
    function GetItem(Key: String): String;
    procedure SetItem(Key: String; const Value: String);

    function GetCurrentValue(): String;
  protected
    procedure InitHashItem(var AItem: PX2UtHashItem); override;
    procedure FreeHashItem(var AItem: PX2UtHashItem); override;
  public
    constructor Create(); override;
    property CurrentKey;

    //:$ Gets or sets an item.
    property Items[Key: String]:        String  read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location.
    property CurrentValue:      String          read GetCurrentValue;
  end;

implementation
resourcestring
  RSEmptyKey  = 'Cannot hash an empty key!';


{======================== TX2UtCustomHash
  Initialization
========================================}
constructor TX2UtCustomHash.Create;
begin
  inherited;

  FHashItemSize := SizeOf(TX2UtHashItem);
  DataSize      := FHashItemSize;
end;


{======================== TX2UtCustomHash
  Hashing
========================================}
procedure Mix(var A, B, C: Cardinal);
begin
  Dec(A, B); Dec(A, C); C := C shr 13;  A := A xor C;
  Dec(B, C); Dec(B, A); A := A shl 8;   B := B xor A;
  Dec(C, A); Dec(C, B); B := B shr 13;  C := C xor B;
  Dec(A, B); Dec(A, C); C := C shr 12;  A := A xor C;
  Dec(B, C); Dec(B, A); A := A shl 16;  B := B xor A;
  Dec(C, A); Dec(C, B); B := B shr 5;   C := C xor B;
  Dec(A, B); Dec(A, C); C := C shr 3;   A := A xor C;
  Dec(B, C); Dec(B, A); A := A shl 10;  B := B xor A;
  Dec(C, A); Dec(C, B); B := B shr 15;  C := C xor B;
end;

function TX2UtCustomHash.Hash;
var
  iA:         Cardinal;
  iB:         Cardinal;
  iC:         Cardinal;
  iLength:    Cardinal;
  pValue:     PChar;

begin
  iA      := $9e3779b9;
  iB      := iA;
  iC      := iA;
  iLength := Length(AValue);
  pValue  := PChar(AValue);

  // Handle most of the key
  while (iLength >= 12) do
  begin
    Inc(iA, Ord(pValue[0]) + (Ord(pValue[1]) shl 8) + (Ord(pValue[2]) shl 16) +
                             (Ord(pValue[3]) shl 24));
    Inc(iB, Ord(pValue[4]) + (Ord(pValue[5]) shl 8) + (Ord(pValue[6]) shl 16) +
                             (Ord(pValue[7]) shl 24));
    Inc(iA, Ord(pValue[8]) + (Ord(pValue[9]) shl 8) + (Ord(pValue[10]) shl 16) +
                             (Ord(pValue[11]) shl 24));

    Mix(iA, iB, iC);
    Inc(pValue, 12);
    Dec(iLength, 12);
  end;

  // Handle the last 11 bytes
  Inc(iC, iLength);

  while iLength > 0 do
  begin
    case iLength of
      11:   Inc(iC, Ord(pValue[10]) shr 24);
      10:   Inc(iC, Ord(pValue[9]) shr 16);
      9:    Inc(iC, Ord(pValue[8]) shr 8);
      8:    Inc(iB, Ord(pValue[7]) shr 24);
      7:    Inc(iB, Ord(pValue[6]) shr 16);
      6:    Inc(iB, Ord(pValue[5]) shr 8);
      5:    Inc(iB, Ord(pValue[4]));
      4:    Inc(iA, Ord(pValue[3]) shr 24);
      3:    Inc(iA, Ord(pValue[2]) shr 16);
      2:    Inc(iA, Ord(pValue[1]) shr 8);
      1:    Inc(iA, Ord(pValue[0]));
    end;

    Dec(iLength);
  end;

  Mix(iA, iB, iC);
  Result  := iC;
end;



{======================== TX2UtCustomHash
  Tree Traversing
========================================}
function TX2UtCustomHash.ValidCursor;
begin
  Result  := inherited ValidCursor(ARaiseError);
  if Result then
  begin
    Result  := Assigned(FHashCursor);

    if (not Result) and (ARaiseError) then
      raise EX2UtBTreeInvalidCursor.Create(RSInvalidCursor);
  end;
end;

procedure TX2UtCustomHash.ClearCursor;
begin
  inherited;

  FHashCursor := nil;
end;

function TX2UtCustomHash.Next;
begin
  if Assigned(FHashCursor) then
    FHashCursor := FHashCursor^.Next;

  if not Assigned(FHashCursor) then
  begin
    Result  := inherited Next();
    if Result then
      FHashCursor := PX2UtHashList(GetNodeData(Cursor))^.Root;
  end else
    Result  := True;
end;


{======================== TX2UtCustomHash
  Item Management
========================================}
function TX2UtCustomHash.GetItemData;
begin
  Assert(HashDataSize > 0, RSInvalidDataSize);
  Result  := Pointer(Cardinal(AItem) + HashItemSize);
end;

function TX2UtCustomHash.LookupItem;
var
  iIndex:     Cardinal;
  pData:      PX2UtHashList;
  pFound:     PX2UtHashItem;
  pItem:      PX2UtHashItem;
  pLast:      PX2UtHashItem;

begin
  Result  := nil;
  iIndex  := Hash(AKey);
  ANode   := inherited LookupNode(iIndex, ACanCreate, ASetCursor);

  if Assigned(ANode) then
  begin
    pData := PX2UtHashList(GetNodeData(ANode));
    pItem := pData^.Root;
    pLast := nil;

    if Assigned(pItem) then
    begin
      pFound  := nil;

      // Find key
      repeat
        if pItem.Key = AKey then
        begin
          pFound  := pItem;
          break;
        end;

        pLast := pItem;
        pItem := pItem^.Next;
      until not Assigned(pItem);

      pItem := pFound;
    end;

    if Assigned(pItem) then
      Result      := pItem
    else if ACanCreate then
    begin
      InitHashItem(pItem);

      if not Assigned(pData^.Root) then
        pData^.Root := pItem;

      if Assigned(pLast) then
        pLast^.Next := pItem;

      pItem^.Prev := pLast;
      pItem^.Next := nil;
      pItem^.Key  := AKey;
      Result      := pItem;
    end else
      Result      := nil;
  end;

  if Assigned(Result) and ASetCursor then
    FHashCursor := Result;
end;


procedure TX2UtCustomHash.Delete;
var
  bFree:      Boolean;
  pData:      PX2UtHashList;
  pNode:      PX2UtBTreeNode;
  pItem:      PX2UtHashItem;

begin
  pItem := LookupItem(AKey, pNode);
  if Assigned(pItem) then
  begin
    pData := GetItemData(pItem);

    if pData^.Root = pItem then
    begin
      if Assigned(pItem^.Next) then
        pData^.Root := pItem^.Next
      else if Assigned(pItem^.Prev) then
        pData^.Root := pItem^.Prev
      else
        pData^.Root := nil;
    end;

    bFree := (not Assigned(pData^.Root));
    FreeHashItem(pItem);

    if bFree then
      FreeNode(pNode);
  end;

  inherited Delete(Hash(AKey));
end;

function TX2UtCustomHash.Exists;
begin
  Result  := inherited Exists(Hash(AKey), ASetCursor);
end;


function TX2UtCustomHash.GetCurrentKey;
begin
  Result  := '';
  if ValidCursor(True) then
    Result  := HashCursor^.Key;
end;


procedure TX2UtCustomHash.FreeNode;
var
  pData:        PX2UtHashItem;
  pNext:        PX2UtHashItem;

begin
  pData := PX2UtHashList(GetNodeData(ANode))^.Root;
  while Assigned(pData) do
  begin
    pNext := pData^.Next;
    FreeHashItem(pData);
    pData := pNext;
  end;

  inherited;
end;


procedure TX2UtCustomHash.InitHashItem;
begin
  Assert(HashDataSize > 0, RSInvalidDataSize);
  GetMem(AItem, HashTotalSize);
  FillChar(AItem^, HashTotalSize, #0);
end;

procedure TX2UtCustomHash.FreeHashItem;
begin
  if Assigned(AItem^.Prev) then
    AItem^.Prev^.Next := AItem^.Next;

  if Assigned(AItem^.Next) then
    AItem^.Next^.Prev := AItem^.Prev;

  FreeMem(AItem, HashTotalSize);
  ClearCursor();

  AItem := nil;
end;


function TX2UtCustomHash.GetHashTotalSize;
begin
  Result  := FHashItemSize + FHashDataSize;
end;


{============================== TX2UtHash
  Item Management
========================================}
constructor TX2UtHash.Create;
begin
  inherited;

  HashDataSize  := SizeOf(Pointer);
end;

function TX2UtHash.GetItem;
var
  pNode:        PX2UtBTreeNode;
  pItem:        PX2UtHashItem;

begin
  Assert(Length(Key) > 0, RSEmptyKey);
  pItem := LookupItem(Key, pNode);
  if Assigned(pItem) then
    Result  := PPointer(GetItemData(pItem))^;
end;

procedure TX2UtHash.SetItem;
var
  pNode:        PX2UtBTreeNode;
  pItem:        PX2UtHashItem;

begin
  Assert(Length(Key) > 0, RSEmptyKey);
  pItem := LookupItem(Key, pNode, True);
  if Assigned(pItem) then
    PPointer(GetItemData(pItem))^ := Value;
end;

function TX2UtHash.GetCurrentValue;
begin
  Result  := nil;
  if ValidCursor() then
    Result  := PPointer(GetItemData(HashCursor))^;
end;


{======================= TX2UtIntegerHash
  Item Management
========================================}
function TX2UtIntegerHash.GetItem;
begin
  Result  := Integer(inherited GetItem(Key));
end;

procedure TX2UtIntegerHash.SetItem;
begin
  inherited SetItem(Key, Pointer(Value));
end;

function TX2UtIntegerHash.GetCurrentValue;
begin
  Result  := Integer(inherited GetCurrentValue());
end;


{======================== TX2UtStringHash
  Item Management
========================================}
constructor TX2UtStringHash.Create;
begin
  inherited;

  HashDataSize  := SizeOf(PString);
end;

function TX2UtStringHash.GetItem;
var
  pNode:        PX2UtBTreeNode;
  pItem:        PX2UtHashItem;

begin
  Assert(Length(Key) > 0, RSEmptyKey);
  pItem := LookupItem(Key, pNode);
  if Assigned(pItem) then
    Result  := PString(GetItemData(pItem))^;
end;

procedure TX2UtStringHash.SetItem;
var
  pNode:        PX2UtBTreeNode;
  pItem:        PX2UtHashItem;

begin
  Assert(Length(Key) > 0, RSEmptyKey);
  pItem := LookupItem(Key, pNode, True);
  if Assigned(pItem) then
    PString(GetItemData(pItem))^  := Value;
end;


procedure TX2UtStringHash.InitHashItem;
var
  pData:        PString;

begin
  inherited;

  pData := GetItemData(AItem);
  Initialize(pData^);
end;

procedure TX2UtStringHash.FreeHashItem;
var
  pData:        PString;

begin
  pData := GetItemData(AItem);
  Finalize(pData^);

  inherited;
end;


function TX2UtStringHash.GetCurrentValue;
begin
  Result  := '';
  if ValidCursor() then
    Result  := PString(GetItemData(HashCursor))^;
end;

end.
