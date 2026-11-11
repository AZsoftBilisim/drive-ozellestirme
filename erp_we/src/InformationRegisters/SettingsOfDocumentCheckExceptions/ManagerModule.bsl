#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves document types that should not be counted as verifiable. According to them, data can be stored in the inf. in the database,
// but they are no longer counted.
// 
// Parameters:
// 	OnlyWithoutPossibilityOfChange - Boolean - provided that it is necessary to return only those documents
// 		for which the settings are not set manually by the user (it is necessary when the result of the function is used in a query
// 		with a separate receipt of data from the exception table). The default value is False.
//
// Returns:
//	Array of Type - Types of documents that should not be checked.
//
Function ExcludedTypesOfDocumentsForVerification(OnlyWithoutPossibilityOfChange = False) Export
	
	ReturnArray = New Array;
	
	If Not OnlyWithoutPossibilityOfChange Then
		
		ReturnArray = TableOfExcludedDocuments().UnloadColumn("Type");
		
	EndIf;
	
	CommonClientServer.SupplementArray(ReturnArray, ExcludedTypesToCheckWithoutPossibilityOfModification());
	
	Return ReturnArray;
	
EndFunction

// Gets the names of documents that should not be counted as verifiable. According to them, data can be stored in the inf. in the database,
// but they are no longer counted.
// 
// Parameters:
// 	OnlyWithoutPossibilityOfChange - Boolean - provided that it is necessary to return only those documents
// 	for which the settings are not set manually by the user (it is necessary when the result of the function is used in a query
// 	with a separate receipt of data from the exception table). The default value is False.
//
// Returns:
//	Array of String - Names of documents that should not be checked.
//
Function ExcludedDocumentsForVerification(OnlyWithoutPossibilityOfChange = False) Export
	
	ReturnArray = New Array;
	
	If Not OnlyWithoutPossibilityOfChange Then
		
		ReturnArray = TableOfExcludedDocuments().UnloadColumn("DocumentName");
		
	EndIf;
	
	CommonClientServer.SupplementArray(ReturnArray, ExcludedDocumentsForVerificationWithoutPossibilityOfModification());
	
	Return ReturnArray;
	
EndFunction

#EndRegion

#Region Private

Function ExcludedTypesToCheckWithoutPossibilityOfModification()
	
	ReturnArray = New Array;
	
	For Each NameOfExcludedDocument In ExcludedDocumentsForVerificationWithoutPossibilityOfModification() Do
		ReturnArray.Add(Type("DocumentRef." + NameOfExcludedDocument));
	EndDo;
	
	Return ReturnArray;
	
EndFunction

Function ExcludedDocumentsForVerificationWithoutPossibilityOfModification()
	
	ReturnArray = New Array;
	mDocuments = Metadata.Documents;
	
	ReturnArray.Add(mDocuments.OBEntry.Name);
	ReturnArray.Add(mDocuments.OBEntryARAP.Name);
	ReturnArray.Add(mDocuments.OBEntryCash.Name);
	ReturnArray.Add(mDocuments.OBEntrySalesForPastPeriods.Name);
	ReturnArray.Add(mDocuments.OBEntryFinancialInstruments.Name);
	ReturnArray.Add(mDocuments.OBEntryOtherExpenses.Name);
	ReturnArray.Add(mDocuments.OBEntryOtherAssetsAndLiabilities.Name);
	ReturnArray.Add(mDocuments.OBEntryAcquiringContractARAP.Name);
	ReturnArray.Add(mDocuments.OBEntryARAPAdvanceHolders.Name);
	ReturnArray.Add(mDocuments.OBEntryGoods.Name);
	ReturnArray.Add(mDocuments.CorrectionOfSidedBalanceInCompanyGoodsAccounting.Name);
	ReturnArray.Add(mDocuments.AllocationOfIncomeByLinesOfBusiness.Name);
	ReturnArray.Add(mDocuments.VATAllocation.Name);
	ReturnArray.Add(mDocuments.AllocationOfOtherCosts.Name);
	ReturnArray.Add(mDocuments.ExchangeDifferenceCalculation.Name);
	ReturnArray.Add(mDocuments.CalculationOfDiscountInterestExpenses.Name);
	ReturnArray.Add(mDocuments.InventoryCostCalculation.Name);
	ReturnArray.Add(mDocuments.CostCalculationRecorder.Name);
	ReturnArray.Add(mDocuments.ARAPAccountingRecorder.Name);
	ReturnArray.Add(mDocuments.ARAPAccountingScheduleAdjustment.Name);
	ReturnArray.Add(mDocuments.IntangibleAssetsAmortizationCharge2_4.Name);
	ReturnArray.Add(mDocuments.FixedAssetsDepreciationCharge2_4.Name);
	ReturnArray.Add(mDocuments.AccrualOfLeaseInterest.Name);
	ReturnArray.Add(mDocuments.AccrualAndWriteOffOfBadDebtAlowances.Name);
	ReturnArray.Add(mDocuments.CalculationOfInventoryImpairmentProvision.Name);
	ReturnArray.Add(mDocuments.PeriodEndTransactionFinancialAccounting.Name);
	DocumentVerificationLocalization.CompleteExcludedDocumentsForVerification(ReturnArray);
	
	Return ReturnArray;
	
EndFunction

Function TableOfExcludedDocuments()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Data.Name AS DocumentName,
	|	VALUETYPE(Data.EmptyRefValue) AS Type
	|FROM
	|	InformationRegister.SettingsOfDocumentCheckExceptions AS ExceptionSettings
	|	INNER JOIN Catalog.MetadataObjectIDs AS Data
	|	ON ExceptionSettings.DocumentKind = Data.Ref
	|	AND NOT Data.DeletionMark
	|WHERE
	|	NOT ExceptionSettings.IsChecked";
	
	ReturnTable = Query.Execute().Unload();
	
	Return ReturnTable;
	
EndFunction

#EndRegion

#EndIf