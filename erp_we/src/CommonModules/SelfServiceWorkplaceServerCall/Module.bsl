#Region Public

// Receives documents of the basis of the acceptance certificate from the client
//
// Parameters:
//  ReceivingNote  - DocumentRef.DiscrepancyReportFollowingShipment - the document for which the grounds are obtained.
//
// Returns:
//   Array   - an array that contains the documents "Sale of goods and services", which are the grounds.
//
Function DocumentsOfBasisOfAcceptanceCertificateFromClient(ReceivingNote) Export

	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &ReceivingNote";
	
	Query.SetParameter("ReceivingNote", ReceivingNote);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return New Array;
	EndIf;
	
	Return Result.Unload().UnloadColumn("SaleOfGoodsAndServices");

EndFunction 

#EndRegion



