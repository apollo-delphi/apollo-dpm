unit Apollo_DPM_Adjustment;

interface

uses
  System.JSON;

type
  TFilterListType = (fltNone, fltBlack, fltWhite);

  TPathMove = record
    Destination: string;
    Source: string;
  end;

  TAdjustment = class
  private
    FFilterList: TArray<string>;
    FFilterListType: TFilterListType;
    FPathMoves: TArray<TPathMove>;
    procedure Init;
  public
    function GetJSON: TJSONObject;
    procedure SetJSON(aJSONObj: TJSONObject);
    constructor Create;
    property FilterList: TArray<string> read FFilterList write FFilterList;
    property FilterListType: TFilterListType read FFilterListType write FFilterListType;
    property PathMoves: TArray<TPathMove> read FPathMoves write FPathMoves;
  end;

implementation

const
  cKeyFilterListType = 'filterListType';
  cKeyFilterList = 'filterList';
  cKeyPathMoves = 'pathMoves';
  cKeySource = 'source';
  cKeyDestination = 'destination';

{ TAdjustment }

constructor TAdjustment.Create;
begin
  Init;
end;

function TAdjustment.GetJSON: TJSONObject;
var
  FilterListItem: string;
  PathMove: TPathMove;
  jsnFilterList: TJSONArray;
  jsnPathMove: TJSONObject;
  jsnPathMoves: TJSONArray;
begin
  Result := TJSONObject.Create;

  Result.AddPair(cKeyFilterListType, TJSONNumber.Create(Ord(FilterListType)));

  if Length(FilterList) > 0 then
  begin
    jsnFilterList := TJSONArray.Create;

    for FilterListItem in FilterList do
      jsnFilterList.Add(FilterListItem);

    Result.AddPair(cKeyFilterList, jsnFilterList);
  end;

  if Length(FPathMoves) > 0 then
  begin
    jsnPathMoves := TJSONArray.Create;

    for PathMove in PathMoves do
    begin
      jsnPathMove := TJSONObject.Create;
      jsnPathMove.AddPair(cKeySource, PathMove.Source);
      jsnPathMove.AddPair(cKeyDestination, PathMove.Destination);

      jsnPathMoves.Add(jsnPathMove);
    end;

    Result.AddPair(cKeyPathMoves, jsnPathMoves);
  end;
end;

procedure TAdjustment.Init;
begin
  FFilterListType := fltBlack;

  FFilterList := [
    '.gitignore',
    'README.md'
  ];
end;

procedure TAdjustment.SetJSON(aJSONObj: TJSONObject);
var
  iFilterListType: Integer;
  jsnFilterList: TJSONArray;
  jsnPathMoves: TJSONArray;
  jsnVal: TJSONValue;
  PathMove: TPathMove;
begin
  if aJSONObj.TryGetValue<Integer>(cKeyFilterListType, iFilterListType) then
    FilterListType := TFilterListType(iFilterListType);

  FilterList := [];
  if aJSONObj.TryGetValue(cKeyFilterList, jsnFilterList) then
    for jsnVal in jsnFilterList do
      FilterList := FilterList + [jsnVal.Value];

  PathMoves := [];
  if aJSONObj.TryGetValue(cKeyPathMoves, jsnPathMoves) then
    for jsnVal in jsnPathMoves do
    begin
      PathMove.Source := (jsnVal as TJSONObject).GetValue(cKeySource).Value;
      PathMove.Destination := (jsnVal as TJSONObject).GetValue(cKeyDestination).Value;

      PathMoves := PathMoves + [PathMove];
    end;
end;

end.
