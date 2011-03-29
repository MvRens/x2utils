{
  :: X2UtPersistXML implements persistency to an XML file.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtPersistXML;

{$WARN SYMBOL_PLATFORM OFF}

interface
uses
  Classes,
  Registry,
  Windows,

  X2UtPersist,
  X2UtPersistIntf,
  X2UtPersistXMLBinding;


type
  TX2UtPersistXML = class(TX2CustomPersist)
  private
    FFileName: String;
  protected
    function CreateFiler(AIsReader: Boolean): IX2PersistFiler; override;
  public
    property FileName:  String  read FFileName  write FFileName;
  end;


  TX2UtPersistXMLFiler = class(TX2CustomPersistFiler)
  private
    FFileName:      String;
    FConfiguration: IXMLConfiguration;
    FSection:       IXMLSection;
    FSectionStack:  TInterfaceList;
  protected
    function GetValue(const AName: string; out AValue: IXMLvalue; AWriting: Boolean): Boolean;
  public
    function BeginSection(const AName: String): Boolean; override;
    procedure EndSection; override;


    procedure GetKeys(const ADest: TStrings); override;
    procedure GetSections(const ADest: TStrings); override;

    
    function ReadInteger(const AName: String; out AValue: Integer): Boolean; override;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean; override;
    function ReadString(const AName: String; out AValue: String): Boolean; override;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; override;
    function ReadVariant(const AName: string; out AValue: Variant): Boolean; override;

    function ReadStream(const AName: string; AStream: TStream): Boolean; override;


    function WriteInteger(const AName: String; AValue: Integer): Boolean; override;
    function WriteFloat(const AName: String; AValue: Extended): Boolean; override;
    function WriteString(const AName, AValue: String): Boolean; override;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; override;
    function WriteVariant(const AName: Variant; const AValue: Variant): Boolean; override;

    function WriteStream(const AName: string; AStream: TStream): Boolean; override;

    
    procedure DeleteKey(const AName: string); override;
    procedure DeleteSection(const AName: string); override;


    property Configuration: IXMLConfiguration read FConfiguration;
    property Section:       IXMLSection       read FSection;
    property SectionStack:  TInterfaceList    read FSectionStack;
    property FileName:      String            read FFileName;
  public
    constructor Create(AIsReader: Boolean; const AFileName: String);
    destructor Destroy; override;
  end;


  { Wrapper functions }
  function ReadFromXML(AObject: TObject; const AFileName: string): Boolean;
  procedure WriteToXML(AObject: TObject; const AFileName: string);


implementation
uses
  SysUtils,
  Variants,

  X2UtStrings;
  

{ Wrapper functions }
function ReadFromXML(AObject: TObject; const AFileName: string): Boolean;
begin
  with TX2UtPersistXML.Create do
  try
    FileName  := AFileName;
    Result    := Read(AObject);
  finally
    Free;
  end;
end;


procedure WriteToXML(AObject: TObject; const AFileName: string);
begin
  with TX2UtPersistXML.Create do
  try
    FileName  := AFileName;
    Write(AObject);
  finally
    Free;
  end;
end;


{ TX2UtPersistXML }
function TX2UtPersistXML.CreateFiler(AIsReader: Boolean): IX2PersistFiler;
begin
  Result  := TX2UtPersistXMLFiler.Create(AIsReader, Self.FileName);
end;


{ TX2UtPersistXML }
constructor TX2UtPersistXMLFiler.Create(AIsReader: Boolean; const AFileName: string);
begin
  inherited Create(AIsReader);

  FSectionStack := TInterfaceList.Create;
  FFileName := AFileName;

  if AIsReader then
    FConfiguration := LoadConfiguration(AFileName)
  else
    FConfiguration := NewConfiguration;

  FSection := FConfiguration;
end;


destructor TX2UtPersistXMLFiler.Destroy;
begin
  if not IsReader then
    Configuration.OwnerDocument.SaveToFile(FileName);

  FreeAndNil(FSectionStack);

  inherited;
end;


function TX2UtPersistXMLFiler.BeginSection(const AName: String): Boolean;
var
  sectionIndex: Integer;
  
begin
  Result := False;

  for sectionIndex := 0 to Pred(Section.section.Count) do
  begin
    if SameText(Section.section[sectionIndex].name, AName) then
    begin
      Result := True;
      FSection := Section.section[sectionIndex];
      Break;;
    end;
  end;

  if not Result then
  begin
    FSection := Section.section.Add;
    FSection.name := AName;
    Result := True;
  end;

  if Result then
  begin
    SectionStack.Add(Section);
    inherited BeginSection(AName);
  end;
end;


procedure TX2UtPersistXMLFiler.EndSection;
var
  lastItem: Integer;
  
begin
  inherited;

  if SectionStack.Count > 0 then
  begin
    lastItem := Pred(SectionStack.Count);

    if lastItem > 0 then
      FSection := (SectionStack[Pred(lastItem)] as IXMLSection)
    else
      FSection := Configuration;

    SectionStack.Delete(lastItem);
  end;
end;


procedure TX2UtPersistXMLFiler.GetKeys(const ADest: TStrings);
var
  valueIndex: Integer;

begin
  for valueIndex := 0 to Pred(Section.value.Count) do
    ADest.Add(Section.value[valueIndex].name);
end;


procedure TX2UtPersistXMLFiler.GetSections(const ADest: TStrings);
var
  sectionIndex: Integer;

begin
  for sectionIndex := 0 to Pred(Section.section.Count) do
    ADest.Add(Section.section[sectionIndex].name);
end;


function TX2UtPersistXMLFiler.GetValue(const AName: string; out AValue: IXMLvalue; AWriting: Boolean): Boolean;
var
  valueIndex: Integer;

begin
  AValue := nil;
  Result := False;

  for valueIndex := 0 to Pred(Section.value.Count) do
    if SameText(Section.value[valueIndex].name, AName) then
    begin
      AValue := Section.value[valueIndex];
      Result := True;
      Break;
    end;

  if AWriting then
  begin
    if not Result then
    begin
      AValue := Section.value.Add;
      AValue.name := AName;
    end;

    AValue.ChildNodes.Clear;
    Result := True;
  end;
end;


function TX2UtPersistXMLFiler.ReadInteger(const AName: String; out AValue: Integer): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, False) and (value.Hasinteger);
  if Result then
    AValue := value.integer;
end;


function TX2UtPersistXMLFiler.ReadFloat(const AName: String; out AValue: Extended): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, False) and (value.Hasfloat);
  if Result then
    AValue := value.float;
end;


function TX2UtPersistXMLFiler.ReadVariant(const AName: string; out AValue: Variant): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, False);
  if Result then
  begin
    if value.Hasinteger then
      AValue := value.integer

    else if value.Hasfloat then
      AValue := value.float

    else if value.Has_string then
      AValue := value._string

    else if value.Hasint64 then
      AValue := value.int64

    else if value.Hasvariant then
      if value.variantIsNil then
        AValue := Null
      else
        AValue := value.variant;
  end;
end;


function TX2UtPersistXMLFiler.ReadStream(const AName: string; AStream: TStream): Boolean;
begin
  raise EAbstractError.Create('Stream not yet supported in XML');
end;


function TX2UtPersistXMLFiler.ReadString(const AName: String; out AValue: String): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, False) and (value.Has_string);
  if Result then
    AValue := value._string;
end;


function TX2UtPersistXMLFiler.ReadInt64(const AName: String; out AValue: Int64): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, False) and (value.Hasint64);
  if Result then
    AValue := value.int64;
end;


function TX2UtPersistXMLFiler.WriteInteger(const AName: String; AValue: Integer): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, True);
  if Result then
    value.integer := AValue;
end;


function TX2UtPersistXMLFiler.WriteFloat(const AName: String; AValue: Extended): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, True);
  if Result then
    value.float := AValue;
end;


function TX2UtPersistXMLFiler.WriteString(const AName, AValue: String): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, True);
  if Result then
    value._string := AValue;
end;


function TX2UtPersistXMLFiler.WriteInt64(const AName: String; AValue: Int64): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, True);
  if Result then
    value.int64 := AValue;
end;


function TX2UtPersistXMLFiler.WriteVariant(const AName, AValue: Variant): Boolean;
var
  value: IXMLvalue;

begin
  Result := GetValue(AName, value, True);
  if Result then
  begin
    if VarIsNull(AValue) or VarIsClear(AValue) then
      value.variantIsNil := True
    else
    begin
      case VarType(AValue) of
        varSmallint,
        varInteger:
          value.Integer := AValue;

        varSingle,
        varDouble,
        varCurrency,
        varDate:
          value.float := AValue;

        varInt64:
          value.Int64 := AValue;

        varOleStr,
        varStrArg,
        varString:
          value._string := AValue;
      else
        value.variant := AValue;
      end;
    end;
  end;
end;


function TX2UtPersistXMLFiler.WriteStream(const AName: string; AStream: TStream): Boolean;
begin
  raise EAbstractError.Create('Stream not yet supported in XML');
end;


procedure TX2UtPersistXMLFiler.DeleteKey(const AName: string);
var
  valueIndex: Integer;

begin
  for valueIndex := 0 to Pred(Section.value.Count) do
    if SameText(Section.value[valueIndex].name, AName) then
    begin
      Section.value.Delete(valueIndex);
      Break;
    end;
end;


procedure TX2UtPersistXMLFiler.DeleteSection(const AName: string);
var
  sectionIndex: Integer;

begin
  for sectionIndex := 0 to Pred(Section.section.Count) do
    if SameText(Section.section[sectionIndex].name, AName) then
    begin
      Section.section.Delete(sectionIndex);
      Break;
    end;
end;

end.

