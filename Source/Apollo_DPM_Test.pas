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
    function GetTestPackageName(const aStep: Integer): string;
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
    procedure ClearTestProject;
  protected
    function GetDescription: string;
    function GetError: string;
    function GetPassed: Boolean;
    function GetProjectPackage(const aPackageName: string): TDependentPackage;
    procedure AssertBoolean(const aActual, aExpected: Boolean);
    procedure AssertInteger(const aActual, aExpected: Integer);
    procedure AssertNil(aObject: TObject; const aObjName: string);
    procedure AssertObject(aObject: TObject; const aObjName: string);
    procedure AssertString(const aActual, aExpected: string);
    procedure Run;
  public
    constructor Create(aDPMEngine: TDPMEngine);
    destructor Destroy; override;
  end;

  TTestInstallCodeSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUninstallCodeSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestUpdateCodeSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
    procedure DoAction(aPackage: TInitialPackage; aVersion: TVersion; const aStep: Integer);
  end;

  TTestInstallBplSource = class(TTestCommon, ITestImpl)
  protected
    function GetDescription: string;
    function GetStepCount: Integer;
    function GetTestPackageName(const aStep: Integer): string;
    function GetVersion(const aStep: Integer): TVersion;
    procedure Asserts;
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
    TTestUninstallCodeSource.Create(aDPMEngine),
    TTestUpdateCodeSource.Create(aDPMEngine),
    TTestInstallBplSource.Create(aDPMEngine)
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

function TTestInstallCodeSource.GetTestPackageName(const aStep: Integer): string;
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
      TestPackage := CreateTestPackage(FTestImpl.GetTestPackageName(i));
      Version := FTestImpl.GetVersion(i);

      FTestImpl.DoAction(TestPackage, Version, i);
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
    FError.Add(Format('Boolean: Actual=%s Expected=%s', [BoolToStr(aActual), BoolToStr(aExpected)]));
  end;
end;

procedure TTestCommon.AssertInteger(const aActual, aExpected: Integer);
begin
  if aActual <> aExpected then
  begin
    FPassed := False;
    FError.Add(Format('Integer: Actual=%d Expected=%d', [aActual, aExpected]));
  end;
end;

procedure TTestCommon.AssertNil(aObject: TObject; const aObjName: string);
begin
  if aObject <> nil then
  begin
    FPassed := False;
    FError.Add(Format('Object %s is not nil', [aObjName]));
  end;
end;

procedure TTestCommon.AssertObject(aObject: TObject; const aObjName: string);
begin
  if not Assigned(aObject) then
  begin
    FPassed := False;
    FError.Add(Format('Object %s not assigned', [aObjName]));
  end;
end;

procedure TTestCommon.AssertString(const aActual, aExpected: string);
begin
  if aActual <> aExpected then
  begin
    FPassed := False;
    FError.Add(Format('String: Actual=%s Expected=%s', [aActual, aExpected]));
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

function TTestUninstallCodeSource.GetTestPackageName(const aStep: Integer): string;
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

function TTestUpdateCodeSource.GetTestPackageName(const aStep: Integer): string;
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
begin

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

function TTestInstallBplSource.GetTestPackageName(const aStep: Integer): string;
begin
  Result := 'Thunderbird_Tree.json';
end;

function TTestInstallBplSource.GetVersion(const aStep: Integer): TVersion;
begin
  Result := TVersion.CreateAsLatestVersionOption;
end;

end.
