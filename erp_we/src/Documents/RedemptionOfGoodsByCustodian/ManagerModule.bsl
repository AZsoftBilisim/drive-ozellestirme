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
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	RedemptionOfGoodsByCustodianLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.RedemptionOfGoodsByCustodian") Then
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
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		RedemptionOfGoodsByCustodianLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// 		Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	RedemptionOfGoodsByCustodianLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "purchase of goods by the custodian".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.RedemptionOfGoodsByCustodian) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RedemptionOfGoodsByCustodian.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RedemptionOfGoodsByCustodian);
		CreateBasedOnCommand.WriteMode = "Post";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region CreationBasedOnRedemptionOfGiverSGoods

// Adds a Command to create a document "Redemption of goods from the custodian" based on the "Redemption of the giver's goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCommandToCreateBasedOnRedemptionOfGiverSGoods(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.RedemptionOfGoodsByCustodian) Then
		
		CreateBasedOnCommand                     = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.RedemptionOfGoodsByCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Người nhận gia công mua lại hàng hóa';
														|ru = 'Выкуп товаров переработчиком';
														|en = 'Redemption of goods by subcontractor'; fa = 'Redemption of goods by subcontractor';
														|it = 'Rimborso dei materiali da parte dell''elaboratore';
														|pl = 'Wykup towarów przez przetwórcę';
														|tr = 'Ürünlerin fason üretici tarafından geri alınması'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCompaniesAndProductionByThirdParty25";
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreateBasedOnCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.RedemptionOfProviderGoods);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	RedemptionOfGoodsByCustodianLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
// 		DocumentRef - DocumentRef.RedemptionOfGoodsByCustodian- link to the document
//
// Returns:
// 		Structure - details of the selected document
//
Function DocumentAttributes(DocumentRef) Export
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date",  Date(1,1,1));
	AttributesStructure1.Insert("Organization", Catalogs.Companies.EmptyRef());
	AttributesStructure1.Insert("Partner", Catalogs.Partners.EmptyRef());
	AttributesStructure1.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	AttributesStructure1.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	AttributesStructure1.Insert("ARAPObjectSettings", Enums.ARAPObjectSettings.EmptyRef());
	AttributesStructure1.Insert("Currency", Catalogs.Currencies.EmptyRef());
	AttributesStructure1.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.RedemptionOfGoodsByCustodian);
	AttributesStructure1.Insert("ByOrder", False);
	AttributesStructure1.Insert("DocumentAmount", 0);
	AttributesStructure1.Insert("AmountARAP", 0);
	AttributesStructure1.Insert("Rate", 1);
	AttributesStructure1.Insert("Repetition", 1);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef";
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.RedemptionOfGoodsByCustodian - Object of the document to
//																			get the base text from.
//
// Returns:
//	Structure - with the name, date and number of the foundation
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object);
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.RedemptionOfGoodsByCustodian - the document object to
//																			get the selection list for.
//
// Returns:
//	ValueTable - List of variants of the base texts
//
Function GroundsForPrinting(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	If ValueIsFilled(Object.Contract) Then
		
		BaseStructure = BaseStructure(Object);
		
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

#EndRegion

#Region SetOfSeries

//Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "BusinessOperation,Date";
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.RedemptionOfGoodsByCustodian";
	
	UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																New Structure());
	UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																New Structure());
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|				AND (ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByCustodian)
	|					OR ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller))
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 18
	|					ELSE 17
	|				END
	|		ELSE 0
	|	END                      AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	Statuses.LineNumber         AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region PurposeAndDirectionOfActivity

// Initializes parameters that serve the selection of assignments in document forms.
//
//	Returns:
//		See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// The remnants of the transferred goods
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"GoodsTransferredToCustodians",
			True,
			"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Passed").Check = True;
	
	DescriptionOfColumns.DataPaths.Organization    = "Object.Organization";
	DescriptionOfColumns.DataPaths.Contract        = "Object.Contract";
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
EndFunction

// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return RedemptionOfGoodsByCustodianLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
//  String - Text of the request for Reflection in regl accounting
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return RedemptionOfGoodsByCustodianLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion
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
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(BusinessOperation)";
	
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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.RedemptionOfGoodsByCustodian, DocumentObject.RedemptionOfGoodsByCustodian - document of redemption of goods by the custodian.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the taxable sales().
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Counterparty, Contract, BusinessOperation, 
										|LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillPropertyValues(FillParameters, DocumentAttributes);
	
	FillParameters.RedemptionOfGoodsByCustodian = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters to register the issued invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.RedemptionOfGoodsByCustodian, DocumentObject.RedemptionOfGoodsByCustodian - document of redemption of goods by the custodian.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of the Invoice data().
//
Function ParametersForRegisteringInvoicesIssued(Document) Export
	
	DocumentAttributes = New Structure("Ref, Date, Organization, Counterparty, VATTaxation, BusinessOperation");
	
	If TypeOf(Document) = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, DocumentAttributes);
	
	RegistrationParameters.GoodsSales = True;
	
	Return RegistrationParameters;
	
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
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                    = True;
	ParametersStructure.PaymentType_                          = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage            = ""; 
	
	ParametersStructure.CourseNumerator                        = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                      = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                        = "Object.Goods";
	ParametersStructure.PropsNameTSOrder                  = "";
	ParametersStructure.PathToTSDataPaymentDecryption      = "Object.ARAPDetails";
	
	ParametersStructure.CashAccount                                = "Object.CashAccount";
	ParametersStructure.PaymentID                 = "Object.PaymentID";
	ParametersStructure.Manager                             = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber              = "";
	ParametersStructure.IncomingDocumentDate               = "";

	ParametersStructure.PaymentSchedule                         = "Object.Terms.PaymentSchedule";
	ParametersStructure.PaymentDate                          = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText                   = "Form.PaymentStepsText";
	ParametersStructure.InvoiceForOrders                   = "";
	ParametersStructure.OrderBase                       = "";
	
	ParametersStructure.FormItems.LabelCurrencies          = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages           = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations         = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement            = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements  = "GoodsAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.PathToTSDataPaymentSteps             = "";
	ParametersStructure.DocumentAmountForm                  = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm               = "";
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = False;
	
	ParametersStructure.ARAPObject                       = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms, Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
EndProcedure

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Presentation of a metadata object in the main language
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Bên cho thuê kho mua lại hàng hóa';
		|ru = 'Выкуп товаров хранителем';
		|en = 'Sales invoice — VMI sold'; fa = 'فاکتور فروش — VMI فروخته‌شده';
		|it = 'Acquisto di merci da parte del depositario';
		|pl = 'Wykup towarów opiekunem';
		|tr = 'Malların emanetçi tarafından itfası'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("BusinessOperation");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If Data.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller Then
		ObjectPresentation = NStr("vi = 'Bên nhận gia công mua lại hàng hóa';
									|ru = 'Выкуп товаров переработчиком';
									|en = 'Redemption of goods by subcontractor'; fa = 'Redemption of goods by subcontractor';
									|it = 'Rimborso dei materiali da parte dell''elaboratore';
									|pl = 'Wykup towarów przez przetwórcę';
									|tr = 'Malların fason üretici tarafından itfası'");
	Else
		ObjectPresentation = NStr("vi = 'Bên cho thuê kho mua lại hàng hóa';
									|ru = 'Выкуп товаров хранителем';
									|en = 'Sales invoice — VMI sold'; fa = 'فاکتور فروش — VMI فروخته‌شده';
									|it = 'Acquisto di merci da parte del depositario';
									|pl = 'Wykup towarów opiekunem';
									|tr = 'Malların emanetçi tarafından itfası'");
	EndIf;
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Data.Number, Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.SalesOpportunity                  AS SalesOpportunity,
	|	DocumentData.Department           AS Department,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.PriceIncludesVAT         AS PriceIncludesVAT,
	|	DocumentData.VATTaxation      AS VATTaxation,
	|	DocumentData.PaymentMethod             AS PaymentMethod,
	|	DocumentData.PaymentDate             AS PaymentDate,
	|	DocumentData.CourseNumerator           AS Rate,
	|	DocumentData.CourseDenominator         AS Repetition,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	ISNULL(DocumentData.Contract.AllowableAmountPayable, 0) AS AllowableAmountPayable,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.ARAPObject          AS ARAPObject,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	For Each Column In QueryResult.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	MetadataIdentifier = Common.MetadataObjectID(FullObjectName());
	ContractInformation    = "";
	NumberForPrinting           = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier",        MetadataIdentifier);
	Query.SetParameter("BeginningOfMonthOfPeriod",            BegOfMonth(Attributes.Period));
	Query.SetParameter("NumberForPrinting",                  NumberForPrinting);
	Query.SetParameter("ContractInformation",           ContractInformation);
	Query.SetParameter("PriceIncludesVAT",                ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.RedemptionOfGoodsByCustodian);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	HeaderData_.BusinessOperation  AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	HeaderData_.Counterparty             AS Counterparty,
	|	HeaderData_.Contract                AS Contract,
	|	HeaderData_.Shipper       AS Shipper,
	|	HeaderData_.GoodsRecipient        AS GoodsRecipient,
	|	FALSE                               AS RetailSaleOfGoods,
	|	InventoryTable.Ref              AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                       AS ImplementationAdjustmentDocument,
	|	UNDEFINED                       AS ConsignedGoodsCustomer,
	|	FALSE                               AS SalesViaCommissionAgent,
	|	FALSE                               AS ErrorCorrection,
	|	FALSE                               AS AdjustmentUnderApprovalOfParties,
	|	UNDEFINED                       AS DocumentSaleAdjustment,
	|	HeaderData_.ARAPObject         AS ARAPObject,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	Dimension.Products             AS Products,
	|	Dimension.Characteristic           AS Characteristic,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	Dimension.Series                    AS Series,
	|	""""                               AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Count
	|		ELSE InventoryTable.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	InventoryTable.QuantityByGBRN    AS QuantityByGBRN,
	|	0                                  AS ExciseTaxAmount,
	|	InventoryTable.CCDNumber            AS CCDNumber,
	|	InventoryTable.VATRate           AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	InventoryTable.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	InventoryTable.LineNumber         AS LineNumber,
	|	InventoryTable.RowID AS RowID,
	|	InventoryTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting    AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfGoodsByCustodian.InventoryKinds AS InventoryTable
	|		LEFT JOIN Document.RedemptionOfGoodsByCustodian AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|";
	
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryTable.Package",
			"InventoryTable.ItemsLocationAttributes.Products"));
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Department AS Department,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	TableTypesOfStocks_.VATActivityType AS VATActivityType,
	|
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	&Manager AS Manager,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS RevenueAmount,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS RevenueAmountExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS RevenueAmountExclVATLocal,
	|	TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal AS RevenueAmountIncludingVATLocal,
	|	&Partner AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountOfVATSettlements AS AmountExcludingVATInARAPCurrency,
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate           AS VATRate
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                     AS Period,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	&Ref                     AS Document,
	|	&Partner                    AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.RedemptionOfGoodsByCustodian.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|ORDER BY
	|	SeriesTable.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                    AS LineOfBusiness,
	|	&Partner                 AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	CAST(&Comment AS STRING(100)) AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.RedemptionOfGoodsByCustodian.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                           AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber            AS CCDNumber,
	|	TableTypesOfStocks_.Count          AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN    AS QuantityByGBRN,
	|	&BusinessOperation                 AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType  AS VATTaxation,
	|	UNDEFINED                           AS CorItemsLocationAttributes,
	|	UNDEFINED                           AS CorInventoryOwnerAttribute,
	|	UNDEFINED                           AS ShipmentCompany,
	|	TableTypesOfStocks_.Products        AS Products,
	|	TableTypesOfStocks_.Characteristic      AS Characteristic
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|ORDER BY
	|	TableTypesOfStocks_.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	SetRequestParameterVATTaxTypesTaxable(Query);
	
	QueryText = 
	"SELECT
	|	InventoryKinds.LineNumber                AS LineNumber,
	|	InventoryKinds.Ref                     AS Ref,
	|	&Organization                           AS Organization,
	|	CatInventoryKinds.Currency                  AS Currency,
	|	InventoryKinds.RowID        AS RowID,
	|	InventoryKinds.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryType              AS InventoryType,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey   AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributes.Products   AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.Count                 AS Count,
	|	InventoryKinds.QuantityByGBRN           AS QuantityByGBRN,
	|	InventoryKinds.VATRate                  AS VATRate,
	|	InventoryKinds.VATAmount                   AS VATAmount,
	|	InventoryKinds.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	CASE
	|		WHEN InventoryKinds.AmountIncludingVAT <> 0
	|			THEN CAST(InventoryKinds.AmountARAP * InventoryKinds.VATAmount / InventoryKinds.AmountIncludingVAT AS NUMBER(31, 2))
	|		ELSE 0
	|	END                                  AS AmountOfVATSettlements,
	|	InventoryKinds.AmountARAP        AS AmountARAP,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	ISNULL(InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)         AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)       AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)          AS VATAmountMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)      AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)         AS VATLocal,
	|	ISNULL(Amounts.VATBaseLocal, 0)          AS VATBaseLocal,
	|	
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities
	|				AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END)                                 AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|			THEN VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|		WHEN InventoryKinds.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END)                                 AS VATActivityType
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.RedemptionOfGoodsByCustodian.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|			AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON InventoryKinds.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|		
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON InventoryKinds.Ref = Amounts.Ref
	|			AND InventoryKinds.RowID = Amounts.RowID
	|WHERE
	|	InventoryKinds.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Goods.ItemsLocationAttributes.Products   AS Products,
	|	Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	&EmptyAssignment                                AS Purpose,
	|	Goods.ItemsLocationAttributes.Series          AS Series,
	|	Goods.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|FROM
	|	Document.RedemptionOfGoodsByCustodian.Goods AS Goods
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Goods.ItemsLocationAttributes.Products      = Dimension.Products
	|			AND Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND Goods.ItemsLocationAttributes.Series          = Dimension.Series
	|			AND Goods.ItemsLocationAttributes.StorageLocation  = Dimension.StorageLocation
	|			AND &EmptyAssignment                                = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.Products IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments";
	
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners",
								InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters));
	
EndProcedure

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref                                                             AS Ref,
	|	MAX(
	|		ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities
	|INTO TTBases
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentData
	|		LEFT JOIN Document.RedemptionOfGoodsByCustodian.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.RedemptionOfGoodsByCustodian";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
								Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%",        RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If SynonymForDocumentTable <> "GoodsTable" Then
		For Each CalculationParameter In RedefiningParameterCalculation Do
			RedefiningParameterCalculation[CalculationParameter.Key] = StrReplace(CalculationParameter.Value,
																				"GoodsTable",
																				SynonymForDocumentTable);
		EndDo;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
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
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure SetRequestParameterVATTaxTypesTaxable(Query) Export
	
	If Query.Parameters.Property("TypesOfVATTaxable") Then
		Return;
	EndIf;

	Query.SetParameter("TypesOfVATTaxable", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.RedemptionOfGoodsByCustodian AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS CalculationObjectSource,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.RedemptionOfGoodsByCustodian.ARAPDetails AS Table
		|		LEFT JOIN Document.RedemptionOfGoodsByCustodian AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.PaymentDate                                               AS PaymentDate,
		|	NULL                                                                     AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	0 		                                                                 AS AmountARAPByPackage,
		|	Table.AmountIncludingVAT                                                        AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.Ref.BusinessOperation                                     AS BusinessOperation,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	NULL                                                                     AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.RedemptionOfGoodsByCustodian.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Ref.BusinessOperation                                     AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate                                               AS PaymentDate,
		|	NULL                                                                     AS PaymentOption,
		|	Table.AmountARAP                                              AS AmountDue,
		|		
		|   TRUE 	                                                                 AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	NULL                                                                     AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.RedemptionOfGoodsByCustodian.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.RedemptionOfGoodsByCustodian.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingDimensionByPartners");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Sales_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			AS VATActivityType,
	|	DocumentTable.VATTaxation				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	UNDEFINED 									AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
// 		PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Redemption of goods by the custodian
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Mua lại hàng hóa bảo quản';
									|ru = 'Выкуп товаров хранителем';
									|en = 'Sales invoice — VMI sold'; fa = 'فاکتور فروش — VMI فروخته‌شده';
									|it = 'Acquisto di merci da parte del depositario';
									|pl = 'Wykup towarów opiekunem';
									|tr = 'Malların emanetçi tarafından itfası'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Mua lại hàng hóa bảo quản';
											|ru = 'Выкуп товаров хранителем';
											|en = 'Sales invoice — VMI sold'; fa = 'فاکتور فروش — VMI فروخته‌شده';
											|it = 'Acquisto di merci da parte del depositario';
											|pl = 'Wykup towarów opiekunem';
											|tr = 'Malların emanetçi tarafından itfası'");
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.RedemptionOfGoodsByCustodian,
													  ComparisonType.Equal);
													  
	// Repurchase of goods by the processor
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "InvoiceRepurchaseByProcessor";
	PrintCommand.Presentation = NStr("vi = 'Người nhận gia công mua lại hàng hóa';
									|ru = 'Выкуп товаров переработчиком';
									|en = 'Sales invoice — External subcontracting'; fa = 'فاکتور فروش — پیمانکاری فرعی خارجی';
									|it = 'Rimborso dei materiali da parte dell''elaboratore';
									|pl = 'Wykup towarów przez przetwórcę';
									|tr = 'Malların fason üretici tarafından itfası'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Người nhận gia công mua lại hàng hóa';
											|ru = 'Выкуп товаров переработчиком';
											|en = 'Redemption of goods by subcontractor'; fa = 'Redemption of goods by subcontractor';
											|it = 'Rimborso dei materiali da parte dell''elaboratore';
											|pl = 'Wykup towarów przez przetwórcę';
											|tr = 'Malların fason üretici tarafından itfası'");
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.RedemptionOfGoodsByToller,
													  ComparisonType.Equal);
	If Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Commercial invoice';
										|ru = 'Commercial invoice';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Commercial invoice';
										|pl = 'Commercial invoice';
										|tr = 'Commercial invoice'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
		
	RedemptionOfGoodsByCustodianLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			NStr("vi = 'Mua lại hàng hóa';
				|ru = 'Выкуп товаров';
				|en = 'Redemption of goods'; fa = 'بازخرید کالا';
				|it = 'Svincolo di merci';
				|pl = 'Wykup towarów';
				|tr = 'Malların itfası'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	ElsIf PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceRepurchaseByProcessor") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceRepurchaseByProcessor",
			NStr("vi = 'Mua lại hàng hóa';
				|ru = 'Выкуп товаров';
				|en = 'Redemption of goods'; fa = 'بازخرید کالا';
				|it = 'Svincolo di merci';
				|pl = 'Wykup towarów';
				|tr = 'Malların itfası'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	RedemptionOfGoodsByCustodianLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects,
		OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure")
		And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
									Metadata.Documents.RedemptionOfGoodsByCustodian.FullName(),
									ObjectsArray,
									Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
																									PrintFormsSet,
																									ObjectsArray,
																									"Invoice");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormInvoice(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceInt");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RedemptionOfGoodsByCustodian", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
		
	RedemptionOfGoodsByCustodianLocalization.CreateSetOfPrintedForms(ObjectsArray,
																		PrintParameters,
																		PrintFormsCollection,
																		PrintObjects,
																		PrintFormsSet);
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates("Document.RedemptionOfGoodsByCustodian",
																						ObjectsArray,
																						PrintParameters,
																						PrintFormsCollection,
																						PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(
		PrintFormsSet,
		"Invoice",
		NStr("vi = 'Mua lại hàng hóa';
			|ru = 'Выкуп товаров';
			|en = 'Redemption of goods'; fa = 'بازخرید کالا';
			|it = 'Svincolo di merci';
			|pl = 'Wykup towarów';
			|tr = 'Malların itfası'"),
		0);
	
	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceInt", NStr("vi = 'Invoice';
																										|ru = 'Invoice';
																										|en = 'Invoice'; fa = 'فاکتور';
																										|it = 'Invoice';
																										|pl = 'Invoice';
																										|tr = 'Invoice'"), 2);
	EndIf;	
	RedemptionOfGoodsByCustodianLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	RedemptionOfGoods.Ref          AS Ref,
	|	RedemptionOfGoods.Number           AS Number,
	|	RedemptionOfGoods.Date            AS Date,
	|	RedemptionOfGoods.Counterparty      AS Recipient,
	|	RedemptionOfGoods.Organization     AS Organization,
	|	RedemptionOfGoods.Organization.Prefix AS Prefix,
	|	RedemptionOfGoods.Currency          AS Currency,
	|	CASE
	|		WHEN RedemptionOfGoods.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR RedemptionOfGoods.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                           AS ConsiderVAT,
	|	RedemptionOfGoods.PriceIncludesVAT AS PriceIncludesVAT,
	|	RedemptionOfGoods.IssuiedBy        AS VacationProduced,
	|	&Presentation               AS Presentation
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS RedemptionOfGoods
	|WHERE
	|	RedemptionOfGoods.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentGoods.Ref               AS Ref,
	|	DocumentGoods.LineNumber          AS LineNumber,
	|	DocumentGoods.Products         AS Products,
	|	DocumentGoods.Products.Code     AS Code,
	|	DocumentGoods.Products.SKU AS SKU,
	|	DocumentGoods.Products.DescriptionFull AS ProductNameFull_,
	|	DocumentGoods.Characteristic.DescriptionFull AS Characteristic,
	|	PRESENTATION(DocumentGoods.Series) AS SeriesPresentation,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DocumentGoods.Products.UnitOfMeasure.Description
	|		ELSE DocumentGoods.Package.Description
	|	END                                AS UnitOfMeasure,
	|	DocumentGoods.NumberOfPackages   AS Count,
	|	DocumentGoods.Price                 AS Price,
	|	DocumentGoods.Sum                AS Sum,
	|	DocumentGoods.VATRate            AS VATRate,
	|	DocumentGoods.VATAmount             AS VATAmount
	|FROM
	|	Document.RedemptionOfGoodsByCustodian.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref";
	
	Query.Text = StrReplace(
		Query.Text, "&Presentation", FillInDocumentPresentationInRequest("RedemptionOfGoods.BusinessOperation"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	FirstDocument = True;
	ShowVAT  = Constants.DisplayAdditionalVATColumns.Get();
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes   = ValueIsFilled(NameOfCodeColumn);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_RedemptionOfGoodsByCustodian_Invoice";
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate("Document.RedemptionOfGoodsByCustodian.PF_MXL_RedemptionOfGoodsByCustodian");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea,
			PrintData.Ref);
		
		TitleText =
			TMCommonUseClientServer.GenerateDocumentTitle(
				PrintData,
				PrintData.Presentation);
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TitleText);
		
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		
		SupplierPresentation = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		
		DataStructureProvider = New Structure;
		DataStructureProvider.Insert("Vendor",               PrintData.Organization);
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		
		CustomerDataStructure = New Structure;
		CustomerDataStructure.Insert("Recipient",              PrintData.Recipient);
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		ThereIsVAT        = PrintData.ConsiderVAT;
		
		NamesOfRegions = NamesOfRegions(ShowVAT And ThereIsVAT);
		
		ProductColumnArea = Template.Area("FirstColumnOfGoods");
		ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
											+ ?(OutputCodes, 0, Template.Area("ColumnOfCodes").ColumnWidth);
		
		RoomArea = Template.GetArea(NamesOfRegions.TableHeader + "|LineNumber");
		AreaCodes  = Template.GetArea(NamesOfRegions.TableHeader + "|ColumnOfCodes");
		ProductArea  = Template.GetArea(NamesOfRegions.TableHeader + "|" + NamesOfRegions.OwnGoods);
		DataArea = Template.GetArea(NamesOfRegions.TableHeader + "|" + NamesOfRegions.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		LineNumberArea = Template.GetArea(NamesOfRegions.TableRow + "|LineNumber");
		StringCodeArea  = Template.GetArea(NamesOfRegions.TableRow + "|ColumnOfCodes");
		ProductAreaRows  = Template.GetArea(NamesOfRegions.TableRow + "|" + NamesOfRegions.OwnGoods);
		RowDataArea = Template.GetArea(NamesOfRegions.TableRow + "|" + NamesOfRegions.Data);
		
		Sum       = 0;
		VATAmount    = 0;
		LineNumber = 0;
		
		// Output the rows of the Goods table
		ProductSelection_1 = SelectionByDocuments.Select();
		
		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			
			SetParameter(LineNumberArea, "LineNumber", LineNumber);
			SpreadsheetDocument.Put(LineNumberArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				
				StringCodeArea.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(StringCodeArea);
			EndIf;
			
			ProductAreaRows.Parameters.Fill(ProductSelection_1);
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(ProductSelection_1.ProductNameFull_,
																				ProductSelection_1.Characteristic,
																				Undefined,
																				ProductSelection_1.SeriesPresentation,
																				AdditionalParametersProductPresentation);
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductAreaRows.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductAreaRows);
			
			RowDataArea.Parameters.Fill(ProductSelection_1);
			
			SpreadsheetDocument.Join(RowDataArea);
			
			Sum    = Sum    + ProductSelection_1.Sum;
			VATAmount = VATAmount + ProductSelection_1.VATAmount;
			
		EndDo;
		
		// We output the basement
		RoomArea = Template.GetArea(NamesOfRegions.TableFooter + "|LineNumber");
		AreaCodes  = Template.GetArea(NamesOfRegions.TableFooter + "|ColumnOfCodes");
		ProductArea  = Template.GetArea(NamesOfRegions.TableFooter + "|" + NamesOfRegions.OwnGoods);
		DataArea = Template.GetArea(NamesOfRegions.TableFooter + "|" + NamesOfRegions.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		TotalDataStructure = New Structure;
		TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		
		DataArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the total of the ADS
		If GetFunctionalOption("UseVATAccounting") Then
			Area = Template.GetArea("VATBasement");
			
			DataStructureVATBasement = New Structure;
			DataStructureVATBasement.Insert("TotalVAT", VATAmount);
			
			If ThereIsVAT Then
				DataStructureVATBasement.Insert("VAT",
												?(PrintData.PriceIncludesVAT, 
													NStr("vi = 'Trong đó thuế GTGT:';
														|ru = 'В том числе НДС:';
														|en = 'Including VAT:'; fa = 'Including VAT:';
														|it = 'IVA compresa:';
														|pl = 'W tym VAT';
														|tr = 'KDV dahil:'", Common.DefaultLanguageCode()),
													NStr("vi = 'Thuế GTGT:';
														|ru = 'Сумма НДС:';
														|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
														|it = 'Importo IVA:';
														|pl = 'Wartość VAT';
														|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			Else
				DataStructureVATBasement.Insert("VAT", NStr("vi = 'Không gồm thuế (GTGT)';
															|ru = 'Без налога (НДС)';
															|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
															|it = 'senza imposta (IVA)';
															|pl = 'bez podatku (VAT)';
															|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
			EndIf;
			
			Area.Parameters.Fill(DataStructureVATBasement);
			SpreadsheetDocument.Join(Area);
		EndIf;
		// We output the Amount in words
		TemplateArea = Template.GetArea("AmountInWords");
		
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Tổng số %1, thành tiền %2';
								|ru = 'Всего наименований %1, на сумму %2';
								|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
								|it = 'Totale articoli %1, per importo di %2';
								|pl = 'Razem pozycji %1, na kwotę %2';
								|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
							LineNumber,
							PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		DataStructureSumInWords = New Structure;
		DataStructureSumInWords.Insert("AmountInWords",  AmountInWords);
		DataStructureSumInWords.Insert("TotalString", TotalString);
		
		TemplateArea.Parameters.Fill(DataStructureSumInWords);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			VacationProduced = PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date);
			
			DataStructureVacationProduced = New Structure;
			DataStructureVacationProduced.Insert("VacationProduced", VacationProduced);
			
			TemplateArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

Function NamesOfRegions(ThereIsVAT)
	
	ReturnStructure = New Structure("Data, OwnGoods, TableFooter, TableRow, TableHeader");
	
	If ThereIsVAT Then
		ReturnStructure.Data = "WithVATData";
		ReturnStructure.OwnGoods = "GoodsWithVAT";
		ReturnStructure.TableFooter = "BasementTableWithVAT";
		ReturnStructure.TableRow = "TableRowWithVAT";
		ReturnStructure.TableHeader = "HeaderOfTableWithVAT";
	Else
		ReturnStructure.Data = "Data";
		ReturnStructure.OwnGoods = "OwnGoods";
		ReturnStructure.TableFooter = "TableFooter";
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.TableHeader = "TableHeader";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	EndIf;
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	FALSE AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	"""" AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.RedemptionOfGoodsByCustodian AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	0 AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	0 AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref											AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	0                                                        AS DiscountAmount,
	|	Goods.Sum                                             AS AmountWithoutADiscount,
	|	FALSE                                                     AS ThisIsReusablePackage	
	|FROM 
	|	Document.RedemptionOfGoodsByCustodian.Goods AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Goods.LineNumber
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
EndFunction

#EndRegion

#Region DocumentsRegistry

Function CreateHyperlinkToDesign(Parameters) Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      ** Key     - String - name of the prop in the template;
//      ** Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      ** Key     - String - name of the prop in the template;
//      ** Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites:
//      ** Key     - String - name of the attachment in the template;
//      ** Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

// Returns the base text based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.RedemptionOfGoodsByCustodian - Object of the document to
//																			get the base text from.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation
//
Function BaseStructure(Object)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If (Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) 
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
			"SELECT ALLOWED
			|	CounterpartyContracts.NameForPrinting AS Basis,
			|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
			|	CounterpartyContracts.Number AS BaseDocumentNumber
			|FROM
			|	Catalog.CounterpartyContracts AS CounterpartyContracts
			|WHERE
			|	CounterpartyContracts.Ref = &Ref");
		Query.SetParameter("Ref", Object.Contract);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

// The function returns the name of the Manager of the product redemption document by the custodian.
//
// Returns:
//	String - the name of the manager of the goods repurchase document by the custodian.
//
Function FullObjectName()
	
	Return "Document.RedemptionOfGoodsByCustodian";
	
EndFunction

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
	
EndProcedure

#EndRegion

#Region UnifiedMethodsForBusinessOperations

#Region Posting

// Returns parameters for filling in inventory types for the document "Transfer of goods to the custodian".
//
// Parameters:
//  Object - DocumentObject.RedemptionOfGoodsByCustodian - 
//
// Returns:
//  See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	FillParameters.SelectionOfStockTypes_.Organization = Object.Organization;
	
	FillParameters.SelectionOfStockTypes_.InventoryType = New Array;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business transaction of the contract.
//
// Parameters:
//  Business Operation - Enumeration link.Economic operations - an economic operation for verification.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return GetFunctionalOption("ToUseTermsOfSales");

EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//  Object - FormDataStructure - 
//
// Returns:
//  CatalogRef.CounterpartyContracts - 
//
Function GetDefaultContract(Object) Export
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
	   And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		Contract = SalesServer.GetDefaultContract(Object,
														   ContractBusinessTransaction(),
														   Object.ARAPCurrency,
														   Object.LineOfBusiness);
	Else
		
		Contract = SalesServer.GetDefaultContract(Object,
														   ContractBusinessTransaction(),
														   Object.ARAPCurrency);
		
	EndIf;
	
	Return Contract;
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;

	SalesServer.SetContractAvailability(
		Object, Items.Contract.Enabled, Items.Contract.Visible, Contract);
	
EndProcedure

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = True;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);

	Items.Partner.Title = NStr("vi = 'Khách hàng';
								|ru = 'Клиент';
								|en = 'Customer'; fa = 'مشتری';
								|it = 'Cliente';
								|pl = 'Customer';
								|tr = 'Müşteri'");;
	
	Items.Terms.Visible = ToUseTermsOfSales();
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
			
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo khách hàng';
																		|ru = 'По клиенту';
																		|en = 'By customer'; fa = 'بر اساس مشتری';
																		|it = 'Per cliente';
																		|pl = 'Przez klienta';
																		|tr = 'Müşteriye göre'")));
			
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));

	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// FAG
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.CustomersARAPAccounting", True));
	
	Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//  NewDocument - Boolean - 
//  Number - Number - 
//  Date - Date - 
//
// Returns:
//  String - 
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	Return "";
	
EndFunction

// Returns the document view
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Mua lại hàng hóa bảo quản';
				|ru = 'Выкуп товаров хранителем';
				|en = 'Sales invoice — VMI sold'; fa = 'فاکتور فروش — VMI فروخته‌شده';
				|it = 'Acquisto di merci da parte del depositario';
				|pl = 'Wykup towarów opiekunem';
				|tr = 'Malların emanetçi tarafından itfası'");
	
EndFunction

#EndRegion

#EndRegion

#Region GeneralMethodsForBusinessOperations

#Region ActionHandlers

// Gets a server action handler depending on the business operation
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions, Undefined - 
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function ActionHandler(BusinessOperation = Undefined) Export
	If BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller Then
		ActionHandler = RedemptionOfGoodsByToller;
	Else
		ActionHandler = Documents.RedemptionOfGoodsByCustodian;
	EndIf;
	Return ActionHandler;
	
EndFunction

#EndRegion

#Region Form

// Sets up the business operation props
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Object - FormDataStructure - 
//
Procedure ConfigureBusinessTransactionDetails(Form, Object) Export
	
	Items = Form.Items;
	
	Items.BusinessOperation.ChoiceList.Clear();
		
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.RedemptionOfGoodsByCustodian);
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.RedemptionOfGoodsByToller);
	EndIf;
	Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
	   And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region QueriesTexts

// Returns a representation of the document to insert into the query
//
// Parameters:
//  BusinessTransactionField - String - name field of the business transaction in the request
//
// Returns:
//  String - 
//
Function FillInDocumentPresentationInRequest(BusinessTransactionField = "BusinessOperation")
	
	Presentation =
	"
	|CASE
	|	WHEN &BusinessTransactionField = VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller)
	|		THEN ""&RedemptionOfGoodsByToller""
	|	ELSE
	|		""&RedemptionOfGoodsByCustodian""
	|END
	|";
	
	Presentation = StrReplace(Presentation, "&BusinessTransactionField", BusinessTransactionField);
	
	Handler = Documents.RedemptionOfGoodsByCustodian.ActionHandler(Enums.BusinessTransactions.RedemptionOfGoodsByCustodian);
	Presentation = StrReplace(Presentation, "&RedemptionOfGoodsByCustodian", Handler.ObjectPresentation());
	Handler =Documents.RedemptionOfGoodsByCustodian.ActionHandler(Enums.BusinessTransactions.RedemptionOfGoodsByToller);
	Presentation = StrReplace(Presentation, "&RedemptionOfGoodsByToller", Handler.ObjectPresentation());
	Return Presentation;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
