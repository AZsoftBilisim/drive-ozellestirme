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
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	
	FixedAssetCostAndDepreciationAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.FixedAssetCostAndDepreciationAdjustment") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		FixedAssetCostAndDepreciationAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  Period - Date - The month in which Registered Records are generated
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(Period, TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BegOfYear", BegOfYear(Period));
	
	GetDocumentData(Query);
	CreateDepreciationTablesForPeriod(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(
		Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;

	QueryTexts = New ValueList;
	
	QueryTextTableFACost(QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	
	QueryTextTableInitialFixedAssetsInformation(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Undefined);
	
	QueryTextTableOtherExpenses(QueryTexts);
	QueryTextTableItemisedExpensesLots(QueryTexts);
	QueryTextTableOtherAssetsLiabilities(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	QueryTextTableOtherIncome(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	FixedAssetCostAndDepreciationAdjustmentLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);

EndProcedure

// Adds the command to create the document "adjusting the cost and depreciation of fixed assets".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.FixedAssetCostAndDepreciationAdjustment) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
	
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

#EndRegion

#Region InterfaceImplementation

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

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings	 - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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
	
	FullDocumentName = "Document.FixedAssetCostAndDepreciationAdjustment";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("AdditionalRegistry", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	EndIf;
		
	If QueryText = Undefined Then
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
										RedefiningParameterCalculation,
										TemporaryTableQueryTexts);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);

	Query.Text =
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AdjustmentModeFromPreviousDate AS AdjustmentModeFromPreviousDate,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
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
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentsList
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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionCostIncrease AS AssetsLiabilitiesIncomeDimensionCostIncrease,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionDepreciationDecrease AS AssetsLiabilitiesIncomeDimensionDepreciationDecrease,
	|	DocumentData.DimensionBonusDepreciationDecrease AS DimensionBonusDepreciationDecrease,
	|	DocumentData.DimensionDepreciationIncrease AS DimensionDepreciationIncrease,
	|	DocumentData.DimensionTargetFinancingIncomeIncrease AS DimensionTargetFinancingIncomeIncrease,
	|	DocumentData.DimensionCostDecrease AS DimensionCostDecrease,
	|	DocumentData.DimensionCostIncrease AS DimensionCostIncrease,
	|	DocumentData.DimensionDepreciationDecrease AS DimensionDepreciationDecrease,
	|	DocumentData.DimensionOfRevenueDecreaseInBonusDepreciation AS DimensionOfRevenueDecreaseInBonusDepreciation,
	|	DocumentData.DimensionOfRevenueDecreaseInIncomeTF AS DimensionOfRevenueDecreaseInIncomeTF,
	|	DocumentData.DimensionBonusDepreciation AS DimensionBonusDepreciation,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpensesDepreciationIncrease,
	|	DocumentData.DimensionThisYearDepreciationDecrease AS DimensionThisYearDepreciationDecrease,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpensesCostReduction,
	|	DocumentData.DimensionOfExpensesDecreaseInIncomeTF AS DimensionOfExpensesDecreaseInIncomeTF,
	|	DocumentData.LineOfBusiness_BonusDepreciation AS LineOfBusiness_BonusDepreciation,
	|	DocumentData.LineOfBusinessDepreciationIncrease AS LineOfBusinessDepreciationIncrease,
	|	DocumentData.LineOfBusinessCostIncrease AS LineOfBusinessCostIncrease,
	|	DocumentData.LineOfBusinessDepreciationDecrease AS LineOfBusinessDepreciationDecrease,
	|	DocumentData.LineOfBusinessThisYearDepreciationDecrease AS LineOfBusinessThisYearDepreciationDecrease,
	|	DocumentData.LineOfBusinessBonusDepreciationDecrease AS LineOfBusinessBonusDepreciationDecrease,
	|	DocumentData.LineOfBusinessCostDecrease AS LineOfBusinessCostDecrease,
	|	DocumentData.LineOfBusinessTargetFinancingIncomeIncrease AS LineOfBusinessTargetFinancingIncomeIncrease,
	|	DocumentData.LineOfBusinessTargetFinancingIncomeDecrease AS LineOfBusinessTargetFinancingIncomeDecrease,
	|	DocumentData.Business_UnitBonusDepreciation AS Business_UnitBonusDepreciation,
	|	DocumentData.BusinessUnitDepreciationIncrease AS BusinessUnitDepreciationIncrease,
	|	DocumentData.BusinessUnitCostIncrease AS BusinessUnitCostIncrease,
	|	DocumentData.BusinessUnitDepreciationDecrease AS BusinessUnitDepreciationDecrease,
	|	DocumentData.BusinessUnitThisYearDepreciationDecrease AS BusinessUnitThisYearDepreciationDecrease,
	|	DocumentData.BusinessUnitBonusDepreciationDecrease AS BusinessUnitBonusDepreciationDecrease,
	|	DocumentData.BusinessUnitCostDecrease AS BusinessUnitCostDecrease,
	|	DocumentData.BusinessUnitTargetFinancingIncomeIncrease AS BusinessUnitTargetFinancingIncomeIncrease,
	|	DocumentData.BusinessUnitTargetFinancingIncomeDecrease AS BusinessUnitTargetFinancingIncomeDecrease,
	|	DocumentData.ExpenseParametersMatchAccountingDataBonusDepreciation AS ExpenseParametersMatchAccountingDataBonusDepreciation,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease,
	|	DocumentData.DepreciationAdjustmentForPeriod AS DepreciationAdjustmentForPeriod,
	|	DocumentData.DepreciationIncreaseRecording AS DepreciationIncreaseRecording,
	|	DocumentData.BonusDepreciationIncreaseRecording AS BonusDepreciationIncreaseRecording,
	|	DocumentData.CostIncreaseRecording AS CostIncreaseRecording,
	|	DocumentData.DepreciationDecreaseRecording AS DepreciationDecreaseRecording,
	|	DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods AS SeparateAdjustmentOfCurrentAndPreviousPeriods,
	|	DocumentData.RecordThisYearDepreciationDecreaseAsStorno AS RecordThisYearDepreciationDecreaseAsStorno,
	|	DocumentData.BonusDepreciationDecreaseRecording AS BonusDepreciationDecreaseRecording,
	|	DocumentData.RecordingOfBonusDepreciationDecreaseStorno AS RecordingOfBonusDepreciationDecreaseStorno,
	|	DocumentData.CostDecreaseRecording AS CostDecreaseRecording,
	|	DocumentData.RecordCostDecreaseByReversal AS RecordCostDecreaseByReversal,
	|	DocumentData.RecordCostChangeInTADueToPD AS RecordCostChangeInTADueToPD,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.Department AS Department,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	DocumentData.IncomeLiabilityItemCostIncrease AS IncomeLiabilityItemCostIncrease,
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS IncomeLiabilityItemDepreciationDecrease,
	|	DocumentData.IncomeLiabilityItemBonusDepreciationDecrease AS IncomeLiabilityItemBonusDepreciationDecrease,
	|	DocumentData.IncomeLiabilityItemTargetFinancingIncomeDecrease AS IncomeLiabilityItemTargetFinancingIncomeDecrease,
	|	DocumentData.AssetExpenseItemCostDecrease AS AssetExpenseItemCostDecrease,
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS AssetExpenseItemDepreciationIncrease,
	|	DocumentData.ExpenseItemThisYearDepreciationDecrease AS ExpenseItemThisYearDepreciationDecrease,
	|	DocumentData.AssetExpenseItemCostReduction AS AssetExpenseItemCostReduction,
	|	DocumentData.AssetExpenseItemTargetFinancingIncomeIncrease AS AssetExpenseItemTargetFinancingIncomeIncrease,
	|	DocumentData.IncomeLedgerAccountsSettingsCostIncrease AS IncomeLedgerAccountsSettingsCostIncrease,
	|	DocumentData.IncomeLedgerAccountsSettingsDepreciationDecrease AS IncomeLedgerAccountsSettingsDepreciationDecrease,
	|	DocumentData.LedgerAccountSettingsDecreaseInBonusDepreciation AS LedgerAccountSettingsDecreaseInBonusDepreciation,
	|	DocumentData.LedgerExpensesAccountSettingsIncreasedDepreciation AS LedgerExpensesAccountSettingsIncreasedDepreciation,
	|	DocumentData.ExpenseLedgerAccountsSettingsIncreaseIncomeTF AS ExpenseLedgerAccountsSettingsIncreaseIncomeTF,
	|	DocumentData.ExpenseLedgerAccountsSettingsCostDecrease AS ExpenseLedgerAccountsSettingsCostDecrease,
	|	DocumentData.FixedAssetKind AS FixedAssetKind,
	|	DocumentData.AdjustmentModeFromPreviousDate AS AdjustmentModeFromPreviousDate,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.ApplicationOfTargetFinancing AS ApplicationOfTargetFinancing,
	|	DocumentData.CostAdjustment AS CostAdjustment,
	|	DocumentData.AdjustmentOfInitialCost AS AdjustmentOfInitialCost,
	|	DocumentData.DepreciationAdjustment AS DepreciationAdjustment,
	|	DocumentData.BonusDepreciationAdjustment AS BonusDepreciationAdjustment,
	|	DocumentData.AdjustmentOfDepreciationCalculationParameters AS AdjustmentOfDepreciationCalculationParameters,
	|	DocumentData.AdjustTAExpenseAmountOfInvestmentTaxDeduction AS AdjustTAExpenseAmountOfInvestmentTaxDeduction,
	|	DocumentData.PeriodAdjustment AS PeriodAdjustment,
	|	BEGINOFPERIOD(DocumentData.Date, MONTH) AS BeginningOfDocumentPeriod,
	|	ENDOFPERIOD(DocumentData.Date, MONTH) AS EndOfDocumentPeriod,
	|	DocumentData.FixedAssetsEvent.EventKindWithFixedAssets AS EventKindWithFixedAssets,
	|	VALUE(Enum.BusinessTransactions.FixedAssetCostAndDepreciationAdjustment) AS BusinessOperation
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
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
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	UUID(DocumentTable.FixedAsset) AS FAID,
	|	
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|	DocumentTable.CostInTaxAccounting AS CostInTaxAccounting,
	|	DocumentTable.CostPermanentDifference AS CostPermanentDifference,
	|	DocumentTable.CostTargetFinancing AS CostTargetFinancing,
	|	
	|	DocumentTable.DepreciationAsOfTheYearStartBookkeeping AS DepreciationAsOfTheYearStartBookkeeping,
	|	DocumentTable.DepreciationAsOfTheYearStartTaxAccounting AS DepreciationAsOfTheYearStartTaxAccounting,
	|	DocumentTable.PermanentDifferencesInDepreciationAsOfTheYearStart AS PermanentDifferencesInDepreciationAsOfTheYearStart,
	|	DocumentTable.DepreciationAtBeginningOfYearMa AS DepreciationAtBeginningOfYearMa,
	|	DocumentTable.TargetFundsInDepreciationAsOfTheYearStart AS TargetFundsInDepreciationAsOfTheYearStart,
	|
	|	DocumentTable.DepreciationInAccounting AS DepreciationInAccounting,
	|	DocumentTable.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|	DocumentTable.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|	DocumentTable.DepreciationManagementAccounting AS DepreciationManagementAccounting,
	|	DocumentTable.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|
	|	DocumentTable.SecurityDepositValue AS SecurityDepositValue,
	|	DocumentTable.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	DocumentTable.InitialCostTA AS InitialCostTA,
	|	DocumentTable.InitialCostMA AS InitialCostMA,
	|
	|	DocumentTable.DepreciationAllowance AS DepreciationAllowance,
	|	DocumentTable.TAExpenseAmountOfInvestmentTaxDeduction AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	DocumentTable.CostUsedToCalculateDepreciationInAccounting AS CostUsedToCalculateDepreciationInAccounting,
	|	DocumentTable.CostUsedToCalculateDepreciationInManagementAccounting AS CostUsedToCalculateDepreciationInManagementAccounting,
	|	DocumentTable.PermanentDifferencesUsedToCalculateDepreciation AS PermanentDifferencesUsedToCalculateDepreciation
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment.FA AS DocumentTable
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
	
	#Region DocumentDataTableParametersForACPeriod
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Date AS Date,
	|
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|	DocumentTable.CostTargetFinancing AS CostTargetFinancing,
	|
	|	DocumentTable.DepreciationInAccounting AS DepreciationInAccounting,
	|	DocumentTable.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|
	|	DocumentTable.DepreciationLocalUpdate AS DepreciationLocalUpdate,
	|	DocumentTable.FixedAssetDepreciationTargetFinancingUpdate AS FixedAssetDepreciationTargetFinancingUpdate
	|
	|INTO DocumentDataTableParametersForACPeriod
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriodAC AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
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

	#Region TableParametersForPeriodTA
	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	DocumentTable.Date AS Date,
	|	DocumentTable.CostInTaxAccounting AS CostInTaxAccounting,
	|	DocumentTable.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|	DocumentTable.DepreciationAllowance AS DepreciationAllowance,
	|	DocumentTable.DepreciationInTaxAccountingUpdate AS DepreciationInTaxAccountingUpdate
	|
	|INTO TableParametersForPeriodTA
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriodTA AS DocumentTable
	|		ON DocumentTable.Ref = FATable.Ref
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FixedAssetCostAndDepreciationAdjustment"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Điều chỉnh giá trị và khấu hao TSCĐ';
															|ru = 'Корректировка стоимости и амортизации ОС';
															|en = 'Adjust fixed asset cost and depreciation'; fa = 'تعدیل بهای تمام‌شده و استهلاک دارایی ثابت';
															|it = 'Rettifica del costo e dell''ammortamento di Capitali fissi';
															|pl = 'Korekta wartości i amortyzacji ŚT';
															|tr = 'Sabit kıymet maliyet ve amortisman düzeltmesi'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.FixedAssetCostAndDepreciationAdjustment);
	
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.FixedAssetCostAndDepreciationAdjustment);
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("Article6_ProfitLoss_", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	
	ValuesOfHoldingParameters.Insert("BO_CostIncrease", Enums.BusinessTransactions.FixedAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("BO_CostReduction", Enums.BusinessTransactions.FixedAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("BO_ReducingCostOfCF", Enums.BusinessTransactions.ReduceCostOfTargetFinancingOfFixedAssets);
	ValuesOfHoldingParameters.Insert("BO_IncreasedDepreciation", Enums.BusinessTransactions.IncreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("BO_IncreaseInDepreciationOfCF", Enums.BusinessTransactions.IncreaseInDepreciationOfTargetFinancingOfFixedAssets);
	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciation", Enums.BusinessTransactions.DecreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("BO_ChangeInCFRevenues", Enums.BusinessTransactions.ChangeOfDeferredIncomeFromFixedAssetsTargetFinancing);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostIncrease", Catalogs.BusinessTransactionsSettings.FixedAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostReduction", Catalogs.BusinessTransactionsSettings.FixedAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReducingCostOfCF", Catalogs.BusinessTransactionsSettings.ReduceCostOfTargetFinancingOfFixedAssets);
	ValuesOfHoldingParameters.Insert("SettingHO_IncreaseDepreciation", Catalogs.BusinessTransactionsSettings.IncreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("SettingHO_IncreaseDepreciationOfTF", Catalogs.BusinessTransactionsSettings.IncreaseInDepreciationOfTargetFinancingOfFixedAssets);
	ValuesOfHoldingParameters.Insert("SettingHO_ReductionOfDepreciation", Catalogs.BusinessTransactionsSettings.DecreaseInFixedAssetDepreciation);

	ValuesOfHoldingParameters.Insert("BO_IncreaseInDepreciationAtBeginningOfYear", Enums.BusinessTransactions.IncreaseInFixedAssetDepreciationAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("HO_IncreaseInDepreciationOfCentralBankAtBeginningOfYear", Enums.BusinessTransactions.IncreaseInDepreciationOfTargetFinancingOfFixedAssetsAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciationAtBeginningOfYear", Enums.BusinessTransactions.DecreaseInFixedAssetDepreciationAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreaseInDepreciationAtBeginningOfYear", Catalogs.BusinessTransactionsSettings.IncreaseInFixedAssetDepreciationAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreaseInCFDepreciationAtBeginningOfYear", Catalogs.BusinessTransactionsSettings.IncreaseInDepreciationOfTargetFinancingOfFixedAssetsAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReductionOfDepreciationAtBeginningOfYear", Catalogs.BusinessTransactionsSettings.DecreaseInFixedAssetDepreciationAsOfTheYearStart);

	ValuesOfHoldingParameters.Insert("BO_IncludeDepreciationAllowanceInExpenses", Enums.BusinessTransactions.IncludeDepreciationAllowanceInExpenses);
	ValuesOfHoldingParameters.Insert("SettingUpHO_InclusionOfDepreciationPremiumInExpenses", Catalogs.BusinessTransactionsSettings.IncludeDepreciationAllowanceInExpenses);

	ValuesOfHoldingParameters.Insert("BO_DecreaseInBonusDepreciation", Enums.BusinessTransactions.DecreaseInBonusDepreciation);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReductionOfDepreciationPremium", Catalogs.BusinessTransactionsSettings.DecreaseInBonusDepreciation);

	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		If Attributes.AdjustmentModeFromPreviousDate
			And ValueIsFilled(Attributes.BeginOfPeriod) Then
			ValuesOfHoldingParameters.Insert("AdditionalRegistry", StrTemplate(NStr("vi = 'Điều chỉnh từ ngày %1 trước đó';
																					|ru = 'Корректировка с прошлой даты %1';
																					|en = 'Adjustment from previous date %1'; fa = 'Adjustment from previous date %1';
																					|it = 'Adjustment from previous date %1';
																					|pl = 'Adjustment from previous date %1';
																					|tr = '%1 geçmiş tarihinden itibaren düzeltme'"), Format(Attributes.BeginOfPeriod, "DLF=D;")));
		Else
			ValuesOfHoldingParameters.Insert("AdditionalRegistry", "");
		EndIf;

	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Organization             AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	DocumentData.Department           AS Department,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	DocumentData.Date                    AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	DocumentData.Date                    AS RecordingInAccountingDate,
	|	&AdditionalRegistry                    AS More,
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.PostInAccounting             AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInTA             AS RecordInTA,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	DocumentData.AdjustmentModeFromPreviousDate AS IsPatch,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN DocumentData.BeginOfPeriod
	|		ELSE DATETIME(1,1,1)
	|	END AS CorrectionPeriodStart,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DocumentData.Date, MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CorrectionPeriodEnd,
	|
	|	FATable.FixedAsset              AS FixedAsset
	|
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|		LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFACost(QueryTexts)

	RegisterName = "FACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	NonCurrentAssetsInternal.QueryTextTableTTLeasedFA(QueryTexts);

	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);

	ListOfMergeRequests = New Array;
	
	#Region CostIncrease
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_CostIncrease                     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostIncrease.FixedAsset      AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	TTCostIncrease.Cost             AS Cost,
	|	TTCostIncrease.LocalCost         AS LocalCost,
	|	TTCostIncrease.CostInTaxAccounting           AS CostInTaxAccounting,
	|	TTCostIncrease.CostPermanentDifference           AS CostPermanentDifference,
	|
	|	TTCostIncrease.LocalCost
	|		- TTCostIncrease.CostInTaxAccounting
	|		- TTCostIncrease.CostPermanentDifference     AS CostTemporaryDifference,
	|
	|	TTCostIncrease.CostTargetFinancing           AS CostTargetFinancing,
	|	TTCostIncrease.CostTargetFinancingPD         AS CostTargetFinancingPD,
	|
	|	0                                           AS SecurityDepositValue,
	|	0                                           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|			THEN TTLeasedFA.Counterparty
	|		ELSE UNDEFINED
	|	END                                       AS CorCounterparty,
	|
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostIncrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostIncrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTCostIncrease.FinRecordID          AS FinRecordID,
	|	TTCostIncrease.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.Ref = TTCostIncrease.Ref
	|			AND TTLeasedFA.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	(TTCostIncrease.Cost <> 0
	|		OR TTCostIncrease.LocalCost <> 0
	|		OR TTCostIncrease.CostInTaxAccounting <> 0
	|		OR TTCostIncrease.CostPermanentDifference <> 0
	|		OR TTCostIncrease.CostTargetFinancing <> 0
	|		OR TTCostIncrease.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region CostReduction
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_CostReduction                     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostReduction.FixedAsset      AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	TTCostReduction.Cost             AS Cost,
	|	TTCostReduction.LocalCost         AS LocalCost,
	|	TTCostReduction.CostInTaxAccounting           AS CostInTaxAccounting,
	|	TTCostReduction.CostPermanentDifference           AS CostPermanentDifference,
	|
	|	TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference     AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	0 AS SecurityDepositValue,
	|	0 AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|			THEN TTLeasedFA.Counterparty
	|		ELSE UNDEFINED
	|	END                                       AS CorCounterparty,
	|
	|	DocumentData.AssetExpenseItemCostReduction              AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction           AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTCostReduction.FinRecordID          AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.Ref = TTCostReduction.Ref
	|			AND TTLeasedFA.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region CostReductionIsReversed
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_CostReduction                     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostReduction.FixedAsset      AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	-TTCostReduction.Cost             AS Cost,
	|	-TTCostReduction.LocalCost         AS LocalCost,
	|	-TTCostReduction.CostInTaxAccounting           AS CostInTaxAccounting,
	|	-TTCostReduction.CostPermanentDifference           AS CostPermanentDifference,
	|
	|	-(TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference)     AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	0 AS SecurityDepositValue,
	|	0 AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|			THEN TTLeasedFA.Counterparty
	|		ELSE UNDEFINED
	|	END                                       AS CorCounterparty,
	|
	|	DocumentData.AssetExpenseItemCostReduction              AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction           AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTCostReduction.FinRecordID          AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.Ref = TTCostReduction.Ref
	|			AND TTLeasedFA.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion


	#Region IncreaseInCollateralCost
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_CostIncrease                     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostIncrease.FixedAsset      AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	TTCostIncrease.SecurityDepositValue    AS SecurityDepositValue,
	|
	|	0                                           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|			THEN TTLeasedFA.Counterparty
	|		ELSE UNDEFINED
	|	END                                       AS CorCounterparty,
	|
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|
	|	UNDEFINED                                AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.Ref = TTCostIncrease.Ref
	|			AND TTLeasedFA.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	TTCostIncrease.SecurityDepositValue <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region ReductionOfCollateralCost
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_CostReduction                     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostReduction.FixedAsset      AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|	InformationAboutAccounting.Leaseholder                   AS Leaseholder,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	TTCostReduction.SecurityDepositValue    AS SecurityDepositValue,
	|
	|	0                                           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|			THEN TTLeasedFA.Counterparty
	|		ELSE UNDEFINED
	|	END AS CorCounterparty,
	|
	|	UNDEFINED AS CorExpenseItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|	UNDEFINED AS DebitBusinessUnit,
	|	UNDEFINED AS CorLineOfBusiness,
	|
	|	UNDEFINED                                AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.Ref = TTCostReduction.Ref
	|			AND TTLeasedFA.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	TTCostReduction.SecurityDepositValue <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	QueryTextTTIncreaseInDepreciationAtBeginningOfYear(QueryTexts);
	QueryTextTTReductionOfDepreciationAtBeginningOfYear(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region IncreasedDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_IncreasedDepreciation                   AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTIncreasedDepreciation.FixedAsset    AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	TTIncreasedDepreciation.Depreciation         AS Depreciation,
	|	TTIncreasedDepreciation.DepreciationLocal     AS DepreciationLocal,
	|	TTIncreasedDepreciation.DepreciationInTaxAccounting       AS DepreciationInTaxAccounting,
	|	TTIncreasedDepreciation.DepreciationPermanentDifferences       AS DepreciationPermanentDifferences,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		- TTIncreasedDepreciation.DepreciationInTaxAccounting
	|		- TTIncreasedDepreciation.DepreciationPermanentDifferences AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTIncreasedDepreciation.FinRecordID          AS FinRecordID,
	|	TTIncreasedDepreciation.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	TTIncreasedDepreciation.Depreciation <> 0
	|		OR TTIncreasedDepreciation.DepreciationLocal <> 0
	|		OR TTIncreasedDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTIncreasedDepreciation.DepreciationPermanentDifferences <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreaseInDepreciationOfCF
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_IncreaseInDepreciationOfCF                 AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTIncreasedDepreciation.FixedAsset    AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS DepreciationInTaxAccounting,
	|	0 AS DepreciationPermanentDifferences,
	|	0 AS DepreciationTD,
	|
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing       AS FixedAssetDepreciationTargetFinancing,
	|	TTIncreasedDepreciation.DepreciationTargetFinancingPD     AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTIncreasedDepreciation.FinRecordID AS FinRecordID,
	|	&SettingHO_IncreaseDepreciationOfTF AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreasedDepreciation.DepreciationTargetFinancingPD <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region DecreaseInDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_DecreaseInDepreciation                   AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTDecreaseInDepreciation.FixedAsset    AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	TTDecreaseInDepreciation.Depreciation         AS Depreciation,
	|	TTDecreaseInDepreciation.DepreciationLocal     AS DepreciationLocal,
	|	TTDecreaseInDepreciation.DepreciationInTaxAccounting       AS DepreciationInTaxAccounting,
	|	TTDecreaseInDepreciation.DepreciationPermanentDifferences       AS DepreciationPermanentDifferences,
	|
	|	TTDecreaseInDepreciation.DepreciationLocal
	|		- TTDecreaseInDepreciation.DepreciationInTaxAccounting
	|		- TTDecreaseInDepreciation.DepreciationPermanentDifferences AS DepreciationTD,
	|
	|	TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing       AS FixedAssetDepreciationTargetFinancing,
	|	TTDecreaseInDepreciation.DepreciationTargetFinancingPD     AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	UNDEFINED AS CorExpenseItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTDecreaseInDepreciation.FinRecordID          AS FinRecordID,
	|	TTDecreaseInDepreciation.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordThisYearDepreciationDecreaseAsStorno
	|	AND (TTDecreaseInDepreciation.Depreciation <> 0
	|		OR TTDecreaseInDepreciation.DepreciationLocal <> 0
	|		OR TTDecreaseInDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTDecreaseInDepreciation.DepreciationPermanentDifferences <> 0
	|		OR TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTDecreaseInDepreciation.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region ReductionOfDepreciationReverse
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_DecreaseInDepreciation                   AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTDecreaseInDepreciation.FixedAsset    AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	-TTDecreaseInDepreciation.Depreciation        AS Depreciation,
	|	-TTDecreaseInDepreciation.DepreciationLocal    AS DepreciationLocal,
	|	-TTDecreaseInDepreciation.DepreciationInTaxAccounting      AS DepreciationInTaxAccounting,
	|	-TTDecreaseInDepreciation.DepreciationPermanentDifferences      AS DepreciationPermanentDifferences,
	|
	|	-(TTDecreaseInDepreciation.DepreciationLocal
	|		- TTDecreaseInDepreciation.DepreciationInTaxAccounting
	|		- TTDecreaseInDepreciation.DepreciationPermanentDifferences) AS DepreciationTD,
	|
	|	-TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing      AS FixedAssetDepreciationTargetFinancing,
	|	-TTDecreaseInDepreciation.DepreciationTargetFinancingPD    AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	DocumentData.ExpenseItemThisYearDepreciationDecrease AS CorExpenseItem,
	|	DocumentData.DimensionThisYearDepreciationDecrease AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitThisYearDepreciationDecrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessThisYearDepreciationDecrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTDecreaseInDepreciation.FinRecordID          AS FinRecordID,
	|	TTDecreaseInDepreciation.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordThisYearDepreciationDecreaseAsStorno
	|	AND (TTDecreaseInDepreciation.Depreciation <> 0
	|		OR TTDecreaseInDepreciation.DepreciationLocal <> 0
	|		OR TTDecreaseInDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTDecreaseInDepreciation.DepreciationPermanentDifferences <> 0
	|		OR TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTDecreaseInDepreciation.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationAtBeginningOfYear
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_IncreaseInDepreciationAtBeginningOfYear       AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation         AS Depreciation,
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal     AS DepreciationLocal,
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting       AS DepreciationInTaxAccounting,
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences       AS DepreciationPermanentDifferences,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FinRecordID          AS FinRecordID,
	|	TTIncreaseInDepreciationAtBeginningOfYear.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreaseInDepreciationAtBeginningOfYear AS TTIncreaseInDepreciationAtBeginningOfYear
	|		ON TTIncreaseInDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreaseInDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset
	|
	|WHERE
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationAtBeginningOfYearCF
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&HO_IncreaseInDepreciationOfCentralBankAtBeginningOfYear     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS DepreciationInTaxAccounting,
	|	0 AS DepreciationPermanentDifferences,
	|	0 AS DepreciationTD,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing       AS FixedAssetDepreciationTargetFinancing,
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD     AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FinRecordID AS FinRecordID,
	|	&SettingUpHO_IncreaseInCFDepreciationAtBeginningOfYear  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreaseInDepreciationAtBeginningOfYear AS TTIncreaseInDepreciationAtBeginningOfYear
	|		ON TTIncreaseInDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreaseInDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset
	|
	|WHERE
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region DecreaseInDepreciationAtBeginningOfYear
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_DecreaseInDepreciationAtBeginningOfYear       AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTReductionOfDepreciationAtBeginningOfYear.FixedAsset AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	TTReductionOfDepreciationAtBeginningOfYear.Depreciation         AS Depreciation,
	|	TTReductionOfDepreciationAtBeginningOfYear.DepreciationLocal     AS DepreciationLocal,
	|	TTReductionOfDepreciationAtBeginningOfYear.DepreciationInTaxAccounting       AS DepreciationInTaxAccounting,
	|	TTReductionOfDepreciationAtBeginningOfYear.DepreciationPermanentDifferences       AS DepreciationPermanentDifferences,
	|
	|	TTReductionOfDepreciationAtBeginningOfYear.DepreciationLocal
	|		- TTReductionOfDepreciationAtBeginningOfYear.DepreciationInTaxAccounting
	|		- TTReductionOfDepreciationAtBeginningOfYear.DepreciationPermanentDifferences AS DepreciationTD,
	|
	|	TTReductionOfDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing       AS FixedAssetDepreciationTargetFinancing,
	|	TTReductionOfDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD     AS DepreciationTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|
	|	UNDEFINED AS CorExpenseItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS CorLineOfBusiness,
	|
	|	InformationAboutAccounting.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	TTReductionOfDepreciationAtBeginningOfYear.FinRecordID AS FinRecordID,
	|	TTReductionOfDepreciationAtBeginningOfYear.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTReductionOfDepreciationAtBeginningOfYear AS TTReductionOfDepreciationAtBeginningOfYear
	|		ON TTReductionOfDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTReductionOfDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTReductionOfDepreciationAtBeginningOfYear.FixedAsset
	|
	|WHERE
	|	TTReductionOfDepreciationAtBeginningOfYear.Depreciation <> 0
	|		OR TTReductionOfDepreciationAtBeginningOfYear.DepreciationLocal <> 0
	|		OR TTReductionOfDepreciationAtBeginningOfYear.DepreciationInTaxAccounting <> 0
	|		OR TTReductionOfDepreciationAtBeginningOfYear.DepreciationPermanentDifferences <> 0
	|		OR TTReductionOfDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTReductionOfDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableOtherExpenses(QueryTexts, Registers = Undefined)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "AITAmount,Recorder,VariancePeriod";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(QueryTexts, Registers = Undefined)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "Recorder";

	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots(Add_Fields);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOtherAssetsLiabilities(QueryTexts)

	RegisterName = "OtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	
	ListOfMergeRequests = New Array;

	#Region CostIncrease
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_CostIncrease                   AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostIncrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostIncrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeLiabilityItemCostIncrease AS AssetRef,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionCostIncrease AS Dimension,
	|	TTCostIncrease.Cost           AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemCostIncrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|	AND TTCostIncrease.Cost <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region CostReduction
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_CostReduction                   AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS AssetRef,
	|	DocumentData.DimensionCostDecrease AS Dimension,
	|	TTCostReduction.Cost           AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|	AND TTCostReduction.Cost <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region CostReductionIsReversed
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_CostReduction                   AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS AssetRef,
	|	DocumentData.DimensionCostDecrease AS Dimension,
	|	-TTCostReduction.Cost          AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|	AND TTCostReduction.Cost <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreasedDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_IncreasedDepreciation                 AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS AssetRef,
	|	DocumentData.DimensionDepreciationIncrease AS Dimension,
	|	TTIncreasedDepreciation.Depreciation       AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|	AND TTIncreasedDepreciation.Depreciation <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region DecreaseInDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_DecreaseInDepreciation                 AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS AssetRef,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionDepreciationDecrease AS Dimension,
	|	TTDecreaseInDepreciation.Depreciation       AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|	AND TTDecreaseInDepreciation.Depreciation <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
			
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	
	ListOfMergeRequests = New Array;

	#Region CostIncrease
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostIncrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostIncrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeLiabilityItemCostIncrease AS AssetRef,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionCostIncrease AS Dimension,
	|	DocumentData.IncomeLedgerAccountsSettingsCostIncrease AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTCostIncrease.LocalCost
	|		+ TTCostIncrease.CostTargetFinancing   AS SumCompl,
	|
	|	TTCostIncrease.CostPermanentDifference
	|		+ TTCostIncrease.CostTargetFinancingPD AS PermanentDifference,
	|
	|	TTCostIncrease.LocalCost
	|		+ TTCostIncrease.CostTargetFinancing
	|		- TTCostIncrease.CostInTaxAccounting
	|		- TTCostIncrease.CostPermanentDifference
	|		- TTCostIncrease.CostTargetFinancingPD AS CostTD,
	|
	|	TTCostIncrease.Cost AS SumMan,
	|	TTCostIncrease.Cost AS AmountIncludingVAT,
	|	TTCostIncrease.Cost AS AmountExcludingVAT,
	|
	|	TTCostIncrease.FinRecordID AS FinRecordID,
	|	TTCostIncrease.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemCostIncrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND (TTCostIncrease.Cost <> 0
	|		OR TTCostIncrease.LocalCost <> 0
	|		OR TTCostIncrease.CostTargetFinancing <> 0
	|		OR TTCostIncrease.CostInTaxAccounting <> 0
	|		OR TTCostIncrease.CostPermanentDifference <> 0
	|		OR TTCostIncrease.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region CostReduction
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS AssetRef,
	|	DocumentData.DimensionCostDecrease AS Dimension,
	|	DocumentData.ExpenseLedgerAccountsSettingsCostDecrease AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTCostReduction.LocalCost
	|		+ TTCostReduction.CostTargetFinancing   AS SumCompl,
	|
	|	TTCostReduction.CostPermanentDifference
	|		+ TTCostReduction.CostTargetFinancingPD AS PermanentDifference,
	|
	|	TTCostReduction.LocalCost
	|		+ TTCostReduction.CostTargetFinancing
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference
	|		- TTCostReduction.CostTargetFinancingPD AS CostTD,
	|
	|	TTCostReduction.Cost AS SumMan,
	|	TTCostReduction.Cost AS AmountIncludingVAT,
	|	TTCostReduction.Cost AS AmountExcludingVAT,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region CostReductionIsReversed
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS AssetRef,
	|	DocumentData.DimensionCostDecrease AS Dimension,
	|	DocumentData.ExpenseLedgerAccountsSettingsCostDecrease AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	-(TTCostReduction.LocalCost
	|		+ TTCostReduction.CostTargetFinancing)   AS SumCompl,
	|
	|	-(TTCostReduction.CostPermanentDifference
	|		+ TTCostReduction.CostTargetFinancingPD) AS PermanentDifference,
	|
	|	-(TTCostReduction.LocalCost
	|		+ TTCostReduction.CostTargetFinancing
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference
	|		- TTCostReduction.CostTargetFinancingPD) AS CostTD,
	|
	|	-TTCostReduction.Cost AS SumMan,
	|	-TTCostReduction.Cost AS AmountIncludingVAT,
	|	-TTCostReduction.Cost AS AmountExcludingVAT,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreasedDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS AssetRef,
	|	DocumentData.DimensionDepreciationIncrease AS Dimension,
	|	DocumentData.LedgerExpensesAccountSettingsIncreasedDepreciation AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		+ TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing AS SumCompl,
	|
	|	TTIncreasedDepreciation.DepreciationPermanentDifferences
	|		+ TTIncreasedDepreciation.DepreciationTargetFinancingPD AS PermanentDifference,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		+ TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing
	|		- TTIncreasedDepreciation.DepreciationInTaxAccounting
	|		- TTIncreasedDepreciation.DepreciationPermanentDifferences
	|		- TTIncreasedDepreciation.DepreciationTargetFinancingPD AS CostTD,
	|
	|	TTIncreasedDepreciation.Depreciation AS SumMan,
	|	TTIncreasedDepreciation.Depreciation AS AmountIncludingVAT,
	|	TTIncreasedDepreciation.Depreciation AS AmountExcludingVAT,
	|
	|	TTIncreasedDepreciation.FinRecordID AS FinRecordID,
	|	TTIncreasedDepreciation.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND (TTIncreasedDepreciation.Depreciation <> 0
	|		OR TTIncreasedDepreciation.DepreciationLocal <> 0
	|		OR TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreasedDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTIncreasedDepreciation.DepreciationPermanentDifferences <> 0
	|		OR TTIncreasedDepreciation.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region DecreaseInDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS AssetRef,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionDepreciationDecrease AS Dimension,
	|	DocumentData.IncomeLedgerAccountsSettingsDepreciationDecrease AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTDecreaseInDepreciation.DepreciationLocal
	|		+ TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing   AS SumCompl,
	|
	|	TTDecreaseInDepreciation.DepreciationPermanentDifferences
	|		+ TTDecreaseInDepreciation.DepreciationTargetFinancingPD AS PermanentDifference,
	|
	|	TTDecreaseInDepreciation.DepreciationLocal
	|		+ TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing
	|		- TTDecreaseInDepreciation.DepreciationInTaxAccounting
	|		- TTDecreaseInDepreciation.DepreciationPermanentDifferences
	|		- TTDecreaseInDepreciation.DepreciationTargetFinancingPD AS CostTD,
	|
	|	TTDecreaseInDepreciation.Depreciation AS SumMan,
	|	TTDecreaseInDepreciation.Depreciation AS AmountIncludingVAT,
	|	TTDecreaseInDepreciation.Depreciation AS AmountExcludingVAT,
	|
	|	TTDecreaseInDepreciation.FinRecordID AS FinRecordID,
	|	TTDecreaseInDepreciation.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND (TTDecreaseInDepreciation.Depreciation <> 0
	|		OR TTDecreaseInDepreciation.DepreciationLocal <> 0
	|		OR TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTDecreaseInDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTDecreaseInDepreciation.DepreciationPermanentDifferences <> 0
	|		OR TTDecreaseInDepreciation.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	
	MergeRequestTexts = New Array;
	
	#Region CostIncrease
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostIncrease                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostIncrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostIncrease
	|	END AS LineOfBusiness,
	|
	|	&Article6_ProfitLoss_                    AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTCostIncrease.FixedAsset     AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&ArticleAP_OS                               AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTCostIncrease.FixedAsset     AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	TTCostIncrease.Cost            AS Sum,
	|	TTCostIncrease.Cost            AS SumMan,
	|	TTCostIncrease.LocalCost        AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	(TTCostIncrease.Cost <> 0
	|		OR TTCostIncrease.LocalCost <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CostReduction
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostReduction                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	InformationAboutAccounting.LineOfBusiness    AS LineOfBusiness,
	|	&ArticleAP_OS                               AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTCostReduction.FixedAsset     AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	DocumentData.DimensionOfExpensesCostReduction AS CorExpenditureDimension,
	|	UNDEFINED                               AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	TTCostReduction.Cost            AS Sum,
	|	TTCostReduction.Cost            AS SumMan,
	|	TTCostReduction.LocalCost        AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	#Region CostReductionIsReversed
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostReduction                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|	UNDEFINED                               AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&ArticleAP_OS AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTCostReduction.FixedAsset     AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	TTCostReduction.Cost            AS Sum,
	|	TTCostReduction.Cost            AS SumMan,
	|	TTCostReduction.LocalCost        AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region IncreasedDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_IncreasedDepreciation                  AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	InformationAboutAccounting.LineOfBusiness    AS LineOfBusiness,
	|	&ArticleAP_OS                               AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTIncreasedDepreciation.FixedAsset   AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&Article6_ProfitLoss_                    AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTIncreasedDepreciation.FixedAsset   AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	TTIncreasedDepreciation.Depreciation        AS Sum,
	|	TTIncreasedDepreciation.Depreciation        AS SumMan,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		+ TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	(TTIncreasedDepreciation.Depreciation <> 0
	|		OR TTIncreasedDepreciation.DepreciationLocal <> 0
	|		OR TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DecreaseInDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_DecreaseInDepreciation                  AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS AssetRef,
	|	DocumentData.DimensionDepreciationDecrease AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesIncomeDimensionDepreciationDecrease AS AssetsLiabilitiesDimension,
	|	UNDEFINED                               AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&ArticleAP_OS                               AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTDecreaseInDepreciation.FixedAsset   AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	TTDecreaseInDepreciation.Depreciation        AS Sum,
	|	TTDecreaseInDepreciation.Depreciation        AS SumMan,
	|
	|	TTDecreaseInDepreciation.DepreciationLocal
	|		+ TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing AS SumCompl
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|WHERE
	|	(TTDecreaseInDepreciation.Depreciation <> 0
	|		OR TTDecreaseInDepreciation.DepreciationLocal <> 0
	|		OR TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
		
	#Region IncreaseInCFRevenues
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostIncrease                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	InformationAboutAccounting.LineOfBusiness    AS LineOfBusiness,
	|	&ArticleAP_OS                               AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTCostIncrease.FixedAsset     AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitTargetFinancingIncomeIncrease
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessTargetFinancingIncomeIncrease
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.AssetExpenseItemTargetFinancingIncomeIncrease AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	DocumentData.DimensionOfExpensesDecreaseInIncomeTF AS CorExpenditureDimension,
	|	UNDEFINED                               AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	0                                          AS Sum,
	|	0                                          AS SumMan,
	|	TTCostIncrease.CostTargetFinancing          AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	TTCostIncrease.CostTargetFinancing <> 0
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	#Region DecreaseInIncomeOfTF
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostReduction                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	InformationAboutAccounting.LineOfBusiness    AS LineOfBusiness,
	|	&Article6_ProfitLoss_                    AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTCostReduction.FixedAsset     AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&ArticleAP_OS                               AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTCostReduction.FixedAsset     AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	0                                          AS Sum,
	|	0                                          AS SumMan,
	|	TTCostReduction.CostTargetFinancing          AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	TTCostReduction.CostTargetFinancing <> 0
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableOtherIncome(QueryTexts)

	RegisterName = "OtherIncome";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	QueryTextTTReductionOfDepreciationAtBeginningOfYear(QueryTexts);
	
	MergeRequestTexts = New Array;
	
	#Region CostIncrease
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostIncrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostIncrease
	|	END AS LineOfBusiness,
	|
	|	&BO_CostIncrease                        AS BusinessOperation,
	|	DocumentData.IncomeLiabilityItemCostIncrease AS IncomeItem,
	|	DocumentData.DimensionCostIncrease AS DimensionOfRevenue,
	|
	|	TTCostIncrease.Cost                AS Sum,
	|	TTCostIncrease.Cost                AS SumMan,
	|	TTCostIncrease.LocalCost
	|		+ TTCostIncrease.CostTargetFinancing        AS SumCompl,
	|
	|	TTCostIncrease.FinRecordID          AS FinRecordID,
	|	TTCostIncrease.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemCostIncrease) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND (TTCostIncrease.Cost <> 0
	|		OR TTCostIncrease.LocalCost <> 0
	|		OR TTCostIncrease.CostTargetFinancing <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	#Region DecreaseInDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS LineOfBusiness,
	|
	|	&BO_DecreaseInDepreciation                      AS BusinessOperation,
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS IncomeItem,
	|	DocumentData.DimensionDepreciationDecrease AS DimensionOfRevenue,
	|
	|	TTDecreaseInDepreciation.Depreciation            AS Sum,
	|
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.CompanyManagementAccounting, FALSE)
	|			THEN 0
	|		ELSE TTDecreaseInDepreciation.Depreciation
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.UseAccountingOfOtherIncomeExpensesInLocalAccounting, FALSE)
	|			THEN 0
	|		WHEN TTDecreaseInDepreciation.AccrueDepreciation
	|			THEN 0
	|		ELSE TTDecreaseInDepreciation.DepreciationLocal + TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing
	|	END AS SumCompl,
	|
	|	TTDecreaseInDepreciation.FinRecordID          AS FinRecordID,
	|	TTDecreaseInDepreciation.BusinessTransactionSetting  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|		LEFT JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	NOT DocumentData.RecordThisYearDepreciationDecreaseAsStorno
	|	AND VALUETYPE(DocumentData.IncomeLiabilityItemDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND (TTDecreaseInDepreciation.Depreciation <> 0
	|		OR (TTDecreaseInDepreciation.DepreciationLocal <> 0 OR TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing <> 0)
	|				AND NOT TTDecreaseInDepreciation.AccrueDepreciation)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DecreaseInDepreciationAtBeginningOfYear
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationDecrease
	|	END AS LineOfBusiness,
	|
	|	&BO_DecreaseInDepreciationAtBeginningOfYear          AS BusinessOperation,
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS IncomeItem,
	|	DocumentData.DimensionDepreciationDecrease AS DimensionOfRevenue,
	|
	|	TTReductionOfDepreciationAtBeginningOfYear.Depreciation            AS Sum,
	|
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.CompanyManagementAccounting, FALSE)
	|			THEN 0
	|		ELSE TTReductionOfDepreciationAtBeginningOfYear.Depreciation
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.UseAccountingOfOtherIncomeExpensesInLocalAccounting, FALSE)
	|			THEN 0
	|		WHEN TTReductionOfDepreciationAtBeginningOfYear.AccrueDepreciation
	|			THEN 0
	|		ELSE TTReductionOfDepreciationAtBeginningOfYear.DepreciationLocal + TTReductionOfDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing
	|	END AS SumCompl,
	|
	|	TTReductionOfDepreciationAtBeginningOfYear.FinRecordID AS FinRecordID,
	|	TTReductionOfDepreciationAtBeginningOfYear.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTReductionOfDepreciationAtBeginningOfYear AS TTReductionOfDepreciationAtBeginningOfYear
	|		ON TTReductionOfDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTReductionOfDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTReductionOfDepreciationAtBeginningOfYear.FixedAsset
	|
	|		LEFT JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND (TTReductionOfDepreciationAtBeginningOfYear.Depreciation <> 0
	|		OR (TTReductionOfDepreciationAtBeginningOfYear.DepreciationLocal <> 0 OR TTReductionOfDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing <> 0)
	|				AND NOT TTReductionOfDepreciationAtBeginningOfYear.AccrueDepreciation)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	#Region DecreaseInIncomeOfTF
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitTargetFinancingIncomeDecrease
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessTargetFinancingIncomeDecrease
	|	END AS LineOfBusiness,
	|
	|	&BO_ChangeInCFRevenues                         AS BusinessOperation,
	|	DocumentData.IncomeLiabilityItemTargetFinancingIncomeDecrease AS IncomeItem,
	|	DocumentData.DimensionOfRevenueDecreaseInIncomeTF AS DimensionOfRevenue,
	|
	|	0                                              AS Sum,
	|	0                                              AS SumMan,
	|	TTCostReduction.CostTargetFinancing              AS SumCompl,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemTargetFinancingIncomeDecrease) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND TTCostReduction.CostTargetFinancing <> 0
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = FixedAssetCostAndDepreciationAdjustmentLocalization.QueryTextTableInitialFixedAssetsInformation(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|	TTInitialInformationFA.AccountingProcedureAC AS AccountingProcedureAC,
		|	TTInitialInformationFA.AccountingProcedureMA AS AccountingProcedureMA,
		|	TTInitialInformationFA.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	TTInitialInformationFA.CommissioningDateAC AS CommissioningDateAC,
		|	TTInitialInformationFA.CommissioningDateMA AS CommissioningDateMA,
		|	TTInitialInformationFA.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	TTInitialInformationFA.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	TTInitialInformationFA.DeregistrationDocumentACC AS DeregistrationDocumentACC,
		|	TTInitialInformationFA.DeregistrationDocumentMA AS DeregistrationDocumentMA,
		|	TTInitialInformationFA.Counterparty AS Counterparty,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN FATable.InitialCostLocalAccounting
		|		ELSE TTInitialInformationFA.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN FATable.InitialCostMA
		|		ELSE TTInitialInformationFA.InitialCostMA
		|	END AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		INNER JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.Ref = FATable.Ref
		|			AND TTInitialInformationFA.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.AdjustmentOfInitialCost
		|	AND (DocumentData.PostInAccounting
		|				AND TTInitialInformationFA.InitialCostLocalAccounting <> FATable.InitialCostLocalAccounting
		|			OR DocumentData.RecordInManAccounting
		|				AND TTInitialInformationFA.InitialCostMA <> FATable.InitialCostMA)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|	TTInitialInformationFA.AccountingProcedureAC AS AccountingProcedureAC,
		|	TTInitialInformationFA.AccountingProcedureMA AS AccountingProcedureMA,
		|	TTInitialInformationFA.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	TTInitialInformationFA.CommissioningDateAC AS CommissioningDateAC,
		|	TTInitialInformationFA.CommissioningDateMA AS CommissioningDateMA,
		|	TTInitialInformationFA.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	TTInitialInformationFA.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	TTInitialInformationFA.DeregistrationDocumentACC AS DeregistrationDocumentACC,
		|	TTInitialInformationFA.DeregistrationDocumentMA AS DeregistrationDocumentMA,
		|	TTInitialInformationFA.Counterparty AS Counterparty,
		|
		|	FATable.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	FATable.InitialCostMA AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		INNER JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.Ref = FATable.Ref
		|			AND TTInitialInformationFA.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.AdjustmentOfInitialCost
		|	AND (TTInitialInformationFA.InitialCostLocalAccounting <> FATable.InitialCostLocalAccounting
		|			OR TTInitialInformationFA.InitialCostMA <> FATable.InitialCostMA)
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	TTOsuuDepreciationParameters.UsefulLifeMonths AS UsefulLifeMonths,
	|	TTOsuuDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	TTOsuuDepreciationParameters.AccelerationFactor AS AccelerationFactor,
	|	TTOsuuDepreciationParameters.DepreciationMethod AS DepreciationMethod,
	|	TTOsuuDepreciationParameters.ResidualValueMan AS ResidualValueMan,
	|	TTOsuuDepreciationParameters.ResidualValueLocal AS ResidualValueLocal,
	|	TTOsuuDepreciationParameters.LastChangeDate AS LastChangeDate,
	|	TTOsuuDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FATable.CostUsedToCalculateDepreciationInManagementAccounting AS CostUsedToCalculateDepreciationManag,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|			THEN FATable.CostUsedToCalculateDepreciationInAccounting
	|		ELSE TTOsuuDepreciationParameters.CostUsedToCalculateDepreciationLocal
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS TTOsuuDepreciationParameters
	|		ON TTOsuuDepreciationParameters.Ref = FATable.Ref
	|			AND TTOsuuDepreciationParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.AdjustmentOfDepreciationCalculationParameters
	|	AND TTOsuuDepreciationParameters.CostUsedToCalculateDepreciationManag <> FATable.CostUsedToCalculateDepreciationInManagementAccounting
	|	AND TTAccountingPolicyOfFinancialAccounting.AccountingPolicyForFixedAssets = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|";

	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTTCostIncrease(QueryTexts)

	TableName = "TTCostIncrease";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTCostAdjustment(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTCostAdjustment.Ref               AS Ref,
	|	TTCostAdjustment.FixedAsset     AS FixedAsset,
	|
	// Cost
	|	CASE 
	|		WHEN TTCostAdjustment.Cost > 0
	|			THEN TTCostAdjustment.Cost
	|		ELSE 0
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN TTCostAdjustment.LocalCost > 0
	|			THEN TTCostAdjustment.LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN DocumentData.RecordCostChangeInTADueToPD
	|			THEN 0
	|		WHEN TTCostAdjustment.CostInTaxAccounting > 0
	|			THEN TTCostAdjustment.CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
	|		WHEN DocumentData.RecordCostChangeInTADueToPD
	|			THEN 0
	|		WHEN TTCostAdjustment.LocalCost > 0
	|			THEN TTCostAdjustment.CostPermanentDifference
	|		WHEN TTCostAdjustment.LocalCost = 0
	|				AND TTCostAdjustment.CostInTaxAccounting > 0
	|			THEN TTCostAdjustment.CostPermanentDifference
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	// CostTargetFinancing
	|	CASE 
	|		WHEN TTCostAdjustment.CostTargetFinancing > 0
	|			THEN TTCostAdjustment.CostTargetFinancing
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	// CostTargetFinancingPD
	|	CASE 
	|		WHEN TTCostAdjustment.CostTargetFinancingPD > 0
	|			THEN TTCostAdjustment.CostTargetFinancingPD
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	// SecurityDepositValue
	|	CASE 
	|		WHEN TTCostAdjustment.SecurityDepositValue > 0
	|			THEN TTCostAdjustment.SecurityDepositValue
	|		ELSE 0
	|	END AS SecurityDepositValue,
	|
	|	TTCostAdjustment.RowID  AS FinRecordID,
	|	&SettingUpHO_CostIncrease             AS BusinessTransactionSetting
	|
	|INTO TTCostIncrease
	|
	|FROM
	|	TTCostAdjustment AS TTCostAdjustment
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTCostAdjustment.Ref
	|
	|WHERE
	|	DocumentData.CostIncreaseRecording
	|
	|	AND (TTCostAdjustment.Cost > 0
	|		OR TTCostAdjustment.LocalCost > 0
	|		OR TTCostAdjustment.CostInTaxAccounting > 0
	|		OR TTCostAdjustment.CostTargetFinancing > 0
	|		OR TTCostAdjustment.CostTargetFinancingPD > 0
	|		OR TTCostAdjustment.SecurityDepositValue > 0
	|		OR CASE 
	|				WHEN DocumentData.RecordCostChangeInTADueToPD
	|					THEN 0
	|				WHEN TTCostAdjustment.LocalCost > 0
	|					THEN TTCostAdjustment.CostPermanentDifference
	|				WHEN TTCostAdjustment.LocalCost = 0
	|						AND TTCostAdjustment.CostInTaxAccounting > 0
	|					THEN TTCostAdjustment.CostPermanentDifference
	|				ELSE 0
	|			END <> 0)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTCostReduction(QueryTexts)

	TableName = "TTCostReduction";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTCostAdjustment(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTCostAdjustment.Ref               AS Ref,
	|	TTCostAdjustment.FixedAsset     AS FixedAsset,
	|
	// Cost
	|	CASE 
	|		WHEN TTCostAdjustment.Cost < 0
	|			THEN -TTCostAdjustment.Cost
	|		ELSE 0
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN TTCostAdjustment.LocalCost < 0
	|			THEN -TTCostAdjustment.LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN DocumentData.RecordCostChangeInTADueToPD
	|			THEN 0
	|		WHEN TTCostAdjustment.CostInTaxAccounting < 0
	|			THEN -TTCostAdjustment.CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
	|		WHEN DocumentData.RecordCostChangeInTADueToPD
	|			THEN 0
	|		WHEN TTCostAdjustment.LocalCost < 0
	|			THEN -TTCostAdjustment.CostPermanentDifference
	|		WHEN TTCostAdjustment.LocalCost = 0
	|				AND TTCostAdjustment.CostInTaxAccounting < 0
	|			THEN -TTCostAdjustment.CostPermanentDifference
	|		WHEN TTCostAdjustment.LocalCost = 0
	|				AND TTCostAdjustment.CostInTaxAccounting = 0
	|			THEN -TTCostAdjustment.CostPermanentDifference
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	// CostTargetFinancing
	|	CASE 
	|		WHEN TTCostAdjustment.CostTargetFinancing < 0
	|			THEN -TTCostAdjustment.CostTargetFinancing
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	// CostTargetFinancingPD
	|	CASE 
	|		WHEN TTCostAdjustment.CostTargetFinancingPD < 0
	|			THEN -TTCostAdjustment.CostTargetFinancingPD
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	// SecurityDepositValue
	|	CASE 
	|		WHEN TTCostAdjustment.SecurityDepositValue < 0
	|			THEN -TTCostAdjustment.SecurityDepositValue
	|		ELSE 0
	|	END AS SecurityDepositValue,
	|
	|	TTCostAdjustment.RowID  AS FinRecordID,
	|	&SettingUpHO_CostReduction             AS BusinessTransactionSetting
	|
	|INTO TTCostReduction
	|
	|FROM
	|	TTCostAdjustment AS TTCostAdjustment
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTCostAdjustment.Ref
	|
	|WHERE
	|	DocumentData.CostDecreaseRecording
	|
	|	AND (TTCostAdjustment.Cost < 0
	|		OR TTCostAdjustment.LocalCost < 0
	|		OR TTCostAdjustment.CostInTaxAccounting < 0
	|		OR TTCostAdjustment.CostTargetFinancing < 0
	|		OR TTCostAdjustment.CostTargetFinancingPD < 0
	|		OR TTCostAdjustment.SecurityDepositValue < 0
	|		OR CASE 
	|				WHEN DocumentData.RecordCostChangeInTADueToPD
	|					THEN 0
	|				WHEN TTCostAdjustment.LocalCost < 0
	|					THEN -TTCostAdjustment.CostPermanentDifference
	|				WHEN TTCostAdjustment.LocalCost = 0
	|						AND TTCostAdjustment.CostInTaxAccounting < 0
	|					THEN -TTCostAdjustment.CostPermanentDifference
	|				WHEN TTCostAdjustment.LocalCost = 0
	|						AND TTCostAdjustment.CostInTaxAccounting = 0
	|					THEN -TTCostAdjustment.CostPermanentDifference
	|				ELSE 0
	|			END <> 0)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTIncreasedDepreciation(QueryTexts)

	TableName = "TTIncreasedDepreciation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTDepreciationAdjustment(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTDepreciationAdjustment.Ref             AS Ref,
	|	TTDepreciationAdjustment.FixedAsset   AS FixedAsset,
	|	TTDepreciationAdjustment.AccrueDepreciation     AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN TTDepreciationAdjustment.Depreciation > 0
	|			THEN TTDepreciationAdjustment.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationLocal > 0
	|			THEN TTDepreciationAdjustment.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationInTaxAccounting > 0
	|			THEN TTDepreciationAdjustment.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationLocal > 0
	|			THEN TTDepreciationAdjustment.DepreciationPermanentDifferences
	|		WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|				AND TTDepreciationAdjustment.DepreciationInTaxAccounting > 0
	|			THEN TTDepreciationAdjustment.DepreciationPermanentDifferences
	|		WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|				AND TTDepreciationAdjustment.DepreciationInTaxAccounting = 0
	|			THEN TTDepreciationAdjustment.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing > 0
	|			THEN TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationTargetFinancingPD > 0
	|			THEN TTDepreciationAdjustment.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	TTDepreciationAdjustment.VariancePeriod AS VariancePeriod,
	|	TTDepreciationAdjustment.RowID AS FinRecordID,
	|	&SettingHO_IncreaseDepreciation AS BusinessTransactionSetting
	|
	|INTO TTIncreasedDepreciation
	|
	|FROM
	|	TTDepreciationAdjustment AS TTDepreciationAdjustment
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTDepreciationAdjustment.Ref
	|
	|WHERE
	|	DocumentData.DepreciationIncreaseRecording
	|
	|	AND (TTDepreciationAdjustment.Depreciation > 0
	|		OR TTDepreciationAdjustment.DepreciationLocal > 0
	|		OR TTDepreciationAdjustment.DepreciationInTaxAccounting > 0
	|		OR TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing > 0
	|		OR TTDepreciationAdjustment.DepreciationTargetFinancingPD > 0
	|		OR CASE 
	|				WHEN TTDepreciationAdjustment.DepreciationLocal > 0
	|					THEN TTDepreciationAdjustment.DepreciationPermanentDifferences
	|				WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|						AND TTDepreciationAdjustment.DepreciationInTaxAccounting > 0
	|					THEN TTDepreciationAdjustment.DepreciationPermanentDifferences
	|				WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|						AND TTDepreciationAdjustment.DepreciationInTaxAccounting = 0
	|					THEN TTDepreciationAdjustment.DepreciationPermanentDifferences
	|				ELSE 0
	|			END <> 0)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTDecreaseInDepreciation(QueryTexts)

	TableName = "TTDecreaseInDepreciation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTDepreciationAdjustment(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTDepreciationAdjustment.Ref             AS Ref,
	|	TTDepreciationAdjustment.FixedAsset   AS FixedAsset,
	|	TTDepreciationAdjustment.AccrueDepreciation     AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN TTDepreciationAdjustment.Depreciation < 0
	|			THEN -TTDepreciationAdjustment.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationLocal < 0
	|			THEN -TTDepreciationAdjustment.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationInTaxAccounting < 0
	|			THEN -TTDepreciationAdjustment.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|				AND TTDepreciationAdjustment.DepreciationInTaxAccounting = 0
	|			THEN 0
	|		WHEN TTDepreciationAdjustment.DepreciationLocal < 0
	|			THEN -TTDepreciationAdjustment.DepreciationPermanentDifferences
	|		WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|				AND TTDepreciationAdjustment.DepreciationInTaxAccounting < 0
	|			THEN -TTDepreciationAdjustment.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing < 0
	|			THEN -TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationTargetFinancingPD < 0
	|			THEN -TTDepreciationAdjustment.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	TTDepreciationAdjustment.VariancePeriod AS VariancePeriod,
	|	TTDepreciationAdjustment.RowID  AS FinRecordID,
	|	&SettingHO_ReductionOfDepreciation  AS BusinessTransactionSetting
	|
	|INTO TTDecreaseInDepreciation
	|
	|FROM
	|	TTDepreciationAdjustment AS TTDepreciationAdjustment
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTDepreciationAdjustment.Ref
	|
	|WHERE
	|	DocumentData.DepreciationDecreaseRecording
	|
	|	AND (TTDepreciationAdjustment.Depreciation < 0
	|		OR TTDepreciationAdjustment.DepreciationLocal < 0
	|		OR TTDepreciationAdjustment.DepreciationInTaxAccounting < 0
	|		OR TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing < 0
	|		OR TTDepreciationAdjustment.DepreciationTargetFinancingPD < 0
	|		OR CASE 
	|				WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|						AND TTDepreciationAdjustment.DepreciationInTaxAccounting = 0
	|					THEN 0
	|				WHEN TTDepreciationAdjustment.DepreciationLocal < 0
	|					THEN -TTDepreciationAdjustment.DepreciationPermanentDifferences
	|				WHEN TTDepreciationAdjustment.DepreciationLocal = 0
	|						AND TTDepreciationAdjustment.DepreciationInTaxAccounting < 0
	|					THEN -TTDepreciationAdjustment.DepreciationPermanentDifferences
	|				ELSE 0
	|			END <> 0)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTIncreaseInDepreciationAtBeginningOfYear(QueryTexts)

	TableName = "TTIncreaseInDepreciationAtBeginningOfYear";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTDepreciationAdjustmentAtBeginningOfYear(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTDepreciationAdjustmentAtBeginningOfYear.Ref             AS Ref,
	|	TTDepreciationAdjustmentAtBeginningOfYear.FixedAsset   AS FixedAsset,
	|	TTDepreciationAdjustmentAtBeginningOfYear.AccrueDepreciation     AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.Depreciation > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|				AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|				AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting = 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationTargetFinancingPD > 0
	|			THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	TTDepreciationAdjustmentAtBeginningOfYear.RowID  AS FinRecordID,
	|	&SettingUpHO_IncreaseInDepreciationAtBeginningOfYear AS BusinessTransactionSetting
	|
	|INTO TTIncreaseInDepreciationAtBeginningOfYear
	|
	|FROM
	|	TTDepreciationAdjustmentAtBeginningOfYear AS TTDepreciationAdjustmentAtBeginningOfYear
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTDepreciationAdjustmentAtBeginningOfYear.Ref
	|
	|WHERE
	|	DocumentData.DepreciationIncreaseRecording
	|
	|	AND (TTDepreciationAdjustmentAtBeginningOfYear.Depreciation > 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal > 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting > 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing > 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.DepreciationTargetFinancingPD > 0
	|		OR CASE 
	|				WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal > 0
	|					THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|				WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|						AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting > 0
	|					THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|				WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|						AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting = 0
	|					THEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|				ELSE 0
	|			END <> 0)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTReductionOfDepreciationAtBeginningOfYear(QueryTexts)

	TableName = "TTReductionOfDepreciationAtBeginningOfYear";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTDepreciationAdjustmentAtBeginningOfYear(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTDepreciationAdjustmentAtBeginningOfYear.Ref             AS Ref,
	|	TTDepreciationAdjustmentAtBeginningOfYear.FixedAsset   AS FixedAsset,
	|	TTDepreciationAdjustmentAtBeginningOfYear.AccrueDepreciation     AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.Depreciation < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|				AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting = 0
	|			THEN 0
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|				AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationTargetFinancingPD < 0
	|			THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	TTDepreciationAdjustmentAtBeginningOfYear.RowID AS FinRecordID,
	|	&SettingUpHO_ReductionOfDepreciationAtBeginningOfYear AS BusinessTransactionSetting
	|
	|INTO TTReductionOfDepreciationAtBeginningOfYear
	|
	|FROM
	|	TTDepreciationAdjustmentAtBeginningOfYear AS TTDepreciationAdjustmentAtBeginningOfYear
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTDepreciationAdjustmentAtBeginningOfYear.Ref
	|
	|WHERE
	|	DocumentData.DepreciationDecreaseRecording
	|
	|	AND (TTDepreciationAdjustmentAtBeginningOfYear.Depreciation < 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal < 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting < 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing < 0
	|		OR TTDepreciationAdjustmentAtBeginningOfYear.DepreciationTargetFinancingPD < 0
	|		OR CASE 
	|				WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|						AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting = 0
	|					THEN 0
	|				WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal < 0
	|					THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|				WHEN TTDepreciationAdjustmentAtBeginningOfYear.DepreciationLocal = 0
	|						AND TTDepreciationAdjustmentAtBeginningOfYear.DepreciationInTaxAccounting < 0
	|					THEN -TTDepreciationAdjustmentAtBeginningOfYear.DepreciationPermanentDifferences
	|				ELSE 0
	|			END <> 0)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTCostAdjustment(QueryTexts)

	TableName = "TTCostAdjustment";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.Ref            AS Ref,
	|	FATable.FixedAsset  AS FixedAsset,
	|
	// Cost
	|	CASE 
	|		WHEN ISNULL(FACost.Cost, 0) <> FATable.CostInManagementAccounting 
	|				AND DocumentData.RecordInManAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN FATable.CostInManagementAccounting - ISNULL(FACost.Cost, 0)
	|		ELSE 0
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN ISNULL(FACost.LocalCost, 0) <> FATable.CostInAccounting 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN FATable.CostInAccounting - ISNULL(FACost.LocalCost, 0)
	|		ELSE 0
	|	END AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN ISNULL(FACost.CostInTaxAccounting, 0) <> FATable.CostInTaxAccounting
	|				AND NOT DocumentData.BonusDepreciationAdjustment
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|			THEN FATable.CostInTaxAccounting - ISNULL(FACost.CostInTaxAccounting, 0)
	|
	|		WHEN ISNULL(FACost.CostInTaxAccounting, 0) <> (FATable.CostInTaxAccounting + FATable.DepreciationAllowance)
	|				AND DocumentData.BonusDepreciationAdjustment
	|				AND DocumentData.BonusDepreciationIncreaseRecording
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|			THEN (FATable.CostInTaxAccounting + FATable.DepreciationAllowance) - ISNULL(FACost.CostInTaxAccounting, 0)
	|
	|		WHEN ISNULL(FACost.CostInTaxAccounting, 0) <> (FATable.CostInTaxAccounting - FATable.DepreciationAllowance)
	|				AND DocumentData.BonusDepreciationAdjustment
	|				AND DocumentData.BonusDepreciationDecreaseRecording
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|			THEN (FATable.CostInTaxAccounting - FATable.DepreciationAllowance) - ISNULL(FACost.CostInTaxAccounting, 0)
	|
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
	|		WHEN ISNULL(FACost.CostPermanentDifference, 0) <> FATable.CostPermanentDifference 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN FATable.CostPermanentDifference - ISNULL(FACost.CostPermanentDifference, 0)
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	// CostTargetFinancing
	|	CASE 
	|		WHEN ISNULL(FACost.CostTargetFinancing, 0) <> FATable.CostTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN FATable.CostTargetFinancing - ISNULL(FACost.CostTargetFinancing, 0)
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	// CostTargetFinancingPD
	|	CASE 
	|		WHEN ISNULL(FACost.CostTargetFinancing, 0) <> FATable.CostTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN FATable.CostTargetFinancing - ISNULL(FACost.CostTargetFinancing, 0)
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	// SecurityDepositValue
	|	CASE 
	|		WHEN ISNULL(FACost.SecurityDepositValue, 0) <> FATable.SecurityDepositValue 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|			THEN FATable.SecurityDepositValue - ISNULL(FACost.SecurityDepositValue, 0)
	|		ELSE 0
	|	END AS SecurityDepositValue,
	|
	// TAExpenseAmountOfInvestmentTaxDeduction
	|	CASE 
	|		WHEN ISNULL(FACost.TAExpenseAmountOfInvestmentTaxDeduction, 0) <> FATable.TAExpenseAmountOfInvestmentTaxDeduction 
	|				AND DocumentData.AdjustTAExpenseAmountOfInvestmentTaxDeduction 
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN FATable.TAExpenseAmountOfInvestmentTaxDeduction - ISNULL(FACost.TAExpenseAmountOfInvestmentTaxDeduction, 0)
	|		ELSE 0
	|	END AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	FATable.RowID AS RowID
	|
	|INTO TTCostAdjustment
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.CostAdjustment
	|	AND (ISNULL(FACost.Cost, 0) <> FATable.CostInManagementAccounting 
	|				AND DocumentData.RecordInManAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.LocalCost, 0) <> FATable.CostInAccounting 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.CostInTaxAccounting, 0) <> FATable.CostInTaxAccounting 
	|				AND NOT DocumentData.BonusDepreciationAdjustment
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.CostInTaxAccounting, 0) <> (FATable.CostInTaxAccounting + FATable.DepreciationAllowance) 
	|				AND DocumentData.BonusDepreciationAdjustment
	|				AND DocumentData.BonusDepreciationIncreaseRecording
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.CostInTaxAccounting, 0) <> (FATable.CostInTaxAccounting - FATable.DepreciationAllowance) 
	|				AND DocumentData.BonusDepreciationAdjustment
	|				AND DocumentData.BonusDepreciationDecreaseRecording
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.CostPermanentDifference, 0) <> FATable.CostPermanentDifference 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.CostTargetFinancing, 0) <> FATable.CostTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(FACost.SecurityDepositValue, 0) <> FATable.SecurityDepositValue 
	|				AND DocumentData.PostInAccounting 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Leased)
	|
	|		OR ISNULL(FACost.TAExpenseAmountOfInvestmentTaxDeduction, 0) <> FATable.TAExpenseAmountOfInvestmentTaxDeduction 
	|				AND DocumentData.AdjustTAExpenseAmountOfInvestmentTaxDeduction 
	|				AND DocumentData.RecordInTA 
	|				AND DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|	)
	|
	|INDEX BY 
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTDepreciationAdjustment(QueryTexts)

	TableName = "TTDepreciationAdjustment";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	QueryTextTableTueDepreciationOfCurrentMonth(QueryTexts); 
	QueryTextTTDepreciationAdjustmentAtBeginningOfYear(QueryTexts); 

	ListOfMergeRequests = New Array;
	
	#Region AdjustingBalance
	
	QueryText =
	"SELECT
	|	FATable.Ref                 AS Ref,
	|	FATable.FixedAsset       AS FixedAsset,
	|
	|	ISNULL(InitialFixedAssetsInformation.AccountingProcedureAC, UNDEFINED) 
	|		= VALUE(Enum.FARepaymentProcedure.AccrueWearAsPerUFADR)  AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) - ISNULL(AdjustmentAtBeginningOfYear.Depreciation, 0) <> FATable.DepreciationManagementAccounting 
	|				AND DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationManagementAccounting 
	|					- ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.Depreciation, 0) 
	|					+ ISNULL(TueDepreciationOfCurrentMonth.Depreciation, 0)
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationLocal, 0) <> FATable.DepreciationInAccounting 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.DepreciationInAccounting 
	|					- ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.DepreciationLocal, 0) 
	|					+ ISNULL(TueDepreciationOfCurrentMonth.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationInTaxAccounting, 0) <> FATable.DepreciationInTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|			THEN FATable.DepreciationInTaxAccounting 
	|					- ISNULL(AdjustmentAtBeginningOfYear.DepreciationInTaxAccounting, 0)
	|					- ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0)
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationPermanentDifferences, 0) <> FATable.DepreciationPermanentDifferences 
	|				AND DocumentData.RecordInLocalAccounting 
	|			THEN FATable.DepreciationPermanentDifferences 
	|					- ISNULL(AdjustmentAtBeginningOfYear.DepreciationPermanentDifferences, 0)
	|					- ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) - ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) <> FATable.FixedAssetDepreciationTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.FixedAssetDepreciationTargetFinancing 
	|					- ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) 
	|					+ ISNULL(TueDepreciationOfCurrentMonth.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) - ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) <> FATable.FixedAssetDepreciationTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.FixedAssetDepreciationTargetFinancing 
	|					- ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) 
	|					+ ISNULL(TueDepreciationOfCurrentMonth.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	FATable.RowID AS RowID,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|INTO TTDepreciationAdjustment
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTDepreciationAdjustmentAtBeginningOfYear AS AdjustmentAtBeginningOfYear
	|		ON AdjustmentAtBeginningOfYear.Ref = FATable.Ref
	|			AND AdjustmentAtBeginningOfYear.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
	|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TueDepreciationOfCurrentMonth AS TueDepreciationOfCurrentMonth
	|		ON TueDepreciationOfCurrentMonth.Ref = FATable.Ref
	|			AND TueDepreciationOfCurrentMonth.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|	AND DocumentData.DepreciationAdjustment
	|	AND NOT DocumentData.DepreciationAdjustmentForPeriod
	|	AND (NOT DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods 
	|		OR BEGINOFPERIOD(DocumentData.Period, DAY) <> BEGINOFPERIOD(DocumentData.Period, YEAR))
	|
	|	AND (ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) - ISNULL(AdjustmentAtBeginningOfYear.Depreciation, 0) <> FATable.DepreciationManagementAccounting 
	|				AND DocumentData.RecordInManAccounting 
	|
	|		OR ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationLocal, 0) <> FATable.DepreciationInAccounting 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationInTaxAccounting, 0) <> FATable.DepreciationInTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|
	|		OR ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationPermanentDifferences, 0) <> FATable.DepreciationPermanentDifferences 
	|				AND DocumentData.RecordInLocalAccounting 
	|
	|		OR ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) - ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) <> FATable.FixedAssetDepreciationTargetFinancing 
	|				AND DocumentData.PostInAccounting)
	|";
	
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region AdjustmentForMAPeriod
	
	QueryText =
	"SELECT
	|	DepreciationTableForPeriod.Ref           AS Ref,
	|	DepreciationTableForPeriod.FixedAsset AS FixedAsset,
	|
	|	FALSE AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) <> DepreciationTableForPeriod.DepreciationManagementAccounting 
	|			THEN DepreciationTableForPeriod.DepreciationManagementAccounting - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|				AND ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) <> DepreciationTableForPeriod.DepreciationInAccounting
	|			THEN DepreciationTableForPeriod.DepreciationInAccounting - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	0 AS DepreciationInTaxAccounting,
	|	0 AS DepreciationPermanentDifferences,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	DepreciationTableForPeriod.RowID AS RowID,
	|	DepreciationTableForPeriod.EndOfMonth AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TableDepreciationForMAPeriod AS DepreciationTableForPeriod
	|		ON DepreciationTableForPeriod.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_DepreciationForPeriod AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = DepreciationTableForPeriod.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = DepreciationTableForPeriod.FixedAsset
	|			AND FixedAssetsDepreciationCharge.EndOfMonth = DepreciationTableForPeriod.EndOfMonth
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|	AND DocumentData.DepreciationAdjustment
	|	AND DocumentData.DepreciationAdjustmentForPeriod
	|	AND DocumentData.RecordInManAccounting
	|
	|	AND (ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)  <> DepreciationTableForPeriod.DepreciationManagementAccounting 
	|		OR ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|			AND ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) <> DepreciationTableForPeriod.DepreciationInAccounting) 
	|
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion
	
	#Region AdjustmentForPeriodAC
	
	QueryText =
	"SELECT
	|	DepreciationTableForPeriod.Ref           AS Ref,
	|	DepreciationTableForPeriod.FixedAsset AS FixedAsset,
	|
	|	FALSE AS AccrueDepreciation,
	|
	|	0 AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) <> DepreciationTableForPeriod.DepreciationInAccounting
	|			THEN DepreciationTableForPeriod.DepreciationInAccounting - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	0 AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) <> DepreciationTableForPeriod.DepreciationPermanentDifferences
	|			THEN DepreciationTableForPeriod.DepreciationPermanentDifferences - ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN DocumentData.ApplicationOfTargetFinancing
	|				AND ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) <> DepreciationTableForPeriod.FixedAssetDepreciationTargetFinancing
	|			THEN DepreciationTableForPeriod.FixedAssetDepreciationTargetFinancing - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN DocumentData.ApplicationOfTargetFinancing
	|				AND ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) <> DepreciationTableForPeriod.FixedAssetDepreciationTargetFinancing
	|			THEN DepreciationTableForPeriod.FixedAssetDepreciationTargetFinancing - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	DepreciationTableForPeriod.RowID AS RowID,
	|	DepreciationTableForPeriod.EndOfMonth AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TableDepreciationForACPeriod AS DepreciationTableForPeriod
	|		ON DepreciationTableForPeriod.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_DepreciationForPeriod AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = DepreciationTableForPeriod.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = DepreciationTableForPeriod.FixedAsset
	|			AND FixedAssetsDepreciationCharge.EndOfMonth = DepreciationTableForPeriod.EndOfMonth
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|	AND DocumentData.DepreciationAdjustment
	|	AND DocumentData.DepreciationAdjustmentForPeriod
	|	AND DocumentData.PostInAccounting
	|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|
	|	AND (ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)  <> DepreciationTableForPeriod.DepreciationInAccounting 
	|		OR DocumentData.ApplicationOfTargetFinancing
	|			AND ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) <> DepreciationTableForPeriod.FixedAssetDepreciationTargetFinancing) 
	|
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion


	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryText = QueryText +
	"INDEX BY
	|	Ref";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTDepreciationAdjustmentAtBeginningOfYear(QueryTexts)

	TableName = "TTDepreciationAdjustmentAtBeginningOfYear";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	QueryTextTableTTDepreciationAtBeginningOfYear(QueryTexts); 
	
	QueryText =
	"SELECT
	|	FATable.Ref                 AS Ref,
	|	FATable.FixedAsset       AS FixedAsset,
	|
	|	ISNULL(InitialFixedAssetsInformation.AccountingProcedureAC, UNDEFINED) 
	|		= VALUE(Enum.FARepaymentProcedure.AccrueWearAsPerUFADR)  AS AccrueDepreciation,
	|
	// Depreciation
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.Depreciation, 0) <> FATable.DepreciationAtBeginningOfYearMa 
	|				AND DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationAtBeginningOfYearMa - ISNULL(DepreciationAsOfTheYearStart.Depreciation, 0)
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationLocal, 0) <> FATable.DepreciationAsOfTheYearStartBookkeeping 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.DepreciationAsOfTheYearStartBookkeeping - ISNULL(DepreciationAsOfTheYearStart.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN DocumentData.DepreciationAdjustmentForPeriod
	|			THEN 0
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationInTaxAccounting, 0) <> FATable.DepreciationAsOfTheYearStartTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|			THEN FATable.DepreciationAsOfTheYearStartTaxAccounting - ISNULL(DepreciationAsOfTheYearStart.DepreciationInTaxAccounting, 0)
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationPermanentDifferences, 0) <> FATable.PermanentDifferencesInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.PermanentDifferencesInDepreciationAsOfTheYearStart - ISNULL(DepreciationAsOfTheYearStart.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing, 0) <> FATable.TargetFundsInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.TargetFundsInDepreciationAsOfTheYearStart - ISNULL(DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationTargetFinancingPD, 0) <> FATable.TargetFundsInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|			THEN FATable.TargetFundsInDepreciationAsOfTheYearStart - ISNULL(DepreciationAsOfTheYearStart.DepreciationTargetFinancingPD, 0)
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	FATable.FAID AS RowID
	|
	|INTO TTDepreciationAdjustmentAtBeginningOfYear
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTDepreciationAtBeginningOfYear AS DepreciationAsOfTheYearStart
	|		ON DepreciationAsOfTheYearStart.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
	|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|	AND DocumentData.DepreciationAdjustment
	|	AND DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods
	|
	|	AND (ISNULL(DepreciationAsOfTheYearStart.Depreciation, 0) <> FATable.DepreciationAtBeginningOfYearMa 
	|				AND DocumentData.RecordInManAccounting 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.DepreciationLocal, 0) <> FATable.DepreciationAsOfTheYearStartBookkeeping 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.DepreciationInTaxAccounting, 0) <> FATable.DepreciationAsOfTheYearStartTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.DepreciationPermanentDifferences, 0) <> FATable.PermanentDifferencesInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing, 0) <> FATable.TargetFundsInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting)
	|
	|INDEX BY 
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTueDepreciationOfCurrentMonth(QueryTexts)
	
	TableName = "TueDepreciationOfCurrentMonth";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|	SUM(CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -FixedAssetsDepreciationCharge.Depreciation 
	|			ELSE FixedAssetsDepreciationCharge.Depreciation 
	|		END) AS Depreciation,
	|
	|	SUM(CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -FixedAssetsDepreciationCharge.DepreciationLocal 
	|			ELSE FixedAssetsDepreciationCharge.DepreciationLocal 
	|		END) AS DepreciationLocal,
	|
	|	SUM(CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing 
	|			ELSE FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing 
	|		END) AS FixedAssetDepreciationTargetFinancing
	|
	|INTO TueDepreciationOfCurrentMonth
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Organization = DocumentData.Organization
	|			AND FixedAssetsDepreciationCharge.FixedAsset = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Period >= DocumentData.BeginningOfDocumentPeriod
	|			AND FixedAssetsDepreciationCharge.Period <= DocumentData.EndOfDocumentPeriod
	|			AND VALUETYPE(FixedAssetsDepreciationCharge.Recorder) = TYPE(Document.FixedAssetsDepreciationCharge2_4)
	|
	|WHERE
	|	DocumentData.PeriodAdjustment <> 0
	|	AND DocumentData.EventKindWithFixedAssets = VALUE(Enum.EventKindsWithFixedAssets.Other)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	FixedAssetsDepreciationCharge.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";

	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTDepreciationAtBeginningOfYear(QueryTexts)
	
	TableName = "TTDepreciationAtBeginningOfYear";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryText =
	"SELECT DISTINCT
	|	FATable.FixedAsset AS FixedAsset
	|
	|INTO TTFAListDepreciationAtBeginningOfYear
	|
	|FROM 
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.DepreciationAdjustment
	|	AND DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods
	|
	|INDEX BY
	|	FixedAsset
	|";
	QueryTexts.Add(QueryText, "TTFAListDepreciationAtBeginningOfYear", False);
	
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|
	|	-FixedAssetsDepreciationCharge.DepreciationBalance AS Depreciation,
	|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|	-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|	-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|	-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|	-FixedAssetsDepreciationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD
	|
	|INTO TTDepreciationAtBeginningOfYear
	|
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|			&BegOfYear,
	|			FixedAsset IN (
	|				SELECT 
	|					Table.FixedAsset
	|				FROM 
	|					TTFAListDepreciationAtBeginningOfYear AS Table)) AS FixedAssetsDepreciationCharge
	|
	|INDEX BY
	|	FixedAsset
	|";

	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	QueryTextTTIncreaseInDepreciationAtBeginningOfYear(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	#Region CostReduction
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	TTCostReduction.Cost AmountIncludingVAT,
	|	TTCostReduction.Cost AS AmountExcludingVAT,
	|	TTCostReduction.Cost AS AmountExcludingVATMan,
	|
	|	TTCostReduction.LocalCost AS AmountIncludingVATCompl,
	|	TTCostReduction.LocalCost AS AmountExcludingVATCompl,
	|
	|	TTCostReduction.CostPermanentDifference AS PermanentDifference,
	|
	|	TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference AS CostTD,
	|
	|	&BO_CostReduction                         AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region ReducingCostOfCF
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0 AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	TTCostReduction.CostTargetFinancing AS AmountIncludingVATCompl,
	|
	|	TTCostReduction.CostTargetFinancing AS AmountExcludingVATCompl,
	|
	|	TTCostReduction.CostTargetFinancingPD AS PermanentDifference,
	|
	|	TTCostReduction.CostTargetFinancing
	|		- TTCostReduction.CostTargetFinancingPD AS CostTD,
	|
	|	&BO_ReducingCostOfCF                       AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	&SettingUpHO_ReducingCostOfCF AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region CostReductionIsReversed
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	-TTCostReduction.Cost AmountIncludingVAT,
	|	-TTCostReduction.Cost AS AmountExcludingVAT,
	|	-TTCostReduction.Cost AS AmountExcludingVATMan,
	|
	|	-TTCostReduction.LocalCost AS AmountIncludingVATCompl,
	|
	|	-TTCostReduction.LocalCost AS AmountExcludingVATCompl,
	|
	|	-TTCostReduction.CostPermanentDifference AS PermanentDifference,
	|
	|	-(TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference) AS CostTD,
	|
	|	&BO_CostReduction                         AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region TFCostReductionIsReversed
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0 AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	-TTCostReduction.CostTargetFinancing AS AmountIncludingVATCompl,
	|	-TTCostReduction.CostTargetFinancing AS AmountExcludingVATCompl,
	|
	|	-TTCostReduction.CostTargetFinancingPD AS PermanentDifference,
	|
	|	-(TTCostReduction.CostTargetFinancing
	|		- TTCostReduction.CostTargetFinancingPD) AS CostTD,
	|
	|	&BO_ReducingCostOfCF                       AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	&SettingUpHO_ReducingCostOfCF AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreasedDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	TTIncreasedDepreciation.Depreciation             AS AmountIncludingVAT,
	|	TTIncreasedDepreciation.Depreciation             AS AmountExcludingVAT,
	|	TTIncreasedDepreciation.Depreciation             AS AmountExcludingVATMan,
	|
	|	TTIncreasedDepreciation.DepreciationLocal         AS AmountIncludingVATCompl,
	|
	|	TTIncreasedDepreciation.DepreciationLocal         AS AmountExcludingVATCompl,
	|
	|	TTIncreasedDepreciation.DepreciationPermanentDifferences           AS PermanentDifference,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		- TTIncreasedDepreciation.DepreciationInTaxAccounting
	|		- TTIncreasedDepreciation.DepreciationPermanentDifferences     AS CostTD,
	|
	|	&BO_IncreasedDepreciation                       AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTIncreasedDepreciation.FinRecordID         AS FinRecordID,
	|	TTIncreasedDepreciation.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	TTIncreasedDepreciation.VariancePeriod AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTIncreasedDepreciation.Depreciation <> 0
	|		OR TTIncreasedDepreciation.DepreciationLocal <> 0
	|		OR TTIncreasedDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTIncreasedDepreciation.DepreciationPermanentDifferences <> 0)
	|
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreaseInDepreciationOfCF
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0             AS AmountIncludingVAT,
	|	0             AS AmountExcludingVAT,
	|	0             AS AmountExcludingVATMan,
	|
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing     AS AmountIncludingVATCompl,
	|
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing     AS AmountExcludingVATCompl,
	|
	|	TTIncreasedDepreciation.DepreciationTargetFinancingPD   AS PermanentDifference,
	|
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing
	|		- TTIncreasedDepreciation.DepreciationTargetFinancingPD   AS CostTD,
	|
	|	&BO_IncreaseInDepreciationOfCF                     AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTIncreasedDepreciation.FinRecordID AS FinRecordID,
	|	&SettingHO_IncreaseDepreciationOfTF AS BusinessTransactionSetting,
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	TTIncreasedDepreciation.VariancePeriod AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreasedDepreciation.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationAtBeginningOfYear
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation AS AmountIncludingVAT,
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation AS AmountExcludingVAT,
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation AS AmountExcludingVATMan,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal AS AmountIncludingVATCompl,
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal AS AmountExcludingVATCompl,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences   AS PermanentDifference,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences AS CostTD,
	|
	|	&BO_IncreaseInDepreciationAtBeginningOfYear           AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FinRecordID AS FinRecordID,
	|	TTIncreaseInDepreciationAtBeginningOfYear.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreaseInDepreciationAtBeginningOfYear AS TTIncreaseInDepreciationAtBeginningOfYear
	|		ON TTIncreaseInDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreaseInDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTIncreaseInDepreciationAtBeginningOfYear.Depreciation <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationAtBeginningOfYearCF
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0             AS AmountIncludingVAT,
	|	0             AS AmountExcludingVAT,
	|	0             AS AmountExcludingVATMan,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing     AS AmountIncludingVATCompl,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing     AS AmountExcludingVATCompl,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD   AS PermanentDifference,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD   AS CostTD,
	|
	|	&HO_IncreaseInDepreciationOfCentralBankAtBeginningOfYear         AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FinRecordID  AS FinRecordID,
	|	&SettingUpHO_IncreaseInCFDepreciationAtBeginningOfYear AS BusinessTransactionSetting,
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreaseInDepreciationAtBeginningOfYear AS TTIncreaseInDepreciationAtBeginningOfYear
	|		ON TTIncreaseInDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreaseInDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region ReductionOfDepreciationReverse
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitThisYearDepreciationDecrease
	|	END AS Department,
	|
	|	DocumentData.ExpenseItemThisYearDepreciationDecrease AS ExpenseItem,
	|	DocumentData.DimensionThisYearDepreciationDecrease AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessThisYearDepreciationDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	-TTDecreaseInDepreciation.Depreciation             AS AmountIncludingVAT,
	|	-TTDecreaseInDepreciation.Depreciation             AS AmountExcludingVAT,
	|	-TTDecreaseInDepreciation.Depreciation             AS AmountExcludingVATMan,
	|
	|	-TTDecreaseInDepreciation.DepreciationLocal         AS AmountIncludingVATCompl,
	|
	|	-TTDecreaseInDepreciation.DepreciationLocal         AS AmountExcludingVATCompl,
	|
	|	-TTDecreaseInDepreciation.DepreciationPermanentDifferences           AS PermanentDifference,
	|
	|	-(TTDecreaseInDepreciation.DepreciationLocal
	|		- TTDecreaseInDepreciation.DepreciationInTaxAccounting
	|		- TTDecreaseInDepreciation.DepreciationPermanentDifferences)    AS CostTD,
	|
	|	&BO_DecreaseInDepreciation                       AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	TTDecreaseInDepreciation.FinRecordID         AS FinRecordID,
	|	TTDecreaseInDepreciation.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	TTDecreaseInDepreciation.VariancePeriod AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTDecreaseInDepreciation.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordThisYearDepreciationDecreaseAsStorno
	|	AND VALUETYPE(DocumentData.ExpenseItemThisYearDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTDecreaseInDepreciation.Depreciation <> 0
	|		OR TTDecreaseInDepreciation.DepreciationLocal <> 0
	|		OR TTDecreaseInDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTDecreaseInDepreciation.DepreciationPermanentDifferences <> 0)
	|
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationPremium
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.ExpenseParametersMatchAccountingDataBonusDepreciation
	|			THEN DocumentData.Department
	|		ELSE DocumentData.Business_UnitBonusDepreciation
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemCostDecrease AS ExpenseItem,
	|	DocumentData.DimensionBonusDepreciation AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.ExpenseParametersMatchAccountingDataBonusDepreciation
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusiness_BonusDepreciation
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|
	|	-FATable.DepreciationAllowance AS CostTD,
	|
	|	&BO_IncludeDepreciationAllowanceInExpenses      AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_InclusionOfDepreciationPremiumInExpenses AS BusinessTransactionSetting,
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = FATable.Ref
	|			AND InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BonusDepreciationAdjustment
	|	AND DocumentData.BonusDepreciationIncreaseRecording
	|	AND FATable.DepreciationAllowance <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region ReductionOfDepreciationPremiumReverse
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.ExpenseParametersMatchAccountingDataBonusDepreciation
	|			THEN DocumentData.Department
	|		ELSE DocumentData.Business_UnitBonusDepreciation
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemCostDecrease AS ExpenseItem,
	|	DocumentData.DimensionBonusDepreciation AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.ExpenseParametersMatchAccountingDataBonusDepreciation
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusiness_BonusDepreciation
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|
	|	FATable.DepreciationAllowance AS CostTD,
	|
	|	&BO_IncludeDepreciationAllowanceInExpenses      AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_InclusionOfDepreciationPremiumInExpenses AS BusinessTransactionSetting,
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = FATable.Ref
	|			AND InformationAboutAccounting.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BonusDepreciationAdjustment
	|	AND DocumentData.RecordingOfBonusDepreciationDecreaseStorno
	|	AND FATable.DepreciationAllowance <> 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInCFRevenues
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitTargetFinancingIncomeIncrease
	|	END AS Department,
	|
	|	DocumentData.AssetExpenseItemTargetFinancingIncomeIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDecreaseInIncomeTF AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessTargetFinancingIncomeIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	0 AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	TTCostIncrease.CostTargetFinancing AS AmountIncludingVATCompl,
	|
	|	TTCostIncrease.CostTargetFinancing AS AmountExcludingVATCompl,
	|
	|	TTCostIncrease.CostTargetFinancingPD AS PermanentDifference,
	|
	|	TTCostIncrease.CostTargetFinancing
	|		- TTCostIncrease.CostTargetFinancingPD AS CostTD,
	|
	|	&BO_ChangeInCFRevenues                          AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|
	|	&IDOfUnusedFinRecord           AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
	|
	|	0 AS AITAmount,
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemTargetFinancingIncomeIncrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTCostIncrease.CostTargetFinancing <> 0
	|		OR TTCostIncrease.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTIncreaseInDepreciationAtBeginningOfYear(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses(Add_Fields));
	
	#Region CostReduction
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	DocumentData.Organization AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	DocumentData.Ref AS ExpenseReceiptDocument,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTCostReduction.Cost AS Cost,
	|	TTCostReduction.Cost AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	TTCostReduction.LocalCost AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	TTCostReduction.CostPermanentDifference AS PermanentDifference,
	|
	|	TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference AS CostTD,
	|
	|	&BO_CostReduction AS BusinessOperation,
	|
	|	TTCostReduction.FinRecordID         AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region CostReductionIsReversed
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	DocumentData.Organization AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitCostDecrease
	|	END AS Department,
	|
	|	DocumentData.Ref AS ExpenseReceiptDocument,
	|
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
	|
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessCostDecrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	-TTCostReduction.Cost AS Cost,
	|	-TTCostReduction.Cost AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	-TTCostReduction.LocalCost AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	-TTCostReduction.CostPermanentDifference AS PermanentDifference,
	|
	|	-(TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference) AS CostTD,
	|
	|	&BO_CostReduction AS BusinessOperation,
	|
	|	TTCostReduction.FinRecordID         AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostReduction.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.Cost <> 0
	|		OR TTCostReduction.LocalCost <> 0
	|		OR TTCostReduction.CostInTaxAccounting <> 0
	|		OR TTCostReduction.CostPermanentDifference <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region IncreasedDepreciation
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	DocumentData.Organization AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	DocumentData.Ref AS ExpenseReceiptDocument,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
	|
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTIncreasedDepreciation.Depreciation AS Cost,
	|	TTIncreasedDepreciation.Depreciation AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		+ TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	TTIncreasedDepreciation.DepreciationPermanentDifferences
	|		+ TTIncreasedDepreciation.DepreciationTargetFinancingPD AS PermanentDifference,
	|
	|	TTIncreasedDepreciation.DepreciationLocal
	|		+ TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing
	|		- TTIncreasedDepreciation.DepreciationInTaxAccounting
	|		- TTIncreasedDepreciation.DepreciationPermanentDifferences
	|		- TTIncreasedDepreciation.DepreciationTargetFinancingPD AS CostTD,
	|
	|	&BO_IncreasedDepreciation AS BusinessOperation,
	|
	|	TTIncreasedDepreciation.FinRecordID         AS FinRecordID,
	|	TTIncreasedDepreciation.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreasedDepreciation AS TTIncreasedDepreciation
	|		ON TTIncreasedDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreasedDepreciation.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreasedDepreciation.FixedAsset
	|
	|WHERE
	|	(TTIncreasedDepreciation.Depreciation <> 0
	|		OR TTIncreasedDepreciation.DepreciationLocal <> 0
	|		OR TTIncreasedDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTIncreasedDepreciation.DepreciationPermanentDifferences <> 0
	|		OR TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreasedDepreciation.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreaseInDepreciationAtBeginningOfYear
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	DocumentData.Organization AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitDepreciationIncrease
	|	END AS Department,
	|
	|	DocumentData.Ref AS ExpenseReceiptDocument,
	|
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
	|
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessDepreciationIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation AS Cost,
	|	TTIncreaseInDepreciationAtBeginningOfYear.Depreciation AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal
	|		+ TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences
	|		+ TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD AS PermanentDifference,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal
	|		+ TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences
	|		- TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD AS CostTD,
	|
	|	&BO_IncreaseInDepreciationAtBeginningOfYear AS BusinessOperation,
	|
	|	TTIncreaseInDepreciationAtBeginningOfYear.FinRecordID AS FinRecordID,
	|	TTIncreaseInDepreciationAtBeginningOfYear.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTIncreaseInDepreciationAtBeginningOfYear AS TTIncreaseInDepreciationAtBeginningOfYear
	|		ON TTIncreaseInDepreciationAtBeginningOfYear.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTIncreaseInDepreciationAtBeginningOfYear.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTIncreaseInDepreciationAtBeginningOfYear.FixedAsset
	|
	|WHERE
	|	(TTIncreaseInDepreciationAtBeginningOfYear.Depreciation <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationLocal <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationInTaxAccounting <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationPermanentDifferences <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing <> 0
	|		OR TTIncreaseInDepreciationAtBeginningOfYear.DepreciationTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreaseInCFRevenues
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	DocumentData.Organization AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitTargetFinancingIncomeIncrease
	|	END AS Department,
	|
	|	DocumentData.Ref AS ExpenseReceiptDocument,
	|	DocumentData.AssetExpenseItemTargetFinancingIncomeIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDecreaseInIncomeTF AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease
	|			THEN InformationAboutAccounting.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessTargetFinancingIncomeIncrease
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	TTCostIncrease.CostTargetFinancing AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	TTCostIncrease.CostTargetFinancingPD AS PermanentDifference,
	|
	|	TTCostIncrease.CostTargetFinancing
	|		- TTCostIncrease.CostTargetFinancingPD AS CostTD,
	|
	|	&BO_CostIncrease AS BusinessOperation,
	|
	|	TTCostIncrease.FinRecordID         AS FinRecordID,
	|	TTCostIncrease.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostIncrease AS TTCostIncrease
	|		ON TTCostIncrease.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostIncrease.Ref
	|			AND InformationAboutAccounting.FixedAsset = TTCostIncrease.FixedAsset
	|
	|WHERE
	|	(TTCostIncrease.CostTargetFinancing <> 0
	|		OR TTCostIncrease.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure CreateDepreciationTablesForPeriod(Query)

	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|	ENDOFPERIOD(DocumentTable.Date, MONTH) AS EndOfMonth,
	|
	|	SUM(DocumentTable.Depreciation + DocumentTable.DepreciationUpdate) AS DepreciationManagementAccounting,
	|	SUM(DocumentTable.DepreciationLocal + DocumentTable.DepreciationLocalUpdate) AS DepreciationInAccounting
	|
	|INTO TableDepreciationForMAPeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriod AS DocumentTable
	|		ON DocumentTable.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.DepreciationAdjustmentForPeriod
	|	AND DocumentData.RecordInManAccounting
	|
	|GROUP BY
	|	FATable.Ref,
	|	FATable.FixedAsset,
	|	ENDOFPERIOD(DocumentTable.Date, MONTH) 
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|	ENDOFPERIOD(DocumentTable.Date, MONTH) AS EndOfMonth,
	|
	|	SUM(DocumentTable.DepreciationInAccounting + DocumentTable.DepreciationLocalUpdate) AS DepreciationInAccounting,
	|	SUM(DocumentTable.DepreciationPermanentDifferences + DocumentTable.DepreciationPermanentDifferencesUpdate) AS DepreciationPermanentDifferences,
	|	SUM(DocumentTable.FixedAssetDepreciationTargetFinancing + DocumentTable.FixedAssetDepreciationTargetFinancingUpdate) AS FixedAssetDepreciationTargetFinancing
	|
	|INTO TableDepreciationForACPeriod
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FinancialDetailsForThePeriodAC AS DocumentTable
	|		ON DocumentTable.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.DepreciationAdjustmentForPeriod
	|	AND DocumentData.PostInAccounting
	|
	|GROUP BY
	|	FATable.Ref,
	|	FATable.FixedAsset,
	|	ENDOFPERIOD(DocumentTable.Date, MONTH) 
	|
	|INDEX BY
	|	Ref
	
	
	|";
	
	Query.Text = QueryText;
	Query.Execute();
	
	TMCommonUse.AddIDsToTemporaryTable("TableDepreciationForMAPeriod", Query.TempTablesManager);
	TMCommonUse.AddIDsToTemporaryTable("TableDepreciationForACPeriod", Query.TempTablesManager);
	
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return FixedAssetCostAndDepreciationAdjustmentLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return FixedAssetCostAndDepreciationAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region DepreciationCalculationParameters

// Calculates depreciation calculation parameters
// 
// Parameters:
// 	FunctionParameters - Structure - Contains:
// 		* Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment -
//  	* AccountingSection - String, Undefined - accounting sections to get parameters for
//  	
//  Returns:
//  	Structure - See Documents.FixedAssetsDepreciationCharge2_4.ParametersForCalculatingDepreciationAccordingToTable
//  	Undefined - if failed.
//
Function DepreciationCalculationParameters(FunctionParameters) Export
	
	If Not FunctionParameters.AdjustmentModeFromPreviousDate
		Or FunctionParameters.BeginOfPeriod = '000101010000' Then
		Return Undefined;
	EndIf;
	
	If FunctionParameters.Property("AccountingSection")
		And FunctionParameters.AccountingSection <> Undefined Then
			
		ListOfAccountingSections = StrSplit(FunctionParameters.AccountingSection, ",");
	
	Else
		
		ListOfAccountingSections = New Array;
		If FunctionParameters.PostInAccounting Then
			ListOfAccountingSections.Add("ACC");
		EndIf;
		If FunctionParameters.RecordInTA Then
			ListOfAccountingSections.Add("TA");
		EndIf;
		If FunctionParameters.RecordInManAccounting Then
			ListOfAccountingSections.Add("MA");
		EndIf;
		
	EndIf;
	
	FixedAsset = Catalogs.Assets.EmptyRef();
	DepreciationAllowance = 0;
	For Each RowData In FunctionParameters.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			FixedAsset = RowData.FixedAsset;
			DepreciationAllowance = ?(
				FunctionParameters.BonusDepreciationAdjustment And FunctionParameters.BonusDepreciationIncreaseRecording, 
				RowData.DepreciationAllowance, 
				-RowData.DepreciationAllowance);
			Break;
		EndIf;
	EndDo;
	
	DocumentDate = ?(FunctionParameters.Date <> '000101010000', FunctionParameters.Date, CurrentSessionDate());
	EndOfPeriod = ?(FunctionParameters.IncludesDepreciationOfCurrentMonth, EndOfMonth(DocumentDate), BegOfMonth(DocumentDate)-1);
	
	AccountingPolicyForFixedAssets = AccountingPoliciesTaxSettingsCached.AccountingPolicyForFixedAssets(
		FunctionParameters.Organization, EndOfMonth(DocumentDate));

	ProcedureForCalculatingManSDepreciation = AccountingPoliciesTaxSettingsCached.DepreciationProcedureFAMan(
		FunctionParameters.Organization, EndOfMonth(DocumentDate));
	
	DepreciationChargeProcedureLocal = AccountingPoliciesTaxSettingsCached.ProcedureOfFixedAssetDepreciationChargeLocal(
		FunctionParameters.Organization, EndOfMonth(DocumentDate));
	
	If FunctionParameters.IncludesDepreciationOfCurrentMonth Then
		
		EndOfMAPeriod = BegOfDay(EndOfMonth(DocumentDate));
		
	ElsIf AccountingPolicyForFixedAssets = Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards
		And ProcedureForCalculatingManSDepreciation = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
		And (BegOfDay(DocumentDate)-1) <> EndOfPeriod Then
		
		EndOfMAPeriod = BegOfDay(DocumentDate)-1;
	Else
		EndOfMAPeriod = BegOfMonth(DocumentDate)-1;
	EndIf;
	
	If FunctionParameters.IncludesDepreciationOfCurrentMonth Then
		
		EndOfACPeriod = BegOfDay(EndOfMonth(DocumentDate));
		
	ElsIf AccountingPolicyForFixedAssets = Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards
		And DepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
		And (BegOfDay(DocumentDate)-1) <> EndOfPeriod Then
		
		EndOfACPeriod = BegOfDay(DocumentDate)-1;
	Else
		EndOfACPeriod = BegOfMonth(DocumentDate)-1;
	EndIf;
	
	If FunctionParameters.IncludesDepreciationOfCurrentMonth Then
		EndOfPeriodTA = BegOfDay(EndOfMonth(DocumentDate));
	Else
		EndOfPeriodTA = BegOfMonth(DocumentDate)-1;
	EndIf;

	EndOfPeriod = Max(EndOfMAPeriod, EndOfACPeriod);

	CalculationParameters = New Structure;
	CalculationParameters.Insert("Ref", FunctionParameters.Ref);
	CalculationParameters.Insert("Organization", FunctionParameters.Organization);
	CalculationParameters.Insert("FixedAsset", FixedAsset);
	CalculationParameters.Insert("Date", DocumentDate);
	CalculationParameters.Insert("BeginOfPeriod", FunctionParameters.BeginOfPeriod);
	CalculationParameters.Insert("EndOfPeriod", EndOfPeriod);
	CalculationParameters.Insert("EndOfMAPeriod", EndOfMAPeriod);
	CalculationParameters.Insert("EndOfACPeriod", EndOfACPeriod);
	CalculationParameters.Insert("EndOfPeriodTA", EndOfPeriodTA);
	CalculationParameters.Insert("DepreciationAllowance", DepreciationAllowance);
	CalculationParameters.Insert("FillInUU", ListOfAccountingSections.Find("MA") <> Undefined);
	CalculationParameters.Insert("FillInBU", ListOfAccountingSections.Find("ACC") <> Undefined);
	CalculationParameters.Insert("FillInTA", ListOfAccountingSections.Find("TA") <> Undefined);
	
	ParametersForCalculation = Documents.FixedAssetsDepreciationCharge2_4.ParametersForCalculatingDepreciationAccordingToTable(CalculationParameters);
	
	Return ParametersForCalculation;
	
EndFunction

// Process depreciation calculation parameters.
// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - Document
//  ParametersForCalculation - See DepreciationCalculationParameters
//  AccountingSection - String, Undefined - Accounting section
Procedure ProcessDepreciationCalculationParameters(Object, ParametersForCalculation, AccountingSection = Undefined) Export
	
	If ParametersForCalculation = Undefined Then
		Return;
	EndIf;
	
	If Object.RecordInManAccounting
		And (AccountingSection = "MA" Or AccountingSection = Undefined) Then
	
		Object.CostAtBeginningOfYear = ParametersForCalculation.CostAtBeginningOfYear;
		Object.DepreciationAsOfTheYearStart = ParametersForCalculation.DepreciationAsOfTheYearStart;
		Object.DepreciationAsOfThePeriodStart = ParametersForCalculation.DepreciationAsOfThePeriodStart;
		Object.CommissioningDateMA = ParametersForCalculation.CommissioningDateMA;

		Object.FinancialDetailsForThePeriod.Clear();
		CommonClientServer.SupplementTable(ParametersForCalculation.ParametersForMAPeriod, Object.FinancialDetailsForThePeriod);
		Object.FinancialDetailsForThePeriod.Sort("Date");
		
	EndIf;
	
	If Object.PostInAccounting
		And (AccountingSection = "ACC" Or AccountingSection = Undefined)
		And AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, Object.Date) Then

		Object.LocalCostAtBeginningOfYear = ParametersForCalculation.LocalCostAtBeginningOfYear;
		Object.LocalDepreciationAsOfTheYearStart = ParametersForCalculation.LocalDepreciationAsOfTheYearStart;
		Object.LocalDepreciationAtBeginningOfPeriod = ParametersForCalculation.LocalDepreciationAtBeginningOfPeriod;
		Object.CommissioningDateAC = ParametersForCalculation.CommissioningDateAC;

		Object.FinancialDetailsForThePeriodAC.Clear();
		CommonClientServer.SupplementTable(ParametersForCalculation.FinancialDetailsForThePeriodAC, Object.FinancialDetailsForThePeriodAC);
		Object.FinancialDetailsForThePeriodAC.Sort("Date");
		
	EndIf;
	
	FixedAssetCostAndDepreciationAdjustmentLocalization.ProcessResultOfFillingInDepreciationCalculationParameters(
		Object, ParametersForCalculation, AccountingSection);
	
EndProcedure

// Process the depreciation calculation result on the server.
// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - Document
//  CalculationResult2 - See Documents.FixedAssetsDepreciationCharge2_4.CalculateDepreciationAccordingToTable
Procedure ProcessDepreciationCalculationResult(Object, CalculationResult2) Export
	
	If CalculationResult2.Property("MaCalculationResult") Then
	
		For Each StringParameters_ In Object.FinancialDetailsForThePeriod Do
			
			LineDepreciation = CalculationResult2.MaCalculationResult.Find(StringParameters_.LineNumber, "LineNumber");
			
			If LineDepreciation <> Undefined Then
				
				StringParameters_.Depreciation = LineDepreciation.Depreciation;
				StringParameters_.DepreciationLocal = LineDepreciation.DepreciationLocal;
				
			Else
				
				StringParameters_.Depreciation = 0;
				StringParameters_.DepreciationLocal = 0;
			
			EndIf;
			
		EndDo;
	
	EndIf;
	
	If CalculationResult2.Property("ResultOfCalculationOfBU") Then
		
		For Each StringParameters_ In Object.FinancialDetailsForThePeriodAC Do
			
			LineDepreciation = CalculationResult2.ResultOfCalculationOfBU.Find(StringParameters_.LineNumber, "LineNumber");
			
			If LineDepreciation <> Undefined Then
				
				StringParameters_.DepreciationInAccounting = LineDepreciation.DepreciationInAccounting;
				StringParameters_.DepreciationPermanentDifferences = LineDepreciation.DepreciationPermanentDifferences;
				StringParameters_.FixedAssetDepreciationTargetFinancing = LineDepreciation.FixedAssetDepreciationTargetFinancing;
				
			Else
				
				StringParameters_.DepreciationInAccounting = 0;
				StringParameters_.DepreciationPermanentDifferences = 0;
				StringParameters_.FixedAssetDepreciationTargetFinancing = 0;
			
			EndIf;
			
		EndDo;

	EndIf;

	If CalculationResult2.Property("ResultOfCalculationIsTA") Then
		
		For Each StringParameters_ In Object.FinancialDetailsForThePeriodTA Do
			
			LineDepreciation = CalculationResult2.ResultOfCalculationIsTA.Find(StringParameters_.LineNumber, "LineNumber");
			
			If LineDepreciation <> Undefined Then
				StringParameters_.DepreciationInTaxAccounting = LineDepreciation.DepreciationInTaxAccounting;
			Else
				StringParameters_.DepreciationInTaxAccounting = 0;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillingBasedOn

// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - Document
//  FillingData - DocumentRef - fill-in data
Procedure FillInBasedOnDocument(Object, FillingData) Export

	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
		
		FillOutDocumentOnBasisOfAcceptanceForAccountingFA(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4") Then
		
		FillInDocumentBasedOnChangeInFAParameters(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsCostAdditions2_4") Then
		
		FillOutDocumentBasedOnFAUpgrade(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.MergeOfFixedAssets") Then
		
		FillInDocumentBasedOnFAAssociation(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.FARevaluation2_4") Then
		
		FillOutDocumentBasedOnFARevaluation(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.SplitFixedAssets") Then
		
		FillOutDocumentBasedOnFAConfiguration(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.DisposeFixedAssets2_4") Then
		
		FillOutDocumentBasedOnFAWriteOff(Object, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.AllocateVariancesToFixedAssetCost") Then
		
		FillOutDocumentOnBasisOfAttributionOfDeviationsToCostOfFA(Object, FillingData);
		
	EndIf;
	
EndProcedure

Procedure FillOutDocumentOnBasisOfAcceptanceForAccountingFA(Object, Basis)

	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.Date AS Date,
	|
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.DateOfRecognition, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentModeFromPreviousDate,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.DateOfRecognition, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN BEGINOFPERIOD(DocumentData.DateOfRecognition, MONTH)
	|		ELSE DATETIME(1,1,1)
	|	END AS BeginOfPeriod
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult)
	
EndProcedure

Procedure FillInDocumentBasedOnChangeInFAParameters(Object, Basis)

	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	ContinuePopulation = FixedAssetCostAndDepreciationAdjustmentLocalization.FillInDocumentBasedOnChangeInFAParameters(Object, Basis);
	
	If Not ContinuePopulation Then
		Return;
	EndIf;

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.ValidOnDate, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentModeFromPreviousDate,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.ValidOnDate, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN BEGINOFPERIOD(DocumentData.ValidOnDate, MONTH)
	|		ELSE DATETIME(1,1,1)
	|	END AS BeginOfPeriod
	|
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.ChangeFixedAssetFinancialDetails2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult)
	
EndProcedure

Procedure FillOutDocumentBasedOnFAUpgrade(Object, Basis)
	
	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.RenovationDate, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentModeFromPreviousDate,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.RenovationDate, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN BEGINOFPERIOD(DocumentData.RenovationDate, MONTH)
	|		ELSE DATETIME(1,1,1)
	|	END AS BeginOfPeriod
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FixedAssetsCostAdditions2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";

	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult)
	
EndProcedure

Procedure FillInDocumentBasedOnFAAssociation(Object, Basis)
	
	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset
	|
	|INTO CompletedAdjustments
	| 
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.DocumentBasis = &Basis
	|	AND DocumentData.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	FALSE AS AdjustmentModeFromPreviousDate,
	|	DATETIME(1,1,1) AS BeginOfPeriod,
	|
	|	CASE
	|		WHEN TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CompletedAdjustments AS CompletedAdjustments
	|					WHERE
	|						CompletedAdjustments.FixedAsset = DocumentData.FixedAsset)
	|			THEN TRUE
	|
	|		ELSE FALSE
	|
	|	END ThisIsOriginalFA
	|
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.FixedAsset AS FixedAsset,
	|	1 AS LineNumber
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CompletedAdjustments AS CompletedAdjustments
	|			WHERE
	|				CompletedAdjustments.FixedAsset = DocumentData.FixedAsset)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset,
	|	TabularSection.LineNumber AS LineNumber
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|
	|		INNER JOIN Document.MergeOfFixedAssets.FA TabularSection
	|		ON TabularSection.Ref = DocumentData.Ref
	|
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CompletedAdjustments AS CompletedAdjustments
	|			WHERE
	|				CompletedAdjustments.FixedAsset = DocumentData.FixedAsset)
	|
	|ORDER BY
	|	LineNumber
	|";

	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult)

EndProcedure

Procedure FillOutDocumentBasedOnFARevaluation(Object, Basis)
	
	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
	|	FALSE AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	FALSE AS AdjustmentModeFromPreviousDate,
	|	DATETIME(1,1,1) AS BeginOfPeriod
	|
	|FROM
	|	Document.FARevaluation2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FARevaluation2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";

	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult)

EndProcedure

Procedure FillOutDocumentBasedOnFAConfiguration(Object, Basis)
	
	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset
	|
	|INTO CompletedAdjustments
	| 
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.DocumentBasis = &Basis
	|	AND DocumentData.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	FALSE AS AdjustmentModeFromPreviousDate,
	|	DATETIME(1,1,1) AS BeginOfPeriod,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|					VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|
	|				AND NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CompletedAdjustments AS CompletedAdjustments
	|					WHERE
	|						CompletedAdjustments.FixedAsset = DocumentData.FixedAsset)
	|			THEN TRUE
	|
	|		ELSE FALSE
	|
	|	END ThisIsOriginalFA
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.FixedAsset AS FixedAsset,
	|	1 AS LineNumber
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			CompletedAdjustments AS CompletedAdjustments
	|		WHERE
	|			CompletedAdjustments.FixedAsset = DocumentData.FixedAsset)
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.LineNumber AS LineNumber
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|		INNER JOIN Document.SplitFixedAssets.FA FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|	AND (DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|		OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|				VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|			AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CompletedAdjustments AS CompletedAdjustments
	|			WHERE
	|				CompletedAdjustments.FixedAsset = DocumentData.FixedAsset)
	|		)
	|
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			CompletedAdjustments AS CompletedAdjustments
	|		WHERE
	|			CompletedAdjustments.FixedAsset = FATable.FixedAsset)
	|
	|ORDER BY
	|	LineNumber
	|";

	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult)

EndProcedure

Procedure FillOutDocumentBasedOnFAWriteOff(Object, Basis)
	
	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.DateOfDeduction, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentModeFromPreviousDate,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|				AND BEGINOFPERIOD(DocumentData.DateOfDeduction, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN BEGINOFPERIOD(DocumentData.DateOfDeduction, MONTH)
	|		ELSE DATETIME(1,1,1)
	|	END AS BeginOfPeriod
	|
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.DisposeFixedAssets2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";

	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(Object, QueryResult);

EndProcedure

Procedure FillOutDocumentOnBasisOfAttributionOfDeviationsToCostOfFA(Object, Basis)

	Object.FixedAssetKind = Enums.PropertyKinds.Own;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses)
	|			THEN FALSE
	|		ELSE DocumentData.RecordInTA 
	|	END AS RecordInTA,
	|
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.Date AS Date,
	|
	|
	|	TRUE AS AdjustmentModeFromPreviousDate,
	|
	|	CASE
	|		WHEN ISNULL(FixedAssetsInitialRecognition.AdjustmentModeFromPreviousDate, FALSE)
	|			THEN BEGINOFPERIOD(FixedAssetsInitialRecognition.DateOfRecognition, DAY)
	|
	|		WHEN ISNULL(FixedAssetsCostAdditions.AdjustmentModeFromPreviousDate, FALSE)
	|			THEN BEGINOFPERIOD(FixedAssetsCostAdditions.RenovationDate, DAY)
	|
	|		ELSE BEGINOFPERIOD(ISNULL(DocumentData.SourceDocument.Date, DocumentData.Date), MONTH) 
	|	END AS BeginOfPeriod
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = DocumentData.SourceDocument
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4 AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = DocumentData.SourceDocument
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost.FA AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	
	FillInDocument_(Object, QueryResult)
	
EndProcedure

Procedure FillInDocument_(Object, QueryResult)

	ThisIsAdditionalChargeFromDateOfAcceptanceForAccounting = False;
	
	If Not QueryResult[QueryResult.UBound()-1].IsEmpty() Then
		
		Selection = QueryResult[QueryResult.UBound()-1].Select();
		Selection.Next();
		FillPropertyValues(Object, Selection);
		
		Object.GeneratedDocument = ValueIsFilled(Object.DocumentBasis);
		
		If Object.AdjustmentModeFromPreviousDate
			And ValueIsFilled(Object.DocumentBasis)
			And TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
				
			ThisIsAdditionalChargeFromDateOfAcceptanceForAccounting = True;
		EndIf;
		
		If Object.AdjustmentModeFromPreviousDate
			And ValueIsFilled(Object.DocumentBasis) Then
				
			If (TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsInitialRecognition2_4")
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.FARevaluation2_4")) Then
			
				// The document is created for additional depreciation
				Object.AdjustmentOfInitialCost = False;
				Object.CostAdjustment = False;
				Object.CostIncreaseRecording = False;
				Object.CostDecreaseRecording = False;
				Object.DepreciationAdjustment = True;
				Object.DepreciationIncreaseRecording = True;
				Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease = True;
				Object.IncludesDepreciationOfCurrentMonth = True;
				Object.AdjustmentOfDepreciationCalculationParameters = False;
				
			ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.SplitFixedAssets")
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.MergeOfFixedAssets") Then
			
				Object.AdjustmentOfInitialCost = False;
				Object.CostAdjustment = False;
				Object.CostIncreaseRecording = False;
				Object.CostDecreaseRecording = False;
				Object.DepreciationAdjustment = True;
				Object.DepreciationIncreaseRecording = Not Selection.ThisIsOriginalFA;
				Object.DepreciationDecreaseRecording = Selection.ThisIsOriginalFA;
				Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease = Object.DepreciationIncreaseRecording;
				Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease = Object.DepreciationDecreaseRecording;
				Object.IncludesDepreciationOfCurrentMonth = True;
				Object.AdjustmentOfDepreciationCalculationParameters = False;
			
			ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsCostAdditions2_4")
				Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.AllocateVariancesToFixedAssetCost") Then
			
				// The document is created to adjust depreciation for the period
				Object.AdjustmentOfInitialCost = False;
				Object.CostAdjustment = False;
				Object.CostIncreaseRecording = False;
				Object.CostDecreaseRecording = False;
				Object.DepreciationAdjustment = True;
				Object.DepreciationAdjustmentForPeriod = True;
				Object.DepreciationIncreaseRecording = True;
				Object.DepreciationDecreaseRecording = True;
				Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease = True;
				Object.IncludesDepreciationOfCurrentMonth = True;
				Object.AdjustmentOfDepreciationCalculationParameters = False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If QueryResult[QueryResult.UBound()].IsEmpty() Then
		Return
	EndIf; 
		
	Object.FA.Load(QueryResult[QueryResult.UBound()].Unload());
	
	InitialInformation = Catalogs.Assets.InitialInformation(Object.FA[0].FixedAsset);
	Object.Organization = InitialInformation.Organization;
	Object.Department = InitialInformation.FixedAssetsLocation;
	Object.ApplicationOfTargetFinancing = InitialInformation.ApplicationOfTargetFinancing;

	If Object.ApplicationOfTargetFinancing Then
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease = True;
	EndIf;
	
	Documents.FixedAssetCostAndDepreciationAdjustment.FillInByAccountingData(Object);
	
	ParametersForCalculation = DepreciationCalculationParameters(CalculationParameters(Object));
	ProcessDepreciationCalculationParameters(Object, ParametersForCalculation);
	
	If ThisIsAdditionalChargeFromDateOfAcceptanceForAccounting Then
		
		AuxiliaryAttributes = AuxiliaryAttributes(Object);
		
		Depreciation = Object.FinancialDetailsForThePeriod.Total("Depreciation");
		
		If AuxiliaryAttributes.FALocalAccountingIsConductedIndependently Then
			DepreciationInAccounting = Object.FinancialDetailsForThePeriodAC.Total("DepreciationInAccounting");
		Else
			DepreciationInAccounting = Object.FinancialDetailsForThePeriod.Total("DepreciationLocal");
		EndIf;
		
		DepreciationPermanentDifferences = Object.FinancialDetailsForThePeriodAC.Total("DepreciationPermanentDifferences");
		FixedAssetDepreciationTargetFinancing = Object.FinancialDetailsForThePeriodAC.Total("FixedAssetDepreciationTargetFinancing");
		DepreciationInTaxAccounting = Object.FinancialDetailsForThePeriodTA.Total("DepreciationInTaxAccounting");
		
		For Each RowData In Object.FA Do
			RowData.DepreciationManagementAccounting = Depreciation;
			RowData.DepreciationInAccounting = DepreciationInAccounting;
			RowData.DepreciationInTaxAccounting = DepreciationInTaxAccounting;
			RowData.DepreciationPermanentDifferences = DepreciationPermanentDifferences;
			RowData.FixedAssetDepreciationTargetFinancing = FixedAssetDepreciationTargetFinancing;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters(Object) Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	#Region CostIncrease
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeLiabilityItemCostIncrease";
	ChoiceParameters.ArticleType = "TypeOfIncomeItemCostIncrease";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.CostAdjustment
		And Object.CostIncreaseRecording
		And (Not Object.RecordCostChangeInTADueToPD
			Or Object.RecordInManAccounting
			Or Object.PostInAccounting);
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionCostIncrease";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimensionCostIncrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeLiabilityItemCostIncrease");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionCostIncrease");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesIncomeDimensionCostIncrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region CostReduction
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "AssetExpenseItemCostReduction";
	ChoiceParameters.ArticleType = "TypeOfExpenditureItemCostReduction";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.CostAdjustment
		And Object.CostDecreaseRecording
		And (Not Object.RecordCostChangeInTADueToPD
			Or Object.RecordInManAccounting
			Or Object.PostInAccounting);
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpensesCostReduction";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionCostDecrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("AssetExpenseItemCostReduction");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpensesCostReduction");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionCostDecrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region IncreasedDepreciation
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "AssetExpenseItemDepreciationIncrease";
	ChoiceParameters.ArticleType = "TypeOfExpenseItemIncreaseInDepreciation";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.DepreciationAdjustment
		And Object.DepreciationIncreaseRecording;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpensesDepreciationIncrease";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionDepreciationIncrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("AssetExpenseItemDepreciationIncrease");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpensesDepreciationIncrease");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionDepreciationIncrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);

	#EndRegion
	
	#Region DecreaseInDepreciationOfCurrentYear
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemThisYearDepreciationDecrease";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.DepreciationAdjustment
		And Object.RecordThisYearDepreciationDecreaseAsStorno;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionThisYearDepreciationDecrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemThisYearDepreciationDecrease");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionThisYearDepreciationDecrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);

	#EndRegion
	
	#Region DecreaseInDepreciation
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeLiabilityItemDepreciationDecrease";
	ChoiceParameters.ArticleType = "TypeOfIncomeItemDepreciationReduction";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.DepreciationAdjustment
		And Object.DepreciationDecreaseRecording;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionDepreciationDecrease";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimensionDepreciationDecrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeLiabilityItemDepreciationDecrease");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionDepreciationDecrease");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesIncomeDimensionDepreciationDecrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region IncreaseInDepreciationPremium
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "AssetExpenseItemCostDecrease";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.BonusDepreciationAdjustment
		And (Object.BonusDepreciationIncreaseRecording
			Or Object.BonusDepreciationDecreaseRecording
				And Object.RecordingOfBonusDepreciationDecreaseStorno);
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionBonusDepreciation";
	
	ChoiceParameters.FormItems.AssetRef.Add("AssetExpenseItemCostDecrease");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionBonusDepreciation");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region DecreaseInBonusDepreciation
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeLiabilityItemBonusDepreciationDecrease";
	ChoiceParameters.ArticleType = "TypeOfIncomeItemBonusDepreciationReduction";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.BonusDepreciationAdjustment
		And Object.BonusDepreciationDecreaseRecording
		And Not Object.RecordingOfBonusDepreciationDecreaseStorno;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenueDecreaseInBonusDepreciation";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionBonusDepreciationDecrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeLiabilityItemBonusDepreciationDecrease");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenueDecreaseInBonusDepreciation");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionBonusDepreciationDecrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region IncreaseInCFRevenues
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "AssetExpenseItemTargetFinancingIncomeIncrease";
	ChoiceParameters.ArticleType = "TypeOfExpenditureItemIncreaseInCFRevenues";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.CostAdjustment
		And Object.CostIncreaseRecording
		And Object.ApplicationOfTargetFinancing;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpensesDecreaseInIncomeTF";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionTargetFinancingIncomeIncrease";
	
	ChoiceParameters.FormItems.AssetRef.Add("AssetExpenseItemTargetFinancingIncomeIncrease");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpensesDecreaseInIncomeTF");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionTargetFinancingIncomeIncrease");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion

	#Region DecreaseInIncomeOfTF
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeLiabilityItemTargetFinancingIncomeDecrease";
	ChoiceParameters.ArticleType = "TypeOfIncomeItemReductionOfCFIncome";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And Object.CostAdjustment
		And Object.CostDecreaseRecording
		And Object.ApplicationOfTargetFinancing;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenueDecreaseInIncomeTF";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimensionDecreaseInIncomeTF";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeLiabilityItemTargetFinancingIncomeDecrease");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenueDecreaseInIncomeTF");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesIncomeDimensionDecreaseInIncomeTF");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	#EndRegion

	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

Function AccountingAccountSettings_() Export
	
	ParametersArray = New Array();
			
	#Region CostIncrease
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "IncomeLedgerAccountsSettingsCostIncrease";
	SetupParameters.AssetAndLiabilityItem = "IncomeLiabilityItemCostIncrease";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimensionCostIncrease";
	SetupParameters.Presentation = "PresentationOfReflectionCostIncrease";
	SetupParameters.ArticleType = "TypeOfIncomeItemCostIncrease";

	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionCostIncrease");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region CostReduction
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "ExpenseLedgerAccountsSettingsCostDecrease";
	SetupParameters.AssetAndLiabilityItem = "AssetExpenseItemCostReduction";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionCostDecrease";
	SetupParameters.Presentation = "PresentationOfReflectionCostReduction";
	SetupParameters.ArticleType = "TypeOfExpenditureItemCostReduction";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionCostReduction");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region IncreasedDepreciation
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "LedgerExpensesAccountSettingsIncreasedDepreciation";
	SetupParameters.AssetAndLiabilityItem = "AssetExpenseItemDepreciationIncrease";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionDepreciationIncrease";
	SetupParameters.Presentation = "PresentationOfReflectionIncreaseInDepreciation";
	SetupParameters.ArticleType = "TypeOfExpenseItemIncreaseInDepreciation";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionIncreaseInDepreciation");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region DecreaseInDepreciation
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "IncomeLedgerAccountsSettingsDepreciationDecrease";
	SetupParameters.AssetAndLiabilityItem = "IncomeLiabilityItemDepreciationDecrease";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimensionDepreciationDecrease";
	SetupParameters.Presentation = "PresentationOfReflectionReductionOfDepreciation";
	SetupParameters.ArticleType = "TypeOfIncomeItemDepreciationReduction";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionReductionOfDepreciation");
	ParametersArray.Add(SetupParameters);
	#EndRegion

	#Region DecreaseInBonusDepreciation
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "LedgerAccountSettingsDecreaseInBonusDepreciation";
	SetupParameters.AssetAndLiabilityItem = "IncomeLiabilityItemBonusDepreciationDecrease";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionBonusDepreciationDecrease";
	SetupParameters.Presentation = "PresentationOfReflectionReductionOfBonusDepreciation";
	SetupParameters.ArticleType = "TypeOfIncomeItemBonusDepreciationReduction";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionReductionOfBonusDepreciation");
	ParametersArray.Add(SetupParameters);
	#EndRegion

	#Region IncreaseInCFRevenues
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "ExpenseLedgerAccountsSettingsIncreaseIncomeTF";
	SetupParameters.AssetAndLiabilityItem = "AssetExpenseItemTargetFinancingIncomeIncrease";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionTargetFinancingIncomeIncrease";
	SetupParameters.Presentation = "PresentationOfReflectionIncreaseInCFRevenues";
	SetupParameters.ArticleType = "TypeOfExpenditureItemIncreaseInCFRevenues";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionIncreaseInCFRevenues");
	ParametersArray.Add(SetupParameters);
	#EndRegion

	#Region DecreaseInIncomeOfTF
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "LedgerAccountSettingsTargetFinancingIncomeDecrease";
	SetupParameters.AssetAndLiabilityItem = "IncomeLiabilityItemTargetFinancingIncomeDecrease";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimensionDecreaseInIncomeTF";
	SetupParameters.Presentation = "PresentationOfReflectionOfDecreaseInIncomeOfCF";
	SetupParameters.ArticleType = "TypeOfIncomeItemReductionOfCFIncome";

	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfReflectionOfDecreaseInIncomeOfCF");
	ParametersArray.Add(SetupParameters);
	#EndRegion

	Return ParametersArray;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - Object
//  RowsSelected - Array, Undefined -  Selected lines
Procedure FillInByAccountingData(Object, RowsSelected = Undefined) Export

	If RowsSelected <> Undefined
		And RowsSelected.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = FixedAssetCostAndDepreciationAdjustmentLocalization.QueryTextFillInByAccountingData();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	CostAndDepreciation.FixedAsset AS FixedAsset,
		|
		|	SUM(CostAndDepreciation.CostInManagementAccounting) AS CostInManagementAccounting,
		|	SUM(CostAndDepreciation.CostInAccounting) AS CostInAccounting,
		|	SUM(CostAndDepreciation.CostInTaxAccounting) AS CostInTaxAccounting,
		|	SUM(CostAndDepreciation.CostPermanentDifference) AS CostPermanentDifference,
		|	SUM(CostAndDepreciation.CostTargetFinancing) AS CostTargetFinancing,
		|	SUM(CostAndDepreciation.DepreciationInAccounting) AS DepreciationInAccounting,
		|	SUM(CostAndDepreciation.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
		|	SUM(CostAndDepreciation.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
		|	SUM(CostAndDepreciation.DepreciationManagementAccounting) AS DepreciationManagementAccounting,
		|	SUM(CostAndDepreciation.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing,
		|	SUM(CostAndDepreciation.SecurityDepositValue) AS SecurityDepositValue
		|
		|INTO CostAndDepreciation
		|
		|FROM
		|	(SELECT
		|		FACostBalance.FixedAsset AS FixedAsset,
		|		FACostBalance.CostBalance AS CostInManagementAccounting,
		|		FACostBalance.LocalCostBalance AS CostInAccounting,
		|		FACostBalance.CostInTaxAccountingBalance AS CostInTaxAccounting,
		|		FACostBalance.CostPermanentDifferenceBalance AS CostPermanentDifference,
		|		FACostBalance.CostTargetFinancingBalance AS CostTargetFinancing,
		|		FACostBalance.SecurityDepositValueBalance AS SecurityDepositValue,
		|		0 AS DepreciationInAccounting,
		|		0 AS DepreciationInTaxAccounting,
		|		0 AS DepreciationPermanentDifferences,
		|		0 AS DepreciationManagementAccounting,
		|		0 AS FixedAssetDepreciationTargetFinancing
		|	FROM
		|		AccumulationRegister.FACost.Balance(
		|				&PeriodLimit,
		|				&CostAdjustment
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS FACostBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FACost.FixedAsset,
		|		FACost.Cost,
		|		CASE
		|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -FACost.LocalCost
		|			ELSE FACost.LocalCost
		|		END,
		|		CASE
		|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -FACost.CostInTaxAccounting
		|			ELSE FACost.CostInTaxAccounting
		|		END,
		|		CASE
		|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -FACost.CostPermanentDifference
		|			ELSE FACost.CostPermanentDifference
		|		END,
		|		CASE
		|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -FACost.CostTargetFinancing
		|			ELSE FACost.CostTargetFinancing
		|		END,
		|		CASE
		|			WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -FACost.SecurityDepositValue
		|			ELSE FACost.SecurityDepositValue
		|		END,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		AccumulationRegister.FACost AS FACost
		|	WHERE
		|		FACost.Recorder = &Ref
		|		AND FACost.Organization = &Organization
		|		AND FACost.Period < &Period
		|		AND &CostAdjustment
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FixedAssetsDepreciationChargeBalance.FixedAsset,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		-FixedAssetsDepreciationChargeBalance.DepreciationLocalBalance,
		|		-FixedAssetsDepreciationChargeBalance.DepreciationInTaxAccountingBalance,
		|		-FixedAssetsDepreciationChargeBalance.DepreciationPermanentDifferencesBalance,
		|		-FixedAssetsDepreciationChargeBalance.DepreciationBalance,
		|		-FixedAssetsDepreciationChargeBalance.FixedAssetDepreciationTargetFinancingBalance
		|	FROM
		|		AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
		|				&PeriodLimit,
		|				&DepreciationAdjustment
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsDepreciationChargeBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FixedAssetsDepreciationCharge.FixedAsset,
		|		FixedAssetsDepreciationCharge.Depreciation,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.DepreciationLocal
		|			ELSE FixedAssetsDepreciationCharge.DepreciationLocal
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
		|			ELSE FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
		|			ELSE FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.Depreciation
		|			ELSE FixedAssetsDepreciationCharge.Depreciation
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
		|			ELSE FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
		|		END
		|	FROM
		|		AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
		|	WHERE
		|		FixedAssetsDepreciationCharge.Recorder = &Ref
		|		AND FixedAssetsDepreciationCharge.Organization = &Organization
		|		AND FixedAssetsDepreciationCharge.Period < &Period
		|		AND &DepreciationAdjustment
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		FixedAssetsDepreciationCharge.FixedAsset,
		|		FixedAssetsDepreciationCharge.Depreciation,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.DepreciationLocal
		|			ELSE FixedAssetsDepreciationCharge.DepreciationLocal
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
		|			ELSE FixedAssetsDepreciationCharge.DepreciationInTaxAccounting
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
		|			ELSE FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.Depreciation
		|			ELSE FixedAssetsDepreciationCharge.Depreciation
		|		END,
		|		CASE
		|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
		|			ELSE FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
		|		END
		|	FROM
		|		AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
		|	WHERE
		|		FixedAssetsDepreciationCharge.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
		|		AND FixedAssetsDepreciationCharge.Organization = &Organization
		|		AND FixedAssetsDepreciationCharge.Period < &Period
		|		AND FixedAssetsDepreciationCharge.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
		|		AND &DepreciationAdjustment
		|
		|	) AS CostAndDepreciation
		|
		|GROUP BY
		|	CostAndDepreciation.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
		|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationInAccounting,
		|	-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
		|	-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
		|	-FixedAssetsDepreciationCharge.DepreciationBalance AS DepreciationManagementAccounting,
		|	-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing
		|
		|INTO DepreciationAsOfTheYearStart
		|
		|FROM
		|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
		|			&BegOfYear,
		|			&SeparateAdjustmentOfCurrentAndPreviousPeriods
		|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetsDepreciationCharge
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfFA.Ref AS FixedAsset,
		|
		|	CostAndDepreciation.CostInManagementAccounting AS CostInManagementAccounting,
		|	CostAndDepreciation.CostInAccounting AS CostInAccounting,
		|	CostAndDepreciation.CostInTaxAccounting AS CostInTaxAccounting,
		|	CostAndDepreciation.CostPermanentDifference AS CostPermanentDifference,
		|	CostAndDepreciation.CostTargetFinancing AS CostTargetFinancing,
		|	CostAndDepreciation.SecurityDepositValue AS SecurityDepositValue,
		|
		|	CostAndDepreciation.DepreciationInAccounting AS DepreciationInAccounting,
		|	CostAndDepreciation.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
		|	CostAndDepreciation.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
		|	CostAndDepreciation.DepreciationManagementAccounting AS DepreciationManagementAccounting,
		|	CostAndDepreciation.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
		|
		|	DepreciationAsOfTheYearStart.DepreciationInAccounting AS DepreciationAsOfTheYearStartBookkeeping,
		|	DepreciationAsOfTheYearStart.DepreciationInTaxAccounting AS DepreciationAsOfTheYearStartTaxAccounting,
		|	DepreciationAsOfTheYearStart.DepreciationPermanentDifferences AS PermanentDifferencesInDepreciationAsOfTheYearStart,
		|	DepreciationAsOfTheYearStart.DepreciationManagementAccounting AS DepreciationAtBeginningOfYearMa,
		|	DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing AS TargetFundsInDepreciationAsOfTheYearStart,
		|
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationInManagementAccounting,
		|	FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationInAccounting
		|
		|FROM
		|	Catalog.Assets AS ListOfFA
		|
		|		LEFT JOIN CostAndDepreciation AS CostAndDepreciation
		|		ON CostAndDepreciation.FixedAsset = ListOfFA.Ref
		|
		|		LEFT JOIN DepreciationAsOfTheYearStart AS DepreciationAsOfTheYearStart
		|		ON DepreciationAsOfTheYearStart.FixedAsset = ListOfFA.Ref
		|
		|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|			&Period,
		|			&AdjustmentOfInitialCost
		|				AND Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND Organization = &Organization
		|				AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformation
		|		ON (InitialFixedAssetsInformation.FixedAsset = ListOfFA.Ref)
		|			AND (InitialFixedAssetsInformation.Organization = &Organization)
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|			&Period,
		|			&AdjustmentOfDepreciationCalculationParameters
		|				AND Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND Organization = &Organization
		|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = ListOfFA.Ref)
		|			AND (FixedAssetDepreciationParametersManagementAccounting.Organization = &Organization)
		|
		|WHERE
		|	ListOfFA.Ref IN (&ListOfFA)
		|";
		
	EndIf; 
	
	ObjectAttributes = Common.ObjectAttributesValues(Object.Ref,
		New Structure("FixedAssetsEvent, ParentCompany", "FixedAssetsEvent.EventKindWithFixedAssets", "Organization.ParentCompany"));
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("ParentCompany", ObjectAttributes.ParentCompany);
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	Query.SetParameter("AdjustmentOfInitialCost", Object.AdjustmentOfInitialCost);
	Query.SetParameter("DepreciationAdjustment", Object.DepreciationAdjustment);
	Query.SetParameter("AdjustmentOfDepreciationCalculationParameters", Object.AdjustmentOfDepreciationCalculationParameters);
	Query.SetParameter("SeparateAdjustmentOfCurrentAndPreviousPeriods", Object.SeparateAdjustmentOfCurrentAndPreviousPeriods);
	
	If Object.FixedAssetKind = Enums.PropertyKinds.Leased
		Or Object.CostAdjustment Then
		Query.SetParameter("CostAdjustment", True);
	Else
		Query.SetParameter("CostAdjustment", False);
	EndIf;
	
	ThisChangeIsERP = Object.PeriodAdjustment <> 0 And ObjectAttributes.FixedAssetsEvent = Enums.EventKindsWithFixedAssets.Other;
	Query.SetParameter("ChangingERP", ThisChangeIsERP);
	
	Period = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	Query.SetParameter("PeriodLimit", New Boundary(Period, BoundaryType.Excluding));
	Query.SetParameter("Period", Period);
	Query.SetParameter("UPPeriod", Period+1);
	Query.SetParameter("BegOfYear", BegOfYear(Period));
	
	ListOfFA = Object.FA.Unload(RowsSelected).UnloadColumn("FixedAsset");
	Query.SetParameter("ListOfFA", ListOfFA);
	
	CostAndDepreciation = Query.Execute().Unload();
	CostAndDepreciation.Indexes.Add("FixedAsset");
	
	If RowsSelected <> Undefined Then
		StringsList = RowsSelected;
	Else
		StringsList = Object.FA;
	EndIf; 
	
	For Each RowData In StringsList Do
		
		DataOfAccounting = CostAndDepreciation.Find(RowData.FixedAsset, "FixedAsset");
		If DataOfAccounting <> Undefined Then
			
			FillPropertyValues(RowData, DataOfAccounting);
		
		Else
			
			RowData.CostInAccounting = 0;
			RowData.CostInTaxAccounting = 0;
			RowData.CostPermanentDifference = 0;
			RowData.CostInManagementAccounting = 0;
			RowData.CostTargetFinancing = 0;
			RowData.DepreciationInAccounting = 0;
			RowData.DepreciationInTaxAccounting = 0;
			RowData.DepreciationPermanentDifferences = 0;
			RowData.DepreciationManagementAccounting = 0;
			RowData.FixedAssetDepreciationTargetFinancing = 0;
			RowData.DepreciationAsOfTheYearStartBookkeeping = 0;
			RowData.DepreciationAsOfTheYearStartTaxAccounting = 0;
			RowData.PermanentDifferencesInDepreciationAsOfTheYearStart = 0;
			RowData.DepreciationAtBeginningOfYearMa = 0;
			RowData.TargetFundsInDepreciationAsOfTheYearStart = 0;
			RowData.SecurityDepositValue = 0;
			RowData.InitialCostLocalAccounting = 0;
			RowData.InitialCostTA = 0;
			RowData.InitialCostMA = 0;
			RowData.CostUsedToCalculateDepreciationInAccounting = 0;
			RowData.CostUsedToCalculateDepreciationInManagementAccounting = 0;
			RowData.PermanentDifferencesUsedToCalculateDepreciation = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure
 
// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - 
//  FormServiceParameters - Structure -
// 
Procedure GetParametersOfAccountingPoliciesForPeriod(Object, FormServiceParameters) Export
	
	ProcedureForCalculatingManSDepreciation = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
	DepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
	ProcedureForCalculatingDepreciationManLease = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
	LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
	FALocalAccountingIsConductedIndependently = True;
	FSB6IsApplied = True;
	
	ReglParametersAreReceived = FixedAssetCostAndDepreciationAdjustmentLocalization.GetParametersOfAccountingPoliciesForPeriod(
								Object, FormServiceParameters);
	
	If Object.AdjustmentModeFromPreviousDate
		And ValueIsFilled(Object.BeginOfPeriod)
		And ValueIsFilled(Object.Organization) Then
			
		DocumentDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
		
		QueryText = 
		"SELECT
		|	ISNULL(MAX(CASE 
		|		WHEN AccountingPolicy.DepreciationProcedure = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) 
		|			THEN TRUE 
		|		ELSE FALSE 
		|	END), TRUE) AS FromDateOfTakingIntoAccountUpr,
		|
		|	ISNULL(MAX(CASE 
		|		WHEN AccountingPolicy.DepreciationChargeProcedureLocal = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) 
		|			THEN TRUE 
		|		ELSE FALSE 
		|	END), TRUE) AS FromDateOfTakingIntoAccountRegl,
		|
		|	ISNULL(MAX(CASE 
		|		WHEN AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) 
		|			THEN TRUE 
		|		ELSE FALSE 
		|	END), TRUE) AS FromDateOfAcceptanceForAccountingManLease,
		|
		|	ISNULL(MAX(CASE 
		|		WHEN AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) 
		|			THEN TRUE 
		|		ELSE FALSE 
		|	END), TRUE) AS FromDateOfLocalLeaseAcceptanceForAccounting,
		|
		|	ISNULL(MAX(CASE 
		|		WHEN AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent) 
		|			THEN TRUE 
		|		ELSE FALSE 
		|	END), TRUE) AS FALocalAccountingIsConductedIndependently
		|
		|FROM
		|	(SELECT
		|		AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge AS DepreciationProcedure,
		|		AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal AS DepreciationChargeProcedureLocal,
		|		AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag AS LeasedAssetDepreciationChargeProcedureManag,
		|		AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal AS LeasedFixedAssetDepreciationChargeProcedureLocal,
		|		AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting
		|	FROM
		|		InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
		|	WHERE
		|		AccountingPolicy.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND AccountingPolicy.Organization = &ParentCompany
		|
		|	UNION ALL
		|
		|	SELECT
		|		AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge AS DepreciationProcedure,
		|		AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal AS DepreciationChargeProcedureLocal,
		|		AccountingPolicy.LeasedAssetDepreciationChargeProcedureManag AS LeasedAssetDepreciationChargeProcedureManag,
		|		AccountingPolicy.LeasedFixedAssetDepreciationChargeProcedureLocal AS LeasedFixedAssetDepreciationChargeProcedureLocal,
		|		AccountingPolicy.FixedAssetAccountingProcedureInLocalAccounting AS FixedAssetAccountingProcedureInLocalAccounting
		|	FROM
		|		InformationRegister.FinancialAccountingPolicy.SliceLast(&BeginOfPeriod, Organization = &ParentCompany) AS AccountingPolicy
		|
		|	) AS AccountingPolicy
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("ParentCompany", Common.ObjectAttributeValue(Object.Organization, "ParentCompany"));
		Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", BegOfDay(DocumentDate) - 1);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
			
			If Selection.FromDateOfTakingIntoAccountUpr Then
				ProcedureForCalculatingManSDepreciation = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
			Else
				ProcedureForCalculatingManSDepreciation = Enums.DepreciationProcedure.StartingNextMonth;
			EndIf;
			
			If Selection.FromDateOfTakingIntoAccountRegl Then
				DepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
			Else
				DepreciationChargeProcedureLocal = Enums.DepreciationProcedure.StartingNextMonth;
			EndIf;
			
			If Selection.FromDateOfAcceptanceForAccountingManLease Then
				ProcedureForCalculatingDepreciationManLease = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
			Else
				ProcedureForCalculatingDepreciationManLease = Enums.DepreciationProcedure.StartingNextMonth;
			EndIf;
			
			If Selection.FromDateOfLocalLeaseAcceptanceForAccounting Then
				LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
			Else
				LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.StartingNextMonth;
			EndIf;
			
			FALocalAccountingIsConductedIndependently = Selection.FALocalAccountingIsConductedIndependently;
			
		EndIf;
		
	EndIf;
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"ProcedureForCalculatingDepreciationUpr_ForPeriod",
		ProcedureForCalculatingManSDepreciation,
		FormServiceParameters);
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"ProcedureForCalculatingDepreciationManLease_ForPeriod",
		ProcedureForCalculatingDepreciationManLease,
		FormServiceParameters);
	
	If Not ReglParametersAreReceived Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ProcedureForCalculatingDepreciationRegl_ForPeriod",
			DepreciationChargeProcedureLocal,
			FormServiceParameters);
	
		NonCurrentAssetsInternal.SetStructureProperty(
			"DepreciationProcedureLocalLease_ForPeriod",
			LeasedFixedAssetDepreciationChargeProcedureLocal,
			FormServiceParameters);
	
		NonCurrentAssetsInternal.SetStructureProperty(
			"ReglVNAAccountingIsConductedIndependently_ForPeriod",
			FALocalAccountingIsConductedIndependently,
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FSB6_IsAppliedForPeriod",
			FSB6IsApplied,
			FormServiceParameters);
			
	EndIf;
		
EndProcedure

Function TheseAreRentedFA(Object) Export
	
	TheseAreRentedFA = False;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			TheseAreRentedFA = LeasedAssetAccounting.FixedAssetsAreLeased(
									RowData.FixedAsset,
									?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
			Break;
		EndIf;
	EndDo;
	
	Return TheseAreRentedFA;
	
EndFunction

Function AuxiliaryAttributes(Object) Export
	
	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("AccountingPolicyForFixedAssets", AccountingPoliciesTaxSettingsCached.AccountingPolicyForFixedAssets(Object.Organization, DateOfParameters));
	AuxiliaryAttributes.Insert("FSB6IsApplied", AccountingPoliciesTaxSettingsCached.FSB6IsApplied(Object.Organization, DateOfParameters));
	AuxiliaryAttributes.Insert("IncomeTaxPayer", False);
	AuxiliaryAttributes.Insert("SupportPBU18", False);
	AuxiliaryAttributes.Insert("CalculationOfPermanentAndTemporaryDifferencesIsKept", False);

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert("UseFixedAssetAccountingByActivities", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfParameters));
	
	Documents.FixedAssetCostAndDepreciationAdjustment.GetParametersOfAccountingPoliciesForPeriod(Object, AuxiliaryAttributes);
		
	FixedAssetCostAndDepreciationAdjustmentLocalization.AddAuxiliaryDetails(Object, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

Function CalculationParameters(Object) Export
	
	FunctionParameters = New Structure;
	FunctionParameters.Insert("Ref", Object.Ref);
	FunctionParameters.Insert("Date", Object.Date);
	FunctionParameters.Insert("Organization", Object.Organization);
	FunctionParameters.Insert("FA", Object.FA.Unload());
	FunctionParameters.Insert("AdjustmentModeFromPreviousDate", Object.AdjustmentModeFromPreviousDate);
	FunctionParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	FunctionParameters.Insert("BonusDepreciationAdjustment", Object.BonusDepreciationAdjustment);
	FunctionParameters.Insert("BonusDepreciationIncreaseRecording", Object.BonusDepreciationIncreaseRecording);
	FunctionParameters.Insert("IncludesDepreciationOfCurrentMonth", Object.IncludesDepreciationOfCurrentMonth);
	FunctionParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FunctionParameters.Insert("RecordInTA", Object.RecordInTA);
	FunctionParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	
	Return FunctionParameters; 
	
EndFunction

Function TextOfDepreciationAdjustmentLabel(Basis) Export
	
	QueryText = 
	"SELECT TOP 1
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Priority AS Priority
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		DocumentData.Number AS Number,
	|		DocumentData.Date AS Date,
	|		DocumentData.Posted AS Posted,
	|		1 AS Priority
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|	WHERE
	|		DocumentData.DocumentBasis = &Basis
	|		AND DocumentData.DepreciationAdjustment
	|		AND DocumentData.Posted
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Ref AS Ref,
	|		DocumentData.Number AS Number,
	|		DocumentData.Date AS Date,
	|		DocumentData.Posted AS Posted,
	|		2 AS Priority
	|	FROM
	|		Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|	WHERE
	|		DocumentData.DocumentBasis = &Basis
	|		AND DocumentData.DepreciationAdjustment
	|		AND NOT DocumentData.Posted
	|		AND NOT DocumentData.DeletionMark
	|
	|	) AS DocumentData
	|
	|ORDER BY
	|	Priority
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	StringsList = New Array;
	
	If Selection.Next() Then
		
		If Selection.Posted Then
			Text = NStr("vi = 'Đã tạo điều chỉnh %1 ngày %2';
						|ru = 'Оформлена корректировка %1 от %2';
						|en = 'The %1 adjustment dated %2 is registered'; fa = 'The %1 adjustment dated %2 is registered';
						|it = 'Оформлена корректировка %1 от %2';
						|pl = 'The %1 adjustment dated %2 is registered';
						|tr = '%2 üzerinden %1 düzeltmesi yapıldı'");
		Else	
			Text = NStr("vi = 'Đã tạo điều chỉnh %1 ngày %2 (chưa kết chuyển)';
						|ru = 'Создана корректировка %1 от %2 (не проведен)';
						|en = 'The %1 adjustment dated %2 is created (not posted)'; fa = 'The %1 adjustment dated %2 is created (not posted)';
						|it = 'Создана корректировка %1 от %2 (не проведен)';
						|pl = 'The %1 adjustment dated %2 is created (not posted)';
						|tr = '%2 üzerinden %1 düzeltmesi oluşturuldu (kaydedilmedi)'");
		EndIf;
		Text = StrTemplate(Text, Selection.Number, Format(Selection.Date, "DLF=D;"));		
		Text = New FormattedString(Text,,,, GetURL(Selection.Ref));
		StringsList.Add(Text);
		
	Else
		
		StringsList.Add(NStr("vi = 'Chưa tạo điều chỉnh khấu hao';
							|ru = 'Корректировка амортизации не создана';
							|en = 'Depreciation adjustment is not created'; fa = 'Depreciation adjustment is not created';
							|it = 'Корректировка амортизации не создана';
							|pl = 'Depreciation adjustment is not created';
							|tr = 'Amortisman düzeltmesi oluşturulmadı'"));

		If AccessRight("InteractiveInsert", Metadata.Documents.FixedAssetCostAndDepreciationAdjustment) Then
			StringsList.Add(" ");
			StringsList.Add("(");
			StringsList.Add(New FormattedString(NStr("vi = 'tạo mới';
													|ru = 'создать';
													|en = 'create'; fa = 'ایجاد';
													|it = 'создать';
													|pl = 'create';
													|tr = 'oluştur'"),,,, "#Create"));
			StringsList.Add(")");
		EndIf;
		
	EndIf;
	
	Return New FormattedString(StringsList);
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.FixedAssetCostAndDepreciationAdjustment.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("3565c48d-ce97-490b-a49a-f12978a4c012");
	Handler.UpdateDataFillingProcedure = "Documents.FixedAssetCostAndDepreciationAdjustment.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang cập nhật chứng từ ""Điều chỉnh giá trị và khấu hao TSCĐ"":
								  |- điền mục tin mới ""Phản ánh trong KTTh""';
								  |ru = 'Обновляет документы ""Корректировка стоимости и амортизации ОС"":
								  |- заполняет новый реквизит ""Отражать в НУ""';
								  |en = 'Updates the ""Adjust fixed asset cost and depreciation"" documents:
								  |- Fills in the new ""Record in TA"" attribute'; fa = 'Updates the ""Adjust fixed asset cost and depreciation"" documents:
								  |- Fills in the new ""Record in TA"" attribute';
								  |it = 'Updates the ""Adjust fixed asset cost and depreciation"" documents:
								  |- Fills in the new ""Record in TA"" attribute';
								  |pl = 'Updates the ""Adjust fixed asset cost and depreciation"" documents:
								  |- Fills in the new ""Record in TA"" attribute';
								  |tr = '""Sabit kıymet maliyet ve amortisman düzeltmesi"" belgelerini günceller:
								  |- Yeni ""Vergi muhasebesine yansıtın"" özniteliğini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName());

	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.FixedAssetCostAndDepreciationAdjustment";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|WHERE
	|	(DocumentData.FixedAssetKind <> VALUE(Enum.PropertyKinds.Leased)
	|		AND DocumentData.RecordInLocalAccounting
	|		AND NOT DocumentData.PostInAccounting
	|		AND NOT DocumentData.RecordInTA
	|
	|	OR DocumentData.DocumentBasis <> UNDEFINED
	|		AND NOT DocumentData.GeneratedDocument)
	|";
	
	Query = New Query(QueryText);

	ReferenceList = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, ReferenceList);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.FixedAssetCostAndDepreciationAdjustment.ProcessDataForMigrationToNewVersion");
		
	FullObjectName = "Document.FixedAssetCostAndDepreciationAdjustment";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;

	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.FixedAssetCostAndDepreciationAdjustment
			If DocumentObject = Undefined Then
				CommitTransaction();
				InfobaseUpdate.MarkProcessingCompletion(Document.Ref);
				Continue;
			EndIf;
			
			If ValueIsFilled(DocumentObject.DocumentBasis)
				And Not DocumentObject.GeneratedDocument Then
				
				DocumentObject.GeneratedDocument = True;
			
			ElsIf Not ValueIsFilled(DocumentObject.DocumentBasis)
				And DocumentObject.DocumentBasis <> Undefined Then
				
				DocumentObject.DocumentBasis = Undefined;
			EndIf;
			
			If DocumentObject.FixedAssetKind <> Enums.PropertyKinds.Leased
				And DocumentObject.RecordInLocalAccounting
				And Not DocumentObject.PostInAccounting
				And Not DocumentObject.RecordInTA Then
				
				DocumentObject.PostInAccounting = True;
				
				
			EndIf;

			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(DocumentObject.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
		EndTry;
		
	EndDo;
	
 	NonCurrentAssetsInternal.CheckHandlerExecution(
 		ObjectsWithIssuesCount, 
 		ObjectsProcessed, 
 		FullObjectName);
 		
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ObjectsProcessed);	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
