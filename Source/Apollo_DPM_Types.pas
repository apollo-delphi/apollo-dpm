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
    InitialPackage: TInitialPackage;
    PackageAction: TPackageAction;
    Version: TVersion;
    constructor Create(const aPackageAction: TPackageAction; aInitialPackage: TInitialPackage;
      aVersion: TVersion);
  end;

  TPackageHandles = TArray<TPackageHandle>;

  TUINotifyProc = procedure(const aText: string) of object;

implementation

{ TPackageHandle }

constructor TPackageHandle.Create(const aPackageAction: TPackageAction;
  aInitialPackage: TInitialPackage; aVersion: TVersion);
begin
  PackageAction := aPackageAction;
  InitialPackage := aInitialPackage;
  Version := aVersion;
end;

end.
