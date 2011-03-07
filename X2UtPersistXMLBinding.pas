{
  X2Software XML Data Binding

    Generated on:   3-3-2011 12:45:23
    Generated from: P:\test\X2Utils\XSD\PersistXML.xsd
}
unit X2UtPersistXMLBinding;

interface
uses
  Classes,
  XMLDoc,
  XMLIntf,
  XMLDataBindingUtils;

type
  { Forward declarations for PersistXML }
  IXMLSection = interface;
  IXMLvalueList = interface;
  IXMLsectionList = interface;
  IXMLValue = interface;
  IXMLConfiguration = interface;

  { Interfaces for PersistXML }
  IXMLSection = interface(IXMLNode)
    ['{810C68EC-1138-4B89-A164-9F9B03970771}']
    function Getsection: IXMLsectionList;
    function Getvalue: IXMLvalueList;
    function GetHasname: Boolean;
    function Getname: WideString;

    procedure Setname(const Value: WideString);

    property section: IXMLsectionList read Getsection;
    property value: IXMLvalueList read Getvalue;
    property Hasname: Boolean read GetHasname;
    property name: WideString read Getname write Setname;
  end;

  IXMLvalueList = interface(IXMLNodeCollection)
    ['{93139658-6A8B-46DE-B7B9-734A6A94762A}']
    function Get_value(Index: Integer): IXMLValue;
    function Add: IXMLValue;
    function Insert(Index: Integer): IXMLValue;

    property value[Index: Integer]: IXMLValue read Get_value; default;
  end;

  IXMLsectionList = interface(IXMLNodeCollection)
    ['{C6BFF503-B4F0-492B-9B60-B97140D59782}']
    function Get_section(Index: Integer): IXMLSection;
    function Add: IXMLSection;
    function Insert(Index: Integer): IXMLSection;

    property section[Index: Integer]: IXMLSection read Get_section; default;
  end;

  IXMLValue = interface(IXMLNode)
    ['{3F92F545-4FA7-43AD-A623-113BD9100FE2}']
    function GetHasinteger: Boolean;
    function Getinteger: Integer;
    function GetHasfloat: Boolean;
    function Getfloat: Double;
    function GetHas_string: Boolean;
    function Get_string: WideString;
    function GetHasvariant: Boolean;
    function GetvariantIsNil: Boolean;
    function Getvariant: WideString;
    function GetHasint64: Boolean;
    function Getint64: Int64;
    function GetHasname: Boolean;
    function Getname: WideString;

    procedure Setinteger(const Value: Integer);
    procedure Setfloat(const Value: Double);
    procedure Set_string(const Value: WideString);
    procedure SetvariantIsNil(const Value: Boolean);
    procedure Setvariant(const Value: WideString);
    procedure Setint64(const Value: Int64);
    procedure Setname(const Value: WideString);

    property Hasinteger: Boolean read GetHasinteger;
    property integer: Integer read Getinteger write Setinteger;
    property Hasfloat: Boolean read GetHasfloat;
    property float: Double read Getfloat write Setfloat;
    property Has_string: Boolean read GetHas_string;
    property _string: WideString read Get_string write Set_string;
    property Hasvariant: Boolean read GetHasvariant;
    property variantIsNil: Boolean read GetvariantIsNil write SetvariantIsNil;
    property variant: WideString read Getvariant write Setvariant;
    property Hasint64: Boolean read GetHasint64;
    property int64: Int64 read Getint64 write Setint64;
    property Hasname: Boolean read GetHasname;
    property name: WideString read Getname write Setname;
  end;

  IXMLConfiguration = interface(IXMLSection)
    ['{AE639E63-960C-445F-89D8-53866535F725}']
    procedure XSDValidateDocument;
  end;


  { Classes for PersistXML }
  TXMLSection = class(TXMLNode, IXMLSection)
  private
    Fsection: IXMLsectionList;
    Fvalue: IXMLvalueList;
  public
    procedure AfterConstruction; override;
  protected
    function Getsection: IXMLsectionList;
    function Getvalue: IXMLvalueList;
    function GetHasname: Boolean;
    function Getname: WideString;

    procedure Setname(const Value: WideString);
  end;

  TXMLvalueList = class(TXMLNodeCollection, IXMLvalueList)
  public
    procedure AfterConstruction; override;
  protected
    function Get_value(Index: Integer): IXMLValue;
    function Add: IXMLValue;
    function Insert(Index: Integer): IXMLValue;
  end;

  TXMLsectionList = class(TXMLNodeCollection, IXMLsectionList)
  public
    procedure AfterConstruction; override;
  protected
    function Get_section(Index: Integer): IXMLSection;
    function Add: IXMLSection;
    function Insert(Index: Integer): IXMLSection;
  end;

  TXMLValue = class(TXMLNode, IXMLValue)
  protected
    function GetHasinteger: Boolean;
    function Getinteger: Integer;
    function GetHasfloat: Boolean;
    function Getfloat: Double;
    function GetHas_string: Boolean;
    function Get_string: WideString;
    function GetHasvariant: Boolean;
    function GetvariantIsNil: Boolean;
    function Getvariant: WideString;
    function GetHasint64: Boolean;
    function Getint64: Int64;
    function GetHasname: Boolean;
    function Getname: WideString;

    procedure Setinteger(const Value: Integer);
    procedure Setfloat(const Value: Double);
    procedure Set_string(const Value: WideString);
    procedure SetvariantIsNil(const Value: Boolean);
    procedure Setvariant(const Value: WideString);
    procedure Setint64(const Value: Int64);
    procedure Setname(const Value: WideString);
  end;

  TXMLConfiguration = class(TXMLSection, IXMLConfiguration)
  protected
    procedure XSDValidateDocument;
  end;


  { Document functions }
  function GetConfiguration(ADocument: XMLIntf.IXMLDocument): IXMLConfiguration;
  function LoadConfiguration(const AFileName: String): IXMLConfiguration;
  function LoadConfigurationFromStream(AStream: TStream): IXMLConfiguration;
  function NewConfiguration: IXMLConfiguration;


const
  TargetNamespace = '';


implementation
uses
  SysUtils;

{ Document functions }
function GetConfiguration(ADocument: XMLIntf.IXMLDocument): IXMLConfiguration;
begin
  Result := ADocument.GetDocBinding('Configuration', TXMLConfiguration, TargetNamespace) as IXMLConfiguration
end;

function LoadConfiguration(const AFileName: String): IXMLConfiguration;
begin
  Result := LoadXMLDocument(AFileName).GetDocBinding('Configuration', TXMLConfiguration, TargetNamespace) as IXMLConfiguration
end;

function LoadConfigurationFromStream(AStream: TStream): IXMLConfiguration;
var
  doc: XMLIntf.IXMLDocument;

begin
  doc := NewXMLDocument;
  doc.LoadFromStream(AStream);
  Result  := GetConfiguration(doc);
end;

function NewConfiguration: IXMLConfiguration;
begin
  Result := NewXMLDocument.GetDocBinding('Configuration', TXMLConfiguration, TargetNamespace) as IXMLConfiguration
end;



{ Implementation for PersistXML }
procedure TXMLSection.AfterConstruction;
begin
  RegisterChildNode('section', TXMLSection);
  Fsection := CreateCollection(TXMLsectionList, IXMLSection, 'section') as IXMLsectionList;
  RegisterChildNode('section', TXMLSection);
  RegisterChildNode('value', TXMLValue);
  Fvalue := CreateCollection(TXMLvalueList, IXMLValue, 'value') as IXMLvalueList;
  RegisterChildNode('value', TXMLValue);
  inherited;
end;

function TXMLSection.Getsection: IXMLsectionList;
begin
  Result := Fsection;
end;

function TXMLSection.Getvalue: IXMLvalueList;
begin
  Result := Fvalue;
end;

function TXMLSection.GetHasname: Boolean;
begin
  Result := Assigned(AttributeNodes.FindNode('name'));
end;


function TXMLSection.Getname: WideString;
begin
  Result := AttributeNodes['name'].Text;
end;

procedure TXMLSection.Setname(const Value: WideString);
begin
  SetAttribute('name', Value);
end;

procedure TXMLvalueList.AfterConstruction;
begin
  RegisterChildNode('value', TXMLValue);

  ItemTag := 'value';
  ItemInterface := IXMLValue;

  inherited;
end;

function TXMLvalueList.Get_value(Index: Integer): IXMLValue;
begin
  Result := (List[Index] as IXMLValue);
end;

function TXMLvalueList.Add: IXMLValue;
begin
  Result := (AddItem(-1) as IXMLValue);
end;

function TXMLvalueList.Insert(Index: Integer): IXMLValue;
begin
  Result := (AddItem(Index) as IXMLValue);
end;

procedure TXMLsectionList.AfterConstruction;
begin
  RegisterChildNode('section', TXMLSection);

  ItemTag := 'section';
  ItemInterface := IXMLSection;

  inherited;
end;

function TXMLsectionList.Get_section(Index: Integer): IXMLSection;
begin
  Result := (List[Index] as IXMLSection);
end;

function TXMLsectionList.Add: IXMLSection;
begin
  Result := (AddItem(-1) as IXMLSection);
end;

function TXMLsectionList.Insert(Index: Integer): IXMLSection;
begin
  Result := (AddItem(Index) as IXMLSection);
end;

function TXMLValue.GetHasinteger: Boolean;
begin
  Result := Assigned(ChildNodes.FindNode('integer'));
end;


function TXMLValue.Getinteger: Integer;
begin
  Result := ChildNodes['integer'].NodeValue;
end;

function TXMLValue.GetHasfloat: Boolean;
begin
  Result := Assigned(ChildNodes.FindNode('float'));
end;


function TXMLValue.Getfloat: Double;
begin
  Result := XMLToFloat(ChildNodes['float'].NodeValue);
end;

function TXMLValue.GetHas_string: Boolean;
begin
  Result := Assigned(ChildNodes.FindNode('string'));
end;


function TXMLValue.Get_string: WideString;
begin
  Result := ChildNodes['string'].Text;
end;

function TXMLValue.GetHasvariant: Boolean;
begin
  Result := Assigned(ChildNodes.FindNode('variant'));
end;


function TXMLValue.GetvariantIsNil: Boolean;
begin
  Result := GetNodeIsNil(ChildNodes['variant']);
end;


function TXMLValue.Getvariant: WideString;
begin
  Result := ChildNodes['variant'].Text;
end;

function TXMLValue.GetHasint64: Boolean;
begin
  Result := Assigned(ChildNodes.FindNode('int64'));
end;


function TXMLValue.Getint64: Int64;
begin
  Result := ChildNodes['int64'].NodeValue;
end;

function TXMLValue.GetHasname: Boolean;
begin
  Result := Assigned(AttributeNodes.FindNode('name'));
end;


function TXMLValue.Getname: WideString;
begin
  Result := AttributeNodes['name'].Text;
end;

procedure TXMLValue.Setinteger(const Value: Integer);
begin
  ChildNodes['integer'].NodeValue := Value;
end;

procedure TXMLValue.Setfloat(const Value: Double);
begin
  ChildNodes['float'].NodeValue := FloatToXML(Value);
end;

procedure TXMLValue.Set_string(const Value: WideString);
begin
  ChildNodes['string'].NodeValue := Value;
end;

procedure TXMLValue.SetvariantIsNil(const Value: Boolean);
begin
  SetNodeIsNil(ChildNodes['variant'], Value);
end;


procedure TXMLValue.Setvariant(const Value: WideString);
begin
  ChildNodes['variant'].NodeValue := Value;
end;

procedure TXMLValue.Setint64(const Value: Int64);
begin
  ChildNodes['int64'].NodeValue := Value;
end;

procedure TXMLValue.Setname(const Value: WideString);
begin
  SetAttribute('name', Value);
end;

procedure TXMLConfiguration.XSDValidateDocument;
begin
  XMLDataBindingUtils.XSDValidate(Self);
end;



end.
