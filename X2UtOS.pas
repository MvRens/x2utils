{
  :: X2UtOS provides a singleton OS object to access properties associated
  :: with the Operating System, such as the version number.
  :: It is part of the X2Utils suite.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtOS;

interface
uses
  Windows;

type
  //:$ Enumeration of the recognized Operating System versions
  TX2OSVersion  = (osWin95, osWin98, osWinME, osWinNT3, osWinNT4,
                   osWin2K, osWinXP, osWin2003, osUnknown);

  {
    :$ Contains extended version information for the Operating System
  }
  TX2OSVersionEx  = class(TObject)
  private
    FName:            String;
    FVersionString:   String;
    FBuild:           Cardinal;
    FRawInfo:         TOSVersionInfo;
  public
    //:$ Contains the name of the OS
    property Name:            String          read FName          write FName;

    //:$ Contains a string representation of the OS' version
    property VersionString:   String          read FVersionString write FVersionString;

    //:$ Contains the build number of the OS
    property Build:           Cardinal        read FBuild         write FBuild;

    //:$ Contains the raw version information as provided by the OS
    property RawInfo:         TOSVersionInfo  read FRawInfo       write FRawInfo;
  end;

  {
    :$ Container for the Operating System's information
  }
  TX2OS           = class(TObject)
  private
    FVersion:         TX2OSVersion;
    FVersionEx:       TX2OSVersionEx;
  protected
    procedure GetVersion(); virtual;
  public
    constructor Create();
    destructor Destroy(); override;

    //:$ Returns the formatted version information
    //:: If Build is False, the return value will not include the
    //:: OS' Build number.
    function FormatVersion(Build: Boolean = True): String;

    //:$ Contains the detected OS version
    property Version:       TX2OSVersion    read FVersion;

    //:$ Contains extended OS version information
    property VersionEx:     TX2OSVersionEx  read FVersionEx;
  end;

  function OS(): TX2OS;

implementation
uses
  SysUtils;
  
var
  GOS:        TX2OS;


{========================================
  Singleton
========================================}
function OS;
begin
  if not Assigned(GOS) then
    GOS := TX2OS.Create();

  Result  := GOS;
end;


{================================== TX2OS
  Initialization
========================================}
constructor TX2OS.Create;
begin
  inherited;

  FVersionEx  := TX2OSVersionEx.Create();
  GetVersion();
end;

destructor TX2OS.Destroy;
begin
  FreeAndNil(FVersionEx);

  inherited;
end;


{================================== TX2OS
  Version
========================================}
procedure TX2OS.GetVersion;
var
  pVersion:       TOSVersionInfo;

begin
  FVersion  := osUnknown;

  // Get version information
  pVersion.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(pVersion);

  with FVersionEx do begin
    // No Kylix support yet, sorry!
    RawInfo := pVersion;
    Name    := 'Windows';

    // Analyze version
    case pVersion.dwMajorVersion of
      3:      // Windows NT 3.51
        FVersion  := osWinNT3;
      4:      // Windows 95/98/ME/NT 4
        case pVersion.dwMinorVersion of
          0:  // Windows 95/NT 4
            case pVersion.dwPlatformId of
              VER_PLATFORM_WIN32_NT:        // Windows NT 4
                FVersion  := osWinNT4;
              VER_PLATFORM_WIN32_WINDOWS:   // Windows 95
                FVersion  := osWin95;
            end;
          10: // Windows 98
            FVersion  := osWin98;
          90: // Windows ME
            FVersion  := osWinME;
        end;
      5:      // Windows 2000/XP/2003
        case pVersion.dwMinorVersion of
          0:  // Windows 2000
            FVersion  := osWin2K;
          1:  // Windows XP
            FVersion  := osWinXP;
          2:  // Windows Server 2003
            FVersion  := osWin2003;
        end;
    end;

    case Version of
      osWin95:      VersionString := '95';
      osWin98:      VersionString := '98';
      osWinME:      VersionString := 'ME';
      osWinNT3:     VersionString := 'NT 3.51';
      osWinNT4:     VersionString := 'NT 4';
      osWin2K:      VersionString := '2000';
      osWinXP:      VersionString := 'XP';
      osWin2003:    VersionString := 'Server 2003';
      osUnknown:    VersionString := Format('%d.%d', [pVersion.dwMajorVersion,
                                                      pVersion.dwMinorVersion]);
    end;

    if StrLen(pVersion.szCSDVersion) > 0 then
      VersionString := VersionString + ' ' + pVersion.szCSDVersion;

    case pVersion.dwPlatformId of
      VER_PLATFORM_WIN32_NT:
        Build := pVersion.dwBuildNumber;
      VER_PLATFORM_WIN32_WINDOWS:
        Build := LoWord(pVersion.dwBuildNumber);
    end;
  end;
end;


function TX2OS.FormatVersion;
var
  sBuild:     String;

begin
  sBuild    := '';

  if Build then
    sBuild    := Format(' build %d', [FVersionEx.Build]);

  with FVersionEx do
    Result := Format('%s %s%s', [Name, VersionString, sBuild]);
end;


initialization
finalization
  FreeAndNil(GOS);
  
end.
