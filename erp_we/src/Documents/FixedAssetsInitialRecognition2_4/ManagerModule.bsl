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
	DocumentMechanisms.Add("ImpairmentFA");
	
	FixedAssetsInitialRecognitionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.FixedAssetsInitialRecognition2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		AddlParameters.OnlyMarkedOnes = Registers <> Undefined;
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers);
		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableCGUComposition(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		FixedAssetsInitialRecognitionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
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
	QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Undefined);
	QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	FixedAssetsInitialRecognitionLocalization.TablesForCalculatingCost(Query, QueryTexts);
	
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
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	Documents.AllocateVariancesToFixedAssetCost.AddGenerateCommand(GenerationCommands);
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	FixedAssetsInitialRecognitionLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "acceptance for OS accounting".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order	- Number	- The order of the command.
//
// Returns:
//	- ValueTableRow: See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	- Undefined
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.FixedAssetsInitialRecognition2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.FixedAssetsInitialRecognition2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Order = Order;
		
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
	
	If UserRightsCached.PrintPriceTagsAndLabels() Then
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "NonCurrentAssetsClient.PrintingLabelsOfObjectsOfOperationFromDocument";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "Labels";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	FixedAssetsInitialRecognitionLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	FixedAssetsInitialRecognitionLocalization.AddReportCommands(ReportsCommands, Parameters);

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

Procedure FillInCost(Object, RowsSelected = Undefined) Export

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
	Query.SetParameter("PartialCommissioning", Object.PartialCommissioning);
	Query.SetParameter("AccountingProcedureMA", Object.AccountingProcedureMA);
	Query.SetParameter("AccountingProcedureAC", Object.AccountingProcedureAC);
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
		EndIf; 
		
		If Object.RecordInTA Then
			RowData.CostInTaxAccounting = ListOfExpenseLines[0].AmountFA;
		EndIf; 
		
		If Object.PostInAccounting Or Object.RecordInTA Then
			RowData.CostPermanentDifference = ListOfExpenseLines[0].AmountPermanentDifferences;
		EndIf; 

	EndDo;
	
	FixedAssetsInitialRecognitionLocalization.FillInCost(Object, StringsList, FATable);
	
EndProcedure

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
		NStr("vi = 'Giá trị';
			|ru = 'Стоимость';
			|en = 'Cost'; fa = 'بهای تمام‌شده';
			|it = 'Cost';
			|pl = 'Cost';
			|tr = 'Maliyet'"), 
		NStr("vi = 'Giá trị (KTDN)';
			|ru = 'Стоимость (БУ)';
			|en = 'Cost (LA)'; fa = 'بها (محلی)';
			|it = 'Costo (contabilità)';
			|pl = 'Wartość (EK)';
			|tr = 'Maliyet (LA)'"), 
		FALocalAccountingIsConductedIndependently, 
		ComplCurrency = CurrencyOfMan,
		ComplCurrencyPresentation);
	
	PresentationOfDetails.Insert("FA.CostInAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
		NStr("vi = 'Giá trị';
			|ru = 'Стоимость';
			|en = 'Cost'; fa = 'بهای تمام‌شده';
			|it = 'Cost';
			|pl = 'Cost';
			|tr = 'Maliyet'"), 
		NStr("vi = 'Giá trị (KTQT)';
			|ru = 'Стоимость (УУ)';
			|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
			|it = 'Costo contabilità gestionale';
			|pl = 'Wartość (EZ)';
			|tr = 'Maliyet (YM)'"), 
		FALocalAccountingIsConductedIndependently, 
		ComplCurrency = CurrencyOfMan,
		CurrencyOfManPresentation);
		
	PresentationOfDetails.Insert("FA.CostInManagementAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTTh)';
																			|ru = 'Стоимость (НУ)';
																			|en = 'Cost (TA)'; fa = 'بها (مالیاتی)';
																			|it = 'Costo (contabilità fiscale)';
																			|pl = 'Wartość (EP)';
																			|tr = 'Maliyet (VM)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.CostInTaxAccounting", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (CLVV)';
																			|ru = 'Стоимость (ПР)';
																			|en = 'Cost (PD)'; fa = 'بها (تفاوت دائم)';
																			|it = 'Costo (differenze permanenti)';
																			|pl = 'Wartość (RT)';
																			|tr = 'Maliyet (SF)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.CostPermanentDifference", FieldPresentation);

	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị thanh lý pháp quy';
																			|ru = 'Ликвидационная стоимость регл.';
																			|en = 'Residual value local'; fa = 'Residual value local';
																			|it = 'Ликвидационная стоимость регл.';
																			|pl = 'Residual value local';
																			|tr = 'Artık değer (yerel)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("FA.ResidualValueLocal", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị thanh lý quản lý';
																			|ru = 'Ликвидационная стоимость упр.';
																			|en = 'Residual value mgmt'; fa = 'Residual value mgmt';
																			|it = 'Residual value mgmt';
																			|pl = 'Residual value mgmt';
																			|tr = 'Tasfiye değeri yön.'"), CurrencyOfManPresentation);
	PresentationOfDetails.Insert("FA.ResidualValueMan", FieldPresentation);
		
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

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.FixedAssetsInitialRecognition2_4";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("Partner", "DocumentData.Contract.Partner");
	RedefiningParameterCalculation.Insert("Counterparty", "DocumentData.Contract.Counterparty");
	RedefiningParameterCalculation.Insert("AdditionalRegistry", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		
		QueryText = FixedAssetsInitialRecognitionLocalization.AdaptedCaseSensitiveQueryText(
							RegisterName, RedefiningParameterCalculation, SynonymForDocumentTable);
		
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
	|	DocumentData.DateOfRecognition AS DateOfRecognition
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
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentsList
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
	|	DocumentData.Contract.Partner AS Partner,
	|	DocumentData.Contract.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.FixedAssetsLocation AS FixedAssetsLocation,
	|	DocumentData.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.ConstructionObject AS ConstructionObject,
	|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
	|	DocumentData.AccountingProcedureAC AS AccountingProcedureAC,
	|	DocumentData.AccountingProcedureMA AS AccountingProcedureMA,
	|	DocumentData.LocationAddress AS LocationAddress,
	|	DocumentData.LocationAddressValue AS LocationAddressValue,
	|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualManagementAccounting,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	DocumentData.UsefulLifeAccounting AS UsefulLifeAccounting,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	DocumentData.AccelerationFactorAccounting AS AccelerationFactorAccounting,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactorManagementAccounting,
	|
	|	CASE WHEN DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|		THEN VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|		ELSE DocumentData.DepreciationMethodAccounting
	|	END AS DepreciationMethodAccounting,
	|
	|	CASE
	|		WHEN
	|			DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|			THEN VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.Linear)
	|		ELSE DocumentData.DepreciationAccrualMethodManagementAccounting
	|	END AS DepreciationAccrualMethodManagementAccounting,
	|
	|	DocumentData.AdjustmentModeFromPreviousDate AS AdjustmentModeFromPreviousDate,
	|
	|	CASE
	|		WHEN DocumentData.AdjustmentModeFromPreviousDate
	|			THEN DocumentData.DateOfRecognition
	|		ELSE DocumentData.Date
	|	END AS DateOfRecognition,
	|
	|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|	DocumentData.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	DocumentData.ExpenseItemAccounting.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	DocumentData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	DocumentData.DepartmentACC AS DepartmentACC,
	|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping AS BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting
	|
	|		ELSE DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	| 
	|	END AS BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.ExpenseRecordMethodAC
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.ExpenseRecordMethodTA
	|
	|		ELSE DocumentData.MethodForReflectingMaExpenses
	| 
	|	END AS MethodForReflectingMaExpenses,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.ExpenseItemAccounting
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.ExpenseItemTaxAccounting
	|
	|		ELSE DocumentData.ExpenseItemManagementAccounting
	| 
	|	END AS ExpenseItemManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			
	|			THEN UNDEFINED
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.ExpensesDimensionAccounting
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.ExpensesDimensionTaxAccounting
	|
	|		ELSE DocumentData.ExpensesDimensionManagementAccounting
	| 
	|	END AS ExpensesDimensionManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.DepartmentACC
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.BusinessUnitTaxAccounting
	|
	|		ELSE DocumentData.BusinessUnitManagementAccounting
	| 
	|	END AS BusinessUnitManagementAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN DocumentData.LineOfBusinessBookkeeping
	|
	|		WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND DocumentData.RecordInManAccounting
	|				AND DocumentData.RecordInLocalAccounting
	|				AND (DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)
	|					OR DocumentData.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued))
	|
	|			THEN DocumentData.LineOfBusinessTaxAccounting
	|
	|		ELSE DocumentData.LineOfBusinessManagementAccounting
	| 
	|	END AS LineOfBusinessManagementAccounting,
	|
	|	CASE WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND DocumentData.RecordInManAccounting
	|		THEN DocumentData.ExpenseItemAccounting.CostAllocationOptionManag
	|		ELSE DocumentData.ExpenseItemManagementAccounting.CostAllocationOptionManag 
	|	END AS CostAllocationOptionManag,
	|
	|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DocumentData.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	DocumentData.CGU AS CGU,
	|
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|
	|	0 AS PackageNumber,
	|
	|	&AcceptanceForAccountingOS_DocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
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
	|	Ref
	|";
	FixedAssetsInitialRecognitionLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
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
	|	DocumentTable.AmountOfTargetFunds AS AmountOfTargetFunds,
	|	DocumentTable.ResidualValueMan AS ResidualValueMan,
	|	DocumentTable.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentTable.RunningTimeValue AS RunningTimeValue,
	|	DocumentTable.EstimatedRunningTime AS EstimatedRunningTime
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4.FA AS DocumentTable
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
	FixedAssetsInitialRecognitionLocalization.ValuesOfHoldingParameters(ValuesOfHoldingParameters);
	
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FixedAssetsInitialRecognition2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Bắt đầu hạch toán TSCĐ hữu hình';
															|ru = 'Принятие к учету ОС';
															|en = 'Fixed assets — Initial recognition'; fa = 'دارایی‌های ثابت — شناسایی اولیه';
															|it = 'Scrittura nei libri contabili Cespiti';
															|pl = 'Przyjęcie do ewidencji środków trwałych';
															|tr = 'Sabit kıymetler - İlk tahakkuk'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		If Attributes.AdjustmentModeFromPreviousDate
			And ValueIsFilled(Attributes.DateOfRecognition) Then
			ValuesOfHoldingParameters.Insert("AdditionalRegistry", StrTemplate(NStr("vi = 'Tiếp nhận vào kế toán từ ngày %1 trước đó';
																					|ru = 'Принятие к учету с прошлой даты %1';
																					|en = 'Recognize %1 from previous date'; fa = 'Recognize %1 from previous date';
																					|it = 'Recognize %1 from previous date';
																					|pl = 'Recognize %1 from previous date';
																					|tr = '%1 geçmiş tarihinden itibaren muhasebeleştirme'"), Format(Attributes.DateOfRecognition, "DLF=D;")));
		Else
			ValuesOfHoldingParameters.Insert("AdditionalRegistry", "");
		EndIf;
		
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
	|	DocumentData.Contract.Partner         AS Partner,
	|	DocumentData.Contract.Counterparty      AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.FixedAssetsLocation         AS Department,
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
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
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
	|	DocumentData.FixedAssetsLocation         AS Department,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
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
	|			THEN DocumentData.DateOfRecognition
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
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DATETIME(1,1,1)                             AS CorrectionDate,
	|	DocumentData.Organization                  AS Organization,
	|	FATable.FixedAsset                   AS FixedAsset,
	|	DocumentData.FinanciallyLiablePerson                          AS FinanciallyLiablePerson,
	|	DocumentData.FixedAssetsLocation              AS FixedAssetsLocation,
	|	DocumentData.LocationAddress         AS LocationAddress,
	|	DocumentData.LocationAddressValue AS LocationAddressValue,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.DateOfRecognition           AS Period,
	|	DocumentData.Period                       AS CorrectionDate,
	|	DocumentData.Organization                  AS Organization,
	|	FATable.FixedAsset                   AS FixedAsset,
	|	DocumentData.FinanciallyLiablePerson                          AS FinanciallyLiablePerson,
	|	DocumentData.FixedAssetsLocation              AS FixedAssetsLocation,
	|	DocumentData.LocationAddress         AS LocationAddress,
	|	DocumentData.LocationAddressValue AS LocationAddressValue,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableFixedAssetsAccountingProcedure();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Period                  AS Period,
		|	DATETIME(1,1,1)                        AS CorrectionDate,
		|	DocumentData.Organization             AS Organization,
		|	FATable.FixedAsset              AS FixedAsset,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
		|	FATable.RunningTimeValue           AS RunningTimeValue,
		|	FATable.EstimatedRunningTime                AS EstimatedRunningTime,
		|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting       AS RecordInManAccounting
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|WHERE
		|	(DocumentData.PostInAccounting 
		|		OR DocumentData.RecordInManAccounting)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.DateOfRecognition      AS Period,
		|	DocumentData.Period                  AS CorrectionDate,
		|	DocumentData.Organization             AS Organization,
		|	FATable.FixedAsset              AS FixedAsset,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
		|	FATable.RunningTimeValue           AS RunningTimeValue,
		|	FATable.EstimatedRunningTime                AS EstimatedRunningTime,
		|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting       AS RecordInManAccounting
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.AdjustmentModeFromPreviousDate
		|	AND (DocumentData.PostInAccounting 
		|		OR DocumentData.RecordInManAccounting)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts);
	
	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		QueryText =
		"SELECT
		|	DocumentData.Period         AS Period,
		|	DATETIME(1,1,1)               AS CorrectionDate,
		|	DocumentData.Organization    AS Organization,
		|	FATable.FixedAsset     AS FixedAsset,
		|
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemAccounting AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
		|	DocumentData.DepartmentACC AS DepartmentACC,
		|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
		|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.PostInAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.DateOfRecognition AS Period,
		|	DocumentData.Period         AS CorrectionDate,
		|	DocumentData.Organization    AS Organization,
		|	FATable.FixedAsset     AS FixedAsset,
		|
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemAccounting AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
		|	DocumentData.DepartmentACC AS DepartmentACC,
		|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
		|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.PostInAccounting
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Period        AS Period,
		|	DATETIME(1,1,1)              AS CorrectionDate,
		|	DocumentData.Organization   AS Organization,
		|	FATable.FixedAsset    AS FixedAsset,
		|
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|
		|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualAccounting,
		|	DocumentData.MethodForReflectingMaExpenses AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemManagementAccounting AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionManagementAccounting AS ExpensesDimensionAccounting,
		|	DocumentData.BusinessUnitManagementAccounting AS DepartmentACC,
		|	DocumentData.LineOfBusinessManagementAccounting AS LineOfBusinessBookkeeping,
		|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.DateOfRecognition AS Period,
		|	DocumentData.Period          AS CorrectionDate,
		|	DocumentData.Organization     AS Organization,
		|	FATable.FixedAsset      AS FixedAsset,
		|
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|
		|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualAccounting,
		|	DocumentData.MethodForReflectingMaExpenses AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemManagementAccounting AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionManagementAccounting AS ExpensesDimensionAccounting,
		|	DocumentData.BusinessUnitManagementAccounting AS DepartmentACC,
		|	DocumentData.LineOfBusinessManagementAccounting AS LineOfBusinessBookkeeping,
		|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.AdjustmentModeFromPreviousDate
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableFixedAssetsAccountingProcedureManagementAccounting();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Period                      AS Period,
		|	DATETIME(1,1,1)                            AS CorrectionDate,
		|	DocumentData.Organization                 AS Organization,
		|	FATable.FixedAsset                  AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
		|	DocumentData.DepreciationAccrualManagementAccounting      AS AccrueDepreciationOrAmortization,
		|	DocumentData.MethodForReflectingMaExpenses   AS ExpensesPostingMethod,
		|	DocumentData.ExpenseItemManagementAccounting            AS ExpenseItem,
		|	DocumentData.ExpensesDimensionManagementAccounting         AS DimensionOfExpenses,
		|	DocumentData.BusinessUnitManagementAccounting             AS Department,
		|	DocumentData.LineOfBusinessManagementAccounting   AS LineOfBusiness,
		|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInManAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.DateOfRecognition          AS Period,
		|	DocumentData.Period                      AS CorrectionDate,
		|	DocumentData.Organization                 AS Organization,
		|	FATable.FixedAsset                  AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
		|	DocumentData.DepreciationAccrualManagementAccounting      AS AccrueDepreciationOrAmortization,
		|	DocumentData.MethodForReflectingMaExpenses   AS ExpensesPostingMethod,
		|	DocumentData.ExpenseItemManagementAccounting            AS ExpenseItem,
		|	DocumentData.ExpensesDimensionManagementAccounting         AS DimensionOfExpenses,
		|	DocumentData.BusinessUnitManagementAccounting             AS Department,
		|	DocumentData.LineOfBusinessManagementAccounting   AS LineOfBusiness,
		|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses       AS CompanyRecipientOfExpenses
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInManAccounting
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts);
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		QueryText =
		"SELECT
		|	DocumentData.Ref       AS Recorder,
		|	DocumentData.Period       AS Period,
		|	DATETIME(1,1,1)             AS CorrectionDate,
		|	DocumentData.Organization  AS Organization,
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.DateOfRecognition
		|		ELSE WDepreciationParametersOfOSBU.LastChangeDate
		|	END AS LastChangeDate,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.UsefulLifeAccounting
		|		ELSE WDepreciationParametersOfOSBU.UsefulLifeMonthsAC
		|	END AS UsefulLifeMonthsAC,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.AccelerationFactorAccounting
		|		ELSE WDepreciationParametersOfOSBU.AccelerationFactor
		|	END AS AccelerationFactor,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|			THEN FATable.EstimatedRunningTime
		|		ELSE WDepreciationParametersOfOSBU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.UsefulLifeAccounting
		|		ELSE WDepreciationParametersOfOSBU.UsefulLifeForCalculatingDepreciationMonth
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting)
		|		ELSE WDepreciationParametersOfOSBU.CostUsedToCalculateDepreciationManag
		|	END AS CostUsedToCalculateDepreciationManag,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN FATable.ResidualValueLocal
		|		ELSE WDepreciationParametersOfOSBU.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU AS WDepreciationParametersOfOSBU
		|		ON WDepreciationParametersOfOSBU.Ref = FATable.Ref
		|			AND WDepreciationParametersOfOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref       AS Recorder,
		|	DocumentData.DateOfRecognition AS Period,
		|	DocumentData.Period       AS CorrectionDate,
		|	DocumentData.Organization  AS Organization,
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.DateOfRecognition
		|		ELSE WDepreciationParametersOfOSBU.LastChangeDate
		|	END AS LastChangeDate,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.UsefulLifeAccounting
		|		ELSE WDepreciationParametersOfOSBU.UsefulLifeMonthsAC
		|	END AS UsefulLifeMonthsAC,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.AccelerationFactorAccounting
		|		ELSE WDepreciationParametersOfOSBU.AccelerationFactor
		|	END AS AccelerationFactor,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|			THEN FATable.EstimatedRunningTime
		|		ELSE WDepreciationParametersOfOSBU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN DocumentData.UsefulLifeAccounting
		|		ELSE WDepreciationParametersOfOSBU.UsefulLifeForCalculatingDepreciationMonth
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting)
		|		ELSE WDepreciationParametersOfOSBU.CostUsedToCalculateDepreciationManag
		|	END AS CostUsedToCalculateDepreciationManag,
		|
		|	CASE
		|		WHEN DocumentData.PostInAccounting
		|			THEN FATable.ResidualValueLocal
		|		ELSE WDepreciationParametersOfOSBU.ResidualValueMan
		|	END AS ResidualValueMan
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN WDepreciationParametersOfOSBU AS WDepreciationParametersOfOSBU
		|		ON WDepreciationParametersOfOSBU.Ref = FATable.Ref
		|			AND WDepreciationParametersOfOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND DocumentData.AdjustmentModeFromPreviousDate
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref       AS Recorder,
		|	DocumentData.Period       AS Period,
		|	DATETIME(1,1,1)             AS CorrectionDate,
		|	DocumentData.Organization  AS Organization,
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	DocumentData.Period AS LastChangeDate,
		|
		|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeMonthsAC,
		|
		|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactor,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|			THEN FATable.EstimatedRunningTime
		|		ELSE 0
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationManag,
		|
		|	FATable.ResidualValueLocal AS ResidualValueMan
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref       AS Recorder,
		|	DocumentData.DateOfRecognition AS Period,
		|	DocumentData.Period       AS CorrectionDate,
		|	DocumentData.Organization  AS Organization,
		|	FATable.FixedAsset   AS FixedAsset,
		|
		|	DocumentData.Period AS LastChangeDate,
		|
		|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeMonthsAC,
		|
		|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactor,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|			THEN FATable.EstimatedRunningTime
		|		ELSE 0
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationManag,
		|
		|	FATable.ResidualValueLocal AS ResidualValueMan
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.AdjustmentModeFromPreviousDate
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText =
	"SELECT
	|	DocumentData.Ref              AS Recorder,
	|	DocumentData.Period              AS Period,
	|	DATETIME(1,1,1)                    AS CorrectionDate,
	|	DocumentData.DateOfRecognition  AS LastChangeDate,
	|	DocumentData.Organization         AS Organization,
	|	FATable.FixedAsset          AS FixedAsset,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeMonths,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeForCalculatingDepreciationMonth,
	|	FATable.EstimatedRunningTime            AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactor,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethod,
	|
	|	FATable.ResidualValueMan       AS ResidualValueMan,
	|	FATable.ResidualValueLocal   AS ResidualValueLocal,
	|
	|	ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting) AS CostUsedToCalculateDepreciationManag,
	|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
	|		ON CostCalculation.Ref = FATable.Ref
	|			AND CostCalculation.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref              AS Recorder,
	|	DocumentData.DateOfRecognition  AS Period,
	|	DocumentData.Period              AS CorrectionDate,
	|	DocumentData.DateOfRecognition  AS LastChangeDate,
	|	DocumentData.Organization         AS Organization,
	|	FATable.FixedAsset          AS FixedAsset,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeMonths,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeForCalculatingDepreciationMonth,
	|	FATable.EstimatedRunningTime            AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactor,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethod,
	|
	|	FATable.ResidualValueMan       AS ResidualValueMan,
	|	FATable.ResidualValueLocal   AS ResidualValueLocal,
	|
	|	ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting) AS CostUsedToCalculateDepreciationManag,
	|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
	|		ON CostCalculation.Ref = FATable.Ref
	|			AND CostCalculation.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|	AND DocumentData.AdjustmentModeFromPreviousDate
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|	FATable.FixedAsset AS FixedAsset,
		|	DocumentData.Organization AS Organization,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.DateOfRecognition 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateAC
		|	END AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.DateOfRecognition 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateMA
		|	END AS CommissioningDateMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentAC
		|	END AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentMA
		|	END AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN DocumentData.DepreciationMethodAccounting 
		|		ELSE InitialFixedAssetsInformation.DepreciationMethodAccounting
		|	END AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN DocumentData.AccountingProcedureAC 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureAC
		|	END AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.AccountingProcedureMA 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureMA
		|	END AS AccountingProcedureMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting)
		|		ELSE InitialFixedAssetsInformation.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting)
		|		ELSE InitialFixedAssetsInformation.InitialCostMA
		|	END AS InitialCostMA
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	(DocumentData.RecordInLocalAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|		OR DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses))
		|
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.DateOfRecognition AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|	FATable.FixedAsset AS FixedAsset,
		|	DocumentData.Organization AS Organization,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.DateOfRecognition 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateAC
		|	END AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.DateOfRecognition 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateMA
		|	END AS CommissioningDateMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentAC
		|	END AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentMA
		|	END AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN DocumentData.DepreciationMethodAccounting 
		|		ELSE InitialFixedAssetsInformation.DepreciationMethodAccounting
		|	END AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|			THEN DocumentData.AccountingProcedureAC 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureAC
		|	END AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.AccountingProcedureMA 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureMA
		|	END AS AccountingProcedureMA,
		|
		|	CASE 
		|		WHEN DocumentData.PostInAccounting 
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting)
		|		ELSE InitialFixedAssetsInformation.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting)
		|		ELSE InitialFixedAssetsInformation.InitialCostMA
		|	END AS InitialCostMA
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.AdjustmentModeFromPreviousDate
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|	FATable.FixedAsset AS FixedAsset,
		|	DocumentData.Organization AS Organization,
		|
		|	DocumentData.DateOfRecognition AS CommissioningDateAC,
		|	DocumentData.DateOfRecognition AS CommissioningDateMA,
		|
		|	DocumentData.Ref AS CommissioningDocumentAC,
		|	DocumentData.Ref AS CommissioningDocumentMA,
		|
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	CASE DocumentData.AccountingProcedureMA
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.CostIsNotRedeemable)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|	END AS AccountingProcedureAC,
		|
		|	DocumentData.AccountingProcedureMA AS AccountingProcedureMA,
		|
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS InitialCostLocalAccounting,
		|	ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting) AS InitialCostMA
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.DateOfRecognition AS Period,
		|	DocumentData.Period AS CorrectionDate,
		|	FATable.FixedAsset AS FixedAsset,
		|	DocumentData.Organization AS Organization,
		|
		|	DocumentData.DateOfRecognition AS CommissioningDateAC,
		|	DocumentData.DateOfRecognition AS CommissioningDateMA,
		|
		|	DocumentData.Ref AS CommissioningDocumentAC,
		|	DocumentData.Ref AS CommissioningDocumentMA,
		|
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	CASE DocumentData.AccountingProcedureMA
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.CostIsNotRedeemable)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|	END AS AccountingProcedureAC,
		|
		|	DocumentData.AccountingProcedureMA AS AccountingProcedureMA,
		|
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS InitialCostLocalAccounting,
		|	ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting) AS InitialCostMA
		|
		|FROM
		|	DocumentDataFATable AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.AdjustmentModeFromPreviousDate
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableLeasedAsset(QueryTexts, Registers)

	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTLeasedFA(QueryTexts);

	QueryText =
	"SELECT
	|	DocumentData.Ref        AS Recorder,
	|	DocumentData.Period        AS Period,
	|	DocumentData.Organization   AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	TTLeasedFA.Cost    AS Cost,
	|	TTLeasedFA.ParValue AS ParValue,
	|	TTLeasedFA.Partner      AS Partner,
	|	TTLeasedFA.Counterparty   AS Counterparty,
	|	TTLeasedFA.Contract      AS Contract,
	|	VALUE(Enum.FixedAssetsStates.InLease) AS State
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.Ref = FATable.Ref
	|			AND TTLeasedFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RecognitionOfLeaseItems)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
		
EndProcedure

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableFACost(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Ref                       AS Recorder,
		|	DocumentData.Period                       AS Period,
		|	DocumentData.Organization                  AS Organization,
		|	DocumentData.FixedAssetsLocation              AS Department,
		|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	DocumentData.LineOfBusiness      AS LineOfBusiness,
		|
		|	CASE 
		|		WHEN DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|				OR DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.BusinessTransactions.DepreciatedFixedAssetsRecognition)
		|		ELSE DocumentData.BusinessOperation 
		|	END                                        AS BusinessOperation,
		|
		|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
		|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
		|	FATable.FixedAsset                   AS FixedAsset,
		|
		|	CASE 
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject) 
		|			THEN DocumentData.ConstructionObject 
		|		ELSE FATable.FixedAsset 
		|	END                                        AS ExpensesCapitalizationDimension,
		|
		|	ISNULL(TTCostCalculation.Department, UNDEFINED)                AS DebitBusinessUnit,
		|	ISNULL(TTCostCalculation.LineOfBusiness, UNDEFINED)      AS CorLineOfBusiness,
		|	ISNULL(TTCostCalculation.ExpenseItem, UNDEFINED)               AS CorExpenseItem,
		|	ISNULL(TTCostCalculation.DimensionOfExpenses, UNDEFINED)            AS CorExpenditureDimension,
		|	NOT TTCostCalculation.AccountingObject IS NULL                             AS CostCalculation,
		|
		|	CASE
		|		WHEN NOT DocumentData.RecordInManAccounting
		|			THEN 0
		|		ELSE ISNULL(TTCostCalculation.AmountOfUU, FATable.CostInManagementAccounting)
		|	END AS Cost,
		|
		|	CASE
		|		WHEN NOT DocumentData.PostInAccounting
		|			THEN 0
		|		ELSE ISNULL(TTCostCalculation.AmountAccounting, FATable.CostInAccounting)
		|	END AS LocalCost,
		|
		|	0 AS PreliminaryCostMan,
		|	0 AS PreliminaryCostLocal,
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
		|		ON TTCostCalculation.Ref = DocumentData.Ref
		|			AND TTCostCalculation.AccountingObject = FATable.FixedAsset
		|
		|UNION ALL
		|
		// You need to write down the preliminary cost separately to calculate depreciation
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Ref                       AS Recorder,
		|	DocumentData.Period                       AS Period,
		|	DocumentData.Organization                  AS Organization,
		|	DocumentData.FixedAssetsLocation              AS Department,
		|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	DocumentData.LineOfBusiness      AS LineOfBusiness,
		|
		|	CASE 
		|		WHEN DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|				OR DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.BusinessTransactions.DepreciatedFixedAssetsRecognition)
		|		ELSE DocumentData.BusinessOperation 
		|	END                                        AS BusinessOperation,
		|
		|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
		|	DocumentData.DimensionKindExpenseCapitalization AS DimensionKindExpenseCapitalization,
		|	FATable.FixedAsset                   AS FixedAsset,
		|
		|	CASE 
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject) 
		|			THEN DocumentData.ConstructionObject 
		|		ELSE FATable.FixedAsset 
		|	END                                        AS ExpensesCapitalizationDimension,
		|
		|	UNDEFINED                                 AS DebitBusinessUnit,
		|	UNDEFINED                                 AS CorLineOfBusiness,
		|	UNDEFINED                                 AS CorExpenseItem,
		|	UNDEFINED                                 AS CorExpenditureDimension,
		|	FALSE                                         AS CostCalculation,
		|
		|	0                                            AS Cost,
		|	0                                            AS LocalCost,
		|
		|	FATable.CostInManagementAccounting                        AS PreliminaryCostMan,
		|	FATable.CostInAccounting                        AS PreliminaryCostLocal,
		|
		|	&IDOfUnusedFinRecord        AS FinRecordID,
		|	UNDEFINED                                 AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|WHERE
		|	(FATable.CostInAccounting <> 0 OR FATable.CostInManagementAccounting <> 0)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryTextTableTTAccruedDepreciation(Query, QueryTexts);
	
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
		|	AccruedDepreciation.Ref                   AS Recorder,
		|	VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationCharge) AS BusinessOperation,
		|	AccruedDepreciation.CalculationPeriod            AS Period,
		|	AccruedDepreciation.Organization              AS Organization,
		|	AccruedDepreciation.Department            AS Department,
		|	AccruedDepreciation.FixedAsset         AS FixedAsset,
		|	AccruedDepreciation.LineOfBusiness  AS LineOfBusiness,
		|	AccruedDepreciation.FinancialAccountingGroup   AS FinancialAccountingGroup,
		|
		|	AccruedDepreciation.AmountOfUU    AS Depreciation,
		|	AccruedDepreciation.AmountAccounting    AS DepreciationLocal,
		|
		|	AccruedDepreciation.DebitBusinessUnit              AS DebitBusinessUnit,
		|	AccruedDepreciation.CorLineOfBusiness    AS CorLineOfBusiness,
		|	AccruedDepreciation.ExpenseItem                AS CorExpenseItem,
		|	AccruedDepreciation.DimensionOfExpenses             AS CorExpenditureDimension,
		|	
		|	AccruedDepreciation.RowID           AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationCharge) AS BusinessTransactionSetting
		|	
		|FROM
		|	AccruedDepreciation AS AccruedDepreciation
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
		|	DocumentData.Ref                          AS Recorder,
		|	VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationCharge) AS BusinessOperation,
		|	DocumentData.Period                          AS Period,
		|	DocumentData.Organization                     AS Organization,
		|	DocumentData.FixedAssetsLocation                 AS Department,
		|	FATable.FixedAsset                      AS FixedAsset,
		|	DocumentData.LineOfBusiness         AS LineOfBusiness,
		|	DocumentData.FinancialAccountingGroup          AS FinancialAccountingGroup,
		|
		|	CASE 
		|		WHEN DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN FATable.CostInManagementAccounting
		|		ELSE 0
		|	END                             AS Depreciation,
		|	CASE 
		|		WHEN DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|			THEN FATable.CostInAccounting
		|		ELSE 0
		|	END                             AS DepreciationLocal,
		|
		|	UNDEFINED                      AS DebitBusinessUnit,
		|	UNDEFINED                      AS CorLineOfBusiness,
		|	UNDEFINED                      AS CorExpenseItem,
		|	UNDEFINED                      AS CorExpenditureDimension,
		|	
		|	FATable.RowID     AS FinRecordID,
		|	DocumentData.BusinessTransactionSetting   AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|WHERE
		|	(DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|		OR DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued))
		|";
		
	EndIf; 
	
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
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	NonCurrentAssetsInternal.TextOfTrafficRequestIncomeExpensesOtherAssetsLiabilitiesAcceptanceForAccounting(ListOfMergeRequests);	

	FixedAssetsInitialRecognitionLocalization.AddRequestTextTrafficTableIncomeExpensesOtherAssetsLiabilities(ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableCGUComposition(Query, QueryTexts, Registers)

	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS NonCurrentAsset,
	|	DocumentData.CGU AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
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
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText = FixedAssetsInitialRecognitionLocalization.QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields);
	
	If QueryText = Undefined Then
		
		ListOfMergeRequests = New Array;
		ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
		ListOfMergeRequests.Add(NonCurrentAssetsInternal.RequestTextTableReflectionOfAccruedDepreciationInOtherExpenses(Add_Fields));
		
		NonCurrentAssetsInternal.TextOfRequestOtherexpensesOfAcceptanceForAccounting(ListOfMergeRequests);
		NonCurrentAssetsInternal.QueryTextOfOtherExpensesShouldNotBeTakenIntoAccountAndIncludedInExpenses(ListOfMergeRequests, True, True);
		
		QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTAccruedDepreciation(Query, QueryTexts)

	TableName = "AccruedDepreciation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	SubqueryText =
	// Depreciation at a preliminary cost
	"SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.Period                          AS CalculationPeriod,
	|	DocumentData.Period                          AS AccrualPeriod,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.FixedAssetsLocation                 AS Department,
	|	DocumentData.FixedAssetsLocation                 AS DebitBusinessUnit,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	DocumentData.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.LineOfBusiness         AS CorLineOfBusiness,
	|	DocumentData.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	DocumentData.ExpenseItemManagementAccounting                AS ExpenseItem,
	|	DocumentData.ExpensesDimensionManagementAccounting             AS DimensionOfExpenses,
	|	UNDEFINED                                    AS CGU,
	|	FATable.CostInManagementAccounting                           AS AmountOfUU,
	|	FATable.CostInAccounting                           AS AmountAccounting,
	|	0                                               AS ImpairmentMA,
	|	0                                               AS ImpairmentAC,
	|	0                                               AS ImpairmentOfCF,
	|	0                                               AS PackageNumber,
	|	0                                               AS ACProduction,
	|	0                                               AS LifeSpentPastPeriod,
	|	0                                               AS LifeSpentCurrentPeriod,
	|	0                                               AS LifeSpentPastPeriodAccounting,
	|	0                                               AS LifeSpentCurrentPeriodAccounting,
	|	0                                               AS CostUsedToCalculateDepreciationManag,
	|	0                                               AS CostUsedToCalculateDepreciationLocal,
	|	0                                               AS ImpairmentBalanceLocal,
	|	0                                               AS ImpairmentBalanceMan,
	|	UNDEFINED                                    AS AccountingProcedureMA,
	|	UNDEFINED                                    AS AccountingProcedureAC,
	|	UNDEFINED                                    AS ProcedureForCalculatingDepreciationOfMa,
	|	UNDEFINED                                    AS ProcedureForCalculatingDepreciationAC,
	|	UNDEFINED                                    AS PostingOptionForImpairedFADepreciation,
	|	0                                               AS DepreciationMethodVersionMA,
	|	0                                               AS DepreciationMethodVersionLA,
	|	FALSE                                            AS ThisIsAnAdditionalAccrual,
	|	FALSE                                            AS ThisIsAdditionalChargeAccounting,
	|	FALSE                                            AS ThisIsRecordingOfDifference,
	|	FALSE                                            AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
	|	FATable.RowID                   AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|
	// Additional depreciation
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.Period                          AS CalculationPeriod,
	|	DocumentData.Period                          AS AccrualPeriod,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.FixedAssetsLocation                 AS Department,
	|	DocumentData.FixedAssetsLocation                 AS DebitBusinessUnit,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	DocumentData.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.LineOfBusiness         AS CorLineOfBusiness,
	|	DocumentData.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	CASE 
	|		WHEN DocumentData.CostAllocationOptionManag IN (&ListOfPermittedCostAllocationOptions)
	|			THEN DocumentData.ExpenseItemManagementAccounting
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.AdditionalAccrualOfPropertyTaxesAndDepreciation)
	|	END                                           AS ExpenseItem,
	|	CASE 
	|		WHEN DocumentData.CostAllocationOptionManag IN (&ListOfPermittedCostAllocationOptions)
	|			THEN DocumentData.ExpensesDimensionManagementAccounting
	|		ELSE UNDEFINED
	|	END                                           AS DimensionOfExpenses,
	|
	|	UNDEFINED                                    AS CGU,
	|
	|	CostCalculation.AmountOfUU
	|	 - FATable.CostInManagementAccounting AS AmountOfUU,
	|
	|	CostCalculation.AmountAccounting
	|	 - FATable.CostInAccounting AS AmountAccounting,
	|
	|	0                                               AS ImpairmentMA,
	|	0                                               AS ImpairmentAC,
	|	0                                               AS ImpairmentOfCF,
	|
	|	0                                               AS PackageNumber,
	|	0                                               AS ACProduction,
	|	0                                               AS LifeSpentPastPeriod,
	|	0                                               AS LifeSpentCurrentPeriod,
	|	0                                               AS LifeSpentPastPeriodAccounting,
	|	0                                               AS LifeSpentCurrentPeriodAccounting,
	|	0                                               AS CostUsedToCalculateDepreciationManag,
	|	0                                               AS CostUsedToCalculateDepreciationLocal,
	|	0                                               AS ImpairmentBalanceLocal,
	|	0                                               AS ImpairmentBalanceMan,
	|	UNDEFINED                                    AS AccountingProcedureMA,
	|	UNDEFINED                                    AS AccountingProcedureAC,
	|	UNDEFINED                                    AS ProcedureForCalculatingDepreciationOfMa,
	|	UNDEFINED                                    AS ProcedureForCalculatingDepreciationAC,
	|	UNDEFINED                                    AS PostingOptionForImpairedFADepreciation,
	|	0                                               AS DepreciationMethodVersionMA,
	|	0                                               AS DepreciationMethodVersionLA,
	|	FALSE                                            AS ThisIsAnAdditionalAccrual,
	|	FALSE                                            AS ThisIsAdditionalChargeAccounting,
	|	FALSE                                            AS ThisIsRecordingOfDifference,
	|	FALSE                                            AS ThisIsAdjustmentOfDepreciationForPreviousPeriod,
	|	FATable.RowID                   AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		INNER JOIN TTCostCalculationGrouped AS CostCalculation
	|		ON CostCalculation.Ref = FATable.Ref
	|			AND CostCalculation.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|	AND CostCalculation.AmountOfUU > FATable.CostInManagementAccounting
	|";
	
	Documents.FixedAssetsDepreciationCharge2_4.RequestTextTTAccruedDepreciation(QueryTexts, SubqueryText, True);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return FixedAssetsInitialRecognitionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return FixedAssetsInitialRecognitionLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	FixedAssetsInitialRecognitionLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

Function GetDataForPrintedFormOS1(PrintParameters, ObjectsArray) Export

	Return FixedAssetsInitialRecognitionLocalization.GetDataForPrintedFormOS1(PrintParameters, ObjectsArray);

EndFunction

Function LabelPrintingData(DocumentsArray) Export

	QueryText =
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.LineNumber AS LineNumber
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4.FA AS FATable
	|WHERE
	|	FATable.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	FATable.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.Execute();
	
	ObjectsArray = QueryResult.Unload().UnloadColumn("FixedAsset");
	
	Return ObjectsArray;
	
EndFunction

#EndRegion

#Region FillType

// Fill in based on the conclusion of the lease Contract.
// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - Object
//  Basis - DocumentRef.SigningOfLeaseContract - Basis
// 
// Returns:
//  Undefined, String - error text
Function FillInBasedOnConclusionOfLeaseAgreement(Object, Basis) Export
	
	If Not ValueIsFilled(Basis) Then
		Object.DocumentBasis = Undefined;
		Object.GeneratedDocument = False;
		Return Undefined;
	EndIf;

	Object.BusinessOperation = Enums.BusinessTransactions.RecognitionOfLeaseItems;
	Object.DocumentBasis = Basis;
	Object.GeneratedDocument = True;
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS FixedAssetsLocation,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.AssetHolder AS AssetHolder,
	|	DocumentData.Contract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting AS PostInAccounting,
	|	FALSE AS RecordInTA,
	|	DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.Contract.RecognizeLeasedAssetsInManagementAccounting AS RecordInManAccounting,
	|	DocumentData.Contract.VATTaxation AS VATTaxation,
	|	VALUE(Enum.SeparateVATAccountingOptions.FromDocument) AS SeparateVATAccountingOption
	|
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.FixedAsset AS FixedAsset
	|FROM
	|	Document.SigningOfLeaseContract.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Basis
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
		
		ErrorText = NStr("vi = 'Không xem xét tiếp nhận vào kế toán tài sản cố định được tính trên bảng cân đối kế toán của bên cho thuê';
						|ru = 'Принятие к учету основных средств, учитываемых на балансе арендодателя, не предусмотрено';
						|en = 'Initial recognition of fixed assets recorded on the lessor''s balance sheet is not provided'; fa = 'Initial recognition of fixed assets recorded on the lessor''s balance sheet is not provided';
						|it = 'Non è prevista la registrazione in contabilità delle immobilizzazioni includibili nel bilancio del locatore';
						|pl = 'Przyjęcie do ewidencji środków trwałych, uwzględnianych w bilansie leasingodawcy, nie jest przewidziena';
						|tr = 'Kiraya verenin bilançosunda muhasebeleştirilen sabit kıymetler - ilk tahakkuk işlemi sağlanmamıştır'");
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
	
	FillInCost(Object);
	
	FixedAssetsInitialRecognitionLocalization.FillInBasedOnConclusionOfLeaseAgreement(Object, Basis);
	
	Return Undefined;
	
EndFunction

// Fill in based on changes in the terms of the lease Contract.
// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - Object
//  Basis - DocumentRef.LeaseTermAdjustment - Basis
// 
// Returns:
//  Undefined, String - error text
Function FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Basis) Export
	
	If Not ValueIsFilled(Basis) Then
		Object.DocumentBasis = Undefined;
		Object.GeneratedDocument = False;
		Return Undefined;
	EndIf;

	Object.BusinessOperation = Enums.BusinessTransactions.RecognitionOfLeaseItems;
	Object.DocumentBasis = Basis;
	Object.GeneratedDocument = True;
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Contract.Department AS FixedAssetsLocation,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Date AS ReferenceDocumentDateForCertificate,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract
	|	ELSE DocumentData.NewContract END AS Contract,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.AssetHolder
	|	ELSE DocumentData.NewContract.AssetHolder END AS AssetHolder,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.LineOfBusiness
	|	ELSE DocumentData.NewContract.LineOfBusiness END AS LineOfBusiness,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting
	|	ELSE DocumentData.NewContract.RecognizeLeasedItemsInLocalAccounting END AS PostInAccounting,
	|	FALSE AS RecordInTA,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting
	|	ELSE DocumentData.NewContract.RecognizeLeasedItemsInLocalAccounting END AS RecordInLocalAccounting,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.RecognizeLeasedAssetsInManagementAccounting
	|	ELSE DocumentData.NewContract.RecognizeLeasedAssetsInManagementAccounting END AS RecordInManAccounting,
	|	CASE WHEN DocumentData.NewContract = VALUE(Catalog.LeaseContract.EmptyRef) THEN
	|		DocumentData.Contract.VATTaxation
	|	ELSE DocumentData.NewContract.VATTaxation END AS VATTaxation,
	|	VALUE(Enum.SeparateVATAccountingOptions.FromDocument) AS SeparateVATAccountingOption
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
	|	AND FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.Rent)
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
		And Not LeasedAssetAccountingLocalization.LeaseAccountingAccordingToFSB25_2018IsUsed(Selection.Organization, Object.Date) Then
		
		ErrorText = NStr("vi = 'Không xem xét tiếp nhận vào kế toán tài sản cố định được tính trên bảng cân đối kế toán của bên cho thuê';
						|ru = 'Принятие к учету основных средств, учитываемых на балансе арендодателя, не предусмотрено';
						|en = 'Initial recognition of fixed assets recorded on the lessor''s balance sheet is not provided'; fa = 'Initial recognition of fixed assets recorded on the lessor''s balance sheet is not provided';
						|it = 'Non è prevista la registrazione in contabilità delle immobilizzazioni includibili nel bilancio del locatore';
						|pl = 'Przyjęcie do ewidencji środków trwałych, uwzględnianych w bilansie leasingodawcy, nie jest przewidziena';
						|tr = 'Kiraya verenin bilançosunda muhasebeleştirilen sabit kıymetler - ilk tahakkuk işlemi sağlanmamıştır'");
		Return ErrorText;
		
	EndIf; 
	
	If Package[1].IsEmpty() Then
		ErrorText = NStr("vi = 'Trong chứng từ không có tài sản cố định hữu hình mà cần tiếp nhận vào kế toán';
						|ru = 'В документе нет основных средств, которые необходимо принять к учету';
						|en = 'The document does not contain any fixed assets for recognition'; fa = 'The document does not contain any fixed assets for recognition';
						|it = 'В документе нет основных средств, которые необходимо принять к учету';
						|pl = 'The document does not contain any fixed assets for recognition';
						|tr = 'Belgede muhasebeleştirilecek sabit kıymet bulunmamaktadır'");
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
	
	FillInCost(Object);
	
	FixedAssetsInitialRecognitionLocalization.FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Basis);
	
	Return Undefined;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array - 
// 
// Returns:
//  Boolean - 
Function FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return True;
	EndIf;
	
	DataToFill = Documents.FixedAssetsPhysicalCount.FillingDataBasedOnInventory24(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.Recognition, 
							ArrayOfLineNumbers);
							
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu tạo ghi nhận vào kế toán';
							|ru = 'В документе %1 отсутствуют строки требующие создания принятия к учету';
							|en = 'There are no lines which require recognition in the %1 document'; fa = 'There are no lines which require recognition in the %1 document';
							|it = 'There are no lines which require recognition in the %1 document';
							|pl = 'There are no lines which require recognition in the %1 document';
							|tr = '%1 belgesinde muhasebeleştirme oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return False;
		
	EndIf;
	
	Selection = DataToFill.Attributes[0];
	FillPropertyValues(Object, Selection);
	
	
	PostInAccounting = False;
	RecordInTA = False;
	RecordInManAccounting = False;

	For Each Selection In DataToFill.TabularSection Do
		
		If Not ValueIsFilled(Object.OSGroup) Then
			Object.OSGroup = Selection.OSGroup;
		EndIf;
		
		If Object.OSGroup <> Selection.OSGroup Then
			Continue;
		EndIf;
		
		NewRow = Object.FA.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Object.PostInAccounting Then
			NewRow.CostInAccounting = Selection.ActualCostAC;
		EndIf; 
		
		If Object.PostInAccounting Then
			NewRow.CostInTaxAccounting = Selection.ActualCostTA;
		EndIf; 

		If Object.RecordInManAccounting Then
			NewRow.CostInManagementAccounting = Selection.CostActualMan;
		EndIf; 

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

	Return True;
	
EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	FixedAssetsInitialRecognitionLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArticleSelectionAndAnalyticsOptions);
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseRecordMethodAC", Parameters);
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseRecordMethodTA", Parameters);
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "MethodForReflectingMaExpenses", Parameters);
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
	Handler.Procedure = "Documents.FixedAssetsInitialRecognition2_4.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.88";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("91a1bcf2-75a9-4983-9424-0a46fc3c1ce9");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.FixedAssetsInitialRecognition2_4.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Tiếp nhận vào kế toán TSCĐ"":
								  |- Điền mục tin ""Phương án tính bổ sung khấu hao""
								  |- Điền mục tin ""Khấu trừ thuế đầu tư""
								  |- Xóa mục tin ""Phản ánh trong KTTh"" trong ERP WE';
								  |ru = 'Обновляет документы ""Принятие к учету ОС"":
								  |- Заполняет реквизит ""Вариант доначисления амортизации""
								  |- Заполняет реквизит ""Инвестиционный налоговый вычет""
								  |- Очищает реквизит ""Отражать в НУ"" в ERP WE';
								  |en = 'Updates the ""Fixed assets — Initial recognition"" documents:
								  |- Fills in the ""Additional depreciation accrual option"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.
								  |- Clears the ""Record in TA"" attribute in ERP WE.'; fa = 'Updates the ""Fixed assets — Initial recognition"" documents:
								  |- Fills in the ""Additional depreciation accrual option"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.
								  |- Clears the ""Record in TA"" attribute in ERP WE.';
								  |it = 'Updates the ""Fixed assets — Initial recognition"" documents:
								  |- Fills in the ""Additional depreciation accrual option"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.
								  |- Clears the ""Record in TA"" attribute in ERP WE.';
								  |pl = 'Updates the ""Fixed assets — Initial recognition"" documents:
								  |- Fills in the ""Additional depreciation accrual option"" attribute.
								  |- Fills in the ""Investment tax deduction"" attribute.
								  |- Clears the ""Record in TA"" attribute in ERP WE.';
								  |tr = '""Sabit Kıymetlerin Muhasebeleştirilmesi"" belgelerini günceller:
								  |- ""Amortisman ek tahakkuk seçeneği"" özniteliğini doldurur
								  |- ""Yatırım vergi indirimi"" alanını doldurur 
								  |- ERP WE''de ""VM''de Yansıt"" alanını temizler'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.FixedAssetsInitialRecognition2_4";
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
	|		Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|	WHERE
	|		DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.EmptyRef)
	|			OR DocumentData.DepreciationAdjustmentOption = VALUE(Enum.AdditionalDepreciationAccrualOptions.EmptyRef)
	|				AND DocumentData.AdjustmentModeFromPreviousDate
	|			OR DocumentData.RecordInTA
	|				AND NOT &ComplianceCAAccountingIsKept
	|
	|	) AS DocumentsList
	|";
	Query = New Query(QueryText);
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.FixedAssetsInitialRecognition2_4.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.FixedAssetsInitialRecognition2_4";
	
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
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.FixedAssetsInitialRecognition2_4
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.CostGenerationProcedure) Then
				DocumentObject.CostGenerationProcedure = Enums.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeDocumentCreationDateInCost;
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.DepreciationAdjustmentOption)
				And DocumentObject.AdjustmentModeFromPreviousDate Then
				
				DocumentObject.DepreciationAdjustmentOption =
					?(DocumentObject.DeleteAccrueAdditionalDepreciationForPreviousPeriod, 
						Enums.AdditionalDepreciationAccrualOptions.Automatically,
						Enums.AdditionalDepreciationAccrualOptions.Manually);
					
			EndIf;
			If DocumentObject.RecordInTA 
				And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
				DocumentObject.RecordInTA = False;
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
