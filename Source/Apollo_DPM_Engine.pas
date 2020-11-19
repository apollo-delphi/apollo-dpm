unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_Package,
  System.SysUtils,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetPrivatePackagesPath: string;
    procedure BuildMenu;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure DPMMenuItemClick(Sender: TObject);
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
  public
    procedure SavePackage(aPackage: TPackage);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  System.Classes,
  System.JSON,
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

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create;
begin
  BuildMenu;
end;

destructor TDPMEngine.Destroy;
begin
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

function TDPMEngine.GetPrivatePackagesPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPrivatePackagesPath);
end;

procedure TDPMEngine.SavePackage(aPackage: TPackage);
var
  Bytes: TBytes;
  jsnPackageObj: TJSONObject;

  s: string;
begin
  jsnPackageObj := aPackage.CreateJSON;
  try
    Bytes := TEncoding.ANSI.GetBytes(jsnPackageObj.ToJSON);

    s := TPath.Combine(GetPrivatePackagesPath, aPackage.Name + '.json');

    WriteFile(s, Bytes);
  finally
    jsnPackageObj.Free;
  end;
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
