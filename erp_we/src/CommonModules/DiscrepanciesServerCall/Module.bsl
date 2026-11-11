////////////////////////////////////////////////////////////////////////////////
// The Server Call Divergences module contains procedures and functions designed for interaction between client and
// server procedures when working with documents to reflect discrepancies after shipment to customers, after returns
// to suppliers, after moving.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure ChangeDocumentBasisOfActOfDiscrepancies(DiscrepancyCertificate, Basis) Export

	DiscrepanciesServer.ChangeDocumentBasisOfActOfDiscrepancies(DiscrepancyCertificate, Basis);

EndProcedure

Function StatusOfActToBeExecutedWorkedOut(DiscrepancyCertificate) Export
	
	ActStatus = GeneralPurposeTMServerCall.ObjectAttributeValue(DiscrepancyCertificate, "Status");
	StatusOfActToBeExecutedWorkedOut = ActStatus = Enums.StatusesOfDiscrepancyReport.ForCompletion
		Or ActStatus = Enums.StatusesOfDiscrepancyReport.Processed_;
	
	Return StatusOfActToBeExecutedWorkedOut;
		
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - Form
Procedure EstablishAvailabilityOfVendorAgreements(Form) Export
	
	If ValueIsFilled(Form.Object.Partner) And Form.UseTermsOfPurchases Then
		NumberOfSupplierAgreements  = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Form.Object.Partner);
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Terms", "Visible", NumberOfSupplierAgreements > 0);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Form.Items, "Terms", "Visible", False);
	EndIf;
	
EndProcedure

#EndRegion
