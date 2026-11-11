#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If TypeOf(FillingData) = Type("DocumentRef.IssuedTaxInvoicePrepayment") Then
		
		InvoiceAttributes = Common.ObjectAttributesValues(FillingData, "Organization, Counterparty, DocumentBasis");
		
		BusinessOperation = Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer;
		
		Organization = InvoiceAttributes.Organization;
		Counterparty = InvoiceAttributes.Counterparty;
		DocumentPayments = InvoiceAttributes.DocumentBasis;
		
		Documents.VATWritingOffAsExpenses.FillInTableAdvancesReceived(ThisObject);
		
	ElsIf FillingData <> Undefined 
		And TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("BusinessOperation") Then
		
		BusinessOperation = FillingData.BusinessOperation;
		
		If FillingData.Property("Organization") Then
			Organization = FillingData.Organization;
		EndIf;
		If FillingData.Property("Counterparty") Then
			Counterparty = FillingData.Counterparty;
		EndIf;
		If FillingData.Property("TaxInvoice") 
				And BusinessOperation = Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff Then
			TaxInvoice = FillingData.TaxInvoice;
		EndIf;
		If FillingData.Property("DocumentPayments") 
				And BusinessOperation = Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer Then
			DocumentPayments = FillingData.DocumentPayments;
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff
				And ValueIsFilled(Organization) And ValueIsFilled(Counterparty) And ValueIsFilled(TaxInvoice) Then
			Documents.VATWritingOffAsExpenses.FillInValueTable(ThisObject);
		EndIf;
		If BusinessOperation = Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer
				And ValueIsFilled(Organization) And ValueIsFilled(Counterparty) And ValueIsFilled(DocumentPayments) Then
			Documents.VATWritingOffAsExpenses.FillInValueTable(ThisObject);
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);

	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.VATWritingOffAsExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	VATWritingOffAsExpensesLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array();
	If BusinessOperation <> Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff Then
		NotCheckedAttributeArray.Add("TaxInvoice");
		NotCheckedAttributeArray.Add("Assets_");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer Then
		NotCheckedAttributeArray.Add("DocumentPayments");
		NotCheckedAttributeArray.Add("PrepaymentsFromCustomer");
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.VATWritingOffAsExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
 
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If Not Cancel Then
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	EndIf;
	
	VATWritingOffAsExpensesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	VATWritingOffAsExpensesLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	VATWritingOffAsExpensesLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	For Each String In Assets_ Do
		If Not ValueIsFilled(String.SaleExport) And String.SaleExport <> Undefined Then
			String.SaleExport = Undefined;
		EndIf;
	EndDo;
	
	If BusinessOperation <> Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff Then
		If ValueIsFilled(TaxInvoice) Then
			TaxInvoice = Undefined;
		EndIf;
		If Assets_.Count() > 0 Then
			Assets_.Clear();
		EndIf;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer Then
		If ValueIsFilled(DocumentPayments) Then
			DocumentPayments = Undefined;
		EndIf;
		If PrepaymentsFromCustomer.Count() > 0 Then
			PrepaymentsFromCustomer.Clear();
		EndIf;
	EndIf;
	
	VATAmount = Assets_.Total("VAT") + PrepaymentsFromCustomer.Total("VAT");
	VATAmountMan = Assets_.Total("VATManag") + PrepaymentsFromCustomer.Total("VATManag");
	AmountExcludingVAT = Assets_.Total("AmountExcludingVAT") + PrepaymentsFromCustomer.Total("AmountExcludingVAT");
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Assets_,PrepaymentsFromCustomer");
	
	ItemsAndDimensionsSelectionParameters = Documents.VATWritingOffAsExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	VATWritingOffAsExpensesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	// Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.VATWritingOffAsExpenses.AccountingAccountSettings_());
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	VATWritingOffAsExpensesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	EmployeeResponsible = Users.CurrentUser();
	Assets_.Clear();
	AmountExcludingVAT 			= 0;
	VATAmount    			= 0;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Assets_,PrepaymentsFromCustomer");
	
	VATWritingOffAsExpensesLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#EndIf
