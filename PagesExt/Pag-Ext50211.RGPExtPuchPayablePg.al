namespace BCEXPERTROAD.BCEXPERTROAD;

using Microsoft.Purchases.Setup;

pageextension 50211 RGPExtPuchPayablePg extends "Purchases & Payables Setup"
{
    layout
    {
        
     addlast("Number Series")
        
        {        
        
            field(RFQ;Rec.RFQ)
            {
                ApplicationArea = All;
                
               
                Editable = true;
            }
               
              
        }
    }
}
