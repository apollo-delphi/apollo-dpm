unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Apollo_DPM_Package;

type
  TfrmPackage = class(TFrame)
    lblName: TLabel;
  private
  public
    constructor Create(aOwner: TComponent; aPackage: TPackage);
  end;

implementation

{$R *.dfm}

{ TfrmPackage }

constructor TfrmPackage.Create(aOwner: TComponent; aPackage: TPackage);
begin
  inherited Create(aOwner);

  lblName.Caption := aPackage.Name;
end;

end.
