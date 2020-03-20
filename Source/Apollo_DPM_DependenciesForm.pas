unit Apollo_DPM_DependenciesForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Apollo_DPM_Package, Vcl.ComCtrls;

type
  TDependenciesForm = class(TForm)
    lvDependencies: TListView;
  private
    { Private declarations }
  public
    constructor Create(var aDependencies: TArray<TPackageDependence>); reintroduce;
  end;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Form;

{ TDependenciesForm }

constructor TDependenciesForm.Create(
  var aDependencies: TArray<TPackageDependence>);
begin
  inherited Create(DPMForm);
end;

end.
