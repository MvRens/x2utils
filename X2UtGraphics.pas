{
  :: X2UtGraphics contains various graphics-related functions.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtGraphics;

interface
uses
  Classes,
  Controls,
  Graphics;

  {
    :$ Applies anti-aliasing to a font.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased.
  }
  procedure AAFont(const AFont: TFont);

  {
    :$ Applies anti-aliasing to a control's font.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased.
  }
  procedure AAControl(const AControl: TControl);

  {
    :$ Applies anti-aliasing to all child controls.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased. If ARecursive is set to True,
    :: all children's children will be processed as well.
  }
  procedure AAChildren(const AParent: TWinControl;
                       const ARecursive: Boolean = False);

  {
    :$ Applies anti-aliasing to all owned controls.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased.
  }
  procedure AAOwned(const AOwner: TComponent);


implementation
uses
  SysUtils,
  Windows;

type
  { Explanation of sneaky hack:

      Normally, protected members are available only in either the unit in which
      the class is declared, or any descendants. Using this fact, we create a
      descendant of the class and use the descendant in the same class, thus
      we are able to access the protected properties...
  }
  THackControl  = class(TControl);


procedure AAFont;
var
  pFont:      TLogFont;
  hAAFont:    HFONT;

begin
  // Use AFont as a starting point...
  with pFont do begin
    lfHeight          := AFont.Height;
    lfWidth           := 0;
    lfEscapement      := 0;
    lfOrientation     := 0;

    if fsBold in AFont.Style then
      lfWeight        := FW_BOLD
    else
      lfWeight        := 0;

    // These are actually booleans, but implemented as bytes for some reason
    lfItalic          := Byte(fsItalic in AFont.Style);
    lfUnderline       := Byte(fsUnderline in AFont.Style);
    lfStrikeOut       := 0;
    lfCharSet         := DEFAULT_CHARSET;
    lfOutPrecision    := OUT_DEFAULT_PRECIS;
    lfClipPrecision   := CLIP_DEFAULT_PRECIS;

    // This is what causes the anti-aliasing
    lfQuality         := ANTIALIASED_QUALITY;

    lfPitchAndFamily  := DEFAULT_PITCH;
    StrPCopy(lfFaceName, AFont.Name);
  end;

  // Create the font
  hAAFont := CreateFontIndirect(pFont);

  // Assign it to the control
  AFont.Handle  := hAAFont;
end;

procedure AAControl;
var
  pControl:     THackControl;

begin
  pControl              := THackControl(AControl);
  AAFont(pControl.Font);
end;

procedure AAChildren;
var
  iControl:       Integer;

begin
  for iControl  := 0 to AParent.ControlCount - 1 do
  begin
    AAControl(AParent.Controls[iControl]);

    if ARecursive and (AParent.Controls[iControl] is TWinControl) then
      AAChildren(TWinControl(AParent.Controls[iControl]), True);
  end;
end;

procedure AAOwned;
var
  iControl:       Integer;

begin
  for iControl  := 0 to AOwner.ComponentCount - 1 do
    if AOwner.Components[iControl] is TControl then
      AAControl(TControl(AOwner.Components[iControl]));
end;

end.
