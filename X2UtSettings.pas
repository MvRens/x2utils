{
  :: X2UtSettings provides a generic access mechanism for application settings.
  :: Include one of the extensions (X2UtSettingsINI, X2UtSettingsRegistry) for
  :: an implementation.
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
unit X2UtSettings;

interface
uses
  Classes;
  
type
  {
    :$ Abstract settings object

    :: Provides access to the settings regardless of the storage backend.
  }
  TX2Settings         = class(TObject)
  public
    function ReadBool(const AName: String; const ADefault: Boolean = False): Boolean; virtual; abstract;
    function ReadFloat(const AName: String; const ADefault: Double = 0.0): Double; virtual; abstract;
    function ReadInteger(const AName: String; const ADefault: Integer = 0): Integer; virtual; abstract;
    function ReadString(const AName: String; const ADefault: String = ''): String; virtual; abstract;

    procedure WriteBool(const AName: String; AValue: Boolean); virtual; abstract;
    procedure WriteFloat(const AName: String; AValue: Double); virtual; abstract;
    procedure WriteInteger(const AName: String; AValue: Integer); virtual; abstract;
    procedure WriteString(const AName, AValue: String); virtual; abstract;

    procedure GetSectionNames(const ADest: TStrings); virtual; abstract;
    procedure GetValueNames(const ADest: TStrings); virtual; abstract;

    procedure DeleteSection(); virtual; abstract;
    procedure DeleteValue(const AName: String); virtual; abstract;
  end;

  {
    :$ Settings factory

    :: Extensions must implement a factory descendant which an application can
    :: create to provide application-wide access to the same settings.
  }
  TX2SettingsFactory  = class(TObject)
  protected
    function GetSection(const ASection: String): TX2Settings; virtual; abstract;
  public
    //:$ Load a section from the settings
    //:: Sub-sections are indicated by seperating the sections with a dot ('.')
    //:: characters, ex: Sub.Section. The underlying extension will translate
    //:: this into a compatible section.
    //:! The application is responsible for freeing the returned class.
    property Sections[const ASection: String]:    TX2Settings read GetSection; default;
  end;


implementation

end.
