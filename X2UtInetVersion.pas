{** Provides internet version checking.
 *
 * Queries an URL for XML version information.
 * <br /><br />
 *
 * Last changed:  $Date$ <br />
 * Revision:      $Rev$ <br />
 * Author:        $Author$ <br />
*}
unit X2UtInetVersion;

interface
uses
  Classes,

  IdHTTPHeaderInfo,
  XMLIntf;
  
type
  TX2InetVersionType  = (vtUnknown, vtStable, vtBeta, vtReleaseCandidate);

  TX2InetVersionInfo  = class(TCollectionItem)
  private
    FMajor:                 Integer;
    FMinor:                 Integer;
    FRelease:               Integer;
    FBuild:                 Integer;
    FNewer:                 Boolean;
    FVersionType:           TX2InetVersionType;
    FVersionTypeString:     String;
    FWhatsNewTemp:          String;
  protected
    procedure LoadFromNode(const ANode: IXMLNode);
  public
    property VersionType:       TX2InetVersionType  read FVersionType;
    property VersionTypeString: String              read FVersionTypeString;
    property Major:             Integer             read FMajor;
    property Minor:             Integer             read FMinor;
    property Release:           Integer             read FRelease;
    property Build:             Integer             read FBuild;
    property Newer:             Boolean             read FNewer;
    property WhatsNewTemp:      String              read FWhatsNewTemp;
  end;

  TX2InetVersions     = class(TCollection)
  private
    function GetItem(Index: Integer): TX2InetVersionInfo;
    procedure SetItem(Index: Integer; Value: TX2InetVersionInfo);
  public
    constructor Create();

    function Add(): TX2InetVersionInfo;

    property Items[Index: Integer]:  TX2InetVersionInfo  read GetItem
                                                         write SetItem; default;
  end;

  TX2InetVersion  = class(TThread)
  private
    FAppID:             String;
    FURL:               String;
    FProxyParams:       TIdProxyConnectionInfo;

    FApplicationURL:    String;
    FVersions:          TX2InetVersions;
  protected
    procedure Execute(); override;
  public
    constructor Create();
    destructor Destroy(); override;

    property AppID:             String                  read FAppID write FAppID;
    property URL:               String                  read FURL   write FURL;
    property ProxyParams:       TIdProxyConnectionInfo  read FProxyParams;
    
    property ApplicationURL:    String                  read FApplicationURL;
    property Versions:          TX2InetVersions         read FVersions;
  end;

implementation
uses
  ActiveX,
  SysUtils,
  XMLDoc,

  IdURI,
  IdHTTP,
  X2UtApp;


{ TX2InetVersionInfo }
procedure TX2InetVersionInfo.LoadFromNode(const ANode: IXMLNode);
  function GetVersion(const AName: String): Integer;
  var
    xmlVersion:     IXMLNode;

  begin
    Result      := 0;
    xmlVersion  := ANode.ChildNodes.FindNode(AName);
    if Assigned(xmlVersion) then
      Result  := StrToIntDef(xmlVersion.Text, 0);
  end;

var
  xmlItem:          IXMLNode;
  xmlWhatsNew:      IXMLNode;

begin
  FVersionTypeString  := ANode.Attributes['type'];
  FVersionType        := vtUnknown;

  if FVersionTypeString = 'stable' then
    FVersionType      := vtStable
  else if FVersionTypeString = 'beta' then
    FVersionType      := vtBeta
  else if FVersionTypeString = 'releasecandidate' then
    FVersionType      := vtReleaseCandidate;

  FMajor    := GetVersion('major');
  FMinor    := GetVersion('minor');
  FRelease  := GetVersion('release');
  FBuild    := GetVersion('build');

  with App.Version do
    FNewer  := (FMajor > Major) or
               ((FMajor = Major) and (FMinor > Minor)) or
               ((FMajor = Major) and (FMinor = Minor) and (FRelease > Release)) or
               ((FMajor = Major) and (FMinor = Minor) and (FRelease = Release) and (FBuild > Build));

  FWhatsNewTemp := '';
  xmlWhatsNew   := ANode.ChildNodes.FindNode('whatsnew');
  if Assigned(xmlWhatsNew) then
  begin
    xmlItem := xmlWhatsNew.ChildNodes.First();
    while Assigned(xmlItem) do
    begin
      if xmlItem.NodeName = 'item' then
      begin
        FWhatsNewTemp := FWhatsNewTemp + '- ' + xmlItem.Text + #13#10;
      end;

      xmlItem := xmlItem.NextSibling();
    end;
  end;
end;


{ TX2InetVersions }
constructor TX2InetVersions.Create();
begin
  inherited Create(TX2InetVersionInfo);
end;


function TX2InetVersions.Add(): TX2InetVersionInfo;
begin
  Result  := TX2InetVersionInfo(inherited Add());
end;


function TX2InetVersions.GetItem(Index: Integer): TX2InetVersionInfo;
begin
  Result  := TX2InetVersionInfo(inherited GetItem(Index));
end;

procedure TX2InetVersions.SetItem(Index: Integer; Value: TX2InetVersionInfo);
begin
  inherited SetItem(Index, Value);
end;


{ TX2InetVersion }
constructor TX2InetVersion.Create();
begin
  inherited Create(True);

  FProxyParams  := TIdProxyConnectionInfo.Create();
  FVersions     := TX2InetVersions.Create();
end;

destructor TX2InetVersion.Destroy();
begin
  FreeAndNil(FVersions);
  FreeAndNil(FProxyParams);

  inherited;
end;


procedure TX2InetVersion.Execute();
var
  idHTTP:       TIdHTTP;
  memData:      TMemoryStream;
  xmlDoc:       IXMLDocument;
  xmlRoot:      IXMLNode;
  xmlURL:       IXMLNode;
  xmlVersion:   IXMLNode;

begin
  CoInitialize(nil);

  idHTTP  := TIdHTTP.Create(nil);
  try
    idHTTP.ProxyParams.Assign(FProxyParams);
    memData := TMemoryStream.Create();
    try
      idHTTP.Get(Format('%s?appid=%s', [FURL, TIdURI.ParamsEncode(FAppID)]), memData);
      memData.Seek(0, soFromBeginning);

      xmlDoc  := TXMLDocument.Create(nil);
      try
        xmlDoc.LoadFromStream(memData);
        xmlRoot := xmlDoc.DocumentElement;

        if xmlRoot.NodeName <> 'application' then
          exit;

        xmlURL  := xmlRoot.ChildNodes.FindNode('url');
        if Assigned(xmlURL) then
          FApplicationURL := xmlURL.Text;

        xmlVersion  := xmlRoot.ChildNodes.First();
        while Assigned(xmlVersion) do
        begin
          if xmlVersion.NodeName = 'version' then
            FVersions.Add().LoadFromNode(xmlVersion);

          xmlVersion  := xmlVersion.NextSibling();
        end;
      finally
        xmlDoc  := nil;
      end;
    finally
      FreeAndNil(memData);
    end;
  finally
    FreeAndNil(idHTTP);
  end;
end;

end.
 