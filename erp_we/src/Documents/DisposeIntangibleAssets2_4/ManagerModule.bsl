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
	
	DisposeIntangibleAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.DisposeIntangibleAssets2_4") Then
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
		QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		DisposeIntangibleAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	
	QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Undefined);
	QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetAmortizationParametersManagementAccounting(QueryTexts, Undefined);
	QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Undefined);
	QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	
	QueryTextTableIACost(QueryTexts);
	QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableOtherExpenses(QueryTexts);
	QueryTextTableItemisedExpensesLots(QueryTexts);
	QueryTextTableOtherAssetsLiabilities(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	DisposeIntangibleAssetsLocalization.AddDeferredTrafficRequestTexts(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables
	
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
	
	DisposeIntangibleAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "write-off of IA".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.DisposeIntangibleAssets2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DisposeIntangibleAssets2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DisposeIntangibleAssets2_4);
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
	
	DisposeIntangibleAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	DisposeIntangibleAssetsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

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

#EndRegion

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
	
	FullDocumentName = "Document.DisposeIntangibleAssets2_4";
	
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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation
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
	|	Document.DisposeIntangibleAssets2_4 AS DocumentsList
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
	|	DocumentData.Ref                     AS Ref,
	|	DocumentData.Date                       AS Period,
	|	DocumentData.Number                      AS Number,
	|	DocumentData.Posted                   AS Posted,
	|	DocumentData.DeletionMark            AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting         AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting          AS RecordInManAccounting,
	|	DocumentData.PostInAccounting                AS PostInAccounting,
	|	DocumentData.RecordInTA                AS RecordInTA,
	|	DocumentData.BusinessOperation      AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department              AS Department,
	|	DocumentData.ExpenseItem             AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses          AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	DocumentData.GLAccountSettings       AS GLAccountSettings,
	|	DocumentData.DimensionCorrespondsToIAToWriteOff AS DimensionCorrespondsToIAToWriteOff,
	|	DocumentData.ExpensesBusinessUnit      AS ExpensesBusinessUnit,
	|	DocumentData.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	DocumentData.EmployeeResponsible              AS EmployeeResponsible,
	|	DocumentData.Comment                AS Comment,
	|	BusinessTransactionsSettings.Ref      AS BusinessTransactionSetting
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.DisposeIntangibleAssets2_4 AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
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
	
	#Region DocumentDataIATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.IntangibleAsset AS IntangibleAsset,
	|	DocumentTable.ResidualValueMan AS ResidualValueMan,
	|	DocumentTable.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentTable.AmountManagementAccounting AS AmountManagementAccounting,
	|	DocumentTable.ChargeAmountAccounting  AS ChargeAmountAccounting,
	|	DocumentTable.AmountTaxAccounting AS AmountTaxAccounting,
	|	DocumentTable.AmountPermanentDifference AS AmountPermanentDifference,
	|	DocumentTable.AmountTemporaryDifference AS AmountTemporaryDifference
	|
	|INTO DocumentDataIATable
	|
	|FROM
	|	Document.DisposeIntangibleAssets2_4.IA AS DocumentTable
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.DisposeIntangibleAssets2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Ghi giảm TSCĐ vô hình';
															|ru = 'Списание НМА';
															|en = 'Dispose intangible assets'; fa = 'واگذاری دارایی‌های نامشهود';
															|it = 'Cancellazione degli attivi immateriali';
															|pl = 'Wyksięgowanie wartości niematerialnych';
															|tr = 'Maddi olmayan varlık gider yazma'"));
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	ValuesOfHoldingParameters.Insert("BO_Cost", Enums.BusinessTransactions.WriteOffIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("BO_CostTargetFinancing", Enums.BusinessTransactions.WriteOffCostOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("BO_Depreciation", Enums.BusinessTransactions.IntangibleAssetAmortizationWriteOff);
	ValuesOfHoldingParameters.Insert("BO_FixedAssetDepreciationTargetFinancing", Enums.BusinessTransactions.WriteOffAmortizationOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("BO_ReserveCost", Enums.BusinessTransactions.WriteOffRevaluationReserveOfIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("BT_ReserveDepreciation", Enums.BusinessTransactions.WriteOffRevaluationReserveOfIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("BO_Impairment", Enums.BusinessTransactions.WriteOffOfIaImpairment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_Cost", Catalogs.BusinessTransactionsSettings.WriteOffIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_CostTargetFinancing", Catalogs.BusinessTransactionsSettings.WriteOffCostOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("SettingUpHO_Depreciation", Catalogs.BusinessTransactionsSettings.IntangibleAssetAmortizationWriteOff);
	ValuesOfHoldingParameters.Insert("SettingUpHO_FixedAssetDepreciationTargetFinancing", Catalogs.BusinessTransactionsSettings.WriteOffAmortizationOfTargetFinancingOfIntangibleAssets);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReserveCost", Catalogs.BusinessTransactionsSettings.WriteOffRevaluationReserveOfIntangibleAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReserveDepreciation", Catalogs.BusinessTransactionsSettings.WriteOffRevaluationReserveOfIntangibleAssetAmortization);
	ValuesOfHoldingParameters.Insert("SettingUpHO_Impairment", Catalogs.BusinessTransactionsSettings.WriteOffOfIaImpairment);
	
	ValuesOfHoldingParameters.Insert("Ap_nmaArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	ValuesOfHoldingParameters.Insert("Article6_ProfitLoss", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);

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
	|	ISNULL(TableOfIA.LineNumber-1, 0)           AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	TableOfIA.IntangibleAsset                  AS IntangibleAsset,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.Date                            AS Date,
	|	&MetadataIdentifier                        AS RefType,
	|	DocumentData.Posted                        AS Posted,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.PostInAccounting                     AS RecordInLocalAccounting,
	|	DocumentData.RecordInTA                     AS RecordInTA
	|
	|FROM
	|	Document.DisposeIntangibleAssets2_4 AS DocumentData
	|
	|		LEFT JOIN Document.DisposeIntangibleAssets2_4.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	|	Document.DisposeIntangibleAssets2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableInitialIntangibleAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialIntangibleAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationOfIA(QueryTexts);
	
	QueryText = DisposeIntangibleAssetsLocalization.QueryTextTableInitialIntangibleAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	DocumentData.Ref                                             AS Recorder,
		|	DocumentData.Period                                             AS Period,
		|	DocumentData.Organization                                        AS Organization,
		|	TableOfIA.IntangibleAsset                                     AS IntangibleAsset,
		|
		|	InitialIntangibleAssetsInformation.DepreciationMethodAccounting             AS DepreciationMethodAccounting,
		|	InitialIntangibleAssetsInformation.PurchaseDate                         AS PurchaseDate,
		|	InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting                     AS DateOfRecognitionManagementAccounting,
		|	InitialIntangibleAssetsInformation.DateOfRecognitionAccounting                     AS DateOfRecognitionAccounting,
		|	InitialIntangibleAssetsInformation.DocumentOfRecognitionManagementAccounting                 AS DocumentOfRecognitionManagementAccounting,
		|	InitialIntangibleAssetsInformation.DocumentOfRecognitionAccounting                 AS DocumentOfRecognitionAccounting,
		|
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
		|			THEN InitialIntangibleAssetsInformation.InitialCostMA - TableOfIA.AmountManagementAccounting                
		|		ELSE InitialIntangibleAssetsInformation.InitialCostMA
		|	END AS InitialCostMA,
		|
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
		|			THEN InitialIntangibleAssetsInformation.InitialCostLocalAccounting - TableOfIA.ChargeAmountAccounting                
		|		ELSE InitialIntangibleAssetsInformation.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE
		|		WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
		|			THEN DocumentData.Ref
		|		ELSE UNDEFINED
		|	END AS DocumentWriteOffs
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataIATable AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|	
		|		INNER JOIN TTInitialInformationOfIA AS InitialIntangibleAssetsInformation
		|		ON InitialIntangibleAssetsInformation.Ref = TableOfIA.Ref
		|			AND InitialIntangibleAssetsInformation.IntangibleAsset = TableOfIA.IntangibleAsset
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IADepreciationParametersBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersNMABU(QueryTexts);

	QueryText = DisposeIntangibleAssetsLocalization.QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	DocumentData.Ref                        AS Recorder,
		|	DocumentData.Period                        AS Period,
		|	DocumentData.Organization                   AS Organization,
		|	RegisterData.IntangibleAsset            AS IntangibleAsset,
		|	RegisterData.UsefulLifeMonthsAC   AS UsefulLifeMonthsAC,
		|	RegisterData.DepreciationAccrualFactor                  AS DepreciationAccrualFactor,
		|	TableOfIA.ResidualValueLocal        AS ResidualValueMan,
		|	RegisterData.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
		|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	RegisterData.LastChangeDate        AS LastChangeDate
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|	
		|		INNER JOIN WDepreciationParametersNMABU AS RegisterData
		|		ON RegisterData.Ref = TableOfIA.Ref
		|			AND RegisterData.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|WHERE
		|	DocumentData.PostInAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
		|	AND TableOfIA.ResidualValueLocal <> RegisterData.ResidualValueMan
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

	QueryText = 
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|	RegisterData.IntangibleAsset             AS IntangibleAsset,
	|	RegisterData.UsefulLifeMonths               AS UsefulLifeMonths,
	|	RegisterData.AccelerationFactor            AS AccelerationFactor,
	|	RegisterData.DepreciationMethod      AS DepreciationMethod,
	|	TableOfIA.ResidualValueMan             AS ResidualValueMan,
	|	TableOfIA.ResidualValueLocal         AS ResidualValueLocal,
	|	RegisterData.UsefulLifeForCalculatingDepreciationMonth   AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	RegisterData.LastChangeDate         AS LastChangeDate
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|	
	|		INNER JOIN TTNmauuDepreciationParameters AS RegisterData
	|		ON RegisterData.Ref = TableOfIA.Ref
	|			AND RegisterData.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|	AND (TableOfIA.ResidualValueMan <> RegisterData.ResidualValueMan
	|		OR TableOfIA.ResidualValueLocal <> RegisterData.ResidualValueLocal)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts, Registers)
	
	RegisterName = "IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = DisposeIntangibleAssetsLocalization.QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts);

	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	DocumentData.Ref           AS Recorder,
		|	DocumentData.Period           AS Period,
		|	DocumentData.Organization      AS Organization,
		|	TableOfIA.IntangibleAsset   AS IntangibleAsset,
		|	FALSE                             AS DepreciationAccrualAccounting,
		|	VALUE(Enum.IntangibleAssetsStates.WrittenOff_) AS BUState
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataIATable AS TableOfIA
		|		ON TableOfIA.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.PostInAccounting
		|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
		|";
		
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
	|	DocumentData.Ref         AS Recorder,
	|	DocumentData.Period         AS Period,
	|	DocumentData.Organization    AS Organization,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	VALUE(Enum.IntangibleAssetsStates.WrittenOff_) AS State
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataIATable AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIntangibleAssetsAmortizationCharge(QueryTexts)

	RegisterName = "IntangibleAssetsAmortizationCharge";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTDepreciationWriteOffOfIa(QueryTexts);
	
	QueryText =
	"// Depreciation write-off
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Department              AS Department,
	|	TTDepreciationWriteOff.IntangibleAsset  AS IntangibleAsset,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTDepreciationWriteOff.Depreciation 
	|		ELSE 0 
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationLocal 
	|		ELSE 0 
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInTA 
	|			THEN TTDepreciationWriteOff.DepreciationInTaxAccounting 
	|		ELSE 0 
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting
	|				OR DocumentData.RecordInTA
	|					AND ISNULL(IACost.LocalCost, 0) = 0
	|					AND ISNULL(IACost.CostTargetFinancing, 0) = 0
	|			THEN TTDepreciationWriteOff.DepreciationPermanentDifferences 
	|		ELSE 0 
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationLocal 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTDepreciationWriteOff.DepreciationInTaxAccounting 
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting
	|					OR DocumentData.RecordInTA
	|						AND ISNULL(IACost.LocalCost, 0) = 0
	|						AND ISNULL(IACost.CostTargetFinancing, 0) = 0
	|				THEN TTDepreciationWriteOff.DepreciationPermanentDifferences 
	|			ELSE 0 
	|		END AS DepreciationTD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.FixedAssetDepreciationTargetFinancing 
	|		ELSE 0 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationTaxAccountingTargetFinancing 
	|		ELSE 0 
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationTargetFinancingPD 
	|		ELSE 0 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationOfTargetFinancingTD 
	|		ELSE 0 
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	0                                          AS DepreciationRevaluationReserve,
	|	0                                          AS DepreciationRevaluationReserveLocal,
	|
	|	TTDepreciationWriteOff.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	TTDepreciationWriteOff.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.ExpenseItem             AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTDepreciationWriteOff.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	&BO_Depreciation                            AS BusinessOperation,
	|	
	|	TTDepreciationWriteOff.RowID  AS FinRecordID,
	|	&SettingUpHO_Depreciation                   AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffOfIa AS TTDepreciationWriteOff
	|		ON TTDepreciationWriteOff.Ref = DocumentData.Ref 
	|
	|		LEFT JOIN TT_CostOfVNA AS IACost
	|		ON IACost.AccountingObject = TTDepreciationWriteOff.IntangibleAsset
	|			AND IACost.Ref = TTDepreciationWriteOff.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting 
	|			AND TTDepreciationWriteOff.Depreciation <> 0
	|		OR DocumentData.RecordInLocalAccounting
	|			AND (TTDepreciationWriteOff.DepreciationLocal <> 0
	|				OR TTDepreciationWriteOff.DepreciationInTaxAccounting <> 0
	|				OR TTDepreciationWriteOff.DepreciationPermanentDifferences <> 0
	|				OR TTDepreciationWriteOff.DepreciationTD <> 0
	|				OR TTDepreciationWriteOff.FixedAssetDepreciationTargetFinancing <> 0))
	|
	|UNION ALL
	|
	|// Write-off of revaluation reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Department              AS Department,
	|	TTDepreciationWriteOff.IntangibleAsset  AS IntangibleAsset,
	|
	|	0                                          AS Depreciation,
	|	0                                          AS DepreciationLocal,
	|	0                                          AS DepreciationInTaxAccounting,
	|	0                                          AS DepreciationPermanentDifferences,
	|	0                                          AS DepreciationTD,
	|	0                                          AS FixedAssetDepreciationTargetFinancing,
	|	0                                          AS DepreciationTaxAccountingTargetFinancing,
	|	0                                          AS DepreciationTargetFinancingPD,
	|	0                                          AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationRevaluationReserve 
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	TTDepreciationWriteOff.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTDepreciationWriteOff.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem             AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTDepreciationWriteOff.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	&BT_ReserveDepreciation                      AS BusinessOperation,
	|	
	|	&IDOfUnusedFinRecord      AS FinRecordID,
	|	UNDEFINED                               AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffOfIa AS TTDepreciationWriteOff
	|		ON TTDepreciationWriteOff.Ref = DocumentData.Ref 
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND TTDepreciationWriteOff.DepreciationRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting
	|			AND TTDepreciationWriteOff.DepreciationRevaluationReserveLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableIACost(QueryTexts)

	RegisterName = "IACost";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTDepreciationWriteOffOfIa(QueryTexts);
	QueryTextTableTTImpairmentOfIaWriteOffs(QueryTexts);
	QueryTextTableTTResidualValueOfIa(QueryTexts);
	QueryTextTableTTCostOfIaWriteOff(QueryTexts);
	
	QueryText =
	"
	// Depreciation write-off
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	TTDepreciationWriteOff.IntangibleAsset AS IntangibleAsset,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTDepreciationWriteOff.Depreciation 
	|		ELSE 0 
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationLocal 
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInTA 
	|			THEN TTDepreciationWriteOff.DepreciationInTaxAccounting 
	|		ELSE 0 
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting
	|				OR DocumentData.RecordInTA
	|					AND ISNULL(TTResidualValue.LocalCost, 0) = 0
	|					AND ISNULL(TTResidualValue.CostTargetFinancing, 0) = 0
	|			THEN TTDepreciationWriteOff.DepreciationPermanentDifferences 
	|		ELSE 0 
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationLocal 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTDepreciationWriteOff.DepreciationInTaxAccounting 
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting
	|					OR DocumentData.RecordInTA
	|						AND ISNULL(TTResidualValue.LocalCost, 0) = 0
	|						AND ISNULL(TTResidualValue.CostTargetFinancing, 0) = 0
	|				THEN TTDepreciationWriteOff.DepreciationPermanentDifferences 
	|			ELSE 0 
	|		END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.FixedAssetDepreciationTargetFinancing 
	|		ELSE 0 
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationTaxAccountingTargetFinancing 
	|		ELSE 0 
	|	END AS CostTargetFinancingTA,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationTargetFinancingPD 
	|		ELSE 0 
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationOfTargetFinancingTD 
	|		ELSE 0 
	|	END AS CostTargetFinancingTD,
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTDepreciationWriteOff.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTDepreciationWriteOff.LineOfBusiness AS LineOfBusiness,
	|	&BO_Depreciation                        AS BusinessOperation,
	|	DocumentData.ExpenseItem         AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTDepreciationWriteOff.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	TTDepreciationWriteOff.RowID AS FinRecordID,
	|	&SettingUpHO_Depreciation               AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffOfIa AS TTDepreciationWriteOff
	|		ON TTDepreciationWriteOff.Ref = DocumentData.Ref 
	|
	|		LEFT JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON TTResidualValue.Ref = TTDepreciationWriteOff.Ref
	|			AND TTResidualValue.IntangibleAsset = TTDepreciationWriteOff.IntangibleAsset
	|
	|UNION ALL
	|
	// Write-off of residual value
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	TTResidualValue.IntangibleAsset AS IntangibleAsset,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost 
	|		ELSE 0 
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost 
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInTA 
	|			THEN TTResidualValue.CostInTaxAccounting 
	|		ELSE 0 
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|				OR DocumentData.RecordInTA
	|					AND ISNULL(TTResidualValue.LocalCost, 0) = 0
	|					AND ISNULL(TTResidualValue.CostTargetFinancing, 0) = 0
	|			THEN TTResidualValue.CostPermanentDifference 
	|		ELSE 0 
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTResidualValue.CostInTaxAccounting 
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting 
	|					OR DocumentData.RecordInTA
	|						AND ISNULL(TTResidualValue.LocalCost, 0) = 0
	|						AND ISNULL(TTResidualValue.CostTargetFinancing, 0) = 0
	|				THEN TTResidualValue.CostPermanentDifference 
	|			ELSE 0 
	|		END AS CostTemporaryDifference,
	|
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTResidualValue.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTResidualValue.LineOfBusiness AS LineOfBusiness,
	|	&BO_Cost                          AS BusinessOperation,
	|	DocumentData.ExpenseItem         AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTResidualValue.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	TTResidualValue.RowID AS FinRecordID,
	|	&SettingUpHO_Cost                 AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON TTResidualValue.Ref = DocumentData.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting 
	|			AND TTResidualValue.Cost <> 0
	|		OR DocumentData.RecordInLocalAccounting
	|			AND (TTResidualValue.LocalCost <> 0
	|				OR TTResidualValue.CostInTaxAccounting <> 0
	|				OR TTResidualValue.CostPermanentDifference <> 0
	|				OR TTResidualValue.CostTemporaryDifference <> 0))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	TTResidualValue.IntangibleAsset AS IntangibleAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancing 
	|		ELSE 0 
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancingTA 
	|		ELSE 0 
	|	END AS CostTargetFinancingTA,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancingPD 
	|		ELSE 0 
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancingTD 
	|		ELSE 0 
	|	END AS CostTargetFinancingTD,
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	
	|	TTResidualValue.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTResidualValue.LineOfBusiness AS LineOfBusiness,
	|	&BO_CostTargetFinancing                        AS BusinessOperation,
	|	DocumentData.ExpenseItem         AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTResidualValue.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	TTResidualValue.RowID AS FinRecordID,
	|	&SettingUpHO_CostTargetFinancing               AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON TTResidualValue.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.PostInAccounting
	|	AND (TTResidualValue.CostTargetFinancing <> 0
	|		OR TTResidualValue.CostTargetFinancingTA <> 0
	|		OR TTResidualValue.CostTargetFinancingPD <> 0
	|		OR TTResidualValue.CostTargetFinancingTD <> 0)
	|
	|UNION ALL
	|
	// Write-off of revaluation reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	CostOfWriteOffIsTT.IntangibleAsset  AS IntangibleAsset,
	|
	|	0                                        AS Cost,
	|	0                                        AS LocalCost,
	|	0                                        AS CostInTaxAccounting,
	|	0                                        AS CostPermanentDifference,
	|	0                                        AS CostTemporaryDifference,
	|	0                                        AS CostTargetFinancing,
	|	0                                        AS CostTargetFinancingTA,
	|	0                                        AS CostTargetFinancingPD,
	|	0                                        AS CostTargetFinancingTD,
	|	0                                        AS PreliminaryCostMan,
	|	0                                        AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostOfWriteOffIsTT.CostRevaluationReserve 
	|		ELSE 0 
	|	END AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostOfWriteOffIsTT.CostRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS CostRevaluationReserveLocal,
	|	
	|	0                                        AS CostGainMA,
	|	0                                        AS CostGainLocal,
	|
	|	CostOfWriteOffIsTT.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	CostOfWriteOffIsTT.LineOfBusiness AS LineOfBusiness,
	|	&BO_ReserveCost                      AS BusinessOperation,
	|	DocumentData.ExpenseItem           AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN CostOfWriteOffIsTT.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.WriteOffRevaluationReserveOfIntangibleAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostOfIaWriteOff AS CostOfWriteOffIsTT
	|		ON CostOfWriteOffIsTT.Ref = DocumentData.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND CostOfWriteOffIsTT.CostRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting
	|			AND CostOfWriteOffIsTT.CostRevaluationReserveLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	TableOfIA.IntangibleAsset           AS IntangibleAsset,
	|
	|	0                                        AS Cost,
	|	0                                        AS LocalCost,
	|	0                                        AS CostInTaxAccounting,
	|	0                                        AS CostPermanentDifference,
	|	0                                        AS CostTemporaryDifference,
	|	0                                        AS CostTargetFinancing,
	|	0                                        AS CostTargetFinancingTA,
	|	0                                        AS CostTargetFinancingPD,
	|	0                                        AS CostTargetFinancingTD,
	|	0                                        AS PreliminaryCostMan,
	|	0                                        AS PreliminaryCostLocal,
	|	0                                        AS CostRevaluationReserve,
	|	0                                        AS CostRevaluationReserveLocal,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TableOfIA.CostGainMA 
	|		ELSE 0 
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TableOfIA.CostGainLocal 
	|		ELSE 0 
	|	END AS CostGainLocal,
	|
	|	TableOfIA.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness       AS LineOfBusiness,
	|	&BO_ReserveCost                      AS BusinessOperation,
	|	DocumentData.ExpenseItem           AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TableOfIA.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.WriteOffRevaluationReserveOfIntangibleAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostOfIaWriteOff AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|			AND TableOfIA.CostGainMA <> 0
	|		OR DocumentData.PostInAccounting
	|			AND TableOfIA.CostGainLocal <> 0
	|
	|UNION ALL
	|
	// Write-off of other amounts
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)   AS RecordType,
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Department            AS Department,
	|	TableOfIA.IntangibleAsset           AS IntangibleAsset,
	|
	|	0                                        AS Cost,
	|	0                                        AS LocalCost,
	|	0                                        AS CostInTaxAccounting,
	|	0                                        AS CostPermanentDifference,
	|	0                                        AS CostTemporaryDifference,
	|	0                                        AS CostTargetFinancing,
	|	0                                        AS CostTargetFinancingTA,
	|	0                                        AS CostTargetFinancingPD,
	|	0                                        AS CostTargetFinancingTD,
	|
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|			THEN IACost.PreliminaryCostMan 
	|		ELSE 0 
	|	END AS PreliminaryCostMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|				AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|			THEN IACost.PreliminaryCostLocal 
	|		ELSE 0 
	|	END AS PreliminaryCostLocal,
	|
	|	0                                        AS CostRevaluationReserve,
	|	0                                        AS CostRevaluationReserveLocal,
	|	0                                        AS CostGainMA,
	|	0                                        AS CostGainLocal,
	|	
	|	TableOfIA.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness       AS LineOfBusiness,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	UNDEFINED                             AS CorExpenseItem,
	|	UNDEFINED                             AS CorExpenditureDimension,
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord   AS FinRecordID,
	|	UNDEFINED                            AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTTableOfIa AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref 
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|			AND IACost.PreliminaryCostMan <> 0
	|		OR DocumentData.PostInAccounting
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|			AND IACost.PreliminaryCostLocal <> 0
	|
	|UNION ALL
	|
	// Write-off of impairment
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)     AS RecordType,
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Department              AS Department,
	|	TableOfIA.IntangibleAsset             AS IntangibleAsset,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TableOfIA.ImpairmenMan 
	|		ELSE 0 
	|	END                                      AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TableOfIA.ImpairmentLocalAssets 
	|		ELSE 0 
	|	END                                      AS LocalCost,
	|
	|	0                                          AS CostInTaxAccounting,
	|	0                                          AS CostPermanentDifference,
	|	0                                          AS CostTemporaryDifference,
	|	0                                          AS CostTargetFinancing,
	|	0                                          AS CostTargetFinancingTA,
	|	0                                          AS CostTargetFinancingPD,
	|	0                                          AS CostTargetFinancingTD,
	|
	|	0                                          AS PreliminaryCostMan,
	|	0                                          AS PreliminaryCostLocal,
	|
	|	0                                          AS CostRevaluationReserve,
	|	0                                          AS CostRevaluationReserveLocal,
	|	0                                          AS CostGainMA,
	|	0                                          AS CostGainLocal,
	|	
	|	TableOfIA.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness         AS LineOfBusiness,
	|	&BO_Impairment                            AS BusinessOperation,
	|	DocumentData.ExpenseItem             AS CorExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TableOfIA.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	DocumentData.RecordInLocalAccounting         AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting          AS RecordInManAccounting,
	|	
	|	TableOfIA.RowID             AS FinRecordID,
	|	&SettingUpHO_Impairment                   AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTImpairmentOfIaWriteOffs AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting 
	|			AND TableOfIA.ImpairmenMan <> 0
	|		OR DocumentData.PostInAccounting 
	|			AND TableOfIA.ImpairmentLocalAssets <> 0) 
	|";

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
	
	QueryTextTableTTResidualValueOfIa(QueryTexts);
	QueryTextTableTTDepreciationWriteOffOfIa(QueryTexts);
	QueryTextTableTTCostOfIaWriteOff(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)         AS RecordType,
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	&BO_Cost                                  AS BusinessOperation,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TableOfIA.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TableOfIA.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	DocumentData.ExpenseItem                 AS AssetRef,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TableOfIA.IntangibleAsset
	|		ELSE DocumentData.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|
	|	TableOfIA.Cost                           AS Sum
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTResidualValueOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|WHERE
	|	TableOfIA.Cost <> 0
	|	AND VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|
	|UNION ALL
	|
	|// The revaluation reserve depreciation
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	&BT_ReserveDepreciation                  AS BusinessOperation,
	|	DocumentData.Organization            AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TableOfIA.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TableOfIA.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	&Ap_nmaArticle                          AS AssetRef,
	|	TableOfIA.IntangibleAsset         AS Dimension,
	|
	|	TableOfIA.DepreciationRevaluationReserve AS Sum
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTDepreciationWriteOffOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|WHERE
	|	TableOfIA.DepreciationRevaluationReserve <> 0
	|
	|UNION ALL
	|
	|// Revaluation reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	&BO_ReserveCost                    AS BusinessOperation,
	|	DocumentData.Organization            AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TableOfIA.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TableOfIA.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	&Ap_nmaArticle                          AS AssetRef,
	|	TableOfIA.IntangibleAsset         AS Dimension,
	|
	|	TableOfIA.CostRevaluationReserve   AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTCostOfIaWriteOff AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|WHERE
	|	TableOfIA.CostRevaluationReserve <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTResidualValueOfIa(QueryTexts);
	QueryTextTableTTDepreciationWriteOffOfIa(QueryTexts);
	QueryTextTableTTCostOfIaWriteOff(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	DocumentData.ExpenseItem           AS AssetRef,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTResidualValue.IntangibleAsset
	|		ELSE DocumentData.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|
	|	DocumentData.GLAccountSettings     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost + TTResidualValue.CostTargetFinancing 
	|		ELSE 0 
	|	END AS SumCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostPermanentDifference + TTResidualValue.CostTargetFinancingPD
	|		WHEN DocumentData.RecordInTA
	|				AND TTResidualValue.LocalCost = 0
	|			THEN TTResidualValue.CostPermanentDifference
	|		ELSE 0 
	|	END AS PermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost + TTResidualValue.CostTargetFinancing 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTResidualValue.CostInTaxAccounting
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting 
	|				THEN TTResidualValue.CostPermanentDifference + TTResidualValue.CostTargetFinancingPD
	|			WHEN DocumentData.RecordInTA
	|					AND TTResidualValue.LocalCost = 0
	|				THEN TTResidualValue.CostPermanentDifference
	|			ELSE 0 
	|		END AS CostTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost
	|		ELSE 0 
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost
	|		ELSE 0 
	|	END AS AmountExcludingVAT,
	|
	|	TTResidualValue.RowID AS FinRecordID,
	|	&SettingUpHO_Cost AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON DocumentData.Ref = TTResidualValue.Ref
	|
	|WHERE
	|	VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|
	|	AND (DocumentData.RecordInManAccounting
	|			AND TTResidualValue.Cost <> 0 
	|		OR DocumentData.RecordInLocalAccounting
	|			AND (TTResidualValue.LocalCost <> 0 
	|				OR TTResidualValue.CostInTaxAccounting <> 0
	|				OR TTResidualValue.CostTargetFinancing <> 0))
	|
	|UNION ALL
	|
	|// The revaluation reserve depreciation
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Department      AS Department,
	|	TTDepreciationWriteOff.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                      AS AssetRef,
	|	TTDepreciationWriteOff.IntangibleAsset AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTDepreciationWriteOff.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS AmountExcludingVAT,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	&SettingUpHO_ReserveDepreciation AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffOfIa AS TTDepreciationWriteOff
	|		ON DocumentData.Ref = TTDepreciationWriteOff.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND TTDepreciationWriteOff.DepreciationRevaluationReserve <> 0 
	|		OR DocumentData.PostInAccounting
	|			AND TTDepreciationWriteOff.DepreciationRevaluationReserveLocal <> 0)
	|
	|UNION ALL
	|
	|// Revaluation reserve
	|SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Department      AS Department,
	|	CostOfWriteOffIsTT.LineOfBusiness AS LineOfBusiness,
	|	&Ap_nmaArticle                      AS AssetRef,
	|	CostOfWriteOffIsTT.IntangibleAsset AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostOfWriteOffIsTT.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostOfWriteOffIsTT.CostRevaluationReserve
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostOfWriteOffIsTT.CostRevaluationReserve
	|		ELSE 0 
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostOfWriteOffIsTT.CostRevaluationReserve
	|		ELSE 0 
	|	END AS AmountExcludingVAT,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	&SettingUpHO_ReserveCost AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostOfIaWriteOff AS CostOfWriteOffIsTT
	|		ON DocumentData.Ref = CostOfWriteOffIsTT.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND CostOfWriteOffIsTT.CostRevaluationReserve <> 0 
	|		OR DocumentData.PostInAccounting
	|			AND CostOfWriteOffIsTT.CostRevaluationReserveLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = DisposeIntangibleAssetsLocalization.QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryTextTableTTResidualValueOfIa(QueryTexts);
		
		QueryText =
		"// Depreciation write-off
		|SELECT
		|	DocumentData.Ref             AS Recorder,
		|	DocumentData.Period             AS Period,
		|	&BO_Depreciation                    AS BusinessOperation,
		|	DocumentData.Organization        AS Organization,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|			THEN TableOfIA.Department
		|		ELSE DocumentData.ExpensesBusinessUnit
		|	END AS Department,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|			THEN TableOfIA.LineOfBusiness
		|		ELSE DocumentData.ExpenseLineOfBusiness
		|	END AS LineOfBusiness,
		|
		|	DocumentData.ExpenseItem     AS AssetRef,
		|	UNDEFINED                       AS DimensionOfRevenue,
		|
		|	CASE
		|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
		|			THEN TableOfIA.IntangibleAsset
		|		ELSE DocumentData.DimensionOfExpenses
		|	END AS DimensionOfExpenses,
		|
		|	TableOfIA.IntangibleAsset     AS AssetsLiabilitiesDimension,
		|	TableOfIA.FinancialAccountingGroup  AS FinancialAccountingGroup,
		|
		|	DocumentData.Department      AS DebitBusinessUnit,
		|	TableOfIA.LineOfBusiness AS CorLineOfBusiness,
		|	&Ap_nmaArticle                      AS CorItem,
		|	UNDEFINED                       AS CorIncomeDimension,
		|	UNDEFINED                       AS CorExpenditureDimension,
		|	TableOfIA.IntangibleAsset     AS CorDimensionOfAssetsLiabilities,
		|	TableOfIA.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN TableOfIA.Depreciation 
		|		ELSE 0 
		|	END AS Sum,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN TableOfIA.Depreciation 
		|		ELSE 0 
		|	END AS SumMan,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN TableOfIA.DepreciationLocal + TableOfIA.FixedAssetDepreciationTargetFinancing 
		|		ELSE 0 
		|	END AS SumCompl
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTDepreciationWriteOffOfIa AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|
		|UNION ALL
		|
		|// Write-off of residual value
		|SELECT
		|	NestedQuery.Ref AS Recorder,
		|	NestedQuery.Period AS Period,
		|	NestedQuery.BusinessOperation AS BusinessOperation,
		|	NestedQuery.Organization AS Organization,
		|
		|	NestedQuery.Department AS Department,
		|	NestedQuery.LineOfBusiness AS LineOfBusiness,
		|	NestedQuery.AssetRef AS AssetRef,
		|	NestedQuery.DimensionOfRevenue AS DimensionOfRevenue,
		|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
		|	NestedQuery.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	NestedQuery.FinancialAccountingGroup AS FinancialAccountingGroup,
		|
		|	NestedQuery.DebitBusinessUnit AS DebitBusinessUnit,
		|	NestedQuery.CorLineOfBusiness AS CorLineOfBusiness,
		|	NestedQuery.CorItem AS CorItem,
		|	NestedQuery.CorIncomeDimension AS CorIncomeDimension,
		|	NestedQuery.CorExpenditureDimension AS CorExpenditureDimension,
		|	NestedQuery.CorDimensionOfAssetsLiabilities AS CorDimensionOfAssetsLiabilities,
		|	NestedQuery.CorFinancialAccountingGroup AS CorFinancialAccountingGroup,
		|
		|	CASE 
		|		WHEN NestedQuery.RecordInManAccounting 
		|			THEN SUM(NestedQuery.Sum) 
		|		ELSE 0 
		|	END AS Sum,
		|
		|	CASE 
		|		WHEN NestedQuery.RecordInManAccounting 
		|			THEN SUM(NestedQuery.SumMan) 
		|		ELSE 0 
		|	END AS SumMan,
		|
		|	CASE 
		|		WHEN NestedQuery.PostInAccounting 
		|			THEN SUM(NestedQuery.SumCompl) 
		|		ELSE 0 
		|	END AS SumCompl
		|
		|FROM
		|	(SELECT
		|		DocumentData.Ref             AS Ref,
		|		DocumentData.Period             AS Period,
		|		&BO_Cost                      AS BusinessOperation,
		|		DocumentData.Organization        AS Organization,
		|		DocumentData.RecordInManAccounting  AS RecordInManAccounting,
		|		DocumentData.PostInAccounting        AS PostInAccounting,
		|
		|		DocumentData.Department      AS Department,
		|		TableOfIA.LineOfBusiness AS LineOfBusiness,
		|
		|		&Ap_nmaArticle                      AS AssetRef,
		|		UNDEFINED                       AS DimensionOfRevenue,
		|		UNDEFINED                       AS DimensionOfExpenses,
		|		TableOfIA.IntangibleAsset     AS AssetsLiabilitiesDimension,
		|		TableOfIA.FinancialAccountingGroup  AS FinancialAccountingGroup,
		|
		|		CASE
		|			WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|				THEN TableOfIA.Department
		|			ELSE DocumentData.ExpensesBusinessUnit
		|		END AS DebitBusinessUnit,
		|
		|		CASE
		|			WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|				THEN TableOfIA.LineOfBusiness
		|			ELSE DocumentData.ExpenseLineOfBusiness
		|		END AS CorLineOfBusiness,
		|
		|		DocumentData.ExpenseItem     AS CorItem,
		|		UNDEFINED                       AS CorIncomeDimension,
		|
		|		CASE
		|			WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
		|				THEN TableOfIA.IntangibleAsset
		|			ELSE DocumentData.DimensionOfExpenses
		|		END AS CorExpenditureDimension,
		|
		|		UNDEFINED                       AS CorDimensionOfAssetsLiabilities,
		|		TableOfIA.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
		|
		|		TableOfIA.Cost               AS Sum,
		|		TableOfIA.Cost               AS SumMan,
		|		TableOfIA.LocalCost + TableOfIA.CostTargetFinancing AS SumCompl
		|	FROM
		|		DocumentDataDetails AS DocumentData
		|
		|			LEFT JOIN TTResidualValueOfIa AS TableOfIA
		|			ON DocumentData.Ref = TableOfIA.Ref
		|
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Ref,
		|	NestedQuery.Period,
		|	NestedQuery.BusinessOperation,
		|	NestedQuery.Organization,
		|	NestedQuery.RecordInManAccounting,
		|	NestedQuery.PostInAccounting,
		|
		|	NestedQuery.Department,
		|	NestedQuery.LineOfBusiness,
		|	NestedQuery.AssetRef,
		|	NestedQuery.DimensionOfRevenue,
		|	NestedQuery.DimensionOfExpenses,
		|	NestedQuery.AssetsLiabilitiesDimension,
		|	NestedQuery.FinancialAccountingGroup,
		|
		|	NestedQuery.DebitBusinessUnit,
		|	NestedQuery.CorLineOfBusiness,
		|	NestedQuery.CorItem,
		|	NestedQuery.CorIncomeDimension,
		|	NestedQuery.CorExpenditureDimension,
		|	NestedQuery.CorDimensionOfAssetsLiabilities,
		|	NestedQuery.CorFinancialAccountingGroup
		|
		|UNION ALL
		|
		|// Write-off of the revaluation reserve for depreciation of IA
		|SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	&BT_ReserveDepreciation                   AS BusinessOperation,
		|	DocumentData.Organization             AS Organization,
		|
		|	DocumentData.Department           AS Department,
		|	TableOfIA.LineOfBusiness      AS LineOfBusiness,
		|
		|	&Ap_nmaArticle                           AS AssetRef,
		|	UNDEFINED                            AS DimensionOfRevenue,
		|	UNDEFINED                            AS DimensionOfExpenses,
		|	TableOfIA.IntangibleAsset          AS AssetsLiabilitiesDimension,
		|	TableOfIA.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|			THEN TableOfIA.Department
		|		ELSE DocumentData.ExpensesBusinessUnit
		|	END AS DebitBusinessUnit,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|			THEN TableOfIA.LineOfBusiness
		|		ELSE DocumentData.ExpenseLineOfBusiness
		|	END AS CorLineOfBusiness,
		|
		|	&Article6_ProfitLoss                 AS CorItem,
		|	UNDEFINED                            AS CorIncomeDimension,
		|	UNDEFINED                            AS CorExpenditureDimension,
		|	UNDEFINED                            AS CorDimensionOfAssetsLiabilities,
		|	TableOfIA.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN TableOfIA.DepreciationRevaluationReserve 
		|		ELSE 0 
		|	END AS Sum,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN TableOfIA.DepreciationRevaluationReserve 
		|		ELSE 0 
		|	END AS SumMan,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN TableOfIA.DepreciationRevaluationReserveLocal 
		|		ELSE 0 
		|	END AS SumCompl
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTDepreciationWriteOffOfIa AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|
		|WHERE
		|	DocumentData.RecordInManAccounting AND TableOfIA.DepreciationRevaluationReserve <> 0
		|		OR DocumentData.PostInAccounting AND TableOfIA.DepreciationRevaluationReserveLocal <> 0
		|
		|UNION ALL
		|
		|// Write-off of revaluation reserve value of the intangible assets
		|SELECT
		|	DocumentData.Ref                 AS Recorder,
		|	DocumentData.Period                 AS Period,
		|	&BO_ReserveCost                    AS BusinessOperation,
		|	DocumentData.Organization            AS Organization,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|			THEN TableOfIA.Department
		|		ELSE DocumentData.ExpensesBusinessUnit
		|	END AS Department,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
		|			THEN TableOfIA.LineOfBusiness
		|		ELSE DocumentData.ExpenseLineOfBusiness
		|	END AS LineOfBusiness,
		|
		|	&Article6_ProfitLoss                AS AssetRef,
		|	UNDEFINED                           AS DimensionOfRevenue,
		|	UNDEFINED                           AS DimensionOfExpenses,
		|	UNDEFINED                           AS AssetsLiabilitiesDimension,
		|	TableOfIA.FinancialAccountingGroup      AS FinancialAccountingGroup,
		|
		|	DocumentData.Department          AS DebitBusinessUnit,
		|	TableOfIA.LineOfBusiness     AS CorLineOfBusiness,
		|	&Ap_nmaArticle                          AS CorItem,
		|	UNDEFINED                           AS CorIncomeDimension,
		|	UNDEFINED                           AS CorExpenditureDimension,
		|	TableOfIA.IntangibleAsset         AS CorDimensionOfAssetsLiabilities,
		|	TableOfIA.FinancialAccountingGroup      AS CorFinancialAccountingGroup,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN TableOfIA.CostRevaluationReserve 
		|		ELSE 0 
		|	END AS Sum,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN TableOfIA.CostRevaluationReserve 
		|		ELSE 0 
		|	END AS SumMan,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN TableOfIA.CostRevaluationReserveLocal 
		|		ELSE 0 
		|	END AS SumCompl
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTCostOfIaWriteOff AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|
		|WHERE
		|	DocumentData.RecordInManAccounting AND TableOfIA.CostRevaluationReserve <> 0
		|		OR DocumentData.PostInAccounting AND TableOfIA.CostRevaluationReserveLocal <> 0
		|";

	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableImpairmentFA(QueryTexts)

	RegisterName = "ImpairmentFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTImpairmentOfIaWriteOffs(QueryTexts);
	
	QueryText =
	"// Write-off of impairment
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Department              AS Department,
	|	TableOfIA.IntangibleAsset             AS NonCurrentAsset,
	|	TableOfIA.CGU                            AS CGU,
	|
	|	TableOfIA.ImpairmenMan                  AS ImpairmenMan,
	|	TableOfIA.ImpairmentLocalAssets                 AS ImpairmentLocalAssets,
	|
	|	TableOfIA.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.ExpenseItem             AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses          AS CorExpenditureDimension,
	|	&BO_Impairment                            AS BusinessOperation,
	|	
	|	TableOfIA.RowID             AS FinRecordID,
	|	&SettingUpHO_Impairment                   AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTImpairmentOfIaWriteOffs AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	QueryTextTableTTResidualValueOfIa(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));

	QueryText =
	"SELECT
	|	DocumentData.Period                            AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	DocumentData.Organization                       AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem                    AS ExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTResidualValue.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                      AS VATActivityType,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost 
	|		ELSE 0 
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost 
	|		ELSE 0 
	|	END AS AmountExcludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTResidualValue.Cost  
	|		ELSE 0 
	|	END AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost 
	|		ELSE 0 
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost 
	|		ELSE 0 
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting
	|				OR DocumentData.RecordInTA
	|					AND TTResidualValue.LocalCost = 0
	|			THEN TTResidualValue.CostPermanentDifference
	|		ELSE 0 
	|	END AS PermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.LocalCost 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTResidualValue.CostInTaxAccounting 
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting
	|					OR DocumentData.RecordInTA
	|						AND TTResidualValue.LocalCost = 0
	|				THEN TTResidualValue.CostPermanentDifference
	|			ELSE 0 
	|		END AS CostTD,
	|	
	|	&BO_Cost AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TTResidualValue.RowID AS FinRecordID,
	|	&SettingUpHO_Cost AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON DocumentData.Ref = TTResidualValue.Ref
	|
	|WHERE
	|	VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|
	|	AND (DocumentData.RecordInManAccounting 
	|			AND TTResidualValue.Cost <> 0
	|		OR DocumentData.RecordInLocalAccounting
	|			AND (TTResidualValue.LocalCost <> 0
	|				OR TTResidualValue.CostPermanentDifference <> 0
	|				OR TTResidualValue.CostTemporaryDifference <> 0))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Period                            AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	DocumentData.Organization                       AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem                    AS ExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTResidualValue.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                      AS VATActivityType,
	|	
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancing 
	|		ELSE 0 
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancing 
	|		ELSE 0 
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancingPD
	|		ELSE 0 
	|	END AS PermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTResidualValue.CostTargetFinancingTD 
	|		ELSE 0 
	|	END AS CostTD,
	|	
	|	&BO_Cost AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TTResidualValue.RowID AS FinRecordID,
	|	&SettingUpHO_CostTargetFinancing AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON DocumentData.Ref = TTResidualValue.Ref
	|
	|WHERE
	|	VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|
	|	AND DocumentData.PostInAccounting
	|		AND (TTResidualValue.CostTargetFinancing <> 0
	|			OR TTResidualValue.CostTargetFinancingPD <> 0
	|			OR TTResidualValue.CostTargetFinancingTD <> 0)
	|";
	ListOfMergeRequests.Add(QueryText);
	
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

Function QueryTextTableTTInitialBatchesOfOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	QueryTextTableTTResidualValueOfIa(QueryTexts);
	
	QueriesArray = New Array;
	QueriesArray.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses(Add_Fields));
	
	QueryText =
	"SELECT
	|	DocumentData.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToIAToWriteOff
	|			THEN TTResidualValue.IntangibleAsset
	|		ELSE DocumentData.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	DocumentData.Ref AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TTResidualValue.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TTResidualValue.Cost
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TTResidualValue.Cost
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|
	|	0 AS VATManag,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN TTResidualValue.LocalCost + TTResidualValue.CostTargetFinancing
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|
	|			THEN TTResidualValue.CostPermanentDifference + TTResidualValue.CostTargetFinancingPD
	|
	|		WHEN DocumentData.RecordInTA
	|				AND TTResidualValue.LocalCost = 0
	|				AND TTResidualValue.CostTargetFinancing = 0
	|
	|			THEN TTResidualValue.CostPermanentDifference
	|
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN TTResidualValue.LocalCost + TTResidualValue.CostTargetFinancing
	|		ELSE 0
	|	END
	|		- CASE
	|			WHEN DocumentData.RecordInTA
	|				THEN TTResidualValue.CostInTaxAccounting
	|			ELSE 0
	|		END
	|		- CASE
	|			WHEN DocumentData.PostInAccounting
	|
	|				THEN TTResidualValue.CostPermanentDifference + TTResidualValue.CostTargetFinancingPD
	|
	|			WHEN DocumentData.RecordInTA
	|					AND TTResidualValue.LocalCost = 0
	|					AND TTResidualValue.CostTargetFinancing = 0
	|
	|				THEN TTResidualValue.CostPermanentDifference
	|
	|			ELSE 0
	|		END AS CostTD,
	|
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	
	|	TTResidualValue.RowID AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTResidualValueOfIa AS TTResidualValue
	|		ON DocumentData.Ref = TTResidualValue.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting 
	|			AND TTResidualValue.Cost <> 0
	|		OR DocumentData.RecordInLocalAccounting
	|			AND (TTResidualValue.LocalCost <> 0
	|				OR TTResidualValue.CostPermanentDifference <> 0
	|				OR TTResidualValue.CostTemporaryDifference <> 0
	|				OR TTResidualValue.CostTargetFinancing <> 0
	|				OR TTResidualValue.CostTargetFinancingPD <> 0))
	|";
	QueriesArray.Add(QueryText);
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
		
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

Procedure QueryTextTableTTCostOfIaWriteOff(QueryTexts)

	TableName = "TTCostOfIaWriteOff";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTTableOfIa(QueryTexts);
	
	
	QueryText =
	"// Depreciation write-off
	|SELECT
	|	DocumentData.Ref                     AS Ref,
	|	TableOfIA.IntangibleAsset             AS IntangibleAsset,
	|
	|	IntangibleAssetsAmortizationCharge.Depreciation                 AS Cost,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal             AS LocalCost,
	|	IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting               AS CostInTaxAccounting,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences               AS CostPermanentDifference,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD               AS CostTemporaryDifference,
	|	IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing               AS CostTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing             AS CostTargetFinancingTA,
	|	IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD             AS CostTargetFinancingPD,
	|	IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD             AS CostTargetFinancingTD,
	|	IACost.CostRevaluationReserve     AS CostRevaluationReserve,
	|	IACost.CostRevaluationReserveLocal AS CostRevaluationReserveLocal,
	|	IACost.CostGainMA              AS CostGainMA,
	|	IACost.CostGainLocal          AS CostGainLocal,
	|
	|	1                                          AS PercentageOfWriteOffs,
	|	1                                          AS ACWriteOffPercentage,
	|	1                                          AS PercentageOfCFWriteOffs,
	|	1                                          AS ShareOfWriteOffTa,
	|	1                                          AS ShareOfNUCFWriteOff,
	|	1                                          AS ShareOfPDWriteOffs,
	|	1                                          AS ShareOfWriteOffOfPRTF,
	|	
	|	TableOfIA.Department                   AS Department,
	|	TableOfIA.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness         AS LineOfBusiness,
	|	TableOfIA.IncomeItem                   AS IncomeItem,
	|	TableOfIA.DimensionOfRevenue                AS DimensionOfRevenue,
	|	
	|	TableOfIA.RowID             AS RowID
	|
	|INTO TTCostOfIaWriteOff
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTTableOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|
	|UNION ALL
	|
	|// Write-off of partial cost
	|SELECT DISTINCT
	|	DocumentData.Ref         AS Ref,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|
	|	TableOfIA.AmountManagementAccounting  AS Cost,
	|	TableOfIA.ChargeAmountAccounting - TableOfIA.ChargeAmountAccounting * IACost.ShareOfCentralBank AS LocalCost,
	|	TableOfIA.AmountTaxAccounting - TableOfIA.AmountTaxAccounting * IACost.CFNUShare AS CostInTaxAccounting,
	|	TableOfIA.AmountPermanentDifference - TableOfIA.AmountPermanentDifference * IACost.CfprShare AS CostPermanentDifference,
	|
	|	CAST((TableOfIA.ChargeAmountAccounting - TableOfIA.ChargeAmountAccounting * IACost.ShareOfCentralBank) AS NUMBER(31,2))
	|	- CAST((TableOfIA.AmountTaxAccounting - TableOfIA.AmountTaxAccounting * IACost.CFNUShare) AS NUMBER(31,2))
	|	- CAST((TableOfIA.AmountPermanentDifference - TableOfIA.AmountPermanentDifference * IACost.CfprShare) AS NUMBER(31,2)) AS CostTemporaryDifference,
	|
	|	TableOfIA.ChargeAmountAccounting * IACost.ShareOfCentralBank AS CostTargetFinancing,
	|	TableOfIA.AmountTaxAccounting * IACost.CFNUShare AS CostTargetFinancingTA,
	|	TableOfIA.AmountPermanentDifference * IACost.CfprShare AS CostTargetFinancingPD,
	|
	|	CAST((TableOfIA.ChargeAmountAccounting * IACost.ShareOfCentralBank) AS NUMBER(31,2))
	|	- CAST((TableOfIA.AmountTaxAccounting * IACost.CFNUShare) AS NUMBER(31,2))
	|	- CAST((TableOfIA.AmountPermanentDifference * IACost.CfprShare) AS NUMBER(31,2)) AS CostTargetFinancingTD,
	|	
	|
	|	IACost.CostRevaluationReserve
	|	* CASE WHEN ISNULL(IACost.Cost, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountManagementAccounting AS NUMBER(31, 10)) 
	|				/ IACost.Cost AS NUMBER(31, 10))
	|	END AS CostRevaluationReserve,
	|
	|	IACost.CostRevaluationReserveLocal
	|	* CASE WHEN ISNULL(IACost.Cost, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.ChargeAmountAccounting AS NUMBER(31, 10)) 
	|				/ IACost.Cost AS NUMBER(31, 10))
	|	END AS CostRevaluationReserveLocal,
	|
	|	IACost.CostGainMA
	|	* CASE WHEN ISNULL(IACost.Cost, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountManagementAccounting AS NUMBER(31, 10))
	|				/ IACost.Cost AS NUMBER(31, 10))
	|	END AS CostGainMA,
	|
	|	IACost.CostGainLocal
	|	* CASE WHEN ISNULL(IACost.Cost, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.ChargeAmountAccounting AS NUMBER(31, 10)) 
	|				/ IACost.Cost AS NUMBER(31, 10))
	|	END AS CostGainLocal,
	|
	|	CASE WHEN ISNULL(IACost.Cost, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountManagementAccounting AS NUMBER(31, 10)) 
	|						/ IACost.Cost AS NUMBER(31, 10))
	|	END AS PercentageOfWriteOffs,
	|
	|	CASE WHEN ISNULL(IACost.LocalCost, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.ChargeAmountAccounting - TableOfIA.ChargeAmountAccounting * IACost.ShareOfCentralBank AS NUMBER(31, 10)) 
	|						/ IACost.LocalCost AS NUMBER(31, 10))
	|	END AS ACWriteOffPercentage,
	|
	|	CASE WHEN ISNULL(IACost.CostTargetFinancing, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.ChargeAmountAccounting * IACost.ShareOfCentralBank AS NUMBER(31, 10)) 
	|						/ IACost.CostTargetFinancing AS NUMBER(31, 10))
	|	END AS PercentageOfCFWriteOffs,
	|
	|	CASE WHEN ISNULL(IACost.CostInTaxAccounting, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountTaxAccounting - TableOfIA.AmountTaxAccounting * IACost.CFNUShare AS NUMBER(31, 10)) 
	|						/ IACost.CostInTaxAccounting AS NUMBER(31, 10))
	|	END AS ShareOfWriteOffTa,
	|
	|	CASE WHEN ISNULL(IACost.CostTargetFinancingTA, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountTaxAccounting * IACost.CFNUShare AS NUMBER(31, 10)) 
	|						/ IACost.CostTargetFinancingTA AS NUMBER(31, 10))
	|	END AS ShareOfNUCFWriteOff,
	|
	|	CASE WHEN ISNULL(IACost.CostPermanentDifference, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountPermanentDifference - TableOfIA.AmountPermanentDifference * IACost.CfprShare AS NUMBER(31, 10)) 
	|						/ IACost.CostPermanentDifference AS NUMBER(31, 10))
	|	END AS ShareOfPDWriteOffs,
	|
	|	CASE WHEN ISNULL(IACost.CostTargetFinancingPD, 0) = 0
	|		THEN 1
	|		ELSE CAST(CAST(TableOfIA.AmountPermanentDifference * IACost.CfprShare AS NUMBER(31, 10)) 
	|						/ IACost.CostTargetFinancingPD AS NUMBER(31, 10))
	|	END AS ShareOfWriteOffOfPRTF,
	|
	|	TableOfIA.Department           AS Department,
	|	TableOfIA.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness AS LineOfBusiness,
	|	TableOfIA.IncomeItem           AS IncomeItem,
	|	TableOfIA.DimensionOfRevenue        AS DimensionOfRevenue,
	|	
	|	TableOfIA.RowID     AS RowID
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTTableOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTDepreciationWriteOffOfIa(QueryTexts)

	TableName = "TTDepreciationWriteOffOfIa";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTTableOfIa(QueryTexts);
	QueryTextTableTTCostOfIaWriteOff(QueryTexts);
	
	QueryText =
	"// Depreciation write-off
	|SELECT
	|	DocumentData.Ref                         AS Ref,
	|	TableOfIA.IntangibleAsset                 AS IntangibleAsset,
	|
	|	IntangibleAssetsAmortizationCharge.Depreciation                     AS Depreciation,
	|	IntangibleAssetsAmortizationCharge.DepreciationLocal                 AS DepreciationLocal,
	|	IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting                   AS DepreciationInTaxAccounting,
	|	IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences                   AS DepreciationPermanentDifferences,
	|	IntangibleAssetsAmortizationCharge.DepreciationTD                   AS DepreciationTD,
	|	IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing                   AS FixedAssetDepreciationTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing                 AS DepreciationTaxAccountingTargetFinancing,
	|	IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD                 AS DepreciationTargetFinancingPD,
	|	IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD                 AS DepreciationOfTargetFinancingTD,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve     AS DepreciationRevaluationReserve,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal,
	|
	|	TableOfIA.Department                       AS Department,
	|	TableOfIA.FinancialAccountingGroup              AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness             AS LineOfBusiness,
	|	&BO_Depreciation                                AS BusinessOperation,
	|	
	|	TableOfIA.RowID                 AS RowID
	|
	|INTO TTDepreciationWriteOffOfIa
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTTableOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|
	|UNION ALL
	|
	|// Write-off of partial depreciation
	|SELECT
	|	DocumentData.Ref                    AS Ref,
	|	CostOfWritingOffIA.IntangibleAsset  AS IntangibleAsset,
	|
	// Depreciation
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.Depreciation = ISNULL(IACost.Cost, 0)
	|			THEN CostOfWritingOffIA.Cost
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.Depreciation * CostOfWritingOffIA.PercentageOfWriteOffs AS NUMBER(31,2))
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.DepreciationLocal = ISNULL(IACost.LocalCost, 0)
	|			THEN CostOfWritingOffIA.LocalCost
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationLocal * CostOfWritingOffIA.ACWriteOffPercentage AS NUMBER(31,2))
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting = ISNULL(IACost.CostInTaxAccounting, 0)
	|			THEN CostOfWritingOffIA.CostInTaxAccounting
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting * CostOfWritingOffIA.ShareOfWriteOffTa AS NUMBER(31,2))
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences = ISNULL(IACost.CostPermanentDifference, 0)
	|			THEN CostOfWritingOffIA.CostPermanentDifference
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences * CostOfWritingOffIA.ShareOfPDWriteOffs AS NUMBER(31,2))
	|	END AS DepreciationPermanentDifferences,
	|
	// DepreciationTD
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.DepreciationLocal = ISNULL(IACost.LocalCost, 0)
	|			THEN CostOfWritingOffIA.LocalCost
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationLocal * CostOfWritingOffIA.ACWriteOffPercentage AS NUMBER(31,2))
	|	END
	|		- CASE
	|				WHEN IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting = ISNULL(IACost.CostInTaxAccounting, 0)
	|					THEN CostOfWritingOffIA.CostInTaxAccounting
	|				ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting * CostOfWritingOffIA.ShareOfWriteOffTa AS NUMBER(31,2))
	|			END
	|		- CASE
	|				WHEN IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences = ISNULL(IACost.CostPermanentDifference, 0)
	|					THEN CostOfWritingOffIA.CostPermanentDifference
	|				ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences * CostOfWritingOffIA.ShareOfPDWriteOffs AS NUMBER(31,2))
	|			END AS DepreciationTD,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing = ISNULL(IACost.CostTargetFinancing, 0)
	|			THEN CostOfWritingOffIA.CostTargetFinancing
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing * CostOfWritingOffIA.PercentageOfCFWriteOffs AS NUMBER(31,2))
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTaxAccountingTargetFinancing
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing = ISNULL(IACost.CostTargetFinancingTA, 0)
	|			THEN CostOfWritingOffIA.CostTargetFinancingTA
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing * CostOfWritingOffIA.ShareOfNUCFWriteOff AS NUMBER(31,2))
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD = ISNULL(IACost.CostTargetFinancingPD, 0)
	|			THEN CostOfWritingOffIA.CostTargetFinancingPD
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD * CostOfWritingOffIA.ShareOfWriteOffOfPRTF AS NUMBER(31,2))
	|	END AS DepreciationTargetFinancingPD,
	|
	// DepreciationOfTargetFinancingTD
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing = ISNULL(IACost.CostTargetFinancing, 0)
	|			THEN CostOfWritingOffIA.CostTargetFinancing
	|		ELSE CAST(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing * CostOfWritingOffIA.PercentageOfCFWriteOffs AS NUMBER(31,2))
	|	END
	|		- CASE
	|				WHEN IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing = ISNULL(IACost.CostTargetFinancingTA, 0)
	|					THEN CostOfWritingOffIA.CostTargetFinancingTA
	|				ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing * CostOfWritingOffIA.ShareOfNUCFWriteOff AS NUMBER(31,2))
	|			END
	|		- CASE
	|				WHEN IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD = ISNULL(IACost.CostTargetFinancingPD, 0)
	|					THEN CostOfWritingOffIA.CostTargetFinancingPD
	|				ELSE CAST(IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD * CostOfWritingOffIA.ShareOfWriteOffOfPRTF AS NUMBER(31,2))
	|			END AS DepreciationOfTargetFinancingTD,
	|
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve                   AS DepreciationRevaluationReserve,
	|	IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocal               AS DepreciationRevaluationReserveLocal,
	|
	|	CostOfWritingOffIA.Department                           AS Department,
	|	CostOfWritingOffIA.FinancialAccountingGroup                  AS FinancialAccountingGroup,
	|	CostOfWritingOffIA.LineOfBusiness                 AS LineOfBusiness,
	|	&BO_Depreciation                                              AS BusinessOperation,
	|	CostOfWritingOffIA.RowID                     AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON DocumentData.Ref = IntangibleAssetsAmortizationCharge.Ref
	|
	|		INNER JOIN TTCostOfIaWriteOff AS CostOfWritingOffIA
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = CostOfWritingOffIA.IntangibleAsset
	|			AND IntangibleAssetsAmortizationCharge.Ref = CostOfWritingOffIA.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS IACost
	|		ON IntangibleAssetsAmortizationCharge.AccountingObject = IACost.AccountingObject
	|			AND IntangibleAssetsAmortizationCharge.Ref = IACost.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|
	|INDEX BY
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTImpairmentOfIaWriteOffs(QueryTexts)

	TableName = "TTImpairmentOfIaWriteOffs";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTCostOfIaWriteOff(QueryTexts);
	
	QueryText =
	"// The write-off of the IA impairment is complete.
	|SELECT
	|	DocumentData.Ref                         AS Ref,
	|	TableOfIA.IntangibleAsset                 AS IntangibleAsset,
	|
	|	ImpairmentIA.CGU                            AS CGU,
	|
	|	ImpairmentIA.ImpairmenMan                  AS ImpairmenMan,
	|	ImpairmentIA.ImpairmentLocalAssets                 AS ImpairmentLocalAssets,
	|
	|	TableOfIA.FinancialAccountingGroup              AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness             AS LineOfBusiness,
	|	&BO_Impairment                                AS BusinessOperation,
	|	
	|	TableOfIA.RowID                 AS RowID
	|
	|INTO TTImpairmentOfIaWriteOffs
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTTableOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentIA
	|		ON ImpairmentIA.Ref = TableOfIA.Ref
	|			AND ImpairmentIA.AccountingObject = TableOfIA.IntangibleAsset
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|
	|UNION ALL
	|
	|// Partial write-off of IA impairment.
	|SELECT
	|	DocumentData.Ref                         AS Ref,
	|	TableOfIA.IntangibleAsset                 AS IntangibleAsset,
	|
	|	ImpairmentIA.CGU                            AS CGU,
	|
	|	ImpairmentIA.ImpairmenMan 
	|		* TTCostOfIaWriteOff.PercentageOfWriteOffs      AS ImpairmenMan,
	|	
	|	ImpairmentIA.ImpairmentLocalAssets 
	|		* TTCostOfIaWriteOff.ACWriteOffPercentage    AS ImpairmentLocalAssets,
	|
	|	TableOfIA.FinancialAccountingGroup              AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness             AS LineOfBusiness,
	|	&BO_Impairment                                AS BusinessOperation,
	|	
	|	TableOfIA.RowID                 AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTTableOfIa AS TableOfIA
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentIA
	|		ON ImpairmentIA.Ref = TableOfIA.Ref
	|			AND ImpairmentIA.AccountingObject = TableOfIA.IntangibleAsset
	|
	|		INNER JOIN TTCostOfIaWriteOff AS TTCostOfIaWriteOff
	|		ON TTCostOfIaWriteOff.Ref = TableOfIA.Ref
	|			AND TTCostOfIaWriteOff.IntangibleAsset = TableOfIA.IntangibleAsset
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTResidualValueOfIa(QueryTexts) Export

	TableName = "TTResidualValueOfIa";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTTableOfIa(QueryTexts);
	QueryTextTableTTDepreciationWriteOffOfIa(QueryTexts);
	
	QueryTextTableTTImpairmentOfIaWriteOffs(QueryTexts);
	
	QueryText =
	"// Write-off of residual value
	|SELECT
	|	DocumentData.Ref          AS Ref,
	|	TableOfIA.IntangibleAsset  AS IntangibleAsset,
	|
	|	ISNULL(IACost.Cost, 0) 
	|		- ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|		- ISNULL(ImpairmentFA.ImpairmenMan, 0) AS Cost,
	|
	|	ISNULL(IACost.LocalCost, 0)
	|		- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0) 
	|		- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS LocalCost,
	|
	|	ISNULL(IACost.CostInTaxAccounting, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0)     AS CostInTaxAccounting,
	|	ISNULL(IACost.CostPermanentDifference, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0)     AS CostPermanentDifference,
	|
	|	// TD as AC-TA-PD
	|	(ISNULL(IACost.LocalCost, 0)
	|		- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|		- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0))
	|		- (ISNULL(IACost.CostInTaxAccounting, 0)
	|			- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0))
	|		- (ISNULL(IACost.CostPermanentDifference, 0)
	|			- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0)) AS CostTemporaryDifference,
	|
	|	ISNULL(IACost.CostTargetFinancing, 0) - ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0)     AS CostTargetFinancing,
	|	ISNULL(IACost.CostTargetFinancingTA, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTA,
	|	ISNULL(IACost.CostTargetFinancingPD, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|	ISNULL(IACost.CostTargetFinancingTD, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD, 0) AS CostTargetFinancingTD,
	|
	|	TableOfIA.Department            AS Department,
	|	TableOfIA.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness  AS LineOfBusiness,
	|	TableOfIA.IncomeItem            AS IncomeItem,
	|	TableOfIA.DimensionOfRevenue         AS DimensionOfRevenue,
	|	
	|	TableOfIA.RowID      AS RowID,
	|	1 AS SubqueryID
	|
	|INTO TTResidualValueOfIa
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTTableOfIa AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS IACost
	|		ON IACost.Ref = TableOfIA.Ref 
	|			AND IACost.AccountingObject = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref
	|			AND IntangibleAssetsAmortizationCharge.AccountingObject = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = TableOfIA.Ref
	|			AND ImpairmentFA.AccountingObject = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|	AND (ISNULL(IACost.Cost, 0)
	|		- ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|		- ISNULL(ImpairmentFA.ImpairmenMan, 0)<> 0
	|		OR
	|			ISNULL(IACost.LocalCost, 0)
	|				- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|				- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) <> 0
	|		OR
	|			ISNULL(IACost.CostInTaxAccounting, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0) <> 0
	|		OR
	|			ISNULL(IACost.CostPermanentDifference, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) <> 0
	|	
	|		OR
	|			(ISNULL(IACost.LocalCost, 0)
	|				- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|				- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0))
	|			- (ISNULL(IACost.CostInTaxAccounting, 0)
	|				- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0))
	|			- (ISNULL(IACost.CostPermanentDifference, 0)
	|				- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0)) <> 0
	|	
	|		OR ISNULL(IACost.CostTargetFinancing, 0) - ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0) <> 0
	|		OR ISNULL(IACost.CostTargetFinancingTA, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing, 0) <> 0
	|		OR ISNULL(IACost.CostTargetFinancingPD, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD, 0) <> 0
	|		OR ISNULL(IACost.CostTargetFinancingTD, 0) - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD, 0) <> 0)
	|
	|UNION ALL
	|
	|//Partial write-off of residual value
	|SELECT
	|	DocumentData.Ref         AS Ref,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|
	|	TableOfIA.Cost 
	|		- ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|		- ISNULL(ImpairmentFA.ImpairmenMan, 0)         AS Cost,
	|
	|	TableOfIA.LocalCost 
	|		- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|		- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS LocalCost,
	|
	|	TableOfIA.CostInTaxAccounting - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0)     AS CostInTaxAccounting,
	|
	|	TableOfIA.CostPermanentDifference - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0)     AS CostPermanentDifference,
	|
	|	TableOfIA.CostTemporaryDifference 
	|		- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTD, 0)
	|		- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0)     AS CostTemporaryDifference,
	|
	|	TableOfIA.CostTargetFinancing - ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0)     AS CostTargetFinancing,
	|	TableOfIA.CostTargetFinancingTA - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTA,
	|	TableOfIA.CostTargetFinancingPD - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|	TableOfIA.CostTargetFinancingTD - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD, 0) AS CostTargetFinancingTD,
	|
	|	TableOfIA.Department           AS Department,
	|	TableOfIA.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TableOfIA.LineOfBusiness AS LineOfBusiness,
	|	TableOfIA.IncomeItem           AS IncomeItem,
	|	TableOfIA.DimensionOfRevenue        AS DimensionOfRevenue,
	|	
	|	TableOfIA.RowID     AS RowID,
	|	2 AS SubqueryID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTCostOfIaWriteOff AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTDepreciationWriteOffOfIa AS IntangibleAssetsAmortizationCharge
	|		ON IntangibleAssetsAmortizationCharge.Ref = TableOfIA.Ref 
	|			AND IntangibleAssetsAmortizationCharge.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTImpairmentOfIaWriteOffs AS ImpairmentFA
	|		ON ImpairmentFA.Ref = TableOfIA.Ref
	|			AND ImpairmentFA.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialIntangibleAssetsDisposal)
	|	AND (
	|			TableOfIA.Cost 
	|				- ISNULL(IntangibleAssetsAmortizationCharge.Depreciation, 0)
	|				- ISNULL(ImpairmentFA.ImpairmenMan, 0) <> 0
	|		OR 
	|			TableOfIA.LocalCost 
	|				- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationLocal, 0)
	|				- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) <> 0
	|		OR 
	|			TableOfIA.CostInTaxAccounting - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting, 0) <> 0
	|		OR 
	|			TableOfIA.CostPermanentDifference - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) <> 0
	|		OR 
	|			TableOfIA.CostTemporaryDifference 
	|				- ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTD, 0)
	|				- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) <> 0
	|		OR 
	|			TableOfIA.CostTargetFinancing - ISNULL(IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing, 0) <> 0
	|		OR 
	|			TableOfIA.CostTargetFinancingTA - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing, 0) <> 0
	|		OR 
	|			TableOfIA.CostTargetFinancingPD - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD, 0) <> 0
	|		OR 
	|			TableOfIA.CostTargetFinancingTD - ISNULL(IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD, 0) <> 0
	|		)
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTTableOfIa(QueryTexts)
	
	TableName = "TableOfIA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = DisposeIntangibleAssetsLocalization.QueryTextTableTTTableOfIa(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForIA(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTPlaceOfIaAccounting(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTNmauuDepreciationParameters(QueryTexts);
		
		QueryText = 
		"SELECT
		|	TableOfIA.Ref                      AS Ref,
		|	TableOfIA.LineNumber                 AS LineNumber,
		|	TableOfIA.IntangibleAsset         AS IntangibleAsset,
		|
		|	AccountingProcedure.FinancialAccountingGroup    AS FinancialAccountingGroup,
		|	AccountingProcedure.LineOfBusiness   AS LineOfBusiness,
		|	AccountingProcedure.EstimatedRunningTime            AS EstimatedRunningTime,
		|
		|	IntangibleAssetsRegistrationPlace.Organization              AS Organization,
		|	IntangibleAssetsRegistrationPlace.Department            AS Department,
		|
		|	UNDEFINED                           AS IncomeItem,
		|	UNDEFINED                           AS DimensionOfRevenue,
		|
		|	TableOfIA.AmountManagementAccounting             AS AmountManagementAccounting,
		|	TableOfIA.ChargeAmountAccounting             AS ChargeAmountAccounting,
		|	TableOfIA.AmountTaxAccounting             AS AmountTaxAccounting,
		|	TableOfIA.AmountPermanentDifference             AS AmountPermanentDifference,
		|	TableOfIA.AmountTemporaryDifference             AS AmountTemporaryDifference,
		|	
		|	TableOfIA.RowID 		   AS RowID
		|	
		|INTO TTTableOfIa
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataIATable AS TableOfIA
		|		ON DocumentData.Ref = TableOfIA.Ref
		|
		|		LEFT JOIN TTAccountingProcedureForIA AS AccountingProcedure
		|		ON AccountingProcedure.Ref = TableOfIA.Ref
		|			AND AccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTPlaceOfIaAccounting AS IntangibleAssetsRegistrationPlace
		|		ON IntangibleAssetsRegistrationPlace.Ref = TableOfIA.Ref
		|			AND IntangibleAssetsRegistrationPlace.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|		LEFT JOIN TTNmauuDepreciationParameters AS MaDepreciationParameters
		|		ON MaDepreciationParameters.Ref = TableOfIA.Ref
		|			AND MaDepreciationParameters.IntangibleAsset = TableOfIA.IntangibleAsset
		|
		|INDEX BY
		|	Ref,
		|	IntangibleAsset
		|";
	
	EndIf; 
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return DisposeIntangibleAssetsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return DisposeIntangibleAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Other

// 
// Parameters:
//  Organization - CatalogRef.Companies -
//  Date - Date - Document date
// 
// Returns:
//  Map - Submission of Bank details
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
	
	PresentationOfDetails.Insert("IA.ChargeAmountAccounting", FieldPresentation);
	
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
		
	PresentationOfDetails.Insert("IA.AmountManagementAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (KTTh)';
																			|ru = 'Сумма (НУ)';
																			|en = 'TA amount'; fa = 'مبلغ حسابداری مالیاتی';
																			|it = 'Importo (Registro Fiscale)';
																			|pl = 'Wartość (EP)';
																			|tr = 'Tutar (VM)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("IA.AmountTaxAccounting", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLVV)';
																			|ru = 'Сумма (ПР)';
																			|en = 'Amount (PD)'; fa = 'مبلغ (تفاوت دائم)';
																			|it = 'Importo (differenza costante)';
																			|pl = 'Wartość (różnica trwała)';
																			|tr = 'Tutar (Kalıcı fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("IA.AmountPermanentDifference", FieldPresentation);

	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLTT)';
																			|ru = 'Сумма (ВР)';
																			|en = 'Amount (TD)'; fa = 'مبلغ (تفاوت موقت)';
																			|it = 'Importo (differenza temporanea)';
																			|pl = 'Wartość (różnica przejściowa)';
																			|tr = 'Tutar (Geçici fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("IA.AmountTemporaryDifference", FieldPresentation);

	Return PresentationOfDetails;
	
EndFunction

Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	ListOfConditions = New Structure;
	ListOfConditions.Insert("DimensionOfExpensesRequired_", True);
	ListOfConditions.Insert("DimensionCorrespondsToIAToWriteOff", False);
	ChoiceParameters.ConditionsForMandatoryAnalyticsInRows = ListOfConditions;

	Return ChoiceParameters;
	
EndFunction

Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
	Return SetupParameters;
	
EndFunction

// Fills in the document based on the inventory
//
// Parameters:
//  Object - DocumentObject.DisposeIntangibleAssets2_4 - The document that needs to be filled out.
//  ReportErrors - Boolean - True if you need to report errors.
//  ArrayOfLineNumbers - Array - Inventory rows.
//
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.IntangibleAssetsPhysicalCount.FillingDataBasedOnInventory(
							Object.DocumentBasis,
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.WriteOff, 
							ArrayOfLineNumbers);
							
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu ghi giảm';
							|ru = 'В документе %1 отсутствуют строки требующие создания списания';
							|en = 'There are no lines which require writing off in the %1 document'; fa = 'There are no lines which require writing off in the %1 document';
							|it = 'There are no lines which require writing off in the %1 document';
							|pl = 'There are no lines which require writing off in the %1 document';
							|tr = '%1 belgesinde silme oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return;
		
	EndIf;
	
	Selection = DataToFill.Attributes[0];
	FillPropertyValues(Object, Selection);
	
	Object.BusinessOperation = Enums.BusinessTransactions.DisposeIntangibleAssets;
	
	PostInAccounting = False;
	RecordInTA = False;
	RecordInManAccounting = False;
	
	For Each Selection In DataToFill.TabularSection Do
		
		RowData = Object.IA.Add();
		RowData.IntangibleAsset = Selection.IntangibleAsset;
		
		If Selection.PostInAccounting Then
			PostInAccounting = True;
		EndIf; 
		If Selection.RecordInTA Then
			RecordInTA = True;
		EndIf; 
		If Selection.RecordInManAccounting Then
			RecordInManAccounting = True;
		EndIf; 
		
	EndDo;
	
	If Object.IA.Count() <> 0 Then
		Object.PostInAccounting = PostInAccounting;
		Object.RecordInTA = RecordInTA;
		Object.RecordInManAccounting = RecordInManAccounting;
		Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;
	EndIf;
	
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
	Handler.Procedure = "Documents.DisposeIntangibleAssets2_4.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Id = New UUID("a6e51db7-a3ef-4362-a7ed-bc3c849f83f8");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.DisposeIntangibleAssets2_4.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Đang cập nhật chứng từ ""Ghi giảm TSCĐVH"":
								  |- Điền mục tin mới ""Phản ánh trong KTTh.';
								  |ru = 'Обновляет документы ""Списание НМА"":
								  |- Заполняет новый реквизит ""Отражать в НУ.';
								  |en = 'Updates the ""Dispose intangible assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.'; fa = 'Updates the ""Dispose intangible assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |it = 'Updates the ""Dispose intangible assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |pl = 'Updates the ""Dispose intangible assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |tr = '""Maddi Olmayan Varlık Silme"" belgelerini günceller:
								  | - ""Vergi muhasebesinde yansıt"" yeni özniteliğini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DisposeIntangibleAssets2_4.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.DisposeIntangibleAssets2_4.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.DisposeIntangibleAssets2_4.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.DisposeIntangibleAssets2_4";
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
	|		Document.DisposeIntangibleAssets2_4 AS DocumentData
	|	WHERE
	|		DocumentData.RecordInLocalAccounting
	|			AND NOT DocumentData.PostInAccounting
	|			AND NOT DocumentData.RecordInTA
	|
	|	) AS DocumentsList
	|";
	
	Query = New Query(QueryText);
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.DisposeIntangibleAssets2_4.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.DisposeIntangibleAssets2_4";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.DisposeIntangibleAssets2_4
			If DocumentObject = Undefined Then
				CommitTransaction();
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
