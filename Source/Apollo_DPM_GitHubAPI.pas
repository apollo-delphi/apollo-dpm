unit Apollo_DPM_GitHubAPI;

interface

uses
  Apollo_HTTP;

type
  TGHAPI = class
  private
    FHTTP: THTTP;
    function GetAPIHostBaseURL(const aRepoOwner, aRepoName: string): string;
  public
    function GetMasterBranchSHA(const aRepoOwner, aRepoName: string): string;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.JSON,
  System.SysUtils;

{ TGHAPI }

constructor TGHAPI.Create;
begin
  FHTTP := THTTP.Create;
end;

destructor TGHAPI.Destroy;
begin
  FHTTP.Free;

  inherited;
end;

function TGHAPI.GetAPIHostBaseURL(const aRepoOwner, aRepoName: string): string;
begin
  Result := Format('https://api.github.com/repos/%s/%s', [aRepoOwner, aRepoName]);
end;

function TGHAPI.GetMasterBranchSHA(const aRepoOwner, aRepoName: string): string;
var
  jsnObj: TJSONObject;
  sJSON: string;
  URL: string;
begin
  Result := '';

  URL := GetAPIHostBaseURL(aRepoOwner, aRepoName) + '/branches/master';
  sJSON := FHTTP.Get(URL);

  jsnObj := TJSONObject.ParseJSONValue(sJSON) as TJSONObject;
  try
    Result := (jsnObj.GetValue('commit') as TJSONObject).GetValue('sha').Value;
  finally
    jsnObj.Free;
  end;
end;

end.
