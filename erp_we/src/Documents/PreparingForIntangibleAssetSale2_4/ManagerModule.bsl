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
	DocumentMechanisms.Add("ImpairmentFA");
	
	PreparingForIntangibleAssetSaleLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.PreparingForIntangibleAssetSale2_4") Then
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
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		PreparingForIntangibleAssetSaleLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);

	QueryTextTableIACost(QueryTexts);
	QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	PreparingForIntangibleAssetSaleLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
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
	
	Documents.CustomerInvoiceServicesAndAssets.AddGenerateCommand(GenerationCommands);
	
	PreparingForIntangibleAssetSaleLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Preparing for the transfer of IA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.PreparingForIntangibleAssetSale2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PreparingForIntangibleAssetSale2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PreparingForIntangibleAssetSale2_4);
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
	
	PreparingForIntangibleAssetSaleLocalization.AddReportCommands(ReportsCommands, Parameters);

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
	
	FullDocumentName = "Document.PreparingForIntangibleAssetSale2_4";
	
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
	|	DocumentData.Period AS Period,
	|	DocumentData.Number  AS Number
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
	|	Document.PreparingForIntangibleAssetSale2_4 AS DocumentsList
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
	|	DocumentData.Ref                 AS Ref,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.Date                   AS Period,
	|	DocumentData.Number                  AS Number,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department          AS Department,
	|	DocumentData.EmployeeResponsible          AS EmployeeResponsible,
	|	DocumentData.Comment            AS Comment,
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	VALUE(Enum.BusinessTransactions.PreparingForIntangibleAssetSale) AS BusinessOperation
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.PreparingForIntangibleAssetSale2_4 AS DocumentData
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
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.PreparingForIntangibleAssetSale2_4.IA AS DocumentTable
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
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Chuẩn bị chuyển giao TSCĐ vô hình';
															|ru = 'Подготовка к передаче НМА';
															|en = 'Retire intangible assets'; fa = 'کنارگذاری دارایی‌های نامشهود';
															|it = 'Preparazione al trasferimento dei Beni immateriali';
															|pl = 'Przygotowanie do przekazania wartości niematerialnych';
															|tr = 'Maddi olmayan varlıkların çekilmesi'"));
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.PreparingForIntangibleAssetSale2_4"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.PreparingForIntangibleAssetSale);
	ValuesOfHoldingParameters.Insert("BusinessTransactionCost", Enums.BusinessTransactions.WriteOffIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("EconomicOperationDepreciation", Enums.BusinessTransactions.IntangibleAssetAmortizationWriteOff);
	ValuesOfHoldingParameters.Insert("BusinessTransactionReserveCost", Enums.BusinessTransactions.WriteOffRevaluationReserveOfIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("BusinessOperationProvisionDepreciation", Enums.BusinessTransactions.WriteOffRevaluationReserveOfIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("BusinessTransactionImpairment", Enums.BusinessTransactions.WriteOffOfIaImpairment);
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	ValuesOfHoldingParameters.Insert("SettingUpBusinessOperationDepreciation", Catalogs.BusinessTransactionsSettings.IntangibleAssetAmortizationWriteOff);
	ValuesOfHoldingParameters.Insert("SettingUpBusinessOperationReserveCost", Catalogs.BusinessTransactionsSettings.WriteOffRevaluationReserveOfIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpBusinessTransactionImpairment", Catalogs.BusinessTransactionsSettings.WriteOffOfIaImpairment);
	
	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	
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
	|	DocumentData.Ref           AS Ref,
	|	TableOfIA.IntangibleAsset   AS IntangibleAsset,
	|	&BusinessOperation           AS BusinessOperation,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Department    AS Department,
	|	DocumentData.Date             AS Date,
	|	&MetadataIdentifier         AS RefType,
	|	DocumentData.Posted         AS Posted,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting AS RecordInTA
	|
	|FROM
	|	Document.PreparingForIntangibleAssetSale2_4 AS DocumentData
	|
	|		LEFT JOIN Document.PreparingForIntangibleAssetSale2_4.IA AS TableOfIA
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
	|	Document.PreparingForIntangibleAssetSale2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers)

	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = PreparingForIntangibleAssetSaleLocalization.QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts);
	
	If QueryText = Undefined Then
		QueryText =
		"SELECT
		|	DocumentData.Ref           AS Recorder,
		|	DocumentData.Period           AS Period,
		|	DocumentData.Organization      AS Organization,
		|	TableOfIA.IntangibleAsset   AS IntangibleAsset,
		|	FALSE                             AS DepreciationAccrualAccounting,
		|	VALUE(Enum.IntangibleAssetsStates.WrittenOff_) AS BUState
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataIATable AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|WHERE
		|	DocumentData.RecordInLocalAccounting";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "IntangibleAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref           AS Recorder,
	|	DocumentData.Period           AS Period,
	|	DocumentData.Organization      AS Organization,
	|	TableOfIA.IntangibleAsset   AS IntangibleAsset,
	|	FALSE                             AS AccrueDepreciationOrAmortization,
	|	VALUE(Enum.IntangibleAssetsStates.WrittenOff_) AS State
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataIATable AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|WHERE
	|	DocumentData.RecordInManAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
	
	QueryText = PreparingForIntangibleAssetSaleLocalization.QueryTextTableInitialIntangibleAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref                                      AS Recorder,
		|	DocumentData.Period                                      AS Period,
		|	DocumentData.Organization                                 AS Organization,
		|	TableOfIA.IntangibleAsset                              AS IntangibleAsset,
		|	InitialInformation.ReceiptMethod                    AS ReceiptMethod,
		|	InitialInformation.InitialCostLocalAccounting            AS InitialCostLocalAccounting,
		|	InitialInformation.InitialCostMA            AS InitialCostMA,
		|	InitialInformation.DepreciationMethodAccounting         AS DepreciationMethodAccounting,
		|	InitialInformation.PurchaseDate                     AS PurchaseDate,
		|	InitialInformation.DateOfRecognitionManagementAccounting                 AS DateOfRecognitionManagementAccounting,
		|	InitialInformation.DateOfRecognitionAccounting                 AS DateOfRecognitionAccounting,
		|	InitialInformation.DocumentOfRecognitionManagementAccounting             AS DocumentOfRecognitionManagementAccounting,
		|	InitialInformation.DocumentOfRecognitionAccounting             AS DocumentOfRecognitionAccounting,
		|	DocumentData.Ref                                      AS DocumentWriteOffs
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataIATable AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|
		|		INNER JOIN TTInitialInformationOfIA AS InitialInformation
		|		ON TableOfIA.IntangibleAsset = InitialInformation.IntangibleAsset
		|			AND InitialInformation.Organization = TableOfIA.Organization
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIACost(QueryTexts)

	RegisterName = "IACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"// Depreciation write-off
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	DepreciationOfVNA.AccountingObject             AS IntangibleAsset,
	|
	|	DepreciationOfVNA.Depreciation             AS Cost,
	|	DepreciationOfVNA.DepreciationLocal         AS LocalCost,
	|	DepreciationOfVNA.DepreciationInTaxAccounting           AS CostInTaxAccounting,
	|	DepreciationOfVNA.DepreciationPermanentDifferences           AS CostPermanentDifference,
	|	DepreciationOfVNA.DepreciationTD           AS CostTemporaryDifference,
	|	DepreciationOfVNA.FixedAssetDepreciationTargetFinancing           AS CostTargetFinancing,
	|	DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing         AS CostTargetFinancingTA,
	|	DepreciationOfVNA.DepreciationTargetFinancingPD         AS CostTargetFinancingPD,
	|	DepreciationOfVNA.DepreciationOfTargetFinancingTD         AS CostTargetFinancingTD,
	|	0                                      AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&EconomicOperationDepreciation      AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID         AS FinRecordID,
	|	&SettingUpBusinessOperationDepreciation AS BusinessTransactionSetting
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
	|		INNER JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = TableOfIA.Ref
	|			AND DepreciationOfVNA.AccountingObject = TableOfIA.IntangibleAsset
	|
	|UNION ALL
	|
	|// Write-off of the pre-assessment reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	CostOfVNA.AccountingObject               AS IntangibleAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|	0                                      AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	CostOfVNA.CostRevaluationReserve AS CostRevaluationReserve,
	|	CostOfVNA.CostRevaluationReserveLocal AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&BusinessTransactionReserveCost  AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
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
	|		INNER JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = TableOfIA.Ref 
	|			AND CostOfVNA.AccountingObject = TableOfIA.IntangibleAsset 
	|
	|WHERE
	|	(CostOfVNA.CostRevaluationReserve <> 0
	|		OR CostOfVNA.CostRevaluationReserveLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	CostOfVNA.AccountingObject               AS IntangibleAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|	0                                      AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|
	|	CostOfVNA.CostGainMA          AS CostGainMA,
	|	CostOfVNA.CostGainLocal      AS CostGainLocal,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&BusinessTransactionReserveCost  AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
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
	|		INNER JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = TableOfIA.Ref
	|			AND CostOfVNA.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	(CostOfVNA.CostGainMA <> 0
	|		OR CostOfVNA.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|// Write-off of impairment
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	ImpairmentFA.AccountingObject             AS IntangibleAsset,
	|
	|	ImpairmentFA.ImpairmenMan          AS Cost,
	|	ImpairmentFA.ImpairmentLocalAssets         AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|	0                                      AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&BusinessTransactionImpairment      AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID         AS FinRecordID,
	|	&SettingUpBusinessTransactionImpairment AS BusinessTransactionSetting
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
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = TableOfIA.Ref
	|			AND ImpairmentFA.AccountingObject = TableOfIA.IntangibleAsset 
	|
	|UNION ALL
	|
	|// Write-off of other amounts
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	TableOfIA.IntangibleAsset         AS IntangibleAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|	CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction     AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&BusinessOperation                 AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
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
	|		INNER JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = TableOfIA.Ref
	|			AND CostOfVNA.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	// Depreciation write-off
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	DepreciationOfVNA.AccountingObject             AS IntangibleAsset,
	|
	|	DepreciationOfVNA.Depreciation             AS Depreciation,
	|	DepreciationOfVNA.DepreciationLocal         AS DepreciationLocal,
	|	DepreciationOfVNA.DepreciationInTaxAccounting           AS DepreciationInTaxAccounting,
	|	DepreciationOfVNA.DepreciationPermanentDifferences           AS DepreciationPermanentDifferences,
	|	DepreciationOfVNA.DepreciationTD           AS DepreciationTD,
	|	DepreciationOfVNA.FixedAssetDepreciationTargetFinancing           AS FixedAssetDepreciationTargetFinancing,
	|	DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing         AS DepreciationTaxAccountingTargetFinancing,
	|	DepreciationOfVNA.DepreciationTargetFinancingPD         AS DepreciationTargetFinancingPD,
	|	DepreciationOfVNA.DepreciationOfTargetFinancingTD         AS DepreciationOfTargetFinancingTD,
	|	DepreciationOfVNA.DepreciationRevaluationReserve     AS DepreciationRevaluationReserve,
	|	DepreciationOfVNA.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&EconomicOperationDepreciation      AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID             AS FinRecordID,
	|	&SettingUpBusinessOperationDepreciation AS BusinessTransactionSetting
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
	|		INNER JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = TableOfIA.Ref
	|			AND DepreciationOfVNA.AccountingObject = TableOfIA.IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableImpairmentFA(QueryTexts)

	RegisterName = "ImpairmentFA";
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	// Write-off of impairment
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	ImpairmentFA.AccountingObject             AS NonCurrentAsset,
	|	ImpairmentFA.CGU                    AS CGU,
	|
	|	ImpairmentFA.ImpairmenMan          AS ImpairmenMan,
	|	ImpairmentFA.ImpairmentLocalAssets         AS ImpairmentLocalAssets,
	|	
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&BusinessTransactionImpairment      AS BusinessOperation,
	|	
	|	TableOfIA.RowID             AS FinRecordID,
	|	&SettingUpBusinessTransactionImpairment AS BusinessTransactionSetting
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
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = TableOfIA.Ref
	|			AND ImpairmentFA.AccountingObject = TableOfIA.IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTIAAccountingParameters(QueryTexts);
	
	QueryText =
	"// Depreciation write-off
	|SELECT
	|	DocumentData.Ref              AS Recorder,
	|	DocumentData.Period              AS Period,
	|	&EconomicOperationDepreciation   AS BusinessOperation,
	|	DocumentData.Organization         AS Organization,
	|
	|	DocumentData.Department       AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                       AS AssetRef,
	|	UNDEFINED                        AS DimensionOfRevenue,
	|	UNDEFINED                        AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset      AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department       AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle                       AS CorItem,
	|	UNDEFINED                        AS CorIncomeDimension,
	|	UNDEFINED                        AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset      AS CorDimensionOfAssetsLiabilities,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DepreciationOfVNA.Depreciation          AS Sum,
	|	DepreciationOfVNA.Depreciation          AS SumMan,
	|	DepreciationOfVNA.DepreciationLocal 
	|		+ DepreciationOfVNA.FixedAssetDepreciationTargetFinancing  AS SumCompl
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
	|		INNER JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = TableOfIA.Ref
	|			AND DepreciationOfVNA.AccountingObject = TableOfIA.IntangibleAsset
	|
	|UNION ALL
	|
	|//Write-off of impairment
	|SELECT
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	&BusinessTransactionImpairment      AS BusinessOperation,
	|	DocumentData.Organization            AS Organization,
	|
	|	DocumentData.Department          AS Department,
	|	TTIAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                          AS AssetRef,
	|	UNDEFINED                           AS DimensionOfRevenue,
	|	UNDEFINED                           AS DimensionOfExpenses,
	|	TableOfIA.IntangibleAsset         AS AssetsLiabilitiesDimension,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department          AS DebitBusinessUnit,
	|	TTIAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&Ap_nmaArticle                          AS CorItem,
	|	UNDEFINED                           AS CorIncomeDimension,
	|	UNDEFINED                           AS CorExpenditureDimension,
	|	TableOfIA.IntangibleAsset         AS CorDimensionOfAssetsLiabilities,
	|	TTIAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	ImpairmentFA.ImpairmenMan          AS Sum,
	|	ImpairmentFA.ImpairmenMan          AS SumMan,
	|	ImpairmentFA.ImpairmentLocalAssets         AS SumCompl
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
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = TableOfIA.Ref
	|			AND ImpairmentFA.AccountingObject = TableOfIA.IntangibleAsset 
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

#EndRegion

#Region ConductingLocalAccounting_

Function RequestTextTTReflectedInLocalAccounting() Export

	Return PreparingForIntangibleAssetSaleLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export
	
	Return PreparingForIntangibleAssetSaleLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	PreparingForIntangibleAssetSaleLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#EndRegion

#EndIf
