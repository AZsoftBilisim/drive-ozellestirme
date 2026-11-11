#Region Internal

// Returns a fact table based on the results of correspondence between balance registers.
//
// Parameters:
//  DocumentsForProcessing_ - ValueTable
//  FactGettingParameters - Structure - parameters for getting the fact, including:
//   * Period - StandardPeriod
//  RulesTable - ValueTable:
//   * DataSourceXO - CatalogRef.BusinessTransactionsSettings
//   * TypeOfAccountingDataReceipt - EnumRef.AccountingDataTypes
//   * TypeOfAccountingDataExpense - EnumRef.AccountingDataTypes
//
// Returns:
//  ValueTable - See BudgetingServer.FactTableTemplateForBudgetItems
//
Function ActualDataOfOperationalAccounting(DocumentsForProcessing_, FactGettingParameters, RulesTable) Export
	
	ActualDataTable = BudgetingServer.FactTableTemplateForBudgetItems(FactGettingParameters);
	ActualDataTable.Columns.Add("Rule", New TypeDescription("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"));
	
	BalanceFinancialRegisters = New Map();
	DocumentsKinds = DocumentsForProcessing_.Copy(, "DocumentKind");
	DocumentsKinds.GroupBy("DocumentKind");
	
	For Each LineDocument In DocumentsKinds Do
		BalanceRegistersByDocumentType = BudgetingCached.ResidualFinancialRegistersByTypeOfDocument(
			LineDocument.DocumentKind);
		For Each KeyAndValue In BalanceRegistersByDocumentType Do
			BalanceFinancialRegisters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndDo;
	
	If BalanceFinancialRegisters.Count() = 0 Then
		Return ActualDataTable;
	EndIf;
	
	TempTablesManager = New TempTablesManager();
	QueryOptions = ParametersForRequestingFinancialRegisterData(DocumentsForProcessing_, FactGettingParameters, RulesTable);
	Query = RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager);
	QueriesTexts = New Array();
	
	RequestTextsForRegisterEntries = RequestTextsForRegisterEntries(Query, BalanceFinancialRegisters);
	
	QueriesTexts.Add(RequestTextForCorrespondenceRecords(RequestTextsForRegisterEntries));
	
	GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts);
	
	AllocateUnbalancedCorrespondenceResources(Query, QueriesTexts);
	
	CheckCorrespondenceErrors(Query, QueriesTexts, DocumentsForProcessing_, RulesTable);
	
	CreateRegisterRecordTableOfServiceAccountingObjects(Query, QueriesTexts);
	
	CreateTableOfComplexCorrespondence(Query, QueriesTexts);
	
	CreateRulesForReceivingFactOfCorrespondence(Query, QueriesTexts);
	
	ApplyRulesOfFactReceiptToCorrespondence(Query, QueriesTexts, RequestTextsForRegisterEntries);
	
	CreateRulesForFillingInAnalytics(Query, QueriesTexts);
	
	IdentifyResourcesOfDataSources(Query, QueriesTexts);
	
	GenerateCorrespondenceAnalyticsRequests(Query, QueriesTexts, RequestTextsForRegisterEntries);
	
	FinancialAccountingByBalanceSheetRegisterData.DestroyTemporaryTables(Query, QueriesTexts);
	
	FillInActualDataTable(Query, QueriesTexts, ActualDataTable,
		DocumentsForProcessing_, FactGettingParameters, RulesTable);
	
	Return ActualDataTable;
	
EndFunction

// Returns the structure of financial accounting settings with property values accepted in the budgeting subsystem.
// 
// Returns:
//  See ChartsOfCharacteristicTypes.AssetLiabilityItems.FinancialAccounting_Settings
//
Function FinancialAccountingSettingsForBudgeting() Export
	
	AccountingSettings = ChartsOfCharacteristicTypes.AssetLiabilityItems.FinancialAccounting_Settings();
	
	AccountingSettings.FormationOfCorrespondence = True;
	AccountingSettings.AccountingForImproperValues = False;
	AccountingSettings.RevenueAccountingExcludingVAT = True;
	AccountingSettings.RevenueAccountingWithVAT = False;
	
	Return AccountingSettings;
	
EndFunction

// Returns a description of all available fields of the data source asset and liability items.
// 
// Parameters:
//  RegisterName - String - Name of the data source register
//  AccountingReflectionParameters - See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//  
// Returns:
//  Structure of KeyAndValue - LongDesc:
//   * Key - String - The name of the register dimension, the name of the Attribute of the dimension - the analytics key, or the name of the register Attribute
//   * Value - See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
//
Function DescriptionOfFinancialRegisterFields(RegisterName, AccountingReflectionParameters = Undefined) Export
	
	If AccountingReflectionParameters = Undefined Then
		RegisterManager = AccumulationRegisters[RegisterName]; // AccumulationRegisterManager -
		AccountingReflectionParameters = RegisterManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(); // See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
	EndIf;
	
	FieldsDetails = New Structure();
	
	For Each DetailsOfDimension In AccountingReflectionParameters.DimensionsDetails Do
		FieldsDetails.Insert(DetailsOfDimension.Key, Common.CopyRecursive(DetailsOfDimension.Value));
	EndDo;
	
	For Each AttributeDetails In AccountingReflectionParameters.AttributesDetails1 Do
		FieldsDetails.Insert(AttributeDetails.Key, Common.CopyRecursive(AttributeDetails.Value));
	EndDo;
	
	Return FieldsDetails;
	
EndFunction

// Returns the name of the resource value based on the passed resource group name
// 
// Parameters:
//  ResourceGroup - String - Name of the resource group of the data source
//  
// Returns:
//  String - Name of the resource value
//
Function NameOfResourceGroupValue(ResourceGroup) Export
	
	AssetLiabilityItemManager = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	
	If ResourceGroup = AssetLiabilityItemManager.ManagementAccountingResourcesGroup() Then
		EnumValueName = "SumMan";
	ElsIf ResourceGroup = AssetLiabilityItemManager.RegulatedAccountingResourcesGroup() Then
		EnumValueName = "SumCompl";
	ElsIf ResourceGroup = AssetLiabilityItemManager.CurrencyAccountingResourcesGroup() Then
		EnumValueName = "SumCurr";
	ElsIf ResourceGroup = AssetLiabilityItemManager.QuantitativeAccountingResourcesGroup() Then
		EnumValueName = "Count";
	Else
		EnumValueName = "";
	EndIf;
	
	Return EnumValueName;
	
EndFunction

#EndRegion

#Region Private

Function ParametersForRequestingFinancialRegisterData(DocumentsForProcessing_, FactGettingParameters, RulesTable)
	
	QueryOptions = FinancialAccountingByBalanceSheetRegisterData.ParametersForRequestingFinancialRegisterData();
	QueryOptions.Insert("DocumentsForProcessing_", DocumentsForProcessing_);
	
	If TypeOf(FactGettingParameters.Period) = Type("StandardPeriod") Then
		If QueryOptions.StartDate > '00010101' Then
			QueryOptions.StartDate = FactGettingParameters.Period.StartDate;
		EndIf;
		If QueryOptions.StartDate > '00010101' Then
			QueryOptions.EndDate = FactGettingParameters.Period.EndDate;
		EndIf;
	EndIf;
	
	QueryOptions.Insert("OperationalAccountingRules", RulesTable.Copy(
		New Structure("DataSourceSection,RuleType",
			Enums.SectionsOfBudgetingDataSources.OperationalAccounting,
			Enums.ActualBudgetingDataQueryRuleType.ActualData),
		"Rule"));
	
	DescriptionIndicator = ChartsOfCharacteristicTypes.AssetLiabilityItems.NewDescriptionOfIndicator();
	For Each KeyAndValue In DescriptionIndicator Do
		ResourceGroup = KeyAndValue.Key;
		QueryOptions.Insert(ResourceGroup, ResourceGroup);
	EndDo;
	
	Return QueryOptions;
	
EndFunction

Function RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager)
	
	Query = FinancialAccountingByBalanceSheetRegisterData.RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager);
	
	QuantityQualifiers = Metadata.AccumulationRegisters.ActualBudgetingData.Resources.Count.Type.NumberQualifiers;
	Query.Parameters.LengthOfQuantity = QuantityQualifiers.Digits;
	Query.Parameters.QuantityAccuracy = QuantityQualifiers.FractionDigits;
	
	Query.SetParameter("AllAnalyticsExpressions", New Map());
	
	Query.SetParameter("NameOfFieldsFolder", DataSourcesServer.NameOfDataSourceFieldsFolder());
	Query.SetParameter("FolderNameCorFields", DataSourcesServer.NameOfFolderOfFieldsOfCorDataSource());
	Query.SetParameter("PrefixOfFieldNames", DataSourcesServer.PrefixOfFieldNamesCorOfDataSource());
	Query.SetParameter("LengthOfFieldsFolderName", StrLen(Query.Parameters.NameOfFieldsFolder));
	Query.SetParameter("LengthOfFolderNameCorFields", StrLen(Query.Parameters.FolderNameCorFields));
	Query.SetParameter("PrefixLengthOfFieldNames", StrLen(Query.Parameters.PrefixOfFieldNames));
	
	QueriesTexts = New Array();
	QueriesTexts.Add("
	|SELECT
	|	DocumentsForProcessing_.Document AS Recorder,
	|	DocumentsForProcessing_.DocumentKind AS DocumentKind
	|INTO TTDocumentsForProcessing
	|FROM
	|	&DocumentsForProcessing_ AS DocumentsForProcessing_
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	DocumentsForProcessing_.Recorder,
	|	DocumentsForProcessing_.DocumentKind AS DocumentKind
	|INTO TTPortionOfDocuments
	|FROM
	|	TTDocumentsForProcessing AS DocumentsForProcessing_
	|WHERE
	|	NOT DocumentsForProcessing_.Recorder REFS Document.PaymentRequest
	|	AND NOT DocumentsForProcessing_.Recorder REFS Document.ApplicationForBusinessTrip
	|INDEX BY
	|	Recorder
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	OperationalAccountingRules.Rule AS Ref
	|INTO TTRulesOfOperationalAccounting
	|FROM
	|	&OperationalAccountingRules AS OperationalAccountingRules
	|INDEX BY
	|	Ref
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTDocumentsForProcessing");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Result = Query.ExecuteBatch();
	
	Query.Parameters.Delete("DocumentsForProcessing_");
	Query.Parameters.Delete("OperationalAccountingRules");
	
	Return Query;
	
EndFunction

Function CaseRecordRequestTextTemplate()
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&RegisterName AS RegisterName,
	|	&AccountingObject AS AccountingObject,
	|	&ThisIsDebit AS ThisIsDebit,
	|	&ThisIsLoan AS ThisIsLoan,
	|	&ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&AnalyticsSelectionFields,
	|	&Recorder AS Recorder,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	&FinRecordID AS FinRecordID,
	|	&RowID AS RowID,
	|	&VATActivityType AS OfficialTypeOfActivityVAT,
	|	&Currency AS Currency,
	|	&SumMan AS SumMan,
	|	&SumCompl AS SumCompl,
	|	&SumCurr AS SumCurr,
	|	&Count AS Count,
	|	&DataSourceResources,
	|	&PropsStorno AS PropsStorno
	|FROM
	|	&DataSource
	|WHERE
	|	&Active
	|	AND &FinRecordID <> &IDOfUnusedFinRecord
	|	AND &ConditionPeriod
	|	AND &ConditionLogger
	|	AND &OrganizationCondition
	|	AND &ResourceValueCondition
	|	AND &ConditionDocumentsToBeDeleted
	|	AND &ConditionAdditionalSelection
	|GROUP BY
	|	&Period,
	|	&AccountingObject,
	|	&ThisIsDebit,
	|	&ThisIsLoan,
	|	&ThisIsReverseTransaction,
	|	&AnalyticsFieldGroup,
	|	&Recorder,
	|	&Organization,
	|	&Department,
	|	&LineOfBusiness,
	|	&SettingUpBusinessTransaction,
	|	&FinRecordID,
	|	&RowID,
	|	&Currency,
	|	&PropsStorno
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextsForRegisterEntries(Query, BalanceFinancialRegisters)
	
	RegisterRequestsTexts = New Structure();
	
	AccountingSettings = FinancialAccountingSettingsForBudgeting();
	FinancialAccountingObjects = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObjects(AccountingSettings);
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();
	
	For Each KeyAndValue In BalanceFinancialRegisters Do
		NameOfDataSource = KeyAndValue.Key;
		MotionReflectionParameters = KeyAndValue.Value;
		
		RegisterMetadata = AccumulationRegistersMetadata[NameOfDataSource];
		
		TheStructureOfTheSearch = New Structure("DataSource", NameOfDataSource);
		AccountingObjectRows_ = FinancialAccountingObjects.FindRows(TheStructureOfTheSearch);
		
		If AccountingObjectRows_.Count() = 0 Then
			Continue;
		EndIf;
		
		If RegistersOfRecoveryOfCalculationsOnStorno.Find(NameOfDataSource) <> Undefined Then
			Query.Parameters.RestoreCalculationsForStorno = True;
		EndIf;
		
		FinancialAccountingByBalanceSheetRegisterData.ClarifyParametersOfReflectionOfRegisteredRecorded(
			MotionReflectionParameters, RegisterMetadata);
		
		AccountingObjectResourceKeys = New Map();
		
		For Each AccountingObjectLine_ In AccountingObjectRows_ Do
			FinancialAccountingByBalanceSheetRegisterData.FillInCorDataSources(Query.Parameters, AccountingObjectLine_);
			FinancialAccountingByBalanceSheetRegisterData.FillInItemsBasedOnVATAccountingCriteria(Query.Parameters, AccountingObjectLine_);
			
			FinancialAccountingByBalanceSheetRegisterData.ClarifyPropertiesOfAccountingObject(
				MotionReflectionParameters, AccountingObjectLine_, RegisterMetadata);
			
			ResourceKey = FinancialAccountingByBalanceSheetRegisterData.ResourceKeyOfAccountingObject(AccountingObjectLine_);
			
			If AccountingObjectResourceKeys[ResourceKey] = Undefined Then
				AccountingObjectResourceKeys.Insert(ResourceKey, New Array());
			EndIf;
			
			AccountingObjectResourceKeys[ResourceKey].Add(AccountingObjectLine_);
		EndDo;
		
		If AccountingObjectResourceKeys.Count() = 1 Then
			FieldsOfAccountingObjectSelection = RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(
				AccountingObjectRows_, MotionReflectionParameters, Query.Parameters);
		Else
			FieldsOfAccountingObjectSelection = New Structure();
			SelectionFieldNames = SelectionFieldsBasedOnDescriptionOfAccountingObject();
			
			For Each FieldName In SelectionFieldNames Do
				FieldsOfAccountingObjectSelection.Insert(FieldName, New Map());
			EndDo;
			
			ResourceKeyNumber = 0;
			
			For Each KeyForAccountingObjectResources In AccountingObjectResourceKeys Do
				ResourceKeyNumber = ResourceKeyNumber + 1;
				AccountingObjectRows_ = KeyForAccountingObjectResources.Value;
				
				RowsOfSelectionOfAccountingObjectFields = RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(
					AccountingObjectRows_, MotionReflectionParameters, Query.Parameters);
				
				For Each KeyAndValue In FieldsOfAccountingObjectSelection Do
					FieldSelectionString_ = RowsOfSelectionOfAccountingObjectFields[KeyAndValue.Key];
					If KeyAndValue.Value[FieldSelectionString_] = Undefined Then
						KeyAndValue.Value.Insert(FieldSelectionString_, New Array());
					EndIf;
					KeyAndValue.Value[FieldSelectionString_].Add(ResourceKeyNumber);
				EndDo;
			EndDo;
			
			For Each FieldName In SelectionFieldNames Do
				SampleRowsFields = FieldsOfAccountingObjectSelection[FieldName];
				AccountingObjectSelectionField = FinancialAccountingByBalanceSheetRegisterData.FieldValueSelectionString(SampleRowsFields);
				FieldsOfAccountingObjectSelection.Insert(FieldName, AccountingObjectSelectionField);
			EndDo;
		EndIf;
		
		If IsBlankString(MotionReflectionParameters.PathToDataDivision) Then
			Department = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.BusinessStructure.EmptyRef());
		Else
			Department = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.PathToDataDivision);
		EndIf;
		
		If IsBlankString(MotionReflectionParameters.DataPathCurrency) Then
			Currency = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.Currencies.EmptyRef());
		Else
			Currency = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.DataPathCurrency);
		EndIf;
		
		If IsBlankString(MotionReflectionParameters.DataPathIsStorno) Then
			PropsStorno = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(False);
		Else
			PropsStorno = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.DataPathIsStorno);
		EndIf;
		
		RegisterName = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(NameOfDataSource);
		Recorder = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.DataPathLogger);
		Organization = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.DataPathOrganization);
		
		If IsBlankString(MotionReflectionParameters.PathToDataVATActivity) Then
			VATActivityType = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Enums.VATTaxationTypes.EmptyRef());
		Else
			VATActivityType = StrTemplate("MAX(%1)",
				FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.PathToDataVATActivity));
		EndIf;
		
		If FinancialAccountingByBalanceSheetRegisterData.ResourceIsMissingOrMayBeEmpty(MotionReflectionParameters.ManResources) Then
			Query.Parameters.RegistersWithoutManSum.Add(NameOfDataSource);
		EndIf;
		
		If FinancialAccountingByBalanceSheetRegisterData.ResourceIsMissingOrMayBeEmpty(MotionReflectionParameters.LocalResources) Then
			Query.Parameters.RegistersWithoutSumLocal.Add(NameOfDataSource);
		EndIf;
		
		DataSource = StrTemplate("AccumulationRegister.%1 AS RegisterTable
			|	INNER JOIN TTPortionOfDocuments AS PortionOfDocuments
			|		ON &Recorder = PortionOfDocuments.Recorder", NameOfDataSource);
		
		If AccountingObjectResourceKeys.Count() > 1 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRepeaterToDataSource(DataSource, AccountingObjectResourceKeys.Count());
		EndIf;
		
		ConditionPeriod = FinancialAccountingByBalanceSheetRegisterData.ConditionStringPeriod(Query.Parameters);
		ConditionLogger = FinancialAccountingByBalanceSheetRegisterData.ConditionStringLogger(Query.Parameters);
		OrganizationCondition = FinancialAccountingByBalanceSheetRegisterData.OrganizationConditionLine(Query.Parameters);
		ConditionDocumentsToBeDeleted = FinancialAccountingByBalanceSheetRegisterData.ConditionLineDocumentsToBeDeleted(RegisterMetadata);
		ConditionAdditionalSelection = FinancialAccountingByBalanceSheetRegisterData.StringAdditionalSelection(MotionReflectionParameters);
		
		If NameOfDataSource = AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name Then
			ConditionAdditionalSelection = ConditionAdditionalSelection + StrReplace("
				|	AND (DataSourceAlias.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
				|		OR DataSourceAlias.AccountingDimensionByPartners.Organization <> VALUE(Catalog.Companies.ManagementCompany))",
				"DataSourceAlias",
				MotionReflectionParameters.DataSourceAlias);
		ElsIf NameOfDataSource = AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name Then
			ConditionAdditionalSelection = ConditionAdditionalSelection + StrReplace("
				|	AND (DataSourceAlias.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
				|		OR DataSourceAlias.AccountingDimensionByPartners.Organization <> VALUE(Catalog.Companies.ManagementCompany))",
				"DataSourceAlias",
				MotionReflectionParameters.DataSourceAlias);
		EndIf;
		
		If Query.TempTablesManager.Tables.Find("DocumentCache") <> Undefined Then
			ConditionAdditionalSelection = ConditionAdditionalSelection + "
				|	AND NOT TRUE IN
				|		(SELECT TOP 1
				|			TRUE
				|		FROM
				|			DocumentCache AS DocumentCache
				|		WHERE
				|			DocumentCache.Recorder = &Recorder
				|			AND DocumentCache.Period = &Period)";
		EndIf;
		
		QueryText = CaseRecordRequestTextTemplate();
		
		If AccountingObjectResourceKeys.Count() > 1 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRepeaterToDimensionFields(QueryText);
		EndIf;
		
		QueryText = StrReplace(QueryText, "&AccountingObject", FieldsOfAccountingObjectSelection.AccountingObject);
		QueryText = StrReplace(QueryText, "&LineOfBusiness", FieldsOfAccountingObjectSelection.LineOfBusiness);
		QueryText = StrReplace(QueryText, "&FinRecordID", FieldsOfAccountingObjectSelection.FinRecordID);
		QueryText = StrReplace(QueryText, "&SettingUpBusinessTransaction", FieldsOfAccountingObjectSelection.SettingUpBusinessTransaction);
		QueryText = StrReplace(QueryText, "&RowID", FieldsOfAccountingObjectSelection.RowID);
		QueryText = StrReplace(QueryText, "&ThisIsDebit", FieldsOfAccountingObjectSelection.ThisIsDebit);
		QueryText = StrReplace(QueryText, "&ThisIsLoan", FieldsOfAccountingObjectSelection.ThisIsLoan);
		QueryText = StrReplace(QueryText, "&ThisIsReverseTransaction", FieldsOfAccountingObjectSelection.ThisIsReverseTransaction);
		QueryText = StrReplace(QueryText, "&SumMan", FieldsOfAccountingObjectSelection.SumMan);
		QueryText = StrReplace(QueryText, "&SumCompl", FieldsOfAccountingObjectSelection.SumCompl);
		QueryText = StrReplace(QueryText, "&SumCurr", FieldsOfAccountingObjectSelection.SumCurr);
		QueryText = StrReplace(QueryText, "&Count", FieldsOfAccountingObjectSelection.Count);
		QueryText = StrReplace(QueryText, "&ResourceValueCondition", FieldsOfAccountingObjectSelection.ResourceValueCondition);
		
		QueryText = StrReplace(QueryText, "&DataSource", DataSource);
		QueryText = StrReplace(QueryText, "&ConditionPeriod", ConditionPeriod);
		QueryText = StrReplace(QueryText, "&ConditionLogger", ConditionLogger);
		QueryText = StrReplace(QueryText, "&OrganizationCondition", OrganizationCondition);
		QueryText = StrReplace(QueryText, "&ConditionDocumentsToBeDeleted", ConditionDocumentsToBeDeleted);
		QueryText = StrReplace(QueryText, "&ConditionAdditionalSelection", ConditionAdditionalSelection);
		QueryText = StrReplace(QueryText, "&RegisterName", RegisterName);
		QueryText = StrReplace(QueryText, "&Currency", Currency);
		QueryText = StrReplace(QueryText, "&Recorder", Recorder);
		QueryText = StrReplace(QueryText, "&Organization", Organization);
		QueryText = StrReplace(QueryText, "&Department", Department);
		QueryText = StrReplace(QueryText, "&VATActivityType", VATActivityType);
		QueryText = StrReplace(QueryText, "&PropsStorno", PropsStorno);
		
		QueryText = StrReplace(QueryText, "&RequestParameterRegistrar", "&Recorder");
		QueryText = StrReplace(QueryText, "&RequestParameterOrganization", "&Organization");
		
		QueryText = StrReplace(QueryText, "&Period", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("Period"));
		QueryText = StrReplace(QueryText, "&Active", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("Active"));
		QueryText = StrReplace(QueryText, "&RecordType", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("RecordType"));
		
		If NameOfDataSource = AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name Then
			TextOfNestedTable = "(" + QueryText + ")";
			
			// delete after error correction 00-00450915
			AccrualOfClientSAdvancePaymentUponReturn = "(RegisterTable.ThisIsLoan
			|	AND RegisterTable.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.EmptyRef),
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsPayable))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ReturnOfGoodsFromCustomer),
			|		TYPE(Document.SaleAdjustment),
			|		TYPE(Document.ARAPAdjustment)))";
			
			// delete after fixing the cause of the error 00-00556880
			CustomerPrepaymentSettlementDuringAdjustment = "(RegisterTable.ThisIsDebit
			|	AND RegisterTable.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsReceivable))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ARAPAdjustment)))";
			
			// delete after fixing the cause of the error 00-00570173
			AccrualOfClientSAdvancePaymentUponAdjustment = "(RegisterTable.ThisIsDebit
			|	AND RegisterTable.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.APWriteOff))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ARAPAdjustment)))";
			
			QueryText = "
			|SELECT
			|	RegisterTable.Period AS Period,
			|	RegisterTable.RegisterName AS RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				WHEN &AccrualOfClientSAdvancePaymentUponAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|				ELSE RegisterTable.AccountingObject
			|			END
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|			END
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|			END
			|		WHEN &AccrualOfClientSAdvancePaymentUponAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|			END
			|		ELSE RegisterTable.AccountingObject
			|	END AS AccountingObject,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END AS ThisIsDebit,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END AS ThisIsLoan,
			|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
			|	&NestedTableAnalyticsFields,
			|	RegisterTable.Recorder AS Recorder,
			|	RegisterTable.Organization AS Organization,
			|	RegisterTable.Department AS Department,
			|	RegisterTable.LineOfBusiness AS LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
			|		WHEN &AccrualOfClientSAdvancePaymentUponAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END AS SettingUpBusinessTransaction,
			|	RegisterTable.FinRecordID AS FinRecordID,
			|	RegisterTable.RowID AS RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT AS OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency AS Currency,
			|	SUM(RegisterTable.SumMan) AS SumMan,
			|	SUM(RegisterTable.SumCompl) AS SumCompl,
			|	SUM(RegisterTable.SumCurr) AS SumCurr,
			|	SUM(RegisterTable.Count) AS Count,
			|	&SumsOfResourcesOfNestedDataSource,
			|	RegisterTable.PropsStorno AS PropsStorno
			|FROM
			|	&TextOfNestedTable AS RegisterTable
			|	,
			|	(SELECT
			|		UNDEFINED AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Dr AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Cr AS DrCr
			|	) AS PartsOfDoubleEntry
			|WHERE
			|	PartsOfDoubleEntry.DrCr = UNDEFINED
			|	OR &AccrualOfClientSAdvancePaymentUponReturn
			|	OR &CustomerPrepaymentSettlementDuringAdjustment
			|	OR &AccrualOfClientSAdvancePaymentUponAdjustment
			|GROUP BY
			|	RegisterTable.Period,
			|	RegisterTable.RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				WHEN &AccrualOfClientSAdvancePaymentUponAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|				ELSE RegisterTable.AccountingObject
			|			END
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|			END
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|			END
			|		WHEN &AccrualOfClientSAdvancePaymentUponAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers)
			|			END
			|		ELSE RegisterTable.AccountingObject
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END,
			|	RegisterTable.ThisIsReverseTransaction,
			|	&NestedTableAnalyticsGroup,
			|	RegisterTable.Recorder,
			|	RegisterTable.Organization,
			|	RegisterTable.Department,
			|	RegisterTable.LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
			|		WHEN &AccrualOfClientSAdvancePaymentUponAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END,
			|	RegisterTable.FinRecordID,
			|	RegisterTable.RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency,
			|	RegisterTable.PropsStorno
			|";
			
			QueryText = StrReplace(QueryText, "&TextOfNestedTable", TextOfNestedTable);
			QueryText = StrReplace(QueryText, "&AccrualOfClientSAdvancePaymentUponReturn", AccrualOfClientSAdvancePaymentUponReturn);
			QueryText = StrReplace(QueryText, "&CustomerPrepaymentSettlementDuringAdjustment", CustomerPrepaymentSettlementDuringAdjustment);
			QueryText = StrReplace(QueryText, "&AccrualOfClientSAdvancePaymentUponAdjustment", AccrualOfClientSAdvancePaymentUponAdjustment);
			
		ElsIf NameOfDataSource = AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name Then
			TextOfNestedTable = "(" + QueryText + ")";
			
			// delete after error correction 00-00453822
			AccrualOfAdvancePaymentToSupplierUponReturn = "(RegisterTable.ThisIsDebit
			|	AND RegisterTable.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.EmptyRef),
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsReceivable))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ReturnOfGoodsToVendor),
			|		TYPE(Document.PurchaseAdjustment),
			|		TYPE(Document.ARAPAdjustment)))";
			
			// delete after fixing the cause of the error 00-00556880
			VendorPrepaymentSettlementDuringAdjustment = "(RegisterTable.ThisIsLoan
			|	AND RegisterTable.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsPayable))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ARAPAdjustment)))";
			
			// delete after fixing the cause of the error 00-00570173
			AccrualOfAdvancePaymentToSupplierUponAdjustment = "(RegisterTable.ThisIsLoan
			|	AND RegisterTable.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.ARWriteOff))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ARAPAdjustment)))";
			
			QueryText = "
			|SELECT
			|	RegisterTable.Period AS Period,
			|	RegisterTable.RegisterName AS RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|				WHEN &VendorPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|				WHEN &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|				ELSE RegisterTable.AccountingObject
			|			END
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|			END
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|			END
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|			END
			|		ELSE RegisterTable.AccountingObject
			|	END AS AccountingObject,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END AS ThisIsDebit,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END AS ThisIsLoan,
			|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
			|	&NestedTableAnalyticsFields,
			|	RegisterTable.Recorder AS Recorder,
			|	RegisterTable.Organization AS Organization,
			|	RegisterTable.Department AS Department,
			|	RegisterTable.LineOfBusiness AS LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.VendorPrepaymentSettlement)
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END AS SettingUpBusinessTransaction,
			|	RegisterTable.FinRecordID AS FinRecordID,
			|	RegisterTable.RowID AS RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT AS OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency AS Currency,
			|	SUM(RegisterTable.SumMan) AS SumMan,
			|	SUM(RegisterTable.SumCompl) AS SumCompl,
			|	SUM(RegisterTable.SumCurr) AS SumCurr,
			|	SUM(RegisterTable.Count) AS Count,
			|	&SumsOfResourcesOfNestedDataSource,
			|	RegisterTable.PropsStorno AS PropsStorno
			|FROM
			|	&TextOfNestedTable AS RegisterTable
			|	,
			|	(SELECT
			|		UNDEFINED AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Dr AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Cr AS DrCr
			|	) AS PartsOfDoubleEntry
			|WHERE
			|	PartsOfDoubleEntry.DrCr = UNDEFINED
			|	OR &AccrualOfAdvancePaymentToSupplierUponReturn
			|	OR &VendorPrepaymentSettlementDuringAdjustment
			|	OR &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|GROUP BY
			|	RegisterTable.Period,
			|	RegisterTable.RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|				WHEN &VendorPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|				WHEN &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|				ELSE RegisterTable.AccountingObject
			|			END
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|			END
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|			END
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors)
			|				ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable)
			|			END
			|		ELSE RegisterTable.AccountingObject
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END,
			|	RegisterTable.ThisIsReverseTransaction,
			|	&NestedTableAnalyticsGroup,
			|	RegisterTable.Recorder,
			|	RegisterTable.Organization,
			|	RegisterTable.Department,
			|	RegisterTable.LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.VendorPrepaymentSettlement)
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END,
			|	RegisterTable.FinRecordID,
			|	RegisterTable.RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency,
			|	RegisterTable.PropsStorno
			|";
			
			QueryText = StrReplace(QueryText, "&TextOfNestedTable", TextOfNestedTable);
			QueryText = StrReplace(QueryText, "&AccrualOfAdvancePaymentToSupplierUponReturn", AccrualOfAdvancePaymentToSupplierUponReturn);
			QueryText = StrReplace(QueryText, "&VendorPrepaymentSettlementDuringAdjustment", VendorPrepaymentSettlementDuringAdjustment);
			QueryText = StrReplace(QueryText, "&AccrualOfAdvancePaymentToSupplierUponAdjustment", AccrualOfAdvancePaymentToSupplierUponAdjustment);
		EndIf;
		
		RegisterRequestsTexts.Insert(NameOfDataSource, QueryText);
	EndDo;
	
	Return RegisterRequestsTexts;
	
EndFunction

Function RequestTextForCorrespondenceRecords(RequestTextsForRegisterEntries)
	
	QueriesTexts = New Array();
	
	For Each KeyAndValue In RequestTextsForRegisterEntries Do
		QueriesTexts.Add(KeyAndValue.Value);
	EndDo;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = StrReplace(QueryText, "&AnalyticsSelectionFields", "//AnalyticsSelectionFields");
	QueryText = StrReplace(QueryText, "&AnalyticsFieldGroup", "//AnalyticsFieldGroup");
	
	QueryText = StrReplace(QueryText, "&DataSourceResources", "//DataSourceResources");
	QueryText = StrReplace(QueryText, "&SumsOfResourcesOfNestedDataSource", "//SumsOfResourcesOfNestedDataSource");
	
	QueryText = StrReplace(QueryText, "&NestedTableAnalyticsFields", "//NestedTableAnalyticsFields");
	QueryText = StrReplace(QueryText, "&NestedTableAnalyticsGroup", "//NestedTableAnalyticsGroup");
	
	SelectionFieldsToDelete = FieldsForSelectingCorrespondenceRequestsThatAreBeingDeleted();
	IndexingFields = IndexFieldsOfCorrespondenceTable();
	PlacementTable = "TTMovementRegisters";
	
	FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(QueryText, SelectionFieldsToDelete , IndexingFields, PlacementTable);

	Return QueryText;
	
EndFunction

Procedure GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts)
	
	AddTablesOfDebitAndCreditRegisteredRecords(Query, QueriesTexts);
	ProcessAndConnectMovementTables(Query, QueriesTexts);
	
	IdentifyCorrespondenceErrors(QueriesTexts, Query.Parameters, True);
	
	If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTCorrespondenceErrors") Then
		DetermineMaximumNumberOfMovementRecords(QueriesTexts);
		
		RestoreRegisteredRecordsOfErroneousCorrespondence(QueriesTexts, Query.Parameters, "Dr");
		RestoreRegisteredRecordsOfErroneousCorrespondence(QueriesTexts, Query.Parameters, "Cr");
		
		IdentifyRegistersWithReverseRegisteredRecords(QueriesTexts);
		
		ReplaceReverseMovementWithReverse(QueriesTexts, "Dr");
		ReplaceReverseMovementWithReverse(QueriesTexts, "Cr");
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMaximumNumberOfEntries");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterRegisteredRecordsReverseDebit");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementRegistersReverseCredit");

		TableOfCorrespondenceOfRegisteredRecordsOfRegisters = Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
		
		ProcessAndConnectMovementTables(Query, QueriesTexts);
		
		IdentifyCorrespondenceWithoutErrors(QueriesTexts, Query.Parameters);
		DetermineReverseToReverseReplacementRegisters(QueriesTexts);
		
		If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTCorrespondenceWithoutErrors") Then
			ReplaceCorrespondenceReverseWithReverse(QueriesTexts,
				Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters,
				TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
			
			TableOfReverseReplacementRegisters = Query.TempTablesManager.Tables.Find("TTReverseToReverseReplacementRegisters");
			TableOfReverseReplacementRegisters = TableOfReverseReplacementRegisters.GetData().Unload();
			Query.Parameters.ReverseToReverseReplacementRegisters = TableOfReverseReplacementRegisters.UnloadColumn("RegisterName");
		Else
			Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters = TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
		EndIf;
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTReverseToReverseReplacementRegisters");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceWithoutErrors");
	Else
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
		AddEmptyTableOfReverseReplacementDocuments(QueriesTexts);
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTDebit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCredit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorDataSources");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTIdsOfCorDataSources");
	
	RestoreCalculationsForStorno(Query, QueriesTexts);
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumManDr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutManSum)
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr = RegisteredRecordsDebitCredit.SumComplCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		ELSE RegisteredRecordsDebitCredit.SumManDr
	|	END AS SumManDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumManCr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutManSum)
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr = RegisteredRecordsDebitCredit.SumComplCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		ELSE RegisteredRecordsDebitCredit.SumManCr
	|	END AS SumManCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutSumLocal)
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN RegisteredRecordsDebitCredit.SumManDr = RegisteredRecordsDebitCredit.SumManCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		ELSE RegisteredRecordsDebitCredit.SumComplDr
	|	END AS SumComplDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumComplCr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutSumLocal)
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN RegisteredRecordsDebitCredit.SumManDr = RegisteredRecordsDebitCredit.SumManCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		ELSE RegisteredRecordsDebitCredit.SumComplCr
	|	END AS SumComplCr
	|INTO TTMovementDebitCredit
	|FROM
	|	TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|
	|UNION ALL
	|
	|SELECT
	|	SettlementsWithCustomersOnStorno.Period AS Period,
	|	0 AS RecNoDr,
	|	0 AS RecNoCr,
	|	SettlementsWithCustomersOnStorno.RegisterName AS RegisterNameDr,
	|	SettlementsWithCustomersOnStorno.RegisterName AS RegisterNameCr,
	|	SettlementsWithCustomersOnStorno.AccountingObjectDr AS AccountingObjectDr,
	|	SettlementsWithCustomersOnStorno.AccountingObjectCr AS AccountingObjectCr,
	|	SettlementsWithCustomersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionDr,
	|	SettlementsWithCustomersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionCr,
	|	SettlementsWithCustomersOnStorno.Organization AS Organization,
	|	SettlementsWithCustomersOnStorno.Recorder AS Recorder,
	|	SettlementsWithCustomersOnStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	SettlementsWithCustomersOnStorno.FinRecordID AS FinRecordID,
	|	SettlementsWithCustomersOnStorno.RowID AS RowIDDr,
	|	SettlementsWithCustomersOnStorno.RowID AS RowIDCr,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeDr,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeCr,
	|	SettlementsWithCustomersOnStorno.Currency AS CurrencyDr,
	|	SettlementsWithCustomersOnStorno.Currency AS CurrencyCr,
	|	SettlementsWithCustomersOnStorno.SumManDr AS AmountOfManMovementDr,
	|	SettlementsWithCustomersOnStorno.SumManCr AS AmountOfManMovementCr,
	|	SettlementsWithCustomersOnStorno.SumComplDr AS AmountOfLocalTrafficDr,
	|	SettlementsWithCustomersOnStorno.SumComplCr AS AmountOfLocalTrafficCr,
	|	SettlementsWithCustomersOnStorno.SumCurrDr AS AmountOfMovementShaftDr,
	|	SettlementsWithCustomersOnStorno.SumCurrCr AS AmountOfMovementCrShaft,
	|	0 AS AmountOfDrMovement,
	|	0 AS CrMotionCount,
	|	SettlementsWithCustomersOnStorno.PropsStorno AS PropsStorno,
	|	FALSE AS ComplexEntryDr,
	|	FALSE AS ComplexEntryCr,
	|	TRUE AS TakeIntoAccountBusinessTransaction,
	|	SettlementsWithCustomersOnStorno.SumManDr AS SumManDr,
	|	SettlementsWithCustomersOnStorno.SumManCr AS SumManCr,
	|	SettlementsWithCustomersOnStorno.SumComplDr AS SumComplDr,
	|	SettlementsWithCustomersOnStorno.SumComplCr AS SumComplCr
	|FROM
	|	TTSettlementsWithCustomersOnStorno AS SettlementsWithCustomersOnStorno
	|
	|UNION ALL
	|
	|SELECT
	|	SettlementsWithSuppliersOnStorno.Period AS Period,
	|	0 AS RecNoDr,
	|	0 AS RecNoCr,
	|	SettlementsWithSuppliersOnStorno.RegisterName AS RegisterNameDr,
	|	SettlementsWithSuppliersOnStorno.RegisterName AS RegisterNameCr,
	|	SettlementsWithSuppliersOnStorno.AccountingObjectDr AS AccountingObjectDr,
	|	SettlementsWithSuppliersOnStorno.AccountingObjectCr AS AccountingObjectCr,
	|	SettlementsWithSuppliersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionDr,
	|	SettlementsWithSuppliersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionCr,
	|	SettlementsWithSuppliersOnStorno.Organization AS Organization,
	|	SettlementsWithSuppliersOnStorno.Recorder AS Recorder,
	|	SettlementsWithSuppliersOnStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	SettlementsWithSuppliersOnStorno.FinRecordID AS FinRecordID,
	|	SettlementsWithSuppliersOnStorno.RowID AS RowIDDr,
	|	SettlementsWithSuppliersOnStorno.RowID AS RowIDCr,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeDr,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeCr,
	|	SettlementsWithSuppliersOnStorno.Currency AS CurrencyDr,
	|	SettlementsWithSuppliersOnStorno.Currency AS CurrencyCr,
	|	SettlementsWithSuppliersOnStorno.SumManDr AS AmountOfManMovementDr,
	|	SettlementsWithSuppliersOnStorno.SumManCr AS AmountOfManMovementCr,
	|	SettlementsWithSuppliersOnStorno.SumComplDr AS AmountOfLocalTrafficDr,
	|	SettlementsWithSuppliersOnStorno.SumComplCr AS AmountOfLocalTrafficCr,
	|	SettlementsWithSuppliersOnStorno.SumCurrDr AS AmountOfMovementShaftDr,
	|	SettlementsWithSuppliersOnStorno.SumCurrCr AS AmountOfMovementCrShaft,
	|	0 AS AmountOfDrMovement,
	|	0 AS CrMotionCount,
	|	SettlementsWithSuppliersOnStorno.PropsStorno AS PropsStorno,
	|	FALSE AS ComplexEntryDr,
	|	FALSE AS ComplexEntryCr,
	|	TRUE AS TakeIntoAccountBusinessTransaction,
	|	SettlementsWithSuppliersOnStorno.SumManDr AS SumManDr,
	|	SettlementsWithSuppliersOnStorno.SumManCr AS SumManCr,
	|	SettlementsWithSuppliersOnStorno.SumComplDr AS SumComplDr,
	|	SettlementsWithSuppliersOnStorno.SumComplCr AS SumComplCr
	|FROM
	|	TTSettlementsWithSuppliersOnStorno AS SettlementsWithSuppliersOnStorno
	|INDEX BY
	|	Recorder,
	|	RowIDDr,
	|	RowIDCr,
	|	CurrencyDr,
	|	CurrencyCr,
	|	ComplexEntryDr,
	|	ComplexEntryCr
	|";
	
	QueryText = StrReplace(QueryText,
		"TableOfCorrespondenceOfRegisteredRecordsOfRegisters",
		Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
EndProcedure

Procedure AllocateUnbalancedCorrespondenceResources(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
	|	DocumentAmountsInAccountingCurrency.RowID AS RowID,
	|	DocumentAmountsInAccountingCurrency.Currency AS Currency,
	|	DocumentAmountsInAccountingCurrency.ARAPCurrency AS ARAPCurrency,
	|	DocumentAmountsInAccountingCurrency.AmountExcludingVAT AS AmountExcludingVAT,
	|	DocumentAmountsInAccountingCurrency.VATAmount AS VATAmount,
	|	DocumentAmountsInAccountingCurrency.AmountARAP AS AmountARAP,
	|	DocumentAmountsInAccountingCurrency.AmountVATARAP AS AmountVATARAP
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|		WHERE
	|			RegisteredRecordsDebitCredit.Recorder = DocumentAmountsInAccountingCurrency.Recorder
	|			AND (RegisteredRecordsDebitCredit.ComplexEntryDr OR RegisteredRecordsDebitCredit.ComplexEntryCr)
	|		)
	|	AND NOT
	|		(DocumentAmountsInAccountingCurrency.Currency IN
	|			(&ManagementAccountingCurrency,
	|			VALUE(Catalog.Currencies.EmptyRef))
	|		AND DocumentAmountsInAccountingCurrency.ARAPCurrency IN
	|			(&ManagementAccountingCurrency,
	|			VALUE(Catalog.Currencies.EmptyRef))
	|		)
	|INDEX BY
	|	Recorder,
	|	RowID,
	|	Currency,
	|	ARAPCurrency,
	|	AmountVATARAP
	|");
	
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS LineNumber,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	0 AS ComplexRecordNumber,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS DistributableAmountShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS DistributableAmountOfCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS DistributableAmountOfDr,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS DistributableNumberOfCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = &ManagementAccountingCurrency
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN FALSE
	|		WHEN AmountsInDrCurrencies.RowID IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsSumDistributionDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = &ManagementAccountingCurrency
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN FALSE
	|		WHEN AmountsInCrCurrencies.RowID IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsSumDistributionCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN 0
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN 0
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = &ManagementAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = RegisteredRecordsDebitCredit.CurrencyCr
	|			THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft
	|		WHEN AmountsInDrCurrencies.RowID IS NULL
	|			THEN CAST(CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr * RegisteredRecordsDebitCredit.SumManDr / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr * RegisteredRecordsDebitCredit.SumComplDr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END AS NUMBER(&LengthOfSum, &SumAccuracy))
	|		WHEN RegisteredRecordsDebitCredit.VATActivityTypeDr IN (&TypesOfTaxationExcludingVAT)
	|		  OR RegisteredRecordsDebitCredit.VATActivityTypeCr IN (&TypesOfTaxationExcludingVAT)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AccountingObjectCr IN (&VATAccountingObjects)
	|					THEN 0
	|				WHEN RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.Currency
	|					THEN AmountsInDrCurrencies.AmountExcludingVAT + AmountsInDrCurrencies.VATAmount
	|				ELSE AmountsInDrCurrencies.AmountARAP
	|			END * CASE
	|				WHEN AmountsInDrCurrencies.AmountExcludingVAT < 0 OR AmountsInDrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		WHEN RegisteredRecordsDebitCredit.AccountingObjectCr IN (&VATAccountingObjects)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.Currency
	|					THEN AmountsInDrCurrencies.VATAmount
	|				ELSE AmountsInDrCurrencies.AmountVATARAP
	|			END * CASE
	|				WHEN AmountsInDrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		WHEN RegisteredRecordsDebitCredit.AccountingObjectCr IN (&AccountingObjectsWithVAT)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.Currency
	|					THEN AmountsInDrCurrencies.AmountExcludingVAT + AmountsInDrCurrencies.VATAmount
	|				ELSE AmountsInDrCurrencies.AmountARAP
	|			END * CASE
	|				WHEN AmountsInDrCurrencies.AmountExcludingVAT < 0 OR AmountsInDrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.Currency
	|				THEN AmountsInDrCurrencies.AmountExcludingVAT
	|			ELSE AmountsInDrCurrencies.AmountARAP - AmountsInDrCurrencies.AmountVATARAP
	|		END * CASE
	|			WHEN AmountsInDrCurrencies.AmountExcludingVAT < 0
	|				THEN -1
	|			ELSE 1
	|		END
	|	END AS SumCurrDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN 0
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN 0
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = &ManagementAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = RegisteredRecordsDebitCredit.CurrencyDr
	|			THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr
	|		WHEN AmountsInCrCurrencies.RowID IS NULL
	|			THEN CAST(CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft * RegisteredRecordsDebitCredit.SumManCr / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft * RegisteredRecordsDebitCredit.SumComplCr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END AS NUMBER(&LengthOfSum, &SumAccuracy))
	|		WHEN RegisteredRecordsDebitCredit.VATActivityTypeCr IN (&TypesOfTaxationExcludingVAT)
	|		  OR RegisteredRecordsDebitCredit.VATActivityTypeDr IN (&TypesOfTaxationExcludingVAT)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AccountingObjectDr IN (&VATAccountingObjects)
	|					THEN 0
	|				WHEN RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.Currency
	|					THEN AmountsInCrCurrencies.AmountExcludingVAT + AmountsInCrCurrencies.VATAmount
	|				ELSE AmountsInCrCurrencies.AmountARAP
	|			END * CASE
	|				WHEN AmountsInCrCurrencies.AmountExcludingVAT < 0 OR AmountsInCrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		WHEN RegisteredRecordsDebitCredit.AccountingObjectDr IN (&VATAccountingObjects)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.Currency
	|					THEN AmountsInCrCurrencies.VATAmount
	|				ELSE AmountsInCrCurrencies.AmountVATARAP
	|			END * CASE
	|				WHEN AmountsInCrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		WHEN RegisteredRecordsDebitCredit.AccountingObjectDr IN (&AccountingObjectsWithVAT)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.Currency
	|					THEN AmountsInCrCurrencies.AmountExcludingVAT + AmountsInCrCurrencies.VATAmount
	|				ELSE AmountsInCrCurrencies.AmountARAP
	|			END * CASE
	|				WHEN AmountsInCrCurrencies.AmountExcludingVAT < 0 OR AmountsInCrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.Currency
	|				THEN AmountsInCrCurrencies.AmountExcludingVAT
	|			ELSE AmountsInCrCurrencies.AmountARAP - AmountsInCrCurrencies.AmountVATARAP
	|		END * CASE
	|			WHEN AmountsInCrCurrencies.AmountExcludingVAT < 0
	|				THEN -1
	|			ELSE 1
	|		END
	|	END AS SumCurrCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.AmountOfDrMovement = 0
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsQuantityDistributionDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.CrMotionCount = 0
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsQuantityDistributionCr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.AmountOfDrMovement = 0
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement
	|		WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement * RegisteredRecordsDebitCredit.SumManDr / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|		WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement * RegisteredRecordsDebitCredit.SumComplDr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|		ELSE 0
	|	END AS NUMBER(&LengthOfQuantity, &QuantityAccuracy)) AS CountDr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.CrMotionCount = 0
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount
	|		WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount * RegisteredRecordsDebitCredit.SumManCr / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|		WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount * RegisteredRecordsDebitCredit.SumComplCr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|		ELSE 0
	|	END AS NUMBER(&LengthOfQuantity, &QuantityAccuracy)) AS CountCr
	|INTO TTDistributionOfUnbalancedAssets
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsInDrCurrencies
	|		ON RegisteredRecordsDebitCredit.Recorder = AmountsInDrCurrencies.Recorder
	|		 AND RegisteredRecordsDebitCredit.RowIDCr = AmountsInDrCurrencies.RowID
	|		 AND RegisteredRecordsDebitCredit.ComplexEntryDr
	|		 AND (RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.Currency
	|			OR (RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.ARAPCurrency AND AmountsInDrCurrencies.AmountVATARAP <> 0))
	|		 AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|			WHERE
	|				ReverseReplacementDocuments.Period = RegisteredRecordsDebitCredit.Period
	|				AND ReverseReplacementDocuments.Recorder = RegisteredRecordsDebitCredit.Recorder
	|				AND ReverseReplacementDocuments.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|				AND ReverseReplacementDocuments.Organization = RegisteredRecordsDebitCredit.Organization
	|				AND ReverseReplacementDocuments.PropsStorno = RegisteredRecordsDebitCredit.PropsStorno
	|			)
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsInCrCurrencies
	|		ON RegisteredRecordsDebitCredit.Recorder = AmountsInCrCurrencies.Recorder
	|		 AND RegisteredRecordsDebitCredit.RowIDDr = AmountsInCrCurrencies.RowID
	|		 AND RegisteredRecordsDebitCredit.ComplexEntryCr
	|		 AND (RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.Currency
	|			OR (RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.ARAPCurrency AND AmountsInCrCurrencies.AmountVATARAP <> 0))
	|		 AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|			WHERE
	|				ReverseReplacementDocuments.Period = RegisteredRecordsDebitCredit.Period
	|				AND ReverseReplacementDocuments.Recorder = RegisteredRecordsDebitCredit.Recorder
	|				AND ReverseReplacementDocuments.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|				AND ReverseReplacementDocuments.Organization = RegisteredRecordsDebitCredit.Organization
	|				AND ReverseReplacementDocuments.PropsStorno = RegisteredRecordsDebitCredit.PropsStorno
	|			)
	|INDEX BY
	|	LineNumber,
	|	RecNoDr,
	|	RecNoCr,
	|	ComplexRecordNumber
	|";
	
	QueryText = StrReplace(QueryText, "&LengthOfSum", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.LengthOfSum));
	QueryText = StrReplace(QueryText, "&SumAccuracy", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.SumAccuracy));
	QueryText = StrReplace(QueryText, "&LengthOfQuantity", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.LengthOfQuantity));
	QueryText = StrReplace(QueryText, "&QuantityAccuracy", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.QuantityAccuracy));
	
	QueriesTexts.Add(QueryText);

	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementDebitCredit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAmountsOfDocumentsInAccountingCurrencies");
	
	FinancialAccountingByBalanceSheetRegisterData.AddTableOfSumRoundingErrors(QueriesTexts, "TTErrorCorrectionSumsShaftDr", "DistributableAmountShaftDr", "SumCurrDr");
	FinancialAccountingByBalanceSheetRegisterData.AddTableOfSumRoundingErrors(QueriesTexts, "TTErrorCorrectionSumsShaftCr", "DistributableAmountOfCrShaft", "SumCurrCr");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRoundingErrorTable(QueriesTexts, "TTErrorCorrectionOfDrQuantities", "DistributableAmountOfDr", "CountDr");
	FinancialAccountingByBalanceSheetRegisterData.AddRoundingErrorTable(QueriesTexts, "TTErrorCorrectionOfCrQuantities", "DistributableNumberOfCr", "CountCr");
	
	QueriesTexts.Add("
	|SELECT
	|	DistributionOfUnbalancedAssets.Period AS Period,
	|	DistributionOfUnbalancedAssets.LineNumber AS RecNo,
	|	DistributionOfUnbalancedAssets.RecNoDr AS RecNoDr,
	|	DistributionOfUnbalancedAssets.RecNoCr AS RecNoCr,
	|	DistributionOfUnbalancedAssets.RegisterNameDr AS RegisterNameDr,
	|	DistributionOfUnbalancedAssets.RegisterNameCr AS RegisterNameCr,
	|	DistributionOfUnbalancedAssets.AccountingObjectDr AS AccountingObjectDr,
	|	DistributionOfUnbalancedAssets.AccountingObjectCr AS AccountingObjectCr,
	|	DistributionOfUnbalancedAssets.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	DistributionOfUnbalancedAssets.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	DistributionOfUnbalancedAssets.Organization AS Organization,
	|	DistributionOfUnbalancedAssets.Recorder AS Recorder,
	|	DistributionOfUnbalancedAssets.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DistributionOfUnbalancedAssets.FinRecordID AS FinRecordID,
	|	DistributionOfUnbalancedAssets.RowIDDr AS RowIDDr,
	|	DistributionOfUnbalancedAssets.RowIDCr AS RowIDCr,
	|	DistributionOfUnbalancedAssets.CurrencyDr AS CurrencyDr,
	|	DistributionOfUnbalancedAssets.CurrencyCr AS CurrencyCr,
	|	DistributionOfUnbalancedAssets.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	DistributionOfUnbalancedAssets.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	DistributionOfUnbalancedAssets.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	DistributionOfUnbalancedAssets.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	DistributionOfUnbalancedAssets.PropsStorno AS PropsStorno,
	|	DistributionOfUnbalancedAssets.ComplexEntryDr AS ComplexEntryDr,
	|	DistributionOfUnbalancedAssets.ComplexEntryCr AS ComplexEntryCr,
	|	DistributionOfUnbalancedAssets.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	DistributionOfUnbalancedAssets.SumManDr AS SumManDr,
	|	DistributionOfUnbalancedAssets.SumManCr AS SumManCr,
	|	DistributionOfUnbalancedAssets.SumComplDr AS SumComplDr,
	|	DistributionOfUnbalancedAssets.SumComplCr AS SumComplCr,
	|	DistributionOfUnbalancedAssets.SumCurrDr + ISNULL(CorrectionOfErrorsInDrShaft.RoundingError, 0) AS SumCurrDr,
	|	DistributionOfUnbalancedAssets.SumCurrCr + ISNULL(CorrectionOfErrorsInCRShaft.RoundingError, 0) AS SumCurrCr,
	|	DistributionOfUnbalancedAssets.CountDr + ISNULL(CorrectionOfDrQuantityErrors.RoundingError, 0) AS CountDr,
	|	DistributionOfUnbalancedAssets.CountCr + ISNULL(CorrectionOfCrQuantityErrors.RoundingError, 0) AS CountCr
	|INTO TTMovementDebitCredit
	|FROM
	|	TTDistributionOfUnbalancedAssets AS DistributionOfUnbalancedAssets
	|	LEFT JOIN TTErrorCorrectionSumsShaftDr AS CorrectionOfErrorsInDrShaft
	|		ON DistributionOfUnbalancedAssets.RecNoDr = CorrectionOfErrorsInDrShaft.RecNoDr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfErrorsInDrShaft.LineNumber
	|	LEFT JOIN TTErrorCorrectionSumsShaftCr AS CorrectionOfErrorsInCRShaft
	|		ON DistributionOfUnbalancedAssets.RecNoCr = CorrectionOfErrorsInCRShaft.RecNoCr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfErrorsInCRShaft.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfDrQuantities AS CorrectionOfDrQuantityErrors
	|		ON DistributionOfUnbalancedAssets.RecNoDr = CorrectionOfDrQuantityErrors.RecNoDr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfDrQuantityErrors.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfCrQuantities AS CorrectionOfCrQuantityErrors
	|		ON DistributionOfUnbalancedAssets.RecNoCr = CorrectionOfCrQuantityErrors.RecNoCr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfCrQuantityErrors.LineNumber
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	RegisterNameDr,
	|	RegisterNameCr,
	|	AccountingObjectDr,
	|	AccountingObjectCr
	|");
	
	DeletedTemporaryTables = New Array();
	DeletedTemporaryTables.Add("TTDistributionOfUnbalancedAssets");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftDr");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftCr");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfDrQuantities");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfCrQuantities");

	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

Procedure CheckCorrespondenceErrors(Query, QueriesTexts, DocumentsForProcessing_, RulesTable)
	
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno
	|INTO TTCorrespondenceErrors
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|WHERE
	|	RegisteredRecordsDebitCredit.RegisterNameDr = """"
	|	OR RegisteredRecordsDebitCredit.RegisterNameCr = """"
	|	OR RegisteredRecordsDebitCredit.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	OR RegisteredRecordsDebitCredit.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	OR RegisteredRecordsDebitCredit.FinRecordID = """"
	|	OR RegisteredRecordsDebitCredit.SumManDr <> RegisteredRecordsDebitCredit.SumManCr
	|	OR RegisteredRecordsDebitCredit.SumComplDr <> RegisteredRecordsDebitCredit.SumComplCr
	|
	|UNION ALL
	|
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	&NameOfRegisterOfServiceAccountingObjects AS RegisterNameDr,
	|	&NameOfRegisterOfServiceAccountingObjects AS RegisterNameCr,
	|	MAX(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.AccountingObjectDr
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END) AS AccountingObjectDr,
	|	MAX(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.AccountingObjectCr
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END) AS AccountingObjectCr,
	|	FALSE AS ThisIsReverseTransactionDr,
	|	FALSE AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS SettingUpBusinessTransaction,
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		ELSE 0
	|	END) AS SumManDr,
	|	SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		ELSE 0
	|	END) AS SumManCr,
	|	SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		ELSE 0
	|	END) AS SumComplDr,
	|	SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		ELSE 0
	|	END) AS SumComplCr,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|WHERE
	|	(RegisteredRecordsDebitCredit.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|	AND NOT RegisteredRecordsDebitCredit.AccountingObjectDr IN
	|		(VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry),
	|		 VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)))
	|	OR
	|	(RegisteredRecordsDebitCredit.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|	AND NOT RegisteredRecordsDebitCredit.AccountingObjectCr IN
	|		(VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry),
	|		 VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)))
	|GROUP BY
	|	RegisteredRecordsDebitCredit.Period,
	|	RegisteredRecordsDebitCredit.Recorder,
	|	RegisteredRecordsDebitCredit.Organization,
	|	RegisteredRecordsDebitCredit.PropsStorno
	|HAVING
	|	SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		ELSE 0
	|	END) <> SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		ELSE 0
	|	END)
	|	OR
	|	SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		ELSE 0
	|	END) <> SUM(CASE
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		ELSE 0
	|	END)
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	PropsStorno
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.RegisterNameDr AS RegisterNameDr,
	|	CorrespondencesErrors.RegisterNameCr AS RegisterNameCr,
	|	CorrespondencesErrors.AccountingObjectDr AS AccountingObjectDr,
	|	CorrespondencesErrors.AccountingObjectCr AS AccountingObjectCr,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder,
	|	CorrespondencesErrors.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondencesErrors.FinRecordID AS FinRecordID,
	|	CorrespondencesErrors.SumManDr AS SumManDr,
	|	CorrespondencesErrors.SumManCr AS SumManCr,
	|	CorrespondencesErrors.SumComplDr AS SumComplDr,
	|	CorrespondencesErrors.SumComplCr AS SumComplCr,
	|	CorrespondencesErrors.PropsStorno AS PropsStorno
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder,
	|	MAX(CacheOfDocumentNamesByRule.Rule) AS RuleForObtainingFact
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|	INNER JOIN TTPortionOfDocuments AS PortionOfDocuments
	|	ON CorrespondencesErrors.Recorder = PortionOfDocuments.Recorder
	|	INNER JOIN InformationRegister.DocumentNameCacheForProcessingByRule AS CacheOfDocumentNamesByRule
	|	ON PortionOfDocuments.DocumentKind = CacheOfDocumentNamesByRule.DocumentKind
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTRulesOfOperationalAccounting AS OperationalAccountingRules
	|		WHERE
	|			OperationalAccountingRules.Ref = CacheOfDocumentNamesByRule.Rule
	|		)
	|GROUP BY
	|	CorrespondencesErrors.Period,
	|	CorrespondencesErrors.Recorder,
	|	CorrespondencesErrors.Organization
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	Selection = Results[Results.UBound() - 1].Select();
	SelectionCorrespondence = Results[Results.UBound()].Select();
	
	While SelectionCorrespondence.Next() Do
		CorrespondenceErrors = New Map();
		
		TheStructureOfTheSearch = New Structure("Period,Organization,Recorder");
		FillPropertyValues(TheStructureOfTheSearch, SelectionCorrespondence);
		
		Selection.Reset();
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			If Not ValueIsFilled(Selection.FinRecordID) Then
				
				ErrorText = NStr("vi = 'Chưa điền tên định danh bản ghi tài chính vào %1';
								|ru = 'Не заполнен идентификатор фин.записи в %1';
								|en = 'Financial record ID is required in %1'; fa = 'Financial record ID is required in %1';
								|it = 'Identificativo di registrazione finanziaria in %1 non compilato';
								|pl = 'Nie wypełniono identyfikatora wpisu finansowego w %1';
								|tr = '%1''de mali kayıt kimliği doldurulmadı'");
				If Not ValueIsFilled(Selection.RegisterNameDr)
					Or Selection.RegisterNameDr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1""';
																		|ru = 'регистре ""%1""';
																		|en = 'the ""%1"" register'; fa = 'the ""%1"" register';
																		|it = 'registro ""%1""';
																		|pl = 'rejestrze ""%1""';
																		|tr = '""%1"" kaydında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr])));
				ElsIf Not ValueIsFilled(Selection.RegisterNameCr)
					Or Selection.RegisterNameCr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1""';
																		|ru = 'регистре ""%1""';
																		|en = 'the ""%1"" register'; fa = 'the ""%1"" register';
																		|it = 'registro ""%1""';
																		|pl = 'rejestrze ""%1""';
																		|tr = '""%1"" kaydında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr])));
				ElsIf Selection.RegisterNameDr = Selection.RegisterNameCr Then
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1""';
																		|ru = 'регистре ""%1""';
																		|en = 'the ""%1"" register'; fa = 'the ""%1"" register';
																		|it = 'registro ""%1""';
																		|pl = 'rejestrze ""%1""';
																		|tr = '""%1"" kaydında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr])));
				Else
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1"" và ""%2""';
																		|ru = 'регистрах ""%1"" и ""%2""';
																		|en = 'the ""%1"" and ""%2"" registers'; fa = 'the ""%1"" and ""%2"" registers';
																		|it = 'registri ""%1"" e ""%2""';
																		|pl = 'rejestrach ""%1"" i ""%2""';
																		|tr = '""%1"" ve ""%2"" kayıtlarında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr])));
				EndIf;
				CorrespondenceErrors.Insert(ErrorText);
				
			ElsIf Not ValueIsFilled(Selection.RegisterNameDr) Then
				
				ErrorText = StrTemplate(NStr("vi = 'Không tìm thấy đối ứng cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
											|ru = 'Не найдена корреспонденция для записи регистра ""%1"" с идентификатором %2';
											|en = 'Correspondence for the ""%1"" register record with the %2 ID is not found'; fa = 'Correspondence for the ""%1"" register record with the %2 ID is not found';
											|it = 'Corrispondenza per la registrazione del registro ""%1"" con identificativo %2 non trovata';
											|pl = 'Nie znaleziono korespondencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
											|tr = '%2 kimlikli ''""%1"" kayıt girişi için yazışma bulunamadı'"),
					Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr]),
					Selection.FinRecordID);
				CorrespondenceErrors.Insert(ErrorText);
				
			ElsIf Not ValueIsFilled(Selection.RegisterNameCr) Then
				
				ErrorText = StrTemplate(NStr("vi = 'Không tìm thấy đối ứng cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
											|ru = 'Не найдена корреспонденция для записи регистра ""%1"" с идентификатором %2';
											|en = 'Correspondence for the ""%1"" register record with the %2 ID is not found'; fa = 'Correspondence for the ""%1"" register record with the %2 ID is not found';
											|it = 'Corrispondenza per la registrazione del registro ""%1"" con identificativo %2 non trovata';
											|pl = 'Nie znaleziono korespondencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
											|tr = '%2 kimlikli ''""%1"" kayıt girişi için yazışma bulunamadı'"),
					Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
					Selection.FinRecordID);
				CorrespondenceErrors.Insert(ErrorText);
				
			Else
				
				If Not ValueIsFilled(Selection.AccountingObjectDr)
					And Selection.RegisterNameDr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					ErrorText = StrTemplate(NStr("vi = 'Chưa xác định đối tượng kế toán cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
												|ru = 'Не определен объект учета для записи регистра ""%1"" с идентификатором %2';
												|en = 'Accounting object is not defined for the ""%1"" register record with the %2 ID'; fa = 'Accounting object is not defined for the ""%1"" register record with the %2 ID';
												|it = 'Oggetto di contabilità per la registrazione del registro ""%1"" con identificativo %2 non definito';
												|pl = 'Nie określono obiektu ewidencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
												|tr = '%2 kimlikli ""%1"" kayıt girişi için hesap nesnesi tanımlanmadı'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
						Selection.FinRecordID);
					CorrespondenceErrors.Insert(ErrorText);
				EndIf;
				
				If Not ValueIsFilled(Selection.AccountingObjectCr)
					And Selection.RegisterNameCr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					ErrorText = StrTemplate(NStr("vi = 'Chưa xác định đối tượng kế toán cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
												|ru = 'Не определен объект учета для записи регистра ""%1"" с идентификатором %2';
												|en = 'Accounting object is not defined for the ""%1"" register record with the %2 ID'; fa = 'Accounting object is not defined for the ""%1"" register record with the %2 ID';
												|it = 'Oggetto di contabilità per la registrazione del registro ""%1"" con identificativo %2 non definito';
												|pl = 'Nie określono obiektu ewidencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
												|tr = '%2 kimlikli ""%1"" kayıt girişi için hesap nesnesi tanımlanmadı'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr]),
						Selection.FinRecordID);
					CorrespondenceErrors.Insert(ErrorText);
				EndIf;
				
				If Selection.SumManDr <> Selection.SumManCr Then
					If Selection.RegisterNameDr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
						ErrorText = StrTemplate(NStr("vi = 'Số tiền kế toán quản trị bên nợ và bên có theo đối tượng kế toán ""%1"" không trùng nhau';
													|ru = 'Не совпадают суммы управленческого учета дебета и кредита по объекту учета ""%1""';
													|en = 'The amounts of management accounting of debit and credit for the ""%1"" accounting object do not match'; fa = 'The amounts of management accounting of debit and credit for the ""%1"" accounting object do not match';
													|it = 'Non corrispondono gli importi a debito e a credito per l''oggetto ""%1"" in contabilità gestionale';
													|pl = 'Różnią się wartości ewidencji zarządczej wn i ma według obiektu ewidencji ""%1""';
													|tr = '""%1"" muhasebe nesnesi için borç ve alacak yönetimi muhasebe tutarları eşleşmiyor'"),
							?(ValueIsFilled(Selection.AccountingObjectDr), Selection.AccountingObjectDr, Selection.AccountingObjectCr));
					Else
						ErrorText = StrTemplate(NStr("vi = 'Số tiền kế toán quản trị các bản ghi của biểu ghi ""%1"" và ""%2"" có tên định danh %3 không trùng nhau';
													|ru = 'Не совпадают суммы управленческого учета записей регистров ""%1"" и ""%2"" с идентификатором %3';
													|en = 'The amounts of management accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match'; fa = 'The amounts of management accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match';
													|it = 'Gli importi in contabilità gestionale delle registrazioni dei registri ""%1"" e ""%2"" non corrispondono all''identificativo %3';
													|pl = 'Różnią się wartości ewidencji zarządczej wpisów rejestrów ""%1"" i ""%2"" i identyfikatora %3';
													|tr = '""%1''"" ve ""%2"" genel muhasebe girişlerinin yönetim muhasebesi tutarları, %3 kimliğiyle eşleşmiyor'"),
							Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
							Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr]),
							Selection.FinRecordID);
					EndIf;
					CorrespondenceErrors.Insert(ErrorText);
				EndIf;
				
				If Selection.SumComplDr <> Selection.SumComplCr Then
					If Selection.RegisterNameDr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
						ErrorText = StrTemplate(NStr("vi = 'Số tiền kế toán pháp quy bên nợ và bên có theo đối tượng kế toán ""%1"" không trùng nhau';
													|ru = 'Не совпадают суммы регламентированного учета дебета и кредита по объекту учета ""%1""';
													|en = 'The amounts of local accounting of debit and credit for the ""%1"" accounting object do not match'; fa = 'The amounts of local accounting of debit and credit for the ""%1"" accounting object do not match';
													|it = 'Non corrispondono gli importi a debito e a credito per l''oggetto ""%1"" in contabilità regolamentata';
													|pl = 'Różnią się wartości ewidencji reglamentowanej wn i ma według obiektu ewidencji ""%1""';
													|tr = '""%1"" muhasebe nesnesi için borç ve alacak yerel muhasebe tutarları eşleşmiyor'"),
							?(ValueIsFilled(Selection.AccountingObjectDr), Selection.AccountingObjectDr, Selection.AccountingObjectCr));
					Else
						ErrorText = StrTemplate(NStr("vi = 'Số tiền kế toán pháp quy các bản ghi của biểu ghi ""%1"" và ""%2"" với tên định danh %3 không trùng nhau';
													|ru = 'Не совпадают суммы регламентированного учета записей регистров ""%1"" и ""%2"" с идентификатором %3';
													|en = 'The amounts of local accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match'; fa = 'The amounts of local accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match';
													|it = 'Gli importi in contabilità regolamentata delle registrazioni dei registri ""%1"" e ""%2"" non corrispondono all''identificativo %3';
													|pl = 'Różnią się wartości ewidencji reglamentowanej wpisów rejestrów ""%1"" i ""%2"" i identyfikatora %3';
													|tr = '""%1''"" ve ""%2"" genel muhasebe girişlerinin yerel muhasebesi tutarları, %3 kimliğiyle eşleşmiyor'"),
							Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
							Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr]),
							Selection.FinRecordID);
					EndIf;
					CorrespondenceErrors.Insert(ErrorText);
				EndIf;
			EndIf;
		EndDo;
		
		If CorrespondenceErrors.Count() > 0 Then
			ErrorText = "";
			For Each KeyAndValue In CorrespondenceErrors Do
				ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + KeyAndValue.Key;
			EndDo;
			
			TheStructureOfTheSearch = New Structure("Rule", SelectionCorrespondence.RuleForObtainingFact);
			RuleDescription_ = RulesTable.FindRows(TheStructureOfTheSearch)[0];
			
			RegisterDocumentProcessingError(ErrorText, SelectionCorrespondence, DocumentsForProcessing_, RuleDescription_);
		EndIf;
	EndDo;
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder,
	|	CorrespondencesErrors.PropsStorno AS PropsStorno
	|INTO TTLoggersWithErrors
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|GROUP BY
	|	CorrespondencesErrors.Period,
	|	CorrespondencesErrors.Recorder,
	|	CorrespondencesErrors.Organization,
	|	CorrespondencesErrors.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	PropsStorno
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr OR RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS InvertCorrespondence,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsDebitCredit.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsDebitCredit.CountDr AS CountDr,
	|	RegisteredRecordsDebitCredit.CountCr AS CountCr
	|INTO TTCorrespondenceRegisteredRecords
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTLoggersWithErrors AS LoggersWithErrors
	|		WHERE
	|			LoggersWithErrors.Period = RegisteredRecordsDebitCredit.Period
	|			AND LoggersWithErrors.Recorder = RegisteredRecordsDebitCredit.Recorder
	|			AND LoggersWithErrors.Organization = RegisteredRecordsDebitCredit.Organization
	|			AND LoggersWithErrors.PropsStorno = RegisteredRecordsDebitCredit.PropsStorno
	|		)
	|INDEX BY
	|	Period,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	InvertCorrespondence
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementDebitCredit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTLoggersWithErrors");
	
EndProcedure

Procedure CreateRegisterRecordTableOfServiceAccountingObjects(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	TRUE AS ThisIsDebit,
	|	FALSE AS ThisIsLoan,
	|	CorrespondenceOfRegisteredRecords.Period AS Period,
	|	CorrespondenceOfRegisteredRecords.RegisterNameDr AS RegisterName,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectDr AS AccountingObject,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransaction,
	|	CorrespondenceOfRegisteredRecords.Recorder AS Recorder,
	|	CorrespondenceOfRegisteredRecords.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID AS FinRecordID,
	|	CorrespondenceOfRegisteredRecords.RowIDDr AS RowID,
	|	CorrespondenceOfRegisteredRecords.CurrencyDr AS Currency,
	|	CorrespondenceOfRegisteredRecords.PropsStorno AS PropsStorno,
	|	SUM(CorrespondenceOfRegisteredRecords.SumManDr) AS SumMan,
	|	SUM(CorrespondenceOfRegisteredRecords.SumComplDr) AS SumCompl,
	|	SUM(CorrespondenceOfRegisteredRecords.SumCurrDr) AS SumCurr,
	|	SUM(CorrespondenceOfRegisteredRecords.CountDr) AS Count
	|INTO PlacementTable
	|FROM
	|	TTCorrespondenceRegisteredRecords AS CorrespondenceOfRegisteredRecords
	|WHERE
	|	CorrespondenceOfRegisteredRecords.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|GROUP BY
	|	CorrespondenceOfRegisteredRecords.Period,
	|	CorrespondenceOfRegisteredRecords.RegisterNameDr,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectDr,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionDr,
	|	CorrespondenceOfRegisteredRecords.Recorder,
	|	CorrespondenceOfRegisteredRecords.Organization,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID,
	|	CorrespondenceOfRegisteredRecords.RowIDDr,
	|	CorrespondenceOfRegisteredRecords.CurrencyDr,
	|	CorrespondenceOfRegisteredRecords.PropsStorno
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS ThisIsDebit,
	|	TRUE AS ThisIsLoan,
	|	CorrespondenceOfRegisteredRecords.Period AS Period,
	|	CorrespondenceOfRegisteredRecords.RegisterNameCr AS RegisterName,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectCr AS AccountingObject,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransaction,
	|	CorrespondenceOfRegisteredRecords.Recorder AS Recorder,
	|	CorrespondenceOfRegisteredRecords.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID AS FinRecordID,
	|	CorrespondenceOfRegisteredRecords.RowIDCr AS RowID,
	|	CorrespondenceOfRegisteredRecords.CurrencyCr AS Currency,
	|	CorrespondenceOfRegisteredRecords.PropsStorno AS PropsStorno,
	|	SUM(CorrespondenceOfRegisteredRecords.SumManCr) AS SumMan,
	|	SUM(CorrespondenceOfRegisteredRecords.SumComplCr) AS SumCompl,
	|	SUM(CorrespondenceOfRegisteredRecords.SumCurrCr) AS SumCurr,
	|	SUM(CorrespondenceOfRegisteredRecords.CountCr) AS Count
	|FROM
	|	TTCorrespondenceRegisteredRecords AS CorrespondenceOfRegisteredRecords
	|WHERE
	|	CorrespondenceOfRegisteredRecords.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|GROUP BY
	|	CorrespondenceOfRegisteredRecords.Period,
	|	CorrespondenceOfRegisteredRecords.RegisterNameCr,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectCr,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionCr,
	|	CorrespondenceOfRegisteredRecords.Recorder,
	|	CorrespondenceOfRegisteredRecords.Organization,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID,
	|	CorrespondenceOfRegisteredRecords.RowIDCr,
	|	CorrespondenceOfRegisteredRecords.CurrencyCr,
	|	CorrespondenceOfRegisteredRecords.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RowID,
	|	AccountingObject,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno
	|";
	
	QueryText = StrReplace(QueryText, "PlacementTable", "tt" + FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects());
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure CreateTableOfComplexCorrespondence(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondenceOfRegisteredRecords.RecNo AS RecNo,
	|	CorrespondenceOfRegisteredRecords.Period AS Period,
	|	CorrespondenceOfRegisteredRecords.Organization AS Organization,
	|	CorrespondenceOfRegisteredRecords.Recorder AS Recorder,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID AS FinRecordID,
	|	CorrespondenceOfRegisteredRecords.PropsStorno AS PropsStorno,
	|	CorrespondenceOfRegisteredRecords.AmountOfManMovementDr AS AmountOfManMovement,
	|	CorrespondenceOfRegisteredRecords.AmountOfLocalTrafficDr AS AmountOfLocalTraffic,
	|	CorrespondenceOfRegisteredRecords.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.SumManDr AS SumMan,
	|	CorrespondenceOfRegisteredRecords.SumComplDr AS SumCompl
	|INTO TTComplexCorrespondence
	|FROM
	|	TTCorrespondenceRegisteredRecords AS CorrespondenceOfRegisteredRecords
	|WHERE
	|	CorrespondenceOfRegisteredRecords.ComplexEntryDr
	|
	|UNION ALL
	|
	|SELECT
	|	CorrespondenceOfRegisteredRecords.RecNo AS RecNo,
	|	CorrespondenceOfRegisteredRecords.Period AS Period,
	|	CorrespondenceOfRegisteredRecords.Organization AS Organization,
	|	CorrespondenceOfRegisteredRecords.Recorder AS Recorder,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID AS FinRecordID,
	|	CorrespondenceOfRegisteredRecords.PropsStorno AS PropsStorno,
	|	CorrespondenceOfRegisteredRecords.AmountOfManMovementCr AS AmountOfManMovement,
	|	CorrespondenceOfRegisteredRecords.AmountOfLocalTrafficCr AS AmountOfLocalTraffic,
	|	CorrespondenceOfRegisteredRecords.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.SumManCr AS SumMan,
	|	CorrespondenceOfRegisteredRecords.SumComplCr AS SumCompl
	|FROM
	|	TTCorrespondenceRegisteredRecords AS CorrespondenceOfRegisteredRecords
	|WHERE
	|	CorrespondenceOfRegisteredRecords.ComplexEntryCr
	|");
	
EndProcedure

Procedure CreateRulesForReceivingFactOfCorrespondence(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	ActualDataQueryRules_.Ref AS Ref,
	|	ActualDataQueryRules_.ValidFrom AS ValidFrom,
	|	ActualDataQueryRules_.ValidTo AS ValidTo,
	|	CAST(ActualDataQueryRules_.DataSource AS ChartOfCharacteristicTypes.AssetLiabilityItems) AS DataSource,
	|	CAST(ActualDataQueryRules_.CorDataSource AS ChartOfCharacteristicTypes.AssetLiabilityItems) AS CorDataSource,
	|	CAST(ActualDataQueryRules_.FilterPresentation AS STRING(16)) <> """" AS RuleContainsSelection,
	|	ActualDataQueryRules_.TotalType AS TotalType
	|INTO TTRulesForObtainingFact
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRules_
	|	INNER JOIN TTRulesOfOperationalAccounting AS OperationalAccountingRules
	|		ON ActualDataQueryRules_.Ref = OperationalAccountingRules.Ref
	|WHERE
	|	VALUETYPE(ActualDataQueryRules_.DataSource) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|INDEX BY
	|	TotalType
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRulesOfOperationalAccounting");
	
	QueriesTexts.Add("
	|SELECT
	|	ActualDataQueryRules_.Ref AS Ref,
	|	ActualDataQueryRules_.ValidFrom AS ValidFrom,
	|	CASE
	|		WHEN ActualDataQueryRules_.ValidTo = DATETIME(0001, 01, 01)
	|			THEN DATETIME(3999, 12, 31, 23, 59, 59)
	|		ELSE ActualDataQueryRules_.ValidTo
	|	END AS ValidTo,
	|	CASE
	|		WHEN ActualDataQueryRules_.TotalType = VALUE(Enum.TypesOfTotals.TurnoverCr)
	|			THEN ActualDataQueryRules_.CorDataSource
	|		ELSE ActualDataQueryRules_.DataSource
	|	END AS DataSourceDr,
	|	CASE
	|		WHEN ActualDataQueryRules_.TotalType = VALUE(Enum.TypesOfTotals.TurnoverCr)
	|			THEN ActualDataQueryRules_.DataSource
	|		ELSE ActualDataQueryRules_.CorDataSource
	|	END AS DataSourceCr,
	|	ActualDataQueryRules_.RuleContainsSelection AS RuleContainsSelection,
	|	CASE
	|		WHEN ActualDataQueryRules_.TotalType = VALUE(Enum.TypesOfTotals.TurnoverCr)
	|			THEN ActualDataQueryRules_.CorDataSource
	|		ELSE ActualDataQueryRules_.DataSource
	|	END = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS EmptyDataSourceDr,
	|	CASE
	|		WHEN ActualDataQueryRules_.TotalType = VALUE(Enum.TypesOfTotals.TurnoverCr)
	|			THEN ActualDataQueryRules_.DataSource
	|		ELSE ActualDataQueryRules_.CorDataSource
	|	END = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS EmptyDataSourceCr,
	|	ActualDataQueryRules_.TotalType = VALUE(Enum.TypesOfTotals.TurnoverCr) AS InversionOfDataSources,
	|	FALSE AS InversionOfActualData
	|INTO TTRulesForReceivingFactOfCorrespondence
	|FROM
	|	TTRulesForObtainingFact AS ActualDataQueryRules_
	|
	|UNION ALL
	|
	|SELECT
	|	ActualDataQueryRules_.Ref AS Ref,
	|	ActualDataQueryRules_.ValidFrom AS ValidFrom,
	|	CASE
	|		WHEN ActualDataQueryRules_.ValidTo = DATETIME(0001, 01, 01)
	|			THEN DATETIME(3999, 12, 31, 23, 59, 59)
	|		ELSE ActualDataQueryRules_.ValidTo
	|	END AS ValidTo,
	|	ActualDataQueryRules_.CorDataSource AS DataSourceDr,
	|	ActualDataQueryRules_.DataSource AS DataSourceCr,
	|	ActualDataQueryRules_.RuleContainsSelection AS RuleContainsSelection,
	|	ActualDataQueryRules_.CorDataSource = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS EmptyDataSourceDr,
	|	ActualDataQueryRules_.DataSource = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS EmptyDataSourceCr,
	|	TRUE AS InversionOfDataSources,
	|	TRUE AS InversionOfActualData
	|FROM
	|	TTRulesForObtainingFact AS ActualDataQueryRules_
	|WHERE
	|	ActualDataQueryRules_.TotalType = VALUE(Enum.TypesOfTotals.Turnover)
	|INDEX BY
	|	ValidFrom,
	|	ValidTo,
	|	DataSourceDr,
	|	DataSourceCr,
	|	EmptyDataSourceDr,
	|	EmptyDataSourceCr
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRulesForObtainingFact");
	
EndProcedure

Procedure ApplyRulesOfFactReceiptToCorrespondence(Query, QueriesTexts, RegisterRequestsTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	ActualDataQueryRules_.Ref AS RuleForObtainingFact,
	|	ActualDataQueryRules_.RuleContainsSelection AS RuleContainsSelection,
	|	ActualDataQueryRules_.EmptyDataSourceDr AS EmptyDataSourceDr,
	|	ActualDataQueryRules_.EmptyDataSourceCr AS EmptyDataSourceCr,
	|	ActualDataQueryRules_.InversionOfDataSources AS InversionOfDataSources,
	|	ActualDataQueryRules_.InversionOfActualData AS InversionOfActualData,
	|	CorrespondenceOfRegisteredRecords.RecNo AS RecNo,
	|	CorrespondenceOfRegisteredRecords.Period AS Period,
	|	CorrespondenceOfRegisteredRecords.RegisterNameDr AS RegisterNameDr,
	|	CorrespondenceOfRegisteredRecords.RegisterNameCr AS RegisterNameCr,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectDr AS AccountingObjectDr,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectCr AS AccountingObjectCr,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	CorrespondenceOfRegisteredRecords.InvertCorrespondence AS InvertCorrespondence,
	|	CorrespondenceOfRegisteredRecords.Organization AS Organization,
	|	CorrespondenceOfRegisteredRecords.Recorder AS Recorder,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID AS FinRecordID,
	|	CorrespondenceOfRegisteredRecords.RowIDDr AS RowIDDr,
	|	CorrespondenceOfRegisteredRecords.RowIDCr AS RowIDCr,
	|	CorrespondenceOfRegisteredRecords.PropsStorno AS PropsStorno,
	|	CorrespondenceOfRegisteredRecords.CurrencyDr AS CurrencyDr,
	|	CorrespondenceOfRegisteredRecords.CurrencyCr AS CurrencyCr,
	|	CorrespondenceOfRegisteredRecords.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	CorrespondenceOfRegisteredRecords.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	CorrespondenceOfRegisteredRecords.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	CorrespondenceOfRegisteredRecords.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	CorrespondenceOfRegisteredRecords.ComplexEntryDr AS ComplexEntryDr,
	|	CorrespondenceOfRegisteredRecords.ComplexEntryCr AS ComplexEntryCr,
	|	CorrespondenceOfRegisteredRecords.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.SumManDr AS SumManDr,
	|	CorrespondenceOfRegisteredRecords.SumManCr AS SumManCr,
	|	CorrespondenceOfRegisteredRecords.SumComplDr AS SumComplDr,
	|	CorrespondenceOfRegisteredRecords.SumComplCr AS SumComplCr,
	|	CorrespondenceOfRegisteredRecords.SumCurrDr AS SumCurrDr,
	|	CorrespondenceOfRegisteredRecords.SumCurrCr AS SumCurrCr,
	|	CorrespondenceOfRegisteredRecords.CountDr AS CountDr,
	|	CorrespondenceOfRegisteredRecords.CountCr AS CountCr
	|INTO TTCorrespondenceAccordingToRules
	|FROM
	|	TTCorrespondenceRegisteredRecords AS CorrespondenceOfRegisteredRecords
	|	INNER JOIN TTRulesForReceivingFactOfCorrespondence AS ActualDataQueryRules_
	|		ON CorrespondenceOfRegisteredRecords.Period >= ActualDataQueryRules_.ValidFrom
	|		 AND CorrespondenceOfRegisteredRecords.Period <= ActualDataQueryRules_.ValidTo
	|		 AND (ActualDataQueryRules_.EmptyDataSourceDr
	|			OR CorrespondenceOfRegisteredRecords.AccountingObjectDr = ActualDataQueryRules_.DataSourceDr)
	|		 AND (ActualDataQueryRules_.EmptyDataSourceCr
	|			OR CorrespondenceOfRegisteredRecords.AccountingObjectCr = ActualDataQueryRules_.DataSourceCr)
	|WHERE
	|	NOT CorrespondenceOfRegisteredRecords.InvertCorrespondence
	|	AND NOT(ActualDataQueryRules_.EmptyDataSourceDr AND ActualDataQueryRules_.EmptyDataSourceCr)
	|
	|UNION ALL
	|
	|SELECT
	|	ActualDataQueryRules_.Ref AS RuleForObtainingFact,
	|	ActualDataQueryRules_.RuleContainsSelection AS RuleContainsSelection,
	|	ActualDataQueryRules_.EmptyDataSourceDr AS EmptyDataSourceDr,
	|	ActualDataQueryRules_.EmptyDataSourceCr AS EmptyDataSourceCr,
	|	ActualDataQueryRules_.InversionOfDataSources AS InversionOfDataSources,
	|	ActualDataQueryRules_.InversionOfActualData AS InversionOfActualData,
	|	CorrespondenceOfRegisteredRecords.RecNo AS RecNo,
	|	CorrespondenceOfRegisteredRecords.Period AS Period,
	|	CorrespondenceOfRegisteredRecords.RegisterNameCr AS RegisterNameDr,
	|	CorrespondenceOfRegisteredRecords.RegisterNameDr AS RegisterNameCr,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectCr AS AccountingObjectDr,
	|	CorrespondenceOfRegisteredRecords.AccountingObjectDr AS AccountingObjectCr,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransactionDr,
	|	CorrespondenceOfRegisteredRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransactionCr,
	|	CorrespondenceOfRegisteredRecords.InvertCorrespondence AS InvertCorrespondence,
	|	CorrespondenceOfRegisteredRecords.Organization AS Organization,
	|	CorrespondenceOfRegisteredRecords.Recorder AS Recorder,
	|	CorrespondenceOfRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.FinRecordID AS FinRecordID,
	|	CorrespondenceOfRegisteredRecords.RowIDCr AS RowIDDr,
	|	CorrespondenceOfRegisteredRecords.RowIDDr AS RowIDCr,
	|	CorrespondenceOfRegisteredRecords.PropsStorno AS PropsStorno,
	|	CorrespondenceOfRegisteredRecords.CurrencyCr AS CurrencyDr,
	|	CorrespondenceOfRegisteredRecords.CurrencyDr AS CurrencyCr,
	|	CorrespondenceOfRegisteredRecords.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	CorrespondenceOfRegisteredRecords.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	CorrespondenceOfRegisteredRecords.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	CorrespondenceOfRegisteredRecords.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	CorrespondenceOfRegisteredRecords.ComplexEntryDr AS ComplexEntryDr,
	|	CorrespondenceOfRegisteredRecords.ComplexEntryCr AS ComplexEntryCr,
	|	CorrespondenceOfRegisteredRecords.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CorrespondenceOfRegisteredRecords.SumManDr AS SumManDr,
	|	CorrespondenceOfRegisteredRecords.SumManCr AS SumManCr,
	|	CorrespondenceOfRegisteredRecords.SumComplDr AS SumComplDr,
	|	CorrespondenceOfRegisteredRecords.SumComplCr AS SumComplCr,
	|	CorrespondenceOfRegisteredRecords.SumCurrDr AS SumCurrDr,
	|	CorrespondenceOfRegisteredRecords.SumCurrCr AS SumCurrCr,
	|	CorrespondenceOfRegisteredRecords.CountDr AS CountDr,
	|	CorrespondenceOfRegisteredRecords.CountCr AS CountCr
	|FROM
	|	TTCorrespondenceRegisteredRecords AS CorrespondenceOfRegisteredRecords
	|	INNER JOIN TTRulesForReceivingFactOfCorrespondence AS ActualDataQueryRules_
	|		ON CorrespondenceOfRegisteredRecords.Period >= ActualDataQueryRules_.ValidFrom
	|		 AND CorrespondenceOfRegisteredRecords.Period <= ActualDataQueryRules_.ValidTo
	|		 AND (ActualDataQueryRules_.EmptyDataSourceDr
	|			OR CorrespondenceOfRegisteredRecords.AccountingObjectCr = ActualDataQueryRules_.DataSourceDr)
	|		 AND (ActualDataQueryRules_.EmptyDataSourceCr
	|			OR CorrespondenceOfRegisteredRecords.AccountingObjectDr = ActualDataQueryRules_.DataSourceCr)
	|WHERE
	|	CorrespondenceOfRegisteredRecords.InvertCorrespondence
	|	AND NOT(ActualDataQueryRules_.EmptyDataSourceDr AND ActualDataQueryRules_.EmptyDataSourceCr)
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RowIDDr,
	|	RowIDCr,
	|	RegisterNameDr,
	|	RegisterNameCr,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	InvertCorrespondence,
	|	PropsStorno
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceRegisteredRecords");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRulesForReceivingFactOfCorrespondence");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondenceAccordingToRules.RuleForObtainingFact AS RuleForObtainingFact,
	|	CorrespondenceAccordingToRules.RuleContainsSelection AS RuleContainsSelection,
	|	CorrespondenceAccordingToRules.EmptyDataSourceDr AS EmptyDataSourceDr,
	|	CorrespondenceAccordingToRules.EmptyDataSourceCr AS EmptyDataSourceCr,
	|	CorrespondenceAccordingToRules.InversionOfDataSources AS InversionOfDataSources,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceDr
	|			THEN """"
	|		ELSE CorrespondenceAccordingToRules.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceCr
	|			THEN """"
	|		ELSE CorrespondenceAccordingToRules.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceDr
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		ELSE CorrespondenceAccordingToRules.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceCr
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		ELSE CorrespondenceAccordingToRules.AccountingObjectCr
	|	END AS AccountingObjectCr
	|INTO TTRulesForProcessingCorrespondence
	|FROM
	|	TTCorrespondenceAccordingToRules AS CorrespondenceAccordingToRules
	|GROUP BY
	|	CorrespondenceAccordingToRules.RuleForObtainingFact,
	|	CorrespondenceAccordingToRules.RuleContainsSelection,
	|	CorrespondenceAccordingToRules.EmptyDataSourceDr,
	|	CorrespondenceAccordingToRules.EmptyDataSourceCr,
	|	CorrespondenceAccordingToRules.InversionOfDataSources,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceDr
	|			THEN """"
	|		ELSE CorrespondenceAccordingToRules.RegisterNameDr
	|	END,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceCr
	|			THEN """"
	|		ELSE CorrespondenceAccordingToRules.RegisterNameCr
	|	END,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceDr
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		ELSE CorrespondenceAccordingToRules.AccountingObjectDr
	|	END,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.EmptyDataSourceCr
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		ELSE CorrespondenceAccordingToRules.AccountingObjectCr
	|	END
	|INDEX BY
	|	RuleForObtainingFact,
	|	RuleContainsSelection
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RulesForProcessingCorrespondence.RuleForObtainingFact AS RuleForObtainingFact,
	|	RulesForProcessingCorrespondence.InversionOfDataSources AS InversionOfDataSources,
	|	RulesForProcessingCorrespondence.RegisterNameDr AS RegisterNameDr,
	|	RulesForProcessingCorrespondence.RegisterNameCr AS RegisterNameCr,
	|	RulesForProcessingCorrespondence.AccountingObjectDr AS AccountingObjectDr,
	|	RulesForProcessingCorrespondence.AccountingObjectCr AS AccountingObjectCr,
	|	ActualDataQueryRules_.SettingsComposer
	|FROM
	|	TTRulesForProcessingCorrespondence AS RulesForProcessingCorrespondence
	|	INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRules_
	|		ON RulesForProcessingCorrespondence.RuleForObtainingFact = ActualDataQueryRules_.Ref
	|WHERE
	|	RulesForProcessingCorrespondence.RuleContainsSelection
	|TOTALS BY
	|	RegisterNameDr,
	|	RegisterNameCr
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	ResultOfSelectionRule = Results[Results.UBound()];
	
	CorrespondenceSelections = New ValueTable();
	CorrespondenceSelections.Columns.Add("RegisterNameDr", Common.StringTypeDetails(150));
	CorrespondenceSelections.Columns.Add("RegisterNameCr", Common.StringTypeDetails(150));
	CorrespondenceSelections.Columns.Add("HasFilterDr", New TypeDescription("Boolean"));
	CorrespondenceSelections.Columns.Add("HasFilterCr", New TypeDescription("Boolean"));
	CorrespondenceSelections.Columns.Add("Filter", New TypeDescription("DataCompositionFilter"));
	
	RegisterFilterFields = New Structure();
	AvailableRegisterFields_ = New Structure();
	
	FetchingRegisterNameDr = ResultOfSelectionRule.Select(QueryResultIteration.ByGroups);
	While FetchingRegisterNameDr.Next() Do
		FetchingRegisterNameCr = FetchingRegisterNameDr.Select(QueryResultIteration.ByGroups);
		While FetchingRegisterNameCr.Next() Do
			SelectionSelectionRules = FetchingRegisterNameCr.Select();
			
			FilterOfCorrespondence = CorrespondenceSelections.Add();
			FilterOfCorrespondence.RegisterNameDr = FetchingRegisterNameDr.RegisterNameDr;
			FilterOfCorrespondence.RegisterNameCr = FetchingRegisterNameCr.RegisterNameCr;
			
			If SelectionSelectionRules.Count() > 1 Then
				FilterRules = FilterOfCorrespondence.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterRules.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			Else
				FilterRules = FilterOfCorrespondence.Filter;
			EndIf;
			
			While SelectionSelectionRules.Next() Do
				If TypeOf(FilterRules) = Type("DataCompositionFilterItemGroup") Then
					FilterRule = FilterRules.Items.Add(Type("DataCompositionFilterItemGroup"));
					FilterRule.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				Else
					FilterRule = FilterRules;
				EndIf;
				
				RuleSettingsComposer = New DataCompositionSettingsComposer();
				RuleSettingsComposer.LoadSettings(SelectionSelectionRules.SettingsComposer.Get());
				AddRuleSelectionToDataLayoutSelection(
					RuleSettingsComposer.Settings.Filter,
					SelectionSelectionRules.InversionOfDataSources,
					FilterRule);
				
				If Not IsBlankString(SelectionSelectionRules.RegisterNameDr)
					And FinancialAccountingByBalanceSheetRegisterData.ThereAreElementsOfSelection(FilterRule, "Dr") Then
					If Not RegisterFilterFields.Property(SelectionSelectionRules.RegisterNameDr) Then
						RegisterFilterFields.Insert(SelectionSelectionRules.RegisterNameDr, New Array());
					EndIf;
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionElementFields(
						RegisterFilterFields[SelectionSelectionRules.RegisterNameDr], FilterRule, "Dr");
					FilterOfCorrespondence.HasFilterDr = True;
				EndIf;
				
				If Not IsBlankString(SelectionSelectionRules.RegisterNameCr)
					And FinancialAccountingByBalanceSheetRegisterData.ThereAreElementsOfSelection(FilterRule, "Cr") Then
					If Not RegisterFilterFields.Property(SelectionSelectionRules.RegisterNameCr) Then
						RegisterFilterFields.Insert(SelectionSelectionRules.RegisterNameCr, New Array());
					EndIf;
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionElementFields(
						RegisterFilterFields[SelectionSelectionRules.RegisterNameCr], FilterRule, "Cr");
					FilterOfCorrespondence.HasFilterCr = True;
				EndIf;
				
				RuleKey = KeySelectionRules(SelectionSelectionRules);
				AddRuleKeyToDataLayoutSelection(RuleKey, FilterRule);
			EndDo;
		EndDo;
	EndDo;
	
	SelectionFieldsToDelete = DeletedFieldsForSelectingMotionAnalyticsQueries();
	IndexingFields = IndexFieldsOfCorrespondenceSelectionTables();
	ReverseIndexFields = IndexFieldsOfTablesReplacingReverseWithReverse();
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("Organization");
	ExistingSelectionFields.Add("Department");
	ExistingSelectionFields.Add("LineOfBusiness");
	ExistingSelectionFields.Add("Currency");
	ExistingSelectionFields.Add("Recorder");
	ExistingSelectionFields.Add("BusinessTransactionSetting");
	ExistingSelectionFields.Add("PropsStorno");
	
	For Each KeyAndValue In RegisterFilterFields Do
		RegisterTableName = KeyAndValue.Key;
		FilterFieldsRegister = KeyAndValue.Value;
		
		If RegisterTableName = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			AvailableRegisterFields = Common.CopyRecursive(ExistingSelectionFields);
		Else
			AvailableRegisterFields = FinancialAccountingByBalanceSheetRegisterData.AvailableDataSourceFields(
				DescriptionOfFinancialRegisterFields(RegisterTableName));
			
			SelectionOfAnalyticsFields = New Array();
			SelectingSourceResources = New Array();
			GroupingAnalyticsFields = New Array();
			
			FinancialAccountingByBalanceSheetRegisterData.FillInAnalyticsSampleLines(
				SelectionOfAnalyticsFields, GroupingAnalyticsFields, AvailableRegisterFields, ExistingSelectionFields, FilterFieldsRegister);
			
			RegisterRequestText = RegisterRequestsTexts[RegisterTableName];
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
				SelectingSourceResources, RegisterRequestText);
			
			StornoReplacementWithReverseIsRequired = Query.Parameters.RegistersAreReplacedStornoByReverse.Find(RegisterTableName) <> Undefined;
			ReverseEntryNeedsToBeReplacedStorno = Query.Parameters.ReverseToReverseReplacementRegisters.Find(RegisterTableName) <> Undefined;
			
			PlacementTable = "tt" + RegisterTableName;
			StornoReplacementTable = PlacementTable + "ReplacementStorno";
			ReverseReplacementTable = PlacementTable + "ReverseReplacement";
			
			If StornoReplacementWithReverseIsRequired Then
				FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete,, StornoReplacementTable);
				QueriesTexts.Add(RegisterRequestText);
				RegisterRequestText = TextOfAnalysisSelectionFromNestedTable();
				RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", StornoReplacementTable);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
					SelectingSourceResources, RegisterRequestText);
			EndIf;
			
			If ReverseEntryNeedsToBeReplacedStorno Then
				FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, ReverseIndexFields, ReverseReplacementTable);
				QueriesTexts.Add(RegisterRequestText);
				RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable(True);
				RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", ReverseReplacementTable);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
					SelectingSourceResources, RegisterRequestText);
			EndIf;
			
			FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, IndexingFields, PlacementTable);
			
			If RegistersOfRecoveryOfCalculationsOnStorno.Find(RegisterTableName) <> Undefined Then
				AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterTableName);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
					SelectingSourceResources, RegisterRequestText);
			EndIf;
			
			QueriesTexts.Add(RegisterRequestText);
			
			If StornoReplacementWithReverseIsRequired Then
				FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, StornoReplacementTable);
			EndIf;
			
			If ReverseEntryNeedsToBeReplacedStorno Then
				FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, ReverseReplacementTable);
			EndIf;
		EndIf;
	
		AvailableRegisterFields.Add("TypeOfRegistrar");
		AvailableRegisterFields_.Insert(RegisterTableName, AvailableRegisterFields);
	EndDo;
	
	If QueriesTexts.Count() > 0 Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Results = Query.ExecuteBatch();
		QueriesTexts.Clear();
	
		DataCompositionSelectionFields = DataCompositionSelectionFields(Query.Parameters);
		DataLayoutResultsTable = DataLayoutResultsTable(DataCompositionSelectionFields);
		AddressOfDataLayoutStore = PutToTempStorage(Undefined, New UUID());
	Else
		DataLayoutResultsTable = Undefined;
	EndIf;
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("OrganizationDr");
	ExistingSelectionFields.Add("OrganizationCr");
	ExistingSelectionFields.Add("CurrencyDr");
	ExistingSelectionFields.Add("CurrencyCr");
	
	FetchingRegisterNameDr.Reset();
	
	While FetchingRegisterNameDr.Next() Do
		FetchingRegisterNameCr = FetchingRegisterNameDr.Select(QueryResultIteration.ByGroups);
		While FetchingRegisterNameCr.Next() Do
			SelectionSearchStructure = New Structure("RegisterNameDr,RegisterNameCr",
				FetchingRegisterNameDr.RegisterNameDr, FetchingRegisterNameCr.RegisterNameCr);
			FilterOfCorrespondence = CorrespondenceSelections.FindRows(SelectionSearchStructure)[0];
			
			QueryText = "
			|SELECT
			|	CorrespondenceAccordingToRules.RuleForObtainingFact AS RuleForObtainingFact,
			|	CorrespondenceAccordingToRules.RecNo AS RecNo,
			|	CorrespondenceAccordingToRules.AccountingObjectDr AS AccountingObjectDr,
			|	CorrespondenceAccordingToRules.AccountingObjectCr AS AccountingObjectCr,
			|	CorrespondenceAccordingToRules.Organization AS OrganizationDr,
			|	CorrespondenceAccordingToRules.Organization AS OrganizationCr,
			|	CorrespondenceAccordingToRules.CurrencyDr AS CurrencyDr,
			|	CorrespondenceAccordingToRules.CurrencyCr AS CurrencyCr,
			|	&TableSelectionFieldsDr,
			|	&TableSelectionFieldsCr
			|FROM
			|	TTCorrespondenceAccordingToRules AS CorrespondenceAccordingToRules
			|";
			
			If FilterOfCorrespondence.HasFilterDr Then
				QueryText = QueryText + "
				|	INNER JOIN &TableDr AS TableDr
				|		ON CorrespondenceAccordingToRules.Period = TableDr.Period
				|		 AND CorrespondenceAccordingToRules.Recorder = TableDr.Recorder
				|		 AND CorrespondenceAccordingToRules.FinRecordID = TableDr.FinRecordID
				|		 AND CorrespondenceAccordingToRules.RowIDDr = TableDr.RowID
				|		 AND CorrespondenceAccordingToRules.RegisterNameDr = &RegisterNameDr
				|		 AND CorrespondenceAccordingToRules.AccountingObjectDr = TableDr.AccountingObject
				|		 AND CorrespondenceAccordingToRules.Organization = TableDr.Organization
				|		 AND CASE
				|			WHEN TableDr.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
				|				THEN CorrespondenceAccordingToRules.SettingUpBusinessTransaction = TableDr.SettingUpBusinessTransaction
				|			ELSE TRUE
				|		 END
				|		 AND CASE
				|			WHEN CorrespondenceAccordingToRules.InvertCorrespondence
				|				THEN NOT TableDr.ThisIsDebit
				|			ELSE NOT TableDr.ThisIsLoan
				|		 END
				|		 AND CorrespondenceAccordingToRules.ThisIsReverseTransactionDr = TableDr.ThisIsReverseTransaction
				|		 AND CorrespondenceAccordingToRules.PropsStorno = TableDr.PropsStorno
				|";
			EndIf;
			
			If FilterOfCorrespondence.HasFilterCr Then
				QueryText = QueryText + "
				|	INNER JOIN &TableCr AS TableCr
				|		ON CorrespondenceAccordingToRules.Period = TableCr.Period
				|		 AND CorrespondenceAccordingToRules.Recorder = TableCr.Recorder
				|		 AND CorrespondenceAccordingToRules.FinRecordID = TableCr.FinRecordID
				|		 AND CorrespondenceAccordingToRules.RowIDCr = TableCr.RowID
				|		 AND CorrespondenceAccordingToRules.RegisterNameCr = &RegisterNameCr
				|		 AND CorrespondenceAccordingToRules.AccountingObjectCr = TableCr.AccountingObject
				|		 AND CorrespondenceAccordingToRules.Organization = TableCr.Organization
				|		 AND CASE
				|			WHEN TableCr.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
				|				THEN CorrespondenceAccordingToRules.SettingUpBusinessTransaction = TableCr.SettingUpBusinessTransaction
				|			ELSE TRUE
				|		 END
				|		 AND CASE
				|			WHEN CorrespondenceAccordingToRules.InvertCorrespondence
				|				THEN NOT TableCr.ThisIsLoan
				|			ELSE NOT TableCr.ThisIsDebit
				|		 END
				|		 AND CorrespondenceAccordingToRules.ThisIsReverseTransactionCr = TableCr.ThisIsReverseTransaction
				|		 AND CorrespondenceAccordingToRules.PropsStorno = TableCr.PropsStorno
				|";
			EndIf;
			
			QueryText = QueryText + "
			|WHERE
			|	CorrespondenceAccordingToRules.RuleContainsSelection
			|";
			
			QueryText = StrReplace(QueryText, "&TableDr", StrTemplate("tt%1", FetchingRegisterNameDr.RegisterNameDr));
			QueryText = StrReplace(QueryText, "&TableCr", StrTemplate("tt%1", FetchingRegisterNameCr.RegisterNameCr));
			QueryText = StrReplace(QueryText, "&RegisterNameDr", StrTemplate("""%1""", FetchingRegisterNameDr.RegisterNameDr));
			QueryText = StrReplace(QueryText, "&RegisterNameCr", StrTemplate("""%1""", FetchingRegisterNameCr.RegisterNameCr));
			
			FilterFieldsRegisterDr = Undefined;
			AvailableRegisterFieldsDr = Undefined;
			
			If IsBlankString(FetchingRegisterNameDr.RegisterNameDr)
			 Or Not RegisterFilterFields.Property(FetchingRegisterNameDr.RegisterNameDr, FilterFieldsRegisterDr) Then
				FilterFieldsRegisterDr = New Array();
			EndIf;
			
			If IsBlankString(FetchingRegisterNameDr.RegisterNameDr)
			 Or Not AvailableRegisterFields_.Property(FetchingRegisterNameDr.RegisterNameDr, AvailableRegisterFieldsDr) Then
				AvailableRegisterFieldsDr = New Array();
			EndIf;
			
			QueryText = StrReplace(QueryText, "&TableSelectionFieldsDr",
				FinancialAccountingByBalanceSheetRegisterData.FieldSelectionText(
					AvailableRegisterFieldsDr, ExistingSelectionFields, FilterFieldsRegisterDr, "Dr", "TableDr"));
			
			FilterFieldsRegisterCr = Undefined;
			AvailableRegisterFieldsCr = Undefined;
			
			If IsBlankString(FetchingRegisterNameCr.RegisterNameCr)
			 Or Not RegisterFilterFields.Property(FetchingRegisterNameCr.RegisterNameCr, FilterFieldsRegisterCr) Then
				FilterFieldsRegisterCr = New Array();
			EndIf;
			
			If IsBlankString(FetchingRegisterNameCr.RegisterNameCr)
			 Or Not AvailableRegisterFields_.Property(FetchingRegisterNameCr.RegisterNameCr, AvailableRegisterFieldsCr) Then
				AvailableRegisterFieldsCr = New Array();
			EndIf;
			
			QueryText = StrReplace(QueryText, "&TableSelectionFieldsCr",
				FinancialAccountingByBalanceSheetRegisterData.FieldSelectionText(
					AvailableRegisterFieldsCr, ExistingSelectionFields, FilterFieldsRegisterCr, "Cr", "TableCr"));
			
			DataCompositionSchema = FinancialAccountingByBalanceSheetRegisterData.NewDataLayoutScheme(QueryText);
			AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, AddressOfDataLayoutStore);
			SettingsComposer = FinancialAccountingByBalanceSheetRegisterData.NewDataLayoutSettingsComposer(
				AddressOfDataCompositionSchema, DataCompositionSelectionFields, Query.Parameters);
			DataCompositionClientServer.CopyElements(SettingsComposer.Settings.Filter, FilterOfCorrespondence.Filter);
			
			FinancialAccountingByBalanceSheetRegisterData.AddLayoutResultToTable(DataCompositionSchema, SettingsComposer,
				Query.TempTablesManager, DataLayoutResultsTable);
		EndDo;
	EndDo;
	
	For Each KeyAndValue In RegisterFilterFields Do
		RegisterTableName = KeyAndValue.Key;
		PlacementTable = "tt" + RegisterTableName;
		If RegisterTableName <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, PlacementTable);
		EndIf;
	EndDo;
	
	ThereAreCorrespondenceWithSelection = DataLayoutResultsTable <> Undefined
		And DataLayoutResultsTable.Count() > 0;
	
	If ThereAreCorrespondenceWithSelection Then
		QueriesTexts.Add("
		|SELECT
		|	LayoutResultsTable.RecNo AS RecNo,
		|	LayoutResultsTable.RuleForObtainingFact AS RuleForObtainingFact
		|INTO TTCorrespondenceWithSelection
		|FROM
		|	&DataLayoutResultsTable AS LayoutResultsTable
		|INDEX BY
		|	RecNo,
		|	RuleForObtainingFact
		|");
		
		Query.SetParameter("DataLayoutResultsTable", DataLayoutResultsTable);
	EndIf;
	
	QueryText = "
	|SELECT
	|	CorrespondenceAccordingToRules.RuleForObtainingFact AS RuleForObtainingFact,
	|	CorrespondenceAccordingToRules.EmptyDataSourceDr AS EmptyDataSourceDr,
	|	CorrespondenceAccordingToRules.EmptyDataSourceCr AS EmptyDataSourceCr,
	|	CorrespondenceAccordingToRules.InversionOfDataSources AS InversionOfDataSources,
	|	CorrespondenceAccordingToRules.InversionOfActualData AS InversionOfActualData,
	|	CASE
	|		WHEN NOT CorrespondenceAccordingToRules.InversionOfDataSources
	|			AND NOT CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN &Dr
	|		WHEN CorrespondenceAccordingToRules.InversionOfDataSources
	|			AND CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN &Dr
	|		ELSE &Cr
	|	END AS SourceOfCorrespondenceData,
	|	CorrespondenceAccordingToRules.RecNo AS RecNo,
	|	CorrespondenceAccordingToRules.Period AS Period,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.RegisterNameCr
	|		ELSE CorrespondenceAccordingToRules.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.RegisterNameDr
	|		ELSE CorrespondenceAccordingToRules.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.AccountingObjectCr
	|		ELSE CorrespondenceAccordingToRules.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.AccountingObjectDr
	|		ELSE CorrespondenceAccordingToRules.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.ThisIsReverseTransactionCr
	|		ELSE CorrespondenceAccordingToRules.ThisIsReverseTransactionDr
	|	END AS ThisIsReverseTransactionDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.ThisIsReverseTransactionDr
	|		ELSE CorrespondenceAccordingToRules.ThisIsReverseTransactionCr
	|	END AS ThisIsReverseTransactionCr,
	|	CorrespondenceAccordingToRules.InvertCorrespondence AS InvertCorrespondence,
	|	CorrespondenceAccordingToRules.Organization AS Organization,
	|	CorrespondenceAccordingToRules.Recorder AS Recorder,
	|	CorrespondenceAccordingToRules.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondenceAccordingToRules.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.RowIDCr
	|		ELSE CorrespondenceAccordingToRules.RowIDDr
	|	END AS RowIDDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.RowIDDr
	|		ELSE CorrespondenceAccordingToRules.RowIDCr
	|	END AS RowIDCr,
	|	CorrespondenceAccordingToRules.PropsStorno AS PropsStorno,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.CurrencyCr
	|		ELSE CorrespondenceAccordingToRules.CurrencyDr
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN CorrespondenceAccordingToRules.InvertCorrespondence
	|			THEN CorrespondenceAccordingToRules.CurrencyDr
	|		ELSE CorrespondenceAccordingToRules.CurrencyCr
	|	END AS CurrencyCr,
	|	CorrespondenceAccordingToRules.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	CorrespondenceAccordingToRules.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	CorrespondenceAccordingToRules.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	CorrespondenceAccordingToRules.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	CorrespondenceAccordingToRules.ComplexEntryDr AS ComplexEntryDr,
	|	CorrespondenceAccordingToRules.ComplexEntryCr AS ComplexEntryCr,
	|	CorrespondenceAccordingToRules.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CorrespondenceAccordingToRules.SumManDr AS SumManDr,
	|	CorrespondenceAccordingToRules.SumManCr AS SumManCr,
	|	CorrespondenceAccordingToRules.SumComplDr AS SumComplDr,
	|	CorrespondenceAccordingToRules.SumComplCr AS SumComplCr,
	|	CorrespondenceAccordingToRules.SumCurrDr AS SumCurrDr,
	|	CorrespondenceAccordingToRules.SumCurrCr AS SumCurrCr,
	|	CorrespondenceAccordingToRules.CountDr AS CountDr,
	|	CorrespondenceAccordingToRules.CountCr AS CountCr
	|INTO TTActualCorrespondence
	|FROM
	|	TTCorrespondenceAccordingToRules AS CorrespondenceAccordingToRules
	|WHERE
	|	NOT CorrespondenceAccordingToRules.RuleContainsSelection
	|	OR &ConditionForSelectionOfCorrespondenceWithSelection
	|INDEX BY
	|	RuleForObtainingFact,
	|	AccountingObjectDr,
	|	AccountingObjectCr
	|";
	
	If ThereAreCorrespondenceWithSelection Then
		ConditionForSelectionOfCorrespondenceWithSelection = "TRUE IN
		|	(SELECT TOP 1
		|		TRUE
		|	FROM
		|		TTCorrespondenceWithSelection AS CorrespondenceWithSelection
		|	WHERE
		|		CorrespondenceWithSelection.RecNo = CorrespondenceAccordingToRules.RecNo
		|		AND CorrespondenceWithSelection.RuleForObtainingFact = CorrespondenceAccordingToRules.RuleForObtainingFact
		|	)
		|";
	Else
		ConditionForSelectionOfCorrespondenceWithSelection = "FALSE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionForSelectionOfCorrespondenceWithSelection", ConditionForSelectionOfCorrespondenceWithSelection);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceAccordingToRules");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRulesForProcessingCorrespondence");
	
	If ThereAreCorrespondenceWithSelection Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceWithSelection");
	EndIf;
	
EndProcedure

Procedure CreateRulesForFillingInAnalytics(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	ActualCorrespondence.RuleForObtainingFact AS RuleForObtainingFact,
	|	ActualCorrespondence.EmptyDataSourceDr AS EmptyDataSourceDr,
	|	ActualCorrespondence.EmptyDataSourceCr AS EmptyDataSourceCr,
	|	ActualCorrespondence.InversionOfDataSources AS InversionOfDataSources,
	|	ActualCorrespondence.SourceOfCorrespondenceData AS SourceOfCorrespondenceData,
	|	ActualCorrespondence.AccountingObjectDr AS AccountingObjectDr,
	|	ActualCorrespondence.AccountingObjectCr AS AccountingObjectCr,
	|	ActualCorrespondence.RegisterNameDr AS RegisterNameDr,
	|	ActualCorrespondence.RegisterNameCr AS RegisterNameCr
	|INTO TTRulesForProcessingCorrespondence
	|FROM
	|	TTActualCorrespondence AS ActualCorrespondence
	|GROUP BY
	|	ActualCorrespondence.RuleForObtainingFact,
	|	ActualCorrespondence.EmptyDataSourceDr,
	|	ActualCorrespondence.EmptyDataSourceCr,
	|	ActualCorrespondence.InversionOfDataSources,
	|	ActualCorrespondence.SourceOfCorrespondenceData,
	|	ActualCorrespondence.AccountingObjectDr,
	|	ActualCorrespondence.AccountingObjectCr,
	|	ActualCorrespondence.RegisterNameDr,
	|	ActualCorrespondence.RegisterNameCr
	|INDEX BY
	|	RuleForObtainingFact
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RulesForProcessingCorrespondence.RuleForObtainingFact AS RuleForObtainingFact,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue1
	|			THEN ActualDataQueryRules_.DimensionValue1
	|		ELSE NULL
	|	END AS DimensionValue1,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue2
	|			THEN ActualDataQueryRules_.DimensionValue2
	|		ELSE NULL
	|	END AS DimensionValue2,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue3
	|			THEN ActualDataQueryRules_.DimensionValue3
	|		ELSE NULL
	|	END AS DimensionValue3,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue4
	|			THEN ActualDataQueryRules_.DimensionValue4
	|		ELSE NULL
	|	END AS DimensionValue4,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue5
	|			THEN ActualDataQueryRules_.DimensionValue5
	|		ELSE NULL
	|	END AS DimensionValue5,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue6
	|			THEN ActualDataQueryRules_.DimensionValue6
	|		ELSE NULL
	|	END AS DimensionValue6
	|INTO AnalyticsFillInTTValues
	|FROM
	|	TTRulesForProcessingCorrespondence AS RulesForProcessingCorrespondence
	|	INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRules_
	|		ON RulesForProcessingCorrespondence.RuleForObtainingFact = ActualDataQueryRules_.Ref
	|WHERE
	|	ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue1
	|	OR ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue2
	|	OR ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue3
	|	OR ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue4
	|	OR ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue5
	|	OR ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue6
	|GROUP BY
	|	RulesForProcessingCorrespondence.RuleForObtainingFact,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue1
	|			THEN ActualDataQueryRules_.DimensionValue1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue2
	|			THEN ActualDataQueryRules_.DimensionValue2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue3
	|			THEN ActualDataQueryRules_.DimensionValue3
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue4
	|			THEN ActualDataQueryRules_.DimensionValue4
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue5
	|			THEN ActualDataQueryRules_.DimensionValue5
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue6
	|			THEN ActualDataQueryRules_.DimensionValue6
	|		ELSE NULL
	|	END
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RulesForProcessingCorrespondence.RuleForObtainingFact AS RuleForObtainingFact,
	|	RulesForProcessingCorrespondence.AccountingObjectDr AS AccountingObjectDr,
	|	RulesForProcessingCorrespondence.AccountingObjectCr AS AccountingObjectCr,
	|	CASE
	|		WHEN RulesForProcessingCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN RulesForProcessingCorrespondence.RegisterNameDr
	|		ELSE RulesForProcessingCorrespondence.RegisterNameCr
	|	END AS RegisterName,
	|	CASE
	|		WHEN RulesForProcessingCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN RulesForProcessingCorrespondence.RegisterNameCr
	|		ELSE RulesForProcessingCorrespondence.RegisterNameDr
	|	END AS NameCorRegister,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue1
	|			THEN NULL
	|		ELSE CAST(ActualDataQueryRules_.DimensionPopulationExpression1 AS STRING(1024))
	|	END AS ExpressionAnalytics1,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue2
	|			THEN NULL
	|		ELSE CAST(ActualDataQueryRules_.DimensionPopulationExpression2 AS STRING(1024))
	|	END AS ExpressionAnalytics2,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue3
	|			THEN NULL
	|		ELSE CAST(ActualDataQueryRules_.DimensionPopulationExpression3 AS STRING(1024))
	|	END AS ExpressionAnalytics3,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue4
	|			THEN NULL
	|		ELSE CAST(ActualDataQueryRules_.DimensionPopulationExpression4 AS STRING(1024))
	|	END AS ExpressionAnalytics4,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue5
	|			THEN NULL
	|		ELSE CAST(ActualDataQueryRules_.DimensionPopulationExpression5 AS STRING(1024))
	|	END AS ExpressionAnalytics5,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue6
	|			THEN NULL
	|		ELSE CAST(ActualDataQueryRules_.DimensionPopulationExpression6 AS STRING(1024))
	|	END AS ExpressionAnalytics6,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue1
	|			THEN FALSE
	|		WHEN RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceDr
	|		OR NOT RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceCr
	|			THEN FALSE
	|		ELSE SUBSTRING(ActualDataQueryRules_.DimensionPopulationExpression1, 1, &LengthOfFolderNameCorFields) = &FolderNameCorFields
	|	END AS CorSourceOfAnalytics1,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue2
	|			THEN FALSE
	|		WHEN RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceDr
	|		OR NOT RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceCr
	|			THEN FALSE
	|		ELSE SUBSTRING(ActualDataQueryRules_.DimensionPopulationExpression2, 1, &LengthOfFolderNameCorFields) = &FolderNameCorFields
	|	END AS CorSourceOfAnalytics2,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue3
	|			THEN FALSE
	|		WHEN RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceDr
	|		OR NOT RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceCr
	|			THEN FALSE
	|		ELSE SUBSTRING(ActualDataQueryRules_.DimensionPopulationExpression3, 1, &LengthOfFolderNameCorFields) = &FolderNameCorFields
	|	END AS CorSourceOfAnalytics3,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue4
	|			THEN FALSE
	|		WHEN RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceDr
	|		OR NOT RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceCr
	|			THEN FALSE
	|		ELSE SUBSTRING(ActualDataQueryRules_.DimensionPopulationExpression4, 1, &LengthOfFolderNameCorFields) = &FolderNameCorFields
	|	END AS CorSourceOfAnalytics4,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue5
	|			THEN FALSE
	|		WHEN RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceDr
	|		OR NOT RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceCr
	|			THEN FALSE
	|		ELSE SUBSTRING(ActualDataQueryRules_.DimensionPopulationExpression5, 1, &LengthOfFolderNameCorFields) = &FolderNameCorFields
	|	END AS CorSourceOfAnalytics5,
	|	CASE
	|		WHEN ActualDataQueryRules_.FillInAnalyticsWithSpecifiedValue6
	|			THEN FALSE
	|		WHEN RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceDr
	|		OR NOT RulesForProcessingCorrespondence.InversionOfDataSources AND RulesForProcessingCorrespondence.EmptyDataSourceCr
	|			THEN FALSE
	|		ELSE SUBSTRING(ActualDataQueryRules_.DimensionPopulationExpression6, 1, &LengthOfFolderNameCorFields) = &FolderNameCorFields
	|	END AS CorSourceOfAnalytics6
	|INTO TTAnalyticsFillInExpressions
	|FROM
	|	TTRulesForProcessingCorrespondence AS RulesForProcessingCorrespondence
	|	INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRules_
	|		ON RulesForProcessingCorrespondence.RuleForObtainingFact = ActualDataQueryRules_.Ref
	|INDEX BY
	|	RuleForObtainingFact,
	|	AccountingObjectDr,
	|	AccountingObjectCr
	|");
	
EndProcedure

Procedure IdentifyResourcesOfDataSources(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	CASE
	|		WHEN RulesForProcessingCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN RulesForProcessingCorrespondence.AccountingObjectDr
	|		ELSE RulesForProcessingCorrespondence.AccountingObjectCr
	|	END AS AccountingObject,
	|	CASE
	|		WHEN RulesForProcessingCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN RulesForProcessingCorrespondence.RegisterNameDr
	|		ELSE RulesForProcessingCorrespondence.RegisterNameCr
	|	END AS RegisterName,
	|	ActualDataQueryRules_.TransactionAmountSource AS Factor
	|INTO TTIndicatorsOfRulesForObtainingFact
	|FROM
	|	TTRulesForProcessingCorrespondence AS RulesForProcessingCorrespondence
	|	INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRules_
	|		ON RulesForProcessingCorrespondence.RuleForObtainingFact = ActualDataQueryRules_.Ref
	|GROUP BY
	|	CASE
	|		WHEN RulesForProcessingCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN RulesForProcessingCorrespondence.AccountingObjectDr
	|		ELSE RulesForProcessingCorrespondence.AccountingObjectCr
	|	END,
	|	CASE
	|		WHEN RulesForProcessingCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN RulesForProcessingCorrespondence.RegisterNameDr
	|		ELSE RulesForProcessingCorrespondence.RegisterNameCr
	|	END,
	|	ActualDataQueryRules_.TransactionAmountSource
	|INDEX BY
	|	AccountingObject
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRulesForProcessingCorrespondence");
	
	QueriesTexts.Add("
	|SELECT
	|	IndicatorsOfAccountingObjects.AccountingObject AS AccountingObject
	|INTO TTVariousIndicatorsOfAccountingObjects
	|FROM
	|	(SELECT
	|		AssetLiabilityItemsManResources.Ref AS AccountingObject,
	|		AssetLiabilityItemsManResources.Factor AS Factor
	|	FROM
	|		ChartOfCharacteristicTypes.AssetLiabilityItems.ManResources AS AssetLiabilityItemsManResources
	|	WHERE
	|		TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|			WHERE
	|				IndicatorsOfRulesForGettingFact.AccountingObject = AssetLiabilityItemsManResources.Ref
	|			)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AssetLiabilityItemsLocalResources.Ref AS AccountingObject,
	|		AssetLiabilityItemsLocalResources.Factor AS Factor
	|	FROM
	|		ChartOfCharacteristicTypes.AssetLiabilityItems.LocalResources AS AssetLiabilityItemsLocalResources
	|	WHERE
	|		TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|			WHERE
	|				IndicatorsOfRulesForGettingFact.AccountingObject = AssetLiabilityItemsLocalResources.Ref
	|			)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AssetLiabilityItemsShaftResources.Ref AS AccountingObject,
	|		AssetLiabilityItemsShaftResources.Factor AS Factor
	|	FROM
	|		ChartOfCharacteristicTypes.AssetLiabilityItems.ShaftResources AS AssetLiabilityItemsShaftResources
	|	WHERE
	|		TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|			WHERE
	|				IndicatorsOfRulesForGettingFact.AccountingObject = AssetLiabilityItemsShaftResources.Ref
	|			)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AssetLiabilityItemsResourcesQuantity.Ref AS AccountingObject,
	|		AssetLiabilityItemsResourcesQuantity.Factor AS Factor
	|	FROM
	|		ChartOfCharacteristicTypes.AssetLiabilityItems.ResourcesQuantity AS AssetLiabilityItemsResourcesQuantity
	|	WHERE
	|		TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|			WHERE
	|				IndicatorsOfRulesForGettingFact.AccountingObject = AssetLiabilityItemsResourcesQuantity.Ref
	|			)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AssetLiabilityItemsAdditionalIndicators.Ref AS AccountingObject,
	|		AssetLiabilityItemsAdditionalIndicators.Factor AS Factor
	|	FROM
	|		ChartOfCharacteristicTypes.AssetLiabilityItems.AdditionalIndicators AS AssetLiabilityItemsAdditionalIndicators
	|	WHERE
	|		TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|			WHERE
	|				IndicatorsOfRulesForGettingFact.AccountingObject = AssetLiabilityItemsAdditionalIndicators.Ref
	|			)
	|	) AS IndicatorsOfAccountingObjects
	|GROUP BY
	|	IndicatorsOfAccountingObjects.AccountingObject
	|HAVING
	|	COUNT(DISTINCT IndicatorsOfAccountingObjects.Factor) > 1
	|INDEX BY
	|	AccountingObject
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor
	|INTO TTVariousIndicatorsOfRulesForObtainingFact
	|FROM
	|	TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|	INNER JOIN TTVariousIndicatorsOfAccountingObjects AS VariousIndicatorsOfAccountingObjects
	|	ON IndicatorsOfRulesForGettingFact.AccountingObject = VariousIndicatorsOfAccountingObjects.AccountingObject
	|
	|UNION
	|
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor
	|FROM
	|	TTIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTVariousIndicatorsOfAccountingObjects AS VariousIndicatorsOfAccountingObjects
	|		WHERE
	|			VariousIndicatorsOfAccountingObjects.AccountingObject = IndicatorsOfRulesForGettingFact.AccountingObject
	|		)
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			ChartOfCharacteristicTypes.AssetLiabilityItems.AdditionalIndicators AS AssetLiabilityItemsAdditionalIndicators
	|		WHERE
	|			AssetLiabilityItemsAdditionalIndicators.Ref = IndicatorsOfRulesForGettingFact.AccountingObject
	|		)
	|INDEX BY
	|	AccountingObject,
	|	Factor
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTIndicatorsOfRulesForObtainingFact");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTVariousIndicatorsOfAccountingObjects");
	
	QueriesTexts.Add("
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor,
	|	AssetLiabilityItemsManResources.ResourceName AS ResourceName,
	|	AssetLiabilityItemsManResources.ZoomRatio AS ZoomRatio,
	|	&ManResources AS ResourceGroup
	|INTO TTResourcesOfDataSources
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.ManResources AS AssetLiabilityItemsManResources
	|	INNER JOIN TTVariousIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|	ON AssetLiabilityItemsManResources.Ref = IndicatorsOfRulesForGettingFact.AccountingObject
	|	 AND AssetLiabilityItemsManResources.Factor = IndicatorsOfRulesForGettingFact.Factor
	|
	|UNION ALL
	|
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor,
	|	AssetLiabilityItemsLocalResources.ResourceName AS ResourceName,
	|	AssetLiabilityItemsLocalResources.ZoomRatio AS ZoomRatio,
	|	&LocalResources AS ResourceGroup
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.LocalResources AS AssetLiabilityItemsLocalResources
	|	INNER JOIN TTVariousIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|	ON AssetLiabilityItemsLocalResources.Ref = IndicatorsOfRulesForGettingFact.AccountingObject
	|	 AND AssetLiabilityItemsLocalResources.Factor = IndicatorsOfRulesForGettingFact.Factor
	|
	|UNION ALL
	|
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor,
	|	AssetLiabilityItemsShaftResources.ResourceName AS ResourceName,
	|	AssetLiabilityItemsShaftResources.ZoomRatio AS ZoomRatio,
	|	&ShaftResources AS ResourceGroup
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.ShaftResources AS AssetLiabilityItemsShaftResources
	|	INNER JOIN TTVariousIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|	ON AssetLiabilityItemsShaftResources.Ref = IndicatorsOfRulesForGettingFact.AccountingObject
	|	 AND AssetLiabilityItemsShaftResources.Factor = IndicatorsOfRulesForGettingFact.Factor
	|
	|UNION ALL
	|
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor,
	|	AssetLiabilityItemsResourcesQuantity.ResourceName AS ResourceName,
	|	AssetLiabilityItemsResourcesQuantity.ZoomRatio AS ZoomRatio,
	|	&ResourcesQuantity AS ResourceGroup
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.ResourcesQuantity AS AssetLiabilityItemsResourcesQuantity
	|	INNER JOIN TTVariousIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|	ON AssetLiabilityItemsResourcesQuantity.Ref = IndicatorsOfRulesForGettingFact.AccountingObject
	|	 AND AssetLiabilityItemsResourcesQuantity.Factor = IndicatorsOfRulesForGettingFact.Factor
	|
	|UNION ALL
	|
	|SELECT
	|	IndicatorsOfRulesForGettingFact.AccountingObject AS AccountingObject,
	|	IndicatorsOfRulesForGettingFact.RegisterName AS RegisterName,
	|	IndicatorsOfRulesForGettingFact.Factor AS Factor,
	|	AssetLiabilityItemsAdditionalIndicators.ResourceName AS ResourceName,
	|	AssetLiabilityItemsAdditionalIndicators.ZoomRatio AS ZoomRatio,
	|	AssetLiabilityItemsAdditionalIndicators.ResourceGroup AS ResourceGroup
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.AdditionalIndicators AS AssetLiabilityItemsAdditionalIndicators
	|	INNER JOIN TTVariousIndicatorsOfRulesForObtainingFact AS IndicatorsOfRulesForGettingFact
	|	ON AssetLiabilityItemsAdditionalIndicators.Ref = IndicatorsOfRulesForGettingFact.AccountingObject
	|	 AND AssetLiabilityItemsAdditionalIndicators.Factor = IndicatorsOfRulesForGettingFact.Factor
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTVariousIndicatorsOfRulesForObtainingFact");
	
EndProcedure

Procedure GenerateCorrespondenceAnalyticsRequests(Query, QueriesTexts, RegisterRequestsTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	AnalyticsFillInExpressions.RegisterName AS RegisterName,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics1
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics1
	|		ELSE NULL
	|	END AS ExpressionAnalytics1,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics2
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics2
	|		ELSE NULL
	|	END AS ExpressionAnalytics2,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics3
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics3
	|		ELSE NULL
	|	END AS ExpressionAnalytics3,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics4
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics4
	|		ELSE NULL
	|	END AS ExpressionAnalytics4,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics5
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics5
	|		ELSE NULL
	|	END AS ExpressionAnalytics5,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics6
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics6
	|		ELSE NULL
	|	END AS ExpressionAnalytics6
	|FROM
	|	TTAnalyticsFillInExpressions AS AnalyticsFillInExpressions
	|GROUP BY
	|	AnalyticsFillInExpressions.RegisterName,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics1
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics2
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics3
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics3
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics4
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics4
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics5
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics5
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN NOT AnalyticsFillInExpressions.CorSourceOfAnalytics6
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics6
	|		ELSE NULL
	|	END
	|
	|UNION
	|
	|SELECT
	|	AnalyticsFillInExpressions.NameCorRegister AS RegisterName,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics1
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics1
	|		ELSE NULL
	|	END AS ExpressionAnalytics1,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics2
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics2
	|		ELSE NULL
	|	END AS ExpressionAnalytics2,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics3
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics3
	|		ELSE NULL
	|	END AS ExpressionAnalytics3,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics4
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics4
	|		ELSE NULL
	|	END AS ExpressionAnalytics4,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics5
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics5
	|		ELSE NULL
	|	END AS ExpressionAnalytics5,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics6
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics6
	|		ELSE NULL
	|	END AS ExpressionAnalytics6
	|FROM
	|	TTAnalyticsFillInExpressions AS AnalyticsFillInExpressions
	|WHERE
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics1
	|	OR AnalyticsFillInExpressions.CorSourceOfAnalytics2
	|	OR AnalyticsFillInExpressions.CorSourceOfAnalytics3
	|	OR AnalyticsFillInExpressions.CorSourceOfAnalytics4
	|	OR AnalyticsFillInExpressions.CorSourceOfAnalytics5
	|	OR AnalyticsFillInExpressions.CorSourceOfAnalytics6
	|GROUP BY
	|	AnalyticsFillInExpressions.NameCorRegister,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics1
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics2
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics3
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics3
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics4
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics4
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics5
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics5
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN AnalyticsFillInExpressions.CorSourceOfAnalytics6
	|			THEN AnalyticsFillInExpressions.ExpressionAnalytics6
	|		ELSE NULL
	|	END
	|TOTALS BY
	|	RegisterName
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	DataSourcesResources.RegisterName AS RegisterName,
	|	DataSourcesResources.ResourceName AS ResourceName
	|FROM
	|	TTResourcesOfDataSources AS DataSourcesResources
	|GROUP BY
	|	DataSourcesResources.RegisterName,
	|	DataSourcesResources.ResourceName
	|TOTALS BY
	|	RegisterName
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	ResultOfAnalyticsExpression = Results[Results.UBound() - 1];
	ResultResourcesOfSources = Results[Results.UBound()];
	
	FetchingRegisterName = ResultOfAnalyticsExpression.Select(QueryResultIteration.ByGroups);
	SamplingSourceName = ResultResourcesOfSources.Select(QueryResultIteration.ByGroups);
	
	SelectionFieldsToDelete = DeletedFieldsForSelectingMotionAnalyticsQueries();
	ReverseIndexFields = IndexFieldsOfTablesReplacingReverseWithReverse();
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();
	
	DeletedTemporaryTables = New Array();
	IndexOfResultOfAnalyticsQuery = 0;
	
	While FetchingRegisterName.Next() Do
		RegisterAnalyticsExpressions = RegisterAnalyticsExpressions(FetchingRegisterName, Query.Parameters);
		
		SelectionOfAnalyticsFields = New Array();
		SelectingSourceResources = New Array();
		GroupingAnalyticsFields = New Array();
		
		FillInLinesOfExpressionSelection(SelectionOfAnalyticsFields, GroupingAnalyticsFields,
			RegisterAnalyticsExpressions, Query.Parameters.AllAnalyticsExpressions);
		
		SamplingSourceName.Reset();
		TheStructureOfTheSearch = New Structure("RegisterName", FetchingRegisterName.RegisterName);
		
		If SamplingSourceName.FindNext(TheStructureOfTheSearch) Then
			FillInResourceSelectionLines(SelectingSourceResources, SamplingSourceName);
		EndIf;
		
		RegisterTableName = FetchingRegisterName.RegisterName;
		TemporaryRegisterTableName = "tt" + FetchingRegisterName.RegisterName;
		
		If Query.TempTablesManager.Tables.Find(TemporaryRegisterTableName) = Undefined Then
			RegisterRequestText = RegisterRequestsTexts[RegisterTableName];
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
				SelectingSourceResources, RegisterRequestText);
			
			StornoReplacementWithReverseIsRequired = Query.Parameters.RegistersAreReplacedStornoByReverse.Find(RegisterTableName) <> Undefined;
			ReverseEntryNeedsToBeReplacedStorno = Query.Parameters.ReverseToReverseReplacementRegisters.Find(RegisterTableName) <> Undefined;
			
			If StornoReplacementWithReverseIsRequired Or ReverseEntryNeedsToBeReplacedStorno Then
				If StornoReplacementWithReverseIsRequired Then
					StornoReplacementTable = TemporaryRegisterTableName + "ReplacementStorno";
					FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete,, StornoReplacementTable);
					QueriesTexts.Add(RegisterRequestText);
					RegisterRequestText = TextOfAnalysisSelectionFromNestedTable();
					RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", StornoReplacementTable);
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
						SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
						SelectingSourceResources, RegisterRequestText);
					DeletedTemporaryTables.Add(StornoReplacementTable);
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
				EndIf;
				
				If ReverseEntryNeedsToBeReplacedStorno Then
					ReverseReplacementTable = TemporaryRegisterTableName + "ReverseReplacement";
					FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, ReverseIndexFields, ReverseReplacementTable);
					QueriesTexts.Add(RegisterRequestText);
					RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable(True);
					RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", ReverseReplacementTable);
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
						SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
						SelectingSourceResources, RegisterRequestText);
					DeletedTemporaryTables.Add(ReverseReplacementTable);
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
				EndIf;
			Else
				FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete);
			EndIf;
			
			If RegistersOfRecoveryOfCalculationsOnStorno.Find(RegisterTableName) <> Undefined Then
				AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterTableName);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
					SelectingSourceResources, RegisterRequestText);
			EndIf;
		Else
			RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable();
			RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", TemporaryRegisterTableName);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				SelectionOfAnalyticsFields, GroupingAnalyticsFields, RegisterRequestText);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfResourcesToQueryText(
				SelectingSourceResources, RegisterRequestText);
		EndIf;
		
		QueriesTexts.Add(RegisterRequestText);
		Query.Parameters.AnalyticsSampleRegisters.Insert(FetchingRegisterName.RegisterName, IndexOfResultOfAnalyticsQuery);
		IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
	EndDo;
	
	QueriesTexts.Add("
	|SELECT
	|	ActualCorrespondence.RuleForObtainingFact AS RuleForObtainingFact,
	|	ActualCorrespondence.InversionOfActualData AS InversionOfActualData,
	|	ActualCorrespondence.SourceOfCorrespondenceData AS SourceOfCorrespondenceData,
	|	CASE
	|		WHEN ActualCorrespondence.SourceOfCorrespondenceData = &Dr
	|			THEN &Cr
	|		ELSE &Dr
	|	END AS CorSourceOfCorrespondenceData,
	|	ISNULL(AnalyticsFillInExpressions.CorSourceOfAnalytics1
	|		OR AnalyticsFillInExpressions.CorSourceOfAnalytics2
	|		OR AnalyticsFillInExpressions.CorSourceOfAnalytics3
	|		OR AnalyticsFillInExpressions.CorSourceOfAnalytics4
	|		OR AnalyticsFillInExpressions.CorSourceOfAnalytics5
	|		OR AnalyticsFillInExpressions.CorSourceOfAnalytics6, FALSE) AS GetCoreAnalytics,
	|	ActualCorrespondence.RecNo AS RecNo,
	|	ActualCorrespondence.Period AS Period,
	|	ActualCorrespondence.RegisterNameDr AS RegisterNameDr,
	|	ActualCorrespondence.RegisterNameCr AS RegisterNameCr,
	|	ActualCorrespondence.AccountingObjectDr AS AccountingObjectDr,
	|	ActualCorrespondence.AccountingObjectCr AS AccountingObjectCr,
	|	ActualCorrespondence.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	ActualCorrespondence.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	ActualCorrespondence.InvertCorrespondence AS InvertCorrespondence,
	|	ActualCorrespondence.Organization AS Organization,
	|	ActualCorrespondence.Recorder AS Recorder,
	|	ActualCorrespondence.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	ActualCorrespondence.FinRecordID AS FinRecordID,
	|	ActualCorrespondence.RowIDDr AS RowIDDr,
	|	ActualCorrespondence.RowIDCr AS RowIDCr,
	|	ActualCorrespondence.PropsStorno AS PropsStorno,
	|	ActualCorrespondence.CurrencyDr AS CurrencyDr,
	|	ActualCorrespondence.CurrencyCr AS CurrencyCr,
	|	ActualCorrespondence.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	ActualCorrespondence.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	ActualCorrespondence.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	ActualCorrespondence.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	ActualCorrespondence.ComplexEntryDr AS ComplexEntryDr,
	|	ActualCorrespondence.ComplexEntryCr AS ComplexEntryCr,
	|	ActualCorrespondence.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	ActualCorrespondence.SumManDr AS SumMan,
	|	ActualCorrespondence.SumComplDr AS SumCompl,
	|	ActualCorrespondence.SumCurrDr AS SumCurrDr,
	|	ActualCorrespondence.SumCurrCr AS SumCurrCr,
	|	ActualCorrespondence.CountDr AS CountDr,
	|	ActualCorrespondence.CountCr AS CountCr
	|FROM
	|	TTActualCorrespondence AS ActualCorrespondence
	|	LEFT JOIN TTAnalyticsFillInExpressions AS AnalyticsFillInExpressions
	|	ON ActualCorrespondence.RuleForObtainingFact = AnalyticsFillInExpressions.RuleForObtainingFact
	|	 AND ActualCorrespondence.AccountingObjectDr = AnalyticsFillInExpressions.AccountingObjectDr
	|	 AND ActualCorrespondence.AccountingObjectCr = AnalyticsFillInExpressions.AccountingObjectCr
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	AnalyticsFillInValues.RuleForObtainingFact AS RuleForObtainingFact,
	|	AnalyticsFillInValues.DimensionValue1 AS DimensionValue1,
	|	AnalyticsFillInValues.DimensionValue2 AS DimensionValue2,
	|	AnalyticsFillInValues.DimensionValue3 AS DimensionValue3,
	|	AnalyticsFillInValues.DimensionValue4 AS DimensionValue4,
	|	AnalyticsFillInValues.DimensionValue5 AS DimensionValue5,
	|	AnalyticsFillInValues.DimensionValue6 AS DimensionValue6
	|FROM
	|	AnalyticsFillInTTValues AS AnalyticsFillInValues
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	AnalyticsFillInExpressions.RuleForObtainingFact AS RuleForObtainingFact,
	|	AnalyticsFillInExpressions.AccountingObjectDr AS AccountingObjectDr,
	|	AnalyticsFillInExpressions.AccountingObjectCr AS AccountingObjectCr,
	|	AnalyticsFillInExpressions.ExpressionAnalytics1 AS ExpressionAnalytics1,
	|	AnalyticsFillInExpressions.ExpressionAnalytics2 AS ExpressionAnalytics2,
	|	AnalyticsFillInExpressions.ExpressionAnalytics3 AS ExpressionAnalytics3,
	|	AnalyticsFillInExpressions.ExpressionAnalytics4 AS ExpressionAnalytics4,
	|	AnalyticsFillInExpressions.ExpressionAnalytics5 AS ExpressionAnalytics5,
	|	AnalyticsFillInExpressions.ExpressionAnalytics6 AS ExpressionAnalytics6,
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics1 AS CorSourceOfAnalytics1,
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics2 AS CorSourceOfAnalytics2,
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics3 AS CorSourceOfAnalytics3,
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics4 AS CorSourceOfAnalytics4,
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics5 AS CorSourceOfAnalytics5,
	|	AnalyticsFillInExpressions.CorSourceOfAnalytics6 AS CorSourceOfAnalytics6
	|FROM
	|	TTAnalyticsFillInExpressions AS AnalyticsFillInExpressions
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	DataSourcesResources.AccountingObject AS AccountingObject,
	|	DataSourcesResources.Factor AS Factor,
	|	DataSourcesResources.ResourceGroup AS ResourceGroup,
	|	DataSourcesResources.ResourceName AS ResourceName,
	|	DataSourcesResources.ZoomRatio AS ZoomRatio
	|FROM
	|	TTResourcesOfDataSources AS DataSourcesResources
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ComplexCorrespondence.RecNo AS RecNo,
	|	ComplexCorrespondence.Period AS Period,
	|	ComplexCorrespondence.Organization AS Organization,
	|	ComplexCorrespondence.Recorder AS Recorder,
	|	ComplexCorrespondence.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	ComplexCorrespondence.FinRecordID AS FinRecordID,
	|	ComplexCorrespondence.PropsStorno AS PropsStorno,
	|	ComplexCorrespondence.AmountOfManMovement AS AmountOfManMovement,
	|	ComplexCorrespondence.AmountOfLocalTraffic AS AmountOfLocalTraffic,
	|	ComplexCorrespondence.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	ComplexCorrespondence.SumMan AS SumMan,
	|	ComplexCorrespondence.SumCompl AS SumCompl
	|FROM
	|	TTComplexCorrespondence AS ComplexCorrespondence
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

Procedure FillInActualDataTable(Query, QueriesTexts, ActualDataTable,
	DocumentsForProcessing_, FactGettingParameters, RulesTable)
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	FactGettingParameters.Insert("LengthOfSum", Query.Parameters.LengthOfSum);
	FactGettingParameters.Insert("SumAccuracy", Query.Parameters.SumAccuracy);
	FactGettingParameters.Insert("LengthOfQuantity", Query.Parameters.LengthOfQuantity);
	FactGettingParameters.Insert("QuantityAccuracy", Query.Parameters.QuantityAccuracy);
	
	AnalyticsTables = New Structure();
	IndexOfResultOfCorrespondenceRequest = 0;
	
	For Each KeyAndValue In Query.Parameters.AnalyticsSampleRegisters Do
		AnalyticsTables.Insert(KeyAndValue.Key, AnalyticsQueryTable(Results[KeyAndValue.Value]));
		If KeyAndValue.Value >= IndexOfResultOfCorrespondenceRequest Then
			IndexOfResultOfCorrespondenceRequest = KeyAndValue.Value + 1;
		EndIf;
	EndDo;
	
	AnalyticsValueResultIndex = IndexOfResultOfCorrespondenceRequest + 1;
	IndexOfResultOfAnalyticsExpressions = IndexOfResultOfCorrespondenceRequest + 2;
	ResultIndexResourcesOfIndicators = IndexOfResultOfCorrespondenceRequest + 3;
	IndexOfResultOfComplexCorrespondence = IndexOfResultOfCorrespondenceRequest + 4;
	
	ResultOfCorrespondence = Results[IndexOfResultOfCorrespondenceRequest];
	ResultOfAnalyticsValue = Results[AnalyticsValueResultIndex];
	ResultOfAnalyticsExpression = Results[IndexOfResultOfAnalyticsExpressions];
	ResultResourcesOfIndicators = Results[ResultIndexResourcesOfIndicators];
	ResultIsComplexCorrespondence = Results[IndexOfResultOfComplexCorrespondence];
	
	SelectionCorrespondence = ResultOfCorrespondence.Select();
	SamplingAnalyticsValues = ResultOfAnalyticsValue.Select();
	SelectingAnalyticsExpression = ResultOfAnalyticsExpression.Select();
	SamplingResourcesOfIndicators = ResultResourcesOfIndicators.Select();
	SamplingComplexCorrespondence = ResultIsComplexCorrespondence.Select();
	
	While SelectionCorrespondence.Next() Do
		DrCr = SelectionCorrespondence.SourceOfCorrespondenceData;
		BalancedDrCr = SelectionCorrespondence.CorSourceOfCorrespondenceData;
		
		AnalyticsOfDataSource = TrafficAnalyticsLines(SelectionCorrespondence,
			SamplingAnalyticsValues, SelectingAnalyticsExpression, AnalyticsTables, Query.Parameters, DrCr);
		AnalyticsOfCoreDataSource = TrafficAnalyticsLines(SelectionCorrespondence,
			SamplingAnalyticsValues, SelectingAnalyticsExpression, AnalyticsTables, Query.Parameters, BalancedDrCr);
		
		CorrespondenceErrors = New Map();
		
		If Not FinancialAccountingByBalanceSheetRegisterData.CheckingEqualityOfBalanceResources(
			SelectionCorrespondence, AnalyticsOfDataSource, Query.Parameters, DrCr) Then
			CorrespondenceErrors.Insert(StrTemplate(
				NStr("vi = 'Lỗi khi chọn đối tượng phân tích đối với bản ghi của biểu ghi ""%1"" với tên định danh %2.';
					|ru = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
					|en = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.'; fa = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
					|it = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
					|pl = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
					|tr = '%2 kimlikli ""%1"" kayıt girişinin boyutu seçilirken hata oluştu.'"),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[SelectionCorrespondence["RegisterName" + DrCr]]),
				SelectionCorrespondence.FinRecordID));
		EndIf;
		
		If SelectionCorrespondence.GetCoreAnalytics
		And Not FinancialAccountingByBalanceSheetRegisterData.CheckingEqualityOfBalanceResources(
			SelectionCorrespondence, AnalyticsOfCoreDataSource, Query.Parameters, BalancedDrCr) Then
			CorrespondenceErrors.Insert(StrTemplate(
				NStr("vi = 'Lỗi khi chọn đối tượng phân tích đối với bản ghi của biểu ghi ""%1"" với tên định danh %2.';
					|ru = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
					|en = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.'; fa = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
					|it = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
					|pl = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
					|tr = '%2 kimlikli ""%1"" kayıt girişinin boyutu seçilirken hata oluştu.'"),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[SelectionCorrespondence["RegisterName" + BalancedDrCr]]),
				SelectionCorrespondence.FinRecordID));
		EndIf;
		
		If AnalyticsOfDataSource.Count() > 1 And AnalyticsOfCoreDataSource.Count() > 1 Then
			CorrespondenceErrors.Insert(StrTemplate(
				NStr("vi = 'Các bản ghi của biểu ghi ""%1"" và ""%2"" với tên định danh %3 có mối liên hệ ""nhiều với nhiều"".';
					|ru = 'Записи регистров ""%1"" и ""%2"" с идентификатором %3 имеют отношение ""многие ко многим"".';
					|en = 'Records of registers ""%1"" and ""%2"" with ID %3 have the Many-to-Many relationship.'; fa = 'Records of registers ""%1"" and ""%2"" with ID %3 have the Many-to-Many relationship.';
					|it = 'Voci di registro ""%1"" e ""%2"" con ID %3 hanno relazione ""molti verso molti"".';
					|pl = 'Wpisy rejestrów ""%1"" i ""%2"" z identyfikatorem %3 mają stosunek ""wiele do wielu"".';
					|tr = '%3 kimlikli ""%1"" ve ""%2"" kayıt girişlerinin ""çoktan çok olana"" ilişkisi var.'"),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[SelectionCorrespondence.RegisterNameDr]),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[SelectionCorrespondence.RegisterNameCr]),
				SelectionCorrespondence.FinRecordID));
		EndIf;
		
		TheStructureOfTheSearch = New Structure("Rule", SelectionCorrespondence.RuleForObtainingFact);
		RulesLines = RulesTable.FindRows(TheStructureOfTheSearch);
		
		If RulesLines <> Undefined Then
			RuleDescription_ = RulesLines[0];
		Else
			CorrespondenceErrors.Insert(StrTemplate(
				NStr("vi = 'Lỗi khi truy cập đến thuộc tính quy tắc nhận dữ liệu thực tế ""%1"".';
					|ru = 'Ошибка при обращении к свойствам правила получения фактических данных ""%1"".';
					|en = 'An error occurred when accessing the properties of the rule for obtaining the ""%1"" actual data.'; fa = 'An error occurred when accessing the properties of the rule for obtaining the ""%1"" actual data.';
					|it = 'An error occurred when accessing the properties of the rule for obtaining the ""%1"" actual data.';
					|pl = 'An error occurred when accessing the properties of the rule for obtaining the ""%1"" actual data.';
					|tr = '""%1"" gerçek verileri alma kuralının özelliklerine erişilirken hata oluştu.'"),
				SelectionCorrespondence.RuleForObtainingFact));
		EndIf;
		
		If CorrespondenceErrors.Count() > 0 Then
			ErrorText = "";
			For Each CorrespondenceError In CorrespondenceErrors Do
				ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + CorrespondenceError.Key;
			EndDo;
			RegisterDocumentProcessingError(ErrorText, SelectionCorrespondence, DocumentsForProcessing_, RuleDescription_);
			Continue;
		EndIf;
		
		DescriptionIndicator = DescriptionOfDataSourceIndicator(SamplingResourcesOfIndicators, RuleDescription_);
		ResourcesValues = IndicatorResourceValues(SelectionCorrespondence, DescriptionIndicator, AnalyticsOfDataSource, FactGettingParameters, DrCr);
		
		If SelectionCorrespondence["ComplexEntry" + DrCr] Then
			If Not SourceBalanceIndicator(DescriptionIndicator) Then
				RecalculateResourcesOfUnbalancedComplexCorrespondenceIndicator(SelectionCorrespondence, SamplingComplexCorrespondence, ResourcesValues);
			ElsIf ResourcesValues.Count() > 1 Then
				RecalculateResourcesOfBalanceIndicatorOfComplexCorrespondence(SelectionCorrespondence, ResourcesValues, DrCr);
			EndIf;
		EndIf;
		
		If AnalyticsOfDataSource.Count() = 1 And AnalyticsOfCoreDataSource.Count() <= 1 Then
			GetSimpleAnalyticsData(SelectionCorrespondence, ActualDataTable, ResourcesValues,
				AnalyticsOfDataSource, AnalyticsOfCoreDataSource, FactGettingParameters, RuleDescription_);
		Else
			GetSophisticatedAnalyticsData(SelectionCorrespondence, ActualDataTable, ResourcesValues,
				AnalyticsOfDataSource, AnalyticsOfCoreDataSource, FactGettingParameters, RuleDescription_);
		EndIf;
	EndDo;
	
	CollapseActualDataTable(ActualDataTable);
	
EndProcedure

Procedure RegisterDocumentProcessingError(ErrorText, SelectionCorrespondence, DocumentsForProcessing_, RuleDescription_)
	
	TheStructureOfTheSearch = New Structure("Document", SelectionCorrespondence.Recorder);
	DocumentRows = DocumentsForProcessing_.FindRows(TheStructureOfTheSearch);
	ErrorString = Undefined;
	
	For Each DocumentLine In DocumentRows Do
		If DocumentLine.Organization.IsEmpty() And DocumentLine.Period = '00010101'
		 Or DocumentLine.Organization = SelectionCorrespondence.Organization
			And DocumentLine.Period = SelectionCorrespondence.Period Then
			ErrorString = DocumentLine;
			Break;
		EndIf;
	EndDo;
	
	If ErrorString = Undefined Then
		ErrorString = DocumentsForProcessing_.Add();
		ErrorString.Document = TheStructureOfTheSearch.Document;
	EndIf;
	
	ErrorString.Error = True;
	ErrorString.Period = SelectionCorrespondence.Period;
	ErrorString.Organization = SelectionCorrespondence.Organization;
	ErrorString.Comment = ErrorString.Comment
		+ ?(IsBlankString(ErrorString.Comment), "", Chars.LF)
		+ ErrorText;
	ErrorString.Rule = RuleDescription_.Rule;
	ErrorString.BudgetFlowItem = RuleDescription_.BudgetFlowItem;
	
EndProcedure

Procedure CollapseActualDataTable(ActualDataTable)
	
	GroupColumns = New Array();
	TotalingColumns = New Array();
	
	For Each Column In ActualDataTable.Columns Do
		If Column.ValueType.ContainsType(Type("Number")) Then
			TotalingColumns.Add(Column.Name);
		Else
			GroupColumns.Add(Column.Name);	
		EndIf;
	EndDo;	
	
	GroupColumns  = StrConcat(GroupColumns , ",");
	TotalingColumns = StrConcat(TotalingColumns, ",");
	
	ActualDataTable.GroupBy(GroupColumns, TotalingColumns);
	
EndProcedure

#Region RequestTextsForProcessingRegisterRegisteredRecords

Procedure AddTablesOfDebitAndCreditRegisteredRecords(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|	RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS OfficialTypeOfActivityVAT,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	RegisterRegisteredRecords_1.SumMan AS SumMan,
	|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTRegisterRecordsFromStorno
	|FROM
	|	TTMovementRegisters AS RegisterRegisteredRecords_1
	|WHERE
	|	RegisterRegisteredRecords_1.SumMan < 0 OR RegisterRegisteredRecords_1.SumCompl < 0
	|	OR RegisterRegisteredRecords_1.SumCurr < 0 OR RegisterRegisteredRecords_1.Count < 0
	|INDEX BY
	|	ThisIsDebit,
	|	ThisIsLoan
	|");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	RegisterRecordsWithStorno.RegisterName AS RegisterName
	|INTO TTRegistersAreReplacedStornoByReverse
	|FROM
	|	TTRegisterRecordsFromStorno AS RegisterRecordsWithStorno
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutManSum)
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN RegisterRegisteredRecords_1.Currency = &ManagementAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			THEN CASE
	|				WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|					THEN RegisterRegisteredRecords_1.SumCompl
	|				WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|					THEN RegisterRegisteredRecords_1.SumCurr
	|				ELSE RegisterRegisteredRecords_1.SumMan
	|			END
	|		ELSE RegisterRegisteredRecords_1.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutSumLocal)
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN RegisterRegisteredRecords_1.Currency = RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			AND RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		ELSE RegisterRegisteredRecords_1.SumCompl
	|	END AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTCollapsedRegisteredRecordsDebit
	|FROM
	|	(SELECT
	|		RegisterRegisteredRecords_1.Period AS Period,
	|		RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|		RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|		RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|		RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRegisteredRecords_1.Organization AS Organization,
	|		RegisterRegisteredRecords_1.Recorder AS Recorder,
	|		RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|		RegisterRegisteredRecords_1.RowID AS RowID,
	|		RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRegisteredRecords_1.Currency AS Currency,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.SumMan >= 0
	|				THEN RegisterRegisteredRecords_1.SumMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.SumCompl >= 0
	|				THEN RegisterRegisteredRecords_1.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.SumCurr >= 0
	|				THEN RegisterRegisteredRecords_1.SumCurr
	|			ELSE 0
	|		END AS SumCurr,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.Count >= 0
	|				THEN RegisterRegisteredRecords_1.Count
	|			ELSE 0
	|		END AS Count,
	|		RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|	FROM
	|		TTMovementRegisters AS RegisterRegisteredRecords_1
	|	WHERE
	|		NOT RegisterRegisteredRecords_1.ThisIsLoan
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecordsWithStorno.Period AS Period,
	|		RegisterRecordsWithStorno.RegisterName AS RegisterName,
	|		RegisterRecordsWithStorno.AccountingObject AS AccountingObject,
	|		RegisterRecordsWithStorno.ThisIsLoan AS ThisIsDebit,
	|		NOT RegisterRecordsWithStorno.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRecordsWithStorno.Organization AS Organization,
	|		RegisterRecordsWithStorno.Recorder AS Recorder,
	|		RegisterRecordsWithStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRecordsWithStorno.FinRecordID AS FinRecordID,
	|		RegisterRecordsWithStorno.RowID AS RowID,
	|		RegisterRecordsWithStorno.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRecordsWithStorno.Currency AS Currency,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.SumMan < 0
	|				THEN -RegisterRecordsWithStorno.SumMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.SumCompl < 0
	|				THEN -RegisterRecordsWithStorno.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.SumCurr < 0
	|				THEN -RegisterRecordsWithStorno.SumCurr
	|			ELSE 0
	|		END AS SumCurr,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.Count < 0
	|				THEN -RegisterRecordsWithStorno.Count
	|			ELSE 0
	|		END AS Count,
	|		RegisterRecordsWithStorno.PropsStorno AS PropsStorno
	|	FROM
	|		TTRegisterRecordsFromStorno AS RegisterRecordsWithStorno
	|	WHERE
	|		NOT RegisterRecordsWithStorno.ThisIsDebit
	|	) AS RegisterRegisteredRecords_1
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutManSum)
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN RegisterRegisteredRecords_1.Currency = &ManagementAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			THEN CASE
	|				WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|					THEN RegisterRegisteredRecords_1.SumCompl
	|				WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|					THEN RegisterRegisteredRecords_1.SumCurr
	|				ELSE RegisterRegisteredRecords_1.SumMan
	|			END
	|		ELSE RegisterRegisteredRecords_1.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutSumLocal)
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN RegisterRegisteredRecords_1.Currency = RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			AND RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		ELSE RegisterRegisteredRecords_1.SumCompl
	|	END AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTRolledUpMotionCredit
	|FROM
	|	(SELECT
	|		RegisterRegisteredRecords_1.Period AS Period,
	|		RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|		RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|		RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|		RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRegisteredRecords_1.Organization AS Organization,
	|		RegisterRegisteredRecords_1.Recorder AS Recorder,
	|		RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|		RegisterRegisteredRecords_1.RowID AS RowID,
	|		RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRegisteredRecords_1.Currency AS Currency,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.SumMan >= 0
	|				THEN RegisterRegisteredRecords_1.SumMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.SumCompl >= 0
	|				THEN RegisterRegisteredRecords_1.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.SumCurr >= 0
	|				THEN RegisterRegisteredRecords_1.SumCurr
	|			ELSE 0
	|		END AS SumCurr,
	|		CASE
	|			WHEN RegisterRegisteredRecords_1.Count >= 0
	|				THEN RegisterRegisteredRecords_1.Count
	|			ELSE 0
	|		END AS Count,
	|		RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|	FROM
	|		TTMovementRegisters AS RegisterRegisteredRecords_1
	|	WHERE
	|		NOT RegisterRegisteredRecords_1.ThisIsDebit
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecordsWithStorno.Period AS Period,
	|		RegisterRecordsWithStorno.RegisterName AS RegisterName,
	|		RegisterRecordsWithStorno.AccountingObject AS AccountingObject,
	|		RegisterRecordsWithStorno.ThisIsDebit AS ThisIsLoan,
	|		NOT RegisterRecordsWithStorno.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRecordsWithStorno.Organization AS Organization,
	|		RegisterRecordsWithStorno.Recorder AS Recorder,
	|		RegisterRecordsWithStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRecordsWithStorno.FinRecordID AS FinRecordID,
	|		RegisterRecordsWithStorno.RowID AS RowID,
	|		RegisterRecordsWithStorno.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRecordsWithStorno.Currency AS Currency,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.SumMan < 0
	|				THEN -RegisterRecordsWithStorno.SumMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.SumCompl < 0
	|				THEN -RegisterRecordsWithStorno.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.SumCurr < 0
	|				THEN -RegisterRecordsWithStorno.SumCurr
	|			ELSE 0
	|		END AS SumCurr,
	|		CASE
	|			WHEN RegisterRecordsWithStorno.Count < 0
	|				THEN -RegisterRecordsWithStorno.Count
	|			ELSE 0
	|		END AS Count,
	|		RegisterRecordsWithStorno.PropsStorno AS PropsStorno
	|	FROM
	|		TTRegisterRecordsFromStorno AS RegisterRecordsWithStorno
	|	WHERE
	|		NOT RegisterRecordsWithStorno.ThisIsLoan
	|	) AS RegisterRegisteredRecords_1
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementRegisters");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterRecordsFromStorno");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	StornoReplacementRegisterTable = Query.TempTablesManager.Tables.Find("TTRegistersAreReplacedStornoByReverse");
	StornoReplacementRegisterTable = StornoReplacementRegisterTable.GetData().Unload();
	Query.Parameters.RegistersAreReplacedStornoByReverse = StornoReplacementRegisterTable.UnloadColumn("RegisterName");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegistersAreReplacedStornoByReverse");
	
EndProcedure

Procedure ProcessAndConnectMovementTables(Query, QueriesTexts)
	
	IdentifyComplexTransactionsWithIndicationOfCorSources(Query, QueriesTexts);
	
	AddDataSourceIDs(QueriesTexts, Query.Parameters, "Dr");
	AddDataSourceIDs(QueriesTexts, Query.Parameters, "Cr");
	
	AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, "Dr");
	AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, "Cr");
	
	ConnectRegisteredRecordsByKeyFields(Query, QueriesTexts);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisteredRecordsWithDebitTotals");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisteredRecordsWithCreditTotals");
	
EndProcedure

Procedure IdentifyComplexTransactionsWithIndicationOfCorSources(Query, QueriesTexts)
	
	If Query.TempTablesManager.Tables.Find("TTCorDataSources") = Undefined Then
		QueriesTexts.Add("
		|SELECT
		|	CorDataSources.AccountingObject AS AccountingObject,
		|	CorDataSources.CorDataSource AS CorRegisterName,
		|	CorDataSources.Id AS Id,
		|	CorDataSources.CorID AS CorID
		|INTO TTCorDataSources
		|FROM
		|	&CorDataSources AS CorDataSources
		|INDEX BY
		|	AccountingObject,
		|	CorRegisterName
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	CorDataSources.AccountingObject AS AccountingObject,
		|	CorDataSources.Id AS Id
		|INTO TTIdsOfCorDataSources
		|FROM
		|	TTCorDataSources AS CorDataSources
		|GROUP BY
		|	CorDataSources.AccountingObject,
		|	CorDataSources.Id
		|INDEX BY
		|	AccountingObject
		|");
	EndIf;
	
	QueriesTexts.Add("
	|SELECT
	|	DirectDebit.Period AS Period,
	|	DirectDebit.Organization AS Organization,
	|	DirectDebit.Recorder AS Recorder,
	|	DirectDebit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DirectDebit.FinRecordID AS FinRecordID,
	|	DirectDebit.PropsStorno AS PropsStorno,
	|	CorDataSources.CorRegisterName AS CorRegisterName,
	|	CorDataSources.CorID AS CorID,
	|	COUNT(DISTINCT DirectDebit.AccountingObject) AS NumberOfAccountingObjects
	|INTO TTTransactionIDsDebit
	|FROM
	|	TTCollapsedRegisteredRecordsDebit AS DirectDebit
	|	INNER JOIN TTCorDataSources AS CorDataSources
	|		ON DirectDebit.AccountingObject = CorDataSources.AccountingObject
	|GROUP BY
	|	DirectDebit.Period,
	|	DirectDebit.Recorder,
	|	DirectDebit.FinRecordID,
	|	DirectDebit.Organization,
	|	DirectDebit.SettingUpBusinessTransaction,
	|	DirectDebit.PropsStorno,
	|	CorDataSources.CorRegisterName,
	|	CorDataSources.CorID
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	CorRegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	MovementCredit.Period AS Period,
	|	MovementCredit.Organization AS Organization,
	|	MovementCredit.Recorder AS Recorder,
	|	MovementCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementCredit.FinRecordID AS FinRecordID,
	|	MovementCredit.PropsStorno AS PropsStorno,
	|	CorDataSources.CorRegisterName AS CorRegisterName,
	|	CorDataSources.CorID AS CorID,
	|	COUNT(DISTINCT MovementCredit.AccountingObject) AS NumberOfAccountingObjects
	|INTO TTTransactionIDsCredit
	|FROM
	|	TTRolledUpMotionCredit AS MovementCredit
	|	INNER JOIN TTCorDataSources AS CorDataSources
	|		ON MovementCredit.AccountingObject = CorDataSources.AccountingObject
	|GROUP BY
	|	MovementCredit.Period,
	|	MovementCredit.Recorder,
	|	MovementCredit.FinRecordID,
	|	MovementCredit.Organization,
	|	MovementCredit.SettingUpBusinessTransaction,
	|	MovementCredit.PropsStorno,
	|	CorDataSources.CorRegisterName,
	|	CorDataSources.CorID
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	CorRegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno
	|");
	
	QueriesTexts.Add("
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	TTTransactionIDsDebit AS IdsOfDebitTransactions
	|WHERE
	|	IdsOfDebitTransactions.NumberOfAccountingObjects > 1
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	TTTransactionIDsCredit AS TransactionIDs_
	|WHERE
	|	TransactionIDs_.NumberOfAccountingObjects > 1
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueriesTexts.Clear();
	
	Results = Query.ExecuteBatch();
	HasComplexEntries = Not Results[Results.UBound()].IsEmpty();
	
	If Not HasComplexEntries Then
		Query.Text = "
		|SELECT TOP 1
		|	DirectDebit.Period AS Period,
		|	DirectDebit.RegisterName AS RegisterName,
		|	DirectDebit.Organization AS Organization,
		|	DirectDebit.Recorder AS Recorder,
		|	DirectDebit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	DirectDebit.FinRecordID AS FinRecordID,
		|	DirectDebit.PropsStorno AS PropsStorno,
		|	COUNT(DISTINCT DirectDebit.AccountingObject) AS NumberOfAccountingObjects
		|FROM
		|	TTCollapsedRegisteredRecordsDebit AS DirectDebit
		|	INNER JOIN TTTransactionIDsCredit AS TransactionIDs_
		|		ON DirectDebit.Period = TransactionIDs_.Period
		|		 AND DirectDebit.Recorder = TransactionIDs_.Recorder
		|		 AND DirectDebit.FinRecordID = TransactionIDs_.FinRecordID
		|		 AND DirectDebit.RegisterName = TransactionIDs_.CorRegisterName
		|		 AND DirectDebit.Organization = TransactionIDs_.Organization
		|		 AND CASE
		|			WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				AND TransactionIDs_.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				THEN DirectDebit.SettingUpBusinessTransaction = TransactionIDs_.SettingUpBusinessTransaction
		|			ELSE TRUE
		|		 END
		|		 AND DirectDebit.PropsStorno = TransactionIDs_.PropsStorno
		|GROUP BY
		|	DirectDebit.Period,
		|	DirectDebit.Recorder,
		|	DirectDebit.FinRecordID,
		|	DirectDebit.RegisterName,
		|	DirectDebit.Organization,
		|	DirectDebit.SettingUpBusinessTransaction,
		|	DirectDebit.PropsStorno
		|HAVING
		|	COUNT(DISTINCT DirectDebit.AccountingObject) > 1
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	MovementCredit.Period AS Period,
		|	MovementCredit.RegisterName AS RegisterName,
		|	MovementCredit.Organization AS Organization,
		|	MovementCredit.Recorder AS Recorder,
		|	MovementCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	MovementCredit.FinRecordID AS FinRecordID,
		|	MovementCredit.PropsStorno AS PropsStorno,
		|	COUNT(DISTINCT MovementCredit.AccountingObject) AS NumberOfAccountingObjects
		|FROM
		|	TTRolledUpMotionCredit AS MovementCredit
		|	INNER JOIN TTTransactionIDsDebit AS IdsOfDebitTransactions
		|		ON MovementCredit.Period = IdsOfDebitTransactions.Period
		|		 AND MovementCredit.Recorder = IdsOfDebitTransactions.Recorder
		|		 AND MovementCredit.FinRecordID = IdsOfDebitTransactions.FinRecordID
		|		 AND MovementCredit.RegisterName = IdsOfDebitTransactions.CorRegisterName
		|		 AND MovementCredit.Organization = IdsOfDebitTransactions.Organization
		|		 AND CASE
		|			WHEN MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				AND IdsOfDebitTransactions.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				THEN MovementCredit.SettingUpBusinessTransaction = IdsOfDebitTransactions.SettingUpBusinessTransaction
		|			ELSE TRUE
		|		 END
		|		 AND MovementCredit.PropsStorno = IdsOfDebitTransactions.PropsStorno
		|GROUP BY
		|	MovementCredit.Period,
		|	MovementCredit.Recorder,
		|	MovementCredit.FinRecordID,
		|	MovementCredit.RegisterName,
		|	MovementCredit.Organization,
		|	MovementCredit.SettingUpBusinessTransaction,
		|	MovementCredit.PropsStorno
		|HAVING
		|	COUNT(DISTINCT MovementCredit.AccountingObject) > 1
		|";
		
		Result = Query.Execute();
		HasComplexEntries = Not Result.IsEmpty();
	EndIf;
	
	If Not HasComplexEntries Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTTransactionIDsDebit");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTTransactionIDsCredit");
	EndIf;
	
	Query.Parameters.ComplexTransactionsWithIndicationOfCorSources = HasComplexEntries;
	
EndProcedure

Procedure AddDataSourceIDs(QueriesTexts, QueryOptions, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RecNo AS RecNo,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	RegisterRegisteredRecords_1.SumMan AS SumMan,
	|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno,
	|	&ThereAreCorDataSources AS ThereAreCorDataSources,
	|	&IDOfCorOfDataSources AS IDOfCorOfDataSources
	|INTO TTRegisteredRecordsDrCr
	|FROM
	|	TTFoldedRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	Organization,
	|	PropsStorno,
	|	IDOfCorOfDataSources
	|";
	
	If QueryOptions.ComplexTransactionsWithIndicationOfCorSources Then
		QueryText = StrReplace(QueryText,
			"TTFoldedRegisteredRecordsDrCr AS RegisterRegisteredRecords_1",
			"TTFoldedRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
			|	LEFT JOIN TTIdsOfCorDataSources AS IdsOfCorDataSources
			|		ON RegisterRegisteredRecords_1.AccountingObject = IdsOfCorDataSources.AccountingObject");
		
		QueryText = StrReplace(QueryText,
			"INTO TTRegisteredRecordsDrCr",
			"INTO TTRegisterRegisteredRecordsDrCr");
		
		QueryText = StrReplace(QueryText,
			"INDEX BY
			|	Period,
			|	Recorder,
			|	FinRecordID,",
			"INDEX BY
			|	Period,
			|	Recorder,
			|	FinRecordID,
			|	RegisterName,");
		
		ThereAreCorDataSources = "NOT IdsOfCorDataSources.Id IS NULL";
		IDOfCorOfDataSources = "ISNULL(IdsOfCorDataSources.Id, """")";
	Else
		ThereAreCorDataSources = "TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTIdsOfCorDataSources AS IdsOfCorDataSources
			|		WHERE
			|			IdsOfCorDataSources.AccountingObject = RegisterRegisteredRecords_1.AccountingObject
			|		)";
		IDOfCorOfDataSources = """""";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ThereAreCorDataSources", ThereAreCorDataSources);
	QueryText = StrReplace(QueryText, "&IDOfCorOfDataSources", IDOfCorOfDataSources);
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTFoldedRegisteredRecordsDrCr";
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	
	If QueryOptions.ComplexTransactionsWithIndicationOfCorSources Then
		QueryText = "
		|SELECT
		|	RegisterRegisteredRecords_1.Period AS Period,
		|	RegisterRegisteredRecords_1.RecNo AS RecNo,
		|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
		|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
		|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
		|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	RegisterRegisteredRecords_1.Organization AS Organization,
		|	RegisterRegisteredRecords_1.Recorder AS Recorder,
		|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
		|	RegisterRegisteredRecords_1.RowID AS RowID,
		|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
		|	RegisterRegisteredRecords_1.Currency AS Currency,
		|	RegisterRegisteredRecords_1.SumMan AS SumMan,
		|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
		|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
		|	RegisterRegisteredRecords_1.Count AS Count,
		|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno,
		|	RegisterRegisteredRecords_1.ThereAreCorDataSources AS ThereAreCorDataSources,
		|	CASE
		|		WHEN RegisterRegisteredRecords_1.IDOfCorOfDataSources <> """"
		|			THEN RegisterRegisteredRecords_1.IDOfCorOfDataSources
		|		ELSE ISNULL(CorTransactionIds.CorID, """")
		|	END AS IDOfCorOfDataSources
		|INTO TTRegisteredRecordsDrCr
		|FROM
		|	TTRegisterRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
		|	LEFT JOIN TTCtTransactionIdsDrCr AS CorTransactionIds
		|		ON RegisterRegisteredRecords_1.Period = CorTransactionIds.Period
		|		 AND RegisterRegisteredRecords_1.Recorder = CorTransactionIds.Recorder
		|		 AND RegisterRegisteredRecords_1.FinRecordID = CorTransactionIds.FinRecordID
		|		 AND RegisterRegisteredRecords_1.RegisterName = CorTransactionIds.CorRegisterName
		|		 AND RegisterRegisteredRecords_1.Organization = CorTransactionIds.Organization
		|		 AND CASE
		|			WHEN RegisterRegisteredRecords_1.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				AND CorTransactionIds.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				THEN RegisterRegisteredRecords_1.SettingUpBusinessTransaction = CorTransactionIds.SettingUpBusinessTransaction
		|			ELSE TRUE
		|		 END
		|		 AND RegisterRegisteredRecords_1.PropsStorno = CorTransactionIds.PropsStorno
		|INDEX BY
		|	Period,
		|	Recorder,
		|	FinRecordID,
		|	SettingUpBusinessTransaction,
		|	Organization,
		|	PropsStorno,
		|	IDOfCorOfDataSources
		|";
		
		FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
		QueriesTexts.Add(QueryText);
		
		MotionTableName = "TTRegisterRegisteredRecordsDrCr";
		FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
		
		MotionTableName = "TTCtTransactionIdsDrCr";
		FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	EndIf;
	
EndProcedure

Procedure AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.PropsStorno AS PropsStorno,
	|	RegisterRecords.IDOfCorOfDataSources AS IDOfCorOfDataSources,
	|	COUNT(RegisterRecords.FinRecordID) AS NumberOfFinRecords,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	MAX(RegisterRecords.SumMan = 0 AND RegisterRecords.SumCompl = 0) AS ThereIsZeroBalance
	|INTO TTResultsOfOperations
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.SettingUpBusinessTransaction,
	|	RegisterRecords.Organization,
	|	RegisterRecords.PropsStorno,
	|	RegisterRecords.IDOfCorOfDataSources
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	Organization,
	|	PropsStorno,
	|	IDOfCorOfDataSources
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.PropsStorno AS PropsStorno,
	|	COUNT(RegisterRecords.FinRecordID) AS NumberOfFinRecords,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	MAX(RegisterRecords.SumMan = 0 AND RegisterRecords.SumCompl = 0) AS ThereIsZeroBalance
	|INTO TTResultsForFinRecords
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|WHERE
	|	RegisterRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTMotionCorDrCr AS MotionCor
	|		WHERE
	|			MotionCor.Period = RegisterRecords.Period
	|			AND MotionCor.Recorder = RegisterRecords.Recorder
	|			AND MotionCor.FinRecordID = RegisterRecords.FinRecordID
	|			AND MotionCor.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND MotionCor.Organization = RegisterRecords.Organization
	|			AND MotionCor.PropsStorno = RegisterRecords.PropsStorno
	|			AND MotionCor.ThisIsCorDrCr
	|		)
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTMotionCorDrCr AS MotionCor
	|			LEFT JOIN TTCorDataSources AS CorDataSources
	|				ON CorDataSources.AccountingObject = RegisterRecords.AccountingObject
	|			LEFT JOIN TTCorDataSources AS DataSources
	|				ON DataSources.AccountingObject = MotionCor.AccountingObject
	|		WHERE
	|			MotionCor.Period = RegisterRecords.Period
	|			AND MotionCor.Recorder = RegisterRecords.Recorder
	|			AND MotionCor.FinRecordID = RegisterRecords.FinRecordID
	|			AND MotionCor.SettingUpBusinessTransaction = RegisterRecords.SettingUpBusinessTransaction
	|			AND MotionCor.Organization = RegisterRecords.Organization
	|			AND MotionCor.PropsStorno = RegisterRecords.PropsStorno
	|			AND MotionCor.ThisIsCorDrCr
	|			AND (MotionCor.AccountingObject <> RegisterRecords.AccountingObject OR MotionCor.ThisIsReverseTransaction = RegisterRecords.ThisIsReverseTransaction)
	|			AND CASE
	|				WHEN NOT DataSources.AccountingObject IS NULL
	|					THEN DataSources.CorRegisterName = RegisterRecords.RegisterName
	|				WHEN NOT CorDataSources.AccountingObject IS NULL
	|					THEN CorDataSources.CorRegisterName = MotionCor.RegisterName
	|				ELSE TRUE
	|			END
	|		)
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.Organization,
	|	RegisterRecords.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	PropsStorno
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RecNo AS RecNo,
	|	RegisterRecords.RegisterName AS RegisterName,
	|	RegisterRecords.AccountingObject AS AccountingObject,
	|	RegisterRecords.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowID AS RowID,
	|	RegisterRecords.VATActivityType AS VATActivityType,
	|	RegisterRecords.Currency AS Currency,
	|	RegisterRecords.SumMan AS SumMan,
	|	RegisterRecords.SumCompl AS SumCompl,
	|	RegisterRecords.SumCurr AS SumCurr,
	|	RegisterRecords.Count AS Count,
	|	RegisterRecords.PropsStorno AS PropsStorno,
	|	RegisterRecords.ThereAreCorDataSources AS ThereAreCorDataSources,
	|	ISNULL(ResultsForOperations.NumberOfFinRecords, 0) AS NumberOfOperationRecords,
	|	ISNULL(ResultsForOperations.SumMan, 0) AS TransactionManAmount,
	|	ISNULL(ResultsForOperations.SumCompl, 0) AS AmountOfLocalTransaction,
	|	ISNULL(ResultsForOperations.ThereIsZeroBalance, FALSE) AS ThereIsZeroBalanceOfOperation,
	|	ISNULL(ResultsForFinRecords.NumberOfFinRecords, 0) AS NumberOfEntriesFinEntries,
	|	ISNULL(ResultsForFinRecords.SumMan, 0) AS AmountOfManFinRecord,
	|	ISNULL(ResultsForFinRecords.SumCompl, 0) AS AmountOfLocalFinRecord,
	|	ISNULL(ResultsForFinRecords.ThereIsZeroBalance, FALSE) AS ThereIsZeroBalanceOfFinRecord,
	|	VALUETYPE(RegisterRecords.Recorder) AS TypeOfRegistrar
	|INTO TTRegisteredRecordsWithDrCrTotals
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|	LEFT JOIN TTResultsOfOperations AS ResultsForOperations
	|		ON RegisterRecords.Period = ResultsForOperations.Period
	|		 AND RegisterRecords.Recorder = ResultsForOperations.Recorder
	|		 AND RegisterRecords.FinRecordID = ResultsForOperations.FinRecordID
	|		 AND RegisterRecords.SettingUpBusinessTransaction = ResultsForOperations.SettingUpBusinessTransaction
	|		 AND RegisterRecords.Organization = ResultsForOperations.Organization
	|		 AND RegisterRecords.PropsStorno = ResultsForOperations.PropsStorno
	|		 AND RegisterRecords.IDOfCorOfDataSources = ResultsForOperations.IDOfCorOfDataSources
	|	LEFT JOIN TTResultsForFinRecords AS ResultsForFinRecords
	|		ON RegisterRecords.Period = ResultsForFinRecords.Period
	|		 AND RegisterRecords.Recorder = ResultsForFinRecords.Recorder
	|		 AND RegisterRecords.FinRecordID = ResultsForFinRecords.FinRecordID
	|		 AND RegisterRecords.Organization = ResultsForFinRecords.Organization
	|		 AND RegisterRecords.PropsStorno = ResultsForFinRecords.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno,
	|	AccountingObject
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTResultsOfOperations");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTResultsForFinRecords");
	
EndProcedure

Procedure ConnectRegisteredRecordsByKeyFields(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	ISNULL(DirectDebit.Period, MovementCredit.Period) AS Period,
	|	ISNULL(DirectDebit.RecNo, 0) AS RecNoDr,
	|	ISNULL(MovementCredit.RecNo, 0) AS RecNoCr,
	|	CASE
	|		WHEN NOT DirectDebit.RegisterName IS NULL
	|			THEN DirectDebit.RegisterName
	|		WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		ELSE """"
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN NOT MovementCredit.RegisterName IS NULL
	|			THEN MovementCredit.RegisterName
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		ELSE """"
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN NOT DirectDebit.AccountingObject IS NULL
	|			THEN DirectDebit.AccountingObject
	|		WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfDebtOffsetDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ARAPSettlements)
	|		WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|		  OR MovementCredit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RetailCustomerAccountsReceivables)
	|		WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN NOT MovementCredit.AccountingObject IS NULL
	|			THEN MovementCredit.AccountingObject
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfDebtOffsetDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ARAPSettlements)
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|		  OR DirectDebit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RetailCustomerAccountsReceivables)
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS AccountingObjectCr,
	|	ISNULL(DirectDebit.ThisIsReverseTransaction, FALSE) AS ThisIsReverseTransactionDr,
	|	ISNULL(MovementCredit.ThisIsReverseTransaction, FALSE) AS ThisIsReverseTransactionCr,
	|	CASE
	|		WHEN DirectDebit.Organization IS NULL
	|			THEN MovementCredit.Organization
	|		WHEN MovementCredit.Organization IS NULL
	|			THEN DirectDebit.Organization
	|		WHEN DirectDebit.Organization = VALUE(Catalog.Companies.EmptyRef)
	|			THEN MovementCredit.Organization
	|		ELSE DirectDebit.Organization
	|	END AS Organization,
	|	ISNULL(DirectDebit.Recorder, MovementCredit.Recorder) AS Recorder,
	|	CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction IS NULL
	|			THEN MovementCredit.SettingUpBusinessTransaction
	|		WHEN MovementCredit.SettingUpBusinessTransaction IS NULL
	|			THEN DirectDebit.SettingUpBusinessTransaction
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN MovementCredit.SettingUpBusinessTransaction
	|		ELSE DirectDebit.SettingUpBusinessTransaction
	|	END AS SettingUpBusinessTransaction,
	|	ISNULL(DirectDebit.FinRecordID, MovementCredit.FinRecordID) AS FinRecordID,
	|	ISNULL(DirectDebit.RowID, """") AS RowIDDr,
	|	ISNULL(MovementCredit.RowID, """") AS RowIDCr,
	|	ISNULL(DirectDebit.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityTypeDr,
	|	ISNULL(MovementCredit.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityTypeCr,
	|	ISNULL(DirectDebit.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyDr,
	|	ISNULL(MovementCredit.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyCr,
	|	ISNULL(DirectDebit.SumMan, 0) AS AmountOfManMovementDr,
	|	ISNULL(MovementCredit.SumMan, 0) AS AmountOfManMovementCr,
	|	ISNULL(DirectDebit.SumCompl, 0) AS AmountOfLocalTrafficDr,
	|	ISNULL(MovementCredit.SumCompl, 0) AS AmountOfLocalTrafficCr,
	|	ISNULL(DirectDebit.SumCurr, 0) AS AmountOfMovementShaftDr,
	|	ISNULL(MovementCredit.SumCurr, 0) AS AmountOfMovementCrShaft,
	|	ISNULL(DirectDebit.Count, 0) AS AmountOfDrMovement,
	|	ISNULL(MovementCredit.Count, 0) AS CrMotionCount,
	|	ISNULL(DirectDebit.PropsStorno, MovementCredit.PropsStorno) AS PropsStorno,
	|	CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN NOT ISNULL(MovementCredit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN FALSE
	|				WHEN ISNULL(DirectDebit.SumMan, 0) = ISNULL(MovementCredit.AmountOfManFinRecord, 0)
	|				  OR ISNULL(DirectDebit.SumCompl, 0) = ISNULL(MovementCredit.AmountOfLocalFinRecord, 0)
	|					THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|					  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|					  OR ISNULL(MovementCredit.ThereIsZeroBalanceOfFinRecord, FALSE)
	|				ELSE FALSE
	|			END
	|		WHEN NOT (ISNULL(DirectDebit.NumberOfOperationRecords, 0) = 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) > 1)
	|			THEN FALSE
	|		WHEN ISNULL(DirectDebit.TransactionManAmount, 0) = ISNULL(MovementCredit.TransactionManAmount, 0)
	|		  OR ISNULL(DirectDebit.AmountOfLocalTransaction, 0) = ISNULL(MovementCredit.AmountOfLocalTransaction, 0)
	|			THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|			  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|			  OR ISNULL(MovementCredit.ThereIsZeroBalanceOfOperation, FALSE)
	|		ELSE FALSE
	|	END AS ComplexEntryDr,
	|	CASE
	|		WHEN MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN NOT ISNULL(DirectDebit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN FALSE
	|				WHEN ISNULL(DirectDebit.AmountOfManFinRecord, 0) = ISNULL(MovementCredit.SumMan, 0)
	|				  OR ISNULL(DirectDebit.AmountOfLocalFinRecord, 0) = ISNULL(MovementCredit.SumCompl, 0)
	|					THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|					  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|					  OR ISNULL(DirectDebit.ThereIsZeroBalanceOfFinRecord, FALSE)
	|				ELSE FALSE
	|			END
	|		WHEN NOT (ISNULL(DirectDebit.NumberOfOperationRecords, 0) > 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) = 1)
	|			THEN FALSE
	|		WHEN ISNULL(DirectDebit.TransactionManAmount, 0) = ISNULL(MovementCredit.TransactionManAmount, 0)
	|		  OR ISNULL(DirectDebit.AmountOfLocalTransaction, 0) = ISNULL(MovementCredit.AmountOfLocalTransaction, 0)
	|			THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|			  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|			  OR ISNULL(DirectDebit.ThereIsZeroBalanceOfOperation, FALSE)
	|		ELSE FALSE
	|	END AS ComplexEntryCr,
	|	CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|		  OR MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS TakeIntoAccountBusinessTransaction,
	|	CASE
	|		WHEN DirectDebit.SumMan IS NULL
	|			THEN CASE
	|				WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN MovementCredit.SumMan
	|				ELSE 0
	|			END
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN DirectDebit.SumMan <> ISNULL(MovementCredit.AmountOfManFinRecord, 0)
	|					THEN DirectDebit.SumMan
	|				WHEN ISNULL(MovementCredit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(MovementCredit.SumMan, 0)
	|				ELSE DirectDebit.SumMan
	|			END
	|		WHEN DirectDebit.TransactionManAmount <> ISNULL(MovementCredit.TransactionManAmount, 0)
	|			THEN DirectDebit.SumMan
	|		WHEN DirectDebit.NumberOfOperationRecords = 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) > 1
	|			THEN ISNULL(MovementCredit.SumMan, 0)
	|		ELSE DirectDebit.SumMan
	|	END AS SumManDr,
	|	CASE
	|		WHEN MovementCredit.SumMan IS NULL
	|			THEN CASE
	|				WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN DirectDebit.SumMan
	|				ELSE 0
	|			END
	|		WHEN MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN ISNULL(DirectDebit.AmountOfManFinRecord, 0) <> MovementCredit.SumMan
	|					THEN MovementCredit.SumMan
	|				WHEN ISNULL(DirectDebit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(DirectDebit.SumMan, 0)
	|				ELSE MovementCredit.SumMan
	|			END
	|		WHEN ISNULL(DirectDebit.TransactionManAmount, 0) <> MovementCredit.TransactionManAmount
	|			THEN MovementCredit.SumMan
	|		WHEN ISNULL(DirectDebit.NumberOfOperationRecords, 0) > 1 AND MovementCredit.NumberOfOperationRecords = 1
	|			THEN ISNULL(DirectDebit.SumMan, 0)
	|		ELSE MovementCredit.SumMan
	|	END AS SumManCr,
	|	CASE
	|		WHEN DirectDebit.SumCompl IS NULL
	|			THEN CASE
	|				WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN MovementCredit.SumCompl
	|				ELSE 0
	|			END
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN DirectDebit.SumCompl <> ISNULL(MovementCredit.AmountOfLocalFinRecord, 0)
	|					THEN DirectDebit.SumCompl
	|				WHEN ISNULL(MovementCredit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(MovementCredit.SumCompl, 0)
	|				ELSE DirectDebit.SumCompl
	|			END
	|		WHEN DirectDebit.AmountOfLocalTransaction <> ISNULL(MovementCredit.AmountOfLocalTransaction, 0)
	|			THEN DirectDebit.SumCompl
	|		WHEN DirectDebit.NumberOfOperationRecords = 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) > 1
	|			THEN ISNULL(MovementCredit.SumCompl, 0)
	|		ELSE DirectDebit.SumCompl
	|	END AS SumComplDr,
	|	CASE
	|		WHEN MovementCredit.SumCompl IS NULL
	|			THEN CASE
	|				WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN DirectDebit.SumCompl
	|				ELSE 0
	|			END
	|		WHEN MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN ISNULL(DirectDebit.AmountOfLocalFinRecord, 0) <> MovementCredit.SumCompl
	|					THEN MovementCredit.SumCompl
	|				WHEN ISNULL(DirectDebit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(DirectDebit.SumCompl, 0)
	|				ELSE MovementCredit.SumCompl
	|			END
	|		WHEN ISNULL(DirectDebit.AmountOfLocalTransaction, 0) <> MovementCredit.AmountOfLocalTransaction
	|			THEN MovementCredit.SumCompl
	|		WHEN ISNULL(DirectDebit.NumberOfOperationRecords, 0) > 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) = 1
	|			THEN ISNULL(DirectDebit.SumCompl, 0)
	|		ELSE MovementCredit.SumCompl
	|	END AS SumComplCr
	|INTO TableOfCorrespondenceOfRegisteredRecordsOfRegisters
	|FROM
	|	TTRegisteredRecordsWithDebitTotals AS DirectDebit
	|	FULL JOIN TTRegisteredRecordsWithCreditTotals AS MovementCredit
	|	ON DirectDebit.Period = MovementCredit.Period
	|	 AND DirectDebit.Recorder = MovementCredit.Recorder
	|	 AND DirectDebit.FinRecordID = MovementCredit.FinRecordID
	|	 AND DirectDebit.Organization = MovementCredit.Organization
	|	 AND DirectDebit.PropsStorno = MovementCredit.PropsStorno
	|	 AND NOT DirectDebit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|	 AND NOT MovementCredit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|	 AND CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN DirectDebit.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	// correspondence of records with filled and empty XO settings is allowed if there are no other correspondence with the same XO for a record with filled XO
	|		WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|					LEFT JOIN TTCorDataSources AS CorDataSources
	|						ON CorDataSources.AccountingObject = DirectDebit.AccountingObject
	|					LEFT JOIN TTCorDataSources AS DataSources
	|						ON DataSources.AccountingObject = CreditOnlyRegisteredRecords.AccountingObject
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND (CreditOnlyRegisteredRecords.AccountingObject <> DirectDebit.AccountingObject OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|					AND CASE
	|						WHEN NOT DataSources.AccountingObject IS NULL
	|							THEN DataSources.CorRegisterName = DirectDebit.RegisterName
	|						WHEN NOT CorDataSources.AccountingObject IS NULL
	|							THEN CorDataSources.CorRegisterName = CreditOnlyRegisteredRecords.RegisterName
	|						ELSE TRUE
	|					END
	|				)
	// correspondence of records with filled and empty XO settings is allowed if there are no other correspondence with the same XO for a record with filled XO
	|		WHEN MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|					LEFT JOIN TTCorDataSources AS CorDataSources
	|						ON CorDataSources.AccountingObject = MovementCredit.AccountingObject
	|					LEFT JOIN TTCorDataSources AS DataSources
	|						ON DataSources.AccountingObject = DebitOnlyRegisteredRecords.AccountingObject
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND (DebitOnlyRegisteredRecords.AccountingObject <> MovementCredit.AccountingObject OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|					AND CASE
	|						WHEN NOT DataSources.AccountingObject IS NULL
	|							THEN DataSources.CorRegisterName = MovementCredit.RegisterName
	|						WHEN NOT CorDataSources.AccountingObject IS NULL
	|							THEN CorDataSources.CorRegisterName = DebitOnlyRegisteredRecords.RegisterName
	|						ELSE TRUE
	|					END
	|				)
	// correspondence of records with empty XO settings is prohibited if both form complex transactions with other records
	|		WHEN DirectDebit.NumberOfEntriesFinEntries > 1 AND MovementCredit.NumberOfEntriesFinEntries > 1
	|			THEN FALSE
	// correspondence of records with empty XO settings is prohibited if one forms complex transactions, and for the other there is correspondence with a filled XO setting
	|		WHEN DirectDebit.NumberOfEntriesFinEntries > 1
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND (DebitOnlyRegisteredRecords.AccountingObject <> MovementCredit.AccountingObject OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|				)
	// correspondence of records with empty XO settings is prohibited if one forms complex transactions, and for the other there is correspondence with a filled XO setting
	|		WHEN MovementCredit.NumberOfEntriesFinEntries > 1
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND (CreditOnlyRegisteredRecords.AccountingObject <> DirectDebit.AccountingObject OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|				)
	// correspondence of records with empty XO settings is prohibited if there are correspondences with filled XO settings for both
	|		ELSE NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDebit AS DebitOnlyRegisteredRecords
	|			WHERE
	|				DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|				AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|				AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|				AND DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|				AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|				AND DebitOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|				AND DebitOnlyRegisteredRecords.ThisIsDebit
	|				AND (DebitOnlyRegisteredRecords.AccountingObject <> MovementCredit.AccountingObject OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|			)
	|		AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTCredit AS CreditOnlyRegisteredRecords
	|			WHERE
	|				CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|				AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|				AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|				AND CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|				AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|				AND CreditOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|				AND CreditOnlyRegisteredRecords.ThisIsLoan
	|				AND (CreditOnlyRegisteredRecords.AccountingObject <> DirectDebit.AccountingObject OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|			)
	|	 END
	|	 AND CASE
	// correspondence of the records of the circulating registers with themselves is always prohibited
	|		WHEN NOT DirectDebit.ThisIsDebit AND NOT MovementCredit.ThisIsLoan
	|			THEN FALSE
	// correspondence records are limited in the description of the debit accounting object
	|		WHEN DirectDebit.ThereAreCorDataSources
	|			THEN TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCorDataSources AS CorDataSources
	|				WHERE
	|					CorDataSources.AccountingObject = DirectDebit.AccountingObject
	|					AND CorDataSources.CorRegisterName = MovementCredit.RegisterName
	|				)
	// correspondence records are limited in the description of the object of credit accounting
	|		WHEN MovementCredit.ThereAreCorDataSources
	|			THEN TRUE IN 
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCorDataSources AS CorDataSources
	|				WHERE
	|					CorDataSources.AccountingObject = MovementCredit.AccountingObject
	|					AND CorDataSources.CorRegisterName = DirectDebit.RegisterName
	|				)
	// this is part of the correct complex correspondence "one to many" by debit
	|		WHEN DirectDebit.NumberOfOperationRecords = 1 AND MovementCredit.NumberOfOperationRecords > 1
	|			AND DirectDebit.TransactionManAmount = MovementCredit.TransactionManAmount
	|			AND DirectDebit.AmountOfLocalTransaction = MovementCredit.AmountOfLocalTransaction
	|			THEN TRUE
	// this is part of the correct complex many-to-one correspondence on the loan
	|		WHEN DirectDebit.NumberOfOperationRecords > 1 AND MovementCredit.NumberOfOperationRecords = 1
	|			AND DirectDebit.TransactionManAmount = MovementCredit.TransactionManAmount
	|			AND DirectDebit.AmountOfLocalTransaction = MovementCredit.AmountOfLocalTransaction
	|			THEN TRUE
	// correspondence of direct and reverse entries within the same register is allowed if there are no correspondence with other objects or the same sign of reverse and the amounts of upr and regl for the reverse
	|		WHEN DirectDebit.AccountingObject = MovementCredit.AccountingObject AND DirectDebit.ThisIsReverseTransaction AND NOT MovementCredit.ThisIsReverseTransaction
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND CASE
	|						WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND ((CreditOnlyRegisteredRecords.AccountingObject <> DirectDebit.AccountingObject
	|						OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|						OR
	|						(CreditOnlyRegisteredRecords.AccountingObject = DirectDebit.AccountingObject
	|						AND CreditOnlyRegisteredRecords.ThisIsReverseTransaction <> DirectDebit.ThisIsReverseTransaction
	|						AND CreditOnlyRegisteredRecords.SumMan = DirectDebit.SumMan
	|						AND CreditOnlyRegisteredRecords.SumCompl = DirectDebit.SumCompl
	|						AND CreditOnlyRegisteredRecords.SumMan <> MovementCredit.SumMan
	|						AND CreditOnlyRegisteredRecords.SumCompl <> MovementCredit.SumCompl)
	|					)
	|				)
	// correspondence of direct and reverse entries within the same register is allowed if there are no correspondence with other objects or the same sign of reverse and the amounts of upr and regl for the reverse
	|		WHEN DirectDebit.AccountingObject = MovementCredit.AccountingObject AND NOT DirectDebit.ThisIsReverseTransaction AND MovementCredit.ThisIsReverseTransaction
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND CASE
	|						WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND ((DebitOnlyRegisteredRecords.AccountingObject <> MovementCredit.AccountingObject
	|						OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|						OR
	|						(DebitOnlyRegisteredRecords.AccountingObject = MovementCredit.AccountingObject
	|						AND DebitOnlyRegisteredRecords.ThisIsReverseTransaction <> MovementCredit.ThisIsReverseTransaction
	|						AND DebitOnlyRegisteredRecords.SumMan = MovementCredit.SumMan
	|						AND DebitOnlyRegisteredRecords.SumCompl = MovementCredit.SumCompl
	|						AND DebitOnlyRegisteredRecords.SumMan <> DirectDebit.SumMan
	|						AND DebitOnlyRegisteredRecords.SumCompl <> DirectDebit.SumCompl)
	|					)
	|				)
	// correspondence of records within the same register has priority for records with the same accounting objects and amounts of upr and regl
	|		WHEN DirectDebit.RegisterName = MovementCredit.RegisterName AND DirectDebit.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND CASE
	|						WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND CreditOnlyRegisteredRecords.AccountingObject = DirectDebit.AccountingObject
	|					AND CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction
	|					AND CreditOnlyRegisteredRecords.SumMan = DirectDebit.SumMan
	|					AND CreditOnlyRegisteredRecords.SumCompl = DirectDebit.SumCompl
	|					AND (CreditOnlyRegisteredRecords.AccountingObject <> MovementCredit.AccountingObject
	|						OR
	|						(CreditOnlyRegisteredRecords.AccountingObject = MovementCredit.AccountingObject
	|						AND CreditOnlyRegisteredRecords.SumMan <> MovementCredit.SumMan
	|						AND CreditOnlyRegisteredRecords.SumCompl <> MovementCredit.SumCompl)
	|					AND NOT (MovementCredit.SumMan = 0 AND MovementCredit.SumCompl = 0)
	|					)
	|				)
	|			AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND CASE
	|						WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND DebitOnlyRegisteredRecords.AccountingObject = MovementCredit.AccountingObject
	|					AND DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction
	|					AND DebitOnlyRegisteredRecords.SumMan = MovementCredit.SumMan
	|					AND DebitOnlyRegisteredRecords.SumCompl = MovementCredit.SumCompl
	|					AND (DebitOnlyRegisteredRecords.AccountingObject <> DirectDebit.AccountingObject
	|						OR
	|						(DebitOnlyRegisteredRecords.AccountingObject = DirectDebit.AccountingObject
	|						AND DebitOnlyRegisteredRecords.SumMan <> DirectDebit.SumMan
	|						AND DebitOnlyRegisteredRecords.SumCompl <> DirectDebit.SumCompl)
	|					)
	|					AND NOT (DirectDebit.SumMan = 0 AND DirectDebit.SumCompl = 0)
	|				)
	// other cases of many-to-many relationships, priority for records with the same amounts of upr and regl
	|		WHEN DirectDebit.NumberOfOperationRecords > 1 AND MovementCredit.NumberOfOperationRecords > 1
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND CASE
	|						WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND CreditOnlyRegisteredRecords.SumMan = DirectDebit.SumMan
	|					AND CreditOnlyRegisteredRecords.SumCompl = DirectDebit.SumCompl
	|					AND CreditOnlyRegisteredRecords.SumMan <> MovementCredit.SumMan
	|					AND CreditOnlyRegisteredRecords.SumCompl <> MovementCredit.SumCompl
	|				)
	|			AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND CASE
	|						WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND DebitOnlyRegisteredRecords.SumMan = MovementCredit.SumMan
	|					AND DebitOnlyRegisteredRecords.SumCompl = MovementCredit.SumCompl
	|					AND DebitOnlyRegisteredRecords.SumMan <> DirectDebit.SumMan
	|					AND DebitOnlyRegisteredRecords.SumCompl <> DirectDebit.SumCompl
	|				)
	|		ELSE TRUE
	|	 END
	|WHERE
	|	CASE
	|		WHEN DirectDebit.Recorder IS NULL
	|			THEN CASE
	// we do not output a record with zero balance resources
	|				WHEN MovementCredit.SumMan = 0 AND MovementCredit.SumCompl = 0
	|					THEN FALSE
	// the record of the residual register is always output
	|				WHEN MovementCredit.ThisIsLoan
	|					THEN TRUE
	// we do not output the reverse register entry if there is correspondence with another expenditure movement for it
	|				ELSE NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						TTCredit AS CreditOnlyRegisteredRecords
	|						LEFT JOIN TTCorDataSources AS CorDataSources
	|							ON CreditOnlyRegisteredRecords.RegisterName = CorDataSources.CorRegisterName
	|							 AND MovementCredit.ThereAreCorDataSources
	|					WHERE
	|						CreditOnlyRegisteredRecords.Period = MovementCredit.Period
	|						AND CreditOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|						AND CreditOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|						AND CreditOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|						AND CreditOnlyRegisteredRecords.PropsStorno = MovementCredit.PropsStorno
	|						AND CreditOnlyRegisteredRecords.ThisIsLoan
	|						AND CASE
	|							WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|							ELSE TRUE
	|						END
	|						AND CASE
	|							WHEN NOT CorDataSources.AccountingObject IS NULL
	|								THEN CorDataSources.AccountingObject = MovementCredit.AccountingObject
	|							ELSE NOT MovementCredit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|						END
	|					)
	|					AND NOT MovementCredit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|			END
	|		WHEN MovementCredit.Recorder IS NULL
	|			THEN CASE
	// we do not output a record with zero balance resources
	|				WHEN DirectDebit.SumMan = 0 AND DirectDebit.SumCompl = 0
	|					THEN FALSE
	// the record of the residual register is always output
	|				WHEN DirectDebit.ThisIsDebit
	|					THEN TRUE
	// we do not output the reverse register entry if there is correspondence with another incoming movement for it
	|				ELSE NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						TTDebit AS DebitOnlyRegisteredRecords
	|						LEFT JOIN TTCorDataSources AS CorDataSources
	|							ON DebitOnlyRegisteredRecords.RegisterName = CorDataSources.CorRegisterName
	|							 AND DirectDebit.ThereAreCorDataSources
	|					WHERE
	|						DebitOnlyRegisteredRecords.Period = DirectDebit.Period
	|						AND DebitOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|						AND DebitOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|						AND DebitOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|						AND DebitOnlyRegisteredRecords.PropsStorno = DirectDebit.PropsStorno
	|						AND DebitOnlyRegisteredRecords.ThisIsDebit
	|						AND CASE
	|							WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|							ELSE TRUE
	|						END
	|						AND CASE
	|							WHEN NOT CorDataSources.AccountingObject IS NULL
	|								THEN CorDataSources.AccountingObject = DirectDebit.AccountingObject
	|							ELSE NOT DirectDebit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|						END
	|					)
	|					AND NOT DirectDebit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|			END
	|		ELSE TRUE
	|	END
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	ThisIsReverseTransactionDr,
	|	ThisIsReverseTransactionCr
	|";
	
	TableOfCorrespondenceOfRegisteredRecordsOfRegisters = Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
	
	If Query.TempTablesManager.Tables.Find(TableOfCorrespondenceOfRegisteredRecordsOfRegisters) <> Undefined Then
		TableOfCorrespondenceOfRegisteredRecordsOfRegisters = TableOfCorrespondenceOfRegisteredRecordsOfRegisters + "1";
		Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters = TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
	EndIf;
	
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

#Region TextsOfRequestsForErrorCorrectionOfCorrespondenceWithReverse

Procedure IdentifyCorrespondenceErrors(QueriesTexts, QueryOptions, ReverseErrors = False)
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno
	|INTO TTCorrespondenceErrors
	|FROM
	|	TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|WHERE
	|	(RegisteredRecordsDebitCredit.RegisterNameDr = """"
	|		OR RegisteredRecordsDebitCredit.RegisterNameCr = """"
	|		OR (RegisteredRecordsDebitCredit.SumManDr <> RegisteredRecordsDebitCredit.SumManCr
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutManSum)
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutManSum))
	|		OR (RegisteredRecordsDebitCredit.SumComplDr <> RegisteredRecordsDebitCredit.SumComplCr
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutSumLocal)
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutSumLocal)))
	|	AND RegisteredRecordsDebitCredit.FinRecordID <> """"
	|	AND &TheseAreReverseRegisteredRecords
	|GROUP BY
	|	RegisteredRecordsDebitCredit.Period,
	|	RegisteredRecordsDebitCredit.Recorder,
	|	RegisteredRecordsDebitCredit.FinRecordID,
	|	RegisteredRecordsDebitCredit.Organization,
	|	RegisteredRecordsDebitCredit.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	PropsStorno
	|";
	
	If ReverseErrors Then
		TheseAreReverseRegisteredRecords = "TRUE IN 
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS ReverseRegisteredRecords
		|		WHERE
		|			ReverseRegisteredRecords.Period = RegisteredRecordsDebitCredit.Period
		|			AND ReverseRegisteredRecords.Recorder = RegisteredRecordsDebitCredit.Recorder
		|			AND ReverseRegisteredRecords.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
		|			AND ReverseRegisteredRecords.Organization = RegisteredRecordsDebitCredit.Organization
		|			AND ReverseRegisteredRecords.PropsStorno = RegisteredRecordsDebitCredit.PropsStorno
		|			AND (ReverseRegisteredRecords.ThisIsReverseTransactionDr OR ReverseRegisteredRecords.ThisIsReverseTransactionCr)
		|		)";
	Else
		TheseAreReverseRegisteredRecords = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TheseAreReverseRegisteredRecords", TheseAreReverseRegisteredRecords);
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", QueryOptions.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure DetermineMaximumNumberOfMovementRecords(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	MAX(MaximumRecordNumbers.RecNo) AS RecNo
	|INTO TTMaximumNumberOfEntries
	|FROM
	|	(SELECT
	|		MAX(DirectDebit.RecNo) AS RecNo
	|	FROM
	|		TTDebit AS DirectDebit
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MAX(MovementCredit.RecNo) AS RecNo
	|	FROM
	|		TTCredit AS MovementCredit
	|	) AS MaximumRecordNumbers
	|");
	
EndProcedure

Procedure RestoreRegisteredRecordsOfErroneousCorrespondence(QueriesTexts, QueryOptions, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterName AS RegisterName,
	|	RegisterRecords.AccountingObject AS AccountingObject,
	|	RegisterRecords.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowID AS RowID,
	|	RegisterRecords.VATActivityType AS VATActivityType,
	|	RegisterRecords.Currency AS Currency,
	|	RegisterRecords.SumMan AS SumMan,
	|	RegisterRecords.SumCompl AS SumCompl,
	|	RegisterRecords.SumCurr AS SumCurr,
	|	RegisterRecords.Count AS Count,
	|	RegisterRecords.PropsStorno AS PropsStorno
	|INTO TTMovementRegistersReverseDrCr
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTCorrespondenceErrors AS CorrespondencesErrors
	|		WHERE
	|			CorrespondencesErrors.Period = RegisterRecords.Period
	|			AND CorrespondencesErrors.Recorder = RegisterRecords.Recorder
	|			AND CorrespondencesErrors.FinRecordID = RegisterRecords.FinRecordID
	|			AND CorrespondencesErrors.Organization = RegisterRecords.Organization
	|			AND CorrespondencesErrors.PropsStorno = RegisterRecords.PropsStorno
	|		)
	|INDEX BY
	|	ThisIsReverseTransaction
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTRegisteredRecordsDrCr";
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	
EndProcedure

Procedure IdentifyRegistersWithReverseRegisteredRecords(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	MovementReverseDr.Period AS Period,
	|	MovementReverseDr.RegisterName AS RegisterName,
	|	MovementReverseDr.Organization AS Organization,
	|	MovementReverseDr.Recorder AS Recorder,
	|	MovementReverseDr.FinRecordID AS FinRecordID,
	|	MovementReverseDr.PropsStorno AS PropsStorno
	|INTO TTRegistersWithReverseRegisteredRecords
	|FROM
	|	TTRegisterRegisteredRecordsReverseDebit AS MovementReverseDr
	|WHERE
	|	MovementReverseDr.ThisIsReverseTransaction
	|
	|UNION
	|
	|SELECT DISTINCT
	|	MovementReverseCr.Period AS Period,
	|	MovementReverseCr.RegisterName AS RegisterName,
	|	MovementReverseCr.Organization AS Organization,
	|	MovementReverseCr.Recorder AS Recorder,
	|	MovementReverseCr.FinRecordID AS FinRecordID,
	|	MovementReverseCr.PropsStorno AS PropsStorno
	|FROM
	|	TTMovementRegistersReverseCredit AS MovementReverseCr
	|WHERE
	|	MovementReverseCr.ThisIsReverseTransaction
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	PropsStorno
	|");
	
EndProcedure

Procedure ReplaceReverseMovementWithReverse(QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	MovementReverse.Period AS Period,
	|	MovementReverse.RegisterName AS RegisterName,
	|	MovementReverse.AccountingObject AS AccountingObject,
	|	MovementReverse.ThisIsDrCr AS ThisIsDrCr,
	|	MovementReverse.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	MovementReverse.Organization AS Organization,
	|	MovementReverse.Recorder AS Recorder,
	|	MovementReverse.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementReverse.FinRecordID AS FinRecordID,
	|	MovementReverse.RowID AS RowID,
	|	MovementReverse.VATActivityType AS VATActivityType,
	|	MovementReverse.Currency AS Currency,
	|	MovementReverse.SumMan AS SumMan,
	|	MovementReverse.SumCompl AS SumCompl,
	|	MovementReverse.SumCurr AS SumCurr,
	|	MovementReverse.Count AS Count,
	|	MovementReverse.PropsStorno AS PropsStorno
	|INTO TTMovementOfRegistersIsReversed
	|FROM
	|	TTMovementRegistersReverseDrCr AS MovementReverse
	|WHERE
	|	NOT MovementReverse.ThisIsReverseTransaction
	|
	|UNION ALL
	|
	|SELECT
	|	MovementReverse.Period AS Period,
	|	MovementReverse.RegisterName AS RegisterName,
	|	MovementReverse.AccountingObject AS AccountingObject,
	|	MovementReverse.ThisIsCorDrCr AS ThisIsDrCr,
	|	NOT MovementReverse.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	MovementReverse.Organization AS Organization,
	|	MovementReverse.Recorder AS Recorder,
	|	MovementReverse.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementReverse.FinRecordID AS FinRecordID,
	|	MovementReverse.RowID AS RowID,
	|	MovementReverse.VATActivityType AS VATActivityType,
	|	MovementReverse.Currency AS Currency,
	|	- MovementReverse.SumMan AS SumMan,
	|	- MovementReverse.SumCompl AS SumCompl,
	|	- MovementReverse.SumCurr AS SumCurr,
	|	- MovementReverse.Count AS Count,
	|	MovementReverse.PropsStorno AS PropsStorno
	|FROM
	|	TTCorMovementRegistersReverseDrCr AS MovementReverse
	|WHERE
	|	MovementReverse.ThisIsReverseTransaction
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisteredRecordsAreReversed.Period AS Period,
	|	RegisteredRecordsAreReversed.RegisterName AS RegisterName,
	|	RegisteredRecordsAreReversed.AccountingObject AS AccountingObject,
	|	RegisteredRecordsAreReversed.ThisIsDrCr AS ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization AS Organization,
	|	RegisteredRecordsAreReversed.Recorder AS Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.FinRecordID AS FinRecordID,
	|	RegisteredRecordsAreReversed.RowID AS RowID,
	|	RegisteredRecordsAreReversed.VATActivityType AS VATActivityType,
	|	RegisteredRecordsAreReversed.Currency AS Currency,
	|	SUM(RegisteredRecordsAreReversed.SumMan) AS SumMan,
	|	SUM(RegisteredRecordsAreReversed.SumCompl) AS SumCompl,
	|	SUM(RegisteredRecordsAreReversed.SumCurr) AS SumCurr,
	|	SUM(RegisteredRecordsAreReversed.Count) AS Count,
	|	RegisteredRecordsAreReversed.PropsStorno AS PropsStorno
	|INTO TTRolledUpRegisteredRecordsAreReversed
	|FROM
	|	TTMovementOfRegistersIsReversed AS RegisteredRecordsAreReversed
	|GROUP BY
	|	RegisteredRecordsAreReversed.Period,
	|	RegisteredRecordsAreReversed.RegisterName,
	|	RegisteredRecordsAreReversed.AccountingObject,
	|	RegisteredRecordsAreReversed.ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization,
	|	RegisteredRecordsAreReversed.Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.FinRecordID,
	|	RegisteredRecordsAreReversed.RowID,
	|	RegisteredRecordsAreReversed.VATActivityType,
	|	RegisteredRecordsAreReversed.Currency,
	|	RegisteredRecordsAreReversed.PropsStorno
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementOfRegistersIsReversed");
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsAreReversed.RecNo + MaximumNumberOfRecords.RecNo AS RecNo,
	|	RegisteredRecordsAreReversed.Period AS Period,
	|	RegisteredRecordsAreReversed.RegisterName AS RegisterName,
	|	RegisteredRecordsAreReversed.AccountingObject AS AccountingObject,
	|	RegisteredRecordsAreReversed.ThisIsDrCr AS ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization AS Organization,
	|	RegisteredRecordsAreReversed.Recorder AS Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.FinRecordID AS FinRecordID,
	|	RegisteredRecordsAreReversed.RowID AS RowID,
	|	RegisteredRecordsAreReversed.VATActivityType AS VATActivityType,
	|	RegisteredRecordsAreReversed.Currency AS Currency,
	|	RegisteredRecordsAreReversed.SumMan AS SumMan,
	|	RegisteredRecordsAreReversed.SumCompl AS SumCompl,
	|	RegisteredRecordsAreReversed.SumCurr AS SumCurr,
	|	RegisteredRecordsAreReversed.Count AS Count,
	|	RegisteredRecordsAreReversed.PropsStorno AS PropsStorno
	|INTO TTFoldedRegisteredRecordsDrCr
	|FROM
	|	TTRolledUpRegisteredRecordsAreReversed AS RegisteredRecordsAreReversed
	|	,
	|	TTMaximumNumberOfEntries AS MaximumNumberOfRecords
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	PropsStorno
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRolledUpRegisteredRecordsAreReversed");
	
EndProcedure

Procedure IdentifyCorrespondenceWithoutErrors(QueriesTexts, QueryOptions)
	
	IdentifyCorrespondenceErrors(QueriesTexts, QueryOptions);
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr
	|INTO TTCorrespondenceWithoutErrors
	|FROM
	|	TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTCorrespondenceErrors AS CorrespondencesErrors
	|		WHERE
	|			CorrespondencesErrors.Period = RegisteredRecordsDebitCredit.Period
	|			AND CorrespondencesErrors.Recorder = RegisteredRecordsDebitCredit.Recorder
	|			AND CorrespondencesErrors.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|			AND CorrespondencesErrors.Organization = RegisteredRecordsDebitCredit.Organization
	|			AND CorrespondencesErrors.PropsStorno = RegisteredRecordsDebitCredit.PropsStorno
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", QueryOptions.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, QueryOptions.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
EndProcedure

Procedure DetermineReverseToReverseReplacementRegisters(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondenceWithoutErrors.Period AS Period,
	|	CorrespondenceWithoutErrors.Organization AS Organization,
	|	CorrespondenceWithoutErrors.Recorder AS Recorder,
	|	CorrespondenceWithoutErrors.FinRecordID AS FinRecordID,
	|	CorrespondenceWithoutErrors.PropsStorno AS PropsStorno
	|INTO TTDocumentsReplacingReverseWithReverse
	|FROM
	|	TTCorrespondenceWithoutErrors AS CorrespondenceWithoutErrors
	|GROUP BY
	|	CorrespondenceWithoutErrors.Period,
	|	CorrespondenceWithoutErrors.Recorder,
	|	CorrespondenceWithoutErrors.FinRecordID,
	|	CorrespondenceWithoutErrors.Organization,
	|	CorrespondenceWithoutErrors.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	PropsStorno
	|");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	ReverseRegisters.RegisterName AS RegisterName
	|INTO TTReverseToReverseReplacementRegisters
	|FROM
	|	TTRegistersWithReverseRegisteredRecords AS ReverseRegisters
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|		WHERE
	|			ReverseReplacementDocuments.Period = ReverseRegisters.Period
	|			AND ReverseReplacementDocuments.Recorder = ReverseRegisters.Recorder
	|			AND ReverseReplacementDocuments.FinRecordID = ReverseRegisters.FinRecordID
	|			AND ReverseReplacementDocuments.Organization = ReverseRegisters.Organization
	|			AND ReverseReplacementDocuments.PropsStorno = ReverseRegisters.PropsStorno
	|		)
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegistersWithReverseRegisteredRecords");
	
EndProcedure

Procedure ReplaceCorrespondenceReverseWithReverse(QueriesTexts,
	CreatedTableOfCorrespondenceRegisteredRecords, DeletedTableOfCorrespondenceRegisteredRecords)
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsDebitCredit.PropsStorno AS PropsStorno,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr
	|INTO CreatedTableOfCorrespondenceRegisteredRecords
	|FROM
	|	DeletedTableOfCorrespondenceRegisteredRecords AS RegisteredRecordsDebitCredit
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|		WHERE
	|			ReverseReplacementDocuments.Period = RegisteredRecordsDebitCredit.Period
	|			AND ReverseReplacementDocuments.Recorder = RegisteredRecordsDebitCredit.Recorder
	|			AND ReverseReplacementDocuments.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|			AND ReverseReplacementDocuments.Organization = RegisteredRecordsDebitCredit.Organization
	|			AND ReverseReplacementDocuments.PropsStorno = RegisteredRecordsDebitCredit.PropsStorno
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	RegisteredRecordsWithoutErrors.Period AS Period,
	|	RegisteredRecordsWithoutErrors.RecNoDr AS RecNoDr,
	|	RegisteredRecordsWithoutErrors.RecNoCr AS RecNoCr,
	|	RegisteredRecordsWithoutErrors.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithoutErrors.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithoutErrors.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithoutErrors.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithoutErrors.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithoutErrors.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithoutErrors.Organization AS Organization,
	|	RegisteredRecordsWithoutErrors.Recorder AS Recorder,
	|	RegisteredRecordsWithoutErrors.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithoutErrors.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithoutErrors.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithoutErrors.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithoutErrors.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsWithoutErrors.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsWithoutErrors.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithoutErrors.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithoutErrors.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithoutErrors.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithoutErrors.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithoutErrors.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithoutErrors.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsWithoutErrors.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsWithoutErrors.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsWithoutErrors.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsWithoutErrors.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithoutErrors.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithoutErrors.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithoutErrors.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithoutErrors.SumManDr AS SumManDr,
	|	RegisteredRecordsWithoutErrors.SumManCr AS SumManCr,
	|	RegisteredRecordsWithoutErrors.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithoutErrors.SumComplCr AS SumComplCr
	|FROM
	|	TTCorrespondenceWithoutErrors AS RegisteredRecordsWithoutErrors
	|";
	
	QueryText = StrReplace(QueryText, "CreatedTableOfCorrespondenceRegisteredRecords", CreatedTableOfCorrespondenceRegisteredRecords);
	QueryText = StrReplace(QueryText, "DeletedTableOfCorrespondenceRegisteredRecords", DeletedTableOfCorrespondenceRegisteredRecords);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTableOfCorrespondenceRegisteredRecords);
	
EndProcedure

Procedure AddEmptyTableOfReverseReplacementDocuments(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	DATETIME(0001, 01, 01) AS Period,
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	CAST("""" AS STRING(36)) AS FinRecordID,
	|	UNDEFINED AS Recorder,
	|	FALSE AS PropsStorno
	|INTO TTDocumentsReplacingReverseWithReverse
	|WHERE
	|	FALSE
	|");
	
EndProcedure

#EndRegion

#Region TextsOfRequestsToRestorePaymentsForStorno

Procedure RestoreCalculationsForStorno(Query, QueriesTexts)
	
	QueryText = "
	|SELECT TOP 0
	|	DocumentsRegistry.Organization AS Organization,
	|	DocumentsRegistry.Ref AS DocumentReversingEntry,
	|	DocumentsRegistry.IBDocumentDate AS Period,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument
	|INTO TTRegisterOfDocumentsStorno
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	INNER JOIN TTPortionOfDocuments AS PortionOfDocuments
	|		ON DocumentsRegistry.Ref = PortionOfDocuments.Recorder
	|WHERE
	|	DocumentsRegistry.Posted
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND &FilterConditions
	|INDEX BY
	|	DocumentReversingEntry,
	|	ReversedDocument
	|";
	
	If Query.Parameters.RestoreCalculationsForStorno Then
		QueryText = StrReplace(QueryText, "TOP 0", "");
	EndIf;
	
	SelectionConditionsStrings = New Array();
	
	If Query.Parameters.StartDate > '00010101' Then
		SelectionConditionsStrings.Add("DocumentsRegistry.IBDocumentDate >= &StartDate");
	EndIf;
	
	If Query.Parameters.EndDate > '00010101' Then
		SelectionConditionsStrings.Add("DocumentsRegistry.IBDocumentDate <= &EndDate");
	EndIf;
	
	If TypeOf(Query.Parameters.Recorder) = Type("Array") Then
		SelectionConditionsStrings.Add("DocumentsRegistry.Ref IN (&Recorder)");
	ElsIf ValueIsFilled(Query.Parameters.Recorder) Then
		SelectionConditionsStrings.Add("DocumentsRegistry.Ref = &Recorder");
	EndIf;
	
	If SelectionConditionsStrings.Count() > 0 Then
		LineSplitter = Chars.LF + Chars.Tab + "And ";
		TextOfSelectionConditions = StrConcat(SelectionConditionsStrings, LineSplitter);
	Else
		TextOfSelectionConditions = "TRUE";
	EndIf;
		
	QueryText = StrReplace(QueryText, "&FilterConditions", TextOfSelectionConditions);
	
	QueriesTexts.Add(QueryText);
	
	#Region ReversePrepaymentFromCustomer
	
	QueryText = "
	|SELECT
	|	RegisterData.Period AS Period,
	|	""CustomersARAPAccountingByDueDates"" AS RegisterName,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable) AS AccountingObjectDr,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers) AS AccountingObjectCr,
	|	FALSE AS ThisIsReverseTransaction,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer) AS SettingUpBusinessTransaction,
	|	"""" AS FinRecordID,
	|	"""" AS RowID,
	|	FALSE AS PropsStorno,
	|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.Recorder AS ARAPDocument,
	|	RegisterData.Currency AS Currency,
	|	&OtherSelectionFields,
	|	SUM(RegisterData.ARAPMan) AS SumManDr,
	|	SUM(RegisterData.PrepaymentMan) AS SumManCr,
	|	SUM(RegisterData.DebtLocal) AS SumComplDr,
	|	SUM(RegisterData.PrepaymentLocal) AS SumComplCr,
	|	SUM(RegisterData.Debt) AS SumCurrDr,
	|	SUM(RegisterData.Prepayment) AS SumCurrCr
	|INTO TTSettlementsWithCustomersOnStorno
	|FROM
	|	(SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CustomersARAPAccountingByDueDates.Currency AS Currency,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.Debt 
	|			ELSE CustomersARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.DebtLocal 
	|			ELSE CustomersARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.ARAPMan 
	|			ELSE CustomersARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.Prepayment 
	|			ELSE CustomersARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON CustomersARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.ReversedDocument
	|		 AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		NOT CustomersARAPAccountingByDueDates.ReversingEntry
	|		AND &OrganizationSelectionCriteria
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CustomersARAPAccountingByDueDates.Currency AS Currency,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.Debt 
	|			ELSE CustomersARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.DebtLocal 
	|			ELSE CustomersARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.ARAPMan 
	|			ELSE CustomersARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.Prepayment 
	|			ELSE CustomersARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON CustomersARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.DocumentReversingEntry
	|		 AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		CustomersARAPAccountingByDueDates.ReversingEntry
	|		AND &OrganizationSelectionCriteria
	|	) AS RegisterData
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.Currency
	|HAVING
	|	SUM(RegisterData.Debt) <> 0 OR SUM(RegisterData.Prepayment) <> 0
	|	OR SUM(RegisterData.ARAPMan) <> 0 OR SUM(RegisterData.PrepaymentMan) <> 0
	|	OR SUM(RegisterData.DebtLocal) <> 0 OR SUM(RegisterData.PrepaymentLocal) <> 0
	|";
	
	If TypeOf(Query.Parameters.Organization) = Type("Array") Then
		OrganizationSelectionCriteria = "CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization IN (&Organization)";
	ElsIf ValueIsFilled(Query.Parameters.Organization) Then
		OrganizationSelectionCriteria = "CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = &Organization";
	Else
		OrganizationSelectionCriteria = "TRUE";
	EndIf;
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("AccountingDimensionByPartners");
	ExistingSelectionFields.Add("ARAPObject");
	ExistingSelectionFields.Add("Currency");
	ExistingSelectionFields.Add("ARAPDocument");
	ExistingSelectionFields.Add("Recorder");
	ExistingSelectionFields.Add("FinRecordID");
	ExistingSelectionFields.Add("BusinessTransactionSetting");
	ExistingSelectionFields.Add("ReversingEntry");
	
	AvailableOtherFields = New Array();
	AllRegisterFields = FinancialAccountingByBalanceSheetRegisterData.AvailableDataSourceFields(
		DescriptionOfFinancialRegisterFields(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name));
	
	TextOfSelectionOfOtherFields = FinancialAccountingByBalanceSheetRegisterData.FieldSelectionText(
		AvailableOtherFields, ExistingSelectionFields, AllRegisterFields);
		
	QueryText = StrReplace(QueryText, "&OtherSelectionFields", TextOfSelectionOfOtherFields);
	QueryText = StrReplace(QueryText, "&OrganizationSelectionCriteria", OrganizationSelectionCriteria);
	QueriesTexts.Add(QueryText);
	
	#EndRegion
	
	#Region ReversePrepaymentToVendor
	
	QueryText = "
	|SELECT
	|	RegisterData.Period AS Period,
	|	""VendorsARAPAccountingByDueDates"" AS RegisterName,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors) AS AccountingObjectDr,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable) AS AccountingObjectCr,
	|	FALSE AS ThisIsReverseTransaction,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor) AS SettingUpBusinessTransaction,
	|	"""" AS FinRecordID,
	|	"""" AS RowID,
	|	FALSE AS PropsStorno,
	|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.Recorder AS ARAPDocument,
	|	RegisterData.Currency AS Currency,
	|	&OtherSelectionFields,
	|	SUM(RegisterData.PrepaymentMan) AS SumManDr,
	|	SUM(RegisterData.ARAPMan) AS SumManCr,
	|	SUM(RegisterData.PrepaymentLocal) AS SumComplDr,
	|	SUM(RegisterData.DebtLocal) AS SumComplCr,
	|	SUM(RegisterData.Prepayment) AS SumCurrDr,
	|	SUM(RegisterData.Debt) AS SumCurrCr
	|INTO TTSettlementsWithSuppliersOnStorno
	|FROM
	|	(SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		VendorsARAPAccountingByDueDates.Currency AS Currency,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.Debt 
	|			ELSE VendorsARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.DebtLocal 
	|			ELSE VendorsARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.ARAPMan 
	|			ELSE VendorsARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.Prepayment 
	|			ELSE VendorsARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON VendorsARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.ReversedDocument
	|		 AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		NOT VendorsARAPAccountingByDueDates.ReversingEntry
	|		AND &OrganizationSelectionCriteria
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		VendorsARAPAccountingByDueDates.Currency AS Currency,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.Debt 
	|			ELSE VendorsARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.DebtLocal 
	|			ELSE VendorsARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.ARAPMan 
	|			ELSE VendorsARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.Prepayment 
	|			ELSE VendorsARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON VendorsARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.DocumentReversingEntry
	|		 AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		VendorsARAPAccountingByDueDates.ReversingEntry
	|		AND &OrganizationSelectionCriteria
	|	) AS RegisterData
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.Currency
	|HAVING
	|	SUM(RegisterData.Debt) <> 0 OR SUM(RegisterData.Prepayment) <> 0
	|	OR SUM(RegisterData.ARAPMan) <> 0 OR SUM(RegisterData.PrepaymentMan) <> 0
	|	OR SUM(RegisterData.DebtLocal) <> 0 OR SUM(RegisterData.PrepaymentLocal) <> 0
	|";
	
	If TypeOf(Query.Parameters.Organization) = Type("Array") Then
		OrganizationSelectionCriteria = "VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization IN (&Organization)";
	ElsIf ValueIsFilled(Query.Parameters.Organization) Then
		OrganizationSelectionCriteria = "VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = &Organization";
	Else
		OrganizationSelectionCriteria = "TRUE";
	EndIf;
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("AccountingDimensionByPartners");
	ExistingSelectionFields.Add("ARAPObject");
	ExistingSelectionFields.Add("Currency");
	ExistingSelectionFields.Add("ARAPDocument");
	ExistingSelectionFields.Add("Recorder");
	ExistingSelectionFields.Add("FinRecordID");
	ExistingSelectionFields.Add("BusinessTransactionSetting");
	ExistingSelectionFields.Add("ReversingEntry");
	
	AvailableOtherFields = New Array();
	AllRegisterFields = FinancialAccountingByBalanceSheetRegisterData.AvailableDataSourceFields(
		DescriptionOfFinancialRegisterFields(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name));
	
	TextOfSelectionOfOtherFields = FinancialAccountingByBalanceSheetRegisterData.FieldSelectionText(
		AvailableOtherFields, ExistingSelectionFields, AllRegisterFields);
		
	QueryText = StrReplace(QueryText, "&OtherSelectionFields", TextOfSelectionOfOtherFields);
	QueryText = StrReplace(QueryText, "&OrganizationSelectionCriteria", OrganizationSelectionCriteria);
	QueriesTexts.Add(QueryText);
	
	#EndRegion
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterOfDocumentsStorno");
	
	If Query.Parameters.RestoreCalculationsForStorno Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Results = Query.ExecuteBatch();
		QueriesTexts.Clear();
		
		If TMCommonUse.TemporaryTableSize(Query.TempTablesManager, "TTSettlementsWithCustomersOnStorno") > 0 Then
			TMCommonUse.AddIDsToTemporaryTable(
				"TTSettlementsWithCustomersOnStorno",
				Query.TempTablesManager,
				"FinRecordID");
		EndIf;
		
		If TMCommonUse.TemporaryTableSize(Query.TempTablesManager, "TTSettlementsWithSuppliersOnStorno") > 0 Then
			TMCommonUse.AddIDsToTemporaryTable(
				"TTSettlementsWithSuppliersOnStorno",
				Query.TempTablesManager,
				"FinRecordID");
		EndIf;
	EndIf;
	
EndProcedure

Procedure AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterName)
	
	QueryText = "
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.AccountingObjectDr AS AccountingObject,
	|	TRUE AS ThisIsDebit,
	|	FALSE AS ThisIsLoan,
	|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&AnalyticsSelectionFields,
	|	RegisterTable.Recorder AS Recorder,
	|	RegisterTable.Organization AS Organization,
	|	RegisterTable.ARAPObject.Department AS Department,
	|	RegisterTable.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterTable.FinRecordID AS FinRecordID,
	|	RegisterTable.RowID AS RowID,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.SumManDr AS SumMan,
	|	RegisterTable.SumComplDr AS SumCompl,
	|	RegisterTable.SumCurrDr AS SumCurr,
	|	0 AS Count,
	|	&EmptyDataSourceResources,
	|	FALSE AS PropsStorno
	|FROM
	|	&DataSource AS RegisterTable
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.AccountingObjectCr AS AccountingObject,
	|	FALSE AS ThisIsDebit,
	|	TRUE AS ThisIsLoan,
	|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&AnalyticsSelectionFields,
	|	RegisterTable.Recorder AS Recorder,
	|	RegisterTable.Organization AS Organization,
	|	RegisterTable.ARAPObject.Department AS Department,
	|	RegisterTable.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterTable.FinRecordID AS FinRecordID,
	|	RegisterTable.RowID AS RowID,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.SumManCr AS SumMan,
	|	RegisterTable.SumComplCr AS SumCompl,
	|	RegisterTable.SumCurrCr AS SumCurr,
	|	0 AS Count,
	|	&EmptyDataSourceResources,
	|	FALSE AS PropsStorno
	|FROM
	|	&DataSource AS RegisterTable
	|";
	
	If RegisterName = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name Then
		DataSource = "TTSettlementsWithCustomersOnStorno";
	Else
		DataSource = "TTSettlementsWithSuppliersOnStorno";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DataSource", DataSource);
	
	IndexBy = "INDEX BY"; //@Query-part
	
	If StrFind(RegisterRequestText, IndexBy, SearchDirection.FromEnd) = 0 Then
		RegisterRequestText = RegisterRequestText
			+ TMCommonUse.QuerySeparatorInJoin()
			+ QueryText;
	Else
		RegisterRequestText = StrReplace(RegisterRequestText, IndexBy,
			TMCommonUse.QuerySeparatorInJoin()
			+ QueryText
			+ IndexBy);
	EndIf;
	
EndProcedure

#EndRegion

#Region TextsOfCorrespondenceAnalyticsRequests

Function TextOfAnalysisSelectionFromNestedTable()
	
	QueryText = "
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.AccountingObject AS AccountingObject,
	|	RegisterTable.ThisIsDebit AS ThisIsDebit,
	|	RegisterTable.ThisIsLoan AS ThisIsLoan,
	|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&NestedTableAnalyticsFields,
	|	RegisterTable.Recorder AS Recorder,
	|	RegisterTable.Organization AS Organization,
	|	RegisterTable.Department AS Department,
	|	RegisterTable.LineOfBusiness AS LineOfBusiness,
	|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterTable.FinRecordID AS FinRecordID,
	|	RegisterTable.RowID AS RowID,
	|	RegisterTable.Currency AS Currency,
	|	SUM(RegisterTable.SumMan) AS SumMan,
	|	SUM(RegisterTable.SumCompl) AS SumCompl,
	|	SUM(RegisterTable.SumCurr) AS SumCurr,
	|	SUM(RegisterTable.Count) AS Count,
	|	&SumsOfResourcesOfNestedDataSource,
	|	RegisterTable.PropsStorno AS PropsStorno
	|FROM
	|	(SELECT
	|		RegisterTable.Period AS Period,
	|		RegisterTable.RegisterName AS RegisterName,
	|		RegisterTable.AccountingObject AS AccountingObject,
	|		RegisterTable.ThisIsDebit AS ThisIsDebit,
	|		RegisterTable.ThisIsLoan AS ThisIsLoan,
	|		RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		&NestedTableAnalyticsFields,
	|		RegisterTable.Recorder AS Recorder,
	|		RegisterTable.Organization AS Organization,
	|		RegisterTable.Department AS Department,
	|		RegisterTable.LineOfBusiness AS LineOfBusiness,
	|		RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterTable.FinRecordID AS FinRecordID,
	|		RegisterTable.RowID AS RowID,
	|		RegisterTable.Currency AS Currency,
	|		CASE
	|			WHEN RegisterTable.SumMan >= 0
	|				THEN RegisterTable.SumMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN RegisterTable.SumCompl >= 0
	|				THEN RegisterTable.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN RegisterTable.SumCurr >= 0
	|				THEN RegisterTable.SumCurr
	|			ELSE 0
	|		END AS SumCurr,
	|		CASE
	|			WHEN RegisterTable.Count >= 0
	|				THEN RegisterTable.Count
	|			ELSE 0
	|		END AS Count,
	|		&ResourcesOfNestedDataSource,
	|		RegisterTable.PropsStorno AS PropsStorno
	|	FROM
	|		&DataSource AS RegisterTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterTable.Period AS Period,
	|		RegisterTable.RegisterName AS RegisterName,
	|		RegisterTable.AccountingObject AS AccountingObject,
	|		RegisterTable.ThisIsLoan AS ThisIsDebit,
	|		RegisterTable.ThisIsDebit AS ThisIsLoan,
	|		NOT RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		&NestedTableAnalyticsFields,
	|		RegisterTable.Recorder AS Recorder,
	|		RegisterTable.Organization AS Organization,
	|		RegisterTable.Department AS Department,
	|		RegisterTable.LineOfBusiness AS LineOfBusiness,
	|		RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterTable.FinRecordID AS FinRecordID,
	|		RegisterTable.RowID AS RowID,
	|		RegisterTable.Currency AS Currency,
	|		CASE
	|			WHEN RegisterTable.SumMan < 0
	|				THEN -RegisterTable.SumMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN RegisterTable.SumCompl < 0
	|				THEN -RegisterTable.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN RegisterTable.SumCurr < 0
	|				THEN -RegisterTable.SumCurr
	|			ELSE 0
	|		END AS SumCurr,
	|		CASE
	|			WHEN RegisterTable.Count < 0
	|				THEN -RegisterTable.Count
	|			ELSE 0
	|		END AS Count,
	|		&EmptyDataSourceResources,
	|		RegisterTable.PropsStorno AS PropsStorno
	|	FROM
	|		&DataSource AS RegisterTable
	|	WHERE
	|		RegisterTable.SumMan < 0 OR RegisterTable.SumCompl < 0
	|		OR RegisterTable.SumCurr < 0 OR RegisterTable.Count < 0
	|	) AS RegisterTable
	|GROUP BY
	|	RegisterTable.Period,
	|	RegisterTable.RegisterName,
	|	RegisterTable.AccountingObject,
	|	RegisterTable.ThisIsDebit,
	|	RegisterTable.ThisIsLoan,
	|	RegisterTable.ThisIsReverseTransaction,
	|	&NestedTableAnalyticsGroup,
	|	RegisterTable.Recorder,
	|	RegisterTable.Organization,
	|	RegisterTable.Department,
	|	RegisterTable.LineOfBusiness,
	|	RegisterTable.SettingUpBusinessTransaction,
	|	RegisterTable.FinRecordID,
	|	RegisterTable.RowID,
	|	RegisterTable.Currency,
	|	RegisterTable.PropsStorno
	|";
	
	Return QueryText;
	
EndFunction

Function TextOfAnalyticsSampleFromTemporaryTable(ReplacingReverseWithReverse = False)
	
	If ReplacingReverseWithReverse Then
		QueryText = "
		|SELECT
		|	RegisterTable.Period AS Period,
		|	RegisterTable.RegisterName AS RegisterName,
		|	RegisterTable.AccountingObject AS AccountingObject,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsDebit
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN RegisterTable.ThisIsLoan
		|		ELSE RegisterTable.ThisIsDebit
		|	END AS ThisIsDebit,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsLoan
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN RegisterTable.ThisIsDebit
		|		ELSE RegisterTable.ThisIsLoan
		|	END AS ThisIsLoan,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsReverseTransaction
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsReverseTransaction
		|		ELSE RegisterTable.ThisIsReverseTransaction
		|	END AS ThisIsReverseTransaction,
		|	&NestedTableAnalyticsFields,
		|	RegisterTable.Recorder AS Recorder,
		|	RegisterTable.Organization AS Organization,
		|	RegisterTable.Department AS Department,
		|	RegisterTable.LineOfBusiness AS LineOfBusiness,
		|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterTable.FinRecordID AS FinRecordID,
		|	RegisterTable.RowID AS RowID,
		|	RegisterTable.Currency AS Currency,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.SumMan
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.SumMan
		|		ELSE RegisterTable.SumMan
		|	END) AS SumMan,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.SumCompl
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.SumCompl
		|		ELSE RegisterTable.SumCompl
		|	END) AS SumCompl,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.SumCurr
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.SumCurr
		|		ELSE RegisterTable.SumCurr
		|	END) AS SumCurr,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.Count
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.Count
		|		ELSE RegisterTable.Count
		|	END) AS Count,
		|	&SumsOfResourcesOfNestedDataSource,
		|	RegisterTable.PropsStorno AS PropsStorno
		|FROM
		|	&DataSource AS RegisterTable
		|	LEFT JOIN TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
		|		ON RegisterTable.Period = ReverseReplacementDocuments.Period
		|		 AND RegisterTable.Recorder = ReverseReplacementDocuments.Recorder
		|		 AND RegisterTable.FinRecordID = ReverseReplacementDocuments.FinRecordID
		|		 AND RegisterTable.Organization = ReverseReplacementDocuments.Organization
		|		 AND RegisterTable.PropsStorno = ReverseReplacementDocuments.PropsStorno
		|GROUP BY
		|	RegisterTable.Period,
		|	RegisterTable.RegisterName,
		|	RegisterTable.AccountingObject,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsDebit
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN RegisterTable.ThisIsLoan
		|		ELSE RegisterTable.ThisIsDebit
		|	END,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsLoan
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN RegisterTable.ThisIsDebit
		|		ELSE RegisterTable.ThisIsLoan
		|	END,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsReverseTransaction
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsReverseTransaction
		|		ELSE RegisterTable.ThisIsReverseTransaction
		|	END,
		|	&NestedTableAnalyticsGroup,
		|	RegisterTable.Recorder,
		|	RegisterTable.Organization,
		|	RegisterTable.Department,
		|	RegisterTable.LineOfBusiness,
		|	RegisterTable.SettingUpBusinessTransaction,
		|	RegisterTable.FinRecordID,
		|	RegisterTable.RowID,
		|	RegisterTable.Currency,
		|	RegisterTable.PropsStorno
		|";
	Else
		QueryText = "
		|SELECT
		|	RegisterTable.Period AS Period,
		|	RegisterTable.RegisterName AS RegisterName,
		|	RegisterTable.AccountingObject AS AccountingObject,
		|	RegisterTable.ThisIsDebit AS ThisIsDebit,
		|	RegisterTable.ThisIsLoan AS ThisIsLoan,
		|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	&AnalyticsSelectionFields,
		|	RegisterTable.Recorder AS Recorder,
		|	RegisterTable.Organization AS Organization,
		|	RegisterTable.Department AS Department,
		|	RegisterTable.LineOfBusiness AS LineOfBusiness,
		|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterTable.FinRecordID AS FinRecordID,
		|	RegisterTable.RowID AS RowID,
		|	RegisterTable.Currency AS Currency,
		|	RegisterTable.SumMan AS SumMan,
		|	RegisterTable.SumCompl AS SumCompl,
		|	RegisterTable.SumCurr AS SumCurr,
		|	RegisterTable.Count AS Count,
		|	&ResourcesOfNestedDataSource,
		|	RegisterTable.PropsStorno AS PropsStorno
		|FROM
		|	&DataSource AS RegisterTable
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctionsForGeneratingQueryTexts

Function FieldsForSelectingCorrespondenceRequestsThatAreBeingDeleted()
	
	FieldsToDelete__ = New Array();
	FieldsToDelete__.Add("Department");
	FieldsToDelete__.Add("LineOfBusiness");
	
	Return FieldsToDelete__;
	
EndFunction

Function DeletedFieldsForSelectingMotionAnalyticsQueries()
	
	FieldsToDelete__ = New Array();
	FieldsToDelete__.Add("OfficialTypeOfActivityVAT");
	
	Return FieldsToDelete__;
	
EndFunction

Function IndexFieldsOfCorrespondenceTable()
	
	IndexFields = New Array();
	IndexFields.Add("ThisIsDebit");
	IndexFields.Add("ThisIsLoan");
	
	Return IndexFields;
	
EndFunction

Function IndexFieldsOfCorrespondenceSelectionTables()
	
	IndexFields = New Array();
	IndexFields.Add("Period");
	IndexFields.Add("Recorder");
	IndexFields.Add("FinRecordID");
	IndexFields.Add("RowID");
	IndexFields.Add("AccountingObject");
	IndexFields.Add("Organization");
	IndexFields.Add("SettingUpBusinessTransaction");
	IndexFields.Add("PropsStorno");
	
	Return IndexFields;
	
EndFunction

Function IndexFieldsOfTablesReplacingReverseWithReverse()
	
	IndexFields = New Array();
	IndexFields.Add("Period");
	IndexFields.Add("Recorder");
	IndexFields.Add("FinRecordID");
	IndexFields.Add("Organization");
	
	Return IndexFields;
	
EndFunction

Function SelectionFieldsBasedOnDescriptionOfAccountingObject()
	
	SelectionFields1 = FinancialAccountingByBalanceSheetRegisterData.SelectionFieldsBasedOnDescriptionOfAccountingObject();
	
	Return SelectionFields1;
	
EndFunction

Function RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(AccountingObjectRows_, MotionReflectionParameters, QueryOptions)
	
	FieldList = StrConcat(SelectionFieldsBasedOnDescriptionOfAccountingObject(), ",");
	
	FieldsOfAccountingObjectSelection = FinancialAccountingByBalanceSheetRegisterData.RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, FieldList);
	
	Return FieldsOfAccountingObjectSelection;
	
EndFunction

#EndRegion

#Region SelectionOfCorrespondenceAccordingToSettingsOfDataCompositionSchema

Function DataCompositionSelectionFields(QueryOptions)
	
	SelectionFields = New Structure();
	SelectionFields.Insert("RecNo", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative));
	SelectionFields.Insert("RuleForObtainingFact", New TypeDescription("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"));
	
	Return SelectionFields;
	
EndFunction

Function DataLayoutResultsTable(DataCompositionSelectionFields)
	
	ResultsTable = New ValueTable();
	
	For Each ComboBox In DataCompositionSelectionFields Do
		ResultsTable.Columns.Add(ComboBox.Key, ComboBox.Value);
	EndDo;
	
	Return ResultsTable;
	
EndFunction

Function KeySelectionRules(SelectionSelectionRules)
	
	RuleKey = New Structure();
	RuleKey.Insert("RuleForObtainingFact", SelectionSelectionRules.RuleForObtainingFact);
	
	If ValueIsFilled(SelectionSelectionRules.AccountingObjectDr) Then
		RuleKey.Insert("AccountingObjectDr", SelectionSelectionRules.AccountingObjectDr);
	EndIf;
	
	If ValueIsFilled(SelectionSelectionRules.AccountingObjectCr) Then
		RuleKey.Insert("AccountingObjectCr", SelectionSelectionRules.AccountingObjectCr);
	EndIf;
	
	Return RuleKey;
	
EndFunction

Procedure AddRuleKeyToDataLayoutSelection(RuleKey, FilterReceiver)
	
	For Each KeyAndValue In RuleKey Do
		NewItem = FilterReceiver.Items.Add(Type("DataCompositionFilterItem"));
		NewItem.LeftValue = New DataCompositionField(KeyAndValue.Key);
		NewItem.ComparisonType = DataCompositionComparisonType.Equal;
		NewItem.RightValue = KeyAndValue.Value;
		NewItem.Use = True;
	EndDo;
	
EndProcedure

Procedure AddRuleSelectionToDataLayoutSelection(FilterSource, InversionOfDataSources, FilterReceiver)
	
	PostfixesByFolderFieldNames = New Structure();
	PostfixesByFolderFieldNames.Insert(
		DataSourcesServer.NameOfDataSourceFieldsFolder(),
		?(InversionOfDataSources, "Cr", "Dr"));
	PostfixesByFolderFieldNames.Insert(
		DataSourcesServer.NameOfFolderOfFieldsOfCorDataSource(),
		?(InversionOfDataSources, "Dr", "Cr"));
	
	For Each SourceSelectionElement In FilterSource.Items Do
		If Not SourceSelectionElement.Use Then
			Continue;
		EndIf;
		
		TypeOfSelectionElement = TypeOf(SourceSelectionElement);
		ReceiverSelectionElement = FilterReceiver.Items.Add(TypeOfSelectionElement);
		
		If TypeOfSelectionElement = Type("DataCompositionFilterItem") Then
			DataPath = String(SourceSelectionElement.LeftValue);
			DataPathParts = StrSplit(DataPath, ".");
			NameOfFieldsFolder = DataPathParts[0];
			Postfix = "";
			
			If PostfixesByFolderFieldNames.Property(NameOfFieldsFolder, Postfix) Then
				DataPathParts.Delete(0);
			Else
				Postfix = ?(InversionOfDataSources, "Cr", "Dr");
			EndIf;
			
			If NameOfFieldsFolder = DataSourcesServer.NameOfFolderOfFieldsOfCorDataSource() Then
				FieldsNamesPrefix = DataSourcesServer.PrefixOfFieldNamesCorOfDataSource();
				LengthOfNamePrefix = StrLen(FieldsNamesPrefix);
				If Left(DataPathParts[0], LengthOfNamePrefix) = FieldsNamesPrefix Then
					DataPathParts[0] = Mid(DataPathParts[0], LengthOfNamePrefix + 1);
				EndIf;
			EndIf;
			
			DataPathParts[0] = DataPathParts[0] + Postfix;
			DataPath = StrConcat(DataPathParts, ".");
			FillPropertyValues(ReceiverSelectionElement, SourceSelectionElement,, "LeftValue");
			ReceiverSelectionElement.LeftValue = New DataCompositionField(DataPath);
		Else
			FillPropertyValues(ReceiverSelectionElement, SourceSelectionElement);
			AddRuleSelectionToDataLayoutSelection(FilterSource, InversionOfDataSources, FilterReceiver);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region GettingCorrespondenceAnalytics

Function RegisterAnalyticsExpressions(FetchingRegisterName, QueryOptions)
	
	RegisterAnalyticsExpressions = New Array();
	SelectingAnalyticsExpression = FetchingRegisterName.Select();
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	While SelectingAnalyticsExpression.Next() Do
		For ExpressionNumber = 1 To MaximumNumberOfAnalysts Do
			ExpressionAnalytics = SelectingAnalyticsExpression["ExpressionAnalytics" + ExpressionNumber];
			If ValueIsFilled(ExpressionAnalytics) Then
				NormalizeAnalyticsExpression(ExpressionAnalytics, QueryOptions);
				If RegisterAnalyticsExpressions.Find(ExpressionAnalytics) = Undefined Then
					RegisterAnalyticsExpressions.Add(ExpressionAnalytics);
				EndIf;
				If QueryOptions.AllAnalyticsExpressions[ExpressionAnalytics] = Undefined Then
					ExpressionName = "Expression" + StrReplace(ExpressionAnalytics, ".", "");
					QueryOptions.AllAnalyticsExpressions.Insert(ExpressionAnalytics, ExpressionName);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return RegisterAnalyticsExpressions;
	
EndFunction

Procedure NormalizeAnalyticsExpression(ExpressionAnalytics, QueryOptions)
	
	If StrStartsWith(ExpressionAnalytics, QueryOptions.NameOfFieldsFolder) Then
		ExpressionAnalytics = Mid(ExpressionAnalytics, QueryOptions.LengthOfFieldsFolderName + 2);
	EndIf;
	
	If StrStartsWith(ExpressionAnalytics, QueryOptions.FolderNameCorFields) Then
		ExpressionAnalytics = Mid(ExpressionAnalytics, QueryOptions.LengthOfFolderNameCorFields + 2);
		If StrStartsWith(ExpressionAnalytics, QueryOptions.PrefixOfFieldNames) Then
			ExpressionAnalytics = Mid(ExpressionAnalytics, QueryOptions.PrefixLengthOfFieldNames + 1);
		EndIf;
	EndIf;
	
	ExpressionAnalytics = StrReplace(ExpressionAnalytics, "_", ".");
	
EndProcedure

Procedure FillInLinesOfExpressionSelection(SelectingFields, FieldsGrouping, RegisterAnalyticsExpressions, AllAnalyticsExpressions)
	
	For Each ExpressionAnalytics In RegisterAnalyticsExpressions Do
		DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(ExpressionAnalytics);
		ExpressionAlias = AllAnalyticsExpressions[ExpressionAnalytics];
		SelectingFields.Add(DataPath + " AS " + ExpressionAlias);
		FieldsGrouping.Add(DataPath);
	EndDo;
	
EndProcedure

Procedure FillInResourceSelectionLines(SelectionOfResources, SamplingSourceName)
	
	FetchingResourceNames = SamplingSourceName.Select();
	
	While FetchingResourceNames.Next() Do
		ResourceName = FetchingResourceNames.ResourceName;
		DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(ResourceName);
		ResourceAlias = "Resource" + ResourceName;
		SelectionOfResources.Add(StrTemplate("SUM(%1) AS %2", DataPath, ResourceAlias));
	EndDo;
	
EndProcedure

#EndRegion

#Region FillingInActualDataTable

Function AnalyticsQueryTable(QueryResult)
	
	QueryTable = QueryResult.Unload();
	RequiredIndexFields = "Period,Recorder,FinRecordID,RowID,RegisterName,AccountingObject,Organization,PropsStorno";
	
	QueryTable.Indexes.Add(RequiredIndexFields + ",ThisIsDebit,ThisIsReverseTransaction");
	QueryTable.Indexes.Add(RequiredIndexFields + ",ThisIsLoan,ThisIsReverseTransaction");
	QueryTable.Indexes.Add(RequiredIndexFields + ",SettingUpBusinessTransaction,ThisIsDebit,ThisIsReverseTransaction");
	QueryTable.Indexes.Add(RequiredIndexFields + ",SettingUpBusinessTransaction,ThisIsLoan,ThisIsReverseTransaction");
	
	Return QueryTable;
	
EndFunction

Function TrafficAnalyticsLines(SelectionCorrespondence,
		SamplingAnalyticsValues, SelectingAnalyticsExpression, AnalyticsTables, QueryOptions, DrCr)
	
	RegisterName = SelectionCorrespondence["RegisterName" + DrCr];
	ThisIsDataSource = SelectionCorrespondence.SourceOfCorrespondenceData = DrCr;
	
	If ThisIsDataSource Or SelectionCorrespondence.GetCoreAnalytics Then
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Period", SelectionCorrespondence.Period);
		TheStructureOfTheSearch.Insert("Recorder", SelectionCorrespondence.Recorder);
		TheStructureOfTheSearch.Insert("FinRecordID", SelectionCorrespondence.FinRecordID);
		TheStructureOfTheSearch.Insert("RowID", SelectionCorrespondence["RowID" + DrCr]);
		TheStructureOfTheSearch.Insert("RegisterName", RegisterName);
		TheStructureOfTheSearch.Insert("AccountingObject", SelectionCorrespondence["AccountingObject" + DrCr]);
		TheStructureOfTheSearch.Insert("Organization", SelectionCorrespondence.Organization);
		TheStructureOfTheSearch.Insert("PropsStorno", SelectionCorrespondence.PropsStorno);
		
		If SelectionCorrespondence.TakeIntoAccountBusinessTransaction Then
			TheStructureOfTheSearch.Insert("SettingUpBusinessTransaction", SelectionCorrespondence.SettingUpBusinessTransaction);
		EndIf;
		
		If DrCr = "Dr" Then
			TheStructureOfTheSearch.Insert("ThisIsLoan", False);
		Else
			TheStructureOfTheSearch.Insert("ThisIsDebit", False);
		EndIf;
		
		TheStructureOfTheSearch.Insert("ThisIsReverseTransaction", SelectionCorrespondence["ThisIsReverseTransaction" + DrCr]);
		AnalyticsLines_ = AnalyticsTables[RegisterName].Copy(TheStructureOfTheSearch); // ValueTable -
		
		PerformAdditionalSelectionOfAnalyticsRows(SelectionCorrespondence, AnalyticsLines_, DrCr);
		
		If ThisIsDataSource Then
			SamplingAnalyticsValues.Reset();
			TheStructureOfTheSearch = New Structure("RuleForObtainingFact", SelectionCorrespondence.RuleForObtainingFact);
			GetAnalyticsValues = SamplingAnalyticsValues.FindNext(TheStructureOfTheSearch);
		Else
			GetAnalyticsValues = False;
		EndIf;
		
		SelectingAnalyticsExpression.Reset();
		TheStructureOfTheSearch = New Structure(
			"RuleForObtainingFact,AccountingObjectDr,AccountingObjectCr",
			SelectionCorrespondence.RuleForObtainingFact,
			SelectionCorrespondence.AccountingObjectDr,
			SelectionCorrespondence.AccountingObjectCr);
		GetAnalyticsExpressions = SelectingAnalyticsExpression.FindNext(TheStructureOfTheSearch);
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		AnalyticsColumnNames = CommonClientServer.ValueInArray("Department");
		
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			AnalyticsColumnName = "Dimension" + DimensionNumber;
			AnalyticsLines_.Columns.Add(AnalyticsColumnName);
			
			If GetAnalyticsValues Then
				DimensionValue = SamplingAnalyticsValues["DimensionValue" + DimensionNumber];
			Else
				DimensionValue = Null;
			EndIf;
			
			If DimensionValue = Null And GetAnalyticsExpressions Then
				ExpressionAnalytics = SelectingAnalyticsExpression["ExpressionAnalytics" + DimensionNumber];
				CorSourceOfAnalytics = SelectingAnalyticsExpression["CorSourceOfAnalytics" + DimensionNumber];
				
				If ValueIsFilled(ExpressionAnalytics)
				 And (ThisIsDataSource And Not CorSourceOfAnalytics 
					Or Not ThisIsDataSource And CorSourceOfAnalytics) Then
					NormalizeAnalyticsExpression(ExpressionAnalytics, QueryOptions);
					NameOfExpressionColumn = QueryOptions.AllAnalyticsExpressions[ExpressionAnalytics];
				Else
					NameOfExpressionColumn = Null;
				EndIf;
			Else
				NameOfExpressionColumn = Null;
			EndIf;
			
			For Each AnalyticsLine_ In AnalyticsLines_ Do
				If DimensionValue <> Null Then
					AnalyticsLine_[AnalyticsColumnName] = DimensionValue;
				ElsIf ValueIsFilled(NameOfExpressionColumn) Then
					If ValueIsFilled(AnalyticsLine_[NameOfExpressionColumn]) Then
						AnalyticsLine_[AnalyticsColumnName] = AnalyticsLine_[NameOfExpressionColumn];
					Else
						AnalyticsLine_[AnalyticsColumnName] = Undefined;
					EndIf;
				Else
					AnalyticsLine_[AnalyticsColumnName] = Undefined;
				EndIf;
				
				If DimensionNumber = 1 And Not ValueIsFilled(AnalyticsLine_.Department) Then
					AnalyticsLine_.Department = Undefined;
				EndIf;
			EndDo;
			AnalyticsColumnNames.Add(AnalyticsColumnName);
		EndDo;
		
		If AnalyticsLines_.Count() > 1 Then
			ResourcesColumnNames = New Array();
			For Each Column In AnalyticsLines_.Columns Do
				If Column.ValueType.ContainsType(Type("Number")) Then
					ResourcesColumnNames.Add(Column.Name);
				EndIf;
			EndDo;
			GroupColumns = StrConcat(AnalyticsColumnNames, ",");
			TotalingColumns = StrConcat(ResourcesColumnNames, ",");
			AnalyticsLines_.GroupBy(GroupColumns, TotalingColumns);
			SelectAnalyticsRowsByAmounts(SelectionCorrespondence, AnalyticsLines_, DrCr);
		EndIf;
	Else
		AnalyticsLines_ = New ValueTable();
	EndIf;
	
	Return AnalyticsLines_;
	
EndFunction

// The selection conditions in this procedure must correspond to the additional conditions for joining records in the correspondence formation procedure
//
Procedure PerformAdditionalSelectionOfAnalyticsRows(SelectionCorrespondence, AnalyticsLines_, DrCr)
	
	If Not SelectionCorrespondence.TakeIntoAccountBusinessTransaction Then
		RowsCount = AnalyticsLines_.Count();
		For ReverseIndex = 1 To RowsCount Do
			AnalyticsLine_ = AnalyticsLines_[RowsCount - ReverseIndex];
			If ValueIsFilled(AnalyticsLine_.SettingUpBusinessTransaction)
				And AnalyticsLine_.SettingUpBusinessTransaction <> SelectionCorrespondence.SettingUpBusinessTransaction Then
				AnalyticsLines_.Delete(AnalyticsLine_);
			EndIf;
		EndDo;
	EndIf;
	
	SelectAnalyticsRowsByAmounts(SelectionCorrespondence, AnalyticsLines_, DrCr);
	
EndProcedure

Procedure SelectAnalyticsRowsByAmounts(SelectionCorrespondence, AnalyticsLines_, DrCr)
	
	If AnalyticsLines_.Count() > 1
	And Not SelectionCorrespondence["ComplexEntry" + DrCr] Then
		AnalyticsWithMovementSums = New Array();
		
		For Each AnalyticsLine_ In AnalyticsLines_ Do
			If AnalyticsLine_.SumMan = SelectionCorrespondence["AmountOfManMovement" + DrCr]
			   And AnalyticsLine_.SumCompl = SelectionCorrespondence["AmountOfLocalTraffic" + DrCr] Then
				AnalyticsWithMovementSums.Add(AnalyticsLine_);
			EndIf;
		EndDo;
		
		If AnalyticsWithMovementSums.Count() = 1 Then
			RowsCount = AnalyticsLines_.Count();
			For ReverseIndex = 1 To RowsCount Do
				AnalyticsLine_ = AnalyticsLines_[RowsCount - ReverseIndex];
				If AnalyticsLine_ <> AnalyticsWithMovementSums[0] Then
					AnalyticsLines_.Delete(AnalyticsLine_);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

Function DescriptionOfDataSourceIndicator(SamplingResourcesOfIndicators, RuleDescription_)
	
	DescriptionIndicator = ChartsOfCharacteristicTypes.AssetLiabilityItems.NewDescriptionOfIndicator();
	
	TheStructureOfTheSearch = New Structure("AccountingObject,Factor",
		RuleDescription_.DataSource, RuleDescription_.TransactionAmountSource);
	
	SamplingResourcesOfIndicators.Reset();
	
	While SamplingResourcesOfIndicators.FindNext(TheStructureOfTheSearch) Do
		ResourceTable = DescriptionIndicator[SamplingResourcesOfIndicators.ResourceGroup]; // ValueTable -
		FillPropertyValues(ResourceTable.Add(), SamplingResourcesOfIndicators);
	EndDo;
	
	Return DescriptionIndicator;
	
EndFunction

Function SourceBalanceIndicator(DescriptionIndicator)
	
	SourceBalanceIndicator = True;
	
	For Each KeyAndValue In DescriptionIndicator Do
		ResourceTable = KeyAndValue.Value;
		If ResourceTable.Count() > 0 Then
			SourceBalanceIndicator = False;
			Break;
		EndIf;
	EndDo;
	
	Return SourceBalanceIndicator;
	
EndFunction

Function IndicatorResourceValues(SelectionCorrespondence, DescriptionIndicator, AnalyticsOfDataSource, FactGettingParameters, DrCr)
	
	ResourcesValues = NewValuesOfIndicatorResources(FactGettingParameters);
	SourceBalanceIndicator = SourceBalanceIndicator(DescriptionIndicator);
	
	If SourceBalanceIndicator And AnalyticsOfDataSource.Count() = 1 Then
		NewRow = ResourcesValues.Add();
		NewRow.SumMan = SelectionCorrespondence.SumMan;
		NewRow.SumCompl = SelectionCorrespondence.SumCompl;
		NewRow.SumCurr = SelectionCorrespondence["SumCurr" + DrCr];
		NewRow.Count = SelectionCorrespondence["Count" + DrCr];
	Else
		For Each AnalyticsLine_ In AnalyticsOfDataSource Do
			NewRow = ResourcesValues.Add();
			If SourceBalanceIndicator Then
				FillPropertyValues(NewRow, AnalyticsLine_);
			Else
				For Each KeyAndValue In DescriptionIndicator Do
					ResourceGroup = KeyAndValue.Key;
					ResourceTable = KeyAndValue.Value;
					ValueOfResources = 0;
					
					For Each ResourceString In ResourceTable Do
						ResourceColumnName = "Resource" + ResourceString.ResourceName;
						ResourceValue = AnalyticsLine_[ResourceColumnName] * ResourceString.ZoomRatio;
						ValueOfResources = ValueOfResources + ResourceValue;
					EndDo;
					
					If SelectionCorrespondence["ThisIsReverseTransaction" + DrCr] And ValueOfResources < 0 Then
						ValueOfResources = - ValueOfResources;
					EndIf;
					
					EnumValueName = NameOfResourceGroupValue(ResourceGroup);
					NewRow[EnumValueName] = ValueOfResources;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	ResourcesValues.FillValues(SelectionCorrespondence["Currency" + DrCr], "Currency");
	
	Return ResourcesValues;
	
EndFunction

Procedure RecalculateResourcesOfUnbalancedComplexCorrespondenceIndicator(SelectionCorrespondence, SamplingComplexCorrespondence, ResourcesValues)
	
	ManDistributionCoefficients = New Array();
	LocalDistributionCoefficients = New Array();
	IndexOfCurrentCorrespondence = 0;
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Period", SelectionCorrespondence.Period);
	TheStructureOfTheSearch.Insert("Recorder", SelectionCorrespondence.Recorder);
	TheStructureOfTheSearch.Insert("FinRecordID", SelectionCorrespondence.FinRecordID);
	TheStructureOfTheSearch.Insert("Organization", SelectionCorrespondence.Organization);
	TheStructureOfTheSearch.Insert("PropsStorno", SelectionCorrespondence.PropsStorno);
	
	If SelectionCorrespondence.TakeIntoAccountBusinessTransaction Then
		TheStructureOfTheSearch.Insert("SettingUpBusinessTransaction", SelectionCorrespondence.SettingUpBusinessTransaction);
	EndIf;
	
	SamplingComplexCorrespondence.Reset();
	
	While SamplingComplexCorrespondence.FindNext(TheStructureOfTheSearch) Do
		If SamplingComplexCorrespondence.AmountOfManMovement <> 0 Then
			ManDistributionCoefficients.Add(SamplingComplexCorrespondence.SumMan);
		Else
			ManDistributionCoefficients.Add(SamplingComplexCorrespondence.SumCompl);
		EndIf;
			
		If SamplingComplexCorrespondence.AmountOfLocalTraffic <> 0 Then
			LocalDistributionCoefficients.Add(SamplingComplexCorrespondence.SumCompl);
		Else
			LocalDistributionCoefficients.Add(SamplingComplexCorrespondence.SumMan);
		EndIf;
		
		If SelectionCorrespondence.RecNo = SamplingComplexCorrespondence.RecNo Then
			IndexOfCurrentCorrespondence = ManDistributionCoefficients.Count() - 1;
		EndIf;
	EndDo;
	
	For Each Column In ResourcesValues.Columns Do
		If Column.ValueType.ContainsType(Type("Number")) Then
			ResourceSummary = ResourcesValues.Total(Column.Name);
			DistributionAccuracy = Column.ValueType.NumberQualifiers.FractionDigits;
			
			If Column.Name = "SumCompl" Then
				DistributionCoefficients = LocalDistributionCoefficients;
			Else
				DistributionCoefficients = ManDistributionCoefficients;
			EndIf;
			
			If ResourceSummary <> 0 Then
				DistributionOfTotal = CommonClientServer.DistributeAmountInProportionToCoefficients(
					ResourceSummary, DistributionCoefficients, DistributionAccuracy);
			Else
				DistributionOfTotal = Undefined;
			EndIf;
			
			If DistributionOfTotal = Undefined Then
				ResourceAllocation = Undefined;
			Else
				ResourceValue = DistributionOfTotal[IndexOfCurrentCorrespondence];
				If ResourceValue <> 0 Then
					ResourceAllocation = CommonClientServer.DistributeAmountInProportionToCoefficients(
						ResourceValue, ResourcesValues.UnloadColumn(Column.Name), DistributionAccuracy);
				Else
					ResourceAllocation = Undefined;
				EndIf;
			EndIf;
			
			If ResourceAllocation = Undefined Then
				ResourcesValues.FillValues(0, Column.Name);
			Else
				ResourcesValues.LoadColumn(ResourceAllocation, Column.Name);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure RecalculateResourcesOfBalanceIndicatorOfComplexCorrespondence(SelectionCorrespondence, ResourcesValues, DrCr)
	
	For Each Column In ResourcesValues.Columns Do
		If Column.ValueType.ContainsType(Type("Number")) Then
			If Column.Name = "SumCurr" Or Column.Name = "Count" Then
				ResourceNameSuffix = DrCr;
			Else
				ResourceNameSuffix = "";
			EndIf;
			
			ResourceValue = SelectionCorrespondence[Column.Name + ResourceNameSuffix];
			DistributionAccuracy = Column.ValueType.NumberQualifiers.FractionDigits;
			
			If ResourceValue <> 0 Then
				ResourceAllocation = CommonClientServer.DistributeAmountInProportionToCoefficients(
					ResourceValue, ResourcesValues.UnloadColumn(Column.Name), DistributionAccuracy);
			Else
				ResourceAllocation = Undefined;
			EndIf;
			
			If ResourceAllocation = Undefined Then
				ResourcesValues.FillValues(0, Column.Name);
			Else
				ResourcesValues.LoadColumn(ResourceAllocation, Column.Name);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure GetSimpleAnalyticsData(SelectionCorrespondence, ActualDataTable, ResourcesValues,
	AnalyticsOfDataSource, AnalyticsOfCoreDataSource, FactGettingParameters, RuleDescription_)
	
	DrCr = SelectionCorrespondence.SourceOfCorrespondenceData;
	SourceAnalyticsLine = AnalyticsOfDataSource[0];
	SourceCodeAnalyticsLine = ?(SelectionCorrespondence.GetCoreAnalytics,
		AnalyticsOfCoreDataSource[0], Undefined);
	StringOfResourceValues = ResourcesValues[0];
	
	ActualDataLine = ActualDataTable.Add();
	
	FillInActualDataAttributes(ActualDataLine, SelectionCorrespondence, RuleDescription_);
	CompleteActualDataAnalytics(ActualDataLine, SourceAnalyticsLine, SourceCodeAnalyticsLine, RuleDescription_);
	FillInActualDataResources(ActualDataLine, SelectionCorrespondence, StringOfResourceValues, FactGettingParameters, RuleDescription_);
	
EndProcedure

Procedure FillInActualDataAttributes(ActualDataLine, SelectionCorrespondence, RuleDescription_)
	
	FillPropertyValues(ActualDataLine, SelectionCorrespondence, "Period,Recorder,Organization");
	FillPropertyValues(ActualDataLine, RuleDescription_);
	
	ActualDataLine.RatePeriod = SelectionCorrespondence.Period;
	ActualDataLine.Scenario = Catalogs.BudgetingScenarios.ActualData;
	
EndProcedure

Procedure CompleteActualDataAnalytics(ActualDataLine, SourceAnalyticsLine, SourceCodeAnalyticsLine, RuleDescription_)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AnalyticsColumnName = "Dimension" + DimensionNumber;
		ColumnNameTypeOfAnalytics = "DimensionKind" + DimensionNumber;
		
		If Not ValueIsFilled(RuleDescription_[ColumnNameTypeOfAnalytics]) Then
			ActualDataLine[AnalyticsColumnName] = Undefined;
		ElsIf ValueIsFilled(SourceAnalyticsLine[AnalyticsColumnName]) Then
			ActualDataLine[AnalyticsColumnName] = SourceAnalyticsLine[AnalyticsColumnName];
		ElsIf SourceCodeAnalyticsLine <> Undefined
			And ValueIsFilled(SourceCodeAnalyticsLine[AnalyticsColumnName]) Then
			ActualDataLine[AnalyticsColumnName] = SourceCodeAnalyticsLine[AnalyticsColumnName];
		Else
			ActualDataLine[AnalyticsColumnName] = Undefined;
		EndIf;
	EndDo;
	
	ActualDataLine.Department = SourceAnalyticsLine.Department;
	
EndProcedure

Procedure FillInActualDataResources(ActualDataLine, SelectionCorrespondence, StringOfResourceValues, FactGettingParameters, RuleDescription_)
	
	CurrenciesOfOperationalAccounting = FinancialAccountingByBalanceSheetRegisterData.CurrenciesOfOperationalAccounting(SelectionCorrespondence.Organization);
	FunctionalSum = FunctionalSum(StringOfResourceValues, CurrenciesOfOperationalAccounting, FactGettingParameters);
	RuleCoefficient = RuleCoefficient(SelectionCorrespondence, RuleDescription_);
	
	ActualDataLine.CurrencyFunctional = FunctionalSum.Currency;
	ActualDataLine.AmountInFunctionalCurrency = FunctionalSum.Sum * RuleCoefficient;
	
	ActualDataLine.SumMan = StringOfResourceValues.SumMan * RuleCoefficient;
	ActualDataLine.SumCompl = StringOfResourceValues.SumCompl * RuleCoefficient;
	
	ActualDataLine.Currency = StringOfResourceValues.Currency;
	ActualDataLine.AmountInCurrency = StringOfResourceValues.SumCurr * RuleCoefficient;
	ActualDataLine.Count = StringOfResourceValues.Count * RuleCoefficient;
	
	ActualDataLine.StorageCurrency = StringOfResourceValues.Currency;
	ActualDataLine.AmountInStorageCurrency = StringOfResourceValues.SumCurr * RuleCoefficient;
	
EndProcedure

Function FunctionalSum(ResourcesValues, CurrenciesOfOperationalAccounting, FactGettingParameters)
	
	If FactGettingParameters.FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
		Sum = ResourcesValues.SumMan;
		ResourceCurrency = CurrenciesOfOperationalAccounting.CurrencyOfMan;
	Else //Fact receipt parametersreferences.Functional Currency = Transfers.Types of accounting in a functional currency.VValuteRegl
		Sum = ResourcesValues.SumCompl;
		ResourceCurrency = CurrenciesOfOperationalAccounting.ComplCurrency;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Sum", Sum);
	Result.Insert("Currency", ResourceCurrency);
	
	Return Result;
	
EndFunction

Function RuleCoefficient(SelectionCorrespondence, RuleDescription_)
	
	If SelectionCorrespondence.InversionOfActualData
		And SelectionCorrespondence.InvertCorrespondence Then
		RuleCoefficient = RuleDescription_.ZoomRatio;
	ElsIf SelectionCorrespondence.InversionOfActualData
		Or SelectionCorrespondence.InvertCorrespondence Then
		RuleCoefficient = - RuleDescription_.ZoomRatio;
	Else 
		RuleCoefficient = RuleDescription_.ZoomRatio;
	EndIf;
	
	Return RuleCoefficient;
	
EndFunction

Procedure GetSophisticatedAnalyticsData(SelectionCorrespondence, ActualDataTable, ResourcesValues,
	AnalyticsOfDataSource, AnalyticsOfCoreDataSource, FactGettingParameters, RuleDescription_)
	
	DrCr = SelectionCorrespondence.SourceOfCorrespondenceData;
	BalancedDrCr = SelectionCorrespondence.CorSourceOfCorrespondenceData;
	
	If AnalyticsOfDataSource.Count() > 1 Then
		ManyAnalysts = New Structure("DrCr,AnalyticsLines_", DrCr, AnalyticsOfDataSource);
		SourceCodeAnalyticsLine = ?(SelectionCorrespondence.GetCoreAnalytics,
			AnalyticsOfCoreDataSource[0], Undefined);
		OneDimension = New Structure("DrCr,AnalyticsLine_", BalancedDrCr, SourceCodeAnalyticsLine);
		DataSourceResources = ResourcesValues;
	Else
		ManyAnalysts = New Structure("DrCr,AnalyticsLines_", BalancedDrCr, AnalyticsOfCoreDataSource);
		OneDimension = New Structure("DrCr,AnalyticsLine_", DrCr, AnalyticsOfDataSource[0]);
		
		EmptyMetric = ChartsOfCharacteristicTypes.AssetLiabilityItems.NewDescriptionOfIndicator();
		ValuesOfCorOfResources = IndicatorResourceValues(SelectionCorrespondence, EmptyMetric, AnalyticsOfCoreDataSource, FactGettingParameters, BalancedDrCr);
		
		If SelectionCorrespondence["ComplexEntry" + BalancedDrCr] Then
			RecalculateResourcesOfBalanceIndicatorOfComplexCorrespondence(SelectionCorrespondence, ValuesOfCorOfResources, BalancedDrCr);
		EndIf;
		
		AllocateResourcesForComplexAnalytics(ResourcesValues, ValuesOfCorOfResources);
		DataSourceResources = ValuesOfCorOfResources;
	EndIf;
	
	ResourcesStringIndex = 0;
	
	For Each AnalyticsLine_ In ManyAnalysts.AnalyticsLines_ Do
		ActualDataLine = ActualDataTable.Add();
		StringOfResourceValues = DataSourceResources[ResourcesStringIndex];
		
		If ManyAnalysts.DrCr = DrCr Then
			SourceAnalyticsLine = AnalyticsLine_;
			SourceCodeAnalyticsLine = OneDimension.AnalyticsLine_;
		Else
			SourceAnalyticsLine = OneDimension.AnalyticsLine_;
			SourceCodeAnalyticsLine = AnalyticsLine_;
		EndIf;
		
		FillInActualDataAttributes(ActualDataLine, SelectionCorrespondence, RuleDescription_);
		CompleteActualDataAnalytics(ActualDataLine, SourceAnalyticsLine, SourceCodeAnalyticsLine, RuleDescription_);
		FillInActualDataResources(ActualDataLine, SelectionCorrespondence, StringOfResourceValues, FactGettingParameters, RuleDescription_);
		
		ResourcesStringIndex = ResourcesStringIndex + 1;
	EndDo;
	
EndProcedure

Procedure AllocateResourcesForComplexAnalytics(ResourcesValues, ValuesOfCorOfResources)
	
	StringOfResourceValues = ResourcesValues[0];
	ManDistributionCoefficients = ValuesOfCorOfResources.UnloadColumn("SumMan");
	LocalDistributionCoefficients = ValuesOfCorOfResources.UnloadColumn("SumCompl");
	
	If ValuesOfCorOfResources.Total("SumMan") = 0 Then
		ManDistributionCoefficients = LocalDistributionCoefficients;
	EndIf;
	
	If ValuesOfCorOfResources.Total("SumCompl") = 0 Then
		LocalDistributionCoefficients = ManDistributionCoefficients;
	EndIf;
	
	For Each Column In ValuesOfCorOfResources.Columns Do
		If Column.ValueType.ContainsType(Type("Number")) Then
			ResourceValue = StringOfResourceValues[Column.Name];
			DistributionAccuracy = Column.ValueType.NumberQualifiers.FractionDigits;
			
			If Column.Name = "SumCompl" Then
				DistributionCoefficients = LocalDistributionCoefficients;
			Else
				DistributionCoefficients = ManDistributionCoefficients;
			EndIf;
			
			If ResourceValue <> 0 Then
				ResourceAllocation = CommonClientServer.DistributeAmountInProportionToCoefficients(
					ResourceValue, DistributionCoefficients, DistributionAccuracy);
			Else
				ResourceAllocation = Undefined;
			EndIf;
			
			If ResourceAllocation = Undefined Then
				ValuesOfCorOfResources.FillValues(0, Column.Name);
			Else
				ValuesOfCorOfResources.LoadColumn(ResourceAllocation, Column.Name);
			EndIf;
		EndIf;
	EndDo;
	
	ValuesOfCorOfResources.FillValues(StringOfResourceValues.Currency, "Currency");
	
EndProcedure

Function NewValuesOfIndicatorResources(FactGettingParameters)
	
	DescriptionAmountType = Common.TypeDescriptionNumber(
		FactGettingParameters.LengthOfSum, FactGettingParameters.SumAccuracy);
	DescriptionOfQuantityType = Common.TypeDescriptionNumber(
		FactGettingParameters.LengthOfQuantity, FactGettingParameters.QuantityAccuracy);
	
	ResourcesValues = New ValueTable();
	ResourcesValues.Columns.Add("SumMan", DescriptionAmountType);
	ResourcesValues.Columns.Add("SumCompl", DescriptionAmountType);
	ResourcesValues.Columns.Add("SumCurr", DescriptionAmountType);
	ResourcesValues.Columns.Add("Count", DescriptionOfQuantityType);
	ResourcesValues.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	Return ResourcesValues;
	
EndFunction

#EndRegion

#EndRegion
