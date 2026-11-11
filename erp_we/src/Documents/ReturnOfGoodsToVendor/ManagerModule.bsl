#If Not MobileStandaloneServer Then
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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses"); // for the formation of Registered Records for deviations in the cost of goods
	DocumentMechanisms.Add("PreparationOfReportsToPurchasingCommittee");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReturnOfGoodsToVendorLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReturnOfGoodsToVendor") Then
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		ReturnOfGoodsToVendorLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
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

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.Date              AS Date,
	|	Header.Partner           AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	Header.DeliveryMethod    AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|		END               AS Address,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|		END               AS FieldValueAddress,
	|
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	Header.AdditionalDeliveryInformation
	|		                    AS AdditionalInformation,
	|	Header.Warehouse             AS Warehouse,
	|	TRUE                  AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	Document.ReturnOfGoodsToVendor AS Header
	|WHERE
	|	Header.Ref IN (&References)";
	
	Return QueryText;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		CreationCommand = Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
		If CreationCommand <> Undefined Then
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi trả lại nhà cung cấp';
												|ru = 'Акт о расхождениях после возврата поставщику';
												|en = 'Discrepancy report following return to vendor'; fa = 'Discrepancy report following return to vendor';
												|it = 'Atto sulle discrepanze dopo il reso al fornitore';
												|pl = 'Protokół o odchyleniu po zwrotcie do dostawcy';
												|tr = 'Tedarikçiye iade sonrası tutarsızlık raporu'");
		EndIf;
	EndIf;
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.VendorInvoice.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());

	
	ReturnOfGoodsToVendorLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the "Return items to supplier"document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:  
//	 ValueTableRow, Undefined - the command to output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReturnOfGoodsToVendor) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReturnOfGoodsToVendor.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReturnOfGoodsToVendor);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create the "Return items to supplier"document.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnWarehouseGroupCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ReturnOfGoodsToVendor) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReturnOfGoodsToVendor.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateReturnOfGoodsToSupplierBasedOnWarehouseGroup";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReturnOfGoodsToVendor);
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
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingReceived.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	// DocumentsListForm
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingReceived.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Important";
		ReportCommand.Order = 3;
	EndIf;
	
	ReturnOfGoodsToVendorLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Date,BusinessOperation,Organization,Partner";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = FullObjectName();
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentUnderReturnToVendor);
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.ShipmentPlanning = False;
	SeriesSpecificationParameters.SelectionPlanning   = False;
	SeriesSpecificationParameters.FactOfSelection           = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
		SeriesSpecificationParameters.ParametersForGettingDataFromRegisters.Insert("Organization", Object.Organization);
		SeriesSpecificationParameters.ParametersForGettingDataFromRegisters.Insert("Partner", Object.Partner);
	EndIf;

	Return SeriesSpecificationParameters;
	
EndFunction

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
	
	InfluencingAttributes = "BusinessOperation,CompensationMethod";
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, InfluencingAttributes);
		BusinessOperation = StructureFillingData.BusinessOperation;
		CompensationMethod     = StructureFillingData.CompensationMethod;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		CompensationMethod     = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		CompensationMethod     = FillingData.CompensationMethod;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.InfluencingAttributes                = InfluencingAttributes;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)";
	ParametersStructure.ChangesPaymentPlan               = BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	
	ParametersStructure.CourseNumerator                          = "";
	ParametersStructure.CourseDenominator                        = "";
	If CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment Then
		ParametersStructure.ARAPObjectSettings                        = Enums.ARAPObjectSettings.ByARAPDocuments;
	Else
		ParametersStructure.ARAPObjectSettings                            = "Object.Contract.ARAPObjectSettings";
	EndIf;
	ParametersStructure.ConditionalOrderOfCalculations          = 
		"CASE WHEN DataSource.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment) THEN
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|ELSE
		|	CASE
		|		WHEN
		|			DataSource.Contract IN (VALUE(Catalog.CounterpartyContracts.EmptyRef),
		|										VALUE(Catalog.IntercompanyContracts.EmptyRef),
		|										UNDEFINED) THEN
		|				UNDEFINED
		|		ELSE
		|			DataSource.Contract.ARAPObjectSettings
		|	END
		|END
		|";
	
	ParametersStructure.PaymentMethod                      = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.CashAccount                            = ""; 
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Manager                         = "Object.Manager";
	
	ParametersStructure.DocumentAmountForm              = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	
	ParametersStructure.FormItems.HyperlinkPaymentDecryption = "ReducedDebtByLine";
	ParametersStructure.FormItems.LineOfBusiness       = "LineOfBusiness";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	Return ParametersStructure;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND &FactOfSelection
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByReturnToVendor
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON (Warehouses.Ref = BatchAccountingPolicies.Warehouse)
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|				AND BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
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

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ReturnOfGoodsToVendorLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReturnOfGoodsToVendorLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.TermsOfUse_ = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)";
	
	AppointmentTemplateWithoutAgencyPurchase = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	AppointmentTemplateWithoutAgencyPurchase.LineOfBusiness  = "Object.LineOfBusiness";
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.DeliveryForPrincipal));
	
	AppointmentTemplateWithoutAgencyPurchase.TermsOfUse_ = "Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)";
	
	// Remnants of goods in the warehouse.
	
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.Currency = "Object.Currency";
	
	Return FormTemplate;
	
EndFunction

#Region VATAccounting

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.ReturnOfGoodsToVendor - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract; 
	FillParameters.Period  = Object.Date;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor Then
		FillParameters.ReturnOfGoodsToVendor = True;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		FillParameters.ReturnOfGoodsToConsignor = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.ReturnOfGoodsToVendor, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	RegistrationParameters.VATTaxation		= Object.VATTaxation;
	
	If Not ValueIsFilled(Object.Date) Then
		RegistrationParameters.Date = CurrentSessionDate();
	Else
		RegistrationParameters.Date = Object.Date;
	EndIf;
	
	RegistrationParameters.ReturnOfGoodsToVendor = (Not Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	
	Return RegistrationParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.ReturnOfGoodsFromCustomer, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	
	RegistrationParameters.Ref				= Object.Ref;
	RegistrationParameters.Organization		= Object.Organization;
	RegistrationParameters.Counterparty			= Object.Counterparty;
	RegistrationParameters.VATTaxation	= Object.VATTaxation;
	
	If Not ValueIsFilled(Object.Date) Then
		RegistrationParameters.Date = CurrentSessionDate();
	Else
		RegistrationParameters.Date = Object.Date;
	EndIf;
	
	ImportOfGoods = False;
	PurchaseEAEU = False;
	If ValueIsFilled(Object.DocumentInflow) Then
		
		If Object.DocumentInflow.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport Then
			ImportOfGoods = True;
		EndIf;
		
		BusinessTransactionsProcurementInEAEUCountries = PurchasesServerCall.BusinessOperationsOnMain(
				PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
				
		If BusinessTransactionsProcurementInEAEUCountries.Find(Object.DocumentInflow.BusinessOperation) <> Undefined Then 
			PurchaseEAEU = True;
		EndIf;
		
	EndIf;
	
	RegistrationParameters.ReturnOfGoodsFromVATPayer  = (Not Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor)
															And Not ImportOfGoods;
	RegistrationParameters.ImportOfGoodsFromCustomsUnion   = PurchaseEAEU;
	RegistrationParameters.AdjustmentUnderApprovalOfParties = RegistrationParameters.ReturnOfGoodsFromVATPayer;
	
	Return RegistrationParameters;
	
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
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)";

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
		"Organization, Warehouse", Parameters);
	
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
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		If Not AccessRight("Read", Metadata.InformationRegisters.StatesByEDIAccountingObjects)
			Or Not AccessRight("Read", Metadata.InformationRegisters.DocumentsWithCounterpartyCheckErrors) Then
			StandardProcessing = False;
			SelectedForm = "ListForm";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region FillingInDocument_

Function ParametersForCreatingWarehousesByGroup(CommandParameter) Export
	
	Query = New Query();
	
	If TypeOf(CommandParameter) = Type("DocumentRef.GoodsQualityControlCertificate") Then
		
		Query.Text =
		"SELECT ALLOWED DISTINCT
		|	Goods.Warehouse.Ref AS Warehouse
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|	AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn)";
		Query.SetParameter("Ref", CommandParameter);
		
	EndIf;
	
	Warehouses = Query.Execute().Unload().UnloadColumn("Warehouse");
	
	MultipleWarehouses = False;
	If Warehouses.Count() > 1 Then
		MultipleWarehouses = True;
	ElsIf Warehouses.Count() = 0 Then
		Warehouses.Add(Catalogs.Warehouses.EmptyRef()); // when processing the document filling, items will not be filled in, a message will be displayed about the absence of lines with the desired action
	EndIf;
	
	ParametersForCreatingWarehousesByGroup = New Structure();
	ParametersForCreatingWarehousesByGroup.Insert("WarehousesList", Warehouses);
	ParametersForCreatingWarehousesByGroup.Insert("MultipleWarehouses", MultipleWarehouses);
	
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

Procedure FillInListOfBusinessOperations(TransactionList) Export
	
	TransactionList.Clear();
	TransactionList.Add(Enums.BusinessTransactions.ReturnOfGoodsToVendor);
	If GetFunctionalOption("UsePurchaseCommission") Then
		TransactionList.Add(Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	EndIf;
	
EndProcedure

// Returns the value of the props read from the information base by reference to the object
// 
// Parameters:
//  Ref - See Common.ObjectAttributeValue
//  AttributeName - String - The name of the props
// 
// Returns:
//  Boolean - if the received value is not of the boolean type, the value False is returned
Function ValueOfBooleanObjectSProps(Ref, AttributeName) Export
	
	SetPrivilegedMode(True);
	Result = Common.ObjectAttributeValue(Ref, AttributeName);
	If TypeOf(Result) <> Type("Boolean") Then
		Result = False;
	EndIf;
	SetPrivilegedMode(False);
	
	Return Result
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	If RegisterName = "Purchases" Then
		DataSources.Insert("InventoryKinds.ItemsLocationAttributes");
	EndIf;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	DocumentData.Ref                AS Ref,
		|	DocumentData.Number                 AS Number,
		|	DocumentData.Date                  AS Period,
		|	DocumentData.Organization           AS Organization,
		|	DocumentData.Partner               AS Partner,
		|	DocumentData.Counterparty            AS Counterparty,
		|	DocumentData.Currency                AS Currency,
		|	DocumentData.Warehouse                 AS Warehouse,
		|	DocumentData.PriceIncludesVAT       AS PriceIncludesVAT,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.VATTaxation    AS VATTaxation,
		|	DocumentData.Department         AS Department,
		|	DocumentData.Comment           AS Comment,
		|	DocumentData.Posted              AS Posted,
		|	DocumentData.DeletionMark       AS DeletionMark,
		|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	CASE
		|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                 AS UseWarehouseManagemantSystemForGoodsIssue,
		|	
		|	DocumentData.ReturnOfReceivedReusablePackages AS ReturnOfReceivedReusablePackages,
		|	DocumentData.DepositForPackageIsRequired           AS DepositForPackageIsRequired,
		|	
		|	CASE WHEN DocumentData.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ReturnCash) THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END AS ReturnCash,
		|	DocumentData.Manager AS Manager,
		|	DocumentData.Author AS Author,
		|	DocumentData.Contract	AS Contract,
		|	DocumentData.DocumentInflow AS DocumentInflow,
		|	ISNULL(DocumentData.DocumentInflow.PurchaseOrder,
		|		VALUE(Document.PurchaseOrder.EmptyRef)) AS Order_Receipt,	
		|	DocumentData.ARAPObject AS ARAPObject,
		|	DocumentData.ARAPObject.UUID AS IDARAPObject,
		|	DocumentData.Terms AS Terms,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
		|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
		|	DocumentData.DocumentAmount AS DocumentAmount,
		|	PRESENTATION(DocumentData.Contract) AS ContractPresentation,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
		|	,
		|	CASE
		|		WHEN DocumentData.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|			THEN FALSE
		|		WHEN NOT DocumentData.Contract.PurchaseRegistrationOption IS NULL
		|				AND DocumentData.Contract.PurchaseRegistrationOption <> VALUE(Enum.PurchaseRegistrationOptions.NotSeparate)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS UninvoicedReceiptDocumentIsUsed,
		|	UNDEFINED AS AdjustmentPeriod_
		|FROM
		|	Document.ReturnOfGoodsToVendor AS DocumentData
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref = &Ref";
	
	Result =  Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("LocalAccountingCurrency",           Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",               Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
	Query.SetParameter("NumberForPrinting",                            ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("PrintNumber",                 		  ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("MetadataIdentifier",       			  Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("TaxationOfOrganization",               AccountingParametersForOrganization.BasicTaxationVATSales);	
	
	Query.SetParameter("IdApplicationForImportOfGoods",      Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries",           PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU));
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.ContractPresentation);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	&EmptyAssignment          AS Purpose,
	|	Keys.Series                AS Series,
	|	Keys.StorageLocation		   AS Warehouse
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS Goods
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Keys.Products = Dimension.Products
	|	AND Keys.Characteristic = Dimension.Characteristic
	|	AND Keys.Series = Dimension.Series
	|	AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	AND Keys.StorageLocation = Dimension.StorageLocation
	|	AND &EmptyAssignment = Dimension.Purpose
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.Products IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
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
	
	AnalyticsParameters = New Structure;
	AnalyticsParameters.Insert("Organization", 				Query.Parameters.Organization);
	AnalyticsParameters.Insert("Partner",     				Query.Parameters.Partner);
	AnalyticsParameters.Insert("Counterparty",  				Query.Parameters.Counterparty);
	AnalyticsParameters.Insert("Contract",     				Query.Parameters.Contract);
	AnalyticsParameters.Insert("LineOfBusiness", 	Query.Parameters.LineOfBusiness);
	
	Query.SetParameter("AccountingDimensionByPartners",
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters));
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, Undefined, Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts) Export
	TempTableName = "TTTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	Dimension.Products                        AS Products,
	|	Dimension.Characteristic                      AS Characteristic,
	|	Dimension.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	KeysWithoutAssignment.DimensionKey              AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryType                        AS InventoryType,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType      AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount                   AS VATAmount,
	|	TableTypesOfStocks_.VATRate                  AS VATRate,
	|	ISNULL(Amounts.AmountExcludingVATCompl, TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)	AS AmountExcludingVATCompl,	
	|	ISNULL(Amounts.VATAmountCompl, 0)				  AS VATAmountCompl,
	|	ISNULL(Amounts.VATAmountMan, 0)				  AS VATAmountMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)			  AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATBaseLocal, 0)				  AS VATBaseLocal,
	|	TableTypesOfStocks_.RowID        AS RowID,
	|	TableTypesOfStocks_.DocumentInflow        AS DocumentInflow,
	|	(CASE
	|		WHEN ISNULL(Dimension.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) 
	|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Dimension.Purpose.VATActivityType
	|		WHEN TableTypesOfStocks_.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN TableTypesOfStocks_.DocumentInflow.PurchaseForActivity
	|		ELSE &TaxationOfOrganization END)  AS VATActivityType,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.RowID
	|		WHEN &ReturnOfReceivedReusablePackages AND NOT &DepositForPackageIsRequired
	|			AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN TableTypesOfStocks_.RowID
	|		ELSE &IDARAPObject
	|	END                                         AS FinRecordID
	|INTO TTTypesOfStocks
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS TableTypesOfStocks_
	|		
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysWithoutAssignment
	|		ON Dimension.Products = KeysWithoutAssignment.Products
	|			AND Dimension.Characteristic = KeysWithoutAssignment.Characteristic
	|			AND Dimension.Series = KeysWithoutAssignment.Series
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysWithoutAssignment.ProductCostElement
	|			AND Dimension.StorageLocation = KeysWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = KeysWithoutAssignment.Purpose	
	|
	|		LEFT JOIN 
	|			TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON
	|			TableTypesOfStocks_.Ref = Amounts.Ref
	|			AND TableTypesOfStocks_.RowID = Amounts.RowID
	|
	|		LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON InventoryKinds.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, TempTableName);
	Return QueryText;
	
EndFunction

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	UNDEFINED 						AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.ReturnOfGoodsToVendor.Goods AS DocumentGoods
	|		LEFT JOIN Document.ReturnOfGoodsToVendor AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|	AND DocumentGoods.Count <> 0";
		
	MetadataObject	= Metadata.Documents.ReturnOfGoodsToVendor;
	TSSeriesName			= "SetOfSeries";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										TSSeriesName);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	UNDEFINED						AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
 	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ShipmentByOrder
	|	FROM
	|	Document.ReturnOfGoodsToVendor.Goods AS DocumentGoods
	|		LEFT JOIN Document.ReturnOfGoodsToVendor AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	SeriesTable.Products   AS Products,
		|	SeriesTable.Characteristic AS Characteristic,
		|	CASE WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE) THEN
		|				SeriesTable.Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END                   AS Purpose,
		|	SeriesTable.Series          AS Series,
		|	SeriesTable.Count     AS Count,
		|	SeriesTable.Warehouse          AS Sender,
		|	&Partner                    AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ShipmentUnderReturnToVendor) AS WarehouseOperation,
		|	&Ref                     AS Document,
		|	&Period                     AS Period,
		|	&Ref                     AS Recorder,
		|	NOT &UseWarehouseManagemantSystemForGoodsIssue AS ThisIsWarehouseRecord
		|FROM
		|	Document.ReturnOfGoodsToVendor.SetOfSeries AS SeriesTable
		|WHERE
		|	SeriesTable.Ref = &Ref
		|	AND SeriesTable.Count <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SeriesTable.Products   AS Products,
		|	SeriesTable.Characteristic AS Characteristic,
		|	CASE WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE) THEN
		|				SeriesTable.Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END                   AS Purpose,
		|	SeriesTable.Series          AS Series,
		|	SeriesTable.Count     AS Count,
		|	SeriesTable.Warehouse          AS Warehouse,
		|	&Partner                    AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ShipmentUnderReturnToVendor) AS WarehouseOperation,
		|	&Ref                     AS Document,
		|	&Period                     AS Period,
		|	&Ref                     AS Recorder,
		|	NOT &UseWarehouseManagemantSystemForGoodsIssue AS ThisIsWarehouseRecord
		|FROM
		|	Document.ReturnOfGoodsToVendor.Goods AS SeriesTable
		|WHERE
		|	SeriesTable.Ref = &Ref
		|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers)
	RegisterName = "ReceivedReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	InventoryKinds.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	InventoryKinds.Products               AS Products,
	|	InventoryKinds.Characteristic             AS Characteristic,
	|	CASE
	|		WHEN ISNULL(InventoryKinds.ItemsLocationAttributes.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN InventoryKinds.ItemsLocationAttributes.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                 AS Purpose,
	|	InventoryKinds.Count                                AS Count,
	|	CASE
	|		WHEN InventoryKinds.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.DocumentInflow
	|	END                                                 AS DocumentInflow,
	|	InventoryKinds.AmountIncludingVAT                                 AS Sum,
	|	&Partner                                              AS Partner,
	|	&DepositForPackageIsRequired                              AS DepositIsRequired,
	|
	|	CASE
	|		WHEN &DepositForPackageIsRequired
	|			THEN &IDOfUnusedFinRecord
	|		ELSE InventoryKinds.FinRecordID
	|	END                                                 AS FinRecordID,
	|	&BusinessTransactionSetting                       AS BusinessTransactionSetting 
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|WHERE
	|	&ReturnOfReceivedReusablePackages
	|	AND InventoryKinds.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	TableTypesOfStocks_.LineNumber                AS LineNumber,
		|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
		|	&Period                                       AS Period,
		|	&Warehouse                                        AS Warehouse,
		|	&Organization                                  AS ShipmentCompany,
		|	&Organization                                  AS Organization,
		|	TableTypesOfStocks_.Products               AS Products,
		|	TableTypesOfStocks_.Characteristic             AS Characteristic,
		|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
		|	TableTypesOfStocks_.Count                 AS Count,
		|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
		|	&VATTaxation                           AS VATTaxation,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TableTypesOfStocks_.DocumentInflow        AS DocumentSalesOfGoodsAndServices,
		|	&BusinessOperation                        AS BusinessOperation
		|FROM
		|	TTTypesOfStocks AS TableTypesOfStocks_
		|ORDER BY
		|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
		"// Return of goods to the supplier.
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	&Manager AS Manager,
		|
		|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
		|	InventoryKinds.InventoryType AS InventoryType,
		|   InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	
		|	&Partner AS Partner,
		|	&Counterparty AS Counterparty,
		|	&Terms AS Terms,
		|	&Contract AS Contract,
		|	CASE
		|		WHEN &Order_Receipt <> VALUE(Document.PurchaseOrder.EmptyRef)
		|   		THEN &Order_Receipt
		|		ELSE &DocumentInflow
		|	END AS OrderDocument,
		|
		|	InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
		|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
		|		&LineOfBusiness 
		|	END AS CounterpartyLineOfBusiness,
		|
		|	InventoryKinds.Count AS Count,
		|
		|	CAST(InventoryKinds.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
		|	CAST(InventoryKinds.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
		|	0 AS DiscountAmount,
		|
		|	CAST(InventoryKinds.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Cost,
		|	CAST((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS CostExcludingVAT,
		|	CAST((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|
		|	&Currency AS DocumentCurrency,
		|	InventoryKinds.AmountIncludingVAT AS AmountInDocumentCurrency,
		|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVATInDocumentCurrency,
		|
		|	&Currency AS ARAPCurrency,
		|	InventoryKinds.AmountIncludingVAT AS AmountInARAPCurrency,
		|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVATInARAPCurrency,
		|
		|	CASE
		|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
		|			THEN InventoryKinds.InventoryOwnerAttribute
		|		ELSE InventoryKinds.Products
		|	END AS SourceOfProductFinancialAccountingGroup,
		|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
		|FROM
		|	TTTypesOfStocks AS InventoryKinds
		|WHERE
		|	InventoryKinds.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods))
		|";
	
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
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
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
	|	&PrintNumber                         AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReturnOfGoodsToVendor";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("UseWarehouseManagemantSystemForGoodsIssue",
		"	CASE
		|		WHEN GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND GoodsTable.Ref.Date >= GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("PrintNumber",       """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
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
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingDimensionByPartners");
	AdditionalParameters.Add("ConversionRateToManCurrency");
	AdditionalParameters.Add("FactorOfConversionToCurrencyOfRegul");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
		SetRequestParametersCurrencyCoefficients(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Sales_CommissionGoods_GoodsInStorageWithRightToSell
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.VATTaxation 			AS VATActivityType,
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
	|	TableTypesOfStocks_.Count 				AS Count,
	|	TableTypesOfStocks_.RowID		AS RowID,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) THEN
	|		CASE WHEN &Currency = &ManagementAccountingCurrency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount
	|			ELSE CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		END
	|		+
	|		CASE WHEN &Currency = &ManagementAccountingCurrency
	|			THEN TableTypesOfStocks_.VATAmount
	|			ELSE CAST(TableTypesOfStocks_.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		END
	|	ELSE 0
	|	END AS OffBalanceCost,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) THEN
	|		CASE WHEN &Currency = &LocalAccountingCurrency
	|			THEN TableTypesOfStocks_.VATAmount
	|			ELSE CAST(TableTypesOfStocks_.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		END
	|		+
	|		CASE WHEN TableTypesOfStocks_.VATBaseLocal = 0
	|			THEN CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|			ELSE TableTypesOfStocks_.VATBaseLocal
	|		END
	|	ELSE 0
	|	END AS OffBalanceCostLocal,
	|
	// Optional fields
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END AS AccountingSection,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  	AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReturnOfGoodsToVendor AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN
	|		(VALUE(Enum.InventoryTypes.ConsignedGoods),
	|		 VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region DisposalAtFixedCost_Item
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	// Filling in the fields of the types of activity inds and types of activity indsdocument must correspond to filling in the corresponding fields
	// in the function textcurrent turnover of Party goods() of the general module for calculating the cost of filling in parties.
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  	AS CorItemsLocationAttributes,
	|	UNDEFINED 								  	AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner 						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods)  AS IncomeItem,
	|	DocumentTable.Partner 						AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 				AS Count,
	|	TableTypesOfStocks_.RowID 		AS RowID,
	|	TableTypesOfStocks_.AmountExcludingVATMan + TableTypesOfStocks_.VATAmountMan 	AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 									AS CostExcludingVAT,
	|	(CASE
	|		WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		 AND NOT &MovingAverage
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE TableTypesOfStocks_.AmountExcludingVATCompl END)					AS LocalCost,
	|	(CASE
	|		WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		 AND NOT &MovingAverage
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan + TableTypesOfStocks_.VATAmountMan
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan END)					AS CostMan,
	|	0													 				AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END AS AccountingSection,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  	AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReturnOfGoodsToVendor AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	TextProducts_1 =
	"SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.BusinessOperation AS BusinessOperation,
	|	InventoryKinds.Ref.Department AS Department,
	|	InventoryKinds.Ref.Counterparty AS Counterparty,
	|	InventoryKinds.Ref.Contract AS Contract,
	|	InventoryKinds.Ref.GoodsRecipient AS GoodsRecipient,
	|	InventoryKinds.Ref.Shipper AS Shipper,
	|	FALSE AS CustomerVATExempt,
	|	InventoryKinds.Ref AS DocumentReturnPolicy,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Purpose AS Purpose,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN InventoryKinds.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
	|		THEN NULL
	|		ELSE InventoryKinds.DocumentInflow 
	|	END AS DocumentInflow,
	|	InventoryKinds.DocumentInflow.PurchaseForActivity AS VATActivityType,
	|	InventoryKinds.RowID AS RowID,
	|	&IDARAPObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|	AND InventoryKinds.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|	AND (CASE
	|		WHEN InventoryKinds.Ref.ReturnOfReceivedReusablePackages
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|";
	
	VATAccountingERP.ReflectReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextProducts_1);
	
	TextProducts_1 = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType, 
	|	TableTypesOfStocks_.Ref AS Ref,	
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DocumentInflow AS DocumentAcquisitions,
	|	&IdApplicationForImportOfGoods AS ImportDocumentType,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	0 AS QuantityByGBRN,
	|	TableTypesOfStocks_.Count AS Count,
	|	ISNULL(DocumentAmounts_.AmountExcludingVAT, 0) AS Sum,
	|	TRUE AS Primary,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|		ON TableTypesOfStocks_.Ref = DocumentAmounts_.Ref
	|			AND TableTypesOfStocks_.RowID = DocumentAmounts_.RowID
	|		INNER JOIN Document.VendorInvoice AS VendorInvoice
	|		ON TableTypesOfStocks_.DocumentInflow = VendorInvoice.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND VendorInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEU)
	|	AND VendorInvoice.NewWayToCreateApplicationForGoodsImportFromEAEU";
	
	ReturnOfGoodsToVendorLocalization.AddRequestTextTableProductsForImportDocuments(TextProducts_1);
	
	ImportAccounting.ReflectImportOfGoodsFromCustomsUnionNewMechanics(Query, QueryTexts, Registers, TextProducts_1);
	
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
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ReturnOfGoodsToVendor AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReturnOfGoodsToVendor.ARAPDetails AS Table
		|		LEFT JOIN Document.ReturnOfGoodsToVendor AS DocumentDataHeader
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
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReturnOfGoodsToVendor.ARAPDetails AS Table
		|		LEFT JOIN Document.ReturnOfGoodsToVendor AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	TextReturn = "
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Organization             AS Organization,
		|	Table.Partner                 AS Partner,
		|	
		|	Table.ARAPObject          AS ARAPObject,
		|	Table.Currency                  AS ARAPCurrency,
		|	Table.Currency                  AS DocumentCurrency,
		|	Table.DocumentAmount          AS AmountARAP,
		|	Table.DocumentAmount          AS Sum,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.Date                    AS DateOfCourse,
		|	Table.BusinessOperation   AS BusinessOperation,
		|	UNDEFINED                    AS CashFlowItem,
		|
		|	Table.ARAPObject.UUID AS FinRecordID,
		|	UNDEFINED AS BusinessTransactionSetting
		|FROM
		|	Document.ReturnOfGoodsToVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)";
		
	TextTranscriptOfPayment = "
		|SELECT
		|	Table.Ref                                                        AS Ref,
		|	Table.Ref.Organization                                            AS Organization,
		|	Table.Ref.Partner                                                AS Partner,
		|
		|	Table.Ref.ARAPObject                                         AS CalculationObjectSource,
		|	Table.ARAPObject                                                AS CalculationObjectReceiver,
		|	
		|	Table.Sum                                                         AS Sum,
		|	Table.Ref.Currency                                                 AS DocumentCurrency,
		|	Table.AmountARAP                                           AS AmountARAP,
		|	Table.ARAPCurrency                                          AS ARAPCurrency,
		|	Table.Ref.Date                                                   AS RecorderDate,
		|	Table.Ref.Number                                                  AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	Table.Ref.Date                                                   AS DateOfCourse
		|FROM
		|	Document.ReturnOfGoodsToVendor.ARAPDetails AS Table
		|WHERE
		|	Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|	AND Table.ARAPObject <> Table.Ref.ARAPObject
		|	AND Table.Ref IN (&Ref)";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextReturn, TextTranscriptOfPayment);
	
EndProcedure

#Region Print

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
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConsiderVAT,
	|	FALSE AS OperationIsSubjectToBuyerSPersonalIncomeTax,
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
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
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
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.ReturnOfGoodsToVendor AS Documents
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
	|		LEFT JOIN Constants
	|		ON TRUE
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
	|	CASE
	|		WHEN
	|			Goods.Ref.ReturnOfReceivedReusablePackages
	|			AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|FROM 
	|	Document.ReturnOfGoodsToVendor.Goods AS Goods
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

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	
	Return JobPrintingRules;
	
EndFunction

Function GeneratePrintedFormReturnToSupplier(ObjectsArray, PrintObjects)
	
	    
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query(
	"SELECT
	|	ReturnOfGoodsToVendor.Ref AS Ref,
	|	ReturnOfGoodsToVendor.Number AS Number,
	|	ReturnOfGoodsToVendor.Date AS Date,
	|	ReturnOfGoodsToVendor.Partner AS Partner,
	|	ReturnOfGoodsToVendor.Counterparty AS Recipient,
	|	ReturnOfGoodsToVendor.Organization AS Organization,
	|	ReturnOfGoodsToVendor.Organization.Prefix AS Prefix,
	|	ReturnOfGoodsToVendor.Currency AS Currency,
	|	ReturnOfGoodsToVendor.PriceIncludesVAT AS PriceIncludesVAT,
	|	ReturnOfGoodsToVendor.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN ReturnOfGoodsToVendor.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConsiderVAT,
	|	ReturnOfGoodsToVendor.Warehouse.CurrentEmployeeInChargeTypes AS VacationProduced
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|WHERE
	|	ReturnOfGoodsToVendor.Ref IN(&DocumentsArray)
	|	AND ReturnOfGoodsToVendor.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductNameFull_,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Description AS UnitPrice,
	|	NestedQuery.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.VATRate AS VATRate,
	|	NestedQuery.Price AS Price,
	|	NestedQuery.Count AS Count,
	|	NestedQuery.Sum AS Sum,
	|	NestedQuery.VATAmount AS VATAmount,
	|	NestedQuery.LineNumber AS LineNumber,
	|	CASE
	|		WHEN
	|			NestedQuery.Ref.ReturnOfReceivedReusablePackages
	|			AND NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		ReturnOfGoodsToVendor.Ref AS Ref,
	|		ReturnOfGoodsToVendor.ItemsLocationAttributes.Products AS Products,
	|		CASE
	|			WHEN ReturnOfGoodsToVendor.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|		ReturnOfGoodsToVendor.Package AS Package,
	|		CASE
	|			WHEN ReturnOfGoodsToVendor.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN ReturnOfGoodsToVendor.ItemsLocationAttributes.Products.UnitOfMeasure
	|			ELSE ReturnOfGoodsToVendor.Package
	|		END AS UnitOfMeasure,
	|		ReturnOfGoodsToVendor.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		ReturnOfGoodsToVendor.VATRate AS VATRate,
	|		ReturnOfGoodsToVendor.Price AS Price,
	|		ReturnOfGoodsToVendor.NumberOfPackages AS Count,
	|		CASE WHEN ReturnOfGoodsToVendor.Ref.PriceIncludesVAT THEN
	|			ReturnOfGoodsToVendor.AmountIncludingVAT
	|		ELSE 
	|           ReturnOfGoodsToVendor.AmountIncludingVAT - ReturnOfGoodsToVendor.VATAmount
	|		END AS Sum,
	|		ReturnOfGoodsToVendor.VATAmount AS VATAmount,
	|		ReturnOfGoodsToVendor.LineNumber AS LineNumber
	|	FROM
	|		Document.ReturnOfGoodsToVendor.InventoryKinds AS ReturnOfGoodsToVendor
	|	WHERE
	|		ReturnOfGoodsToVendor.Ref IN(&DocumentsArray)
	|		AND ReturnOfGoodsToVendor.Ref.Posted) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"NestedQuery.Package",
		"NestedQuery.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ReturnOfGoodsToVendor.Package",
		"ReturnOfGoodsToVendor.ItemsLocationAttributes.Products"));
		
	Query.SetParameter("DocumentsArray", ObjectsArray);
		
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReturnOfGoodsToVendor_Invoice";
	
	ResultsArray            = Query.ExecuteBatch();
	
	ResultPrintData        = ResultsArray[0]; // QueryResult
	ResultDocumentSelection = ResultsArray[1]; // QueryResult
	
	PrintData                 = ResultPrintData.Select();
	SelectionByDocuments          = ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	ThereIsRNPT = False;
	
	While PrintData.Next() Do
	
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.ReturnOfGoodsToVendor.PF_MXL_ReturnToVendor");
		
		ProductSelection_1 = SelectionByDocuments.Select();
		
				
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			
			ProductColumnArea = Template.Area("OwnGoods");
			If Not ThereIsRNPT Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.35;	
			EndIf;
			If Not OutputCodes Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
			EndIf;
			
		Else
			
			ProductColumnArea = Template.Area("ProductWithoutAmounts");
			If Not ThereIsRNPT Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.25;	
			EndIf;

			If OutputCodes Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 0.975;
				AreaColumnQuantity = Template.Area("DataWithoutSumsQuantity");
				AreaColumnQuantity.ColumnWidth = AreaColumnQuantity.ColumnWidth * 0.95;
			Else
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.125;
			EndIf;
			
		EndIf;
		
		TemplateArea = Template.GetArea("Title");
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Trả lại hàng cho nhà cung cấp';
																												|ru = 'Возврат поставщику';
																												|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
																												|it = 'Reso al fornitore';
																												|pl = 'Zwrot do dostawcy ';
																												|tr = 'Tedarikçiye iade'")));
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Organization);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Recipient);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		// Output the title of the Products table
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			
			RoomArea     = Template.GetArea("TableHeader|LineNumber");
			AreaCodes      = Template.GetArea("TableHeader|ColumnOfCodes");
			ProductArea      = Template.GetArea("TableHeader|OwnGoods");
			AreaDataQuantity           = Template.GetArea("TableHeader|DataQuantity");
			AreaDataQuantityByRNPT     = Template.GetArea("TableHeader|DataQuantityAccordingToRNPT");
			AreaDataPriceAmount            = Template.GetArea("TableHeader|DataPriceAmount");
			
		Else
			
			RoomArea     = Template.GetArea("HeaderOfTableWithoutAmounts|LineNumberWithoutSums");
			AreaCodes      = Template.GetArea("HeaderOfTableWithoutAmounts|ColumnOfCodesWithoutSums");
			ProductArea      = Template.GetArea("HeaderOfTableWithoutAmounts|ProductWithoutAmounts");
			AreaDataWithoutSumsQuantity       = Template.GetArea("HeaderOfTableWithoutAmounts|DataWithoutSumsQuantity");
			AreaDataWithoutSumsQuantityByRNPT = Template.GetArea("HeaderOfTableWithoutAmounts|DataWithoutSumsQuantityByRNPT");
			
		EndIf;
			
		SpreadsheetDocument.Put(RoomArea);
			
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			SpreadsheetDocument.Join(ProductArea);
			SpreadsheetDocument.Join(AreaDataQuantity);
			If ThereIsRNPT Then
				SpreadsheetDocument.Join(AreaDataQuantityByRNPT);	
			EndIf;
			SpreadsheetDocument.Join(AreaDataPriceAmount);	
		Else
			SpreadsheetDocument.Join(ProductArea);
			SpreadsheetDocument.Join(AreaDataWithoutSumsQuantity);
			If ThereIsRNPT Then
				SpreadsheetDocument.Join(AreaDataWithoutSumsQuantityByRNPT);
			Else
				DataAreaWithoutSumsBorder = Template.GetArea("HeaderOfTableWithoutAmounts|DataWithoutSumsBorder");
				SpreadsheetDocument.Join(DataAreaWithoutSumsBorder);
			EndIf;
		EndIf;
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			
			RoomArea     = Template.GetArea("TableRow|LineNumber");
			AreaCodes      = Template.GetArea("TableRow|ColumnOfCodes");
			ProductArea      = Template.GetArea("TableRow|OwnGoods");
			AreaDataQuantity           = Template.GetArea("TableRow|DataQuantity");
			AreaDataQuantityByRNPT    = Template.GetArea("TableRow|DataQuantityAccordingToRNPT");
			AreaDataPriceAmount            = Template.GetArea("TableRow|DataPriceAmount");
			
		Else
			
			RoomArea     = Template.GetArea("TableRowWithoutSums|LineNumberWithoutSums");
			AreaCodes      = Template.GetArea("TableRowWithoutSums|ColumnOfCodesWithoutSums");
			ProductArea      = Template.GetArea("TableRowWithoutSums|ProductWithoutAmounts");
			AreaDataWithoutSumsQuantity       = Template.GetArea("TableRowWithoutSums|DataWithoutSumsQuantity");
			AreaDataWithoutSumsQuantityByRNPT = Template.GetArea("TableRowWithoutSums|DataWithoutSumsQuantityByRNPT");
			
		EndIf;

		
		Sum          = 0;
		VATAmount       = 0;
		LineNumber    = 0;
		
		// Output the rows of the Goods table
			
		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			DataStructureLineNumber = New Structure("LineNumber", LineNumber);
			RoomArea.Parameters.Fill(DataStructureLineNumber);
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			ProductNameWithoutCCD = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint);			
			OwnGoods = ProductNameWithoutCCD;
			

			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			ProductArea.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductArea);
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				RoomArea     = Template.GetArea("TableRow|LineNumber");
				AreaCodes      = Template.GetArea("TableRow|ColumnOfCodes");
				ProductArea      = Template.GetArea("TableRow|OwnGoods");
				AreaDataQuantity           = Template.GetArea("TableRow|DataQuantity");
				AreaDataQuantityByRNPT     = Template.GetArea("TableRow|DataQuantityAccordingToRNPT");
				AreaDataPriceAmount            = Template.GetArea("TableRow|DataPriceAmount");
				
			Else
				
				RoomArea     = Template.GetArea("TableRowWithoutSums|LineNumberWithoutSums");
				AreaCodes      = Template.GetArea("TableRowWithoutSums|ColumnOfCodesWithoutSums");
				ProductArea      = Template.GetArea("TableRowWithoutSums|ProductWithoutAmounts");
				AreaDataWithoutSumsQuantity       = Template.GetArea("TableRowWithoutSums|DataWithoutSumsQuantity");
				AreaDataWithoutSumsQuantityByRNPT = Template.GetArea("TableRowWithoutSums|DataWithoutSumsQuantityByRNPT");
				
			EndIf;

			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				AreaDataQuantity.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaDataQuantity);
				If ThereIsRNPT Then
					AreaDataQuantityByRNPT.Parameters.Fill(ProductSelection_1);
					SpreadsheetDocument.Join(AreaDataQuantityByRNPT);	
				EndIf;
				AreaDataPriceAmount.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaDataPriceAmount);	
				
			Else
				AreaDataWithoutSumsQuantity.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaDataWithoutSumsQuantity);
				If ThereIsRNPT Then
					AreaDataWithoutSumsQuantityByRNPT.Parameters.Fill(ProductSelection_1);
					SpreadsheetDocument.Join(AreaDataWithoutSumsQuantityByRNPT);
				Else
					DataAreaWithoutSumsBorder = Template.GetArea("TableRowWithoutSums|DataWithoutSumsBorder");
					SpreadsheetDocument.Join(DataAreaWithoutSumsBorder);
				EndIf;
				
			EndIf;
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				Sum    = Sum    + ProductSelection_1.Sum;
				VATAmount = VATAmount + ProductSelection_1.VATAmount;
				
			EndIf;
				
		EndDo;

		// We output the basement
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				RoomArea     = Template.GetArea("TableFooter|LineNumber");
				AreaCodes      = Template.GetArea("TableFooter|ColumnOfCodes");
				ProductArea      = Template.GetArea("TableFooter|OwnGoods");
				AreaDataQuantity           = Template.GetArea("TableFooter|DataQuantity");
				AreaDataQuantityByRNPT     = Template.GetArea("TableFooter|DataQuantityAccordingToRNPT");
				AreaDataPriceAmount            = Template.GetArea("TableFooter|DataPriceAmount");
				
			Else
				
				RoomArea     = Template.GetArea("TableFooter|LineNumberWithoutSums");
				AreaCodes      = Template.GetArea("TableFooter|ColumnOfCodesWithoutSums");
				ProductArea      = Template.GetArea("TableFooter|ProductWithoutAmounts");
				AreaDataWithoutSumsQuantity       = Template.GetArea("TableFooter|DataWithoutSumsQuantity");
				AreaDataWithoutSumsQuantityByRNPT = Template.GetArea("TableFooter|DataWithoutSumsQuantityByRNPT");
				
			EndIf;

			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			
			TotalDataStructure = New Structure("Total", PrintFormGeneration.SumFormat(Sum));
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				AreaDataQuantity.Parameters.Fill(TotalDataStructure);
				SpreadsheetDocument.Join(AreaDataQuantity);
				If ThereIsRNPT Then
					AreaDataQuantityByRNPT.Parameters.Fill(TotalDataStructure);
					SpreadsheetDocument.Join(AreaDataQuantityByRNPT);	
				EndIf;
				AreaDataPriceAmount.Parameters.Fill(TotalDataStructure);
				SpreadsheetDocument.Join(AreaDataPriceAmount);	
				
			Else
				AreaDataWithoutSumsQuantity.Parameters.Fill(TotalDataStructure);
				SpreadsheetDocument.Join(AreaDataWithoutSumsQuantity);
				If ThereIsRNPT Then
					AreaDataWithoutSumsQuantityByRNPT.Parameters.Fill(TotalDataStructure);
					SpreadsheetDocument.Join(AreaDataWithoutSumsQuantityByRNPT);	
				EndIf;		
				
			EndIf;			
		EndIf;
			
		// We output the total of the ADS
		
		If PrintData.ConsiderVAT And PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				RoomArea     = Template.GetArea("VATTableBasement|LineNumber");
				AreaCodes      = Template.GetArea("VATTableBasement|ColumnOfCodes");
				ProductArea      = Template.GetArea("VATTableBasement|OwnGoods");
				AreaDataQuantity           = Template.GetArea("VATTableBasement|DataQuantity");
				AreaDataQuantityByRNPT    = Template.GetArea("VATTableBasement|DataQuantityAccordingToRNPT");
				AreaDataPriceAmount            = Template.GetArea("VATTableBasement|DataPriceAmount");
				
			Else
				
				RoomArea     = Template.GetArea("VATTableBasement|LineNumberWithoutSums");
				AreaCodes      = Template.GetArea("VATTableBasement|ColumnOfCodesWithoutSums");
				ProductArea      = Template.GetArea("VATTableBasement|ProductWithoutAmounts");
				AreaDataWithoutSumsQuantity       = Template.GetArea("VATTableBasement|DataWithoutSumsQuantity");
				AreaDataWithoutSumsQuantityByRNPT = Template.GetArea("VATTableBasement|DataWithoutSumsQuantityByRNPT");
				
			EndIf;

			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			VATDataStructure = New Structure;
			VATDataStructure.Insert("VAT", ?(PrintData.PriceIncludesVAT,
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
			VATDataStructure.Insert("TotalVAT", PrintFormGeneration.SumFormat(VATAmount));
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				AreaDataQuantity.Parameters.Fill(VATDataStructure);
				SpreadsheetDocument.Join(AreaDataQuantity);
				If ThereIsRNPT Then
					AreaDataQuantityByRNPT.Parameters.Fill(VATDataStructure);
					SpreadsheetDocument.Join(AreaDataQuantityByRNPT);	
				EndIf;
				AreaDataPriceAmount.Parameters.Fill(VATDataStructure);
				SpreadsheetDocument.Join(AreaDataPriceAmount);	
				
			Else
				AreaDataWithoutSumsQuantity.Parameters.Fill(VATDataStructure);
				SpreadsheetDocument.Join(AreaDataWithoutSumsQuantity);
				If ThereIsRNPT Then
					AreaDataWithoutSumsQuantityByRNPT.Parameters.Fill(VATDataStructure);
					SpreadsheetDocument.Join(AreaDataWithoutSumsQuantityByRNPT);	
				EndIf;		
				
			EndIf;				
		EndIf;
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
			
			// We output the Amount in words
			
			TemplateArea = Template.GetArea("AmountInWords");
			AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
			
			TotalString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng số %1, thành tiền %2';
					|ru = 'Всего наименований %1, на сумму %2';
					|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
					|it = 'Totale articoli %1, per importo di %2';
					|pl = 'Razem pozycji %1, na kwotę %2';
					|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
				ProductSelection_1.Count(),
				PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
			
			DataStructureSummaryRow = New Structure;
			DataStructureSummaryRow.Insert("TotalString", TotalString);
			DataStructureSummaryRow.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
			TemplateArea.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			
			TemplateArea = Template.GetArea("BasementTablesWithoutSums");
			TotalString = NStr("vi = 'Số lượng các dòng là: %NumberOfTitles%';
								|ru = 'Всего наименований %NumberOfTitles%';
								|en = 'Total items %NumberOfTitles%'; fa = 'Total items %NumberOfTitles%';
								|it = 'Totale articoli %NumberOfTitles%';
								|pl = 'Łącznie nazw %NumberOfTitles%';
								|tr = 'Toplam tanım %NumberOfTitles%'", Common.DefaultLanguageCode());
			TotalString = StrReplace(TotalString, "%NumberOfTitles%", ProductSelection_1.Count());
			DataStructureSummaryRow = New Structure;
			DataStructureSummaryRow.Insert("TotalString", TotalString);
			TemplateArea.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf;
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			DataStructureVacationProduced = New Structure;
			DataStructureVacationProduced.Insert("VacationProduced", PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date));
			TemplateArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

EndFunction

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	// A stub so that the printing of sets from the transportation task does not fall.
	MessageText = NStr("vi = 'Bộ in cho chứng từ ""%Document%"" không được hỗ trợ.';
						|ru = 'Печать комплектов для документов ""%Document%"" не поддерживается.';
						|en = 'Printing sets for documents ""%Document%"" is not supported.'; fa = 'Printing sets for documents ""%Document%"" is not supported.';
						|it = 'La stampa delle serie per i documenti ""%Document%"" non è supportata.';
						|pl = 'Druk zestawów dokumentów ""%Document%"" nie jest obsługiwany.';
						|tr = '""%Document%"" belge setlerinin yazdırılması desteklenmez.'");
	MessageText = StrReplace(MessageText, "%Document%", Metadata.Documents.ReturnOfGoodsToVendor.Synonym);
	CommonClientServer.MessageToUser(MessageText);
	Return Undefined;
EndFunction

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReturnOfGoodsToVendor - The object of the document that you need to get the base text from.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation:
//	* Basis 		- String
//	* BaseDocumentNumber	- String
//	* ReferenceDocumentDateForPrintForms		- Date
//
Function StructureOfBaseForPrinting(Object) Export
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
	If ValueIsFilled(Object.Contract) Then
		ARAPObjectSettings = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	EndIf;
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
			"SELECT
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
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		If ValueIsFilled(StructureBase.Basis) Then
			StructureBase.Basis = StructureBase.Basis + ", " + NStr("vi = 'Chuyển giao ký gửi';
																	|ru = 'Передача на комиссию';
																	|en = 'Consignment sales'; fa = 'فروش امانی';
																	|it = 'Trasferimento in conto vendita';
																	|pl = 'Przekazanie do komisu';
																	|tr = 'Konsinyeye transfer'");
		Else
			StructureBase.Basis = NStr("vi = 'Chuyển giao ký gửi';
										|ru = 'Передача на комиссию';
										|en = 'Consignment sales'; fa = 'فروش امانی';
										|it = 'Trasferimento in conto vendita';
										|pl = 'Przekazanie do komisu';
										|tr = 'Konsinyeye transfer'");
		EndIf;
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReturnOfGoodsToVendor - The document object to get the selection list from.
//
// Returns:
//	ValueTable - with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = StructureOfBaseForPrinting(Object);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
	EndIf;
	Return TableOfBases_;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Refund to the supplier
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ReturnToVendor";
	PrintCommand.Presentation = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
									|ru = 'Возврат поставщику';
									|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
									|it = 'Reso al fornitore';
									|pl = 'Zwrot do dostawcy ';
									|tr = 'Tedarikçiye iade'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
											|ru = 'Возврат поставщику';
											|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
											|it = 'Reso al fornitore';
											|pl = 'Zwrot do dostawcy ';
											|tr = 'Tedarikçiye iade'");

	If Not UserRightsCached.ThisIsPartner() Then
		// Task for the selection of goods
		DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
		
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
	EndIf;
	
	ReturnOfGoodsToVendorLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReturnToVendor") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ReturnToVendor", NStr("vi = 'Trả lại hàng cho nhà cung cấp';
																											|ru = 'Возврат поставщику';
																											|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
																											|it = 'Reso al fornitore';
																											|pl = 'Zwrot do dostawcy ';
																											|tr = 'Tedarikçiye iade'"), GeneratePrintedFormReturnToSupplier(ObjectsArray, PrintObjects));
	EndIf;
	
	ReturnOfGoodsToVendorLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

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

#EndRegion

#Region Other

// This function checks the order document when creating an expense order
//
// Parameters:
//	ReferenceOrder - DocumentRef - Document-order
//	Warehouse - CatalogRef.Warehouses - element of the Warehouses reference list.
//
// Returns:
//	Structure - verification results:
//	* Operation 						- String - Type of operation. "Failure" if the checks passed with errors
//	* ErrorText 					- String - Must be filled in when Failure = True
//	* GroupOfWarehousesAtYourDisposal 	- Boolean - A group of warehouses is selected at the disposal
//	* DateOfShipment 					- Date
//	* UseAdvancedWarehousing 	- Boolean - The warehouse uses an order scheme.
//
Function PerformOrderChecks(ReferenceOrder, Warehouse) Export
		
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Operation", "");
	ReturnStructure.Insert("ErrorText", "");
	ReturnStructure.Insert("GroupOfWarehousesAtYourDisposal", False);
	ReturnStructure.Insert("DateOfShipment");
	ReturnStructure.Insert("UseAdvancedWarehousing");
		
	Attributes = New Structure("DateOfShipment, Warehouse, UseAdvancedWarehousing", "Date");
		 			
	Attributes.Warehouse = "Warehouse";
	Attributes.UseAdvancedWarehousing ="
	|CASE
	|	WHEN ISNULL(Warehouse.UseWarehouseManagemantSystemForGoodsIssue, FALSE)
	|			AND DATE >= ISNULL(Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1))
	|		THEN TRUE
	|	ELSE FALSE
	|END";
	
	AttributesValues = Common.ObjectAttributesValues(ReferenceOrder, Attributes);
	UseAdvancedWarehousing = AttributesValues.UseAdvancedWarehousing;
	
	ReturnStructure.UseAdvancedWarehousing = UseAdvancedWarehousing;
	
	If UseAdvancedWarehousing Then
		
		Warehouse = AttributesValues.Warehouse;
		FillPropertyValues(ReturnStructure, AttributesValues, "DateOfShipment");
		
	Else
		
		ErrorText = NStr("vi = 'Đối với kho bãi ""%Warehouse%"" không cần lập phiếu xuất kho.
			|Chưa điền chứng từ.';
			|ru = 'Для склада ""%Warehouse%"" оформление расходных ордеров не требуется.
			|Заполнение документа не выполнено.';
			|en = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
			|The document is not completed.'; fa = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
			|The document is not completed.';
			|it = 'Per il magazzino, ""%Warehouse%"" non è richiesta la formalizzazione dei mandati di pagamento.
			|La compilazione del documento non è eseguita.';
			|pl = 'W przypadku magazynu ""%Warehouse%"" sporządzenie zleceń wydania nie jest wymagane.
			|Dokument nie został wypełniony.';
			|tr = '""%Warehouse%"" ambarı için herhangi bir ambar çıkış fişlerini oluşturma gerekmemektedir.
			| Belge tamamlanmamıştır.'");
		ReturnStructure.ErrorText = StrReplace(ErrorText, "%Warehouse%", String(AttributesValues.Warehouse));
		ReturnStructure.Operation = "Cancel";
		Return ReturnStructure;
		
	EndIf;	

	Return ReturnStructure
	
EndFunction

Function FullObjectName()
	Return "Document.ReturnOfGoodsToVendor";
EndFunction

#EndRegion

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

#Region Posting

#EndRegion

Function QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsAndServicesToRegisterPurchasingReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	&Ref AS DocumentAcquisitions,
	|	DimensionKeys.Purpose AS Purpose,
	|	-ReturnOfGoodsToVendorInventoryKinds.Count AS Count,
	|	-ReturnOfGoodsToVendorInventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	&Currency AS Currency,
	|	ReturnOfGoodsToVendorInventoryKinds.CCDNumber AS CCDNumber,
	|	-ReturnOfGoodsToVendorInventoryKinds.AmountIncludingVAT AS AmountIncludingVAT,
	|	-ReturnOfGoodsToVendorInventoryKinds.VATAmount AS VATAmount,
	|	-CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN Amounts.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	-CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN Amounts.AmountIncludingVATMan
	|		ELSE 0
	|	END AS SumMan,
	|	TRUE AS Primary,
	|	&IDARAPObject AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	ReturnOfGoodsToVendorInventoryKinds.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(Assignments.ConsiderVATRates, FALSE)
	|			THEN ReturnOfGoodsToVendorInventoryKinds.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate
	|FROM
	|	Document.ReturnOfGoodsToVendor.InventoryKinds AS ReturnOfGoodsToVendorInventoryKinds
	|LEFT JOIN
	|	TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|ON
	|	ReturnOfGoodsToVendorInventoryKinds.Ref = Amounts.Ref
	|	AND ReturnOfGoodsToVendorInventoryKinds.RowID = Amounts.RowID
	|LEFT JOIN
	|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|ON
	|	ReturnOfGoodsToVendorInventoryKinds.ItemsLocationAttributes = DimensionKeys.Ref
	|LEFT JOIN
	|	Catalog.Assignments AS Assignments
	|ON
	|	DimensionKeys.Purpose = Assignments.Ref
	|WHERE
	|	ReturnOfGoodsToVendorInventoryKinds.Ref = &Ref
	|	AND CASE DimensionKeys.Products.ItemsType
	|			WHEN VALUE(Enum.ItemsTypes.OwnGoods)
	|				THEN TRUE
	|			WHEN VALUE(Enum.ItemsTypes.Work_5)
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	AND Assignments.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.ReturnOfGoodsToVendor.Goods AS TabPart";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#EndRegion

#EndIf
#EndIf
