program GoldSrcBSPtoSMD;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  Classes,
  Graphics,
  UnitBSPstruct in 'Modules\UnitBSPstruct.pas',
  UnitVec in 'Modules\UnitVec.pas',
  UnitPlane in 'Modules\UnitPlane.pas',
  UnitTexture in 'Modules\UnitTexture.pas',
  UnitMapHeader in 'Modules\UnitMapHeader.pas',
  UnitFace in 'Modules\UnitFace.pas',
  UnitBrushModel in 'Modules\UnitBrushModel.pas',
  UnitEntity in 'Modules\UnitEntity.pas',
  UnitStaticModelSMD in 'Modules\UnitStaticModelSMD.pas';

var
  MapBSP: tMapBSP;
  FileName: String;
  TotalCountTriangles: Integer;
begin
  {$R-}
  Writeln('Programm to export GoldSrc BSP map to SMD static model.');
  Writeln('Support export entity and world brushes with all textures,');
  Writeln('include tool textures like sky, trigger and ect. Support');
  Writeln('export texture names and coords.');
  Writeln;
  FileName:=ParamStr(1);
  if (FileName <> '') then
    begin
      Writeln('Map: ' + FileName);
      Writeln;
      if not(LoadBSP30FromFile(FileName, @MapBSP)) then
        begin
          Write(' Error Load Map: ');
          Writeln(ShowLoadBSPMapError(MapBSP.LoadState));
        end
      else
        begin
          Write('Map Loaded. Exporting to SMD...');

          FileName:=ExtractOrigFileName(ExtractFileName(FileName))+ '.smd';
          TotalCountTriangles:=SaveMapToSMD(FileName, @MapBSP);
          Writeln('Complited!');
          Writeln('Total Triangles: ', TotalCountTriangles);
          Writeln('Total Vertecies: ', MapBSP.CountVertices);
          Writeln('Total Original Faces: ', MapBSP.CountFaces);
          Writeln('Total Texture Groups: ', MapBSP.TextureLump.nCountTextures);
          Writeln('Saved to File: ', FileName);
        end;
      FreeMapBSP(@MapBSP);
    end
  else Writeln('Drop *.bsp map file on Application');
  Writeln;
  Write('Press Enter to exit...');
  Readln;
  {$R+}
end.
