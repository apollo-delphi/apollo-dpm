unit tst_Apollo_DPM;

interface

uses
  Apollo_DPM_GitHubAPI,
  DUnitX.TestFramework;

type
  [TestFixture]
  TestGHAPI = class
  strict private
    FGHAPI: TGHAPI;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    //[TestCase('TestGetMasterBranchSHA', 'apollo-delphi;apollo-http', ';')]
    procedure TestGetMasterBranchSHA(const aOwner, aRepo: string);

    [TestCase('GetTextFileContent', 'apollo-delphi;apollo-dpm;/master/Public/PublicPackages.json;packages', ';')]
    procedure TestGetTextFileContent(const aOwner, aRepo, aPath, _Result: string);

    [TestCase('TestGetRepoTags', 'apollo-delphi;apollo-http;1.0', ';')]
    procedure TestGetRepoTags(const aOwner, aRepo, _OneOfTagName: string);

    //[TestCase('TestGetRepoTree', 'apollo-delphi;apollo-http;88f14a6e2b8071f983c934a37d02688a1912e43e', ';')]
    procedure TestGetRepoTree(const aOwner, aRepo, aSHA: string);
  end;

implementation

uses
  Apollo_DPM_Package,
  System.SysUtils;

{ TestGHAPI }

procedure TestGHAPI.Setup;
begin
  FGHAPI := TGHAPI.Create;
end;

procedure TestGHAPI.TearDown;
begin
  FGHAPI := nil;
end;

procedure TestGHAPI.TestGetMasterBranchSHA(const aOwner, aRepo: string);
var
  SHA: string;
begin
  SHA := FGHAPI.GetMasterBranchSHA(aOwner, aRepo);
end;

procedure TestGHAPI.TestGetRepoTags(const aOwner, aRepo, _OneOfTagName: string);
var
  CatchOneOfTagName: Boolean;
  Tag: TTag;
  Tags: TArray<TTag>;
begin
  Tags := FGHAPI.GetRepoTags(aOwner, aRepo);

  CatchOneOfTagName := False;
  for Tag in Tags do
  begin
    if Tag.SHA.IsEmpty or Tag.Name.IsEmpty then
      Assert.Fail('Empty tag name found');

    if Tag.Name = _OneOfTagName then
      CatchOneOfTagName := True;
  end;

  if CatchOneOfTagName then
    Assert.Pass
  else
    Assert.Fail('Did not catch tag name ' + _OneOfTagName);
end;

procedure TestGHAPI.TestGetRepoTree(const aOwner, aRepo, aSHA: string);
begin
  FGHAPI.GetRepoTree(aOwner, aRepo, aSHA);
end;

procedure TestGHAPI.TestGetTextFileContent(const aOwner, aRepo, aPath,
  _Result: string);
var
  sJSON: string;
begin
  sJSON := FGHAPI.GetTextFileContent(aOwner, aRepo, aPath);
  Assert.IsMatch(_Result, sJSON);
end;

initialization
  TDUnitX.RegisterTestFixture(TestGHAPI);

end.
