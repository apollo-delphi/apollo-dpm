unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Apollo_DPM_Package,
  Apollo_DPM_Types;

type
  TfrmPackage = class(TFrame)
    lblName: TLabel;
    btnEdit: TButton;
    procedure btnEditClick(Sender: TObject);
  private
    FOnAction: TFrameActionProc;
    FPackage: TPackage;
  public
    constructor Create(aOwner: TComponent; aPackage: TPackage); reintroduce;
    property OnAction: TFrameActionProc read FOnAction write FOnAction;
  end;

implementation

{$R *.dfm}

{ TfrmPackage }

procedure TfrmPackage.btnEditClick(Sender: TObject);
begin
  FOnAction(fatEditPackage, FPackage);
end;

constructor TfrmPackage.Create(aOwner: TComponent; aPackage: TPackage);
begin
  inherited Create(aOwner);

  FPackage := aPackage;
  lblName.Caption := aPackage.Name;
end;

end.
