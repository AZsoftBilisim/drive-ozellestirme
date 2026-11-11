
#Region Internal

// Performs an action when clicking a hyperlink in the "documents to be Processed" report for a discrepancy document.
//
// Parameters:
//  Form               - ClientApplicationForm - the form that the call comes from 
//  CommandDetails     - String - description of the action to be performed, "Edit" or " Issue"
//  DiscrepancyCertificate    - DocumentRef.DiscrepancyReportFollowingShipment - report of discrepancies being processed.
//  BasisOfAct       - DocumentRef.CustomerInvoice,
//                      - DocumentRef.ReturnOfGoodsToVendor      - the basis of the act of discrepancies, according to which
//                                                                 actions are performed
//  CreatedDocument - Structure, DocumentRef - there is still either an empty link of the type being drawn up, or a structure from the same link and utility services. operations.
//
Procedure ProcessingReportCommandProcessingDocuments(Form, CommandDetails, DiscrepancyCertificate, BasisOfAct, CreatedDocument) Export
EndProcedure


#EndRegion