program X2UtUnitTests;

uses
  TestFramework,
  GUITestRunner,
  Variants,
  BitsTest in 'Units\BitsTest.pas',
  HashesTest in 'Units\HashesTest.pas',
  PersistTest in 'Units\PersistTest.pas',
  X2UtSingleInstance in '..\X2UtSingleInstance.pas',
  X2UtHashes in '..\X2UtHashes.pas',
  X2UtHashesVariants in '..\X2UtHashesVariants.pas',
  NamedFormatTest in 'Units\NamedFormatTest.pas';

//SettingsTest in 'Units\SettingsTest.pas',
  //IniParserTest in 'Units\IniParserTest.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  RunRegisteredTests();
end.
 
