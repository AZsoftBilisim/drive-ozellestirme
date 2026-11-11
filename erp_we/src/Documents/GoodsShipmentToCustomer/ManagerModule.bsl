#If Not MobileStandaloneServer Then
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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Warehouse", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Warehouse, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Warehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IssuiedBy", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Warehouse, Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "IssuiedBy";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Warehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IssuiedByJobTitle", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("GoodsDelivery");
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	GoodsShipmentToCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);

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
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GoodsShipmentToCustomer") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	Else
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject);
		
		GoodsShipmentToCustomerLocalization.AddRequestTexts(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef,
		Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//	Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region GenerateFrom

// Adds the command to create the document "Shipment of goods to the client".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentToCustomer) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsShipmentToCustomer.FullName();
		CreateBasedOnCommand.Handler =
			"GenerationByReferenceTMClient.ShipmentOfItemsToCustomerToCreateBasedOn";
		CreateBasedOnCommand.Presentation =
			TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsShipmentToCustomer);
		
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseShipmentWithDeferredTransferOfTitle2_5";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "Shipment of goods to the client".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentToCustomer) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsShipmentToCustomer.FullName();
		CreateBasedOnCommand.Presentation =
			TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsShipmentToCustomer);
		
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseShipmentWithDeferredTransferOfTitle2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		
		Command = Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
		If Command <> Undefined Then
			Command.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và trước khi chuyển quyền sở hữu';
										|ru = 'Акт о расхождениях после отгрузки товаров клиенту и до перехода права собственности';
										|en = 'Sales dispute after goods shipment to customer and before transfer of title to goods'; fa = 'Sales dispute after goods shipment to customer and before transfer of title to goods';
										|it = 'Sales dispute after goods shipment to customer and before transfer of title to goods';
										|pl = 'Sales dispute after goods shipment to customer and before transfer of title to goods';
										|tr = 'Ürünlerin müşteri tarafında satış uyuşmazlığıyla karşılaşması ve mülkiyetin devrinden önce tutarsızlıkların beyanı'");
		EndIf;
		
	EndIf;
		
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	Documents.GoodsReceiptFromCustomer.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerInvoice.AddCommandToCreateTransferOfOwnershipBasedOnOrder(
		GenerationCommands);
	
	Command = Documents.RecognitionOfStockSurplusShippedToCustomer.AddGenerateCommand(
		GenerationCommands);
	If Command <> Undefined Then
		Command.Presentation = NStr("vi = 'Ghi tăng hàng thừa đã giao cho khách';
									|ru = 'Оприходование излишков товаров, отгруженных клиенту';
									|en = 'Recognition of stock surplus shipped to customer'; fa = 'شناسایی مازاد موجودی ارسال‌شده به مشتری';
									|it = 'Recognition of stock surplus shipped to customer';
									|pl = 'Recognition of stock surplus shipped to customer';
									|tr = 'Müşteriye sevk edilmiş stok fazlası ürünlerin tahakkuku'");
	EndIf;

	Command = Documents.WriteOffOfShippedGoods.AddGenerateCommand(
		GenerationCommands);
	If Command <> Undefined Then
		Command.Presentation = NStr("vi = 'Ghi giảm hàng hóa đã giao cho khách';
									|ru = 'Списание товаров, отгруженных клиенту';
									|en = 'Write-off of goods shipped to customer'; fa = 'اسقاط کالاهای ارسال‌شده به مشتری';
									|it = 'Write-off of goods shipped to customer';
									|pl = 'Write-off of goods shipped to customer';
									|tr = 'Müşteriye sevk edilen ürünlerin gider yazılması'");
	EndIf;
	
	CreationCommand = Documents.DeliveryOrder.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		
		AdvancedOrderOptions = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliveryIsRequired", 
			True,
			DataCompositionComparisonType.Equal);
		
		If AdvancedOrderOptions Then
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand,
				"ShipmentByOrders", 
				False,
				DataCompositionComparisonType.Equal);
			
		EndIf;
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliveryPlanning", 
			Enums.DeliveryPlanningKinds.SeparateDocument,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	GoodsShipmentToCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);;
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfActImplementationCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	GoodsShipmentToCustomerLocalization.AddReportCommands(ReportsCommands, Parameters);
	
	ReportCommand = Reports.StateOfDelivery.AddReportCommand(ReportsCommands, Parameters, "DeliveryStateContext");
	
	If ReportCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			Metadata.Documents.GoodsShipmentToCustomer.Attributes.Organization.Name,
			Catalogs.Companies.ManagementCompany,
			DataCompositionComparisonType.NotEqual);
		
	EndIf;
	
EndProcedure

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return GoodsShipmentToCustomerLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
//  String - The text of the request for the temporary reflection table in the regl accounting
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return GoodsShipmentToCustomerLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion
#Region ARAPAccounting

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - Arbitrary - object or collection for calculating settlement parameters
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	// The AR/AP object of the document "Shipment of goods to the customer"
	// is an official one and is not intended for selection
	ParametersStructure.ARAPObjectInternal = True;

	ParametersStructure.ThisIsSalePurchase = True;
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesPaymentPlan = False;
	ParametersStructure.ModifiesDeliveryShipmentPlan = True;
	
	ParametersStructure.ARAPCurrency = "Object.Currency";
	ParametersStructure.AmountARAP = "Object.DocumentAmount";
	ParametersStructure.AmountARAPByPackage = "";
	
	ParametersStructure.CourseDenominator = 1;
	ParametersStructure.CourseNumerator = 1;
	
	ParametersStructure.PathToTSData = "Object.Goods";
	ParametersStructure.PropsNameTSOrder = "SalesOrder";
	ParametersStructure.PropsNameTSAmountWithVAT = "Sum";
	
	ParametersStructure.Manager = "Object.Manager";
	ParametersStructure.OrderBase = "Object.DocumentBasis";
	
	ParametersStructure.InvoiceForOrders = "Object.ShipmentByOrders";
	
	ParametersStructure.ARAPObject = "Object.ARAPObject";
	ParametersStructure.Terms = "Object.Terms";
	
	ParametersStructure.ForeignCurrencyTransaction = "";
	ParametersStructure.CompanyBankAccount = "";
	ParametersStructure.CounterpartyBankAccount = "";
	ParametersStructure.CashAccount = "";
	ParametersStructure.PaymentMethod = "";
	ParametersStructure.FinancialAccountingGroup = "";
	ParametersStructure.PaymentID = "";
	
	ParametersStructure.FormItems.DebtLimitationText = "DecorationDebtLimitation";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ ấn định lĩnh vực hoạt động ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	// Remnants of goods in the sender warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
//
// Parameters:
// 	Form - ClientApplicationForm
//
// Returns:
// 	See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	DocumentProcessingProcedure.NameOfFormElementIsSeparate = "GoodsWithAssignment";
	DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate = "ProductsTeamGroupSeparately";
	DocumentProcessingProcedure.OrderDetailsName = "ShipmentByOrders";
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,BusinessOperation,Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsShipmentToCustomer";
	
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	
	SeriesSpecificationParameters.SelectionPlanning = True;
	SeriesSpecificationParameters.FactOfSelection         = True;
	
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchIndicationStatusOfGoodsShipped");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("ShipmentByOrders");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_SalesOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(
													SeriesSpecificationParameters);
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchIndicationStatusOfGoodsShipped AS BatchIndicationStatusOfGoodsShipped,
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
	|	Goods.Warehouse             AS Warehouse,
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
	|	Goods.Warehouse,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Count     AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	SetOfSeries.Products      AS Products,
	|	SetOfSeries.Characteristic    AS Characteristic,
	|	SetOfSeries.Purpose        AS Purpose,
	|	SetOfSeries.Warehouse             AS Warehouse,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchIndicationStatusOfGoodsShipped AS OldStatusOfIndicatingSeriesOfShippedItems,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|				AND &SelectionPlanning
	|			THEN
	|				CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN
	|							CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE
	|						CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND NOT (Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|						AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue)
	|				AND &FactOfSelection
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentToCustomer
	|			THEN
	|				CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN
	|							CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE
	|						CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END                    AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|						AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
	|					THEN
	|						CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 18
	|							ELSE 17
	|						END
	|				ELSE 0
	|			END
	|	END                    AS BatchIndicationStatusOfGoodsShipped
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|			AND ProductsToRequest.Warehouse = BatchAccountingPolicies.Warehouse
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|			ON ProductsToRequest.Warehouse = Warehouses.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber                           AS LineNumber,
	|	Statuses.BatchesIndicationStatus                   AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchIndicationStatusOfGoodsShipped AS BatchIndicationStatusOfGoodsShipped,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchIndicationStatusOfGoodsShipped
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                         AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchIndicationStatusOfGoodsShipped
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
	|	OR Statuses.BatchIndicationStatusOfGoodsShipped <> Statuses.OldStatusOfIndicatingSeriesOfShippedItems
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the value of the shipment order.
//
// Parameters:
//	FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//														of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//	DocumentRef - link to the order for performing the warehouse operation
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	If FieldValuesToIdentifyReferences.Goods_RowCode <> 0 Then
		Return FieldValuesToIdentifyReferences.Goods_SalesOrder;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region Delivery

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
	|	T.Warehouse                 AS Warehouse,
	|	TRUE                  AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	Header.Terms.SplitGoodsIssueNotesByReferences AS SplitGoodsIssueNotesByReferences
	|FROM
	|	(SELECT DISTINCT
	|		T.Ref AS Ref,
	|		T.Warehouse AS Warehouse
	|	FROM
	|		Document.GoodsShipmentToCustomer.Goods AS T
	|	WHERE
	|		T.Ref IN(&References)
	|	) AS T
	|		INNER JOIN Document.GoodsShipmentToCustomer AS Header
	|		ON (Header.Ref = T.Ref)
	|WHERE
	|	NOT Header.ShipmentByOrders
	|		OR NOT &UseAdvancedFeaturesOfSalesOrder
	|		OR Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers";
	
	SubstituteTextUseAdvancedCustomerOrderFeatures(QueryText, "Header");
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DocumentFulfillmentStatus

// Initializes the status structure of the document.
//
// Returns:
//	See Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureOfAdditionalRequests = New Structure;
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrderInvoiceShipped",
		QueryTextTTGoodsOrderInvoiceShipped());
	StructureOfAdditionalRequests.Insert("QueryTextTTDocuments",
		QueryTextTTDocuments());
	
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("DisplayShipmentTables", 1);
	StructureState.Insert("DisplayDeliveryTables", 2);
	StructureState.Insert("ToDisplayPPPTable", 3);
	StructureState.Insert("NameTSGoodsShipment", "Goods");
	StructureState.Insert("NameOfInvoiceForOrdersField", "ShipmentByOrders");
	StructureState.Insert("ThereAreSummaryShipmentIndicators", True);
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	StructureState.Insert("NameOfAmountField", "Sum");
	
	Return StructureState;
	
EndFunction

#EndRegion

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.GoodsShipmentToCustomer - Object of the document to
//																			get the base text from.
//
// Returns:
//	Structure- Structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	OrderBase = Undefined;
	If Object.ShipmentByOrders Then
	
		If ValueIsFilled(Object.SalesOrder) Then
			
			If TypeOf(Object.SalesOrder) <> Type("DocumentRef.GoodsShipmentToCustomer") Then
				OrderBase = Object.SalesOrder;
			EndIf;
		
		Else
			
			For Each Page1 In Object.Goods Do
				
				If ValueIsFilled(Page1.SalesOrder)
					And TypeOf(Page1.SalesOrder) <> Type("DocumentRef.GoodsShipmentToCustomer") Then
					
					OrderBase = Page1.SalesOrder;
					Break;
					
				EndIf;
				
			EndDo;
		
		EndIf;
	
	EndIf;
	
	ARAPObjectSettings = ARAPAccountingServer.ARAPObjectSettings(False, OrderBase, Object.Terms, Object.Contract);
	
	BaseStructure = BaseStructure(Object, ARAPObjectSettings);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		BaseStructure.Basis = BaseStructure.Basis + ", " + NStr("ru = 'Отгрузка клиенту';
																|vi = 'Outbound delivery — Wholesale';
																|en = 'Outbound delivery — Wholesale'; fa = 'تحویل خروجی — عمده‌فروشی';
																|it = 'Spedizione al cliente';
																|pl = 'Wysyłka do klienta';
																|tr = 'Müşteriye sevkiyat'");
	Else
		BaseStructure.Basis = NStr("ru = 'Отгрузка клиенту';
									|vi = 'Outbound delivery — Wholesale';
									|en = 'Outbound delivery — Wholesale'; fa = 'تحویل خروجی — عمده‌فروشی';
									|it = 'Spedizione al cliente';
									|pl = 'Wysyłka do klienta';
									|tr = 'Müşteriye sevkiyat'");
	EndIf;
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base"attribute.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.GoodsShipmentToCustomer - the document object to
//																			get the selection list for.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis", New TypeDescription("String",,,, New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",
		New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.Date)));
	TableOfBases_.Columns.Add("BaseDocumentNumber",
		New TypeDescription("String",,,, New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
		AddedRow.Basis = BaseStructure.Basis + ", " + NStr("vi = 'giao hàng cho khách';
															|ru = 'отгрузка клиенту';
															|en = 'shipment to customer'; fa = 'shipment to customer';
															|it = 'shipment to customer';
															|pl = 'shipment to customer';
															|tr = 'müşteriye sevkiyat'");
		
		If ValueIsFilled(BaseStructure.ReferenceDocumentDateForPrintForms)
			And ValueIsFilled(BaseStructure.BaseDocumentNumber) Then
			
			ExtendedText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 số %2 ngày %3';
					|ru = '%1 № %2 от %3';
					|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
					|it = '%1 № %2 dal %3';
					|pl = '%1 nr %2 z dnia %3.';
					|tr = '%2sayılı %3tarihli %1'"),
				BaseStructure.Basis,
				BaseStructure.BaseDocumentNumber,
				Format(BaseStructure.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			
			ExtendedText = ExtendedText + ", " + NStr("vi = 'giao hàng cho khách';
														|ru = 'отгрузка клиенту';
														|en = 'shipment to customer'; fa = 'shipment to customer';
														|it = 'shipment to customer';
														|pl = 'shipment to customer';
														|tr = 'müşteriye sevkiyat'");
			
			AddedRow = TableOfBases_.Add();
			FillPropertyValues(AddedRow, BaseStructure);
			
			AddedRow.Basis = ExtendedText;
			
		EndIf;
		
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByOrders);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis + ", " + NStr("vi = 'giao hàng cho khách';
															|ru = 'отгрузка клиенту';
															|en = 'shipment to customer'; fa = 'shipment to customer';
															|it = 'shipment to customer';
															|pl = 'shipment to customer';
															|tr = 'müşteriye sevkiyat'");
	EndIf;
	
	If TableOfBases_.Count() = 0 Then
		AddedRow = TableOfBases_.Add();
		AddedRow.Basis = NStr("vi = 'giao hàng cho khách';
								|ru = 'отгрузка клиенту';
								|en = 'shipment to customer'; fa = 'shipment to customer';
								|it = 'shipment to customer';
								|pl = 'shipment to customer';
								|tr = 'müşteriye sevkiyat'");
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Allows you to specify metadata objects for which the logic of restricting access to data is set.
//
// Parameters:
//	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)
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

// Checks the completeness of the verified details.
//
// Parameters:
//	 ShipmentOfItems    - DocumentRef.GoodsShipmentToCustomer - The document on the basis of which the input is made
//	 Status             - EnumRef - Status of the document that is used for entering data
//	 ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
//
Procedure CheckPossibilityOfEnteringBasedOn(ShipmentOfItems, Status = Undefined,
	ThereAreErrorsPosted = False) Export
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = False;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(ShipmentOfItems, CheckParameters);
	
EndProcedure

// This function checks the order document when creating an expense order.
//
// Parameters:
//	ReferenceOrder - DefinedType.ShipmentReferenceOrder - link to the order document.
//	Warehouse        - CatalogRef.Warehouses                - Link to an item in the Warehouses reference list.
//
// Returns:
//	Structure - verification results:
//	* Operation                   - String - Type of operation. "Failure" if the checks passed with errors
//	* ErrorText                - String - Must be filled in when Operation = "Failure"
//	* GroupOfWarehousesAtYourDisposal - Boolean - A group of warehouses is selected at the disposal
//	* DateOfShipment               - Date - 
//	* UseAdvancedWarehousing  - Boolean - The warehouse uses an order scheme.
//
Function PerformOrderChecks(ReferenceOrder, Warehouse) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Operation", "");
	ReturnStructure.Insert("ErrorText", "");
	ReturnStructure.Insert("GroupOfWarehousesAtYourDisposal", False);
	ReturnStructure.Insert("DateOfShipment");
	ReturnStructure.Insert("UseAdvancedWarehousing");
	
	If Not ValueIsFilled(Common.ObjectAttributeValue(ReferenceOrder, "Warehouse")) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi"" trong chứng từ ""%ReferenceOrder%"". Không thể tạo phiếu.';
						|ru = 'Не заполнено поле ""Склад"" в документе ""%ReferenceOrder%"". Невозможно создать ордер.';
						|en = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.'; fa = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.';
						|it = 'Il campo ""Magazzino"" nel documento ""%ReferenceOrder%"" non è stato compilato. Impossibile creare un mandato.';
						|pl = 'Nie jest wypełnione pole ""Magazyn"" w dokumencie ""%ReferenceOrder%"". Nie można utworzyć zlecenia.';
						|tr = '""%ReferenceOrder%"" belgesindeki ""Ambar"" alanı doldurulmamış. Giriş fişi oluşturulamaz.'");
		ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
		
		ReturnStructure.ErrorText = ErrorText;
		ReturnStructure.Operation    = "Cancel";
		
		Return ReturnStructure;
		
	EndIf;
	
	WarehouseGroupStructure = New Structure("IsFolder", "Warehouse.IsFolder");
	WarehouseGroupValue  = Common.ObjectAttributesValues(ReferenceOrder, WarehouseGroupStructure);
	
	GroupOfWarehousesAtYourDisposal = WarehouseGroupValue.IsFolder;
	ReturnStructure.GroupOfWarehousesAtYourDisposal = GroupOfWarehousesAtYourDisposal; 
	
	Attributes = New Structure("DateOfShipment, Warehouse, UseAdvancedWarehousing", "Date");
	
	If Not GroupOfWarehousesAtYourDisposal Then
		
		Attributes.Warehouse = "Warehouse";
		Attributes.UseAdvancedWarehousing = "
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
								|tr = '""%Warehouse%"" ambarı için herhangi bir ambar çıkış fişlerini düzenleme gerekmemektedir.
								| Belge tamamlanmamıştır.'");
			
			ReturnStructure.ErrorText = StrReplace(ErrorText, "%Warehouse%", String(AttributesValues.Warehouse));
			ReturnStructure.Operation    = "Cancel";
			
			Return ReturnStructure;
			
		EndIf;
		
	EndIf;
	
	If GroupOfWarehousesAtYourDisposal Then
		
		If Not ValueIsFilled(Warehouse) Then
			
			WarehouseArray = Documents.GoodsIssueNote.OrderWarehousesDuringShipment(ReferenceOrder, Undefined);
			
			If WarehouseArray.Count() = 0 Then
				
				ErrorText = NStr("vi = 'Đối với các kho bãi của chứng từ ""%ReferenceOrder%"" không cần lập phiếu nhập kho.
									|Chưa điền chứng từ.';
									|ru = 'Для складов документа ""%ReferenceOrder%"" оформление приходных ордеров не требуется.
									|Заполнение документа не выполнено.';
									|en = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
									|The document is not populated.'; fa = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
									|The document is not populated.';
									|it = 'Per i magazzini del documento ""%ReferenceOrder%"" non è richiesta la formalizzazione dei reversali d’incasso.
									|La compilazione del documento non è eseguita.';
									|pl = 'W przypadku magazynów dokumentu ""%ReferenceOrder%"" sporządzenie zleceń wydania nie jest wymagane.
									|Dokument nie został wypełniony.';
									|tr = '""%ReferenceOrder%"" belgesindeki depolar için ambar giriş fişlerinin düzenlemesi gerekmemektedir.
									| Belge tamamlanmamıştır.'");
				ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
				
				ReturnStructure.ErrorText = ErrorText;
				ReturnStructure.Operation    = "Cancel";
				
				Return ReturnStructure;
				
			ElsIf WarehouseArray.Count() = 1 Then
				
				Warehouse = WarehouseArray[0];
				
			Else
				
				ReturnStructure.Operation = "Return";
				
				Return ReturnStructure;
				
			EndIf;
			
		Else
			
			ReturnStructure.Operation = "Return";
			
			Return ReturnStructure;
			
		EndIf;
		
	EndIf;
	
	Return ReturnStructure
	
EndFunction

// Returns an empty value orders.
//
// Returns:
//	Array - an array of empty values.
//
Function EmptyOrderValues() Export
	
	EmptyOrderValues = New Array;
	EmptyOrderValues.Add(Undefined);
	EmptyOrderValues.Add(Documents.SalesOrder.EmptyRef());
	
	Return EmptyOrderValues;
	
EndFunction

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//
// Returns:
//  Array - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName = "") Export
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Undefined);
	
	Return ArrayOfValidStatuses;
	
EndFunction

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

// Returns the Products table
//
// Parameters:
//  Invoice - DocumentRef.GoodsShipmentToCustomer - link to the invoice for PM Products that need to be returned
//
// Returns:
//  ValueTable - The tabular part of the goods receipt document.
//
Function TableDataAndDocument(Invoice) Export
	
	QueryText = 
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.PriceKind AS PriceKind,
		|	GoodsTable.Price AS Price,
		|	GoodsTable.Sum AS Sum,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.Warehouse AS Warehouse,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	GoodsTable.SalesOrder AS SalesOrder,
		|	GoodsTable.DeliveryPeriodDays AS DeliveryPeriodDays,
		|	GoodsTable.RowID AS RowID,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTable.ProductsInSet AS ProductsInSet,
		|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
		|	GoodsTable.FEACNCode AS FEACNCode,
		|	GoodsTable.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
		|	GoodsTable.BatchIndicationStatusOfGoodsShipped AS BatchIndicationStatusOfGoodsShipped
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Invoice";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//  Goods				 - FormDataCollection - Table part " Products"
//  FillParameters	 - Structure -
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(
		Goods,
		StructureOfActions,
		CachedValues);
	
EndProcedure

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.GoodsShipmentToCustomer, DocumentRef.GoodsShipmentToCustomer, FormDataStructure -
//  the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	DocumentAttributes = 
		"Date,
		|Contract,
		|LineOfBusiness,
		|Organization,
		|Department,
		|Warehouse";
	
	If TypeOf(Object) = Type("DocumentObject.GoodsShipmentToCustomer")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.GoodsShipmentToCustomer") Then
		ObjectData = Common.ObjectAttributesValues(Object, DocumentAttributes);
	EndIf;
	
	FillPropertyValues(FillParameters, ObjectData, DocumentAttributes);
	FillParameters.GoodsSales = True;
	
	Return FillParameters;
	
EndFunction

// Returns the query text for the temporary table of vttables
// 
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//
// Returns:
//	String - 
//
Function QueryTextTTTableInventoryTypesDecorator(Query, QueryTexts) Export

	Return QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	
EndFunction

#Region VATAccounting

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.GoodsShipmentToCustomer, FormDataStructure	- the document to get parameters for.
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
	If Object.Patch Then
		RegistrationParameters.ErrorCorrection = True;
	EndIf;
	
	RegistrationParameters.VATAccrualUponShipment  = True;
	RegistrationParameters.GoodsSales         = True;
	RegistrationParameters.ImplementationOfWorksServices      = True;
	
	Return RegistrationParameters;
	
EndFunction

// Initializes the parameters for registering notifications about the movement of tracked goods
//
// Parameters:
//  Object		- DocumentObject.GoodsShipmentToCustomer, FormDataStructure	- the document to get parameters for.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 	     * Ref - DocumentRef - Link to the shipment document.
// 	     * Date - Date - Date of the sales document.
// 	     * Organization - CatalogRef.Companies - The organization in which the sale of goods is reflected.
// 	     * Counterparty - CatalogRef.Counterparties,
// 	                    Reference link.Organizations - Counterparty or buyer organization.
//       * Warehouse - CatalogRef.Warehouses -
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the sales document.
// 	     [Operation parameters]
// 	     * SaleToCountriesOfCustomsUnion - Boolean - A sign that the operation of moving goods to the country of the customs union is reflected.
//       * AccountingForTheRNPTIsMaintained - Boolean - Indicates that there are traceable products in the tabular part of the document
//
Function ParametersForRegisteringNotificationsAboutMovementOfTraceableGoods(Object) Export
	
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Ref",               Object.Ref);
	RegistrationParameters.Insert("Date",                 Object.Date);
	RegistrationParameters.Insert("Organization",          Object.Organization);
	RegistrationParameters.Insert("Counterparty",           Object.Counterparty);
	RegistrationParameters.Insert("Warehouse",                Object.Warehouse);
	RegistrationParameters.Insert("VATTaxation",   Object.VATTaxation);
	RegistrationParameters.Insert("SaleToCountriesOfCustomsUnion", False);
	RegistrationParameters.Insert("AccountingForTheRNPTIsMaintained",    False);
	RegistrationParameters.Insert("TransferOfTitleToGoods", False);
	
	If ValueIsFilled(Object.Counterparty) Then
		CounterpartyDetailsValues = Common.ObjectAttributesValues(Object.Counterparty, "LegalEntityIndividual,RegistrationCountry.EEUMember");
		If CounterpartyDetailsValues.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.LegalEntityNonResident") 
			And ValueIsFilled(CounterpartyDetailsValues.CountryOfRegistrationMemberOfEEU)
			And CounterpartyDetailsValues.CountryOfRegistrationMemberOfEEU Then		
			RegistrationParameters.SaleToCountriesOfCustomsUnion = True;
			If Object.Goods.FindRows(New Structure("AccountingForTheRNPTIsMaintained", True)).Count() Then
				RegistrationParameters.AccountingForTheRNPTIsMaintained = True;
			EndIf;
		EndIf;
	EndIf;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region Filling_By_Order

// Constructor function for the structure of the folder props.
//
// Returns:
//  Structure:
//  	* Organization - CatalogRef.Companies
//  	* Warehouse - CatalogRef.Warehouses
//  	* Department - CatalogRef.BusinessStructure
//  	* BusinessOperation - EnumRef.BusinessTransactions
//  	* Ref - DocumentRef.GoodsShipmentToCustomer
//  	* Partner - CatalogRef.Partners
//  	* Counterparty - CatalogRef.Counterparties
//  	* Terms - CatalogRef.TermsOfSale
//  	* Contract - CatalogRef.CounterpartyContracts
//  	* Currency - CatalogRef.Currencies
//  	* SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer
//  	* LineOfBusiness - CatalogRef.LinesOfBusiness
//  	* VATTaxation - EnumRef.VATTaxationTypes
//  	* PriceIncludesVAT - Boolean
//  	* UseAdvancedFeaturesOfSalesOrder - Boolean
//
Function HeaderAttributes() Export

	HeaderAttributes = New Structure;
	
	HeaderAttributes.Insert("Organization",             Catalogs.Companies.EmptyRef());
	HeaderAttributes.Insert("Warehouse",                   Catalogs.Warehouses.EmptyRef());
	HeaderAttributes.Insert("Department",           Catalogs.BusinessStructure.EmptyRef());
	HeaderAttributes.Insert("BusinessOperation",   Enums.BusinessTransactions.EmptyRef());
	HeaderAttributes.Insert("Ref",                  Documents.GoodsShipmentToCustomer.EmptyRef());
	HeaderAttributes.Insert("Partner",                 Catalogs.Partners.EmptyRef());
	HeaderAttributes.Insert("Counterparty",              Catalogs.Counterparties.EmptyRef());
	HeaderAttributes.Insert("Terms",              Catalogs.TermsOfSale.EmptyRef());
	HeaderAttributes.Insert("Contract",                 Catalogs.CounterpartyContracts.EmptyRef());
	HeaderAttributes.Insert("Currency",                  Catalogs.Currencies.EmptyRef());
	HeaderAttributes.Insert("SalesOpportunity",                  Catalogs.SalesOpportunitiesToCustomer.EmptyRef());
	HeaderAttributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	HeaderAttributes.Insert("VATTaxation",      Enums.VATTaxationTypes.EmptyRef());
	HeaderAttributes.Insert("PriceIncludesVAT",         False);
	HeaderAttributes.Insert("UseAdvancedFeaturesOfSalesOrder", False);
	
	Return HeaderAttributes;
	
EndFunction

// Returns an array containing the transmitted invoice, as well as all orders that fit
// the selection by the header Attributes.
//
// Parameters:
// 	Invoice - DocumentRef.GoodsShipmentToCustomer - invoice.
// 	HeaderAttributes - Structure - Details of the caps:
// 		* Organization - CatalogRef.Companies
// 		* Warehouse - CatalogRef.Warehouses
// 		* SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer
// 		* BusinessOperation - EnumRef.BusinessTransactions
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness
//
// Returns:
// 	Array of DocumentRef
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.SalesOrder AS DocumentData
	|	INNER JOIN Document.SalesOrder.Goods AS TableData
	|		ON DocumentData.Ref = TableData.Ref
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND CASE
	|		WHEN DocumentData.ThisIsOrderAsInvoice
	|			AND TableData.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			THEN TRUE
	|		ELSE TableData.Warehouse IN HIERARCHY (&Warehouse)
	|			AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	END
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND DocumentData.VATTaxation = &VATTaxation
	|	AND DocumentData.PriceIncludesVAT = &PriceIncludesVAT
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.LineOfBusiness = &LineOfBusiness)
	|	AND DocumentData.ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TableData
	|		ON DocumentData.Ref = TableData.Ref
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Ref.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND CASE
	|		WHEN DocumentData.ThisIsOrderAsInvoice
	|			AND TableData.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			THEN TRUE
	|		ELSE TableData.Warehouse IN HIERARCHY (&Warehouse)
	|			AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	END
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND DocumentData.Ref.VATTaxation = &VATTaxation
	|	AND DocumentData.Ref.PriceIncludesVAT = &PriceIncludesVAT
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.Ref.LineOfBusiness = &LineOfBusiness)
	|	AND DocumentData.ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
	|
	|UNION ALL
	|
	|SELECT
	|	&Invoice AS ReferenceOrder
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice",               Invoice);
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("Partner",                 HeaderAttributes.Partner);
	Query.SetParameter("Counterparty",              HeaderAttributes.Counterparty);
	Query.SetParameter("Terms",              HeaderAttributes.Terms);
	Query.SetParameter("Contract",                 HeaderAttributes.Contract);
	Query.SetParameter("Warehouse",                   HeaderAttributes.Warehouse);
	Query.SetParameter("Currency",                  HeaderAttributes.Currency);
	Query.SetParameter("SalesOpportunity",                  HeaderAttributes.SalesOpportunity);
	Query.SetParameter("LineOfBusiness", HeaderAttributes.LineOfBusiness);
	Query.SetParameter("VATTaxation",      HeaderAttributes.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",         HeaderAttributes.PriceIncludesVAT);
	Query.SetParameter("ToUseTermsOfSales",
		GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	Query.SetParameter("ThisIsOrderAsInvoice",
		Not HeaderAttributes.UseAdvancedFeaturesOfSalesOrder);
	
	References = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Return CommonClientServer.CollapseArray(References);
	
EndFunction

// Returns parameters for filling in the document for refund requests and receipt orders.
//
// Returns:
//  Structure:
//  	* AnArrayOfOrders - Undefined
//  	* FormIsOpen - Boolean
//  	* FillByWarehouseDocument - Boolean
//  	* AddSeriesOnRequest - Boolean
//  	* RegistrationViaRM - Boolean
//  	* DiscrepancyCertificate - DocumentRef.DiscrepancyReportFollowingShipment
//  	* BasisOfAct - DocumentRef.GoodsShipmentToCustomer
//  	* HeaderAttributes - Undefined
//  	* Organization - CatalogRef.Companies
//  	* BusinessOperation - EnumRef.BusinessTransactions
//  	* Warehouse - CatalogRef.Warehouses
//  	* Department - CatalogRef.BusinessStructure
//  	* FieldNameOrder - String
//  	* KeyFields - String
//  	* Resources - Array of String
//  	* DisplayMessage_1 - Boolean
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",     Undefined);
	FillParameters.Insert("FormIsOpen",      False);
	FillParameters.Insert("FillByWarehouseDocument", Undefined);
	
	FillParameters.Insert("AddSeriesOnRequest", False);
	FillParameters.Insert("RegistrationViaRM",        False);
	
	FillParameters.Insert("DiscrepancyCertificate",        Documents.DiscrepancyReportFollowingShipment.EmptyRef());
	FillParameters.Insert("BasisOfAct",           Documents.GoodsShipmentToCustomer.EmptyRef());
	
	FillParameters.Insert("HeaderAttributes",          Undefined);
	FillParameters.Insert("Organization",             Catalogs.Companies.EmptyRef());
	FillParameters.Insert("BusinessOperation",   Enums.BusinessTransactions.EmptyRef());
	FillParameters.Insert("Warehouse",                   Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("Department",           Catalogs.BusinessStructure.EmptyRef());
	
	FillParameters.Insert("FieldNameOrder", "SalesOrder");
	FillParameters.Insert("KeyFields", "");
	
	FillParameters.Insert("Resources", New Array);
	
	FillParameters.Insert("DisplayMessage_1", False);
	
	Return FillParameters;
	
EndFunction

// Initializes parameters populate the document according to the document.
//
// Parameters:
//  FillParameters - Structure - the fill settings of the default document.
//  HeaderAttributes - Structure - document data that will be used for filling in parameters.
//  AnArrayOfOrders - Array of DocumentRef.GoodsShipmentToCustomer, DocumentRef.SaleAdjustment -
//  	array for applications to be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders  = AnArrayOfOrders;
	FillParameters.HeaderAttributes = HeaderAttributes;
	FillParameters.Organization    = HeaderAttributes.Organization;
	FillParameters.Warehouse          = HeaderAttributes.Warehouse;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	ShipmentReferences.Warehouse AS Warehouse,
		|	(ShipmentReferences.QuantityToBeShippedTurnover -
		|		ShipmentReferences.ShippedQuantityTurnover) AS ToShipBalance
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS ShipmentReferences
		|		LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
		|		ON TRUE
		|WHERE
		|	(ShipmentReferences.QuantityToBeShippedTurnover -
		|		ShipmentReferences.ShippedQuantityTurnover) > 0
		|	AND CAST(ShipmentReferences.Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
		|	AND &CheckDate >= CAST(ShipmentReferences.Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue
		|	AND TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst)";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&References)";
		TableFormationParameters.Group = "Warehouse";
		TableFormationParameters.Indicators = "ToShip, Shipped";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query.SetParameter("References", AnArrayOfOrders);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		
		Selection = Query.Execute().Select();
		
		FillParameters.FillByWarehouseDocument = Selection.Next();
		
	EndIf;
	
	FillParameters.KeyFields = KeyFieldsOfGoodsTable();
	
EndProcedure

// If all orders in the document have the same Attribute values for the "This Order Account", then this value is returned.
// Otherwise, the value of the functional option "Use the expanded capabilities of the Client" is returned.
//
// Parameters:
//  References - Array of DocumentRef.SalesOrder, DocumentRef.RequestForReturnOfGoodsFromCustomer - document instructions.
//
// Returns:
//  Boolean
//
Function UseAdvancedFeaturesOfSalesOrder(References) Export
	
	If References.Count() = 0 Then
		Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Document.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|FROM
	|	Document.SalesOrder AS Document
	|WHERE
	|	Document.Ref IN(&References)
	|
	|UNION
	|
	|SELECT
	|	Document.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Document
	|WHERE
	|	Document.Ref IN(&References)
	|";
	
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	Upload0 = Query.Execute().Unload();
	If Upload0.Count() = 1 Then
		Return Not Upload0[0].ThisIsOrderAsInvoice;
	Else
		Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
EndFunction

// Returns a list of details by which tables are compared when filling in orders/orders
// 
// Returns:
//  String
//
Function KeyFieldsOfGoodsTable() Export
    
    Return "SalesOrder, Products, Characteristic, Purpose, Series, Warehouse";
    
EndFunction

// Fills in the passed parameter table for orders and warehouse orders.
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.GoodsShipmentToCustomer - Link to the current invoice
//  FillParameters	 - Structure - The default settings defined in the method of Parametrization()
//  PackageBarcodes	 - ValueTable - Table of packaging barcodes
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	SelectionByOrdersOrders = FillParameters.Resources.Find("SelectionByOrdersOrders") <> Undefined;
	
	QueryTexts = New Array();
	
	// 1. We get the Query Text for the Balances for shipment: [for shipment] - [shipped]
	
	QueryTexts.Add(QueryTextRemnantsOfGoodsForRegistration());
	
	// 2. We connect the Balances to be shipped from item 1. with the data from the tables of the order documents.
	// The Number, Date, Document summation, etc. fields are required to be displayed in the order selection form.
		
	QueryText =
	"SELECT
	|	Warehouses.Ref AS Warehouse
	|INTO TTWarehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&Warehouse)
	|	AND Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|	AND &CurrentDate >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Table.Ref AS Ref
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|WHERE
	|	Table.Ref IN(&References)
	|	AND Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT Table.Canceled
	|	AND Table.Ref.Posted
	|	AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Ref AS Ref
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
	|WHERE
	|	Table.Ref IN(&References)
	|	AND Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT Table.Canceled
	|	AND Table.Ref.Posted
	|	AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOfAccounting.ReferenceOrder              AS SalesOrder,
	|	DataOfAccounting.ReferenceOrder              AS Ref,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	CASE
	|		WHEN Table.WithAssignment
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                 AS Purpose,
	|	Table.Series                         AS Series,
	|	Table.RowCode                     AS RowCode,
	|	Table.Count                    AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ForRegistrationQuantity,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	Table.Warehouse                         AS Warehouse,
	|	Table.ProductsInSet            AS ProductsInSet,
	|	Table.ItemVariantOfSet          AS ItemVariantOfSet,
	|	CASE
	|		WHEN Table.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND Table.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                 AS CheckShipment,
	|	VALUETYPE(DataOfAccounting.ReferenceOrder) AS TypeOfOrder_,
	|	Table.Ref.Number                  AS Number,
	|	Table.Ref.Date                   AS Date,
	|	Table.Ref.DocumentAmount         AS DocumentAmount,
	|	Table.Ref.Currency                 AS Currency,
	|	Table.Ref.Partner                AS Partner,
	|	Table.Ref.Terms             AS Terms,
	|	Table.Ref.Status                 AS Status,
	|	Table.Ref.Counterparty             AS Counterparty,
	|	Table.Ref.Organization            AS Organization,
	|	Table.Ref.BusinessOperation  AS BusinessOperation,
	|	Table.Ref.Manager               AS Manager,
	|	Table.Ref.Comment            AS Comment,
	|	Table.Ref.ThisIsOrderAsInvoice        AS ThisIsOrderAsInvoice
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	DataOfAccounting.ReferenceOrder              AS SalesOrder,
	|	DataOfAccounting.ReferenceOrder              AS Ref,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	CASE
	|		WHEN Table.WithAssignment
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                 AS Purpose,
	|	Table.Series                         AS Series,
	|	Table.RowCode                     AS RowCode,
	|	Table.Count                    AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ForRegistrationQuantity,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	Table.Warehouse                         AS Warehouse,
	|	Table.ProductsInSet            AS ProductsInSet,
	|	Table.ItemVariantOfSet          AS ItemVariantOfSet,
	|	CASE
	|		WHEN Table.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND Table.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                 AS CheckShipment,
	|	VALUETYPE(DataOfAccounting.ReferenceOrder) AS TypeOfOrder_,
	|	Table.Ref.Number                  AS Number,
	|	Table.Ref.Date                   AS Date,
	|	Table.Ref.ReplacementAmount            AS DocumentAmount,
	|	Table.Ref.Currency                 AS Currency,
	|	Table.Ref.Partner                AS Partner,
	|	Table.Ref.Terms             AS Terms,
	|	Table.Ref.Status                 AS Status,
	|	Table.Ref.Counterparty             AS Counterparty,
	|	Table.Ref.Organization            AS Organization,
	|	Table.Ref.BusinessOperation  AS BusinessOperation,
	|	Table.Ref.Manager               AS Manager,
	|	Table.Ref.Comment            AS Comment,
	|	Table.Ref.ThisIsOrderAsInvoice        AS ThisIsOrderAsInvoice
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	NOT Table.Canceled
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, InvoicesServer.QuerySeparatorText());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Warehouse", FillParameters.Warehouse);
	Query.SetParameter("Recorder", Recorder);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	
	Results = Query.ExecuteBatch();
	ResultOfShipLine = Results[Results.UBound()-1];
	SampleProducts_ = Results[Results.UBound()].Select();
	
	If ResultOfShipLine.IsEmpty()
		And SampleProducts_.Count() = 0
		And FillParameters.DisplayMessage_1 Then
		
		ErrorText = ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment();
		Raise ErrorText;
	EndIf;
	
	Filter = New Map;
	If ValueIsFilled(FillParameters.Warehouse) Then
		TMCommonUse.AddSelectionItemToCollection(Filter, "Warehouse", "SELECT Warehouse FROM TTWarehouses");
	EndIf;
	
	// We get data from orders: quantity Collected and quantity Collected.
	// Going to - the user for information.
	If FillParameters.FillByWarehouseDocument Then
	
		Query.Text = AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue(Filter);
		TableOrders = Query.Execute().Unload();
		
		TableColumn2 = TableOrders.Columns.Count; // ValueTableColumn
		TableColumn2.Name = "NoteQuantity";
		TableColumn2 = TableOrders.Columns.ReferenceOrder; // ValueTableColumn
		TableColumn2.Name = FillParameters.FieldNameOrder;
		
		If TableOrders.Columns.Find("AssemblyInProgress") <> Undefined Then
			TableColumn2 = TableOrders.Columns.AssemblyInProgress; // ValueTableColumn
			TableColumn2.Name = "NumberInProgress";
		EndIf;
		
	Else
		
		TableOrders = New ValueTable();
		
	EndIf;
	
	If Goods.Columns.Find("RecalculationOfAmountIsRequired") = Undefined Then
		Goods.Columns.Add("RecalculationOfAmountIsRequired", New TypeDescription("Boolean"));
	EndIf;
	
	If Goods.Columns.Find("NumberOfPackages") = Undefined Then
		Goods.Columns.Add("NumberOfPackages", New TypeDescription("Number"));
	EndIf;
	
	If SelectionByOrdersOrders Then
		
		If Goods.Columns.Find("QuantityInOrder") = Undefined Then
			Goods.Columns.Add("QuantityInOrder", New TypeDescription("Number"));
		EndIf;
		
		If Goods.Columns.Find("NumberInProgress") = Undefined Then 
			Goods.Columns.Add("NumberInProgress", New TypeDescription("Number"));
		EndIf;
		
		If Goods.Columns.Find("NoteQuantity") = Undefined Then 
			Goods.Columns.Add("NoteQuantity", New TypeDescription("Number"));
		EndIf;
		
		ShippedGoods_ = TableOrders.Copy();
		
	EndIf;
	
	CheckWarehouses = Undefined;
	FillParameters.Property("CheckWarehouses", CheckWarehouses);
	
	While SampleProducts_.Next() Do
		
		If ValueIsFilled(CheckWarehouses) Then
			WarehousesByRef = CheckWarehouses.Get(SampleProducts_.SalesOrder);
			If WarehousesByRef <> Undefined
				 And WarehousesByRef.Find(SampleProducts_.Warehouse) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		QuantityToShip = SampleProducts_.ForRegistrationQuantity;
		RecalculationOfAmountIsRequired = False;
		
		// If you need to fill in an order, and the warehouse is an order, then we take the quantity to be shipped from the order
		// Fill in the Order = True and check the shipment = False - this situation is possible if
		// the warehouse is a group in the header of the document, but the warehouse is not in TS.
		If FillParameters.FillByWarehouseDocument
			And SampleProducts_.CheckShipment
			And Not SampleProducts_.ThisIsOrderAsInvoice Then
			
			SearchParameters = New Structure(FillParameters.KeyFields);
			FillPropertyValues(SearchParameters, SampleProducts_);
			
			FoundRows = TableOrders.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then
				
				ShippedLine = FoundRows[0];
				
				If ShippedLine.NoteQuantity > 0 Then
					
					If ShippedLine.NoteQuantity < SampleProducts_.Count Then
						
						QuantityToShip = ShippedLine.NoteQuantity;
						ShippedLine.NoteQuantity = 0;
						RecalculationOfAmountIsRequired = True;
						
					Else
						
						QuantityToShip = SampleProducts_.Count;
						ShippedLine.NoteQuantity =
							ShippedLine.NoteQuantity
							- SampleProducts_.Count;
						
					EndIf;
					
				ElsIf SelectionByOrdersOrders Then
					QuantityToShip = 0;
				Else
					Continue;
				EndIf;
				
			ElsIf SelectionByOrdersOrders Then
				QuantityToShip = 0;
			Else
				Continue;
			EndIf;
			
		EndIf;
		
		// The line search is relevant for the Selection Form based on orders/orders - the
		// Goods table of the Shipment of Goods document is passed to it (to the Form) as a parameter. For all other cases, add a new line.
		SearchParameters = New Structure(FillParameters.KeyFields + ", RowCode");
		FillPropertyValues(SearchParameters, SampleProducts_);
		
		FoundRows = Goods.FindRows(SearchParameters);
		
		If FoundRows.Count() > 0 Then
			TabRow = FoundRows[0];
		Else
			TabRow = Goods.Add();
			FillPropertyValues(TabRow, SampleProducts_,, "Count");
			TabRow.Count = QuantityToShip;
			TabRow.RecalculationOfAmountIsRequired = RecalculationOfAmountIsRequired;
		EndIf;
		
		// For the case of Selection by orders/orders, fill in the columns Quantity in the order, Quantity is Collected and
		// Quantity in the order (collected)
		If SelectionByOrdersOrders Then
			
			TabRow.QuantityInOrder = ?(SampleProducts_.RowCode <> 0, SampleProducts_.ForRegistrationQuantity, 0);
			
			If FillParameters.FillByWarehouseDocument And SampleProducts_.CheckShipment Then
				
				SearchParameters = New Structure(FillParameters.KeyFields);
				FillPropertyValues(SearchParameters, SampleProducts_);
				If SampleProducts_.ThisIsOrderAsInvoice Then
					SearchParameters.SalesOrder = Recorder;
				EndIf;
				
				FoundRows = ShippedGoods_.FindRows(SearchParameters);
				
				If FoundRows.Count() > 0 Then
					
					ShippedLine = FoundRows[0];
					
					If ShippedLine.NumberInProgress > 0 Then
						TabRow.NumberInProgress = ShippedLine.NumberInProgress;
						ShippedLine.NumberInProgress = 0;
					EndIf;
					
					If ShippedLine.NoteQuantity > 0 Then
						
						If ShippedLine.NoteQuantity <= SampleProducts_.Count Then
							
							TabRow.NoteQuantity = ShippedLine.NoteQuantity;
							ShippedLine.NoteQuantity = 0;
							ShippedGoods_.Delete(ShippedLine);
							
						Else
							
							TabRow.NoteQuantity = SampleProducts_.Count;
							ShippedLine.NoteQuantity =
								ShippedLine.NoteQuantity
								- SampleProducts_.Count;
							
						EndIf;
						
					EndIf;
					
				EndIf;
			
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If FillParameters.FillByWarehouseDocument Then
		
		InvoicesServer.DeleteEmptyLines(TableOrders, "NoteQuantity");
		
		For Each ShippedLine In TableOrders Do
			
			If ShippedLine.NoteQuantity < 0 Then
				Continue;
			EndIf;
			
			SearchParameters = New Structure(FillParameters.KeyFields);
			FillPropertyValues(SearchParameters, ShippedLine);
			
			FoundRows = Goods.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then
				
				FoundRow = FoundRows[0];
				
				If SelectionByOrdersOrders Then
					FoundRow.NoteQuantity =
						FoundRow.NoteQuantity + ShippedLine.NoteQuantity;
				Else
					FoundRow.Count = FoundRow.Count + ShippedLine.NoteQuantity;
					FoundRow.RecalculationOfAmountIsRequired = True;
				EndIf;
				
			Else
				
				TabRow = Goods.Add();
				FillPropertyValues(TabRow, ShippedLine);
				
				TabRow.Count = ShippedLine.NoteQuantity;
				TabRow.NumberOfPackages = ShippedLine.NoteQuantity;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// Recalculating the number of packages for all lines
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	BatchProcessingOfTablePartServer.TreatTS(
		Goods,
		StructureOfActions);
	
	// We recalculate the amount only in those lines where it is necessary
	StructureOfActions.Clear();
	StructureOfActions.Insert("RecalculateAmount");
	For Each Page1 In Goods Do
		
		If Page1.RecalculationOfAmountIsRequired Then
			BatchProcessingOfTablePartServer.ProcessTSString(Page1, StructureOfActions, Undefined);
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(FillParameters.AnArrayOfOrders) Then
		GoodsShipmentToCustomerLocalization.FillInBarcodesOfPackages(FillParameters.AnArrayOfOrders, Goods, PackageBarcodes);
	EndIf;
	
EndProcedure

// Generates the data necessary to verify the entry of the invoice on the basis of orders.
// See GenerationByReferenceTMServerCall.ShipmentOfItemsToClientFormOpeningParameters
//
// Parameters:
//  References - Array of DocumentRef- list of orders on the basis of which the invoice is issued
//
// Returns:
//  See ParametersForCheckingInputBasedOn
//
Function DataForInputValidationBasedOn(References) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Table.LineNumber AS LineNumber
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|WHERE
	|	(Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|		OR Table.Ref.ThisIsOrderAsInvoice)
	|	AND Table.Ref IN (&References)
	|	AND NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.LineNumber AS LineNumber
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
	|WHERE
	|	(Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|		OR Table.Ref.ThisIsOrderAsInvoice)
	|	AND Table.Ref IN (&References)
	|	AND NOT Table.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.SalesOrder AS Table
	|WHERE
	|	Table.Ref IN (&References)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Table
	|WHERE
	|	Table.Ref IN (&References)";
	
	Query.SetParameter("References", References);
	QueryResult = Query.ExecuteBatch();
	
	ResultGoodsToShip = QueryResult[QueryResult.UBound() - 1];
	TableBusinessOfOperations = QueryResult[QueryResult.UBound()].Unload();
	
	DataForInputValidationBasedOn = ParametersForCheckingInputBasedOn();
	DataForInputValidationBasedOn.ThereIsShip = Not ResultGoodsToShip.IsEmpty();
	DataForInputValidationBasedOn.BusinessTransactions = TableBusinessOfOperations.UnloadColumn("BusinessOperation");

	Return DataForInputValidationBasedOn;

EndFunction

// Parameter constructor function for checking input based on
//
// Returns:
// 	Structure:
// 	* ThereIsShip - Boolean
// 	* BusinessTransactions - Array of EnumRef.BusinessTransactions
//
Function ParametersForCheckingInputBasedOn() Export
	
	ParametersForCheckingInputBasedOn = New Structure;
	ParametersForCheckingInputBasedOn.Insert("ThereIsShip", False);
	ParametersForCheckingInputBasedOn.Insert("BusinessTransactions", New Array);
	
	Return ParametersForCheckingInputBasedOn;
	
EndFunction

#EndRegion

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
	
	ObjectPresentation = NStr("vi = 'Giao hàng cho khách';
								|ru = 'Отгрузка товаров клиенту';
								|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
								|it = 'Goods shipment to customer';
								|pl = 'Goods shipment to customer';
								|tr = 'Müşteriye ürün sevkiyatı'");
	
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"),
		ObjectPresentation,
		Data.Number,
		Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness = 
	"SELECT
	|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
	|	DirectionsOfDocuments.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))
	|		OR (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfAnalytics
	|INTO TTLinesOfBusiness
	|FROM
	|	Document.GoodsShipmentToCustomer AS DirectionsOfDocuments
	|WHERE
	|	DirectionsOfDocuments.Ref = &Ref";
	
	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	#Region IncreaseShipping
	
	TextProducts_1 =
	"SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	DocumentDataHeader.Contract AS Contract,
	|	DocumentDataHeader.LineOfBusiness AS LineOfBusiness,
	|	DocumentDataHeader.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Date AS DateOfShipment,
	|	Table.Sum AS IncreaseShipping,
	|	0 AS ReduceShipping,
	|	Table.Sum AS IncreaseToBeSHIPPED,
	|	0 AS ReduceToBESHIPPED,
	|	Table.Sum AS AmountARAP,
	|	Table.SalesOrder AS SalesOrder_,
	|	0 AS DepositForPackage,
	|	FALSE AS ExceedingOrder,
	|	DocumentDataHeader.ShipmentByOrders AS InvoiceForOrders,
	|	DocumentDataHeader.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
	|	DocumentDataHeader.Currency AS DocumentCurrency
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentDataHeader
	|		INNER JOIN Document.GoodsShipmentToCustomer.Goods AS Table
	|		ON DocumentDataHeader.Ref = Table.Ref
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND NOT DocumentDataHeader.ShipmentByOrders";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, "", "", "", TextProducts_1);
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array;
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.DeliveryIsRequired AS DeliveryIsRequired,
	|	DocumentData.DeliveryPlanning AS DeliveryPlanning,
	|	DocumentData.DeliveryMethod25 AS DeliveryMethod25,
	|	DocumentData.DeliveryPoint AS DeliveryPoint,
	|	DocumentData.DeliveryZone AS DeliveryZone,
	|	DocumentData.DeliveryToCarrier AS DeliveryToCarrier,
	|	DocumentData.CarrierPartner AS CarrierPartner,
	|	DocumentData.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DocumentData.CarrierSDeliveryArea AS CarrierSDeliveryArea
	|INTO DocumentDataHeader
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ProductsTypeOfProducts,
	|	GoodsTable.SalesOrder.ThisIsOrderAsInvoice AS SalesOrderIsOrderAsInvoice,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.DeliveryLineCode AS DeliveryLineCode,
	|	GoodsTable.Package AS Package
	|INTO DocumentDataTableItems
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.Text =
	"SELECT
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.SalesOrder          AS SalesOrder,
	|	DocumentData.Date                  AS ReferenceDate,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	ISNULL(DocumentData.Counterparty.RegistrationCountry.EEUMember, FALSE) AS CounterpartyMemberOfEAEU,
	|	CASE
	|		WHEN ISNULL(DocumentData.Counterparty.LegalEntityIndividual,
	|			VALUE(Enum.LegalEntityIndividual.EmptyRef)) = VALUE(Enum.LegalEntityIndividual.LegalEntityNonResident)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                 AS CounterpartyNotResident,
	|	DocumentData.Terms            AS Terms,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Organization.RegistrationCountry AS RegistrationCountry,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Warehouse                 AS Warehouse,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.Comment           AS Comment,
	|	DocumentData.Manager              AS Manager,
	|	DocumentData.Author                 AS Author,
	|	DocumentData.SalesOpportunity                AS SalesOpportunity,
	|	DocumentData.VATTaxation    AS VATTaxation,
	|	TRUE                                AS PriceIncludesVAT,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.Department         AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DocumentAmount        AS DocumentAmount,
	|	DocumentData.DeletionMark       AS DeletionMark,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.Patch           AS Patch,
	|	DocumentData.ReversedDocument  AS ReversedDocument,
	|	DocumentData.CorrectedDocument  AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date  AS AdjustmentPeriod_,
	|	DocumentData.ShipmentByOrders     AS ShipmentByOrders,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.DeliveryIsRequired AS DeliveryIsRequired,
	|	DocumentData.DeliveryPlanning AS DeliveryPlanning,
	|	DocumentData.DeliveryMethod25 AS DeliveryMethod25,
	|	DocumentData.DeliveryPoint AS DeliveryPoint,
	|	DocumentData.DeliveryZone AS DeliveryZone,
	|	DocumentData.DeliveryToCarrier AS DeliveryToCarrier,
	|	DocumentData.CarrierPartner AS CarrierPartner,
	|	DocumentData.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DocumentData.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	For Each Column In QueryResult.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ContractInformation    = "";
	NumberForPrinting           = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	MetadataIdentifier =
		Common.MetadataObjectID("Document.GoodsShipmentToCustomer");
	
	If ValueIsFilled(Attributes.Contract) Then
		
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern,
			Attributes.Contract);
			
	EndIf;
	
	Query.SetParameter("MetadataIdentifier",        MetadataIdentifier);
	Query.SetParameter("ShipmentForMultipleOrders",    Not ValueIsFilled(Attributes.SalesOrder));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("NumberForPrinting",                  NumberForPrinting);
	Query.SetParameter("ContractInformation",           ContractInformation);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",  Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
							GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	Query.SetParameter("TaxationOfOrganization",
		VATAccountingERP.AccountingParametersForOrganization(Query.Parameters.Organization, Query.Parameters.Period).BasicTaxationVATSales);
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	Query.SetParameter("TypesOfVATTaxationNonTaxable", VATAccountingERP.TypesOfVATTaxationNonTaxable());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	If Attributes.DeliveryIsRequired Then
		
		OperationLevel = GoodsDelivery.LevelOfOperationOfDocument(DocumentRef, Attributes.DeliveryPlanning);
		Query.SetParameter("OperationLevel", OperationLevel);
		
	EndIf;
	
EndProcedure

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                        AS Period,
	|	&BusinessOperation         AS BusinessOperation,
	|	TableTypesOfStocks_.Organization AS Organization,
	|	&Department                 AS Department,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                          AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse       AS Warehouse,
	|	TableTypesOfStocks_.InventoryType  AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS SourceOfProductFinancialAccountingGroup,
	|	&LineOfBusiness       AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                          AS CorItemsLocationAttributes,
	|	&Contract                       AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.InventoryType  AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS CorSourceOfItemsFinancialAccountingGroup,
	|	TableTypesOfStocks_.Count  AS Count,
	|	TableTypesOfStocks_.Count  AS CorQuantity,
	|	0                              AS Cost,
	|	0                              AS CostExcludingVAT,
	|	0                              AS LocalCost
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_";
	
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
	|	&Period														AS Period,
	|	SeriesTable.Series											AS Series,
	|	SeriesTable.Products									AS Products,
	|	SeriesTable.Characteristic									AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END														AS Purpose,
	|	&Ref														AS Document,
	|	SeriesTable.Warehouse											AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef)		AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer)	AS WarehouseOperation,
	|	&Partner													AS Recipient,
	|	CASE
	|		WHEN NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END														AS ThisIsWarehouseRecord,
	|	SeriesTable.Count										AS Count
	|FROM
	|	Document.GoodsShipmentToCustomer.SetOfSeries AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period														AS Period,
	|	SeriesTable.Series											AS Series,
	|	SeriesTable.Products									AS Products,
	|	SeriesTable.Characteristic									AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END														AS Purpose,
	|	&Ref														AS Document,
	|	SeriesTable.Warehouse											AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef)		AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer)	AS WarehouseOperation,
	|	&Partner													AS Recipient,
	|	CASE
	|		WHEN NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END														AS ThisIsWarehouseRecord,
	|	SeriesTable.Count										AS Count
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	// 1. Shipment by order
	"SELECT
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Ref.Date    AS Period,
	|	GoodsTable.SalesOrder   AS ReferenceOrder,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode      AS RowCode,
	|	GoodsTable.Warehouse          AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                        AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped) AS Factor,
	|	GoodsTable.Count     AS Count,
	|	GoodsTable.Sum          AS Sum
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.ShipmentByOrders
	|	AND GoodsTable.RowCode <> 0
	|	AND NOT GoodsTable.SalesOrder IN (
	|					VALUE(Document.SalesOrder.EmptyRef),
	|					VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|					UNDEFINED
	|					)
	|	AND CASE
	|		WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|			THEN NOT CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|		WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN NOT CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|		ELSE
	|			TRUE
	|	END
	|
	|UNION ALL
	|
	// 2. Shipment beyond the order
	|SELECT
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Ref.Date    AS Period,
	|	GoodsTable.SalesOrder   AS ReferenceOrder,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode      AS RowCode,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsTable.Warehouse
	|	END                        AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|				)
	|			AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN
	|				GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                        AS Series,
	|	TableOfIndicators.Ref    AS Factor,
	|	GoodsTable.Count     AS Count,
	|	GoodsTable.Sum          AS Sum
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.ShipmentByOrders
	|	AND GoodsTable.RowCode = 0
	|	AND NOT GoodsTable.SalesOrder IN (
	|			VALUE(Document.SalesOrder.EmptyRef),
	|			VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|			UNDEFINED
	|			)
	|	AND CASE
	|		WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|			THEN NOT CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|		WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN NOT CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|		ELSE
	|			TRUE
	|	END
	|
	|UNION ALL
	|
	// 3. Shipment without an order or shipment by order (return request), but the order
	// (return request) has the attribute This is an orderaccount
	|SELECT
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Ref.Date    AS Period,
	|	CASE
	|		WHEN GoodsTable.Ref.Patch
	|			THEN GoodsTable.Ref.CorrectedDocument
	|		ELSE
	|			GoodsTable.Ref
	|	END                        AS ReferenceOrder,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode      AS RowCode,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsTable.Warehouse
	|	END                        AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|				)
	|			AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN
	|				GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                        AS Series,
	|	TableOfIndicators.Ref    AS Factor,
	|	GoodsTable.Count     AS Count,
	|	GoodsTable.Sum          AS Sum
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|				)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (GoodsTable.RowCode <> 0
	|		AND NOT GoodsTable.Ref.ShipmentByOrders
	|		AND GoodsTable.SalesOrder IN (
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|				UNDEFINED
	|				)
	|		OR
	|		GoodsTable.Ref.ShipmentByOrders
	|		AND NOT GoodsTable.SalesOrder IN (
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|				UNDEFINED
	|				)
	|		AND CASE
	|			WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|				THEN CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			ELSE
	|				FALSE
	|		END
	|	)
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
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
	|	&Ref						AS Ref,
	|	&Period						AS IBDocumentDate,
	|	&Number						AS IBDocumentNumber,
	|	&MetadataIdentifier	AS RefType,
	|	&Organization				AS Organization,
	|	&BusinessOperation		AS BusinessOperation,
	|	&Partner					AS Partner,
	|	&Counterparty					AS Counterparty,
	|	&Contract					AS Contract,
	|	&LineOfBusiness	AS LineOfBusiness,
	|	&Warehouse						AS StorageLocation,
	|	&Department				AS Department,
	|	&Manager					AS EmployeeResponsible,
	|	&Author						AS Author,
	|	&Comment				AS Comment,
	|	&Currency						AS Currency,
	|	&DocumentAmount				AS Sum,
	|	&Posted					AS Posted,
	|	&DeletionMark			AS DeletionMark,
	|	FALSE						AS AdditionalRecord,
	|	&ContractInformation		AS More,
	|	&Period						AS SourceDocumentDate,
	|	&Patch				AS ReverseTransactionCorrection,
	|	&ReversedDocument		AS ReversedDocument,
	|	&CorrectedDocument		AS CorrectedDocument,
	|	&NumberForPrinting				AS SourceDocumentNumber,
	|	&Period						AS RecordingInAccountingDate,
	|	UNDEFINED				AS Priority
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	&VATRateWithoutVAT AS VATRate,
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
	|	Document.GoodsShipmentToCustomer.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.ShipmentByOrders
	|				AND &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|										UNDEFINED,
	|										VALUE(Document.SalesOrder.EmptyRef),
	|										VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|										)
	|			THEN DocumentGoods.SalesOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	HeaderData_.Patch				AS Patch,
	|	HeaderData_.CorrectedDocument	AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.ShipmentByOrders
	|				AND &UseAdvancedOrderFeatures
	|				AND DocumentGoods.RowCode = 0
	|				AND NOT DocumentGoods.SalesOrder IN (
	|										UNDEFINED,
	|										VALUE(Document.SalesOrder.EmptyRef),
	|										VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|										)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.ShipmentByOrders
	|				AND &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|										UNDEFINED,
	|										VALUE(Document.SalesOrder.EmptyRef),
	|										VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|										)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
	|		LEFT JOIN Document.GoodsShipmentToCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0";
	
	SubstituteTextUseAdvancedCustomerOrderFeatures(
		TextOfDocumentDataRequest, "HeaderData_", "&UseAdvancedOrderFeatures", "DocumentGoods");
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.ShipmentByOrders
	|				AND &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|										UNDEFINED,
	|										VALUE(Document.SalesOrder.EmptyRef),
	|										VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|										)
	|			THEN DocumentGoods.SalesOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	HeaderData_.Patch				AS Patch,
	|	HeaderData_.CorrectedDocument	AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.ShipmentByOrders
	|				AND &UseAdvancedOrderFeatures
	|				AND DocumentGoods.RowCode = 0
	|				AND NOT DocumentGoods.SalesOrder IN (
	|										UNDEFINED,
	|										VALUE(Document.SalesOrder.EmptyRef),
	|										VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|										)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	CASE
	|		WHEN HeaderData_.ShipmentByOrders
	|				AND &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|										UNDEFINED,
	|										VALUE(Document.SalesOrder.EmptyRef),
	|										VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|										)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
	|		LEFT JOIN Document.GoodsShipmentToCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|";
	
	SubstituteTextUseAdvancedCustomerOrderFeatures(
		TextOfDocumentDataRequest, "HeaderData_", "&UseAdvancedOrderFeatures");
	
	UseAdvancedOrderFeatures =
		?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
			"TRUE",
			"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
	
	MetadataObject	= Metadata.Documents.GoodsShipmentToCustomer;
	TSSeriesName			= "SetOfSeries";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										TSSeriesName);
	
EndProcedure

Function QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters)
	
	RegisterName = "Delivery";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.Patch
		And (Not DocumentObject.DeliveryIsRequired
			Or DocumentObject.DeliveryMethod25 = Enums.TransportMethods25.SelfPickup
			Or DocumentObject.DeliveryMethod25 = Enums.TransportMethods25.OurCourier)
		Or (DocumentObject.Patch
			And Not DocumentObject.DeliveryIsRequired) Then
		
		Return "";
		
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentHeader.DeliveryPlanning AS DeliveryPlanning,
	|	GoodsTable.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	DocumentHeader.Organization AS Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
	|	BEGINOFPERIOD(&Period, DAY) AS DateOfShipment,
	|	DocumentHeader.DeliveryMethod25 AS DeliveryMethod,
	|	CASE
	|		WHEN DocumentHeader.DeliveryMethod25 = VALUE(Enum.TransportMethods25.ByCarrier)
	|			THEN DocumentHeader.CarrierPartner
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Carrier,
	|	GoodsTable.Warehouse AS Sender,
	|	ISNULL(TableWarehousesDeliveryDetails.WarehousePoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS SenderPoint,
	|	ISNULL(TableWarehousesDeliveryDetails.AreaOfWarehouse, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Sender_Area,
	|	CASE
	|		WHEN DocumentHeader.DeliveryToCarrier
	|			THEN DocumentHeader.CarrierPartner
	|		ELSE DocumentHeader.Partner
	|	END AS Recipient,
	|	CASE
	|		WHEN DocumentHeader.DeliveryToCarrier
	|			THEN DocumentHeader.CarrierDeliveryPoint
	|		ELSE DocumentHeader.DeliveryPoint
	|	END AS RecipientPoint,
	|	CASE
	|		WHEN DocumentHeader.DeliveryToCarrier
	|			THEN DocumentHeader.CarrierSDeliveryArea
	|		ELSE DocumentHeader.DeliveryZone
	|	END AS Recipient_Area,
	|	CASE
	|		WHEN &ShipmentByOrders
	|				AND NOT GoodsTable.SalesOrder.ThisIsOrderAsInvoice
	|			THEN GoodsTable.SalesOrder
	|		WHEN DocumentHeader.Patch
	|			THEN DocumentHeader.CorrectedDocument
	|		ELSE &Ref
	|	END AS ReferenceOrder,
	|	UNDEFINED AS Trip,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	CASE
	|		WHEN &ShipmentByOrders
	|			THEN GoodsTable.DeliveryLineCode
	|		ELSE GoodsTable.RowCode
	|	END AS RowCode,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|				AND NOT DocumentHeader.Patch
	|			THEN &Ref
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|				AND DocumentHeader.Patch
	|			THEN DocumentHeader.CorrectedDocument
	|		ELSE UNDEFINED
	|	END AS PlanningDocument,
	|	1 AS Arm,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Count AS ToDeliver,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	0 AS Weight,
	|	0 AS VolumeM3,
	|	&OperationLevel AS OperationLevel,
	|	NOT DocumentHeader.DeliveryToCarrier AS ThisIsFinalArm,
	|	1 AS MinimumArmNumber,
	|	TRUE AS PrimaryRegisterRecord,
	|	BEGINOFPERIOD(&Period, DAY) AS SourceShipmentDate,
	|	GoodsTable.Purpose AS Purpose
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|		LEFT JOIN Document.GoodsShipmentToCustomer AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|		LEFT JOIN Document.GoodsShipmentToCustomer.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
	|		ON GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref
	|			AND GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &DeliveryIsRequired
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.SelfPickup)
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.OurCourier)
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND (&ShipmentByOrders
	|				AND (GoodsTable.RowCode = 0
	|					OR GoodsTable.SalesOrder.ThisIsOrderAsInvoice = TRUE)
	|				AND VALUETYPE(GoodsTable.SalesOrder) IN (&AcceptableTypesOfDeliveryOrders)
	|			OR NOT &ShipmentByOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentHeader.DeliveryPlanning,
	|	GoodsTable.LineNumber,
	|	BEGINOFPERIOD(&Period, DAY),
	|	DocumentHeader.Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo),
	|	BEGINOFPERIOD(&Period, DAY),
	|	VALUE(Enum.TransportMethods25.ByCarrier),
	|	DocumentHeader.CarrierPartner,
	|	DocumentHeader.CarrierPartner,
	|	DocumentHeader.CarrierDeliveryPoint,
	|	DocumentHeader.CarrierSDeliveryArea,
	|	DocumentHeader.Partner,
	|	DocumentHeader.DeliveryPoint,
	|	DocumentHeader.DeliveryZone,
	|	CASE
	|		WHEN &ShipmentByOrders
	|				AND NOT GoodsTable.SalesOrder.ThisIsOrderAsInvoice
	|			THEN GoodsTable.SalesOrder
	|		WHEN DocumentHeader.Patch
	|			THEN DocumentHeader.CorrectedDocument
	|		ELSE &Ref
	|	END,
	|	UNDEFINED,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	CASE
	|		WHEN &ShipmentByOrders
	|			THEN GoodsTable.DeliveryLineCode
	|		ELSE GoodsTable.RowCode
	|	END,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|				AND NOT DocumentHeader.Patch
	|			THEN &Ref
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|				AND DocumentHeader.Patch
	|			THEN DocumentHeader.CorrectedDocument
	|		ELSE UNDEFINED
	|	END,
	|	2,
	|	GoodsTable.Package,
	|	GoodsTable.Count,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	&OperationLevel,
	|	TRUE,
	|	0,
	|	FALSE,
	|	DATETIME(1, 1, 1),
	|	VALUE(Catalog.Assignments.EmptyRef)
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|		LEFT JOIN Document.GoodsShipmentToCustomer AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|		LEFT JOIN Document.GoodsShipmentToCustomer.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
	|		ON GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref
	|			AND GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &DeliveryIsRequired
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.SelfPickup)
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.OurCourier)
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND DocumentHeader.DeliveryToCarrier
	|	AND (&ShipmentByOrders
	|				AND (GoodsTable.RowCode = 0
	|					OR GoodsTable.SalesOrder.ThisIsOrderAsInvoice = TRUE)
	|				AND VALUETYPE(GoodsTable.SalesOrder) IN (&AcceptableTypesOfDeliveryOrders)
	|			OR NOT &ShipmentByOrders)";
	
	AcceptableTypesOfDeliveryOrders = New Array; // Array of Type
	AcceptableTypesOfDeliveryOrders.Add(Type("DocumentRef.SalesOrder"));
	AcceptableTypesOfDeliveryOrders.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	Query.SetParameter("AcceptableTypesOfDeliveryOrders", AcceptableTypesOfDeliveryOrders);
	
	QueryText = StrReplace(QueryText, "Document.GoodsShipmentToCustomer.Goods", "DocumentDataTableItems");
	QueryText = StrReplace(QueryText, "Document.GoodsShipmentToCustomer AS DocumentHeader", "DocumentDataHeader AS DocumentHeader");
	QueryText = StrReplace(QueryText, "GoodsTable.Products.ItemsType", "GoodsTable.ProductsTypeOfProducts");
	QueryText = StrReplace(QueryText, "GoodsTable.SalesOrder.ThisIsOrderAsInvoice", "GoodsTable.SalesOrderIsOrderAsInvoice");
	
	SynonymForDocumentTable = "DataTable";
	GoodsDelivery.SetParametersOfEventRequest(Query, AddlParameters);
	GoodsDelivery.AddDocumentReflectionRequest(Query, Registers, QueryTexts, QueryText, SynonymForDocumentTable);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TTProductsOfOrganizations.LineNumber				AS LineNumber,
	|	TTProductsOfOrganizations.RecordType				AS RecordType,
	|	TTProductsOfOrganizations.Period					AS Period,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Organization				AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.CCDNumber				AS CCDNumber,
	|	TTProductsOfOrganizations.Count				AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN		AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation	AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation		AS VATTaxation,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute			AS CorInventoryOwnerAttribute,
	|	TTProductsOfOrganizations.ShipmentCompany		AS ShipmentCompany,
	|	TTProductsOfOrganizations.Products			AS Products,
	|	TTProductsOfOrganizations.Characteristic			AS Characteristic
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Returns the Query Text of the temporary table of Registered Records of the Accumulation register of organizations' products.
//
// Parameters:
//	Query - Query - request for a document.
//	QueryTexts - ValueList of String - collection of Query Texts for the event.
//
// Returns:
//	String - The Query Text of the temporary table of Registered Records of the Accumulation register of organizations' goods.
//
Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period								AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany
	|		ELSE TableTypesOfStocks_.Organization
	|	END								AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END								AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count		AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountExcludingVATCompl	AS CostOfProductBatchID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	&BusinessOperation				AS BusinessOperation,
	|	UNDEFINED						AS VATTaxation,
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Organization		AS ShipmentCompany,
	|	TableTypesOfStocks_.Products		AS Products,
	|	TableTypesOfStocks_.Characteristic	AS Characteristic
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period								AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Organization		AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count		AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountExcludingVATCompl	AS CostOfProductBatchID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	&BusinessOperation				AS BusinessOperation,
	|	UNDEFINED						AS VATTaxation,
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Organization		AS ShipmentCompany,
	|	TableTypesOfStocks_.Products		AS Products,
	|	TableTypesOfStocks_.Characteristic	AS Characteristic
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	CCDNumberCCDNumberType
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber                AS LineNumber,
	|	InventoryKinds.Ref                     AS Ref,
	|	InventoryKinds.SalesOrder               AS SalesOrder,
	|	&Organization                           AS Organization,
	|	Dimension.StorageLocation                AS Warehouse,
	|	InventoryKinds.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType      AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS InventoryOwnerAttributeSaleOfAnotherCompanySInventory,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeInventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany,
	|	InventoryKinds.SetAccountingDimension      AS SetAccountingDimension,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey   AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	AnalyticsForShipmentsWithoutDestination.DimensionKey AS InventoriedLocationAttributesOfShipmentWithoutDestination,
	|	ISNULL(CountryItemVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)) AS VATRate,
	|	Dimension.Products                 AS Products,
	|	Dimension.Characteristic               AS Characteristic,
	|	Dimension.Series						   AS Series,
	|	InventoryKinds.Package                   AS Package,
	|	InventoryKinds.Count                 AS Count,
	|	InventoryKinds.NumberOfPackages         AS NumberOfPackages,
	|	InventoryKinds.QuantityByGBRN           AS QuantityByGBRN,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)     AS AmountExcludingVATCompl,
	|	InventoryKinds.Sum                      AS Sum,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	InventoryKinds.CCDNumber.CCDNumberType      AS CCDNumberCCDNumberType,
	|	InventoryKinds.FEACNCode                   AS FEACNCode,
	|	InventoryKinds.RowCode                  AS RowCode,
	|	ISNULL(Dimension.Products.TracedGoods, FALSE) AS TracedGoods,
	|	CASE
	|		WHEN Dimension.Purpose.LineOfBusiness IS NULL
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE Dimension.Purpose.LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN &VATTaxation IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|			AND ISNULL(VATRates.Ref, UNDEFINED) = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) AND InventoryKinds.FEACNCode.Commodity
	|		THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|		THEN VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|		WHEN ISNULL(Dimension.Purpose.VATActivityType, &VATTaxation) = VALUE(Enum.SeparateVATAccountingOptions.EmptyRef)
	|		THEN &TaxationOfOrganization
	|		ELSE ISNULL(Dimension.Purpose.VATActivityType, &VATTaxation)
	|	END AS VATActivityType,
	|	InventoryKinds.RowID        AS RowID
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.GoodsShipmentToCustomer.InventoryKinds AS InventoryKinds
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		InventoryKinds.Ref = Amounts.Ref
	|		AND InventoryKinds.RowID = Amounts.RowID
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsForShipmentsWithoutDestination
	|		ON InventoryKinds.ItemsLocationAttributesShipment.Products = AnalyticsForShipmentsWithoutDestination.Products
	|			AND InventoryKinds.ItemsLocationAttributesShipment.Characteristic = AnalyticsForShipmentsWithoutDestination.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributesShipment.Series = AnalyticsForShipmentsWithoutDestination.Series
	|			AND InventoryKinds.ItemsLocationAttributesShipment.StorageLocation = AnalyticsForShipmentsWithoutDestination.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsForShipmentsWithoutDestination.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsForShipmentsWithoutDestination.ProductCostElement
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS CountryItemVATRates
	|		ON Dimension.Products = CountryItemVATRates.Products
	|			AND (CountryItemVATRates.VATRate.BeginOfPeriod <= &Period
	|				OR CountryItemVATRates.VATRate.BeginOfPeriod = DATETIME(1, 1, 1))
	|			AND (CountryItemVATRates.VATRate.EndOfPeriod >= &Period
	|				OR CountryItemVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1))
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period, Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON Dimension.Products = ProductsVATRates.Products
	|			AND (ProductsVATRates.VATRate.BeginOfPeriod <= &Period
	|				OR ProductsVATRates.VATRate.BeginOfPeriod = DATETIME(1, 1, 1))
	|			AND (ProductsVATRates.VATRate.EndOfPeriod >= &Period
	|				OR ProductsVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1))
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
	|		ON (BasicVATRates.VATRate.BeginOfPeriod <= &Period
	|			OR BasicVATRates.VATRate.BeginOfPeriod = DATETIME(1, 1, 1))
	|			AND (BasicVATRates.VATRate.EndOfPeriod >= &Period
	|				OR BasicVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1))
	|		LEFT JOIN Catalog.VATRates AS VATRates
	|		ON (CountryItemVATRates.VATRate = VATRates.Ref
	|				AND (VATRates.BeginOfPeriod <= &Period OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
	|				AND (VATRates.EndOfPeriod >= &Period OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
	|			OR CountryItemVATRates.VATRate IS NULL AND ProductsVATRates.VATRate = VATRates.Ref
	|				AND (VATRates.BeginOfPeriod <= &Period OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
	|				AND (VATRates.EndOfPeriod >= &Period OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
	|			OR CountryItemVATRates.VATRate IS NULL AND BasicVATRates.VATRate IS NULL AND ProductsVATRates.VATRate = VATRates.Ref
	|				AND (VATRates.BeginOfPeriod <= &Period OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
	|				AND (VATRates.EndOfPeriod >= &Period OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
	|		)
	|
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
	|	AnalystTable.Products   AS Products,
	|	AnalystTable.Characteristic AS Characteristic,
	|	&EmptyAssignment              AS Purpose,
	|	AnalystTable.Series          AS Series,
	|	AnalystTable.Warehouse          AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		Goods.ItemsLocationAttributes.Products   AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Goods.ItemsLocationAttributes.Series          AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|	FROM
	|		Document.GoodsShipmentToCustomer.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributes.Products = Dimension.Products
	|				AND Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|				AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		Goods.ItemsLocationAttributesShipment.Products   AS Products,
	|		Goods.ItemsLocationAttributesShipment.Characteristic AS Characteristic,
	|		Goods.ItemsLocationAttributesShipment.Series          AS Series,
	|		Goods.ItemsLocationAttributesShipment.StorageLocation  AS Warehouse
	|	FROM
	|		Document.GoodsShipmentToCustomer.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributesShipment.Products = Dimension.Products
	|				AND Goods.ItemsLocationAttributesShipment.Characteristic = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributesShipment.Series = Dimension.Series
	|				AND Goods.ItemsLocationAttributesShipment.StorageLocation = Dimension.StorageLocation
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	) AS AnalystTable";
	
	QueryAnalyst.SetParameter("Ref",				Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",	Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
										Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	//Sets
	QueryAnalyst = New Query;
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	Goods.SetAccountingDimension.ProductsInSet		AS ProductsInSet,
	|	Goods.SetAccountingDimension.ItemVariantOfSet	AS ItemVariantOfSet
	|FROM
	|	Document.GoodsShipmentToCustomer.InventoryKinds AS Goods
	|		LEFT JOIN InformationRegister.SetAccountingDimension AS Dimension
	|		ON Goods.SetAccountingDimension.ProductsInSet = Dimension.ProductsInSet
	|			AND Goods.SetAccountingDimension.ItemVariantOfSet = Dimension.ItemVariantOfSet
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.ProductsInSet IS NULL";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.SetAccountingDimension.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.GoodsShipmentToCustomer";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	TextOfRequestToRedefineBusinessTransaction = "
		|	CASE
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer)
		|		ELSE GoodsTable.Ref.BusinessOperation
		|	END";
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
								Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("UseAdvancedFeaturesOfSalesOrder",
								GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",         """""");
	RedefiningParameterCalculation.Insert("ShipmentByOrders",     "GoodsTable.Ref.ShipmentByOrders");
	RedefiningParameterCalculation.Insert("ContractInformation",  """""");
	RedefiningParameterCalculation.Insert("BusinessOperation", TextOfRequestToRedefineBusinessTransaction);
	
	If RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
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
	
	If SynonymForDocumentTable <> "GoodsTable" Then
		For Each CalculationParameter In RedefiningParameterCalculation Do
			RedefiningParameterCalculation[CalculationParameter.Key] = StrReplace(
				CalculationParameter.Value, "GoodsTable", SynonymForDocumentTable);
		EndDo;
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref         AS Ref,
	|	TabPart.Ref.Date    AS Period,
	|	TabPart.Products   AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Warehouse          AS Warehouse,
	|	TabPart.Purpose     AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count     AS Count,
	|	UNDEFINED            AS PlannedConsumptionOfDistributedStock,
	|	TRUE                  AS ControlOfFreeResidue
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS TabPart
	|WHERE
	|	TabPart.RowCode = 0
	|		OR NOT TabPart.Ref.ShipmentByOrders
	|		OR TabPart.SalesOrder IN (
	|				UNDEFINED,
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|				)
	|		OR ISNULL(TabPart.SalesOrder.ThisIsOrderAsInvoice, FALSE)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	ValueText_ = "
	|SELECT
	|	ShipmentOfItems.Date AS Period,
	|	ShipmentOfItems.Ref AS Ref,
	|	ShipmentOfItems.BusinessOperation AS BusinessOperation,
	|	ShipmentOfItems.Counterparty AS Counterparty,
	|	ShipmentOfItems.Contract AS Contract,
	|	ShipmentOfItems.Shipper AS Shipper,
	|	ShipmentOfItems.GoodsRecipient AS GoodsRecipient,
	|	ShipmentOfItems.Organization AS Organization,
	|	ShipmentOfItems.Department AS Department,
	|	CASE
	|		WHEN ShipmentOfItems.Patch
	|			THEN ShipmentOfItems.CorrectedDocument
	|		ELSE
	|			ShipmentOfItems.Ref
	|	END AS DocumentSalesOfGoodsAndServices,
	|	FALSE AS SalesViaCommissionAgent,
	|	CASE
	|		WHEN ShipmentOfItems.Patch
	|			THEN ShipmentOfItems.Ref
	|		ELSE
	|			UNDEFINED
	|	END AS ImplementationAdjustmentDocument,
	|	CASE
	|		WHEN ShipmentOfItems.ShipmentByOrders
	|			AND NOT TypesOfTSStocks.SalesOrder.ThisIsOrderAsInvoice
	|			THEN TypesOfTSStocks.SalesOrder
	|		WHEN ShipmentOfItems.Patch
	|			THEN ShipmentOfItems.CorrectedDocument
	|		ELSE
	|			ShipmentOfItems.Ref
	|	END AS ShipmentReferenceOrder,
	|	ShipmentOfItems.Patch AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|			THEN ISNULL(ItemsOfCustomerSOrder.VATRate, &ExportVATRate)
	|		ELSE
	|			ISNULL(ItemsOfCustomerSOrder.VATRate, VALUE(Catalog.VATRates.EmptyRef))
	|	END AS VATRate,
	|	TypesOfTSStocks.Products                           AS Products,
	|	TypesOfTSStocks.Characteristic                         AS Characteristic,
	|	TypesOfTSStocks.Series                                  AS Series,
	|	UNDEFINED                                         AS PartnerProducts,
	|	TypesOfTSStocks.SetAccountingDimension.ProductsInSet     AS ProductsInSet,
	|	TypesOfTSStocks.SetAccountingDimension.ItemVariantOfSet   AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|				OR TypesOfTSStocks.NumberOfPackages = 0
	|			THEN TypesOfTSStocks.Count
	|		ELSE TypesOfTSStocks.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN TypesOfTSStocks.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	TypesOfTSStocks.QuantityByGBRN AS QuantityByGBRN,
	|	CASE
	|		WHEN ISNULL(ItemsOfCustomerSOrder.Count, 0) = 0
	|			THEN TypesOfTSStocks.Sum
	|		ELSE
	|			ItemsOfCustomerSOrder.AmountIncludingVAT * TypesOfTSStocks.Count / ItemsOfCustomerSOrder.Count
	|	END AS Sum,
	|	CASE
	|		WHEN ISNULL(ItemsOfCustomerSOrder.Count, 0) = 0
	|			THEN 0
	|		ELSE
	|			ItemsOfCustomerSOrder.VATAmount * TypesOfTSStocks.Count / ItemsOfCustomerSOrder.Count
	|	END AS VATAmount,
	|	CASE
	|		WHEN &Currency <> &LocalAccountingCurrency
	|			THEN 0
	|		WHEN ISNULL(ItemsOfCustomerSOrder.Count, 0) = 0
	|			THEN TypesOfTSStocks.Sum
	|		ELSE
	|			ItemsOfCustomerSOrder.AmountIncludingVAT * TypesOfTSStocks.Count / ItemsOfCustomerSOrder.Count
	|	END AS SumCompl,
	|	CASE
	|		WHEN &Currency <> &LocalAccountingCurrency
	|			THEN 0
	|		WHEN ISNULL(ItemsOfCustomerSOrder.Count, 0) = 0
	|			THEN 0
	|		ELSE
	|			ItemsOfCustomerSOrder.VATAmount * TypesOfTSStocks.Count / ItemsOfCustomerSOrder.Count
	|	END AS VATAmountCompl,
	|	TypesOfTSStocks.CCDNumber AS CCDNumber,
	|	TypesOfTSStocks.FEACNCode AS FEACNCode,
	|	TypesOfTSStocks.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TypesOfTSStocks.LineNumber AS LineNumber,
	|	TypesOfTSStocks.RowCode AS RowCode,
	|	TypesOfTSStocks.RowID AS RowID,
	|	TypesOfTSStocks.RowID AS FinRecordID,
	|	ShipmentOfItems.VATTaxation AS VATTaxation,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.GoodsShipmentToCustomer AS ShipmentOfItems
	|		
	|		LEFT JOIN TTTableTypesOfStocks AS TypesOfTSStocks
	|		ON ShipmentOfItems.Ref = TypesOfTSStocks.Ref
	|
	|		LEFT JOIN Document.SalesOrder.Goods AS ItemsOfCustomerSOrder
	|		ON TypesOfTSStocks.SalesOrder = ItemsOfCustomerSOrder.Ref
	|			AND TypesOfTSStocks.RowCode = ItemsOfCustomerSOrder.RowCode
	|			AND NOT TypesOfTSStocks.SalesOrder.ThisIsOrderAsInvoice
	|		
	|WHERE
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	CASE
	|			WHEN NOT TypesOfTSStocks.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"TypesOfTSStocks.Package",
			"TypesOfTSStocks.ItemsLocationAttributes.Products"));
	
	VATAccountingERP.ReflectShipmentToCustomer(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
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
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period AS Period,
	|	&Ref AS Ref,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	&SalesOpportunity AS SalesOpportunity,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|	UNDEFINED AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.RowID AS RowID,
	|
	// Other fields
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.VHFWarehouses = True;
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
		
	Return JobPrintingRules;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ThisIsPartner = UserRightsCached.ThisIsPartner();
	
	// Shipment of Goods to the Customer
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Giao hàng cho khách';
									|ru = 'Отгрузка товаров клиенту';
									|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
									|it = 'Goods shipment to customer';
									|pl = 'Goods shipment to customer';
									|tr = 'Müşteriye ürün sevkiyatı'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 11;
	
	If AccessRight("Read", Metadata.Catalogs.QualityCertificates)
		And GetFunctionalOption("UseQualityCertificates") Then
		
		// Register of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesOfProductsRegister";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (đăng ký)';
										|ru = 'Сертификаты (реестр)';
										|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
										|it = 'Certificati (registro)';
										|pl = 'Certyfikaty (rejestr)';
										|tr = 'Sertifikalar (kayıt)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 33;
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocuments";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
										|ru = 'Сертификаты (по каждой позиции документа)';
										|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
										|it = 'Certificati (per ogni voce del documento)';
										|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
										|tr = 'Sertifikalar (belgedeki her kalem için)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 34;
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocumentsWithoutDuplicates";
		PrintCommand.Presentation = NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
										|ru = 'Сертификаты (по одному на сертификат)';
										|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
										|it = 'Certificati (uno per certificato)';
										|pl = 'Certyfikaty (po jednym na certyfikat)';
										|tr = 'Sertifikalar (sertifika başına bir tane)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 35;
		
	EndIf;
	
	If Not ThisIsPartner Then
		// Task for the selection of goods
		DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask", 36);
	EndIf;
	
	If Not ThisIsPartner
		And GoodsDeliveryClientServer.UsedDelivery20() Then
		
		// Shipping Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintingShippingLabels";
		PrintCommand.PrintManager = "DataProcessor.PrintPriceTagsAndLabels.Print";
		PrintCommand.Id = "ShippingLabel";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem giao hàng';
										|ru = 'Этикетки доставки';
										|en = 'Delivery labels'; fa = 'Delivery labels';
										|it = 'Etichette di consegna';
										|pl = 'Etykiety dostawy';
										|tr = 'Teslimat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 38;

	EndIf;
	
	GoodsShipmentToCustomerLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Forms printed forms of the object.
//
// Parameters:
//	ObjectsArray        - Array           - an array of references to objects which need to print,
//	PrintParameters       - Structure        - structure of additional print parameters,
//	PrintFormsCollection - ValueTable  - generated table documents,
//	PrintObjects         - ValueList   - list of print objects,
//	OutputParameters       - Structure        - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			NStr("vi = 'Giao hàng cho khách';
				|ru = 'Отгрузка товаров клиенту';
				|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
				|it = 'Goods shipment to customer';
				|pl = 'Goods shipment to customer';
				|tr = 'Müşteriye ürün sevkiyatı'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects),
			,
			"Document.GoodsShipmentToCustomer.PF_MXL_GoodsShipmentToCustomer");
	EndIf;
		
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesOfProductsRegister") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(ObjectsArray,
																										PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateRegistry");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocuments") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(ObjectsArray,
																											PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocumentsWithoutDuplicates") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(
				ObjectsArray,PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
		
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	GoodsShipmentToCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects,
		OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// Create printed forms of objects.
//
// Parameters:
//	ObjectsArray        - Array           - an array of references to objects which need to print,
//	PrintParameters       - Structure        - structure of additional print parameters,
//	PrintFormsCollection - ValueTable  - generated table documents,
//	PrintObjects         - ValueList   - list of print objects.
//
// Returns:
//  Undefined
//
Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure")
		And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet =
			InformationRegisters.ObjectPrintSettings.PrintFormsSet(
				Metadata.Documents.GoodsShipmentToCustomer.FullName(),
				ObjectsArray,
				Undefined);
		
	EndIf;
	
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects =
		InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
			PrintFormsCollection,
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
	
	SetsOfPrintingOnObjects =
		InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
			PrintFormsCollection,
			PrintFormsSet,
			ObjectsArray,
			"GoodsPickingPlacementJob");
	
	PrintParameters.Insert("JobType", "SelectionTask");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.GoodsShipmentToCustomer", PrintKit.Objects);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.CreateTaskForProductSelectionAndPlacement(
				StructureOfTypes,
				PrintObjects,
				PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects =
		InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
			PrintFormsCollection,
			PrintFormsSet,
			ObjectsArray,
			"CertificatesOfProductsRegister");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(
				PrintKit.Objects,
				PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects =
		InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
			PrintFormsCollection,
			PrintFormsSet,
			ObjectsArray,
			"CertificatesProductImagesFromDocuments");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(
				PrintKit.Objects,
				PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects =
		InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
			PrintFormsCollection,
			PrintFormsSet,
			ObjectsArray,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(
				PrintKit.Objects,
				PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceInt");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.GoodsShipmentToCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	GoodsShipmentToCustomerLocalization.CreateSetOfPrintedForms(
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.GoodsShipmentToCustomer",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"Invoice",
																			NStr("vi = 'Giao hàng cho khách';
																				|ru = 'Отгрузка товаров клиенту';
																				|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
																				|it = 'Goods shipment to customer';
																				|pl = 'Goods shipment to customer';
																				|tr = 'Müşteriye ürün sevkiyatı'"),
																			2);
	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceInt", NStr("vi = 'Invoice';
																										|ru = 'Invoice';
																										|en = 'Invoice'; fa = 'فاکتور';
																										|it = 'Invoice';
																										|pl = 'Invoice';
																										|tr = 'Invoice'"), 2);
	EndIf;
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"CCDNumberRegistry",
																			NStr("vi = 'Số đăng ký tờ khai hải quan';
																				|ru = 'Реестр номеров ГТД';
																				|en = 'CCD number registry'; fa = 'دفتر ثبت شماره‌های CCD';
																				|it = 'Registro numeri delle dichiarazioni doganali di carico';
																				|pl = 'Wykaz numerów towarowej deklaracji celnej';
																				|tr = 'GB numaraları kaydı'"),
																			0);
	
	If GetFunctionalOption("UseQualityCertificates") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																				"CertificatesOfProductsRegister",
																				NStr("vi = 'Giấy chứng nhận (đăng ký)';
																					|ru = 'Сертификаты (реестр)';
																					|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
																					|it = 'Certificati (registro)';
																					|pl = 'Certyfikaty (rejestr)';
																					|tr = 'Sertifikalar (kayıt)'"),
																				0);
		
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																				"CertificatesProductImagesFromDocuments",
																				NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
																					|ru = 'Сертификаты (по каждой позиции документа)';
																					|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
																					|it = 'Certificati (per ogni voce del documento)';
																					|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
																					|tr = 'Sertifikalar (belgedeki her kalem için)'"),
																				0);
		
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																				"CertificatesProductImagesFromDocumentsWithoutDuplicates",
																				NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
																					|ru = 'Сертификаты (по одному на сертификат)';
																					|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
																					|it = 'Certificati (uno per certificato)';
																					|pl = 'Certyfikaty (po jednym na certyfikat)';
																					|tr = 'Sertifikalar (sertifika başına bir tane)'"),
																				0);
	EndIf;
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"GoodsPickingPlacementJob",
																			NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
																				|ru = 'Задание на отбор товаров';
																				|en = 'Picking job'; fa = 'کار برداشت';
																				|it = 'Task per selezione prodotti';
																				|pl = 'Zadanie na selekcję towarów';
																				|tr = 'Ürün filtre görevi'"),
																			0);
	
	GoodsShipmentToCustomerLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

// The function generates a printed Form of documents for shipment of goods to the client.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - printed Form of documents for shipment of goods to the client.
//
Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	ShipmentOfItems.Ref          AS Ref,
	|	ShipmentOfItems.Number           AS Number,
	|	ShipmentOfItems.Date            AS Date,
	|	ShipmentOfItems.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	ShipmentOfItems.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected,
	|	ShipmentOfItems.Partner         AS Partner,
	|	ShipmentOfItems.Counterparty      AS Recipient,
	|	ShipmentOfItems.Organization     AS Organization,
	|	ShipmentOfItems.Organization.Prefix AS Prefix,
	|	ShipmentOfItems.Currency          AS Currency,
	|	ShipmentOfItems.IssuiedBy        AS VacationProduced,
	|	ShipmentOfItems.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.GoodsShipmentToCustomer AS ShipmentOfItems
	|WHERE
	|	ShipmentOfItems.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ShipmentOfItems.Ref         AS Ref,
	|	ShipmentOfItems.LineNumber    AS LineNumber,
	|	KitConfigurations.Ref    AS ItemKitConfiguration,
	|	KitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.SetPricingOption AS SetPricingOption,
	|	ShipmentOfItems.ProductsInSet   AS ProductsInSet,
	|	ShipmentOfItems.ItemVariantOfSet AS ItemVariantOfSet,
	|	ShipmentOfItems.Products   AS Products,
	|	ShipmentOfItems.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ShipmentOfItems.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN ShipmentOfItems.Products.UnitOfMeasure
	|		ELSE ShipmentOfItems.Package
	|	END                          AS UnitOfMeasure,
	|	ShipmentOfItems.Package       AS Package,
	|	CASE
	|		WHEN ShipmentOfItems.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor1
	|	END                          AS ZoomRatio,
	|	ShipmentOfItems.Count     AS Count,
	|	ShipmentOfItems.NumberOfPackages AS NumberOfPackages,
	|	ShipmentOfItems.Sum / ShipmentOfItems.NumberOfPackages AS Price,
	|	ShipmentOfItems.Sum          AS Sum
	|INTO Goods
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItems
	|	LEFT JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON KitConfigurations.Owner = ShipmentOfItems.ProductsInSet
	|		AND KitConfigurations.Characteristic = ShipmentOfItems.ItemVariantOfSet
	|		AND KitConfigurations.Main
	|WHERE
	|	ShipmentOfItems.Ref IN(&DocumentsArray)
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT DISTINCT
	|	Goods.Ref AS Ref
	|INTO PrintDocuments_1
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration
	|INTO DocumentConfigurations
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	TableOfGoods.Ref                AS Ref,
	|	MIN(TableOfGoods.LineNumber)  AS LineNumber,
	|	TableOfGoods.ProductsInSet    AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet  AS ItemVariantOfSet,
	|	SUM(TableOfGoods.Sum)          AS Sum
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Goods.Ref               AS Ref,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END                       AS MainComponent,
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet   AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products         AS Products,
	|	Goods.Characteristic       AS Characteristic,
	|	0                           AS DefaultQuantity,
	|	Goods.Count           AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	PrintDocuments_1.Ref                     AS Ref,
	|	FALSE                                       AS MainComponent,
	|	KitConfigurations.Ref                AS ItemKitConfiguration,
	|	KitConfigurations.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.Ref.SetPricingOption AS SetPricingOption,
	|	KitConfigurations.Ref.Owner       AS ProductsInSet,
	|	KitConfigurations.Ref.Characteristic AS ItemVariantOfSet,
	|	KitConfigurations.Products          AS Products,
	|	KitConfigurations.Characteristic        AS Characteristic,
	|	SUM(KitConfigurations.Count)     AS DefaultQuantity,
	|	0                                          AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS KitConfigurations
	|		LEFT JOIN PrintDocuments_1 AS PrintDocuments_1
	|		ON TRUE
	|WHERE
	|	KitConfigurations.Ref IN
	|		(SELECT
	|			Configuration_.ItemKitConfiguration
	|		FROM DocumentConfigurations AS Configuration_)
	|
	|GROUP BY
	|	PrintDocuments_1.Ref,
	|	KitConfigurations.Ref,
	|	KitConfigurations.Ref.Owner,
	|	KitConfigurations.Ref.Characteristic,
	|	KitConfigurations.Products,
	|	KitConfigurations.Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	Table.Ref               AS Ref,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	Table.ItemKitConfiguration AS ItemKitConfiguration,
	|	Table.SetPricingOption AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count)    AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	Result.Ref               AS Ref,
	|	Result.ItemKitConfiguration AS ItemKitConfiguration,
	|	Result.SetPricingOption AS SetPricingOption,
	|	Result.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Result.ProductsInSet   AS ProductsInSet,
	|	Result.ItemVariantOfSet AS ItemVariantOfSet,
	|	CAST(MIN(CASE
	|		WHEN Result.DefaultQuantity <> 0
	|				AND Result.MainComponent
	|			THEN Result.Count / Result.DefaultQuantity
	|		ELSE NULL
	|	END) + 0.5 AS NUMBER(10,0)) - 1 AS Count,
	|	MAX(CASE
	|		WHEN Result.DefaultQuantity <> 0
	|			THEN Result.Count / Result.DefaultQuantity
	|		ELSE NULL
	|	END)                         AS CoefficientMaximum,
	|	CAST(MIN(CASE
	|		WHEN Result.DefaultQuantity <> 0
	|			THEN Result.Count / Result.DefaultQuantity
	|		ELSE NULL
	|	END) + 0.5 AS NUMBER(10,0)) - 1 AS MinimumRatio
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	Table.Ref               AS Ref,
	|	Table.LineNumber          AS LineNumber,
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ItemKitConfiguration,
	|	CASE
	|		WHEN CASE
	|				WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|					THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|				ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|				END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|				AND TemporaryTableSetsOptional.SetPricingOption IN(
	|					VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|					VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|			THEN VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE TemporaryTableSetsOptional.SetPricingOption
	|	END                        AS SetPricingOption,
	|	CASE
	|		WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|			THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END                        AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	CASE
	|		WHEN TemporaryTableSetsOptional.MinimumRatio = TemporaryTableSetsOptional.CoefficientMaximum
	|			THEN TRUE
	|		ELSE FALSE
	|	END                        AS FullSet,
	|	Table.Sum                AS Sum
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.Ref = TemporaryTableSetsOptional.Ref
	|			AND Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT
	|	NestedQuery.Ref               AS Ref,
	|	NestedQuery.LineNumber          AS LineNumber,
	|	NestedQuery.SetPricingOption AS SetPricingOption,
	|	NestedQuery.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	NestedQuery.ProductsInSet   AS ProductsInSet,
	|	NestedQuery.ItemVariantOfSet AS ItemVariantOfSet,
	|	NestedQuery.Products         AS Products,
	|	NestedQuery.Products.Code     AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.Products.DescriptionFull AS ProductNameFull_,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	NestedQuery.UnitOfMeasure.Description AS UnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor2, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END                                AS Package,
	|	NestedQuery.NumberOfPackages   AS Count,
	|	NestedQuery.Price                 AS Price,
	|	NestedQuery.Sum                AS Sum,
	|	0                                    AS VATAmount,
	|	NestedQuery.TheseAreComponents     AS TheseAreComponents,
	|	NestedQuery.IsRecordsSet             AS IsRecordsSet,
	|	NestedQuery.FullSet          AS FullSet,
	|	CASE
	|		WHEN NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		Table.Ref               AS Ref,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END                        AS LineNumber,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.SetPricingOption
	|			ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END                        AS SetPricingOption,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.PresentationOptionInPrintForms
	|			ELSE VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END                        AS PresentationOptionInPrintForms,
	|		Table.ProductsInSet   AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		Table.Products         AS Products,
	|		Table.Characteristic       AS Characteristic,
	|		Table.UnitOfMeasure     AS UnitOfMeasure,
	|		Table.Package             AS Package,
	|		Table.Count           AS Count,
	|		Table.NumberOfPackages   AS NumberOfPackages,
	|		Table.Price                 AS Price,
	|		Table.Sum                AS Sum,
	|		VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|		0                            AS VATAmount,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END                        AS TheseAreComponents,
	|		FALSE                         AS IsRecordsSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.FullSet
	|			ELSE FALSE
	|		END                        AS FullSet
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.Ref = Table.Ref
	|				AND TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|				AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|			AND TemporaryTableSets.PresentationOptionInPrintForms IN(
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableSets.Ref               AS Ref,
	|		TemporaryTableSets.LineNumber          AS LineNumber,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		TemporaryTableSets.ProductsInSet   AS ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet AS ItemVariantOfSet,
	|		TemporaryTableSets.ProductsInSet   AS Products,
	|		TemporaryTableSets.ItemVariantOfSet AS Characteristic,
	|		TemporaryTableSets.ProductsInSet.UnitOfMeasure AS UnitOfMeasure,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.Count           AS Count,
	|		TemporaryTableSets.NumberOfPackages   AS NumberOfPackages,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|				THEN (TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE 0
	|		END                                       AS Price,
	|		TemporaryTableSets.Sum                AS Sum,
	|		VALUE(Catalog.VATRates.EXCLUDINGVAT)       AS VATRate,
	|		0                                           AS VATAmount,
	|		FALSE                                        AS TheseAreComponents,
	|		TRUE                                      AS IsRecordsSet,
	|		TemporaryTableSets.FullSet          AS FullSet
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN(
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber,
	|	IsRecordsSet DESC
	|
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ShipmentOfItems.Package",
			"ShipmentOfItems.Products"));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	FirstDocument = True;
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes   = ValueIsFilled(NameOfCodeColumn);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsShipmentToCustomer_Invoice";
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[9]; // QueryResult
	
	PrintData		= ResultPrintData.Select();
	SelectionByDocuments	= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate("Document.GoodsShipmentToCustomer.PF_MXL_GoodsShipmentToCustomer");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea,
			PrintData.Ref);
			
		TitleLine = NStr("vi = 'Giao hàng cho khách';
						|ru = 'Отгрузка товаров клиенту';
						|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
						|it = 'Goods shipment to customer';
						|pl = 'Goods shipment to customer';
						|tr = 'Müşteriye ürün sevkiyatı'", Common.DefaultLanguageCode());
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData, TitleLine);
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TitleText);
		
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		
		DateOfReceiptOfInformation = ?(ValueIsFilled(PrintData.DateOfDocumentBeingCorrected),
									PrintData.DateOfDocumentBeingCorrected,
									PrintData.Date);
		
		SupplierPresentation = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, DateOfReceiptOfInformation),
				"FullDescr");
		
		DataStructureProvider = New Structure;
		DataStructureProvider.Insert("Vendor",               PrintData.Organization);
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, DateOfReceiptOfInformation),
				"FullDescr");
		
		CustomerDataStructure = New Structure;
		CustomerDataStructure.Insert("Recipient",              PrintData.Recipient);
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		TableHeader = "TableHeader";
		ProductPostfix = "OwnGoods";
		Data = "Data";
		
		ProductColumnArea = Template.Area("FirstColumnOfGoods");
		ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
			+ ?(OutputCodes, 0, Template.Area("ColumnOfCodes").ColumnWidth);
		
		RoomArea = Template.GetArea(TableHeader + "|LineNumber");
		AreaCodes  = Template.GetArea(TableHeader + "|ColumnOfCodes");
		ProductArea  = Template.GetArea(TableHeader + "|" + ProductPostfix);
		DataArea = Template.GetArea(TableHeader + "|" + Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		TableRow = "TableRow";
		LineNumberAreaStandard = Template.GetArea(TableRow + "|LineNumber");
		ScopeOfStringCodesStandard  = Template.GetArea(TableRow + "|ColumnOfCodes");
		ProductAreaRowsStandard  = Template.GetArea(TableRow + "|" + ProductPostfix);
		DataAreaOfStringIsStandard = Template.GetArea(TableRow + "|" + Data);
		
		UseSets = False;
		
		If TMCommonUseClientServer.HasObjectAttribute(SelectionByDocuments, "IsRecordsSet") Then
			UseSets = True;
			
			TableRowSet = "TableRowSet";
			TableRowComponents = "TableRowComponents";
			LineNumberAreaSet         = Template.GetArea(TableRowSet + "|LineNumber");
			LineNumberAreaComponents = Template.GetArea(TableRowComponents + "|LineNumber");
			StringCodeAreaSet          = Template.GetArea(TableRowSet + "|ColumnOfCodes");
			StringCodeAreaComponents  = Template.GetArea(TableRowComponents + "|ColumnOfCodes");
			ProductAreaRowsSet          = Template.GetArea(TableRowSet + "|" + ProductPostfix);
			ProductAreaRowsComponents  = Template.GetArea(TableRowComponents + "|" + ProductPostfix);
			RowDataAreaSet         = Template.GetArea(TableRowSet + "|" + Data);
			RowDataAreaComponents = Template.GetArea(TableRowComponents + "|" + Data);
		EndIf;
		
		Sum		= 0;
		LineNumber	= 0;
		
		BlankData = SetsServer.BlankData();
		
		// Output the rows of the Goods table
		ProductSelection_1 = SelectionByDocuments.Select();
		
		While ProductSelection_1.Next() Do
			
			If SetsServer.UseSetArea(ProductSelection_1, UseSets) Then
				StringCodeArea  = StringCodeAreaSet;
				LineNumberArea = LineNumberAreaSet;
				RowDataArea = RowDataAreaSet;
				ProductAreaRows  = ProductAreaRowsSet;
			ElsIf SetsServer.UseScope(ProductSelection_1, UseSets) Then
				StringCodeArea  = StringCodeAreaComponents;
				LineNumberArea = LineNumberAreaComponents;
				RowDataArea = RowDataAreaComponents;
				ProductAreaRows  = ProductAreaRowsComponents;
			Else
				StringCodeArea  = ScopeOfStringCodesStandard;
				LineNumberArea = LineNumberAreaStandard;
				RowDataArea = DataAreaOfStringIsStandard;
				ProductAreaRows  = ProductAreaRowsStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				SetParameter(LineNumberArea, "LineNumber", Undefined);
			Else
				LineNumber = LineNumber + 1;
				
				SetParameter(LineNumberArea, "LineNumber", LineNumber);
			EndIf;
			
			SpreadsheetDocument.Put(LineNumberArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				
				StringCodeArea.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(StringCodeArea);
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(ProductSelection_1, UseSets);
			
			ProductAreaRows.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint) + PrefixAndPostfix.Postfix;
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductAreaRows.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductAreaRows);
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				RowDataArea.Parameters.Fill(BlankData);
			Else
				RowDataArea.Parameters.Fill(ProductSelection_1);
			EndIf;
			
			SpreadsheetDocument.Join(RowDataArea);
			
			If Not SetsServer.UseScope(ProductSelection_1, UseSets) Then
				Sum = Sum + ProductSelection_1.Sum;
			EndIf;
			
		EndDo;
		
		// We output the basement
		TableFooter = "TableFooter";
		RoomArea = Template.GetArea(TableFooter + "|LineNumber");
		AreaCodes  = Template.GetArea(TableFooter + "|ColumnOfCodes");
		ProductArea  = Template.GetArea(TableFooter + "|" + ProductPostfix);
		DataArea = Template.GetArea(TableFooter + "|" + Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		TotalDataStructure = New Structure;
		TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		
		DataArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the Amount in words
		TemplateArea = Template.GetArea("AmountInWords");
		
		AmountToBeRegistered = Sum;
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
			VacationProduced = PersonsTM.IndividualShortName(PrintData.VacationProduced, DateOfReceiptOfInformation);
			
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
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	EndIf;
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
EndProcedure

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
EndFunction

#EndRegion

#Region InfobaseUpdate

// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.GoodsShipmentToCustomer.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.62";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a9d008dc-40d8-423d-9977-bce8dd0108c9");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure =
		"Documents.GoodsShipmentToCustomer.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment =
		NStr("ru = 'Создание объектов расчетов в документах Отгрузка товаров клиенту,
		|формирование движений взаиморасчетов по отгрузке товаров без перехода права собственности для документов:
		|- Отгрузка товаров клиенту
		|- Списание отгруженных товаров
		|- Поступление товаров от клиентов
		|- Переход права собственности (Реализация товаров и услуг)';
		|vi = 'Creates AR/AP objects in the ""Goods shipment to customer"" documents,
		|generates AR/AP accounting records for the shipment of goods without transfer of title to goods for the following documents:
		|- Goods shipment to customer
		|- Shipped goods write-off
		|- Goods receipt from customer
		|- Transfer of title to goods (Customer invoice)';
		|en = 'Creates AR/AP objects in the ""Goods shipment to customer"" documents,
		|generates AR/AP accounting records for the shipment of goods without transfer of title to goods for the following documents:
		|- Goods shipment to customer
		|- Shipped goods write-off
		|- Goods receipt from customer
		|- Transfer of title to goods (Customer invoice)'; fa = 'Creates AR/AP objects in the ""Goods shipment to customer"" documents,
		|generates AR/AP accounting records for the shipment of goods without transfer of title to goods for the following documents:
		|- Goods shipment to customer
		|- Shipped goods write-off
		|- Goods receipt from customer
		|- Transfer of title to goods (Customer invoice)';
		|it = 'Creates AR/AP objects in the ""Goods shipment to customer"" documents,
		|generates AR/AP accounting records for the shipment of goods without transfer of title to goods for the following documents:
		|- Goods shipment to customer
		|- Shipped goods write-off
		|- Goods receipt from customer
		|- Transfer of title to goods (Customer invoice)';
		|pl = 'Creates AR/AP objects in the ""Goods shipment to customer"" documents,
		|generates AR/AP accounting records for the shipment of goods without transfer of title to goods for the following documents:
		|- Goods shipment to customer
		|- Shipped goods write-off
		|- Goods receipt from customer
		|- Transfer of title to goods (Customer invoice)';
		|tr = 'Müşteriye Ürün sevkiyatı belgelerinde hesaplama nesnelerinin oluşturulması,
		|mülkiyet hakkı  devri olmaksızın ürün sevkiyatına ilişkin karşılıklı ödeme hareketlerinin oluşturulması (şu belgeler için: 
		| - Müşteriye ürün sevkiyatı,
		|- Sevk edilen ürünlerin stoktan düşülmesi, 
		| - Müşterilerden ürün girişi, 
		| - Mülkiyet devri (Ürün ve hizmet satışı)'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.GoodsShipmentToCustomer.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoice.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.GoodsShipmentToCustomer.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.GoodsShipmentFromStorage.FullName());
	ToLock.Add(Metadata.Documents.CustomerInvoice.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Notes the documents of shipment of goods and transfer of ownership for processing.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.GoodsShipmentToCustomer";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	DocumentsTable.Ref AS Ref
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentsTable
	|WHERE
	|	DocumentsTable.Posted
	|	AND NOT DocumentsTable.ShipmentByOrders
	|	AND DocumentsTable.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)";
	
	PortionOfDocumentsForRegistration = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		PortionOfDocumentsForRegistration.Add(Selection.Ref);
		
		If PortionOfDocumentsForRegistration.Count() >= 1000 Then
			
			InfobaseUpdate.MarkForProcessing(Parameters, PortionOfDocumentsForRegistration);
			PortionOfDocumentsForRegistration.Clear();
			
		EndIf;
		
	EndDo;
	
	If PortionOfDocumentsForRegistration.Count() Then
		InfobaseUpdate.MarkForProcessing(Parameters, PortionOfDocumentsForRegistration);
	EndIf;
	
EndProcedure

// Performs registration of problematic data.
//
// Parameters:
// 	Document - DocumentRef - link to the problem document
// 	Recommendation - String - recommendation for correction
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//
Procedure RegisterProblematicData(Document, Recommendation, Parameters)
	
	InfobaseUpdate.MarkProcessingCompletion(Document);
	InfobaseUpdate.FileIssueWithData(
		Document,
		Recommendation,
		Parameters);
	
EndProcedure

// Document update handler.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = Metadata.Documents.GoodsShipmentToCustomer.FullName();
	NameOfRegisterSettlementsWithClients = Metadata.AccumulationRegisters.CustomersARAPAccounting.Name;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue,
			FullObjectName);
		
		Return;
		
	EndIf;
	
	Recommendation = NStr("vi = 'Chứng từ có chứa dữ liệu lỗi.
		|Hãy kiểm tra tính chính xác khi điền chứng từ và kết chuyển lại.';
		|ru = 'Документ содержит ошибочные данные.
		|Проверьте правильность заполнения документа и перепроведите его.';
		|en = 'The document contains incorrect data.
		|Check that the document is filled in correctly and post it again.'; fa = 'The document contains incorrect data.
		|Check that the document is filled in correctly and post it again.';
		|it = 'The document contains incorrect data.
		|Check that the document is filled in correctly and post it again.';
		|pl = 'The document contains incorrect data.
		|Check that the document is filled in correctly and post it again.';
		|tr = 'Belge, hatalı bilgiler içermektedir.
		|Belgenin doğru doldurulup doldurulmadığını kontrol edin ve tekrar kontrol edin.'");
	
	Query = New Query();
	Query.SetParameter("UpdatedData", UpdatedData);
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO ShippingDocumentsWithoutOrders
	|FROM
	|	&UpdatedData AS UpdatedData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ShippingDocumentsWithoutOrders.Ref AS DocumentShipment,
	|	UNDEFINED AS LinkedDocument
	|FROM
	|	ShippingDocumentsWithoutOrders AS ShippingDocumentsWithoutOrders
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ShippingDocumentsWithoutOrders.Ref AS DocumentShipment,
	|	ISNULL(TableOfGoodsOfLinkedDocument.Ref, UNDEFINED) AS LinkedDocument
	|FROM
	|	ShippingDocumentsWithoutOrders AS ShippingDocumentsWithoutOrders
	|		INNER JOIN Document.CustomerInvoice.Goods AS TableOfGoodsOfLinkedDocument
	|		ON ShippingDocumentsWithoutOrders.Ref = TableOfGoodsOfLinkedDocument.SalesOrder
	|		AND TableOfGoodsOfLinkedDocument.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ShippingDocumentsWithoutOrders.Ref AS DocumentShipment,
	|	ISNULL(TableOfGoodsOfLinkedDocument.Ref, UNDEFINED) AS LinkedDocument
	|FROM
	|	ShippingDocumentsWithoutOrders AS ShippingDocumentsWithoutOrders
	|		INNER JOIN Document.WriteOffOfShippedGoods.Goods AS TableOfGoodsOfLinkedDocument
	|		ON ShippingDocumentsWithoutOrders.Ref = TableOfGoodsOfLinkedDocument.ReferenceOrder
	|		AND TableOfGoodsOfLinkedDocument.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ShippingDocumentsWithoutOrders.Ref AS DocumentShipment,
	|	ISNULL(TableOfGoodsOfLinkedDocument.Ref, UNDEFINED) AS LinkedDocument
	|FROM
	|	ShippingDocumentsWithoutOrders AS ShippingDocumentsWithoutOrders
	|		INNER JOIN Document.GoodsReceiptFromCustomer.Goods AS TableOfGoodsOfLinkedDocument
	|		ON ShippingDocumentsWithoutOrders.Ref = TableOfGoodsOfLinkedDocument.ReferenceOrder
	|		AND TableOfGoodsOfLinkedDocument.Ref.Posted
	|TOTALS
	|BY
	|	DocumentShipment";
	
	SampleDocumentShipment = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleDocumentShipment.Next() Do
		
		DocumentShipment = SampleDocumentShipment.DocumentShipment; // DocumentRef.GoodsShipmentToCustomer
		ObjectWithIssue = DocumentShipment;
		
		BeginTransaction();
		
		Try
		
			// blocking the document shipingtowards to the client
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", DocumentShipment);
			Block.Lock();
			
			// 1) creation of a settlement object for shipping documents to the client
			ThereAreProblematicData = False;
			
			DocumentObject = DocumentShipment.GetObject();
			ARAPAccountingServer.BeforeWrite(DocumentObject, ThereAreProblematicData, DocumentWriteMode.Posting);
			
			If ThereAreProblematicData Then
				
				RegisterProblematicData(DocumentShipment, Recommendation, Parameters);
				Continue;
				
			Else
				InfobaseUpdate.WriteData(DocumentObject);
			EndIf;
			
			// 2) the creation of Registered Records for documents shipment of goods to the client
			If Not ThereAreProblematicData Then
				
				TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
					DocumentShipment,
					NameOfRegisterSettlementsWithClients);
				
				TableName = "Table" + NameOfRegisterSettlementsWithClients;
				If TablesForRegisteredRecords.Property(TableName) Then
					
					TableRecordset = TablesForRegisteredRecords[TableName];
					For Each TSRow In TableRecordset Do
						
						If Not ValueIsFilled(TSRow.AccountingDimensionByPartners)
							Or Not ValueIsFilled(TSRow.ARAPObject)
							Or Not ValueIsFilled(TSRow.Currency) Then
							
							ThereAreProblematicData = True;
							Break;
							
						EndIf;
						
					EndDo;
					
					If ThereAreProblematicData Then
						RegisterProblematicData(DocumentShipment, Recommendation, Parameters);
					Else
						
						RecordSet = AccumulationRegisters.CustomersARAPAccounting.CreateRecordSet();
						RecordSet.Filter.Recorder.Set(DocumentShipment);
						RecordSet.Load(TableRecordset);
						RecordSet.Write();
						
					EndIf;
					
				Else
					
					RegisterProblematicData(DocumentShipment, Recommendation, Parameters);
					ThereAreProblematicData = True;
					
				EndIf;
				
			EndIf;
			
			// 3) creation of Registered Records for related documents
			If Not ThereAreProblematicData Then
				
				FetchingLinkedDocument = SampleDocumentShipment.Select();
				While FetchingLinkedDocument.Next() Do
					
					LinkedDocument = FetchingLinkedDocument.LinkedDocument;
					If ValueIsFilled(LinkedDocument) Then
						
						ObjectWithIssue = LinkedDocument;
						
						TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
							LinkedDocument,
							NameOfRegisterSettlementsWithClients);
						
						TableName = "Table" + NameOfRegisterSettlementsWithClients;
						If TablesForRegisteredRecords.Property(TableName) Then
							
							TableRecordset = TablesForRegisteredRecords[TableName];
							For Each TSRow In TableRecordset Do
								
								If Not ValueIsFilled(TSRow.AccountingDimensionByPartners)
									Or Not ValueIsFilled(TSRow.ARAPObject)
									Or Not ValueIsFilled(TSRow.Currency) Then
									
									ThereAreProblematicData = True;
									Break;
									
								EndIf;
								
							EndDo;
							
							If ThereAreProblematicData Then
								RegisterProblematicData(DocumentShipment, Recommendation, Parameters);
							Else
									
								RecordSet = AccumulationRegisters.CustomersARAPAccounting.CreateRecordSet();
								RecordSet.Filter.Recorder.Set(LinkedDocument);
								RecordSet.Read();
								
								Filter = New Structure();
								Filter.Insert("RecordType", AccumulationRecordType.Expense);
								
								For Each Record In TableRecordset.FindRows(Filter) Do
									
									If ValueIsFilled(Record.BeingShipped) Then
										
										NewRecord = RecordSet.Add();
										FillPropertyValues(NewRecord, Record);
										
									EndIf;
									
								EndDo;
								
								If RecordSet.Modified() Then
									RecordSet.Write();
								EndIf;
								
							EndIf;
							
						Else
							
							RegisterProblematicData(LinkedDocument, Recommendation, Parameters);
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(
				ErrorInfo(),
				ObjectWithIssue);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
		Parameters.Queue,
		FullObjectName);
	
EndProcedure

#EndRegion

#Region Other

Function QueryTextTTGoodsOrderInvoiceShipped()
	
	QueryText = "
	|SELECT ALLOWED
	|	TTDocuments.DocumentRef       AS Ref,
	|	DocumentGoods.Warehouse             AS Warehouse,
	|	DocumentGoods.Products      AS Products,
	|	DocumentGoods.Characteristic    AS Characteristic,
	|	DocumentGoods.Series             AS Series,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.Sum)      AS AmountIncludingVAT
	|INTO TTGoodsNotShipped
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	TTDocuments.Posted
	|	AND (NOT DocumentGoods.Ref.ShipmentByOrders
	|			OR NOT &UseAdvancedFeaturesOfSalesOrder)
	|
	|GROUP BY
	|	TTDocuments.DocumentRef,
	|	DocumentGoods.Warehouse,
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series
	|;
	|";
	
	SubstituteTextUseAdvancedCustomerOrderFeatures(QueryText, "DocumentGoods.Ref", , "DocumentGoods");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDocuments()
	
	QueryText =
	"SELECT ALLOWED
	|	GoodsTable.SalesOrder AS DocumentRef,
	|	VALUETYPE(GoodsTable.SalesOrder) AS DocumentType,
	|	GoodsTable.SalesOrder.Date AS DocumentDate,
	|	GoodsTable.SalesOrder.Posted AS Posted,
	|	GoodsTable.SalesOrder.Number AS DocumentNumber
	|INTO TTDocuments
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&DocumentsArray)
	|	AND GoodsTable.Ref.ShipmentByOrders
	|	AND GoodsTable.SalesOrder <> UNDEFINED
	|	AND NOT GoodsTable.SalesOrder.ThisIsOrderAsInvoice
	|
	|UNION
	|
	|SELECT
	|	GoodsTable.Ref AS DocumentRef,
	|	VALUETYPE(GoodsTable.Ref) AS DocumentType,
	|	GoodsTable.Ref.Date AS DocumentDate,
	|	GoodsTable.Ref.Posted AS Posted,
	|	GoodsTable.Ref.Number AS DocumentNumber
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&DocumentsArray)
	|	AND GoodsTable.Ref.ShipmentByOrders
	|	AND GoodsTable.SalesOrder <> UNDEFINED
	|	AND GoodsTable.SalesOrder.ThisIsOrderAsInvoice
	|
	|UNION
	|
	|SELECT
	|	Document.Ref,
	|	VALUETYPE(Document.Ref),
	|	Document.Date,
	|	Document.Posted,
	|	Document.Number
	|FROM
	|	Document.GoodsShipmentToCustomer AS Document
	|WHERE
	|	Document.Ref IN (&DocumentsArray)
	|	AND NOT Document.ShipmentByOrders";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
	
EndFunction

// Returns the base text based on the document data and the specified calculation order.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.GoodsShipmentToCustomer - Object of the document to
// get the base text from.
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings - Procedure of settlements.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object, ARAPObjectSettings)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
			"SELECT ALLOWED
			|	CounterpartyContracts.NameForPrinting AS Basis,
			|	CounterpartyContracts.Date                  AS ReferenceDocumentDateForPrintForms,
			|	CounterpartyContracts.Number                 AS BaseDocumentNumber
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
		
	ElsIf (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		And Object.ShipmentByOrders Then
		
		AnArrayOfOrders = Undefined;
		If ValueIsFilled(Object.SalesOrder) Then
			AnArrayOfOrders = New Array;
			AnArrayOfOrders.Add(Object.SalesOrder);
		ElsIf Object.Goods.Count() <> 0 Then 
			If TypeOf(Object) = Type("Structure") Then
				AnArrayOfOrders = Object.Goods.UnloadColumn("SalesOrder");
			Else
				AnArrayOfOrders = Object.Goods.Unload(,"SalesOrder").UnloadColumn("SalesOrder");
			EndIf;
		EndIf;
		
		If AnArrayOfOrders <> Undefined Then
		
			Query = New Query(
				"SELECT ALLOWED
				|	SalesOrders.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
				|	SalesOrders.DateAccordingToInformationFromCustomer  AS DateAccordingToInformationFromCustomer,
				|	SalesOrders.Number                AS Number,
				|	SalesOrders.Date                 AS Date,
				|	&SynonymForOrder                      AS Synonym
				|FROM
				|	Document.SalesOrder AS SalesOrders
				|WHERE
				|	SalesOrders.Ref IN(&AnArrayOfOrders)
				|
				|UNION ALL
				|
				|SELECT
				|	UNDEFINED          AS NumberAccordingToCustomerData,
				|	UNDEFINED          AS DateAccordingToInformationFromCustomer,
				|	RequestsForReturn.Number AS Number,
				|	RequestsForReturn.Date  AS Date,
				|	&ApplicationSynonym        AS Synonym
				|FROM
				|	Document.RequestForReturnOfGoodsFromCustomer AS RequestsForReturn
				|WHERE
				|	RequestsForReturn.Ref IN(&AnArrayOfOrders)
				|
				|UNION ALL
				|
				|SELECT
				|	UNDEFINED            AS NumberAccordingToCustomerData,
				|	UNDEFINED            AS DateAccordingToInformationFromCustomer,
				|	ShipmentOfItems.Number   AS Number,
				|	ShipmentOfItems.Date    AS Date,
				|	&SynonymForShipment        AS Synonym
				|FROM
				|	Document.GoodsShipmentToCustomer AS ShipmentOfItems
				|WHERE
				|	ShipmentOfItems.Ref IN(&AnArrayOfOrders)

				|");
				
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder",
				NStr("vi = 'Đơn hàng của khách';
					|ru = 'Заказ клиента';
					|en = 'Sales order'; fa = 'سفارش فروش';
					|it = 'Ordine del cliente';
					|pl = 'Zamówienie klienta';
					|tr = 'Satış siparişi'", Common.DefaultLanguageCode()));
			Query.SetParameter("ApplicationSynonym",
				NStr("vi = 'Giấy đề nghị đổi hàng';
					|ru = 'Заявка на замену';
					|en = 'Request for replacement'; fa = 'Request for replacement';
					|it = 'Domanda di sostituzione';
					|pl = 'Wniosek o wymianę';
					|tr = 'Değiştirme talebi'", Common.DefaultLanguageCode()));
			Query.SetParameter("SynonymForShipment",
				NStr("vi = 'Giao hàng cho khách';
					|ru = 'Отгрузка товаров клиенту';
					|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
					|it = 'Goods shipment to customer';
					|pl = 'Goods shipment to customer';
					|tr = 'Müşteriye ürün sevkiyatı'", Common.DefaultLanguageCode()));
				
			Selection = Query.Execute().Select();
			
			TextForOrders = "";
			OneFoundation = Selection.Count() = 1;
			While Selection.Next() Do
				
				If ValueIsFilled(Selection.NumberAccordingToCustomerData) And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
					
					TextForOrders = TextForOrders
						+ ", "
						+ StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1 số %2 ngày %3';
								|ru = '%1 № %2 от %3';
								|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
								|it = '%1 № %2 dal %3';
								|pl = '%1 nr %2 z dnia %3.';
								|tr = '%2sayılı %3tarihli %1'", Common.DefaultLanguageCode()),
							Selection.Synonym,
							Selection.NumberAccordingToCustomerData,
							Format(Selection.DateAccordingToInformationFromCustomer, "DLF=DD"));
					
					DateForOrders  = Selection.DateAccordingToInformationFromCustomer;
					OrderNumber_1 = Selection.NumberAccordingToCustomerData;
					
				Else
					
					NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number);
					DocumentTitle = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 số %2 ngày %3';
							|ru = '%1 № %2 от %3';
							|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
							|it = '%1 № %2 dal %3';
							|pl = '%1 nr %2 z dnia %3.';
							|tr = '%2sayılı %3tarihli %1'", Common.DefaultLanguageCode()),
						Selection.Synonym,
						NumberForPrinting,
						Format(Selection.Date, "DLF=DD"));
					
					TextForOrders = TextForOrders + ", " + DocumentTitle;
					DateForOrders  = Selection.Date;
					OrderNumber_1 = ?(OneFoundation,ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number),"");
					
				EndIf;
			EndDo;
			StructureBase.Basis =  TrimAll(Mid(TextForOrders, 3));
			StructureBase.ReferenceDocumentDateForPrintForms = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = OrderNumber_1;
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
	
EndProcedure

Function QueryTextRemnantsOfGoodsForRegistration(TempTableName = "TTAccountingData")

	QueryText =
	"SELECT ALLOWED
	|	Set.ReferenceOrder                 AS ReferenceOrder,
	|	Set.Products                 AS Products,
	|	Set.Characteristic               AS Characteristic,
	|	Set.RowCode                    AS RowCode,
	|	Set.Series                        AS Series,
	|	Set.Warehouse                        AS Warehouse,
	|	SUM(Set.ForRegistrationQuantity) AS ForRegistrationQuantity,
	|	SUM(Set.AmountToBeProcessed)      AS AmountToBeProcessed
	|INTO TempTableName
	|FROM
	|	(SELECT
	|		Table.ReferenceOrder                   AS ReferenceOrder,
	|		Table.Products                   AS Products,
	|		Table.Characteristic                 AS Characteristic,
	|		Table.RowCode                      AS RowCode,
	|		Table.Series                          AS Series,
	|		Table.Warehouse                          AS Warehouse,
	|		Table.QuantityToBeShippedTurnover
	|			- Table.ShippedQuantityTurnover AS ForRegistrationQuantity,
	|		Table.AmountToBeShippedTurnover
	|			- Table.ShippedAmountTurnover      AS AmountToBeProcessed
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS Table
	|	WHERE
	|		Table.QuantityToBeShippedTurnover
	|			- Table.ShippedQuantityTurnover <> 0
	|		OR Table.AmountToBeShippedTurnover
	|			- Table.ShippedAmountTurnover <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.ReferenceOrder        AS ReferenceOrder,
	|		Table.Products        AS Products,
	|		Table.Characteristic      AS Characteristic,
	|		Table.RowCode           AS RowCode,
	|		Table.Series               AS Series,
	|		Table.Warehouse               AS Warehouse,
	|		Table.ShippedQuantity AS ForRegistrationQuantity,
	|		Table.ShippedAmount      AS AmountToBeProcessed
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.Ref         AS ReferenceOrder,
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.RowCode      AS RowCode,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Warehouse          AS Warehouse,
	|		GoodsTable.Count     AS ForRegistrationQuantity,
	|		GoodsTable.AmountIncludingVAT      AS AmountToBeProcessed
	|	FROM
	|		Document.SalesOrder.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN (&References)
	|		AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		AND GoodsTable.Ref.ThisIsOrderAsInvoice
	|		AND NOT GoodsTable.Canceled
	|		AND CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|				THEN GoodsTable.Warehouse IN HIERARCHY (&Warehouse)
	|						OR GoodsTable.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE
	|				GoodsTable.Warehouse = &Warehouse
	|		END
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.Ref         AS ReferenceOrder,
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.RowCode      AS RowCode,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.Warehouse          AS Warehouse,
	|		GoodsTable.Count     AS ForRegistrationQuantity,
	|		GoodsTable.AmountIncludingVAT      AS AmountToBeProcessed
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN (&References)
	|		AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		AND GoodsTable.Ref.ThisIsOrderAsInvoice
	|		AND NOT GoodsTable.Canceled
	|		AND CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|				THEN GoodsTable.Warehouse IN HIERARCHY (&Warehouse)
	|						OR GoodsTable.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE
	|				GoodsTable.Warehouse = &Warehouse
	|		END
	|	) AS Set
	|
	|GROUP BY
	|	Set.ReferenceOrder,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.RowCode,
	|	Set.Series,
	|	Set.Warehouse
	|
	|HAVING
	|	SUM(Set.ForRegistrationQuantity) > 0
	|";
	
	// Turnover of the register of the order of offloading and return
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Series, Warehouse";
	TableFormationParameters.ConditionText =
		"	ReferenceOrder IN (&References)
		|	AND Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|	AND CASE
		|		WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN TRUE
		|		WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|			THEN Warehouse IN HIERARCHY (&Warehouse)
		|		ELSE
		|			Warehouse = &Warehouse
		|	END
		|";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	// Physical table of the Order register for the return order
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"	Active
		|	AND Recorder = &Recorder
		|	AND ReferenceOrder IN (&References)
		|	AND CASE
		|		WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN TRUE
		|		WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|			THEN Warehouse IN HIERARCHY (&Warehouse)
		|		ELSE
		|			Warehouse = &Warehouse
		|	END
		|";
	TableFormationParameters.Indicators = "Shipped";
	TableFormationParameters.Resources = "Count, Sum";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	
	Return QueryText;

EndFunction

// Returns the business of operations of the Contract.
//
// Returns:
//  Array of EnumRef.BusinessTransactions
// 
Function ContractBusinessTransaction() Export
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(Enums.BusinessTransactions.SaleToCustomer);
	BusinessTransactions.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
	
	Return BusinessTransactions;
	
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

#Region UnifiedMethodsForBusinessOperations

#Region FunctionalOptionsInQueryTexts

// Changes the text of the use of advanced features of the customer order parameter in the request text.
// Must work synchronously with the unified method to use the expanded capabilities of the customer.
//
// Parameters:
//	QueryText				- String - query text.
//	TableName					- String - the name of the table in the request.
//	Parameter					- String - a parameter in the request.
//	NameOfProductsTable			- String - name of the product table in the request.
//	NameOfAttributeOfSalesOrder	- String - the Attribute name of the customer's order.
//
Procedure SubstituteTextUseAdvancedCustomerOrderFeatures(
		QueryText,
		TableName,
		Parameter = "&UseAdvancedFeaturesOfSalesOrder",
		NameOfProductsTable = "",
		NameOfAttributeOfSalesOrder = "SalesOrder") Export
	
	If Not IsBlankString(NameOfProductsTable) Then
		NewText = "NOT ISNULL(%1.%2.ThisIsOrderAsInvoice, NOT %3)"; //@Query-part
		NewText = StrTemplate(NewText, NameOfProductsTable, NameOfAttributeOfSalesOrder, Parameter);
		
		QueryText = StrReplace(QueryText, Parameter, NewText);
	EndIf;
	
	Return;
	
EndProcedure

#EndRegion

#Region Form

// Gets the default contract.
//
// Parameters:
//    Object                         - FormDataStructure, DocumentObject.GoodsShipmentToCustomer - The object from which the main parameters for the search will be taken.
//    CurrencySelection_2                  - Boolean - Search by the specified settlement currency of the Contract you are looking for (True) or
//												without taking into account the settlement currency (False).
//    FilterByLineOfBusiness - Boolean - Conduct a search in the specified area of activity of the desired Contract (True) or
//												in all directions (False).
//
// Returns:
//    CatalogRef.CounterpartyContracts - the default counterparty agreement.
//
Function GetDefaultContract(Object,
										CurrencySelection_2 = True,
										FilterByLineOfBusiness = True) Export
	
	Currency = Undefined;
	If CurrencySelection_2 Then
		Currency = Object.Currency;
	EndIf;
	
	LineOfBusiness = Undefined;
	If FilterByLineOfBusiness
	   And GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	BusinessTransactions = ContractBusinessTransaction();
	
	Contract = SalesServer.GetDefaultContract(Object,
		BusinessTransactions,
		Currency,
		LineOfBusiness);
	
	Return Contract;
	
EndFunction

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - Contains:
//           * Items - FormAllItems - Contains:
//              ** Partner - TextBox - Contains:
//                  *** Title - String - 
//              ** GoodsSalesOrder - TextBox - Contains:
//                  *** Title - String -
//              ** CloseOrder - CommandBarButton - Contains:
//                  *** Enabled - Boolean - 
//              ** CloseOrders_2 - CommandBarButton - Contains:
//                  *** Enabled - Boolean - 
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);

	RightToChangeOrders = AccessRight("Update", Metadata.Documents.SalesOrder);
	Items.CloseOrder.Enabled  = RightToChangeOrders;
	Items.CloseOrders_2.Enabled = RightToChangeOrders;
	
	UsePartnersAndCounterparties =
		GetFunctionalOption("UsePartnersAndCounterparties");
	ToUseTermsOfSales =
		GetFunctionalOption("ToUseTermsOfSales");
	
	Items.CounterpartyCheckIssueCounterpartyPages.Visible =
		UsePartnersAndCounterparties;
	
	Items.Terms.Visible = ToUseTermsOfSales;
	Items.GoodsFillThePricesByTermsOfSales.Visible = Items.Terms.Visible;
	
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
		New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.SaleToCustomer));
	
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
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink(
			"Filter.ARAPCurrency",
			"Object.Currency"));
	
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	If Not Items.Find("LineOfBusiness") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
EndProcedure

// Returns the form header of the shipment of goods to the customer document.
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
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluştur)'"), ObjectPresentation());
	Else
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 del %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), ObjectPresentation(), Number, Date);
	EndIf;
	
	Return Title;
	
EndFunction

// Returns Presentation of the document shipment of goods to the client.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Giao hàng cho khách';
				|ru = 'Отгрузка товаров клиенту';
				|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
				|it = 'Goods shipment to customer';
				|pl = 'Goods shipment to customer';
				|tr = 'Müşteriye ürün sevkiyatı'");
	
EndFunction

// Binds the Goods table rows to orders.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Object - FormDataStructure - Contains:
//  		  * Ref - DocumentRef.GoodsShipmentToCustomer - 
//  SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters
//  SelectByOrder_ - Boolean - 
//  PriceIncludesVAT - Boolean -
//
Procedure LinkRowsToOrders(Form, Object, SeriesSpecificationParameters, SelectByOrder_, PriceIncludesVAT) Export
	
	If Not Form.UseSalesOrders
		Or (Not Form.UseShipmentForMultipleOrders
			And Not ValueIsFilled(Object.SalesOrder)) Then
		Return;
	EndIf;
	
	QueryTexts = New Array;
	
	InvoiceManager = Documents.GoodsShipmentToCustomer;
	
	// 1. We get the Query Text for the Balances for shipment: [for shipment] - [shipped]
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Object);
	HeaderAttributes.Insert("PriceIncludesVAT", PriceIncludesVAT);
	HeaderAttributes.UseAdvancedFeaturesOfSalesOrder =
		UseAdvancedFeaturesOfSalesOrder(Object.Goods.Unload().UnloadColumn("SalesOrder"));
	
	References = InvoiceManager.WaybillOrders(Object.Ref, HeaderAttributes);
	CommonClientServer.DeleteValueFromArray(References, Object.Ref);
	
	QueryTexts.Add(QueryTextRemnantsOfGoodsForRegistration("GoodsForRegistration"));
	
	// 2. We get duplicates of rows in the temporary table obtained in paragraph 1.
	
	QueryText =
	"SELECT
	|	COUNT(*)                    AS DuplicateCount,
	|	GoodsForRegistration.Products   AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.Series          AS Series,
	|	GoodsForRegistration.Warehouse          AS Warehouse
	|INTO DuplicatesOfProductsForRegistration
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic,
	|	GoodsForRegistration.Series,
	|	GoodsForRegistration.Warehouse";
	
	QueryTexts.Add(QueryText);
	
	// 3. We connect the tables received in paragraphs 1 and 2, and also add data from the tables
	// of the order documents.
	
	QueryText =
	"SELECT
	|	GoodsForRegistration.ReferenceOrder          AS SalesOrder,
	|	GoodsForRegistration.RowCode             AS RowCode,
	|	GoodsForRegistration.Products          AS Products,
	|	GoodsForRegistration.Characteristic        AS Characteristic,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			AND CustomerOrderGoods.WithAssignment
	|			THEN CustomerOrderGoods.Ref.Purpose
	|		WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|			AND RequestForReturnOfGoods_.WithAssignment
	|			THEN RequestForReturnOfGoods_.Ref.Purpose
	|		WHEN ShipmentOfItemsToCustomer.Ref IS NOT NULL
	|			THEN ShipmentOfItemsToCustomer.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                   AS Purpose,
	|	GoodsForRegistration.Series                 AS Series,
	|	GoodsForRegistration.ForRegistrationQuantity AS ToRegister,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|				AND CustomerOrderGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsForRegistration.AmountToBeProcessed / GoodsForRegistration.ForRegistrationQuantity
	|		WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|				AND RequestForReturnOfGoods_.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsForRegistration.AmountToBeProcessed / GoodsForRegistration.ForRegistrationQuantity
	|		WHEN ShipmentOfItemsToCustomer.Ref IS NOT NULL
	|				AND ShipmentOfItemsToCustomer.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsForRegistration.AmountToBeProcessed / GoodsForRegistration.ForRegistrationQuantity
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN GoodsForRegistration.AmountToBeProcessed * &QueryTextPackingFactorOrders / GoodsForRegistration.ForRegistrationQuantity
	|		WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|			THEN GoodsForRegistration.AmountToBeProcessed * &QueryTextReturnRequestPackingFactor / GoodsForRegistration.ForRegistrationQuantity
	|		WHEN ShipmentOfItemsToCustomer.Ref IS NOT NULL
	|			THEN GoodsForRegistration.AmountToBeProcessed * &QueryTextShipmentPackingFactorToCustomer / GoodsForRegistration.ForRegistrationQuantity
	|		ELSE 0
	|	END                                   AS Price,
	|	GoodsForRegistration.Warehouse                 AS Warehouse,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN CustomerOrderGoods.DeliveryPeriodDays
	|		WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|			THEN RequestForReturnOfGoods_.DeliveryPeriodDays
	|		WHEN ShipmentOfItemsToCustomer.Ref IS NOT NULL
	|			THEN ShipmentOfItemsToCustomer.DeliveryPeriodDays
	|	END                                   AS DeliveryPeriodDays,
	|	0                                       AS Allocated,
	|	DuplicatesOfProducts.DuplicateCount           AS DuplicateCount
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|	
	|		LEFT JOIN DuplicatesOfProductsForRegistration AS DuplicatesOfProducts
	|		ON GoodsForRegistration.Products = DuplicatesOfProducts.Products
	|			AND GoodsForRegistration.Characteristic = DuplicatesOfProducts.Characteristic
	|			AND GoodsForRegistration.Warehouse = DuplicatesOfProducts.Warehouse
	|			AND GoodsForRegistration.Series = DuplicatesOfProducts.Series
	|	
	|		LEFT JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
	|		ON CustomerOrderGoods.Ref = GoodsForRegistration.ReferenceOrder
	|			AND CustomerOrderGoods.Products = GoodsForRegistration.Products
	|			AND CustomerOrderGoods.Characteristic = GoodsForRegistration.Characteristic
	|			AND CustomerOrderGoods.RowCode = GoodsForRegistration.RowCode
	|			AND CustomerOrderGoods.Warehouse = GoodsForRegistration.Warehouse
	|			AND CustomerOrderGoods.Series = GoodsForRegistration.Series
	|
	|		LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomer
	|		ON ShipmentOfItemsToCustomer.Ref = GoodsForRegistration.ReferenceOrder
	|			AND ShipmentOfItemsToCustomer.Products = GoodsForRegistration.Products
	|			AND ShipmentOfItemsToCustomer.Characteristic = GoodsForRegistration.Characteristic
	|			AND ShipmentOfItemsToCustomer.RowCode = GoodsForRegistration.RowCode
	|			AND ShipmentOfItemsToCustomer.Warehouse = GoodsForRegistration.Warehouse
	|			AND ShipmentOfItemsToCustomer.Series = GoodsForRegistration.Series
	|
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
	|		ON RequestForReturnOfGoods_.Ref = GoodsForRegistration.ReferenceOrder
	|			AND RequestForReturnOfGoods_.RowCode = GoodsForRegistration.RowCode
	|			AND RequestForReturnOfGoods_.Products = GoodsForRegistration.Products
	|			AND RequestForReturnOfGoods_.Characteristic = GoodsForRegistration.Characteristic
	|			AND RequestForReturnOfGoods_.Warehouse = GoodsForRegistration.Warehouse
	|			AND RequestForReturnOfGoods_.Series = GoodsForRegistration.Series
	|
	|ORDER BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic,
	|	GoodsForRegistration.Warehouse,
	|	GoodsForRegistration.Series,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			AND CustomerOrderGoods.WithAssignment
	|			THEN CustomerOrderGoods.Ref.Purpose
	|		WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|			AND RequestForReturnOfGoods_.WithAssignment
	|			THEN RequestForReturnOfGoods_.Ref.Purpose
	|		WHEN ShipmentOfItemsToCustomer.Ref IS NOT NULL
	|			THEN ShipmentOfItemsToCustomer.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN CustomerOrderGoods.DateOfShipment
	|		WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|			THEN RequestForReturnOfGoods_.DateOfShipment
	|		WHEN ShipmentOfItemsToCustomer.Ref IS NOT NULL
	|			THEN ShipmentOfItemsToCustomer.Ref.Date
	|	END,
	|	GoodsForRegistration.ReferenceOrder,
	|	GoodsForRegistration.RowCode
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackingFactorOrders",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CustomerOrderGoods.Package",
			"CustomerOrderGoods.Products"));
	
	QueryText = StrReplace(QueryText, "&QueryTextReturnRequestPackingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"RequestForReturnOfGoods_.Package",
			"RequestForReturnOfGoods_.Products"));
	
	QueryText = StrReplace(QueryText, "&QueryTextShipmentPackingFactorToCustomer",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ShipmentOfItemsToCustomer.Package",
			"ShipmentOfItemsToCustomer.Products"));
	
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Recorder", Object.Ref);
	Query.SetParameter("References", References);
	Query.SetParameter("ProductTypeGoodsItem", Enums.ItemsTypes.OwnGoods);
	Query.SetParameter("Warehouse", Object.Warehouse);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("SalesOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	TableOfUnallocatedGoods.Columns.Add("Series");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("Price");
	TableOfUnallocatedGoods.Columns.Add("Warehouse");
	TableOfUnallocatedGoods.Columns.Add("DeliveryPeriodDays");
	
	NamesOfPropertiesToFillIn = "SalesOrder, RowCode, Purpose, DeliveryPeriodDays";
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("RowCode",      0);
		TheStructureOfTheSearch.Insert("Products",   Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Series",          Selection.Series);
		TheStructureOfTheSearch.Insert("Price",           Selection.Price);
		TheStructureOfTheSearch.Insert("Warehouse",          Selection.Warehouse);
		
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ToRegister;
		
		// If there are no duplicates, we distribute the line of the order along the lines of the invoice
		If Selection.DuplicateCount < 2 Then
			
			For Each CurRow In FoundRows Do
				
				FillPropertyValues(CurRow, Selection, NamesOfPropertiesToFillIn);
				
				RetainedQuantity = RetainedQuantity - CurRow.Count;
				
				If RetainedQuantity <= 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		// If there are duplicates, we distribute the lines of orders according to the lines of the invoice, taking into account the quantity
		Else
			
			// On the first pass we will fill in only if the quantity in the line of the order and the invoice match
			MatchingStringFound = False;
			
			For Each CurRow In FoundRows Do
				
				If CurRow.Count = Selection.ToRegister Then
					
					MatchingStringFound = True;
					
					FillPropertyValues(CurRow, Selection, NamesOfPropertiesToFillIn);
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not MatchingStringFound Then
				NewRow = TableOfUnallocatedGoods.Add();
				FillPropertyValues(NewRow, Selection);
				
				NewRow.Count = RetainedQuantity;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		StructureOfActions.Insert("RecalculateAmount");
		
		RowsToProcess = New Array();
		
		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("SalesOrder",   Undefined);
			TheStructureOfTheSearch.Insert("RowCode",      0);
			TheStructureOfTheSearch.Insert("Products",   UnallocatedRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic", UnallocatedRow.Characteristic);
			TheStructureOfTheSearch.Insert("Series",          UnallocatedRow.Series);
			TheStructureOfTheSearch.Insert("Price",           UnallocatedRow.Price);
			TheStructureOfTheSearch.Insert("Warehouse",          UnallocatedRow.Warehouse);
			
			ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
			
			For Each LineProducts_ In ProductLines_3 Do
				
				If LineProducts_.Count = UnallocatedRow.Count Then
					
					FillPropertyValues(LineProducts_, UnallocatedRow, NamesOfPropertiesToFillIn);
					
					UnallocatedRow.Count = 0;
					
				ElsIf LineProducts_.Count > UnallocatedRow.Count Then
					
					Difference = LineProducts_.Count - UnallocatedRow.Count;
					
					NewLineProducts = Object.Goods.Add();
					FillPropertyValues(NewLineProducts, LineProducts_);
					
					NewLineProducts.Count = Difference;
					
					ProductLines_3.Add(NewLineProducts);
					
					FillPropertyValues(LineProducts_, UnallocatedRow, NamesOfPropertiesToFillIn + ",Count");
					
					UnallocatedRow.Count = 0;
					
					RowsToProcess.Add(LineProducts_);
					RowsToProcess.Add(NewLineProducts);
					
				ElsIf LineProducts_.Count < UnallocatedRow.Count Then
					
					Difference = UnallocatedRow.Count - LineProducts_.Count;
					
					FillPropertyValues(LineProducts_, UnallocatedRow, NamesOfPropertiesToFillIn);
					
					UnallocatedRow.Count = Difference;
					
				EndIf;
				
				If UnallocatedRow.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
#EndIf
