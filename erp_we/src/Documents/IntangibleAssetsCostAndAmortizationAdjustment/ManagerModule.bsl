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
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	
	IntangibleAssetsCostAndAmortizationAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IntangibleAssetsCostAndAmortizationAdjustment") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers);
		
		QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		IntangibleAssetsCostAndAmortizationAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	QueryTexts = New ValueList;
	
	QueryTextTableIACost(QueryTexts);
	QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts);

	QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts, Undefined);
	
	QueryTextTableOtherExpenses(QueryTexts);
	QueryTextTableItemisedExpensesLots(QueryTexts);
	QueryTextTableOtherAssetsLiabilities(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	QueryTextTableOtherIncome(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	IntangibleAssetsCostAndAmortizationAdjustmentLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
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
	
	Documents.ChangeIntangibleAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);

EndProcedure

// Adds the command to create the document "adjusting the cost and depreciation of IA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment);
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

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.IntangibleAssetsCostAndAmortizationAdjustment";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, RegisterName);
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
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
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
	|	DocumentDataDetails.Period AS Period,
	|	DocumentDataDetails.Number AS Number,
	|	DocumentDataDetails.Organization AS Organization
	|	
	|FROM
	|	DocumentDataDetails AS DocumentDataDetails";
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
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentsList
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
	|	DocumentData.AssetsLiabilitiesIncomeDimensionDecreaseInIncomeTF AS AssetsLiabilitiesIncomeDimensionDecreaseInIncomeTF,
	|	DocumentData.DimensionDepreciationIncrease AS DimensionDepreciationIncrease,
	|	DocumentData.DimensionCostDecrease AS DimensionCostDecrease,
	|	DocumentData.DimensionTargetFinancingIncomeIncrease AS DimensionTargetFinancingIncomeIncrease,
	|	DocumentData.DimensionCostIncrease AS DimensionCostIncrease,
	|	DocumentData.DimensionDepreciationDecrease AS DimensionDepreciationDecrease,
	|	DocumentData.DimensionOfRevenueDecreaseInIncomeTF AS DimensionOfRevenueDecreaseInIncomeTF,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpensesDepreciationIncrease,
	|	DocumentData.DimensionThisYearDepreciationDecrease AS DimensionThisYearDepreciationDecrease,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpensesCostReduction,
	|	DocumentData.DimensionOfExpensesDecreaseInIncomeTF AS DimensionOfExpensesDecreaseInIncomeTF,
	|	DocumentData.LineOfBusinessDepreciationIncrease AS LineOfBusinessDepreciationIncrease,
	|	DocumentData.LineOfBusinessCostIncrease AS LineOfBusinessCostIncrease,
	|	DocumentData.LineOfBusinessDepreciationDecrease AS LineOfBusinessDepreciationDecrease,
	|	DocumentData.LineOfBusinessThisYearDepreciationDecrease AS LineOfBusinessThisYearDepreciationDecrease,
	|	DocumentData.LineOfBusinessCostDecrease AS LineOfBusinessCostDecrease,
	|	DocumentData.LineOfBusinessTargetFinancingIncomeIncrease AS LineOfBusinessTargetFinancingIncomeIncrease,
	|	DocumentData.LineOfBusinessTargetFinancingIncomeDecrease AS LineOfBusinessTargetFinancingIncomeDecrease,
	|	DocumentData.BusinessUnitDepreciationIncrease AS BusinessUnitDepreciationIncrease,
	|	DocumentData.BusinessUnitCostIncrease AS BusinessUnitCostIncrease,
	|	DocumentData.BusinessUnitDepreciationDecrease AS BusinessUnitDepreciationDecrease,
	|	DocumentData.BusinessUnitThisYearDepreciationDecrease AS BusinessUnitThisYearDepreciationDecrease,
	|	DocumentData.BusinessUnitCostDecrease AS BusinessUnitCostDecrease,
	|	DocumentData.BusinessUnitTargetFinancingIncomeIncrease AS BusinessUnitTargetFinancingIncomeIncrease,
	|	DocumentData.BusinessUnitTargetFinancingIncomeDecrease AS BusinessUnitTargetFinancingIncomeDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncrease,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease AS BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease,
	|	DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods AS SeparateAdjustmentOfCurrentAndPreviousPeriods,
	|	DocumentData.DepreciationIncreaseRecording AS DepreciationIncreaseRecording,
	|	DocumentData.CostIncreaseRecording AS CostIncreaseRecording,
	|	DocumentData.DepreciationDecreaseRecording AS DepreciationDecreaseRecording,
	|	DocumentData.RecordThisYearDepreciationDecreaseAsStorno AS RecordThisYearDepreciationDecreaseAsStorno,
	|	DocumentData.CostDecreaseRecording AS CostDecreaseRecording,
	|	DocumentData.RecordCostDecreaseByReversal AS RecordCostDecreaseByReversal,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.Department AS Department,
	|	DocumentData.IncomeLiabilityItemCostIncrease AS IncomeLiabilityItemCostIncrease,
	|	DocumentData.IncomeLiabilityItemDepreciationDecrease AS IncomeLiabilityItemDepreciationDecrease,
	|	DocumentData.IncomeLiabilityItemTargetFinancingIncomeDecrease AS IncomeLiabilityItemTargetFinancingIncomeDecrease,
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS AssetExpenseItemDepreciationIncrease,
	|	DocumentData.ExpenseItemThisYearDepreciationDecrease AS ExpenseItemThisYearDepreciationDecrease,
	|	DocumentData.AssetExpenseItemCostReduction AS AssetExpenseItemCostReduction,
	|	DocumentData.AssetExpenseItemTargetFinancingIncomeIncrease AS AssetExpenseItemTargetFinancingIncomeIncrease,
	|	DocumentData.IncomeLedgerAccountsSettingsCostIncrease AS IncomeLedgerAccountsSettingsCostIncrease,
	|	DocumentData.IncomeLedgerAccountsSettingsDepreciationDecrease AS IncomeLedgerAccountsSettingsDepreciationDecrease,
	|	DocumentData.LedgerExpensesAccountSettingsIncreasedDepreciation AS LedgerExpensesAccountSettingsIncreasedDepreciation,
	|	DocumentData.ExpenseLedgerAccountsSettingsIncreaseIncomeTF AS ExpenseLedgerAccountsSettingsIncreaseIncomeTF,
	|	DocumentData.ExpenseLedgerAccountsSettingsCostDecrease AS ExpenseLedgerAccountsSettingsCostDecrease,
	|	DocumentData.CostAdjustment AS CostAdjustment,
	|	DocumentData.AdjustmentOfInitialCost AS AdjustmentOfInitialCost,
	|	DocumentData.DepreciationAdjustment AS DepreciationAdjustment,
	|	DocumentData.IncludesDepreciationOfCurrentMonth AS IncludesDepreciationOfCurrentMonth,
	|	DocumentData.PeriodAdjustment AS PeriodAdjustment,
	|	DocumentData.KindOfAccountingObjects AS KindOfAccountingObjects,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetsCostAndAmortizationAdjustment) AS BusinessOperation
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentData
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
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset,
	|	DocumentTable.IntangibleAsset AS AccountingObject,
	|	UUID(DocumentTable.IntangibleAsset) AS IAID,
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
	|	DocumentTable.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	DocumentTable.InitialCostTA AS InitialCostTA,
	|	DocumentTable.InitialCostMA AS InitialCostMA
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS DocumentTable
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
	|	IntangibleAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IntangibleAssetsCostAndAmortizationAdjustment"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Điều chỉnh giá trị và khấu hao tài sản cố định vô hình';
															|ru = 'Корректировка стоимости и амортизации НМА';
															|en = 'Adjust intangible asset cost and amortization'; fa = 'تعدیل بهای تمام‌شده و استهلاک دارایی نامشهود';
															|it = 'Rettifica del costo e dell''ammortamento di Beni immateriali';
															|pl = 'Korekta wartości i amortyzacji ANM';
															|tr = 'Maddi olmayan varlık maliyet ve amortisman düzeltmesi'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.IntangibleAssetsCostAndAmortizationAdjustment);

	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.IntangibleAssetsCostAndAmortizationAdjustment);
	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	ValuesOfHoldingParameters.Insert("Article6_ProfitLoss_", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	
	ValuesOfHoldingParameters.Insert("BO_CostIncrease", Enums.BusinessTransactions.IntangibleAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("BO_CostReduction", Enums.BusinessTransactions.IntangibleAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("BO_ReducingCostOfCF", Enums.BusinessTransactions.ReduceAccumulatedAmortizationOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("BO_IncreasedDepreciation", Enums.BusinessTransactions.IncreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("BO_IncreaseInDepreciationOfCF", Enums.BusinessTransactions.IncreaseInAmortizationOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciation", Enums.BusinessTransactions.DecreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("BO_ChangeInCFRevenues", Enums.BusinessTransactions.ChangeOfDeferredIncomeFromIntangibleAssetsTargetFinancing);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostIncrease", Catalogs.BusinessTransactionsSettings.IntangibleAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostReduction", Catalogs.BusinessTransactionsSettings.IntangibleAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReducingCostOfCF", Catalogs.BusinessTransactionsSettings.ReduceAccumulatedAmortizationOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("SettingHO_IncreaseDepreciation", Catalogs.BusinessTransactionsSettings.IncreaseInIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("SettingHO_IncreaseDepreciationOfTF", Catalogs.BusinessTransactionsSettings.IncreaseInAmortizationOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("SettingHO_ReductionOfDepreciation", Catalogs.BusinessTransactionsSettings.DecreaseInIntangibleAssetAmortization);
	
	ValuesOfHoldingParameters.Insert("BO_IncreaseInDepreciationAtBeginningOfYear", Enums.BusinessTransactions.IncreaseInIntangibleAssetAmortizationAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("HO_IncreaseInDepreciationOfCentralBankAtBeginningOfYear", Enums.BusinessTransactions.IncreaseInAmortizationOfTargetFinancingOfIntangibleAssetsAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciationAtBeginningOfYear", Enums.BusinessTransactions.DecreaseInIntangibleAssetAmortizationAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreaseInDepreciationAtBeginningOfYear", Catalogs.BusinessTransactionsSettings.IncreaseInIntangibleAssetAmortizationAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("SettingUpHO_IncreaseInCFDepreciationAtBeginningOfYear", Catalogs.BusinessTransactionsSettings.IncreaseInAmortizationOfTargetFinancingOfIntangibleAssetsAsOfTheYearStart);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReductionOfDepreciationAtBeginningOfYear", Catalogs.BusinessTransactionsSettings.DecreaseInIntangibleAssetAmortizationAsOfTheYearStart);
	
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
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
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0)   AS RecNo,
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
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentData
	|
	|		LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIACost(QueryTexts)

	RegisterName = "IACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");

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
	|	TTCostIncrease.IntangibleAsset   AS IntangibleAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
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
	|	DocumentData.Organization                 AS CorCompany,
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
	|	TTCostIncrease.FinRecordID AS FinRecordID,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
	|
	|WHERE
	|	TTCostIncrease.Cost <> 0
	|		OR TTCostIncrease.LocalCost <> 0
	|		OR TTCostIncrease.CostInTaxAccounting <> 0
	|		OR TTCostIncrease.CostPermanentDifference <> 0
	|		OR TTCostIncrease.CostTargetFinancing <> 0
	|		OR TTCostIncrease.CostTargetFinancingPD <> 0
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
	|	TTCostReduction.IntangibleAsset   AS IntangibleAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
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
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.AssetExpenseItemCostReduction AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS CorExpenditureDimension,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|	TTCostReduction.IntangibleAsset   AS IntangibleAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	-TTCostReduction.Cost            AS Cost,
	|	-TTCostReduction.LocalCost        AS LocalCost,
	|	-TTCostReduction.CostInTaxAccounting          AS CostInTaxAccounting,
	|	-TTCostReduction.CostPermanentDifference          AS CostPermanentDifference,
	|
	|	-(TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference)    AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.AssetExpenseItemCostReduction AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS CorExpenditureDimension,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	
	#Region ReducingCostOfCF
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_ReducingCostOfCF                   AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostReduction.IntangibleAsset   AS IntangibleAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|
	|	TTCostReduction.CostTargetFinancing           AS CostTargetFinancing,
	|	TTCostReduction.CostTargetFinancingPD         AS CostTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.AssetExpenseItemCostReduction AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS CorExpenditureDimension,
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
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	&SettingUpHO_ReducingCostOfCF  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region TFCostReductionIsReversed
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_ReducingCostOfCF                   AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	TTCostReduction.IntangibleAsset   AS IntangibleAsset,
	|	DocumentData.Department               AS Department,
	|	InformationAboutAccounting.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	InformationAboutAccounting.LineOfBusiness     AS LineOfBusiness,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|
	|	-TTCostReduction.CostTargetFinancing          AS CostTargetFinancing,
	|	-TTCostReduction.CostTargetFinancingPD        AS CostTargetFinancingPD,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.AssetExpenseItemCostReduction AS CorExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS CorExpenditureDimension,
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
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	&SettingUpHO_ReducingCostOfCF  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordCostDecreaseByReversal
	|	AND (TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
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
	|	TTIncreasedDepreciation.IntangibleAsset AS IntangibleAsset,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|	TTIncreasedDepreciation.IntangibleAsset AS IntangibleAsset,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|	TTDecreaseInDepreciation.IntangibleAsset AS IntangibleAsset,
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
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
	|
	|WHERE
	|	NOT DocumentData.RecordThisYearDepreciationDecreaseAsStorno
	|
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
	|	TTDecreaseInDepreciation.IntangibleAsset AS IntangibleAsset,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
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
	|	TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset AS IntangibleAsset,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset
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
	|	TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset AS IntangibleAsset,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset
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
	|	TTReductionOfDepreciationAtBeginningOfYear.IntangibleAsset AS IntangibleAsset,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTReductionOfDepreciationAtBeginningOfYear.IntangibleAsset
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
	
	Add_Fields = "Recorder";

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
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region CostIncrease
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_CostReduction                   AS BusinessOperation,
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
	|	TTCostReduction.Cost AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostReduction AS TTCostReduction
	|		ON TTCostReduction.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTCostReduction.Ref
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemCostIncrease) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|	AND TTCostReduction.Cost <> 0
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
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
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);
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
	|		+ TTCostIncrease.CostTargetFinancing AS SumCompl,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|		+ TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing   AS SumCompl,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
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
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");

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
	|	TTCostIncrease.IntangibleAsset  AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&Ap_nmaArticle                              AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTCostIncrease.IntangibleAsset  AS CorDimensionOfAssetsLiabilities,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
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
	|	&Ap_nmaArticle                              AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTCostReduction.IntangibleAsset  AS AssetsLiabilitiesDimension,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|	&Ap_nmaArticle                              AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTCostReduction.IntangibleAsset  AS CorDimensionOfAssetsLiabilities,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|	&Ap_nmaArticle                              AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTIncreasedDepreciation.IntangibleAsset AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&Article6_ProfitLoss_                    AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTIncreasedDepreciation.IntangibleAsset AS CorDimensionOfAssetsLiabilities,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|	&Ap_nmaArticle                              AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTDecreaseInDepreciation.IntangibleAsset AS CorDimensionOfAssetsLiabilities,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|
	|	TTDecreaseInDepreciation.Depreciation        AS Sum,
	|	TTDecreaseInDepreciation.Depreciation        AS SumMan,
	|
	|	TTDecreaseInDepreciation.DepreciationLocal
	|		+ TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
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
	|	&Ap_nmaArticle                              AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	TTCostIncrease.IntangibleAsset  AS AssetsLiabilitiesDimension,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
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
	|	TTCostReduction.IntangibleAsset  AS AssetsLiabilitiesDimension,
	|	InformationAboutAccounting.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	InformationAboutAccounting.LineOfBusiness    AS CorLineOfBusiness,
	|	&Ap_nmaArticle                              AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTCostReduction.IntangibleAsset  AS CorDimensionOfAssetsLiabilities,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");
	
	QueryTextTTCostIncrease(QueryTexts);
	QueryTextTTCostReduction(QueryTexts);
	QueryTextTTIncreasedDepreciation(QueryTexts);
	QueryTextTTDecreaseInDepreciation(QueryTexts);
	
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
	|
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
	|
	|		LEFT JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	NOT DocumentData.RecordThisYearDepreciationDecreaseAsStorno
	|	AND VALUETYPE(DocumentData.IncomeLiabilityItemDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND (TTDecreaseInDepreciation.Depreciation <> 0
	|		OR TTDecreaseInDepreciation.DepreciationLocal <> 0 
	|		OR TTDecreaseInDepreciation.FixedAssetDepreciationTargetFinancing <> 0)
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
	|	TTReductionOfDepreciationAtBeginningOfYear.Depreciation AS Sum,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTReductionOfDepreciationAtBeginningOfYear.IntangibleAsset
	|
	|		LEFT JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	VALUETYPE(DocumentData.IncomeLiabilityItemDepreciationDecrease) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	AND (TTReductionOfDepreciationAtBeginningOfYear.Depreciation <> 0
	|		OR TTReductionOfDepreciationAtBeginningOfYear.DepreciationLocal <> 0 
	|		OR TTReductionOfDepreciationAtBeginningOfYear.FixedAssetDepreciationTargetFinancing <> 0)
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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

Procedure QueryTextTableInitialIntangibleAssetsInformation(Query, QueryTexts, Registers)

	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = IntangibleAssetsCostAndAmortizationAdjustmentLocalization.QueryTextTableInitialIntangibleAssetsInformation(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|
		|	TTInitialInformationOfIA.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	TTInitialInformationOfIA.PurchaseDate AS PurchaseDate,
		|	TTInitialInformationOfIA.DateOfRecognitionAccounting AS DateOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionAccounting AS DocumentOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionManagementAccounting AS DocumentOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DocumentWriteOffs AS DocumentWriteOffs,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN TableOfIA.InitialCostLocalAccounting
		|		ELSE TTInitialInformationOfIA.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN TableOfIA.InitialCostMA
		|		ELSE TTInitialInformationOfIA.InitialCostMA
		|	END AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		INNER JOIN TTInitialInformationOfIA AS TTInitialInformationOfIA
		|		ON TTInitialInformationOfIA.Ref = TableOfIA.Ref
		|			AND TTInitialInformationOfIA.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.AdjustmentOfInitialCost
		|	AND (DocumentData.PostInAccounting
		|				AND TTInitialInformationOfIA.InitialCostLocalAccounting <> TableOfIA.InitialCostLocalAccounting
		|			OR DocumentData.RecordInManAccounting
		|				AND TTInitialInformationOfIA.InitialCostMA <> TableOfIA.InitialCostMA)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|
		|	TTInitialInformationOfIA.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	TTInitialInformationOfIA.PurchaseDate AS PurchaseDate,
		|	TTInitialInformationOfIA.DateOfRecognitionAccounting AS DateOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionAccounting AS DocumentOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionManagementAccounting AS DocumentOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DocumentWriteOffs AS DocumentWriteOffs,
		|
		|	TableOfIA.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	TableOfIA.InitialCostMA AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		INNER JOIN TTInitialInformationOfIA AS TTInitialInformationOfIA
		|		ON TTInitialInformationOfIA.Ref = TableOfIA.Ref
		|			AND TTInitialInformationOfIA.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.AdjustmentOfInitialCost
		|	AND (TTInitialInformationOfIA.InitialCostLocalAccounting <> TableOfIA.InitialCostLocalAccounting
		|			OR TTInitialInformationOfIA.InitialCostMA <> TableOfIA.InitialCostMA)
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure
 
Procedure QueryTextTTCostIncrease(QueryTexts)

	TableName = "TTCostIncrease";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTCostAdjustment(QueryTexts);
	
	QueryText =
	"SELECT
	|	TTCostAdjustment.Ref AS Ref,
	|	TTCostAdjustment.IntangibleAsset AS IntangibleAsset,
	|
	// Cost
	|	CASE 
	|		WHEN TTCostAdjustment.Cost > 0
	|			THEN TTCostAdjustment.Cost
	|		ELSE 0
	|	END                                       AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN TTCostAdjustment.LocalCost > 0
	|			THEN TTCostAdjustment.LocalCost
	|		ELSE 0
	|	END                                       AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN TTCostAdjustment.CostInTaxAccounting > 0
	|			THEN TTCostAdjustment.CostInTaxAccounting
	|		ELSE 0
	|	END                                       AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
	|		WHEN TTCostAdjustment.LocalCost = 0
	|				AND TTCostAdjustment.CostInTaxAccounting = 0
	|			THEN 0
	|		WHEN TTCostAdjustment.LocalCost > 0
	|			THEN TTCostAdjustment.CostPermanentDifference
	|		WHEN TTCostAdjustment.LocalCost = 0
	|				AND TTCostAdjustment.CostInTaxAccounting > 0
	|			THEN TTCostAdjustment.CostPermanentDifference
	|		ELSE 0
	|	END                                       AS CostPermanentDifference,
	|
	// CostTargetFinancing
	|	CASE 
	|		WHEN TTCostAdjustment.CostTargetFinancing > 0
	|			THEN TTCostAdjustment.CostTargetFinancing
	|		ELSE 0
	|	END                                       AS CostTargetFinancing,
	|
	// CostTargetFinancingPD
	|	CASE 
	|		WHEN TTCostAdjustment.CostTargetFinancingPD > 0
	|			THEN TTCostAdjustment.CostTargetFinancingPD
	|		ELSE 0
	|	END                                       AS CostTargetFinancingPD,
	|
	|	TTCostAdjustment.RowID  AS FinRecordID,
	|	&SettingUpHO_CostIncrease             AS BusinessTransactionSetting
	|
	|INTO TTCostIncrease
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostAdjustment AS TTCostAdjustment
	|		ON TTCostAdjustment.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.CostIncreaseRecording
	|
	|	AND (TTCostAdjustment.Cost > 0
	|		OR TTCostAdjustment.LocalCost > 0
	|		OR TTCostAdjustment.CostInTaxAccounting > 0
	|		OR TTCostAdjustment.CostTargetFinancing > 0
	|		OR TTCostAdjustment.CostTargetFinancingPD > 0
	|		OR CASE 
	|				WHEN TTCostAdjustment.LocalCost = 0
	|						AND TTCostAdjustment.CostInTaxAccounting = 0
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
	|	IntangibleAsset
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
	|	TTCostAdjustment.Ref AS Ref,
	|	TTCostAdjustment.IntangibleAsset AS IntangibleAsset,
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
	|		WHEN TTCostAdjustment.CostInTaxAccounting < 0
	|			THEN -TTCostAdjustment.CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
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
	|	TTCostAdjustment.RowID AS FinRecordID,
	|	&SettingUpHO_CostReduction AS BusinessTransactionSetting
	|
	|INTO TTCostReduction
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostAdjustment AS TTCostAdjustment
	|		ON TTCostAdjustment.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.CostDecreaseRecording
	|
	|	AND (TTCostAdjustment.Cost < 0
	|		OR TTCostAdjustment.LocalCost < 0
	|		OR TTCostAdjustment.CostInTaxAccounting < 0
	|		OR TTCostAdjustment.CostTargetFinancing < 0
	|		OR TTCostAdjustment.CostTargetFinancingPD < 0
	|		OR CASE 
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
	|	IntangibleAsset
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
	|	TTDepreciationAdjustment.Ref AS Ref,
	|	TTDepreciationAdjustment.IntangibleAsset AS IntangibleAsset,
	|
	// Depreciation
	|	CASE 
	|		WHEN TTDepreciationAdjustment.Depreciation > 0
	|			THEN TTDepreciationAdjustment.Depreciation
	|		ELSE 0
	|	END                                       AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationLocal > 0
	|			THEN TTDepreciationAdjustment.DepreciationLocal
	|		ELSE 0
	|	END                                       AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationInTaxAccounting > 0
	|			THEN TTDepreciationAdjustment.DepreciationInTaxAccounting
	|		ELSE 0
	|	END                                       AS DepreciationInTaxAccounting,
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
	|	END                                       AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing > 0
	|			THEN TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END                                       AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN TTDepreciationAdjustment.DepreciationTargetFinancingPD > 0
	|			THEN TTDepreciationAdjustment.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END                                       AS DepreciationTargetFinancingPD,
	|
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
	|	IntangibleAsset
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
	|	TTDepreciationAdjustment.Ref AS Ref,
	|	TTDepreciationAdjustment.IntangibleAsset AS IntangibleAsset,
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
	|	TTDepreciationAdjustment.RowID AS FinRecordID,
	|	&SettingHO_ReductionOfDepreciation AS BusinessTransactionSetting
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
	|	IntangibleAsset
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
	|	TTDepreciationAdjustmentAtBeginningOfYear.Ref AS Ref,
	|	TTDepreciationAdjustmentAtBeginningOfYear.IntangibleAsset AS IntangibleAsset,
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
	|	IntangibleAsset
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
	|	TTDepreciationAdjustmentAtBeginningOfYear.Ref AS Ref,
	|	TTDepreciationAdjustmentAtBeginningOfYear.IntangibleAsset AS IntangibleAsset,
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
	|	IntangibleAsset
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
	|	TableOfIA.Ref               AS Ref,
	|	TableOfIA.IntangibleAsset  AS IntangibleAsset,
	|
	// Cost
	|	CASE 
	|		WHEN ISNULL(IACost.Cost, 0) <> TableOfIA.CostInManagementAccounting 
	|				AND DocumentData.RecordInManAccounting 
	|			THEN TableOfIA.CostInManagementAccounting - ISNULL(IACost.Cost, 0)
	|		ELSE 0
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN ISNULL(IACost.LocalCost, 0) <> TableOfIA.CostInAccounting 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.CostInAccounting - ISNULL(IACost.LocalCost, 0)
	|		ELSE 0
	|	END AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN ISNULL(IACost.CostInTaxAccounting, 0) <> TableOfIA.CostInTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|			THEN TableOfIA.CostInTaxAccounting - ISNULL(IACost.CostInTaxAccounting, 0)
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
	|		WHEN ISNULL(IACost.CostPermanentDifference, 0) <> TableOfIA.CostPermanentDifference 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.CostPermanentDifference - ISNULL(IACost.CostPermanentDifference, 0)
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	// CostTargetFinancing
	|	CASE 
	|		WHEN ISNULL(IACost.CostTargetFinancing, 0) <> TableOfIA.CostTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.CostTargetFinancing - ISNULL(IACost.CostTargetFinancing, 0)
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	// CostTargetFinancingPD
	|	CASE 
	|		WHEN ISNULL(IACost.CostTargetFinancing, 0) <> TableOfIA.CostTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.CostTargetFinancing - ISNULL(IACost.CostTargetFinancing, 0)
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	|	TableOfIA.RowID              AS RowID
	|
	|INTO TTCostAdjustment
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.CostAdjustment
	|	AND (ISNULL(IACost.Cost, 0) <> TableOfIA.CostInManagementAccounting 
	|				AND DocumentData.RecordInManAccounting
	|
	|		OR ISNULL(IACost.LocalCost, 0) <> TableOfIA.CostInAccounting 
	|				AND DocumentData.PostInAccounting
	|
	|		OR ISNULL(IACost.CostInTaxAccounting, 0) <> TableOfIA.CostInTaxAccounting 
	|				AND DocumentData.RecordInTA
	|
	|		OR ISNULL(IACost.CostPermanentDifference, 0) <> TableOfIA.CostPermanentDifference 
	|				AND DocumentData.PostInAccounting
	|
	|		OR ISNULL(IACost.CostTargetFinancing, 0) <> TableOfIA.CostTargetFinancing 
	|				AND DocumentData.PostInAccounting)
	|
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTDepreciationAdjustment(QueryTexts)

	TableName = "TTDepreciationAdjustment";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTTDepreciationAdjustmentAtBeginningOfYear(QueryTexts); 
	
	QueryText =
	"SELECT
	|	TableOfIA.Ref               AS Ref,
	|	TableOfIA.IntangibleAsset  AS IntangibleAsset,
	|
	// Depreciation
	|	CASE 
	|		WHEN ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0) - ISNULL(AdjustmentAtBeginningOfYear.Depreciation, 0) <> TableOfIA.DepreciationManagementAccounting 
	|				AND DocumentData.RecordInManAccounting 
	|			THEN TableOfIA.DepreciationManagementAccounting 
	|					- ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.Depreciation, 0)
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationLocal, 0) <> TableOfIA.DepreciationInAccounting 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.DepreciationInAccounting 
	|					- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationInTaxAccounting, 0) <> TableOfIA.DepreciationInTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|			THEN TableOfIA.DepreciationInTaxAccounting 
	|					- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.DepreciationInTaxAccounting, 0)
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationPermanentDifferences, 0) <> TableOfIA.DepreciationPermanentDifferences 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.DepreciationPermanentDifferences 
	|					- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0) - ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) <> TableOfIA.FixedAssetDepreciationTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.FixedAssetDepreciationTargetFinancing 
	|					- ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0) - ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) <> TableOfIA.FixedAssetDepreciationTargetFinancing 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.FixedAssetDepreciationTargetFinancing 
	|					- ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|					- ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	TableOfIA.RowID AS RowID
	|
	|INTO TTDepreciationAdjustment
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTDepreciationAdjustmentAtBeginningOfYear AS AdjustmentAtBeginningOfYear
	|		ON AdjustmentAtBeginningOfYear.Ref = TableOfIA.Ref
	|			AND AdjustmentAtBeginningOfYear.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.DepreciationAdjustment
	|	AND (NOT DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods 
	|		OR BEGINOFPERIOD(DocumentData.Period, DAY) <> BEGINOFPERIOD(DocumentData.Period, YEAR))
	|
	|	AND (ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0) - ISNULL(AdjustmentAtBeginningOfYear.Depreciation, 0) <> TableOfIA.DepreciationManagementAccounting 
	|				AND DocumentData.RecordInManAccounting
	|
	|		OR ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationLocal, 0) <> TableOfIA.DepreciationInAccounting 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationInTaxAccounting, 0) <> TableOfIA.DepreciationInTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|
	|		OR ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) - ISNULL(AdjustmentAtBeginningOfYear.DepreciationPermanentDifferences, 0) <> TableOfIA.DepreciationPermanentDifferences 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0) - ISNULL(AdjustmentAtBeginningOfYear.FixedAssetDepreciationTargetFinancing, 0) <> TableOfIA.FixedAssetDepreciationTargetFinancing 
	|				AND DocumentData.PostInAccounting)
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTDepreciationAdjustmentAtBeginningOfYear(QueryTexts)

	TableName = "TTDepreciationAdjustmentAtBeginningOfYear";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTDepreciationAtBeginningOfYear(QueryTexts); 
	
	QueryText =
	"SELECT
	|	TableOfIA.Ref                 AS Ref,
	|	TableOfIA.IntangibleAsset    AS IntangibleAsset,
	|
	// Depreciation
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.Depreciation, 0) <> TableOfIA.DepreciationAtBeginningOfYearMa 
	|				AND DocumentData.RecordInManAccounting 
	|			THEN TableOfIA.DepreciationAtBeginningOfYearMa - ISNULL(DepreciationAsOfTheYearStart.Depreciation, 0)
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationLocal, 0) <> TableOfIA.DepreciationAsOfTheYearStartBookkeeping 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.DepreciationAsOfTheYearStartBookkeeping - ISNULL(DepreciationAsOfTheYearStart.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationInTaxAccounting, 0) <> TableOfIA.DepreciationAsOfTheYearStartTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|			THEN TableOfIA.DepreciationAsOfTheYearStartTaxAccounting - ISNULL(DepreciationAsOfTheYearStart.DepreciationInTaxAccounting, 0)
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationPermanentDifferences, 0) <> TableOfIA.PermanentDifferencesInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.PermanentDifferencesInDepreciationAsOfTheYearStart - ISNULL(DepreciationAsOfTheYearStart.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing, 0) <> TableOfIA.TargetFundsInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.TargetFundsInDepreciationAsOfTheYearStart - ISNULL(DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE 
	|		WHEN ISNULL(DepreciationAsOfTheYearStart.DepreciationTargetFinancingPD, 0) <> TableOfIA.TargetFundsInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|			THEN TableOfIA.TargetFundsInDepreciationAsOfTheYearStart - ISNULL(DepreciationAsOfTheYearStart.DepreciationTargetFinancingPD, 0)
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	TableOfIA.IAID AS RowID
	|
	|INTO TTDepreciationAdjustmentAtBeginningOfYear
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTDepreciationAtBeginningOfYear AS DepreciationAsOfTheYearStart
	|		ON DepreciationAsOfTheYearStart.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.KindOfAccountingObjects = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|	AND DocumentData.DepreciationAdjustment
	|	AND DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods
	|
	|	AND (ISNULL(DepreciationAsOfTheYearStart.Depreciation, 0) <> TableOfIA.DepreciationAtBeginningOfYearMa 
	|				AND DocumentData.RecordInManAccounting 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.DepreciationLocal, 0) <> TableOfIA.DepreciationAsOfTheYearStartBookkeeping 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.DepreciationInTaxAccounting, 0) <> TableOfIA.DepreciationAsOfTheYearStartTaxAccounting 
	|				AND DocumentData.RecordInTA 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.DepreciationPermanentDifferences, 0) <> TableOfIA.PermanentDifferencesInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting 
	|
	|		OR ISNULL(DepreciationAsOfTheYearStart.FixedAssetDepreciationTargetFinancing, 0) <> TableOfIA.TargetFundsInDepreciationAsOfTheYearStart 
	|				AND DocumentData.PostInAccounting)
	|
	|INDEX BY 
	|	Ref
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
	|	TableOfIA.IntangibleAsset AS IntangibleAsset
	|
	|INTO TTListOfIADepreciationAtBeginningOfYear
	|
	|FROM 
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.DepreciationAdjustment
	|	AND DocumentData.SeparateAdjustmentOfCurrentAndPreviousPeriods
	|
	|INDEX BY
	|	IntangibleAsset
	|";
	QueryTexts.Add(QueryText, "TTListOfIADepreciationAtBeginningOfYear", False);
	
	QueryText = 
	"SELECT
	|	IntangibleAssetsAmortizationCharge.IntangibleAsset AS IntangibleAsset,
	|
	|	-IntangibleAssetsAmortizationCharge.DepreciationBalance AS Depreciation,
	|	-IntangibleAssetsAmortizationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|	-IntangibleAssetsAmortizationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|	-IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|	-IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD
	|
	|INTO TTDepreciationAtBeginningOfYear
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|			&BegOfYear,
	|			IntangibleAsset IN (
	|				SELECT 
	|					Table.IntangibleAsset
	|				FROM 
	|					TTListOfIADepreciationAtBeginningOfYear AS Table)) AS IntangibleAssetsAmortizationCharge
	|
	|INDEX BY
	|	IntangibleAsset
	|";

	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");
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
	|
	|	TTCostReduction.LocalCost AS AmountExcludingVATCompl,
	|
	|	TTCostReduction.CostPermanentDifference AS PermanentDifference,
	|
	|	TTCostReduction.LocalCost
	|		- TTCostReduction.CostInTaxAccounting
	|		- TTCostReduction.CostPermanentDifference AS CostTD,
	|
	|	&BO_CostReduction AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTCostReduction.FinRecordID          AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting  AS BusinessTransactionSetting,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|	TTCostReduction.CostTargetFinancing AS AmountExcludingVATCompl,
	|
	|	TTCostReduction.CostTargetFinancingPD AS PermanentDifference,
	|
	|	TTCostReduction.CostTargetFinancing
	|		- TTCostReduction.CostTargetFinancingPD AS CostTD,
	|
	|	&BO_ReducingCostOfCF AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTCostReduction.FinRecordID AS FinRecordID,
	|	&SettingUpHO_ReducingCostOfCF AS BusinessTransactionSetting,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
	|
	|WHERE
	|	NOT DocumentData.RecordCostDecreaseByReversal
	|	AND VALUETYPE(DocumentData.AssetExpenseItemCostReduction) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTCostReduction.CostTargetFinancing <> 0
	|		OR TTCostReduction.CostTargetFinancingPD <> 0)
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|	&BO_IncreasedDepreciation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTIncreasedDepreciation.FinRecordID AS FinRecordID,
	|	&SettingHO_IncreaseDepreciation AS BusinessTransactionSetting,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
	|
	|WHERE
	|	VALUETYPE(DocumentData.AssetExpenseItemDepreciationIncrease) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND (TTIncreasedDepreciation.Depreciation <> 0
	|		OR TTIncreasedDepreciation.DepreciationLocal <> 0
	|		OR TTIncreasedDepreciation.DepreciationInTaxAccounting <> 0
	|		OR TTIncreasedDepreciation.DepreciationPermanentDifferences <> 0)
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
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing     AS AmountExcludingVATCompl,
	|
	|	TTIncreasedDepreciation.DepreciationTargetFinancingPD   AS PermanentDifference,
	|
	|	TTIncreasedDepreciation.FixedAssetDepreciationTargetFinancing
	|		- TTIncreasedDepreciation.DepreciationTargetFinancingPD   AS CostTD,
	|
	|	&BO_IncreaseInDepreciationOfCF AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTIncreasedDepreciation.FinRecordID AS FinRecordID,
	|	&SettingHO_IncreaseDepreciationOfTF AS BusinessTransactionSetting,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset
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
	|	DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDecreaseInDepreciation AS TTDecreaseInDepreciation
	|		ON TTDecreaseInDepreciation.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingInformation AS InformationAboutAccounting
	|		ON InformationAboutAccounting.Ref = TTDecreaseInDepreciation.Ref
	|			AND InformationAboutAccounting.IntangibleAsset = TTDecreaseInDepreciation.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
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
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts,, "TTAccountingInformation");
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
	|	DocumentData.AssetExpenseItemCostReduction AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesCostReduction AS DimensionOfExpenses,
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
	|	TTCostReduction.FinRecordID          AS FinRecordID,
	|	TTCostReduction.BusinessTransactionSetting  AS BusinessTransactionSetting,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
	|
	|WHERE
	|	(TTCostReduction.Cost <> 0
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostReduction.IntangibleAsset
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
	|	DocumentData.AssetExpenseItemDepreciationIncrease AS ExpenseItem,
	|	DocumentData.DimensionOfExpensesDepreciationIncrease AS DimensionOfExpenses,
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
	|	TTIncreasedDepreciation.FinRecordID          AS FinRecordID,
	|	TTIncreasedDepreciation.BusinessTransactionSetting  AS BusinessTransactionSetting,
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreasedDepreciation.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTIncreaseInDepreciationAtBeginningOfYear.IntangibleAsset
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
	|			AND InformationAboutAccounting.IntangibleAsset = TTCostIncrease.IntangibleAsset
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

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return "";

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return IntangibleAssetsCostAndAmortizationAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

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
		Object.CostAdjustment
		And Object.CostIncreaseRecording;
	
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
		Object.CostAdjustment
		And Object.CostDecreaseRecording;
	
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
		Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset")
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
		Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset")
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
		Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset")
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
	
	#Region IncreaseInCFRevenues
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "AssetExpenseItemTargetFinancingIncomeIncrease";
	ChoiceParameters.ArticleType = "TypeOfExpenditureItemIncreaseInCFRevenues";
	
	ChoiceParameters.AvailabilityByOperation = 
		Object.CostAdjustment
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
		Object.CostAdjustment
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

Procedure FillInByAccountingData(Object, RowsSelected = Undefined) Export

	If RowsSelected <> Undefined
		And RowsSelected.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CostAndDepreciation.IntangibleAsset AS IntangibleAsset,
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
	|	SUM(CostAndDepreciation.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing
	|
	|INTO CostAndDepreciation
	|
	|FROM
	|	(SELECT
	|		IACostBalance.IntangibleAsset AS IntangibleAsset,
	|		IACostBalance.CostBalance AS CostInManagementAccounting,
	|		IACostBalance.LocalCostBalance AS CostInAccounting,
	|		IACostBalance.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|		IACostBalance.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|		IACostBalance.CostTargetFinancingBalance AS CostTargetFinancing,
	|		0 AS DepreciationInAccounting,
	|		0 AS DepreciationInTaxAccounting,
	|		0 AS DepreciationPermanentDifferences,
	|		0 AS DepreciationManagementAccounting,
	|		0 AS FixedAssetDepreciationTargetFinancing
	|	FROM
	|		AccumulationRegister.IACost.Balance(
	|				&PeriodLimit,
	|				Organization = &Organization
	|					AND IntangibleAsset IN (&ListOfIA)) AS IACostBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IACost.IntangibleAsset,
	|		IACost.Cost,
	|		CASE
	|			WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -IACost.LocalCost
	|			ELSE IACost.LocalCost
	|		END,
	|		CASE
	|			WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -IACost.CostInTaxAccounting
	|			ELSE IACost.CostInTaxAccounting
	|		END,
	|		CASE
	|			WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -IACost.CostPermanentDifference
	|			ELSE IACost.CostPermanentDifference
	|		END,
	|		CASE
	|			WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -IACost.CostTargetFinancing
	|			ELSE IACost.CostTargetFinancing
	|		END,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.IACost AS IACost
	|	WHERE
	|		IACost.Recorder = &Ref
	|		AND IACost.Organization = &Organization
	|		AND IACost.Period < &Period
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IntangibleAssetsAmortizationChargeBalance.IntangibleAsset,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		-IntangibleAssetsAmortizationChargeBalance.DepreciationLocalBalance,
	|		-IntangibleAssetsAmortizationChargeBalance.DepreciationInTaxAccountingBalance,
	|		-IntangibleAssetsAmortizationChargeBalance.DepreciationPermanentDifferencesBalance,
	|		-IntangibleAssetsAmortizationChargeBalance.DepreciationBalance,
	|		-IntangibleAssetsAmortizationChargeBalance.FixedAssetDepreciationTargetFinancingBalance
	|	FROM
	|		AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|				&PeriodLimit,
	|				Organization = &Organization
	|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAmortizationChargeBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IntangibleAssetsAmortizationCharge.IntangibleAsset,
	|		IntangibleAssetsAmortizationCharge.Depreciation,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.DepreciationLocal
	|			ELSE IntangibleAssetsAmortizationCharge.DepreciationLocal
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting
	|			ELSE IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|			ELSE IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.Depreciation
	|			ELSE IntangibleAssetsAmortizationCharge.Depreciation
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing
	|			ELSE IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing
	|		END
	|	FROM
	|		AccumulationRegister.IntangibleAssetsAmortizationCharge AS IntangibleAssetsAmortizationCharge
	|	WHERE
	|		IntangibleAssetsAmortizationCharge.Recorder = &Ref
	|		AND IntangibleAssetsAmortizationCharge.Organization = &Organization
	|		AND IntangibleAssetsAmortizationCharge.Period < &Period
	|
	|	UNION ALL
	|	
	|	SELECT
	|		IntangibleAssetsAmortizationCharge.IntangibleAsset,
	|		IntangibleAssetsAmortizationCharge.Depreciation,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.DepreciationLocal
	|			ELSE IntangibleAssetsAmortizationCharge.DepreciationLocal
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting
	|			ELSE IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|			ELSE IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.Depreciation
	|			ELSE IntangibleAssetsAmortizationCharge.Depreciation
	|		END,
	|		CASE
	|			WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing
	|			ELSE IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing
	|		END
	|	FROM
	|		AccumulationRegister.IntangibleAssetsAmortizationCharge AS IntangibleAssetsAmortizationCharge
	|	WHERE
	|		IntangibleAssetsAmortizationCharge.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4
	|		AND IntangibleAssetsAmortizationCharge.Organization = &Organization
	|		AND IntangibleAssetsAmortizationCharge.Period < &Period
	|		AND IntangibleAssetsAmortizationCharge.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
	|
	|	) AS CostAndDepreciation
	|
	|GROUP BY
	|	CostAndDepreciation.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsAmortizationCharge.IntangibleAsset AS IntangibleAsset,
	|	-IntangibleAssetsAmortizationCharge.DepreciationLocalBalance AS DepreciationInAccounting,
	|	-IntangibleAssetsAmortizationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|	-IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|	-IntangibleAssetsAmortizationCharge.DepreciationBalance AS DepreciationManagementAccounting,
	|	-IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing
	|
	|INTO DepreciationAsOfTheYearStart
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|			&BegOfYear,
	|			&SeparateAdjustmentOfCurrentAndPreviousPeriods
	|				AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAmortizationCharge
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CostAndDepreciation.IntangibleAsset AS IntangibleAsset,
	|
	|	CostAndDepreciation.CostInManagementAccounting AS CostInManagementAccounting,
	|	CostAndDepreciation.CostInAccounting AS CostInAccounting,
	|	CostAndDepreciation.CostInTaxAccounting AS CostInTaxAccounting,
	|	CostAndDepreciation.CostPermanentDifference AS CostPermanentDifference,
	|	CostAndDepreciation.CostTargetFinancing AS CostTargetFinancing,
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
	|	InitialIntangibleAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	InitialIntangibleAssetsInformation.InitialCostTA AS InitialCostTA,
	|	InitialIntangibleAssetsInformation.InitialCostMA AS InitialCostMA
	|
	|FROM
	|	CostAndDepreciation AS CostAndDepreciation
	|
	|		LEFT JOIN DepreciationAsOfTheYearStart AS DepreciationAsOfTheYearStart
	|		ON DepreciationAsOfTheYearStart.IntangibleAsset = CostAndDepreciation.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|			&Period,
	|			Recorder <> &Ref
	|				AND Organization = &Organization
	|				AND IntangibleAsset IN (&ListOfIA)) AS InitialIntangibleAssetsInformation
	|		ON (InitialIntangibleAssetsInformation.IntangibleAsset = CostAndDepreciation.IntangibleAsset)
	|			AND (InitialIntangibleAssetsInformation.Organization = &Organization)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("SeparateAdjustmentOfCurrentAndPreviousPeriods", Object.SeparateAdjustmentOfCurrentAndPreviousPeriods);
	
	Period = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	Query.SetParameter("PeriodLimit", New Boundary(Period, BoundaryType.Excluding));
	Query.SetParameter("Period", Period);
	Query.SetParameter("BegOfYear", BegOfYear(Period));
	
	ListOfIA = Object.IA.Unload(RowsSelected).UnloadColumn("IntangibleAsset");
	Query.SetParameter("ListOfIA", ListOfIA);
	
	CostAndDepreciation = Query.Execute().Unload();
	CostAndDepreciation.Indexes.Add("IntangibleAsset");
	
	If RowsSelected <> Undefined Then
		StringsList = RowsSelected;
	Else
		StringsList = Object.IA;
	EndIf; 
	
	For Each RowData In StringsList Do
		
		DataOfAccounting = CostAndDepreciation.Find(RowData.IntangibleAsset, "IntangibleAsset");
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
			RowData.InitialCostLocalAccounting = 0;
			RowData.InitialCostTA = 0;
			RowData.InitialCostMA = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

// calculates depreciation when switching to fsb 14 using the formula:
// Akorr = (PS - LS) / SPIist * SPIist - An
//	where
//		acorr - the amount of adjustment of the accumulated depreciation of the IA object;
//		ps - the initial cost of the IA facility;
//		ls - liquidation value of the IA facility;
//		spi total - the total useful life of the IA facility in months;
//		spiist - the expired useful life of the IA facility as of the date of transition to fsb 14;
//		an is the amount of depreciation accumulated on the IA object before the date of transition to fsb 14.
//		
// Parameters:
//  Object - DocumentObject.IntangibleAssetsCostAndAmortizationAdjustment - Object
//  RowsSelected - Array - Selected lines
Procedure CalculateDepreciationWhenSwitchingToFSB14(Object, RowsSelected = Undefined) Export

	If RowsSelected <> Undefined
		And RowsSelected.Count() = 0 Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	InitialIntangibleAssetsInformation.IntangibleAsset AS IntangibleAsset,
	|	DATEDIFF(BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, MONTH), &BegOfMonth, MONTH) AS ExpiredPeriodAC,
	|	DATEDIFF(BEGINOFPERIOD(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, MONTH), &BegOfMonth, MONTH) AS ExpiredPeriodMA,
	|	InitialIntangibleAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	InitialIntangibleAssetsInformation.InitialCostMA AS InitialCostMA
	|
	|INTO InitialIntangibleAssetsInformation
	|
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|		&EndOfMonth, 
	|		Organization = &Organization
	|			AND IntangibleAsset IN (&ListOfIA)) AS InitialIntangibleAssetsInformation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset AS IntangibleAsset,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan AS ResidualValueMan
	|
	|INTO IADepreciationParametersBookkeepingAndTaxAccounting
	|
	|FROM
	|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
	|		&EndOfMonth, 
	|		Organization = &Organization
	|			AND IntangibleAsset IN (&ListOfIA)) AS IADepreciationParametersBookkeepingAndTaxAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeMonths,
	|	IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan AS ResidualValueMan
	|
	|INTO IntangibleAssetAmortizationParametersManagementAccounting
	|
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|		&EndOfMonth, 
	|		Organization = &Organization
	|			AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetAmortizationParametersManagementAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset AS IntangibleAsset,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC AS UsefulLifeMonthsAC
	|
	|INTO ParametersOfDepreciationNmabu_BeginningOfMonth
	|
	|FROM
	|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
	|		&BegOfMonth, 
	|		Organization = &Organization
	|			AND IntangibleAsset IN (&ListOfIA)) AS IADepreciationParametersBookkeepingAndTaxAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeMonths
	|
	|INTO ParametersOfDepreciationNmauu_BeginningOfMonth
	|
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|		&BegOfMonth, 
	|		Organization = &Organization
	|			AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetAmortizationParametersManagementAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfIA.Ref AS IntangibleAsset,
	|
	|	CASE
	|		WHEN ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0) = 0
	|				OR ISNULL(ParametersOfDepreciationNmauu_BeginningOfMonth.UsefulLifeMonths, 0) = 0
	|
	|			THEN 0
	|
	|		ELSE (ISNULL(InitialIntangibleAssetsInformation.InitialCostMA, 0) 
	|					- ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan, 0))
	|	 			/ ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0)
	|				* ISNULL(InitialIntangibleAssetsInformation.ExpiredPeriodMA, 0)
	|
	|			- CASE
	|				WHEN ISNULL(InitialIntangibleAssetsInformation.ExpiredPeriodMA, 0) <= ISNULL(ParametersOfDepreciationNmauu_BeginningOfMonth.UsefulLifeMonths, 0)
	|					THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostMA, 0)
	|							/ ISNULL(ParametersOfDepreciationNmauu_BeginningOfMonth.UsefulLifeMonths, 0) 
	|					ELSE 0 
	|			 END
	|
	|	END AS DepreciationManagementAccounting,
	|
	|	CASE
	|		WHEN ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC, 0) = 0
	|				OR ISNULL(ParametersOfDepreciationNmabu_BeginningOfMonth.UsefulLifeMonthsAC, 0) = 0
	|
	|			THEN 0
	|
	|		ELSE (ISNULL(InitialIntangibleAssetsInformation.InitialCostLocalAccounting, 0) 
	|					- ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan, 0))
	|	 			/ ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC, 0)
	|				* ISNULL(InitialIntangibleAssetsInformation.ExpiredPeriodAC, 0)
	|
	|			- CASE
	|				WHEN ISNULL(InitialIntangibleAssetsInformation.ExpiredPeriodAC, 0) <= ISNULL(ParametersOfDepreciationNmabu_BeginningOfMonth.UsefulLifeMonthsAC, 0)
	|					THEN ISNULL(InitialIntangibleAssetsInformation.InitialCostLocalAccounting, 0)
	|							/ ISNULL(ParametersOfDepreciationNmabu_BeginningOfMonth.UsefulLifeMonthsAC, 0) 
	|					ELSE 0 
	|			 END
	|
	|	END AS DepreciationInAccounting
	|
	|FROM
	|	Catalog.IntangibleAssets AS ListOfIA
	|
	|		LEFT JOIN InitialIntangibleAssetsInformation AS InitialIntangibleAssetsInformation
	|		ON InitialIntangibleAssetsInformation.IntangibleAsset = ListOfIA.Ref
	|
	|		LEFT JOIN IADepreciationParametersBookkeepingAndTaxAccounting AS IADepreciationParametersBookkeepingAndTaxAccounting
	|		ON IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = ListOfIA.Ref
	|
	|		LEFT JOIN ParametersOfDepreciationNmabu_BeginningOfMonth AS ParametersOfDepreciationNmabu_BeginningOfMonth
	|		ON ParametersOfDepreciationNmabu_BeginningOfMonth.IntangibleAsset = ListOfIA.Ref
	|
	|		LEFT JOIN IntangibleAssetAmortizationParametersManagementAccounting AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = ListOfIA.Ref
	|
	|		LEFT JOIN ParametersOfDepreciationNmauu_BeginningOfMonth AS ParametersOfDepreciationNmauu_BeginningOfMonth
	|		ON ParametersOfDepreciationNmauu_BeginningOfMonth.IntangibleAsset = ListOfIA.Ref
	|
	|WHERE
	|	ListOfIA.Ref IN (&ListOfIA)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	
	Period = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	Query.SetParameter("BegOfMonth", BegOfMonth(Period));
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));
	
	ListOfIA = Object.IA.Unload(RowsSelected).UnloadColumn("IntangibleAsset");
	Query.SetParameter("ListOfIA", ListOfIA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do

		TheStructureOfTheSearch = New Structure("IntangibleAsset", Selection.IntangibleAsset);
		StringsList = Object.IA.FindRows(TheStructureOfTheSearch);
		
		If StringsList.Count() <> 0 Then
			If Object.RecordInManAccounting Then
				StringsList[0].DepreciationManagementAccounting = Selection.DepreciationManagementAccounting;
			EndIf;
			If Object.RecordInLocalAccounting Then
				StringsList[0].DepreciationInAccounting = Selection.DepreciationInAccounting;
			EndIf;
		EndIf;
		
	EndDo;

EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.IntangibleAssetsCostAndAmortizationAdjustment.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("b39d4edc-7927-4a30-8119-3e71176bf097");
	Handler.UpdateDataFillingProcedure = "Documents.IntangibleAssetsCostAndAmortizationAdjustment.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang cập nhật chứng từ ""Điều chỉnh giá trị và khấu hao TSCĐVH"":
								  |- điền mục tin mới ""Phản ánh trong KTTh""';
								  |ru = 'Обновляет документы ""Корректировка стоимости и амортизации НМА"":
								  |- заполняет новый реквизит ""Отражать в НУ""';
								  |en = 'Updates the ""Adjust intangible asset cost and amortization"" documents:
								  |- Fills in the new ""Record in TA"" attribute.'; fa = 'Updates the ""Adjust intangible asset cost and amortization"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |it = 'Updates the ""Adjust intangible asset cost and amortization"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |pl = 'Updates the ""Adjust intangible asset cost and amortization"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |tr = '""Maddi Olmayan Varlık Maliyet ve Amortisman Düzeltmesi"" belgelerini günceller:
								  |- ""Vergi muhasebesinde yansıt"" yeni özniteliğini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName());

	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.IntangibleAssetsCostAndAmortizationAdjustment";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentData
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|			AND NOT DocumentData.PostInAccounting
	|			AND NOT DocumentData.RecordInTA
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
		"Document.IntangibleAssetsCostAndAmortizationAdjustment.ProcessDataForMigrationToNewVersion");
		
	FullObjectName = "Document.IntangibleAssetsCostAndAmortizationAdjustment";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.IntangibleAssetsCostAndAmortizationAdjustment
			If DocumentObject = Undefined Then
				CommitTransaction();
				InfobaseUpdate.MarkProcessingCompletion(Document.Ref);
				Continue;
			EndIf;
		
			If DocumentObject.RecordInLocalAccounting
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
