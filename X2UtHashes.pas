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
    Value:          record end;
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
  (*
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
  *)

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


  procedure Mix(var A, B, C: Cardinal);
  
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
asm
  sub A, B; sub A, C; shr C, 13;  xor A, C;
  sub B, C; sub B, A; shl A, 8;   xor B, A;
  sub C, A; sub C, B; shr B, 13;  xor C, B;
  sub A, B; sub A, C; shr C, 12;  xor A, C;
  sub B, C; sub B, A; shl A, 16;  xor B, A;
  sub C, A; sub C, B; shr B, 5;   xor C, B;
  sub A, B; sub A, C; shr C, 3;   xor A, C;
  sub B, C; sub B, A; shl A, 10;  xor B, A;
  sub C, A; sub C, B; shr B, 15;  xor C, B;
end;

function TX2UtCustomHash.Hash;
begin
  Result  := 0;

  (*
ypedef  unsigned long  int  ub4;   /* unsigned 4-byte quantities */
typedef  unsigned       char ub1;   /* unsigned 1-byte quantities */

#define hashsize(n) ((ub4)1<<(n))
#define hashmask(n) (hashsize(n)-1)

/*
--------------------------------------------------------------------
mix -- mix 3 32-bit values reversibly.
For every delta with one or two bits set, and the deltas of all three
  high bits or all three low bits, whether the original value of a,b,c
  is almost all zero or is uniformly distributed,
* If mix() is run forward or backward, at least 32 bits in a,b,c
  have at least 1/4 probability of changing.
* If mix() is run forward, every bit of c will change between 1/3 and
  2/3 of the time.  (Well, 22/100 and 78/100 for some 2-bit deltas.)
mix() was built out of 36 single-cycle latency instructions in a 
  structure that could supported 2x parallelism, like so:
      a -= b; 
      a -= c; x = (c>>13);
      b -= c; a ^= x;
      b -= a; x = (a<<8);
      c -= a; b ^= x;
      c -= b; x = (b>>13);
      ...
  Unfortunately, superscalar Pentiums and Sparcs can't take advantage 
  of that parallelism.  They've also turned some of those single-cycle
  latency instructions into multi-cycle latency instructions.  Still,
  this is the fastest good hash I could find.  There were about 2^^68
  to choose from.  I only looked at a billion or so.
--------------------------------------------------------------------
*/
#define mix(a,b,c) \
{ \
  a -= b; a -= c; a ^= (c>>13); \
  b -= c; b -= a; b ^= (a<<8); \
  c -= a; c -= b; c ^= (b>>13); \
  a -= b; a -= c; a ^= (c>>12);  \
  b -= c; b -= a; b ^= (a<<16); \
  c -= a; c -= b; c ^= (b>>5); \
  a -= b; a -= c; a ^= (c>>3);  \
  b -= c; b -= a; b ^= (a<<10); \
  c -= a; c -= b; c ^= (b>>15); \
}

/*
--------------------------------------------------------------------
hash() -- hash a variable-length key into a 32-bit value
  k       : the key (the unaligned variable-length array of bytes)
  len     : the length of the key, counting by bytes
  initval : can be any 4-byte value
Returns a 32-bit value.  Every bit of the key affects every bit of
the return value.  Every 1-bit and 2-bit delta achieves avalanche.
About 6*len+35 instructions.

The best hash table sizes are powers of 2.  There is no need to do
mod a prime (mod is sooo slow!).  If you need less than 32 bits,
use a bitmask.  For example, if you need only 10 bits, do
  h = (h & hashmask(10));
In which case, the hash table should have hashsize(10) elements.

If you are hashing n strings (ub1 ** )k, do it like this:
  for (i=0, h=0; i<n; ++i) h = hash( k[i], len[i], h);

By Bob Jenkins, 1996.  bob_jenkins@burtleburtle.net.  You may use this
code any way you wish, private, educational, or commercial.  It's free.

See http://burtleburtle.net/bob/hash/evahash.html
Use for hash table lookup, or anything where one collision in 2^^32 is
acceptable.  Do NOT use for cryptographic purposes.
--------------------------------------------------------------------
*/

ub4 hash( k, length, initval)
register ub1 *k;        /* the key */
register ub4  length;   /* the length of the key */
register ub4  initval;  /* the previous hash, or an arbitrary value */
{
   register ub4 a,b,c,len;

   /* Set up the internal state */
   len = length;
   a = b = 0x9e3779b9;  /* the golden ratio; an arbitrary value */
   c = initval;         /* the previous hash value */

   /*---------------------------------------- handle most of the key */
   while (len >= 12)
   {
      a += (k[0] +((ub4)k[1]<<8) +((ub4)k[2]<<16) +((ub4)k[3]<<24));
      b += (k[4] +((ub4)k[5]<<8) +((ub4)k[6]<<16) +((ub4)k[7]<<24));
      c += (k[8] +((ub4)k[9]<<8) +((ub4)k[10]<<16)+((ub4)k[11]<<24));
      mix(a,b,c);
      k += 12; len -= 12;
   }

   /*------------------------------------- handle the last 11 bytes */
   c += length;
   switch(len)              /* all the case statements fall through */
   {
   case 11: c+=((ub4)k[10]<<24);
   case 10: c+=((ub4)k[9]<<16);
   case 9 : c+=((ub4)k[8]<<8);
      /* the first byte of c is reserved for the length */
   case 8 : b+=((ub4)k[7]<<24);
   case 7 : b+=((ub4)k[6]<<16);
   case 6 : b+=((ub4)k[5]<<8);
   case 5 : b+=k[4];
   case 4 : a+=((ub4)k[3]<<24);
   case 3 : a+=((ub4)k[2]<<16);
   case 2 : a+=((ub4)k[1]<<8);
   case 1 : a+=k[0];
     /* case 0: nothing left to add */
   }
   mix(a,b,c);
   /*-------------------------------------------- report the result */
   return c;
}
  *)
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
  iIndex:     Integer;
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
var
  pKey:       PString;

begin
  Result  := '';
  if ValidCursor(True) then
  begin
    Result  := HashCursor^.Key;
    {
    pKey    := GetNodeInternal(Cursor);
    Result  := pKey^;
    }
  end;
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
(*
constructor TX2UtHash.Create;
begin
  inherited;

  DataSize  := SizeOf(Pointer);
end;

function TX2UtHash.GetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Key);
  if Assigned(pNode) then
    Result  := PPointer(GetNodeData(pNode))^;
end;

procedure TX2UtHash.SetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Key, True);
  if Assigned(pNode) then
    PPointer(GetNodeData(pNode))^ := Value;
end;

function TX2UtHash.GetCurrentValue;
begin
  Result  := nil;
  if ValidCursor(True) then
    Result  := PPointer(GetNodeData(Cursor))^;
end;
*)


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
var
  pData:        PString;

begin
  if ValidCursor() then
    Result  := PString(GetItemData(HashCursor))^;
end;

end.
