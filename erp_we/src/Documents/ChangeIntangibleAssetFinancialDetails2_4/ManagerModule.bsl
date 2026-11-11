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
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	ChangeIntangibleAssetFinancialDetailsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ChangeIntangibleAssetFinancialDetails2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		
		QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		QueryTextTableCGUComposition(Query, QueryTexts, Registers);
	
		ChangeIntangibleAssetFinancialDetailsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Undefined);
	
	QueryTextTableIACost(QueryTexts);
	QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts);
	QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	ChangeIntangibleAssetFinancialDetailsLocalization.TablesOfDeferredMotionFormation(QueryTexts);

	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.IntangibleAssetsCostAndAmortizationAdjustment.AddGenerateCommand(GenerationCommands);
	
	ChangeIntangibleAssetFinancialDetailsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Change the parameters of the NMA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4);
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
	
	ChangeIntangibleAssetFinancialDetailsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ChangeIntangibleAssetFinancialDetailsLocalization.AddPrintCommands(PrintCommands);

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
	
	FullDocumentName = "Document.ChangeIntangibleAssetFinancialDetails2_4";
	
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
	|	DocumentData.Period  AS Period,
	|	DocumentData.Number   AS Number
	|FROM
	|	DocumentDataDetails AS DocumentData";
	
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
	|	Document.ChangeIntangibleAssetFinancialDetails2_4 AS DocumentsList
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
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	DocumentData.AccountingProcedureAC AS AccountingProcedureAC,
	|	DocumentData.AccountingProcedureACFlag AS AccountingProcedureACFlag,
	|	DocumentData.AccountingProcedureMA AS AccountingProcedureMA,
	|	DocumentData.AccountingProcedureMAFlag AS AccountingProcedureMAFlag,
	|	DocumentData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	DocumentData.DepreciationMethodAccountingFlag AS DepreciationMethodAccountingFlag,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
	|	DocumentData.DepreciationAccrualMethodManagementAccountingFlag AS DepreciationAccrualMethodManagementAccountingFlag,
	|	DocumentData.UsefulLifeAccounting AS UsefulLifeAccounting,
	|	DocumentData.UsefulLifeAccountingFlag AS UsefulLifeAccountingFlag,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	DocumentData.UsefulLifeManagementAccountingFlag AS UsefulLifeManagementAccountingFlag,
	|	DocumentData.EstimatedRunningTime AS EstimatedRunningTime,
	|	DocumentData.EstimatedRunningTimeFlag AS EstimatedRunningTimeFlag,
	|	DocumentData.DepreciationAccrualFactor AS DepreciationAccrualFactor,
	|	DocumentData.DepreciationAccrualFactorFlag AS DepreciationAccrualFactorFlag,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactorManagementAccounting,
	|	DocumentData.AccelerationFactorManagementAccountingFlag AS AccelerationFactorManagementAccountingFlag,
	|	DocumentData.ResidualValueMan AS ResidualValueMan,
	|	DocumentData.ResidualValueManFlag AS ResidualValueManFlag,
	|	DocumentData.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentData.ResidualValueLocalFlag AS ResidualValueLocalFlag,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.FinancialAccountingGroupFlag AS FinancialAccountingGroupFlag,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.LineOfBusinessFlag AS LineOfBusinessFlag,
	|	DocumentData.DepreciationExpenseRecordingIsChanged AS DepreciationExpenseRecordingIsChanged,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.CGUFlag AS CGUFlag,
	|	DocumentData.CGU AS CGU,
	|	DocumentData.ExpensesPostingMethod AS ExpensesPostingMethod,
	|	VALUE(Enum.BusinessTransactions.ChangeIntangibleAssetFinancialDetails) AS BusinessOperation,
	|
	|	&ChangingNMA_ParametersDocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4 AS DocumentData
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
	ChangeIntangibleAssetFinancialDetailsLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IntangibleAsset AS AccountingObject,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4.IA AS DocumentTable
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
	
	#Region DocumentDataTableDepreciation
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentTable.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DocumentTable.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|INTO DocumentDataTableDepreciation
	|
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4.Depreciation AS DocumentTable
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

	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ChangeIntangibleAssetFinancialDetails2_4"));
	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Thay đổi tham số TSCĐVH';
															|ru = 'Изменение параметров НМА';
															|en = 'Adjust intangible asset financial details'; fa = 'تعدیل جزئیات مالی دارایی نامشهود';
															|it = 'Modifica dei parametri degli attivi immateriali';
															|pl = 'Zmiana parametrów wartości niematerialnych';
															|tr = 'Maddi olmayan varlık finansal bilgi düzeltmesi'"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ChangeIntangibleAssetFinancialDetails);
	ValuesOfHoldingParameters.Insert("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf;
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	DocumentData.Ref                AS Ref,
	|	TableOfIA.IntangibleAsset        AS IntangibleAsset,
	|	&BusinessOperation                AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	UNDEFINED                          AS Department,
	|	DocumentData.Date                  AS Date,
	|	&MetadataIdentifier              AS RefType,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.RecordInManAccounting     AS RecordInManAccounting,
	|	DocumentData.PostInAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInTA           AS RecordInTA
	|
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4 AS DocumentData
	|
	|		LEFT JOIN Document.ChangeIntangibleAssetFinancialDetails2_4.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
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
	|	DocumentData.Ref         AS Ref,
	|	DocumentData.Date           AS IBDocumentDate,
	|	DocumentData.Number          AS IBDocumentNumber,
	|	&MetadataIdentifier       AS RefType,
	|	DocumentData.Organization    AS Organization,
	|	&BusinessOperation         AS BusinessOperation,
	|	UNDEFINED                   AS LineOfBusiness,
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
	|	Document.ChangeIntangibleAssetFinancialDetails2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
	
	QueryText = ChangeIntangibleAssetFinancialDetailsLocalization.QueryTextTableInitialIntangibleAssetsInformation();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText = 
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization AS Organization,
		|	TTInitialInformationOfIA.ReceiptMethod AS ReceiptMethod,
		|	TTInitialInformationOfIA.InitialCostMA AS InitialCostMA,
		|	TTInitialInformationOfIA.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	DocumentData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	TTInitialInformationOfIA.PurchaseDate AS PurchaseDate,
		|	TTInitialInformationOfIA.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DateOfRecognitionAccounting AS DateOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionManagementAccounting AS DocumentOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionAccounting AS DocumentOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DocumentWriteOffs AS DocumentWriteOffs,
		|	TTInitialInformationOfIA.CostRevaluationReserve AS CostRevaluationReserve,
		|	TTInitialInformationOfIA.DepreciationRevaluationReserve AS DepreciationRevaluationReserve
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTInitialInformationOfIA AS TTInitialInformationOfIA
		|		ON TTInitialInformationOfIA.Ref = TableOfIA.Ref
		|			AND TTInitialInformationOfIA.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.PostInAccounting
		|	AND DocumentData.DepreciationMethodAccountingFlag
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization AS Organization,
		|	TTInitialInformationOfIA.ReceiptMethod AS ReceiptMethod,
		|	TTInitialInformationOfIA.InitialCostMA AS InitialCostMA,
		|	TTInitialInformationOfIA.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|	TTInitialInformationOfIA.PurchaseDate AS PurchaseDate,
		|	TTInitialInformationOfIA.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DateOfRecognitionAccounting AS DateOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionManagementAccounting AS DocumentOfRecognitionManagementAccounting,
		|	TTInitialInformationOfIA.DocumentOfRecognitionAccounting AS DocumentOfRecognitionAccounting,
		|	TTInitialInformationOfIA.DocumentWriteOffs AS DocumentWriteOffs,
		|	TTInitialInformationOfIA.CostRevaluationReserve AS CostRevaluationReserve,
		|	TTInitialInformationOfIA.DepreciationRevaluationReserve AS DepreciationRevaluationReserve
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTInitialInformationOfIA AS TTInitialInformationOfIA
		|		ON TTInitialInformationOfIA.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationAccrualMethodManagementAccountingFlag
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedure(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	DocumentData.Organization AS Organization,
	|	
	|	CASE
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE IntangibleAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE IntangibleAssetsAccountingProcedure.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|			THEN DocumentData.EstimatedRunningTime
	|		ELSE IntangibleAssetsAccountingProcedure.EstimatedRunningTime
	|	END AS EstimatedRunningTime,
	|	
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForIA AS IntangibleAssetsAccountingProcedure
	|		ON IntangibleAssetsAccountingProcedure.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|		OR DocumentData.EstimatedRunningTimeFlag)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForNmabu(QueryTexts);
	
	QueryText = ChangeIntangibleAssetFinancialDetailsLocalization.QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization AS Organization,
		|	
		|	TTAccountingProcedureForNmabu.BUState AS BUState,
		|
		|	CASE
		|		WHEN DocumentData.AccountingProcedureACFlag
		|			THEN DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|		ELSE TTAccountingProcedureForNmabu.DepreciationAccrualAccounting
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.DepreciationRecordMethodLA
		|		ELSE DocumentData.Ref
		|	END AS DepreciationRecordMethodLA,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.ExpenseRecordMethodAC
		|		ELSE UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN TTAccountingProcedureForNmabu.TransferExpensesToAnotherCompany
		|		ELSE FALSE
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN TTAccountingProcedureForNmabu.CompanyRecipientOfExpenses
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingProcedureForNmabu AS TTAccountingProcedureForNmabu
		|		ON TTAccountingProcedureForNmabu.Ref = TableOfIA.Ref
		|			AND TTAccountingProcedureForNmabu.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.PostInAccounting
		|	AND (DocumentData.AccountingProcedureACFlag
		|		OR DocumentData.DepreciationExpenseRecordingIsChanged)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization AS Organization,
		|	
		|	TTAccountingProcedureForNmabu.BUState AS BUState,
		|
		|	CASE
		|		WHEN DocumentData.AccountingProcedureMAFlag
		|			THEN DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|		ELSE TTAccountingProcedureForNmabu.DepreciationAccrualAccounting
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.DepreciationRecordMethodLA
		|		ELSE DocumentData.Ref
		|	END AS DepreciationRecordMethodLA,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.ExpenseRecordMethodAC
		|		ELSE UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|				OR NOT DocumentData.PostInAccounting
		|			THEN TTAccountingProcedureForNmabu.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN TTAccountingProcedureForNmabu.TransferExpensesToAnotherCompany
		|		ELSE FALSE
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE
		|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
		|			THEN TTAccountingProcedureForNmabu.CompanyRecipientOfExpenses
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|		
		|		LEFT JOIN TTAccountingProcedureForNmabu AS TTAccountingProcedureForNmabu
		|		ON TTAccountingProcedureForNmabu.Ref = TableOfIA.Ref
		|			AND TTAccountingProcedureForNmabu.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND (DocumentData.AccountingProcedureMAFlag
		|		OR DocumentData.DepreciationExpenseRecordingIsChanged)
		|";
		
	EndIf;
	
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
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	DocumentData.Organization AS Organization,
	|	
	|	TTAccountingProcedureForNMAU.State AS State,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureMAFlag
	|			THEN DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|		ELSE TTAccountingProcedureForNMAU.AccrueDepreciationOrAmortization
	|	END AS AccrueDepreciationOrAmortization,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.DepreciationRecordMethod
	|		ELSE DocumentData.Ref
	|	END AS DepreciationRecordMethod,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.ExpensesPostingMethod
	|		ELSE UNDEFINED
	|	END AS ExpensesPostingMethod,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.ExpenseItem
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.TransferExpensesToAnotherCompany
	|		ELSE FALSE
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	CASE
	|		WHEN NOT DocumentData.DepreciationExpenseRecordingIsChanged
	|			THEN TTAccountingProcedureForNMAU.CompanyRecipientOfExpenses
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN TTAccountingProcedureForNMAU AS TTAccountingProcedureForNMAU
	|		ON TTAccountingProcedureForNMAU.Ref = TableOfIA.Ref
	|			AND TTAccountingProcedureForNMAU.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.AccountingProcedureMAFlag
	|		OR DocumentData.DepreciationExpenseRecordingIsChanged)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IADepreciationParametersBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersNMABU(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts);
	
	QueryText = ChangeIntangibleAssetFinancialDetailsLocalization.QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText = 
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization AS Organization,
		|
		|	WDepreciationParametersNMABU.LastChangeDate AS LastChangeDate,
		|
		// UsefulLifeForCalculatingDepreciationMonth 
		|	CASE
		|		WHEN DocumentData.UsefulLifeAccountingFlag AND WDepreciationParametersNMABU.IntangibleAsset IS NULL
		|			THEN DocumentData.UsefulLifeAccounting
		|		WHEN DocumentData.UsefulLifeAccountingFlag
		|				AND WDepreciationParametersNMABU.UsefulLifeMonthsAC = WDepreciationParametersNMABU.UsefulLifeForCalculatingDepreciationMonth
		|			THEN DocumentData.UsefulLifeAccounting
		|		WHEN DocumentData.UsefulLifeAccountingFlag
		|			THEN WDepreciationParametersNMABU.UsefulLifeForCalculatingDepreciationMonth + (DocumentData.UsefulLifeAccounting - WDepreciationParametersNMABU.UsefulLifeMonthsAC)
		|		ELSE WDepreciationParametersNMABU.UsefulLifeForCalculatingDepreciationMonth
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.EstimatedRunningTimeFlag AND WDepreciationParametersNMABU.IntangibleAsset IS NULL
		|			THEN DocumentData.EstimatedRunningTime
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND TTAccountingProcedureForIA.EstimatedRunningTime = WDepreciationParametersNMABU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|			THEN DocumentData.EstimatedRunningTime
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|			THEN WDepreciationParametersNMABU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits + (DocumentData.EstimatedRunningTime - TTAccountingProcedureForIA.EstimatedRunningTime)
		|		ELSE WDepreciationParametersNMABU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE
		|		WHEN DocumentData.UsefulLifeAccountingFlag
		|			THEN DocumentData.UsefulLifeAccounting
		|		ELSE WDepreciationParametersNMABU.UsefulLifeMonthsAC
		|	END AS UsefulLifeMonthsAC,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationAccrualFactorFlag
		|			THEN DocumentData.DepreciationAccrualFactor
		|		ELSE WDepreciationParametersNMABU.DepreciationAccrualFactor
		|	END AS DepreciationAccrualFactor,
		|
		|	CASE
		|		WHEN DocumentData.ResidualValueLocalFlag
		|			THEN DocumentData.ResidualValueLocal
		|		ELSE WDepreciationParametersNMABU.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		INNER JOIN WDepreciationParametersNMABU AS WDepreciationParametersNMABU
		|		ON WDepreciationParametersNMABU.Ref = TableOfIA.Ref
		|			AND WDepreciationParametersNMABU.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingProcedureForIA AS TTAccountingProcedureForIA
		|		ON TTAccountingProcedureForIA.Ref = TableOfIA.Ref
		|			AND TTAccountingProcedureForIA.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.RecordInLocalAccounting
		|	AND (DocumentData.DepreciationAccrualFactorFlag
		|		OR DocumentData.UsefulLifeAccountingFlag
		|		OR DocumentData.ResidualValueLocalFlag
		|		OR DocumentData.EstimatedRunningTimeFlag)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	TableOfIA.IntangibleAsset AS IntangibleAsset,
		|	DocumentData.Organization AS Organization,
		|
		|	WDepreciationParametersNMABU.LastChangeDate AS LastChangeDate,
		|
		// UsefulLifeForCalculatingDepreciationMonth 
		|	CASE
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag AND WDepreciationParametersNMABU.IntangibleAsset IS NULL
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag
		|				AND WDepreciationParametersNMABU.UsefulLifeMonthsAC = WDepreciationParametersNMABU.UsefulLifeForCalculatingDepreciationMonth
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag
		|			THEN WDepreciationParametersNMABU.UsefulLifeForCalculatingDepreciationMonth + (DocumentData.UsefulLifeManagementAccounting - WDepreciationParametersNMABU.UsefulLifeMonthsAC)
		|		ELSE WDepreciationParametersNMABU.UsefulLifeForCalculatingDepreciationMonth
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	CASE
		|		WHEN DocumentData.EstimatedRunningTimeFlag AND WDepreciationParametersNMABU.IntangibleAsset IS NULL
		|			THEN DocumentData.EstimatedRunningTime
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|				AND TTAccountingProcedureForIA.EstimatedRunningTime = WDepreciationParametersNMABU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|			THEN DocumentData.EstimatedRunningTime
		|		WHEN DocumentData.EstimatedRunningTimeFlag
		|			THEN WDepreciationParametersNMABU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits + (DocumentData.EstimatedRunningTime - TTAccountingProcedureForIA.EstimatedRunningTime)
		|		ELSE WDepreciationParametersNMABU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE
		|		WHEN DocumentData.UsefulLifeManagementAccountingFlag
		|			THEN DocumentData.UsefulLifeManagementAccounting
		|		ELSE WDepreciationParametersNMABU.UsefulLifeMonthsAC
		|	END AS UsefulLifeMonthsAC,
		|
		|	CASE
		|		WHEN DocumentData.AccelerationFactorManagementAccountingFlag
		|			THEN DocumentData.AccelerationFactorManagementAccounting
		|		ELSE WDepreciationParametersNMABU.DepreciationAccrualFactor
		|	END AS DepreciationAccrualFactor,
		|
		|	CASE
		|		WHEN DocumentData.ResidualValueLocalFlag
		|			THEN DocumentData.ResidualValueLocal
		|		ELSE WDepreciationParametersNMABU.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|		INNER JOIN WDepreciationParametersNMABU AS WDepreciationParametersNMABU
		|		ON WDepreciationParametersNMABU.Ref = TableOfIA.Ref
		|			AND WDepreciationParametersNMABU.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingProcedureForIA AS TTAccountingProcedureForIA
		|		ON TTAccountingProcedureForIA.Ref = TableOfIA.Ref
		|			AND TTAccountingProcedureForIA.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND (DocumentData.AccelerationFactorManagementAccountingFlag
		|		OR DocumentData.UsefulLifeManagementAccountingFlag
		|		OR DocumentData.ResidualValueLocalFlag
		|		OR DocumentData.EstimatedRunningTimeFlag)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetAmortizationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTNmauuDepreciationParameters(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	DocumentData.Organization AS Organization,
	|
	|	ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate, DATETIME(1, 1, 1)) AS LastChangeDate,
	|	
	|	CASE
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|		ELSE ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths, 0)
	|	END AS UsefulLifeMonths,
	|
	// UsefulLifeForCalculatingDepreciationMonth 
	|	CASE
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag AND IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset IS NULL
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag
	|				AND IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths = IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|			THEN DocumentData.UsefulLifeManagementAccounting
	|		WHEN DocumentData.UsefulLifeManagementAccountingFlag
	|			THEN IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth + (DocumentData.UsefulLifeManagementAccounting - IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeMonths)
	|		ELSE IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|	END AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	CASE
	|		WHEN DocumentData.EstimatedRunningTimeFlag AND IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset IS NULL
	|			THEN DocumentData.EstimatedRunningTime
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|				AND TTAccountingProcedureForIA.EstimatedRunningTime = IntangibleAssetAmortizationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|			THEN DocumentData.EstimatedRunningTime
	|		WHEN DocumentData.EstimatedRunningTimeFlag
	|			THEN IntangibleAssetAmortizationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits + (DocumentData.EstimatedRunningTime - TTAccountingProcedureForIA.EstimatedRunningTime)
	|		ELSE IntangibleAssetAmortizationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	CASE
	|		WHEN DocumentData.AccelerationFactorManagementAccountingFlag
	|			THEN DocumentData.AccelerationFactorManagementAccounting
	|		ELSE ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.AccelerationFactor, 0)
	|	END AS AccelerationFactor,
	|
	|	CASE
	|		WHEN DocumentData.DepreciationAccrualMethodManagementAccountingFlag
	|			THEN DocumentData.DepreciationAccrualMethodManagementAccounting
	|		ELSE IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod
	|	END AS DepreciationMethod,
	|
	|	CASE
	|		WHEN DocumentData.ResidualValueManFlag
	|			THEN DocumentData.ResidualValueMan
	|		WHEN DocumentData.ResidualValueLocalFlag
	|				AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|				AND &CurrencyOfMan = DocumentData.ComplCurrency
	|			THEN DocumentData.ResidualValueLocal
	|		ELSE ISNULL(IntangibleAssetAmortizationParametersManagementAccounting.ResidualValueMan, 0)
	|	END AS ResidualValueMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN TTNmauuDepreciationParameters AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON IntangibleAssetAmortizationParametersManagementAccounting.Ref = TableOfIA.Ref
	|			AND IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTAccountingProcedureForIA AS TTAccountingProcedureForIA
	|		ON TTAccountingProcedureForIA.Ref = TableOfIA.Ref
	|			AND TTAccountingProcedureForIA.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.UsefulLifeManagementAccountingFlag
	|		OR DocumentData.AccelerationFactorManagementAccountingFlag
	|		OR DocumentData.DepreciationAccrualMethodManagementAccountingFlag
	|		OR DocumentData.ResidualValueManFlag
	|		OR DocumentData.ResidualValueLocalFlag
	|			AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
	|			AND &CurrencyOfMan = DocumentData.ComplCurrency
	|		OR DocumentData.EstimatedRunningTimeFlag)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIACost(QueryTexts)

	RegisterName = "IACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	TTIAAccountingParameters.Department           AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|
	|	IACost.Cost                  AS Cost,
	|	IACost.LocalCost              AS LocalCost,
	|	IACost.CostInTaxAccounting                AS CostInTaxAccounting,
	|	IACost.CostPermanentDifference                AS CostPermanentDifference,
	|	IACost.CostTemporaryDifference                AS CostTemporaryDifference,
	|	IACost.CostTargetFinancing                AS CostTargetFinancing,
	|	IACost.CostTargetFinancingTA              AS CostTargetFinancingTA,
	|	IACost.CostTargetFinancingPD              AS CostTargetFinancingPD,
	|	IACost.CostTargetFinancingTD              AS CostTargetFinancingTD,
	|	IACost.TAExpenseAmountOfInvestmentTaxDeduction      AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	IACost.PreliminaryCostMan       AS PreliminaryCostMan,
	|	IACost.PreliminaryCostLocal   AS PreliminaryCostLocal,
	|	IACost.CostRevaluationReserve      AS CostRevaluationReserve,
	|	IACost.CostRevaluationReserveLocal  AS CostRevaluationReserveLocal,
	|
	|	0                                       AS CostGainMA,
	|	0                                       AS CostGainLocal,
	|
	|
	|	DocumentData.Organization             AS CorCompany,
	|	TTIAAccountingParameters.Department       AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	UNDEFINED                            AS CorExpenseItem,
	|	UNDEFINED                            AS CorExpenditureDimension,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsCostParameterChange) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	TTIAAccountingParameters.Department       AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	IACost.Cost                  AS Cost,
	|	IACost.LocalCost              AS LocalCost,
	|	IACost.CostInTaxAccounting                AS CostInTaxAccounting,
	|	IACost.CostPermanentDifference                AS CostPermanentDifference,
	|	IACost.CostTemporaryDifference                AS CostTemporaryDifference,
	|	IACost.CostTargetFinancing                AS CostTargetFinancing,
	|	IACost.CostTargetFinancingTA              AS CostTargetFinancingTA,
	|	IACost.CostTargetFinancingPD              AS CostTargetFinancingPD,
	|	IACost.CostTargetFinancingTD              AS CostTargetFinancingTD,
	|	IACost.TAExpenseAmountOfInvestmentTaxDeduction      AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	IACost.PreliminaryCostMan       AS PreliminaryCostMan,
	|	IACost.PreliminaryCostLocal   AS PreliminaryCostLocal,
	|	IACost.CostRevaluationReserve      AS CostRevaluationReserve,
	|	IACost.CostRevaluationReserveLocal  AS CostRevaluationReserveLocal,
	|
	|	0                                       AS CostGainMA,
	|	0                                       AS CostGainLocal,
	|
	|
	|	DocumentData.Organization             AS CorCompany,
	|	TTIAAccountingParameters.Department       AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	UNDEFINED                            AS CorExpenseItem,
	|	UNDEFINED                            AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsCostParameterChange) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = DocumentData.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	TTIAAccountingParameters.Department       AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|
	|	0                                       AS Cost,
	|	0                                       AS LocalCost,
	|	0                                       AS CostInTaxAccounting,
	|	0                                       AS CostPermanentDifference,
	|	0                                       AS CostTemporaryDifference,
	|	0                                       AS CostTargetFinancing,
	|	0                                       AS CostTargetFinancingTA,
	|	0                                       AS CostTargetFinancingPD,
	|	0                                       AS CostTargetFinancingTD,
	|	0                                       AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                       AS PreliminaryCostMan,
	|	0                                       AS PreliminaryCostLocal,
	|	0                                       AS CostRevaluationReserve,
	|	0                                       AS CostRevaluationReserveLocal,
	|
	|	IACost.CostGainMA           AS CostGainMA,
	|	IACost.CostGainLocal       AS CostGainLocal,
	|
	|
	|	DocumentData.Organization             AS CorCompany,
	|	TTIAAccountingParameters.Department       AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	UNDEFINED                            AS CorExpenseItem,
	|	UNDEFINED                            AS CorExpenditureDimension,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeIntangibleAssetRevaluationReserve) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag OR DocumentData.LineOfBusinessFlag)
	|	AND (IACost.CostGainMA <> 0 OR IACost.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	TableOfIA.IntangibleAsset          AS IntangibleAsset,
	|	TTIAAccountingParameters.Department       AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	0                                       AS Cost,
	|	0                                       AS LocalCost,
	|	0                                       AS CostInTaxAccounting,
	|	0                                       AS CostPermanentDifference,
	|	0                                       AS CostTemporaryDifference,
	|	0                                       AS CostTargetFinancing,
	|	0                                       AS CostTargetFinancingTA,
	|	0                                       AS CostTargetFinancingPD,
	|	0                                       AS CostTargetFinancingTD,
	|	0                                       AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                       AS PreliminaryCostMan,
	|	0                                       AS PreliminaryCostLocal,
	|	0                                       AS CostRevaluationReserve,
	|	0                                       AS CostRevaluationReserveLocal,
	|
	|	IACost.CostGainMA           AS CostGainMA,
	|	IACost.CostGainLocal       AS CostGainLocal,
	|
	|
	|	DocumentData.Organization             AS CorCompany,
	|	TTIAAccountingParameters.Department       AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	UNDEFINED                            AS CorExpenseItem,
	|	UNDEFINED                            AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeIntangibleAssetRevaluationReserve) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	(DocumentData.FinancialAccountingGroupFlag 
	|		OR DocumentData.LineOfBusinessFlag)
	|
	|	AND (IACost.CostGainMA <> 0 
	|		OR IACost.CostGainLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|	TableOfIA.IntangibleAsset             AS IntangibleAsset,
	|	TTIAAccountingParameters.Department          AS Department,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                               AS Counterparty,
	|	IntangibleAssetsAmortizationCharge.Depreciation                 AS Depreciation,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal             AS DepreciationLocal,
	|	IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD               AS DepreciationTD,
	|	IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	DocumentData.Organization                AS CorCompany,
	|	TTIAAccountingParameters.Department          AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	UNDEFINED                               AS CorExpenseItem,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetAmortizationParameterChange) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IntangibleAssetsAmortizationCharge.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)     AS RecordType,
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|	TableOfIA.IntangibleAsset             AS IntangibleAsset,
	|	TTIAAccountingParameters.Department          AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                               AS Counterparty,
	|	IntangibleAssetsAmortizationCharge.Depreciation                 AS Depreciation,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal             AS DepreciationLocal,
	|	IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD               AS DepreciationTD,
	|	IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	DocumentData.Organization                AS CorCompany,
	|	TTIAAccountingParameters.Department          AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	UNDEFINED                               AS CorExpenseItem,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	
	|	TableOfIA.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetAmortizationParameterChange) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IntangibleAssetsAmortizationCharge.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	// Moving depreciation
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetAmortizationParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTIAAccountingParameters.Department            AS Department,
	|	TTIAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	&Ap_nmaArticle                                AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	UNDEFINED                                 AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset               AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	TTIAAccountingParameters.Department            AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	&Ap_nmaArticle                                AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset               AS CorDimensionOfAssetsLiabilities,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	IntangibleAssetsAmortizationCharge.Depreciation                   AS Sum,
	|	IntangibleAssetsAmortizationCharge.Depreciation                   AS SumMan,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal + IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IntangibleAssetsAmortizationCharge.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|
	|UNION ALL
	|
	// Moving the cost
	|SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	VALUE(Enum.BusinessTransactions.IntangibleAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTIAAccountingParameters.Department            AS Department,
	|	TTIAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	&Ap_nmaArticle                                AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	UNDEFINED                                 AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset               AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	TTIAAccountingParameters.Department            AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN DocumentData.LineOfBusinessFlag
	|			THEN DocumentData.LineOfBusiness
	|		ELSE TTIAAccountingParameters.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	&Ap_nmaArticle                                AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset               AS CorDimensionOfAssetsLiabilities,
	|
	|	CASE 
	|		WHEN DocumentData.FinancialAccountingGroupFlag
	|			THEN DocumentData.FinancialAccountingGroup
	|		ELSE TTIAAccountingParameters.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	IACost.Cost                       AS Sum,
	|	IACost.Cost                       AS SumMan,
	|	IACost.LocalCost + IACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTIAAccountingParameters AS TTIAAccountingParameters
	|		ON TTIAAccountingParameters.Ref = TableOfIA.Ref
	|			AND TTIAAccountingParameters.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.AccountingObject = TableOfIA.IntangibleAsset
	|			AND IACost.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.FinancialAccountingGroupFlag
	|		OR DocumentData.LineOfBusinessFlag
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableCGUComposition(Query, QueryTexts, Registers)
	
	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref         AS Recorder,
	|	DocumentData.Period         AS Period,
	|	TableOfIA.IntangibleAsset AS NonCurrentAsset,
	|	DocumentData.Organization    AS Organization,
	|	DocumentData.CGU           AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.CGUFlag";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return ChangeIntangibleAssetFinancialDetailsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return ChangeIntangibleAssetFinancialDetailsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Depreciation";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("DepreciationExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("DepreciationIsExpenseItemWithoutDivision");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DepreciationDimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DepreciationExpenseAnalyticsWithoutPartitioning");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
