namespace BC.BC;

using Microsoft.Inventory.Transfer;

tableextension 50215 RGPExtTransferOrder extends "Transfer Header"
{
    fields
    {
        field(50213; "RGP Request No."; Code[20])
        {
            Caption = 'Request No.';
            DataClassification = ToBeClassified;
        }
         field(50214; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            DataClassification = ToBeClassified;
        }
        field(50215; "Request Date"; Date)
        {
            Caption = 'Request Date';
            DataClassification = ToBeClassified;
        }
    }
}
