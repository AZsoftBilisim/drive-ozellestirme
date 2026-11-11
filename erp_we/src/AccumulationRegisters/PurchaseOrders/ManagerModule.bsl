#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Receives the quantity issued by invoices for orders.
//
// Parameters:
//  FilterTable		 - ValueTable - A table with the "Link" and "codebreak" fields, the rows must be unique.
//  FilterByDimensions	 - Structure - the structure key defines the name of the dimension to be selected for,
//  									and the structure value defines the desired value.
//  ExcludeOrder		 - Boolean - True, exclude
//
// Returns:
//  ValueTable - A table with the fields "Link", "Code strings", "Quantity". For each pair, the Order-line code contains
//                    the quantity issued by invoices.
//
Function TableDecorated(FilterTable, FilterByDimensions = Undefined, ExcludeOrder = False) Export

	QueryText =
		"SELECT
		|	Table.Ref    AS Ref,
		|	Table.RowCode AS RowCode
		|INTO TTSelection
		|FROM
		|	&FilterTable AS Table
		|WHERE
		|	Table.RowCode > 0
		|;
		|
		|//////////////////////////////////
		|SELECT ALLOWED
		|	Filter.RowCode AS RowCode,
		|	Filter.Ref    AS Ref,
		|	MAX(OrderRegister.Products)   AS Products,
		|	MAX(OrderRegister.Characteristic) AS Characteristic,
		|	MAX(OrderRegister.Warehouse)          AS Warehouse,
		|
		|	SUM(CASE WHEN OrderRegister.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|				OrderRegister.ToRegister
		|			ELSE
		|				0
		|		END)           AS Count,
		|	SUM(CASE WHEN OrderRegister.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|				OrderRegister.ToRegister
		|			ELSE
		|				0
		|		END)           AS CountReceipt,
		|	SUM(CASE WHEN OrderRegister.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND OrderRegister.ToRegister < 0 AND NOT Discrepancies.Ref IS NULL THEN
		|				- OrderRegister.ToRegister
		|			ELSE
		|				0
		|		END)           AS NumberAdjustment
		|FROM
		|	TTSelection AS Filter
		|
		|		INNER JOIN AccumulationRegister.PurchaseOrders AS OrderRegister
		|		ON OrderRegister.PurchaseOrder = Filter.Ref
		|		 AND OrderRegister.RowCode = Filter.RowCode
		|		 AND OrderRegister.RecordType = VALUE(AccumulationRecordType.Expense)
		|		 AND OrderRegister.ToRegister <> 0
		|		 AND OrderRegister.Active
		|		 AND &Filter1
		|
		|		LEFT JOIN Document.PurchaseAdjustment.Discrepancies AS Discrepancies
		|		ON Discrepancies.Ref = OrderRegister.Recorder
		|		 AND Discrepancies.PurchaseOrder = OrderRegister.PurchaseOrder
		|		 AND Discrepancies.RowCode = OrderRegister.RowCode
		|		 AND Discrepancies.PostingOption
		|			= VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount)
		|GROUP BY
		|	Filter.Ref, Filter.RowCode";
	
	Query = New Query(QueryText);
	Query.SetParameter("FilterTable", FilterTable);
	
	Filter = New Array;
	If ExcludeOrder Then
		Filter.Add("OrderRegister.PurchaseOrder <> OrderRegister.Recorder");
	EndIf;
	If ValueIsFilled(FilterByDimensions) Then
		For Each KeyValue In FilterByDimensions Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
			Filter.Add("OrderRegister." + KeyValue.Key + " IN(&" + KeyValue.Key + ")");
		EndDo;
	EndIf;
	If ValueIsFilled(Filter) Then
		Query.Text = StrReplace(Query.Text, "AND &Filter1", "And " + StrConcat(Filter, " And "));
	Else	
		Query.Text = StrReplace(Query.Text, "AND &Filter1", "");
	EndIf;
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Table.Indexes.Add("Ref, RowCode");

	Return Table;

EndFunction

// Returns the balance to be processed for the passed list of orders
//
// Parameters:
//  AnArrayOfOrders		 - Array - an array of orders
//  ExcludedInvoice - DocumentRef.InventoryTransfer - An invoice whose movements must be excluded from the result.
// 
// Returns:
//  ValueTable - tables with row codes.
//
Function ToRegisterBalance(AnArrayOfOrders, ExcludedInvoice = Undefined) Export
	
	Query = New Query();
	Query.SetParameter("Orders", AnArrayOfOrders);
	Query.SetParameter("ExcludedInvoice", ExcludedInvoice);
	
	Query.Text =
	"SELECT ALLOWED
	|	Table.ReferenceOrder          AS ReferenceOrder,
	|	Table.Products          AS Products,
	|	Table.Characteristic        AS Characteristic,
	|	Table.Warehouse                 AS Warehouse,
	|	Table.RowCode             AS RowCode,
	|	SUM(Table.Count)     AS Count,
	|	Table.PurchaseOrder       AS PurchaseOrder,
	|	Table.Purpose            AS Purpose
	|FROM
	|	(SELECT
	|		Table.PurchaseOrder AS ReferenceOrder,
	|		Table.Products       AS Products,
	|		Table.Characteristic     AS Characteristic,
	|		Table.RowCode          AS RowCode,
	|		Table.Warehouse              AS Warehouse,
	|		Table.ToRegisterBalance AS Count,
	|		Table.PurchaseOrder    AS PurchaseOrder,
	|		OrderTable.Purpose   AS Purpose
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder IN (&Orders)) AS Table
	|			INNER JOIN Document.PurchaseOrder.Goods AS OrderTable
	|			ON Table.PurchaseOrder = OrderTable.Ref
	|				AND Table.RowCode = OrderTable.RowCode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.PurchaseOrder,
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.RowCode,
	|		Table.Warehouse,
	|		Table.ToRegisterExpense,
	|		Table.PurchaseOrder,
	|		OrderTable.Purpose
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Turnovers(, , Recorder, PurchaseOrder IN (&Orders)) AS Table
	|			INNER JOIN Document.PurchaseOrder.Goods AS OrderTable
	|			ON Table.PurchaseOrder = OrderTable.Ref
	|				AND Table.RowCode = OrderTable.RowCode
	|	WHERE
	|		Table.Recorder = &ExcludedInvoice) AS Table
	|
	|GROUP BY
	|	Table.ReferenceOrder,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.RowCode,
	|	Table.Warehouse,
	|	Table.PurchaseOrder,
	|	Table.Purpose";
	
	OrderLineCodes = Query.Execute().Unload();
	
	Return OrderLineCodes;
	
EndFunction

// The text of the request receives the balance of the resources Ordered, Co-registration, Amount
// The remainder is supplemented by movements made by the invoice specified in the Registrar parameter.
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
	"SELECT ALLOWED
	|	Set.PurchaseOrder     AS PurchaseOrder,
	|	Set.Products        AS Products,
	|	Set.Characteristic      AS Characteristic,
	|	Set.RowCode           AS RowCode,
	|	Set.Warehouse               AS Warehouse,
	|	SUM(Set.Ordered)     AS Ordered,
	|	SUM(Set.ToRegister)  AS ToRegister,
	|	SUM(Set.ToReceive) AS ToReceive,
	|	SUM(Set.Sum)        AS Sum
	|INTO TableName
	|FROM(
	|	SELECT
	|		Table.PurchaseOrder     AS PurchaseOrder,
	|		Table.Products        AS Products,
	|		Table.Characteristic      AS Characteristic,
	|		Table.RowCode           AS RowCode,
	|		Table.Warehouse               AS Warehouse,
	|		Table.OrderedBalance     AS Ordered,
	|		Table.ToRegisterBalance  AS ToRegister,
	|		Table.ToReceiveBalance AS ToReceive,
	|		Table.SumBalance        AS Sum
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(, 
	|			&FilterByDimensions
	|			) AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.PurchaseOrder     AS PurchaseOrder,
	|		Table.Products        AS Products,
	|		Table.Characteristic      AS Characteristic,
	|		Table.RowCode           AS RowCode,
	|		Table.Warehouse               AS Warehouse,
	|		Table.Ordered            AS Ordered,
	|		Table.ToRegister         AS ToRegister,
	|		Table.ToReceive        AS ToReceive,
	|		Table.Sum               AS Sum
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS Table
	|	WHERE
	|		Active
	|		AND Recorder IN(&Recorder)
	|		AND RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND &FilterByDimensions
	|	) AS Set
	|
	|GROUP BY
	|	Set.PurchaseOrder,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.RowCode,
	|	Set.Warehouse
	|
	|,&HAVING";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TempTableName);
		QueryText = QueryText + 
		"
		|
		|INDEX BY
		|	PurchaseOrder,
		|	RowCode";
	Else
		QueryText = StrReplace(QueryText, "INTO TableName", "");
	EndIf;
	
	TextOfSelectionByMeasurements = TMCommonUse.SelectionTextBySelectionCollection(FilterByDimensions);
	QueryText = StrReplace(QueryText, "&FilterByDimensions", TextOfSelectionByMeasurements);
	
	If Not IsBlankString(Expression) Then
		
		If StrFind(Expression, "ToRegister") <> 0 Then
			Expression = StrReplace(Expression, "ToRegister", "SUM(Set.ToRegister)");
		EndIf;
		
		If StrFind(Expression, "ToReceive") <> 0 Then
			Expression = StrReplace(Expression, "ToReceive", "SUM(Set.ToReceive)");
		EndIf;
		
		If StrFind(Expression, "Ordered") <> 0 Then
			Expression = StrReplace(Expression, "Ordered", "SUM(Set.Ordered)");
		EndIf;
		
		If StrFind(Expression, "Sum") <> 0 Then
			Expression = StrReplace(Expression, "Sum", "SUM(Set.Sum)");
		EndIf;
		
		QueryText = StrReplace(QueryText, ",&HAVING", "HAVING " + Expression);
		
	Else
		
		QueryText = StrReplace(QueryText, ",&HAVING", "");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for instructions for registration
// 
// Parameters:
// 	ResourceName - String
// Returns:
// 	String - The text of the request is the temporary tables of the order to be issued.
//
Function QueryTextInstructionsForRegistration(ResourceName) Export

	QueryText =
	"SELECT ALLOWED
	|	References.ReferenceOrder AS ReferenceOrder
	|INTO InstructionsForRegistration
	|FROM
	|	(SELECT
	|		References.PurchaseOrder AS ReferenceOrder,
	|		&ResourceNameBalance                  AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(
	|				,
	|				PurchaseOrder IN (
	|					SELECT
	|						WaybillOrders.ReferenceOrder AS ReferenceOrder
	|					FROM
	|						WaybillOrders AS WaybillOrders)) AS References
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		References.PurchaseOrder AS ReferenceOrder,
	|		CASE
	|			WHEN References.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -&ResourceName
	|			ELSE &ResourceName
	|		END AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS References
	|	WHERE
	|		References.Recorder = &Recorder
	|		AND References.Active
	|		AND References.PurchaseOrder IN (
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
	
	QueryText = StrReplace(QueryText, "&ResourceNameBalance", "References." + ResourceName + "Balance");
	QueryText = StrReplace(QueryText, "&ResourceName",        "References." + ResourceName);
	
	Return QueryText;

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
	|	ValueAllowed(PurchaseOrder.Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(PurchaseOrder.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Purchases");
	NewTypeOfAlerts.Id = "1891dd60-41c2-4180-b00f-003b9916d6df";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập hóa đơn (Mua hàng)';
										|ru = 'Оформление накладной (Закупки)';
										|en = 'Create invoice (Purchasing)'; fa = 'Create invoice (Purchasing)';
										|it = 'Create invoice (Purchasing)';
										|pl = 'Create invoice (Purchasing)';
										|tr = 'İrsaliyenin düzenlenmesi (Satın alımlar)'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.PurchaseOrders.Templates.Notifications_InvoiceRegistration.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Lập hóa đơn. [NotificationSource]';
												|ru = 'Оформлена накладная. [NotificationSource]';
												|en = 'Invoice is registered. [NotificationSource]';
												|it = 'Invoice is registered. [NotificationSource]';
												|pl = 'Invoice is registered. [NotificationSource]';
												|tr = 'İrsaliye düzenlendi. [NotificationSource]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.PurchaseOrders.FullName());
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.PurchaseOrders.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("20d50adc-3f36-456a-b239-9b81f7ec431d");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.PurchaseOrders.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi tích lũy ""Đơn hàng đặt nhà cung cấp"" đối với chứng từ ""Biên bản chênh lệch sau nhập hàng"".';
							|ru = 'Обновляет движения по регистру накопления ""Заказы поставщикам"" для документов ""Акт о расхождениях после приемки"".';
							|en = 'Updates register records in the ""Purchase orders"" accumulation register for the ""Receipt discrepancy reports"" documents.'; fa = 'Updates register records in the ""Purchase orders"" accumulation register for the ""Receipt discrepancy reports"" documents.';
							|it = 'Updates register records in the ""Purchase orders"" accumulation register for the ""Receipt discrepancy reports"" documents.';
							|pl = 'Updates register records in the ""Purchase orders"" accumulation register for the ""Receipt discrepancy reports"" documents.';
							|tr = '""Stok farkları raporu"" belgeleri için ""Satın alma siparişleri"" birikim kaydındaki hareketleri günceller.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.PurchaseOrders.FullName());
	ItemsToRead.Add(Metadata.Catalogs.CounterpartyContracts.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.PurchaseOrders.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.PurchaseOrders.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.PurchaseOrders.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(DocumentsList, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	RegisterName = "PurchaseOrders";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;

	For Each FullDocumentName In DocumentsList Do
	DocumentName	= StrSplit(FullDocumentName, ".")[1];
	QueryTexts	= Documents[DocumentName].DocumentDataForPosting(Undefined, RegisterName, AddlParameters);
	
	RecordersCertificatesAfterAcceptance = DocumentsPosting.CallLoggers(QueryTexts,
																					FullRegisterName,
																					FullDocumentName);
		
	EndDo;

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.PurchaseOrders AS RegisterTable
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		ON RegisterTable.Recorder = GoodsTable.Ref
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentTable
	|		ON RegisterTable.Recorder = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&Recorders)
	|	AND DocumentTable.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
	|	AND NOT DocumentTable.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))";
	
	Query.SetParameter("Recorders", RecordersCertificatesAfterAcceptance);
	
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
	FullRegisterName	= Metadata.AccumulationRegisters.PurchaseOrders.FullName();
	
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

#EndRegion

#EndIf