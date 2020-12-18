unit Apollo_DPM_Filter;

interface

type
  TFilterListType = (fltBlack, fltWhite);

  TMove = record
    Destination: string;
    Source: string;
  end;

  TFilter = class
  private
    FFilterList: TArray<string>;
    FFilterListType: TFilterListType;
    FMoves: TArray<TMove>;
  end;

implementation

end.
