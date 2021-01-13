unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package,
  Apollo_DPM_Version;

type
  TAsyncLoadCallBack = reference to procedure;
  TAsyncLoadProc = reference to procedure;

  TFrameActionType = (fatInstall, fatUpdate, fatUninstall, fatEditPackage);
  TFrameAllowActionFunc = function(const aFrameActionType: TFrameActionType;
    aPackage: TPackage; aVersion: TVersion): Boolean of object;
  TFrameActionProc = procedure(const aFrameActionType: TFrameActionType; aPackage: TPackage;
    aVersion: TVersion) of object;

  TPackageAction = (paInstall, paUninstall);

  TPackageHandle = record
  public
    NeedToFree: Boolean;
    Package: TPackage;
    PackageAction: TPackageAction;
    PackageID: string;
    Version: TVersion;
    constructor Create(const aPackageAction: TPackageAction; aPackage: TPackage;
      aVersion: TVersion; aNeedToFree: Boolean = False);
  end;

  TPackageHandles = TArray<TPackageHandle>;

  TPackageHandlesHelper = record helper for TPackageHandles
    function GetFirstInstallPackage: TInitialPackage;
    function ContainsInstallHandle(const aID: string): Boolean;
  end;

  TVersionConflict = record
  public
    DependentPackage: TDependentPackage;
    InstalledVersion: TVersion;
    RequiredVersion: TVersion;
    Selection: TVersion;
    constructor Create(aDependentPackage: TDependentPackage; aRequiredVersion: TVersion;
      aInstalledVersion: TVersion);
  end;

  TVersionConflicts = TArray<TVersionConflict>;

  TUINotifyProc = procedure(const aText: string) of object;

implementation

{ TPackageHandle }

constructor TPackageHandle.Create(const aPackageAction: TPackageAction;
  aPackage: TPackage; aVersion: TVersion; aNeedToFree: Boolean = False);
begin
  PackageAction := aPackageAction;
  Package := aPackage;
  PackageID := Package.ID;
  Version := aVersion;
  NeedToFree := aNeedToFree;
end;

{ TPackageHandlesHelper }

function TPackageHandlesHelper.ContainsInstallHandle(
  const aID: string): Boolean;
var
  PackageHandle: TPackageHandle;
begin
  Result := False;

  for PackageHandle in Self do
    if (PackageHandle.PackageAction = paInstall) and
       (PackageHandle.PackageID = aID)
    then
      Exit(True);
end;

function TPackageHandlesHelper.GetFirstInstallPackage: TInitialPackage;
var
  PackageHandle: TPackageHandle;
begin
  Result := nil;

  for PackageHandle in Self do
    if PackageHandle.PackageAction = paInstall then
      Exit(PackageHandle.Package as TInitialPackage);
end;

{ TVersionConflict }

constructor TVersionConflict.Create(aDependentPackage: TDependentPackage;
  aRequiredVersion, aInstalledVersion: TVersion);
begin
  DependentPackage := aDependentPackage;
  RequiredVersion := aRequiredVersion;
  InstalledVersion := aInstalledVersion;
  Selection := nil;
end;

end.
