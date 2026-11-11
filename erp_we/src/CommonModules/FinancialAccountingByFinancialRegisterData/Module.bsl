#Region Public

// Adds the reflection parameters necessary for generating transactions in operational accounting registers.
// 
// Parameters:
// 	 ParametersForGeneratingTransactions - See FinancialAccountingPostingServer.ParametersForGeneratingTransactions
//
Procedure AddParametersForGeneratingTransactions(ParametersForGeneratingTransactions) Export
	
	If Not GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		Return;
	EndIf;
	
	ParametersForGeneratingTransactions.CollapseTransactionTable = True;
	ParametersForGeneratingTransactions.RemoveInsignificantTransactions = True;
	
EndProcedure

// Generates international accounting transactions based on the data from operational accounting registers.
// 
// Parameters:
// 	ParametersForGeneratingTransactions - Structure - Parameters for generating transactions.
// 	TableOfTransactions - ValueTable - The table that the generated transactions are added to.
//
Procedure Reflect(ParametersForGeneratingTransactions, TableOfTransactions) Export
	
	If Not GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		Return;
	EndIf;
	
	QueryOptions = ParametersForRequestingFinancialRegisterData();
	Query = RequestingDataFromFinancialRegisters(QueryOptions, ParametersForGeneratingTransactions.TempTablesManager);
	RequestTextsForRegisterEntries = RequestTextsForRegisterEntries(Query);
	
	If RequestTextsForRegisterEntries.Count() = 0 Then
		Return;
	EndIf;
	
	QueriesTexts = New Array();
	QueriesTexts.Add(RequestTextForCorrespondenceRecords(RequestTextsForRegisterEntries));
	
	GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts);
	
	AllocateUnbalancedCorrespondenceResources(Query, QueriesTexts);

	DistributeCorrespondenceByMaturityDates(Query, QueriesTexts);
	
	DefineCorrespondenceAccountsForObjects(Query, QueriesTexts);
	
	CheckCorrespondenceErrors(Query, QueriesTexts, TableOfTransactions, ParametersForGeneratingTransactions);
	
	CreateTableOfRegisteredRecordsOfServiceAccountingObjects(Query, QueriesTexts);
	
	DefineAccountsForIndividualCorrespondence(Query, QueriesTexts, RequestTextsForRegisterEntries);
	
	DeleteUnansweredCorrespondence(Query, QueriesTexts);
	
	GenerateCorrespondenceAnalyticsRequests(Query, QueriesTexts, RequestTextsForRegisterEntries);
	
	FinancialAccountingByBalanceSheetRegisterData.DestroyTemporaryTables(Query, QueriesTexts);
	
	FillInTransactionTable(Query, QueriesTexts, TableOfTransactions, ParametersForGeneratingTransactions);
	
EndProcedure

// Supplements the document registration tables to be reflected in international accounting according to Registered Records in financial registers.
// 
// Parameters:
// 	Object - DocumentObject - The document that is being held.
// 	AdditionalProperties - Structure - Additional properties of the RS are reflected in documentsinternational Accounting.
// 	RegistrationTable - ValueTable - A table with registration data for reflection, which needs to be supplemented:
// 	                      * Period - Date - registration period (document date)
// 	                      * Organization - CatalogRef.Companies - the organization for which the document generates transactions
// 	                      * DateRecord - Date - the date on which the document forms of the transaction;
// 	                      * BusinessOperation - EnumRef.BusinessTransactions - of reflected economic operation.
//
Procedure AddRegistrationTablesToReflection(Object, AdditionalProperties, RegistrationTable) Export
	
	If Not GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		Return;
	EndIf;
	
	DocumentType = TypeOf(Object.Ref);
	CommandOperationalAccountingDocuments = Metadata.DataProcessors.DocumentPostingInFinancialAccounting.Commands.AccountingEntries; 
	If Not CommandOperationalAccountingDocuments.CommandParameterType.ContainsType(DocumentType) Then
		Return;	
	EndIf;
	
	TableReflectionOfDocumentsInInternationalAccounting = Undefined;
	TableReflectionOfDocumentsInInternationalAccountingIsTransferred = 
		AdditionalProperties.Property("TableReflectionOfDocumentsInInternationalAccounting", TableReflectionOfDocumentsInInternationalAccounting);
	
	If TableReflectionOfDocumentsInInternationalAccountingIsTransferred  Then 
		// A data table for registration was prepared in the manager module.
		CommonClientServer.SupplementTable(TableReflectionOfDocumentsInInternationalAccounting, RegistrationTable);
	Else
		ToSupplementRegistrationTableAccordingToFinancialRegisters(Object, RegistrationTable);
	EndIf;
	
EndProcedure

// Checks whether there are configured invoice matches that are required to reflect documents. 
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - Contains a temporary table documentreflection:
// 	              * Document - DocumentRef - reflected document
// 	              * Organization - CatalogRef.Companies - reflected organization
// 	              * PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - current transaction generation setting as of the date of reflection
// 	CheckParameters - See DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCheckingReflectionRules
// 	
// Returns:
// 	ValueTable - Table of required settings:
// 	              * AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems -
// 	              * SettingObject1 - DefinedType.ObjectForSettingUpFinancialAccountingAccounts
// 	              * ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts -
// 	              * PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - 
//
Function CheckRecordingRules(TempTablesManager, CheckParameters) Export
	
	ErrorsTable = New ValueTable;
	
	If Not GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		Return ErrorsTable;
	EndIf;
	
	ErrorsTable.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	ErrorsTable.Columns.Add("SettingObject1", Metadata.DefinedTypes.ObjectForSettingUpFinancialAccountingAccounts.Type);
	ErrorsTable.Columns.Add("ChartOfAccounts", New TypeDescription("CatalogRef.FinancialAccountingChartsOfAccounts"));
	ErrorsTable.Columns.Add("PostingGenerationSetting", New TypeDescription("CatalogRef.FinancialAccountingPostingGenerationSetting"));
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	ObjectsToConfigure.AccountingObject,
	|	ObjectsToConfigure.SettingObject1,
	|	ObjectsToConfigure.ChartOfAccounts,
	|	ObjectsToConfigure.PostingGenerationSetting
	|FROM
	|	InformationRegister.FinancialAccountingAccountsThatRequireSettings AS ObjectsToConfigure
	|WHERE
	|	(ChartOfAccounts, PostingGenerationSetting, Document) IN
	|		(SELECT
	|			DocumentsToBeReflected.ChartOfAccounts,
	|			DocumentsToBeReflected.PostingGenerationSetting,
	|			DocumentsToBeReflected.Recorder
	|		FROM
	|			DocumentsToBeReflected AS DocumentsToBeReflected
	|		) 
	|";
	
	ErrorsTable = Query.Execute().Unload();
	
	Return ErrorsTable;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions
// 
Procedure CustomizeReportsOptions(Settings) Export
	
	Reports.AnalysisOfTransactionsOfOperationalAccounting.CustomizeReportOptions(Settings);
	Reports.AnalysisOfOperationalAccountingCorrespondence.CustomizeReportOptions(Settings);
	
EndProcedure

// Returns an indication of the use of dividing assets and liabilities into short-term and long-term by the terms of circulation.
// 
// Parameters:
//  Companies - CatalogRef.Companies, Array of CatalogRef.Companies - organizations for which the analysis is performed
//  Period - Date - the date on which the analysis is performed
// 
// Returns:
//  Boolean - a sign of the use of the division of assets and liabilities by the terms of circulation.
//
Function AllocationOfLongTermAssetsAndLiabilitiesIsUsed(Companies, Period) Export
	
	AllocationOfLongTermAssetsAndLiabilitiesIsUsed =
		GetFunctionalOption("UseFinancialAccounting")
		And GetFunctionalOption("SettingOfPostingByAccountingObjects");
	
	If AllocationOfLongTermAssetsAndLiabilitiesIsUsed Then
		QueryText = "
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(
		|		&Period,
		|		Organization IN (&Companies)
		|	) AS FinancialAccountingChartsOfAccounts
		|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
		|		&Period,
		|		Organization IN (&Companies)
		|	) AS FinancialAccountingPolicy
		|	ON FinancialAccountingChartsOfAccounts.Organization = FinancialAccountingPolicy.Organization
		|WHERE
		|	FinancialAccountingChartsOfAccounts.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities
		|	AND FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("Period", Period);
		Query.SetParameter("Companies", TMCommonUseClientServer.Array(Companies));
		AllocationOfLongTermAssetsAndLiabilitiesIsUsed = Not Query.Execute().IsEmpty();
	EndIf;
	
	Return AllocationOfLongTermAssetsAndLiabilitiesIsUsed;
	
EndFunction

// Delete after switching to 8.3.20. Replace with the query language function STRING()
// Uses the standard Attributes of the string number register as the string identifier, converting from the Number type to the String type.
// It is used to identify register entries if the Attribute of the ID of the financial record is filled in with the value
// of the unique identifier of the settlement object and the Attribute of the line IDENTIFIER is missing.
//
// Parameters:
//  ReflectionParameters - See ParametersOfRegisteringRecordedMovementsInInternationalAccounting
//
Procedure UseLineNumberAsLineId(ReflectionParameters) Export
	
	ConversionStrings = New Array();
	MaximumNumberOfDigits = 6;
	
	For DigitNumber = 1 To MaximumNumberOfDigits Do
		StringConversion = StrReplace(
			"SUBSTRING(""0123456789"", SECOND(DATEADD(DATETIME(1, 1, 1), SECOND, DataSourceAlias.LineNumber * &Multiplier)) / 6 + 1, 1)",
			"&Multiplier",
			Format(6 * Pow(10, 1 - DigitNumber), "NDS=.; NG=0"));
		ConversionStrings.Insert(0, StringConversion);
	EndDo;
	
	Separator = Chars.LF + Chars.Tab + "+ ";
	
	ReflectionParameters.DataPathRowId = StrReplace(
		StrConcat(ConversionStrings, Separator),
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
EndProcedure

#EndRegion

#Region Internal

// Returns the structure of parameters for reflecting records of Accumulation registers in international accounting.
// 
// Parameters:
//  RegisterName - String - name of the Accumulation register - data source
//  RegisterMetadata - MetadataObjectAccumulationRegister - metadata of the Accumulation register - data source
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
// 
// Returns:
//  See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersOfRegisteringRecordedMovementsInInternationalAccounting(RegisterName, RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	RegisterManager = AccumulationRegisters[RegisterName]; // AccumulationRegisterManager -
	AccountingReflectionParameters = RegisterManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata, RegistrationForReflection); // See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
	
	If RegistrationForReflection Then
		Return AccountingReflectionParameters;
	EndIf;
	
	CurrentExtdimension = FinancialAccountingServerCached.CurrentExtdimension();
	AnalyticsSourcesAttributes = New Array();
	
	For Each AttributeDetails In AccountingReflectionParameters.AttributesDetails1 Do
		FieldName = AttributeDetails.Key;
		FieldDetails = AttributeDetails.Value;
		AddAttributesToAnalyticsSources = False;
		
		For Each CirculatingExtdimension In CurrentExtdimension Do
			If FieldDetails.Type = CirculatingExtdimension.ValueType Then
				AddAttributesToAnalyticsSources = True;
			Else
				TypesOfExtdimension = CirculatingExtdimension.ValueType.Types();
				For Each ExtDimensionType In TypesOfExtdimension Do
					If FieldDetails.Type.ContainsType(ExtDimensionType) Then
						AddAttributesToAnalyticsSources = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If AddAttributesToAnalyticsSources Then
				Break;
			EndIf;
		EndDo;
		
		If AddAttributesToAnalyticsSources Then
			AccountingReflectionParameters.DimensionsDetails.Insert(FieldName, Common.CopyRecursive(FieldDetails));
			AnalyticsSourcesAttributes.Add(FieldName);
		EndIf;
	EndDo;
	
	For Each FieldName In AnalyticsSourcesAttributes Do
		AccountingReflectionParameters.AttributesDetails1.Delete(FieldName);
	EndDo;
	
	Return AccountingReflectionParameters;
	
EndFunction

// Adds a description of the selection by type of registrar to the parameters for reflecting Registered Records of the Accumulation register
// in international accounting.
// 
// Parameters:
//  AccountingReflectionParameters - See ParametersOfRegisteringRecordedMovementsInInternationalAccounting
//
Procedure AddSelectionByRegistrarType(AccountingReflectionParameters) Export
	
	DescriptionOfLoggerField = AccountingReflectionParameters.AttributesDetails1.Recorder;
	
	DescriptionOfRegisterField = FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField();
	DescriptionOfRegisterField.DataPath = "VALUETYPE(" + DescriptionOfLoggerField.DataPath + ")"; //@query-part
	DescriptionOfRegisterField.Title = NStr("vi = 'Kiểu nguồn ghi';
											|ru = 'Тип регистратора';
											|en = 'Recorder type'; fa = 'نوع ثبت‌کننده';
											|it = 'Tipo di registratore';
											|pl = 'Typ rejestratora';
											|tr = 'Kaydedici türü'");
	DescriptionOfRegisterField.Type = New TypeDescription("Type");
	
	AccountingReflectionParameters.AttributesDetails1.Insert("TypeOfRegistrar", DescriptionOfRegisterField);
	
EndProcedure

// Returns the manager of temporary tables with the balances of accumulation registers to be reclassified from
// long-term to short-term in the transferred period. The names of temporary tables in the manager correspond
// to the names of accumulation registers. Empty temporary tables are destroyed.
// 
// Parameters:
//  Companies - CatalogRef.Companies, Array of CatalogRef.Companies - organizations for which the balance analysis is performed
//  Period - Date - date of the month in which the balance analysis takes place 
// 
// Returns:
//  TempTablesManager - manager of temporary tables with reclassifiable balances of accumulation registers.
//
Function DataOnReclassificationOfNonCurrentAssetsLiabilities(Companies, Period) Export
	
	BalanceFinancialRegisters = BalanceFinancialRegisters();
	MetadataAccumulationRegisters = Metadata.AccumulationRegisters;
	
	QueriesTexts = New Array();
	
	For Each RegisterName In BalanceFinancialRegisters Do
		RegisterMetadata = MetadataAccumulationRegisters[RegisterName];
		AccountingReflectionParameters = ParametersOfRegisteringRecordedMovementsInInternationalAccounting(RegisterName, RegisterMetadata);
		
		If AccountingReflectionParameters.AllocationOfLongTermAssetsAndLiabilities Then
			QueriesTexts.Add(FinancialAccountingByFinancialRegisterDataInternal.TextOfRequestForBalancesForReclassification(RegisterName));
		EndIf;
	EndDo;
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueriesTexts.Clear();
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));
	Query.SetParameter("PeriodBoundary", New Boundary(EndOfMonth(Period), BoundaryType.Including));
	Query.SetParameter("CompanyArray", TMCommonUseClientServer.Array(Companies));
	Query.Execute();
	
	For Each TempTable In Query.TempTablesManager.Tables Do
		QueryText = "
		|SELECT TOP 1
		|	""&TableName"" AS TableName
		|FROM
		|	&TableName
		|";
		QueryText = StrReplace(QueryText, "&TableName", TempTable.FullName);
		QueriesTexts.Add(QueryText);
	EndDo;
	
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	QueriesTexts.Clear();
	
	Result = Query.Execute();
	TablesWithData = Result.Unload().UnloadColumn("TableName");
	
	For Each TempTable In Query.TempTablesManager.Tables Do
		If TablesWithData.Find(TempTable.FullName) = Undefined Then
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, TempTable.FullName);
		EndIf;
	EndDo;
	
	If QueriesTexts.Count() > 0 Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.Execute();
	EndIf;
	
	Return Query.TempTablesManager;
	
EndFunction

// Returns organizations for which there are balances in the accumulation registers that are subject to reclassification from
// long-term to short-term in the transferred period.
// 
// Parameters:
//  Companies - CatalogRef.Companies, Array of CatalogRef.Companies - organizations for which the balance analysis is performed
//  Period - Date - date of the month in which the balance analysis takes place 
// 
// Returns:
//  Array of CatalogRef.Companies - organizations for which there are reclassifiable balances of accumulation registers.
//
Function OrganizationsReclassifyingNonCurrentAssetsLiabilities(Companies, Period) Export
	
	ReclassificationOrganizations = New Array();
	TempTablesManager = DataOnReclassificationOfNonCurrentAssetsLiabilities(Companies, Period);
	
	If TempTablesManager.Tables.Count() = 0 Then
		Return ReclassificationOrganizations;
	EndIf;
	
	MetadataAccumulationRegisters = Metadata.AccumulationRegisters;
	QueriesTexts = New Array();
	
	For Each TempTable In TempTablesManager.Tables Do
		RegisterName = TempTable.FullName;
		RegisterMetadata = MetadataAccumulationRegisters[RegisterName];
		AccountingReflectionParameters = ParametersOfRegisteringRecordedMovementsInInternationalAccounting(RegisterName, RegisterMetadata);
		
		QueryText = "
		|SELECT
		|	&Organization AS Organization
		|FROM
		|	&TableName AS RegisterTable
		|GROUP BY
		|	&Organization
		|";
		
		QueryText = StrReplace(QueryText, "&Organization", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(AccountingReflectionParameters.DataPathOrganization));
		QueryText = StrReplace(QueryText, "&TableName", TempTable.FullName);
		
		QueriesTexts.Add(QueryText);
	EndDo;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin(True));
	
	Result = Query.Execute();
	ReclassificationOrganizations = Result.Unload().UnloadColumn("Organization");
	
	Return ReclassificationOrganizations;
	
EndFunction

// Adds request texts to the transmitted array for generating transactions for the reclassification
// of accumulation register balances
// 
// Parameters:
// 	QueriesTexts - Array of String - the array of query texts to be filled in
// 	TempTablesManager - TempTablesManager - the manager of temporary tables obtained in the data classification function of long-term activitiesreferences()
//
Procedure AddTextsOfRequestsForReclassificationOfNonCurrentAssetsLiabilities(QueriesTexts, TempTablesManager) Export
	
	TemporaryTableNames = New Array();
	
	For Each TempTable In TempTablesManager.Tables Do
		TemporaryTableNames.Add(TempTable.FullName);
	EndDo;
	
	For Each TempTableName In TemporaryTableNames Do
		TMCommonUse.AddIDsToTemporaryTable(TempTableName, TempTablesManager, "FinRecordID");
		QueriesTexts.Add(FinancialAccountingByFinancialRegisterDataInternal.TextOfRequestForReclassificationOfBalances(TempTableName));
	EndDo;
	
EndProcedure

// Returns a description of the fields of the data source of the accounting object that can be used to fill in the ExtDimension.
// The composition of the fields is filled in with all dimensions of the data source and Attributes corresponding to the negotiable ExtDimension.
// 
// Parameters:
//  RegisterName - String - Name of the data source register
//  AccountingReflectionParameters - See ParametersOfRegisteringRecordedMovementsInInternationalAccounting
//  
// Returns:
//  Structure of KeyAndValue - LongDesc:
//   * Key - String - The name of the register dimension, the name of the Attribute of the dimension - the analytics key, or the name of the register Attribute
//   * Value - See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
//
Function SourcesOfFinancialRegisterAnalytics(RegisterName, AccountingReflectionParameters = Undefined) Export
	
	If AccountingReflectionParameters = Undefined Then
		AccountingReflectionParameters = ParametersOfRegisteringRecordedMovementsInInternationalAccounting(RegisterName);
	EndIf;
	
	SourcesOfAnalytics = Common.CopyRecursive(AccountingReflectionParameters.DimensionsDetails);
	
	Return SourcesOfAnalytics;
	
EndFunction

// Returns a description of all available fields of the accounting object's data source.
// 
// Parameters:
//  RegisterName - String - Name of the data source register
//  AccountingReflectionParameters - See ParametersOfRegisteringRecordedMovementsInInternationalAccounting
//  
// Returns:
//  Structure of KeyAndValue - LongDesc:
//   * Key - String - The name of the register dimension, the name of the Attribute of the dimension - the analytics key, or the name of the register Attribute
//   * Value - See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
//
Function DescriptionOfFinancialRegisterFields(RegisterName, AccountingReflectionParameters = Undefined) Export
	
	FieldsDetails = SourcesOfFinancialRegisterAnalytics(RegisterName, AccountingReflectionParameters);
	
	AcceptableAttributes = New Array();
	AcceptableAttributes.Add("Recorder");
	AcceptableAttributes.Add("TypeOfRegistrar");
	AcceptableAttributes.Add("BusinessTransactionSetting");
	
	For Each FieldName In AcceptableAttributes Do
		FieldDetails = Undefined;
		If AccountingReflectionParameters.AttributesDetails1.Property(FieldName, FieldDetails) Then
			FieldsDetails.Insert(FieldName, Common.CopyRecursive(FieldDetails));
		EndIf;
	EndDo;
	
	Return FieldsDetails;
	
EndFunction

// Returns a list of fields of the accounting object's data source that can be used to fill in a subconto of a certain type.
// The most appropriate fields by type will be at the top of the list.
// 
// Parameters:
// 	ExtdimensionValueType - TypeDescription - Sub-konto type
// 	DescriptionOfAccountingObject_ - See ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject 
// 	Prefix - String - an arbitrary prefix that is appended to the field name. For example, " ObjectAccouNt"
// Returns:
// 	ValueList of ValueListItem - LongDesc:
//		* Value - String - Field name, including the prefix
//		* Presentation - String - Data path
//
Function PossibleExtdimensionFields(ExtdimensionValueType, DescriptionOfAccountingObject_, Prefix = "") Export
	
	Result = New ValueList();
	
	If DescriptionOfAccountingObject_ = Undefined Then
		Return Result;
	EndIf;
	
	RegisterFieldsDetails = ExtdimensionRegisterFields(ExtdimensionValueType, DescriptionOfAccountingObject_.DataSource);
	For Each FieldDetails In RegisterFieldsDetails Do
		Result.Add(?(IsBlankString(Prefix), "", Prefix + ".") + FieldDetails.FieldName, FieldDetails.DataPath);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a structure for setting the values of the parameters for requesting financial register data,
// including from the reports of the analysis of the correspondence of the operational accounting and the analysis of the transaction of the operational accounting.
// 
// Returns:
//  Structure:
//   * StartDate - Date - start date of the report creation
//   * EndDate - Date - end date of the report creation
//   * ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts, Array of CatalogRef.FinancialAccountingChartsOfAccounts - selection according to the plan or plans of accounts
//   * Recorder - DocumentRef, Array of DocumentRef - selection by document or documents
//   * Organization - CatalogRef.Companies, Array of CatalogRef.Companies - selection by organization or organizations
//   * AccountingObjectDr - ChartOfCharacteristicTypesRef.AssetLiabilityItems - selection by debit accounting object
//   * AccountingObjectCr - ChartOfCharacteristicTypesRef.AssetLiabilityItems - selection by credit accounting object
//   * TypeOfRegistrar - Array of Type - selection by collections of different types of documents
//   * NotReflectedInAccounting - Boolean, Undefined - indication of the installation of the selection of documents not reflected in the MFPs
//   * AdditionalSelection - DataCompositionFilter - selection of fixed linker settings for data layout settings
//   * VariantKey - String - name of the report variant
//
Function ParametersForRequestingFinancialRegisterData() Export
	
	QueryOptions = FinancialAccountingByBalanceSheetRegisterData.ParametersForRequestingFinancialRegisterData();
	
	QueryOptions.Insert("ChartOfAccounts", Undefined);
	QueryOptions.Insert("NotReflectedInAccounting", Undefined);
	QueryOptions.Insert("VariantKey", Undefined);
	
	Return QueryOptions;
	
EndFunction

// Returns a request to run the reports Analysis of the responsiveness of the operational accounting and analysis of the operational accounting.
// Accepts at the input the values of parameters according to which selection should be set in the generated query
// or restrictions should be imposed on the composition of the selection tables when forming query texts.
// 
// Parameters:
//  QueryOptions - See ParametersForRequestingFinancialRegisterData
// 
// Returns:
//  Query
//
Function RequestForAnalysisOfCorrespondenceOfOperationalAccounting(QueryOptions) Export
	
	TempTablesManager = New TempTablesManager();
	AdditionalSelection = QueryOptions.AdditionalSelection; // DataCompositionFilter -
	ThereIsAdditionalSelection = AdditionalSelection.Items.Count() > 0;
	
	Query = RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager);
	
	If Query.Parameters.RevenueExcludingVAT = Undefined
		And QueryOptions.VariantKey = "ErrorsInOnlineAccountingTransactions" Then
		Query.Parameters.RevenueExcludingVAT = True;
	EndIf;
	
	RequestTextsForRegisterEntries = RequestTextsForRegisterEntries(Query);
	
	If RequestTextsForRegisterEntries.Count() = 0 Then
		QueryText = Reports.AnalysisOfOperationalAccountingCorrespondence.Create().DataCompositionSchema.DataSets.RecordsSet.Query;
		
		If QueryOptions.VariantKey = "CorrespondenceAnalysisChessBulletin"
		 Or QueryOptions.VariantKey = "AnalysisOfCorrespondenceOnDocuments" Then
			Query.Text = QueryText;
		Else
			FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(QueryText,,, "TTSetOfRegisteredRecords");
			Query.Text = QueryText;
			Query.Execute();
		EndIf;
		
		Return Query;
	EndIf;
	
	QueriesTexts = New Array();
	QueriesTexts.Add(RequestTextForCorrespondenceRecords(RequestTextsForRegisterEntries));
	
	GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts);
	
	AllocateUnbalancedCorrespondenceResources(Query, QueriesTexts);
	
	DistributeCorrespondenceByMaturityDates(Query, QueriesTexts);
	
	If QueryOptions.VariantKey = "ErrorsInOnlineAccountingTransactions" Then
		
		QueriesTexts.Add(QueryTextCorrespondenceErrorAnalysis(QueryOptions));
		
	ElsIf QueryOptions.VariantKey = "CorrespondenceAnalysisChessBulletin"
		Or QueryOptions.VariantKey = "AnalysisOfCorrespondenceOnDocuments" Then
		
		DefineCorrespondenceAccountsForObjects(Query, QueriesTexts);
		
	Else
		
		DefineCorrespondenceAccountsForObjects(Query, QueriesTexts);
		
		SkipCorrespondenceErrorChecking(QueriesTexts);
		
		CreateTableOfRegisteredRecordsOfServiceAccountingObjects(Query, QueriesTexts);
		
		DefineAccountsForIndividualCorrespondence(Query, QueriesTexts, RequestTextsForRegisterEntries);
		
		DeleteUnansweredCorrespondence(Query, QueriesTexts);
		
		QueriesTexts.Add(RequestTextFullCorrespondenceAnalysis());
		
	EndIf;
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueriesTexts.Clear();
	Query.Execute();
	
	If QueryOptions.VariantKey = "CorrespondenceAnalysisChessBulletin" Then
		Query.Text = RequestTextAnalysisOfCorrespondenceForConfiguration();
	ElsIf QueryOptions.VariantKey = "AnalysisOfCorrespondenceOnDocuments" Then
		If ThereIsAdditionalSelection Then
			PrepareCorrespondenceAnalysisRequestForConfigurationWithSelection(Query, QueriesTexts,
				RequestTextsForRegisterEntries, QueryOptions.AdditionalSelection);
		Else
			Query.Text = RequestTextAnalysisOfCorrespondenceForConfiguration();
		EndIf;
	EndIf;
	
	Return Query;
	
EndFunction

// Returns the structure of the financial accounting settings with the set property values in accordance
// with the transmitted Entry generation settings.
// 
// Parameters:
//  TransactionGenerationSettings - See Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings
// 
// Returns:
//  See ChartsOfCharacteristicTypes.AssetLiabilityItems.FinancialAccounting_Settings
//
Function AccountingSettingsByTransactionGenerationSettings(TransactionGenerationSettings) Export
	
	AccountingSettings = ChartsOfCharacteristicTypes.AssetLiabilityItems.FinancialAccounting_Settings();
	
	If TransactionGenerationSettings.OptionForGeneratingTransactions = Undefined
	 Or TransactionGenerationSettings.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		AccountingSettings.FormationOfCorrespondence = True;
	Else
		AccountingSettings.FormationOfCorrespondence = False;
	EndIf;
	
	If TransactionGenerationSettings.MethodOfAccountingForImproperValues = Undefined
	 Or TransactionGenerationSettings.MethodOfAccountingForImproperValues = Enums.MethodsOfNotOwnedControlledValuesAccounting.RecordedOnOffBalanceAccounts Then
		AccountingSettings.AccountingForImproperValues = True;
	Else
		AccountingSettings.AccountingForImproperValues = False;
	EndIf;
	
	If TransactionGenerationSettings.RevenueExcludingVAT = True
	 Or TransactionGenerationSettings.RevenueExcludingVAT = Undefined Then
		AccountingSettings.RevenueAccountingExcludingVAT = True;
	Else
		AccountingSettings.RevenueAccountingExcludingVAT = False;
	EndIf;
	
	If TransactionGenerationSettings.RevenueExcludingVAT = False
	 Or TransactionGenerationSettings.RevenueExcludingVAT = Undefined Then
		AccountingSettings.RevenueAccountingWithVAT = True;
	Else
		AccountingSettings.RevenueAccountingWithVAT = False;
	EndIf;
	
	Return AccountingSettings;
	
EndFunction

#EndRegion

#Region Private

Procedure ToSupplementRegistrationTableAccordingToFinancialRegisters(Document, RegistrationTable)

	DescriptionOfRegisters = ParametersOfReflectionOfRegisteredRecordsOfFinancialRegisters(Document, True);
	TextsOfRegistrationRequests = New Array;
	
	For Each KeyAndValue In DescriptionOfRegisters Do
		RegisterName = KeyAndValue.Key;
		LongDesc = KeyAndValue.Value;
		
		If IsBlankString(LongDesc.DataPathOrganization) Then
			Continue;
		EndIf;
		
		QueryText = 
		"SELECT DISTINCT
		|	Period AS DateRecord,
		|	&Organization AS Organization,
		|	BusinessTransactionSetting.BusinessOperation AS BusinessOperation
		|FROM
		|	&FullRegisterName AS RegisterTable
		|WHERE
		|	&Recorder = &Ref
		|";
		QueryText = StrReplace(QueryText, "&FullRegisterName", StrTemplate("AccumulationRegister.%1", RegisterName));
		QueryText = StrReplace(QueryText, "&Organization", LongDesc.DataPathOrganization);
		QueryText = StrReplace(QueryText, "&Recorder", LongDesc.DataPathLogger);
		TextsOfRegistrationRequests.Add(QueryText);
	EndDo;
	
	If TextsOfRegistrationRequests.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = StrConcat(TextsOfRegistrationRequests, TMCommonUse.QuerySeparatorInJoin(True));
	Query.SetParameter("Ref", Document.Ref);
	CommonClientServer.SupplementTable(Query.Execute().Unload(), RegistrationTable);
	
EndProcedure

Function ParametersOfReflectionOfRegisteredRecordsOfFinancialRegisters(Document, RegistrationForReflection = False)
	
	ParametersOfReflectionOfRegisterRegisteredRecords = New Structure;
	
	BalanceFinancialRegisters = BalanceFinancialRegisters();
	MetadataAccumulationRegisters = Metadata.AccumulationRegisters;
	TypeOfDocumentMotionCollection = TypeOf(Document.RegisterRecords);
	
	For Each RegisterName In BalanceFinancialRegisters Do
		If RegisterName = MetadataAccumulationRegisters.CustomersARAPAccountingByDueDates.Name Then
			NameOfMotionCheckRegister = MetadataAccumulationRegisters.CustomersARAPAccounting.Name;
		ElsIf RegisterName = MetadataAccumulationRegisters.VendorsARAPAccountingByDueDates.Name Then
			NameOfMotionCheckRegister = MetadataAccumulationRegisters.VendorsARAPAccounting.Name;
		Else
			NameOfMotionCheckRegister = RegisterName;
		EndIf;
		
		If TypeOfDocumentMotionCollection = Type("Structure")
			And Not Document.RegisterRecords.Property(NameOfMotionCheckRegister) Then
			Continue;
		ElsIf TypeOfDocumentMotionCollection = Type("RegisterRecordsCollection")
			And Document.RegisterRecords.Find(NameOfMotionCheckRegister) = Undefined Then
			Continue;
		EndIf;
		
		RegisterMetadata = MetadataAccumulationRegisters[RegisterName];
		AccountingReflectionParameters = ParametersOfRegisteringRecordedMovementsInInternationalAccounting(RegisterName, RegisterMetadata, RegistrationForReflection);
		ParametersOfReflectionOfRegisterRegisteredRecords.Insert(RegisterName, AccountingReflectionParameters);
	EndDo;
	
	Return ParametersOfReflectionOfRegisterRegisteredRecords;
	
EndFunction

Function BalanceFinancialRegisters(FinancialAccountingObjects = Undefined, AccountingSettings = Undefined)
	
	If FinancialAccountingObjects = Undefined Then
		If AccountingSettings = Undefined Then
			AccountingSettings = AccountingSettingsByTransactionGenerationSettings(
				Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings());
		EndIf;
		FinancialRegisters = ChartsOfCharacteristicTypes.AssetLiabilityItems.DataSourcesOfAccountingObjects(AccountingSettings);
	Else
		DataSources = FinancialAccountingObjects.Copy(, "DataSource");
		ServiceLines = DataSources.FindRows(New Structure("DataSource", ""));
		
		For Each ServiceLine In ServiceLines Do
			DataSources.Delete(ServiceLine);
		EndDo;
		
		DataSources.GroupBy("DataSource");
		FinancialRegisters = DataSources.UnloadColumn("DataSource");
	EndIf;
	
	Return FinancialRegisters;
	
EndFunction

Function ExtdimensionRegisterFields(ExtdimensionValueType, RegisterName)
	
	RegisterFields = New ValueTable();
	RegisterFields.Columns.Add("FieldName", Common.StringTypeDetails(150));
	
	If RegisterName = "" Then
		Return RegisterFields;
	EndIf;
	
	DescriptionOfRegisterField = FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField();
	For Each KeyAndValue In DescriptionOfRegisterField Do
		ColumnName = KeyAndValue.Key;
		ColumnType = TypeOf(KeyAndValue.Value);
		RegisterFields.Columns.Add(ColumnName, New TypeDescription(CommonClientServer.ValueInArray(ColumnType)));
	EndDo;
	
	SourcesOfAnalytics = SourcesOfFinancialRegisterAnalytics(RegisterName);
	
	For Each KeyAndValue In SourcesOfAnalytics Do
		DescriptionOfSourceOfExtdimension = KeyAndValue.Value;
		If DescriptionOfSourceOfExtdimension.Type = ExtdimensionValueType Then
			NewRow = RegisterFields.Insert(0);
			NewRow.FieldName = KeyAndValue.Key;
			FillPropertyValues(NewRow, DescriptionOfSourceOfExtdimension);
		Else
			For Each Type In ExtdimensionValueType.Types() Do
				If DescriptionOfSourceOfExtdimension.Type.ContainsType(Type) Then
					NewRow = RegisterFields.Add();
					NewRow.FieldName = KeyAndValue.Key;
					FillPropertyValues(NewRow, DescriptionOfSourceOfExtdimension);
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return RegisterFields;
	
EndFunction

Function EmptyTypeValues(TypeDescription)
	
	BlankValues = New Array();
	
	For Each Type In TypeDescription.Types() Do
		BlankValues.Add(FinancialAccountingClientServer.EmptyTypeValue(Type));
	EndDo;
	
	If BlankValues.Count() > 1 Then
		BlankValues.Add(Undefined);
	EndIf;
	
	Return BlankValues;
	
EndFunction

#Region TextsOfCorrespondenceGenerationRequests

Function RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager)
	
	Query = FinancialAccountingByBalanceSheetRegisterData.RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager);
	
	SourcesWithDueDates = New ValueTable();
	SourcesWithDueDates.Columns.Add("DataSource", Common.StringTypeDetails(150)); // name of the source register of the accounting object
	SourcesWithDueDates.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	Query.SetParameter("SourcesWithDueDates", SourcesWithDueDates);
	
	SignsOfCorrespondenceAccounting = New ValueTable();
	SignsOfCorrespondenceAccounting.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	SignsOfCorrespondenceAccounting.Columns.Add("CorObjectOfAccounting", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	SignsOfCorrespondenceAccounting.Columns.Add("AccountingFlag", Common.StringTypeDetails(150));
	SignsOfCorrespondenceAccounting.Columns.Add("Value", New TypeDescription("Boolean"));
	Query.SetParameter("SignsOfCorrespondenceAccounting", SignsOfCorrespondenceAccounting);
	
	ObjectsOfImproperValues = New ValueTable();
	ObjectsOfImproperValues.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	Query.SetParameter("ObjectsOfImproperValues", ObjectsOfImproperValues);
	
	Query.SetParameter("AttributeOfAccountingRevenueWithoutVAT", "RevenueExcludingVAT");
	
	Query.SetParameter("AllocationOfLongTermAssetsAndLiabilities", False);
	Query.SetParameter("MethodOfAccountingForImproperValues", Undefined);
	Query.SetParameter("RevenueExcludingVAT", Undefined);
	
	Query.SetParameter("HowToApplySettingsForObjects", 9999);
	
	Query.SetParameter("AllExpressionsAreExtdimension", New Map());
	Query.SetParameter("AllKindsOfExtdimension", New Map());
	
	Query.SetParameter("ExtdimensionExpressionPrefixDr", "AccountingObjectDr");
	Query.SetParameter("ExtdimensionExpressionPrefixCr", "AccountingObjectCr");
	Query.SetParameter("LengthOfExpressionPrefixDr", StrLen(Query.Parameters.ExtdimensionExpressionPrefixDr));
	Query.SetParameter("LengthOfCrExpressionPrefix", StrLen(Query.Parameters.ExtdimensionExpressionPrefixCr));
	
	QuantityQualifiers = Metadata.AccountingRegisters.International.Resources.Count.Type.NumberQualifiers;
	Query.Parameters.LengthOfQuantity = QuantityQualifiers.Digits;
	Query.Parameters.QuantityAccuracy = QuantityQualifiers.FractionDigits;
	
	QueriesTexts = New Array();
	If TempTablesManager.Tables.Find("DocumentsToBeReflected") <> Undefined Then
		QueriesTexts.Add("
		|SELECT
		|	DocumentsToBeReflected.Recorder AS Recorder,
		|	DocumentsToBeReflected.Organization AS Organization,
		|	DocumentsToBeReflected.DateRecord AS DateRecord
		|INTO TTPortionOfDocuments
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected
		|
		|GROUP BY
		|	DocumentsToBeReflected.Recorder,
		|	DocumentsToBeReflected.Organization,
		|	DocumentsToBeReflected.DateRecord
		|INDEX BY
		|	Recorder,
		|	Organization,
		|	DateRecord
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	VALUETYPE(PortionOfDocuments.Recorder) AS TypeOfRegistrar
		|FROM
		|	TTPortionOfDocuments AS PortionOfDocuments
		|GROUP BY
		|	VALUETYPE(PortionOfDocuments.Recorder)
		|");
		
		QueriesTexts.Add("
		|SELECT DISTINCT
		|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	COUNT(DISTINCT ChartsOfAccounts.MethodOfNotOwnedControlledValuesAccounting) AS QuantityMethodOfAccountingForImproperValues,
		|	ISNULL(MAX(ChartsOfAccounts.MethodOfNotOwnedControlledValuesAccounting),
		|		VALUE(Enum.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts)) AS MethodOfAccountingForImproperValues,
		|	ISNULL(MAX(TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities), FALSE) AS AllocationOfLongTermAssetsAndLiabilities,
		|	COUNT(DISTINCT TransactionGenerationSettings.RevenueTransactionsExcludingVAT) AS QuantityRevenueExcludingVAT,
		|	ISNULL(MAX(TransactionGenerationSettings.RevenueTransactionsExcludingVAT), TRUE) AS RevenueExcludingVAT
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected
		|	INNER JOIN Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
		|		ON DocumentsToBeReflected.ChartOfAccounts = ChartsOfAccounts.Ref
		|	INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
		|		ON DocumentsToBeReflected.PostingGenerationSetting = TransactionGenerationSettings.Ref
		|");
		
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Results = Query.ExecuteBatch();
		
		Query.Parameters.TypeOfRegistrar = Results[1].Unload().UnloadColumn("TypeOfRegistrar");
		Query.Parameters.ChartOfAccounts = Results[2].Unload().UnloadColumn("ChartOfAccounts");
		
		SelectingTransactionSettings = Results[3].Select();
	Else
		QueriesTexts.Add("
		|SELECT
		|	ChartsOfAccounts.MethodOfNotOwnedControlledValuesAccounting AS MethodOfAccountingForImproperValues,
		|	TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities AS DivisionIntoShortTermLongTermAssetsAndLiabilities,
		|	TransactionGenerationSettings.RevenueTransactionsExcludingVAT AS RevenueTransactionsExcludingVAT
		|FROM
		|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS BusinessAccountPlans
		|	INNER JOIN Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
		|		ON BusinessAccountPlans.ChartOfAccounts = ChartsOfAccounts.Ref
		|	INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
		|		ON BusinessAccountPlans.PostingGenerationSetting = TransactionGenerationSettings.Ref
		|WHERE
		|	&ConditionPeriod
		|	AND &ChartOfAccountsCondition
		|	AND &OrganizationCondition
		|GROUP BY
		|	ChartsOfAccounts.MethodOfNotOwnedControlledValuesAccounting,
		|	TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities,
		|	TransactionGenerationSettings.RevenueTransactionsExcludingVAT
		|");
		
		If Query.Parameters.StartDate > '00010101' Then
			QueriesTexts.Add("
			|SELECT
			|	ChartsOfAccounts.MethodOfNotOwnedControlledValuesAccounting AS MethodOfAccountingForImproperValues,
			|	TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities AS DivisionIntoShortTermLongTermAssetsAndLiabilities,
			|	TransactionGenerationSettings.RevenueTransactionsExcludingVAT AS RevenueTransactionsExcludingVAT
			|FROM
			|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&StartDate,
			|		&ChartOfAccountsCondition
			|		AND &OrganizationCondition) AS BusinessAccountPlans
			|	INNER JOIN Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
			|		ON BusinessAccountPlans.ChartOfAccounts = ChartsOfAccounts.Ref
			|	INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
			|		ON BusinessAccountPlans.PostingGenerationSetting = TransactionGenerationSettings.Ref
			|GROUP BY
			|	ChartsOfAccounts.MethodOfNotOwnedControlledValuesAccounting,
			|	TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities,
			|	TransactionGenerationSettings.RevenueTransactionsExcludingVAT
			|");
		EndIf;
		
		QueryText = StrReplace("
			|SELECT
			|	COUNT(DISTINCT TransactionGenerationSettings.MethodOfAccountingForImproperValues) AS QuantityMethodOfAccountingForImproperValues,
			|	ISNULL(MAX(TransactionGenerationSettings.MethodOfAccountingForImproperValues),
			|		VALUE(Enum.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts)) AS MethodOfAccountingForImproperValues,
			|	ISNULL(MAX(TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities), FALSE) AS AllocationOfLongTermAssetsAndLiabilities,
			|	COUNT(DISTINCT TransactionGenerationSettings.RevenueTransactionsExcludingVAT) AS QuantityRevenueExcludingVAT,
			|	ISNULL(MAX(TransactionGenerationSettings.RevenueTransactionsExcludingVAT), TRUE) AS RevenueExcludingVAT
			|FROM
			|	&TransactionGenerationSettings AS TransactionGenerationSettings",
			"&TransactionGenerationSettings",
			"(" + StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
		
		QueryText = StrReplace(QueryText, "&ConditionPeriod", FinancialAccountingByBalanceSheetRegisterData.ConditionStringPeriod(Query.Parameters));
		QueryText = StrReplace(QueryText, "&ChartOfAccountsCondition", ConditionsLineChartOfAccounts(Query.Parameters));
		QueryText = StrReplace(QueryText, "&OrganizationCondition", FinancialAccountingByBalanceSheetRegisterData.OrganizationConditionLine(Query.Parameters));
		QueryText = StrReplace(QueryText, "&Period", "Period");
		QueryText = StrReplace(QueryText, "&ChartOfAccounts", "ChartOfAccounts");
		QueryText = StrReplace(QueryText, "&Organization", "Organization");
		QueryText = StrReplace(QueryText, "&RequestParameterChartOfAccounts", "&ChartOfAccounts");
		QueryText = StrReplace(QueryText, "&RequestParameterOrganization", "&Organization");
		
		Query.Text = QueryText;
		SelectingTransactionSettings = Query.Execute().Select();
	EndIf;
	
	SelectingTransactionSettings.Next();
	Query.Parameters.AllocationOfLongTermAssetsAndLiabilities = SelectingTransactionSettings.AllocationOfLongTermAssetsAndLiabilities;
	
	If SelectingTransactionSettings.QuantityMethodOfAccountingForImproperValues <= 1 Then
		Query.Parameters.MethodOfAccountingForImproperValues = SelectingTransactionSettings.MethodOfAccountingForImproperValues;
	EndIf;
	
	If SelectingTransactionSettings.QuantityRevenueExcludingVAT <= 1 Then
		Query.Parameters.RevenueExcludingVAT = SelectingTransactionSettings.RevenueExcludingVAT;
	EndIf;
	
	Return Query;
	
EndFunction

Function CaseRecordRequestTextTemplate()
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&RegisterName AS RegisterName,
	|	&AccountingObject AS AccountingObject,
	|	&SettingObject1 AS SettingObject1,
	|	&PlaceOfRegistration AS PlaceOfRegistration,
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
	|	&MaturityDate AS MaturityDate,
	|	&Currency AS Currency,
	|	&SumMan AS SumMan,
	|	&SumCompl AS SumCompl,
	|	&SumCurr AS SumCurr,
	|	&Count AS Count,
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
	|	AND &ConditionPropsStorno
	|GROUP BY
	|	&Period,
	|	&AccountingObject,
	|	&SettingObject1,
	|	&PlaceOfRegistration,
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
	|	&MaturityDate,
	|	&Currency,
	|	&PropsStorno
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextsForRegisterEntries(Query)
	
	RegisterRequestsTexts = New Structure();
	
	TransactionSettings = SettingsForGeneratingTransactionsBasedOnRequestParameters(Query.Parameters);
	AccountingSettings = AccountingSettingsByTransactionGenerationSettings(TransactionSettings);
	FinancialAccountingObjects = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObjects(AccountingSettings);
	
	BalanceFinancialRegisters = BalanceFinancialRegisters(FinancialAccountingObjects);
	ExcludeRegistersByLoggerMovementCollections(Query.Parameters, BalanceFinancialRegisters);
	
	ThereIsPortionOfDocuments = Query.TempTablesManager.Tables.Find("TTPortionOfDocuments") <> Undefined;
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();
	
	For Each NameOfDataSource In BalanceFinancialRegisters Do
		TheStructureOfTheSearch = New Structure("DataSource", NameOfDataSource);
		AccountingObjectRows_ = FinancialAccountingObjects.FindRows(TheStructureOfTheSearch);
		
		If AccountingObjectRows_.Count() = 0 Then
			Continue;
		EndIf;
		
		If RegistersOfRecoveryOfCalculationsOnStorno.Find(NameOfDataSource) <> Undefined Then
			Query.Parameters.RestoreCalculationsForStorno = True;
		EndIf;
		
		RegisterMetadata = AccumulationRegistersMetadata[NameOfDataSource];
		MotionReflectionParameters = ParametersOfRegisteringRecordedMovementsInInternationalAccounting(NameOfDataSource, RegisterMetadata);
		TimeTableOfRegisteredRecords = Query.TempTablesManager.Tables.Find("RegisterRecords" + NameOfDataSource);
		
		If MotionReflectionParameters.AllocationOfLongTermAssetsAndLiabilities
			And IsBlankString(MotionReflectionParameters.DataPathMaturityDate) Then
			If TimeTableOfRegisteredRecords <> Undefined
				And TimeTableOfRegisteredRecords.Columns.Find("PlannedRepaymentDate") <> Undefined Then
				MotionReflectionParameters.DataPathMaturityDate = "PlannedRepaymentDate";
			Else
				MotionReflectionParameters.AllocationOfLongTermAssetsAndLiabilities = False;
			EndIf;
		EndIf;
		
		FinancialAccountingByBalanceSheetRegisterData.ClarifyParametersOfReflectionOfRegisteredRecorded(
			MotionReflectionParameters, RegisterMetadata);
		
		AccountingObjectResourceKeys = New Map();
		
		For Each AccountingObjectLine_ In AccountingObjectRows_ Do
			FinancialAccountingByBalanceSheetRegisterData.FillInCorDataSources(Query.Parameters, AccountingObjectLine_);
			FinancialAccountingByBalanceSheetRegisterData.FillInSourcesWithDueDates(Query.Parameters, AccountingObjectLine_, MotionReflectionParameters);
			FinancialAccountingByBalanceSheetRegisterData.FillInSignsOfCorrespondenceAccounting(Query.Parameters, AccountingObjectLine_);
			FinancialAccountingByBalanceSheetRegisterData.FillInObjectsOfInappropriateValues(Query.Parameters, AccountingObjectLine_);
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
		
		If IsBlankString(MotionReflectionParameters.DataPathAccountingLocation) Then
			PlaceOfRegistration = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
		Else
			PlaceOfRegistration = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(MotionReflectionParameters.DataPathAccountingLocation);
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
		
		RegisterName = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(NameOfDataSource);
		
		If TimeTableOfRegisteredRecords = Undefined Then
			DataSource = StrTemplate("AccumulationRegister.%1 AS RegisterTable", NameOfDataSource);
			
			If ThereIsPortionOfDocuments Then
				DataSource = DataSource + "
				|	INNER JOIN TTPortionOfDocuments AS PortionOfDocuments
				|		ON &Recorder = PortionOfDocuments.Recorder
				|		 AND &Organization = PortionOfDocuments.Organization
				|		 AND BEGINOFPERIOD(&Period, DAY) = PortionOfDocuments.DateRecord";
			EndIf;
			ConditionDocumentsToBeDeleted = FinancialAccountingByBalanceSheetRegisterData.ConditionLineDocumentsToBeDeleted(RegisterMetadata);
		Else
			DataSource = StrTemplate("%1 AS RegisterTable", TimeTableOfRegisteredRecords.FullName);
			ConditionDocumentsToBeDeleted = "TRUE";
		EndIf;
		
		If AccountingObjectResourceKeys.Count() > 1 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRepeaterToDataSource(DataSource, AccountingObjectResourceKeys.Count());
		EndIf;
		
		ConditionPeriod = FinancialAccountingByBalanceSheetRegisterData.ConditionStringPeriod(Query.Parameters);
		ConditionLogger = FinancialAccountingByBalanceSheetRegisterData.ConditionStringLogger(Query.Parameters);
		OrganizationCondition = FinancialAccountingByBalanceSheetRegisterData.OrganizationConditionLine(Query.Parameters);
		ConditionAdditionalSelection = FinancialAccountingByBalanceSheetRegisterData.StringAdditionalSelection(MotionReflectionParameters);
		ConditionPropsStorno = FinancialAccountingByBalanceSheetRegisterData.ConditionStringPropsStorno();
		
		QueryText = CaseRecordRequestTextTemplate();
		
		If AccountingObjectResourceKeys.Count() > 1 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRepeaterToDimensionFields(QueryText);
		EndIf;
		
		QueryText = StrReplace(QueryText, "&AccountingObject", FieldsOfAccountingObjectSelection.AccountingObject);
		QueryText = StrReplace(QueryText, "&SettingObject1", FieldsOfAccountingObjectSelection.SettingObject1);
		QueryText = StrReplace(QueryText, "&LineOfBusiness", FieldsOfAccountingObjectSelection.LineOfBusiness);
		QueryText = StrReplace(QueryText, "&FinRecordID", FieldsOfAccountingObjectSelection.FinRecordID);
		QueryText = StrReplace(QueryText, "&SettingUpBusinessTransaction", FieldsOfAccountingObjectSelection.SettingUpBusinessTransaction);
		QueryText = StrReplace(QueryText, "&RowID", FieldsOfAccountingObjectSelection.RowID);
		QueryText = StrReplace(QueryText, "&MaturityDate", FieldsOfAccountingObjectSelection.MaturityDate);
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
		QueryText = StrReplace(QueryText, "&ConditionPropsStorno", ConditionPropsStorno);
		QueryText = StrReplace(QueryText, "&RegisterName", RegisterName);
		QueryText = StrReplace(QueryText, "&Currency", Currency);
		QueryText = StrReplace(QueryText, "&PlaceOfRegistration", PlaceOfRegistration);
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
			|	RegisterTable.SettingObject1 AS SettingObject1,
			|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
			|	RegisterTable.MaturityDate AS MaturityDate,
			|	RegisterTable.Currency AS Currency,
			|	SUM(RegisterTable.SumMan) AS SumMan,
			|	SUM(RegisterTable.SumCompl) AS SumCompl,
			|	SUM(RegisterTable.SumCurr) AS SumCurr,
			|	SUM(RegisterTable.Count) AS Count,
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
			|	RegisterTable.SettingObject1,
			|	RegisterTable.PlaceOfRegistration,
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
			|	RegisterTable.MaturityDate,
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
			|	RegisterTable.SettingObject1 AS SettingObject1,
			|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
			|	RegisterTable.MaturityDate AS MaturityDate,
			|	RegisterTable.Currency AS Currency,
			|	SUM(RegisterTable.SumMan) AS SumMan,
			|	SUM(RegisterTable.SumCompl) AS SumCompl,
			|	SUM(RegisterTable.SumCurr) AS SumCurr,
			|	SUM(RegisterTable.Count) AS Count,
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
			|	RegisterTable.SettingObject1,
			|	RegisterTable.PlaceOfRegistration,
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
			|	RegisterTable.MaturityDate,
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
	
	QueryText = StrReplace(QueryText, "&NestedTableAnalyticsFields", "//NestedTableAnalyticsFields");
	QueryText = StrReplace(QueryText, "&NestedTableAnalyticsGroup", "//NestedTableAnalyticsGroup");
	
	SelectionFieldsToDelete = FieldsForSelectingCorrespondenceRequestsThatAreBeingDeleted();
	IndexingFields = IndexFieldsOfCorrespondenceTable();
	PlacementTable = "TTMovementRegisters";
	
	FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(QueryText, SelectionFieldsToDelete, IndexingFields, PlacementTable);

	Return QueryText;
	
EndFunction

Procedure GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts)
	
	AddTablesOfInformationAboutAccountingObjects(QueriesTexts);
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
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTObjectsOfImproperValues");
	
	RestoreStornoCalculationsIfNecessary(Query, QueriesTexts);
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	ISNULL(SignsOfCorrespondenceAccounting.ValueNumber, 0) AS ComplexRecordNumber,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
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
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
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
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
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
	|	LEFT JOIN TTSignsOfCorrespondenceAccounting AS SignsOfCorrespondenceAccounting
	|		ON RegisteredRecordsDebitCredit.AccountingObjectDr = SignsOfCorrespondenceAccounting.AccountingObjectDr
	|		 AND RegisteredRecordsDebitCredit.AccountingObjectCr = SignsOfCorrespondenceAccounting.AccountingObjectCr
	|WHERE
	|	&ConditionObjectOfAccountingDr
	|	AND &ConditionCrAccountingObject
	|";
	
	If Query.Parameters.RestoreCalculationsForStorno Then
		QueryTextOfStornoCalculations = "
		|SELECT
		|	SettlementsWithCustomersOnStorno.Period AS Period,
		|	0 AS RecNoDr,
		|	0 AS RecNoCr,
		|	0 AS ComplexRecordNumber,
		|	SettlementsWithCustomersOnStorno.RegisterName AS RegisterNameDr,
		|	SettlementsWithCustomersOnStorno.RegisterName AS RegisterNameCr,
		|	SettlementsWithCustomersOnStorno.AccountingObjectDr AS AccountingObjectDr,
		|	SettlementsWithCustomersOnStorno.AccountingObjectCr AS AccountingObjectCr,
		|	SettlementsWithCustomersOnStorno.SettingObject1 AS SettingObject1Dr,
		|	SettlementsWithCustomersOnStorno.SettingObject1 AS SettingObject1Cr,
		|	SettlementsWithCustomersOnStorno.PlaceOfRegistration AS PlaceOfRegistrationDr,
		|	SettlementsWithCustomersOnStorno.PlaceOfRegistration AS PlaceOfRegistrationCr,
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
		|	SettlementsWithCustomersOnStorno.MaturityDate AS MaturityDateDr,
		|	SettlementsWithCustomersOnStorno.MaturityDate AS MaturityDateCr,
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
		|	SettlementsWithCustomersOnStorno.PropsStorno AS PropsStornoDr,
		|	SettlementsWithCustomersOnStorno.PropsStorno AS PropsStornoCr,
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
		|	0 AS ComplexRecordNumber,
		|	SettlementsWithSuppliersOnStorno.RegisterName AS RegisterNameDr,
		|	SettlementsWithSuppliersOnStorno.RegisterName AS RegisterNameCr,
		|	SettlementsWithSuppliersOnStorno.AccountingObjectDr AS AccountingObjectDr,
		|	SettlementsWithSuppliersOnStorno.AccountingObjectCr AS AccountingObjectCr,
		|	SettlementsWithSuppliersOnStorno.SettingObject1 AS SettingObject1Dr,
		|	SettlementsWithSuppliersOnStorno.SettingObject1 AS SettingObject1Cr,
		|	SettlementsWithSuppliersOnStorno.PlaceOfRegistration AS PlaceOfRegistrationDr,
		|	SettlementsWithSuppliersOnStorno.PlaceOfRegistration AS PlaceOfRegistrationCr,
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
		|	SettlementsWithSuppliersOnStorno.MaturityDate AS MaturityDateDr,
		|	SettlementsWithSuppliersOnStorno.MaturityDate AS MaturityDateCr,
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
		|	SettlementsWithSuppliersOnStorno.PropsStorno AS PropsStornoDr,
		|	SettlementsWithSuppliersOnStorno.PropsStorno AS PropsStornoCr,
		|	FALSE AS ComplexEntryDr,
		|	FALSE AS ComplexEntryCr,
		|	TRUE AS TakeIntoAccountBusinessTransaction,
		|	SettlementsWithSuppliersOnStorno.SumManDr AS SumManDr,
		|	SettlementsWithSuppliersOnStorno.SumManCr AS SumManCr,
		|	SettlementsWithSuppliersOnStorno.SumComplDr AS SumComplDr,
		|	SettlementsWithSuppliersOnStorno.SumComplCr AS SumComplCr
		|FROM
		|	TTSettlementsWithSuppliersOnStorno AS SettlementsWithSuppliersOnStorno
		|";
		
		QueryText = QueryText
			+ TMCommonUse.QuerySeparatorInJoin()
			+ QueryTextOfStornoCalculations;
	EndIf;
	
	QueryText = QueryText + "
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
		"&ConditionObjectOfAccountingDr",
		ConditionLineAccountingObject(Query.Parameters, "Dr", "RegisteredRecordsDebitCredit"));
	QueryText = StrReplace(QueryText,
		"&ConditionCrAccountingObject",
		ConditionLineAccountingObject(Query.Parameters, "Cr", "RegisteredRecordsDebitCredit"));
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
	|	RegisteredRecordsDebitCredit.ComplexRecordNumber AS ComplexRecordNumber,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
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
	|	DistributionOfUnbalancedAssets.SettingObject1Dr AS SettingObject1Dr,
	|	DistributionOfUnbalancedAssets.SettingObject1Cr AS SettingObject1Cr,
	|	DistributionOfUnbalancedAssets.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	DistributionOfUnbalancedAssets.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	DistributionOfUnbalancedAssets.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	DistributionOfUnbalancedAssets.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	DistributionOfUnbalancedAssets.Organization AS Organization,
	|	DistributionOfUnbalancedAssets.Recorder AS Recorder,
	|	DistributionOfUnbalancedAssets.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DistributionOfUnbalancedAssets.FinRecordID AS FinRecordID,
	|	DistributionOfUnbalancedAssets.RowIDDr AS RowIDDr,
	|	DistributionOfUnbalancedAssets.RowIDCr AS RowIDCr,
	|	DistributionOfUnbalancedAssets.MaturityDateDr AS MaturityDateDr,
	|	DistributionOfUnbalancedAssets.MaturityDateCr AS MaturityDateCr,
	|	DistributionOfUnbalancedAssets.CurrencyDr AS CurrencyDr,
	|	DistributionOfUnbalancedAssets.CurrencyCr AS CurrencyCr,
	|	DistributionOfUnbalancedAssets.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	DistributionOfUnbalancedAssets.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	DistributionOfUnbalancedAssets.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	DistributionOfUnbalancedAssets.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	DistributionOfUnbalancedAssets.PropsStornoDr AS PropsStornoDr,
	|	DistributionOfUnbalancedAssets.PropsStornoCr AS PropsStornoCr,
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
	|	RecNoDr,
	|	RecNoCr
	|");
	
	DeletedTemporaryTables = New Array();
	DeletedTemporaryTables.Add("TTDistributionOfUnbalancedAssets");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftDr");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftCr");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfDrQuantities");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfCrQuantities");

	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

Procedure DistributeCorrespondenceByMaturityDates(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS LineNumber,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNo AS RecNo,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
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
	|	RegisteredRecordsDebitCredit.PropsStornoDr OR RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStorno,
	|	ISNULL(DetailedDebitRegisteredRecords.SumMan, RegisteredRecordsDebitCredit.AmountOfManMovementDr) AS AmountOfManMovementDr,
	|	ISNULL(DetailedRegisteredRecordsCredit.SumMan, RegisteredRecordsDebitCredit.AmountOfManMovementCr) AS AmountOfManMovementCr,
	|	ISNULL(DetailedDebitRegisteredRecords.SumCompl, RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr) AS AmountOfLocalTrafficDr,
	|	ISNULL(DetailedRegisteredRecordsCredit.SumCompl, RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr) AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS DistributableAmountOfManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS DistributableAmountOfManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS DistributableAmountOfLocalDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS DistributableAmountOfLocalCr,
	|	RegisteredRecordsDebitCredit.SumCurrDr AS DistributableAmountShaftDr,
	|	RegisteredRecordsDebitCredit.SumCurrCr AS DistributableAmountOfCrShaft,
	|	RegisteredRecordsDebitCredit.CountDr AS DistributableAmountOfDr,
	|	RegisteredRecordsDebitCredit.CountCr AS DistributableNumberOfCr,
	|	ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|		OR ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1 AS ThereIsDistribution,
	|	CASE
	|		WHEN ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN DetailedDebitRegisteredRecords.MaturityDate
	|		ELSE RegisteredRecordsDebitCredit.MaturityDateDr
	|	END AS MaturityDateDr,
	|	CASE
	|		WHEN ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN DetailedRegisteredRecordsCredit.MaturityDate
	|		ELSE RegisteredRecordsDebitCredit.MaturityDateCr
	|	END AS MaturityDateCr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.SumManDr = 0
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumManDr * DetailedDebitRegisteredRecords.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumManDr * DetailedRegisteredRecordsCredit.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumManDr * DetailedDebitRegisteredRecords.SumMan * DetailedRegisteredRecordsCredit.SumMan / (RegisteredRecordsDebitCredit.AmountOfManMovementDr * RegisteredRecordsDebitCredit.AmountOfManMovementCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfSum, &SumAccuracy)) AS SumManDr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.SumManCr = 0
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumManCr * DetailedDebitRegisteredRecords.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumManCr * DetailedRegisteredRecordsCredit.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumManCr * DetailedDebitRegisteredRecords.SumMan * DetailedRegisteredRecordsCredit.SumMan / (RegisteredRecordsDebitCredit.AmountOfManMovementDr * RegisteredRecordsDebitCredit.AmountOfManMovementCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfSum, &SumAccuracy)) AS SumManCr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr = 0
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumComplDr * DetailedDebitRegisteredRecords.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumComplDr * DetailedRegisteredRecordsCredit.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumComplDr * DetailedDebitRegisteredRecords.SumCompl * DetailedRegisteredRecordsCredit.SumCompl / (RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr * RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfSum, &SumAccuracy)) AS SumComplDr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.SumComplCr = 0
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumComplCr * DetailedDebitRegisteredRecords.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumComplCr * DetailedRegisteredRecordsCredit.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumComplCr * DetailedDebitRegisteredRecords.SumCompl * DetailedRegisteredRecordsCredit.SumCompl / (RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr * RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfSum, &SumAccuracy)) AS SumComplCr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.SumCurrDr = 0
	|			THEN RegisteredRecordsDebitCredit.SumCurrDr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.SumCurrDr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrDr * DetailedDebitRegisteredRecords.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrDr * DetailedDebitRegisteredRecords.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrDr * DetailedRegisteredRecordsCredit.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrDr * DetailedRegisteredRecordsCredit.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumCurrDr * DetailedDebitRegisteredRecords.SumMan * DetailedRegisteredRecordsCredit.SumMan / (RegisteredRecordsDebitCredit.AmountOfManMovementDr * RegisteredRecordsDebitCredit.AmountOfManMovementCr)
	|			WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumCurrDr * DetailedDebitRegisteredRecords.SumCompl * DetailedRegisteredRecordsCredit.SumCompl / (RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr * RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfSum, &SumAccuracy)) AS SumCurrDr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.SumCurrCr = 0
	|			THEN RegisteredRecordsDebitCredit.SumCurrCr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.SumCurrCr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrCr * DetailedDebitRegisteredRecords.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrCr * DetailedDebitRegisteredRecords.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrCr * DetailedRegisteredRecordsCredit.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.SumCurrCr * DetailedRegisteredRecordsCredit.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumCurrCr * DetailedDebitRegisteredRecords.SumMan * DetailedRegisteredRecordsCredit.SumMan / (RegisteredRecordsDebitCredit.AmountOfManMovementDr * RegisteredRecordsDebitCredit.AmountOfManMovementCr)
	|			WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|				THEN RegisteredRecordsDebitCredit.SumCurrCr * DetailedDebitRegisteredRecords.SumCompl * DetailedRegisteredRecordsCredit.SumCompl / (RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr * RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfSum, &SumAccuracy)) AS SumCurrCr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.CountDr = 0
	|			THEN RegisteredRecordsDebitCredit.CountDr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.CountDr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountDr * DetailedDebitRegisteredRecords.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountDr * DetailedDebitRegisteredRecords.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountDr * DetailedRegisteredRecordsCredit.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountDr * DetailedRegisteredRecordsCredit.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|				THEN RegisteredRecordsDebitCredit.CountDr * DetailedDebitRegisteredRecords.SumMan * DetailedRegisteredRecordsCredit.SumMan / (RegisteredRecordsDebitCredit.AmountOfManMovementDr * RegisteredRecordsDebitCredit.AmountOfManMovementCr)
	|			WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|				THEN RegisteredRecordsDebitCredit.CountDr * DetailedDebitRegisteredRecords.SumCompl * DetailedRegisteredRecordsCredit.SumCompl / (RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr * RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfQuantity, &QuantityAccuracy)) AS CountDr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.CountCr = 0
	|			THEN RegisteredRecordsDebitCredit.CountCr
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			AND NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN RegisteredRecordsDebitCredit.CountCr
	|		WHEN NOT ISNULL(DetailedRegisteredRecordsCredit.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountCr * DetailedDebitRegisteredRecords.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountCr * DetailedDebitRegisteredRecords.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END
	|		WHEN NOT ISNULL(DetailedDebitRegisteredRecords.NumberOfRepaymentStages, 0) > 1
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountCr * DetailedRegisteredRecordsCredit.SumMan / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.CountCr * DetailedRegisteredRecordsCredit.SumCompl / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|				THEN RegisteredRecordsDebitCredit.CountCr * DetailedDebitRegisteredRecords.SumMan * DetailedRegisteredRecordsCredit.SumMan / (RegisteredRecordsDebitCredit.AmountOfManMovementDr * RegisteredRecordsDebitCredit.AmountOfManMovementCr)
	|			WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0 AND RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|				THEN RegisteredRecordsDebitCredit.CountCr * DetailedDebitRegisteredRecords.SumCompl * DetailedRegisteredRecordsCredit.SumCompl / (RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr * RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr)
	|			ELSE 0
	|		END
	|	END AS NUMBER(&LengthOfQuantity, &QuantityAccuracy)) AS CountCr
	|INTO TTDistributionByMaturityDates
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|	LEFT JOIN TableOfDetailedRegisteredRecordsWithDebitTotals AS DetailedDebitRegisteredRecords
	|		ON RegisteredRecordsDebitCredit.RecNoDr = DetailedDebitRegisteredRecords.RecNo
	|	LEFT JOIN TableOfDetailedRegisteredRecordsWithCreditTotals AS DetailedRegisteredRecordsCredit
	|		ON RegisteredRecordsDebitCredit.RecNoCr = DetailedRegisteredRecordsCredit.RecNo
	|INDEX BY
	|	LineNumber,
	|	RecNo
	|";
	
	QueryText = StrReplace(QueryText, "&LengthOfSum", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.LengthOfSum));
	QueryText = StrReplace(QueryText, "&SumAccuracy", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.SumAccuracy));
	QueryText = StrReplace(QueryText, "&LengthOfQuantity", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.LengthOfQuantity));
	QueryText = StrReplace(QueryText, "&QuantityAccuracy", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Query.Parameters.QuantityAccuracy));
	QueryText = StrReplace(QueryText, "TableOfDetailedRegisteredRecordsWithDebitTotals", Query.Parameters.TableOfDetailedRegisteredRecordsWithDebitTotals);
	QueryText = StrReplace(QueryText, "TableOfDetailedRegisteredRecordsWithCreditTotals", Query.Parameters.TableOfDetailedRegisteredRecordsWithCreditTotals);
	
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementDebitCredit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, Query.Parameters.TableOfDetailedRegisteredRecordsWithDebitTotals);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, Query.Parameters.TableOfDetailedRegisteredRecordsWithCreditTotals);
	
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionOfSumsManDr", "DistributableAmountOfManDr", "SumManDr");
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionForManCr", "DistributableAmountOfManCr", "SumManCr");
	
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionOfLocalDrSums", "DistributableAmountOfLocalDr", "SumComplDr");
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionForLocalCrSums", "DistributableAmountOfLocalCr", "SumComplCr");
	
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionSumsShaftDr", "DistributableAmountShaftDr", "SumCurrDr");
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionSumsShaftCr", "DistributableAmountOfCrShaft", "SumCurrCr");
	
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionOfDrQuantities", "DistributableAmountOfDr", "CountDr");
	FinancialAccountingByBalanceSheetRegisterData.AddResourceRoundingErrorTable(QueriesTexts, "TTErrorCorrectionOfCrQuantities", "DistributableNumberOfCr", "CountCr");
	
	QueriesTexts.Add("
	|SELECT
	|	DistributionByMaturityDates.Period AS Period,
	|	DistributionByMaturityDates.LineNumber AS RecNo,
	|	DistributionByMaturityDates.RegisterNameDr AS RegisterNameDr,
	|	DistributionByMaturityDates.RegisterNameCr AS RegisterNameCr,
	|	DistributionByMaturityDates.AccountingObjectDr AS AccountingObjectDr,
	|	DistributionByMaturityDates.AccountingObjectCr AS AccountingObjectCr,
	|	DistributionByMaturityDates.SettingObject1Dr AS SettingObject1Dr,
	|	DistributionByMaturityDates.SettingObject1Cr AS SettingObject1Cr,
	|	DistributionByMaturityDates.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	DistributionByMaturityDates.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	DistributionByMaturityDates.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	DistributionByMaturityDates.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	DistributionByMaturityDates.Organization AS Organization,
	|	DistributionByMaturityDates.Recorder AS Recorder,
	|	DistributionByMaturityDates.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DistributionByMaturityDates.FinRecordID AS FinRecordID,
	|	DistributionByMaturityDates.RowIDDr AS RowIDDr,
	|	DistributionByMaturityDates.RowIDCr AS RowIDCr,
	|	DistributionByMaturityDates.CurrencyDr AS CurrencyDr,
	|	DistributionByMaturityDates.CurrencyCr AS CurrencyCr,
	|	DistributionByMaturityDates.PropsStorno AS PropsStorno,
	|	DistributionByMaturityDates.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	DistributionByMaturityDates.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	DistributionByMaturityDates.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	DistributionByMaturityDates.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	DistributionByMaturityDates.ComplexEntryDr AS ComplexEntryDr,
	|	DistributionByMaturityDates.ComplexEntryCr AS ComplexEntryCr,
	|	DistributionByMaturityDates.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	DistributionByMaturityDates.MaturityDateDr AS MaturityDateDr,
	|	DistributionByMaturityDates.MaturityDateCr AS MaturityDateCr,
	|	DistributionByMaturityDates.SumManDr + ISNULL(CorrectionOfErrorsInManDr.RoundingError, 0) AS SumManDr,
	|	DistributionByMaturityDates.SumManCr + ISNULL(CorrectionOfErrorsInManCr.RoundingError, 0) AS SumManCr,
	|	DistributionByMaturityDates.SumComplDr + ISNULL(ErrorCorrectionOfLocalDrSums.RoundingError, 0) AS SumComplDr,
	|	DistributionByMaturityDates.SumComplCr + ISNULL(ErrorCorrectionOfLocalCrSums.RoundingError, 0) AS SumComplCr,
	|	DistributionByMaturityDates.SumCurrDr + ISNULL(CorrectionOfErrorsInDrShaft.RoundingError, 0) AS SumCurrDr,
	|	DistributionByMaturityDates.SumCurrCr + ISNULL(CorrectionOfErrorsInCRShaft.RoundingError, 0) AS SumCurrCr,
	|	DistributionByMaturityDates.CountDr + ISNULL(CorrectionOfDrQuantityErrors.RoundingError, 0) AS CountDr,
	|	DistributionByMaturityDates.CountCr + ISNULL(CorrectionOfCrQuantityErrors.RoundingError, 0) AS CountCr
	|INTO TTMovementDebitCredit
	|FROM
	|	TTDistributionByMaturityDates AS DistributionByMaturityDates
	|	LEFT JOIN TTErrorCorrectionOfSumsManDr AS CorrectionOfErrorsInManDr
	|		ON DistributionByMaturityDates.RecNo = CorrectionOfErrorsInManDr.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = CorrectionOfErrorsInManDr.LineNumber
	|	LEFT JOIN TTErrorCorrectionForManCr AS CorrectionOfErrorsInManCr
	|		ON DistributionByMaturityDates.RecNo = CorrectionOfErrorsInManCr.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = CorrectionOfErrorsInManCr.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfLocalDrSums AS ErrorCorrectionOfLocalDrSums
	|		ON DistributionByMaturityDates.RecNo = ErrorCorrectionOfLocalDrSums.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = ErrorCorrectionOfLocalDrSums.LineNumber
	|	LEFT JOIN TTErrorCorrectionForLocalCrSums AS ErrorCorrectionOfLocalCrSums
	|		ON DistributionByMaturityDates.RecNo = ErrorCorrectionOfLocalCrSums.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = ErrorCorrectionOfLocalCrSums.LineNumber
	|	LEFT JOIN TTErrorCorrectionSumsShaftDr AS CorrectionOfErrorsInDrShaft
	|		ON DistributionByMaturityDates.RecNo = CorrectionOfErrorsInDrShaft.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = CorrectionOfErrorsInDrShaft.LineNumber
	|	LEFT JOIN TTErrorCorrectionSumsShaftCr AS CorrectionOfErrorsInCRShaft
	|		ON DistributionByMaturityDates.RecNo = CorrectionOfErrorsInCRShaft.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = CorrectionOfErrorsInCRShaft.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfDrQuantities AS CorrectionOfDrQuantityErrors
	|		ON DistributionByMaturityDates.RecNo = CorrectionOfDrQuantityErrors.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = CorrectionOfDrQuantityErrors.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfCrQuantities AS CorrectionOfCrQuantityErrors
	|		ON DistributionByMaturityDates.RecNo = CorrectionOfCrQuantityErrors.RecNo
	|		 AND DistributionByMaturityDates.LineNumber = CorrectionOfCrQuantityErrors.LineNumber
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	RecNo,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	SettingObject1Dr,
	|	SettingObject1Cr,
	|	PlaceOfRegistrationDr,
	|	PlaceOfRegistrationCr,
	|	Organization
	|");
	
	DeletedTemporaryTables = New Array();
	DeletedTemporaryTables.Add("TTDistributionByMaturityDates");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfSumsManDr");
	DeletedTemporaryTables.Add("TTErrorCorrectionForManCr");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfLocalDrSums");
	DeletedTemporaryTables.Add("TTErrorCorrectionForLocalCrSums");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftDr");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftCr");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfDrQuantities");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfCrQuantities");

	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

Procedure DefineCorrespondenceAccountsForObjects(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObject,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingObject1Dr IN (&EmptyConfigurationObjects)
	|			THEN UNDEFINED
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Dr
	|	END AS InvoiceMatchingSettingsObject,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistration,
	|	RegisteredRecordsDebitCredit.Organization AS Organization
	|INTO TTAccountingObjectsAndSettings
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|GROUP BY
	|	RegisteredRecordsDebitCredit.AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.Organization
	|
	|UNION
	|
	|SELECT
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObject,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingObject1Cr IN (&EmptyConfigurationObjects)
	|			THEN UNDEFINED
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Cr
	|	END AS InvoiceMatchingSettingsObject,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistration,
	|	RegisteredRecordsDebitCredit.Organization AS Organization
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|GROUP BY
	|	RegisteredRecordsDebitCredit.AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr,
	|	RegisteredRecordsDebitCredit.Organization
	|INDEX BY
	|	AccountingObject,
	|	InvoiceMatchingSettingsObject,
	|	PlaceOfRegistration,
	|	Organization
	|";
	
	TypesOfSettingsObjects = Metadata.DefinedTypes.ObjectForSettingUpFinancialAccountingAccounts.Type;
	EmptyConfigurationObjects = EmptyTypeValues(TypesOfSettingsObjects);
	QueryText = StrReplace(QueryText, "&EmptyConfigurationObjects", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(EmptyConfigurationObjects));
	
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	1 AS Priority,
	|	AccountingObjectsAndSettings.AccountingObject AS AccountingObject,
	|	AccountingObjectsAndSettings.SettingObject1 AS SettingObject1,
	|	AccountingObjectsAndSettings.PlaceOfRegistration AS PlaceOfRegistration,
	|	AccountingObjectsAndSettings.Organization AS Organization,
	|	InvoiceSettingsByMapItem.ChartOfAccounts AS ChartOfAccounts,
	|	InvoiceSettingsByMapItem.PostingGenerationSetting AS PostingGenerationSetting,
	|	InvoiceSettingsByMapItem.LedgerAccountLongTerm AS LedgerAccountLongTerm,
	|	InvoiceSettingsByMapItem.GLAccount AS GLAccount
	|INTO TTAccountPriorities
	|FROM
	|	TTAccountingObjectsAndSettings AS AccountingObjectsAndSettings
	|	INNER JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS InvoiceSettingsByMapItem
	|		ON AccountingObjectsAndSettings.AccountingObject = InvoiceSettingsByMapItem.AccountingObject
	|		 AND AccountingObjectsAndSettings.InvoiceMatchingSettingsObject = InvoiceSettingsByMapItem.SettingObject1
	|		 AND AccountingObjectsAndSettings.PlaceOfRegistration = InvoiceSettingsByMapItem.PlaceOfRegistration
	|		 AND AccountingObjectsAndSettings.Organization = InvoiceSettingsByMapItem.Organization
	|WHERE
	|	&ChartOfAccountsCondition
	|	AND InvoiceSettingsByMapItem.SettingType = VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject)
	|	AND InvoiceSettingsByMapItem.PlaceOfRegistration <> UNDEFINED
	|	AND InvoiceSettingsByMapItem.Organization <> VALUE(Catalog.Companies.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Priority,
	|	AccountingObjectsAndSettings.AccountingObject AS AccountingObject,
	|	AccountingObjectsAndSettings.SettingObject1 AS SettingObject1,
	|	AccountingObjectsAndSettings.PlaceOfRegistration AS PlaceOfRegistration,
	|	AccountingObjectsAndSettings.Organization AS Organization,
	|	InvoiceSettingsByMapItem.ChartOfAccounts AS ChartOfAccounts,
	|	InvoiceSettingsByMapItem.PostingGenerationSetting AS PostingGenerationSetting,
	|	InvoiceSettingsByMapItem.LedgerAccountLongTerm AS LedgerAccountLongTerm,
	|	InvoiceSettingsByMapItem.GLAccount AS GLAccount
	|FROM
	|	TTAccountingObjectsAndSettings AS AccountingObjectsAndSettings
	|	INNER JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS InvoiceSettingsByMapItem
	|		ON AccountingObjectsAndSettings.AccountingObject = InvoiceSettingsByMapItem.AccountingObject
	|		 AND AccountingObjectsAndSettings.InvoiceMatchingSettingsObject = InvoiceSettingsByMapItem.SettingObject1
	|		 AND AccountingObjectsAndSettings.PlaceOfRegistration = InvoiceSettingsByMapItem.PlaceOfRegistration
	|WHERE
	|	&ChartOfAccountsCondition
	|	AND InvoiceSettingsByMapItem.SettingType = VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject)
	|	AND InvoiceSettingsByMapItem.PlaceOfRegistration <> UNDEFINED
	|	AND InvoiceSettingsByMapItem.Organization = VALUE(Catalog.Companies.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	3 AS Priority,
	|	AccountingObjectsAndSettings.AccountingObject AS AccountingObject,
	|	AccountingObjectsAndSettings.SettingObject1 AS SettingObject1,
	|	AccountingObjectsAndSettings.PlaceOfRegistration AS PlaceOfRegistration,
	|	AccountingObjectsAndSettings.Organization AS Organization,
	|	InvoiceSettingsByMapItem.ChartOfAccounts AS ChartOfAccounts,
	|	InvoiceSettingsByMapItem.PostingGenerationSetting AS PostingGenerationSetting,
	|	InvoiceSettingsByMapItem.LedgerAccountLongTerm AS LedgerAccountLongTerm,
	|	InvoiceSettingsByMapItem.GLAccount AS GLAccount
	|FROM
	|	TTAccountingObjectsAndSettings AS AccountingObjectsAndSettings
	|	INNER JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS InvoiceSettingsByMapItem
	|		ON AccountingObjectsAndSettings.AccountingObject = InvoiceSettingsByMapItem.AccountingObject
	|		 AND AccountingObjectsAndSettings.InvoiceMatchingSettingsObject = InvoiceSettingsByMapItem.SettingObject1
	|		 AND AccountingObjectsAndSettings.Organization = InvoiceSettingsByMapItem.Organization
	|WHERE
	|	&ChartOfAccountsCondition
	|	AND InvoiceSettingsByMapItem.SettingType = VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject)
	|	AND InvoiceSettingsByMapItem.PlaceOfRegistration = UNDEFINED
	|	AND InvoiceSettingsByMapItem.Organization <> VALUE(Catalog.Companies.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	4 AS Priority,
	|	AccountingObjectsAndSettings.AccountingObject AS AccountingObject,
	|	AccountingObjectsAndSettings.SettingObject1 AS SettingObject1,
	|	AccountingObjectsAndSettings.PlaceOfRegistration AS PlaceOfRegistration,
	|	AccountingObjectsAndSettings.Organization AS Organization,
	|	InvoiceSettingsByMapItem.ChartOfAccounts AS ChartOfAccounts,
	|	InvoiceSettingsByMapItem.PostingGenerationSetting AS PostingGenerationSetting,
	|	InvoiceSettingsByMapItem.LedgerAccountLongTerm AS LedgerAccountLongTerm,
	|	InvoiceSettingsByMapItem.GLAccount AS GLAccount
	|FROM
	|	TTAccountingObjectsAndSettings AS AccountingObjectsAndSettings
	|	INNER JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS InvoiceSettingsByMapItem
	|		ON AccountingObjectsAndSettings.AccountingObject = InvoiceSettingsByMapItem.AccountingObject
	|		 AND AccountingObjectsAndSettings.InvoiceMatchingSettingsObject = InvoiceSettingsByMapItem.SettingObject1
	|WHERE
	|	&ChartOfAccountsCondition
	|	AND InvoiceSettingsByMapItem.SettingType = VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.TotalByAccountingObject)
	|INDEX BY
	|	AccountingObject,
	|	SettingObject1,
	|	PlaceOfRegistration,
	|	Organization,
	|	Priority,
	|	ChartOfAccounts,
	|	PostingGenerationSetting
	|";
	
	QueryText = StrReplace(QueryText, "&ChartOfAccountsCondition", ConditionsLineChartOfAccounts(Query.Parameters));
	QueryText = StrReplace(QueryText, "&ChartOfAccounts", "InvoiceSettingsByMapItem.ChartOfAccounts");
	QueryText = StrReplace(QueryText, "&RequestParameterChartOfAccounts", "&ChartOfAccounts");
	
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAccountingObjectsAndSettings");
	
	QueriesTexts.Add("
	|SELECT
	|	PrioritiesOfAccountingAccounts.AccountingObject AS AccountingObject,
	|	PrioritiesOfAccountingAccounts.SettingObject1 AS SettingObject1,
	|	PrioritiesOfAccountingAccounts.PlaceOfRegistration AS PlaceOfRegistration,
	|	PrioritiesOfAccountingAccounts.Organization AS Organization,
	|	PrioritiesOfAccountingAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	PrioritiesOfAccountingAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	MIN(PrioritiesOfAccountingAccounts.Priority) AS Priority
	|INTO TTHighestAccountPriorities
	|FROM
	|	TTAccountPriorities AS PrioritiesOfAccountingAccounts
	|GROUP BY
	|	PrioritiesOfAccountingAccounts.AccountingObject,
	|	PrioritiesOfAccountingAccounts.SettingObject1,
	|	PrioritiesOfAccountingAccounts.PlaceOfRegistration,
	|	PrioritiesOfAccountingAccounts.Organization,
	|	PrioritiesOfAccountingAccounts.ChartOfAccounts,
	|	PrioritiesOfAccountingAccounts.PostingGenerationSetting
	|INDEX BY
	|	AccountingObject,
	|	SettingObject1,
	|	PlaceOfRegistration,
	|	Organization,
	|	Priority,
	|	ChartOfAccounts,
	|	PostingGenerationSetting
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	PrioritiesOfAccountingAccounts.AccountingObject AS AccountingObject,
	|	PrioritiesOfAccountingAccounts.SettingObject1 AS SettingObject1,
	|	PrioritiesOfAccountingAccounts.PlaceOfRegistration AS PlaceOfRegistration,
	|	PrioritiesOfAccountingAccounts.Organization AS Organization,
	|	PrioritiesOfAccountingAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	PrioritiesOfAccountingAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	PrioritiesOfAccountingAccounts.LedgerAccountLongTerm AS LedgerAccountLongTerm,
	|	PrioritiesOfAccountingAccounts.GLAccount AS GLAccount
	|INTO TTAccountsOfAccountingObjects
	|FROM
	|	TTAccountPriorities AS PrioritiesOfAccountingAccounts
	|	INNER JOIN TTHighestAccountPriorities AS HighestAccountPriorities
	|		ON PrioritiesOfAccountingAccounts.AccountingObject = HighestAccountPriorities.AccountingObject
	|		 AND PrioritiesOfAccountingAccounts.SettingObject1 = HighestAccountPriorities.SettingObject1
	|		 AND PrioritiesOfAccountingAccounts.PlaceOfRegistration = HighestAccountPriorities.PlaceOfRegistration
	|		 AND PrioritiesOfAccountingAccounts.Organization = HighestAccountPriorities.Organization
	|		 AND PrioritiesOfAccountingAccounts.Priority = HighestAccountPriorities.Priority
	|		 AND PrioritiesOfAccountingAccounts.ChartOfAccounts = HighestAccountPriorities.ChartOfAccounts
	|		 AND PrioritiesOfAccountingAccounts.PostingGenerationSetting = HighestAccountPriorities.PostingGenerationSetting
	|GROUP BY
	|	PrioritiesOfAccountingAccounts.AccountingObject,
	|	PrioritiesOfAccountingAccounts.SettingObject1,
	|	PrioritiesOfAccountingAccounts.PlaceOfRegistration,
	|	PrioritiesOfAccountingAccounts.Organization,
	|	PrioritiesOfAccountingAccounts.ChartOfAccounts,
	|	PrioritiesOfAccountingAccounts.PostingGenerationSetting,
	|	PrioritiesOfAccountingAccounts.LedgerAccountLongTerm,
	|	PrioritiesOfAccountingAccounts.GLAccount
	|INDEX BY
	|	AccountingObject,
	|	SettingObject1,
	|	PlaceOfRegistration,
	|	Organization,
	|	ChartOfAccounts,
	|	PostingGenerationSetting
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAccountPriorities");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTHighestAccountPriorities");
	
	AddTableOfTransactionGenerationSettings(Query, QueriesTexts);
	AddTableOfAccountingPoliciesForFinancialAccounting(Query, QueriesTexts);
	AddTableOfAccountingSettingsForOtherOfOperations(QueriesTexts);
	
	QueriesTexts.Add("
	|SELECT
	|	ISNULL(TransactionSettingsByPeriod.ChartOfAccounts, VALUE(Catalog.FinancialAccountingChartsOfAccounts.EmptyRef)) AS ChartOfAccounts,
	|	ISNULL(TransactionSettingsByPeriod.PostingGenerationSetting, VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)) AS PostingGenerationSetting,
	|	CASE
	|		WHEN NOT ISNULL(TransactionSettingsByPeriod.AllocationOfLongTermAssetsAndLiabilities, FALSE)
	|			THEN FALSE
	|		WHEN ISNULL(AccountingPoliciesForPeriods.DurationOfCompanyOperatingCycle, 0) = 0
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.MaturityDateDr = DATETIME(0001,01,01)
	|			THEN FALSE
	|		WHEN NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTSourcesWithDueDates AS SourcesWithDueDates
	|			WHERE
	|				SourcesWithDueDates.RegisterName = RegisteredRecordsDebitCredit.RegisterNameDr
	|				AND SourcesWithDueDates.AccountingObject = RegisteredRecordsDebitCredit.AccountingObjectDr
	|			)
	|			THEN FALSE
	|		WHEN DATEDIFF(RegisteredRecordsDebitCredit.Period, RegisteredRecordsDebitCredit.MaturityDateDr, MONTH) >= AccountingPoliciesForPeriods.DurationOfCompanyOperatingCycle
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS LongTermDr,
	|	CASE
	|		WHEN NOT ISNULL(TransactionSettingsByPeriod.AllocationOfLongTermAssetsAndLiabilities, FALSE)
	|			THEN FALSE
	|		WHEN ISNULL(AccountingPoliciesForPeriods.DurationOfCompanyOperatingCycle, 0) = 0
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.MaturityDateCr = DATETIME(0001,01,01)
	|			THEN FALSE
	|		WHEN NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTSourcesWithDueDates AS SourcesWithDueDates
	|			WHERE
	|				SourcesWithDueDates.RegisterName = RegisteredRecordsDebitCredit.RegisterNameCr
	|				AND SourcesWithDueDates.AccountingObject = RegisteredRecordsDebitCredit.AccountingObjectCr
	|			)
	|			THEN FALSE
	|		WHEN DATEDIFF(RegisteredRecordsDebitCredit.Period, RegisteredRecordsDebitCredit.MaturityDateCr, MONTH) >= AccountingPoliciesForPeriods.DurationOfCompanyOperatingCycle
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS LongTermCr,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	CASE
	|		WHEN NOT AccountingSettingsForOtherTransactionsDr.GLAccountSettings IS NULL
	|			THEN AccountingSettingsForOtherTransactionsDr.GLAccountSettings
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Dr
	|	END AS SettingObject1Dr,
	|	CASE
	|		WHEN NOT AccountingSettingsForOtherTransactionsCr.GLAccountSettings IS NULL
	|			THEN AccountingSettingsForOtherTransactionsCr.GLAccountSettings
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Cr
	|	END AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SourceConfigurationObjectCr,
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
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsDebitCredit.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsDebitCredit.CountDr AS CountDr,
	|	RegisteredRecordsDebitCredit.CountCr AS CountCr
	|INTO TTMovementWithDebitCreditSettings
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|	LEFT JOIN TTSettingsForTransactionsByPeriod AS TransactionSettingsByPeriod
	|		ON BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) = TransactionSettingsByPeriod.Period
	|		 AND RegisteredRecordsDebitCredit.Organization = TransactionSettingsByPeriod.Organization
	|	LEFT JOIN TTAccountingPolicyForPeriods AS AccountingPoliciesForPeriods
	|		ON BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) = AccountingPoliciesForPeriods.Period
	|		 AND RegisteredRecordsDebitCredit.Organization = AccountingPoliciesForPeriods.Organization
	|	LEFT JOIN TTSettingsOfOperations AS AccountingSettingsForOtherTransactionsDr
	|		ON RegisteredRecordsDebitCredit.RecNo = AccountingSettingsForOtherTransactionsDr.RecNo
	|		 AND TransactionSettingsByPeriod.ChartOfAccounts = AccountingSettingsForOtherTransactionsDr.ChartOfAccounts
	|		 AND AccountingSettingsForOtherTransactionsDr.DebitCredit = CASE
	|			WHEN RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr
	|				THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|			ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|		 END
	|		AND RegisteredRecordsDebitCredit.RegisterNameDr = &RegisterNameOtherAssetsLiabilities
	|		AND VALUETYPE(RegisteredRecordsDebitCredit.SettingObject1Dr) <> TYPE(Catalog.OtherTransactionsGLAccountsSettings)
	|	LEFT JOIN TTSettingsOfOperations AS AccountingSettingsForOtherTransactionsCr
	|		ON RegisteredRecordsDebitCredit.RecNo = AccountingSettingsForOtherTransactionsCr.RecNo
	|		 AND TransactionSettingsByPeriod.ChartOfAccounts = AccountingSettingsForOtherTransactionsCr.ChartOfAccounts
	|		 AND AccountingSettingsForOtherTransactionsCr.DebitCredit = CASE
	|			WHEN RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr
	|				THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|			ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|		 END
	|		AND RegisteredRecordsDebitCredit.RegisterNameCr = &RegisterNameOtherAssetsLiabilities
	|		AND VALUETYPE(RegisteredRecordsDebitCredit.SettingObject1Cr) <> TYPE(Catalog.OtherTransactionsGLAccountsSettings)
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTSignsOfCorrespondenceAccounting AS SignsOfCorrespondenceAccounting
	|		WHERE
	|			SignsOfCorrespondenceAccounting.AccountingObjectDr = RegisteredRecordsDebitCredit.AccountingObjectDr
	|			AND SignsOfCorrespondenceAccounting.AccountingObjectCr = RegisteredRecordsDebitCredit.AccountingObjectCr
	|			AND SignsOfCorrespondenceAccounting.AccountingFlag = &AttributeOfAccountingRevenueWithoutVAT
	|			AND SignsOfCorrespondenceAccounting.Value <> TransactionSettingsByPeriod.RevenueExcludingVAT
	|		)
	|	AND ((RegisteredRecordsDebitCredit.AccountingObjectDr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		AND RegisteredRecordsDebitCredit.AccountingObjectCr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues))
	|		OR TransactionSettingsByPeriod.MethodOfAccountingForImproperValues = VALUE(Enum.MethodsOfNotOwnedControlledValuesAccounting.RecordedOnOffBalanceAccounts))
	|INDEX BY
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	SettingObject1Dr,
	|	SettingObject1Cr,
	|	PlaceOfRegistrationDr,
	|	PlaceOfRegistrationCr,
	|	Organization,
	|	ChartOfAccounts,
	|	PostingGenerationSetting
	|");
	
	DeletedTemporaryTables = New Array();
	DeletedTemporaryTables.Add("TTMovementDebitCredit");
	DeletedTemporaryTables.Add("TTSourcesWithDueDates");
	DeletedTemporaryTables.Add("TTSettingsForTransactionsByPeriod");
	DeletedTemporaryTables.Add("TTAccountingPolicyForPeriods");
	DeletedTemporaryTables.Add("TTSettingsOfOperations");
	DeletedTemporaryTables.Add("TTSignsOfCorrespondenceAccounting");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsDebitCredit.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsDebitCredit.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsDebitCredit.LongTermDr AS LongTermDr,
	|	RegisteredRecordsDebitCredit.LongTermCr AS LongTermCr,
	|	ISNULL(CASE
	|		WHEN VALUETYPE(RegisteredRecordsDebitCredit.SettingObject1Dr) = TYPE(Catalog.OtherTransactionsGLAccountsSettings)
	|			THEN AccountSettingsForOtherDrOperations.GLAccount
	|		WHEN RegisteredRecordsDebitCredit.LongTermDr
	|			THEN AccountsOfAccountingObjectsDr.LedgerAccountLongTerm
	|		ELSE AccountsOfAccountingObjectsDr.GLAccount
	|	END, VALUE(ChartOfAccounts.International.EmptyRef)) AS GLAccountDr,
	|	ISNULL(CASE
	|		WHEN VALUETYPE(RegisteredRecordsDebitCredit.SettingObject1Cr) = TYPE(Catalog.OtherTransactionsGLAccountsSettings)
	|			THEN AccountSettingsForOtherCrOperations.GLAccount
	|		WHEN RegisteredRecordsDebitCredit.LongTermCr
	|			THEN AccountsOfAccountingObjectsCr.LedgerAccountLongTerm
	|		ELSE AccountsOfAccountingObjectsCr.GLAccount
	|	END, VALUE(ChartOfAccounts.International.EmptyRef)) AS GLAccountCr,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsDebitCredit.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
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
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsDebitCredit.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsDebitCredit.CountDr AS CountDr,
	|	RegisteredRecordsDebitCredit.CountCr AS CountCr
	|INTO TTMovementWithDebitCreditAccounts
	|FROM
	|	TTMovementWithDebitCreditSettings AS RegisteredRecordsDebitCredit
	|	LEFT JOIN TTAccountsOfAccountingObjects AS AccountsOfAccountingObjectsDr
	|		ON RegisteredRecordsDebitCredit.AccountingObjectDr = AccountsOfAccountingObjectsDr.AccountingObject
	|		 AND RegisteredRecordsDebitCredit.SettingObject1Dr = AccountsOfAccountingObjectsDr.SettingObject1
	|		 AND RegisteredRecordsDebitCredit.PlaceOfRegistrationDr = AccountsOfAccountingObjectsDr.PlaceOfRegistration
	|		 AND RegisteredRecordsDebitCredit.Organization = AccountsOfAccountingObjectsDr.Organization
	|		 AND RegisteredRecordsDebitCredit.ChartOfAccounts = AccountsOfAccountingObjectsDr.ChartOfAccounts
	|		 AND RegisteredRecordsDebitCredit.PostingGenerationSetting = AccountsOfAccountingObjectsDr.PostingGenerationSetting
	|	LEFT JOIN TTAccountsOfAccountingObjects AS AccountsOfAccountingObjectsCr
	|		ON RegisteredRecordsDebitCredit.AccountingObjectCr = AccountsOfAccountingObjectsCr.AccountingObject
	|		 AND RegisteredRecordsDebitCredit.SettingObject1Cr = AccountsOfAccountingObjectsCr.SettingObject1
	|		 AND RegisteredRecordsDebitCredit.PlaceOfRegistrationCr = AccountsOfAccountingObjectsCr.PlaceOfRegistration
	|		 AND RegisteredRecordsDebitCredit.Organization = AccountsOfAccountingObjectsCr.Organization
	|		 AND RegisteredRecordsDebitCredit.ChartOfAccounts = AccountsOfAccountingObjectsCr.ChartOfAccounts
	|		 AND RegisteredRecordsDebitCredit.PostingGenerationSetting = AccountsOfAccountingObjectsCr.PostingGenerationSetting
	|	LEFT JOIN Catalog.OtherTransactionsGLAccountsSettings.FinancialAccountingSettings AS AccountSettingsForOtherDrOperations
	|		ON RegisteredRecordsDebitCredit.SettingObject1Dr = AccountSettingsForOtherDrOperations.Ref
	|		 AND RegisteredRecordsDebitCredit.ChartOfAccounts = AccountSettingsForOtherDrOperations.ChartOfAccounts
	|	LEFT JOIN Catalog.OtherTransactionsGLAccountsSettings.FinancialAccountingSettings AS AccountSettingsForOtherCrOperations
	|		ON RegisteredRecordsDebitCredit.SettingObject1Cr = AccountSettingsForOtherCrOperations.Ref
	|		 AND RegisteredRecordsDebitCredit.ChartOfAccounts = AccountSettingsForOtherCrOperations.ChartOfAccounts
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	RegisterNameDr,
	|	RegisterNameCr,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	GLAccountDr,
	|	GLAccountCr
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementWithDebitCreditSettings");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAccountsOfAccountingObjects");
	
EndProcedure

Procedure CheckCorrespondenceErrors(Query, QueriesTexts, TableOfTransactions, ParametersForGeneratingTransactions)
	
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.LongTermDr AS LongTermDr,
	|	RegisteredRecordsWithAccounts.LongTermCr AS LongTermCr,
	|	RegisteredRecordsWithAccounts.GLAccountDr AS GLAccountDr,
	|	RegisteredRecordsWithAccounts.GLAccountCr AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumManDr,
	|	RegisteredRecordsWithAccounts.SumManCr AS SumManCr,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithAccounts.SumComplCr AS SumComplCr
	|INTO TTCorrespondenceErrors
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsWithAccounts
	|WHERE
	|	RegisteredRecordsWithAccounts.RegisterNameDr = """"
	|	OR RegisteredRecordsWithAccounts.RegisterNameCr = """"
	|	OR RegisteredRecordsWithAccounts.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	OR RegisteredRecordsWithAccounts.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	OR RegisteredRecordsWithAccounts.FinRecordID = """"
	|	OR RegisteredRecordsWithAccounts.SumManDr <> RegisteredRecordsWithAccounts.SumManCr
	|	OR RegisteredRecordsWithAccounts.SumComplDr <> RegisteredRecordsWithAccounts.SumComplCr
	|	OR RegisteredRecordsWithAccounts.ChartOfAccounts = VALUE(Catalog.FinancialAccountingChartsOfAccounts.EmptyRef)
	|	OR RegisteredRecordsWithAccounts.PostingGenerationSetting = VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)
	|	OR (RegisteredRecordsWithAccounts.GLAccountDr = VALUE(ChartOfAccounts.International.EmptyRef)
	|		AND RegisteredRecordsWithAccounts.AccountingObjectDr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		AND (RegisteredRecordsWithAccounts.ChartOfAccounts.TransactionsWithCorrespondence
	|			OR RegisteredRecordsWithAccounts.RegisterNameDr <> &NameOfRegisterOfServiceAccountingObjects
	|			OR RegisteredRecordsWithAccounts.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)))
	|	OR (RegisteredRecordsWithAccounts.GLAccountCr = VALUE(ChartOfAccounts.International.EmptyRef)
	|		AND RegisteredRecordsWithAccounts.AccountingObjectCr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		AND (RegisteredRecordsWithAccounts.ChartOfAccounts.TransactionsWithCorrespondence
	|			OR RegisteredRecordsWithAccounts.RegisterNameCr <> &NameOfRegisterOfServiceAccountingObjects
	|			OR RegisteredRecordsWithAccounts.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)))
	|
	|UNION ALL
	|
	|SELECT
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	FALSE AS LongTermDr,
	|	FALSE AS LongTermCr,
	|	MAX(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.GLAccountDr
	|		ELSE VALUE(ChartOfAccounts.International.EmptyRef)
	|	END) AS GLAccountDr,
	|	MAX(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.GLAccountCr
	|		ELSE VALUE(ChartOfAccounts.International.EmptyRef)
	|	END) AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	&NameOfRegisterOfServiceAccountingObjects AS RegisterNameDr,
	|	&NameOfRegisterOfServiceAccountingObjects AS RegisterNameCr,
	|	MAX(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.AccountingObjectDr
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END) AS AccountingObjectDr,
	|	MAX(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.AccountingObjectCr
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END) AS AccountingObjectCr,
	|	UNDEFINED AS SettingObject1Dr,
	|	UNDEFINED AS SettingObject1Cr,
	|	FALSE AS ThisIsReverseTransactionDr,
	|	FALSE AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS SettingUpBusinessTransaction,
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumManDr
	|		ELSE 0
	|	END) AS SumManDr,
	|	SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumManCr
	|		ELSE 0
	|	END) AS SumManCr,
	|	SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumComplDr
	|		ELSE 0
	|	END) AS SumComplDr,
	|	SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumComplCr
	|		ELSE 0
	|	END) AS SumComplCr
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsWithAccounts
	|WHERE
	|	(RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|	AND NOT RegisteredRecordsWithAccounts.AccountingObjectDr IN
	|		(VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry),
	|		 VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)))
	|	OR
	|	(RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|	AND NOT RegisteredRecordsWithAccounts.AccountingObjectCr IN
	|		(VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry),
	|		 VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)))
	|GROUP BY
	|	RegisteredRecordsWithAccounts.Period,
	|	RegisteredRecordsWithAccounts.Recorder,
	|	RegisteredRecordsWithAccounts.Organization,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting
	|HAVING
	|	SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumManDr
	|		ELSE 0
	|	END) <> SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumManCr
	|		ELSE 0
	|	END)
	|	OR
	|	SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumComplDr
	|		ELSE 0
	|	END) <> SUM(CASE
	|		WHEN RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN RegisteredRecordsWithAccounts.SumComplCr
	|		ELSE 0
	|	END)
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	Organization,
	|	ChartOfAccounts
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.ChartOfAccounts AS ChartOfAccounts,
	|	CorrespondencesErrors.PostingGenerationSetting AS PostingGenerationSetting,
	|	CorrespondencesErrors.LongTermDr AS LongTermDr,
	|	CorrespondencesErrors.LongTermCr AS LongTermCr,
	|	CorrespondencesErrors.GLAccountDr AS GLAccountDr,
	|	CorrespondencesErrors.GLAccountCr AS GLAccountCr,
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.RegisterNameDr AS RegisterNameDr,
	|	CorrespondencesErrors.RegisterNameCr AS RegisterNameCr,
	|	CorrespondencesErrors.AccountingObjectDr AS AccountingObjectDr,
	|	CorrespondencesErrors.AccountingObjectCr AS AccountingObjectCr,
	|	CorrespondencesErrors.SettingObject1Dr AS SettingObject1Dr,
	|	CorrespondencesErrors.SettingObject1Cr AS SettingObject1Cr,
	|	VALUETYPE(CorrespondencesErrors.SettingObject1Dr) AS TypeOfConfigurationObjectDr,
	|	VALUETYPE(CorrespondencesErrors.SettingObject1Cr) AS TypeOfConfigurationObjectCr,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder,
	|	CorrespondencesErrors.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondencesErrors.FinRecordID AS FinRecordID,
	|	CorrespondencesErrors.SumManDr AS SumManDr,
	|	CorrespondencesErrors.SumManCr AS SumManCr,
	|	CorrespondencesErrors.SumComplDr AS SumComplDr,
	|	CorrespondencesErrors.SumComplCr AS SumComplCr
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.ChartOfAccounts AS ChartOfAccounts,
	|	CorrespondencesErrors.ChartOfAccounts.TransactionsWithCorrespondence AS TransactionsWithCorrespondence,
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|GROUP BY
	|	CorrespondencesErrors.Period,
	|	CorrespondencesErrors.Recorder,
	|	CorrespondencesErrors.Organization,
	|	CorrespondencesErrors.ChartOfAccounts
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	Selection = Results[Results.UBound() - 1].Select();
	TransactionSelection_ = Results[Results.UBound()].Select();
	
	While TransactionSelection_.Next() Do
		NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
		FillPropertyValues(NewEntry, TransactionSelection_, "ChartOfAccounts,Period,Organization,Recorder");
		ErrorsAndTransactionStatuses = New Map();
		
		TheStructureOfTheSearch = New Structure("ChartOfAccounts,Period,Organization,Recorder");
		FillPropertyValues(TheStructureOfTheSearch, TransactionSelection_);
		
		Selection.Reset();
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			If Not ValueIsFilled(Selection.FinRecordID) Then
				
				TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
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
				ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				
			ElsIf Not ValueIsFilled(Selection.RegisterNameDr) Then
				
				TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
				ErrorText = StrTemplate(NStr("vi = 'Không tìm thấy đối ứng cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
											|ru = 'Не найдена корреспонденция для записи регистра ""%1"" с идентификатором %2';
											|en = 'Correspondence for the ""%1"" register record with the %2 ID is not found'; fa = 'Correspondence for the ""%1"" register record with the %2 ID is not found';
											|it = 'Corrispondenza per la registrazione del registro ""%1"" con identificativo %2 non trovata';
											|pl = 'Nie znaleziono korespondencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
											|tr = '%2 kimlikli ''""%1"" kayıt girişi için yazışma bulunamadı'"),
					Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr]),
					Selection.FinRecordID);
				ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				
			ElsIf Not ValueIsFilled(Selection.RegisterNameCr) Then
				
				TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
				ErrorText = StrTemplate(NStr("vi = 'Không tìm thấy đối ứng cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
											|ru = 'Не найдена корреспонденция для записи регистра ""%1"" с идентификатором %2';
											|en = 'Correspondence for the ""%1"" register record with the %2 ID is not found'; fa = 'Correspondence for the ""%1"" register record with the %2 ID is not found';
											|it = 'Corrispondenza per la registrazione del registro ""%1"" con identificativo %2 non trovata';
											|pl = 'Nie znaleziono korespondencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
											|tr = '%2 kimlikli ''""%1"" kayıt girişi için yazışma bulunamadı'"),
					Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
					Selection.FinRecordID);
				ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				
			Else
				
				If Not ValueIsFilled(Selection.AccountingObjectDr)
					And Selection.RegisterNameDr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
					ErrorText = StrTemplate(NStr("vi = 'Chưa xác định đối tượng kế toán cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
												|ru = 'Не определен объект учета для записи регистра ""%1"" с идентификатором %2';
												|en = 'Accounting object is not defined for the ""%1"" register record with the %2 ID'; fa = 'Accounting object is not defined for the ""%1"" register record with the %2 ID';
												|it = 'Oggetto di contabilità per la registrazione del registro ""%1"" con identificativo %2 non definito';
												|pl = 'Nie określono obiektu ewidencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
												|tr = '%2 kimlikli ""%1"" kayıt girişi için hesap nesnesi tanımlanmadı'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
						Selection.FinRecordID);
					ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				EndIf;
				
				If Not ValueIsFilled(Selection.AccountingObjectCr)
					And Selection.RegisterNameCr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
					ErrorText = StrTemplate(NStr("vi = 'Chưa xác định đối tượng kế toán cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
												|ru = 'Не определен объект учета для записи регистра ""%1"" с идентификатором %2';
												|en = 'Accounting object is not defined for the ""%1"" register record with the %2 ID'; fa = 'Accounting object is not defined for the ""%1"" register record with the %2 ID';
												|it = 'Oggetto di contabilità per la registrazione del registro ""%1"" con identificativo %2 non definito';
												|pl = 'Nie określono obiektu ewidencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
												|tr = '%2 kimlikli ""%1"" kayıt girişi için hesap nesnesi tanımlanmadı'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr]),
						Selection.FinRecordID);
					ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				EndIf;
				
				If Selection.SumManDr <> Selection.SumManCr Then
					TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
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
					ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				EndIf;
				
				If Selection.SumComplDr <> Selection.SumComplCr Then
					TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
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
					ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				EndIf;
			EndIf;
			
			If Not ValueIsFilled(Selection.ChartOfAccounts) Then
				
				TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined;
				ErrorText = StrTemplate(NStr("vi = 'Chưa xác định hệ thống tài khoản kế toán quốc tế của doanh nghiệp ""%1""';
											|ru = 'Не определен план счетов международного учета организации ""%1""';
											|en = 'Financial accounting chart of accounts of the ""%1"" company is not defined'; fa = 'Financial accounting chart of accounts of the ""%1"" company is not defined';
											|it = 'Il piano dei conti internazionale dell''azienda ""%1"" non è definito';
											|pl = 'Nie określono planu kont ewidencji międzynarodowej firmy ""%1""';
											|tr = '""%1"" iş yerinin uluslararası muhasebesi için hesap planı tanımlanmadı'"), Selection.Organization);
				ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				
			ElsIf Not ValueIsFilled(Selection.PostingGenerationSetting) Then
				
				TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined;
				ErrorText = StrTemplate(NStr("vi = 'Chưa xác định tùy chỉnh lập các bút toán của doanh nghiệp ""%1"" theo hệ thống tài khoản ""%2""';
											|ru = 'Не определена настройка формирования проводок организации ""%1"" по плану счетов ""%2""';
											|en = 'Posting schema of the ""%1"" company for the ""%2"" chart of accounts is not defined'; fa = 'Posting schema of the ""%1"" company for the ""%2"" chart of accounts is not defined';
											|it = 'Le impostazioni di generazione delle registrazioni dell''azienda ""%1"" per il piano dei conti ""%2"" non sono definite';
											|pl = 'Nie określono ustawienia tworzenia dekretowań firmy ""%1"" według planu kont ""%2""';
											|tr = '""%1"" iş yeri için ""%2"" hesap planına göre hareket oluşturma ayarı tanımlı değil'"),
					Selection.Organization, Selection.ChartOfAccounts);
				ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				
			Else
				
				If Not ValueIsFilled(Selection.GLAccountDr) And ValueIsFilled(Selection.AccountingObjectDr)
				   And (TransactionSelection_.TransactionsWithCorrespondence
						Or Selection.RegisterNameDr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects()
						Or Selection.AccountingObjectDr = ChartsOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
				   And Selection.AccountingObjectDr <> ChartsOfCharacteristicTypes.AssetLiabilityItems.ImproperValues Then
					TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined;
					If Selection.TypeOfConfigurationObjectDr = Type("CatalogRef.OtherTransactionsGLAccountsSettings") Then
						ErrorText = StrTemplate(
							NStr("vi = 'Trong chứng từ chưa chỉ ra tài khoản kế toán theo dạng tài sản và nguồn vốn ""%1""';
								|ru = 'В документе не указан счет учета по статье активов и пассивов ""%1""';
								|en = 'The ledger account for the ""%1"" asset and liability item is not specified in the document'; fa = 'The ledger account for the ""%1"" asset and liability item is not specified in the document';
								|it = 'В документе не указан счет учета по статье активов и пассивов ""%1""';
								|pl = 'The ledger account for the ""%1"" asset and liability item is not specified in the document';
								|tr = 'Bu belgede ""%1"" varlıklar ve yükümlülükler kaleminin defterikebir hesabı belirtilmemiştir'"),
							Selection.AccountingObjectDr);
					Else
						RegisterEmptyAccountForConfiguration(Selection, "Dr");
						ErrorText = StrTemplate(
							NStr("vi = 'Chưa tùy chỉnh tài khoản kế toán %1 cho đối tượng kế toán ""%2"" từ %3';
								|ru = 'Не настроен %1 счет учета для объекта учета ""%2"" с %3';
								|en = 'The %1 ledger account is not set up for the ""%2"" accounting object with %3'; fa = 'The %1 ledger account is not set up for the ""%2"" accounting object with %3';
								|it = 'Не настроен %1 счет учета для объекта учета ""%2"" с %3';
								|pl = 'The %1 ledger account is not set up for the ""%2"" accounting object with %3';
								|tr = '%1 defterikebir hesabı, %3 itibarıyla ""%2"" muhasebe nesnesi için ayarlanmamıştır.'"),
							Lower(PresentationOfAppealPeriod(Selection, Query.Parameters, "Dr")),
							Selection.AccountingObjectDr,
							?(ValueIsFilled(Selection.SettingObject1Dr),
								StrTemplate(NStr("vi = 'tùy chỉnh ""%1""';
												|ru = 'настройкой ""%1""';
												|en = 'the ""%1"" setting'; fa = 'the ""%1"" setting';
												|it = 'impostazione ""%1""';
												|pl = 'ustawieniem ""%1""';
												|tr = '""%1"" ayar ile'"), Selection.SettingObject1Dr),
								NStr("vi = 'tùy chỉnh trống';
									|ru = 'пустой настройкой';
									|en = 'empty setting'; fa = 'empty setting';
									|it = 'impostazione vuota';
									|pl = 'pustym ustawieniem';
									|tr = 'boş ayar ile'")));
					EndIf;
					ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				EndIf;
				
				If Not ValueIsFilled(Selection.GLAccountCr) And ValueIsFilled(Selection.AccountingObjectCr)
				   And (TransactionSelection_.TransactionsWithCorrespondence
						Or Selection.RegisterNameCr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects()
						Or Selection.AccountingObjectCr = ChartsOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
				   And Selection.AccountingObjectCr <> ChartsOfCharacteristicTypes.AssetLiabilityItems.ImproperValues Then
					TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined;
					If Selection.TypeOfConfigurationObjectCr = Type("CatalogRef.OtherTransactionsGLAccountsSettings") Then
						ErrorText = StrTemplate(
							NStr("vi = 'Trong chứng từ chưa chỉ ra tài khoản kế toán theo dạng tài sản và nguồn vốn ""%1""';
								|ru = 'В документе не указан счет учета по статье активов и пассивов ""%1""';
								|en = 'The ledger account for the ""%1"" asset and liability item is not specified in the document'; fa = 'The ledger account for the ""%1"" asset and liability item is not specified in the document';
								|it = 'В документе не указан счет учета по статье активов и пассивов ""%1""';
								|pl = 'The ledger account for the ""%1"" asset and liability item is not specified in the document';
								|tr = 'Bu belgede ""%1"" varlıklar ve yükümlülükler kaleminin defterikebir hesabı belirtilmemiştir'"),
							Selection.AccountingObjectCr);
					Else
						RegisterEmptyAccountForConfiguration(Selection, "Cr");
						ErrorText = StrTemplate(
							NStr("vi = 'Chưa tùy chỉnh tài khoản kế toán %1 cho đối tượng kế toán ""%2"" từ %3';
								|ru = 'Не настроен %1 счет учета для объекта учета ""%2"" с %3';
								|en = 'The %1 ledger account is not set up for the ""%2"" accounting object with %3'; fa = 'The %1 ledger account is not set up for the ""%2"" accounting object with %3';
								|it = 'Не настроен %1 счет учета для объекта учета ""%2"" с %3';
								|pl = 'The %1 ledger account is not set up for the ""%2"" accounting object with %3';
								|tr = '%1 defterikebir hesabı, %3 itibarıyla ""%2"" muhasebe nesnesi için ayarlanmamıştır.'"),
							Lower(PresentationOfAppealPeriod(Selection, Query.Parameters, "Cr")),
							Selection.AccountingObjectCr,
							?(ValueIsFilled(Selection.SettingObject1Cr),
								StrTemplate(NStr("vi = 'tùy chỉnh ""%1""';
												|ru = 'настройкой ""%1""';
												|en = 'the ""%1"" setting'; fa = 'the ""%1"" setting';
												|it = 'impostazione ""%1""';
												|pl = 'ustawieniem ""%1""';
												|tr = '""%1"" ayar ile'"), Selection.SettingObject1Cr),
								NStr("vi = 'tùy chỉnh trống';
									|ru = 'пустой настройкой';
									|en = 'empty setting'; fa = 'empty setting';
									|it = 'impostazione vuota';
									|pl = 'pustym ustawieniem';
									|tr = 'boş ayar ile'")));
					EndIf;
					ErrorsAndTransactionStatuses.Insert(ErrorText, TransactionStatus_);
				EndIf;
			EndIf;
		EndDo;
		
		For Each KeyAndValue In ErrorsAndTransactionStatuses Do
			FinancialAccountingPostingServer.AddTransactionError(NewEntry, KeyAndValue.Key);
			FinancialAccountingPostingServer.FillInTransactionStatus(NewEntry, KeyAndValue.Value);
		EndDo;
		
		FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
	EndDo;
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.ChartOfAccounts AS ChartOfAccounts,
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder
	|INTO TTLoggersWithErrors
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|GROUP BY
	|	CorrespondencesErrors.Period,
	|	CorrespondencesErrors.Recorder,
	|	CorrespondencesErrors.Organization,
	|	CorrespondencesErrors.ChartOfAccounts
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	ChartOfAccounts
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.LongTermDr AS LongTermDr,
	|	RegisteredRecordsWithAccounts.LongTermCr AS LongTermCr,
	|	RegisteredRecordsWithAccounts.GLAccountDr AS GLAccountDr,
	|	RegisteredRecordsWithAccounts.GLAccountCr AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.PostingGenerationSetting.MethodOfCancelingTransactions
	|		= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|			THEN RegisteredRecordsWithAccounts.SumManDr < 0
	|			  OR RegisteredRecordsWithAccounts.SumManCr < 0
	|			  OR RegisteredRecordsWithAccounts.SumComplDr < 0
	|			  OR RegisteredRecordsWithAccounts.SumComplCr < 0
	|			  OR RegisteredRecordsWithAccounts.SumCurrDr < 0
	|			  OR RegisteredRecordsWithAccounts.SumCurrCr < 0
	|			  OR RegisteredRecordsWithAccounts.CountDr < 0
	|			  OR RegisteredRecordsWithAccounts.CountCr < 0
	|		ELSE RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr OR RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr
	|	END AS InvertEntriy,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsWithAccounts.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumManDr,
	|	RegisteredRecordsWithAccounts.SumManCr AS SumManCr,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithAccounts.SumComplCr AS SumComplCr,
	|	RegisteredRecordsWithAccounts.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsWithAccounts.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsWithAccounts.CountDr AS CountDr,
	|	RegisteredRecordsWithAccounts.CountCr AS CountCr
	|INTO TTMovementWithAccounts
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsWithAccounts
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTLoggersWithErrors AS LoggersWithErrors
	|		WHERE
	|			LoggersWithErrors.Period = RegisteredRecordsWithAccounts.Period
	|			AND LoggersWithErrors.Recorder = RegisteredRecordsWithAccounts.Recorder
	|			AND LoggersWithErrors.Organization = RegisteredRecordsWithAccounts.Organization
	|			AND LoggersWithErrors.ChartOfAccounts = RegisteredRecordsWithAccounts.ChartOfAccounts
	|		)
	|INDEX BY
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	LongTermDr,
	|	LongTermCr,
	|	InvertEntriy,
	|	RegisterNameDr,
	|	RegisterNameCr
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementWithDebitCreditAccounts");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTLoggersWithErrors");
	
EndProcedure

Procedure SkipCorrespondenceErrorChecking(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.LongTermDr AS LongTermDr,
	|	RegisteredRecordsWithAccounts.LongTermCr AS LongTermCr,
	|	RegisteredRecordsWithAccounts.GLAccountDr AS GLAccountDr,
	|	RegisteredRecordsWithAccounts.GLAccountCr AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.PostingGenerationSetting.MethodOfCancelingTransactions
	|		= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|			THEN RegisteredRecordsWithAccounts.SumManDr < 0
	|			  OR RegisteredRecordsWithAccounts.SumManCr < 0
	|			  OR RegisteredRecordsWithAccounts.SumComplDr < 0
	|			  OR RegisteredRecordsWithAccounts.SumComplCr < 0
	|			  OR RegisteredRecordsWithAccounts.SumCurrDr < 0
	|			  OR RegisteredRecordsWithAccounts.SumCurrCr < 0
	|			  OR RegisteredRecordsWithAccounts.CountDr < 0
	|			  OR RegisteredRecordsWithAccounts.CountCr < 0
	|		ELSE RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr OR RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr
	|	END AS InvertEntriy,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsWithAccounts.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumManDr,
	|	RegisteredRecordsWithAccounts.SumManCr AS SumManCr,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithAccounts.SumComplCr AS SumComplCr,
	|	RegisteredRecordsWithAccounts.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsWithAccounts.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsWithAccounts.CountDr AS CountDr,
	|	RegisteredRecordsWithAccounts.CountCr AS CountCr
	|INTO TTMovementWithAccounts
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsWithAccounts
	|INDEX BY
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	LongTermDr,
	|	LongTermCr,
	|	InvertEntriy,
	|	RegisterNameDr,
	|	RegisterNameCr
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementWithDebitCreditAccounts");
	
EndProcedure

Procedure CreateTableOfRegisteredRecordsOfServiceAccountingObjects(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	TRUE AS ThisIsDebit,
	|	FALSE AS ThisIsLoan,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterName,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObject,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistration,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransaction,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowID,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS Currency,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDate,
	|	SUM(RegisteredRecordsWithAccounts.SumManDr) AS SumMan,
	|	SUM(RegisteredRecordsWithAccounts.SumComplDr) AS SumCompl,
	|	SUM(RegisteredRecordsWithAccounts.SumCurrDr) AS SumCurr,
	|	SUM(RegisteredRecordsWithAccounts.CountDr) AS Count
	|INTO PlacementTable
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|WHERE
	|	RegisteredRecordsWithAccounts.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|GROUP BY
	|	RegisteredRecordsWithAccounts.Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.Recorder,
	|	RegisteredRecordsWithAccounts.Organization,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr,
	|	RegisteredRecordsWithAccounts.CurrencyDr,
	|	RegisteredRecordsWithAccounts.MaturityDateDr
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS ThisIsDebit,
	|	TRUE AS ThisIsLoan,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterName,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObject,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistration,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransaction,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowID,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS Currency,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDate,
	|	SUM(RegisteredRecordsWithAccounts.SumManCr) AS SumMan,
	|	SUM(RegisteredRecordsWithAccounts.SumComplCr) AS SumCompl,
	|	SUM(RegisteredRecordsWithAccounts.SumCurrCr) AS SumCurr,
	|	SUM(RegisteredRecordsWithAccounts.CountCr) AS Count
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|WHERE
	|	RegisteredRecordsWithAccounts.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|GROUP BY
	|	RegisteredRecordsWithAccounts.Period,
	|	RegisteredRecordsWithAccounts.RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.Recorder,
	|	RegisteredRecordsWithAccounts.Organization,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDCr,
	|	RegisteredRecordsWithAccounts.CurrencyCr,
	|	RegisteredRecordsWithAccounts.MaturityDateCr
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RowID,
	|	AccountingObject,
	|	SettingObject1,
	|	PlaceOfRegistration,
	|	MaturityDate,
	|	Organization,
	|	SettingUpBusinessTransaction
	|";
	
	QueryText = StrReplace(QueryText, "PlacementTable", "tt" + FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects());
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure DefineAccountsForIndividualCorrespondence(Query, QueriesTexts, RegisterRequestsTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	SpeedReflectionSettings.ApplicationProcedure AS ApplicationProcedure,
	|	SpeedReflectionSettings.ItIsNotReflectedInTheAccounts AS ItIsNotReflectedInTheAccounts,
	|	SpeedReflectionSettings.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	SpeedReflectionSettings.InvertTheResourceSign AS InvertTheResourceSign,
	|	SpeedReflectionSettings.ApplySubsequentSettings AS ApplySubsequentSettings,
	|	SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr AS CustomSettingOfExtdimensionFillingDr,
	|	SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr AS CustomSettingOfExtdimensionFillingCr,
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr AS UseCorrespondenceSettingsDr,
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr AS UseCorrespondenceSettingsCr,
	|	SpeedReflectionSettings.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	SpeedReflectionSettings.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	CASE
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN RegisteredRecordsWithAccounts.GLAccountDr
	|		ELSE SpeedReflectionSettings.GLAccountDr
	|	END AS GLAccountDr,
	|	CASE
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN RegisteredRecordsWithAccounts.GLAccountCr
	|		ELSE SpeedReflectionSettings.GLAccountCr
	|	END AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.LongTermDr AS LongTermDr,
	|	RegisteredRecordsWithAccounts.LongTermCr AS LongTermCr,
	|	RegisteredRecordsWithAccounts.RecNo AS RecNo,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.InvertEntriy AS InvertEntriy,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsWithAccounts.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumManDr,
	|	RegisteredRecordsWithAccounts.SumManCr AS SumManCr,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithAccounts.SumComplCr AS SumComplCr,
	|	RegisteredRecordsWithAccounts.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsWithAccounts.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsWithAccounts.CountDr AS CountDr,
	|	RegisteredRecordsWithAccounts.CountCr AS CountCr
	|INTO TTRpmForSetting
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|	INNER JOIN InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SpeedReflectionSettings
	|		ON RegisteredRecordsWithAccounts.ChartOfAccounts = SpeedReflectionSettings.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = SpeedReflectionSettings.PostingGenerationSetting
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectDr = SpeedReflectionSettings.AccountingObjectDr
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectCr = SpeedReflectionSettings.AccountingObjectCr
	|		 AND RegisteredRecordsWithAccounts.LongTermDr = SpeedReflectionSettings.LongTermDr
	|		 AND RegisteredRecordsWithAccounts.LongTermCr = SpeedReflectionSettings.LongTermCr
	|		 AND NOT RegisteredRecordsWithAccounts.InvertEntriy
	|
	|UNION ALL
	|
	|SELECT
	|	SpeedReflectionSettings.ApplicationProcedure AS ApplicationProcedure,
	|	SpeedReflectionSettings.ItIsNotReflectedInTheAccounts AS ItIsNotReflectedInTheAccounts,
	|	SpeedReflectionSettings.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	SpeedReflectionSettings.InvertTheResourceSign AS InvertTheResourceSign,
	|	SpeedReflectionSettings.ApplySubsequentSettings AS ApplySubsequentSettings,
	|	SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr AS CustomSettingOfExtdimensionFillingDr,
	|	SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr AS CustomSettingOfExtdimensionFillingCr,
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr AS UseCorrespondenceSettingsDr,
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr AS UseCorrespondenceSettingsCr,
	|	SpeedReflectionSettings.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	SpeedReflectionSettings.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	CASE
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN RegisteredRecordsWithAccounts.GLAccountCr
	|		ELSE SpeedReflectionSettings.GLAccountDr
	|	END AS GLAccountDr,
	|	CASE
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN RegisteredRecordsWithAccounts.GLAccountDr
	|		ELSE SpeedReflectionSettings.GLAccountCr
	|	END AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.LongTermCr AS LongTermDr,
	|	RegisteredRecordsWithAccounts.LongTermDr AS LongTermCr,
	|	RegisteredRecordsWithAccounts.RecNo AS RecNo,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.InvertEntriy AS InvertEntriy,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowIDDr,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowIDCr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectCr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectDr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsWithAccounts.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS CurrencyDr,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS CurrencyCr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDateDr,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDateCr,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumManDr,
	|	RegisteredRecordsWithAccounts.SumManCr AS SumManCr,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithAccounts.SumComplCr AS SumComplCr,
	|	RegisteredRecordsWithAccounts.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsWithAccounts.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsWithAccounts.CountDr AS CountDr,
	|	RegisteredRecordsWithAccounts.CountCr AS CountCr
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|	INNER JOIN InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SpeedReflectionSettings
	|		ON RegisteredRecordsWithAccounts.ChartOfAccounts = SpeedReflectionSettings.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = SpeedReflectionSettings.PostingGenerationSetting
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectDr = SpeedReflectionSettings.AccountingObjectCr
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectCr = SpeedReflectionSettings.AccountingObjectDr
	|		 AND RegisteredRecordsWithAccounts.LongTermDr = SpeedReflectionSettings.LongTermCr
	|		 AND RegisteredRecordsWithAccounts.LongTermCr = SpeedReflectionSettings.LongTermDr
	|		 AND RegisteredRecordsWithAccounts.InvertEntriy
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
	|	SourceConfigurationObjectDr,
	|	SourceConfigurationObjectCr,
	|	PlaceOfRegistrationDr,
	|	PlaceOfRegistrationCr,
	|	MaturityDateDr,
	|	MaturityDateCr,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	ThereIsAdditionalSelectionDr,
	|	ThereIsAdditionalSelectionCr
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RevolutionsForTuning.ChartOfAccounts AS ChartOfAccounts,
	|	RevolutionsForTuning.PostingGenerationSetting AS PostingGenerationSetting,
	|	RevolutionsForTuning.RegisterNameDr AS RegisterNameDr,
	|	RevolutionsForTuning.RegisterNameCr AS RegisterNameCr,
	|	RevolutionsForTuning.AccountingObjectDr AS AccountingObjectDr,
	|	RevolutionsForTuning.AccountingObjectCr AS AccountingObjectCr,
	|	RevolutionsForTuning.LongTermDr AS LongTermDr,
	|	RevolutionsForTuning.LongTermCr AS LongTermCr,
	|	RevolutionsForTuning.ApplicationProcedure AS ApplicationProcedure,
	|	RevolutionsForTuning.InvertEntriy AS InvertEntriy,
	|	RevolutionsForTuning.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	RevolutionsForTuning.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr
	|INTO TTRevSettingKeys
	|FROM
	|	TTRpmForSetting AS RevolutionsForTuning
	|GROUP BY
	|	RevolutionsForTuning.ChartOfAccounts,
	|	RevolutionsForTuning.PostingGenerationSetting,
	|	RevolutionsForTuning.RegisterNameDr,
	|	RevolutionsForTuning.RegisterNameCr,
	|	RevolutionsForTuning.AccountingObjectDr,
	|	RevolutionsForTuning.AccountingObjectCr,
	|	RevolutionsForTuning.LongTermDr,
	|	RevolutionsForTuning.LongTermCr,
	|	RevolutionsForTuning.ApplicationProcedure,
	|	RevolutionsForTuning.InvertEntriy,
	|	RevolutionsForTuning.ThereIsAdditionalSelectionDr,
	|	RevolutionsForTuning.ThereIsAdditionalSelectionCr
	|INDEX BY
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	LongTermDr,
	|	LongTermCr,
	|	ApplicationProcedure,
	|	ThereIsAdditionalSelectionDr,
	|	ThereIsAdditionalSelectionCr
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RevSettingKeys.ChartOfAccounts AS ChartOfAccounts,
	|	RevSettingKeys.PostingGenerationSetting AS PostingGenerationSetting,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.AccountingObjectCr
	|		ELSE RevSettingKeys.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.AccountingObjectDr
	|		ELSE RevSettingKeys.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.LongTermCr
	|		ELSE RevSettingKeys.LongTermDr
	|	END AS LongTermDr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.LongTermDr
	|		ELSE RevSettingKeys.LongTermCr
	|	END AS LongTermCr,
	|	RevSettingKeys.ApplicationProcedure AS ApplicationProcedure,
	|	RevSettingKeys.InvertEntriy AS InvertEntriy,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr1
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr1
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValueDr1,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr2
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr2
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValueDr2,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr3
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr3
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValueDr3,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr1
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr1
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValueCr1,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr2
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr2
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValueCr2,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr3
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr3
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValueCr3
	|INTO TTValuesOfExtdimensionOfRevolutions
	|FROM
	|	TTRevSettingKeys AS RevSettingKeys
	|	INNER JOIN InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SpeedReflectionSettings
	|		ON RevSettingKeys.ChartOfAccounts = SpeedReflectionSettings.ChartOfAccounts
	|		 AND RevSettingKeys.PostingGenerationSetting = SpeedReflectionSettings.PostingGenerationSetting
	|		 AND RevSettingKeys.AccountingObjectDr = SpeedReflectionSettings.AccountingObjectDr
	|		 AND RevSettingKeys.AccountingObjectCr = SpeedReflectionSettings.AccountingObjectCr
	|		 AND RevSettingKeys.LongTermDr = SpeedReflectionSettings.LongTermDr
	|		 AND RevSettingKeys.LongTermCr = SpeedReflectionSettings.LongTermCr
	|		 AND RevSettingKeys.ApplicationProcedure = SpeedReflectionSettings.ApplicationProcedure
	|WHERE
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|	AND SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|	AND (SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|	) OR
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|	AND SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|	AND (SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|	)
	|GROUP BY
	|	RevSettingKeys.ChartOfAccounts,
	|	RevSettingKeys.PostingGenerationSetting,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.AccountingObjectCr
	|		ELSE RevSettingKeys.AccountingObjectDr
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.AccountingObjectDr
	|		ELSE RevSettingKeys.AccountingObjectCr
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.LongTermCr
	|		ELSE RevSettingKeys.LongTermDr
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.LongTermDr
	|		ELSE RevSettingKeys.LongTermCr
	|	END,
	|	RevSettingKeys.ApplicationProcedure,
	|	RevSettingKeys.InvertEntriy,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr1
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr1
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr2
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr2
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr3
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr3
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr1
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr1
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr2
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr2
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|					THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionDr3
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|					THEN UNDEFINED
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN SpeedReflectionSettings.SpecifiedValueIsExtdimensionCr3
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END
	|INDEX BY
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	ApplicationProcedure,
	|	InvertEntriy
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RevSettingKeys.ChartOfAccounts AS ChartOfAccounts,
	|	RevSettingKeys.PostingGenerationSetting AS PostingGenerationSetting,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.RegisterNameCr
	|		ELSE RevSettingKeys.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.RegisterNameDr
	|		ELSE RevSettingKeys.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.AccountingObjectCr
	|		ELSE RevSettingKeys.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.AccountingObjectDr
	|		ELSE RevSettingKeys.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.LongTermCr
	|		ELSE RevSettingKeys.LongTermDr
	|	END AS LongTermDr,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN RevSettingKeys.LongTermDr
	|		ELSE RevSettingKeys.LongTermCr
	|	END AS LongTermCr,
	|	RevSettingKeys.ApplicationProcedure AS ApplicationProcedure,
	|	RevSettingKeys.InvertEntriy AS InvertEntriy,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr1
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr1
	|		ELSE NULL
	|	END AS ExpressionOfExtdimensionDr1,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr2
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr2
	|		ELSE NULL
	|	END AS ExpressionOfExtdimensionDr2,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr3
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr3
	|		ELSE NULL
	|	END AS ExpressionOfExtdimensionDr3,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN FALSE
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN FALSE
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr1, 1, &LengthOfExpressionPrefixDr) = &ExtdimensionExpressionPrefixDr
	|				ELSE FALSE
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN FALSE
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN FALSE
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr1, 1, &LengthOfCrExpressionPrefix) = &ExtdimensionExpressionPrefixCr
	|		ELSE FALSE
	|	END AS CorExpressionDr1,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN FALSE
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN FALSE
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr2, 1, &LengthOfExpressionPrefixDr) = &ExtdimensionExpressionPrefixDr
	|				ELSE FALSE
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN FALSE
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN FALSE
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr2, 1, &LengthOfCrExpressionPrefix) = &ExtdimensionExpressionPrefixCr
	|		ELSE FALSE
	|	END AS CorExpressionDr2,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|					THEN FALSE
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|					THEN FALSE
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr3, 1, &LengthOfExpressionPrefixDr) = &ExtdimensionExpressionPrefixDr
	|				ELSE FALSE
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|			THEN FALSE
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|			THEN FALSE
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr3, 1, &LengthOfCrExpressionPrefix) = &ExtdimensionExpressionPrefixCr
	|		ELSE FALSE
	|	END AS CorExpressionDr3,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr1
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr1
	|		ELSE NULL
	|	END AS ExpressionOfExtdimensionCr1,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr2
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr2
	|		ELSE NULL
	|	END AS ExpressionOfExtdimensionCr2,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN NULL
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN NULL
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr3
	|				ELSE NULL
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN NULL
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN NULL
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr3
	|		ELSE NULL
	|	END AS ExpressionOfExtdimensionCr3,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN FALSE
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN FALSE
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr1, 1, &LengthOfCrExpressionPrefix) = &ExtdimensionExpressionPrefixCr
	|				ELSE FALSE
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN FALSE
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN FALSE
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr1, 1, &LengthOfExpressionPrefixDr) = &ExtdimensionExpressionPrefixDr
	|		ELSE FALSE
	|	END AS CorExpressionCr1,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN FALSE
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN FALSE
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr2, 1, &LengthOfCrExpressionPrefix) = &ExtdimensionExpressionPrefixCr
	|				ELSE FALSE
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN FALSE
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN FALSE
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr2, 1, &LengthOfExpressionPrefixDr) = &ExtdimensionExpressionPrefixDr
	|		ELSE FALSE
	|	END AS CorExpressionCr2,
	|	CASE
	|		WHEN RevSettingKeys.InvertEntriy
	|			THEN CASE
	|				WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|					THEN FALSE
	|				WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|					THEN FALSE
	|				WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|					THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingDr3, 1, &LengthOfCrExpressionPrefix) = &ExtdimensionExpressionPrefixCr
	|				ELSE FALSE
	|			END
	|		WHEN SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|			THEN FALSE
	|		WHEN NOT SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|			THEN FALSE
	|		WHEN SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN SUBSTRING(SpeedReflectionSettings.ExpressionOfExtdimensionFillingCr3, 1, &LengthOfExpressionPrefixDr) = &ExtdimensionExpressionPrefixDr
	|		ELSE FALSE
	|	END AS CorExpressionCr3
	|INTO TTExtdimensionOfRevolutions
	|FROM
	|	TTRevSettingKeys AS RevSettingKeys
	|	INNER JOIN InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SpeedReflectionSettings
	|		ON RevSettingKeys.ChartOfAccounts = SpeedReflectionSettings.ChartOfAccounts
	|		 AND RevSettingKeys.PostingGenerationSetting = SpeedReflectionSettings.PostingGenerationSetting
	|		 AND RevSettingKeys.AccountingObjectDr = SpeedReflectionSettings.AccountingObjectDr
	|		 AND RevSettingKeys.AccountingObjectCr = SpeedReflectionSettings.AccountingObjectCr
	|		 AND RevSettingKeys.LongTermDr = SpeedReflectionSettings.LongTermDr
	|		 AND RevSettingKeys.LongTermCr = SpeedReflectionSettings.LongTermCr
	|		 AND RevSettingKeys.ApplicationProcedure = SpeedReflectionSettings.ApplicationProcedure
	|WHERE
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|	AND SpeedReflectionSettings.CustomSettingOfExtdimensionFillingDr
	|	AND (SpeedReflectionSettings.MethodOfFillingExtdimensionDr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionDr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionDr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|	) OR
	|	NOT SpeedReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|	AND SpeedReflectionSettings.CustomSettingOfExtdimensionFillingCr
	|	AND (SpeedReflectionSettings.MethodOfFillingExtdimensionCr1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionCr2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|		OR SpeedReflectionSettings.MethodOfFillingExtdimensionCr3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|	)
	|INDEX BY
	|	RegisterNameDr,
	|	RegisterNameCr,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	ApplicationProcedure,
	|	InvertEntriy
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RevSettingKeys.ChartOfAccounts AS ChartOfAccounts,
	|	RevSettingKeys.PostingGenerationSetting AS PostingGenerationSetting,
	|	RevSettingKeys.RegisterNameDr AS RegisterNameDr,
	|	RevSettingKeys.RegisterNameCr AS RegisterNameCr,
	|	RevSettingKeys.AccountingObjectDr AS AccountingObjectDr,
	|	RevSettingKeys.AccountingObjectCr AS AccountingObjectCr,
	|	RevSettingKeys.LongTermDr AS LongTermDr,
	|	RevSettingKeys.LongTermCr AS LongTermCr,
	|	RevSettingKeys.ApplicationProcedure AS ApplicationProcedure,
	|	RevSettingKeys.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	RevSettingKeys.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	SpeedReflectionSettings.AdditionalSelectionDr AS AdditionalSelectionDr,
	|	SpeedReflectionSettings.AdditionalSelectionCr AS AdditionalSelectionCr
	|FROM
	|	TTRevSettingKeys AS RevSettingKeys
	|	INNER JOIN InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SpeedReflectionSettings
	|		ON RevSettingKeys.ChartOfAccounts = SpeedReflectionSettings.ChartOfAccounts
	|		 AND RevSettingKeys.PostingGenerationSetting = SpeedReflectionSettings.PostingGenerationSetting
	|		 AND RevSettingKeys.AccountingObjectDr = SpeedReflectionSettings.AccountingObjectDr
	|		 AND RevSettingKeys.AccountingObjectCr = SpeedReflectionSettings.AccountingObjectCr
	|		 AND RevSettingKeys.LongTermDr = SpeedReflectionSettings.LongTermDr
	|		 AND RevSettingKeys.LongTermCr = SpeedReflectionSettings.LongTermCr
	|		 AND RevSettingKeys.ApplicationProcedure = SpeedReflectionSettings.ApplicationProcedure
	|WHERE
	|	RevSettingKeys.ThereIsAdditionalSelectionDr
	|	OR RevSettingKeys.ThereIsAdditionalSelectionCr
	|TOTALS BY
	|	RegisterNameDr,
	|	RegisterNameCr
	|");

	QueriesTexts.Add("
	|SELECT
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN RevSettingKeys.RegisterNameDr
	|		ELSE RevSettingKeys.RegisterNameCr
	|	END AS RegisterName
	|FROM
	|	TTRevSettingKeys AS RevSettingKeys
	|	,
	|	(SELECT
	|		&Dr AS DrCr
	|	UNION ALL
	|	SELECT
	|		&Cr AS DrCr
	|	) AS PartsOfDoubleEntry
	|WHERE
	|	RevSettingKeys.ThereIsAdditionalSelectionDr
	|	OR RevSettingKeys.ThereIsAdditionalSelectionCr
	|GROUP BY
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN RevSettingKeys.RegisterNameDr
	|		ELSE RevSettingKeys.RegisterNameCr
	|	END
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	ResultSelectionOfRevolutions = Results[Results.UBound() - 1];
	ResultRegisterNames = Results[Results.UBound()];

	FetchingRegisterNameDr = ResultSelectionOfRevolutions.Select(QueryResultIteration.ByGroups);
	FetchingRegisterName = ResultRegisterNames.Select();
	
	SelectionFieldsToDelete = DeletedFieldsForSelectingMotionAnalyticsQueries();
	IndexingFields = IndexFieldsOfIndividualCorrespondenceTables();
	ReverseIndexFields = IndexFieldsOfTablesReplacingReverseWithReverse();
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();

	AvailableRegisterFields_ = New Structure();
	
	While FetchingRegisterName.Next() Do
		RowsOfAnalyticsFields = New Array();
		RowsOfAnalyticsGroups = New Array();
		AvailableRegisterFields = New Array();
		
		RegisterTableName = FetchingRegisterName.RegisterName;
		
		AddAvailableRegisterFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups,
			AvailableRegisterFields, RegisterTableName);
		
		If RegisterTableName <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			RegisterRequestText = RegisterRequestsTexts[RegisterTableName];
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			
			StornoReplacementWithReverseIsRequired = Query.Parameters.RegistersAreReplacedStornoByReverse.Find(RegisterTableName) <> Undefined;
			ReverseEntryNeedsToBeReplacedStorno = Query.Parameters.ReverseToReverseReplacementRegisters.Find(RegisterTableName) <> Undefined;
			
			StornoReplacementTable = "tt" + RegisterTableName + "ReplacementStorno";
			ReverseReplacementTable = "tt" + RegisterTableName + "ReverseReplacement";
			PlacementTable = "tt" + RegisterTableName;
			
			If StornoReplacementWithReverseIsRequired Then
				FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete,, StornoReplacementTable);
				QueriesTexts.Add(RegisterRequestText);
				RegisterRequestText = TextOfAnalysisSelectionFromNestedTable();
				RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", StornoReplacementTable);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			EndIf;
			
			If ReverseEntryNeedsToBeReplacedStorno Then
				FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, ReverseIndexFields, ReverseReplacementTable);
				QueriesTexts.Add(RegisterRequestText);
				RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable(True);
				RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", ReverseReplacementTable);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			EndIf;
			
			FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, IndexingFields, PlacementTable);
			
			If Query.Parameters.RestoreCalculationsForStorno And RegistersOfRecoveryOfCalculationsOnStorno.Find(RegisterTableName) <> Undefined Then
				AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterTableName);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			EndIf;
			
			QueriesTexts.Add(RegisterRequestText);
			
			If StornoReplacementWithReverseIsRequired Then
				FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, StornoReplacementTable);
			EndIf;
			
			If ReverseEntryNeedsToBeReplacedStorno Then
				FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, ReverseReplacementTable);
			EndIf;
		EndIf;
		
		AvailableRegisterFields_.Insert(RegisterTableName, AvailableRegisterFields);
	EndDo;
	
	If QueriesTexts.Count() > 0 Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Results = Query.ExecuteBatch();
		QueriesTexts.Clear();
	
		DataCompositionSelectionFields = DataCompositionSelectionFields(Query.Parameters);
		DataLayoutResultsTable = DataLayoutResultsTable(DataCompositionSelectionFields);
		AddressOfDataLayoutStore = PutToTempStorage(Undefined, New UUID());
		MeasurementOfSpeedSettings = MeasurementsOfCorrespondenceReflectionSettings();
	Else
		DataLayoutResultsTable = Undefined;
	EndIf;
	
	While FetchingRegisterNameDr.Next() Do
		FetchingRegisterNameCr = FetchingRegisterNameDr.Select(QueryResultIteration.ByGroups);
		While FetchingRegisterNameCr.Next() Do
			QueryText = "
			|SELECT
			|	RevolutionsForTuning.ApplicationProcedure AS ApplicationProcedure,
			|	RevolutionsForTuning.LongTermDr AS LongTermDr,
			|	RevolutionsForTuning.LongTermCr AS LongTermCr,
			|	RevolutionsForTuning.RecNo AS RecNo,
			|	RevolutionsForTuning.ChartOfAccounts AS ChartOfAccounts,
			|	RevolutionsForTuning.PostingGenerationSetting AS PostingGenerationSetting,
			|	RevolutionsForTuning.AccountingObjectDr AS AccountingObjectDr,
			|	RevolutionsForTuning.AccountingObjectCr AS AccountingObjectCr,
			|	RevolutionsForTuning.CurrencyDr AS CurrencyDr,
			|	RevolutionsForTuning.CurrencyCr AS CurrencyCr,
			|	&AvailableTableFieldsDr,
			|	&AvailableTableFieldsCr
			|FROM
			|	TTRpmForSetting AS RevolutionsForTuning
			|	INNER JOIN &TableDr AS TableDr
			|		ON RevolutionsForTuning.Period = TableDr.Period
			|		 AND RevolutionsForTuning.Recorder = TableDr.Recorder
			|		 AND RevolutionsForTuning.FinRecordID = TableDr.FinRecordID
			|		 AND RevolutionsForTuning.RowIDDr = TableDr.RowID
			|		 AND RevolutionsForTuning.RegisterNameDr = &RegisterNameDr
			|		 AND RevolutionsForTuning.AccountingObjectDr = TableDr.AccountingObject
			|		 AND RevolutionsForTuning.SourceConfigurationObjectDr = TableDr.SettingObject1
			|		 AND RevolutionsForTuning.PlaceOfRegistrationDr = TableDr.PlaceOfRegistration
			|		 AND RevolutionsForTuning.MaturityDateDr = TableDr.MaturityDate
			|		 AND RevolutionsForTuning.Organization = TableDr.Organization
			|		 AND CASE
			|			WHEN TableDr.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
			|				THEN RevolutionsForTuning.SettingUpBusinessTransaction = TableDr.SettingUpBusinessTransaction
			|			ELSE TRUE
			|		 END
			|		 AND CASE
			|			WHEN RevolutionsForTuning.InvertEntriy
			|				THEN NOT TableDr.ThisIsDebit
			|			ELSE NOT TableDr.ThisIsLoan
			|		 END
			|		 AND RevolutionsForTuning.ThisIsReverseTransactionDr = TableDr.ThisIsReverseTransaction
			|	INNER JOIN &TableCr AS TableCr
			|		ON RevolutionsForTuning.Period = TableCr.Period
			|		 AND RevolutionsForTuning.Recorder = TableCr.Recorder
			|		 AND RevolutionsForTuning.FinRecordID = TableCr.FinRecordID
			|		 AND RevolutionsForTuning.RowIDCr = TableCr.RowID
			|		 AND RevolutionsForTuning.RegisterNameCr = &RegisterNameCr
			|		 AND RevolutionsForTuning.AccountingObjectCr = TableCr.AccountingObject
			|		 AND RevolutionsForTuning.SourceConfigurationObjectCr = TableCr.SettingObject1
			|		 AND RevolutionsForTuning.PlaceOfRegistrationCr = TableCr.PlaceOfRegistration
			|		 AND RevolutionsForTuning.MaturityDateCr = TableCr.MaturityDate
			|		 AND RevolutionsForTuning.Organization = TableCr.Organization
			|		 AND CASE
			|			WHEN TableCr.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
			|				THEN RevolutionsForTuning.SettingUpBusinessTransaction = TableCr.SettingUpBusinessTransaction
			|			ELSE TRUE
			|		 END
			|		 AND CASE
			|			WHEN RevolutionsForTuning.InvertEntriy
			|				THEN NOT TableCr.ThisIsLoan
			|			ELSE NOT TableCr.ThisIsDebit
			|		 END
			|		 AND RevolutionsForTuning.ThisIsReverseTransactionCr = TableCr.ThisIsReverseTransaction
			|WHERE
			|	RevolutionsForTuning.ThereIsAdditionalSelectionDr
			|	OR RevolutionsForTuning.ThereIsAdditionalSelectionCr
			|";
			
			QueryText = StrReplace(QueryText, "&TableDr", StrTemplate("tt%1", FetchingRegisterNameDr.RegisterNameDr));
			QueryText = StrReplace(QueryText, "&TableCr", StrTemplate("tt%1", FetchingRegisterNameCr.RegisterNameCr));
			QueryText = StrReplace(QueryText, "&RegisterNameDr", StrTemplate("""%1""", FetchingRegisterNameDr.RegisterNameDr));
			QueryText = StrReplace(QueryText, "&RegisterNameCr", StrTemplate("""%1""", FetchingRegisterNameCr.RegisterNameCr));
			
			AddAvailableFieldsToQueryText(AvailableRegisterFields_[FetchingRegisterNameDr.RegisterNameDr], QueryText, "Dr");
			AddAvailableFieldsToQueryText(AvailableRegisterFields_[FetchingRegisterNameCr.RegisterNameCr], QueryText, "Cr");
			
			DataCompositionSchema = DataCompositionServer.DataCompositionSchemaForQueryText(QueryText);
			AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, AddressOfDataLayoutStore);
			SettingsComposer = FinancialAccountingByBalanceSheetRegisterData.NewDataLayoutSettingsComposer(
				AddressOfDataCompositionSchema, DataCompositionSelectionFields, Query.Parameters);
			
			SelectionSelections = FetchingRegisterNameCr.Select();
			If SelectionSelections.Count() > 1 Then
				OrGroup = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				FilterItems1 = OrGroup.Items;
			Else
				FilterItems1 = SettingsComposer.Settings.Filter.Items;
			EndIf;
			
			While SelectionSelections.Next() Do
				SelectionOfTurnover = FilterItems1.Add(Type("DataCompositionFilterItemGroup"));
				SelectionOfTurnover.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
				AddDimensionSettingsToDataLayoutSelection(MeasurementOfSpeedSettings, SelectionSelections, SelectionOfTurnover);
				
				If SelectionSelections.ThereIsAdditionalSelectionDr Then
					AdditionalSelectionDr = SelectionSelections.AdditionalSelectionDr; // ValueStorage -
					SettingsComposerDr = New DataCompositionSettingsComposer();
					SettingsComposerDr.LoadSettings(AdditionalSelectionDr.Get());
					FinancialAccountingByBalanceSheetRegisterData.CopyDataCompositionFilter(SelectionOfTurnover, SettingsComposerDr.Settings.Filter,, "Dr");
				EndIf;
				
				If SelectionSelections.ThereIsAdditionalSelectionCr Then
					AdditionalSelectionCr = SelectionSelections.AdditionalSelectionCr; // ValueStorage -
					SettingsComposerCr = New DataCompositionSettingsComposer();
					SettingsComposerCr.LoadSettings(AdditionalSelectionCr.Get());
					FinancialAccountingByBalanceSheetRegisterData.CopyDataCompositionFilter(SelectionOfTurnover, SettingsComposerCr.Settings.Filter,, "Cr");
				EndIf;
			EndDo;
			
			FinancialAccountingByBalanceSheetRegisterData.AddLayoutResultToTable(DataCompositionSchema, SettingsComposer,
				Query.TempTablesManager, DataLayoutResultsTable);
		EndDo;
	EndDo;
	
	ThereAreRevolutionsWithAdditionalSelection = DataLayoutResultsTable <> Undefined
		And DataLayoutResultsTable.Count() > 0;
	
	If ThereAreRevolutionsWithAdditionalSelection Then
		QueriesTexts.Add("
		|SELECT
		|	LayoutResultsTable.RecNo AS RecNo,
		|	LayoutResultsTable.ApplicationProcedure AS ApplicationProcedure
		|INTO TTRevolutionsWithSelection
		|FROM
		|	&DataLayoutResultsTable AS LayoutResultsTable
		|INDEX BY
		|	RecNo,
		|	ApplicationProcedure
		|");
		
		Query.SetParameter("DataLayoutResultsTable", DataLayoutResultsTable);
	EndIf;
	
	QueryText = "
	|SELECT
	|	RevolutionsForTuning.ApplicationProcedure AS ApplicationProcedure,
	|	RevolutionsForTuning.ItIsNotReflectedInTheAccounts AS ItIsNotReflectedInTheAccounts,
	|	RevolutionsForTuning.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	RevolutionsForTuning.InvertTheResourceSign AS InvertTheResourceSign,
	|	RevolutionsForTuning.ApplySubsequentSettings AS ApplySubsequentSettings,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.UseCorrespondenceSettingsCr
	|		ELSE RevolutionsForTuning.UseCorrespondenceSettingsDr
	|	END AS UseCorrespondenceSettingsDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.UseCorrespondenceSettingsDr
	|		ELSE RevolutionsForTuning.UseCorrespondenceSettingsCr
	|	END AS UseCorrespondenceSettingsCr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.GLAccountCr
	|		ELSE RevolutionsForTuning.GLAccountDr
	|	END AS GLAccountDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.GLAccountDr
	|		ELSE RevolutionsForTuning.GLAccountCr
	|	END AS GLAccountCr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.LongTermCr
	|		ELSE RevolutionsForTuning.LongTermDr
	|	END AS LongTermDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.LongTermDr
	|		ELSE RevolutionsForTuning.LongTermCr
	|	END AS LongTermCr,
	|	RevolutionsForTuning.RecNo AS RecNo,
	|	RevolutionsForTuning.ChartOfAccounts AS ChartOfAccounts,
	|	RevolutionsForTuning.PostingGenerationSetting AS PostingGenerationSetting,
	|	RevolutionsForTuning.Period AS Period,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.RegisterNameCr
	|		ELSE RevolutionsForTuning.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.RegisterNameDr
	|		ELSE RevolutionsForTuning.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.AccountingObjectCr
	|		ELSE RevolutionsForTuning.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.AccountingObjectDr
	|		ELSE RevolutionsForTuning.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.SettingObject1Cr
	|		ELSE RevolutionsForTuning.SettingObject1Dr
	|	END AS SettingObject1Dr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.SettingObject1Dr
	|		ELSE RevolutionsForTuning.SettingObject1Cr
	|	END AS SettingObject1Cr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.PlaceOfRegistrationCr
	|		ELSE RevolutionsForTuning.PlaceOfRegistrationDr
	|	END AS PlaceOfRegistrationDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.PlaceOfRegistrationDr
	|		ELSE RevolutionsForTuning.PlaceOfRegistrationCr
	|	END AS PlaceOfRegistrationCr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.ThisIsReverseTransactionCr
	|		ELSE RevolutionsForTuning.ThisIsReverseTransactionDr
	|	END AS ThisIsReverseTransactionDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.ThisIsReverseTransactionDr
	|		ELSE RevolutionsForTuning.ThisIsReverseTransactionCr
	|	END AS ThisIsReverseTransactionCr,
	|	RevolutionsForTuning.InvertEntriy AS InvertEntriy,
	|	RevolutionsForTuning.Organization AS Organization,
	|	RevolutionsForTuning.Recorder AS Recorder,
	|	RevolutionsForTuning.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RevolutionsForTuning.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.RowIDCr
	|		ELSE RevolutionsForTuning.RowIDDr
	|	END AS RowIDDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.RowIDDr
	|		ELSE RevolutionsForTuning.RowIDCr
	|	END AS RowIDCr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.SourceConfigurationObjectCr
	|		ELSE RevolutionsForTuning.SourceConfigurationObjectDr
	|	END AS SourceConfigurationObjectDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.SourceConfigurationObjectDr
	|		ELSE RevolutionsForTuning.SourceConfigurationObjectCr
	|	END AS SourceConfigurationObjectCr,
	|	RevolutionsForTuning.PropsStorno AS PropsStorno,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.CurrencyCr
	|		ELSE RevolutionsForTuning.CurrencyDr
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.CurrencyDr
	|		ELSE RevolutionsForTuning.CurrencyCr
	|	END AS CurrencyCr,
	|	RevolutionsForTuning.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RevolutionsForTuning.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RevolutionsForTuning.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RevolutionsForTuning.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RevolutionsForTuning.ComplexEntryDr AS ComplexEntryDr,
	|	RevolutionsForTuning.ComplexEntryCr AS ComplexEntryCr,
	|	RevolutionsForTuning.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.MaturityDateCr
	|		ELSE RevolutionsForTuning.MaturityDateDr
	|	END AS MaturityDateDr,
	|	CASE
	|		WHEN RevolutionsForTuning.InvertEntriy
	|			THEN RevolutionsForTuning.MaturityDateDr
	|		ELSE RevolutionsForTuning.MaturityDateCr
	|	END AS MaturityDateCr,
	|	RevolutionsForTuning.SumManDr AS SumManDr,
	|	RevolutionsForTuning.SumManCr AS SumManCr,
	|	RevolutionsForTuning.SumComplDr AS SumComplDr,
	|	RevolutionsForTuning.SumComplCr AS SumComplCr,
	|	RevolutionsForTuning.SumCurrDr AS SumCurrDr,
	|	RevolutionsForTuning.SumCurrCr AS SumCurrCr,
	|	RevolutionsForTuning.CountDr AS CountDr,
	|	RevolutionsForTuning.CountCr AS CountCr
	|INTO TTTurnoversWithAccounts
	|FROM
	|	TTRpmForSetting AS RevolutionsForTuning
	|WHERE
	|	NOT RevolutionsForTuning.ThereIsAdditionalSelectionDr
	|	AND NOT RevolutionsForTuning.ThereIsAdditionalSelectionCr
	|	OR &ConditionForSelectingRevolutionsWithAdditionalSelection
	|";
	
	If ThereAreRevolutionsWithAdditionalSelection Then
		ConditionForSelectingRevolutionsWithAdditionalSelection = "TRUE IN
		|	(SELECT TOP 1
		|		TRUE
		|	FROM
		|		TTRevolutionsWithSelection AS SpeedWithSelection
		|	WHERE
		|		SpeedWithSelection.RecNo = RevolutionsForTuning.RecNo
		|		AND SpeedWithSelection.ApplicationProcedure = RevolutionsForTuning.ApplicationProcedure
		|	)
		|";
	Else
		ConditionForSelectingRevolutionsWithAdditionalSelection = "FALSE";
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&ConditionForSelectingRevolutionsWithAdditionalSelection",
		ConditionForSelectingRevolutionsWithAdditionalSelection);
	
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRpmForSetting");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRevSettingKeys");
	
	If ThereAreRevolutionsWithAdditionalSelection Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRevolutionsWithSelection");
	EndIf;
	
EndProcedure

Procedure DeleteUnansweredCorrespondence(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	&HowToApplySettingsForObjects AS ApplicationProcedure,
	|	FALSE AS ItIsNotReflectedInTheAccounts,
	|	FALSE AS ManualSpecificationOfEntry,
	|	FALSE AS InvertTheResourceSign,
	|	FALSE AS ApplySubsequentSettings,
	|	FALSE AS UseCorrespondenceSettingsDr,
	|	FALSE AS UseCorrespondenceSettingsCr,
	|	RegisteredRecordsWithAccounts.GLAccountDr AS GLAccountDr,
	|	RegisteredRecordsWithAccounts.GLAccountCr AS GLAccountCr,
	|	RegisteredRecordsWithAccounts.LongTermDr AS LongTermDr,
	|	RegisteredRecordsWithAccounts.LongTermCr AS LongTermCr,
	|	RegisteredRecordsWithAccounts.RecNo AS RecNo,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.InvertEntriy AS InvertEntriy,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsWithAccounts.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumManDr,
	|	RegisteredRecordsWithAccounts.SumManCr AS SumManCr,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithAccounts.SumComplCr AS SumComplCr,
	|	RegisteredRecordsWithAccounts.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsWithAccounts.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsWithAccounts.CountDr AS CountDr,
	|	RegisteredRecordsWithAccounts.CountCr AS CountCr
	|INTO TTAllRegisteredRecordsAndRevolutions
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|
	|UNION ALL
	|
	|SELECT
	|	TurnoverWithAccounts.ApplicationProcedure AS ApplicationProcedure,
	|	TurnoverWithAccounts.ItIsNotReflectedInTheAccounts AS ItIsNotReflectedInTheAccounts,
	|	TurnoverWithAccounts.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	TurnoverWithAccounts.InvertTheResourceSign AS InvertTheResourceSign,
	|	TurnoverWithAccounts.ApplySubsequentSettings AS ApplySubsequentSettings,
	|	TurnoverWithAccounts.UseCorrespondenceSettingsDr AS UseCorrespondenceSettingsDr,
	|	TurnoverWithAccounts.UseCorrespondenceSettingsCr AS UseCorrespondenceSettingsCr,
	|	TurnoverWithAccounts.GLAccountDr AS GLAccountDr,
	|	TurnoverWithAccounts.GLAccountCr AS GLAccountCr,
	|	TurnoverWithAccounts.LongTermDr AS LongTermDr,
	|	TurnoverWithAccounts.LongTermCr AS LongTermCr,
	|	TurnoverWithAccounts.RecNo AS RecNo,
	|	TurnoverWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	TurnoverWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	TurnoverWithAccounts.Period AS Period,
	|	TurnoverWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	TurnoverWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	TurnoverWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	TurnoverWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	TurnoverWithAccounts.SettingObject1Dr AS SettingObject1Dr,
	|	TurnoverWithAccounts.SettingObject1Cr AS SettingObject1Cr,
	|	TurnoverWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	TurnoverWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	TurnoverWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	TurnoverWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	TurnoverWithAccounts.InvertEntriy AS InvertEntriy,
	|	TurnoverWithAccounts.Organization AS Organization,
	|	TurnoverWithAccounts.Recorder AS Recorder,
	|	TurnoverWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	TurnoverWithAccounts.FinRecordID AS FinRecordID,
	|	TurnoverWithAccounts.RowIDDr AS RowIDDr,
	|	TurnoverWithAccounts.RowIDCr AS RowIDCr,
	|	TurnoverWithAccounts.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	TurnoverWithAccounts.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	TurnoverWithAccounts.PropsStorno AS PropsStorno,
	|	TurnoverWithAccounts.CurrencyDr AS CurrencyDr,
	|	TurnoverWithAccounts.CurrencyCr AS CurrencyCr,
	|	TurnoverWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	TurnoverWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	TurnoverWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	TurnoverWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	TurnoverWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	TurnoverWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	TurnoverWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	TurnoverWithAccounts.MaturityDateDr AS MaturityDateDr,
	|	TurnoverWithAccounts.MaturityDateCr AS MaturityDateCr,
	|	TurnoverWithAccounts.SumManDr AS SumManDr,
	|	TurnoverWithAccounts.SumManCr AS SumManCr,
	|	TurnoverWithAccounts.SumComplDr AS SumComplDr,
	|	TurnoverWithAccounts.SumComplCr AS SumComplCr,
	|	TurnoverWithAccounts.SumCurrDr AS SumCurrDr,
	|	TurnoverWithAccounts.SumCurrCr AS SumCurrCr,
	|	TurnoverWithAccounts.CountDr AS CountDr,
	|	TurnoverWithAccounts.CountCr AS CountCr
	|FROM
	|	TTTurnoversWithAccounts AS TurnoverWithAccounts
	|INDEX BY
	|	RecNo,
	|	ApplicationProcedure,
	|	ApplySubsequentSettings,
	|	ItIsNotReflectedInTheAccounts
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementWithAccounts");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTTurnoversWithAccounts");
	
	QueriesTexts.Add("
	|SELECT
	|	AllRegisteredRecordsAndRevolutions.ApplicationProcedure AS ApplicationProcedure,
	|	AllRegisteredRecordsAndRevolutions.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	AllRegisteredRecordsAndRevolutions.InvertTheResourceSign AS InvertTheResourceSign,
	|	AllRegisteredRecordsAndRevolutions.UseCorrespondenceSettingsDr AS UseCorrespondenceSettingsDr,
	|	AllRegisteredRecordsAndRevolutions.UseCorrespondenceSettingsCr AS UseCorrespondenceSettingsCr,
	|	AllRegisteredRecordsAndRevolutions.GLAccountDr AS GLAccountDr,
	|	AllRegisteredRecordsAndRevolutions.GLAccountCr AS GLAccountCr,
	|	AllRegisteredRecordsAndRevolutions.LongTermDr AS LongTermDr,
	|	AllRegisteredRecordsAndRevolutions.LongTermCr AS LongTermCr,
	|	AllRegisteredRecordsAndRevolutions.ChartOfAccounts AS ChartOfAccounts,
	|	AllRegisteredRecordsAndRevolutions.PostingGenerationSetting AS PostingGenerationSetting,
	|	AllRegisteredRecordsAndRevolutions.Period AS Period,
	|	AllRegisteredRecordsAndRevolutions.RegisterNameDr AS RegisterNameDr,
	|	AllRegisteredRecordsAndRevolutions.RegisterNameCr AS RegisterNameCr,
	|	AllRegisteredRecordsAndRevolutions.AccountingObjectDr AS AccountingObjectDr,
	|	AllRegisteredRecordsAndRevolutions.AccountingObjectCr AS AccountingObjectCr,
	|	AllRegisteredRecordsAndRevolutions.SettingObject1Dr AS SettingObject1Dr,
	|	AllRegisteredRecordsAndRevolutions.SettingObject1Cr AS SettingObject1Cr,
	|	VALUETYPE(AllRegisteredRecordsAndRevolutions.SettingObject1Dr) = TYPE(Catalog.OtherTransactionsGLAccountsSettings) AS UseSettingsForOtherDrOperations,
	|	VALUETYPE(AllRegisteredRecordsAndRevolutions.SettingObject1Cr) = TYPE(Catalog.OtherTransactionsGLAccountsSettings) AS UseSettingsForOtherCrOperations,
	|	AllRegisteredRecordsAndRevolutions.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	AllRegisteredRecordsAndRevolutions.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	AllRegisteredRecordsAndRevolutions.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	AllRegisteredRecordsAndRevolutions.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	AllRegisteredRecordsAndRevolutions.InvertEntriy AS InvertEntriy,
	|	AllRegisteredRecordsAndRevolutions.Organization AS Organization,
	|	AllRegisteredRecordsAndRevolutions.Recorder AS Recorder,
	|	AllRegisteredRecordsAndRevolutions.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	AllRegisteredRecordsAndRevolutions.FinRecordID AS FinRecordID,
	|	AllRegisteredRecordsAndRevolutions.RowIDDr AS RowIDDr,
	|	AllRegisteredRecordsAndRevolutions.RowIDCr AS RowIDCr,
	|	AllRegisteredRecordsAndRevolutions.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	AllRegisteredRecordsAndRevolutions.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	AllRegisteredRecordsAndRevolutions.PropsStorno AS PropsStorno,
	|	AllRegisteredRecordsAndRevolutions.CurrencyDr AS CurrencyDr,
	|	AllRegisteredRecordsAndRevolutions.CurrencyCr AS CurrencyCr,
	|	AllRegisteredRecordsAndRevolutions.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	AllRegisteredRecordsAndRevolutions.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	AllRegisteredRecordsAndRevolutions.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	AllRegisteredRecordsAndRevolutions.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	AllRegisteredRecordsAndRevolutions.ComplexEntryDr AS ComplexEntryDr,
	|	AllRegisteredRecordsAndRevolutions.ComplexEntryCr AS ComplexEntryCr,
	|	AllRegisteredRecordsAndRevolutions.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	AllRegisteredRecordsAndRevolutions.MaturityDateDr AS MaturityDateDr,
	|	AllRegisteredRecordsAndRevolutions.MaturityDateCr AS MaturityDateCr,
	|	AllRegisteredRecordsAndRevolutions.SumManDr AS SumManDr,
	|	AllRegisteredRecordsAndRevolutions.SumManCr AS SumManCr,
	|	AllRegisteredRecordsAndRevolutions.SumComplDr AS SumComplDr,
	|	AllRegisteredRecordsAndRevolutions.SumComplCr AS SumComplCr,
	|	AllRegisteredRecordsAndRevolutions.SumCurrDr AS SumCurrDr,
	|	AllRegisteredRecordsAndRevolutions.SumCurrCr AS SumCurrCr,
	|	AllRegisteredRecordsAndRevolutions.CountDr AS CountDr,
	|	AllRegisteredRecordsAndRevolutions.CountCr AS CountCr
	|INTO TTMovementWithAccounts
	|FROM
	|	TTAllRegisteredRecordsAndRevolutions AS AllRegisteredRecordsAndRevolutions
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTAllRegisteredRecordsAndRevolutions AS PreviousSettings
	|		WHERE
	|			PreviousSettings.RecNo = AllRegisteredRecordsAndRevolutions.RecNo
	|			AND PreviousSettings.ApplicationProcedure < AllRegisteredRecordsAndRevolutions.ApplicationProcedure
	|			AND NOT PreviousSettings.ApplySubsequentSettings
	|		)
	|	AND NOT AllRegisteredRecordsAndRevolutions.ItIsNotReflectedInTheAccounts
	|INDEX BY
	|	RegisterNameDr,
	|	RegisterNameCr,
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	GLAccountDr,
	|	GLAccountCr,
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	SettingObject1Dr,
	|	SettingObject1Cr,
	|	FinRecordID
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAllRegisteredRecordsAndRevolutions");
	
EndProcedure

Procedure GenerateCorrespondenceAnalyticsRequests(Query, QueriesTexts, RegisterRequestsTexts)
		
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr AS UseCorrespondenceSettings,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.GLAccountDr AS GLAccount,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterName,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObject
	|INTO TTAccountsOfAccountingObjects
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|GROUP BY
	|	RegisteredRecordsWithAccounts.RegisterNameDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.GLAccountDr,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|
	|UNION
	|
	|SELECT
	|	RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr AS UseCorrespondenceSettings,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.GLAccountCr AS GLAccount,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterName,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObject
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|GROUP BY
	|	RegisteredRecordsWithAccounts.RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.GLAccountCr,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|INDEX BY
	|	ChartOfAccounts,
	|	PostingGenerationSetting,
	|	AccountingObject,
	|	GLAccount,
	|	UseCorrespondenceSettings
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	AccountsOfAccountingObjects.GLAccount AS GLAccount
	|INTO TTInternationalAccountingAccounts
	|FROM
	|	TTAccountsOfAccountingObjects AS AccountsOfAccountingObjects
	|GROUP BY
	|	AccountsOfAccountingObjects.GLAccount
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	InternationalAccountingAccounts.GLAccount AS GLAccount,
	|	ISNULL(InternationalAccountingAccounts.GLAccount.Currency1, FALSE) AS Currency1,
	|	ISNULL(InternationalAccountingAccounts.GLAccount.Quantitative, FALSE) AS Quantitative,
	|	ISNULL(InternationalAccountingAccounts.GLAccount.AccountingByBusinessUnits, FALSE) AS AccountingByBusinessUnits,
	|	ISNULL(InternationalAccountingAccounts.GLAccount.AccountingByLinesOfBusiness, FALSE) AS AccountingByLinesOfBusiness,
	|	CASE
	|		WHEN NOT ExtDimensionTypes3.Ref IS NULL THEN 3
	|		WHEN NOT ExtDimensionTypes2.Ref IS NULL THEN 2
	|		WHEN NOT ExtDimensionTypes1.Ref IS NULL THEN 1
	|		ELSE 0
	|	END AS ExtDimensionCount,
	|	ISNULL(ExtDimensionTypes1.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType1,
	|	ExtDimensionTypes1.ExtDimensionType.ValueType AS ExtdimensionValueType1,
	|	ISNULL(ExtDimensionTypes1.ExtDimensionType.PredefinedDataName, """") AS ExtraDimensionTypeName1,
	|	ISNULL(ExtDimensionTypes2.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType2,
	|	ExtDimensionTypes2.ExtDimensionType.ValueType AS ExtdimensionValueType2,
	|	ISNULL(ExtDimensionTypes2.ExtDimensionType.PredefinedDataName, """") AS ExtraDimensionTypeName2,
	|	ISNULL(ExtDimensionTypes3.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType3,
	|	ExtDimensionTypes3.ExtDimensionType.ValueType AS ExtdimensionValueType3,
	|	ISNULL(ExtDimensionTypes3.ExtDimensionType.PredefinedDataName, """") AS ExtraDimensionTypeName3
	|INTO TTPropertiesOfAccountingAccounts
	|FROM
	|	TTInternationalAccountingAccounts AS InternationalAccountingAccounts
	|	LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes1
	|		ON InternationalAccountingAccounts.GLAccount = ExtDimensionTypes1.Ref
	|		 AND ExtDimensionTypes1.LineNumber = 1
	|	LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes2
	|		ON InternationalAccountingAccounts.GLAccount = ExtDimensionTypes2.Ref
	|		 AND ExtDimensionTypes2.LineNumber = 2
	|	LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes3
	|		ON InternationalAccountingAccounts.GLAccount = ExtDimensionTypes3.Ref
	|		 AND ExtDimensionTypes3.LineNumber = 3
	|INDEX BY
	|	GLAccount
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTInternationalAccountingAccounts");
	
	QueriesTexts.Add("
	|SELECT
	|	AccountsOfAccountingObjects.ChartOfAccounts AS ChartOfAccounts,
	|	AccountsOfAccountingObjects.PostingGenerationSetting AS PostingGenerationSetting,
	|	AccountsOfAccountingObjects.GLAccount AS GLAccount,
	|	AccountsOfAccountingObjects.AccountingObject AS AccountingObject,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension1
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValue1,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension2
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValue2,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension3
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END AS ExtraDimensionValue3
	|INTO TTSpecifiedValuesOfExtdimension
	|FROM
	|	TTAccountsOfAccountingObjects AS AccountsOfAccountingObjects
	|	INNER JOIN InformationRegister.SettingsForFillingExtraDimensionOnFinancialAccountingAccounts AS ExtraDimensionFillingSettings
	|		ON AccountsOfAccountingObjects.ChartOfAccounts = ExtraDimensionFillingSettings.ChartOfAccounts
	|		 AND AccountsOfAccountingObjects.PostingGenerationSetting = ExtraDimensionFillingSettings.PostingGenerationSetting
	|		 AND AccountsOfAccountingObjects.AccountingObject = ExtraDimensionFillingSettings.AccountingObject
	|		 AND AccountsOfAccountingObjects.GLAccount = ExtraDimensionFillingSettings.GLAccount
	|WHERE
	|	NOT AccountsOfAccountingObjects.UseCorrespondenceSettings
	|	AND (ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|		OR ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|		OR ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 IN (
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue),
	|			VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill))
	|	)
	|GROUP BY
	|	AccountsOfAccountingObjects.ChartOfAccounts,
	|	AccountsOfAccountingObjects.PostingGenerationSetting,
	|	AccountsOfAccountingObjects.AccountingObject,
	|	AccountsOfAccountingObjects.GLAccount,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension1
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension2
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue)
	|			THEN ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension3
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill)
	|			THEN UNDEFINED
	|		ELSE NULL
	|	END
	|INDEX BY
	|	AccountingObject,
	|	GLAccount,
	|	ChartOfAccounts,
	|	PostingGenerationSetting
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	AccountsOfAccountingObjects.ChartOfAccounts AS ChartOfAccounts,
	|	AccountsOfAccountingObjects.PostingGenerationSetting AS PostingGenerationSetting,
	|	AccountsOfAccountingObjects.GLAccount AS GLAccount,
	|	AccountsOfAccountingObjects.RegisterName AS RegisterName,
	|	AccountsOfAccountingObjects.AccountingObject AS AccountingObject,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling1
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension1,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling2
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension2,
	|	CASE
	|		WHEN ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|			THEN ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling3
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension3
	|INTO TTExpressionsOfExtdimensionFilling
	|FROM
	|	TTAccountsOfAccountingObjects AS AccountsOfAccountingObjects
	|	INNER JOIN InformationRegister.SettingsForFillingExtraDimensionOnFinancialAccountingAccounts AS ExtraDimensionFillingSettings
	|		ON AccountsOfAccountingObjects.ChartOfAccounts = ExtraDimensionFillingSettings.ChartOfAccounts
	|		 AND AccountsOfAccountingObjects.PostingGenerationSetting = ExtraDimensionFillingSettings.PostingGenerationSetting
	|		 AND AccountsOfAccountingObjects.AccountingObject = ExtraDimensionFillingSettings.AccountingObject
	|		 AND AccountsOfAccountingObjects.GLAccount = ExtraDimensionFillingSettings.GLAccount
	|WHERE
	|	NOT AccountsOfAccountingObjects.UseCorrespondenceSettings
	|	AND (ExtraDimensionFillingSettings.MethodOfFillingExtdimension1 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|		OR ExtraDimensionFillingSettings.MethodOfFillingExtdimension2 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|		OR ExtraDimensionFillingSettings.MethodOfFillingExtdimension3 = VALUE(Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister)
	|	)
	|INDEX BY
	|	RegisterName,
	|	AccountingObject,
	|	GLAccount,
	|	ChartOfAccounts,
	|	PostingGenerationSetting
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	AccountsOfAccountingObjects.RegisterName AS RegisterName,
	|	AccountsOfAccountingObjects.GLAccount AS GLAccount
	|FROM
	|	TTAccountsOfAccountingObjects AS AccountsOfAccountingObjects
	|GROUP BY
	|	AccountsOfAccountingObjects.RegisterName,
	|	AccountsOfAccountingObjects.GLAccount
	|TOTALS BY
	|	RegisterName
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	PropertiesOfAccountingAccounts.GLAccount AS GLAccount,
	|	PropertiesOfAccountingAccounts.ExtDimensionCount AS ExtDimensionCount,
	|	PropertiesOfAccountingAccounts.ExtDimensionType1 AS ExtDimensionType1,
	|	PropertiesOfAccountingAccounts.ExtdimensionValueType1 AS ExtdimensionValueType1,
	|	PropertiesOfAccountingAccounts.ExtraDimensionTypeName1 AS ExtraDimensionTypeName1,
	|	PropertiesOfAccountingAccounts.ExtDimensionType2 AS ExtDimensionType2,
	|	PropertiesOfAccountingAccounts.ExtdimensionValueType2 AS ExtdimensionValueType2,
	|	PropertiesOfAccountingAccounts.ExtraDimensionTypeName2 AS ExtraDimensionTypeName2,
	|	PropertiesOfAccountingAccounts.ExtDimensionType3 AS ExtDimensionType3,
	|	PropertiesOfAccountingAccounts.ExtdimensionValueType3 AS ExtdimensionValueType3,
	|	PropertiesOfAccountingAccounts.ExtraDimensionTypeName3 AS ExtraDimensionTypeName3
	|FROM
	|	TTPropertiesOfAccountingAccounts AS PropertiesOfAccountingAccounts
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ExtdimensionFillingExpressions.RegisterName AS RegisterName,
	|	ExtdimensionFillingExpressions.ExpressionOfExtdimension1 AS ExpressionOfExtdimension1,
	|	ExtdimensionFillingExpressions.ExpressionOfExtdimension2 AS ExpressionOfExtdimension2,
	|	ExtdimensionFillingExpressions.ExpressionOfExtdimension3 AS ExpressionOfExtdimension3
	|FROM
	|	TTExpressionsOfExtdimensionFilling AS ExtdimensionFillingExpressions
	|GROUP BY
	|	ExtdimensionFillingExpressions.RegisterName,
	|	ExtdimensionFillingExpressions.ExpressionOfExtdimension1,
	|	ExtdimensionFillingExpressions.ExpressionOfExtdimension2,
	|	ExtdimensionFillingExpressions.ExpressionOfExtdimension3
	|
	|UNION
	|
	|SELECT
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.RegisterNameDr
	|		ELSE ExpressionsOfExtdimensionOfRevolutions.RegisterNameCr
	|	END AS RegisterName,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr1
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr1
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension1,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr2
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr2
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension2,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr3
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr3
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension3
	|FROM
	|	TTExtdimensionOfRevolutions AS ExpressionsOfExtdimensionOfRevolutions
	|	,
	|	(SELECT
	|		&Dr AS DrCr
	|	UNION ALL
	|	SELECT
	|		&Cr AS DrCr
	|	) AS PartsOfDoubleEntry
	|WHERE
	|	(PartsOfDoubleEntry.DrCr = &Dr
	|		AND (NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1
	|			OR NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2
	|			OR NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3)
	|	) OR
	|	(PartsOfDoubleEntry.DrCr = &Cr
	|		AND (NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1
	|			OR NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2
	|			OR NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3)
	|	)
	|GROUP BY
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.RegisterNameDr
	|		ELSE ExpressionsOfExtdimensionOfRevolutions.RegisterNameCr
	|	END,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr1
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr2
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr3
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND NOT ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr3
	|		ELSE NULL
	|	END
	|
	|UNION
	|
	|SELECT
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.RegisterNameCr
	|		ELSE ExpressionsOfExtdimensionOfRevolutions.RegisterNameDr
	|	END AS RegisterName,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr1
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr1
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension1,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr2
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr2
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension2,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr3
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr3
	|		ELSE NULL
	|	END AS ExpressionOfExtdimension3
	|FROM
	|	TTExtdimensionOfRevolutions AS ExpressionsOfExtdimensionOfRevolutions
	|	,
	|	(SELECT
	|		&Dr AS DrCr
	|	UNION ALL
	|	SELECT
	|		&Cr AS DrCr
	|	) AS PartsOfDoubleEntry
	|WHERE
	|	(PartsOfDoubleEntry.DrCr = &Dr
	|		AND (ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1
	|			OR ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2
	|			OR ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3)
	|	) OR
	|	(PartsOfDoubleEntry.DrCr = &Cr
	|		AND (ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1
	|			OR ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2
	|			OR ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3)
	|	)
	|GROUP BY
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.RegisterNameCr
	|		ELSE ExpressionsOfExtdimensionOfRevolutions.RegisterNameDr
	|	END,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr1
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr2
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr3
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr AND ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr3
	|		ELSE NULL
	|	END
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	ResultOfRegisterAccountingAccount = Results[Results.UBound() - 2];
	ResultTypesOfExtdimension = Results[Results.UBound() - 1];
	ResultOfExtdimensionExpression = Results[Results.UBound()];
	
	FetchingRegisterName = ResultOfRegisterAccountingAccount.Select(QueryResultIteration.ByGroups);
	SamplingExtdimensionSpecies = ResultTypesOfExtdimension.Select();
	SamplingExpressionExtdimension = ResultOfExtdimensionExpression.Select();
	
	AllKindsOfExtdimension = AllKindsOfExtdimensionAccountingAccounts(SamplingExtdimensionSpecies);
	AllExpressionsAreExtdimension = AllExtdimensionFillingExpressions(SamplingExpressionExtdimension, Query.Parameters);
	
	TransactionSettings = SettingsForGeneratingTransactionsBasedOnRequestParameters(Query.Parameters);
	AccountingSettings = AccountingSettingsByTransactionGenerationSettings(TransactionSettings);
	FinancialAccountingObjects = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObjects(AccountingSettings);
	
	SelectionFieldsToDelete = DeletedFieldsForSelectingMotionAnalyticsQueries();
	ReverseIndexFields = IndexFieldsOfTablesReplacingReverseWithReverse();
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();
	
	DeletedTemporaryTables = New Array();
	IndexOfResultOfAnalyticsQuery = 0;
	
	While FetchingRegisterName.Next() Do
		TypesOfExtdimensionOfRegister = TypesOfExtdimensionOfRegister(FetchingRegisterName, SamplingExtdimensionSpecies);
		RegisterExtdimensionExpressions = RegisterExtdimensionExpressions(FetchingRegisterName, SamplingExpressionExtdimension, Query.Parameters);
		
		RowsOfAnalyticsFields = New Array();
		RowsOfAnalyticsGroups = New Array();
		
		RegisterTableName = FetchingRegisterName.RegisterName;
		If RegisterTableName = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			RegisterTableName = "";
		EndIf;
		
		AddExtdimensionSelectionFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups,
			AllKindsOfExtdimension, TypesOfExtdimensionOfRegister, RegisterTableName, FinancialAccountingObjects);
		
		AddExpressionSelectionFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups,
			AllExpressionsAreExtdimension, RegisterExtdimensionExpressions);
		
		TemporaryRegisterTableName = "tt" + FetchingRegisterName.RegisterName;
		
		If Query.TempTablesManager.Tables.Find(TemporaryRegisterTableName) = Undefined Then
			RegisterRequestText = RegisterRequestsTexts[RegisterTableName];
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			
			StornoReplacementWithReverseIsRequired = Query.Parameters.RegistersAreReplacedStornoByReverse.Find(RegisterTableName) <> Undefined;
			ReverseEntryNeedsToBeReplacedStorno = Query.Parameters.ReverseToReverseReplacementRegisters.Find(RegisterTableName) <> Undefined;
			
			If StornoReplacementWithReverseIsRequired Or ReverseEntryNeedsToBeReplacedStorno Then
				If StornoReplacementWithReverseIsRequired Then
					StornoReplacementTable = "tt" + RegisterTableName + "ReplacementStorno";
					FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete,, StornoReplacementTable);
					QueriesTexts.Add(RegisterRequestText);
					RegisterRequestText = TextOfAnalysisSelectionFromNestedTable();
					RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", StornoReplacementTable);
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
						RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
					DeletedTemporaryTables.Add(StornoReplacementTable);
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
				EndIf;
				
				If ReverseEntryNeedsToBeReplacedStorno Then
					ReverseReplacementTable = "tt" + RegisterTableName + "ReverseReplacement";
					FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, ReverseIndexFields, ReverseReplacementTable);
					QueriesTexts.Add(RegisterRequestText);
					RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable(True);
					RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", ReverseReplacementTable);
					FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
						RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
					DeletedTemporaryTables.Add(ReverseReplacementTable);
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
				EndIf;
			Else
				FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete);
			EndIf;
			
			If Query.Parameters.RestoreCalculationsForStorno And RegistersOfRecoveryOfCalculationsOnStorno.Find(RegisterTableName) <> Undefined Then
				AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterTableName);
				FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
					RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			EndIf;
		Else
			RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable();
			RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", TemporaryRegisterTableName);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
		EndIf;
		
		QueriesTexts.Add(RegisterRequestText);
		Query.Parameters.AnalyticsSampleRegisters.Insert(FetchingRegisterName.RegisterName, IndexOfResultOfAnalyticsQuery);
		IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
	EndDo;
	
	Query.Parameters.AllKindsOfExtdimension = AllKindsOfExtdimension;
	Query.Parameters.AllExpressionsAreExtdimension = AllExpressionsAreExtdimension;
	
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts.TransactionsWithCorrespondence AS TransactionsWithCorrespondence,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	RegisteredRecordsWithAccounts.GLAccountDr AS GLAccountDr,
	|	PropertiesOfAccountingAccountsDr.Currency1 AS Currency1Dr,
	|	PropertiesOfAccountingAccountsDr.Quantitative AS QuantitativeDr,
	|	PropertiesOfAccountingAccountsDr.AccountingByBusinessUnits AS AccountingByBusinessUnitsDr,
	|	PropertiesOfAccountingAccountsDr.AccountingByLinesOfBusiness AS AccountingByLinesOfBusinessDr,
	|	PropertiesOfAccountingAccountsDr.ExtDimensionCount AS ExtDimensionCountDr,
	|	PropertiesOfAccountingAccountsDr.ExtDimensionType1 AS ExtDimensionTypeDr1,
	|	PropertiesOfAccountingAccountsDr.ExtDimensionType2 AS ExtDimensionTypeDr2,
	|	PropertiesOfAccountingAccountsDr.ExtDimensionType3 AS ExtDimensionTypeDr3,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherDrOperations
	|			THEN AccountSettingsForOtherDrOperations.ExtDimension1
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueDr1
	|		ELSE IndicatedValuesOfExtdimensionOfDr.ExtraDimensionValue1
	|	END AS ExtraDimensionValueDr1,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherDrOperations
	|			THEN AccountSettingsForOtherDrOperations.ExtDimension2
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueDr2
	|		ELSE IndicatedValuesOfExtdimensionOfDr.ExtraDimensionValue2
	|	END AS ExtraDimensionValueDr2,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherDrOperations
	|			THEN AccountSettingsForOtherDrOperations.ExtDimension3
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueDr3
	|		ELSE IndicatedValuesOfExtdimensionOfDr.ExtraDimensionValue3
	|	END AS ExtraDimensionValueDr3,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherDrOperations
	|			THEN TRUE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN NOT ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueDr1 IS NULL
	|		ELSE NOT IndicatedValuesOfExtdimensionOfDr.ExtraDimensionValue1 IS NULL
	|	END AS DoNotComputeExtdimensionDr1,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherDrOperations
	|			THEN TRUE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN NOT ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueDr2 IS NULL
	|		ELSE NOT IndicatedValuesOfExtdimensionOfDr.ExtraDimensionValue2 IS NULL
	|	END AS DoNotComputeExtdimensionDr2,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherDrOperations
	|			THEN TRUE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN NOT ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueDr3 IS NULL
	|		ELSE NOT IndicatedValuesOfExtdimensionOfDr.ExtraDimensionValue3 IS NULL
	|	END AS DoNotComputeExtdimensionDr3,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr1
	|		ELSE ExtdimensionFillingExpressionsDr.ExpressionOfExtdimension1
	|	END AS ExpressionOfExtdimensionDr1,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr2
	|		ELSE ExtdimensionFillingExpressionsDr.ExpressionOfExtdimension2
	|	END AS ExpressionOfExtdimensionDr2,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsDr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionDr3
	|		ELSE ExtdimensionFillingExpressionsDr.ExpressionOfExtdimension3
	|	END AS ExpressionOfExtdimensionDr3,
	|	ISNULL(ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr1, FALSE) AS CorExpressionDr1,
	|	ISNULL(ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr2, FALSE) AS CorExpressionDr2,
	|	ISNULL(ExpressionsOfExtdimensionOfRevolutions.CorExpressionDr3, FALSE) AS CorExpressionDr3,
	|	RegisteredRecordsWithAccounts.GLAccountCr AS GLAccountCr,
	|	PropertiesOfAccountingAccountsCr.Currency1 AS Currency1Cr,
	|	PropertiesOfAccountingAccountsCr.Quantitative AS QuantitativeCr,
	|	PropertiesOfAccountingAccountsCr.AccountingByBusinessUnits AS AccountingByBusinessUnitsCr,
	|	PropertiesOfAccountingAccountsCr.AccountingByLinesOfBusiness AS AccountingByLinesOfBusinessCr,
	|	PropertiesOfAccountingAccountsCr.ExtDimensionCount AS ExtDimensionCountCr,
	|	PropertiesOfAccountingAccountsCr.ExtDimensionType1 AS ExtDimensionTypeCr1,
	|	PropertiesOfAccountingAccountsCr.ExtDimensionType2 AS ExtDimensionTypeCr2,
	|	PropertiesOfAccountingAccountsCr.ExtDimensionType3 AS ExtDimensionTypeCr3,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherCrOperations
	|			THEN AccountSettingsForOtherCrOperations.ExtDimension1
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueCr1
	|		ELSE IndicatedValuesOfExtdimensionCr.ExtraDimensionValue1
	|	END AS ExtraDimensionValueCr1,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherCrOperations
	|			THEN AccountSettingsForOtherCrOperations.ExtDimension2
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueCr2
	|		ELSE IndicatedValuesOfExtdimensionCr.ExtraDimensionValue2
	|	END AS ExtraDimensionValueCr2,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherCrOperations
	|			THEN AccountSettingsForOtherCrOperations.ExtDimension3
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueCr3
	|		ELSE IndicatedValuesOfExtdimensionCr.ExtraDimensionValue3
	|	END AS ExtraDimensionValueCr3,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherCrOperations
	|			THEN TRUE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN NOT ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueCr1 IS NULL
	|		ELSE NOT IndicatedValuesOfExtdimensionCr.ExtraDimensionValue1 IS NULL
	|	END AS DoNotComputeExtdimensionCr1,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherCrOperations
	|			THEN TRUE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN NOT ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueCr2 IS NULL
	|		ELSE NOT IndicatedValuesOfExtdimensionCr.ExtraDimensionValue2 IS NULL
	|	END AS DoNotComputeExtdimensionCr2,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseSettingsForOtherCrOperations
	|			THEN TRUE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN NOT ValuesOfExtdimensionOfRevolutions.ExtraDimensionValueCr3 IS NULL
	|		ELSE NOT IndicatedValuesOfExtdimensionCr.ExtraDimensionValue3 IS NULL
	|	END AS DoNotComputeExtdimensionCr3,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr1
	|		ELSE ExtdimensionFillingExpressionsCr.ExpressionOfExtdimension1
	|	END AS ExpressionOfExtdimensionCr1,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr2
	|		ELSE ExtdimensionFillingExpressionsCr.ExpressionOfExtdimension2
	|	END AS ExpressionOfExtdimensionCr2,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.UseCorrespondenceSettingsCr
	|			THEN ExpressionsOfExtdimensionOfRevolutions.ExpressionOfExtdimensionCr3
	|		ELSE ExtdimensionFillingExpressionsCr.ExpressionOfExtdimension3
	|	END AS ExpressionOfExtdimensionCr3,
	|	ISNULL(ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr1, FALSE) AS CorExpressionCr1,
	|	ISNULL(ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr2, FALSE) AS CorExpressionCr2,
	|	ISNULL(ExpressionsOfExtdimensionOfRevolutions.CorExpressionCr3, FALSE) AS CorExpressionCr3,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	RegisteredRecordsWithAccounts.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithAccounts.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithAccounts.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsWithAccounts.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectDr AS SettingObject1Dr,
	|	RegisteredRecordsWithAccounts.SourceConfigurationObjectCr AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithAccounts.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithAccounts.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithAccounts.InvertEntriy AS InvertEntriy,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	REFPRESENTATION(RegisteredRecordsWithAccounts.SettingUpBusinessTransaction) AS SettingUpBusinessTransactionPresentation,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithAccounts.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithAccounts.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithAccounts.PropsStorno AS PropsStorno,
	|	RegisteredRecordsWithAccounts.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithAccounts.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithAccounts.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithAccounts.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithAccounts.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithAccounts.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithAccounts.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithAccounts.ManualSpecificationOfEntry AS ManualSpecificationOfEntry,
	|	RegisteredRecordsWithAccounts.InvertTheResourceSign AS InvertTheResourceSign,
	|	RegisteredRecordsWithAccounts.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsWithAccounts.MaturityDateCr AS MaturityDateCr,
	|	RegisteredRecordsWithAccounts.SumManDr AS SumMan,
	|	RegisteredRecordsWithAccounts.SumComplDr AS SumCompl,
	|	RegisteredRecordsWithAccounts.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsWithAccounts.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsWithAccounts.CountDr AS CountDr,
	|	RegisteredRecordsWithAccounts.CountCr AS CountCr
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|	LEFT JOIN TTPropertiesOfAccountingAccounts AS PropertiesOfAccountingAccountsDr
	|		ON RegisteredRecordsWithAccounts.GLAccountDr = PropertiesOfAccountingAccountsDr.GLAccount
	|	LEFT JOIN TTPropertiesOfAccountingAccounts AS PropertiesOfAccountingAccountsCr
	|		ON RegisteredRecordsWithAccounts.GLAccountCr = PropertiesOfAccountingAccountsCr.GLAccount
	|	LEFT JOIN TTSpecifiedValuesOfExtdimension AS IndicatedValuesOfExtdimensionOfDr
	|		ON RegisteredRecordsWithAccounts.AccountingObjectDr = IndicatedValuesOfExtdimensionOfDr.AccountingObject
	|		 AND RegisteredRecordsWithAccounts.GLAccountDr = IndicatedValuesOfExtdimensionOfDr.GLAccount
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = IndicatedValuesOfExtdimensionOfDr.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = IndicatedValuesOfExtdimensionOfDr.PostingGenerationSetting
	|	LEFT JOIN TTSpecifiedValuesOfExtdimension AS IndicatedValuesOfExtdimensionCr
	|		ON RegisteredRecordsWithAccounts.AccountingObjectCr = IndicatedValuesOfExtdimensionCr.AccountingObject
	|		 AND RegisteredRecordsWithAccounts.GLAccountCr = IndicatedValuesOfExtdimensionCr.GLAccount
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = IndicatedValuesOfExtdimensionCr.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = IndicatedValuesOfExtdimensionCr.PostingGenerationSetting
	|	LEFT JOIN TTExpressionsOfExtdimensionFilling AS ExtdimensionFillingExpressionsDr
	|		ON RegisteredRecordsWithAccounts.RegisterNameDr = ExtdimensionFillingExpressionsDr.RegisterName
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectDr = ExtdimensionFillingExpressionsDr.AccountingObject
	|		 AND RegisteredRecordsWithAccounts.GLAccountDr = ExtdimensionFillingExpressionsDr.GLAccount
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = ExtdimensionFillingExpressionsDr.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = ExtdimensionFillingExpressionsDr.PostingGenerationSetting
	|	LEFT JOIN TTExpressionsOfExtdimensionFilling AS ExtdimensionFillingExpressionsCr
	|		ON RegisteredRecordsWithAccounts.RegisterNameCr = ExtdimensionFillingExpressionsCr.RegisterName
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectCr = ExtdimensionFillingExpressionsCr.AccountingObject
	|		 AND RegisteredRecordsWithAccounts.GLAccountCr = ExtdimensionFillingExpressionsCr.GLAccount
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = ExtdimensionFillingExpressionsCr.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = ExtdimensionFillingExpressionsCr.PostingGenerationSetting
	|	LEFT JOIN TTValuesOfExtdimensionOfRevolutions AS ValuesOfExtdimensionOfRevolutions
	|		ON RegisteredRecordsWithAccounts.AccountingObjectDr = ValuesOfExtdimensionOfRevolutions.AccountingObjectDr
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectCr = ValuesOfExtdimensionOfRevolutions.AccountingObjectCr
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = ValuesOfExtdimensionOfRevolutions.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = ValuesOfExtdimensionOfRevolutions.PostingGenerationSetting
	|		 AND RegisteredRecordsWithAccounts.ApplicationProcedure = ValuesOfExtdimensionOfRevolutions.ApplicationProcedure
	|		 AND RegisteredRecordsWithAccounts.InvertEntriy = ValuesOfExtdimensionOfRevolutions.InvertEntriy
	|	LEFT JOIN TTExtdimensionOfRevolutions AS ExpressionsOfExtdimensionOfRevolutions
	|		ON RegisteredRecordsWithAccounts.RegisterNameDr = ExpressionsOfExtdimensionOfRevolutions.RegisterNameDr
	|		 AND RegisteredRecordsWithAccounts.RegisterNameCr = ExpressionsOfExtdimensionOfRevolutions.RegisterNameCr
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectDr = ExpressionsOfExtdimensionOfRevolutions.AccountingObjectDr
	|		 AND RegisteredRecordsWithAccounts.AccountingObjectCr = ExpressionsOfExtdimensionOfRevolutions.AccountingObjectCr
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = ExpressionsOfExtdimensionOfRevolutions.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.PostingGenerationSetting = ExpressionsOfExtdimensionOfRevolutions.PostingGenerationSetting
	|		 AND RegisteredRecordsWithAccounts.ApplicationProcedure = ExpressionsOfExtdimensionOfRevolutions.ApplicationProcedure
	|		 AND RegisteredRecordsWithAccounts.InvertEntriy = ExpressionsOfExtdimensionOfRevolutions.InvertEntriy
	|	LEFT JOIN Catalog.OtherTransactionsGLAccountsSettings.FinancialAccountingSettings AS AccountSettingsForOtherDrOperations
	|		ON RegisteredRecordsWithAccounts.SettingObject1Dr = AccountSettingsForOtherDrOperations.Ref
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = AccountSettingsForOtherDrOperations.ChartOfAccounts
	|	LEFT JOIN Catalog.OtherTransactionsGLAccountsSettings.FinancialAccountingSettings AS AccountSettingsForOtherCrOperations
	|		ON RegisteredRecordsWithAccounts.SettingObject1Cr = AccountSettingsForOtherCrOperations.Ref
	|		 AND RegisteredRecordsWithAccounts.ChartOfAccounts = AccountSettingsForOtherCrOperations.ChartOfAccounts
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

#EndRegion

#Region RequestTextsForProcessingRegisterRegisteredRecords

Procedure AddTablesOfInformationAboutAccountingObjects(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	SourcesWithDueDates.DataSource AS RegisterName,
	|	SourcesWithDueDates.AccountingObject AS AccountingObject
	|INTO TTSourcesWithDueDates
	|FROM
	|	&SourcesWithDueDates AS SourcesWithDueDates
	|INDEX BY
	|	RegisterName,
	|	AccountingObject
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ObjectsOfImproperValues.AccountingObject AS AccountingObject
	|INTO TTObjectsOfImproperValues
	|FROM
	|	&ObjectsOfImproperValues AS ObjectsOfImproperValues
	|INDEX BY
	|	AccountingObject
	|");
	
	AddTablesOfSignsOfCorrespondenceAccounting(QueriesTexts);
	
EndProcedure

Procedure AddTablesOfSignsOfCorrespondenceAccounting(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	SignsOfCorrespondenceAccounting.AccountingObject AS AccountingObject,
	|	SignsOfCorrespondenceAccounting.CorObjectOfAccounting AS CorObjectOfAccounting,
	|	SignsOfCorrespondenceAccounting.AccountingFlag AS AccountingFlag,
	|	SignsOfCorrespondenceAccounting.Value AS Value
	|INTO TTInitialSignsOfCorrespondenceAccounting
	|FROM
	|	&SignsOfCorrespondenceAccounting AS SignsOfCorrespondenceAccounting
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	SignsOfCorrespondenceAccounting.AccountingFlag AS AccountingFlag,
	|	SignsOfCorrespondenceAccounting.Value AS Value,
	|	RECORDAUTONUMBER() AS ValueNumber
	|INTO TTValuesOfCorrespondenceAccountingFeatures
	|FROM
	|	TTInitialSignsOfCorrespondenceAccounting AS SignsOfCorrespondenceAccounting
	|GROUP BY
	|	SignsOfCorrespondenceAccounting.AccountingFlag,
	|	SignsOfCorrespondenceAccounting.Value
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ValuesOfSignsOfCorrespondenceAccounting.AccountingFlag AS AccountingFlag,
	|	MIN(ValuesOfSignsOfCorrespondenceAccounting.Value) AS MinValue,
	|	MAX(ValuesOfSignsOfCorrespondenceAccounting.Value) AS MaxValue,
	|	COUNT(ValuesOfSignsOfCorrespondenceAccounting.Value) AS ValuesCount
	|INTO TTResultsOfSignsOfCorrespondenceAccounting
	|FROM
	|	TTValuesOfCorrespondenceAccountingFeatures AS ValuesOfSignsOfCorrespondenceAccounting
	|GROUP BY
	|	ValuesOfSignsOfCorrespondenceAccounting.AccountingFlag
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN SignsOfCorrespondenceAccounting.AccountingObject
	|		ELSE SignsOfCorrespondenceAccounting.CorObjectOfAccounting
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN SignsOfCorrespondenceAccounting.CorObjectOfAccounting
	|		ELSE SignsOfCorrespondenceAccounting.AccountingObject
	|	END AS AccountingObjectCr,
	|	SignsOfCorrespondenceAccounting.AccountingFlag AS AccountingFlag,
	|	SignsOfCorrespondenceAccounting.Value AS Value,
	|	ValuesOfAccountingAttributes.ValueNumber AS ValueNumber,
	|	ResultsOfAccountingSigns.MinValue AS MinValue,
	|	ResultsOfAccountingSigns.MaxValue AS MaxValue,
	|	ResultsOfAccountingSigns.ValuesCount AS ValuesCount
	|INTO TTSignsOfCorrespondenceAccounting
	|FROM
	|	TTInitialSignsOfCorrespondenceAccounting AS SignsOfCorrespondenceAccounting
	|	INNER JOIN TTValuesOfCorrespondenceAccountingFeatures AS ValuesOfAccountingAttributes
	|		ON SignsOfCorrespondenceAccounting.AccountingFlag = ValuesOfAccountingAttributes.AccountingFlag
	|		 AND SignsOfCorrespondenceAccounting.Value = ValuesOfAccountingAttributes.Value
	|	INNER JOIN TTResultsOfSignsOfCorrespondenceAccounting AS ResultsOfAccountingSigns
	|		ON SignsOfCorrespondenceAccounting.AccountingFlag = ResultsOfAccountingSigns.AccountingFlag
	|	,
	|	(SELECT
	|		&Dr AS DrCr
	|	UNION ALL
	|	SELECT
	|		&Cr AS DrCr
	|	) AS PartsOfDoubleEntry
	|INDEX BY
	|	AccountingObjectDr,
	|	AccountingObjectCr,
	|	AccountingFlag
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTInitialSignsOfCorrespondenceAccounting");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTValuesOfCorrespondenceAccountingFeatures");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTResultsOfSignsOfCorrespondenceAccounting");
	
EndProcedure

Procedure AddTablesOfDebitAndCreditRegisteredRecords(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|	RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS OfficialTypeOfActivityVAT,
	|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
	|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
	|INTO TTMovementRegistersDebit
	|FROM
	|	(SELECT
	|		RegisterRegisteredRecords_1.Period AS Period,
	|		RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|		RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|		RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|		RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|		RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|		RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRegisteredRecords_1.Organization AS Organization,
	|		RegisterRegisteredRecords_1.Recorder AS Recorder,
	|		RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|		RegisterRegisteredRecords_1.RowID AS RowID,
	|		RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
	|		RegisterRecordsWithStorno.SettingObject1 AS SettingObject1,
	|		RegisterRecordsWithStorno.PlaceOfRegistration AS PlaceOfRegistration,
	|		RegisterRecordsWithStorno.ThisIsLoan AS ThisIsDebit,
	|		NOT RegisterRecordsWithStorno.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRecordsWithStorno.Organization AS Organization,
	|		RegisterRecordsWithStorno.Recorder AS Recorder,
	|		RegisterRecordsWithStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRecordsWithStorno.FinRecordID AS FinRecordID,
	|		RegisterRecordsWithStorno.RowID AS RowID,
	|		RegisterRecordsWithStorno.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRecordsWithStorno.MaturityDate AS MaturityDate,
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
	|	RegisterName,
	|	AccountingObject
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
	|INTO TTMovementRegistersCredit
	|FROM
	|	(SELECT
	|		RegisterRegisteredRecords_1.Period AS Period,
	|		RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|		RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|		RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|		RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|		RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|		RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRegisteredRecords_1.Organization AS Organization,
	|		RegisterRegisteredRecords_1.Recorder AS Recorder,
	|		RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|		RegisterRegisteredRecords_1.RowID AS RowID,
	|		RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
	|		RegisterRecordsWithStorno.SettingObject1 AS SettingObject1,
	|		RegisterRecordsWithStorno.PlaceOfRegistration AS PlaceOfRegistration,
	|		RegisterRecordsWithStorno.ThisIsDebit AS ThisIsLoan,
	|		NOT RegisterRecordsWithStorno.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|		RegisterRecordsWithStorno.Organization AS Organization,
	|		RegisterRecordsWithStorno.Recorder AS Recorder,
	|		RegisterRecordsWithStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|		RegisterRecordsWithStorno.FinRecordID AS FinRecordID,
	|		RegisterRecordsWithStorno.RowID AS RowID,
	|		RegisterRecordsWithStorno.OfficialTypeOfActivityVAT AS VATActivityType,
	|		RegisterRecordsWithStorno.MaturityDate AS MaturityDate,
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
	|	RegisterName,
	|	AccountingObject
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
	
	CollapseRegisteredRecordsByKeyFields(Query, QueriesTexts, "Dr");
	CollapseRegisteredRecordsByKeyFields(Query, QueriesTexts, "Cr");
	
	IdentifyComplexTransactionsWithIndicationOfCorSources(Query, QueriesTexts);
	
	AddDataSourceIDs(QueriesTexts, Query.Parameters, "Dr");
	AddDataSourceIDs(QueriesTexts, Query.Parameters, "Cr");
	
	AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, "Dr");
	AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, "Cr");
	
	ConnectRegisteredRecordsByKeyFields(Query, QueriesTexts);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisteredRecordsWithDebitTotals");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisteredRecordsWithCreditTotals");
	
EndProcedure

Procedure CollapseRegisteredRecordsByKeyFields(Query, QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RecNo AS RecNo,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	RegisterRegisteredRecords_1.SumMan AS SumMan,
	|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTDetailedRegisteredRecords
	|FROM
	|	TTRegisterRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTSourcesWithDueDates AS SourcesWithDueDates
	|		WHERE
	|			SourcesWithDueDates.RegisterName = RegisterRegisteredRecords_1.RegisterName
	|			AND SourcesWithDueDates.AccountingObject = RegisterRegisteredRecords_1.AccountingObject
	|		)
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	RowID,
	|	RegisterName,
	|	AccountingObject,
	|	SettingObject1,
	|	PlaceOfRegistration,
	|	Organization,
	|	VATActivityType,
	|	Currency,
	|	ThisIsDrCr,
	|	ThisIsReverseTransaction,
	|	PropsStorno
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	DetailedRegisteredRecords.Period AS Period,
	|	DetailedRegisteredRecords.RegisterName AS RegisterName,
	|	DetailedRegisteredRecords.AccountingObject AS AccountingObject,
	|	DetailedRegisteredRecords.SettingObject1 AS SettingObject1,
	|	DetailedRegisteredRecords.PlaceOfRegistration AS PlaceOfRegistration,
	|	DetailedRegisteredRecords.ThisIsDrCr AS ThisIsDrCr,
	|	DetailedRegisteredRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	DetailedRegisteredRecords.Organization AS Organization,
	|	DetailedRegisteredRecords.Recorder AS Recorder,
	|	DetailedRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DetailedRegisteredRecords.FinRecordID AS FinRecordID,
	|	DetailedRegisteredRecords.RowID AS RowID,
	|	DetailedRegisteredRecords.VATActivityType AS VATActivityType,
	|	DetailedRegisteredRecords.Currency AS Currency,
	|	DetailedRegisteredRecords.PropsStorno AS PropsStorno,
	|	MAX(DetailedRegisteredRecords.RecNo) AS RecNo,
	|	MAX(DetailedRegisteredRecords.MaturityDate) AS MaturityDate,
	|	COUNT(DISTINCT DetailedRegisteredRecords.MaturityDate) AS NumberOfRepaymentStages,
	|	SUM(DetailedRegisteredRecords.SumMan) AS SumMan,
	|	SUM(DetailedRegisteredRecords.SumCompl) AS SumCompl,
	|	SUM(DetailedRegisteredRecords.SumCurr) AS SumCurr,
	|	SUM(DetailedRegisteredRecords.Count) AS Count
	|INTO TTResultsOfDetailedRegisteredRecords
	|FROM
	|	TTDetailedRegisteredRecords AS DetailedRegisteredRecords
	|GROUP BY
	|	DetailedRegisteredRecords.Period,
	|	DetailedRegisteredRecords.Recorder,
	|	DetailedRegisteredRecords.FinRecordID,
	|	DetailedRegisteredRecords.SettingUpBusinessTransaction,
	|	DetailedRegisteredRecords.RowID,
	|	DetailedRegisteredRecords.RegisterName,
	|	DetailedRegisteredRecords.AccountingObject,
	|	DetailedRegisteredRecords.SettingObject1,
	|	DetailedRegisteredRecords.PlaceOfRegistration,
	|	DetailedRegisteredRecords.Organization,
	|	DetailedRegisteredRecords.VATActivityType,
	|	DetailedRegisteredRecords.Currency,
	|	DetailedRegisteredRecords.ThisIsDrCr,
	|	DetailedRegisteredRecords.ThisIsReverseTransaction,
	|	DetailedRegisteredRecords.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	RowID,
	|	RegisterName,
	|	AccountingObject,
	|	SettingObject1,
	|	PlaceOfRegistration,
	|	Organization,
	|	VATActivityType,
	|	Currency,
	|	ThisIsDrCr,
	|	ThisIsReverseTransaction,
	|	PropsStorno
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	CurCurrentTableOfRegisteredRecordsWithTotals = ?(DrCr = "Dr",
		Query.Parameters.TableOfDetailedRegisteredRecordsWithDebitTotals,
		Query.Parameters.TableOfDetailedRegisteredRecordsWithCreditTotals);
	
	CreateTableOfRegisteredRecordsWithTotals = Query.TempTablesManager.Tables.Find(CurCurrentTableOfRegisteredRecordsWithTotals) = Undefined;
	
	If CreateTableOfRegisteredRecordsWithTotals Then
		CompleteTableOfRegisteredRecordsWithTotals = False;
		CreatedTableOfRegisteredRecordsWithTotals = CurCurrentTableOfRegisteredRecordsWithTotals;
	Else
		CompleteTableOfRegisteredRecordsWithTotals = FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTResultsOfDetailedRegisteredRecords");
		If CompleteTableOfRegisteredRecordsWithTotals Then
			CreatedTableOfRegisteredRecordsWithTotals = CurCurrentTableOfRegisteredRecordsWithTotals + "1";
			DeletedTableOfRegisteredRecordsWithTotals = CurCurrentTableOfRegisteredRecordsWithTotals;
		EndIf;
	EndIf;
	
	If CreateTableOfRegisteredRecordsWithTotals Or CompleteTableOfRegisteredRecordsWithTotals Then
		QueryText = "
		|SELECT
		|	DetailedRegisteredRecords.Period AS Period,
		|	DetailedRegisteredRecords.RegisterName AS RegisterName,
		|	DetailedRegisteredRecords.AccountingObject AS AccountingObject,
		|	DetailedRegisteredRecords.SettingObject1 AS SettingObject1,
		|	DetailedRegisteredRecords.PlaceOfRegistration AS PlaceOfRegistration,
		|	DetailedRegisteredRecords.ThisIsDrCr AS ThisIsDrCr,
		|	DetailedRegisteredRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	DetailedRegisteredRecords.Organization AS Organization,
		|	DetailedRegisteredRecords.Recorder AS Recorder,
		|	DetailedRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	DetailedRegisteredRecords.FinRecordID AS FinRecordID,
		|	DetailedRegisteredRecords.RowID AS RowID,
		|	DetailedRegisteredRecords.VATActivityType AS VATActivityType,
		|	DetailedRegisteredRecords.MaturityDate AS MaturityDate,
		|	DetailedRegisteredRecords.Currency AS Currency,
		|	DetailedRegisteredRecords.SumMan AS SumMan,
		|	DetailedRegisteredRecords.SumCompl AS SumCompl,
		|	DetailedRegisteredRecords.SumCurr AS SumCurr,
		|	DetailedRegisteredRecords.Count AS Count,
		|	DetailedRegisteredRecords.PropsStorno AS PropsStorno,
		|	ISNULL(ResultsOfDetailedRegisteredRecords.RecNo, 0) AS RecNo,
		|	ISNULL(ResultsOfDetailedRegisteredRecords.NumberOfRepaymentStages, 1) AS NumberOfRepaymentStages
		|INTO CreatedTableOfRegisteredRecordsWithTotals
		|FROM
		|	TTDetailedRegisteredRecords AS DetailedRegisteredRecords
		|	LEFT JOIN TTResultsOfDetailedRegisteredRecords AS ResultsOfDetailedRegisteredRecords
		|		ON DetailedRegisteredRecords.Period = ResultsOfDetailedRegisteredRecords.Period
		|		 AND DetailedRegisteredRecords.Recorder = ResultsOfDetailedRegisteredRecords.Recorder
		|		 AND DetailedRegisteredRecords.FinRecordID = ResultsOfDetailedRegisteredRecords.FinRecordID
		|		 AND DetailedRegisteredRecords.SettingUpBusinessTransaction = ResultsOfDetailedRegisteredRecords.SettingUpBusinessTransaction
		|		 AND DetailedRegisteredRecords.RowID = ResultsOfDetailedRegisteredRecords.RowID
		|		 AND DetailedRegisteredRecords.RegisterName = ResultsOfDetailedRegisteredRecords.RegisterName
		|		 AND DetailedRegisteredRecords.AccountingObject = ResultsOfDetailedRegisteredRecords.AccountingObject
		|		 AND DetailedRegisteredRecords.SettingObject1 = ResultsOfDetailedRegisteredRecords.SettingObject1
		|		 AND DetailedRegisteredRecords.PlaceOfRegistration = ResultsOfDetailedRegisteredRecords.PlaceOfRegistration
		|		 AND DetailedRegisteredRecords.Organization = ResultsOfDetailedRegisteredRecords.Organization
		|		 AND DetailedRegisteredRecords.VATActivityType = ResultsOfDetailedRegisteredRecords.VATActivityType
		|		 AND DetailedRegisteredRecords.Currency = ResultsOfDetailedRegisteredRecords.Currency
		|		 AND DetailedRegisteredRecords.ThisIsDrCr = ResultsOfDetailedRegisteredRecords.ThisIsDrCr
		|		 AND DetailedRegisteredRecords.ThisIsReverseTransaction = ResultsOfDetailedRegisteredRecords.ThisIsReverseTransaction
		|		 AND DetailedRegisteredRecords.PropsStorno = ResultsOfDetailedRegisteredRecords.PropsStorno
		|";
		
		QueryText = StrReplace(QueryText, "CreatedTableOfRegisteredRecordsWithTotals", CreatedTableOfRegisteredRecordsWithTotals);
		
		If CompleteTableOfRegisteredRecordsWithTotals Then
			QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT
			|	DetailedRegisteredRecordsWithResults.Period AS Period,
			|	DetailedRegisteredRecordsWithResults.RegisterName AS RegisterName,
			|	DetailedRegisteredRecordsWithResults.AccountingObject AS AccountingObject,
			|	DetailedRegisteredRecordsWithResults.SettingObject1 AS SettingObject1,
			|	DetailedRegisteredRecordsWithResults.PlaceOfRegistration AS PlaceOfRegistration,
			|	DetailedRegisteredRecordsWithResults.ThisIsDrCr AS ThisIsDrCr,
			|	DetailedRegisteredRecordsWithResults.ThisIsReverseTransaction AS ThisIsReverseTransaction,
			|	DetailedRegisteredRecordsWithResults.Organization AS Organization,
			|	DetailedRegisteredRecordsWithResults.Recorder AS Recorder,
			|	DetailedRegisteredRecordsWithResults.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
			|	DetailedRegisteredRecordsWithResults.FinRecordID AS FinRecordID,
			|	DetailedRegisteredRecordsWithResults.RowID AS RowID,
			|	DetailedRegisteredRecordsWithResults.VATActivityType AS VATActivityType,
			|	DetailedRegisteredRecordsWithResults.MaturityDate AS MaturityDate,
			|	DetailedRegisteredRecordsWithResults.Currency AS Currency,
			|	DetailedRegisteredRecordsWithResults.SumMan AS SumMan,
			|	DetailedRegisteredRecordsWithResults.SumCompl AS SumCompl,
			|	DetailedRegisteredRecordsWithResults.SumCurr AS SumCurr,
			|	DetailedRegisteredRecordsWithResults.Count AS Count,
			|	DetailedRegisteredRecordsWithResults.PropsStorno AS PropsStorno,
			|	DetailedRegisteredRecordsWithResults.RecNo AS RecNo,
			|	DetailedRegisteredRecordsWithResults.NumberOfRepaymentStages AS NumberOfRepaymentStages
			|FROM
			|	DeletedTableOfRegisteredRecordsWithTotals AS DetailedRegisteredRecordsWithResults
			|";
			
			QueryText = StrReplace(QueryText, "DeletedTableOfRegisteredRecordsWithTotals", DeletedTableOfRegisteredRecordsWithTotals);
		EndIf;
		
		QueryText = QueryText + "
		|INDEX BY
		|	RecNo
		|";
		
		FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
		QueriesTexts.Add(QueryText);
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTDetailedRegisteredRecords");
	
	If CompleteTableOfRegisteredRecordsWithTotals Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTableOfRegisteredRecordsWithTotals);

		If DrCr = "Dr" Then
			Query.Parameters.TableOfDetailedRegisteredRecordsWithDebitTotals = CreatedTableOfRegisteredRecordsWithTotals;
		Else
			Query.Parameters.TableOfDetailedRegisteredRecordsWithCreditTotals = CreatedTableOfRegisteredRecordsWithTotals;
		EndIf;
	EndIf;
	
	QueryText = "
	|SELECT
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RecNo AS RecNo,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.AccountingObject AS AccountingObject,
	|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	RegisterRegisteredRecords_1.SumMan AS SumMan,
	|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTFoldedRegisteredRecordsDrCr
	|FROM
	|	TTRegisterRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTSourcesWithDueDates AS SourcesWithDueDates
	|		WHERE
	|			SourcesWithDueDates.RegisterName = RegisterRegisteredRecords_1.RegisterName
	|			AND SourcesWithDueDates.AccountingObject = RegisterRegisteredRecords_1.AccountingObject
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	ResultsOfDetailedRegisteredRecords.Period AS Period,
	|	ResultsOfDetailedRegisteredRecords.RecNo AS RecNo,
	|	ResultsOfDetailedRegisteredRecords.RegisterName AS RegisterName,
	|	ResultsOfDetailedRegisteredRecords.AccountingObject AS AccountingObject,
	|	ResultsOfDetailedRegisteredRecords.SettingObject1 AS SettingObject1,
	|	ResultsOfDetailedRegisteredRecords.PlaceOfRegistration AS PlaceOfRegistration,
	|	ResultsOfDetailedRegisteredRecords.ThisIsDrCr AS ThisIsDrCr,
	|	ResultsOfDetailedRegisteredRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	ResultsOfDetailedRegisteredRecords.Organization AS Organization,
	|	ResultsOfDetailedRegisteredRecords.Recorder AS Recorder,
	|	ResultsOfDetailedRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	ResultsOfDetailedRegisteredRecords.FinRecordID AS FinRecordID,
	|	ResultsOfDetailedRegisteredRecords.RowID AS RowID,
	|	ResultsOfDetailedRegisteredRecords.VATActivityType AS VATActivityType,
	|	ResultsOfDetailedRegisteredRecords.MaturityDate AS MaturityDate,
	|	ResultsOfDetailedRegisteredRecords.Currency AS Currency,
	|	ResultsOfDetailedRegisteredRecords.SumMan AS SumMan,
	|	ResultsOfDetailedRegisteredRecords.SumCompl AS SumCompl,
	|	ResultsOfDetailedRegisteredRecords.SumCurr AS SumCurr,
	|	ResultsOfDetailedRegisteredRecords.Count AS Count,
	|	ResultsOfDetailedRegisteredRecords.PropsStorno AS PropsStorno
	|FROM
	|	TTResultsOfDetailedRegisteredRecords AS ResultsOfDetailedRegisteredRecords
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTRegisterRegisteredRecordsDrCr";
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTResultsOfDetailedRegisteredRecords");
	
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
	|	CorDataSources.CorRegisterName,
	|	CorDataSources.CorID
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	CorRegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	MovementCredit.Period AS Period,
	|	MovementCredit.Organization AS Organization,
	|	MovementCredit.Recorder AS Recorder,
	|	MovementCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementCredit.FinRecordID AS FinRecordID,
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
	|	CorDataSources.CorRegisterName,
	|	CorDataSources.CorID
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	CorRegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction
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
		|GROUP BY
		|	DirectDebit.Period,
		|	DirectDebit.Recorder,
		|	DirectDebit.FinRecordID,
		|	DirectDebit.RegisterName,
		|	DirectDebit.Organization,
		|	DirectDebit.SettingUpBusinessTransaction
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
		|GROUP BY
		|	MovementCredit.Period,
		|	MovementCredit.Recorder,
		|	MovementCredit.FinRecordID,
		|	MovementCredit.RegisterName,
		|	MovementCredit.Organization,
		|	MovementCredit.SettingUpBusinessTransaction
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
	|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
	|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
		|	RegisterRegisteredRecords_1.SettingObject1 AS SettingObject1,
		|	RegisterRegisteredRecords_1.PlaceOfRegistration AS PlaceOfRegistration,
		|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
		|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	RegisterRegisteredRecords_1.Organization AS Organization,
		|	RegisterRegisteredRecords_1.Recorder AS Recorder,
		|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
		|	RegisterRegisteredRecords_1.RowID AS RowID,
		|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
		|	RegisterRegisteredRecords_1.MaturityDate AS MaturityDate,
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
		|INDEX BY
		|	Period,
		|	Recorder,
		|	FinRecordID,
		|	SettingUpBusinessTransaction,
		|	Organization,
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
	|	RegisterRecords.IDOfCorOfDataSources AS IDOfCorOfDataSources,
	|	COUNT(RegisterRecords.FinRecordID) AS NumberOfFinRecords,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	MAX(RegisterRecords.SumMan = 0 AND RegisterRecords.SumCompl = 0) AS ThereIsZeroBalance
	|INTO TTResultsOfOperations
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTObjectsOfImproperValues AS ObjectsOfImproperValues
	|		WHERE
	|			ObjectsOfImproperValues.AccountingObject = RegisterRecords.AccountingObject
	|		)
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.SettingUpBusinessTransaction,
	|	RegisterRecords.Organization,
	|	RegisterRecords.IDOfCorOfDataSources
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	Organization,
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
	|			LEFT JOIN TTSignsOfCorrespondenceAccounting AS SignsOfCorrespondenceAccounting
	|				ON SignsOfCorrespondenceAccounting.AccountingObjectDrCr = RegisterRecords.AccountingObject
	|				 AND SignsOfCorrespondenceAccounting.AccountingObjectBalancedDrCr = MotionCor.AccountingObject
	|		WHERE
	|			MotionCor.Period = RegisterRecords.Period
	|			AND MotionCor.Recorder = RegisterRecords.Recorder
	|			AND MotionCor.FinRecordID = RegisterRecords.FinRecordID
	|			AND MotionCor.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND MotionCor.Organization = RegisterRecords.Organization
	|			AND MotionCor.ThisIsCorDrCr
	|			AND CASE
	|				WHEN SignsOfCorrespondenceAccounting.AccountingFlag IS NULL
	|					THEN TRUE
	|				ELSE SignsOfCorrespondenceAccounting.Value = SignsOfCorrespondenceAccounting.MaxValue
	|			END
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
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTObjectsOfImproperValues AS ObjectsOfImproperValues
	|		WHERE
	|			ObjectsOfImproperValues.AccountingObject = RegisterRecords.AccountingObject
	|		)
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RecNo AS RecNo,
	|	RegisterRecords.RegisterName AS RegisterName,
	|	RegisterRecords.AccountingObject AS AccountingObject,
	|	RegisterRecords.SettingObject1 AS SettingObject1,
	|	RegisterRecords.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRecords.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowID AS RowID,
	|	RegisterRecords.VATActivityType AS VATActivityType,
	|	RegisterRecords.MaturityDate AS MaturityDate,
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
	|	VALUETYPE(RegisterRecords.Recorder) AS TypeOfRegistrar,
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTObjectsOfImproperValues AS ObjectsOfImproperValues
	|		WHERE
	|			ObjectsOfImproperValues.AccountingObject = RegisterRecords.AccountingObject
	|	) AS ImproperValues
	|INTO TTRegisteredRecordsWithDrCrTotals
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|	LEFT JOIN TTResultsOfOperations AS ResultsForOperations
	|		ON RegisterRecords.Period = ResultsForOperations.Period
	|		 AND RegisterRecords.Recorder = ResultsForOperations.Recorder
	|		 AND RegisterRecords.FinRecordID = ResultsForOperations.FinRecordID
	|		 AND RegisterRecords.SettingUpBusinessTransaction = ResultsForOperations.SettingUpBusinessTransaction
	|		 AND RegisterRecords.Organization = ResultsForOperations.Organization
	|		 AND RegisterRecords.IDOfCorOfDataSources = ResultsForOperations.IDOfCorOfDataSources
	|	LEFT JOIN TTResultsForFinRecords AS ResultsForFinRecords
	|		ON RegisterRecords.Period = ResultsForFinRecords.Period
	|		 AND RegisterRecords.Recorder = ResultsForFinRecords.Recorder
	|		 AND RegisterRecords.FinRecordID = ResultsForFinRecords.FinRecordID
	|		 AND RegisterRecords.Organization = ResultsForFinRecords.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	SettingUpBusinessTransaction,
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
	|		WHEN MovementCredit.ImproperValues
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		ELSE """"
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN NOT MovementCredit.RegisterName IS NULL
	|			THEN MovementCredit.RegisterName
	|		WHEN DirectDebit.ImproperValues
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		ELSE """"
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN NOT DirectDebit.AccountingObject IS NULL
	|			THEN DirectDebit.AccountingObject
	|		WHEN MovementCredit.ImproperValues
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
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
	|		WHEN DirectDebit.ImproperValues
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfDebtOffsetDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ARAPSettlements)
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|		  OR DirectDebit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RetailCustomerAccountsReceivables)
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	END AS AccountingObjectCr,
	|	ISNULL(DirectDebit.SettingObject1, UNDEFINED) AS SettingObject1Dr,
	|	ISNULL(MovementCredit.SettingObject1, UNDEFINED) AS SettingObject1Cr,
	|	ISNULL(DirectDebit.PlaceOfRegistration, UNDEFINED) AS PlaceOfRegistrationDr,
	|	ISNULL(MovementCredit.PlaceOfRegistration, UNDEFINED) AS PlaceOfRegistrationCr,
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
	|	ISNULL(DirectDebit.MaturityDate, DATETIME(0001,01,01)) AS MaturityDateDr,
	|	ISNULL(MovementCredit.MaturityDate, DATETIME(0001,01,01)) AS MaturityDateCr,
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
	|	ISNULL(DirectDebit.PropsStorno, FALSE) AS PropsStornoDr,
	|	ISNULL(MovementCredit.PropsStorno, FALSE) AS PropsStornoCr,
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
	|				WHEN MovementCredit.ImproperValues
	|					THEN MovementCredit.SumMan
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
	|				WHEN DirectDebit.ImproperValues
	|					THEN DirectDebit.SumMan
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
	|				WHEN MovementCredit.ImproperValues
	|					THEN MovementCredit.SumCompl
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
	|				WHEN DirectDebit.ImproperValues
	|					THEN DirectDebit.SumCompl
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
	|				AND CreditOnlyRegisteredRecords.ThisIsLoan
	|				AND (CreditOnlyRegisteredRecords.AccountingObject <> DirectDebit.AccountingObject OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|			)
	|	 END
	|	 AND CASE
	// correspondence of the records of the circulating registers with themselves is always prohibited
	|		WHEN NOT DirectDebit.ThisIsDebit AND NOT MovementCredit.ThisIsLoan
	|			THEN FALSE
	// records of improper controlled values do not form correspondence
	|		WHEN DirectDebit.ImproperValues OR MovementCredit.ImproperValues
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
	// improper controlled values are always displayed
	|				WHEN MovementCredit.ImproperValues
	|					THEN TRUE
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
	// improper controlled values are always displayed
	|				WHEN DirectDebit.ImproperValues
	|					THEN TRUE
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
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID
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
	|	RegisteredRecordsDebitCredit.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
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
	|	DetailedRegisteredRecordsWithResults.Period AS Period,
	|	DetailedRegisteredRecordsWithResults.RegisterName AS RegisterName,
	|	DetailedRegisteredRecordsWithResults.AccountingObject AS AccountingObject,
	|	DetailedRegisteredRecordsWithResults.SettingObject1 AS SettingObject1,
	|	DetailedRegisteredRecordsWithResults.PlaceOfRegistration AS PlaceOfRegistration,
	|	DetailedRegisteredRecordsWithResults.ThisIsDrCr AS ThisIsDrCr,
	|	DetailedRegisteredRecordsWithResults.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	DetailedRegisteredRecordsWithResults.Organization AS Organization,
	|	DetailedRegisteredRecordsWithResults.Recorder AS Recorder,
	|	DetailedRegisteredRecordsWithResults.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DetailedRegisteredRecordsWithResults.FinRecordID AS FinRecordID,
	|	DetailedRegisteredRecordsWithResults.RowID AS RowID,
	|	DetailedRegisteredRecordsWithResults.VATActivityType AS VATActivityType,
	|	DetailedRegisteredRecordsWithResults.MaturityDate AS MaturityDate,
	|	DetailedRegisteredRecordsWithResults.Currency AS Currency,
	|	DetailedRegisteredRecordsWithResults.SumMan AS SumMan,
	|	DetailedRegisteredRecordsWithResults.SumCompl AS SumCompl,
	|	DetailedRegisteredRecordsWithResults.SumCurr AS SumCurr,
	|	DetailedRegisteredRecordsWithResults.Count AS Count,
	|	DetailedRegisteredRecordsWithResults.PropsStorno AS PropsStorno
	|INTO TTDetailedRegisteredRecords
	|FROM
	|	TableOfDetailedRegisteredRecordsWithTotals AS DetailedRegisteredRecordsWithResults
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTCorrespondenceErrors AS CorrespondencesErrors
	|		WHERE
	|			CorrespondencesErrors.Period = DetailedRegisteredRecordsWithResults.Period
	|			AND CorrespondencesErrors.Recorder = DetailedRegisteredRecordsWithResults.Recorder
	|			AND CorrespondencesErrors.FinRecordID = DetailedRegisteredRecordsWithResults.FinRecordID
	|			AND CorrespondencesErrors.Organization = DetailedRegisteredRecordsWithResults.Organization
	|		)
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RegisterName,
	|	AccountingObject,
	|	Organization
	|";
	
	QueryText = StrReplace(QueryText, "TableOfDetailedRegisteredRecordsWithTotals", ?(DrCr = "Dr",
		QueryOptions.TableOfDetailedRegisteredRecordsWithDebitTotals,
		QueryOptions.TableOfDetailedRegisteredRecordsWithCreditTotals));
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterName AS RegisterName,
	|	RegisterRecords.AccountingObject AS AccountingObject,
	|	RegisterRecords.SettingObject1 AS SettingObject1,
	|	RegisterRecords.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisterRecords.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowID AS RowID,
	|	RegisterRecords.VATActivityType AS VATActivityType,
	|	RegisterRecords.MaturityDate AS MaturityDate,
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
	|		)
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTDetailedRegisteredRecords AS DetailedRegisteredRecords
	|		WHERE
	|			DetailedRegisteredRecords.Period = RegisterRecords.Period
	|			AND DetailedRegisteredRecords.Recorder = RegisterRecords.Recorder
	|			AND DetailedRegisteredRecords.FinRecordID = RegisterRecords.FinRecordID
	|			AND DetailedRegisteredRecords.RegisterName = RegisterRecords.RegisterName
	|			AND DetailedRegisteredRecords.AccountingObject = RegisterRecords.AccountingObject
	|			AND DetailedRegisteredRecords.Organization = RegisterRecords.Organization
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	DetailedRegisteredRecords.Period AS Period,
	|	DetailedRegisteredRecords.RegisterName AS RegisterName,
	|	DetailedRegisteredRecords.AccountingObject AS AccountingObject,
	|	DetailedRegisteredRecords.SettingObject1 AS SettingObject1,
	|	DetailedRegisteredRecords.PlaceOfRegistration AS PlaceOfRegistration,
	|	DetailedRegisteredRecords.ThisIsDrCr AS ThisIsDrCr,
	|	DetailedRegisteredRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	DetailedRegisteredRecords.Organization AS Organization,
	|	DetailedRegisteredRecords.Recorder AS Recorder,
	|	DetailedRegisteredRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DetailedRegisteredRecords.FinRecordID AS FinRecordID,
	|	DetailedRegisteredRecords.RowID AS RowID,
	|	DetailedRegisteredRecords.VATActivityType AS VATActivityType,
	|	DetailedRegisteredRecords.MaturityDate AS MaturityDate,
	|	DetailedRegisteredRecords.Currency AS Currency,
	|	DetailedRegisteredRecords.SumMan AS SumMan,
	|	DetailedRegisteredRecords.SumCompl AS SumCompl,
	|	DetailedRegisteredRecords.SumCurr AS SumCurr,
	|	DetailedRegisteredRecords.Count AS Count,
	|	DetailedRegisteredRecords.PropsStorno AS PropsStorno
	|FROM
	|	TTDetailedRegisteredRecords AS DetailedRegisteredRecords
	|INDEX BY
	|	ThisIsReverseTransaction
	|";
	
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTRegisteredRecordsDrCr";
	FinancialAccountingByBalanceSheetRegisterData.ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTDetailedRegisteredRecords");
	
EndProcedure

Procedure IdentifyRegistersWithReverseRegisteredRecords(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	MovementReverseDr.Period AS Period,
	|	MovementReverseDr.RegisterName AS RegisterName,
	|	MovementReverseDr.Organization AS Organization,
	|	MovementReverseDr.Recorder AS Recorder,
	|	MovementReverseDr.FinRecordID AS FinRecordID
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
	|	MovementReverseCr.FinRecordID AS FinRecordID
	|FROM
	|	TTMovementRegistersReverseCredit AS MovementReverseCr
	|WHERE
	|	MovementReverseCr.ThisIsReverseTransaction
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
	|");
	
EndProcedure

Procedure ReplaceReverseMovementWithReverse(QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	MovementReverse.Period AS Period,
	|	MovementReverse.RegisterName AS RegisterName,
	|	MovementReverse.AccountingObject AS AccountingObject,
	|	MovementReverse.SettingObject1 AS SettingObject1,
	|	MovementReverse.PlaceOfRegistration AS PlaceOfRegistration,
	|	MovementReverse.ThisIsDrCr AS ThisIsDrCr,
	|	MovementReverse.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	MovementReverse.Organization AS Organization,
	|	MovementReverse.Recorder AS Recorder,
	|	MovementReverse.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementReverse.FinRecordID AS FinRecordID,
	|	MovementReverse.RowID AS RowID,
	|	MovementReverse.VATActivityType AS VATActivityType,
	|	MovementReverse.MaturityDate AS MaturityDate,
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
	|	MovementReverse.SettingObject1 AS SettingObject1,
	|	MovementReverse.PlaceOfRegistration AS PlaceOfRegistration,
	|	MovementReverse.ThisIsCorDrCr AS ThisIsDrCr,
	|	NOT MovementReverse.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	MovementReverse.Organization AS Organization,
	|	MovementReverse.Recorder AS Recorder,
	|	MovementReverse.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementReverse.FinRecordID AS FinRecordID,
	|	MovementReverse.RowID AS RowID,
	|	MovementReverse.VATActivityType AS VATActivityType,
	|	MovementReverse.MaturityDate AS MaturityDate,
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
	|	RegisteredRecordsAreReversed.SettingObject1 AS SettingObject1,
	|	RegisteredRecordsAreReversed.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisteredRecordsAreReversed.ThisIsDrCr AS ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization AS Organization,
	|	RegisteredRecordsAreReversed.Recorder AS Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.FinRecordID AS FinRecordID,
	|	RegisteredRecordsAreReversed.RowID AS RowID,
	|	RegisteredRecordsAreReversed.VATActivityType AS VATActivityType,
	|	RegisteredRecordsAreReversed.MaturityDate AS MaturityDate,
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
	|	RegisteredRecordsAreReversed.SettingObject1,
	|	RegisteredRecordsAreReversed.PlaceOfRegistration,
	|	RegisteredRecordsAreReversed.ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization,
	|	RegisteredRecordsAreReversed.Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.FinRecordID,
	|	RegisteredRecordsAreReversed.RowID,
	|	RegisteredRecordsAreReversed.VATActivityType,
	|	RegisteredRecordsAreReversed.MaturityDate,
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
	|	RegisteredRecordsAreReversed.SettingObject1 AS SettingObject1,
	|	RegisteredRecordsAreReversed.PlaceOfRegistration AS PlaceOfRegistration,
	|	RegisteredRecordsAreReversed.ThisIsDrCr AS ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization AS Organization,
	|	RegisteredRecordsAreReversed.Recorder AS Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.FinRecordID AS FinRecordID,
	|	RegisteredRecordsAreReversed.RowID AS RowID,
	|	RegisteredRecordsAreReversed.VATActivityType AS VATActivityType,
	|	RegisteredRecordsAreReversed.MaturityDate AS MaturityDate,
	|	RegisteredRecordsAreReversed.Currency AS Currency,
	|	RegisteredRecordsAreReversed.SumMan AS SumMan,
	|	RegisteredRecordsAreReversed.SumCompl AS SumCompl,
	|	RegisteredRecordsAreReversed.SumCurr AS SumCurr,
	|	RegisteredRecordsAreReversed.Count AS Count,
	|	RegisteredRecordsAreReversed.PropsStorno AS PropsStorno
	|INTO TTRegisterRegisteredRecordsDrCr
	|FROM
	|	TTRolledUpRegisteredRecordsAreReversed AS RegisteredRecordsAreReversed
	|	,
	|	TTMaximumNumberOfEntries AS MaximumNumberOfRecords
	|INDEX BY
	|	RegisterName,
	|	AccountingObject
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
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
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
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
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
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
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
	|	CorrespondenceWithoutErrors.FinRecordID AS FinRecordID
	|INTO TTDocumentsReplacingReverseWithReverse
	|FROM
	|	TTCorrespondenceWithoutErrors AS CorrespondenceWithoutErrors
	|GROUP BY
	|	CorrespondenceWithoutErrors.Period,
	|	CorrespondenceWithoutErrors.Recorder,
	|	CorrespondenceWithoutErrors.FinRecordID,
	|	CorrespondenceWithoutErrors.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
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
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
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
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
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
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
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
	|	RegisteredRecordsWithoutErrors.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsWithoutErrors.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsWithoutErrors.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsWithoutErrors.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
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
	|	RegisteredRecordsWithoutErrors.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsWithoutErrors.MaturityDateCr AS MaturityDateCr,
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
	|	RegisteredRecordsWithoutErrors.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsWithoutErrors.PropsStornoCr AS PropsStornoCr,
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
	|	UNDEFINED AS Recorder
	|INTO TTDocumentsReplacingReverseWithReverse
	|WHERE
	|	FALSE
	|");
	
EndProcedure

#EndRegion

#Region TextsOfRequestsToRestorePaymentsForStorno

Procedure RestoreStornoCalculationsIfNecessary(Query, QueriesTexts)
	
	If Not Query.Parameters.RestoreCalculationsForStorno Then
		Return;
	EndIf;
	
	QueryText = "
	|SELECT
	|	&OrganizationField_ AS Organization,
	|	DocumentsRegistry.Ref AS DocumentReversingEntry,
	|	DocumentsRegistry.IBDocumentDate AS Period,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument
	|INTO TTRegisterOfDocumentsStorno
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Posted
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND &ConditionsForSelectionOfDocuments
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|		WHERE
	|			RegisteredRecordsDebitCredit.Period = DocumentsRegistry.IBDocumentDate
	|			AND RegisteredRecordsDebitCredit.Recorder = DocumentsRegistry.Ref
	|			AND RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			AND RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			AND &OrganizationSelectionCriteria
	|		)
	|INDEX BY
	|	DocumentReversingEntry,
	|	ReversedDocument
	|";
	
	ThereIsPortionOfDocuments = Query.TempTablesManager.Tables.Find("TTPortionOfDocuments") <> Undefined;
	
	If ThereIsPortionOfDocuments Then
		QueryText = StrReplace(QueryText,
			"InformationRegister.DocumentsRegistry AS DocumentsRegistry",
			"InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|	INNER JOIN TTPortionOfDocuments AS PortionOfDocuments
			|		ON BEGINOFPERIOD(DocumentsRegistry.IBDocumentDate, DAY) = PortionOfDocuments.DateRecord
			|		 AND DocumentsRegistry.Ref = PortionOfDocuments.Recorder");
		OrganizationSelectionField = "PortionOfDocuments.Organization";
		OrganizationSelectionCriteria = "RegisteredRecordsDebitCredit.Organization = PortionOfDocuments.Organization";
	Else
		OrganizationSelectionField = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.Companies.EmptyRef());
		OrganizationSelectionCriteria = "RegisteredRecordsDebitCredit.Organization = DocumentsRegistry.Organization";
	EndIf;
	
	LinesOfConditionsForSelectionOfDocuments = New Array();
	
	If Query.Parameters.StartDate > '00010101' Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.IBDocumentDate >= &StartDate");
	EndIf;
	
	If Query.Parameters.EndDate > '00010101' Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.IBDocumentDate <= &EndDate");
	EndIf;
	
	If TypeOf(Query.Parameters.Recorder) = Type("Array") Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.Ref IN (&Recorder)");
	ElsIf ValueIsFilled(Query.Parameters.Recorder) Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.Ref = &Recorder");
	EndIf;
	
	If LinesOfConditionsForSelectionOfDocuments.Count() > 0 Then
		LineSplitter = Chars.LF + Chars.Tab + "And ";
		ConditionsForSelectionOfDocuments = StrConcat(LinesOfConditionsForSelectionOfDocuments, LineSplitter);
	Else
		ConditionsForSelectionOfDocuments = "TRUE";
	EndIf;
		
	QueryText = StrReplace(QueryText, "&OrganizationField_", OrganizationSelectionField);
	QueryText = StrReplace(QueryText, "&ConditionsForSelectionOfDocuments", ConditionsForSelectionOfDocuments);
	QueryText = StrReplace(QueryText, "&OrganizationSelectionCriteria", OrganizationSelectionCriteria);
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
	QueriesTexts.Add(QueryText);
	
	If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTRegisterOfDocumentsStorno") Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterOfDocumentsStorno");
		Query.Parameters.RestoreCalculationsForStorno = False;
		Return;
	EndIf;
	
	#Region ReversePrepaymentFromCustomer
	
	QueryText = "
	|SELECT
	|	RegisterData.Period AS Period,
	|	""CustomersARAPAccountingByDueDates"" AS RegisterName,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.CustomersAccountsReceivable) AS AccountingObjectDr,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsFromCustomers) AS AccountingObjectCr,
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS SettingObject1,
	|	UNDEFINED AS PlaceOfRegistration,
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
	|	DATETIME(0001,01,01) AS MaturityDate,
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
	|		 AND &ConnectionConditionByOrganization
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
	|		 AND &ConnectionConditionByOrganization
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
	
	If ThereIsPortionOfDocuments Then
		ConnectionConditionByOrganization = "CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization";
	Else
		ConnectionConditionByOrganization = "TRUE";
	EndIf;
	
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
	ExistingSelectionFields.Add("BusinessTransactionSetting");
	
	SampleLinesOfOtherFields = New Array();
	LineSplitter = "," + Chars.LF + Chars.Tab;
	FieldsDetails = DescriptionOfFinancialRegisterFields(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
	
	For Each KeyAndValue In FieldsDetails Do
		DataPathParts = StrSplit(KeyAndValue.Value.DataPath, ".");
		CaseFieldName = DataPathParts[0];
		If ExistingSelectionFields.Find(CaseFieldName) = Undefined Then
			SampleLinesOfOtherFields.Add("UNDEFINED AS " + CaseFieldName);
			ExistingSelectionFields.Add(CaseFieldName);
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&OtherSelectionFields", StrConcat(SampleLinesOfOtherFields, LineSplitter));
	QueryText = StrReplace(QueryText, "&ConnectionConditionByOrganization", ConnectionConditionByOrganization);
	QueryText = StrReplace(QueryText, "&OrganizationSelectionCriteria", OrganizationSelectionCriteria);
	
	QueriesTexts.Add(QueryText);
	
	If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTSettlementsWithCustomersOnStorno") Then
		TMCommonUse.AddIDsToTemporaryTable(
			"TTSettlementsWithCustomersOnStorno",
			Query.TempTablesManager,
			"FinRecordID");
	EndIf;
	
	#EndRegion
	
	#Region ReversePrepaymentToVendor
	
	QueryText = "
	|SELECT
	|	RegisterData.Period AS Period,
	|	""VendorsARAPAccountingByDueDates"" AS RegisterName,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.PrepaymentsToVendors) AS AccountingObjectDr,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VendorAccountsReceivable) AS AccountingObjectCr,
	|	RegisterData.ARAPObject.FinancialAccountingGroup AS SettingObject1,
	|	UNDEFINED AS PlaceOfRegistration,
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
	|	DATETIME(0001,01,01) AS MaturityDate,
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
	|		 AND &ConnectionConditionByOrganization
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
	|		 AND &ConnectionConditionByOrganization
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
	
	If ThereIsPortionOfDocuments Then
		ConnectionConditionByOrganization = "VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization";
	Else
		ConnectionConditionByOrganization = "TRUE";
	EndIf;
	
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
	ExistingSelectionFields.Add("BusinessTransactionSetting");
	
	SampleLinesOfOtherFields = New Array();
	LineSplitter = "," + Chars.LF + Chars.Tab;
	FieldsDetails = DescriptionOfFinancialRegisterFields(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
	
	For Each KeyAndValue In FieldsDetails Do
		DataPathParts = StrSplit(KeyAndValue.Value.DataPath, ".");
		CaseFieldName = DataPathParts[0];
		If ExistingSelectionFields.Find(CaseFieldName) = Undefined Then
			SampleLinesOfOtherFields.Add("UNDEFINED AS " + CaseFieldName);
			ExistingSelectionFields.Add(CaseFieldName);
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&OtherSelectionFields", StrConcat(SampleLinesOfOtherFields, LineSplitter));
	QueryText = StrReplace(QueryText, "&ConnectionConditionByOrganization", ConnectionConditionByOrganization);
	QueryText = StrReplace(QueryText, "&OrganizationSelectionCriteria", OrganizationSelectionCriteria);
	
	QueriesTexts.Add(QueryText);
	
	If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTSettlementsWithSuppliersOnStorno") Then
		TMCommonUse.AddIDsToTemporaryTable(
			"TTSettlementsWithSuppliersOnStorno",
			Query.TempTablesManager,
			"FinRecordID");
	EndIf;
	
	#EndRegion
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterOfDocumentsStorno");
	
EndProcedure

Procedure AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterName)
	
	QueryText = "
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.AccountingObjectDr AS AccountingObject,
	|	RegisterTable.SettingObject1 AS SettingObject1,
	|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
	|	RegisterTable.MaturityDate AS MaturityDate,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.SumManDr AS SumMan,
	|	RegisterTable.SumComplDr AS SumCompl,
	|	RegisterTable.SumCurrDr AS SumCurr,
	|	0 AS Count
	|FROM
	|	&DataSource AS RegisterTable
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.AccountingObjectCr AS AccountingObject,
	|	RegisterTable.SettingObject1 AS SettingObject1,
	|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
	|	RegisterTable.MaturityDate AS MaturityDate,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.SumManCr AS SumMan,
	|	RegisterTable.SumComplCr AS SumCompl,
	|	RegisterTable.SumCurrCr AS SumCurr,
	|	0 AS Count
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

#Region TextsOfRequestsForDeterminingAccountingAccountsByObject

Procedure AddTableOfTransactionGenerationSettings(Query, QueriesTexts)
	
	If Query.TempTablesManager.Tables.Find("DocumentsToBeReflected") = Undefined Then
		QueryText = "
		|SELECT
		|	FinancialAccountingChartsOfAccountsForCompanies.Period AS Period,
		|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts AS ChartOfAccounts,
		|	FinancialAccountingChartsOfAccountsForCompanies.Organization AS Organization,
		|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting AS PostingGenerationSetting
		|INTO TTAccountPlanTransactionSettings
		|FROM
		|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
		|WHERE
		|	&ChartOfAccountsCondition
		|INDEX BY
		|	Period,
		|	Organization,
		|	ChartOfAccounts
		|";
		
		QueryText = StrReplace(QueryText, "&ChartOfAccountsCondition", ConditionsLineChartOfAccounts(Query.Parameters));
		QueryText = StrReplace(QueryText, "&ChartOfAccounts", "FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts");
		QueryText = StrReplace(QueryText, "&RequestParameterChartOfAccounts", "&ChartOfAccounts");
		
		QueriesTexts.Add(QueryText);
		
		QueriesTexts.Add("
		|SELECT
		|	BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) AS Period,
		|	RegisteredRecordsDebitCredit.Organization AS Organization,
		|	ISNULL(AccountPlanTransactionSettings.ChartOfAccounts, VALUE(Catalog.FinancialAccountingChartsOfAccounts.EmptyRef)) AS ChartOfAccounts,
		|	MAX(AccountPlanTransactionSettings.Period) AS TransactionSetupPeriod
		|INTO TTPeriodsOfEntriesSettings
		|FROM
		|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
		|	LEFT JOIN TTAccountPlanTransactionSettings AS AccountPlanTransactionSettings
		|		ON RegisteredRecordsDebitCredit.Period >= AccountPlanTransactionSettings.Period
		|		 AND RegisteredRecordsDebitCredit.Organization = AccountPlanTransactionSettings.Organization
		|GROUP BY
		|	BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY),
		|	RegisteredRecordsDebitCredit.Organization,
		|	ISNULL(AccountPlanTransactionSettings.ChartOfAccounts, VALUE(Catalog.FinancialAccountingChartsOfAccounts.EmptyRef))
		|INDEX BY
		|	TransactionSetupPeriod,
		|	Organization,
		|	ChartOfAccounts
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	TransactionSettingsPeriods.Period AS Period,
		|	TransactionSettingsPeriods.Organization AS Organization,
		|	TransactionSettingsPeriods.ChartOfAccounts AS ChartOfAccounts,
		|	ISNULL(TransactionSettingsPeriods.ChartOfAccounts.MethodOfNotOwnedControlledValuesAccounting, VALUE(Enum.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts)) AS MethodOfAccountingForImproperValues,
		|	ISNULL(AccountPlanTransactionSettings.PostingGenerationSetting, VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)) AS PostingGenerationSetting,
		|	ISNULL(AccountPlanTransactionSettings.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities, FALSE) AS AllocationOfLongTermAssetsAndLiabilities,
		|	ISNULL(AccountPlanTransactionSettings.PostingGenerationSetting.RevenueTransactionsExcludingVAT, FALSE) AS RevenueExcludingVAT
		|INTO TTSettingsForTransactionsByPeriod
		|FROM
		|	TTPeriodsOfEntriesSettings AS TransactionSettingsPeriods
		|	LEFT JOIN TTAccountPlanTransactionSettings AS AccountPlanTransactionSettings
		|		ON TransactionSettingsPeriods.TransactionSetupPeriod = AccountPlanTransactionSettings.Period
		|		 AND TransactionSettingsPeriods.Organization = AccountPlanTransactionSettings.Organization
		|		 AND TransactionSettingsPeriods.ChartOfAccounts = AccountPlanTransactionSettings.ChartOfAccounts
		|GROUP BY
		|	TransactionSettingsPeriods.Period,
		|	TransactionSettingsPeriods.Organization,
		|	TransactionSettingsPeriods.ChartOfAccounts,
		|	AccountPlanTransactionSettings.PostingGenerationSetting
		|INDEX BY
		|	Period,
		|	Organization,
		|	ChartOfAccounts,
		|	PostingGenerationSetting
		|");
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAccountPlanTransactionSettings");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTPeriodsOfEntriesSettings");
	Else
		QueriesTexts.Add("
		|SELECT
		|	DocumentsToBeReflected.DateRecord AS Period,
		|	DocumentsToBeReflected.Organization AS Organization,
		|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentsToBeReflected.ChartOfAccounts.MethodOfNotOwnedControlledValuesAccounting AS MethodOfAccountingForImproperValues,
		|	DocumentsToBeReflected.PostingGenerationSetting AS PostingGenerationSetting,
		|	DocumentsToBeReflected.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities AS AllocationOfLongTermAssetsAndLiabilities,
		|	DocumentsToBeReflected.PostingGenerationSetting.RevenueTransactionsExcludingVAT AS RevenueExcludingVAT
		|INTO TTSettingsForTransactionsByPeriod
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected
		|GROUP BY
		|	DocumentsToBeReflected.DateRecord,
		|	DocumentsToBeReflected.Organization,
		|	DocumentsToBeReflected.ChartOfAccounts,
		|	DocumentsToBeReflected.PostingGenerationSetting
		|INDEX BY
		|	Period,
		|	Organization,
		|	ChartOfAccounts,
		|	PostingGenerationSetting
		|");
	EndIf;
	
EndProcedure

Procedure AddTableOfAccountingPoliciesForFinancialAccounting(Query, QueriesTexts)
	
	If Query.Parameters.AllocationOfLongTermAssetsAndLiabilities Then
		QueriesTexts.Add("
		|SELECT
		|	FinancialAccountingPolicy.Period AS Period,
		|	FinancialAccountingPolicy.Organization AS Organization,
		|	FinancialAccountingPolicy.DurationOfCompanyOperatingCycle AS DurationOfCompanyOperatingCycle
		|INTO TTAccountingPolicy
		|FROM
		|	InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
		|INDEX BY
		|	Period,
		|	Organization
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) AS Period,
		|	RegisteredRecordsDebitCredit.Organization AS Organization,
		|	MAX(AccountingPolicy.Period) AS AccountingPolicyPeriod
		|INTO TTAccountingPolicyPeriods
		|FROM
		|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
		|	LEFT JOIN TTAccountingPolicy AS AccountingPolicy
		|		ON RegisteredRecordsDebitCredit.Period >= AccountingPolicy.Period
		|		 AND RegisteredRecordsDebitCredit.Organization = AccountingPolicy.Organization
		|GROUP BY
		|	BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY),
		|	RegisteredRecordsDebitCredit.Organization
		|INDEX BY
		|	AccountingPolicyPeriod,
		|	Organization
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	AccountingPolicyPeriods.Period AS Period,
		|	AccountingPolicyPeriods.Organization AS Organization,
		|	ISNULL(AccountingPolicy.DurationOfCompanyOperatingCycle, 0) AS DurationOfCompanyOperatingCycle
		|INTO TTAccountingPolicyForPeriods
		|FROM
		|	TTAccountingPolicyPeriods AS AccountingPolicyPeriods
		|	LEFT JOIN TTAccountingPolicy AS AccountingPolicy
		|		ON AccountingPolicyPeriods.AccountingPolicyPeriod = AccountingPolicy.Period
		|		 AND AccountingPolicyPeriods.Organization = AccountingPolicy.Organization
		|GROUP BY
		|	AccountingPolicyPeriods.Period,
		|	AccountingPolicyPeriods.Organization,
		|	ISNULL(AccountingPolicy.DurationOfCompanyOperatingCycle, 0)
		|INDEX BY
		|	Period,
		|	Organization
		|");
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAccountingPolicy");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAccountingPolicyPeriods");
	Else
		QueriesTexts.Add("
		|SELECT
		|	DATETIME(0001,01,01) AS Period,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	0 AS DurationOfCompanyOperatingCycle
		|INTO TTAccountingPolicyForPeriods
		|WHERE
		|	FALSE
		|");
	EndIf;
	
EndProcedure

Procedure AddTableOfAccountingSettingsForOtherOfOperations(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsDebitCredit.RecNo AS RecNo,
	|	OtherAssetsLiabilities.DebitCredit AS DebitCredit,
	|	FinancialAccountingSettings.ChartOfAccounts AS ChartOfAccounts,
	|	MAX(FinancialAccountingSettings.Ref) AS GLAccountSettings
	|INTO TTSettingsOfOperations
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|	INNER JOIN AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsLiabilities
	|		ON RegisteredRecordsDebitCredit.Period = OtherAssetsLiabilities.Period
	|		 AND RegisteredRecordsDebitCredit.Recorder = OtherAssetsLiabilities.Recorder
	|		 AND RegisteredRecordsDebitCredit.FinRecordID = OtherAssetsLiabilities.FinRecordID
	|		 AND RegisteredRecordsDebitCredit.SettingUpBusinessTransaction = OtherAssetsLiabilities.BusinessTransactionSetting
	|		 AND RegisteredRecordsDebitCredit.Organization = OtherAssetsLiabilities.Organization
	|	INNER JOIN Catalog.OtherTransactionsGLAccountsSettings.FinancialAccountingSettings AS FinancialAccountingSettings
	|		ON OtherAssetsLiabilities.GLAccountSettings = FinancialAccountingSettings.Ref
	|WHERE
	|	(RegisteredRecordsDebitCredit.RegisterNameDr = &RegisterNameOtherAssetsLiabilities
	|		AND VALUETYPE(RegisteredRecordsDebitCredit.SettingObject1Dr) <> TYPE(Catalog.OtherTransactionsGLAccountsSettings))
	|	OR
	|	(RegisteredRecordsDebitCredit.RegisterNameCr = &RegisterNameOtherAssetsLiabilities
	|		AND VALUETYPE(RegisteredRecordsDebitCredit.SettingObject1Cr) <> TYPE(Catalog.OtherTransactionsGLAccountsSettings))
	|GROUP BY
	|	RegisteredRecordsDebitCredit.RecNo,
	|	OtherAssetsLiabilities.DebitCredit,
	|	FinancialAccountingSettings.ChartOfAccounts
	|INDEX BY
	|	RecNo,
	|	ChartOfAccounts,
	|	DebitCredit
	|");
	
EndProcedure

#EndRegion

#Region TextsOfCorrespondenceAnalyticsRequests

Function TextOfAnalysisSelectionFromNestedTable()
	
	QueryText = "
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.AccountingObject AS AccountingObject,
	|	RegisterTable.SettingObject1 AS SettingObject1,
	|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
	|	RegisterTable.MaturityDate AS MaturityDate,
	|	RegisterTable.Currency AS Currency,
	|	SUM(RegisterTable.SumMan) AS SumMan,
	|	SUM(RegisterTable.SumCompl) AS SumCompl,
	|	SUM(RegisterTable.SumCurr) AS SumCurr,
	|	SUM(RegisterTable.Count) AS Count
	|FROM
	|	(SELECT
	|		RegisterTable.Period AS Period,
	|		RegisterTable.RegisterName AS RegisterName,
	|		RegisterTable.AccountingObject AS AccountingObject,
	|		RegisterTable.SettingObject1 AS SettingObject1,
	|		RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
	|		RegisterTable.MaturityDate AS MaturityDate,
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
	|		END AS Count
	|	FROM
	|		&DataSource AS RegisterTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterTable.Period AS Period,
	|		RegisterTable.RegisterName AS RegisterName,
	|		RegisterTable.AccountingObject AS AccountingObject,
	|		RegisterTable.SettingObject1 AS SettingObject1,
	|		RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
	|		RegisterTable.MaturityDate AS MaturityDate,
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
	|		END AS Count
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
	|	RegisterTable.SettingObject1,
	|	RegisterTable.PlaceOfRegistration,
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
	|	RegisterTable.MaturityDate,
	|	RegisterTable.Currency
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
		|	RegisterTable.SettingObject1 AS SettingObject1,
		|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
		|	RegisterTable.MaturityDate AS MaturityDate,
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
		|	END) AS Count
		|FROM
		|	&DataSource AS RegisterTable
		|	LEFT JOIN TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
		|		ON RegisterTable.Period = ReverseReplacementDocuments.Period
		|		 AND RegisterTable.Recorder = ReverseReplacementDocuments.Recorder
		|		 AND RegisterTable.FinRecordID = ReverseReplacementDocuments.FinRecordID
		|		 AND RegisterTable.Organization = ReverseReplacementDocuments.Organization
		|GROUP BY
		|	RegisterTable.Period,
		|	RegisterTable.RegisterName,
		|	RegisterTable.AccountingObject,
		|	RegisterTable.SettingObject1,
		|	RegisterTable.PlaceOfRegistration,
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
		|	RegisterTable.MaturityDate,
		|	RegisterTable.Currency
		|";
	Else
		QueryText = "
		|SELECT
		|	RegisterTable.Period AS Period,
		|	RegisterTable.RegisterName AS RegisterName,
		|	RegisterTable.AccountingObject AS AccountingObject,
		|	RegisterTable.SettingObject1 AS SettingObject1,
		|	RegisterTable.PlaceOfRegistration AS PlaceOfRegistration,
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
		|	RegisterTable.MaturityDate AS MaturityDate,
		|	RegisterTable.Currency AS Currency,
		|	RegisterTable.SumMan AS SumMan,
		|	RegisterTable.SumCompl AS SumCompl,
		|	RegisterTable.SumCurr AS SumCurr,
		|	RegisterTable.Count AS Count
		|FROM
		|	&DataSource AS RegisterTable
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForVariantsOfReportAnalysisOfTransactionsOfOperationalAccounting

Function QueryTextCorrespondenceErrorAnalysis(QueryOptions)
	
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	VALUE(Catalog.FinancialAccountingChartsOfAccounts.EmptyRef) AS ChartOfAccounts,
	|	VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef) AS PostingGenerationSetting,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountDr,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountCr,
	|	FALSE AS LongTermDr,
	|	FALSE AS LongTermCr,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.RegisterNameCr
	|		ELSE RegisteredRecordsDebitCredit.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.RegisterNameDr
	|		ELSE RegisteredRecordsDebitCredit.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.AccountingObjectCr
	|		ELSE RegisteredRecordsDebitCredit.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.AccountingObjectDr
	|		ELSE RegisteredRecordsDebitCredit.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.SettingObject1Cr
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Dr
	|	END AS SettingObject1Dr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.SettingObject1Dr
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Cr
	|	END AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.CurrencyCr
	|		ELSE RegisteredRecordsDebitCredit.CurrencyDr
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.CurrencyDr
	|		ELSE RegisteredRecordsDebitCredit.CurrencyCr
	|	END AS CurrencyCr,
	|	VALUE(Enum.StatusesOfPostingsInFinancialAccounting.EmptyRef) AS ReflectionStatus,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumManCr
	|		ELSE RegisteredRecordsDebitCredit.SumManDr
	|	END AS SumManDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumManDr
	|		ELSE RegisteredRecordsDebitCredit.SumManCr
	|	END AS SumManCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumComplCr
	|		ELSE RegisteredRecordsDebitCredit.SumComplDr
	|	END AS SumComplDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumComplDr
	|		ELSE RegisteredRecordsDebitCredit.SumComplCr
	|	END AS SumComplCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumCurrCr
	|		ELSE RegisteredRecordsDebitCredit.SumCurrDr
	|	END AS SumCurrDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumCurrDr
	|		ELSE RegisteredRecordsDebitCredit.SumCurrCr
	|	END AS SumCurrCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.CountCr
	|		ELSE RegisteredRecordsDebitCredit.CountDr
	|	END AS CountDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.CountDr
	|		ELSE RegisteredRecordsDebitCredit.CountCr
	|	END AS CountCr
	|INTO TTSetOfRegisteredRecords
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|WHERE
	|	&ConditionNotReflectedInAccounting
	|";
	
	If QueryOptions.NotReflectedInAccounting = True Then
		ConditionNotReflectedInAccounting = "TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
		|		WHERE
		|			ReflectionStatuses.Organization = RegisteredRecordsDebitCredit.Organization
		|			AND ReflectionStatuses.Recorder = RegisteredRecordsDebitCredit.Recorder
		|			AND BEGINOFPERIOD(ReflectionStatuses.DateRecord, DAY) = BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY)
		|			AND NOT ReflectionStatuses.Status IN (
		|				VALUE(Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting),
		|				VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting)
		|			)
		|		)
		|";
	Else
		ConditionNotReflectedInAccounting = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionNotReflectedInAccounting", ConditionNotReflectedInAccounting);
	QueryText = StrReplace(QueryText, "RegisteredRecordsDebitCredit.InvertEntriy",
		"RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr OR RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr");
	
	Return QueryText;
	
EndFunction

Function RequestTextFullCorrespondenceAnalysis()
		
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisteredRecordsWithAccounts.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsWithAccounts.PostingGenerationSetting AS PostingGenerationSetting,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.GLAccountCr
	|		ELSE RegisteredRecordsWithAccounts.GLAccountDr
	|	END AS GLAccountDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.GLAccountDr
	|		ELSE RegisteredRecordsWithAccounts.GLAccountCr
	|	END AS GLAccountCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.LongTermCr
	|		ELSE RegisteredRecordsWithAccounts.LongTermDr
	|	END AS LongTermDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.LongTermDr
	|		ELSE RegisteredRecordsWithAccounts.LongTermCr
	|	END AS LongTermCr,
	|	RegisteredRecordsWithAccounts.Period AS Period,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.RegisterNameCr
	|		ELSE RegisteredRecordsWithAccounts.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.RegisterNameDr
	|		ELSE RegisteredRecordsWithAccounts.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.AccountingObjectCr
	|		ELSE RegisteredRecordsWithAccounts.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.AccountingObjectDr
	|		ELSE RegisteredRecordsWithAccounts.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.SettingObject1Cr
	|		ELSE RegisteredRecordsWithAccounts.SettingObject1Dr
	|	END AS SettingObject1Dr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.SettingObject1Dr
	|		ELSE RegisteredRecordsWithAccounts.SettingObject1Cr
	|	END AS SettingObject1Cr,
	|	RegisteredRecordsWithAccounts.Organization AS Organization,
	|	RegisteredRecordsWithAccounts.Recorder AS Recorder,
	|	RegisteredRecordsWithAccounts.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithAccounts.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.CurrencyCr
	|		ELSE RegisteredRecordsWithAccounts.CurrencyDr
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN RegisteredRecordsWithAccounts.CurrencyDr
	|		ELSE RegisteredRecordsWithAccounts.CurrencyCr
	|	END AS CurrencyCr,
	|	ISNULL(ReflectionStatuses.Status, VALUE(Enum.StatusesOfPostingsInFinancialAccounting.EmptyRef)) AS ReflectionStatus,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.SumManCr
	|		ELSE RegisteredRecordsWithAccounts.SumManDr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS SumManDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.SumManDr
	|		ELSE RegisteredRecordsWithAccounts.SumManCr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS SumManCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.SumComplCr
	|		ELSE RegisteredRecordsWithAccounts.SumComplDr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS SumComplDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.SumComplDr
	|		ELSE RegisteredRecordsWithAccounts.SumComplCr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS SumComplCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.SumCurrCr
	|		ELSE RegisteredRecordsWithAccounts.SumCurrDr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS SumCurrDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.SumCurrDr
	|		ELSE RegisteredRecordsWithAccounts.SumCurrCr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS SumCurrCr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.CountCr
	|		ELSE RegisteredRecordsWithAccounts.CountDr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS CountDr,
	|	CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertEntriy
	|			THEN -RegisteredRecordsWithAccounts.CountDr
	|		ELSE RegisteredRecordsWithAccounts.CountCr
	|	END * CASE
	|		WHEN RegisteredRecordsWithAccounts.InvertTheResourceSign
	|			THEN -1
	|		ELSE 1
	|	END AS CountCr
	|INTO TTSetOfRegisteredRecords
	|FROM
	|	TTMovementWithAccounts AS RegisteredRecordsWithAccounts
	|	LEFT JOIN InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|		ON RegisteredRecordsWithAccounts.ChartOfAccounts = ReflectionStatuses.ChartOfAccounts
	|		 AND RegisteredRecordsWithAccounts.Organization = ReflectionStatuses.Organization
	|		 AND RegisteredRecordsWithAccounts.Recorder = ReflectionStatuses.Recorder
	|		 AND BEGINOFPERIOD(RegisteredRecordsWithAccounts.Period, DAY) = BEGINOFPERIOD(ReflectionStatuses.DateRecord, DAY)
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForReportVariantsAnalysisOfOperationalAccountingCorrespondence

Function RequestTextAnalysisOfCorrespondenceForConfiguration()
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsDebitCredit.PostingGenerationSetting AS PostingGenerationSetting,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountDr,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.LongTermCr
	|		ELSE RegisteredRecordsDebitCredit.LongTermDr
	|	END AS LongTermDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.LongTermDr
	|		ELSE RegisteredRecordsDebitCredit.LongTermCr
	|	END AS LongTermCr,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.RegisterNameCr
	|		ELSE RegisteredRecordsDebitCredit.RegisterNameDr
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.RegisterNameDr
	|		ELSE RegisteredRecordsDebitCredit.RegisterNameCr
	|	END AS RegisterNameCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.AccountingObjectCr
	|		ELSE RegisteredRecordsDebitCredit.AccountingObjectDr
	|	END AS AccountingObjectDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.AccountingObjectDr
	|		ELSE RegisteredRecordsDebitCredit.AccountingObjectCr
	|	END AS AccountingObjectCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.SettingObject1Cr
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Dr
	|	END AS SettingObject1Dr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.SettingObject1Dr
	|		ELSE RegisteredRecordsDebitCredit.SettingObject1Cr
	|	END AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.CurrencyCr
	|		ELSE RegisteredRecordsDebitCredit.CurrencyDr
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN RegisteredRecordsDebitCredit.CurrencyDr
	|		ELSE RegisteredRecordsDebitCredit.CurrencyCr
	|	END AS CurrencyCr,
	|	ISNULL(ReflectionStatuses.Status, VALUE(Enum.StatusesOfPostingsInFinancialAccounting.EmptyRef)) AS ReflectionStatus,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumManCr
	|		ELSE RegisteredRecordsDebitCredit.SumManDr
	|	END AS SumManDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumManDr
	|		ELSE RegisteredRecordsDebitCredit.SumManCr
	|	END AS SumManCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumComplCr
	|		ELSE RegisteredRecordsDebitCredit.SumComplDr
	|	END AS SumComplDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumComplDr
	|		ELSE RegisteredRecordsDebitCredit.SumComplCr
	|	END AS SumComplCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumCurrCr
	|		ELSE RegisteredRecordsDebitCredit.SumCurrDr
	|	END AS SumCurrDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.SumCurrDr
	|		ELSE RegisteredRecordsDebitCredit.SumCurrCr
	|	END AS SumCurrCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.CountCr
	|		ELSE RegisteredRecordsDebitCredit.CountDr
	|	END AS CountDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.InvertEntriy
	|			THEN -RegisteredRecordsDebitCredit.CountDr
	|		ELSE RegisteredRecordsDebitCredit.CountCr
	|	END AS CountCr
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsDebitCredit
	|	LEFT JOIN InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|		ON RegisteredRecordsDebitCredit.ChartOfAccounts = ReflectionStatuses.ChartOfAccounts
	|		 AND RegisteredRecordsDebitCredit.Organization = ReflectionStatuses.Organization
	|		 AND RegisteredRecordsDebitCredit.Recorder = ReflectionStatuses.Recorder
	|		 AND BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) = BEGINOFPERIOD(ReflectionStatuses.DateRecord, DAY)
	|WHERE
	|	RegisteredRecordsDebitCredit.AccountingObjectDr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|	AND RegisteredRecordsDebitCredit.AccountingObjectCr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|";
	
	QueryText = StrReplace(QueryText,
		"RegisteredRecordsDebitCredit.InvertEntriy",
		"CASE
		|		WHEN RegisteredRecordsDebitCredit.PostingGenerationSetting.MethodOfCancelingTransactions
		|		= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
		|			THEN RegisteredRecordsDebitCredit.SumManDr < 0
		|			  OR RegisteredRecordsDebitCredit.SumManCr < 0
		|			  OR RegisteredRecordsDebitCredit.SumComplDr < 0
		|			  OR RegisteredRecordsDebitCredit.SumComplCr < 0
		|			  OR RegisteredRecordsDebitCredit.SumCurrDr < 0
		|			  OR RegisteredRecordsDebitCredit.SumCurrCr < 0
		|			  OR RegisteredRecordsDebitCredit.CountDr < 0
		|			  OR RegisteredRecordsDebitCredit.CountCr < 0
		|		ELSE RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr OR RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr
		|	END");
	
	Return QueryText;
	
EndFunction

// The procedure generates a request for a correspondence report,
// which is reflected using the correspondence settings with the set selection
// 
// Parameters:
//  Query - Query - request for a correspondence report
//  QueriesTexts - Array of String - array of query texts
//  RegisterRequestsTexts - Structure of KeyAndValue - LongDesc:
//   * Key - String - name of the financial register
//   * Value - String - the text of the financial register data sampling request
//  AdditionalSelection - DataCompositionFilter - selection set in the correspondence reflection setting
//
Procedure PrepareCorrespondenceAnalysisRequestForConfigurationWithSelection(Query, QueriesTexts, RegisterRequestsTexts, AdditionalSelection)
	
	FilterFieldsDr = New Array();
	FilterFieldsCr = New Array();
	
	FinancialAccountingByBalanceSheetRegisterData.AddSelectionElementFields(FilterFieldsDr, AdditionalSelection, "Dr");
	FinancialAccountingByBalanceSheetRegisterData.AddSelectionElementFields(FilterFieldsCr, AdditionalSelection, "Cr");
	
	QueriesTexts.Add("
	|SELECT
	|	RegisteredRecordsDebitCredit.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsDebitCredit.PostingGenerationSetting AS PostingGenerationSetting,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountDr,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountCr,
	|	RegisteredRecordsDebitCredit.LongTermDr AS LongTermDr,
	|	RegisteredRecordsDebitCredit.LongTermCr AS LongTermCr,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	FALSE AS InvertEntriy,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.SourceConfigurationObjectDr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsDebitCredit.SourceConfigurationObjectCr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateCr,
	|	ISNULL(ReflectionStatuses.Status, VALUE(Enum.StatusesOfPostingsInFinancialAccounting.EmptyRef)) AS ReflectionStatus,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.SumCurrDr AS SumCurrDr,
	|	RegisteredRecordsDebitCredit.SumCurrCr AS SumCurrCr,
	|	RegisteredRecordsDebitCredit.CountDr AS CountDr,
	|	RegisteredRecordsDebitCredit.CountCr AS CountCr
	|INTO TTRpmForSetting
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsDebitCredit
	|	LEFT JOIN InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|		ON RegisteredRecordsDebitCredit.ChartOfAccounts = ReflectionStatuses.ChartOfAccounts
	|		 AND RegisteredRecordsDebitCredit.Organization = ReflectionStatuses.Organization
	|		 AND RegisteredRecordsDebitCredit.Recorder = ReflectionStatuses.Recorder
	|		 AND BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) = BEGINOFPERIOD(ReflectionStatuses.DateRecord, DAY)
	|WHERE
	|	NOT CASE
	|		WHEN RegisteredRecordsDebitCredit.PostingGenerationSetting.MethodOfCancelingTransactions
	|		= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|			THEN RegisteredRecordsDebitCredit.SumManDr < 0
	|			  OR RegisteredRecordsDebitCredit.SumManCr < 0
	|			  OR RegisteredRecordsDebitCredit.SumComplDr < 0
	|			  OR RegisteredRecordsDebitCredit.SumComplCr < 0
	|			  OR RegisteredRecordsDebitCredit.SumCurrDr < 0
	|			  OR RegisteredRecordsDebitCredit.SumCurrCr < 0
	|			  OR RegisteredRecordsDebitCredit.CountDr < 0
	|			  OR RegisteredRecordsDebitCredit.CountCr < 0
	|		ELSE RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr OR RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	RegisteredRecordsDebitCredit.ChartOfAccounts AS ChartOfAccounts,
	|	RegisteredRecordsDebitCredit.PostingGenerationSetting AS PostingGenerationSetting,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountDr,
	|	VALUE(ChartOfAccounts.International.EmptyRef) AS GLAccountCr,
	|	RegisteredRecordsDebitCredit.LongTermCr AS LongTermDr,
	|	RegisteredRecordsDebitCredit.LongTermDr AS LongTermCr,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.AccountingObjectCr AS AccountingObjectDr,
	|	RegisteredRecordsDebitCredit.AccountingObjectDr AS AccountingObjectCr,
	|	RegisteredRecordsDebitCredit.SettingObject1Cr AS SettingObject1Dr,
	|	RegisteredRecordsDebitCredit.SettingObject1Dr AS SettingObject1Cr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationCr AS PlaceOfRegistrationDr,
	|	RegisteredRecordsDebitCredit.PlaceOfRegistrationDr AS PlaceOfRegistrationCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionCr,
	|	TRUE AS InvertEntriy,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.SourceConfigurationObjectCr AS SourceConfigurationObjectDr,
	|	RegisteredRecordsDebitCredit.SourceConfigurationObjectDr AS SourceConfigurationObjectCr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.MaturityDateCr AS MaturityDateDr,
	|	RegisteredRecordsDebitCredit.MaturityDateDr AS MaturityDateCr,
	|	ISNULL(ReflectionStatuses.Status, VALUE(Enum.StatusesOfPostingsInFinancialAccounting.EmptyRef)) AS ReflectionStatus,
	|	-RegisteredRecordsDebitCredit.SumManCr AS SumManDr,
	|	-RegisteredRecordsDebitCredit.SumManDr AS SumManCr,
	|	-RegisteredRecordsDebitCredit.SumComplCr AS SumComplDr,
	|	-RegisteredRecordsDebitCredit.SumComplDr AS SumComplCr,
	|	-RegisteredRecordsDebitCredit.SumCurrCr AS SumCurrDr,
	|	-RegisteredRecordsDebitCredit.SumCurrDr AS SumCurrCr,
	|	-RegisteredRecordsDebitCredit.CountCr AS CountDr,
	|	-RegisteredRecordsDebitCredit.CountDr AS CountCr
	|FROM
	|	TTMovementWithDebitCreditAccounts AS RegisteredRecordsDebitCredit
	|	LEFT JOIN InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|		ON RegisteredRecordsDebitCredit.ChartOfAccounts = ReflectionStatuses.ChartOfAccounts
	|		 AND RegisteredRecordsDebitCredit.Organization = ReflectionStatuses.Organization
	|		 AND RegisteredRecordsDebitCredit.Recorder = ReflectionStatuses.Recorder
	|		 AND BEGINOFPERIOD(RegisteredRecordsDebitCredit.Period, DAY) = BEGINOFPERIOD(ReflectionStatuses.DateRecord, DAY)
	|WHERE
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.PostingGenerationSetting.MethodOfCancelingTransactions
	|		= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|			THEN RegisteredRecordsDebitCredit.SumManDr < 0
	|			  OR RegisteredRecordsDebitCredit.SumManCr < 0
	|			  OR RegisteredRecordsDebitCredit.SumComplDr < 0
	|			  OR RegisteredRecordsDebitCredit.SumComplCr < 0
	|			  OR RegisteredRecordsDebitCredit.SumCurrDr < 0
	|			  OR RegisteredRecordsDebitCredit.SumCurrCr < 0
	|			  OR RegisteredRecordsDebitCredit.CountDr < 0
	|			  OR RegisteredRecordsDebitCredit.CountCr < 0
	|		ELSE RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr OR RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr
	|	END
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
	|	SourceConfigurationObjectDr,
	|	SourceConfigurationObjectCr,
	|	PlaceOfRegistrationDr,
	|	PlaceOfRegistrationCr,
	|	MaturityDateDr,
	|	MaturityDateCr,
	|	Organization,
	|	SettingUpBusinessTransaction
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementWithDebitCreditAccounts");
	
	QueryText = "
	|SELECT
	|	RevolutionsForTuning.RegisterNameDr AS RegisterNameDr,
	|	RevolutionsForTuning.RegisterNameCr AS RegisterNameCr
	|FROM
	|	TTRpmForSetting AS RevolutionsForTuning
	|WHERE
	|	&ConditionObjectOfAccountingDr
	|	AND &ConditionCrAccountingObject
	|GROUP BY
	|	RevolutionsForTuning.RegisterNameDr,
	|	RevolutionsForTuning.RegisterNameCr
	|";
	
	QueryText = StrReplace(QueryText,
		"&ConditionObjectOfAccountingDr",
		ConditionLineAccountingObject(Query.Parameters, "Dr", "RevolutionsForTuning", True));
	QueryText = StrReplace(QueryText,
		"&ConditionCrAccountingObject",
		ConditionLineAccountingObject(Query.Parameters, "Cr", "RevolutionsForTuning", True));
	
	QueriesTexts.Add(QueryText);
	
	QueriesTexts.Add("
	|SELECT
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN RevolutionsForTuning.RegisterNameDr
	|		ELSE RevolutionsForTuning.RegisterNameCr
	|	END AS RegisterName
	|FROM
	|	TTRpmForSetting AS RevolutionsForTuning
	|	,
	|	(SELECT
	|		&Dr AS DrCr
	|	UNION ALL
	|	SELECT
	|		&Cr AS DrCr
	|	) AS PartsOfDoubleEntry
	|GROUP BY
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN RevolutionsForTuning.RegisterNameDr
	|		ELSE RevolutionsForTuning.RegisterNameCr
	|	END
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	ResultRegisterRotations = Results[Results.UBound() - 1];
	ResultRegisterNames = Results[Results.UBound()];
	
	SamplingRegisterRevolutions = ResultRegisterRotations.Select();
	FetchingRegisterName = ResultRegisterNames.Select();
	
	SelectionFieldsToDelete = DeletedFieldsForSelectingMotionAnalyticsQueries();
	IndexingFields = IndexFieldsOfIndividualCorrespondenceTables();
	ReverseIndexFields = IndexFieldsOfTablesReplacingReverseWithReverse();
	RegistersOfRecoveryOfCalculationsOnStorno = FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno();

	AvailableRegisterFields_ = New Structure();
	
	While FetchingRegisterName.Next() Do
		RegisterTableName = FetchingRegisterName.RegisterName;
		
		If IsBlankString(RegisterTableName)
		 Or RegisterTableName = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			Continue;
		EndIf;
		
		RowsOfAnalyticsFields = New Array();
		RowsOfAnalyticsGroups = New Array();
		AvailableRegisterFields = New Array();
		
		AddAvailableRegisterFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups,
			AvailableRegisterFields, RegisterTableName);
		
		RegisterRequestText = RegisterRequestsTexts[RegisterTableName];
		FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
			RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
		
		StornoReplacementWithReverseIsRequired = Query.Parameters.RegistersAreReplacedStornoByReverse.Find(RegisterTableName) <> Undefined;
		ReverseEntryNeedsToBeReplacedStorno = Query.Parameters.ReverseToReverseReplacementRegisters.Find(RegisterTableName) <> Undefined;
		
		StornoReplacementTable = "tt" + RegisterTableName + "ReplacementStorno";
		ReverseReplacementTable = "tt" + RegisterTableName + "ReverseReplacement";
		PlacementTable = "tt" + RegisterTableName;
		
		If StornoReplacementWithReverseIsRequired Then
			FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete,, StornoReplacementTable);
			QueriesTexts.Add(RegisterRequestText);
			RegisterRequestText = TextOfAnalysisSelectionFromNestedTable();
			RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", StornoReplacementTable);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
		EndIf;
		
		If ReverseEntryNeedsToBeReplacedStorno Then
			FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, ReverseIndexFields, ReverseReplacementTable);
			QueriesTexts.Add(RegisterRequestText);
			RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable(True);
			RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", ReverseReplacementTable);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
		EndIf;
		
		FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, IndexingFields, PlacementTable);
		
		If Query.Parameters.RestoreCalculationsForStorno And RegistersOfRecoveryOfCalculationsOnStorno.Find(RegisterTableName) <> Undefined Then
			AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterTableName);
			FinancialAccountingByBalanceSheetRegisterData.AddSelectionOfAnalyticsToQueryText(
				RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
		EndIf;
		
		QueriesTexts.Add(RegisterRequestText);
		AvailableRegisterFields_.Insert(RegisterTableName, AvailableRegisterFields);
	EndDo;
	
	If QueriesTexts.Count() > 0 Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Results = Query.ExecuteBatch();
		QueriesTexts.Clear();
	EndIf;
	
	While SamplingRegisterRevolutions.Next() Do
		QueryText = "
		|SELECT
		|	RevolutionsForTuning.ChartOfAccounts AS ChartOfAccounts,
		|	RevolutionsForTuning.PostingGenerationSetting AS PostingGenerationSetting,
		|	RevolutionsForTuning.GLAccountDr AS GLAccountDr,
		|	RevolutionsForTuning.GLAccountCr AS GLAccountCr,
		|	RevolutionsForTuning.LongTermDr AS LongTermDr,
		|	RevolutionsForTuning.LongTermCr AS LongTermCr,
		|	RevolutionsForTuning.Period AS Period,
		|	RevolutionsForTuning.RegisterNameDr AS RegisterNameDr,
		|	RevolutionsForTuning.RegisterNameCr AS RegisterNameCr,
		|	RevolutionsForTuning.AccountingObjectDr AS AccountingObjectDr,
		|	RevolutionsForTuning.AccountingObjectCr AS AccountingObjectCr,
		|	RevolutionsForTuning.SettingObject1Dr AS SettingObject1Dr,
		|	RevolutionsForTuning.SettingObject1Cr AS SettingObject1Cr,
		|	RevolutionsForTuning.Organization AS Organization,
		|	RevolutionsForTuning.Recorder AS Recorder,
		|	RevolutionsForTuning.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RevolutionsForTuning.FinRecordID AS FinRecordID,
		|	RevolutionsForTuning.CurrencyDr AS CurrencyDr,
		|	RevolutionsForTuning.CurrencyCr AS CurrencyCr,
		|	RevolutionsForTuning.ReflectionStatus AS ReflectionStatus,
		|	RevolutionsForTuning.SumManDr AS SumManDr,
		|	RevolutionsForTuning.SumManCr AS SumManCr,
		|	RevolutionsForTuning.SumComplDr AS SumComplDr,
		|	RevolutionsForTuning.SumComplCr AS SumComplCr,
		|	RevolutionsForTuning.SumCurrDr AS SumCurrDr,
		|	RevolutionsForTuning.SumCurrCr AS SumCurrCr,
		|	RevolutionsForTuning.CountDr AS CountDr,
		|	RevolutionsForTuning.CountCr AS CountCr,
		|	&TableSelectionFieldsDr,
		|	&TableSelectionFieldsCr
		|FROM
		|	TTRpmForSetting AS RevolutionsForTuning
		|";
		
		If FilterFieldsDr.Count() > 0
			And Not IsBlankString(SamplingRegisterRevolutions.RegisterNameDr)
			And Not SamplingRegisterRevolutions.RegisterNameDr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			QueryText = QueryText + "
			|	INNER JOIN &TableDr AS TableDr
			|		ON RevolutionsForTuning.Period = TableDr.Period
			|		 AND RevolutionsForTuning.Recorder = TableDr.Recorder
			|		 AND RevolutionsForTuning.FinRecordID = TableDr.FinRecordID
			|		 AND RevolutionsForTuning.RowIDDr = TableDr.RowID
			|		 AND RevolutionsForTuning.RegisterNameDr = &RegisterNameDr
			|		 AND RevolutionsForTuning.AccountingObjectDr = TableDr.AccountingObject
			|		 AND RevolutionsForTuning.SourceConfigurationObjectDr = TableDr.SettingObject1
			|		 AND RevolutionsForTuning.MaturityDateDr = TableDr.MaturityDate
			|		 AND RevolutionsForTuning.Organization = TableDr.Organization
			|		 AND CASE
			|			WHEN TableDr.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
			|				THEN RevolutionsForTuning.SettingUpBusinessTransaction = TableDr.SettingUpBusinessTransaction
			|			ELSE TRUE
			|		 END
			|		 AND CASE
			|			WHEN RevolutionsForTuning.InvertEntriy
			|				THEN NOT TableDr.ThisIsDebit
			|			ELSE NOT TableDr.ThisIsLoan
			|		 END
			|		 AND RevolutionsForTuning.ThisIsReverseTransactionDr = TableDr.ThisIsReverseTransaction
			|";
		EndIf;
			
		If FilterFieldsCr.Count() > 0
			And Not IsBlankString(SamplingRegisterRevolutions.RegisterNameCr)
			And Not SamplingRegisterRevolutions.RegisterNameCr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			QueryText = QueryText + "
			|	INNER JOIN &TableCr AS TableCr
			|		ON RevolutionsForTuning.Period = TableCr.Period
			|		 AND RevolutionsForTuning.Recorder = TableCr.Recorder
			|		 AND RevolutionsForTuning.FinRecordID = TableCr.FinRecordID
			|		 AND RevolutionsForTuning.RowIDCr = TableCr.RowID
			|		 AND RevolutionsForTuning.RegisterNameCr = &RegisterNameCr
			|		 AND RevolutionsForTuning.AccountingObjectCr = TableCr.AccountingObject
			|		 AND RevolutionsForTuning.SourceConfigurationObjectCr = TableCr.SettingObject1
			|		 AND RevolutionsForTuning.MaturityDateCr = TableCr.MaturityDate
			|		 AND RevolutionsForTuning.Organization = TableCr.Organization
			|		 AND CASE
			|			WHEN TableCr.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
			|				THEN RevolutionsForTuning.SettingUpBusinessTransaction = TableCr.SettingUpBusinessTransaction
			|			ELSE TRUE
			|		 END
			|		 AND CASE
			|			WHEN RevolutionsForTuning.InvertEntriy
			|				THEN NOT TableCr.ThisIsLoan
			|			ELSE NOT TableCr.ThisIsDebit
			|		 END
			|		 AND RevolutionsForTuning.ThisIsReverseTransactionCr = TableCr.ThisIsReverseTransaction
			|";
		EndIf;
		
		QueryText = StrReplace(QueryText, "&TableDr", StrTemplate("tt%1", SamplingRegisterRevolutions.RegisterNameDr));
		QueryText = StrReplace(QueryText, "&TableCr", StrTemplate("tt%1", SamplingRegisterRevolutions.RegisterNameCr));
		QueryText = StrReplace(QueryText, "&RegisterNameDr", StrTemplate("""%1""", SamplingRegisterRevolutions.RegisterNameDr));
		QueryText = StrReplace(QueryText, "&RegisterNameCr", StrTemplate("""%1""", SamplingRegisterRevolutions.RegisterNameCr));
		
		AvailableRegisterFieldsDr = Undefined;
		AvailableRegisterFieldsCr = Undefined;
		
		If IsBlankString(SamplingRegisterRevolutions.RegisterNameDr)
		 Or Not AvailableRegisterFields_.Property(SamplingRegisterRevolutions.RegisterNameDr, AvailableRegisterFieldsDr) Then
			AvailableRegisterFieldsDr = New Array();
		EndIf;
		
		If IsBlankString(SamplingRegisterRevolutions.RegisterNameCr)
		 Or Not AvailableRegisterFields_.Property(SamplingRegisterRevolutions.RegisterNameCr, AvailableRegisterFieldsCr) Then
			AvailableRegisterFieldsCr = New Array();
		EndIf;
		
		AddSelectionFieldsToQueryText(FilterFieldsDr, AvailableRegisterFieldsDr, QueryText, "Dr");
		AddSelectionFieldsToQueryText(FilterFieldsCr, AvailableRegisterFieldsCr, QueryText, "Cr");
		
		QueriesTexts.Add(QueryText);
	EndDo;
	
	If QueriesTexts.Count() = 0 Then
		QueriesTexts.Add("
		|SELECT
		|	RevolutionsForTuning.ChartOfAccounts AS ChartOfAccounts,
		|	RevolutionsForTuning.PostingGenerationSetting AS PostingGenerationSetting,
		|	RevolutionsForTuning.GLAccountDr AS GLAccountDr,
		|	RevolutionsForTuning.GLAccountCr AS GLAccountCr,
		|	RevolutionsForTuning.LongTermDr AS LongTermDr,
		|	RevolutionsForTuning.LongTermCr AS LongTermCr,
		|	RevolutionsForTuning.Period AS Period,
		|	RevolutionsForTuning.RegisterNameDr AS RegisterNameDr,
		|	RevolutionsForTuning.RegisterNameCr AS RegisterNameCr,
		|	RevolutionsForTuning.AccountingObjectDr AS AccountingObjectDr,
		|	RevolutionsForTuning.AccountingObjectCr AS AccountingObjectCr,
		|	RevolutionsForTuning.SettingObject1Dr AS SettingObject1Dr,
		|	RevolutionsForTuning.SettingObject1Cr AS SettingObject1Cr,
		|	RevolutionsForTuning.Organization AS Organization,
		|	RevolutionsForTuning.Recorder AS Recorder,
		|	RevolutionsForTuning.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RevolutionsForTuning.FinRecordID AS FinRecordID,
		|	RevolutionsForTuning.CurrencyDr AS CurrencyDr,
		|	RevolutionsForTuning.CurrencyCr AS CurrencyCr,
		|	RevolutionsForTuning.ReflectionStatus AS ReflectionStatus,
		|	RevolutionsForTuning.SumManDr AS SumManDr,
		|	RevolutionsForTuning.SumManCr AS SumManCr,
		|	RevolutionsForTuning.SumComplDr AS SumComplDr,
		|	RevolutionsForTuning.SumComplCr AS SumComplCr,
		|	RevolutionsForTuning.SumCurrDr AS SumCurrDr,
		|	RevolutionsForTuning.SumCurrCr AS SumCurrCr,
		|	RevolutionsForTuning.CountDr AS CountDr,
		|	RevolutionsForTuning.CountCr AS CountCr
		|FROM
		|	TTRpmForSetting AS RevolutionsForTuning
		|");
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRpmForSetting");
		
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Results = Query.ExecuteBatch();
		QueriesTexts.Clear();
		
		RevolutionsForTuning = Results[0].Unload();
		
		TypesOfSelectionFieldsDr = New Structure();
		TypesOfSelectionFieldsCr = New Structure();
		
		For Each KeyAndValue In RegisterRequestsTexts Do
			FilterAvailableFields = DescriptionOfFinancialRegisterFields(KeyAndValue.Key);
			FillInTypesOfSelectionFields(FilterFieldsDr, TypesOfSelectionFieldsDr, FilterAvailableFields);
			FillInTypesOfSelectionFields(FilterFieldsCr, TypesOfSelectionFieldsCr, FilterAvailableFields);
		EndDo;
		
		AddSelectionFieldsToTableColumns(TypesOfSelectionFieldsDr, RevolutionsForTuning.Columns, "Dr");
		AddSelectionFieldsToTableColumns(TypesOfSelectionFieldsCr, RevolutionsForTuning.Columns, "Cr");
		
		FieldSelectionText = "";
		LineSplitter = "," + Chars.LF + Chars.Tab;
		
		For Each Column In RevolutionsForTuning.Columns Do
			If Not IsBlankString(FieldSelectionText) Then
				FieldSelectionText = FieldSelectionText + LineSplitter;
			EndIf;
			FieldSelectionText = FieldSelectionText + "RevolutionsForTuning." + Column.Name;
		EndDo;
		
		QueryText = "
		|SELECT
		|	&FieldSelectionText
		|INTO TTRpmForSetting
		|FROM
		|	&RevolutionsForTuning AS RevolutionsForTuning
		|";
		
		QueryText = StrReplace(QueryText, "&FieldSelectionText", FieldSelectionText);
		
		Query.Text = QueryText;
		Query.SetParameter("RevolutionsForTuning", RevolutionsForTuning);
		Result = Query.Execute();
		
		If FilterFieldsDr.Find("TypeOfRegistrar") <> Undefined Then
			FieldSelectionString_ = "VALUETYPE(RevolutionsForTuning.RecorderDr) AS TypeOfRegistrarDr";
			FieldSelectionText = FieldSelectionText + LineSplitter + FieldSelectionString_;
		EndIf;
		
		If FilterFieldsCr.Find("TypeOfRegistrar") <> Undefined Then
			FieldSelectionString_ = "VALUETYPE(RevolutionsForTuning.RecorderCr) AS TypeOfRegistrarCr";
			FieldSelectionText = FieldSelectionText + LineSplitter + FieldSelectionString_;
		EndIf;
		
		QueryText = "
		|SELECT
		|	&FieldSelectionText
		|FROM
		|	TTRpmForSetting AS RevolutionsForTuning
		|";
		
		QueryText = StrReplace(QueryText, "&FieldSelectionText", FieldSelectionText);
		QueriesTexts.Add(QueryText);
	EndIf;
	
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin(True));
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctionsForGeneratingQueryTexts

Function SettingsForGeneratingTransactionsBasedOnRequestParameters(QueryOptions)
	
	TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings(, False);
	
	TransactionSettings.AllocationOfLongTermAssetsAndLiabilities = QueryOptions.AllocationOfLongTermAssetsAndLiabilities;
	TransactionSettings.MethodOfAccountingForImproperValues = QueryOptions.MethodOfAccountingForImproperValues;
	TransactionSettings.RevenueExcludingVAT = QueryOptions.RevenueExcludingVAT;
	
	Return TransactionSettings;
	
EndFunction

Procedure ExcludeRegistersByLoggerMovementCollections(QueryOptions, BalanceFinancialRegisters)
	
	If Not ValueIsFilled(QueryOptions.Recorder)
	   And Not ValueIsFilled(QueryOptions.TypeOfRegistrar) Then
		Return;
	EndIf;
	
	If TypeOf(QueryOptions.Recorder) = Type("Array") Then
		TypesOfLoggers = New Array();
		For Each Recorder In QueryOptions.Recorder Do
			TypeOfRegistrar = TypeOf(Recorder);
			If TypesOfLoggers.Find(TypeOfRegistrar) = Undefined Then
				TypesOfLoggers.Add(TypeOfRegistrar);
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(QueryOptions.Recorder) Then 
		TypesOfLoggers = CommonClientServer.ValueInArray(TypeOf(QueryOptions.Recorder));
	ElsIf TypeOf(QueryOptions.TypeOfRegistrar) = Type("Array") Then
		TypesOfLoggers = QueryOptions.TypeOfRegistrar;
	Else
		TypesOfLoggers = CommonClientServer.ValueInArray(QueryOptions.TypeOfRegistrar);
	EndIf;
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	AllAccumulationRegisters = New Map();
	
	For Each TypeOfRegistrar In TypesOfLoggers Do
		DocumentMetadata = Metadata.FindByType(TypeOfRegistrar);
		For Each MetadataRegister In DocumentMetadata.RegisterRecords Do
			If AccumulationRegistersMetadata.Contains(MetadataRegister) Then
				RegisterName = MetadataRegister.Name;
				If AllAccumulationRegisters[RegisterName] = Undefined Then
					AllAccumulationRegisters.Insert(RegisterName, True);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	For Each RegisterName In BalanceFinancialRegisters Do
		RegisterMetadata = AccumulationRegistersMetadata[RegisterName];
		MotionReflectionParameters = ParametersOfRegisteringRecordedMovementsInInternationalAccounting(RegisterName, RegisterMetadata);
		
		If MotionReflectionParameters.DataPathLogger <> "Recorder" Then
			RegistrationDetails_1 = RegisterMetadata.Attributes[MotionReflectionParameters.DataPathLogger];
			For Each TypeOfRegistrar In TypesOfLoggers Do
				If RegistrationDetails_1.Type.ContainsType(TypeOfRegistrar) Then
					AllAccumulationRegisters.Insert(RegisterName, True);
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If MotionReflectionParameters.AllocationOfLongTermAssetsAndLiabilities Then
			For Each TypeOfRegistrar In TypesOfLoggers Do
				If TypeOfRegistrar = Type("DocumentRef.PeriodEndTransactionFinancialAccounting") Then
					AllAccumulationRegisters.Insert(RegisterName, True);
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	ValuesCount = BalanceFinancialRegisters.Count();
	
	For ValueNumber = 1 To ValuesCount Do
		ValueIndex = ValuesCount - ValueNumber;
		RegisterName = BalanceFinancialRegisters[ValueIndex];
		If AllAccumulationRegisters[RegisterName] = Undefined Then
			BalanceFinancialRegisters.Delete(ValueIndex);
		EndIf;
	EndDo;
	
EndProcedure

Function FieldsForSelectingCorrespondenceRequestsThatAreBeingDeleted()
	
	FieldsToDelete__ = New Array();
	FieldsToDelete__.Add("Department");
	FieldsToDelete__.Add("LineOfBusiness");
	
	Return FieldsToDelete__;
	
EndFunction

Function DeletedFieldsForSelectingMotionAnalyticsQueries()
	
	FieldsToDelete__ = New Array();
	FieldsToDelete__.Add("OfficialTypeOfActivityVAT");
	FieldsToDelete__.Add("PropsStorno");
	
	Return FieldsToDelete__;
	
EndFunction

Function IndexFieldsOfCorrespondenceTable()
	
	IndexFields = New Array();
	IndexFields.Add("ThisIsDebit");
	IndexFields.Add("ThisIsLoan");
	
	Return IndexFields;
	
EndFunction

Function IndexFieldsOfIndividualCorrespondenceTables()
	
	IndexFields = New Array();
	IndexFields.Add("Period");
	IndexFields.Add("Recorder");
	IndexFields.Add("FinRecordID");
	IndexFields.Add("RowID");
	IndexFields.Add("AccountingObject");
	IndexFields.Add("SettingObject1");
	IndexFields.Add("PlaceOfRegistration");
	IndexFields.Add("MaturityDate");
	IndexFields.Add("Organization");
	IndexFields.Add("SettingUpBusinessTransaction");
	
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
	
	SelectionFields1.Add("SettingObject1");
	SelectionFields1.Add("MaturityDate");
	
	Return SelectionFields1;
	
EndFunction

Function RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(AccountingObjectRows_, MotionReflectionParameters, QueryOptions)
	
	FieldList = StrConcat(SelectionFieldsBasedOnDescriptionOfAccountingObject(), ",");
	
	FieldsOfAccountingObjectSelection = FinancialAccountingByBalanceSheetRegisterData.RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, FieldList);
	
	FieldsOfAccountingObjectSelection.SettingObject1 = FinancialAccountingByBalanceSheetRegisterData.SelectionStringOfAccountingObjectField(
		"DataPathConfigurationObject", AccountingObjectRows_, MotionReflectionParameters, QueryOptions, Undefined);
	
	FieldsOfAccountingObjectSelection.MaturityDate = FinancialAccountingByBalanceSheetRegisterData.FieldSelectionStringWithAttributeOfAccountingInObject(
		"DataPathMaturityDate", "AllocationOfLongTermAssetsAndLiabilities", AccountingObjectRows_, MotionReflectionParameters, QueryOptions, '00010101');
	
	Return FieldsOfAccountingObjectSelection;
	
EndFunction

Function ExtdimensionSampleString(ExtDimensionType, ExtdimensionValueType, RegisterName, AccountingObjectRows_)
	
	SelectionStrings = New Array();
	
	PathToExtdimensionDataWithoutSelection = "";
	DataSelectionsWithoutExtdimensionPaths = New Array();
	
	For Each AccountingObjectLine_ In AccountingObjectRows_ Do
		PathToExtdimensionData = AccountingObjectLine_.PathsToExtdimensionData.Find(ExtDimensionType, "ExtDimensionType");
		If PathToExtdimensionData <> Undefined Then
			DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(PathToExtdimensionData.DataPath);
			If AccountingObjectLine_.Filterdata_.Items.Count() > 0 Then
				LinesWhen = New Array();
				LinesWhen.Add(Chars.Tab);
				LinesWhen.Add("WHEN"); //@Query-part
				LinesWhen.Add(FinancialAccountingByBalanceSheetRegisterData.DataSelectionConditionString(AccountingObjectLine_.Filterdata_));
				
				LinesAreThen = New Array();
				LinesAreThen.Add(Chars.Tab);
				LinesAreThen.Add("THEN"); //@Query-part
				LinesAreThen.Add(DataPath);
				
				SelectionStrings.Add(StrConcat(LinesWhen, " "));
				SelectionStrings.Add(StrConcat(LinesAreThen, " "));
			Else
				PathToExtdimensionDataWithoutSelection = DataPath;
			EndIf;
		ElsIf AccountingObjectLine_.Filterdata_.Items.Count() > 0 Then
			DataSelectionsWithoutExtdimensionPaths.Add(AccountingObjectLine_.Filterdata_);
		EndIf;
	EndDo;
	
	SelectRegisterFieldsByExtdimensionType = Not IsBlankString(RegisterName);
	
	If Not IsBlankString(PathToExtdimensionDataWithoutSelection) Then
		LinesWhen = New Array();
		LinesWhen.Add(Chars.Tab);
		LinesWhen.Add("WHEN"); //@Query-part
		
		If DataSelectionsWithoutExtdimensionPaths.Count() > 0 Then
			LinesWhen.Add("NOT"); //@Query-part
			LinesWhen.Add(FinancialAccountingByBalanceSheetRegisterData.DataSelectionConditionString(DataSelectionsWithoutExtdimensionPaths));
		Else
			LinesWhen.Add("TRUE"); //@Query-part
			SelectRegisterFieldsByExtdimensionType = False;
		EndIf;
		
		LinesAreThen = New Array();
		LinesAreThen.Add(Chars.Tab);
		LinesAreThen.Add("THEN"); //@Query-part
		LinesAreThen.Add(PathToExtdimensionDataWithoutSelection);
		
		SelectionStrings.Add(StrConcat(LinesWhen, " "));
		SelectionStrings.Add(StrConcat(LinesAreThen, " "));
	EndIf;
	
	If SelectRegisterFieldsByExtdimensionType Then
		RegisterFieldsDetails = ExtdimensionRegisterFields(ExtdimensionValueType, RegisterName);
		
		For Each FieldDetails In RegisterFieldsDetails Do
			DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(FieldDetails.DataPath);
			
			LinesWhen = New Array();
			LinesWhen.Add(Chars.Tab);
			LinesWhen.Add("WHEN NOT"); //@Query-part
			LinesWhen.Add(DataPath);
			LinesWhen.Add("IN ("); //@Query-part
			LinesWhen.Add(FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(EmptyTypeValues(FieldDetails.Type)));
			LinesWhen.Add(") AND VALUETYPE("); //@Query-part
			LinesWhen.Add(DataPath);
			LinesWhen.Add(") IN ("); //@Query-part
			LinesWhen.Add(FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(ExtdimensionValueType.Types()));
			LinesWhen.Add(")");
			
			LinesAreThen = New Array();
			LinesAreThen.Add(Chars.Tab);
			LinesAreThen.Add("THEN"); //@Query-part
			LinesAreThen.Add(DataPath);
				
			SelectionStrings.Add(StrConcat(LinesWhen, " "));
			SelectionStrings.Add(StrConcat(LinesAreThen, " "));
		EndDo;
	EndIf;
	
	If SelectionStrings.Count() > 0 Then
		StringsOtherwise = New Array();
		StringsOtherwise.Add(Chars.Tab);
		StringsOtherwise.Add("ELSE"); //@Query-part
		StringsOtherwise.Add("UNDEFINED"); //@Query-part
		
		LinesEnd = New Array();
		LinesEnd.Add(Chars.Tab);
		LinesEnd.Add("END"); //@Query-part
		
		SelectionStrings.Insert(0, "CASE"); //@Query-part
		SelectionStrings.Add(StrConcat(StringsOtherwise, " "));
		SelectionStrings.Add(StrConcat(LinesEnd, ""));
		SelectionString = StrConcat(SelectionStrings, Chars.LF);
	Else
		SelectionString = "UNDEFINED"; //@Query-part
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function ConditionsLineChartOfAccounts(QueryOptions)
	
	If TypeOf(QueryOptions.ChartOfAccounts) = Type("Array") Then
		Return "&ChartOfAccounts IN (&RequestParameterChartOfAccounts)";
	ElsIf ValueIsFilled(QueryOptions.ChartOfAccounts) Then
		Return "&ChartOfAccounts = &RequestParameterChartOfAccounts";
	Else
		Return "TRUE";
	EndIf;
	
EndFunction

Function ConditionLineAccountingObject(QueryOptions, DrCr, SourceAlias, StrictCondition = False)
	
	ConditionStrings = New Array();
	
	If TypeOf(QueryOptions["AccountingObject" + DrCr]) = Type("Array") Then
		ConditionStrings.Add(FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("AccountingObject%1", SourceAlias) + " IN (&AccountingObject%1)");
		If Not StrictCondition Then
			ConditionStrings.Add(FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("AccountingObject%2", SourceAlias) + " IN (&AccountingObject%1)");
		EndIf;
	ElsIf ValueIsFilled(QueryOptions["AccountingObject" + DrCr]) Then
		ConditionStrings.Add(FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("AccountingObject%1", SourceAlias) + " = &AccountingObject%1");
		If Not StrictCondition Then
			ConditionStrings.Add(FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("AccountingObject%2", SourceAlias) + " = &AccountingObject%1");
		EndIf;
	EndIf;
	
	If ConditionStrings.Count() = 0 Then
		Return "TRUE";
	ElsIf ConditionStrings.Count() = 1 Then
		Return StrTemplate(ConditionStrings[0], DrCr);
	Else
		BalancedDrCr = ?(DrCr = "Dr", "Cr", "Dr");
		Return StrTemplate("(" + StrConcat(ConditionStrings, " OR ") + ")", DrCr, BalancedDrCr);
	EndIf;
	
EndFunction

Function PresentationOfAppealPeriod(Selection, QueryOptions, DrCr)
	
	If QueryOptions.SourcesWithDueDates.Find(Selection["AccountingObject" + DrCr], "AccountingObject") = Undefined Then
		Return "";
	ElsIf Selection["LongTerm" + DrCr] Then
		Return NStr("vi = 'Dài hạn';
					|ru = 'Долгосрочный';
					|en = 'Long-term'; fa = 'بلندمدت';
					|it = 'A lungo termine';
					|pl = 'Długoterminowy';
					|tr = 'Uzun vadeli'");
	Else
		Return NStr("vi = 'Ngắn hạn';
					|ru = 'Краткосрочный';
					|en = 'Short-term'; fa = 'کوتاه‌مدت';
					|it = 'A breve termine';
					|pl = 'Krótkoterminowy';
					|tr = 'Kısa vadeli'");
	EndIf;
	
EndFunction

#EndRegion

#Region SelectionOfAccountingAccounts

Function AllKindsOfExtdimensionAccountingAccounts(Selection)
	
	AllKindsOfExtdimension = New Map();
	UserExtdimensionNumber = 1;
	
	While Selection.Next() Do
		For ExtDimensionNumber = 1 To Selection.ExtDimensionCount Do
			ExtDimensionType = Selection["ExtDimensionType" + ExtDimensionNumber];
			If ValueIsFilled(ExtDimensionType) And AllKindsOfExtdimension[ExtDimensionType] = Undefined Then
				If IsBlankString(Selection["ExtraDimensionTypeName" + ExtDimensionNumber]) Then
					ExtraDimensionTypeName = "UserExtdimension" + Format(UserExtdimensionNumber, "NG=0");
					UserExtdimensionNumber = UserExtdimensionNumber + 1;
				Else
					ExtraDimensionTypeName = "ExtDimension" + Selection["ExtraDimensionTypeName" + ExtDimensionNumber];
				EndIf;
				DescriptionOfExtdimension = New Structure();
				DescriptionOfExtdimension.Insert("Name", ExtraDimensionTypeName);
				DescriptionOfExtdimension.Insert("Type", Selection["ExtdimensionValueType" + ExtDimensionNumber]);
				AllKindsOfExtdimension.Insert(ExtDimensionType, DescriptionOfExtdimension);
			EndIf;
		EndDo;
	EndDo;
	
	Return AllKindsOfExtdimension;
	
EndFunction

Function AllExtdimensionFillingExpressions(Selection, QueryOptions)
	
	AllExpressionsAreExtdimension = New Map();
	
	While Selection.Next() Do
		For ExpressionNumber = 1 To 3 Do
			ExpressionOfExtdimension = Selection["ExpressionOfExtdimension" + ExpressionNumber];
			If ValueIsFilled(ExpressionOfExtdimension) Then
				NormalizeExpressionExtdimension(ExpressionOfExtdimension, QueryOptions);
				If AllExpressionsAreExtdimension[ExpressionOfExtdimension] = Undefined Then
					ExpressionName = "Expression" + StrReplace(ExpressionOfExtdimension, ".", "");
					AllExpressionsAreExtdimension.Insert(ExpressionOfExtdimension, ExpressionName);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return AllExpressionsAreExtdimension;
	
EndFunction

Function TypesOfExtdimensionOfRegister(FetchingRegisterName, SamplingExtdimensionSpecies)
	
	TypesOfExtdimensionOfRegister = New Array();
	
	InvoiceSelection_ = FetchingRegisterName.Select();
	While InvoiceSelection_.Next() Do
		SamplingExtdimensionSpecies.Reset();
		SamplingExtdimensionSpecies.FindNext(InvoiceSelection_.GLAccount, "GLAccount");
		For ExtDimensionNumber = 1 To SamplingExtdimensionSpecies.ExtDimensionCount Do
			ExtDimensionType = SamplingExtdimensionSpecies["ExtDimensionType" + ExtDimensionNumber];
			If ValueIsFilled(ExtDimensionType) And TypesOfExtdimensionOfRegister.Find(ExtDimensionType) = Undefined Then
				TypesOfExtdimensionOfRegister.Add(ExtDimensionType);
			EndIf;
		EndDo;
	EndDo;
	
	Return TypesOfExtdimensionOfRegister;
	
EndFunction

Function RegisterExtdimensionExpressions(FetchingRegisterName, SamplingExpressionExtdimension, QueryOptions)
	
	RegisterExtdimensionExpressions = New Array();
	
	SamplingExpressionExtdimension.Reset();
	While SamplingExpressionExtdimension.FindNext(FetchingRegisterName.RegisterName, "RegisterName") Do
		For ExpressionNumber = 1 To 3 Do
			ExpressionOfExtdimension = SamplingExpressionExtdimension["ExpressionOfExtdimension" + ExpressionNumber];
			If ValueIsFilled(ExpressionOfExtdimension) Then
				NormalizeExpressionExtdimension(ExpressionOfExtdimension, QueryOptions);
				If RegisterExtdimensionExpressions.Find(ExpressionOfExtdimension) = Undefined Then
					RegisterExtdimensionExpressions.Add(ExpressionOfExtdimension);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return RegisterExtdimensionExpressions;
	
EndFunction

Procedure AddExtdimensionSelectionFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, AllKindsOfExtdimension, TypesOfExtdimensionOfRegister, RegisterName, FinancialAccountingObjects)
	
	TheStructureOfTheSearch = New Structure("DataSource", RegisterName);
	AccountingObjectRows_ = FinancialAccountingObjects.FindRows(TheStructureOfTheSearch);
	
	For Each ExtDimensionType In TypesOfExtdimensionOfRegister Do
		DescriptionOfSpeciesExtdimension = AllKindsOfExtdimension[ExtDimensionType];
		ExtdimensionSampleString = ExtdimensionSampleString(ExtDimensionType, DescriptionOfSpeciesExtdimension.Type, RegisterName, AccountingObjectRows_);
		RowsOfAnalyticsFields.Add(ExtdimensionSampleString + " AS " + DescriptionOfSpeciesExtdimension.Name);
		RowsOfAnalyticsGroups.Add(ExtdimensionSampleString);
	EndDo;
	
EndProcedure

Procedure AddExpressionSelectionFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, AllExpressionsAreExtdimension, RegisterExtdimensionExpressions)
	
	For Each ExpressionOfExtdimension In RegisterExtdimensionExpressions Do
		ExpressionName = AllExpressionsAreExtdimension[ExpressionOfExtdimension];
		DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(ExpressionOfExtdimension);
		RowsOfAnalyticsFields.Add(DataPath + " AS " + ExpressionName);
		RowsOfAnalyticsGroups.Add(DataPath);
	EndDo;
	
EndProcedure

Procedure AddAvailableRegisterFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, AvailableRegisterFields, RegisterName)
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("Organization");
	ExistingSelectionFields.Add("Department");
	ExistingSelectionFields.Add("LineOfBusiness");
	ExistingSelectionFields.Add("Currency");
	ExistingSelectionFields.Add("Recorder");
	ExistingSelectionFields.Add("BusinessTransactionSetting");
	ExistingSelectionFields.Add("MaturityDate");
	
	If IsBlankString(RegisterName)
	 Or RegisterName = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
		For Each CaseFieldName In ExistingSelectionFields Do
			AvailableRegisterFields.Add(CaseFieldName);
		EndDo;
	Else
		FieldsDetails = DescriptionOfFinancialRegisterFields(RegisterName);
		For Each KeyAndValue In FieldsDetails Do
			DataPathParts = StrSplit(KeyAndValue.Value.DataPath, ".");
			CaseFieldName = DataPathParts[0];
			
			If AvailableRegisterFields.Find(CaseFieldName) = Undefined Then
				AvailableRegisterFields.Add(CaseFieldName);
				If ExistingSelectionFields.Find(CaseFieldName) = Undefined Then
					DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(CaseFieldName);
					RowsOfAnalyticsFields.Add(DataPath + " AS " + CaseFieldName);
					RowsOfAnalyticsGroups.Add(DataPath);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	AvailableRegisterFields.Add("TypeOfRegistrar");
	
EndProcedure

Procedure AddAvailableFieldsToQueryText(AvailableRegisterFields, QueryText, DrCr);
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("CurrencyDr");
	ExistingSelectionFields.Add("CurrencyCr");
	
	RowsOfAvailableFields = New Array();
	
	For Each AvailableField In AvailableRegisterFields Do
		FieldName = AvailableField + DrCr;
		
		If ExistingSelectionFields.Find(FieldName) = Undefined Then
			If AvailableField = "BusinessTransactionSetting" Then
				RowsOfAvailableFields.Add("Table" + DrCr+ ".SettingUpBusinessTransaction AS " + FieldName);
			ElsIf AvailableField = "TypeOfRegistrar" Then
				RowsOfAvailableFields.Add("VALUETYPE(Table" + DrCr+ ".Recorder) AS " + FieldName);
			Else
				RowsOfAvailableFields.Add("Table" + DrCr+ "." + AvailableField + " AS " + FieldName);
			EndIf;
		EndIf;
	EndDo;
	
	LineSplitter = "," + Chars.LF + Chars.Tab;
	
	If RowsOfAvailableFields.Count() > 0 Then
		TextOfAvailableFields = StrConcat(RowsOfAvailableFields, LineSplitter);
	Else
		TextOfAvailableFields = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
	EndIf;
	
	QueryText = StrReplace(QueryText, "&AvailableTableFields" + DrCr, TextOfAvailableFields);
	
EndProcedure

Procedure AddSelectionFieldsToQueryText(FilterFields, AvailableRegisterFields, QueryText, DrCr)
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("CurrencyDr");
	ExistingSelectionFields.Add("CurrencyCr");
	
	RowsOfSelectionFields = New Array();
	
	For Each FilterField In FilterFields Do
		FieldName = FilterField + DrCr;
		
		If AvailableRegisterFields.Count() = 0 Then
			RowsOfSelectionFields.Add(FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined) + " AS " + FieldName);
		ElsIf ExistingSelectionFields.Find(FieldName) = Undefined Then
			If FilterField = "BusinessTransactionSetting" Then
				RowsOfSelectionFields.Add("Table" + DrCr+ ".SettingUpBusinessTransaction AS " + FieldName);
			ElsIf FilterField = "TypeOfRegistrar" Then
				RowsOfSelectionFields.Add("VALUETYPE(Table" + DrCr+ ".Recorder) AS " + FieldName);
			ElsIf AvailableRegisterFields.Find(FilterField) <> Undefined Then
				RowsOfSelectionFields.Add("Table" + DrCr+ "." + FilterField + " AS " + FieldName);
			Else
				RowsOfSelectionFields.Add(FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined) + " AS " + FieldName);
			EndIf;
		EndIf;
	EndDo;
	
	LineSplitter = "," + Chars.LF + Chars.Tab;
	
	If RowsOfSelectionFields.Count() > 0 Then
		TextOfSelectionFields_ = StrConcat(RowsOfSelectionFields, LineSplitter);
	Else
		TextOfSelectionFields_ = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TableSelectionFields" + DrCr, TextOfSelectionFields_);
	
EndProcedure

Procedure FillInTypesOfSelectionFields(FilterFields, TypesOfSelectionFields, FilterAvailableFields)
	
	For Each KeyAndValue In FilterAvailableFields Do
		DataPathParts = StrSplit(KeyAndValue.Value.DataPath, ".");
		CaseFieldName = DataPathParts[0];
		
		For Each FilterField In FilterFields Do
			If FilterField = CaseFieldName Then
				If Not TypesOfSelectionFields.Property(FilterField) Then
					TypesOfSelectionFields.Insert(FilterField, New Array());
				EndIf;
				CommonClientServer.SupplementArray(TypesOfSelectionFields[FilterField], KeyAndValue.Value.Type.Types(), True);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	If FilterFields.Find("TypeOfRegistrar") <> Undefined And Not TypesOfSelectionFields.Property("Recorder") Then
		TypesOfSelectionFields.Insert("Recorder", Documents.AllRefsType().Types());
	EndIf;
	
EndProcedure

Procedure AddSelectionFieldsToTableColumns(TypesOfSelectionFields, TableColumns1, DrCr)
	
	ExistingTableColumns = New Array();
	ExistingTableColumns.Add("CurrencyDr");
	ExistingTableColumns.Add("CurrencyCr");
	
	For Each KeyAndValue In TypesOfSelectionFields Do
		ColumnName = KeyAndValue.Key + DrCr;
		
		If ExistingTableColumns.Find(ColumnName) = Undefined Then
			TableColumns1.Add(ColumnName, New TypeDescription(KeyAndValue.Value));
		EndIf;
	EndDo;
	
EndProcedure

Procedure RegisterEmptyAccountForConfiguration(MotionSampling_, DrCr)
	
	AccountRegistrationData = InformationRegisters.FinancialAccountingAccountsThatRequireSettings.NewAccountRegistrationData();
	AccountRegistrationData.ChartOfAccounts = MotionSampling_.ChartOfAccounts;
	AccountRegistrationData.PostingGenerationSetting = MotionSampling_.PostingGenerationSetting;
	AccountRegistrationData.AccountingObject = MotionSampling_["AccountingObject" + DrCr];
	AccountRegistrationData.SettingObject1 = MotionSampling_["SettingObject1" + DrCr];
	AccountRegistrationData.Document = MotionSampling_.Recorder;
	AccountRegistrationData.LongTerm = MotionSampling_["LongTerm" + DrCr];
	
	InformationRegisters.FinancialAccountingAccountsThatRequireSettings.RegisterForConfiguration(AccountRegistrationData);
	
EndProcedure

Procedure NormalizeExpressionExtdimension(ExpressionOfExtdimension, QueryOptions, DrCr = "")
	
	If DrCr <> "Cr" And StrStartsWith(ExpressionOfExtdimension, QueryOptions.ExtdimensionExpressionPrefixDr) Then
		ExpressionOfExtdimension = Mid(ExpressionOfExtdimension, QueryOptions.LengthOfExpressionPrefixDr + 2);
	EndIf;
	
	If DrCr <> "Dr" And StrStartsWith(ExpressionOfExtdimension, QueryOptions.ExtdimensionExpressionPrefixCr) Then
		ExpressionOfExtdimension = Mid(ExpressionOfExtdimension, QueryOptions.LengthOfCrExpressionPrefix + 2);
	EndIf;
	
	ExpressionOfExtdimension = StrReplace(ExpressionOfExtdimension, "_", ".");
	
EndProcedure

#EndRegion

#Region SelectionOfCorrespondenceAccordingToSettingsOfDataCompositionSchema

Function DataCompositionSelectionFields(QueryOptions)
	
	SelectionFields = New Structure();
	SelectionFields.Insert("RecNo", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative));
	SelectionFields.Insert("ApplicationProcedure", Common.TypeDescriptionNumber(3, 0, AllowedSign.Nonnegative));
	
	Return SelectionFields;
	
EndFunction

Function DataLayoutResultsTable(DataCompositionSelectionFields)
	
	ResultsTable = New ValueTable();
	
	For Each ComboBox In DataCompositionSelectionFields Do
		ResultsTable.Columns.Add(ComboBox.Key, ComboBox.Value);
	EndDo;
	
	Return ResultsTable;
	
EndFunction

Function MeasurementsOfCorrespondenceReflectionSettings()
	
	SettingMeasurements = New Array();
	
	For Each Dimension In Metadata.InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting.Dimensions Do
		SettingMeasurements.Add(Dimension.Name);
	EndDo;
	
	Return SettingMeasurements;
	
EndFunction

Procedure AddDimensionSettingsToDataLayoutSelection(SettingMeasurements, SelectingSettings, FilterReceiver)
	
	For Each DimensionName In SettingMeasurements Do
		NewItem = FilterReceiver.Items.Add(Type("DataCompositionFilterItem"));
		NewItem.LeftValue = New DataCompositionField(DimensionName);
		NewItem.ComparisonType = DataCompositionComparisonType.Equal;
		NewItem.RightValue = SelectingSettings[DimensionName];
		NewItem.Use = True;
	EndDo;
	
EndProcedure

#EndRegion

#Region GeneratePostings

Procedure FillInTransactionTable(Query, QueriesTexts, TableOfTransactions, ParametersForGeneratingTransactions)
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	ParametersForGeneratingTransactions.Insert("LengthOfSum", Query.Parameters.LengthOfSum);
	ParametersForGeneratingTransactions.Insert("SumAccuracy", Query.Parameters.SumAccuracy);
	ParametersForGeneratingTransactions.Insert("LengthOfQuantity", Query.Parameters.LengthOfQuantity);
	ParametersForGeneratingTransactions.Insert("QuantityAccuracy", Query.Parameters.QuantityAccuracy);
	
	AnalyticsTables = New Structure();
	IndexOfMovementQueryResult = 0;
	
	For Each KeyAndValue In Query.Parameters.AnalyticsSampleRegisters Do
		AnalyticsTables.Insert(KeyAndValue.Key, AnalyticsQueryTable(Results[KeyAndValue.Value]));
		If KeyAndValue.Value >= IndexOfMovementQueryResult Then
			IndexOfMovementQueryResult = KeyAndValue.Value + 1;
		EndIf;
	EndDo;
	
	ResultOfMovement = Results[IndexOfMovementQueryResult];
	MotionSampling_ = ResultOfMovement.Select();
	
	While MotionSampling_.Next() Do
		AnalyticsLines_Dr = TrafficAnalyticsLines(MotionSampling_, AnalyticsTables, Query.Parameters, "Dr");
		AnalyticsLines_Cr = TrafficAnalyticsLines(MotionSampling_, AnalyticsTables, Query.Parameters, "Cr");

		EntryErrors = New Map();
		
		If Not FinancialAccountingByBalanceSheetRegisterData.CheckingEqualityOfBalanceResources(MotionSampling_, AnalyticsLines_Dr, Query.Parameters, "Dr") Then
			EntryErrors.Insert(StrTemplate(NStr("vi = 'Lỗi khi chọn khoản mục đối với bản ghi của biểu ghi ""%1"" với tên định danh %2.';
												|ru = 'Ошибка при подборе субконто к записи регистра ""%1"" с идентификатором %2.';
												|en = 'An error occurred upon picking an extra dimension for the ""%1"" register record with ID %2.'; fa = 'An error occurred upon picking an extra dimension for the ""%1"" register record with ID %2.';
												|it = 'Errore durante la selezione di un sottoconto con voce di registro ""%1"" e ID %2.';
												|pl = 'Błąd podczas wyboru subkonto do wpisu rejestru ""%1"" z identyfikatorem %2.';
												|tr = '""%1"" kayıt girişini %2 kimliği ile eşleştirmek için alt bağlantı hatası.'"),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[MotionSampling_.RegisterNameDr]),
				MotionSampling_.FinRecordID));
		EndIf;
		
		If Not FinancialAccountingByBalanceSheetRegisterData.CheckingEqualityOfBalanceResources(MotionSampling_, AnalyticsLines_Cr, Query.Parameters, "Cr") Then
			EntryErrors.Insert(StrTemplate(NStr("vi = 'Lỗi khi chọn khoản mục đối với bản ghi của biểu ghi ""%1"" với tên định danh %2.';
												|ru = 'Ошибка при подборе субконто к записи регистра ""%1"" с идентификатором %2.';
												|en = 'An error occurred upon picking an extra dimension for the ""%1"" register record with ID %2.'; fa = 'An error occurred upon picking an extra dimension for the ""%1"" register record with ID %2.';
												|it = 'Errore durante la selezione di un sottoconto con voce di registro ""%1"" e ID %2.';
												|pl = 'Błąd podczas wyboru subkonto do wpisu rejestru ""%1"" z identyfikatorem %2.';
												|tr = '""%1"" kayıt girişini %2 kimliği ile eşleştirmek için alt bağlantı hatası.'"),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[MotionSampling_.RegisterNameCr]),
				MotionSampling_.FinRecordID));
		EndIf;
		
		If AnalyticsLines_Dr.Count() > 1 And AnalyticsLines_Cr.Count() > 1 Then
			EntryErrors.Insert(StrTemplate(NStr("vi = 'Các bản ghi của biểu ghi ""%1"" và ""%2"" với tên định danh %3 có mối liên hệ ""nhiều với nhiều"".';
												|ru = 'Записи регистров ""%1"" и ""%2"" с идентификатором %3 имеют отношение ""многие ко многим"".';
												|en = 'Records of registers ""%1"" and ""%2"" with ID %3 have the Many-to-Many relationship.'; fa = 'Records of registers ""%1"" and ""%2"" with ID %3 have the Many-to-Many relationship.';
												|it = 'Voci di registro ""%1"" e ""%2"" con ID %3 hanno relazione ""molti verso molti"".';
												|pl = 'Wpisy rejestrów ""%1"" i ""%2"" z identyfikatorem %3 mają stosunek ""wiele do wielu"".';
												|tr = '%3 kimlikli ""%1"" ve ""%2"" kayıt girişlerinin ""çoktan çok olana"" ilişkisi var.'"),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[MotionSampling_.RegisterNameDr]),
				Common.ObjectPresentation(Metadata.AccumulationRegisters[MotionSampling_.RegisterNameCr]),
				MotionSampling_.FinRecordID));
		EndIf;
		
		If EntryErrors.Count() > 0 Then
			ErrorText = "";
			For Each TransactionError In EntryErrors Do
				ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + TransactionError.Key;
			EndDo;
			AddTransactionWithError(TableOfTransactions, MotionSampling_, ErrorText, ParametersForGeneratingTransactions);
		ElsIf AnalyticsLines_Dr.Count() = 1 And AnalyticsLines_Cr.Count() = 1 Then
			AddSimpleEntriy(TableOfTransactions, MotionSampling_, AnalyticsLines_Dr, AnalyticsLines_Cr, ParametersForGeneratingTransactions);
		Else
			AddComplexEntriy(TableOfTransactions, MotionSampling_, AnalyticsLines_Dr, AnalyticsLines_Cr, ParametersForGeneratingTransactions);
		EndIf;
	EndDo;
	
EndProcedure

Function AnalyticsQueryTable(QueryResult)
	
	QueryTable = QueryResult.Unload();
	RequiredIndexFields = "Period,Recorder,FinRecordID,RowID,RegisterName,AccountingObject,SettingObject1,PlaceOfRegistration,MaturityDate,Organization";
	
	QueryTable.Indexes.Add(RequiredIndexFields + ",ThisIsDebit,ThisIsReverseTransaction");
	QueryTable.Indexes.Add(RequiredIndexFields + ",ThisIsLoan,ThisIsReverseTransaction");
	QueryTable.Indexes.Add(RequiredIndexFields + ",SettingUpBusinessTransaction,ThisIsDebit,ThisIsReverseTransaction");
	QueryTable.Indexes.Add(RequiredIndexFields + ",SettingUpBusinessTransaction,ThisIsLoan,ThisIsReverseTransaction");
	
	Return QueryTable;
	
EndFunction

Function TrafficAnalyticsLines(MotionSampling_, AnalyticsTables, QueryOptions, DrCr)
	
	RegisterName = MotionSampling_["RegisterName" + DrCr];
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Period", MotionSampling_.Period);
	TheStructureOfTheSearch.Insert("Recorder", MotionSampling_.Recorder);
	TheStructureOfTheSearch.Insert("FinRecordID", MotionSampling_.FinRecordID);
	TheStructureOfTheSearch.Insert("RowID", MotionSampling_["RowID" + DrCr]);
	TheStructureOfTheSearch.Insert("RegisterName", RegisterName);
	TheStructureOfTheSearch.Insert("AccountingObject", MotionSampling_["AccountingObject" + DrCr]);
	TheStructureOfTheSearch.Insert("SettingObject1", MotionSampling_["SettingObject1" + DrCr]);
	TheStructureOfTheSearch.Insert("PlaceOfRegistration", MotionSampling_["PlaceOfRegistration" + DrCr]);
	TheStructureOfTheSearch.Insert("MaturityDate", MotionSampling_["MaturityDate" + DrCr]);
	TheStructureOfTheSearch.Insert("Organization", MotionSampling_.Organization);
	
	If MotionSampling_.TakeIntoAccountBusinessTransaction Then
		TheStructureOfTheSearch.Insert("SettingUpBusinessTransaction", MotionSampling_.SettingUpBusinessTransaction);
	EndIf;
	
	If DrCr = "Dr" Then
		TheStructureOfTheSearch.Insert("ThisIsLoan", False);
	Else
		TheStructureOfTheSearch.Insert("ThisIsDebit", False);
	EndIf;
	
	TheStructureOfTheSearch.Insert("ThisIsReverseTransaction", MotionSampling_["ThisIsReverseTransaction" + DrCr]);
	AnalyticsLines_ = AnalyticsTables[RegisterName].Copy(TheStructureOfTheSearch); // ValueTable -
	
	If AnalyticsLines_.Count() = 0
	   And TheStructureOfTheSearch.SettingObject1 = Undefined Then
		TheStructureOfTheSearch.SettingObject1 = Null;
		AnalyticsLines_ = AnalyticsTables[RegisterName].Copy(TheStructureOfTheSearch); // ValueTable -
	EndIf;
	
	PerformAdditionalSelectionOfAnalyticsRows(MotionSampling_, AnalyticsLines_, DrCr);
	
	AnalyticsLines_.Columns.Add("ExtDimension1");
	AnalyticsLines_.Columns.Add("ExtDimension2");
	AnalyticsLines_.Columns.Add("ExtDimension3");
	AnalyticsLines_.Columns.Add("BalancedExtDimension1");
	AnalyticsLines_.Columns.Add("BalancedExtDimension2");
	AnalyticsLines_.Columns.Add("BalancedExtDimension3");
	
	BalancedDrCr = ?(DrCr = "Dr", "Cr", "Dr");
	ExtdimensionExpressionPrefix = ?(MotionSampling_.InvertEntriy, BalancedDrCr, DrCr);
	
	For ExtDimensionNumber = 1 To MotionSampling_["ExtDimensionCount" + DrCr] Do
		ExtDimensionType = MotionSampling_["ExtDimensionType" + DrCr + ExtDimensionNumber];
		ExtraDimensionValue = MotionSampling_["ExtraDimensionValue" + DrCr + ExtDimensionNumber];
		DoNotComputeExtdimension = MotionSampling_["DoNotComputeExtdimension" + DrCr + ExtDimensionNumber];
		ExpressionOfExtdimension = MotionSampling_["ExpressionOfExtdimension" + DrCr + ExtDimensionNumber];
		ThisIsExpressionFromCorrespondence = MotionSampling_["CorExpression" + DrCr + ExtDimensionNumber];
		
		If Not ThisIsExpressionFromCorrespondence And ValueIsFilled(ExpressionOfExtdimension) Then
			NormalizeExpressionExtdimension(ExpressionOfExtdimension, QueryOptions, ExtdimensionExpressionPrefix);
		EndIf;
		
		For Each AnalyticsLine_ In AnalyticsLines_ Do
			If DoNotComputeExtdimension Then
				ExtdimensionLines = ExtraDimensionValue;
			ElsIf ValueIsFilled(ExpressionOfExtdimension) Then
				If ThisIsExpressionFromCorrespondence Then
					ExtdimensionLines = Undefined;
				Else
					ExtdimensionLines = AnalyticsLine_[QueryOptions.AllExpressionsAreExtdimension[ExpressionOfExtdimension]];
				EndIf;
			Else
				ExtdimensionLines = AnalyticsLine_[QueryOptions.AllKindsOfExtdimension[ExtDimensionType].Name];
			EndIf;
			
			AnalyticsLine_["ExtDimension" + ExtDimensionNumber] = ?(ValueIsFilled(ExtdimensionLines), ExtdimensionLines, Undefined);
			AnalyticsLine_.LineOfBusiness = ?(ValueIsFilled(AnalyticsLine_.LineOfBusiness), AnalyticsLine_.LineOfBusiness, Undefined);
			AnalyticsLine_.Department = ?(ValueIsFilled(AnalyticsLine_.Department), AnalyticsLine_.Department, Undefined);
		EndDo;
	EndDo;
	
	If MotionSampling_["ExtDimensionCount" + DrCr] = 0 Then
		For Each AnalyticsLine_ In AnalyticsLines_ Do
			AnalyticsLine_.LineOfBusiness = ?(ValueIsFilled(AnalyticsLine_.LineOfBusiness), AnalyticsLine_.LineOfBusiness, Undefined);
			AnalyticsLine_.Department = ?(ValueIsFilled(AnalyticsLine_.Department), AnalyticsLine_.Department, Undefined);
		EndDo;
	EndIf;
	
	ThereAreCorExpressions = False;
	
	For ExtDimensionNumber = 1 To MotionSampling_["ExtDimensionCount" + BalancedDrCr] Do
		ThereIsExpressionForCorrespondence = MotionSampling_["CorExpression" + BalancedDrCr + ExtDimensionNumber];
		CorExpressionOfExtdimension = MotionSampling_["ExpressionOfExtdimension" + BalancedDrCr + ExtDimensionNumber];
		
		If ThereIsExpressionForCorrespondence And ValueIsFilled(CorExpressionOfExtdimension) Then
			NormalizeExpressionExtdimension(CorExpressionOfExtdimension, QueryOptions, ExtdimensionExpressionPrefix);
			ThereAreCorExpressions = True;
		Else
			Continue;
		EndIf;
		
		For Each AnalyticsLine_ In AnalyticsLines_ Do
			CorExtdimensionLines = AnalyticsLine_[QueryOptions.AllExpressionsAreExtdimension[CorExpressionOfExtdimension]];
			AnalyticsLine_["BalancedExtDimension" + ExtDimensionNumber] = ?(ValueIsFilled(CorExtdimensionLines), CorExtdimensionLines, Undefined);
		EndDo;
	EndDo;
	
	If AnalyticsLines_.Count() > 1 Then
		GroupColumns = "LineOfBusiness,Department,ExtDimension1,ExtDimension2,ExtDimension3";
		If ThereAreCorExpressions Then
			GroupColumns = GroupColumns + ",BalancedExtDimension1,BalancedExtDimension2,BalancedExtDimension3";
		EndIf;
		TotalingColumns = "SumMan,SumCompl,SumCurr,Count";
		AnalyticsLines_.GroupBy(GroupColumns, TotalingColumns);
		SelectAnalyticsRowsByAmounts(MotionSampling_, AnalyticsLines_, DrCr);
	EndIf;
	
	Return AnalyticsLines_;
	
EndFunction

// The selection conditions in this procedure must correspond to the additional conditions for joining records in the correspondence formation procedure
//
Procedure PerformAdditionalSelectionOfAnalyticsRows(MotionSampling_, AnalyticsLines_, DrCr)
	
	If Not MotionSampling_.TakeIntoAccountBusinessTransaction Then
		RowsCount = AnalyticsLines_.Count();
		For ReverseIndex = 1 To RowsCount Do
			AnalyticsLine_ = AnalyticsLines_[RowsCount - ReverseIndex];
			If ValueIsFilled(AnalyticsLine_.SettingUpBusinessTransaction)
				And AnalyticsLine_.SettingUpBusinessTransaction <> MotionSampling_.SettingUpBusinessTransaction Then
				AnalyticsLines_.Delete(AnalyticsLine_);
			EndIf;
		EndDo;
	EndIf;
	
	SelectAnalyticsRowsByAmounts(MotionSampling_, AnalyticsLines_, DrCr);
	
EndProcedure

Procedure SelectAnalyticsRowsByAmounts(MotionSampling_, AnalyticsLines_, DrCr)
	
	If AnalyticsLines_.Count() > 1
	And Not MotionSampling_["ComplexEntry" + DrCr] Then
		AnalyticsWithMovementSums = New Array();
		
		For Each AnalyticsLine_ In AnalyticsLines_ Do
			If AnalyticsLine_.SumMan = MotionSampling_["AmountOfManMovement" + DrCr]
			   And AnalyticsLine_.SumCompl = MotionSampling_["AmountOfLocalTraffic" + DrCr] Then
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

Procedure AddTransactionWithError(TableOfTransactions, MotionSampling_, ErrorText, ParametersForGeneratingTransactions)
	
	NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
	FillPropertyValues(NewEntry, MotionSampling_, "ChartOfAccounts,Period,Organization,Recorder");
	
	TransactionStatus_ = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken;
	
	FinancialAccountingPostingServer.AddTransactionError(NewEntry, ErrorText);
	FinancialAccountingPostingServer.FillInTransactionStatus(NewEntry, TransactionStatus_);
	FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
	
EndProcedure

Procedure AddSimpleEntriy(TableOfTransactions, MotionSampling_, AnalyticsLines_Dr, AnalyticsLines_Cr, ParametersForGeneratingTransactions)
	
	CurrenciesOfOperationalAccounting = FinancialAccountingByBalanceSheetRegisterData.CurrenciesOfOperationalAccounting(MotionSampling_.Organization);
	AccountingCurrenciesOnChartOfAccounts = FinancialAccountingServerCached.AccountingCurrencies(MotionSampling_.ChartOfAccounts, MotionSampling_.Organization);

	FunctionalSum = FunctionalSum(MotionSampling_, CurrenciesOfOperationalAccounting, AccountingCurrenciesOnChartOfAccounts);
	PresentationAmount = PresentationAmount(MotionSampling_, CurrenciesOfOperationalAccounting, AccountingCurrenciesOnChartOfAccounts);
	
	NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
	
	FillInBalanceMeasurementsAndDetails(NewEntry, MotionSampling_);
	FillBalanceResources(NewEntry, FunctionalSum, PresentationAmount, AccountingCurrenciesOnChartOfAccounts);
	
	FillInUnbalancedDimensionsAndResources(NewEntry, MotionSampling_, MotionSampling_, AnalyticsLines_Dr[0], "Dr");
	FillInUnbalancedDimensionsAndResources(NewEntry, MotionSampling_, MotionSampling_, AnalyticsLines_Cr[0], "Cr");
	
	FillOutExtdimensionAccounts(NewEntry, MotionSampling_, AnalyticsLines_Dr[0], "Dr");
	FillOutExtdimensionAccounts(NewEntry, MotionSampling_, AnalyticsLines_Cr[0], "Cr");
	
	InvertEntryIfNecessary(NewEntry, MotionSampling_, ParametersForGeneratingTransactions);
	
	FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
	
EndProcedure

Function FunctionalSum(ResourceData, CurrenciesOfOperationalAccounting, CurrenciesOfInternationalAccounting)
	
	If CurrenciesOfInternationalAccounting.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
		Sum = ResourceData.SumMan;
		ResourceCurrency = CurrenciesOfOperationalAccounting.CurrencyOfMan;
	Else //Currency of international accounting.Accountingfunctional currency = Transfers.Types of accounting in a functional currency.VValuteRegl
		Sum = ResourceData.SumCompl;
		ResourceCurrency = CurrenciesOfOperationalAccounting.ComplCurrency;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Sum", Sum);
	Result.Insert("Currency", ResourceCurrency);
	
	Return Result;
	
EndFunction

Function PresentationAmount(ResourceData, CurrenciesOfOperationalAccounting, CurrenciesOfInternationalAccounting, Correspondence = True)
	
	If CurrenciesOfInternationalAccounting.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_
		And CurrenciesOfInternationalAccounting.Presentations = CurrenciesOfOperationalAccounting.CurrencyOfMan Then
		Sum = ResourceData.SumMan;
		ResourceCurrency = CurrenciesOfOperationalAccounting.CurrencyOfMan;
	ElsIf CurrenciesOfInternationalAccounting.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal
		And CurrenciesOfInternationalAccounting.Presentations = CurrenciesOfOperationalAccounting.ComplCurrency Then
		Sum = ResourceData.SumCompl;
		ResourceCurrency = CurrenciesOfOperationalAccounting.ComplCurrency;
	ElsIf CurrenciesOfInternationalAccounting.Presentations = CurrenciesOfOperationalAccounting.CurrencyOfMan Then
		Sum = ResourceData.SumMan;
		ResourceCurrency = CurrenciesOfOperationalAccounting.CurrencyOfMan;
	ElsIf CurrenciesOfInternationalAccounting.Presentations = CurrenciesOfOperationalAccounting.ComplCurrency Then
		Sum = ResourceData.SumCompl;
		ResourceCurrency = CurrenciesOfOperationalAccounting.ComplCurrency;
	ElsIf Correspondence
		And CurrenciesOfInternationalAccounting.Presentations = ResourceData.CurrencyDr Then
		Sum = ResourceData.SumCurrDr;
		ResourceCurrency = ResourceData.CurrencyDr;
	ElsIf Correspondence
		And CurrenciesOfInternationalAccounting.Presentations = ResourceData.CurrencyCr Then
		Sum = ResourceData.SumCurrCr;
		ResourceCurrency = ResourceData.CurrencyCr;
	ElsIf Not Correspondence
		And CurrenciesOfInternationalAccounting.Presentations = ResourceData.Currency Then
		Sum = ResourceData.SumCurr;
		ResourceCurrency = ResourceData.Currency;
	ElsIf CurrenciesOfInternationalAccounting.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
		Sum = ResourceData.SumMan;
		ResourceCurrency = CurrenciesOfOperationalAccounting.CurrencyOfMan;
	Else //Currency of international accounting.Accountingfunctional currency = Transfers.Types of accounting in a functional currency.VValuteRegl
		Sum = ResourceData.SumCompl;
		ResourceCurrency = CurrenciesOfOperationalAccounting.ComplCurrency;
	EndIf;

	Result = New Structure;
	Result.Insert("Sum", Sum);
	Result.Insert("Currency", ResourceCurrency);
	
	Return Result;
	
EndFunction

Procedure FillInBalanceMeasurementsAndDetails(NewEntry, MotionSampling_)
	
	NewEntry.Period = MotionSampling_.Period;
	NewEntry.Recorder = MotionSampling_.Recorder;
	NewEntry.ChartOfAccounts = MotionSampling_.ChartOfAccounts;
	NewEntry.Organization = MotionSampling_.Organization;
	
	If (MotionSampling_.TransactionsWithCorrespondence
			Or MotionSampling_.RegisterNameDr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects()
			Or MotionSampling_.AccountingObjectDr = ChartsOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	   And MotionSampling_.AccountingObjectDr <> ChartsOfCharacteristicTypes.AssetLiabilityItems.ImproperValues Then
		NewEntry.AccountDr = MotionSampling_.GLAccountDr;
	EndIf;
	
	If (MotionSampling_.TransactionsWithCorrespondence
			Or MotionSampling_.RegisterNameCr <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects()
			Or MotionSampling_.AccountingObjectCr = ChartsOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	   And MotionSampling_.AccountingObjectCr <> ChartsOfCharacteristicTypes.AssetLiabilityItems.ImproperValues Then
		NewEntry.AccountCr = MotionSampling_.GLAccountCr;
	EndIf;
	
	NewEntry.Content = MotionSampling_.SettingUpBusinessTransactionPresentation;
	NewEntry.ReversingEntry = MotionSampling_.PropsStorno;
	NewEntry.FinRecordID = "";
	NewEntry.BusinessTransactionSetting = MotionSampling_.SettingUpBusinessTransaction;
	
	If MotionSampling_.ManualSpecificationOfEntry Then
		FinancialAccountingPostingServer.FillInTransactionStatus(NewEntry, 
			Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting);
	EndIf;
	
EndProcedure

Procedure FillBalanceResources(NewEntry, FunctionalSum, PresentationAmount, AccountingCurrenciesOnChartOfAccounts)
	
	NewEntry.Sum = FunctionalSum.Sum;
	NewEntry.CurrencyOfStorageOfAmount = FunctionalSum.Currency;
	NewEntry.CurrencyFunctional = AccountingCurrenciesOnChartOfAccounts.Functional;
	
	NewEntry.PresentationAmount = PresentationAmount.Sum;
	NewEntry.PresentationAmountStorageCurrency = PresentationAmount.Currency;
	NewEntry.PresentationCurrency = AccountingCurrenciesOnChartOfAccounts.Presentations;
	
EndProcedure

Procedure FillInUnbalancedDimensionsAndResources(NewEntry, MotionSampling_, ResourceData, AnalyticsLine_, DrCr, Correspondence = True)
	
	If MotionSampling_["Currency1" + DrCr] Then
		NewEntry["Currency" + DrCr] = ResourceData["Currency" + ?(Correspondence, DrCr, "")];
		NewEntry["CurrencyAmount" + DrCr] = ResourceData["SumCurr" + ?(Correspondence, DrCr, "")];
		If Not ValueIsFilled(NewEntry["Currency" + DrCr])
		   And Not ValueIsFilled(NewEntry["CurrencyAmount" + DrCr]) Then
			NewEntry["Currency" + DrCr] = NewEntry.CurrencyOfStorageOfAmount;
			NewEntry["CurrencyAmount" + DrCr] = NewEntry.Sum;
		EndIf;
	EndIf;
	
	If MotionSampling_["Quantitative" + DrCr] Then
		NewEntry["Count" + DrCr] = ResourceData["Count" + ?(Correspondence, DrCr, "")];
	EndIf;
	
	If MotionSampling_["RegisterName" + DrCr] <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
		If MotionSampling_["AccountingByBusinessUnits" + DrCr] Then
			NewEntry["Department" + DrCr] = AnalyticsLine_.Department;
		EndIf;
		If MotionSampling_["AccountingByLinesOfBusiness" + DrCr] Then
			NewEntry["LineOfBusiness" + DrCr] = AnalyticsLine_.LineOfBusiness;
		EndIf;
		
		BalancedDrCr = ?(DrCr = "Dr", "Cr", "Dr");
		If MotionSampling_["RegisterName" + BalancedDrCr] = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects()
		   And MotionSampling_["AccountingObject" + BalancedDrCr] <> ChartsOfCharacteristicTypes.AssetLiabilityItems.ImproperValues Then
			If MotionSampling_["AccountingByBusinessUnits" + BalancedDrCr] Then
				NewEntry["Department" + BalancedDrCr] = AnalyticsLine_.Department;
			EndIf;
			
			If MotionSampling_["AccountingByLinesOfBusiness" + BalancedDrCr] Then
				NewEntry["LineOfBusiness" + BalancedDrCr] = AnalyticsLine_.LineOfBusiness;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillOutExtdimensionAccounts(NewEntry, MotionSampling_, AnalyticsLine_, DrCr)
	
	For ExtDimensionNumber = 1 To MotionSampling_["ExtDimensionCount" + DrCr] Do
		NewEntry["ExtDimensionType" + DrCr + ExtDimensionNumber] = MotionSampling_["ExtDimensionType" + DrCr + ExtDimensionNumber];
		If MotionSampling_["RegisterName" + DrCr] <> FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
			If Not MotionSampling_["CorExpression" + DrCr + ExtDimensionNumber]
			 Or ValueIsFilled(AnalyticsLine_["ExtDimension" + ExtDimensionNumber]) Then
				NewEntry["ExtDimension" + DrCr + ExtDimensionNumber] = AnalyticsLine_["ExtDimension" + ExtDimensionNumber];
			EndIf;
		ElsIf ValueIsFilled(AnalyticsLine_["ExtDimension" + ExtDimensionNumber]) Then
			NewEntry["ExtDimension" + DrCr + ExtDimensionNumber] = AnalyticsLine_["ExtDimension" + ExtDimensionNumber];
		EndIf;
	EndDo;
	
	BalancedDrCr = ?(DrCr = "Dr", "Cr", "Dr");
	
	For CorExtdimensionNumber = 1 To MotionSampling_["ExtDimensionCount" + BalancedDrCr] Do
		If MotionSampling_["CorExpression" + BalancedDrCr + CorExtdimensionNumber]
		And Not ValueIsFilled(NewEntry["ExtDimension" + BalancedDrCr + CorExtdimensionNumber]) Then
			NewEntry["ExtDimension" + BalancedDrCr + CorExtdimensionNumber] = AnalyticsLine_["BalancedExtDimension" + CorExtdimensionNumber];
		EndIf;
	EndDo;
	
	If MotionSampling_["RegisterName" + BalancedDrCr] = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects()
	   And MotionSampling_["AccountingObject" + BalancedDrCr] <> ChartsOfCharacteristicTypes.AssetLiabilityItems.ImproperValues Then
		For CorExtdimensionNumber = 1 To MotionSampling_["ExtDimensionCount" + BalancedDrCr] Do
			If Not ValueIsFilled(NewEntry["ExtDimension" + BalancedDrCr + CorExtdimensionNumber])
				And Not MotionSampling_["DoNotComputeExtdimension" + BalancedDrCr + CorExtdimensionNumber] Then
				For ExtDimensionNumber = 1 To MotionSampling_["ExtDimensionCount" + DrCr] Do
					If MotionSampling_["ExtDimensionType" + BalancedDrCr + CorExtdimensionNumber] = MotionSampling_["ExtDimensionType" + DrCr + ExtDimensionNumber] Then
						NewEntry["ExtDimension" + BalancedDrCr + CorExtdimensionNumber] = AnalyticsLine_["ExtDimension" + ExtDimensionNumber];
						Break;
					EndIf;
				EndDo;
				
				If Not ValueIsFilled(NewEntry["ExtDimension" + BalancedDrCr + CorExtdimensionNumber])
					And MotionSampling_["AccountingObject" + BalancedDrCr] = ChartsOfCharacteristicTypes.AssetLiabilityItems.RetailCustomerAccountsReceivables
					And MotionSampling_["ExtDimensionType" + BalancedDrCr + CorExtdimensionNumber] = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties Then
					NewEntry["ExtDimension" + BalancedDrCr + CorExtdimensionNumber] = Catalogs.Counterparties.RetailCustomer;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure InvertEntryIfNecessary(NewEntry, MotionSampling_, ParametersForGeneratingTransactions)
	
	If MotionSampling_.InvertEntriy Then
		AccountingRegisters.International.InvertEntriy(
			NewEntry,
			ParametersForGeneratingTransactions.InvertedFields,
			ParametersForGeneratingTransactions.InvertedResources,
			ParametersForGeneratingTransactions.ExtDimensionCount);
	EndIf;
	
	If MotionSampling_.InvertTheResourceSign Then
		For Each ResourceName In ParametersForGeneratingTransactions.InvertedResources Do
			If ValueIsFilled(NewEntry[ResourceName]) Then
				NewEntry[ResourceName] = -NewEntry[ResourceName];
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure AddComplexEntriy(TableOfTransactions, MotionSampling_, AnalyticsLines_Dr, AnalyticsLines_Cr, ParametersForGeneratingTransactions);
	
	CurrenciesOfOperationalAccounting = FinancialAccountingByBalanceSheetRegisterData.CurrenciesOfOperationalAccounting(MotionSampling_.Organization);
	AccountingCurrenciesOnChartOfAccounts = FinancialAccountingServerCached.AccountingCurrencies(MotionSampling_.ChartOfAccounts, MotionSampling_.Organization);
	
	If AnalyticsLines_Dr.Count() > 1 Then
		ManyAnalysts = New Structure("DrCr,AnalyticsLines_", "Dr", AnalyticsLines_Dr);
		OneDimension = New Structure("DrCr,AnalyticsLines_", "Cr", AnalyticsLines_Cr);
	Else
		OneDimension = New Structure("DrCr,AnalyticsLines_", "Dr", AnalyticsLines_Dr);
		ManyAnalysts = New Structure("DrCr,AnalyticsLines_", "Cr", AnalyticsLines_Cr);
	EndIf;
	
	ResourcesOfManyAnalysts = FinancialAccountingByBalanceSheetRegisterData.RecalculatedResourcesOfManyAnalysts(MotionSampling_, ManyAnalysts, ParametersForGeneratingTransactions);
	SingleAnalyticsResources = FinancialAccountingByBalanceSheetRegisterData.DistributedResourcesOfSingleAnalytics(MotionSampling_, OneDimension, ResourcesOfManyAnalysts, ParametersForGeneratingTransactions);
	
	AnalyticsRowIndex = 0;
	For Each AnalyticsLine_ In ManyAnalysts.AnalyticsLines_ Do
		FunctionalSum = FunctionalSum(ResourcesOfManyAnalysts[AnalyticsRowIndex], CurrenciesOfOperationalAccounting, AccountingCurrenciesOnChartOfAccounts);
		PresentationAmount = PresentationAmount(ResourcesOfManyAnalysts[AnalyticsRowIndex], CurrenciesOfOperationalAccounting, AccountingCurrenciesOnChartOfAccounts, False);

		NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);

		FillInBalanceMeasurementsAndDetails(NewEntry, MotionSampling_);
		FillBalanceResources(NewEntry, FunctionalSum, PresentationAmount, AccountingCurrenciesOnChartOfAccounts);
		
		FillInUnbalancedDimensionsAndResources(NewEntry, MotionSampling_,
			ResourcesOfManyAnalysts[AnalyticsRowIndex], AnalyticsLine_, ManyAnalysts.DrCr, False);
		FillInUnbalancedDimensionsAndResources(NewEntry, MotionSampling_,
			SingleAnalyticsResources[AnalyticsRowIndex], OneDimension.AnalyticsLines_[0], OneDimension.DrCr, False);
		
		FillOutExtdimensionAccounts(NewEntry, MotionSampling_, AnalyticsLine_, ManyAnalysts.DrCr);
		FillOutExtdimensionAccounts(NewEntry, MotionSampling_, OneDimension.AnalyticsLines_[0], OneDimension.DrCr);
		
		InvertEntryIfNecessary(NewEntry, MotionSampling_, ParametersForGeneratingTransactions);
		
		FinancialAccountingPostingServer.AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
		AnalyticsRowIndex = AnalyticsRowIndex + 1;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion