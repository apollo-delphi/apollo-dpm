unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package;

type
  TAsyncLoadCallBack = reference to procedure;
  TAsyncLoadProc = reference to procedure;

  TFrameActionType = (fatInstall, fatUninstall, fatEditPackage);
  TFrameAllowActionFunc = function(const aFrameActionType: TFrameActionType;
    aPackage: TPackage): Boolean of object;
  TFrameActionProc = procedure(const aFrameActionType: TFrameActionType; aPackage: TPackage;
    const aVersion: TVersion) of object;

  TUINotifyProc = procedure(const aText: string) of object;

implementation

end.
