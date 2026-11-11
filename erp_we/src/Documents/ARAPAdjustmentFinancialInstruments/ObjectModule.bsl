#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	If Debt_.Count() Then
		Debt_.Clear();
	EndIf;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Debt_");
	
	ARAPAdjustmentFinancialInstrumentsLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillByStructure(FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
	ARAPAdjustmentFinancialInstrumentsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustmentFinancialInstruments.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then 
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If
		BusinessOperation = Enums.BusinessTransactions.ARWriteOff Or
		BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance
	Then
		NotCheckedAttributeArray.Add("IncomeItem");
	Else
		NotCheckedAttributeArray.Add("ExpenseItem");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustmentFinancialInstruments.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ARAPAdjustmentFinancialInstrumentsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ARAPCurrency = Common.ObjectAttributeValue(Contract, "ARAPCurrency");
	DocumentAmount = Debt_.Total("Sum");
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If
			BusinessOperation = Enums.BusinessTransactions.ARWriteOff Or
			BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance
		Then
			IncomeItem = Undefined;
			DimensionOfRevenue = Undefined;
		Else
			ExpenseItem = Undefined;
			DimensionOfExpenses = Undefined;
		EndIf;
		
		// Filling in the currency of mutual settlements if the "Use as Currency" option is disabled
		If Not GetFunctionalOption("UseMultipleCurrencies") Then
			If Not ValueIsFilled(ARAPCurrency) Then
				ARAPCurrency = Constants.ManagementAccountingCurrency.Get();
			EndIf;
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Debt_");
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustmentFinancialInstruments.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ARAPAdjustmentFinancialInstruments.AccountingAccountSettings_(BusinessOperation));
		
	ClearSettlementDocument();
	ARAPAdjustmentFinancialInstrumentsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ARAPAdjustmentFinancialInstrumentsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ARAPAdjustmentFinancialInstrumentsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ARAPAdjustmentFinancialInstrumentsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing;
	ElsIf NonCurrentAssets.VNAManagementIsUsed() Then
		ContractKind = Enums.ContractKindsOfFinancialInstruments.Lease;
	EndIf;
	
EndProcedure

Procedure FillByStructure(FillingData)
	
	If FillingData.Property("BusinessOperation") Then
		BusinessOperation = FillingData.BusinessOperation;
	EndIf;
	
EndProcedure

#EndRegion
Procedure ClearSettlementDocument()
	
	For Each LineOfATabularSection In Debt_ Do
		
		If ValueIsFilled(LineOfATabularSection.ARAPDocument)
			And LineOfATabularSection.AmountType <> Enums.TypesOfLeasePayments.DepositPayment
			And LineOfATabularSection.AmountType <> Enums.TypesOfLeasePayments.RentalServicePrepayment Then
			LineOfATabularSection.ARAPDocument = Undefined;
		EndIf;
			
	EndDo;
	
EndProcedure
#EndRegion

#EndIf
