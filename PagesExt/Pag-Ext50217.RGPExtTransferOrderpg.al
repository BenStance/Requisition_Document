namespace BCEXPERTROAD.BCEXPERTROAD;

using Microsoft.Purchases.Document;
using Microsoft.Inventory.Transfer;

pageextension 50217 RGPTransferOrderExt extends "Transfer Order"
{
    layout
    {
        addlast(General)
        {
            field("Request No."; Rec."RGP Request No.")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Request Date"; Rec."Request Date")
            {
                ApplicationArea = All;
                Editable = false; 
            }
        }
    }
}
