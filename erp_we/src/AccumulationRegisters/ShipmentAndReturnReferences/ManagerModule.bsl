#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Supply

// Receives the quantity issued by invoices for orders.
//
// Parameters:
// 	FilterTable - ValueTable - A table with the "Link" and "codebreak" fields, the rows must be unique.
// 	FilterByDimensions - Structure - the structure key defines the name of the dimension to be selected for,
//  	and the structure value defines the desired value.
//  ExcludeOrder - Boolean - Flag that excludes the order from the list of issued invoices.
//
// Returns:
//  ValueTable - The table contains the amount of invoices issued:
//   * Ref - DocumentRef
//   * RowCode - Number
//   * Count - Number
//
Function TableDecorated(FilterTable, FilterByDimensions = Undefined, ExcludeOrder = False) Export
	
	TableFormationParameters = NewParametersForCreatingExpandedTable();
	TableFormationParameters.Periodicity = "Recorder";
	TableFormationParameters.ConditionText =
		"(ReferenceOrder, RowCode) IN
		|		(SELECT
		|				Ref,
		|				RowCode
		|			FROM
		|				TTSelection)";
	TableFormationParameters.Group = "Recorder, ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "Issued_1, Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = "ReferenceOrder, RowCode";
	TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
	
	TT_ShipmentOrdersTurnoverExpanded =
		QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.RowCode AS RowCode
	|INTO TTSelection
	|FROM
	|	&FilterTable AS Table
	|WHERE
	|	Table.RowCode > 0
	|
	|"
	+ Common.QueryBatchSeparator()
	+ TT_ShipmentOrdersTurnoverExpanded
	+ Common.QueryBatchSeparator()
	+ "
	|SELECT
	|	Filter.RowCode AS RowCode,
	|	Filter.Ref AS Ref,
	|	MAX(OrdersRegister.Products) AS Products,
	|	MAX(OrdersRegister.Characteristic) AS Characteristic,
	|	MAX(OrdersRegister.Warehouse) AS Warehouse,
	|	MAX(OrdersRegister.Series) AS Series,
	|	SUM(OrdersRegister.ShippedQuantityTurnover) AS Count
	|FROM
	|	TTSelection AS Filter
	|		INNER JOIN TT_ShipmentOrdersTurnoverExpanded AS OrdersRegister
	|		ON OrdersRegister.ReferenceOrder = Filter.Ref
	|		AND OrdersRegister.RowCode = Filter.RowCode
	|		AND &FilterCondition
	|WHERE
	|	&SelectionByTypeOfSalesOrders
	|GROUP BY
	|	Filter.Ref,
	|	Filter.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	Filter.RowCode AS RowCode,
	|	Filter.Ref AS Ref,
	|	MAX(OrdersRegister.Products) AS Products,
	|	MAX(OrdersRegister.Characteristic) AS Characteristic,
	|	MAX(OrdersRegister.Warehouse) AS Warehouse,
	|	MAX(OrdersRegister.Series) AS Series,
	|	SUM(OrdersRegister.IssuedQuantityTurnover) AS Count
	|FROM
	|	TTSelection AS Filter
	|		INNER JOIN TT_ShipmentOrdersTurnoverExpanded AS OrdersRegister
	|		ON OrdersRegister.ReferenceOrder = Filter.Ref
	|		AND OrdersRegister.RowCode = Filter.RowCode
	|		AND &FilterCondition
	|WHERE
	|	NOT &SelectionByTypeOfSalesOrders
	|GROUP BY
	|	Filter.Ref,
	|	Filter.RowCode";
	
	QueryText = StrReplace(QueryText,
		"&SelectionByTypeOfSalesOrders",
		SalesServer.TextOfConditionIsSalesDocument("OrdersRegister.ReferenceOrder"));
	
	Query = New Query(QueryText);
	Query.SetParameter("FilterTable", FilterTable);
	
	Filter = New Array;
	
	If ExcludeOrder Then
		Filter.Add("OrdersRegister.ReferenceOrder <> OrdersRegister.Recorder"); // @query-part
	EndIf;
	
	If ValueIsFilled(FilterByDimensions) Then
		
		For Each KeyValue In FilterByDimensions Do
			
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
			Filter.Add("OrdersRegister."
				+ KeyValue.Key
				+ " IN (&" + KeyValue.Key + ")");
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(Filter) Then
		ReplaceSubstring = StrConcat(Filter, " And ");
	Else
		ReplaceSubstring = "TRUE"; // @query-part
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&FilterCondition",
		ReplaceSubstring);
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Table.Indexes.Add("Ref, RowCode");
	
	Return Table;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Returns a description of access restrictions.
//
// Parameters:
// 	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export 

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(ReferenceOrder.Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(ReferenceOrder.Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.ReferenceOrder.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)";

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
	NewTypeOfAlerts.Id = "1f2c2d2f-d120-42fe-9d9b-2352dfb40657";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập hóa đơn (Bán hàng)';
										|ru = 'Оформление накладной (Продажи)';
										|en = 'Create invoice (Sales)'; fa = 'Create invoice (Sales)';
										|it = 'Create invoice (Sales)';
										|pl = 'Create invoice (Sales)';
										|tr = 'İrsaliyenin düzenlenmesi (Satışlar)'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Templates.Notifications_InvoiceRegistration.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã lập hóa đơn. [NotificationSource]';
												|ru = 'Оформлена накладная. [NotificationSource]';
												|en = 'Invoice is registered. [NotificationSource]';
												|it = 'Invoice is registered. [NotificationSource]';
												|pl = 'Invoice is registered. [NotificationSource]';
												|tr = 'İrsaliye düzenlendi. [NotificationSource]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "88d110fa-0f41-413b-bb39-d955c9220723";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập chứng từ giao hàng cho khách';
										|ru = 'Оформление отгрузки товаров клиенту';
										|en = 'Create goods shipment to customer'; fa = 'Create goods shipment to customer';
										|it = 'Create goods shipment to customer';
										|pl = 'Create goods shipment to customer';
										|tr = 'Müşteriye ürün sevkiyatının düzenlenmesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Templates.Notifications_ShipmentRegistration.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã lập chứng từ giao hàng cho khách. [NotificationSource]';
												|ru = 'Оформлена отгрузка товаров клиенту. [NotificationSource]';
												|en = 'Goods shipment to customer is created. [NotificationSource]';
												|it = 'Goods shipment to customer is created. [NotificationSource]';
												|pl = 'Goods shipment to customer is created. [NotificationSource]';
												|tr = 'Müşteriye ürün sevkiyatı düzenlendi. [NotificationSource]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	
EndProcedure

// The text of the request receives the balance of the resources Fordesign and Ordered
// The remainder is supplemented with movements made by the invoice specified in the logger parameter.
//
// Parameters:
// 	TempTableName - String - Put the result in a temporary table with the specified name. 
// 	FilterByDimensions - Structure - The key is the name of the dimension, the value is the name of the parameter in the request, for example:
// 		New Structure("Nomenclature", "Goods") will be converted in the Query Text to:
// 		"Nomenclature In (&Goods)".
// 	Resources - String - A condition for the HAVING by resources section.
//  	For example, a string of the form "To form <> 0" will be converted in the Query Text to:
//  	"SUM(Set.Co-registration) <> 0".
//
// Returns:
// 	String
//
Function QueryTextBalance(TempTableName = "", FilterByDimensions = Undefined, Resources = "") Export
	
	QueryText =
	"SELECT ALLOWED
	|	Set.ReferenceOrder AS ReferenceOrder,
	|	Set.Products AS Products,
	|	Set.Characteristic AS Characteristic,
	|	Set.RowCode AS RowCode,
	|	Set.Series AS Series,
	|	Set.Warehouse AS Warehouse,
	|	SUM(Set.Ordered) AS Ordered,
	|	SUM(Set.ToRegister) AS ToRegister,
	|	SUM(Set.ToTransfer) AS ToTransfer
	|INTO TableName
	|FROM
	|	(SELECT
	|		Table.ReferenceOrder AS ReferenceOrder,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.RowCode AS RowCode,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		(Table.OrderedQuantityTurnover -
	|			Table.IssuedQuantityTurnover) AS Ordered,
	|		(Table.ForRegistrationQuantityTurnover -
	|			Table.IssuedQuantityTurnover) AS ToRegister,
	|		(Table.QuantityToBeShippedTurnover -
	|			Table.ShippedQuantityTurnover) AS ToTransfer
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS Table
	|	WHERE
	|		(Table.OrderedQuantityTurnover -
	|			Table.IssuedQuantityTurnover) <> 0
	|		OR (Table.ForRegistrationQuantityTurnover -
	|			Table.IssuedQuantityTurnover) <> 0
	|		OR (Table.QuantityToBeShippedTurnover -
	|			Table.ShippedQuantityTurnover) <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.ReferenceOrder AS ReferenceOrder,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.RowCode AS RowCode,
	|		Table.Series AS Series,
	|		Table.Warehouse AS Warehouse,
	|		Table.IssuedQuantity AS Ordered,
	|		Table.IssuedQuantity AS ToRegister,
	|		Table.ShippedQuantity AS ToTransfer
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded AS Table) AS Set
	|GROUP BY
	|	Set.ReferenceOrder,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.RowCode,
	|	Set.Series,
	|	Set.Warehouse
	|HAVING
	|	&FilterHAVING";
	
	TableFormationParameters = NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"&FilterByDimensions";
	TableFormationParameters.Indicators = "Ordered, ToRegister, Issued_1, ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	TableFormationParameters = NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"Active
		|		AND Recorder = &Recorder
		|		AND &FilterByDimensions";
	TableFormationParameters.Indicators = "Issued_1, Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	If Not IsBlankString(TempTableName) Then
		
		QueryText = StrReplace(QueryText,
			"INTO TableName",
			"INTO " + TempTableName); // @query-part-1 @query-part-2
		
		QueryText = QueryText
			+ "
			|
			|INDEX BY
			|	ReferenceOrder,
			|	RowCode"; // @query-part
		
	Else
		QueryText = StrReplace(QueryText, "INTO TableName", ""); // @query-part
	EndIf;
	
	TextOfSelectionByMeasurements = TMCommonUse.SelectionTextBySelectionCollection(FilterByDimensions);
	QueryText = StrReplace(QueryText, "&FilterByDimensions", TextOfSelectionByMeasurements);
	
	If Not IsBlankString(Resources) Then
		
		If StrFind(Resources, "ToRegister") <> 0 Then
			
			Resources = StrReplace(Resources,
				"ToRegister",
				"SUM(ToRegister)"); // @query-part-2
			
		EndIf;
		
		If StrFind(Resources, "Ordered") <> 0 Then
			
			Resources = StrReplace(Resources,
				"Ordered",
				"SUM(Ordered)"); // @query-part-2
			
		EndIf;
		
		If StrFind(Resources, "ToTransfer") <> 0 Then
			
			Resources = StrReplace(Resources,
				"ToTransfer",
				"SUM(ToTransfer)"); // @query-part-2
			
		EndIf;
		
		QueryText = StrReplace(QueryText,
			"&FilterHAVING",
			Resources);
		
	Else
		
		QueryText = StrReplace(QueryText,
			"&FilterHAVING",
			"TRUE");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// The request text gets the remainder of the resources Coformed and Declared
// The remainder is supplemented with movements made by the invoice specified in the logger parameter.
//
// Parameters:
// 	TempTableName - String - Put the result in a temporary table with the specified name. 
// 	FilterByDimensions - Structure - The key is the name of the dimension, the value is the name of the parameter in the request, for example:
//  	New Structure("Nomenclature", "Goods") will be converted in the Query Text to:
//  	"Nomenclature In (&Goods)".
// 	Expression - String - A condition for the HAVING by resources section.
//  	For example, a string of the form "To form <> 0" will be converted in the Query Text to:
//  	"SUM(Set.Co-registration) <> 0".
// 
// Returns:
// 	String - query text.
//
Function QueryTextBalancesOnReturns(TempTableName = "", FilterByDimensions = Undefined, Expression = "") Export
	
	QueryText =
	"SELECT
	|	Set.ReferenceOrder AS PurchaseOrder,
	|	Set.Products AS Products,
	|	Set.Characteristic AS Characteristic,
	|	Set.RowCode AS RowCode,
	|	SUM(Set.Ordered) AS Ordered,
	|	SUM(Set.ToRegister) AS ToRegister
	|INTO TableName
	|FROM
	|	(SELECT
	|		Table.ReferenceOrder AS ReferenceOrder,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.RowCode AS RowCode,
	|		(Table.QuantityRequestedForReturnTurnover
	|			- Table.IssuedByReturnsQuantityTurnover) AS Ordered,
	|		(Table.ForRegistrationOnReturnsQuantityTurnover
	|			- Table.IssuedByReturnsQuantityTurnover) AS ToRegister
	|	FROM
	|		#RequestsForReturnsTurnoverExpanded AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.ReferenceOrder AS ReferenceOrder,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.RowCode AS RowCode,
	|		Table.IssuedByReturnsQuantity AS Ordered,
	|		Table.IssuedByReturnsQuantity AS ToRegister
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded AS Table) AS Set
	|GROUP BY
	|	Set.ReferenceOrder,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.RowCode
	|HAVING
	|	&FilterHAVING";
	
	TableFormationParameters = NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"&FilterByDimensions";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "RequestedForReturn, ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	
	RequestsForReturnsTurnoverExpanded =
		QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#RequestsForReturnsTurnoverExpanded",
		RequestsForReturnsTurnoverExpanded);
	
	TableFormationParameters = NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"Active
		|		AND Recorder IN (&Recorder)
		|		AND &FilterByDimensions";
	TableFormationParameters.Indicators = "RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	If Not IsBlankString(TempTableName) Then
		
		QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TempTableName); // @query-part-1 @query-part-2
		QueryText = QueryText
			+ "
			|
			|INDEX BY
			|	ReferenceOrder,
			|	RowCode"; // @query-part
		
	Else
		QueryText = StrReplace(QueryText, "INTO TableName", ""); // @query-part
	EndIf;
	
	TextOfSelectionByMeasurements = TMCommonUse.SelectionTextBySelectionCollection(FilterByDimensions);
	QueryText = StrReplace(QueryText, "&FilterByDimensions", TextOfSelectionByMeasurements);
	
	If Not IsBlankString(Expression) Then
		
		If StrFind(Expression, "ToRegister") <> 0 Then
			Expression = StrReplace(Expression, "ToRegister", "SUM(Set.ToRegister)"); // @query-part-2
		EndIf;
		If StrFind(Expression, "Ordered") <> 0 Then
			Expression = StrReplace(Expression, "Ordered", "SUM(Set.Ordered)"); // @query-part-2
		EndIf;
		
		QueryText = StrReplace(QueryText,
			"&FilterHAVING",
			Expression);
		
	Else
		
		QueryText = StrReplace(QueryText,
			"&FilterHAVING",
			"TRUE");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the structure of parameters for the selection from the table of revolutions in expanded form.
//
// Returns:
// 	Structure:
// 		* Group - Undefined, String, Array of String - array of dimensions received in the grouping.
// 		* Indicators - Undefined, String, Array of String - array of received indicators.
// 		* Resources - Undefined, String, Array of String - array of resources received.
// 		* Indexes - Undefined, String, Array of String - array of indexes.
// 		* TempTableName - String - the name of the temporary table where the query results are placed.
// 		* PhysicalTable - Boolean - indicates whether a sample is generated from the physical register table.
// 		* ConditionText - String - parameters of the virtual speed table or the text of the condition of the physical table.
// 		* BeginOfPeriod - String - the beginning of the period (for the table of revolutions).
// 		* EndOfPeriod - String - end of the period (for the table of revolutions).
// 		* Periodicity - String - The time fence (for the table of revolutions).
// 		* TableSynonym - String - synonym of the table in the query.
// 		* FormatRequest - Boolean - indicates whether the generated request is formatted.
// 		* OnlyAllowed - Boolean - indicates that only allowed entries are selected.
//
Function NewParametersForCreatingExpandedTable() Export
	
	Result = New Structure;
	Result.Insert("ConditionText", "");
	Result.Insert("Group", Undefined);
	Result.Insert("Indicators", Undefined);
	Result.Insert("Resources", Undefined);
	Result.Insert("Indexes", Undefined);
	Result.Insert("TempTableName", "");
	Result.Insert("PhysicalTable", False);
	Result.Insert("BeginOfPeriod", "");
	Result.Insert("EndOfPeriod", "");
	Result.Insert("Periodicity", "");
	Result.Insert("TableSynonym", "RegisterTable");
	Result.Insert("FormatRequest", False);
	Result.Insert("OnlyAllowed", False);
	
	Return Result;
	
EndFunction

// Returns the text of a subquery or temporary table in expanded form.
//
// Parameters:
// 	TableFormationParameters - See NewParametersForCreatingExpandedTable.
//
// Returns:
// 	String - The text of the temporary table query.
//
Function QueryTextExpandedTable(Val TableFormationParameters) Export
	
	ConditionText = TableFormationParameters.ConditionText;
	Group = TableFormationParameters.Group;
	ArrayOfIndicators = TableFormationParameters.Indicators;
	ArrayOfResources = TableFormationParameters.Resources;
	ArrayOfIndexes = TableFormationParameters.Indexes;
	TempTableName = TableFormationParameters.TempTableName;
	PhysicalTable = TableFormationParameters.PhysicalTable;
	BeginOfPeriod = TableFormationParameters.BeginOfPeriod;
	EndOfPeriod = TableFormationParameters.EndOfPeriod;
	Periodicity = TableFormationParameters.Periodicity;
	TableSynonym = TableFormationParameters.TableSynonym;
	FormatRequest = TableFormationParameters.FormatRequest;
	OnlyAllowed = TableFormationParameters.OnlyAllowed;
	
	CreateArrayOfDimensionFields(Group);
	CreateArrayOfIndexes(ArrayOfIndexes);
	GenerateArrayOfMetrics(ArrayOfIndicators);
	CreateArrayOfResources(ArrayOfResources);
	
	MeasurementText_ = "";
	GroupingText = "";
	ResourcesText = "";
	TextIndex = "";
	FilterByIndicators = "";
	
	// creating a list of indexes
	For Each IndexName In ArrayOfIndexes Do
		
		TextIndex = TextIndex + StrTemplate(
			"%1,
			|",
			IndexName);
		
	EndDo;
	
	If ValueIsFilled(TextIndex) Then
		
		TextIndex = "INDEX BY
			|" + TextIndex; // @query-part
		
	EndIf;
	
	// creating a list of resources
	For Each IndicatorName In ArrayOfIndicators Do
		
		For Each ResourceName In ArrayOfResources Do
			
			DescriptionOfResourceField = DescriptionOfResourceField(
				IndicatorName,
				ResourceName,
				Not PhysicalTable);
			
			ResourcesText = ResourcesText + DescriptionOfResourceField;
			
		EndDo;
		
		FilterByIndicators = FilterByIndicators + StrTemplate(
			"VALUE(%1.%2),
			|",
			Metadata.Enums.IndicatorsOfShipmentAndReturnReferences.FullName(),
			IndicatorName); // @query-part
		
	EndDo;
	
	// creating conditions
	FilterByIndicators = Left(TrimAll(FilterByIndicators), StrLen(TrimAll(FilterByIndicators)) - 1);
	
	If PhysicalTable Then
		
		If ValueIsFilled(ConditionText) Then
			
			ConditionText = StrTemplate("WHERE
				|%1
				|AND #TableSynonym.Factor IN (%2)",
				ConditionText,
				FilterByIndicators); // @query-part
			
		Else
			
			ConditionText = StrTemplate("WHERE
				|#TableSynonym.Factor IN (%1)",
				FilterByIndicators); // @query-part
			
		EndIf;
		
		DataSourceText = TrimAll(StrTemplate(
			"AccumulationRegister.ShipmentAndReturnReferences AS #TableSynonym
			|%1",
			ConditionText)); // @query-part
		
	Else
		
		If ValueIsFilled(ConditionText) Then
			
			ConditionText = ConditionText + StrTemplate("
				|AND Factor IN (%1)",
				FilterByIndicators); // @query-part
			
		Else
			
			ConditionText = StrTemplate(
				"Factor IN (%1)",
				FilterByIndicators); // @query-part
			
		EndIf;
		
		DataSourceText = StrTemplate(
			"AccumulationRegister.ShipmentAndReturnReferences.Turnovers(%1, %2, %3, %4) AS #TableSynonym",
			BeginOfPeriod,
			EndOfPeriod,
			Periodicity,
			ConditionText); // @query-part
		
	EndIf;
	
	// creating a list of selection fields
	For Each GroupItem2 In Group Do
		
		MeasurementText_ = MeasurementText_ + StrTemplate(
			"#TableSynonym.%1 AS %1,
			|",
			GroupItem2); // @query-part
		
		GroupingText = GroupingText + StrTemplate(
			"#TableSynonym.%1,
			|",
			GroupItem2);
		
	EndDo;
	
	ResourcesText = Left(TrimAll(ResourcesText), StrLen(TrimAll(ResourcesText)) - 1);
	GroupingText = Left(TrimAll(GroupingText), StrLen(TrimAll(GroupingText)) - 1);
	TextIndex = Left(TrimAll(TextIndex), StrLen(TrimAll(TextIndex)) - 1);
	TextSelection = ?(OnlyAllowed, "SELECT ALLOWED", "SELECT"); // @query-part-1 @query-part-2
	
	// generating the Query Text
	If ValueIsFilled(TempTableName) Then
		
		QueryText = TrimAll(StrTemplate(
			"%1
			|%2%3
			|INTO %4
			|FROM %5
			|GROUP BY
			|%6
			|%7",
			TextSelection,
			MeasurementText_,
			ResourcesText,
			TempTableName,
			DataSourceText,
			GroupingText,
			TextIndex));
		
	Else
		
		QueryText = TrimAll(StrTemplate(
			"%1
			|%2%3
			|FROM %4
			|GROUP BY
			|%5",
			TextSelection,
			MeasurementText_,
			ResourcesText,
			DataSourceText,
			GroupingText));
		
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"#TableSynonym",
		TableSynonym);
	
	// formatting the Query Text
	If FormatRequest Then
		
		QuerySchema = New QuerySchema();
		QuerySchema.SetQueryText(TrimAll(QueryText));
		Result = QuerySchema.GetQueryText();
		
	Else
		Result = QueryText;
	EndIf;
	
	If Not ValueIsFilled(TempTableName) Then
		Result = "(" + Result + ")";
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the correspondence between control error codes and error template texts.
//
// Returns:
// 	Map of String
//
Function TextsOfTurnoverControlErrorsByIndicators() Export
	
	Result = New Map;
	
	Result.Insert("Ordered",
		TextOfControlError(
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'"),
			NStr("vi = 'đã đặt hàng';
				|ru = 'заказано';
				|en = 'ordered'; fa = 'ordered';
				|it = 'ordered';
				|pl = 'ordered';
				|tr = 'sipariş edildi'")));
	
	Result.Insert("RequestedForReturn",
		TextOfControlError(
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'"),
			NStr("vi = 'đã đề nghị trả lại';
				|ru = 'заявлено на возврат';
				|en = 'requested for return'; fa = 'requested for return';
				|it = 'requested for return';
				|pl = 'requested for return';
				|tr = 'iade talebinde bulunuldu'")));
	
	Result.Insert("ToRegister",
		TextOfControlError(
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'"),
			NStr("vi = 'đã đề nghị lập chứng từ';
				|ru = 'заявлено к оформлению';
				|en = 'requested to register'; fa = 'requested to register';
				|it = 'requested to register';
				|pl = 'requested to register';
				|tr = 'oluşturma talebinde bulunuldu'")));
	
	Result.Insert("ToRegisterForReturns",
		TextOfControlError(
			NStr("vi = 'Đã lập chứng từ trả lại';
				|ru = 'оформлено по возвратам';
				|en = 'registered on returns'; fa = 'registered on returns';
				|it = 'registered on returns';
				|pl = 'registered on returns';
				|tr = 'İadelere göre oluşturuldu'"),
			NStr("vi = 'đã đề nghị lập chứng từ';
				|ru = 'заявлено к оформлению';
				|en = 'requested to register'; fa = 'requested to register';
				|it = 'requested to register';
				|pl = 'requested to register';
				|tr = 'oluşturma talebinde bulunuldu'")));
	
	Result.Insert("ToShip",
		TextOfControlError(
			NStr("vi = 'đã giao hàng';
				|ru = 'отгружено';
				|en = 'shipped'; fa = 'shipped';
				|it = 'shipped';
				|pl = 'shipped';
				|tr = 'sevk edildi'"),
			NStr("vi = 'đã thông báo để giao hàng';
				|ru = 'заявлено к отгрузке';
				|en = 'requested to ship'; fa = 'requested to ship';
				|it = 'requested to ship';
				|pl = 'requested to ship';
				|tr = 'sevkiyat talebinde bulunuldu'")));
	
	Result.Insert("ForReceiving",
		TextOfControlError(
			NStr("vi = 'đã tiếp nhận';
				|ru = 'принято';
				|en = 'accepted'; fa = 'accepted';
				|it = 'accepted';
				|pl = 'accepted';
				|tr = 'kabul edildi'"),
			NStr("vi = 'đã đề nghị tiếp nhận';
				|ru = 'заявлено к приемке';
				|en = 'requested to receive'; fa = 'requested to receive';
				|it = 'requested to receive';
				|pl = 'requested to receive';
				|tr = 'kabul talebinde bulunuldu'")));
	
	Result.Insert("Sales_CShipment",
		TextOfControlError(
			NStr("vi = 'đã đề nghị lập chứng từ';
				|ru = 'заявлено к оформлению';
				|en = 'requested to register'; fa = 'requested to register';
				|it = 'requested to register';
				|pl = 'requested to register';
				|tr = 'oluşturma talebinde bulunuldu'"),
			NStr("vi = 'đã thông báo để giao hàng';
				|ru = 'заявлено к отгрузке';
				|en = 'requested to ship'; fa = 'requested to ship';
				|it = 'requested to ship';
				|pl = 'requested to ship';
				|tr = 'sevkiyat talebinde bulunuldu'")));
	
	Result.Insert("SalesByDesign",
		TextOfControlError(
			NStr("vi = 'đã giao hàng';
				|ru = 'отгружено';
				|en = 'shipped'; fa = 'shipped';
				|it = 'shipped';
				|pl = 'shipped';
				|tr = 'sevk edildi'"),
			NStr("vi = 'đã đề nghị lập chứng từ';
				|ru = 'заявлено к оформлению';
				|en = 'requested to register'; fa = 'requested to register';
				|it = 'requested to register';
				|pl = 'requested to register';
				|tr = 'oluşturma talebinde bulunuldu'")));
	
	Result.Insert("Sales_Shipped",
		TextOfControlError(
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'"),
			NStr("vi = 'đã giao hàng';
				|ru = 'отгружено';
				|en = 'shipped'; fa = 'shipped';
				|it = 'shipped';
				|pl = 'shipped';
				|tr = 'sevk edildi'")));
	
	Result.Insert("Sales_KAcceptance",
		TextOfControlError(
			NStr("vi = 'đã đề nghị tiếp nhận';
				|ru = 'заявлено к приемке';
				|en = 'requested to receive'; fa = 'requested to receive';
				|it = 'requested to receive';
				|pl = 'requested to receive';
				|tr = 'kabul talebinde bulunuldu'"),
			NStr("vi = 'đã giao hàng';
				|ru = 'отгружено';
				|en = 'shipped'; fa = 'shipped';
				|it = 'shipped';
				|pl = 'shipped';
				|tr = 'sevk edildi'")));
	
	Result.Insert("Returns_ReturnRequested",
		TextOfControlError(
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'"),
			NStr("vi = 'đã đề nghị trả lại';
				|ru = 'заявлено на возврат';
				|en = 'requested for return'; fa = 'requested for return';
				|it = 'requested for return';
				|pl = 'requested for return';
				|tr = 'iade talebinde bulunuldu'")));
	
	Result.Insert("Returns_ToReturnProcessing",
		TextOfControlError(
			NStr("vi = 'đã tiếp nhận';
				|ru = 'принято';
				|en = 'accepted'; fa = 'accepted';
				|it = 'accepted';
				|pl = 'accepted';
				|tr = 'kabul edildi'"),
			NStr("vi = 'đã đề nghị lập chứng từ';
				|ru = 'заявлено к оформлению';
				|en = 'requested to register'; fa = 'requested to register';
				|it = 'requested to register';
				|pl = 'requested to register';
				|tr = 'oluşturma talebinde bulunuldu'")));
	
	Result.Insert("ReturnsOnAcceptance",
		TextOfControlError(
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'"),
			NStr("vi = 'đã đề nghị tiếp nhận';
				|ru = 'заявлено к приемке';
				|en = 'requested to receive'; fa = 'requested to receive';
				|it = 'requested to receive';
				|pl = 'requested to receive';
				|tr = 'kabul talebinde bulunuldu'")));
	
	Result.Insert("Returns_IssuedForReturns",
		TextOfControlError(
			NStr("vi = 'đã tiếp nhận';
				|ru = 'принято';
				|en = 'accepted'; fa = 'accepted';
				|it = 'accepted';
				|pl = 'accepted';
				|tr = 'kabul edildi'"),
			NStr("vi = 'đã lập chứng từ';
				|ru = 'оформлено';
				|en = 'registered'; fa = 'registered';
				|it = 'registered';
				|pl = 'registered';
				|tr = 'düzenlendi'")));
	
	Result.Insert("Sales_Completed",
		NStr("vi = 'Theo lệnh %1 đã lập chứng từ với số lượng âm: %2 %3';
			|ru = 'По распоряжению %1 оформлено отрицательное количество: %2 %3';
			|en = 'A negative quantity is registered under the ""%1"" reference: %2 %3'; fa = 'A negative quantity is registered under the ""%1"" reference: %2 %3';
			|it = 'A negative quantity is registered under the ""%1"" reference: %2 %3';
			|pl = 'A negative quantity is registered under the ""%1"" reference: %2 %3';
			|tr = '%1 emir üzerine negatif tutar düzenlenmiştir: %2 %3'"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	#Region ProcessingOfCurrentDocuments
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocuments";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("417c4cfa-4a72-4d6c-8470-db93bd907396");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.RegisterDataOfCurrentDocuments";
	Handler.CheckProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền biểu ghi tích lũy ""Lệnh giao hàng và trả lại""  đối với lệnh thực tế (chưa đóng):
		|- chuyển bản ghi kết chuyển từ biểu ghi tích lũy ""Lệnh giao hàng""
		|- tạo bản ghi kết chuyển theo chỉ tiêu
		|- tính toán trạng thái của các lệnh';
		|ru = 'Заполнение регистра накопления ""Распоряжения на отгрузку и возврат"" для актуальных (незакрытых) распоряжений:
		|- перенос движений из регистра накопления ""Распоряжения на отгрузку""
		|- формирование движений по показателям
		|- вычисление состояний распоряжений';
		|en = 'Fill the ""Shipment and return references"" accumulation register for open references:
		|- Transfer records from the ""Shipment reference"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states'; fa = 'Fill the ""Shipment and return references"" accumulation register for open references:
		|- Transfer records from the ""Shipment reference"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states';
		|it = 'Fill the ""Shipment and return references"" accumulation register for open references:
		|- Transfer records from the ""Shipment reference"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states';
		|pl = 'Fill the ""Shipment and return references"" accumulation register for open references:
		|- Transfer records from the ""Shipment reference"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states';
		|tr = 'Mevcut (kapanmamış) emirler için ""Sevkiyat emirleri ve iade"" birikim kaydının doldurulması:
		| - ""Sevkiyat emirleri"" birikim kaydından hareketlerin aktarılması
		| - Göstergelere göre hareketlerin oluşturulması
		| - Emir durumlarının hesaplanması'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteShipmentReferences.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	Editable1.Add(Metadata.InformationRegisters.ShipmentAndReturnReferencesToFulfill.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.GoodsShipmentFromStorage.FullName());
	ToLock.Add(Metadata.Documents.RegisterAdjustment.FullName());
	ToLock.Add(Metadata.Documents.CustomerInvoice.FullName());
	ToLock.Add(Metadata.Documents.TransferOfGoodsToBailee.FullName());
	ToLock.Add(Metadata.Documents.CustomerInvoiceServices.FullName());
	
	
	ToLock.Add(Metadata.Documents.SubcontractOrder2_5.FullName());
	ToLock.Add(Metadata.Documents.SalesOrder.FullName());
	
	
	ToLock.Add(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	ToLock.Add(Metadata.Documents.ReportToMaterialProvider2_5.FullName());
	ToLock.Add(Metadata.Documents.ProductionStage2_2.FullName());
	ToLock.Add(Metadata.Documents.PurchasingReportToConsignorPrincipal.FullName());
	ToLock.Add(Metadata.Documents.GoodsReceiptFromCustomer.FullName());
	ToLock.Add(Metadata.Documents.SaleAdjustment.FullName());
	
	
	ToLock.Add(Metadata.Documents.WriteOffOfShippedGoods.FullName());
	ToLock.Add(Metadata.Documents.OBEntryGoods.FullName());
	ToLock.Add(Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer.FullName());
	ToLock.Add(Metadata.Documents.GoodsShipmentToCustomer.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfDocumentsReturnRequest";
	NewRow.Order = "Before";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocumentsStorno";
	NewRow.Order = "Before";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataFromIrrelevantDocuments";
	NewRow.Order = "Before";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfIrrelevantDocumentsStorno";
	NewRow.Order = "Before";
	
	#EndRegion
	
	#Region ProcessingReturnRequests
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfDocumentsReturnRequest";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("69925c0b-1bf1-4201-8dfa-273820bfba47");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.RegisterDataOfDocumentsReturnRequest";
	Handler.CheckProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền biểu ghi tích lũy ""Lệnh giao hàng và trả lại"" đối với chứng từ trả lại:
		|- chuyển bản ghi kết chuyển từ biểu ghi tích lũy ""Giấy đề nghị trả hàng từ người mua""
		|- tạo bản ghi kết chuyển theo chỉ tiêu
		|- tính toán trạng thái của lệnh';
		|ru = 'Заполнение регистра накопления ""Распоряжения на отгрузку и возврат"" для документов возврата:
		|- перенос движений из регистра накопления ""Заявки на возврат товаров от клиентов""
		|- формирование движений по показателям
		|- вычисление состояний распоряжений';
		|en = 'Fill the ""Shipment and return references"" accumulation register for return documents:
		|- Transfer records from the ""Sales return requests"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states'; fa = 'Fill the ""Shipment and return references"" accumulation register for return documents:
		|- Transfer records from the ""Sales return requests"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states';
		|it = 'Fill the ""Shipment and return references"" accumulation register for return documents:
		|- Transfer records from the ""Sales return requests"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states';
		|pl = 'Fill the ""Shipment and return references"" accumulation register for return documents:
		|- Transfer records from the ""Sales return requests"" accumulation register
		|- Generate records by indicators
		|- Calculate reference states';
		|tr = 'İade belgeleri için ""Sevkiyat emirleri ve iade"" birikim kaydının doldurulması:
		| - ""Satış iadesi talebi"" birikim kaydından hareketlerin aktarılması
		| - Göstergelere göre hareketlerin oluşturulması
		| - Emir durumlarının hesaplanması'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteRequestsForReturnOfGoodsFromCustomers.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	Editable1.Add(Metadata.InformationRegisters.ShipmentAndReturnReferencesToFulfill.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName());
	ToLock.Add(Metadata.Documents.ReturnOfGoodsFromCustomer.FullName());
	ToLock.Add(Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocuments";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocumentsStorno";
	NewRow.Order = "Before";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataFromIrrelevantDocuments";
	NewRow.Order = "Before";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfIrrelevantDocumentsStorno";
	NewRow.Order = "Before";
	
	#EndRegion
	
	#Region ProcessingOfCurrentDocumentsStorno
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocumentsStorno";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("dfc64e9a-f553-45b3-80a2-8f534e2c26f3");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.RegisterDataOfCurrentDocumentsStorno";
	Handler.CheckProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền biểu ghi tích lũy ""Lệnh giao hàng và trả lại"" đối với các chứng từ Đảo ngược hiện tại';
							|ru = 'Заполнение регистра накопления ""Распоряжения на отгрузку и возврат"" для актуальных документов Сторно';
							|en = 'Fill the ""Shipment and return references"" accumulation register for relevant Storno documents'; fa = 'Fill the ""Shipment and return references"" accumulation register for relevant Storno documents';
							|it = 'Fill the ""Shipment and return references"" accumulation register for relevant Storno documents';
							|pl = 'Fill the ""Shipment and return references"" accumulation register for relevant Storno documents';
							|tr = 'Gerçek belgeler için ""Sevkiyat ve iade siparişleri"" birikim kaydı tablosunun doldurulmasının iptali'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteRequestsForReturnOfGoodsFromCustomers.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteShipmentReferences.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	Editable1.Add(Metadata.InformationRegisters.ShipmentAndReturnReferencesToFulfill.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.ReversingEntry.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocuments";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfDocumentsReturnRequest";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataFromIrrelevantDocuments";
	NewRow.Order = "Before";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfIrrelevantDocumentsStorno";
	NewRow.Order = "Before";
	
	#EndRegion
	
	#Region ProcessingOfIrrelevantDocuments
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataFromIrrelevantDocuments";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("38389743-a028-42e5-b6d5-f75b20ef318e");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.RegisterDataOfIrrelevantDocuments";
	Handler.CheckProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền biểu ghi tích lũy ""Lệnh giao hàng và trả lại"" đối với các lệnh không còn hiệu lực (đã đóng)';
							|ru = 'Заполнение регистра накопления ""Распоряжения на отгрузку и возврат"" для неактуальных (закрытых) распоряжений';
							|en = 'Fill the ""Shipment and return references"" accumulation register for closed references'; fa = 'Fill the ""Shipment and return references"" accumulation register for closed references';
							|it = 'Fill the ""Shipment and return references"" accumulation register for closed references';
							|pl = 'Fill the ""Shipment and return references"" accumulation register for closed references';
							|tr = 'İlgili olmayan (kapalı) siparişler için ""Sevkiyat ve İade Siparişleri"" birikim kaydının doldurulması'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteShipmentReferences.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	Editable1.Add(Metadata.InformationRegisters.ShipmentAndReturnReferencesToFulfill.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.GoodsShipmentFromStorage.FullName());
	ToLock.Add(Metadata.Documents.RegisterAdjustment.FullName());
	ToLock.Add(Metadata.Documents.CustomerInvoice.FullName());
	ToLock.Add(Metadata.Documents.TransferOfGoodsToBailee.FullName());
	ToLock.Add(Metadata.Documents.CustomerInvoiceServices.FullName());
	
	
	ToLock.Add(Metadata.Documents.SubcontractOrder2_5.FullName());
	ToLock.Add(Metadata.Documents.SalesOrder.FullName());
	
	
	ToLock.Add(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	ToLock.Add(Metadata.Documents.ReportToMaterialProvider2_5.FullName());
	ToLock.Add(Metadata.Documents.ProductionStage2_2.FullName());
	ToLock.Add(Metadata.Documents.PurchasingReportToConsignorPrincipal.FullName());
	ToLock.Add(Metadata.Documents.GoodsReceiptFromCustomer.FullName());
	ToLock.Add(Metadata.Documents.SaleAdjustment.FullName());
	
	
	ToLock.Add(Metadata.Documents.WriteOffOfShippedGoods.FullName());
	ToLock.Add(Metadata.Documents.OBEntryGoods.FullName());
	ToLock.Add(Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer.FullName());
	ToLock.Add(Metadata.Documents.GoodsShipmentToCustomer.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocuments";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfDocumentsReturnRequest";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocumentsStorno";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfIrrelevantDocumentsStorno";
	NewRow.Order = "Before";
	
	#EndRegion
	
	#Region ProcessingOfIrrelevantDocumentsStorno
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfIrrelevantDocumentsStorno";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("33e6dc7f-eb64-4461-b829-85b9551d8759");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.RegisterDataOfIrrelevantDocumentsStorno";
	Handler.CheckProcedure = "AccumulationRegisters.ShipmentAndReturnReferences.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền biểu ghi tích lũy ""Lệnh giao hàng và trả lại"" đối với các chứng từ Đảo ngược không còn hiệu lực';
							|ru = 'Заполнение регистра накопления ""Распоряжения на отгрузку и возврат"" для неактуальных документов Сторно';
							|en = 'Fill the ""Shipment and return references"" accumulation register for irrelevant Storno documents'; fa = 'Fill the ""Shipment and return references"" accumulation register for irrelevant Storno documents';
							|it = 'Fill the ""Shipment and return references"" accumulation register for irrelevant Storno documents';
							|pl = 'Fill the ""Shipment and return references"" accumulation register for irrelevant Storno documents';
							|tr = 'Gerçek olmayan belgeler için ""Sevkiyat ve iade siparişleri"" birikim kaydı tablosunun doldurulmasının iptali'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteRequestsForReturnOfGoodsFromCustomers.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.DeleteShipmentReferences.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	Editable1.Add(Metadata.InformationRegisters.ShipmentAndReturnReferencesToFulfill.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.ReversingEntry.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocuments";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfDocumentsReturnRequest";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataOfCurrentDocumentsStorno";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.ShipmentAndReturnReferences.ProcessDataFromIrrelevantDocuments";
	NewRow.Order = "After";
	
	#EndRegion
	
EndProcedure

// Marks the portion of data to be processed.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
// 	DocumentsArray - Array of DocumentRef - array of links to documents.
// 	FullRegisterName - String - the name of the Accumulation register metadata.
//
Procedure MarkPortionForProcessing(Parameters, Val DocumentsArray, Val FullRegisterName)
	
	InfobaseUpdate.MarkRecordersForProcessing(
		Parameters,
		DocumentsArray,
		FullRegisterName);
	
EndProcedure

// Marks all data from the selection for processing.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
// 	SelectionOfDocuments - QueryResultSelection - Selection from the query result.
// 	FullRegisterName - String - the name of the Accumulation register metadata.
//
Procedure MarkDocumentsForProcessing(Parameters, Val SelectionOfDocuments, Val FullRegisterName)
	
	PortionSize = 1000;
	DocumentsArray = New Array;
	
	While SelectionOfDocuments.Next() Do
		
		If DocumentsArray.Count() = PortionSize Then
			
			MarkPortionForProcessing(Parameters, DocumentsArray, FullRegisterName);
			DocumentsArray.Clear();
			
		EndIf;
		
		DocumentsArray.Add(SelectionOfDocuments.Recorder);
		
	EndDo;
	
	If DocumentsArray.Count() Then
		
		MarkPortionForProcessing(Parameters, DocumentsArray, FullRegisterName);
		DocumentsArray.Clear();
		
	EndIf;
	
EndProcedure

// Marks relevant documents for processing.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataOfCurrentDocuments(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.ShipmentAndReturnReferences";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|INTO TableReflectedRecorders
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.ReferenceOrder AS ReferenceOrder
	|INTO TableCurrentOrders
	|FROM
	|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS Table
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.DeleteShipmentReferences AS Table
	|WHERE
	|	Table.Recorder.Ref IS NOT NULL
	|	AND VALUETYPE(Table.Recorder) <> TYPE(Document.RegisterAdjustment)
	|	AND VALUETYPE(Table.Recorder) <> TYPE(Document.ReversingEntry)
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice)
	|	AND Table.Recorder NOT IN
	|		(SELECT
	|			TableReflectedRecorders.Recorder
	|		FROM
	|			TableReflectedRecorders AS TableReflectedRecorders)
	|	AND (Table.ReferenceOrder IN
	|		(SELECT
	|			TableCurrentOrders.ReferenceOrder
	|		FROM
	|			TableCurrentOrders AS TableCurrentOrders)
	|	OR VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).Status <> VALUE(Enum.SalesOrderStatuses.Closed)
	|	OR VALUETYPE(Table.ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
	|	AND NOT CAST(Table.ReferenceOrder AS
	|		Document.RequestForReturnOfGoodsFromCustomer).Status IN (
	|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
	|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)))";
	
	Selection = Query.Execute().Select();
	
	MarkDocumentsForProcessing(Parameters, Selection, FullRegisterName);
	
EndProcedure

// Marks documents for processing.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataOfDocumentsReturnRequest(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.ShipmentAndReturnReferences";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|INTO TableReflectedRecorders
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.DeleteRequestsForReturnOfGoodsFromCustomers AS Table
	|WHERE
	|	Table.Recorder.Ref IS NOT NULL
	|	AND VALUETYPE(Table.Recorder) <> TYPE(Document.RegisterAdjustment)
	|	AND VALUETYPE(Table.Recorder) <> TYPE(Document.ReversingEntry)
	|	AND Table.Recorder NOT IN
	|		(SELECT
	|			TableReflectedRecorders.Recorder
	|		FROM
	|			TableReflectedRecorders AS TableReflectedRecorders)";
	
	Selection = Query.Execute().Select();
	
	MarkDocumentsForProcessing(Parameters, Selection, FullRegisterName);
	
EndProcedure

// Marks documents for processing "Reverse" for current orders.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataOfCurrentDocumentsStorno(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.ShipmentAndReturnReferences";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|INTO TableReflectedRecorders
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|WHERE
	|	VALUETYPE(Table.Recorder) = TYPE(Document.ReversingEntry)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.ReferenceOrder AS ReferenceOrder
	|INTO TableCurrentOrders
	|FROM
	|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS Table
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.DeleteShipmentReferences AS Table
	|WHERE
	|	Table.Recorder.Ref IS NOT NULL
	|	AND VALUETYPE(Table.Recorder) = TYPE(Document.ReversingEntry)
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice)
	|	AND NOT Table.Recorder IN
	|		(SELECT
	|			TableReflectedRecorders.Recorder
	|		FROM
	|			TableReflectedRecorders AS TableReflectedRecorders)
	|	AND (Table.ReferenceOrder IN
	|		(SELECT
	|			TableCurrentOrders.ReferenceOrder
	|		FROM
	|			TableCurrentOrders AS TableCurrentOrders)
	|	OR VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).Status <> VALUE(Enum.SalesOrderStatuses.Closed))
	|
	|UNION
	|
	|SELECT
	|	Table.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.DeleteRequestsForReturnOfGoodsFromCustomers AS Table
	|WHERE
	|	Table.Recorder.Ref IS NOT NULL
	|	AND VALUETYPE(Table.Recorder) = TYPE(Document.ReversingEntry)
	|	AND NOT Table.Recorder IN
	|		(SELECT
	|			TableReflectedRecorders.Recorder
	|		FROM
	|			TableReflectedRecorders AS TableReflectedRecorders)";
	
	Selection = Query.Execute().Select();
	
	MarkDocumentsForProcessing(Parameters, Selection, FullRegisterName);
	
EndProcedure

// Marks irrelevant documents for processing.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataOfIrrelevantDocuments(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.ShipmentAndReturnReferences";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|INTO TableReflectedRecorders
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.ReferenceOrder AS ReferenceOrder
	|INTO TableCurrentOrders
	|FROM
	|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS Table
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.DeleteShipmentReferences AS Table
	|WHERE
	|	Table.Recorder.Ref IS NOT NULL
	|	AND VALUETYPE(Table.Recorder) <> TYPE(Document.RegisterAdjustment)
	|	AND VALUETYPE(Table.Recorder) <> TYPE(Document.ReversingEntry)
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice)
	|	AND Table.Recorder NOT IN
	|		(SELECT
	|			TableReflectedRecorders.Recorder
	|		FROM
	|			TableReflectedRecorders AS TableReflectedRecorders)
	|	AND Table.ReferenceOrder NOT IN
	|		(SELECT
	|			TableCurrentOrders.ReferenceOrder
	|		FROM
	|			TableCurrentOrders AS TableCurrentOrders)
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).Status <> VALUE(Enum.SalesOrderStatuses.Closed))
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
	|	AND NOT CAST(Table.ReferenceOrder AS
	|		Document.RequestForReturnOfGoodsFromCustomer).Status IN (
	|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
	|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)))";
	
	Selection = Query.Execute().Select();
	
	MarkDocumentsForProcessing(Parameters, Selection, FullRegisterName);
	
EndProcedure

// Marks documents for processing "Reverse" for irrelevant orders.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataOfIrrelevantDocumentsStorno(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.ShipmentAndReturnReferences";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|INTO TableReflectedRecorders
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|WHERE
	|	VALUETYPE(Table.Recorder) = TYPE(Document.ReversingEntry)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.ReferenceOrder AS ReferenceOrder
	|INTO TableCurrentOrders
	|FROM
	|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS Table
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.DeleteShipmentReferences AS Table
	|WHERE
	|	Table.Recorder.Ref IS NOT NULL
	|	AND VALUETYPE(Table.Recorder) = TYPE(Document.ReversingEntry)
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice)
	|	AND NOT Table.Recorder IN
	|		(SELECT
	|			TableReflectedRecorders.Recorder
	|		FROM
	|			TableReflectedRecorders AS TableReflectedRecorders)
	|	AND Table.ReferenceOrder NOT IN
	|		(SELECT
	|			TableCurrentOrders.ReferenceOrder
	|		FROM
	|			TableCurrentOrders AS TableCurrentOrders)
	|	AND NOT (VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).Status <> VALUE(Enum.SalesOrderStatuses.Closed))";
	
	Selection = Query.Execute().Select();
	
	MarkDocumentsForProcessing(Parameters, Selection, FullRegisterName);
	
EndProcedure

// Reflects the re-Registered Records of current documents without regard to documents Reversed.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataOfCurrentDocuments(Parameters) Export
	ProcessDataForMigrationToNewVersion(Parameters, True);
EndProcedure

// Reflects the re-Registered Records of the return documents.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataOfDocumentsReturnRequest(Parameters) Export
	ProcessDataForMigrationToNewVersion(Parameters, True);
EndProcedure

// Reflects anew the Registered Records of current documents Reverse.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataOfCurrentDocumentsStorno(Parameters) Export
	ProcessDataForMigrationToNewVersion(Parameters, True);
EndProcedure

// Reflects the re-Registered Records of irrelevant documents without taking into account the documents of the Reverse.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataFromIrrelevantDocuments(Parameters) Export
	ProcessDataForMigrationToNewVersion(Parameters);
EndProcedure

// Reflects the re-Registered Records of irrelevant documents in Reverse.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataOfIrrelevantDocumentsStorno(Parameters) Export
	ProcessDataForMigrationToNewVersion(Parameters);
EndProcedure

// Reflects the re-Registered Records of the newly registered documents in the Accumulation register of the order of shipment and return.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
// 	EnableBusinessLogic - Boolean - indicates whether business logic is enabled when recording a set of register records.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters, EnableBusinessLogic = False) Export
	
	FullRegisterName = Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName();
	RegisterName = Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Name;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue,
			FullRegisterName);
		
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
	
	For Each CurrentData In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.ShipmentAndReturnReferences.RecordSet");
			LockItem.SetValue("Recorder", CurrentData.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Recorder.Set(CurrentData.Recorder);
			
			TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
				CurrentData.Recorder,
				RegisterName);
			
			ThereAreProblematicData = False;
			
			TableName = "Table" + RegisterName;
			If TablesForRegisteredRecords.Property(TableName) Then
				TableRecordset = TablesForRegisteredRecords[TableName];
			Else
				ThereAreProblematicData = True;
			EndIf;
			
			If Not ThereAreProblematicData Then
				
				If TableRecordset.Count() Then
					
					For Each TableRow In TableRecordset Do
						
						If Not ValueIsFilled(TableRow.ReferenceOrder)
							Or Not ValueIsFilled(TableRow.Products) Then
							
							ThereAreProblematicData = True;
							Break;
							
						EndIf;
						
					EndDo;
					
					If Not ThereAreProblematicData Then
						
						RecordSet.Load(TableRecordset);
						InfobaseUpdate.WriteData(RecordSet,, EnableBusinessLogic);
						
					EndIf;
					
				Else
					InfobaseUpdate.MarkProcessingCompletion(RecordSet);
				EndIf;
				
			EndIf;
			
			If ThereAreProblematicData Then
				
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
				InfobaseUpdate.FileIssueWithData(
					CurrentData.Recorder,
					Recommendation,
					Parameters);
					
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), CurrentData.Recorder);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
EndProcedure

// A function for checking objects when opening document forms and before recording.
//
// Parameters:
//  MetadataAndFilter - See InfobaseUpdate.MetadataAndFilterByData.
//
// Returns:
//  Boolean - True if the object is updated and available for modification.
//
Function DataUpdatedForNewApplicationVersion(MetadataAndFilter) Export
	
	ObjectMetadata = MetadataAndFilter.Metadata; // MetadataObject
	If Metadata.Documents.Find(ObjectMetadata.Name) = Undefined Then
		Return True;
	EndIf;
	
	If Common.RefTypeValue(MetadataAndFilter.Filter) Then
		ObjectReference = MetadataAndFilter.Filter;
	Else
		ObjectReference = MetadataAndFilter.Data.Ref;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ObjectReference", ObjectReference);
	Query.Text =
	"SELECT
	|	TRUE
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.ShipmentAndReturnReferences
	|		WHERE
	|			Recorder = &ObjectReference)
	|	AND (TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.DeleteShipmentReferences
	|		WHERE
	|			Recorder = &ObjectReference)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.DeleteRequestsForReturnOfGoodsFromCustomers
	|		WHERE
	|			Recorder = &ObjectReference))";
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfFormationOfExpandedTable

Procedure CreateArrayOfDimensionFields(Group)
	
	If TypeOf(Group) = Type("String") Then
		
		Group = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			Group,,
			True,
			True);
		
	EndIf;
	
	If Not ValueIsFilled(Group) Then
		
		Group = New Array;
		
		For Each Dimension In Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Dimensions Do
			
			If StrStartsWith(Dimension.Name, "Delete")
				Or Dimension.Name = "Factor" Then
				Continue;
			EndIf;
			
			Group.Add(Dimension.Name);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CreateArrayOfIndexes(ArrayOfIndexes)
	
	If TypeOf(ArrayOfIndexes) = Type("String") Then
		
		ArrayOfIndexes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			ArrayOfIndexes,,
			True,
			True);
		
	EndIf;
	
	If Not ValueIsFilled(ArrayOfIndexes) Then
		ArrayOfIndexes = New Array;
	EndIf;
	
EndProcedure

Procedure GenerateArrayOfMetrics(ArrayOfIndicators)
	
	If TypeOf(ArrayOfIndicators) = Type("String") Then
		
		ArrayOfIndicators = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			ArrayOfIndicators,,
			True,
			True);
			
	EndIf;
	
	If Not ValueIsFilled(ArrayOfIndicators) Then
		
		ArrayOfIndicators = New Array;
		
		For Each EnumerationValue In Metadata.Enums.IndicatorsOfShipmentAndReturnReferences.EnumValues Do
			ArrayOfIndicators.Add(EnumerationValue.Name);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CreateArrayOfResources(ArrayOfResources)
	
	If TypeOf(ArrayOfResources) = Type("String") Then
		
		ArrayOfResources = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			ArrayOfResources,,
			True,
			True);
		
	EndIf;
	
	If Not ValueIsFilled(ArrayOfResources) Then
		
		ArrayOfResources = New Array;
		
		For Each Resource In Metadata.AccumulationRegisters.ShipmentAndReturnReferences.Resources Do
			
			If Not StrStartsWith(Resource.Name, "Delete") Then
				ArrayOfResources.Add(Resource.Name);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function DescriptionOfResourceField(IndicatorName, ResourceName, Turnover)
	
	Result =
	"SUM(CASE
	|	WHEN #TableSynonym.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.[Factor])
	|		THEN #TableSynonym.[TableFieldName]
	|	ELSE 0
	|END) AS [NameOfSelectionField],
	|"; // @query-part
	
	SelectionFieldNames = ReferenceManagementCached.SelectionFieldNames(IndicatorName, ResourceName, Turnover);
	
	TemplateParameters = New Structure;
	TemplateParameters.Insert("Factor", IndicatorName);
	TemplateParameters.Insert("TableFieldName", SelectionFieldNames.TableFieldName);
	TemplateParameters.Insert("NameOfSelectionField", SelectionFieldNames.NameOfSelectionField);
	Result = StringFunctionsClientServer.InsertParametersIntoString(Result, TemplateParameters);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

// Generates the text of the control error message based on the set of transmitted actions.
//
// Returns:
// 	String
//
Function TextOfControlError(Action1, Action2)
	
	Return StrTemplate(
		NStr("vi = 'Theo lệnh %%1 %1 nhiều hơn %2, %%2 %%3';
			|ru = 'По распоряжению %%1 %1 больше, чем %2, на %%2 %%3';
			|en = 'Under the %%1 reference, %1 is greater than %2 by %%2 %%3'; fa = 'Under the %%1 reference, %1 is greater than %2 by %%2 %%3';
			|it = 'Under the %%1 reference, %1 is greater than %2 by %%2 %%3';
			|pl = 'Under the %%1 reference, %1 is greater than %2 by %%2 %%3';
			|tr = 'Siparişe göre %%1 %1, %2 değerinden %%2 %%3 daha fazladır'"),
		Action1,
		Action2);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
