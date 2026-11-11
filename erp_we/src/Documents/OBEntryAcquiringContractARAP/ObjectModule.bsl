#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(	ThisObject, "AcquiringContractARAP");
	
	FillDocumentCurrency();
	
	OBEntryLocalization.OBEntryAcquiringContractARAPBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfSettlementsOnAcquiringProcessingOfTransactions(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfSettlementsOnAcquiringProcessingOfDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not RecordInOperationalAccounting 
		And Not PostInFinancialAndTaxAccounting
		And Not RecordInMA Then
		
		MessageText = NStr("vi = 'Cần phản ánh hoạt động trong một trong số sổ kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not RecordInOperationalAccounting Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringBalancesOfAcquiringCalculationsProcessingFillCheck(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.EnteringBalancesOfSettlementsOnAcquiringProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "AcquiringContractARAP");
	
	OBEntryLocalization.EnteringBalancesOfAcquiringCalculationsWhenCopying(ThisObject, CopiedObject);
	
	EmployeeResponsible = Undefined;
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfAcquiringCalculationsWhenRecording(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInAcquiringData() Export

	Query = New Query("
	|SELECT
	|	AcquiringContractARAP.CashType,
	|	AcquiringContractARAP.Currency,
	|	AcquiringContractARAP.POSTerminal,
	|	AcquiringContractARAP.Contract AS AcquiringContract,
	|	AcquiringContractARAP.PaymentDate AS PaymentDate,
	|	(-AcquiringContractARAP.SumBalance) AS Sum
	|FROM
	|	AccumulationRegister.AcquiringContractARAP.Balance(, Organization = &Organization) AS AcquiringContractARAP
	|WHERE
	|	AcquiringContractARAP.SumBalance < 0
	|	AND AcquiringContractARAP.CashType = VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions)
	|
	|UNION ALL
	|
	|SELECT
	|	AcquiringContractARAP.CashType,
	|	AcquiringContractARAP.Currency,
	|	AcquiringContractARAP.POSTerminal,
	|	AcquiringContractARAP.Contract AS AcquiringContract,
	|	AcquiringContractARAP.PaymentDate AS PaymentDate,
	|	AcquiringContractARAP.SumBalance AS Sum
	|FROM
	|	AccumulationRegister.AcquiringContractARAP.Balance(, Organization = &Organization) AS AcquiringContractARAP
	|WHERE
	|	AcquiringContractARAP.SumBalance > 0
	|	AND AcquiringContractARAP.CashType = VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard)
	|
	|ORDER BY
	|	PaymentDate
	|");

	Query.SetParameter("Organization", Organization);
	AcquiringContractARAP.Load(Query.Execute().Unload());

EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillDocumentCurrency()

	CurrencyTable = AcquiringContractARAP.Unload(, "Currency");
	CurrencyTable.GroupBy("Currency");
	
	If CurrencyTable.Count() = 1 Then
		Currency = CurrencyTable[0].Currency;
	Else
		Currency = Catalogs.Currencies.EmptyRef();
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf
