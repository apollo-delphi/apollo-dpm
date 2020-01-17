unit Apollo_DPM_PackageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Apollo_DPM_Engine,
  Apollo_DPM_Package;

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
    grpMoving: TGroupBox;
    sgMoving: TStringGrid;
    btnSaveJSON: TButton;
    btnPublish: TButton;
    btnCancel: TButton;
    fsdSaveJSON: TFileSaveDialog;
    sgFiltering: TStringGrid;
    procedure btnGoClick(Sender: TObject);
    procedure sgMovingKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnSaveJSONClick(Sender: TObject);
    procedure sgFilteringKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    FDPMEngine: TDPMEngine;
    FPackage: TPackage;
    procedure ReadControls;
  public
    { Public declarations }
    constructor Create(aDPMEngine: TDPMEngine; aPackage: TPackage); reintroduce;
  end;

var
  PackageForm: TPackageForm;

implementation

{$R *.dfm}

{ TPackageForm }

procedure TPackageForm.btnGoClick(Sender: TObject);
var
  Error: string;
  Owner: string;
  Repo: string;
begin
  if FDPMEngine.LoadRepoData(leRepoURL.Text, Owner, Repo, Error) then
    begin
      leOwner.Text := Owner;
      leRepo.Text := Repo;
    end
  else
  if not Error.IsEmpty then
    ShowMessage(Error);
end;

procedure TPackageForm.btnSaveJSONClick(Sender: TObject);
begin
  ReadControls;

  fsdSaveJSON.FileName := 'DPMPackage.json';
  if fsdSaveJSON.Execute then
    begin
      FPackage.FileName := ExtractFileName(fsdSaveJSON.FileName);
      FDPMEngine.SavePackage(FPackage, fsdSaveJSON.FileName);
    end;
end;

constructor TPackageForm.Create(aDPMEngine: TDPMEngine; aPackage: TPackage);
begin
  inherited Create(nil);

  FDPMEngine := aDPMEngine;
  FPackage := aPackage;

  sgMoving.Cells[0, 0] := 'Source';
  sgMoving.Cells[1, 0] := 'Destination';
end;

procedure TPackageForm.ReadControls;
var
  i: Integer;
  Move: TMove;
begin
  FPackage.Owner := leOwner.Text;
  FPackage.Repo := leRepo.Text;
  FPackage.Name := leName.Text;
  FPackage.Description := leDescription.Text;

  if (sgFiltering.RowCount > 0) and (not sgFiltering.Cells[0, 0].IsEmpty) then
    begin
      if rbWhiteList.Checked then
        FPackage.FilterType := ftWhiteList
      else
        FPackage.FilterType := ftBlackList;

      for i := 0 to sgFiltering.RowCount - 1 do
        FPackage.Filters := FPackage.Filters + [sgFiltering.Cells[0, i]];
    end;

  if (sgMoving.RowCount > 1) and (not sgMoving.Cells[0, 1].IsEmpty) then
    for i := 1 to sgMoving.RowCount - 1 do
      begin
        Move.Source := sgMoving.Cells[0, i];
        Move.Destination := sgMoving.Cells[1, i];

        FPackage.Moves := FPackage.Moves + [Move];
      end;
end;

procedure TPackageForm.sgFilteringKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (sgFiltering.Row = sgFiltering.RowCount - 1) and
     (Key = VK_RETURN)
  then
    begin
      sgFiltering.RowCount := sgFiltering.RowCount + 1;
      sgFiltering.Row := sgFiltering.RowCount - 1;
    end;


  if (sgFiltering.Row = sgFiltering.RowCount - 1) and
     (sgFiltering.Row > 0) and
     (Key = VK_BACK)
  then
    begin
      sgFiltering.Row := sgFiltering.RowCount - 2;
      sgFiltering.RowCount := sgFiltering.RowCount - 1;
    end;
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
