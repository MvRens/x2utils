program X2UtUnitTests;

uses
  TestFramework,
  GUITestRunner,
  Variants,
  BitsTest in 'Units\BitsTest.pas',
  HashesTest in 'Units\HashesTest.pas',
  PersistTest in 'Units\PersistTest.pas';

//SettingsTest in 'Units\SettingsTest.pas',
  //IniParserTest in 'Units\IniParserTest.pas';

begin
//  MemChk();
  RunRegisteredTests();
end.
 
