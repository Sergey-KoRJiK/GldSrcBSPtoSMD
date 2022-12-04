unit UnitStaticModelSMD;

interface

uses
  SysUtils,
  Windows,
  Classes,
  UnitVec,
  UnitFace,
  UnitPlane,
  UnitBSPstruct;


const BoneZeroStr: String = '0 ';
const StaticModelHeader: String =
    'version 1' + LF +
    'nodes' + LF +
    '0 "root_bone" -1' + LF +
    'end' + LF +
    'skeleton' + LF +
    'time 0' + LF +
    '0 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000' + LF +
    'end' + LF +
    'triangles';

type tTriangleSMD = record
    V0, V1, V2: tVec3f;
    UV0, UV1, UV2: tVec2f;
  end;
type PTriangleSMD = ^tTriangleSMD;
type ATriangleSMD = array of tTriangleSMD;


function SplitFaceOnTriangle(const lpFaceInfo: PFaceInfo; var Triangles: ATriangleSMD): Integer;
function SaveMapToSMD(const OrigFileName: String; const Map: PMapBSP): Integer;


implementation


function SplitFaceOnTriangle(const lpFaceInfo: PFaceInfo; var Triangles: ATriangleSMD): Integer;
var
  i: Integer;
begin
  {$R-}
  Result:=lpFaceInfo.CountVertex - 2;
  if (Result <= 0) then Exit;

  for i:=2 to (lpFaceInfo.CountVertex - 1) do
    begin
      Triangles[i - 2].V0:=lpFaceInfo.Vertex[0];
      Triangles[i - 2].V1:=lpFaceInfo.Vertex[i];
      Triangles[i - 2].V2:=lpFaceInfo.Vertex[i - 1];
      Triangles[i - 2].UV0:=lpFaceInfo.TexCoords[0];
      Triangles[i - 2].UV1:=lpFaceInfo.TexCoords[i];
      Triangles[i - 2].UV2:=lpFaceInfo.TexCoords[i - 1];
    end;
  {$R+}
end;

function SaveMapToSMD(const OrigFileName: String; const Map: PMapBSP): Integer;
var
  i, j, CountTriangles: Integer;
  lpFaceInfo: PFaceInfo;
  tmpTriags: ATriangleSMD;
  ModelFile: TextFile;
  GroupName, NormStr: String;
begin
  {$R-}
  AssignFile(ModelFile, OrigFileName);
  Rewrite(ModelFile);

  Writeln(ModelFile, StaticModelHeader);
  SetLength(tmpTriags, Map.MaxCountVertexPerFace - 2);
  Result:=0;
  for i:=0 to (Map.CountFaces - 1) do
    begin
      lpFaceInfo:=@Map.FaceInfos[i];

      CountTriangles:=SplitFaceOnTriangle(lpFaceInfo, tmpTriags);
      if (CountTriangles <= 0) then Continue;
      Inc(Result, CountTriangles);

      GroupName:=Map.TextureNames[lpFaceInfo.TexNameId] + '.bmp';
      NormStr:=' ' + Vec3fToStrFixed(lpFaceInfo.Normal) + ' ';

      for j:=0 to (CountTriangles - 1) do
        begin
          Writeln(ModelFile, GroupName);

          // format: bone v0 n0 UV0
          Writeln(ModelFile,
            BoneZeroStr,
            Vec3fToStrFixed(tmpTriags[j].V0),
            NormStr,
            Vec2fToStrFixed(tmpTriags[j].UV0)
          );

          // format: bone v1 n1 UV1
          Writeln(ModelFile,
            BoneZeroStr,
            Vec3fToStrFixed(tmpTriags[j].V1),
            NormStr,
            Vec2fToStrFixed(tmpTriags[j].UV1)
          );

          // format: bone v2 n2 UV2
          Writeln(ModelFile,
            BoneZeroStr,
            Vec3fToStrFixed(tmpTriags[j].V2),
            NormStr,
            Vec2fToStrFixed(tmpTriags[j].UV2)
          );
        end;
    end;
  Write(ModelFile, 'end');
  CloseFile(ModelFile);
  
  SetLength(tmpTriags, 0);
  {$R+}
end;

end.
