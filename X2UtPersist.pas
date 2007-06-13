unit X2UtPersist;

interface
uses
  Classes,
  Types,
  TypInfo;


type
  TX2IterateObjectProc  = procedure(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean) of object;

  TX2CustomPersist = class(TObject)
  private
    FSections:    TStrings;
  protected
    function IterateObject(AObject: TObject; ACallback: TX2IterateObjectProc): Boolean; virtual;

    procedure ReadObject(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean);
    procedure WriteObject(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean);
  protected
    function DoRead(AObject: TObject): Boolean; virtual;
    procedure DoWrite(AObject: TObject); virtual;

    function BeginSection(const AName: String): Boolean; virtual;
    procedure EndSection(); virtual;


    function ReadInteger(const AName: String; out AValue: Integer): Boolean; virtual; abstract;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean; virtual; abstract;
    function ReadString(const AName: String; out AValue: String): Boolean; virtual; abstract;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; virtual; abstract;

    procedure ReadCollection(const AName: String; ACollection: TCollection); virtual;
    procedure ReadStream(const AName: String; AStream: TStream); virtual;


    function WriteInteger(const AName: String; AValue: Integer): Boolean; virtual; abstract;
    function WriteFloat(const AName: String; AValue: Extended): Boolean; virtual; abstract;
    function WriteString(const AName, AValue: String): Boolean; virtual; abstract;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; virtual; abstract;

    procedure ClearCollection(); virtual;
    procedure WriteCollection(const AName: String; ACollection: TCollection); virtual;
    procedure WriteStream(const AName: String; AStream: TStream); virtual;


    property Sections:    TStrings  read FSections;
  public
    constructor Create();
    destructor Destroy(); override;

    function Read(AObject: TObject): Boolean; virtual;
    procedure Write(AObject: TObject); virtual;
  end;



const
  CollectionCountName       = 'Count';
  CollectionItemNamePrefix  = 'Item';


implementation
uses
  SysUtils,

  X2UtStrings;


{ TX2CustomPersist }
constructor TX2CustomPersist.Create();
begin
  inherited;

  FSections := TStringList.Create();
end;


destructor TX2CustomPersist.Destroy();
begin
  FreeAndNil(FSections);

  inherited;
end;


function TX2CustomPersist.IterateObject(AObject: TObject; ACallback: TX2IterateObjectProc): Boolean;
var
  propCount:      Integer;
  propList:       PPropList;
  propIndex:      Integer;
  propInfo:       PPropInfo;
  continue:       Boolean;

begin
  Result  := (AObject.ClassInfo <> nil);
  if not Result then
    Exit;

  { Iterate through published properties }
  propCount := GetPropList(AObject.ClassInfo, tkProperties, nil);
  if propCount > 0 then
  begin
    GetMem(propList, propCount * SizeOf(PPropInfo));
    try
      GetPropList(AObject.ClassInfo, tkProperties, propList);
      continue  := True;

      for propIndex := 0 to Pred(propCount) do
      begin
        propInfo  := propList^[propIndex];
        ACallback(AObject, propInfo, continue);
        
        if not continue then
        begin
          Result  := False;
          Break;
        end;
      end;
    finally
      FreeMem(propList, propCount * SizeOf(PPropInfo));
    end;
  end;
end;


function TX2CustomPersist.Read(AObject: TObject): Boolean;
begin
  Assert(Assigned(AObject), 'AObject must be assigned.');
  Result  := DoRead(AObject);
end;


procedure TX2CustomPersist.Write(AObject: TObject);
begin
  Assert(Assigned(AObject), 'AObject must be assigned.');
  DoWrite(AObject);
end;



function TX2CustomPersist.DoRead(AObject: TObject): Boolean;
begin
  IterateObject(AObject, ReadObject);
  Result  := True;
end;


procedure TX2CustomPersist.DoWrite(AObject: TObject);
begin
  IterateObject(AObject, WriteObject);
end;


function TX2CustomPersist.BeginSection(const AName: String): Boolean;
begin
  FSections.Add(AName);
  Result  := True;
end;


procedure TX2CustomPersist.EndSection();
begin
  Assert(FSections.Count > 0, 'EndSection called without BeginSection');
  FSections.Delete(Pred(FSections.Count));
end;



procedure TX2CustomPersist.ReadObject(AObject: TObject; APropInfo: PPropInfo;
                                      var AContinue: Boolean);
var
  ordValue:     Integer;
  floatValue:   Extended;
  stringValue:  String;
  int64Value:   Int64;
  objectProp:   TObject;

begin
  { Only read writable properties }
  if (APropInfo^.PropType^.Kind <> tkClass) and
     (not Assigned(APropInfo^.SetProc)) then
    Exit;

  case APropInfo^.PropType^.Kind of
    tkInteger,
    tkChar,
    tkWChar:
      if ReadInteger(APropInfo^.Name, ordValue) then
        SetOrdProp(AObject, APropInfo, ordValue);

    tkFloat:
      if ReadFloat(APropInfo^.Name, floatValue) then
        SetFloatProp(AObject, APropInfo, floatValue);

    tkEnumeration:
      if ReadString(APropInfo^.Name, stringValue) then
      begin
        ordValue := GetEnumValue(APropInfo^.PropType^, stringValue);
        if ordValue >= 0 then
          SetOrdProp(AObject, APropInfo, ordValue);
      end;

    tkString,
    tkLString,
    tkWString:
      if ReadString(APropInfo^.Name, stringValue) then
        SetStrProp(AObject, APropInfo, stringValue);

    tkSet:
      if ReadString(APropInfo^.Name, stringValue) then
      begin
        try
          ordValue  := StringToSet(APropInfo, stringValue);
          SetOrdProp(AObject, APropInfo, ordValue);
        except
          on E:EPropertyConvertError do;
        end;
      end;

    tkVariant:
      if ReadString(APropInfo^.Name, stringValue) then
        SetVariantProp(AObject, APropInfo, stringValue);

    tkInt64:
      if ReadInt64(APropInfo^.Name, int64Value) then
        SetInt64Prop(AObject, APropInfo, int64Value);

    tkClass:
      begin
        objectProp  := GetObjectProp(AObject, APropInfo);
        if Assigned(objectProp) then
        begin
          if objectProp is TStream then
          begin
            ReadStream(APropInfo^.Name, TStream(objectProp));
          end else
          begin
            { Recurse into object properties }
            if BeginSection(APropInfo^.Name) then
            try
              if objectProp is TCollection then
                ReadCollection(APropInfo^.Name, TCollection(objectProp));

              AContinue := IterateObject(objectProp, ReadObject);
            finally
              EndSection();
            end;
          end;
        end;
      end;
  end;
end;


procedure TX2CustomPersist.WriteObject(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean);
var
  ordValue:     Integer;
  floatValue:   Extended;
  stringValue:  String;
  int64Value:   Int64;
  objectProp:   TObject;

begin
  { Only write read/writable properties which have IsStored True }
  if (APropInfo^.PropType^.Kind <> tkClass) and
     (not (Assigned(APropInfo^.GetProc) and
           Assigned(APropInfo^.SetProc) and
           IsStoredProp(AObject, APropInfo))) then
    Exit;

  case APropInfo^.PropType^.Kind of
    tkInteger,
    tkChar,
    tkWChar:
      begin
        ordValue  := GetOrdProp(AObject, APropInfo);
        WriteInteger(APropInfo^.Name, ordValue);
      end;

    tkFloat:
      begin
        floatValue  := GetFloatProp(AObject, APropInfo);
        WriteFloat(APropInfo^.Name, floatValue);
      end;

    tkEnumeration:
      begin
        ordValue    := GetOrdProp(AObject, APropInfo);
        stringValue := GetEnumName(APropInfo^.PropType^, ordValue);
        WriteString(APropInfo^.Name, stringValue);
      end;

    tkString,
    tkLString,
    tkWString:
      begin
        stringValue := GetStrProp(AObject, APropInfo);
        WriteString(APropInfo^.Name, stringValue);
      end;

    tkSet:
      begin
        ordValue    := GetOrdProp(AObject, APropInfo);
        stringValue := SetToString(APropInfo, ordValue, True);
        WriteString(APropInfo^.Name, stringValue);
      end;

    tkVariant:
      begin
        stringValue := GetVariantProp(AObject, APropInfo);
        WriteString(APropInfo^.Name, stringValue);
      end;

    tkInt64:
      begin
        int64Value  := GetInt64Prop(AObject, APropInfo);
        WriteInt64(APropInfo^.Name, int64Value);
      end;

    tkClass:
      begin
        objectProp  := GetObjectProp(AObject, APropInfo);
        if Assigned(objectProp) then
        begin
          if objectProp is TStream then
          begin
            WriteStream(APropInfo^.Name, TStream(objectProp));
          end else
          begin
            { Recurse into object properties }
            if BeginSection(APropInfo^.Name) then
            try
              if objectProp is TCollection then
                WriteCollection(APropInfo^.Name, TCollection(objectProp));

              AContinue := IterateObject(objectProp, WriteObject);
            finally
              EndSection();
            end;
          end;
        end;
      end;
  end;
end;


procedure TX2CustomPersist.ReadCollection(const AName: String; ACollection: TCollection);
var
  itemCount: Integer;
  itemIndex: Integer;
  collectionItem: TCollectionItem;

begin
  if ReadInteger(CollectionCountName, itemCount) then
  begin
    ACollection.BeginUpdate();
    try
      ACollection.Clear();

      for itemIndex := 0 to Pred(itemCount) do
      begin
        if BeginSection(CollectionItemNamePrefix + IntToStr(itemIndex)) then
        try
          collectionItem  := ACollection.Add();
          IterateObject(collectionItem, ReadObject);
        finally
          EndSection();
        end;
      end;
    finally
      ACollection.EndUpdate();
    end;
  end;
end;


procedure TX2CustomPersist.ReadStream(const AName: String; AStream: TStream);
begin
  // #ToDo1 (MvR) 8-6-2007: ReadStream
end;


procedure TX2CustomPersist.ClearCollection();
begin
end;


procedure TX2CustomPersist.WriteCollection(const AName: String; ACollection: TCollection);
var
  itemIndex: Integer;

begin
  ClearCollection();
  WriteInteger(CollectionCountName, ACollection.Count);

  for itemIndex := 0 to Pred(ACollection.Count) do
  begin
    if BeginSection(CollectionItemNamePrefix + IntToStr(itemIndex)) then
    try
      IterateObject(ACollection.Items[itemIndex], WriteObject);
    finally
      EndSection();
    end;
  end;
end;

procedure TX2CustomPersist.WriteStream(const AName: String; AStream: TStream);
begin
  // #ToDo1 (MvR) 8-6-2007: WriteStream
end;

end.

