codeunit 50212 "RGP Request to PO/TO"
{
    TableNo = "RGP Request Header";

    trigger OnRun()

    begin
        OnBeforeRun(Rec);

        Rec.TestField(Status, Rec.Status::Open);//for debbaging time its Open but should be Approved

        case Rec.Type of
            Rec.Type::Purchase:
                HandlePurchaseOrder(Rec);

            Rec.Type::Transfer:
                HandleTransferOrder(Rec);
        end;

        OnAfterRun(Rec);
    end;

    // ==========================================================
    // PURCHASE ORDER FLOW
    // ==========================================================

    local procedure HandlePurchaseOrder(var RGPHeader: Record "RGP Request Header")
    var
        VendorLine: Record "RGP Request Header";
        VendorNo: Code[20];

    begin
        // Determine vendor priority:
        // 1. Accepted vendor
        // 2. Header vendor

        VendorLine.SetRange("Request No.", RGPHeader."Request No.");

        if VendorLine.FindFirst() then
            VendorNo := VendorLine."Vendor No."
        else begin
            RGPHeader.TestField("Vendor No.");
            VendorNo := RGPHeader."Vendor No.";
        end;

        CreatePurchaseHeader(RGPHeader, VendorNo);
        TransferRequestToPurchaseLines(RGPHeader, PurchHeader);

        // store header
        FirstPurchHeader := PurchHeader;

        RGPHeader."Purchase Order No." := PurchHeader."No.";
        RGPHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeader(
        RGPHeader: Record "RGP Request Header";
        VendorNo: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit "No. Series";
    begin
        OnBeforeCreatePurchaseHeader(RGPHeader);

        // Get Order No. Series
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("Order Nos.");

        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader."No." := NoSeriesMgt.GetNextNo(PurchasesPayablesSetup."Order Nos.", WorkDate(), true);

        // Set basic fields before insert
        PurchHeader."Order Date" := WorkDate();
        PurchHeader."Posting Date" := WorkDate();
        PurchHeader."RGP Request No." := RGPHeader."Request No.";
        PurchHeader."Requested By" := RGPHeader."Requested By";
        PurchHeader."Request Date" := RGPHeader."Request Date";

        PurchHeader."Shortcut Dimension 1 Code" := RGPHeader."Shortcut Dimension 1 Code";
        PurchHeader."Shortcut Dimension 2 Code" := RGPHeader."Shortcut Dimension 2 Code";

        // Insert header FIRST
        PurchHeader.Insert(true);

        // Validate vendor AFTER insert (important for BC logic)
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);

        PurchHeader.Modify(true);

        OnAfterCreatePurchaseHeader(PurchHeader, RGPHeader);
    end;

    local procedure TransferRequestToPurchaseLines(
        RGPHeader: Record "RGP Request Header";
        var PurchHeader: Record "Purchase Header")

    var
        ItemLine: Record "RGP Request Item Line";
        PurchLine: Record "Purchase Line";
        LineNo: Integer;
    begin
        ItemLine.SetRange("Request No.", RGPHeader."Request No.");

        if not ItemLine.FindSet() then
            Error('No item lines exist for Request %1.', RGPHeader."Request No.");

        OnBeforeTransferToPOLines(ItemLine, RGPHeader, PurchHeader);

        repeat
            LineNo += 10000;

            PurchLine.Init();
            PurchLine."Document Type" := PurchHeader."Document Type";
            PurchLine."Document No." := PurchHeader."No.";
            PurchLine."Line No." := LineNo;
            PurchLine.Insert(true);

            PurchLine.Validate(Type, PurchLine.Type::Item);
            PurchLine.Validate("No.", ItemLine."No.");
            PurchLine.Validate(Quantity, ItemLine."Approved Qty");
            PurchLine.Validate("Location Code", ItemLine."Location Code");
            PurchLine.Validate("Unit of Measure Code", ItemLine."Unit of Measure Code");

            PurchLine.Modify(true);

            OnAfterInsertPOLine(ItemLine, PurchLine, RGPHeader);

        until ItemLine.Next() = 0;
    end;



    // ==========================================================
    // TRANSFER ORDER FLOW
    // ==========================================================

    local procedure HandleTransferOrder(var RGPHeader: Record "RGP Request Header")
    begin
        RGPHeader.TestField("Transfer-from Code");
        RGPHeader.TestField("Transfer-to Code");

        CreateTransferHeader(RGPHeader);
        TransferRequestToTransferLines(RGPHeader, TransferHeader);

        // store header
        FirstTransferHeader := TransferHeader;

        RGPHeader."Transfer Order No." := TransferHeader."No.";
        RGPHeader.Modify(true);
    end;

    procedure GetCreatedPurchaseHeader(var Header: Record "Purchase Header")
    begin
        Header := FirstPurchHeader;
    end;

    procedure GetCreatedTransferHeader(var Header: Record "Transfer Header")
    begin
        Header := FirstTransferHeader;
    end;

    local procedure CreateTransferHeader(RGPHeader: Record "RGP Request Header")
    var
        InventorySetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit "No. Series";
    begin
        OnBeforeCreateTransferHeader(RGPHeader);

        InventorySetup.Get();
        InventorySetup.TestField("Transfer Order Nos.");

        TransferHeader.Init();
        TransferHeader."No." := NoSeriesMgt.GetNextNo(InventorySetup."Transfer Order Nos.", WorkDate(), true);

        // Insert BEFORE validations
        TransferHeader.Insert(true);

        // Now validate fields (this triggers BC logic correctly)
        TransferHeader.Validate("Transfer-from Code", RGPHeader."Transfer-from Code");
        TransferHeader.Validate("Transfer-to Code", RGPHeader."Transfer-to Code");
        TransferHeader.Validate("Posting Date", WorkDate());
        TransferHeader.Validate("Direct Transfer", true);

        TransferHeader."RGP Request No." := RGPHeader."Request No.";
        TransferHeader."Assigned User ID" := RGPHeader."Requested By";
        TransferHeader."Request Date" := RGPHeader."Request Date";
        TransferHeader."Shortcut Dimension 1 Code" := RGPHeader."Shortcut Dimension 1 Code";
        TransferHeader."Shortcut Dimension 2 Code" := RGPHeader."Shortcut Dimension 2 Code";

        TransferHeader.Modify(true);

        OnAfterCreateTransferHeader(TransferHeader, RGPHeader);
    end;

    local procedure TransferRequestToTransferLines(
        RGPHeader: Record "RGP Request Header";
        var TransferHeader: Record "Transfer Header")
    var
        ItemLine: Record "RGP Request Item Line";
        TransferLine: Record "Transfer Line";
        LineNo: Integer;
    begin
        ItemLine.SetRange("Request No.", RGPHeader."Request No.");

        if not ItemLine.FindSet() then
            Error('No item lines exist for Request %1.', RGPHeader."Request No.");

        OnBeforeTransferToTransferLines(ItemLine, RGPHeader, TransferHeader);

        repeat
            LineNo += 10000;

            TransferLine.Init();
            TransferLine."Document No." := TransferHeader."No.";
            TransferLine."Line No." := LineNo;
            TransferLine.Insert(true);

            TransferLine.Validate("Item No.", ItemLine."No.");
            TransferLine.Validate(Quantity, ItemLine."Approved Qty");
            TransferLine.Validate("Unit of Measure Code", ItemLine."Unit of Measure Code");

            TransferLine.Modify(true);

            OnAfterInsertTransferLine(ItemLine, TransferLine, RGPHeader);

        until ItemLine.Next() = 0;
    end;


    // ==========================================================
    // VARIABLES
    // ==========================================================

    var

    var
        PurchHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        FirstPurchHeader: Record "Purchase Header";
        FirstTransferHeader: Record "Transfer Header";


    // ==========================================================
    // INTEGRATION EVENTS
    // ==========================================================

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseHeader(var RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseHeader(var PurchHeader: Record "Purchase Header"; RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferToPOLines(var ItemLine: Record "RGP Request Item Line"; RGPHeader: Record "RGP Request Header"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPOLine(var ItemLine: Record "RGP Request Item Line"; var PurchLine: Record "Purchase Line"; RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTransferHeader(var RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTransferHeader(var TransferHeader: Record "Transfer Header"; RGPHeader: Record "RGP Request Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferToTransferLines(var ItemLine: Record "RGP Request Item Line"; RGPHeader: Record "RGP Request Header"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransferLine(var ItemLine: Record "RGP Request Item Line"; var TransferLine: Record "Transfer Line"; RGPHeader: Record "RGP Request Header")
    begin
    end;
}