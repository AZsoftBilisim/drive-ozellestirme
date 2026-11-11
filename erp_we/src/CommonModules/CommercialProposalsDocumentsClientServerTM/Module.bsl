
////////////////////////////////////////////////////////////////////////////////
// Subsystem "Objects UT11, KA2, UP2".
// General module.Commercial Offer documentsclientserverut.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// See CommercialProposalsDocumentsClientServerOverridable.GenerateStatePresentationByStatus
//
// Parameters:
//  Form        - ClientApplicationForm
//  Status       - DefinedType.StatusesOfCommercialProposalsForCustomers
//  CurrentDate  - Date
//
Procedure GenerateStatePresentationByStatus(Form, Status, CurrentDate) Export
	
	State = "";
	ValidityPeriod = Form.Object.ValidityPeriod;
	
	If Status = PredefinedValue("Enum.StatusesOfCommercialProposalsForCustomers.NotApproved") Then
		State = NStr("vi = 'Cần thống nhất';
					|ru = 'На согласовании.';
					|en = 'Pending approval.'; fa = 'Pending approval.';
					|it = 'In fase di definizione.';
					|pl = 'Na uzgodnieniu.';
					|tr = 'Onay bekliyor.'");
	ElsIf Status = PredefinedValue("Enum.StatusesOfCommercialProposalsForCustomers.Draft") Then
		State = NStr("vi = 'Đang soạn.';
					|ru = 'Подготавливается.';
					|en = 'Draft.'; fa = 'Draft.';
					|it = 'In preparazione.';
					|pl = 'Przygotowuje się.';
					|tr = 'Hazırlanıyor.'");
	ElsIf Status = PredefinedValue("Enum.StatusesOfCommercialProposalsForCustomers.Canceled") Then
		State = NStr("vi = 'Đã hủy bỏ.';
					|ru = 'Отменено.';
					|en = 'Canceled.'; fa = 'Canceled.';
					|it = 'Annullato.';
					|pl = 'Anulowano.';
					|tr = 'İptal edildi.'");
	ElsIf Status = PredefinedValue("Enum.StatusesOfCommercialProposalsForCustomers.Valid") Then
		
		If ValidityPeriod >= CurrentDate Then
			State = NStr("vi = 'Có hiệu lực.';
						|ru = 'Действует.';
						|en = 'Valid.'; fa = 'Valid.';
						|it = 'In vigore.';
						|pl = 'Aktualne.';
						|tr = 'Aktif.'");
		Else
			State = NStr("vi = 'Đã hết hạn';
						|ru = 'Срок действия окончен.';
						|en = 'Validity period ended.'; fa = 'Validity period ended.';
						|it = 'Il periodo di validità è terminato.';
						|pl = 'Termin ważności został zakończony.';
						|tr = 'Geçerlilik süresi bitti.'");
		EndIf;
		
	EndIf;
	
	StateFormElement = Form.Items.State; // FormDecoration 
	StateFormElement.Title = State;
	
EndProcedure

// See CommercialProposalsDocumentsClientServerOverridable.CreatePresentationOfProductsForPrinting
//
Procedure CreatePresentationOfProductsForPrinting(PresentationForPrinting, Products, Characteristic, StandardProcessing) Export
	
	StandardProcessing = False;
	PresentationForPrinting = CommercialProposalsDocumentsTMServerCall.PresentationOfProductsForPrinting(Products, Characteristic);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  Taxation - Boolean -
//
// Returns:
//   EnumRef.VATTaxationTypes - 
//
Function TaxationOfVATOnTaxationOfCommercialOffers(Taxation) Export

	If Taxation Then
		Return PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	Else
		Return PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT");
	EndIf;

EndFunction

Function TaxationOfCommercialProposalsForVATTaxation(VATTaxation) Export

	If VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT")
		Or VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII") Then
		Return False;
	Else
		Return True;
	EndIf;

EndFunction

Function BusinessTransactionOfDocumentCommercialOfferToClient(Operation) Export
	
	If Operation = PredefinedValue("Enum.KindsOfCommercialProposalProcedures.PurchaseFromSupplier") Then
		
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
		
	Else
		
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
		
	EndIf;
	
	Return BusinessOperation;
	
EndFunction

Function BusinessTransactionOfDocumentSalesQuotationOfSupplier(Operation) Export
	
	If Operation = PredefinedValue("Enum.KindsOfCommercialProposalProcedures.PurchaseFromSupplier") Then
		
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
		
	Else
		
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement");
		
	EndIf;
	
	Return BusinessOperation;
	
EndFunction

Function ArrayOfSelectionsByProductType(OperationKind) Export
	
	If OperationKind = PredefinedValue("Enum.KindsOfCommercialProposalProcedures.PurchaseFromSupplier") Then
		ArrayOfSelections = ProductsClientServer.SelectionByProductReusablePackagingServiceWork(True);
	Else
		ArrayOfSelections = ProductsClientServer.SelectionByProductReusablePackagingWork(True);
	EndIf;
	
	Return ArrayOfSelections;
	
EndFunction

#EndRegion
