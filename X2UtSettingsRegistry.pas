{
  :: X2UtSettingsRegistry extends X2UtSettings with registry reading/writing.
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
unit X2UtSettingsRegistry;

interface
uses
  Classes,
  Registry,
  Windows,
  X2UtSettings;

type
  {
    :$ Registry-based settings implementation

    :: It is highly recommended to create instances using
    :: TX2RegistrySettingsFactory instead of directly.
  }
  TX2RegistrySettings         = class(TX2Settings)
  private
    FData:        TRegistry;
    FKey:         String;
    FOpen:        Boolean;
    FReadOnly:    Boolean;

    function OpenRead(): Boolean;
    function OpenWrite(): Boolean;
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
    constructor Create(const ARoot: Cardinal; const AKey: String);
    destructor Destroy(); override;
  end;

  {
    :$ Factory for Registry-based settings

    :: Before use, assign Root and Key to valid values.
  }
  TX2RegistrySettingsFactory  = class(TX2SettingsFactory)
  private
    FKey:           String;
    FRoot:          HKEY;
  protected
    function GetSection(const ASection: String): TX2Settings; override;
  public
    //:$ Specifies the base registry key
    property Key:           String    read FKey     write FKey;

    //:$ Specifies the root key
    property Root:          HKEY      read FRoot    write FRoot;
  end;

implementation
uses
  SysUtils;

{============= TX2RegistrySettingsFactory
  Section
========================================}
function TX2RegistrySettingsFactory.GetSection;
var
  sKey:       String;

begin
  sKey    := IncludeTrailingPathDelimiter(FKey) +
             StringReplace(ASection, '.', '\', [rfReplaceAll]);
  Result  := TX2RegistrySettings.Create(FRoot, sKey);
end;


{==================== TX2RegistrySettings
  Initialization
========================================}
constructor TX2RegistrySettings.Create;
begin
  inherited Create();

  FData         := TRegistry.Create();
  FData.RootKey := ARoot;
  FKey          := AKey;
end;

destructor TX2RegistrySettings.Destroy;
begin
  FreeAndNil(FData);

  inherited;
end;


function TX2RegistrySettings.OpenRead;
begin
  if not FOpen then begin
    FReadOnly := True;
    FOpen     := FData.OpenKey(FKey, False);
  end;

  Result  := FOpen;
end;

function TX2RegistrySettings.OpenWrite;
begin
  if (FOpen) and (FReadOnly) then begin
    FData.CloseKey();
    FOpen := False;
  end;

  if not FOpen then begin
    FReadOnly := False;
    FOpen     := FData.OpenKey(FKey, True);
  end;

  Result  := FOpen;
end;


{==================== TX2RegistrySettings
  Read
========================================}
function TX2RegistrySettings.ReadBool;
begin
  Result  := ADefault;

  if (OpenRead()) and (FData.ValueExists(AName)) then
    try
      Result  := FData.ReadBool(AName)
    except
      // Silently ignore exceptions so the
      // default value gets returned
    end;
end;

function TX2RegistrySettings.ReadFloat;
begin
  Result  := ADefault;

  if (OpenRead()) and (FData.ValueExists(AName)) then
    try
      Result  := FData.ReadFloat(AName)
    except
    end;
end;

function TX2RegistrySettings.ReadInteger;
begin
  Result  := ADefault;

  if (OpenRead()) and (FData.ValueExists(AName)) then
    try
      Result  := FData.ReadInteger(AName)
    except
    end;
end;

function TX2RegistrySettings.ReadString;
begin
  Result  := ADefault;

  if (OpenRead()) and (FData.ValueExists(AName)) then
    try
      Result  := FData.ReadString(AName)
    except
    end;
end;


{==================== TX2RegistrySettings
  Write
========================================}
procedure TX2RegistrySettings.WriteBool;
begin
  if OpenWrite() then
    FData.WriteBool(AName, AValue);
end;

procedure TX2RegistrySettings.WriteFloat;
begin
  if OpenWrite() then
    FData.WriteFloat(AName, AValue);
end;

procedure TX2RegistrySettings.WriteInteger;
begin
  if OpenWrite() then
    FData.WriteInteger(AName, AValue);
end;

procedure TX2RegistrySettings.WriteString;
begin
  if OpenWrite() then
    FData.WriteString(AName, AValue);
end;


{==================== TX2RegistrySettings
  Enumeration
========================================}
procedure TX2RegistrySettings.GetSectionNames;
begin
  if OpenRead() then
    FData.GetKeyNames(ADest);
end;


procedure TX2RegistrySettings.GetValueNames;
begin
  if OpenRead() then
    FData.GetValueNames(ADest);
end;


{==================== TX2RegistrySettings
  Delete
========================================}
procedure TX2RegistrySettings.DeleteSection;
begin
  // On Delphi 6 at least DeleteKey recursively calls itself for subkeys,
  // eliminating issues with WinNT based systems. Might need to verify
  // for Delphi 5 or lower if it's ever used.
  FData.CloseKey();
  FData.DeleteKey(FKey);
  FOpen := False;
end;

procedure TX2RegistrySettings.DeleteValue;
begin
  if OpenRead() then
    if FData.ValueExists(AName) then
      FData.DeleteValue(AName);
end;

function TX2RegistrySettings.ValueExists;
begin
  Result  := False;
  
  if OpenRead() then
    Result  := FData.ValueExists(AName);
end;

end.
