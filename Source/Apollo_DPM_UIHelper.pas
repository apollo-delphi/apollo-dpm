unit Apollo_DPM_UIHelper;

interface

uses
  Apollo_DPM_Types,
  Vcl.Forms,
  Vcl.WinXCtrls;

type
  TFormHelper = class helper for TForm
    procedure AsyncLoad(aIndicator: TActivityIndicator; aLoadProc: TAsyncLoadProc;
      aCallBack: TAsyncLoadCallBack);
  end;

implementation

uses
  System.Classes,
  System.Threading;

procedure AsyncLoadCommon(aIndicator: TActivityIndicator; aLoadProc: TAsyncLoadProc;
      aCallBack: TAsyncLoadCallBack);
var
  AsyncTask: ITask;
begin
  AsyncTask := TTask.Create(procedure()
    begin
      aLoadProc;

      TThread.Synchronize(nil, procedure()
        begin
          if Assigned(aCallBack) then
            aCallBack;
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

{ TFormHelper }

procedure TFormHelper.AsyncLoad(aIndicator: TActivityIndicator;
  aLoadProc: TAsyncLoadProc; aCallBack: TAsyncLoadCallBack);
begin
  AsyncLoadCommon(aIndicator, aLoadProc, aCallBack);
end;

end.
