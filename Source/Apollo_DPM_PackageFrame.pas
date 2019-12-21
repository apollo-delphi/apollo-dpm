unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,
  Apollo_DPM_Form,
  Apollo_DPM_Package;

type
  TfrmPackage = class(TFrame)
    lblPackageName: TLabel;
    lblPackageDescription: TLabel;
    btnInstall: TButton;
    cbbVersions: TComboBox;
    lblVersion: TLabel;
    aiVerListLoad: TActivityIndicator;
    procedure cbbVersionsDropDown(Sender: TObject);
    procedure btnInstallClick(Sender: TObject);
  private
    { Private declarations }
    FActionProc: TActionProc;
    FGetVersionsFunc: TGetVersionsFunc;
    FPackage: TPackage;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; aPackage: TPackage); reintroduce;
    property ActionProc: TActionProc read FActionProc write FActionProc;
    property GetVersionsFunc: TGetVersionsFunc read FGetVersionsFunc write FGetVersionsFunc;
  end;

const
  cLatestVersion = 'latest';

implementation

uses
  System.Threading;

{$R *.dfm}

{ TfrmPackage }

procedure TfrmPackage.btnInstallClick(Sender: TObject);
begin
  FActionProc(cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.cbbVersionsDropDown(Sender: TObject);
var
  AsyncTask: ITask;
  Versions: TArray<TVersion>;
begin
  aiVerListLoad.Animate := True;

  AsyncTask := TTask.Create(procedure()
    begin
      Versions := FGetVersionsFunc(FPackage);

      TThread.Synchronize(nil, procedure()
        var
          i: Integer;
        begin
          aiVerListLoad.Animate := False;

          cbbVersions.Items.Clear;
          for i := 0 to Length(Versions) - 1 do
            cbbVersions.Items.Add(Versions[i].Name);
        end
      );
    end
  );
  AsyncTask.Start;
end;

constructor TfrmPackage.Create(AOwner: TComponent; aPackage: TPackage);
begin
  inherited Create(AOwner);

  FPackage := aPackage;

  lblPackageName.Caption := FPackage.Name;
  lblPackageDescription.Caption := FPackage.Description;

  cbbVersions.Items.Add(cLatestVersion);
  cbbVersions.ItemIndex := 0;
end;

end.
