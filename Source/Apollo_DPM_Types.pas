unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package,
  Apollo_DPM_Version;

type
  TAsyncLoadCallBack = reference to procedure;
  TAsyncLoadProc = reference to procedure;

  TFrameActionType = (fatInstall, fatUninstall, fatEditPackage);
  TFrameAllowActionFunc = function(const aFrameActionType: TFrameActionType;
    aPackage: TPackage): Boolean of object;
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

end.
