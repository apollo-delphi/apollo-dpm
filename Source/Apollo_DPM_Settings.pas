unit Apollo_DPM_Settings;

interface

type
  TSettings = class
  private
    FGHPAToken: string;
    FShowIndirectPackages: Boolean;
  public
    function GetJSONString: string;
    procedure SetJSON(const aJSONString: string);
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    property GHPAToken: string read FGHPAToken write FGHPAToken;
    property ShowIndirectPackages: Boolean read FShowIndirectPackages write FShowIndirectPackages;
  end;

implementation

uses
  Apollo_DPM_Consts,
  System.JSON;

{ TSettings }

constructor TSettings.Create(const aJSONString: string);
begin
  SetJSON(aJSONString);
end;

function TSettings.GetJSONString: string;
var
  jsnObj: TJSONObject;
begin
  jsnObj := TJSONObject.Create;
  try
    jsnObj.AddPair(cKeyGHPAToken, GHPAToken);
    jsnObj.AddPair(cKeyShowIndirectPkgs, TJSONBool.Create(FShowIndirectPackages));

    Result := jsnObj.ToJSON;
  finally
    jsnObj.Free;
  end;
end;

procedure TSettings.SetJSON(const aJSONString: string);
var
  bVal: Boolean;
  jsnObj: TJSONObject;
begin
  jsnObj := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
  try
    GHPAToken := jsnObj.GetValue(cKeyGHPAToken).Value;
    if jsnObj.TryGetValue<Boolean>(cKeyShowIndirectPkgs, bVal) then
      FShowIndirectPackages := bVal;
  finally
    jsnObj.Free;
  end;
end;

constructor TSettings.Create;
begin
  inherited Create;
end;

end.
