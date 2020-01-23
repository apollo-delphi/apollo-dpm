unit Apollo_DPM_PackageFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.Menus,
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
    pmActions: TPopupMenu;
    mniInstall: TMenuItem;
    mniPackageSettings: TMenuItem;
    procedure cbbVersionsDropDown(Sender: TObject);
    procedure mniInstallClick(Sender: TObject);
    procedure mniPackageSettingsClick(Sender: TObject);
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

implementation

uses
  Apollo_DPM_Engine,
  System.Threading;

{$R *.dfm}

{ TfrmPackage }

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

          cbbVersions.Items.Add(cLatestRevision);
        end
      );
    end
  );
  AsyncTask.Start;
end;

constructor TfrmPackage.Create(AOwner: TComponent; aPackage: TPackage);
var
  VersionItem: string;
begin
  inherited Create(AOwner);

  FPackage := aPackage;

  lblPackageName.Caption := FPackage.Name;
  lblPackageDescription.Caption := FPackage.Description;

  if not aPackage.InstalledVersion.Name.IsEmpty then
    VersionItem := Format('%s%s...', [aPackage.InstalledVersion.Name, aPackage.InstalledVersion.SHA.Substring(1,5)])
  else
    VersionItem := cLatestVersion;

  cbbVersions.Items.Add(VersionItem);
  cbbVersions.ItemIndex := 0;
end;

procedure TfrmPackage.mniInstallClick(Sender: TObject);
begin
  FActionProc(atInstall, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.mniPackageSettingsClick(Sender: TObject);
begin
  FActionProc(atPackageSettings, cbbVersions.Text, FPackage);
end;

end.
