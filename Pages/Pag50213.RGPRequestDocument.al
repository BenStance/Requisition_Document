page 50213 RGPRequestDocument
{
    Caption = 'RGP Request Document';
    PageType = Document;
    SourceTable = "RGP Request Header";
    ApplicationArea = All;
    UsageCategory = Documents;

    PromotedActionCategories = 'New,Process,Report,Orders,Request Approval,Category6,Category7,Category8,Category9,Category10';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Request No."; Rec."Request No.")
                {
                    ApplicationArea = All;
                    Editable = IsEditable;
                }
                field("Request Date"; Rec."Request Date")
                {
                    ApplicationArea = All;
                    Editable = IsEditable;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = IsEditable;

                    trigger OnValidate()
                    begin
                        UpdateVisibility();
                        CurrPage.Update(false);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Requested By"; Rec."Requested By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Comments; Rec.Comments)
                {
                    ApplicationArea = All;
                    Editable = IsEditable;
                }
                field("Expected Date"; Rec."Expected Date")
                {
                    ApplicationArea = All;
                    Editable = IsEditable;
                }
            }

            // =============================
            // PURCHASE SECTION
            // =============================
            group(PurchaseSection)
            {
                Caption = 'Purchase Information';
                Visible = ShowPurchaseFields;

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    Editable = IsEditable;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            // =============================
            // TRANSFER SECTION
            // =============================
            group(TransferSection)
            {
                Caption = 'Transfer Information';
                Visible = ShowTransferFields;

                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = All;
                    Editable = IsEditable;
                }
            }

            part(ItemSubform; "RGP Request Item Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Request No." = field("Request No.");
                Editable = IsEditable;
            }


        }
    }


    actions
    {
        area(Processing)
        {
            group("Document Actions")
            {
                Caption = 'Document Actions';
                Image = Document;

                group(Open)
                {
                    Caption = 'Open';
                    Image = DocumentEdit;

                    action(Release)
                    {
                        ApplicationArea = All;
                        Caption = 'Release';
                        ToolTip = 'Release the document to Pending status.';
                        Image = ReleaseDoc;
                        Enabled = IsEditable and not IsWorkflowEnabled;
                        Promoted = true;
                        PromotedCategory = Process;
                        PromotedIsBig = true;

                        trigger OnAction()
                        begin
                            if Confirm('Are you sure you want to release this request?') then begin
                                Rec.TestField(Status, Rec.Status::Open);
                                Rec.Status := Rec.Status::Pending;
                                Rec.Modify(true);
                                Message('Request %1 has been released and is now Pending approval.', Rec."Request No.");
                            end;
                        end;
                    }

                    action(Reopen)
                    {
                        ApplicationArea = All;
                        Caption = 'Reopen';
                        ToolTip = 'Reopen the document to Open status.';
                        Image = ReOpen;
                        Enabled = IsEditable and not IsWorkflowEnabled;
                        Promoted = true;
                        PromotedCategory = Process;

                        trigger OnAction()
                        begin
                            if Confirm('Are you sure you want to reopen this request?') then begin
                                Rec.TestField(Status, Rec.Status::Pending);
                                Rec.Status := Rec.Status::Open;
                                Rec.Modify(true);
                                Message('Request %1 has been reopened.', Rec."Request No.");
                            end;
                        end;
                    }
                }
                action(Approvals)
                {
                    ApplicationArea = All;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View approval requests.';
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    // Visible = HasApprovalEntries;

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);
                    end;
                }

                group(Reports)
                {
                    Caption = 'Reports';
                    Image = Report;

                    action(PrintRGPRequest)
                    {
                        ApplicationArea = All;
                        Caption = 'Print RGP Request';
                        ToolTip = 'Print the RGP Request document';
                        Image = Print;
                        Promoted = true;
                        PromotedCategory = Report;
                        PromotedIsBig = true;

                        trigger OnAction()
                        var
                            RGPHeader: Record "RGP Request Header";
                        begin
                            RGPHeader := Rec;
                            RGPHeader.SetRecFilter();

                            Report.RunModal(
                                Report::"RGP Request Document",
                                true,   // Show request page
                                true,   // Print
                                RGPHeader);
                        end;
                    }
                }
                group("Related Document")
                {
                    Caption = 'Related Document';
                    Image = Document;

                    // =============================================
                    // PURCHASE ORDERS
                    // =============================================
                    action(ViewPurchaseOrders)
                    {
                        ApplicationArea = All;
                        Caption = 'Purchase Orders';
                        Image = Order;
                        ToolTip = 'View Purchase Orders created from this request.';
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedIsBig = true;

                        trigger OnAction()
                        var
                            TempPurchHeader: Record "Purchase Header" temporary;
                            PurchHeader: Record "Purchase Header";
                        begin
                            PurchHeader.Reset();
                            PurchHeader.SetRange("RGP Request No.", Rec."Request No.");
                            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);

                            if PurchHeader.FindSet() then
                                repeat
                                    TempPurchHeader := PurchHeader;
                                    TempPurchHeader.Insert();
                                until PurchHeader.Next() = 0;

                            if TempPurchHeader.IsEmpty() then
                                Message(
                                    'No Purchase Orders found for Request %1.',
                                    Rec."Request No.")
                            else
                                Page.Run(Page::"Purchase Orders", TempPurchHeader);
                        end;
                    }

                    // =============================================
                    // TRANSFER ORDERS
                    // =============================================
                    action(ViewTransferOrders)
                    {
                        ApplicationArea = All;
                        Caption = 'Transfer Orders';
                        Image = TransferOrder;
                        ToolTip = 'View Transfer Orders created from this request.';
                        Promoted = true;
                        PromotedCategory = Category4;
                        PromotedIsBig = true;

                        trigger OnAction()
                        var
                            TempTransferHeader: Record "Transfer Header" temporary;
                            TransferHeader: Record "Transfer Header";
                        begin
                            TransferHeader.Reset();
                            TransferHeader.SetRange("RGP Request No.", Rec."Request No.");

                            if TransferHeader.FindSet() then
                                repeat
                                    TempTransferHeader := TransferHeader;
                                    TempTransferHeader.Insert();
                                until TransferHeader.Next() = 0;

                            if TempTransferHeader.IsEmpty() then
                                Message(
                                    'No Transfer Orders found for Request %1.',
                                    Rec."Request No.")
                            else
                                Page.Run(Page::"Transfer Orders", TempTransferHeader);
                        end;
                    }
                }
                group("Approval")
                {
                    Caption = 'Approval';
                    Image = Approval;

                    action(SendApprovalRequest)
                    {
                        ApplicationArea = All;
                        Caption = 'Send Approval Request';
                        Image = SendApprovalRequest;
                        ToolTip = 'Request approval of the document.';
                        Promoted = true;
                        PromotedCategory = Category5;
                        PromotedIsBig = true;

                        trigger OnAction()
                        var
                            CustomWorkflowMgmt: Codeunit "RGP Custom Workflow Mgmt";
                            RecRef: RecordRef;
                        begin
                            RecRef.GetTable(Rec);
                            if CustomWorkflowMgmt.CheckRGPRequestApprovalsWorkflowEnable(Rec) then
                                CustomWorkflowMgmt.OnSendRGPRequestForApproval(Rec);
                        end;
                    }

                    action(CancelApprovalRequest)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Cancel Approval Request';
                        Enabled = CanCancelApprovalForRecord;
                        Image = CancelApprovalRequest;
                        ToolTip = 'Cancel the approval request.';
                        Promoted = true;
                        PromotedCategory = Category5;

                        trigger OnAction()
                        var
                            CustomWorkflowMgmt: Codeunit "RGP Custom Workflow Mgmt";
                            RecRef: RecordRef;
                        begin
                            RecRef.GetTable(Rec);
                            CustomWorkflowMgmt.OnCancelRGPRequestForApproval(Rec);
                        end;
                    }


                    action("Create Purchase Order")
                    {
                        ApplicationArea = All;
                        Caption = 'Create Purchase Order';
                        ToolTip = 'Convert this request into a Purchase Order.';
                        Image = Order;
                        Enabled = Rec.Type = Rec.Type::Purchase;
                        Promoted = true;
                        PromotedCategory = Process;
                        PromotedIsBig = true;

                        trigger OnAction()
                        var
                            RGPHandleReq: Codeunit "RGP Handle Req to P-O(Yes/No)";
                        begin
                            Rec.TestField(Type, Rec.Type::Purchase);
                            RGPHandleReq.Run(Rec);
                        end;
                    }

                    action("Create Transfer Order")
                    {
                        ApplicationArea = All;
                        Caption = 'Create Transfer Order';
                        ToolTip = 'Convert this request into a Transfer Order.';
                        Image = TransferOrder;
                        Enabled = Rec.Type = Rec.Type::Transfer;
                        Promoted = true;
                        PromotedCategory = Process;
                        PromotedIsBig = true;

                        trigger OnAction()
                        var
                            RGPHandleReq: Codeunit "RGP Handle Req to P-O(Yes/No)";
                        begin
                            Rec.TestField(Type, Rec.Type::Transfer);
                            RGPHandleReq.Run(Rec);
                        end;
                    }
                    action(Comment)
                    {
                        ApplicationArea = All;
                        Caption = 'Comments';
                        Image = ViewComments;
                        ToolTip = 'View or add comments for the record.';
                        Promoted = true;
                        PromotedCategory = Category5;
                        Visible = OpenApprovalEntriesExistCurrUser;

                        trigger OnAction()
                        begin
                            ApprovalsMgmt.GetApprovalComment(Rec);
                        end;
                    }

                }
            }


        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
        OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
        HasApprovalEntries := ApprovalsMgmt.HasApprovalEntries(Rec.RecordId);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetEditable();
    end;

    trigger OnOpenPage()
    begin
        SetEditable();
    end;

    trigger OnAfterGetRecord()
    begin
        SetEditable();
    end;


    local procedure SetEditable()
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        IsEditable := Rec.Status = Rec.Status::Open;
        EnableConvertToQuote := (Rec.Status = Rec.Status::Approved);
        IsWorkflowEnabled := WorkflowManagement.CanExecuteWorkflow(Rec, RGPCustomWorkflowMgmt.RunWorkflowOnSendRGPRequestForApprovalCode());
    end;

    local procedure UpdateVisibility()
    begin
        ShowPurchaseFields := Rec.Type = Rec.Type::Purchase;
        ShowTransferFields := Rec.Type = Rec.Type::Transfer;
    end;



    var
        IsEditable: Boolean;
        ShowPurchaseFields: Boolean;
        ShowTransferFields: Boolean;

        IsWorkflowEnabled: Boolean;
        RGPCustomWorkflowMgmt: Codeunit "RGP Custom Workflow Mgmt";
        OpenApprovalEntriesExistCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        HasApprovalEntries: Boolean;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        EnableConvertToQuote: Boolean;
}