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
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	TransferOfGoodsToBaileeLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.TransferOfGoodsToBailee") Then
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
		
		TransferOfGoodsToBaileeLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
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

// Adds the document creation command "Transfer of goods to the custodian".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee)
		And GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.TransferOfGoodsToBailee.FullName();
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(
															Metadata.Documents.TransferOfGoodsToBailee);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions =
			"UseTransferToCustodyWithRightOfSale,
			|UseSalesCommission,
			|UseProductionByThirdParty2_5";
		
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
		Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
		GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment"));
	OperationSettings.Insert(
		Enums.BusinessTransactions.TransferToCommissionAgent,
		GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment"));
	OperationSettings.Insert(
		Enums.BusinessTransactions.TransferToToller2_5,
		GetFunctionalOption("UseDiscrepancyReportFollowingShipmentByTransfersToSubcontractor2_5"));
	For Each SettingUpOperation In OperationSettings Do
		
		If Not SettingUpOperation.Value Then
			Continue;
		EndIf;
		
		BusinessOperation = SettingUpOperation.Key;
		
		Command = Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
		If Command <> Undefined Then
				
			AttachableCommands.AddCommandVisibilityCondition(
				Command, "BusinessOperation", BusinessOperation, DataCompositionComparisonType.Equal);
				
			Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
			Command.Presentation = Handler.ReportFormHeader();
		
		EndIf;
		
	EndDo;
	
	Command = Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReceiptFromKeeper(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	Command = Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReceiptFromCommissionAgent(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToCommissionAgent,
			DataCompositionComparisonType.Equal);
	EndIf;
	Command = Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReturnFromProcessor(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToToller2_5,
			DataCompositionComparisonType.Equal);
	EndIf;
	Command = Documents.RequestForReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		ListAvailableOperations = New Array();
		ListAvailableOperations.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
		ListAvailableOperations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			ListAvailableOperations,
			DataCompositionComparisonType.InList);
	EndIf;
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	TransferOfGoodsToBaileeLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	Documents.GoodsReceiptForStorage.AddCreateCommandBasedOnTransferToProcessor(GenerationCommands);
EndProcedure

// Adds a command to create the document "Transfer of goods to the custodian" based on the Order to the customer.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add the new command on the basis of the order
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	
	CommissionSale = AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee) 
			And GetFunctionalOption("UseSalesCommission");
	
	TransferToStorage = AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee);
	
	If TransferToStorage Or CommissionSale Then
		
		HandlerName = "GenerationByReferenceTMClient.TransferOfGoodsToCustodianIsCarriedOutOnBasisOfOrder";
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Id       = "CreateByOrderReference";
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(
															Metadata.Documents.TransferOfGoodsToBailee);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.MultipleChoice  = True;
		
		FOArray = New Array();
		If TransferToStorage Then
			FOArray.Add("UseTransferToCustodyWithRightOfSale");
		EndIf;
		
		If CommissionSale Then
			FOArray.Add("UseSalesCommission");
		EndIf;
		
		CreateBasedOnCommand.FunctionalOptions = StrConcat(FOArray,",");
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command to create a document "Transfer of goods to the custodian" based on the Order to the processor.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   Undefined, ValueTableRow of See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands -
//
Function AddCreateBasedOnOrderToProcessorCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee) Then
		
		HandlerName = "ProcessingByThirdPartiesClient.TransferOfGoodsToCustodianOrOnBasisOfOrderToProcessor";
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Id       = "CreateBasedOnOrderToProcessor";
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Chuyển giao nguyên liệu cho bên nhận gia công';
														|ru = 'Передача сырья переработчику';
														|en = 'Goods issue — Subcontracting services received'; fa = 'صدور کالا — خدمات پیمانکاری فرعی دریافتی';
														|it = 'Trasferimento di materie prime al subfornitore';
														|pl = 'Przenoszenie surowców do procesora';
														|tr = 'Hammaddelerin fason üreticiye transferi'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.MultipleChoice  = True;
		CreateBasedOnCommand.FunctionalOptions = "UseProductionByThirdParty2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

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
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToToller2_5,
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	TransferOfGoodsToBaileeLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return TransferOfGoodsToBaileeLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
//  String - The text of the request for the temporary reflection table in the regl accounting
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return TransferOfGoodsToBaileeLocalization.RequestTextTTReflectedInLocalAccounting();
	
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
																			|tr = 'Yalnızca ""%1"" faaliyet destinasyonları '"));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterials22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterialsForStage22));
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
//  Form - ClientApplicationForm
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	DocumentProcessingProcedure.NameOfFormElementIsSeparate = "GoodsWithAssignment";
	DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate = "ProductsTeamGroupSeparately";
	DocumentProcessingProcedure.OrderDetailsName = "TransferByOrders";
	
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
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.TransferOfGoodsToBailee";
	
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	
	SeriesSpecificationParameters.SelectionPlanning = True;
	SeriesSpecificationParameters.FactOfSelection         = True;
	
	SeriesSpecificationParameters.WarehouseFieldName = "Warehouse";
	SeriesSpecificationParameters.NameOfSenderWarehouseField = "Warehouse";
	SeriesSpecificationParameters.NameOfRecipientWarehouseField  = "Contract";
	
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentSender");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("TransferByOrders");
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
//	SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
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
	|	Goods.AssignmentSender AS AssignmentSender,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
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
	|	Goods.AssignmentSender AS AssignmentSender,
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
	|	Goods.AssignmentSender,
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
	|	SetOfSeries.AssignmentSender AS AssignmentSender,
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
	|	SetOfSeries.AssignmentSender AS AssignmentSender,
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
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
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
	|	END                      AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|									AND ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods)
	|								OR (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent)
	|								OR ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|										AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|								THEN
	|									CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatusOfGoodsTransferred
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.AssignmentSender = ProductsToRequest.AssignmentSender
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.AssignmentSender = SeriesToRequest.AssignmentSender
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
	|	Statuses.LineNumber                          AS LineNumber,
	|	Statuses.BatchesIndicationStatus                  AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                        AS BatchesIndicationStatus
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
	|		Document.TransferOfGoodsToBailee.Goods AS T
	|	WHERE
	|		T.Ref IN(&References)
	|	) AS T
	|		INNER JOIN Document.TransferOfGoodsToBailee AS Header
	|		ON (Header.Ref = T.Ref)
	|WHERE
	|	NOT Header.TransferByOrders
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
//	Structure - initialized document execution structure.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureOfAdditionalRequests = New Structure("QueryTextTTGoodsOrderInvoiceShipped",
											QueryTextTTGoodsOrderInvoiceShipped());
	
	StructureState.Insert("ThisIsAnInvoice",                   True);
	StructureState.Insert("DisplayShipmentTables",        1);
	StructureState.Insert("NameTSGoodsShipment",            "Goods");
	StructureState.Insert("NameOfInvoiceForOrdersField",      "TransferByOrders");
	StructureState.Insert("ThereAreSummaryShipmentIndicators", True);
	StructureState.Insert("StructureOfAdditionalRequests",           StructureOfAdditionalRequests);
	StructureState.Insert("NameOfAmountField",                   "Sum");
	
	Return StructureState
	
EndFunction

#EndRegion

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.TransferOfGoodsToBailee - Object of the document to
//																			get the base text from.
//
// Returns:
//	Structure- Structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	ARAPObjectSettings = ARAPAccountingServer.ARAPObjectSettings(False,,Object.Terms, Object.Contract);
	
	BaseStructure = BaseStructure(Object, ARAPObjectSettings);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		BaseStructure.Basis = BaseStructure.Basis + ", " + NStr("vi = 'Chuyển đến lưu trữ.';
																|ru = 'передача на хранение';
																|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
																|it = 'trasferimento in deposito';
																|pl = 'przekazanie do przechowywania';
																|tr = 'depoya transfer'");
	Else
		BaseStructure.Basis = NStr("vi = 'Chuyển đến lưu trữ.';
									|ru = 'Передача на хранение.';
									|en = 'VMI fill-up.'; fa = 'VMI fill-up.';
									|it = 'Trasferimento in deposito.';
									|pl = 'Przenieś na przechowanie.';
									|tr = 'Depoya transfer.'");
	EndIf;
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base"attribute.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.TransferOfGoodsToBailee - the document object to
//																			get the selection list for.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis", New TypeDescription("String", , , , New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms", New TypeDescription("Date", , , , ,
																			New DateQualifiers(DateFractions.Date)));
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String", , , ,
																			New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
		AddedRow.Basis = BaseStructure.Basis + ", " + NStr("ru = 'передача на хранение';
															|vi = 'VMI fill-up';
															|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
															|it = 'trasferimento in deposito';
															|pl = 'przekazanie do przechowywania';
															|tr = 'depoya transfer'");
		
		If ValueIsFilled(BaseStructure.ReferenceDocumentDateForPrintForms)
			And ValueIsFilled(BaseStructure.BaseDocumentNumber) Then
			
			ExtendedText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 số %2 ngày %3';
																						|ru = '%1 № %2 от %3';
																						|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
																						|it = '%1 № %2 dal %3';
																						|pl = '%1 nr %2 z dnia %3.';
																						|tr = '%2sayılı %3tarihli %1'"),
																						BaseStructure.Basis,
																						BaseStructure.BaseDocumentNumber,
																						Format(BaseStructure.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			
			ExtendedText = ExtendedText + ", " + NStr("vi = 'Chuyển đến lưu trữ.';
														|ru = 'передача на хранение';
														|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
														|it = 'trasferimento in deposito';
														|pl = 'przekazanie do przechowywania';
														|tr = 'depoya transfer'");
			
			AddedRow = TableOfBases_.Add();
			FillPropertyValues(AddedRow, BaseStructure);
			
			AddedRow.Basis = ExtendedText;
			
		EndIf;
		
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByOrders);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis + ", " + NStr("ru = 'передача на хранение';
															|vi = 'VMI fill-up';
															|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
															|it = 'trasferimento in deposito';
															|pl = 'przekazanie do przechowywania';
															|tr = 'depoya transfer'");
	EndIf;
	
	If TableOfBases_.Count() = 0 Then
		AddedRow = TableOfBases_.Add();
		AddedRow.Basis = NStr("ru = 'передача на хранение';
								|vi = 'VMI fill-up';
								|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
								|it = 'trasferimento in deposito';
								|pl = 'przekazanie do przechowywania';
								|tr = 'depoya transfer'");
	EndIf;
	
	Return TableOfBases_;
	
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

// Fills in a table of products based on selection data or an array of orders.
//
// Parameters:
//	SelectionData_ 		- Structure 				- fields that will be used to select order balances for filling in the document.
//	Goods 				- FormDataCollection 		- the product table where the remaining orders will be placed.
//	TransferWarehouse 		- CatalogRef.Warehouses 	- the warehouse where the remaining orders will be selected.
//	AnArrayOfOrders 		- Array 					- orders for which balances will be selected.
//	FillParameters - Structure 				- fill parameters.
//	PackageBarcodes   - ValueTable           - data on brands.
//
Procedure FillByOrderBalances(SelectionData_, Goods, TransferWarehouse, AnArrayOfOrders, FillParameters, PackageBarcodes) Export
	
	DisplayMessage_1    = True;
	SelectionByOrdersOrders = False;
	DesignParameters    = Undefined;
	
	If FillParameters.Property("DisplayMessage_1") Then
		DisplayMessage_1 = FillParameters.DisplayMessage_1;
	EndIf;
	
	If FillParameters.Property("SelectionByOrdersOrders") Then
		SelectionByOrdersOrders = FillParameters.SelectionByOrdersOrders;
	EndIf;
	
	If FillParameters.Property("DesignParameters", DesignParameters) Then
		If DesignParameters <> Undefined Then
			FillingInOrders = DesignParameters.ByOrders;
			FillingByOrders = DesignParameters.ByNotes;
		EndIf;
	EndIf;
	
	// Data on the remaining items of the order
	RequestResultForOrderBalances = GetQueryResultsForOrderBalances(
											SelectionData_, FillParameters, TransferWarehouse, AnArrayOfOrders);
	
	If RequestResultForOrderBalances[9].IsEmpty()
		And RequestResultForOrderBalances[10].IsEmpty()
		And GetFunctionalOption("UseShipmentByRowsInSalesOrder")
		And DisplayMessage_1 Then
		
		ErrorText = ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment();
		
		Raise ErrorText;
		
	EndIf;
	
	ArrayOfCustomersOrders = New Array();
	
	SampleProducts_ = RequestResultForOrderBalances[9].Select();
	
	While SampleProducts_.Next() Do
		If ArrayOfCustomersOrders.Find(SampleProducts_.SalesOrder) = Undefined Then
			ArrayOfCustomersOrders.Add(SampleProducts_.SalesOrder);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("DocumentCurrency",       SelectionData_.Currency);
	Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
	
	Query.Text =
	"SELECT ALLOWED
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref                    AS SalesOrder,
	|	TheOrdersTable.Currency                    AS Currency,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                    AS ConvertToDocumentCurrency
	|FROM
	|	Document.SalesOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED DISTINCT
	|	BEGINOFPERIOD(CombinedOrderTable.Date, DAY) AS Date,
	|	CombinedOrderTable.Currency                    AS Currency,
	|	CombinedOrderTable.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|		TheOrdersTable.Currency                    AS Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		Document.SalesOrder AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency) AS CombinedOrderTable";
	
	Handler = ActionHandler(SelectionData_.BusinessOperation);
	Handler.EditTextOfRequestForConversionToDocumentCurrency(Query.Text);
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultOrderDetails	= ResultsArray[0]; // QueryResult
	ResultSelection			= ResultsArray[1]; // QueryResult
	
	OrderDetails_ = ResultOrderDetails.Select();
	
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency",    New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date",      New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator",      New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	
	Selection = ResultSelection.Select();
	
	While Selection.Next() Do
		NewRow = TableOfExchangeRates.Add();
		FillPropertyValues(NewRow, Selection);
		
		Currency_Rates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date, Selection.LocalAccountingCurrency);
		NewRow.CourseNumerator = Currency_Rates.CourseNumerator;
		NewRow.CourseDenominator = Currency_Rates.CourseDenominator;
	EndDo;
	
	If TableOfExchangeRates.Count() > 0 Then
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, SelectionData_.Date);
	EndIf;
	
	RegistrationProcedure = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
	
	FillByWarehouseDocument = RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst
						And Not SelectionByOrdersOrders;
	
	If DesignParameters <> Undefined Then
		FillByWarehouseDocument = FillingByOrders
							And Not FillingInOrders;
	EndIf;
	
	ShippedStamps = Undefined;
	ShippedGoods_ = RequestResultForOrderBalances[RequestResultForOrderBalances.UBound()].Unload();
	
	If ValueIsFilled(SelectionData_.Ref) Then
		ArrayOfCustomersOrders.Add(SelectionData_.Ref);
	EndIf;
	TransferOfGoodsToBaileeLocalization.GenerateShippedStamps(ArrayOfCustomersOrders, ShippedStamps);
	TransferOfGoodsToBaileeLocalization.ExcludeSoldBrands(ArrayOfCustomersOrders, ShippedStamps);
	PackageBarcodes.Clear();
	If ShippedStamps <> Undefined Then
		For Each TableRow In ShippedStamps Do
			FillPropertyValues(PackageBarcodes.Add(), TableRow);
		EndDo;
	EndIf;
	
	FillInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(SelectionData_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	StructureOfActions.Insert("RecalculateAmount");
	
	RowsToProcess = New Array();
	SampleProducts_.Reset();
	
	While SampleProducts_.Next() Do
		
		QuantityToShip = SampleProducts_.Count;
		
		FillingByOrder = FillByWarehouseDocument
							And SampleProducts_.CheckShipment;
		
		If FillingByOrder Then
			
			SearchParameters = New Structure("SalesOrder, Products, Characteristic, Warehouse, Series");
			FillPropertyValues(SearchParameters, SampleProducts_);
			
			FoundRows = ShippedGoods_.FindRows(SearchParameters);
			
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			ShippedLine = FoundRows[0];
			
			If ShippedLine.Count > 0 Then
				
				If ShippedLine.Count < SampleProducts_.Count Then
					QuantityToShip = ShippedLine.Count;
					ShippedLine.Count = 0;
				Else
					QuantityToShip = SampleProducts_.Count;
					ShippedLine.Count = ShippedLine.Count - SampleProducts_.Count;
				EndIf;
				
			Else
				Continue;
			EndIf;
			
		EndIf;
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_, , "Count");
		
		TabRow.Count			= QuantityToShip;
		TabRow.NumberOfPackages	= QuantityToShip / SampleProducts_.ZoomRatio;
		
		RecalculateAmounts = (QuantityToShip <> SampleProducts_.QuantityInOrder);
		
		If ValueIsFilled(TabRow.PriceKind)
			And Not ValueIsFilled(TabRow.Price) Then
			
		RowsToProcess.Add(TabRow);
			
		ElsIf RecalculateAmounts Then
			
			SumBalance = SampleProducts_.SumBalance;
			
			If FillingByOrder Then
				SumBalance = SumBalance * QuantityToShip / SampleProducts_.Count;
			EndIf;
			
			TabRow.Sum = SumBalance;
			
		EndIf;
		
		If SelectionByOrdersOrders Then
			
			TabRow.QuantityInOrder         = ?(SampleProducts_.RowCode <> 0, QuantityToShip, 0);
			TabRow.PackagingQuantityInTheOrder = ?(SampleProducts_.RowCode<> 0,
													QuantityToShip,
													0) / SampleProducts_.ZoomRatio;
			
			SearchParameters = New Structure("SalesOrder, Products, Characteristic, Warehouse, Series");
			FillPropertyValues(SearchParameters, SampleProducts_);
			
			FoundRows = ShippedGoods_.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then
				
				ShippedLine = FoundRows[0];
				
				If ShippedLine.NumberInProgress > 0 Then
					TabRow.NumberInProgress = ShippedLine.NumberInProgress / SampleProducts_.ZoomRatio;
					ShippedLine.NumberInProgress = 0;
				EndIf;
				
				If ShippedLine.Count > 0 Then
					
					If ShippedLine.Count <= SampleProducts_.Count Then
						TabRow.NoteQuantity         = ShippedLine.Count;
						TabRow.PackagingQuantityInTheNote = ShippedLine.Count / SampleProducts_.ZoomRatio;
						
						ShippedLine.Count = 0;
						ShippedGoods_.Delete(ShippedLine);
					Else
						TabRow.NoteQuantity         = SampleProducts_.Count;
						TabRow.PackagingQuantityInTheNote = SampleProducts_.Count / SampleProducts_.ZoomRatio;
						
						ShippedLine.Count = ShippedLine.Count - SampleProducts_.Count;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		OrderDetails_.Reset();
		
		OrderFound = OrderDetails_.FindNext(TabRow.SalesOrder, "SalesOrder");
		
		FilterParameters = New Structure("Currency, Date");
		FillPropertyValues(FilterParameters, OrderDetails_);
		
		CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
		
		If OrderFound
			And OrderDetails_.ConvertToDocumentCurrency Then
			
			If CurrencyExchangeRate.Count() = 1 Then
				RecalculateAmounts = True;
				
				SourceRateParameters	= New Structure("Currency, CourseNumerator, CourseDenominator",
														OrderDetails_.Currency, CurrencyExchangeRate[0].CourseNumerator, CurrencyExchangeRate[0].CourseDenominator);
				NewRateParameters	= New Structure("Currency, CourseNumerator, CourseDenominator",
														SelectionData_.Currency, StructureOfNewCurrencyRates.CourseNumerator, StructureOfNewCurrencyRates.CourseDenominator);
				
				TabRow.Price	= ProcessingOfExchangeRatesTM.ConvertAtRate(TabRow.Price,
																			SourceRateParameters,
																			NewRateParameters);
				TabRow.Sum	= ProcessingOfExchangeRatesTM.ConvertAtRate(TabRow.Sum,
																			SourceRateParameters,
																			NewRateParameters);
			EndIf;
			
		EndIf;
		
		If TMCommonUseClientServer.HasObjectAttribute(TabRow, "ProductsInSet")
			And TMCommonUseClientServer.HasObjectAttribute(TabRow, "SetIndex")
			And ValueIsFilled(TabRow.ProductsInSet) Then
			
			TabRow.SetIndex = 1;
			
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Goods,
		Undefined);

	If (SelectionByOrdersOrders
			Or FillByWarehouseDocument)
		And ShippedGoods_.Count() > 0 Then
		
		For Each ShippedLine In ShippedGoods_ Do
			
			If ShippedLine.Count > 0 Then //If you have shipped more
				
				SearchParameters = New Structure("Products,Characteristic,Warehouse, Series");
				FillPropertyValues(SearchParameters, ShippedLine);
				
				If TypeOf(ShippedLine.SalesOrder) = Handler.OrderType_5() Then
					SearchParameters.Insert("SalesOrder", ShippedLine.SalesOrder)
				EndIf;
				
				FoundRows = Goods.FindRows(SearchParameters);
				
				If SelectionByOrdersOrders Then
					
					If FoundRows.Count() > 0 Then
						TabRow = FoundRows[0];
						
						TabRow.NoteQuantity         = TabRow.NoteQuantity + ShippedLine.Count;
						TabRow.PackagingQuantityInTheNote = TabRow.PackagingQuantityInTheNote + ShippedLine.Count
																* (TabRow.PackagingQuantityInTheNote / TabRow.Count);
					Else
						TabRow = Goods.Add();
						FillPropertyValues(TabRow, ShippedLine);
						
						TabRow.NoteQuantity         = ShippedLine.Count;
						TabRow.PackagingQuantityInTheNote = ShippedLine.Count;
					EndIf;
					
				ElsIf ShippedLine.AdvancedWarehousingOnShipment Then
					
					If FoundRows.Count() > 0 Then
						TabRow = FoundRows[0];
						
						TabRow.NumberOfPackages = TabRow.NumberOfPackages + ShippedLine.Count
														* (TabRow.NumberOfPackages / TabRow.Count);
						TabRow.Count         = TabRow.Count + ShippedLine.Count;
					Else
						TabRow = Goods.Add();
						FillPropertyValues(TabRow, ShippedLine);
						
						TabRow.Count         = ShippedLine.Count;
						TabRow.NumberOfPackages = ShippedLine.Count;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// This function checks the order document when creating an expense order.
//
// Parameters:
//	ReferenceOrder - DefinedType.ShipmentReferenceOrder - link to the order document.
//	Warehouse        - CatalogRef.Warehouses                - Link to an item in the Warehouses reference list.
//
// Returns:
//	Structure - verification results:
//		* Cancel 						- Boolean - True if the checks passed with errors, otherwise-False.
//		* ErrorText 					- String - Must be filled in when Failure = True.
//		* DateOfShipment 					- Date - 
//		* GroupOfWarehousesAtYourDisposal 	- Boolean - A group of warehouses is selected at the disposal.
//		* UseAdvancedWarehousing 	- Boolean - The warehouse uses an order scheme.
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
						|tr = '""%ReferenceOrder%"" belgesindeki ""Ambar"" alanı doldurulmamış. Sipariş oluşturulamaz.'");
		ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
		
		ReturnStructure.ErrorText = ErrorText;
		ReturnStructure.Operation    = "Cancel";
		
		Return ReturnStructure
		
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
	
	If Data.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		ObjectPresentation = NStr("vi = 'Chuyển đi ký gửi';
									|ru = 'Передача на комиссию';
									|en = 'Consignment sales'; fa = 'فروش امانی';
									|it = 'Trasferimento in conto vendita';
									|pl = 'Przekazanie do komisu';
									|tr = 'Konsinye satış'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5 Then
		ObjectPresentation = NStr("vi = 'Chuyển giao nguyên vật liệu cho bên nhận gia công';
									|ru = 'Передача сырья переработчику';
									|en = 'Goods issue — Subcontracting services received'; fa = 'صدور کالا — خدمات پیمانکاری فرعی دریافتی';
									|it = 'Trasferimento di materie prime al subfornitore';
									|pl = 'Przenoszenie surowców do procesora';
									|tr = 'Hammaddelerin fason üreticiye transferi'");
	Else
		ObjectPresentation = NStr("vi = 'Chuyển hàng cho bên cho thuê kho';
									|ru = 'Передача товаров хранителю';
									|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
									|it = 'Consegna di merci al depositario';
									|pl = 'Przekazanie towaru do magazyniera';
									|tr = 'Malların emanetçiye transferi'");
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
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.SalesOrder          AS SalesOrder,
	|	DocumentData.Date                  AS ReferenceDate,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.Terms            AS Terms,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Warehouse                 AS Warehouse,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.Comment           AS Comment,
	|	DocumentData.Manager              AS Manager,
	|	DocumentData.Author                 AS Author,
	|	DocumentData.SalesOpportunity                AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.Department         AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	DocumentData.DocumentAmount        AS DocumentAmount,
	|	DocumentData.DeletionMark       AS DeletionMark,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.Patch           AS Patch,
	|	DocumentData.ReversedDocument  AS ReversedDocument,
	|	DocumentData.CorrectedDocument  AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.TransferByOrders     AS TransferByOrder,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.TransferOfGoodsToBailee AS DocumentData
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
	MetadataIdentifier = Common.MetadataObjectID("Document.TransferOfGoodsToBailee");
	
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
	Query.SetParameter("TransferForMultipleOrders",    Not ValueIsFilled(Attributes.SalesOrder));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("NumberForPrinting",                  NumberForPrinting);
	Query.SetParameter("ContractInformation",           ContractInformation);
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Attributes.BusinessOperation);
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
							Handler.UseAdvancedFeaturesOfSalesOrder());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
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
	|			THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		ELSE TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
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
	|	&Period                     AS Period,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssignmentSender.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.AssignmentSender
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	&Ref                     AS Document,
	|	SeriesTable.Warehouse          AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer) AS WarehouseOperation,
	|	CASE
	|		WHEN NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|				OR (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|				AND NOT SeriesTable.Products.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent)
	|			THEN UNDEFINED
	|		ELSE &Partner
	|	END                       AS Recipient,
	|	CASE
	|		WHEN NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END                       AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.TransferOfGoodsToBailee.SetOfSeries AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                     AS Period,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssignmentSender.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.AssignmentSender
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	&Ref                     AS Document,
	|	SeriesTable.Warehouse          AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer) AS WarehouseOperation,
	|	CASE
	|		WHEN NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|				OR (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|				AND NOT SeriesTable.Products.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent)
	|			THEN UNDEFINED
	|		ELSE &Partner
	|	END                       AS Recipient,
	|	CASE
	|		WHEN NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END                       AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS SeriesTable
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
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|	AND &TransferByOrder
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|	AND &TransferByOrder
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|	AND GoodsTable.RowCode = 0
	|	AND &TransferByOrder
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|	AND GoodsTable.RowCode = 0
	|	AND &TransferByOrder
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	SubstituteTextUseAdvancedCustomerOrderFeatures(QueryText, "GoodsTable.Ref", , "GoodsTable");
	
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Warehouse                   AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	Document.TransferOfGoodsToBailee AS DocumentData
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
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS DocumentTable
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
	|		WHEN HeaderData_.TransferByOrders
	|			AND &UseAdvancedOrderFeatures
	|			AND DocumentGoods.SalesOrder <> UNDEFINED
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
	|	DocumentGoods.AssignmentSender AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.TransferByOrders
	|			AND &UseAdvancedOrderFeatures
	|			AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.TransferByOrders
	|			AND &UseAdvancedOrderFeatures
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		LEFT JOIN Document.TransferOfGoodsToBailee AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|";
	
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
	|		WHEN HeaderData_.TransferByOrders
	|			AND &UseAdvancedOrderFeatures
	|			AND DocumentGoods.SalesOrder <> UNDEFINED
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
	|	DocumentGoods.AssignmentSender AS Purpose,
	|	DocumentGoods.Purpose			AS PurposeForConnection,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.TransferByOrders
	|			AND &UseAdvancedOrderFeatures
	|			AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	CASE
	|		WHEN HeaderData_.TransferByOrders
	|			AND &UseAdvancedOrderFeatures
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		LEFT JOIN Document.TransferOfGoodsToBailee AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|";
	
	SubstituteTextUseAdvancedCustomerOrderFeatures(
		TextOfDocumentDataRequest, "HeaderData_", "&UseAdvancedOrderFeatures");
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Purpose", "PurposeForConnection");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.SynonymForDocumentTable = "DocumentGoods";
	ParametersOfModularHolding.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	ParametersOfModularHolding.MetadataObject = Metadata.Documents.TransferOfGoodsToBailee;
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(Query,
																QueryTexts,
																Registers,
																TextOfDocumentDataRequest,
																ParametersOfModularHolding);
	
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
	|	&Period                           AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END                             AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END                             AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber       AS CCDNumber,
	|	TableTypesOfStocks_.Count     AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation            AS BusinessOperation,
	|	UNDEFINED                      AS VATTaxation,
	|	UNDEFINED                      AS CorItemsLocationAttributes,
	|	UNDEFINED                      AS CorInventoryOwnerAttribute,
	|	&Organization                      AS ShipmentCompany,
	|	TableTypesOfStocks_.Products   AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	FALSE                              AS Primary
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                           AS Period,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
	|		ELSE TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|	END AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END                             AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber       AS CCDNumber,
	|	TableTypesOfStocks_.Count     AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation            AS BusinessOperation,
	|	UNDEFINED                      AS VATTaxation,
	|	UNDEFINED                      AS CorItemsLocationAttributes,
	|	UNDEFINED                      AS CorInventoryOwnerAttribute,
	|	UNDEFINED                      AS ShipmentCompany,
	|	TableTypesOfStocks_.Products   AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TRUE                            AS Primary
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = 
	"SELECT
	|	InventoryKinds.LineNumber                AS LineNumber,
	|	InventoryKinds.Ref                     AS Ref,
	|	InventoryKinds.SalesOrder               AS SalesOrder,
	|	&Organization                           AS Organization,
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	InventoryKinds.InventoryOwnerAttribute.Currency          AS Currency,
	|	InventoryKinds.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	InventoryKinds.RowID        AS RowID,
	|	InventoryKinds.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType      AS InventoryType,
	|	InventoryKinds.SetAccountingDimension      AS SetAccountingDimension,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey   AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	AnalysisOfTransmittedProducts.DimensionKey AS AnalysisOfTransmittedProducts,
	|	AnalysisOfTransmittedProductsWithoutAssignment.DimensionKey AS AnalysisOfTransmittedProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.Count                 AS Count,
	|	InventoryKinds.QuantityByGBRN           AS QuantityByGBRN,
	|	InventoryKinds.Sum                      AS Sum,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	ISNULL(InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|			AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProducts
	|		ON InventoryKinds.ItemsLocationAttributesGoodsAtPartners = AnalysisOfTransmittedProducts.DimensionKey
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProductsWithoutAssignment
	|		ON AnalysisOfTransmittedProducts.Products = AnalysisOfTransmittedProductsWithoutAssignment.Products
	|			AND AnalysisOfTransmittedProducts.Characteristic = AnalysisOfTransmittedProductsWithoutAssignment.Characteristic
	|			AND AnalysisOfTransmittedProducts.Series = AnalysisOfTransmittedProductsWithoutAssignment.Series
	|			AND AnalysisOfTransmittedProducts.StorageLocation = AnalysisOfTransmittedProductsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.ProductCostElement
	|WHERE
	|	InventoryKinds.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		
		Return;
		
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
		Query.Parameters.Currency, Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

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
	|		Document.TransferOfGoodsToBailee.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributes.Products      = Dimension.Products
	|				AND Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributes.Series          = Dimension.Series
	|				AND Goods.ItemsLocationAttributes.StorageLocation  = Dimension.StorageLocation
	|				AND &EmptyAssignment                                = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Products   AS Products,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Characteristic AS Characteristic,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Series          AS Series,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.StorageLocation  AS Warehouse
	|	FROM
	|		Document.TransferOfGoodsToBailee.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributesGoodsAtPartners.Products      = Dimension.Products
	|				AND Goods.ItemsLocationAttributesGoodsAtPartners.Characteristic = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributesGoodsAtPartners.Series          = Dimension.Series
	|				AND Goods.ItemsLocationAttributesGoodsAtPartners.StorageLocation  = Dimension.StorageLocation
	|				AND &EmptyAssignment                                                = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	) AS AnalystTable";
	
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	//Sets
	QueryAnalyst = New Query;
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	Goods.SetAccountingDimension.ProductsInSet   AS ProductsInSet,
	|	Goods.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS Goods
	|		LEFT JOIN InformationRegister.SetAccountingDimension AS Dimension
	|		ON Goods.SetAccountingDimension.ProductsInSet      = Dimension.ProductsInSet
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
	
	FullDocumentName      = "Document.TransferOfGoodsToBailee";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	TextOfRequestToRedefineBusinessTransaction = "
		|	CASE
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|		ELSE GoodsTable.Ref.BusinessOperation
		|	END";
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
								Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("UseAdvancedFeaturesOfSalesOrder",
								GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",         """""");
	RedefiningParameterCalculation.Insert("TransferByOrder",      "GoodsTable.Ref.TransferByOrders");
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
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.TransferOfGoodsToBailee.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.TransferByOrders
		|		OR TabPart.RowCode = 0
		|		OR ISNULL(TabPart.SalesOrder.ThisIsOrderAsInvoice, FALSE)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
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
	
	#Region Moving_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes      	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	UNDEFINED 			 							AS VATActivityType,
	|	UNDEFINED			 							AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.Manager				AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
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
	|	Document.TransferOfGoodsToBailee AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT (DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|		AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND (TableTypesOfStocks_.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion
	
	#Region Moving_Goods_TransferToCommission
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	UNDEFINED 			 							AS VATActivityType,
	|	UNDEFINED			 							AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	UNDEFINED										AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END 									AS AccountingSection,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END 									AS CorAccountingSection,
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.TransferOfGoodsToBailee AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
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
	JobPrintingRules.VHFWarehouses				= True;
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
	
	If Not ThisIsPartner Then
		
		// Expenditure invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ExpenseToPrint";
		PrintCommand.Presentation = NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
										|ru = 'Расходная накладная';
										|en = 'Sales invoice'; fa = 'فاکتور فروش';
										|it = 'Bolla di consegna';
										|pl = 'Faktura wydanie na zewnątrz';
										|tr = 'Satış faturası'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintManagement.AddCommandVisibilityCondition(
			PrintCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
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
	EndIf;
	
	// Transfer of goods to the custodian
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Chuyển hàng cho người trông coi';
									|ru = 'Передача товаров хранителю';
									|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
									|it = 'Consegna di merci al depositario';
									|pl = 'Przekazanie towaru do magazyniera';
									|tr = 'Malların emanetçiye transferi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
													  ComparisonType.Equal);
	
	// Transfer of goods to the commission agent
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "InvoiceToConsignee";
	PrintCommand.Presentation = NStr("vi = 'Chuyển giao hàng hóa cho người nhận ký gửi';
									|ru = 'Передача товаров комиссионеру';
									|en = 'Customer stock fill-up documents'; fa = 'Customer stock fill-up documents';
									|it = 'Trasferimento articoli al commissionario';
									|pl = 'Wydanie towarów komisantowi';
									|tr = 'Müşteri stoku doldurma'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.TransferToCommissionAgent,
													  ComparisonType.Equal);
	
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
		PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														  "BusinessOperation",
														  Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
														  ComparisonType.Equal);
		
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
		PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														  "BusinessOperation",
														  Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
														  ComparisonType.Equal);
		
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
		PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														  "BusinessOperation",
														  Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
														  ComparisonType.Equal);
		
	EndIf;
	
	
	If Not ThisIsPartner Then
		// Task for the selection of goods
		DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
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
		PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														  "BusinessOperation",
														  Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
														  ComparisonType.Equal);
		
	EndIf;
	
	TransferOfGoodsToBaileeLocalization.AddPrintCommands(PrintCommands);
	
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
			NStr("vi = 'Chuyển hàng cho người trông coi';
				|ru = 'Передача товаров хранителю';
				|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
				|it = 'Consegna di merci al depositario';
				|pl = 'Przekazanie towaru do magazyniera';
				|tr = 'Malların emanetçiye transferi'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects),
			,
			"Document.TransferOfGoodsToBailee.PF_MXL_TransferOfGoodsToBailee");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceToConsignee") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceToConsignee",
			NStr("vi = 'Chuyển giao hàng hóa cho người nhận ký gửi';
				|ru = 'Передача товаров комиссионеру';
				|en = 'Customer stock fill-up documents'; fa = 'Customer stock fill-up documents';
				|it = 'Trasferimento articoli al commissionario';
				|pl = 'Wydanie towarów komisantowi';
				|tr = 'Müşteri stoku doldurma'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects),
			,
			"Document.TransferOfGoodsToBailee.PF_MXL_TransferOfGoodsToBailee");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ExpenseToPrint") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ExpenseToPrint",
			NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
				|ru = 'Расходная накладная';
				|en = 'Sales invoice'; fa = 'فاکتور فروش';
				|it = 'Bolla di consegna';
				|pl = 'Faktura wydanie na zewnątrz';
				|tr = 'Satış faturası'"),
			CreatePrintedFormInvoice(ObjectsArray, PrintObjects),
			,
			"Document.TransferOfGoodsToBailee.PF_MXL_ExpenseToPrint");
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
	
	TransferOfGoodsToBaileeLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects,
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
				Metadata.Documents.TransferOfGoodsToBailee.FullName(),
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
			"ExpenseToPrint");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			CreatePrintedFormInvoice(PrintKit.Objects, PrintObjects));
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
		StructureOfTypes.Insert("Document.TransferOfGoodsToBailee", PrintKit.Objects);
		
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
		StructureOfTypes.Insert("Document.TransferOfGoodsToBailee", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	TransferOfGoodsToBaileeLocalization.CreateSetOfPrintedForms(
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.TransferOfGoodsToBailee",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"ExpenseToPrint",
																			NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
																				|ru = 'Расходная накладная';
																				|en = 'Sales invoice'; fa = 'فاکتور فروش';
																				|it = 'Bolla di consegna';
																				|pl = 'Faktura wydanie na zewnątrz';
																				|tr = 'Satış faturası'"),
																			0);
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"Invoice",
																			NStr("vi = 'Chuyển hàng cho người trông coi';
																				|ru = 'Передача товаров хранителю';
																				|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
																				|it = 'Consegna di merci al depositario';
																				|pl = 'Przekazanie towaru do magazyniera';
																				|tr = 'Malların emanetçiye transferi'"),
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
																				|tr = 'Mal seçimi görevi'"),
																			0);
	
	TransferOfGoodsToBaileeLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

// The function gets the data for the formation of printed forms and sales invoice.
//
// Parameters:
//	Print parametres-Structure-structure of additional print parameters,
//	ObjectsArray  - Array    - Array of links to objects that need to be printed.
//
// Returns:
//	SpreadsheetDocument - the printed form is a bill of lading of documents for the transfer of goods to the custodian.
//
Function CreatePrintedFormInvoice(ObjectsArray, PrintObjects)
	
	UsePackages = GetFunctionalOption("UseItemPackages");
	
	RequestForWarehouses = New Query;
	RequestForWarehouses.Text =
	"SELECT DISTINCT
	|	DocumentGoods.Ref AS Ref,
	|	DocumentGoods.Warehouse  AS Warehouse,
	|	DocumentGoods.Warehouse.UseItemsBatch AS UseItemsBatch
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|
	|TOTALS BY
	|	UseItemsBatch";
	
	RequestForWarehouses.SetParameter("ObjectsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	QueryResult = RequestForWarehouses.Execute();
	SetPrivilegedMode(False);
	
	ObjectsTree = QueryResult.Unload(QueryResultIteration.ByGroups);
	
	For Each UsingSeries In ObjectsTree.Rows Do
		
		RequestForProducts = New Query;
		RequestForProducts.SetParameter("WarehouseArray",  UsingSeries.Rows.UnloadColumn("Warehouse"));
		RequestForProducts.SetParameter("ObjectsArray", UsingSeries.Rows.UnloadColumn("Ref"));
		
		If UsingSeries.UseItemsBatch Then
			
			QueryTextByGoods =
			"SELECT
			|	DocumentGoods.Ref         AS Ref,
			|	DocumentGoods.Warehouse          AS Warehouse,
			|	DocumentGoods.Products   AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Package       AS Package,
			|	""""                           AS Series,
			|	DocumentGoods.Count     AS Count,
			|	DocumentGoods.NumberOfPackages AS NumberOfPackages
			|INTO TableOfGoods
			|FROM
			|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
			|WHERE
			|	DocumentGoods.Ref IN(&ObjectsArray)
			|	AND DocumentGoods.Warehouse IN(&WarehouseArray)
			|	AND NOT (DocumentGoods.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
			|														VALUE(Enum.ItemsTypes.ReusablePackage))
			|		AND DocumentGoods.BatchesIndicationStatusInWarehouses IN(2, 4, 6, 8))
			|
			|UNION ALL
			|
			|SELECT
			|	Series_Document.Ref         AS Ref,
			|	Series_Document.Warehouse          AS Warehouse,
			|	Series_Document.Products   AS Products,
			|	Series_Document.Characteristic AS Characteristic,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|	Series_Document.Series          AS Series,
			|	Series_Document.Count     AS Count,
			|	Series_Document.Count     AS NumberOfPackages
			|FROM
			|	Document.TransferOfGoodsToBailee.SetOfSeries AS Series_Document
			|		INNER JOIN Document.TransferOfGoodsToBailee.Goods AS GoodsTable
			|		ON Series_Document.Ref = GoodsTable.Ref
			|			AND Series_Document.Products = GoodsTable.Products
			|			AND Series_Document.Characteristic = GoodsTable.Characteristic
			|			AND Series_Document.Warehouse = GoodsTable.Warehouse
			|WHERE
			|	Series_Document.Ref IN(&ObjectsArray)
			|	AND Series_Document.Warehouse IN(&WarehouseArray)
			|	AND Series_Document.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
			|													VALUE(Enum.ItemsTypes.ReusablePackage))
			|
			|GROUP BY
			|	Series_Document.Ref,
			|	Series_Document.Warehouse,
			|	Series_Document.Products,
			|	Series_Document.Characteristic,
			|	Series_Document.Series,
			|	Series_Document.Count,
			|	Series_Document.Count
			|
			|HAVING
			|	MAX(GoodsTable.BatchesIndicationStatusInWarehouses) IN(2, 4, 6, 8, 10)
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 1
			|SELECT
			|	TableOfGoods.Ref         AS Ref,
			|	TableOfGoods.Warehouse          AS Warehouse,
			|	TableOfGoods.Products   AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Package       AS Package,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END                         AS Series,
			|	SUM(TableOfGoods.NumberOfPackages) AS NumberOfPackages,
			|	SUM(TableOfGoods.Count) AS Count
			|INTO SummaryTableOfProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Warehouse,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Package,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 2
			|SELECT
			|	TableOfGoods.Ref             AS Ref,
			|	TableOfGoods.Ref.Number       AS Number,
			|	TableOfGoods.Ref.Date        AS Date,
			|	TableOfGoods.Ref.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
			|	TableOfGoods.Ref.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected,
			|	TableOfGoods.Ref.Organization AS Organization,
			|	TableOfGoods.Ref.Organization.Prefix AS Prefix,
			|	TableOfGoods.Ref.Counterparty  AS Counterparty,
			|	TableOfGoods.Warehouse              AS Warehouse,
			|	TableOfGoods.Products       AS Products,
			|	TableOfGoods.Products.Code   AS Code,
			|	TableOfGoods.Products.SKU AS SKU,
			|	TableOfGoods.Products.DescriptionFull AS ProductPresentation,
			|	TableOfGoods.Characteristic     AS Characteristic,
			|	TableOfGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	PRESENTATION(TableOfGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	&QueryTextUnitOfMeasureDescription AS PresentationOfPackingUnit,
			|	CASE
			|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
			|			THEN UNDEFINED
			|		ELSE TableOfGoods.Package.Description
			|	END                             AS Package,
			|	TableOfGoods.Series.Description AS BatchPresentation,
			|	TableOfGoods.Count         AS Count,
			|	TableOfGoods.NumberOfPackages AS NumberOfPackages,
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings,
			|	CASE
			|		WHEN TableOfGoods.Ref.ToReturnReusablePackage
			|				AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN TRUE
			|		ELSE FALSE
			|	END                             AS ThisIsReusablePackage
			|FROM
			|	SummaryTableOfProducts AS TableOfGoods
			|
			|ORDER BY
			|	Ref,
			|	Warehouse,
			|	Products,
			|	Characteristic
			|
			|TOTALS BY
			|	Ref,
			|	Warehouse,
			|	Products,
			|	Characteristic
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 3
			|SELECT
			|	TableOfGoods.Ref         AS Ref,
			|	TableOfGoods.Warehouse          AS Warehouse,
			|	TableOfGoods.Products   AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series.Description AS BatchPresentation
			|FROM
			|	TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|	AND NOT TableOfGoods.Series IS NULL
			|
			|ORDER BY
			|	Ref,
			|	Warehouse,
			|	Products,
			|	Characteristic,
			|	BatchPresentation";
			
			QueryTextByGoods = StrReplace(QueryTextByGoods, "&QueryTextPackagingFactor",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"TableOfGoods.Package",
					"TableOfGoods.Products"));
			
			QueryTextByGoods = StrReplace(QueryTextByGoods, "&QueryTextUnitOfMeasureDescription",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
					"Description",
					"TableOfGoods.Package",
					"TableOfGoods.Products"));
			
			RequestForProducts.Text = QueryTextByGoods;
			
			SetPrivilegedMode(True);
			ResultsArray = RequestForProducts.ExecuteBatch();
			SetPrivilegedMode(False);
			
			ResultPrintData			= ResultsArray[2]; // QueryResult
			ResultSelectionBySeries		= ResultsArray[3]; // QueryResult
			
			PrintData    = ResultPrintData.Select(QueryResultIteration.ByGroups);
			SelectionBySeries = ResultSelectionBySeries.Select();
			
		Else
			
			QueryTextByGoods = 
			"SELECT
			|	TransferGoods.Ref             AS Ref,
			|	TransferGoods.Ref.Number       AS Number,
			|	TransferGoods.Ref.Date        AS Date,
			|	TransferGoods.Ref.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
			|	TransferGoods.Ref.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected,
			|	TransferGoods.Ref.Organization AS Organization,
			|	TransferGoods.Ref.Organization.Prefix AS Prefix,
			|	TransferGoods.Ref.Counterparty  AS Counterparty,
			|	TransferGoods.Warehouse AS Warehouse,
			|	TransferGoods.Products       AS Products,
			|	TransferGoods.Products.Code   AS Code,
			|	TransferGoods.Products.SKU AS SKU,
			|	TransferGoods.Products.DescriptionFull AS ProductPresentation,
			|	TransferGoods.Characteristic     AS Characteristic,
			|	TransferGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
			|	PRESENTATION(TransferGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	&QueryTextUnitOfMeasureDescription AS PresentationOfPackingUnit,
			|	CASE
			|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
			|			THEN UNDEFINED
			|		ELSE TransferGoods.Package.Description
			|	END AS Package,
			|	"""" AS BatchPresentation,
			|	TransferGoods.Count AS Count,
			|	TransferGoods.NumberOfPackages AS NumberOfPackages,
			|	NULL AS BatchUsageSettings,
			|	CASE
			|		WHEN TransferGoods.Ref.ToReturnReusablePackage
			|				AND TransferGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ThisIsReusablePackage
			|FROM
			|	Document.TransferOfGoodsToBailee.Goods AS TransferGoods
			|WHERE
			|	TransferGoods.Ref IN(&ObjectsArray)
			|	AND TransferGoods.Warehouse IN(&WarehouseArray)
			|
			|ORDER BY
			|	Ref,
			|	Warehouse,
			|	TransferGoods.LineNumber
			|
			|TOTALS BY
			|	Ref,
			|	Warehouse,
			|	Products,
			|	Characteristic";
			
			QueryTextByGoods = StrReplace(QueryTextByGoods, "&QueryTextPackagingFactor",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"TransferGoods.Package",
					"TransferGoods.Products"));
			
			QueryTextByGoods = StrReplace(QueryTextByGoods, "&QueryTextUnitOfMeasureDescription",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
					"Description",
					"TransferGoods.Package",
					"TransferGoods.Products"));
			
			RequestForProducts.Text = QueryTextByGoods;
			
			SetPrivilegedMode(True);
			QueryResult = RequestForProducts.Execute();
			SetPrivilegedMode(False);
			
			PrintData = QueryResult.Select(QueryResultIteration.ByGroups);
			
		EndIf;
		
		FirstDocument = True;
		ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
		NameOfCodeColumn = ColumnOfCodes.ColumnName;
		PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
		OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_TransferOfGoodsToBailee_ExpenseToPrint";
		
		Template = PrintManagement.PrintFormTemplate("Document.TransferOfGoodsToBailee.PF_MXL_ExpenseToPrint");
		
		WidthOfMissingAreas = 0;
		
		If Not OutputCodes Then
			WidthOfMissingAreas = Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf;
		
		If Not UsePackages Then
			WidthOfMissingAreas = WidthOfMissingAreas
											+ Template.Area("NumberOfPackagesColumn").ColumnWidth;
			WidthOfMissingAreas = WidthOfMissingAreas
											+ Template.Area("PresentationColumnOfPackages").ColumnWidth;
		EndIf;
		
		// Expand the "Goods column" by the width of the missing areas
		Template.Area("ProductColumn_").ColumnWidth = Template.Area("ProductColumn_").ColumnWidth
														+ WidthOfMissingAreas;
		
		DocumentAttributes = New Structure("Number, Date, Prefix, Presentation, DateOfDocumentBeingCorrected, NumberOfDocumentBeingCorrected");
		
		While PrintData.Next() Do
			
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
			
			FillPropertyValues(DocumentAttributes, PrintData);
			
			SampleByWarehouse = PrintData.Select(QueryResultIteration.ByGroups);
			
			While SampleByWarehouse.Next() Do
				
				If Not FirstDocument Then
					SpreadsheetDocument.PutHorizontalPageBreak();
				EndIf;
				
				FirstDocument = False;
				
				Area = Template.GetArea("Title");
				
				DataStructureHeader = New Structure;
				DataStructureHeader.Insert("TitleText", NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
															|ru = 'Расходная накладная';
															|en = 'Sales invoice'; fa = 'فاکتور فروش';
															|it = 'Bolla di consegna';
															|pl = 'Faktura wydanie na zewnątrz';
															|tr = 'Satış faturası'", Common.DefaultLanguageCode()));
				
				BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
				
				Area.Parameters.Fill(DataStructureHeader);
				SpreadsheetDocument.Put(Area);
				
				Area = Template.GetArea("Header");
				
				PresentationOfOrder = TMCommonUseClientServer.GenerateDocumentTitle(
					DocumentAttributes,
					NStr("vi = 'Chuyển hàng cho người trông coi';
						|ru = 'Передача товаров хранителю';
						|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
						|it = 'Consegna di merci al depositario';
						|pl = 'Przekazanie towaru do magazyniera';
						|tr = 'Malların emanetçiye transferi'", Common.DefaultLanguageCode()));
				
				HeaderDataStructure_ = New Structure;
				HeaderDataStructure_.Insert("Warehouse",                     SampleByWarehouse.Warehouse);
				HeaderDataStructure_.Insert("WarehousePresentation_",       SampleByWarehouse.Warehouse);
				HeaderDataStructure_.Insert("PresentationOfOrder", PresentationOfOrder);
				
				Area.Parameters.Fill(HeaderDataStructure_);
				SpreadsheetDocument.Put(Area);
				
				Area = Template.GetArea("Vendor");
				
				RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(
					PrintFormGeneration.InformationAboutLegalEntity(SampleByWarehouse.Organization,
																?(ValueIsFilled(SampleByWarehouse.DateOfDocumentBeingCorrected),
																	SampleByWarehouse.DateOfDocumentBeingCorrected,
																	SampleByWarehouse.Date)),
					"FullDescr");
				
				DataStructureProvider = New Structure;
				DataStructureProvider.Insert("Organization",              SampleByWarehouse.Organization);
				DataStructureProvider.Insert("RepresentationOfTheOrganization", RepresentationOfTheOrganization);
				
				Area.Parameters.Fill(DataStructureProvider);
				SpreadsheetDocument.Put(Area);
				
				Area = Template.GetArea("Customer");
				
				PartnerPresentation_ = PrintFormGeneration.OrganizationDescription(
					PrintFormGeneration.InformationAboutLegalEntity(SampleByWarehouse.Counterparty,
																?(ValueIsFilled(SampleByWarehouse.DateOfDocumentBeingCorrected),
																	SampleByWarehouse.DateOfDocumentBeingCorrected,
																	SampleByWarehouse.Date)),
					"FullDescr");
				
				DataStructureProvider.Insert("Counterparty",            SampleByWarehouse.Counterparty);
				DataStructureProvider.Insert("PartnerPresentation_", PartnerPresentation_);
				
				Area.Parameters.Fill(DataStructureProvider);
				SpreadsheetDocument.Put(Area);
				
				Area = Template.GetArea("TableHeader|BeginningOfTheLine");
				SpreadsheetDocument.Put(Area);
				
				If OutputCodes Then
					Area = Template.GetArea("TableHeader|ColumnOfCodes");
					
					DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
					
					Area.Parameters.Fill(DataStructureCodes);
					SpreadsheetDocument.Join(Area);
				EndIf;
				
				Area = Template.GetArea("TableHeader|ProductColumn_");
				SpreadsheetDocument.Join(Area);
				
				If UsePackages Then
					Area = Template.GetArea("TableHeader|PackingColumns");
					SpreadsheetDocument.Join(Area);
				EndIf;
				
				Area = Template.GetArea("TableHeader|QuantityColumns");
				SpreadsheetDocument.Join(Area);
				
				StartOfLineArea		 = Template.GetArea("TableRow|BeginningOfTheLine");
				AreaColumnCodes		 = Template.GetArea("TableRow|ColumnOfCodes");
				ProductColumnArea_	 = Template.GetArea("TableRow|ProductColumn_");
				PackagingColumnArea	 = Template.GetArea("TableRow|PackingColumns");
				AreaQuantityColumn = Template.GetArea("TableRow|QuantityColumns");
				
				LineCount = 1;
				
				SamplingByTSLinks = SampleByWarehouse.Select(QueryResultIteration.ByGroups);
				
				While SamplingByTSLinks.Next() Do
					
					SamplingByTSProduct = SamplingByTSLinks.Select(QueryResultIteration.ByGroups);
					
					While SamplingByTSProduct.Next() Do
						
						SamplingByTSLines = SamplingByTSProduct.Select(QueryResultIteration.ByGroups);
						
						FirstRow             = True;
						UnitString    = "";
						StringOfPackages           = "";
						CountRow         = "";
						NumberOfPackagesString = "";
						
						While SamplingByTSLines.Next() Do
							
							If SamplingByTSLines.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
								
								If FirstRow Then
									
									DataStructureLineNumber = New Structure("LineNumber", LineCount);
									StartOfLineArea.Parameters.Fill(DataStructureLineNumber);
									
									LineCount = LineCount + 1;
									
									SpreadsheetDocument.Put(StartOfLineArea);
									
									If OutputCodes Then
										DataStructureCodes = New Structure("CodeValue", SamplingByTSLines[NameOfCodeColumn]);
										
										AreaColumnCodes.Parameters.Fill(DataStructureCodes);
										SpreadsheetDocument.Join(AreaColumnCodes);
									EndIf;
									
									TheStructureOfTheSearch = New Structure;
									TheStructureOfTheSearch.Insert("Ref",         SamplingByTSLines.Ref);
									TheStructureOfTheSearch.Insert("Warehouse",          SamplingByTSLines.Warehouse);
									TheStructureOfTheSearch.Insert("Products",   SamplingByTSLines.Products);
									TheStructureOfTheSearch.Insert("Characteristic", SamplingByTSLines.Characteristic);
									
									SeriesString = "";
									
									While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
										SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
									EndDo;
									
									If StrLen(SeriesString) <> 0 Then
										SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
									EndIf;
									
									AdditionalParametersForGettingNameToPrint =
										ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
									AdditionalParametersForGettingNameToPrint.ReturnContainers = SamplingByTSLines.ThisIsReusablePackage;
									AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
									
									OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
										SamplingByTSLines.ProductPresentation,
										SamplingByTSLines.CharacteristicPresentation,
										,
										SeriesString,
										AdditionalParametersForGettingNameToPrint);
									
									ProductDataStructure = New Structure("OwnGoods", OwnGoods);
									
									ProductColumnArea_.Parameters.Fill(ProductDataStructure);
									SpreadsheetDocument.Join(ProductColumnArea_);
									
									FirstRow = False;
									
								EndIf;
								
								If UsePackages Then
									StringOfPackages = StringOfPackages + SamplingByTSLines.PresentationOfPackingUnit + Chars.LF;
									NumberOfPackagesString = NumberOfPackagesString + SamplingByTSLines.NumberOfPackages + Chars.LF;
								EndIf;
								
								CountRow      = CountRow + SamplingByTSLines.Count + Chars.LF;
								UnitString = UnitString + SamplingByTSLines.PresentationOfBasicUnitOfMeasure
														+ Chars.LF;
								
								ProductWithSeriesInstance = True;
								
							Else
								
								DataStructureLineNumber = New Structure("LineNumber", LineCount);
								StartOfLineArea.Parameters.Fill(DataStructureLineNumber);
								
								LineCount = LineCount + 1;
								
								SpreadsheetDocument.Put(StartOfLineArea);
								
								If OutputCodes Then
									DataStructureCodes = New Structure("CodeValue", SamplingByTSLines[NameOfCodeColumn]);
									
									AreaColumnCodes.Parameters.Fill(DataStructureCodes);
									SpreadsheetDocument.Join(AreaColumnCodes);
								EndIf;
								
								AdditionalParametersForGettingNameToPrint =
									ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
								AdditionalParametersForGettingNameToPrint.ReturnContainers = SamplingByTSLines.ThisIsReusablePackage;
								AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
								
								OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
									SamplingByTSLines.ProductPresentation,
									SamplingByTSLines.CharacteristicPresentation,
									,
									SamplingByTSLines.BatchPresentation,
									AdditionalParametersForGettingNameToPrint);
								
								ProductDataStructure = New Structure("OwnGoods", OwnGoods);
								
								ProductColumnArea_.Parameters.Fill(ProductDataStructure);
								SpreadsheetDocument.Join(ProductColumnArea_);
								
								If UsePackages Then
									PackagingColumnArea.Parameters.Fill(SamplingByTSLines);
									SpreadsheetDocument.Join(PackagingColumnArea);
								EndIf;
								
								AreaQuantityColumn.Parameters.Fill(SamplingByTSLines);
								SpreadsheetDocument.Join(AreaQuantityColumn);
								
								ProductWithSeriesInstance = False;
								
							EndIf;
							
						EndDo;
						
						If ProductWithSeriesInstance Then
							If UsePackages Then
								DataStructurePackingColumn = New Structure;
								DataStructurePackingColumn.Insert("NumberOfPackages",                    NumberOfPackagesString);
								DataStructurePackingColumn.Insert("PresentationOfPackingUnit", StringOfPackages);
								
								PackagingColumnArea.Parameters.Fill(DataStructurePackingColumn);
								SpreadsheetDocument.Join(PackagingColumnArea);
							EndIf;
							
							DataStructureQuantityColumn = New Structure;
							DataStructureQuantityColumn.Insert("Count",                           CountRow);
							DataStructureQuantityColumn.Insert("PresentationOfBasicUnitOfMeasure", UnitString);
							
							AreaQuantityColumn.Parameters.Fill(DataStructureQuantityColumn);
							SpreadsheetDocument.Join(AreaQuantityColumn);
							
						EndIf;
						
					EndDo;
					
				EndDo;
				
				Area = Template.GetArea("TableFooter|BeginningOfTheLine");
				SpreadsheetDocument.Put(Area);
				
				If OutputCodes Then
					Area = Template.GetArea("TableFooter|ColumnOfCodes");
					SpreadsheetDocument.Join(Area);
				EndIf;
				
				Area = Template.GetArea("TableFooter|ProductColumn_");
				SpreadsheetDocument.Join(Area);
				
				If UsePackages Then
					Area = Template.GetArea("TableFooter|PackingColumns");
					SpreadsheetDocument.Join(Area);
				EndIf;
				
				Area = Template.GetArea("TableFooter|QuantityColumns");
				SpreadsheetDocument.Join(Area);
				
				Area = Template.GetArea("Signatures");
				
				TextOfResultingLine = NStr("vi = 'Số lượng các dòng là: %TotalItems_1%';
											|ru = 'Всего наименований %TotalItems_1%';
											|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
											|it = 'Totale articoli %TotalItems_1%';
											|pl = 'Razem pozycji %TotalItems_1%';
											|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
				TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", LineCount-1);
				
				DataStructureHeader.Insert("TotalString", TextOfResultingLine);
				
				Area.Parameters.Fill(DataStructureHeader);
				SpreadsheetDocument.Put(Area);
				
			EndDo;
			
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
				PrintData.Ref);
			
		EndDo;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// This function generates a printed form of documents for transferring goods to the custodian.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - printed form of documents for the transfer of goods to the custodian.
//
Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	GoodsHandover.Ref          AS Ref,
	|	GoodsHandover.Number           AS Number,
	|	GoodsHandover.Date            AS Date,
	|	GoodsHandover.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	GoodsHandover.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected,
	|	GoodsHandover.Partner         AS Partner,
	|	GoodsHandover.Counterparty      AS Recipient,
	|	GoodsHandover.Organization     AS Organization,
	|	GoodsHandover.Organization.Prefix AS Prefix,
	|	GoodsHandover.Currency          AS Currency,
	|	GoodsHandover.IssuiedBy        AS VacationProduced,
	|	GoodsHandover.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsHandover.Ref         AS Ref,
	|	GoodsHandover.LineNumber    AS LineNumber,
	|	KitConfigurations.Ref    AS ItemKitConfiguration,
	|	KitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.SetPricingOption AS SetPricingOption,
	|	GoodsHandover.ProductsInSet   AS ProductsInSet,
	|	GoodsHandover.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsHandover.Products   AS Products,
	|	GoodsHandover.Characteristic AS Characteristic,
	|	CASE
	|		WHEN GoodsHandover.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsHandover.Products.UnitOfMeasure
	|		ELSE GoodsHandover.Package
	|	END                          AS UnitOfMeasure,
	|	GoodsHandover.Package       AS Package,
	|	CASE
	|		WHEN GoodsHandover.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor1
	|	END                          AS ZoomRatio,
	|	GoodsHandover.Count     AS Count,
	|	GoodsHandover.NumberOfPackages AS NumberOfPackages,
	|	GoodsHandover.Sum / GoodsHandover.NumberOfPackages AS Price,
	|	GoodsHandover.Sum          AS Sum
	|INTO Goods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS GoodsHandover
	|	LEFT JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON KitConfigurations.Owner = GoodsHandover.ProductsInSet
	|		AND KitConfigurations.Characteristic = GoodsHandover.ItemVariantOfSet
	|		AND KitConfigurations.Main
	|WHERE
	|	GoodsHandover.Ref IN(&DocumentsArray)
	|
	|INDEX BY
	|	GoodsHandover.Ref,
	|	GoodsHandover.ProductsInSet,
	|	GoodsHandover.ItemVariantOfSet
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
	|		WHEN NestedQuery.Ref.ToReturnReusablePackage
	|				AND NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
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
			"GoodsHandover.Package",
			"GoodsHandover.Products"));
	
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
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_TransferOfGoodsToBailee_Invoice";
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[9]; // QueryResult
	
	PrintData		= ResultPrintData.Select();
	SelectionByDocuments	= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate("Document.TransferOfGoodsToBailee.PF_MXL_TransferOfGoodsToBailee");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea,
			PrintData.Ref);
			
		TitleLine = ?(PrintData.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent,
			NStr("vi = 'Chuyển giao hàng hóa cho người nhận ký gửi';
				|ru = 'Передача товаров комиссионеру';
				|en = 'Customer stock fill-up documents'; fa = 'Customer stock fill-up documents';
				|it = 'Trasferimento articoli al commissionario';
				|pl = 'Wydanie towarów komisantowi';
				|tr = 'Müşteri stoku doldurma'", Common.DefaultLanguageCode()),
			NStr("vi = 'Chuyển giao hàng hóa cho người cất giữ';
				|ru = 'Передача товаров хранителю';
				|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
				|it = 'Consegna di merci al depositario';
				|pl = 'Przekazanie towaru do magazyniera';
				|tr = 'Malların emanetçiye transferi'", Common.DefaultLanguageCode()));
			
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
	
	If (GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25()) Then
		
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
		
	EndIf;
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
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
	|	TRUE AS ConsiderVAT,
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
	|	FALSE AS InvoiceToBeRefunded,
	|	FALSE AS PriceIncludesVAT
	|FROM
	|	Document.TransferOfGoodsToBailee AS Documents
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
	|	TRUE AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet                              AS ProductsInSet,
	|	Table.ItemVariantOfSet                            AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Table.Price
	|		ELSE Table.Sum/Table.NumberOfPackages 
	|	END AS Price,
	|	Table.Sum AS Sum,
	|	CASE
	|		WHEN
	|			Table.Ref.ToReturnReusablePackage
	|			AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	0 AS DiscountAmount,
	|	Table.Sum AS AmountWithoutADiscount
	|INTO Goods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND NOT Table.Ref.ToReturnReusablePackage))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.DiscountAmount                       AS DiscountAmount,
	|	Table.AmountWithoutADiscount                    AS AmountWithoutADiscount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref											AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet								AS ProductsInSet,
	|	Goods.ItemVariantOfSet								AS ItemVariantOfSet,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT)                    AS VATRate,
	|	0                                                        AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|	Goods.AmountWithoutADiscount                                    AS AmountWithoutADiscount,
	|	Goods.ThisIsReusablePackage                                 AS ThisIsReusablePackage	
	|FROM (
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
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
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
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

Procedure WhenDefiningCommandToPrintSetOfDocuments(Command) Export
	AttachableCommands.AddCommandVisibilityCondition(Command,
														"BusinessOperation",
														Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
														ComparisonType.Equal);
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
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	TTDocuments.Posted
	|	AND (NOT DocumentGoods.Ref.TransferByOrders
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

// Returns the base text based on the document data and the specified calculation order.
//
// Parameters:
//	Object 			- FormDataStructure, DocumentObject.TransferOfGoodsToBailee - Object of the document to
//																					get the base text from.
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings 							- Procedure of settlements.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object, ARAPObjectSettings)
	
	StructureBase = New Structure("Basis, BaseDocumentNumber, ReferenceDocumentDateForPrintForms");
	
	If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	CounterpartyContracts.NameForPrinting AS Basis,
		|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
		|	CounterpartyContracts.Number AS BaseDocumentNumber
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Ref";
		
		Query.SetParameter("Ref", Object.Contract);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			StructureBase.Basis      = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms  = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	ElsIf (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		And Object.TransferByOrders Then
		
		AnArrayOfOrders = Undefined;
		
		If ValueIsFilled(Object.SalesOrder) Then
			AnArrayOfOrders = New Array;
			AnArrayOfOrders.Add(Object.SalesOrder);
		ElsIf Object.Goods.Count() <> 0 Then
			
			If TypeOf(Object) = Type("Structure") Then
				AnArrayOfOrders = Object.Goods.UnloadColumn("SalesOrder");
			Else
				AnArrayOfOrders = Object.Goods.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
			EndIf;
			
		EndIf;
		
		If AnArrayOfOrders <> Undefined Then
		
			Query = New Query;
			Query.Text = 
			"SELECT ALLOWED
			|	SalesOrders.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
			|	SalesOrders.DateAccordingToInformationFromCustomer  AS DateAccordingToInformationFromCustomer,
			|	SalesOrders.Number                AS Number,
			|	SalesOrders.Date                 AS Date,
			|	&SynonymForOrder                      AS Synonym
			|FROM
			|	Document.SalesOrder AS SalesOrders
			|WHERE
			|	SalesOrders.Ref IN(&AnArrayOfOrders)";
			
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của khách';
														|ru = 'Заказ клиента';
														|en = 'Sales order'; fa = 'سفارش فروش';
														|it = 'Ordine del cliente';
														|pl = 'Zamówienie klienta';
														|tr = 'Satış siparişi'"));
			
			Selection = Query.Execute().Select();
			
			TextForOrders = "";
			OneFoundation  = Selection.Count() = 1;
			
			While Selection.Next() Do
				
				If ValueIsFilled(Selection.NumberAccordingToCustomerData)
					And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
					
					TextForOrders = TextForOrders + ", "
									+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 số %2 ngày %3';
																									|ru = '%1 № %2 от %3';
																									|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
																									|it = '%1 № %2 dal %3';
																									|pl = '%1 nr %2 z dnia %3.';
																									|tr = '%2sayılı %3tarihli %1'"),
																							Selection.Synonym,
																							Selection.NumberAccordingToCustomerData,
																							Format(Selection.DateAccordingToInformationFromCustomer, "DLF=DD"));
					
					DateForOrders  = Selection.DateAccordingToInformationFromCustomer;
					OrderNumber_1 = Selection.NumberAccordingToCustomerData;
					
				Else
					TextForOrders = TextForOrders + ", "
									+ TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
					
					DateForOrders  = Selection.Date;
					OrderNumber_1 = Selection.Number;
				EndIf;
				
			EndDo;
			
			StructureBase.Basis      = TrimAll(Mid(TextForOrders, 3));
			StructureBase.ReferenceDocumentDateForPrintForms  = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = ?(OneFoundation,
												ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1),
												"");
			
		EndIf;
		
	EndIf;
	
	Return StructureBase;
	
EndFunction

// Generates the query result for the undelivered part of orders.
//
// Parameters:
//	SelectionData_        - Structure -               the fields that will be selected remnants of the orders.
//	FillParameters - Structure - 
//	TransferWarehouse       - CatalogRef.Warehouses - the warehouse where the remaining orders will be selected.
//	AnArrayOfOrders       - Array of DocumentRef - orders for which the remaining orders will be selected.
//
// Returns:
//	QueryResult - the result of the request for the unloaded part of orders \ requests.
//
Function GetQueryResultsForOrderBalances(SelectionData_, 
													FillParameters, 
													TransferWarehouse = Undefined, 
													AnArrayOfOrders = Undefined)
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Handler = ActionHandler(SelectionData_.BusinessOperation);
	
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UseAdvancedFeaturesOfSalesOrder = Handler.UseAdvancedFeaturesOfSalesOrder();
	
	ThisIsProductionOfEEU = (Common.ObjectAttributeValue(SelectionData_.Contract, "BusinessOperation") = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
	
	Query.SetParameter("Recorder",   SelectionData_.Ref);
	Query.SetParameter("CurrentDate",   BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Partner",       SelectionData_.Partner);
	Query.SetParameter("Counterparty",    SelectionData_.Counterparty);
	Query.SetParameter("Terms",    SelectionData_.Terms);
	If SelectionData_.BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5 Then 
		Query.SetParameter("EconomicOperationsOfOrders", Handler.EconomicOperationsOfOrders(ThisIsProductionOfEEU));
	Else
		Query.SetParameter("EconomicOperationsOfOrders", Handler.EconomicOperationsOfOrders());
	EndIf;
	Query.SetParameter("Organization",   SelectionData_.Organization);
	Query.SetParameter("UseWarehouseSelection_", ValueIsFilled(TransferWarehouse));
	Query.SetParameter("TransferWarehouse", TransferWarehouse);
	Query.SetParameter("Contract",       SelectionData_.Contract);
	Query.SetParameter("SalesOpportunity",        SelectionData_.SalesOpportunity);
	Query.SetParameter("LineOfBusiness",   SelectionData_.LineOfBusiness);
	Query.SetParameter("ToReturnReusablePackage", SelectionData_.ToReturnReusablePackage);
	
	Query.SetParameter("AnArrayOfOrders",    AnArrayOfOrders);
	Query.SetParameter("SelectByOrder_", AnArrayOfOrders <> Undefined);
	
	Query.SetParameter("ToUseTermsOfSales",    ToUseTermsOfSales);
	Query.SetParameter("UseLinesOfBusiness", UseLinesOfBusiness);
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
								UseAdvancedFeaturesOfSalesOrder);
	
	If TypeOf(SelectionData_) = Type("Structure")
		And SelectionData_.Property("TransferGoods") Then
		
		Query.SetParameter("TransferGoods", SelectionData_.TransferGoods);
		
	Else
		
		ItemsType   = New TypeDescription("CatalogRef.Products");
		TypeOfFeature = New TypeDescription("CatalogRef.ItemsCharacteristics");
		PackageType       = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
		
		TypeOfCodes      = New TypeDescription("Number", New NumberQualifiers(10, 0));
		QuantityType = TMCommonUse.DescriptionOfQuantitativeFieldType();
		
		TransferGoods = New ValueTable;
		TransferGoods.Columns.Add("LineNumber",          TypeOfCodes);
		TransferGoods.Columns.Add("RowCode",            TypeOfCodes);
		TransferGoods.Columns.Add("SalesOrder",         Handler.OrderTypeDescription());
		TransferGoods.Columns.Add("Warehouse",                New TypeDescription("CatalogRef.Warehouses"));
		TransferGoods.Columns.Add("ProductsInSet",   ItemsType);
		TransferGoods.Columns.Add("ItemVariantOfSet", TypeOfFeature);
		TransferGoods.Columns.Add("Products",         ItemsType);
		TransferGoods.Columns.Add("Characteristic",       TypeOfFeature);
		TransferGoods.Columns.Add("Package",             PackageType);
		TransferGoods.Columns.Add("Series",                New TypeDescription("CatalogRef.ItemsBatches"));
		TransferGoods.Columns.Add("Count",           QuantityType);
		TransferGoods.Columns.Add("QuantityInOrder",    QuantityType);
		TransferGoods.Columns.Add("PriceKind",              New TypeDescription("CatalogRef.TypesOfPrices"));
		TransferGoods.Columns.Add("Price",                 TMCommonUse.MoneyFieldTypeDescription());
		TransferGoods.Columns.Add("Sum",                TMCommonUse.MoneyFieldTypeDescription());
		
		Query.SetParameter("TransferGoods", TransferGoods);
		
	EndIf;
	
	Query.Text =
	"SELECT
	|	Warehouses.Ref AS Ref
	|INTO WarehouseGroups
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	&UseWarehouseSelection_
	|	AND Warehouses.Ref IN(&TransferWarehouse)
	|	AND Warehouses.IsFolder
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Warehouses.Ref    AS Ref
	|INTO TransferWarehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT &UseWarehouseSelection_
	|	OR Warehouses.Ref IN(&TransferWarehouse)
	|		AND NOT Warehouses.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	Warehouses.Ref    AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY (
	|		SELECT
	|			WarehouseGroups.Ref
	|		FROM
	|			WarehouseGroups AS WarehouseGroups)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Ref
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TransferGoods.RowCode      AS RowCode,
	|	TransferGoods.SalesOrder   AS SalesOrder,
	|	TransferGoods.Products   AS Products,
	|	TransferGoods.Characteristic AS Characteristic,
	|	TransferGoods.Package       AS Package,
	|	TransferGoods.Series          AS Series,
	|	TransferGoods.Count     AS Count
	|INTO TTTransferGoods
	|FROM
	|	&TransferGoods AS TransferGoods
	|WHERE
	|	TransferGoods.RowCode <> 0;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TTTransferGoods.RowCode         AS RowCode,
	|	TTTransferGoods.SalesOrder      AS SalesOrder,
	|	TTTransferGoods.Products      AS Products,
	|	TTTransferGoods.Characteristic    AS Characteristic,
	|	CAST(TTTransferGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	TTTransferGoods.Series             AS Series,
	|	SUM(TTTransferGoods.Count) AS Count
	|INTO TTGoodsTransferredByOrder
	|FROM
	|	TTTransferGoods AS TTTransferGoods
	|
	|GROUP BY
	|	TTTransferGoods.RowCode,
	|	TTTransferGoods.SalesOrder,
	|	TTTransferGoods.Products,
	|	TTTransferGoods.Characteristic,
	|	TTTransferGoods.Package,
	|	TTTransferGoods.Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	TransferGoods.LineNumber          AS LineNumber,
	|	TransferGoods.RowCode            AS RowCode,
	|	&Recorder                        AS SalesOrder,
	|	CAST(TransferGoods.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	TransferGoods.ProductsInSet   AS ProductsInSet,
	|	TransferGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	CAST(TransferGoods.Products AS Catalog.Products) AS Products,
	|	TransferGoods.Characteristic       AS Characteristic,
	|	CAST(TransferGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	TransferGoods.Series                AS Series,
	|	TransferGoods.Count           AS Count,
	|	TransferGoods.Count           AS QuantityInOrder,
	|	TransferGoods.PriceKind              AS PriceKind,
	|	TransferGoods.Price                 AS Price,
	|	TransferGoods.Sum                AS Sum
	|INTO TTGoodsTransferWithoutOrder
	|FROM
	|	&TransferGoods AS TransferGoods
	|WHERE
	|	TransferGoods.RowCode = 0
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	SalesOrder.Ref AS Ref
	|INTO TTSelectedCustomerOrders
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	NOT SalesOrder.DeletionMark
	|	AND CASE
	|		WHEN &SelectByOrder_
	|			THEN SalesOrder.Ref IN(&AnArrayOfOrders)
	|		ELSE SalesOrder.Partner = &Partner
	|			AND SalesOrder.Counterparty = &Counterparty
	|			AND CASE
	|				WHEN NOT &ToUseTermsOfSales
	|					THEN TRUE
	|				ELSE &CustomerOrderAgreement = &Terms
	|			END
	|			AND SalesOrder.BusinessOperation IN(&EconomicOperationsOfOrders)
	|			AND SalesOrder.Organization = &Organization
	|			AND SalesOrder.Contract = &Contract
	|			AND SalesOrder.SalesOpportunity = &SalesOpportunity
	|			AND CASE
	|				WHEN NOT &UseLinesOfBusiness
	|					THEN TRUE
	|				ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|			END
	|			AND &CustomerSOrderToReturnMultiTurnContainer = &ToReturnReusablePackage
	|	END
	|
	|INDEX BY
	|	Ref
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	GoodsHandover.Ref AS Ref
	|INTO TTSelectedTransfersToGuardian
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	NOT GoodsHandover.DeletionMark
	|	AND CASE
	|		WHEN &SelectByOrder_
	|			THEN GoodsHandover.Ref IN(&AnArrayOfOrders, &Recorder)
	|		ELSE GoodsHandover.Partner = &Partner
	|			AND GoodsHandover.Counterparty = &Counterparty
	|			AND CASE
	|				WHEN NOT &ToUseTermsOfSales
	|					THEN TRUE
	|				ELSE GoodsHandover.Terms = &Terms
	|			END
	|			AND GoodsHandover.Organization = &Organization
	|			AND GoodsHandover.Contract = &Contract
	|			AND GoodsHandover.SalesOpportunity = &SalesOpportunity
	|			AND CASE
	|				WHEN NOT &UseLinesOfBusiness
	|					THEN TRUE
	|				ELSE GoodsHandover.LineOfBusiness = &LineOfBusiness
	|			END
	|			AND GoodsHandover.ToReturnReusablePackage = &ToReturnReusablePackage
	|	END
	|
	|INDEX BY
	|	Ref
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	OrdersTable.RowCode          AS RowCode,
	|	OrdersTable.SalesOrder       AS SalesOrder,
	|	OrdersTable.Warehouse              AS Warehouse,
	|	OrdersTable.Products       AS Products,
	|	OrdersTable.Characteristic     AS Characteristic,
	|	OrdersTable.Series              AS Series,
	|	SUM(OrdersTable.ToRegister) AS Count,
	|	SUM(OrdersTable.Sum)       AS Sum
	|INTO TableBalance
	|FROM
	|	(SELECT
	|		TurnoversByOrders.RowCode          AS RowCode,
	|		TurnoversByOrders.ReferenceOrder       AS SalesOrder,
	|		TurnoversByOrders.Warehouse              AS Warehouse,
	|		TurnoversByOrders.Products       AS Products,
	|		TurnoversByOrders.Characteristic     AS Characteristic,
	|		TurnoversByOrders.Series              AS Series,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister,
	|		(TurnoversByOrders.AmountToBeProcessedTurnover -
	|			TurnoversByOrders.IssuedAmountTurnover) AS Sum
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|	WHERE
	|		((TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|		OR (TurnoversByOrders.AmountToBeProcessedTurnover -
	|			TurnoversByOrders.IssuedAmountTurnover) <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.RowCode      AS RowCode,
	|		OrdersRegisterRecords.ReferenceOrder   AS SalesOrder,
	|		OrdersRegisterRecords.Warehouse          AS Warehouse,
	|		OrdersRegisterRecords.Products   AS Products,
	|		OrdersRegisterRecords.Characteristic AS Characteristic,
	|		OrdersRegisterRecords.Series          AS Series,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE OrdersRegisterRecords.Count
	|		END AS ToRegister,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Sum
	|			ELSE OrdersRegisterRecords.Sum
	|		END AS Sum
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|			INNER JOIN TTSelectedCustomerOrders AS SelectedOrders_1
	|			ON OrdersRegisterRecords.ReferenceOrder = SelectedOrders_1.Ref
	|	
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND &UseAdvancedFeaturesOfSalesOrder
	|		AND OrdersRegisterRecords.Factor IN
	|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1))
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.Warehouse IN(
	|			SELECT
	|				TransferWarehouses.Ref
	|			FROM
	|				TransferWarehouses AS TransferWarehouses)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsFromOrder.RowCode      AS RowCode,
	|		GoodsFromOrder.Ref         AS SalesOrder,
	|		GoodsFromOrder.Warehouse          AS Warehouse,
	|		GoodsFromOrder.Products   AS Products,
	|		GoodsFromOrder.Characteristic AS Characteristic,
	|		GoodsFromOrder.Series          AS Series,
	|		GoodsFromOrder.Count     AS ToRegister,
	|		&OrderGoodsAmountWithVAT      AS Sum
	|	FROM
	|		Document.SalesOrder.Goods AS GoodsFromOrder
	|			INNER JOIN TTSelectedCustomerOrders AS SelectedOrders_1
	|			ON GoodsFromOrder.Ref = SelectedOrders_1.Ref
	|	
	|	WHERE
	|		NOT GoodsFromOrder.Canceled
	|		AND GoodsFromOrder.Warehouse IN(
	|			SELECT
	|				TransferWarehouses.Ref
	|			FROM
	|				TransferWarehouses AS TransferWarehouses)
	|		AND NOT &UseAdvancedFeaturesOfSalesOrder
	|	
	|	) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.RowCode,
	|	OrdersTable.Warehouse,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.Series
	|
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	RowCode,
	|	SalesOrder
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	OrderList.Ref AS Ref
	|INTO TTListOfOrders
	|FROM
	|	TTSelectedCustomerOrders AS OrderList
	|
	|UNION ALL
	|
	|SELECT
	|	OrderList.Ref
	|FROM
	|	TTSelectedTransfersToGuardian AS OrderList
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT
	|	OrderingProducts.Ref.SalesOpportunity        AS SalesOpportunity,
	|	OrderingProducts.LineNumber          AS LineNumber,
	|	TableBalance.SalesOrder      AS SalesOrder,
	|	TableBalance.RowCode         AS RowCode,
	|	TableBalance.Warehouse             AS Warehouse,
	|	&OrderProductsSetProducts   AS ProductsInSet,
	|	&OrderGoodsSetCharacteristics AS ItemVariantOfSet,
	|	TableBalance.Products      AS Products,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	TableBalance.Products.FEACNCode     AS FEACNCode,
	|	TableBalance.Characteristic    AS Characteristic,
	|	&CustomerOrderAssignment          AS Purpose,
	|	CASE
	|		WHEN OrderingProducts.WithAssignment
	|			THEN &CustomerOrderSenderAssignment
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                            AS AssignmentSender,
	|	OrderingProducts.Series                AS Series,
	|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
	|	CASE
	|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1)
	|	END                            AS ZoomRatio,
	|	TableBalance.Count        AS Count,
	|	TableBalance.Count / ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1) AS NumberOfPackages,
	|	OrderingProducts.Count           AS QuantityInOrder,
	|	ISNULL(WaybillGoods.Count, 0) AS QuantityInInvoice,
	|	&OrderProductsTypeOfPrice              AS PriceKind,
	|	OrderingProducts.Price                 AS Price,
	|	OrderingProducts.Sum                AS Sum,
	|	&TableBalancesAmount             AS SumBalance,
	|	OrderingProducts.DateOfShipment         AS DateOfShipment,
	|	OrderingProducts.DeliveryPeriodDays         AS DeliveryPeriodDays,
	|	OrderingProducts.SupplyOption   AS SupplyOption,
	|	CASE
	|		WHEN OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                            AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                            AS CheckShipment
	|FROM
	|	TableBalance AS TableBalance
	|	
	|	INNER JOIN Document.SalesOrder.Goods AS OrderingProducts
	|	ON TableBalance.RowCode = OrderingProducts.RowCode
	|	AND TableBalance.SalesOrder = OrderingProducts.Ref
	|	
	|	LEFT JOIN TTGoodsTransferredByOrder AS WaybillGoods
	|	ON TableBalance.RowCode = WaybillGoods.RowCode
	|	AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED                        AS SalesOpportunity,
	|	TransferGoods.LineNumber          AS LineNumber,
	|	TransferGoods.SalesOrder         AS SalesOrder,
	|	TransferGoods.RowCode            AS RowCode,
	|	TransferGoods.Warehouse                AS Warehouse,
	|	TransferGoods.ProductsInSet   AS ProductsInSet,
	|	TransferGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	TransferGoods.Products         AS Products,
	|	TransferGoods.Products.ItemsType AS ItemsType,
	|	TransferGoods.Products.FEACNCode AS FEACNCode,
	|	TransferGoods.Characteristic       AS Characteristic,
	|	UNDEFINED                        AS Purpose,
	|	UNDEFINED                        AS AssignmentSender,
	|	TransferGoods.Series                AS Series,
	|	TransferGoods.Package             AS Package,
	|	CASE
	|		WHEN TransferGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor3, 1)
	|	END                               AS ZoomRatio,
	|	TransferGoods.Count           AS Count,
	|	TransferGoods.Count / ISNULL(&QueryTextPackagingFactor3, 1) AS NumberOfPackages,
	|	0                                   AS QuantityInOrder,
	|	TransferGoods.Count           AS QuantityInInvoice,
	|	TransferGoods.PriceKind              AS PriceKind,
	|	TransferGoods.Price                 AS Price,
	|	TransferGoods.Sum                AS Sum,
	|	TransferGoods.Sum                AS SumBalance,
	|	UNDEFINED                        AS DateOfShipment,
	|	UNDEFINED                        AS DeliveryPeriodDays,
	|	UNDEFINED                        AS SupplyOption,
	|	CASE
	|		WHEN TransferGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND TransferGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                               AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN TransferGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND TransferGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                               AS CheckShipment
	|FROM
	|	TTGoodsTransferWithoutOrder AS TransferGoods
	|
	|UNION ALL
	|
	|SELECT
	|	OrderingProducts.Ref.SubcontractOrder.SalesOpportunity   AS SalesOpportunity,
	|	OrderingProducts.LineNumber                        AS LineNumber,
	|	TableBalance.SalesOrder                    AS SalesOrder,
	|	TableBalance.RowCode                       AS RowCode,
	|	TableBalance.Warehouse                           AS Warehouse,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	TableBalance.Products                    AS Products,
	|	OrderingProducts.Products.ItemsType       AS ItemsType,
	|	TableBalance.Products.FEACNCode           AS FEACNCode,
	|	TableBalance.Characteristic                  AS Characteristic,
	|	&CustomerOrderAssignmentStage                    AS Purpose,
	|	CASE
	|		WHEN OrderingProducts.WithAssignment
	|			THEN &CustomerOrderSenderAssignment
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                          AS AssignmentSender,
	|	OrderingProducts.Series                              AS Series,
	|	ISNULL(WaybillGoods.Package, OrderingProducts.Package)     AS Package,
	|	CASE
	|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) =
	|				VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1)
	|	END                                          AS ZoomRatio,
	|	TableBalance.Count                      AS Count,
	|	TableBalance.Count
	|		/ ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1) AS NumberOfPackages,
	|	OrderingProducts.Count                         AS QuantityInOrder,
	|	ISNULL(WaybillGoods.Count, 0)        AS QuantityInInvoice,
	|	OrderingProducts.Ref.SubcontractOrder.PriceKind  AS PriceKind,
	|	0                                              AS Price,
	|	0                                              AS Sum,
	|	TableBalance.Sum                           AS SumBalance,
	|	OrderingProducts.DateOfShipment                       AS DateOfShipment,
	|	0                                              AS DeliveryPeriodDays,
	|	OrderingProducts.SupplyOption                 AS SupplyOption,
	|	CASE
	|		WHEN OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                          AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                          AS CheckShipment
	|FROM
	|	TableBalance AS TableBalance
	|	
	|	INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS OrderingProducts
	|	ON TableBalance.RowCode = OrderingProducts.RowCode
	|	AND TableBalance.SalesOrder = OrderingProducts.Ref.SubcontractOrder
	|	
	|	LEFT JOIN TTGoodsTransferredByOrder AS WaybillGoods
	|	ON TableBalance.RowCode = WaybillGoods.RowCode
	|	AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
	|
	|ORDER BY
	|	TableBalance.SalesOrder,
	|	OrderingProducts.LineNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT TOP 1
	|	CustomerOrderGoods.LineNumber AS LineNumber
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref IN(&AnArrayOfOrders)
	|	AND CustomerOrderGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT CustomerOrderGoods.Canceled
	|	AND CustomerOrderGoods.Ref.Posted
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 11
	|SELECT
	|	OrdersTable.SalesOrder   AS SalesOrder,
	|	OrdersTable.Products   AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.Series          AS Series,
	|	SUM(OrdersTable.Count) AS Count,
	|	SUM(OrdersTable.NumberInProgress) AS NumberInProgress,
	|	OrdersTable.Warehouse          AS Warehouse,
	|	OrdersTable.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment
	|FROM
	|	(SELECT
	|		GoodsForIssueBalance.DocumentShipments AS SalesOrder,
	|		GoodsForIssueBalance.Products     AS Products,
	|		GoodsForIssueBalance.Characteristic   AS Characteristic,
	|		GoodsForIssueBalance.Series            AS Series,
	|		GoodsForIssueBalance.ToShipExpense + GoodsForIssueBalance.AssembledReceipt AS Count,
	|		GoodsForIssueBalance.AssemblyInProgressReceipt AS NumberInProgress,
	|		GoodsForIssueBalance.Warehouse            AS Warehouse,
	|		CASE
	|			WHEN GoodsForIssueBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|					AND GoodsForIssueBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                   AS AdvancedWarehousingOnShipment
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|				,
	|				,
	|				,
	|				,
	|				Warehouse IN
	|					(SELECT
	|						TransferWarehouses.Ref
	|					FROM
	|						TransferWarehouses AS TransferWarehouses)
	|
	|				AND DocumentShipments IN
	|					(SELECT
	|						OrderList.Ref
	|					FROM
	|						TTListOfOrders AS OrderList)
	|
	|				AND (DocumentShipments REFS Document.SalesOrder
	|					OR DocumentShipments = &Recorder)
	|
	|			) AS GoodsForIssueBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TurnoversByOrders.ReferenceOrder       AS SalesOrder,
	|		TurnoversByOrders.Products       AS Products,
	|		TurnoversByOrders.Characteristic     AS Characteristic,
	|		TurnoversByOrders.Series              AS Series,
	|		-TurnoversByOrders.IssuedQuantityTurnover AS Count,
	|		0                                      AS NumberInProgress,
	|		TurnoversByOrders.Warehouse              AS Warehouse,
	|		CASE
	|			WHEN TurnoversByOrders.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|					AND TurnoversByOrders.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END                            AS AdvancedWarehousingOnShipment
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|	WHERE
	|		TurnoversByOrders.Recorder <> &Recorder
	|	) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.Series,
	|	OrdersTable.Warehouse,
	|	OrdersTable.AdvancedWarehousingOnShipment
	|
	|HAVING
	|	SUM(OrdersTable.Count) > 0
	|		OR SUM(OrdersTable.NumberInProgress) > 0";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				OrderList.Ref
		|			FROM
		|				TTSelectedCustomerOrders AS OrderList)
		|		AND &UseAdvancedFeaturesOfSalesOrder
		|		AND Warehouse IN
		|			(SELECT
		|					TransferWarehouses.Ref
		|				FROM
		|					TransferWarehouses AS TransferWarehouses)";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.Periodicity = "Recorder";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				OrderList.Ref
		|			FROM
		|				TTSelectedCustomerOrders AS OrderList)
		|		AND &UseAdvancedFeaturesOfSalesOrder
		|		AND Warehouse IN
		|		(SELECT
		|				TransferWarehouses.Ref
		|			FROM
		|				TransferWarehouses AS TransferWarehouses)";
	TableFormationParameters.Group = "Recorder, ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"WaybillGoods.Package",
			"WaybillGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"OrderingProducts.Package",
			"OrderingProducts.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TransferGoods.Package",
			"TransferGoods.Products"));
			
	Handler.EditRequestTextForOrderBalances(Query.Text);
	
	QueryText = Query.Text;
	TransferOfGoodsToBaileeLocalization.ToWorkOutRestrictionsOnTransferringToVMI(QueryText);
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Return QueryResult;
	
EndFunction

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
	
EndProcedure

Function QueryTextDocumentGoods(Filter, JoinText, ConnectionVerificationText = "") Export
	
	If Not ValueIsFilled(ConnectionVerificationText) Then
		ConnectionVerificationText = "NOT DataOfAccounting.ItemsLocationAttributes IS NULL";
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.Package AS Package,
	|	SUM(ISNULL(DataOfAccounting.ToRegister, 0)) AS ToRegister,
	|	SUM(Table.Count) AS QuantityOfGoodsInDocument
	|INTO InventoryAnalytics
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS Table
	|		LEFT JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
	|		ON Table.CCDNumber = CatalogCCDNumbers.Ref
	|		
	|		LEFT JOIN TTAccountingData AS DataOfAccounting
	|		ON &ConnectionMethod
	|WHERE
	|	&ConnectionVerificationText
	|	AND (NOT &CommissionAgentUsesInventoryAccountingByProductBatchID
	|		OR ISNULL(CatalogCCDNumbers.CCDNumberType, UNDEFINED) IN
	|			(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|			VALUE(Enum.CCDNumberTypes.KitRNPT)
	|			)
	|		)
	|	AND &Filter
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemsLocationAttributesGoodsAtPartners,
	|	Table.CCDNumber,
	|	Table.Package
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.Package AS Package,
	|	SUM(ISNULL(DataOfAccounting.ToRegister, 0)) AS ToRegister,
	|	SUM(Table.Count) AS QuantityOfGoodsInDocument
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS Table
	|		LEFT JOIN Catalog.CCDNumbers AS CatalogCCDNumbers
	|		ON Table.CCDNumber = CatalogCCDNumbers.Ref
	|
	|		LEFT JOIN TTAccountingData AS DataOfAccounting
	|		ON &ConnectionMethod
	|WHERE
	|	&ConnectionVerificationText
	|	AND &CommissionAgentUsesInventoryAccountingByProductBatchID
	|	AND ISNULL(CatalogCCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.CCDNumber)) = VALUE(Enum.CCDNumberTypes.CCDNumber)
	|	AND &Filter
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemsLocationAttributesGoodsAtPartners,
	|	Table.CCDNumber,
	|	Table.Package
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributesGoodsAtPartners,
	|	CCDNumber,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TransferGoods.Ref AS Ref,
	|	TransferGoods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	TransferGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	InventoryAnalytics.CCDNumber AS CCDNumber,
	|	InventoryAnalytics.Package AS Package
	|INTO DimensionSeries_
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS TransferGoods
	|		INNER JOIN InventoryAnalytics AS InventoryAnalytics
	|		ON TransferGoods.Ref = InventoryAnalytics.Ref
	|		AND
	|			TransferGoods.ItemsLocationAttributesGoodsAtPartners = InventoryAnalytics.ItemsLocationAttributesGoodsAtPartners
	|		AND TransferGoods.Package = InventoryAnalytics.Package
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributesGoodsAtPartners,
	|	CCDNumber,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTable.Ref AS Ref,
	|	InventoryTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	InventoryTable.CCDNumber AS CCDNumber,
	|	InventoryTable.Package AS Package,
	|	InventoryTable.Price AS Price,
	|	SUM(InventoryTable.Count) AS Count
	|INTO TypesOfInventoryOwnersAttributesOfDocuments
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS InventoryTable
	|WHERE
	|	InventoryTable.Ref IN (&References)
	|GROUP BY
	|	InventoryTable.Ref,
	|	InventoryTable.ItemsLocationAttributesGoodsAtPartners,
	|	InventoryTable.CCDNumber,
	|	InventoryTable.Package,
	|	InventoryTable.Price
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryTable.Ref,
	|	InventoryTable.ItemsLocationAttributesGoodsAtPartners,
	|	InventoryTable.CCDNumber,
	|	InventoryTable.Package,
	|	InventoryTable.Price,
	|	SUM(InventoryTable.Count)
	|FROM
	|	Document.TransferOfGoodsToBailee.InventoryKinds AS InventoryTable
	|WHERE
	|	InventoryTable.SalesOrder IN (&References)
	|GROUP BY
	|	InventoryTable.Ref,
	|	InventoryTable.ItemsLocationAttributesGoodsAtPartners,
	|	InventoryTable.CCDNumber,
	|	InventoryTable.Package,
	|	InventoryTable.Price
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributesGoodsAtPartners,
	|	CCDNumber,
	|	Package,
	|	Price
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ItemsLocationAttributesGoodsAtPartners.Products AS Products,
	|	Table.ItemsLocationAttributesGoodsAtPartners.Characteristic AS Characteristic,
	|	Table.ItemsLocationAttributesGoodsAtPartners.Purpose AS Purpose,
	|	CASE
	|		WHEN DimensionSeries_.BatchesIndicationStatus IN (14, 18)
	|			THEN Table.ItemsLocationAttributesGoodsAtPartners.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	InventoryAnalytics.ToRegister AS ToRegister,
	|	Table.Price AS Price,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|	Table.Ref.Warehouse AS Warehouse,
	|	Table.CCDNumber AS CCDNumber
	|INTO Result
	|FROM
	|	TypesOfInventoryOwnersAttributesOfDocuments AS Table
	|		INNER JOIN InventoryAnalytics AS InventoryAnalytics
	|		ON Table.Ref = InventoryAnalytics.Ref
	|		AND Table.ItemsLocationAttributesGoodsAtPartners = InventoryAnalytics.ItemsLocationAttributesGoodsAtPartners
	|		AND Table.CCDNumber = InventoryAnalytics.CCDNumber
	|		AND Table.Package = InventoryAnalytics.Package
	|		LEFT JOIN DimensionSeries_ AS DimensionSeries_
	|		ON Table.Ref = DimensionSeries_.Ref
	|		AND Table.ItemsLocationAttributesGoodsAtPartners = DimensionSeries_.ItemsLocationAttributesGoodsAtPartners
	|		AND Table.CCDNumber = DimensionSeries_.CCDNumber
	|		AND Table.Package = DimensionSeries_.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RECORDAUTONUMBER() AS LineNumber,
	|	Result.Ref AS Ref,
	|	Result.Products AS Products,
	|	Result.Characteristic AS Characteristic,
	|	Result.Purpose AS Purpose,
	|	Result.Series AS Series,
	|	Result.Package AS Package,
	|	Result.Count AS Count,
	|	Result.ToRegister AS ToRegister,
	|	Result.Price AS Price,
	|	Result.VATRate AS VATRate,
	|	Result.Warehouse AS Warehouse,
	|	Result.CCDNumber AS CCDNumber
	|INTO ResultIsNumbered
	|FROM
	|	Result
	|
	|INDEX BY
	|	LineNumber,
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBase.Ref AS Ref,
	|	TableBase.Products AS Products,
	|	TableBase.Characteristic AS Characteristic,
	|	TableBase.Purpose AS Purpose,
	|	TableBase.Series AS Series,
	|	TableBase.Package AS Package,
	|	CASE
	|		WHEN TableBase.ToRegister >= SUM(Distribution_Table.Count)
	|			THEN TableBase.Count
	|		ELSE CASE
	|			WHEN TableBase.Count - (SUM(Distribution_Table.Count) - TableBase.ToRegister) < 0
	|				THEN 0
	|			ELSE TableBase.Count - (SUM(Distribution_Table.Count) - TableBase.ToRegister)
	|		END
	|	END AS Count,
	|	CASE
	|		WHEN TableBase.ToRegister >= SUM(Distribution_Table.Count)
	|			THEN TableBase.Count
	|		ELSE CASE
	|			WHEN TableBase.Count - (SUM(Distribution_Table.Count) - TableBase.ToRegister) < 0
	|				THEN 0
	|			ELSE TableBase.Count - (SUM(Distribution_Table.Count) - TableBase.ToRegister)
	|		END
	|	END AS ToRegister,
	|	TableBase.Price AS Price,
	|	TableBase.VATRate AS VATRate,
	|	TableBase.Warehouse AS Warehouse,
	|	TableBase.CCDNumber AS CCDNumber
	|FROM
	|	ResultIsNumbered AS TableBase
	|		LEFT JOIN ResultIsNumbered AS Distribution_Table
	|		ON TableBase.LineNumber >= Distribution_Table.LineNumber
	|		AND TableBase.Ref = Distribution_Table.Ref
	|		AND TableBase.Products = Distribution_Table.Products
	|		AND TableBase.Characteristic = Distribution_Table.Characteristic
	|		AND TableBase.Purpose = Distribution_Table.Purpose
	|		AND TableBase.Series = Distribution_Table.Series
	|		AND TableBase.Warehouse = Distribution_Table.Warehouse
	|		AND TableBase.CCDNumber = Distribution_Table.CCDNumber
	|GROUP BY
	|	TableBase.LineNumber,
	|	TableBase.Ref,
	|	TableBase.Products,
	|	TableBase.Characteristic,
	|	TableBase.Purpose,
	|	TableBase.Series,
	|	TableBase.Package,
	|	TableBase.Count,
	|	TableBase.ToRegister,
	|	TableBase.Price,
	|	TableBase.VATRate,
	|	TableBase.Warehouse,
	|	TableBase.CCDNumber";
	
	QueryText = StrReplace(QueryText, "&ConnectionVerificationText", ConnectionVerificationText);
	QueryText = StrReplace(QueryText, "&ConnectionMethod", JoinText);
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&Filter", FilterText1);
	
	Return QueryText;
	
EndFunction

Function RequestTextRequirementsForRegistrationForTransfers(TempTableName = "") Export
	
	QueryText = 
	"SELECT ALLOWED
	|	Set.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Set.CCDNumber                   AS CCDNumber,
	|	SUM(Set.Count)          AS ToRegister
	|INTO TableName
	|FROM
	|	(SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CCDNumber                   AS CCDNumber,
	|		Table.CountBalance          AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(, ItemsLocationAttributes IN (&ProductAccountingAnalysts)) AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CCDNumber                   AS CCDNumber,
	|		-Table.Count                AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS Table
	|	WHERE
	|		Table.Active
	|		AND Table.Recorder IN(&Recorder)
	|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ItemsLocationAttributes,
	|	Set.CCDNumber
	|
	|HAVING
	|	SUM(Set.Count) > 0
	|";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO TableName", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	UseTransferToCustodyWithRightOfSale =
		GetFunctionalOption("UseTransferToCustodyWithRightOfSale")
		And AccessRight("Read", Metadata.Documents.SalesOrder);
	
	UseAdvancedFeaturesOfSalesOrder =
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseProductionByThirdParty =
		GetFunctionalOption("UseProductionByThirdParty2_5")
		And AccessRight("Read", Metadata.Documents.SubcontractOrder2_5);
	GeneralAccessRights =
		CommonQueryParameters.IsFullUser
			Or ((AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee)
					Or AccessRight("Update", Metadata.Documents.TransferOfGoodsToBailee))
				And AccessRight("View", Metadata.Documents.TransferOfGoodsToBailee)
				And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences));
	
	If Not UseTransferToCustodyWithRightOfSale
			And Not UseProductionByThirdParty
		Or Not GeneralAccessRights Then
		Return;
	EndIf;
	If UseTransferToCustodyWithRightOfSale Then
		Query = New Query;
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
		Query.SetParameter("UseAdvancedOrderingFeatures", UseAdvancedFeaturesOfSalesOrder);
		
		Query.Text = 
		"SELECT ALLOWED
		|	COUNT(DISTINCT OrdersToBeRegistered.Ref) AS OrdersForRegistrationOfTransfersOfGoodsToCustodianAreInProgress
		|FROM
		|	(SELECT
		|		DataTable.ReferenceOrder AS Ref,
		|		UNDEFINED AS Warehouse,
		|		UNDEFINED AS Products,
		|		UNDEFINED AS Characteristic,
		|		UNDEFINED AS Series
		|	FROM
		|		InformationRegister.ShipmentAndReturnReferencesToFulfill AS DataTable
		|		
		|	WHERE
		|		VALUETYPE(DataTable.ReferenceOrder) IN (&TypesOfOrders)
		|		AND DataTable.DocumentStateToRegister <> VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
		|		AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			WHERE
		|				DocumentsRegistry.Ref = DataTable.ReferenceOrder
		|				AND DocumentsRegistry.BusinessOperation IN(&BusinessTransactions)
		|				AND &UseAdvancedOrderingFeatures
		|				AND DocumentsRegistry.EmployeeResponsible = &User
		|			)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DataTable.DocumentShipments AS Ref,
		|		DataTable.Warehouse            AS Warehouse,
		|		DataTable.Products     AS Products,
		|		DataTable.Characteristic   AS Characteristic,
		|		DataTable.Series            AS Series
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(,
		|			VALUETYPE(DocumentShipments) IN (&TypesOfOrders)
		|			) AS DataTable
		|	WHERE
		|		(DataTable.ToShipBalance - DataTable.AssembledBalance > 0
		|			OR DataTable.ToRegisterBalance > 0)
		|		AND DataTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|		AND DataTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|		AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			WHERE
		|				DocumentsRegistry.Ref = DataTable.DocumentShipments
		|				AND DocumentsRegistry.BusinessOperation IN(&BusinessTransactions)
		|				AND &UseAdvancedFeaturesOfSalesOrder
		|				AND DocumentsRegistry.EmployeeResponsible = &User
		|			)
		|	) AS OrdersToBeRegistered
		|
		|";
		
		SubstituteTextUseAdvancedCustomerOrderFeatures(Query.Text, "DocumentsRegistry", 
				"&UseAdvancedOrderingFeatures", "DataTable", "ReferenceOrder");
		
		EconomicOperationsOfTransfers = New Array;
		EconomicOperationsOfTransfers.Add(Enums.BusinessTransactions.ReturnFromCustodian);
		EconomicOperationsOfTransfers.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
		
		TypesOfOrders = New Array;
		TypesOfOrders.Add(Type("DocumentRef.SalesOrder"));
		TypesOfOrders.Add(Type("DocumentRef.TransferOfGoodsToBailee"));
		
		Query.SetParameter("BusinessTransactions", EconomicOperationsOfTransfers);
		Query.SetParameter("TypesOfOrders",      TypesOfOrders);
		
		Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
		
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id = "DocumentsOfTransferOfGoodsToCustodian";
		UserTaskParent.Presentation = NStr("vi = 'Chứng từ chuyển vào bảo quản';
											|ru = 'Документы передачи товаров хранителю';
											|en = 'Documents of VMI fill-up'; fa = 'Documents of VMI fill-up';
											|it = 'Documenti di consegna merci al depositario';
											|pl = 'Dokumenty przekazują towary do depozytariusza';
											|tr = 'Malların emanetçiye transfer belgeleri'");
		UserTaskParent.Owner      = Metadata.Subsystems.Sales;
		UserTaskParent.HasToDoItems      = Result.OrdersForRegistrationOfTransfersOfGoodsToCustodianAreInProgress > 0;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Warehouse",        Catalogs.Warehouses.EmptyRef());
		FilterParameters.Insert("DateOfShipment", CommonQueryParameters.CurrentDate);
		FilterParameters.Insert("Manager",     CommonQueryParameters.User);
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		FormParameters.Insert("CurrentPageName",      "GroupToRegister");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "OrdersForRegistrationOfTransfersOfGoodsToCustodianAreInProgress";
		ToDoItem.HasToDoItems       = Result.OrdersForRegistrationOfTransfersOfGoodsToCustodianAreInProgress > 0;
		ToDoItem.Presentation  = NStr("vi = 'Lệnh lập chứng từ đang làm việc';
										|ru = 'Распоряжения на оформление в работе';
										|en = 'References for registration in progress'; fa = 'References for registration in progress';
										|it = 'Le disposizioni per la formalizzazione sono in esecuzione';
										|pl = 'Zamówienia rejestracji są w toku wykonywania';
										|tr = 'İş yerinde işleme alınacak siparişler'");
		ToDoItem.Count     = Result.OrdersForRegistrationOfTransfersOfGoodsToCustodianAreInProgress;
		ToDoItem.Important         = False;
		ToDoItem.Form          = "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices";
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "DocumentsOfTransferOfGoodsToCustodian";
	EndIf;
	
	If UseProductionByThirdParty Then
		
		FilterParameters =
			InvoicesServer.OrderSelectionParameters(,,,
				Enums.BusinessTransactions.TransferToToller2_5,
				CommonQueryParameters.User);
		
		QueriesTexts =
			DataProcessors.DocumentsOfTransferToTollingAll2_5.QueriesTexts(
				FilterParameters,
				Enums.BusinessTransactions.TransferToToller2_5);
		
		Query = New Query(QueriesTexts.StatusCalculationQueryText);
		Query.TempTablesManager = New TempTablesManager;
		
		Query.SetParameter("BusinessTransaction",       Enums.BusinessTransactions.TransferToToller2_5);
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
		FilterParameters.Insert("DateOfShipment", CommonQueryParameters.CurrentDate);
		FilterParameters.Insert("Manager",     CommonQueryParameters.User);
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		FormParameters.Insert("CurrentPageName",      "RawMaterialTransferPage");
		FormParameters.Insert("FormAssignmentKey",     "ToDoList");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "TransferToProcessorForProcessing2_5";
		ToDoItem.HasToDoItems       = Result > 0;
		ToDoItem.Presentation  = NStr("vi = 'Chuyển giao cho bên nhận gia công cần lập chứng từ';
										|ru = 'Передачи переработчику к оформлению';
										|en = 'Transfers to subcontractor for registration'; fa = 'Transfers to subcontractor for registration';
										|it = 'Trasferimenti all''elaboratore per formalizzazione';
										|pl = 'Przekazania do przetwórcy do rejestracji';
										|tr = 'İşlem için fason üreticiye transferler'");
		ToDoItem.Count     = Result;
		ToDoItem.Important         = False;
		ToDoItem.Form          = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices";
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "ProductionByThirdParty";
		
	EndIf;
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

#Region UnifiedMethodsForBusinessOperations

#Region FillType

// Returns the text of the request to fill in the document on the basis of the customer's order.
//
// Returns:
//  String -
//
Function TextOfRequestToFillInOrderForm() Export
	
	QueryText =
	"SELECT
	|	SalesOrder.Ref      AS SalesOrder,
	|	SalesOrder.BusinessOperation AS BusinessOperation,
	|	SalesOrder.Status      AS DocumentStatus,
	|	SalesOrder.Partner     AS Partner,
	|	SalesOrder.Counterparty  AS Counterparty,
	|	SalesOrder.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	SalesOrder.Terms  AS Terms,
	|	SalesOrder.Organization AS Organization,
	|	SalesOrder.BankAccount AS CompanyBankAccount,
	|	SalesOrder.Contract     AS Contract,
	|	CASE
	|		WHEN
	|			ISNULL(Warehouses.IsFolder, FALSE)
	|				AND ISNULL(Warehouses.SelectGroup, UNDEFINED) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE SalesOrder.Warehouse
	|	END                    AS Warehouse,
	|	ISNULL(Warehouses.UseWarehouseManagemantSystemForGoodsIssue,
	|			FALSE)            AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN
	|			ISNULL(Warehouses.IsFolder, FALSE)
	|				AND ISNULL(Warehouses.SelectGroup, UNDEFINED) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                    AS ItIsForbiddenToSelectWarehouseGroup,
	|	SalesOrder.Currency      AS Currency,
	|
	|	SalesOrder.Shipper               AS Shipper,
	|	SalesOrder.ShipperBankAccount AS ShipperBankAccount,
	|	SalesOrder.GoodsRecipient                AS GoodsRecipient,
	|	SalesOrder.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
	|
	|	SalesOrder.DateOfShipment       AS DateOfShipment,
	|	SalesOrder.NotShipInInstallments AS NotShipInInstallments,
	|
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.DeliveryMethod
	|	END                                   AS DeliveryMethod,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.CarrierPartner
	|	END                                   AS CarrierPartner,
	|	SalesOrder.DeliveryAddress              AS DeliveryAddress,
	|	SalesOrder.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.DeliveryZone
	|	END                                   AS DeliveryZone,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.DeliveryTimeFrom
	|	END                                   AS DeliveryTimeFrom,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.DeliveryTimeTo
	|	END                                   AS DeliveryTimeTo,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.AdditionalDeliveryInformation
	|	END                                   AS AdditionalDeliveryInformation,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.SpecialTransportationConditions
	|	END                                   AS SpecialTransportationConditions,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|				OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|			THEN SalesOrder.SpecialTransportationConditionsDescription
	|	END                                   AS SpecialTransportationConditionsDescription,
	|
	|	SalesOrder.SalesOpportunity                  AS SalesOpportunity,
	|	SalesOrder.Department           AS Department,
	|	SalesOrder.ContactPerson          AS ContactPerson,
	|	SalesOrder.LineOfBusiness AS LineOfBusiness,
	|
	|	SalesOrder.ToReturnReusablePackage      AS ToReturnReusablePackage,
	|	SalesOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
	|	CASE
	|		WHEN &ToUseTermsOfSales
	|			THEN ISNULL(Terms1.ScheduleOfPackageReturn, VALUE(Catalog.BusinessCalendars.EmptyRef))
	|		ELSE VALUE(Catalog.BusinessCalendars.EmptyRef)
	|	END                                       AS ScheduleOfPackageReturn,
	|	CASE
	|		WHEN &ToUseTermsOfSales 
	|			THEN ISNULL(Terms1.CalculatePackageReturnDateAccordingToCalendar, FALSE)
	|		ELSE FALSE
	|	END                                       AS CalculatePackageReturnDateAccordingToCalendar,
	|
	|	SalesOrder.ThisIsOrderAsInvoice                AS ThisIsOrderAsInvoice,
	|
	|	NOT SalesOrder.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON SalesOrder.Warehouse = Warehouses.Ref
	|	
	|		LEFT JOIN Catalog.TermsOfSale AS Terms1
	|		ON SalesOrder.Terms = Terms1.Ref
	|WHERE
	|	SalesOrder.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT DISTINCT
	|	ShippingOrdersShipped.Warehouse AS Warehouse
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersShipped
	|	LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON ShippingOrdersShipped.Warehouse = Warehouses.Ref
	|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
	|		ON TRUE
	|WHERE
	|	ShippingOrdersShipped.QuantityToBeShippedTurnover
	|		- ShippingOrdersShipped.ShippedQuantityTurnover > 0
	|	AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|		OR Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|			AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CheckDate
	|		OR TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForIssueBalanceAndTurnovers.Warehouse AS Warehouse
	|FROM
	|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|			,
	|			,
	|			,
	|			,
	|			DocumentShipments = &DocumentBasis
	|				AND CAST(Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
	|				AND CAST(Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue < &CheckDate
	|		) AS GoodsForIssueBalanceAndTurnovers
	|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
	|		ON TRUE
	|WHERE
	|	GoodsForIssueBalanceAndTurnovers.ToShipExpense - GoodsForIssueBalanceAndTurnovers.ToRegisterExpense > 0
	|	AND TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst)
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText = "
		|	ReferenceOrder = &DocumentBasis
		|";
	TableFormationParameters.Group = "Warehouse";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Posting

// Returns parameters for filling in inventory types for the document "Transfer of goods to the custodian".
// 
// Parameters:
// 	Object - DocumentObject.TransferOfGoodsToBailee
// Returns:
// 	See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	
	AvailableStockTypes = New Array;
	AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
	AvailableStockTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	
	SelectionOfStockTypes_.InventoryType = AvailableStockTypes;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region Rounding

// Fills in the Shopbill and need to Round attributes in the table rows
// 
// Parameters:
//  Object - FormDataStructure - 
//  Rows - Array, Undefined - array of processed strings
//  
Procedure FillInShopPantryAttributeInTable(Object, Rows = Undefined) Export
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.Goods,,, Rows);
	
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

// Adds the actions "Fill in the sign of the account" and "Recalculate the number of units"
//
// Parameters:
//  StructureOfActions - Structure - 
//
Procedure AddFillInActionForShopPantryAttribute(StructureOfActions) Export
	
	StructureOfActions.Insert("FillInShopPantryAttribute");
	
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
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding() Export
	
	Return New Structure("Goods");
	
EndFunction

#EndRegion

#Region QueriesTexts

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
		"TableOfOrders.BusinessOperation",
		"VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)",
		"=");
	
	TMCommonUse.AddSelectionItemToCollection(
		RequestTextParameters.Filter,
		"CASE
		|	WHEN TableOfOrders.Warehouse = &Warehouse
		|		OR TableOfOrders.Warehouse IN HIERARCHY (&Warehouse)
		|		OR TableOfOrders.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		THEN TRUE
		|	ELSE FALSE
		|END",
		"TRUE",
		"=");
	
	Return Documents.SalesOrder.RequestTextForOrdersInvoices(RequestTextParameters);
	
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
	
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		"ReferenceOrder",
		"SELECT
		|	WaybillOrders.ReferenceOrder
		|FROM
		|	WaybillOrders AS WaybillOrders");
	
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		"CASE
		|	WHEN Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		THEN TRUE
		|	ELSE FALSE
		|END",
		"TRUE",
		"=");
	
	QueryText =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextBalance(
			TempTableName,
			FilterByDimensions,
			"ToRegister > 0");
	
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
	|	GoodsForRegistration.Warehouse
	|";
	
EndFunction

#EndRegion

// Edits the text of the conversion request to the document currency
//
// Parameters:
//  QueryText - String - the editable text of the request.
//
Procedure EditTextOfRequestForConversionToDocumentCurrency(QueryText) Export
	
	Return;
	
EndProcedure

// Edits the text of the request for order balances
//
// Parameters:
//  QueryText - String - the editable text of the request.
//
Procedure EditRequestTextForOrderBalances(QueryText) Export
	
	//Customer Order Table
	QueryText = StrReplace(QueryText, "&CustomerOrderAgreement",                "SalesOrder.Terms");
	QueryText = StrReplace(QueryText, "&CustomerSOrderToReturnMultiTurnContainer", "SalesOrder.ToReturnReusablePackage");
	QueryText = StrReplace(QueryText, "&CustomerOrderSenderAssignment",     "OrderingProducts.Ref.Purpose");
	QueryText = StrReplace(QueryText, "&CustomerOrderAssignmentStage",            "VALUE(Catalog.Assignments.EmptyRef)");
	QueryText =
		StrReplace(
			QueryText,
			"&CustomerOrderAssignment",
			"CASE
			|	WHEN OrderingProducts.WithAssignment
			|		THEN OrderingProducts.Ref.Purpose
			|	ELSE VALUE(Catalog.Assignments.EmptyRef)
			|END");
	
	//Product Order table
	QueryText = StrReplace(QueryText, "&OrderGoodsAmountWithVAT", "GoodsFromOrder.AmountIncludingVAT");
	
	//The Order Items table
	QueryText = StrReplace(QueryText, "&OrderProductsSetProducts",   "OrderingProducts.ProductsInSet");
	QueryText = StrReplace(QueryText, "&OrderGoodsSetCharacteristics", "OrderingProducts.ItemVariantOfSet");
	
	QueryText = StrReplace(QueryText, "&OrderProductsTypeOfPrice",              "OrderingProducts.PriceKind");
	QueryText = StrReplace(QueryText, "&TableBalancesAmount",             "TableBalance.Sum");
	
EndProcedure

#EndRegion

#Region DocumentOrderDocument

// Returns the access right of the customer's order.
//
// Parameters:
//  NameRight - String - the name of the right being checked.
//
// Returns:
//  Boolean - 
//
Function OrderAccessRights(NameRight) Export
	
	Return AccessRight(NameRight, Metadata.Documents.SalesOrder);
	
EndFunction

// Returns the manager of the customer's order document
//
// Returns:
//  DocumentManager.SalesOrder - 
//
Function OrderManager() Export
	
	Return Documents.SalesOrder;
	
EndFunction

// Returns the type description for the customer's order
// 
// Returns:
//  TypeDescription - 
//
Function OrderTypeDescription() Export
	
	Return New TypeDescription("DocumentRef.SalesOrder");
	
EndFunction

// Returns the type for the customer's order
// 
// Returns:
//  Type - 
//
Function OrderType_5() Export
	
	Return Type("DocumentRef.SalesOrder");
	
EndFunction

// Returns the synonym of the order.
//
// Returns:
//  String - synonym of the order.
//
Function SynonymForOrder() Export
	
	Return NStr("vi = 'Đơn hàng của khách';
				|ru = 'Заказ клиента';
				|en = 'Sales order'; fa = 'سفارش فروش';
				|it = 'Ordine del cliente';
				|pl = 'Zamówienie klienta';
				|tr = 'Satış siparişi'");
	
EndFunction

#EndRegion

#Region DiscrepancyCertificate

// Returns the type of the basis of the act of discrepancy
//
// Returns:
//  EnumRef.TypesOfBaseDocumentsForDiscrepancyReport
//
Function TypeOfBasisOfAct() Export
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee;
	
EndFunction

// Returns a sign of the registration of the return document through the document of the act of discrepancy
//
// Returns:
//  Boolean - 
//
Function IssueRefundOfAct() Export
	
	Return True;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi chuyển giao hàng hóa cho người trông coi';
				|ru = 'после передачи товаров хранителю';
				|en = 'after VMI fill-up'; fa = 'after VMI fill-up';
				|it = 'dopo la consegna delle merci al depositario';
				|pl = 'po przekazaniu towarów do depozytariusza';
				|tr = 'malların emanetçiye transferinden sonra'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa cho bên cho thuê kho (tạo mới)';
				|ru = 'Акт о расхождениях после передачи товаров хранителю (создание)';
				|en = 'Discrepancy report following the VMI fill-up (create)'; fa = 'Discrepancy report following the VMI fill-up (create)';
				|it = 'Акт о расхождениях после передачи товаров хранителю (создание)';
				|pl = 'Discrepancy report following the VMI fill-up (create)';
				|tr = 'Malların emanetçiye transferinden sonra tutarsızlık raporu (oluştur)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa cho bên cho thuê kho';
				|ru = 'Акт о расхождениях после передачи товаров хранителю';
				|en = 'Discrepancy report following the VMI fill-up'; fa = 'Discrepancy report following the VMI fill-up';
				|it = 'Акт о расхождениях после передачи товаров хранителю';
				|pl = 'Discrepancy report following the VMI fill-up';
				|tr = 'Malların emanetçiye transferinden sonra tutarsızlık raporu'");
	
EndFunction

// Returns the title of the partner of the discrepancy report
//
// Returns:
//  String - 
//
Function HeaderOfActPartner() Export
	
	Return NStr("vi = 'Bạn hàng';
				|ru = 'Партнер';
				|en = 'Partner'; fa = 'شریک تجاری';
				|it = 'Partner';
				|pl = 'Partner';
				|tr = 'İş ortağı'");
	
EndFunction

// Returns the title of the document of the basis of the act of discrepancy
//
// Returns:
//  String - 
//
Function TitleOfDocumentGroundsOfAct() Export
	
	Return NStr("vi = 'Chuyển giao hàng hóa cho người bảo quản';
				|ru = 'Передача хранителю';
				|en = 'Transfer to the custodian'; fa = 'Transfer to the custodian';
				|it = 'Consegna al depositario';
				|pl = 'Przeniesienie do depozytariusza';
				|tr = 'Emanetçiye transfer'");
	
EndFunction

// Returns the hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ReportAgreementHint() Export
	
	Return NStr("vi = 'Hợp đồng mà có lập chứng từ chuyển giao';
				|ru = 'Договор, в рамках которого оформлена передача';
				|en = 'Contract under which transfer is registered'; fa = 'Contract under which transfer is registered';
				|it = 'Contratto in base al quale è stata effettuata la consegna';
				|pl = 'Umowa, na mocy której wykonywany jest transfer';
				|tr = 'Sevk işleminin gerçekleştirildiği sözleşme'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

// Returns an array of business operations orders.
//
// Returns:
//  Array of EnumRef.BusinessTransactions -
//
Function EconomicOperationsOfOrders() Export
	
	OperationArray = New Array;
	OperationArray.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	OperationArray.Add(Enums.BusinessTransactions.ReturnFromCustodian);
	
	Return OperationArray;
	
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

// Returns the attribute using the advanced features of the customer's order
//
// Returns:
//  Boolean -
//
Function UseAdvancedFeaturesOfSalesOrder() Export
	
	Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
EndFunction

// Returns the attribute using customer orders
//
// Returns:
//  Boolean -
//
Function UseSalesOrders() Export

	UseSalesOrders = GetFunctionalOption("UseSalesOrders")
								 Or GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");

	Return UseSalesOrders;

EndFunction

// Returns the attribute of using the implementation for multiple orders.
//
// Returns:
//  Boolean -
//
Function UseSaleByMultipleOrders() Export

	Return GetFunctionalOption("UseSaleByMultipleOrders");

EndFunction

// Returns a sign of implementation in excess of the order.
// 
// Returns:
// 	Boolean
//
Function SalesInExcessOfOrder() Export
	
	Return UserRightsCached.SalesInExcessOfOrder();
	
EndFunction

// Returns a sign of deviation from the terms of sale.
// 
// Returns:
// 	Boolean
//
Function VarianceFromSalesTermsAndConditions() Export
	
	Return UserRightsCached.VarianceFromSalesTermsAndConditions();
	
EndFunction

#EndRegion

#Region FunctionalOptionsInQueryTexts

// Changes the text of the use of advanced features of the customer order parameter in the request text.
// Must work synchronously with the unified method to use the expanded capabilities of the customer.
//
// Parameters:
//  QueryText     - String - query text.
//  TableName       - String - the name of the table in the request.
//  Parameter         - String - a parameter in the request.
//  NameOfProductsTable - String - name of the product table in the request.
//
Procedure SubstituteTextUseAdvancedCustomerOrderFeatures(
		QueryText, TableName, Parameter = "&UseAdvancedFeaturesOfSalesOrder", NameOfProductsTable = "", NameOfAttributeOfSalesOrder = "SalesOrder") Export
	DocumentBusinessTransaction = Enums.BusinessTransactions.TransferToToller2_5;
	ContractBusinessTransaction  = ProcessingByThirdParties.ContractBusinessTransaction();
	
	NameOfDocumentOperation = Common.EnumerationValueName(DocumentBusinessTransaction);
	NameOfAgreementOperation  = Common.EnumerationValueName(ContractBusinessTransaction);
		
	NewText = "(%1.BusinessOperation IN (
				  |					VALUE(Enum.BusinessTransactions.%2),
				  |					VALUE(Enum.BusinessTransactions.%3))
				  |OR %4)";
				  
	NewText = StrTemplate(NewText, TableName, NameOfDocumentOperation, NameOfAgreementOperation, Parameter);
	
	QueryText = StrReplace(QueryText, Parameter, NewText);
	If Not NameOfProductsTable = "" Then
		NewText = "NOT ISNULL(%1.%2.ThisIsOrderAsInvoice, NOT %3)"; //@Query-part
		NewText = StrTemplate(NewText, NameOfProductsTable, NameOfAttributeOfSalesOrder, Parameter);
		QueryText = StrReplace(QueryText, Parameter, NewText);
	EndIf;
	
	Return;
	
EndProcedure

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//    Object                         - FormDataStructure, DocumentObject.TransferOfGoodsToBailee - The object from which the main parameters for the search will be taken.
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
	   And GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
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

	Items.Partner.Title            = NStr("vi = 'Khách hàng';
											|ru = 'Клиент';
											|en = 'Customer'; fa = 'مشتری';
											|it = 'Cliente';
											|pl = 'Customer';
											|tr = 'Müşteri'");
	Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказ клиента';
										|en = 'Sales order'; fa = 'سفارش فروش';
										|it = 'Ordine del cliente';
										|pl = 'Zamówienie klienta';
										|tr = 'Satış siparişi'");
	
	RightToChangeOrders = OrderAccessRights("Update");
	Items.CloseOrder.Enabled  = RightToChangeOrders;
	Items.CloseOrders_2.Enabled = RightToChangeOrders;
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.GoodsFillThePricesByTermsOfSales.Visible = Items.Terms.Visible;
	Items.GoodsFillInPricesUnderAgreement.Visible   = False;
	
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
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.BusinessOperation", Object.BusinessOperation));
	
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
	If Not Items.Find("LineOfBusiness") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
	// Type of price
	If Not Items.Find("GoodsPriceKind") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.OutputAnyTypeOfPrice", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
		
		Items.GoodsPriceKind.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
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

// Returns the presentation of the document transfer of goods to the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Chuyển giao hàng hóa cho người bảo quản';
				|ru = 'Передача товаров хранителю';
				|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
				|it = 'Consegna di merci al depositario';
				|pl = 'Przekazanie towaru do magazyniera';
				|tr = 'Malların emanetçiye transferi'");
	
EndFunction

// Binds the rows of the Products table to customer orders.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Object - FormDataStructure - Contains:
//  		  * Ref - DocumentRef.TransferOfGoodsToBailee - 
//  SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters
//  SelectByOrder_ - Boolean - 
//
Procedure LinkTransferLinesToOrders(Form, Object, SeriesSpecificationParameters, SelectByOrder_) Export
	
	If Not Form.UseSalesOrders
		Or (Not Form.UseTransferForSeveralOrders
			And Not ValueIsFilled(Object.SalesOrder)) Then
		Return;
	EndIf;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Object.BusinessOperation);
	
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
			"&SalesOrder",
			"=");
	EndIf;
	
	QueryTexts.Add(Handler.QueryTextWaybillOrders(RequestTextParameters));
	
	QueryTexts.Add(QueryTextRemnantsOfGoodsForRegistration("GoodsForRegistration"));
	QueryTexts.Add(QueryTextDuplicatesOfProductsForRegistration());
	
	QueryText =
	"SELECT
	|	GoodsForRegistration.ReferenceOrder       AS SalesOrder,
	|	GoodsForRegistration.RowCode          AS RowCode,
	|	GoodsForRegistration.Products       AS Products,
	|	GoodsForRegistration.Characteristic     AS Characteristic,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			AND CustomerOrderGoods.WithAssignment
	|			THEN CustomerOrderGoods.Ref.Purpose
	|		WHEN SubcontractOrder.Ref IS NOT NULL
	|			AND OrderingGoodsToProcessor.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|			THEN OrderingGoodsToProcessor.Purpose
	|		WHEN StageGoods.Ref IS NOT NULL
	|			AND StageGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|			THEN StageGoods.Purpose
	|		WHEN StageGoods.Ref IS NOT NULL
	|			AND CAST(StageGoods.Ref.SubcontractOrder AS Document.SubcontractOrder2_5).TransferToSubcontractorForOrderPurpose
	|			THEN CAST(StageGoods.Ref.SubcontractOrder AS Document.SubcontractOrder2_5).TransferPurpose
	|		WHEN SubcontractOrder.Ref IS NOT NULL
	|			AND SubcontractOrder.TransferToSubcontractorForOrderPurpose
	|			THEN SubcontractOrder.TransferPurpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                AS Purpose,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			AND CustomerOrderGoods.WithAssignment
	|			THEN CustomerOrderGoods.Ref.Purpose
	|		WHEN OrderingGoodsToProcessor.Ref IS NOT NULL
	|			AND OrderingGoodsToProcessor.WithAssignment
	|			THEN OrderingGoodsToProcessor.Purpose
	|		WHEN StageGoods.Ref IS NOT NULL
	|			AND StageGoods.WithAssignment
	|			THEN StageGoods.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                AS AssignmentSender,
	|	GoodsForRegistration.Series              AS Series,
	|	GoodsForRegistration.ToRegister        AS ToRegister,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN CustomerOrderGoods.PriceKind
	|		WHEN SubcontractOrder.Ref IS NOT NULL
	|			THEN SubcontractOrder.PriceKind
	|	END                                AS PriceKind,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN CustomerOrderGoods.Price
	|		WHEN OrderingGoodsToProcessor.Ref IS NOT NULL
	|			THEN OrderingGoodsToProcessor.Price
	|	END                                AS Price,
	|	GoodsForRegistration.Warehouse              AS Warehouse,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN CustomerOrderGoods.DeliveryPeriodDays
	|		WHEN OrderingGoodsToProcessor.Ref IS NOT NULL
	|			THEN OrderingGoodsToProcessor.DeliveryPeriodDays
	|	END                                AS DeliveryPeriodDays,
	|	0                                    AS Allocated,
	|	DuplicatesOfProducts.DuplicateCount        AS DuplicateCount
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|	
	|	LEFT JOIN DuplicatesOfProductsForRegistration AS DuplicatesOfProducts
	|	ON GoodsForRegistration.Products = DuplicatesOfProducts.Products
	|	AND GoodsForRegistration.Characteristic = DuplicatesOfProducts.Characteristic
	|	AND GoodsForRegistration.Warehouse = DuplicatesOfProducts.Warehouse
	|	AND GoodsForRegistration.Series = DuplicatesOfProducts.Series
	|	
	|	LEFT JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
	|	ON CustomerOrderGoods.Ref = GoodsForRegistration.ReferenceOrder
	|	AND CustomerOrderGoods.RowCode = GoodsForRegistration.RowCode
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5 AS SubcontractOrder
	|	ON SubcontractOrder.Ref = GoodsForRegistration.ReferenceOrder
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS OrderingGoodsToProcessor
	|	ON OrderingGoodsToProcessor.Ref = GoodsForRegistration.ReferenceOrder
	|	AND OrderingGoodsToProcessor.RowCode = GoodsForRegistration.RowCode
	|	
	|	LEFT JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS StageGoods
	|	ON StageGoods.Ref.SubcontractOrder = GoodsForRegistration.ReferenceOrder
	|	AND StageGoods.RowCode = GoodsForRegistration.RowCode
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
	|		WHEN SubcontractOrder.Ref IS NOT NULL
	|			AND OrderingGoodsToProcessor.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|			THEN OrderingGoodsToProcessor.Purpose
	|		WHEN StageGoods.Ref IS NOT NULL
	|			AND StageGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|			THEN StageGoods.Purpose
	|		WHEN StageGoods.Ref IS NOT NULL
	|			AND CAST(StageGoods.Ref.SubcontractOrder AS Document.SubcontractOrder2_5).TransferToSubcontractorForOrderPurpose
	|			THEN CAST(StageGoods.Ref.SubcontractOrder AS Document.SubcontractOrder2_5).TransferPurpose
	|		WHEN SubcontractOrder.Ref IS NOT NULL
	|			AND SubcontractOrder.TransferToSubcontractorForOrderPurpose
	|			THEN SubcontractOrder.TransferPurpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	CASE
	|		WHEN CustomerOrderGoods.Ref IS NOT NULL
	|			THEN CustomerOrderGoods.DateOfShipment
	|		WHEN OrderingGoodsToProcessor.Ref IS NOT NULL
	|			THEN OrderingGoodsToProcessor.DateOfShipment
	|		WHEN StageGoods.Ref IS NOT NULL
	|			THEN StageGoods.DateOfShipment
	|	END,
	|	GoodsForRegistration.ReferenceOrder,
	|	GoodsForRegistration.RowCode
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
	Query.SetParameter("SalesOrder",                        Object.SalesOrder);
	Query.SetParameter("Partner",                             Object.Partner);
	Query.SetParameter("Counterparty",                          Object.Counterparty);
	Query.SetParameter("Terms",                          Object.Terms);
	Query.SetParameter("Organization",                         Object.Organization);
	Query.SetParameter("Contract",                             Object.Contract);
	Query.SetParameter("Warehouse",                               Object.Warehouse);
	Query.SetParameter("Currency",                              Object.Currency);
	Query.SetParameter("SalesOpportunity",                              Object.SalesOpportunity);
	Query.SetParameter("LineOfBusiness",             Object.LineOfBusiness);
	Query.SetParameter("ToReturnReusablePackage",           Object.ToReturnReusablePackage);
	Query.SetParameter("Goods",                              TableOfGoods);
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	If QueryResult[2].IsEmpty() Then
		Return;
	EndIf;
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("SalesOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	TableOfUnallocatedGoods.Columns.Add("AssignmentSender");
	TableOfUnallocatedGoods.Columns.Add("Series");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("PriceKind");
	TableOfUnallocatedGoods.Columns.Add("Price");
	TableOfUnallocatedGoods.Columns.Add("Warehouse");
	TableOfUnallocatedGoods.Columns.Add("DeliveryPeriodDays");
	
	Selection = QueryResult[4].Select();
	
	NamesOfPropertiesToFillIn = "SalesOrder, RowCode, Purpose, AssignmentSender, DeliveryPeriodDays";
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("RowCode",      0);
		TheStructureOfTheSearch.Insert("Products",   Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Series",          Selection.Series);
		If ValueIsFilled(Form.PriceTypeAccountingPriceType) Then
			TheStructureOfTheSearch.Insert("PriceKind",    Selection.PriceKind);
		EndIf;
		TheStructureOfTheSearch.Insert("Price",           Selection.Price);
		TheStructureOfTheSearch.Insert("Warehouse",          Selection.Warehouse);
		
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
		Else
			
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
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert(
			"FillInDuplicateDependentDetails", New Structure("WithoutReusablePackages", "Sum"));

		RowsToProcess = New Array();

		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("SalesOrder",   Undefined);
			TheStructureOfTheSearch.Insert("RowCode",      0);
			TheStructureOfTheSearch.Insert("Products",   UnallocatedRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic", UnallocatedRow.Characteristic);
			TheStructureOfTheSearch.Insert("Series",          UnallocatedRow.Series);
			If ValueIsFilled(Form.PriceTypeAccountingPriceType) Then
				TheStructureOfTheSearch.Insert("PriceKind",    UnallocatedRow.PriceKind);
			EndIf;
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

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			Undefined);

	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

// Returns an indication that the warehouse is a group and groups can be used in sales documents.
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses
// 
// Returns:
//  Boolean - This is a group of warehouses
//
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse) Export
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction

#EndRegion

#EndRegion

#Region GeneralMethodsForBusinessOperations

#Region ActionHandlers

// Gets an action handler depending on the business operation
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions, Undefined - 
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function ActionHandler(BusinessOperation = Undefined) Export
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		Handler = TransferToCommissionAgent;
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5 Then
		Handler = TransferToToller;
	Else
		Handler = Documents.TransferOfGoodsToBailee;
	EndIf;
	
	Return Handler;
	
EndFunction

// Gets an action handler depending on the order type
//
// Parameters:
//  OrderType_5 - Type -
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function HandlerForActionsByOrderType(OrderType_5) Export
	If OrderType_5 = TransferToToller.OrderType_5() Then
		BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5;
	Else
		BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	EndIf;
	Return ActionHandler(BusinessOperation);
	
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
	
	If BasisType = TransferToCommissionAgent.TypeOfBasisOfAct() Then
		BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
	ElsIf BasisType = TransferToToller.TypeOfBasisOfAct() Then
		BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5;
	Else
		BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
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
	
	AvailableBusinessTransactionsOfDocument = TMCommonUse.AvailableBusinessTransactions("Document.TransferOfGoodsToBailee");
	
	Items = Form.Items;
	Items.BusinessOperation.ChoiceList.Clear();
	Items.BusinessOperation.ChoiceList.LoadValues(GetAvailableOperationsForDocument());
	Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
		And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	ElsIf AvailableBusinessTransactionsOfDocument <> Undefined
		And ValueIsFilled(Object.BusinessOperation)
		And AvailableBusinessTransactionsOfDocument.Find(Object.BusinessOperation) = Undefined
		And Items.BusinessOperation.ChoiceList.Count() > 0 Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

// Gets the available CS for the user for the Cur document, taking into account the FO.
//
// Returns:
//  Array - spsok available HO
//
Function GetAvailableOperationsForDocument() Export
	
	AvailableBusinessTransactionsOfDocument = TMCommonUse.AvailableBusinessTransactions("Document.TransferOfGoodsToBailee");
	ListOfAvailableOperations = New Array();
	
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale")
		And (AvailableBusinessTransactionsOfDocument = Undefined
			Or AvailableBusinessTransactionsOfDocument.Find(Enums.BusinessTransactions.TransferToStorageWithRightOfSale) <> Undefined) Then
		ListOfAvailableOperations.Add(
			Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission")
		And (AvailableBusinessTransactionsOfDocument = Undefined
			Or AvailableBusinessTransactionsOfDocument.Find(Enums.BusinessTransactions.TransferToCommissionAgent) <> Undefined) Then
		ListOfAvailableOperations.Add(
			Enums.BusinessTransactions.TransferToCommissionAgent);
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5")
		And (AvailableBusinessTransactionsOfDocument = Undefined
			Or AvailableBusinessTransactionsOfDocument.Find(Enums.BusinessTransactions.TransferToToller2_5) <> Undefined) Then
		ListOfAvailableOperations.Add(
			Enums.BusinessTransactions.TransferToToller2_5);
	EndIf;
	Return ListOfAvailableOperations;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
#EndIf
