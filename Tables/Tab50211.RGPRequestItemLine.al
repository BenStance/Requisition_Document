table 50211 "RGP Request Item Line"
{
    Caption = 'RGP Request Item Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = 'Request No.';
            TableRelation = "RGP Request Header"."Request No.";
            DataClassification = ToBeClassified;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(3; "Type"; Enum RGPLineTypesenum)
        {
            Caption = 'Type';
            DataClassification = ToBeClassified;
        }

        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation =
                if (Type = const(Item)) Item."No.";
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                Item: Record Item;

            begin
                Description := '';
                "Unit of Measure Code" := '';

                case Type of
                    Type::Item:
                        if Item.Get("No.") then begin
                            Description := Item.Description;
                            "Unit of Measure Code" := Item."Base Unit of Measure";
                        end;
                end;
                UpdateInventoryQuantities();
            end;
        }

        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }

        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                UpdateInventoryQuantities();
            end;
        }

        field(7; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation =
                if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure".Code;
            DataClassification = ToBeClassified;

        }

        field(8; "Location Current Qty"; Decimal)
        {
            Caption = 'Location Current Qty';
            Editable = false;
            DecimalPlaces = 0 : 5;
        }

        field(9; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;
            MinValue = 0;
        }
        field(10; "Request From Current Qty"; Decimal)
        {
            Caption = 'Request From Current Qty';
            Editable = false;
            DecimalPlaces = 0 : 5;
        }

        field(11; "Approved Qty"; Decimal)
        {
            Caption = 'Approved Qty';
            DataClassification = ToBeClassified;
        }

        field(16; "Comments"; Text[250])
        {
            Caption = 'Comments';
            DataClassification = ToBeClassified;
        }


    }

    keys
    {
        key(PK; "Request No.", "Line No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    var
        RGPRequestLine: Record "RGP Request Item Line";
        RGPHeader: Record "RGP Request Header";
    begin
        // ==============================
        // Generate Line No.
        // ==============================
        if "Line No." = 0 then begin
            RGPRequestLine.SetRange("Request No.", "Request No.");
            if RGPRequestLine.FindLast() then
                "Line No." := RGPRequestLine."Line No." + 10000
            else
                "Line No." := 10000;
        end;

        // ==============================
        // Default Location from Header
        // ==============================
        if RGPHeader.Get("Request No.") then
            if RGPHeader."Transfer-to Code" <> '' then
                Validate("Location Code", RGPHeader."Transfer-to Code");
    end;

    local procedure UpdateInventoryQuantities()
    var
        ItemRec: Record Item;
        RGPHeader: Record "RGP Request Header";
    begin
        "Location Current Qty" := 0;
        "Request From Current Qty" := 0;

        if Type <> Type::Item then
            exit;

        if not ItemRec.Get("No.") then
            exit;

        // ================================
        // 1️⃣ Location Current Qty
        // ================================
        if "Location Code" <> '' then begin
            ItemRec.SetRange("Location Filter", "Location Code");
            ItemRec.CalcFields(Inventory);
            "Location Current Qty" := ItemRec.Inventory;
        end;

        // ================================
        // 2️⃣ Request From Current Qty
        // (From Header Transfer-from Code)
        // ================================
        if RGPHeader.Get("Request No.") then
            if RGPHeader."Transfer-from Code" <> '' then begin
                ItemRec.Reset();
                ItemRec.SetRange("Location Filter", RGPHeader."Transfer-from Code");
                ItemRec.CalcFields(Inventory);
                "Request From Current Qty" := ItemRec.Inventory;
            end;
    end;

}