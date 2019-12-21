unit tst_Apollo_DPM;

interface

uses
  Apollo_DPM_Engine,
  Apollo_DPM_GitHubAPI,
  DUnitX.TestFramework;

type
  [TestFixture]
  TestDPMEngine = class
  strict private
    FDPMEngine: TDPMEngine;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    //[TestCase('GetPublishedPackages', '')]
    procedure TestGetPublishedPackages;

    [TestCase('InstallPackage', 'Apollo_HTTP;1.0', ';')]
    procedure TestInstallPackage(const aPackageName, aPackageVersionName: string);
  end;

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

    //[TestCase('GetTextFileContent', 'apollo-delphi;apollo-dpm;/master/Published/packages.json;packages', ';')]
    procedure TestGetTextFileContent(const aOwner, aRepo, aPath, _Result: string);

    //[TestCase('TestGetRepoTags', 'apollo-delphi;apollo-http', ';')]
    procedure TestGetRepoTags(const aOwner, aRepo: string);

    //[TestCase('TestGetRepoTree', 'apollo-delphi;apollo-http;88f14a6e2b8071f983c934a37d02688a1912e43e', ';')]
    procedure TestGetRepoTree(const aOwner, aRepo, aSHA: string);
  end;

implementation

uses
  Apollo_DPM_Package;

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

procedure TestGHAPI.TestGetRepoTags(const aOwner, aRepo: string);
begin
  FGHAPI.GetRepoTags(aOwner, aRepo);
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

{ TestDPMEngine }

procedure TestDPMEngine.Setup;
begin
  FDPMEngine := TDPMEngine.Create(nil);
end;

procedure TestDPMEngine.TearDown;
begin
  FDPMEngine := nil;
end;

procedure TestDPMEngine.TestGetInstalledPackages;
begin

end;

procedure TestDPMEngine.TestGetPublishedPackages;
var
  PablishedPackages:  TPackageList;
begin
  PablishedPackages := FDPMEngine.GetPublishedPackages;
  try
    Assert.IsTrue(PablishedPackages.Count > 0);
  finally
    PablishedPackages.Free;
  end;
end;

procedure TestDPMEngine.TestInstallPackage(const aPackageName, aPackageVersionName: string);
var
  Package: TPackage;
  PackageList: TPackageList;
  TestPackage: TPackage;
begin
  PackageList := FDPMEngine.GetPublishedPackages;
  try
    TestPackage := nil;

    for Package in PackageList do
      if Package.Name = aPackageName then
        begin
          TestPackage := Package;
          Break;
        end;

    if Assigned(TestPackage) then
      begin
        FDPMEngine.GetPackageVersions(TestPackage);
        FDPMEngine.InstallPackage(aPackageVersionName, TestPackage);
      end;
  finally
    PackageList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TestGHAPI);
  TDUnitX.RegisterTestFixture(TestDPMEngine);

end.
