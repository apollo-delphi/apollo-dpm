unit Apollo_DPM_Test;

interface

uses
  Apollo_DPM_Engine;

type
  ITest = interface
  ['{029DBA8F-B8CD-4CDB-83B6-532588499196}']
    function GetDescription: string;
    function GetError: string;
    function GetPassed: Boolean;
    procedure Run;
    property Error: string read GetError;
    property Passed: Boolean read GetPassed;
  end;

function GetTests(aDPMEngine: TDPMEngine): TArray<ITest>;

implementation

uses
  Apollo_DPM_Package,
  Apollo_DPM_Version,
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  ToolsAPI;

type
  ITestImpl = interface
  ['{811F30EC-DF80-4EB2-884D-68D7A4A70814}']
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestCommon = class abstract(TInterfacedObject, ITest)
  private
    FDPMEngine: TDPMEngine;
    FPassed: Boolean;
    FTestImpl: ITestImpl;
    FError: TStrings;
    function BoolToStr(const aBool: Boolean): string;
    function CreateTestPackage(const aPackageFileName: string): TPrivatePackage;
    function GetTestCasesPath: string;
  protected
    function GetDescription: string;
    function GetError: string;
    function GetPassed: Boolean;
    function GetIDEPackage(const aPackageName: string): TDependentPackage;
    function GetProjectPackage(const aPackageName: string): TDependentPackage;
    procedure AssertBoolean(const aActual, aExpected: Boolean);
    procedure AssertBplInstalled(const aPath: string);
    procedure AssertBplNotInstalled(const aPath: string);
    procedure AssertDirExists(const aPath: string);
    procedure AssertDirNotExists(const aPath: string);
    procedure AssertFileExists(const aPath: string);
    procedure AssertFileNotExists(const aPath: string);
    procedure AssertInteger(const aActual, aExpected: Integer);
    procedure AssertNil(aObject: TObject; const aObjName: string);
    procedure AssertObject(aObject: TObject; const aObjName: string);
    procedure AssertString(const aActual, aExpected: string);
    procedure ClearTestProject; virtual;
    procedure Run;
  public
    constructor Create(aDPMEngine: TDPMEngine);
    destructor Destroy; override;
  end;

  TTestInstallCodeSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUninstallCodeSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUpdateCodeSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestInstallBplSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure ClearTestProject; override;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUnistallBplSource = class(TTestCommon, ITestImpl)
  private
    FBplPath: string;
    FPackageDir: string;
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure ClearTestProject; override;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUpdateBplSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure ClearTestProject; override;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestInstallBplBinary = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure ClearTestProject; override;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUninstallBplBinary = class(TTestCommon, ITestImpl)
  private
    FBplPath: string;
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure ClearTestProject; override;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUpdateBplBinary = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageFileName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure ClearTestProject; override;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  EWrongStep = class(Exception)
  public
    constructor Create;
  end;

function GetTests(aDPMEngine: TDPMEngine): TArray<ITest>;
begin
  Result := [
    TTestInstallCodeSource.Create(aDPMEngine),
    TTestUpdateCodeSource.Create(aDPMEngine),
    TTestUninstallCodeSource.Create(aDPMEngine),
    TTestInstallBplSource.Create(aDPMEngine),
    TTestUpdateBplSource.Create(aDPMEngine),
    TTestUnistallBplSource.Create(aDPMEngine),
    TTestInstallBplBinary.Create(aDPMEngine),
    TTestUpdateBplBinary.Create(aDPMEngine),
    TTestUninstallBplBinary.Create(aDPMEngine)
  ];
end;

{ TTestInstallCodeSource }

procedure TTestInstallCodeSource.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Apollo_ORM');
  AssertObject(Package, 'Apollo_ORM');
  AssertObject(Package.Version, 'Apollo_ORM.Version');
  AssertInteger(Length(Package.Version.Dependencies), 3);
  AssertBoolean(Package.IsDirect, True);

  Package := GetProjectPackage('Apollo_DB_Core');
  AssertObject(Package, 'Apollo_DB_Core');
  AssertBoolean(Package.IsDirect, False);

  Package := GetProjectPackage('Apollo_Helpers');
  AssertObject(Package, 'Apollo_Helpers');
  AssertBoolean(Package.IsDirect, False);

  Package := GetProjectPackage('Apollo_Types');
  AssertObject(Package, 'Apollo_Types');
  AssertBoolean(Package.IsDirect, False);

  Package := GetProjectPackage('Apollo_DB_SQLite');
  AssertObject(Package, 'Apollo_DB_SQLite');
  AssertBoolean(Package.IsDirect, True);
end;

procedure TTestInstallCodeSource.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  FDPMEngine.Action_Install(aPackage, aVersion);
end;

function TTestInstallCodeSource.GetDescription: string;
begin
  Result := 'Install Code Source Package';
end;

function TTestInstallCodeSource.GetStepCount: Integer;
begin
  Result := 2;
end;

function TTestInstallCodeSource.GetTestPackageFileName(const aStep: Integer): string;
begin
  case aStep of
    1: Result := 'Apollo_DB_SQLite.json';
    2: Result := 'Apollo_ORM.json';
  else
    raise EWrongStep.Create;
  end;
end;

function TTestInstallCodeSource.GetVersion(const aStep: Integer): TVersion;
begin
  case aStep of
    1:begin
        Result := TVersion.Create;
        Result.SHA := '60f92556444c29145ff1c0446d908d8978c32d24';
      end;
    2: Result := TVersion.CreateAsLatestVersionOption;
  else
    raise EWrongStep.Create;
  end;
end;

{ TTestCommon }

procedure TTestCommon.Run;
var
  DPMProject: IOTAProject;
  i: Integer;
  NeedToFreeVersion: Boolean;
  TestPackage: TPrivatePackage;
  TestProject: IOTAProject;
  Version: TVersion;
begin
  TestProject := FDPMEngine.Project_GetTest;
  FDPMEngine.Project_SetActive(TestProject);
  ClearTestProject;

  try
    FPassed := True;
    FError.Clear;

    for i := 1 to FTestImpl.GetStepCount do
    begin
      TestPackage := CreateTestPackage(FTestImpl.GetTestPackageFileName(i));
      Version := FTestImpl.GetVersion(i);
      NeedToFreeVersion := False;
      try
        if Assigned(Version) and not Version.SHA.IsEmpty then
          Version := FDPMEngine.Versions_SyncCache(TestPackage.ID, Version)
        else
          NeedToFreeVersion := True;

        FTestImpl.DoAction(TestPackage, Version, i);
      finally
        TestPackage.Free;

        if Assigned(Version) and NeedToFreeVersion then
          Version.Free;
      end;
    end;

    FTestImpl.Asserts;
  except
    on E: Exception do
    begin
      FPassed := False;
      FError.Add(E.Message);
    end;
  end;

  DPMProject := FDPMEngine.Project_GetDPM;
  FDPMEngine.Project_SetActive(DPMProject);
end;

function TTestCommon.GetDescription: string;
begin
  Result := FTestImpl.GetDescription;
end;

function TTestCommon.GetError: string;
begin
  Result := FError.CommaText;
end;

function TTestCommon.GetIDEPackage(
  const aPackageName: string): TDependentPackage;
var
  ProjectPackage: TDependentPackage;
begin
  Result := nil;

  for ProjectPackage in FDPMEngine.Packages_GetIDE do
    if ProjectPackage.Name = aPackageName then
    begin
      if Assigned(Result) then
        raise Exception.Create('TTestCommon.GetIDEPackage: more than one package found')
      else
        Result := ProjectPackage;
    end;
end;

function TTestCommon.GetPassed: Boolean;
begin
  Result := FPassed;
end;

function TTestCommon.GetProjectPackage(
  const aPackageName: string): TDependentPackage;
var
  ProjectPackage: TDependentPackage;
begin
  Result := nil;

  for ProjectPackage in FDPMEngine.Packages_GetProject do
    if ProjectPackage.Name = aPackageName then
    begin
      if Assigned(Result) then
        raise Exception.Create('TTestCommon.GetProjectPackage: more than one package found')
      else
        Result := ProjectPackage;
    end;
end;

procedure TTestCommon.AssertBoolean(const aActual, aExpected: Boolean);
begin
  if aActual <> aExpected then
  begin
    FPassed := False;
    FError.Add(Format('AssertBoolean: Actual=%s Expected=%s', [BoolToStr(aActual), BoolToStr(aExpected)]));
  end;
end;

procedure TTestCommon.AssertBplInstalled(const aPath: string);
begin
  if not FDPMEngine.Bpl_IsInstalled(aPath) then
  begin
    FPassed := False;
    FError.Add(Format('AssertBplInstalled: %s', [aPath]));
  end;
end;

procedure TTestCommon.AssertBplNotInstalled(const aPath: string);
begin
  if FDPMEngine.Bpl_IsInstalled(aPath) then
  begin
    FPassed := False;
    FError.Add(Format('AssertBplNotInstalled: %s', [aPath]));
  end;
end;

procedure TTestCommon.AssertDirExists(const aPath: string);
begin
  if not FDPMEngine.Directory_Exists(aPath) then
  begin
    FPassed := False;
    FError.Add(Format('AssertDirExists: %s', [aPath]));
  end;
end;

procedure TTestCommon.AssertDirNotExists(const aPath: string);
begin
  if FDPMEngine.Directory_Exists(aPath) then
  begin
    FPassed := False;
    FError.Add(Format('AssertDirNotExists: %s', [aPath]));
  end;
end;

procedure TTestCommon.AssertFileExists(const aPath: string);
begin
  if not FDPMEngine.File_Exists(aPath) then
  begin
    FPassed := False;
    FError.Add(Format('AssertFileExists: %s', [aPath]));
  end;
end;

procedure TTestCommon.AssertFileNotExists(const aPath: string);
begin
  if FDPMEngine.File_Exists(aPath) then
  begin
    FPassed := False;
    FError.Add(Format('AssertFileNotExists: %s', [aPath]));
  end;
end;

procedure TTestCommon.AssertInteger(const aActual, aExpected: Integer);
begin
  if aActual <> aExpected then
  begin
    FPassed := False;
    FError.Add(Format('AssertInteger: Actual=%d Expected=%d', [aActual, aExpected]));
  end;
end;

procedure TTestCommon.AssertNil(aObject: TObject; const aObjName: string);
begin
  if aObject <> nil then
  begin
    FPassed := False;
    FError.Add(Format('AssertNil %s is not nil', [aObjName]));
  end;
end;

procedure TTestCommon.AssertObject(aObject: TObject; const aObjName: string);
begin
  if not Assigned(aObject) then
  begin
    FPassed := False;
    FError.Add(Format('AssertObject %s not assigned', [aObjName]));
  end;
end;

procedure TTestCommon.AssertString(const aActual, aExpected: string);
begin
  if aActual <> aExpected then
  begin
    FPassed := False;
    FError.Add(Format('AssertString: Actual=%s Expected=%s', [aActual, aExpected]));
  end;
end;

function TTestCommon.BoolToStr(const aBool: Boolean): string;
begin
  if aBool then
    Result := 'True'
  else
    Result := 'False';
end;

procedure TTestCommon.ClearTestProject;
var
  FileItem: string;
  Files: TArray<string>;
  ProjectPackagesPath: string;
  VendorsPath: string;
begin
  VendorsPath := FDPMEngine.Path_GetVendors(ptCodeSource);
  if TDirectory.Exists(VendorsPath) then
  begin
    Files := FDPMEngine.Files_Get(VendorsPath, '*.pas');
    for FileItem in Files do
      if FDPMEngine.ProjectActive_Contains(FileItem) then
        FDPMEngine.ProjectActive_RemoveFile(FileItem);

    TDirectory.Delete(VendorsPath, True);
  end;

  ProjectPackagesPath := FDPMEngine.Path_GetProjectPackages;
  if TFile.Exists(ProjectPackagesPath) then
    TFile.Delete(ProjectPackagesPath);
end;

constructor TTestCommon.Create(aDPMEngine: TDPMEngine);
begin
  FDPMEngine := aDPMEngine;
  FDPMEngine.TestMode := True;
  FError := TStringList.Create;
  GetInterface(ITestImpl, FTestImpl);
end;

function TTestCommon.CreateTestPackage(
  const aPackageFileName: string): TPrivatePackage;
var
  DependentPackage: TDependentPackage;
  TestPackageFilePath: string;
begin
  TestPackageFilePath := TPath.Combine(GetTestCasesPath, aPackageFileName);

  Result := TPrivatePackage.Create(FDPMEngine.File_GetText(TestPackageFilePath));

  DependentPackage := GetProjectPackage(Result.Name);
  if Assigned(DependentPackage) then
    Result.DependentPackage := DependentPackage;
end;

destructor TTestCommon.Destroy;
begin
  FError.Free;
  FDPMEngine.TestMode := False;

  inherited;
end;

function TTestCommon.GetTestCasesPath: string;
begin
  Result := FDPMEngine.Path_GetActiveProject;
  Result := TDirectory.GetParent(Result);
  Result := TDirectory.GetParent(Result);
  Result := TPath.Combine(Result, 'TestCases');
end;

{ TTestUninstallCodeSource }

procedure TTestUninstallCodeSource.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Apollo_ORM');
  AssertNil(Package, 'Apollo_ORM');

  Package := GetProjectPackage('Apollo_DB_Core');
  AssertObject(Package, 'Apollo_DB_Core');
  AssertBoolean(Package.IsDirect, False);

  Package := GetProjectPackage('Apollo_Helpers');
  AssertObject(Package, 'Apollo_Helpers');
  AssertBoolean(Package.IsDirect, False);

  Package := GetProjectPackage('Apollo_Types');
  AssertNil(Package, 'Apollo_Types');
end;

procedure TTestUninstallCodeSource.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
var
  DependentPackage: TDependentPackage;
begin
  case aStep of
    1: FDPMEngine.Action_Install(aPackage, aVersion);
    2:begin
        FDPMEngine.Action_Install(aPackage, aVersion);
        DependentPackage := GetProjectPackage(aPackage.Name);
        FDPMEngine.Action_Uninstall(DependentPackage);
      end;
  end;
end;

function TTestUninstallCodeSource.GetDescription: string;
begin
  Result := 'Uninstall Code Source Package';
end;

function TTestUninstallCodeSource.GetStepCount: Integer;
begin
  Result := 2;
end;

function TTestUninstallCodeSource.GetTestPackageFileName(const aStep: Integer): string;
begin
  case aStep of
    1: Result := 'Apollo_DB_SQLite.json';
    2: Result := 'Apollo_ORM.json';
  else
    raise EWrongStep.Create
  end;
end;

function TTestUninstallCodeSource.GetVersion(const aStep: Integer): TVersion;
begin
  case aStep of
    1: Result := TVersion.CreateAsLatestVersionOption;
    2: Result := TVersion.CreateAsLatestVersionOption;
  else
    raise EWrongStep.Create
  end;
end;

{ TestUpdateCodeSource }

procedure TTestUpdateCodeSource.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Apollo_Types');
  AssertNil(Package, 'Apollo_Types');

  Package := GetProjectPackage('Apollo_Helpers');
  AssertObject(Package, 'Apollo_Helpers');
  AssertBoolean(Package.IsDirect, True);
  AssertObject(Package.Version, 'Apollo_Helpers.Version');
  AssertString(Package.Version.SHA, 'aa939bfda490f602831819138840103fc9ee458b');
end;

procedure TTestUpdateCodeSource.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  case aStep of
    1:  FDPMEngine.Action_Install(aPackage, aVersion);
    2:  FDPMEngine.Action_Update(aPackage, aVersion);
  else
    raise EWrongStep.Create
  end;
end;

function TTestUpdateCodeSource.GetDescription: string;
begin
  Result := 'Update Code Source Package';
end;

function TTestUpdateCodeSource.GetStepCount: Integer;
begin
  Result := 2;
end;

function TTestUpdateCodeSource.GetTestPackageFileName(const aStep: Integer): string;
begin
  case aStep of
    1:  Result := 'Apollo_Helpers.json';
    2:  Result := 'Apollo_Helpers.json';
  else
    raise EWrongStep.Create
  end;
end;

function TTestUpdateCodeSource.GetVersion(const aStep: Integer): TVersion;
begin
  case aStep of
    1:
    begin
      Result := TVersion.Create;
      Result.SHA := '20683959f32e24062f227cec7f2d2d1776fb3d55';
    end;
    2:
    begin
      Result := TVersion.Create;
      Result.SHA := 'aa939bfda490f602831819138840103fc9ee458b';
    end;
  else
    raise EWrongStep.Create
  end;
end;

{ EWrongStep }

constructor EWrongStep.Create;
begin
  inherited Create('Wrong step');
end;

{ TTestInstallBplSource }

procedure TTestInstallBplSource.Asserts;
var
  BplPath: string;
  Package: TDependentPackage;
begin
  Package := GetIDEPackage('Test_Thunderbird_Tree');
  AssertObject(Package, 'Test_Thunderbird_Tree');
  AssertBoolean(Package.IsDirect, True);
  AssertDirExists(FDPMEngine.Path_GetPackage(Package));

  BplPath := '';
  if (Length(Package.BplFileRefs) > 0) then
    BplPath := Package.BplFileRefs[0];
  AssertBoolean(BplPath.EndsWith('\Bpl\thunderbirdTree.bpl'), True);
  AssertFileExists(BplPath);

  AssertBplInstalled(BplPath);
end;

procedure TTestInstallBplSource.ClearTestProject;
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := GetIDEPackage('Test_Thunderbird_Tree');
  if Assigned(DependentPackage) then
    FDPMEngine.Action_Uninstall(DependentPackage);
end;

procedure TTestInstallBplSource.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  FDPMEngine.Action_Install(aPackage, aVersion);
end;

function TTestInstallBplSource.GetDescription: string;
begin
  Result := 'Install Bpl Source Package';
end;

function TTestInstallBplSource.GetStepCount: Integer;
begin
  Result := 1;
end;

function TTestInstallBplSource.GetTestPackageFileName(const aStep: Integer): string;
begin
  Result := 'Test_Thunderbird_Tree.json';
end;

function TTestInstallBplSource.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.CreateAsLatestVersionOption;
end;

{ TTestUnistallBplSource }

procedure TTestUnistallBplSource.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Test_Thunderbird_Tree');
  AssertNil(Package, 'Test_Thunderbird_Tree');

  Package := GetIDEPackage('Test_Thunderbird_Tree');
  AssertNil(Package, 'Test_Thunderbird_Tree');

  AssertDirNotExists(FPackageDir);
  AssertFileNotExists(FBplPath);
  AssertBplNotInstalled(FBplPath);

  AssertFileNotExists(FDPMEngine.Path_GetProjectPackages);
end;

procedure TTestUnistallBplSource.ClearTestProject;
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := GetIDEPackage('Test_Thunderbird_Tree');
  if Assigned(DependentPackage) then
    FDPMEngine.Action_Uninstall(DependentPackage);
end;

procedure TTestUnistallBplSource.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
var
  DependentPackage: TDependentPackage;
begin
  FDPMEngine.Action_Install(aPackage, aVersion);
  DependentPackage := GetIDEPackage('Test_Thunderbird_Tree');

  FBplPath := DependentPackage.BplFileRefs[0];
  FPackageDir := FDPMEngine.Path_GetPackage(DependentPackage);

  FDPMEngine.Action_Uninstall(DependentPackage);
end;

function TTestUnistallBplSource.GetDescription: string;
begin
  Result := 'Uninstall Bpl Source Package';
end;

function TTestUnistallBplSource.GetStepCount: Integer;
begin
  Result := 1;
end;

function TTestUnistallBplSource.GetTestPackageFileName(
  const aStep: Integer): string;
begin
  Result := 'Test_Thunderbird_Tree.json';
end;

function TTestUnistallBplSource.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.CreateAsLatestVersionOption;
end;

{ TTestUpdateBplSource }

procedure TTestUpdateBplSource.Asserts;
var
  BplPath: string;
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Test_Thunderbird_Tree');
  AssertObject(Package, 'Test_Thunderbird_Tree');
  AssertObject(Package.Version, 'Test_Thunderbird_Tree.Version');
  AssertString(Package.Version.SHA, '08366f730fe3b30dea4c50c095df0c0b5cb0adaa');
  AssertBoolean(Package.IsDirect, True);
  AssertDirExists(FDPMEngine.Path_GetPackage(Package));

  BplPath := '';
  if (Length(Package.BplFileRefs) > 0) then
    BplPath := Package.BplFileRefs[0];
  AssertBoolean(BplPath.EndsWith('\Bpl\thunderbirdTree.bpl'), True);
  AssertFileExists(BplPath);

  AssertBplInstalled(BplPath);
end;

procedure TTestUpdateBplSource.ClearTestProject;
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := GetIDEPackage('Test_Thunderbird_Tree');
  if Assigned(DependentPackage) then
    FDPMEngine.Action_Uninstall(DependentPackage);
end;

procedure TTestUpdateBplSource.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  case aStep of
    1: FDPMEngine.Action_Install(aPackage, aVersion);
    2: FDPMEngine.Action_Update(aPackage, aVersion);
  end;
end;

function TTestUpdateBplSource.GetDescription: string;
begin
  Result := 'Update Bpl Source Package';
end;

function TTestUpdateBplSource.GetStepCount: Integer;
begin
  Result := 2;
end;

function TTestUpdateBplSource.GetTestPackageFileName(const aStep: Integer): string;
begin
  Result := 'Test_Thunderbird_Tree.json';
end;

function TTestUpdateBplSource.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.Create;
  case aStep of
    1: Result.SHA := 'c1468b962d14f6d160e35dc9018a4b29ac816292';
    2: Result.SHA := '08366f730fe3b30dea4c50c095df0c0b5cb0adaa';
  end;
end;

{ TTestInstallBplBinary }

procedure TTestInstallBplBinary.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Test_TRichView');
  AssertObject(Package, 'Test_TRichView');
  AssertObject(Package.Version, 'Test_TRichView.Version');
  AssertString(Package.Version.SHA, 'c49e2d846f488cf12e83cd2e2ff1aee1c8acf49e');
  AssertBoolean(Package.IsDirect, True);
  AssertFileExists(Package.BplFileRefs[0]);
  AssertBplInstalled(Package.BplFileRefs[0]);
  AssertDirNotExists(FDPMEngine.Path_GetPackage(Package));
end;

procedure TTestInstallBplBinary.ClearTestProject;
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := GetIDEPackage('Test_TRichView');
  if Assigned(DependentPackage) then
    FDPMEngine.Action_Uninstall(DependentPackage);
end;

procedure TTestInstallBplBinary.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  FDPMEngine.Action_Install(aPackage, aVersion);
end;

function TTestInstallBplBinary.GetDescription: string;
begin
  Result := 'Install Bpl Binary Package';
end;

function TTestInstallBplBinary.GetStepCount: Integer;
begin
  Result := 1;
end;

function TTestInstallBplBinary.GetTestPackageFileName(const aStep: Integer): string;
begin
  Result := 'Test_TRichView.json';
end;

function TTestInstallBplBinary.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.Create;
  Result.SHA := 'c49e2d846f488cf12e83cd2e2ff1aee1c8acf49e';
end;

{ TTestUninstallBplBinary }

procedure TTestUninstallBplBinary.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Test_TRichView');
  AssertNil(Package, 'Test_TRichView');
  AssertFileNotExists(FBplPath);
  AssertBplNotInstalled(FBplPath);
end;

procedure TTestUninstallBplBinary.ClearTestProject;
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := GetIDEPackage('Test_TRichView');
  if Assigned(DependentPackage) then
    FDPMEngine.Action_Uninstall(DependentPackage);
end;

procedure TTestUninstallBplBinary.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  case aStep of
    1:
      begin
        FDPMEngine.Action_Install(aPackage, aVersion);
        FBplPath := aPackage.BinaryFileRefs[0];
      end;
    2: FDPMEngine.Action_Uninstall(aPackage);
  end;
end;

function TTestUninstallBplBinary.GetDescription: string;
begin
  Result := 'Uninstall Bpl Binary Package';
end;

function TTestUninstallBplBinary.GetStepCount: Integer;
begin
  Result := 2;
end;

function TTestUninstallBplBinary.GetTestPackageFileName(
  const aStep: Integer): string;
begin
  Result := 'Test_TRichView.json';
end;

function TTestUninstallBplBinary.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.CreateAsLatestVersionOption;
end;

{ TTestUpdateBplBinary }

procedure TTestUpdateBplBinary.Asserts;
var
  Package: TDependentPackage;
begin
  Package := GetProjectPackage('Test_TRichView');
  AssertObject(Package, 'Test_TRichView');
  AssertObject(Package.Version, 'Test_TRichView.Version');
  AssertString(Package.Version.SHA, '9b4bfa8f32c312d256fa12be6089e33c226fbafc');
  AssertBoolean(Package.IsDirect, True);
  AssertInteger(Length(Package.BplFileRefs), 1);
  AssertFileExists(Package.BplFileRefs[0]);
  AssertBplInstalled(Package.BplFileRefs[0]);
  AssertDirNotExists(FDPMEngine.Path_GetPackage(Package));
end;

procedure TTestUpdateBplBinary.ClearTestProject;
var
  DependentPackage: TDependentPackage;
begin
  inherited;

  DependentPackage := GetIDEPackage('Test_TRichView');
  if Assigned(DependentPackage) then
    FDPMEngine.Action_Uninstall(DependentPackage);
end;


procedure TTestUpdateBplBinary.DoAction(aPackage: TInitialPackage;
  aVersion: TVersion; const aStep: Integer);
begin
  case aStep of
    1: FDPMEngine.Action_Install(aPackage, aVersion);
    2: FDPMEngine.Action_Update(aPackage, aVersion);
  end;
end;

function TTestUpdateBplBinary.GetDescription: string;
begin
  Result := 'Update Bpl Binary Package';
end;

function TTestUpdateBplBinary.GetStepCount: Integer;
begin
  Result := 2;
end;

function TTestUpdateBplBinary.GetTestPackageFileName(const aStep: Integer): string;
begin
  Result := 'Test_TRichView.json';
end;

function TTestUpdateBplBinary.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.Create;
  case aStep of
    1: Result.SHA := 'c49e2d846f488cf12e83cd2e2ff1aee1c8acf49e';
    2: Result.SHA := '9b4bfa8f32c312d256fa12be6089e33c226fbafc';
  end;
end;

end.
