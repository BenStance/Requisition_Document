report 50214 "RGP Request Document"

{

    Caption = 'RGP Requisition Document';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = './Requisition_Document/Layouts/RGPRequestDocument.rdl';

    dataset
    {
        dataitem(RGPHeader; "RGP Request Header")
        {
            RequestFilterFields = "Request No.";

            column(RequestNo; "Request No.") { }
            column(RequestDate; "Request Date") { }
            column(Type; Type) { }
            column(Status; Status) { }
            column(RequestedBy; "Requested By") { }
            column(VendorNo; "Vendor No.") { }
            column(VendorName; "Vendor Name") { }
            column(TransferFrom; "Transfer-from Code") { }
            column(TransferTo; "Transfer-to Code") { }
            column(ExpectedDate; "Expected Date") { }
            column(Comments; Comments) { }
            column(Dim1; "Shortcut Dimension 1 Code") { }
            column(Dim2; "Shortcut Dimension 2 Code") { }
            column(CompanyName; CompanyInfo.Name) { }
            column(CompanyAddress; CompanyInfo.Address) { }
            column(CompanyAddress2; CompanyInfo."Address 2") { }
            column(CompanyCity; CompanyInfo.City) { }
            column(CompanyPostCode; CompanyInfo."Post Code") { }
            column(CompanyCountry; CompanyInfo."Country/Region Code") { }
            column(CompanyPhone; CompanyInfo."Phone No.") { }
            column(CompanyEmail; CompanyInfo."E-Mail") { }
            column(CompanyPicture; CompanyInfo.Picture) { }
            column(VendorAddress; VendorRec.Address) { }
            column(VendorAddress2; VendorRec."Address 2") { }
            column(VendorCity; VendorRec.City) { }
            column(VendorPostCode; VendorRec."Post Code") { }
            column(VendorCountry; VendorRec."Country/Region Code") { }
            column(VendorPhone; VendorRec."Phone No.") { }
            column(VendorEmail; VendorRec."E-Mail") { }
            column(VendorContact; VendorRec.Contact) { }
            column(VendorTIN; VendorRec."VAT Registration No.") { }

            dataitem(RGPLine; "RGP Request Item Line")
            {
                DataItemLink = "Request No." = field("Request No.");
                DataItemLinkReference = RGPHeader;

                column(LineNo; "Line No.") { }
                column(TypeLine; Type) { }
                column(No_; "No.") { }
                column(Description; Description) { }
                column(LocationCode; "Location Code") { }
                column(UOM; "Unit of Measure Code") { }
                column(RequestedQty; Quantity) { }
                column(ApprovedQty; "Approved Qty") { }
                column(LocationCurrentQty; "Location Current Qty") { }
                column(RequestFromCurrentQty; "Request From Current Qty") { }
                column(LineComments; Comments) { }

                trigger OnAfterGetRecord()
                begin
                    // Only print lines with Approved Qty > 0 (optional)
                    if "Approved Qty" = 0 then
                        CurrReport.Skip();
                end;
            }  
            trigger OnAfterGetRecord()
            begin
                Clear(VendorRec);

                if "Vendor No." <> '' then
                    VendorRec.Get("Vendor No.");
            end;         
        }
        
    }
    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.CalcFields(Picture);
    end;

    var
    VendorRec: Record Vendor;
    CompanyInfo: Record "Company Information"; 
}