#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	
	ProvideAssetsToLeaseeLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ProvideAssetsToLeasee2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAssetsLeasedOut(QueryTexts, Registers);
		
		QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		ProvideAssetsToLeaseeLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	GetDocumentData(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
	QueryTexts = New ValueList;
		
	QueryTextTableFACost(Query, QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	
	QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAssetsLeasedOut(QueryTexts, Undefined);
	QueryTextTableOtherExpenses(QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	ProvideAssetsToLeaseeLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

// Generates Registered Records of tables of operations "Calculating the cost of an investment in a lease".
//
// Parameters:
//  DocumentRef - DocumentRef.ProvideAssetsToLeasee2_4 - Document for which movements are generated
//  TempTablesManager	- TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfRegisteredRecordsWhenCalculatingCostOfInvestmentInLease(DocumentRef, TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	FillInInitializationParameters(Query, DocumentRef, Undefined);
	
	CalculateRentalInvestmentCost.SetRequestParameters(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
	QueryTexts = New ValueList;
	
	CalculateRentalInvestmentCost.QueryTextTableOtherExpenses(QueryTexts);
	CalculateRentalInvestmentCost.QueryTextTableOtherIncome(QueryTexts);
	CalculateRentalInvestmentCost.QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts);
	QueryTextTableInvestmentInRent(QueryTexts, Undefined);
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.TempTablesManager = TempTablesManager;
	AddlParameters.OnlyMarkedOnes = True;
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return TablesForRegisteredRecords;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ReturnAssetsFromLeasee2_4.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "the transfer of the asset in the lease."
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Documents.ProvideAssetsToLeasee2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ProvideAssetsToLeasee2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ProvideAssetsToLeasee2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ProvideAssetsToLeasee2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	FieldText = 
	"CASE WHEN DocumentData.LeaseholderIntercompanyARAP
	|		THEN DocumentData.Leaseholder
	|		ELSE DocumentData.Organization
	|	END";
	RedefiningParameterCalculation.Insert("CompanyRecipient", FieldText);
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);
	
	Query.Text =
	"SELECT
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Number                  AS Number,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ContractType            AS ContractType,
	|	DocumentData.ARAPCurrency   AS ARAPCurrency
	|FROM
	|	DocumentDataDetails AS DocumentData";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
		
EndProcedure

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS DocumentsList
	|
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Leaseholder               AS Leaseholder,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.FinanciallyLiablePerson                     AS FinanciallyLiablePerson,
	|	DocumentData.LeaseholderEmployeeInCharge           AS LeaseholderEmployeeInCharge,
	|	DocumentData.LeaseholderBusinessUnit AS LeaseholderBusinessUnit,
	|	DocumentData.LocationAddress    AS LocationAddress,
	|	DocumentData.LocationAddressValue AS LocationAddressValue,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting      AS PostInAccounting,
	|	FALSE                                    AS RecordInTA,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|	DocumentData.ExpenseItemAccounting        AS ExpenseItemAccounting,
	|	DocumentData.ExpensesDimensionAccounting     AS ExpensesDimensionAccounting,
	|	DocumentData.DepartmentACC         AS DepartmentACC,
	|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping AS BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping,
	|	DocumentData.IncomeItem           AS IncomeItem,
	|	DocumentData.DimensionOfRevenue        AS DimensionOfRevenue,
	|	DocumentData.MethodForReflectingMaExpenses AS MethodForReflectingMaExpenses,
	|	DocumentData.ExpenseItemManagementAccounting        AS ExpenseItemManagementAccounting,
	|	DocumentData.ExpensesDimensionManagementAccounting     AS ExpensesDimensionManagementAccounting,
	|	DocumentData.BusinessUnitManagementAccounting         AS BusinessUnitManagementAccounting,
	|	DocumentData.LineOfBusinessManagementAccounting AS LineOfBusinessManagementAccounting,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting AS BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting,
	|	DocumentData.DepreciationAccrualLocalAccounting AS DepreciationAccrualLocalAccounting,
	|	DocumentData.DepreciationAccrualMan AS DepreciationAccrualMan,
	|	DocumentData.Department           AS Department,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|
	|	CASE
	|		WHEN DocumentData.LeaseholderIntercompanyARAP
	|			THEN DocumentData.Leaseholder
	|		ELSE DocumentData.Organization
	|	END AS CompanyRecipient,
	|
	|	DocumentData.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|	DocumentData.LeaseholderIntercompanyARAP AS LeaseholderIntercompanyARAP,
	|	DocumentData.DepreciationAccrualMan = VALUE(Enum.DepreciationAccrualChangeOptions.Valid) AS DepreciationAccrualManagementAccounting,
	|	VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee) AS BusinessOperation,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Contract) = TYPE(Catalog.CounterpartyContracts)
	|				AND DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN CAST(DocumentData.Contract AS Catalog.CounterpartyContracts).ContractType
	|		WHEN VALUETYPE(DocumentData.Contract) = TYPE(Catalog.IntercompanyContracts)
	|				AND DocumentData.Contract <> VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN CAST(DocumentData.Contract AS Catalog.IntercompanyContracts).ContractType
	|		ELSE VALUE(Enum.ContractTypes.EmptyRef)
	|	END AS ContractType,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Contract) = TYPE(Catalog.CounterpartyContracts)
	|				AND DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN CAST(DocumentData.Contract AS Catalog.CounterpartyContracts).ARAPCurrency
	|		WHEN VALUETYPE(DocumentData.Contract) = TYPE(Catalog.IntercompanyContracts)
	|				AND DocumentData.Contract <> VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN CAST(DocumentData.Contract AS Catalog.IntercompanyContracts).ARAPCurrency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS ARAPCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses) AS RetirementItem,
	|	CASE
	|		WHEN &TransferForLeaseUnderFAS25
	|				AND CASE
	|					WHEN VALUETYPE(DocumentData.Contract) = TYPE(Catalog.CounterpartyContracts)
	|							AND DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|						THEN CAST(DocumentData.Contract AS Catalog.CounterpartyContracts).ContractType
	|					WHEN VALUETYPE(DocumentData.Contract) = TYPE(Catalog.IntercompanyContracts)
	|							AND DocumentData.Contract <> VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|						THEN CAST(DocumentData.Contract AS Catalog.IntercompanyContracts).ContractType
	|					ELSE VALUE(Enum.ContractTypes.EmptyRef)
	|				END IN (&TypesOfContractsUnderFSB25)
	|			THEN 0
	|		ELSE 1
	|	END AS FSBU25Coefficient
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.SecurityDepositValue AS SecurityDepositValue,
	|	DocumentTable.FairValueLocal AS FairValueLocal,
	|	DocumentTable.FairValueManag AS FairValueManag,
	|	DocumentTable.RentalPayments AS RentalPayments,
	|	DocumentTable.AdvancePayments AS AdvancePayments,
	|	DocumentTable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	DocumentTable.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableServicePaymentSchedule
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.RentalService			AS RentalService,
	|	DocumentTable.RentalServiceVAT		AS RentalServiceVAT
	|
	|INTO DocumentDataTableServicePaymentSchedule
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4.ServicePaymentSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableScheduleOfAccrualOfServices
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.RentalService			AS RentalService,
	|	DocumentTable.RentalServiceVAT		AS RentalServiceVAT
	|
	|INTO DocumentDataTableScheduleOfAccrualOfServices
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4.ServiceAccrualSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableScheduleOfAccrualOfInterest
	QueryText =
	"SELECT
	|	DocumentTable.Ref					AS Ref,
	|	DocumentTable.Date					AS Date,
	|	DocumentTable.FixedAsset		AS FixedAsset,
	|	DocumentTable.Interests				AS Interests
	|
	|INTO DocumentDataTableScheduleOfAccrualOfInterest
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4.InterestAccrualSchedule AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters()

	ValuesOfHoldingParameters = New Structure;
	NonCurrentAssets.AddValuesOfPaymentParametersWhenDebitingFA(ValuesOfHoldingParameters);
	
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ProvideAssetsToLeasee2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Chuyển giao TSCĐ cho thuê';
															|ru = 'Передача ОС в аренду';
															|en = 'Provide assets to lessee'; fa = 'واگذاری دارایی‌ها به مستأجر';
															|it = 'Trasferimento immobilizzazioni in affitto';
															|pl = 'Przekazanie środków trwałych do dzierżawy';
															|tr = 'Sabit kıymetlerin kiralayana temini'"));
	
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses",GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherAssetsAndLiabilities",GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	ValuesOfHoldingParameters.Insert("UseTraceableImportedGoodsAccounting",GetFunctionalOption("UseTraceableImportedGoodsAccounting"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);

	ValuesOfHoldingParameters.Insert("HO_RevaluationOfFI", Enums.BusinessTransactions.RevaluationOfFinancialInstruments);
	ValuesOfHoldingParameters.Insert("SettingUpHO_RevaluationOfFI", Catalogs.BusinessTransactionsSettings.RevaluationOfFinancialInstruments);
	
	ValuesOfHoldingParameters.Insert("BO_ProvideAssetsToLeasee", Enums.BusinessTransactions.ProvideAssetsToLeasee);
	ValuesOfHoldingParameters.Insert("SettingUpHO_TransferOSToLease", Catalogs.BusinessTransactionsSettings.ProvideAssetsToLeasee);
	
	ValuesOfHoldingParameters.Insert("BO_FixedAssetsCostParameterChange", Enums.BusinessTransactions.FixedAssetsCostParameterChange);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ChangingFACostParameters", Catalogs.BusinessTransactionsSettings.FixedAssetsCostParameterChange);
	
	ValuesOfHoldingParameters.Insert("BO_FixedAssetDepreciationParameterChange", Enums.BusinessTransactions.FixedAssetDepreciationParameterChange);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ChangingFADepreciationParameters", Catalogs.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange);
	
	ValuesOfHoldingParameters.Insert("SettingUpHO_SelectionOfNGLV", Catalogs.BusinessTransactionsSettings.DefineNonGuaranteedResidualValue);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AccrualOfInterestOnProfitableLeases", Catalogs.BusinessTransactionsSettings.AccrueProfitableRentalInterest);
	
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	
	ValuesOfHoldingParameters.Insert("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	ValuesOfHoldingParameters.Insert("TransferForLeaseUnderFAS25", GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25"));

	Return ValuesOfHoldingParameters;
	
EndFunction

#Region RequestTextsForConducting

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Date             AS Date,
	|	DocumentData.Ref           AS Ref,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Department    AS Department,
	|	DocumentData.Posted         AS Posted,
	|	&BO_ProvideAssetsToLeasee            AS BusinessOperation,
	|	&MetadataIdentifier         AS RefType,
	|	DocumentData.FixedAssetsEvent        AS FixedAssetsEvent,
	|	FATable.FixedAsset       AS FixedAsset,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	FALSE                             AS AdditionalRecord
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS DocumentData
	|
	|		LEFT JOIN Document.ProvideAssetsToLeasee2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Date             AS Date,
	|	DocumentData.Ref           AS Ref,
	|	DocumentData.Leaseholder        AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	DocumentData.Posted         AS Posted,
	|	&BO_ProvideAssetsToLeasee            AS BusinessOperation,
	|	&MetadataIdentifier         AS RefType,
	|	DocumentData.FixedAssetsEvent        AS FixedAssetsEvent,
	|	FATable.FixedAsset       AS FixedAsset,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	TRUE                           AS AdditionalRecord
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS DocumentData
	|
	|		LEFT JOIN Document.ProvideAssetsToLeasee2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Organization <> DocumentData.Leaseholder
	|	AND DocumentData.LeaseholderIntercompanyARAP";	
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Leaseholder AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	&BO_ProvideAssetsToLeasee AS BusinessOperation,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date   AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.Number,
	|	&MetadataIdentifier,
	|	DocumentData.Leaseholder,
	|	DocumentData.Leaseholder,
	|	DocumentData.Contract,
	|	&BO_ProvideAssetsToLeasee,
	|	UNDEFINED,
	|	DocumentData.ReceivingBusinessUnit,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Comment,
	|	DocumentData.Posted,
	|	DocumentData.DeletionMark,
	|	TRUE,
	|	DocumentData.Date,
	|	&NumberForPrinting,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.LeaseholderIntercompanyARAP
	|	AND DocumentData.Leaseholder <> DocumentData.Organization
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	TTLocationOfFA.FixedAsset            AS FixedAsset,
	|	DocumentData.FinanciallyLiablePerson                             AS FinanciallyLiablePerson,
	|	DocumentData.ReceivingBusinessUnit         AS FixedAssetsLocation,
	|	DocumentData.Leaseholder                       AS Leaseholder,
	|	DocumentData.LeaseholderBusinessUnit         AS LeaseholderBusinessUnit,
	|	DocumentData.LeaseholderEmployeeInCharge                   AS LeaseholderEmployeeInCharge,
	|
	|	CASE 
	|		WHEN DocumentData.LeaseholderIntercompanyARAP AND DocumentData.LocationAddress <> """"	
	|			THEN DocumentData.LocationAddress
	|		ELSE TTLocationOfFA.LocationAddress
	|	END AS LocationAddress,
	|
	|	CASE 
	|		WHEN DocumentData.LeaseholderIntercompanyARAP AND DocumentData.LocationAddress <> """"
	|			THEN DocumentData.LocationAddressValue
	|		ELSE TTLocationOfFA.LocationAddressValue
	|	END AS LocationAddressValue
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTLocationOfFA AS TTLocationOfFA
	|		ON TTLocationOfFA.Ref = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	FixedAssetsAccountingProcedure.FixedAsset         AS FixedAsset,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|	FixedAssetsAccountingProcedure.RunningTimeValue      AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime           AS EstimatedRunningTime,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON DocumentData.Ref = FixedAssetsAccountingProcedure.Ref
	|WHERE
	|	FixedAssetsAccountingProcedure.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	
	QueryText = ProvideAssetsToLeaseeLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText =
		"SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	DocumentData.Organization             AS Organization,
		|	TueAccountingProcedureForOSBU.FixedAsset     AS FixedAsset,
		|
		|	CASE WHEN ExtendedFATable.FixedAsset.OSType IN (
		|			VALUE(Enum.FATypes.Node), VALUE(Enum.FATypes.DepreciationComponent))
		|			AND &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|		THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|		ELSE TueAccountingProcedureForOSBU.BUState
		|	END AS BUState,
		|
		// DepreciationAccrualAccounting
		|	CASE 
		|		WHEN ExtendedFATable.FixedAsset.OSType IN (
		|			VALUE(Enum.FATypes.Node), VALUE(Enum.FATypes.DepreciationComponent))
		|			AND &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN FALSE
		|		WHEN DocumentData.DepreciationAccrualLocalAccounting = VALUE(Enum.DepreciationAccrualChangeOptions.Valid)
		|			AND (TueAccountingProcedureForOSBU.DepreciationAccrualAccounting
		|				OR TTInitialInformationFA.AccountingProcedureAC IN (
		|					VALUE(Enum.FARepaymentProcedure.DepreciationAccrual),
		|					VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		ELSE DocumentData.ExpenseRecordMethodAC
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.ExpenseItemAccounting
		|		ELSE DocumentData.ExpenseItemAccounting
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		ELSE DocumentData.ExpensesDimensionAccounting
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN DocumentData.ReceivingBusinessUnit
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
		|			THEN DocumentData.ReceivingBusinessUnit
		|		ELSE DocumentData.DepartmentACC
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
		|			THEN TTAccountingFA.LineOfBusiness
		|		ELSE DocumentData.LineOfBusinessBookkeeping
		|	END AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTExtendedFATable AS ExtendedFATable
		|		ON ExtendedFATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingFA AS TTAccountingFA
		|		ON TTAccountingFA.Ref = ExtendedFATable.Ref
		|			AND TTAccountingFA.FixedAsset = ExtendedFATable.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS TueAccountingProcedureForOSBU
		|		ON TueAccountingProcedureForOSBU.Ref = ExtendedFATable.Ref
		|			AND TueAccountingProcedureForOSBU.FixedAsset = ExtendedFATable.FixedAsset
		|
		|		INNER JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.Ref = ExtendedFATable.Ref
		|			AND TTInitialInformationFA.FixedAsset = ExtendedFATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationAccrualLocalAccounting IN (
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Valid),
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Stopped))
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	DocumentData.Organization             AS Organization,
		|	TueAccountingProcedureForOSBU.FixedAsset     AS FixedAsset,
		|
		|	CASE WHEN ExtendedFATable.FixedAsset.OSType IN (
		|			VALUE(Enum.FATypes.Node), VALUE(Enum.FATypes.DepreciationComponent))
		|			AND &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|		THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|		ELSE TueAccountingProcedureForOSBU.BUState
		|	END AS BUState,
		|
		// DepreciationAccrualAccounting
		|	CASE 
		|		WHEN ExtendedFATable.FixedAsset.OSType IN (
		|			VALUE(Enum.FATypes.Node), VALUE(Enum.FATypes.DepreciationComponent))
		|			AND &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN FALSE
		|		WHEN DocumentData.DepreciationAccrualLocalAccounting = VALUE(Enum.DepreciationAccrualChangeOptions.Valid)
		|			AND (TueAccountingProcedureForOSBU.DepreciationAccrualAccounting
		|				OR TTInitialInformationFA.AccountingProcedureAC IN (
		|					VALUE(Enum.FARepaymentProcedure.DepreciationAccrual),
		|					VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		ELSE DocumentData.MethodForReflectingMaExpenses
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.ExpenseItemAccounting
		|		ELSE DocumentData.ExpenseItemManagementAccounting
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		ELSE DocumentData.ExpensesDimensionManagementAccounting
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.DepartmentACC
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
		|			THEN DocumentData.Department
		|		ELSE DocumentData.BusinessUnitManagementAccounting
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
		|			THEN TueAccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
		|			THEN TTAccountingFA.LineOfBusiness
		|		ELSE DocumentData.LineOfBusinessManagementAccounting
		|	END AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTExtendedFATable AS ExtendedFATable
		|		ON ExtendedFATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingFA AS TTAccountingFA
		|		ON TTAccountingFA.Ref = ExtendedFATable.Ref
		|			AND TTAccountingFA.FixedAsset = ExtendedFATable.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS TueAccountingProcedureForOSBU
		|		ON TueAccountingProcedureForOSBU.Ref = ExtendedFATable.Ref
		|			AND TueAccountingProcedureForOSBU.FixedAsset = ExtendedFATable.FixedAsset
		|
		|		INNER JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.FixedAsset = ExtendedFATable.Ref
		|			AND TTInitialInformationFA.FixedAsset = ExtendedFATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationAccrualMan IN (
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Valid),
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Stopped))
		|";

	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref               AS Recorder,
	|	DocumentData.Period               AS Period,
	|	DocumentData.Organization          AS Organization,
	|	ExtendedFATable.FixedAsset AS FixedAsset,
	|
	|	CASE WHEN ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|		THEN VALUE(Enum.FixedAssetsStates.Recognized_)
	|		ELSE VALUE(Enum.FixedAssetsStates.TakenOffBooks)
	|	END AS State,
	|
	|	CASE WHEN ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|		THEN DocumentData.DepreciationAccrualManagementAccounting
	|		ELSE FALSE
	|	END AS AccrueDepreciationOrAmortization,
	|
	|	CASE
	|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
	|			THEN TTAccountingProcedureForOsuu.ExpensesPostingMethod
	|			ELSE DocumentData.MethodForReflectingMaExpenses
	|	END AS ExpensesPostingMethod,
	|
	|	CASE
	|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
	|			THEN TTAccountingProcedureForOsuu.ExpenseItem
	|			ELSE DocumentData.ExpenseItemManagementAccounting
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
	|			THEN TTAccountingProcedureForOsuu.DimensionOfExpenses
	|			ELSE DocumentData.ExpensesDimensionManagementAccounting
	|	END AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
	|			THEN DocumentData.ReceivingBusinessUnit
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	|			THEN DocumentData.ReceivingBusinessUnit
	|		ELSE DocumentData.BusinessUnitManagementAccounting
	|	END AS Department,
	|
	|	CASE
	|		WHEN &TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)
	|			THEN TTAccountingProcedureForOsuu.LineOfBusiness
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	|			THEN TTAccountingFA.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessManagementAccounting
	|	END AS LineOfBusiness
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.Ref = ExtendedFATable.Ref
	|			AND TTAccountingFA.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = ExtendedFATable.Ref
	|			AND TTAccountingProcedureForOsuu.FixedAsset = ExtendedFATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.DepreciationAccrualMan IN (
	|		VALUE(Enum.DepreciationAccrualChangeOptions.Valid),
	|		VALUE(Enum.DepreciationAccrualChangeOptions.Stopped))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAssetsLeasedOut(QueryTexts, Registers)

	RegisterName = "AssetsLeasedOut";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref          AS Recorder,
	|	DocumentData.Period          AS Period,
	|	DocumentData.Period          AS TransferDate,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.Leaseholder       AS Counterparty,
	|	DocumentData.Contract         AS Contract,
	|	ISNULL(FATable.SecurityDepositValue, 0) AS SecurityDepositValue,
	|	ExtendedFATable.FixedAsset AS FixedAsset,
	|
	|	VALUE(Enum.FixedAssetsStates.LeasedOut) AS State
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = ExtendedFATable.Ref
	|			AND FATable.FixedAsset = ExtendedFATable.FixedAsset
	|WHERE
	|	ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(Query, QueryTexts, Registers = Undefined)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	ListOfMergeRequests = New Array;
	
	#Region CostWriteOff
	
	QueryText = "SELECT
	|	WriteOffFixedAssetsCost.RecordType                    AS RecordType,
	|	WriteOffFixedAssetsCost.Recorder                    AS Recorder,
	|	WriteOffFixedAssetsCost.Period                         AS Period,
	|	WriteOffFixedAssetsCost.Organization                    AS Organization,
	|	WriteOffFixedAssetsCost.Department                  AS Department,
	|	WriteOffFixedAssetsCost.FixedAsset               AS FixedAsset,
	|	WriteOffFixedAssetsCost.Cost                      AS Cost,
	|	WriteOffFixedAssetsCost.LocalCost                  AS LocalCost,
	|	WriteOffFixedAssetsCost.CostInTaxAccounting                    AS CostInTaxAccounting,
	|	WriteOffFixedAssetsCost.CostPermanentDifference                    AS CostPermanentDifference,
	|	WriteOffFixedAssetsCost.CostTemporaryDifference                    AS CostTemporaryDifference,
	|	WriteOffFixedAssetsCost.CostTargetFinancing                    AS CostTargetFinancing,
	|	WriteOffFixedAssetsCost.CostTargetFinancingTA                  AS CostTargetFinancingTA,
	|	WriteOffFixedAssetsCost.CostTargetFinancingPD                  AS CostTargetFinancingPD,
	|	WriteOffFixedAssetsCost.CostTargetFinancingTD                  AS CostTargetFinancingTD,
	|	WriteOffFixedAssetsCost.PreliminaryCostMan       AS PreliminaryCostMan,
	|	WriteOffFixedAssetsCost.PreliminaryCostLocal   AS PreliminaryCostLocal,
	|	WriteOffFixedAssetsCost.CostRevaluationReserve      AS CostRevaluationReserve,
	|	WriteOffFixedAssetsCost.CostRevaluationReserveLocal  AS CostRevaluationReserveLocal,
	|	WriteOffFixedAssetsCost.CostGainMA               AS CostGainMA,
	|	WriteOffFixedAssetsCost.CostGainLocal           AS CostGainLocal,
	|	WriteOffFixedAssetsCost.DisregardedCostTA       AS DisregardedCostTA,
	|	WriteOffFixedAssetsCost.SecurityDepositValue             AS SecurityDepositValue,
	|	WriteOffFixedAssetsCost.FinancialAccountingGroup         AS FinancialAccountingGroup,
	|	WriteOffFixedAssetsCost.LineOfBusiness        AS LineOfBusiness,
	|	WriteOffFixedAssetsCost.Leaseholder                      AS Leaseholder,
	|	WriteOffFixedAssetsCost.CorCounterparty                  AS CorCounterparty,
	|	WriteOffFixedAssetsCost.BusinessOperation          AS BusinessOperation,
	|	WriteOffFixedAssetsCost.RecordInLocalAccounting             AS RecordInLocalAccounting,
	|	WriteOffFixedAssetsCost.RecordInManAccounting              AS RecordInManAccounting,
	|	WriteOffFixedAssetsCost.FinRecordID         AS FinRecordID,
	|	WriteOffFixedAssetsCost.BusinessTransactionSetting AS BusinessTransactionSetting 
	|FROM &SubqueryText AS WriteOffFixedAssetsCost
	|
	|INNER JOIN DocumentDataDetails AS DocumentData
	|	ON WriteOffFixedAssetsCost.Recorder = DocumentData.Ref
	|		AND &TransferForLeaseUnderFAS25
	|		AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)";
	
	SubqueryText = NonCurrentAssetsInternal.TextOfRequestToDeductCostOfFA(QueryTexts, Query);
	QueryText = StrReplace(QueryText, "&SubqueryText", "(" + SubqueryText + ")");
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion

	#Region ChangingTenantSGFUI
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Department                      AS Department,
	|	ExtendedFATable.FixedAsset              AS FixedAsset,
	|
	|	FACost.Cost*DocumentData.FSBU25Coefficient     AS Cost,
	|	FACost.LocalCost*DocumentData.FSBU25Coefficient AS LocalCost,
	|	FACost.CostInTaxAccounting                            AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                            AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference
	|		- FACost.LocalCost*(1 - DocumentData.FSBU25Coefficient) AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                            AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                          AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                          AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                          AS CostTargetFinancingTD,
	|
	|	FACost.PreliminaryCostMan               AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal           AS PreliminaryCostLocal,
	|
	|	FACost.CostRevaluationReserve              AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal          AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	0                                                  AS DisregardedCostTA,
	|	0                                                  AS SecurityDepositValue,
	|
	|	FAAccountingParameters.FinancialAccountingGroup            AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness           AS LineOfBusiness,
	|	UNDEFINED                                       AS Leaseholder,
	|	UNDEFINED                                       AS CorCounterparty,
	|
	|	&BO_FixedAssetsCostParameterChange                 AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	ExtendedFATable.RowID           AS FinRecordID,
	|	&SettingUpHO_ChangingFACostParameters        AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref 
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = ExtendedFATable.Ref
	|			AND FACost.AccountingObject = ExtendedFATable.FixedAsset
	|WHERE
	|	ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	ExtendedFATable.FixedAsset              AS FixedAsset,
	|
	|	FACost.Cost*DocumentData.FSBU25Coefficient     AS Cost,
	|	FACost.LocalCost*DocumentData.FSBU25Coefficient AS LocalCost,
	|	FACost.CostInTaxAccounting                            AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                            AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference 
	|		- FACost.LocalCost*(1 - DocumentData.FSBU25Coefficient) AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                            AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                          AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                          AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                          AS CostTargetFinancingTD,
	|
	|	FACost.PreliminaryCostMan               AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal           AS PreliminaryCostLocal,
	|
	|	FACost.CostRevaluationReserve              AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal          AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	0                                                  AS DisregardedCostTA,
	|	0                                                  AS SecurityDepositValue,
	|
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness           AS LineOfBusiness,
	|	DocumentData.Leaseholder                          AS Leaseholder,
	|	UNDEFINED                                       AS CorCounterparty,
	|
	|	&BO_FixedAssetsCostParameterChange                 AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	ExtendedFATable.RowID           AS FinRecordID,
	|	&SettingUpHO_ChangingFACostParameters        AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = ExtendedFATable.Ref
	|			AND FACost.AccountingObject = ExtendedFATable.FixedAsset
	|WHERE
	|	ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	ExtendedFATable.FixedAsset              AS FixedAsset,
	|
	|	0                                                  AS Cost,
	|	0                                                  AS LocalCost,
	|	0                                                  AS CostInTaxAccounting,
	|	0                                                  AS CostPermanentDifference,
	|	0                                                  AS CostTemporaryDifference,
	|	0                                                  AS CostTargetFinancing,
	|	0                                                  AS CostTargetFinancingTA,
	|	0                                                  AS CostTargetFinancingPD,
	|	0                                                  AS CostTargetFinancingTD,
	|
	|	0                                                  AS PreliminaryCostMan,
	|	0                                                  AS PreliminaryCostLocal,
	|
	|	0                                                  AS CostRevaluationReserve,
	|	0                                                  AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	0                                                  AS DisregardedCostTA,
	|	ISNULL(FATable.SecurityDepositValue, 0)          AS SecurityDepositValue,
	|
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness           AS LineOfBusiness,
	|	DocumentData.Leaseholder                          AS Leaseholder,
	|	UNDEFINED                                       AS CorCounterparty,
	|
	|	&BO_FixedAssetsCostParameterChange                 AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord              AS FinRecordID,
	|	UNDEFINED                                       AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = ExtendedFATable.Ref
	|			AND FATable.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|WHERE
	|	DocumentData.LeaseholderIntercompanyARAP
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region MovingRevaluationReserveOfCostOfFA
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Department                      AS Department,
	|	ExtendedFATable.FixedAsset              AS FixedAsset,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingTA,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostTargetFinancingTD,
	|
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	FACost.CostGainMA                       AS CostGainMA,
	|	FACost.CostGainLocal                   AS CostGainLocal,
	|
	|	0                                                  AS DisregardedCostTA,
	|	0                                                  AS SecurityDepositValue,
	|
	|	FAAccountingParameters.FinancialAccountingGroup            AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness           AS LineOfBusiness,
	|	UNDEFINED                                       AS Leaseholder,
	|	UNDEFINED                                       AS CorCounterparty,
	|
	|	CASE
	|		WHEN DocumentData.Organization <> DocumentData.CompanyRecipient
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) 
	|	END AS BusinessOperation,
	|
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	ExtendedFATable.RowID           AS FinRecordID,
	|
	|	CASE
	|		WHEN DocumentData.Organization <> DocumentData.CompanyRecipient
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferFixedAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) 
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref 
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = ExtendedFATable.Ref
	|			AND FACost.AccountingObject = ExtendedFATable.FixedAsset
	|WHERE
	|	NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|	AND (DocumentData.FinancialAccountingGroup <> FAAccountingParameters.FinancialAccountingGroup
	|		OR DocumentData.Organization <> DocumentData.CompanyRecipient)
	|	AND (FACost.CostGainMA <> 0 OR FACost.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.CompanyRecipient              AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	ExtendedFATable.FixedAsset              AS FixedAsset,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingTA,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostTargetFinancingTD,
	|
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	FACost.CostGainMA                       AS CostGainMA,
	|	FACost.CostGainLocal                   AS CostGainLocal,
	|
	|	0                                                  AS DisregardedCostTA,
	|	0                                                  AS SecurityDepositValue,
	|
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness           AS LineOfBusiness,
	|	UNDEFINED                                       AS Leaseholder,
	|	UNDEFINED                                       AS CorCounterparty,
	|
	|	CASE
	|		WHEN DocumentData.Organization <> DocumentData.CompanyRecipient
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) 
	|	END AS BusinessOperation,
	|
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	ExtendedFATable.RowID           AS FinRecordID,
	|
	|	CASE
	|		WHEN DocumentData.Organization <> DocumentData.CompanyRecipient
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferFixedAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) 
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = ExtendedFATable.Ref
	|			AND FACost.AccountingObject = ExtendedFATable.FixedAsset
	|
	|WHERE
	|	NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|	AND (DocumentData.FinancialAccountingGroup <> FAAccountingParameters.FinancialAccountingGroup
	|		OR DocumentData.Organization <> DocumentData.CompanyRecipient)
	|	AND (FACost.CostGainMA <> 0 OR FACost.CostGainLocal <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	ListOfMergeRequests = New Array;
	
	#Region WriteOffOfDepreciation
	
	QueryText = "SELECT
	|	FixedAssetDepreciationWriteOff.RecordType              AS RecordType,
	|	FixedAssetDepreciationWriteOff.Recorder              AS Recorder,
	|	FixedAssetDepreciationWriteOff.Period                   AS Period,
	|	FixedAssetDepreciationWriteOff.Organization              AS Organization,
	|	FixedAssetDepreciationWriteOff.Department            AS Department,
	|	FixedAssetDepreciationWriteOff.FixedAsset         AS FixedAsset,
	|	FixedAssetDepreciationWriteOff.Depreciation              AS Depreciation,
	|	FixedAssetDepreciationWriteOff.DepreciationLocal          AS DepreciationLocal,
	|	FixedAssetDepreciationWriteOff.DepreciationInTaxAccounting            AS DepreciationInTaxAccounting,
	|	FixedAssetDepreciationWriteOff.DepreciationPermanentDifferences            AS DepreciationPermanentDifferences,
	|	FixedAssetDepreciationWriteOff.DepreciationTD            AS DepreciationTD,
	|	FixedAssetDepreciationWriteOff.FixedAssetDepreciationTargetFinancing            AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetDepreciationWriteOff.DepreciationTaxAccountingTargetFinancing          AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetDepreciationWriteOff.DepreciationTargetFinancingPD          AS DepreciationTargetFinancingPD,
	|	FixedAssetDepreciationWriteOff.DepreciationOfTargetFinancingTD          AS DepreciationOfTargetFinancingTD,
	|	FixedAssetDepreciationWriteOff.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	FixedAssetDepreciationWriteOff.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|	FixedAssetDepreciationWriteOff.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	FixedAssetDepreciationWriteOff.LineOfBusiness  AS LineOfBusiness,
	|	FixedAssetDepreciationWriteOff.BusinessOperation    AS BusinessOperation,
	|	FixedAssetDepreciationWriteOff.AccrueDepreciation           AS AccrueDepreciation,
	|	FixedAssetDepreciationWriteOff.FinRecordID   AS FinRecordID,
	|	FixedAssetDepreciationWriteOff.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM &SubqueryText AS FixedAssetDepreciationWriteOff
	|
	|INNER JOIN DocumentDataDetails AS DocumentData
	|	ON FixedAssetDepreciationWriteOff.Recorder = DocumentData.Ref
	|		AND &TransferForLeaseUnderFAS25
	|		AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)";
	
	SubqueryText = NonCurrentAssetsInternal.RequestTextForDepreciationWriteOffFA(QueryTexts);
	QueryText = StrReplace(QueryText, "&SubqueryText", "(" + SubqueryText + ")");
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion

	#Region ChangingTenantSGFUI
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	DocumentData.Organization               AS Organization,
	|	DocumentData.Department             AS Department,
	|	ExtendedFATable.FixedAsset     AS FixedAsset,
	|
	|	FixedAssetsDepreciationCharge.Depreciation*DocumentData.FSBU25Coefficient     AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal*DocumentData.FSBU25Coefficient AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD
	|		- FixedAssetsDepreciationCharge.DepreciationLocal*(1-DocumentData.FSBU25Coefficient) AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve     AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|
	|	FAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	&BO_FixedAssetDepreciationParameterChange      AS BusinessOperation,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation              AS AccrueDepreciation,
	|
	|	ExtendedFATable.RowID  AS FinRecordID,
	|	&SettingUpHO_ChangingFADepreciationParameters AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = ExtendedFATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = ExtendedFATable.FixedAsset
	|WHERE
	|	ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	DocumentData.Organization               AS Organization,
	|	DocumentData.ReceivingBusinessUnit   AS Department,
	|	ExtendedFATable.FixedAsset     AS FixedAsset,
	|
	|	FixedAssetsDepreciationCharge.Depreciation*DocumentData.FSBU25Coefficient     AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal*DocumentData.FSBU25Coefficient AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD 
	|		- FixedAssetsDepreciationCharge.DepreciationLocal*(1-DocumentData.FSBU25Coefficient) AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve     AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|
	|	DocumentData.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	FAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	&BO_FixedAssetDepreciationParameterChange      AS BusinessOperation,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation              AS AccrueDepreciation,
	|
	|	ExtendedFATable.RowID  AS FinRecordID,
	|	&SettingUpHO_ChangingFADepreciationParameters AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = ExtendedFATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = ExtendedFATable.FixedAsset
	|WHERE
	|	ExtendedFATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|	OR NOT (&TransferForLeaseUnderFAS25 AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25))
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableImpairmentFA(QueryTexts)

	RegisterName = "ImpairmentFA";
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);

	QueryText = NonCurrentAssetsInternal.TextOfRequestToWriteOffImpairmentOfFA(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"// Moving depreciation
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	&BO_FixedAssetDepreciationParameterChange AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	FAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	ExtendedFATable.FixedAsset AS AssetsLiabilitiesDimension,
	|	FAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	FAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	ExtendedFATable.FixedAsset AS CorDimensionOfAssetsLiabilities,
	|	FAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.CompanyRecipient AS CorCompany,
	|
	|	FixedAssetsDepreciationCharge.Depreciation         AS Sum,
	|	FixedAssetsDepreciationCharge.Depreciation         AS SumMan,
	|	FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = ExtendedFATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = ExtendedFATable.FixedAsset
	|
	|UNION ALL
	|
	|// Moving the cost
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	&BO_FixedAssetsCostParameterChange AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	FAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	ExtendedFATable.FixedAsset AS AssetsLiabilitiesDimension,
	|	FAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	FAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	ExtendedFATable.FixedAsset AS CorDimensionOfAssetsLiabilities,
	|	FAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.CompanyRecipient AS CorCompany,
	|
	|	FACost.Cost             AS Sum,
	|	FACost.Cost             AS SumMan,
	|	FACost.LocalCost + FACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS ExtendedFATable
	|		ON ExtendedFATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS FAAccountingParameters
	|		ON FAAccountingParameters.Ref = ExtendedFATable.Ref
	|			AND FAAccountingParameters.FixedAsset = ExtendedFATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = ExtendedFATable.Ref
	|			AND FACost.AccountingObject = ExtendedFATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfPaymentsForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period				AS ChangeDate,
	|	DocumentData.Contract				AS Contract,
	|	DocumentData.Ref				AS EffectiveContractTerms,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.RentalService		AS RentalService,
	|	ChartTable.RentalServiceVAT	AS RentalServiceVAT
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableServicePaymentSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|WHERE
	|	&TransferForLeaseUnderFAS25
	|		AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfChargesForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period				AS ChangeDate,
	|	DocumentData.Contract				AS Contract,
	|	DocumentData.Ref				AS EffectiveContractTerms,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.RentalService		AS RentalService,
	|	ChartTable.RentalServiceVAT	AS RentalServiceVAT
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableScheduleOfAccrualOfServices AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|WHERE
	|	&TransferForLeaseUnderFAS25
	|		AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfInterestChargesOnIncomeRental";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period				AS ChangeDate,
	|	DocumentData.Contract				AS Contract,
	|	DocumentData.Ref				AS EffectiveContractTerms,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.Interests				AS Interests
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataTableScheduleOfAccrualOfInterest AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|WHERE
	|	&TransferForLeaseUnderFAS25
	|		AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableInvestmentInRent(QueryTexts, Registers)
	
	RegisterName = "InvestmentInRent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTFATableAccordingToFSB25(QueryTexts);
	QueryTextTableTTInterest(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(CalculateRentalInvestmentCost.QueryTextTableInvestmentInRent());

	#Region AssignmentOfRentalInvestmentsToCHIA // Dr <58.AP> - Cr <58.VA>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	0                                      AS RentalPayments,
	|	ExpenseAmount.LocalExpenses              AS RentalPaymentsLocal,
	|	ExpenseAmount.ManSExpenses               AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	0                                      AS InterestDiscount,
	|	0                                      AS InterestDiscountLocal,
	|	0                                      AS InterestDiscountMan,
	|	&SettingUpHO_TransferOSToLease         AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATableAccordingToFSB25 AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN ExpenseAmount AS ExpenseAmount
	|		ON FATable.FixedAsset = ExpenseAmount.FixedAsset
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region DefineNonGuaranteedResidualValue // Dr <58.NGLS> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	0                                      AS RentalPayments,
	|	FATable.NonGuaranteedResidualValueLocal                     AS RentalPaymentsLocal,
	|	FATable.NonGuaranteedResidualValueManag                      AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	0                                      AS InterestDiscount,
	|	0                                      AS InterestDiscountMan,
	|	0                                      AS InterestDiscountLocal,
	|	&SettingUpHO_SelectionOfNGLV             AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATableAccordingToFSB25 AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	&TransferForLeaseUnderFAS25
	|	AND (FATable.NonGuaranteedResidualValueLocal <> 0 OR FATable.NonGuaranteedResidualValueManag <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	0                                      AS RentalPayments,
	|	0                                      AS RentalPaymentsLocal,
	|	0                                      AS RentalPaymentsManag,
	|	FATable.NonGuaranteedResidualValueLocal                     AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag                      AS NonGuaranteedResidualValueManag,
	|	0                                      AS InterestDiscount,
	|	0                                      AS InterestDiscountMan,
	|	0                                      AS InterestDiscountLocal,
	|	&SettingUpHO_SelectionOfNGLV             AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATableAccordingToFSB25 AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	&TransferForLeaseUnderFAS25
	|	AND (FATable.NonGuaranteedResidualValueLocal <> 0 OR FATable.NonGuaranteedResidualValueManag <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region AllocationOfInterest // Dr <58.AP> - Cr <58.%>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	FATable.RentalPayments              AS RentalPayments,
	|	TTInterest.LocalInterestRates                AS RentalPaymentsLocal,
	|	TTInterest.ManSInterest                 AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	0                                      AS InterestDiscount,
	|	0                                      AS InterestDiscountLocal,
	|	0                                      AS InterestDiscountMan,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON FATable.Ref = DocumentData.Ref
	|		INNER JOIN TTInterest AS TTInterest
	|		ON FATable.FixedAsset = TTInterest.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Contract                AS Contract,
	|	DocumentData.ARAPCurrency   AS Currency,
	|	FATable.FixedAsset             AS FixedAsset,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	0                                      AS RentalPayments,
	|	0                                      AS RentalPaymentsLocal,
	|	0                                      AS RentalPaymentsManag,
	|	0                                      AS NonGuaranteedResidualValueLocal,
	|	0                                      AS NonGuaranteedResidualValueManag,
	|	TTInterest.Interests                    AS InterestDiscount,
	|	TTInterest.LocalInterestRates                AS InterestDiscountLocal,
	|	TTInterest.ManSInterest                 AS InterestDiscountMan,
	|	&SettingUpHO_AccrualOfInterestOnProfitableLeases AS BusinessTransactionSetting,
	|	FATable.RowID          AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON FATable.Ref = DocumentData.Ref
	|		INNER JOIN TTInterest AS TTInterest
	|		ON FATable.FixedAsset = TTInterest.FixedAsset
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "Recorder";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region GenerationOfTemporaryTablesForPosting

Procedure QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	QueryText = "SELECT
	|	FADisposal.Period AS Period,
	|	FADisposal.RecordType AS RecordType,
	|	FADisposal.Organization AS Organization,
	|	FADisposal.Department AS Department,
	|	FADisposal.ExpenseItem AS ExpenseItem,
	|	FADisposal.DimensionOfExpenses AS DimensionOfExpenses,
	|	FADisposal.LineOfBusiness AS LineOfBusiness,
	|	FADisposal.VATActivityType AS VATActivityType,
	|	FADisposal.AmountIncludingVAT AS AmountIncludingVAT,
	|	FADisposal.AmountExcludingVAT AS AmountExcludingVAT,
	|	FADisposal.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	FADisposal.AmountIncludingVATCompl AS AmountIncludingVATCompl,
	|	FADisposal.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	FADisposal.PermanentDifference AS PermanentDifference,
	|	FADisposal.CostTD AS CostTD,
	|	FADisposal.BusinessOperation AS BusinessOperation,
	|	FADisposal.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	FADisposal.FinRecordID AS FinRecordID,
	|	FADisposal.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FADisposal.Recorder AS Recorder
	|FROM &SubqueryText AS FADisposal
	|
	|INNER JOIN DocumentDataDetails AS DocumentData
	|	ON FADisposal.Recorder = DocumentData.Ref
	|		AND &TransferForLeaseUnderFAS25
	|		AND DocumentData.ContractType IN (&TypesOfContractsUnderFSB25)";
	
	SubqueryText = NonCurrentAssetsInternal.QueryTextTableTTInitialOtherExpensesAtDisposalOfFA(QueryTexts);
	QueryText = StrReplace(QueryText, "&SubqueryText", "(" + SubqueryText + ")");
	ListOfMergeRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts);
	
	QueryText = 
	"SELECT
	|	FATable.Ref                       AS Ref,
	|	FATable.LineNumber                  AS LineNumber,
	|	FATable.FixedAsset             AS FixedAsset,
	|	VALUE(Catalog.Assets.EmptyRef) AS FAOwner,
	|
	|	AccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness   AS LineOfBusiness,
	|	AccountingProcedure.RunningTimeValue       AS RunningTimeValue,
	|	AccountingProcedure.EstimatedRunningTime            AS EstimatedRunningTime,
	|
	|	FALocation.Organization          AS Organization,
	|	FALocation.FinanciallyLiablePerson                  AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation      AS FixedAssetsLocation,
	|	FALocation.LocationAddress AS LocationAddress,
	|	FALocation.Leaseholder            AS Leaseholder,
	|
	|	FALSE                                   AS AccrueDepreciation,
	|
	|	UNDEFINED                           AS IncomeItem,
	|	UNDEFINED                           AS DimensionOfRevenue,
	|
	|	0                                      AS AmountManagementAccounting,
	|	0                                      AS ChargeAmountAccounting,
	|	0                                      AS AmountTaxAccounting,
	|	0                                      AS AmountPermanentDifference,
	|	0                                      AS AmountTemporaryDifference,
	|	
	|	FATable.RowID 		   AS RowID
	|	
	|INTO TTFATable
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedure
	|		ON AccountingProcedure.Ref = FATable.Ref
	|			AND AccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = FATable.Ref
	|			AND FALocation.FixedAsset = FATable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref                       AS Ref,
	|	FATable.LineNumber                  AS LineNumber,
	|	NodesComponents.SubAssetComponent           AS FixedAsset,
	|	FATable.FixedAsset             AS FAOwner,
	|
	|	AccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness   AS LineOfBusiness,
	|	AccountingProcedure.RunningTimeValue       AS RunningTimeValue,
	|	AccountingProcedure.EstimatedRunningTime            AS EstimatedRunningTime,
	|
	|	FALocation.Organization          AS Organization,
	|	FALocation.FinanciallyLiablePerson                  AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation      AS FixedAssetsLocation,
	|	FALocation.LocationAddress AS LocationAddress,
	|	FALocation.Leaseholder            AS Leaseholder,
	|
	|	FALSE                                   AS AccrueDepreciation,
	|
	|	UNDEFINED                           AS IncomeItem,
	|	UNDEFINED                           AS DimensionOfRevenue,
	|
	|	0                                      AS AmountManagementAccounting,
	|	0                                      AS ChargeAmountAccounting,
	|	0                                      AS AmountTaxAccounting,
	|	0                                      AS AmountPermanentDifference,
	|	0                                      AS AmountTemporaryDifference,
	|	
	|	NodesComponents.RowID     AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON NodesComponents.Ref = FATable.Ref
	|			AND NodesComponents.FixedAsset = FATable.FixedAsset 
	|		
	|		LEFT JOIN TTAccountingFA AS AccountingProcedure
	|		ON AccountingProcedure.Ref = NodesComponents.Ref 
	|			AND AccountingProcedure.FixedAsset = NodesComponents.SubAssetComponent 
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = NodesComponents.Ref 
	|			AND FALocation.FixedAsset = NodesComponents.SubAssetComponent 
	|
	|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Ref = NodesComponents.Ref 
	|			AND InitialFixedAssetsInformation.FixedAsset = NodesComponents.SubAssetComponent 
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTFATableAccordingToFSB25(QueryTexts)
	
	TableName = "TTFATableAccordingToFSB25";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	QueryTextTableTTCurrencyConversionFactors(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.FairValueLocal AS FairValueLocal,
	|	FATable.FairValueManag AS FairValueManag,
	|	FATable.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag,
	|	FATable.RentalPayments AS RentalPayments,
	|	CAST(FATable.RentalPayments * ISNULL(Coefficients.LocalConversionRatio, 0) AS NUMBER(31, 2)) AS RentalPaymentsLocal,
	|	CAST(FATable.RentalPayments * ISNULL(Coefficients.ManConversionFactor, 0) AS NUMBER(31, 2)) AS RentalPaymentsManag,
	|	FATable.RowID AS RowID
	|INTO TTFATableAccordingToFSB25
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON (Coefficients.Date = DocumentData.Period)
	|			AND (Coefficients.Organization = DocumentData.Organization)
	|			AND (Coefficients.ARAPCurrency = DocumentData.ARAPCurrency)
	|WHERE
	|	&TransferForLeaseUnderFAS25
	|	AND DocumentData.ContractType IN(&TypesOfContractsUnderFSB25)
	|
	|INDEX BY
	|	Ref,
	|	RowID,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTInterest(QueryTexts)
	
	TableName = "TTInterest";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTCurrencyConversionFactors(QueryTexts);
	
	QueryText =
	"SELECT
	|	InterestAccrualSchedule.Ref AS Ref,
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset,
	|	SUM(InterestAccrualSchedule.Interests) AS Interests
	|INTO TTInterestOnSchedule
	|FROM
	|	TableScheduleOfAccrualOfInterest AS InterestAccrualSchedule
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = InterestAccrualSchedule.Ref
	|
	|GROUP BY
	|	InterestAccrualSchedule.Ref,
	|	InterestAccrualSchedule.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestOnSchedule.Ref AS Ref,
	|	TTInterestOnSchedule.FixedAsset AS FixedAsset,
	|	TTInterestOnSchedule.Interests AS Interests,
	|	TTInterestOnSchedule.Interests * ISNULL(Coefficients.LocalConversionRatio, 0) AS LocalInterestRates,
	|	TTInterestOnSchedule.Interests * ISNULL(Coefficients.ManConversionFactor, 0) AS ManSInterest
	|INTO TTInterest
	|FROM
	|	TTInterestOnSchedule AS TTInterestOnSchedule
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTInterestOnSchedule.Ref
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Organization = DocumentData.Organization
	|			AND Coefficients.Date = DocumentData.Period
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTCurrencyConversionFactors(QueryTexts)

	TableName = "TTCurrencyConversionFactors";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Period AS Date
	|INTO PeriodsTable
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|INDEX BY
	|	Organization,
	|	ARAPCurrency,
	|	Date";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, TableName, True);

EndProcedure

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ProvideAssetsToLeaseeLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

Function TextOfReflectionInLocalAccounting() Export
	
	Return ProvideAssetsToLeaseeLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

// Adds print commands.
// 
// Parameters:
// 	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
	ProvideAssetsToLeaseeLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Function GetDataForPrintedFormOS1(PrintParameters, ObjectsArray) Export
	
	Return ProvideAssetsToLeaseeLocalization.GetDataForPrintedFormOS1(PrintParameters, ObjectsArray);
	
EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;

	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";

	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");

	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";

	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
