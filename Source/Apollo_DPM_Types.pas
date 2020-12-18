unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package;

type
  TAsyncLoadCallBack = reference to procedure;
  TAsyncLoadProc = reference to procedure;

  TFrameActionType = (fatInstall, fatEditPackage);
  TFrameAllowActionFunc = function(const aActionType: TFrameActionType): Boolean of object;
  TFrameActionProc = procedure(const aFrameActionType: TFrameActionType; aPackage: TPackage;
    const aVersion: TVersion) of object;

implementation

end.
