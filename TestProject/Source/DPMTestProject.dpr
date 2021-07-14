program DPMTestProject;

uses
  Vcl.Forms,
  DPMTestForm in 'DPMTestForm.pas' {TestForm},
  Apollo_Helpers in '..\Vendors\Apollo_Helpers\Apollo_Helpers.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TTestForm, TestForm);
  Application.Run;
end.
