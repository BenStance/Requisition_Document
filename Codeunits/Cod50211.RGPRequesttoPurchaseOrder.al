codeunit 50211 "RGP Handle Req to P-O(Yes/No)"
{
    TableNo = "RGP Request Header";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        RGPRequestToPO_TO: Codeunit "RGP Request to PO/TO";
        IsHandled: Boolean;
    begin
        Rec.TestField(Status, Rec.Status::Open);//for debbaging time its Open but should be Approved

        // ==========================================
        // Prevent Double Conversion
        // ==========================================
        case Rec.Type of
            Rec.Type::Purchase:
                if Rec."Purchase Order No." <> '' then
                    Error('Purchase Order %1 has already been created for this request.',
                          Rec."Purchase Order No.");

            Rec.Type::Transfer:
                if Rec."Transfer Order No." <> '' then
                    Error('Transfer Order %1 has already been created for this request.',
                          Rec."Transfer Order No.");
        end;

        // ==========================================
        // Confirmation
        // ==========================================
        if not ConfirmManagement.GetResponseOrDefault(GetConfirmQuestion(), true) then
            exit;

        IsHandled := false;
        OnBeforeConvertRequest(Rec, IsHandled);
        if IsHandled then
            exit;

        // ==========================================
        // Run Converter
        // ==========================================
        RGPRequestToPO_TO.Run(Rec);

        case Rec.Type of
            Rec.Type::Purchase:
                begin
                    RGPRequestToPO_TO.GetCreatedPurchaseHeader(PurchHeader);
                    HandleOpenPurchaseOrder(PurchHeader);
                end;

            Rec.Type::Transfer:
                begin
                    RGPRequestToPO_TO.GetCreatedTransferHeader(TransferHeader);
                    HandleOpenTransferOrder(TransferHeader);
                end;
        end;
    end;


    // =====================================================
    // OPEN PURCHASE ORDER
    // =====================================================
    local procedure HandleOpenPurchaseOrder(var PurchHeader: Record "Purchase Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnAfterCreatePurchaseOrder(PurchHeader, IsHandled);

        if not IsHandled then
            if ConfirmManagement.GetResponseOrDefault(OpenNewPOQst, true) then
                Page.Run(Page::"Purchase Order", PurchHeader);
    end;
    // =====================================================
    // OPEN TRANSFER ORDER
    // =====================================================
    local procedure HandleOpenTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnAfterCreateTransferOrder(TransferHeader, IsHandled);

        if not IsHandled then
            if ConfirmManagement.GetResponseOrDefault(OpenNewTOQst, true) then
                Page.Run(Page::"Transfer Order", TransferHeader);
    end;
    // =====================================================
    // DYNAMIC CONFIRMATION TEXT
    // =====================================================

    local procedure GetConfirmQuestion(): Text
    var
        RGPRequestHeader: Record "RGP Request Header";
    begin
        case RGPRequestHeader.Type of
            RGPRequestHeader.Type::Purchase:
                exit(ConvertRequestToPOQst);

            RGPRequestHeader.Type::Transfer:
                exit(ConvertRequestToTOQst);
        end;
    end;


    // =====================================================
    // LABELS
    // =====================================================

    var
        ConvertRequestToPOQst: Label 'Do you want to convert this request to a Purchase Order?';
        ConvertRequestToTOQst: Label 'Do you want to convert this request to a Transfer Order?';
        OpenNewPOQst: Label 'Purchase Order has been created. Do you want to open it?';
        OpenNewTOQst: Label 'Transfer Order has been created. Do you want to open it?';

        PurchHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";


    // =====================================================
    // EVENTS
    // =====================================================

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertRequest(var RGPRequestHeader: Record "RGP Request Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTransferOrder(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}