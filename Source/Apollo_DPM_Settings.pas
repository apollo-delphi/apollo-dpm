unit Apollo_DPM_Settings;

interface

type
  TSettings = class
  private
    FGHPAToken: string;
  public
    function GetJSONString: string;
    constructor Create; overload;
    constructor Create(const aJSONString: string); overload;
    property GHPAToken: string read FGHPAToken write FGHPAToken;
  end;

implementation

uses
  Apollo_DPM_Consts,
  System.JSON;

{ TSettings }

constructor TSettings.Create(const aJSONString: string);
var
  jsnObj: TJSONObject;
begin
  jsnObj := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
  try
    GHPAToken := jsnObj.GetValue(cKeyGHPAToken).Value;
  finally
    jsnObj.Free;
  end;
end;

function TSettings.GetJSONString: string;
var
  jsnObj: TJSONObject;
begin
  jsnObj := TJSONObject.Create;
  try
    jsnObj.AddPair(cKeyGHPAToken, GHPAToken);

    Result := jsnObj.ToJSON;
  finally
    jsnObj.Free;
  end;
end;

constructor TSettings.Create;
begin
  inherited Create;
end;

end.
