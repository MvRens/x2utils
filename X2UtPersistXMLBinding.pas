{
  X2Software XML Data Binding

    Generated on:   18-2-2011 15:23:30
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
  IXMLvalue = interface;
  IXMLConfiguration = interface;

  { Interfaces for PersistXML }
  IXMLSection = interface(IXMLNode)
    ['{37E1BD74-261B-44DA-BA06-162DBE32160C}']
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
    ['{267C86A8-44E3-4532-8ABE-15B1EDBFD78D}']
    function Get_value(Index: Integer): IXMLvalue;
    function Add: IXMLvalue;
    function Insert(Index: Integer): IXMLvalue;

    property value[Index: Integer]: IXMLvalue read Get_value; default;
  end;

  IXMLsectionList = interface(IXMLNodeCollection)
    ['{2C43C489-F92B-4E8F-873F-3825FC294945}']
    function Get_section(Index: Integer): IXMLSection;
    function Add: IXMLSection;
    function Insert(Index: Integer): IXMLSection;

    property section[Index: Integer]: IXMLSection read Get_section; default;
  end;

  IXMLvalue = interface(IXMLNode)
    ['{63A166DE-F145-4A3E-941B-6A937DE0B783}']
    function GetHasname: Boolean;
    function Getname: WideString;

    procedure Setname(const Value: WideString);

    property Hasname: Boolean read GetHasname;
    property name: WideString read Getname write Setname;
  end;

  IXMLConfiguration = interface(IXMLSection)
    ['{81AAD8C2-F976-4203-B9D6-646408E5DE8A}']
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
    function Get_value(Index: Integer): IXMLvalue;
    function Add: IXMLvalue;
    function Insert(Index: Integer): IXMLvalue;
  end;

  TXMLsectionList = class(TXMLNodeCollection, IXMLsectionList)
  public
    procedure AfterConstruction; override;
  protected
    function Get_section(Index: Integer): IXMLSection;
    function Add: IXMLSection;
    function Insert(Index: Integer): IXMLSection;
  end;

  TXMLvalue = class(TXMLNode, IXMLvalue)
  protected
    function GetHasname: Boolean;
    function Getname: WideString;

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
  RegisterChildNode('value', TXMLvalue);
  Fvalue := CreateCollection(TXMLvalueList, IXMLvalue, 'value') as IXMLvalueList;
  RegisterChildNode('value', TXMLvalue);
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
  RegisterChildNode('value', TXMLvalue);

  ItemTag := 'value';
  ItemInterface := IXMLvalue;

  inherited;
end;

function TXMLvalueList.Get_value(Index: Integer): IXMLvalue;
begin
  Result := (List[Index] as IXMLvalue);
end;

function TXMLvalueList.Add: IXMLvalue;
begin
  Result := (AddItem(-1) as IXMLvalue);
end;

function TXMLvalueList.Insert(Index: Integer): IXMLvalue;
begin
  Result := (AddItem(Index) as IXMLvalue);
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

function TXMLvalue.GetHasname: Boolean;
begin
  Result := Assigned(AttributeNodes.FindNode('name'));
end;


function TXMLvalue.Getname: WideString;
begin
  Result := AttributeNodes['name'].Text;
end;

procedure TXMLvalue.Setname(const Value: WideString);
begin
  SetAttribute('name', Value);
end;

procedure TXMLConfiguration.XSDValidateDocument;
begin
  XMLDataBindingUtils.XSDValidate(Self);
end;



end.
