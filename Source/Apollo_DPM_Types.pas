unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package;

type
  TAsyncLoadCallBack = reference to procedure;
  TAsyncLoadProc = reference to procedure;
  TFrameActionType = (fatEditPackage);
  TFrameActionProc = procedure(const aFrameActionType: TFrameActionType; aPackage: TPackage) of object;

implementation

end.
