unit Apollo_DPM_DependenciesForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Apollo_DPM_Form,
  Apollo_DPM_Package;

type
  TDependenciesForm = class(TForm)
    lvDependencies: TListView;
    procedure FormShow(Sender: TObject);
  private
    FLoadPackageDependenciesProc: TLoadPackageDependenciesProc;
    FPackage: TPackage;
    FVersion: TVersion;
  public
    constructor Create(const aVersion: TVersion; aPackage: TPackage;
      aLoadPackageDependenciesProc: TLoadPackageDependenciesProc); reintroduce;
  end;

implementation

{$R *.dfm}

uses
  Apollo_DPM_UIHelper;

{ TDependenciesForm }

constructor TDependenciesForm.Create(const aVersion: TVersion; aPackage: TPackage;
  aLoadPackageDependenciesProc: TLoadPackageDependenciesProc);
begin
  inherited Create(DPMForm);

  FLoadPackageDependenciesProc := aLoadPackageDependenciesProc;
  FPackage :=  aPackage;
  FVersion := aVersion;
end;

procedure TDependenciesForm.FormShow(Sender: TObject);
begin
{  AsyncTask := TTask.Create(procedure()
    begin
      FLoadPackageDependenciesProc(FVersion, FPackage);
    end
  );
  AsyncTask.Start;}

  AsyncLoad(
    nil,
    procedure()
    begin
      FLoadPackageDependenciesProc(FVersion, FPackage);
    end,
    nil
  );
end;

end.
