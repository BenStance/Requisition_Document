table 50210 "RGP Request Header"
{
    Caption = 'RGP Request Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = 'Request No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Request No." <> xRec."Request No." then begin
                    PurchasesPayablesSetup.Get();
                    NoSeriesMgt.TestManual(PurchasesPayablesSetup."RFQ");
                    "Request No." := '';
                end;
            end;
        }

        field(2; "Request Date"; Date)
        {
            Caption = 'Request Date';
        }

        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionMembers = Purchase,Transfer;
            OptionCaption = 'Purchase,Transfer';
        }

        field(4; Status; Enum "RGPStatusenum")
        {
            Caption = 'Status';
            Editable = false;
        }

        field(5; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            Editable = false;
        }

        // ===============================
        // PURCHASE HEADER FIELDS
        // ===============================

        field(6; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";

            trigger OnValidate()
            var
                VendorRec: Record Vendor;
            begin
                if VendorRec.Get("Vendor No.") then
                    "Vendor Name" := VendorRec.Name
                else
                    "Vendor Name" := '';
            end;
        }

        field(7; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            Editable = false;
        }

        // ===============================
        // TRANSFER HEADER FIELDS
        // ===============================

        field(8; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location.Code;
        }

        field(9; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location.Code;
        }

        field(10; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location.Code where("Use As In-Transit" = const(true));
        }

        field(11; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
        }

        // ===============================
        // DIMENSIONS
        // ===============================

        field(12; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code
                where("Global Dimension No." = const(1),
                      Blocked = const(false));
        }

        field(13; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code
                where("Global Dimension No." = const(2),
                      Blocked = const(false));
        }

        field(14; Comments; Text[250])
        {
            Caption = 'Comments';
        }

        field(15; "Expected Date"; Date)
        {
            Caption = 'Expected Date';
        }

        field(16; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }

        // ===============================
        // CREATED DOCUMENT REFERENCES
        // ===============================

        field(17; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            Editable = false;
            TableRelation = "Purchase Header"."No."
                where("Document Type" = const(Order));
        }

        field(18; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            Editable = false;
            TableRelation = "Transfer Header"."No.";
        }

        field(19; "Approval Status"; Option)
        {
            Caption = 'Approval Status';
            OptionMembers = Open,"Pending Approval",Approved,Rejected;
            OptionCaption = 'Open,Pending Approval,Approved,Rejected';
            Editable = false;
        }
        field(20; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center".Code;

            trigger OnValidate()
            begin
                UpdateDimensionsFromRespCenter();
            end;
        }
    }

    keys
    {
        key(PK; "Request No.")
        {
            Clustered = true;
        }
    }

    var
        NoSeriesMgt: Codeunit "No. Series";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        StatusChanged: Boolean;

    trigger OnInsert()
    var
        UserSetup: Record "User Setup";
    begin
        if "Request No." = '' then begin
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.TestField("RFQ");

            "No. Series" := PurchasesPayablesSetup."RFQ";
            "Request No." := NoSeriesMgt.GetNextNo("No. Series", Today(), true);
            "Request Date" := Today();
            Status := Status::Open;
        end;

        if UserSetup.Get(UserId()) then begin
            "Requested By" := UserSetup."User ID";
            "Responsibility Center" := UserSetup."Purchase Resp. Ctr. Filter";
        end;

        // Apply dimensions if RC exists
        if "Responsibility Center" <> '' then
            UpdateDimensionsFromRespCenter();
    end;

    trigger OnModify()
    begin
        if xRec.Status <> Rec.Status then
            StatusChanged := true;

        if StatusChanged then
            StatusChanged := false;
    end;

    local procedure UpdateDimensionsFromRespCenter()
    var
        DefaultDim: Record "Default Dimension";
        DimValue: Record "Dimension Value";
        RespCenter: Record "Responsibility Center";
    begin
        if "Responsibility Center" = '' then
            exit;

        // ===============================
        // GET RESPONSIBILITY CENTER
        // ===============================
        if RespCenter.Get("Responsibility Center") then begin

            // Default Transfer-to Location from RC
            if RespCenter."Location Code" <> '' then
                "Transfer-to Code" := RespCenter."Location Code";
                Validate("Transfer-to Code", RespCenter."Location Code");
        end;

        // ===============================
        // GLOBAL DIMENSION 1
        // ===============================
        DefaultDim.Reset();
        DefaultDim.SetRange("Table ID", Database::"Responsibility Center");
        DefaultDim.SetRange("No.", "Responsibility Center");
        DefaultDim.SetRange("Dimension Code", GetGlobalDimCode(1));

        if DefaultDim.FindFirst() then
            if DimValue.Get(DefaultDim."Dimension Code", DefaultDim."Dimension Value Code") then
                if not DimValue.Blocked then
                    "Shortcut Dimension 1 Code" := DefaultDim."Dimension Value Code";

        // ===============================
        // GLOBAL DIMENSION 2
        // ===============================
        DefaultDim.Reset();
        DefaultDim.SetRange("Table ID", Database::"Responsibility Center");
        DefaultDim.SetRange("No.", "Responsibility Center");
        DefaultDim.SetRange("Dimension Code", GetGlobalDimCode(2));

        if DefaultDim.FindFirst() then
            if DimValue.Get(DefaultDim."Dimension Code", DefaultDim."Dimension Value Code") then
                if not DimValue.Blocked then
                    "Shortcut Dimension 2 Code" := DefaultDim."Dimension Value Code";
    end;

    local procedure GetGlobalDimCode(GlobalDimNo: Integer): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();

        case GlobalDimNo of
            1:
                exit(GLSetup."Global Dimension 1 Code");
            2:
                exit(GLSetup."Global Dimension 2 Code");
        end;
    end;
}