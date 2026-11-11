#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	
	PurchasingNotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Purchases");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "2ab7588b-52c0-4f03-ad8f-bc5cf8011f9a";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập chứng từ tiếp nhận vào kho';
										|ru = 'Оформление поступления на склад';
										|en = 'Registration of receipt to the warehouse'; fa = 'Registration of receipt to the warehouse';
										|it = 'Registration of receipt to the warehouse';
										|pl = 'Registration of receipt to the warehouse';
										|tr = 'Ambara teslim düzenleme'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.GoodsToReceive.Templates.Notifications_WarehouseOrderRegistration.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã lập chứng từ tiếp nhận vào kho [Warehouse] [DateOfReceipt]. [NotificationSource]';
												|ru = 'Оформлено поступление на склад [Warehouse] [DateOfReceipt]. [NotificationSource]';
												|en = 'Receipt to the [Warehouse] warehouse dated [DateOfReceipt] is registered. [NotificationSource]';
												|it = 'Receipt to the [Warehouse] warehouse dated [DateOfReceipt] is registered. [NotificationSource]';
												|pl = 'Receipt to the [Warehouse] warehouse dated [DateOfReceipt] is registered. [NotificationSource]';
												|tr = '[Warehouse] [DateOfReceipt] ambarına teslim düzenleme. [NotificationSource]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.GoodsToReceive.FullName());
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "bbd413b5-d94e-4ff2-b4bf-94e239fec6a6";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập chứng từ tiếp nhận hàng hóa';
										|ru = 'Оформление поступления товаров';
										|en = 'Goods receipt registration'; fa = 'Goods receipt registration';
										|it = 'Goods receipt registration';
										|pl = 'Goods receipt registration';
										|tr = 'Ürün makbuzunun düzenlenmesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.GoodsToReceive.Templates.Notifications_ReceiptRegistration.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã lập chứng từ tiếp nhận hàng hóa. [NotificationSource]';
												|ru = 'Оформлено поступление товаров. [NotificationSource]';
												|en = 'The goods receipt is registered. [NotificationSource]';
												|it = 'The goods receipt is registered. [NotificationSource]';
												|pl = 'The goods receipt is registered. [NotificationSource]';
												|tr = 'Ürün makbuzunun düzenlenmesi. [NotificationSource]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.GoodsToReceive.FullName());
EndProcedure

#EndRegion

// Calculates the accepted quantity, according to the data of the accumulation register "Goods to be received".
//
// Parameters:
//  Filter - ValueTable - table of products for which you need to get the accepted quantity
//  Adjusting - ValueTable	 - table of products storno
//  OrderWarehousesOnly - Boolean - indicates that the accepted quantity is calculated only in order warehouses.
// 
// Returns:
//  ValueTable - the table of accepted goods.
//
Function TableDecorated(Filter, Adjusting, OrderWarehousesOnly = False) Export

	RegisterMetadata = Metadata.AccumulationRegisters.GoodsToReceive;
	FilterTable = New ValueTable;
	FilterTable.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	FilterTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	FilterTable.Columns.Add("Warehouse",          New TypeDescription("CatalogRef.Warehouses"));
	FilterTable.Columns.Add("Purpose",     New TypeDescription("CatalogRef.Assignments"));
	FilterTable.Columns.Add("Ref",         RegisterMetadata.Dimensions.DocumentInflow.Type);
	CommonClientServer.SupplementTable(Filter, FilterTable);

	Query = New Query();

	// Request for the issued quantity by order.
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Warehouse AS Warehouse,
		|	Table.Ref AS DocumentInflow
		|INTO TTSelection
		|FROM
		|	&Filter AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose,
		|	Table.Warehouse AS Warehouse,
		|	Table.ToReceive AS Count
		|INTO TTAdjustment
		|FROM
		|	&Adjusting AS Table
		|WHERE
		|	Table.ToReceive <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Purpose AS Purpose,
		|	Set.Warehouse AS Warehouse,
		|	SUM(Set.Count) AS Count
		|FROM
		|	(SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Purpose AS Purpose,
		|		Table.Warehouse AS Warehouse,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN Table.GoodsReceiptNotesToRegister - Table.Accepts
		|			ELSE Table.Accepts
		|		END AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive AS Table
		|			INNER JOIN TTSelection AS Filter
		|			ON Table.Products = Filter.Products
		|				AND Table.Characteristic = Filter.Characteristic
		|				AND Table.Warehouse = Filter.Warehouse
		|				AND Table.Purpose = Filter.Purpose
		|				AND Table.DocumentInflow = Filter.DocumentInflow
		|	WHERE
		|		Table.Active
		|		AND (Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|					AND Table.GoodsReceiptNotesToRegister <> 0
		|				OR Table.Accepts <> 0)
		|		AND &AllWarehouses
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products,
		|		Table.Characteristic,
		|		Table.Purpose,
		|		Table.Warehouse,
		|		-Table.Count
		|	FROM
		|		TTAdjustment AS Table
		|			INNER JOIN TTSelection AS Filter
		|			ON Table.Products = Filter.Products
		|				AND Table.Characteristic = Filter.Characteristic
		|				AND Table.Warehouse = Filter.Warehouse
		|				AND Table.Purpose = Filter.Purpose) AS Set
		|
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Purpose,
		|	Set.Warehouse
		|
		|HAVING
		|	SUM(Set.Count) > 0";
	
	If OrderWarehousesOnly Then
		Query.Text = StrReplace(Query.Text, "&AllWarehouses",
			"Table.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
			|AND Table.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate");
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

// Returns the text of the remainder request to the layout
// 
// Parameters:
// 	AddSeriesFromRegistrar - Boolean
// 	FilterByDimensions - Map - selections for the request
// Returns:
// 	String - Query text
Function TextOfRequestRemainsToIssueOrders(AddSeriesFromRegistrar = False, FilterByDimensions = Undefined) Export
	
	If AddSeriesFromRegistrar Then
		
		QueryText = 
		"SELECT
		|	Table.Recorder         AS Recorder,
		|	Table.RecordType         AS RecordType,
		|	Table.DocumentInflow AS ReferenceOrder,
		|	Table.Products        AS Products,
		|	Table.Characteristic      AS Characteristic,
		|	Table.Purpose          AS Purpose,
		|	Table.Warehouse               AS Warehouse,
		|	Table.Series               AS Series,
		|	SUM(Table.ToRegisterGoodsReceipts)  AS Count
		|INTO TTRegisterData
		|FROM
		|	AccumulationRegister.GoodsToReceive AS Table
		|WHERE
		|	Table.DocumentInflow IN(&References)
		|	AND NOT Table.Recorder IN (&Recorder)
		|	AND Table.Active
		|	
		|GROUP BY
		|	Table.Recorder,
		|	Table.RecordType,
		|	Table.DocumentInflow,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.Purpose,
		|	Table.Warehouse,
		|	Table.Products
		|
		|HAVING
		|	SUM(Table.ToRegisterGoodsReceipts) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Ref AS Recorder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series,
		|	SUM(Table.Count) AS Count
		|INTO TTReceiptOrderData
		|FROM Document.GoodsReceiptNote.Goods AS Table
		|WHERE
		|	Table.Ref IN (SELECT T.Recorder FROM TTRegisterData AS T)
		|GROUP BY
		|	Table.Ref,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series
		|;
		|SELECT
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Warehouse,
		|	CASE WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef) THEN
		|		ISNULL(ReceiptDocumentData.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
		|	ELSE
		|		Table.Series
		|	END AS Series,
		|	SUM(CASE WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef) 
		|			AND ReceiptDocumentData.Series <> VALUE(Catalog.ItemsBatches.EmptyRef) THEN
		|		ReceiptDocumentData.Count
		|	ELSE
		|		Table.Count
		|	END) AS Count
		|INTO TTAccepted
		|FROM
		|	TTRegisterData AS Table
		|		LEFT JOIN TTReceiptOrderData AS ReceiptDocumentData
		|		ON Table.Recorder = ReceiptDocumentData.Recorder
		|		AND Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND Table.Products = ReceiptDocumentData.Products
		|		AND Table.Characteristic = ReceiptDocumentData.Characteristic
		|		AND Table.Purpose = ReceiptDocumentData.Purpose
		|		AND (Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			OR Table.Series = ReceiptDocumentData.Series)
		|WHERE
		|	NOT ReceiptDocumentData.Recorder IS NULL
		|		
		|GROUP BY
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	CASE WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef) THEN
		|		ISNULL(ReceiptDocumentData.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
		|	ELSE
		|		Table.Series
		|	END,
		|	Table.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Ref AS Recorder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series,
		|	SUM(Table.Count) AS Count
		|INTO TTReceiptDocumentData
		|FROM Document.InventoryTransfer.Goods AS Table
		|WHERE
		|	Table.Ref IN (SELECT T.Recorder FROM TTRegisterData AS T)
		|	AND Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|GROUP BY
		|	Table.Ref,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series
		|;
		|SELECT
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Warehouse,
		|	CASE WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef) THEN
		|		ReceiptDocumentData.Series
		|	ELSE
		|		Table.Series
		|	END AS Series,
		|	SUM(CASE WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef) THEN
		|		ReceiptDocumentData.Count
		|	ELSE
		|		Table.Count
		|	END) AS Count
		|INTO TTIssued
		|FROM
		|	TTRegisterData AS Table
		|		LEFT JOIN TTReceiptDocumentData AS ReceiptDocumentData
		|		ON Table.Recorder = ReceiptDocumentData.Recorder
		|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND Table.Products = ReceiptDocumentData.Products
		|		AND Table.Characteristic = ReceiptDocumentData.Characteristic
		|		AND Table.Purpose = ReceiptDocumentData.Purpose
		|		AND (Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			OR Table.Series = ReceiptDocumentData.Series)
		|WHERE
		|	NOT ReceiptDocumentData.Recorder IS NULL
		|		
		|
		|GROUP BY
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	CASE WHEN Table.Series = VALUE(Catalog.ItemsBatches.EmptyRef) THEN
		|		ReceiptDocumentData.Series
		|	ELSE
		|		Table.Series
		|	END,
		|	Table.Warehouse
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
		|	SUM(Set.Count)    AS Count
		|FROM
		|	(
		|	SELECT
		|		Table.ReferenceOrder         AS ReferenceOrder,
		|		Table.Products         AS Products,
		|		Table.Characteristic       AS Characteristic,
		|		Table.Purpose           AS Purpose,
		|		Table.Warehouse                AS Warehouse,
		|		Table.Series                AS Series,
		|		Table.Count           AS Count
		|	FROM
		|		TTAccepted AS Table
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
		|		-Table.Count          AS Count
		|	FROM
		|		TTIssued AS Table
		|		
		|	) AS Set
		|
		|GROUP BY
		|	ReferenceOrder,
		|	Products,
		|	CHARACTERISTIC,
		|	Purpose,
		|	Warehouse,
		|	Series";
		
	Else
		
		QueryText = 
		"SELECT
		|	Table.DocumentInflow AS ReferenceOrder,
		|	Table.Products        AS Products,
		|	Table.Characteristic      AS Characteristic,
		|	Table.Purpose          AS Purpose,
		|	Table.Warehouse               AS Warehouse,
		|	Table.Series               AS Series,
		|	Table.ToRegisterGoodsReceiptsExpense   AS ToRegisterExpense,
		|	Table.ToRegisterGoodsReceiptsReceipt   AS ToRegisterReceipt
		|INTO TTRegisterData
		|FROM
		|	AccumulationRegister.GoodsToReceive.Turnovers(, , , DocumentInflow IN (&References)
		|	AND &Filter1
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
		|	SUM(Set.Count)    AS Count
		|FROM
		|	(
		|	SELECT
		|		Table.ReferenceOrder         AS ReferenceOrder,
		|		Table.Products         AS Products,
		|		Table.Characteristic       AS Characteristic,
		|		Table.Purpose           AS Purpose,
		|		Table.Warehouse                AS Warehouse,
		|		Table.Series                AS Series,
		|		Table.ToRegisterReceipt    AS Count
		|	FROM
		|		TTRegisterData AS Table
		|	WHERE
		|		Table.ToRegisterReceipt > 0
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
		|		-Table.ToRegisterExpense   AS Count
		|	FROM
		|		TTRegisterData AS Table
		|	WHERE
		|		Table.ToRegisterExpense > 0
		|		
		|	UNION ALL
		|		
		|	SELECT
		|		Table.DocumentInflow  AS ReferenceOrder,
		|		Table.Products         AS Products,
		|		Table.Characteristic       AS Characteristic,
		|		Table.Purpose           AS Purpose,
		|		Table.Warehouse                AS Warehouse,
		|		Table.Series                AS Series,
		|		SUM(Table.ToRegisterGoodsReceipts) AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive AS Table
		|	WHERE
		|		Table.Recorder IN(&Recorder)
		|		AND Table.DocumentInflow IN(&References)
		|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND Table.ToRegisterGoodsReceipts > 0
		|		AND Table.Active
		|		AND &Filter1
		|
		|	GROUP BY
		|		Table.DocumentInflow,
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
		
	EndIf;
	
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

	QueryText = StrReplace(QueryText, "AND &Filter1", FilterText1);
	
	Return QueryText;
	
EndFunction

// Receives the Balance of the goods actually taken.
// 
// Parameters:
//  References - Array of See AccumulationRegister.GoodsToReceive.DocumentInflow
//  Warehouse - See AccumulationRegister.GoodsToReceive.Warehouse
// Returns:
//  ValueTable - table with fields:
//	* ReferenceOrder - See AccumulationRegister.GoodsToReceive.DocumentInflow
//	* Products - See AccumulationRegister.GoodsToReceive.Products
//	* Characteristic - See AccumulationRegister.GoodsToReceive.Characteristic
//	* Purpose - See AccumulationRegister.GoodsToReceive.Purpose
//	* Warehouse - See AccumulationRegister.GoodsToReceive.Warehouse
//	* Series - See AccumulationRegister.GoodsToReceive.Series
//	* Count - Number - accepted quantity.
//
Function Accepted(References, Warehouse) Export
	
	Query = New Query();
	Query.Text = 
		"SELECT
		|	Table.DocumentInflow AS ReferenceOrder,
		|	Table.Products        AS Products,
		|	Table.Characteristic      AS Characteristic,
		|	Table.Purpose          AS Purpose,
		|	Table.Warehouse               AS Warehouse,
		|	Table.Series               AS Series,
		|	SUM(Table.ToRegisterGoodsReceiptsReceipt) AS Count
		|FROM
		|	AccumulationRegister.GoodsToReceive.Turnovers(, , , DocumentInflow IN (&References)
		|	AND Warehouse = &Warehouse
		|	)AS Table
		|
		|GROUP BY
		|	Table.DocumentInflow,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Warehouse,
		|	Table.Series";
	Query.SetParameter("References", References);
	Query.SetParameter("Warehouse", Warehouse);
	RegisterData = Query.Execute().Unload();
	
	Return RegisterData;
	
EndFunction

// The request text gets the remainder of the resource coformlationaccording to the Distribution
// The remainder is supplemented with movements made by the invoice specified in the logger parameter
//
// Parameters:
//  TempTableName	 - String - Put the result in a temporary table with the specified name. 
//  FilterByDimensions	 - Structure - The key is the name of the dimension, the value is the name of the parameter in the request, for example:
//  									New Structure("Nomenclature", "Product") will be converted in the request text to:
//  									Nomenclature In(&Product)
//  Expression			 - String - A condition for the HAVING by resources section.
//  								For example, a string of the form "Co-form <> 0" will be converted in the query text to:
//  								AMOUNT(Set.Co-registration) <> 0
// 
// Returns:
//  String - Query text
//
Function QueryTextBalance(TempTableName = "", FilterByDimensions = Undefined, Expression = "") Export
	
	QueryText =
	"SELECT
	|	Set.DocumentInflow  AS ReferenceOrder,
	|	Set.Products         AS Products,
	|	Set.Characteristic       AS Characteristic,
	|	Set.Purpose           AS Purpose,
	|	Set.Warehouse                AS Warehouse,
	|	Set.Series                AS Series,
	|	SUM(Set.ToRegister)   AS ToRegister
	|INTO TableName
	|FROM(
	|	SELECT
	|		Table.DocumentInflow                AS DocumentInflow,
	|		Table.Products                       AS Products,
	|		Table.Characteristic                     AS Characteristic,
	|		Table.Purpose                         AS Purpose,
	|		Table.Warehouse                              AS Warehouse,
	|		Table.Series                              AS Series,
	|		Table.ToRegisterInvoicesByReferenceBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(, 
	|			&FilterByDimensions
	|			) AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.DocumentInflow                AS DocumentInflow,
	|		Table.Products                       AS Products,
	|		Table.Characteristic                     AS Characteristic,
	|		Table.Purpose                         AS Purpose,
	|		Table.Warehouse                              AS Warehouse,
	|		Table.Series                              AS Series,
	|		Table.ToRegisterInvoicesByReference AS ToRegister
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS Table
	|	WHERE
	|		Active
	|		AND Recorder = &Recorder
	|		AND RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND &FilterByDimensions
	|	) AS Set
	|
	|GROUP BY
	|	DocumentInflow,
	|	Products,
	|	CHARACTERISTIC,
	|	Purpose,
	|	Warehouse,
	|	Series
	|
	|,&HAVING";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TempTableName);
		QueryText = QueryText + 
		"
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Warehouse";
	Else
		QueryText = StrReplace(QueryText, ",INTO TableName", "");
	EndIf;
	
	TextOfSelectionByMeasurements = TMCommonUse.SelectionTextBySelectionCollection(FilterByDimensions);
	QueryText = StrReplace(QueryText, "&FilterByDimensions", TextOfSelectionByMeasurements);
	
	If Not IsBlankString(Expression) Then
		
		If StrFind(Expression, "ToRegister") <> 0 Then
			Expression = StrReplace(Expression, "ToRegister", "SUM(Set.ToRegister)");
		EndIf;
		
		QueryText = StrReplace(QueryText, ",&HAVING", "HAVING " + Expression);
		
	Else
		
		QueryText = StrReplace(QueryText, ",&HAVING", "");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for instructions for registration
//
// Returns:
//  String - The text of the request is the temporary tables of the order to be issued.
//
Function QueryTextInstructionsForRegistration() Export

	QueryText =
	"SELECT ALLOWED
	|	References.ReferenceOrder AS ReferenceOrder
	|INTO InstructionsForRegistration
	|FROM
	|	(SELECT
	|		References.DocumentInflow                       AS ReferenceOrder,
	|		References.ToRegisterInvoicesByReferenceBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				DocumentInflow IN (
	|					SELECT
	|						WaybillOrders.ReferenceOrder AS ReferenceOrder
	|					FROM
	|						WaybillOrders AS WaybillOrders)) AS References
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		References.DocumentInflow AS ReferenceOrder,
	|		CASE
	|			WHEN References.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -References.ToRegisterInvoicesByReference
	|			ELSE References.ToRegisterInvoicesByReference
	|		END AS ToRegister
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS References
	|	WHERE
	|		References.Recorder = &Recorder
	|		AND References.Active
	|		AND References.DocumentInflow IN (
	|			SELECT
	|				WaybillOrders.ReferenceOrder AS ReferenceOrder
	|			FROM
	|				WaybillOrders AS WaybillOrders)
	|	) AS References
	|
	|GROUP BY
	|	References.ReferenceOrder
	|
	|HAVING
	|	SUM(References.ToRegister) > 0
	|
	|INDEX BY
	|	ReferenceOrder
	|";

	Return QueryText;

EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.GoodsToReceive.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.17";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("d85549cf-a1f0-4528-b3a8-233ea28c8ddf");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.GoodsToReceive.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	
	CommentText1 = New Array;
	CommentText1.Add(NStr("vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi tích lũy ""Hàng hóa cần tiếp nhận"":';
							|ru = 'Обновляет движения по регистру накопления ""Товары к поступлению"":';
							|en = 'Updates register records in the ""Goods to receive"" accumulation register:'; fa = 'Updates register records in the ""Goods to receive"" accumulation register:';
							|it = 'Updates register records in the ""Goods to receive"" accumulation register:';
							|pl = 'Updates register records in the ""Goods to receive"" accumulation register:';
							|tr = '""Alımı yapılacak ürünler"" birikim kaydındaki hareketleri günceller:'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Biên bản chênh lệch sau khi nhập hàng"";';
							|ru = '- для документов ""Акт о расхождениях после приемки"";';
							|en = '- For the ""Receipt discrepancy report"" documents.'; fa = '- For the ""Receipt discrepancy report"" documents.';
							|it = '- For the ""Receipt discrepancy report"" documents.';
							|pl = '- For the ""Receipt discrepancy report"" documents.';
							|tr = '- ""Stok farkları raporu"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Đơn hàng đặt nhà cung cấp"";';
							|ru = '- для документов ""Заказ поставщику"";';
							|en = '- For the ""Purchase order"" documents.'; fa = '- For the ""Purchase order"" documents.';
							|it = '- For the ""Purchase order"" documents.';
							|pl = '- For the ""Purchase order"" documents.';
							|tr = '- ""Satın alma siparişi"" belgeleri için;'"));
	CommentText1.Add(NStr("ru = '- для документов ""Заказ на сборку (разборку);';
							|vi = '- For the Kitting order documents';
							|en = '- For the Kitting order documents'; fa = '- For the Kitting order documents';
							|it = '- For the Kitting order documents';
							|pl = '- For the Kitting order documents';
							|tr = '- ""Montaj (demontaj) emri"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Giấy đề nghị trả hàng từ người mua;';
							|ru = '- для документов ""Заявка на возврат товаров от клиента;';
							|en = '- For the ""Sales return request"" documents.'; fa = '- For the ""Sales return request"" documents.';
							|it = '- For the ""Sales return request"" documents.';
							|pl = '- For the ""Sales return request"" documents.';
							|tr = '- ""Müşterinin ürün iadesi talebi"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Điều chỉnh mua hàng"", khi lập chứng từ mua hàng theo hình thức tách riêng;';
							|ru = '- для документов ""Корректировка приобретения"", при раздельном оформлении закупок;';
							|en = '- For the ""Purchase adjustment"" documents with separate purchase registration.'; fa = '- For the ""Purchase adjustment"" documents with separate purchase registration.';
							|it = '- For the ""Purchase adjustment"" documents with separate purchase registration.';
							|pl = '- For the ""Purchase adjustment"" documents with separate purchase registration.';
							|tr = '- Ayrı satın alma işlemlerinde ""Satın alma düzeltmesi"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Giấy đề nghị trả hàng từ người mua;';
							|ru = '- для документов ""Заявка на возврат товаров от клиента;';
							|en = '- For the ""Sales return request"" documents.'; fa = '- For the ""Sales return request"" documents.';
							|it = '- For the ""Sales return request"" documents.';
							|pl = '- For the ""Sales return request"" documents.';
							|tr = '- ""Müşterinin ürün iadesi talebi"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Tiếp nhận hàng hóa từ nơi cất giữ"";';
							|ru = '- для документов ""Поступление товаров с хранения"";';
							|en = '- For the ""VMI receipt"" documents.'; fa = '- For the ""VMI receipt"" documents.';
							|it = '- For the ""VMI receipt"" documents.';
							|pl = '- For the ""VMI receipt"" documents.';
							|tr = '- ""Depodan irsaliyeler"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Phiếu nhập kho"";';
							|ru = '- для документов ""Приходный ордер на товары"";';
							|en = '- For the ""Goods receipt"" documents.'; fa = '- For the ""Goods receipt"" documents.';
							|it = '- For the ""Goods receipt"" documents.';
							|pl = '- For the ""Goods receipt"" documents.';
							|tr = '- ""Ambar giriş fişi"" belgeleri için;'"));
	CommentText1.Add(NStr("vi = '- đối với các chứng từ ""Sản xuất không theo đơn đặt hàng"";';
							|ru = '- для документов ""Производство без заказа"";';
							|en = '- For the ""Backflush production"" documents.'; fa = '- For the ""Backflush production"" documents.';
							|it = '- For the ""Backflush production"" documents.';
							|pl = '- For the ""Backflush production"" documents.';
							|tr = '- ""Geriye dönük üretim"" belgeleri için;'"));
	Handler.Comment = StrConcat(CommentText1, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ItemsToRead.Add(Metadata.Documents.PurchaseOrder.FullName());
	ItemsToRead.Add(Metadata.Documents.ByAssemblyDisassemblyOrder.FullName());
	ItemsToRead.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName());
	ItemsToRead.Add(Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName());
	ItemsToRead.Add(Metadata.Documents.PurchaseAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.GoodsReceiptNote.FullName());
	ItemsToRead.Add(Metadata.Documents.BackflushProduction.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.GoodsToReceive.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.GoodsToReceive.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.GoodsToReceive.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.GoodsToReceive.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(DocumentsList, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	RegisterName = "GoodsToReceive";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;
	
	QueryTexts = Documents.DiscrepancyReportFollowingReceipt.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	CommonTemporaryTables = New Array();
	Documents.DiscrepancyReportFollowingReceipt.QueryTextDocumentData(CommonTemporaryTables);
	RecordersCertificatesAfterAcceptance = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.DiscrepancyReportFollowingReceipt",
		CommonTemporaryTables);
	
	QueryTexts = Documents.PurchaseAdjustment.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	AcquisitionAdjustmentRecorders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.PurchaseAdjustment");
	
	QueryTexts = Documents.PurchaseOrder.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	RecordersToPurchaseOrder = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.PurchaseOrder");
	
	QueryTexts = Documents.ByAssemblyDisassemblyOrder.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);

	RecordersOfAssemblyOrders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.ByAssemblyDisassemblyOrder");
	
	QueryTexts = Documents.RequestForReturnOfGoodsFromCustomer.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);

	RecordersSalesReturnRequestFromClient = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.RequestForReturnOfGoodsFromCustomer");
	
	QueryTexts = Documents.ReceiptOfGoodsFromCustodian.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);

	RecordersReceiptOfGoodsFromCustodian = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.ReceiptOfGoodsFromCustodian");
	QueryTexts = Documents.BackflushProduction.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	RecordersBackflushedProduction = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.BackflushProduction");
	Query = New Query;
	Query.SetParameter("RecordersCertificatesAfterAcceptance", RecordersCertificatesAfterAcceptance);
	Query.SetParameter("AcquisitionAdjustmentRecorders", AcquisitionAdjustmentRecorders);
	Query.SetParameter("RecordersToPurchaseOrder", RecordersToPurchaseOrder);
	Query.SetParameter("RecordersOfAssemblyOrders", RecordersOfAssemblyOrders);
	Query.SetParameter("RecordersSalesReturnRequestFromClient", RecordersSalesReturnRequestFromClient);
	Query.SetParameter("RecordersReceiptOfGoodsFromCustodian", RecordersReceiptOfGoodsFromCustodian);
	Query.SetParameter("RecordersBackflushedProduction", RecordersBackflushedProduction);
	Query.Text =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsToReceive AS RegisterTable
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		ON RegisterTable.Recorder = GoodsTable.Ref
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentTable
	|		ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersCertificatesAfterAcceptance)
	|	AND GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND DocumentTable.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
	|	AND GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= DocumentTable.Date
	|	AND (NOT GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		OR (GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > DocumentTable.Date))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsToReceive AS RegisterTable
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		ON RegisterTable.Recorder = GoodsTable.Ref
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentTable
	|		ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersCertificatesAfterAcceptance)
	|	AND GoodsTable.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|	AND DocumentTable.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
	|	AND GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= DocumentTable.Date
	|
	|UNION
	|
	// Assembly orders with an invalid value for the period field.
	|SELECT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsToReceive AS RegisterTable
	|	
	|	INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentTable
	|	ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersOfAssemblyOrders)
	|
	|UNION
	|
	|SELECT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsToReceive AS RegisterTable
	|		INNER JOIN Document.PurchaseOrder AS DocumentTable
	|		ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersToPurchaseOrder)
	|	AND DocumentTable.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices),
	|		VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
	|	AND DocumentTable.Status IN (VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
	|		VALUE(Enum.PurchaseOrderStatuses.Closed))
	|
	|UNION
	|
	// Backflushing production with the corrected logic of the formation of movements.
	|SELECT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsToReceive AS RegisterTable
	|	
	|	INNER JOIN Document.BackflushProduction AS DocumentTable
	|	ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersBackflushedProduction)
	|
	|UNION
	|
	// Incoming orders with the Sender field being filled in again.
	|SELECT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GoodsToReceive AS RegisterTable
	|	
	|	INNER JOIN Document.GoodsReceiptNote AS DocumentTable
	|	ON RegisterTable.Recorder = DocumentTable.Ref
	|	
	|	INNER JOIN Document.BackflushProduction AS AttributesBP
	|	ON AttributesBP.Ref = DocumentTable.ReferenceOrder
	|WHERE
	|	NOT DocumentTable.Sender = AttributesBP.Department
	|
	|
	|UNION
	|
	// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
	|SELECT
	|	DocumentTable.Ref AS Recorder
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DocumentTable
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersCertificatesAfterAcceptance)
	|	AND DocumentTable.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
	|
	|UNION
	|
	// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
	|SELECT
	|	DocumentTable.Ref AS Recorder
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&AcquisitionAdjustmentRecorders)
	|	AND DocumentTable.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
	|
	|UNION
	|
	|SELECT
	|	DocumentTable.Ref AS Recorder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentTable
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersSalesReturnRequestFromClient)
	|	AND DocumentTable.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|		VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|
	|UNION
	|
	|SELECT
	|	DocumentTable.Ref AS Recorder
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS DocumentTable
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&RecordersReceiptOfGoodsFromCustodian)
	|	AND NOT DocumentTable.BusinessOperation IN(
	|		 VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|		 VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.GoodsToReceive.FullName();
	
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
	DocumentsList.Add("Document.PurchaseOrder");
	DocumentsList.Add("Document.ByAssemblyDisassemblyOrder");
	DocumentsList.Add("Document.PurchaseAdjustment");
	DocumentsList.Add("Document.RequestForReturnOfGoodsFromCustomer");
	DocumentsList.Add("Document.ReceiptOfGoodsFromCustodian");
	DocumentsList.Add("Document.GoodsReceiptNote");
	DocumentsList.Add("Document.BackflushProduction");
	Return DocumentsList;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
