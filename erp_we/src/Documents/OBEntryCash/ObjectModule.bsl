#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "CashAccounts,CashRegisters,BankAccounts");
	
	FillDocumentCurrency();
	
	OBEntryLocalization.OBEntryCashBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringCashBalancesProcessingOfTransactions(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringCashBalancesProcessingDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	
	If Not RecordInOperationalAccounting And Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
		MessageText = NStr("vi = 'Cần phản ánh hoạt động trong một trong sổ kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCashInHand Then
		NotCheckedAttributeArray.Add("CashAccounts");
	Else
		If GetFunctionalOption("UseMultipleCashAccounts") Then
			NotCheckedAttributeArray.Add("Currency");
		EndIf;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCashInRetailCashRegister Then
		NotCheckedAttributeArray.Add("CashRegisters");
	Else
		If GetFunctionalOption("UseSeveralCashRegisters") Then
			NotCheckedAttributeArray.Add("Currency");
		EndIf;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		NotCheckedAttributeArray.Add("BankAccounts");
	Else
		If GetFunctionalOption("UseMultipleBankAccounts") Then
			NotCheckedAttributeArray.Add("Currency");
		EndIf;
	EndIf;

	
	NotCheckedAttributeArray.Add("Currency");
	
	NotCheckedAttributeArray.Add("Currency");
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringCashBalancesProcessingFillChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		 
		Documents.OBEntryCash.InitializeDocument(ThisObject, FillingData, StandardProcessing);
		
	EndIf;
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts;
	EndIf;
	
	If Not ValueIsFilled(Organization)
		And Not GetFunctionalOption("UseMultipleCompanies") Then
		
		Organization = SettingsValueCached.GetDefaultOrganization();
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		
	EndIf;
	
	OBEntryLocalization.EnteringCashBalancesProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	OBEntryLocalization.EnteringCashBalancesWhenRecording(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "CashAccounts,CashRegisters,BankAccounts");

	OBEntryLocalization.EnteringCashBalancesWhenCopying(ThisObject, CopiedObject);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	OBEntryLocalization.EnteringCashBalancesBeforeDeleting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillDocumentCurrency()

	Query = New Query;
	Query.Text =
		"SELECT
		|	DataTable.Ref AS Ref
		|INTO RawData
		|FROM
		|	&DataTable AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RawData.Ref.CashCurrency AS Currency
		|FROM
		|	RawData AS RawData";
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand Then
		
		TableOfCashRegisters = CashAccounts.Unload(, "CashAccount");
		TableOfCashRegisters.Columns.CashAccount.Name = "Ref";
		
		Query.SetParameter("DataTable", TableOfCashRegisters);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		
		TableOfAccounts = BankAccounts.Unload(, "BankAccount");
		TableOfAccounts.Columns.BankAccount.Name = "Ref";
		
		Query.SetParameter("DataTable", TableOfAccounts);
		
	Else
		
		TableOfCashRegisterCashAccounts = CashRegisters.Unload(, "CashRegister");
		TableOfCashRegisterCashAccounts.Columns.CashRegister.Name = "Ref";
		
		Query.SetParameter("DataTable", TableOfCashRegisterCashAccounts);
		
	EndIf;
	
	CurrencyTable = Query.Execute().Unload();
	
	If CurrencyTable.Count() = 1 Then
		Currency = CurrencyTable[0].Currency;
	Else
		Currency = Catalogs.Currencies.EmptyRef();
	EndIf;

EndProcedure

#EndRegion

#EndIf
