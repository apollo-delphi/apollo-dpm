unit Apollo_DPM_GitHubAPI;

interface

uses
  Apollo_HTTP;

type
  TTag = record
    Name: string;
    SHA: string;
  end;

  TGHAPI = class
  private
    FHTTP: THTTP;
    function GetAPIHostBaseURL(const aRepoOwner, aRepoName: string): string;
  public
    function GetMasterBranchSHA(const aRepoOwner, aRepoName: string): string;
    function GetRepoTags(const aRepoOwner, aRepoName: string): TArray<TTag>;
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

function TGHAPI.GetRepoTags(const aRepoOwner, aRepoName: string): TArray<TTag>;
var
  jsnArr: TJSONArray;
  jsnObj: TJSONObject;
  jsnVal: TJSONValue;
  sJSON: string;
  Tag: TTag;
  URL: string;
begin
  Result := [];

  URL := GetAPIHostBaseURL(aRepoOwner, aRepoName) + '/tags';
  sJSON := FHTTP.Get(URL);

  jsnArr := TJSONObject.ParseJSONValue(sJSON) as TJSONArray;
  try
    for jsnVal in jsnArr do
    begin
      jsnObj := jsnVal as TJSONObject;

      Tag.Name := jsnObj.GetValue('name').Value;
      Tag.SHA := (jsnObj.GetValue('commit') as TJSONObject).GetValue('sha').Value;

      Result := Result + [Tag];
    end;
  finally
    jsnArr.Free;
  end;
end;

end.
