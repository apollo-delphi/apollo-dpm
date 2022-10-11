unit Apollo_DPM_GitHubAPI;

interface

uses
  Apollo_HTTP;

type
  TTag = record
    Date: TDateTime;
    Name: string;
    SHA: string;
  end;

  TTreeNode = record
    FileType: string;
    Path: string;
    URL: string;
  end;

  TTree = TArray<TTreeNode>;

  TBlob = record
    Content: string;
    Encoding: string;
    URL: string;
  end;

  TGHAPI = class
  private
    FHTTP: THTTP;
    function GetAPIHostBaseURL(const aRepoOwner, aRepoName: string): string;
  public
    function GetMasterBranch(const aRepoOwner, aRepoName: string): TTag;
    function GetRepoBlob(const aURL: string): TBlob;
    function GetRepoTags(const aRepoOwner, aRepoName: string): TArray<TTag>;
    function GetRepoTree(const aRepoOwner, aRepoName, aSHA: string): TTree;
    procedure SetGHPAToken(const aToken: string);
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

function TGHAPI.GetMasterBranch(const aRepoOwner, aRepoName: string): TTag;
var
  jsnObj: TJSONObject;
  sJSON: string;
  URL: string;
begin
  URL := GetAPIHostBaseURL(aRepoOwner, aRepoName) + '/branches/master';
  sJSON := FHTTP.Get(URL);

  jsnObj := TJSONObject.ParseJSONValue(sJSON) as TJSONObject;
  try
    Result.SHA := jsnObj.FindValue('commit.sha').Value;
    Result.Date := jsnObj.FindValue('commit.commit.committer.date').AsType<TDateTime>;
    Result.Name := '';
  finally
    jsnObj.Free;
  end;
end;

function TGHAPI.GetRepoBlob(const aURL: string): TBlob;
var
  jsnObj: TJSONObject;
  sJSON: string;
begin
  sJSON := FHTTP.Get(aURL);

  jsnObj := TJSONObject.ParseJSONValue(sJSON) as TJSONObject;
  try
    Result.URL := jsnObj.GetValue('url').Value;
    Result.Content := jsnObj.GetValue('content').Value;
    Result.Encoding := jsnObj.GetValue('encoding').Value;
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
      Tag.Date := 0;

      Result := Result + [Tag];
    end;
  finally
    jsnArr.Free;
  end;
end;

function TGHAPI.GetRepoTree(const aRepoOwner, aRepoName, aSHA: string): TTree;
var
  jsnObj: TJSONObject;
  jsnTree: TJSONArray;
  jsnTreeNode: TJSONObject;
  jsnVal: TJSONValue;
  sJSON: string;
  TreeNode: TTreeNode;
  URL: string;
begin
  Result := [];

  URL := Format(GetAPIHostBaseURL(aRepoOwner, aRepoName) + '/git/trees/%s?recursive=1', [aSHA]);
  sJSON := FHTTP.Get(URL);

  jsnObj := TJSONObject.ParseJSONValue(sJSON) as TJSONObject;
  try
    jsnTree := jsnObj.GetValue('tree') as TJSONArray;
    for jsnVal in jsnTree do
    begin
      jsnTreeNode := jsnVal as TJSONObject;

      TreeNode.FileType := jsnTreeNode.GetValue('type').Value;
      TreeNode.Path := jsnTreeNode.GetValue('path').Value;
      TreeNode.URL := jsnTreeNode.GetValue('url').Value;

      Result := Result + [TreeNode];
    end;
  finally
    jsnObj.Free;
  end;
end;

procedure TGHAPI.SetGHPAToken(const aToken: string);
begin
  FHTTP.SetCustomHeader('Authorization', Format(' token %s', [aToken]));
end;

end.
