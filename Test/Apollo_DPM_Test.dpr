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
  Apollo_HTTP in '..\..\apollo-http\Source\Apollo_HTTP.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
end.
