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
    mniAdd: TMenuItem;
    mniPackageSettings: TMenuItem;
    mniRemove: TMenuItem;
    mniUpgrade: TMenuItem;
    procedure cbbVersionsDropDown(Sender: TObject);
    procedure mniAddClick(Sender: TObject);
    procedure mniPackageSettingsClick(Sender: TObject);
  private
    { Private declarations }
    FActionProc: TActionProc;
    FAllowAction: TAllowActionFunc;
    FGetVersionsFunc: TGetVersionsFunc;
    FPackage: TPackage;
    procedure InitActions;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aGetVersionsFunc: TGetVersionsFunc;
      aAllowAction: TAllowActionFunc); reintroduce;
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

constructor TfrmPackage.Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aGetVersionsFunc: TGetVersionsFunc;
      aAllowAction: TAllowActionFunc);
var
  VersionItem: string;
begin
  inherited Create(AOwner);

  FPackage := aPackage;
  FActionProc := aActionProc;
  FAllowAction := aAllowAction;
  FGetVersionsFunc := aGetVersionsFunc;

  lblPackageName.Caption := FPackage.Name;
  lblPackageDescription.Caption := FPackage.Description;

  if not aPackage.InstalledVersion.Name.IsEmpty then
    VersionItem := Format('%s%s...', [aPackage.InstalledVersion.Name, aPackage.InstalledVersion.SHA.Substring(1,5)])
  else
    VersionItem := cLatestVersion;

  cbbVersions.Items.Add(VersionItem);
  cbbVersions.ItemIndex := 0;

  InitActions;
end;

procedure TfrmPackage.InitActions;
begin
  mniAdd.Visible := FAllowAction(FPackage, atAdd);
  mniRemove.Visible := FAllowAction(FPackage, atRemove);
  mniUpgrade.Visible := FAllowAction(FPackage, atUpgrade);
  mniPackageSettings.Visible := FAllowAction(FPackage, atPackageSettings);
end;

procedure TfrmPackage.mniAddClick(Sender: TObject);
begin
  FActionProc(atAdd, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.mniPackageSettingsClick(Sender: TObject);
begin
  FActionProc(atPackageSettings, cbbVersions.Text, FPackage);
end;

end.
