#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the shipped quantity according to the data in the "Goods for shipment" accumulation register.
//
// Parameters:
//  Filter - ValueTable - table of products for which you need to get the shipped quantity
//  Adjusting - ValueTable	 - table of products storno
//  OrderWarehousesOnly - Boolean - indicates the calculation of the shipped quantity only in order warehouses.
//
// Returns:
//	ValueTable - table of shipped goods.
//
Function TableDecorated(Filter, Adjusting, OrderWarehousesOnly = False) Export

	RegisterMetadata = Metadata.AccumulationRegisters.GoodsForIssue;
	FilterTable = New ValueTable;
	FilterTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	FilterTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	FilterTable.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	FilterTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	FilterTable.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	FilterTable.Columns.Add("Ref", RegisterMetadata.Dimensions.DocumentShipments.Type);
	CommonClientServer.SupplementTable(Filter, FilterTable);

	Query = New Query();

	// Request for the issued quantity by order.
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Series AS Series,
		|	Table.Warehouse AS Warehouse,
		|	Table.Ref AS DocumentShipments
		|INTO TTSelection
		|FROM
		|	&Filter AS Table
		|;
		|
		|///////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Series AS Series,
		|	Table.Warehouse AS Warehouse,
		|	Table.ToShip AS Count
		|INTO TTAdjustment
		|FROM
		|	&Adjusting AS Table
		|WHERE
		|	Table.ToShip <> 0
		|;
		|
		|///////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.ItemsType AS ItemsType,
		|	Set.Characteristic AS Characteristic,
		|	Set.Purpose AS Purpose,
		|	Set.Series AS Series,
		|	Set.Warehouse AS Warehouse,
		|	SUM(Set.Count) AS Count
		|FROM
		|(SELECT
		|	Table.Products AS Products,
		|	Table.Products.ItemsType AS ItemsType,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Series AS Series,
		|	Table.Warehouse AS Warehouse,
		|	
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN Table.ToShip - Table.AssemblyInProgress - Table.Assembled
		|		ELSE - Table.ToShip + Table.AssemblyInProgress + Table.Assembled
		|	END AS Count
		|FROM
		|	AccumulationRegister.GoodsForIssue AS Table
		|		INNER JOIN TTSelection AS Filter
		|		ON Table.Products = Filter.Products
		|		 AND Table.Characteristic = Filter.Characteristic
		|		 AND Table.Warehouse = Filter.Warehouse
		|		 AND Table.Purpose = Filter.Purpose
		|		 AND Table.Series = Filter.Series
		|		 AND Table.DocumentShipments = Filter.DocumentShipments
		|		 AND Table.DocumentShipments <> Table.Recorder
		|WHERE
		|	Table.Active
		|		AND (Table.ToShip <> 0 OR Table.AssemblyInProgress <> 0 OR Table.Assembled <> 0)
		|		AND &AllWarehouses
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	CAST(Table.Products AS Catalog.Products).ItemsType AS ItemsType,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Series AS Series,
		|	Table.Warehouse AS Warehouse,
		|	-Table.Count AS Count
		|
		|FROM
		|	TTAdjustment AS Table
		|		INNER JOIN TTSelection AS Filter
		|		ON Table.Products = Filter.Products
		|		 AND Table.Characteristic = Filter.Characteristic
		|		 AND Table.Warehouse = Filter.Warehouse
		|		 AND Table.Purpose = Filter.Purpose
		|		 AND Table.Series = Filter.Series) AS Set
		|
		|GROUP BY
		|	Set.Products,
		|	Set.ItemsType,
		|	Set.Characteristic,
		|	Set.Purpose,
		|	Set.Warehouse,
		|	Set.Series
		|HAVING
		|	SUM(Set.Count) > 0
		|";
	
	If OrderWarehousesOnly Then
		Query.Text = StrReplace(Query.Text, "&AllWarehouses",
			"Table.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
			|AND Table.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate");
		Query.SetParameter("CurrentDate", CurrentSessionDate());
	Else
		Query.SetParameter("AllWarehouses", True);
	EndIf;
	
	Query.SetParameter("Adjusting", Adjusting);
	Query.SetParameter("Filter",         FilterTable);
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Table.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	
	Return Table;
	
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
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	SalesNotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Sales");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "f1c69a62-435a-44c4-acfa-89b189b7e4ca";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập chứng từ từ kho';
										|ru = 'Оформление отгрузки со склада';
										|en = 'Registration of shipment from the warehouse'; fa = 'Registration of shipment from the warehouse';
										|it = 'Registration of shipment from the warehouse';
										|pl = 'Registration of shipment from the warehouse';
										|tr = 'Ambardan sevkiyat düzenleme'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.GoodsForIssue.Templates.Notifications_WarehouseOrderRegistration.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã lập chứng từ giao hàng từ kho [Warehouse] [DateOfShipment]. [NotificationSource]';
												|ru = 'Оформлена отгрузка со склада [Warehouse] [DateOfShipment]. [NotificationSource]';
												|en = 'Shipment from the [Warehouse] warehouse dated [DateOfShipment] is registered. [NotificationSource]';
												|it = 'Shipment from the [Warehouse] warehouse dated [DateOfShipment] is registered. [NotificationSource]';
												|pl = 'Shipment from the [Warehouse] warehouse dated [DateOfShipment] is registered. [NotificationSource]';
												|tr = '[Warehouse] [DateOfShipment] ambarından sevkiyat düzenleme. [NotificationSource]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.GoodsForIssue.FullName());
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

// The request text gets a table of goods shipped by orders, but not issued by invoices
// The table is supplemented with the movements made by the invoice specified in the logger parameter.
//
// Parameters:
//  FilterByDimensions	 - Map 
//  	* Key-String-left value: single field or fields separated by commas
//		* Value - Structure - 1. Key: "Type of comparison"; Value - String - comparison operator in the query
//																 2. Key: "Right value"; Value - String - a single field with an ampersand or a query to the table
// 
// Returns:
//  String
//
Function TextOfRequestRemainsToIssue(FilterByDimensions = Undefined) Export
	
	QueryText = 
	"SELECT
	|	Table.DocumentShipments  AS ReferenceOrder,
	|	Table.Products      AS Products,
	|	Table.Characteristic    AS Characteristic,
	|	Table.Purpose        AS Purpose,
	|	Table.Warehouse             AS Warehouse,
	|	Table.Series             AS Series,
	|	Table.ToShipExpense   AS ToShip,
	|	Table.ToRegisterExpense AS ToRegister,
	|	Table.AssembledReceipt     AS Assembled,
	|	Table.AssemblyInProgressReceipt  AS AssemblyInProgress
	|INTO TTRegisterData
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(, , , DocumentShipments IN (&References)
	|	AND &Filter
	|	)AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Set.ReferenceOrder         AS ReferenceOrder,
	|	Set.Products         AS Products,
	|	Set.Characteristic       AS Characteristic,
	|	Set.Purpose           AS Purpose,
	|	Set.Warehouse                AS Warehouse,
	|	Set.Series                AS Series,
	|	SUM(Set.Count)    AS Count,
	|	MAX(Set.AssemblyInProgress) AS AssemblyInProgress
	|FROM
	|	(
	|	SELECT
	|		Table.ReferenceOrder         AS ReferenceOrder,
	|		Table.Products         AS Products,
	|		Table.Characteristic       AS Characteristic,
	|		Table.Purpose           AS Purpose,
	|		Table.Warehouse                AS Warehouse,
	|		Table.Series                AS Series,
	|		Table.ToShip 
	|			+ Table.Assembled        AS Count,
	|		Table.AssemblyInProgress           AS AssemblyInProgress
	|	FROM
	|		TTRegisterData AS Table
	|	WHERE
	|		Table.ToShip 
	|			+ Table.Assembled > 0
	|		
	|	UNION ALL
	|		
	|	SELECT
	|		Table.ReferenceOrder         AS ReferenceOrder,
	|		Table.Products         AS Products,
	|		Table.Characteristic       AS Characteristic,
	|		Table.Purpose           AS Purpose,
	|		Table.Warehouse                AS Warehouse,
	|		Table.Series                AS Series,
	|		-Table.ToRegister         AS Count,
	|		Table.AssemblyInProgress           AS AssemblyInProgress
	|	FROM
	|		TTRegisterData AS Table
	|	WHERE
	|		Table.ToRegister > 0
	|		
	|	UNION ALL
	|		
	|	SELECT
	|		Table.DocumentShipments     AS ReferenceOrder,
	|		Table.Products         AS Products,
	|		Table.Characteristic       AS Characteristic,
	|		Table.Purpose           AS Purpose,
	|		Table.Warehouse                AS Warehouse,
	|		Table.Series                AS Series,
	|		SUM(Table.ToRegister)   AS Count,
	|		MAX(Table.AssemblyInProgress) AS AssemblyInProgress
	|	FROM
	|		AccumulationRegister.GoodsForIssue AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|		AND Table.DocumentShipments IN(&References)
	|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Table.ToRegister > 0
	|		AND Table.Active
	|		AND &Filter
	|
	|	GROUP BY
	|		Table.DocumentShipments,
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.Series,
	|		Table.Warehouse
	|	) AS Set
	|
	|GROUP BY
	|	ReferenceOrder,
	|	Products,
	|	CHARACTERISTIC,
	|	Purpose,
	|	Warehouse,
	|	Series";
	
	FilterText1 = "";
	
	If ValueIsFilled(FilterByDimensions) Then
		
		For Each KeyValue In FilterByDimensions Do
			
			LeftValue  		= KeyValue.Key;
			TypeOfRequestComparison = KeyValue.Value.ComparisonType;
			RightValue 		= KeyValue.Value.RightValue;
			
			FilterText1 = FilterText1 + " And "
						+ "(" + LeftValue + ") " + TypeOfRequestComparison + " (" + RightValue + ")";
			
		EndDo;
		
	EndIf;

	QueryText = StrReplace(QueryText, "AND &Filter", FilterText1);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.GoodsForIssue.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.23.13";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("07ff8c27-2f9f-472b-a205-84b738d4c0e2");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.GoodsForIssue.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang cập nhật bản ghi kết chuyển theo biểu ghi tích lũy ""Hàng cần giao"" cho chứng từ ""Biên bản chênh lệch sau khi nhập hàng"".';
							|ru = 'Обновляет движения по регистру накопления ""Товары к отгрузке"" для документов ""Акт о расхождениях после приемки"".';
							|en = 'Updates register records in the ""Goods to ship"" accumulation register for the ""Receipt discrepancy reports"" documents.'; fa = 'Updates register records in the ""Goods to ship"" accumulation register for the ""Receipt discrepancy reports"" documents.';
							|it = 'Updates register records in the ""Goods to ship"" accumulation register for the ""Receipt discrepancy reports"" documents.';
							|pl = 'Updates register records in the ""Goods to ship"" accumulation register for the ""Receipt discrepancy reports"" documents.';
							|tr = '""Stok farkları raporu"" belgeleri için ""Sevk edilecek mallar"" birikim kaydındaki hareketleri günceller.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.GoodsForIssue.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.GoodsForIssue.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.GoodsForIssue.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.GoodsForIssue.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(DocumentsList, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsForIssue AS RegisterTable
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		ON RegisterTable.Recorder = GoodsTable.Ref
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentTable
	|		ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND DocumentTable.TypeOfBaseDocumentForNonConformanceCertificate <> VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
	|	AND GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= DocumentTable.Date";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.GoodsForIssue.FullName();
	
	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.UpdatedData = Parameters.UpdatedData;
	
	ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(DocumentsList,
																						FullRegisterName,
																						Parameters.Queue,
																						AdditionalParameters);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Function DocumentsToUpdate()
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.DiscrepancyReportFollowingReceipt");
	
	Return DocumentsList;
	
EndFunction

#EndRegion

#EndIf
