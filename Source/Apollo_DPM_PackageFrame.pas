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
    lblInstalled: TLabel;
    lblInstallDescribe: TLabel;
    procedure cbbVersionsDropDown(Sender: TObject);
    procedure mniAddClick(Sender: TObject);
    procedure mniPackageSettingsClick(Sender: TObject);
    procedure mniRemoveClick(Sender: TObject);
    procedure cbbVersionsChange(Sender: TObject);
  private
    { Private declarations }
    FActionProc: TActionProc;
    FAllowAction: TAllowActionFunc;
    FGetVersionsFunc: TGetVersionsFunc;
    FPackage: TPackage;
    procedure FillVersions;
    procedure InitActions;
    procedure SetInstallDescribe;
  public
    { Public declarations }
    function IsShowThisPackage(aPackage: TPackage): Boolean;
    procedure InitState;
    constructor Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aGetVersionsFunc: TGetVersionsFunc;
      aAllowAction: TAllowActionFunc); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Engine,
  System.Threading;

{$R *.dfm}

{ TfrmPackage }

procedure TfrmPackage.cbbVersionsChange(Sender: TObject);
begin
  lblInstallDescribe.Caption := 'fdsfs';
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
        begin
          aiVerListLoad.Animate := False;

          FillVersions;
        end
      );
    end
  );
  AsyncTask.Start;
end;

constructor TfrmPackage.Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aGetVersionsFunc: TGetVersionsFunc;
      aAllowAction: TAllowActionFunc);
begin
  inherited Create(AOwner);

  FPackage := TPackage.Create(aPackage);
  FActionProc := aActionProc;
  FAllowAction := aAllowAction;
  FGetVersionsFunc := aGetVersionsFunc;

  lblPackageDescription.Caption := FPackage.Description;

  InitState;
end;

destructor TfrmPackage.Destroy;
begin
  FPackage.Free;

  inherited;
end;

procedure TfrmPackage.FillVersions;
var
  i: Integer;
  VersionItem: string;
begin
  cbbVersions.Items.Clear;
  for i := 0 to Length(FPackage.Versions) - 1 do
    cbbVersions.Items.Add(FPackage.Versions[i].DisplayName);

  cbbVersions.Items.Add(cLatestCommit);

  {if not FPackage.InstalledVersion.Name.IsEmpty then
    VersionItem := Format('%s%s...', [FPackage.InstalledVersion.Name, FPackage.InstalledVersion.SHA.Substring(1,5)])
  else
    VersionItem := cLatestVersion;

  cbbVersions.Items.Add(VersionItem);
  cbbVersions.ItemIndex := 0;

  cbbVersions.Items.Clear;
  for i := 0 to Length(FPackage.Versions) - 1 do
    cbbVersions.Items.Add(FPackage.Versions[i].Name);

  cbbVersions.Items.Add(cLatestRevision);}
end;

procedure TfrmPackage.InitActions;
begin
  mniAdd.Visible := FAllowAction(FPackage, atAdd);
  mniRemove.Visible := FAllowAction(FPackage, atRemove);
  mniUpgrade.Visible := FAllowAction(FPackage, atUpgrade);
  mniPackageSettings.Visible := FAllowAction(FPackage, atPackageSettings);
end;

procedure TfrmPackage.InitState;
begin
  FillVersions;
  InitActions;
end;

function TfrmPackage.IsShowThisPackage(aPackage: TPackage): Boolean;
begin
  Result := aPackage.Name = FPackage.Name;
end;

procedure TfrmPackage.mniAddClick(Sender: TObject);
begin
  FActionProc(atAdd, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.mniPackageSettingsClick(Sender: TObject);
begin
  FActionProc(atPackageSettings, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.mniRemoveClick(Sender: TObject);
begin
  FActionProc(atRemove, cbbVersions.Text, FPackage);
end;

procedure TfrmPackage.SetInstallDescribe;
begin

end;

end.
