unit Apollo_DPM_UIHelper;

interface

uses
  VCL.Forms,
  VCL.WinXCtrls;

type
  TAsyncLoadProc = reference to procedure;
  TAsyncLoadCallback = reference to procedure;

  TUIFormHelper = class helper for TForm
    procedure AsyncLoad(aIndicator: TActivityIndicator; aAsyncLoadProc: TAsyncLoadProc;
      aCallback: TAsyncLoadCallback);
  end;

  TUIFrameHelper = class helper for TFrame
    procedure AsyncLoad(aIndicator: TActivityIndicator; aAsyncLoadProc: TAsyncLoadProc;
      aCallback: TAsyncLoadCallback);
  end;

  procedure AsyncLoadCommon(aIndicator: TActivityIndicator; aAsyncLoadProc: TAsyncLoadProc;
      aCallback: TAsyncLoadCallback);

implementation

uses
  System.Classes,
  System.Threading;

procedure AsyncLoadCommon(aIndicator: TActivityIndicator; aAsyncLoadProc: TAsyncLoadProc;
    aCallback: TAsyncLoadCallback);
var
  AsyncTask: ITask;
begin
  AsyncTask := TTask.Create(procedure()
    begin
      aAsyncLoadProc;

      TThread.Synchronize(nil, procedure()
        begin
          if Assigned(aCallback) then
            aCallback;
          if Assigned(aIndicator) then
            aIndicator.Animate := False;
        end
      );
    end
  );

  if Assigned(aIndicator) then
    aIndicator.Animate := True;
  AsyncTask.Start;
end;


{ TUIFormHelper }

procedure TUIFormHelper.AsyncLoad(aIndicator: TActivityIndicator; aAsyncLoadProc: TAsyncLoadProc;
  aCallback: TAsyncLoadCallback);
begin
  AsyncLoadCommon(aIndicator, aAsyncLoadProc, aCallback);
end;

{ TUIFrameHelper }

procedure TUIFrameHelper.AsyncLoad(aIndicator: TActivityIndicator;
  aAsyncLoadProc: TAsyncLoadProc; aCallback: TAsyncLoadCallback);
begin
  AsyncLoadCommon(aIndicator, aAsyncLoadProc, aCallback);
end;

end.
