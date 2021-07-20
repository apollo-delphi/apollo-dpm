program DPMTestProject;

uses
  Vcl.Forms,
  DPMTestForm in 'DPMTestForm.pas' {TestForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TTestForm, TestForm);
  Application.Run;
end.
