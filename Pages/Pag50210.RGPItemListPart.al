page 50210 "RGP Request Item Subform"
{
    Caption = 'RGP Request Subform';
    PageType = ListPart;
    SourceTable = "RGP Request Item Line";
    SourceTableView = sorting("Request No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Type;Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of line (G/L Account, Item, or Fixed Asset).';
                    Editable = IsEditable;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the G/L Account, Item, or Fixed Asset.';
                    Editable = IsEditable;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the item.';
                    Editable = IsEditable;
                }
                
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure code.';
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity requested.';
                    Editable = IsEditable;
                    caption = 'Requested Qty.';
                }
                field("Location Current Qty"; Rec."Location Current Qty")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current quantity in the location.';
                    Editable = false;
                    caption = 'Current Qty.';
                }
                field("Request From Current Qty"; Rec."Request From Current Qty")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current quantity from the request.';
                    Editable = false;
                    caption = 'Available Qty.';
                }
                field("Approved Qty"; Rec."Approved Qty")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the approved quantity.';
                    Editable = IsEditable;
                    caption = 'Approved Qty.';
                }
                
                field(Comments;Rec.Comments){
                    ApplicationArea=All;
                    ToolTip='Specifies the comments.';
                    Editable=IsEditable;
                }                
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetEditable();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetEditable();
    end;

    local procedure SetEditable()
    var
        RGPRequestHeader: Record "RGP Request Header";
    begin
        if RGPRequestHeader.Get(Rec."Request No.") then
            IsEditable := RGPRequestHeader.Status = RGPRequestHeader.Status::Open
        else
            IsEditable := true;
    end;

    var
        IsEditable: Boolean;
}