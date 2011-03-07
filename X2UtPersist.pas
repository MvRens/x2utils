{
  :: X2UtPersist provides a framework for persisting objects and settings.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtPersist;

interface
uses
  Classes,
  Contnrs,
  Types,
  TypInfo,

  X2UtPersistIntf;


type
  TX2IterateObjectProc  = procedure(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean) of object;


  TX2CustomPersist = class(TInterfacedPersistent, IX2Persist)
  protected
    function CreateFiler(AIsReader: Boolean): IX2PersistFiler; virtual; abstract;
  public
    function Read(AObject: TObject): Boolean; virtual;
    procedure Write(AObject: TObject); virtual;

    function CreateReader: IX2PersistReader; virtual;
    function CreateWriter: IX2PersistWriter; virtual;

    function CreateSectionReader(const ASection: String): IX2PersistReader; virtual;
    function CreateSectionWriter(const ASection: String): IX2PersistWriter; virtual;
  end;


  TX2CustomPersistFiler = class(TInterfacedObject, IInterface, IX2PersistFiler,
                                IX2PersistReader, IX2PersistWriter)
  private
    FIsReader:    Boolean;
    FSections:    TStrings;
  protected
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;

    function IterateObject(AObject: TObject; ACallback: TX2IterateObjectProc): Boolean; virtual;

    procedure ReadObject(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean); virtual;
    procedure WriteObject(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean); virtual;

    property IsReader:  Boolean           read FIsReader;
    property Sections:  TStrings          read FSections;
  public
    constructor Create(AIsReader: Boolean);
    destructor Destroy; override;


    { IX2PersistFiler }
    function BeginSection(const AName: String): Boolean; virtual;
    procedure EndSection; virtual;
    
    procedure GetKeys(const ADest: TStrings); virtual; abstract;
    procedure GetSections(const ADest: TStrings); virtual; abstract;


    { IX2PersistReader }
    function Read(AObject: TObject): Boolean; virtual;

    function ReadBoolean(const AName: String; out AValue: Boolean): Boolean; virtual;
    function ReadInteger(const AName: String; out AValue: Integer): Boolean; virtual; abstract;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean; virtual; abstract;
    function ReadString(const AName: String; out AValue: String): Boolean; virtual; abstract;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; virtual; abstract;
    function ReadStream(const AName: String; AStream: TStream): Boolean; virtual;

    procedure ReadCollection(ACollection: TCollection); virtual;


    { IX2PersistWriter }
    procedure Write(AObject: TObject); virtual;

    function WriteBoolean(const AName: String; AValue: Boolean): Boolean; virtual;
    function WriteInteger(const AName: String; AValue: Integer): Boolean; virtual; abstract;
    function WriteFloat(const AName: String; AValue: Extended): Boolean; virtual; abstract;
    function WriteString(const AName, AValue: String): Boolean; virtual; abstract;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; virtual; abstract;
    function WriteStream(const AName: String; AStream: TStream): Boolean; virtual;

    procedure ClearCollection; virtual;
    procedure WriteCollection(ACollection: TCollection); virtual;

    procedure DeleteKey(const AName: String); virtual; abstract;
    procedure DeleteSection(const AName: String); virtual; abstract;


    { IX2PersistReader2 }
    function ReadVariant(const AName: string; out AValue: Variant): Boolean; virtual;


    { IX2PersistWriter2 }
    function WriteVariant(const AName: Variant; const AValue: Variant): Boolean; virtual;
  end;


implementation
uses
  SysUtils,
  Variants,

  X2UtStrings;


type
  { This class has to proxy all the interfaces in order for
    reference counting to go through this class. }
  TX2PersistSectionFilerProxy = class(TInterfacedObject, IInterface,
                                      IX2PersistFiler, IX2PersistReader,
                                      IX2PersistWriter, IX2PersistReader2,
                                      IX2PersistWriter2)
  private
    FFiler:           IX2PersistFiler;
    FSectionCount:    Integer;
  protected
    property Filer:           IX2PersistFiler   read FFiler;
    property SectionCount:    Integer           read FSectionCount;


    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;


    { IX2PersistFiler }
    function BeginSection(const AName: String): Boolean;
    procedure EndSection;

    procedure GetKeys(const ADest: TStrings);
    procedure GetSections(const ADest: TStrings);


    { IX2PersistReader }
    function Read(AObject: TObject): Boolean;
    function ReadBoolean(const AName: string; out AValue: Boolean): Boolean;
    function ReadInteger(const AName: String; out AValue: Integer): Boolean;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean;
    function ReadString(const AName: String; out AValue: String): Boolean;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean;
    function ReadStream(const AName: String; AStream: TStream): Boolean;


    { IX2PersistWriter }
    procedure Write(AObject: TObject);
    function WriteBoolean(const AName: String; AValue: Boolean): Boolean;
    function WriteInteger(const AName: String; AValue: Integer): Boolean;
    function WriteFloat(const AName: String; AValue: Extended): Boolean;
    function WriteString(const AName, AValue: String): Boolean;
    function WriteInt64(const AName: String; AValue: Int64): Boolean;
    function WriteStream(const AName: String; AStream: TStream): Boolean;

    procedure DeleteKey(const AName: String);
    procedure DeleteSection(const AName: String);


    { IX2PersistReader2 }
    function ReadVariant(const AName: string; out AValue: Variant): Boolean;

    { IX2PersistWriter2 }
    function WriteVariant(const AName: Variant; const AValue: Variant): Boolean;
  public
    constructor Create(const AFiler: IX2PersistFiler; const ASection: String);
    destructor Destroy; override;
  end;


{ TX2CustomPersist }
function TX2CustomPersist.CreateReader: IX2PersistReader;
begin
  Result  := (CreateFiler(True) as IX2PersistReader);
end;


function TX2CustomPersist.CreateWriter: IX2PersistWriter;
begin
  Result  := (CreateFiler(False) as IX2PersistWriter);
end;


function TX2CustomPersist.CreateSectionReader(const ASection: String): IX2PersistReader;
begin
  Result  := (TX2PersistSectionFilerProxy.Create(CreateReader, ASection) as IX2PersistReader);
end;


function TX2CustomPersist.CreateSectionWriter(const ASection: String): IX2PersistWriter;
begin
  Result  := (TX2PersistSectionFilerProxy.Create(CreateWriter, ASection) as IX2PersistWriter);
end;


function TX2CustomPersist.Read(AObject: TObject): Boolean;
begin
  with CreateReader do
    Result  := Read(AObject);
end;


procedure TX2CustomPersist.Write(AObject: TObject);
begin
  with CreateWriter do
    Write(AObject);
end;


{ TX2CustomPersistFiler }
constructor TX2CustomPersistFiler.Create(AIsReader: Boolean);
begin
  inherited Create;

  FIsReader := AIsReader;
  FSections := TStringList.Create;
end;


destructor TX2CustomPersistFiler.Destroy;
begin
  FreeAndNil(FSections);

  inherited;
end;


function TX2CustomPersistFiler.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Pointer(Obj)  := nil;
  Result        := E_NOINTERFACE;

  { A filer is one-way, prevent the wrong interface from being obtained }
  if IsEqualGUID(IID, IX2PersistReader) and (not IsReader) then
    Exit;

  if IsEqualGUID(IID, IX2PersistWriter) and IsReader then
    Exit;

  Result  := inherited QueryInterface(IID, Obj);
end;


function TX2CustomPersistFiler.BeginSection(const AName: String): Boolean;
begin
  FSections.Add(AName);
  Result  := True;
end;


procedure TX2CustomPersistFiler.EndSection;
begin
  Assert(FSections.Count > 0, 'EndSection called without BeginSection');
  FSections.Delete(Pred(FSections.Count));
end;


function TX2CustomPersistFiler.IterateObject(AObject: TObject; ACallback: TX2IterateObjectProc): Boolean;
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


function TX2CustomPersistFiler.Read(AObject: TObject): Boolean;
var
  customDataIntf: IX2PersistCustomData;

begin
  Assert(Assigned(AObject), 'AObject must be assigned.');

  if AObject is TCollection then
    ReadCollection(TCollection(AObject));

  Result  := IterateObject(AObject, ReadObject);

  if Result and Supports(AObject, IX2PersistCustomData, customDataIntf) then
    customDataIntf.Read(Self);
end;


function TX2CustomPersistFiler.ReadBoolean(const AName: String; out AValue: Boolean): Boolean;
var
  value:    String;

begin
  AValue  := False;
  Result  := ReadString(AName, value) and
             TryStrToBool(value, AValue);
end;


procedure TX2CustomPersistFiler.ReadObject(AObject: TObject; APropInfo: PPropInfo;
                                            var AContinue: Boolean);
var
  ordValue:     Integer;
  floatValue:   Extended;
  stringValue:  String;
  int64Value:   Int64;
  objectProp:   TObject;
  variantValue: Variant;

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
      if ReadVariant(APropInfo^.Name, variantValue) then
        SetVariantProp(AObject, APropInfo, variantValue);

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
              AContinue := Read(objectProp);
            finally
              EndSection;
            end;
          end;
        end;
      end;
  end;
end;


procedure TX2CustomPersistFiler.Write(AObject: TObject);
var
  customDataIntf: IX2PersistCustomData;

begin
  Assert(Assigned(AObject), 'AObject must be assigned.');

  if AObject is TCollection then
    WriteCollection(TCollection(AObject));

  if IterateObject(AObject, WriteObject) and
     Supports(AObject, IX2PersistCustomData, customDataIntf) then
    customDataIntf.Write(Self);
end;


function TX2CustomPersistFiler.WriteBoolean(const AName: String; AValue: Boolean): Boolean;
begin
  Result  := WriteString(AName, BoolToStr(AValue, True));
end;


procedure TX2CustomPersistFiler.WriteObject(AObject: TObject; APropInfo: PPropInfo; var AContinue: Boolean);
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
        WriteVariant(APropInfo^.Name, GetVariantProp(AObject, APropInfo));
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
              Write(objectProp);
            finally
              EndSection;               
            end;
          end;
        end;
      end;
  end;
end;


procedure TX2CustomPersistFiler.ReadCollection(ACollection: TCollection);
var
  itemCount: Integer;
  itemIndex: Integer;
  collectionItem: TCollectionItem;

begin
  if ReadInteger(CollectionCountName, itemCount) then
  begin
    ACollection.BeginUpdate;
    try
      ACollection.Clear;

      for itemIndex := 0 to Pred(itemCount) do
      begin
        if BeginSection(CollectionItemNamePrefix + IntToStr(itemIndex)) then
        try
          collectionItem  := ACollection.Add;          
          Read(collectionItem);
        finally
          EndSection;
        end;
      end;
    finally
      ACollection.EndUpdate;
    end;
  end;
end;


function TX2CustomPersistFiler.ReadStream(const AName: String; AStream: TStream): Boolean;
var
  data:   String;

begin
  Result  := ReadString(AName, data);
  if Result then
    AStream.WriteBuffer(PChar(data)^, Length(data));
end;


procedure TX2CustomPersistFiler.ClearCollection;
var
  sections:   TStringList;
  sectionIndex:   Integer;

begin
  inherited;

  sections  := TStringList.Create;
  try
    GetSections(sections);

    for sectionIndex := 0 to Pred(sections.Count) do
      if SameTextS(sections[sectionIndex], CollectionItemNamePrefix) then
        DeleteSection(sections[sectionIndex]);
  finally
    FreeAndNil(sections);
  end;
end;


procedure TX2CustomPersistFiler.WriteCollection(ACollection: TCollection);
var
  itemIndex: Integer;

begin
  ClearCollection;
  WriteInteger(CollectionCountName, ACollection.Count);

  for itemIndex := 0 to Pred(ACollection.Count) do
  begin
    if BeginSection(CollectionItemNamePrefix + IntToStr(itemIndex)) then
    try
      Write(ACollection.Items[itemIndex]);
    finally
      EndSection;
    end;
  end;
end;


function TX2CustomPersistFiler.WriteStream(const AName: String; AStream: TStream): Boolean;
var
  data:   String;

begin
  Result            := True;
  AStream.Position  := 0;

  SetLength(data, AStream.Size);
  AStream.ReadBuffer(PChar(data)^, AStream.Size);

  WriteString(AName, data);
end;


function TX2CustomPersistFiler.ReadVariant(const AName: string; out AValue: Variant): Boolean;
var
  stringValue: string;

begin
  AValue := Unassigned;
  Result := ReadString(AName, stringValue);

  if Result then
    AValue := stringValue;
end;


function TX2CustomPersistFiler.WriteVariant(const AName, AValue: Variant): Boolean;
begin
  Result := WriteString(AName, AValue);
end;


{ TX2PersistSectionFilerProxy }
constructor TX2PersistSectionFilerProxy.Create(const AFiler: IX2PersistFiler; const ASection: String);
var
  sections:       TSplitArray;
  sectionIndex:   Integer;
  undoIndex:      Integer;

begin
  inherited Create;

  FFiler    := AFiler;

  Split(ASection, SectionSeparator, sections);
  FSectionCount := 0;

  for sectionIndex := Low(sections) to High(sections) do
  begin
    if Length(sections[sectionIndex]) > 0 then
    begin
      if not Filer.BeginSection(sections[sectionIndex]) then
      begin
        { Undo all sections so far }
        for undoIndex := 0 to Pred(SectionCount) do
          Filer.EndSection;

        FFiler  := nil;
        Break;
      end else
        Inc(FSectionCount);
    end;
  end;
end;


destructor TX2PersistSectionFilerProxy.Destroy;
var
  sectionIndex:     Integer;

begin
  if Assigned(Filer) then
    for sectionIndex := 0 to Pred(SectionCount) do
      Filer.EndSection;

  inherited;
end;


function TX2PersistSectionFilerProxy.QueryInterface(const IID: TGUID; out Obj): HResult;
var
  filerInterface:   IInterface;

begin
  if Assigned(Filer) then
  begin
    { Only return interfaces supported by the filer
      - see TX2CustomPersistFiler.QueryInterface }
    if Filer.QueryInterface(IID, filerInterface) = S_OK then
      { ...but always return the proxy version of the interface to prevent
           issues with reference counting. }
      Result  := inherited QueryInterface(IID, Obj)
    else
      Result  := E_NOINTERFACE;
  end else
    Result  := inherited QueryInterface(IID, Obj);
end;


function TX2PersistSectionFilerProxy.BeginSection(const AName: String): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := Filer.BeginSection(AName);
end;


procedure TX2PersistSectionFilerProxy.EndSection;
begin
  if Assigned(Filer) then
    Filer.EndSection;
end;


procedure TX2PersistSectionFilerProxy.GetKeys(const ADest: TStrings);
begin
  if Assigned(Filer) then
    Filer.GetKeys(ADest);
end;


procedure TX2PersistSectionFilerProxy.GetSections(const ADest: TStrings);
begin
  if Assigned(Filer) then
    Filer.GetSections(ADest);
end;


function TX2PersistSectionFilerProxy.Read(AObject: TObject): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).Read(AObject);
end;


function TX2PersistSectionFilerProxy.ReadBoolean(const AName: string; out AValue: Boolean): Boolean;
begin
  Result  := False;
  AValue  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).ReadBoolean(AName, AValue);
end;


function TX2PersistSectionFilerProxy.ReadInteger(const AName: String; out AValue: Integer): Boolean;
begin
  Result  := False;
  AValue  := 0;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).ReadInteger(AName, AValue);
end;


function TX2PersistSectionFilerProxy.ReadFloat(const AName: String; out AValue: Extended): Boolean;
begin
  Result  := False;
  AValue  := 0;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).ReadFloat(AName, AValue);
end;


function TX2PersistSectionFilerProxy.ReadString(const AName: String; out AValue: String): Boolean;
begin
  Result  := False;
  AValue  := '';
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).ReadString(AName, AValue);
end;


function TX2PersistSectionFilerProxy.ReadInt64(const AName: String; out AValue: Int64): Boolean;
begin
  Result  := False;
  AValue  := 0;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).ReadInt64(AName, AValue);
end;


function TX2PersistSectionFilerProxy.ReadStream(const AName: String; AStream: TStream): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistReader).ReadStream(AName, AStream);
end;


function TX2PersistSectionFilerProxy.ReadVariant(const AName: string; out AValue: Variant): Boolean;
var
  reader2: IX2PersistReader2;

begin
  Result := False;
  if Assigned(Filer) and Supports(Filer, IX2PersistReader2, reader2) then
    Result := reader2.ReadVariant(AName, AValue);
end;


procedure TX2PersistSectionFilerProxy.Write(AObject: TObject);
begin
  if Assigned(Filer) then
    (Filer as IX2PersistWriter).Write(AObject);
end;


function TX2PersistSectionFilerProxy.WriteBoolean(const AName: String; AValue: Boolean): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistWriter).WriteBoolean(AName, AValue);
end;


function TX2PersistSectionFilerProxy.WriteInteger(const AName: String; AValue: Integer): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistWriter).WriteInteger(AName, AValue);
end;


function TX2PersistSectionFilerProxy.WriteFloat(const AName: String; AValue: Extended): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistWriter).WriteFloat(AName, AValue);
end;


function TX2PersistSectionFilerProxy.WriteString(const AName, AValue: String): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistWriter).WriteString(AName, AValue);
end;


function TX2PersistSectionFilerProxy.WriteVariant(const AName, AValue: Variant): Boolean;
var
  writer2: IX2PersistWriter2;

begin
  Result := False;
  if Assigned(Filer) and Supports(Filer, IX2PersistWriter2, writer2) then
    Result := writer2.WriteVariant(AName, AValue);
end;


function TX2PersistSectionFilerProxy.WriteInt64(const AName: String; AValue: Int64): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistWriter).WriteInt64(AName, AValue);
end;


function TX2PersistSectionFilerProxy.WriteStream(const AName: String; AStream: TStream): Boolean;
begin
  Result  := False;
  if Assigned(Filer) then
    Result  := (Filer as IX2PersistWriter).WriteStream(AName, AStream);
end;


procedure TX2PersistSectionFilerProxy.DeleteKey(const AName: String);
begin
  if Assigned(Filer) then
    (Filer as IX2PersistWriter).DeleteKey(AName);
end;


procedure TX2PersistSectionFilerProxy.DeleteSection(const AName: String);
begin
  if Assigned(Filer) then
    (Filer as IX2PersistWriter).DeleteSection(AName);
end;

end.

