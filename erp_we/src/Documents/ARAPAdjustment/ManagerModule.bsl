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
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("LossAllowance");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ARAPAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ARAPAdjustment") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers);
		QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableLossAllowance(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		ARAPAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ARAPAdjustmentLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a "debt Write-off" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ARAPAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ARAPAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ARAPAdjustment);
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
	
	ARAPAdjustmentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ARAPAdjustmentLocalization.AddPrintCommands(PrintCommands);

EndProcedure
// The function generates the request text to reflect the document in regl. accounting.
//
// Returns:
// 		String - query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return ARAPAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// 		String - query text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ARAPAdjustmentLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpAccountToReflectDebitingExpenses
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.IncomeExpensesAssetsLiabilities";
	
	SetupParameters.ArticleType = "ArticleType";
	SetupParameters.AssetAndLiabilityItem = "AssetRef";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfTheCostReflectionInTheReglAccounting");
	SetupParameters.FormItems.Add("ExpensesAssetsLiabilitiesPresentationOfRecordingInComplAccounting");
	SetupParameters.FormItems.Add("PresentationOfTheIncomeReflectionInTheReglAccounting");
	SetupParameters.FormItems.Add("IncomeAssetsLiabilitiesPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction
// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	CorrespondenceWithIncome - Boolean - A sign of correspondence with income. 	
// 
// Returns:
// 	Array of Structure - Array of accounting account settings See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, CorrespondenceWithIncome) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region AssetRef
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.IncomeExpensesAssetsLiabilities";
	ChoiceParameters.AssetRef = "AssetRef";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	If CorrespondenceWithIncome Then
		ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	EndIf;
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesAssetsLiabilitiesAssetRef");
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("IncomeAssetsLiabilitiesAssetRef");
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = CorrespondenceWithIncome;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("IncomeAssetsLiabilitiesIncomeAnalytics");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = Not CorrespondenceWithIncome;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesAssetsLiabilitiesExpenseAnalytics");
	#EndRegion
	
	WriteOffAtExpenseOfReserve = (BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance);
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = Not WriteOffAtExpenseOfReserve;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("IncomeAssetLiabilityAnalysis");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAssetsLiabilitiesAnalyticsOfAssetsLiabilities");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("IncomeAssetsLiabilitiesAnalyticsOfAssetsLiabilities");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
		
	Return ArrayOfSelectionParameters;
	
EndFunction

// The function finds debt adjustments of a given basis.
//
// Parameters:
//	Basis - DocumentRef, CatalogRef - A Document or Catalog for which you need to find a debt adjustment
//	FilterParameters - Structure - Selection of debt adjustments by Attributes. The Structure Key is the Attribute Name.
//	AttributesOfDebtAdjustment - Structure - Returnable. Adjustment data (Link, Number, Date, Organization, Currency, etc.).
//	Posted - Boolean - If the attribute is set to True, then only the completed ones will be searched.
//
// Returns:
//	ValueTable - Table of debt adjustments found (Link, Number, Date, Organization).
//
Function DebtAdjustmentsBasedOn(Basis, FilterParameters = Undefined, AttributesOfDebtAdjustment = Undefined, Posted = False) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT DISTINCT
	|	ARAPAdjustment.Ref                    AS Ref,
	|	ARAPAdjustment.Number                     AS Number,
	|	ARAPAdjustment.Date                      AS Date,
	|	ARAPAdjustment.Organization               AS Organization,
	|	ARAPAdjustment.Counterparty                AS Counterparty,
	|	ARAPAdjustment.Posted                  AS Posted
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS ARAPAdjustmentDebt_
	|		INNER JOIN Document.ARAPAdjustment AS ARAPAdjustment
	|		ON ARAPAdjustmentDebt_.Ref = ARAPAdjustment.Ref
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPAdjustmentDebt_.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	ARAPObjects.Object = &Basis
	|	AND (NOT ARAPAdjustment.DeletionMark)
	|	AND TRUE
	|");
	
	Query.SetParameter("Basis",   Basis);
	
	If FilterParameters <> Undefined Then
		
		ConditionsText = "";
		
		For Each FilterElement In FilterParameters Do
			ConditionsText = ConditionsText + "
			|	AND ARAPAdjustment." + FilterElement.Key + " = &" + FilterElement.Key;
			Query.SetParameter(FilterElement.Key, FilterElement.Value);
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "AND TRUE", ConditionsText);
		
	EndIf;
	
	If Posted Then
		Query.Text = StrReplace(Query.Text,
			"(NOT ARAPAdjustment.DeletionMark)",
			"ARAPAdjustment.Posted");
	EndIf;
	
	QueryResult = Query.Execute();
	
	AttributesOfDebtAdjustment = New Structure;
	For Each Column In QueryResult.Columns Do
		AttributesOfDebtAdjustment.Insert(Column.Name);
	EndDo;
	
	TableOfDebtAdjustments = New ValueTable;
	For Each Column In QueryResult.Columns Do
		TableOfDebtAdjustments.Columns.Add(Column.Name);
	EndDo;
	If Not QueryResult.IsEmpty() Then
		TableOfDebtAdjustments = QueryResult.Unload();
		FillPropertyValues(AttributesOfDebtAdjustment, TableOfDebtAdjustments[0]);
	EndIf;
	
	Return TableOfDebtAdjustments;
	
EndFunction

Function AdjustmentOfDebtOnBasisOf(Basis, Organization) Export
	
	Result = Undefined;
	FilterParameters = New Structure("Organization", Organization);
	DebtAdjustments = DebtAdjustmentsBasedOn(Basis, FilterParameters,  Undefined, False);
	If DebtAdjustments.Count() > 0 Then
		Result = DebtAdjustments[0].Ref;
	EndIf;
	
	Return Result;

EndFunction


// the function generates a Presentation of the debt adjustment.
//
// Parameters:
//  Number - String - Adjustment number.
//  Date - Date - Date of correction.
//  Posted - Boolean - Indicates that the document has been completed.
//  PresentationPrefix - String - Presentation Of the document title.
//  PresentationPostfix - String - Presentation Of an additional description of the document.
//
// Returns:
//	String - Presentation of debt adjustment.
//
Function PresentationOfDebtAdjustment(Number, Date, Posted = True, PresentationPrefix="", PresentationPostfix="") Export
	
	If Not ValueIsFilled(PresentationPrefix) Then
		PresentationPrefix = NStr("vi = 'Điều chỉnh công nợ';
									|ru = 'Корректировка задолженности';
									|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
									|it = 'Rettifica dell''indebitamento';
									|pl = 'Korekta zadłużenia';
									|tr = 'Borç düzeltmesi'");
	EndIf;
	
	HeaderStructure_ = New Structure;
	HeaderStructure_.Insert("Date", Date);
	HeaderStructure_.Insert("Number", Number);
	
	SubstringsArray = New Array;
	SubstringsArray.Add(TMCommonUseClientServer.GenerateDocumentTitle(HeaderStructure_, PresentationPrefix));
	If Not Posted Then
		SubstringsArray.Add(NStr("vi = '(chưa kết chuyển)';
								|ru = '(не проведен)';
								|en = '(not posted)'; fa = '(not posted)';
								|it = '(non registrato)';
								|pl = '(nie zatwierdzony)';
								|tr = '(kaydedilmedi)'"));
	EndIf;
	
	If ValueIsFilled(PresentationPostfix) Then
		SubstringsArray.Add(PresentationPostfix);
	EndIf;
	
	Presentation = StrConcat(SubstringsArray, " ");
	
	Return Presentation;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Debt_.Partner, Null AS TRUE)";

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

// Returns a table of documents for the return of goods to the supplier for which additional costs are calculated by calculating the cost. expenses.
// 
// Parameters:
//  Organization - CatalogRef.Companies - For which you need to get an additional .expenses. 
//  Counterparty - CatalogRef.Counterparties - The supplier for which the additional costs were incurred.expenses for the return of goods.
//  DocumentReturnPolicy - DocumentRef.ReturnOfGoodsToVendor - The document of return of goods to the supplier.
// 
// Returns:
//  ValueTable - Additional costs for refunds to the supplier
Function AdditionalCostsForReturnsToSupplier(Organization, Counterparty = Undefined, DocumentReturnPolicy = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReturnProducts.Ref AS DocumentReturnPolicy,
	|	ReturnProducts.Ref.Currency AS Currency,
	|	ReturnProducts.Sum AS ReturnAmount,
	|	CASE
	|		WHEN ReturnProducts.Ref.Currency = &CurrencyOfMan
	|			THEN Cost_.AddExpensesForGoods
	|		WHEN ReturnProducts.Ref.Currency = &ComplCurrency
	|			THEN Cost_.AddExpensesLocal
	|		ELSE CASE
	|				WHEN ExchangeRates.CourseNumerator IS NULL
	|						OR ExchangeRates.CourseNumerator = 0
	|					THEN 0
	|				ELSE Cost_.AddExpensesLocal / ISNULL(ExchangeRates.CourseNumerator, 1) * ISNULL(ExchangeRates.CourseDenominator, 1)
	|			END
	|	END AS AdditExpenseAmount,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator,
	|	Cost_.AddExpensesForGoods AS AddExpensesForGoods,
	|	Cost_.AddExpensesMan AS AddExpensesMan,
	|	Cost_.AddExpensesLocal AS AddExpensesLocal,
	|	Complaints.Ref AS Claim
	|FROM
	|	Document.ReturnOfGoodsToVendor.Goods AS ReturnProducts
	|		INNER JOIN AccumulationRegister.InventoryCost AS Cost_
	|		ON (Cost_.Recorder = ReturnProducts.Ref)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&OnDate, BaseCurrency = &ComplCurrency) AS ExchangeRates
	|		ON (ExchangeRates.Currency = ReturnProducts.Ref.Currency)
	|		LEFT JOIN Catalog.Complaints AS Complaints
	|		ON ReturnProducts.Ref = Complaints.Basis
	|			AND NOT Complaints.DeletionMark
	|			AND Complaints.ConductComplaintARAP
	|			AND &RecordComplaints
	|WHERE
	|	ReturnProducts.Ref.Organization = &Organization
	|	AND (ReturnProducts.Ref = &ReturnOfGoods OR &AnyDocument)
	|	AND (ReturnProducts.Ref.Counterparty = &Counterparty OR &AnyCounterparty)
	|	AND (Cost_.AddExpensesMan <> 0 OR Cost_.AddExpensesLocal <> 0)";
	
	Query.SetParameter("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	Query.SetParameter("OnDate", CurrentSessionDate());
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("AnyCounterparty", Counterparty = Undefined);
	Query.SetParameter("ReturnOfGoods", DocumentReturnPolicy);
	Query.SetParameter("AnyDocument", DocumentReturnPolicy = Undefined);
	RecordComplaints = GetFunctionalOption("RecordComplaints");
	Query.SetParameter("RecordComplaints", RecordComplaints);
	
	RefundTable = Query.Execute().Unload();
	ClaimsTable = RefundTable.Copy(,"DocumentReturnPolicy,Claim");
	
	RefundTable.GroupBy("DocumentReturnPolicy,Currency,ReturnAmount,AdditExpenseAmount,AddExpensesMan,AddExpensesLocal");
	RefundTable.Columns.Add("Claim", New TypeDescription("CatalogRef.Complaints"));
	If RecordComplaints Then
		Filter = New Structure("DocumentReturnPolicy");
		For Each Page1 In RefundTable Do
			Filter.DocumentReturnPolicy = Page1.DocumentReturnPolicy;
			FoundRows = ClaimsTable.FindRows(Filter);
			If FoundRows.Count() = 1 Then
				Page1.Claim = FoundRows[0].Claim;
			EndIf;
		EndDo;
	EndIf;
	
	Return RefundTable;
	
EndFunction

#EndRegion

#Region Internal

Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments) Export
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ARWriteOff;
	String.FullDocumentName			= Metadata.Documents.ARAPAdjustment.FullName();
	String.PurposeUseKey 	= "ARAPAdjustment";
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi giảm công nợ';
										|ru = 'Списание задолженности';
										|en = 'AR/AP write-off'; fa = 'AR/AP write-off';
										|it = 'Storno del debito';
										|pl = 'Umorzenie zadłużenia';
										|tr = 'Borcun gider yazılması'");
	String.Order                      = 1;
	String.AddButtonCreate        = True;
	
	If GetFunctionalOption("ToGenerateLossAllowance") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance;
		String.FullDocumentName			= Metadata.Documents.ARAPAdjustment.FullName();
		String.PurposeUseKey 	= "ARAPAdjustment";
		String.WorkplaceTitle	 	= NStr("vi = 'Ghi giảm công nợ';
											|ru = 'Списание задолженности';
											|en = 'AR/AP write-off'; fa = 'AR/AP write-off';
											|it = 'Storno del debito';
											|pl = 'Umorzenie zadłużenia';
											|tr = 'Borcun gider yazılması'");
		String.Order                      = 2;
		String.AddButtonCreate        = True;
	EndIf;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.APWriteOff;
	String.FullDocumentName			= Metadata.Documents.ARAPAdjustment.FullName();
	String.PurposeUseKey 	= "ARAPAdjustment";
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi giảm công nợ';
										|ru = 'Списание задолженности';
										|en = 'AR/AP write-off'; fa = 'AR/AP write-off';
										|it = 'Storno del debito';
										|pl = 'Umorzenie zadłużenia';
										|tr = 'Borcun gider yazılması'");
	String.Order                      = 3;
	String.AddButtonCreate        = True;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.AccrualOfAccountsReceivable;
		String.FullDocumentName			= Metadata.Documents.ARAPAdjustment.FullName();
		String.PurposeUseKey 	= "ARAPAdjustment";
		String.WorkplaceTitle	 	= NStr("vi = 'Tính công nợ';
											|ru = 'Начисление задолженности';
											|en = 'AR/AP accrual'; fa = 'AR/AP accrual';
											|it = 'Maturazione debito';
											|pl = 'Naliczenie zadłużenia';
											|tr = 'Borcun tahakkuku'");
		String.Order                      = 4;
		String.AddButtonCreate        = True;
		
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.AccrualOfAccountsPayable;
		String.FullDocumentName			= Metadata.Documents.ARAPAdjustment.FullName();
		String.PurposeUseKey 	= "ARAPAdjustment";
		String.WorkplaceTitle	 	= NStr("vi = 'Tính công nợ';
											|ru = 'Начисление задолженности';
											|en = 'AR/AP accrual'; fa = 'AR/AP accrual';
											|it = 'Maturazione debito';
											|pl = 'Naliczenie zadłużenia';
											|tr = 'Borcun tahakkuku'");
		String.Order                      = 5;
		String.AddButtonCreate        = True;
	EndIf;

	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								New ValueList, 
								New ValueList, 
								"");
	
	Return TableOfValuesAvailable;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.Date                                  AS Period,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.Counterparty                            AS Counterparty,
	|	UNDEFINED AS CostAllocationOptionLocal,
	|	UNDEFINED AS TypeOfValueOfVATExpenses,
	|	DocumentData.BusinessOperation                 AS BusinessOperation,
	|	DocumentData.PointInTime                         AS PointInTime,
	|	DocumentData.Posted                              AS Posted,
	|	DocumentData.Patch                           AS Patch,
	|	DocumentData.ReversedDocument                  AS ReversedDocument,
	|	DocumentData.CorrectedDocument                  AS CorrectedDocument,
	|	DocumentData.IntercompanyARAP             AS IntercompanyARAP,
	|	DocumentData.CorrespondenceWithIncome              AS CorrespondenceWithIncome,
	|	TRUE                                                AS DebtManyToOne,
	|	DocumentData.Debt_.(
	|		LineNumber AS LineNumber,
	|		PaymentType_ AS PaymentType_,
	|		Partner AS Partner,
	|		ARAPObject AS ARAPObject,
	|		ARAPCurrency AS ARAPCurrency,
	|		Sum AS Sum,
	|		RowID AS RowID
	|	) AS Debt_,
	|	DocumentData.IncomeExpensesAssetsLiabilities.(
	|		LineNumber AS LineNumber,
	|		AssetRef AS AssetRef,
	|		DimensionOfRevenue AS DimensionOfRevenue,
	|		DimensionOfExpenses AS DimensionOfExpenses,
	|		AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|		Currency AS Currency,
	|		Sum AS Sum,
	|		RowID AS RowID
	|	) AS IncomeExpensesAssetsLiabilities,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_
	|FROM
	|	Document.ARAPAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute().Unload();
	Attributes = Result[0];
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	If Query.Parameters.Debt_.Count() = 1 And Query.Parameters.IncomeExpensesAssetsLiabilities.Count() > 1 Then
		Query.SetParameter("DebtManyToOne", False);
	EndIf;

	Query.SetParameter("CurrencyOfMan",                               Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("LocalAccountingCurrency",          SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("UseAccountingOfOtherAssetsAndLiabilities",   GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(EmptyRef().Metadata().FullName()));
	SettingUpHO = Catalogs.BusinessTransactionsSettings.FindByAttribute("BusinessOperation", Attributes.BusinessOperation);
	Query.SetParameter("BusinessTransactionSetting", SettingUpHO);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Undefined, // DocumentCurrency
		Undefined, // ARAPCurrency
		Query.Parameters.Period,
		Query.Parameters.Organization);

	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTemporaryDebtTable(Query, QueryTexts) Export
	
	TempTableName = "Table1_";
	
	SetRequestParametersCurrencyCoefficients(Query); 
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText =
	"SELECT DISTINCT
	|	ARAPObjects.Ref                                       AS ARAPObject,
	|	CASE WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|					= VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|			THEN VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		ELSE ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|	END                                                        AS ContractRateOption,
	|	Debt_.ARAPCurrency                           AS ARAPCurrency,
	|	ARAPObjects.Object                                       AS Object,
	|	ARAPObjects.Organization                                  AS Organization,
	|	ARAPObjects.Partner                                      AS Partner,
	|	ARAPObjects.Counterparty                                   AS Counterparty,
	|	ARAPObjects.Contract                                      AS Contract,
	|	ARAPObjects.PaymentType_                                  AS PaymentType_,
	|	ARAPObjects.LineOfBusiness                      AS LineOfBusiness,
	|	ARAPObjects.VATTaxation                           AS VATTaxation,
	|	ARAPObjects.Department                                AS Department,
	|	ARAPObjects.UUID                      AS UUID,
	|	ARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness AS ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,
	|	ISNULL(ARAPObjects.LineOfBusiness.IncomeAccounting, FALSE)               AS IncomeAccounting,
	|	ISNULL(ARAPObjects.LineOfBusiness.VendorARAP, FALSE) AS VendorARAP
	|INTO CalculationObjectData
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS Debt_
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Debt_.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	Debt_.Ref = &Ref
	|INDEX BY
	|	ContractRateOption
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.ARAPObject                                      AS ARAPObject,
	|	NestedQuery.ARAPCurrency                                AS ARAPCurrency,
	|	MAX(NestedQuery.RateARAPCurrencyNumerator)         AS RateARAPCurrencyNumerator,
	|	MAX(NestedQuery.RateARAPCurrencyDenominator)       AS RateARAPCurrencyDenominator,
	|	MAX(NestedQuery.RateManagementAccountingCurrencyNumerator)   AS RateManagementAccountingCurrencyNumerator,
	|	MAX(NestedQuery.RateManagementAccountingCurrencyDenominator) AS RateManagementAccountingCurrencyDenominator
	|INTO ExchangeRates
	|FROM
	|	(SELECT
	|		CalculationObjectData.ARAPObject                             AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency                       AS ARAPCurrency,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateARAPCurrencyNumerator         AS RateARAPCurrencyNumerator,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateARAPCurrencyDenominator       AS RateARAPCurrencyDenominator,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateManagementAccountingCurrencyNumerator   AS RateManagementAccountingCurrencyNumerator,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateManagementAccountingCurrencyDenominator AS RateManagementAccountingCurrencyDenominator
	|	
	|	FROM
	|		InformationRegister.DocumentCurrenciesAndRates AS ExchangeRatesAndCurrenciesOfDocuments
	|			INNER JOIN CalculationObjectData AS CalculationObjectData
	|				ON CalculationObjectData.Object = ExchangeRatesAndCurrenciesOfDocuments.Document
	|					AND CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject                                AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency                          AS ARAPCurrency,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator            AS RateARAPCurrencyNumerator,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator          AS RateARAPCurrencyDenominator,
	|		0                                                                   AS RateManagementAccountingCurrencyNumerator,
	|		0                                                                   AS RateManagementAccountingCurrencyDenominator
	|	FROM
	|		InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&PointInTime, Contract IN (SELECT Contract FROM CalculationObjectData)) AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|			INNER JOIN CalculationObjectData AS CalculationObjectData
	|				ON CalculationObjectData.Contract = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|					AND CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject                                AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency                          AS ARAPCurrency,
	|		0                                                                   AS RateARAPCurrencyNumerator,
	|		0                                                                   AS RateARAPCurrencyDenominator,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator            AS RateManagementAccountingCurrencyNumerator,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator          AS RateManagementAccountingCurrencyDenominator
	|	FROM
	|		InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&PointInTime, Contract IN (SELECT Contract FROM CalculationObjectData)) AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|			INNER JOIN CalculationObjectData AS CalculationObjectData
	|				ON CalculationObjectData.Contract = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|					AND CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND CalculationObjectData.ARAPCurrency = &CurrencyOfMan
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject                                AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency                          AS ARAPCurrency,
	|		0                                                                   AS RateARAPCurrencyNumerator,
	|		0                                                                   AS RateARAPCurrencyDenominator,
	|		RelativeCourses.CourseNumerator                                    AS RateManagementAccountingCurrencyNumerator,
	|		RelativeCourses.CourseDenominator                                  AS RateManagementAccountingCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&PointInTime,
	|				Currency = &CurrencyOfMan
	|				AND BaseCurrency = &LocalAccountingCurrency) AS RelativeCourses 
	|				ON CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND NOT CalculationObjectData.ARAPCurrency = &CurrencyOfMan
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject        AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency  AS ARAPCurrency,
	|		RelativeCourses.CourseNumerator            AS RateARAPCurrencyNumerator,
	|		RelativeCourses.CourseDenominator          AS RateARAPCurrencyDenominator,
	|		0                                           AS RateManagementAccountingCurrencyNumerator,
	|		0                                           AS RateManagementAccountingCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&PointInTime,
	|				(Currency IN
	|					(SELECT
	|						T.ARAPCurrency
	|					FROM
	|						CalculationObjectData AS T))
	|				AND BaseCurrency = &LocalAccountingCurrency) AS RelativeCourses 
	|		ON CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.Mutable)
	|			AND RelativeCourses.Currency = CalculationObjectData.ARAPCurrency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject       AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency AS ARAPCurrency,
	|		0                                          AS RateARAPCurrencyNumerator,
	|		0                                          AS RateARAPCurrencyDenominator,
	|		RelativeCourses.CourseNumerator           AS RateManagementAccountingCurrencyNumerator,
	|		RelativeCourses.CourseDenominator         AS RateManagementAccountingCurrencyDenominator
	|	FROM
	|		CalculationObjectData AS CalculationObjectData
	|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|					&PointInTime, Currency = &CurrencyOfMan AND BaseCurrency = &LocalAccountingCurrency) AS RelativeCourses
	|				ON CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.Mutable)
	|	) AS NestedQuery
	|GROUP BY
	|	NestedQuery.ARAPObject,
	|	NestedQuery.ARAPCurrency
	|INDEX BY
	|	ARAPObject,
	|	ARAPCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	Debt_.ARAPObject AS ARAPObject,
	|
	|	CalculationObjectData.Organization AS Organization,
	|	CalculationObjectData.Counterparty AS Counterparty,
	|	Debt_.Partner AS Partner,
	|	CalculationObjectData.Contract AS Contract,
	|	CASE WHEN CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				AND CalculationObjectData.IncomeAccounting AND NOT CalculationObjectData.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			OR CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND CalculationObjectData.VendorARAP AND NOT CalculationObjectData.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN
	|			CalculationObjectData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfActivityOfCalculations,
	|	CASE WHEN CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				AND CalculationObjectData.IncomeAccounting
	|			OR CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND CalculationObjectData.VendorARAP
	|		THEN
	|			CalculationObjectData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN AccountingItems.AssetRef
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN AccountingItems.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|		THEN AccountingItems.AssetRef
	|		ELSE UNDEFINED
	|	END AS IncomeItem,
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|		THEN AccountingItems.DimensionOfRevenue
	|		ELSE UNDEFINED
	|	END AS DimensionOfRevenue,
	|
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|		THEN AccountingItems.AssetRef
	|		ELSE UNDEFINED
	|	END AS AssetAndLiabilityItem,
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|		THEN AccountingItems.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|
	|	Debt_.ARAPCurrency AS ARAPCurrency,
	|	
	|	ISNULL(Amounts.AmountExcludingVAT, Debt_.Sum) AS Sum,
	|
	|	CASE WHEN Debt_.ARAPCurrency = &LocalAccountingCurrency
	|		THEN Debt_.Sum
	|	ELSE ISNULL(Amounts.AmountExcludingVATCompl,
	|			CAST(Debt_.Sum
	|					* ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) 
	|					/ ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31,2)))
	|	END AS SumCompl,
	|
	|	CASE WHEN Debt_.ARAPCurrency = &CurrencyOfMan
	|		THEN Debt_.Sum
	|	ELSE ISNULL(Amounts.AmountExcludingVATMan,
	|				CAST(Debt_.Sum
	|					* ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1)
	|					/ (ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31,2)))
	|	END AS SumMan,
	|
	|	
	|	Debt_.PaymentType_ AS PaymentType_,
	|	Debt_.PaymentDate AS PaymentDate,
	|	CalculationObjectData.VATTaxation AS VATTaxation,
	|	CalculationObjectData.Department AS Department,
	|	AccountingItems.Department AS SubdivisionOfArticle,
	|	AccountingItems.GLAccountSettings AS GLAccountSettings,
	|	Debt_.RowID AS RowID,
	|	CalculationObjectData.UUID AS FinRecordID
	|
	|INTO Table1_
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS Debt_
	|	INNER JOIN CalculationObjectData AS CalculationObjectData
	|	ON Debt_.ARAPObject = CalculationObjectData.ARAPObject
	|	
	|	INNER JOIN
	|		Document.ARAPAdjustment.IncomeExpensesAssetsLiabilities AS AccountingItems
	|	ON
	|		Debt_.Ref = AccountingItems.Ref
	|	
	|	LEFT JOIN 
	|		ExchangeRates AS CurrencyExchangeRate
	|	ON 
	|		Debt_.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Debt_.ARAPObject = CurrencyExchangeRate.ARAPObject
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		&Ref = Amounts.Ref
	|		AND Debt_.RowID = Amounts.RowID
	|
	|WHERE
	|	Debt_.Ref = &Ref
	|	AND &DebtManyToOne
	|
	|UNION ALL
	|
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	Debt_.ARAPObject AS ARAPObject,
	|
	|	CalculationObjectData.Organization AS Organization,
	|	CalculationObjectData.Counterparty AS Counterparty,
	|	CalculationObjectData.Partner AS Partner,
	|	CalculationObjectData.Contract AS Contract,
	|	CASE WHEN CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				AND CalculationObjectData.IncomeAccounting AND NOT CalculationObjectData.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			OR CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND CalculationObjectData.VendorARAP AND NOT CalculationObjectData.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN
	|			CalculationObjectData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfActivityOfCalculations,
	|	CASE WHEN CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				AND CalculationObjectData.IncomeAccounting
	|			OR CalculationObjectData.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				AND CalculationObjectData.VendorARAP
	|		THEN
	|			CalculationObjectData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN AccountingItems.AssetRef
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN AccountingItems.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|		THEN AccountingItems.AssetRef
	|		ELSE UNDEFINED
	|	END AS IncomeItem,
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|		THEN AccountingItems.DimensionOfRevenue
	|		ELSE UNDEFINED
	|	END AS DimensionOfRevenue,
	|
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|		THEN AccountingItems.AssetRef
	|		ELSE UNDEFINED
	|	END AS AssetAndLiabilityItem,
	|	CASE WHEN VALUETYPE(AccountingItems.AssetRef) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|		THEN AccountingItems.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|
	|	Debt_.ARAPCurrency AS ARAPCurrency,
	|	
	|	ISNULL(Amounts.AmountExcludingVAT, AccountingItems.Sum) AS Sum,
	|
	|	CASE WHEN Debt_.ARAPCurrency = &LocalAccountingCurrency
	|		THEN AccountingItems.Sum
	|	ELSE CASE WHEN ISNULL(Amounts.AmountExcludingVATCompl, 0) <> 0
	|			THEN Amounts.AmountExcludingVATCompl
	|			ELSE CAST(AccountingItems.Sum
	|					* ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31,2))
	|			END
	|	END AS SumCompl,
	|
	|	CASE WHEN Debt_.ARAPCurrency = &CurrencyOfMan
	|		THEN AccountingItems.Sum
	|	ELSE CASE WHEN ISNULL(Amounts.AmountExcludingVATMan, 0) <> 0
	|			THEN Amounts.AmountExcludingVATMan
	|			ELSE CAST(AccountingItems.Sum
	|					* ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1)
	|					/ (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31,2))
	|			END
	|	END AS SumMan,
	|	
	|	Debt_.PaymentType_ AS PaymentType_,
	|	Debt_.PaymentDate AS PaymentDate,
	|	CalculationObjectData.VATTaxation AS VATTaxation,
	|	CalculationObjectData.Department AS Department,
	|	AccountingItems.Department AS SubdivisionOfArticle,
	|	AccountingItems.GLAccountSettings AS GLAccountSettings,
	|	AccountingItems.RowID AS RowID,
	|	CalculationObjectData.UUID AS FinRecordID
	|
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS Debt_
	|	INNER JOIN CalculationObjectData AS CalculationObjectData
	|	ON Debt_.ARAPObject = CalculationObjectData.ARAPObject
	|	
	|	INNER JOIN
	|		Document.ARAPAdjustment.IncomeExpensesAssetsLiabilities AS AccountingItems
	|	ON
	|		Debt_.Ref = AccountingItems.Ref
	|	
	|	LEFT JOIN 
	|		ExchangeRates AS CurrencyExchangeRate
	|	ON 
	|		Debt_.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Debt_.ARAPObject = CurrencyExchangeRate.ARAPObject
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		&Ref = Amounts.Ref
	|		AND AccountingItems.RowID = Amounts.RowID
	|
	|WHERE
	|	Debt_.Ref = &Ref
	|	AND NOT &DebtManyToOne
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CalculationObjectData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ExchangeRates";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "CustomersARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("BalancesOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Number AS RecorderNumber,
	|	Table.PaymentDate AS PaymentDate,
	|	Table.RecordType AS RecordType,
	|	
	|	// Dimensions
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.Organization AS Organization,
	|	Table.Counterparty AS Counterparty,
	|	Table.Partner AS Partner,
	|	Table.Contract AS Contract,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS Currency,
	|	
	|	// Resources
	|	// The amount in the settlement currency.
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.Sum) AS AmountDue,
	|	0 AS ToShip,
	|	
	|	SUM(Table.SumCompl) AS SumCompl,
	|	SUM(Table.SumMan) AS SumMan,
	|	
	|	// Attributes
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.PaymentForms.EmptyRef) AS PaymentMethod,
	|	VALUE(Catalog.Currencies.EmptyRef) AS DocumentCurrency,
	|	Table.ExcludeDuringControl AS ExcludeDuringControl,
	|
	|	Table.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	
	|	CASE
	|		WHEN SUM(Table.Sum) = 0
	|			OR Table.Currency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE CAST(SUM(Table.SumCompl) / SUM(Table.Sum) AS NUMBER(10, 4))
	|	END                                                                 AS RateARAPCurrencyNumerator,
	|	CASE
	|		WHEN SUM(Table.Sum) = 0
	|			OR Table.Currency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS RateARAPCurrencyDenominator,
	|	CASE
	|		WHEN SUM(Table.SumMan) = 0
	|			OR Table.Currency = &CurrencyOfMan
	|			THEN 0
	|		ELSE CAST(SUM(Table.SumCompl) / SUM(Table.SumMan) AS NUMBER(10, 4))
	|	END                                                                 AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE
	|		WHEN SUM(Table.SumMan) = 0
	|			OR Table.Currency = &CurrencyOfMan
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	5 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument,
	|	VALUE(Enum.SettlementOperations.ARAPAdjustment) AS SettlementTransaction
	|FROM
	|	(SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		// The amount in the settlement currency.
	|		CASE WHEN Debt_.Sum <= ReserveBalances.Sum
	|			THEN Debt_.Sum
	|			ELSE ReserveBalances.Sum
	|		END AS Sum,
	|		
	|		CASE WHEN Debt_.SumCompl <= ReserveBalances.SumCompl
	|			THEN Debt_.SumCompl
	|			ELSE ReserveBalances.SumCompl
	|		END AS SumCompl,
	|		CASE WHEN Debt_.SumMan <= ReserveBalances.SumMan
	|			THEN Debt_.SumMan
	|			ELSE ReserveBalances.SumMan
	|		END AS SumMan,
	|		
	|		// Attributes
	|		TRUE AS ExcludeDuringControl,
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract   
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|		INNER JOIN
	|			BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|		ON
	|			Debt_.RowID = ReserveBalances.RowID
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|
	|	WHERE
	|		&BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ARWriteOff),
	|			VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		// The amount in the settlement currency.
	|		CASE WHEN Debt_.Sum <= ISNULL(ReserveBalances.Sum, 0)
	|			THEN 0
	|			ELSE Debt_.Sum - ISNULL(ReserveBalances.Sum, 0)
	|		END AS Sum,
	|		
	|		CASE WHEN Debt_.SumCompl <= ISNULL(ReserveBalances.SumCompl, 0)
	|			THEN 0
	|			ELSE Debt_.SumCompl - ISNULL(ReserveBalances.SumCompl, 0)
	|		END AS SumCompl,
	|		CASE WHEN Debt_.SumMan <= ISNULL(ReserveBalances.SumMan, 0)
	|			THEN 0
	|			ELSE Debt_.SumMan - ISNULL(ReserveBalances.SumMan, 0)
	|		END AS SumMan,
	|		
	|		// Attributes
	|		TRUE AS ExcludeDuringControl,
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract   
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|		LEFT JOIN
	|			BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|		ON
	|			Debt_.RowID = ReserveBalances.RowID
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|
	|	WHERE
	|		&BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ARWriteOff),
	|			VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		AND (Debt_.Sum > ISNULL(ReserveBalances.Sum, 0)
	|			OR Debt_.SumCompl > ISNULL(ReserveBalances.SumCompl, 0)
	|			OR Debt_.SumMan > ISNULL(ReserveBalances.SumMan, 0))
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		// The amount in the settlement currency.
	|		-Debt_.Sum AS Sum,
	|		
	|		-Debt_.SumCompl AS SumCompl,
	|		-Debt_.SumMan AS SumMan,
	|		
	|		// Attributes
	|		FALSE AS ExcludeDuringControl,
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|	WHERE
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		// The amount in the settlement currency.
	|		Debt_.Sum AS Sum,
	|		
	|		Debt_.SumCompl AS SumCompl,
	|		Debt_.SumMan AS SumMan,
	|		
	|		// Attributes
	|		TRUE AS ExcludeDuringControl,
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|	WHERE
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.AccrualOfAccountsReceivable)
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		// The amount in the settlement currency.
	|		Debt_.Sum AS Sum,
	|		
	|		Debt_.SumCompl AS SumCompl,
	|		Debt_.SumMan AS SumMan,
	|		
	|		// Attributes
	|		TRUE AS ExcludeDuringControl,
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|	WHERE
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.AccrualOfAccountsPayable)
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)) AS Table
	|
	|GROUP BY
	|	Table.PaymentDate,
	|	Table.RecordType,
	|	
	|	// Dimensions
	|	Table.AccountingDimensionByPartners,
	|	Table.Organization,
	|	Table.Counterparty,
	|	Table.Partner,
	|	Table.Contract,
	|	Table.LineOfBusiness,
	|
	|	Table.ARAPObject,
	|	Table.Currency,
	|	
	|	// Attributes
	|	Table.ExcludeDuringControl,
	|	Table.FinRecordID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "VendorsARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("BalancesOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Number AS RecorderNumber,
	|	Table.PaymentDate AS PaymentDate,
	|	Table.RecordType AS RecordType,
	|	
	|	// Dimensions
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.Organization AS Organization,
	|	Table.Counterparty AS Counterparty,
	|	Table.Partner AS Partner,
	|	Table.Contract AS Contract,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS Currency,
	|	
	|	// Resources
	|	// The amount in the settlement currency.
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.Sum) AS AmountDue,
	|	
	|	SUM(Table.SumCompl) AS SumCompl,
	|	SUM(Table.SumMan) AS SumMan,
	|	
	|	// Attributes
	|	&BusinessOperation AS BusinessOperation,
	|	Table.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	
	|	CASE
	|		WHEN SUM(Table.Sum) = 0
	|			OR Table.Currency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE CAST(SUM(Table.SumCompl) / SUM(Table.Sum) AS NUMBER(10, 4))
	|	END                                                                 AS RateARAPCurrencyNumerator,
	|	CASE
	|		WHEN SUM(Table.Sum) = 0
	|			OR Table.Currency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS RateARAPCurrencyDenominator,
	|	CASE
	|		WHEN SUM(Table.SumMan) = 0
	|			OR Table.Currency = &CurrencyOfMan
	|			THEN 0
	|		ELSE CAST(SUM(Table.SumCompl) / SUM(Table.SumMan) AS NUMBER(10, 4))
	|	END                                                                 AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE
	|		WHEN SUM(Table.SumMan) = 0
	|			OR Table.Currency = &CurrencyOfMan
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	5 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument,
	|	VALUE(Enum.SettlementOperations.ARAPAdjustment) AS SettlementTransaction
	|FROM
	|	(SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		Debt_.Sum AS Sum,
	|		Debt_.SumCompl AS SumCompl,
	|		Debt_.SumMan AS SumMan,
	|		
	|		// Attributes
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|	WHERE
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		-CASE WHEN Debt_.Sum <= ReserveBalances.Sum
	|			THEN Debt_.Sum
	|			ELSE ReserveBalances.Sum
	|		END AS Sum,
	|		-CASE WHEN Debt_.SumCompl <= ReserveBalances.SumCompl
	|			THEN Debt_.SumCompl
	|			ELSE ReserveBalances.SumCompl
	|		END AS SumCompl,
	|		-CASE WHEN Debt_.SumMan <= ReserveBalances.SumMan
	|			THEN Debt_.SumMan
	|			ELSE ReserveBalances.SumMan
	|		END AS SumMan,
	|		
	|		// Attributes
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|		INNER JOIN
	|			BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|		ON
	|			Debt_.RowID = ReserveBalances.RowID
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|
	|	WHERE
	|		&BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ARWriteOff),
	|			VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		-CASE WHEN Debt_.Sum <= ISNULL(ReserveBalances.Sum, 0)
	|			THEN 0
	|			ELSE Debt_.Sum - ISNULL(ReserveBalances.Sum, 0)
	|		END AS Sum,
	|		
	|		-CASE WHEN Debt_.SumCompl <= ISNULL(ReserveBalances.SumCompl, 0)
	|			THEN 0
	|			ELSE Debt_.SumCompl - ISNULL(ReserveBalances.SumCompl, 0)
	|		END AS SumCompl,
	|		-CASE WHEN Debt_.SumMan <= ISNULL(ReserveBalances.SumMan, 0)
	|			THEN 0
	|			ELSE Debt_.SumMan - ISNULL(ReserveBalances.SumMan, 0)
	|		END AS SumMan,
	|		
	|		// Attributes
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|		LEFT JOIN
	|			BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|		ON
	|			Debt_.RowID = ReserveBalances.RowID
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|
	|	WHERE
	|		&BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ARWriteOff),
	|			VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		AND (Debt_.Sum > ISNULL(ReserveBalances.Sum, 0)
	|			OR Debt_.SumCompl > ISNULL(ReserveBalances.SumCompl, 0)
	|			OR Debt_.SumMan > ISNULL(ReserveBalances.SumMan, 0))
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		Debt_.Sum AS Sum,
	|		Debt_.SumCompl AS SumCompl,
	|		Debt_.SumMan AS SumMan,
	|		
	|		// Attributes
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|	WHERE
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.AccrualOfAccountsReceivable)
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Debt_.PaymentDate AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		
	|		// Dimensions
	|		RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|		Debt_.Organization AS Organization,
	|		Debt_.Counterparty AS Counterparty,
	|		Debt_.Partner AS Partner,
	|		Debt_.Contract AS Contract,
	|		Debt_.DirectionOfActivityOfCalculations AS LineOfBusiness,
	|
	|		Debt_.ARAPObject AS ARAPObject,
	|		Debt_.ARAPCurrency AS Currency,
	|		
	|		// Resources
	|		Debt_.Sum AS Sum,
	|		Debt_.SumCompl AS SumCompl,
	|		Debt_.SumMan AS SumMan,
	|		
	|		// Attributes
	|		Debt_.FinRecordID AS FinRecordID
	|	FROM
	|		Table1_ AS Debt_
	|		
	|		// Let's define the Analytics Keys
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			Debt_.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Debt_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Debt_.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Debt_.Contract = RegisterAccountingAnalyticsForPartners.Contract  
	|			AND Debt_.DirectionOfActivityOfCalculations = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|
	|	WHERE
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.AccrualOfAccountsPayable)
	|		AND Debt_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)) AS Table
	|		
	|GROUP BY
	|	Table.PaymentDate,
	|	Table.RecordType,
	|	
	|	// Dimensions
	|	Table.AccountingDimensionByPartners,
	|	Table.Organization,
	|	Table.Counterparty,
	|	Table.Partner,
	|	Table.Contract,
	|	Table.LineOfBusiness,
	|
	|	Table.ARAPObject,
	|	Table.Currency,
	|	
	|	// Attributes
	|	Table.FinRecordID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	Debt_.SubdivisionOfArticle AS Department,
	|	Debt_.LineOfBusiness AS LineOfBusiness,
	|	Debt_.IncomeItem AS IncomeItem,
	|	Debt_.DimensionOfRevenue AS DimensionOfRevenue,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	Debt_.SumMan AS Sum,
	|	CASE WHEN NOT &CompanyManagementAccounting
	|		THEN 0
	|		ELSE Debt_.SumMan
	|	END AS SumMan,
	|	CASE WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|		THEN 0
	|		ELSE Debt_.SumCompl
	|	END AS SumCompl,
	|	
	|	Debt_.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	Table1_ AS Debt_
	|	
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND Debt_.IncomeItem <> UNDEFINED
	|	AND &CorrespondenceWithIncome
	|
	|ORDER BY
	|	Debt_.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("BalancesOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	Debt_.SubdivisionOfArticle AS Department,
	|	Debt_.ExpenseItem AS ExpenseItem,
	|	Debt_.DimensionOfExpenses AS DimensionOfExpenses,
	|	Debt_.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	&Character*(ISNULL(Amounts.AmountExcludingVATMan, Debt_.SumMan) - ISNULL(ReserveBalances.SumMan, 0)) AS AmountIncludingVAT,
	|	&Character*(ISNULL(Amounts.AmountExcludingVATMan, Debt_.SumMan) - ISNULL(ReserveBalances.SumMan, 0)) AS AmountExcludingVAT,
	|	&Character*(ISNULL(Amounts.AmountExcludingVATMan, Debt_.SumMan) - ISNULL(ReserveBalances.SumMan, 0)) AS AmountExcludingVATMan,
	|	&Character*(ISNULL(Amounts.AmountExcludingVATCompl, Debt_.SumCompl) - ISNULL(ReserveBalances.SumCompl, 0)) AS AmountIncludingVATCompl,
	|	&Character*(ISNULL(Amounts.AmountExcludingVATCompl, Debt_.SumCompl) - ISNULL(ReserveBalances.SumCompl, 0)) AS AmountExcludingVATCompl,
	|	-ISNULL(ReserveBalances.PermanentDifference, 0) AS PermanentDifference,
	|	-ISNULL(ReserveBalances.CostTD, 0) AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	Debt_.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_ AS VariancePeriod
	|	
	|FROM
	|	Table1_ AS Debt_
	|	
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = &Ref
	|		AND Debt_.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON
	|		Debt_.RowID = ReserveBalances.RowID
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|WHERE
	|	Debt_.ExpenseItem <> UNDEFINED
	|	AND NOT &CorrespondenceWithIncome
	|";
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable Then
		QueryText = StrReplace(QueryText, "&Character", "-1");
	Else
		QueryText = StrReplace(QueryText, "&Character", "1");
	EndIf;
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	#Region ARWriteOff
	ARWriteOff =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	&Organization                            AS Organization,
	|	Debt_.SubdivisionOfArticle       AS Department,
	|	Debt_.LineOfBusiness   AS LineOfBusiness,
	|	Debt_.AssetAndLiabilityItem     AS AssetRef,
	|	CASE
	|		WHEN Debt_.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE Debt_.AssetsLiabilitiesDimension
	|	END                                   AS Dimension,
	|	Debt_.SumMan                  AS Sum
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&UseAccountingOfOtherAssetsAndLiabilities
	|	AND Debt_.AssetAndLiabilityItem <> UNDEFINED
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ARWriteOff),
	|		VALUE(Enum.BusinessTransactions.AccrualOfAccountsPayable))
	|";
	#EndRegion

	#Region APWriteOff
	APWriteOff =
	"SELECT
	|	&Period                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	&Organization                            AS Organization,
	|	Debt_.SubdivisionOfArticle       AS Department,
	|	Debt_.LineOfBusiness   AS LineOfBusiness,
	|	Debt_.AssetAndLiabilityItem     AS AssetRef,
	|	CASE
	|		WHEN Debt_.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE Debt_.AssetsLiabilitiesDimension
	|	END                                   AS Dimension,
	|	Debt_.SumMan                  AS Sum
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&UseAccountingOfOtherAssetsAndLiabilities
	|	AND Debt_.AssetAndLiabilityItem <> UNDEFINED
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.APWriteOff),
	|		VALUE(Enum.BusinessTransactions.AccrualOfAccountsReceivable))
	|";
	#EndRegion
	
	QueryText = APWriteOff
		+ " UNION ALL " + ARWriteOff;
	
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	#Region AccrualCreditWriteOffDebitDebt
	AccrualCreditWriteOffDebitDebt =
	"SELECT
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	Debt_.SubdivisionOfArticle      AS Department,
	|	Debt_.LineOfBusiness  AS LineOfBusiness,
	|	Debt_.AssetAndLiabilityItem    AS AssetRef,
	|	Debt_.AssetsLiabilitiesDimension AS Dimension,
	|	Debt_.GLAccountSettings     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	Debt_.SumCompl                AS SumCompl,
	|	Debt_.SumMan                 AS SumMan,
	|	Debt_.SumMan                 AS AmountIncludingVAT,
	|	Debt_.SumMan                 AS AmountExcludingVAT,
	|
	|	Debt_.FinRecordID   AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&UseAccountingOfOtherAssetsAndLiabilities
	|	AND Debt_.AssetAndLiabilityItem <> UNDEFINED
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.AccrualOfAccountsPayable),
	|		VALUE(Enum.BusinessTransactions.ARWriteOff))
	|";
	#EndRegion

	#Region AccrualDebitWriteOffCreditDebt
	AccrualDebitWriteOffCreditDebt =
	"SELECT
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	Debt_.SubdivisionOfArticle      AS Department,
	|	Debt_.LineOfBusiness  AS LineOfBusiness,
	|	Debt_.AssetAndLiabilityItem    AS AssetRef,
	|	Debt_.AssetsLiabilitiesDimension AS Dimension,
	|	Debt_.GLAccountSettings     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	Debt_.SumCompl                AS SumCompl,
	|	Debt_.SumMan                 AS SumMan,
	|	Debt_.SumMan                 AS AmountIncludingVAT,
	|	Debt_.SumMan                 AS AmountExcludingVAT,
	|
	|	Debt_.FinRecordID   AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&UseAccountingOfOtherAssetsAndLiabilities
	|	AND Debt_.AssetAndLiabilityItem <> UNDEFINED
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.AccrualOfAccountsReceivable),
	|		VALUE(Enum.BusinessTransactions.APWriteOff))";
	#EndRegion
	
	QueryText = AccrualDebitWriteOffCreditDebt
		+ " UNION ALL " + AccrualCreditWriteOffDebitDebt;
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""Debt_"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	&Period AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.ARAPCurrency AS DocumentCurrency,
	|	DocumentTable.ARAPCurrency AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	&Period AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	DocumentTable.Sum AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.ARWriteOff),
	|					VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance),
	|					VALUE(Enum.BusinessTransactions.AccrualOfAccountsPayable))
	|				AND DocumentTable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			OR DocumentTable.Ref.BusinessOperation IN (
	|						VALUE(Enum.BusinessTransactions.APWriteOff),
	|						VALUE(Enum.BusinessTransactions.AccrualOfAccountsReceivable))
	|				AND DocumentTable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &DebtManyToOne
	|
	|UNION ALL
	|
	|SELECT
	|	""IncomeExpensesAssetsLiabilities"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	&Period AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.ARAPCurrency AS DocumentCurrency,
	|	DocumentTable.ARAPCurrency AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	&Period AS DateOfCourse,
	|
	|	AccountingItems.LineNumber AS LineNumber,
	|	AccountingItems.RowID AS RowID,
	|	AccountingItems.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	AccountingItems.Sum AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.ARWriteOff),
	|					VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|				AND DocumentTable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			OR DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|				AND DocumentTable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS DocumentTable
	|	LEFT JOIN
	|		Document.ARAPAdjustment.IncomeExpensesAssetsLiabilities AS AccountingItems
	|	ON
	|		DocumentTable.Ref = AccountingItems.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT &DebtManyToOne
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("AllocationOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|		THEN VALUE(Enum.BusinessTransactions.ARWriteOff)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	Debt_.SubdivisionOfArticle AS Department,
	|	Debt_.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	CASE WHEN &IntercompanyARAP
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE Debt_.Partner
	|	END AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE WHEN VALUETYPE(Debt_.ARAPObject) IN(
	|			TYPE(Catalog.LeaseContract),
	|			TYPE(Catalog.LoanAndDepositContracts))
	|		THEN Debt_.ARAPObject
	|		ELSE Debt_.ARAPObject.Contract
	|	END AS Contract,
	|	Debt_.ARAPObject AS ARAPObject,
	|	
	|	Debt_.LineOfBusiness AS LineOfBusinessItems,
	|	CASE 
	|		WHEN Debt_.AssetAndLiabilityItem <> UNDEFINED
	|			THEN Debt_.AssetAndLiabilityItem 
	|		WHEN Debt_.IncomeItem <> UNDEFINED
	|			THEN Debt_.IncomeItem
	|		ELSE Debt_.ExpenseItem
	|	END AS IncomeAndExpenseItem,
	|	Debt_.DimensionOfRevenue AS DimensionOfRevenue,
	|	Debt_.DimensionOfExpenses AS DimensionOfExpenses,
	|	Debt_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	SUM(Debt_.SumMan - ISNULL(ReserveBalances.SumMan, 0)) AS Sum,
	|	0 AS AmountExcludingVAT,
	|	SUM(Debt_.SumCompl - ISNULL(ReserveBalances.SumCompl, 0)) AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,

	|	Debt_.ARAPCurrency AS Currency,
	|	SUM(Debt_.Sum - ISNULL(ReserveBalances.Sum, 0)) AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,

	|	Debt_.ARAPCurrency AS ARAPCurrency,
	|	SUM(Debt_.Sum- ISNULL(ReserveBalances.Sum, 0)) AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	Debt_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	Debt_.RowID AS FinRecordID
	|FROM
	|	Table1_ AS Debt_
	|	LEFT JOIN BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON Debt_.RowID = ReserveBalances.RowID
	|
	|GROUP BY
	|
	|	CASE WHEN &IntercompanyARAP
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE Debt_.Partner
	|	END,
	|	CASE WHEN VALUETYPE(Debt_.ARAPObject) IN(
	|			TYPE(Catalog.LeaseContract),
	|			TYPE(Catalog.LoanAndDepositContracts))
	|		THEN Debt_.ARAPObject
	|		ELSE Debt_.ARAPObject.Contract
	|	END,
	|	Debt_.ARAPObject,
	|	Debt_.AssetAndLiabilityItem,
	|	Debt_.AssetsLiabilitiesDimension,
	|	Debt_.IncomeItem,
	|	Debt_.DimensionOfRevenue,
	|	Debt_.ExpenseItem,
	|	Debt_.DimensionOfExpenses,
	|	Debt_.ARAPCurrency,
	|	Debt_.SubdivisionOfArticle,
	|	Debt_.LineOfBusiness,
	|	Debt_.RowID";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("AllocationOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
        QueryTextTemporaryDebtTable(Query, QueryTexts);
    EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	Debt_.SubdivisionOfArticle AS Department,
	|	Debt_.LineOfBusiness AS LineOfBusiness,
	|	
	|	UNDEFINED AS Partner,
	|	&Organization AS Counterparty,
	|	CASE WHEN VALUETYPE(Debt_.ARAPObject) IN(
	|					TYPE(Catalog.LeaseContract),
	|					TYPE(Catalog.LoanAndDepositContracts))
	|		THEN Debt_.ARAPObject
	|		ELSE Debt_.ARAPObject.Contract
	|	END AS Contract,
	|	Debt_.ARAPObject AS ARAPObject,
	|	
	|	Debt_.LineOfBusiness AS CorLineOfBusiness,
	|	CASE WHEN &IntercompanyARAP
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE Debt_.Partner
	|	END AS CorPartner,
	|	&Counterparty AS CorCounterparty,
	|	CASE WHEN VALUETYPE(Debt_.ARAPObject) IN(
	|					TYPE(Catalog.LeaseContract),
	|					TYPE(Catalog.LoanAndDepositContracts))
	|		THEN Debt_.ARAPObject
	|		ELSE Debt_.ARAPObject.Contract
	|	END AS CorContract,
	|	Debt_.ARAPObject AS CorARAPObject,
	|	
	|	ReserveBalances.SumMan AS Sum,
	|	0 AS AmountExcludingVAT,
	|	ReserveBalances.SumCompl AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	Debt_.ARAPCurrency AS Currency,
	|	ReserveBalances.Sum AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	Debt_.ARAPCurrency AS ARAPCurrency,
	|	ReserveBalances.Sum AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	Debt_.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|	ReserveBalances.Sum AS AdjAmountInARAPCurrency,
	|	0 AS AdjAmountExcludingVATInARAPCurrency,
	|	
	|	Debt_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	Debt_.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	Table1_ AS Debt_
	|	INNER JOIN BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON Debt_.RowID = ReserveBalances.RowID
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts)
	
	// We distribute the tabular part of the document write-off of reserves, data from the registers of mutual settlements
	// and balances from the register of reserves. As a result, we add 2 temporary tables to the query texts:
	//  - The remaining reserves of the remaining debts - in the context of the identifiers of the rows of the tabular part (used for Other expenses)
	//  - Distribution of reserves to the remaining debts - in the context of Settlement documents and Row Identifiers (used for Reserves)
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	AuxiliaryQuery = New Query;
	AuxiliaryQuery.TempTablesManager = Query.TempTablesManager;
	For Each Parameter In Query.Parameters Do
		AuxiliaryQuery.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	AuxiliaryQuery.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	
	#Region QueryTextDistributionOfCalculationsByRowIDs
	
	AuxiliaryQuery.Text =
	"SELECT
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder AS ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	SUM(Calculations.Debt * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS Sum,
	|	SUM(Calculations.DebtLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumCompl,
	|	SUM(Calculations.ARAPMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumMan
	|INTO TT_Calculations
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.Recorder = &Ref
	|	AND Calculations.Active
	|	AND NOT &NewOnlineARAPAccounting
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument
	|HAVING
	|	SUM(Calculations.Debt * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	SUM(Calculations.Debt * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS Sum,
	|	SUM(Calculations.DebtLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumCompl,
	|	SUM(Calculations.ARAPMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumMan
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.DocumentRecorder = &Ref
	|	AND Calculations.Active
	|	AND &NewOnlineARAPAccounting
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument
	|HAVING
	|	SUM(Calculations.Debt * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS Sum,
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumCompl,
	|	SUM(Calculations.PrepaymentMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumMan
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.Recorder = &Ref
	|	AND Calculations.Active
	|	AND NOT &NewOnlineARAPAccounting
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS Sum,
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumCompl,
	|	SUM(Calculations.PrepaymentMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS SumMan
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.DocumentRecorder = &Ref
	|	AND Calculations.Active
	|	AND &NewOnlineARAPAccounting
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT_Calculations.AccountingDimensionByPartners,
	|	TT_Calculations.ARAPObject,
	|	TT_Calculations.Currency,
	|	TT_Calculations.ARAPDocument
	|INTO Tt_AnalysisOfDoubtfulDebtsReserves
	|FROM
	|	TT_Calculations AS TT_Calculations
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Calculations.AccountingDimensionByPartners,
	|	TT_Calculations.ARAPObject,
	|	TT_Calculations.Currency,
	|	TT_Calculations.ARAPDocument,
	|	TT_Calculations.Sum,
	|	TT_Calculations.SumCompl,
	|	TT_Calculations.SumMan
	|FROM
	|	TT_Calculations AS TT_Calculations
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	Debt_.ARAPObject AS ARAPObject,
	|	Debt_.RowID,
	|	Debt_.Sum,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS SumMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS SumCompl
	|FROM
	|	Document.ARAPAdjustment.Debt_ AS Debt_
	|	
	|	// Clarification of amounts in the currency of regl and upr
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		&Ref = Amounts.Ref
	|		AND Debt_.RowID = Amounts.RowID
	|WHERE
	|	Debt_.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|ORDER BY
	|	LineNumber";
	
	#EndRegion
	
	PackageResult = AuxiliaryQuery.ExecuteBatch();
	
	TableCalculations = PackageResult[2].Unload();
	TableCalculations.Indexes.Add("ARAPObject");
	Table1_ = PackageResult[3].Unload();
	
	TableSettlementDocuments = TableCalculations.CopyColumns();
	TableSettlementDocuments.Columns.Add("RowID", New TypeDescription("String",, New StringQualifiers(36)));
	
	DistributionTable_1 = TableSettlementDocuments.CopyColumns();
	DistributionTable_1.Columns.Add("CostTD", New TypeDescription("Number"));
	DistributionTable_1.Columns.Add("PermanentDifference", New TypeDescription("Number"));
	
	If Not Table1_.Count() = 0 Then
		
		// We distribute the calculation table by row IDs of the debt table.
		
		For Each RowArrears In Table1_ Do
			TheStructureOfTheSearch = New Structure("ARAPObject", RowArrears.ARAPObject);
			FoundRows = TableCalculations.FindRows(TheStructureOfTheSearch);
			For Each LineCalculations In FoundRows Do
				If RowArrears.Sum = 0 And RowArrears.SumCompl = 0 And RowArrears.SumMan = 0 Then
					Break;
				EndIf;
				
				If LineCalculations.Sum = 0 And LineCalculations.SumCompl = 0 And LineCalculations.SumMan = 0 Then
					Continue;
				EndIf;
				
				Sum = Min(RowArrears.Sum, LineCalculations.Sum);
				SumMan = Min(RowArrears.SumMan, LineCalculations.SumMan);
				SumCompl = Min(RowArrears.SumCompl, LineCalculations.SumCompl);
				
				NewRow = TableSettlementDocuments.Add();
				FillPropertyValues(NewRow, LineCalculations,, "Sum,SumMan,SumCompl");
				NewRow.RowID = RowArrears.RowID;
				NewRow.Sum = Sum;
				NewRow.SumMan = SumMan;
				NewRow.SumCompl = SumCompl;
				
				RowArrears.Sum = RowArrears.Sum - Sum;
				RowArrears.SumMan = RowArrears.SumMan - SumMan;
				RowArrears.SumCompl = RowArrears.SumCompl - SumCompl;
				
				LineCalculations.Sum = LineCalculations.Sum - Sum;
				LineCalculations.SumMan = LineCalculations.SumMan - SumMan;
				LineCalculations.SumCompl = LineCalculations.SumCompl - SumCompl;
			EndDo;
		EndDo;
		
	EndIf;
	// We block the accumulation register "Reserves for doubtful debts" according to the Accounting Analytics for partners, Settlement Object and Currency.
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("AccumulationRegister.LossAllowance");
	DataLockItem.Mode = DataLockMode.Shared;
	DataLockItem.DataSource = TableSettlementDocuments;
	DataLockItem.UseFromDataSource("AccountingDimensionByPartners", "AccountingDimensionByPartners");
	DataLockItem.UseFromDataSource("ARAPObject", "ARAPObject");
	DataLockItem.UseFromDataSource("Currency", "Currency");
	DataLockItem.UseFromDataSource("ARAPDocument", "ARAPDocument");
	DataLock.Lock();
	
	#Region QueryTextBalancesOfProvisionsForDoubtfulDebts
	
	AuxiliaryQuery.Text =
	"SELECT
	|	ReserveBalances.AccountingDimensionByPartners,
	|	ReserveBalances.ARAPObject,
	|	ReserveBalances.Currency,
	|	ReserveBalances.ARAPDocument AS ARAPDocument,
	|	
	|	-ReserveBalances.SumBalance AS Sum,
	|	-ReserveBalances.SumComplBalance AS SumCompl,
	|	-ReserveBalances.SumManBalance AS SumMan,
	|	-ReserveBalances.CostTDBalance AS CostTD,
	|	-ReserveBalances.PermanentDifferenceBalance AS PermanentDifference
	|FROM
	|	AccumulationRegister.LossAllowance.Balance(&PointInTime) AS ReserveBalances
	|	
	|	INNER JOIN
	|		Tt_AnalysisOfDoubtfulDebtsReserves AS Tt_AnalysisOfDoubtfulDebtsReserves
	|	ON
	|		ReserveBalances.AccountingDimensionByPartners = Tt_AnalysisOfDoubtfulDebtsReserves.AccountingDimensionByPartners
	|		AND ReserveBalances.ARAPObject = Tt_AnalysisOfDoubtfulDebtsReserves.ARAPObject
	|		AND ReserveBalances.Currency = Tt_AnalysisOfDoubtfulDebtsReserves.Currency
	|		AND ReserveBalances.ARAPDocument = Tt_AnalysisOfDoubtfulDebtsReserves.ARAPDocument
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)";
	
	#EndRegion
	
	TableReserveBalances = AuxiliaryQuery.Execute().Unload();
	TableReserveBalances.Indexes.Add("AccountingDimensionByPartners,ARAPObject,Currency,ARAPDocument");
	
	If Not TableReserveBalances.Count() = 0 Then
		
		// We distribute the resulting table of settlement documents according to the table of reserve balances.
		
		For Each LineSettlementDocuments In TableSettlementDocuments Do
			TheStructureOfTheSearch = New Structure("AccountingDimensionByPartners,ARAPObject,Currency,ARAPDocument");
			FillPropertyValues(TheStructureOfTheSearch, LineSettlementDocuments);
			
			FoundRows = TableReserveBalances.FindRows(TheStructureOfTheSearch);
			For Each LineReserveBalances In FoundRows Do
				If LineSettlementDocuments.Sum = 0 And LineSettlementDocuments.SumCompl = 0 And LineSettlementDocuments.SumMan = 0 Then
					Break;
				EndIf;
				
				If LineReserveBalances.Sum = 0 And LineReserveBalances.SumCompl = 0 And LineReserveBalances.SumMan = 0 Then
					Continue;
				EndIf;
				
				Sum = Min(LineSettlementDocuments.Sum, LineReserveBalances.Sum);
				SumMan = Min(LineSettlementDocuments.SumMan, LineReserveBalances.SumMan);
				SumCompl = Min(LineSettlementDocuments.SumCompl, LineReserveBalances.SumCompl);
				AmountFA = LineReserveBalances.SumCompl - LineReserveBalances.CostTD - LineReserveBalances.PermanentDifference;
				
				NewRow = DistributionTable_1.Add();
				FillPropertyValues(NewRow, LineReserveBalances,, "Sum,SumMan,SumCompl");
				NewRow.RowID = LineSettlementDocuments.RowID;
				NewRow.Sum = Sum;
				NewRow.SumMan = SumMan;
				NewRow.SumCompl = SumCompl;
				If SumCompl > AmountFA Then
					NewRow.CostTD = Min(SumCompl, LineReserveBalances.CostTD);
					NewRow.PermanentDifference = Min(SumCompl, LineReserveBalances.PermanentDifference);
				Else 
					NewRow.CostTD = 0;
					NewRow.PermanentDifference = 0;
				EndIf;
				
				LineSettlementDocuments.Sum = LineSettlementDocuments.Sum - Sum;
				LineSettlementDocuments.SumMan = LineSettlementDocuments.SumMan - SumMan;
				LineSettlementDocuments.SumCompl = LineSettlementDocuments.SumCompl - SumCompl;
				
				LineReserveBalances.Sum = LineReserveBalances.Sum - Sum;
				LineReserveBalances.SumMan = LineReserveBalances.SumMan - SumMan;
				LineReserveBalances.SumCompl = LineReserveBalances.SumCompl - SumCompl;
				LineReserveBalances.CostTD = LineReserveBalances.CostTD - NewRow.CostTD;
				LineReserveBalances.PermanentDifference = LineReserveBalances.PermanentDifference - NewRow.PermanentDifference;
			EndDo;
		EndDo;
		
	EndIf;
	Query.SetParameter("AllocationOfProvisionsForDoubtfulDebts", DistributionTable_1);
	
	QueryText =
	"SELECT
	|	T.AccountingDimensionByPartners,
	|	T.ARAPObject,
	|	T.Currency,
	|	T.ARAPDocument,
	|	T.RowID,
	|	T.Sum,
	|	T.SumMan,
	|	T.SumCompl,
	|	T.CostTD,
	|	T.PermanentDifference
	|INTO AllocationOfProvisionsForDoubtfulDebts
	|FROM
	|	&AllocationOfProvisionsForDoubtfulDebts AS T";
	
	QueryTexts.Add(QueryText, "AllocationOfProvisionsForDoubtfulDebts");
	
	QueryText =
	"SELECT
	|	T.RowID,
	|	SUM(T.Sum) AS Sum,
	|	SUM(T.SumMan) AS SumMan,
	|	SUM(T.SumCompl) AS SumCompl,
	|	SUM(T.CostTD) AS CostTD,
	|	SUM(T.PermanentDifference) AS PermanentDifference
	|INTO BalancesOfProvisionsForDoubtfulDebts
	|FROM
	|	AllocationOfProvisionsForDoubtfulDebts AS T
	|GROUP BY
	|	T.RowID";
	
	QueryTexts.Add(QueryText, "BalancesOfProvisionsForDoubtfulDebts");
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLossAllowance(Query, QueryTexts, Registers)

	RegisterName = "LossAllowance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("AllocationOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	AllocationOfReserves.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	AllocationOfReserves.ARAPObject AS ARAPObject,
	|	AllocationOfReserves.Currency AS Currency,
	|	AllocationOfReserves.ARAPDocument AS ARAPDocument,
	|	UNDEFINED AS AmountType,
	|	
	|	AllocationOfReserves.Sum AS Sum,
	|	AllocationOfReserves.SumMan AS SumMan,
	|	AllocationOfReserves.SumCompl AS SumCompl,
	|	AllocationOfReserves.PermanentDifference AS PermanentDifference,
	|	AllocationOfReserves.CostTD AS CostTD,
	|	
	|	VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessOperation,
	|	AllocationOfReserves.RowID AS RowID,
	|	
	|	CASE
	|		WHEN AllocationOfReserves.ARAPObject REFS Catalog.ARAPObjects
	|			THEN AllocationOfReserves.ARAPObject.UUID
	|		ELSE AllocationOfReserves.RowID
	|	END AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessTransactionSetting
	|	
	|FROM
	|	AllocationOfProvisionsForDoubtfulDebts AS AllocationOfReserves";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS Partner,
	|	&Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Sum,
	|	&Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&Number AS SourceDocumentNumber,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate
	|FROM
	|	Document.ARAPAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;

	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,,);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
