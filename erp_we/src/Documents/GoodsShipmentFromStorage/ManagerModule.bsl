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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentCorrection");
	
	GoodsShipmentFromStorageLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsShipmentFromStorage") Then
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
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		
		GoodsShipmentFromStorageLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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

// Adds the command to create the document "shipment of goods from storage".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsShipmentFromStorage.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
			Metadata.Documents.GoodsShipmentFromStorage);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command to create the document "shipment of goods from storage".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnWarehouseGroupCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsShipmentFromStorage.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehouses";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsShipmentFromStorage);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command "Transfer to the giver" to create the document "Shipment of goods from storage".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined, ValueTableRow - command description.
//
Function AddCommandShipmentOfGoodsFromStorageTransferToGiverCreateBasedOnOrder(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		HandlerName = "GenerationByReferenceTMClient.ShipmentOfGoodsFromStorageTransferToGiverCreateOnBasisOfOrder";
		Presentation  = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = "ShipmentOfGoodsFromStorageTransferToGiver";
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Presentation       = Presentation;
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTollManufacturing2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the "Return to giver" command to create the "Shipment of goods from storage" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined, ValueTableRow - command description.
//
Function AddCommandShipmentOfGoodsFromStorageRefundGiverCreateBasedOnOrder(
			GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		HandlerName = "GenerationByReferenceTMClient.ShipmentOfGoodsFromStorageRefundGiverCreateOnBasisOfOrder";
		Presentation  = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = "ShipmentOfGoodsFromStorageReturnToGiver";
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Presentation       = Presentation;
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTollManufacturing2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command "Return of the repaired Finished product" to create the document "Shipment of goods from storage".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined, ValueTableRow - command description.
//
Function AddCommandShipmentOfGoodsFromStorageReturnOfRepairedFINISHEDProductBasedOnOrder(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		HandlerName = "GenerationByReferenceTMClient.ShipmentOfGoodsFromStorageReturnOfRepairedFINISHEDProductBasedOnOrder";
		Presentation  = NStr("vi = 'Trả lại sản phẩm đang được sửa chữa';
							|ru = 'Возврат ремонтируемого изделия';
							|en = 'Return of product under R&M'; fa = 'Return of product under R&M';
							|it = 'Return of product under R&M';
							|pl = 'Return of product under R&M';
							|tr = 'Bakım onarım yapılan ürün iadesi'");;
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id       = "ShipmentOfGoodsFromStorageReturnOfRepairedFINISHEDProduct";
		CreateBasedOnCommand.Handler          = HandlerName;
		CreateBasedOnCommand.Presentation       = Presentation;
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.MultipleChoice  = False;
		CreateBasedOnCommand.FunctionalOptions = "UseTollManufacturing2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		CreationCommand = Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(
							GenerationCommands);
		
		If CreationCommand <> Undefined Then
			GivingOperations  = New ValueList;
			GivingOperations.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
			GivingOperations.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand,
				"BusinessOperation",
				GivingOperations,
				DataCompositionComparisonType.NotInList);
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng từ kho';
												|ru = 'Акт о расхождениях после отгрузки с хранения';
												|en = 'VMI pick-up discrepancy report'; fa = 'VMI pick-up discrepancy report';
												|it = 'Atti sulle discrepanze dopo la spedizione dal luogo di stoccaggio';
												|pl = 'Protokół o odchyleniu po wysyłce towarów z przechowywania';
												|tr = 'Depodan sevkiyat sonrası tutarsızlık raporu'");
		EndIf;
	EndIf;
	If GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterShipmentForShipmentsOfGoodsToGiver2_5") Then
		
		CreationCommand =
			Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
			
		If CreationCommand <> Undefined Then
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand,
				"BusinessOperation",
				Enums.BusinessTransactions.TransferToMaterialProvider2_5,
				DataCompositionComparisonType.Equal);
				
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi giao sản phẩm của bên đặt gia công';
												|ru = 'Акт о расхождениях после отгрузки продукции давальца';
												|en = 'Discrepancy report following shipment of manufactured products from the provider'; fa = 'Discrepancy report following shipment of manufactured products from the provider';
												|it = 'Atto di accettazione con riserva dopo la spedizione dei prodotti del fornitore';
												|pl = 'Protokół o odchyleniu po wysyłce produkcji właściciela surowców';
												|tr = 'Sağlayıcı ürünlerinin sevkiyatından sonra tutarsızlık raporu.'");
			
		EndIf;
		
		CreationCommand =
			Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
			
		If CreationCommand <> Undefined Then
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand,
				"BusinessOperation",
				Enums.BusinessTransactions.ReturnToMaterialProvider2_5,
				DataCompositionComparisonType.Equal);
				
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi giao nguyên vật liệu của bên đặt gia công';
												|ru = 'Акт о расхождениях после отгрузки сырья давальца';
												|en = 'Discrepancy report following shipment of raw materials from the provider'; fa = 'Discrepancy report following shipment of raw materials from the provider';
												|it = 'Atto di accettazione con riserva dopo la spedizione di materie prime del fornitore';
												|pl = 'Protokół o odchyleniu po wysyłce surowców właściciela surowców';
												|tr = 'Sağlayıcı hammaddelerinin sevkiyatından sonra tutarsızlık raporu'");
			
		EndIf;
		
	EndIf;
	
	CreationCommand = Documents.ReportToMaterialProvider2_5.AddGenerateCommand(GenerationCommands);
	
	If CreationCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToMaterialProvider2_5,
			DataCompositionComparisonType.Equal);

	EndIf;
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	GoodsShipmentFromStorageLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	Documents.ReceiptOfGoodsFromCustodian.AddCommandToCreateBasedOnTransferToGiver(GenerationCommands);
	Documents.ReceiptOfGoodsFromCustodian.AddCommandToCreateBasedOnReturnToGiver(GenerationCommands);
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
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	GoodsShipmentFromStorageLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Date";
	
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
	SeriesSpecificationParameters.Date                 = Object.Date;
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(
		SeriesSpecificationParameters);
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_SalesOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");

	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef, Undefined - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	If FieldValuesToIdentifyReferences.Goods_RowCode <> 0 Then 
		Return FieldValuesToIdentifyReferences.Goods_SalesOrder;
	Else
		Return Undefined;
	EndIf;
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - the composition of fields is set in the function
//		Nomenclaturales.Parametrizatsii.
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
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Count          AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products                                                       AS Products,
	|	Goods.Characteristic                                                     AS Characteristic,
	|	Goods.Purpose                                                         AS Purpose,
	|	Goods.Series                                                              AS Series,
	|	Goods.Warehouse                                                              AS Warehouse,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count)                                                  AS Count
	|
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Count     AS Count
	|
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products      AS Products,
	|	SetOfSeries.Characteristic    AS Characteristic,
	|	SetOfSeries.Purpose        AS Purpose,
	|	SetOfSeries.Warehouse             AS Warehouse,
	|	SUM(SetOfSeries.Count) AS Count
	|
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
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
	|				AND &FactOfSelection
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByReturnToVendor
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
	|	END                      AS BatchesIndicationStatus
	|
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products      = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose     = SeriesToRequest.Purpose
	|				AND ProductsToRequest.Warehouse          = SeriesToRequest.Warehouse
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON (Warehouses.Ref = BatchAccountingPolicies.Warehouse)
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products      = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose     = ProductsToRequest.Purpose
	|			AND Goods.Warehouse          = ProductsToRequest.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
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

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	TemplateForAssigningAgencyPurchases = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	TemplateForAssigningAgencyPurchases.LineOfBusiness  = "Object.LineOfBusiness";
	TemplateForAssigningAgencyPurchases.RecordsInWarehouseRegisters = "TRUE";
	TemplateForAssigningAgencyPurchases.AssignmentTypes.Clear();
	TemplateForAssigningAgencyPurchases.AssignmentTypes.Add(Enums.AssignmentTypes.DeliveryForPrincipal);
	
	TemplateForAssigningAgencyPurchases.TermsOfUse_ = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)";

	AppointmentTemplateWithoutAgencyPurchase = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	AppointmentTemplateWithoutAgencyPurchase.LineOfBusiness  = "Object.LineOfBusiness";
	AppointmentTemplateWithoutAgencyPurchase.RecordsInWarehouseRegisters = "TRUE";
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.DeliveryForPrincipal));
	
	AppointmentTemplateWithoutAgencyPurchase.TermsOfUse_ =
		"Object.BusinessOperation NOT IN (
		|					VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))";
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness      = "Object.LineOfBusiness";
	DestinationPattern.Partner                      = "Object.Partner";
	DestinationPattern.Contract                      = "Object.Contract";
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5))";
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True,
		"Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse          = "Object.Goods.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// Returns the destination template
// 
// Parameters:
//  Object - DocumentObject.GoodsShipmentFromStorage, FormDataStructure - 
// Returns:
//  See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(
				Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		DestinationPattern.Partner = Object.Partner;
		DestinationPattern.Contract = Object.Contract;
		DestinationPattern.AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal;
		
		If ValueIsFilled(Object.Basis)
				And Constants.OptionOfGoodsAssignmentInSales.Get() =
					Enums.OptionsOfGoodsAssignmentInSales.SalesOrder Then
			
			DestinationPattern.OrderDocument = Object.Basis;
			
		EndIf;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		DestinationPattern.Partner = Object.Partner;
		DestinationPattern.Contract = Object.Contract;
		DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
		
		If ValueIsFilled(Object.Basis)
			And Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Get() = Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder Then
			DestinationPattern.OrderDocument = Object.Basis;
		ElsIf Not ValueIsFilled(Object.LineOfBusiness) Then
			ContractLB = Common.ObjectAttributeValue(Object.Contract, "LineOfBusiness");
			If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(ContractLB) Then
				DestinationPattern.LineOfBusiness = ContractLB;
			EndIf;
		EndIf;
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region Delivery

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - query text.
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Ref                             AS Ref,
	|	Header.Number                              AS Number,
	|	Header.Date                               AS Date,
	|	Header.Posted                           AS Posted,
	|	Header.Partner                            AS RecipientSender,
	|	Header.CarrierPartner                  AS Carrier,
	|	Header.DeliveryMethod                     AS DeliveryMethod,
	|	Header.DeliveryZone                       AS Zone,
	|	CASE
	|		WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|	END                                    AS Address,
	|	CASE
	|		WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|	END                                    AS FieldValueAddress,
	|	Header.DeliveryTimeFrom                     AS TimeFrom,
	|	Header.DeliveryTimeTo                    AS TimeTo,
	|	Header.AdditionalDeliveryInformation AS AdditionalInformation,
	|	T.Warehouse                                  AS Warehouse,
	|	TRUE                                   AS DeliverFully,
	|	Header.SpecialTransportationConditions             AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription     AS SpecialTransportationConditionsDescription,
	|	FALSE                                     AS SplitGoodsIssueNotesByReferences
	|FROM
	|	(SELECT DISTINCT
	|		T.Ref AS Ref,
	|		T.Warehouse AS Warehouse
	|	FROM
	|		Document.GoodsShipmentFromStorage.Goods AS T
	|	WHERE
	|		T.Ref IN (&References)
	|	) AS T
	|		INNER JOIN Document.GoodsShipmentFromStorage AS Header
	|		ON Header.Ref = T.Ref";
	
	Return QueryText;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return GoodsShipmentFromStorageLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return GoodsShipmentFromStorageLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
// This function checks the order document when creating an expense order.
//
// Parameters:
//	ReferenceOrder - DocumentRef - link to the order document,
//	Warehouse        - CatalogRef.Warehouses - Link to an item in the Warehouses reference list.
//
// Returns:
//	Structure - verification results:
//		* Cancel                      - Boolean - True if the checks passed with errors, otherwise-False,
//		* ErrorText                - String - must be filled in when Failure = True,
//		* DateOfShipment               - Date   - date of shipment of goods,
//		* GroupOfWarehousesAtYourDisposal - Boolean - A group of warehouses is selected at the disposal
//		* UseAdvancedWarehousing  - Boolean - The warehouse uses an order scheme.
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
	
	WarehouseGroupStructure     = New Structure("IsFolder", "Warehouse.IsFolder");
	WarehouseGroupValue      = Common.ObjectAttributesValues(ReferenceOrder, WarehouseGroupStructure);
	
	GroupOfWarehousesAtYourDisposal                   = WarehouseGroupValue.IsFolder;
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
		
		UseAdvancedWarehousing                   = AttributesValues.UseAdvancedWarehousing;
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
				
				ErrorText = NStr("vi = 'Đối với các kho bãi của chứng từ ""%ReferenceOrder%"" không cần lập phiếu xuất kho.
					|Chưa điền chứng từ.';
					|ru = 'Для складов документа ""%ReferenceOrder%"" оформление расходных ордеров не требуется.
					|Заполнение документа не выполнено.';
					|en = 'Goods issue notes are not required for the ""%ReferenceOrder%"" document warehouses.
					|Document is not filled in.'; fa = 'Goods issue notes are not required for the ""%ReferenceOrder%"" document warehouses.
					|Document is not filled in.';
					|it = 'Per il magazzino del documento ""%ReferenceOrder%"" non è richiesta la formalizzazione dei mandati di pagamento.
					|La compilazione del documento non è eseguita.';
					|pl = 'W przypadku magazynów dokumentu ""%ReferenceOrder%"" sporządzenie zleceń wydania nie jest wymagane.
					|Dokument nie został wypełniony.';
					|tr = '""%ReferenceOrder%"" belgesindeki ambarlar için ambar çıkış fişlerini düzenleme gerekmemektedir.
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
	
	Return ReturnStructure;
	
EndFunction

// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	
// Returns:
//  See AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument
//
Function ProcedureForFillingOutAssignmentsInDocument(Form) Export
	
	DocumentProcessingProcedure = AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument();
	DocumentProcessingProcedure.OrderDetailsName = "ByOrder";
	DocumentProcessingProcedure.DocumentDefinesFunctionAssignmentTemplate = True;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	If Form.Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		Or Form.Object.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	EndIf;
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
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
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Partner)
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
#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",            Undefined);
	FillParameters.Insert("FormIsOpen",             False);
	FillParameters.Insert("FillByWarehouseDocument",        Undefined);
	
	FillParameters.Insert("AddSeriesOnRequest", False);
	
	FillParameters.Insert("DiscrepancyCertificate",         Documents.DiscrepancyReportFollowingShipment.EmptyRef());
	FillParameters.Insert("BasisOfAct",            Documents.GoodsShipmentFromStorage.EmptyRef());
	
	FillParameters.Insert("HeaderAttributes",           Undefined);
	FillParameters.Insert("Organization",              Catalogs.Companies.EmptyRef());
	FillParameters.Insert("BusinessOperation",    Enums.BusinessTransactions.EmptyRef());
	FillParameters.Insert("Warehouse",                    Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("Department",            Catalogs.BusinessStructure.EmptyRef());

	FillParameters.Insert("DocumentName",             "GoodsShipmentFromStorage");
	FillParameters.Insert("RegisterNameOrder",         "ShipmentAndReturnReferences");
	FillParameters.Insert("FieldNameOrder",             "SalesOrder");
	
	FillParameters.Insert("KeyFields",             "Products, Characteristic, Series, Purpose, Warehouse");
	
	Return FillParameters;
	
EndFunction
	
// Returns an array containing the passed invoice, as well as:
// A. an Order from an array of orders (if there is one element in the array)
// B. All orders that fit the selection by header details.
//
// Parameters:
//  Invoice		 - DocumentRef.GoodsShipmentFromStorage -
//  HeaderAttributes	 - Structure -
//
// Returns:
//  Array of DocumentRef.MaterialProviderOrder2_5
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	Query = New Query();
	Query.SetParameter("Recorder",      Invoice);
	Query.SetParameter("Partner",          HeaderAttributes.Partner);
	Query.SetParameter("Counterparty",       HeaderAttributes.Counterparty);
	Query.SetParameter("Contract",          HeaderAttributes.Contract);
	Query.SetParameter("Organization",      HeaderAttributes.Organization);
	Query.SetParameter("SalesOpportunity",           HeaderAttributes.SalesOpportunity);
	
	Query.Text =
	"SELECT
	|	MaterialProviderOrder2_5.Ref AS OrderDocument
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Partner       = &Partner
	|	AND MaterialProviderOrder2_5.Counterparty  = &Counterparty
	|	AND MaterialProviderOrder2_5.Contract     = &Contract
	|	AND MaterialProviderOrder2_5.Organization = &Organization
	|	AND MaterialProviderOrder2_5.SalesOpportunity      = &SalesOpportunity
	|	AND MaterialProviderOrder2_5.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	&Recorder AS OrderDocument";
	
	Return Query.Execute().Unload().UnloadColumn("OrderDocument");
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	FillParameters.HeaderAttributes	= HeaderAttributes;
	
	If Not ValueIsFilled(FillParameters.Warehouse) Then
		FillParameters.Warehouse = HeaderAttributes.Warehouse
	EndIf;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	ShipmentReferences.Warehouse AS Warehouse,
		|	(ShipmentReferences.QuantityToBeShippedTurnover -
		|		ShipmentReferences.ShippedQuantityTurnover) AS ToTransferBalance
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
			"ReferenceOrder IN (&GiverSOrders)";
		TableFormationParameters.Group = "Warehouse";
		TableFormationParameters.Indicators = "ToShip, Shipped";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query.SetParameter("GiverSOrders", AnArrayOfOrders);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		
		Selection = Query.Execute().Select();
		
		FillParameters.FillByWarehouseDocument = Selection.Next();
		
	EndIf;
	
EndProcedure

// Fills in the passed parameter table for orders and warehouse orders.
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.GoodsShipmentFromStorage - Link to the current invoice
//  FillParameters	 - Structure - The default parameters are defined in the document parameters () method.
//  PackageBarcodes	 - ValueTable - Table of packaging barcodes
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	FilterByWarehouse = ValueIsFilled(FillParameters.Warehouse);
	
	Query = New Query;
	
	If FilterByWarehouse Then
		
		Query.TempTablesManager = New TempTablesManager;
		
		Query.Text = 
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|INTO TTWarehouses
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	NOT Warehouses.IsFolder
		|	AND Warehouses.Ref IN HIERARCHY (&Warehouse)";
		
		Query.SetParameter("Warehouse", FillParameters.Warehouse);
		Query.Execute();
		
	EndIf;
	
	Goods.Indexes.Add("SalesOrder, " + FillParameters.KeyFields);
	
	// 1. Orders
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "ReferenceOrder", "&References");
	If FilterByWarehouse Then
		TMCommonUse.AddSelectionItemToCollection(
			Filter,
			"Warehouse",
			"SELECT
			|	TTWarehouses.Warehouse
			|FROM
			|TTWarehouses AS TTWarehouses");
	EndIf;
	
	RequestTextForOrders =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextBalance("TTAccountingData", Filter, "ToTransfer <> 0");
	
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "Ref", "&References");
	
	QueryTextOrderDocument = Documents.MaterialProviderOrder2_5.QueryTextDocumentGoods(Filter, "ManufacturedProduct");
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(RequestTextForOrders);
	ArrayOfTexts.Add(QueryTextOrderDocument);
	
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder",  Recorder);
	
	OrdersTable = Query.Execute().Unload();
	
	TableColumn2 = OrdersTable.Columns.ReferenceOrder; // ValueTableColumn
	TableColumn2.Name = "SalesOrder";
	TableColumn2 = OrdersTable.Columns.ToTransfer; // ValueTableColumn
	TableColumn2.Name = "QuantityInOrder";
	
	// Adding the number of orders
	Var_Key = "SalesOrder, RowCode, " + FillParameters.KeyFields;
	
	Condition = "On [Count]";
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
	// 2. Orders
	If Not FillParameters.FillByWarehouseDocument Then
		Return;
	EndIf;
	
	Filter = New Map;
	If FilterByWarehouse Then
		TMCommonUse.AddSelectionItemToCollection(Filter, "Warehouse", "SELECT Warehouse FROM TTWarehouses");
	EndIf;	
	
	Query.Text = AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue(Filter);
	
	TableOrders = Query.Execute().Unload();
	
	TableColumn2 = TableOrders.Columns.Count; // ValueTableColumn
	TableColumn2.Name = "NoteQuantity";
	TableColumn2 = TableOrders.Columns.ReferenceOrder; // ValueTableColumn
	TableColumn2.Name = "SalesOrder";
	
	If TableOrders.Columns.Find("AssemblyInProgress") <> Undefined Then
		TableColumn2 = TableOrders.Columns.AssemblyInProgress; // ValueTableColumn
		TableColumn2.Name = "NumberInProgress";
	EndIf;
	
	// Adding the number of orders.
	Var_Key = "SalesOrder, " + FillParameters.KeyFields;
	
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
	
	// Additional information - how much product is collected
	If TableOrders.Columns.Find("NumberInProgress") <> Undefined Then
		InvoicesServer.AllocateQuantity(TableOrders, Goods, "NumberInProgress", Var_Key, "", True);
	EndIf;
	
	If ValueIsFilled(FillParameters.AnArrayOfOrders) Then
		GoodsShipmentFromStorageLocalization.FillInBarcodesOfPackages(FillParameters.AnArrayOfOrders, Goods, PackageBarcodes);
	EndIf;
	
EndProcedure

// Fills in product and discount tables based on selection data or an array of orders
//
// Parameters:
//	SelectionData_        - Structure - fields that will be used to select order balances for filling in the document
//	Goods              - FormDataCollection - item table in which are placed the remains of the orders
//	Warehouse               - CatalogRef.Warehouses - warehouse where order balances will be selected
//	AnArrayOfOrders       - Array - orders for which balances will be selected
//	FillParameters - Structure - Fill-in parameters.
//
Procedure FillByOrderBalances(SelectionData_, Goods, Warehouse, AnArrayOfOrders, FillParameters) Export
	
	// Data on the remaining items of the order
	RequestResultForOrderBalances = GetQueryResultsForOrderBalances(SelectionData_, Warehouse, AnArrayOfOrders);
	
	If RequestResultForOrderBalances[4].IsEmpty()
	   And RequestResultForOrderBalances[5].IsEmpty()
	   And FillParameters.Property("DisplayMessage_1")
	   And FillParameters.DisplayMessage_1 Then
		
		ErrorText = ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment();
		
		Raise ErrorText;
		
	EndIf;
	
	SelectionByOrdersOrders = FillParameters.Property("SelectionByOrdersOrders")
							 And FillParameters.SelectionByOrdersOrders;
	
	DesignParameters = Undefined;
	If FillParameters.Property("DesignParameters", DesignParameters) 
	   And DesignParameters <> Undefined Then
		
		FillByWarehouseDocument = DesignParameters.ByNotes And Not DesignParameters.ByOrders;
		
	Else
		
		OrderOfExecutionOfOrderFirst =
			Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() =
				Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst;
		
		FillByWarehouseDocument = Not SelectionByOrdersOrders And OrderOfExecutionOfOrderFirst;
		
	EndIf;
	
	ShippedGoods_ = RequestResultForOrderBalances[8].Unload();
	
	SampleProducts_ = RequestResultForOrderBalances[4].Select();
	While SampleProducts_.Next() Do
		
		QuantityToShip = SampleProducts_.Count;
		
		FillingByOrder  = FillByWarehouseDocument And SampleProducts_.CheckShipment;
		If FillingByOrder Then
			
			SearchParameters = New Structure;
			SearchParameters.Insert("SalesOrder",   SampleProducts_.SalesOrder);
			SearchParameters.Insert("Products",   SampleProducts_.Products);
			SearchParameters.Insert("Characteristic", SampleProducts_.Characteristic);
			SearchParameters.Insert("Warehouse",          SampleProducts_.Warehouse);
			SearchParameters.Insert("Series",          SampleProducts_.Series);
			SearchParameters.Insert("Purpose",     SampleProducts_.Purpose);
			
			FoundRows = ShippedGoods_.FindRows(SearchParameters);
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			ShippedLine = FoundRows[0];
			
			If ShippedLine.Count > 0 Then
				
				If ShippedLine.Count < SampleProducts_.Count Then
					QuantityToShip          = ShippedLine.Count;
					ShippedLine.Count = 0;
				Else
					QuantityToShip          = SampleProducts_.Count;
					ShippedLine.Count = ShippedLine.Count - SampleProducts_.Count;
				EndIf;
				
			Else
				Continue;
			EndIf;
			
		EndIf;
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_,, "Count");
		TabRow.Count         = QuantityToShip;
		TabRow.NumberOfPackages = QuantityToShip / SampleProducts_.ZoomRatio;
		
		If SelectionByOrdersOrders Then
			
			TabRow.QuantityInOrder         = ?(SampleProducts_.RowCode <> 0, QuantityToShip, 0);
			TabRow.PackagingQuantityInTheOrder = TabRow.QuantityInOrder / SampleProducts_.ZoomRatio;
			
			SearchParameters = New Structure;
			SearchParameters.Insert("SalesOrder",   SampleProducts_.SalesOrder);
			SearchParameters.Insert("Products",   SampleProducts_.Products);
			SearchParameters.Insert("Characteristic", SampleProducts_.Characteristic);
			SearchParameters.Insert("Warehouse",          SampleProducts_.Warehouse);
			SearchParameters.Insert("Series",          SampleProducts_.Series);
			SearchParameters.Insert("Purpose",     SampleProducts_.Purpose);
			
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
						
						ShippedLine.Count        = 0;
						ShippedGoods_.Delete(ShippedLine);
						
					Else
						
						TabRow.NoteQuantity         = SampleProducts_.Count;
						TabRow.PackagingQuantityInTheNote = SampleProducts_.Count / SampleProducts_.ZoomRatio;
						
						ShippedLine.Count        = ShippedLine.Count - SampleProducts_.Count;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If (SelectionByOrdersOrders Or FillByWarehouseDocument) And ShippedGoods_.Count() > 0 Then
		
		For Each ShippedLine In ShippedGoods_ Do
	
			If ShippedLine.Count > 0 Then //If you have shipped more
				
				SearchParameters = New Structure;
				SearchParameters.Insert("Products",   ShippedLine.Products);
				SearchParameters.Insert("Characteristic", ShippedLine.Characteristic);
				SearchParameters.Insert("Warehouse",          ShippedLine.Warehouse);
				SearchParameters.Insert("Series",          ShippedLine.Series);
				SearchParameters.Insert("Purpose",     ShippedLine.Purpose);
				
				If TypeOf(ShippedLine.SalesOrder) = Type("DocumentRef.MaterialProviderOrder2_5") Then
					SearchParameters.Insert("SalesOrder", ShippedLine.SalesOrder);
				EndIf;
				
				FoundRows = Goods.FindRows(SearchParameters);
				
				If SelectionByOrdersOrders Then
				
					If FoundRows.Count() > 0 Then
						
						TabRow = FoundRows[0];
						
						TabRow.PackagingQuantityInTheNote =
							TabRow.PackagingQuantityInTheNote
							+ ShippedLine.Count * (TabRow.PackagingQuantityInTheNote / TabRow.Count);
						
						TabRow.NoteQuantity = TabRow.NoteQuantity + ShippedLine.Count;
						
					Else
						
						TabRow = Goods.Add();
						FillPropertyValues(TabRow, ShippedLine);
						TabRow.NoteQuantity         = ShippedLine.Count;
						TabRow.PackagingQuantityInTheNote = ShippedLine.Count;
						
					EndIf;
					
				ElsIf ShippedLine.AdvancedWarehousingOnShipment Then
					
					If FoundRows.Count() > 0 Then
						
						TabRow = FoundRows[0];
						
						TabRow.NumberOfPackages =
							TabRow.NumberOfPackages
							+ ShippedLine.Count * (TabRow.NumberOfPackages / TabRow.Count);
						
						TabRow.Count = TabRow.Count + ShippedLine.Count;
						
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

#EndRegion
// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn.DescriptionOfBankingDetailsToFillIn
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
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Basis, Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	Parameters.FillInIf.ObjectFieldsAreEmpty = "Basis";
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

#Region BasisForPrint

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.GoodsShipmentFromStorage - The document object for which you want to get the selection list.
//
// Returns:
//	ValueTable - Table of values with Attributes of the bases:
//     * Basis      - String - name of the foundation.
//     * ReferenceDocumentDateForPrintForms  - String - date of foundation.
//     * BaseDocumentNumber - String - base number.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object);
	If ValueIsFilled(BaseStructure.BasisForPrint) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.BasisForPrint;
	EndIf;
	
	Return TableOfBases_;
	
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
	Return;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	StandardProcessing = False;
	
	If Data.BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale
	 Or Data.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		DocumentSynonym = NStr("vi = 'Xuất kho hàng hóa từ nơi cất giữ';
								|ru = 'Отгрузка товаров с хранения';
								|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
								|it = 'Spedizione delle merci dal deposito';
								|pl = 'Wysyłka towarów z przechowywania';
								|tr = 'Malların VMI''dan sevkiyat talebi'");
		
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		
		DocumentSynonym = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		DocumentSynonym = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		
	EndIf;
	
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), DocumentSynonym, Data.Number, Data.Date);
	Return;
	
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
		Warehouses.Add(Catalogs.Warehouses.EmptyRef()); // goods will not be filled in during the processing of filling in the document, a message will be issued about the absence of lines with the necessary action
	EndIf;
	
	ParametersForCreatingWarehousesByGroup = New Structure();
	ParametersForCreatingWarehousesByGroup.Insert("WarehousesList", Warehouses);
	ParametersForCreatingWarehousesByGroup.Insert("MultipleWarehouses", MultipleWarehouses);
	
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	// under question
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
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.ByOrder                AS ByOrder,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.Warehouse                   AS Warehouse,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.GoodsShipmentFromStorage AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	NumberForPrinting                          = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	MetadataIdentifier                = Common.MetadataObjectID(FullObjectName());

	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier",              MetadataIdentifier);
	Query.SetParameter("ContractInformation",                 ContractInformation);
	Query.SetParameter("NumberForPrinting",                        NumberForPrinting);
	Query.SetParameter("Patch",                          Attributes.Patch);
	Query.SetParameter("ReversedDocument",                 Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",                 Attributes.CorrectedDocument);
	Query.SetParameter("DeliveryForPrincipal",                Attributes.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal);
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                                               AS Document,
	|	&Period                                                               AS Period,
	|	&Ref                                                               AS Recorder,
	|	SeriesTable.Products                                             AS Products,
	|	SeriesTable.Characteristic                                           AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                                 AS Purpose,
	|	SeriesTable.Series                                                    AS Series,
	|	SeriesTable.Count                                               AS Count,
	|	SeriesTable.Warehouse                                                    AS Sender,
	|	&Partner                                                              AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ShipmentUnderReturnToVendor) AS WarehouseOperation,
	|	CASE
	|		WHEN NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsShipmentFromStorage.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	&Warehouse,
	|	&Partner,
	|	VALUE(Enum.WarehouseTransactions.ShipmentUnderReturnToVendor),
	|	CASE
	|		WHEN NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
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
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority";
	
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
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
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
	|	Document.GoodsShipmentFromStorage.InventoryKinds AS DocumentTable
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	&Period                                       AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
	|					VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5))
	|			THEN &BusinessOperation
	|		WHEN TRUE
	|			THEN VALUE(Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale)
	|	END                                         AS BusinessOperation,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	VALUE (Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	TableTypesOfStocks_.DocumentInflow        AS DocumentSalesOfGoodsAndServices
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	TempTableName = "TTTypesOfStocks";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                        AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                      AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose                          AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series                               AS Series,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation                       AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	KeysWithoutAssignment.DimensionKey              AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType      AS InventoryType,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	TableTypesOfStocks_.RowID        AS RowID,
	|	TableTypesOfStocks_.DocumentInflow        AS DocumentInflow
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.GoodsShipmentFromStorage.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysWithoutAssignment
	|	ON TableTypesOfStocks_.ItemsLocationAttributes.Products                          = KeysWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                     = KeysWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series                              = KeysWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation                      = KeysWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = KeysWithoutAssignment.Purpose
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		WHEN &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|											UNDEFINED,
	|											VALUE(Document.SalesOrder.EmptyRef))
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
	|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			AND HeaderData_.ByOrder
	|			AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		WHEN TRUE
	|			THEN FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN TRUE
	|		WHEN &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|											UNDEFINED,
	|											VALUE(Document.SalesOrder.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS DocumentGoods
	|		LEFT JOIN Document.GoodsShipmentFromStorage AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0";
	
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
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		WHEN &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|						UNDEFINED,
	|						VALUE(Document.SalesOrder.EmptyRef))
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
	|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			AND HeaderData_.ByOrder
	|			AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		WHEN TRUE
	|			THEN FALSE
	|	END								AS ExceedingOrder,
	|	CASE
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN TRUE
	|		WHEN &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN (
	|						UNDEFINED,
	|						VALUE(Document.SalesOrder.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder,
	|	CASE
	|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|			THEN FALSE
	|		ELSE TRUE
	|	END								AS GoodsReturn
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS DocumentGoods
	|		LEFT JOIN Document.GoodsShipmentFromStorage AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0";
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
	
	MetadataObject	= Metadata.Documents.GoodsShipmentFromStorage;
	TSSeriesName			= "SetOfSeries";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										TSSeriesName);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Goods.ItemsLocationAttributes.Products   AS Products,
	|	Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	&EmptyAssignment    AS Purpose,
	|	Goods.ItemsLocationAttributes.Series          AS Series,
	|	Goods.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|FROM
	|	Document.GoodsShipmentFromStorage.InventoryKinds AS Goods
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON (Goods.ItemsLocationAttributes.Products      = Dimension.Products)
	|			AND (Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic)
	|			AND (Goods.ItemsLocationAttributes.Series          = Dimension.Series)
	|			AND (Goods.ItemsLocationAttributes.StorageLocation  = Dimension.StorageLocation)
	|			AND (&EmptyAssignment    = Dimension.Purpose)
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
	
	AnalyticsParameters = New Structure;
	AnalyticsParameters.Insert("Partner",                 Query.Parameters.Partner);
	AnalyticsParameters.Insert("Counterparty",              Query.Parameters.Counterparty);
	AnalyticsParameters.Insert("Organization",             Query.Parameters.Organization);
	AnalyticsParameters.Insert("Contract",                 Query.Parameters.Contract);
	AnalyticsParameters.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	Query.SetParameter("AccountingDimensionByPartners",
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters));
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.GoodsShipmentFromStorage";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",         """""");
	RedefiningParameterCalculation.Insert("ContractInformation",  """""");
	
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

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	0 AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &DeliveryForPrincipal
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|	AND NOT GoodsTable.SalesOrder IN (
	|	UNDEFINED,
	|	VALUE(Document.SalesOrder.EmptyRef))
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip) AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.RowCode = 0
	|	AND NOT GoodsTable.SalesOrder = UNDEFINED
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.SalesOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped) AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.SalesOrder = UNDEFINED
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
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
		|	Document.GoodsShipmentFromStorage.Goods AS TabPart
		|WHERE
		|	TabPart.SalesOrder IN (
		|		UNDEFINED,
		|		VALUE(Document.SalesOrder.EmptyRef))
		|	OR TabPart.RowCode = 0
		|		AND TabPart.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
		|";
	
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
	AdditionalParameters.Add("AccountingDimensionByPartners");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
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
	
	#Region Sales_Product
	
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
	|	UNDEFINED 									AS VATActivityType,
	|	UNDEFINED									AS DocumentVATActivityType,
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
	|	&BusinessOperation					AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsShipmentFromStorage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
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
	
	// Shipment of goods from storage
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id                  = "GoodsShipmentFromStorage";
	PrintCommand.Presentation                  = NStr("vi = 'Xuất kho hàng hóa từ nơi cất giữ';
														|ru = 'Отгрузка товаров с хранения';
														|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
														|it = 'Spedizione delle merci dal deposito';
														|pl = 'Wysyłka towarów z przechowywania';
														|tr = 'Malların VMI''dan sevkiyat talebi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 10;
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale);
	TransactionList.Add(Enums.BusinessTransactions.DeliveryForPrincipal);
	
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		TransactionList,
		ComparisonType.InList);
		
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "TransferToMaterialProvider2_5";
	PrintCommand.Presentation =
		TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 10;
	
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		Enums.BusinessTransactions.TransferToMaterialProvider2_5,
		ComparisonType.Equal);
		
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ReturnToMaterialProvider2_5";
	PrintCommand.Presentation =
		TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 10;
	
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		Enums.BusinessTransactions.ReturnToMaterialProvider2_5,
		ComparisonType.Equal);
	
	If Constants.UseInternationalPrintingForms.Get() Then
		// InvoiceInt
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
		
		PrintManagement.AddCommandVisibilityCondition(
			PrintCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToMaterialProvider2_5,
			ComparisonType.Equal);

	EndIf;
	If Not ThisIsPartner Then
		
		// Task for the selection of goods
		DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	
	EndIf;
	
	GoodsShipmentFromStorageLocalization.AddPrintCommands(PrintCommands);

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
	
	TemplateName = "GoodsShipmentFromStorage";
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, TemplateName) Then
		TemplateSynonym = NStr("vi = 'Xuất kho hàng hóa từ nơi cất giữ';
								|ru = 'Отгрузка товаров с хранения';
								|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
								|it = 'Spedizione delle merci dal deposito';
								|pl = 'Wysyłka towarów z przechowywania';
								|tr = 'Malların VMI''dan sevkiyat talebi'");
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, TemplateName, TemplateSynonym,
			FormPrintedFormShipmentOfGoodsFromStorage(ObjectsArray, PrintObjects));
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "TransferToMaterialProvider2_5") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"TransferToMaterialProvider2_5",
			TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver(),
			FormPrintedFormShipmentOfGoodsFromStorage(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReturnToMaterialProvider2_5") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReturnToMaterialProvider2_5",
			TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver(),
			FormPrintedFormShipmentOfGoodsFromStorage(ObjectsArray, PrintObjects));
		
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	GoodsShipmentFromStorageLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
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
//	Undefined - If it was not possible to form a set of printed forms.
//
Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure")
		And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
									Metadata.Documents.GoodsShipmentFromStorage.FullName(),
									ObjectsArray,
									Undefined);
		
	EndIf;
	
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
																									PrintFormsSet,
																									ObjectsArray,
																									"GoodsShipmentFromStorage");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormShipmentOfGoodsFromStorage(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
																									PrintFormsSet,
																									ObjectsArray,
																									"GoodsPickingPlacementJob");
	
	PrintParameters.Insert("JobType", "SelectionTask");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.GoodsShipmentFromStorage", PrintKit.Objects);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.CreateTaskForProductSelectionAndPlacement(StructureOfTypes,
																										PrintObjects,
																										PrintParameters));
	EndDo;
	
	GoodsShipmentFromStorageLocalization.CreateSetOfPrintedForms(ObjectsArray,
																			PrintParameters,
																			PrintFormsCollection,
																			PrintObjects,
																			PrintFormsSet);
	
EndFunction

Function PrintFormsSet() Export

	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"GoodsShipmentFromStorage",
																			NStr("vi = 'Xuất kho hàng hóa từ nơi cất giữ';
																				|ru = 'Отгрузка товаров с хранения';
																				|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
																				|it = 'Spedizione delle merci dal deposito';
																				|pl = 'Wysyłka towarów z przechowywania';
																				|tr = 'Malların VMI''dan sevkiyat talebi'"),
																			1);
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"GoodsPickingPlacementJob",
																			NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
																				|ru = 'Задание на отбор товаров';
																				|en = 'Picking job'; fa = 'کار برداشت';
																				|it = 'Task per selezione prodotti';
																				|pl = 'Zadanie na selekcję towarów';
																				|tr = 'Mal seçimi görevi'"),
																			0);
																			
	GoodsShipmentFromStorageLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

// This function generates a printed form of documents for shipment of goods from storage.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - printed form of documents for the shipment of goods from storage.
//
Function FormPrintedFormShipmentOfGoodsFromStorage(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsShipmentFromStorage.Ref                     AS Ref,
	|	GoodsShipmentFromStorage.Number                      AS Number,
	|	GoodsShipmentFromStorage.Date                       AS Date,
	|	GoodsShipmentFromStorage.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	GoodsShipmentFromStorage.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected,
	|	GoodsShipmentFromStorage.Partner                    AS Partner,
	|	GoodsShipmentFromStorage.Counterparty                 AS Recipient,
	|	GoodsShipmentFromStorage.Organization                AS Organization,
	|	GoodsShipmentFromStorage.Organization.Prefix        AS Prefix,
	|	GoodsShipmentFromStorage.BusinessOperation      AS BusinessOperation,
	|	GoodsShipmentFromStorage.Currency                     AS Currency,
	|	GoodsShipmentFromStorage.IssuiedBy                   AS VacationProduced
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|WHERE
	|	GoodsShipmentFromStorage.Ref IN(&DocumentsArray)
	|	AND GoodsShipmentFromStorage.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref                            AS Ref,
	|	NestedQuery.LineNumber                       AS LineNumber,
	|	NestedQuery.Products.Code                  AS Code,
	|	NestedQuery.Products.SKU              AS SKU,
	|	NestedQuery.Products.DescriptionFull   AS ProductNameFull_,
	|	NestedQuery.Products                      AS Products,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END                                             AS Package,
	|	NestedQuery.Count                        AS Count,
	|	NestedQuery.UnitOfMeasure.Description     AS UnitPrice,
	|	NestedQuery.UnitOfMeasure                  AS UnitOfMeasure,
	|	NestedQuery.Price                              AS Price,
	|	NestedQuery.Sum                             AS Sum
	|FROM
	|	(SELECT
	|		GoodsShipmentFromStorage.Ref               AS Ref,
	|		GoodsShipmentFromStorage.LineNumber          AS LineNumber,
	|		GoodsShipmentFromStorage.Products         AS Products,
	|		GoodsShipmentFromStorage.Characteristic       AS Characteristic,
	|		GoodsShipmentFromStorage.Package             AS Package,
	|		CASE
	|			WHEN GoodsShipmentFromStorage.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsShipmentFromStorage.Products.UnitOfMeasure
	|			ELSE GoodsShipmentFromStorage.Package
	|		END                                         AS UnitOfMeasure,
	|		CASE
	|			WHEN GoodsShipmentFromStorage.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor2
	|		END                                         AS ZoomRatio,
	|		GoodsShipmentFromStorage.NumberOfPackages   AS Count,
	|		GoodsShipmentFromStorage.Price                 AS Price,
	|		GoodsShipmentFromStorage.Sum                AS Sum
	|	FROM
	|		Document.GoodsShipmentFromStorage.Goods AS GoodsShipmentFromStorage
	|	WHERE
	|		GoodsShipmentFromStorage.Ref IN(&DocumentsArray)
	|		AND GoodsShipmentFromStorage.Ref.Posted) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("NestedQuery.Package",
																							"NestedQuery.Products"));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("GoodsShipmentFromStorage.Package",
																							"GoodsShipmentFromStorage.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsShipmentFromStorage_Invoice";
	
	ResultsArray   = Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.GoodsShipmentFromStorage.PF_MXL_GoodsShipmentFromStorage");
		
		ProductSelection_1 = SelectionByDocuments.Select();
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TemplateArea = Template.GetArea("Title");
		
		HeaderDataStructure_1 = New Structure;
		If PrintData.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			DocumentSynonym = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		ElsIf PrintData.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			DocumentSynonym = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		Else
			DocumentSynonym = NStr("vi = 'Xuất kho hàng hóa từ nơi cất giữ';
									|ru = 'Отгрузка товаров с хранения';
									|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
									|it = 'Spedizione delle merci dal deposito';
									|pl = 'Wysyłka towarów z przechowywania';
									|tr = 'Malların VMI''dan sevkiyat talebi'", Common.DefaultLanguageCode());
		EndIf;
		HeaderDataStructure_1.Insert("TitleText",
										TMCommonUseClientServer.GenerateDocumentTitle(
											PrintData,
											DocumentSynonym));
		
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
																		Template,
																		TemplateArea,
																		PrintData.Ref);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea            = Template.GetArea("Vendor");
		SupplierPresentation  = PrintFormGeneration.OrganizationDescription(
										PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date),
										"FullDescr");
		
		DataStructureProvider = New Structure;
		DataStructureProvider.Insert("Vendor",               PrintData.Organization);
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date),
									"FullDescr");
		
		CustomerDataStructure = New Structure;
		CustomerDataStructure.Insert("Recipient",              PrintData.Recipient);
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		ProductColumnArea = Template.Area("OwnGoods");
		
		If Not OutputCodes Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
		EndIf;
		
		// Output the title of the Products table
		RoomArea     = Template.GetArea("TableHeader|LineNumber");
		AreaCodes      = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductArea      = Template.GetArea("TableHeader|OwnGoods");
		DataArea     = Template.GetArea("TableHeader|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		RoomArea  = Template.GetArea("TableRow|LineNumber");
		AreaCodes   = Template.GetArea("TableRow|ColumnOfCodes");
		ProductArea   = Template.GetArea("TableRow|OwnGoods");
		DataArea  = Template.GetArea("TableRow|Data");
		
		Sum       = 0;
		LineNumber = 0;
		
		// Output the rows of the Goods table
		While ProductSelection_1.Next() Do
			
			LineNumber                = LineNumber + 1;
			DataStructureLineNumber = New Structure("LineNumber", LineNumber);
			
			RoomArea.Parameters.Fill(DataStructureLineNumber);
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersProductPresentation);
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductArea.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductArea);
			
			DataArea.Parameters.Fill(ProductSelection_1);
			SpreadsheetDocument.Join(DataArea);
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				Sum = Sum + ProductSelection_1.Sum;
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
		
		TotalDataStructure = New Structure("Total", PrintFormGeneration.SumFormat(Sum));
		
		DataArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the Amount in words
		TemplateArea = Template.GetArea("AmountInWords");
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Tổng số %1, thành tiền %2';
								|ru = 'Всего наименований %1, на сумму %2';
								|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
								|it = 'Totale articoli %1, per importo di %2';
								|pl = 'Razem pozycji %1, na kwotę %2';
								|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
							ProductSelection_1.Count(),
							PrintFormGeneration.SumFormat(Sum, PrintData.Currency));
		
		DataStructureSummaryRow = New Structure;
		DataStructureSummaryRow.Insert("TotalString", TotalString);
		DataStructureSummaryRow.Insert(
			"AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(Sum, PrintData.Currency));
		
		TemplateArea.Parameters.Fill(DataStructureSummaryRow);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			DataStructureVacationProduced = New Structure;
			DataStructureVacationProduced.Insert("VacationProduced",
				PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date));
			
			TemplateArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	
EndProcedure

// Get data for the printed form of the invoice for payment.
// 
// Parameters:
//	PrintParameters - Structure - structure of additional print parameters,
//	ObjectsArray  - Array of DocumentRef.GoodsShipmentFromStorage    - an array of references to objects which need to print,
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
//
// Returns:
//  Structure - Get Data For The Printed Invoice Form:
// * HeaderResults - QueryResult -
// * ResultsByPaymentStages - QueryResult -
// * ResultForTabularPart - QueryResult -
//
Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

// Get data for the printed form of the invoice for payment.
// 
// Parameters:
//	PrintParameters - Structure - structure of additional print parameters,
//	ObjectsArray  - Array of DocumentRef.GoodsShipmentFromStorage    - an array of references to objects which need to print,
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
// 
// Returns:
//  Structure - Get Data For The Printed Invoice Form:
// * HeaderResults - QueryResult -
// * ResultsByPaymentStages - QueryResult -
// * ResultForTabularPart - QueryResult -
//
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
	|	FALSE AS ConsiderVAT,
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
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE Documents.CompanyBankAccount.Bank.InternationalDescription END AS BankNameInt,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE Documents.CompanyBankAccount.TransferBank.InternationalDescription END AS BankNameForPaymentsInt,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankSWIFTCode AS BankSWIFTCode,
	|	Documents.CompanyBankAccount.BankSWIFTCodeForPayments AS BankSWIFTCodeForPayments,
	|	Documents.CompanyBankAccount.BankAddress AS BankAddress,
	|	Documents.CompanyBankAccount.TransferBankAddress AS TransferBankAddress,
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
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
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
	|	Document.GoodsShipmentFromStorage AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
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
	|	Goods.Products.DescriptionFull					AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	UNDEFINED                                             AS VATRate,
	|	0                                                        AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(Goods.Characteristic.DescriptionFull, """") AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	0                                                        AS DiscountAmount,
	|	Goods.Sum                                             AS AmountWithoutADiscount,
	|	FALSE                                 AS ThisIsReusablePackage	
	|FROM 
	|	Document.GoodsShipmentFromStorage.Goods AS Goods
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

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.GoodsShipmentFromStorage))
		And AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5)
		And (AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage)
			Or AccessRight("Update", Metadata.Documents.GoodsShipmentFromStorage))
		And GetFunctionalOption("UseTollManufacturing2_5");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	TransfersToGiversForRegistrationForRegistration2_5 =
		DataProcessors.DocumentsOfReceiptForTollingAll2_5.NumberOfLinesForLayout(
			Enums.BusinessTransactions.TransferToMaterialProvider2_5);
		
	ReturnsOfRawMaterialsToGiversForRegistrationForRegistration2_5 =
		DataProcessors.DocumentsOfReceiptForTollingAll2_5.NumberOfLinesForLayout(
			Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	
	UserTaskParent = ToDoList.Find("ProcessingOfProvidedMaterials2_5", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id = "ProcessingOfProvidedMaterials2_5";
		UserTaskParent.Presentation = NStr("vi = 'Gia công sản xuất';
											|ru = 'Переработка давальческого сырья';
											|en = 'Subcontracting services'; fa = 'خدمات پیمانکاری فرعی';
											|it = 'Trasformazione di materie prime del committente';
											|pl = 'Przetwarzanie surowców dostarczonych przez klienta';
											|tr = 'Sağlayıcı hammaddelerinin yeniden işlenmesi'");
		UserTaskParent.Owner      = Metadata.Subsystems.Sales;
	EndIf;
	
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems
							Or TransfersToGiversForRegistrationForRegistration2_5 > 0
							Or ReturnsOfRawMaterialsToGiversForRegistrationForRegistration2_5 > 0;
	
	// Transfers to givers for registration
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPageName",      "ProductTransferPage");
	FormParameters.Insert("FormAssignmentKey",     "ToDoList");
	FormParameters.Insert("QuickFilterStructure", New Structure);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "TransfersToGiversForRegistrationForRegistration2_5";
	ToDoItem.HasToDoItems       = TransfersToGiversForRegistrationForRegistration2_5 > 0;
	ToDoItem.Presentation  = NStr("vi = 'Chuyển giao cho bên đặt gia công cần lập chứng từ';
									|ru = 'Передачи давальцам к оформлению';
									|en = '""Goods issues — Subcontracting services delivered"" for registration'; fa = '""Goods issues — Subcontracting services delivered"" for registration';
									|it = 'Consegne ai prestatori da formalizzare';
									|pl = 'Transfery do dostawców do rejestracji';
									|tr = 'Düzenleme için sağlayıcılara transferler'");
	ToDoItem.Count     = TransfersToGiversForRegistrationForRegistration2_5;
	ToDoItem.Important         = False;
	ToDoItem.Form          = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices";
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ProcessingOfProvidedMaterials2_5";
	
	// Returns of raw materials to givers for registration
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPageName",      "RawMaterialReturnsPage");
	FormParameters.Insert("FormAssignmentKey",     "ToDoList");
	FormParameters.Insert("QuickFilterStructure", New Structure);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ReturnsOfRawMaterialsToGiversForRegistrationForRegistration2_5";
	ToDoItem.HasToDoItems       = ReturnsOfRawMaterialsToGiversForRegistrationForRegistration2_5 > 0;
	ToDoItem.Presentation  = NStr("vi = 'Trả lại nguyên vật liệu cho bên đặt gia công cần lập chứng từ';
									|ru = 'Возвраты сырья давальцам к оформлению';
									|en = 'Returns of raw materials to providers to register'; fa = 'Returns of raw materials to providers to register';
									|it = 'Resi di materie prime ai fornitori in formalizzazione';
									|pl = 'Zwroty surowców właścicielom surowców do rejestracji';
									|tr = 'Düzenleme için hammaddelerin sağlayıcılara iadesi'");
	ToDoItem.Count     = ReturnsOfRawMaterialsToGiversForRegistrationForRegistration2_5;
	ToDoItem.Important         = False;
	ToDoItem.Form          = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices";
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ProcessingOfProvidedMaterials2_5";
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInListOfBusinessOperations(TransactionList) Export
	
	TransactionList.Clear();
	
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		TransactionList.Add(
			Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale,
			NStr("vi = 'Xuất kho cho người gửi';
				|ru = 'Отгрузка поклажедателю';
				|en = 'VMI pick-up request from vendor'; fa = 'درخواست برداشت VMI از تأمین‌کننده';
				|it = 'Spedizione al depositante';
				|pl = 'Wysyłka do depozytariusza';
				|tr = 'Göndericiye sevkiyat'"));
	EndIf;
	
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		TransactionList.Add(
			Enums.BusinessTransactions.DeliveryForPrincipal,
			NStr("vi = 'Xuất kho cho người đặt ký gửi';
				|ru = 'Отгрузка принципалу';
				|en = 'Shipment to principal'; fa = 'ارسال به مالک اصلی';
				|it = 'Spedizione al mandante';
				|pl = 'Wysyłka do zleceniodawcy';
				|tr = 'İş verene sevkiyat'"));
	EndIf;
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		TransactionList.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
		TransactionList.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	EndIf;
EndProcedure

// Returns the base text based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.GoodsShipmentFromStorage - The object of the document for which you want to get the text of the base
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object)
	
	StructureBase = New Structure;
	StructureBase.Insert("BasisForPrint");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		And Object.ByOrder Then
		
		AnArrayOfOrders = Object.Goods.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
		
		Query = New Query(
		"SELECT ALLOWED
		|	GiverSOrders.NumberAccordingToPartnerData AS NumberAccordingToPartnerData,
		|	GiverSOrders.DateAccordingToInformationFromPartner  AS DateAccordingToInformationFromPartner,
		|	GiverSOrders.Number                 AS Number,
		|	GiverSOrders.Date                  AS Date,
		|	&SynonymForOrder                       AS Synonym
		|FROM
		|	Document.MaterialProviderOrder2_5 AS GiverSOrders
		|WHERE
		|	GiverSOrders.Ref IN(&AnArrayOfOrders)
		|");
		
		Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
		Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của bên đặt gia công';
													|ru = 'Заказ давальца';
													|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
													|it = 'Заказ давальца';
													|pl = 'Zamówienie dostawcy';
													|tr = 'Tedarikçi siparişi'"));
		Selection = Query.Execute().Select();
		
		TextForOrders = "";
		OneFoundation = Selection.Count() = 1;
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.NumberAccordingToPartnerData) And ValueIsFilled(Selection.DateAccordingToInformationFromPartner) Then
				
				InformationAboutOrder =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 số %2 ngày %3';
							|ru = '%1 № %2 от %3';
							|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
							|it = '%1 № %2 от %3';
							|pl = '%1 nr %2 z dnia %3.';
							|tr = '%2sayılı %3tarihli %1'"),
						Selection.Synonym,
						Selection.NumberAccordingToPartnerData,
						Format(Selection.DateAccordingToInformationFromPartner, "DLF=DD"));
				
				DateForOrders  = Selection.DateAccordingToInformationFromPartner;
				OrderNumber_1 = Selection.NumberAccordingToPartnerData;
				
			Else
				
				InformationAboutOrder =
					TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
				
				DateForOrders  = Selection.Date;
				OrderNumber_1 = Selection.Number;
				
			EndIf;
			
			TextForOrders = TextForOrders + ", " + InformationAboutOrder;
			
		EndDo;
		
		StructureBase.BasisForPrint      = TrimAll(Mid(TextForOrders, 3));
		StructureBase.ReferenceDocumentDateForPrintForms  = ?(OneFoundation, DateForOrders, "");
		StructureBase.BaseDocumentNumber = ?(OneFoundation, ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1), "");
		
		If ValueIsFilled(Object.Contract) Then
			
			ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "Date, Number");
			ContractDetailsText = StrTemplate(
				NStr("vi = 'theo hợp đồng số %1 ngày %2';
					|ru = 'по договору №%1 от %2';
					|en = 'under contract No. %1 dated %2'; fa = 'under contract No. %1 dated %2';
					|it = 'по договору №%1 от %2';
					|pl = 'pod kontraktem NR %1 od %2';
					|tr = '%2 itibarıyla %1 numaralı sözleşme kapsamında'"),
				ContractDetails_.Number,
				Format(ContractDetails_.Date, "DLF=DD"));
			
			StructureBase.BasisForPrint = StructureBase.BasisForPrint + NStr("vi = ', nguyên vật việu gia công %1';
																			|ru = ', переработка давальческого сырья %1';
																			|en = ', processing provided materials %1'; fa = ', processing provided materials %1';
																			|it = ', переработка давальческого сырья %1';
																			|pl = ', przetwarzanie surowców dostarczanych przez dostawcę %1';
																			|tr = ', %1 tedarikçi hammaddelerinin işlenmesi'");
			StructureBase.BasisForPrint = StrTemplate(StructureBase.BasisForPrint, ContractDetailsText);
			
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
		"SELECT ALLOWED
		|	CounterpartyContracts.NameForPrinting AS Basis,
		|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
		|	CounterpartyContracts.Number AS BaseDocumentNumber
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Ref
		|");
		Query.SetParameter("Ref", Object.Contract);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			StructureBase.BasisForPrint = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		If ValueIsFilled(Object.Contract) Then
			
			ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "Date, Number");
			ContractDetailsText = StrTemplate(NStr("vi = 'theo hợp đồng số %1 ngày %2';
													|ru = 'по договору №%1 от %2';
													|en = 'under contract No. %1 dated %2'; fa = 'under contract No. %1 dated %2';
													|it = 'по договору №%1 от %2';
													|pl = 'pod kontraktem NR %1 od %2';
													|tr = '%2 itibarıyla %1 numaralı sözleşme kapsamında'"), ContractDetails_.Number, Format(ContractDetails_.Date, "DLF=DD"));
			
			StructureBase.ReferenceDocumentDateForPrintForms  = ContractDetails_.Date;
			StructureBase.BaseDocumentNumber = ContractDetails_.Number;
			
		Else
			ContractDetailsText = "";
		EndIf;
		
		StructureBase.BasisForPrint = TrimAll(StrTemplate(NStr("vi = 'Trả lại nguyên liệu gia công %1';
																|ru = 'Возврат давальческого сырья %1';
																|en = 'Provided materials return %1'; fa = 'Provided materials return %1';
																|it = 'Возврат давальческого сырья %1';
																|pl = 'Zwrot materiałów w przerobie zewnętrznym %1';
																|tr = 'Sağlayıcı hammaddelerinin iadesi %1'"), ContractDetailsText));
		
	Else
		If ValueIsFilled(Object.Basis)
			And Documents.AllRefsType().Types().Find(TypeOf(Object.Basis)) <> Undefined Then
			
			AttributesStructure1 = Common.ObjectAttributesValues(Object.Basis, "Number, Date");
			
			StructureBase.BaseDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(AttributesStructure1.Number);
			StructureBase.ReferenceDocumentDateForPrintForms = AttributesStructure1.Date;
			
			StructureBase.BasisForPrint = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 số %2 ngày %3';
					|ru = '%1 № %2 от %3';
					|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
					|it = '%1 № %2 dal %3';
					|pl = '%1 nr %2 z dnia %3.';
					|tr = '%3 itibarıyla %2 numaralı %1'"),
				Object.Basis.Metadata().Synonym,
				StructureBase.BaseDocumentNumber,
				Format(StructureBase.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
			
			ReceiptDocuments = Object.Goods.Unload(, "DocumentInflow").UnloadColumn("DocumentInflow");
			
			Query = New Query(
			"SELECT ALLOWED
			|	GoodsReceiptForStorage.IncomingDocumentNumber AS IncomingDocumentNumber,
			|	GoodsReceiptForStorage.IncomingDocumentDate AS IncomingDocumentDate,
			|	GoodsReceiptForStorage.Number AS Number,
			|	GoodsReceiptForStorage.Date AS Date,
			|	&Synonym AS Synonym
			|FROM
			|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
			|WHERE
			|	GoodsReceiptForStorage.Ref IN (&ReceiptDocuments)");
			
			Query.SetParameter("ReceiptDocuments", ReceiptDocuments);
			Query.SetParameter("Synonym", NStr("vi = 'Nhập hàng vào kho';
												|ru = 'Приемка товаров на хранение';
												|en = 'VMI procurement'; fa = 'تدارکات VMI';
												|it = 'Accettazione delle merci per il deposito';
												|pl = 'Przyjęcie towarów do przechowania';
												|tr = 'Malların depoya girişi'"));
			Selection = Query.Execute().Select();
			
			TextOnReceipts = "";
			OneFoundation = Selection.Count() = 1;
			While Selection.Next() Do
				
				If ValueIsFilled(Selection.IncomingDocumentNumber) And ValueIsFilled(Selection.IncomingDocumentDate) Then
					
					InformationAboutAdmission =
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1 số %2 ngày %3';
								|ru = '%1 № %2 от %3';
								|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
								|it = '%1 № %2 dal %3';
								|pl = '%1 nr %2 z dnia %3.';
								|tr = '%3 itibarıyla %2 numaralı %1'"),
							Selection.Synonym,
							Selection.IncomingDocumentNumber,
							Format(Selection.IncomingDocumentDate, "DLF=DD"));
					
					ReferenceDocumentDateForCertificate = Selection.IncomingDocumentDate;
					NumberOfBaseDocument = Selection.IncomingDocumentNumber;
					
				Else
					
					InformationAboutAdmission = TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
					ReferenceDocumentDateForCertificate = Selection.Date;
					NumberOfBaseDocument = Selection.Number;
					
				EndIf;
				
				TextOnReceipts = TextOnReceipts + ", " + InformationAboutAdmission;
				
			EndDo;
			
			StructureBase.BasisForPrint = TrimAll(Mid(TextOnReceipts, 3));
			StructureBase.ReferenceDocumentDateForPrintForms = ?(OneFoundation, ReferenceDocumentDateForCertificate, "");
			StructureBase.BaseDocumentNumber = ?(OneFoundation, ObjectsPrefixesClientServer.NumberForPrinting(NumberOfBaseDocument), "");
			
		EndIf;
	EndIf;
	Return StructureBase;
	
EndFunction

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.GoodsShipmentFromStorage - The object of the document for which you want to get the text of the base.
//
// Returns:
//  Structure - See BaseStructure - structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object);
	Return BaseStructure;
	
EndFunction

// The function returns the name of the document Manager for shipping goods from storage.
//
// Returns:
//  String - the name of the manager of the document of shipment of goods from storage.
//
Function FullObjectName()
	
	Return "Document.GoodsShipmentFromStorage";
	
EndFunction

Function GenerateShipmentTable()
	
	GoodsForShipment = New ValueTable;
	GoodsForShipment.Columns.Add("SalesOrder", New TypeDescription("DocumentRef.SalesOrder"));
	GoodsForShipment.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	GoodsForShipment.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	GoodsForShipment.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	GoodsForShipment.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	GoodsForShipment.Columns.Add("LineNumberInDocument", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	GoodsForShipment.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	GoodsForShipment.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	GoodsForShipment.Columns.Add("QuantityInOrder", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
	GoodsForShipment.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
	GoodsForShipment.Columns.Add("DocumentQuantity", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("DocumentAmount", TMCommonUse.MoneyFieldTypeDescription());
	GoodsForShipment.Columns.Add("ZoomRatio", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	GoodsForShipment.Columns.Add("NumberOfPackages", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("NumberInReport", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("CountBalance", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("NumberInProgress", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("QuantityIsCollected", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("QuantityInInvoice", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("QuantityIsSelected", TMCommonUse.DescriptionOfQuantitativeFieldType());
	GoodsForShipment.Columns.Add("Check", New TypeDescription("Boolean"));
	GoodsForShipment.Columns.Add("AdvancedWarehousingOnShipment", New TypeDescription("Boolean"));
	
	Return GoodsForShipment;
	
EndFunction

// Returns the table of product balances for shipment
//
// Parameters:
//  DataParameters - Structure - The structure contains:
//   * Partner - CatalogRef.Partners - Partner.
//   * Counterparty - CatalogRef.Counterparties - Contractor.
//   * Organization - CatalogRef.Companies - Organization.
//   * Warehouse - CatalogRef
//   * Contract - CatalogRef
//   * SalesOrders - Array of DocumentRef.SalesOrder
//   * GoodsShipment - ValueTable - products of the document.
//   * DocumentShipments - DocumentRef.GoodsShipmentFromStorage - text the shipment document.
//   * ByOrder - Boolean - The shipment is made on the customer's order.
//
// Returns:
//  ValueTable - See GenerateShipmentTable - the table of shipment of the goods from storage.
//
Function GetTableOfShipmentBalances(DataParameters) Export
	
	Query = New Query;
	Query.SetParameter("RecordType", AccumulationRecordType.Expense);
	Query.SetParameter("EmptyAssignment",      Catalogs.Assignments.EmptyRef());
	Query.SetParameter("Contract", DataParameters.Contract);
	Query.SetParameter("Counterparty", DataParameters.Counterparty);
	Query.SetParameter("Organization", DataParameters.Organization);
	Query.SetParameter("Partner", DataParameters.Partner);
	Query.SetParameter("Recorder", DataParameters.DocumentShipments);
	Query.SetParameter("ImplementationWarehouse", DataParameters.Warehouse);
	Query.SetParameter("ItemsType", Enums.ItemsTypes.OwnGoods);
	
	If ValueIsFilled(DataParameters.GoodsShipment) Then
		Query.SetParameter("GoodsShipment",   DataParameters.GoodsShipment);
	Else
		GoodsSales_ = New ValueTable;
		GoodsSales_.Columns.Add("SalesOrder", New TypeDescription("DocumentRef.SalesOrder"));
		GoodsSales_.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		GoodsSales_.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		GoodsSales_.Columns.Add("RowCode", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		GoodsSales_.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
		GoodsSales_.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		GoodsSales_.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		GoodsSales_.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		GoodsSales_.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
		GoodsSales_.Columns.Add("QuantityInOrder", TMCommonUse.DescriptionOfQuantitativeFieldType());
		GoodsSales_.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		GoodsSales_.Columns.Add("ConnectionKey", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		
		Query.SetParameter("GoodsShipment", GoodsSales_);
	EndIf;
	
	GoodsForShipment = GenerateShipmentTable();
	
	If DataParameters.ByOrder Then
		Query.SetParameter("SelectByOrder_", DataParameters.SalesOrders.Count() > 0);
		Query.SetParameter("AnArrayOfOrders", DataParameters.SalesOrders);
	Else
		Query.SetParameter("SelectByOrder_", False);
		Query.SetParameter("AnArrayOfOrders", New Array());
	EndIf;
	
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("PackageDepositIsRequired", False);
	
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
		
	FillInRequestTextForOrder(Query);
	QueryResult = Query.ExecuteBatch();
	BalanceData = QueryResult[6].Unload();
	OrderAndShipmentData = QueryResult[7].Unload();
	DataOnCompanyBalances = QueryResult[14].Unload();
	ReportData_ = QueryResult[13].Unload();
	PriceData = QueryResult[15].Unload();
	OrderData_1 = QueryResult[18].Unload();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	
	For Each PriceLine In PriceData Do
		
		FilterByProduct = New Structure();
		FilterByProduct.Insert("Products", PriceLine.Products);
		FilterByProduct.Insert("Characteristic", PriceLine.Characteristic);
		FilterByProduct.Insert("Purpose", PriceLine.Purpose);
		FilterByProduct.Insert("Price", 0);
		RowsByRemainder = DataOnCompanyBalances.FindRows(FilterByProduct);
		For Each StringBalance In RowsByRemainder Do
			If StringBalance.CountBalance > PriceLine.CountBalance 
				And PriceLine.CountBalance > 0 Then
				NewRowOfBalances = BalanceData.Add();
				FillPropertyValues(NewRowOfBalances, StringBalance);
				NewRowOfBalances.CountBalance = StringBalance.CountBalance - PriceLine.CountBalance;
				StringBalance.Price = PriceLine.Price;
				StringBalance.Sum = StringBalance.Price * PriceLine.CountBalance;
				PriceLine.CountBalance = 0;
			Else 
				StringBalance.Price = PriceLine.Price;
				StringBalance.Sum = StringBalance.Price * PriceLine.CountBalance;
				PriceLine.CountBalance = PriceLine.CountBalance-StringBalance.CountBalance;
			EndIf;
		EndDo;
		
	EndDo;

	RowsToProcess = New Array;
	For Each LineByOrderAndShipment In OrderAndShipmentData Do
		FilterByProduct = GetSearchStructure();
		FilterByProduct.Insert("Products", LineByOrderAndShipment.Products);
		FilterByProduct.Insert("Characteristic", LineByOrderAndShipment.Characteristic);
		FilterByProduct.Insert("Purpose", LineByOrderAndShipment.Purpose);
		FilterByProduct.Insert("Series", LineByOrderAndShipment.Series);
		FilterByProduct.Insert("Warehouse", LineByOrderAndShipment.Warehouse);
		
		ProductSelectionWithoutSeries = GetSearchStructure(False);
		FillPropertyValues(ProductSelectionWithoutSeries, FilterByProduct);
		
		RemainderLines = BalanceData.FindRows(FilterByProduct);
		
		NewShipmentLine = GoodsForShipment.Add();
		FillPropertyValues(NewShipmentLine, LineByOrderAndShipment, "Products, Characteristic, Series, Purpose, SalesOrder, Price,
			|Package, ZoomRatio, QuantityInInvoice, Warehouse, AdvancedWarehousingOnShipment, Sum");
		NewShipmentLine.QuantityInOrder = 0;
		
		For Each RemainderLine In RemainderLines Do
			If RemainderLine.CountBalance = 0 Then
				Continue;
			EndIf;
			CountBalance = Min(RemainderLine.CountBalance, LineByOrderAndShipment.QuantityInOrder);
			If CountBalance > 0 Then
				NewShipmentLine.QuantityInOrder = CountBalance;
				RemainderLine.CountBalance = RemainderLine.CountBalance - CountBalance;
			EndIf;
		EndDo;
		
		RowsWithBalancesByOrganization = DataOnCompanyBalances.FindRows(FilterByProduct);
		If RowsWithBalancesByOrganization.Count() = 0 Then
			RowsWithBalancesByOrganization = DataOnCompanyBalances.FindRows(ProductSelectionWithoutSeries);
		EndIf;
		For Each BusinessBalanceLine In RowsWithBalancesByOrganization Do
			If BusinessBalanceLine.CountBalance = 0 Then
				Continue;
			EndIf;
			If ValueIsFilled(LineByOrderAndShipment.SalesOrder) Then
				CountBalance = Min(BusinessBalanceLine.CountBalance, NewShipmentLine.QuantityInOrder);
			Else
				CountBalance = BusinessBalanceLine.CountBalance;
			EndIf;
			NewShipmentLine.CountBalance = CountBalance;
			NewShipmentLine.Count = CountBalance;
			RowsToProcess.Add(NewShipmentLine);
			If BusinessBalanceLine.CountBalance = LineByOrderAndShipment.QuantityInOrder Then
				NewShipmentLine.Sum = BusinessBalanceLine.Sum;
			Else
				ConversionFactor_ = ?(LineByOrderAndShipment.ZoomRatio > 0, LineByOrderAndShipment.ZoomRatio, 1);
				NewShipmentLine.Price = ?(ValueIsFilled(NewShipmentLine.Price), NewShipmentLine.Price, BusinessBalanceLine.Price * ConversionFactor_);
				NewShipmentLine.Sum = NewShipmentLine.Price * (CountBalance / ConversionFactor_);
			EndIf;
			BusinessBalanceLine.CountBalance = BusinessBalanceLine.CountBalance - CountBalance;
			
		EndDo;
		
		If NewShipmentLine.QuantityInInvoice = 0
			And NewShipmentLine.QuantityInOrder = 0 Then
			GoodsForShipment.Delete(NewShipmentLine);
			Continue;
		EndIf;
		
		If NewShipmentLine.AdvancedWarehousingOnShipment Then
			OrderLines_1 = OrderData_1.FindRows(FilterByProduct);
			For Each OrderLine_1 In OrderLines_1 Do
				If OrderLine_1.NumberInProgress <> 0 Then
					NumberInProgress = Min((OrderLine_1.NumberInProgress/LineByOrderAndShipment.ZoomRatio)*LineByOrderAndShipment.ZoomRatio, NewShipmentLine.CountBalance, NewShipmentLine.QuantityInOrder);
					NewShipmentLine.NumberInProgress = NumberInProgress;
					OrderLine_1.NumberInProgress = OrderLine_1.NumberInProgress - NumberInProgress;
				EndIf;
				If OrderLine_1.Count <> 0 Then
					QuantityIsCollected = Min((OrderLine_1.Count/LineByOrderAndShipment.ZoomRatio)*LineByOrderAndShipment.ZoomRatio, NewShipmentLine.CountBalance, NewShipmentLine.QuantityInOrder);
					NewShipmentLine.QuantityIsCollected = QuantityIsCollected;
					OrderLine_1.Count = OrderLine_1.Count - QuantityIsCollected;
				EndIf;
			EndDo;
		EndIf;

		FilterByProduct = New Structure();
		FilterByProduct.Insert("Products", LineByOrderAndShipment.Products);
		FilterByProduct.Insert("Characteristic", LineByOrderAndShipment.Characteristic);
		FilterByProduct.Insert("Purpose", LineByOrderAndShipment.Purpose);
		ReportLines = ReportData_.FindRows(FilterByProduct);
		For Each ReportRow In ReportLines Do
			If ReportRow.NumberInReport <= 0
				Or NewShipmentLine.NumberInReport > 0 Then
				Continue;
			EndIf;
			NumberInReport = Min(NewShipmentLine.CountBalance, NewShipmentLine.QuantityInOrder, Int(ReportRow.NumberInReport/LineByOrderAndShipment.ZoomRatio)*LineByOrderAndShipment.ZoomRatio);
			NewShipmentLine.NumberInReport = NumberInReport;
			ReportRow.NumberInReport = ReportRow.NumberInReport - NumberInReport;
		EndDo;
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		GoodsForShipment,
		CachedValues);

	For Each StringBalance In DataOnCompanyBalances Do
		
		If StringBalance.CountBalance = 0 Then
			Continue;
		EndIf;
		
		FilterByProduct = New Structure();
		FilterByProduct.Insert("Products", StringBalance.Products);
		FilterByProduct.Insert("Characteristic", StringBalance.Characteristic);
		FilterByProduct.Insert("Purpose", StringBalance.Purpose);
		FilterByProduct.Insert("Warehouse", StringBalance.Warehouse);
		If ValueIsFilled(StringBalance.Series) Then
			FilterByProduct.Insert("Series", StringBalance.Series);
		EndIf;
		ProductLines_2 = GoodsForShipment.FindRows(FilterByProduct);
		
		FilterByProduct = New Structure();
		FilterByProduct.Insert("Products", StringBalance.Products);
		FilterByProduct.Insert("Characteristic", StringBalance.Characteristic);
		FilterByProduct.Insert("Purpose", StringBalance.Purpose);
		ReportLines = ReportData_.FindRows(FilterByProduct);
		
		NumberInReport = 0;
		ReportRow = ?(ReportLines.Count() = 1, ReportLines[0], Undefined);
		ShipByReport =  ?(Not ReportRow = Undefined, ReportRow.NumberInReport, 0);
		
		If ProductLines_2.Count() = 0
			And Not DataParameters.ByOrder Then
			RowOfProduct = GoodsForShipment.Add();
			FillPropertyValues(RowOfProduct, StringBalance);
			RowOfProduct.NumberInReport = ShipByReport; 
			RowOfProduct.ZoomRatio = 1;
		Else
			CurrentRowNumber1 = 1;
			For Each RowOfProduct In ProductLines_2 Do
				If CurrentRowNumber1 < ProductLines_2.Count()
					And RowOfProduct.QuantityInOrder < StringBalance.CountBalance Then
					RowOfProduct.CountBalance = RowOfProduct.QuantityInOrder;
					StringBalance.CountBalance = StringBalance.CountBalance - RowOfProduct.QuantityInOrder;
				Else
					RowOfProduct.CountBalance = StringBalance.CountBalance;
				EndIf;
				If ShipByReport > 0 Then
					If CurrentRowNumber1 < ProductLines_2.Count()
						And RowOfProduct.CountBalance < ShipByReport Then
							RowOfProduct.NumberInReport = RowOfProduct.CountBalance;
							ShipByReport = ShipByReport - RowOfProduct.CountBalance;
					Else
						RowOfProduct.NumberInReport = ShipByReport;
						ShipByReport = 0;
					EndIf;
				EndIf;
				CurrentRowNumber1 = CurrentRowNumber1 + 1;
			EndDo;
		EndIf;
		
	EndDo;
	
	GoodsForShipment.Sort("SalesOrder, Products, Characteristic, Series, Purpose, Package, Warehouse");
	
	Return GoodsForShipment;
		
EndFunction

Procedure FillInRequestTextForOrder(Query)
	
	Query.Text =
	"SELECT
	|	ShipmentOfGoodsFromStorageGoods.RowCode AS RowCode,
	|	CAST(ShipmentOfGoodsFromStorageGoods.Products AS Catalog.Products) AS Products,
	|	ShipmentOfGoodsFromStorageGoods.Characteristic AS Characteristic,
	|	ShipmentOfGoodsFromStorageGoods.Count AS Count,
	|	ShipmentOfGoodsFromStorageGoods.Series AS Series,
	|	CAST(ShipmentOfGoodsFromStorageGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(ShipmentOfGoodsFromStorageGoods.Purpose AS Catalog.Assignments) AS Purpose,
	|	ShipmentOfGoodsFromStorageGoods.SalesOrder AS SalesOrder,
	|	ShipmentOfGoodsFromStorageGoods.Price AS Price,
	|	ShipmentOfGoodsFromStorageGoods.Warehouse AS Warehouse,
	|	ShipmentOfGoodsFromStorageGoods.Sum AS Sum
	|INTO TTSalesProducts
	|FROM
	|	&GoodsShipment AS ShipmentOfGoodsFromStorageGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSalesProducts.Products AS Products,
	|	TTSalesProducts.Characteristic AS Characteristic,
	|	SUM(TTSalesProducts.Count) AS Count,
	|	TTSalesProducts.Series AS Series,
	|	TTSalesProducts.Package AS Package,
	|	TTSalesProducts.SalesOrder AS SalesOrder,
	|	&QueryTextPackagingFactor4 AS ZoomRatio,
	|	TTSalesProducts.Purpose AS Purpose,
	|	TTSalesProducts.Price AS Price,
	|	TTSalesProducts.Warehouse AS Warehouse,
	|	TTSalesProducts.Sum AS Sum
	|INTO TTGoodsSalesOnOrderPackaging
	|FROM
	|	TTSalesProducts AS TTSalesProducts
	|WHERE
	|	TTSalesProducts.Products.ItemsType = &ItemsType
	|
	|GROUP BY
	|	TTSalesProducts.Characteristic,
	|	TTSalesProducts.Series,
	|	TTSalesProducts.Package,
	|	TTSalesProducts.SalesOrder,
	|	TTSalesProducts.Purpose,
	|	TTSalesProducts.Products,
	|	TTSalesProducts.Price,
	|	TTSalesProducts.Warehouse,
	|	TTSalesProducts.Sum
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderingProducts.Ref AS Ref,
	|	OrderingProducts.Warehouse AS Warehouse,
	|	OrderingProducts.Series AS Series,
	|	SUM(OrderingProducts.Count) AS QuantityInOrder,
	|	AVG(OrderingProducts.Price) AS Price,
	|	SUM(OrderingProducts.Sum) AS Sum,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	OrderingProducts.Characteristic AS Characteristic,
	|	OrderingProducts.Products AS Products,
	|	&QueryTextPackagingFactor2 AS ZoomRatio,
	|	OrderingProducts.Package AS Package
	|INTO GoodsAndPackaging
	|FROM
	|	Document.SalesOrder.Goods AS OrderingProducts
	|WHERE
	|	(&SelectByOrder_
	|				AND OrderingProducts.Ref IN (&AnArrayOfOrders)
	|			OR NOT &SelectByOrder_
	|				AND (OrderingProducts.Ref.Partner = &Partner
	|					AND OrderingProducts.Ref.Counterparty = &Counterparty
	|					AND OrderingProducts.Ref.Contract = &Contract
	|					AND OrderingProducts.Ref.Organization = &Organization
	|					AND CASE
	|						WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|							THEN OrderingProducts.Ref.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|									OR OrderingProducts.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|						ELSE OrderingProducts.Ref.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|					END
	|					AND &UseAdvancedFeaturesOfSalesOrder))
	|
	|GROUP BY
	|	OrderingProducts.Ref,
	|	OrderingProducts.Series,
	|	OrderingProducts.Products.ItemsType,
	|	OrderingProducts.Characteristic,
	|	OrderingProducts.Products,
	|	OrderingProducts.Package,
	|	OrderingProducts.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderingProducts.Ref AS Ref,
	|	OrderingProducts.Ref.Warehouse AS Warehouse,
	|	OrderingProducts.Series AS Series,
	|	SUM(OrderingProducts.QuantityInOrder) AS QuantityInOrder,
	|	AVG(OrderingProducts.Price / OrderingProducts.ZoomRatio) AS Price,
	|	SUM(OrderingProducts.Sum) AS Sum,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	OrderingProducts.Characteristic AS Characteristic,
	|	OrderingProducts.Products AS Products
	|INTO GoodsFromOrder
	|FROM
	|	GoodsAndPackaging AS OrderingProducts
	|
	|GROUP BY
	|	OrderingProducts.Ref,
	|	OrderingProducts.Ref.Warehouse,
	|	OrderingProducts.Series,
	|	OrderingProducts.Products.ItemsType,
	|	OrderingProducts.Characteristic,
	|	OrderingProducts.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSalesProducts.Products AS Products,
	|	TTSalesProducts.Characteristic AS Characteristic,
	|	SUM(TTSalesProducts.Count) AS Count,
	|	TTSalesProducts.Series AS Series,
	|	TTSalesProducts.SalesOrder AS SalesOrder,
	|	TTSalesProducts.Purpose AS Purpose
	|INTO TTGoodsSalesByOrder
	|FROM
	|	TTSalesProducts AS TTSalesProducts
	|
	|GROUP BY
	|	TTSalesProducts.Products,
	|	TTSalesProducts.Characteristic,
	|	TTSalesProducts.Series,
	|	TTSalesProducts.SalesOrder,
	|	TTSalesProducts.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.Warehouse AS Warehouse,
	|	OrdersTable.Series AS Series,
	|	SUM(OrdersTable.ToRegister) AS Count,
	|	SUM(OrdersTable.Sum) AS Sum
	|INTO TableBalance
	|FROM
	|	(SELECT
	|		CAST(ShippingOrdersTurnover.ReferenceOrder AS Document.SalesOrder) AS SalesOrder,
	|		ShippingOrdersTurnover.Products AS Products,
	|		ShippingOrdersTurnover.Characteristic AS Characteristic,
	|		ShippingOrdersTurnover.Warehouse AS Warehouse,
	|		ShippingOrdersTurnover.Series AS Series,
	|		(ShippingOrdersTurnover.ForRegistrationQuantityTurnover
	|			- ShippingOrdersTurnover.IssuedQuantityTurnover) AS ToRegister,
	|		(ShippingOrdersTurnover.AmountToBeProcessedTurnover
	|			- ShippingOrdersTurnover.IssuedAmountTurnover) AS Sum
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS ShippingOrdersTurnover
	|	WHERE
	|		(ShippingOrdersTurnover.ForRegistrationQuantityTurnover
	|			- ShippingOrdersTurnover.IssuedQuantityTurnover) <> 0
	|		OR (ShippingOrdersTurnover.AmountToBeProcessedTurnover
	|			- ShippingOrdersTurnover.IssuedAmountTurnover) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CAST(OrdersRegisterRecords.ReferenceOrder AS Document.SalesOrder),
	|		OrdersRegisterRecords.Products,
	|		OrdersRegisterRecords.Characteristic,
	|		OrdersRegisterRecords.Warehouse,
	|		OrdersRegisterRecords.Series,
	|		-OrdersRegisterRecords.Count,
	|		-OrdersRegisterRecords.Sum
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN
	|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1))
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder REFS Document.SalesOrder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerOrderGoods.Ref,
	|		CustomerOrderGoods.Products,
	|		CustomerOrderGoods.Characteristic,
	|		CustomerOrderGoods.Warehouse,
	|		CustomerOrderGoods.Series,
	|		CustomerOrderGoods.Count,
	|		CustomerOrderGoods.Sum
	|	FROM
	|		Document.SalesOrder.Goods AS CustomerOrderGoods
	|	WHERE
	|		CASE
	|				WHEN &SelectByOrder_
	|					THEN CustomerOrderGoods.Ref IN (&AnArrayOfOrders)
	|				ELSE CustomerOrderGoods.Ref.Partner = &Partner
	|						AND CustomerOrderGoods.Ref.Counterparty = &Counterparty
	|						AND CustomerOrderGoods.Ref.Contract = &Contract
	|						AND CustomerOrderGoods.Ref.Organization = &Organization
	|			END
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND NOT CustomerOrderGoods.Ref.DeletionMark
	|		AND CASE
	|				WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|					THEN CustomerOrderGoods.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|							OR CustomerOrderGoods.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				ELSE CustomerOrderGoods.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|			END
	|		AND NOT &UseAdvancedFeaturesOfSalesOrder) AS OrdersTable
	|WHERE
	|	OrdersTable.Products.ItemsType = &ItemsType
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.Warehouse,
	|	OrdersTable.Series
	|
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.SalesOrder AS SalesOrder,
	|	TableBalance.Products AS Products,
	|	TableBalance.SalesOrder.Purpose AS Purpose,
	|	SUM(TableBalance.Count) AS CountBalance,
	|	TableBalance.Characteristic AS Characteristic,
	|	TableBalance.Warehouse AS Warehouse,
	|	TableBalance.Series AS Series,
	|	SUM(TableBalance.Sum) AS Sum
	|
	|FROM
	|	TableBalance AS TableBalance
	|
	|GROUP BY
	|	TableBalance.SalesOrder,
	|	TableBalance.Products,
	|	TableBalance.SalesOrder.Purpose,
	|	TableBalance.Characteristic,
	|	TableBalance.Warehouse,
	|	TableBalance.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Package AS Package,
	|	NestedQuery.SalesOrder AS SalesOrder,
	|	ISNULL(NestedQuery.ZoomRatio, 1) AS ZoomRatio,
	|	NestedQuery.Purpose AS Purpose,
	|	SUM(NestedQuery.QuantityInOrder) AS QuantityInOrder,
	|	MAX(NestedQuery.Price) AS Price,
	|	SUM(NestedQuery.QuantityInInvoice) AS QuantityInInvoice,
	|	NestedQuery.Warehouse AS Warehouse,
	|	CASE
	|		WHEN NestedQuery.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND NestedQuery.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	SUM(NestedQuery.Sum) AS Sum
	|FROM
	|	(SELECT
	|		TTGoodsSalesOnOrderPackaging.Products AS Products,
	|		TTGoodsSalesOnOrderPackaging.Characteristic AS Characteristic,
	|		TTGoodsSalesOnOrderPackaging.Count AS QuantityInInvoice,
	|		TTGoodsSalesOnOrderPackaging.Series AS Series,
	|		CASE
	|			WHEN TTGoodsSalesOnOrderPackaging.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN TTGoodsSalesOnOrderPackaging.Products.UnitOfMeasure
	|			ELSE TTGoodsSalesOnOrderPackaging.Package
	|		END AS Package,
	|		TTGoodsSalesOnOrderPackaging.SalesOrder AS SalesOrder,
	|		TTGoodsSalesOnOrderPackaging.ZoomRatio AS ZoomRatio,
	|		TTGoodsSalesOnOrderPackaging.Purpose AS Purpose,
	|		0 AS QuantityInOrder,
	|		0 AS Price,
	|		TTGoodsSalesOnOrderPackaging.Warehouse AS Warehouse,
	|		0 AS Sum
	|	FROM
	|		TTGoodsSalesOnOrderPackaging AS TTGoodsSalesOnOrderPackaging
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsAndPackaging.Products,
	|		GoodsAndPackaging.Characteristic,
	|		0,
	|		GoodsAndPackaging.Series,
	|		CASE
	|			WHEN GoodsAndPackaging.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsAndPackaging.Products.UnitOfMeasure
	|			ELSE GoodsAndPackaging.Package
	|		END,
	|		GoodsAndPackaging.Ref,
	|		GoodsAndPackaging.ZoomRatio,
	|		GoodsAndPackaging.Ref.Purpose,
	|		GoodsAndPackaging.QuantityInOrder,
	|		GoodsAndPackaging.Price,
	|		GoodsAndPackaging.Warehouse,
	|		GoodsAndPackaging.Sum
	|	FROM
	|		GoodsAndPackaging AS GoodsAndPackaging) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Series,
	|	NestedQuery.Package,
	|	NestedQuery.SalesOrder,
	|	NestedQuery.Purpose,
	|	ISNULL(NestedQuery.ZoomRatio, 1),
	|	NestedQuery.Warehouse,
	|	CASE
	|		WHEN NestedQuery.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND NestedQuery.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryLocationAttributeKeys.Ref AS Ref,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.StorageLocation AS StorageLocation,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose
	|INTO TableOfProductAnalysts
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON InventoryLocationAttributeKeys.Purpose = Assignments.Ref
	|WHERE
	|	Assignments.Partner = &Partner
	|	AND Assignments.Contract = &Contract
	|	AND (Assignments.OrderDocument IN (&AnArrayOfOrders)
	|			OR Assignments.OrderDocument = VALUE(Document.SalesOrder.EmptyRef)
	|			OR NOT &SelectByOrder_)
	|	AND Assignments.Ref <> &EmptyAssignment
	|	AND CASE
	|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|				THEN InventoryLocationAttributeKeys.StorageLocation IN HIERARCHY (&ImplementationWarehouse)
	|						OR InventoryLocationAttributeKeys.StorageLocation = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE InventoryLocationAttributeKeys.StorageLocation IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|		END
	|	AND InventoryLocationAttributeKeys.Products.ItemsType = &ItemsType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Products AS Products,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Characteristic AS Characteristic,
	|	SUM(GoodsAndServicesToRegisterPurchasingReportsToConsignor.Count) AS Count,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Purpose AS Purpose,
	|	Assignments.OrderDocument AS SalesOrder
	|INTO ReportData_
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS GoodsAndServicesToRegisterPurchasingReportsToConsignor
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON GoodsAndServicesToRegisterPurchasingReportsToConsignor.Purpose = Assignments.Ref
	|WHERE
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Purpose.Contract = &Contract
	|	AND GoodsAndServicesToRegisterPurchasingReportsToConsignor.Purpose.Partner = &Partner
	|	AND (Assignments.OrderDocument IN (&AnArrayOfOrders)
	|			OR NOT &SelectByOrder_
	|			OR Assignments.OrderDocument = VALUE(Document.SalesOrder.EmptyRef))
	|	AND Assignments.Ref <> &EmptyAssignment
	|	AND GoodsAndServicesToRegisterPurchasingReportsToConsignor.Organization = &Organization
	|	AND GoodsAndServicesToRegisterPurchasingReportsToConsignor.RecordType = &RecordType
	|	AND GoodsAndServicesToRegisterPurchasingReportsToConsignor.Products.ItemsType = &ItemsType
	|
	|GROUP BY
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Products,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Characteristic,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignor.Purpose,
	|	Assignments.OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|INTO InventoryTable
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.GoodsOwner = &Partner
	|	AND InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.Contract = &Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CompanyGoods.Count
	|			ELSE -CompanyGoods.Count
	|		END) AS CountBalance,
	|	TableOfProductAnalysts.Products AS Products,
	|	TableOfProductAnalysts.Characteristic AS Characteristic,
	|	TableOfProductAnalysts.Series AS Series,
	|	TableOfProductAnalysts.StorageLocation AS Warehouse,
	|	TableOfProductAnalysts.Purpose AS Purpose,
	|	TableOfProductAnalysts.Purpose.OrderDocument AS SalesOrder,
	|	SUM(CASE
	|			WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 0
	|			ELSE CompanyGoods.Count
	|		END) AS CountExpense
	|INTO OrganizationSGoodsBalancesExpenses
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|		INNER JOIN InventoryTable AS InventoryTable
	|		ON CompanyGoods.InventoryOwnerAttribute = InventoryTable.InventoryOwnerAttribute
	|		INNER JOIN TableOfProductAnalysts AS TableOfProductAnalysts
	|		ON CompanyGoods.ItemsLocationAttributes = TableOfProductAnalysts.Ref
	|WHERE
	|	CompanyGoods.Recorder <> &Recorder
	|	AND CompanyGoods.Active
	|
	|GROUP BY
	|	TableOfProductAnalysts.Products,
	|	TableOfProductAnalysts.Characteristic,
	|	TableOfProductAnalysts.Series,
	|	TableOfProductAnalysts.StorageLocation,
	|	TableOfProductAnalysts.Purpose,
	|	TableOfProductAnalysts.Purpose.OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrganizationSGoodsBalancesExpenses.Products AS Products,
	|	OrganizationSGoodsBalancesExpenses.Characteristic AS Characteristic,
	|	OrganizationSGoodsBalancesExpenses.Purpose AS Purpose,
	|	OrganizationSGoodsBalancesExpenses.SalesOrder AS SalesOrder,
	|	SUM(OrganizationSGoodsBalancesExpenses.CountExpense) AS CountExpense
	|INTO OrganizationSProductsWithoutSerialNumbers
	|FROM
	|	OrganizationSGoodsBalancesExpenses AS OrganizationSGoodsBalancesExpenses
	|
	|GROUP BY
	|	OrganizationSGoodsBalancesExpenses.Products,
	|	OrganizationSGoodsBalancesExpenses.Characteristic,
	|	OrganizationSGoodsBalancesExpenses.Purpose,
	|	OrganizationSGoodsBalancesExpenses.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportData_.Products AS Products,
	|	ReportData_.Characteristic AS Characteristic,
	|	ReportData_.Purpose AS Purpose,
	|	ReportData_.SalesOrder AS SalesOrder,
	|	ReportData_.Count - OrganizationSProductsWithoutSerialNumbers.CountExpense AS NumberInReport
	|FROM
	|	ReportData_ AS ReportData_
	|		INNER JOIN OrganizationSProductsWithoutSerialNumbers AS OrganizationSProductsWithoutSerialNumbers
	|		ON ReportData_.Products = OrganizationSProductsWithoutSerialNumbers.Products
	|			AND ReportData_.Characteristic = OrganizationSProductsWithoutSerialNumbers.Characteristic
	|			AND ReportData_.Purpose = OrganizationSProductsWithoutSerialNumbers.Purpose
	|			AND ReportData_.SalesOrder = OrganizationSProductsWithoutSerialNumbers.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrganizationSGoodsBalancesExpenses.CountBalance AS CountBalance,
	|	OrganizationSGoodsBalancesExpenses.Products AS Products,
	|	OrganizationSGoodsBalancesExpenses.Characteristic AS Characteristic,
	|	OrganizationSGoodsBalancesExpenses.Series AS Series,
	|	OrganizationSGoodsBalancesExpenses.Warehouse AS Warehouse,
	|	OrganizationSGoodsBalancesExpenses.SalesOrder AS SalesOrder,
	|	OrganizationSGoodsBalancesExpenses.Purpose AS Purpose,
	|	OrganizationSGoodsBalancesExpenses.CountExpense AS CountExpense,
	|	CASE
	|		WHEN OrganizationSGoodsBalancesExpenses.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|				AND OrganizationSGoodsBalancesExpenses.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	0 AS Price,
	|	0 AS Sum
	|FROM
	|	OrganizationSGoodsBalancesExpenses AS OrganizationSGoodsBalancesExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchasePrices.Products AS Products,
	|	PurchasePrices.Characteristic AS Characteristic,
	|	PurchasePrices.Purpose AS Purpose,
	|	PurchasePrices.CountBalance AS CountBalance,
	|	PurchasePrices.Price AS Price
	|FROM
	|	(SELECT
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Products AS Products,
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Characteristic AS Characteristic,
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Purpose AS Purpose,
	|		SUM(GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.CountReceipt) AS CountBalance,
	|		CAST(GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.AmountIncludingVATReceipt / GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.CountReceipt AS NUMBER(31, 2)) AS Price
	|	FROM
	|		AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Turnovers(
	|				,
	|				,
	|				,
	|				(Purpose, Products, Characteristic) IN
	|					(SELECT
	|						TableOfProductAnalysts.Purpose,
	|						TableOfProductAnalysts.Products,
	|						TableOfProductAnalysts.Characteristic
	|					FROM
	|						TableOfProductAnalysts)) AS GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers
	|	WHERE
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Organization = &Organization
	|	
	|	GROUP BY
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Products,
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Characteristic,
	|		GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.Purpose,
	|		CAST(GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.AmountIncludingVATReceipt / GoodsAndServicesToRegisterPurchasingReportsToConsignorTurnovers.CountReceipt AS NUMBER(31, 2))
	|	) AS PurchasePrices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOrder.Ref AS Ref
	|INTO ShippingDocuments
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	CASE
	|			WHEN &SelectByOrder_
	|				THEN SalesOrder.Ref IN (&AnArrayOfOrders)
	|						OR SalesOrder.Ref = &Recorder
	|			ELSE SalesOrder.Partner = &Partner
	|					AND SalesOrder.Counterparty = &Counterparty
	|					AND SalesOrder.Contract = &Contract
	|					AND SalesOrder.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|				THEN SalesOrder.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|						OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE SalesOrder.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|					OR CAST(SalesOrder.Warehouse AS Catalog.Warehouses).IsFolder
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	RequestForReturnOfGoodsFromCustomer.Ref
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|WHERE
	|	CASE
	|			WHEN &SelectByOrder_
	|				THEN RequestForReturnOfGoodsFromCustomer.Ref IN (&AnArrayOfOrders)
	|						OR RequestForReturnOfGoodsFromCustomer.Ref = &Recorder
	|			ELSE RequestForReturnOfGoodsFromCustomer.Partner = &Partner
	|					AND RequestForReturnOfGoodsFromCustomer.Counterparty = &Counterparty
	|					AND RequestForReturnOfGoodsFromCustomer.Contract = &Contract
	|					AND RequestForReturnOfGoodsFromCustomer.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|				THEN RequestForReturnOfGoodsFromCustomer.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|						OR RequestForReturnOfGoodsFromCustomer.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE RequestForReturnOfGoodsFromCustomer.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsShipmentFromStorage.Ref
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|WHERE
	|	CASE
	|			WHEN &SelectByOrder_
	|				THEN GoodsShipmentFromStorage.Ref IN (&AnArrayOfOrders)
	|						OR GoodsShipmentFromStorage.Ref = &Recorder
	|			ELSE GoodsShipmentFromStorage.Partner = &Partner
	|					AND GoodsShipmentFromStorage.Counterparty = &Counterparty
	|					AND GoodsShipmentFromStorage.Contract = &Contract
	|					AND GoodsShipmentFromStorage.Organization = &Organization
	|		END
	|	AND GoodsShipmentFromStorage.Ref = &Recorder
	|	AND CASE
	|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|				THEN GoodsShipmentFromStorage.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|						OR GoodsShipmentFromStorage.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE GoodsShipmentFromStorage.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|		END
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOrder.Ref AS Ref
	|INTO CustomerOrders
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	CASE
	|			WHEN &SelectByOrder_
	|				THEN SalesOrder.Ref IN (&AnArrayOfOrders)
	|			ELSE SalesOrder.Partner = &Partner
	|					AND SalesOrder.Counterparty = &Counterparty
	|					AND SalesOrder.Contract = &Contract
	|					AND SalesOrder.Organization = &Organization
	|		END
	|	AND CASE
	|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
	|				THEN SalesOrder.Warehouse IN HIERARCHY (&ImplementationWarehouse)
	|						OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE SalesOrder.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
	|		END
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.Warehouse AS Warehouse,
	|	OrdersTable.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment,
	|	OrdersTable.Series AS Series,
	|	SUM(OrdersTable.NumberInProgress) AS NumberInProgress,
	|	SUM(OrdersTable.Count) AS Count,
	|	OrdersTable.Purpose AS Purpose
	|FROM
	|	(SELECT
	|		GoodsForIssueBalance.DocumentShipments AS SalesOrder,
	|		GoodsForIssueBalance.Products AS Products,
	|		GoodsForIssueBalance.Characteristic AS Characteristic,
	|		GoodsForIssueBalance.Warehouse AS Warehouse,
	|		CASE
	|			WHEN GoodsForIssueBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|					AND GoodsForIssueBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS AdvancedWarehousingOnShipment,
	|		GoodsForIssueBalance.Series AS Series,
	|		GoodsForIssueBalance.AssemblyInProgressReceipt AS NumberInProgress,
	|		GoodsForIssueBalance.ToShipExpense + GoodsForIssueBalance.AssembledReceipt AS Count,
	|		GoodsForIssueBalance.Purpose AS Purpose
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|				,
	|				,
	|				,
	|				,
	|				DocumentShipments IN
	|						(SELECT
	|							ShippingDocuments.Ref
	|						FROM
	|							ShippingDocuments)
	|					AND Products IN
	|						(SELECT
	|							TableOfProductAnalysts.Products
	|						FROM
	|							TableOfProductAnalysts)) AS GoodsForIssueBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersBalance.ReferenceOrder,
	|		OrdersBalance.Products,
	|		OrdersBalance.Characteristic,
	|		OrdersBalance.Warehouse,
	|		CASE
	|			WHEN OrdersBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|					AND OrdersBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		OrdersBalance.Series,
	|		0,
	|		OrdersBalance.IssuedQuantityTurnover,
	|		CAST(OrdersBalance.ReferenceOrder AS Document.SalesOrder).Purpose
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS OrdersBalance
	|	WHERE
	|		OrdersBalance.Recorder <> &Recorder) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.Warehouse,
	|	OrdersTable.AdvancedWarehousingOnShipment,
	|	OrdersTable.Series,
	|	OrdersTable.Purpose
	|
	|HAVING
	|	(SUM(OrdersTable.Count) > 0
	|		OR SUM(OrdersTable.NumberInProgress) > 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProductAnalysts.Ref AS Ref,
	|	TableOfProductAnalysts.Products AS Products,
	|	TableOfProductAnalysts.Characteristic AS Characteristic,
	|	TableOfProductAnalysts.Series AS Series,
	|	TableOfProductAnalysts.StorageLocation AS StorageLocation,
	|	TableOfProductAnalysts.Purpose AS Purpose
	|FROM
	|	TableOfProductAnalysts AS TableOfProductAnalysts";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|				WHEN &SelectByOrder_
		|					THEN ReferenceOrder IN (&AnArrayOfOrders)
		|				ELSE CAST(ReferenceOrder AS Document.SalesOrder).Partner = &Partner
		|					AND CAST(ReferenceOrder AS Document.SalesOrder).Counterparty = &Counterparty
		|					AND CAST(ReferenceOrder AS Document.SalesOrder).Contract = &Contract
		|					AND CAST(ReferenceOrder AS Document.SalesOrder).Organization = &Organization
		|			END
		|		AND CASE
		|				WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|					THEN Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|						OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				ELSE Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|			END
		|		AND &UseAdvancedFeaturesOfSalesOrder
		|		AND VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
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
		"VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)
		|		AND ReferenceOrder IN
		|			(SELECT
		|					CustomerOrders.Ref
		|				FROM
		|					CustomerOrders)
		|		AND Products IN
		|			(SELECT
		|					TableOfProductAnalysts.Products
		|				FROM
		|					TableOfProductAnalysts)"; // @query-part
	TableFormationParameters.Group = "Recorder, ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"OrderingProducts.Package",
			"OrderingProducts.Products"));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor4",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TTSalesProducts.Package",
			"TTSalesProducts.Products"));
	
EndProcedure

// Returns the request text for getting available orders
// 
// Parameters:
//  TempTableName - String - if necessary, you can specify a different name for the temporary table
// 
// Returns:
//  String - Query text
//
Function QueryTextTableOrders(TempTableName = "") Export
	
	QueryText = 
	"SELECT
	|	OrdersTable.OrderDocument AS OrderDocument
	|INTO OrdersTable
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS OrderDocument,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|				THEN (TurnoversByOrders.QuantityToBeShippedTurnover
	|					- TurnoversByOrders.ShippedQuantityTurnover)
	|			WHEN TRUE
	|				THEN (TurnoversByOrders.ForRegistrationQuantityTurnover
	|					- TurnoversByOrders.IssuedQuantityTurnover)
	|		END AS Count
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.ShippedQuantityTurnover) <> 0
	|		OR (TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		SalesOrder.Ref AS OrderDocument,
	|		CustomerOrderGoods.Count AS Count
	|	FROM
	|		Document.SalesOrder AS SalesOrder
	|			INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
	|			ON SalesOrder.Ref = CustomerOrderGoods.Ref
	|	WHERE
	|		SalesOrder.Organization = &Organization
	|		AND SalesOrder.Currency = &Currency
	|		AND SalesOrder.Counterparty = &Counterparty
	|		AND SalesOrder.Contract = &Contract
	|		AND SalesOrder.Partner = &Partner
	|		AND
	|			CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
	|		AND (SalesOrder.Warehouse = &Warehouse
	|		OR SalesOrder.Warehouse IN HIERARCHY (&Warehouse)
	|		OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|		AND CASE
	|			WHEN NOT &UseLinesOfBusiness
	|				THEN TRUE
	|			ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|		END
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND NOT &UseAdvancedFeaturesOfSalesOrder
	|		AND NOT SalesOrder.DeletionMark
	|		AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|	UNION ALL
	|
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder AS OrderDocument,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			AND OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|				THEN -OrdersRegisterRecords.Count
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			AND OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|				THEN OrdersRegisterRecords.Count
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Count
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|				THEN OrdersRegisterRecords.Count
	|		END AS Count
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN
	|		(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder.Organization = &Organization
	|		AND OrdersRegisterRecords.ReferenceOrder.Currency = &Currency
	|		AND OrdersRegisterRecords.ReferenceOrder.Counterparty = &Counterparty
	|		AND OrdersRegisterRecords.ReferenceOrder.Contract = &Contract
	|		AND OrdersRegisterRecords.ReferenceOrder.Partner = &Partner
	|		AND CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|				THEN TRUE
	|			WHEN TRUE
	|				THEN OrdersRegisterRecords.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
	|		END
	|		AND CASE
	|			WHEN NOT &UseLinesOfBusiness
	|				THEN TRUE
	|			ELSE OrdersRegisterRecords.ReferenceOrder.LineOfBusiness = &LineOfBusiness
	|		END
	|		AND CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|				THEN VALUETYPE(OrdersRegisterRecords.ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			ELSE VALUETYPE(OrdersRegisterRecords.ReferenceOrder) <> TYPE(Document.MaterialProviderOrder2_5)
	|		END
	|		AND (OrdersRegisterRecords.Warehouse = &Warehouse
	|		OR OrdersRegisterRecords.Warehouse IN HIERARCHY (&Warehouse)
	|		OR OrdersRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))) AS OrdersTable
	|GROUP BY
	|	OrdersTable.OrderDocument
	|HAVING
	|	SUM(OrdersTable.Count) > 0";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder.Organization = &Organization
		|		AND ReferenceOrder.Currency = &Currency
		|		AND ReferenceOrder.Counterparty = &Counterparty
		|		AND ReferenceOrder.Contract = &Contract
		|		AND ReferenceOrder.Partner = &Partner
		|		AND CASE
		|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
		|					THEN TRUE
		|				WHEN TRUE
		|					THEN Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
		|			END
		|		AND CASE
		|				WHEN NOT &UseLinesOfBusiness
		|					THEN TRUE
		|				ELSE ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END
		|		AND CASE
		|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
		|					THEN VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
		|				ELSE VALUETYPE(ReferenceOrder) <> TYPE(Document.MaterialProviderOrder2_5)
		|			END
		|		AND (Warehouse = &Warehouse
		|			OR Warehouse IN HIERARCHY (&Warehouse)
		|			OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef))";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1, ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	If ValueIsFilled(TempTableName) Then
		QueryText = StrReplace(QueryText, "OrdersTable", TempTableName);
	EndIf;
	
	Return QueryText;
	
EndFunction

// Adds a command to create a document "Shipments of goods from storage "based on the"customer Order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   Undefined
//   See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddCreateCommandBasedOnCustomerOrder(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then

		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsShipmentFromStorage.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsShipmentFromStorage);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseOrderSupplyWithAssignment,ProvideAgentServicesOnPurchaseToPrincipals";
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateShipmentOfGoodsFromStorageBasedOnCustomerOrder";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns an error if we are trying to create "shipments of goods from storage" based on the "customer Order" from the household. operation other than "Delivery under the principal".
//
// Parameters:
//  BasisObject - DocumentRef - Reference to the base object.
//
// Returns:
//  Structure - The structure contains:
//   * ErrorText - Undefined, String - error description.
//
Function CreateShipmentOfGoodsFromStorageBasedOnCustomerOrderVerificationOfBusinessTransactions(BasisObject) Export
	
	CheckResult = New Structure("ErrorText", Undefined);
	
	If TypeOf(BasisObject) = Type("DocumentRef.SalesOrder") Then
		
		BusinessOperation = Common.ObjectAttributeValue(BasisObject, "BusinessOperation");
		
		If Not ValueIsFilled(BusinessOperation)
			Or Not BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			
			CheckResult.ErrorText = NStr("vi = 'Lệnh không thể được thực thi cho giao dịch kinh doanh này.';
										|ru = 'Команда не может быть выполнена для данной хозяйственной операции';
										|en = 'The command cannot be executed for the given business transaction.'; fa = 'The command cannot be executed for the given business transaction.';
										|it = 'Il comando non può essere eseguito per questa operazione gestionale';
										|pl = 'Nie można wykonać polecenia dla danej operacji gospodarczej.';
										|tr = 'Komut bu ticari işlem için yürütülemez'");
			
		EndIf;
				
	EndIf;
	
	Return CheckResult;

EndFunction

// Generates the query result for the undelivered part of orders
//
// Parameters:
//	SelectionData_      - Structure - the fields that will be selected remains orders
//	Warehouse             - CatalogRef.Warehouses - warehouse where order balances will be selected
//	AnArrayOfOrders     - Array of DocumentRef.MaterialProviderOrder2_5 - orders for which Balances will be selected
//	The variant of the form - enumeration Link - indicates the variant of the sales document design.
//
// Returns:
//	QueryResult - the result of the request for the unloaded part of orders \ requests.
//
Function GetQueryResultsForOrderBalances(SelectionData_, Warehouse = Undefined, AnArrayOfOrders = Undefined)
	
	Query = New Query;
	
	EconomicOperationsOfOrders = New Array;
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	EconomicOperationsOfOrders.Add(TollingSchemeClientServer.ContractBusinessTransaction());
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.Subcontracting2_5);
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	Query.SetParameter("EconomicOperationsOfOrders", EconomicOperationsOfOrders);
	Query.SetParameter("AnArrayOfOrders",                     AnArrayOfOrders);
	Query.SetParameter("SelectByOrder_",                  AnArrayOfOrders <> Undefined);
	Query.SetParameter("Warehouse",                             Warehouse);
	Query.SetParameter("CurrentDate",                       BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Recorder",                       SelectionData_.Ref);
	Query.SetParameter("Partner",                           SelectionData_.Partner);
	Query.SetParameter("Counterparty",                        SelectionData_.Counterparty);
	Query.SetParameter("Contract",                           SelectionData_.Contract);
	Query.SetParameter("Organization",                       SelectionData_.Organization);
	Query.SetParameter("Currency",                            SelectionData_.Currency);
	Query.SetParameter("SalesOpportunity",                            SelectionData_.SalesOpportunity);
	Query.SetParameter("LineOfBusiness",           SelectionData_.LineOfBusiness);
	Query.SetParameter(
		"UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	
	GoodsShipment = Undefined;
	If TypeOf(SelectionData_) <> Type("Structure") 
	 Or Not SelectionData_.Property("GoodsShipment", GoodsShipment) Then
		
		GoodsShipment = New ValueTable;
		GoodsShipment.Columns.Add("SalesOrder",      New TypeDescription("DocumentRef.MaterialProviderOrder2_5"));
		GoodsShipment.Columns.Add("RowCode",         Common.TypeDescriptionNumber(10, 0));
		GoodsShipment.Columns.Add("Products",      New TypeDescription("CatalogRef.Products"));
		GoodsShipment.Columns.Add("Characteristic",    New TypeDescription("CatalogRef.ItemsCharacteristics"));
		GoodsShipment.Columns.Add("Count",        Common.TypeDescriptionNumber(15, 3));
		GoodsShipment.Columns.Add("Warehouse",             New TypeDescription("CatalogRef.Warehouses"));
		GoodsShipment.Columns.Add("LineNumber",       Common.TypeDescriptionNumber(10, 0));
		GoodsShipment.Columns.Add("Package",          New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		GoodsShipment.Columns.Add("Series",             New TypeDescription("CatalogRef.ItemsBatches"));
		GoodsShipment.Columns.Add("QuantityInOrder", Common.TypeDescriptionNumber(15, 3));
		
	EndIf;
	
	Query.SetParameter("GoodsShipment", GoodsShipment);
	
	Query.Text =
	"SELECT
	|	GoodsShipment.SalesOrder                                       AS SalesOrder,
	|	GoodsShipment.RowCode                                          AS RowCode,
	|	GoodsShipment.LineNumber                                        AS LineNumber,
	|	CAST(GoodsShipment.Products AS Catalog.Products) AS Products,
	|	GoodsShipment.Characteristic                                     AS Characteristic,
	|	GoodsShipment.Series                                              AS Series,
	|	CAST(GoodsShipment.Warehouse AS Catalog.Warehouses)              AS Warehouse,
	|	GoodsShipment.Package                                           AS Package,
	|	GoodsShipment.Count                                         AS Count
	|INTO GoodsShipment
	|FROM
	|	&GoodsShipment AS GoodsShipment
	|
	|INDEX BY
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsShipment.SalesOrder      AS SalesOrder,
	|	GoodsShipment.RowCode         AS RowCode,
	|	GoodsShipment.Products      AS Products,
	|	GoodsShipment.Characteristic    AS Characteristic,
	|	GoodsShipment.Series             AS Series,
	|	SUM(GoodsShipment.Count) AS Count,
	|	GoodsShipment.Package          AS Package
	|INTO GoodsShippedByOrder
	|FROM
	|	GoodsShipment AS GoodsShipment
	|WHERE
	|	GoodsShipment.RowCode <> 0
	|
	|GROUP BY
	|	GoodsShipment.SalesOrder,
	|	GoodsShipment.RowCode,
	|	GoodsShipment.Products,
	|	GoodsShipment.Characteristic,
	|	GoodsShipment.Series,
	|	GoodsShipment.Package
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	RowCode,
	|	SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Recorder                  AS SalesOrder,
	|	GoodsShipment.RowCode      AS RowCode,
	|	GoodsShipment.LineNumber    AS LineNumber,
	|	GoodsShipment.Products   AS Products,
	|	GoodsShipment.Characteristic AS Characteristic,
	|	GoodsShipment.Count     AS Count,
	|	GoodsShipment.Warehouse          AS Warehouse,
	|	GoodsShipment.Package       AS Package,
	|	GoodsShipment.Series          AS Series,
	|	GoodsShipment.Count     AS QuantityInOrder
	|INTO GoodsShippedWithoutOrder
	|FROM
	|	GoodsShipment AS GoodsShipment
	|WHERE
	|	GoodsShipment.RowCode = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder     AS SalesOrder,
	|	OrdersTable.Products     AS Products,
	|	OrdersTable.Characteristic   AS Characteristic,
	|	OrdersTable.RowCode        AS RowCode,
	|	OrdersTable.Warehouse            AS Warehouse,
	|	OrdersTable.Series            AS Series,
	|	SUM(OrdersTable.ToTransfer) AS Count
	|INTO TableBalance
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder     AS SalesOrder,
	|		TurnoversByOrders.Products     AS Products,
	|		TurnoversByOrders.Characteristic   AS Characteristic,
	|		TurnoversByOrders.RowCode        AS RowCode,
	|		TurnoversByOrders.Warehouse            AS Warehouse,
	|		TurnoversByOrders.Series            AS Series,
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.ShippedQuantityTurnover) AS ToTransfer
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.ShippedQuantityTurnover) <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder   AS SalesOrder,
	|		OrdersRegisterRecords.Products   AS Products,
	|		OrdersRegisterRecords.Characteristic AS Characteristic,
	|		OrdersRegisterRecords.RowCode      AS RowCode,
	|		OrdersRegisterRecords.Warehouse          AS Warehouse,
	|		OrdersRegisterRecords.Series          AS Series,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE OrdersRegisterRecords.Count
	|		END AS ToTransfer
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN
	|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|		AND OrdersRegisterRecords.Active
	|		AND CASE
	|			WHEN &SelectByOrder_
	|				THEN OrdersRegisterRecords.ReferenceOrder IN (&AnArrayOfOrders)
	|			ELSE OrdersRegisterRecords.ReferenceOrder.Partner     = &Partner
	|				AND OrdersRegisterRecords.ReferenceOrder.Counterparty  = &Counterparty
	|				AND OrdersRegisterRecords.ReferenceOrder.Contract     = &Contract
	|				AND OrdersRegisterRecords.ReferenceOrder.Organization = &Organization
	|				AND OrdersRegisterRecords.ReferenceOrder.Currency      = &Currency
	|				AND OrdersRegisterRecords.ReferenceOrder.SalesOpportunity      = &SalesOpportunity
	|				AND (NOT &UseLinesOfBusiness
	|					OR OrdersRegisterRecords.ReferenceOrder.LineOfBusiness = &LineOfBusiness)
	|				AND OrdersRegisterRecords.ReferenceOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
	|		END
	|		AND CASE
	|			WHEN &Warehouse IN (
	|					UNDEFINED,
	|					VALUE(Catalog.Warehouses.EmptyRef))
	|				THEN TRUE
	|			WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|				THEN OrdersRegisterRecords.Warehouse IN HIERARCHY (&Warehouse)
	|				  OR OrdersRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE OrdersRegisterRecords.Warehouse IN (
	|									VALUE(Catalog.Warehouses.EmptyRef),
	|									&Warehouse)
	|		END
	|	) AS OrdersTable
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode,
	|	OrdersTable.Warehouse,
	|	OrdersTable.Series
	|
	|HAVING
	|	SUM(OrdersTable.ToTransfer) > 0
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.SalesOrder                              AS SalesOrder,
	|	TableBalance.Products                              AS Products,
	|	TableBalance.Characteristic                            AS Characteristic,
	|	TableBalance.RowCode                                 AS RowCode,
	|	TableBalance.Count                                AS Count,
	|	TableBalance.Warehouse                                     AS Warehouse,
	|	ISNULL(WaybillGoods.Count, 0)                  AS QuantityInInvoice,
	|	OrderingProducts.LineNumber                                  AS LineNumber,
	|	OrderingProducts.Ref.SalesOpportunity                                AS SalesOpportunity,
	|	OrderingProducts.DateOfShipment                                 AS DateOfShipment,
	|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
	|	OrderingProducts.Series                                        AS Series,
	|	OrderingProducts.Count                                   AS QuantityInOrder,
	|	TableBalance.Products.FEACNCode                     AS FEACNCode,
	|	OrderingProducts.Products.ItemsType                 AS ItemsType,
	|	CASE
	|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2)
	|	END                                                    AS ZoomRatio,
	|	TableBalance.Count / ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1) AS NumberOfPackages,
	|	OrderingProducts.SupplyOption                           AS SupplyOption,
	|	CASE
	|		WHEN OrderingProducts.WithAssignment
	|			THEN TableBalance.SalesOrder.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                    AS Purpose,
	|	CASE
	|		WHEN OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                    AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN OrderingProducts.Products.ItemsType IN (
	|							VALUE(Enum.ItemsTypes.OperationService),
	|							VALUE(Enum.ItemsTypes.Work_5))
	|			THEN FALSE
	|		ELSE CASE
	|				WHEN OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|					AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|					THEN TRUE
	|			ELSE FALSE
	|		END
	|	END                                                    AS CheckShipment
	|FROM
	|	TableBalance AS TableBalance
	|
	|		INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS OrderingProducts
	|		ON TableBalance.Products   = OrderingProducts.Products
	|		 AND TableBalance.Characteristic = OrderingProducts.Characteristic
	|		 AND TableBalance.RowCode      = OrderingProducts.RowCode
	|		 AND TableBalance.SalesOrder   = OrderingProducts.Ref
	|
	|		LEFT JOIN GoodsShippedByOrder AS WaybillGoods
	|		ON TableBalance.Products   = WaybillGoods.Products
	|		 AND TableBalance.Characteristic = WaybillGoods.Characteristic
	|		 AND TableBalance.RowCode      = WaybillGoods.RowCode
	|		 AND TableBalance.SalesOrder   = WaybillGoods.SalesOrder
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsShipment.SalesOrder                                                AS SalesOrder,
	|	GoodsShipment.Products                                                AS Products,
	|	GoodsShipment.Characteristic                                              AS Characteristic,
	|	GoodsShipment.RowCode                                                   AS RowCode,
	|	GoodsShipment.Count                                                  AS Count,
	|	GoodsShipment.Warehouse                                                       AS Warehouse,
	|	GoodsShipment.Count                                                  AS QuantityInInvoice,
	|	GoodsShipment.LineNumber                                                 AS LineNumber,
	|	UNDEFINED                                                               AS SalesOpportunity,
	|	UNDEFINED                                                               AS DateOfShipment,
	|	GoodsShipment.Package                                                    AS Package,
	|	GoodsShipment.Series                                                       AS Series,
	|	0                                                                          AS QuantityInOrder,
	|	GoodsShipment.Products.FEACNCode                                       AS FEACNCode,
	|	GoodsShipment.Products.ItemsType                                AS ItemsType,
	|	CASE
	|		WHEN GoodsShipment.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor3
	|	END                                                                      AS ZoomRatio,
	|	GoodsShipment.Count / ISNULL(&QueryTextPackagingFactor3, 1) AS NumberOfPackages,
	|	UNDEFINED                                                               AS SupplyOption,
	|	VALUE(Catalog.Assignments.EmptyRef)                               AS Purpose,
	|	CASE
	|		WHEN GoodsShipment.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsShipment.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                      AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN GoodsShipment.Products.ItemsType IN (
	|								VALUE(Enum.ItemsTypes.OperationService),
	|								VALUE(Enum.ItemsTypes.Work_5))
	|			THEN FALSE
	|		ELSE CASE
	|			WHEN GoodsShipment.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND GoodsShipment.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	END                                                                      AS CheckShipment
	|FROM
	|	GoodsShippedWithoutOrder AS GoodsShipment
	|
	|ORDER BY
	|	TableBalance.SalesOrder,
	|	OrderingProducts.LineNumber
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	GiverSOrder2_5Products.LineNumber AS LineNumber
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GiverSOrder2_5Products
	|WHERE
	|	GiverSOrder2_5Products.Ref IN (&AnArrayOfOrders)
	|	AND GiverSOrder2_5Products.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND NOT GiverSOrder2_5Products.Canceled
	|	AND GiverSOrder2_5Products.Ref.Posted
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialProviderOrder2_5.Ref AS Ref
	|INTO ShippingDocuments
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	CASE
	|		WHEN &SelectByOrder_
	|			THEN MaterialProviderOrder2_5.Ref IN (&AnArrayOfOrders)
	|			  OR MaterialProviderOrder2_5.Ref = &Recorder
	|		ELSE MaterialProviderOrder2_5.Partner     = &Partner
	|			AND MaterialProviderOrder2_5.Counterparty  = &Counterparty
	|			AND MaterialProviderOrder2_5.Contract     = &Contract
	|			AND MaterialProviderOrder2_5.Organization = &Organization
	|			AND MaterialProviderOrder2_5.Currency      = &Currency
	|			AND MaterialProviderOrder2_5.SalesOpportunity      = &SalesOpportunity
	|			AND (NOT &UseLinesOfBusiness
	|				OR MaterialProviderOrder2_5.LineOfBusiness = &LineOfBusiness)
	|			AND MaterialProviderOrder2_5.BusinessOperation IN (&EconomicOperationsOfOrders)
	|	END
	|	AND CASE
	|		WHEN &Warehouse IN (
	|				UNDEFINED,
	|				VALUE(Catalog.Warehouses.EmptyRef))
	|			THEN TRUE
	|		WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|			THEN MaterialProviderOrder2_5.Warehouse IN HIERARCHY (&Warehouse)
	|			  OR MaterialProviderOrder2_5.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE MaterialProviderOrder2_5.Warehouse IN (
	|								VALUE(Catalog.Warehouses.EmptyRef),
	|								&Warehouse)
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsShipmentFromStorage.Ref AS Ref
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|WHERE
	|	CASE
	|		WHEN &SelectByOrder_
	|			THEN GoodsShipmentFromStorage.Ref IN (&AnArrayOfOrders)
	|			  OR GoodsShipmentFromStorage.Ref  = &Recorder
	|		ELSE GoodsShipmentFromStorage.Partner     = &Partner
	|			AND GoodsShipmentFromStorage.Counterparty  = &Counterparty
	|			AND GoodsShipmentFromStorage.Contract     = &Contract
	|			AND GoodsShipmentFromStorage.Organization = &Organization
	|			AND GoodsShipmentFromStorage.Currency      = &Currency
	|			AND GoodsShipmentFromStorage.SalesOpportunity      = &SalesOpportunity
	|			AND (NOT &UseLinesOfBusiness
	|				OR GoodsShipmentFromStorage.LineOfBusiness = &LineOfBusiness)
	|			AND GoodsShipmentFromStorage.BusinessOperation IN (&EconomicOperationsOfOrders)
	|	END
	|	AND GoodsShipmentFromStorage.Ref = &Recorder
	|	AND CASE
	|		WHEN &Warehouse IN (
	|				UNDEFINED,
	|				VALUE(Catalog.Warehouses.EmptyRef))
	|			THEN TRUE
	|		WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|			THEN GoodsShipmentFromStorage.Warehouse IN HIERARCHY (&Warehouse)
	|			  OR GoodsShipmentFromStorage.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsShipmentFromStorage.Warehouse IN (
	|										VALUE(Catalog.Warehouses.EmptyRef),
	|										&Warehouse)
	|	END
	|
	|INDEX BY
	|	Ref
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialProviderOrder2_5.Ref AS Ref
	|INTO OrderDocument
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	CASE
	|		WHEN &SelectByOrder_
	|			THEN MaterialProviderOrder2_5.Ref IN (&AnArrayOfOrders)
	|			  OR MaterialProviderOrder2_5.Ref = &Recorder
	|		ELSE MaterialProviderOrder2_5.Partner     = &Partner
	|			AND MaterialProviderOrder2_5.Counterparty  = &Counterparty
	|			AND MaterialProviderOrder2_5.Contract     = &Contract
	|			AND MaterialProviderOrder2_5.Organization = &Organization
	|			AND MaterialProviderOrder2_5.Currency      = &Currency
	|			AND MaterialProviderOrder2_5.SalesOpportunity      = &SalesOpportunity
	|			AND (NOT &UseLinesOfBusiness
	|				OR MaterialProviderOrder2_5.LineOfBusiness = &LineOfBusiness)
	|			AND MaterialProviderOrder2_5.BusinessOperation IN (&EconomicOperationsOfOrders)
	|	END
	|	AND CASE
	|		WHEN &Warehouse IN (
	|				UNDEFINED,
	|				VALUE(Catalog.Warehouses.EmptyRef))
	|			THEN TRUE
	|		WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|			THEN MaterialProviderOrder2_5.Warehouse IN HIERARCHY (&Warehouse)
	|			  OR MaterialProviderOrder2_5.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE MaterialProviderOrder2_5.Warehouse IN (
	|								VALUE(Catalog.Warehouses.EmptyRef),
	|								&Warehouse)
	|	END
	|
	|INDEX BY
	|	Ref
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder                AS SalesOrder,
	|	OrdersTable.Products                AS Products,
	|	OrdersTable.Characteristic              AS Characteristic,
	|	OrdersTable.Warehouse                       AS Warehouse,
	|	OrdersTable.AdvancedWarehousingOnShipment    AS AdvancedWarehousingOnShipment,
	|	OrdersTable.Series                       AS Series,
	|	OrdersTable.Purpose                  AS Purpose,
	|	SUM(OrdersTable.NumberInProgress) AS NumberInProgress,
	|	SUM(OrdersTable.Count)           AS Count
	|FROM
	|	(SELECT
	|		GoodsForIssueBalance.DocumentShipments                                       AS SalesOrder,
	|		GoodsForIssueBalance.Products                                           AS Products,
	|		GoodsForIssueBalance.Characteristic                                         AS Characteristic,
	|		GoodsForIssueBalance.Warehouse                                                  AS Warehouse,
	|		CASE
	|			WHEN GoodsForIssueBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND GoodsForIssueBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                                                         AS AdvancedWarehousingOnShipment,
	|		GoodsForIssueBalance.Series                                                  AS Series,
	|		GoodsForIssueBalance.Purpose                                             AS Purpose,
	|		GoodsForIssueBalance.AssemblyInProgressReceipt                                       AS NumberInProgress,
	|		GoodsForIssueBalance.ToShipExpense + GoodsForIssueBalance.AssembledReceipt AS Count
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,,
	|			DocumentShipments IN
	|				(SELECT
	|					ShippingDocuments.Ref
	|				FROM
	|					ShippingDocuments)) AS GoodsForIssueBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrdersBalance.ReferenceOrder                                                   AS SalesOrder,
	|		OrdersBalance.Products                                                   AS Products,
	|		OrdersBalance.Characteristic                                                 AS Characteristic,
	|		OrdersBalance.Warehouse                                                          AS Warehouse,
	|		CASE
	|			WHEN OrdersBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND OrdersBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                                                        AS AdvancedWarehousingOnShipment,
	|		OrdersBalance.Series                                                          AS Series,
	|		CASE
	|			WHEN OrderingProducts.WithAssignment
	|				THEN OrdersBalance.ReferenceOrder.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                                                                        AS Purpose,
	|		0                                                                            AS NumberInProgress,
	|		-OrdersBalance.ShippedQuantityTurnover AS Count
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS OrdersBalance
	|
	|			LEFT JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS OrderingProducts
	|			ON OrdersBalance.Products   = OrderingProducts.Products
	|			 AND OrdersBalance.Characteristic = OrderingProducts.Characteristic
	|			 AND OrdersBalance.RowCode      = OrderingProducts.RowCode
	|			 AND OrdersBalance.ReferenceOrder   = OrderingProducts.Ref
	|	WHERE
	|		OrdersBalance.Recorder <> &Recorder) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.Warehouse,
	|	OrdersTable.AdvancedWarehousingOnShipment,
	|	OrdersTable.Series,
	|	OrdersTable.Purpose
	|
	|HAVING
	|	SUM(OrdersTable.Count) > 0
	|	OR SUM(OrdersTable.NumberInProgress) > 0";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|				WHEN &SelectByOrder_
		|					THEN ReferenceOrder IN (&AnArrayOfOrders)
		|				ELSE ReferenceOrder.Partner     = &Partner
		|					AND ReferenceOrder.Counterparty  = &Counterparty
		|					AND ReferenceOrder.Contract     = &Contract
		|					AND ReferenceOrder.Organization = &Organization
		|					AND ReferenceOrder.Currency      = &Currency
		|					AND ReferenceOrder.SalesOpportunity      = &SalesOpportunity
		|					AND (NOT &UseLinesOfBusiness
		|						OR ReferenceOrder.LineOfBusiness = &LineOfBusiness)
		|					AND ReferenceOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
		|			END
		|			AND CASE
		|				WHEN &Warehouse IN (
		|						UNDEFINED,
		|						VALUE(Catalog.Warehouses.EmptyRef))
		|					THEN TRUE
		|				WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|					THEN Warehouse IN HIERARCHY (&Warehouse)
		|					  OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				ELSE Warehouse IN (
		|						VALUE(Catalog.Warehouses.EmptyRef),
		|						&Warehouse)
		|			END";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
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
		|				OrderDocument.Ref
		|			FROM
		|				OrderDocument)";
	TableFormationParameters.Group = "Recorder, ReferenceOrder, Products, Characteristic, Warehouse, Series, RowCode";
	TableFormationParameters.Indicators = "Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"WaybillGoods.Package", "WaybillGoods.Products"));
			
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"OrderingProducts.Package", "OrderingProducts.Products"));
			
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextPackagingFactor3",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"GoodsShipment.Package", "GoodsShipment.Products"));
	
	SetPrivilegedMode(True);
	
	Return Query.ExecuteBatch();
	
EndFunction
Function GetSearchStructure(BySeries = True)
	
	TheStructureOfTheSearch = New Structure;
	
	TheStructureOfTheSearch.Insert("Products");
	TheStructureOfTheSearch.Insert("Characteristic");
	TheStructureOfTheSearch.Insert("Purpose");
	TheStructureOfTheSearch.Insert("Warehouse");
	If BySeries Then
		TheStructureOfTheSearch.Insert("Series");
	EndIf;
	
	Return TheStructureOfTheSearch;
	
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

#EndRegion

#EndIf
#EndIf
