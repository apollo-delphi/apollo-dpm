unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  Apollo_DPM_Settings,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus,
  Xml.XMLIntf;

type
  TDPMEngine = class
  private
    FAreActionsLocked: Boolean;
    FGHAPI: TGHAPI;
    FIDEPackages: TDependentPackageList;
    FPrivatePackages: TPrivatePackageList;
    FSettings: TSettings;
    FUIActionsLockProc: TUIActionsLockProc;
    FUIActionsUnlockProc: TUIActionsUnlockProc;
    FUIGetFolderFunc: TUIGetFolderFunc;
    FUINotifyProc: TUINotifyProc;
    FVersionCacheList: TVersionCacheList;
    function FindXmlNode(aNode: IXMLNode; const aNodeName: string): IXMLNode;
    function GetApolloMenuItem: TMenuItem;
    function GetDependentPackage(aPackage: TPackage): TDependentPackage;
    function GetIDEMainMenu: TMainMenu;
    function GetIDEPackagesPath: string;
    function GetPrivatePackagesFolderPath: string;
    function GetSettingsPath: string;
    function GetVersionCacheList: TVersionCacheList;
    function MakeBPL(const aProjectFileName, aPackagePath: string): string;
    function RepoPathToFilePath(const aRepoPath: string): string;
    function RunConsole(const aCommand: string): string;
    function SaveAsPrivatePackage(aPackage: TInitialPackage): string;
    function SyncVersionCache(const aPackageID: string; aVersion: TVersion): TVersion;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure ApplySettings;
    procedure BuildMenu;
    procedure DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
      aResult: TDependentPackageList); overload;
    procedure DPMClosed;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure DPMOpened;
    procedure FreeVersionCacheList;
    procedure InstallBpl(const aBplPath: string);
    procedure LoadRepoVersions(aPackage: TPackage);
    procedure LockActions;
    procedure SavePackageList(const aPath: string; aPackageList: TDependentPackageList);
    procedure UninstallBpl(const aBplPath: string);
    procedure UnlockActions;
    function GetProjectGroup: IOTAProjectGroup;
  public
    function AreVersionsLoaded(const aPackageID: string): Boolean;
    function AllowAction(const aFrameActionType: TFrameActionType;
      aPackage: TPackage; aVersion: TVersion): Boolean;
    function DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
    function GetIDEPackages: TDependentPackageList;
    function GetInitialPackage(aDependentPackage: TDependentPackage): TInitialPackage;
    function GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
    function LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName, aError: string): Boolean;
    function LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
    function SaveContent(const aPackagePath, aRepoPath, aContent: string): string;
    function ShowConflictForm(const aCaption: string; aVersionConflicts: TVersionConflicts): TVersionConflicts;
    procedure AddNewPrivatePackage(aPackage: TInitialPackage);
    procedure ApplyAndSaveSettings;
    procedure OpenProject(const aProjectPath: string);
    procedure ShowFirstModule;
    procedure UpdatePrivatePackage(aPackage: TPrivatePackage);
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
    constructor Create;
    destructor Destroy; override;
    property GetFolder: TUIGetFolderFunc read FUIGetFolderFunc;
    property GHAPI: TGHAPI read FGHAPI;
    property Settings: TSettings read FSettings;
    function GetPackagePath(aPackage: TPackage): string;
    function IsProjectOpened: Boolean;
    procedure AddFileToActiveProject(const aFilePath: string);
    procedure ResetDependentPackage(aDependentPackage: TDependentPackage);
    procedure SaveActiveProject;
    procedure SavePackages;
    property AreActionsLocked: Boolean read FAreActionsLocked;

  private
    FProjectPackages: TDependentPackageList;
    FTestMode: Boolean;
    procedure FreePackageLists;
  public
    class function Files_Get(const aDirectoryPath, aNamePattern: string): TArray<string>;
    class function File_GetText(const aPath: string): string;
    function Action_Install(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
    function Action_Uninstall(aPackage: TPackage): TPackageHandles;
    function Action_Update(aPackage: TPackage; aVersion: TVersion): TPackageHandles;
    function Packages_GetPrivate: TPrivatePackageList;
    function Packages_GetProject: TDependentPackageList;
    function Package_LoadDependencies(aDependentPackage: TDependentPackage): TDependentPackageList; overload;
    function Package_LoadDependencies(aInitialPackage: TInitialPackage; aVersion: TVersion): TDependentPackageList; overload;
    function Path_GetActiveProject: string;
    function Path_GetProjectPackages: string;
    function Path_GetVendors: string;
    function ProjectActive_Contains(const aFilePath: string): Boolean;
    function ProjectActive_RemoveFile(const aFilePath: string): IOTAProject;
    function Project_GetActive: IOTAProject;
    function Project_GetDPM: IOTAProject;
    function Project_GetTest: IOTAProject;
    function Project_SetActive(aProject: IOTAProject): IOTAProject;
    property NotifyUI: TUINotifyProc read FUINotifyProc;
    property TestMode: Boolean read FTestMode write FTestMode;
  end;

implementation

uses
  Apollo_DPM_Actions,
  Apollo_DPM_ConflictForm,
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_Pipes,
  Apollo_DPM_Validation,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.Types,
  Vcl.Controls,
  Xml.XMLDoc;

{ TDPMEngine }

function TDPMEngine.ProjectActive_Contains(const aFilePath: string): Boolean;
begin
  Result := GetActiveProject.FindModuleInfo(aFilePath) <> nil;
end;

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

procedure TDPMEngine.AddNewPrivatePackage(aPackage: TInitialPackage);
var
  Package: TPrivatePackage;
  Path: string;
begin
  Path := SaveAsPrivatePackage(aPackage);

  Package := TPrivatePackage.Create(File_GetText(Path));
  Package.FilePath := Path;

  Packages_GetPrivate.Add(Package);
end;

procedure TDPMEngine.AddFileToActiveProject(const aFilePath: string);
begin
  TThread.Synchronize(nil, procedure()
    begin
      GetActiveProject.AddFile(aFilePath, True);
    end
  );
end;

function TDPMEngine.AllowAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage; aVersion: TVersion): Boolean;
var
  DependentPackage: TDependentPackage;
  InitialPackage: TInitialPackage;
begin
  Result := False;

  if aPackage is TInitialPackage then
  begin
    InitialPackage := aPackage as TInitialPackage;

    case aFrameActionType of
      fatInstall:
        Result := TInstall.GetClass(InitialPackage.PackageType).Allowed(Self, InitialPackage, aVersion);

      fatUpdate:
        Result := Assigned(aVersion) and
          InitialPackage.IsInstalled and
          (InitialPackage.DependentPackage.Version.SHA <> aVersion.SHA);

      fatUninstall:
        Result := TUninstall.GetClass(InitialPackage.PackageType).Allowed(Self, InitialPackage.DependentPackage, aVersion);

      fatEditPackage:
        Result := True;
    end;
  end
  else
  if aPackage is TDependentPackage then
  begin
    DependentPackage := aPackage as TDependentPackage;

    case aFrameActionType of
      fatInstall:
        Result := False;

      fatUpdate:
        Result := Assigned(aVersion) and
          (DependentPackage.Version.SHA <> aVersion.SHA);

      fatUninstall:
        Result := TUninstall.GetClass(DependentPackage.PackageType).Allowed(Self, DependentPackage, aVersion);

      fatEditPackage:
        Result := False;
    end;
  end;
end;

function TDPMEngine.AreVersionsLoaded(const aPackageID: string): Boolean;
begin
  Result := GetVersionCacheList.ContainsLoadedPackageID(aPackageID);
end;

function TDPMEngine.MakeBPL(const aProjectFileName, aPackagePath: string): string;
var
  ConsoleOutput: string;
  FileItem: string;
  Files: TArray<string>;
  FrameworkDir: string;
  MSBuildPath: string;
  OutputFile: string;
  OutputPath: string;
  ProjectFilePath: string;
  RsVarsPath: string;
  StringList: TStringList;
  XmlFile: IXMLDocument;
  XmlNode: IXMLNode;
begin
  FUINotifyProc(Format('compiling %s', [aProjectFileName]));

  ProjectFilePath := '';
  Files := Files_Get(aPackagePath, '*');
  for FileItem in Files do
    if FileItem.EndsWith(aProjectFileName) then
    begin
      ProjectFilePath := FileItem;
      Break;
    end;

  if ProjectFilePath.IsEmpty then
    raise Exception.CreateFmt('compiling bpl: %s was not found.', [aProjectFileName]);

  RsVarsPath := TPath.Combine((BorlandIDEServices as IOTAServices).ExpandRootMacro('$(BDSBIN)'), 'rsvars.bat');

  if not TFile.Exists(RsVarsPath) then
    raise Exception.Create('compiling bpl: can`t find rsvars.bat');

  StringList := TStringList.Create;
  try
    StringList.LoadFromFile(RsVarsPath);
    FrameworkDir := StringList.Values['@SET FrameworkDir'];
  finally
    StringList.Free;
  end;

  if FrameworkDir.IsEmpty then
    raise Exception.Create('compiling bpl: can`t find .NET FrameworkDir');

  MSBuildPath := TPath.Combine(FrameworkDir, 'MSBuild.exe');
  ConsoleOutput := RunConsole(Format('%s "%s" /t:Make', [MSBuildPath, ProjectFilePath]));

  //FUINotifyProc(ConsoleOutput);

  XmlFile := LoadXMLDocument(ProjectFilePath);

  XmlNode := FindXmlNode(XmlFile.Node, 'DCC_BplOutput');
  if Assigned(XmlNode) and not XmlNode.Text.IsEmpty then
    OutputPath := XmlNode.Text
  else
    OutputPath := '$(BDSCOMMONDIR)\Bpl';
  OutputPath := (BorlandIDEServices as IOTAServices).ExpandRootMacro(OutputPath);

  OutputFile := FindXmlNode(XmlFile.Node, 'MainSource').Text;
  OutputFile := OutputFile.Remove(OutputFile.LastIndexOf('.'));
  OutputFile := OutputFile + '.bpl';

  Result := TPath.Combine(OutputPath, OutputFile);
  if not TFile.Exists(Result) then
    raise Exception.CreateFmt('compiling bpl: %s was not found.', [Result]);
end;

procedure TDPMEngine.OpenProject(const aProjectPath: string);
var
  ModuleServices: IOTAModuleServices;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  ModuleServices.OpenModule(aProjectPath);
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

  BuildMenu;

  Validation := TValidation.Create(Self);
end;

function TDPMEngine.Project_GetTest: IOTAProject;
var
  ProjectGroup: IOTAProjectGroup;
  i: Integer;
begin
  ProjectGroup := GetProjectGroup;

  for i := 0 to ProjectGroup.ProjectCount - 1 do
    if ProjectGroup.Projects[i].FileName.EndsWith('DPMTestProject.dproj') then
      Exit(ProjectGroup.Projects[i]);

  raise Exception.Create('Test project DPMTestProject.dproj is not in the project group!');
end;

function TDPMEngine.DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
var
  Versions: TArray<TVersion>;
begin
  if not aVersion.SHA.IsEmpty then
    Exit(aVersion);

  Versions := GetVersions(aPackage);
  if Length(Versions) > 0 then
    Exit(Versions[0])
  else
    raise Exception.Create('No versions was found!');
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;
  FGHAPI.Free;
  FreeVersionCacheList;
  DPMClosed;

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
end;

procedure TDPMEngine.DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
  aResult: TDependentPackageList);
var
  Blob: TBlob;
  i: Integer;
  Package: TDependentPackage;
  PackageList: TDependentPackageList;
  sJSON: string;
  TreeNode: TTreeNode;
begin
  aVersion.RepoTree := LoadRepoTree(aDependentPackage, aVersion);
  aVersion.Dependencies := [];

  for TreeNode in aVersion.RepoTree do
    if TreeNode.Path.EndsWith(cPathProjectPackages) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);
      sJSON := TNetEncoding.Base64.Decode(Blob.Content);

      PackageList := TDependentPackageList.Create(sJSON, SyncVersionCache);
      try
        for i := PackageList.Count - 1 downto 0 do
        begin
          aVersion.Dependencies := aVersion.Dependencies + [PackageList[i].ID];

          if PackageList[i].IsDirect then
          begin
            Package := PackageList.ExtractAt(i);
            aResult.Add(Package);

            DoLoadDependencies(Package, Package.Version, aResult);
          end;
        end;
      finally
        PackageList.Free;
      end;
    end;
end;

procedure TDPMEngine.DPMClosed;
begin
  FreePackageLists;

  if Assigned(FSettings) then
    FreeAndNil(FSettings);
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
begin
  DPMForm := TDPMForm.Create(Self);
  try
    DPMOpened;
    FUIActionsLockProc := DPMForm.LockActions;
    FUIActionsUnlockProc := DPMForm.UnlockActions;
    FUINotifyProc := DPMForm.NotifyObserver;
    FUIGetFolderFunc := DPMForm.GetFolder;
    DPMForm.ShowModal;
  finally
    DPMForm.Free;
    DPMClosed;
  end;
end;

procedure TDPMEngine.DPMOpened;
begin
  if TFile.Exists(GetSettingsPath) then
    FSettings := TSettings.Create(File_GetText(GetSettingsPath))
  else
    FSettings := TSettings.Create;

  ApplySettings;
end;

function TDPMEngine.GetInitialPackage(
  aDependentPackage: TDependentPackage): TInitialPackage;
begin
  Result := Packages_GetPrivate.GetByID(aDependentPackage.ID);

  if Assigned(Result) then
    Exit(Result);
end;

function TDPMEngine.FindXmlNode(aNode: IXMLNode;
  const aNodeName: string): IXMLNode;
var
  i: Integer;
begin
  Result := nil;
  if not Assigned(aNode) then
    Exit;

  if CompareText(aNode.NodeName, aNodeName) = 0 then
    Result := aNode
  else
    if Assigned(aNode.ChildNodes) then
      for i := 0 to aNode.ChildNodes.Count - 1 do
      begin
        Result := FindXmlNode(aNode.ChildNodes[I], aNodeName);
        if Result <> nil then
          Exit;
      end;
end;

procedure TDPMEngine.FreePackageLists;
begin
  if Assigned(FPrivatePackages) then
    FreeAndNil(FPrivatePackages);
  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);
  if Assigned(FIDEPackages) then
    FreeAndNil(FIDEPackages);
end;

procedure TDPMEngine.FreeVersionCacheList;
begin
  if Assigned(FVersionCacheList) then
    FreeAndNil(FVersionCacheList);
end;

function TDPMEngine.Project_GetActive: IOTAProject;
begin
  Result := GetActiveProject;
end;

function TDPMEngine.Path_GetActiveProject: string;
begin
  Result := TDirectory.GetParent(GetActiveProject.FileName);
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

function TDPMEngine.GetDependentPackage(aPackage: TPackage): TDependentPackage;
begin
  if aPackage is TDependentPackage then
    Result := aPackage as TDependentPackage
  else
  if aPackage is TInitialPackage then
    Result := (aPackage as TInitialPackage).DependentPackage
  else
    raise Exception.Create('unknown package type');
end;

function TDPMEngine.Project_GetDPM: IOTAProject;
var
  ProjectGroup: IOTAProjectGroup;
  i: Integer;
begin
  ProjectGroup := GetProjectGroup;

  for i := 0 to ProjectGroup.ProjectCount - 1 do
    if ProjectGroup.Projects[i].FileName.EndsWith('Apollo_DPM.dproj') then
      Exit(ProjectGroup.Projects[i]);

  raise Exception.Create('Project Apollo_DPM.dproj is not in the project group!');
end;

class function TDPMEngine.Files_Get(const aDirectoryPath, aNamePattern: string): TArray<string>;
var
  Files: TStringDynArray;
  i: Integer;
begin
  Files := TDirectory.GetFiles(aDirectoryPath, aNamePattern, TSearchOption.soAllDirectories);
  Result := [];
  for i := 0 to Length(Files) - 1 do
    Result := Result + [Files[i]];
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDPMEngine.GetIDEPackages: TDependentPackageList;
var
  sJSON: string;
begin
  if not Assigned(FIDEPackages) then
  begin
    if TFile.Exists(GetIDEPackagesPath) then
    begin
      sJSON := TFile.ReadAllText(GetIDEPackagesPath, TEncoding.ANSI);
      FIDEPackages := TDependentPackageList.Create(sJSON, SyncVersionCache);
    end
    else
      FIDEPackages := TDependentPackageList.Create;
  end;

  Result := FIDEPackages;
end;

function TDPMEngine.GetIDEPackagesPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPathIDEPackages);
end;

function TDPMEngine.GetPackagePath(aPackage: TPackage): string;
begin
  if IsProjectOpened then
    Result := TPath.Combine(Path_GetVendors, aPackage.Name)
  else
    Result := '';
end;

function TDPMEngine.Packages_GetPrivate: TPrivatePackageList;
var
  FileArr: TArray<string>;
  FileItem: string;
  PrivatePackageFile: TPrivatePackageFile;
  PrivatePackageFiles: TArray<TPrivatePackageFile>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesFolderPath) then
    begin
      FileArr := Files_Get(GetPrivatePackagesFolderPath, '*.json');
      PrivatePackageFiles := [];
      for FileItem in FileArr do
      begin
        PrivatePackageFile.Path := FileItem;
        PrivatePackageFile.JSONString := File_GetText(FileItem);

        PrivatePackageFiles := PrivatePackageFiles + [PrivatePackageFile];
      end;

      if Length(PrivatePackageFiles) > 0 then
        FPrivatePackages := TPrivatePackageList.Create(PrivatePackageFiles);

      FPrivatePackages.SetDependentPackageRef(Packages_GetProject);
      FPrivatePackages.SetDependentPackageRef(GetIDEPackages);
    end;
  end;

  if not Assigned(FPrivatePackages) then
    FPrivatePackages := TPrivatePackageList.Create([]);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesFolderPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPathPrivatePackagesFolder);
end;

function TDPMEngine.GetProjectGroup: IOTAProjectGroup;
var
  ModuleServices: IOTAModuleServices;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Result := ModuleServices.MainProjectGroup;
end;

function TDPMEngine.Packages_GetProject: TDependentPackageList;
var
  sJSON: string;
begin
  if not Assigned(FProjectPackages) then
  begin
    if TFile.Exists(Path_GetProjectPackages) then
    begin
      sJSON := TFile.ReadAllText(Path_GetProjectPackages, TEncoding.ANSI);
      FProjectPackages := TDependentPackageList.Create(sJSON, SyncVersionCache);
    end
    else
      FProjectPackages := TDependentPackageList.Create;
  end;

  Result := FProjectPackages;
end;

function TDPMEngine.Path_GetProjectPackages: string;
begin
  if IsProjectOpened then
    Result := TPath.Combine(Path_GetActiveProject, cPathProjectPackages)
  else
    Result := '';
end;

function TDPMEngine.GetSettingsPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPathSettings);
end;

class function TDPMEngine.File_GetText(const aPath: string): string;
begin
  Result := TFile.ReadAllText(aPath, TEncoding.ANSI);
end;

function TDPMEngine.Path_GetVendors: string;
begin
  Result := TPath.Combine(TDirectory.GetParent(Path_GetActiveProject), 'Vendors');
end;

function TDPMEngine.GetVersionCacheList: TVersionCacheList;
begin
  if not Assigned(FVersionCacheList) then
    FVersionCacheList := TVersionCacheList.Create;

  Result := FVersionCacheList;
end;

function TDPMEngine.GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
begin
  if (not aCachedOnly) and (not AreVersionsLoaded(aPackage.ID)) then
    LoadRepoVersions(aPackage);

  Result := GetVersionCacheList.GetByPackageID(aPackage.ID);
end;

function TDPMEngine.Action_Install(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
var
  Action: TInstall;
begin
  LockActions;
  Action := TInstall.GetClass(aInitialPackage.PackageType).Create(Self, aInitialPackage, aVersion);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

procedure TDPMEngine.InstallBpl(const aBplPath: string);
var
  FileName: string;
  PackageServices: IOTAPackageServices;
begin
  FileName := TPath.GetFileName(aBplPath);
  FUINotifyProc(Format('installing %s', [FileName]));

  PackageServices := BorlandIDEServices as IOTAPackageServices;
  try
    PackageServices.InstallPackage(aBplPath);
  except
    on E: Exception do
    begin
      if E.Message.Contains(cStrNotDesignTimePackage) then
        FUINotifyProc(Format('%s is not design time package, continue..', [FileName]))
      else
        raise;
    end;
  end;
end;

function TDPMEngine.IsProjectOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
end;

function TDPMEngine.Package_LoadDependencies(aInitialPackage: TInitialPackage; aVersion: TVersion): TDependentPackageList;
var
  DependentPackage: TDependentPackage;
begin
  Result := TDependentPackageList.Create;

  DependentPackage := TDependentPackage.CreateByInitial(aInitialPackage, False);
  try
    DoLoadDependencies(DependentPackage, aVersion, Result);
  finally
    FreeAndNil(DependentPackage);
  end;
end;

function TDPMEngine.Package_LoadDependencies(
  aDependentPackage: TDependentPackage): TDependentPackageList;
var
  DependentPackage: TDependentPackage;
  ID: string;
begin
  Result := TDependentPackageList.Create(False);

  for ID in aDependentPackage.Version.Dependencies do
  begin
    DependentPackage := Packages_GetProject.GetByID(ID);

    if Assigned(DependentPackage) then
      Result.Add(DependentPackage);
  end;
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
    SHA := FGHAPI.GetMasterBranch(URLWords[1], URLWords[2]).SHA;
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

function TDPMEngine.LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
begin
  if aVersion.RepoTreeLoaded then
    Exit(aVersion.RepoTree);

  Result := FGHAPI.GetRepoTree(aPackage.RepoOwner, aPackage.RepoName,
    aVersion.SHA);

  aVersion.RepoTreeLoaded := True;
end;

procedure TDPMEngine.LoadRepoVersions(aPackage: TPackage);

  procedure CreateVersion(const aTag: TTag);
  var
    Version: TVersion;
  begin
    Version := TVersion.Create;
    Version.Assign(aTag);

    SyncVersionCache(aPackage.ID, Version);
  end;

var
  Tag:  TTag;
  Tags: TArray<TTag>;
begin
  Tags := FGHAPI.GetRepoTags(aPackage.RepoOwner, aPackage.RepoName);

  for Tag in Tags do
    CreateVersion(Tag);

  Tag := FGHAPI.GetMasterBranch(aPackage.RepoOwner, aPackage.RepoName);
  CreateVersion(Tag);

  GetVersionCacheList.AddLoadedPackageID(aPackage.ID);
end;

procedure TDPMEngine.LockActions;
begin
  FAreActionsLocked := True;
  FUIActionsLockProc;
end;

function TDPMEngine.ProjectActive_RemoveFile(const aFilePath: string): IOTAProject;
begin
  TThread.Synchronize(nil, procedure()
    begin
      GetActiveProject.RemoveFile(aFilePath);
    end
  );
  Result := GetActiveProject;
end;

function TDPMEngine.RepoPathToFilePath(const aRepoPath: string): string;
var
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := '';
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := TPath.Combine(Result, RepoPathPart);
end;

procedure TDPMEngine.ResetDependentPackage(
  aDependentPackage: TDependentPackage);
var
  InitialPackage: TInitialPackage;
begin
  InitialPackage := GetInitialPackage(aDependentPackage);
  if Assigned(InitialPackage) then
    InitialPackage.DependentPackage := nil;
end;

function TDPMEngine.RunConsole(const aCommand: string): string;
begin
  try
    Result := RunCommandPrompt(aCommand);
  except
    on E: Exception do
      raise Exception.CreateFmt('RunConsole: %s '#13#10'%s', [aCommand, E.Message]);
  end;
end;

procedure TDPMEngine.SaveActiveProject;
begin
  TThread.Synchronize(nil, procedure()
    begin
      GetActiveProject.Save(False, True);
    end
  );
end;

function TDPMEngine.SaveAsPrivatePackage(aPackage: TInitialPackage): string;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Result := TPath.Combine(GetPrivatePackagesFolderPath, aPackage.Name + '.json');

  WriteFile(Result, Bytes);
end;

function TDPMEngine.SaveContent(const aPackagePath, aRepoPath,
  aContent: string): string;
var
  Bytes: TBytes;
begin
  Result := TPath.Combine(aPackagePath, RepoPathToFilePath(aRepoPath));
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  WriteFile(Result, Bytes);

  FUINotifyProc('writing ' + Result);
end;

procedure TDPMEngine.SavePackageList(const aPath: string;
  aPackageList: TDependentPackageList);
var
  Bytes: TBytes;
begin
  if (aPackageList.Count = 0) and TFile.Exists(aPath) then
    TFile.Delete(aPath)
  else
  begin
    Bytes := TEncoding.ANSI.GetBytes(aPackageList.GetJSONString);
    WriteFile(aPath, Bytes);
  end;
end;

procedure TDPMEngine.SavePackages;
begin
  if IsProjectOpened then
    SavePackageList(Path_GetProjectPackages, Packages_GetProject);

  SavePackageList(GetIDEPackagesPath, GetIDEPackages);
end;

function TDPMEngine.Project_SetActive(aProject: IOTAProject): IOTAProject;
var
  ProjectGroup: IOTAProjectGroup;
begin
  ProjectGroup := GetProjectGroup;

  if ProjectGroup.ActiveProject <> aProject then
  begin
    ProjectGroup.SetActiveProject(aProject);
    FreePackageLists;
  end;

  Result := aProject;
end;

procedure TDPMEngine.ApplyAndSaveSettings;
var
  Bytes: TBytes;
begin
  ApplySettings;

  Bytes := TEncoding.ANSI.GetBytes(FSettings.GetJSONString);
  WriteFile(GetSettingsPath, Bytes);
end;

procedure TDPMEngine.ApplySettings;
begin
  FGHAPI.SetGHPAToken(FSettings.GHPAToken);
end;

function TDPMEngine.ShowConflictForm(const aCaption: string;
  aVersionConflicts: TVersionConflicts): TVersionConflicts;
var
  ConflictForm: TConflictForm;
begin
  Result := [];

  ConflictForm := TConflictForm.Create(aCaption, DPMForm, aVersionConflicts);
  try
    if ConflictForm.ShowModal = mrOK then
      Result := ConflictForm.GetResult
    else
      Abort;
  finally
    ConflictForm.Free;
  end;
end;

procedure TDPMEngine.ShowFirstModule;
var
  i: Integer;
  ProjectModuleInfo: IOTAModuleInfo;
begin
  for i := 0 to GetActiveProject.GetModuleCount - 1 do
  begin
    ProjectModuleInfo := GetActiveProject.GetModule(i) as IOTAModuleInfo;
    if TPath.GetExtension(ProjectModuleInfo.FileName).ToLower = '.pas' then
      begin
        ProjectModuleInfo.OpenModule.Show;
        Break;
      end;
  end;
end;

function TDPMEngine.Action_Uninstall(aPackage: TPackage): TPackageHandles;
var
  Action: TUninstall;
  DependentPackage: TDependentPackage;
begin
  LockActions;
  DependentPackage := GetDependentPackage(aPackage);
  Action := TUninstall.GetClass(DependentPackage.PackageType).Create(Self, DependentPackage);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

procedure TDPMEngine.UninstallBpl(const aBplPath: string);
var
  PackageServices: IOTAPackageServices;
begin
  FUINotifyProc(Format('uninstalling %s', [TPath.GetFileName(aBplPath)]));

  PackageServices := BorlandIDEServices as IOTAPackageServices;
  PackageServices.UninstallPackage(aBplPath);
end;

procedure TDPMEngine.UnlockActions;
begin
  FUIActionsUnlockProc;
  FAreActionsLocked := False;
end;

function TDPMEngine.Action_Update(aPackage: TPackage; aVersion: TVersion): TPackageHandles;
var
  Action: TUpdate;
  DependentPackage: TDependentPackage;
begin
  LockActions;
  DependentPackage := GetDependentPackage(aPackage);
  Action := TUpdate.GetClass(DependentPackage.PackageType).Create(Self, DependentPackage, aVersion);
  try
    Action.TestMode := TestMode;
    Result := Action.Run;
  finally
    Action.Free;
    UnlockActions;
  end;
end;

procedure TDPMEngine.UpdatePrivatePackage(aPackage: TPrivatePackage);
begin
  TFile.Delete(aPackage.FilePath);
  aPackage.FilePath := SaveAsPrivatePackage(aPackage);
end;

function TDPMEngine.SyncVersionCache(const aPackageID: string; aVersion: TVersion): TVersion;
begin
  Result := GetVersionCacheList.SyncVersion(aPackageID, aVersion);
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
