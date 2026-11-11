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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CommissionFeeCalculationMethod";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CommissionFeeCalculationMethod";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RemunerationPercentage", Parameters);
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "OperationService, CommissionFeeCalculationMethod, VATRateOfRemuneration");
	
EndProcedure

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
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateReportBasedOnPaymentInvoiceCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	PurchasingReportToConsignorPrincipalLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "report to the Commitee (principal) on sales".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined - There is no comda of creation based on.
//
Function AddGenerateCommand(GenerationCommands) Export
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	PurchasingReportToConsignorPrincipalLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//  CommissionFeeCalculationMethod - EnumRef.CommissionFeeCalculationMethods - method for calculating remuneration.
//  ArrayOfAllProps - Array of String - Array of all the names of banking details that depend on the business operation.
//  ArrayOfOperationDetails - Array of String - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(CommissionFeeCalculationMethod, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("RemunerationPercentage");
	ArrayOfAllProps.Add("VATRateOfRemuneration");
	ArrayOfAllProps.Add("AmountVATRemuneration");
	ArrayOfAllProps.Add("Goods.CommissionAmount");
	ArrayOfAllProps.Add("Goods.AmountVATRemuneration");
	ArrayOfAllProps.Add("CommissionAmount");
	ArrayOfAllProps.Add("OperationService");
	
	ArrayOfOperationDetails = New Array;
	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("VATRateOfRemuneration");
		ArrayOfOperationDetails.Add("AmountVATRemuneration");
		ArrayOfOperationDetails.Add("Goods.CommissionAmount");
		ArrayOfOperationDetails.Add("Goods.AmountVATRemuneration");
		ArrayOfOperationDetails.Add("CommissionAmount");
		ArrayOfOperationDetails.Add("OperationService");
	EndIf;
	
EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.ConsignmentReportToVendor - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount+DocumentData.CommissionAmount AS DocumentAmount,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|
	|	DocumentData.DocumentAmount+DocumentData.CommissionAmount AS AmountARAP,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|
	|	DocumentData.Posted AS Posted
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		ARAPCurrency = Selection.ARAPCurrency;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		CommissionAmount = Selection.CommissionAmount;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		CommissionAmount = 0;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.DeliveryForPrincipal);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP); 
	AttributesStructure1.Insert("CommissionAmount", CommissionAmount);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// The function returns the structure of significant document details
//
// Returns:
//	Structure - Details of the document.
//
Function StructureOfMeaningfulProps() Export
	
	Return New Structure("
		|Partner,
		|Counterparty,
		|Contract,
		|Organization,
		|Terms,
		|Currency,
		|Department,
		|VATTaxation,
		|PriceIncludesVAT,
		|LineOfBusiness,
		|DocumentAcquisitions
		|");
	
EndFunction


// The function returns the request text for selecting products and works
//
// Parameters:
//  TempTableName - Undefined, String - name of the temporary table.
//
// Returns:
//  String - query text.
//
Function TextOfRequestGoodsServicesForPreparationOfReportsToPurchasingCommitteeBalancesByAppointment(TempTableName = Undefined) Export
	
	// the request text contains literals to replace.
	QueryText =
	"SELECT
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Products.UnitOfMeasure AS Package,
	|	BalanceTable.Purpose AS Purpose,
	|	BalanceTable.DocumentAcquisitions AS DocumentAcquisitions,
	|	BalanceTable.DocumentAcquisitions.Counterparty AS Vendor,
	|	BalanceTable.CCDNumber AS CCDNumber,
	|	BalanceTable.Currency AS Currency,
	|	BalanceTable.CountBalance AS Count,
	|	BalanceTable.QuantityByGBRNBalance AS QuantityByGBRN,
	|	BalanceTable.CountBalance / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages,
	|	CASE
	|		WHEN VendorInvoice.PriceIncludesVAT
	|			THEN CAST(BalanceTable.AmountIncludingVATBalance / CASE
	|						WHEN BalanceTable.CountBalance = 0
	|							THEN 1
	|						ELSE BalanceTable.CountBalance
	|					END AS NUMBER(31, 2))
	|		ELSE CAST((BalanceTable.AmountIncludingVATBalance - BalanceTable.VATAmountBalance) / CASE
	|					WHEN BalanceTable.CountBalance = 0
	|						THEN 1
	|					ELSE BalanceTable.CountBalance
	|				END AS NUMBER(31, 2))
	|	END AS Price,
	|	BalanceTable.AmountIncludingVATBalance AS AmountIncludingVAT,
	|	BalanceTable.VATAmountBalance AS VATAmount,
	|	CASE
	|		WHEN VendorInvoice.PriceIncludesVAT
	|			THEN BalanceTable.AmountIncludingVATBalance
	|		ELSE CAST(BalanceTable.AmountIncludingVATBalance - BalanceTable.VATAmountBalance AS NUMBER(31, 2))
	|	END AS Sum,
	|	Assignments.OrderDocument AS SalesOrder,
	|	
	|	CASE
	|		WHEN ISNULL(Assignments.ConsiderVATRates, FALSE)
	|			THEN BalanceTable.VATRate
	|		ELSE ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|			  VALUE(Catalog.VATRates.EmptyRef)))
	|	END AS VATRate
	|,TempTableName
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance(
	|			,
	|			(NOT &UseSelectionAsIntended
	|				OR &UseSelectionAsIntended
	|					AND Purpose IN (&AssignmentsArray))
	|			AND (NOT &UseDocumentSelection
	|				OR &UseDocumentSelection
	|					AND DocumentAcquisitions IN (&ArrayOfPurchaseDocuments))
	|				AND (NOT &UseSupplierSelection
	|					OR &UseSupplierSelection
	|						AND DocumentAcquisitions.Counterparty = &Vendor)
	|				AND Purpose.Contract = &Contract
	|				AND Currency = &Currency
	|				AND Organization = &Organization) AS BalanceTable
	|		LEFT JOIN Document.VendorInvoice AS VendorInvoice
	|		ON (VendorInvoice.Ref = BalanceTable.DocumentAcquisitions)
	|	LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period,
	|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON BalanceTable.Products = ProductsVATRates.Products
	|	LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
	|		ON (TRUE)
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		BalanceTable.Purpose = Assignments.Ref
	|";

	ReplacementText_1 = "";
	OrderingText = "";
	
	If ValueIsFilled(TempTableName) Then
		ReplacementText_1 = "INTO "+TempTableName;
	Else
		OrderingText = "
		|ORDER BY
		|	Organization,
		|	Products,
		|	Characteristic,
		|	Package,
		|	Purpose,
		|	DocumentAcquisitions,
		|	SalesOrder
		|";
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"BalanceTable.Products.UnitOfMeasure",
		"BalanceTable.Products"));
	
	QueryText = StrReplace(QueryText, ",TempTableName", ReplacementText_1) + OrderingText;
	
	Return QueryText;
EndFunction

// Procedure for filling in products in a document
//
// Parameters:
//  Object - DocumentObject.PurchasingReportToConsignorPrincipal - Document.
//  PurposeList - Array of CatalogRef.Assignments - a list of destinations for which products are selected.
//  ListOfAcquisitionDocuments - Array - from the document Link.Purchase Of Goods And Services, Document Link.Correctionbeverly,
//         Document link.Return to the supplier - a list of documents that changed the data for purchased works and goods.
//
Procedure RequirementsForGoodsAndServicesForMakingReportsToPurchasingCommittee(Object, PurposeList, ListOfAcquisitionDocuments) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"Document.PurchasingReportToConsignorPrincipal.ManagerModule.RequirementsForGoodsAndServicesForMakingReportsToPurchasingCommittee");
	NumberOfProcessedData = 0;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(TextOfRequestGoodsServicesForPreparationOfReportsToPurchasingCommitteeBalancesByAppointment());

	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", ?(ValueIsFilled(Object.Contract), Object.Contract, Undefined));
	
	Query.SetParameter("AssignmentsArray", PurposeList);
	Query.SetParameter("UseSelectionAsIntended", (PurposeList.Count()>0));
	
	Query.SetParameter("ArrayOfPurchaseDocuments", ListOfAcquisitionDocuments);
	Query.SetParameter("UseDocumentSelection", (ListOfAcquisitionDocuments.Count()>0));
	
	Query.SetParameter("Vendor", Catalogs.Counterparties.EmptyRef());
	Query.SetParameter("UseSupplierSelection", False);
	
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Object.Organization));
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsAndServicesToRegisterPurchasingReportsToConsignorBalance.Products.UnitOfMeasure",
		"GoodsAndServicesToRegisterPurchasingReportsToConsignorBalance.Products"));
	
	QueryResult = Query.Execute();
	
	Object.Goods.Clear();
	
	SelectionByProductType_ = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionByProductType_.Next() Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, SelectionByProductType_);
		
		NumberOfProcessedData = NumberOfProcessedData + 1;
	EndDo;
	
	CheckForAcquisitionsAndCorrectiveAdjustmentsInSameReport(Object);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);
	
EndProcedure

// The function returns the result of a check to find an acquisition and a corrective adjustment in one report
//
// Parameters:
//  Object - DocumentObject.PurchasingReportToConsignorPrincipal - Document.
//
// Returns:
//  Boolean - The result of the check.
//
Function CheckForAcquisitionsAndCorrectiveAdjustmentsInSameReport(Object) Export
	
	Cancel = False;
	
	Return Cancel;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.Contract  = "Object.Contract";
	
	DestinationPattern.AssignmentTypes = New Array;
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.DeliveryForPrincipal);
	
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", True, "Object.Goods.Purpose");
	
	Return FormTemplate;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return PurchasingReportToConsignorPrincipalLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return PurchasingReportToConsignorPrincipalLocalization.RequestTextTTReflectedInLocalAccounting();

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
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	StructuresArray = New Array;
	
	#Region PurchasingCommitteeReport
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		
	ParametersStructure.CourseNumerator                    = 1;
	ParametersStructure.CourseDenominator                  = 1;
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	ParametersStructure.DocumentAmount                   = "Object.DocumentAmount";
	ParametersStructure.PropsNameTSOrder              = "SalesOrder";
	ParametersStructure.ARAPCurrency             = "Object.Currency";
	ParametersStructure.AmountARAP              = "Object.DocumentAmount";
	
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "";
	ParametersStructure.IncomingDocumentDate           = "";
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentSettlement";
	ParametersStructure.FormItems.InscriptionCalculations     = "DecorationSettlementState";
	
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	ParametersStructure.PropsNameTSAmountWithVAT          = "AmountARAP";
	
	ParametersStructure.ARAPObject                   = "Object.Goods.ARAPObject";
	
	ParametersStructure.InvoiceForOrders               = Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder;
	ParametersStructure.PaymentStagesViewOnly        = Not (UserRightsCached.VarianceFromSalesTermsAndConditions()
										Or Not Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction

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

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.ConsignmentReportToVendor - the document to generate parameters for.
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
	FillParameters.PurchasingReportToConsignorPrincipal = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.ConsignmentReportToVendor, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.Date					= Object.Date;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	RegistrationParameters.VATTaxation		= Object.VATTaxation;
	RegistrationParameters.ImplementationOfWorksServices	= True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

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

// Returns the VAT rate for the specified purchase document.
//
// Parameters:
//	RowData - Structure:
//  * Products - CatalogRef.Products - nomenclature;
//  * Characteristic - CatalogRef.ItemsCharacteristics - a characteristic of an item; 
//  * DocumentAcquisitions - DocumentRef.VendorInvoice, DocumentRef.ReturnOfGoodsToVendor, DocumentRef.PurchaseAdjustment - purchase document;
//  * Purpose - CatalogRef.Assignments - purpose of the product;
//  * CCDNumber - CatalogRef.CCDNumbers - CCD number;
//	Organization - CatalogRef.Companies - The company is a commission agent.
//	
// Returns:
//	Undefined, CatalogRef.VATRates - bid on the purchase document.
//
Function GetVATRateOnPurchase(RowData, Organization) Export
	
	QueryText = "SELECT TOP 1
		|	GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.VATRate AS VATRate
		|FROM
		|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Turnovers(
		|			,
		|			,
		|			,
		|			Organization = &Organization
		|				AND Products = &Products
		|				AND Characteristic = &Characteristic
		|				AND DocumentAcquisitions = &DocumentAcquisitions
		|				AND Purpose = &Purpose
		|				AND CCDNumber = &CCDNumber) AS GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers";
	
	Query = New Query();
	Query.Parameters.Insert("Organization", Organization);
	For Each DataOfParameter In RowData Do
		Query.Parameters.Insert(DataOfParameter.Key, DataOfParameter.Value);
	EndDo;
	Query.Text = QueryText;
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		Return Result.VATRate;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Creates a representation of the metadata object in the main language.
// 
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Báo cáo đấu thầu';
		|ru = 'Отчет комитенту о закупках';
		|en = 'Purchase notification'; fa = 'اعلان خرید';
		|it = 'Report sugli acquisti al committente';
		|pl = 'Raport do komisanta o zakupach';
		|tr = 'Satın alma bildirimi'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("PreparationOfReportsToPurchasingCommittee");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	
	PurchasingReportToConsignorPrincipalLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PurchasingReportToConsignorPrincipal") Then
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
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		PurchasingReportToConsignorPrincipalLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

#Region CreatingHyperlinkInSalesLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	ShowOrders = GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals")
		And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor);
		
	Hyperlink = Undefined;
	HyperlinkText = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
						|ru = 'Отчеты комитентам (принципалам) о закупках';
						|en = 'Purchase notifications'; fa = 'اعلامیه‌های خرید';
						|it = 'Report ai commitenti (mandanti) sugli acquisti';
						|pl = 'Raporty komitentom (zleceniodawcom) o zakupach';
						|tr = 'Satın alma bildirimleri'");
	
	If ShowOrders Then
		Hyperlink = New FormattedString(HyperlinkText,,,,
			NameOfReportsToPurchasingCommitteeListForm());
	EndIf;
	
	Return Hyperlink;
	
EndFunction

Function NameOfReportsToPurchasingCommitteeListForm() Export
	
	Return "Document.PurchasingReportToConsignorPrincipal.Form.ToRegister";
	
EndFunction

#EndRegion

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                                         AS Period,
	|	DocumentData.Number                                        AS Number,
	|	DocumentData.Ref                                       AS Ref,
	|	DocumentData.Currency                                       AS Currency,
	|	DocumentData.Organization                                  AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency   AS LocalAccountingCurrency,
	|	DocumentData.Organization.RegistrationCountry                AS RegistrationCountry,
	|	DocumentData.Partner                                      AS Partner,
	|	DocumentData.Counterparty                                   AS Counterparty,
	|	DocumentData.OperationService                                       AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)          AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|	DocumentData.Contract                                      AS Contract,
	|	DocumentData.Manager                                     AS Manager,
	|
	|	CASE WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|	THEN
	|		DocumentData.Date
	|	ELSE
	|		DocumentData.EndOfPeriod
	|	END                                                        AS EndOfPeriod,
	|	DocumentData.Department                                AS Department,
	|	DocumentData.FinancialAccountingGroup                       AS FinancialAccountingGroup,
	|	DocumentData.Terms                                   AS Terms,
	|	DocumentData.LineOfBusiness                      AS LineOfBusiness,
	|	DocumentData.Comment                                  AS Comment,
	|	DocumentData.DocumentAmount                               AS DocumentAmount,
	|	DocumentData.DeletionMark                              AS DeletionMark,
	|	DocumentData.Posted                                     AS Posted,
	|	DocumentData.Author                                        AS Author,
	|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	UNDEFINED AS AdjustmentPeriod_
	|
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                            Attributes.Period);
	Query.SetParameter("Number",                             Attributes.Number);
	Query.SetParameter("EndOfPeriod",                      EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("Currency",                            Attributes.Currency);
	Query.SetParameter("ARAPCurrency",              Attributes.Currency);
	Query.SetParameter("BusinessOperation",             Enums.BusinessTransactions.PurchasingReportToThePrincipal);
	Query.SetParameter("BusinessTransactionSetting",    Catalogs.BusinessTransactionsSettings.PurchasingReportToThePrincipal);
	Query.SetParameter("LocalAccountingCurrency",    Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",        Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Contract",                           Attributes.Contract);
	Query.SetParameter("Organization",                       Attributes.Organization);
	Query.SetParameter("RegistrationCountry",                 Attributes.RegistrationCountry);
	Query.SetParameter("Counterparty",                        Attributes.Counterparty);
	Query.SetParameter("Products",                      Attributes.Products);
	Query.SetParameter("Characteristic",                    Attributes.Characteristic);
	Query.SetParameter("Warehouse",                             Attributes.Warehouse);
	Query.SetParameter("Series",                             Attributes.Series);
	Query.SetParameter("Purpose",                        Attributes.Purpose);
	Query.SetParameter("Manager",                          Attributes.Manager);
	Query.SetParameter("Partner",                           Attributes.Partner);
	Query.SetParameter("Department",                     Attributes.Department);
	Query.SetParameter("FinancialAccountingGroup",            Attributes.FinancialAccountingGroup);
	Query.SetParameter("Terms",                        Attributes.Terms);
	Query.SetParameter("UseAgentServiceSale", GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", 
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	Query.SetParameter("LineOfBusiness",           Attributes.LineOfBusiness);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",   Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("Status",                            Undefined);
	Query.SetParameter("MetadataIdentifier",           Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("Comment",					   Attributes.Comment);
	Query.SetParameter("DocumentAmount",					   Attributes.DocumentAmount);
	Query.SetParameter("DeletionMark",				   Attributes.DeletionMark);
	Query.SetParameter("Posted",					   	   Attributes.Posted);
	Query.SetParameter("NumberForPrinting",		   			   Attributes.Number);
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation",             ContractInformation);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("AccountingForIncomeUnderLB",                            Attributes.AccountingForIncomeUnderLB);
	Query.SetParameter("AccountingForLBCosts",                             Attributes.AccountingForLBCosts);
	Query.SetParameter("Author",                                      Attributes.Author);
	Query.SetParameter("AdjustmentPeriod_",                        Attributes.AdjustmentPeriod_);
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	MAX(StageData_1.PaymentDate) AS PaymentDate
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.PaymentScheduleSteps AS StageData_1
	|WHERE
	|	StageData_1.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("PaymentDateSupplier", Attributes.PaymentDate);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, 
		Query.Parameters.Currency,
		Query.Parameters.Period,
		Query.Parameters.Organization);

	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners", InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters));
	
EndProcedure

Procedure SetParameterForProductAccountingAnalystRequest(Query)
	
	If Query.Parameters.Property("ItemsLocationAttributes") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Query.Parameters.Products) Then
		FieldsStructure = New Structure("Products, Characteristic, Series, Warehouse, Purpose");
		FillPropertyValues(FieldsStructure, Query.Parameters);
		
		Query.SetParameter("ItemsLocationAttributes",
						InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(FieldsStructure));
	Else
		Query.SetParameter("ItemsLocationAttributes", Undefined);
	EndIf;
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	InvoiceForOrders     = ?(Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder,
								"TRUE",
								"FALSE");

	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.PaymentScheduleSteps AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON ARAPObjects.Object = Table.Ref
		|		AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	(CASE
		|		WHEN &InvoiceForOrders
		|			THEN Table.SalesOrder.ARAPObject
		|		WHEN DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN Table.ARAPObject.Contract.ARAPObject
		|		ELSE Table.ARAPObject
		|	END) AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	
	QueryTextDocumentExchangeRates = StrReplace(QueryTextDocumentExchangeRates,
								"&InvoiceForOrders",
								InvoiceForOrders);
									
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	HeaderData_.Ref                                                    AS Ref,
		|	HeaderData_.Organization                                               AS Organization,
		|	HeaderData_.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                AS ARAPObject,
		|	Table.PaymentDate                                                   AS PaymentDate,
		|	Table.OrderDocument                                                         AS SalesOrder_,
		|	&InvoiceForOrders                                                   AS InvoiceForOrders,
		|	Table.AmountARAP                                           AS AmountARAP,
		|	0                                                                     AS AmountARAPByPackage,
		|	Table.PaymentAmount                                                  AS Sum,
		|	
		|	HeaderData_.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	HeaderData_.Date                                                      AS RecorderDate,
		|	HeaderData_.Number                                                     AS RecorderNumber,
		|	HeaderData_.Currency                                                    AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)    AS BusinessOperation,
		|	HeaderData_.Date                                                      AS DateOfCourse,
		|	HeaderData_.Currency                                                    AS DocumentCurrency,
		|	Table.PaymentOption                                                 AS PaymentOption,
		|	Table.ExceedingOrder                                                   AS ExceedingOrder,
		|	UNDEFINED                                                          AS LinkedDocument
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.PaymentScheduleSteps AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS HeaderData_
		|		ON Table.Ref = HeaderData_.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	#EndRegion
	
	#Region IncreasePaymentPlan
		
	TextPaymentPlanning = "
		|SELECT
		|	HeaderData_.Ref                                                    AS Ref,
		|	HeaderData_.Organization                                               AS Organization,
		|	HeaderData_.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                AS ARAPObject,
		|	HeaderData_.Date                                                      AS RecorderDate,
		|	HeaderData_.Number                                                     AS RecorderNumber,
		|	HeaderData_.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	HeaderData_.Currency                                                    AS ARAPCurrency,
		|	HeaderData_.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)    AS BusinessOperation,
		|	HeaderData_.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.PaymentDate                                                   AS PaymentDate,
		|	Table.PaymentOption                                                 AS PaymentOption,
		|	Table.AmountARAP                                           AS AmountDue,
		|		
		|	CASE WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|			THEN FALSE
		|		ELSE TRUE
		|	END                                                                 AS ExcludeDuringControl,
		|	&InvoiceForOrders                                                   AS InvoiceForOrders,
		|	Table.OrderDocument                                                         AS SalesOrder_,
		|	Table.ExceedingOrder                                                   AS ExceedingOrder,
		|	UNDEFINED                                                          AS LinkedDocument
		|	
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.PaymentScheduleSteps AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS HeaderData_
		|		ON Table.Ref = HeaderData_.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.AmountARAP > 0";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|
		|	ARAPObjects.Ref                                                   AS CalculationObjectReceiver,
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
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
		|	Document.PurchasingReportToConsignorPrincipal.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ARAPObjects.Object = Table.Ref
		|			AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.DocumentAmount > 0";
	
	#EndRegion
	
	#Region TextProducts_1
	
	TextProducts_1 = "
	
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.Ref.Date                                                      AS DateOfShipment,
		|	0                                                                        AS IncreaseToBeSHIPPED,
		|	Table.AmountARAP                                              AS ReduceShipping,
		|	0                                                                        AS IncreaseShipping,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.AmountARAP                                              AS ReduceToBESHIPPED,
		|
		|	Table.SalesOrder                                                     AS SalesOrder_,
		|	0                                                                        AS DepositForPackage,
		|	FALSE                                                                     AS ExceedingOrder,
		|	&InvoiceForOrders                                                      AS InvoiceForOrders,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)       AS BusinessOperation,
		|	Table.Ref.Currency                                                    AS DocumentCurrency
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	#EndRegion
	
	TextSale           = StrReplace(TextSale,
								"&InvoiceForOrders",
								InvoiceForOrders);
	
	TextPaymentPlanning = StrReplace(TextPaymentPlanning,
								"&InvoiceForOrders",
								InvoiceForOrders);
	
	TextProducts_1 = StrReplace(TextProducts_1,
								"&InvoiceForOrders",
								InvoiceForOrders);
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset, TextProducts_1);
	
	TextPayment = 
		"SELECT
		|	HeaderData_.Ref                                                    AS Ref,
		|	HeaderData_.Organization                                               AS Organization,
		|	HeaderData_.Partner                                                   AS Partner,
		|	
		|	HeaderData_.Currency                                                    AS ARAPCurrency,
		|	Table.ARAPObject                                                AS ARAPObject,
		|	Table.SalesOrder                                                  AS OrderDocument,
		|	-(Table.AmountIncludingVAT)                                                  AS Sum,
		|	-(Table.AmountIncludingVAT)                                                  AS AmountARAP,
		|	0                                                                     AS IncreaseIsPaid,
		|	0                                                                     AS ReductionIsPaid,
		|	
		|	HeaderData_.Date                                                      AS RecorderDate,
		|	HeaderData_.Date                                                      AS DateOfCourse,
		|	DATETIME(1,1,1)                                                      AS MaturityDate,
		|	HeaderData_.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
		|	HeaderData_.PaymentMethod                                               AS PaymentMethod,
		|	UNDEFINED                                                          AS CashFlowItem,
		|	UNDEFINED                                                          AS ProformaInvoice,
		|	HeaderData_.Currency                                                    AS DocumentCurrency,
		|	UNDEFINED                                                          AS LinkedDocument,
		|	Table.ARAPObject.UUID                        AS FinRecordID,
		|	&BusinessTransactionSetting                                       AS BusinessTransactionSetting
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS HeaderData_
		|		ON Table.Ref = HeaderData_.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.AmountIncludingVAT < 0
		|
		|UNION ALL
		|
		|SELECT
		|	HeaderData_.Ref                                                    AS Ref,
		|	HeaderData_.Organization                                               AS Organization,
		|	HeaderData_.Partner                                                   AS Partner,
		|	
		|	HeaderData_.Currency                                                    AS ARAPCurrency,
		|	Table.ARAPObject                                                AS ARAPObject,
		|	Table.SalesOrder                                                  AS OrderDocument,
		|	-(Table.CommissionAmount)                                        AS Sum,
		|	-(Table.CommissionAmount)                                        AS AmountARAP,
		|	0                                                                     AS IncreaseIsPaid,
		|	0                                                                     AS ReductionIsPaid,
		|	
		|	HeaderData_.Date                                                      AS RecorderDate,
		|	HeaderData_.Date                                                      AS DateOfCourse,
		|	DATETIME(1,1,1)                                                      AS MaturityDate,
		|	HeaderData_.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
		|	HeaderData_.PaymentMethod                                               AS PaymentMethod,
		|	UNDEFINED                                                          AS CashFlowItem,
		|	UNDEFINED                                                          AS ProformaInvoice,
		|	HeaderData_.Currency                                                    AS DocumentCurrency,
		|	UNDEFINED                                                          AS LinkedDocument,
		|	Table.ARAPObject.UUID                        AS FinRecordID,
		|	&BusinessTransactionSetting                                       AS BusinessTransactionSetting
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS Table
		|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS HeaderData_
		|		ON Table.Ref = HeaderData_.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.CommissionAmount < 0";
		
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment,"2");
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	CASE
	|		WHEN DocumentTable.TaxInvoiceDate = DATETIME(1,1,1)
	|			THEN DocumentTable.Ref.Date
	|		ELSE DocumentTable.TaxInvoiceDate
	|	END AS VATBasePeriod,
	|	CASE
	|		WHEN DocumentTable.TaxInvoiceDate = DATETIME(1,1,1)
	|			THEN DocumentTable.Ref.Date
	|		ELSE DocumentTable.TaxInvoiceDate
	|	END AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountIncludingVAT AS AmountARAP,
	|	DocumentTable.VATAmount AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Remuneration"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowIDRemuneration AS RowID,
	|	DocumentTable.CommissionAmount - DocumentTable.AmountVATRemuneration AS AmountExcludingVAT,
	|	DocumentTable.Ref.VATRateOfRemuneration AS VATRate,
	|	DocumentTable.AmountVATRemuneration AS VATAmount,
	|	DocumentTable.CommissionAmount AS AmountARAP,
	|	DocumentTable.AmountVATRemuneration  AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.CommissionAmount <> 0
	|
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	VALUE(Enum.BusinessTransactions.DeliveryForPrincipal) AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsAndServicesToRegisterPurchasingReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.DocumentAcquisitions AS DocumentAcquisitions,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	&ARAPCurrency AS Currency,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.VATAmount AS VATAmount,
	|	CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN Amounts.AmountExcludingVATCompl + Amounts.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN Amounts.AmountExcludingVATMan + Amounts.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|	TRUE AS Primary,
	|	GoodsTable.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	GoodsTable.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(Assignments.ConsiderVATRates, FALSE)
	|			THEN GoodsTable.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS GoodsTable
	|LEFT JOIN
	|	TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|ON
	|	GoodsTable.Ref = Amounts.Ref
	|	AND GoodsTable.RowID = Amounts.RowID
	|LEFT JOIN
	|	Catalog.Assignments AS Assignments
	|ON
	|	GoodsTable.Purpose = Assignments.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
		"// Return of goods to the supplier.
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.PurchasingReportToThePrincipal) AS BusinessOperation,
		|	DocumentHeader.Organization AS Organization,
		|	DocumentHeader.Department AS Department,
		|	DocumentHeader.Manager AS Manager,
		|
		|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTable.ItemsLocationAttributes.StorageLocation AS Warehouse,
		|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
		|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	
		|	DocumentHeader.Partner AS Partner,
		|	DocumentHeader.Counterparty AS Counterparty,
		|	DocumentHeader.Terms AS Terms,
		|	DocumentHeader.Contract AS Contract,
		|	CASE
		|		WHEN GoodsTable.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
		|			THEN GoodsTable.SalesOrder
		|		ELSE &Ref
		|	END AS OrderDocument,
		|
		|	GoodsTable.Purpose.LineOfBusiness AS ProductLineOfBusiness,
		|	DocumentHeader.LineOfBusiness AS CounterpartyLineOfBusiness,
		|
		|	GoodsTable.Count AS Count,
		|
		|	CAST(GoodsTable.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST((GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
		|	CAST(GoodsTable.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST((GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
		|	0 AS DiscountAmount,
		|
		|	CAST(GoodsTable.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Cost,
		|	CAST((GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS CostExcludingVAT,
		|	CAST((GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|
		|	DocumentHeader.Currency AS DocumentCurrency,
		|	GoodsTable.AmountIncludingVAT AS AmountInDocumentCurrency,
		|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVATInDocumentCurrency,
		|
		|	DocumentHeader.Currency AS ARAPCurrency,
		|	GoodsTable.AmountIncludingVAT AS AmountInARAPCurrency,
		|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVATInARAPCurrency,
		|
		|	CASE
		|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
		|			THEN GoodsTable.InventoryOwnerAttribute
		|		ELSE GoodsTable.Products
		|	END AS SourceOfProductFinancialAccountingGroup,
		|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS GoodsTable
		|	LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS DocumentHeader
		|		ON GoodsTable.Ref = DocumentHeader.Ref
		|WHERE
		|	GoodsTable.Ref = &Ref
		|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableOfGoods.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	&Period                                   AS Period,
	|	DimensionByBusinessUnits.DimensionKey   AS ItemsLocationAttributes,
	|	&Organization                              AS Organization,
	|	TableOfGoods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableOfGoods.CCDNumber                   AS CCDNumber,
	|	TableOfGoods.Count                 AS Count,
	|	TableOfGoods.QuantityByGBRN           AS QuantityByGBRN,
	|	VALUE(Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale) AS BusinessOperation,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.Characteristic             AS Characteristic,
	|	VALUE (Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	TableOfGoods.DocumentAcquisitions       AS DocumentSalesOfGoodsAndServices
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS TableOfGoods
	|
	|	INNER JOIN Document.PurchasingReportToConsignorPrincipal AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|
	|	INNER JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnits
	|	ON DimensionByBusinessUnits.Products = TableOfGoods.Products
	|		AND DimensionByBusinessUnits.Characteristic = TableOfGoods.Characteristic
	|		AND DimensionByBusinessUnits.Purpose = TableOfGoods.Purpose
	|		AND DimensionByBusinessUnits.StorageLocation = VALUE(Catalog.BusinessStructure.EmptyRef)
	|
	|WHERE
	|	TableOfGoods.Ref = &Ref
	|	AND ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND ProductData_1.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);

	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	TextProducts_1 = 
	"SELECT
	|	Goods.Ref                          AS Ref,
	|	Goods.Ref.Organization              AS Organization,
	|	Goods.Products                    AS Products,
	|	Goods.Characteristic                  AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)                           AS Series,
	|	VALUE(Catalog.Products.EmptyRef)                           AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef)                           AS ItemVariantOfSet,
	|	Goods.Products.FEACNCode                           AS FEACNCode,
	|	Goods.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	Goods.Ref.Date                     AS Period,
	|	FALSE                                   AS ErrorCorrection,
	|	FALSE                                   AS AdjustmentUnderApprovalOfParties,
	|	Goods.Ref                          AS DocumentSalesOfGoodsAndServices,
	|	CASE WHEN Goods.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                  AS VATTaxation,
	|	Goods.Ref.Department            AS Department,
	|	Goods.Ref.Counterparty               AS Counterparty,
	|	Goods.Ref.Contract                  AS Contract,
	|	Goods.Ref.Organization              AS Shipper,
	|	Goods.Ref.Counterparty               AS GoodsRecipient,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR Goods.NumberOfPackages = 0
	|			THEN Goods.Count
	|		ELSE Goods.NumberOfPackages
	|	END                                  AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Goods.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END                                  AS UnitOfMeasure,
	|	Goods.QuantityByGBRN                AS QuantityByGBRN,
	|	""""                                   AS Content,
	|	Goods.VATRate                       AS VATRate,
	|	Goods.CCDNumber                        AS CCDNumber,
	|	Goods.DocumentAcquisitions            AS DocumentAcquisitions,
	|	Goods.VendorInvoiceReceived           AS VendorInvoiceReceived,
	|	Goods.LineNumber		               AS LineNumber,
	|	Goods.RowID             AS RowID
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS Goods
	|WHERE
	|	Goods.Ref IN (&Ref)
	|";
	TextProducts_1 = StrReplace(
		TextProducts_1,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Goods.Package",
			"Goods.Products"));
	
	VATAccountingERP.ReflectReportToPurchasingCommittee(Query, QueryTexts, Registers, TextProducts_1);

	TextReward = 
	"SELECT
	|	ConsignmentReportToVendor.Date                    AS Period,
	|	ConsignmentReportToVendor.Ref                  AS Ref,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor) AS BusinessOperation,
	|	ConsignmentReportToVendor.Organization             AS Organization,
	|	ConsignmentReportToVendor.Department           AS Department,
	|	ConsignmentReportToVendor.Counterparty              AS Counterparty,
	|	ConsignmentReportToVendor.Contract                 AS Contract,
	|	UNDEFINED                           AS ConsignedGoodsCustomer,
	|	FALSE                                   AS SalesViaCommissionAgent,
	|	UNDEFINED                           AS Shipper,
	|	UNDEFINED                           AS GoodsRecipient,
	|	FALSE                                   AS RetailSaleOfGoods,
	|	ConsignmentReportToVendor.Ref                  AS DocumentSalesOfGoodsAndServices,
	|	FALSE                                   AS ErrorCorrection,
	|	FALSE                                   AS AdjustmentUnderApprovalOfParties,
	|	UNDEFINED                           AS ImplementationAdjustmentDocument,
	|	ReportToCommitteeProducts.ARAPObject    AS ARAPObject,
	|	CASE WHEN VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                  AS VATTaxation,
	|	
	|	ConsignmentReportToVendor.OperationService                                        AS Products,
	|	UNDEFINED                                                 AS Characteristic,
	|	UNDEFINED                                                 AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	""""                                                         AS Content,
	|	0                                                            AS Count,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)   AS UnitOfMeasure,
	|	0                                                            AS QuantityByGBRN,
	|	0                                                            AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)                  AS CCDNumber,
	|	ConsignmentReportToVendor.VATRateOfRemuneration                       AS VATRate,
	|	UNDEFINED                                                 AS FEACNCode,
	|	UNDEFINED                                                 AS InventoryOwnerAttribute,
	|	ReportToCommitteeProducts.LineNumber                             AS LineNumber,
	|	ReportToCommitteeProducts.RowIDRemuneration             AS RowID,
	|	ReportToCommitteeProducts.RowIDRemuneration             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignmentReportToVendor) AS BusinessTransactionSetting
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS ReportToCommitteeProducts
	|		LEFT JOIN Document.PurchasingReportToConsignorPrincipal AS ConsignmentReportToVendor
	|		ON (ConsignmentReportToVendor.Ref = ReportToCommitteeProducts.Ref)
	|WHERE
	|	ConsignmentReportToVendor.Ref IN(&Ref)
	|	AND ReportToCommitteeProducts.CommissionAmount <> 0
	|";
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, TextReward);
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.Purpose.OrderDocument AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	0 AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	-GoodsTable.AmountIncludingVAT AS Sum
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT (GoodsTable.Purpose.OrderDocument = UNDEFINED
	|	OR NOT GoodsTable.Purpose.OrderDocument REFS Document.SalesOrder
	|	OR GoodsTable.Purpose.OrderDocument = VALUE(Document.SalesOrder.EmptyRef))
	|	AND GoodsTable.AmountIncludingVAT <> 0
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountsOfDocumentsInAccountingCurrencies", QueryTexts) Then
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	SetParameterForProductAccountingAnalystRequest(Query);
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	
	QueryText =
	"SELECT
	|	DocumentDataProducts.LineNumber             AS LineNumber,
	|	&Period                                       AS Period,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	&AccountingDimensionByPartners                    AS AccountingDimensionByPartners,
	|	CASE WHEN &AccountingForIncomeUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	DocumentDataProducts.SalesOrder            AS SalesOrder,
	|	&ItemsLocationAttributes                   AS ItemsLocationAttributes,
	|	CASE WHEN &AccountingForLBCosts THEN
	|		&LineOfBusiness
	|	END AS ProductLineOfBusiness,
	|	DocumentData.Department                 AS Department,
	|	VALUE(Enum.InventoryTypes.OperationService)     AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	CASE
	|		WHEN DocumentData.VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN DocumentData.VATRateOfRemuneration = &ExportVATRate
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN DocumentData.VATRateOfRemuneration = &ExportVATRate
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END AS VATTaxation,
	|
	|	&Manager AS Manager,
	|
	|	&BusinessOperation                        AS BusinessOperation,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 
	|		CAST(DocumentDataProducts.CommissionAmount 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan,
	|		CAST((DocumentDataProducts.CommissionAmount 
	|				- DocumentDataProducts.AmountVATRemuneration)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl,
	|		CAST((DocumentDataProducts.CommissionAmount
	|				- DocumentDataProducts.AmountVATRemuneration)
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl,
	|		CAST(DocumentDataProducts.CommissionAmount 
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.Terms               AS Terms,
	|
	|	DocumentData.Currency                   AS ARAPCurrency,
	|	DocumentDataProducts.CommissionAmount      AS AmountInARAPCurrency,
	|	DocumentDataProducts.CommissionAmount - DocumentDataProducts.AmountVATRemuneration AS AmountExcludingVATInARAPCurrency,
	|
	|	DocumentData.Currency                   AS DocumentCurrency,
	|	DocumentDataProducts.CommissionAmount      AS AmountInDocumentCurrency,
	|	DocumentDataProducts.CommissionAmount - DocumentDataProducts.AmountVATRemuneration AS AmountExcludingVATInDocumentCurrency,
	|
	|	DocumentData.OperationService                   AS SourceOfProductFinancialAccountingGroup,
	|	DocumentDataProducts.ARAPObject     AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	DocumentDataProducts.RowIDRemuneration AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignmentReportToVendor) AS BusinessTransactionSetting,
	|	DocumentDataProducts.VATRate           AS VATRate
	|
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS DocumentDataProducts
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		DocumentDataProducts.Ref = Amounts.Ref
	|		AND DocumentDataProducts.RowIDRemuneration = Amounts.RowID
	|	
	|	LEFT JOIN
	|		Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|	ON
	|		DocumentDataProducts.Ref = DocumentData.Ref
	|WHERE
	|	DocumentDataProducts.Ref = &Ref
	|	AND DocumentDataProducts.CommissionAmount <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction


Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.PurchasingReportToConsignorPrincipal";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
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

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("Update", Metadata.Documents.PurchasingReportToConsignorPrincipal) Then
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ mua hàng đại lý';
										|ru = 'Акт об оказании услуг агентской закупки';
										|en = 'Certificate of delivered agent purchase services'; fa = 'Certificate of delivered agent purchase services';
										|it = 'Atto di prestazione di servizi di acquisti in regime di agenzia';
										|pl = 'Protokół świadczenia usług zakupu agencyjnego';
										|tr = 'Ajans satın alma hizmetlerine ilişkin rapor'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;

	If Not UserRightsCached.ThisIsPartner() Then
		// Report to the Committee on purchases
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
		PrintCommand.Id = "PurchasingReportToConsignorPrincipal";
		PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
										|ru = 'Отчет комитенту (принципалу) о закупках';
										|en = 'Purchase notification'; fa = 'اعلان خرید';
										|it = 'Report al committente (mandante) sugli acquisti';
										|pl = 'Raport komitentowi (zleceniodawcy) o zakupach';
										|tr = 'Satın alımlara ilişkin yetkiliye (iş verene) rapor'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
												|ru = 'Отчет комитенту (принципалу) о закупках';
												|en = 'Purchase notification'; fa = 'اعلان خرید';
												|it = 'Report al committente (mandante) sugli acquisti';
												|pl = 'Raport komitentowi (zleceniodawcy) o zakupach';
												|tr = 'Satın alımlara ilişkin yetkiliye (iş verene) rapor'");
	EndIf;

	PurchasingReportToConsignorPrincipalLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to the objects that you want to print.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value-reference to the object.
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Act") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ';
																								|ru = 'Акт об оказании услуг';
																								|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																								|it = 'Atto di prestazione dei servizi';
																								|pl = 'Protokół świadczenia usług';
																								|tr = 'Hizmet tutanağı'"),
			FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	PurchasingReportToConsignorPrincipalLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.PurchasingReportToConsignorPrincipal.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	PurchasingReportToConsignorPrincipalLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
			
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"PurchasingReportToConsignorPrincipal");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.PurchasingReportToConsignorPrincipal", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommissionReports.CreatePrintedFormForPurchaseReport(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"Act");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.PurchasingReportToConsignorPrincipal", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormOfActOnProvisionOfServices(PrintKit.Objects, PrintObjects));
	EndDo;
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "PurchasingReportToConsignorPrincipal", NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																															|ru = 'Отчет комитенту (принципалу) о закупках';
																															|en = 'Purchase notification'; fa = 'اعلان خرید';
																															|it = 'Report al committente (mandante) sugli acquisti';
																															|pl = 'Raport komitentowi (zleceniodawcy) o zakupach';
																															|tr = 'Satın alımlara ilişkin yetkiliye (iş verene) rapor'"), 2);
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ';
																							|ru = 'Акт об оказании услуг';
																							|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																							|it = 'Atto di prestazione dei servizi';
																							|pl = 'Protokół świadczenia usług';
																							|tr = 'Hizmet tutanağı'"),                                       2);
	
	PurchasingReportToConsignorPrincipalLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

Function FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.OperationService.DescriptionFull AS Service_Name,
	|	DocumentData.OperationService.Code AS Code,
	|	DocumentData.OperationService.SKU AS SKU,
	|
	|	DocumentData.CommissionAmount AS Sum,
	|	DocumentData.VATRateOfRemuneration AS VATRate,
	|	DocumentData.AmountVATRemuneration AS VATAmount
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|");
		
	Query.SetParameter("DocumentsArray", ObjectsArray);
		
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTING_ReportToCommittee_ActOnServices";
	
	Template = PrintManagement.PrintFormTemplate("Document.PurchasingReportToConsignorPrincipal.PF_MXL_CertificateOfServices");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	PrintData = Query.Execute().Select();
	FirstDocument = True;
	While PrintData.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We output the general details of the header.
		TableHeading = Template.GetArea("Header");
		
		SupplierInformation = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date);
		InformationOnRecipient = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date);
		
		SetParameter(TableHeading, "SupplierPresentation",
			PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr,"));
		SetParameter(TableHeading, "RecipientPresentation1",
			PrintFormGeneration.OrganizationDescription(InformationOnRecipient, "FullDescr,"));
		SetParameter(TableHeading, "TitleText",
			TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Biên bản cung cấp dịch vụ';
																			|ru = 'Акт об оказании услуг';
																			|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																			|it = 'Atto di prestazione dei servizi';
																			|pl = 'Protokół świadczenia usług';
																			|tr = 'Hizmet tutanağı'", Common.DefaultLanguageCode())));
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TableHeading, PrintData.Ref);
		SpreadsheetDocument.Put(TableHeading);
			
		// Output the table.
		If ValueIsFilled(NameOfCodeColumn) Then
			TemplateArea = Template.GetArea("StringWithCodes");
			SetParameter(TemplateArea, "NameOfCodeColumn", PresentationOfCodesColumn);
			SetParameter(TemplateArea, "SKU", PrintData[NameOfCodeColumn]);
		Else
			TemplateArea = Template.GetArea("String");
		EndIf;
		TemplateArea.Parameters.Fill(PrintData);
		
		SpreadsheetDocument.Put(TemplateArea);	
		
		// We output the details of the basement.
		BasementArea_ = Template.GetArea("Footer");
		
		TextAboutAmountInWords = NStr("vi = 'Số tiền hoa hồng ký gửi là';
										|ru = 'Сумма комиссионного вознаграждения составила';
										|en = 'Commission equals'; fa = 'Commission equals';
										|it = 'Importo della provvigione è di';
										|pl = 'Wysokość wynagrodzenia prowizyjnego wyniosła';
										|tr = 'Komisyon miktarı şu şekildedir'", Common.DefaultLanguageCode()) + " "
			+ ?(PrintData.Sum < 0, NStr("vi = 'trừ';
										|ru = 'минус';
										|en = 'minus'; fa = 'minus';
										|it = 'meno';
										|pl = 'minus';
										|tr = 'eksi'", Common.DefaultLanguageCode()) + " ", "")
			+ ProcessingOfExchangeRatesTM.GenerateAmountInWords(PrintData.Sum, PrintData.Currency) + ","
			+ Chars.LF
			+ NStr("vi = 'Trong đó thuế GTGT (';
					|ru = 'в том числе НДС (';
					|en = 'including VAT ('; fa = 'including VAT (';
					|it = 'compreso IVA (';
					|pl = 'w tym VAT (';
					|tr = 'KDV dahil ('", Common.DefaultLanguageCode())	+ PrintData.VATRate + ") "
			+ Format(PrintData.VATAmount, "NFD=2") + " " + PrintData.Currency;
		
		SetParameter(BasementArea_, "TextAboutAmountInWords", TextAboutAmountInWords);
		
		SpreadsheetDocument.Put(BasementArea_);	
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			PrintData.Ref);
		
	EndDo;
		
	Return SpreadsheetDocument;

EndFunction

// Returns data for the formation of a printed form "Report to the purchasing committee".
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array of DocumentRef.PurchasingReportToConsignorPrincipal - links to documents for which you need
//																		to get data.
//
// Returns:
//	Structure - a collection of data used when printing the UPD, containing the following properties:
//		* Title - String - Report header.
//		* HeaderResults - QueryResult - general data of the document.
//		* ResultForTabularPart - QueryResult - data of the tabular part of the document.
//		* DocumentTraceabilityData - ValueTable - a table containing information about the traceability of the document, with the following columns:
//			** Ref - DocumentRef.PurchasingReportToConsignorPrincipal - link to the document.
//			** ThereIsRNPT - Boolean - indicates that the document contains traceability information.
//		* TraceableComponents - ValueTable - - description of the table of information on traceable components, with the following columns:
//			** CCDNumber - CatalogRef.CCDNumbers - link to the RPT number of the kit.
//			** ProductBatchIDNumber - String - product registration number.
//			** QuantityByGBRN - Number - the standard number of components per unit of the kit.
//			** FEACNUnitOfMeasure - String - name of the unit of measurement.
//
Function GetDataForPrintedProcurementReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PurchasingReportToConsignorPrincipal.Ref					AS Ref,
	|	PurchasingReportToConsignorPrincipal.Number					AS Number,
	|	PurchasingReportToConsignorPrincipal.Date					AS Date,
	|	PurchasingReportToConsignorPrincipal.Counterparty				AS Consignor,
	|	PurchasingReportToConsignorPrincipal.Organization				AS Consignee,
	|	PurchasingReportToConsignorPrincipal.Organization.Prefix		AS Prefix,
	|	PurchasingReportToConsignorPrincipal.Contract					AS Contract,
	|	PurchasingReportToConsignorPrincipal.Currency					AS Currency,
	|	PurchasingReportToConsignorPrincipal.CommissionAmount		AS CommissionAmount,
	|	PurchasingReportToConsignorPrincipal.AmountVATRemuneration	AS AmountVATRemuneration,
	|	PurchasingReportToConsignorPrincipal.RemunerationPercentage	AS RemunerationPercentage,
	|	CASE
	|		WHEN PurchasingReportToConsignorPrincipal.VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				OR PurchasingReportToConsignorPrincipal.VATRateOfRemuneration = VALUE(Catalog.VATRates.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END											AS ThereIsRewardRate,
	|	CASE
	|		WHEN PurchasingReportToConsignorPrincipal.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN FALSE
	|		ELSE TRUE
	|	END											AS SaleIsSubjectToVAT,
	|	""""											AS CommitteeRepresentative,
	|	PurchasingReportToConsignorPrincipal.Manager.Individual AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal AS PurchasingReportToConsignorPrincipal
	|WHERE
	|	PurchasingReportToConsignorPrincipal.Ref IN(&DocumentsArray)
	|	AND PurchasingReportToConsignorPrincipal.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref												AS Ref,
	|	MAX(NestedQuery.LineNumber)								AS LineNumber,
	|	NestedQuery.Products										AS Products,
	|	NestedQuery.Products.DescriptionFull						AS ProductItemName,
	|	NestedQuery.Products.Code									AS Code,
	|	NestedQuery.Products.SKU								AS SKU,
	|	NestedQuery.CCDNumber.UnitOfMeasure.Presentation				AS FEACNUnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull					AS Characteristic,
	|	NestedQuery.UnitOfMeasure.Presentation						AS UnitOfMeasurementName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END																AS Package,
	|	SUM(NestedQuery.Count)									AS Count,
	|	SUM(NestedQuery.QuantityByGBRN)								AS QuantityByGBRN,
	|	NestedQuery.Price												AS Price,
	|	SUM(NestedQuery.ConsignorAmount)								AS ConsignorAmount,
	|	NestedQuery.VATRate											AS VATRate,
	|	SUM(NestedQuery.AmountIncludingVAT)									AS AmountIncludingVAT,
	|	SUM(NestedQuery.VATAmount)										AS VATAmount,
	|	SUM(NestedQuery.CommissionAmount)							AS CommissionAmount,
	|	NestedQuery.RemunerationPercentage								AS RemunerationPercentage,
	|	NestedQuery.CCDNumber											AS CCDNumber,
	|	NestedQuery.CCDNumber.CCDNumberType								AS CCDNumberType,
	|	NestedQuery.CCDNumber.Presentation								AS ProductBatchIDNumber,
	|	NestedQuery.TaxInvoiceDate									AS TaxInvoiceDate,
	|	NestedQuery.Vendor											AS Vendor
	|FROM
	|	(SELECT
	|		GoodsTable.Ref						AS Ref,
	|		GoodsTable.LineNumber					AS LineNumber,
	|		GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsTable.Products					AS Products,
	|		CASE
	|			WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsTable.Products.UnitOfMeasure
	|			ELSE GoodsTable.Package
	|		END										AS UnitOfMeasure,
	|		GoodsTable.Characteristic				AS Characteristic,
	|		GoodsTable.Package						AS Package,
	|		GoodsTable.NumberOfPackages			AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsTable.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE GoodsTable.QuantityByGBRN
	|		END										AS QuantityByGBRN,
	|		GoodsTable.Price							AS Price,
	|		CASE
	|			WHEN GoodsTable.Ref.PriceIncludesVAT
	|				THEN GoodsTable.AmountIncludingVAT
	|		ELSE
	|			GoodsTable.Sum
	|		END										AS ConsignorAmount,
	|		GoodsTable.VATRate						AS VATRate,
	|		GoodsTable.AmountIncludingVAT						AS AmountIncludingVAT,
	|		GoodsTable.VATAmount						AS VATAmount,
	|		GoodsTable.CommissionAmount			AS CommissionAmount,
	|		CASE
	|			WHEN GoodsTable.CommissionAmount <> 0
	|				THEN GoodsTable.CommissionAmount / (GoodsTable.AmountIncludingVAT / 100)
	|			ELSE 0
	|		END										AS RemunerationPercentage,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsTable.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|			ELSE GoodsTable.CCDNumber
	|		END										AS CCDNumber,
	|		GoodsTable.TaxInvoiceDate				AS TaxInvoiceDate,
	|		GoodsTable.Vendor						AS Vendor
	|	FROM
	|		Document.PurchasingReportToConsignorPrincipal.Goods AS GoodsTable
	|	
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|		AND GoodsTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|														VALUE(Enum.ItemsTypes.Work_5))
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.UnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.Price,
	|	NestedQuery.VATRate,
	|	NestedQuery.RemunerationPercentage,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.TaxInvoiceDate,
	|	NestedQuery.Vendor
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(ConsignorAmount),
	|	SUM(CommissionAmount),
	|	SUM(AmountIncludingVAT),
	|	SUM(VATAmount)
	|BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref	AS Ref,
	|	MAX(CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND ISNULL(Goods.CCDNumber.CCDNumberType, UNDEFINED) IN(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|																		VALUE(Enum.CCDNumberTypes.KitRNPT))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)			AS ThereIsRNPT
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS Goods
	|
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	Goods.Ref
	|
	|ORDER BY
	|	Goods.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 
	|SELECT DISTINCT
	|	DocumentTable.CCDNumber							AS CCDNumber,
	|	CASE
	|		WHEN Components.ProductBatchIDNumber.RegistrationNumber = """"
	|			THEN Components.ProductBatchIDNumber
	|		ELSE Components.ProductBatchIDNumber.RegistrationNumber
	|	END												AS ProductBatchIDNumber,
	|	Components.QuantityByGBRN						AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure
	|FROM
	|	Document.PurchasingReportToConsignorPrincipal.Goods AS DocumentTable
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON DocumentTable.CCDNumber = Components.Ref";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"NestedQuery.Package",
									"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Title = NStr("vi = 'Bảng kê dành cho người đặt ký gửi về việc mua hàng';
				|ru = 'Отчет комитенту о закупках';
				|en = 'Purchase notification'; fa = 'اعلان خرید';
				|it = 'Report sugli acquisti al committente';
				|pl = 'Raport do komisanta o zakupach';
				|tr = 'Satın alma bildirimi'", Common.DefaultLanguageCode());
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderResults					= ResultsArray[0]; // QueryResult - 
	ResultForTabularPart			= ResultsArray[ResultsArray.UBound() - 2]; // QueryResult - 
	DocumentTraceabilityData	= ResultsArray[ResultsArray.UBound() - 1].Unload(); // ValueTable - 
	TraceableComponents			= ResultsArray[ResultsArray.UBound()].Unload(); // ValueTable - 
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("Title",							Title);
	DataStructureForPrinting.Insert("HeaderResults",					HeaderResults);
	DataStructureForPrinting.Insert("ResultForTabularPart",			ResultForTabularPart);
	DataStructureForPrinting.Insert("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataStructureForPrinting.Insert("TraceableComponents",		TraceableComponents);
	
	Return DataStructureForPrinting;
	
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
	
EndProcedure

// Other

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

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
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
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

Function MetadataOfDocument() Export
	
	ObjectStructure = LinesOfBusinessServer.ObjectStructure();
	ObjectStructure.IssuedByOrder = False;
	
	Return ObjectStructure;
	
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.PurchasingReportToConsignorPrincipal - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "SELECT
	|	Goods.SalesOrder          AS SalesOrder,
	|	FALSE                         AS ExceedingOrder,
	|	Goods.AmountIncludingVAT             AS PaymentAmount,
	|	&OrderingCaps                  AS Order_Header
	|INTO TTProducts_11
	|FROM
	|	&ValueTable AS Goods
	|WHERE Goods.AmountIncludingVAT > 0
	|	AND &LinkCondition_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.SalesOrder          AS SalesOrder,
	|	CASE
	|		WHEN Goods.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                        AS ExceedingOrder,
	|	Goods.CommissionAmount   AS PaymentAmount,
	|	&OrderingCaps                  AS Order_Header
	|INTO TTProducts_12
	|FROM
	|	&ValueTable AS Goods
	|WHERE Goods.CommissionAmount > 0
	|	AND &LinkCondition_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_11.SalesOrder       AS SalesOrder,
	|	TTProducts_11.ExceedingOrder        AS ExceedingOrder,
	|	TTProducts_11.PaymentAmount       AS PaymentAmount,
	|	TTProducts_11.Order_Header         AS OrderingCaps
	|INTO TTProducts_1
	|FROM
	|	TTProducts_11 AS TTProducts_11
	|
	|UNION ALL
	|
	|SELECT
	|	TTProducts_12.SalesOrder,
	|	TTProducts_12.ExceedingOrder,
	|	TTProducts_12.PaymentAmount,
	|	TTProducts_12.Order_Header
	|FROM
	|	TTProducts_12 AS TTProducts_12
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN ISNULL(TTProducts_1.SalesOrder.Number, """") = """"
	|				THEN TTProducts_1.OrderingCaps
	|			ELSE TTProducts_1.SalesOrder
	|	END                        AS OrderDocument,
	|	CASE WHEN ISNULL(TTProducts_1.SalesOrder.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.SalesOrder.DATE, DATETIME(1,1,1))
	|	END                        AS OrderDate,
	|	CASE WHEN ISNULL(TTProducts_1.SalesOrder.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.ApprovalDate, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.SalesOrder.ApprovalDate, DATETIME(1,1,1))
	|	END                        AS ApprovalDate,
	|	SUM(TTProducts_1.PaymentAmount) AS PaymentAmount,
	|	SUM(TTProducts_1.PaymentAmount) AS AmountARAP,
	|	TTProducts_1.ExceedingOrder         AS ExceedingOrder,
	|	0                            AS PackageDepositValue,
	|	0                            AS AmountARAPByPackage
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|
	|GROUP BY
	|	CASE WHEN ISNULL(TTProducts_1.SalesOrder.Number, """") = """"
	|				THEN TTProducts_1.OrderingCaps
	|			ELSE TTProducts_1.SalesOrder
	|	END,
	|	CASE WHEN ISNULL(TTProducts_1.SalesOrder.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.SalesOrder.DATE, DATETIME(1,1,1))
	|	END,
	|	CASE WHEN ISNULL(TTProducts_1.SalesOrder.Number, """") = """"
	|				THEN ISNULL(TTProducts_1.OrderingCaps.ApprovalDate, DATETIME(1,1,1))
	|			ELSE ISNULL(TTProducts_1.SalesOrder.ApprovalDate, DATETIME(1,1,1))
	|	END,
	|	TTProducts_1.ExceedingOrder";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.PurchasingReportToConsignorPrincipal.Goods");
		Query.Text = StrReplace(Query.Text, "&OrderingCaps", "Goods.Ref.SalesOrder");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf
