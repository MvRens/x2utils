{
  :: X2UtVirtualTree provides a set of functions commonly used with
  :: TVirtualTree (http://www.delphi-gems.com/).
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
unit X2UtVirtualTree;

interface
uses
  VirtualTrees;

  //:$ Applies the sort order on the specified column
  //:: When a column is already sorted, the sort order is reversed.
  procedure SortColumn(const AHeader: TVTHeader;
                       const AColumn: TColumnIndex);

implementation

procedure SortColumn;
begin
  with AHeader do
    if SortColumn = AColumn then
      SortDirection := TSortDirection(1 - Integer(SortDirection))
    else begin
      SortColumn    := AColumn;
      SortDirection := sdAscending;
    end;
end;

end.
 