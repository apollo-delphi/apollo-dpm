unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package,
  Apollo_DPM_Version,
  Vcl.Forms;

type
  TAsyncLoadCallBack = reference to procedure;
  TAsyncLoadProc = reference to procedure;

  TFrameActionType = (fatInstall, fatUpdate, fatUninstall, fatEditPackage);

  TFrameAllowActionFunc = function(const aFrameActionType: TFrameActionType;
    aPackage: TPackage; aVersion: TVersion): Boolean of object;
  TFrameActionProc = procedure(const aFrameActionType: TFrameActionType; aPackage: TPackage;
    aVersion: TVersion) of object;
  TFrameSelectedProc = procedure(aFrame: TFrame; aPackage: TPackage) of object;

  TPackageAction = (paInstall, paUninstall);

  TPackageHandle = record
  public
    IsDirect: Boolean;
    NeedToFree: Boolean;
    Package: TPackage;
    PackageAction: TPackageAction;
    PackageID: string;
    Version: TVersion;
    constructor CreateInstallHandle(aPackage: TPackage; aVersion: TVersion;
      const aIsDirect: Boolean; aNeedToFree: Boolean);
    constructor CreateUninstallHandle(aPackage: TPackage);
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

  TUIActionsLockProc = procedure of object;
  TUIActionsUnlockProc = procedure of object;
  TUINotifyProc = procedure(const aText: string) of object;
  TUIGetFolderFunc = function: string of object;

implementation

{ TPackageHandle }

constructor TPackageHandle.CreateInstallHandle(aPackage: TPackage; aVersion: TVersion;
  const aIsDirect: Boolean; aNeedToFree: Boolean);
begin
  PackageAction := paInstall;
  Package := aPackage;
  PackageID := Package.ID;
  Version := aVersion;
  IsDirect := aIsDirect;
  NeedToFree := aNeedToFree;
end;

constructor TPackageHandle.CreateUninstallHandle(aPackage: TPackage);
begin
  PackageAction := paUninstall;
  Package := aPackage;
  PackageID := Package.ID;
  Version := nil;
  IsDirect := False;
  NeedToFree := False;
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
