#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AcquiringContract") Then
		FillInContractOfAcquiring(FillingData.AcquiringContract, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
	BankReportOnAcquiringTransactionsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AcquiringContract")
		And Not ValueIsFilled(FillingData.AcquiringContract) And ValueIsFilled(AcquiringContract) Then
		FillInContractOfAcquiring(AcquiringContract, FillingData);
	EndIf;
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.BankReportOnAcquiringTransactions.ItemsAndDimensionsSelectionParameters(
		RecordCommission And Not KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	FillInTotals_();
	
	If Not DetailedTransactionReconciliation Then
		Purchases.Clear();
		Returns.Clear();
	EndIf;
	
	If KeepRecordsOfCommissionInARAPAccounting Then
		Department = Catalogs.BusinessStructure.EmptyRef();
	Else
		CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Purchases,Returns");
	
	ItemsAndDimensionsSelectionParameters = Documents.BankReportOnAcquiringTransactions.ItemsAndDimensionsSelectionParameters(
		RecordCommission And Not KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	BankReportOnAcquiringTransactionsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	BankReportOnAcquiringTransactionsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckCompletionOfCommissionArticle = (RecordCommission And FeeAmount <> 0
		And Not KeepRecordsOfCommissionInARAPAccounting);
	
	PerformVerificationOfFillingOutContractOfCommission = (RecordCommission And FeeAmount <> 0
		And KeepRecordsOfCommissionInARAPAccounting);
	
	If Not PerformVerificationOfFillingOutContractOfCommission Then
		NotCheckedAttributeArray.Add("CommissionARAPObject");
	EndIf;
	
	If AdditionalProperties.Property("ExcludeVerificationOfFillingInARAPObjectOfFee")
		And AdditionalProperties.ExcludeVerificationOfFillingInARAPObjectOfFee Then
		NotCheckedAttributeArray.Add("CommissionARAPObject");
	EndIf;
	
	If Not DetailedTransactionReconciliation Then
		NotCheckedAttributeArray.Add("Purchases");
		NotCheckedAttributeArray.Add("Returns");
	EndIf;
	
	If ValueIsFilled(AcquiringContract)
		And Not Common.ObjectAttributeValue(AcquiringContract, "POSTerminalsAreUsed") Then
		NotCheckedAttributeArray.Add("Purchases.POSTerminal");
		NotCheckedAttributeArray.Add("Returns.POSTerminal");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes, NotCheckedAttributeArray);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
		
	ItemsAndDimensionsSelectionParameters = Documents.BankReportOnAcquiringTransactions.ItemsAndDimensionsSelectionParameters(
		CheckCompletionOfCommissionArticle);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	BankReportOnAcquiringTransactionsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	BankReportOnAcquiringTransactionsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	BankReportOnAcquiringTransactionsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Purchases,Returns");
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInContractOfAcquiring(Contract, FillingData)

	AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(Contract);
	FillPropertyValues(ThisObject, AttributesValues, "Organization, Currency");
	FillingData.Insert("RecordCommission", AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.InReport);
	
	If FillingData.RecordCommission Then
		FillPropertyValues(ThisObject, AttributesValues, "ExpenseItem, DimensionOfExpenses,
			|KeepRecordsOfCommissionInARAPAccounting, CommissionARAPObject");
		Department = AttributesValues.ExpensesBusinessUnit;
	EndIf;

EndProcedure

Procedure FillInTotals_()
	
	CalculationAmountOfPurchases = Purchases.Total("Sum");
	If AmountOfPurchases <> CalculationAmountOfPurchases Then
		AmountOfPurchases = CalculationAmountOfPurchases;
	EndIf;
	
	CalculationAmountOfRefunds = Returns.Total("Sum");
	If AmountOfReturns <> CalculationAmountOfRefunds Then
		AmountOfReturns = CalculationAmountOfRefunds;
	EndIf;
	
	If DetailedTransactionReconciliation Then
		CalculationDocumentAmount = AmountOfPurchases - AmountOfReturns - FeeAmount;
	Else
		CalculationDocumentAmount = FeeAmount;
	EndIf;
	If DocumentAmount <> CalculationDocumentAmount Then
		DocumentAmount = CalculationDocumentAmount;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
