unit Apollo_DPM_GitHubAPI;

interface

uses
  Apollo_HTTP;

type
  TTag = record
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
  public
    Content: string;
    Encoding: string;
    URL: string;
    procedure Init;
  end;

  TGHAPI = class
  private
    FHTTP: THTTP;
    function GetAPIHostBasePath(const aOwner, aRepo: string): string;
  public
    function GetMasterBranchSHA(const aOwner, aRepo: string): string;
    function GetRepoBlob(const aURL: string): TBlob;
    function GetRepoTags(const aOwner, aRepo: string): TArray<TTag>;
    function GetRepoTree(const aOwner, aRepo, aSHA: string): TTree;
    function GetTextFileContent(const aOwner, aRepo, aPath: string): string;
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

function TGHAPI.GetAPIHostBasePath(const aOwner, aRepo: string): string;
begin
  Result := Format('https://api.github.com/repos/%s/%s', [aOwner, aRepo]);
end;

function TGHAPI.GetMasterBranchSHA(const aOwner, aRepo: string): string;
var
  jsnObj: TJSONObject;
  sJSON: string;
  URL: string;
begin
  URL := GetAPIHostBasePath(aOwner, aRepo) + '/branches/master';
  sJSON := FHTTP.Get(URL);

  jsnObj := TJSONObject.ParseJSONValue(sJSON) as TJSONObject;
  try
    Result := (jsnObj.GetValue('commit') as TJSONObject).GetValue('sha').Value;
  finally
    jsnObj.Free;
  end;
end;

function TGHAPI.GetRepoBlob(const aURL: string): TBlob;
var
  jsnObj: TJSONObject;
  sJSON: string;
begin
  Result.Init;

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

function TGHAPI.GetRepoTags(const aOwner, aRepo: string): TArray<TTag>;
var
  jsnArr: TJSONArray;
  jsnObj: TJSONObject;
  jsnVal: TJSONValue;
  sJSON: string;
  Tag: TTag;
  URL: string;
begin
  Result := [];

  URL := GetAPIHostBasePath(aOwner, aRepo) + '/tags';
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

function TGHAPI.GetRepoTree(const aOwner, aRepo, aSHA: string): TTree;
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

  URL := Format(GetAPIHostBasePath(aOwner, aRepo) + '/git/trees/%s?recursive=1', [aSHA]);
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

function TGHAPI.GetTextFileContent(const aOwner, aRepo, aPath: string): string;
var
  URL: string;
begin
  URL := Format('https://raw.githubusercontent.com/%s/%s%s', [aOwner, aRepo, aPath]);
  Result := FHTTP.Get(URL);
end;

{ TBlob }

procedure TBlob.Init;
begin
  Content := '';
  Encoding := '';
  URL := '';
end;

end.
