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
  private
    //procedure SaveLayout(const aControls: TArray<TWinControl>);
  public
  end;

var
  DPMForm: TDPMForm;

const
  cSwitchToRightIconIndex = 0;
  cSwitchToLeftIconIndex = 1;

implementation

{$R *.dfm}

procedure TDPMForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //SaveLayout([Self, splHorizontal, splVertical, swPackageDetail]);
end;

procedure TDPMForm.pnlDetailSwitcherClick(Sender: TObject);
begin
  swPackageDetail.Opened := swPackageDetail.Opened <> True;
end;

procedure TDPMForm.swPackageDetailClosed(Sender: TObject);
begin
  actSwitchPackageDetail.ImageIndex := cSwitchToLeftIconIndex;
end;

procedure TDPMForm.swPackageDetailOpened(Sender: TObject);
begin
  actSwitchPackageDetail.ImageIndex := cSwitchToRightIconIndex;
end;

{procedure TDPMForm.SaveLayout(const aControls: TArray<TWinControl>);
begin
end;}

end.
