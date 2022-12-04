unit UnitBSPstruct;

interface

uses
  SysUtils,
  Windows,
  Classes,
  Graphics,
  Math,
  UnitVec,
  UnitEntity,
  UnitPlane,
  UnitTexture,
  UnitMapHeader,
  UnitFace,
  UnitBrushModel;


type eLoadMapErrors = (
    erNoErrors = 0,
    erFileNotExists,
    erMinSize,
    erBadVersion,
    erBadEOFbyHeader,
    erNoEntData,
    erNoPlanes,
    erNoTextures,
    erNoVertex,
    erNoTexInfos,
    erNoFaces,
    erNoEdge,
    erNoSurfEdge,
    erNoBrushes
  );

type tMapBSP = record
    LoadState: eLoadMapErrors;
    MapFileSize: Integer;
    MapHeader: tMapHeader; // BSP

    SizeEndData: Integer;
    EntDataLump: String; // BSP
    CountEntities: Integer;
    Entities: AEntity;

    PlaneLump: APlane;  // BSP
    CountPlanes: Integer;

    TextureLump: tTextureLump; // BSP
    TextureNames: AString; // Size = nCountTextures

    VertexLump: AVertex; // BSP
    CountVertices: Integer;

    TexInfoLump: ATexInfo; // BSP
    CountTexInfos: Integer;

    FaceLump: AFace; // BSP
    FaceInfos: AFaceInfo;
    CountFaces: Integer;
    MaxCountVertexPerFace: Integer;

    EdgeLump: AEdge; // BSP
    CountEdges: Integer;

    SurfEdgeLump: ASurfEdge; // BSP
    CountSurfEdges: Integer;

    ModelLump: ABrushModel; // BSP
    CountBrushModels: Integer;
  end;
type PMapBSP = ^tMapBSP;


procedure FreeMapBSP(const Map: PMapBSP);

function LoadBSP30FromFile(const FileName: String; const Map: PMapBSP): Boolean;
function ShowLoadBSPMapError(const LoadMapErrorType: eLoadMapErrors): String;

procedure UpdateFaceInfo(const Map: PMapBSP; const FaceId: Integer);
procedure UpDateEntityInfo(const Map: PMapBSP; const EntityId: Integer);


implementation


procedure FreeMapBSP(const Map: PMapBSP);
var
  i: Integer;
begin
  {$R-}
  Map.LoadState:=erNoErrors;
  Map.MapFileSize:=0;

  Map.SizeEndData:=0;
  Map.EntDataLump:='';
  Map.CountEntities:=0;
  SetLength(Map.Entities, 0);

  Map.CountPlanes:=0;
  SetLength(Map.PlaneLump, 0);

  Setlength(Map.TextureLump.MipTexInfos, 0);
  SetLength(Map.TextureLump.OffsetsToMipTex, 0);
  SetLength(Map.TextureNames, 0);
  Map.TextureLump.nCountTextures:=0;

  Map.CountVertices:=0;
  SetLength(Map.VertexLump, 0);

  Map.CountTexInfos:=0;
  SetLength(Map.TexInfoLump, 0);

  SetLength(Map.FaceLump, 0);
  for i:=0 to (Map.CountFaces - 1) do
    begin
      SetLength(Map.FaceInfos[i].Vertex, 0);
      SetLength(Map.FaceInfos[i].TexCoords, 0);
    end;
  SetLength(Map.FaceInfos, 0);
  Map.CountFaces:=0;
  Map.MaxCountVertexPerFace:=0;

  Map.CountEdges:=0;
  SetLength(Map.EdgeLump, 0);

  Map.CountSurfEdges:=0;
  SetLength(Map.SurfEdgeLump, 0);

  Map.CountBrushModels:=0;
  SetLength(Map.ModelLump, 0);
  {$R+}
end;

function LoadBSP30FromFile(const FileName: String; const Map: PMapBSP): boolean;
var
  i, j: Integer;
  MapFile: File;
  tmpList: TStringList;
begin
  {$R-}
  FreeMapBSP(Map);

  LoadBSP30FromFile:=False;
  Map.LoadState:=erNoErrors;
  if not(FileExists(FileName)) then
    begin
      Map.LoadState:=erFileNotExists;
      Exit;
    end;

  AssignFile(MapFile, FileName);
  Reset(MapFile, 1);

  Map.MapFileSize:=FileSize(MapFile);
  if (Map.MapFileSize < MAP_HEADER_SIZE) then
    begin
      Map.LoadState:=erMinSize;
      CloseFile(MapFile);
      Exit;
    end;

  BlockRead(MapFile, Map.MapHeader, MAP_HEADER_SIZE);
  if (Map.MapHeader.nVersion <> MAP_VERSION) then
    begin
      Map.LoadState:=erBadVersion;
      CloseFile(MapFile);
      Exit;
    end;
  if (GetEOFbyHeader(Map.MapHeader) < Map.MapFileSize) then
    begin
      Map.LoadState:=erBadEOFbyHeader;
      CloseFile(MapFile);
      Exit;
    end;

  // Set Lump Sizes
  with Map^, MapHeader do
    begin
      SizeEndData:=           LumpsInfo[LUMP_ENTITIES].nLength;
      CountPlanes:=           LumpsInfo[LUMP_PLANES].nLength div SizeOf(tPlane);
      CountVertices:=         LumpsInfo[LUMP_VERTICES].nLength div SizeOf(tVertex);
      CountTexInfos:=         LumpsInfo[LUMP_TEXINFO].nLength div SizeOf(tTexInfo);
      CountFaces:=            LumpsInfo[LUMP_FACES].nLength div SizeOf(tFace);
      CountEdges:=            LumpsInfo[LUMP_EDGES].nLength div SizeOf(tEdge);
      CountSurfEdges:=        LumpsInfo[LUMP_SURFEDGES].nLength div SizeOf(tSurfEdge);
      CountBrushModels:=      LumpsInfo[LUMP_BRUSHES].nLength div SizeOf(tBrushModel);
    end;

  // Read EntData
  if (Map.SizeEndData > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_ENTITIES].nOffset);
      SetLength(Map.EntDataLump, Map.SizeEndData);
      BlockRead(MapFile, (@Map.EntDataLump[1])^, Map.SizeEndData);

      FixEntityStrEndToWin(Map.EntDataLump, Map.SizeEndData);
      tmpList:=SplitEntDataByRow(Map.EntDataLump, Map.SizeEndData);
      Map.CountEntities:=GetEntityList(tmpList, Map.Entities);
      if (tmpList <> nil) then
        begin
          tmpList.Clear;
          tmpList.Destroy;
        end;
    end
  else
    begin
      Map.LoadState:=erNoEntData;
      CloseFile(MapFile);
      Exit;
    end;

  // Read Planes
  if (Map.CountPlanes > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_PLANES].nOffset);
      SetLength(Map.PlaneLump, Map.CountPlanes);
      BlockRead(MapFile, (@Map.PlaneLump[0])^, Map.MapHeader.LumpsInfo[LUMP_PLANES].nLength);
    end
  else
    begin
      Map.LoadState:=erNoPlanes;
      CloseFile(MapFile);
      Exit;
    end;

  // Read Textures
  if (Map.MapHeader.LumpsInfo[LUMP_TEXTURES].nLength > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_TEXTURES].nOffset);
      BlockRead(MapFile, Map.TextureLump.nCountTextures, 4);

      SetLength(Map.TextureLump.OffsetsToMipTex, Map.TextureLump.nCountTextures);
      BlockRead(MapFile, (@Map.TextureLump.OffsetsToMipTex[0])^, Map.TextureLump.nCountTextures*4);

      // read MipTex
      SetLength(Map.TextureLump.MipTexInfos, Map.TextureLump.nCountTextures);
      SetLength(Map.TextureNames, Map.TextureLump.nCountTextures);
      j:=Map.MapHeader.LumpsInfo[LUMP_TEXTURES].nOffset;
      for i:=0 to Map.TextureLump.nCountTextures - 1 do
        begin
          Seek(MapFile, j + Map.TextureLump.OffsetsToMipTex[i]);
          BlockRead(MapFile, (@Map.TextureLump.MipTexInfos[i])^, SizeOf(tMipTex));
          Map.TextureNames[i]:=GetCorrectTextureName(Map.TextureLump.MipTexInfos[i]);
        end;
    end
  else
    begin
      Map.LoadState:=erNoTextures;
      CloseFile(MapFile);
      Exit;
    end;

  // Read Vertecies
  if (Map.CountVertices > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_VERTICES].nOffset);
      SetLength(Map.VertexLump, Map.CountVertices);
      BlockRead(MapFile, (@Map.VertexLump[0])^, Map.MapHeader.LumpsInfo[LUMP_VERTICES].nLength);
    end
  else
    begin
      Map.LoadState:=erNoVertex;
      CloseFile(MapFile);
      Exit;
    end;

  // Read TexInfos
  if (Map.CountTexInfos > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_TEXINFO].nOffset);
      SetLength(Map.TexInfoLump, Map.CountTexInfos);
      BlockRead(MapFile, (@Map.TexInfoLump[0])^, Map.MapHeader.LumpsInfo[LUMP_TEXINFO].nLength);
    end
  else
    begin
      Map.LoadState:=erNoTexInfos;
      CloseFile(MapFile);
      Exit;
    end;

  // Read Faces
  if (Map.CountFaces > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_FACES].nOffset);
      SetLength(Map.FaceLump, Map.CountFaces);
      BlockRead(MapFile, (@Map.FaceLump[0])^, Map.MapHeader.LumpsInfo[LUMP_FACES].nLength);
    end
  else
    begin
      Map.LoadState:=erNoFaces;
      CloseFile(MapFile);
      Exit;
    end;

  // Read Edges
  if (Map.CountEdges > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_EDGES].nOffset);
      SetLength(Map.EdgeLump, Map.CountEdges);
      BlockRead(MapFile, (@Map.EdgeLump[0])^, Map.MapHeader.LumpsInfo[LUMP_EDGES].nLength);
    end
  else
    begin
      Map.LoadState:=erNoEdge;
      CloseFile(MapFile);
      Exit;
    end;

  // Read SurfEdges
  if (Map.CountSurfEdges > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_SURFEDGES].nOffset);
      SetLength(Map.SurfEdgeLump, Map.CountSurfEdges);
      BlockRead(MapFile, (@Map.SurfEdgeLump[0])^, Map.MapHeader.LumpsInfo[LUMP_SURFEDGES].nLength);
    end
  else
    begin
      Map.LoadState:=erNoSurfEdge;
      CloseFile(MapFile);
      Exit;
    end;

  // Read Brush Models
  if (Map.CountBrushModels > 0) then
    begin
      Seek(MapFile, Map.MapHeader.LumpsInfo[LUMP_BRUSHES].nOffset);
      SetLength(Map.ModelLump, Map.CountBrushModels);
      BlockRead(MapFile, (@Map.ModelLump[0])^, Map.MapHeader.LumpsInfo[LUMP_BRUSHES].nLength);
    end
  else
    begin
      Map.LoadState:=erNoBrushes;
      CloseFile(MapFile);
      Exit;
    end;

  CloseFile(MapFile);
  LoadBSP30FromFile:=True;

  // Update Face Info
  SetLength(Map.FaceInfos, Map.CountFaces);
  for i:=0 to (Map.CountFaces - 1) do
    begin
      UpDateFaceInfo(Map, i);
    end;

  // Update Entity Brush geometry position by Origin
  for i:=0 to (Map.CountEntities - 1) do
    begin
      UpDateEntityInfo(Map, i);
    end;
  {$R+}
end;

function ShowLoadBSPMapError(const LoadMapErrorType: eLoadMapErrors): String;
begin
  {$R-}
  Result:='';
  case LoadMapErrorType of
    erNoErrors : Result:='No Errors in load Map File';
    erFileNotExists : Result:='Map File Not Exists';
    erMinSize : Result:='Map File have size less then size of Header';
    erBadVersion : Result:='Map File have bad BSP version';
    erBadEOFbyHeader : Result:='Size of Map File less then contained in Header';
    erNoEntData : Result:='Map File not have Entity lump';
    erNoTextures : Result:='Map File not have Texture lump';
    erNoPlanes : Result:='Map File not have Plane lump';
    erNoVertex : Result:='Map File not have Vertex lump';
    erNoTexInfos : Result:='Map File not have TexInfo lump';
    erNoFaces : Result:='Map File not have Face lump';
    erNoEdge : Result:='Map File not have Edge lump';
    erNoSurfEdge : Result:='Map File not have SurfEdge lump';
    erNoBrushes : Result:='Map File not have ModelBrush lump';
  end;
  {$R+}
end;

procedure UpdateFaceInfo(const Map: PMapBSP; const FaceId: Integer);
var
  lpFace: PFace;
  lpFaceInfo: PFaceInfo;
  lpTexInfo: PTexInfo;
  i, EdgeIndex, w, h: Integer;
begin
  {$R-}
  lpFace:=@Map.FaceLump[FaceId];
  lpFaceInfo:=@Map.FaceInfos[FaceId];
  lpTexInfo:=@Map.TexInfoLump[lpFace.iTextureInfo];

  lpFaceInfo.Normal:=Map.PlaneLump[lpFace.iPlane].vNormal;
  if (lpFace.nPlaneSides <> 0) then SignInvertVec(@lpFaceInfo.Normal);

  lpFaceInfo.CountVertex:=lpFace.nSurfEdges;
  SetLength(lpFaceInfo.Vertex, lpFaceInfo.CountVertex);
  SetLength(lpFaceInfo.TexCoords, lpFaceInfo.CountVertex);

  if (lpFaceInfo.CountVertex > Map.MaxCountVertexPerFace) then
    begin
      Map.MaxCountVertexPerFace:=lpFaceInfo.CountVertex;
    end;

  // Get Vertecies
  for i:=0 to (lpFace.nSurfEdges - 1) do
    begin
      EdgeIndex:=Map.SurfEdgeLump[lpFace.iFirstSurfEdge + i];
      if (EdgeIndex >= 0) then
        begin
          lpFaceInfo.Vertex[i]:=Map.VertexLump[Map.EdgeLump[EdgeIndex].v0];
        end
      else
        begin
          lpFaceInfo.Vertex[i]:=Map.VertexLump[Map.EdgeLump[-EdgeIndex].v1];
        end;
    end;

  // Get texture coordinates
  lpFaceInfo.TexNameId:=Map.TexInfoLump[lpFace.iTextureInfo].iMipTex;
  w:=Map.TextureLump.MipTexInfos[lpFaceInfo.TexNameId].nWidth;
  h:=Map.TextureLump.MipTexInfos[lpFaceInfo.TexNameId].nHeight;
  for i:=0 to (lpFaceInfo.CountVertex - 1) do
    begin
      lpFaceInfo.TexCoords[i].x:=GetTexureCoordS(@lpFaceInfo.Vertex[i], lpTexInfo)/w;
      lpFaceInfo.TexCoords[i].y:=GetTexureCoordT(@lpFaceInfo.Vertex[i], lpTexInfo)/h;
    end;
  {$R+}
end;

procedure UpDateEntityInfo(const Map: PMapBSP; const EntityId: Integer);
var
  lpEntity: PEntity;
  tmpStr: String;
  i, ModelId: Integer;
  Origin: tVec3f;
  //
  isHaveOrigin: Boolean;
  lpModel: PBrushModel;
begin
  {$R-}
  lpEntity:=@Map.Entities[EntityId];

  // Get Entity origin if exists
  tmpStr:='';
  Origin:=VEC_ZERO;
  isHaveOrigin:=False;
  for i:=0 to (lpEntity.CountPairs - 1) do
    begin
      if (lpEntity.Pairs[i].Key = KEY_ORIGIN) then
        begin
          tmpStr:=lpEntity.Pairs[i].Value;
          isHaveOrigin:=StrToVec(tmpStr, @Origin);
        end;
    end;

  // Update Brush Model id
  tmpStr:='';
  for i:=0 to (lpEntity.CountPairs - 1) do
    begin
      if (lpEntity.Pairs[i].Key = KEY_MODEL) then
        tmpStr:=lpEntity.Pairs[i].Value;
    end;
  if (tmpStr <> '') then
    if (tmpStr[1] = '*') then
      begin
        Delete(tmpStr, 1, 1);
        ModelId:=StrToIntDef(tmpStr, -1);

        if (ModelId > 0) then
          begin
            lpModel:=@Map.ModelLump[ModelId];

            if (isHaveOrigin) then
              begin
                for i:=lpModel.iFirstFace to (lpModel.nFaces + lpModel.iFirstFace - 1) do
                  begin
                    // Correct Faces vertecies of entity brush by entity origin
                    TranslateVertexArray(
                      @Map.FaceInfos[i].Vertex[0],
                      @Origin,
                      Map.FaceInfos[i].CountVertex
                    );
                  end;
              end;
          end;
      end;
  {$R+}
end;

end.
