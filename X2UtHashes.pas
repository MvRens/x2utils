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
    :$ Internal representation of a hash node
  }
  PX2UtHashNode   = ^TX2UtHashNode;
  TX2UtHashNode   = record
    Prev:           PX2UtHashNode;
    Next:           PX2UtHashNode;
    Key:            String;
    Value:          record end;
  end;

  {
    :$ Hash implementation

    :: This class implements a hash without knowing anything about
    :: the data it contains.
  }
  TX2UtCustomHash = class(TX2UtCustomBTree)
  private
    FHashCursor:        PX2UtHashNode;
    FHashDataSize:      Cardinal;

    function GetCurrentKey(): String;
  protected
    function Hash(const AValue: String): Cardinal; virtual;

    function LookupNode(const AKey: String;
                        const ACanCreate: Boolean = False;
                        const ASetCursor: Boolean = False): PX2UtBTreeNode;

    procedure InitNode(var ANode: PX2UtBTreeNode); override;
    procedure FreeNode(var ANode: PX2UtBTreeNode); override;

    procedure ClearCursor(); override;
    function ValidCursor(const ARaiseError: Boolean = True): Boolean; override;

    procedure InitHashNode(var ANode: PX2UtHashNode); virtual;
    procedure FreeHashNode(var ANode: PX2UtHashNode); virtual;

    property HashDataSize:      Cardinal        read FHashDataSize  write FHashDataSize;

    //:$ Returns the key at the current cursor location.
    property CurrentKey:        String          read GetCurrentKey;
  public
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

  {
    :$ Hash implementation for string values
  }
  TX2UtStringHash = class(TX2UtCustomHash)
  private
    function GetItem(Key: String): String;
    procedure SetItem(Key: String; const Value: String);

    function GetCurrentValue(): String;
  protected
    procedure InitNode(var ANode: PX2UtBTreeNode); override;
    procedure FreeNode(var ANode: PX2UtBTreeNode); override;
  public
    constructor Create(); override;
    property CurrentKey;

    //:$ Gets or sets an item.
    property Items[Key: String]:        String  read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location.
    property CurrentValue:      String          read GetCurrentValue;
  end;
  *)

implementation

{======================== TX2UtCustomHash
  Hashing
========================================}
function TX2UtCustomHash.Hash;
begin
  Result  := 0;
end;



{======================== TX2UtCustomHash
  Tree Traversing
========================================}
function TX2UtCustomHash.ValidCursor;
begin
  Result  := inherited ValidCursor(ARaiseError);
  if Result then
  begin
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
      FHashCursor := GetNodeData(Cursor);
  end else
    Result  := True;
end;


{======================== TX2UtCustomHash
  Item Management
========================================}
function TX2UtCustomHash.LookupNode;
var
  iIndex:     Integer;
  pNode:      PX2UtBTreeNode;

begin
  iIndex  := Hash(AKey);
  pNode   := inherited LookupNode(iIndex, ACanCreate, ASetCursor);
end;


procedure TX2UtCustomHash.Delete;
begin
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
    {
    pKey    := GetNodeInternal(Cursor);
    Result  := pKey^;
    }
  end;
end;


procedure TX2UtCustomHash.InitNode;
var
  pData:        PString;

begin
  inherited;

  {
  pData := GetNodeInternal(ANode);
  Initialize(pData^);
  }
end;

procedure TX2UtCustomHash.FreeNode;
var
  pData:        PString;

begin
  {
  pData := GetNodeInternal(ANode);
  Finalize(pData^);
  }

  inherited;
end;


{============================== TX2UtHash
  Item Management
========================================}
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


{======================== TX2UtStringHash
  Item Management
========================================}
constructor TX2UtStringHash.Create;
begin
  inherited;

  DataSize  := SizeOf(PString);
end;

function TX2UtStringHash.GetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Key);
  if Assigned(pNode) then
    Result  := PString(GetNodeData(pNode))^;
end;

procedure TX2UtStringHash.SetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Key, True);
  if Assigned(pNode) then
    PString(GetNodeData(pNode))^  := Value;
end;


procedure TX2UtStringHash.InitNode;
var
  pData:        PString;

begin
  inherited;

  pData := GetNodeData(ANode);
  Initialize(pData^);
end;

procedure TX2UtStringHash.FreeNode;
var
  pData:        PString;

begin
  pData := GetNodeData(ANode);
  Finalize(pData^);

  inherited;
end;


function TX2UtStringHash.GetCurrentValue;
var
  pData:        PString;

begin
  if ValidCursor() then
    Result  := PString(GetNodeData(Cursor))^;
end;

end.
