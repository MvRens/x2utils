{
  :: X2UtSettingsINI extends X2UtSettings with INI reading/writing.
  ::
  :: Subversion repository available at:
  ::   $URL$
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$

  :$
  :$
  :$ X2Utils is released under the zlib/libpng OSI-approved license.
  :$ For more information: http://www.opensource.org/
  :$ /n/n
  :$ /n/n
  :$ Copyright (c) 2003 X2Software
  :$ /n/n
  :$ This software is provided 'as-is', without any express or implied warranty.
  :$ In no event will the authors be held liable for any damages arising from
  :$ the use of this software.
  :$ /n/n
  :$ Permission is granted to anyone to use this software for any purpose,
  :$ including commercial applications, and to alter it and redistribute it
  :$ freely, subject to the following restrictions:
  :$ /n/n
  :$ 1. The origin of this software must not be misrepresented; you must not
  :$ claim that you wrote the original software. If you use this software in a
  :$ product, an acknowledgment in the product documentation would be
  :$ appreciated but is not required.
  :$ /n/n
  :$ 2. Altered source versions must be plainly marked as such, and must not be
  :$ misrepresented as being the original software.
  :$ /n/n
  :$ 3. This notice may not be removed or altered from any source distribution.
}
unit X2UtSettingsINI;

interface
uses
  Classes,
  IniFiles,
  X2UtSettings;

type
  {
    :$ INI-based settings implementation

    :: It is highly recommended to create instances using TX2INISettingsFactory
    :: instead of directly.
  }
  TX2INISettings        = class(TX2Settings)
  private
    FData:        TMemIniFile;
    FSection:     String;
  public
    // IX2Settings implementation
    function ReadBool(const AName: String; const ADefault: Boolean = False): Boolean; override;
    function ReadFloat(const AName: String; const ADefault: Double = 0.0): Double; override;
    function ReadInteger(const AName: String; const ADefault: Integer = 0): Integer; override;
    function ReadString(const AName: String; const ADefault: String = ''): String; override;

    procedure WriteBool(const AName: String; AValue: Boolean); override;
    procedure WriteFloat(const AName: String; AValue: Double); override;
    procedure WriteInteger(const AName: String; AValue: Integer); override;
    procedure WriteString(const AName, AValue: String); override;

    function ValueExists(const AName: String): Boolean; override;

    procedure GetSectionNames(const ADest: TStrings); override;
    procedure GetValueNames(const ADest: TStrings); override;

    procedure DeleteSection(); override;
    procedure DeleteValue(const AName: String); override;
  public
    constructor Create(const AFilename, ASection: String);
    destructor Destroy(); override;
  end;

  {
    :$ Factory for INI-based settings

    :: Before use, assign Filename with a valid path.
  }
  TX2INISettingsFactory = class(TX2SettingsFactory)
  private
    FFilename:      String;
  protected
    function GetSection(const ASection: String): TX2Settings; override;
  public
    //:$ Specifies the filename of the INI
    property Filename:      String  read FFilename  write FFilename;
  end;

implementation
uses
  SysUtils;

{================== TX2INISettingsFactory
  Section
========================================}
function TX2INISettingsFactory.GetSection;
begin
  Result  := TX2INISettings.Create(FFilename, ASection);
end;


{========================= TX2INISettings
  Initialization
========================================}
constructor TX2INISettings.Create;
begin
  inherited Create();

  FData     := TMemIniFile.Create(AFilename);
  FSection  := ASection;
end;

destructor TX2INISettings.Destroy;
begin
  FData.UpdateFile();
  FreeAndNil(FData);

  inherited;
end;


{========================= TX2INISettings
  Read
========================================}
function TX2INISettings.ReadBool;
begin
  Result  := FData.ReadBool(FSection, AName, ADefault);
end;

function TX2INISettings.ReadFloat;
begin
  Result  := FData.ReadFloat(FSection, AName, ADefault);
end;

function TX2INISettings.ReadInteger;
begin
  Result  := FData.ReadInteger(FSection, AName, ADefault);
end;

function TX2INISettings.ReadString;
begin
  Result  := FData.ReadString(FSection, AName, ADefault);
end;


{========================= TX2INISettings
  Write
========================================}
procedure TX2INISettings.WriteBool;
begin
  FData.WriteBool(FSection, AName, AValue);
end;

procedure TX2INISettings.WriteFloat;
begin
  FData.WriteFloat(FSection, AName, AValue);
end;

procedure TX2INISettings.WriteInteger;
begin
  FData.WriteInteger(FSection, AName, AValue);
end;

procedure TX2INISettings.WriteString;
begin
  FData.WriteString(FSection, AName, AValue);
end;


{========================= TX2INISettings
  Enumeration
========================================}
function TX2INISettings.ValueExists;
begin
  Result  := FData.ValueExists(FSection, AName);
end;


procedure TX2INISettings.GetSectionNames;
var
  slSections:       TStringList;
  slFound:          TStringList;
  iSection:         Integer;
  sCompare:         String;
  iCompareLen:      Integer;
  sSection:         String;
  iPos:             Integer;

begin
  sCompare    := FSection;
  iCompareLen := Length(sCompare);

  if iCompareLen > 0 then begin
    sCompare  := sCompare + '.';
    Inc(iCompareLen);
  end;

  slSections  := TStringList.Create();
  slFound     := TStringList.Create();
  try
    slFound.Sorted      := True;
    slFound.Duplicates  := dupIgnore;
    FData.ReadSections(slSections);

    // Filter out non-subsections
    for iSection  := slSections.Count - 1 downto 0 do
      if (iCompareLen = 0) or
         (SameText(sCompare, Copy(slSections[iSection], 1, iCompareLen))) then begin
        sSection  := slSections[iSection];

        Delete(sSection, 1, iCompareLen);
        iPos      := AnsiPos('.', sSection);

        if iPos > 0 then
          SetLength(sSection, iPos - 1);

        slFound.Add(sSection);
      end;

    ADest.AddStrings(slFound);
  finally
    FreeAndNil(slFound);
    FreeAndNil(slSections);
  end;
end;

procedure TX2INISettings.GetValueNames;
begin
  FData.ReadSection(FSection, ADest);
end;


{========================= TX2INISettings
  Delete
========================================}
procedure TX2INISettings.DeleteSection;
var
  slSections:       TStringList;
  iSection:         Integer;
  sCompare:         String;
  iCompareLen:      Integer;

begin
  sCompare    := FSection;
  iCompareLen := Length(sCompare);

  if iCompareLen > 0 then begin
    sCompare  := sCompare + '.';
    Inc(iCompareLen);
  end;

  slSections  := TStringList.Create();
  try
    // At first thought, parsing the sections again seems redundant, but it
    // eliminates the need for recursive calls, any section that matches the
    // start is automatically a sub-(sub-etc-)section of the current section.
    FData.ReadSections(slSections);

    for iSection  := slSections.Count - 1 downto 0 do
      if (iCompareLen = 0) or
         (SameText(sCompare, Copy(slSections[iSection], 1, iCompareLen))) then
        FData.EraseSection(slSections[iSection]);
  finally
    FreeAndNil(slSections);
  end;
  FData.EraseSection(FSection);
end;

procedure TX2INISettings.DeleteValue;
begin
  FData.DeleteKey(FSection, AName);
end;

end.
