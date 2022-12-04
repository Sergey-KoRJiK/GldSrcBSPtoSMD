unit UnitBrushModel;

interface

uses SysUtils, Windows, Classes, UnitVec;

type tBrushModel = record
    vMin, vMax: tVec3f;
    Origin: tVec3f;
    iNode: Integer;
    iClipNode0, iClipNode1: Integer;
    iSpecialNode: Integer;
    nVisLeafs: Integer;
    iFirstFace, nFaces: Integer;
  end;
type PBrushModel = ^tBrushModel;
type ABrushModel = array of tBrushModel;


implementation


end.
 
