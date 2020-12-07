unit Apollo_DPM_Types;

interface

uses
  Apollo_DPM_Package;

type
  TFrameActionType = (fatEditPackage);
  TFrameActionProc = procedure(const aFrameActionType: TFrameActionType; aPackage: TPackage) of object;

implementation

end.
