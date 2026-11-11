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
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("AcceptanceForProcessing");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	BackflushProductionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.BackflushProduction") Then
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
		
		QueryTextTableProductsRelease(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers);
		
		
		QueryTextTableRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		
		BackflushProductionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization, Department");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, Department";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "GroupCosts", Parameters);
	
EndProcedure

#Region StandardCommandSubsystems

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
	
	ProductionServer.AddCommandCreateProductReleaseWithoutOrderBasedOn(GenerationCommands);
	Documents.InternalAcceptanceCertificate.AddGenerateCommand(GenerationCommands);
	Documents.WorkOutput.AddCreateCommandBasedOnCreatingNewEmployees(GenerationCommands);
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	BackflushProductionLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create a "document Production order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.BackflushProduction) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.BackflushProduction.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Sản xuất không theo đơn đặt hàng';
												|ru = 'Производство без заказа';
												|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
												|it = 'Produzione senza ordine';
												|pl = 'Produkcja bez zamówień';
												|tr = 'Geriye dönük üretim'");
		CreateBasedOnCommand.Handler = "ProductionClient.ToArrangeProductionWithoutOrderOnBasisOf";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		CreateBasedOnCommand.MultipleChoice = False;
		
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
	
	Reports.ProductsCostTree.AddReportCommand(ReportsCommands);
	
	BackflushProductionLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// StandardSubsystems.Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	#Region PrintOutput

	If AccessRight("Read", Metadata.Documents.BackflushProduction) Then
		
		// Production output
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Invoice";
		PrintCommand.Presentation = NStr("vi = 'Xuất xưởng thành phẩm';
										|ru = 'Выпуск продукции';
										|en = 'Product release'; fa = 'تولید محصول';
										|it = 'Emissione di prodotti';
										|pl = 'Wyprodukowanie';
										|tr = 'Ürün sürümü'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;

#EndRegion

#Region PrintingTransferMaterials

	If AccessRight("Read", Metadata.Documents.BackflushProduction) Then
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "MaterialTransferToProduction";
		PrintCommand.Presentation = NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
										|ru = 'Передача материалов в производство';
										|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
										|it = 'Consegna materiali in produzione';
										|pl = 'Przekazanie materiałów do produkcji';
										|tr = 'Malzemelerin üretime aktarımı'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
#EndRegion

	#Region PrintTaskForSelectionPlacementOfGoods
	
	// Task for the selection of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(
		PrintCommands,
		"SelectionTask");
	
	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(
		PrintCommands,
		"PlacementJob");
	
	#EndRegion

	BackflushProductionLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "Department, Date";
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
//	Parameters:
//			Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//	Returns:
//			Structure - The structure of the parameters for specifying the series for the object.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	#Region ManufacturedProducts
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName	= "Document.BackflushProduction";
	ParametersForSpecifyingTSSeries.WarehouseFieldName		= "Recipient";
	ParametersForSpecifyingTSSeries.NameTSGoods		= "ManufacturedProducts";
	ParametersForSpecifyingTSSeries.TSSeriesName			= "BatchFinishedProducts";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches	=
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	ParametersForSpecifyingTSSeries.UseItemsBatch	=
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Recipient");
	ParametersForSpecifyingTSSeries.LinkFields.Add("CostGroupNumber");
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ManufactureOfProducts);
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	ParametersForSpecifyingTSSeries.ShipmentPlanning = False;
	ParametersForSpecifyingTSSeries.SelectionPlanning   = False;
	ParametersForSpecifyingTSSeries.FactOfSelection           = True;
	
	ParametersForSpecifyingTSSeries.RegisterSeries = True;
	
	ParametersForSpecifyingTSSeries.Date = Object.Date;
	
	SeriesSpecificationParameters.Insert("ManufacturedProducts", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName	= "Document.BackflushProduction";
	ParametersForSpecifyingTSSeries.WarehouseFieldName		= "Recipient";
	ParametersForSpecifyingTSSeries.NameTSGoods		= "SideAndIntermediateRelease";
	ParametersForSpecifyingTSSeries.TSSeriesName			= "BatchSideAndIntermediateRelease";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches	=
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	ParametersForSpecifyingTSSeries.UseItemsBatch	=
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.LinkFields.Add("Recipient");
	ParametersForSpecifyingTSSeries.LinkFields.Add("CostGroupNumber");
	ParametersForSpecifyingTSSeries.LinkFields.Add("ProductOwner");
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ManufactureOfProducts);
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	ParametersForSpecifyingTSSeries.ShipmentPlanning = False;
	ParametersForSpecifyingTSSeries.SelectionPlanning   = False;
	ParametersForSpecifyingTSSeries.FactOfSelection           = True;
	
	ParametersForSpecifyingTSSeries.RegisterSeries = True;
	
	ParametersForSpecifyingTSSeries.Date = Object.Date;
	
	SeriesSpecificationParameters.Insert("SideAndIntermediateRelease", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region MaterialsAndWorks
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName	= "Document.BackflushProduction";
	ParametersForSpecifyingTSSeries.WarehouseFieldName		= "Warehouse";
	ParametersForSpecifyingTSSeries.NameTSGoods		= "MaterialsAndWorks";
	ParametersForSpecifyingTSSeries.TSSeriesName			= "MaterialsAndWorks";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches	=
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	ParametersForSpecifyingTSSeries.UseItemsBatch	=
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Warehouse");
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ConsumptionDuringProduction);
	
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.ShipmentPlanning = False;
	ParametersForSpecifyingTSSeries.SelectionPlanning   = False;
	ParametersForSpecifyingTSSeries.FactOfSelection           = True;
	
	ParametersForSpecifyingTSSeries.RegisterSeries =
		ProductsClientServer.ItIsNecessaryToRegisterSeries(ParametersForSpecifyingTSSeries);
	
	ParametersForSpecifyingTSSeries.Date = Object.Date;
	
	SeriesSpecificationParameters.Insert("MaterialsAndWorks", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//	Parameters:
//		SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = "";
	
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProducts"
		Or SeriesSpecificationParameters.NameTSGoods = "SideAndIntermediateRelease" Then
		QueryText = TextOfRequestToFillInStatusesForSpecifyingSerialNumberOfProduct();
	ElsIf SeriesSpecificationParameters.NameTSGoods = "MaterialsAndWorks"
		Or SeriesSpecificationParameters.NameTSGoods = "SelectedLabeledProducts"
		Or SeriesSpecificationParameters.NameTSGoods = "Goods" Then
		QueryText = RequestTextForFillingInStatusesSpecifyingSeriesMaterialsAndWorks();
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region FillType

// Generates a list of documents based on the passed parameters.
//	Parameters:
//		Parameters - Structure - the parameters for the generation of documents.
//			It has the structure {Productspecifications, data Folders, cost Grouping}. all keys are required.
//			Product specifications - a table of values containing a list of manufactured products distributed according to the rules.
//			Data folders-Structure - data for filling in the document header.
//			Cost grouping - type of cost grouping.
//		ListOfObjects - Structure - list of generated documents.
//
Procedure DocumentsOnParameters(Parameters, ListOfObjects) Export
	
	ProductTable = GetFromTempStorage(Parameters.ProductsAccordingToSpecification);
	
	FillInCostGroupsInCollection(ProductTable);
	
	TempTablesManager = New TempTablesManager;
	SpecificationDataForByManufacturedProductsList(ProductTable, Parameters, TempTablesManager);
	
	GenerateDocuments(Parameters, TempTablesManager, ListOfObjects);
	
EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	// Template for output products
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.ManufacturedProducts.Purpose");
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.LineOfBusiness      = "Object.LineOfBusiness";
	
	// The needs for manufactured products in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate,
																	"OrderFulfillment",
																	True,
																	"Object.ManufacturedProducts.Purpose",
																	"OutputProductsNeed");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ =
		"Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.ManufacturedProducts.Recipient";
	
	// The needs for issued works in the recipient division.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate,
																	"FulfillOrdersWithWorks",
																	True,
																	"Object.ManufacturedProducts.Purpose",
																	"OutputProductsNeedForWork");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ =
		"Object.ManufacturedProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Department";
	
	// Template for by-products
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SideAndIntermediateRelease.Purpose");
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.LineOfBusiness      = "Object.LineOfBusiness";
	
	// Needs for by-products in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate,
																	"OrderFulfillment",
																	True,
																	"Object.SideAndIntermediateRelease.Purpose",
																	"ByProductsNeed");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ =
		"Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.SideAndIntermediateRelease.Recipient";
	
	// The needs for side work in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate,
																	"FulfillOrdersWithWorks",
																	True,
																	"Object.SideAndIntermediateRelease.Purpose",
																	"ByProductsNeedForWork");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ =
		"Object.SideAndIntermediateRelease.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Department";
	
	// Template for materials
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.MaterialsAndWorks.Purpose");
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.DeliveryForPrincipal));
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.LineOfBusiness      = "Object.LineOfBusiness";
	
	// Remnants of materials in the pantry.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate,
																	"OrderFulfillment",
																	True,
																	"Object.MaterialsAndWorks.Purpose",
																	"MaterialsAndWorksInStock");
	
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.TermsOfUse_ =
		"Object.MaterialsAndWorks.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.MaterialsAndWorks.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.MaterialsAndWorks.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.MaterialsAndWorks.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.ManufacturedProducts.Products";
	ChoiceParameterLinks.Characteristic          = "Object.ManufacturedProducts.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.Date";
	ChoiceParameterLinks.LineOfBusiness = "Object.ManufacturedProducts.LineOfBusiness";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProducts.BillOfMaterials", ChoiceParameterLinks);
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of cost allocation.
//
// Returns:
//  Structure - parameters specifying the specifics of the distribution of costs for output products.
//
Function CostAllocationParameters(Object) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts("ManufacturedProducts", Object.MethodOfAllocatingFinishedProductCosts);
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments
		Or Object.Patch
			And Object.CorrectionSavesProductionLots Then
		
		CostAllocationParameters.CalculateShareCostPercentageField = True;
		CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
		CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
		CostAllocationParameters.SetShareOfCostIsRequiredByDefault = True;
		CostAllocationParameters.ParametersForFillingInCostShares.Date = 
									?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Date"), 
									Object.Date,
									Date("00010101"));
		CostAllocationParameters.ParametersForFillingInCostShares.Currency = 
									?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Currency"), 
									Object.Currency, 
									Catalogs.Currencies.EmptyRef());
		
		If Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument
			And Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
			
			CostAllocationParameters.CostGroupingField = "CostGroupNumber";
			CostAllocationParameters.CostGroupingPresentationField = "ExpenseGroup";
			
		EndIf;
		
	EndIf;
	
	Return CostAllocationParameters;
	
EndFunction

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	FillParameters.Insert("FormIsOpen",          False);
	FillParameters.Insert("ObjectForm",          Undefined);
	FillParameters.Insert("FillByWarehouseDocument",     Undefined);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	FillParameters.Insert("Organization",           Catalogs.Companies.EmptyRef());
	FillParameters.Insert("Department",         Catalogs.BusinessStructure.EmptyRef());
	FillParameters.Insert("Warehouse",                 Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("FilterByWarehouse",         False);
	
	FillParameters.Insert("DocumentName",          "BackflushProduction");
	FillParameters.Insert("FieldNameOrder",          "BackflushProduction");
	
	FillParameters.Insert("KeyFields",          "Products, Characteristic, Series, Purpose");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.HeaderAttributes	= HeaderAttributes;
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	
	FillParameters.Organization				= HeaderAttributes.Organization;
	FillParameters.Department			= HeaderAttributes.Department;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		FillParameters.FillByWarehouseDocument = InvoicesServer.FillByWarehouseDocument(FillParameters.Warehouse);
	EndIf;
	
EndProcedure

// Fills in the passed parameter table for orders and warehouse orders
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.ReceiptOfGoodsFromCustodian - Link to the current invoice
//  FillParameters	 - Structure - The default settings defined in the method of Parametrization()
//  PackageBarcodes	 - ValueTable, Undefined - Table of barcodes of packages for returning stamp data
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	Query = New Query(AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue());
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder", Recorder);
	
	TableOrders = Query.Execute().Unload();
	
	// Adding the number of orders.
	ColumnVT = TableOrders.Columns.Count; // ValueTableColumn - 
	ColumnVT.Name = "NoteQuantity";
	InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity",
		"Products, Characteristic, Purpose", "On [Count]", True, "Series");
	InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");

	InvoicesServer.DeleteEmptyLines(Goods, "Count");
	
	BackflushProductionLocalization.FillInBarcodesOfPackages(FillParameters.AnArrayOfOrders, Goods, PackageBarcodes);
	
EndProcedure

#EndRegion

#Region GroupCosts

// Returns a list of fields that identify the cost group.
//	Parameters:
//		GroupCosts - EnumRef.GroupingsOfCostsInBackflushProduction - type of cost grouping.
//	Returns:
//		ValueList - a list of fields identifying the cost group.
//
Function ListOfCostGroupFields(GroupCosts) Export
	
	FieldList = New ValueList;
	LanguageCode = Common.DefaultLanguageCode();
	
	If GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProducts Then
		FieldList.Add("Products",       NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Produkt';
											|tr = 'Öğe'", LanguageCode));
		FieldList.Add("Characteristic",     NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'", LanguageCode));
		FieldList.Add("Series",              NStr("vi = 'Sê-ri';
													|ru = 'Серия';
													|en = 'Batch'; fa = 'بچ';
													|it = 'Serie';
													|pl = 'Seria';
													|tr = 'Parti'", LanguageCode));
	ElsIf GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments Then
		FieldList.Add("Products",       NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Produkt';
											|tr = 'Öğe'", LanguageCode));
		FieldList.Add("Characteristic",     NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'", LanguageCode));
		FieldList.Add("Purpose",         NStr("vi = 'Chỉ định';
												|ru = 'Назначение';
												|en = 'Assignment'; fa = 'تخصیص';
												|it = 'Destinazione';
												|pl = 'Przeznaczenie';
												|tr = 'Atama'", LanguageCode));
		FieldList.Add("Series",              NStr("vi = 'Sê-ri';
													|ru = 'Серия';
													|en = 'Batch'; fa = 'بچ';
													|it = 'Serie';
													|pl = 'Seria';
													|tr = 'Parti'", LanguageCode));
	ElsIf GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches Then
		FieldList.Add("Products",       NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Produkt';
											|tr = 'Öğe'", LanguageCode));
		FieldList.Add("Characteristic",     NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'", LanguageCode));
	ElsIf GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches Then
		FieldList.Add("Products",       NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Produkt';
											|tr = 'Öğe'", LanguageCode));
		FieldList.Add("Characteristic",     NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'", LanguageCode));
		FieldList.Add("Purpose",         NStr("vi = 'Chỉ định';
												|ru = 'Назначение';
												|en = 'Assignment'; fa = 'تخصیص';
												|it = 'Destinazione';
												|pl = 'Przeznaczenie';
												|tr = 'Atama'", LanguageCode));
	ElsIf GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM Then
		FieldList.Add("BillOfMaterials",       NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
													|ru = 'Спецификация';
													|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
													|it = 'Specifica';
													|pl = 'Specyfikacja';
													|tr = 'Ürün reçetesi'", LanguageCode));
	ElsIf GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments Then
		FieldList.Add("BillOfMaterials",       NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
													|ru = 'Спецификация';
													|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
													|it = 'Specifica';
													|pl = 'Specyfikacja';
													|tr = 'Ürün reçetesi'", LanguageCode));
		FieldList.Add("Purpose",         NStr("vi = 'Chỉ định';
												|ru = 'Назначение';
												|en = 'Assignment'; fa = 'تخصیص';
												|it = 'Destinazione';
												|pl = 'Przeznaczenie';
												|tr = 'Atama'", LanguageCode));
	EndIf;
	If GetFunctionalOption("UseInternalSubcontracting") Then
		FieldList.Add("InternalSubcontracting", "");
		FieldList.Add("MaterialProviderCompany",    NStr("vi = 'Gia công cho';
														|ru = 'Переработка для';
														|en = 'Subcontracting for'; fa = 'پیمانکاری فرعی برای';
														|it = 'Переработка для';
														|pl = 'Subcontracting for';
														|tr = 'Fason müşterisi'", LanguageCode));
	EndIf;
	Return FieldList;
	
EndFunction

// Returns a string containing a list of ways to get fields that identify the cost group.
//	Parameters:
//		TableName - String - name of the source for getting fields that identify the cost group.
//		FieldList - ValueList - a list of fields identifying the cost group.
//	Returns:
//		String - a string containing a list of ways to obtain fields identifying the cost group.
//
Function RequestTextByCostGroupFields(TableName, FieldList) Export
	
	RequestTextByField = "";
	
	For Each CurField In FieldList Do
		
		RequestTextByField = RequestTextByField + ", " + TableName + "." + CurField.Value;
		
	EndDo;
	
	Return RequestTextByField;
	
EndFunction

// Returns a structure containing a list of fields that identify the cost group.
//	Parameters:
//		FieldList - ValueList - a list of fields identifying the cost group.
//	Returns:
//		Structure - a structure containing a list of fields identifying the cost group.
//
Function CostGroupSearchStructure(FieldList) Export
	
	TheStructureOfTheSearch = New Structure;
	
	For Each CurField In FieldList Do
		TheStructureOfTheSearch.Insert(CurField.Value);
	EndDo;
	
	Return TheStructureOfTheSearch;
	
EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionOptions = New Array;
	
	// Output items
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath					= "Object.ManufacturedProducts";
	ChoiceParameters.AssetRef						= "Recipient";
	ChoiceParameters.ArticleType					= "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem			= True;
	ChoiceParameters.DimensionOfExpenses			= "DimensionOfExpenses";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	FormItems = ChoiceParameters.FormItems;
	FormItems.AssetRef.Add("ManufacturedProductsRecipient");
	FormItems.DimensionOfExpenses.Add("ManufacturedProductsDimensionOfExpenses");
	FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductsAssetsLiabilitiesDimension");
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	// By-products
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath					= "Object.SideAndIntermediateRelease";
	ChoiceParameters.AssetRef						= "Recipient";
	ChoiceParameters.ArticleType					= "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem			= True;
	ChoiceParameters.DimensionOfExpenses			= "DimensionOfExpenses";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	FormItems = ChoiceParameters.FormItems;
	FormItems.AssetRef.Add("SideAndIntermediateReleaseRecipient");
	FormItems.DimensionOfExpenses.Add("SideAndIntermediateReleaseDimensionOfExpenses");
	FormItems.AssetsLiabilitiesDimension.Add("SideAndIntermediateReleaseAssetsLiabilitiesDimension");
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionOptions;
	
EndFunction

#EndRegion

#Region GLAccountSettings

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//  See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SettingsParameters = New Array;
	
	// Output items
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.ArticleType				= "ArticleType";
	SetupParameters.DataPath				= "Object.ManufacturedProducts";
	SetupParameters.AssetAndLiabilityItem	= "Recipient";
	
	SetupParameters.FormItems.Add("ManufacturedProductsTransactionRecordingPresentation");
	
	SetupParameters.HideUnavailableInvoiceInRows = True;
	SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines.Insert(
		"DirectionOfProductionIssue",
		Enums.BusinessTransactions.GoodsConsumptionOnDemand);
	
	SettingsParameters.Add(SetupParameters);
	
	// By-products
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.ArticleType				= "ArticleType";
	SetupParameters.DataPath				= "Object.SideAndIntermediateRelease";
	SetupParameters.AssetAndLiabilityItem	= "Recipient";
	
	SetupParameters.FormItems.Add("SideAndIntermediateReleaseTransactionRecordingPresentation");
	
	SetupParameters.HideUnavailableInvoiceInRows = True;
	SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines.Insert(
		"DirectionOfProductionIssue",
		Enums.BusinessTransactions.GoodsConsumptionOnDemand);
	
	SettingsParameters.Add(SetupParameters);
	
	Return SettingsParameters;
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.BackflushProduction, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization							= Object.Organization;
	FillParameters.Date								= Object.Date;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.OutputOfProductsAndWorks				= True;
	
	Return FillParameters;
	
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

#Region Rounding

// Returns the parameters for rounding
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForCheckingFillingQuantity
// 
Function TSParametersForRounding() Export
	
	TSParameters = New Structure;
	
	TSName = "ManufacturedProducts";
	WarehouseFieldName = "Recipient";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);

	TSName = "SideAndIntermediateRelease";
	WarehouseFieldName = "Recipient";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
	
	TSName = "MaterialsAndWorks";
	WarehouseFieldName = "Warehouse";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
		
	Return TSParameters;	

EndFunction

#EndRegion

#Region PrintJobsForInventoryPickingPlacementAndRecount

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array of See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Array;
	
	// Materials and works
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.VHFWarehouses = True;
	JobPrintingRules.NameTSGoods = "MaterialsAndWorks";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	// Output items
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation = True;
	JobPrintingRules.VHFWarehouses = True;
	JobPrintingRules.NameTSGoods = "ManufacturedProducts";
	JobPrintingRules.WarehouseFieldName = "Recipient";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	// By-products
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation = True;
	JobPrintingRules.VHFWarehouses = True;
	JobPrintingRules.NameTSGoods = "SideAndIntermediateRelease";
	JobPrintingRules.WarehouseFieldName = "Recipient";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion

#Region Other

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Sản xuất không theo đơn đặt hàng';
		|ru = 'Производство без заказа';
		|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
		|it = 'Produzione senza ordine';
		|pl = 'Produkcja bez zamówień';
		|tr = 'Geriye dönük üretim'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* ManufacturedProducts - ValueTable, TabularSection, Undefined - data about the output items of the document.
//		* SideAndIntermediateRelease - ValueTable, TabularSection, Undefined - data on the by-products of the document.
//		* MaterialsAndWorks - ValueTable, TabularSection, Undefined - data about the materials of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure;
	DocumentTables.Insert("ManufacturedProducts");
	DocumentTables.Insert("SideAndIntermediateRelease");
	DocumentTables.Insert("MaterialsAndWorks");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region FillType

// Generates a list of cost groups and populates the field "Homegraffitinet" in the passed collection.
//	Parameters:
//		Collection - ValueTable - a collection where you need to fill in the cost group numbers.
//
Procedure FillInCostGroupsInCollection(Collection)
	
	For Each CurRow In Collection Do
		If ValueIsFilled(CurRow.Purpose) Then
			If CurRow.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM Then
				CurRow.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments;
			ElsIf CurRow.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProducts Then
				CurRow.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments;
			ElsIf CurRow.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches Then
				CurRow.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches;
			EndIf;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductTable.Organization,
	|	ProductTable.GroupCosts,
	|	ProductTable.Department,
	|	ProductTable.Products,
	|	ProductTable.Characteristic,
	|	ProductTable.Purpose,
	|	ProductTable.BillOfMaterials
	|INTO ProductTable
	|FROM
	|	&ProductTable AS ProductTable
	|WHERE
	|	NOT ProductTable.Count = 0
	|	AND NOT ProductTable.ErrorInModelSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductTable.Organization AS Organization,
	|	ProductTable.GroupCosts AS GroupCosts,
	|	ProductTable.Department AS Department,
	|	ProductTable.Products,
	|	ProductTable.Characteristic,
	|	ProductTable.Purpose,
	|	ProductTable.BillOfMaterials
	|FROM
	|	ProductTable AS ProductTable
	|
	|TOTALS BY
	|	Organization,
	|	Department,
	|	GroupCosts";
	
	Query.SetParameter("ProductTable", Collection);
	
	ResultTree_ = Query.Execute().Unload(QueryResultIteration.ByGroups);
	GroupIndex = 1;
	
	For Each CurOrganization In ResultTree_.Rows Do
		For Each CurDivision In CurOrganization.Rows Do
			For Each CurCostGrouping In CurDivision.Rows Do
				
				FieldList = ListOfCostGroupFields(CurCostGrouping.GroupCosts);
				RequiredDimensionFields = "Organization, Department, GroupCosts";
				GroupFields = "";
				
				For Each CurField In FieldList Do
					GroupFields = GroupFields + ", " + CurField.Value;
				EndDo;
				
				GroupFields = RequiredDimensionFields + GroupFields;
				
				TheStructureOfTheSearch = New Structure(RequiredDimensionFields);
				FillPropertyValues(TheStructureOfTheSearch, CurCostGrouping);
				
				CostGroups = Collection.Copy(TheStructureOfTheSearch);
				CostGroups.GroupBy(GroupFields);
				
				TheStructureOfTheSearch = New Structure(GroupFields);
				
				For Each CurGroup In CostGroups Do
					
					FillPropertyValues(TheStructureOfTheSearch, CurGroup);
					
					Rows = Collection.FindRows(TheStructureOfTheSearch);
					For Each CurRow In Rows Do
						CurRow.CostGroupNumber = GroupIndex;
					EndDo;
					
					GroupIndex = GroupIndex + 1;
					
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

// Generates temporary tables based on specification data for the transmitted product list.
//
Procedure SpecificationDataForByManufacturedProductsList(ProductTable, Parameters, TempTablesManager) Export
	
	ListOfData = Parameters.ListOfData;
	HeaderData_    = Parameters.HeaderData_;
	
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	// Grouping fields
	ItemList.Columns.Add("CostGroupNumber");
	ItemList.Columns.Add("Department");
	
	For Each CurRow In ProductTable Do
		
		If Not CurRow.RecordCostsByADocument Then
			Continue;
		EndIf;
		
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.ProductionStart = HeaderData_.Date;
		
	EndDo;
	
	ProductionData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		ItemList,
		Catalogs.BillsOfMaterials.DataSamplingParameters(),
		True,
		"CostGroupNumber,Department");
	
	If Not ListOfData.Find("RecyclableWaste") = Undefined Then
		EliminateReturnableWasteFromOutputProducts(ProductTable, ProductionData);
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	InitializeSpecificationDataTables(ProductTable, TempTablesManager);
	
	If Not ListOfData.Find("RecyclableWaste") = Undefined Then
		Query.Text = Query.Text + QueryTextRecyclableWaste();
	EndIf;
	
	If Not ListOfData.Find("MaterialsAndServices") = Undefined Then
		Query.Text = Query.Text + QueryTextUsedMaterials();
	EndIf;
	
	If Not ListOfData.Find("LaborCosts") = Undefined Then
		Query.Text = Query.Text + QueryTextLaborCosts();
	EndIf;
	
	IndexOf = 0;
	GetCostData = Not ListOfData.Find("RecyclableWaste") = Undefined
							Or Not ListOfData.Find("MaterialsAndServices") = Undefined
							Or Not ListOfData.Find("LaborCosts") = Undefined;
	
	For Each CurRow In ProductionData Do
		
		If CurRow = Undefined Then
			Continue;
		EndIf;
		
		Query.SetParameter("CostGroupNumber", CurRow.CostGroupNumber);
		Query.SetParameter("Department", CurRow.Department);
		
		If Not ListOfData.Find("RecyclableWaste") = Undefined Then
			Query.SetParameter("RecyclableWaste", CurRow.RecyclableWaste);
		EndIf;
		
		If Not ListOfData.Find("MaterialsAndServices") = Undefined Then
			Query.SetParameter("MaterialsAndServices", CurRow.MaterialsAndServices);
		EndIf;
		
		If Not ListOfData.Find("LaborCosts") = Undefined Then
			Query.SetParameter("LaborCosts", CurRow.LaborCosts);
		EndIf;
		
		If GetCostData Then
			Query.Execute();
		EndIf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	FillInAssignmentOfMaterialsForSeparateBalances(TempTablesManager, Parameters);
	
EndProcedure

// Fills in the assignment of materials based on leftovers
//
Procedure FillInAssignmentOfMaterialsForSeparateBalances(TempTablesManager, Parameters)
	
	If Parameters.ListOfData.Find("MaterialsAndServices") = Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
		"SELECT
		|	ProductTable.CostGroupNumber	AS CostGroupNumber,
		|	ProductTable.Organization		AS Organization,
		|	ProductTable.Purpose			AS Purpose,
		|	GiverAppointments.Ref			AS AppointmentOfGiver
		|INTO ProductAssignments_
		|FROM
		|	ProductTable AS ProductTable
		|	LEFT JOIN Catalog.Assignments AS CatAssignments
		|	ON CatAssignments.Ref = ProductTable.Purpose
		|	LEFT JOIN Catalog.Assignments AS GiverAppointments
		|	ON GiverAppointments.LineOfBusiness = CatAssignments.LineOfBusiness
		|		AND GiverAppointments.Partner = CatAssignments.Partner
		|		AND GiverAppointments.Contract = CatAssignments.Contract
		|		AND GiverAppointments.AssignmentType IN(
		|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|WHERE
		|	ProductTable.GroupCosts IN
		|		(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
		|		VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches),
		|		VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments))
		|	AND NOT ProductTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|
		|GROUP BY
		|	ProductTable.Organization,
		|	ProductTable.Purpose,
		|	ProductTable.CostGroupNumber,
		|	GiverAppointments.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MaterialsAndServices.CostGroupNumber	AS CostGroupNumber,
		|	DimensionKeys.DimensionKey		AS ItemsLocationAttributes,
		|	ProductAssignments_.Organization		AS Organization,
		|	ProductAssignments_.Purpose		AS Purpose
		|INTO DimensionLeftovers
		|FROM
		|	MaterialsAndServices AS MaterialsAndServices
		|		INNER JOIN ProductAssignments_ AS ProductAssignments_
		|		ON MaterialsAndServices.CostGroupNumber = ProductAssignments_.CostGroupNumber
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
		|		ON (DimensionKeys.Products = MaterialsAndServices.Products)
		|			AND (DimensionKeys.Characteristic = MaterialsAndServices.Characteristic)
		|			AND (DimensionKeys.StorageLocation = MaterialsAndServices.Warehouse)
		|			AND (DimensionKeys.Purpose = ProductAssignments_.Purpose)
		|			AND (DimensionKeys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef))
		|
		|GROUP BY
		|	ProductAssignments_.Purpose,
		|	ProductAssignments_.Organization,
		|	DimensionKeys.DimensionKey,
		|	MaterialsAndServices.CostGroupNumber
		|
		|UNION ALL
		|
		|SELECT
		|	MaterialsAndServices.CostGroupNumber		AS CostGroupNumber,
		|	DimensionKeys.DimensionKey			AS ItemsLocationAttributes,
		|	ProductAssignments_.Organization			AS Organization,
		|	ProductAssignments_.AppointmentOfGiver	AS Purpose
		|FROM
		|	MaterialsAndServices AS MaterialsAndServices
		|		INNER JOIN ProductAssignments_ AS ProductAssignments_
		|		ON MaterialsAndServices.CostGroupNumber = ProductAssignments_.CostGroupNumber
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
		|		ON (DimensionKeys.Products = MaterialsAndServices.Products)
		|			AND (DimensionKeys.Characteristic = MaterialsAndServices.Characteristic)
		|			AND (DimensionKeys.StorageLocation = MaterialsAndServices.Warehouse)
		|			AND (DimensionKeys.Purpose = ProductAssignments_.AppointmentOfGiver)
		|			AND (DimensionKeys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef))
		|WHERE
		|	NOT ProductAssignments_.AppointmentOfGiver = ProductAssignments_.Purpose
		|GROUP BY
		|	ProductAssignments_.AppointmentOfGiver,
		|	ProductAssignments_.Organization,
		|	DimensionKeys.DimensionKey,
		|	MaterialsAndServices.CostGroupNumber
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	ProductAssignments_.Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DimensionLeftovers.CostGroupNumber AS CostGroupNumber,
		|	CompanyGoodsBalance.ItemsLocationAttributes.Products AS Products,
		|	CompanyGoodsBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	CompanyGoodsBalance.ItemsLocationAttributes.StorageLocation AS Warehouse,
		|	DimensionLeftovers.Purpose AS Purpose,
		|	SUM(CompanyGoodsBalance.CountBalance) AS Count
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|			&Date,
		|			(ItemsLocationAttributes, Organization) IN
		|				(SELECT
		|					DimensionLeftovers.ItemsLocationAttributes,
		|					DimensionLeftovers.Organization
		|				FROM
		|					DimensionLeftovers AS DimensionLeftovers)) AS CompanyGoodsBalance
		|		LEFT JOIN DimensionLeftovers AS DimensionLeftovers
		|		ON (DimensionLeftovers.ItemsLocationAttributes = CompanyGoodsBalance.ItemsLocationAttributes)
		|			AND (DimensionLeftovers.Organization = CompanyGoodsBalance.Organization)
		|
		|GROUP BY
		|	CompanyGoodsBalance.ItemsLocationAttributes.Products,
		|	CompanyGoodsBalance.ItemsLocationAttributes.Characteristic,
		|	CompanyGoodsBalance.ItemsLocationAttributes.StorageLocation,
		|	DimensionLeftovers.Purpose,
		|	DimensionLeftovers.CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MaterialsAndServices.CostGroupNumber,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.Purpose,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	SUM(MaterialsAndServices.NumberOfPackages) AS NumberOfPackages,
		|	SUM(MaterialsAndServices.Count) AS Count
		|FROM
		|	MaterialsAndServices AS MaterialsAndServices
		|
		|GROUP BY
		|	MaterialsAndServices.Purpose,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MaterialsAndServices";
		
	Query.SetParameter("Date", Parameters.HeaderData_.Date);
	Result = Query.ExecuteBatch();
	
	IndexOf = Result.UBound();
	RemainingMaterials	= Result[IndexOf - 2].Select();
	MaterialsAndServices	= Result[IndexOf - 1].Unload();
	
	FilterFields = "CostGroupNumber, Products, Characteristic, Warehouse";
	MaterialsAndServices.Indexes.Add(FilterFields);
	FilterOfProducts_ = New Structure(FilterFields);
	
	While RemainingMaterials.Next() Do
		
		GoodsQuantity = RemainingMaterials.Count;
		
		FillPropertyValues(FilterOfProducts_, RemainingMaterials);
		
		For Each ContentLine In MaterialsAndServices.FindRows(FilterOfProducts_) Do
			
			If ContentLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, ContentLine.Count);
			
			NewRow = MaterialsAndServices.Add();
			FillPropertyValues(NewRow, ContentLine);
			
			NewRow.Purpose			= RemainingMaterials.Purpose;
			NewRow.Count			= Count;
			NewRow.NumberOfPackages	= Count
				/ Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(NewRow.Package, NewRow.Products);
			
			ContentLine.Count = ContentLine.Count - NewRow.Count;
			ContentLine.NumberOfPackages = ContentLine.NumberOfPackages - NewRow.NumberOfPackages;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = MaterialsAndServices.FindRows(New Structure("Count", 0));
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		MaterialsAndServices.Delete(TableRow);
	EndDo;
	
	Query.Text =
		"SELECT
		|	MaterialsAndServices.CostGroupNumber,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.Purpose,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.NumberOfPackages AS NumberOfPackages,
		|	MaterialsAndServices.Count AS Count
		|INTO MaterialsAndServices
		|FROM
		|	&MaterialsAndServices AS MaterialsAndServices";
	Query.SetParameter("MaterialsAndServices", MaterialsAndServices);
	Query.Execute();
	
EndProcedure

// Creates and fills in documents based on the passed parameters.
// 
// Parameters:
// 	Parameters - Structure - LongDesc
// 	TempTablesManager - TempTablesManager - LongDesc
// 	ListOfObjects - Array - LongDesc
Procedure GenerateDocuments(Parameters, TempTablesManager, ListOfObjects)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = RequestTextProductsByCostGroup()
					+ RequestTextReturnableWasteByCostGroup()
					+ RequestTextMaterialsByCostGroup()
					+ RequestTextLaborCostsByCostGroup();
	
	PricesKind = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	
	Query.SetParameter("Date", Parameters.HeaderData_.Date);
	Query.SetParameter("PriceKind", PricesKind);
	Query.SetParameter("AutoFill", Parameters.AutoFill);
	
	Result = Query.ExecuteBatch();
	IndexOf = Result.UBound();
	
	ManufacturedProduct			= Result[IndexOf - 4].Unload(QueryResultIteration.ByGroups);
	RecyclableWaste	= Result[IndexOf - 3].Unload();
	MaterialsAndWorks	= Result[IndexOf - 2].Unload();
	LaborCosts		= Result[IndexOf].Unload();
	
	TheStructureOfTheSearch = New Structure("CostGroupNumber");
	
	For Each CurOrganization In ManufacturedProduct.Rows Do
		For Each CurReleaseForActivity In CurOrganization.Rows Do
			For Each CurCostGrouping In CurReleaseForActivity.Rows Do
				For Each CurDivision In CurCostGrouping.Rows Do
					For Each CurMethodOfDistribution In CurDivision.Rows Do
						CurDocument = Documents.BackflushProduction.CreateDocument();
						CurDocument.GetNewObjectRef();
						CurDocument.PriceKind = PricesKind;
						
						ListOfObjects.Add(CurDocument);
						
						FillingData = New Structure("Organization, ProductionIssueForActivity");
						FillPropertyValues(FillingData, CurMethodOfDistribution);
						CurDocument.Fill(FillingData);
						
						FillPropertyValues(CurDocument, Parameters.HeaderData_);
						FillPropertyValues(CurDocument, CurMethodOfDistribution,, "ProductionIssueForActivity");
						
						ListOfCostGroups = New Array;
						
						For Each CurProduct In CurMethodOfDistribution.Rows Do
							NewRow = CurDocument.ManufacturedProducts.Add();
							FillPropertyValues(NewRow, CurProduct);
							ListOfCostGroups.Add(CurProduct.CostGroupNumber);
						EndDo;
						
						ListOfCostGroups = CommonClientServer.CollapseArray(ListOfCostGroups);
						
						For Each CurGroup In ListOfCostGroups Do
							
							TheStructureOfTheSearch.CostGroupNumber = CurGroup;
							
							For Each CurRow In RecyclableWaste.FindRows(TheStructureOfTheSearch) Do
								FillPropertyValues(CurDocument.SideAndIntermediateRelease.Add(), CurRow);
							EndDo;
							
							For Each CurRow In MaterialsAndWorks.FindRows(TheStructureOfTheSearch) Do
								FillPropertyValues(CurDocument.MaterialsAndWorks.Add(), CurRow);
							EndDo;
							
							For Each CurRow In LaborCosts.FindRows(TheStructureOfTheSearch) Do
								FillPropertyValues(CurDocument.LaborCosts.Add(), CurRow);
							EndDo;
							
						EndDo;
						
						SeriesSpecificationParameters =
							ProductsServer.SeriesSpecificationParameters(CurDocument, Documents.BackflushProduction);
						ProductsServer.FillInStatusesForSpecifyingSeries(CurDocument, SeriesSpecificationParameters.ManufacturedProducts);
						ProductsServer.FillInStatusesForSpecifyingSeries(CurDocument, SeriesSpecificationParameters.SideAndIntermediateRelease);
						ProductsServer.FillInStatusesForSpecifyingSeries(CurDocument, SeriesSpecificationParameters.MaterialsAndWorks);
						
						TransferSeriesSpecifiedSeparately(CurDocument, "ManufacturedProducts");
						TransferSeriesSpecifiedSeparately(CurDocument, "SideAndIntermediateRelease");
						
						CostAllocationParametersStructure =
							Documents.BackflushProduction.CostAllocationParameters(CurDocument);
						CostAllocationParameters =
							New FixedStructure(CostAllocationParametersStructure);
						
						ProductionServer.CalculateFractionOfCost(CurDocument, CostAllocationParameters);
						
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

// Puts the product table in W, creates empty W for costs
//
Procedure InitializeSpecificationDataTables(ProductTable, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	TextReturnableWaste =
		"SELECT TOP 0
		|	SideAndIntermediateRelease.CostGroupNumber AS CostGroupNumber,
		|	SideAndIntermediateRelease.Department AS Department,
		|	SideAndIntermediateRelease.DirectionOfProductionIssue AS DirectionOfProductionIssue,
		|	SideAndIntermediateRelease.Recipient AS Recipient,
		|	SideAndIntermediateRelease.Products AS Products,
		|	SideAndIntermediateRelease.Characteristic AS Characteristic,
		|	SideAndIntermediateRelease.Series AS Series,
		|	SideAndIntermediateRelease.Purpose AS Purpose,
		|	SideAndIntermediateRelease.ProductCostElement AS ProductCostElement,
		|	SideAndIntermediateRelease.Package AS Package,
		|	&PricingFields,
		|	SideAndIntermediateRelease.NumberOfPackages AS NumberOfPackages,
		|	SideAndIntermediateRelease.Count AS Count
		|INTO RecyclableWaste
		|FROM
		|	Document.BackflushProduction.SideAndIntermediateRelease AS SideAndIntermediateRelease
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = SideAndIntermediateRelease.Products.ProductKind
		|;
		|";
	
	PricingSettings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
	PricingSettings.SourceOfGoods = "SideAndIntermediateRelease";
	ReplacementText = PriceManagementSystemClientServer.TextOfFieldsForPricing(PricingSettings);
	If ValueIsFilled(ReplacementText) Then
		TextReturnableWaste = StrReplace(TextReturnableWaste, "&PricingFields", ReplacementText);
	Else
		TextReturnableWaste = StrReplace(TextReturnableWaste, "&PricingFields,", "");
	EndIf;
	
	TextMaterialsAndWorks =
		"SELECT TOP 0
		|	MaterialsAndWorks.CostGroupNumber AS CostGroupNumber,
		|	MaterialsAndWorks.Warehouse AS Warehouse,
		|	MaterialsAndWorks.Department AS Department,
		|	MaterialsAndWorks.Products AS Products,
		|	MaterialsAndWorks.Characteristic AS Characteristic,
		|	MaterialsAndWorks.Purpose AS Purpose,
		|	MaterialsAndWorks.ProductCostElement AS ProductCostElement,
		|	MaterialsAndWorks.Package AS Package,
		|	MaterialsAndWorks.NumberOfPackages AS NumberOfPackages,
		|	MaterialsAndWorks.Count AS Count
		|INTO MaterialsAndServices
		|FROM
		|	Document.BackflushProduction.MaterialsAndWorks AS MaterialsAndWorks
		|;
		|";
	
	TextLaborCosts =
		"SELECT TOP 0
		|	LaborCosts.CostGroupNumber AS CostGroupNumber,
		|	LaborCosts.Department AS Department,
		|	LaborCosts.WorkKind AS WorkKind,
		|	LaborCosts.ProductCostElement AS ProductCostElement,
		|	LaborCosts.Count AS Count
		|INTO LaborCosts
		|FROM
		|	Document.BackflushProduction.LaborCosts AS LaborCosts
		|;
		|";
	
	Query.Text = QueryTextManufacturedProduct()
					+ TextReturnableWaste
					+ TextMaterialsAndWorks
					+ TextLaborCosts;
	Query.SetParameter("ProductTable", ProductTable);
	Query.Execute();
	
EndProcedure

// Returns the query text for placing the product table in TUE.
//	Returns:
//		String - query text.
//
Function QueryTextManufacturedProduct()
	
	QueriesTexts = New Array();
	
	QueryText = "SELECT
		|	ProductTable.CostGroupNumber,
		|	ProductTable.Organization,
		|	ProductTable.GroupCosts,
		|	ProductTable.Department,
		|	ProductTable.DirectionOfProductionIssue,
		|	ProductTable.Recipient,
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.Series,
		|	ProductTable.Purpose,
		|	ProductTable.BillOfMaterials,
		|	ProductTable.Count
		|INTO #ProductTable
		|FROM
		|	&ProductTable AS ProductTable
		|WHERE
		|	NOT ProductTable.Count = 0
		|	AND NOT ProductTable.ErrorInModelSettings
		|;
		|";

	QueriesTexts.Add(QueryText);
	
	ProductTableName_ = "ProductTable";
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	If UsePriceManagementSystem25 Then

		ProductTableName_ = "ProductTablePreliminary";
		
		Settings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
		
		Settings.SourceOfGoods = ProductTableName_;
		Settings.ReceiverOfGoods = "ProductTable";
		Settings.ListOfOtherFields = "CostGroupNumber, Organization, GroupCosts, Department, 
		|DirectionOfProductionIssue, Recipient, Purpose, BillOfMaterials, Count";
		Settings.PackagingField = "";
		
		QueryText = PriceManagementSystemClientServer.TextOfTemporaryTableRequestWithAddendumForPricing(
												Settings,
												UsePriceManagementSystem25);
		QueriesTexts.Add(QueryText);
		QueriesTexts.Add(";");
		
	EndIf;
	
	QueryText = StrConcat(QueriesTexts);
	QueryText = StrReplace(QueryText, "#ProductTable", ProductTableName_);
		
	Return QueryText;
		
EndFunction

// Returns the text of a request to merge specification data with an existing TUE
// in the returnable waste part.
//	Returns:
//		String - query text.
//
Function QueryTextRecyclableWaste()
	QueryText = "SELECT
		|	&CostGroupNumber AS CostGroupNumber,
		|	RecyclableWaste.StageSubdivision AS Department,
		|	CASE
		|		WHEN RecyclableWaste.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
		|		ELSE VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	END AS DirectionOfProductionIssue,
		|	CASE
		|		WHEN RecyclableWaste.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &Department
		|		ELSE RecyclableWaste.Warehouse
		|	END AS Recipient,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Package,
		|	RecyclableWaste.NumberOfPackages AS NumberOfPackages,
		|	RecyclableWaste.Count AS Count
		|INTO ReturnableWasteSpecifications
		|FROM
		|	&RecyclableWaste AS RecyclableWaste
		|WHERE
		|	NOT RecyclableWaste.ProductCostElement = VALUE(Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RecyclableWaste.CostGroupNumber,
		|	RecyclableWaste.Department,
		|	RecyclableWaste.DirectionOfProductionIssue,
		|	RecyclableWaste.Recipient,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Package,
		|	RecyclableWaste.NumberOfPackages,
		|	RecyclableWaste.Count
		|INTO ReturnableWastePreparatory
		|FROM
		|	ReturnableWasteSpecifications AS RecyclableWaste
		|
		|UNION ALL
		|
		|SELECT
		|	RecyclableWaste.CostGroupNumber,
		|	RecyclableWaste.Department,
		|	RecyclableWaste.DirectionOfProductionIssue,
		|	RecyclableWaste.Recipient,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Package,
		|	RecyclableWaste.NumberOfPackages,
		|	RecyclableWaste.Count
		|FROM
		|	RecyclableWaste AS RecyclableWaste
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RecyclableWaste
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReturnableWasteSpecifications
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RecyclableWaste.CostGroupNumber,
		|	RecyclableWaste.Department,
		|	RecyclableWaste.DirectionOfProductionIssue,
		|	RecyclableWaste.Recipient,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Package,
		|	&PricingFields,
		|	RecyclableWaste.NumberOfPackages,
		|	RecyclableWaste.Count
		|INTO RecyclableWaste
		|FROM
		|	ReturnableWastePreparatory AS RecyclableWaste
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = RecyclableWaste.Products.ProductKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReturnableWastePreparatory
		|;
		|";

	PricingSettings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
	PricingSettings.SourceOfGoods = "RecyclableWaste";
	ReplacementText = PriceManagementSystemClientServer.TextOfFieldsForPricing(PricingSettings);
	If ValueIsFilled(ReplacementText) Then
		QueryText = StrReplace(QueryText, "&PricingFields", ReplacementText);
	Else
		QueryText = StrReplace(QueryText, "&PricingFields,", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of a request to merge specification data with an existing SPECIFICATION in the materials and works part.
// 
//	Returns:
//		String - query text.
//
Function QueryTextUsedMaterials()
	Return
		"SELECT
		|	&CostGroupNumber AS CostGroupNumber,
		|	MaterialsAndServices.StageSubdivision AS Department,
		|	MaterialsAndServices.Warehouse AS Warehouse,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.NumberOfPackages AS NumberOfPackages,
		|	MaterialsAndServices.Count AS Count
		|INTO BOMMaterialsAndServices
		|FROM
		|	&MaterialsAndServices AS MaterialsAndServices
		|WHERE
		|	NOT MaterialsAndServices.MethodOfReceivingMaterial =
		|		VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MaterialsAndServices.CostGroupNumber,
		|	ISNULL(MaterialsAndServices.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.NumberOfPackages AS NumberOfPackages,
		|	MaterialsAndServices.Count AS Count
		|INTO MaterialsAndServicesPreparatory
		|FROM
		|	BOMMaterialsAndServices AS MaterialsAndServices
		|
		|UNION ALL
		|
		|SELECT
		|	MaterialsAndServices.CostGroupNumber,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.NumberOfPackages,
		|	MaterialsAndServices.Count
		|FROM
		|	MaterialsAndServices AS MaterialsAndServices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MaterialsAndServices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BOMMaterialsAndServices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MaterialsAndServices.CostGroupNumber,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.NumberOfPackages,
		|	MaterialsAndServices.Count
		|INTO MaterialsAndServices
		|FROM
		|	MaterialsAndServicesPreparatory AS MaterialsAndServices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MaterialsAndServicesPreparatory
		|;
		|";
		
EndFunction

// Returns the text of a request to merge specification data with an existing TUE
// in the labor part.
//	Returns:
//		String - query text.
//
Function QueryTextLaborCosts()
	
	Return
		"SELECT
		|	&CostGroupNumber AS CostGroupNumber,
		|	LaborCosts.StageSubdivision AS Department,
		|	LaborCosts.WorkKind,
		|	LaborCosts.ProductCostElement,
		|	LaborCosts.Count AS Count
		|INTO LaborSpecifications
		|FROM
		|	&LaborCosts AS LaborCosts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LaborCosts.CostGroupNumber AS CostGroupNumber,
		|	LaborCosts.Department AS Department,
		|	LaborCosts.WorkKind,
		|	LaborCosts.ProductCostElement,
		|	LaborCosts.Count AS Count
		|INTO LaborCostsPreparatory
		|FROM
		|	LaborSpecifications AS LaborCosts
		|
		|UNION ALL
		|
		|SELECT
		|	LaborCosts.CostGroupNumber AS CostGroupNumber,
		|	LaborCosts.Department AS Department,
		|	LaborCosts.WorkKind,
		|	LaborCosts.ProductCostElement,
		|	LaborCosts.Count AS Count
		|FROM
		|	LaborCosts AS LaborCosts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP LaborCosts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP LaborSpecifications
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LaborCosts.CostGroupNumber AS CostGroupNumber,
		|	LaborCosts.Department AS Department,
		|	LaborCosts.WorkKind,
		|	LaborCosts.ProductCostElement,
		|	LaborCosts.Count AS Count
		|INTO LaborCosts
		|FROM
		|	LaborCostsPreparatory AS LaborCosts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP LaborCostsPreparatory
		|;
		|";
		
EndFunction

// Returns the query text for generating the final table
// in the product part.
Function RequestTextProductsByCostGroup()
	
	QueryText = "SELECT
		|	ProductTable.CostGroupNumber				AS CostGroupNumber,
		|	ProductTable.Organization					AS Organization,
		|	CASE
		|		WHEN ProductTable.GroupCosts IN
		|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments),
		|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
		|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
		|			THEN ISNULL(ProductTable.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END											AS ProductionIssueForActivity,
		|	ProductTable.GroupCosts				AS GroupCosts,
		|	ProductTable.Department					AS Department,
		|	ProductTable.DirectionOfProductionIssue				AS DirectionOfProductionIssue,
		|	ProductTable.Recipient						AS Recipient,
		|	ProductTable.Products					AS Products,
		|	ProductTable.Characteristic					AS Characteristic,
		|	ProductTable.Series							AS Series,
		|	ProductTable.Purpose						AS Purpose,
		|	ProductTable.BillOfMaterials					AS BillOfMaterials,
		|	SUM(ProductTable.Count)				AS Count,
		|	SUM(ProductTable.Count)				AS NumberOfPackages,
		|	SUM(ISNULL(CostShares.CostShare, 0))	AS CostShare,
		|	CatBillsOfMaterials.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
		|	ItemsPrices.Price 							AS Price,
		|	SUM(ProductTable.Count * ItemsPrices.Price) AS Sum
		|FROM
		|	ProductTable AS ProductTable
		|		LEFT JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS CostShares
		|		ON (CostShares.Ref = ProductTable.BillOfMaterials)
		|			AND (CostShares.Products = ProductTable.Products
		|				OR (CostShares.Products = VALUE(Catalog.Products.EmptyRef)
		|					AND CostShares.ProductKind = ProductTable.Products.ProductKind))
		|			AND (CostShares.Characteristic = ProductTable.Characteristic
		|				OR CostShares.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|		LEFT JOIN Catalog.BillsOfMaterials AS CatBillsOfMaterials
		|		ON CatBillsOfMaterials.Ref = ProductTable.BillOfMaterials
		|		LEFT JOIN
		|			&ItemsPrices AS ItemsPrices
		|		ON 
		|			&ItemPriceConnectionCondition
		|
		|GROUP BY
		|	ProductTable.BillOfMaterials,
		|	ProductTable.Products,
		|	ProductTable.DirectionOfProductionIssue,
		|	ProductTable.CostGroupNumber,
		|	CatBillsOfMaterials.MethodOfAllocatingFinishedProductCosts,
		|	ProductTable.Characteristic,
		|	ProductTable.Organization,
		|	CASE
		|		WHEN ProductTable.GroupCosts IN
		|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments),
		|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
		|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
		|			THEN ISNULL(ProductTable.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END,
		|	ProductTable.Purpose,
		|	ProductTable.Recipient,
		|	ProductTable.Series,
		|	ProductTable.Department,
		|	ItemsPrices.Price,
		|	ProductTable.GroupCosts
		|
		|ORDER BY
		|	ProductTable.Organization,
		|	CASE
		|		WHEN ProductTable.GroupCosts IN
		|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments),
		|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
		|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
		|			THEN ISNULL(ProductTable.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END,
		|	ProductTable.GroupCosts,
		|	ProductTable.Department,
		|	CatBillsOfMaterials.MethodOfAllocatingFinishedProductCosts,
		|	ProductTable.CostGroupNumber,
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.Series,
		|	ProductTable.Purpose,
		|	ProductTable.BillOfMaterials,
		|	ProductTable.DirectionOfProductionIssue,
		|	ProductTable.Recipient
		|
		|TOTALS BY
		|	Organization,
		|	ProductionIssueForActivity,
		|	GroupCosts,
		|	Department,
		|	MethodOfAllocatingFinishedProductCosts
		|;
		|";
		
	QueryText = StrReplace(QueryText,
		"&ItemsPrices",
		PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices("ProductTable",
			,
			New Structure("Parameter", "&PriceKind")));
	QueryText = StrReplace(QueryText,
		"&ItemPriceConnectionCondition",
		PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
		"ProductTable",
		"ItemsPrices"));
	
	Return QueryText;
	
EndFunction

// Returns the text of the query for generating the final table in terms of returnable waste.
//	Returns:
//		String - query text.
//
Function RequestTextReturnableWasteByCostGroup() Export
	QueryText = "SELECT
		|	RecyclableWaste.CostGroupNumber,
		|	RecyclableWaste.Department,
		|	RecyclableWaste.DirectionOfProductionIssue,
		|	RecyclableWaste.Recipient,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Package,
		|	SUM(RecyclableWaste.NumberOfPackages) AS NumberOfPackages,
		|	SUM(RecyclableWaste.Count) AS Count,
		|	ItemsPrices.Price AS Price,
		|	SUM(RecyclableWaste.Count * ItemsPrices.Price) AS Sum
		|FROM
		|	RecyclableWaste AS RecyclableWaste
		|		LEFT JOIN
		|			&ItemsPrices AS ItemsPrices
		|		ON 
		|			&ItemPriceConnectionCondition
		|WHERE
		|	&AutoFill
		|
		|GROUP BY
		|	RecyclableWaste.Package,
		|	RecyclableWaste.DirectionOfProductionIssue,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Recipient,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.Department,
		|	ItemsPrices.Price,
		|	RecyclableWaste.CostGroupNumber
		|
		|ORDER BY
		|	RecyclableWaste.CostGroupNumber,
		|	RecyclableWaste.Products,
		|	RecyclableWaste.Characteristic,
		|	RecyclableWaste.Series,
		|	RecyclableWaste.Purpose,
		|	RecyclableWaste.DirectionOfProductionIssue,
		|	RecyclableWaste.Recipient,
		|	RecyclableWaste.Department,
		|	RecyclableWaste.ProductCostElement,
		|	RecyclableWaste.Package
		|;
		|";
	
	QueryText = StrReplace(QueryText,
		"&ItemsPrices",
		PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices("RecyclableWaste",
			,
			New Structure("Parameter", "&PriceKind")));
	QueryText = StrReplace(QueryText,
		"&ItemPriceConnectionCondition",
		PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
		"RecyclableWaste",
		"ItemsPrices"));
	
	Return QueryText;
	
EndFunction

// Returns the query text for generating a summary table for materials and works.
//	Returns:
//		String - query text.
//
Function RequestTextMaterialsByCostGroup() Export
	Return
		"SELECT
		|	MaterialsAndServices.CostGroupNumber,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.Purpose,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	SUM(MaterialsAndServices.NumberOfPackages) AS NumberOfPackages,
		|	SUM(MaterialsAndServices.Count) AS Count
		|FROM
		|	MaterialsAndServices AS MaterialsAndServices
		|WHERE
		|	&AutoFill
		|
		|GROUP BY
		|	MaterialsAndServices.Purpose,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.CostGroupNumber
		|
		|ORDER BY
		|	MaterialsAndServices.CostGroupNumber,
		|	MaterialsAndServices.Products,
		|	MaterialsAndServices.Characteristic,
		|	MaterialsAndServices.Purpose,
		|	MaterialsAndServices.Warehouse,
		|	MaterialsAndServices.Department,
		|	MaterialsAndServices.ProductCostElement,
		|	MaterialsAndServices.Package
		|;
		|";
		
EndFunction

// Returns the text of the query to retrieve the brigades units
//
Function QueryTextLaborBrigades()
	
	Return
		"SELECT
		|	LaborCosts.Department,
		|	MAX(CatTeams.Ref) AS Team
		|INTO LaborBrigades
		|FROM
		|	LaborCosts AS LaborCosts
		|
		|	INNER JOIN Catalog.Teams AS CatTeams
		|	ON CatTeams.Department = LaborCosts.Department
		|WHERE
		|	&AutoFill
		|
		|GROUP BY
		|	LaborCosts.Department
		|HAVING
		|	COUNT(DISTINCT CatTeams.Ref) = 1
		|;
		|";
		
EndFunction

// Returns the text of the query for generating a summary table in terms of labor costs.
//	Returns:
//		String - query text.
//
Function RequestTextLaborCostsByCostGroup() Export
	
	Return QueryTextLaborBrigades() +
		"SELECT
		|	LaborCosts.CostGroupNumber,
		|	LaborCosts.Department,
		|	LaborBrigades.Team AS Performer,
		|	LaborCosts.WorkKind,
		|	LaborCosts.ProductCostElement,
		|	SUM(LaborCosts.Count) AS Count
		|FROM
		|	LaborCosts AS LaborCosts
		|
		|	LEFT JOIN LaborBrigades AS LaborBrigades
		|	ON LaborBrigades.Department = LaborCosts.Department
		|
		|WHERE
		|	&AutoFill
		|
		|GROUP BY
		|	LaborCosts.ProductCostElement,
		|	LaborCosts.WorkKind,
		|	LaborCosts.Department,
		|	LaborBrigades.Team,
		|	LaborCosts.CostGroupNumber
		|
		|ORDER BY
		|	LaborCosts.CostGroupNumber,
		|	LaborBrigades.Team,
		|	LaborCosts.WorkKind,
		|	LaborCosts.Department,
		|	LaborCosts.ProductCostElement
		|;
		|";
		
EndFunction

// The product table may contain returnable waste, the amount of which is covered
// by regulatory data. These rows must be removed from the product table.
Procedure EliminateReturnableWasteFromOutputProducts(ProductTable, ProductionData)
	
	Filters = New Structure("CostGroupNumber, Products, Characteristic");
	
	For Each CurStructure In ProductionData Do
		
		If CurStructure = Undefined Then
			Continue;
		EndIf;
		
		Filters.CostGroupNumber = CurStructure.CostGroupNumber;
		
		RecyclableWaste = CurStructure.RecyclableWaste.CopyColumns();
		RecyclableWaste.Columns.Add("Purpose",	New TypeDescription("CatalogRef.Assignments"));
		RecyclableWaste.Columns.Add("Series",		New TypeDescription("CatalogRef.ItemsBatches"));
		
		For Each CurWaste In CurStructure.RecyclableWaste Do
			FillPropertyValues(Filters, CurWaste, "Products, Characteristic");
			ProductionLines = ProductTable.FindRows(Filters);
			For Each CurProducts_ In ProductionLines Do
				
				Count = Min(CurProducts_.Count, CurWaste.Count);
				
				NewRow = RecyclableWaste.Add();
				FillPropertyValues(NewRow, CurWaste);
				NewRow.Purpose			= CurProducts_.Purpose;
				NewRow.Series				= CurProducts_.Series;
				NewRow.Count			= Count;
				NewRow.NumberOfPackages	= NewRow.Count
					* NewRow.PackageData.Denominator / NewRow.PackageData.Numerator;
				
				CurProducts_.Count	= CurProducts_.Count - Count;
				CurWaste.Count		= CurWaste.Count - Count;
				
			EndDo;
			
			If ProductionLines.Count() = 0 Then
				NewRow = RecyclableWaste.Add();
				FillPropertyValues(NewRow, CurWaste);
			EndIf;
		EndDo;
		
		CurStructure.RecyclableWaste = RecyclableWaste;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = ProductTable.FindRows(New Structure("Count", 0));
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		ProductTable.Delete(TableRow);
	EndDo;
	
EndProcedure

// Fills in the series table based on the original one
Procedure TransferSeriesSpecifiedSeparately(Document, TSName)
	
	If TSName = "ManufacturedProducts" Then
		NameOfTabularPartOfSeries = "BatchFinishedProducts";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		NameOfTabularPartOfSeries = "BatchSideAndIntermediateRelease";
	EndIf;
	
	For Each CurRow In Document[TSName] Do
		If (CurRow.BatchesIndicationStatus = 3
				Or CurRow.BatchesIndicationStatus = 5
				Or CurRow.BatchesIndicationStatus = 7
				Or CurRow.BatchesIndicationStatus = 9)
			And ValueIsFilled(CurRow.Series) Then
			FillPropertyValues(Document[NameOfTabularPartOfSeries].Add(), CurRow);
			CurRow.BatchesIndicationStatus = CurRow.BatchesIndicationStatus + 1;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Posting

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	Attributes.Date,
		|	Attributes.Date AS Period,
		|	Attributes.Number,
		|	Attributes.Ref,
		|	Attributes.Posted,
		|	Attributes.DeletionMark,
		|	Attributes.Organization,
		|	Attributes.Department,
		|	Attributes.GroupCosts,
		|	Attributes.ProductionIssueForActivity,
		|	Attributes.LineOfBusiness,
		|	Attributes.PriceKind,
		|	Attributes.InventoryOwnerAttributesAreSpecifiedManually,
		|	Attributes.Currency,
		|	Attributes.EmployeeResponsible,
		|	Attributes.Author,
		|	Attributes.Comment,
		|	Attributes.Patch,
		|	Attributes.ReversedDocument,
		|	Attributes.CorrectedDocument,
		|	Attributes.CorrectedDocument.Date AS AdjustmentPeriod_,
		|	Attributes.ReferenceOrderForLaborCosts,
		|	Attributes.CorrectionSavesProductionLots,
		|	CASE
		|		WHEN Attributes.Patch
		|			AND Attributes.CorrectionSavesProductionLots
		|			THEN Attributes.CorrectedDocument
		|		ELSE Attributes.Ref
		|	END AS DocumentLots
		|FROM
		|	Document.BackflushProduction AS Attributes
		|WHERE
		|	Attributes.Ref = &Ref
		|;
		|
		|SELECT DISTINCT
		|	T.MaterialProviderCompany AS Organization,
		|	T.Ref.Date AS Period
		|FROM
		|	Document.BackflushProduction.ManufacturedProducts AS T
		|WHERE
		|	T.Ref = &Ref
		|	AND T.InternalSubcontracting
		|	AND T.MaterialProviderCompany <> VALUE(Catalog.Companies.EmptyRef)
		|";
	
	Result = Query.ExecuteBatch();
	Attributes = Result[0].Select();
	Attributes.Next();
	
	For Each Column In Result[0].Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter("AnalyticalAccountingByProductsGroups",
								GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	
	Query.SetParameter("MetadataIdentifier",
							Common.MetadataObjectID(Type("DocumentRef.BackflushProduction")));
								
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	Query.SetParameter("InvoiceIsOrder",
							PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Undefined));
	
	Query.SetParameter("Period", Query.Parameters.Date);
	
	Query.SetParameter("UseDocumentCorrection", GetFunctionalOption("UseDocumentCorrection"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	CostCalculationAppliedAlgorithms.ToFormTTTypesOfVATActivities(Query, Result[1].Unload());
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency,
		Undefined,
		Query.Parameters.Date,
		Query.Parameters.Organization);
	
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
	
EndProcedure

Procedure SetRequestParameterInventoryOwnerAttributeByDefault(Query)
	
	If Query.Parameters.Property("DefaultStockView") Then
		Return;
	EndIf;
	
	DefaultStockView = Catalogs.InventoryKinds.DocumentInventoryView(Query.Parameters.Organization, Undefined);
	Query.SetParameter("DefaultStockView", DefaultStockView);
	RequestTypesOfInventory = New Query;
	RequestTypesOfInventory.Text =
	"SELECT
	|	TableOfGoods.Ref             AS Ref,
	|	TableOfGoods.MaterialProviderCompany AS MaterialProviderCompany
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Ref
	|	AND TableOfGoods.InternalSubcontracting
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.MaterialProviderCompany
	|";
	RequestTypesOfInventory.SetParameter("Ref", Query.Parameters.Ref);
	
	DefaultStockTypes = New ValueTable();
	DefaultStockTypes.Columns.Add("Ref", New TypeDescription("DocumentRef.BackflushProduction"));
	DefaultStockTypes.Columns.Add("MaterialProviderCompany", New TypeDescription("CatalogRef.Companies"));
	DefaultStockTypes.Columns.Add("InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
	
	Selection = RequestTypesOfInventory.Execute().Select();
	While Selection.Next() Do
		NewRow = DefaultStockTypes.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(NewRow.MaterialProviderCompany, Undefined);
	EndDo;
	
	Query.SetParameter("DefaultInventoryOwnerAttributesOfGiver", DefaultStockTypes);
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)

	If Query = Undefined Or Query.Parameters.Property("ProductAnalysisKeysInitialized") Then
		Return;
	EndIf;
	
	QueryTexts = New ValueList;
	

	QueryText =
	"SELECT DISTINCT
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ProductCostElement
	|FROM
	|	(
	// unit analytics when products are released to the warehouse or written off for expenses
	|	SELECT
	|		&Department										AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		GoodsTable.Purpose							AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|		
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|		
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND (GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			OR CatWarehouses.Ref IS NOT NULL
	|				AND (NOT CatWarehouses.ShopFloorStockroom OR &ProductCostingByPlannedCost))
	|	
	|	UNION ALL
	|	
	// Unit analytics when products are released to the warehouse or written off for expenses without an appointment.
	|	SELECT
	|		&Department										AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|		
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|		
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND (GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			OR CatWarehouses.Ref IS NOT NULL
	|				AND (NOT CatWarehouses.ShopFloorStockroom OR &ProductCostingByPlannedCost))
	|	
	|	UNION ALL
	|	
	// analytics of the recipient of products without destination
	|	SELECT
	|		GoodsTable.Recipient							AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND NOT GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	
	|	UNION ALL
	|	
	
	// Analytics of the division when returning waste to the warehouse or writing off for expenses.
	|	SELECT
	|		&Department										AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		GoodsTable.Purpose							AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|		
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|		
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND (GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			OR CatWarehouses.Ref IS NOT NULL
	|				AND NOT CatWarehouses.ShopFloorStockroom)
	|	
	|	UNION ALL
	|	
	// Analysis of the division when releasing returnable waste to the warehouse or writing off for expenses without an appointment.
	|	SELECT
	|		&Department										AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|		
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|		
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND (GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			OR CatWarehouses.Ref IS NOT NULL
	|				AND NOT CatWarehouses.ShopFloorStockroom)
	|	
	|	UNION ALL
	|	
	// analytics of the recipient of returnable waste without appointment
	|	SELECT DISTINCT
	|		GoodsTable.Recipient							AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND NOT GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	
	|	UNION ALL
	|	
	
	// analysis of the batch of production of the recipient of returnable waste
	|	SELECT DISTINCT
	|		GoodsTable.Department							AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		GoodsTable.Purpose							AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		GoodsTable.ProductCostElement						AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analysis of the batch of production of the recipient of returnable waste without appointment
	|	SELECT DISTINCT
	|		GoodsTable.Department							AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		GoodsTable.ProductCostElement						AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analysis of the production batch of the materials and works division
	|	SELECT DISTINCT
	|		GoodsTable.Department							AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		GoodsTable.Purpose							AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		GoodsTable.ProductCostElement						AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analytics of the production batch of the materials and works division without assignment
	|	SELECT DISTINCT
	|		GoodsTable.Department							AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		GoodsTable.ProductCostElement						AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analytics of the sender of materials and works without assignment
	|	SELECT DISTINCT
	|		GoodsTable.Warehouse									AS Warehouse,
	|		GoodsTable.Products							AS Products,
	|		GoodsTable.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// committee analytics
	|	SELECT DISTINCT
	|		GoodsTable.InventoryOwnerAttribute.GoodsOwner						AS Warehouse,
	|		GoodsTable.ItemsLocationAttributes.Products							AS Products,
	|		GoodsTable.ItemsLocationAttributes.Characteristic						AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.InventoryOwnerAttributesMaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	
	|	UNION ALL
	|	
	// Analytics of the manufacturing division for internal processing
	|	SELECT DISTINCT
	|		&Department               AS Warehouse,
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Purpose     AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END                        AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.InternalSubcontracting
	|	) AS GoodsTable
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON GoodsTable.Products = Dimension.Products
	|	AND GoodsTable.Characteristic = Dimension.Characteristic
	|	AND GoodsTable.Series = Dimension.Series
	|	AND GoodsTable.Warehouse = Dimension.StorageLocation
	|	AND GoodsTable.Purpose = Dimension.Purpose
	|	AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.ProductCostElement";
	
	QueryTexts.Add(QueryText);
	
	AnalyticsRequest = New Query;
	AnalyticsRequest.Text = StrConcat(QueryTexts.UnloadValues(), Common.QueryBatchSeparator());
	
	AnalyticsRequest.SetParameter("Ref", Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Department", Query.Parameters.Department);
	AnalyticsRequest.SetParameter("ProductCostingByPlannedCost", Query.Parameters.ProductCostingByPlannedCost);
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;

	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.BackflushProduction";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("KeepRecordsOfInventoryCostByAssignments",
		Format(GetFunctionalOption("KeepRecordsOfInventoryCostByAssignments"), "BF=FALSE; BT=TRUE"));
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Undefined, QueryTexts, Undefined);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, QueryTexts, Undefined);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Undefined, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
	

	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName%, chưa thực hiện điều chỉnh nội dung truy vấn 
								|tạo các bản ghi kết chuyển theo biểu ghi %RegisterName%.';
								|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса 
								|формирования движений по регистру %RegisterName%.';
								|en = 'In the %FullDocumentName% document, adaptation of request for generating records 
								|of the %RegisterName% register is not implemented.'; fa = 'In the %FullDocumentName% document, adaptation of request for generating records 
								|of the %RegisterName% register is not implemented.';
								|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento del testo di richiesta 
								|della generazione dei movimenti sul registro%RegisterName%.';
								|pl = 'W dokumencie %FullDocumentName%nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów 
								| w rejestrze %RegisterName%.';
								|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi 
								|talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure SetEmptyBatchTrackingAnalyticsQueryParameter(Query)
	
	If Not Query.Parameters.Property("AnalysisOfAccountingOfBatchesOfGoods") Then
		SelectionByPartyAnalysis = New Structure("Date, AssetTaxClass",
												Query.Parameters.Date,
												Enums.AssetKinds.Goods);
		Query.SetParameter("AnalysisOfAccountingOfBatchesOfGoods",
									Catalogs.KeysForLotVendorAttributes.GetAnalyticsKey(SelectionByPartyAnalysis));
	EndIf;
	
	If Not Query.Parameters.Property("AnalysisOfWorkBatchAccounting") Then
		SelectionByPartyAnalysis = New Structure("Date, AssetTaxClass",
												Query.Parameters.Date,
												Enums.AssetKinds.OtherWorksAndServices);
		Query.SetParameter("AnalysisOfWorkBatchAccounting",
									Catalogs.KeysForLotVendorAttributes.GetAnalyticsKey(SelectionByPartyAnalysis));
	EndIf;
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return BackflushProductionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
// 
// Returns:
// 	See BackflushProductionLocalization.RequestTextTTReflectedInLocalAccounting
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return BackflushProductionLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

#Region QueryTextsTemporaryTables

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText = 
	"SELECT
	|	Departments.Ref							AS Ref,
	|	Departments.BusinessOperation 			AS BusinessOperation,
	|	Departments.Organization						AS Organization,
	|	Departments.Department						AS Department,
	|	MIN(Departments.AdditionalRecord)		AS AdditionalRecord
	|INTO TTBases
	|FROM
	|	(
	// Issuing division
	|	SELECT
	|		DocumentData.Ref											AS Ref,
	|		VALUE(Enum.BusinessTransactions.ProductsRelease)	AS BusinessOperation,
	|		DocumentData.Organization										AS Organization,
	|		&Department													AS Department,
	|		FALSE															AS AdditionalRecord
	|	FROM
	|		Document.BackflushProduction AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|
	// Internal Processing
	|	SELECT
	|		DocumentData.Ref											AS Ref,
	|		VALUE(Enum.BusinessTransactions.ProductsRelease)	AS BusinessOperation,
	|		DocumentData.MaterialProviderCompany								AS Organization,
	|		&Department													AS Department,
	|		TRUE															AS AdditionalRecord
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND DocumentData.InternalSubcontracting
	|	
	|	UNION ALL
	|
	// Recipient of returnable waste
	|	SELECT
	|		DocumentData.Ref											AS Ref,
	|		VALUE(Enum.BusinessTransactions.ProductsRelease)	AS BusinessOperation,
	|		CASE
	|			WHEN NOT DocumentData.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|				THEN DocumentData.ProductOwner
	|			WHEN CostGroupsData.MaterialProviderCompany IS NOT NULL
	|				THEN CostGroupsData.MaterialProviderCompany
	|			WHEN TRUE
	|				THEN DocumentData.Ref.Organization
	|		END															AS Organization,
	|		DocumentData.Department									AS Department,
	|		TRUE															AS AdditionalRecord
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS DocumentData
	|		
	|		LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS CostGroupsData
	|		ON CostGroupsData.Ref           = DocumentData.Ref
	|		AND CostGroupsData.CostGroupNumber = DocumentData.CostGroupNumber
	|		AND CostGroupsData.InternalSubcontracting
	|	
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.Department = &Department
	|
	|	UNION ALL
	|
	// Materials Division
	|	SELECT
	|		DocumentData.Ref																AS Ref,
	|		VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)	AS BusinessOperation,
	|		DocumentData.InventoryOwnerAttribute.Organization												AS Organization,
	|		DocumentData.Department														AS Department,
	|		TRUE																				AS AdditionalRecord
	|	FROM
	|		Document.BackflushProduction.InventoryOwnerAttributesMaterialsAndWorks AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.Department = &Department
	|
	|	UNION ALL
	|
	// Division of works
	|	SELECT
	|		DocumentData.Ref																AS Ref,
	|		VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)	AS BusinessOperation,
	|		&Organization																		AS Organization,
	|		DocumentData.Department														AS Department,
	|		TRUE																				AS AdditionalRecord
	|	FROM
	|		Document.BackflushProduction.MaterialsAndWorks AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.Department = &Department
	|		AND DocumentData.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	) AS Departments
	|
	|GROUP BY
	|	Departments.Ref,
	|	Departments.Organization,
	|	Departments.Department,
	|	Departments.BusinessOperation
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfInventoryGiverByDefault(Query, QueryTexts)
	
	RegisterName = "TTTypesOfInventoryGiverByDefault";
	
	QueryText =
	"SELECT
	|	InventoryKinds.Ref             AS Ref,
	|	InventoryKinds.MaterialProviderCompany AS MaterialProviderCompany,
	|	InventoryKinds.InventoryOwnerAttribute         AS InventoryOwnerAttribute
	|INTO TTTypesOfInventoryGiverByDefault
	|FROM
	|	&DefaultInventoryOwnerAttributesOfGiver AS InventoryKinds
	|
	|INDEX BY
	|	Ref,
	|	MaterialProviderCompany
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""InventoryOwnerAttributesFinishedProducts""	AS TabularSectionName,
	|	DocumentTable.LineNumber	AS LineNumber,
	|	UNDEFINED					AS Vendor,
	|	UNDEFINED					AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|	UNDEFINED					AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|		ELSE VALUE(Enum.AssetKinds.Goods)
	|	END							AS AssetTaxClass,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			THEN DocumentTable.RowCode
	|		ELSE 0
	|	END							AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesFinishedProducts AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""ManufacturedProducts""				AS TabularSectionName,
	|	DocumentTable.LineNumber	AS LineNumber,
	|	UNDEFINED					AS Vendor,
	|	UNDEFINED					AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|	UNDEFINED					AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			THEN DocumentTable.RowCode
	|		ELSE 0
	|	END							AS RowCode
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT DocumentTable.Products.TracedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryOwnerAttributesSideProducts""	AS TabularSectionName,
	|	DocumentTable.LineNumber	AS LineNumber,
	|	UNDEFINED					AS Vendor,
	|	UNDEFINED					AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|	UNDEFINED					AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|		ELSE VALUE(Enum.AssetKinds.Goods)
	|	END							AS AssetTaxClass,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			THEN DocumentTable.LineNumber
	|		ELSE 0
	|	END							AS RowCode
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesSideProducts AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""SideAndIntermediateRelease""				AS TabularSectionName,
	|	DocumentTable.LineNumber	AS LineNumber,
	|	UNDEFINED					AS Vendor,
	|	UNDEFINED					AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|	UNDEFINED					AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			THEN DocumentTable.LineNumber
	|		ELSE 0
	|	END							AS RowCode
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT DocumentTable.Products.TracedGoods
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField,
																								Query,
																								QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
	
	SetEmptyBatchTrackingAnalyticsQueryParameter(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	
	QueryText = 
	// Output items (goods) by recipient
	"SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	GoodsTable.CostGroupNumber                     AS CostGroupNumber,
	|	""InventoryOwnerAttributesFinishedProducts""                      AS TabularSectionName,
	|	GoodsTable.LineNumber                           AS LineNumber,
	|	VALUE(Catalog.Companies.EmptyRef)       AS ProductOwner,
	|	""Products""                                    AS SourceFinancialAccountingDimension,
	|	UNDEFINED                                        AS SourceCorFinancialAccountingDimension,
	|	""AssignmentRecipient""                            AS SourceVATActivityType,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS SenderItem,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS SenderCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS SenderBatch,
	|	CASE
	|		WHEN NOT GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.Ref.Department
	|		ELSE GoodsTable.ItemsLocationAttributes.StorageLocation
	|	END                                                      AS SenderStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS SenderDestination,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS SenderOfProductCostingElements,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS RecipientProducts,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS RecipientCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS RecipientBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS RecipientStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS RecipientAppointment,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS RecipientProductCostingElements,
	|
	|	GoodsTable.DirectionOfProductionIssue                    AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	GoodsTable.InventoryOwnerAttribute                            AS InventoryOwnerAttribute,
	|	UNDEFINED                                        AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END                                               AS ExpenseItem,
	|	UNDEFINED                                        AS CCDNumber,
	|	GoodsTable.BillOfMaterials                          AS BillOfMaterials,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	GoodsTable.Count                            AS Count,
	|	0                                                   AS QuantityByGBRN,
	|	CASE
	|		WHEN TRUE
	|			THEN GoodsTable.Sum
	|	END                                               AS Sum,
	|	0                                                   AS OffBalanceSheetAmount,
	|		
	|	GoodsTable.RowID                   AS RowID,
	|	GoodsTable.FinRecordID                AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease) AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN GoodsTable.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE GoodsTable.Department
	|	END                                               AS ExpenseRecipientDivision,
	|	GoodsTable.DimensionOfExpenses                     AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension              AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings                  AS GLAccountSettings,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS Work_5,
	|	GoodsTable.ItemsLocationAttributes.Products.TracedGoods AS TraceableWork,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE) AS ShopFloorStockroom
	|INTO TTProducts_1
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesFinishedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	// Output items (works) by recipient
	|SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	GoodsTable.CostGroupNumber                     AS CostGroupNumber,
	|	""ManufacturedProducts""                                 AS TabularSectionName,
	|	GoodsTable.LineNumber                           AS LineNumber,
	|	VALUE(Catalog.Companies.EmptyRef)       AS ProductOwner,
	|	""Products""                                    AS SourceFinancialAccountingDimension,
	|	UNDEFINED                                        AS SourceCorFinancialAccountingDimension,
	|	""AssignmentRecipient""                            AS SourceVATActivityType,
	|
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Products
	|		ELSE UNDEFINED
	|	END                                                      AS SenderItem,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Characteristic
	|		ELSE UNDEFINED
	|	END                                                      AS SenderCharacteristics,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Series
	|		ELSE UNDEFINED
	|	END                                                      AS SenderBatch,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.StorageLocation
	|		ELSE UNDEFINED
	|	END                                                      AS SenderStorageLocation,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Purpose
	|		ELSE UNDEFINED
	|	END                                                      AS SenderDestination,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.ProductCostElement
	|		ELSE UNDEFINED
	|	END                                                      AS SenderOfProductCostingElements,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS RecipientProducts,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS RecipientCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS RecipientBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS RecipientStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS RecipientAppointment,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS RecipientProductCostingElements,
	|
	|	GoodsTable.DirectionOfProductionIssue                    AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	UNDEFINED                                        AS InventoryOwnerAttribute,
	|	UNDEFINED                                        AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END                                               AS ExpenseItem,
	|	UNDEFINED                                        AS CCDNumber,
	|	GoodsTable.BillOfMaterials                          AS BillOfMaterials,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	GoodsTable.Count                            AS Count,
	|	0                                                   AS QuantityByGBRN,
	|	GoodsTable.Sum                                 AS Sum,
	|	0                                                   AS OffBalanceSheetAmount,
	|	
	|	GoodsTable.RowID                   AS RowID,
	|	GoodsTable.RowID                   AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease) AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN GoodsTable.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE GoodsTable.Department
	|	END												AS ExpenseRecipientDivision,
	|	GoodsTable.DimensionOfExpenses					AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings				AS GLAccountSettings,
	|	TRUE												AS Work_5,
	|	FALSE												AS TraceableWork,
	|	FALSE                                                AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.Products.TracedGoods
	|
	|UNION ALL
	|
	// By-products (goods) by recipient
	|SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	GoodsTable.CostGroupNumber                     AS CostGroupNumber,
	|	""InventoryOwnerAttributesSideProducts""                      AS TabularSectionName,
	|	GoodsTable.LineNumber                           AS LineNumber,
	|	GoodsTable.ProductOwner                       AS ProductOwner,
	|	""Products""                                    AS SourceFinancialAccountingDimension,
	|	UNDEFINED                                        AS SourceCorFinancialAccountingDimension,
	|	""AssignmentRecipient""                            AS SourceVATActivityType,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS SenderItem,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS SenderCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS SenderBatch,
	|	CASE
	|		WHEN NOT GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.Ref.Department
	|		ELSE GoodsTable.ItemsLocationAttributes.StorageLocation
	|	END                                                      AS SenderStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS SenderDestination,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS SenderOfProductCostingElements,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS RecipientProducts,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS RecipientCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS RecipientBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS RecipientStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS RecipientAppointment,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS RecipientProductCostingElements,
	|
	|	GoodsTable.DirectionOfProductionIssue                    AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	GoodsTable.InventoryOwnerAttribute                            AS InventoryOwnerAttribute,
	|	UNDEFINED                                        AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END                                               AS ExpenseItem,
	|	UNDEFINED                                        AS CCDNumber,
	|	UNDEFINED                                        AS BillOfMaterials,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	GoodsTable.Count                            AS Count,
	|	0                                                   AS QuantityByGBRN,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN 0
	|		ELSE GoodsTable.Sum
	|	END                                               AS Sum,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN GoodsTable.Sum
	|		ELSE 0
	|	END                                               AS OffBalanceSheetAmount,
	|	
	|	GoodsTable.RowID                   AS RowID,
	|	GoodsTable.FinRecordID                AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN GoodsTable.ReceivingBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN GoodsTable.Department
	|		ELSE GoodsTable.ReceivingBusinessUnit
	|	END											AS ExpenseRecipientDivision,
	|	GoodsTable.DimensionOfExpenses					AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings				AS GLAccountSettings,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS Work_5,
	|	GoodsTable.ItemsLocationAttributes.Products.TracedGoods AS TraceableWork,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE) AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesSideProducts AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	// By-products (works) by recipient
	|SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	GoodsTable.CostGroupNumber                     AS CostGroupNumber,
	|	""SideAndIntermediateRelease""                                 AS TabularSectionName,
	|	GoodsTable.LineNumber                           AS LineNumber,
	|	GoodsTable.ProductOwner                       AS ProductOwner,
	|	""Products""                                    AS SourceFinancialAccountingDimension,
	|	UNDEFINED                                        AS SourceCorFinancialAccountingDimension,
	|	""AssignmentRecipient""                            AS SourceVATActivityType,
	|
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Products
	|		ELSE UNDEFINED
	|	END                                                      AS SenderItem,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Characteristic
	|		ELSE UNDEFINED
	|	END                                                      AS SenderCharacteristics,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Series
	|		ELSE UNDEFINED
	|	END                                                      AS SenderBatch,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.StorageLocation
	|		ELSE UNDEFINED
	|	END                                                      AS SenderStorageLocation,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.Purpose
	|		ELSE UNDEFINED
	|	END                                                      AS SenderDestination,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.ItemsLocationAttributes.ProductCostElement
	|		ELSE UNDEFINED
	|	END                                                      AS SenderOfProductCostingElements,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS RecipientProducts,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS RecipientCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS RecipientBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS RecipientStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS RecipientAppointment,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS RecipientProductCostingElements,
	|
	|	GoodsTable.DirectionOfProductionIssue                    AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	UNDEFINED                                        AS InventoryOwnerAttribute,
	|	UNDEFINED                                        AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END                                               AS ExpenseItem,
	|	UNDEFINED                                        AS CCDNumber,
	|	UNDEFINED                                        AS BillOfMaterials,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	GoodsTable.Count                            AS Count,
	|	0                                                   AS QuantityByGBRN,
	|	GoodsTable.Sum                                 AS Sum,
	|	0                                                   AS OffBalanceSheetAmount,
	|	
	|	GoodsTable.RowID                   AS RowID,
	|	GoodsTable.RowID                   AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN GoodsTable.ReceivingBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN GoodsTable.Department
	|		ELSE GoodsTable.ReceivingBusinessUnit
	|	END												AS ExpenseRecipientDivision,
	|	GoodsTable.DimensionOfExpenses						AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension				AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings					AS GLAccountSettings,
	|	TRUE												AS Work_5,
	|	FALSE												AS TraceableWork,
	|	FALSE                                                AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.Products.TracedGoods
	|
	|UNION ALL
	|
	// By-products (goods) by batch
	|SELECT
	|	GoodsTable.Ref                                    AS Ref,
	|	GoodsTable.CostGroupNumber                         AS CostGroupNumber,
	|	""InventoryOwnerAttributesSideProducts""                          AS TabularSectionName,
	|	GoodsTable.LineNumber                               AS LineNumber,
	|	GoodsTable.ProductOwner                           AS ProductOwner,
	|	""ProductionLot""                                  AS SourceFinancialAccountingDimension,
	|	""Products""                                        AS SourceCorFinancialAccountingDimension,
	|	""ProductionLot""                                  AS SourceVATActivityType,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS SenderItem,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS SenderCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS SenderBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS SenderStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS SenderDestination,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS SenderOfProductCostingElements,
	|
	|	GoodsTable.ItemsLocationAttributes.Products   AS RecipientProducts,
	|	GoodsTable.ItemsLocationAttributes.Characteristic AS RecipientCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series          AS RecipientBatch,
	|	GoodsTable.Department                             AS RecipientStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose     AS RecipientAppointment,
	|	GoodsTable.ProductCostElement                         AS RecipientProductCostingElements,
	|
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)  AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	GoodsTable.InventoryOwnerAttribute                                AS InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttribute                                AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                            AS ExpenseItem,
	|	UNDEFINED                                            AS CCDNumber,
	|	UNDEFINED                                            AS BillOfMaterials,
	|	GoodsTable.ProductCostElement                         AS ProductCostElement,
	|	-1 * GoodsTable.Count                           AS Count,
	|	0                                                       AS QuantityByGBRN,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN 0
	|		ELSE -1 * GoodsTable.Sum
	|	END                                                   AS Sum,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN -1 * GoodsTable.Sum
	|		ELSE 0
	|	END                                                   AS OffBalanceSheetAmount,
	|	
	|	GoodsTable.RowID                       AS RowID,
	|	GoodsTable.FinRecordID                    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN GoodsTable.ReceivingBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN GoodsTable.Department
	|		ELSE GoodsTable.ReceivingBusinessUnit
	|	END                                                   AS ExpenseRecipientDivision,
	|	GoodsTable.DimensionOfExpenses                         AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension                  AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings                      AS GLAccountSettings,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                   AS Work_5,
	|	GoodsTable.ItemsLocationAttributes.Products.TracedGoods AS TraceableWork,
	|	FALSE                                                    AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesSideProducts AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	// By-products (works) by batch
	|SELECT
	|	GoodsTable.Ref                          AS Ref,
	|	GoodsTable.CostGroupNumber               AS CostGroupNumber,
	|	""SideAndIntermediateRelease""                           AS TabularSectionName,
	|	GoodsTable.LineNumber                     AS LineNumber,
	|	GoodsTable.ProductOwner                 AS ProductOwner,
	|	""ProductionLot""                        AS SourceFinancialAccountingDimension,
	|	""Products""                              AS SourceCorFinancialAccountingDimension,
	|	""ProductionLot""                        AS SourceVATActivityType,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS SenderItem,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS SenderCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS SenderBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS SenderStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS SenderDestination,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS SenderOfProductCostingElements,
	|
	|	GoodsTable.Products                    AS RecipientProducts,
	|	GoodsTable.Characteristic                  AS RecipientCharacteristics,
	|	GoodsTable.Series                           AS RecipientBatch,
	|	GoodsTable.Department                   AS RecipientStorageLocation,
	|	GoodsTable.Purpose                      AS RecipientAppointment,
	|	GoodsTable.ProductCostElement               AS RecipientProductCostingElements,
	|
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)  AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	UNDEFINED                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                  AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                  AS ExpenseItem,
	|	UNDEFINED                                  AS CCDNumber,
	|	UNDEFINED                                  AS BillOfMaterials,
	|	GoodsTable.ProductCostElement               AS ProductCostElement,
	|	-1 * GoodsTable.Count                 AS Count,
	|	0                                             AS QuantityByGBRN,
	|	-1 * GoodsTable.Sum                      AS Sum,
	|	0                                             AS OffBalanceSheetAmount,
	|	
	|	GoodsTable.RowID             AS RowID,
	|	GoodsTable.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN GoodsTable.ReceivingBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN GoodsTable.Department
	|		ELSE GoodsTable.ReceivingBusinessUnit
	|	END											AS ExpenseRecipientDivision,
	|	GoodsTable.DimensionOfExpenses					AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings				AS GLAccountSettings,
	|	TRUE											AS Work_5,
	|	FALSE											AS TraceableWork,
	|	FALSE                                          AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.Products.TracedGoods
	|
	|UNION ALL
	|
	// Works by batch
	|SELECT
	|	GoodsTable.Ref                          AS Ref,
	|	GoodsTable.CostGroupNumber               AS CostGroupNumber,
	|	""""                                          AS TabularSectionName,
	|	GoodsTable.LineNumber                     AS LineNumber,
	|	VALUE(Catalog.Companies.EmptyRef) AS ProductOwner,
	|	""ProductionLot""                        AS SourceFinancialAccountingDimension,
	|	UNDEFINED                                  AS SourceCorFinancialAccountingDimension,
	|	""ProductionLot""                        AS SourceVATActivityType,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS SenderItem,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS SenderCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS SenderBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS SenderStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS SenderDestination,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS SenderOfProductCostingElements,
	|
	|	GoodsTable.Products                    AS RecipientProducts,
	|	GoodsTable.Characteristic                  AS RecipientCharacteristics,
	|	GoodsTable.Series                           AS RecipientBatch,
	|	GoodsTable.Department                   AS RecipientStorageLocation,
	|	GoodsTable.Purpose                      AS RecipientAppointment,
	|	GoodsTable.ProductCostElement               AS RecipientProductCostingElements,
	|
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	UNDEFINED                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                  AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                  AS ExpenseItem,
	|	UNDEFINED                                  AS CCDNumber,
	|	UNDEFINED                                  AS BillOfMaterials,
	|	GoodsTable.ProductCostElement               AS ProductCostElement,
	|	GoodsTable.Count                      AS Count,
	|	0                                             AS QuantityByGBRN,
	|	0                                             AS Sum,
	|	0                                             AS OffBalanceSheetAmount,
	|	
	|	UNDEFINED                                  AS RowID,
	|	GoodsTable.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots) AS BusinessTransactionSetting,
	|
	|	UNDEFINED								AS ExpenseRecipientDivision,
	|	UNDEFINED								AS DimensionOfExpenses,
	|	UNDEFINED								AS AssetsLiabilitiesDimension,
	|	UNDEFINED								AS GLAccountSettings,
	|	TRUE										AS Work_5,
	|	FALSE										AS TraceableWork,
	|	FALSE                                          AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.Products.TracedGoods
	|
	|UNION ALL
	|
	// Materials and works on the Lot reference
	|SELECT
	|	GoodsTable.Ref                                    AS Ref,
	|	GoodsTable.CostGroupNumber                         AS CostGroupNumber,
	|	""""                                                    AS TabularSectionName,
	|	GoodsTable.LineNumber                               AS LineNumber,
	|	VALUE(Catalog.Companies.EmptyRef)           AS ProductOwner,
	|	""ProductionLot""                                  AS SourceFinancialAccountingDimension,
	|	UNDEFINED                                            AS SourceCorFinancialAccountingDimension,
	|	""ProductionLot""                                  AS SourceVATActivityType,
	|
	|	GoodsTable.ItemsLocationAttributes.Products      AS SenderItem,
	|	GoodsTable.ItemsLocationAttributes.Characteristic    AS SenderCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series             AS SenderBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation     AS SenderStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose        AS SenderDestination,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS SenderOfProductCostingElements,
	|
	|	GoodsTable.ItemsLocationAttributes.Products   AS RecipientProducts,
	|	GoodsTable.ItemsLocationAttributes.Characteristic AS RecipientCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series          AS RecipientBatch,
	|	GoodsTable.Department                             AS RecipientStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.Purpose     AS RecipientAppointment,
	|	GoodsTable.ProductCostElement                         AS RecipientProductCostingElements,
	|
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS DirectionOfProductionIssue,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	GoodsTable.InventoryOwnerAttribute                                AS InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute                      AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                            AS ExpenseItem,
	|	GoodsTable.CCDNumber                                  AS CCDNumber,
	|	UNDEFINED                                            AS BillOfMaterials,
	|	GoodsTable.ProductCostElement                         AS ProductCostElement,
	|	GoodsTable.Count                                AS Count,
	|	GoodsTable.QuantityByGBRN                          AS QuantityByGBRN,
	|	0                                                       AS Sum,
	|	0                                                       AS OffBalanceSheetAmount,
	|	
	|	UNDEFINED                                            AS RowID,
	|	GoodsTable.RowID                       AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots) AS BusinessTransactionSetting,
	|	
	|	UNDEFINED																		AS ExpenseRecipientDivision,
	|	UNDEFINED																		AS DimensionOfExpenses,
	|	UNDEFINED																		AS AssetsLiabilitiesDimension,
	|	UNDEFINED																		AS GLAccountSettings,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END																				AS Work_5,
	|	GoodsTable.ItemsLocationAttributes.Products.TracedGoods			AS TraceableWork,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)	AS ShopFloorStockroom
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesMaterialsAndWorks AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName); 
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAnalysisKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProducts_1.Ref												AS Ref,
	|	TTProducts_1.DirectionOfProductionIssue									AS DirectionOfProductionIssue,
	|	TTProducts_1.BusinessOperation								AS BusinessOperation,
	|	CASE
	|		WHEN TTProducts_1.InventoryOwnerAttribute = UNDEFINED
	|			AND NOT TTProducts_1.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TTProducts_1.ProductOwner
	|		WHEN TTProducts_1.InventoryOwnerAttribute = UNDEFINED
	|			AND CatProductionLots.InternalSubcontracting
	|			AND NOT TTProducts_1.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|			THEN CatProductionLots.Organization
	|		WHEN NOT TTProducts_1.InventoryOwnerAttribute = UNDEFINED
	|			THEN TTProducts_1.InventoryOwnerAttribute.Organization
	|		WHEN TRUE
	|			THEN &Organization
	|	END														AS Organization,
	|	CatProductionLots.InternalSubcontracting					AS InternalSubcontracting,
	|	CASE
	|		WHEN CatProductionLots.InternalSubcontracting
	|			THEN CatProductionLots.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END														AS MaterialProviderCompany,
	|	CASE
	|		WHEN NOT TTProducts_1.SenderItem = UNDEFINED
	|			THEN ProductKeysBySender.DimensionKey
	|		ELSE UNDEFINED
	|	END														AS AnalysisOfProductTrackingBySender,
	|	CASE
	|		WHEN NOT TTProducts_1.SenderItem = UNDEFINED
	|			THEN ProductKeysBySenderWithoutDestination.DimensionKey
	|		ELSE UNDEFINED
	|	END														AS AnalysisOfProductTrackingBySenderWithoutDestination,
	|	CASE
	|		WHEN NOT TTProducts_1.RecipientProducts = UNDEFINED
	|			THEN ItemKeysByRecipient.DimensionKey
	|		ELSE UNDEFINED
	|	END														AS AnalysisOfProductAccountingByRecipient,
	|	CASE
	|		WHEN NOT TTProducts_1.RecipientProducts = UNDEFINED
	|			THEN ItemKeysByRecipientWithoutAssignment.DimensionKey
	|		ELSE UNDEFINED
	|	END														AS AnalysisOfProductAccountingByRecipientWithoutAssignment,
	|	TTProducts_1.InventoryOwnerAttribute											AS InventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner							AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	CatInventoryKinds.SaleOfAnotherCompanyInventory			AS SaleOfAnotherCompanyInventory,
	|	TTProducts_1.CorInventoryOwnerAttribute										AS CorInventoryOwnerAttribute,
	|	TTProducts_1.SenderStorageLocation							AS Warehouse,
	|	TTProducts_1.RecipientStorageLocation							AS Recipient,
	|	TTProducts_1.RecipientProducts								AS Products,
	|	TTProducts_1.RecipientCharacteristics							AS Characteristic,
	|	TTProducts_1.ExpenseItem										AS ExpenseItem,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes				AS LotVendorAttributes,
	|	CatProductionLots.Ref								AS ProductionLot,
	|	CASE
	|		WHEN TTProducts_1.SourceFinancialAccountingDimension = ""Products""
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT TTProducts_1.SenderItem = UNDEFINED
	|			AND NOT TTProducts_1.SenderItem.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN TTProducts_1.SenderItem.AnalyticalGroup
	|		WHEN TTProducts_1.SourceFinancialAccountingDimension = ""Products""
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT TTProducts_1.RecipientProducts = UNDEFINED
	|			AND NOT TTProducts_1.RecipientProducts.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN TTProducts_1.RecipientProducts.AnalyticalGroup
	|		WHEN TTProducts_1.SourceFinancialAccountingDimension = ""ProductionLot""
	|			THEN CatProductionLots.ProductsGroup
	|		ELSE UNDEFINED
	|	END														AS FinancialAccountingDimension,
	|	CASE
	|		WHEN TTProducts_1.SourceCorFinancialAccountingDimension = ""Products""
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT TTProducts_1.SenderItem = UNDEFINED
	|			AND NOT TTProducts_1.SenderItem.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN TTProducts_1.SenderItem.AnalyticalGroup
	|		WHEN TTProducts_1.SourceCorFinancialAccountingDimension = ""Products""
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT TTProducts_1.RecipientProducts = UNDEFINED
	|			AND NOT TTProducts_1.RecipientProducts.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN TTProducts_1.RecipientProducts.AnalyticalGroup
	|		WHEN TTProducts_1.SourceCorFinancialAccountingDimension = ""ProductionLot""
	|			THEN CatProductionLots.ProductsGroup
	|		ELSE UNDEFINED
	|	END														AS CorControllingAttributes,
	|	CASE
	|		WHEN TTProducts_1.SourceVATActivityType = ""AssignmentRecipient""
	|			AND ISNULL(TTProducts_1.RecipientAppointment.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN TTProducts_1.RecipientAppointment.VATActivityType
	|		WHEN TTProducts_1.SourceVATActivityType = ""AssignmentSender""
	|			AND ISNULL(TTProducts_1.SenderDestination.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN TTProducts_1.SenderDestination.VATActivityType
	|		WHEN TTProducts_1.SourceVATActivityType = ""AssignmentRecipient""
	|		 AND NOT TTActivitiesVAT.VATActivityType IS NULL
	|			THEN TTActivitiesVAT.VATActivityType
	|		WHEN TTProducts_1.SourceVATActivityType = ""AssignmentRecipient""
	|			OR TTProducts_1.SourceVATActivityType = ""AssignmentSender""
	|			THEN &ProductionIssueForActivity
	|		WHEN TTProducts_1.SourceVATActivityType = ""ProductionLot""
	|			THEN CatProductionLots.VATActivityType
	|		ELSE UNDEFINED
	|	END														AS VATActivityType,
	|	TTProducts_1.CCDNumber											AS CCDNumber,
	|	TTProducts_1.ProductCostElement									AS ProductCostElement,
	|	TTProducts_1.BillOfMaterials										AS BillOfMaterials,
	|	TTProducts_1.Count											AS Count,
	|	TTProducts_1.QuantityByGBRN									AS QuantityByGBRN,
	|	TTProducts_1.Sum												AS Sum,
	|	CAST(TTProducts_1.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))				AS SumMan,
	|	CAST(TTProducts_1.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))				AS SumCompl,
	|	CAST(TTProducts_1.OffBalanceSheetAmount * &ConversionRateToManCurrency AS NUMBER(31,2))	AS OffBalanceSheetManAmount,
	|	CAST(TTProducts_1.OffBalanceSheetAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))	AS OffBalanceSheetLocalAmount,
	|	TTProducts_1.RowID								AS RowID,
	|	TTProducts_1.FinRecordID								AS FinRecordID,
	|	TTProducts_1.BusinessTransactionSetting						AS BusinessTransactionSetting,
	|	TTProducts_1.ExpenseRecipientDivision					AS ExpenseRecipientDivision,
	|	TTProducts_1.DimensionOfExpenses									AS DimensionOfExpenses,
	|	TTProducts_1.AssetsLiabilitiesDimension							AS AssetsLiabilitiesDimension,
	|	TTProducts_1.GLAccountSettings								AS GLAccountSettings,
	|	CommitteeAnalytics.DimensionKey							AS CommitteeAnalytics,
	|	CASE
	|		WHEN CatInventoryKinds.GoodsOwner REFS Catalog.Companies
	|			THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfSettlementsWithCommittee.DimensionKey
	|	END														AS AccountingDimensionByPartners,
	|	TTProducts_1.Work_5												AS Work_5,
	|	TTProducts_1.TraceableWork								AS TraceableWork,
	|	TTProducts_1.ShopFloorStockroom									AS ShopFloorStockroom
	|INTO TTTypesOfStocks
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = &DocumentLots
	|	AND CatProductionLots.Code = TTProducts_1.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber      = TTProducts_1.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = TTProducts_1.TabularSectionName
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductKeysBySender
	|	ON ProductKeysBySender.Products = TTProducts_1.SenderItem
	|	AND ProductKeysBySender.Characteristic = TTProducts_1.SenderCharacteristics
	|	AND ProductKeysBySender.Series = TTProducts_1.SenderBatch
	|	AND ProductKeysBySender.StorageLocation = TTProducts_1.SenderStorageLocation
	|	AND ProductKeysBySender.Purpose = TTProducts_1.SenderDestination
	|	AND ProductKeysBySender.ProductCostElement = TTProducts_1.SenderOfProductCostingElements
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductKeysBySenderWithoutDestination
	|	ON ProductKeysBySenderWithoutDestination.Products = ProductKeysBySender.Products
	|	AND ProductKeysBySenderWithoutDestination.Characteristic = ProductKeysBySender.Characteristic
	|	AND ProductKeysBySenderWithoutDestination.Series = ProductKeysBySender.Series
	|	AND ProductKeysBySenderWithoutDestination.StorageLocation = ProductKeysBySender.StorageLocation
	|	AND ProductKeysBySenderWithoutDestination.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|	AND ProductKeysBySenderWithoutDestination.ProductCostElement = ProductKeysBySender.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ItemKeysByRecipient
	|	ON ItemKeysByRecipient.Products = TTProducts_1.RecipientProducts
	|	AND ItemKeysByRecipient.Characteristic = TTProducts_1.RecipientCharacteristics
	|	AND ItemKeysByRecipient.Series = TTProducts_1.RecipientBatch
	|	AND ItemKeysByRecipient.StorageLocation = TTProducts_1.RecipientStorageLocation
	|	AND ItemKeysByRecipient.Purpose = TTProducts_1.RecipientAppointment
	|	AND ItemKeysByRecipient.ProductCostElement = TTProducts_1.RecipientProductCostingElements
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ItemKeysByRecipientWithoutAssignment
	|	ON ItemKeysByRecipientWithoutAssignment.Products = ItemKeysByRecipient.Products
	|	AND ItemKeysByRecipientWithoutAssignment.Characteristic = ItemKeysByRecipient.Characteristic
	|	AND ItemKeysByRecipientWithoutAssignment.Series = ItemKeysByRecipient.Series
	|	AND ItemKeysByRecipientWithoutAssignment.StorageLocation = ItemKeysByRecipient.StorageLocation
	|	AND ItemKeysByRecipientWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|	AND ItemKeysByRecipientWithoutAssignment.ProductCostElement = ItemKeysByRecipient.ProductCostElement
	|	
	|	LEFT JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|	ON CatInventoryKinds.Ref = TTProducts_1.InventoryOwnerAttribute
	|	
	|	LEFT JOIN TTActivitiesVAT AS TTActivitiesVAT
	|	ON CatInventoryKinds.Organization = TTActivitiesVAT.MaterialProviderCompany
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|	ON ItemKeysByRecipient.Products = CommitteeAnalytics.Products
	|	AND ItemKeysByRecipient.Characteristic = CommitteeAnalytics.Characteristic
	|	AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose
	|	AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series
	|	AND CatInventoryKinds.GoodsOwner = CommitteeAnalytics.StorageLocation
	|	AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|	AND CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfSettlementsWithCommittee
	|	ON AnalysisOfSettlementsWithCommittee.Organization = &Organization
	|	AND AnalysisOfSettlementsWithCommittee.Partner = CatInventoryKinds.GoodsOwner
	|	AND AnalysisOfSettlementsWithCommittee.Counterparty = CatInventoryKinds.Counterparty
	|	AND AnalysisOfSettlementsWithCommittee.Contract = CatInventoryKinds.Contract
	|	AND AnalysisOfSettlementsWithCommittee.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|	ON AnalysisOfIntercampaniCalculations.Organization = &Organization
	|	AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|	AND AnalysisOfIntercampaniCalculations.Counterparty = CatInventoryKinds.Counterparty
	|	AND AnalysisOfIntercampaniCalculations.Contract = CatInventoryKinds.Contract
	|	AND AnalysisOfIntercampaniCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date													AS Period,
	|	VALUE(AccumulationRecordType.Receipt)					AS RecordType,
	|	&AdjustmentPeriod_									AS VariancePeriod,
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.ExpenseRecipientDivision			AS Department,
	|	TTTypesOfStocks.ExpenseItem							AS ExpenseItem,
	|	TTTypesOfStocks.DimensionOfExpenses							AS DimensionOfExpenses,
	|	&LineOfBusiness								AS LineOfBusiness,
	|	UNDEFINED											AS VATActivityType,
	|	TTTypesOfStocks.Sum										AS AmountIncludingVAT,
	|	TTTypesOfStocks.Sum										AS AmountExcludingVAT,
	|	TTTypesOfStocks.SumMan									AS AmountExcludingVATMan,
	|	TTTypesOfStocks.SumCompl									AS AmountIncludingVATCompl,
	|	TTTypesOfStocks.SumCompl									AS AmountExcludingVATCompl,
	|	0														AS PermanentDifference,
	|	0														AS CostTD,
	|	CASE 
	|		WHEN TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 
	|			THEN VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost) 
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) 
	|	END AS BusinessOperation,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS ItemsLocationAttributes,
	|	
	|	TTTypesOfStocks.FinRecordID				AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|WHERE
	|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	AND TTTypesOfStocks.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND NOT TTTypesOfStocks.Sum = 0
	|	AND (&ProductCostingByPlannedCost
	|		OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
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

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTTypesOfStocks.Organization AS Organization,
	|	TTTypesOfStocks.ExpenseRecipientDivision AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	TTTypesOfStocks.ExpenseItem AS ExpenseItem,
	|	TTTypesOfStocks.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTTypesOfStocks.LotVendorAttributes AS LotVendorAttributes,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	TTTypesOfStocks.VATActivityType AS VATActivityType,
	|
	|	TTTypesOfStocks.Sum AS Cost,
	|	TTTypesOfStocks.Sum AS CostExcludingVAT,
	|	TTTypesOfStocks.SumCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	TTTypesOfStocks.RowID AS RowID,
	|	TTTypesOfStocks.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|WHERE
	|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	AND TTTypesOfStocks.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND NOT TTTypesOfStocks.Sum = 0
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction


#Region DocumentCorrection

Function QueryTextTableLaborCostsWithCorrection(Query, QueryTexts) Export
	
	RegisterName = "LaborCostsWithCorrection";
	
	QueryText =
	"SELECT
	|	CatProductionLots.Ref      AS ProductionLot,
	|	TableLaborCosts.Ref        AS ReferenceOrder,
	|	TableLaborCosts.WorkKind      AS WorkKind,
	|	TableLaborCosts.Performer   AS Performer,
	|	TableLaborCosts.Department AS Department,
	|	TableLaborCosts.RowCode     AS ReferenceRowCode,
	|	TableLaborCosts.Count    AS Count,
	|	FALSE                              AS ReversingEntry
	|INTO LaborCostsWithCorrection
	|FROM
	|	Document.BackflushProduction.LaborCosts AS TableLaborCosts
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = &DocumentLots
	|	AND CatProductionLots.Code       = TableLaborCosts.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	TableLaborCosts.Ref = &Ref
	|	AND &ReferenceOrderForLaborCosts
	|
	|UNION ALL
	|
	|SELECT
	|	CatProductionLots.Ref      AS ProductionLot,
	|	TableLaborCosts.Ref        AS ReferenceOrder,
	|	TableLaborCosts.WorkKind      AS WorkKind,
	|	TableLaborCosts.Performer   AS Performer,
	|	TableLaborCosts.Department AS Department,
	|	TableLaborCosts.RowCode     AS ReferenceRowCode,
	|	-TableLaborCosts.Count   AS Count,
	|	TRUE                            AS ReversingEntry
	|FROM
	|	Document.BackflushProduction AS DocumentAttributes
	|	
	|	INNER JOIN Document.BackflushProduction.LaborCosts AS TableLaborCosts
	|	ON TableLaborCosts.Ref = DocumentAttributes.ReversedDocument
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = &DocumentLots
	|	AND CatProductionLots.Code       = TableLaborCosts.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	&UseDocumentCorrection
	|	AND DocumentAttributes.Ref = &Ref
	|	AND &ReferenceOrderForLaborCosts
	|	AND &Patch
	|	AND &CorrectionSavesProductionLots
	|
	|INDEX BY
	|	ProductionLot,
	|	WorkKind,
	|	Performer,
	|	Department
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLaborCostsChanges(Query, QueryTexts) Export
	
	RegisterName = "LaborCostsChanges";
	
	If Not DocumentsPosting.ThereIsQueryTable("LaborCostsWithCorrection", QueryTexts) Then
		QueryTextTableLaborCostsWithCorrection(Query, QueryTexts)
	EndIf;
	
	QueryText =
	"SELECT
	|	TableLaborCosts.ProductionLot AS ProductionLot,
	|	TableLaborCosts.WorkKind           AS WorkKind,
	|	TableLaborCosts.Performer        AS Performer,
	|	TableLaborCosts.Department      AS Department,
	|	SUM(TableLaborCosts.Count)  AS Count
	|INTO LaborCostsChanges
	|FROM
	|	LaborCostsWithCorrection AS TableLaborCosts
	|
	|GROUP BY
	|	TableLaborCosts.ProductionLot,
	|	TableLaborCosts.WorkKind,
	|	TableLaborCosts.Performer,
	|	TableLaborCosts.Department
	|
	|HAVING
	|	NOT SUM(TableLaborCosts.Count) = 0
	|
	|INDEX BY
	|	ProductionLot,
	|	WorkKind,
	|	Performer,
	|	Department
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion


Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	// receipt of products and returnable waste by the recipient
	|SELECT
	|	&Date													AS Period,
	|	VALUE(AccumulationRecordType.Receipt)					AS RecordType,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS ItemsLocationAttributes,
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)				AS CCDNumber,
	|	TTTypesOfStocks.Count								AS Count,
	|	TTTypesOfStocks.QuantityByGBRN							AS QuantityByGBRN,
	|	0														AS ToRegisterGoodsIssue,
	|	0														AS ToRegisterGoodsIssueByProductBatchID,
	|	TTTypesOfStocks.BusinessOperation						AS BusinessOperation,
	|	TTTypesOfStocks.VATActivityType						AS VATTaxation,
	|	TTTypesOfStocks.Products								AS Products,
	|	TTTypesOfStocks.Characteristic							AS Characteristic,
	|	TRUE													AS Primary
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|
	|WHERE
	|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
	|	OR TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|		AND TTTypesOfStocks.TraceableWork
	|
	|UNION ALL
	|
	// write-off of materials from storerooms
	|SELECT
	|	&Date													AS Period,
	|	VALUE(AccumulationRecordType.Expense)					AS RecordType,
	|	TTTypesOfStocks.AnalysisOfProductTrackingBySender	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TTTypesOfStocks.SaleOfAnotherCompanyInventory
	|			THEN TTTypesOfStocks.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE TTTypesOfStocks.Organization
	|	END													AS Organization,
	|	CASE
	|		WHEN TTTypesOfStocks.SaleOfAnotherCompanyInventory
	|			THEN TTTypesOfStocks.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TTTypesOfStocks.InventoryOwnerAttribute
	|	END													AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.CCDNumber									AS CCDNumber,
	|	TTTypesOfStocks.Count								AS Count,
	|	TTTypesOfStocks.QuantityByGBRN							AS QuantityByGBRN,
	|	0														AS ToRegisterGoodsIssue,
	|	0														AS ToRegisterGoodsIssueByProductBatchID,
	|	TTTypesOfStocks.BusinessOperation						AS BusinessOperation,
	|	TTTypesOfStocks.VATActivityType						AS VATTaxation,
	|	TTTypesOfStocks.Products								AS Products,
	|	TTTypesOfStocks.Characteristic							AS Characteristic,
	|	TRUE													AS Primary
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|
	|WHERE
	|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND NOT TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	AND (NOT TTTypesOfStocks.Work_5
	|		OR TTTypesOfStocks.TraceableWork)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)					AS RecordType,
	|	&Date													AS Period,
	|	TTTypesOfStocks.Warehouse										AS Warehouse,
	|	TTTypesOfStocks.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization			AS CompanyOwner,
	|	TTTypesOfStocks.AnalysisOfProductTrackingBySender	AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS SellerInventoryOwnerAttribute,
	|	TTTypesOfStocks.CCDNumber									AS CCDNumber,
	|	TTTypesOfStocks.Products								AS Products,
	|	TTTypesOfStocks.Characteristic							AS Characteristic,
	|	TTTypesOfStocks.Count								AS Count,
	|	TTTypesOfStocks.BusinessOperation						AS BusinessOperation,
	|	TTTypesOfStocks.VATActivityType						AS VATTaxation
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|WHERE
	|	TTTypesOfStocks.SaleOfAnotherCompanyInventory
	|	AND TTTypesOfStocks.DirectionOfProductionIssue =
	|		VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND NOT TTTypesOfStocks.BusinessOperation =
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	AND NOT TTTypesOfStocks.Work_5";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)

	IssueReceiptOfGoodsForOnePassGoods(Query, QueryTexts, Registers);
	IssueReceiptOfGoodsOnOneWayReturnableWaste(Query, QueryTexts, Registers);
	
EndProcedure

Procedure IssueReceiptOfGoodsForOnePassGoods(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref				AS Ref,
	|	UNDEFINED						AS OrderDocument,
	|	DataSource.Ref				AS Invoice,
	|	DataSource.Ref.Patch	AS Patch,
	|	DataSource.Ref.CorrectedDocument AS CorrectedDocument,
	|	UNDEFINED						AS Contract,
	|	UNDEFINED						AS Terms,
	|	VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) AS GoodsReceiptOption,
	|	DataSource.Ref.Date			AS Date,
	|	DataSource.Products			AS Products,
	|	DataSource.Characteristic		AS Characteristic,
	|	DataSource.Purpose			AS Purpose,
	|	FALSE AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DataSource.Series				AS Series,
	|	DataSource.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	FALSE								AS ExceedingOrder,
	|	DataSource.Recipient			AS Warehouse,
	|	DataSource.Ref.Department	AS Sender,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	DataSource.Count			AS Count,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ReceiptUnderOrders,
	|	FALSE								AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND VALUETYPE(DataSource.Recipient) = TYPE(Catalog.Warehouses)
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.BackflushProduction;
	
	AdditionalSeriesConnectionFields = New Array();
	AdditionalSeriesConnectionFields.Add("Recipient");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "BatchFinishedProducts";
	ParametersOfModularHolding.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
	
	WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1,
		ParametersOfModularHolding);

EndProcedure

Procedure IssueReceiptOfGoodsOnOneWayReturnableWaste(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref				AS Ref,
	|	UNDEFINED						AS OrderDocument,
	|	DataSource.Ref				AS Invoice,
	|	DataSource.Ref.Patch	AS Patch,
	|	DataSource.Ref.CorrectedDocument AS CorrectedDocument,
	|	UNDEFINED						AS Contract,
	|	UNDEFINED						AS Terms,
	|	VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) AS GoodsReceiptOption,
	|	DataSource.Ref.Date			AS Date,
	|	DataSource.Products			AS Products,
	|	DataSource.Characteristic		AS Characteristic,
	|	DataSource.Purpose			AS Purpose,
	|	FALSE AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DataSource.Series				AS Series,
	|	DataSource.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	FALSE								AS ExceedingOrder,
	|	DataSource.Recipient			AS Warehouse,
	|	DataSource.Ref.Department AS Sender,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	DataSource.Count			AS Count,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ReceiptUnderOrders,
	|	FALSE								AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND VALUETYPE(DataSource.Recipient) = TYPE(Catalog.Warehouses)
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.BackflushProduction;
	
	AdditionalSeriesConnectionFields = New Array();
	AdditionalSeriesConnectionFields.Add("Recipient");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "BatchSideAndIntermediateRelease";
	ParametersOfModularHolding.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
	
	WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1,
		ParametersOfModularHolding);

EndProcedure

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	// arrival of works at the calculated cost to the recipient
	"SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	CASE
	|		WHEN ManufacturedProducts.InternalSubcontracting
	|			THEN ManufacturedProducts.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END									AS Organization,
	|	ManufacturedProducts.Recipient				AS Department,
	|	ManufacturedProducts.Products			AS Products,
	|	ManufacturedProducts.Characteristic			AS Characteristic,
	|	ManufacturedProducts.Purpose				AS Purpose,
	|	ManufacturedProducts.Count				AS Count
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS ManufacturedProducts
	|WHERE
	|	ManufacturedProducts.Ref = &Ref
	|	AND ManufacturedProducts.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|	AND NOT ManufacturedProducts.Products.TracedGoods
	|
	|UNION ALL
	// arrival of works at a fixed cost by the recipient
	|SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	CASE
	|		WHEN NOT SideWorks.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN SideWorks.ProductOwner
	|		WHEN CatProductionLots.InternalSubcontracting
	|			THEN CatProductionLots.Organization
	|		WHEN TRUE
	|			THEN &Organization
	|	END									AS Organization,
	|	SideWorks.Recipient				AS Department,
	|	SideWorks.Products				AS Products,
	|	SideWorks.Characteristic			AS Characteristic,
	|	SideWorks.Purpose				AS Purpose,
	|	SideWorks.Count				AS Count
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS SideWorks
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = &DocumentLots
	|	AND CatProductionLots.Code = SideWorks.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	SideWorks.Ref = &Ref
	|	AND SideWorks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|	AND NOT SideWorks.Products.TracedGoods
	|
	|UNION ALL
	|
	// expenditure of works
	|SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Expense)	AS RecordType,
	|	&Organization							AS Organization,
	|	ConsumptionOfWorks.Department				AS Department,
	|	ConsumptionOfWorks.Products				AS Products,
	|	ConsumptionOfWorks.Characteristic				AS Characteristic,
	|	ConsumptionOfWorks.Purpose					AS Purpose,
	|	ConsumptionOfWorks.Count					AS Count
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS ConsumptionOfWorks
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON ConsumptionOfWorks.Products = CatProducts.Ref
	|		AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT CatProducts.TracedGoods
	|WHERE
	|	ConsumptionOfWorks.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableProductsRelease(Query, QueryTexts, Registers)
	
	RegisterName = "ProductsRelease";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN TabularSection.InternalSubcontracting
	|			THEN TabularSection.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN &Organization
	|	END										AS Organization,
	|	&Department								AS Department,
	|	&Date										AS Period,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			AND VALUETYPE(TabularSection.Recipient) = TYPE(Catalog.Warehouses)
	|			AND NOT CAST(TabularSection.Recipient AS Catalog.Warehouses).ShopFloorStockroom
	|			THEN SenderSAnalyticsKeys.DimensionKey
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TabularSection.ItemsLocationAttributes
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND VALUETYPE(TabularSection.Recipient) = TYPE(Catalog.Warehouses)
	|			AND NOT  CAST(TabularSection.Recipient AS Catalog.Warehouses).ShopFloorStockroom
	|			THEN SenderAnalyticsKeysWithoutDestination.DimensionKey
	|		ELSE RecipientAnalyticsKeysWithoutAssignment.DimensionKey
	|	END										AS ItemsLocationAttributes,
	|	TabularSection.Count					AS Count,
	|	CASE
	|		WHEN TabularSection.Recipient REFS ChartOfCharacteristicTypes.ExpenseItems
	|				OR TabularSection.Recipient REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN TabularSection.Recipient
	|		ELSE UNDEFINED
	|	END										AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS TabularSection
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS RecipientAnalyticsKeysWithoutAssignment
	|		ON TabularSection.ItemsLocationAttributes.Products = RecipientAnalyticsKeysWithoutAssignment.Products
	|		AND TabularSection.ItemsLocationAttributes.Characteristic = RecipientAnalyticsKeysWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = RecipientAnalyticsKeysWithoutAssignment.Purpose
	|		AND TabularSection.ItemsLocationAttributes.Series = RecipientAnalyticsKeysWithoutAssignment.Series
	|		AND TabularSection.ItemsLocationAttributes.StorageLocation = RecipientAnalyticsKeysWithoutAssignment.StorageLocation
	|		AND TabularSection.ItemsLocationAttributes.ProductCostElement = RecipientAnalyticsKeysWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS SenderSAnalyticsKeys
	|		ON TabularSection.ItemsLocationAttributes.Products = SenderSAnalyticsKeys.Products
	|		AND TabularSection.ItemsLocationAttributes.Characteristic = SenderSAnalyticsKeys.Characteristic
	|		AND TabularSection.ItemsLocationAttributes.Series = SenderSAnalyticsKeys.Series
	|		AND &Department = SenderSAnalyticsKeys.StorageLocation
	|		AND TabularSection.ItemsLocationAttributes.Purpose = SenderSAnalyticsKeys.Purpose
	|		AND TabularSection.ItemsLocationAttributes.ProductCostElement = SenderSAnalyticsKeys.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS SenderAnalyticsKeysWithoutDestination
	|		ON SenderSAnalyticsKeys.Products = SenderAnalyticsKeysWithoutDestination.Products
	|		AND SenderSAnalyticsKeys.Characteristic = SenderAnalyticsKeysWithoutDestination.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = SenderAnalyticsKeysWithoutDestination.Purpose
	|		AND SenderSAnalyticsKeys.Series = SenderAnalyticsKeysWithoutDestination.Series
	|		AND SenderSAnalyticsKeys.StorageLocation = SenderAnalyticsKeysWithoutDestination.StorageLocation
	|		AND SenderSAnalyticsKeys.ProductCostElement = SenderAnalyticsKeysWithoutDestination.ProductCostElement
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN NOT TabularSection.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN TabularSection.ProductOwner
	|		WHEN CatProductionLots.InternalSubcontracting
	|			THEN CatProductionLots.Organization
	|		WHEN TRUE
	|			THEN &Organization
	|	END										AS Organization,
	|	&Department								AS Department,
	|	&Date										AS Period,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			AND VALUETYPE(TabularSection.Recipient) = TYPE(Catalog.Warehouses)
	|			AND NOT CAST(TabularSection.Recipient AS Catalog.Warehouses).ShopFloorStockroom
	|			THEN SenderSAnalyticsKeys.DimensionKey
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TabularSection.ItemsLocationAttributes
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND VALUETYPE(TabularSection.Recipient) = TYPE(Catalog.Warehouses)
	|			AND NOT CAST(TabularSection.Recipient AS Catalog.Warehouses).ShopFloorStockroom
	|			THEN SenderAnalyticsKeysWithoutDestination.DimensionKey
	|		ELSE RecipientAnalyticsKeysWithoutAssignment.DimensionKey
	|	END										AS ItemsLocationAttributes,
	|	TabularSection.Count					AS Count,
	|	CASE
	|		WHEN TabularSection.Recipient REFS ChartOfCharacteristicTypes.ExpenseItems
	|				OR TabularSection.Recipient REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN TabularSection.Recipient
	|		ELSE UNDEFINED
	|	END										AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses			AS DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension		AS AssetsLiabilitiesDimension
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS TabularSection
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS RecipientAnalyticsKeysWithoutAssignment
	|		ON TabularSection.ItemsLocationAttributes.Products = RecipientAnalyticsKeysWithoutAssignment.Products
	|		AND TabularSection.ItemsLocationAttributes.Characteristic = RecipientAnalyticsKeysWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = RecipientAnalyticsKeysWithoutAssignment.Purpose
	|		AND TabularSection.ItemsLocationAttributes.Series = RecipientAnalyticsKeysWithoutAssignment.Series
	|		AND TabularSection.ItemsLocationAttributes.StorageLocation = RecipientAnalyticsKeysWithoutAssignment.StorageLocation
	|		AND TabularSection.ItemsLocationAttributes.ProductCostElement = RecipientAnalyticsKeysWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS SenderSAnalyticsKeys
	|		ON TabularSection.ItemsLocationAttributes.Products = SenderSAnalyticsKeys.Products
	|		AND TabularSection.ItemsLocationAttributes.Characteristic = SenderSAnalyticsKeys.Characteristic
	|		AND TabularSection.ItemsLocationAttributes.Series = SenderSAnalyticsKeys.Series
	|		AND &Department = SenderSAnalyticsKeys.StorageLocation
	|		AND TabularSection.ItemsLocationAttributes.Purpose = SenderSAnalyticsKeys.Purpose
	|		AND TabularSection.ItemsLocationAttributes.ProductCostElement = SenderSAnalyticsKeys.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS SenderAnalyticsKeysWithoutDestination
	|		ON SenderSAnalyticsKeys.Products = SenderAnalyticsKeysWithoutDestination.Products
	|		AND SenderSAnalyticsKeys.Characteristic = SenderAnalyticsKeysWithoutDestination.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = SenderAnalyticsKeysWithoutDestination.Purpose
	|		AND SenderSAnalyticsKeys.Series = SenderAnalyticsKeysWithoutDestination.Series
	|		AND TabularSection.ItemsLocationAttributes.StorageLocation = SenderAnalyticsKeysWithoutDestination.StorageLocation
	|		AND SenderSAnalyticsKeys.ProductCostElement = SenderAnalyticsKeysWithoutDestination.ProductCostElement
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = &DocumentLots
	|		AND CatProductionLots.Code = TabularSection.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)

	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	// Shipment of materials from the workshop storeroom
	|SELECT
	|	&Date																	AS Period,
	|	GoodsTable.Products												AS Products,
	|	GoodsTable.Characteristic											AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END																	AS Purpose,
	|	GoodsTable.Series														AS Series,
	|	GoodsTable.Count												AS Count,
	|	GoodsTable.Warehouse														AS Sender,
	|	CatWarehouses.Department													AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ConsumptionDuringProduction)	AS WarehouseOperation,
	|	&Ref																	AS Document,
	|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue
	|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue			AS ThisIsWarehouseRecord
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	// production of products in the pantry
	|SELECT
	|	&Date																	AS Period,
	|	GoodsTable.Products												AS Products,
	|	GoodsTable.Characteristic											AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END																	AS Purpose,
	|	GoodsTable.Series														AS Series,
	|	GoodsTable.Count												AS Count,
	|	GoodsTable.Recipient												AS Sender,
	|	GoodsTable.Recipient												AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts)	AS WarehouseOperation,
	|	&Ref																	AS Document,
	|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt			AS ThisIsWarehouseRecord
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	// production of products in the pantry
	|SELECT
	|	&Date																	AS Period,
	|	GoodsTable.Products												AS Products,
	|	GoodsTable.Characteristic											AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END																	AS Purpose,
	|	GoodsTable.Series														AS Series,
	|	GoodsTable.Count												AS Count,
	|	GoodsTable.Recipient												AS Sender,
	|	GoodsTable.Recipient												AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts)	AS WarehouseOperation,
	|	&Ref																	AS Document,
	|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt			AS ThisIsWarehouseRecord
	|FROM
	|	Document.BackflushProduction.BatchFinishedProducts AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	// production of returnable waste to the pantry
	|SELECT
	|	&Date															AS Period,
	|	GoodsTable.Products										AS Products,
	|	GoodsTable.Characteristic									AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END															AS Purpose,
	|	GoodsTable.Series												AS Series,
	|	GoodsTable.Count										AS Count,
	|	GoodsTable.Recipient										AS Sender,
	|	GoodsTable.Recipient										AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts)	AS WarehouseOperation,
	|	&Ref															AS Document,
	|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt	AS ThisIsWarehouseRecord
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	// production of returnable waste to the pantry
	|SELECT
	|	&Date															AS Period,
	|	GoodsTable.Products										AS Products,
	|	GoodsTable.Characteristic									AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END															AS Purpose,
	|	GoodsTable.Series												AS Series,
	|	GoodsTable.Count										AS Count,
	|	GoodsTable.Recipient										AS Sender,
	|	GoodsTable.Recipient										AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts)	AS WarehouseOperation,
	|	&Ref															AS Document,
	|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt	AS ThisIsWarehouseRecord
	|FROM
	|	Document.BackflushProduction.BatchSideAndIntermediateRelease AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = GoodsTable.Recipient
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT DISTINCT
	|	ManufacturedProducts.LineNumber					AS LineNumber,
	|	&Date										AS DateOfReceipt,
	|	DimensionKeys.Products					AS Products,
	|	DimensionKeys.Characteristic				AS Characteristic,
	|	DimensionKeys.Series						AS Series,
	|	DimensionKeys.Purpose					AS Purpose,
	|	ManufacturedProducts.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesFinishedProducts AS ManufacturedProducts
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON ManufacturedProducts.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON ManufacturedProducts.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND DimensionKeys.Products = UninvoicedReceipts.Products
	|			AND DimensionKeys.Characteristic = UninvoicedReceipts.Characteristic
	|			AND DimensionKeys.Series = UninvoicedReceipts.Series
	|			AND DimensionKeys.Purpose = UninvoicedReceipts.Purpose
	|			AND (UninvoicedReceipts.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef))
	|WHERE
	|	ManufacturedProducts.Ref = &Ref
	|	AND (UninvoicedReceipts.InventoryOwnerAttribute IS NULL
	|			OR UninvoicedReceipts.DateOfReceipt < &Date)
	|	AND ManufacturedProducts.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	SideAndIntermediateRelease.LineNumber					AS LineNumber,
	|	&Date										AS DateOfReceipt,
	|	DimensionKeys.Products					AS Products,
	|	DimensionKeys.Characteristic				AS Characteristic,
	|	DimensionKeys.Series						AS Series,
	|	DimensionKeys.Purpose					AS Purpose,
	|	SideAndIntermediateRelease.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesSideProducts AS SideAndIntermediateRelease
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON SideAndIntermediateRelease.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON SideAndIntermediateRelease.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND DimensionKeys.Products = UninvoicedReceipts.Products
	|			AND DimensionKeys.Characteristic = UninvoicedReceipts.Characteristic
	|			AND DimensionKeys.Series = UninvoicedReceipts.Series
	|			AND DimensionKeys.Purpose = UninvoicedReceipts.Purpose
	|			AND (UninvoicedReceipts.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef))
	|WHERE
	|	SideAndIntermediateRelease.Ref = &Ref
	|	AND (UninvoicedReceipts.InventoryOwnerAttribute IS NULL
	|			OR UninvoicedReceipts.DateOfReceipt < &Date)
	|	AND SideAndIntermediateRelease.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)";
	
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
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

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	TTTypesOfStocks.Organization				AS Organization,
	|	TTTypesOfStocks.Recipient 				AS Department,
	|	UNDEFINED 							AS LineOfBusiness,
	|	TTTypesOfStocks.ExpenseItem			AS AssetRef,
	|	CASE
	|		WHEN TTTypesOfStocks.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TTTypesOfStocks.AssetsLiabilitiesDimension
	|	END 									AS Dimension,
	|	TTTypesOfStocks.SumMan					AS Sum
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|WHERE
	|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	AND TTTypesOfStocks.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND NOT TTTypesOfStocks.Sum = 0
	|";
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date AS Period,
	|	TTTypesOfStocks.Organization AS Organization,
	|	TTTypesOfStocks.Recipient AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	TTTypesOfStocks.ExpenseItem AS AssetRef,
	|	TTTypesOfStocks.AssetsLiabilitiesDimension AS Dimension,
	|	TTTypesOfStocks.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTTypesOfStocks.SumCompl AS SumCompl,
	|	TTTypesOfStocks.SumMan AS SumMan,
	|	TTTypesOfStocks.SumMan AS AmountIncludingVAT,
	|	TTTypesOfStocks.SumMan AS AmountExcludingVAT,
	|
	|	TTTypesOfStocks.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)	AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|WHERE
	|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	AND TTTypesOfStocks.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND NOT TTTypesOfStocks.Sum = 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	&Date																				AS Period,
		|	CASE
		|		WHEN TTTypesOfStocks.ExpenseItem.CostAllocationOptionLocal =
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|			THEN CASE
		|					WHEN TTTypesOfStocks.ExpenseItem.VATAssetTaxClass IN
		|							(VALUE(Enum.AssetKinds.FA),
		|							VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
		|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
		|					WHEN TTTypesOfStocks.ExpenseItem.VATAssetTaxClass = VALUE(Enum.AssetKinds.IA)
		|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
		|				END
		|		ELSE VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
		|	END																				AS BusinessOperation,
		|	TTTypesOfStocks.Organization															AS Organization,
		|	TTTypesOfStocks.ExpenseRecipientDivision										AS Department,
		|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient								AS ItemsLocationAttributes,
		|	&Department																		AS Warehouse,
		|	TTTypesOfStocks.InventoryOwnerAttribute															AS InventoryOwnerAttribute,
		|	TTTypesOfStocks.InventoryOwnerAttribute.InventoryType													AS InventoryType,
		|	TTTypesOfStocks.ExpenseItem														AS IncomeAndExpenseItem,
		|	TTTypesOfStocks.DimensionOfExpenses														AS DimensionOfExpenses,
		|	TTTypesOfStocks.AssetsLiabilitiesDimension												AS AssetsLiabilitiesDimension,
		|	TTTypesOfStocks.Count															AS Count,
		|	TTTypesOfStocks.SumMan																AS Cost,
		|	TTTypesOfStocks.SumMan																AS CostExcludingVAT,
		|	TTTypesOfStocks.SumCompl																AS LocalCost,
		|	CASE
		|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
		|			THEN TTTypesOfStocks.InventoryOwnerAttribute
		|		ELSE TTTypesOfStocks.Products
		|	END																				AS SourceOfProductFinancialAccountingGroup
		|FROM
		|	TTTypesOfStocks AS TTTypesOfStocks
		|WHERE
		|	TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date                                AS Period,
	|	CASE
	|		WHEN InventoryKinds.DirectionOfProductionIssue IN
	|				(VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|				VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			AND NOT InventoryKinds.ShopFloorStockroom
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE InventoryKinds.BusinessOperation
	|	END                                AS BusinessOperation,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE InventoryKinds.Organization
	|	END                                AS Organization,
	|	&Department                       AS Department,
	|	InventoryKinds.AnalysisOfProductTrackingBySender.Purpose.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.AnalysisOfProductTrackingBySender
	|		ELSE InventoryKinds.AnalysisOfProductTrackingBySenderWithoutDestination
	|	END                                AS ItemsLocationAttributes,
	|	InventoryKinds.Warehouse                    AS Warehouse,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType
	|		ELSE InventoryKinds.InventoryOwnerAttribute.InventoryType
	|	END                                AS InventoryType,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE InventoryKinds.InventoryOwnerAttribute
	|	END                                AS InventoryOwnerAttribute,
	|	InventoryKinds.AnalysisOfProductAccountingByRecipient.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.AnalysisOfProductAccountingByRecipient
	|		ELSE InventoryKinds.AnalysisOfProductAccountingByRecipientWithoutAssignment
	|	END                                AS CorItemsLocationAttributes,
	|	InventoryKinds.Recipient               AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	CASE
	|		WHEN InventoryKinds.CorInventoryOwnerAttribute = UNDEFINED
	|			THEN InventoryKinds.InventoryOwnerAttribute.InventoryType
	|		ELSE InventoryKinds.CorInventoryOwnerAttribute.InventoryType
	|	END                                AS CorInventoryType,
	|	CASE
	|		WHEN InventoryKinds.CorInventoryOwnerAttribute = UNDEFINED
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.CorInventoryOwnerAttribute
	|	END                                AS CorInventoryOwnerAttribute,
	|
	|	InventoryKinds.Count               AS Count,
	|	InventoryKinds.Count               AS CorQuantity,
	|
	|	0                                    AS Cost,
	|	0                                    AS CostExcludingVAT,
	|	0                                    AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.Products
	|	END                                AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			AND InventoryKinds.CorInventoryOwnerAttribute = UNDEFINED
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.CorInventoryOwnerAttribute
	|		ELSE InventoryKinds.Products
	|	END                                AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED                         AS DocumentRegisterRecords,
	|	InventoryKinds.Organization              AS CorCompany
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|WHERE
	|	NOT InventoryKinds.AnalysisOfProductTrackingBySender =
	|			UNDEFINED
	|	AND NOT InventoryKinds.AnalysisOfProductTrackingBySender =
	|			InventoryKinds.AnalysisOfProductAccountingByRecipient
	|	AND NOT InventoryKinds.DirectionOfProductionIssue =
	|			VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers)
	
	RegisterName = "LaborCostsToRegister";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("LaborCostsChanges", QueryTexts) Then
		QueryTextTableLaborCostsChanges(Query, QueryTexts)
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Date                                     AS Period,
	|	&Organization                              AS Organization,
	|	TableLaborCosts.ProductionLot    AS ProductionLot,
	|	TableLaborCosts.ReferenceOrder          AS ReferenceOrder,
	|	TableLaborCosts.WorkKind              AS WorkKind,
	|	TableLaborCosts.Performer           AS Performer,
	|	TableLaborCosts.Department         AS Department,
	|	TableLaborCosts.ReferenceRowCode AS ReferenceRowCode,
	|	TableLaborCosts.Count            AS Count,
	|	TableLaborCosts.ReversingEntry                AS ReversingEntry
	|FROM
	|	LaborCostsWithCorrection AS TableLaborCosts
	|WHERE
	|	TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			LaborCostsChanges AS LaborCostsChanges
	|		WHERE
	|			LaborCostsChanges.ProductionLot = TableLaborCosts.ProductionLot
	|			AND LaborCostsChanges.WorkKind         = TableLaborCosts.WorkKind
	|			AND LaborCostsChanges.Performer      = TableLaborCosts.Performer
	|			AND LaborCostsChanges.Department    = TableLaborCosts.Department
	|		)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	SetRequestParameterInventoryOwnerAttributeByDefault(Query);
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfInventoryGiverByDefault", QueryTexts) Then
		QueryTextTTTypesOfInventoryGiverByDefault(Query, QueryTexts);
	EndIf;
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Date                                     AS Period,
	|	InventoryKinds.Organization                   AS Organization,
	|	InventoryKinds.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	InventoryKinds.CommitteeAnalytics            AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute.Currency             AS Currency,
	|	InventoryKinds.CCDNumber                      AS CCDNumber,
	|	0                                         AS Count,
	|	0                                         AS RevenueAmount,
	|	0                                         AS RevenueAmountExclVATLocal,
	|	0                                         AS RevenueAmountMan,
	|	InventoryKinds.Count                    AS QuantityConsumed,
	|	0                                         AS QuantityToRegister,
	|	0                                         AS QuantityForRegistrationByProductBatchID,
	|	0                                         AS RevenueAmountToRegister,
	|	InventoryKinds.Count                    AS QuantityConsumedForIncoiceRegistration,
	|	InventoryKinds.QuantityByGBRN              AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	Dimension.Products                    AS Products,
	|	Dimension.Characteristic                  AS Characteristic,
	|	InventoryKinds.BusinessOperation         AS BusinessOperation,
	|	CASE
	|		WHEN InventoryKinds.Organization = InventoryKinds.MaterialProviderCompany
	|			THEN ISNULL(TTTypesOfInventoryGiverByDefault.InventoryOwnerAttribute, VALUE(Catalog.InventoryKinds.EmptyRef))
	|		WHEN TRUE
	|			THEN &DefaultStockView
	|	END                                     AS CorInventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType            AS VATTaxation,
	|	InventoryKinds.FinRecordID        AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff) AS BusinessTransactionSetting,
	|	InventoryKinds.RowID           AS RowID
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|	
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON InventoryKinds.AnalysisOfProductAccountingByRecipient = Dimension.Ref
	|	
	|	LEFT JOIN TTTypesOfInventoryGiverByDefault AS TTTypesOfInventoryGiverByDefault
	|	ON TTTypesOfInventoryGiverByDefault.Ref = InventoryKinds.Ref
	|	AND TTTypesOfInventoryGiverByDefault.MaterialProviderCompany = InventoryKinds.MaterialProviderCompany
	|WHERE
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|ORDER BY
	|	Period";
	
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
	|	&Ref									AS Ref,
	|	UNDEFINED							AS RecordSeparator,
	|	&Date									AS IBDocumentDate,
	|	&Number									AS IBDocumentNumber,
	|	&MetadataIdentifier				AS RefType,
	|	DocumentData.Organization				AS Organization,
	|	DocumentData.BusinessOperation	AS BusinessOperation,
	|	&LineOfBusiness				AS LineOfBusiness,
	|	DocumentData.Department			AS Department,
	|	&EmployeeResponsible							AS EmployeeResponsible,
	|	&Author									AS Author,
	|	CAST(&Comment AS STRING(100))	AS Comment,
	|	&Currency									AS Currency,
	|	0										AS Sum,
	|	&Posted								AS Posted,
	|	&DeletionMark						AS DeletionMark,
	|	DocumentData.AdditionalRecord	AS AdditionalRecord,
	|	""""									AS More,
	|	&Date									AS SourceDocumentDate,
	|	&NumberForPrinting							AS SourceDocumentNumber,
	|	DocumentData.Department			AS StorageLocation,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Date									AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref				AS Ref,
	|	SourceData.Ref.Date			AS Period,
	|	UNDEFINED						AS OrderDocument,
	|	SourceData.Ref				AS Invoice,
	|	SourceData.Ref.Patch	AS Patch,
	|	SourceData.Ref.CorrectedDocument	AS CorrectedDocument,
	|	SourceData.Department		AS Recipient,
	|	SourceData.Warehouse				AS Warehouse,
	|	SourceData.Products		AS Products,
	|	SourceData.Characteristic		AS Characteristic,
	|	SourceData.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series				AS Series,
	|	SourceData.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	SourceData.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS SourceData
	|
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND NOT SourceData.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref				AS Ref,
	|	SourceData.Ref.Date			AS Period,
	|	UNDEFINED						AS OrderDocument,
	|	SourceData.Ref				AS Invoice,
	|	SourceData.Ref.Patch	AS Patch,
	|	SourceData.Ref.CorrectedDocument	AS CorrectedDocument,
	|	SourceData.Department		AS Recipient,
	|	SourceData.Warehouse				AS Warehouse,
	|	SourceData.Products		AS Products,
	|	SourceData.Characteristic		AS Characteristic,
	|	SourceData.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series				AS Series,
	|	SourceData.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	SourceData.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS SourceData
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND NOT SourceData.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref				AS Ref,
	|	UNDEFINED						AS OrderDocument,
	|	DataSource.Ref				AS Invoice,
	|	DataSource.Ref.Patch	AS Patch,
	|	DataSource.Ref.CorrectedDocument AS CorrectedDocument,
	|	UNDEFINED						AS Contract,
	|	UNDEFINED						AS Terms,
	|	VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	DataSource.Products			AS Products,
	|	DataSource.Characteristic		AS Characteristic,
	|	DataSource.Purpose			AS Purpose,
	|	FALSE AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DataSource.Series				AS Series,
	|	DataSource.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	FALSE								AS ExceedingOrder,
	|	DataSource.Recipient			AS Warehouse,
	|	DataSource.Ref.Department	AS Sender,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	DataSource.Count			AS Count,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ReceiptUnderOrders
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND VALUETYPE(DataSource.Recipient) = TYPE(Catalog.Warehouses)
	|
	|UNION ALL
	|
	|SELECT
	|	DataSource.Ref				AS Ref,
	|	UNDEFINED						AS OrderDocument,
	|	DataSource.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	UNDEFINED						AS Contract,
	|	UNDEFINED						AS Terms,
	|	VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	DataSource.Products			AS Products,
	|	DataSource.Characteristic		AS Characteristic,
	|	DataSource.Purpose			AS Purpose,
	|	FALSE AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DataSource.Series				AS Series,
	|	DataSource.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	FALSE								AS ExceedingOrder,
	|	DataSource.Recipient			AS Warehouse,
	|	DataSource.Ref.Department		AS Sender,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	DataSource.Count			AS Count,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ReceiptUnderOrders
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND VALUETYPE(DataSource.Recipient) = TYPE(Catalog.Warehouses)
	|";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.BackflushProduction.MaterialsAndWorks AS TabPart";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.BackflushProduction.ManufacturedProducts AS TabPart
		|WHERE
		|	TabPart.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	AND (NOT TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	OR TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
		|	OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE)
		|	OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND TabPart.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.BackflushProduction.ManufacturedProducts AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|	AND TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient     AS Warehouse,
		|	
		|	CASE WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE THEN
		|				VALUE(Catalog.Assignments.EmptyRef)
		|			ELSE
		|				TabPart.Purpose
		|		END AS Purpose,
		|	
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	
		|	CASE
		|		WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.BackflushProduction.EmptyRef)
		|			THEN TabPart.Ref
		|		ELSE TabPart.Ref.CorrectedDocument
		|	END AS OrderDocument,
		|	
		|	CASE WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
		|				TabPart.Ref.DateOfReceipt
		|			ELSE
		|				TabPart.Ref.Date
		|		END AS DateOfReceipt,
		|	
		|	TRUE                  AS AvailableForConsumption,
		|	FALSE                    AS OnSchedule,
		|	UNDEFINED            AS OrderInSchedule,
		|	0                       AS QuantityInGraph
		|FROM
		|	Document.BackflushProduction.ManufacturedProducts AS TabPart
		|WHERE
		|	TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.BackflushProduction.SideAndIntermediateRelease AS TabPart
		|WHERE
		|	TabPart.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	AND (NOT TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	OR TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
		|	OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE)
		|	OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND TabPart.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.BackflushProduction.SideAndIntermediateRelease AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|	AND TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient     AS Warehouse,
		|	
		|	CASE WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE THEN
		|				VALUE(Catalog.Assignments.EmptyRef)
		|			ELSE
		|				TabPart.Purpose
		|		END AS Purpose,
		|	
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	
		|	CASE
		|		WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.BackflushProduction.EmptyRef)
		|			THEN TabPart.Ref
		|		ELSE TabPart.Ref.CorrectedDocument
		|	END AS OrderDocument,
		|	
		|	CASE WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
		|				TabPart.Ref.DateOfReceipt
		|			ELSE
		|				TabPart.Ref.Date
		|		END AS DateOfReceipt,
		|	
		|	TRUE                  AS AvailableForConsumption,
		|	FALSE                    AS OnSchedule,
		|	UNDEFINED            AS OrderInSchedule,
		|	0                       AS QuantityInGraph
		|FROM
		|	Document.BackflushProduction.SideAndIntermediateRelease AS TabPart
		|WHERE
		|	TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
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
	
	#Region InternalReceipt_ReceiptOfManufacturedProducts
	
	// There are being formed Registered Records for the release of products to the warehouse, to the workshop storeroom and the release of work to the division.
	// No Register Records are generated for the issue with write-off for expenses - such Register Records are generated 
	// in the request Internal Access_Prikhodvypublennoyproduction Division.
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref				AS Lot,
	|	TTTypesOfStocks.LotVendorAttributes	AS LotVendorAttributes,
	|	0									AS RowCode,
	|
	// Corresponding fields
	|	TTTypesOfStocks.LotVendorAttributes						AS LotVendorAttributesCorr,
	|	CASE
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END													AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END													AS CorInventoryOwnerAttribute,
	|	UNDEFINED											AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.EmployeeResponsible			AS Manager,
	|	TTTypesOfStocks.FinancialAccountingDimension AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS Cost,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumCompl
	|		ELSE 0 
	|	END AS LocalCost,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS CostMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	TTTypesOfStocks.OffBalanceSheetManAmount	AS OffBalanceCost,
	|	TTTypesOfStocks.OffBalanceSheetLocalAmount	AS OffBalanceCostLocal,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TTTypesOfStocks.RowID		AS RowID,
	// 2.4 For products from toll-free raw materials during processing, the ID of the fin record is not filled
	// in to separate the lines with balance and off-balance amounts when transferring products from production.
	|	(CASE
	|		WHEN TRUE
	|			THEN TTTypesOfStocks.FinRecordID END) AS FinRecordID,
	|
	// When accounting according to the standard cost of a household Operation and setting up household Operations must match 
	// the request #Write-off area of other parties_The transfer of the released productionsclad
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		WHEN TTTypesOfStocks.ShopFloorStockroom OR TTTypesOfStocks.Work_5 
	|			THEN TTTypesOfStocks.BusinessOperation
	|		WHEN TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost)
	|		ELSE VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		  AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)
	|		WHEN TTTypesOfStocks.ShopFloorStockroom OR TTTypesOfStocks.Work_5
	|			THEN TTTypesOfStocks.BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.BackflushProduction AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TTTypesOfStocks.DirectionOfProductionIssue IN
	|		(VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);

	#EndRegion
	
	#Region InternalReceipt_ReceiptOfManufacturedProductsToDivision
	
	// There are Registered Records for the release of products and work on the Accounting section "Output" when reflecting the output at the planned cost,
	// including in case of release with write-off for expenses.
	// When the issue is reflected at the actual cost, RegisteredRecords are formed:
	// - for the release of products to the division (if you specify a wholesale warehouse)
	// - for the release of products and work on sub-settlement at the time of release with write-off for expenses 
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	(CASE
	|		WHEN TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|		 OR TTTypesOfStocks.ShopFloorStockroom
	|			THEN TTTypesOfStocks.AnalysisOfProductAccountingByRecipient
	|		ELSE TTTypesOfStocks.AnalysisOfProductTrackingBySender END) AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref				AS Lot,
	|	TTTypesOfStocks.LotVendorAttributes	AS LotVendorAttributes,
	|	0									AS RowCode,
	|
	// Corresponding fields
	|	TTTypesOfStocks.LotVendorAttributes	AS LotVendorAttributesCorr,
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.EmployeeResponsible			AS Manager,
	|	TTTypesOfStocks.FinancialAccountingDimension AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|	TTTypesOfStocks.SumMan		AS Cost,
	|	TTTypesOfStocks.SumMan		AS CostExcludingVAT,
	|	TTTypesOfStocks.SumCompl		AS LocalCost,
	|	TTTypesOfStocks.SumMan		AS CostMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS CorGrossInitialCostENT,
	|
	// Additional field
	|	CASE WHEN &ProductCostingByPlannedCost
	|	 AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED
	|	END AS AccountingSection,
	|
	// Other fields
	|	TTTypesOfStocks.RowID					AS RowID,
	|	TTTypesOfStocks.FinRecordID AS FinRecordID,
	|	TTTypesOfStocks.BusinessOperation					AS BusinessOperation,
	|	TTTypesOfStocks.BusinessTransactionSetting		AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.Supplement)	AS EntryType
	|
	|FROM
	|	Document.BackflushProduction AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (
	// There are Registered Records for the production of products and works with a write-off for expenses.
	|		TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	// There are Registered Records for the release of products to the wholesale warehouse.
	|		OR
	|		TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
	|		AND NOT TTTypesOfStocks.ShopFloorStockroom
	// When the output is reflected at the planned cost, Registered Records are additionally generated for the release of products to the workshop pantry and
	// for the release of works, except for the release at a fixed cost..
	|		OR 
	|		&ProductCostingByPlannedCost
	|		AND TTTypesOfStocks.DirectionOfProductionIssue IN (
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
	|	 	AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);

	#EndRegion
	
	#Region WriteOffToOtherBatches_TransferOfManufacturedProductsToWarehouse
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	(CASE
	|		WHEN TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|		 OR TTTypesOfStocks.ShopFloorStockroom
	|			THEN TTTypesOfStocks.AnalysisOfProductAccountingByRecipient
	|		ELSE TTTypesOfStocks.AnalysisOfProductTrackingBySender END) AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref				AS Lot,
	|	TTTypesOfStocks.LotVendorAttributes	AS LotVendorAttributes,
	|
	// Corresponding fields
	|	TTTypesOfStocks.LotVendorAttributes						AS LotVendorAttributesCorr,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS CorItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute		AS CorInventoryOwnerAttribute,
	|	UNDEFINED					AS CorCompany,
	|	DocumentTable.Ref			AS CorLot,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.EmployeeResponsible			AS Manager,
	|	TTTypesOfStocks.FinancialAccountingDimension AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS Cost,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumCompl
	|		ELSE 0 
	|	END AS LocalCost,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS CostMan,
	|
	// Additional field
	|	CASE WHEN &ProductCostingByPlannedCost
	|	 AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED
	|	END AS AccountingSection,
	|
	// Other fields
	|	TTTypesOfStocks.RowID					AS RowID,
	// 2.4 For manufactured products from toll-free raw materials during processing, the ID of the FIN record is not filled
	// in to separate the lines with balance and off-balance amounts.
	|	(CASE
	|		WHEN TRUE
	|			THEN TTTypesOfStocks.FinRecordID END) AS FinRecordID,
	// The business transaction and setting up of the household of operation must match the query #Area Internal Access_The arrival of the released products.
	|	CASE
	|		WHEN TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost)
	|		ELSE VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|	END																				AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)	AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.Supplement)	AS EntryType,
	|	DocumentTable.Ref	AS DocumentRegisterRecords
	|
	|FROM
	|	Document.BackflushProduction AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	// When the output is reflected according to the planned or actual cost, Registered Records are generated for the transfer of products 
	// from the division to the wholesale warehouse.
	|	AND (
	|		TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
	|		AND NOT TTTypesOfStocks.ShopFloorStockroom
	// When the output is reflected at the standard cost, additional Registered Records are generated for the output of products to the shop hoard and 
	// Registered Records for the output of works, except for the output at a fixed cost and the output with write-off for expenses.
	// The Registered Records of the write-off for expenses are formed in the write-off of the expenseactivities_Write-offs of released productionsworkspends.
	|		OR
	|		&ProductCostingByPlannedCost
	|		AND TTTypesOfStocks.DirectionOfProductionIssue IN (
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
	|		AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);

	#EndRegion
	
	#Region WriteOffForExpensesAssets_WriteOffOfManufacturedProductsAndWorksForExpenses
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	&Ref					AS DocumentRegisterRecords,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DocumentTable.Ref				AS Lot,
	|	TTTypesOfStocks.LotVendorAttributes	AS LotVendorAttributes,
	|
	// Corresponding fields
	|	UNDEFINED								AS CorCompany,
	|	UNDEFINED								AS CorItemsLocationAttributes,
	|	UNDEFINED								AS CorInventoryOwnerAttribute,
	|	TTTypesOfStocks.ExpenseItem				AS ExpenseItemAssets,
	|	CASE WHEN TTTypesOfStocks.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN TTTypesOfStocks.DimensionOfExpenses
	|		ELSE TTTypesOfStocks.AssetsLiabilitiesDimension
	|	END										AS AssetExpenseAnalytics,
	|	DocumentTable.LineOfBusiness	AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	TTTypesOfStocks.ExpenseRecipientDivision AS Department,
	|	DocumentTable.EmployeeResponsible			AS Manager,
	|	TTTypesOfStocks.FinancialAccountingDimension AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS Cost,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumCompl
	|		ELSE 0 
	|	END AS LocalCost,
	|	CASE
	|		WHEN &ProductCostingByPlannedCost
	|		 OR TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			THEN TTTypesOfStocks.SumMan
	|		ELSE 0 
	|	END AS CostMan,
	|
	// Additional field
	|	CASE WHEN &ProductCostingByPlannedCost
	|	 AND TTTypesOfStocks.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED
	|	END AS AccountingSection,
	|
	// Other fields
	|	VALUE(Enum.LotRecordTypes.Supplement)	AS EntryType,
	|	TTTypesOfStocks.GLAccountSettings					AS GLAccountSettings,
	|	TTTypesOfStocks.RowID					AS RowID,
	|	TTTypesOfStocks.FinRecordID				AS FinRecordID,
	|	CASE WHEN TTTypesOfStocks.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	END AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)	AS BusinessTransactionSetting
	|FROM
	|	Document.BackflushProduction AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TTTypesOfStocks.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);

	#EndRegion
	
	#Region WriteOffToOtherBatches_ExpenseOfMaterialsFromWarehouseAndReceiptOfProductionBatch
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.AnalysisOfProductTrackingBySender	AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED											AS CorCompany,
	|	TTTypesOfStocks.ProductionLot						AS CorLot,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS CorItemsLocationAttributes,
	|	TTTypesOfStocks.CorInventoryOwnerAttribute								AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.EmployeeResponsible			AS Manager,
	|	TTTypesOfStocks.FinancialAccountingDimension AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|
	// Other fields
	|	TTTypesOfStocks.RowID					AS RowID,
	|	TTTypesOfStocks.FinRecordID				AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)			AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots)	AS BusinessTransactionSetting
	|FROM
	|	Document.BackflushProduction AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TTTypesOfStocks.DirectionOfProductionIssue = 
	|		VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND TTTypesOfStocks.BusinessOperation <> 
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);
	
	#EndRegion
	
	#Region InternalReceipt_ReceiptOfReturnableWastePerProductionBatch
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.AnalysisOfProductAccountingByRecipient	AS ItemsLocationAttributes,
	|	TTTypesOfStocks.CorInventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TTTypesOfStocks.ProductionLot	AS Lot,
	|	UNDEFINED						AS LotVendorAttributes,
	|	0									AS RowCode,
	|
	// Corresponding fields
	|	TTTypesOfStocks.AnalysisOfProductTrackingBySender	AS CorItemsLocationAttributes,
	|	TTTypesOfStocks.CorControllingAttributes				AS CorGroupOfManufacturedProducts, 
	|	UNDEFINED AS LotVendorAttributesCorr,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	UNDEFINED							AS Department,
	|	UNDEFINED							AS Manager,
	|	TTTypesOfStocks.FinancialAccountingDimension AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|	TTTypesOfStocks.SumMan		AS Cost,
	|	TTTypesOfStocks.SumMan		AS CostExcludingVAT,
	|	TTTypesOfStocks.SumCompl		AS LocalCost,
	|	TTTypesOfStocks.SumMan		AS CostMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	TTTypesOfStocks.OffBalanceSheetManAmount	AS OffBalanceCost,
	|	TTTypesOfStocks.OffBalanceSheetLocalAmount	AS OffBalanceCostLocal,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TTTypesOfStocks.RowID					AS RowID,
	|	TTTypesOfStocks.FinRecordID				AS FinRecordID,
	|	TTTypesOfStocks.BusinessOperation					AS BusinessOperation,
	|	TTTypesOfStocks.BusinessTransactionSetting		AS BusinessTransactionSetting
	|FROM
	|	Document.BackflushProduction AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TTTypesOfStocks.DirectionOfProductionIssue = 
	|		VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND TTTypesOfStocks.BusinessOperation = 
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region ProductionLots

// Generates a batch production of the document.
// Parameters:
//  Object - DocumentObject.BackflushProduction - the object for which it is necessary to form the batch production.
//
Procedure FormProductionBatches(Object) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", Object.Ref);
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextManufacturedProductsTable());
	QueryTexts.Add(QueryTextCostGroupFields());
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	TextSelectionOfBatchFields = QueryTextSelectionOfBatchFields();
	Catalogs.ProductionLots.FormProductionBatches(
		Query,
		TextSelectionOfBatchFields,
		True,
		True);
	
EndProcedure

Function QueryTextManufacturedProductsTable()
	
	Return
	"SELECT ALLOWED
	|	CASE
	|		WHEN GoodsTable.Ref.Patch
	|			AND GoodsTable.Ref.CorrectionSavesProductionLots
	|			THEN GoodsTable.Ref.CorrectedDocument
	|		ELSE GoodsTable.Ref
	|	END                                        AS Ref,
	|	GoodsTable.Ref.Date                    AS Date,
	|	GoodsTable.Ref.GroupCosts       AS GroupCosts,
	|	GoodsTable.Ref.Organization             AS Organization,
	|	GoodsTable.Ref.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.Ref.ProductionIssueForActivity   AS ProductionIssueForActivity,
	|	GoodsTable.LineNumber                    AS LineNumber,
	|	GoodsTable.CostGroupNumber              AS CostGroupNumber,
	|	GoodsTable.InternalSubcontracting          AS InternalSubcontracting,
	|	GoodsTable.MaterialProviderCompany             AS MaterialProviderCompany,
	|	GoodsTable.Products                   AS Products,
	|	GoodsTable.Characteristic                 AS Characteristic,
	|	GoodsTable.BillOfMaterials                   AS BillOfMaterials,
	|	GoodsTable.Series                          AS Series,
	|	GoodsTable.Purpose                     AS Purpose
	|INTO TableProduction
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND GoodsTable.Ref.Posted
	|
	|INDEX BY
	|	Ref,
	|	LineNumber
	|";
	
EndFunction

Function QueryTextCostGroupFields()
	
	Return
	"SELECT ALLOWED
	|	TableProduction.Ref                AS Ref,
	|	TableProduction.CostGroupNumber     AS CostGroupNumber,
	|	TableProduction.GroupCosts     AS GroupCosts,
	|	CASE
	|		WHEN TableProduction.InternalSubcontracting
	|			THEN TableProduction.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN TableProduction.Organization
	|	END                                  AS Organization,
	|	TableProduction.InternalSubcontracting AS InternalSubcontracting,
	|	TableProduction.ProductionIssueForActivity AS ProductionIssueForActivity,
	|	MIN(CASE
	|		WHEN TableProduction.GroupCosts IN
	|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByDocument),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOM))
	|			THEN TableProduction.LineOfBusiness
	|		ELSE ISNULL(CatAssignments.LineOfBusiness, UNDEFINED)
	|	END)                                 AS LineOfBusiness,
	|	MIN(CASE
	|		WHEN TableProduction.GroupCosts IN
	|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
	|			THEN TableProduction.Products
	|		ELSE UNDEFINED
	|	END)                                 AS Products,
	|	MIN(CASE
	|		WHEN TableProduction.GroupCosts IN
	|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
	|			THEN TableProduction.Characteristic
	|		ELSE UNDEFINED
	|	END)                                 AS Characteristic,
	|	MIN(CASE
	|		WHEN TableProduction.GroupCosts IN
	|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOM),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments))
	|			THEN TableProduction.BillOfMaterials
	|		ELSE UNDEFINED
	|	END)                                 AS BillOfMaterials,
	|	MIN(CASE
	|		WHEN TableProduction.GroupCosts IN
	|				(VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches))
	|			THEN TableProduction.Purpose
	|		ELSE UNDEFINED
	|	END)                                 AS Purpose,
	|	MIN(CASE
	|		WHEN TableProduction.GroupCosts IN(
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts),
	|				VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments))
	|			THEN TableProduction.Series
	|		ELSE UNDEFINED
	|	END)                                 AS Series
	|INTO CostGroupFields
	|FROM
	|	TableProduction AS TableProduction
	|
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON CatAssignments.Ref = TableProduction.Purpose
	|
	|GROUP BY
	|	TableProduction.Ref,
	|	TableProduction.CostGroupNumber,
	|	TableProduction.GroupCosts,
	|	CASE
	|		WHEN TableProduction.InternalSubcontracting
	|			THEN TableProduction.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN TableProduction.Organization
	|	END,
	|	TableProduction.InternalSubcontracting,
	|	TableProduction.ProductionIssueForActivity
	|
	|INDEX BY
	|	Organization,
	|	InternalSubcontracting,
	|	ProductionIssueForActivity,
	|	LineOfBusiness,
	|	Products,
	|	Characteristic,
	|	BillOfMaterials,
	|	Purpose,
	|	Series
	|";
	
EndFunction

Function QueryTextSelectionOfBatchFields()
	
	Return
	"SELECT ALLOWED
	|	CostGroupFields.Ref                       AS Document,
	|	CostGroupFields.CostGroupNumber            AS CostGroupNumber,
	|	CostGroupFields.GroupCosts            AS GroupCosts,
	|	CostGroupFields.Organization                  AS Organization,
	|	CostGroupFields.InternalSubcontracting        AS InternalSubcontracting,
	|	CostGroupFields.ProductionIssueForActivity        AS VATActivityType,
	|	MainProducts.Products                 AS MainProductProducts,
	|	MainProducts.Characteristic               AS MainProductCharacteristic,
	|	CatMainProducts.AnalyticalGroup AS ProductsGroup,
	|	UNDEFINED                                 AS ProcessType,
	|	CostGroupFields.LineOfBusiness      AS LineOfBusiness,
	|	CostGroupFields.Products                 AS Products,
	|	CostGroupFields.Characteristic               AS Characteristic,
	|	CostGroupFields.BillOfMaterials                 AS BillOfMaterials,
	|	CostGroupFields.Purpose                   AS Purpose,
	|	CostGroupFields.Series                        AS Series
	|INTO TTProductionBatchFields
	|FROM
	|	CostGroupFields AS CostGroupFields
	|
	|	INNER JOIN LineNumbersOfMainProducts AS LineNumbersOfMainProducts
	|	ON LineNumbersOfMainProducts.Ref = CostGroupFields.Ref
	|	AND LineNumbersOfMainProducts.CostGroupNumber = CostGroupFields.CostGroupNumber
	|
	|	INNER JOIN TableProduction AS MainProducts
	|	ON MainProducts.Ref = CostGroupFields.Ref
	|	AND MainProducts.LineNumber = LineNumbersOfMainProducts.LineNumber
	|
	|	LEFT JOIN Catalog.Products AS CatMainProducts
	|	ON CatMainProducts.Ref = MainProducts.Products
	|";
	
EndFunction

#EndRegion

#Region SetOfSeries

Function TextOfRequestToFillInStatusesForSpecifyingSerialNumberOfProduct()
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Recipient AS Recipient,
	|	Goods.CostGroupNumber AS CostGroupNumber,
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
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Recipient,
	|	Goods.CostGroupNumber,
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
	|	Goods.Recipient,
	|	Goods.CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Recipient,
	|	SetOfSeries.CostGroupNumber,
	|	SetOfSeries.Count AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Recipient,
	|	SetOfSeries.CostGroupNumber,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Recipient,
	|	SetOfSeries.CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|						OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|									THEN 10
	|								ELSE 9
	|							END
	|					ELSE 0
	|				END
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|						OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|									THEN 8
	|								ELSE 7
	|							END
	|					ELSE 0
	|				END
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyOnReceiving
	|			AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|				OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|			AND BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenReceivingProductsFromManufacturing
	|			THEN CASE
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
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
	|		WHEN SeriesAccountingPoliciesAreCommon.BatchAccountingPolicy.SpecifyDuringProduction
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 2
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|	
	|	LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|		AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		AND Goods.Purpose = ProductsToRequest.Purpose
	|		AND Goods.Series = ProductsToRequest.Series
	|		AND Goods.Recipient = ProductsToRequest.Recipient
	|		AND Goods.CostGroupNumber = ProductsToRequest.CostGroupNumber
	|
	|	LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|		AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|		AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|		AND ProductsToRequest.Recipient = SeriesToRequest.Recipient
	|		AND ProductsToRequest.CostGroupNumber = SeriesToRequest.CostGroupNumber
	|
	|	LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPoliciesWarehouse
	|		ON BatchAccountingPoliciesWarehouse.Warehouse = ProductsToRequest.Recipient
	|		AND ProductsToRequest.ProductKind = BatchAccountingPoliciesWarehouse.Ref
	|
	|	LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON BatchAccountingPoliciesWarehouse.Warehouse = Warehouses.Ref
	|	
	|	LEFT JOIN Catalog.ItemKinds AS SeriesAccountingPoliciesAreCommon
	|	ON SeriesAccountingPoliciesAreCommon.Ref = ProductsToRequest.ProductKind
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

Function RequestTextForFillingInStatusesSpecifyingSeriesMaterialsAndWorks()
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyOnShipmentForInternalNeeds
	|			THEN CASE
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		WHEN SeriesAccountingPoliciesAreCommon.BatchAccountingPolicy.SpecifyOnMaterialConsumption
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 2
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|	
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = Goods.Products
	|	
	|	LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPoliciesWarehouse
	|	ON BatchAccountingPoliciesWarehouse.Warehouse = Goods.Warehouse
	|	AND BatchAccountingPoliciesWarehouse.Ref = CatProducts.ProductKind
	|	
	|	LEFT JOIN Catalog.ItemKinds AS SeriesAccountingPoliciesAreCommon
	|	ON SeriesAccountingPoliciesAreCommon.Ref = CatProducts.ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber,
	|	Statuses.BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	Statuses.LineNumber";

	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			NStr("vi = 'Xuất xưởng thành phẩm';
				|ru = 'Выпуск продукции';
				|en = 'Product release'; fa = 'تولید محصول';
				|it = 'Emissione di prodotti';
				|pl = 'Wyprodukowanie';
				|tr = 'Ürün sürümü'"),
			FormPrintedFormOfInvoice(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "MaterialTransferToProduction") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"MaterialTransferToProduction",
			NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
				|ru = 'Передача материалов в производство';
				|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
				|it = 'Consegna materiali in produzione';
				|pl = 'Przekazanie materiałów do produkcji';
				|tr = 'Malzemelerin üretime aktarımı'"),
			PrintingTransferOfMaterialsToProduction(ObjectsArray, PrintObjects));
		
	EndIf;
	
	BackflushProductionLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function FormPrintedFormOfInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	Template = PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_Invoice");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref						AS Ref,
	|	DocumentData.Number						AS Number,
	|	DocumentData.Date						AS Date,
	|	DocumentData.CorrectedDocument.Number	AS NumberOfDocumentBeingCorrected,
	|	DocumentData.CorrectedDocument.Date	AS DateOfDocumentBeingCorrected
	|FROM
	|	Document.BackflushProduction AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	DocumentData.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                          AS Ref,
	|	GoodsTable.CostGroupNumber               AS CostGroupNumber,
	|	MAX(GoodsTable.InternalSubcontracting) AS InternalSubcontracting,
	|	MAX(GoodsTable.MaterialProviderCompany)    AS MaterialProviderCompany
	|INTO CostGroups
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.CostGroupNumber
	|
	|INDEX BY
	|	Ref,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref               AS Ref,
	|	CASE
	|		WHEN GoodsTable.InternalSubcontracting
	|			THEN GoodsTable.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN GoodsTable.Ref.Organization
	|	END                              AS Organization,
	|	GoodsTable.LineNumber          AS LineNumber,
	|	GoodsTable.Products         AS Products,
	|	GoodsTable.Characteristic       AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                              AS Purpose,
	|	GoodsTable.Recipient           AS Warehouse,
	|	GoodsTable.Ref.Department AS Department,
	|	GoodsTable.Package             AS Package,
	|	GoodsTable.NumberOfPackages   AS Count,
	|	GoodsTable.Series                AS Series
	|INTO TTProducts_1
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient.ShopFloorStockroom
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Ref,
	|	CASE
	|		WHEN GoodsTable.InternalSubcontracting
	|			THEN GoodsTable.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN SeriesTable.Ref.Organization
	|	END,
	|	MAX(GoodsTable.LineNumber),
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Recipient,
	|	SeriesTable.Ref.Department,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|	SeriesTable.Count,
	|	SeriesTable.Series
	|FROM
	|	Document.BackflushProduction.BatchFinishedProducts AS SeriesTable
	|		INNER JOIN Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|		ON SeriesTable.Ref = GoodsTable.Ref
	|			AND SeriesTable.Products = GoodsTable.Products
	|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|			AND SeriesTable.Purpose = GoodsTable.Purpose
	|			AND SeriesTable.Recipient = GoodsTable.Recipient
	|			AND SeriesTable.CostGroupNumber = GoodsTable.CostGroupNumber
	|WHERE
	|	SeriesTable.Ref IN(&DocumentsArray)
	|	AND SeriesTable.Count <> 0
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient.ShopFloorStockroom
	|
	|GROUP BY
	|	SeriesTable.Ref,
	|	CASE
	|		WHEN GoodsTable.InternalSubcontracting
	|			THEN GoodsTable.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN SeriesTable.Ref.Organization
	|	END,
	|	SeriesTable.Recipient,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Count
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (4, 6, 8, 10)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref             AS Ref,
	|	CASE
	|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN GoodsTable.ProductOwner
	|		WHEN CostGroups.InternalSubcontracting
	|			THEN CostGroups.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN GoodsTable.Ref.Organization
	|	END                            AS Organization,
	|	GoodsTable.LineNumber        AS LineNumber,
	|	GoodsTable.Products       AS Products,
	|	GoodsTable.Characteristic     AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	GoodsTable.Recipient         AS Warehouse,
	|	GoodsTable.Department      AS Department,
	|	GoodsTable.Package           AS Package,
	|	GoodsTable.NumberOfPackages AS Count,
	|	GoodsTable.Series              AS Series
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	
	|	INNER JOIN CostGroups AS CostGroups
	|	ON CostGroups.Ref = GoodsTable.Ref
	|	AND CostGroups.CostGroupNumber = GoodsTable.CostGroupNumber
	|	
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient.ShopFloorStockroom
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Ref,
	|	CASE
	|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN GoodsTable.ProductOwner
	|		WHEN CostGroups.InternalSubcontracting
	|			THEN CostGroups.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN GoodsTable.Ref.Organization
	|	END,
	|	MAX(GoodsTable.LineNumber),
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Recipient,
	|	GoodsTable.Department,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|	SeriesTable.Count,
	|	SeriesTable.Series
	|FROM
	|	Document.BackflushProduction.BatchSideAndIntermediateRelease AS SeriesTable
	|	
	|	INNER JOIN Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
	|	ON SeriesTable.Ref = GoodsTable.Ref
	|	AND SeriesTable.Products = GoodsTable.Products
	|	AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|	AND SeriesTable.Purpose = GoodsTable.Purpose
	|	AND SeriesTable.Recipient = GoodsTable.Recipient
	|	AND SeriesTable.CostGroupNumber = GoodsTable.CostGroupNumber
	|	AND SeriesTable.ProductOwner = GoodsTable.ProductOwner
	|	
	|	INNER JOIN CostGroups AS CostGroups
	|	ON CostGroups.Ref = GoodsTable.Ref
	|	AND CostGroups.CostGroupNumber = GoodsTable.CostGroupNumber
	|
	|WHERE
	|	SeriesTable.Ref IN(&DocumentsArray)
	|	AND SeriesTable.Count <> 0
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND VALUETYPE(GoodsTable.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT GoodsTable.Recipient.ShopFloorStockroom
	|
	|GROUP BY
	|	SeriesTable.Ref,
	|	CASE
	|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|			THEN GoodsTable.ProductOwner
	|		WHEN CostGroups.InternalSubcontracting
	|			THEN CostGroups.MaterialProviderCompany
	|		WHEN TRUE
	|			THEN GoodsTable.Ref.Organization
	|	END,
	|	SeriesTable.Recipient,
	|	GoodsTable.Department,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Count
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (4, 6, 8, 10)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                      AS Ref,
	|	GoodsTable.Organization                 AS Organization,
	|	GoodsTable.Organization.Prefix         AS Prefix,
	|	MIN(GoodsTable.LineNumber)        AS LineNumber,
	|	GoodsTable.Products                AS Products,
	|	&CodeArticle                               AS CodeArticle,
	|	GoodsTable.Products.DescriptionFull AS ProductItemName,
	|	GoodsTable.Characteristic              AS Characteristic,
	|	GoodsTable.Characteristic.Description AS CharacteristicName,
	|	GoodsTable.Series.Description          AS SeriesName_,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure.Description
	|		ELSE GoodsTable.Package.Description
	|	END                                     AS UnitOfMeasure,
	|	SUM(GoodsTable.Count)           AS Count,
	|	VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction) AS DirectionOfProductionIssue,
	|	GoodsTable.Warehouse.Presentation         AS RecipientPresentation1,
	|	GoodsTable.Department.Presentation AS DivisionRepresentation,
	|	&RecipientTypeWarehouse                       AS TypeRecipient
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Organization,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure.Description
	|		ELSE GoodsTable.Package.Description
	|	END,
	|	GoodsTable.Series,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Department
	|
	|ORDER BY
	|	Ref,
	|	Organization,
	|	LineNumber
	|
	|TOTALS
	|	MAX(TypeRecipient)
	|BY
	|	Ref,
	|	Organization,
	|	DivisionRepresentation,
	|	RecipientPresentation1";
	
	Query.Text = StrReplace(Query.Text, 
		"&CodeArticle", 
		?(NameOfCodeColumn = "", """""", "GoodsTable.Products." + NameOfCodeColumn));

	Query.SetParameter("DocumentsArray",           ObjectsArray);
	Query.SetParameter("RecipientTypeWarehouse",         NStr("vi = 'Kho bãi';
																|ru = 'Склад';
																|en = 'Warehouse'; fa = 'Warehouse';
																|it = 'Magazzino';
																|pl = 'Magazyn';
																|tr = 'Ambar'", Common.DefaultLanguageCode()));
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	SpreadsheetDocument.HeaderSize = 0;
	SpreadsheetDocument.FooterSize = 0;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProductsRelease_Invoice";
	
	ResultsArray 		= Query.ExecuteBatch();
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[ResultsArray.UBound()].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		SelectionByOrganization_ = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		
		While SelectionByOrganization_.Next() Do
			SelectionByDivision_ = SelectionByOrganization_.Select(QueryResultIteration.ByGroups);
			While SelectionByDivision_.Next() Do
				SelectionByRecipients = SelectionByDivision_.Select(QueryResultIteration.ByGroups);
				While SelectionByRecipients.Next() Do
					
					If Not FirstDocument Then
						SpreadsheetDocument.PutHorizontalPageBreak();
					EndIf;
					
					PageNumber = 1;
					
					FirstDocument    = False;
					RowNumberStart = SpreadsheetDocument.TableHeight + 1;
					
					// We output the general details of the header
					TemplateArea = Template.GetArea("Header");
					TemplateArea.Parameters.Fill(PrintData);
					TemplateArea.Parameters.DivisionRepresentation = SelectionByRecipients.DivisionRepresentation;
					TemplateArea.Parameters.RecipientPresentation1 = SelectionByRecipients.RecipientPresentation1;
					TemplateArea.Parameters.TypeRecipient = SelectionByRecipients.TypeRecipient;
					
					AreaParameters_ = New Structure;
					AreaParameters_.Insert(
						"TitleText",
						TMCommonUseClientServer.GenerateDocumentTitle(
							PrintData,
							NStr("vi = 'Xuất xưởng thành phẩm';
								|ru = 'Выпуск продукции';
								|en = 'Product release'; fa = 'تولید محصول';
								|it = 'Emissione di prodotti';
								|pl = 'Wyprodukowanie';
								|tr = 'Ürün sürümü'", Common.DefaultLanguageCode())));
					AreaParameters_.Insert(
						"RepresentationOfTheOrganization",
						PrintFormGeneration.OrganizationDescription(
							PrintFormGeneration.InformationAboutLegalEntity(
								SelectionByOrganization_.Organization,
								PrintData.Date),
							"FullDescr,TIN,LegalAddress,Phones"));
					
					TemplateArea.Parameters.Fill(AreaParameters_);
					
					SpreadsheetDocument.Put(TemplateArea);
					
					// Creating an array to check the output
					ArrayOfOutputAreas = New Array;
					
					// We output the multiline part of the document
					TableHeaderArea = Template.GetArea(?(NameOfCodeColumn = "", "TabHeader", "TabHeaderWithCode"));
					TemplateArea           = Template.GetArea(?(NameOfCodeColumn = "", "String",       "StringWithCode"));
					BasementArea_          = Template.GetArea("Footer");
					
					If NameOfCodeColumn <> "" Then
						TableHeaderArea.Parameters.Column = PresentationOfCodesColumn;
					EndIf;
					
					LineProducts_ = SelectionByRecipients.Select();
					RowsCount = LineProducts_.Count();
					LineNumber = 0;
					ProductLineParameters = New Structure("LineNumber,ProductItemName");
					While LineProducts_.Next() Do
						
						AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
						AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
						
						LineNumber = LineNumber + 1;
						
						ProductLineParameters.LineNumber = LineNumber;
						ProductLineParameters.ProductItemName =
							ProductsClientServer.PresentationOfProductsForPrinting(
								LineProducts_.ProductItemName, 
								LineProducts_.CharacteristicName,,
								LineProducts_.SeriesName_,
								AdditionalParametersProductPresentation);
						
						TemplateArea.Parameters.Fill(LineProducts_);
						TemplateArea.Parameters.Fill(ProductLineParameters);
						
						If LineNumber = 1 Then
							
							TableHeaderArea.Parameters.PageNumber =
								StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Trang %1';
										|ru = 'Страница %1';
										|en = 'Page %1'; fa = 'Page %1';
										|it = 'Pagina %1';
										|pl = 'Strona %1';
										|tr = 'Sayfa %1'", Common.DefaultLanguageCode()), PageNumber);
							
							SpreadsheetDocument.Put(TableHeaderArea);
							
						Else
							
							ArrayOfOutputAreas.Clear();
							ArrayOfOutputAreas.Add(TemplateArea);
							
							If LineNumber = RowsCount Then
								
								ArrayOfOutputAreas.Add(BasementArea_);
								
							EndIf;
							
							If LineNumber <> 1 And Not SpreadsheetDocument.CheckPut(ArrayOfOutputAreas) Then
								
								PageNumber = PageNumber + 1;
								SpreadsheetDocument.PutHorizontalPageBreak();
								TableHeaderArea.Parameters.PageNumber =
									StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Trang %1';
											|ru = 'Страница %1';
											|en = 'Page %1'; fa = 'Page %1';
											|it = 'Pagina %1';
											|pl = 'Strona %1';
											|tr = 'Sayfa %1'", Common.DefaultLanguageCode()), PageNumber);
								
								SpreadsheetDocument.Put(TableHeaderArea);
								
							EndIf;
							
						EndIf;
						
						SpreadsheetDocument.Put(TemplateArea);
						
					EndDo;
					
					// Output the document's basement
					BasementArea_.Parameters.TotalString =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Tổng số mục %1';
								|ru = 'Всего наименований %1';
								|en = 'Total items %1'; fa = 'Total items %1';
								|it = 'Totale articoli %1';
								|pl = 'Razem pozycji %1';
								|tr = 'Toplam tanım %1'", Common.DefaultLanguageCode()), LineProducts_.Count());
					
					SpreadsheetDocument.Put(BasementArea_);
					
					PrintManagement.SetDocumentPrintArea(
						SpreadsheetDocument,
						RowNumberStart,
						PrintObjects,
						PrintData.Ref);
					
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

Function PrintingTransferOfMaterialsToProduction(ObjectsArray, PrintObjects)

	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	OutputAdditionalColumn = ValueIsFilled(AdditionalColumn);

	Query= New Query;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text =
	"SELECT
	|	Attributes.Ref                     AS Ref,
	|	Attributes.Number                      AS Number,
	|	Attributes.Date                       AS Date,
	|	Attributes.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	Attributes.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|
	|	INNER JOIN Document.BackflushProduction AS Attributes
	|	ON Attributes.Ref = GoodsTable.Ref
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT ISNULL(GoodsTable.Warehouse.ShopFloorStockroom, TRUE)
	|
	|GROUP BY
	|	Attributes.Ref,
	|	Attributes.Number,
	|	Attributes.Date,
	|	Attributes.CorrectedDocument
	|
	|ORDER BY
	|	Attributes.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                                                        AS Ref,
	|	REFPRESENTATION(GoodsTable.InventoryOwnerAttribute.Organization)                   AS Organization,
	|	GoodsTable.InventoryOwnerAttribute.Organization.Prefix                                AS Prefix,
	|	REFPRESENTATION(GoodsTable.ItemsLocationAttributes.StorageLocation) AS Warehouse,
	|	REFPRESENTATION(GoodsTable.Department)                            AS Department,
	|	GoodsTable.LineNumber                                                   AS LineNumber,
	|	&AdditionalColumnKey,
	|	GoodsTable.ItemsLocationAttributes.Products.DescriptionFull    AS Products,
	|	GoodsTable.ItemsLocationAttributes.Characteristic.DescriptionFull  AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			REFPRESENTATION(GoodsTable.ItemsLocationAttributes.Products.UnitOfMeasure)
	|		ELSE 
	|			REFPRESENTATION(GoodsTable.Package)
	|	END                                                                       AS Package,
	|	GoodsTable.NumberOfPackages                                            AS Count
	|FROM
	|	Document.BackflushProduction.InventoryOwnerAttributesMaterialsAndWorks AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.ItemsLocationAttributes.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT ISNULL(GoodsTable.ItemsLocationAttributes.StorageLocation.ShopFloorStockroom, TRUE)
	|	AND GoodsTable.Ref.PackagingUnitsInInventoryOwnerAttributes
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref                                  AS Ref,
	|	REFPRESENTATION(GoodsTable.Ref.Organization) AS Organization,
	|	GoodsTable.Ref.Organization.Prefix              AS Prefix,
	|	REFPRESENTATION(GoodsTable.Warehouse)              AS Warehouse,
	|	REFPRESENTATION(GoodsTable.Department)      AS Department,
	|	GoodsTable.LineNumber                             AS LineNumber,
	|	&AdditionalColumnItem,
	|	GoodsTable.Products.DescriptionFull         AS Products,
	|	GoodsTable.Characteristic.DescriptionFull       AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
	|		ELSE
	|			REFPRESENTATION(GoodsTable.Package)
	|	END                                                 AS Package,
	|	GoodsTable.NumberOfPackages                      AS Count
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT ISNULL(GoodsTable.Warehouse.ShopFloorStockroom, TRUE)
	|	AND NOT GoodsTable.Ref.PackagingUnitsInInventoryOwnerAttributes
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	MAX(Prefix)
	|BY
	|	Ref,
	|	Organization,
	|	Department,
	|	Warehouse
	|";
	
	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnKey,", "GoodsTable.ItemsLocationAttributes.Products." + AdditionalColumn +" AS AdditionalColumn,");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnItem,", "GoodsTable.Products." + AdditionalColumn +" AS AdditionalColumn,");
	Else
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnKey,", "");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnItem,", "");
	EndIf;
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_MaterialTransferToProduction";

	DocumentAttributes = New Structure("Number, Date, Prefix, DateOfDocumentBeingCorrected, NumberOfDocumentBeingCorrected");
	DocumentSynonym = String(Enums.BusinessTransactions.MaterialTransferToProduction);

	Template =
		PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_MaterialTransferToProduction");
	
	HeaderArea_ = Template.GetArea("Title");
	LabelArea   = Template.GetArea("Signatures");
	If OutputAdditionalColumn Then
		AreaRow       = Template.GetArea("RowColumn");
		Area_TableHeader = Template.GetArea("TableHeaderAdditionalColumn");
	Else
		AreaRow       = Template.GetArea("String");
		Area_TableHeader = Template.GetArea("TableHeader");
	EndIf;
	
	ResultsArray 		= Query.ExecuteBatch();
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		SelectionByOrganization_ = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		While SelectionByOrganization_.Next() Do
			
			SelectionByDivision_ = SelectionByOrganization_.Select(QueryResultIteration.ByGroups);
			While SelectionByDivision_.Next() Do
				
				SampleByWarehouse = SelectionByDivision_.Select(QueryResultIteration.ByGroups);
				While SampleByWarehouse.Next() Do
					
					RowNumberStart = TabDocument.TableHeight + 1;
					
					If Not FirstDocument Then
						TabDocument.PutHorizontalPageBreak();
					EndIf;
					FirstDocument = False;
					
					// Header output.
					FillPropertyValues(DocumentAttributes, PrintData);
					HeaderArea_.Parameters.Fill(SampleByWarehouse);
					
					AreaParameters_ = New Structure;
					AreaParameters_.Insert(
						"TitleText",
						TMCommonUseClientServer.GenerateDocumentTitle(
							DocumentAttributes,
							DocumentSynonym));
					AreaParameters_.Insert("Organization", SampleByWarehouse.Organization);
					
					HeaderArea_.Parameters.Fill(AreaParameters_);
					
					BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
						TabDocument,
						Template,
						HeaderArea_,
						SelectionByDocuments.Ref);
					
					TabDocument.Put(HeaderArea_);
					
					// Output of the header.
					If OutputAdditionalColumn Then
						Area_TableHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
					EndIf;
					TabDocument.Put(Area_TableHeader);
					
					// Output of document lines.
					
					RowIndex = 1;
					StringSelection = SampleByWarehouse.Select();
					While StringSelection.Next() Do
						
						AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
						AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
						
						AreaRow.Parameters.Fill(StringSelection);
						
						AreaRow.Parameters.Products = ProductsClientServer.PresentationOfProductsForPrinting(
							StringSelection.Products,
							StringSelection.Characteristic,
							,
							,
							AdditionalParametersProductPresentation);
						
						AreaRow.Parameters.LineNumber = RowIndex;
						
						TabDocument.Put(AreaRow);
						
						RowIndex = RowIndex + 1;
						
					EndDo;
					
					// Output of the basement.
					TabDocument.Put(LabelArea);
	
					PrintManagement.SetDocumentPrintArea(
						TabDocument,
						RowNumberStart,
						PrintObjects,
						SelectionByDocuments.Ref);
					
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	Return TabDocument;
	
EndFunction

#EndRegion

// The procedure for processing changes in the direction of activity.
// 
// Parameters:
// 	Form - ClientApplicationForm
// Returns:
// 	See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "ManufacturedProducts,SideAndIntermediateRelease,MaterialsAndWorks";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("ManufacturedProducts",  TableOfConditions);
	DocumentProcessingProcedure.StringProcessingConditions.Insert("SideAndIntermediateRelease",  TableOfConditions);
	DocumentProcessingProcedure.StringProcessingConditions.Insert("MaterialsAndWorks", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.BackflushProduction.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.25.26";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("22e5af9c-ec3d-4253-83a1-3a0812b5dd49");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.BackflushProduction.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Sản xuất không theo đơn đặt hàng"":';
								|ru = 'Обновление документов ""Производство без заказа"":';
								|en = 'Update the ""Backflush production"" documents:'; fa = 'Update the ""Backflush production"" documents:';
								|it = 'Обновление документов ""Производство без заказа"":';
								|pl = 'Update the ""Backflush production"" documents:';
								|tr = '""Siparişsiz üretim"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin hệ thống ""Việc chỉnh sửa sẽ lưu lô hàng sản xuất"".';
								|ru = '- заполняет служебный реквизит ""Исправление сохраняет партии производства"".';
								|en = '- Fills in the internal ""Correction saves production lots"" attribute.'; fa = '- Fills in the internal ""Correction saves production lots"" attribute.';
								|it = '- Fills in the internal ""Correction saves production lots"" attribute.';
								|pl = '- Fills in the internal ""Correction saves production lots"" attribute.';
								|tr = '- ""Düzeltme üretim lotlarını kaydeder"" hizmet özniteliğini doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.BackflushProduction.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.DocumentCorrections.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.BackflushProduction.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.BackflushProduction.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.BackflushProduction";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.BackflushProduction AS DocumentAttributes
	|WHERE
	// We raise the flag for all source documents for which no correcting/reversing documents have been entered.
	|	NOT DocumentAttributes.Patch
	|	AND NOT DocumentAttributes.CorrectionSavesProductionLots
	|	AND NOT TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentCorrections AS ReversingDocuments
	|			
	|			LEFT JOIN Document.BackflushProduction AS CorrectionAttributes
	|			ON CorrectionAttributes.Ref = ReversingDocuments.Recorder
	|			
	|		WHERE
	|			ReversingDocuments.CorrectedDocument = DocumentAttributes.Ref
	|			AND NOT ISNULL(CorrectionAttributes.CorrectionSavesProductionLots, FALSE)
	|		)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.BackflushProduction";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref        AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentAttributes
	|	ON UpdatedData.Ref = DocumentAttributes.Ref
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = 0;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				DocumentObject.CorrectionSavesProductionLots = True;
				ObjectModified = True;
			EndIf;
			
			ExceptionReason = 2; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = 2 Then
				Raise NStr("vi = 'Không thể xử lý cập nhật chứng từ ""Sản xuất không theo đơn đặt hàng"".';
							|ru = 'Не удалось обработать обновление документов ""Производство без заказа"".';
							|en = 'Cannot process the update of the ""Backflush production"" documents.'; fa = 'Cannot process the update of the ""Backflush production"" documents.';
							|it = 'Cannot process the update of the ""Backflush production"" documents.';
							|pl = 'Cannot process the update of the ""Backflush production"" documents.';
							|tr = '""Geriye dönük üretim"" belgelerinin güncellenmesi işlenemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
