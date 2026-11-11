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
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("ImpairmentFA");
	
	DisposeFixedAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DisposeFixedAssets2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAssetsLeasedOut(QueryTexts, Registers);
		QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers);
		
		QueryTextTableFACost(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		DisposeFixedAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
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
	
	QueryTextTableInitialFixedAssetsInformation(QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAssetsLeasedOut(QueryTexts, Undefined);	
	
	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableOtherExpenses(QueryTexts);
	QueryTextTableOtherAssetsLiabilities(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	DisposeFixedAssetsLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
		
	Return MovementTables;
	
EndFunction

// Generates tables of movements when performing the operation "Closing expenses from the disposal of fixed assets".
//
// Parameters:
//  TempTablesManager	- TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//  RegisterRecordsPeriod - Date - The month in which Registered Records are generated
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfRegisteredRecordsInClosingExpensesFromDisposalOfFA(TempTablesManager, RegisterRecordsPeriod) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("RegisterRecordsPeriod", RegisterRecordsPeriod);
	
	GetDocumentData(Query);

	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	ClosingExpensesFromDisposalOfFixedAssets.SetRequestParameters(Query);
	
	QueryTexts = New ValueList;
	
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableOtherExpenses(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableItemisedExpensesLots(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.TempTablesManager = TempTablesManager;
	AddlParameters.OnlyMarkedOnes = True;
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return TablesForRegisteredRecords;
	
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
	
	Documents.OtherGoodsRecordingAsReceived.AddGenerateCommand(GenerationCommands);
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	DisposeFixedAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "depreciation of fixed assets".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order						 - Number			 - The order of the command.
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.DisposeFixedAssets2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DisposeFixedAssets2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DisposeFixedAssets2_4);
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
	
	DisposeFixedAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	DisposeFixedAssetsLocalization.AddPrintCommands(PrintCommands);

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

#Region Workplace

// Generates data for the workplace.
// 
// Parameters:
//  Parameters - Structure - Contains:
//  	* BeginOfPeriod - Date -
//  	* EndOfPeriod - Date -
//  	* Organization - CatalogRef.Companies
//  	* DocumentWriteOffs - String -
// 
// Returns:
//  ValueTable - The data of the workplace
Function WorkplaceData(Parameters) Export
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	InventoryInOperation.Period AS Period,
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Recorder AS DocumentRetirements,
	|	InventoryInOperation.Lot AS Lot,
	|	InventoryInOperation.Lot.FixedAsset AS FixedAsset
	|
	|INTO DisposalsOfGoodsAndMaterials
	|
	|FROM
	|	AccumulationRegister.InventoryInOperation AS InventoryInOperation
	|WHERE
	|	(InventoryInOperation.Period >= &BeginOfPeriod
	|		OR &BeginOfPeriod = DATETIME(1,1,1))
	|
	|	AND (InventoryInOperation.Period <= &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1,1,1))
	|	
	|	AND (InventoryInOperation.Organization = &Organization
	|		OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|	AND InventoryInOperation.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.Decomissioning),
	|		VALUE(Enum.BusinessTransactions.PutOutOfOperation))
	|
	|	AND InventoryInOperation.Lot.OperationCategory.AccountAsGroupFA
	|
	|	AND InventoryInOperation.Active
	|	
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	BasisTable.Ref AS Ref,
	|	BasisTable.DocumentBasis AS DocumentBasis,
	|	BasisTable.FixedAsset AS FixedAsset
	|
	|INTO WriteOffsOfOS
	|
	|FROM
	|	(SELECT
	|		BasisTable.Ref AS Ref,
	|		BasisTable.DocumentBasis AS DocumentBasis,
	|		FATable.FixedAsset AS FixedAsset
	|	FROM
	|		Document.DisposeFixedAssets2_4.Basis1 AS BasisTable
	|
	|			INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|			ON FATable.Ref = BasisTable.Ref
	|	
	|	WHERE
	|		BasisTable.Ref.Posted
	|
	|		AND BasisTable.DocumentBasis IN (
	|			SELECT
	|				DisposalsOfGoodsAndMaterials.DocumentRetirements
	|			FROM
	|				DisposalsOfGoodsAndMaterials AS DisposalsOfGoodsAndMaterials)
	|
	|		AND FATable.FixedAsset IN (
	|			SELECT
	|				DisposalsOfGoodsAndMaterials.FixedAsset
	|			FROM
	|				DisposalsOfGoodsAndMaterials AS DisposalsOfGoodsAndMaterials)
	|
	|	UNION ALL
	|
	|	SELECT
	|		BasisTable.Ref AS Ref,
	|		BasisTable.DocumentBasis AS DocumentBasis,
	|		FATable.FixedAsset AS FixedAsset
	|	FROM
	|		Document.DisposeFixedAssets2_4 AS BasisTable
	|
	|			INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|			ON FATable.Ref = BasisTable.Ref
	|
	|	WHERE
	|		BasisTable.Posted
	|
	|		AND BasisTable.DocumentBasis IN (
	|			SELECT
	|				DisposalsOfGoodsAndMaterials.DocumentRetirements
	|			FROM
	|				DisposalsOfGoodsAndMaterials AS DisposalsOfGoodsAndMaterials)
	|
	|		AND FATable.FixedAsset IN (
	|			SELECT
	|				DisposalsOfGoodsAndMaterials.FixedAsset
	|			FROM
	|				DisposalsOfGoodsAndMaterials AS DisposalsOfGoodsAndMaterials)
	|
	|	) AS BasisTable
	|	
	|INDEX BY
	|	DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(DisposalsOfGoodsAndMaterials.Period, MONTH) AS MonthOfDisposal,
	|	DisposalsOfGoodsAndMaterials.Period AS DateOfDisposal,
	|	DisposalsOfGoodsAndMaterials.Organization AS Organization,
	|	DisposalsOfGoodsAndMaterials.FixedAsset AS FixedAsset,
	|	DisposalsOfGoodsAndMaterials.Lot AS Lot,
	|	DisposalsOfGoodsAndMaterials.DocumentRetirements AS DocumentRetirements,
	|	ISNULL(WriteOffsWereCarriedOut.Ref, UNDEFINED) AS DocumentWriteOffs
	|
	|FROM
	|	DisposalsOfGoodsAndMaterials AS DisposalsOfGoodsAndMaterials
	|
	|		LEFT JOIN WriteOffsOfOS AS WriteOffsWereCarriedOut
	|		ON WriteOffsWereCarriedOut.DocumentBasis = DisposalsOfGoodsAndMaterials.DocumentRetirements
	|			AND WriteOffsWereCarriedOut.FixedAsset = DisposalsOfGoodsAndMaterials.FixedAsset
	|
	|WHERE
	|	(&DocumentWriteOffs = """"
	|		OR &DocumentWriteOffs = ""NotIssued""
	|				AND ISNULL(WriteOffsWereCarriedOut.Ref,UNDEFINED) = UNDEFINED
	|		OR &DocumentWriteOffs = ""Issued""
	|				AND ISNULL(WriteOffsWereCarriedOut.Ref, UNDEFINED) <> UNDEFINED)
	|
	|ORDER BY
	|	Organization,
	|	DateOfDisposal,
	|	DocumentRetirements,
	|	FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("DocumentWriteOffs", Parameters.DocumentWriteOffs);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

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
	
	PresentationOfDetails.Insert("FA.ChargeAmountAccounting", FieldPresentation);
	
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
		
	PresentationOfDetails.Insert("FA.AmountManagementAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (KTTh)';
																			|ru = 'Сумма (НУ)';
																			|en = 'TA amount'; fa = 'مبلغ حسابداری مالیاتی';
																			|it = 'Importo (Registro Fiscale)';
																			|pl = 'Wartość (EP)';
																			|tr = 'Tutar (VM)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.AmountTaxAccounting", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLVV)';
																			|ru = 'Сумма (ПР)';
																			|en = 'Amount (PD)'; fa = 'مبلغ (تفاوت دائم)';
																			|it = 'Importo (differenza costante)';
																			|pl = 'Wartość (różnica trwała)';
																			|tr = 'Tutar (Kalıcı fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.AmountPermanentDifference", FieldPresentation);

	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLTT)';
																			|ru = 'Сумма (ВР)';
																			|en = 'Amount (TD)'; fa = 'مبلغ (تفاوت موقت)';
																			|it = 'Importo (differenza temporanea)';
																			|pl = 'Wartość (różnica przejściowa)';
																			|tr = 'Tutar (Geçici fark)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.AmountTemporaryDifference", FieldPresentation);

	Return PresentationOfDetails;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.DisposeFixedAssets2_4";
	
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
	|	Document.DisposeFixedAssets2_4 AS DocumentsList
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
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.EmployeeResponsible              AS EmployeeResponsible,
	|	DocumentData.Comment                AS Comment,
	|	DocumentData.Posted                   AS Posted,
	|	DocumentData.DeletionMark            AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting         AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting          AS RecordInManAccounting,
	|	DocumentData.PostInAccounting                AS PostInAccounting,
	|	DocumentData.RecordInTA                AS RecordInTA,
	|	DocumentData.Department              AS Department,
	|	DocumentData.BusinessOperation      AS BusinessOperation,
	|	DocumentData.ExpenseItem             AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses          AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	DocumentData.GLAccountSettings       AS GLAccountSettings,
	|	DocumentData.DimensionCorrespondsToFAToWriteOff AS DimensionCorrespondsToFAToWriteOff,
	|	DocumentData.RetirementItem      AS RetirementItem,
	|	DocumentData.ExpensesBusinessUnit      AS ExpensesBusinessUnit,
	|	DocumentData.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|	DocumentData.FixedAssetsEvent                  AS FixedAssetsEvent,
	|	DocumentData.AdjustmentModeFromPreviousDate       AS AdjustmentModeFromPreviousDate,
	|	BEGINOFPERIOD(DocumentData.DateOfDeduction, DAY) AS DateOfDeduction,
	|	BusinessTransactionsSettings.Ref      AS BusinessTransactionSetting
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
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
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.ResidualValueMan AS ResidualValueMan,
	|	DocumentTable.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentTable.AmountManagementAccounting AS AmountManagementAccounting,
	|	DocumentTable.ChargeAmountAccounting  AS ChargeAmountAccounting,
	|	DocumentTable.AmountTaxAccounting AS AmountTaxAccounting,
	|	DocumentTable.AmountPermanentDifference AS AmountPermanentDifference,
	|	DocumentTable.AmountTemporaryDifference AS AmountTemporaryDifference
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.DisposeFixedAssets2_4.FA AS DocumentTable
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
	
	#Region DocumentDataTableTraceableGoods
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.CCDNumber AS CCDNumber,
	|	DocumentTable.FEACNCode AS FEACNCode,
	|	DocumentTable.QuantityByGBRN AS QuantityByGBRN,
	|	DocumentTable.RetirementTransactionCode AS RetirementTransactionCode
	|
	|INTO DocumentDataTableTraceableGoods
	|
	|FROM
	|	Document.DisposeFixedAssets2_4.TraceableGoods AS DocumentTable
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
	NonCurrentAssets.AddValuesOfPaymentParametersWhenDebitingFA(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.DisposeFixedAssets2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Ghi giảm TSCĐ hữu hình';
															|ru = 'Списание ОС';
															|en = 'Dispose fixed assets'; fa = 'واگذاری دارایی‌های ثابت';
															|it = 'Cancellazione contabile capitale fisso';
															|pl = 'Wyksięgowanie środków trwałych';
															|tr = 'Sabit kıymetlerin tasfiyesi'"));
	
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses",GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherAssetsAndLiabilities",GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	ValuesOfHoldingParameters.Insert("UseTraceableImportedGoodsAccounting",GetFunctionalOption("UseTraceableImportedGoodsAccounting"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
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
	|	&MetadataIdentifier                        AS RefType,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Posted                        AS Posted,
	|	DocumentData.PostInAccounting                     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInTA                     AS RecordInTA,
	|	DocumentData.FixedAssetsEvent                       AS FixedAssetsEvent,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	DocumentData.AdjustmentModeFromPreviousDate    AS IsPatch,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN DocumentData.DateOfDeduction
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
	|	Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|		LEFT JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
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
	|	DocumentData.Ref          AS Ref,
	|	DocumentData.Date            AS IBDocumentDate,
	|	DocumentData.Number           AS IBDocumentNumber,
	|	&MetadataIdentifier        AS RefType,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	UNDEFINED                    AS LineOfBusiness,
	|	DocumentData.Department   AS Department,
	|	DocumentData.EmployeeResponsible   AS EmployeeResponsible,
	|	DocumentData.Comment     AS Comment,
	|	DocumentData.Posted        AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE                            AS AdditionalRecord,
	|	DocumentData.Date            AS SourceDocumentDate,
	|	&NumberForPrinting                  AS SourceDocumentNumber,
	|	FALSE                            AS ReverseTransactionCorrection,
	|	UNDEFINED                    AS ReversedDocument,
	|	UNDEFINED                    AS CorrectedDocument,
	|	DocumentData.Date            AS RecordingInAccountingDate,
	|	UNDEFINED                    AS Priority
	|
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	
	QueryTextTableTTFATable(QueryTexts);
	
	QueryText = DisposeFixedAssetsLocalization.QueryTextTableInitialFixedAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentACC
		|	END AS DeregistrationDocumentACC,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentMA
		|	END AS DeregistrationDocumentMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.DateOfDeduction AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentACC
		|	END AS DeregistrationDocumentACC,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentMA
		|	END AS DeregistrationDocumentMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|WHERE
		|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                                         AS Recorder,
	|	DocumentData.Period                                         AS Period,
	|	DATETIME(1,1,1)                                               AS CorrectionDate,
	|
	|	DocumentData.Organization                                    AS Organization,
	|	FATable.FixedAsset                                     AS FixedAsset,
	|
	|	AccountingProcedureForOSBU.ExpenseRecordMethodAC                     AS ExpenseRecordMethodAC,
	|	AccountingProcedureForOSBU.ExpenseItemAccounting                              AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting                           AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.DepartmentACC                               AS DepartmentACC,
	|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping                     AS LineOfBusinessBookkeeping,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA                  AS DepreciationRecordMethodLA,
	|	AccountingProcedureForOSBU.ExpenseRecordMethodTA                     AS ExpenseRecordMethodTA,
	|	AccountingProcedureForOSBU.ExpenseItemTaxAccounting                              AS ExpenseItemTaxAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionTaxAccounting                           AS ExpensesDimensionTaxAccounting,
	|	AccountingProcedureForOSBU.BusinessUnitTaxAccounting                               AS BusinessUnitTaxAccounting,
	|	AccountingProcedureForOSBU.LineOfBusinessTaxAccounting                     AS LineOfBusinessTaxAccounting,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodTA                  AS DepreciationRecordMethodTA,
	|	AccountingProcedureForOSBU.ExpenseItemOfDepreciationAllowance           AS ExpenseItemOfDepreciationAllowance,
	|	AccountingProcedureForOSBU.DepreciationAllowanceExpensesDimension        AS DepreciationAllowanceExpensesDimension,
	|	AccountingProcedureForOSBU.BusinessUnitBonusDepreciation            AS BusinessUnitBonusDepreciation,
	|	AccountingProcedureForOSBU.LineOfBusinessBonusDepreciation  AS LineOfBusinessBonusDepreciation,
	|	AccountingProcedureForOSBU.BonusDepreciationRecordMethod          AS BonusDepreciationRecordMethod,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany           AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses                 AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationGroup                         AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                           AS RealEstate,
	|	AccountingProcedureForOSBU.InvestmentTaxDeduction                  AS InvestmentTaxDeduction,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks) 
	|		ELSE AccountingProcedureForOSBU.BUState
	|	END AS BUState,
	|
	|	CASE
	|		WHEN DocumentData.RecordInTA
	|			THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks) 
	|		ELSE AccountingProcedureForOSBU.StateTa
	|	END AS StateTa,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN FALSE 
	|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
	|	END AS DepreciationAccrualAccounting,
	|
	|	CASE
	|		WHEN DocumentData.RecordInTA
	|			THEN FALSE 
	|		ELSE AccountingProcedureForOSBU.DepreciationAccrualTaxAccounting
	|	END AS DepreciationAccrualTaxAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                                         AS Recorder,
	|	DocumentData.DateOfDeduction                                   AS Period,
	|	DocumentData.Period                                         AS CorrectionDate,
	|
	|	DocumentData.Organization                                    AS Organization,
	|	AccountingProcedureForOSBU.FixedAsset                              AS FixedAsset,
	|
	|	AccountingProcedureForOSBU.ExpenseRecordMethodAC                     AS ExpenseRecordMethodAC,
	|	AccountingProcedureForOSBU.ExpenseItemAccounting                              AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting                           AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.DepartmentACC                               AS DepartmentACC,
	|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping                     AS LineOfBusinessBookkeeping,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodLA                  AS DepreciationRecordMethodLA,
	|	AccountingProcedureForOSBU.ExpenseRecordMethodTA                     AS ExpenseRecordMethodTA,
	|	AccountingProcedureForOSBU.ExpenseItemTaxAccounting                              AS ExpenseItemTaxAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionTaxAccounting                           AS ExpensesDimensionTaxAccounting,
	|	AccountingProcedureForOSBU.BusinessUnitTaxAccounting                               AS BusinessUnitTaxAccounting,
	|	AccountingProcedureForOSBU.LineOfBusinessTaxAccounting                     AS LineOfBusinessTaxAccounting,
	|	AccountingProcedureForOSBU.DepreciationRecordMethodTA                  AS DepreciationRecordMethodTA,
	|	AccountingProcedureForOSBU.ExpenseItemOfDepreciationAllowance           AS ExpenseItemOfDepreciationAllowance,
	|	AccountingProcedureForOSBU.DepreciationAllowanceExpensesDimension        AS DepreciationAllowanceExpensesDimension,
	|	AccountingProcedureForOSBU.BusinessUnitBonusDepreciation            AS BusinessUnitBonusDepreciation,
	|	AccountingProcedureForOSBU.LineOfBusinessBonusDepreciation  AS LineOfBusinessBonusDepreciation,
	|	AccountingProcedureForOSBU.BonusDepreciationRecordMethod          AS BonusDepreciationRecordMethod,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany           AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses                 AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationGroup                         AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                           AS RealEstate,
	|	AccountingProcedureForOSBU.InvestmentTaxDeduction                  AS InvestmentTaxDeduction,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks) 
	|		ELSE AccountingProcedureForOSBU.BUState
	|	END AS BUState,
	|
	|	CASE
	|		WHEN DocumentData.RecordInTA
	|			THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks) 
	|		ELSE AccountingProcedureForOSBU.StateTa
	|	END AS StateTa,
	|
	|	CASE
	|		WHEN DocumentData.PostInAccounting
	|			THEN FALSE 
	|		ELSE AccountingProcedureForOSBU.DepreciationAccrualAccounting
	|	END AS DepreciationAccrualAccounting,
	|
	|	CASE
	|		WHEN DocumentData.RecordInTA
	|			THEN FALSE 
	|		ELSE AccountingProcedureForOSBU.DepreciationAccrualTaxAccounting
	|	END AS DepreciationAccrualTaxAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DATETIME(1,1,1)             AS CorrectionDate,
	|	DocumentData.Organization  AS Organization,
	|	FATable.FixedAsset   AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.DateOfDeduction AS Period,
	|	DocumentData.Period       AS CorrectionDate,
	|	DocumentData.Organization  AS Organization,
	|	FATable.FixedAsset   AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAssetsLeasedOut(QueryTexts, Registers)

	RegisterName = "AssetsLeasedOut";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTLeasedToFA(
		QueryTexts, "TTExtendedFATable");

	NonCurrentAssetsInternal.QueryTextTableTTLeasedToFA(
		QueryTexts, "TTExtendedFATable", "TTLeasedToFA_SubjectToCorrections", True);

	QueryText =
	"SELECT
	|	DocumentData.Ref      AS Recorder,
	|	DocumentData.Period      AS Period,
	|	DATETIME(1,1,1)            AS CorrectionDate,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset  AS FixedAsset
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTLeasedToFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTLeasedToFA_SubjectToCorrections AS RegisterDataLast
	|		ON RegisterDataLast.Ref = FATable.Ref
	|			AND RegisterDataLast.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|	AND (NOT DocumentData.AdjustmentModeFromPreviousDate
	|		OR ISNULL(RegisterDataLast.Period, DATETIME(1,1,1)) < DocumentData.DateOfDeduction)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.DateOfDeduction AS Period,
	|	DocumentData.Period       AS CorrectionDate,
	|	DocumentData.Organization  AS Organization,
	|	FATable.FixedAsset   AS FixedAsset
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTLeasedToFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure	

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)

	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|	DocumentData.Period       AS LastChangeDate,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	// CostUsedToCalculateDepreciationManag
	|	CASE 
	|		WHEN NOT DocumentData.PostInAccounting
	|			THEN OSBUDepreciationParameters.CostUsedToCalculateDepreciationManag
	|		WHEN ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) = 0 
	|			THEN 0
	|		ELSE (ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0))
	|				- (ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) + ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0))
	|				- (FATable.ChargeAmountAccounting 
	|					- (CAST((ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) + ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)) 
	|						* FATable.ChargeAmountAccounting 
	|						/ (ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0)) AS NUMBER(31,2))))
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostForDepreciationCalculationTargetFinancing
	|	CASE 
	|		WHEN NOT DocumentData.PostInAccounting
	|			THEN OSBUDepreciationParameters.CostForDepreciationCalculationTargetFinancing
	|		WHEN OSBUDepreciationParameters.CostForDepreciationCalculationTargetFinancing = 0
	|			THEN 0
	|		WHEN ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) = 0 
	|			THEN 0
	|		ELSE ISNULL(FACost.CostTargetFinancing, 0)
	|				- ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)
	|				- (FATable.ChargeAmountAccounting 
	|					- (CAST(ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) 
	|						* FATable.ChargeAmountAccounting 
	|						/ (ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0)) AS NUMBER(31,2))))
	|	END AS CostForDepreciationCalculationTargetFinancing,
	|
	// PermanentDifferencesUsedToCalculateDepreciation
	|	CASE
	|		WHEN FATable.AmountPermanentDifference <> 0 AND (ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancingPD, 0)) <> 0
	|			THEN OSBUDepreciationParameters.PermanentDifferencesUsedToCalculateDepreciation
	|					- OSBUDepreciationParameters.PermanentDifferencesUsedToCalculateDepreciation
	|						* FATable.AmountPermanentDifference / (ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancingPD, 0))
	|		ELSE OSBUDepreciationParameters.PermanentDifferencesUsedToCalculateDepreciation
	|	END AS PermanentDifferencesUsedToCalculateDepreciation,
	|
	|	OSBUDepreciationParameters.UsefulLifeMonthsAC         AS UsefulLifeMonthsAC,
	|	OSBUDepreciationParameters.UsefulLifeMonthsTA         AS UsefulLifeMonthsTA,
	|	OSBUDepreciationParameters.AnnualDepreciationRate             AS AnnualDepreciationRate,
	|	OSBUDepreciationParameters.AccelerationFactor                 AS AccelerationFactor,
	|	OSBUDepreciationParameters.DepreciationSchedule                    AS DepreciationSchedule,
	|	OSBUDepreciationParameters.SpecialFactor               AS SpecialFactor,
	|	FATable.ResidualValueLocal                         AS ResidualValueMan,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// UsefulLifeForCalculatingDepreciationMonth
	|	OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(OSBUDepreciationParameters.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
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
	|		ON (OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset)
	|
	|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|		ON FATable.FixedAsset = AssetActivityRecords.Asset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|	DocumentData.Period       AS LastChangeDate,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeMonths,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	FATable.ResidualValueMan                    AS ResidualValueMan,
	|	FATable.ResidualValueLocal                AS ResidualValueLocal,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth,
	|
	// CostUsedToCalculateDepreciationManag
	|	CASE 
	|		WHEN ISNULL(FACost.Cost, 0) = 0 
	|			THEN 0
	|		ELSE ISNULL(FACost.Cost, 0)
	|				- ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)
	|				- (FATable.AmountManagementAccounting 
	|					- (CAST(ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) 
	|						* FATable.AmountManagementAccounting 
	|						/ ISNULL(FACost.Cost, 0) AS NUMBER(31,2))))
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE 
	|		WHEN ISNULL(FACost.LocalCost, 0) = 0
	|				OR &ComplianceCAAccountingIsKept
	|			THEN 0
	|		ELSE ISNULL(FACost.LocalCost, 0)
	|				- ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0)
	|				- (FATable.ChargeAmountAccounting 
	|					- (CAST(ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) 
	|						* FATable.ChargeAmountAccounting 
	|						/ ISNULL(FACost.LocalCost, 0) AS NUMBER(31,2))))
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
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
	|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|		ON AssetActivityRecords.Ref = FATable.Ref
	|			AND AssetActivityRecords.Asset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers)
	
	RegisterName = "SubAssetsComponentsOfDepreciation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	FATable.FixedAsset AS SubAssetComponent
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);

	QueryText = NonCurrentAssetsInternal.RequestTextForDepreciationWriteOffFA(QueryTexts);
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

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	
	QueryText = NonCurrentAssetsInternal.TextOfRequestToDeductCostOfFA(QueryTexts, Query);
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

Procedure QueryTextTableOtherAssetsLiabilities(QueryTexts)

	RegisterName = "OtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTDepreciationWriteOffFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTResidualValueOfFA(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_WriteOffFixedAssetsCost                     AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	FATable.LineOfBusiness           AS LineOfBusiness,
	|
	|	DocumentData.ExpenseItem              AS AssetRef,
	|
	|	CASE
	|		WHEN DocumentData.DimensionCorrespondsToFAToWriteOff
	|			THEN FATable.FixedAsset
	|		ELSE DocumentData.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|
	|	FATable.Cost                         AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTResidualValueOfFA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	FATable.Cost <> 0
	|	AND VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND DocumentData.RecordInManAccounting
	|
	|UNION ALL
	|
	|// The revaluation reserve depreciation
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetDepreciation  AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	FATable.LineOfBusiness           AS LineOfBusiness,
	|
	|	&ArticleAP_OS                                AS AssetRef,
	|	FATable.FixedAsset                  AS Dimension,
	|
	|	FATable.DepreciationRevaluationReserve       AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTDepreciationWriteOffFA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	FATable.DepreciationRevaluationReserve <> 0
	|	AND DocumentData.RecordInManAccounting
	|
	|UNION ALL
	|
	|// Revaluation reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetsCost    AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	FATable.LineOfBusiness           AS LineOfBusiness,
	|
	|	&ArticleAP_OS                                AS AssetRef,
	|	FATable.FixedAsset                  AS Dimension,
	|
	|	FATable.CostRevaluationReserve         AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTWriteOffOfCostOfFA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	FATable.CostRevaluationReserve <> 0
	|	AND DocumentData.RecordInManAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);
	
	QueryText = NonCurrentAssetsInternal.TextOfRequestForDisposalFARegisteredRecordsOnOtherAssetsLiabilities(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";

	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATable(QueryTexts);

	QueryText = NonCurrentAssetsInternal.RequestTextDisposalsFARegisteredRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTexts.Add(QueryText, RegisterName);	
	
EndProcedure

Procedure QueryTextTableTTFATable(QueryTexts)
	
	TableName = "TTFATable";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	QueryText = DisposeFixedAssetsLocalization.QueryTextTableTTFATable(QueryTexts);
	
	If QueryText = Undefined Then
		
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
		|	FATable.AmountManagementAccounting              AS AmountManagementAccounting,
		|	FATable.ChargeAmountAccounting              AS ChargeAmountAccounting,
		|	FATable.AmountTaxAccounting              AS AmountTaxAccounting,
		|	FATable.AmountPermanentDifference              AS AmountPermanentDifference,
		|	FATable.AmountTemporaryDifference              AS AmountTemporaryDifference,
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
		|WHERE
		|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DisposeFixedAssets)
		|
		|INDEX BY
		|	Ref,
		|	FixedAsset
		|";
	
	EndIf; 
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return "";
	EndIf;
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));

	QueryText = NonCurrentAssetsInternal.QueryTextTableTTInitialOtherExpensesAtDisposalOfFA(QueryTexts);
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

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return DisposeFixedAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return "";

EndFunction

#EndRegion

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	DisposeFixedAssetsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

Function GetDataForPrintedFormOS4(ObjectsArray) Export
	
	Return DisposeFixedAssetsLocalization.GetDataForPrintedFormOS4(ObjectsArray);
	
EndFunction

#EndRegion

#Region FillType

// Fills it out based on changes in the terms of the lease Contract.
// 
// Parameters:
//  Object - DocumentObject.DisposeFixedAssets2_4 - Object
//  Basis - DocumentRef.LeaseTermAdjustment - Basis
// 
// Returns:
//  Undefined, String - 
Function FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Basis) Export
	
	If Not ValueIsFilled(Basis) Then
		Object.DocumentBasis = Undefined;
		Object.GeneratedDocument = False;
		Return Undefined;
	EndIf;

	Object.BusinessOperation = Enums.BusinessTransactions.DisposeFixedAssets;
	Object.DocumentBasis = Basis;
	Object.GeneratedDocument = True;
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Contract.Department AS FixedAssetsLocation,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Contract.AssetHolder AS AssetHolder,
	|	DocumentData.Contract.RecognizeLeasedAssetsInManagementAccounting AS RecordInManAccounting,
	|	DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting AS PostInAccounting,
	|	FALSE AS RecordInTA
	|
	|FROM
	|	Document.LeaseTermAdjustment AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.FixedAsset AS FixedAsset
	|FROM
	|	Document.LeaseTermAdjustment.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Basis
	|	AND FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.RentalTermination)
	|
	|ORDER BY
	|	FATable.LineNumber
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Object.DocumentBasis);
	Package = Query.ExecuteBatch();
	
	Selection = Package[0].Select();
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	
	If Selection.AssetHolder = Enums.LeasedAssetHolder.Lessor
		And Not LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Selection.Organization, Object.Date) Then
		
		ErrorText = NStr("vi = 'Không xem xét ghi giảm tài sản cố định được tính trên bảng cân đối kế toán của bên cho thuê';
						|ru = 'Списание основных средств, учитываемых на балансе арендодателя, не предусмотрено';
						|en = 'Disposal of fixed assets recorded on the lessor''s balance sheet is not provided'; fa = 'Disposal of fixed assets recorded on the lessor''s balance sheet is not provided';
						|it = 'Списание основных средств, учитываемых на балансе арендодателя, не предусмотрено';
						|pl = 'Disposal of fixed assets recorded on the lessor''s balance sheet is not provided';
						|tr = 'Kiraya verenin bilançosunda muhasebeleştirilen sabit kıymetlerin tasfiyesine ilişkin karşılık sağlanmamıştır'");
		Return ErrorText;
		
	EndIf; 
	
	If Package[1].IsEmpty() Then
		ErrorText = NStr("vi = 'Trong chứng từ không có tài sản cố định hữu hình mà cần ghi giảm';
						|ru = 'В документе нет основных средств, которые необходимо списать';
						|en = 'The document does not contain any fixed assets for disposal'; fa = 'The document does not contain any fixed assets for disposal';
						|it = 'В документе нет основных средств, которые необходимо списать';
						|pl = 'The document does not contain any fixed assets for disposal';
						|tr = 'Belgede gider yazılacak sabit kıymet bulunmamaktadır'");
		Return ErrorText;
	EndIf;
	
	FillPropertyValues(Object, Selection);
	
	If BegOfDay(Selection.ReferenceDocumentDateForCertificate) = BegOfDay(CurrentSessionDate()) 
		And Object.Date < Selection.ReferenceDocumentDateForCertificate Then
		Object.Date = Selection.ReferenceDocumentDateForCertificate + 1;
	EndIf;
	
	Selection = Package[1].Select();

	Object.FA.Clear();

	While Selection.Next() Do
		FillPropertyValues(Object.FA.Add(), Selection);
	EndDo;
	
	If Object.FA.Count() <> 0 
		And ValueIsFilled(Object.FA[0].FixedAsset) Then

		InitialInformation = Catalogs.Assets.InitialInformation(
			Object.FA[0].FixedAsset, Object.Date);
			
		If InitialInformation <> Undefined Then
			
			Object.RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
			Object.PostInAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentAC);
			Object.RecordInTA = ValueIsFilled(InitialInformation.CommissioningDocumentTA);
			Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;
			
			Object.Organization = InitialInformation.Organization;
			Object.Department = InitialInformation.FixedAssetsLocation;
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

//
// Parameters:
//  Object - DocumentObject.DisposeFixedAssets2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array - 
//
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.FixedAssetsPhysicalCount.FillingDataBasedOnInventory24(
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
	Object.Department = Selection.FixedAssetsLocation;
	
	PostInAccounting = False;
	RecordInTA = False;
	RecordInManAccounting = False;
	
	For Each Selection In DataToFill.TabularSection Do
		
		RowData = Object.FA.Add();
		RowData.FixedAsset = Selection.FixedAsset;
		
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
	
	If Object.FA.Count() <> 0 Then
		Object.PostInAccounting = PostInAccounting;
		Object.RecordInTA = RecordInTA;
		Object.RecordInManAccounting = RecordInManAccounting;
		Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

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
	ListOfConditions.Insert("DimensionCorrespondsToFAToWriteOff", False);
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

// Fills in the amount of the write-off based on the disposal of goods and materials.
// 
// Parameters:
//  Object - DocumentObject.DisposeFixedAssets2_4 - Document
Procedure FillInAmountOfWriteOffBasedOnDisposalOfGoodsAndMaterials(Object) Export

	If Object.BusinessOperation <> Enums.BusinessTransactions.PartialFixedAssetsDisposal Then
		Return;
	EndIf;
	
	For Each RowData In Object.FA Do
		
		RowData.AmountManagementAccounting = 0;
		RowData.ChargeAmountAccounting = 0;
		RowData.AmountTaxAccounting = 0;
		RowData.AmountPermanentDifference = 0;
		RowData.AmountTemporaryDifference = 0;
		RowData.ResidualValueMan = 0;
		RowData.ResidualValueLocal = 0;
				
	EndDo;
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	DisposalsOfGoodsAndMaterials = DisposalsOfGoodsAndMaterials(Object);
	
	If DisposalsOfGoodsAndMaterials.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
	|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
	|	InitialFixedAssetsInformation.CommissioningDateTA AS CommissioningDateTA,
	|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA
	|
	|INTO InitialFixedAssetsInformation
	|
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|		&Date,
	|		Organization = &Organization
	|			AND FixedAsset IN(&ListOfFA)) AS InitialFixedAssetsInformation
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FACostBalance.FixedAsset AS FixedAsset,
	|
	|	FACostBalance.LocalCostBalance + FACostBalance.CostTargetFinancingBalance AS LocalCost,
	|	FACostBalance.CostInTaxAccountingBalance + FACostBalance.CostTargetFinancingTABalance AS CostInTaxAccounting,
	|	FACostBalance.CostPermanentDifferenceBalance + FACostBalance.CostTargetFinancingPDBalance AS CostPermanentDifference,
	|
	|	FACostBalance.CostBalance AS Cost
	|
	|INTO CostAtBeginningOfMonth
	|
	|FROM
	|	AccumulationRegister.FACost.Balance(
	|		&BegOfMonth, 
	|		Organization = &Organization
	|			AND FixedAsset IN(&ListOfFA)) AS FACostBalance
	|
	|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.FixedAsset = FACostBalance.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FACostBalance.FixedAsset AS FixedAsset,
	|
	|	FACostBalance.PreliminaryCostLocalBalance AS LocalCost,
	|	FACostBalance.PreliminaryCostManBalance AS Cost
	|
	|INTO PreliminaryCostMan
	|
	|FROM
	|	AccumulationRegister.FACost.Balance(
	|		&Date, 
	|		Organization = &Organization
	|			AND FixedAsset IN(&ListOfFA)) AS FACostBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OSBUDepreciationParameters.FixedAsset AS FixedAsset,
	|	OSBUDepreciationParameters.ResidualValueMan AS ResidualValueMan
	|INTO OSBUDepreciationParameters
	|FROM
	|	InformationRegister.OSBUDepreciationParameters.SliceLast(
	|			&DateOfFirstDisposal,
	|			Recorder <> &Ref
	|				AND Organization = &Organization 
	|				AND FixedAsset IN (&ListOfFA)) AS OSBUDepreciationParameters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FixedAssetDepreciationParametersManagementAccounting.FixedAsset AS FixedAsset,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan AS ResidualValueMan
	|INTO FixedAssetDepreciationParametersManagementAccounting
	|FROM
	|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
	|			&DateOfFirstDisposal, 
	|			Recorder <> &Ref
	|				AND Organization = &Organization 
	|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
	|
	|	ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0) AS ResidualValueLocal,
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateAC, MONTH) = &BegOfMonth
	|			THEN ISNULL(PreliminaryCostMan.LocalCost, 0)
	|		ELSE ISNULL(CostAtBeginningOfMonth.LocalCost, 0)
	|	END AS LocalCost,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateTA, MONTH) = &BegOfMonth
	|			THEN ISNULL(PreliminaryCostMan.LocalCost, 0)
	|		ELSE ISNULL(CostAtBeginningOfMonth.CostInTaxAccounting, 0)
	|	END AS CostInTaxAccounting,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateTA, MONTH) = &BegOfMonth
	|			THEN 0
	|		ELSE ISNULL(CostAtBeginningOfMonth.CostPermanentDifference, 0)
	|	END AS CostPermanentDifference,
	|
	|	CASE
	|		WHEN BEGINOFPERIOD(InitialFixedAssetsInformation.CommissioningDateMA, MONTH) = &BegOfMonth
	|			THEN ISNULL(PreliminaryCostMan.Cost, 0)
	|		ELSE ISNULL(CostAtBeginningOfMonth.Cost, 0)
	|	END AS Cost
	|
	|FROM
	|	InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|
	|		LEFT JOIN CostAtBeginningOfMonth AS CostAtBeginningOfMonth
	|		ON CostAtBeginningOfMonth.FixedAsset = InitialFixedAssetsInformation.FixedAsset
	|
	|		LEFT JOIN PreliminaryCostMan AS PreliminaryCostMan
	|		ON PreliminaryCostMan.FixedAsset = InitialFixedAssetsInformation.FixedAsset
	|
	|		LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
	|		ON OSBUDepreciationParameters.FixedAsset = InitialFixedAssetsInformation.FixedAsset
	|
	|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.FixedAsset = InitialFixedAssetsInformation.FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("BegOfMonth", BegOfMonth(Object.Date));
	Query.SetParameter("DateOfFirstDisposal", DisposalsOfGoodsAndMaterials[0].Period);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	CostTable_ = Query.Execute().Unload();
	CostTable_.Indexes.Add("FixedAsset");
	
	For Each RowData In Object.FA Do
		
		If Not ValueIsFilled(RowData.FixedAsset) Then
			Continue;
		EndIf;
		
		CostRow = CostTable_.Find(RowData.FixedAsset, "FixedAsset");
		
		If CostRow = Undefined Then
			Continue;
		EndIf;
		
		For Each LineDisposal In DisposalsOfGoodsAndMaterials Do
			
			If LineDisposal.FixedAsset <> RowData.FixedAsset Then
				Continue;
			EndIf;

			If LineDisposal.Base <> LineDisposal.BaseBeforeDisposal Then
				ZoomRatio = ?(LineDisposal.BaseBeforeDisposal <> 0, LineDisposal.Base / LineDisposal.BaseBeforeDisposal, 0);
			Else
				ZoomRatio = 1;
			EndIf;
				
			AmountManagementAccounting = Round(CostRow.Cost * ZoomRatio, 2);
			ChargeAmountAccounting = Round(CostRow.LocalCost * ZoomRatio, 2);
			AmountTaxAccounting = Round(CostRow.CostInTaxAccounting * ZoomRatio, 2);
			AmountPermanentDifference = Round(CostRow.CostPermanentDifference * ZoomRatio, 2);
			AmountOfWriteOffOfLSB = Round(CostRow.ResidualValueLocal * ZoomRatio, 2);
			AmountOfLSUDebiting = Round(CostRow.ResidualValueMan * ZoomRatio, 2);
			
			CostRow.Cost = CostRow.Cost - AmountManagementAccounting;
			CostRow.LocalCost = CostRow.LocalCost - ChargeAmountAccounting;
			CostRow.CostInTaxAccounting = CostRow.CostInTaxAccounting - AmountTaxAccounting;
			CostRow.CostPermanentDifference = CostRow.CostPermanentDifference - AmountPermanentDifference;
			
			CostRow.ResidualValueMan = CostRow.ResidualValueMan - AmountOfLSUDebiting;
			CostRow.ResidualValueLocal = CostRow.ResidualValueLocal - AmountOfWriteOffOfLSB;
			
			If LineDisposal.TakeInto Then
			
				If Object.RecordInManAccounting Then
					RowData.AmountManagementAccounting = RowData.AmountManagementAccounting + AmountManagementAccounting;
					RowData.ResidualValueMan = CostRow.ResidualValueMan;
				EndIf;
				
				If Object.PostInAccounting Then
					
					RowData.ChargeAmountAccounting = RowData.ChargeAmountAccounting + ChargeAmountAccounting;
					RowData.AmountPermanentDifference = RowData.AmountPermanentDifference + AmountPermanentDifference;
					
					RowData.ResidualValueLocal = CostRow.ResidualValueLocal;
					
				EndIf;
		
				If Object.RecordInTA Then
					
					RowData.AmountTaxAccounting = RowData.AmountTaxAccounting + AmountTaxAccounting;
					
				EndIf;
		
				RowData.AmountTemporaryDifference = 
					RowData.ChargeAmountAccounting
					- RowData.AmountTaxAccounting
					- RowData.AmountPermanentDifference;
		
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Fills in the disposal item.
// 
// Parameters:
//  Organization - CatalogRef.Companies - 
//  Date - Date - 
//  TabularSection - TabularSection - 
//  RetirementItem  - ChartOfCharacteristicTypesRef.ExpenseItems - 
Procedure FillInExpenseItemRetirement(Organization, Date, TabularSection, RetirementItem) Export
	
	ListOfFA = New Array;
	
	For Each RowData In TabularSection Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;

	QueryText = 
	"SELECT DISTINCT
	|	ISNULL(FixedAssetsAccountingProcedure.FinancialAccountingGroup.AssetKind, UNDEFINED) AS AssetKind
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|		&Date,
	|		CorrectionDate = DATETIME(1,1,1)
	|			AND Organization = &Organization
	|			AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedure
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	
	AvailableArticles = New Array;
	
	Selection = Result.Select();
	If Selection.Next() Then
		
		If Selection.AssetKind = Enums.KindsOfNonCurrentAssets.FixedAssetsProvidedToLessee Then
			NewArticle = ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetRetirement;
		Else
			NewArticle = ChartsOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses;
		EndIf;
		
		If AvailableArticles.Find(NewArticle) = Undefined Then
			AvailableArticles.Add(NewArticle);
		EndIf;
		
	EndIf;

	If AvailableArticles.Count() = 0 Then
		Return;
	EndIf;
	
	If AvailableArticles.Count() = 1
		Or Not ValueIsFilled(RetirementItem) Then
			
		RetirementItem = AvailableArticles[0];
		
	EndIf;
	
EndProcedure

Function DisposalsOfGoodsAndMaterials(Object)

	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	ListOfGrounds = New Array;
	If ValueIsFilled(Object.DocumentBasis)
		And (TypeOf(Object.DocumentBasis) = Type("DocumentRef.OtherGoodsRecordingAsReceived")
			Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.Decomissioning")) Then
				
		ListOfGrounds.Add(Object.DocumentBasis);
	EndIf;
	For Each RowData In Object.Basis1 Do
		If ValueIsFilled(RowData.DocumentBasis)
			And (TypeOf(RowData.DocumentBasis) = Type("DocumentRef.OtherGoodsRecordingAsReceived")
				Or TypeOf(RowData.DocumentBasis) = Type("DocumentRef.Decomissioning")) Then
					
			ListOfGrounds.Add(RowData.DocumentBasis);
		EndIf;
	EndDo;
	
	BeginOfPeriod = BegOfMonth(Object.Date);
	EndOfPeriod = EndOfDay(Object.Date);
		
	If ListOfGrounds.Count() <> 0 Then
		
		QueryText = 
		"SELECT
		|	ISNULL(MIN(DocumentData.BeginOfPeriod), &BeginOfPeriod) AS BeginOfPeriod,
		|	ISNULL(MAX(DocumentData.EndOfPeriod), &EndOfPeriod) AS EndOfPeriod
		|FROM
		|	(SELECT
		|		MIN(DocumentData.Date) AS BeginOfPeriod,
		|		MAX(DocumentData.Date) AS EndOfPeriod
		|	FROM
		|		Document.OtherGoodsRecordingAsReceived AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN (&ListOfGrounds)
		|
		|	UNION ALL
		|
		|	SELECT
		|		MIN(DocumentData.Date) AS BeginOfPeriod,
		|		MAX(DocumentData.Date) AS EndOfPeriod
		|	FROM
		|		Document.Decomissioning AS DocumentData
		|	WHERE
		|		DocumentData.Ref IN (&ListOfGrounds)
		|
		|	) AS DocumentData";
		
		Query = New Query(QueryText);
		Query.SetParameter("ListOfGrounds", ListOfGrounds);
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", EndOfPeriod);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
			
			BeginOfPeriod = BegOfMonth(Selection.BeginOfPeriod);
			
			If BeginOfPeriod > EndOfPeriod Then
				EndOfPeriod = Selection.EndOfPeriod;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ListOfRequests = New Array;
	
	QueryText = 
	"SELECT
	|	LotsOfGoodsAndMaterials.Ref AS Ref
	|
	|INTO LotsOfGoodsAndMaterials
	|
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS LotsOfGoodsAndMaterials
	|WHERE
	|	LotsOfGoodsAndMaterials.FixedAsset IN (&ListOfFA)
	|	AND LotsOfGoodsAndMaterials.OperationCategory.AccountAsGroupFA
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryInOperation.Period AS Period,
	|	InventoryInOperation.Recorder AS Recorder,
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Lot.FixedAsset AS FixedAsset,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.AssetID AS AssetID,
	|	InventoryInOperation.Lot AS Lot,
	|
	|	SUM(InventoryInOperation.Count) AS Count
	|
	|INTO DisposalOfGoodsAndMaterials
	|
	|FROM
	|	AccumulationRegister.InventoryInOperation AS InventoryInOperation
	|WHERE
	|	InventoryInOperation.Active
	|	AND InventoryInOperation.Organization = &Organization
	|	AND InventoryInOperation.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|
	|	AND InventoryInOperation.Lot IN
	|			(SELECT
	|				LotsOfGoodsAndMaterials.Ref
	|			FROM
	|				LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)
	|
	|	AND InventoryInOperation.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.Decomissioning),
	|		VALUE(Enum.BusinessTransactions.PutOutOfOperation))
	|
	|GROUP BY
	|	InventoryInOperation.Period,
	|	InventoryInOperation.Recorder,
	|	InventoryInOperation.Organization,
	|	InventoryInOperation.Lot.FixedAsset,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.Series,
	|	InventoryInOperation.AssetID,
	|	InventoryInOperation.Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Lot.FixedAsset AS FixedAsset,
	|
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.AssetID AS AssetID,
	|	InventoryInOperation.Lot AS Lot,
	|
	|	InventoryInOperation.CountBalance AS Count
	|
	|INTO RemnantsOfGoodsAndMaterials
	|
	|FROM
	|	AccumulationRegister.InventoryInOperation.Balance(
	|		&BeginOfPeriod,
	|		Organization = &Organization
	|			AND Lot IN
	|			(SELECT
	|				LotsOfGoodsAndMaterials.Ref
	|			FROM
	|				LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS InventoryInOperation
	|
	|WHERE
	|	InventoryInOperation.CountBalance > 0
	|
	|INDEX BY
	|	FixedAsset
	|;
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	MAX(DisposeFixedAssets.Date) AS Period
	|
	|INTO PreviousWriteOffs
	|
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DisposeFixedAssets
	|
	|		INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|		ON FATable.Ref = DisposeFixedAssets.Ref
	|
	|WHERE
	|	DisposeFixedAssets.Date >= &BeginOfPeriod
	|	AND DisposeFixedAssets.Date < &EndOfPeriod
	|	AND FATable.FixedAsset IN (
	|			SELECT
	|				DisposalOfGoodsAndMaterials.FixedAsset
	|			FROM 
	|				DisposalOfGoodsAndMaterials AS DisposalOfGoodsAndMaterials)
	|
	|GROUP BY
	|	FATable.FixedAsset
	|	
	|INDEX BY
	|	FixedAsset
	|;
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryInOperation.FixedAsset AS FixedAsset,
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.AssetID AS AssetID,
	|	InventoryInOperation.Lot AS Lot
	|
	|INTO TMTSVOperation_All
	|
	|FROM
	|	(SELECT
	|		DisposalOfGoodsAndMaterials.Organization AS Organization,
	|		DisposalOfGoodsAndMaterials.FixedAsset AS FixedAsset,
	|		DisposalOfGoodsAndMaterials.Products AS Products,
	|		DisposalOfGoodsAndMaterials.Characteristic AS Characteristic,
	|		DisposalOfGoodsAndMaterials.Series AS Series,
	|		DisposalOfGoodsAndMaterials.AssetID AS AssetID,
	|		DisposalOfGoodsAndMaterials.Lot AS Lot
	|	FROM
	|		DisposalOfGoodsAndMaterials AS DisposalOfGoodsAndMaterials
	|
	|	UNION ALL
	|
	|	SELECT
	|		RemnantsOfGoodsAndMaterials.Organization AS Organization,
	|		RemnantsOfGoodsAndMaterials.FixedAsset AS FixedAsset,
	|		RemnantsOfGoodsAndMaterials.Products AS Products,
	|		RemnantsOfGoodsAndMaterials.Characteristic AS Characteristic,
	|		RemnantsOfGoodsAndMaterials.Series AS Series,
	|		RemnantsOfGoodsAndMaterials.AssetID AS AssetID,
	|		RemnantsOfGoodsAndMaterials.Lot AS Lot
	|	FROM
	|		RemnantsOfGoodsAndMaterials AS RemnantsOfGoodsAndMaterials
	|
	|	) AS InventoryInOperation
	|
	|INDEX BY
	|	Organization,
	|	Products,
	|	Characteristic,
	|	Series,
	|	AssetID,
	|	Lot
	|;
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	TMTSVOperation_All.FixedAsset AS FixedAsset,
	|	Cost_Inventory.Organization AS Organization,
	|	Cost_Inventory.Products AS Products,
	|	Cost_Inventory.Characteristic AS Characteristic,
	|	Cost_Inventory.Series AS Series,
	|	Cost_Inventory.AssetID AS AssetID,
	|	Cost_Inventory.Lot AS Lot,
	|
	|	CASE
	|		WHEN SUM(Cost_Inventory.Count) <> 0
	|			THEN SUM(Cost_Inventory.CostMan) / SUM(Cost_Inventory.Count)
	|		ELSE 0
	|	END AS Price
	|
	|INTO InventoryInOperation_Price
	|
	|FROM
	|	TMTSVOperation_All AS TMTSVOperation_All
	|
	|		INNER JOIN InformationRegister.CostOfInventoryInOperation AS Cost_Inventory
	|		ON Cost_Inventory.Organization = TMTSVOperation_All.Organization
	|			AND Cost_Inventory.Products = TMTSVOperation_All.Products
	|			AND Cost_Inventory.Characteristic = TMTSVOperation_All.Characteristic
	|			AND Cost_Inventory.Series = TMTSVOperation_All.Series
	|			AND Cost_Inventory.AssetID = TMTSVOperation_All.AssetID
	|			AND Cost_Inventory.Lot = TMTSVOperation_All.Lot
	|
	|GROUP BY
	|	TMTSVOperation_All.FixedAsset,
	|	Cost_Inventory.Organization,
	|	Cost_Inventory.Products,
	|	Cost_Inventory.Characteristic,
	|	Cost_Inventory.Series,
	|	Cost_Inventory.AssetID,
	|	Cost_Inventory.Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalOfGoodsAndMaterials.Period AS Period,
	|	DisposalOfGoodsAndMaterials.Recorder AS Recorder,
	|	DisposalOfGoodsAndMaterials.FixedAsset AS FixedAsset,
	|
	|	SUM(DisposalOfGoodsAndMaterials.Count) AS Count,
	|	SUM(DisposalOfGoodsAndMaterials.Count * ISNULL(InventoryInOperation_Price.Price, 0)) AS Base
	|
	|INTO DisposalOfTMC_Base
	|
	|FROM
	|	DisposalOfGoodsAndMaterials AS DisposalOfGoodsAndMaterials
	|
	|		LEFT JOIN InventoryInOperation_Price AS InventoryInOperation_Price
	|		ON InventoryInOperation_Price.FixedAsset = DisposalOfGoodsAndMaterials.FixedAsset
	|			AND InventoryInOperation_Price.Organization = DisposalOfGoodsAndMaterials.Organization
	|			AND InventoryInOperation_Price.Products = DisposalOfGoodsAndMaterials.Products
	|			AND InventoryInOperation_Price.Characteristic = DisposalOfGoodsAndMaterials.Characteristic
	|			AND InventoryInOperation_Price.Series = DisposalOfGoodsAndMaterials.Series
	|			AND InventoryInOperation_Price.AssetID = DisposalOfGoodsAndMaterials.AssetID
	|			AND InventoryInOperation_Price.Lot = DisposalOfGoodsAndMaterials.Lot
	|
	|GROUP BY
	|	DisposalOfGoodsAndMaterials.Period,
	|	DisposalOfGoodsAndMaterials.Recorder,
	|	DisposalOfGoodsAndMaterials.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemnantsOfGoodsAndMaterials.FixedAsset AS FixedAsset,
	|
	|	SUM(RemnantsOfGoodsAndMaterials.Count) AS Count,
	|	SUM(RemnantsOfGoodsAndMaterials.Count * ISNULL(InventoryInOperation_Price.Price, 0)) AS Base
	|
	|INTO RemnantsOfTMTS_Base
	|
	|FROM
	|	RemnantsOfGoodsAndMaterials AS RemnantsOfGoodsAndMaterials
	|
	|		LEFT JOIN InventoryInOperation_Price AS InventoryInOperation_Price
	|		ON InventoryInOperation_Price.FixedAsset = RemnantsOfGoodsAndMaterials.FixedAsset
	|			AND InventoryInOperation_Price.Organization = RemnantsOfGoodsAndMaterials.Organization
	|			AND InventoryInOperation_Price.Products = RemnantsOfGoodsAndMaterials.Products
	|			AND InventoryInOperation_Price.Characteristic = RemnantsOfGoodsAndMaterials.Characteristic
	|			AND InventoryInOperation_Price.Series = RemnantsOfGoodsAndMaterials.Series
	|			AND InventoryInOperation_Price.AssetID = RemnantsOfGoodsAndMaterials.AssetID
	|			AND InventoryInOperation_Price.Lot = RemnantsOfGoodsAndMaterials.Lot
	|
	|GROUP BY
	|	RemnantsOfGoodsAndMaterials.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalOfTMC_Base.Recorder AS Recorder,
	|	DisposalOfTMC_Base.FixedAsset AS FixedAsset,
	|
	|	SUM(PreviousDisposalOfTMC_Base.Count) AS Count,
	|	SUM(PreviousDisposalOfTMC_Base.Base) AS Base
	|
	|INTO PreviousDisposalOfTMC_Base
	|
	|FROM
	|	DisposalOfTMC_Base AS DisposalOfTMC_Base
	|
	|		INNER JOIN DisposalOfTMC_Base AS PreviousDisposalOfTMC_Base
	|		ON PreviousDisposalOfTMC_Base.FixedAsset = DisposalOfTMC_Base.FixedAsset
	|			AND PreviousDisposalOfTMC_Base.Recorder <> DisposalOfTMC_Base.Recorder
	|			AND PreviousDisposalOfTMC_Base.Period < DisposalOfTMC_Base.Period
	|
	|GROUP BY
	|	DisposalOfTMC_Base.Recorder,
	|	DisposalOfTMC_Base.FixedAsset
	|
	|INDEX BY
	|	Recorder,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalOfTMC_Base.Period AS Period,
	|	DisposalOfTMC_Base.FixedAsset AS FixedAsset,
	|
	|	DisposalOfTMC_Base.Count AS Count,
	|	DisposalOfTMC_Base.Base AS Base,
	|
	|	ISNULL(RemnantsOfTMTS_Base.Count, 0) - ISNULL(PreviousDisposalOfTMC_Base.Count, 0) AS QuantityBeforeDisposal,
	|	ISNULL(RemnantsOfTMTS_Base.Base, 0) - ISNULL(PreviousDisposalOfTMC_Base.Base, 0) AS BaseBeforeDisposal,
	|
	|	CASE
	|		WHEN &UseListOfBases
	|			THEN DisposalOfTMC_Base.Recorder IN (&ListOfGrounds)
	|		ELSE DisposalOfTMC_Base.Period > ISNULL(PreviousWriteOffs.Period, DATETIME(1,1,1))
	|	END AS TakeInto
	|
	|FROM
	|	DisposalOfTMC_Base AS DisposalOfTMC_Base
	|
	|		LEFT JOIN PreviousWriteOffs AS PreviousWriteOffs
	|		ON PreviousWriteOffs.FixedAsset = DisposalOfTMC_Base.FixedAsset
	|		
	|		LEFT JOIN RemnantsOfTMTS_Base AS RemnantsOfTMTS_Base
	|		ON RemnantsOfTMTS_Base.FixedAsset = DisposalOfTMC_Base.FixedAsset
	|		
	|		LEFT JOIN PreviousDisposalOfTMC_Base AS PreviousDisposalOfTMC_Base
	|		ON PreviousDisposalOfTMC_Base.FixedAsset = DisposalOfTMC_Base.FixedAsset
	|			AND PreviousDisposalOfTMC_Base.Recorder = DisposalOfTMC_Base.Recorder
	|
	|ORDER BY
	|	Period";
	ListOfRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("ListOfFA", ListOfFA);
	Query.SetParameter("ListOfGrounds", ListOfGrounds);
	Query.SetParameter("UseListOfBases", ListOfGrounds.Count() <> 0);
	
	DisposalsOfGoodsAndMaterials = Query.Execute().Unload();
	
	Return DisposalsOfGoodsAndMaterials;
	
EndFunction

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
	Handler.Procedure = "Documents.DisposeFixedAssets2_4.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("48a41932-7ddc-470f-bd76-bf2acd3b452f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.DisposeFixedAssets2_4.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Đang cập nhật chứng từ ""Ghi giảm TSCĐ hữu hình"":
								  |- điền mục tin mới ""Phản ánh trong KTTh""';
								  |ru = 'Обновляет документы ""Списание ОС"":
								  |- заполняет новый реквизит ""Отражать в НУ"".';
								  |en = 'Updates the ""Dispose fixed assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.'; fa = 'Updates the ""Dispose fixed assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |it = 'Updates the ""Dispose fixed assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |pl = 'Updates the ""Dispose fixed assets"" documents:
								  |- Fills in the new ""Record in TA"" attribute.';
								  |tr = '""Sabit kıymetlerin tasfiyesi"" belgelerini günceller: 
								  | - yeni ""VM''DE yansıtın"" özniteliğini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DisposeFixedAssets2_4.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.DisposeFixedAssets2_4.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.DisposeFixedAssets2_4.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.DisposeFixedAssets2_4";
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
	|		Document.DisposeFixedAssets2_4 AS DocumentData
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

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.DisposeFixedAssets2_4.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.DisposeFixedAssets2_4";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.DisposeFixedAssets2_4
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
