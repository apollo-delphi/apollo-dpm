unit Apollo_DPM_PackageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Apollo_DPM_Engine, Vcl.Grids;

type
  TPackageForm = class(TForm)
    leRepoURL: TLabeledEdit;
    btnGo: TButton;
    leOwner: TLabeledEdit;
    leRepo: TLabeledEdit;
    leName: TLabeledEdit;
    leDescription: TLabeledEdit;
    rbWhiteList: TRadioButton;
    rbBlackList: TRadioButton;
    grpFiltering: TGroupBox;
    mmoFiltering: TMemo;
    grpMoving: TGroupBox;
    sgMoving: TStringGrid;
    btnSaveJSON: TButton;
    btnPublish: TButton;
    btnCancel: TButton;
    procedure btnGoClick(Sender: TObject);
    procedure sgMovingKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    FDPMEngine: TDPMEngine;
  public
    { Public declarations }
    constructor Create(aDPMEngine: TDPMEngine); reintroduce;
  end;

var
  PackageForm: TPackageForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_Package;

{ TPackageForm }

procedure TPackageForm.btnGoClick(Sender: TObject);
var
  Package: TPackage;
begin
  Package := FDPMEngine.CreateNewPackageForRepo(leRepoURL.Text);

  if Assigned(Package) then
    try
      leOwner.Text := Package.Owner;
      leRepo.Text := Package.Repo;
      leName.Text := Package.Name;
      leDescription.Text := Package.Description;
    finally
      Package.Free;
    end;
end;

constructor TPackageForm.Create(aDPMEngine: TDPMEngine);
begin
  inherited Create(nil);

  FDPMEngine := aDPMEngine;

  sgMoving.Cells[0, 0] := 'Source';
  sgMoving.Cells[1, 0] := 'Destination';
end;

procedure TPackageForm.sgMovingKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (sgMoving.Row = sgMoving.RowCount - 1) and
     (Key = VK_RETURN)
  then
    begin
      sgMoving.RowCount := sgMoving.RowCount + 1;
      sgMoving.Row := sgMoving.RowCount - 1;
    end;


  if (sgMoving.Row = sgMoving.RowCount - 1) and
     (sgMoving.Row > 1) and
     (Key = VK_BACK)
  then
    begin
      sgMoving.Row := sgMoving.RowCount - 2;
      sgMoving.RowCount := sgMoving.RowCount - 1;
    end;
end;

end.
