program X2UtilsSettingsTest;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  Windows,
  X2UtApp in '..\X2UtApp.pas',
  X2UtSettings in '..\X2UtSettings.pas',
  X2UtSettingsINI in '..\X2UtSettingsINI.pas',
  X2UtSettingsRegistry in '..\X2UtSettingsRegistry.pas';

procedure TraverseSection(const ASettings: TX2SettingsFactory;
                          const ASection: String = '';
                          const AIndent: Integer = 0);
var
  sIndent:          String;
  slSections:       TStringList;
  iSection:         Integer;
  slValues:         TStringList;
  iValue:           Integer;
  sSection:         String;

begin
  sIndent     := StringOfChar(' ', AIndent * 2);
  slSections  := TStringList.Create();
  try
    with ASettings[ASection] do
      try
        GetSectionNames(slSections);

        for iSection  := 0 to slSections.Count - 1 do begin
          WriteLn(sIndent, '[', slSections[iSection], ']');

          sSection  := ASection;
          if Length(sSection) > 0 then
            sSection  := sSection + '.';

          sSection  := sSection + slSections[iSection];

          slValues  := TStringList.Create();
          try
            with ASettings[sSection] do
              try
                GetValueNames(slValues);

                for iValue  := 0 to slValues.Count - 1 do
                  WriteLn(sIndent, slValues[iValue], '=', ReadString(slValues[iValue]));
              finally
                Free();
              end;
          finally
            FreeAndNil(slValues);
          end;

          TraverseSection(ASettings, sSection, AIndent + 1);
        end;
      finally
        Free();
      end;
  finally
    FreeAndNil(slSections);
  end;
end;


var
  Settings:         TX2SettingsFactory;

begin
  // INI settings
  WriteLn('INI data:');
  Settings  := TX2INISettingsFactory.Create();
  try
    with TX2INISettingsFactory(Settings) do
      Filename := App.Path + 'settings.ini';

    {
    // Deletes one section
    with Settings['Test.Section'] do
      try
        DeleteSection();
      finally
        Free();
      end;
    }

    {
    // Deletes everything
    with Settings[''] do
      try
        DeleteSection();
      finally
        Free();
      end;
    }

    // Test for the definitions
    Settings.Define('Test', 'Value', 5, [[0, 5], [10, 15]]);
    Settings.ReadInteger('Test', 'Value');

    TraverseSection(Settings, '', 1);
    WriteLn;
  finally
    FreeAndNil(Settings);
  end;
  ReadLn;

  {
  // Registry settings
  WriteLn('Registry data:');
  Settings  := TX2RegistrySettingsFactory.Create();
  try
    with TX2RegistrySettingsFactory(Settings) do begin
      Root     := HKEY_CURRENT_USER;
      Key      := '\Software\X2Software\X2FileShare\';
    end;

    // Note: you WILL get exceptions here due to the fact that not all
    // values are strings yet they are treated as such here. Perhaps in the
    // future type conversion will be done on-the-fly, but for now just press
    // F5 when debugging (you won't get exceptions when running the EXE as
    // standalone) and the default value will be returned. Perhaps the best
    // solution...
    TraverseSection(Settings, '', 1);
    ReadLn;
  finally
    FreeAndNil(Settings);
  end;
  }
end.
