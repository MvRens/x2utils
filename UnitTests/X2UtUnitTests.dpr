program X2UtUnitTests;

uses
  MemCheck,
  TestFramework,
  GUITestRunner,
  BitsTest in 'Units\BitsTest.pas',
  HashesTest in 'Units\HashesTest.pas';

begin
  MemChk();
  RunRegisteredTests();
end.
 