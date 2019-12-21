program Apollo_DPM_Test;

{$STRONGLINKTYPES ON}
uses
  Vcl.Forms,
  System.SysUtils,
  DUnitX.Loggers.GUI.VCL,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  tst_Apollo_DPM in 'tst_Apollo_DPM.pas',
  Apollo_DPM_GitHubAPI in '..\Source\Apollo_DPM_GitHubAPI.pas',
  Apollo_DPM_Engine in '..\Source\Apollo_DPM_Engine.pas',
  Apollo_DPM_Package in '..\Source\Apollo_DPM_Package.pas',
  Apollo_DPM_Form in '..\Source\Apollo_DPM_Form.pas' {DPMForm},
  DockForm in 'DockForm.pas',
  PersonalityConst in 'PersonalityConst.pas',
  Apollo_HTTP in '..\..\apollo-http\Source\Apollo_HTTP.pas',
  Apollo_DPM_PackageFrame in '..\Source\Apollo_DPM_PackageFrame.pas' {frmPackage: TFrame};

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.CreateForm(TDPMForm, DPMForm);
  Application.Run;
end.
