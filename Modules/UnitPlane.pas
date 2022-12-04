unit UnitPlane;

interface

uses
  SysUtils,
  UnitVec;

type ePlaneType = (
    PLANE_X = 0,
    PLANE_Y = 1,
    PLANE_Z = 2,
    PLANE_ANY_X = 3,
    PLANE_ANY_Y = 4,
    PLANE_ANY_Z = 5
  );

type tPlane = record
    vNormal: tVec3f;
    fDist: Single;
    nType: ePlaneType;
  end;
type PPlane = ^tPlane;
type APlane = array of tPlane;


implementation


end.
