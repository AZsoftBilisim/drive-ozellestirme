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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
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
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("Purchases");
	ReceiptOfGoodsFromCustodianLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReceiptOfGoodsFromCustodian") Then
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
		
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTablePurchaseOrders(Query, QueryTexts, Registers);
		ReceiptOfGoodsFromCustodianLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
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

// Adds the command to create the document "receipt of goods from the Keeper".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
Function AddCreateCommandBasedOnReceiptFromKeeper(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Handler =        "GenerationByReferenceTMClient.ReceiptOfGoodsFromCustodianToCreateOnBasisOfOrder";
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Tiếp nhận hàng hóa từ bên cất giữ';
														|ru = 'Поступление товаров от хранителя';
														|en = 'VMI return'; fa = 'برگشت VMI';
														|it = 'Arrivo di merci dal consegnatario';
														|pl = 'Wpływ towarów od magazyniera';
														|tr = 'Malların VMI''dan teslim alınması'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferToCustodyWithRightOfSale";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command to create a document "Receipt of goods from a commission agent".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
Function AddCreateCommandBasedOnReceiptFromCommissionAgent(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Handler =        "GenerationByReferenceTMClient.ReceiptOfGoodsFromCommissionAgentToCreateOnBasisOfOrder";
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi';
														|ru = 'Поступление товаров от комиссионера';
														|en = 'Receipt of goods from consignee'; fa = 'Receipt of goods from consignee';
														|it = 'Ricezione articoli dal commissionario';
														|pl = 'Przyjęcia towarów od komisanta';
														|tr = 'Malların konsinyeden teslim alınması'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSalesCommission";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "receipt of goods from the Keeper".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
//
Function AddCreateCommandBasedOnReturnFromProcessor(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		HandlerName = "ProcessingByThirdPartiesClient.ReceiptOfGoodsFromCustodianOperationReturnFromProcessorToCreateOnBasisOf";
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = "CreateRefundFromProcessor";
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Nhận trả lại nguyên liệu từ người nhận gia công';
														|ru = 'Возврат сырья от переработчика';
														|en = 'Goods return — Subcontracting services received'; fa = 'Goods return — Subcontracting services received';
														|it = 'Reso delle materie prime dal subfornitore';
														|pl = 'Zwrot surowca od przetwórcy';
														|tr = 'Fason üreticiden hammadde iadesi'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductionByThirdParty2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "receipt of goods from the Keeper".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
//
Function AddCreateCommandBasedOnReceiptFromProcessor(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		HandlerName = "ProcessingByThirdPartiesClient.ReceiptOfGoodsFromCustodianOperationReceiptFromProcessorToCreateOnBasisOf";
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = "CreateReceiptFromProcessor";
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Tiếp nhận từ người nhận gia công';
														|ru = 'Поступление от переработчика';
														|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
														|it = 'Ricezione dal subfornitore';
														|pl = 'Wpływ od przetwórcy';
														|tr = 'Fason üreticiden gelen ürünleri teslim alma'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductionByThirdParty2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a Command to create a document "Receipt of goods from the custodian" based on the "Transfer to the giver".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
//
Function AddCommandToCreateBasedOnTransferToGiver(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		CreateBasedOnCommand                     = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Tiếp nhận từ người nhận gia công';
														|ru = 'Поступление от переработчика';
														|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
														|it = 'Ricezione dal subfornitore';
														|pl = 'Wpływ od przetwórcy';
														|tr = 'Fason üreticiden gelen ürünleri teslim alma'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCompaniesAndProductionByThirdParty25";
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreateBasedOnCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToMaterialProvider2_5);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a Command to create a document "Receipt of goods from the custodian" based on the "Return to the giver".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
//
Function AddCommandToCreateBasedOnReturnToGiver(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		CreateBasedOnCommand                     = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Nhận hàng gia công bị trả lại';
														|ru = 'Возврат от переработчика';
														|en = 'Pick up materials from subcontractor'; fa = 'Pick up materials from subcontractor';
														|it = 'Restituzione da subfornitore';
														|pl = 'Zwrot od przetwórcy';
														|tr = 'Malzemelerin fason üreticiden geri alınması'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCompaniesAndProductionByThirdParty25";
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreateBasedOnCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
		
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
	
	OperationSettings = New Map;
	OperationSettings.Insert(
		Enums.BusinessTransactions.ReturnFromCustodian,
		GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance"));
	OperationSettings.Insert(
		Enums.BusinessTransactions.ReturnFromCommissionAgent,
		GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance"));
	OperationSettings.Insert(
		Enums.BusinessTransactions.ReceiptFromToller2_5,
		GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5"));
	OperationSettings.Insert(
		Enums.BusinessTransactions.ReturnFromProcessingCompany2_5,
		GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5"));	
	For Each SettingUpOperation In OperationSettings Do
		
		If Not SettingUpOperation.Value Then
			Continue;
		EndIf;
		
		BusinessOperation = SettingUpOperation.Key;
		
		Command = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
		If Command <> Undefined Then
				
			AttachableCommands.AddCommandVisibilityCondition(
				Command, "BusinessOperation", BusinessOperation);
			
			Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
			Command.Presentation = Handler.ReportFormHeader();
			
		EndIf;
		
	EndDo;
	
	Command = Documents.TransferOfGoodsToBailee.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReturnFromCustodian);
	EndIf;
	Command = Documents.SubcontractorReport2_5.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReceiptFromToller2_5);
	EndIf;
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ReceiptOfGoodsFromCustodianLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterials22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterialsForStage22));
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
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"OrderFulfillment",
			True,
			"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in all warehouses
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"SecuringOrdersAllWarehouses",
			True,
			"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	DocumentProcessingProcedure.OrderDetailsName = "ByReferences";
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region SetOfSeries

//Names of the details that the parameters for specifying the series depend on.
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
	SeriesSpecificationParameters.FullObjectName = "Document.ReceiptOfGoodsFromCustodian";
	
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceiptFromVendor);
	Else
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer);
	EndIf;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	
	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
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
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	Goods.Count AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	ProductsRecordingAsReceived,
	|	CharacteristicRecordingAsReceived,
	|	Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	ProductsRecordingAsReceived,
	|	CharacteristicRecordingAsReceived,
	|	Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	SetOfSeries.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Count AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	SetOfSeries.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	SetOfSeries.Purpose AS Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.ProductsRecordingAsReceived,
	|	SetOfSeries.CharacteristicRecordingAsReceived,
	|	SetOfSeries.Purpose
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	ProductsRecordingAsReceived,
	|	CharacteristicRecordingAsReceived,
	|	Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|				WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|					THEN 14
	|				ELSE 13
	|			END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|		AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|				WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|				AND ProductsToRequest.Count > 0
	|					THEN 10
	|				ELSE 9
	|			END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|				WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|				AND ProductsToRequest.Count > 0
	|					THEN 8
	|				ELSE 7
	|			END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|		AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|		OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|		AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByReturnFromCustomer
	|			THEN CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|					THEN CASE
	|						WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|						AND ProductsToRequest.Count > 0
	|							THEN 4
	|						ELSE 3
	|					END
	|				ELSE CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|					AND ProductsToRequest.Count > 0
	|						THEN 2
	|					ELSE 1
	|				END
	|			END
	|		ELSE 0
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|			WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|				THEN CASE
	|					WHEN (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods)
	|					OR (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent)
	|					OR ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|					AND &BusinessOperation IN
	|					(VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|						VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|						THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 18
	|							ELSE 17
	|						END
	|					ELSE 0
	|				END
	|			ELSE 0
	|		END
	|	END AS BatchesIndicationStatusOfGoodsTransferred
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|		AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		AND Goods.ProductsRecordingAsReceived = ProductsToRequest.ProductsRecordingAsReceived
	|		AND Goods.CharacteristicRecordingAsReceived = ProductsToRequest.CharacteristicRecordingAsReceived
	|		AND Goods.Purpose = ProductsToRequest.Purpose
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|		AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|		AND ProductsToRequest.ProductsRecordingAsReceived = SeriesToRequest.ProductsRecordingAsReceived
	|		AND ProductsToRequest.CharacteristicRecordingAsReceived = SeriesToRequest.CharacteristicRecordingAsReceived
	|		AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		AND BatchAccountingPolicies.Warehouse = &Warehouse
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
	|	OR Statuses.BatchesIndicationStatusOfGoodsTransferred <> Statuses.OldStatusOfSpecifyingSeriesOfTransferredGoods
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion

#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.ReceiptOfGoodsFromCustodian, DocumentRef.ReceiptOfGoodsFromCustodian - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Contract,
		|Partner,
		|Ref,
		|Date,
		|DateOfReceipt,
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department,
		|Patch,
		|CorrectedDocument");
	
	If ObjectAttributes.Ref <> Undefined And ObjectAttributes.Patch Then
		Attributes = AttributesOfControlledLotReference(ObjectAttributes.CorrectedDocument, FieldNameControlledLotReference);
		Return Attributes;
	EndIf;
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Partner;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,ProductsRecordingAsReceived,Damage";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	CASE
		|		WHEN Table.Damage
		|			THEN Table.ProductsRecordingAsReceived
		|		ELSE Table.Products
		|	END AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return ReceiptOfGoodsFromCustodianLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables that are required for reflection
//	in regulated accounting.
//
// Returns:
//  String - The text of the request for the temporary reflection table in the regl accounting
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ReceiptOfGoodsFromCustodianLocalization.RequestTextTTReflectedInLocalAccounting();
	
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

#Region FillType

// Creates a structure for creating the receipt of goods from the custodian.
//
// Parameters:
//  ReferencesArrray - Array - contains a link to a request for the return of goods from the client
//  OrderProperties_ - Structure - service structure for common mechanisms
//
// Returns:
//  Structure - Details of the header for filling in the receipt of goods from the custodian.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	BusinessTransactionInvoice = Undefined;
	If OrderProperties_ = Undefined
	 Or Not OrderProperties_.Property("EconomicOperationOfBillOfLading", BusinessTransactionInvoice)
	 Or Not ValueIsFilled(BusinessTransactionInvoice) Then
		BusinessTransactionInvoice = Enums.BusinessTransactions.ReturnFromCustodian;
	EndIf;

	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessTransactionInvoice);
	
	Query = New Query;
	Query.Text = Handler.QueryTextInvoiceFillingData();
	Query.SetParameter("OrderDocument", ReferencesArrray[0]);
	Query.SetParameter("BusinessOperation", BusinessTransactionInvoice);
	
	HeaderAttributes = New Structure;
	
	Result = Query.Execute();
	For Each Column In Result.Columns Do
		HeaderAttributes.Insert(Column.Name);
	EndDo;
	
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(HeaderAttributes, Selection);
	EndIf;
	
	Return HeaderAttributes;
	
EndFunction

// Returns parameters for filling in the document for refund requests and receipt orders.
//
// Returns:
//	Structure - Parameters for filling in the document.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",     Undefined);
	FillParameters.Insert("FormIsOpen",      False);
	FillParameters.Insert("FillByWarehouseDocument", False);
	
	FillParameters.Insert("AddSeriesOnRequest", False);
	FillParameters.Insert("RegistrationViaRM",        False);
	
	FillParameters.Insert("DiscrepancyCertificate",      Documents.DiscrepancyReportFollowingReceipt.EmptyRef());
	FillParameters.Insert("BasisOfAct",         Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	FillParameters.Insert("Organization",           Catalogs.Companies.EmptyRef());
	FillParameters.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	FillParameters.Insert("Warehouse",                 Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("Department",         Catalogs.BusinessStructure.EmptyRef());
	
	FillParameters.Insert("FieldNameOrder", "ReferenceOrder");
	FillParameters.Insert("KeyFields", "");
	
	Return FillParameters;
	
EndFunction

// Generates the parameters necessary to verify the entry of the invoice based on orders.
// See GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder
//
// Parameters:
//  References - Array - list of orders on the basis of which the invoice is issued
//  BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued.
//
// Returns:
//  Structure - data for input verification.
//
Function DataForInputValidationBasedOn(References, BusinessOperation = Undefined) Export
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	
	DataToEnter = New Structure("Basis, Status, InstructionsForRegistration, ThereIsShip, CanBeGrouped");
	DataToEnter.ThereIsShip = False;
	DataToEnter.CanBeGrouped = True;
	DataToEnter.Insert("RegistrationViaRM", False);
	DataToEnter.Insert("Warehouse");
	DataToEnter.Insert("BusinessOperation");
	DataToEnter.Insert("EconomicOperationOfBillOfLading");
	DataToEnter.Insert("RegisterNameOrder");
	DataToEnter.EconomicOperationOfBillOfLading = BusinessOperation;
	DataToEnter.RegisterNameOrder                          = Handler.RegisterNameOrder();
	
	Query = New Query;
	Query.Text = Handler.QueryTextDataForInputValidationBasedOn();
	Query.SetParameter("References", References);
	Query.SetParameter("Recorder", Undefined);
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	If Selection.Next() Then
		If Selection.Count() = 1 Then
			DataToEnter.Basis     = Selection.Basis;
			DataToEnter.Status        = Selection.Status;
		EndIf;
		DataToEnter.RegistrationViaRM     = Selection.RegistrationViaRM;
		DataToEnter.Warehouse                 = Selection.Warehouse;
		DataToEnter.BusinessOperation = Selection.BusinessOperation;
		DataToEnter.ThereIsShip         = Not Result[1].IsEmpty();
	EndIf;
	
	ToRegister = Result[Result.UBound()].Unload();
	DataToEnter.InstructionsForRegistration = ToRegister.UnloadColumn("InstructionsForRegistration");
	
	Return DataToEnter;
	
EndFunction

// Returns an array containing the passed invoice, as well as:
// A. an Order from an array of orders (if there is one element in the array)
// B. All orders that fit the selection by header details.
//
// Parameters:
//  Invoice		 - DocumentRef.ReceiptOfGoodsFromCustodian -
//  HeaderAttributes	 - Structure - It must contain the keys Organization, Warehouse,
//  								Transaction, business Operation, and direction of Activity.
//
// Returns:
//  Array - an array of documents is ordered for internal use, ordered for repair.
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	Query = New Query();
	Query.SetParameter("Recorder",               Invoice);
	Query.SetParameter("AnArrayOfOrders",             New Array);
	
	Query.SetParameter("Organization",               HeaderAttributes.Organization);
	Query.SetParameter("Warehouse",                     HeaderAttributes.Warehouse);
	Query.SetParameter("Partner",                   HeaderAttributes.Partner);
	Query.SetParameter("Counterparty",                HeaderAttributes.Counterparty);
	Query.SetParameter("Contract",                   HeaderAttributes.Contract);
	Query.SetParameter("Terms",                HeaderAttributes.Terms);
	Query.SetParameter("SalesOpportunity",                    HeaderAttributes.SalesOpportunity);
	Query.SetParameter("Currency",                    HeaderAttributes.Currency);
	Query.SetParameter("LineOfBusiness",   HeaderAttributes.LineOfBusiness);
	Query.SetParameter("ToReturnReusablePackage", HeaderAttributes.ToReturnReusablePackage);
	
	QueryTexts = New Array;
	
	QueryText =
		"SELECT ALLOWED
		|	&Recorder AS ReferenceOrder
		|";
	QueryTexts.Add(QueryText);
	
	Handler = ActionHandler(HeaderAttributes.BusinessOperation);
	
	QueryText =
		Handler.QueryTextWaybillOrders(TMCommonUse.ParametersOfRequestTextForOrdersInvoices());
	
	If ValueIsFilled(QueryText) Then
		QueryTexts.Add(QueryText);
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Return Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	
EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	Return "Organization, Partner, Counterparty, Terms, Contract, Warehouse, SalesOpportunity,
			|Department, LineOfBusiness, GoodsReceiptOption";
	
EndFunction

// Returns a list of details by which tables are compared when filling in orders/orders
// 
// Returns:
// 	String
//
Function KeyFieldsOfGoodsTable() Export
	
	Return "Products, Characteristic, ProductsRecordingAsReceived, CharacteristicRecordingAsReceived, Purpose, Series";
	
EndFunction

// Initializes parameters populate the document according to the document.
//
// Parameters:
//	FillParameters	 - Structure	 - the fill settings of the default document.
//	HeaderAttributes		 - Structure	 - document data that will be used for filling in parameters.
//	AnArrayOfOrders		 - Array		 - links to applications that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders			= AnArrayOfOrders;
	FillParameters.HeaderAttributes			= HeaderAttributes;
	FillParameters.Organization				= HeaderAttributes.Organization;
	FillParameters.Warehouse					= HeaderAttributes.Warehouse;
	
	Handler = ActionHandler(HeaderAttributes.BusinessOperation);
	FillParameters.KeyFields = Handler.KeyFieldsOfGoodsTable();
	
EndProcedure

// Returns the Goods table of the document receipt of goods from the Keeper.
//
// Parameters:
//	Invoice - DocumentRef.ReceiptOfGoodsFromCustodian - link to the document of receipt of goods from the custodian.
//
// Returns:
//	ValueTable - the tabular part of the document of receipt of goods from the custodian:
//	* LineNumber                - Number - 
//	* Products               - CatalogRef.Products - 
//	* Characteristic             - CatalogRef.ItemsCharacteristics - 
//	* ProductsRecordingAsReceived - CatalogRef.Products - 
//	* CharacteristicRecordingAsReceived - CatalogRef.ItemsCharacteristics - 
//	* Purpose                 - CatalogRef.Assignments - 
//	* Series                      - CatalogRef.ItemsBatches - 
//	* BatchesIndicationStatus        - Number - 
//	* Package                   - CatalogRef.PackagesAndUnitsOfMeasure - 
//	* Count                 - Number - 
//	* NoteQuantity          - Number - 
//	* NumberOfPackages         - Number - 
//	* Price                       - Number - 
//	* CCDNumber                   - CatalogRef.CCDNumbers - 
//	* ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - 
//
Function TableDataAndDocument(Invoice) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.Damage AS Damage,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	Table.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Price AS Price,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.RowCode AS RowCode
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS Table
	|WHERE
	|	Table.Ref = &Invoice";
	
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Fills in the document of receipt of goods from the custodian according to the selected order.
//
// Parameters:
//  Object              - DocumentObject.ReceiptOfGoodsFromCustodian - document of receipt of goods from the custodian.
//  FillParameters - Structure - the fill settings of the default document.
//
Procedure FillInHeaderOfOrderDocument(Object, FillParameters) Export
	
	FillPropertyValues(Object, FillParameters.HeaderAttributes);
	
	If FillParameters.AnArrayOfOrders <> Undefined
		And FillParameters.AnArrayOfOrders.Count() = 1 Then
		Object.DocumentBasis = FillParameters.AnArrayOfOrders[0];
	EndIf;
	
	References = Object.Goods.Unload(, "ReferenceOrder");
	References.GroupBy("ReferenceOrder");
	
	If References.Count() > 1
		Or References.Count() = 1
			And ValueIsFilled(References[0].ReferenceOrder) Then
		Object.ByReferences = True;
	EndIf;
	
	If Object.ByReferences
		And TypeOf(References[0].ReferenceOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		Object.PriceKind = PriceViewFromTablePart(References);
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
		Object.PriceKind = PriceViewFromTablePart(Object.DocumentBasis);
	EndIf;
	
EndProcedure

// Fills in the user's to-do list.
// Parameters: 
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	Enabled =
		GetFunctionalOption("UseProductionByThirdParty2_5")
		And (CommonQueryParameters.IsFullUser
			Or (AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian)
				And AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)));
	
	If Not Enabled Then
		Return;
	EndIf;
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(,,,
			Enums.BusinessTransactions.ReceiptFromToller2_5,
			CommonQueryParameters.User);
	
	QueriesTexts =
		DataProcessors.DocumentsOfTransferToTollingAll2_5.QueriesTexts(
			FilterParameters,
			Enums.BusinessTransactions.ReceiptFromToller2_5);
	
	Query = New Query(QueriesTexts.StatusCalculationQueryText);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("BusinessTransaction",       Enums.BusinessTransactions.ReceiptFromToller2_5);
	Query.SetParameter("Manager",          CommonQueryParameters.User);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	Result = Query.Execute().Select().Count();
	
	UserTaskParent = ToDoList.Find("ProductionByThirdParty", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "ProductionByThirdParty";
		UserTaskParent.Presentation  = NStr("vi = 'Sản xuất bên ngoài';
											|ru = 'Производство на стороне';
											|en = 'Production by third party'; fa = 'تولید توسط شخص ثالث';
											|it = 'Produzione esterna';
											|pl = 'Produkcja postronna';
											|tr = 'Tarafına üretim'");
		UserTaskParent.Owner       = Metadata.Subsystems.Production;
	EndIf;
	
	UserTaskParent.HasToDoItems =
		UserTaskParent.HasToDoItems
		Or Result > 0;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Warehouse",        Catalogs.Warehouses.EmptyRef());
	FilterParameters.Insert("Manager",     CommonQueryParameters.User);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("CurrentPageName",      "PageReceipts");
	FormParameters.Insert("FormAssignmentKey",     "ToDoList");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ReceiptFromProcessorForRegistration2_5";
	ToDoItem.HasToDoItems       = Result > 0;
	ToDoItem.Presentation  = NStr("vi = 'Tiếp nhận từ người nhận gia công để lập chứng từ';
									|ru = 'Поступления от переработчика к оформлению';
									|en = '""Goods receipt — Subcontracting services received"" for registration'; fa = '""Goods receipt — Subcontracting services received"" for registration';
									|it = 'Ricezione dall''elaboratore per formalizzazione';
									|pl = 'Wpływy od przetwórcy do rejestracji';
									|tr = 'Fason üreticiden işlem için teslim alım'");
	ToDoItem.Count     = Result;
	ToDoItem.Important         = False;
	ToDoItem.Form          = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices";
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ProductionByThirdParty";
	
	Return;
	
EndProcedure

// Fills in the table part of the document for orders and warehouse orders.
//
// Parameters:
//	Goods				 - ValueTable - table part of the document of receipt of goods from the custodian.
//	Recorder			 - DocumentRef.ReceiptOfGoodsFromCustodian - link to the document of receipt of goods from the custodian.
//	FillParameters	 - Structure - Parameters for filling in the document.
//  PackageBarcodes	 - Undefined - not used for this document
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	FilterByWarehouse     = ValueIsFilled(FillParameters.Warehouse);
	SelectionByCCDNumbers = (FillParameters.AnArrayOfOrders <> Undefined
							And TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.TransferOfGoodsToBailee"))
						Or ValueIsFilled(FillParameters.DiscrepancyCertificate);
	
	// If you do not need to fill in an order, we pass empty query parameters - an empty table will be returned for orders.
	If FillParameters.FillByWarehouseDocument Then
		ReferencesForOrders = FillParameters.AnArrayOfOrders;
		RegistrarForOrders  = Recorder;
	Else
		ReferencesForOrders = Undefined;
		RegistrarForOrders  = Undefined;
	EndIf;
	
	Handler =
		Documents.ReceiptOfGoodsFromCustodian.ActionHandler(
			FillParameters.HeaderAttributes.BusinessOperation);
	
	// Orders
	
	// 1. According to the orders
	QueryTexts = New Array;
	
	Filter = New Structure(Handler.NameDimensionOrder(), "References");
	If FilterByWarehouse Then
		Filter.Insert("Warehouse", "Warehouse");
	EndIf;
	
	QueryTexts.Add(Handler.QueryTextRemnantsOfGoodsForRegistration("TTAccountingData", Filter));
	
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "Table.Ref", "&References");
	If FilterByWarehouse
		And (FillParameters.AnArrayOfOrders <> Undefined
							And TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")) Then
		TMCommonUse.AddSelectionItemToCollection(Filter, "Table.Warehouse", "&Warehouse");
	EndIf;	
	
	QueryTexts.Add(
		Handler.RequestTextAndOrderDocument(
			Filter,
			FillParameters.AddSeriesOnRequest));
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	QueryText = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(QueryText, True);
	
	TempTablesManager = New TempTablesManager();
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = QueryText;
	
	Query.SetParameter("Recorder",  Recorder);
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	
	If FilterByWarehouse Then
		Query.SetParameter("Warehouse", FillParameters.Warehouse);
	EndIf;
	
	OrdersTable = Query.Execute().Unload();
	If ValueIsFilled(FillParameters.AnArrayOfOrders)
		And TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.SubcontractOrder2_5") Then
		FillInSeriesAccordingToReportsOfProcessor(OrdersTable, TempTablesManager, Recorder);
	EndIf;
	OrderToSupplierColumn = OrdersTable.Columns.PurchaseOrder; // ValueTableColumn
	OrderToSupplierColumn.Name = "ReferenceOrder";
	
	If Not Handler.UseLineCode() Then
		OrdersTable.Columns.Add("Allocated", New TypeDescription("Boolean"));
		OrdersTable.FillValues(False, "Allocated");
		
		If ValueIsFilled(FillParameters.KeyFields) Then
			TheStructureOfTheSearch = New Structure(FillParameters.KeyFields + ", Allocated");
		Else
			TheStructureOfTheSearch = New Structure(Handler.KeyFieldsOfGoodsTable() + ", Allocated");
		EndIf;
		
		LinesToDelete = New Array;
		
		For Each ValueTableRow In OrdersTable Do
			If ValueTableRow.Allocated Then
				Continue;
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, ValueTableRow);
			QuantityToDistribution = ValueTableRow.ToRegister;
			FoundRows = OrdersTable.FindRows(TheStructureOfTheSearch);
			
			For Each FoundRow In FoundRows Do
				If QuantityToDistribution = 0 Then  
					If LinesToDelete.Find(FoundRow) = Undefined Then
						LinesToDelete.Add(FoundRow);
					EndIf;
					
				ElsIf (FoundRow.Count >= QuantityToDistribution) Then
					FoundRow.Count   = QuantityToDistribution;
					FoundRow.ToRegister  = QuantityToDistribution;
					FoundRow.Allocated = True;
					QuantityToDistribution     = QuantityToDistribution - FoundRow.ToRegister;
					
				Else
					FoundRow.ToRegister  = FoundRow.Count;
					FoundRow.Allocated = True;
					QuantityToDistribution     = QuantityToDistribution - FoundRow.ToRegister;
				EndIf;
			EndDo;
		EndDo;
		
		TMCommonUse.DeleteTableRows(OrdersTable, LinesToDelete);
	EndIf;
	
	OrdersTable.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	
	// 2. On transfers to the keeper
	
	TransferTable = OrdersTable.CopyColumns();
	
	If FillParameters.AnArrayOfOrders <> Undefined
		And (TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.TransferOfGoodsToBailee")
			Or FillParameters.HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
			Or FillParameters.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent) Then
		
		FilterByCCDType = False;
		
		If FillParameters.HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			FilterByCCDType = Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(
								FillParameters.HeaderAttributes.Terms);
		EndIf;
		
		JoinText = "Table.ItemsLocationAttributesGoodsAtPartners = DataOfAccounting.ItemsLocationAttributes
							| AND Table.CCDNumber = DataOfAccounting.CCDNumber";
		
		If FilterByCCDType Then
			JoinText = "Table.ItemsLocationAttributesGoodsAtPartners = DataOfAccounting.ItemsLocationAttributes";
		EndIf;
		
		ConnectionVerificationText = "NOT DataOfAccounting.ItemsLocationAttributes IS NULL";
		
		If TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			ProductAccountingAnalysts = AnalysisOfProductItemAccountingForCommissionRefund(FillParameters.AnArrayOfOrders);
		Else
			ProductAccountingAnalysts = AnalysisOfAccountingOfProductRangeForTransferOfGoodsToCustodian(FillParameters.AnArrayOfOrders);
		EndIf;
		
		QueryTexts = New Array;
		
		QueryTexts.Add(
			Documents.TransferOfGoodsToBailee.RequestTextRequirementsForRegistrationForTransfers("TTAccountingData"));
		
		Filter = New Map;
		If FillParameters.HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
			And TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.SubcontractOrder2_5") Then
			TMCommonUse.AddSelectionItemToCollection(Filter, "Table.SalesOrder", "&References");
		Else
			TMCommonUse.AddSelectionItemToCollection(Filter, "Table.Ref", "&References");
		EndIf;
		QueryTexts.Add(
			Documents.TransferOfGoodsToBailee.QueryTextDocumentGoods(
				Filter,
				JoinText,
				ConnectionVerificationText));
		
		Query = New Query;
		If Common.DebugMode() Then
			Query.TempTablesManager = New TempTablesManager();
		EndIf;
		
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
		Query.SetParameter("Recorder",  Recorder);
		Query.SetParameter("References", FillParameters.AnArrayOfOrders);
		Query.SetParameter("ProductAccountingAnalysts", ProductAccountingAnalysts);
		Query.SetParameter("CommissionAgentUsesInventoryAccountingByProductBatchID", FilterByCCDType);
		
		If FilterByWarehouse Then
			Query.SetParameter("Warehouse", FillParameters.Warehouse);
		EndIf;
		
		TransferTable = Query.Execute().Unload();
		
	EndIf;
	
	// 3. On the acts of discrepancies
	
	QueryTexts = New Array;
	
	QueryTexts.Add(TextOfRequestIsReadyForRegistrationByActs("TTAccountingData", Handler.UseLineCode()));
	
	Filter = New Map;
	Filter.Insert("DataOfAccounting.DocumentBasis", "DocumentInflow");
	
	JoinText =
		" Table.Ref = DataOfAccounting.DocumentBasis
		| AND Table.ReferenceOrder = DataOfAccounting.ReferenceOrder
		| AND Table.CCDNumber = DataOfAccounting.CCDNumber
		|";
	
	If Handler.UseLineCode() Then
		JoinText =
			JoinText +
			"AND Table.RowCode = DataOfAccounting.RowCode";
	Else
		JoinText =
			JoinText +
			" AND Table.Products = DataOfAccounting.Products
			| AND Table.Characteristic = DataOfAccounting.Characteristic
			| AND Table.Purpose = DataOfAccounting.Purpose";
	EndIf;
	
	QueryTexts.Add(QueryTextDocumentGoods(Filter, JoinText, Handler.UseLineCode()));
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());;
	
	Query.SetParameter("DocumentInflow", FillParameters.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",    FillParameters.DiscrepancyCertificate);
	
	If FilterByWarehouse Then
		Query.SetParameter("Warehouse", FillParameters.Warehouse);
	EndIf;
	
	TableReportsOfDiscrepancies = Query.Execute().Unload();
	
	If ValueIsFilled(FillParameters.DiscrepancyCertificate) Then
		OrdersTable.Clear();
	EndIf;
	
	// 4. According to the reports of the processor
	
	TableProcessorReports = OrdersTable.CopyColumns();
	
	If FillParameters.AnArrayOfOrders <> Undefined
		And TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.SubcontractorReport2_5") Then
		
		Query = New Query;
		If Common.DebugMode() Then
			Query.TempTablesManager = New TempTablesManager();
		EndIf;
		
		Query.Text = Documents.SubcontractorReport2_5.RequestTextBalancesForReceiptBasedOnProcessorReports();
		
		Query.SetParameter("Recorder",  Recorder);
		Query.SetParameter("References", FillParameters.AnArrayOfOrders);
		
		TableProcessorReports = Query.Execute().Unload();
		
	EndIf;
	// Addition of the order table
	CommonClientServer.SupplementTable(TransferTable, OrdersTable);
	CommonClientServer.SupplementTable(TableReportsOfDiscrepancies, OrdersTable);
	CommonClientServer.SupplementTable(TableProcessorReports, OrdersTable);
	ColumnToDesign = OrdersTable.Columns.ToRegister; // ValueTableColumn
	ColumnToDesign.Name = "QuantityInOrder";
	
	// Orders_3
	Filter = New Map;
	If FilterByWarehouse Then
		TMCommonUse.AddSelectionItemToCollection(Filter, "Warehouse", "&Warehouse", "=");
	EndIf;
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Query.Text =
		AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders(
			False, Filter);
	
	Query.SetParameter("Recorder",  RegistrarForOrders);
	Query.SetParameter("References", ReferencesForOrders);
	
	If FilterByWarehouse Then
		Query.SetParameter("Warehouse", FillParameters.Warehouse);
	EndIf;
	
	TableOrders = Query.Execute().Unload();
	
	If TableOrders.Count() > 0 And ValueIsFilled(Recorder) Then
		DocumentAttributes = Common.ObjectAttributesValues(Recorder, "ByReferences, ReferenceOrder");
		If DocumentAttributes.ByReferences
			And ValueIsFilled(DocumentAttributes.ReferenceOrder) Then
			For Each OrderLine_1 In TableOrders Do
				If Not ValueIsFilled(OrderLine_1.ReferenceOrder) Then
					OrderLine_1.ReferenceOrder = DocumentAttributes.ReferenceOrder;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If FillParameters.FillByWarehouseDocument
		And ValueIsFilled(FillParameters.AnArrayOfOrders)
		And TypeOf(FillParameters.AnArrayOfOrders[0]) = Type("DocumentRef.SubcontractOrder2_5") Then
		
		// We are sending a copy of the order table, since the selected amount must be reset in the algorithm,
		// and it will be used further.
		FillInSeriesOfOrdersAccordingToOrderTable(OrdersTable, TableOrders.Copy());
		
	EndIf;
	ColumnQuantity = TableOrders.Columns.Count; // ValueTableColumn
	ColumnQuantity.Name = "NoteQuantity";
	
	// Distribution of the resulting tables
	Var_Key = FillParameters.KeyFields;
	If SelectionByCCDNumbers Then
		Var_Key = Var_Key + "," + " CCDNumber";
	EndIf;
	
	If Handler.UseLineCode() Then
		Var_Key = Var_Key + ", RowCode";
	EndIf;
	
	Goods.Indexes.Add(Var_Key);
	
	// Adding the number of orders
	Condition = "On [Count]";
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
	// Adding the number of orders.
	Var_Key = FillParameters.KeyFields;
	
	// There are invoices and orders
	Condition = "[Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are orders, no invoices
	Condition = "NOT [Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are invoices, no orders
	Condition = "[Count], NOT [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
	
EndProcedure

// Binds the rows of the Products table to customer orders.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Object - FormDataStructure, DocumentObject.ReceiptOfGoodsFromCustodian - 
//  SeriesSpecificationParameters - See ProductsServer.FillInStatusesForSpecifyingSeries.SeriesSpecificationParameters
//  SelectByOrder_ - Boolean - 
//
Procedure LinkRowsToOrders(Form, Object, SeriesSpecificationParameters, SelectByOrder_) Export
	
	If Not Form.UseOrders
		Or (Not Form.UseReceiptForMultipleOrders
			And Not ValueIsFilled(Object.ReferenceOrder)) Then
		Return;
	EndIf;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Object.BusinessOperation);
	
	QueryTexts = New Array;
	
	QueryText =
	"SELECT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|";
	
	QueryTexts.Add(QueryText);
	
	RequestTextParameters = TMCommonUse.ParametersOfRequestTextForOrdersInvoices();
	RequestTextParameters.GenerateTT = True;
	RequestTextParameters.TTName = "WaybillOrders";
	
	If SelectByOrder_ Then
		TMCommonUse.AddSelectionItemToCollection(
			RequestTextParameters.Filter,
			"Ref",
			"&ReferenceOrder",
			"=");
	EndIf;
	QueryTexts.Add(Handler.QueryTextWaybillOrders(RequestTextParameters));
	
	FilterByDimensions = New Map();
	
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		Handler.NameDimensionOrder(),
		"SELECT
		|	WaybillOrders.ReferenceOrder
		|FROM
		|	WaybillOrders AS WaybillOrders");
	
	TMCommonUse.AddSelectionItemToCollection(
		RequestTextParameters.Filter,
		"Warehouse",
		"&Warehouse",
		"=");
	
	QueryTexts.Add(Handler.QueryTextRemnantsOfGoodsForRegistration("GoodsForRegistration", FilterByDimensions));
	QueryTexts.Add(QueryTextDuplicatesOfProductsForRegistration());
	
	QueryText =
	"SELECT
	|	GoodsForRegistration.ReferenceOrder           AS ReferenceOrder,
	|	GoodsForRegistration.RowCode              AS RowCode,
	|	GoodsForRegistration.Products           AS Products,
	|	GoodsForRegistration.Characteristic         AS Characteristic,
	|	GoodsForRegistration.Purpose             AS Purpose,
	|	GoodsForRegistration.Series                  AS Series,
	|	GoodsForRegistration.ToRegister            AS ToRegister,
	|	0                                        AS Allocated,
	|	DuplicatesOfProductsForRegistration.DuplicateCount AS DuplicateCount
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|	
	|	LEFT JOIN DuplicatesOfProductsForRegistration AS DuplicatesOfProductsForRegistration
	|	ON GoodsForRegistration.Products = DuplicatesOfProductsForRegistration.Products
	|	AND GoodsForRegistration.Characteristic = DuplicatesOfProductsForRegistration.Characteristic
	|
	|ORDER BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic
	|";
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	ColumnsNames = "Products, Characteristic";
	TableOfGoods = Object.Goods.Unload(, ColumnsNames);
	
	Query.SetParameter("Recorder",                         Object.Ref);
	Query.SetParameter("ReferenceOrder",                        Object.ReferenceOrder);
	Query.SetParameter("Partner",                             Object.Partner);
	Query.SetParameter("Counterparty",                          Object.Counterparty);
	Query.SetParameter("Terms",                          Object.Terms);
	Query.SetParameter("Organization",                         Object.Organization);
	Query.SetParameter("Contract",                             Object.Contract);
	Query.SetParameter("Warehouse",                               Object.Warehouse);
	Query.SetParameter("Currency",                              Object.Currency);
	Query.SetParameter("SalesOpportunity",                              Object.SalesOpportunity);
	Query.SetParameter("LineOfBusiness",             Object.LineOfBusiness);
	Query.SetParameter("ToReturnReusablePackage",           Object.ReusablePackageReturn);
	Query.SetParameter("Goods",                              TableOfGoods);
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	If QueryResult[QueryResult.UBound() - 2].IsEmpty() Then
		Return;
	EndIf;
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("ReferenceOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	TableOfUnallocatedGoods.Columns.Add("Series");
	TableOfUnallocatedGoods.Columns.Add("Count");
	
	Selection = QueryResult[QueryResult.UBound()].Select();
	
	NamesOfPropertiesToFillIn = "ReferenceOrder, RowCode, Purpose";
	
	While Selection.Next() Do
		
		// First, we distribute taking into account the series, and then without.
		// Duplicates are processed only after an attempt to distribute without taking into account the series.
		For IndexOf = 0 To 1 Do
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("RowCode",      0);
			TheStructureOfTheSearch.Insert("Products",   Selection.Products);
			TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
			If IndexOf = 0 Then
				TheStructureOfTheSearch.Insert("Series",      Selection.Series);
			EndIf;
			
			FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
			RetainedQuantity = Selection.ToRegister;
			
			// If there are no duplicates, we distribute the order line to the invoice lines
			If Selection.DuplicateCount < 2 Then
				
				For Each CurRow In FoundRows Do
					
					FillPropertyValues(CurRow, Selection, NamesOfPropertiesToFillIn);
					
					RetainedQuantity = RetainedQuantity - CurRow.Count;
					
					If RetainedQuantity <= 0 Then
						Break;
					EndIf;
					
				EndDo;
				
			// If there are duplicates, we distribute the order lines according to the invoice lines, taking into account the quantity
			ElsIf IndexOf = 1 Then
				
				// On the first pass, we will fill in only if the quantity in the order line and the invoice match
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
		
	EndDo;
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then

		RowsToProcess = New Array;
		Cached_Values = Undefined;

		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		
		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			// First, we distribute taking into account the series, and then without.
			For IndexOf = 0 To 1 Do
				
				TheStructureOfTheSearch = New Structure();
				TheStructureOfTheSearch.Insert("ReferenceOrder",   Undefined);
				TheStructureOfTheSearch.Insert("RowCode",      0);
				TheStructureOfTheSearch.Insert("Products",   UnallocatedRow.Products);
				TheStructureOfTheSearch.Insert("Characteristic", UnallocatedRow.Characteristic);
				If IndexOf = 0 Then
					TheStructureOfTheSearch.Insert("Series",      UnallocatedRow.Series);
				EndIf;
				
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
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			Cached_Values);

	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//	Object				 - DocumentObject.ReceiptOfGoodsFromCustodian, FormDataStructure - the object that needs to be updated.
//	FillParameters	 - Structure - Parameters for filling in the document.
//
Procedure UpdateDependentDetailsOfTablePart(Object, FillParameters) Export
	
	RowsToProcess = New Array;
	ProcessedRowsWithPrice = New Array;
	ProcessedLinesWithPriceType = New Array;

	For Each String In Object.Goods Do
		If Not Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
			If ValueIsFilled(String.Price) Then

				ProcessedRowsWithPrice.Add(String);
				Continue;

			ElsIf ValueIsFilled(Object.PriceKind) Then

				ProcessedLinesWithPriceType.Add(String);
				Continue;

			EndIf;
		EndIf;
		RowsToProcess.Add(String);
		
	EndDo;

	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions.Insert("RecalculateAmount");

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsWithPrice,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesWithPriceType,
		StructureOfActions,
		Object.Goods,
		CachedValues);

EndProcedure

#EndRegion

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array of String - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Thu';
							|ru = 'Поступление';
							|en = 'Receipt'; fa = 'دریافت';
							|it = 'Arrivo';
							|pl = 'Receipt';
							|tr = 'Giriş'"));
	ReceiptOfGoodsFromCustodianLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames;
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

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("BusinessOperation");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ObjectPresentation = NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi';
									|ru = 'Поступление товаров от комиссионера';
									|en = 'Receipt of goods from consignee'; fa = 'Receipt of goods from consignee';
									|it = 'Ricezione articoli dal commissionario';
									|pl = 'Przyjęcia towarów od komisanta';
									|tr = 'Malların konsinyeden teslim alınması'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		ObjectPresentation = NStr("vi = 'Tiếp nhận từ bên nhận gia công';
									|ru = 'Поступление от переработчика';
									|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
									|it = 'Ricezione dal subfornitore';
									|pl = 'Wpływ od przetwórcy';
									|tr = 'Fason üreticiden gelen ürünleri teslim alma'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		ObjectPresentation = NStr("vi = 'Nhận trả lại nguyên liệu từ bên nhận gia công';
									|ru = 'Возврат сырья от переработчика';
									|en = 'Goods return — Subcontracting services received'; fa = 'Goods return — Subcontracting services received';
									|it = 'Reso delle materie prime dal subfornitore';
									|pl = 'Zwrot surowca od przetwórcy';
									|tr = 'Fason üreticiden hammadde iadesi'");
	Else
		ObjectPresentation = NStr("vi = 'Tiếp nhận hàng hóa từ bên cho thuê kho';
									|ru = 'Поступление товаров от хранителя';
									|en = 'VMI return'; fa = 'برگشت VMI';
									|it = 'Arrivo di merci dal consegnatario';
									|pl = 'Wpływ towarów od magazyniera';
									|tr = 'Malların VMI''dan teslim alınması'");
	EndIf;
	
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%1 %2 tarihli %3'"), ObjectPresentation, Data.Number, Data.Date);
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "ReceiptOfGoodsFromCustodian");
	
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
	|	DocumentData.ByReferences         AS ByReferences,
	|	DocumentData.ReferenceOrder            AS ReferenceOrder,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.Warehouse                   AS Warehouse,
	|	DocumentData.ControlledLotReference    AS ControlledLotReference,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.SalesOpportunity                  AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.Department           AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ReusablePackageReturn AS ReusablePackageReturn,
	|	DocumentData.IncomingDocumentDate  AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.GoodsReceiptOption   AS GoodsReceiptOption,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                   AS UseWarehouseManagemantSystemForGoodsReceipt,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS DocumentData
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
	MetadataIdentifier = Common.MetadataObjectID("Document.ReceiptOfGoodsFromCustodian");
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier", MetadataIdentifier);
	Query.SetParameter("NumberForPrinting",           NumberForPrinting);
	Query.SetParameter("ContractInformation",    ContractInformation);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                        AS Period,
	|	&BusinessOperation         AS BusinessOperation,
	|	&Organization                   AS Organization,
	|	&Department                 AS Department,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		ELSE TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
	|	END                          AS ItemsLocationAttributes,
	|	&Contract                       AS Warehouse,
	|	TableTypesOfStocks_.InventoryType  AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS InventoryOwnerAttribute,
	|	&LineOfBusiness       AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                          AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse       AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.CorInventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END                          AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.CorInventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END                          AS CorSourceOfItemsFinancialAccountingGroup,
	|	TableTypesOfStocks_.Count  AS Count,
	|	TableTypesOfStocks_.Count  AS CorQuantity,
	|	0                              AS Cost,
	|	0                              AS CostExcludingVAT,
	|	0                              AS LocalCost
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_";
	
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
	|	CASE
	|		WHEN SeriesTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN SeriesTable.Products
	|		ELSE SeriesTable.ProductsRecordingAsReceived
	|	END AS Products,
	|	CASE
	|		WHEN SeriesTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN SeriesTable.Characteristic
	|		ELSE SeriesTable.CharacteristicRecordingAsReceived
	|	END AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Partner AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfSender,
	|	&Warehouse AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt AS ThisIsWarehouseRecord
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN GoodsTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN GoodsTable.Products
	|		ELSE GoodsTable.ProductsRecordingAsReceived
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN GoodsTable.Characteristic
	|		ELSE GoodsTable.CharacteristicRecordingAsReceived
	|	END AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Partner,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Ref.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN
	|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.AcceptedOnReturns))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND CASE
	|		WHEN VALUETYPE(GoodsTable.ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
	|			THEN NOT CAST(GoodsTable.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|		ELSE TRUE
	|	END
	|	AND &ByReferences
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|		VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DimensionKeys.Products      AS Products,
	|	DimensionKeys.Characteristic    AS Characteristic,
	|	DimensionKeys.Series             AS Series,
	|	DimensionKeys.Purpose        AS Purpose,
	|	TableTypesOfStocks_.CCDNumber      AS CCDNumber,
	|	&Period                          AS DateOfReceipt
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.InventoryKinds AS TableTypesOfStocks_
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
	|	ON DimensionKeys.DimensionKey = TableTypesOfStocks_.ItemsLocationAttributes
	|	
	|	LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON UninvoicedReceipts.InventoryOwnerAttribute = TableTypesOfStocks_.CorInventoryOwnerAttribute
	|	AND UninvoicedReceipts.Products = DimensionKeys.Products
	|	AND UninvoicedReceipts.Characteristic = DimensionKeys.Characteristic
	|	AND UninvoicedReceipts.Series = DimensionKeys.Series
	|	AND UninvoicedReceipts.Purpose = DimensionKeys.Purpose
	|	AND UninvoicedReceipts.CCDNumber = TableTypesOfStocks_.CCDNumber
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND &BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5))
	|	AND (UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	GoodsTable.ReferenceOrder AS PurchaseOrder,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	0 AS Ordered,
	|	0 AS ToRegister,
	|	GoodsTable.Count AS ToReceive,
	|	0 AS Sum
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &ByReferences
	|	AND NOT GoodsTable.RowCode = 0
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	GoodsTable.ReferenceOrder AS PurchaseOrder,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	0 AS Ordered,
	|	0 AS ToRegister,
	|	GoodsTable.Count AS ToReceive,
	|	0 AS Sum
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &ByReferences
	|	AND GoodsTable.RowCode = 0
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	GoodsTable.ReferenceOrder AS PurchaseOrder,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	0 AS Ordered,
	|	0 AS ToRegister,
	|	GoodsTable.Count AS ToReceive,
	|	0 AS Sum
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &ByReferences
	|	AND GoodsTable.RowCode = 0
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5)";
	
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
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	CASE
	|		WHEN &TextOfExpressionReceiptByOrder
	|			THEN DataSource.ReferenceOrder
	|		ELSE UNDEFINED
	|	END                                        AS OrderDocument,
	|	DataSource.Ref                        AS Invoice,
	|	DataSource.Ref.Patch            AS Patch,
	|	DataSource.Ref.CorrectedDocument   AS CorrectedDocument,
	|	DataSource.Ref.Contract                AS Contract,
	|	DataSource.Ref.Terms             AS Terms,
	|	DataSource.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE DataSource.Products
	|	END AS Products,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE DataSource.Characteristic
	|	END AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference   AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|				VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			THEN FALSE
	|		WHEN &TextOfExpressionReceiptByOrder
	|			AND DataSource.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                        AS ExceedingOrder,
	|	DataSource.Ref.Warehouse                  AS Warehouse,
	|	DataSource.Ref.Partner                AS Sender,
	|	DataSource.Ref.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	&TextOfExpressionReceiptByOrder    AS ReceiptUnderOrders
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)";
	
	QueryTextDocument_ = StrReplace(QueryTextDocument_,
		"&TextOfExpressionReceiptByOrder",
		TextOfExpressionReceiptByOrder("DataSource"));
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
	// Arrival at an irregular warehouse or for old purposes.
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.ProductsRecordingAsReceived
	|		ELSE TabPart.Products
	|	END AS Products,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.CharacteristicRecordingAsReceived
	|		ELSE TabPart.Characteristic
	|	END AS Characteristic,
	|	TabPart.Ref.Warehouse AS Warehouse,
	|	TabPart.Purpose AS Purpose,
	|	&ControlledLotReference AS ControlledLotReference,
	|	TabPart.ToControlQuality AS ToControlQuality,
	|	TabPart.ToControlQuality AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	&TextOfExpressionReceiptByOrder AS OnSchedule,
	|	TabPart.ReferenceOrder AS OrderInSchedule
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS TabPart
	|WHERE
	|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
	|	OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE";
	
	QueryTextTabPart = StrReplace(QueryTextTabPart,
		"&TextOfExpressionReceiptByOrder",
		TextOfExpressionReceiptByOrder("TabPart"));
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
	// The reverse of the receipt order for the old appointments.
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.ProductsRecordingAsReceived
	|		ELSE TabPart.Products
	|	END AS Products,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.CharacteristicRecordingAsReceived
	|		ELSE TabPart.Characteristic
	|	END AS Characteristic,
	|	TabPart.Ref.Warehouse AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	FALSE AS ToControlQuality,
	|	FALSE AS SubjectToUnlocking,
	|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
	|	-TabPart.Count AS Count,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS TabPart
	|WHERE
	|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
	|	AND TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.ProductsRecordingAsReceived
	|		ELSE TabPart.Products
	|	END AS Products,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.CharacteristicRecordingAsReceived
	|		ELSE TabPart.Characteristic
	|	END AS Characteristic,
	|	TabPart.Ref.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE TabPart.Purpose
	|	END AS Purpose,
	|	TabPart.ToControlQuality AS ToControlQuality,
	|	TabPart.ToControlQuality AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	CASE
	|		WHEN &TextOfExpressionReceiptByOrder
	|		AND NOT TabPart.Ref.ReferenceOrder IN (UNDEFINED,
	|		VALUE(Document.SubcontractOrder2_5.EmptyRef),
	|		VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
	|		AND TabPart.Ref.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TabPart.Ref.ReferenceOrder
	|		ELSE CASE
	|			WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.ReceiptOfGoodsFromCustodian.EmptyRef)
	|				THEN TabPart.Ref
	|			ELSE TabPart.Ref.CorrectedDocument
	|		END
	|	END AS OrderDocument,
	|	CASE
	|		WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1)
	|			THEN TabPart.Ref.DateOfReceipt
	|		ELSE TabPart.Ref.Date
	|	END AS DateOfReceipt,
	|	TRUE AS AvailableForConsumption,
	|	&TextOfExpressionReceiptByOrder AS OnSchedule,
	|	TabPart.Ref.ReferenceOrder AS OrderInSchedule,
	|	TabPart.Count AS QuantityInGraph
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS TabPart
	|WHERE
	|	TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
	|	AND (TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|	OR NOT &TextOfExpressionReceiptByOrder)";
	
	QueryTextTabPart = StrReplace(QueryTextTabPart,
		"&TextOfExpressionReceiptByOrder",
		TextOfExpressionReceiptByOrder("TabPart"));
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
EndProcedure

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref AS Ref,
	|	CASE
	|		WHEN DataSource.ReferenceOrder IN
	|		(UNDEFINED,
	|		VALUE(Document.SubcontractOrder2_5.EmptyRef),
	|		VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
	|			THEN UNDEFINED
	|		ELSE DataSource.ReferenceOrder
	|	END AS OrderDocument,
	|	DataSource.Ref AS Invoice,
	|	DataSource.Ref.Patch AS Patch,
	|	DataSource.Ref.CorrectedDocument AS CorrectedDocument,
	|	DataSource.Ref.Contract AS Contract,
	|	DataSource.Ref.Terms AS Terms,
	|	DataSource.Ref.GoodsReceiptOption AS GoodsReceiptOption,
	|	DataSource.Ref.Date AS Date,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE DataSource.Products
	|	END AS Products,
	|	DataSource.Products AS ItemsForConnection,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE DataSource.Characteristic
	|	END AS Characteristic,
	|	DataSource.Characteristic AS CharacteristicForConnection,
	|	DataSource.Purpose AS Purpose,
	|	DataSource.ToControlQuality AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference AS ControlledLotReference,
	|	DataSource.Series AS Series,
	|	DataSource.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|			VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			THEN FALSE
	|		WHEN &TextOfExpressionReceiptByOrder
	|		AND DataSource.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ExceedingOrder,
	|	DataSource.Ref.Warehouse AS Warehouse,
	|	DataSource.Ref.Partner AS Sender,
	|	DataSource.Ref.BusinessOperation AS BusinessOperation,
	|	DataSource.Count AS Count,
	|	TRUE AS ThisIsAnInvoice,
	|	&TextOfExpressionReceiptByOrder AS ReceiptUnderOrders,
	|	FALSE AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)";
	
	QueryTextDocument_ = StrReplace(QueryTextDocument_,
		"&TextOfExpressionReceiptByOrder",
		TextOfExpressionReceiptByOrder("DataSource"));
	
	AdditionalSeriesConnectionFields = New Array;
	AdditionalSeriesConnectionFields.Add("ProductsRecordingAsReceived");
	AdditionalSeriesConnectionFields.Add("CharacteristicRecordingAsReceived");
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Products", "ItemsForConnection");
	RedefinedSeriesConnectionFields.Insert("Characteristic", "CharacteristicForConnection");
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.ItIsRequiredToTakeIntoAccountRequirementsForIssuingInvoicesByOrder = True;
	MethodParameters.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
	MethodParameters.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	
	WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		Metadata.Documents.ReceiptOfGoodsFromCustodian,
		MethodParameters);

EndProcedure

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Dimension.Ref AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners = Dimension.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Dimension.Ref AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Dimension.Ref AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ProductsRecordingAsReceived = Dimension.Products
	|		AND TableTypesOfStocks_.CharacteristicRecordingAsReceived = Dimension.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = Dimension.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = Dimension.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS AnalysisOfTransmittedProducts,
	|	AnalysisOfTransmittedProductsWithoutAssignment.DimensionKey AS AnalysisOfTransmittedProductsWithoutAssignment,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute.InventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	
	|	TableTypesOfStocks_.ProductsRecordingAsReceived  AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	
	|	LogInAnalytics.DimensionKey AS AnalysisOfAccountingForProductList,
	|	AnalyticsOfRegistrationWithoutAssignment.DimensionKey AS InventoryLocationAttributeAccountingWithoutAssignment,
	|
	|	TableTypesOfStocks_.RowID AS RowID
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON AnalyticsWithoutAssignment.Products = TableTypesOfStocks_.ItemsLocationAttributes.Products
	|		AND AnalyticsWithoutAssignment.Characteristic = TableTypesOfStocks_.ItemsLocationAttributes.Characteristic
	|		AND AnalyticsWithoutAssignment.Series = TableTypesOfStocks_.ItemsLocationAttributes.Series
	|		AND AnalyticsWithoutAssignment.StorageLocation = TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProductsWithoutAssignment
	|		ON TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.Products = AnalysisOfTransmittedProductsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.Characteristic = AnalysisOfTransmittedProductsWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.Series = AnalysisOfTransmittedProductsWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.StorageLocation = AnalysisOfTransmittedProductsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.ProductCostElement
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS LogInAnalytics
	|		ON TableTypesOfStocks_.ProductsRecordingAsReceived = LogInAnalytics.Products
	|			AND TableTypesOfStocks_.CharacteristicRecordingAsReceived = LogInAnalytics.Characteristic
	|			AND Dimension.Series = LogInAnalytics.Series
	|			AND Dimension.StorageLocation = LogInAnalytics.StorageLocation
	|			AND Dimension.Purpose = LogInAnalytics.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfRegistrationWithoutAssignment
	|		ON TableTypesOfStocks_.ProductsRecordingAsReceived = AnalyticsOfRegistrationWithoutAssignment.Products
	|			AND TableTypesOfStocks_.CharacteristicRecordingAsReceived = AnalyticsOfRegistrationWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsOfRegistrationWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsOfRegistrationWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsOfRegistrationWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.ProductCostElement
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|";
	
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
	|	AnalystTable.Products AS Products,
	|	AnalystTable.Characteristic AS Characteristic,
	|	AnalystTable.Purpose AS Purpose,
	|	AnalystTable.Series AS Series,
	|	AnalystTable.Warehouse AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		Goods.ItemsLocationAttributes.Products AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		Goods.ItemsLocationAttributes.Series AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation AS Warehouse
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributes.Products = Dimension.Products
	|			AND Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|			AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Products,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Characteristic,
	|		&EmptyAssignment,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Series,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.StorageLocation
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributesGoodsAtPartners.Products = Dimension.Products
	|			AND Goods.ItemsLocationAttributesGoodsAtPartners.Characteristic = Dimension.Characteristic
	|			AND Goods.ItemsLocationAttributesGoodsAtPartners.Series = Dimension.Series
	|			AND Goods.ItemsLocationAttributesGoodsAtPartners.StorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement)
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Goods.ProductsRecordingAsReceived AS Products,
	|		Goods.CharacteristicRecordingAsReceived AS Characteristic,
	|		Goods.ItemsLocationAttributes.Purpose AS Purpose,
	|		Goods.ItemsLocationAttributes.Series AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation AS Warehouse
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ProductsRecordingAsReceived = Dimension.Products
	|			AND Goods.CharacteristicRecordingAsReceived = Dimension.Characteristic
	|			AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|			AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND Goods.ItemsLocationAttributes.Purpose = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND Goods.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Goods.ProductsRecordingAsReceived AS Products,
	|		Goods.CharacteristicRecordingAsReceived AS Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		Goods.ItemsLocationAttributes.Series AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation AS Warehouse
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ProductsRecordingAsReceived = Dimension.Products
	|			AND Goods.CharacteristicRecordingAsReceived = Dimension.Characteristic
	|			AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|			AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND &EmptyAssignment = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)) AS AnalystTable";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReceiptOfGoodsFromCustodian";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
	ElsIf RegisterName = "PurchaseOrders" Then
		
		QueryText = QueryTextTablePurchaseOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
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

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""Goods"" AS DataSource,
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
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
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
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function TextOfExpressionReceiptByOrder(TableName)
	
	Return StrTemplate(
		"(%1.Ref.ByReferences
		|	AND CASE
		|		WHEN VALUETYPE(%1.ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
		|			THEN NOT CAST(%1.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
		|		ELSE TRUE
		|	END)",
		TableName);
	
EndFunction

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
	
	#Region Moving_Product
	
	QueryText = 
	"SELECT
	
	// Document description
	
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	
	// Item accounting fields
	
	|	DocumentTable.Organization AS Organization,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	UNDEFINED AS VATActivityType,
	|	UNDEFINED AS DocumentVATActivityType,
	
	// Corresponding fields
	
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorLot,
	|	ISNULL(TableTypesOfStocks_.AnalysisOfAccountingForProductList,
	|		TableTypesOfStocks_.ItemsLocationAttributes) AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	
	// Financial Accounting Analysis Fields
	
	|	DocumentTable.SalesOpportunity AS SalesOpportunity,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.Manager AS Manager,
	|	UNDEFINED AS ProductsGroup,
	
	// Quantitative and summary indicators
	
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.RowID AS RowID,
	
	// Other fields
	
	|	DocumentTable.BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS DocumentTable
	|		INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (TableTypesOfStocks_.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ReusablePackageReturn)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion

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
	JobPrintingRules.ReceiptOperation	= True;
	
	Return JobPrintingRules;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		// Receipt of goods from the keeper.
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ReceiptOfGoodsFromCustodian";
		PrintCommand.Presentation = NStr("vi = 'Tiếp nhận hàng hóa từ bên bảo quản';
										|ru = 'Поступление товаров от хранителя';
										|en = 'VMI return'; fa = 'برگشت VMI';
										|it = 'Arrivo di merci dal consegnatario';
										|pl = 'Wpływ towarów od magazyniera';
										|tr = 'Malların VMI''dan teslim alınması'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														  "BusinessOperation",
														  Enums.BusinessTransactions.ReturnFromCustodian,
														  ComparisonType.Equal);
	EndIf;
	
	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	
	ReceiptOfGoodsFromCustodianLocalization.AddPrintCommands(PrintCommands);
	
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReceiptOfGoodsFromCustodian") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReceiptOfGoodsFromCustodian",
			NStr("vi = 'Tiếp nhận hàng hóa từ bên bảo quản';
				|ru = 'Поступление товаров от хранителя';
				|en = 'VMI return'; fa = 'برگشت VMI';
				|it = 'Arrivo di merci dal consegnatario';
				|pl = 'Wpływ towarów od magazyniera';
				|tr = 'Malların VMI''dan teslim alınması'"),
			FormPrintedFormReceiptOfGoodsFromCustodian(ObjectsArray, PrintObjects));
	EndIf;
	
	ReceiptOfGoodsFromCustodianLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects,
		OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// The function generates a printed form of documents of receipt of goods from the custodian.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - printed form of documents of receipt of goods from the custodian.
//
Function FormPrintedFormReceiptOfGoodsFromCustodian(ObjectsArray, PrintObjects)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	UninvoicedReceipt.Ref AS Ref,
	|	UninvoicedReceipt.Number AS Number,
	|	UninvoicedReceipt.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	UninvoicedReceipt.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	UninvoicedReceipt.Date AS Date,
	|	UninvoicedReceipt.Partner AS Partner,
	|	UninvoicedReceipt.Counterparty AS Recipient,
	|	UninvoicedReceipt.Organization AS Organization,
	|	UninvoicedReceipt.Organization.Prefix AS Prefix,
	|	UninvoicedReceipt.Currency AS Currency,
	|	UninvoicedReceipt.Warehouse.CurrentEmployeeInChargeTypes AS GettingProduced
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS UninvoicedReceipt
	|WHERE
	|	UninvoicedReceipt.Ref IN(&DocumentsArray)
	|	AND UninvoicedReceipt.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsTable.Ref               AS Ref,
	|	GoodsTable.LineNumber          AS LineNumber,
	|	KitConfigurations.Ref        AS ItemKitConfiguration,
	|	KitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.SetPricingOption AS SetPricingOption,
	|	GoodsTable.ProductsInSet   AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END                              AS UnitOfMeasure,
	|	GoodsTable.Package             AS Package,
	|	GoodsTable.Count           AS Count,
	|	GoodsTable.NumberOfPackages   AS NumberOfPackages,
	|	GoodsTable.Price                 AS Price,
	|	GoodsTable.Sum                AS Sum,
	|	CASE
	|		WHEN GoodsTable.Ref.ReusablePackageReturn
	|				AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                              AS ThisIsReusablePackage
	|INTO Goods
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|		LEFT JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON KitConfigurations.Owner = GoodsTable.ProductsInSet
	|			AND KitConfigurations.Characteristic = GoodsTable.ItemVariantOfSet
	|			AND KitConfigurations.Main
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND GoodsTable.Ref.Posted
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 2
	|SELECT DISTINCT
	|	Goods.Ref AS Ref
	|INTO PrintDocuments_1
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration
	|INTO DocumentConfigurations
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsTable.Ref               AS Ref,
	|	MIN(GoodsTable.LineNumber) AS LineNumber,
	|	GoodsTable.ProductsInSet   AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	SUM(GoodsTable.Sum)         AS Sum
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS GoodsTable
	|WHERE
	|	GoodsTable.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.ProductsInSet,
	|	GoodsTable.ItemVariantOfSet
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
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet   AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products         AS Products,
	|	Goods.Characteristic       AS Characteristic,
	|	Goods.Count           AS Count,
	|	0                           AS DefaultQuantity,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END                       AS MainComponent
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
	|	KitConfigurations.Ref                AS ItemKitConfiguration,
	|	KitConfigurations.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.Ref.SetPricingOption AS SetPricingOption,
	|	KitConfigurations.Ref.Owner       AS ProductsInSet,
	|	KitConfigurations.Ref.Characteristic AS ItemVariantOfSet,
	|	KitConfigurations.Products          AS Products,
	|	KitConfigurations.Characteristic        AS Characteristic,
	|	0                                          AS Count,
	|	SUM(KitConfigurations.Count)     AS DefaultQuantity,
	|	FALSE                                       AS MainComponent
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS KitConfigurations
	|		LEFT JOIN PrintDocuments_1 AS PrintDocuments_1
	|		ON TRUE
	|WHERE
	|	KitConfigurations.Ref IN
	|		(SELECT DISTINCT
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
	|	Table.Ref                          AS Ref,
	|	Table.ItemKitConfiguration AS ItemKitConfiguration,
	|	Table.SetPricingOption        AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet              AS ProductsInSet,
	|	Table.ItemVariantOfSet            AS ItemVariantOfSet,
	|	Table.Products                    AS Products,
	|	Table.Characteristic                  AS Characteristic,
	|	SUM(Table.Count)               AS Count,
	|	SUM(Table.DefaultQuantity)    AS DefaultQuantity,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT)   AS VATRate,
	|	MAX(Table.MainComponent) AS MainComponent
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
	|		WHEN Result.MainComponent
	|			THEN Result.VATRate
	|		ELSE NULL
	|	END)                         AS VATRate
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
	|	Table.Sum                AS Sum,
	|	TemporaryTableSetsOptional.VATRate AS VATRate,
	|	0                            AS VATAmount
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
	|	NestedQuery.UnitOfMeasure     AS UnitOfMeasure,
	|	NestedQuery.UnitOfMeasure.Description AS UnitPrice,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END                                AS Package,
	|	NestedQuery.NumberOfPackages   AS Count,
	|	NestedQuery.Price                 AS Price,
	|	NestedQuery.Sum                AS Sum,
	|	NestedQuery.VATRate            AS VATRate,
	|	NestedQuery.VATAmount             AS VATAmount,
	|	NestedQuery.TheseAreComponents     AS TheseAreComponents,
	|	NestedQuery.IsRecordsSet             AS IsRecordsSet,
	|	NestedQuery.ThisIsReusablePackage    AS ThisIsReusablePackage
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
	|		Table.ThisIsReusablePackage    AS ThisIsReusablePackage
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
	|		TemporaryTableSets.VATRate            AS VATRate,
	|		TemporaryTableSets.VATAmount             AS VATAmount,
	|		FALSE                                        AS TheseAreComponents,
	|		TRUE                                      AS IsRecordsSet,
	|		FALSE                                        AS ThisIsReusablePackage
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
	|	IsRecordsSet DESC";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
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
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReceiptOfGoodsFromCustodian_Invoice";
	
	PrintData        = ResultsArray[0].Select();
	Goods = ResultsArray[ResultsArray.Count() - 1].Unload();
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		GoodsTable   = Goods.FindRows(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate("Document.ReceiptOfGoodsFromCustodian.PF_MXL_ReceiptOfGoodsFromCustodian");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea,
			PrintData.Ref);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData,
																						NStr("vi = 'Tiếp nhận hàng hóa từ bên bảo quản';
																							|ru = 'Поступление товаров от хранителя';
																							|en = 'VMI return'; fa = 'برگشت VMI';
																							|it = 'Arrivo di merci dal consegnatario';
																							|pl = 'Wpływ towarów od magazyniera';
																							|tr = 'Malların VMI''dan teslim alınması'", Common.DefaultLanguageCode()));
		
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
		RoomArea = Template.GetArea("TableHeader|LineNumber");
		AreaCodes  = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductArea  = Template.GetArea("TableHeader|OwnGoods");
		DataArea = Template.GetArea("TableHeader|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		LineNumberAreaStandard = Template.GetArea("TableRow|LineNumber");
		ScopeOfStringCodesStandard  = Template.GetArea("TableRow|ColumnOfCodes");
		ProductAreaRowsStandard  = Template.GetArea("TableRow|OwnGoods");
		DataAreaOfStringIsStandard = Template.GetArea("TableRow|Data");
		
		UseSets = False;
		
		If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			LineNumberAreaSet = Template.GetArea("TableRowSet" + "|LineNumber");
			StringCodeAreaSet  = Template.GetArea("TableRowSet" + "|ColumnOfCodes");
			ProductAreaRowsSet  = Template.GetArea("TableRowSet" + "|OwnGoods");
			RowDataAreaSet = Template.GetArea("TableRowSet" + "|Data");
			
			LineNumberAreaComponents = Template.GetArea("TableRowComponents" + "|LineNumber");
			StringCodeAreaComponents  = Template.GetArea("TableRowComponents" + "|ColumnOfCodes");
			ProductAreaRowsComponents  = Template.GetArea("TableRowComponents" + "|OwnGoods");
			RowDataAreaComponents = Template.GetArea("TableRowComponents" + "|Data");
		EndIf;
		
		Sum       = 0;
		LineNumber = 0;
		
		BlankData = SetsServer.BlankData();
		
		// Output the rows of the Goods table
		For Each ProductSelection_1 In GoodsTable Do
			
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
				Sum    = Sum    + ProductSelection_1.Sum;
			EndIf;
			
		EndDo;
		
		// We output the basement
		RoomArea = Template.GetArea("TableFooter|LineNumber");
		AreaCodes  = Template.GetArea("TableFooter|ColumnOfCodes");
		ProductArea  = Template.GetArea("TableFooter|OwnGoods");
		DataArea = Template.GetArea("TableFooter|Data");
		
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
		RoomArea = Template.GetArea("VATTableBasement|LineNumber");
		AreaCodes  = Template.GetArea("VATTableBasement|ColumnOfCodes");
		ProductArea  = Template.GetArea("VATTableBasement|OwnGoods");
		DataArea = Template.GetArea("VATTableBasement|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
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
		
		If ValueIsFilled(PrintData.GettingProduced) Then
			GettingProduced = PersonsTM.IndividualShortName(PrintData.GettingProduced, PrintData.Date);
			
			DataStructureGettingProduced = New Structure;
			DataStructureGettingProduced.Insert("GettingProduced", GettingProduced);
			
			TemplateArea.Parameters.Fill(DataStructureGettingProduced);
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
	
EndProcedure

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	
	FillParameters = New Structure(ParameterName, ParameterValue);
	
	TemplateArea.Parameters.Fill(FillParameters);
	
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

#Region FillType

Function QueryTextDocumentGoods(Filter, JoinText, UseLineCode = False)
	
	QueryText = 
	"SELECT ALLOWED
	|	DataOfAccounting.DocumentBasis AS Ref,
	|	DataOfAccounting.Products AS Products,
	|	DataOfAccounting.Characteristic AS Characteristic,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	DataOfAccounting.Purpose AS Purpose,
	|	DataOfAccounting.Series AS Series,
	|	SUM(ISNULL(Table.Count, 0)) AS Count,
	|	MAX(ISNULL(DataOfAccounting.ToRegister, 0)) AS ToRegister,
	|	MAX(DataOfAccounting.Package) AS Package,
	|	MAX(DataOfAccounting.Price) AS Price,
	|	DataOfAccounting.Warehouse AS Warehouse,
	|	DataOfAccounting.CCDNumber AS CCDNumber,
	|	ISNULL(Table.ReferenceOrder, DataOfAccounting.ReferenceOrder) AS ReferenceOrder,
	|	&RowCode AS RowCode
	|FROM
	|	TTAccountingData AS DataOfAccounting
	|		LEFT JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS Table
	|		ON (&ConnectionMethod)
	|WHERE
	|	&Filter
	|
	|GROUP BY
	|	DataOfAccounting.DocumentBasis,
	|	DataOfAccounting.Products,
	|	DataOfAccounting.Characteristic,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	DataOfAccounting.Purpose,
	|	DataOfAccounting.Series,
	|	DataOfAccounting.Warehouse,
	|	DataOfAccounting.CCDNumber,
	|	ISNULL(Table.ReferenceOrder, DataOfAccounting.ReferenceOrder),
	|	&RowCode";
	
	QueryText = StrReplace(QueryText, "&ConnectionMethod", JoinText);
	QueryText = StrReplace(QueryText, "&RowCode", ?(UseLineCode, "DataOfAccounting.RowCode", "0"));
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&Filter", FilterText1);
	
	Return QueryText;
	
EndFunction

Function TextOfRequestIsReadyForRegistrationByActs(TempTableName = "", UseLineCode = False)
	
	QueryText = 
	"SELECT ALLOWED
	|	Set.DocumentBasis  AS DocumentBasis,
	|	Set.ReferenceOrder       AS ReferenceOrder,
	|	Set.RowCode          AS RowCode,
	|	Set.Warehouse              AS Warehouse,
	|	Set.Products       AS Products,
	|	Set.Characteristic     AS Characteristic,
	|	Set.Purpose         AS Purpose,
	|	Set.Series              AS Series,
	|	Set.CCDNumber           AS CCDNumber,
	|	SUM(Set.Count)  AS ToRegister,
	|	Set.Price               AS Price,
	|	Set.Package           AS Package
	|FROM
	|	(SELECT
	|		GoodsTable.DocumentBasis AS DocumentBasis,
	|		GoodsTable.PurchaseOrder   AS ReferenceOrder,
	|		&RowCode                      AS RowCode,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.Purpose        AS Purpose,
	|		GoodsTable.Series             AS Series,
	|		GoodsTable.CCDNumber          AS CCDNumber,
	|		GoodsTable.Warehouse             AS Warehouse,
	|		(GoodsTable.CountByDocument
	|			- GoodsTable.Count) AS Count,
	|		GoodsTable.Price              AS Price,
	|		GoodsTable.Package          AS Package
	|	FROM
	|		Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref.Posted
	|		AND GoodsTable.Ref IN(&DiscrepancyCertificate)
	|		AND GoodsTable.DocumentBasis IN(&DocumentInflow)
	|		AND GoodsTable.FilledUsingBaseDocument
	|		AND GoodsTable.Action IN
	|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Ref         AS DocumentBasis,
	|		GoodsTable.ReferenceOrder   AS ReferenceOrder,
	|		&RowCode                   AS RowCode,
	|		GoodsTable.Products   AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Purpose     AS Purpose,
	|		GoodsTable.Series          AS Series,
	|		GoodsTable.CCDNumber       AS CCDNumber,
	|		UninvoicedReceipt.Warehouse     AS Warehouse,
	|		-GoodsTable.Count    AS Count,
	|		GoodsTable.Price           AS Price,
	|		GoodsTable.Package       AS Package
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
	|			LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS UninvoicedReceipt
	|			ON GoodsTable.Ref = UninvoicedReceipt.Ref
	|	WHERE
	|		UninvoicedReceipt.Posted
	|		AND UninvoicedReceipt.AdditionalReturnWithinGoodsReceipt IN(&DocumentInflow)
	|	
	|	) AS Set
	|
	|GROUP BY
	|	Set.DocumentBasis,
	|	Set.ReferenceOrder,
	|	Set.RowCode,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.Purpose,
	|	Set.Series,
	|	Set.CCDNumber,
	|	Set.Warehouse,
	|	Set.Price,
	|	Set.Package
	|
	|HAVING
	|	SUM(Set.Count) <> 0
	|";
	
	QueryText = StrReplace(QueryText, "&RowCode", ?(UseLineCode, "GoodsTable.RowCode", "0"));
	
	If Not IsBlankString(TempTableName) Then
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, TempTableName);
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure FillInSeriesAccordingToReportsOfProcessor(TableOfGoods, TempTablesManager, Recorder)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	ReportItems_.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTProductsReport
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS ReportItems_
	|	
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|	ON ReportItems_.SubcontractOrder = DataOfAccounting.ReferenceOrder
	|	AND ReportItems_.RowCode = DataOfAccounting.RowCode
	|
	|WHERE
	|	NOT ReportItems_.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	ReportItems_.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS ReportItems_
	|	
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|	ON ReportItems_.SubcontractOrder = DataOfAccounting.ReferenceOrder
	|	AND ReportItems_.RowCode = DataOfAccounting.RowCode
	|
	|WHERE
	|	NOT ReportItems_.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyGoodsBalance.Products               AS Products,
	|	CompanyGoodsBalance.Characteristic             AS Characteristic,
	|	CompanyGoodsBalance.Purpose                 AS Purpose,
	|	CompanyGoodsBalance.Series                      AS Series,
	|	SUM(CompanyGoodsBalance.Count)          AS Count
	|FROM
	|	(SELECT
	|		CompanyGoodsBalance.ItemsLocationAttributes.Products   AS Products,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Purpose     AS Purpose,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Series          AS Series,
	|		CompanyGoodsBalance.CountBalance                         AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(,
	|			(ItemsLocationAttributes) IN
	|				(SELECT
	|					TTProductsReport.ItemsLocationAttributes
	|				FROM
	|					TTProductsReport AS TTProductsReport)) AS CompanyGoodsBalance
	|	
	|	UNION ALL
	|	
	// we will increase the Balance of goods by the amount in the expenditure movements of the Cur receipt
	|	SELECT
	|		CompanyGoodsBalance.ItemsLocationAttributes.Products   AS Products,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Purpose     AS Purpose,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Series          AS Series,
	|		CompanyGoodsBalance.Count                                AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoodsBalance
	|	WHERE
	|		CompanyGoodsBalance.Recorder = &Recorder
	|		AND (CompanyGoodsBalance.ItemsLocationAttributes) IN
	|			(SELECT
	|				TTProductsReport.ItemsLocationAttributes
	|			FROM
	|				TTProductsReport AS TTProductsReport)
	|	) AS CompanyGoodsBalance
	|
	|GROUP BY
	|	CompanyGoodsBalance.Products,
	|	CompanyGoodsBalance.Characteristic,
	|	CompanyGoodsBalance.Purpose,
	|	CompanyGoodsBalance.Series
	|
	|HAVING
	|	SUM(CompanyGoodsBalance.Count) > 0
	|	
	|";
	Query.SetParameter("Recorder", Recorder);
	TableOfSeries = Query.Execute().Unload();
	
	Var_Key = "Products, Characteristic, Purpose";
	Filter = New Structure(Var_Key);
	TableOfSeries.Indexes.Add(Var_Key);
	
	For Each RowOfGoods In TableOfGoods Do
		
		If ValueIsFilled(RowOfGoods.Series) Then
			Continue;
		EndIf;
		
		NumberOfProducts = RowOfGoods.ToRegister;
		FillPropertyValues(Filter, RowOfGoods);
		
		For Each SeriesString In TableOfSeries.FindRows(Filter) Do
			
			If SeriesString.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(NumberOfProducts, SeriesString.Count);
			
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, RowOfGoods);
			FillPropertyValues(NewRow, SeriesString, "Series");
			
			NewRow.ToRegister = Count;
			NewRow.Count  = Count;
			
			SeriesString.Count    = SeriesString.Count - NewRow.Count;
			RowOfGoods.ToRegister = RowOfGoods.ToRegister - NewRow.ToRegister;
			RowOfGoods.Count  = RowOfGoods.Count - NewRow.Count;
			NumberOfProducts         = NumberOfProducts - NewRow.ToRegister;
			
			If NumberOfProducts = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RowFilter = New Structure("ToRegister", 0);
	For Each TableRow In TableOfGoods.FindRows(RowFilter) Do
		TableOfGoods.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInSeriesOfOrdersAccordingToOrderTable(OrdersTable, TableOrders)
	
	Var_Key = "ReferenceOrder, Products, Characteristic, Purpose";
	Filter = New Structure(Var_Key);
	
	For Each OrderLine In OrdersTable Do
		
		If ValueIsFilled(OrderLine.Series) Then
			Continue;
		EndIf;
		
		QuantityInOrder = OrderLine.QuantityInOrder;
		FillPropertyValues(Filter, OrderLine);
		
		For Each OrderLine_1 In TableOrders.FindRows(Filter) Do
			
			If Not ValueIsFilled(OrderLine_1.Series) Then
				Continue;
			EndIf;
			
			Count = Min(QuantityInOrder, OrderLine_1.Count);
			
			If OrderLine.QuantityInOrder = Count Then
				CurrentData = OrderLine;
			Else
				
				CurrentData = OrdersTable.Add();
				FillPropertyValues(CurrentData, OrderLine);
				
				CurrentData.QuantityInOrder = Count;
				OrderLine.QuantityInOrder  = OrderLine.QuantityInOrder - Count;
				
			EndIf;
			
			CurrentData.Series     = OrderLine_1.Series;
			
			QuantityInOrder       = QuantityInOrder - Count;
			OrderLine_1.Count = OrderLine_1.Count - Count;
			
			If QuantityInOrder = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Filter = New Structure("QuantityInOrder", 0);
	For Each CurrentData In OrdersTable.FindRows(Filter) Do
		OrdersTable.Delete(CurrentData);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function AnalysisOfAccountingOfProductRangeForTransferOfGoodsToCustodian(References)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	GoodsTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&References)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	GoodsTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.SalesOrder IN (&References)
	|";
	
	Query.SetParameter("References", References);
	
	ProductAccountingAnalysts = Query.Execute().Unload().UnloadColumn("ItemsLocationAttributes");
	
	Return ProductAccountingAnalysts;
	
EndFunction

Function AnalysisOfProductItemAccountingForCommissionRefund(References)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	GoodsTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN
	|			(SELECT
	|				RequestForReturnOfGoodsFromCustomerReturnedGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|			FROM
	|				Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS RequestForReturnOfGoodsFromCustomerReturnedGoods
	|			WHERE
	|				RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref IN (&References))";
	
	Query.SetParameter("References", References);
	
	ProductAccountingAnalysts = Query.Execute().Unload().UnloadColumn("ItemsLocationAttributes");
	
	Return ProductAccountingAnalysts;
	
EndFunction

Function PriceViewFromTablePart(References)
	
	PriceViewInZayak = Catalogs.TypesOfPrices.EmptyRef();
	
	Query = New Query;
	QueryText = 
	"SELECT DISTINCT
	|	GoodsTable.PriceKind AS PriceKind
	|FROM
	|	&TableOfGoods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&References)
	|
	|GROUP BY
	|	GoodsTable.PriceKind";
	
	Query.SetParameter("References", References);
	If TypeOf(References) = Type("Array") Then
		ReferenceOrder = References[0];
	Else
		ReferenceOrder = References;
	EndIf;
	
	If TypeOf(ReferenceOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		Query.Text = StrReplace(QueryText, "&TableOfGoods", "Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods");
	Else
		Query.Text = StrReplace(QueryText, "&TableOfGoods", "Document.TransferOfGoodsToBailee.Goods");
	EndIf;
	
	Result = Query.Execute().Unload();
	If Result.Count() = 1 Then
		PriceViewInZayak = Result[0].PriceKind;
	EndIf;
	
	Return PriceViewInZayak;
	
EndFunction

#EndRegion

#Region UnifiedMethodsForBusinessOperations

#Region FillType

// Returns the sales condition
//
// Parameters:
//  Terms - CatalogRef.TermsOfSale - 
//
// Returns:
//  See SalesServer.GetTermsAndConditionsOfSale
//
Function GetTermsAndConditionsOfSale(Terms) Export

	Return SalesServer.GetTermsAndConditionsOfSale(Terms);

EndFunction

#EndRegion

#Region Posting

// Returns parameters for filling in inventory types for the document "Receipt of goods from the custodian".
//
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian
//
// Returns:
//  See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	Var FillParameters;
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.ReversedDocument = Object.ReversedDocument;
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	
	FillParameters.SelectionOfStockTypes_.Organization = Object.Organization;
	
	FillParameters.SelectionOfStockTypes_.InventoryType  = New Array;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	
	Return FillParameters;

EndFunction

// Adds an additional property for monitoring when conducting
// 
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian - 
//
Procedure AddAdditionalPropertyToControlWhenConducting(Object) Export
	
	If Not Object.ByReferences Then
		Object.RegisterRecords.CompanyGoods.AdditionalProperties.Insert("CreateSummaryTableProductsOfOrganizations");
	EndIf;
	
EndProcedure

#EndRegion

#Region Rounding

// Fills in the Shopbill and need to Round attributes in the table rows
// 
// Parameters:
//  Object - FormDataStructure - table being processed
//  
Procedure FillInShopPantryAttributeInTable(Object) Export
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.Goods,, Object.Warehouse);
	
EndProcedure

// Recalculates the number of units
//
// Parameters:
//  Object - FormDataStructure - 
//
Procedure RecalculateNumberOfUnits(Object) Export
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionRecalculateNumberOfUnits(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

// Adds the actions "Fill in the sign of the checkbook"
//
// Parameters:
//  StructureOfActions - Structure - 
//  Warehouse - CatalogRef.Warehouses - 
//
Procedure AddFillInActionForShopPantryAttribute(StructureOfActions, Warehouse) Export
	
	StructureOfActions.Insert("FillInShopPantryAttribute", New Structure("WarehouseValue_", Warehouse));
	
EndProcedure

// Adds the action "Recalculate the number of units"
//
// Parameters:
//  StructureOfActions - Structure - 
//
Procedure AddActionRecalculateNumberOfUnits(StructureOfActions) Export
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits());
	
EndProcedure

// Returns the parameters for recalculating the client units
//
// Returns:
//  Undefined - 
//
Function ParametersForRecalculatingNumberOfUnits() Export
	
	Return Undefined;
	
EndFunction

// Returns the parameters for rounding
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses - 
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding(Warehouse) Export
	
	Return New Structure("Goods");
	
EndFunction

#EndRegion

#Region QueriesTexts

//Returns the text of the request data for input validation based on
//
// Returns:
//  String - 
//
Function QueryTextDataForInputValidationBasedOn() Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
	"SELECT
	|	ReferenceOrder.Ref AS Basis,
	|	ReferenceOrder.Status AS Status,
	|	FALSE AS RegistrationViaRM,
	|	CASE
	|		WHEN ReferenceOrder.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE ReferenceOrder.Warehouse
	|	END               AS Warehouse,
	|	ReferenceOrder.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS ReferenceOrder
	|WHERE
	|	ReferenceOrder.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT
	|	ReferenceOrder.Ref AS Basis,
	|	UNDEFINED        AS Status,
	|	FALSE AS RegistrationViaRM,
	|	CASE
	|		WHEN ReferenceOrder.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE ReferenceOrder.Warehouse
	|	END               AS Warehouse,
	|	ReferenceOrder.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.TransferOfGoodsToBailee AS ReferenceOrder
	|WHERE
	|	ReferenceOrder.Ref IN(&References)
	|");
	
	QueriesTexts.Add(
	"SELECT TOP 1
	|	1
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Products_From_Orders
	|WHERE
	|	Products_From_Orders.Ref IN(&References)
	|	AND NOT Products_From_Orders.Canceled
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Products_From_Orders
	|WHERE
	|	Products_From_Orders.Ref IN(&References)
	|");
	
	QueriesTexts.Add(
		AccumulationRegisters.GoodsToReceive.QueryTextBalance(
			"TTBalancesForRegistration",
			New Structure("DocumentInflow", "References"),
			"ToRegister <> 0"));
	
	QueriesTexts.Add(
	"SELECT
	|	Set.ReferenceOrder AS InstructionsForRegistration
	|FROM
	|	(SELECT
	|		RequirementsForRegistration_1.ReferenceOrder AS ReferenceOrder
	|	FROM
	|		TTBalancesForRegistration AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS ReferenceOrder
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref IN (&References)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS ReferenceOrder
	|	FROM
	|		Document.TransferOfGoodsToBailee AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref IN (&References)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ReferenceOrder
	|");
	
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());

EndFunction

//Returns the request text invoice filling data
//
// Returns:
//  String - 
//
Function QueryTextInvoiceFillingData() Export
	
	QueryText =
	"SELECT
	|	&BusinessOperation AS BusinessOperation,
	|	OrderDocument.Ref.Organization AS Organization,
	|	OrderDocument.Ref.Department AS Department,
	|	CASE
	|		WHEN OrderDocument.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrderDocument.Ref.Warehouse
	|	END AS Warehouse,
	|	OrderDocument.Ref.SalesOpportunity AS SalesOpportunity,
	|	OrderDocument.Ref.Partner AS Partner,
	|	OrderDocument.Ref.Counterparty AS Counterparty,
	|	OrderDocument.Ref.Terms AS Terms,
	|	OrderDocument.Ref.Contract AS Contract,
	|	OrderDocument.Ref.LineOfBusiness AS LineOfBusiness,
	|	OrderDocument.Ref.ToReturnReusablePackage AS ReusablePackageReturn,
	|	OrderDocument.Ref.Currency AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderDocument.PriceKind) = 1
	|			THEN MAX(OrderDocument.PriceKind)
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS PriceKind,
	|	OrderDocument.Ref.ReturnOfSpoiledGoods AS ReturnOfSpoiledGoods
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS OrderDocument
	|WHERE
	|	OrderDocument.Ref = &OrderDocument
	|GROUP BY
	|	OrderDocument.Ref,
	|	OrderDocument.Ref.Organization,
	|	OrderDocument.Ref.Department,
	|	CASE
	|		WHEN OrderDocument.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrderDocument.Ref.Warehouse
	|	END,
	|	OrderDocument.Ref.SalesOpportunity,
	|	OrderDocument.Ref.Partner,
	|	OrderDocument.Ref.Counterparty,
	|	OrderDocument.Ref.Terms,
	|	OrderDocument.Ref.Contract,
	|	OrderDocument.Ref.LineOfBusiness,
	|	OrderDocument.Ref.ToReturnReusablePackage,
	|	OrderDocument.Ref.Currency,
	|	OrderDocument.Ref.ReturnOfSpoiledGoods
	|
	|UNION ALL
	|
	|SELECT
	|	&BusinessOperation AS BusinessOperation,
	|	Transfer_.Ref.Organization AS Organization,
	|	Transfer_.Ref.Department AS Department,
	|	CASE
	|		WHEN Transfer_.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Transfer_.Ref.Warehouse
	|	END AS Warehouse,
	|	Transfer_.Ref.SalesOpportunity AS SalesOpportunity,
	|	Transfer_.Ref.Partner AS Partner,
	|	Transfer_.Ref.Counterparty AS Counterparty,
	|	Transfer_.Ref.Terms AS Terms,
	|	Transfer_.Ref.Contract AS Contract,
	|	Transfer_.Ref.LineOfBusiness AS LineOfBusiness,
	|	Transfer_.Ref.ToReturnReusablePackage AS ReusablePackageReturn,
	|	Transfer_.Ref.Currency AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT Transfer_.PriceKind) = 1
	|			THEN MAX(Transfer_.PriceKind)
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS PriceKind,
	|	FALSE AS ReturnOfSpoiledGoods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Transfer_
	|WHERE
	|	Transfer_.Ref = &OrderDocument
	|GROUP BY
	|	Transfer_.Ref,
	|	Transfer_.Ref.Organization,
	|	Transfer_.Ref.Department,
	|	CASE
	|		WHEN Transfer_.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Transfer_.Ref.Warehouse
	|	END,
	|	Transfer_.Ref.SalesOpportunity,
	|	Transfer_.Ref.Partner,
	|	Transfer_.Ref.Counterparty,
	|	Transfer_.Ref.Terms,
	|	Transfer_.Ref.Contract,
	|	Transfer_.Ref.LineOfBusiness,
	|	Transfer_.Ref.ToReturnReusablePackage,
	|	Transfer_.Ref.Currency";

	Return QueryText;
	
EndFunction

//Returns the text of the goods request of the order document
//
// Parameters:
//  Filter - Map - 
//  SupplementSeriesTable - Boolean -
//
// Returns:
//  String - Query text
//
Function RequestTextAndOrderDocument(Filter, SupplementSeriesTable = False) Export
	
	QueryText =
		Documents.RequestForReturnOfGoodsFromCustomer.QueryTextDocumentGoods(
			Filter,
			JoinText(False),
			SupplementSeriesTable);
	
	Return QueryText;
	
EndFunction

//Returns the text of the request for the transferred goods
//
// Returns:
//  String - 
//
Function QueryTextGoodsTransferred() Export
	
	QueryText =
	"SELECT
	|	InvoiceGoods.LineNumber AS LineNumber,
	|	InvoiceGoods.Products AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.Series AS Series,
	|	InvoiceGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	InvoiceGoods.Purpose AS Purpose,
	|	InvoiceGoods.CCDNumber AS CCDNumber,
	|	InvoiceGoods.Count AS Count
	|INTO TTGoodsWaybill
	|FROM
	|	&Goods AS InvoiceGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE TTGoodsWaybill.Series
	|	END AS Series,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DifferentSeriesAccounting,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber,
	|	SUM(TTGoodsWaybill.Count) AS Count
	|INTO InvoiceGoods
	|FROM
	|	TTGoodsWaybill AS TTGoodsWaybill
	|		LEFT JOIN Catalog.Products AS TT_Products
	|		ON TTGoodsWaybill.Products = TT_Products.Ref
	|		LEFT JOIN Catalog.ItemKinds AS TTTypesOfNomenclature
	|		ON TT_Products.ProductKind = TTTypesOfNomenclature.Ref
	|		LEFT JOIN Catalog.BatchAccountingPolicies AS TTSeriesAccountingPolicies
	|		ON TTTypesOfNomenclature.BatchAccountingPolicy = TTSeriesAccountingPolicies.Ref
	|	
	|GROUP BY
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE TTGoodsWaybill.Series
	|	END,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	DimensionKeys.Ref AS Ref
	|INTO DimensionKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|WHERE
	|	DimensionKeys.StorageLocation = &Contract
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3 - Balances as of the document date
	|SELECT ALLOWED
	|	GoodsTransferredBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferredBalance.CCDNumber AS CCDNumber,
	|	GoodsTransferredBalance.CountBalance AS CountBalance
	|INTO GoodsTransferredBalance
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&Period, ItemsLocationAttributes IN
	|		(SELECT
	|			DimensionKeys.Ref
	|		FROM
	|			DimensionKeys AS DimensionKeys)
	|		AND Organization = &Organization) AS GoodsTransferredBalance
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4 - Current Balances
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CountBalance AS CountBalance,
	|	CASE
	|		WHEN GoodsTransferred.CountBalance < 0
	|			THEN -1
	|		ELSE 1
	|	END AS Character
	|INTO GoodsTransferredBalanceMark
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(, ItemsLocationAttributes IN
	|		(SELECT
	|			DimensionKeys.Ref
	|		FROM
	|			DimensionKeys AS DimensionKeys)
	|	AND Organization = &Organization) AS GoodsTransferred
	|;
	|
	|
	|//////////////////////////////////////////////////////////////////////////////// 5 - Balances and quantity by registrar
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferred
	|FROM
	|	(SELECT
	|		GoodsTransferred.ItemsLocationAttributes,
	|		GoodsTransferred.CCDNumber,
	|		CASE
	|			WHEN ISNULL(Balance.CountBalance * Balance.Character, 0) < GoodsTransferred.CountBalance *
	|				ISNULL(Balance.Character, 1)
	|				THEN ISNULL(Balance.CountBalance, 0)
	|			ELSE GoodsTransferred.CountBalance
	|		END AS CountBalance
	|	FROM
	|		GoodsTransferredBalance AS GoodsTransferred
	|			LEFT JOIN GoodsTransferredBalanceMark AS Balance
	|			ON GoodsTransferred.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|			AND GoodsTransferred.CCDNumber = Balance.CCDNumber
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTransferredToRegistrar.ItemsLocationAttributes,
	|		GoodsTransferredToRegistrar.CCDNumber,
	|		GoodsTransferredToRegistrar.Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS GoodsTransferredToRegistrar
	|	WHERE
	|		GoodsTransferredToRegistrar.Recorder = &Recorder
	|		AND GoodsTransferredToRegistrar.Active
	|		AND GoodsTransferredToRegistrar.ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|		AND GoodsTransferredToRegistrar.Organization = &Organization) AS GoodsTransferred
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber
	|
	|HAVING
	|	SUM(GoodsTransferred.CountBalance) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT ALLOWED
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS
	|		Characteristic,
	|	CASE
	|		WHEN TT_Item.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END AS Purpose,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferredGrouping
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTransferred.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN Catalog.Products AS TT_Item
	|		ON DimensionKeys.Products = TT_Item.Ref
	|GROUP BY
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN TT_Item.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
	|	GoodsTransferred.CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7 Connection with goods from the consignment note
	|SELECT
	|	GoodsTransferredGrouping.Products AS Products,
	|	GoodsTransferredGrouping.Characteristic AS Characteristic,
	|	GoodsTransferredGrouping.Purpose AS Purpose,
	|	GoodsTransferredGrouping.Series AS Series,
	|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
	|	GoodsTransferredGrouping.CCDNumber AS CCDNumber,
	|	GoodsTransferredGrouping.OriginCountry AS OriginCountry,
	|	GoodsTransferredGrouping.CountBalance AS CountBalance,
	|	GoodsTransferredGrouping.CountBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
	|
	|FROM
	|	GoodsTransferredGrouping AS GoodsTransferredGrouping
	|		LEFT JOIN InvoiceGoods AS InvoiceGoods
	|		ON GoodsTransferredGrouping.Products = InvoiceGoods.Products
	|		AND GoodsTransferredGrouping.Characteristic = InvoiceGoods.Characteristic
	|		AND GoodsTransferredGrouping.Purpose = InvoiceGoods.Purpose
	|		AND GoodsTransferredGrouping.Series = InvoiceGoods.Series
	|		AND GoodsTransferredGrouping.CCDNumber = InvoiceGoods.CCDNumber
	|
	|ORDER BY
	|	ISNULL(InvoiceGoods.LineNumber, 99999),
	|	GoodsTransferredGrouping.Products,
	|	GoodsTransferredGrouping.Characteristic,
	|	GoodsTransferredGrouping.Purpose,
	|	GoodsTransferredGrouping.Series
	|";
	
	Return QueryText;
	
EndFunction

// Returns the text of the connection between the tables "Table" and "Accounting data"
// 
//  Parameters:
//  UseCCDNumber - Boolean - 
//
// Returns:
//  String - 
//
Function JoinText(UseCCDNumber = True) Export

	JoinText =
	"Table.Ref = DataOfAccounting.ReferenceOrder
	|		AND Table.Purpose = DataOfAccounting.Purpose
	|		AND CASE
	|			WHEN Table.Damage
	|				THEN Table.ProductsRecordingAsReceived
	|			ELSE Table.Products
	|		END = DataOfAccounting.Products
	|		AND CASE
	|			WHEN Table.Damage
	|				THEN Table.CharacteristicRecordingAsReceived
	|			ELSE Table.Characteristic
	|		END = DataOfAccounting.Characteristic";
		
	If UseCCDNumber Then
		
		JoinText = JoinText + "
			|		AND Table.CCDNumber = DataOfAccounting.CCDNumber";
			
	EndIf;

	Return JoinText;

EndFunction

#Region TextsOfRequestsToFillInListOfOrders

// Returns the text of the request for orders available in the invoice.
// 
// Parameters:
//  RequestTextParameters - See TMCommonUse.ParametersOfRequestTextForOrdersInvoices
//
// Returns:
//  String - request text
//
Function QueryTextWaybillOrders(RequestTextParameters) Export
	
	TMCommonUse.AddSelectionItemToCollection(
		RequestTextParameters.Filter,
		"TableOfOrders.Warehouse",
		"&Warehouse",
		"=");
	
	Return Documents.RequestForReturnOfGoodsFromCustomer.RequestTextForOrdersInvoices(RequestTextParameters);
	
EndFunction

// Returns the text of the request for instructions for registration
//
// Returns:
//  String - request text
//
Function QueryTextInstructionsForRegistration() Export

	Return AccumulationRegisters.GoodsToReceive.QueryTextInstructionsForRegistration();

EndFunction

// Returns the text of the request for goods orders for registration
//
// Returns:
//  String - request text
//
Function QueryTextRemnantsOfGoodsForRegistration(TempTableName, FilterByDimensions = Undefined) Export
	
	If FilterByDimensions = Undefined Then
		FilterByDimensions = New Map;
	EndIf;
	
	QueryText =
		AccumulationRegisters.GoodsToReceive.QueryTextBalance(
			TempTableName,
			FilterByDimensions,
			"ToRegister > 0");
	
	QueryText = RequestSchemes.AddSelectionFieldToQuery(QueryText, "0", "RowCode");
	
	QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "Products, Characteristic");
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for duplicates of goods orders for registration
//
// Returns:
//  String - request text
//
Function QueryTextDuplicatesOfProductsForRegistration() Export
	
	Return
	"SELECT
	|	COUNT(*)                    AS DuplicateCount,
	|	GoodsForRegistration.Products   AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic
	|INTO DuplicatesOfProductsForRegistration
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic
	|";
	
EndFunction

#EndRegion

#EndRegion

#Region ReferenceOrder

// Returns an array of order types
//
// Returns:
//  Array of Type -
//
Function TypesOfProducts_() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	
	Return TypesArray;
	
EndFunction

// Returns the name of the order register
//
// Returns:
//  String - 
//
Function RegisterNameOrder() Export
	
	Return "GoodsToReceive";
	
EndFunction

// Returns the name of the dimension of the remainder register that is used as an order
//
// Returns:
//  String - 
//
Function NameDimensionOrder() Export
	
	Return "DocumentInflow";
	
EndFunction

// Returns the use of string code attribute
//
// Returns:
//  Boolean - 
//
Function UseLineCode() Export
	
	Return False;
	
EndFunction

// Returns the synonym of the order.
//
// Returns:
//  String - synonym of the order.
//
Function SynonymForOrder() Export
	
	Return NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
				|ru = 'Заявка на возврат товаров от клиента';
				|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
				|it = 'Richiesta di reso della merce dal cliente';
				|pl = 'Wniosek o zwrot towarów od klienta';
				|tr = 'Müşteriden mal iade talebi'");
	
EndFunction

#EndRegion

#Region DiscrepancyCertificate

// Returns the type of the basis of the act of discrepancy
//
// Returns:
//  EnumRef.TypesOfBaseDocumentsForDiscrepancyReport
//
Function TypeOfBasisOfAct() Export
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi nhận hàng từ bên cất giữ';
				|ru = 'после поступления товаров от хранителя';
				|en = 'after VMI return'; fa = 'after VMI return';
				|it = 'dopo la consegna delle merci dal depositario';
				|pl = 'po otrzymaniu towaru od depozytariusza';
				|tr = 'malların VMI''dan teslim alınmasından sonra'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận hàng hóa từ bên cho thuê kho (tạo mới)';
				|ru = 'Акт о расхождениях после поступления товаров от хранителя (создание)';
				|en = 'Discrepancy report following the VMI return (create)'; fa = 'Discrepancy report following the VMI return (create)';
				|it = 'Акт о расхождениях после поступления товаров от хранителя (создание)';
				|pl = 'Discrepancy report following the VMI return (create)';
				|tr = 'Malların VMI''dan teslim alınmasından sonra tutarsızlık raporu (oluştur)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi nhận được từ nơi cất giữ';
				|ru = 'Акт о расхождениях после поступления товаров от хранителя';
				|en = 'Discrepancy report following VMI return'; fa = 'Discrepancy report following VMI return';
				|it = 'Atto sulle discrepanze dopo la ricezione degli articoli dal magazzino';
				|pl = 'Protokół o odchyleniu po wpływie od opiekuna';
				|tr = 'Malların VMI''dan teslim alınmasından sonra tutarsızlık raporu'");
	
EndFunction

// Returns the hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ReportAgreementHint() Export
	
	Return NStr("vi = 'Hợp đồng mà có lập chứng từ tiếp nhận';
				|ru = 'Договор, в рамках которого оформлено поступление';
				|en = 'Contract under which the receiving is registered'; fa = 'Contract under which the receiving is registered';
				|it = 'Accordo in base al quale è stata formalizzata la ricezione';
				|pl = 'Umowa, w której wydano zezwolenie';
				|tr = 'Teslim alma işleminin gerçekleştirildiği sözleşme'");
	
EndFunction

// Returns a hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ActAgreementHint() Export
	
	Return NStr("vi = 'Thỏa thuận mà hàng hóa được chuyển giao.';
				|ru = 'Соглашение, по которому был передан товар.';
				|en = 'Agreement under which the goods have been transferred.'; fa = 'Agreement under which the goods have been transferred.';
				|it = 'Accordo in base al quale è stata consegnata la merce.';
				|pl = 'Umowa, na mocy której towary zostały przekazane.';
				|tr = 'Ürünlerin transfer edildiği anlaşma.'");
	
EndFunction

// Returns the title of the document base
//
// Returns:
//  String - 
//
Function TitleOfDocumentGroundsOfAct() Export
	
	Return NStr("vi = 'Theo tiếp nhận từ nơi bảo quản';
				|ru = 'Поступление от хранителя';
				|en = 'Receipt from the custodian'; fa = 'Receipt from the custodian';
				|it = 'Consegne dal depositario';
				|pl = 'Wpływ do depozytariusza';
				|tr = 'Emanetçiden teslim alma'");
	
EndFunction

// Returns the title based on
//
// Parameters:
//  AddPartner - Boolean -
//
// Returns:
//  String - 
//
Function HeadlineOnGrounds(AddPartner = True) Export
	
	If AddPartner Then
		Return NStr("vi = 'Theo tiếp nhận từ nơi bảo quản';
					|ru = 'По поступлениям от хранителя';
					|en = 'By receipts from the custodian'; fa = 'By receipts from the custodian';
					|it = 'Per consegne dal depositario';
					|pl = 'W przypadku wpływów od depozytariusza';
					|tr = 'Emanetçiden teslim alıma göre'");
	Else
		Return NStr("vi = 'Theo tiếp nhận';
					|ru = 'По поступлениям';
					|en = 'By receipts'; fa = 'بر اساس دریافت‌ها';
					|it = 'Secondo gli arrivi';
					|pl = 'Wg wpływów';
					|tr = 'Makbuzlara ilişkin'");
	EndIf;
	
EndFunction

//Returns a description of the field with comments
//
// Returns:
//  String - 
//
Function BasementVendorComment() Export
	
	Return NStr("vi = 'Ghi chú của người nhận cất giữ về chênh lệch trong dòng';
				|ru = 'Комментарии хранителя по расхождениям в строке';
				|en = 'Custodian comments to line discrepancies'; fa = 'Custodian comments to line discrepancies';
				|it = 'Commenti del magazzino sulle discrepanze nella riga';
				|pl = 'Uwagi depozytariusza odnośnie do odchylenia w wierszu';
				|tr = 'Satırdaki tutarsızlıklara ilişkin emanetçi yorumları'");
	
EndFunction

//Returns the name of the column, who gives the comment
//
// Returns:
//  String - 
//
Function CustomerComment() Export
	
	Return NStr("vi = 'từ người cất giữ';
				|ru = 'от хранителя';
				|en = 'from custodian'; fa = 'from custodian';
				|it = 'от хранителя';
				|pl = 'od depozytariusza';
				|tr = 'emanetçiden'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.ReturnFromCustodian;
	
EndFunction

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with suppliers
//
// Returns:
//  Boolean - 
//
Function AgreementsWithSuppliersAreApplicable() Export
	
	Return True;
	
EndFunction

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

// Returns the use of a request for the return of goods from customers attribute
//
// Returns:
//  Boolean -
//
Function UseOrders() Export
	
	Return GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");

EndFunction

// Returns the attribute using receipts for multiple orders.
//
// Returns:
//  Boolean -
//
Function UseReceiptForMultipleOrders() Export

	Return False;

EndFunction

// Returns the attribute using the advanced features of the customer's order
//
// Returns:
//  Boolean -
//
Function UseAdvancedFeaturesOfSalesOrder() Export
	
	Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//    Object                         - FormDataStructure, DocumentObject.ReceiptOfGoodsFromCustodian - The object from which the main parameters for the search will be taken.
//    CurrencySelection_2                  - Boolean - Search by the specified settlement currency of the Contract you are looking for (True) or
//												without taking into account the settlement currency (False).
//    FilterByLineOfBusiness - Boolean - Conduct a search in the specified area of activity of the desired Contract (True) or
//												in all directions (False).
//
// Returns:
//    CatalogRef.CounterpartyContracts - the default counterparty agreement.
//
Function GetDefaultContract(Object, CurrencySelection_2 = True, FilterByLineOfBusiness = True) Export
	
	BusinessOperation = ContractBusinessTransaction();
	
	Currency = Undefined;
	If CurrencySelection_2 Then
		Currency = Object.Currency;
	EndIf;
	
	LineOfBusiness = Undefined;
	If FilterByLineOfBusiness
	   And GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	Contract = SalesServer.GetDefaultContract(Object, BusinessOperation, Currency, LineOfBusiness);
	
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
//  Form - ClientApplicationForm - Contains:
//           * Items - FormAllItems - Contains:
//              ** Partner - TextBox - Contains:
//                  *** Title - String -
//              ** GoodsSelectTransferredGoods - FormCommand - Contains:
//                  *** Title - String -
//              ** CloseRequest - FormCommand - Contains:
//                  *** Title - String -
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	Object    = Form.Object;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);
	
	Form.HeaderOfSubmittedProductSelectionForm = "";

	Items.Partner.Title                         = NStr("vi = 'Khách hàng';
														|ru = 'Клиент';
														|en = 'Customer'; fa = 'مشتری';
														|it = 'Cliente';
														|pl = 'Customer';
														|tr = 'Müşteri'");
	Items.GoodsSelectTransferredGoods.Title = "";
	Items.PagesOrder.Visible                   = UseOrders();
	Items.ByReference.Title                  = NStr("vi = 'Theo giấy đề nghị';
													|ru = 'По заявке';
													|en = 'By request'; fa = 'بر اساس درخواست';
													|it = 'Per richiesta';
													|pl = 'Wg zamówienia';
													|tr = 'Talebe göre'");
	Items.ByReferences.Title                 = NStr("vi = 'Theo giấy đề nghị';
													|ru = 'По заявкам';
													|en = 'By requests'; fa = 'بر اساس درخواست‌ها';
													|it = 'Per richieste';
													|pl = 'Wg zamówień';
													|tr = 'Taleplere göre'");
	Items.CloseRequest.Title                   = NStr("vi = 'Đóng giấy đề nghị';
														|ru = 'Закрыть заявку';
														|en = 'Close request'; fa = 'بستن درخواست';
														|it = 'Chiudi la richiesta';
														|pl = 'Zamknij zgłoszenie';
														|tr = 'Talebi kapat'");
	Items.CloseApplications.Title                   = NStr("vi = 'Đóng giấy đề nghị';
															|ru = 'Закрыть заявки';
															|en = 'Close requests'; fa = 'بستن درخواست‌ها';
															|it = 'Chiudere richieste';
															|pl = 'Zamknij zgłoszenia';
															|tr = 'Talepleri kapat'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	
	Items.PriceKind.Visible                      = True;
	Items.GoodsPrice.Visible                   = True;
	Items.GoodsSum.Visible                  = True;
	Items.GoodsFillInPricesByPriceKind.Visible = True;
	Items.GoodsFillInCCDNumbers.Visible     = True;
	Items.GroupInTotal.Visible                  = True;
	
	Items.GoodsFillInPricesUnderAgreement.Visible = False;
	Items.ReusablePackageReturn.Visible = Object.ReusablePackageReturn;
	
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
	
	//Terms
	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.ConsignmentSales25", False));
		
	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Date", "Object.Date", LinkedValueChangeMode.DontChange));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	Items.Terms.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Terms.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	If Not Items.Find("LineOfBusiness") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
	// Type of price
	If Not Items.Find("PriceKind") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
		
		Items.PriceKind.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
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
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (создание)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluşturma)'"), ObjectPresentation());
	Else
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 от %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), ObjectPresentation(), Number, Date);
	EndIf;
	
	Return Title;
	
EndFunction

// Returns a representation of the document receipt of goods from the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Tiếp nhận hàng hóa từ nơi bảo quản';
				|ru = 'Поступление товаров от хранителя';
				|en = 'VMI return'; fa = 'برگشت VMI';
				|it = 'Arrivo di merci dal consegnatario';
				|pl = 'Wpływ towarów od magazyniera';
				|tr = 'Malların VMI''dan teslim alınması'");
	
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
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Handler = ReceiptFromCommissionAgent;
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		Handler = ReceiptFromToller;
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		Handler = ReturnFromProcessingCompany;
	Else
		Handler = Documents.ReceiptOfGoodsFromCustodian;
	EndIf;
	
	Return Handler;
	
EndFunction

// Gets an action handler depending on the order type
//
// Parameters:
//  BasisType - EnumRef.TypesOfBaseDocumentsForDiscrepancyReport -
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function HandlerForActionsBasedOnReportBaseType(BasisType) Export
	
	If BasisType = ReceiptFromCommissionAgent.TypeOfBasisOfAct() Then
		BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	ElsIf BasisType = ReceiptFromToller.TypeOfBasisOfAct() Then
		BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5;
	ElsIf BasisType = ReturnFromProcessingCompany.TypeOfBasisOfAct() Then
		BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
	Else
		BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian;
	EndIf;
	
	Return ActionHandler(BusinessOperation);
	
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
			Enums.BusinessTransactions.ReturnFromCustodian);
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission") Then
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.ReturnFromCommissionAgent);
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.ReceiptFromToller2_5);
	EndIf;
	Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
		And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
#EndIf
