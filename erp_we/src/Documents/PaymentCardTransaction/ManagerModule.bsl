#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible, Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"AcquiringContract", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"POSTerminal", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
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
	DocumentMechanisms.Add("PlanningCashControl");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	PaymentCardTransactionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.PaymentCardTransaction") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query        = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextAcquiringContractARAP(Query, QueryTexts, Registers);
		QueryTextCashInTransit(Query, QueryTexts, Registers);
		QueryTextCashToBePaid(Query, QueryTexts, Registers);
		QueryTextRecordsCashCounterparty(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		PaymentCardTransactionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
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
	
	CreationCommandBasedOnAcquiringOperation = Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands, Enums.BusinessTransactions.RefundToCustomer);
	
	If CreationCommandBasedOnAcquiringOperation <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreationCommandBasedOnAcquiringOperation, 
															"BusinessOperation", 
															Enums.BusinessTransactions.CashReceiptFromCustomer,
															DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationBasedOnCommand = 
		Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	If CreationBasedOnCommand <> Undefined Then
		
		CreationBasedOnCommand.Presentation = StrTemplate(NStr("vi = '%1 (Trả lại tiền cho khách hàng)';
																|ru = '%1 (Возврат оплаты клиенту)';
																|en = '%1 (Refund to customer)'; fa = '%1 (Refund to customer)';
																|it = '%1 (Возврат оплаты клиенту)';
																|pl = '%1 (Refund to customer)';
																|tr = '%1 (Müşteriye ödeme iadesi)'"), CreationBasedOnCommand.Presentation);
		AttachableCommands.AddCommandVisibilityCondition(CreationBasedOnCommand, 
															"BusinessOperation", 
															Enums.BusinessTransactions.CashReceiptFromCustomer,
															DataCompositionComparisonType.Equal);
	EndIf;
	
	PaymentCardTransactionLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "Acquiring transaction".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  OperationKind - EnumRef.BusinessTransactions - the value of a business transaction
//
// Returns:
//	- ValueTableRow - added command to the table of values for output to the submenu
//	- Undefined - if there is no access to the current document
//
Function AddGenerateCommand(GenerationCommands, OperationKind = Undefined) Export
	If AccessRight("Insert", Metadata.Documents.PaymentCardTransaction) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PaymentCardTransaction.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PaymentCardTransaction)
													+ ?(OperationKind = Undefined, "", " (" + OperationKind + ")");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePaymentByCards";
		
		If OperationKind = Enums.BusinessTransactions.RefundToCustomer Then 
			CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.PaymentCardOperation_Refund";
		EndIf;

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
	
	PaymentCardTransactionLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PaymentCardTransactionLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("PaymentRequest");
	ArrayOfAllProps.Add("ARAPDetails.PaymentPurpose");
	ArrayOfAllProps.Add("ARAPDetails.MaturityDate");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		ArrayOfOperationDetails.Add("PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentPurpose");
	EndIf;
	
EndProcedure

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
	Operations = Enums.BusinessTransactions;
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyCheckIssueCounterpartyPages");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Item.Properties.Insert("Visible");
	
	// PaymentRequest
	Item = Settings.Add();
	Item.Fields.Add("PaymentRequest");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundToCustomer);
	Item.Properties.Insert("Visible");
	
	// PaymentPurpose
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.PaymentPurpose");
	Item.Fields.Add("DecryptionWithoutSplittingTheBasisOfThePayment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentRequest");
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// POSTerminal
	Item = Settings.Add();
	Item.Fields.Add("POSTerminal");
	Finances.NewFilter(Item.Condition, "More.POSTerminalsAreUsed", True);
	Item.Properties.Insert("Visible");
	
	// LabelCurrency
	Item = Settings.Add();
	Item.Fields.Add("LabelCurrency");
	Item.Fields.Add("LabelCurrencyCommission");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", False);
	Item.Properties.Insert("Visible");
	
	// Unallocated payment
	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroup");
	Item.Fields.Add("LineOfBusiness");
	Item.Fields.Add("RPDivision");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundToCustomer,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "More.AmountUnallocated", 0,, DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");

	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroupOfRefund");
	Item.Fields.Add("DirectionOfReturnActivity");
	Item.Fields.Add("RocDivision");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundToCustomer);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Contract");
		
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.CashReceiptFromCustomer);
	Finances.NewFilter(AndGroup, "More.UseCustomerContracts", True);
	
	Item.Properties.Insert("Visible");

	Item = Settings.Add();
	Item.Fields.Add("ReturnAgreement");
	
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(AndGroup, "More.UseCustomerContracts", True);
	
	Item.Properties.Insert("Visible");
	
	// Settlement object agreement
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsContract");
	Finances.NewFilter(Item.Condition, "More.UseCustomerContracts", True);
	Item.Properties.Insert("Visible");
	
	// The sum of the settlements, the currency of the settlements
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.AmountARAP");
	Item.Fields.Add("DecryptionWithoutSplittingTheAmountOfMutualSettlements");
	Item.Fields.Add("ARAPDetails.ARAPCurrency");
	Item.Fields.Add("DecryptionWithoutSplittingTheCurrencyOfMutualSettlements");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingTheAmountOfMutualSettlements");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Finances.NewFilter(Item.Condition, "More.ARAPCurrency", "Currency", , , True);
	Item.Properties.Insert("ReadOnly");
	
	// Decorations of the currency of the course of payment, the exchange rate of the account, the exchange rate of the sign of the account
	Item = Settings.Add();
	Item.Fields.Add("CurrencyDecorationAndPaymentRate");
	Item.Fields.Add("ARAPDetails.ExchangeRateNumeratorOfMutualSettlements");
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	Item.Fields.Add("ARAPDetails.CourseNumeratorOfMutualSettlementsText");
	Item.Fields.Add("DecodingOfThePaymentTheExchangeRateTheDenominatorOfMutualSettlementsTheInscription");
	Item.Fields.Add("ARAPDetails.ContractRateOption");
	Item.Fields.Add("DecodingWithoutSplittingIsVariantOfContractCourse");
	
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Finances.NewFilter(Item.Condition, "Currency", "More.ARAPCurrency",, DataCompositionComparisonType.NotEqual, True);
	UnderGroupOr = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr, "More.MultipleARAPCurrency", True);
	Finances.NewFilter(UnderGroupOr, "More.ARAPCurrency", Catalogs.Currencies.EmptyRef(), , DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	// CurrencyDecorationAndPaymentRate
	Item = Settings.Add();
	Item.Fields.Add("CurrencyDecorationAndPaymentRate");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.ARAPCurrency",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(AndGroup, "More.ContractRateOption",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(AndGroup, "More.ExchangeRateNumeratorOfMutualSettlements", 0,, DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Enabled");
	
	// DecodingWithoutSplittingIsVariantOfContractCourse
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingIsVariantOfContractCourse");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "More.ContractRateOption", Enums.ContractRateOptions.SpecifiedInContract,, DataCompositionComparisonType.Equal);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.ContractRateOption", Enums.ContractRateOptions.FixedAsOfShipmentDate,, DataCompositionComparisonType.Equal);
	Finances.NewFilter(AndGroup, "More.ARAPObjectType", Enums.ARAPObjectTypes.Invoice,, DataCompositionComparisonType.Equal);
	Item.Properties.Insert("Hyperlink");
	
	// Course Accuracy
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(AndGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("More.ARAPCurrency"), , DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("Currency"), , DataCompositionComparisonType.NotEqual);
	
	Item.Properties.Insert("EditFormat", "NFD=8");
	
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("More.ARAPCurrency"), , DataCompositionComparisonType.Equal);
	Finances.NewFilter(OrGroup, "More.CurrencyOfComplianceAccounting", New DataCompositionField("Currency"), , DataCompositionComparisonType.Equal);
	
	Item.Properties.Insert("EditFormat", "NFD=4");
	
	// Fee
	Item = Settings.Add();
	Item.Fields.Add("GroupCommission");
	Finances.NewFilter(Item.Condition, "RecordCommission", True);
	Item.Properties.Insert("Visible");
	
	// Maturity Date
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingRepaymentDate");
	Item.Fields.Add("ARAPDetailsMaturityDate");
	
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashReceiptFromCustomer);
	
	Item.Properties.Insert("Visible");
	
	// CommissionAgreement
	Item = Settings.Add();
	Item.Fields.Add("CommissionAgreement");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", True);
	Item.Properties.Insert("Visible");
	
EndProcedure

// Returns the parameters of the selection of articles and analyst.
// 
// Parameters:
//     AvailabilityByOperation - Boolean - Indicates whether the selection of articles and Analytics is available.
// 
// Returns:
//  Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//              .
//
Function ItemsAndDimensionsSelectionParameters(AvailabilityByOperation) Export
	
	ChoiceParametersArray = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ChoiceParameters.AvailabilityByOperation = AvailabilityByOperation;
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return PaymentCardTransactionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return PaymentCardTransactionLocalization.RequestTextTTReflectedInLocalAccounting();

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
	|	AND ValueAllowed(POSTerminal)
	|	AND ValueAllowed(ARAPDetails.Partner)";

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

//Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	InfluencingAttributes = "BusinessOperation,PaymentRequest";
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation, PaymentRequest");
		BusinessOperation = StructureFillingData.BusinessOperation;
		PaymentRequest = StructureFillingData.PaymentRequest;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		PaymentRequest = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		PaymentRequest = FillingData.PaymentRequest;
	EndIf;
	
	StructuresArray = New Array;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.InfluencingAttributes                = InfluencingAttributes;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = True;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	
	ParametersStructure.ChangesCalculationsByString               =
		"//Conditions of return beginning
		|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
		|//Conditions of return end";
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Form.AmountARAP";
	ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
	ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
	ParametersStructure.ARAPObjectSettings                  = "";
	
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.Terms                       = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Partner                          = "Object.ARAPDetails.Partner";
	
	ParametersStructure.InvoiceForOrders               = "";
	ParametersStructure.OrderBase                   = "";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	ParametersStructure.FormItems.ARAPDetails               = "ARAPDetails";
	ParametersStructure.FormItems.AddToPaymentDecryption        = "ARAPDetailsSelectionByStock";
	
	//Settings for the selection of mutual settlements
	ParametersStructure.SelectAccountsReceivable                   = BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer;
	ParametersStructure.SelectOnlyUnconditionalDebt             = BusinessOperation = Enums.BusinessTransactions.RefundToCustomer;
	ParametersStructure.PaymentByRequests                                  = ValueIsFilled(PaymentRequest);
	
	ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
	ParametersStructure.DocumentCurrencyViewOnly      = True;
	
	StructuresArray.Add(ParametersStructure);
	
	#Region SettlementObjectReturn
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		ParametersStructure.InfluencingAttributes                = InfluencingAttributes;
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ChangesPaymentPlan               = True;
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		ParametersStructure.ARAPObject                   = "Object.ARAPObject";
		ParametersStructure.ChangesCalculationsByString               =
			"//Conditions of return beginning
			|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
			|//Conditions of return end";
		
		ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
		ParametersStructure.AmountARAP              = "Form.AmountARAP";
		ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
		ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
		ParametersStructure.ARAPObjectSettings                  = "";
		
		ParametersStructure.PaymentMethod                      = "";
		ParametersStructure.ForeignCurrencyTransaction                    = "";
		
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
		ParametersStructure.Terms                       = "";
		ParametersStructure.CompanyBankAccount        = "";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.CashAccount                            = "";
		ParametersStructure.PaymentID             = "";
		ParametersStructure.Partner                          = "Object.ARAPDetails.Partner";
		
		ParametersStructure.InvoiceForOrders               = "";
		ParametersStructure.OrderBase                   = "";
		ParametersStructure.VATTaxation               = "";
		
		ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
		ParametersStructure.DocumentCurrencyViewOnly      = True;
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.PaymentCardTransaction - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	RedefiningParameterCalculation = New Structure;
	SynonymForDocumentTable = "";
	FullDocumentName = "Document.PaymentCardTransaction";
	
	If RegisterName = "CashToBePaid" Then
		
		RedefiningParameterCalculation.Insert("CurrRequests", "DocumentData.PaymentRequest.Currency");
		
		QueryText = QueryTextCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("PartnerFromDocument", "DocumentData.Partner");
		RedefiningParameterCalculation.Insert("CounterpartyFromDocument", "DocumentData.Counterparty");
		
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
			QueryText, FullDocumentName, SynonymForDocumentTable, RedefiningParameterCalculation);
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
	"SELECT TOP 1
	|	TRUE AS ThereIsGiftCertificate
	|INTO AvailabilityOfTypeOfSettlementObjectGiftCertificate
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS ARAPDetails
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (ARAPDetails.ARAPObject = ARAPObjects.Ref)
	|WHERE
	|	ARAPDetails.Ref = &Ref
	|	AND ARAPObjects.Object REFS Catalog.GiftCertificates
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	
	|	CASE
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Counterparties.RetailCustomer)
	|	ELSE
	|		DocumentData.Counterparty
	|	END AS Counterparty,
	|	
	|	
	|	CASE
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Partners.RetailCustomer)
	|	ELSE
	|		DocumentData.Partner
	|	END AS Partner,
	|	DocumentData.Counterparty AS CounterpartyFromDocument,
	|	DocumentData.Partner AS PartnerFromDocument,
	|	
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.PaymentRequest.Currency AS RequestCurrency,
	|	DocumentData.PaymentRequest.Currency AS CurrRequests,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions)
	|		ELSE VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)
	|	END AS BusinessOperationAcquiring,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.CashRecieptFromCustomerByAcquiringTransactions)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.RefundToCustomerSPaymentCard)
	|	END AS SettingUpAcquiringBusinessOperation,
	|	DocumentData.POSTerminal   AS POSTerminal,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.AcquiringContract.Counterparty AS Acquirer,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department           AS Department,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE) AS ThereIsGiftCertificate,
	|	DocumentData.Posted                AS Posted
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|		LEFT JOIN AvailabilityOfTypeOfSettlementObjectGiftCertificate AS AvailabilityOfGiftCertificateType
	|		ON TRUE
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentRef);
	
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
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.PaymentCardTransaction"));
	Values.Insert("UsePaymentRequests", GetFunctionalOption("UsePaymentRequests"));
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionRateToApplicationCurrency",           Coefficients.ConversionRateToSettlementCurrency);
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Function RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts) Export
	
	TempTableName = "TableOfCalculationObjects";
	
	QueryText = "
	|SELECT DISTINCT
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.ARAPObject.Contract AS Contract,
	|	PaymentDecryptionTable.ARAPObject.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	PaymentDecryptionTable.ARAPObject.Department AS Department
	|
	|INTO TableOfCalculationObjects
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS PaymentDecryptionTable
	|	
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND PaymentDecryptionTable.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|
	|INDEX BY
	|	ARAPObject
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestForAnalytics = New Query;
	
	RequestForAnalytics.Text = RequestTextTemporaryTableOfCalculationObjects(RequestForAnalytics, New ValueList);
	RequestForAnalytics.Text = RequestForAnalytics.Text + "
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|";
	
	RequestForAnalytics.Text = RequestForAnalytics.Text + "
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS PaymentDecryptionTable
	|		INNER JOIN TableOfCalculationObjects AS TableOfCalculationObjects
	|		ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS PaymentDecryptionTable
	|		INNER JOIN TableOfCalculationObjects AS TableOfCalculationObjects
	|		ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND TableOfCalculationObjects.Organization <> &Organization
	|	AND &PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	AND Dimension.DimensionKey IS NULL
	|";
	RequestForAnalytics.SetParameter("Ref", Query.Parameters.Ref);
	RequestForAnalytics.SetParameter("Organization", Query.Parameters.Organization);
	RequestForAnalytics.SetParameter("Counterparty", Query.Parameters.Counterparty);
	RequestForAnalytics.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	RequestForAnalytics.SetParameter("PaymentRequest", Query.Parameters.PaymentRequest);
	
	Selection = RequestForAnalytics.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTTARAPDetails(Query, QueryTexts)
	
	TempTableName = "PaymentDecryptionTable";
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	
	|	CASE
	|		WHEN &ThereIsGiftCertificate = TRUE
	|			THEN &Partner
	|		ELSE PaymentDecryptionTable.Partner
	|	END AS Partner,
	|	
	|	TableOfCalculationObjects.Contract AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness,
	|	CAST(PaymentDecryptionTable.PaymentPurpose AS Document.CustomerCommercialInvoice) AS ProformaInvoice,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	TableOfCalculationObjects.Department AS OrderDivision_,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	
	|	PaymentDecryptionTable.RowID AS RowID
	|
	|INTO PaymentDecryptionTable
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS PaymentDecryptionTable
	|	
	|	INNER JOIN
	|		TableOfCalculationObjects AS TableOfCalculationObjects
	|	ON
	|		PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE WHEN &ThereIsGiftCertificate = TRUE
	|			THEN &Partner
	|			ELSE PaymentDecryptionTable.Partner
	|		END = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTTARAPDetails(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	DocumentData.Date AS PaymentDate,
	|	DocumentData.POSTerminal AS POSTerminal,
	|	DocumentData.AcquiringContract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions) AS CashType,
	|	DocumentData.Currency AS Currency,
	|	
	|	PaymentDecryptionTable.Sum,
	|	
	|	&BusinessOperationAcquiring AS BusinessOperation,
	|	PaymentDecryptionTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.ARAPObject.Object AS OrderDocument,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	DocumentData.AuthorizationCode AS AuthorizationCode,
	|	DocumentData.PaymentCardNumber AS PaymentCardNumber
	|	
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|	
	|	LEFT JOIN
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|	AND ISNULL(DocumentData.AcquiringContract.DetailedTransactionReconciliation, TRUE)
	|	
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	DocumentData.Date AS PaymentDate,
	|	DocumentData.POSTerminal AS POSTerminal,
	|	DocumentData.AcquiringContract AS Contract,
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard) AS CashType,
	|	DocumentData.Currency AS Currency,
	|	
	|	PaymentDecryptionTable.Sum AS Sum,
	|	
	|	&BusinessOperationAcquiring AS BusinessOperation,
	|	PaymentDecryptionTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.ARAPObject.Object AS OrderDocument,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	DocumentData.AuthorizationCode AS AuthorizationCode,
	|	DocumentData.PaymentCardNumber AS PaymentCardNumber
	|	
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|
	|	LEFT JOIN
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	AND ISNULL(DocumentData.AcquiringContract.DetailedTransactionReconciliation, TRUE)
	|	
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)                                               AS RecordType,
	|	DocumentData.Date                                                                 AS Period,
	|	
	|	DocumentData.Organization                                                          AS Organization,
	|	DocumentData.AcquiringContract.BankAccount                                     AS Recipient,
	|	UNDEFINED                                                                         AS Sender,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	DocumentData.AcquiringContract.Counterparty                                         AS Counterparty,
	|	DocumentData.AcquiringContract                                                    AS Contract,
	|	DocumentData.Currency                                                               AS Currency,
	|	
	|	PaymentDecryptionTable.Sum                                                                     AS Sum,
	|	CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2))       AS SumMan,
	|	CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2))      AS SumCompl,
	|	
	|	&BusinessOperationAcquiring                                                      AS BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem                              AS CashFlowItem,
	|	PaymentDecryptionTable.RowID                                        AS FinRecordID,
	|	&SettingUpAcquiringBusinessOperation                                             AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData,
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|		)
	|	
	|UNION ALL
	|	
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
	|	DocumentData.Date                                                                 AS Period,
	|	
	|	DocumentData.Organization                                                          AS Organization,
	|	DocumentData.AcquiringContract.BankAccount                                     AS Recipient,
	|	UNDEFINED                                                                         AS Sender,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	DocumentData.AcquiringContract.Counterparty                                         AS Counterparty,
	|	DocumentData.AcquiringContract                                                    AS Contract,
	|	DocumentData.Currency                                                               AS Currency,
	|	
	|	PaymentDecryptionTable.Sum                                                                     AS Sum,
	|	CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))        AS SumMan,
	|	CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))       AS SumCompl,
	|	
	|	&BusinessOperationAcquiring                                                      AS BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem                              AS CashFlowItem,
	|	PaymentDecryptionTable.RowID                                        AS FinRecordID,
	|	&SettingUpAcquiringBusinessOperation                                             AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData,
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|		)
	|	
	|UNION ALL
	|	
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
	|	DocumentData.Date                                                                 AS Period,
	|	
	|	DocumentData.Organization                                                          AS Organization,
	|	DocumentData.AcquiringContract.BankAccount                                     AS Recipient,
	|	UNDEFINED                                                                         AS Sender,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	DocumentData.AcquiringContract.Counterparty                                         AS Counterparty,
	|	DocumentData.AcquiringContract                                                    AS Contract,
	|	DocumentData.Currency                                                               AS Currency,
	|	
	|	DocumentData.FeeAmount                                                               AS Sum,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
	|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS SumCompl,
	|	
	|	VALUE(Enum.BusinessTransactions.AcquiringFee)                    AS BusinessOperation,
	|	DocumentData.AcquiringContract.CashFlowItemCommission              AS CashFlowItem,
	|	
	|	DocumentData.DocumentID                                               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee)             AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextCashToBePaid(Query, QueryTexts, Registers)
	
	RegisterName = "CashToBePaid";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&PaymentRequest AS PaymentRequest,
	|	&CounterpartyFromDocument AS Recipient,
	|	&Organization AS Organization,
	|	DocumentData.DocumentAmount AS Sum,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions)
	|		ELSE VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)
	|	END AS BusinessOperation
	|	
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|	AND &UsePaymentRequests
	|	AND &PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsCashCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		QueryTextTTARAPDetails(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	DocumentData.Cash AS Cash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentCurrency AS PaymentCurrency,
	|
	|	CASE 
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
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
	|	SUM(DocumentData.VATAmount) AS VATAmount,
	|	SUM(DocumentData.VATAmountCompl) AS VATAmountCompl,
	|	SUM(DocumentData.AmountVATCurrencyPayment) AS AmountVATCurrencyPayment,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	SUM(DocumentData.PaymentAmountInTheSettlementCurrency) AS PaymentAmountInTheSettlementCurrency,
	|	SUM(DocumentData.PostPaymentAmountInARAPCurrency) AS PostPaymentAmountInARAPCurrency,
	|	SUM(DocumentData.PrepaymentAmountInARAPCurrency) AS PrepaymentAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.VATRate AS VATRate,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	FALSE AS DeferredPosting 
	|
	|FROM (
	|	SELECT
	|		DocumentData.Date AS Period,
	|		&BusinessOperationAcquiring AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|				THEN PaymentDecryptionTable.OrderDivision_
	|			ELSE DocumentData.Department
	|		END AS Department,
	|		DocumentData.AcquiringContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|
	|		DocumentData.AcquiringContract AS Cash,
	|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|		DocumentData.Currency AS PaymentCurrency,
	|
	|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
	|		PaymentDecryptionTable.Partner AS Partner,
	|		&Counterparty AS Counterparty,
	|		PaymentDecryptionTable.ARAPObject.Contract AS Contract,
	|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	
	|		CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|		CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|		PaymentDecryptionTable.Sum AS PaymentAmountPaymentCurrency,
	|
	|		0 AS PostpaymentAmount,
	|		0 AS PostpaymentAmountLocal,
	|		0 AS PaymentAmountInPaymentCurrency,
	|		
	|		0 AS PrepaymentAmountMan,
	|		0 AS PrepaymentAmountLocal,
	|		0 AS PrepaymentAmount,
	|
	|		0 AS VATAmount,
	|		0 AS VATAmountCompl,
	|		0 AS AmountVATCurrencyPayment,
	|
	|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|
	|		PaymentDecryptionTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
	|		0 AS PostPaymentAmountInARAPCurrency,
	|		0 AS PrepaymentAmountInARAPCurrency,
	|
	|		UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		UNDEFINED AS VATRate,
	|		&PaymentRequest AS PaymentRequest
	|	FROM
	|		Document.PaymentCardTransaction AS DocumentData
	|	
	|	LEFT JOIN
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer), 
	|			VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date AS Period,
	|		&BusinessOperationAcquiring AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|				THEN PaymentDecryptionTable.OrderDivision_
	|			ELSE DocumentData.Department
	|		END AS Department,
	|		DocumentData.AcquiringContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|
	|		DocumentData.AcquiringContract AS Cash,
	|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|		DocumentData.Currency AS PaymentCurrency,
	|
	|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
	|		PaymentDecryptionTable.Partner AS Partner,
	|		&Counterparty AS Counterparty,
	|		PaymentDecryptionTable.ARAPObject.Contract AS Contract,
	|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	
	|		0 AS PayAmount,
	|		0 AS PaymentAmountLocal,
	|		0 AS PaymentAmountPaymentCurrency,
	|
	|		0 AS PostpaymentAmount,
	|		0 AS PostpaymentAmountLocal,
	|		0 AS PaymentAmountInPaymentCurrency,
	|		
	|		0 AS PrepaymentAmountMan,
	|		0 AS PrepaymentAmountLocal,
	|		0 AS PrepaymentAmount,
	|
	|		PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS VATAmount,
	|		PaymentDecryptionTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS VATAmountCompl,
	|		PaymentDecryptionTable.VATAmount AS AmountVATCurrencyPayment,
	|
	|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|
	|		0 AS PaymentAmountInTheSettlementCurrency,
	|		0 AS PostPaymentAmountInARAPCurrency,
	|		0 AS PrepaymentAmountInARAPCurrency,
	|
	|		UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		PaymentDecryptionTable.VATRate AS VATRate,
	|		&PaymentRequest AS PaymentRequest
	|	FROM
	|		Document.PaymentCardTransaction AS DocumentData
	|	
	|	LEFT JOIN
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|			VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|		AND PaymentDecryptionTable.VATAmount <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date AS Period,
	|		VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|		DocumentData.AcquiringContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|
	|		DocumentData.AcquiringContract.BankAccount AS Cash,
	|		DocumentData.AcquiringContract.CashFlowItemCommission AS CashFlowItem,
	|		DocumentData.Currency AS PaymentCurrency,
	|
	|		DocumentData.CommissionARAPObject.LineOfBusiness AS LineOfBusiness,
	|		DocumentData.AcquiringContract.Partner AS Partner,
	|		DocumentData.CommissionARAPObject.Counterparty AS Counterparty,
	|		DocumentData.CommissionARAPObject.Contract AS Contract,
	|		DocumentData.CommissionARAPObject AS ARAPObject,
	|	
	|		CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|		CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS PaymentAmountLocal,
	|		DocumentData.FeeAmount AS PaymentAmountPaymentCurrency,
	|
	|		0 AS PostpaymentAmount,
	|		0 AS PostpaymentAmountLocal,
	|		0 AS PaymentAmountInPaymentCurrency,
	|		
	|		0 AS PrepaymentAmountMan,
	|		0 AS PrepaymentAmountLocal,
	|		0 AS PrepaymentAmount,
	|	
	|		0 AS VATAmount,
	|		0 AS VATAmountCompl,
	|		0 AS AmountVATCurrencyPayment,
	|
	|		DocumentData.Currency AS ARAPCurrency,
	|
	|		DocumentData.FeeAmount AS PaymentAmountInTheSettlementCurrency,
	|		0 AS PostPaymentAmountInARAPCurrency,
	|		0 AS PrepaymentAmountInARAPCurrency,
	|
	|		DocumentData.AcquiringContract.BankAccount AS SourceOfCashFinancialAccountingGroup,
	|		DocumentData.CommissionARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		UNDEFINED AS VATRate,
	|		UNDEFINED AS PaymentRequest
	|	FROM
	|		Document.PaymentCardTransaction AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND DocumentData.KeepRecordsOfCommissionInARAPAccounting
	|		AND DocumentData.RecordCommission
	|		AND DocumentData.FeeAmount <> 0
	|	
	|	) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.LineOfBusinessCash,
	|	DocumentData.Cash,
	|	DocumentData.CashFlowItem,
	|	DocumentData.PaymentCurrency,
	|	CASE 
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.VATRate,
	|	DocumentData.PaymentRequest
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTInitialOtherExpenses";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.Department AS Department,
	|	DocumentData.AcquiringContract.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	// Calculate the amount in the currency of management accounting.
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|
	|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentData.FeeAmount) AS AmountIncludingVATCompl,
	|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentData.FeeAmount) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
	|	ON
	|		DocumentAmountsInAccountingCurrency.Ref = DocumentData.Ref
	|		AND DocumentAmountsInAccountingCurrency.RowID = ""1""
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|	AND NOT DocumentData.KeepRecordsOfCommissionInARAPAccounting
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

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers)

	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.AcquiringContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|	DocumentData.Department AS IncomeExpenseBusinessUnit,
	|
	|	DocumentData.AcquiringContract AS Cash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	CASE
	|		WHEN ISNULL(DocumentData.AcquiringContract.CashFlowItemCommission, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			VALUE(Catalog.CashFlowReportItems.PaymentToVendor)
	|		ELSE
	|			DocumentData.AcquiringContract.CashFlowItemCommission
	|	END AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|
	|	DocumentData.AcquiringContract.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	DocumentData.FeeAmount AS AmountInCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
	|	DocumentData.PaymentRequest AS PaymentRequest
	|
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Document"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.ARAPCurrency AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Document"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	""1"" AS RowID,
	|	DocumentTable.FeeAmount AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PaymentCardTransaction AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.RecordCommission
	|	AND DocumentTable.FeeAmount <> 0
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

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
	|	&PartnerFromDocument                     AS Partner,
	|	DocumentData.AcquiringContract.BankAccount AS StorageLocation,
	|	&CounterpartyFromDocument                  AS Counterparty,
	|	&Department                          AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	
	|	&Number                                  AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.PaymentCardTransaction AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS Table
		|		LEFT JOIN Document.PaymentCardTransaction AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS Table
		|		LEFT JOIN Document.PaymentCardTransaction AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.Ref = ARAPObjects.Object
		|				AND Table.Partner = ARAPObjects.Partner
		|				AND Table.ARAPCurrency = ARAPObjects.ARAPCurrency
		|				AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	SettlementObjectPayment.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS Table
		|		LEFT JOIN Document.PaymentCardTransaction AS DocumentDataHeader
		|		ON DocumentDataHeader.Ref = Table.Ref
		|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|		ON DocumentDataHeader.Ref = SettlementObjectPayment.Object
		|			AND Table.Partner = SettlementObjectPayment.Partner
		|			AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.CommissionARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PaymentCardTransaction AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates, True);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	If Not Query.Parameters.Property("UsePaymentRequests") Then
		Query.SetParameter("UsePaymentRequests",GetFunctionalOption("UsePaymentRequests"));
	EndIf;
	
	#Region CustomersARAPAccounting
	
	#Region TextPaymentFromCustomer
	
	TextPayment = 
		"SELECT
		|	Table.Ref                                                                          AS Ref,
		|	Table.Ref.Organization                                                              AS Organization,
		|	CASE
		|		WHEN &ThereIsGiftCertificate
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                                                                   AS Partner,
		|	
		|	Table.ARAPCurrency                                                            AS ARAPCurrency,
		|	Table.ARAPObject                                                                  AS ARAPObject,
		|	
		|	Table.AmountARAP                                                             AS AmountARAP,
		|	Table.Sum                                                                           AS Sum,
		|	0                                                                                       AS IncreaseIsPaid,
		|	0                                                                                       AS ReductionIsPaid,
		|	
		|	Table.Ref.Date                                                                     AS RecorderDate,
		|	Table.Ref.Date                                                                     AS DateOfCourse,
		|	Table.MaturityDate                                                                   AS MaturityDate,
		|	Table.Ref.Number                                                                    AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                                          AS PaymentMethod,
		|	Table.CashFlowItem                                                   AS CashFlowItem,
		|	CAST(Table.PaymentPurpose AS Document.CustomerCommercialInvoice)                     AS ProformaInvoice,
		|	Table.Ref.Currency                                                                   AS DocumentCurrency,
		|	UNDEFINED                                                                            AS LinkedDocument,
		|	Table.RowID                                                             AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessTransactionSetting
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)";
		
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment);
	
	#EndRegion
	
	#Region TextRefund
	
	TextReturn = "
		|SELECT
		|	Table.Ref                                                                    AS Ref,
		|	Table.Ref.Organization                                                        AS Organization,
		|	
		|	CASE
		|		WHEN &ThereIsGiftCertificate
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                                                             AS Partner,
		|	
		|	SettlementObjectPayment.Ref                                                       AS ARAPObject,
		|	Table.ARAPCurrency                                                      AS ARAPCurrency,
		|	Table.AmountARAP                                                       AS AmountARAP,
		|	Table.Ref.Currency                                                             AS DocumentCurrency,
		|	Table.Sum                                                                     AS Sum,
		|	0                                                                                 AS BeingPaid,
		|	
		|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
		|	Table.Ref.Date                                                               AS RecorderDate,
		|	Table.Ref.Number                                                              AS RecorderNumber,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                                    AS PaymentMethod,
		|	Table.Ref.Date                                                               AS DateOfCourse,
		|	Table.CashFlowItem                                             AS CashFlowItem,
		|	Table.Ref.PaymentRequest                                AS PaymentRequest,
		|	Table.RowID                                                       AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RefundToCustomerSPaymentCard) AS BusinessTransactionSetting
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS Table
		|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|			ON Table.Ref = SettlementObjectPayment.Object
		|				AND Table.Partner = SettlementObjectPayment.Partner
		|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|				AND NOT SettlementObjectPayment.DeletionMark
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)";
	
	#EndRegion
	
	#Region ReductionIsPaid
	
	TextIsNotPaid = "
		|SELECT
		|	Table.Ref                                                                    AS Ref,
		|	Table.Ref.Organization                                                        AS Organization,
		|	
		|	CASE
		|		WHEN &ThereIsGiftCertificate
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                                                             AS Partner,
		|	
		|	Table.ARAPObject                                                            AS ARAPObject,
		|	Table.ARAPCurrency                                                      AS ARAPCurrency,
		|	Table.AmountARAP                                                       AS IncreaseIsPaid,
		|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                                    AS PaymentMethod,
		|	Table.CashFlowItem                                             AS CashFlowItem,
		|	Table.Ref.PaymentRequest                                AS PaymentRequest,
		|	Table.Ref.Currency                                                             AS DocumentCurrency,
		|	Table.Ref.Date                                                               AS RecorderDate,
		|	Table.Ref.Number                                                              AS RecorderNumber
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
		|	AND Table.Ref.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
		|	AND ISNULL(Table.Ref.PaymentRequest.ControlPaymentByARAPObjects,FALSE)
		|	AND &UsePaymentRequests";
		
	#EndRegion
	
	#Region DebtTransfer_
	
	TextDebtTransfer = "
	|SELECT
	|	Document.Ref                                            AS Ref,
	|	Document.Organization                                       AS Organization,
	|	
	|	CASE
	|		WHEN &ThereIsGiftCertificate
	|			THEN &Partner
	|		ELSE Table.Partner
	|	END                                                      AS Partner,
	|	
	|	SettlementObjectPayment.Ref                                AS CalculationObjectReceiver,
	|	ARAPObjects.Ref                                     AS CalculationObjectSource,
	|	
	|	Table.ARAPCurrency                               AS ARAPCurrency,
	|	Document.Currency                                            AS DocumentCurrency,
	|	Table.AmountARAP                                AS AmountARAP,
	|	Table.Sum                                              AS Sum,
	|	
	|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation,
	|	VALUE(Enum.PaymentForms.BankAccountPayment)             AS PaymentMethod,
	|	Document.Number                                             AS RecorderNumber,
	|	Document.Date                                              AS RecorderDate,
	|	Document.Date                                              AS DateOfCourse,
	|	Table.CashFlowItem                      AS CashFlowItem,
	|	Table.RowID                                AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting,
	|	UNDEFINED                                               AS PaymentRequest
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS Table
	|		INNER JOIN Document.PaymentCardTransaction AS Document
	|			ON Document.Ref = Table.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectPayment
	|			ON Table.Ref = SettlementObjectPayment.Object
	|				AND Table.Partner = SettlementObjectPayment.Partner
	|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
	|				AND NOT SettlementObjectPayment.DeletionMark
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON Table.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.MakingRefundToClient(Query, QueryTexts, Registers, TextReturn,
		TextDebtTransfer, TextIsNotPaid);
	#EndRegion
	
	#Region VendorsARAPAccounting
		
		TextPayment = "
		|SELECT
		|	DocumentData.Ref                                           AS Ref,
		|	DocumentData.Organization                                      AS Organization,
		|	CatalogAcquiringContracts.Partner                             AS Partner,
		|	DocumentData.Date                                             AS RecorderDate,
		|	DocumentData.Number                                            AS RecorderNumber,
		|	
		|	DocumentData.CommissionARAPObject                           AS ARAPObject,
		|	DocumentData.Currency                                           AS ARAPCurrency,
		|
		|	DocumentData.FeeAmount                                    AS Sum,
		|	DocumentData.FeeAmount                                    AS AmountARAP,
		|	0                                                                AS ReductionIsPaid,
		|	0                                                                AS IncreaseIsPaid,
		|	0                                                                AS SumMan,
		|	0                                                                AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.AcquiringFee)  AS BusinessOperation,
		|	CatalogAcquiringContracts.CashFlowItemCommission AS CashFlowItem,
		|	UNDEFINED                                                       AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                     AS PaymentMethod,
		|	DocumentData.Currency                                             AS DocumentCurrency,
		|	DocumentData.Date                                               AS DateOfCourse,
		|	DocumentData.Date                                               AS MaturityDate,
		|	UNDEFINED                                                       AS LinkedDocument,
		|	DocumentData.DocumentID                             AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee) AS BusinessTransactionSetting
		|FROM
		|	Document.PaymentCardTransaction AS DocumentData
		|		LEFT JOIN Catalog.AcquiringContracts AS CatalogAcquiringContracts
		|			ON DocumentData.AcquiringContract = CatalogAcquiringContracts.Ref
		|WHERE
		|	DocumentData.KeepRecordsOfCommissionInARAPAccounting
		|	AND DocumentData.RecordCommission
		|	AND DocumentData.FeeAmount <> 0
		|	AND DocumentData.Ref IN (&Ref)
		|";
	
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
		
	#EndRegion
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
