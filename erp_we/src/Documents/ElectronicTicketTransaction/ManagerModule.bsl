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
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Employee";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Employee";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Department", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization, ServiceType";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "CashFlowItem", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization, BusinessOperation";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "FinancialAccountingGroup", Parameters);
	
EndProcedure

// Defines the properties of the Form fields depending on the data for the electronic ticket Form
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	
	#Region Attributes
	// Business trip request
	Item = Settings.Add();
	Item.Fields.Add("DocumentBasis");
	Finances.NewFilter(Item.Condition, "DocumentBasis",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("TextExpenseReport");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.BookingViaAdvanceHolder);
	Finances.NewFilter(Item.Condition, "More.PrintASingleExpenseReport", True);
	Item.Properties.Insert("Visible");
	
	// Attributes
	Item = Settings.Add();
	Item.Fields.Add("GroupWriteOff");
	Finances.NewFilter(Item.Condition, "DirectWriteOffMethod", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ReflectionGroupLaw");
	Finances.NewFilter(Item.Condition, "DirectWriteOffMethod", True);
	Item.Properties.Insert("Visible");
	
	
	FillInSettingsOfGeneralFormFields(Settings);
	
	#EndRegion
	
EndProcedure

// Defines the properties of form fields depending on the data
// 
// Returns:
//  See CashServer.InitializeFormFieldSettings.
//
Function SettingsOfFormFieldsForTicketOperations() Export
	
	Settings = CashServer.InitializeFormFieldSettings();
	FillInSettingsOfGeneralFormFields(Settings, True);
	
	Return Settings;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Adds a command of creation of the document "Reservation".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//    Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ElectronicTicketTransaction) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ElectronicTicketTransaction.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ElectronicTicketTransaction);
		CreateBasedOnCommand.WriteMode = "Post";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// StandardSubsystems.AccessManagement

// Fills in the text of the access restriction
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text = "AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Agent)
	|	AND ValueAllowed(Carrier)
	|";

EndProcedure
// End StandardSubsystems.AccessManagement

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("VATAccounting");
	
	BookingLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ElectronicTicketTransaction") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		FillInInitializationParameters(Query, DocumentRef);
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		BookingLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);

	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		ElectronicTicket = Common.ObjectAttributesValues(FillingData, "ElectronicTicket").BookingType;
	ElsIf FillingData = Undefined Then
		ElectronicTicket = Undefined;
	Else
		ElectronicTicket = FillingData.ElectronicTicket;
	EndIf;
	
	ThisIsElectronicTicket = Not ValueIsFilled(ElectronicTicket);
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(FillingData, "BusinessOperation");
		Operation = StructureFillingData.BusinessOperation;
	ElsIf FillingData = Undefined Then
		Operation = Undefined;
	Else
		Operation = FillingData.BusinessOperation;
	EndIf;
	
	StructuresArray = New Array;
	
	#Region SettlementsWithCarrier
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	// Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ParametersStructure.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	
	ParametersStructure.ChangesPaymentPlan = True;
	
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	
	ParametersStructure.PropsNameTSAmountWithVAT          = "Sum";
	ParametersStructure.Terms                       = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.VATTaxation               = "";
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroup";
	
	// They are used to generate calculation and analytics objects.
	ParametersStructure.Partner                          = "Object.Carrier";
	ParametersStructure.Counterparty                       = "Object.CounterpartyCarrier";
	
	ParametersStructure.Contract                          = "";
	
	If ThisIsElectronicTicket Then
		ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	Else
		ParametersStructure.ARAPObject                   = "";
	EndIf;
	
	StructuresArray.Add(ParametersStructure);
		
	#EndRegion
	
	#Region SettlementsWithCarrierOrAgentUnderContractAsWhole
	
	If Operation = Enums.BusinessTransactions.BookingViaAgent
		Or Operation = Enums.BusinessTransactions.BookingFromVendor Then
	
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		
		// Determines which register the parameters move, which common forms, enumerations and directories to use.
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		
		ParametersStructure.ARAPObjectSettings                  = Enums.ARAPObjectSettings.ByCounterpartyContracts;
		
		ParametersStructure.ChangesPaymentPlan               = True;
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		ParametersStructure.PropsNameTSAmountWithVAT          = "Sum";
		ParametersStructure.Terms                       = "";
		ParametersStructure.CompanyBankAccount        = "";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.CashAccount                            = "";
		ParametersStructure.PaymentMethod                      = "";
		ParametersStructure.ForeignCurrencyTransaction                    = "";
		ParametersStructure.PaymentID             = "";
		ParametersStructure.VATTaxation               = "";
		ParametersStructure.FinancialAccountingGroup           = "";
		
		// They are used to generate calculation and analytics objects.
		If Operation = Enums.BusinessTransactions.BookingViaAgent Then
			ParametersStructure.Partner                          = "Object.Agent";
			ParametersStructure.Counterparty                       = "Object.CounterpartyAgent";
		Else
			ParametersStructure.Partner                          = "Object.Carrier";
			ParametersStructure.Counterparty                       = "Object.CounterpartyCarrier";
		EndIf;
		
		ParametersStructure.ARAPObject                   = "Object.ARAPObjectContract";
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export 
	
	ParametersArray = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Operations";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	TypesOfOperation = New Array;
	TypesOfOperation.Add(Enums.TypesOfTicketOperations.Return);
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("OperationType", TypesOfOperation);
	
	ParametersArray.Add(ChoiceParameters);
	
	Return ParametersArray;

EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Parameters:
//  OperationType - EnumRef.TypesOfTicketOperations - Type of operation with the ticket
// 
// Returns:
//  - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ParametersForSelectingArticlesAndAnalyticsInInputForm(OperationType) Export 

	ChoiceParametersArray = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	ChoiceParameters.AvailabilityByOperation = (OperationType = Enums.TypesOfTicketOperations.Return);
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
EndFunction

// Returns an array of parameters for selecting articles and analytics.
//
// Returns:
//  -Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ParametersForSelectingArticlesAndAnalyticsForDirectWriteOff() Export 

	ChoiceParametersArray = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.ChoosingExpenseItem        = True;
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	ChoiceParameters.AssetRef                   = "ExpenseItem";
	ChoiceParameters.ArticleType                = "ArticleType";
	ChoiceParameters.DimensionOfExpenses        = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;

EndFunction

// Returns parameters for setting up document accounting accounts.
// 
// Returns:
//  See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Operations";
	SetupParameters.LedgerAccountSettingVersion = "LedgerAccountSettingVersion";
	
	Return SetupParameters;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document correction Input form.
// 
// Parameters:
// 	OperationType - EnumRef.TypesOfTicketOperations - Type of operation with the ticket
// 	
// Returns:
//  - Array of See GLAccountSettingsServer.SetupParameters - account settings.
//
Function AccountSettingsInAdjustmentEntryForm(OperationType) Export
	
	ParametersArray = New Array();
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation = (OperationType = Enums.TypesOfTicketOperations.Return);
	SetupParameters.ArticleType = "ArticleType";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Organization";

	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	
	Return ParametersArray;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document correction Input form.
// 
// Returns:
//  - Array of See GLAccountSettingsServer.SetupParameters - account settings.
//
Function AccountSettingsForDirectWriteOffMethod() Export
	
	ParametersArray = New Array();
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath           = "Object";
	SetupParameters.ArticleType             = "ArticleType";
	SetupParameters.Presentation         = "PresentationOfRecordingInComplAccounting";
	SetupParameters.Organization           = "Object.Organization";
	
	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	ParametersArray.Add(SetupParameters);
	
	Return ParametersArray;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return BookingLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return BookingLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object - DocumentObject.ElectronicTicketTransaction, FormDataStructure- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived.
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.CounterpartyCarrier;
	RegistrationParameters.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	RegistrationParameters.OtherVATConfirmationDocument = True;
	
	Return RegistrationParameters;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns a description of the order of types of operations with tickets. 
//
// Returns:
//  Map of EnumRef.TypesOfTicketOperations:
//      *Key     - EnumRef.TypesOfTicketOperations - type of operation,
//      *Value - Number - The order of the operation type.
//
Function OrderOfOfOperationsTypes() Export
	
	OrderOfOfOperationsTypes = New Map;
	OrderOfOfOperationsTypes.Insert(Enums.TypesOfTicketOperations.Return,2);
	OrderOfOfOperationsTypes.Insert(Enums.TypesOfTicketOperations.ExtraPay,1);
	OrderOfOfOperationsTypes.Insert(Enums.TypesOfTicketOperations.Purchase,0);
	Return OrderOfOfOperationsTypes;
	
EndFunction

// Returns parameters for filling in the VAT activity type
//
// Parameters:
//  Document - DocumentRef.ElectronicTicketTransaction, FormDataStructureAndCollection - data based on which
//                                                                            the filling parameters will be generated.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	Attributes = New Structure("ArrivalDate, Organization");
	
	If TypeOf(Document) = Type("DocumentRef.ElectronicTicketTransaction") Then
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else
		FillPropertyValues(Attributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date = Attributes.ArrivalDate;
	FillParameters.Organization = Attributes.Organization;
	
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// Returns the names of the key Attributes of the electronic ticket that the event depends on
//
// Parameters:
//  ForSynchronization - Boolean - indicates whether to get the names of all Attributes that affect the result of the event
//  AttributesToExclude - Arbitrary, Array of String - array of Attributes that will be excluded from the result.
//
// Returns:
//  Array of String
//
Function KeyDetailsOfElectronicTicket(ForSynchronization = True, AttributesToExclude = Undefined) Export
	
	KeyAttributes = New Array;
	
	KeyAttributes.Add("BusinessOperation");
	KeyAttributes.Add("Organization");
	KeyAttributes.Add("Department");
	KeyAttributes.Add("LineOfBusiness");
	KeyAttributes.Add("Agent");
	KeyAttributes.Add("CounterpartyAgent");
	KeyAttributes.Add("Carrier");
	KeyAttributes.Add("CounterpartyCarrier");
	KeyAttributes.Add("Contract");
	KeyAttributes.Add("AdvanceHolder");
	KeyAttributes.Add("AccountablePersonDepartment");
	KeyAttributes.Add("Employee");
	KeyAttributes.Add("Currency");
	KeyAttributes.Add("PostingDate");
	KeyAttributes.Add("ArrivalDate");
	KeyAttributes.Add("BusinessUnitWriteOffs");
	KeyAttributes.Add("LineOfBusinessForWriteOff");
	KeyAttributes.Add("ExpenseItem");
	KeyAttributes.Add("DimensionOfExpenses");
	KeyAttributes.Add("AssetsLiabilitiesDimension");
	KeyAttributes.Add("GLAccountSettings");
	KeyAttributes.Add("FinancialAccountingGroup");
	KeyAttributes.Add("DirectWriteOffMethod");
	KeyAttributes.Add("PurchaseForActivity");
	KeyAttributes.Add("AcceptVATForDeduction");
	KeyAttributes.Add("TransactionKindCode");
	KeyAttributes.Add("ARAPObject");
	KeyAttributes.Add("ARAPObjectContract");
	KeyAttributes.Add("CashFlowItem");
	KeyAttributes.Add("TicketNumber");
	KeyAttributes.Add("ServiceType");
	KeyAttributes.Add("Date");
	KeyAttributes.Add("ExpenseReport");
	
	If ForSynchronization Then
		KeyAttributes.Add("DeletionMark");
		KeyAttributes.Add("Posted");
	EndIf;
	
	If AttributesToExclude <> Undefined Then
		Return CommonClientServer.ArraysDifference(KeyAttributes, AttributesToExclude);
	EndIf;
	
	Return KeyAttributes;
	
EndFunction

// Returns a table with e-ticket operations
//
// Parameters:
//  ElectronicTicket - DocumentRef.ElectronicTicketTransaction - Link To The E-Ticket
//  ReferencesOfOperations - Arbitrary, Array of DocumentRef.ElectronicTicketTransaction - an array of documentsof operations
//                     for which you want to get up-to-date data.
//  ExcludingOfOperations - Arbitrary, Array of DocumentRef.ElectronicTicketTransaction - an array of documentsof operations
//                     that you want to exclude.
//  IncludePurchaseOperations - Boolean - indicates whether the purchase of operations is included in the table.
//
// Returns:
//  - ValueTable:
//    *RowID - String - row ID
//    *Date - Date - Transaction date
//    *Operation - DocumentRef.ElectronicTicketTransaction - link to the documentof operation
//    *Sum - Number - amount of operation
//    *CalculatedAmount - Number - amount of operation that takes into account the refund amount in negative terms
//    *VATRate - CatalogRef.VATRates - the VAT rate at which the transaction is taxed of operation
//    *VATAmount - Number - Transaction VAT amount
//    *AmountOfPenalty - Number - the amount of the refund penalty
//    *Comment - String - comment of operation
//    *OperationType - EnumRef.TypesOfTicketOperations - type of operation
//    *ThisIsCurrentETicket - Boolean - a sign that determines the presence of operation
//                                           in the table of the current electronic ticket.
//                                           It is typical for electronic tickets
//                                           that are not divided into several documents of operations.
//    *AmountForIssue - Number - the amount to issue.
//
Function ElectronicTicketOperations(ElectronicTicket, ReferencesOfOperations = Undefined, ExcludingOfOperations = Undefined, IncludePurchaseOperations = False) Export
	
	Query = New Query;
	Query.SetParameter("ElectronicTicket", ElectronicTicket);
	Query.SetParameter("SelectByOperations", ValueIsFilled(ReferencesOfOperations));
	Query.SetParameter("ReferencesOfOperations", ReferencesOfOperations);
	Query.SetParameter("ExcludedTransactions", ExcludingOfOperations);
	Query.SetParameter("IncludePurchaseOperations", IncludePurchaseOperations);
	
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN ElectronicTicketTransaction.Posted
	|				AND ElectronicTicketTransaction.DeletionMark
	|			THEN 3
	|		WHEN ElectronicTicketTransaction.DeletionMark
	|			THEN 2
	|		WHEN ElectronicTicketTransaction.Posted
	|			THEN 1
	|		ELSE 0
	|	END AS PictureIndex,
	|	ElectronicTicketTransaction.DeletionMark AS DeletionMark,
	|	ElectronicTicketTransaction.Posted AS Posted,
	|	LinesOfOperations.RowID AS RowID,
	|	ElectronicTicketTransaction.Ref AS Ref,
	|	LinesOfOperations.Date AS Date,
	|	ElectronicTicketTransaction.Ref = &ElectronicTicket AS ThisIsCurrentETicket,
	|	LinesOfOperations.OperationType AS OperationType,
	|	LinesOfOperations.Sum AS Sum,
	|	LinesOfOperations.VATRate AS VATRate,
	|	LinesOfOperations.VATAmount AS VATAmount,
	|	LinesOfOperations.PenaltyAmount AS PenaltyAmount,
	|	CASE
	|		WHEN LinesOfOperations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|			THEN -Sum
	|		ELSE Sum
	|	END AS CalculatedAmount,
	|	CASE
	|		WHEN LinesOfOperations.LineNumber = 1
	|			THEN ElectronicTicketTransaction.Comment
	|		ELSE """"
	|	END AS Comment,
	|	CASE
	|		WHEN LinesOfOperations.OperationType = VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|			THEN 1
	|		ELSE 2
	|	END AS OperationProcedure,
	|	CASE
	|		WHEN LinesOfOperations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|			THEN -LinesOfOperations.Sum
	|		ELSE LinesOfOperations.Sum
	|	END AS AmountForIssue,
	|	ElectronicTicketTransaction.State AS State,
	|	ElectronicTicketTransaction.TicketNumber AS TicketNumber,
	|	ElectronicTicketTransaction.ServiceType AS ServiceType
	|FROM
	|	Document.ElectronicTicketTransaction AS ElectronicTicketTransaction
	|		LEFT JOIN Document.ElectronicTicketTransaction.Operations AS LinesOfOperations
	|		ON ElectronicTicketTransaction.Ref = LinesOfOperations.Ref
	|WHERE
	|	((ElectronicTicketTransaction.ElectronicTicket = &ElectronicTicket
	|				OR ElectronicTicketTransaction.Ref = &ElectronicTicket
	|				AND (NOT LinesOfOperations.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase)
	|					OR &IncludePurchaseOperations))
	|
	|	AND NOT &SelectByOperations
	|		OR ElectronicTicketTransaction.Ref IN (&ReferencesOfOperations))
	|
	|	AND NOT ElectronicTicketTransaction.Ref IN (&ExcludedTransactions)";
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the Attributes required for entering the fine
//
// Returns:
//  - String - Attribute names separated by ",".
//
Function DetailsOfEnteringFine() Export
	
	AttributesList = New Array;
	AttributesList.Add("OperationType");
	AttributesList.Add("Date");
	AttributesList.Add("PenaltyAmount");
	AttributesList.Add("ExpenseItem");
	AttributesList.Add("DimensionOfExpenses");
	AttributesList.Add("AssetsLiabilitiesDimension");
	AttributesList.Add("Department");
	AttributesList.Add("LineOfBusiness");
	AttributesList.Add("GLAccountSettings");
	
	Return StrConcat(AttributesList, ",");
	
EndFunction

// Returns a flag that determines whether the electronic ticket contains such types of operations as "Surcharge" and "Refund"
//
// Parameters:
//  Object - DocumentObject.ElectronicTicketTransaction, FormDataStructureAndCollection - verifiable e-ticket
//
// Returns:
// - Boolean
//
Function ElectronicTicketContainsOfOperationsLines(Object) Export
	
	CompositionOfOperations = Object.Operations.Unload();
	CompositionOfOperations.GroupBy("OperationType");
	Return CompositionOfOperations.Count() > 1;
	
EndFunction

// Initializes the data for creating the ticket of operation.
//
// Returns:
// - Structure:
//    *ETicketData - Undefined,
//                                Data Formstructure Collection, document object.Electronic ticket operation - data
//                                of the electronic ticket for which the operation is being created.
//    *OperationDescription - Structure:
//     **OperationType - EnumRef.TypesOfTicketOperations - the type of operation of the ticket.
//     **ThisIsFullReturn - Boolean - indicates a full refund.
//     **SmartwayVersionID - Number - ID of the smartway version to integrate with the service.
//     **Date - Date - Transaction date.
//    *ThisIsTicketSplit - Boolean - indicates that the ticket is divided of operations into documents.
//
Function DataForCreatingTicketOperation() Export
	
	OperationDescription = New Structure;
	OperationDescription.Insert("OperationType", Enums.TypesOfTicketOperations.ExtraPay);
	OperationDescription.Insert("ThisIsFullReturn", False);
	OperationDescription.Insert("SmartwayVersionID", 0);
	OperationDescription.Insert("Date");
	
	DataForCreatingTicketOperation = New Structure;
	DataForCreatingTicketOperation.Insert("ETicketData", Undefined);
	DataForCreatingTicketOperation.Insert("OperationDescription", OperationDescription);
	DataForCreatingTicketOperation.Insert("ThisIsTicketSplit", False);
	
	Return DataForCreatingTicketOperation;
	
EndFunction

// Returns the State of the electronic ticket.
//
// Parameters:
//  ElectronicTicket - DocumentRef.ElectronicTicketTransaction - link to the electronic ticket for which the State is calculated.
//  CurrentTicketData - DocumentObject.ElectronicTicketTransaction - data of a modified but not yet recorded electronic ticket.
//
// Returns:
// - String
//
Function NewStateOfTicket(ElectronicTicket, CurrentTicketData = Undefined) Export
	
	DefaultState = NStr("vi = 'Đã mua';
						|ru = 'Куплен';
						|en = 'Purchased'; fa = 'خریداری‌شده';
						|it = 'Purchased';
						|pl = 'Purchased';
						|tr = 'Satın alındı'");
	If Not ValueIsFilled(ElectronicTicket) Then
		Return DefaultState;
	EndIf;
	
	ElectronicTicketOperations = ElectronicTicketOperations(ElectronicTicket,,, True);
	
	AmountThatDeterminesState = 0;
	If Not CurrentTicketData = Undefined Then
		LinesOfCurrentOperation = ElectronicTicketOperations.FindRows(New Structure("Ref", ElectronicTicket));
		For Each CurrentRow In LinesOfCurrentOperation Do
			CurrentRow.AmountForIssue = 0;
		EndDo;
		AmountThatDeterminesState = ?(CurrentTicketData.DeletionMark, 0, CurrentTicketData.AmountForIssue);
	EndIf;
	
	DataForCalculatingAmountToBeIssued = ElectronicTicketOperations.Copy(New Structure("DeletionMark", False), "AmountForIssue");
	DataForCalculatingAmountToBeIssued.GroupBy(,"AmountForIssue");
	
	If DataForCalculatingAmountToBeIssued.Count() Then
		AmountThatDeterminesState = AmountThatDeterminesState + DataForCalculatingAmountToBeIssued[0].AmountForIssue;
	EndIf;
	
	FilterOfOperationsSurcharges = New Structure("DeletionMark, OperationType", False, Enums.TypesOfTicketOperations.ExtraPay);
	FilterOfOperationsOfReturn = New Structure("DeletionMark, OperationType", False, Enums.TypesOfTicketOperations.Return);
	
	If ElectronicTicketOperations.FindRows(FilterOfOperationsOfReturn).Count()
			And AmountThatDeterminesState <= 0 Then
		Return NStr("vi = 'Đã hoàn trả';
					|ru = 'Возвращен';
					|en = 'Returned'; fa = 'برگشتی';
					|it = 'Returned';
					|pl = 'Returned';
					|tr = 'İade edildi'");
	EndIf;
	
	If ElectronicTicketOperations.FindRows(FilterOfOperationsSurcharges).Count() Then
		Return NStr("vi = 'Có phụ phí';
					|ru = 'С доплатой';
					|en = 'With additional payment'; fa = 'With additional payment';
					|it = 'Con supplemento';
					|pl = 'Z dopłatą';
					|tr = 'Ek ödeme ile'");
	EndIf;
	
	Return DefaultState;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	If Not FormType = "DocumentForm"
		And Not FormType = "ObjectForm" Then
		Return;
	EndIf;
	
	Value = CommonClientServer.StructureProperty(Parameters, "Key");
	
	// Copy check
	If Value = Undefined Then
		Value = CommonClientServer.StructureProperty(Parameters, "CopyingValue");
	EndIf;
		
	If Value = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	If ValueIsFilled(Value.OperationType) Then
		SelectedForm = "ElectronicTicketTransactionForm";
	Else
		SelectedForm = "DocumentForm";
	EndIf;
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("TicketNumber");
	Fields.Add("Date");
	Fields.Add("OperationType");
	Fields.Add("ServiceType");
	Fields.Add("ElectronicTicket");
	Fields.Add("TicketDate");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Data.OperationType) Then
		Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
										|ru = '%1 %2 от %3';
										|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
										|it = '%1 %2 del %3';
										|pl = '%1 %2 z dnia %3';
										|tr = '%3 tarihli %1 %2'"), Data.ServiceType, Data.TicketNumber, Data.Date);
	Else
		Presentation = StrTemplate(
			NStr("vi = '%1 theo vé điện tử %2 %3 ngày %4';
				|ru = '%1 по электронному билету %2 %3 от %4';
				|en = '%1 by electronic ticket %2 %3 dated %4'; fa = '%1 by electronic ticket %2 %3 dated %4';
				|it = '%1 by electronic ticket %2 %3 dated %4';
				|pl = '%1 by electronic ticket %2 %3 dated %4';
				|tr = '%4 tarihli,  %2 %3numaralı elektronik bilet için %1'"),
			String(Data.OperationType),
			String(Data.ServiceType),
			Data.TicketNumber,
			Data.TicketDate);
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Date                                     AS Period,
	|	DocumentData.BusinessOperation                    AS BusinessOperation,
	|	DocumentData.ArrivalDate                             AS ArrivalDate,
	|	DocumentData.Organization                              AS Organization,
	|	DocumentData.Department                            AS Department,
	|	DocumentData.Employee                                AS Employee,
	|	DocumentData.AdvanceHolder                          AS AdvanceHolder,
	|	DocumentData.AccountablePersonDepartment            AS AccountablePersonDepartment,
	|	DocumentData.CounterpartyAgent                          AS CounterpartyAgent,
	|	DocumentData.Agent                                    AS Agent,
	|	DocumentData.CounterpartyCarrier                     AS CounterpartyCarrier,
	|	DocumentData.Carrier                               AS Carrier,
	|	DocumentData.Contract                                  AS Contract,
	|	DocumentData.Currency                                   AS Currency,
	|	DocumentData.CashFlowItem            AS CashFlowItem,
	|	DocumentData.ExpenseReport                           AS ExpenseReport,
	|
	|	DocumentData.TicketNumber                              AS Number,
	|	DocumentData.Comment                              AS Comment,
	|	DocumentData.Posted                                 AS Posted,
	|	DocumentData.DeletionMark                          AS DeletionMark,
	|	DocumentData.DocumentAmount                           AS DocumentAmount,
	|	DocumentData.AmountForIssue                             AS AmountForIssue,
	|	DocumentData.EmployeeResponsible                            AS EmployeeResponsible,
	|	DocumentData.AcceptVATForDeduction                        AS AcceptVATForDeduction,
	|	DocumentData.ManualAdjustmentOfTaxInvoiceRegister             AS ManualAdjustmentOfTaxInvoiceRegister,
	|	DocumentData.PurchaseForActivity                   AS PurchaseForActivity,
	|	DocumentData.DirectWriteOffMethod                   AS DirectWriteOffMethod,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BusinessTransactionsSettings.Ref                    AS BusinessTransactionSetting,
	|	DocumentData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef) AS ThisIsElectronicTicket,
	|	CASE
	|		WHEN DocumentData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|			THEN DocumentData.Ref
	|		ELSE DocumentData.ElectronicTicket
	|	END AS ElectronicTicket
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
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
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	Query.SetParameter("DateOfRemainingGoods", New Boundary(DocumentRef.PointInTime(), BoundaryType.Excluding));
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ElectronicTicketTransaction";
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("ThisIsElectronicTicket",
		"DocumentData.ElectronicTicket = Value(Document.ElectronicTicketTransaction.EmptyRef)");
	
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
			QueryText, FullDocumentName, SynonymForDocumentTable, True, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.ElectronicTicketTransaction"));
	Values.Insert("ControlIssueOfCashByPurposes",       GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses",           GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("UseAccountingOfOtherAssetsAndLiabilities",           GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	Values.Insert("IDOfUnusedFinRecord",            DocumentsPosting.IDOfUnusedFinRecord());
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	Values.Insert("ManagementAccountingCurrency", CurrencyOfMan);
	Values.Insert("CurrencyOfMan", CurrencyOfMan);
	
	If Attributes <> Undefined Then
		
		Values.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Attributes.Currency, Attributes.Period, Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		
		Values.Insert("NumberForPrinting",       ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|		THEN &Agent
	|		ELSE &Carrier
	|	END                                   AS Partner,
	|	&Employee                              AS StorageLocation,
	|	CASE &BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN &AdvanceHolder
	|		WHEN VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|			THEN &CounterpartyAgent
	|		WHEN VALUE(Enum.BusinessTransactions.BookingFromVendor)
	|			THEN &CounterpartyCarrier
	|	END                                   AS Counterparty,
	|	
	|	&Department                          AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	|	
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&Number                            AS SourceDocumentNumber,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	&Contract                                AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DocumentData.DeleteBookingType = VALUE(Enum.DeleteBookingTypes.Booking)
	|
	|UNION ALL
	|
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	VALUE(Enum.BusinessTransactions.IncomingVATOnAcquisition) AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|		THEN &Agent
	|		ELSE &Carrier
	|	END                                   AS Partner,
	|	&Employee                              AS StorageLocation,
	|	CASE &BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN &AdvanceHolder
	|		WHEN VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|			THEN &CounterpartyAgent
	|		WHEN VALUE(Enum.BusinessTransactions.BookingFromVendor)
	|			THEN &CounterpartyCarrier
	|	END                                   AS Counterparty,
	|	
	|	&Department                          AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	|	
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	TRUE                                  AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&Number                                  AS SourceDocumentNumber,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	&Contract                                AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &AcceptVATForDeduction
	|	AND &ThisIsElectronicTicket
	|	AND NOT DocumentData.DeleteBookingType = VALUE(Enum.DeleteBookingTypes.Booking)
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT // Attribution of the ticket amount to the advance payment by the arrival date
	|	CASE
	|		WHEN &Period > &ArrivalDate
	|			AND &Period > DocumentData.Date
	|			THEN &Period
	|		WHEN DocumentData.Date > &ArrivalDate
	|			THEN DocumentData.Date
	|		ELSE &ArrivalDate
	|	END                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Employee                             AS AdvanceHolder,
	|	&Department                         AS Department,
	|	&Currency                                AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	DocumentData.Sum                  AS Sum,
	|	CASE WHEN (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan) = 0 
	|		THEN 0
	|		ELSE DocumentData.Sum * Coefficients.CourseNumerator * Coefficients.CourseDenominatorMan 
	|			/ (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan)
	|	END AS SumMan,
	|	CASE WHEN Coefficients.CourseDenominator = 0 
	|		THEN 0
	|		ELSE DocumentData.Sum * Coefficients.CourseNumerator  / Coefficients.CourseDenominator
	|	END AS SumCompl,
	|	DocumentData.Sum                  AS ToReport,
	|	0                                      AS PurchaseAmount,
	|	
	|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolder) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.Ref.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.UseBookingByAdvanceHolder) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT &DirectWriteOffMethod
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL
	|
	|SELECT // The reverse of attributing the amount of the ticket to the advance payment by the date of arrival
	|	CASE
	|		WHEN &Period > &ArrivalDate
	|			AND &Period > DocumentData.Date
	|			THEN &Period
	|		WHEN DocumentData.Date > &ArrivalDate
	|			THEN DocumentData.Date
	|		ELSE &ArrivalDate
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Employee                             AS AdvanceHolder,
	|	&Department                         AS Department,
	|	&Currency                                AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	-DocumentData.Sum                 AS Sum,
	|	CASE WHEN (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan) = 0 
	|		THEN 0
	|		ELSE -DocumentData.Sum * Coefficients.CourseNumerator * Coefficients.CourseDenominatorMan 
	|			/ (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan)
	|	END AS SumMan,
	|	CASE WHEN Coefficients.CourseDenominator = 0 
	|		THEN 0
	|		ELSE -DocumentData.Sum * Coefficients.CourseNumerator  / Coefficients.CourseDenominator
	|	END AS SumCompl,
	|	-DocumentData.Sum                 AS ToReport,
	|	0                                      AS PurchaseAmount,
	|	
	|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolderStorno) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.UseBookingByAdvanceHolderStorno) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Date = DocumentData.Date
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT &DirectWriteOffMethod
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|	
	|UNION ALL
	|	
	|SELECT // Purchase via advance holder
	|	CASE
	|		WHEN DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase) THEN
	|			&Period
	|		ELSE
	|			DocumentData.Date
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&AccountablePersonDepartment         AS Department,
	|	&Currency                                AS Currency,
	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	DocumentData.Sum                  AS Sum,
	|	DocumentData.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS SumMan,
	|	DocumentData.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS SumCompl,
	|	DocumentData.Sum                  AS ToReport,
	|	0                                      AS PurchaseAmount,
	|	
	|	VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.RowID    AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		
	|		INNER JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentData.RowID
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|	
	|UNION ALL
	|	
	|SELECT // Purchase via advance holder
	|	CASE
	|		WHEN DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase) THEN
	|			&Period
	|		ELSE
	|			DocumentData.Date
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&AccountablePersonDepartment         AS Department,
	|	&Currency                                AS Currency,
	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	DocumentData.Sum                  AS Sum,
	|	CASE WHEN (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan) = 0 
	|		THEN 0
	|		ELSE DocumentData.Sum * Coefficients.CourseNumerator * Coefficients.CourseDenominatorMan 
	|			/ (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan)
	|	END AS SumMan,
	|	CASE WHEN Coefficients.CourseDenominator = 0 
	|		THEN 0
	|		ELSE DocumentData.Sum * Coefficients.CourseNumerator  / Coefficients.CourseDenominator
	|	END AS SumCompl,
	|	DocumentData.Sum                  AS ToReport,
	|	0                                      AS PurchaseAmount,
	|	
	|	VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.RowID    AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentData.RowID
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|	AND TableExchangeRatesOfReportLines.RowID IS NULL
	|	
	|UNION ALL
	|	
	|SELECT // Purchase via advance holder
	|	CASE
	|		WHEN DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase) THEN
	|			&Period
	|		ELSE
	|			DocumentData.Date
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&AccountablePersonDepartment         AS Department,
	|	&Currency                                AS Currency,
	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	0                                      AS Sum,
	|	0                                      AS SumMan,
	|	0                                      AS SumCompl,
	|	0                                      AS ToReport,
	|	DocumentData.Sum                  AS PurchaseAmount,
	|	
	|	VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|	AND &ExpenseReport = VALUE(Document.ExpenseReport.EmptyRef)
	|
	|UNION ALL
	|	
	|SELECT // Refund when purchasing through an accountable person
	|	DocumentData.Date                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&AccountablePersonDepartment         AS Department,
	|	&Currency                                AS Currency,
	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	DocumentData.Sum                  AS Sum,
	|	CASE WHEN (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan) = 0 
	|		THEN 0
	|		ELSE DocumentData.Sum * Coefficients.CourseNumerator * Coefficients.CourseDenominatorMan 
	|			/ (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan)
	|	END AS SumMan,
	|	CASE WHEN Coefficients.CourseDenominator = 0 
	|		THEN 0
	|		ELSE DocumentData.Sum * Coefficients.CourseNumerator  / Coefficients.CourseDenominator
	|	END AS SumCompl,
	|	DocumentData.Sum                  AS ToReport,
	|	CASE WHEN &ExpenseReport = VALUE(Document.ExpenseReport.EmptyRef)
	|		THEN -DocumentData.Sum
	|		ELSE 0
	|	END AS PurchaseAmount,
	|	VALUE(Enum.BusinessTransactions.RefundOfAdvanceHolderBooking) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.RowID    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RefundOfAdvanceHolderBooking) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Date = DocumentData.Date
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|
	|UNION ALL
	|	
	|SELECT // Penalty
	|	DocumentData.Date                   AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&AccountablePersonDepartment         AS Department,
	|	&Currency                                AS Currency,
	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	DocumentData.PenaltyAmount            AS Sum,
	|	CASE WHEN (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan) = 0 
	|		THEN 0
	|		ELSE DocumentData.PenaltyAmount * Coefficients.CourseNumerator * Coefficients.CourseDenominatorMan 
	|			/ (Coefficients.CourseDenominator * Coefficients.CourseNumeratorMan)
	|	END AS SumMan,
	|	CASE WHEN Coefficients.CourseDenominator = 0 
	|		THEN 0
	|		ELSE DocumentData.PenaltyAmount * Coefficients.CourseNumerator  / Coefficients.CourseDenominator
	|	END AS SumCompl,
	|	DocumentData.PenaltyAmount            AS ToReport,
	|	0                                      AS PurchaseAmount,
	|	
	|	VALUE(Enum.BusinessTransactions.PenaltiesForReturningBookingOfAccountablePerson) AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|
	|	DocumentData.RowID    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturningBookingOfAccountablePerson) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS Coefficients
	|		ON Coefficients.Date = DocumentData.Date
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|	AND DocumentData.PenaltyAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTTCurrencyConversionFactors(Query, QueryTexts)
	
	RegisterName = "TTCurrencyConversionFactors";
	
	QueryText = 
	"SELECT
	|	PeriodsTable.Date AS Date,
	|	PeriodsTable.ARAPCurrency AS ARAPCurrency
	|INTO PeriodsTable
	|FROM
	|	(SELECT
	|		DocumentData.Date AS Date,
	|		DocumentData.Ref.Currency AS ARAPCurrency
	|	FROM
	|		Document.ElectronicTicketTransaction.Operations AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.ArrivalDate,
	|		DocumentData.Currency
	|	FROM
	|		Document.ElectronicTicketTransaction AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|) AS PeriodsTable
	|
	|GROUP BY
	|	PeriodsTable.Date,
	|	PeriodsTable.ARAPCurrency";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates

	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates =
	"SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	OperationTable.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS OperationTable
	|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentDataHeader
	|		ON OperationTable.Ref = DocumentDataHeader.Ref
	|WHERE
	|	OperationTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	OperationTable.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObjectContract AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS OperationTable
	|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentDataHeader
	|		ON OperationTable.Ref = DocumentDataHeader.Ref
	|WHERE
	|	OperationTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	CASE
	|		WHEN DocumentDataHeader.ArrivalDate < OperationTable.Date
	|			THEN OperationTable.Date
	|		ELSE DocumentDataHeader.ArrivalDate
	|	END AS DateOfCourse,
	|	DocumentDataHeader.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS OperationTable
	|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentDataHeader
	|		ON OperationTable.Ref = DocumentDataHeader.Ref
	|WHERE
	|	OperationTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObjectContract AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentDataHeader
	|WHERE
	|	DocumentDataHeader.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentDataHeader
	|WHERE
	|	DocumentDataHeader.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.ArrivalDate AS DateOfCourse,
	|	DocumentDataHeader.ARAPObjectContract AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS OperationTable
	|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentDataHeader
	|		ON OperationTable.Ref = DocumentDataHeader.Ref
	|WHERE
	|	OperationTable.Ref IN (&Ref)
	|	AND &DirectWriteOffMethod";
	
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);

	#EndRegion
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	#Region CarrierSIndebtednessOnTicketIsIndebtednessToCarrierAgentByDateOfTicket
	
	//For a correct double entry, the debt to the carrier or agent under the Contract is linked to the carrier's debt on the ticket
	TextTransferOfCalculations = "
		|SELECT
		|	DocumentData.Ref                                                 AS Ref,
		|
		|	DocumentData.Ref.Organization                                     AS Organization,
		|	DocumentData.Ref.ARAPObjectContract                           AS CalculationObjectSource,
		|	DocumentData.Ref.ARAPObject                                  AS CalculationObjectReceiver,
		|	
		|	DocumentData.Sum                                                  AS Sum,
		|	DocumentData.Ref.Currency                                          AS DocumentCurrency,
		|	DocumentData.Sum                                                  AS AmountARAP,
		|	DocumentData.Ref.Currency                                          AS ARAPCurrency,
		|	CASE
		|		WHEN DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase) THEN
		|			DocumentData.Ref.Date
		|		ELSE
		|			DocumentData.Date
		|	END                                                                  AS RecorderDate,
		|	DocumentData.Ref.Number                                           AS RecorderNumber,
		|	DocumentData.Ref.BusinessOperation                           AS BusinessOperation,
		|	DocumentData.Date                                                   AS PaymentDate,
		|	DocumentData.Date                                                   AS DateOfCourse,
		|	DocumentData.RowID                                    AS FinRecordID,
		|	BusinessTransactionsSettings.Ref                                  AS BusinessTransactionSetting,
		|	UNDEFINED                                                           AS CashFlowItem
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.Ref.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND DocumentData.Ref.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.BookingViaAgent),
		|		VALUE(Enum.BusinessTransactions.BookingFromVendor)
		|	)
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Purchase),
		|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
		|	)
		|	
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutTransferOfAdvancePaymentToSupplier(Query, QueryTexts, Registers, TextTransferOfCalculations);
	
	#EndRegion
	
	#Region CarrierSIndebtednessWhenBuyingThroughAccountablePersonByDateOfTicket
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	SupplierText = "
		|SELECT
		|	DocumentData.Ref                                                 AS Ref,
		|	CASE
		|		WHEN DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Purchase) THEN
		|			DocumentData.Ref.Date
		|		ELSE
		|			DocumentData.Date
		|	END                                                                  AS RecorderDate,
		|	DocumentData.Ref.Number                                           AS RecorderNumber,
		|
		|	DocumentData.Ref.Organization                                     AS Organization,
		|	DocumentData.Ref.Carrier                                      AS Partner,
		|
		|	DocumentData.Ref.ARAPObject                                  AS ARAPObject,
		|	DocumentData.Ref.Currency                                          AS ARAPCurrency,
		|	DocumentData.Sum                                                  AS Sum,
		|	DocumentData.Sum                                                  AS AmountARAP,
		|	0                                                                      AS ReductionIsPaid,
		|	0                                                                      AS IncreaseIsPaid,
		|	CAST(DocumentData.Sum * ISNULL(TableExchangeRatesOfReportLines.ManConversionFactor, 0) AS NUMBER(31,2)) AS SumMan,
		|	CAST(DocumentData.Sum * ISNULL(TableExchangeRatesOfReportLines.LocalConversionRatio, 0) AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.Ref.BusinessOperation                           AS BusinessOperation,
		|	DocumentData.Ref.CashFlowItem                   AS CashFlowItem,
		|	UNDEFINED                                                           AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                         AS PaymentMethod,
		|	DocumentData.Ref.Currency                                          AS DocumentCurrency,
		|	DocumentData.Date                                                   AS DateOfCourse,
		|	DocumentData.Date                                                   AS MaturityDate,
		|	UNDEFINED                                                           AS LinkedDocument,
		|	CASE
		|		WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
		|			THEN DocumentData.RowID
		|		ELSE DocumentData.Ref.ARAPObjectContract.UUID
		|	END                                                                  AS FinRecordID,
		|	BusinessTransactionsSettings.Ref                                  AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.Ref.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
		|		ON TableExchangeRatesOfReportLines.RowID = DocumentData.RowID
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Purchase),
		|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
		|	)
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, SupplierText);
	
	#EndRegion
	
	#Region UseOfBookingByArrivalDate
	
	TextPurchase = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	DocumentData.Ref.Organization                                  AS Organization,
		|	DocumentData.Ref.Carrier                                   AS Partner,
		|	CASE
		|		WHEN DocumentData.Ref.Date > DocumentData.Ref.ArrivalDate
		|			AND DocumentData.Ref.Date > DocumentData.Date
		|			THEN DocumentData.Ref.Date
		|		WHEN DocumentData.Date > DocumentData.Ref.ArrivalDate
		|			THEN DocumentData.Date
		|		ELSE DocumentData.Ref.ArrivalDate
		|	END                                                               AS RecorderDate,
		|	DocumentData.Ref.Number                                        AS RecorderNumber,
		|
		|	DocumentData.Ref.ARAPObject                               AS ARAPObject,
		|	CASE
		|		WHEN DocumentData.Ref.Date > DocumentData.Ref.ArrivalDate
		|			AND DocumentData.Ref.Date > DocumentData.Date
		|			THEN DocumentData.Ref.Date
		|		WHEN DocumentData.Date > DocumentData.Ref.ArrivalDate
		|			THEN DocumentData.Date
		|		ELSE DocumentData.Ref.ArrivalDate
		|	END                                                               AS PaymentDate,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	DocumentData.Sum                                               AS Sum,
		|	DocumentData.Sum                                               AS AmountARAP,
		|	0                                                                   AS AmountARAPByPackage,
		|	0                                                                   AS ToReceive,
		|
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)                  AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	DocumentData.Ref.Currency                                       AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolder) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                      AS PaymentMethod,
		|	DocumentData.Ref.Currency                                       AS DocumentCurrency,
		|	DocumentData.Date                                                AS DateOfCourse,
		|	UNDEFINED                                                        AS LinkedDocument,
		|	""""                                                                AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.UseBookingByAdvanceHolder) AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND NOT &DirectWriteOffMethod
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Purchase),
		|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
		|	)";
	
	TextPaymentPlan_ = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	DocumentData.Ref.Organization                                  AS Organization,
		|	DocumentData.Ref.Carrier                                   AS Partner,
		|	CASE
		|		WHEN DocumentData.Ref.Date > DocumentData.Ref.ArrivalDate
		|			AND DocumentData.Ref.Date > DocumentData.Date
		|			THEN DocumentData.Ref.Date
		|		WHEN DocumentData.Date > DocumentData.Ref.ArrivalDate
		|			THEN DocumentData.Date
		|		ELSE DocumentData.Ref.ArrivalDate
		|	END                                                               AS RecorderDate,
		|	DocumentData.Ref.Number                                        AS RecorderNumber,
		|	CASE
		|		WHEN DocumentData.Ref.Date > DocumentData.Ref.ArrivalDate
		|			AND DocumentData.Ref.Date > DocumentData.Date
		|			THEN DocumentData.Ref.Date
		|		WHEN DocumentData.Date > DocumentData.Ref.ArrivalDate
		|			THEN DocumentData.Date
		|		ELSE DocumentData.Ref.ArrivalDate
		|	END                                                               AS PaymentDate,
		|	
		|	DocumentData.Ref.ARAPObject                               AS ARAPObject,
		|	
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)                  AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	FALSE                                                                AS ExceedingOrder,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	DocumentData.Sum                                               AS AmountDue,
		|	DocumentData.Ref.Currency                                       AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolder) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                      AS PaymentMethod,
		|	DocumentData.Ref.Currency                                       AS DocumentCurrency,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS LinkedDocument,
		|	""""                                                                AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.UseBookingByAdvanceHolder) AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND NOT &DirectWriteOffMethod
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Purchase),
		|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
		|	)";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_);
	
	#EndRegion

	#Region WriteOffToExpenses
	
	TextPurchase = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	DocumentData.Organization                                         AS Organization,
		|	DocumentData.Carrier                                          AS Partner,
		|	DocumentData.Date                                                AS RecorderDate,
		|	DocumentData.Number                                               AS RecorderNumber,
		|
		|	DocumentData.ARAPObject                                      AS ARAPObject,
		|	DocumentData.Date                                                AS PaymentDate,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	DocumentData.Sum                                               AS Sum,
		|	DocumentData.Sum                                               AS AmountARAP,
		|	0                                                                   AS AmountARAPByPackage,
		|	0                                                                   AS ToReceive,
		|
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)                  AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	DocumentData.Currency                                              AS ARAPCurrency,
		|	DocumentData.BusinessOperation                               AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                      AS PaymentMethod,
		|	DocumentData.Currency                                              AS DocumentCurrency,
		|	DocumentData.Date                                                AS DateOfCourse,
		|	UNDEFINED                                                        AS LinkedDocument,
		|	""""                                                                AS FinRecordID,
		|	DocumentData.BusinessTransactionSetting                      AS BusinessTransactionSetting
		|FROM
		|	TTOfAmountDebited AS DocumentData
		|";
	
	TextPaymentPlan_ = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	DocumentData.Organization                                         AS Organization,
		|	DocumentData.Carrier                                          AS Partner,
		|	DocumentData.Date                                                AS RecorderDate,
		|	DocumentData.Number                                               AS RecorderNumber,
		|	DocumentData.Date                                                AS PaymentDate,
		|	DocumentData.ARAPObject                                      AS ARAPObject,
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)                  AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	FALSE                                                                AS ExceedingOrder,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	DocumentData.Sum                                               AS AmountDue,
		|	DocumentData.Currency                                              AS ARAPCurrency,
		|	DocumentData.BusinessOperation                               AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                      AS PaymentMethod,
		|	DocumentData.Currency                                              AS DocumentCurrency,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS LinkedDocument,
		|	""""                                                                AS FinRecordID,
		|	DocumentData.BusinessTransactionSetting                      AS BusinessTransactionSetting
		|FROM
		|	TTOfAmountDebited AS DocumentData
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_,,,"6");
	
	#EndRegion

	#Region ReverseUseOfBookingByArrivalDate
	TextReturn = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	DocumentData.Ref.Organization                                  AS Organization,
		|	DocumentData.Ref.Carrier                                   AS Partner,
		|	DocumentData.Ref.ARAPObject                               AS ARAPObject,
		|	DocumentData.Ref.Currency                                       AS ARAPCurrency,
		|	DocumentData.Ref.Currency                                       AS DocumentCurrency,
		|	DocumentData.Sum                                               AS Sum,
		|	DocumentData.Sum                                               AS AmountARAP,
		|	CASE
		|		WHEN DocumentData.Ref.Date > DocumentData.Ref.ArrivalDate
		|			AND DocumentData.Ref.Date > DocumentData.Date
		|			THEN DocumentData.Ref.Date
		|		WHEN DocumentData.Date > DocumentData.Ref.ArrivalDate
		|			THEN DocumentData.Date
		|		ELSE DocumentData.Ref.ArrivalDate
		|	END                                                               AS RecorderDate,
		|	DocumentData.Ref.Number                                        AS RecorderNumber,
		|	DocumentData.Date                                                AS DateOfCourse,
		|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolderStorno) AS BusinessOperation,
		|	UNDEFINED AS CashFlowItem,
		|	DocumentData.RowID                                 AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.UseBookingByAdvanceHolderStorno) AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND NOT &DirectWriteOffMethod
		|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
		|";
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextReturn);
	#EndRegion
	
	#Region RefundToAgentOrCarrier
	
	//For a correct double entry, the debt to the carrier or agent under the Contract is linked to the carrier's debt on the ticket
	TextTransferOfCalculations = "
		|SELECT
		|	DocumentData.Ref                                                 AS Ref,
		|
		|	DocumentData.Ref.Organization                                     AS Organization,
		|	DocumentData.Ref.ARAPObject                                  AS CalculationObjectSource,
		|	DocumentData.Ref.ARAPObjectContract                           AS CalculationObjectReceiver,
		|	
		|	DocumentData.Sum                                                  AS Sum,
		|	DocumentData.Ref.Currency                                          AS DocumentCurrency,
		|	DocumentData.Sum                                                  AS AmountARAP,
		|	DocumentData.Ref.Currency                                          AS ARAPCurrency,
		|	CASE
		|		WHEN DocumentData.Ref.Date > DocumentData.Date THEN
		|			DocumentData.Ref.Date
		|		ELSE
		|			DocumentData.Date
		|	END                                                                  AS RecorderDate,
		|	DocumentData.Ref.Number                                           AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.BookingReturn)       AS BusinessOperation,
		|	DocumentData.Date                                                   AS PaymentDate,
		|	DocumentData.Date                                                   AS DateOfCourse,
		|	DocumentData.RowID                                    AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.BookingReturn) AS BusinessTransactionSetting,
		|	DocumentData.Ref.CashFlowItem                    AS CashFlowItem
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.Ref.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND DocumentData.Ref.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.BookingViaAgent),
		|		VALUE(Enum.BusinessTransactions.BookingFromVendor)
		|	)
		|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
		|	
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutReturnOfAdvanceTransferToSupplier(Query, QueryTexts, Registers, TextTransferOfCalculations);
	
	TextReturn = "
		|SELECT
		|	DocumentData.Ref                                                 AS Ref,
		|	DocumentData.Ref.Organization                                     AS Organization,
		|	DocumentData.Ref.Carrier                                      AS Partner,
		|	DocumentData.Ref.ARAPObject                                  AS ARAPObject,
		|	
		|	DocumentData.Ref.Currency                                          AS ARAPCurrency,
		|	DocumentData.Sum                                                  AS AmountARAP,
		|	DocumentData.Sum                                                  AS Sum,
		|	
		|	DocumentData.Date                                                   AS RecorderDate,
		|	DocumentData.Date                                                   AS DateOfCourse,
		|	DocumentData.Ref.Number                                           AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.RefundOfAdvanceHolderBooking) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                         AS PaymentMethod,
		|	DocumentData.Ref.CashFlowItem                   AS CashFlowItem,
		|	DocumentData.Ref.Currency                                          AS DocumentCurrency,
		|	DocumentData.RowID                                    AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RefundOfAdvanceHolderBooking) AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Return)
		|	)
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingRefundFromSupplier(Query, QueryTexts, Registers, TextReturn, "");
	
	#EndRegion
	
	#Region Penalty
	
	TextPurchase = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	DocumentData.Ref.Organization                                  AS Organization,
		|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingFromVendor)
		|		THEN DocumentData.Ref.Carrier
		|		ELSE DocumentData.Ref.Agent
		|	END                                                               AS Partner,
		|	DocumentData.Date                                                AS RecorderDate,
		|	DocumentData.Ref.Number                                        AS RecorderNumber,
		|
		|	DocumentData.Ref.ARAPObjectContract                        AS ARAPObject,
		|	DocumentData.Date                                                AS PaymentDate,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	
		|	DocumentData.PenaltyAmount                                         AS Sum,
		|	DocumentData.PenaltyAmount                                         AS AmountARAP,
		|	0                                                                   AS AmountARAPByPackage,
		|	0                                                                   AS ToReceive,
		|
		|	VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)      AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	DocumentData.Ref.Currency                                       AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.PenaltiesForReturnOfReservation) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                      AS PaymentMethod,
		|	DocumentData.Ref.Currency                                       AS DocumentCurrency,
		|	DocumentData.Date                                                AS DateOfCourse,
		|	UNDEFINED                                                        AS LinkedDocument,
		|	DocumentData.RowID                                 AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturnOfReservation) AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND DocumentData.Ref.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.BookingViaAgent),
		|		VALUE(Enum.BusinessTransactions.BookingFromVendor)
		|	)
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Return)
		|	)
		|";
	
	TextPaymentPlan_ = "
		|SELECT
		|	DocumentData.Ref                                              AS Ref,
		|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingFromVendor)
		|		THEN DocumentData.Ref.Carrier
		|		ELSE DocumentData.Ref.Agent
		|	END                                                               AS Partner,
		|	DocumentData.Date                                                AS RecorderDate,
		|	DocumentData.Ref.Number                                        AS RecorderNumber,
		|	DocumentData.Date                                                AS PaymentDate,
		|	
		|	DocumentData.Ref.ARAPObjectContract                        AS ARAPObject,
		|	
		|	VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)      AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	FALSE                                                                AS ExceedingOrder,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	DocumentData.PenaltyAmount                                         AS AmountDue,
		|	DocumentData.Ref.Currency                                       AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.PenaltiesForReturnOfReservation) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.SettlementOfARAP)                      AS PaymentMethod,
		|	DocumentData.Ref.Currency                                       AS DocumentCurrency,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS LinkedDocument,
		|	DocumentData.RowID                                 AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturnOfReservation) AS BusinessTransactionSetting
		|FROM
		|	Document.ElectronicTicketTransaction.Operations AS DocumentData
		|WHERE
		|	DocumentData.Ref IN (&Ref)
		|	AND DocumentData.Ref.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.BookingViaAgent),
		|		VALUE(Enum.BusinessTransactions.BookingFromVendor)
		|	)
		|	AND DocumentData.OperationType IN (
		|		VALUE(Enum.TypesOfTicketOperations.Return)
		|	)
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_);
	
	#EndRegion
	
EndProcedure

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT // Attribution of the ticket amount to the advance payment by the arrival date
	|	CASE
	|		WHEN &ArrivalDate < DocumentData.Date
	|			THEN DocumentData.Date
	|		ELSE &ArrivalDate
	|	END AS Period,
	|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolder) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	&Employee AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	&Currency AS PaymentCurrency,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|
	|	DocumentData.Sum * ISNULL(TableExchangeRatesOfReportLines.ManConversionFactor, CurrencyConversionFactors.ManConversionFactor) AS PayAmount,
	|	DocumentData.Sum * ISNULL(TableExchangeRatesOfReportLines.LocalConversionRatio, CurrencyConversionFactors.LocalConversionRatio) AS PaymentAmountLocal,
	|	DocumentData.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	&Currency AS ARAPCurrency,
	|
	|	DocumentData.Sum AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS DeferredPosting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentData.RowID
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT &DirectWriteOffMethod
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL
	|
	|SELECT // Reverse on the refund amount
	|	CASE
	|		WHEN DocumentData.Date < &ArrivalDate THEN
	|			ENDOFPERIOD(&ArrivalDate, DAY)
	|		ELSE
	|			DocumentData.Date
	|	END AS Period,
	|	VALUE(Enum.BusinessTransactions.UseBookingByAdvanceHolder) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	&Employee AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	&Currency AS PaymentCurrency,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|
	|	-DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS PayAmount,
	|	-DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS PaymentAmountLocal,
	|	-DocumentData.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	&Currency AS ARAPCurrency,
	|
	|	-DocumentData.Sum AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS DeferredPosting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT &DirectWriteOffMethod
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|
	|UNION ALL
	|
	|SELECT // Purchase via advance holder
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&AccountablePersonDepartment AS Department,
	|
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	&Currency AS PaymentCurrency,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|
	|	DocumentData.Sum * ISNULL(TableExchangeRatesOfReportLines.ManConversionFactor, CurrencyConversionFactors.ManConversionFactor) AS PayAmount,
	|	DocumentData.Sum * ISNULL(TableExchangeRatesOfReportLines.LocalConversionRatio, CurrencyConversionFactors.LocalConversionRatio) AS PaymentAmountLocal,
	|	DocumentData.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	&Currency AS ARAPCurrency,
	|
	|	DocumentData.Sum AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS DeferredPosting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData 
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentData.RowID
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL
	|
	|SELECT // Refund when purchasing through an accountable person
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.RefundOfAdvanceHolderBooking) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&AccountablePersonDepartment AS Department,
	|
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	&Currency AS PaymentCurrency,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS PayAmount,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS PaymentAmountLocal,
	|	DocumentData.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	&Currency AS ARAPCurrency,
	|
	|	DocumentData.Sum AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	FALSE AS DeferredPosting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref.BusinessOperation AS BusinessOperation,
	|	DocumentData.Ref.Organization AS Organization,
	|	DocumentData.Ref.Department AS Department,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObjectContract AS ARAPObject,
	|
	|	DocumentData.Ref.Carrier AS CorPartner,
	|	DocumentData.Ref.CounterpartyCarrier AS CorCounterparty,
	|	DocumentData.Ref.ARAPObjectContract.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.Ref.Contract AS CorContract,
	|	DocumentData.Ref.ARAPObject AS CorARAPObject,
	|
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.Sum AS AmountInCurrency,
	|
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.Sum AS AmountInARAPCurrency,
	|
	|	DocumentData.Ref.Currency AS CorCurrencyOfARAPAccounting,
	|	DocumentData.Sum AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.Ref.ARAPObjectContract AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingFromVendor)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref.BusinessOperation AS BusinessOperation,
	|	DocumentData.Ref.Organization AS Organization,
	|	DocumentData.Ref.Department AS Department,
	|
	|	DocumentData.Ref.Agent AS Partner,
	|	DocumentData.Ref.CounterpartyAgent AS Counterparty,
	|	DocumentData.Ref.ARAPObjectContract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Ref.Contract AS Contract,
	|	DocumentData.Ref.ARAPObjectContract AS ARAPObject,
	|
	|	DocumentData.Ref.Carrier AS CorPartner,
	|	DocumentData.Ref.CounterpartyCarrier AS CorCounterparty,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.Ref.ARAPObject.Contract AS CorContract,
	|	DocumentData.Ref.ARAPObject AS CorARAPObject,
	|
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.Sum AS AmountInCurrency,
	|
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.Sum AS AmountInARAPCurrency,
	|
	|	DocumentData.Ref.Currency AS CorCurrencyOfARAPAccounting,
	|	DocumentData.Sum AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.Ref.ARAPObjectContract AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL // Returns
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.BookingReturn) AS BusinessOperation,
	|	DocumentData.Ref.Organization AS Organization,
	|	DocumentData.Ref.Department AS Department,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObjectContract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Ref.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|
	|	DocumentData.Ref.Carrier AS CorPartner,
	|	DocumentData.Ref.CounterpartyCarrier AS CorCounterparty,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.Ref.ARAPObject.Contract AS CorContract,
	|	DocumentData.Ref.ARAPObjectContract AS CorARAPObject,
	|
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.Sum AS AmountInCurrency,
	|
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.Sum AS AmountInARAPCurrency,
	|
	|	DocumentData.Ref.Currency AS CorCurrencyOfARAPAccounting,
	|	DocumentData.Sum AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.Ref.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObjectContract AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingFromVendor)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.BookingReturn) AS BusinessOperation,
	|	DocumentData.Ref.Organization AS Organization,
	|	DocumentData.Ref.Department AS Department,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|
	|	DocumentData.Ref.Agent AS CorPartner,
	|	DocumentData.Ref.CounterpartyAgent AS CorCounterparty,
	|	DocumentData.Ref.ARAPObjectContract.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.Ref.Contract AS CorContract,
	|	DocumentData.Ref.ARAPObjectContract AS CorARAPObject,
	|
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.Sum AS AmountInCurrency,
	|
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.Sum AS AmountInARAPCurrency,
	|
	|	DocumentData.Ref.Currency AS CorCurrencyOfARAPAccounting,
	|	DocumentData.Sum AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.Ref.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.Ref.ARAPObjectContract AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|	AND DocumentData.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Return)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.PenaltiesForReturnOfReservation) AS BusinessOperation,
	|	&Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	DocumentData.Ref.Agent AS Partner,
	|	DocumentData.Ref.CounterpartyAgent AS Counterparty,
	|	DocumentData.Ref.ARAPObjectContract.Contract AS Contract,
	|	DocumentData.Ref.ARAPObjectContract AS ARAPObject,
	|	DocumentData.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS AmountExcludingVAT,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS LocalAmountExcludingVAT,
	|
	|	DocumentData.Ref.Currency AS Currency,
	|	DocumentData.PenaltyAmount AS AmountInCurrency,
	|	DocumentData.PenaltyAmount AS AmountExcludingVATInCurrency,
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.PenaltyAmount AS AmountInARAPCurrency,
	|	DocumentData.PenaltyAmount AS AmountExcludingVATInARAPCurrency,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.RowID AS FinRecordID
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|	AND DocumentData.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.PenaltiesForReturnOfReservation) AS BusinessOperation,
	|	&Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	DocumentData.Ref.Carrier AS Partner,
	|	DocumentData.Ref.CounterpartyCarrier AS Counterparty,
	|	DocumentData.Ref.ARAPObject.Contract AS Contract,
	|	DocumentData.Ref.ARAPObject AS ARAPObject,
	|	DocumentData.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS AmountExcludingVAT,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS LocalAmountExcludingVAT,
	|
	|	DocumentData.Ref.Currency AS Currency,
	|	DocumentData.PenaltyAmount AS AmountInCurrency,
	|	DocumentData.PenaltyAmount AS AmountExcludingVATInCurrency,
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.PenaltyAmount AS AmountInARAPCurrency,
	|	DocumentData.PenaltyAmount AS AmountExcludingVATInARAPCurrency,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.RowID AS FinRecordID
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|	AND DocumentData.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.BookingFromVendor)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	DocumentData.Agent AS Partner,
	|	DocumentData.CounterpartyAgent AS Counterparty,
	|	DocumentData.ARAPObjectContract.Contract AS Contract,
	|	DocumentData.ARAPObjectContract AS ARAPObject,
	|	DocumentData.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.AmountExcludingVAT * CurrencyConversionFactors.ManConversionFactor AS AmountExcludingVAT,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.AmountExcludingVAT * CurrencyConversionFactors.LocalConversionRatio AS LocalAmountExcludingVAT,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Sum AS AmountInCurrency,
	|	DocumentData.AmountExcludingVAT AS AmountExcludingVATInCurrency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Sum AS AmountInARAPCurrency,
	|	DocumentData.AmountExcludingVAT AS AmountExcludingVATInARAPCurrency,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.RowID AS FinRecordID
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.DocumentBusinessTransaction IN (
	|		VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	DocumentData.Carrier AS Partner,
	|	DocumentData.CounterpartyCarrier AS Counterparty,
	|	DocumentData.ARAPObject.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.AmountExcludingVAT * CurrencyConversionFactors.ManConversionFactor AS AmountExcludingVAT,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.AmountExcludingVAT * CurrencyConversionFactors.LocalConversionRatio AS LocalAmountExcludingVAT,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Sum AS AmountInCurrency,
	|	DocumentData.AmountExcludingVAT AS AmountExcludingVATInCurrency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Sum AS AmountInARAPCurrency,
	|	DocumentData.AmountExcludingVAT AS AmountExcludingVATInARAPCurrency,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.RowID AS FinRecordID
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.DocumentBusinessTransaction IN (
	|		VALUE(Enum.BusinessTransactions.BookingFromVendor)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.PenaltiesForReturningBookingOfAccountablePerson) AS BusinessOperation,
	|	&Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Ref.ARAPObject.LineOfBusiness AS LineOfBusinessCash,
	|
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|
	|	DocumentData.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|
	|	DocumentData.Ref.Currency AS Currency,
	|	DocumentData.PenaltyAmount AS AmountInCurrency,
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
	|	DocumentData.RowID AS FinRecordID
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|	AND DocumentData.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ARAPObject.LineOfBusiness AS LineOfBusinessCash,
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	DocumentData.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Sum,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Sum AS AmountInCurrency,
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
	|	DocumentData.RowID AS FinRecordID
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.DocumentBusinessTransaction IN (
	|		VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	)
	|";
	
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem AS AssetRef,
	|	CASE
	|		WHEN DocumentData.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE DocumentData.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	SUM(CAST(DocumentData.PenaltyAmount * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|	AND DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.ExpenseItem,
	|	DocumentData.AssetsLiabilitiesDimension,
	|	DocumentData.LineOfBusiness,
	|	DocumentData.Department
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem AS AssetRef,
	|	CASE
	|		WHEN DocumentData.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE DocumentData.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	SUM(CAST(DocumentData.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|
	|WHERE
	|	DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.Organization,
	|	DocumentData.ExpenseItem,
	|	DocumentData.AssetsLiabilitiesDimension,
	|	DocumentData.LineOfBusiness,
	|	DocumentData.Department
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	CAST(DocumentData.PenaltyAmount
	|			 * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	CAST(DocumentData.PenaltyAmount
	|			 * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(DocumentData.PenaltyAmount
	|			 * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|	CAST(DocumentData.PenaltyAmount
	|			 * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	CAST(DocumentData.PenaltyAmount
	|			 * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) THEN
	|		VALUE(Enum.BusinessTransactions.PenaltiesForReturningBookingOfAccountablePerson)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.PenaltiesForReturnOfReservation)
	|	END AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	CASE
	|		WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN DocumentData.RowID
	|		ELSE DocumentData.Ref.ARAPObjectContract.UUID
	|	END AS FinRecordID,
	|	""""  AS RowID,
	|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) THEN
	|		VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturningBookingOfAccountablePerson)
	|	ELSE
	|		VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturnOfReservation)
	|	END AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		DocumentData.ExpenseItem = ExpenseItems.Ref
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	CAST(DocumentData.Sum
	|			 * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	CASE
	|		WHEN
	|		 DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		 THEN
	|		  CAST(DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(DocumentData.VATAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|		ELSE CAST(DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	END AS AmountExcludingVAT,
	|	
	|	CASE
	|		WHEN
	|			DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		 THEN
	|		  CAST(DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|		- CAST(DocumentData.VATAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|		ELSE CAST(DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	END AS AmountExcludingVATMan,
	|	
	|	CAST(DocumentData.Sum
	|			 * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	
	|	CASE
	|		WHEN
	|			DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		 THEN
	|		  CAST(DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(DocumentData.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|		ELSE CAST(DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	END AS AmountExcludingVATCompl,
	|	
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	DocumentData.IDARAPObject,
	|	DocumentData.RowID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		DocumentData.ExpenseItem = ExpenseItems.Ref
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	(CASE
	|		WHEN &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentData.ExpenseItem
	|		ELSE &ExpenseItemVATWriteOff END) AS ExpenseItem,
	|	(CASE
	|		WHEN &ExpenseItemVATWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentData.DimensionOfExpenses
	|		ELSE &ExpenseDimensionVATWriteOff END) AS DimensionOfExpenses,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	CAST(DocumentData.VATAmount
	|			 * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|	CAST(DocumentData.VATAmount
	|			* CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	CAST(DocumentData.VATAmount
	|			 * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.VATOnAcquiredAssetsWriteOff) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	DocumentData.IDARAPObject,
	|	DocumentData.RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff)  AS BusinessTransactionSetting
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	NOT DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	AND NOT &AcceptVATForDeduction
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS LotVendorAttributes,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	&Ref AS ExpenseReceiptDocument,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS Cost,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS CostExcludingVAT,
	|	0 AS VATManag,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) THEN
	|		VALUE(Enum.BusinessTransactions.PenaltiesForReturningBookingOfAccountablePerson)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.PenaltiesForReturnOfReservation)
	|	END AS BusinessOperation,
	|	
	|	CASE
	|		WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN DocumentData.RowID
	|		ELSE DocumentData.Ref.ARAPObjectContract.UUID
	|	END AS FinRecordID,
	|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) THEN
	|		VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturningBookingOfAccountablePerson)
	|	ELSE
	|		VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturnOfReservation)
	|	END AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS LotVendorAttributes,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	&Ref AS ExpenseReceiptDocument,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS Cost,
	|	DocumentData.AmountExcludingVAT * CurrencyConversionFactors.ManConversionFactor AS CostExcludingVAT,
	|	0 AS VATManag,
	|	DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOfAmountDebited", QueryTexts) Then
		QueryTextTTOfWriteOffAmount(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	&Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem AS AssetRef,
	|	DocumentData.AssetsLiabilitiesDimension AS Dimension,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS SumCompl,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS SumMan,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS AmountIncludingVAT,
	|	DocumentData.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS AmountExcludingVAT,
	|	
	|	CASE
	|		WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN DocumentData.RowID
	|		ELSE DocumentData.Ref.ARAPObjectContract.UUID
	|	END AS FinRecordID,
	|	CASE WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder) THEN
	|		VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturningBookingOfAccountablePerson)
	|	ELSE
	|		VALUE(Catalog.BusinessTransactionsSettings.PenaltiesForReturnOfReservation)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND DocumentData.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND DocumentData.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|	AND DocumentData.PenaltyAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem AS AssetRef,
	|	DocumentData.AssetsLiabilitiesDimension AS Dimension,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	CASE 
	|		WHEN DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN DocumentData.Sum * CurrencyConversionFactors.LocalConversionRatio
	|		ELSE DocumentData.AmountExcludingVAT * CurrencyConversionFactors.LocalConversionRatio
	|	END AS SumCompl,
	|	CASE 
	|		WHEN DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor
	|		ELSE DocumentData.AmountExcludingVAT * CurrencyConversionFactors.ManConversionFactor
	|	END AS SumMan,
	|	DocumentData.Sum * CurrencyConversionFactors.ManConversionFactor AS AmountIncludingVAT,
	|	DocumentData.AmountExcludingVAT * CurrencyConversionFactors.ManConversionFactor AS AmountExcludingVAT,
	|	DocumentData.IDARAPObject AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTOfAmountDebited AS DocumentData
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentData.Date
	|WHERE
	|	DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND DocumentData.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.TaxationSystemSettings.Name,
		Query.TempTablesManager,
		Query.Parameters.Period,
		"TTTaxSystemSettings",
		Query.Parameters.Organization);
	
	ValueText_ = "
	|SELECT
	|	CASE
	|		WHEN DocumentOperations.Date > DocumentOperations.Ref.ArrivalDate
	|			THEN DocumentOperations.Date
	|		ELSE DocumentOperations.Ref.ArrivalDate
	|	END                                        AS Period,
	|	DocumentOperations.Ref                     AS Ref,
	|	DocumentOperations.Ref.Organization         AS Organization,
	|	DocumentOperations.Ref.Department       AS Department,
	|	CASE
	|		WHEN DocumentOperations.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|			THEN DocumentOperations.Ref.CounterpartyAgent
	|		ELSE DocumentOperations.Ref.CounterpartyCarrier
	|	END                                        AS Counterparty,
	|	UNDEFINED                                 AS Contract,
	|	CASE
	|		WHEN DocumentOperations.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|			THEN DocumentOperations.Ref.CounterpartyAgent
	|		ELSE DocumentOperations.Ref.CounterpartyCarrier
	|	END                                        AS Shipper,
	|	&ElectronicTicket                            AS DocumentAcquisitions,
	|	&ElectronicTicket                            AS OriginalTradeDocument,
	|	FALSE                                         AS ErrorCorrection,
	|	FALSE                                         AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                         AS ReduceAmountVATDeduction,
	|	UNDEFINED                                 AS PurchaseAdjustmentDocument,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATTaxation,
	|	&PurchaseForActivity                      AS VATActivityType,
	|	DocumentOperations.VATRate                  AS VATRate,
	|	UNDEFINED                                 AS Products,
	|	UNDEFINED                                 AS InventoryOwnerAttribute,
	|	UNDEFINED                                 AS CCDNumber,
	|	CASE
	|		WHEN DocumentOperations.Ref.BusinessUnitWriteOffs = VALUE(Catalog.BusinessStructure.EmptyRef) THEN
	|			DocumentOperations.Ref.Department
	|		ELSE DocumentOperations.Ref.BusinessUnitWriteOffs
	|	END                                        AS AccountingDivision,
	|	CASE
	|		WHEN DocumentOperations.Ref.LineOfBusinessForWriteOff = VALUE(Catalog.LinesOfBusiness.EmptyRef) THEN
	|			DocumentOperations.Ref.LineOfBusiness
	|		ELSE DocumentOperations.Ref.LineOfBusinessForWriteOff
	|	END                                        AS LineOfBusiness,
	|	FALSE                                         AS PurchasePerBatchOfProduction,
	|	UNDEFINED                                 AS LineOfBusinessOfProductionParty,
	|	UNDEFINED                                 AS ToExpenseAs,
	|	CASE
	|		WHEN &AcceptVATForDeduction
	|			THEN UNDEFINED
	|		ELSE &ExpenseItemVATWriteOff
	|	END                                        AS ExpenseItem,
	|	&ExpenseDimensionVATWriteOff                AS DimensionOfExpenses,
	|	DocumentOperations.Ref.ExpenseItem      AS ItemOfOtherAssets,
	|	DocumentOperations.Ref.AssetsLiabilitiesDimension AS AnalyticsOfOtherAssets,
	|	UNDEFINED                                 AS Purpose,
	|	DocumentOperations.RowID        AS RowID,
	|	DescriptionOfSettlementObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherExpenses) AS BusinessTransactionSetting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentOperations
	|	LEFT JOIN
	|		Catalog.ARAPObjects AS DescriptionOfSettlementObject
	|	ON DocumentOperations.Ref.ARAPObject = DescriptionOfSettlementObject.Ref
	|	LEFT JOIN
	|		TTTaxSystemSettings AS TaxationSystemSettings
	|	ON
	|		DocumentOperations.Ref.Organization = TaxationSystemSettings.Organization
	|WHERE
	|	DocumentOperations.Ref IN (&Ref)
	|	AND DocumentOperations.Ref.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND &DirectWriteOffMethod
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
	ValueText_ = "
	|SELECT
	|	CASE
	|		WHEN DocumentOperations.Date > DocumentOperations.Ref.ArrivalDate
	|			THEN DocumentOperations.Date
	|		ELSE DocumentOperations.Ref.ArrivalDate
	|	END                                                  AS Period,
	|	DocumentOperations.Ref                               AS Ref,
	|	DocumentOperations.Ref.Organization                   AS Organization,
	|	DocumentOperations.Ref.Department                 AS Department,
	|	CASE
	|		WHEN DocumentOperations.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAgent)
	|			THEN DocumentOperations.Ref.CounterpartyAgent
	|		ELSE DocumentOperations.Ref.CounterpartyCarrier
	|	END                                                  AS Counterparty,
	|	&ElectronicTicket                                      AS TaxInvoice,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	DocumentOperations.RowID                  AS RowID,
	|	DocumentOperations.VATRate                            AS VATRate,
	|	CASE
	|		WHEN DocumentOperations.Ref.BusinessUnitWriteOffs = VALUE(Catalog.BusinessStructure.EmptyRef) THEN
	|			DocumentOperations.Ref.Department
	|		ELSE DocumentOperations.Ref.BusinessUnitWriteOffs
	|	END                                                  AS AccountingDivision,
	|	CASE
	|		WHEN DocumentOperations.Ref.LineOfBusinessForWriteOff = VALUE(Catalog.LinesOfBusiness.EmptyRef) THEN
	|			DocumentOperations.Ref.LineOfBusiness
	|		ELSE DocumentOperations.Ref.LineOfBusinessForWriteOff
	|	END                                                  AS LineOfBusiness,
	|	DocumentOperations.Ref.ExpenseItem                AS ExpenseItem,
	|	&ExpenseItemVATWriteOff                             AS ExpenseItemVATWriteOff,
	|	&ExpenseDimensionVATWriteOff                          AS ExpenseDimensionVATWriteOff,
	|	DescriptionOfSettlementObject.UUID        AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentOperations
	|	LEFT JOIN
	|		Catalog.ARAPObjects AS DescriptionOfSettlementObject
	|	ON DocumentOperations.Ref.ARAPObject = DescriptionOfSettlementObject.Ref
	|	LEFT JOIN
	|		TTTaxSystemSettings AS TaxationSystemSettings
	|	ON
	|		DocumentOperations.Ref.Organization = TaxationSystemSettings.Organization
	|WHERE
	|	DocumentOperations.Ref IN (&Ref)
	|	AND &DirectWriteOffMethod
	|	AND DocumentOperations.Ref.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND NOT ISNULL(TaxationSystemSettings.TaxationSystem, UNDEFINED) = VALUE(Enum.TaxationSystems.Simplified)
	|	AND NOT &WriteOffVATByExpensesThatAreNotRecordedInTA
	|	AND NOT &AcceptVATForDeduction
	|";
	
	VATAccountingERP.ReflectVATDeductionForExpenses(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Ref.Currency AS Currency,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	(DocumentTable.Sum - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	CAST(DocumentTable.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                            AS AmountExcludingVATCompl,
	|
	|	CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                               AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	CAST(DocumentTable.Sum * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|	                                                                                             AS AmountExcludingVATMan,
	|	CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2))
	|	                                                                                                AS VATAmountMan,
	|	FALSE AS RecordedInARAPAccounting,
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	CAST(DocumentTable.Sum * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                                AS VATBaseLocal,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Sum AS AmountARAP,
	|	0 AS AmountVATARAP
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentTable
	|		
	|		INNER JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentTable.RowID
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Ref.Currency AS Currency,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	(DocumentTable.Sum - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	CAST(DocumentTable.Sum * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                            AS AmountExcludingVATCompl,
	|	CAST(DocumentTable.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                               AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	CAST(DocumentTable.Sum * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	                                                                                             AS AmountExcludingVATMan,
	|	CAST(DocumentTable.VATAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	                                                                                                AS VATAmountMan,
	|	FALSE AS RecordedInARAPAccounting,
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	CAST(DocumentTable.Sum * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|		- CAST(DocumentTable.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                                AS VATBaseLocal,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Sum AS AmountARAP,
	|	0 AS AmountVATARAP
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentTable
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentTable.RowID
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentTable.Date
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|	AND TableExchangeRatesOfReportLines.RowID IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Ref.Currency AS Currency,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	-(DocumentTable.Sum - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	-DocumentTable.VATAmount AS VATAmount,
	|	-(CAST(DocumentTable.Sum * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)))
	|	                                                                                            AS AmountExcludingVATCompl,
	|	-(CAST(DocumentTable.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)))
	|	                                                                                               AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	-(CAST(DocumentTable.Sum * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)))
	|	                                                                                             AS AmountExcludingVATMan,
	|	-(CAST(DocumentTable.VATAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2)))
	|	                                                                                                AS VATAmountMan,
	|	FALSE AS RecordedInARAPAccounting,
	|	-DocumentTable.Sum AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	-(CAST(DocumentTable.Sum * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	- CAST(DocumentTable.VATAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2)))
	|	                                                                                                AS VATBaseLocal,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	-DocumentTable.Sum AS AmountARAP,
	|	0 AS AmountVATARAP
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentTable
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentTable.Date
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.OperationType NOT IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Ref.Currency AS Currency,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.RowIDOfFine AS RowID,
	|	DocumentTable.PenaltyAmount AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	CAST(DocumentTable.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                            AS AmountExcludingVATCompl,
	|	0 AS VATAmountCompl,
	|	UNDEFINED AS PaymentType_,
	|	CAST(DocumentTable.PenaltyAmount * CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,2))
	|	                                                                                             AS AmountExcludingVATMan,
	|	0 AS VATAmountMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	DocumentTable.PenaltyAmount AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	CAST(DocumentTable.PenaltyAmount * CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,2))
	|	                                                                                                AS VATBaseLocal,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.PenaltyAmount AS AmountARAP,
	|	0 AS AmountVATARAP
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentTable
	|		
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = DocumentTable.Date
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.PenaltyAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction // The text of the tablequestionsummydocumentsvaluteregl()

Function QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts)
	
	RegisterName = "TTExchangeRatesOfReportLines";
	
	QueryTextsByConversionFactors = New ValueList;
	QueryTextTTCurrencyConversionFactors(Query, QueryTextsByConversionFactors);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
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
	|				AND Department = &AccountablePersonDepartment
	|				AND AdvanceHolder = &AdvanceHolder
	|				) AS Cash
	|WHERE
	|	Cash.SumBalance > 0";

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
	|	Operations.Ref.Currency AS Currency,
	|	Operations.Ref.CashFlowItem AS CashFlowItem,
	|	Operations.RowID AS RowID,
	|	Operations.Date AS Date,
	|	Operations.Sum AS Sum,
	|	Operations.AmountTotal AS AmountTotal
	|INTO ReportLines
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS Operations
	|WHERE
	|	Operations.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|	AND Operations.OperationType IN (
	|		VALUE(Enum.TypesOfTicketOperations.Purchase),
	|		VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|	)
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
	|	ReportLines.AmountTotal - CurrencyRatesOfAdvances.ReceivedEmails AS Sum,
	|	CurrencyConversionFactors.ManConversionFactor AS ManConversionFactor,
	|	CurrencyConversionFactors.LocalConversionRatio AS LocalConversionRatio
	|FROM
	|	ReportLines AS ReportLines
	|	
	|		LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|		ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|			AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|			OR NOT &ControlIssueOfCashByPurposes)
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = ReportLines.Date
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
	
	SplitExpenseLine.GroupBy("RowID", "SumMan, SumCompl, Sum");
	SplitExpenseLine.Columns.Add("ManConversionFactor", New TypeDescription("Number"));
	SplitExpenseLine.Columns.Add("LocalConversionRatio", New TypeDescription("Number"));
	
	For Each TableRow In SplitExpenseLine Do
		
		TableRow.ManConversionFactor = TableRow.SumMan / TableRow.Sum;
		TableRow.LocalConversionRatio = TableRow.SumCompl / TableRow.Sum;
		
	EndDo;
	
	QueryText = "
	|SELECT
	|	DataTable.RowID AS RowID,
	|	DataTable.ManConversionFactor AS ManConversionFactor,
	|	DataTable.LocalConversionRatio AS LocalConversionRatio
	|INTO SplitExpenseLine
	|FROM
	|	&SplitExpenseLine AS DataTable
	|;
	|
	|SELECT
	|	ReportLines.RowID AS RowID,
	|	CAST(CurrencyRatesOfAdvances.ManConversionFactor AS NUMBER(31,18)) AS ManConversionFactor,
	|	CAST(CurrencyRatesOfAdvances.LocalConversionRatio AS NUMBER(31,18)) AS LocalConversionRatio
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
	|	CAST(CurrencyConversionFactors.ManConversionFactor AS NUMBER(31,18)) AS ManConversionFactor,
	|	CAST(CurrencyConversionFactors.LocalConversionRatio AS NUMBER(31,18)) AS LocalConversionRatio
	|FROM
	|	ReportLines AS ReportLines
	|		
	|		LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|		ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|		AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|			OR NOT &ControlIssueOfCashByPurposes)
	|		LEFT JOIN TTCurrencyConversionFactors AS CurrencyConversionFactors
	|		ON CurrencyConversionFactors.Date = ReportLines.Date
	|WHERE
	|	ReportLines.AmountTotal - ReportLines.Sum >= ISNULL(CurrencyRatesOfAdvances.ReceivedEmails, 0)
	|	OR ReportLines.AmountTotal = 0
	|
	|UNION ALL
	|
	|SELECT
	|	SplitExpenseLine.RowID AS RowID,
	|	CAST(SplitExpenseLine.ManConversionFactor AS NUMBER(31,18)) AS ManConversionFactor,
	|	CAST(SplitExpenseLine.LocalConversionRatio AS NUMBER(31,18)) AS LocalConversionRatio
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

Function QueryTextTTOfWriteOffAmount(Query, QueryTexts)
	
	RegisterName = "TTOfAmountDebited";
	
	QueryText =
	"SELECT
	|	DocumentOperations.Ref                                          AS Ref,
	|	DocumentOperations.OperationType                                     AS OperationType,
	|	DocumentHeaderData.Number                                        AS Number,
	|	CASE 
	|		WHEN DocumentHeaderData.ArrivalDate < DocumentOperations.Date
	|		THEN DocumentOperations.Date
	|	ELSE DocumentHeaderData.ArrivalDate END                     AS Date,
	|	DocumentOperations.LineNumber                                     AS LineNumber,
	|	&Organization                                                      AS Organization,
	|	CASE
	|		WHEN DocumentHeaderData.BusinessUnitWriteOffs =
	|				VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN DocumentHeaderData.Department
	|		ELSE DocumentHeaderData.BusinessUnitWriteOffs
	|	END                                                             AS Department,
	|	CASE
	|		WHEN DocumentHeaderData.LineOfBusinessForWriteOff =
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN DocumentHeaderData.LineOfBusiness
	|		ELSE DocumentHeaderData.LineOfBusinessForWriteOff
	|	END                                                             AS LineOfBusiness,
	|	DocumentHeaderData.ExpenseItem                               AS ExpenseItem,
	|	DocumentHeaderData.DimensionOfExpenses                            AS DimensionOfExpenses,
	|	DocumentHeaderData.AssetsLiabilitiesDimension                     AS AssetsLiabilitiesDimension,
	|	DocumentHeaderData.CashFlowItem                AS CashFlowItem,
	|	DocumentHeaderData.GLAccountSettings                         AS GLAccountSettings,
	|	DocumentOperations.Sum                                           AS Sum,
	|	DocumentOperations.Sum - DocumentOperations.VATAmount              AS AmountExcludingVAT,
	|	DocumentOperations.VATAmount                                        AS VATAmount,
	|	DocumentHeaderData.Currency                                       AS Currency,
	|	DocumentHeaderData.ARAPObject                               AS ARAPObject,
	|	DocumentHeaderData.ARAPObjectContract                        AS ARAPObjectContract,
	|	DocumentHeaderData.Agent                                        AS Agent,
	|	DocumentHeaderData.CounterpartyAgent                              AS CounterpartyAgent,
	|	DocumentHeaderData.Carrier                                   AS Carrier,
	|	DocumentHeaderData.CounterpartyCarrier                         AS CounterpartyCarrier,
	|	DocumentHeaderData.BusinessOperation                        AS DocumentBusinessTransaction,
	|	VALUE(Enum.BusinessTransactions.ReceiptOfOtherServices)        AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherServices) AS BusinessTransactionSetting,
	|	DocumentOperations.RowID                             AS RowID,
	|	DocumentHeaderData.PurchaseForActivity                       AS VATActivityType,
	|	CASE
	|		WHEN DocumentHeaderData.BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN DocumentOperations.RowID
	|		ELSE DocumentHeaderData.ARAPObjectContract.UUID
	|	END                                                             AS FinRecordID,
	|	DocumentHeaderData.ARAPObject.UUID       AS IDARAPObject
	|INTO TTOfAmountDebited
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentOperations
	|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentHeaderData
	|		ON DocumentOperations.Ref = DocumentHeaderData.Ref
	|WHERE
	|	DocumentOperations.Ref = &Ref
	|	AND &DirectWriteOffMethod
	|	AND DocumentOperations.OperationType IN (VALUE(Enum.TypesOfTicketOperations.Purchase),
	|	                                   VALUE(Enum.TypesOfTicketOperations.ExtraPay))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentOperations.Ref                                          AS Ref,
	|	DocumentOperations.OperationType                                     AS OperationType,
	|	DocumentHeaderData.Number                                        AS Number,
	|	CASE
	|		WHEN DocumentHeaderData.ArrivalDate < DocumentOperations.Date
	|		THEN DocumentOperations.Date
	|	ELSE DocumentHeaderData.ArrivalDate END                     AS Date,
	|	DocumentOperations.LineNumber                                     AS LineNumber,
	|	&Organization                                                      AS Organization,
	|	CASE
	|		WHEN DocumentHeaderData.BusinessUnitWriteOffs =
	|				VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN DocumentHeaderData.Department
	|		ELSE DocumentHeaderData.BusinessUnitWriteOffs
	|	END                                                             AS Department,
	|	CASE
	|		WHEN DocumentHeaderData.LineOfBusinessForWriteOff =
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN DocumentHeaderData.LineOfBusiness
	|		ELSE DocumentHeaderData.LineOfBusinessForWriteOff
	|	END                                                             AS LineOfBusiness,
	|	DocumentHeaderData.ExpenseItem                               AS ExpenseItem,
	|	DocumentHeaderData.DimensionOfExpenses                            AS DimensionOfExpenses,
	|	DocumentHeaderData.AssetsLiabilitiesDimension                     AS AssetsLiabilitiesDimension,
	|	DocumentHeaderData.CashFlowItem                AS CashFlowItem,
	|	DocumentHeaderData.GLAccountSettings                         AS GLAccountSettings,
	|	-DocumentOperations.Sum                                          AS Sum,
	|	-(DocumentOperations.Sum - DocumentOperations.VATAmount)           AS AmountExcludingVAT,
	|	-DocumentOperations.VATAmount                                        AS VATAmount,
	|	DocumentHeaderData.Currency                                       AS Currency,
	|	DocumentHeaderData.ARAPObject                               AS ARAPObject,
	|	DocumentHeaderData.ARAPObjectContract                        AS ARAPObjectContract,
	|	DocumentHeaderData.Agent                                        AS Agent,
	|	DocumentHeaderData.CounterpartyAgent                              AS CounterpartyAgent,
	|	DocumentHeaderData.Carrier                                   AS Carrier,
	|	DocumentHeaderData.CounterpartyCarrier                         AS CounterpartyCarrier,
	|	DocumentHeaderData.BusinessOperation                        AS DocumentBusinessTransaction,
	|	VALUE(Enum.BusinessTransactions.ReceiptOfOtherServices) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherServices) AS BusinessTransactionSetting,
	|	DocumentOperations.RowID                             AS RowID,
	|	DocumentHeaderData.PurchaseForActivity                       AS VATActivityType,
	|	CASE
	|		WHEN DocumentHeaderData.BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.BookingViaAdvanceHolder)
	|			THEN DocumentOperations.RowID
	|		ELSE DocumentHeaderData.ARAPObjectContract.UUID
	|	END                                                             AS FinRecordID,
	|	DocumentHeaderData.ARAPObject.UUID       AS IDARAPObject
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS DocumentOperations
	|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentHeaderData
	|		ON DocumentOperations.Ref = DocumentHeaderData.Ref
	|WHERE
	|	DocumentOperations.Ref = &Ref
	|	AND &DirectWriteOffMethod
	|	AND DocumentOperations.OperationType IN (VALUE(Enum.TypesOfTicketOperations.Return))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#Region BackdateJobQueue

// Updates the State of the ticket and ticket operations.
//
// Parameters - referencedocument - Documentlink.Electronic ticket operation - an electronic ticket or its operation.
//                                If the incoming link is an electronic ticket, then its operations are updated.
//                                Only operations whose key requestions differ from the ticket Attributes are updated.
//                                If the incoming link is an operation, then the status of the electronic ticket is calculated:
//                                ("Purchased", "With additional payment", "Returned").
//
Procedure UpdateOfOperationsAndStateOfElectronicTicket(DocumentReference) Export
	
	TextTemplate1 =
	"SELECT
	|	DocumentData.Ref AS ElectronicTicket,
	|	&Key_Data AS Key_Data
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentReference
	|	AND DocumentData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS TicketOperation,
	|	&Key_Data AS Key_Data
	|FROM
	|	Document.ElectronicTicketTransaction AS DocumentData
	|WHERE
	|	DocumentData.ElectronicTicket = &DocumentReference
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OperationData.ElectronicTicket AS ElectronicTicket,
	|	ETicketData.State AS StateOfElectronicTicket
	|FROM
	|	Document.ElectronicTicketTransaction AS OperationData
	|		LEFT JOIN Document.ElectronicTicketTransaction AS ETicketData
	|		ON OperationData.ElectronicTicket = ETicketData.Ref
	|WHERE
	|	OperationData.Ref = &DocumentReference
	|	AND NOT OperationData.ElectronicTicket = VALUE(Document.ElectronicTicketTransaction.EmptyRef)";
	
	AttributesToExclude = CommonClientServer.ValueInArray("Date");
	KeyAttributes = KeyDetailsOfElectronicTicket(, AttributesToExclude);
	KeyAttributesOfOperation = KeyDetailsOfElectronicTicket(False, AttributesToExclude);
	
	QueryFields = New Array;
	For Each KeyAttribute In KeyAttributes Do
		QueryFields.Add(StrTemplate("DocumentData.%1 AS %1", KeyAttribute));
	EndDo;
	
	Query = New Query;
	Query.Text =
		StrReplace(TextTemplate1,
					"&Key_Data AS Key_Data",
					StrConcat(QueryFields, "," + Chars.LF + Chars.Tab));
		
	Query.SetParameter("DocumentReference", DocumentReference);
	ResultsArray = Query.ExecuteBatch();

	IncomingTicketData = ResultsArray[0].Select();
	
	If IncomingTicketData.Next() Then
		
		// Updating ticket operations
		
		DataOfOperationsOfIncomingTicket = ResultsArray[1].Select();
		UpdatedOfOperations = New Array;
		While DataOfOperationsOfIncomingTicket.Next() Do
			
			CheckedAttributes = KeyAttributes;
			If DataOfOperationsOfIncomingTicket.DeletionMark Then
				CheckedAttributes = KeyAttributesOfOperation;
			EndIf;
			
			For Each AttributeName In CheckedAttributes Do
				If DataOfOperationsOfIncomingTicket[AttributeName] <> IncomingTicketData[AttributeName] Then
					UpdatedOfOperations.Add(DataOfOperationsOfIncomingTicket.TicketOperation);
					Break;
				EndIf;
			EndDo;

		EndDo;

		If UpdatedOfOperations.Count() Then
		
			For Each TicketOperation In UpdatedOfOperations Do
				
				BeginTransaction();
			
				Try
					
					OperationObject = TicketOperation.GetObject();
					
					If OperationObject.DeletionMark Then
						FillPropertyValues(OperationObject, IncomingTicketData, StrConcat(KeyAttributesOfOperation, ","));
						WriteMode = DocumentWriteMode.UndoPosting;
					Else
						FillPropertyValues(OperationObject, IncomingTicketData, StrConcat(KeyAttributes, ","));
						If IncomingTicketData.Posted Then
							WriteMode = DocumentWriteMode.Posting;
						ElsIf IncomingTicketData.DeletionMark Then
							WriteMode = DocumentWriteMode.UndoPosting;
						Else
							WriteMode = DocumentWriteMode.Write;
						EndIf;
					EndIf;
					
					OperationObject.AdditionalProperties.Insert("SkipRegistrationInNonOperationalQueue");
					
					OperationObject.Write(WriteMode);
					
					MessageData = New Structure("ProcessedDocument", OperationObject.Ref);
					ClientNotifications.SendNotification("UpdateFormOfOperationWithElectronicTicket", MessageData);
					
					CommitTransaction();
					
				Except
					
					RollbackTransaction();
					
					ErrorDescription = ErrorInfo();
					ErrorText = NStr("vi = '%1
						|%2';
						|ru = '%1
						|%2';
						|en = '%1
						|%2'; fa = '%1
						|%2';
						|it = '%1
						|%2';
						|pl = '%1
						|%2';
						|tr = '%1
						|%2'");
					
					Raise StrTemplate(ErrorText,
							ErrorDescription.Description,
							NStr("vi = 'Đã xảy ra lỗi khi ghi lại chứng từ.';
								|ru = 'Произошли ошибки при записи документа.';
								|en = 'Errors occurred when writing the document.'; fa = 'Errors occurred when writing the document.';
								|it = 'Errors occurred when writing the document.';
								|pl = 'Errors occurred when writing the document.';
								|tr = 'Belge kaydedilirken hatalar oluştu.'", Common.DefaultLanguageCode()));
						
				EndTry;
				
			EndDo;
			
		EndIf;
		
	Else
		
		// Calculation of the new State of the ticket
		
		IncomingOfOperationData = ResultsArray[2].Select();
		IncomingOfOperationData.Next();
		NewStateOfTicket = NewStateOfTicket(IncomingOfOperationData.ElectronicTicket);
		
		If IncomingOfOperationData.StateOfElectronicTicket <> NewStateOfTicket Then
			
			BeginTransaction();
		
			Try
			
				ElectronicTicketObject = IncomingOfOperationData.ElectronicTicket.GetObject();
				
				ElectronicTicketObject.State = NewStateOfTicket;
				ElectronicTicketObject.AdditionalProperties.Insert("RecordingWithoutRegisteringRecords");
				ElectronicTicketObject.AdditionalProperties.Insert("SkipRegistrationInNonOperationalQueue");
				ElectronicTicketObject.DataExchange.Load = True;
				
				ElectronicTicketObject.Write(DocumentWriteMode.Write);
				
				MessageData = New Structure("ProcessedDocument", ElectronicTicketObject.Ref);
				ClientNotifications.SendNotification("UpdateETicketForm", MessageData);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorDescription = ErrorInfo();
				ErrorText = NStr("vi = '%1
					|%2';
					|ru = '%1
					|%2';
					|en = '%1
					|%2'; fa = '%1
					|%2';
					|it = '%1
					|%2';
					|pl = '%1
					|%2';
					|tr = '%1
					|%2'");
				
				Raise StrTemplate(ErrorText,
						ErrorDescription.Description,
						NStr("vi = 'Đã xảy ra lỗi khi ghi lại chứng từ.';
							|ru = 'Произошли ошибки при записи документа.';
							|en = 'Errors occurred when writing the document.'; fa = 'Errors occurred when writing the document.';
							|it = 'Errors occurred when writing the document.';
							|pl = 'Errors occurred when writing the document.';
							|tr = 'Belge kaydedilirken hatalar oluştu.'", Common.DefaultLanguageCode()));
						
			EndTry;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.ElectronicTicketTransaction.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.62";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("889b810a-2a3b-4906-a027-aea0d23ec512"); // ID generated, not copied
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.ElectronicTicketTransaction.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Giao dịch với vé điện tử"":';
								|ru = 'Обновление документов ""Операция с электронным билетом"":';
								|en = 'Update the ""Electronic ticket transaction"" documents:'; fa = 'Update the ""Electronic ticket transaction"" documents:';
								|it = 'Update the ""Electronic ticket transaction"" documents:';
								|pl = 'Update the ""Electronic ticket transaction"" documents:';
								|tr = '""Elektronik bilet işlemi"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Họ tên hành khách"" từ tên gọi các nhân được chỉ định trong mục tin ""Nhân viên""';
								|ru = '- заполнение реквизита ""ФИО пассажира"" из наименования физического лица, указанного в реквизите ""Сотрудник""';
								|en = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute'; fa = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute';
								|it = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute';
								|pl = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute';
								|tr = '- ""Yolcunun Adı Soyadı"" özniteliğinin ""Çalışan"" özniteliğinde belirtilen kişinin adından doldurma'"));
	ListOfDescriptions.Add(NStr("vi = '- tính lại tổng tiền trong phần bảng ""Giao dịch""';
								|ru = '- пересчет итоговой суммы в табличной части ""Операции""';
								|en = '- Recalculate the total amount in the ""Transactions"" table'; fa = '- Recalculate the total amount in the ""Transactions"" table';
								|it = '- Recalculate the total amount in the ""Transactions"" table';
								|pl = '- Recalculate the total amount in the ""Transactions"" table';
								|tr = '- ""İşlemler"" tablosundaki toplam tutarın yeniden hesaplanması'"));
	ListOfDescriptions.Add(NStr("vi = '- chuyển chứng từ ""Đặt phòng""';
								|ru = '- перенос документа ""Бронирование""';
								|en = '- Transfer of ""Booking"" document'; fa = '- Transfer of ""Booking"" document';
								|it = '- Transfer of ""Booking"" document';
								|pl = '- Transfer of ""Booking"" document';
								|tr = '- ""Rezervasyon"" belgesinin aktarılması'"));

	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ElectronicTicketTransaction.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ElectronicTicketTransactionAttachedFiles.FullName());
	Editable1.Add(Metadata.Documents.ElectronicTicketTransaction.FullName());
	Editable1.Add(Metadata.InformationRegisters.SourceDocumentsData.FullName());
	Editable1.Add(Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.FullName());
	Editable1.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	Editable1.Add(Metadata.InformationRegisters.JobsForPostingInBudgeting.FullName());
	Editable1.Add(Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.FullName());
	Editable1.Add(Metadata.InformationRegisters.DocumentsRegistry.FullName());
	Editable1.Add(Metadata.InformationRegisters.AccessKeysForObjects.FullName());
	Editable1.Add(Metadata.InformationRegisters.AccessKeysToRegisterAccountingCheckResults.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ElectronicTicketTransaction.Ref AS Ref
	|FROM
	|	Document.ElectronicTicketTransaction AS ElectronicTicketTransaction
	|WHERE
	|	ElectronicTicketTransaction.PassengerSFullName = """"
	|	AND NOT ElectronicTicketTransaction.Employee = VALUE(Catalog.Persons.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ElectronicTicketTransaction.Ref
	|FROM
	|	Document.ElectronicTicketTransaction.Operations AS ElectronicTicketTransaction
	|WHERE
	|	ElectronicTicketTransaction.OperationType IN (VALUE(Enum.TypesOfTicketOperations.Purchase), VALUE(Enum.TypesOfTicketOperations.ExtraPay))
	|	AND NOT ElectronicTicketTransaction.Sum = 0
	|	AND ElectronicTicketTransaction.AmountTotal = 0
	|
	|UNION ALL
	|
	|SELECT
	|	ElectronicTicketTransaction.Ref
	|FROM
	|	Document.ElectronicTicketTransaction AS ElectronicTicketTransaction
	|WHERE
	|	ElectronicTicketTransaction.DeleteBookingType = VALUE(Enum.DeleteBookingTypes.Booking)
	|	AND NOT ElectronicTicketTransaction.DeletionMark";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ArrayOfNamesOfRegistersToBeCleared = New Array;
	ArrayOfNamesOfRegistersToBeCleared.Add(Metadata.InformationRegisters.SourceDocumentsData.FullName());
	ArrayOfNamesOfRegistersToBeCleared.Add(Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.FullName());
	ArrayOfNamesOfRegistersToBeCleared.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	ArrayOfNamesOfRegistersToBeCleared.Add(Metadata.InformationRegisters.JobsForPostingInBudgeting.FullName());
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý chứng từ ""Giao dịch với vé điện tử"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать документы ""Операция с электронным билетом"" по обработчику:';
								|en = 'Cannot process the ""Electronic ticket transactions"" documents by the handler:'; fa = 'Cannot process the ""Electronic ticket transactions"" documents by the handler:';
								|it = 'Cannot process the ""Electronic ticket transactions"" documents by the handler:';
								|pl = 'Cannot process the ""Electronic ticket transactions"" documents by the handler:';
								|tr = 'İşleyici tarafından “Elektronik bilet işlemi” belgeleri işlenemedi:'"));	
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Họ tên hành khách"" từ tên gọi các nhân được chỉ định trong mục tin ""Nhân viên""';
								|ru = '- заполнение реквизита ""ФИО пассажира"" из наименования физического лица, указанного в реквизите ""Сотрудник""';
								|en = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute'; fa = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute';
								|it = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute';
								|pl = '- Fill the ""Passenger''s full name"" attribute from the name of the person specified in the ""Employee"" attribute';
								|tr = '- ""Yolcunun Adı Soyadı"" özniteliğinin ""Çalışan"" özniteliğinde belirtilen kişinin adından doldurma'"));
	ListOfDescriptions.Add(NStr("vi = '- tính lại tổng tiền trong phần bảng ""Giao dịch""';
								|ru = '- пересчет итоговой суммы в табличной части ""Операции""';
								|en = '- Recalculate the total amount in the ""Transactions"" table'; fa = '- Recalculate the total amount in the ""Transactions"" table';
								|it = '- Recalculate the total amount in the ""Transactions"" table';
								|pl = '- Recalculate the total amount in the ""Transactions"" table';
								|tr = '- ""İşlemler"" tablosundaki toplam tutarın yeniden hesaplanması'"));
	ListOfDescriptions.Add(NStr("vi = '- chuyển chứng từ ""Đặt phòng""';
								|ru = '- перенос документов ""Бронирование""';
								|en = '- Transfer of ""Booking"" documents'; fa = '- Transfer of ""Booking"" documents';
								|it = '- Transfer of ""Booking"" documents';
								|pl = '- Transfer of ""Booking"" documents';
								|tr = '- ""Rezervasyon"" belgesinin aktarılması'"));
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataForUpdate.Ref AS Ref
		|INTO DocumentsTable
		|FROM
		|	&DataForUpdate AS DataForUpdate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	DocumentData.DataVersion AS DataVersion,
		|	ISNULL(Persons.Description, UNDEFINED) AS PassengerSFullName,
		|	MAX(CASE
		|			WHEN DocumentOperations.OperationType IN (&TypesOfOperationsForRecalculation)
		|					AND NOT DocumentOperations.Sum = 0
		|					AND DocumentOperations.AmountTotal = 0
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS RecalculationOfTotalsIsRequired,
		|	DocumentData.DeleteBookingType =
		|		VALUE(Enum.DeleteBookingTypes.Booking) AS CreationOfNewBookingIsRequired
		|INTO TTDocumentsToBeChanged
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Document.ElectronicTicketTransaction AS DocumentData
		|		ON DocumentsTable.Ref = DocumentData.Ref
		|		LEFT JOIN Catalog.Persons AS Persons
		|		ON (DocumentData.Employee = Persons.Ref)
		|		LEFT JOIN Document.ElectronicTicketTransaction.Operations AS DocumentOperations
		|		ON DocumentsTable.Ref = DocumentOperations.Ref
		|
		|GROUP BY
		|	DocumentsTable.Ref,
		|	DocumentData.DataVersion,
		|	ISNULL(Persons.Description, UNDEFINED),
		|	DocumentData.DeleteBookingType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsToChange.Ref AS Ref,
		|	BookingFiles.Ref AS AttachedFile,
		|	BookingFiles.Description AS BaseName,
		|	BookingFiles.Author AS Author,
		|	BookingFiles.LockedDate AS LockedDate,
		|	BookingFiles.UniversalModificationDate AS ModificationTimeUniversal,
		|	BookingFiles.CreationDate AS CreationDate,
		|	BookingFiles.Encrypted AS Encrypted,
		|	BookingFiles.ChangedBy AS ChangedBy,
		|	BookingFiles.PictureIndex AS PictureIndex,
		|	BookingFiles.LongDesc AS LongDesc,
		|	BookingFiles.SignedWithDS AS SignedWithDS,
		|	BookingFiles.PathToFile AS PathToFile,
		|	BookingFiles.Size AS Size,
		|	BookingFiles.Extension AS ExtensionWithoutPoint,
		|	BookingFiles.BeingEditedBy AS BeingEditedBy,
		|	BookingFiles.TextExtractionStatus AS TextExtractionStatus,
		|	BookingFiles.TextStorage AS TextStorage,
		|	BookingFiles.FileStorageType AS FileStorageType,
		|	BookingFiles.Volume AS Volume,
		|	BookingFiles.FileStorage AS FileStorage,
		|	BookingFiles.StoreVersions AS StoreVersions
		|FROM
		|	TTDocumentsToBeChanged AS DocumentsToChange
		|		INNER JOIN Catalog.ElectronicTicketTransactionAttachedFiles AS BookingFiles
		|		ON DocumentsToChange.Ref = BookingFiles.FileOwner
		|WHERE
		|	DocumentsToChange.CreationOfNewBookingIsRequired
		|TOTALS
		|	COUNT(AttachedFile)
		|BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsToChange.Ref AS Ref,
		|	DocumentsToChange.DataVersion AS DataVersion,
		|	DocumentsToChange.PassengerSFullName AS PassengerSFullName,
		|	DocumentsToChange.RecalculationOfTotalsIsRequired AS RecalculationOfTotalsIsRequired,
		|	DocumentsToChange.CreationOfNewBookingIsRequired AS CreationOfNewBookingIsRequired
		|FROM
		|	TTDocumentsToBeChanged AS DocumentsToChange";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	TypesOfOperationsForRecalculation = New Array;
	TypesOfOperationsForRecalculation.Add(Enums.TypesOfTicketOperations.Purchase);
	TypesOfOperationsForRecalculation.Add(Enums.TypesOfTicketOperations.ExtraPay);
	Query.SetParameter("TypesOfOperationsForRecalculation", TypesOfOperationsForRecalculation);
	
	QueryBatch = Query.ExecuteBatch();
	LastPackage_ = QueryBatch.Count() - 1;
	SelectionOfDocuments = QueryBatch[LastPackage_].Select();
	SelectionOfDocumentsWithAttachments = QueryBatch[LastPackage_-1].Select(QueryResultIteration.ByGroups);
	AttachedFilesCatalogName =
		Metadata.Catalogs.ElectronicTicketTransactionAttachedFiles.FullName();
	
	While SelectionOfDocuments.Next() Do
		
		Recommendation = "";
		ToDeleteObject = False;
		SelectingFiles = Undefined;
		
		BeginTransaction();
		
		Try 
			
			ExceptionReason = "Block";
			
			#Region Locks
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", SelectionOfDocuments.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			If SelectionOfDocuments.CreationOfNewBookingIsRequired Then
			
				LockItem = Block.Add("InformationRegister.DocumentAmountsInAccountingCurrency.RecordSet");
				LockItem.SetValue("Recorder", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				LockItem = Block.Add("InformationRegister.DocumentsRegistry");
				LockItem.SetValue("Ref", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				LockItem = Block.Add("InformationRegister.AccessKeysForObjects");
				LockItem.SetValue("Object", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				LockItem = Block.Add("InformationRegister.AccessKeysToRegisterAccountingCheckResults");
				LockItem.SetValue("Field1", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				LockItem = Block.Add("InformationRegister.SourceDocumentsData");
				LockItem.SetValue("Document", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				LockItem = Block.Add("InformationRegister.JobsOfBackdateAdditionalDocumentPosting");
				LockItem.SetValue("Document", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				LockItem = Block.Add("InformationRegister.JobsForMonthEndClosing");
				LockItem.SetValue("Document", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem = Block.Add("InformationRegister.JobsForPostingInBudgeting");
				LockItem.SetValue("Document", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				While SelectionOfDocumentsWithAttachments.FindNext(New Structure("Ref", SelectionOfDocuments.Ref)) Do
					SelectingFiles = SelectionOfDocumentsWithAttachments.Select();
					While SelectingFiles.Next() Do
						LockItem = Block.Add(AttachedFilesCatalogName);
						LockItem.SetValue("Ref", SelectingFiles.AttachedFile);
						LockItem.Mode = DataLockMode.Exclusive;
					EndDo;
					SelectingFiles.Reset();
				EndDo;
				
			EndIf;
			
			Block.Lock();
			
			#EndRegion
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(
					SelectionOfDocuments.Ref, SelectionOfDocuments.DataVersion, Parameters.Queue);
					
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			If DocumentObject <> Undefined Then
								
				If Not ValueIsFilled(DocumentObject.PassengerSFullName)
						And ValueIsFilled(SelectionOfDocuments.PassengerSFullName) Then
					DocumentObject.PassengerSFullName = SelectionOfDocuments.PassengerSFullName;
				EndIf;
				
				If SelectionOfDocuments.RecalculationOfTotalsIsRequired Then
					CurrentTotal = 0;
					For Each TSRow In DocumentObject.Operations Do
						If TSRow.OperationType = Enums.TypesOfTicketOperations.Purchase
							Or TSRow.OperationType = Enums.TypesOfTicketOperations.ExtraPay Then
							CurrentTotal = CurrentTotal + TSRow.Sum;
							TSRow.AmountTotal = CurrentTotal;
						EndIf;
					EndDo;
				EndIf;
				
				If SelectionOfDocuments.CreationOfNewBookingIsRequired Then
					
					
					DocumentObject.AdditionalProperties.Insert("SkipRegistrationInNonOperationalQueue");
					DocumentObject.DeletionMark = True;
					DocumentObject.Write(DocumentWriteMode.UndoPosting);
					
					
				EndIf;
				
			EndIf;
			
			ExceptionReason = "Record";
				
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(SelectionOfDocuments.Ref);
			EndIf;
			
			If ToDeleteObject And
					SelectingFiles <> Undefined Then
					
				While SelectingFiles.Next() Do
					FileObject1 = SelectingFiles.AttachedFile.GetObject();
					FileObject1.Delete();
				EndDo;
					
			EndIf;
			
			If ToDeleteObject
				And Not FindByRef(
					CommonClientServer.ValueInArray(SelectionOfDocuments.Ref)).Count() Then
				DocumentObject.Delete();
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), SelectionOfDocuments.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					SelectionOfDocuments.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
			
			
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsWithIssuesCount, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsWithIssuesCount, Parameters);
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure


#EndRegion

Procedure FillInSettingsOfGeneralFormFields(Settings, ForTicketOperation = False)
	
	Finances = FinancialReportingServer;
	
	#Region Attributes
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("Agent");
	Item.Fields.Add("CounterpartyAgent");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.BookingViaAgent);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Item.Fields.Add("AccountablePersonDepartment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.BookingViaAdvanceHolder);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Contract");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Enums.BusinessTransactions.BookingViaAgent);
	Finances.NewFilter(OrGroup, "BusinessOperation", Enums.BusinessTransactions.BookingFromVendor);
	Item.Properties.Insert("Visible");
	
	// Attributes
	Item = Settings.Add();
	Item.Fields.Add("Employee");
	Finances.NewFilter(Item.Condition, "DirectWriteOffMethod", False);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	Finances.NewFilter(Item.Condition, "DirectWriteOffMethod", False);
	Item.Properties.Insert("Title", NStr("vi = 'Mục đích chi';
										|ru = 'Цель выдачи';
										|en = 'Issuance purpose'; fa = 'هدف پرداخت';
										|it = 'Scopo di emissione';
										|pl = 'Cel wydania';
										|tr = 'Verilme amacı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	Finances.NewFilter(Item.Condition, "DirectWriteOffMethod", True);
	Item.Properties.Insert("Title", NStr("vi = 'Dạng lưu chuyển tiền tệ';
										|ru = 'Статья движения ДС';
										|en = 'Cash flow item'; fa = 'قلم جریان وجوه نقد';
										|it = 'Cash flow item';
										|pl = 'Cash flow item';
										|tr = 'Nakit akış öğesi'"));
	
	If ForTicketOperation Then
	
		Item = Settings.Add();
		Item.Fields.Add("OperationsPenaltyAmount");
		Finances.NewFilter(Item.Condition, "OperationType", Enums.TypesOfTicketOperations.Return);
		Item.Properties.Insert("Visible");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#EndIf
