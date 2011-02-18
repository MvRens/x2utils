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
    function ReadValue(const AName: string; out AValue: string): Boolean;
    function WriteValue(const AName: string; const AValue: string): Boolean;
  public
    function BeginSection(const AName: String): Boolean; override;
    procedure EndSection; override;


    procedure GetKeys(const ADest: TStrings); override;
    procedure GetSections(const ADest: TStrings); override;

    
    function ReadInteger(const AName: String; out AValue: Integer): Boolean; override;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean; override;
    function ReadString(const AName: String; out AValue: String): Boolean; override;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; override;

    function ReadStream(const AName: string; AStream: TStream): Boolean; override;


    function WriteInteger(const AName: String; AValue: Integer): Boolean; override;
    function WriteFloat(const AName: String; AValue: Extended): Boolean; override;
    function WriteString(const AName, AValue: String): Boolean; override;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; override;

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

  X2UtStrings;
  

const
  RegistrySeparator = '\';


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

    if lastItem < 0 then
      FSection := Configuration
    else
      FSection := (SectionStack[Pred(lastItem)] as IXMLSection);
      
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


function TX2UtPersistXMLFiler.ReadValue(const AName: string; out AValue: string): Boolean;
var
  valueIndex: Integer;

begin
  Result := False;
  AValue := '';

  for valueIndex := 0 to Pred(Section.value.Count) do
    if SameText(Section.value[valueIndex].name, AName) then
    begin
      AValue := Section.value[valueIndex].Text;
      Result := True;
    end;
end;


function TX2UtPersistXMLFiler.ReadInteger(const AName: String; out AValue: Integer): Boolean;
var
  value: string;

begin
  AValue  := 0;
  Result  := ReadValue(AName, value) and TryStrToInt(value, AValue);
end;


function TX2UtPersistXMLFiler.ReadFloat(const AName: String; out AValue: Extended): Boolean;
var
  value: string;

begin
  AValue  := 0;
  Result  := ReadValue(AName, value) and TryStrToFloat(value, AValue);
end;


function TX2UtPersistXMLFiler.ReadStream(const AName: string; AStream: TStream): Boolean;
begin
  raise EAbstractError.Create('Stream not yet supported in XML');
end;


function TX2UtPersistXMLFiler.ReadString(const AName: String; out AValue: String): Boolean;
var
  value: string;

begin
  Result  := ReadValue(AName, value);
end;


function TX2UtPersistXMLFiler.ReadInt64(const AName: String; out AValue: Int64): Boolean;
var
  value: string;

begin
  AValue  := 0;
  Result  := ReadValue(AName, value) and TryStrToInt64(value, AValue);
end;


function TX2UtPersistXMLFiler.WriteValue(const AName, AValue: string): Boolean;
var
  value: IXMLvalue;
  valueIndex: Integer;

begin
  Result := False;
  value := nil;

  for valueIndex := 0 to Pred(Section.value.Count) do
    if SameText(Section.value[valueIndex].name, AName) then
    begin
      value := Section.value[valueIndex];
      Break;
    end;

  if not Assigned(value) then
  begin
    value := Section.value.Add;
    value.name := AName;
  end;

  if Assigned(value) then
  begin
    value.Text := AValue;
    Result := True;
  end;
end;


function TX2UtPersistXMLFiler.WriteInteger(const AName: String; AValue: Integer): Boolean;
begin
  Result  := WriteValue(AName, IntToStr(AValue));
end;


function TX2UtPersistXMLFiler.WriteFloat(const AName: String; AValue: Extended): Boolean;
begin
  Result  := WriteValue(AName, FloatToStr(AValue));
end;


function TX2UtPersistXMLFiler.WriteStream(const AName: string; AStream: TStream): Boolean;
begin
  raise EAbstractError.Create('Stream not yet supported in XML');
end;


function TX2UtPersistXMLFiler.WriteString(const AName, AValue: String): Boolean;
begin
  Result := WriteValue(AName, AValue);
end;


function TX2UtPersistXMLFiler.WriteInt64(const AName: String; AValue: Int64): Boolean;
begin
  Result := WriteValue(AName, IntToStr(AValue));
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

