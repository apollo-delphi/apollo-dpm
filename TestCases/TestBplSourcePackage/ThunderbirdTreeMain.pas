(*
    
    Quick and Dirty component that looks like thunderbird's
    settings having nested panels inside a treelike structure.
        
    Hope you can use it, i do :))

    If you have some ideas regarding this topic do not hesitate to
    build upon this component, just give me a mail what you
    have done (i.janevski@gmail.com)

    Igor Janevski, MSCS

*)

unit ThunderbirdTreeMain;

interface

uses
  messages, windows, SysUtils, Classes, Controls, ComCtrls, Forms, ExtCtrls,
  graphics, stdctrls,dialogs;

type
  TThunderbirdTree = class;

  TThunderbirdSection = class
    private
      fList : Tlist;
      fOwner : TThunderbirdTree;
      fParent : TThunderbirdSection;
      fCaption: String;
      fPanel : TPanel;
      fImage : TImage;
      fExpanded : boolean;
      fHeaderPanel,fContentPanel : TPanel;
      fLeftPanel,fRightPanel : TPanel;

      procedure CreatePanel;
      procedure CreateLabel;
      function getCount: integer;
      function getItem(index: integer): tthunderbirdsection;
      procedure ExpandClick(Sender : TObject);

      function getPreferedHeight : integer;

      procedure RealignAll;

    public
      procedure Contract;
      procedure Expand;
      property Content : TPanel read fRightPanel;
      procedure HeadersVisible(yesNo : boolean);
      procedure Clear;
      procedure Delete(index : integer);
      property Count : integer read getCount;
      property Item[index : integer] : tthunderbirdsection read getItem;default;
      property Caption : String read fCaption;

      function Add(Caption : string) : tthunderbirdsection;

      constructor Create(Owner : TThunderbirdTree;Parent : TThunderbirdSection);virtual;
      destructor Destroy;override;
  end;

  TThunderbirdTree = class(TPanel)
  private
    { Private declarations }
    fRoot : TThunderbirdSection;
    FBorderStyle: TBorderStyle;
    fImageList : TImageList;
    fShowHeaders: Boolean;

    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure setHeadersVisible(const Value: Boolean);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    { Protected declarations }
    procedure Autosize;
  public
    { Public declarations }
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    constructor Create(Aowner : TComponent);override;
    destructor Destroy;override;
    function AddSection(Caption : String) : TThunderbirdSection;
    procedure AttachControl(Section : TThunderbirdSection;Control : TControl;Expand : boolean = false);
  published
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property Font;
    property ShowHeaders : Boolean read fShowHeaders write setHeadersVisible;
  end;

procedure Register;

{$R Treeview.RES}

implementation

procedure Register;
begin
  RegisterComponents('DH Components', [TThunderbirdTree]);
end;

{ TThunderbirdTree }

function TThunderbirdTree.AddSection(Caption: String): TThunderbirdSection;
begin
    result := fRoot.Add(caption);
    Autosize;
end;

procedure TThunderbirdTree.AttachControl(Section: TThunderbirdSection;
  Control: TControl;Expand : boolean);
begin
    section.content.Tag := control.Height;
    control.Parent := section.Content;
    control.Align := alClient;
    if Expand then
       Section.Expand;
end;

procedure TThunderbirdTree.Autosize;
var
   sz,i : integer;
begin
      sz := 0;
      for i := 0 to froot.Count-1 do
          sz := sz + fRoot.Item[i].fPanel.Height;
      Height := sz;
end;

constructor TThunderbirdTree.Create(Aowner: TComponent);
var
   bmp : TBitmap;
begin
  FBorderStyle := bsSingle;
  inherited;
  fShowHeaders := false;
  froot := TThunderbirdSection.Create(self,nil);
  Color := clWhite;
  fImageList := TImageList.Create(self);
  fImageList.Width := 9;
  fImageList.Height := 9;

  bmp := tbitmap.create;
  bmp.LoadFromResourceName(HInstance,'PLUSBMP');
  fImageList.Add(bmp,nil);
  bmp.LoadFromResourceName(HInstance,'MINUSBMP');
  fImageList.Add(bmp,nil);
  freeandnil(bmp);
  //DoubleBuffered := true;

end;

procedure TThunderbirdTree.CreateParams(var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    Style := Style or BorderStyles[FBorderStyle];
    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

destructor TThunderbirdTree.Destroy;
begin
  FreeAndNil(froot);
  inherited;
end;

procedure TThunderbirdTree.SetBorderStyle(const Value: TBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TThunderbirdTree.setHeadersVisible(const Value: Boolean);
begin
  if fShowHeaders <> value then
     fRoot.HeadersVisible(value);
  fShowHeaders := Value;
end;

procedure TThunderbirdTree.WMPaint(var Message: TWMPaint);
begin
    inherited;
end;

{ TThunderbirdSection }

function TThunderbirdSection.Add(Caption: string): tthunderbirdsection;
begin
    result := TThunderbirdSection.Create(fowner,self);
    result.fCaption := caption;
    flist.add(result);
    result.CreatePanel;
end;

procedure TThunderbirdSection.Clear;
begin
    while count > 0 do
       delete(0);
end;

procedure TThunderbirdSection.Contract;
begin
    fExpanded := false;
    fOwner.fImageList.GetBitmap(0,fImage.Picture.Bitmap);
    fImage.Invalidate;
    if fParent.fparent <> nil then
       fParent.fPanel.Height := fParent.getPreferedHeight;
    fPanel.Height := getPreferedHeight;
    fOwner.Autosize;
    fowner.froot.RealignAll;;
end;

constructor TThunderbirdSection.Create(Owner: TThunderbirdTree;
  Parent: TThunderbirdSection);
begin
    fList := TList.create;
    fParent := Parent;
    fOwner := Owner;
    fExpanded := false;
    
end;

procedure TThunderbirdSection.CreateLabel;
var
   _label : tlabel;
begin
      _label := TLabel.Create(fHeaderPanel);
      _label.Parent := fHeaderPanel;
      _label.caption := fCaption;
      _label.Left := 20;
      _label.Visible := true;
      _label.Top := (fHeaderPanel.Height - _label.height) div 2;
      _label.OnClick := ExpandClick;
      _label.cursor := crHandPoint;
      _label.Font.style := [fsBold];

      fImage := TImage.Create(fHeaderPanel);
      fImage.Parent := fHeaderPanel;
      fImage.autosize := true;

      fOwner.fImageList.GetBitmap(0,fImage.Picture.Bitmap);
      fImage.Top := (fHeaderPanel.Height - fimage.height) div 2;
      fImage.left := 5;
      fImage.cursor := crHandPoint;
      fImage.OnClick := ExpandClick;


end;

procedure TThunderbirdSection.CreatePanel;
begin
    fPanel := TPanel.Create(nil);
    if fParent.fParent = nil then
       begin
         fpanel.Parent := fOwner;
       end else
       fpanel.Parent := fParent.Content;

    fpanel.Top := high(integer)-1;
    fpanel.Align := alTop;
    fpanel.Color := fowner.Color;
    fpanel.BevelInner := bvNone;
    fpanel.bevelOuter := bvNone;
    fpanel.BorderStyle := bsNone;
    fpanel.Height := 20;
    //fPanel.DoubleBuffered := true;

    fHeaderPanel := TPanel.Create(fPanel);
    fHeaderPanel.Parent := fPanel;
    fHeaderPanel.Height := 20;
    fHeaderPanel.Align := alTop;
    fHeaderPanel.OnClick := ExpandClick;
    //fheaderpanel.DoubleBuffered := true;

    if not (fOwner.fShowHeaders) then
       begin
        fHeaderPanel.BevelInner := bvNone;
        fHeaderPanel.bevelOuter := bvNone;
        fHeaderPanel.Color := clWhite;
       end;

    fContentPanel := TPanel.Create(fpanel);
    fContentPanel.parent := fpanel;
    fContentPanel.Align := alClient;
    fContentPanel.BevelInner := bvNone;
    fContentPanel.bevelOuter := bvNone;
    fContentPanel.Color := clWhite;
    //fContentPanel.DoubleBuffered := true;

    fLeftPanel := TPanel.Create(fContentPanel);
    fLeftPanel.parent := fContentPanel;
    fLeftPanel.width := 20;
    fLeftPanel.Align := alLeft;
    fLeftPanel.BevelInner := bvNone;
    fLeftPanel.bevelOuter := bvNone;
    fLeftPanel.Color := clWhite;
    //fLeftPanel.DoubleBuffered := true;

    fRightPanel := TPanel.Create(fContentPanel);
    fRightPanel.parent := fContentPanel;
    fRightPanel.Align := alCLient;
    fRightPanel.BevelInner := bvNone;
    fRightPanel.bevelOuter := bvNone;
    fRightPanel.Color := clWhite;
    //fRightPanel.DoubleBuffered := true;

    CreateLabel;



end;

procedure TThunderbirdSection.Delete(index: integer);
begin
    TThunderbirdSection(flist[index]).free;
    flist.delete(index);
end;

destructor TThunderbirdSection.Destroy;
begin
  clear;
  FreeAndNil(fpanel);
  inherited;
end;

procedure TThunderbirdSection.Expand;
begin
    fExpanded := true;
    fOwner.fImageList.GetBitmap(1,fImage.Picture.Bitmap);
    fImage.Invalidate;
    if fParent.fparent <> nil then
       fParent.fPanel.Height := fParent.getPreferedHeight;
    fPanel.Height := getPreferedHeight;
    fOwner.Autosize;
    fowner.froot.RealignAll;
end;

procedure TThunderbirdSection.ExpandClick(Sender: TObject);
begin
      if fExpanded then
         Contract else
         Expand;
end;

function TThunderbirdSection.getCount: integer;
begin
      result := flist.count;
end;

function TThunderbirdSection.getItem(index: integer): tthunderbirdsection;
begin
      result := TThunderbirdSection(flist[index]);
end;


function TThunderbirdSection.getPreferedHeight: integer;
var
   i : integer;
begin
      result := 20;
      if not fExpanded then exit;
      if (count = 0) and (fexpanded) then result := result + Content.tag;
      for i := 0 to count-1 do
          result := result + Item[i].getPreferedHeight;
end;

procedure TThunderbirdSection.HeadersVisible(yesNo: boolean);
var
   i : integer;
begin
      if fHeaderPanel <> nil then
      begin
      if yesNo then
         begin
            fHeaderPanel.BevelInner := bvNone;
            fHeaderPanel.bevelOuter := bvRaised;
            fHeaderPanel.Color := clBtnFace;
         end else
         begin
            fHeaderPanel.BevelInner := bvNone;
            fHeaderPanel.bevelOuter := bvNone;
            fHeaderPanel.Color := clWhite;
         end;
      end;
      for i := 0 to count-1 do
          Item[i].HeadersVisible(yesno);
end;


procedure TThunderbirdSection.RealignAll;
var
   i : integer;

begin
      if fpanel <> nil then
         fPanel.Realign;
      for i := 0 to count-1 do
          Item[i].RealignAll;
end;

end.
