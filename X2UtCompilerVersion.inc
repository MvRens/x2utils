// This makes it easier to check which compiler version is
// being used...
{$DEFINE DUNKNOWN}

{$IFDEF VER160}
  {$DEFINE D8}
  {$DEFINE D7}
  {$DEFINE D6}
  {$DEFINE D5}
  {$DEFINE D4}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER150}
  {$DEFINE D7}
  {$DEFINE D6}
  {$DEFINE D5}
  {$DEFINE D4}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER140}
  {$DEFINE D6}
  {$DEFINE D5}
  {$DEFINE D4}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER130}
  {$DEFINE D5}
  {$DEFINE D4}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER120}
  {$DEFINE D4}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER100}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER90}
  {$DEFINE D2}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

{$IFDEF VER80}
  {$DEFINE D1}
  {$UNDEF DUNKNOWN}
{$ENDIF}

// For unknown compiler versions, assume it is newer.
// Anything other than Delphi; good luck. I don't use it,
// so I don't know what defines they have... if you do know,
// feel free to send me any changes...
{$IFDEF DUNKNOWN}
  {$DEFINE D8}
  {$DEFINE D7}
  {$DEFINE D6}
  {$DEFINE D5}
  {$DEFINE D4}
  {$DEFINE D3}
  {$DEFINE D2}
  {$DEFINE D1}
{$ENDIF}
