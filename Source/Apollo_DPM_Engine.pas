unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  System.SysUtils,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    FGHAPI: TGHAPI;
    FPrivatePackages: TPackageList;
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetPrivatePackagesPath: string;
    procedure BuildMenu;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure SavePackage(aPackage: TPackage);
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
  public
    function GetPrivatePackages: TPackageList;
    function LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName, aError: string): Boolean;
    procedure AddNewPrivatePackage(aPackage: TPackage);
    procedure UpdatePrivatePackage(aPackage: TPackage);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_Validation,
  System.Classes,
  System.IOUtils,
  ToolsAPI;

{ TDPMEngine }

procedure TDPMEngine.AddApolloMenuItem;
var
  ApolloItem: TMenuItem;
begin
  ApolloItem := TMenuItem.Create(nil);
  ApolloItem.Name := cApolloMenuItemName;
  ApolloItem.Caption := cApolloMenuItemCaption;

  GetIDEMainMenu.Items.Insert(GetIDEMainMenu.Items.Count - 1, ApolloItem);
end;

procedure TDPMEngine.AddDPMMenuItem;
var
  DPMMenuItem: TMenuItem;
begin
  DPMMenuItem := TMenuItem.Create(nil);
  DPMMenuItem.Caption := cDPMMenuItemCaption;
  DPMMenuItem.OnClick := DPMMenuItemClick;

  GetApolloMenuItem.Add(DPMMenuItem);
end;

procedure TDPMEngine.AddNewPrivatePackage(aPackage: TPackage);
begin
  SavePackage(aPackage);
  GetPrivatePackages.Add(aPackage);
end;

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create;
begin
  FGHAPI := TGHAPI.Create;

  FPrivatePackages := nil;

  BuildMenu;

  Validation := TValidation.Create(Self);
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;
  FGHAPI.Free;

  if Assigned(FPrivatePackages) then
    FPrivatePackages.Free;

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
begin
  DPMForm := TDPMForm.Create(Self);
  try
    DPMForm.ShowModal;
  finally
    DPMForm.Free;
  end;
end;

function TDPMEngine.GetApolloMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;

  for MenuItem in GetIDEMainMenu.Items do
    if MenuItem.Name = cApolloMenuItemName then
      Exit(MenuItem);
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDPMEngine.GetPrivatePackages: TPackageList;
var
  FileArr: TArray<string>;
  FileItem: string;
  PackageFileData: TPackageFileData;
  PackageFileDataArr: TArray<TPackageFileData>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesPath) then
    begin
      FileArr := TDirectory.GetFiles(GetPrivatePackagesPath, '*.json');
      PackageFileDataArr := [];
      for FileItem in FileArr do
      begin
        PackageFileData.FilePath := FileItem;
        PackageFileData.JSONString := TFile.ReadAllText(FileItem, TEncoding.ANSI);

        PackageFileDataArr := PackageFileDataArr + [PackageFileData];
      end;

      if Length(PackageFileDataArr) > 0 then
        FPrivatePackages := TPackageList.Create(PackageFileDataArr);
    end;
  end;

  if FPrivatePackages = nil then
    FPrivatePackages := TPackageList.Create(True);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPrivatePackagesPath);
end;

function TDPMEngine.LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName,
  aError: string): Boolean;
var
  RepoURL: string;
  SHA: string;
  URLWords: TArray<string>;
begin
  Result := False;
  RepoURL := aRepoURL;
  aRepoOwner := '';
  aRepoName := '';
  aError := '';

  if RepoURL.Contains('://') then
    RepoURL := RepoURL.Substring(RepoURL.IndexOf('://') + 3, RepoURL.Length);
  URLWords := RepoURL.Split(['/']);

  if (not (Length(URLWords) >= 3)) or
   ((Length(URLWords) > 0) and (URLWords[0].ToLower <> 'github.com'))
  then
  begin
    aError := cStrTheGitHubRepositoryUrlIsInvalid;
    Exit;
  end;

  try
    SHA := FGHAPI.GetMasterBranchSHA(URLWords[1], URLWords[2]);
  except
    aError := cStrCantLoadTheRepositoryURL;
    Exit;
  end;

  if SHA.IsEmpty then
    Exit;

  Result := True;
  aRepoOwner := URLWords[1];
  aRepoName := URLWords[2];
end;

procedure TDPMEngine.SavePackage(aPackage: TPackage);
var
  Bytes: TBytes;
  Path: string;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Path := TPath.Combine(GetPrivatePackagesPath, aPackage.Name + '.json');

  WriteFile(Path, Bytes);
  aPackage.FilePath := Path;
end;

procedure TDPMEngine.UpdatePrivatePackage(aPackage: TPackage);
begin
  TFile.Delete(aPackage.FilePath);
  SavePackage(aPackage);
end;

procedure TDPMEngine.WriteFile(const aPath: string; const aBytes: TBytes);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aPath));

  FS := TFile.Create(aPath);
  try
    FS.Position := FS.Size;
    FS.Write(aBytes[0], Length(aBytes));
  finally
    FS.Free;
  end;
end;

end.
