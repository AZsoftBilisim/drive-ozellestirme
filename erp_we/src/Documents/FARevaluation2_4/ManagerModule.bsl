
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Commands

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
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	FARevaluationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);

	FARevaluationLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "revaluation of the OS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order - Number - The order of the command in the menu.
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.FARevaluation2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.FARevaluation2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.FARevaluation2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Order = Order;
		
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
	
	FARevaluationLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

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

#Region Posting

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
	
	If TypeOf(Document) = Type("DocumentObject.FARevaluation2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
		QueryTexts = New ValueList;
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		FARevaluationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	
	GetDocumentData(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
		
	QueryTexts = New ValueList;
	
	NonCurrentAssetsInternal.RequestTextsForRevaluation(Query, QueryTexts, "FA", Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	FARevaluationLocalization.TablesOfDeferredMotionFormation(Query, QueryTexts);

	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

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
	
	FullDocumentName = "Document.FARevaluation2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
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
										RedefiningParameterCalculation);
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
	|	DocumentData.Number AS Number
	|FROM
	|	DocumentDataDetails AS DocumentData
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
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
	|	Document.FARevaluation2_4 AS DocumentsList
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
	|	DocumentData.Ref              AS Ref,
	|	DocumentData.Date                AS Period,
	|	DocumentData.Number               AS Number,
	|	DocumentData.Organization         AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.EmployeeResponsible       AS EmployeeResponsible,
	|	DocumentData.Comment         AS Comment,
	|	DocumentData.Posted            AS Posted,
	|	DocumentData.DeletionMark     AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting   AS RecordInManAccounting,
	|	DocumentData.Department       AS Department,
	|	DocumentData.IncomeItem       AS IncomeItem,
	|	DocumentData.DimensionOfRevenue    AS DimensionOfRevenue,
	|	DocumentData.IncomeBusinessUnit AS IncomeBusinessUnit,
	|	DocumentData.LineOfBusinessIncome AS LineOfBusinessIncome,
	|	DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData AS IncomeBusinessUnitAndLineOfBusinessMatchAccountingData,
	|	DocumentData.ExpenseItem      AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses   AS DimensionOfExpenses,
	|	DocumentData.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DocumentData.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	DocumentData.FixedAssetsEvent           AS FixedAssetsEvent,
	|	DocumentData.RevaluateAtFairValue AS RevaluateAtFairValue,
	|	ISNULL(DocumentData.ExpenseItem.EnteredInTaxAccounting, TRUE) AS EnteredInTaxAccounting,
	|	VALUE(Enum.BusinessTransactions.FARevaluation) AS BusinessOperation
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FARevaluation2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.FARevaluation2_4.FA AS DocumentTable
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

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FARevaluation2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Đánh giá lại TSCĐ';
															|ru = 'Переоценка ОС';
															|en = 'Revaluate fixed assets'; fa = 'تجدید ارزیابی دارایی‌های ثابت';
															|it = 'Rivalutazione Capitale Fisso';
															|pl = 'Przeszacowanie środków trwałych';
															|tr = 'Sabit kıymet yeniden değerlemesi'"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.FARevaluation);
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.FARevaluation);
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("ArticleAP_AccountingObject", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	
	ValuesOfHoldingParameters.Insert("BO_CostIncrease", Enums.BusinessTransactions.FixedAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("BO_CostIncreaseDueToMarkdowns", Enums.BusinessTransactions.IncreaseFixedAssetCostAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("BO_CostReduction", Enums.BusinessTransactions.FixedAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("HO_CostReductionDueToAdditionalAssessment", Enums.BusinessTransactions.DecreaseFixedAssetCostAtFinalAppraisalExpense);

	ValuesOfHoldingParameters.Insert("BO_IncreasedDepreciation", Enums.BusinessTransactions.IncreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("BO_IncreaseInDepreciationDueToMarkdowns", Enums.BusinessTransactions.IncreaseFixedAssetDepreciationAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("BO_DecreaseInDepreciation", Enums.BusinessTransactions.DecreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("HO_ReductionOfDepreciationDueToAdditionalValuation", Enums.BusinessTransactions.DecreaseFixedAssetDepreciationAtFinalAppraisalExpense);

	ValuesOfHoldingParameters.Insert("SettingUpHO_CostIncrease", Catalogs.BusinessTransactionsSettings.FixedAssetsCostAddition);
	ValuesOfHoldingParameters.Insert("SettingUpBT_CostIncreaseDueToMarkdowns", Catalogs.BusinessTransactionsSettings.IncreaseFixedAssetCostAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostReduction", Catalogs.BusinessTransactionsSettings.FixedAssetsCostDecrease);
	ValuesOfHoldingParameters.Insert("SettingUpBT_CostReductionDueToAdditionalAssessment", Catalogs.BusinessTransactionsSettings.DecreaseFixedAssetCostAtFinalAppraisalExpense);
		
	ValuesOfHoldingParameters.Insert("SettingHO_IncreaseDepreciation", Catalogs.BusinessTransactionsSettings.IncreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("SettingUpBT_IncreaseDepreciationDueToMarkdowns", Catalogs.BusinessTransactionsSettings.IncreaseFixedAssetDepreciationAtDevaluationExpense);
	ValuesOfHoldingParameters.Insert("SettingHO_ReductionOfDepreciation", Catalogs.BusinessTransactionsSettings.DecreaseInFixedAssetDepreciation);
	ValuesOfHoldingParameters.Insert("SettingUpBT_ReductionOfDepreciationDueToAdditionalAssessment", Catalogs.BusinessTransactionsSettings.DecreaseFixedAssetDepreciationAtFinalAppraisalExpense);
		
	ValuesOfHoldingParameters.Insert("BO_DepreciationReductionNetMethod", Enums.BusinessTransactions.DecreaseFixedAssetDepreciationCashMethod);
	ValuesOfHoldingParameters.Insert("SettingUpBT_DepreciationReductionBalanceMethod", Catalogs.BusinessTransactionsSettings.DecreaseFixedAssetDepreciationCashMethod);
	
	ValuesOfHoldingParameters.Insert("BO_RecoverImpairmentLoss", Enums.BusinessTransactions.RecoverImpairmentLoss);
	ValuesOfHoldingParameters.Insert("SettingUpBT_RecoveryOfImpairmentLoss", Catalogs.BusinessTransactionsSettings.RecoverImpairmentLoss);

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		ValuesOfHoldingParameters.Insert("EndOfDay", New Boundary(EndOfDay(Attributes.Period), BoundaryType.Including));
	EndIf;
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)            AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.Date                            AS Date,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.Posted                        AS Posted,
	|	&BusinessOperation                          AS BusinessOperation,
	|	&MetadataIdentifier                        AS RefType,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.FixedAssetsEvent                       AS FixedAssetsEvent,
	|	FATable.FixedAsset                      AS FixedAsset
	|
	|FROM
	|	Document.FARevaluation2_4 AS DocumentData
	|
	|		LEFT JOIN Document.FARevaluation2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
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
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Organization             AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	UNDEFINED                            AS LineOfBusiness,
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
	|	Document.FARevaluation2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.LastChangeDate     AS LastChangeDate,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeMonths,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan     AS ResidualValueMan,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal AS ResidualValueLocal,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	CASE 
			// If there was an upgrade, then the residual value is taken to calculate depreciation
	|		WHEN FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths <> FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|			THEN FATable.CostInManagementAccounting 
	|					- (ISNULL(DepreciationOfVNA.Depreciation, 0)
	|						+ ISNULL(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation, 0)
	|						- ISNULL(RevaluationTable.AmountOfMarkdownDepreciationMa, 0))
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag 
	|				+ ISNULL(RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa, 0)
	|				- ISNULL(RevaluationTable.AmountOfMaMarkdown, 0)
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	|	CASE 
	|		WHEN &ComplianceCAAccountingIsKept
	|			THEN 0
			// If there was an upgrade, then the residual value is taken to calculate depreciation
	|		WHEN FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths <> FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|			THEN FATable.CostInAccounting 
	|					- (ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|						+ ISNULL(RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation, 0)
	|						- ISNULL(RevaluationTable.AmountOfMarkdownDepreciationAC, 0))
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal 
	|				+ ISNULL(RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC, 0)
	|				- ISNULL(RevaluationTable.AmountOfACCostMarkdown, 0)
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = FATable.Ref
	|			AND RevaluationTable.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = FATable.Ref
	|			AND DepreciationOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) <> VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return FARevaluationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return FARevaluationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	FARevaluationLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FARevaluation2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array, Undefined - 
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.FixedAssetsPhysicalCount.FillingDataBasedOnInventory24(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.Revaluation, 
							ArrayOfLineNumbers);
		
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu đánh giá lại';
							|ru = 'В документе %1 отсутствуют строки требующие создания переоценки';
							|en = 'No lines that require creating revaluation in the %1 document'; fa = 'No lines that require creating revaluation in the %1 document';
							|it = 'No lines that require creating revaluation in the %1 document';
							|pl = 'No lines that require creating revaluation in the %1 document';
							|tr = '%1 belgesinde yeniden değerleme oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return;
		
	EndIf;
	
	Selection = DataToFill.Attributes[0];
	FillPropertyValues(Object, Selection);
	Object.Department = Selection.FixedAssetsLocation;
	Object.RevaluateAtFairValue = False;
	
	RecordInLocalAccounting = False;
	RecordInManAccounting = False;
	
	For Each Selection In DataToFill.TabularSection Do
		
		If Not Selection.PostInAccounting And Not Selection.RecordInManAccounting Then
			Continue;
		EndIf;
		
		RowData = Object.FA.Add();
		RowData.FixedAsset = Selection.FixedAsset;
		
		If Selection.PostInAccounting Then
			RowData.CostInAccounting = Selection.ActualCostAC;
			RecordInLocalAccounting = True;
		EndIf; 
		
		If Selection.RecordInManAccounting Then
			RowData.CostInManagementAccounting = Selection.CostActualMan;
			RecordInManAccounting = True;
		EndIf; 
		
	EndDo;
	
	If Object.FA.Count() <> 0 Then
		Object.RecordInLocalAccounting = RecordInLocalAccounting;
		Object.RecordInManAccounting = RecordInManAccounting;
	EndIf;
	
EndProcedure

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization,EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization,EmployeeResponsible";

	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RevaluateAtFairValue", Parameters);

EndProcedure

#EndRegion

#EndRegion

#EndIf
