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
  end;

implementation

const
  cKeyFilterListType = 'filterListType';
  cKeyFilterList = 'filterList';

{ TAdjustment }

constructor TAdjustment.Create;
begin
  Init;
end;

function TAdjustment.GetJSON: TJSONObject;
var
  FilterListItem: string;
  jsnFilterList: TJSONArray;
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
  jsnVal: TJSONValue;
begin
  if aJSONObj.TryGetValue<Integer>(cKeyFilterListType, iFilterListType) then
    FilterListType := TFilterListType(iFilterListType);

  FilterList := [];
  if aJSONObj.TryGetValue(cKeyFilterList, jsnFilterList) then
    for jsnVal in jsnFilterList do
      FilterList := FilterList + [jsnVal.Value];
end;

end.
