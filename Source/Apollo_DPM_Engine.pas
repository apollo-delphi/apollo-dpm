unit Apollo_DPM_Engine;

interface

uses
  ToolsAPI,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    procedure BuildMenu;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
  public
    constructor Create;
    destructor Destroy; override;
  end;

const
  cApolloMenuItemCaption = 'Apollo';
  cApolloMenuItemName = 'miApollo';
  cDPMMenuItemCaption = 'DPM - Delphi Package Manager...';

implementation

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

end.
