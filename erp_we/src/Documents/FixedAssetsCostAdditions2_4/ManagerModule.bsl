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
	
	FixedAssetsCostAdditionsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.FixedAssetsCostAdditions2_4") Then
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
		
		NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts,, "RenovationDate");
		
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		FixedAssetsCostAdditionsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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
	
	NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts,, "RenovationDate");
	
	QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	FixedAssetsCostAdditionsLocalization.TablesOfDeferredMotionFormation(Query, QueryTexts);

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

	NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts,, "RenovationDate");
	
	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Undefined);
	QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	FixedAssetsCostAdditionsLocalization.TablesForCalculatingCost(Query, QueryTexts);

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
	
	Documents.AllocateVariancesToFixedAssetCost.AddGenerateCommand(GenerationCommands);
	Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);

	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	FixedAssetsCostAdditionsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the "OS Upgrade" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.FixedAssetsCostAdditions2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.FixedAssetsCostAdditions2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.FixedAssetsCostAdditions2_4);
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
	
	FixedAssetsCostAdditionsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	FixedAssetsCostAdditionsLocalization.AddReportCommands(ReportsCommands, Parameters);

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
	
	FixedAssetsCostAdditionsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

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
	
	FullDocumentName = "Document.FixedAssetsCostAdditions2_4";
	
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
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentsList
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
	|	DocumentData.FixedAssetCostAdditionsPartial AS FixedAssetCostAdditionsPartial,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	DocumentData.AdjustmentModeFromPreviousDate AS AdjustmentModeFromPreviousDate,
	|	DocumentData.RenovationDate AS RenovationDate,
	|	DocumentData.WriteOffAppreciationCosts AS WriteOffAppreciationCosts,
	|	DocumentData.ExpenseItemWriteOffCosts AS ExpenseItemWriteOffCosts,
	|	DocumentData.ExpenseDimensionWriteOffCosts AS ExpenseDimensionWriteOffCosts,
	|	DocumentData.BusinessUnitWriteOffCosts AS BusinessUnitWriteOffCosts,
	|	DocumentData.LineOfBusinessWriteOffCosts AS LineOfBusinessWriteOffCosts,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts AS BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN DocumentData.WriteOffAppreciationCosts
	|				AND DocumentData.PostInAccounting
	|			THEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|		ELSE UNDEFINED 
	|	END AS AccountingProcedureAC,
	|
	|	CASE
	|		WHEN DocumentData.WriteOffAppreciationCosts
	|				AND DocumentData.RecordInTA
	|			THEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|		ELSE DocumentData.AccountingProcedureTA 
	|	END AS AccountingProcedureTA,
	|
	|	CASE
	|		WHEN DocumentData.WriteOffAppreciationCosts
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
	|	,&UpgradeOS_DocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = DocumentData.BusinessOperation
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
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|	DocumentTable.CostInTaxAccounting AS CostInTaxAccounting,
	|	DocumentTable.CostPermanentDifference AS CostPermanentDifference,
	|
	|	DocumentTable.AmountOfBonusDepreciationTaxAccounting AS AmountOfBonusDepreciationTaxAccounting,
	|	DocumentTable.BonusDepreciationPercentage AS BonusDepreciationPercentage,
	|	DocumentTable.AmountOfTargetFunds AS AmountOfTargetFunds
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4.FA AS DocumentTable
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
	
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FixedAssetsCostAdditions2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Nâng cấp TSCĐ';
															|ru = 'Модернизация ОС';
															|en = 'Fixed assets appreciation'; fa = 'افزایش ارزش دارایی‌های ثابت';
															|it = 'Ammodernamento del patrimonio aziendale di capitale fisso';
															|pl = 'Modernizacja środków trwałych';
															|tr = 'SV modernizasyonu'"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Nâng cấp TSCĐ';
															|ru = 'Модернизация ОС';
															|en = 'Fixed assets appreciation'; fa = 'افزایش ارزش دارایی‌های ثابت';
															|it = 'Ammodernamento del patrimonio aziendale di capitale fisso';
															|pl = 'Modernizacja środków trwałych';
															|tr = 'SV modernizasyonu'"));
	ValuesOfHoldingParameters.Insert("UseCostAccounting", GetFunctionalOption("UseCostAccounting"));
	ValuesOfHoldingParameters.Insert("CostAccountingStartDate", Constants.CostAccountingStartDate.Get());
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
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
	|	DocumentData.BusinessOperation   AS BusinessOperation,
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
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
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
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.PostInAccounting             AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInTA             AS RecordInTA,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	FATable.FixedAsset              AS FixedAsset,
	|	DocumentData.AdjustmentModeFromPreviousDate AS IsPatch,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN DocumentData.RenovationDate
	|		ELSE DATETIME(1,1,1)
	|	END AS CorrectionPeriodStart,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DocumentData.Date, MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CorrectionPeriodEnd
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	InitialFixedAssetsInformation.ReceiptMethod AS ReceiptMethod,
	|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
	|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
	|
	|	
	|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	InitialFixedAssetsInformation.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting,
	|	InitialFixedAssetsInformation.CostBefore2002 AS CostBefore2002,
	|	InitialFixedAssetsInformation.DepreciationBefore2002 AS DepreciationBefore2002,
	|	InitialFixedAssetsInformation.DepreciationBefore2009 AS DepreciationBefore2009,
	|	InitialFixedAssetsInformation.ActualUsefulLifeBefore2009 AS ActualUsefulLifeBefore2009,
	|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|
	|
	|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
	|	InitialFixedAssetsInformation.Counterparty AS Counterparty,
	|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
	|	InitialFixedAssetsInformation.CommissioningDateTA AS CommissioningDateTA,
	|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
	|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
	|	InitialFixedAssetsInformation.CommissioningDocumentTA AS CommissioningDocumentTA,
	|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
	|	InitialFixedAssetsInformation.DeregistrationDocumentACC AS DeregistrationDocumentACC,
	|	InitialFixedAssetsInformation.DeregistrationDocumentTA AS DeregistrationDocumentTA,
	|	InitialFixedAssetsInformation.DeregistrationDocumentMA AS DeregistrationDocumentMA
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
	|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
	|		ON CostCalculation.Ref = FATable.Ref
	|			AND CostCalculation.AccountingObject = FATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

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
	|	NOT DocumentData.WriteOffAppreciationCosts
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
	|	AND NOT DocumentData.WriteOffAppreciationCosts
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)
	
	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DATETIME(1,1,1)       AS CorrectionDate,
	|	AccountingProcedureForOSBU.FixedAsset AS FixedAsset,
	|	DocumentData.Organization AS Organization,
	|	AccountingProcedureForOSBU.BUState AS BUState,
	|	AccountingProcedureForOSBU.StateTa AS StateTa,
	|	AccountingProcedureForOSBU.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|
	|
	|	AccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|
	|
	|	AccountingProcedureForOSBU.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.DepartmentACC AS DepartmentACC,
	|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		INNER JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND NOT DocumentData.WriteOffAppreciationCosts
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	BEGINOFPERIOD(DocumentData.RenovationDate, DAY) AS Period,
	|	DocumentData.Period AS CorrectionDate,
	|	AccountingProcedureForOSBU.FixedAsset AS FixedAsset,
	|	DocumentData.Organization AS Organization,
	|	AccountingProcedureForOSBU.BUState AS BUState,
	|	AccountingProcedureForOSBU.StateTa AS StateTa,
	|	AccountingProcedureForOSBU.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|
	|
	|	AccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|
	|
	|	AccountingProcedureForOSBU.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.DepartmentACC AS DepartmentACC,
	|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		INNER JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|	AND NOT DocumentData.WriteOffAppreciationCosts
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	
	QueryTextTableTTAmountOfUpgrade(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(
		QueryTexts,, "TTParametersOfDepreciationOfOSUU_ForLastDate", New Structure("Period", "RenovationDate"), True);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
	|			THEN DocumentData.Period
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.LastChangeDate
	|	END AS LastChangeDate,
	|
	|	DATETIME(1,1,1)             AS CorrectionDate,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeMonths,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan     AS ResidualValueMan,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal AS ResidualValueLocal,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
	|			THEN ISNULL(TTAccountingFA.EstimatedRunningTime, 0)
	|					- ISNULL(AssetActivityRecords.Value, 0)
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// UsefulLifeForCalculatingDepreciationMonth
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
	|			THEN FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|					- DATEDIFF(ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH)
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// To calculate depreciation, the residual value + the amount of modernization is used
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
	|			THEN ISNULL(FACost.Cost, 0) 
	|					- ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|					+ ISNULL(AmountOfModernization.Cost, FATable.CostInManagementAccounting)
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationManag
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
	|			THEN ISNULL(FACost.LocalCost, 0) 
	|					- ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|					+ ISNULL(AmountOfModernization.LocalCost, FATable.CostInAccounting)
	|		ELSE FixedAssetDepreciationParametersManagementAccounting.CostUsedToCalculateDepreciationLocal
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAmountOfUpgrade AS AmountOfModernization
	|		ON AmountOfModernization.Ref = FATable.Ref
	|			AND AmountOfModernization.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.Ref = FATable.Ref
	|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|		ON AssetActivityRecords.Ref = FATable.Ref
	|			AND AssetActivityRecords.Asset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND NOT DocumentData.WriteOffAppreciationCosts
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref       AS Recorder,
	|	BEGINOFPERIOD(DocumentData.RenovationDate, DAY) AS Period,
	|	DocumentData.Organization  AS Organization,
	|	DocumentData.RenovationDate AS LastChangeDate,
	|	DocumentData.Period       AS CorrectionDate,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeMonths,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan     AS ResidualValueMan,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal AS ResidualValueLocal,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	ISNULL(TTAccountingFA.EstimatedRunningTime, 0)
	|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// UsefulLifeForCalculatingDepreciationMonth
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DocumentData.RenovationDate), DocumentData.RenovationDate, MONTH) AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// To calculate depreciation, the residual value + the amount of modernization is used
	|	ISNULL(FACost.Cost, 0) 
	|		- ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|		+ ISNULL(AmountOfModernization.Cost, FATable.CostInManagementAccounting) AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	ISNULL(FACost.LocalCost, 0) 
	|		- ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|		+ ISNULL(AmountOfModernization.LocalCost, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTAmountOfUpgrade AS AmountOfModernization
	|		ON AmountOfModernization.Ref = FATable.Ref
	|			AND AmountOfModernization.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.Ref = FATable.Ref
	|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|		ON AssetActivityRecords.Ref = FATable.Ref
	|			AND AssetActivityRecords.Asset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND NOT DocumentData.WriteOffAppreciationCosts
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTAmountOfUpgrade(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts);
	QueryTextTableTTParametersOfDepreciationOfOSBU_AsOfPreviousDate(QueryTexts);

	QueryText = FixedAssetsCostAdditionsLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref       AS Recorder,
		|	DocumentData.Period       AS Period,
		|	DATETIME(1,1,1)             AS CorrectionDate,
		|	DocumentData.Organization  AS Organization,
		|
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
		|			THEN DocumentData.Period
		|		ELSE OSBUDepreciationParameters.LastChangeDate
		|	END AS LastChangeDate,
		|
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	OSBUDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
		|	OSBUDepreciationParameters.AnnualDepreciationRate     AS AnnualDepreciationRate,
		|	OSBUDepreciationParameters.ResidualValueMan      AS ResidualValueMan,
		|
		// To calculate depreciation, the residual value + the amount of modernization is used
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
		|			THEN ISNULL(FACost.LocalCost, 0) 
		|					+ ISNULL(FACost.CostTargetFinancing, 0)
		|					- ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
		|					- ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
		|					+ ISNULL(AmountOfModernization.LocalCost, FATable.CostInAccounting)
		|		ELSE OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag
		|	END AS CostUsedToCalculateDepreciationManag,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
		|			THEN ISNULL(TTAccountingFA.EstimatedRunningTime, 0)
		|					- ISNULL(AssetActivityRecords.Value, 0)
		|		ELSE OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		// UsefulLifeForCalculatingDepreciationMonth
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
		|			THEN OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|					- DATEDIFF(ISNULL(OSBUDepreciationParameters.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH)
		|		ELSE OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|	END AS UsefulLifeForCalculatingDepreciationMonth
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTAmountOfUpgrade AS AmountOfModernization
		|		ON AmountOfModernization.Ref = FATable.Ref
		|			AND AmountOfModernization.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TT_CostOfVNA AS FACost
		|		ON FACost.Ref = FATable.Ref
		|			AND FACost.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
		|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
		|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA AS TTAccountingFA
		|		ON TTAccountingFA.Ref = FATable.Ref
		|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
		|		ON AssetActivityRecords.Ref = FATable.Ref
		|			AND AssetActivityRecords.Asset = FATable.FixedAsset
		|
		|WHERE
		|	DocumentData.PostInAccounting
		|	AND NOT DocumentData.WriteOffAppreciationCosts
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref       AS Recorder,
		|	BEGINOFPERIOD(DocumentData.RenovationDate, DAY) AS Period,
		|	DocumentData.Period       AS CorrectionDate,
		|	DocumentData.Organization  AS Organization,
		|	DocumentData.RenovationDate AS LastChangeDate,
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	OSBUDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
		|	OSBUDepreciationParameters.AnnualDepreciationRate     AS AnnualDepreciationRate,
		|	OSBUDepreciationParameters.ResidualValueMan      AS ResidualValueMan,
		|
		// To calculate depreciation, the residual value + the amount of modernization is used
		|	ISNULL(FACost.LocalCost, 0) 
		|		+ ISNULL(FACost.CostTargetFinancing, 0)
		|		- ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
		|		- ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
		|		+ ISNULL(AmountOfModernization.LocalCost, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationManag,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	ISNULL(TTAccountingFA.EstimatedRunningTime, 0)
		|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		// UsefulLifeForCalculatingDepreciationMonth
		|	OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
		|		- DATEDIFF(ISNULL(OSBUDepreciationParameters.LastChangeDate, DocumentData.RenovationDate), DocumentData.RenovationDate, MONTH) AS UsefulLifeForCalculatingDepreciationMonth
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTAmountOfUpgrade AS AmountOfModernization
		|		ON AmountOfModernization.Ref = FATable.Ref
		|			AND AmountOfModernization.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TT_CostOfVNA AS FACost
		|		ON FACost.Ref = FATable.Ref
		|			AND FACost.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
		|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
		|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTParametersOfDepreciationOfOSBU_AsOfPreviousDate AS OSBUDepreciationParameters
		|		ON OSBUDepreciationParameters.Ref = FATable.Ref
		|			AND OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA AS TTAccountingFA
		|		ON TTAccountingFA.Ref = FATable.Ref
		|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
		|		ON AssetActivityRecords.Ref = FATable.Ref
		|			AND AssetActivityRecords.Asset = FATable.FixedAsset
		|
		|WHERE
		|	DocumentData.PostInAccounting
		|	AND NOT DocumentData.WriteOffAppreciationCosts
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAdditions)
		|	AND DocumentData.AdjustmentModeFromPreviousDate
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

	FixedAssetsCostAdditionsLocalization.AddRequestTextFACostTable(ListOfMergeRequests);
	
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
	|	DocumentData.BusinessOperation    AS BusinessOperation,
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
	|	ISNULL(TTCostCalculation.AmountOfUU, FATable.CostInManagementAccounting)             AS Cost,
	|
	|	ISNULL(TTCostCalculation.AmountAccounting, FATable.CostInAccounting)             AS LocalCost,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInTA
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|
	|			THEN 0
	|
	|		WHEN TTCostCalculation.AccountingObject IS NULL
	|				AND NOT DocumentData.FixedAssetCostAdditionsPartial
	|
	|			THEN FATable.CostInTaxAccounting - &AdjustingCostOfINV
	|
	|		ELSE ISNULL(TTCostCalculation.AmountFA + TTCostCalculation.SumOfNUCF, FATable.CostInTaxAccounting) - &AdjustingCostOfINV
	|	END AS CostInTaxAccounting,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|				OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|
	|			THEN 0
	|
	|		ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences - TTCostCalculation.CFAmount + TTCostCalculation.PRCFAmount, FATable.CostPermanentDifference) 
	|				+ &AdjustingCostOfINV 
	|	END AS CostPermanentDifference,
	|
	|	CASE
	|		WHEN NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|			THEN 0
	|		ELSE 
	|			CASE
	|				WHEN NOT DocumentData.PostInAccounting
	|					THEN 0
	|				ELSE ISNULL(TTCostCalculation.AmountAccounting, FATable.CostInAccounting)
	|			END
	|    			- CASE
	|					WHEN NOT DocumentData.RecordInTA
	|						THEN 0
	|					WHEN TTCostCalculation.AccountingObject IS NULL
	|						AND NOT DocumentData.FixedAssetCostAdditionsPartial
	|
	|						THEN FATable.CostInTaxAccounting - &AdjustingCostOfINV
	|
	|					ELSE ISNULL(TTCostCalculation.AmountFA + TTCostCalculation.SumOfNUCF, FATable.CostInTaxAccounting) - &AdjustingCostOfINV
	|				END
	|	 			- CASE
	|					WHEN NOT DocumentData.PostInAccounting
	|						THEN 0
	|					ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences - TTCostCalculation.CFAmount + TTCostCalculation.PRCFAmount, FATable.CostPermanentDifference) 
	|							+ &AdjustingCostOfINV 
	|				END 
	|	END AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	0                                                                      AS PreliminaryCostMan,
	|	0                                                                      AS PreliminaryCostLocal,
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
	|		ELSE
	|			CASE
	|				WHEN NOT DocumentData.PostInAccounting
	|						OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|					THEN 0
	|				ELSE ISNULL(TTCostCalculation.AmountAccounting, FATable.CostInAccounting - FATable.AmountOfTargetFunds)
	|			END
	|				- CASE 
	|					WHEN NOT DocumentData.RecordInTA
	|							OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DoNotTakeIntoAccountIncludeInExpenses)
	|							OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|						THEN 0
	|					ELSE ISNULL(TTCostCalculation.AmountFA, FATable.CostInAccounting)
	|				END
	|				- CASE
	|					WHEN NOT DocumentData.PostInAccounting
	|							OR NOT ISNULL(TTTaxSystemSettings.IncomeTaxPayer, FALSE)
	|						THEN 0
	|					ELSE ISNULL(TTCostCalculation.AmountPermanentDifferences, FATable.CostPermanentDifference)
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
	|
	|WHERE
	|	NOT DocumentData.WriteOffAppreciationCosts
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
	|	DocumentData.BusinessOperation    AS BusinessOperation,
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
	|
	|	FATable.CostInManagementAccounting                    AS PreliminaryCostMan,
	|	FATable.CostInAccounting                    AS PreliminaryCostLocal,
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
	|	NOT DocumentData.WriteOffAppreciationCosts
	|";
	
	ListOfMergeRequests.Add(QueryText);
	
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	ReplaceTextOfCostAdjustmentINV(QueryText);
	
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
	|	NOT DocumentData.WriteOffAppreciationCosts
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
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTCostCalculation.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTCostCalculation.AccountingObject
	|
	|WHERE
	|	DocumentData.WriteOffAppreciationCosts
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

Procedure QueryTextTableTTAmountOfUpgrade(QueryTexts) Export

	TableName = "TTAmountOfUpgrade";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FACost.Recorder AS Ref,
	|	FACost.FixedAsset AS FixedAsset,
	|
	|	SUM(FACost.LocalCost + FACost.CostTargetFinancing) AS LocalCost,
	|	SUM(FACost.CostPermanentDifference + FACost.CostTargetFinancingPD) AS CostPermanentDifference,
	|	SUM(FACost.CostTargetFinancing) AS CostTargetFinancing,
	|	SUM(FACost.Cost) AS Cost
	|
	|INTO TTAmountOfUpgrade
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

	FixedAssetsCostAdditionsLocalization.AddRequestTextTableTTInitialOtherExpenses(ListOfMergeRequests);
	
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
	|	DocumentData.WriteOffAppreciationCosts
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
	|	DocumentData.WriteOffAppreciationCosts
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
	|	DocumentData.WriteOffAppreciationCosts
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
	|	DocumentData.WriteOffAppreciationCosts
	|	AND DocumentData.PostInAccounting
	|";
	
	ListOfMergeRequests.Add(QueryText);
		
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTParametersOfDepreciationOfOSBU_AsOfPreviousDate(QueryTexts)
	
	QueryTextTableTTListOfOS_ForLastDate(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(
		QueryTexts, "TTListOfOS_ForLastDate", "TTParametersOfDepreciationOfOSBU_AsOfPreviousDate",, True);
	
EndProcedure

Procedure QueryTextTableTTListOfOS_ForLastDate(QueryTexts)
	
	TableName = "TTListOfOS_ForLastDate";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.RenovationDate AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset
	|
	|INTO TTListOfOS_ForLastDate
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|	
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.AdjustmentModeFromPreviousDate
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	Period
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure ReplaceTextOfCostAdjustmentINV(QueryText)
	
	ReplacementText = "0";
	
	
	QueryText = StrReplace(QueryText, "&AdjustingCostOfINV", ReplacementText);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return FixedAssetsCostAdditionsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return FixedAssetsCostAdditionsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region UpdatingRegisters

// Generates a table of register movements "Parameters of the mortisation of the OSB".
// Used in the register update handler.
// 
// Parameters:
//  Recorder - DocumentRef.FixedAssetsCostAdditions2_4 -
//  QueryTexts - ValueList -
// 
// Returns:
//  ValueTable - Register table
Function UpdateOSBUDepreciationParametersTable(Recorder, QueryTexts) Export
		
	Query = New Query;
	FillInInitializationParameters(Query, Recorder, Undefined);
	
	QueryTexts = New ValueList();
	
	// You need to create temporary tables that are used in the query.
	#Region TTAmountOfUpgrade
	TableName = "TTAmountOfUpgrade";
	If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		QueryText = 
		"SELECT
		|	SUM(RegisterData.CostUsedToCalculateDepreciationManag) AS LocalCost,
		|	SUM(RegisterData.PermanentDifferencesUsedToCalculateDepreciation) AS CostPermanentDifference,
		|	SUM(RegisterData.CostForDepreciationCalculationTargetFinancing) AS CostTargetFinancing,
		|	0 AS Cost,
		|	RegisterData.FixedAsset
		|INTO TTAmountOfUpgrade
		|FROM
		|	InformationRegister.OSBUDepreciationParameters AS RegisterData
		|WHERE
		|	RegisterData.Recorder = &Ref
		|
		|GROUP BY
		|	RegisterData.FixedAsset";
		QueryTexts.Add(QueryText, TableName);
	EndIf;
	#EndRegion
	
	#Region TT_CostOfVNA
	TableName = "TT_CostOfVNA";
	If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		QueryText = 
		"SELECT
		|	RegisterData.Recorder AS Ref,
		|	RegisterData.Period AS Date,
		|	RegisterData.Organization AS Organization,
		|	RegisterData.FixedAsset AS AccountingObject,
		|	0 AS Cost,
		|	SUM(RegisterData.CostUsedToCalculateDepreciationManag) AS LocalCost,
		|	0 AS CostInTaxAccounting,
		|	SUM(RegisterData.PermanentDifferencesUsedToCalculateDepreciation) AS CostPermanentDifference,
		|	0 AS CostTemporaryDifference,
		|	SUM(RegisterData.CostForDepreciationCalculationTargetFinancing) AS CostTargetFinancing,
		|	0 AS CostTargetFinancingTA,
		|	0 AS CostTargetFinancingPD,
		|	0 AS CostTargetFinancingTD,
		|	0 AS DepreciationAllowance,
		|	0 AS SecurityDepositValue,
		|	0 AS PreliminaryCostMan,
		|	0 AS PreliminaryCostLocal,
		|	0 AS CostRevaluationReserve,
		|	0 AS CostRevaluationReserveLocal,
		|	0 AS CostGainMA,
		|	0 AS CostGainLocal,
		|	0 AS ShareOfCentralBank,
		|	0 AS CFNUShare,
		|	"""" AS RowID
		|INTO TT_CostOfVNA
		|FROM
		|	InformationRegister.OSBUDepreciationParameters AS RegisterData
		|WHERE
		|	RegisterData.Recorder = &Ref
		|
		|GROUP BY
		|	RegisterData.Recorder,
		|	RegisterData.Period,
		|	RegisterData.Organization,
		|	RegisterData.FixedAsset";
		QueryTexts.Add(QueryText, TableName);
	EndIf;
	#EndRegion
	
	#Region TT_DepreciationOfVNA
	TableName = "TT_DepreciationOfVNA";
	If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	EndIf;
	#EndRegion
	
	#Region TTOperatingTimeOfObjectsOfOperation
	TableName = "TTOperatingTimeOfObjectsOfOperation";
	If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		QueryText =
		"SELECT
		|	RegisterData.FixedAsset AS Asset,
		|	MAX(RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits) AS Value
		|INTO TTOperatingTimeOfObjectsOfOperation
		|FROM
		|	InformationRegister.OSBUDepreciationParameters AS RegisterData
		|WHERE
		|	RegisterData.Recorder = &Ref
		|
		|GROUP BY
		|	RegisterData.FixedAsset";
		QueryTexts.Add(QueryText, TableName);
	EndIf;
	#EndRegion

	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	
	QueriesArray = New Array;
	For Each ListItem In QueryTexts Do
		QueriesArray.Add(ListItem.Value);
	EndDo;
	Query.Text = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	Query.SetParameter("Ref", Recorder);
	
	RegisterTable = Query.Execute().Unload();
		
	Return RegisterTable;
	
EndFunction

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
	
	PresentationOfDetails.Insert("FA.CostInAccounting", FieldPresentation);
	
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
		
	PresentationOfDetails.Insert("FA.CostInManagementAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (KTTh)';
																			|ru = 'Сумма (НУ)';
																			|en = 'TA amount'; fa = 'مبلغ حسابداری مالیاتی';
																			|it = 'Importo (Registro Fiscale)';
																			|pl = 'Wartość (EP)';
																			|tr = 'Tutar (VM)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.CostInTaxAccounting", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLVV)';
																			|ru = 'Сумма (ПР)';
																			|en = 'Amount (PD)'; fa = 'مبلغ (تفاوت دائم)';
																			|it = 'Importo (differenza costante)';
																			|pl = 'Wartość (różnica trwała)';
																			|tr = 'Tutar (Kalıcı fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.CostPermanentDifference", FieldPresentation);

	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền thưởng khấu hao';
																			|ru = 'Сумма амортизационной премии';
																			|en = 'Bonus depreciation amount'; fa = 'مبلغ استهلاک تشویقی';
																			|it = 'Importo del premi di ammortamento';
																			|pl = 'Wartość premii amortyzacyjnej';
																			|tr = 'Amortisman Primi tutarı'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.AmountOfBonusDepreciationTaxAccounting", FieldPresentation);
	
	Return PresentationOfDetails;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FixedAssetsCostAdditions2_4 - 
//  RowsSelected - Array, Undefined - 
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
	|	FATable.CostInManagementAccounting AS CostInManagementAccounting,
	|	FATable.CostInAccounting AS CostInAccounting,
	|	FATable.CostInTaxAccounting AS CostInTaxAccounting,
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
	|		WHEN &DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
	|			THEN &ConstructionObject
	|		ELSE FATable.FixedAsset
	|	END AS ExpensesCapitalizationDimension,
	|
	|	&PartialCommissioning 
	|		OR &AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
	|		OR &AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount) AS ActualCost,
	|
	|	FALSE AS AttributingDeviationsToCost,
	|	DATETIME(1,1,1) AS SourceDocumentDate,
	|
	|	FATable.CostInManagementAccounting AS AmountOfUU,
	|	FATable.CostInAccounting AS AmountAccounting,
	|	FATable.CostInTaxAccounting AS AmountFA,
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
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", DocumentDate);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("DimensionKindExpenseCapitalization", Object.DimensionKindExpenseCapitalization);
	Query.SetParameter("ConstructionObject", Object.ConstructionObject);
	Query.SetParameter("PartialCommissioning", Object.FixedAssetCostAdditionsPartial);
	Query.SetParameter("AccountingProcedureMA", Undefined);
	Query.SetParameter("AccountingProcedureAC", Undefined);
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
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
		
		RowData.CostInManagementAccounting = 0;
		RowData.CostInAccounting = 0;
		RowData.CostInTaxAccounting = 0;
		RowData.CostPermanentDifference = 0;

		TheStructureOfTheSearch = New Structure("AccountingObject", RowData.FixedAsset);
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
	Handler.Procedure = "Documents.FixedAssetsCostAdditions2_4.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a2a9710b-02c2-47a1-971d-5f5ccd780b98");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.FixedAssetsCostAdditions2_4.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Nâng cấp TSCĐ"":
								  |- Điền mục tin ""Giao dịch"", ""Phương thức hình thành giá trị"", ""Phương án tính bổ sung khấu hao""';
								  |ru = 'Обновляет документы ""Модернизация ОС"":
								  |- Заполняет реквизиты ""Операция"", ""Порядок формирования стоимости"", ""Вариант доначисления амортизации""';
								  |en = 'Updates the ""Fixed assets appreciation"" documents:
								  |- Fills in the ""Transaction"", ""Сost generation procedure"", and ""Additional depreciation accrual option"" attributes.'; fa = 'Updates the ""Fixed assets appreciation"" documents:
								  |- Fills in the ""Transaction"", ""Сost generation procedure"", and ""Additional depreciation accrual option"" attributes.';
								  |it = 'Updates the ""Fixed assets appreciation"" documents:
								  |- Fills in the ""Transaction"", ""Сost generation procedure"", and ""Additional depreciation accrual option"" attributes.';
								  |pl = 'Updates the ""Fixed assets appreciation"" documents:
								  |- Fills in the ""Transaction"", ""Сost generation procedure"", and ""Additional depreciation accrual option"" attributes.';
								  |tr = '""Sabit Kıymet Modernizasyonu"" belgelerini günceller: 
								  | - ""İşlem"", ""Maliyet oluşturma düzeni"", ""Amortisman ek tahakkuk seçeneği"" özniteliklerini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.FixedAssetsCostAdditions2_4.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.FixedAssetsCostAdditions2_4.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.FixedAssetsCostAdditions2_4.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.FixedAssetsCostAdditions2_4";
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
	|		Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|	WHERE
	|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|			OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.EmptyRef)
	|			OR DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.EmptyRef)
	|				AND DocumentData.AdjustmentModeFromPreviousDate
	|			OR DocumentData.RecordInLocalAccounting
	|				AND NOT DocumentData.PostInAccounting
	|				AND NOT DocumentData.RecordInTA
	|
	|	) AS DocumentsList
	|";
	
	Query = New Query(QueryText);
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.FixedAssetsCostAdditions2_4.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.FixedAssetsCostAdditions2_4";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.FixedAssetsCostAdditions2_4
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If DocumentObject.RecordInLocalAccounting
				And Not DocumentObject.PostInAccounting
				And Not DocumentObject.RecordInTA Then
					
				DocumentObject.PostInAccounting = True;
				
				
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.BusinessOperation) Then
				DocumentObject.BusinessOperation = Enums.BusinessTransactions.FixedAssetsCostAdditions;
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.DepreciationAdjustmentOption)
				And DocumentObject.AdjustmentModeFromPreviousDate Then
				DocumentObject.DepreciationAdjustmentOption = Enums.AdditionalDepreciationAccrualOptions.NotRequired;
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
	