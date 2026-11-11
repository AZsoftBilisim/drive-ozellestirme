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
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	
	AllocateVariancesToFixedAssetCostLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.AllocateVariancesToFixedAssetCost") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		AllocateVariancesToFixedAssetCostLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	QueryTexts = New ValueList;
	
	QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	AllocateVariancesToFixedAssetCostLocalization.TablesOfDeferredMotionFormation(Query, QueryTexts);

	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements when calculating the cost.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains the necessary temporary tables.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesForCalculatingCost(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	GetDocumentData(Query);

	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	QueryTexts = New ValueList;

	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	AllocateVariancesToFixedAssetCostLocalization.TablesForCalculatingCost(Query, QueryTexts);

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
	
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	
	AllocateVariancesToFixedAssetCostLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.AllocateVariancesToFixedAssetCost) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AllocateVariancesToFixedAssetCost.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AllocateVariancesToFixedAssetCost);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	AllocateVariancesToFixedAssetCostLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	AllocateVariancesToFixedAssetCostLocalization.AddReportCommands(ReportsCommands, Parameters);

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

#EndRegion

#Region Internal

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	AllocateVariancesToFixedAssetCostLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

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
	
	FullDocumentName = "Document.AllocateVariancesToFixedAssetCost";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
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
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization
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
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentsList
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
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department AS Department,
	|	DocumentData.Department AS FixedAssetsLocation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.ConstructionObject AS ConstructionObject,
	|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	DocumentData.SourceDocument AS SourceDocument,
	|	ISNULL(DocumentData.SourceDocument.Date, DATETIME(1,1,1)) AS SourceDocumentDate,
	|	DocumentData.WriteOffVariancesAsExpenses AS WriteOffVariancesAsExpenses,
	|	DocumentData.ExpenseItemWriteOffCosts AS ExpenseItemWriteOffCosts,
	|	DocumentData.ExpenseDimensionWriteOffCosts AS ExpenseDimensionWriteOffCosts,
	|	DocumentData.BusinessUnitWriteOffCosts AS BusinessUnitWriteOffCosts,
	|	DocumentData.LineOfBusinessWriteOffCosts AS LineOfBusinessWriteOffCosts,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts AS BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts,
	|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN DocumentData.WriteOffVariancesAsExpenses
	|				AND DocumentData.PostInAccounting
	|			THEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|		ELSE UNDEFINED 
	|	END AS AccountingProcedureAC,
	|
	|	CASE
	|		WHEN DocumentData.WriteOffVariancesAsExpenses
	|				AND DocumentData.RecordInManAccounting
	|			THEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|		ELSE UNDEFINED 
	|	END AS AccountingProcedureMA,
	|
	|	UNDEFINED AS ExpenseItemManagementAccounting,
	|	UNDEFINED AS ExpenseItemAccounting,
	|	UNDEFINED AS ExpensesDimensionManagementAccounting,
	|	UNDEFINED AS ExpensesDimensionAccounting
	|
	|	,&DocumentAttributes
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocateVariancesToFixedAssetCost)
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
	AllocateVariancesToFixedAssetCostLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|
	|	DocumentTable.AmountOfUU AS AmountOfUU,
	|	DocumentTable.AmountAccounting AS AmountAccounting,
	|	DocumentTable.AmountFA AS AmountFA,
	|	DocumentTable.AmountPermanentDifferences AS AmountPermanentDifferences,
	|
	|	DocumentTable.AmountOfBonusDepreciationTaxAccounting AS AmountOfBonusDepreciationTaxAccounting,
	|	DocumentTable.BonusDepreciationPercentage AS BonusDepreciationPercentage,
	|	DocumentTable.AmountOfTargetFunds AS AmountOfTargetFunds
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost.FA AS DocumentTable
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
	NonCurrentAssetsInternal.ValuesOfParametersForFAAcceptanceForAccounting(ValuesOfHoldingParameters);
	
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.AllocateVariancesToFixedAssetCost"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Đưa các chênh lệch vào giá trị tài sản cố định';
															|ru = 'Отнесение отклонений в стоимость ОС';
															|en = 'Allocate variances to fixed asset cost'; fa = 'تسهیم انحرافات به بهای تمام‌شده دارایی ثابت';
															|it = 'Allocate variances to fixed asset cost';
															|pl = 'Allocate variances to fixed asset cost';
															|tr = 'Farkların sabit kıymet maliyetine yüklenmesi'"));
	ValuesOfHoldingParameters.Insert("UseCostAccounting", GetFunctionalOption("UseCostAccounting"));
	ValuesOfHoldingParameters.Insert("CostAccountingStartDate", Constants.CostAccountingStartDate.Get());
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.AllocateVariancesToFixedAssetCost);

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
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department           AS Department,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	DocumentData.Date                    AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
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
	|	DocumentData.Posted                AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInTA             AS RecordInTA,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	FATable.FixedAsset              AS FixedAsset,
	|	TRUE                                  AS IsPatch,
	|
	|	ISNULL(BEGINOFPERIOD(DocumentData.SourceDocument.Date, DAY), DATETIME(1,1,1)) AS CorrectionPeriodStart,
	|
	|	BEGINOFPERIOD(ENDOFPERIOD(DocumentData.Date, MONTH), DAY) AS CorrectionPeriodEnd
	|
	|FROM
	|	Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|		LEFT JOIN Document.AllocateVariancesToFixedAssetCost.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	FATable.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness,
	|	FixedAssetsAccountingProcedure.RunningTimeValue AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime AS EstimatedRunningTime
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.WriteOffVariancesAsExpenses
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	TTAccountingProcedureForOsuu.FixedAsset AS FixedAsset,
	|	TTAccountingProcedureForOsuu.State AS State,
	|	TTAccountingProcedureForOsuu.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	TTAccountingProcedureForOsuu.ExpensesPostingMethod AS ExpensesPostingMethod,
	|	TTAccountingProcedureForOsuu.ExpenseItem AS ExpenseItem,
	|	TTAccountingProcedureForOsuu.DimensionOfExpenses AS DimensionOfExpenses,
	|	TTAccountingProcedureForOsuu.Department AS Department,
	|	TTAccountingProcedureForOsuu.LineOfBusiness AS LineOfBusiness,
	|	TTAccountingProcedureForOsuu.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	TTAccountingProcedureForOsuu.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	TTAccountingProcedureForOsuu.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = FATable.Ref
	|			AND TTAccountingProcedureForOsuu.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND NOT DocumentData.WriteOffVariancesAsExpenses
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)
	
	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts);
	
	QueryText = AllocateVariancesToFixedAssetCostLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	AccountingProcedureForOSBU.FixedAsset AS FixedAsset,
		|	DocumentData.Organization AS Organization,
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|	AccountingProcedureForOSBU.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|	AccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	AccountingProcedureForOSBU.ExpenseItemAccounting AS ExpenseItemAccounting,
		|	AccountingProcedureForOSBU.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
		|	AccountingProcedureForOSBU.DepartmentACC AS DepartmentACC,
		|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
		|	AccountingProcedureForOSBU.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
		|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND NOT DocumentData.WriteOffVariancesAsExpenses
		|";
	
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.LastChangeDate AS LastChangeDate,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeMonths,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod AS DepreciationMethod,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan AS ResidualValueMan,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal AS ResidualValueLocal,
	|	FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND NOT DocumentData.WriteOffVariancesAsExpenses
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts);

	QueryText = AllocateVariancesToFixedAssetCostLocalization.QueryTextTableOSBUDepreciationParameters(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref       AS Recorder,
		|	DocumentData.Period       AS Period,
		|	DocumentData.Organization  AS Organization,
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	OSBUDepreciationParameters.LastChangeDate      AS LastChangeDate,
		|	OSBUDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
		|	OSBUDepreciationParameters.AnnualDepreciationRate     AS AnnualDepreciationRate,
		|	OSBUDepreciationParameters.AccelerationFactor         AS AccelerationFactor,
		|	OSBUDepreciationParameters.DepreciationSchedule            AS DepreciationSchedule,
		|	OSBUDepreciationParameters.SpecialFactor       AS SpecialFactor,
		|	OSBUDepreciationParameters.ResidualValueMan      AS ResidualValueMan,
		|	OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND NOT DocumentData.WriteOffVariancesAsExpenses
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTVATTaxation(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTTaxSystemSettings(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region Recognition
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness   AS LineOfBusiness,
	|	FALocation.Leaseholder              AS Leaseholder,
	|	&BusinessOperation                   AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
	|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	FATable.FixedAsset               AS FixedAsset,
	|
	|	CASE 
	|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject) 
	|			THEN DocumentData.ConstructionObject 
	|		ELSE FATable.FixedAsset 
	|	END AS ExpensesCapitalizationDimension,
	|
	|	ISNULL(TTCostCalculation.Department, UNDEFINED)                AS DebitBusinessUnit,
	|	ISNULL(TTCostCalculation.LineOfBusiness, UNDEFINED)      AS CorLineOfBusiness,
	|	ISNULL(TTCostCalculation.ExpenseItem, UNDEFINED)               AS CorExpenseItem,
	|	ISNULL(TTCostCalculation.DimensionOfExpenses, UNDEFINED)            AS CorExpenditureDimension,
	|	TTVATTaxation.VATTaxation                                AS VATTaxation,
	|	NOT TTCostCalculation.AccountingObject IS NULL                             AS CostCalculation,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountOfUU, FATable.AmountOfUU)
	|	END AS Cost,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountAccounting, FATable.AmountAccounting)
	|	END AS LocalCost,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInTA
	|				OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		WHEN TTCostCalculation.AccountingObject IS NULL
	|			THEN FATable.AmountFA
	|		ELSE ISNULL(TTCostCalculation.AmountFA + TTCostCalculation.SumOfNUCF, FATable.AmountFA)
	|	END AS CostInTaxAccounting,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		WHEN TTCostCalculation.AccountingObject IS NULL
	|			THEN FATable.AmountPermanentDifferences
	|		ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences - TTCostCalculation.CFAmount + TTCostCalculation.PRCFAmount, FATable.AmountPermanentDifferences)
	|	END AS CostPermanentDifference,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN NOT DocumentData.PostInAccounting
	|					THEN 0
	|				ELSE ISNULL(TTCostCalculation.AmountAccounting, FATable.AmountAccounting)
	|			END
	|				- CASE
	|					WHEN NOT DocumentData.RecordInTA
	|							OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses)
	|						THEN 0
	|					WHEN TTCostCalculation.AccountingObject IS NULL
	|						THEN FATable.AmountFA
	|					ELSE ISNULL(TTCostCalculation.AmountFA + TTCostCalculation.SumOfNUCF, FATable.AmountFA)
	|				END
	|				- CASE
	|					WHEN NOT DocumentData.PostInAccounting
	|						THEN 0
	|					WHEN TTCostCalculation.AccountingObject IS NULL
	|						THEN FATable.AmountPermanentDifferences
	|					ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences - TTCostCalculation.CFAmount + TTCostCalculation.PRCFAmount, FATable.AmountPermanentDifferences)
	|				END 
	|	END AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	0                                                                      AS DepreciationAllowance,
	|	0                                                                      AS PreliminaryCostMan,
	|	0                                                                      AS PreliminaryCostLocal,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences, 0)
	|	END AS CorAmountPD,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN NOT DocumentData.PostInAccounting
	|						OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|					THEN 0
	|				ELSE ISNULL(TTCostCalculation.AmountAccounting, FATable.AmountAccounting - FATable.AmountOfTargetFunds)
	|			END
	|				- CASE 
	|					WHEN NOT DocumentData.RecordInTA
	|							OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses)
	|							OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|						THEN 0
	|					ELSE ISNULL(TTCostCalculation.AmountFA, FATable.AmountAccounting)
	|				END
	|				- CASE
	|					WHEN NOT DocumentData.PostInAccounting
	|							OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|						THEN 0
	|					ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences, FATable.AmountPermanentDifferences)
	|				END 
	|	END AS CorAmountTD,
	|	
	|	ISNULL(TTCostCalculation.RowID, &IDOfUnusedFinRecord) AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = FATable.Ref
	|			AND TTCostCalculation.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = FATable.Ref
	|			AND FALocation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = FATable.Ref
	|			AND TTVATTaxation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTTaxSystemSettings AS TTTaxSystemSettings
	|		ON TTTaxSystemSettings.Ref = DocumentData.Ref
	|
	|WHERE
	|	NOT DocumentData.WriteOffVariancesAsExpenses
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion

	#Region PreliminaryCostMan
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness   AS LineOfBusiness,
	|	FALocation.Leaseholder              AS Leaseholder,
	|	&BusinessOperation                   AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
	|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	FATable.FixedAsset               AS FixedAsset,
	|
	|	CASE 
	|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject) 
	|			THEN DocumentData.ConstructionObject 
	|		ELSE FATable.FixedAsset 
	|	END                                    AS ExpensesCapitalizationDimension,
	|
	|	UNDEFINED                             AS DebitBusinessUnit,
	|	UNDEFINED                             AS CorLineOfBusiness,
	|	UNDEFINED                             AS CorExpenseItem,
	|	UNDEFINED                             AS CorExpenditureDimension,
	|	TTVATTaxation.VATTaxation  AS VATTaxation,
	|	FALSE                                     AS CostCalculation,
	|
	|	0                                        AS Cost,
	|	0                                        AS LocalCost,
	|	0                                        AS CostInTaxAccounting,
	|	0                                        AS CostPermanentDifference,
	|	0                                        AS CostTemporaryDifference,
	|	0                                        AS CostTargetFinancing,
	|	0                                        AS CostTargetFinancingPD,
	|
	|	0                                        AS DepreciationAllowance,
	|
	|	FATable.AmountOfUU                        AS PreliminaryCostMan,
	|	FATable.AmountAccounting                        AS PreliminaryCostLocal,
	|
	|	0                                        AS CorAmountPD,
	|	0                                        AS CorAmountTD,
	|	
	|	&IDOfUnusedFinRecord    AS FinRecordID,
	|	UNDEFINED                             AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = FATable.Ref
	|			AND FALocation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = FATable.Ref
	|			AND TTVATTaxation.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.WriteOffVariancesAsExpenses
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion
	
	AllocateVariancesToFixedAssetCostLocalization.AddRequestTextFACostTable(ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)

	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Add_Fields = "Recorder,VariancePeriod";
	Add_Fields = "Recorder,VariancePeriod,AITAmount";
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	
	ListOfMergeRequests = New Array;

	#Region Recognition
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	&BusinessOperation                       AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	TTCostCalculation.ExpenseItem             AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                 AS FinancialAccountingGroup,
	|
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|	&APArticle                                    AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTCostCalculation.AccountingObject                AS CorDimensionOfAssetsLiabilities,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.Sum
	|	END AS Sum,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount
	|	END AS SumCompl,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountOfUU
	|	END AS SumMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTCostCalculation.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTCostCalculation.AccountingObject
	|
	|WHERE
	|	NOT DocumentData.WriteOffVariancesAsExpenses
	|
	|	AND (DocumentData.RecordInManAccounting
	|			AND TTCostCalculation.AmountOfUU <> 0
	|		OR DocumentData.PostInAccounting
	|			AND (TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount) <> 0)
	|";

	ListOfMergeRequests.Add(QueryText);

	#EndRegion
	
	#Region DoNotTakeIntoAccountIncludeInExpenses
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	TTCostCalculation.ExpenseItem             AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                 AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitWriteOffCosts
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts
	|			THEN DocumentData.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessWriteOffCosts
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.ExpenseItemWriteOffCosts AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	DocumentData.ExpenseDimensionWriteOffCosts AS CorExpenditureDimension,
	|	UNDEFINED                                 AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED                                 AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.Sum
	|	END AS Sum,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount
	|	END AS SumCompl,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountOfUU
	|	END AS SumMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.WriteOffVariancesAsExpenses
	|
	|	AND (DocumentData.RecordInManAccounting
	|			AND TTCostCalculation.AmountOfUU <> 0
	|		OR DocumentData.PostInAccounting
	|			AND (TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount) <> 0)
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableTTAmountOfExpenses(QueryTexts) Export

	TableName = "TTAmountOfExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FACost.Recorder AS Ref,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	SUM(FACost.LocalCost + FACost.CostTargetFinancing) AS SumCompl,
	|	SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD) AS AmountPermanentDifferences,
	|	SUM(FACost.CostInTaxAccounting) AS AmountFA,
	|	SUM(FACost.CostTargetFinancing) AS CFAmount,
	|	SUM(FACost.Cost) AS Sum
	|
	|INTO TTAmountOfExpenses
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|WHERE
	|	FACost.CostCalculation
	|	AND FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	AND FACost.Recorder IN (
	|		SELECT
	|			DocumentData.Ref
	|		FROM 
	|			DocumentDataDetails AS DocumentData)
	|
	|GROUP BY
	|	FACost.Recorder,
	|	FACost.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields)

	RegisterName = "TTInitialOtherExpenses";
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTTaxSystemSettings(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	NonCurrentAssetsInternal.TextOfRequestOtherexpensesOfAcceptanceForAccounting(ListOfMergeRequests);

	AllocateVariancesToFixedAssetCostLocalization.AddRequestTextTableTTInitialOtherExpenses(ListOfMergeRequests);

	#Region DoNotTakeIntoAccountIncludeMAInExpenses // Dr 91 - Cr 08
	
	QueryText =
	"SELECT
	|	DocumentData.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Organization                  AS Organization,
	|   TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.ExpenseItem             AS ExpenseItem,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                                 AS VATActivityType,
	|
	|	TTCostCalculation.Sum AS AmountIncludingVAT,
	|	TTCostCalculation.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTCostCalculation.AmountOfUU AS AmountExcludingVATMan,
	|
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	                                                                             
	|	TTCostCalculation.RowID AS FinRecordID,
	|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref AS Recorder,
	|	TTCostCalculation.VariancePeriod AS VariancePeriod
	|
	|	,0 AS AITAmount
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.WriteOffVariancesAsExpenses
	|	AND DocumentData.RecordInManAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Organization                  AS Organization,
	|
	|   CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitWriteOffCosts
	|	END AS Department,
	|
	|	DocumentData.ExpenseItemWriteOffCosts    AS ExpenseItem,
	|	DocumentData.ExpenseDimensionWriteOffCosts AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts
	|			THEN DocumentData.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessWriteOffCosts
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                 AS VATActivityType,
	|
	|	TTCostCalculation.Sum AS AmountIncludingVAT,
	|	TTCostCalculation.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTCostCalculation.AmountOfUU AS AmountExcludingVATMan,
	|
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	                                                                             
	|	TTCostCalculation.RowID AS FinRecordID,
	|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|	,0 AS AITAmount
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.WriteOffVariancesAsExpenses
	|	AND DocumentData.RecordInManAccounting
	|";

	ListOfMergeRequests.Add(QueryText);
	#EndRegion
		
	#Region NotToBeTakenIntoAccountIncludeACInExpenses // Dr 91 - Cr 08
	QueryText =
	"SELECT
	|	DocumentData.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Organization                  AS Organization,
	|   TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.ExpenseItem             AS ExpenseItem,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                                 AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	TTCostCalculation.AmountAccounting AS AmountIncludingVATCompl,
	|	TTCostCalculation.AmountAccounting AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountPermanentDifferences 
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting - TTCostCalculation.AmountPermanentDifferences 
	|	END AS CostTD,
	|
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	                                                                             
	|	TTCostCalculation.IdOfACLine AS FinRecordID,
	|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref AS Recorder,
	|	TTCostCalculation.VariancePeriod AS VariancePeriod
	|
	|	,0 AS AITAmount
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTTaxSystemSettings AS TTTaxSystemSettings
	|		ON TTTaxSystemSettings.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.WriteOffVariancesAsExpenses
	|	AND DocumentData.PostInAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Organization                  AS Organization,
	|
	|   CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts
	|			THEN DocumentData.Department
	|		ELSE DocumentData.BusinessUnitWriteOffCosts
	|	END AS Department,
	|
	|	DocumentData.ExpenseItemWriteOffCosts    AS ExpenseItem,
	|	DocumentData.ExpenseDimensionWriteOffCosts AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts
	|			THEN DocumentData.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessWriteOffCosts
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                 AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	TTCostCalculation.AmountAccounting AS AmountIncludingVATCompl,
	|	TTCostCalculation.AmountAccounting AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountPermanentDifferences 
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting - TTCostCalculation.AmountPermanentDifferences 
	|	END AS CostTD,
	|
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	                                                                             
	|	TTCostCalculation.IdOfACLine AS FinRecordID,
	|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref AS Recorder,
	|	DATETIME(1,1,1) AS VariancePeriod
	|
	|	,0 AS AITAmount
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTTaxSystemSettings AS TTTaxSystemSettings
	|		ON TTTaxSystemSettings.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.WriteOffVariancesAsExpenses
	|	AND DocumentData.PostInAccounting
	|";
	
	ListOfMergeRequests.Add(QueryText);
		
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return AllocateVariancesToFixedAssetCostLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return AllocateVariancesToFixedAssetCostLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CostGenerationProcedure", Parameters);

EndProcedure

// 
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost -
Procedure FillInBasedOnPrimaryDocument(Object) Export
	
	If Not ValueIsFilled(Object.SourceDocument) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);

	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.FixedAssetsLocation AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
	|	DocumentData.ConstructionObject AS ConstructionObject,
	|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &SourceDocument
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
	|	DocumentData.ConstructionObject AS ConstructionObject,
	|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &SourceDocument
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.FixedAssetsLocation AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.KindsOfExpenseCapitalizationDimension.FixedAssets) AS DimensionKindExpenseCapitalization,
	|	UNDEFINED AS ConstructionObject,
	|	UNDEFINED AS TargetFinancingApplicationOption,
	|
	|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
	|	FALSE AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &SourceDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.FixedAsset AS FixedAsset
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &SourceDocument
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.FixedAsset AS FixedAsset
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &SourceDocument
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.DepreciationComponent AS FixedAsset
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS FATable
	|
	|WHERE
	|	FATable.Ref = &SourceDocument
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("SourceDocument", Object.SourceDocument);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()-1].Select();
	Selection.Next();
	
	FillPropertyValues(Object, Selection);
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	Object.FA.Clear();
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		RowData = Object.FA.Add();
		FillPropertyValues(RowData, Selection);
	EndDo;
	
	FillInCostAmount(Object);
	
EndProcedure

Procedure FillInCostAmount(Object, RowsSelected = Undefined) Export

	If Not CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Object.Date) Then
		Return;
	EndIf; 
	
	DocumentDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	FATable = Object.FA.Unload(RowsSelected);

	TempTablesManager = New TempTablesManager;
	
	QueryText = 
	"SELECT
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.AmountOfUU AS AmountOfUU,
	|	FATable.AmountAccounting AS AmountAccounting,
	|	FATable.AmountFA AS AmountFA,
	|	FATable.AmountPermanentDifferences AS AmountPermanentDifferences,
	|	FATable.AmountOfTargetFunds AS AmountOfTargetFunds,
	|	FATable.RowID AS RowID
	|
	|INTO FATable
	|
	|FROM
	|	&FATable AS FATable
	|
	|WHERE
	|	FATable.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	FATable.FixedAsset AS AccountingObject,
	|	1 AS Priority
	|
	|INTO TTPortionOfDataToBeCalculated
	|
	|FROM
	|	FATable AS FATable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS AccountingObject,
	|
	|	&CostGenerationProcedure AS CostGenerationProcedure,
	|
	|	CASE
	|		WHEN &DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ExpensesAreDistributedByObjects,
	|
	|	CASE
	|		WHEN CAST(FATable.FixedAsset AS Catalog.Assets).OSType = VALUE(Enum.FATypes.DepreciationComponent)
	|				AND NOT CAST(FATable.FixedAsset AS Catalog.Assets).ConsiderResidualLiabilityValue
	|				AND NOT Table_DepreciationComponents.FixedAsset IS NULL
	|			THEN Table_DepreciationComponents.FixedAsset
	|
	|		WHEN &DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
	|			THEN &ConstructionObject
	|
	|		ELSE FATable.FixedAsset
	|	END AS ExpensesCapitalizationDimension,
	|
	|	FALSE AS ActualCost,
	|	TRUE AS AttributingDeviationsToCost,
	|
	|	ISNULL(FixedAssetsInitialRecognition.Date, 
	|		ISNULL(FixedAssetsCostAdditions.Date, 
	|			ISNULL(RecognizeSubAssetsComponentsOfDepreciation.Date, DATETIME(1,1,1)))) AS SourceDocumentDate,
	|
	|	FATable.AmountOfUU AS AmountOfUU,
	|	FATable.AmountAccounting AS AmountAccounting,
	|	FATable.AmountFA AS AmountFA,
	|
	|	&TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	FATable.AmountOfTargetFunds AS AmountOfTargetFunds,
	|
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	&PostInAccounting AS PostInAccounting,
	|	&RecordInTA AS RecordInTA,
	|	&PostInAccounting AS TakeIntoAccountPD,
	|
	|	FATable.RowID AS RowID
	|
	|INTO TTTableOfObjects
	|
	|FROM
	|	FATable AS FATable
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = &SourceDocument
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4 AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = &SourceDocument
	|
	|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation AS RecognizeSubAssetsComponentsOfDepreciation
	|		ON RecognizeSubAssetsComponentsOfDepreciation.Ref = &SourceDocument
	|
	|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS Table_DepreciationComponents
	|		ON Table_DepreciationComponents.Ref = &SourceDocument
	|			AND Table_DepreciationComponents.DepreciationComponent = FATable.FixedAsset
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", DocumentDate);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("DimensionKindExpenseCapitalization", Object.DimensionKindExpenseCapitalization);
	Query.SetParameter("ConstructionObject", Object.ConstructionObject);
	Query.SetParameter("SourceDocument", Object.SourceDocument);
	Query.SetParameter("AccountingProcedureMA", Undefined);
	Query.SetParameter("AccountingProcedureAC", Undefined);
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.AllocateVariancesToFixedAssetCost);
	Query.SetParameter("CostGenerationProcedure", Object.CostGenerationProcedure);
	Query.SetParameter("TargetFinancingApplicationOption", Object.TargetFinancingApplicationOption);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInTA", Object.RecordInTA);
	Query.SetParameter("FATable", FATable);
	
	Query.Execute();
	
	FACostCalculation.GenerateTTCurrentExpenses(DocumentDate, TempTablesManager);
	
	QueryText = 
	"SELECT
	|	TTCurExpenses.AccountingObject AS AccountingObject,
	|	SUM(TTCurExpenses.SumMan) AS SumMan,
	|	SUM(TTCurExpenses.SumCompl) AS SumCompl,
	|	SUM(TTCurExpenses.SumCompl - TTCurExpenses.PermanentDifference - TTCurExpenses.CostTD) AS AmountFA,
	|	SUM(TTCurExpenses.PermanentDifference) AS AmountPermanentDifferences
	|
	|FROM
	|	TTCurExpenses AS TTCurExpenses
	|
	|GROUP BY
	|	TTCurExpenses.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Result = Query.Execute();

	DocumentExpenses = Result.Unload();
	
	If RowsSelected <> Undefined Then
		StringsList = RowsSelected;
	Else
		StringsList = Object.FA;
	EndIf; 
	
	For Each RowData In StringsList Do
		
		RowData.AmountOfUU = 0;
		RowData.AmountAccounting = 0;
		RowData.AmountFA = 0;
		RowData.AmountPermanentDifferences = 0;

		TheStructureOfTheSearch = New Structure("AccountingObject", RowData.FixedAsset);
		ListOfExpenseLines = DocumentExpenses.FindRows(TheStructureOfTheSearch);
		If ListOfExpenseLines.Count() = 0 Then
			Continue
		EndIf;
		
		If Object.RecordInManAccounting Then
			RowData.AmountOfUU = ListOfExpenseLines[0].SumMan;
		EndIf;
		
		If Object.PostInAccounting Then
			RowData.AmountAccounting = ListOfExpenseLines[0].SumCompl;
			RowData.AmountPermanentDifferences = ListOfExpenseLines[0].AmountPermanentDifferences;
		EndIf; 
		
		If Object.RecordInTA Then
			RowData.AmountFA = ListOfExpenseLines[0].AmountFA;
		EndIf; 
		
	EndDo;
	
EndProcedure

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	#Region ExpenseItemWriteOffCosts
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemWriteOffCosts";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpenseDimensionWriteOffCosts";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemWriteOffCosts");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpenseDimensionWriteOffCosts");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	#EndRegion

	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Adds procedures to the list-handlers for updating information security data
// 
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.AllocateVariancesToFixedAssetCost.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("d6837d44-fd92-4d6f-9107-ceedee4f772f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.AllocateVariancesToFixedAssetCost.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Phân bổ chênh lệch vào giá trị TSCĐ"":
								  |- Điền mục tin ""Phương thức hình thành giá trị""';
								  |ru = 'Обновляет документы ""Отнесение отклонений в стоимость ОС"":
								  |- Заполняет реквизит ""Порядок формирования стоимости""';
								  |en = 'Updates the ""Allocate variances to fixed asset cost"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.'; fa = 'Updates the ""Allocate variances to fixed asset cost"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.';
								  |it = 'Updates the ""Allocate variances to fixed asset cost"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.';
								  |pl = 'Updates the ""Allocate variances to fixed asset cost"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.';
								  |tr = '""Farkların Sabit Kıymet Maliyetine Yüklenmesi"" belgelerini günceller: 
								  | - ""Maliyet oluşturma düzeni"" özniteliğini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.AllocateVariancesToFixedAssetCost.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.AllocateVariancesToFixedAssetCost";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentsList.Ref AS Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref
	|	FROM
	|		Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|	WHERE
	|		DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.EmptyRef)
	|
	|	) AS DocumentsList
	|";
	
	Query = New Query(QueryText);
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.AllocateVariancesToFixedAssetCost.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.AllocateVariancesToFixedAssetCost";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.AllocateVariancesToFixedAssetCost
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If DocumentObject.RecordInLocalAccounting
				And Not DocumentObject.PostInAccounting
				And Not DocumentObject.RecordInTA Then
					
				DocumentObject.PostInAccounting = True;
				
				
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.CostGenerationProcedure) Then
				DocumentObject.CostGenerationProcedure = Enums.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeDocumentCreationDateInCost;
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
	