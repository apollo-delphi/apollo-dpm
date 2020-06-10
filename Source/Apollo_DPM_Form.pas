unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.WinXCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, System.ImageList, Vcl.ImgList, Vcl.Menus, Vcl.Buttons,
  System.Actions, Vcl.ActnList;

type
  TDPMForm = class(TForm)
    swPackageDetail: TSplitView;
    reActionLog: TRichEdit;
    splHorizontal: TSplitter;
    pnlMainContainer: TPanel;
    pnlMain: TPanel;
    tvNavigation: TTreeView;
    splVertical: TSplitter;
    sbPackages: TScrollBox;
    pnlPackages: TPanel;
    pnlButtons: TPanel;
    pnlDetailSwitcher: TPanel;
    ilIcons: TImageList;
    btnSwitcher: TSpeedButton;
    alActions: TActionList;
    actSwitchPackageDetail: TAction;
    procedure pnlDetailSwitcherClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure swPackageDetailOpened(Sender: TObject);
    procedure swPackageDetailClosed(Sender: TObject);
    procedure tvNavigationCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
  private
    //procedure SaveLayout(const aControls: TArray<TWinControl>);
    procedure RenderNavigation;
  public
    constructor Create; reintroduce;
  end;

var
  DPMForm: TDPMForm;

const
  cSwitchToLeftIconIndex = 0;
  cSwitchToRightIconIndex = 1;

  cSettings = 'Settings';

implementation

{$R *.dfm}

constructor TDPMForm.Create;
begin
  inherited Create(nil);

  RenderNavigation;
end;

procedure TDPMForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //SaveLayout([Self, splHorizontal, splVertical, swPackageDetail]);
end;

procedure TDPMForm.pnlDetailSwitcherClick(Sender: TObject);
begin
  swPackageDetail.Opened := swPackageDetail.Opened <> True;
end;

procedure TDPMForm.RenderNavigation;
begin
  tvNavigation.Items.Add(nil, 'Test item');
  tvNavigation.Items.Add(nil, cSettings);
end;

procedure TDPMForm.swPackageDetailClosed(Sender: TObject);
begin
  actSwitchPackageDetail.ImageIndex := cSwitchToLeftIconIndex;
end;

procedure TDPMForm.swPackageDetailOpened(Sender: TObject);
begin
  actSwitchPackageDetail.ImageIndex := cSwitchToRightIconIndex;
end;

procedure TDPMForm.tvNavigationCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Rect: TRect;
begin
  DefaultDraw := False;

  if cdsSelected in State then
    begin
      Sender.Canvas.Brush.Color := clHighlight;
      Sender.Canvas.Font.Color := clHighlightText;
    end
  else
    begin
      Sender.Canvas.Brush.Color := clWindow;
      Sender.Canvas.Font.Color := clWindowText;
    end;

  Rect := Node.DisplayRect(False);
  Sender.Canvas.FillRect(Rect);

  Rect := Node.DisplayRect(True);
  Sender.Canvas.TextOut(Rect.Left, Rect.Top, Node.Text);
end;

{procedure TDPMForm.SaveLayout(const aControls: TArray<TWinControl>);
begin
end;}

end.
