#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn hàng sửa chữa';
		|ru = 'Заказ на ремонт';
		|en = 'R&M order'; fa = 'سفارش تعمیر و نگهداری';
		|it = 'Ordine di manutenzione';
		|pl = 'Zamówienie naprawy';
		|tr = 'Bakım-onarım siparişi'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
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
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, Department";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("InternalInventoryTransfers");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("RMManagement");
	DocumentMechanisms.Add("AddressWarehouse");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RMOrder") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, Registers);
		QueryTextTableRMPlan(Query, QueryTexts, Registers);
		QueryTextTableAssetRelevancePeriods(Query, QueryTexts, Registers);
		QueryTextTableWorkCenterRM(Query, QueryTexts, Registers);
		QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ReflectReserve(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.WorkOutput.AddCreateCommandBasedOnCreatingNewEmployees(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(Command, "LaborCostsAreAvailable", True, DataCompositionComparisonType.Equal);
	EndIf;
	
	Documents.InventoryConsumption.AddCreateBasedOnOrderCommand_(GenerationCommands);
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	DataProcessors.GenerationOfTransferToProductionOrdersByReference.AddGenerateCommand(GenerationCommands);
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	RMOrderLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command of creation of the document "Order for repair".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Documents.RMOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RMOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RMOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseRMManagement";
		
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
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
EndProcedure

// The function returns the details that depend on the business operation of the document.
//
// Parameters:
//  BusinessOperation	 - EnumRef.BusinessTransactions	 - Link to the current operation
//  ArrayOfAllProps	 - Array									 - An array of details of the document
//  ArrayOfOperationDetails - Array									 - An array of details of the operation.
//
// Returns:
//  Array - An array of business transaction details.
//
Function NamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("RM.ExpenseItem");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.Repair Then
		
		ArrayOfOperationDetails.Add("RM.ExpenseItem");
		
	EndIf;
	
	Return ArrayOfOperationDetails;
	
EndFunction

// Cancels all lines for which the employee's work was not documented.
//
// Parameters:
// 		Document - DocumentObject.RMOrder, FormDataStructure - a document where you need to cancel undelivered materials and outstanding work
// 		CheckBalance  - Boolean - indicates whether a request is required to check balances.
//
// Returns:
// 		Number - The number of canceled rows.
//
Function CancelUnfulfilledLaborLines(Document, Val CheckBalance = True) Export
	
	NumberOfCanceledLines = 0;
	Table = Document.LaborCosts;
	
	PropertiesOfCanceledRow = New Structure(
		"Canceled",
		True);
	
	If Not CheckBalance Then
		For N1 = 0 To Table.Count() - 1 Do
			If Not Table[N1].Canceled Then
				FillPropertyValues(Table[N1], PropertiesOfCanceledRow);
				NumberOfCanceledLines = NumberOfCanceledLines + 1;
			EndIf;
		EndDo;
		Return NumberOfCanceledLines;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	OrdersBalance.WorkKind AS WorkKind,
	|	OrdersBalance.Performer AS Team,
	|	SUM(OrdersBalance.CountBalance) AS CountBalance
	|FROM
	|	AccumulationRegister.LaborCostsToRegister.Balance(, ReferenceOrder = &RMOrder) AS OrdersBalance
	|WHERE
	|	OrdersBalance.CountBalance > 0
	|
	|GROUP BY
	|	OrdersBalance.WorkKind,
	|	OrdersBalance.Performer");
	
	Query.SetParameter("RMOrder", Document.Ref);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	If Result.IsEmpty() Then
		Return NumberOfCanceledLines;
	EndIf;
	
	Balance = Result.Unload();
	
	LineCount = 0;
	ResidueSearchStructure_ = New Structure("WorkKind, Team");
	While LineCount < Table.Count() Do
		
		String = Table[LineCount];
		
		If String.Canceled Then
			LineCount = LineCount + 1;
			Continue;
		EndIf;
		
		Var_21_Balance = 0;
		FillPropertyValues(ResidueSearchStructure_, String);
		FoundItemsBalance = Balance.FindRows(ResidueSearchStructure_);
		If FoundItemsBalance.Count() <> 0 Then
			Var_21_Balance = FoundItemsBalance[0].CountBalance;
		EndIf;
		
		If Var_21_Balance > 0 Then
			
			If Var_21_Balance >= String.Count Then
				Var_21_Balance = Var_21_Balance - String.Count;
				FillPropertyValues(String, PropertiesOfCanceledRow);
			Else
				NewRow = Table.Add();
				FillPropertyValues(NewRow, String);
				FillPropertyValues(NewRow, PropertiesOfCanceledRow);
				
				String.Count = String.Count - Var_21_Balance;
				
				NewRow.Count = Var_21_Balance;
				
				Var_21_Balance = 0;
			EndIf;
			
			NumberOfCanceledLines = NumberOfCanceledLines + 1;
			
			FoundItemsBalance[0].CountBalance = Var_21_Balance;
			
		EndIf;
		
		LineCount = LineCount + 1;
		
	EndDo;
	
	Return NumberOfCanceledLines;
	
EndFunction

// Fills in the "Warehouse" field in the table part of materials and works based on the data of the material transfer settings.
//
// Parameters:
// 		Document - FormDataCollection, DocumentObject.RMOrder - A document in which you need to fill in the warehouse column of the tabular part of materials and works
// 		Rows - Array - Array of rows in the table part where you need to fill in the "Warehouse" column.
//
Procedure FillOutWarehouseByContentTransferSettings(Document, Rows=Undefined) Export
	
	QueryText =
	"SELECT
	|	(CAST(FillingData.LineNumber AS NUMBER)) - 1 AS RowIndex,
	|	CAST(FillingData.Products AS Catalog.Products) AS Products,
	|	CAST(FillingData.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic
	|INTO FillingData
	|FROM
	|	&FillingData AS FillingData
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FillingData.RowIndex,
	|	CASE
	|		WHEN TRUE
	|			THEN &TextOfMaterialsWarehouseField
	|	END AS Warehouse
	|FROM
	|	FillingData AS FillingData
	|		,ConnectionTextContentTransferSettings";
		
	RequestTextForGettingWarehouse = ProductionSupply.RequestTextForContentTransferSettings(
										"FillingData", 
										"&Department",
										ProductionSupply.SoftwareOptionAccordingToProductionVersion());
										
	QueryText = StrReplace(
						QueryText, 
						",ConnectionTextContentTransferSettings",
						RequestTextForGettingWarehouse.JoinText);
						
	QueryText = StrReplace(
						QueryText, 
						"&TextOfMaterialsWarehouseField",
						RequestTextForGettingWarehouse.WarehouseTextField);
	
		
	Query = New Query(QueryText);
	Query.SetParameter("FillingData", Document.MaterialsAndWorks.Unload(Rows));
	Query.SetParameter("Department", Document.Department);
	Query.SetParameter("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	
	SetPrivilegedMode(True);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		FillPropertyValues(Document.MaterialsAndWorks[Selection.RowIndex], Selection);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
// 		Object - Structure - structure of object details values required for filling in parameters for specifying series
// Returns:
// 		See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.RMOrder";
	SeriesSpecificationParameters.TSSeriesName = "MaterialsAndWorks";
		
	SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
		
	SeriesSpecificationParameters.NameTSGoods = "MaterialsAndWorks";
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentForInternalNeeds);
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	
	SeriesSpecificationParameters.ThisIsOrder = True;
	SeriesSpecificationParameters.ShipmentPlanning = True;
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.Date = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//	FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//		of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
// 		DocumentRef.RMOrder - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	Return FieldValuesToIdentifyReferences.Ref;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
// Parameters:
// 		SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
// 		String - Query text
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.Canceled,
	|	Goods.SupplyOption,
	|	Goods.Count,
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
	|		WHEN Goods.Canceled
	|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|				OR NOT Goods.SupplyOption IN (
	|						VALUE(Enum.SupplyOptions.FromWarehouse),
	|						VALUE(Enum.SupplyOptions.Ship))
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 11
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
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

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.RMOrder - the document for which you need to get the goods
//  CreationParameters - See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
//  TempTablesManager - TempTablesManager - temporary table manager where a table with columns will be created:
//   * LineNumber - Number - Line number
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Department - CatalogRef.BusinessStructure - Department
//   * Purpose - CatalogRef.Assignments - Purpose
//   * SupplyOption - EnumRef.SupplyOptions - security option
//   * WithAssignment - Boolean - WithAssignment
//   * QuantityOfUnits - Number - number of units
//   * CountByDocument - Number - Number of packages
Procedure GoodsOfDocumentForCreatingSecuringOrder(Ref, CreationParameters, TempTablesManager) Export
	
	Attributes = Common.ObjectAttributesValues(Ref, "Status,Posted");
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.RMOrderStatuses.ForCompletion);
	ArrayOfValidStatuses.Add(Enums.RMOrderStatuses.Running);
	ArrayOfValidStatuses.Add(Enums.RMOrderStatuses.Closed);
	
	ThereAreErrorsStatus = True;
	For Each Item In ArrayOfValidStatuses Do
		If Attributes.Status = Item Then
			ThereAreErrorsStatus = False;
			Break;
		EndIf;
	EndDo;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Ref,
		Attributes.Status,
		Not Attributes.Posted,
		ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	Query.Text =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Ref.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN Goods.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Ref.StartDate AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	
	Query.Execute();
	
EndProcedure

// PROCEDURES AND FUNCTIONS OF CHECKS WHEN CHANGING THE STATUS

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
// 		DocumentsArray - Array - An array of references to documents that should be reviewed
// 		NewStatus - String - Name of the new status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.RMOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl") Then
		
		QueryText =
		"SELECT
		|	Balance.InventoryConsumptionOrder AS OrderDocument
		|INTO TTBalancesByProductName
		|FROM
		|	AccumulationRegister.InventoryConsumptionOrders.Balance(, InventoryConsumptionOrder IN (&DocumentsArray)) AS Balance
		|
		|GROUP BY
		|	Balance.InventoryConsumptionOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.ReferenceOrder AS OrderDocument
		|INTO TTBalancesOnLaborCosts
		|FROM
		|	AccumulationRegister.LaborCostsToRegister.Balance(, ReferenceOrder IN (&DocumentsArray)) AS Balance
		|
		|GROUP BY
		|	Balance.ReferenceOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording,
		|	CASE
		|		WHEN TTBalancesByProductName.OrderDocument IS NULL 
		|				AND TTBalancesOnLaborCosts.OrderDocument IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.RMOrder AS DocumentsTable
		|		LEFT JOIN TTBalancesByProductName AS TTBalancesByProductName
		|		ON DocumentsTable.Ref = TTBalancesByProductName.OrderDocument
		|		LEFT JOIN TTBalancesOnLaborCosts AS TTBalancesOnLaborCosts
		|		ON DocumentsTable.Ref = TTBalancesOnLaborCosts.OrderDocument
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording
		|FROM
		|	Document.RMOrder AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//  ValidationSample			 - QueryResultSelection	 - Current selection string
//  NewStatus				 - EnumRef.RMOrderStatuses - New status
//  AdditionalParameters	 - Structure					 - Structure of additional parameters
//  MessageTemplate			 - String						 - The message to show.
//
// Returns:
//  Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters, MessageTemplate = Undefined) Export
	
	Cancel = False;
	
	If AdditionalParameters = Undefined Then
		Return Not Cancel;
	EndIf;
	
	If AdditionalParameters.Property("OrderFulfillmentControl") Then
		
		If ValidationSample.ThereAreLeftoversOnOrder Then
			
			If MessageTemplate = Undefined Then
				ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"" chưa được đặt, bởi vì đơn hàng chưa hoàn thành';
								|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ выполен не полностью';
								|en = 'Status ""%Status%"" of document ""%Document%"" is not set, because the order is not fulfilled completely'; fa = 'Status ""%Status%"" of document ""%Document%"" is not set, because the order is not fulfilled completely';
								|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché l''ordine non è eseguito completamente';
								|pl = 'W dokumencie %Document% nie ustawiono statusu ""%Status%"", ponieważ zamówienie wykonano nie w całości';
								|tr = '%Document% belgesinin durumu ""%Status%"" değil çünkü emir tamamen yerine getirilmedi'");
			Else
				ErrorText = MessageTemplate;
			EndIf;
			
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
// 		Structure - The structure of the execution state.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("OutputTablesSupply", 1);
	StructureState.Insert("DisplayShipmentTables",    2);
	StructureState.Insert("DisplayTablesCanceledShipment", 3);
	StructureState.Insert("NameTSGoodsShipment", "MaterialsAndWorks");
	StructureState.Insert("FieldNameShipmentDate", "Ref.StartDate");
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("RegisterNameShipmentOfServices", "InventoryConsumptionOrders");
 	
	Return StructureState;
	
EndFunction

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//
// Returns:
//	Array - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName) Export
	
	AcceptableStatuses = New Array;
	If DocumentName = "InventoryConsumption" Then
		AcceptableStatuses.Add(Enums.RMOrderStatuses.ForCompletion);
		AcceptableStatuses.Add(Enums.RMOrderStatuses.Running);
		AcceptableStatuses.Add(Enums.RMOrderStatuses.Closed);
	ElsIf DocumentName = "WorkOutput" Then
		AcceptableStatuses.Add(Enums.RMOrderStatuses.Running);
		AcceptableStatuses.Add(Enums.RMOrderStatuses.Closed);
	EndIf;
	
	Return AcceptableStatuses;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
// Parameters:
//  DocumentObject - DocumentObject.RMOrder - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "MaterialsAndWorks";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "MaterialsAndWorksSupplyOption";
	FormItems.Available           = "MaterialsAndWorksAvailable";
	FormItems.Series              = "MaterialsAndWorksSeries";
	FormItems.WithAssignment        = "MaterialsAndWorksWithAssignment";
	FormItems.Warehouse              = "MaterialsAndWorksWarehouse";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.MaterialsAndWorks.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.MaterialsAndWorks.Canceled";
	DataPaths.ItemsType = "Object.MaterialsAndWorks.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.MaterialsAndWorks.CurrentData.Available";
	Links.NumberOfPackages    = "Items.MaterialsAndWorks.CurrentData.NumberOfPackages";
	Links.Count            = "Items.MaterialsAndWorks.CurrentData.Count";
	Links.ShipIfAvailable = "Items.MaterialsAndWorks.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.MaterialsAndWorks.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.MaterialsAndWorks.CurrentData.ItemsType";
	Links.Package              = "Items.MaterialsAndWorks.CurrentData.Package";
	Links.Products          = "Items.MaterialsAndWorks.CurrentData.Products";
	Links.SupplyOption    = "Items.MaterialsAndWorks.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.MaterialsAndWorks.CurrentData.Warehouse";
	Links.MultipleWarehouses      = True;
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "InventoryConsumptionOrders";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.RMOrder";
	EmbeddingParameters.TableName = "Document.RMOrder.MaterialsAndWorks";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	TabPart.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.Status IN(
		|			VALUE(Enum.RMOrderStatuses.ForCompletion),
		|			VALUE(Enum.RMOrderStatuses.Running),
		|			VALUE(Enum.RMOrderStatuses.Closed)
		|		) AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.RMOrderStatuses.ForCompletion),
		|			VALUE(Enum.RMOrderStatuses.Running),
		|			VALUE(Enum.RMOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	BEGINOFPERIOD(CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|			Attributes.CompletedOn
		|		ELSE Attributes.StartDate
		|	END, DAY) AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	
		|	TabPart.Canceled AS Canceled,
		|	
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	UNDEFINED AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	BEGINOFPERIOD(Attributes.StartDate, DAY) AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS TabPart
		|		
		|		LEFT JOIN Document.RMOrder AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	MaterialsAndWorks = New Structure();
	MaterialsAndWorks.Insert("LineNumber",        New TypeDescription("Number"));
	MaterialsAndWorks.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	MaterialsAndWorks.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	MaterialsAndWorks.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	MaterialsAndWorks.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	MaterialsAndWorks.Insert("WithAssignment",        New TypeDescription("Boolean"));
	MaterialsAndWorks.Insert("Count",         New TypeDescription("Number"));
	MaterialsAndWorks.Insert("NumberOfPackages", New TypeDescription("Number"));
	MaterialsAndWorks.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	MaterialsAndWorks.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	MaterialsAndWorks.Insert("Canceled",           New TypeDescription("Boolean"));
	MaterialsAndWorks.Insert("RowCode",          New TypeDescription("Number"));
	
	Object = New Structure();
	Object.Insert("Department",      New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("Purpose",         New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",             New TypeDescription("DocumentRef.RMOrder"));
	Object.Insert("Status",             New TypeDescription("EnumRef.RMOrderStatuses"));
	Object.Insert("StartDate",         New TypeDescription("Date"));
	Object.Insert("CompletedOn",     New TypeDescription("Date"));
	Object.Insert("Date",               New TypeDescription("Date"));
	Object.Insert("Priority",          New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("MaterialsAndWorks",   MaterialsAndWorks);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList ="UNDEFINED";
	
	Return EmbeddingParameters;
	
EndFunction

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.RMOrder, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.WriteOffOfGoodsAndWorksForItems = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the filling in of the document by type of activity VAT
//
// Parameters:
//  Object		- DocumentObject.RMOrder, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - structure of parameters, See VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity.
//
Function ParametersForCheckingDocumentFillingByTypeOfActivity(Object) Export
	
	FillParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	FillParameters.TabularSectionName = "RM";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "Ref";
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

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

#EndRegion

#Region Internal

#Region Supply

Function DocumentParametersForSoftwareActions(Object) Export
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("EmbeddingParameters",               AvailableRemainingEmbeddingOptions());
	DocumentParameters.Insert("Object",                             Object);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	
	ProvisionInDocumentsServer.FillInEmbeddingServiceParameters(DocumentParameters);
	Return DocumentParameters;
	
EndFunction

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.RMOrder - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		References = Object.MaterialsAndWorks.Unload(, "Products").UnloadColumn("Products");
		If Not ValueIsFilled(Object.StartDate) Or Not ValueIsFilled(Object.CompletedOn) Then
			
			ItemsTypes = Common.ObjectsAttributeValue(References, "ItemsType");
			NewStartDate = '00010101';
			NewCompletionDate = '00010101';
			
			For Each Update In Changes Do
				String = Update.String;
				
				ThisIsWork = ItemsTypes[String.Products] = Enums.ItemsTypes.Work_5;
				If String.SupplyOption = Enums.SupplyOptions.Ship
						Or String.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
						
					If ThisIsWork Then
						NewCompletionDate = CurrentSessionDate();
					Else
						NewStartDate = CurrentSessionDate();
					EndIf;
					
				EndIf;
				If NewStartDate <> '00010101' And NewCompletionDate <> '00010101' Then
					Break;
				EndIf;
				
			EndDo;
			
			If Not ValueIsFilled(Object.StartDate) And Not ValueIsFilled(Object.CompletedOn) Then
				Object.StartDate = NewStartDate;
				Object.CompletedOn = NewCompletionDate;
			Else
				If Not ValueIsFilled(Object.StartDate) And NewStartDate <= Object.CompletedOn Then
					Object.StartDate = NewStartDate;
				EndIf;
				If Not ValueIsFilled(Object.CompletedOn) And NewCompletionDate >= Object.StartDate Then
					Object.CompletedOn = NewCompletionDate;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.MaterialsAndWorks);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);

EndProcedure

#EndRegion

#Region LinesOfBusiness

// 
// Returns:
//  See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.RMOrder";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("RecordsInWarehouseRegisters",
		"ISNULL(GoodsTable.Ref.Purpose.RecordsInWarehouseRegisters, FALSE)");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "InventoryConsumptionOrders" Then
		
		QueryText = QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "LaborCostsToRegister" Then
		
		QueryText = QueryTextTableLaborCostsToRegister(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "RepairOrderLaborCosts";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
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

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	HeaderData_.Ref             AS Ref,
		|	HeaderData_.Date               AS Period,
		|	HeaderData_.Number              AS Number,
		|	HeaderData_.StartDate         AS StartDate,
		|	HeaderData_.CompletedOn     AS CompletedOn,
		|	HeaderData_.Department      AS Department,
		|	HeaderData_.Organization        AS Organization,
		|	HeaderData_.Status             AS Status,
		|	HeaderData_.EmployeeResponsible      AS EmployeeResponsible,
		|	HeaderData_.Author              AS Author,
		|	HeaderData_.Comment        AS Comment,
		|	HeaderData_.Posted           AS Posted,
		|	HeaderData_.DeletionMark    AS DeletionMark,
		|	HeaderData_.LineOfBusiness AS LineOfBusiness,
		|	HeaderData_.BusinessOperation   AS BusinessOperation,
		|	HeaderData_.Purpose         AS Purpose,
		|	HeaderData_.Priority          AS Priority,
		|	ISNULL(HeaderData_.Purpose.RecordsInWarehouseRegisters,FALSE) AS RecordsInWarehouseRegisters,
		|	HeaderData_.Asset AS Asset,
		|	HeaderData_.ThisIsWorksConsumptionOrder AS ThisIsWorksConsumptionOrder
		|FROM
		|	Document.RMOrder AS HeaderData_
		|WHERE
		|	HeaderData_.Ref = &Ref
		|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.RMOrder"));
	ValuesOfHoldingParameters.Insert("UseNodes", GetFunctionalOption("UseSubAssets"));

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, Registers)
	
	RegisterName = "InventoryConsumptionOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	BEGINOFPERIOD(&Period, DAY)           AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	GoodsTable.Ref                   AS InventoryConsumptionOrder,
		|	GoodsTable.Products             AS Products,
		|	GoodsTable.Characteristic           AS Characteristic,
		|	GoodsTable.Series                    AS Series,
		|	GoodsTable.RowCode                AS RowCode,
		|	CASE WHEN GoodsTable.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
		|				THEN GoodsTable.Warehouse
		|			ELSE
		|				VALUE(Catalog.Warehouses.EmptyRef)
		|		END AS Warehouse,
		|	GoodsTable.Count               AS Ordered,
		|	0 AS ToRegister
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND (NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		OR &ThisIsWorksConsumptionOrder)
		|	
		|	UNION ALL
		|	
		|SELECT
		|	CASE WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
		|		THEN CAST(&StartDate AS DATE)
		|		ELSE CAST(&CompletedOn AS DATE)
		|	END,
		|	VALUE(AccumulationRecordType.Receipt),
		|	GoodsTable.Ref,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series,
		|	GoodsTable.RowCode,
		|	CASE WHEN GoodsTable.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
		|				THEN GoodsTable.Warehouse
		|			ELSE
		|				VALUE(Catalog.Warehouses.EmptyRef)
		|		END AS Warehouse,
		|	0,
		|	GoodsTable.Count
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND NOT GoodsTable.Canceled
		|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND &Status IN (VALUE(Enum.RMOrderStatuses.ForCompletion), VALUE(Enum.RMOrderStatuses.Running), VALUE(Enum.RMOrderStatuses.Closed))
		|	AND (NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		OR &ThisIsWorksConsumptionOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	&Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	GoodsTable.Ref,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series,
		|	GoodsTable.RowCode,
		|	CASE
		|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN GoodsTable.Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END,
		|	-GoodsTable.Count,
		|	0
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Canceled
		|	AND (NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		OR &ThisIsWorksConsumptionOrder)
		|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRMPlan(Query, QueryTexts, Registers)
	RegisterName = "RMPlan";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT DISTINCT
		|	&CompletedOn AS Period,
		|	ISNULL(SubAssets.Ref, &Asset) AS Asset,
		|	RM.RMType AS RMType,
		|	RM.RMCycle AS RMCycle
		|FROM
		|	Document.RMOrder.RM AS RM
		|		LEFT JOIN Catalog.SubAssets AS SubAssets
		|		ON RM.Node = SubAssets.Ref AND &UseNodes
		|WHERE
		|	RM.Ref = &Ref
		|	AND &Status IN (VALUE(Enum.RMOrderStatuses.ForCompletion), VALUE(Enum.RMOrderStatuses.Running), VALUE(Enum.RMOrderStatuses.Closed))";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableWorkCenterRM(Query, QueryTexts, Registers)
	RegisterName = "WorkCenterRM";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	RMOrderWorkCenters.Ref AS RMOrder,
		|	RMOrderWorkCenters.WorkCenter AS WorkCenter,
		|	RMOrderWorkCenters.LineNumber AS LineNumber,
		|	RMOrderWorkCenters.StartDate AS StartDate,
		|	RMOrderWorkCenters.CompletedOn AS CompletedOn
		|FROM
		|	Document.RMOrder.WorkCenters AS RMOrderWorkCenters
		|WHERE
		|	RMOrderWorkCenters.Ref = &Ref
		|	AND &Status IN (VALUE(Enum.RMOrderStatuses.ForCompletion), VALUE(Enum.RMOrderStatuses.Running), VALUE(Enum.RMOrderStatuses.Closed))";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers)
	RegisterName = "LaborCostsToRegister";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	&StartDate AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	RepairOrderLaborCosts.Ref AS ReferenceOrder,
		|	RepairOrderLaborCosts.WorkKind AS WorkKind,
		|	RepairOrderLaborCosts.Team AS Performer,
		|	&Department AS Department,
		|	RepairOrderLaborCosts.Count AS Count,
		|	RepairOrderLaborCosts.RowCode AS ReferenceRowCode
		|FROM
		|	Document.RMOrder.LaborCosts AS RepairOrderLaborCosts
		|WHERE
		|	RepairOrderLaborCosts.Ref = &Ref
		|	AND &Status IN (VALUE(Enum.RMOrderStatuses.Running), VALUE(Enum.RMOrderStatuses.Closed))
		|	AND NOT RepairOrderLaborCosts.Canceled";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableAssetRelevancePeriods(Query, QueryTexts, Registers)
	RegisterName = "AssetRelevancePeriods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT DISTINCT
		|	CASE
		|		WHEN Document.Status IN (VALUE(Enum.RMOrderStatuses.Closed))
		|			THEN Document.ActualCompletionDate
		|		ELSE Document.CompletedOn
		|	END AS Period,
		|	Document.Asset AS Asset
		|FROM
		|	Document.RMOrder AS Document
		|WHERE
		|	Document.Ref = &Ref
		|	AND &Status IN (VALUE(Enum.RMOrderStatuses.ForCompletion), VALUE(Enum.RMOrderStatuses.Running), VALUE(Enum.RMOrderStatuses.Closed))";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref                   AS Ref,
	|	CASE WHEN HeaderData_.StartDate <> DATETIME(1, 1, 1) THEN
	|				HeaderData_.StartDate
	|			ELSE
	|				HeaderData_.Date
	|		END                              AS Period,
	|	GoodsTable.Ref                   AS OrderDocument,
	|	UNDEFINED                           AS Invoice,
	|	FALSE                                   AS Patch,
	|	UNDEFINED                           AS CorrectedDocument,
	|	HeaderData_.Department              AS Recipient,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                  AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.BatchesIndicationStatus	   AS BatchesIndicationStatus,
	|	GoodsTable.Count               AS Count,
	|	FALSE                                   AS ExceedingOrder,
	|	GoodsTable.Canceled                 AS Canceled,
	|	FALSE								   AS ThisIsAnInvoice,
	|	TRUE								   AS ShipmentByOrder
	|FROM
	|	Document.RMOrder.MaterialsAndWorks AS GoodsTable
	|		LEFT JOIN Document.RMOrder AS HeaderData_
	|		ON HeaderData_.Ref = GoodsTable.Ref
	|
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Count <> 0
	|	AND HeaderData_.Status IN(VALUE(Enum.RMOrderStatuses.ForCompletion),
	|							VALUE(Enum.RMOrderStatuses.Running),
	|							VALUE(Enum.RMOrderStatuses.Closed))
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)";
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, QueryText);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref                   AS Ref,
	|	HeaderData_.StartDate                 AS Period,
	|	GoodsTable.Ref                   AS OrderDocument,
	|	UNDEFINED                           AS Invoice,
	|	FALSE                                   AS Patch,
	|	UNDEFINED                           AS CorrectedDocument,
	|	HeaderData_.Department              AS Recipient,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                  AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.BatchesIndicationStatus      AS BatchesIndicationStatus,
	|	GoodsTable.Count               AS Count,
	|	FALSE                                   AS ExceedingOrder,
	|	GoodsTable.Canceled                 AS Canceled,
	|	FALSE                                   AS ThisIsAnInvoice,
	|	TRUE                                 AS ShipmentByOrder
	|FROM
	|	Document.RMOrder.MaterialsAndWorks AS GoodsTable
	|		LEFT JOIN Document.RMOrder AS HeaderData_
	|		ON HeaderData_.Ref = GoodsTable.Ref
	|
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND GoodsTable.Count <> 0
	|
	|	AND HeaderData_.Status IN (
	|		VALUE(Enum.RMOrderStatuses.ForCompletion),
	|		VALUE(Enum.RMOrderStatuses.Running),
	|		VALUE(Enum.RMOrderStatuses.Closed))
	|
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, QueryText);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Department AS StorageLocation,
	|	&Department AS Department,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Author AS Author,
	|	&Comment AS Comment,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	0 AS Sum,
	|	&Status AS Status,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period    AS RecordingInAccountingDate,
	|	&Priority AS Priority";
	
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
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.RMOrderStatuses.ForCompletion),
		|			VALUE(Enum.RMOrderStatuses.Running),
		|			VALUE(Enum.RMOrderStatuses.Closed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND (TabPart.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
		|			OR TabPart.Ref.ThisIsWorksConsumptionOrder)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
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
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	BEGINOFPERIOD(CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.CompletedOn
		|		ELSE TabPart.Ref.StartDate
		|	END, DAY) AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.RMOrder.MaterialsAndWorks AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND TabPart.Ref.Status IN(
		|			VALUE(Enum.RMOrderStatuses.ForCompletion),
		|			VALUE(Enum.RMOrderStatuses.Running),
		|			VALUE(Enum.RMOrderStatuses.Closed))
		|		AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
EndProcedure

#EndRegion

#Region FormationOfHyperlinkInJournalOfDocumentsOfInternalCommodityMovement

Function ThereAreOrdersInProgress(Parameters)
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	RMOrder.Ref AS Ref
		|FROM
		|	Document.RMOrder AS RMOrder
		|WHERE
		|	RMOrder.Posted
		|	AND RMOrder.Status <> VALUE(Enum.InternalOrderStatuses.Closed)");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Update", Metadata.Documents.RMOrder)
			And GetFunctionalOption("UseRMManagement")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Phiếu yêu cầu sửa chữa';
						|ru = 'Заказы на ремонт';
						|en = 'R&M orders'; fa = 'سفارش‌های تعمیر و نگهداری';
						|it = 'Ordini di manutenzione';
						|pl = 'Zamówienia na remont';
						|tr = 'Onarım siparişleri'");
	HyperlinkAnchorText = "Document.RMOrder.Form.DocumentsListForm";
	
	If ThereAreOrdersInProgress(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, HyperlinkAnchorText);
	Else
		Return New FormattedString(HyperlinkText,, StyleColors.EmptyTableField,, HyperlinkAnchorText);
	EndIf;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Other

Function QueryTextDocumentGoods(Filter) Export

	QueryText = 
	"SELECT
	|	Table.Ref                       AS InventoryConsumptionOrder,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	CASE WHEN Table.WithAssignment THEN
	|			Table.Ref.Purpose
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END                                AS Purpose,
	|	CASE 
	|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList THEN
	|			Table.Ref.LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)			
	|	END AS LineOfBusiness,
	|	Table.RowCode                    AS RowCode,
	|	Table.Series                        AS Series,
	|	Table.Count                   AS Count,
	|	Table.Package                     AS Package,
	|	NULL                                 AS DateOfShipment,
	|	TableRepairs.ExpenseItem        AS ExpenseItem,
	|	CASE 
	|		WHEN TableRepairs.ExpenseItem.ExpensesOnAssets
	|			THEN Table.Ref.Asset
	|		WHEN TableRepairs.ExpenseItem.RMOrderExpenses
	|			THEN Table.Ref
	|		ELSE UNDEFINED
	|	END                                AS DimensionOfExpenses,
	|	NULL                                 AS ProductsGroup,
	|	Table.Warehouse                        AS Warehouse,
	|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
	|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered,
	|	VALUE(Catalog.Persons.EmptyRef)             AS Individual,
	|	VALUE(Catalog.OperationCategories.EmptyRef)      AS OperationCategory
	|FROM
	|	Document.RMOrder.MaterialsAndWorks AS Table
	|
	|		LEFT JOIN Document.RMOrder.RM AS TableRepairs
	|		ON Table.Ref = TableRepairs.Ref
	|			AND Table.RMCode = TableRepairs.RMCode
	|
	|		LEFT JOIN TTAccountingData AS DataOfAccounting
	|		ON Table.Ref = DataOfAccounting.InventoryConsumptionOrder
	|			AND Table.RowCode = DataOfAccounting.RowCode
	|WHERE
	|	NOT DataOfAccounting.InventoryConsumptionOrder IS NULL";
	
	If ValueIsFilled(Filter) Then
		
		FilterText1 = "";
		
		For Each KeyValue In Filter Do
			
			Var_Key = KeyValue.Key;
			
			If Var_Key = "Ref" Then
				Var_Key = "Table.Ref";
			ElsIf Var_Key = "Warehouse" Then
				Var_Key = "Table.Warehouse";
			EndIf;
			
			FilterText1 = 
				FilterText1
				+ " "
				+ "And"
				+ " "
				+ Var_Key
				+ " "
				+ "IN(&"
				+ KeyValue.Value
				+ ")";
			
		EndDo;
		
		QueryText = QueryText + Chars.LF + FilterText1;
		
	EndIf;
	
	Return QueryText;

EndFunction

#EndRegion

// Returns a table of acceptable deviations of measured items from the list of orders.
//
//	Parameters:
//		ListOfOrders_ - ValueList, DocumentRef.InventoryConsumptionOrder - the list of orders to determine the allowable deviations
//		InventoryMovementType - EnumRef.InventoryMovementTypes -
//	Returns:
//		ValueTable - table of permissible deviations:
//		* OrderDocument                - DocumentRef.InventoryConsumptionOrder
//		* Products         - CatalogRef.Products
//		* Characteristic       - CatalogRef.ItemsCharacteristics
//		* Series                - CatalogRef.ItemsBatches
//		* AllowableVariance - Number
//
Function PermissibleDeviationsOfMeasuredGoods(ListOfOrders_, InventoryMovementType) Export
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If Not ValueIsFilled(ListOfOrders_) Or AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		Table = New ValueTable;
		Table.Columns.Add("OrderDocument");
		Table.Columns.Add("Products");
		Table.Columns.Add("Characteristic");
		Table.Columns.Add("Series");
		Table.Columns.Add("AllowableVariance");
		Return Table;
	EndIf;
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.RMOrder") Then
		ReferenceArray = New Array();
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	GoodsToReceive.InventoryConsumptionOrder AS OrderDocument,
		|	GoodsToReceive.Products                 AS Products,
		|	GoodsToReceive.Characteristic               AS Characteristic,
		|	GoodsToReceive.Series                        AS Series,
		|	SUM(GoodsToReceive.ToRegisterReceipt
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	AccumulationRegister.InventoryConsumptionOrders.Turnovers(&StartPeriod_,&ConPeriod,, 
		|		InventoryConsumptionOrder IN (&ReferenceArray)) AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	GoodsToReceive.InventoryConsumptionOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Series");
	
	Query.SetParameter("ReferenceArray", ReferenceArray);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("InventoryConsumptionOrders",
		"InventoryConsumptionOrder IN (&ReferenceArray)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.RMOrder, FormDataStructure - a repair order for which you need to get a destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfMaterialAssignmentInRM.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentInRM.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
