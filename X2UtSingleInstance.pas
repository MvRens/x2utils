{
  :: X2UtSingleInstance provides functions to detect previous instances of an
  :: application and pass it the new command-line parameters.
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
unit X2UtSingleInstance;

interface
uses
  SysUtils;

type
  {
    :$ Notifier interface

    :: Applications who want to receive notifications on new instances must
    :: implements this interface and call RegisterInstance.
  }
  IX2InstanceNotifier = interface
    ['{4C435D46-6A7F-4CD7-9400-338E3E8FB5C6}']
    procedure OnInstance(const ACmdLine: String);
  end;

  //:$ Checks for a previous instance of the application
  //:: Returns False if a previous instance was found, True if this is the
  //:: first registered instance. ApplicationID must be unique to prevent
  //:: application conflicts, usage of a generated GUID is recommended.
  //:! Set ANotify to False if you're using SingleInstance in a console
  //:! application without a message loop.
  function SingleInstance(const AApplicationID: String;
                          const ANotify: Boolean = True): Boolean;

  //:$ Registers the instance for notifications
  //:: If an application wants to be notified of new instances it must
  //:: implement the IX2InstanceNotifier and register the interface using
  //:: this function.
  procedure RegisterInstance(const ANotifier: IX2InstanceNotifier);

  //:$ Unregisters a previously registered instance
  procedure UnregisterInstance(const ANotifier: IX2InstanceNotifier);


  //:$ Works like System.ParamCount, but uses the specified string instead
  //:$ of the actual command line
  function ParamCountEx(const ACmdLine: String): Integer;

  //:$ Works like System.ParamStr, but uses the specified string instead
  //:$ of the actual command line
  function ParamStrEx(const ACmdLine: String; AIndex: Integer): String;

  //:$ Works like SysUtils.FindCmdLineSwitch, but uses the specified string
  //:$ instead of the actual command line
  function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                               const AChars: TSysCharSet;
                               const AIgnoreCase: Boolean): Boolean; overload;

  //:$ Works like SysUtils.FindCmdLineSwitch, but uses the specified string
  //:$ instead of the actual command line
  function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String): Boolean; overload;

  //:$ Works like SysUtils.FindCmdLineSwitch, but uses the specified string
  //:$ instead of the actual command line
  function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                               const AIgnoreCase: Boolean): Boolean; overload;

implementation
uses
  Classes,
  Messages,
  Windows;

const
  CWindowClass  = 'X2UtInstance.Window';
  CDataCmdLine  = $1010;

var
  GNotifiers:       TInterfaceList;
  GFileMapping:     THandle;
  GWindow:          THandle;


{$WARN SYMBOL_PLATFORM OFF}  


// Copied from System unit because Borland didn't make it public
function GetParamStr(P: PChar; var Param: string): PChar;
var
  i, Len: Integer;
  Start, S, Q: PChar;
begin
  while True do
  begin
    while (P[0] <> #0) and (P[0] <= ' ') do
      P := CharNext(P);
    if (P[0] = '"') and (P[1] = '"') then Inc(P, 2) else Break;
  end;
  Len := 0;
  Start := P;
  while P[0] > ' ' do
  begin
    if P[0] = '"' then
    begin
      P := CharNext(P);
      while (P[0] <> #0) and (P[0] <> '"') do
      begin
        Q := CharNext(P);
        Inc(Len, Q - P);
        P := Q;
      end;
      if P[0] <> #0 then
        P := CharNext(P);
    end
    else
    begin
      Q := CharNext(P);
      Inc(Len, Q - P);
      P := Q;
    end;
  end;

  SetLength(Param, Len);

  P := Start;
  S := Pointer(Param);
  i := 0;
  while P[0] > ' ' do
  begin
    if P[0] = '"' then
    begin
      P := CharNext(P);
      while (P[0] <> #0) and (P[0] <> '"') do
      begin
        Q := CharNext(P);
        while P < Q do
        begin
          S[i] := P^;
          Inc(P);
          Inc(i);
        end;
      end;
      if P[0] <> #0 then P := CharNext(P);
    end
    else
    begin
      Q := CharNext(P);
      while P < Q do
      begin
        S[i] := P^;
        Inc(P);
        Inc(i);
      end;
    end;
  end;

  Result := P;
end;


{========================================
  Window Procedure
========================================}
function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  sCmdLine:       String;
  iNotifier:      Integer;

begin
  Result  := DefWindowProc(hWnd, uMsg, wParam, lParam);

  case uMsg of
    WM_COPYDATA:
      if PCopyDataStruct(lParam)^.dwData = CDataCmdLine then begin
        with PCopyDataStruct(lParam)^ do
          SetString(sCmdLine, PChar(lpData), cbData - 1);

        for iNotifier := GNotifiers.Count - 1 downto 0 do
          IX2InstanceNotifier(GNotifiers[iNotifier]).OnInstance(sCmdLine);
      end;
  end;
end;


{========================================
  Single Instance Check
========================================}
function SingleInstance;
var
  pData:        ^THandle;
  pCopy:        TCopyDataStruct;
  pCmdLine:     PChar;
  sDummy:       String;

begin
  Result  := False;
  if GFileMapping <> 0 then
    exit;

  // Attempt to create shared memory
  GFileMapping  := CreateFileMapping($ffffffff, nil, PAGE_READWRITE, 0,
                                     SizeOf(THandle), PChar('X2UtInstance.' +
                                     AApplicationID));
  if GFileMapping = 0 then
    exit;

  if GetLastError() = ERROR_ALREADY_EXISTS then begin
    if ANotify then begin
      pData := MapViewOfFile(GFileMapping, FILE_MAP_READ, 0, 0, 0);
      if Assigned(pData) then begin
        // Pass command-line parameters
        with pCopy do begin
          pCmdLine  := PChar('"' + ParamStr(0) + '" ' + GetParamStr(CmdLine, sDummy));

          dwData    := CDataCmdLine;
          cbData    := StrLen(pCmdLine) + 1;

          GetMem(lpData, cbData);
          StrCopy(lpData, pCmdLine);
        end;

        SendMessage(pData^, WM_COPYDATA, 0, Integer(@pCopy));
        UnmapViewOfFile(pData);
      end;
    end;

    CloseHandle(GFileMapping);
    GFileMapping  := 0;
    exit;
  end;

  pData   := MapViewOfFile(GFileMapping, FILE_MAP_WRITE, 0, 0, 0);
  if Assigned(pData) then begin
    // Create window
    GWindow := CreateWindow(CWindowClass, '', 0, 0, 0, 0, 0, 0, 0,
                            SysInit.HInstance, nil);
    pData^  := GWindow;
  end else begin
    CloseHandle(GFileMapping);
    GFileMapping  := 0;
    exit;
  end;

  Result  := True;
end;


{========================================
  Notifier Registration
========================================}
procedure RegisterInstance;
begin
  if GNotifiers.IndexOf(ANotifier) = -1 then
    GNotifiers.Add(ANotifier);
end;

procedure UnregisterInstance;
var
  iIndex:       Integer;

begin
  iIndex  := GNotifiers.IndexOf(ANotifier);
  if iIndex > -1 then
    GNotifiers.Delete(iIndex);
end;


{========================================
  Parameter Functions
========================================}
function ParamCountEx;
var
  pCmdLine:     PChar;
  sParam:       String;

begin
  Result    := 0;
  pCmdLine  := GetParamStr(PChar(ACmdLine), sParam);

  while True do begin
    pCmdLine  := GetParamStr(pCmdLine, sParam);

    if Length(sParam) = 0 then
      break;

    Inc(Result);
  end;
end;

function ParamStrEx;
var
  pCmdLine:       PChar;

begin
  Result    := '';
  pCmdLine  := PChar(ACmdLine);
  while True do begin
    pCmdLine  := GetParamStr(pCmdLine, Result);

    if (AIndex = 0) or (Length(Result) = 0) then
      break;

    Dec(AIndex);
  end;
end;


function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                             const AChars: TSysCharSet;
                             const AIgnoreCase: Boolean): Boolean;
var
  iParam:         Integer;
  sParam:         String;

begin
  for iParam  := 1 to ParamCountEx(ACmdLine) do begin
    sParam  := ParamStrEx(ACmdLine, iParam);

    if (AChars = []) or (sParam[1] in AChars) then
      if AIgnoreCase then begin
        if (AnsiCompareText(Copy(sParam, 2, Maxint), ASwitch) = 0) then begin
          Result  := True;
          exit;
        end;
      end else begin
        if (AnsiCompareStr(Copy(sParam, 2, Maxint), ASwitch) = 0) then begin
          Result  := True;
          exit;
        end;
      end;
  end;

  Result  := False;
end;

function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String): Boolean;
begin
  Result  := FindCmdLineSwitchEx(ACmdLine, ASwitch, SwitchChars, True);
end;

function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                           const AIgnoreCase: Boolean): Boolean;
begin
  Result  := FindCmdLineSwitchEx(ACmdLine, ASwitch, SwitchChars, AIgnoreCase);
end;



var
  wndClass:       TWndClass;

initialization
  GNotifiers  := TInterfaceList.Create();

  // Register window class
  FillChar(wndClass, SizeOf(wndClass), #0);
  with wndClass do begin
    lpfnWndProc     := @WndProc;
    hInstance       := SysInit.HInstance;
    lpszClassName   := CWindowClass;
  end;

  Windows.RegisterClass(wndClass);

finalization
  FreeAndNil(GNotifiers);

  if GFileMapping <> 0 then
    // Free file mapping
    CloseHandle(GFileMapping);

  if GWindow <> 0 then
    DestroyWindow(GWindow);

  Windows.UnregisterClass(CWindowClass, SysInit.HInstance);

end.
