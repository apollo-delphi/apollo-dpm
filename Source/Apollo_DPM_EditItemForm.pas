unit Apollo_DPM_EditItemForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TEditItem = record
  public
    Key: string;
    Value: string;
    constructor Create(const aEditLabel, aEditValue: string);
  end;

  TEditItems = TArray<TEditItem>;

  TEditItemsHelper = record helper for TEditItems
    function ValueByKey(const aKey: string): string;
  end;

  TItemEditValidFunc = function(const aOutItems: TEditItems; aOutput: TLabel): Boolean of object;

  TItemEditForm = class(TForm)
    leTemplate: TLabeledEdit;
    btnOK: TButton;
    btnCancel: TButton;
    lblValidationMsg: TLabel;
    procedure btnOKClick(Sender: TObject);
  private
    FControls: TArray<TLabeledEdit>;
    FInItems: TEditItems;
    FValidFunc: TItemEditValidFunc;
    function GetOutItems: TEditItems;
    procedure Init(const aInItems: TEditItems);
  public
    class function Open(aOwner: TComponent; const aCaption: string;
      const aInItems: TEditItems; aValidFunc: TItemEditValidFunc;
      out aOutItems: TEditItems): Boolean;
  end;

var
  ItemEditForm: TItemEditForm;

implementation

{$R *.dfm}

{ TItemEditForm }

procedure TItemEditForm.btnOKClick(Sender: TObject);
begin
  if (not Assigned(FValidFunc)) or
     (FValidFunc(GetOutItems, lblValidationMsg))
  then
    ModalResult := mrOk;
end;

function TItemEditForm.GetOutItems: TEditItems;
var
  i: Integer;
begin
  Result := [];

  for i := 0 to Length(FInItems) - 1 do
    Result := Result + [TEditItem.Create(FInItems[i].Key, FControls[i].Text)];
end;

procedure TItemEditForm.Init(const aInItems: TEditItems);
const
  cNextControlShift = 2;
var
  i: Integer;
  Item: TEditItem;
  LabeledEdit: TLabeledEdit;
  Shift: Integer;
begin
  FControls := [];
  FInItems := aInItems;
  Shift := 0;

  for i := 0 to Length(FInItems) - 1 do
  begin
    Item := FInItems[i];

    LabeledEdit := TLabeledEdit.Create(Self);
    LabeledEdit.Parent := Self;
    LabeledEdit.Top := leTemplate.Top + Shift;
    LabeledEdit.Left := leTemplate.Left;
    LabeledEdit.Width := leTemplate.Width;
    LabeledEdit.LabelPosition := leTemplate.LabelPosition;

    LabeledEdit.EditLabel.Caption := Item.Key;
    LabeledEdit.Text := Item.Value;

    FControls := FControls + [LabeledEdit];

    if i < High(aInItems) then
      Shift := Shift + LabeledEdit.Height + cNextControlShift;
  end;

  Height := Height + Shift;
  btnOK.Top := btnOK.Top + Shift;
  btnCancel.Top := btnCancel.Top + Shift;
end;

class function TItemEditForm.Open(aOwner: TComponent; const aCaption: string;
  const aInItems: TEditItems; aValidFunc: TItemEditValidFunc;
  out aOutItems: TEditItems): Boolean;
begin
  ItemEditForm := TItemEditForm.Create(aOwner);
  try
    ItemEditForm.Caption := aCaption;
    ItemEditForm.Init(aInItems);
    ItemEditForm.FValidFunc := aValidFunc;
    Result := ItemEditForm.ShowModal = mrOk;
    if Result then
      aOutItems := ItemEditForm.GetOutItems;
  finally
    ItemEditForm.Free;
  end;
end;

{ TEditItem }

constructor TEditItem.Create(const aEditLabel, aEditValue: string);
begin
  Key := aEditLabel;
  Value := aEditValue;
end;

{ TEditItemsHelper }

function TEditItemsHelper.ValueByKey(const aKey: string): string;
var
  Item: TEditItem;
begin
  Result := '';

  for Item in Self do
    if Item.Key = aKey then
      Exit(Item.Value);
end;

end.
