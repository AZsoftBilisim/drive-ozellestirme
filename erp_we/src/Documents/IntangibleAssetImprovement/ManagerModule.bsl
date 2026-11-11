
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
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	
	IntangibleAssetImprovementLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IntangibleAssetImprovement") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers);
		
		QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(Query, QueryTexts, Registers);
		QueryTextTableIACost(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		IntangibleAssetImprovementLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	
	QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	IntangibleAssetImprovementLocalization.TablesOfDeferredMotionFormation(Query, QueryTexts);

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
	
	QueryTextTableIACost(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	IntangibleAssetImprovementLocalization.TablesForCalculatingCost(Query, QueryTexts, Undefined);
	
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
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	Documents.ChangeIntangibleAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "revaluation of IA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.IntangibleAssetImprovement) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IntangibleAssetImprovement.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IntangibleAssetImprovement);
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

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure OnFillAccessRestriction(Lists) Export

	Lists.Text =
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
	
	FullDocumentName = "Document.IntangibleAssetImprovement";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(QueryTexts, RegisterName);
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
	|	DocumentDataDetails.Period AS Period,
	|	DocumentDataDetails.Number AS Number
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
	|	Document.IntangibleAssetImprovement AS DocumentsList
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
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.InvestmentTaxDeduction AS InvestmentTaxDeduction,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	SettingUpHO.Ref AS BusinessTransactionSetting
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.IntangibleAssetImprovement AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS SettingUpHO
	|		ON SettingUpHO.BusinessOperation = DocumentData.BusinessOperation
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
	FixedAssetsCostAdditionsLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset,
	|	DocumentTable.IntangibleAsset AS AccountingObject,
	|
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|	DocumentTable.CostInTaxAccounting AS CostInTaxAccounting,
	|	DocumentTable.CostPermanentDifference AS CostPermanentDifference
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.IntangibleAssetImprovement.IA AS DocumentTable
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.IntangibleAssetImprovement"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Cải thiện TSCĐ vô hình';
															|ru = 'Улучшение НМА';
															|en = 'Intangible asset improvement'; fa = 'بهبود دارایی نامشهود';
															|it = 'Улучшение НМА';
															|pl = 'Intangible asset improvement';
															|tr = 'GMA''nın iyileştirilmesi'"));
	ValuesOfHoldingParameters.Insert("DimensionKindExpenseCapitalization", Enums.KindsOfExpenseCapitalizationDimension.IntangibleAssetsAndRD);
	ValuesOfHoldingParameters.Insert("TargetFinancingApplicationOption", Undefined);
	ValuesOfHoldingParameters.Insert("APArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	ValuesOfHoldingParameters.Insert("UseCostAccounting", GetFunctionalOption("UseCostAccounting"));
	ValuesOfHoldingParameters.Insert("CostAccountingStartDate", Constants.CostAccountingStartDate.Get());
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
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
	|	DocumentData.Ref         AS Ref,
	|	DocumentData.Date           AS IBDocumentDate,
	|	DocumentData.Number          AS IBDocumentNumber,
	|	&MetadataIdentifier       AS RefType,
	|	DocumentData.Organization    AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	UNDEFINED                   AS LineOfBusiness,
	|	DocumentData.Department  AS Department,
	|	DocumentData.EmployeeResponsible  AS EmployeeResponsible,
	|	DocumentData.Comment    AS Comment,
	|	DocumentData.Posted       AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE                           AS AdditionalRecord,
	|	DocumentData.Date           AS SourceDocumentDate,
	|	&NumberForPrinting                 AS SourceDocumentNumber,
	|	FALSE                           AS ReverseTransactionCorrection,
	|	UNDEFINED                   AS ReversedDocument,
	|	UNDEFINED                   AS CorrectedDocument,
	|	DocumentData.Date           AS RecordingInAccountingDate,
	|	UNDEFINED                   AS Priority
	|
	|FROM
	|	Document.IntangibleAssetImprovement AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Ref           AS Ref,
	|	TableOfIA.IntangibleAsset   AS IntangibleAsset,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Department    AS Department,
	|	DocumentData.Date             AS Date,
	|	&MetadataIdentifier         AS RefType,
	|	DocumentData.Posted         AS Posted,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInTA      AS RecordInTA
	|
	|FROM
	|	Document.IntangibleAssetImprovement AS DocumentData
	|
	|		LEFT JOIN Document.IntangibleAssetImprovement.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                                      AS Recorder,
	|	DocumentData.Period                                      AS Period,
	|	DocumentData.Organization                                 AS Organization,
	|	InitialInformation.IntangibleAsset                  AS IntangibleAsset,
	|	InitialInformation.ReceiptMethod                    AS ReceiptMethod,
	|	InitialInformation.InitialCostMA            AS InitialCostMA,
	|	InitialInformation.InitialCostLocalAccounting            AS InitialCostLocalAccounting,
	|	InitialInformation.DepreciationMethodAccounting         AS DepreciationMethodAccounting,
	|	InitialInformation.PurchaseDate                     AS PurchaseDate,
	|	InitialInformation.DateOfRecognitionManagementAccounting                 AS DateOfRecognitionManagementAccounting,
	|	InitialInformation.DateOfRecognitionAccounting                 AS DateOfRecognitionAccounting,
	|	InitialInformation.DocumentOfRecognitionManagementAccounting             AS DocumentOfRecognitionManagementAccounting,
	|	InitialInformation.DocumentOfRecognitionAccounting             AS DocumentOfRecognitionAccounting,
	|	InitialInformation.DocumentWriteOffs                     AS DocumentWriteOffs
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTInitialInformationOfIA AS InitialInformation
	|		ON DocumentData.Ref = InitialInformation.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	TableOfIA.IntangibleAsset              AS IntangibleAsset,
	|	DocumentData.Organization                 AS Organization,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	TTIAAccountingParameters.EstimatedRunningTime          AS EstimatedRunningTime,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForNmabu(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	DocumentData.Period                               AS Period,
	|	DocumentData.Organization                          AS Organization,
	|	TableOfIA.IntangibleAsset                       AS IntangibleAsset,
	|	AccountingProcedure.BUState                             AS BUState,
	|	AccountingProcedure.StateTa                             AS StateTa,
	|	AccountingProcedure.DepreciationAccrualAccounting                  AS DepreciationAccrualAccounting,
	|	AccountingProcedure.DepreciationAccrualTaxAccounting                  AS DepreciationAccrualTaxAccounting,
	|	AccountingProcedure.ExpenseItemAccounting                        AS ExpenseItemAccounting,
	|	AccountingProcedure.ExpensesDimensionAccounting                     AS ExpensesDimensionAccounting,
	|	AccountingProcedure.ExpenseItemTaxAccounting                        AS ExpenseItemTaxAccounting,
	|	AccountingProcedure.ExpensesDimensionTaxAccounting                     AS ExpensesDimensionTaxAccounting,
	|	AccountingProcedure.DepreciationRecordMethodLA            AS DepreciationRecordMethodLA,
	|	AccountingProcedure.DepreciationRecordMethodTA            AS DepreciationRecordMethodTA,
	|	AccountingProcedure.TransferExpensesToAnotherCompany     AS TransferExpensesToAnotherCompany,
	|	AccountingProcedure.CompanyRecipientOfExpenses           AS CompanyRecipientOfExpenses,
	|	AccountingProcedure.VATTaxation                      AS VATTaxation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForNmabu AS AccountingProcedure
	|		ON AccountingProcedure.Ref = TableOfIA.Ref
	|			AND AccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForNMAU(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                               AS Recorder,
	|	DocumentData.Period                               AS Period,
	|	DocumentData.Organization                          AS Organization,
	|	TableOfIA.IntangibleAsset                       AS IntangibleAsset,
	|	AccountingProcedure.State                               AS State,
	|	AccountingProcedure.AccrueDepreciationOrAmortization                    AS AccrueDepreciationOrAmortization,
	|	AccountingProcedure.ExpenseItem                          AS ExpenseItem,
	|	AccountingProcedure.DimensionOfExpenses                       AS DimensionOfExpenses,
	|	AccountingProcedure.DepreciationRecordMethod              AS DepreciationRecordMethod,
	|	AccountingProcedure.TransferExpensesToAnotherCompany     AS TransferExpensesToAnotherCompany,
	|	AccountingProcedure.CompanyRecipientOfExpenses           AS CompanyRecipientOfExpenses
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForNMAU AS AccountingProcedure
	|		ON AccountingProcedure.Ref = TableOfIA.Ref
	|			AND AccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetAmortizationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTNmauuDepreciationParameters(QueryTexts);
	QueryTextTableTTIntangibleAssetsOperatingTime(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref         AS Recorder,
	|	DocumentData.Period         AS Period,
	|	DocumentData.Organization    AS Organization,
	|	DocumentData.Period         AS LastChangeDate,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|
	|	IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeMonths,
	|	IntangibleAssetAmortizationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan     AS ResidualValueMan,
	|	IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueLocal AS ResidualValueLocal,
	|
	// UsefulLifeForCalculatingDepreciationMonth
	|	IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	IntangibleAssetAmortizationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|		- ISNULL(IntangibleAssetsOperatingTime.NumberMA, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		LEFT JOIN TTNmauuDepreciationParameters AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON IntangibleAssetAmortizationParametersManagementAccounting.Ref = TableOfIA.Ref
	|			AND IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTIntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON IntangibleAssetsOperatingTime.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsOperatingTime.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "IADepreciationParametersBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersNMABU(QueryTexts);
	QueryTextTableTTIntangibleAssetsOperatingTime(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref          AS Recorder,
	|	DocumentData.Period          AS Period,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.Period          AS LastChangeDate,
	|	TableOfIA.IntangibleAsset  AS IntangibleAsset,
	|
	|	IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeMonthsTA AS UsefulLifeMonthsTA,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.DepreciationAccrualFactor AS DepreciationAccrualFactor,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.ResidualValueMan AS ResidualValueMan,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.SpecialFactor AS SpecialFactor,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|				AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement)
	|
	|			THEN IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeForCalculatingDepreciationMonth
	|					- DATEDIFF(ISNULL(IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH)
	|
	|		ELSE IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeForCalculatingDepreciationMonth
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|				AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement)
	|
	|			THEN IADepreciationParametersBookkeepingAndTaxAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|					- ISNULL(TTIntangibleAssetsOperatingTime.NumberOfBU, 0)
	|
	|		ELSE IADepreciationParametersBookkeepingAndTaxAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		LEFT JOIN WDepreciationParametersNMABU AS IADepreciationParametersBookkeepingAndTaxAccounting
	|		ON IADepreciationParametersBookkeepingAndTaxAccounting.Ref = TableOfIA.Ref
	|			AND IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTIntangibleAssetsOperatingTime AS TTIntangibleAssetsOperatingTime
	|		ON TTIntangibleAssetsOperatingTime.Ref = TableOfIA.Ref
	|			AND TTIntangibleAssetsOperatingTime.IntangibleAsset = TableOfIA.IntangibleAsset
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableIACost(Query, QueryTexts, Registers)

	RegisterName = "IACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts);
	NonCurrentAssetsLocalization.QueryTextTableTTTaxationIA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTTaxSystemSettings(QueryTexts);
	
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	IntangibleAssetsAccountingProcedure.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	&DimensionKindExpenseCapitalization       AS DimensionKindExpenseCapitalization,
	|	&TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	TableOfIA.IntangibleAsset           AS IntangibleAsset,
	|	TableOfIA.IntangibleAsset           AS ExpensesCapitalizationDimension,
	|
	|	ISNULL(TTCostCalculation.Department, UNDEFINED)                AS DebitBusinessUnit,
	|	ISNULL(TTCostCalculation.LineOfBusiness, UNDEFINED)      AS CorLineOfBusiness,
	|	ISNULL(TTCostCalculation.ExpenseItem, UNDEFINED)               AS CorExpenseItem,
	|	ISNULL(TTCostCalculation.DimensionOfExpenses, UNDEFINED)            AS CorExpenditureDimension,
	|	TTVATTaxation.VATTaxation                                AS VATTaxation,
	|	NOT TTCostCalculation.AccountingObject IS NULL                             AS CostCalculation,
	|
	|	ISNULL(TTCostCalculation.AmountOfUU, TableOfIA.CostInManagementAccounting)            AS Cost,
	|
	|	ISNULL(TTCostCalculation.AmountAccounting, TableOfIA.CostInAccounting)            AS LocalCost,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountFA, TableOfIA.CostInTaxAccounting) - &AdjustingCostOfINV
	|	END AS CostInTaxAccounting,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences, TableOfIA.CostPermanentDifference) + &AdjustingCostOfINV
	|	END AS CostPermanentDifference,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountAccounting, TableOfIA.CostInAccounting)
	|	 		- ISNULL(TTCostCalculation.AmountFA, TableOfIA.CostInTaxAccounting)
	|	 		- ISNULL(TTCostCalculation.AmountPermanentDifferences, TableOfIA.CostPermanentDifference)
	|	END AS CostTemporaryDifference,
	|
	
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences, 0)
	|	END AS CorAmountPD,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE ISNULL(TTCostCalculation.AmountAccounting - TTCostCalculation.AmountFA - TTCostCalculation.AmountPermanentDifferences, 0)
	|	END AS CorAmountTD,
	|	
	|	ISNULL(TTCostCalculation.RowID, &IDOfUnusedFinRecord) AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		LEFT JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = TableOfIA.Ref
	|			AND TTCostCalculation.AccountingObject = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTAccountingProcedureForIA AS IntangibleAssetsAccountingProcedure
	|		ON IntangibleAssetsAccountingProcedure.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = TableOfIA.Ref
	|			AND TTVATTaxation.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTTaxSystemSettings AS TTTaxSystemSettings
	|		ON TTTaxSystemSettings.Ref = DocumentData.Ref
	|
	|
	|UNION ALL
	|
	// You need to write down the preliminary cost separately to calculate depreciation
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	IntangibleAssetsAccountingProcedure.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	&DimensionKindExpenseCapitalization       AS DimensionKindExpenseCapitalization,
	|	&TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	TableOfIA.IntangibleAsset           AS IntangibleAsset,
	|	TableOfIA.IntangibleAsset           AS ExpensesCapitalizationDimension,
	|	UNDEFINED                             AS DebitBusinessUnit,
	|	UNDEFINED                             AS CorLineOfBusiness,
	|	UNDEFINED                             AS CorExpenseItem,
	|	UNDEFINED                             AS CorExpenditureDimension,
	|	TTVATTaxation.VATTaxation  AS VATTaxation,
	|	FALSE                                     AS CostCalculation,
	|	0                                        AS Cost,
	|	0                                        AS LocalCost,
	|	0                                        AS CostInTaxAccounting,
	|	0                                        AS CostPermanentDifference,
	|	0                                        AS CostTemporaryDifference,
	|	TableOfIA.CostInManagementAccounting                   AS PreliminaryCostMan,
	|	TableOfIA.CostInAccounting                   AS PreliminaryCostLocal,
	|	0                                        AS CorAmountPD,
	|	0                                        AS CorAmountTD,
	|	
	|	&IDOfUnusedFinRecord    AS FinRecordID,
	|	UNDEFINED                             AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForIA AS IntangibleAssetsAccountingProcedure
	|		ON IntangibleAssetsAccountingProcedure.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = TableOfIA.Ref
	|			AND (TTVATTaxation.IntangibleAsset = TableOfIA.IntangibleAsset)
	|
	|WHERE
	|	(TableOfIA.CostInManagementAccounting <> 0
	|		OR TableOfIA.CostInAccounting <> 0)
	|";
	
	ReplaceTextOfCostAdjustmentINV(QueryText);

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)

	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Add_Fields = "Recorder";

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
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
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
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness      AS CorLineOfBusiness,
	|	&APArticle                                    AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTCostCalculation.AccountingObject                AS CorDimensionOfAssetsLiabilities,
	|	IntangibleAssetsAccountingProcedure.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	TTCostCalculation.Sum                      AS Sum,
	|
	|	TTCostCalculation.AmountAccounting 
	|		+ TTCostCalculation.CFAmount              AS SumCompl,
	|
	|	TTCostCalculation.AmountOfUU                    AS SumMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForIA AS IntangibleAssetsAccountingProcedure
	|		ON IntangibleAssetsAccountingProcedure.Ref = TTCostCalculation.Ref
	|			AND IntangibleAssetsAccountingProcedure.IntangibleAsset = TTCostCalculation.AccountingObject
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
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
	
	NonCurrentAssetsInternal.QueryTextTableTTTaxSystemSettings(QueryTexts);

	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
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
	|	TTCostCalculation.Sum                      AS AmountIncludingVAT,
	|	TTCostCalculation.AmountExcludingVAT                AS AmountExcludingVAT,
	|	TTCostCalculation.AmountOfUU                    AS AmountExcludingVATMan,
	|
	|	TTCostCalculation.AmountAccounting                    AS AmountIncludingVATCompl,
	|	TTCostCalculation.AmountAccounting                    AS AmountExcludingVATCompl,
	|	
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountPermanentDifferences
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting
	|	 			- TTCostCalculation.AmountFA
	|	 			- TTCostCalculation.AmountPermanentDifferences
	|	END AS CostTD,
	|	
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	UNDEFINED                                 AS ItemsLocationAttributes,
	|	TTCostCalculation.RowID        AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref AS Recorder
	|	
	|INTO TTInitialOtherExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTTaxSystemSettings AS TTTaxSystemSettings
	|		ON TTTaxSystemSettings.Ref = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTIntangibleAssetsOperatingTime(QueryTexts)
	
	TableName = "TTIntangibleAssetsOperatingTime";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|
	|	CASE
	|		WHEN AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|			THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(DocumentData.Period, MONTH), DAY, -1), MONTH)
	|		ELSE ENDOFPERIOD(DocumentData.Period, MONTH)
	|	END AS Period
	|
	|INTO TTListOfIa_DevelopmentOfUU
	|
	|FROM
	|	DocumentDataIATable AS TableOfIA
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TableOfIA.Ref
	|	
	|		INNER JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Ref = TableOfIA.Ref
	|
	|INDEX BY
	|	Period,
	|	IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, "TTListOfIa_DevelopmentOfUU", False);

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|
	|	CASE
	|		WHEN AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|			THEN ENDOFPERIOD(DATEADD(BEGINOFPERIOD(DocumentData.Period, MONTH), DAY, -1), MONTH)
	|		ELSE ENDOFPERIOD(DocumentData.Period, MONTH)
	|	END AS Period
	|
	|INTO TTListIA_ACProduction
	|
	|FROM
	|	DocumentDataIATable AS TableOfIA
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TableOfIA.Ref
	|	
	|		INNER JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
	|		ON AccountingPolicy.Ref = TableOfIA.Ref
	|
	|INDEX BY
	|	Period,
	|	IntangibleAsset
	|";
	
	
	QueryTexts.Add(QueryText, "TTListIA_ACProduction", False);
	
	QueryText = 
	"SELECT
	|	IntangibleAssetsOperatingTime.Ref AS Ref,
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|	SUM(IntangibleAssetsOperatingTime.NumberMA) AS NumberMA,
	|	SUM(IntangibleAssetsOperatingTime.NumberOfBU) AS NumberOfBU
	|
	|INTO TTIntangibleAssetsOperatingTime
	|
	|FROM
	|	(SELECT
	|		TTListOfIa.Ref AS Ref,
	|		IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|		IntangibleAssetsOperatingTime.Count AS NumberMA,
	|		0 NumberOfBU
	|	FROM
	|		TTListOfIa_DevelopmentOfUU AS TTListOfIa
	|		
	|			INNER JOIN AccumulationRegister.IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|			ON IntangibleAssetsOperatingTime.IntangibleAsset = TTListOfIa.IntangibleAsset
	|				AND IntangibleAssetsOperatingTime.Period <= TTListOfIa.Period
	|				AND IntangibleAssetsOperatingTime.Active
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTListOfIa.Ref AS Ref,
	|		IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|		0 AS NumberMA,
	|		IntangibleAssetsOperatingTime.Count AS NumberOfBU
	|
	|	FROM
	|		TTListIA_ACProduction AS TTListOfIa
	|	
	|			INNER JOIN AccumulationRegister.IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|			ON IntangibleAssetsOperatingTime.IntangibleAsset = TTListOfIa.IntangibleAsset
	|				AND IntangibleAssetsOperatingTime.Period <= TTListOfIa.Period
	|				AND IntangibleAssetsOperatingTime.Active
	|
	|	) AS IntangibleAssetsOperatingTime
	|
	|GROUP BY
	|	IntangibleAssetsOperatingTime.Ref,
	|	IntangibleAssetsOperatingTime.IntangibleAsset
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure ReplaceTextOfCostAdjustmentINV(QueryText)
	
	ReplacementText = "0";
	
	
	QueryText = StrReplace(QueryText, "&AdjustingCostOfINV", ReplacementText);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return IntangibleAssetImprovementLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return IntangibleAssetImprovementLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	

EndProcedure

#EndRegion

#Region Other

// 
// Parameters:
//  Organization - CatalogRef.Companies - 
//  Date - Date - 
// 
// Returns:
//  Map of KeyAndValue - Contains:
//		* Key - String -
//		* Value - String -
Function PresentationOfDetails(Organization, Date) Export

	PresentationOfDetails = New Map;

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	CurrencyOfManPresentation = String(CurrencyOfMan);
	ComplCurrencyPresentation = String(ComplCurrency);
	
	FALocalAccountingIsConductedIndependently = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
		Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())));
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
		NStr("vi = 'Số tiền';
			|ru = 'Сумма';
			|en = 'Amount'; fa = 'مبلغ';
			|it = 'Amount';
			|pl = 'Amount';
			|tr = 'Tutar'"), 
		NStr("vi = 'Số tiền (KTDN)';
			|ru = 'Сумма (БУ)';
			|en = 'Amount (LA)'; fa = 'مبلغ (محلی)';
			|it = 'Importo (Contabilità)';
			|pl = 'Wartość (EK)';
			|tr = 'Tutar (AC)'"), 
		FALocalAccountingIsConductedIndependently, 
		ComplCurrency = CurrencyOfMan,
		ComplCurrencyPresentation);
	
	PresentationOfDetails.Insert("IA.CostInAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
		NStr("vi = 'Số tiền';
			|ru = 'Сумма';
			|en = 'Amount'; fa = 'مبلغ';
			|it = 'Amount';
			|pl = 'Amount';
			|tr = 'Tutar'"), 
		NStr("vi = 'Số tiền (KTQT)';
			|ru = 'Сумма (УУ)';
			|en = 'Amount (MA)'; fa = 'مبلغ (مدیریت)';
			|it = 'Amount (MA)';
			|pl = 'Amount (MA)';
			|tr = 'Tutar (YM)'"), 
		FALocalAccountingIsConductedIndependently, 
		ComplCurrency = CurrencyOfMan,
		CurrencyOfManPresentation);
		
	PresentationOfDetails.Insert("IA.CostInManagementAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (KTTh)';
																			|ru = 'Сумма (НУ)';
																			|en = 'TA amount'; fa = 'مبلغ حسابداری مالیاتی';
																			|it = 'Importo (Registro Fiscale)';
																			|pl = 'Wartość (EP)';
																			|tr = 'Tutar (VM)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("IA.CostInTaxAccounting", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLVV)';
																			|ru = 'Сумма (ПР)';
																			|en = 'Amount (PD)'; fa = 'مبلغ (تفاوت دائم)';
																			|it = 'Importo (differenza costante)';
																			|pl = 'Wartość (różnica trwała)';
																			|tr = 'Tutar (Kalıcı fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("IA.CostPermanentDifference", FieldPresentation);

	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLTT)';
																			|ru = 'Сумма (ВР)';
																			|en = 'Amount (TD)'; fa = 'مبلغ (تفاوت موقت)';
																			|it = 'Importo (differenza temporanea)';
																			|pl = 'Wartość (różnica przejściowa)';
																			|tr = 'Tutar (Geçici fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("IA.CostTemporaryDifference", FieldPresentation);
	
	Return PresentationOfDetails;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetImprovement - 
//  RowsSelected - TabularSection - 
Procedure FillInCostAmount(Object, RowsSelected = Undefined) Export

	If Not CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Object.Date) Then
		Return;
	EndIf; 
	
	DocumentDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	TableOfIA = Object.IA.Unload(RowsSelected);

	TempTablesManager = New TempTablesManager;
	
	QueryText = 
	"SELECT
	|	TableOfIA.LineNumber AS LineNumber,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	TableOfIA.CostInManagementAccounting AS CostInManagementAccounting,
	|	TableOfIA.CostInAccounting AS CostInAccounting,
	|	TableOfIA.RowID AS RowID
	|
	|INTO TableOfIA
	|
	|FROM
	|	&TableOfIA AS TableOfIA
	|
	|WHERE
	|	TableOfIA.IntangibleAsset <> VALUE(Catalog.Assets.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	TableOfIA.IntangibleAsset AS AccountingObject,
	|	1 AS Priority
	|
	|INTO TTPortionOfDataToBeCalculated
	|
	|FROM
	|	TableOfIA AS TableOfIA
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	TableOfIA.LineNumber AS LineNumber,
	|	TableOfIA.IntangibleAsset AS AccountingObject,
	|
	|	&CostGenerationProcedure AS CostGenerationProcedure,
	|
	|	FALSE AS ExpensesAreDistributedByObjects,
	|
	|	TableOfIA.IntangibleAsset AS ExpensesCapitalizationDimension,
	|
	|	FALSE AS ActualCost,
	|	FALSE AS AttributingDeviationsToCost,
	|	DATETIME(1,1,1) AS SourceDocumentDate,
	|
	|	TableOfIA.CostInManagementAccounting AS AmountOfUU,
	|	TableOfIA.CostInAccounting AS AmountAccounting,
	|	0 AS AmountFA,
	|
	|	&TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	0 AS AmountOfTargetFunds,
	|
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	&PostInAccounting AS PostInAccounting,
	|	&RecordInTA AS RecordInTA,
	|	&PostInAccounting AS TakeIntoAccountPD,
	|
	|	TableOfIA.RowID AS RowID
	|
	|INTO TTTableOfObjects
	|
	|FROM
	|	TableOfIA AS TableOfIA
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", DocumentDate);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("DimensionKindExpenseCapitalization", Enums.KindsOfExpenseCapitalizationDimension.IntangibleAssetsAndRD);
	Query.SetParameter("ConstructionObject", Undefined);
	Query.SetParameter("PartialCommissioning", False);
	Query.SetParameter("AccountingProcedureMA", Undefined);
	Query.SetParameter("AccountingProcedureAC", Undefined);
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	Query.SetParameter("CostGenerationProcedure", Object.CostGenerationProcedure);
	Query.SetParameter("TargetFinancingApplicationOption", Undefined);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInTA", Object.RecordInTA);
	Query.SetParameter("TableOfIA", TableOfIA);
	
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
		StringsList = Object.IA;
	EndIf; 
	
	For Each RowData In StringsList Do
		
		RowData.CostInManagementAccounting = 0;
		RowData.CostInAccounting = 0;
		RowData.CostInTaxAccounting = 0;
		RowData.CostPermanentDifference = 0;

		TheStructureOfTheSearch = New Structure("AccountingObject", RowData.IntangibleAsset);
		ListOfExpenseLines = DocumentExpenses.FindRows(TheStructureOfTheSearch);
		If ListOfExpenseLines.Count() = 0 Then
			Continue
		EndIf;
		
		If Object.RecordInManAccounting Then
			RowData.CostInManagementAccounting = ListOfExpenseLines[0].SumMan;
		EndIf;
		
		If Object.PostInAccounting Then
			RowData.CostInAccounting = ListOfExpenseLines[0].SumCompl;
			RowData.CostPermanentDifference = ListOfExpenseLines[0].AmountPermanentDifferences;
		EndIf; 
		
		If Object.RecordInTA Then
			RowData.CostInTaxAccounting = ListOfExpenseLines[0].AmountFA;
		EndIf; 
		
	EndDo;
	
EndProcedure

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

#EndRegion

#Region InfobaseUpdate

// Adds procedures to the list that handle updating information security
// data for all supported library versions or configurations.
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.IntangibleAssetImprovement.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("cf2fe4bc-9d7d-4088-bcba-e4ebe8234d4a");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.IntangibleAssetImprovement.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Nâng cấp TSCĐVH"":
								  |- Điền mục tin ""Giao dịch"", ""Phương thức hình thành giá trị""';
								  |ru = 'Обновляет документы ""Улучшение НМА"":
								  |- Заполняет реквизиты ""Операция"", ""Порядок формирования стоимости""';
								  |en = 'Updates the ""Intangible asset improvement"" documents:
								  |- Fills in the ""Transaction"" and ""Сost generation procedure"" attributes.'; fa = 'Updates the ""Intangible asset improvement"" documents:
								  |- Fills in the ""Transaction"" and ""Сost generation procedure"" attributes.';
								  |it = 'Updates the ""Intangible asset improvement"" documents:
								  |- Fills in the ""Transaction"" and ""Сost generation procedure"" attributes.';
								  |pl = 'Updates the ""Intangible asset improvement"" documents:
								  |- Fills in the ""Transaction"" and ""Сost generation procedure"" attributes.';
								  |tr = '""Maddi Olmayan Varlık İyileştirme"" belgelerini günceller:
								  | - ""İşlem"", ""Maliyet oluşturma düzeni"" özniteliklerini doldurur'");
	
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetImprovement.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.IntangibleAssetImprovement.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.IntangibleAssetImprovement.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.IntangibleAssetImprovement";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentsList.Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref
	|	FROM
	|		Document.IntangibleAssetImprovement AS DocumentData
	|
	|	WHERE
	|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|			OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.EmptyRef)
	|
	|	) AS DocumentsList
	|";
	Query = New Query(QueryText);
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());

	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.IntangibleAssetImprovement.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.IntangibleAssetImprovement";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.IntangibleAssetImprovement
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.BusinessOperation) Then
				DocumentObject.BusinessOperation = Enums.BusinessTransactions.IntangibleAssetImprovement;
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
