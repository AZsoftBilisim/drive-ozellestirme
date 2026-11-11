#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, DocumentBasis";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
EndProcedure

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
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ExpenseReportLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ExpenseReport") Then
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
		
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableCashFlow(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		ExpenseReportLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
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

// This function defines the details of the selected advance report.
//
// Parameters:
//  ExpenseReport - DocumentRef.ExpenseReport - link to the document.
//
// Returns:
//	Structure - details of the advance report.
//
Function DocumentAttributes(ExpenseReport) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.Department AS Department
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &ExpenseReport
	|");
	
	Query.SetParameter("ExpenseReport", ExpenseReport);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Currency = Selection.Currency;
		AdvanceHolder = Selection.AdvanceHolder;
		Department = Selection.Department;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		AdvanceHolder = Catalogs.Users.EmptyRef();
		Department = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("AdvanceHolder", AdvanceHolder);
	AttributesStructure1.Insert("Department", Department);
	
	Return AttributesStructure1;
	
EndFunction

// Includes or excludes the purchase document in the advance report
// 
// Parameters:
// 	Ref - DocumentRef.ExpenseReport - Expense report
// 	DocumentsToChange -Array - Links to purchase documents
// 	AdditionalProperties - Structure - Additional properties for performing the procedure
// 	Cancel - Boolean - Indicates that the procedure failed
//
Procedure DeleteAddPurchaseDocuments(Ref, DocumentsToChange, AdditionalProperties, Cancel) Export
	
	PurchasingEditableDocument = Undefined;
	AdditionalProperties.Property("PurchasingEditableDocument", PurchasingEditableDocument);
	
	For Each DocumentToChange In DocumentsToChange Do
		
		BeginTransaction();
		
		Try
			
			DocumentObject = DocumentToChange.GetObject();
			
			If DocumentToChange <> PurchasingEditableDocument Then
				Try
					DocumentObject.Lock();
				Except
					MessageText = StrTemplate(
						NStr("vi = '%1 đang trong quá trình chỉnh sửa bởi người dùng hoặc hệ thống và không thể thay đổi.';
							|ru = '%1 находится в процессе редактирования пользователем или системой и не может быть изменено.';
							|en = '%1 is being edited by the user or the system and cannot be changed.'; fa = '%1 is being edited by the user or the system and cannot be changed.';
							|it = '%1 si trova in fase di correzione dall''utente o dal sistema e non può essere modificato.';
							|pl = '%1 jest w trakcie edycji przez użytkownika lub system i nie można go zmienić.';
							|tr = '%1, kullanıcı veya sistem tarafından düzenlenme sürecindedir ve değiştirilemez.'"),
						DocumentObject);
						CommonClientServer.MessageToUser(MessageText);
					Raise;
				EndTry;
			EndIf;
			
			DocumentObject.ExpenseReport = Ref;
			DocumentObject.AdditionalProperties.Insert("DoNotUpdateAdvanceReport");
			DocumentObject.Write();
			
			RecordSet = AccumulationRegisters.AdvanceHolderCash.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(DocumentObject.Ref);
			
			TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
				DocumentObject.Ref, "AdvanceHolderCash");
			
			SetPrivilegedMode(True);
			RecordSet.Load(TablesForRegisteredRecords["Table" + "AdvanceHolderCash"]);
			RecordSet.Write();
			SetPrivilegedMode(False);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorInfo = ErrorInfo();
			MessageText = NStr("vi = 'Không thể thay đổi chứng từ mua do: %1';
								|ru = 'Не удалось изменить документ закупки по причине: %1';
								|en = 'Cannot change the purchase document. Reason: %1'; fa = 'Cannot change the purchase document. Reason: %1';
								|it = 'Non è stato possibile modificare il documento di acquisto a causa di: %1';
								|pl = 'Nie można zmienić dokumentu zakupu z powodu: %1';
								|tr = 'Satın alma belgesi bu sebepten değiştirilemedi: %1'");
			MessageText = StrTemplate(MessageText, BriefErrorDescription(ErrorInfo));
			CommonClientServer.MessageToUser(MessageText);
			
			ErrorText = NStr("vi = 'Không thể sửa đổi chứng từ mua hàng.';
							|ru = 'Не удалось изменить документ закупки.';
							|en = 'Cannot change the purchase document.'; fa = 'Cannot change the purchase document.';
							|it = 'Non è stato possibile modificare il documento di acquisto.';
							|pl = 'Nie można zmienić dokumentu zakupu.';
							|tr = 'Satın alma belgesi değiştirilemedi'", Common.DefaultLanguageCode());
			WriteLogEvent(
				ErrorText,
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo));
				
			Cancel = True;
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ExpenseReportLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ExpenseReportLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	Status - EnumRef.ExpenseReportStatuses - Status of the advance report.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(Status) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpAccountToReflectDebitingExpenses
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.OtherExpenses";
	SetupParameters.ArticleType = "ArticleType";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("OtherExpensesPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction
// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	Status - EnumRef.ExpenseReportStatuses - Status of the advance report.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(Status) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.OtherExpenses";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesExpenseItem");
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	StatusConfirmed = Status = Enums.ExpenseReportStatuses.Upholded;
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = StatusConfirmed;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("OtherExpensesAssetsLiabilitiesDimension");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = StatusConfirmed;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("OtherExpensesDimensionOfExpenses");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
		
	Return ArrayOfSelectionParameters;
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	
	// Basis
	Item = Settings.Add();
	Item.Fields.Add("DocumentBasis");
	Finances.NewFilter(Item.Condition, "DocumentBasis",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentToVendorsAmountARAP");
	Item.Fields.Add("OneCurrency");
	Item.Fields.Add("MultipleCurrencies");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("OtherExpensesExpensesGroup");
	Item.Fields.Add("OtherExpensesVATGroup");
	Item.Fields.Add("OtherExpensesFillInDepartment");
	Item.Fields.Add("OtherExpensesFillInTheDivisionInTheLines");
	Item.Fields.Add("OtherExpensesFillInTheAssetExpenseItemInTheLines");
	Finances.NewFilter(Item.Condition, "Status", Enums.ExpenseReportStatuses.Upholded);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("OtherExpensesRejected");
	Item.Fields.Add("OtherExpensesReasonForRejection");
	Item.Fields.Add("ConfirmationDate");
	Finances.NewFilter(Item.Condition, "Status", Enums.ExpenseReportStatuses.Upholded);
	Finances.NewFilter(Item.Condition, "More.UseExpenseReportStatuses", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Currency");
	Finances.NewFilter(Item.Condition, "Multicurrency", False);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("ReceivedEmails");
	Item.Fields.Add("Spent");
	Item.Fields.Add("BalanceOverspend");
	Item.Fields.Add("OpeningBalanceOverExpenditure");
	Item.Fields.Add("TurnDown");
	Item.Fields.Add("CurrentCurrency1");
	Item.Fields.Add("CurrentCurrency2");
	Finances.NewFilter(Item.Condition, "More.MultiCurrencyBasement", False);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("TheGroupMultiCurrencyAmounts");
	Finances.NewFilter(Item.Condition, "More.MultiCurrencyBasement", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PurchaseDocumentsAllCurrency");
	Item.Fields.Add("OtherExpensesCurrency");
	Item.Fields.Add("PaymentToVendorsCurrency");
	Item.Fields.Add("CurrencyConversion");

	Finances.NewFilter(Item.Condition, "Multicurrency", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PurchaseDocumentsAll");
	Finances.NewFilter(Item.Condition, "More.PrintASingleExpenseReport", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PurchaseDocumentsPurposeOfIssue");
	Finances.NewFilter(Item.Condition, "More.ControlIssueOfCashByPurposes", True);
	Item.Properties.Insert("Visible");
	
EndProcedure

// Defines the purchase documents included in the advance report
//
// Parameters:
//    Ref - DocumentRef.ExpenseReport - link to the advance report
//
// Returns:
//    Array - Links to purchase documents
Function PurchasingDocumentsList(Ref) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.ExpenseReport = &Ref
	|	AND DocumentData.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.ExpenseReport = &Ref
	|	AND DocumentData.Ref.Posted
	|	AND DocumentData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|";
	
	Query.SetParameter("Ref", Ref);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
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
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(AdvanceHolder)
	|	AND ValueAllowed(PaymentToVendors.Vendor, NULL AS TRUE)";

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

#Region VATAccounting

Function ParametersForFillingInVATActivityType(Document) Export
	
	Attributes = New Structure("Date, Organization");
	
	If TypeOf(Document) = Type("DocumentRef.ExpenseReport") Then
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else
		FillPropertyValues(Attributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date = Attributes.Date;
	FillParameters.Organization = Attributes.Organization;
	
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"Status");
		Status = StructureFillingData.Status;
	ElsIf FillingData = Undefined Then
		Status = Undefined;
	Else
		Status = FillingData.Status;
	EndIf;
		
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = Status = Enums.ExpenseReportStatuses.Upholded;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)";
	
	ParametersStructure.DocumentAmount                   = "";
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	ParametersStructure.ARAPObjectSettings                  = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
		
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.PaymentToVendors";
	ParametersStructure.Partner                          = "Object.PaymentToVendors.Vendor";
	ParametersStructure.Terms                       = "";
	ParametersStructure.Contract                          = "";
	ParametersStructure.Counterparty                       = "Object.PaymentToVendors.Counterparty";
	ParametersStructure.FinancialAccountingGroup           = "";
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.LineOfBusiness          = "";
	ParametersStructure.Date                             = "Object.Date"; 
	ParametersStructure.PaymentID             = "";
	ParametersStructure.VATTaxation               = "";
	
	ParametersStructure.FormItems.AddToPaymentDecryption = "SelectionByStock";
	ParametersStructure.FormItems.ARAPDetails = "PaymentToVendors";
	
	ParametersStructure.RecordBranches                 = False;
	
	Return ParametersStructure;
EndFunction

// Query Text time points of previous advance reports.
// 
// Parameters:
//  TTName - String - The name of the temporary table, if the result needs to be placed in a temporary table.
// 
// Returns:
//  String - Query Text time points of previous advance reports
Function QueryTextExpenseReportData(Query, TTName = "") Export
	
	RecordersCashRefunded = New Array;
	RecordersCashRefunded.Add(Type("DocumentRef.CashAccountReceiptNote"));
	RecordersCashRefunded.Add(Type("DocumentRef.BankAccountReceiptNote"));
	
	RecordersCashIssued = OBEntryServer.AvailableTypesOfResidueInput();
	RecordersCashIssued.Add(Type("DocumentRef.CashVoucher"));
	RecordersCashIssued.Add(Type("DocumentRef.ElectronicTicketTransaction"));
	
	InitialBalanceRecorders = New Array;
	InitialBalanceRecorders.Add(Type("DocumentRef.OBEntry"));
	InitialBalanceRecorders.Add(Type("DocumentRef.OBEntryARAPAdvanceHolders"));
	
	Query.SetParameter("RecordersCashIssued", RecordersCashIssued);
	Query.SetParameter("RecordersCashRefunded", RecordersCashRefunded);
	Query.SetParameter("InitialBalanceRecorders", InitialBalanceRecorders);
	
	//By an array of links or by data from the Form
	If Query.Parameters.Property("Organization") Then
		
		QueryText = "
		|SELECT 
		|	&Organization AS Organization,
		|	&AdvanceHolder AS AdvanceHolder,
		|	&Department AS Department,
		|	&Ref AS Ref,
		|	&Date AS Date
		|INTO TTPeriods1
		|;";
	Else
		
		QueryText = "
			|SELECT DISTINCT
			|	RegisterData.Organization AS Organization,
			|	RegisterData.AdvanceHolder AS AdvanceHolder,
			|	RegisterData.Department AS Department,
			|	CASE
			|		WHEN RegisterData.Recorder REFS Document.ExpenseReport
			|			THEN RegisterData.Recorder
			|		WHEN RegisterData.Recorder REFS Document.VendorInvoice
			|			THEN CAST(RegisterData.Recorder AS Document.VendorInvoice).ExpenseReport
			|		WHEN RegisterData.Recorder REFS Document.ElectronicTicketTransaction
			|			THEN CAST(RegisterData.Recorder AS Document.ElectronicTicketTransaction).ExpenseReport
			|	END AS Ref, //Expense report
			|	CASE
			|		WHEN RegisterData.Recorder REFS Document.ExpenseReport
			|			THEN CAST(RegisterData.Recorder AS Document.ExpenseReport).Date
			|		WHEN RegisterData.Recorder REFS Document.VendorInvoice
			|			THEN CAST(RegisterData.Recorder AS Document.VendorInvoice).ExpenseReport.Date
			|		WHEN RegisterData.Recorder REFS Document.ElectronicTicketTransaction
			|			THEN CAST(RegisterData.Recorder AS Document.ElectronicTicketTransaction).ExpenseReport.Date
			|	END AS Date
			|INTO TTPeriods1
			|FROM
			|	AccumulationRegister.AdvanceHolderCash AS RegisterData
			|WHERE
			|	RegisterData.Recorder IN (&DocumentsArray)
			|			OR CAST(RegisterData.Recorder AS Document.VendorInvoice).ExpenseReport IN (&DocumentsArray)
			|			OR (CAST(RegisterData.Recorder AS Document.ElectronicTicketTransaction).ExpenseReport IN (&DocumentsArray)
			|				AND CAST(RegisterData.Recorder AS Document.ElectronicTicketTransaction).AdvanceHolder = RegisterData.AdvanceHolder)
			|;";
	EndIf;
	
	QueryText = QueryText + "
	|	
	|SELECT //1
	|	TTPeriods.Organization,
	|	TTPeriods.AdvanceHolder,
	|	TTPeriods.Department,
	|	TTPeriods.Ref,
	|	TTPeriods.Date AS DateCurReport,
	|	MAX(Document.Date) AS MaxDate
	|INTO MaximumDatesOfPreviousAO
	|FROM
	|	TTPeriods1 AS TTPeriods
	|		LEFT JOIN Document.ExpenseReport AS Document
	|		ON (Document.Organization = TTPeriods.Organization)
	|			AND (Document.AdvanceHolder = TTPeriods.AdvanceHolder)
	|			AND (Document.Department = TTPeriods.Department)
	|			AND (Document.Date < TTPeriods.Date)
	|			AND Document.Posted
	|GROUP BY
	|	TTPeriods.Organization,
	|	TTPeriods.AdvanceHolder,
	|	TTPeriods.Department,
	|	TTPeriods.Ref,
	|	TTPeriods.Date 
	|;
	|SELECT //2
	|	NestedQuery.Organization,
	|	NestedQuery.AdvanceHolder,
	|	NestedQuery.Department,
	|	NestedQuery.Ref,
	|	NestedQuery.DateCurReport AS DateCurReport,
	|	ISNULL(NestedQuery.PreviousLink.Date,DATETIME(1,1,1)) AS DatePreviousReport,
	|	ISNULL(NestedQuery.PreviousLink, UNDEFINED) AS PreviousReport
	|INTO ExpenseReportForPrintingVT3
	|FROM
	|	(SELECT
	|		TTPeriods.Organization,
	|		TTPeriods.AdvanceHolder,
	|		TTPeriods.Department,
	|		TTPeriods.Ref,
	|		TTPeriods.DateCurReport AS DateCurReport,
	|		MAX(Document.Ref) AS PreviousLink
	|	FROM
	|		MaximumDatesOfPreviousAO AS TTPeriods
	|			LEFT JOIN Document.ExpenseReport AS Document
	|				ON (Document.Organization = TTPeriods.Organization)
	|				AND (Document.AdvanceHolder = TTPeriods.AdvanceHolder)
	|				AND (Document.Department = TTPeriods.Department)
	|				AND (Document.Date = TTPeriods.MaxDate)
	|				AND Document.Posted
	|	GROUP BY
	|		TTPeriods.Organization,
	|		TTPeriods.AdvanceHolder,
	|		TTPeriods.Department,
	|		TTPeriods.Ref,
	|		TTPeriods.DateCurReport) AS NestedQuery
	|;
	|SELECT // 3
	|	ExpenseReportForPrintingVT3.Ref,
	|	Cash_Issued.Currency,
	|	Cash_Issued.IssuancePurpose,
	|	
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND VALUETYPE(Cash_Issued.Recorder) IN (&RecordersCashIssued)
	|			AND NOT VALUETYPE(Cash_Issued.Recorder) IN (&InitialBalanceRecorders)
	|			AND Cash_Issued.BusinessOperation <> VALUE(Enum.BusinessTransactions.RefundOfAdvanceHolderBooking) THEN
	|			ISNULL(Cash_Issued.Sum, 0)
	|		ELSE 0
	|	END) AS AmountIssuedInCash,
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND VALUETYPE(Cash_Issued.Recorder) IN (&RecordersCashIssued)
	|			AND NOT VALUETYPE(Cash_Issued.Recorder) IN (&InitialBalanceRecorders)
	|			AND Cash_Issued.BusinessOperation <> VALUE(Enum.BusinessTransactions.RefundOfAdvanceHolderBooking) THEN
	|			ISNULL(Cash_Issued.SumCompl, 0)
	|		ELSE 0
	|	END) AS AmountIssuedInCashLocal,
	|
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND VALUETYPE(Cash_Issued.Recorder) IN (&RecordersCashRefunded) THEN
	|			ISNULL(Cash_Issued.Sum, 0)
	|		ELSE 0
	|	END) AS AmountReturned,
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND VALUETYPE(Cash_Issued.Recorder) IN (&RecordersCashRefunded) THEN
	|			ISNULL(Cash_Issued.SumCompl, 0)
	|		ELSE 0
	|	END) AS LocalRefundAmount,
	|
	|	0 AS AmountConversion,
	|	0 AS LocalConversionAmount,
	|
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND VALUETYPE(Cash_Issued.Recorder) IN (TYPE(Document.BankAccountIssue), TYPE(Document.BankConfirmationAboutCashReceiptOnEmployeeAccount)) THEN
	|			ISNULL(Cash_Issued.Sum, 0)
	|		ELSE
	|			0
	|	END) AS AmountIssuedByCard,
	|	
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND VALUETYPE(Cash_Issued.Recorder) IN (TYPE(Document.BankAccountIssue), TYPE(Document.BankConfirmationAboutCashReceiptOnEmployeeAccount)) THEN
	|			ISNULL(Cash_Issued.SumCompl, 0)
	|		ELSE
	|			0
	|	END) AS AmountIssuedByLocalCreditCard
	|
	|INTO Issued
	|FROM
	|	ExpenseReportForPrintingVT3
	|	
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash AS Cash_Issued
	|	ON
	|		Cash_Issued.Period > ExpenseReportForPrintingVT3.DatePreviousReport
	|		AND Cash_Issued.Period <= ExpenseReportForPrintingVT3.DateCurReport
	|		AND Cash_Issued.Organization = ExpenseReportForPrintingVT3.Organization
	|		AND Cash_Issued.Department = ExpenseReportForPrintingVT3.Department
	|		AND Cash_Issued.AdvanceHolder = ExpenseReportForPrintingVT3.AdvanceHolder
	|
	|GROUP BY
	|	ExpenseReportForPrintingVT3.Ref,
	|	Cash_Issued.Currency,
	|	Cash_Issued.IssuancePurpose
	|
	|UNION ALL
	|
	|SELECT
	|	ExpenseReportForPrintingVT3.Ref,
	|	Cash_Issued.Currency,
	|	Cash_Issued.IssuancePurpose,
	|	
	|	0 AS AmountIssuedInCash,
	|	0 AS AmountIssuedInCashLocal,
	|	0 AS AmountReturned,
	|	0 AS LocalRefundAmount,
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND Cash_Issued.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) THEN
	|			ISNULL(Cash_Issued.Sum, 0)
	|		ELSE
	|			0
	|	END) AS AmountConversion,
	|	SUM(CASE
	|		WHEN Cash_Issued.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND Cash_Issued.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) THEN
	|			ISNULL(Cash_Issued.SumCompl, 0)
	|		ELSE
	|			0
	|	END) AS LocalConversionAmount,
	|	0 AS AmountIssuedByCard,
	|	0 AS AmountIssuedByLocalCreditCard
	|FROM
	|	ExpenseReportForPrintingVT3
	|		LEFT JOIN
	|			AccumulationRegister.AdvanceHolderCash AS Cash_Issued
	|		ON
	|			Cash_Issued.Recorder = ExpenseReportForPrintingVT3.Ref
	|				AND Cash_Issued.Organization = ExpenseReportForPrintingVT3.Organization
	|				AND Cash_Issued.Department = ExpenseReportForPrintingVT3.Department
	|				AND Cash_Issued.AdvanceHolder = ExpenseReportForPrintingVT3.AdvanceHolder
	|GROUP BY
	|	ExpenseReportForPrintingVT3.Ref,
	|	Cash_Issued.Currency,
	|	Cash_Issued.IssuancePurpose
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT // 4
	|	Spent.Ref AS Ref,
	|	Spent.Recorder AS Recorder,
	|	Spent.Currency AS Currency,
	|	Spent.IssuancePurpose AS IssuancePurpose,
	|	Spent.Sum AS AmountExpensed,
	|	Spent.SumCompl AS LocalAmountSpent
	|INTO Spent
	|FROM (
	|	SELECT
	|		ExpenseReportForPrintingVT3.Ref AS Ref,
	|		ExpenseReportForPrintingVT3.Ref AS Recorder,
	|		Cash.Currency,
	|		Cash.IssuancePurpose,
	|		ISNULL(Cash.Sum, 0) AS Sum,
	|		ISNULL(Cash.SumCompl, 0) AS SumCompl
	|	FROM
	|		ExpenseReportForPrintingVT3
	|		
	|		INNER JOIN
	|			AccumulationRegister.AdvanceHolderCash AS Cash
	|		ON
	|			Cash.Recorder = ExpenseReportForPrintingVT3.Ref
	|			AND Cash.Organization = ExpenseReportForPrintingVT3.Organization
	|			AND Cash.Department = ExpenseReportForPrintingVT3.Department
	|			AND Cash.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.ExpenseReport AS Ref,
	|		Cash.Recorder AS Recorder,
	|		Cash.Currency,
	|		Cash.IssuancePurpose,
	|		Cash.SumExpense AS Sum,
	|		Cash.SumComplExpense AS SumCompl
	|	FROM
	|		AccumulationRegister.AdvanceHolderCash.Turnovers(,, Recorder) AS Cash
	|		INNER JOIN Document.VendorInvoice AS DocumentData
	|		ON DocumentData.Ref = Cash.Recorder
	|	WHERE
	|		DocumentData.ExpenseReport IN (&DocumentsArray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.ExpenseReport AS Ref,
	|		Cash.Recorder AS Recorder,
	|		Cash.Currency,
	|		Cash.IssuancePurpose,
	|		-Cash.SumTurnover AS Sum,
	|		-Cash.SumComplTurnover AS SumCompl
	|	FROM
	|		AccumulationRegister.AdvanceHolderCash.Turnovers(,, Recorder) AS Cash
	|			INNER JOIN Document.ElectronicTicketTransaction AS DocumentData
	|				ON DocumentData.Ref = Cash.Recorder
	|			INNER JOIN
	|				ExpenseReportForPrintingVT3 AS ExpenseReportForPrintingVT3
	|			ON
	|				Cash.Organization = ExpenseReportForPrintingVT3.Organization
	|					AND Cash.Department = ExpenseReportForPrintingVT3.Department
	|					AND Cash.AdvanceHolder = ExpenseReportForPrintingVT3.AdvanceHolder
	|	WHERE
	|		DocumentData.ExpenseReport IN (&DocumentsArray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.ExpenseReport AS Ref,
	|		Cash.Recorder AS Recorder,
	|		Cash.Currency,
	|		Cash.IssuancePurpose,
	|		-Cash.SumTurnover AS Sum,
	|		-Cash.SumComplTurnover AS SumCompl
	|	FROM
	|		Document.ElectronicTicketTransaction AS DocumentData
	|			INNER JOIN Document.ElectronicTicketTransaction AS Ticket_Operations
	|				ON DocumentData.Ref = Ticket_Operations.ElectronicTicket
	|			INNER JOIN AccumulationRegister.AdvanceHolderCash.Turnovers(,, Recorder) AS Cash
	|				ON Ticket_Operations.Ref = Cash.Recorder
	|			INNER JOIN
	|				ExpenseReportForPrintingVT3 AS ExpenseReportForPrintingVT3
	|			ON
	|				Cash.Organization = ExpenseReportForPrintingVT3.Organization
	|					AND Cash.Department = ExpenseReportForPrintingVT3.Department
	|					AND Cash.AdvanceHolder = ExpenseReportForPrintingVT3.AdvanceHolder
	|	WHERE
	|		DocumentData.ExpenseReport IN (&DocumentsArray)
	|		
	|	) AS Spent
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT // 5 Balances
	|	ExpenseReportForPrintingVT3.Ref,
	|	Cash.Organization,
	|	Cash.AdvanceHolder,
	|	Cash.IssuancePurpose,
	|	Cash.Currency,
	|	SUM(CASE
	|		WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Cash.Sum
	|		ELSE
	|			-Cash.Sum
	|	END) AS SumClosingBalance,
	|	SUM(CASE
	|		WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Cash.SumCompl
	|		ELSE
	|			-Cash.SumCompl
	|	END) AS SumComplClosingBalance,
	|	SUM(CASE WHEN Cash.Period <= ExpenseReportForPrintingVT3.DatePreviousReport
	|					OR ExpenseReportForPrintingVT3.PreviousReport = Cash.Recorder
	|					OR ExpenseReportForPrintingVT3.DatePreviousReport = DATETIME(1, 1, 1)
	|						AND VALUETYPE(Cash.Recorder) IN (&InitialBalanceRecorders)
	|		THEN CASE
	|				WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Cash.Sum
	|				ELSE -Cash.Sum
	|			END
	|		ELSE 0
	|	END) AS SumOpeningBalance,
	|	SUM(CASE WHEN Cash.Period <= ExpenseReportForPrintingVT3.DatePreviousReport
	|					OR ExpenseReportForPrintingVT3.PreviousReport = Cash.Recorder
	|					OR ExpenseReportForPrintingVT3.DatePreviousReport = DATETIME(1, 1, 1)
	|						AND VALUETYPE(Cash.Recorder) IN (&InitialBalanceRecorders)
	|		THEN CASE
	|				WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Cash.SumCompl
	|				ELSE -Cash.SumCompl
	|			END
	|		ELSE 0
	|	END) AS SumComplOpeningBalance
	|INTO PreliminaryBalances
	|FROM
	|	ExpenseReportForPrintingVT3
	|	
	|	LEFT JOIN
	|		AccumulationRegister.AdvanceHolderCash AS Cash
	|	ON
	|		Cash.Organization = ExpenseReportForPrintingVT3.Organization
	|		AND Cash.Department = ExpenseReportForPrintingVT3.Department
	|		AND Cash.AdvanceHolder = ExpenseReportForPrintingVT3.AdvanceHolder
	|		AND (Cash.Period <= ExpenseReportForPrintingVT3.DateCurReport
	|			OR Cash.Recorder = ExpenseReportForPrintingVT3.Ref)
	|WHERE
	|	NOT Cash.Recorder REFS Document.ExchangeDifferenceCalculation
	|GROUP BY
	|	ExpenseReportForPrintingVT3.Ref,
	|	Cash.Organization,
	|	Cash.AdvanceHolder,
	|	Cash.IssuancePurpose,
	|	Cash.Currency
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT // 6 
	|	Balance.Ref,
	|	Balance.Organization,
	|	Balance.AdvanceHolder,
	|	Balance.Currency,
	|	Balance.IssuancePurpose,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumClosingBalance, 0) > 0 
	|			THEN Balance.SumClosingBalance
	|		ELSE 0
	|	END) AS ClosingBalance,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumClosingBalance, 0) < 0 
	|			THEN -Balance.SumClosingBalance
	|		ELSE 0
	|	END) AS UltimateOverExpenditure,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumComplClosingBalance, 0) > 0 
	|			THEN Balance.SumComplClosingBalance
	|		ELSE 0
	|	END) AS ClosingBalanceOfLocal,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumComplClosingBalance, 0) < 0 
	|			THEN -Balance.SumComplClosingBalance
	|		ELSE 0
	|	END) AS UltimateOverExpenditureOfLocal,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumOpeningBalance, 0) > 0 
	|			THEN Balance.SumOpeningBalance
	|		ELSE 0
	|	END) AS OpeningBalance,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumOpeningBalance, 0) < 0 
	|			THEN -Balance.SumOpeningBalance
	|		ELSE 0
	|	END) AS InitialOverExpenditure,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumComplOpeningBalance, 0) > 0 
	|			THEN Balance.SumComplOpeningBalance
	|		ELSE 0
	|	END) AS OpeningBalanceIsLocal,
	|	SUM(CASE
	|		WHEN ISNULL(Balance.SumComplOpeningBalance, 0) < 0 
	|			THEN -Balance.SumComplOpeningBalance
	|		ELSE 0
	|	END) AS InitialOverExpenditureLocal
	|INTO CurrentAdvanceTime
	|FROM
	|	PreliminaryBalances AS Balance
	|GROUP BY
	|	Balance.Ref,
	|	Balance.Organization,
	|	Balance.AdvanceHolder,
	|	Balance.IssuancePurpose,
	|	Balance.Currency
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT // 7
	|	CurrentAdvanceTime.Ref,
	|	CurrentAdvanceTime.Currency,
	|	CurrentAdvanceTime.IssuancePurpose,
	|	SUM(CurrentAdvanceTime.ClosingBalance),
	|	SUM(CurrentAdvanceTime.UltimateOverExpenditure),
	|	SUM(CurrentAdvanceTime.ClosingBalanceOfLocal),
	|	SUM(CurrentAdvanceTime.UltimateOverExpenditureOfLocal),
	|	SUM(CurrentAdvanceTime.OpeningBalance),
	|	SUM(CurrentAdvanceTime.InitialOverExpenditure),
	|	SUM(CurrentAdvanceTime.OpeningBalanceIsLocal),
	|	SUM(CurrentAdvanceTime.InitialOverExpenditureLocal)
	|INTO Balance
	|FROM
	|	CurrentAdvanceTime
	|GROUP BY
	|	CurrentAdvanceTime.Ref,
	|	CurrentAdvanceTime.Currency,
	|	CurrentAdvanceTime.IssuancePurpose
	|HAVING 
	|	 SUM(CurrentAdvanceTime.ClosingBalance) <> 0
	|	 OR SUM(CurrentAdvanceTime.UltimateOverExpenditure) <> 0
	|	 OR SUM(CurrentAdvanceTime.OpeningBalance) <> 0
	|	 OR SUM(CurrentAdvanceTime.InitialOverExpenditure) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT // 8
	|	HeaderData_.Ref AS Ref,
	|	HeaderData_.Ref.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	HeaderData_.Currency AS Currency,
	|	HeaderData_.IssuancePurpose AS IssuancePurpose,
	|	SUM(HeaderData_.AmountIssuedInCash)   AS AmountIssuedInCash,
	|	SUM(HeaderData_.AmountIssuedByCard)      AS AmountIssuedByCard,
	|	SUM(HeaderData_.AmountReturned)        AS AmountReturned,
	|	SUM(HeaderData_.ClosingBalance)        AS ClosingBalance,
	|	SUM(HeaderData_.UltimateOverExpenditure)     AS UltimateOverExpenditure,
	|	SUM(HeaderData_.AmountExpensed)     AS AmountExpensed,
	|	SUM(HeaderData_.OpeningBalance)       AS OpeningBalance,
	|	SUM(HeaderData_.InitialOverExpenditure)    AS InitialOverExpenditure,
	|	SUM(HeaderData_.AmountIssuedInCashLocal)   AS AmountIssuedInCashLocal,
	|	SUM(HeaderData_.AmountIssuedByLocalCreditCard)      AS AmountIssuedByLocalCreditCard,
	|	SUM(HeaderData_.LocalRefundAmount)        AS LocalRefundAmount,
	|	SUM(HeaderData_.ClosingBalanceOfLocal)        AS ClosingBalanceOfLocal,
	|	SUM(HeaderData_.UltimateOverExpenditureOfLocal)     AS UltimateOverExpenditureOfLocal,
	|	SUM(HeaderData_.LocalAmountSpent)     AS LocalAmountSpent,
	|	SUM(HeaderData_.OpeningBalanceIsLocal)       AS OpeningBalanceIsLocal,
	|	SUM(HeaderData_.InitialOverExpenditureLocal)    AS InitialOverExpenditureLocal
	|INTO TTName
	|FROM
	|(SELECT
	|	Issued.Ref AS Ref,
	|	Issued.Currency AS Currency,
	|	Issued.IssuancePurpose AS IssuancePurpose,
	|	0                               AS OpeningBalance,
	|	0                               AS InitialOverExpenditure,
	|	Issued.AmountIssuedInCash     AS AmountIssuedInCash,
	|	Issued.AmountIssuedByCard        AS AmountIssuedByCard,
	|	Issued.AmountConversion         AS AmountConversion,
	|	Issued.AmountReturned          AS AmountReturned,
	|	0                               AS ClosingBalance,
	|	0                               AS UltimateOverExpenditure,
	|	0                               AS AmountExpensed,
	|	0                               AS OpeningBalanceIsLocal,
	|	0                               AS InitialOverExpenditureLocal,
	|	Issued.AmountIssuedInCashLocal AS AmountIssuedInCashLocal,
	|	Issued.AmountIssuedByLocalCreditCard    AS AmountIssuedByLocalCreditCard,
	|	Issued.LocalConversionAmount     AS LocalConversionAmount,
	|	Issued.LocalRefundAmount      AS LocalRefundAmount,
	|	0                               AS ClosingBalanceOfLocal,
	|	0                               AS UltimateOverExpenditureOfLocal,
	|	0                               AS LocalAmountSpent
	|FROM
	|	Issued
	|WHERE
	|	Issued.AmountIssuedInCash <> 0 OR Issued.AmountIssuedByCard <> 0 OR Issued.AmountConversion <> 0 OR Issued.AmountReturned <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.Ref,
	|	Balance.Currency,
	|	Balance.IssuancePurpose AS IssuancePurpose,
	|	Balance.OpeningBalance AS OpeningBalance,
	|	Balance.InitialOverExpenditure AS InitialOverExpenditure,
	|	0 AS AmountIssuedInCash,
	|	0 AS AmountIssuedByCard,
	|	0 AS AmountConversion,
	|	0 AS AmountReturned,
	|	Balance.ClosingBalance AS ClosingBalance,
	|	Balance.UltimateOverExpenditure AS UltimateOverExpenditure,
	|	0 AS AmountExpensed,
	|	Balance.OpeningBalanceIsLocal AS OpeningBalanceIsLocal,
	|	Balance.InitialOverExpenditureLocal AS InitialOverExpenditureLocal,
	|	0 AS AmountIssuedInCashLocal,
	|	0 AS AmountIssuedByLocalCreditCard,
	|	0 AS LocalConversionAmount,
	|	0 AS LocalRefundAmount,
	|	Balance.ClosingBalanceOfLocal AS ClosingBalanceOfLocal,
	|	Balance.UltimateOverExpenditureOfLocal AS UltimateOverExpenditureOfLocal,
	|	0 LocalAmountSpent
	|FROM
	|	Balance
	|
	|UNION ALL
	|
	|SELECT
	|	Spent.Ref AS Ref,
	|	Spent.Currency AS Currency,
	|	Spent.IssuancePurpose AS IssuancePurpose,
	|	0                               AS OpeningBalance,
	|	0                               AS InitialOverExpenditure,
	|	0 AS AmountIssuedInCash,
	|	0 AS AmountIssuedByCard,
	|	0 AS AmountConversion,
	|	0 AS AmountReturned,
	|	0 AS ClosingBalance,
	|	0 AS UltimateOverExpenditure,
	|	Spent.AmountExpensed AS AmountExpensed,
	|	0                               AS OpeningBalanceIsLocal,
	|	0                               AS InitialOverExpenditureLocal,
	|	0 AS AmountIssuedInCashLocal,
	|	0 AS AmountIssuedByLocalCreditCard,
	|	0 AS LocalConversionAmount,
	|	0 AS LocalRefundAmount,
	|	0 AS ClosingBalanceOfLocal,
	|	0 AS UltimateOverExpenditureOfLocal,
	|	Spent.LocalAmountSpent LocalAmountSpent
	|FROM
	|	Spent) AS HeaderData_
	|GROUP BY
	|	HeaderData_.Ref,
	|	HeaderData_.Currency,
	|	HeaderData_.IssuancePurpose
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////";
	
	If TTName = "" Then
		QueryText = StrReplace(QueryText,"INTO TTName","");
	Else
		QueryText = StrReplace(QueryText,"INTO TTName",StrTemplate("INTO %1",TTName));
	EndIf;
	
	Return QueryText
	
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
	TemporaryTableQueryTexts = New Map;
	
	FullDocumentName = "Document.ExpenseReport";

	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("Period",
		"	CASE
		|		WHEN BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.ConfirmationDate THEN
		|			DocumentData.Date
		|		ELSE
		|			DocumentData.ConfirmationDate
		|	END");
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		TemporaryTableQueryTexts.Insert(
			"SpentInRelatedDocuments",
			QueryTextTempTableConsumedInRelatedDocuments(Query, QueryTexts));
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
			True,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	CASE
	|		WHEN BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.ConfirmationDate THEN
	|			DocumentData.Date
	|		ELSE
	|			DocumentData.ConfirmationDate
	|	END AS Period,
	|	DocumentData.Date                    AS DocumentDate,
	|	DATETIME(1, 1, 1)						AS AdjustmentPeriod_,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.Multicurrency          AS Multicurrency,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.AdvanceHolder         AS AdvanceHolder,
	|	DocumentData.Department           AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.PurchaseForActivity  AS PurchaseForActivity,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.AmountExpensed      AS AmountExpensed,
	|	DocumentData.Status                  AS Status,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Query.SetParameter("DateOfRemainingGoods", ?(Query.Parameters.Period = Query.Parameters.DocumentDate,
												New Boundary(DocumentRef.PointInTime(), BoundaryType.Excluding),
												New Boundary(Query.Parameters.Period, BoundaryType.Excluding)));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                       Common.MetadataObjectID("Document.ExpenseReport"));
	Values.Insert("BusinessOperation",                         Enums.BusinessTransactions.OtherExpensesOfAdvanceHolders);
	Values.Insert("ManagementAccountingCurrency",                    Constants.ManagementAccountingCurrency.Get());
	Values.Insert("UseAccountingOfOtherIncomeExpenses",         GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("ControlIssueOfCashByPurposes",     GetFunctionalOption("ControlIssueOfCashByPurposes"));
	
	If Attributes <> Undefined Then
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",            Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",           Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("NumberForPrinting",                             ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)

	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	PaymentTable_.ARAPObject AS ARAPObject,
	|	PaymentTable_.Vendor  AS Partner,
	|	PaymentTable_.Counterparty AS Counterparty,
	|	PaymentTable_.ARAPObject.Organization AS Organization,
	|	PaymentTable_.ARAPObject.Contract AS Contract,
	|	PaymentTable_.ARAPObject.Department AS Department,
	|	PaymentTable_.ARAPObject.LineOfBusiness AS LineOfBusiness
	|
	|INTO TableOfCalculationObjects
	|FROM
	|	Document.ExpenseReport.PaymentToVendors AS PaymentTable_
	|	
	|WHERE
	|	PaymentTable_.Ref = &Ref
	|
	|INDEX BY
	|	ARAPObject
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&Organization                       				AS Organization,
	|	TableOfCalculationObjects.Counterparty 				AS Counterparty,
	|	TableOfCalculationObjects.Partner    				AS Partner,
	|	TableOfCalculationObjects.Contract    				AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	TableOfCalculationObjects AS TableOfCalculationObjects
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND TableOfCalculationObjects.Counterparty = Dimension.Counterparty
	|		AND TableOfCalculationObjects.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|");
	
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	QueryAnalyst.SetParameter("EmptyContract", Catalogs.CounterpartyContracts.EmptyRef());
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);

EndProcedure

Function RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts)
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	RegisterName = "PaymentToSuppliersTable";
	
	QueryText = "
	|SELECT
	|	PaymentToSuppliersTable.LineNumber AS LineNumber,
	|	PaymentToSuppliersTable.ARAPObject AS ARAPObject,
	|	TableOfCalculationObjects.Organization AS ARAPObjectOfCompany,
	|	TableOfCalculationObjects.Partner AS ARAPObjectIsPartner,
	|	TableOfCalculationObjects.Counterparty AS ARAPObjectCounterparty,
	|	TableOfCalculationObjects.Contract AS ARAPObjectContract,
	|	TableOfCalculationObjects.Department AS ObjectOfCalculationsDivision,
	|	TableOfCalculationObjects.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|
	|	PaymentToSuppliersTable.Sum AS Sum,
	|	PaymentToSuppliersTable.Currency AS Currency,
	|	PaymentToSuppliersTable.AmountARAP,
	|	PaymentToSuppliersTable.ARAPCurrency,
	|
	|	Dimension.DimensionKey AS AccountingDimensionByPartners,
	|	PaymentToSuppliersTable.RowID AS RowID
	|
	|INTO PaymentToSuppliersTable
	|FROM
	|	Document.ExpenseReport.PaymentToVendors AS PaymentToSuppliersTable
	|	
	|	INNER JOIN
	|		TableOfCalculationObjects AS TableOfCalculationObjects
	|	ON
	|		PaymentToSuppliersTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|		AND PaymentToSuppliersTable.Counterparty = TableOfCalculationObjects.Counterparty
	|		AND PaymentToSuppliersTable.Vendor = TableOfCalculationObjects.Partner
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND TableOfCalculationObjects.Counterparty = Dimension.Counterparty
	|		AND TableOfCalculationObjects.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentToSuppliersTable.Ref = &Ref
	|	AND PaymentToSuppliersTable.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTManExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRatesMan";
	
	QueryText =
	"SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * ManSExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO TTExchangeRatesMan
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			Currency = &ManagementAccountingCurrency AND BaseCurrency = &LocalAccountingCurrency) AS ManSExchangeRate
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND ManSExchangeRate.CourseNumerator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLocalExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRatesLocal";
	
	QueryText =
	"SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * LocalCurrencyExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * LocalCurrencyExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO TTExchangeRatesLocal
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			Currency = &LocalAccountingCurrency AND BaseCurrency = &LocalAccountingCurrency) AS LocalCurrencyExchangeRate
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND LocalCurrencyExchangeRate.CourseNumerator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts)
	
	RegisterName = "TTExchangeRatesOfReportLines";
	
	QueryTextsByConversionFactors = New ValueList;
	QueryTextTTManExchangeRates(Query, QueryTextsByConversionFactors);
	QueryTextTTLocalExchangeRates(Query, QueryTextsByConversionFactors);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		For Each ListItem In QueryTextsByConversionFactors Do
			QueryTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		For Each ListItem In QueryTextsByConversionFactors Do
			QueryTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
	EndIf;
	
	ExcludingTables = New Array;
	
	For Each TempTable In Query.TempTablesManager.Tables Do
		ExcludingTables.Add(TempTable.FullName);
	EndDo;
	
	Query.Text = "
	|SELECT
	|	Cash.SumBalance AS ReceivedEmails,
	|	Cash.SumManBalance AS SumManBalance,
	|	Cash.SumComplBalance AS SumComplBalance,
	|	Cash.IssuancePurpose AS IssuancePurpose,
	|	Cash.Currency AS Currency
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			&DateOfRemainingGoods,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND AdvanceHolder = &AdvanceHolder
	|				AND (Currency = &Currency
	|					OR &Multicurrency)) AS Cash
	|WHERE
	|	Cash.SumBalance > 0
	|	AND &ControlIssueOfCashByPurposes
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.SumBalance,
	|	Cash.SumManBalance,
	|	Cash.SumComplBalance,
	|	UNDEFINED AS IssuancePurpose,
	|	Cash.Currency AS Currency
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			&DateOfRemainingGoods,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND AdvanceHolder = &AdvanceHolder
	|				AND (Currency = &Currency
	|					OR &Multicurrency)) AS Cash
	|WHERE
	|	Cash.SumBalance > 0
	|	AND NOT &ControlIssueOfCashByPurposes
	|";

	Result = Query.Execute();
	
	CurrencyRatesOfAdvances = New ValueTable;
	
	For Each Column In Result.Columns Do
		CurrencyRatesOfAdvances.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	CurrencyRatesOfAdvances.Columns.Add("ManConversionFactor", New TypeDescription("Number"));
	CurrencyRatesOfAdvances.Columns.Add("LocalConversionRatio", New TypeDescription("Number"));
	
	Selection = Result.Select();

	While Selection.Next() Do

		NewRow = CurrencyRatesOfAdvances.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.ManConversionFactor = NewRow.SumManBalance / NewRow.ReceivedEmails;
		NewRow.LocalConversionRatio = NewRow.SumComplBalance / NewRow.ReceivedEmails;

	EndDo;
	
	TemporaryTable = New Array;
	TemporaryTable = QueryTextsByConversionFactors.UnloadValues();
	
	TempTablesQueryText = "
	|SELECT
	|	OtherExpenses.Currency AS Currency,
	|	OtherExpenses.CashFlowItem AS CashFlowItem,
	|	OtherExpenses.RowID AS RowID,
	|	OtherExpenses.AmountIncludingVAT AS Sum,
	|	OtherExpenses.AmountTotal AS AmountTotal
	|INTO ReportLines
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.Ref = &Ref
	|	AND NOT OtherExpenses.Canceled
	|	AND OtherExpenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentToVendors.Currency AS Currency,
	|	PaymentToVendors.CashFlowItem AS CashFlowItem,
	|	PaymentToVendors.RowID AS RowID,
	|	PaymentToVendors.Sum AS Sum,
	|	PaymentToVendors.AmountTotal AS AmountTotal
	|FROM
	|	Document.ExpenseReport.PaymentToVendors AS PaymentToVendors
	|WHERE
	|	PaymentToVendors.Ref = &Ref
	|	AND PaymentToVendors.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|
	|UNION ALL
	|
	|SELECT
	|	CurrencyConversion.Currency AS Currency,
	|	CurrencyConversion.CashFlowItem AS CashFlowItem,
	|	CurrencyConversion.RowID AS RowID,
	|	CurrencyConversion.Sum AS Sum,
	|	CurrencyConversion.AmountTotal AS AmountTotal
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS CurrencyConversion
	|WHERE
	|	CurrencyConversion.Ref = &Ref
	|	AND CurrencyConversion.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|;
	|SELECT
	|	DataTable.*
	|INTO CurrencyRatesOfAdvances
	|FROM
	|	&CurrencyRatesOfAdvances AS DataTable
	|";
	
	TemporaryTable.Add(TempTablesQueryText);
	
	Query.Text = StrConcat(TemporaryTable, ";");
	Query.SetParameter("CurrencyRatesOfAdvances", CurrencyRatesOfAdvances);
	Result = Query.Execute();
	
	Query.Text = "
	|SELECT
	|	ReportLines.RowID AS RowID,
	|	ReportLines.Currency AS Currency,
	|	ReportLines.Sum + CurrencyRatesOfAdvances.ReceivedEmails - ReportLines.AmountTotal AS Sum,
	|	CurrencyRatesOfAdvances.ManConversionFactor AS ManConversionFactor,
	|	CurrencyRatesOfAdvances.LocalConversionRatio AS LocalConversionRatio
	|FROM
	|	ReportLines AS ReportLines
	|	
	|		LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|		ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|		AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|			OR NOT &ControlIssueOfCashByPurposes)
	|WHERE
	|	ReportLines.AmountTotal - ReportLines.Sum < ISNULL(CurrencyRatesOfAdvances.ReceivedEmails, 0)
	|	AND ReportLines.AmountTotal > ISNULL(CurrencyRatesOfAdvances.ReceivedEmails, 0)
	|
	|	UNION ALL
	|	
	|SELECT
	|	ReportLines.RowID AS RowID,
	|	ReportLines.Currency AS Currency,
	|	ReportLines.AmountTotal - CurrencyRatesOfAdvances.ReceivedEmails AS Sum,
	|	TableManExchangeRates.ConversionFactor_ AS ManConversionFactor,
	|	TableLocalExchangeRates.ConversionFactor_ AS LocalConversionRatio
	|FROM
	|	ReportLines AS ReportLines
	|	
	|		LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|		ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|			AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|			OR NOT &ControlIssueOfCashByPurposes)
	|		
	|		LEFT JOIN TTExchangeRatesMan AS TableManExchangeRates
	|		ON TableManExchangeRates.Currency = ReportLines.Currency
	|		LEFT JOIN TTExchangeRatesLocal AS TableLocalExchangeRates
	|		ON TableLocalExchangeRates.Currency = ReportLines.Currency
	|WHERE
	|	ReportLines.AmountTotal - ReportLines.Sum < ISNULL(CurrencyRatesOfAdvances.ReceivedEmails, 0)
	|	AND ReportLines.AmountTotal > ISNULL(CurrencyRatesOfAdvances.ReceivedEmails, 0)
	|";

	Result = Query.Execute();
	
	SplitExpenseLine = New ValueTable;
	
	For Each Column In Result.Columns Do
		SplitExpenseLine.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	SplitExpenseLine.Columns.Add("SumMan", New TypeDescription("Number"));
	SplitExpenseLine.Columns.Add("SumCompl", New TypeDescription("Number"));
	
	Selection = Result.Select();

	While Selection.Next() Do

		NewRow = SplitExpenseLine.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.SumMan = NewRow.Sum * NewRow.ManConversionFactor;
		NewRow.SumCompl = NewRow.Sum * NewRow.LocalConversionRatio;

	EndDo;
	
	SplitExpenseLine.GroupBy("RowID,Currency", "SumMan, SumCompl, Sum");
	SplitExpenseLine.Columns.Add("ManConversionFactor", New TypeDescription("Number"));
	SplitExpenseLine.Columns.Add("LocalConversionRatio", New TypeDescription("Number"));
	
	For Each TableRow In SplitExpenseLine Do
		
		TableRow.ManConversionFactor = TableRow.SumMan / TableRow.Sum;
		TableRow.LocalConversionRatio = TableRow.SumCompl / TableRow.Sum;
		
	EndDo;
	
	QueryText = "
	|SELECT
	|	DataTable.RowID AS RowID,
	|	DataTable.Currency AS Currency,
	|	DataTable.ManConversionFactor AS ManConversionFactor,
	|	DataTable.LocalConversionRatio AS LocalConversionRatio
	|INTO SplitExpenseLine
	|FROM
	|	&SplitExpenseLine AS DataTable
	|;
	|
	|SELECT
	|	ReportLines.RowID AS RowID,
	|	CASE WHEN ReportLines.Currency = &ManagementAccountingCurrency 
	|		THEN 1
	|		ELSE CAST(CurrencyRatesOfAdvances.ManConversionFactor AS NUMBER(31,18))
	|	END AS ManConversionFactor,
	|	CASE WHEN ReportLines.Currency = &LocalAccountingCurrency 
	|		THEN 1
	|		ELSE CAST(CurrencyRatesOfAdvances.LocalConversionRatio AS NUMBER(31,18))
	|	END AS LocalConversionRatio
	|INTO TTExchangeRatesOfReportLines
	|FROM
	|	ReportLines AS ReportLines
	|		
	|		LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|		ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|		AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|			OR NOT &ControlIssueOfCashByPurposes)
	|
	|WHERE
	|	NOT CurrencyRatesOfAdvances.ReceivedEmails IS NULL
	|	AND ReportLines.AmountTotal <= CurrencyRatesOfAdvances.ReceivedEmails
	|	AND ReportLines.AmountTotal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	ReportLines.RowID AS RowID,
	|	CAST(ISNULL(TableManExchangeRates.ConversionFactor_, 0) AS NUMBER(31,18)) AS ManConversionFactor,
	|	CAST(ISNULL(TableLocalExchangeRates.ConversionFactor_, 0) AS NUMBER(31,18)) AS LocalConversionRatio
	|FROM
	|	ReportLines AS ReportLines
	|		
	|		LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|		ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|		AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|			OR NOT &ControlIssueOfCashByPurposes)
	|		
	|		LEFT JOIN TTExchangeRatesMan AS TableManExchangeRates
	|		ON TableManExchangeRates.Currency = ReportLines.Currency
	|		LEFT JOIN TTExchangeRatesLocal AS TableLocalExchangeRates
	|		ON TableLocalExchangeRates.Currency = ReportLines.Currency
	|WHERE
	|	ReportLines.AmountTotal - ReportLines.Sum >= ISNULL(CurrencyRatesOfAdvances.ReceivedEmails, 0)
	|	OR ReportLines.AmountTotal = 0
	|
	|UNION ALL
	|
	|SELECT
	|	SplitExpenseLine.RowID AS RowID,
	|	CASE WHEN SplitExpenseLine.Currency = &ManagementAccountingCurrency 
	|		THEN 1
	|		ELSE CAST(SplitExpenseLine.ManConversionFactor AS NUMBER(31,18))
	|	END AS ManConversionFactor,
	|	CASE WHEN SplitExpenseLine.Currency = &LocalAccountingCurrency 
	|		THEN 1
	|		ELSE CAST(SplitExpenseLine.LocalConversionRatio AS NUMBER(31,18))
	|	END AS LocalConversionRatio
	|FROM
	|	SplitExpenseLine AS SplitExpenseLine
	|";
	
	Query.SetParameter("SplitExpenseLine", SplitExpenseLine);
	
	ExcludingTables.Add("ReportLines");
	ExcludingTables.Add("CurrencyRatesOfAdvances");
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, , ExcludingTables);
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOfExchangeDifferences(Query, QueryTexts)
	
	RegisterName = "TableOfExchangeDifferences";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		QueryTextTTManExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		QueryTextTTLocalExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS CurrencyOfConversion,
	|	DocumentData.CashFlowItem,
	|	
	|	CAST(DocumentData.ConversionAmount * TableExchangeRatesManConversion.ConversionFactor_ AS NUMBER(31,2))
	|		- CAST(DocumentData.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|	AS SumMan,
	|	
	|	CAST(DocumentData.ConversionAmount * TableExchangeRatesLocalConversion.ConversionFactor_ AS NUMBER(31,2))
	|		- CAST(DocumentData.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	AS SumCompl,
	|	
	|	DocumentData.RowID AS RowID
	|
	|INTO TableOfExchangeDifferences
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS DocumentData
	|		
	|		LEFT JOIN TTExchangeRatesMan AS TableExchangeRatesManConversion
	|		ON TableExchangeRatesManConversion.Currency = DocumentData.CurrencyOfConversion
	|
	|		LEFT JOIN TTExchangeRatesLocal AS TableExchangeRatesLocalConversion
	|		ON TableExchangeRatesLocalConversion.Currency = DocumentData.CurrencyOfConversion
	|
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentData.RowID
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.Multicurrency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		QueryTextTTManExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		QueryTextTTLocalExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&AdvanceHolder AS AdvanceHolder,
	|	&Department AS Department,
	|	OtherExpenses.Currency AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		OtherExpenses.CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	OtherExpenses.AmountIncludingVAT AS Sum,
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS SumMan,
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS SumCompl,
	|	
	|	OtherExpenses.AmountIncludingVAT AS ToReport,
	|	
	|	VALUE(Enum.BusinessTransactions.OtherExpensesOfAdvanceHolders) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		OtherExpenses.CashFlowItem
	|	END AS CashFlowItem,
	|	OtherExpenses.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesOfAdvanceHolders) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS OtherExpenses
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = OtherExpenses.RowID
	|
	|WHERE
	|	OtherExpenses.Ref = &Ref
	|	AND NOT OtherExpenses.Canceled
	|	AND OtherExpenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&AdvanceHolder AS AdvanceHolder,
	|	&Department AS Department,
	|	PaymentToVendors.Currency AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentToVendors.CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	PaymentToVendors.Sum AS Sum,
	|	CASE WHEN PaymentToVendors.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentToVendors.AmountARAP
	|		ELSE PaymentToVendors.Sum * TableExchangeRatesOfReportLines.ManConversionFactor
	|	END AS SumMan,
	|	CASE WHEN PaymentToVendors.ARAPCurrency = &LocalAccountingCurrency AND PaymentToVendors.Currency <> &LocalAccountingCurrency
	|		THEN PaymentToVendors.AmountARAP
	|		ELSE PaymentToVendors.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio
	|	END AS SumCompl,
	|	PaymentToVendors.Sum AS ToReport,
	|	
	|	VALUE(Enum.BusinessTransactions.AdvanceHolderPaymentToVendor) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentToVendors.CashFlowItem
	|	END AS CashFlowItem,
	|	PaymentToVendors.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdvanceHolderPaymentToVendor) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ExpenseReport.PaymentToVendors AS PaymentToVendors
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = PaymentToVendors.RowID
	|	
	|WHERE
	|	PaymentToVendors.Ref = &Ref
	|	AND PaymentToVendors.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	
	|UNION ALL // Conversion of expense - balance with Receipt of Cash on the way
	|	
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&AdvanceHolder AS AdvanceHolder,
	|	&Department AS Department,
	|	CurrencyConversion.Currency AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		CurrencyConversion.CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	CurrencyConversion.Sum AS Sum,
	|	CurrencyConversion.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS SumMan,
	|	CurrencyConversion.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS SumCompl,
	|	CurrencyConversion.Sum AS ToReport,
	|	
	|	VALUE(Enum.BusinessTransactions.CurrencyConversionByAdvanceHolder) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		CurrencyConversion.CashFlowItem
	|	END AS CashFlowItem,
	|	CurrencyConversion.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversionByAdvanceHolder) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS CurrencyConversion
	|		
	|	LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = CurrencyConversion.RowID
	|WHERE
	|	CurrencyConversion.Ref = &Ref
	|	AND &Multicurrency
	|	AND CurrencyConversion.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	
	|UNION ALL // Conversion Receipt balance with Expense Cash in transit
	|	
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdvanceHolder AS AdvanceHolder,
	|	&Department AS Department,
	
	|	CurrencyConversion.CurrencyOfConversion AS Currency,
	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		CurrencyConversion.CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	CurrencyConversion.ConversionAmount AS Sum,
	|	CurrencyConversion.ConversionAmount * ISNULL(TableManExchangeRates.ConversionFactor_, 0) AS SumMan,
	|	CurrencyConversion.ConversionAmount * ISNULL(TableLocalExchangeRates.ConversionFactor_, 0) AS SumCompl,
	|	CurrencyConversion.ConversionAmount AS ToReport,
	|	
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		CurrencyConversion.CashFlowItem
	|	END AS CashFlowItem,
	|	CurrencyConversion.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCurrencyConversion) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS CurrencyConversion
	|		
	|		LEFT JOIN TTExchangeRatesMan AS TableManExchangeRates
	|		ON TableManExchangeRates.Currency = CurrencyConversion.CurrencyOfConversion
	|		LEFT JOIN TTExchangeRatesLocal AS TableLocalExchangeRates
	|		ON TableLocalExchangeRates.Currency = CurrencyConversion.CurrencyOfConversion
	|
	|WHERE
	|	CurrencyConversion.Ref = &Ref
	|	AND &Multicurrency
	|	AND CurrencyConversion.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) AS IncomeItem,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|	&Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|
	|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
	|
	|	TableOfExchangeDifferences.SumMan AS Sum,
	|	
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN TableOfExchangeDifferences.SumMan
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN TableOfExchangeDifferences.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|		
	|		TableOfExchangeDifferences.RowID AS FinRecordID,
	|		VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain) AS BusinessTransactionSetting
	|
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND (TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts);
	EndIf;
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.TaxationSystemSettings.Name,
		Query.TempTablesManager,
		Query.Parameters.Period,
		"TTTaxSystemSettings",
		Query.Parameters.Organization);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	ExpensesTable.Department AS Department,
	|	ExpensesTable.LineOfBusiness AS LineOfBusiness,
	|	ExpensesTable.ExpenseItem AS ExpenseItem,
	|	ExpensesTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	Attributes.PurchaseForActivity AS VATActivityType,
	|
	|	ExpensesTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS AmountIncludingVAT,
	|
	|	CAST(ExpensesTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(ExpensesTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|
	|	CASE WHEN NOT ExpensesTable.InvIsSubmitted AND NOT ExpensesTable.PrintFormLocalAccounting
	|		AND ISNULL(TaxationSystemSettings.TaxationSystem, UNDEFINED) <> VALUE(Enum.TaxationSystems.Simplified) THEN
	|		CAST(ExpensesTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	ELSE
	|		ExpensesTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio
	|	END AS AmountIncludingVATCompl,
	|	
	|	CAST(ExpensesTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.OtherExpenses) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	ExpensesTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesOfAdvanceHolders) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS ExpensesTable
	|		LEFT JOIN Document.ExpenseReport AS Attributes
	|		ON ExpensesTable.Ref = Attributes.Ref
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = ExpensesTable.RowID
	|		LEFT JOIN TTTaxSystemSettings AS TaxationSystemSettings
	|		ON Attributes.Organization = TaxationSystemSettings.Organization
	|WHERE
	|	ExpensesTable.Ref = &Ref
	|	AND VALUETYPE(ExpensesTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND ExpensesTable.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT ExpensesTable.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	ExpensesTable.Department AS Department,
	|	ExpensesTable.LineOfBusiness AS LineOfBusiness,
	|	(CASE
	|		WHEN &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN ExpensesTable.ExpenseItem
	|		ELSE &ExpenseItemVATWriteOff END) AS ExpenseItem,
	|	(CASE
	|		WHEN &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN ExpensesTable.DimensionOfExpenses
	|		ELSE &ExpenseDimensionVATWriteOff END) AS DimensionOfExpenses,
	|	Attributes.PurchaseForActivity AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|
	|	ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS AmountExcludingVATMan,
	|	ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS AmountIncludingVATCompl,
	|	ExpensesTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.VATOnAcquiredAssetsWriteOff) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	ExpensesTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS ExpensesTable
	|		LEFT JOIN Document.ExpenseReport AS Attributes
	|		ON ExpensesTable.Ref = Attributes.Ref
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = ExpensesTable.RowID
	|		LEFT JOIN TTTaxSystemSettings AS TaxationSystemSettings
	|		ON Attributes.Organization = TaxationSystemSettings.Organization
	|WHERE
	|	ExpensesTable.Ref = &Ref
	|	AND ExpensesTable.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT ExpensesTable.Canceled
	|	AND NOT ExpensesTable.InvIsSubmitted
	|	AND NOT ExpensesTable.PrintFormLocalAccounting
	|	AND VALUETYPE(ExpensesTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND ISNULL(TaxationSystemSettings.TaxationSystem, UNDEFINED) <> VALUE(Enum.TaxationSystems.Simplified)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) AS ExpenseItem,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|
	|	-TableOfExchangeDifferences.SumMan AS AmountIncludingVAT,
	|	-TableOfExchangeDifferences.SumMan AS AmountExcludingVAT,
	|	-TableOfExchangeDifferences.SumMan AS AmountExcludingVATMan,
	|	
	|	-TableOfExchangeDifferences.SumCompl AS AmountIncludingVATCompl,
	|	-TableOfExchangeDifferences.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TableOfExchangeDifferences.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss) AS BusinessTransactionSetting
	|	
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0
	|";
	
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS AssetRef,
	|	CASE
	|		WHEN OtherExpenses.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE OtherExpenses.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS Sum
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS OtherExpenses
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = OtherExpenses.RowID
	|WHERE
	|	OtherExpenses.Ref = &Ref
	|	AND VALUETYPE(OtherExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND OtherExpenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT OtherExpenses.Canceled
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTRegisteredRecordsInOtherAssetsLiabilities";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialRegisteredRecordsOnOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRegisteredRecordsInOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	QueryText = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.QueryTextTableOtherAssetsAndLiabilitiesRecords();
	ArrayOfRequestTexts.Add(QueryText);
	
	ArrayOfRequestTexts.Add(OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches(True));
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTInitialRegisteredRecordsOnOtherAssetsLiabilities";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS AssetRef,
	|	OtherExpenses.AssetsLiabilitiesDimension AS Dimension,
	|	OtherExpenses.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	OtherExpenses.Ref.PurchaseForActivity AS VATActivityType,
	|
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS SumCompl,
	|	CAST(OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS SumMan,
	|	CAST(OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS AmountIncludingVAT,
	|	CAST(OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))  AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	OtherExpenses.RowID AS RowID,
	|	OtherExpenses.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesOfAdvanceHolders) AS BusinessTransactionSetting
	|INTO TTInitialRegisteredRecordsOnOtherAssetsLiabilities
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS OtherExpenses
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = OtherExpenses.RowID
	|WHERE
	|	OtherExpenses.Ref = &Ref
	|	AND OtherExpenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND OtherExpenses.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND NOT OtherExpenses.Canceled
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Registers <> Undefined And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable("DocumentAmountsInAccountingCurrency", QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts);
	
	Text = "
	|////////////////////////////////////////////////////////////////////////////////
	|// Table DocumentAmountsInAccountingCurrency
	|"+
	"SELECT
	|	*
	|FROM
	|	TTAmountsOfDocumentsInAccountingCurrencies";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

Function QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts)
	
	RegisterName = "DocumentAmountsInLocalCurrency";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		QueryTextTTManExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		QueryTextTTLocalExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	&Period AS Period,
	|	CASE WHEN &Multicurrency THEN
	|		DocumentTable.Currency
	|	ELSE
	|		&Currency
	|	END AS Currency,
	|	CASE WHEN &Multicurrency THEN
	|		DocumentTable.Currency
	|	ELSE
	|		&Currency
	|	END AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	CAST(DocumentTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	CAST(DocumentTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|	DocumentTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS VATAmountMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	DocumentTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	CAST(DocumentTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))  AS VATBaseLocal,
	|	UNDEFINED AS ARAPCurrency,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS DocumentTable
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentTable.RowID
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT DocumentTable.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	&Period AS Period,
	|	CASE WHEN &Multicurrency THEN
	|		DocumentTable.Currency
	|	ELSE
	|		&Currency
	|	END AS Currency,
	|	CASE WHEN &Multicurrency THEN
	|		DocumentTable.Currency
	|	ELSE
	|		&Currency
	|	END AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	DocumentTable.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS AmountExcludingVATCompl,
	|	0 AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	DocumentTable.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS AmountExcludingVATMan,
	|	0 AS VATAmountMan,
	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	0 AS VATBaseLocal,
	|	DocumentTable.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP
	|
	|FROM
	|	Document.ExpenseReport.PaymentToVendors AS DocumentTable
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentTable.RowID
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	&Period AS Period,
	|	CASE WHEN DocumentTable.CurrencyOfConversion <> &LocalAccountingCurrency THEN
	|		DocumentTable.CurrencyOfConversion
	|	ELSE
	|		DocumentTable.Currency
	|	END AS Currency,
	|	CASE WHEN DocumentTable.CurrencyOfConversion <> &LocalAccountingCurrency THEN
	|		DocumentTable.CurrencyOfConversion
	|	ELSE
	|		DocumentTable.Currency
	|	END AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	CASE WHEN DocumentTable.CurrencyOfConversion <> &LocalAccountingCurrency THEN
	|		DocumentTable.ConversionAmount
	|	ELSE
	|		DocumentTable.Sum
	|	END AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	CASE WHEN DocumentTable.CurrencyOfConversion <> &LocalAccountingCurrency THEN
	|		CAST(DocumentTable.ConversionAmount * ISNULL(TableExchangeRatesLocalConversionAmount.ConversionFactor_, 0) AS NUMBER(31,2))
	|	ELSE
	|		CAST(DocumentTable.Sum * ISNULL(TableExchangeRatesLocalAmount.ConversionFactor_, 0) AS NUMBER(31,2))
	|	END AS AmountExcludingVATCompl,
	|	0 AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	CASE WHEN DocumentTable.CurrencyOfConversion <> &ManagementAccountingCurrency THEN
	|		CAST(DocumentTable.ConversionAmount * ISNULL(TableExchangeRatesManConversionAmount.ConversionFactor_, 0) AS NUMBER(31,2))
	|	ELSE
	|		CAST(DocumentTable.Sum * ISNULL(TableExchangeRatesManSum.ConversionFactor_, 0) AS NUMBER(31,2))
	|	END AS AmountExcludingVATMan,
	|	0 AS VATAmountMan,
	
	|	FALSE AS RecordedInARAPAccounting,
	|	CASE WHEN DocumentTable.CurrencyOfConversion <> &LocalAccountingCurrency THEN
	|		DocumentTable.ConversionAmount
	|	ELSE
	|		DocumentTable.Sum
	|	END AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	0 AS VATBaseLocal,
	|	UNDEFINED AS ARAPCurrency,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP
	|
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS DocumentTable
	|		
	|		LEFT JOIN TTExchangeRatesLocal AS TableExchangeRatesLocalAmount
	|		ON TableExchangeRatesLocalAmount.Currency = DocumentTable.Currency
	|		LEFT JOIN TTExchangeRatesLocal AS TableExchangeRatesLocalConversionAmount
	|		ON TableExchangeRatesLocalConversionAmount.Currency = DocumentTable.CurrencyOfConversion
	|		LEFT JOIN TTExchangeRatesMan AS TableExchangeRatesManSum
	|		ON TableExchangeRatesManSum.Currency = DocumentTable.Currency
	|		LEFT JOIN TTExchangeRatesMan AS TableExchangeRatesManConversionAmount
	|		ON TableExchangeRatesManConversionAmount.Currency = DocumentTable.CurrencyOfConversion
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &Multicurrency
	|	AND DocumentTable.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction // The text of the tablequestionsummydocumentsvaluteregl()

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period										AS Period,
	|	VALUE(AccumulationRecordType.Receipt)		AS RecordType,
	|	&Organization 								AS Organization,
	|	OtherExpenses.Department 				AS Department,
	|	OtherExpenses.LineOfBusiness		AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem				AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses				AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	&Ref 									AS ExpenseReceiptDocument,
	|	UNDEFINED 								AS LotVendorAttributes,
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	UNDEFINED                                AS VATActivityType,
	|
	|	OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor Cost,
	|	CAST(OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS VATManag,
	|	CAST(OtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	CAST(OtherExpenses.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS VATLocal,
	|	VALUE(Enum.BusinessTransactions.OtherExpenses) AS BusinessOperation,
	|	
	|	OtherExpenses.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesOfAdvanceHolders) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS OtherExpenses
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = OtherExpenses.RowID
	|WHERE
	|	OtherExpenses.Ref = &Ref
	|	AND OtherExpenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT OtherExpenses.Canceled
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period										AS Period,
	|	VALUE(AccumulationRecordType.Receipt) 		AS RecordType,
	|	&Organization 								AS Organization,
	|	Expenses.Department 						AS Department,
	|	Expenses.LineOfBusiness				AS LineOfBusiness,
	|	Expenses.ExpenseItem 						AS ExpenseItem,
	|	Expenses.DimensionOfExpenses 					AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	&Ref 									AS ExpenseReceiptDocument,
	|	UNDEFINED 								AS LotVendorAttributes,
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	UNDEFINED                                AS VATActivityType,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	CAST(Expenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(Expenses.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS LocalCost,
	|
	|	CASE WHEN NOT ConstructionArticles.EnteredInTaxAccounting THEN
	|		CAST(Expenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(Expenses.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	VALUE(Enum.BusinessTransactions.OtherExpenses) AS BusinessOperation,
	|	
	|	Expenses.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesOfAdvanceHolders) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS Expenses
	|
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ConstructionArticles
	|	ON
	|		Expenses.ExpenseItem = ConstructionArticles.Ref
	|		AND ConstructionArticles.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		AND ConstructionArticles.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = Expenses.RowID
	|
	|WHERE
	|	Expenses.Ref = &Ref
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND Expenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT Expenses.Canceled
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		QueryTextTTManExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		QueryTextTTLocalExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.CurrencyConversionByAdvanceHolder) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.AdvanceHolder AS Cash,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		CurrencyConversionTable.CashFlowItem
	|	END AS CashFlowItem,
	|	CurrencyConversionTable.Currency AS Currency,
	|
	|	DocumentData.AdvanceHolder AS CorCash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CorCashType,
	|	CurrencyConversionTable.CurrencyOfConversion AS CorrespondingCurency,
	|
	|	CAST(CurrencyConversionTable.ConversionAmount * ISNULL(TableManExchangeRates.ConversionFactor_, 0) AS NUMBER(31,2)) AS Sum,
	|	CAST(CurrencyConversionTable.ConversionAmount * ISNULL(TableLocalExchangeRates.ConversionFactor_, 0) AS NUMBER(31,2)) AS SumCompl,
	|	CurrencyConversionTable.Sum AS AmountInCurrency,
	|	CurrencyConversionTable.ConversionAmount AS AmountInCorCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS CorSourceOfFAGOfCash
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS CurrencyConversionTable
	|	
	|	INNER JOIN Document.ExpenseReport AS DocumentData
	|	ON CurrencyConversionTable.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN TTExchangeRatesMan AS TableManExchangeRates
	|		ON TableManExchangeRates.Currency = CurrencyConversionTable.CurrencyOfConversion
	|		LEFT JOIN TTExchangeRatesLocal AS TableLocalExchangeRates
	|		ON TableLocalExchangeRates.Currency = CurrencyConversionTable.CurrencyOfConversion
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers)

	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesOfAdvanceHolders) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	TableOtherExpenses.Department AS IncomeExpenseBusinessUnit,
	|
	|	DocumentData.AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		TableOtherExpenses.CashFlowItem
	|	END AS CashFlowItem,
	|	
	|	TableOtherExpenses.Currency AS Currency,
	|	
	|	TableOtherExpenses.LineOfBusiness AS LineOfBusinessItems,
	|	TableOtherExpenses.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	TableOtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOtherExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	TableOtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS Sum,
	|	TableOtherExpenses.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS SumCompl,
	|	TableOtherExpenses.AmountIncludingVAT AS AmountInCurrency,
	|	TableOtherExpenses.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS VATAmount,
	|	TableOtherExpenses.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS VATAmountCompl,
	|	TableOtherExpenses.VATAmount AS AmountVATCurrencyPayment,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	TableOtherExpenses.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
	|	TableOtherExpenses.VATRate AS VATRate
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|	
	|		INNER JOIN 
	|			Document.ExpenseReport.OtherExpenses AS TableOtherExpenses
	|		ON
	|			TableOtherExpenses.Ref = &Ref
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = TableOtherExpenses.RowID
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT TableOtherExpenses.Canceled
	|
	|UNION ALL
	|
	// Calculation of income from exchange differences
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Department AS IncomeExpenseBusinessUnit,
	|
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		TableOfExchangeDifferences.CashFlowItem
	|	END AS CashFlowItem,
	|	TableOfExchangeDifferences.CurrencyOfConversion AS Currency,
	|
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusinessItems,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) AS IncomeAndExpenseItem,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	TableOfExchangeDifferences.SumMan AS Sum,
	|	TableOfExchangeDifferences.SumCompl AS SumCompl,
	|	0 AS AmountInCurrency,
	
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS AmountVATCurrencyPayment,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) AS SourceOfIncomeExpensesFinancialAccountingGroup,
	|	UNDEFINED AS VATRate
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0
	|
	|UNION ALL
	|
	// Calculation of expenses from exchange differences
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Department AS IncomeExpenseBusinessUnit,
	|
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		TableOfExchangeDifferences.CashFlowItem
	|	END AS CashFlowItem,
	|	TableOfExchangeDifferences.CurrencyOfConversion AS Currency,
	|
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusinessItems,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences) AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|
	|	-TableOfExchangeDifferences.SumMan AS Sum,
	|	-TableOfExchangeDifferences.SumCompl AS SumCompl,
	|	0 AS AmountInCurrency,
	
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS AmountVATCurrencyPayment,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences) AS SourceOfIncomeExpensesFinancialAccountingGroup,
	|	UNDEFINED AS VATRate
	|
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentToSuppliersTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.Cash AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentCurrency AS PaymentCurrency,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	SUM(DocumentData.PayAmount) AS PayAmount,
	|	SUM(DocumentData.PaymentAmountLocal) AS PaymentAmountLocal,
	|	SUM(DocumentData.PaymentAmountPaymentCurrency) AS PaymentAmountPaymentCurrency,
	|
	|	SUM(DocumentData.PostpaymentAmount) AS PostpaymentAmount,
	|	SUM(DocumentData.PostpaymentAmountLocal) AS PostpaymentAmountLocal,
	|	SUM(DocumentData.PaymentAmountInPaymentCurrency) AS PaymentAmountInPaymentCurrency,
	|
	|	SUM(DocumentData.PrepaymentAmountMan) AS PrepaymentAmountMan,
	|	SUM(DocumentData.PrepaymentAmountLocal) AS PrepaymentAmountLocal,
	|	SUM(DocumentData.PrepaymentAmount) AS PrepaymentAmount,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	SUM(DocumentData.PaymentAmountInTheSettlementCurrency) AS PaymentAmountInTheSettlementCurrency,
	|	SUM(DocumentData.PostPaymentAmountInARAPCurrency) AS PostPaymentAmountInARAPCurrency,
	|	SUM(DocumentData.PrepaymentAmountInARAPCurrency) AS PrepaymentAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS DeferredPosting 
	|
	|FROM (
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.AdvanceHolderPaymentToVendor) AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|
	|		DocumentData.AdvanceHolder AS Cash,
	|		CASE WHEN &ControlIssueOfCashByPurposes THEN
	|			PaymentToSuppliersTable.CashFlowItem
	|		END AS CashFlowItem,
	
	|		PaymentToSuppliersTable.Currency AS PaymentCurrency,
	|
	|		PaymentToSuppliersTable.Vendor AS Partner,
	|		PaymentToSuppliersTable.Counterparty AS Counterparty,
	|		PaymentToSuppliersTable.ARAPObject.Contract AS Contract,
	|		PaymentToSuppliersTable.ARAPObject AS ARAPObject,
	
	|		CASE WHEN PaymentToSuppliersTable.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN PaymentToSuppliersTable.AmountARAP
	|			ELSE PaymentToSuppliersTable.Sum * TableExchangeRatesOfReportLines.ManConversionFactor
	|		END AS PayAmount,
	
	|		CASE WHEN PaymentToSuppliersTable.ARAPCurrency = &LocalAccountingCurrency AND PaymentToSuppliersTable.Currency <> &LocalAccountingCurrency
	|			THEN PaymentToSuppliersTable.AmountARAP
	|			ELSE PaymentToSuppliersTable.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio
	|		END AS PaymentAmountLocal,
	
	|		PaymentToSuppliersTable.Sum AS PaymentAmountPaymentCurrency,
	|
	|		0 AS PostpaymentAmount,
	|		0 AS PostpaymentAmountLocal,
	|		0 AS PaymentAmountInPaymentCurrency,
	|		
	|		0 AS PrepaymentAmountMan,
	|		0 AS PrepaymentAmountLocal,
	|		0 AS PrepaymentAmount,
	|
	|		PaymentToSuppliersTable.ARAPCurrency AS ARAPCurrency,
	|
	|		PaymentToSuppliersTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
	|		0 AS PostPaymentAmountInARAPCurrency,
	|		0 AS PrepaymentAmountInARAPCurrency,
	|
	|		UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|		PaymentToSuppliersTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|	FROM
	|		Document.ExpenseReport AS DocumentData
	|	
	|		INNER JOIN
	|			Document.ExpenseReport.PaymentToVendors AS PaymentToSuppliersTable
	|		ON
	|			DocumentData.Ref = PaymentToSuppliersTable.Ref
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = PaymentToSuppliersTable.RowID
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND DocumentData.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	
	|	) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Cash,
	|	DocumentData.CashFlowItem,
	|	DocumentData.PaymentCurrency,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentToSuppliersTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	ArrayOfSubqueryTests = New Array;
	
	SubqueryText = "// Transferred the branch's debt to the organization
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|
	|		PaymentToSuppliersTable.ARAPObjectIsPartner AS Partner,
	|		PaymentToSuppliersTable.ARAPObjectCounterparty AS Counterparty,
	|		PaymentToSuppliersTable.ARAPObjectLineOfBusiness AS LineOfBusiness,
	|		PaymentToSuppliersTable.ARAPObjectContract AS Contract,
	|		PaymentToSuppliersTable.ARAPObject AS ARAPObject,
	|
	|		VALUE(Catalog.Partners.OurEnterprise) AS CorPartner,
	|		PaymentToSuppliersTable.ARAPObjectOfCompany AS CorCounterparty,
	|		&LineOfBusiness AS CorLineOfBusiness,
	|		PaymentToSuppliersTable.ARAPObjectContract AS CorContract,
	|		PaymentToSuppliersTable.ARAPObject AS CorARAPObject,
	|		
	|		CASE WHEN PaymentToSuppliersTable.Currency = &ManagementAccountingCurrency
	|			THEN PaymentToSuppliersTable.Sum
	|			ELSE PaymentToSuppliersTable.Sum * TableExchangeRatesOfReportLines.ManConversionFactor
	|		END AS Sum,
	|		CASE WHEN PaymentToSuppliersTable.Currency = &LocalAccountingCurrency
	|			THEN PaymentToSuppliersTable.Sum
	|			ELSE PaymentToSuppliersTable.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio
	|		END AS SumCompl,
	|		PaymentToSuppliersTable.Sum AS AmountInCurrency,
	|
	|		PaymentToSuppliersTable.ARAPCurrency AS ARAPCurrency,
	|		PaymentToSuppliersTable.AmountARAP AS AmountInARAPCurrency,
	|
	|		PaymentToSuppliersTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|		PaymentToSuppliersTable.AmountARAP AS AdjAmountInARAPCurrency,
	|
	|		PaymentToSuppliersTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		PaymentToSuppliersTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
	|	FROM
	|		Document.ExpenseReport AS DocumentData
	|	
	|	LEFT JOIN
	|		PaymentToSuppliersTable AS PaymentToSuppliersTable
	|			ON TRUE
	|		
	|	LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = PaymentToSuppliersTable.RowID
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND DocumentData.Organization <> PaymentToSuppliersTable.ARAPObjectOfCompany
	|";
	
	ArrayOfSubqueryTests.Add(SubqueryText);

	SubqueryText = "
	|// Repaid the debt of the branch to the supplier
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,//AccountsPayableType
	|		PaymentToSuppliersTable.ARAPObjectOfCompany AS Organization,
	|		PaymentToSuppliersTable.ObjectOfCalculationsDivision AS Department,
	|
	|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|		DocumentData.Organization AS Counterparty,
	|		&LineOfBusiness AS LineOfBusiness,
	|		PaymentToSuppliersTable.ARAPObjectContract AS Contract,
	|		PaymentToSuppliersTable.ARAPObject AS ARAPObject,
	|
	|		PaymentToSuppliersTable.ARAPObjectIsPartner AS CorPartner,
	|		PaymentToSuppliersTable.ARAPObjectCounterparty AS CorCounterparty,
	|		PaymentToSuppliersTable.ARAPObjectLineOfBusiness AS CorLineOfBusiness,
	|		PaymentToSuppliersTable.ARAPObjectContract AS CorContract,
	|		PaymentToSuppliersTable.ARAPObject AS CorARAPObject,
	|		
	|		CASE WHEN PaymentToSuppliersTable.Currency = &ManagementAccountingCurrency
	|			THEN PaymentToSuppliersTable.Sum
	|			ELSE PaymentToSuppliersTable.Sum * TableExchangeRatesOfReportLines.ManConversionFactor
	|		END AS Sum,
	|		CASE WHEN PaymentToSuppliersTable.Currency = &LocalAccountingCurrency
	|			THEN PaymentToSuppliersTable.Sum
	|			ELSE PaymentToSuppliersTable.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio
	|		END AS SumCompl,
	|		PaymentToSuppliersTable.Sum AS AmountInCurrency,
	|
	|		PaymentToSuppliersTable.ARAPCurrency AS ARAPCurrency,
	|		PaymentToSuppliersTable.AmountARAP AS AmountInARAPCurrency,
	|
	|		PaymentToSuppliersTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|		PaymentToSuppliersTable.AmountARAP AS AdjAmountInARAPCurrency,
	|
	|		PaymentToSuppliersTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		PaymentToSuppliersTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
	|	FROM
	|		Document.ExpenseReport AS DocumentData
	|	
	|	LEFT JOIN
	|		PaymentToSuppliersTable AS PaymentToSuppliersTable
	|			ON TRUE
	|		
	|	LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = PaymentToSuppliersTable.RowID
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND DocumentData.Organization <> PaymentToSuppliersTable.ARAPObjectOfCompany
	|";

	ArrayOfSubqueryTests.Add(SubqueryText);
	
	SubqueryText = StrConcat(ArrayOfSubqueryTests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness 
	|	END AS LineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|
	|	DocumentData.CorPartner AS CorPartner,
	|	DocumentData.CorCounterparty AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END AS CorLineOfBusiness,
	|	DocumentData.CorContract AS CorContract,
	|	DocumentData.CorARAPObject AS CorARAPObject,
	|	&Currency AS Currency,
	|
	|	SUM(DocumentData.Sum) AS Sum,
	|	SUM(DocumentData.SumCompl) AS SumCompl,
	|	SUM(DocumentData.AmountInCurrency) AS AmountInCurrency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	SUM(DocumentData.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
	|	SUM(DocumentData.AdjAmountInARAPCurrency) AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup
	|INTO TTMovementCounterpartyCounterparty
	|
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness 
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.CorPartner,
	|	DocumentData.CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END,
	|	DocumentData.CorContract,
	|	DocumentData.CorARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup
	|";
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	RecordsCounterpartyCounterparty.Period                        AS Period,
	|	RecordsCounterpartyCounterparty.BusinessOperation         AS BusinessOperation,
	|	RecordsCounterpartyCounterparty.Organization                   AS Organization,
	|	RecordsCounterpartyCounterparty.Department                 AS Department,
	|
	|	RecordsCounterpartyCounterparty.Partner                       AS Partner,
	|	RecordsCounterpartyCounterparty.Counterparty                    AS Counterparty,
	|	RecordsCounterpartyCounterparty.LineOfBusiness       AS LineOfBusiness,
	|	RecordsCounterpartyCounterparty.Contract                       AS Contract,
	|	RecordsCounterpartyCounterparty.ARAPObject                AS ARAPObject,
	|
	|	RecordsCounterpartyCounterparty.CorPartner                    AS CorPartner,
	|	RecordsCounterpartyCounterparty.CorCounterparty                 AS CorCounterparty,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness    AS CorLineOfBusiness,
	|	RecordsCounterpartyCounterparty.CorContract                    AS CorContract,
	|	RecordsCounterpartyCounterparty.CorARAPObject             AS CorARAPObject,
	|	RecordsCounterpartyCounterparty.Currency                        AS Currency,
	|
	|	RecordsCounterpartyCounterparty.Sum                         AS Sum,
	|	RecordsCounterpartyCounterparty.SumCompl                     AS SumCompl,
	|	RecordsCounterpartyCounterparty.AmountInCurrency                  AS AmountInCurrency,
	|
	|	RecordsCounterpartyCounterparty.ARAPCurrency          AS ARAPCurrency,
	|	RecordsCounterpartyCounterparty.AmountInARAPCurrency    AS AmountInARAPCurrency,
	|	RecordsCounterpartyCounterparty.CorCurrencyOfARAPAccounting       AS CorCurrencyOfARAPAccounting,
	|	RecordsCounterpartyCounterparty.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|
	|	RecordsCounterpartyCounterparty.SourceOfARAPFinancialAccountingGroup           AS SourceOfARAPFinancialAccountingGroup,
	|	RecordsCounterpartyCounterparty.CorSourceOfARAPFinancialAccountingGroup        AS CorSourceOfARAPFinancialAccountingGroup
	|
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("SpentInRelatedDocuments", QueryTexts) Then
		QueryTextTempTableConsumedInRelatedDocuments(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS StorageLocation,
	|	&AdvanceHolder                        AS Counterparty,
	|	&Department                          AS Department,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Ref                  AS Ref,
	|	&Number                                  AS IBDocumentNumber,
	|	&Status                                 AS Status,
	|	&Author                                  AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&AmountExpensed
	|	+ ISNULL(DocumentsData.Sum, 0) AS Sum,
	|	&Currency                                 AS Currency,
	|	UNDEFINED                            AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.ExpenseReport AS DocumentData
	|		LEFT JOIN SpentInRelatedDocuments AS DocumentsData
	|		ON DocumentData.Ref = DocumentsData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTempTableConsumedInRelatedDocuments(Query, QueryTexts)

	RegisterName = "SpentInRelatedDocuments";
	
	QueryText = "
	|SELECT
	|	NestedQuery.Ref,
	|	SUM(NestedQuery.Sum) AS Sum
	|INTO SpentInRelatedDocuments
	|FROM (SELECT
	|		DocumentData.Ref,
	|		VendorInvoice.DocumentAmount AS Sum
	|	FROM
	|		Document.ExpenseReport AS DocumentData
	|			INNER JOIN Document.VendorInvoice AS VendorInvoice
	|				ON DocumentData.Ref = VendorInvoice.ExpenseReport
	|					AND VendorInvoice.Posted
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.Multicurrency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref,
	|		SUM(CASE WHEN ElectronicTicketTransaction.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase)
	|					OR ElectronicTicketTransaction.OperationType = VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|					THEN ElectronicTicketTransaction.Sum
	|				ELSE -ElectronicTicketTransaction.Sum
	|			END) AS Sum
	|	FROM
	|		Document.ExpenseReport AS DocumentData
	|			INNER JOIN Document.ElectronicTicketTransaction.Operations AS ElectronicTicketTransaction
	|				ON DocumentData.Ref = ElectronicTicketTransaction.Ref.ExpenseReport
	|					AND ElectronicTicketTransaction.Ref.Posted
	|					AND ElectronicTicketTransaction.Ref.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.Multicurrency
	|	GROUP BY
	|		DocumentData.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref,
	|		SUM(CASE WHEN Ticket_Operations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|					THEN -Ticket_Operations.DocumentAmount
	|				ELSE Ticket_Operations.DocumentAmount
	|			END) AS Sum
	|	FROM
	|		Document.ExpenseReport AS DocumentData
	|			INNER JOIN Document.ElectronicTicketTransaction AS ETicketData
	|				ON DocumentData.Ref = ETicketData.ExpenseReport
	|					AND ETicketData.Posted
	|					AND ETicketData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|			INNER JOIN Document.ElectronicTicketTransaction AS Ticket_Operations
	|				ON ETicketData.Ref = Ticket_Operations.ElectronicTicket
	|				AND Ticket_Operations.Posted
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.Multicurrency
	|	GROUP BY
	|		DocumentData.Ref
	|	) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	
	If Query.TempTablesManager.Tables.Find("TTVATAccountingSettingsForUSN") = Undefined Then 
	
		QueryText = "SELECT
		|	&Organization AS Organization,
		|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS BasicTaxation
		|INTO TTVATAccountingSettingsForUSN
		|";

		RequestForAccountingSettings = New Query(QueryText);
		RequestForAccountingSettings.TempTablesManager = Query.TempTablesManager;
		RequestForAccountingSettings.SetParameter("Organization", Query.Parameters.Organization);
		RequestForAccountingSettings.Execute(); 
		
	EndIf;
	
	ValueText_ = "
	|SELECT
	|	&Period                                      AS Period,
	|	Expenses.Ref                               AS Ref,
	|	Expenses.Ref.Organization                   AS Organization,
	|	Expenses.Ref.Department                 AS Department,
	|	Expenses.Counterparty                           AS Counterparty,
	|	UNDEFINED                                 AS Contract,
	|	Expenses.Counterparty                           AS Shipper,
	|	CASE WHEN Expenses.PrintFormLocalAccounting AND Expenses.ElectronicTicket <> VALUE(Document.ElectronicTicketTransaction.EmptyRef) THEN
	|		Expenses.ElectronicTicket
	|	WHEN Expenses.InvIsSubmitted OR Expenses.PrintFormLocalAccounting
	|		OR ISNULL(VATAccountingSettingsForUSN.BasicTaxation, UNDEFINED) IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|																						VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS)) THEN
	|		Expenses.SourceDocument
	|	ELSE
	|		Expenses.Ref
	|	END                                        AS DocumentAcquisitions,
	|	CASE WHEN Expenses.InvIsSubmitted OR Expenses.PrintFormLocalAccounting
	|		OR ISNULL(VATAccountingSettingsForUSN.BasicTaxation, UNDEFINED) IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|																							VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS)) THEN
	|		Expenses.SourceDocument
	|	ELSE
	|		Expenses.Ref
	|	END                                        AS OriginalTradeDocument,
	|	FALSE                                         AS ErrorCorrection,
	|	FALSE                                         AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                         AS ReduceAmountVATDeduction,
	|	UNDEFINED                                 AS PurchaseAdjustmentDocument,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATTaxation,
	|	CASE WHEN Expenses.InvIsSubmitted OR Expenses.PrintFormLocalAccounting
	|		OR ISNULL(VATAccountingSettingsForUSN.BasicTaxation, UNDEFINED) IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|																							VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS)) THEN
	|		Expenses.Ref.PurchaseForActivity
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                        AS VATActivityType,
	|	Expenses.VATRate                            AS VATRate,
	|	UNDEFINED                                 AS Products,
	|	UNDEFINED                                 AS InventoryOwnerAttribute,
	|	UNDEFINED                                 AS CCDNumber,
	|	Expenses.Department                        AS AccountingDivision,
	|	Expenses.LineOfBusiness              AS LineOfBusiness,
	|	FALSE                                         AS PurchasePerBatchOfProduction,
	|	UNDEFINED                                 AS LineOfBusinessOfProductionParty,
	|	UNDEFINED								 AS ToExpenseAs,
	|	CASE WHEN Expenses.InvIsSubmitted OR Expenses.PrintFormLocalAccounting
	|		OR ISNULL(VATAccountingSettingsForUSN.BasicTaxation, UNDEFINED) IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|																							VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS))
	|		OR &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN
	|		Expenses.ExpenseItem
	|	ELSE
	|		&ExpenseItemVATWriteOff
	|	END                                        AS ExpenseItem,
	|	CASE WHEN Expenses.InvIsSubmitted OR Expenses.PrintFormLocalAccounting
	|		OR ISNULL(VATAccountingSettingsForUSN.BasicTaxation, UNDEFINED) IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|																							VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS))
	|		OR &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN
	|		Expenses.DimensionOfExpenses
	|	ELSE
	|		&ExpenseDimensionVATWriteOff
	|	END                                        AS DimensionOfExpenses,
	|	Expenses.ExpenseItem                       AS ItemOfOtherAssets,
	|	Expenses.AssetsLiabilitiesDimension             AS AnalyticsOfOtherAssets,
	|	UNDEFINED                                 AS Purpose,
	|	Expenses.RowID                  AS RowID,
	|	Expenses.RowID                  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesOfAdvanceHolders) AS BusinessTransactionSetting
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS Expenses
	|	LEFT JOIN
	|		TTVATAccountingSettingsForUSN AS VATAccountingSettingsForUSN
	|	ON
	|		Expenses.Ref.Organization = VATAccountingSettingsForUSN.Organization
	|WHERE
	|	Expenses.Ref IN (&Ref)
	|	AND Expenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT Expenses.Canceled
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
	ValueText_ = "
	|SELECT
	|	&Period                                      AS Period,
	|	Expenses.Ref                               AS Ref,
	|	Expenses.Ref.Organization                   AS Organization,
	|	Expenses.Ref.Department                 AS Department,
	|	Expenses.Counterparty                           AS Counterparty,
	|	Expenses.Ref                               AS TaxInvoice,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	Expenses.RowID                  AS RowID,
	|	Expenses.VATRate                            AS VATRate,
	|	Expenses.Department                        AS AccountingDivision,
	|	Expenses.LineOfBusiness              AS LineOfBusiness,
	|	Expenses.ExpenseItem                       AS ExpenseItem,
	|	CASE WHEN &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN
	|		Expenses.ExpenseItem
	|	ELSE
	|		&ExpenseItemVATWriteOff
	|	END AS ExpenseItemVATWriteOff,
	|	CASE WHEN &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN
	|		Expenses.DimensionOfExpenses
	|	ELSE
	|		&ExpenseDimensionVATWriteOff
	|	END AS ExpenseDimensionVATWriteOff,
	|	Expenses.RowID                  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting
	|FROM
	|	Document.ExpenseReport.OtherExpenses AS Expenses
	|	LEFT JOIN
	|		TTVATAccountingSettingsForUSN AS VATAccountingSettingsForUSN
	|	ON
	|		Expenses.Ref.Organization = VATAccountingSettingsForUSN.Organization
	|WHERE
	|	Expenses.Ref IN (&Ref)
	|	AND Expenses.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|	AND NOT Expenses.Canceled
	|	AND NOT Expenses.InvIsSubmitted
	|	AND NOT Expenses.PrintFormLocalAccounting
	|	AND NOT ISNULL(VATAccountingSettingsForUSN.BasicTaxation, UNDEFINED) IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|																							VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS))
	|	AND NOT &WriteOffVATByExpensesThatAreNotRecordedInTA
	|";
	
	VATAccountingERP.ReflectVATDeductionForExpenses(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates

	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates =
	"SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS DocumentCurrency,
	|	Table.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.ExpenseReport.PaymentToVendors AS Table
	|		LEFT JOIN Document.ExpenseReport AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Table.Ref IN (&Ref)";

	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	#EndRegion
	
	TextPayment = "
		|SELECT
		|	Table.Ref                                                  AS Ref,
		|	Table.Ref.Organization                                      AS Organization,
		|	Table.Vendor                                               AS Partner,
		|	CASE
		|		WHEN BEGINOFPERIOD(Table.Ref.Date, DAY) = Table.Ref.ConfirmationDate THEN
		|			Table.Ref.Date
		|		ELSE
		|			Table.Ref.ConfirmationDate
		|	END                                                           AS RecorderDate,
		|	Table.Ref.Number                                            AS RecorderNumber,
		|	
		|	Table.ARAPCurrency                                    AS ARAPCurrency,
		|	Table.ARAPObject                                          AS ARAPObject,
		|	Table.Sum                                                   AS Sum,
		|	Table.AmountARAP                                     AS AmountARAP,
		|	0                                                               AS IncreaseIsPaid,
		|	0                                                               AS ReductionIsPaid,
		|	CAST(Table.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))  AS SumMan,
		|	CAST(Table.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.PaymentToVendor)   AS BusinessOperation,
		|	VALUE(Catalog.CashFlowReportItems.EmptyRef) AS CashFlowItem,
		|	UNDEFINED                                                    AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.CashAccountPayment_)                     AS PaymentMethod,
		|	Table.Currency                                                  AS DocumentCurrency,
		|	Table.Ref.Date                                             AS DateOfCourse,
		|	DATETIME(1,1,1)                                                AS MaturityDate,
		|	UNDEFINED                                                    AS LinkedDocument,
		|	Table.RowID                                     AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AdvanceHolderPaymentToVendor) AS BusinessTransactionSetting
		|FROM
		|	Document.ExpenseReport.PaymentToVendors AS Table
		|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
		|		ON TableExchangeRatesOfReportLines.RowID = Table.RowID
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
	
EndProcedure

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		QueryTextTTManExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		QueryTextTTLocalExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|//Cash Receipt on the way balance with Cash Expense from the conversion reportee
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	CASE WHEN CurrencyConversion.Currency = &LocalAccountingCurrency
	|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
	|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|	END AS CashTransferKind,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS Sender,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.AcquiringContracts.EmptyRef) AS Contract,
	|	CurrencyConversion.Currency AS Currency,
	|	
	|	CurrencyConversion.Sum AS Sum,
	|	CurrencyConversion.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS SumMan,
	|	CurrencyConversion.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS SumCompl,
	|	
	|	CurrencyConversion.CashFlowItem AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.CurrencyConversionByAdvanceHolder) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversionByAdvanceHolder) AS BusinessTransactionSetting,
	|	CurrencyConversion.RowID AS FinRecordID
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS CurrencyConversion
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|			ON TableExchangeRatesOfReportLines.RowID = CurrencyConversion.RowID
	|WHERE
	|	CurrencyConversion.Ref = &Ref
	|	AND &Multicurrency
	|	AND CurrencyConversion.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|
	|UNION ALL
	|
	|//Cash expense on the way balance with Cash Receipt from the reportee conversion
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	CASE WHEN CurrencyConversion.Currency = &LocalAccountingCurrency
	|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
	|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|	END AS CashTransferKind,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS Sender,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.AcquiringContracts.EmptyRef) AS Contract,
	|	CurrencyConversion.Currency AS Currency,
	|	
	|	CurrencyConversion.Sum AS Sum,
	|	CurrencyConversion.ConversionAmount * ISNULL(TableManExchangeRates.ConversionFactor_, 0) AS SumMan,
	|	CurrencyConversion.ConversionAmount * ISNULL(TableLocalExchangeRates.ConversionFactor_, 0) AS SumCompl,
	|	
	|	CurrencyConversion.CashFlowItem AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCurrencyConversion) AS BusinessTransactionSetting,
	|	CurrencyConversion.RowID AS FinRecordID
	|FROM
	|	Document.ExpenseReport.CurrencyConversion AS CurrencyConversion
	|		LEFT JOIN TTExchangeRatesMan AS TableManExchangeRates
	|			ON TableManExchangeRates.Currency = CurrencyConversion.CurrencyOfConversion
	|		LEFT JOIN TTExchangeRatesLocal AS TableLocalExchangeRates
	|			ON TableLocalExchangeRates.Currency = CurrencyConversion.CurrencyOfConversion
	|WHERE
	|	CurrencyConversion.Ref = &Ref
	|	AND &Multicurrency
	|	AND CurrencyConversion.Ref.Status = VALUE(Enum.ExpenseReportStatuses.Upholded)
	|
	|UNION ALL //Exchange difference balance with Other expenses/income
	|
	// Negative exchange rate differences
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	CASE WHEN TableOfExchangeDifferences.Currency = &LocalAccountingCurrency
	|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
	|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|	END AS CashTransferKind,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS Sender,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.AcquiringContracts.EmptyRef) AS Contract,
	|	TableOfExchangeDifferences.Currency AS Currency,
	|	
	|	0 AS Sum,
	|	-TableOfExchangeDifferences.SumMan AS SumMan,
	|	-TableOfExchangeDifferences.SumCompl AS SumCompl,
	|	
	|	TableOfExchangeDifferences.CashFlowItem AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss) AS BusinessTransactionSetting,
	|	TableOfExchangeDifferences.RowID AS FinRecordID
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|WHERE
	|	TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0
	|	
	|UNION ALL
	|
	// Positive exchange rate differences
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	CASE WHEN TableOfExchangeDifferences.Currency = &LocalAccountingCurrency
	|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
	|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|	END AS CashTransferKind,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS Sender,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.AcquiringContracts.EmptyRef) AS Contract,
	|	TableOfExchangeDifferences.Currency AS Currency,
	|	
	|	0 AS Sum,
	|	TableOfExchangeDifferences.SumMan AS SumMan,
	|	TableOfExchangeDifferences.SumCompl AS SumCompl,
	|	
	|	TableOfExchangeDifferences.CashFlowItem AS CashFlowItem,
	|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain) AS BusinessTransactionSetting,
	|	TableOfExchangeDifferences.RowID AS FinRecordID
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|WHERE
	|	TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	ExpenseReportLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ExpenseReport) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ExpenseReport.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ExpenseReport);
		CreateBasedOnCommand.WriteMode = "Post";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ExpenseReportLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ExpenseReportLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	ExpenseReportLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
	
EndProcedure

Function AdditionalPrintDocuments(DocumentsArray) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.ExpenseReport IN (&DocumentsArray)
	|	AND DocumentData.Posted
	|
	|";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

#EndRegion

#EndRegion

#EndIf
