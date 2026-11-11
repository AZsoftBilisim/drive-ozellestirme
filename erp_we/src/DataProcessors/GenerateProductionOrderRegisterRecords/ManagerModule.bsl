#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region ItemPlan

Procedure GetItemPlanOnHold(Parameters, StorageAddress) Export

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Generation1 oftransfers: transition k nomenclature by_plan");
	
	PlanPositions = PlanPositionsInsideTimeMeasurement(Parameters);
	
	PutToTempStorage(PlanPositions, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, PlanPositions.Count());
	
EndProcedure

#EndRegion

#Region CreatingDocuments

Procedure CreateDocumentsDeferred(Parameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Generation1 oftransfers: creating documents");
	
	ExecutionResult = CreateDocumentsDeferredInsideTimeMeasurement(Parameters);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ExecutionResult.Documents.Count());
	
EndProcedure

#EndRegion

#Region Other

Function AccessStructure() Export
	
	OptionOfSeparationInMovement = Constants.OptionOfGoodslAssignmentInTransfer.Get();
	
	OptionOfSeparationDuringTransfer  = Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get();
	
	MoveOrderIsAvailable = GetFunctionalOption("UseTransferOrders")
		And OptionOfSeparationInMovement = Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient
		And AccessRight("Insert", Metadata.Documents.TransferOrder);
		
	OrderingMaterialsIsAvailable = GetFunctionalOption("UseProductionManagement2_2")
		And OptionOfSeparationDuringTransfer = Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient
		And AccessRight("Insert", Metadata.Documents.OrderOfMaterialsForProduction);
	
	MovingIsAvailable = GetFunctionalOption("UseGoodsTransfer")
		And AccessRight("Insert", Metadata.Documents.InventoryTransfer);
		
	TransferOfMaterialsIsAvailable = GetFunctionalOption("UseProductionManagement2_2")
		And AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials);
	
	AccessStructure = New Structure;
	AccessStructure.Insert("MoveOrderIsAvailable", MoveOrderIsAvailable);
	AccessStructure.Insert("OrderingMaterialsIsAvailable",    OrderingMaterialsIsAvailable);
	AccessStructure.Insert("MovingIsAvailable",        MovingIsAvailable);
	AccessStructure.Insert("TransferOfMaterialsIsAvailable", TransferOfMaterialsIsAvailable);
	
	Return AccessStructure;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ItemPlan

Procedure NomenclaturePlanInTemporaryTableManager(TempTablesManager, SettingsForSelections) Export

	DataCompositionSchema = DataProcessors.GenerateProductionOrderRegisterRecords.GetTemplate("ItemPlan");
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema);
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema);
	
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(SettingsSource);
	
	SettingsComposer.LoadSettings(SettingsForSelections);
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionSettings = SettingsComposer.GetSettings();
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
		DataCompositionSchema,
		DataCompositionSettings
		,
		,
		,
		,
		False);
		
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(DataCompositionTemplate.DataSets.DataSet.Query);
	
	SelectionRequest = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count()-1];
	SelectionRequest.PlacementTable = "ItemPlan";
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Field = SelectionRequest.Operators[0].SelectedFields.Add(
			"VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
		SelectionRequest.Columns.Find(Field).Alias = "Characteristic";
	EndIf;
	
	QueryText = QuerySchema.GetQueryText();
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	For Each LayoutParameter In DataCompositionTemplate.ParameterValues Do
		Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
	EndDo;
	Query.SetParameter("TheProductionScheduleIsUsed",
		ProductionManagementCached.TheProductionScheduleIsUsed());
	
	Query.Execute();
	
EndProcedure

Function PlanPositionsInsideTimeMeasurement(Parameters)
	
	DataCompositionClientServer.SetParameter(Parameters.Settings, "Period", Parameters.DateOfShipment);
	TempTablesManager = New TempTablesManager();
	
	NomenclaturePlanInTemporaryTableManager(TempTablesManager, Parameters.Settings);

	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"" + Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False) +
	"SELECT
	|	
	|	PP.Products           AS Products,
	|	PP.Characteristic         AS Characteristic,
	|	PP.Purpose             AS Purpose,
	|
	|	PP.DestinationWarehouse        AS DestinationWarehouse,
	|	PP.SourceWarehouse       AS SourceWarehouse,
	|
	|	PP.ProductionOrder    AS ProductionOrder,
	|
	|	PP.StartDate             AS StartDate,
	|	PP.EndDate          AS EndDate,
	|
	|	PP.BillOfMaterials           AS BillOfMaterials,
	|	PP.BillOfMaterials.MainProductProducts AS Product,
	|
	|	PP.Required2              AS Required2,
	|	PP.DateOfReceipt        AS DateOfReceipt,
	|	PP.DateOfReceipt = DATETIME(1, 1, 1) AND PP.Available > 0 AS BalanceIsAvailable,
	|
	|	PP.Available > 0           AS SupplyIsAvailable,
	|	PP.Available               AS Supplied,
	|	PP.Available               AS ForTransfer,
	|	PP.Available               AS ToMoveBeforeChange,
	|	PP.Available > 0           AS Mark,
	|
	|	PP.Products.ItemsType AS ItemsType,
	|
	|	PP.ProductionOrder.Organization             AS Organization,
	|	PP.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|
	|	&QueryTextItemWeight   AS UnitWeight,
	|	&QueryTextTheVolumeOfTheItem AS UnitVolume,
	|	&QueryTextItemWeight * PP.Available AS Weight,
	|	&QueryTextTheVolumeOfTheItem * PP.Available AS VolumeM3,
	|
	|	ISNULL(MainWayToEnsure.ProductionDurationDays, 0) AS TransferDurationDays
	|
	|FROM
	|	ItemPlan AS PP
	|
	|		LEFT JOIN Catalog.ProcurementStrategies AS MainWayToEnsure
	|		ON &MainSupplyMethodSubstitution
	|
	|ORDER BY
	|
	|	PP.ProductionOrder.Priority.AddlOrderingAttribute,
	|	PP.ProductionOrder.Department.AddlOrderingAttribute,
	|	PP.ProductionOrder.Queue,
	|	PP.StartDate
	|
	|";
	
	ConnectionFields = "PP.Products, PP.Characteristic, PP.DestinationWarehouse";
	ParameterName   = "MainSupplyMethodSubstitution";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"PP.Products.UnitOfMeasure",
			"PP.Products"));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"PP.Products.UnitOfMeasure",
			"PP.Products"));
	
	Query.Text = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
		Query.Text, ParameterName, ConnectionFields);
		
	Table = Query.Execute().Unload();
	Return Table;
	
EndFunction

#EndRegion

#Region CreatingDocuments

Function CreateDocumentsDeferredInsideTimeMeasurement(Parameters) Export
	
	Result = New Structure("Documents, Messages", New Array(), New Array());
	
	RegistrationOption = Parameters.RegistrationOption;
	UnloadedTable = Parameters.UnloadedTable; // ValueTable
	
	UnloadedTable.Columns.Add("ShipmentStart", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	UnloadedTable.Columns.Add("ReceiptEnd", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	UnloadedTable.Columns.Add("SupplyOption");
	UnloadedTable.Columns.Add("WithAssignment");
	UnloadedTable.Columns.Add("Count");
	UnloadedTable.Columns.Add("NumberOfPackages");
	
	ShipmentStart = BegOfDay(Parameters.DateOfShipment);
	CurrentDate = BegOfDay(CurrentSessionDate());
	DurationOfDay = 3600 * 24;
	SecurityActionCode = ?(ShipmentStart <> CurrentDate, 
		"ACTION_RESERVATION_REFERENCES", "");
	
	For Each TableRow In UnloadedTable Do
		
		TableRow.WithAssignment = Not TableRow.Purpose.IsEmpty();
		TableRow.ShipmentStart       = ShipmentStart;
		TableRow.ReceiptEnd = ShipmentStart + DurationOfDay * TableRow.TransferDurationDays;
		TableRow.Count = TableRow.ForTransfer;
		TableRow.NumberOfPackages = TableRow.ForTransfer;
		TableRow.SupplyOption = Enums.SupplyOptions.Ship;
		
	EndDo;
	
	KeyFields = "SourceWarehouse,DestinationWarehouse,LineOfBusiness,Organization";
	UnloadedTable.Sort(KeyFields, New CompareValues);
	
	PartitioningResult = SupplyServer.SplitTableByKeyValue(UnloadedTable, KeyFields, KeyFields);
	
	AccessStructure = DataProcessors.TransferOfAssignedGoods.AccessStructure();
	
	Storerooms = New Map();
	Storerooms = Common.ObjectsAttributeValue(UnloadedTable.UnloadColumn("DestinationWarehouse"), "ShopFloorStockroom");
	If RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder Then
		
		For Each Item In PartitioningResult Do
			
			If AccessStructure.OrderingMaterialsIsAvailable And Storerooms.Get(Item.Key.DestinationWarehouse) = True Then
				
				DocumentFillingData = New Structure("Warehouse,ShopFloorStockroom,LineOfBusiness,Organization,Goods");
				DocumentFillingData.Warehouse                   = Item.Key.SourceWarehouse;
				DocumentFillingData.ShopFloorStockroom         = Item.Key.DestinationWarehouse;
				DocumentFillingData.LineOfBusiness = Item.Key.LineOfBusiness;
				DocumentFillingData.Organization             = Item.Key.Organization;
				DocumentFillingData.Goods = Item.Table;
				
				DocumentObject = FillInAndHoldDocument(
					Documents.OrderOfMaterialsForProduction,
					DocumentFillingData,
					Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion,
					Result.Messages,
					SecurityActionCode);
				
			Else
				
				DocumentFillingData = New Structure("SourceWarehouse,DestinationWarehouse,LineOfBusiness,Organization,Goods");
				FillPropertyValues(DocumentFillingData, Item.Key);
				DocumentFillingData.Goods = Item.Table;
				
				DocumentObject = FillInAndHoldDocument(
					Documents.TransferOrder,
					DocumentFillingData,
					Enums.InternalOrderStatuses.ForCompletion,
					Result.Messages,
					SecurityActionCode);
				
			EndIf;
			
			Result.Documents.Add(DocumentObject.Ref);
			PutToTempStorage(Result, Parameters.OrderPlacementResultAddress);
			
		EndDo;
		
	ElsIf RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer Then
		
		For Each Item In PartitioningResult Do
			
			If AccessStructure.TransferOfMaterialsIsAvailable And Storerooms.Get(Item.Key.DestinationWarehouse) = True Then
				
				HeaderAttributes = New Structure;
				HeaderAttributes.Insert("Sender",             Item.Key.SourceWarehouse);
				HeaderAttributes.Insert("Recipient",              Item.Key.DestinationWarehouse);
				HeaderAttributes.Insert("LineOfBusiness", Item.Key.LineOfBusiness);
				HeaderAttributes.Insert("Organization",             Item.Key.Organization);
				HeaderAttributes.Insert("Date",                    CurrentSessionDate());
				HeaderAttributes.Insert("BusinessOperation",   Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
				
				DocumentFillingData = New Structure("HeaderAttributes, Goods", HeaderAttributes, Item.Table);
				
				DocumentObject = FillInAndHoldDocument(
					Documents.MovementOfProductsAndMaterials,
					DocumentFillingData,
					Enums.StatusesOfProductsAndMaterialMovement.Shipped,
					Result.Messages);
				
			Else
				
				DocumentFillingData = New Structure("SourceWarehouse,DestinationWarehouse,LineOfBusiness,Organization,Goods");
				FillPropertyValues(DocumentFillingData, Item.Key);
				DocumentFillingData.Goods = Item.Table;
				
				DocumentObject = FillInAndHoldDocument(
					Documents.InventoryTransfer,
					DocumentFillingData,
					Enums.GoodsTransferStatuses.Shipped,
					Result.Messages);
				
			EndIf;
			
			Result.Documents.Add(DocumentObject.Ref);
			PutToTempStorage(Result, Parameters.OrderPlacementResultAddress);
			
		EndDo;
		
	EndIf;
	
	Return Result;

EndFunction

Function CompositionOfColumnsForCreatingDocuments() Export
	
	Return "
		|DestinationWarehouse,
		|SourceWarehouse,
		|LineOfBusiness,
		|Organization,
		|Products,
		|Characteristic,
		|Purpose,
		|TransferDurationDays";
	
EndFunction

// Fills in and conducts the document created by processing.
//
// Parameters:
//  ManagerOfDocuments - DocumentManager - a software object, the document Manager,
//  FillingData - Structure - Structure containing the values of the details and table parts for filling in the document,
//  Status - Link enumeration.Statusposting of goods, enumerationlink.Statusmovementproduction of materials,
//           Link enumeration.Statusinternational orders, listing link.Statuszakazovmaterialovproduction - the Status
//           in which it is necessary to carry out the document.
//  ErrorsMessages - Structure - contains the resulting error messages about document recording.
//  SecurityActionCode - String - the symbol of the security option.
//
// Returns:
//   DocumentObject.OrderOfMaterialsForProduction     - The completed document created by processing.
//   Document object.Custom Order - A completed document created by processing.
//   Document object.Movement of products and materials - A completed document created by processing.
//   Document object.Moving Goods is a completed document created by processing.
//
Function FillInAndHoldDocument(ManagerOfDocuments, FillingData, Status, ErrorsMessages, SecurityActionCode = "")

	DocumentObject = ManagerOfDocuments.CreateDocument();
	
	FillingData.Insert("Date", CurrentSessionDate());
	FillingData.Insert("Status", Status);

	DocumentObject.Fill(FillingData);
	
	If Not IsBlankString(SecurityActionCode) Then
		
		ActionSettingParameters = New Structure;
		ActionSettingParameters.Insert("UncheckShipByOneDateFlag", False);
		ActionSettingParameters.Insert("FillShippingDateWithSingleDate", True);
		
		ProvisionInDocumentsServer.FillInBalanceProvisionOptionForSelectedObjectRows(
			DocumentObject,
			SecurityActionCode,
			ActionSettingParameters);
	
	EndIf;

	WriteDocument(DocumentObject, ErrorsMessages);

	Return DocumentObject;

EndFunction

Procedure WriteDocument(DocumentObject, ErrorsMessages)

	ErrorsNotDetected = DocumentObject.CheckFilling();

	If Not ErrorsNotDetected Then

		DocumentObject.Write(DocumentWriteMode.Write);
		
		Template = NStr("vi = 'Chưa thực hiện kết chuyển %1 %2 ngày %3';
						|ru = 'Проведение не выполнено %1 %2 от %3';
						|en = 'Cannot post %1 %2 dated %3'; fa = 'Cannot post %1 %2 dated %3';
						|it = 'Проведение не выполнено %1 %2 от %3';
						|pl = 'Cannot post %1 %2 dated %3';
						|tr = 'Kaydetme gerçekleştirilmedi %1 %2/%3'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			DocumentObject.Metadata().Synonym,
			DocumentObject.Number,
			DocumentObject.Date);
		
		Message = New UserMessage;
		Message.Text = Text;
		Message.DataKey = DocumentObject.Ref;
		
		ErrorsMessages.Add(Message);

	Else //there are no errors, we are conducting the document

		Try

			DocumentObject.Write(DocumentWriteMode.Posting);

		Except

			DocumentObject.Write(DocumentWriteMode.Write);
			LogEventName = NStr("vi = 'Tạo chứng từ điều chuyển theo đơn hàng sản xuất';
								|ru = 'Формирование перемещений по заказам на производство';
								|en = 'Generate production order transfers'; fa = 'ایجاد انتقالات سفارش تولید';
								|it = 'Формирование перемещений по заказам на производство';
								|pl = 'Tworzenie przeniesień według zleceń produkcyjnych';
								|tr = 'Üretim emirlerine göre transferlerin oluşturulması'");
			WriteLogEvent(LogEventName, EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

		EndTry;

	EndIf;

	Errors = GetUserMessages(True);
	For Each Error In Errors Do

		Error.DataKey = DocumentObject.Ref;
		ErrorsMessages.Add(Error);

	EndDo;

EndProcedure

#EndRegion

#EndRegion

#EndIf
