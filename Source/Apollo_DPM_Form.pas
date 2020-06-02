unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.WinXCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls;

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
    procedure pnlDetailSwitcherClick(Sender: TObject);
  private
  public
  end;

var
  DPMForm: TDPMForm;

implementation

{$R *.dfm}

procedure TDPMForm.pnlDetailSwitcherClick(Sender: TObject);
begin
  swPackageDetail.Opened := swPackageDetail.Opened <> True;
end;

end.
