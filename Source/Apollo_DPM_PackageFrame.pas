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
    mniUpdateTo: TMenuItem;
    lblVersionlDescribe: TLabel;
    procedure cbbVersionsDropDown(Sender: TObject);
    procedure mniAddClick(Sender: TObject);
    procedure mniPackageSettingsClick(Sender: TObject);
    procedure mniRemoveClick(Sender: TObject);
    procedure cbbVersionsChange(Sender: TObject);
    procedure mniUpdateToClick(Sender: TObject);
  private
    { Private declarations }
    FActionProc: TActionProc;
    FAllowAction: TAllowActionFunc;
    FFilledVersions: TArray<TVersion>;
    FIsRepoVersionsLoaded: Boolean;
    FLoadRepoVersionsProc: TLoadRepoVersionsProc;
    FPackage: TPackage;
    function GetIndexByVersion(aVersion: TVersion): Integer;
    function GetSelectedVersion: TVersion;
    function GetVersionByIndex(const aIndex: Integer): TVersion;
    procedure FillVersions;
    procedure InitActions;
    procedure InitState;
    procedure SetVersionDescribe;
  public
    { Public declarations }
    function IsShowThisPackage(aPackage: TPackage): Boolean;
    procedure Refresh;
    constructor Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aLoadRepoVersionsProc: TLoadRepoVersionsProc;
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
  InitState;
end;

procedure TfrmPackage.cbbVersionsDropDown(Sender: TObject);
var
  AsyncTask: ITask;
begin
  if FIsRepoVersionsLoaded then
    Exit;

  aiVerListLoad.Animate := True;

  AsyncTask := TTask.Create(procedure()
    begin
      FLoadRepoVersionsProc(FPackage);

      TThread.Synchronize(nil, procedure()
        begin
          aiVerListLoad.Animate := False;

          FIsRepoVersionsLoaded := True;
          FillVersions;
        end
      );
    end
  );
  AsyncTask.Start;
end;

constructor TfrmPackage.Create(AOwner: TComponent; aPackage: TPackage;
      aActionProc: TActionProc; aLoadRepoVersionsProc: TLoadRepoVersionsProc;
      aAllowAction: TAllowActionFunc);
begin
  inherited Create(AOwner);

  FPackage := aPackage;
  FActionProc := aActionProc;
  FAllowAction := aAllowAction;
  FLoadRepoVersionsProc := aLoadRepoVersionsProc;
  FIsRepoVersionsLoaded := False;

  lblPackageDescription.Caption := FPackage.Description;

  Refresh;
end;

destructor TfrmPackage.Destroy;
begin
  FPackage.Free;

  inherited;
end;

procedure TfrmPackage.FillVersions;
var
  i: Integer;
  Version: TVersion;
  VersionIndex: Integer;
begin
  FFilledVersions := [];
  cbbVersions.Items.Clear;

  for i := 0 to Length(FPackage.Versions) - 1 do
    begin
      cbbVersions.Items.Add(FPackage.Versions[i].DisplayName);
      FFilledVersions := FFilledVersions + [FPackage.Versions[i]];
    end;

  Version.Init;
  if not FIsRepoVersionsLoaded then
    Version.Name := cLatestVersionOrCommit
  else
    Version.Name := cLatestCommit;

  cbbVersions.Items.Add(Version.DisplayName);
  FFilledVersions := FFilledVersions + [Version];

  VersionIndex := GetIndexByVersion(FPackage.InstalledVersion);
  if VersionIndex >= 0 then
    cbbVersions.ItemIndex := VersionIndex
  else
    cbbVersions.ItemIndex := cbbVersions.Items.Count - 1;
end;

function TfrmPackage.GetIndexByVersion(aVersion: TVersion): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Length(FFilledVersions) - 1 do
    if FFilledVersions[i].SHA = aVersion.SHA then
      Exit(i);
end;

function TfrmPackage.GetSelectedVersion: TVersion;
begin
  Result := GetVersionByIndex(cbbVersions.ItemIndex);
end;

function TfrmPackage.GetVersionByIndex(const aIndex: Integer): TVersion;
var
  i: Integer;
begin
  Result.Init;

  for i := 0 to Length(FFilledVersions) - 1 do
    if i = aIndex then
      Exit(FFilledVersions[i]);
end;

procedure TfrmPackage.InitActions;
begin
  mniAdd.Visible := FAllowAction(FPackage, GetSelectedVersion, atAdd);
  mniRemove.Visible := FAllowAction(FPackage, GetSelectedVersion, atRemove);
  mniUpdateTo.Visible := FAllowAction(FPackage, GetSelectedVersion, atUpdateTo);
  mniPackageSettings.Visible := FAllowAction(FPackage, GetSelectedVersion, atPackageSettings);
end;

procedure TfrmPackage.InitState;
begin
  InitActions;
  SetVersionDescribe;
end;

function TfrmPackage.IsShowThisPackage(aPackage: TPackage): Boolean;
begin
  Result := aPackage.Name = FPackage.Name;
end;

procedure TfrmPackage.mniAddClick(Sender: TObject);
var
  Version: TVersion;
begin
  Version := GetSelectedVersion;
  FActionProc(atAdd, Version, FPackage);
end;

procedure TfrmPackage.mniPackageSettingsClick(Sender: TObject);
var
  Version: TVersion;
begin
  Version := GetSelectedVersion;
  FActionProc(atPackageSettings, Version, FPackage);
end;

procedure TfrmPackage.mniRemoveClick(Sender: TObject);
var
  Version: TVersion;
begin
  Version := GetSelectedVersion;
  FActionProc(atRemove, Version, FPackage);
end;

procedure TfrmPackage.mniUpdateToClick(Sender: TObject);
var
  Version: TVersion;
begin
  Version := GetSelectedVersion;
  FActionProc(atUpdateTo, Version, FPackage);
end;

procedure TfrmPackage.Refresh;
begin
  FillVersions;
  InitState;
end;

procedure TfrmPackage.SetVersionDescribe;
var
  Version: TVersion;
begin
  lblVersionlDescribe.Caption := '';
  lblVersionlDescribe.Font.Color := clWindowText;
  Version := GetSelectedVersion;

  if not Version.SHA.IsEmpty and (Version.SHA = FPackage.InstalledVersion.SHA) then
    begin
      lblVersionlDescribe.Caption := Format('was installed at %s',
        [FormatDateTime('hh:mm:ss ddddd', Version.InstallTime)]);
      lblVersionlDescribe.Font.Color := clGreen;
    end
  else
  if Version.RemoveTime > 0 then
    begin
      lblVersionlDescribe.Caption := Format('was removed at %s',
        [FormatDateTime('hh:mm:ss ddddd', Version.RemoveTime)]);
      lblVersionlDescribe.Font.Color := clRed;
    end;
end;

end.
