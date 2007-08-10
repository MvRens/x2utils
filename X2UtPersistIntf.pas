{
  :: X2UtPersistIntf declares the interfaces used for X2UtPersist.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtPersistIntf;

interface
uses
  Classes;


const
  SectionSeparator          = '.';
  CollectionCountName       = 'Count';
  CollectionItemNamePrefix  = 'Item';


type
  IX2PersistFiler = interface;
  IX2PersistReader = interface;
  IX2PersistWriter = interface;
  

  IX2Persist = interface
    ['{E490D44F-EF97-45C6-A0B1-11D592A292F5}']
    function Read(AObject: TObject): Boolean;
    procedure Write(AObject: TObject);

    function CreateReader(): IX2PersistReader;
    function CreateWriter(): IX2PersistWriter;

    function CreateSectionReader(const ASection: String): IX2PersistReader;
    function CreateSectionWriter(const ASection: String): IX2PersistWriter;
  end;

  
  IX2PersistFiler = interface
    ['{BF63CDAA-98D4-42EE-A937-DFCD0074A0ED}']
    function BeginSection(const AName: String): Boolean;
    procedure EndSection();

    procedure GetKeys(const ADest: TStrings);
    procedure GetSections(const ADest: TStrings);
  end;


  IX2PersistReader = interface(IX2PersistFiler)
    ['{250C0BFB-734D-438A-A692-0B4B50771D97}']
    function Read(AObject: TObject): Boolean;

    function ReadBoolean(const AName: String; out AValue: Boolean): Boolean;
    function ReadInteger(const AName: String; out AValue: Integer): Boolean;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean;
    function ReadString(const AName: String; out AValue: String): Boolean;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean;
    function ReadStream(const AName: String; AStream: TStream): Boolean;
  end;


  IX2PersistWriter = interface(IX2PersistFiler)
    ['{2F8D1B01-D1EA-48D7-A727-D32A6DBA5EA3}']
    procedure Write(AObject: TObject);

    function WriteBoolean(const AName: String; AValue: Boolean): Boolean;
    function WriteInteger(const AName: String; AValue: Integer): Boolean;
    function WriteFloat(const AName: String; AValue: Extended): Boolean;
    function WriteString(const AName, AValue: String): Boolean;
    function WriteInt64(const AName: String; AValue: Int64): Boolean;
    function WriteStream(const AName: String; AStream: TStream): Boolean;

    procedure DeleteKey(const AName: String);
    procedure DeleteSection(const AName: String);
  end;


  IX2PersistCustomData = interface
    ['{43E3348B-F48B-4F9B-A877-A92F8B417E0E}']
    procedure Read(AReader: IX2PersistReader);
    procedure Write(AWriter: IX2PersistWriter);
  end;


implementation

end.
