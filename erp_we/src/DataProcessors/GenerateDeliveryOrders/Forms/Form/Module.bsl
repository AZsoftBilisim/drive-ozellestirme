// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object.Direction = Enums.DeliveryDirections.PartnerWarehouse_;
	FilterDate = CurrentSessionDate();
	Object.ShipmentDateFrom = FilterDate;
	Object.ShipmentPeriod.EndDate = FilterDate;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		
		CommonClientServer.SetFormItemProperty(Items, "Organization", "Visible", False);
		
	EndIf;
	
	SpecifySenderRecipientTypes();
	SubstituteExpressionsWeightVolume();
	InitializeAdditionalListProperties();
	
	AddressDetailsForRegistration = PutToTempStorage(Undefined, UUID);
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	InitializeListSelections();
	
	CurrentDirection = Object.Direction;
	CurrentSender = Object.Sender;
	CurrentRecipient = Object.Recipient;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DirectionOnChange(Item)
	
	If Object.Direction = CurrentDirection Then
		Return;
	EndIf;
	
	SpecifySenderRecipientTypes();
	
	Lists = AllLists();
	SetSelectionBySender(ThisObject, Lists, Object.Sender);
	SetSelectionByRecipient(ThisObject, Lists, Object.Recipient);
	
	CurrentDirection = Object.Direction;
	CurrentSender = Object.Sender;
	CurrentRecipient = Object.Recipient;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	Lists = AllLists();
	SetSelectionByOrganization(ThisObject, Lists, Object.Organization);
	
EndProcedure

&AtClient
Procedure SenderOnChange(Item)
	
	If Object.Sender = CurrentSender Then
		Return;
	EndIf;
	
	Lists = AllLists();
	SetSelectionBySender(ThisObject, Lists, Object.Sender);
	
	CurrentSender = Object.Sender;
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	If Object.Recipient = CurrentRecipient Then
		Return;
	EndIf;
	
	Lists = AllLists();
	SetSelectionByRecipient(ThisObject, Lists, Object.Recipient);
	
	CurrentRecipient = Object.Recipient;
	
EndProcedure

&AtClient
Procedure ShipmentPeriodEndDateOnChange(Item)
	
	Lists = BalanceLists();
	SetSelectionByShipmentPeriod(ThisObject, Lists, Object.ShipmentPeriod);
	
EndProcedure

&AtClient
Procedure ShipmentDateFromOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetSelectionByDateOfShipmentOfOrders(ListOfDeliveryOrders, Object.ShipmentDateFrom);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PageOnDocuments Then
		Items.ListByDocumentsCreateDeliveryOrder.DefaultButton = True;
	Else
		Items.ListByItemCreateDeliveryOrder.DefaultButton = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListByItem

&AtServerNoContext
Procedure ListByItemOnGetDataAtServer(TagName, Settings, Rows)
	
	ListOnGetDataAtServer(TagName, Settings, Rows);
	
EndProcedure

&AtClient
Procedure ListByItemDragStart(Item, DragParameters, Perform)
	
	StartDragList(Item, DragParameters, Perform);
	
EndProcedure

&AtClient
Procedure ListByItemOnActivateRow(Item)
	
	DetachIdleHandler("GoodsListUpdateAdditionalParameters");
	AttachIdleHandler("GoodsListUpdateAdditionalParameters", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListByDocuments

&AtServerNoContext
Procedure ListByDocumentsOnGetDataAtServer(TagName, Settings, Rows)
	
	ListOnGetDataAtServer(TagName, Settings, Rows);
	
EndProcedure

&AtClient
Procedure ListByDocumentsDragStart(Item, DragParameters, Perform)
	
	StartDragList(Item, DragParameters, Perform);
	
EndProcedure

&AtClient
Procedure ListByDocumentsOnActivateRow(Item)
	
	DetachIdleHandler("ListOfDocumentsUpdateAdditionalParameters");
	AttachIdleHandler("ListOfDocumentsUpdateAdditionalParameters", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfDeliveryOrders

&AtClient
Procedure ListOfDeliveryOrdersDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If ValueIsFilled(String)
	   And TypeOf(String) = Type("DocumentRef.DeliveryOrder") Then
		
		DragParameters.Action = DragAction.Move;
		
	Else
		
		DragParameters.Action = DragAction.Cancel;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Item - FormTable
//  DragParameters - DragParameters:
//   * Value - Array of See DeliverListLineData
//  StandardProcessing - Boolean
//  String - DocumentRef.DeliveryOrder
//  Field - FormField
//
&AtClient
Async Procedure ListOfDeliveryOrdersDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If TypeOf(DragParameters.Value) <> Type("Array") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(String)
	 Or TypeOf(String) <> Type("DocumentRef.DeliveryOrder") Then
		Return;
	EndIf;
	
	OrderPresentation = String(String);
	QuestionTemplate = NStr("ru = 'Документ ""%1"" будет дополнен выбранными данными. Продолжить?';
							|vi = 'The ""%1"" document will be supplemented with the selected data. Continue?';
							|en = 'The ""%1"" document will be supplemented with the selected data. Continue?'; fa = 'The ""%1"" document will be supplemented with the selected data. Continue?';
							|it = 'The ""%1"" document will be supplemented with the selected data. Continue?';
							|pl = 'The ""%1"" document will be supplemented with the selected data. Continue?';
							|tr = '""%1"" belgesi seçilen verilerle doldurulacaktır. Devam edilsin mi?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTemplate, OrderPresentation);
	NotificationTemplate = NStr("ru = 'Данные успешно добавлены в документ ""%1""';
								|vi = 'The data is successfully added to the ""%1"" document';
								|en = 'The data is successfully added to the ""%1"" document'; fa = 'The data is successfully added to the ""%1"" document';
								|it = 'The data is successfully added to the ""%1"" document';
								|pl = 'The data is successfully added to the ""%1"" document';
								|tr = 'Veriler ""%1"" belgesine başarıyla eklendi.'");
	NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(NotificationTemplate, OrderPresentation);
	
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	If Response = DialogReturnCode.Yes Then
		
		Measurement = PerformanceMonitorClient.StartTimeConsumingOperationMeasurement(
			"DataProcessor.GenerateDeliveryOrders.Form.ListOfDeliveryOrdersDrag");
		CompleteOrderATServer(String, DragParameters.Value);
		PerformanceMonitorClient.FixTimeConsumingOperationMeasure(
			Measurement, DragParameters.Value.Count(), "CompleteOrderATServer");
		
		NotifyChanged(String);
		NotifyChanged(Type("AccumulationRegisterRecordKey.Delivery"));
		
		URL = GetURL(String);
		ShowUserNotification(
			NStr("ru = 'Изменение';
				|vi = 'Change';
				|en = 'Change'; fa = 'تغییر';
				|it = 'Change';
				|pl = 'Change';
				|tr = 'Değişiklik'"),
			URL,
			NotificationText1,
			PictureLib.Information32);
		PerformanceMonitorClient.EndTimeConsumingOperationMeasurement(Measurement, 1, "LastStep");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Async Procedure CreateDeliveryOrder(Command)
	
	If Items.GroupPages.CurrentPage = Items.ItemPageByGoods Then
		
		ListName = "ListByItem";
		SelectedRows = Items.ListByItem.SelectedRows;
		
	ElsIf Items.GroupPages.CurrentPage = Items.PageOnDocuments Then
		
		ListName = "ListByDocuments";
		SelectedRows = Items.ListByDocuments.SelectedRows;
		
	Else
		
		Raise NStr("ru = 'Не определен активный список для получения выделенных строк';
					|vi = 'No active list is defined for getting the selected rows';
					|en = 'No active list is defined for getting the selected rows'; fa = 'No active list is defined for getting the selected rows';
					|it = 'No active list is defined for getting the selected rows';
					|pl = 'No active list is defined for getting the selected rows';
					|tr = 'Seçili satırları almak için etkin liste tanımlanmamış'");
		
	EndIf;
	
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(, NStr("ru = 'Не выбраны строки для создания заказа на доставку.';
								|vi = 'Lines for creating a delivery order are not selected.';
								|en = 'Lines for creating a delivery order are not selected.'; fa = 'Lines for creating a delivery order are not selected.';
								|it = 'Lines for creating a delivery order are not selected.';
								|pl = 'Lines for creating a delivery order are not selected.';
								|tr = 'Teslimat siparişi oluşturmak için satır seçilmemiş.'"));
		Return;
		
	EndIf;
	
	Measurement = PerformanceMonitorClient.StartTimeConsumingOperationMeasurement("DataProcessor.GenerateDeliveryOrders.Form.CreateDeliveryOrder");
	
	DataForSelectedRows = New Array; // Array of See DeliverListLineData
	For Each SelectedRow In SelectedRows Do
		
		RowData = Items[ListName].RowData(SelectedRow); // See DeliverListLineData
		DataForSelectedRows.Add(RowData);
		
	EndDo;
	
	FillParameters = ParametersForFillingInNewOrderUsingSelectedLines(DataForSelectedRows);
	
	MeasurementStepRatio = 100;
	PerformanceMonitorClient.FixTimeConsumingOperationMeasure(
		Measurement, SelectedRows.Count() / MeasurementStepRatio, "FillParameters");
	
	If FillParameters.ThereAreDifferencesInParameters Then
		
		QueryText = NStr("ru = 'При формировании заказа на доставку объединяются строки с разными параметрами доставки.
							|Продолжить?';
							|vi = 'When generating a delivery order, rows with different delivery parameters are merged.
							|Continue?';
							|en = 'When generating a delivery order, rows with different delivery parameters are merged.
							|Continue?'; fa = 'When generating a delivery order, rows with different delivery parameters are merged.
							|Continue?';
							|it = 'When generating a delivery order, rows with different delivery parameters are merged.
							|Continue?';
							|pl = 'When generating a delivery order, rows with different delivery parameters are merged.
							|Continue?';
							|tr = 'Teslimat siparişi oluşturulurken farklı teslimat parametrelerine sahip satırlar birleştiriliyor. 
							|Devam edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		If Response <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		
	EndIf;
	
	PerformanceMonitorClient.FixTimeConsumingOperationMeasure(Measurement, 1, "DialogThereAreDifferencesInParameters");
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillParameters);
	OpenForm("Document.DeliveryOrder.ObjectForm", FormParameters);
	
	PerformanceMonitorClient.EndTimeConsumingOperationMeasurement(Measurement, SelectedRows.Count(), "OpenForm");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeListSelections()
	
	BalanceLists = BalanceLists();
	AllLists = AllLists();
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		SetSelectionByOrganization(ThisObject, AllLists, Object.Organization);
	EndIf;
	
	SetSelectionByRecipient(ThisObject, AllLists, Object.Recipient);
	SetSelectionBySender(ThisObject, AllLists, Object.Sender);
	
	SetSelectionByShipmentPeriod(ThisObject, BalanceLists, Object.ShipmentPeriod);
	SetSelectionByDateOfShipmentOfOrders(ListOfDeliveryOrders, Object.ShipmentDateFrom);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByOrganization(Form, Lists, Organization)
	
	For Each ListName In Lists Do
		
		List = Form[ListName]; // DynamicList
		CommonClientServer.SetDynamicListParameter(
			List, "Organization", Organization);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByShipmentPeriod(Form, Lists, ShipmentPeriod)
	
	For Each ListName In Lists Do
		
		List = Form[ListName]; // DynamicList
		
		CommonClientServer.SetDynamicListParameter(
			List, "DateOfShipmentFrom", ShipmentPeriod.StartDate, ValueIsFilled(ShipmentPeriod.StartDate));
		
		CommonClientServer.SetDynamicListParameter(
			List, "DateOfShipmentBy", ShipmentPeriod.EndDate, ValueIsFilled(ShipmentPeriod.EndDate));
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDateOfShipmentOfOrders(ListOfDeliveryOrders, DateOfShipmentFrom)
	
	CommonClientServer.SetDynamicListParameter(
		ListOfDeliveryOrders, "DateOfShipmentFrom", DateOfShipmentFrom);
	
EndProcedure

&AtServer
Procedure SpecifySenderRecipientTypes()
	
	If Object.Direction = Enums.DeliveryDirections.PartnerWarehouse_ Then
		
		If TypeOf(Object.Sender) <> Type("CatalogRef.Warehouses") Then
			Object.Sender = Catalogs.Warehouses.EmptyRef();
		EndIf;
		Items.Sender.ChooseType = False;
		
		If TypeOf(Object.Recipient) <> Type("CatalogRef.Partners") Then
			Object.Recipient = Catalogs.Partners.EmptyRef();
		EndIf;
		Items.Recipient.ChooseType = False;
		
	Else
		
		Object.Sender = Undefined;
		Object.Recipient = Undefined;
		Items.Sender.ChooseType = True;
		Items.Recipient.ChooseType = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByRecipient(Form, Lists, Recipient)
	
	For Each ListName In Lists Do
		
		List = Form[ListName]; // DynamicList
		CommonClientServer.SetDynamicListParameter(List, "FinalRecipient", Recipient);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionBySender(Form, Lists, Sender)
	
	For Each ListName In Lists Do
		
		List = Form[ListName]; // DynamicList
		CommonClientServer.SetDynamicListParameter(List, "InitialSender", Sender);
		
		AuxProperties = List.SettingsComposer.Settings.AdditionalProperties;
		AuxProperties.Insert("Sender", Sender);
		
	EndDo;
	
EndProcedure

// Parameters:
//  Settings - DataCompositionSettings
// 
// Returns:
//  Structure:
//    * QueryTextDetailedDataPortionsOfRows - String
//    * Sender - CatalogRef.Warehouses
//  
&AtClientAtServerNoContext
Function AdditionalPropertiesOfListSettings(Settings)
	
	Return Settings.AdditionalProperties;
	
EndFunction

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ThisIsListByGoods = (TagName = "ListByItem");
	
	AuxProperties = AdditionalPropertiesOfListSettings(Settings);
	QueryText = AuxProperties.QueryTextDetailedDataPortionsOfRows;
	Sender = AuxProperties.Sender;
	DetailedData = DetailedDataPortionsOfRows(Rows, ThisIsListByGoods, QueryText, Sender);
	
	SelectionOfDetailedBalances = SelectionOfDetailedBalances(ThisIsListByGoods);
	
	ColumnsOfDetailedResidues = New Array; // Array of String
	ColumnsOfDetailedResidues.Add("RowCode");
	ColumnsOfDetailedResidues.Add("Sender");
	ColumnsOfDetailedResidues.Add("SenderPoint");
	ColumnsOfDetailedResidues.Add("Sender_Area");
	ColumnsOfDetailedResidues.Add("DeliveryMethodOfFinalShoulder");
	ColumnsOfDetailedResidues.Add("RecipientOfFinalLeverage");
	ColumnsOfDetailedResidues.Add("PointOfRecipientOfFinalLeverage");
	ColumnsOfDetailedResidues.Add("AreaOfRecipientOfFinalShoulder");
	ColumnsOfDetailedResidues.Add("CarrierOfEndArm");
	ColumnsOfDetailedResidues.Add("Balance");
	If Not ThisIsListByGoods Then
		
		ColumnsOfDetailedResidues.Add("Products");
		ColumnsOfDetailedResidues.Add("Characteristic");
		ColumnsOfDetailedResidues.Add("Series");
		ColumnsOfDetailedResidues.Add("Package");
		
	EndIf;
	ColumnsByRow = StrConcat(ColumnsOfDetailedResidues, ",");
	
	FilterStates1 = FilterDesignStatus(ThisIsListByGoods);
	FilterStates1.Sender = Sender;
	
	For Each ListLine In Rows Do
		
		ListLineData = DeliverListLineData(ListLine);
		FillPropertyValues(SelectionOfDetailedBalances, ListLineData);
		
		DetailsOfLine = DetailedData.DetailedPortionLeftovers.Copy(SelectionOfDetailedBalances, ColumnsByRow);
		ListLineData.Detailing = New ValueStorage(DetailsOfLine);
		
		FillPropertyValues(FilterStates1, ListLineData);
		LineState = DetailedData.DesignStatus.FindRows(FilterStates1);
		If LineState.Count() > 0 Then
			ListLineData.State = LineState[0].State;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function SelectionOfDetailedBalances(ThisIsListByGoods)
	
	SelectionOfDetailedBalances = New Structure;
	SelectionOfDetailedBalances.Insert("ReferenceOrder", Undefined);
	SelectionOfDetailedBalances.Insert("DeliveryMethod", Enums.TransportMethods25.EmptyRef());
	SelectionOfDetailedBalances.Insert("Recipient", Catalogs.Partners.EmptyRef());
	SelectionOfDetailedBalances.Insert("RecipientPoint", Catalogs.DeliveryPoints.EmptyRef());
	SelectionOfDetailedBalances.Insert("Recipient_Area", Catalogs.DeliveryZones.EmptyRef());
	SelectionOfDetailedBalances.Insert("DateOfShipment", '00010101');
	
	If ThisIsListByGoods Then
		
		SelectionOfDetailedBalances.Insert("Products", Catalogs.Products.EmptyRef());
		SelectionOfDetailedBalances.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
		SelectionOfDetailedBalances.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
		SelectionOfDetailedBalances.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
	EndIf;
	
	Return SelectionOfDetailedBalances;
	
EndFunction

&AtServerNoContext
Function FilterDesignStatus(ThisIsListByGoods)
	
	Filter = New Structure;
	Filter.Insert("ReferenceOrder", Undefined);
	Filter.Insert("DeliveryMethod", Enums.TransportMethods25.EmptyRef());
	Filter.Insert("Sender", Undefined);
	Filter.Insert("Carrier", Catalogs.Partners.EmptyRef());
	Filter.Insert("Recipient", Catalogs.Partners.EmptyRef());
	Filter.Insert("RecipientPoint", Catalogs.DeliveryPoints.EmptyRef());
	Filter.Insert("Recipient_Area", Catalogs.DeliveryZones.EmptyRef());
	Filter.Insert("DateOfShipment", '00010101');
	
	If ThisIsListByGoods Then
		
		Filter.Insert("Products", Catalogs.Products.EmptyRef());
		Filter.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
		Filter.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
		Filter.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
	EndIf;
	
	Return Filter;
	
EndFunction

// Parameters:
//  ListLine - DynamicListRow
// 
// Returns:
//  FormDataStructure - this line:
//  * Products - CatalogRef.Products
//  * Selected - Number
//  * Balance - Number
//  * ThereAreDifferences_InDeliveryParameters - Boolean
//  * PictureIndex - Number
//  * Detailing - ValueStorage
//  * OptionsForDeliveryParameters - ValueStorage
//  * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//  * DeliveryType - EnumRef.DeliveryTypes
//  * Recipient - CatalogRef.Partners
//  * RecipientPoint - CatalogRef.DeliveryPoints
//  * Recipient_Area - CatalogRef.DeliveryZones
//  * State - Number
//
&AtServerNoContext
Function DeliverListLineData(ListLine)
	
	ListLineData = ListLine.Value.Data;
	Return ListLineData;
	
EndFunction

&AtServer
Procedure InitializeAdditionalListProperties()
	
	Lists = BalanceLists();
	
	For Each ListName In Lists Do
		
		ListOfLeftovers = ThisObject[ListName]; // DynamicList
		ThisIsListByGoods = (ListOfLeftovers = ListByItem);
		
		AuxProperties = ListOfLeftovers.SettingsComposer.Settings.AdditionalProperties;
		
		QueryText = QueryTextDetailedDataPortionsOfRows(ThisIsListByGoods);
		AuxProperties.Insert("QueryTextDetailedDataPortionsOfRows", QueryText);
		AuxProperties.Insert("Sender", Object.Sender);
		
	EndDo;
	
EndProcedure

&AtServer
Function QueryTextDetailedDataPortionsOfRows(ThisIsListByGoods)
	
	QueryBatch = New Array; // Array of String
	
	QueryTextTTBalance =
	"SELECT
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	DeliveryTurnover.RowCode AS RowCode,
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.DateOfShipment AS DateOfShipment,
	|	DeliveryTurnover.DeliveryMethod AS DeliveryMethod,
	|	DeliveryTurnover.Carrier AS Carrier,
	|	DeliveryTurnover.Sender AS Sender,
	|	DeliveryTurnover.SenderPoint AS SenderPoint,
	|	DeliveryTurnover.Sender_Area AS Sender_Area,
	|	DeliveryTurnover.Recipient AS Recipient,
	|	DeliveryTurnover.RecipientPoint AS RecipientPoint,
	|	DeliveryTurnover.Recipient_Area AS Recipient_Area,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover AS Balance
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			Arm = 1
	|				AND ReferenceOrder IN (&DispositionsOfPortionOfLines)
	|				AND Sender = &Sender
	|				AND &GoodsConditions) AS DeliveryTurnover
	|WHERE
	|	DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover > 0";
	
	If ThisIsListByGoods Then
		GoodsConditions = "Products IN (&ItemOfPortionOfLines)";
	Else
		GoodsConditions = "TRUE";
	EndIf;
	
	QueryTextTTBalance = StrReplace(QueryTextTTBalance, "&GoodsConditions", GoodsConditions);
	
	QueryBatch.Add(QueryTextTTBalance);
	
	QueryTextParametersOfEndArm =
	"SELECT DISTINCT
	|	TTBalance.ReferenceOrder AS ReferenceOrder,
	|	TTBalance.RowCode AS RowCode,
	|	Delivery.DateOfShipment AS DateOfShipment,
	|	Delivery.DeliveryMethod AS DeliveryMethod,
	|	Delivery.Carrier AS Carrier,
	|	Delivery.Recipient AS Recipient,
	|	Delivery.RecipientPoint AS RecipientPoint,
	|	Delivery.Recipient_Area AS Recipient_Area
	|INTO TTParametersOfEndArm
	|FROM
	|	TTBalance AS TTBalance
	|		INNER JOIN AccumulationRegister.Delivery AS Delivery
	|		ON TTBalance.ReferenceOrder = Delivery.ReferenceOrder
	|			AND TTBalance.RowCode = Delivery.RowCode
	|			AND Delivery.ThisIsFinalArm
	|			AND Delivery.ToDeliver > 0
	|			AND Delivery.PlanningDocument = UNDEFINED
	|			AND NOT 1 IN
	|				(SELECT TOP 1
	|					1
	|				FROM
	|					InformationRegister.DocumentCorrections AS DocumentCorrections
	|				WHERE
	|					DocumentCorrections.CorrectedDocument = Delivery.Recorder
	|					OR DocumentCorrections.PreviousCorrection = Delivery.Recorder)
	|";
	
	QueryBatch.Add(QueryTextParametersOfEndArm);
	
	QueryTextState =
	"SELECT
	|	TTBalance.ReferenceOrder AS ReferenceOrder,
	|	TTBalance.DeliveryMethod AS DeliveryMethod,
	|	TTBalance.Sender AS Sender,
	|	TTBalance.Carrier AS Carrier,
	|	TTBalance.Recipient AS Recipient,
	|	TTBalance.RecipientPoint AS RecipientPoint,
	|	TTBalance.Recipient_Area AS Recipient_Area,
	|	TTBalance.DateOfShipment AS DateOfShipment,
	|	&ItemFields,
	|	MAX(CASE
	|			WHEN DeliveryTurnover.Recorder REFS Document.DeliveryOrder
	|				THEN 2
	|			ELSE 1
	|		END) AS State
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN AccumulationRegister.Delivery.Turnovers(, , Recorder, ReferenceOrder IN (&DispositionsOfPortionOfLines)) AS DeliveryTurnover
	|		ON TTBalance.ReferenceOrder = DeliveryTurnover.ReferenceOrder
	|			AND TTBalance.RowCode = DeliveryTurnover.RowCode
	|
	|GROUP BY
	|	TTBalance.ReferenceOrder,
	|	TTBalance.DeliveryMethod,
	|	TTBalance.Sender,
	|	TTBalance.Carrier,
	|	TTBalance.Recipient,
	|	TTBalance.RecipientPoint,
	|	TTBalance.Recipient_Area,
	|	TTBalance.DateOfShipment,
	|	&GoodsGroupingFields";
	
	If ThisIsListByGoods Then
		
		ItemFields =
		"TTBalance.Products AS Products,
		|	TTBalance.Characteristic AS Characteristic,
		|	TTBalance.Series AS Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package";
		
		GoodsGroupingFields =
		"TTBalance.Products,
		|	TTBalance.Characteristic,
		|	TTBalance.Series,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
		
	Else
		
		ItemFields = "NULL";
		GoodsGroupingFields = "NULL";
		
	EndIf;
	
	QueryTextState = StrReplace(QueryTextState, "&ItemFields", ItemFields);
	QueryTextState = StrReplace(QueryTextState, "&GoodsGroupingFields", GoodsGroupingFields);
	
	QueryBatch.Add(QueryTextState);
	
	QueryTextDetailedBalance =
	"SELECT
	|	TTBalance.ReferenceOrder AS ReferenceOrder,
	|	TTBalance.RowCode AS RowCode,
	|	TTBalance.Products AS Products,
	|	TTBalance.Characteristic AS Characteristic,
	|	TTBalance.Series AS Series,
	|	TTBalance.Package AS Package,
	|	TTBalance.DateOfShipment AS DateOfShipment,
	|	TTBalance.DeliveryMethod AS DeliveryMethod,
	|	TTBalance.Sender AS Sender,
	|	TTBalance.SenderPoint AS SenderPoint,
	|	TTBalance.Sender_Area AS Sender_Area,
	|	TTBalance.Recipient AS Recipient,
	|	TTBalance.RecipientPoint AS RecipientPoint,
	|	TTBalance.Recipient_Area AS Recipient_Area,
	|	ISNULL(TTParametersOfEndArm.DeliveryMethod, TTBalance.DeliveryMethod) AS DeliveryMethodOfFinalShoulder,
	|	ISNULL(TTParametersOfEndArm.Carrier, TTBalance.Carrier) AS CarrierOfEndArm,
	|	ISNULL(TTParametersOfEndArm.Recipient, TTBalance.Recipient) AS RecipientOfFinalLeverage,
	|	ISNULL(TTParametersOfEndArm.RecipientPoint, TTBalance.RecipientPoint) AS PointOfRecipientOfFinalLeverage,
	|	ISNULL(TTParametersOfEndArm.Recipient_Area, TTBalance.Recipient_Area) AS AreaOfRecipientOfFinalShoulder,
	|	SUM(TTBalance.Balance) AS Balance
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN TTParametersOfEndArm AS TTParametersOfEndArm
	|		ON TTBalance.ReferenceOrder = TTParametersOfEndArm.ReferenceOrder
	|			AND TTBalance.RowCode = TTParametersOfEndArm.RowCode
	|
	|GROUP BY
	|	TTBalance.ReferenceOrder,
	|	TTBalance.RowCode,
	|	TTBalance.Products,
	|	TTBalance.Characteristic,
	|	TTBalance.Series,
	|	TTBalance.Package,
	|	TTBalance.DateOfShipment,
	|	TTBalance.DeliveryMethod,
	|	TTBalance.Sender,
	|	TTBalance.SenderPoint,
	|	TTBalance.Sender_Area,
	|	TTBalance.Recipient,
	|	TTBalance.RecipientPoint,
	|	TTBalance.Recipient_Area,
	|	ISNULL(TTParametersOfEndArm.DeliveryMethod, TTBalance.DeliveryMethod),
	|	ISNULL(TTParametersOfEndArm.Carrier, TTBalance.Carrier),
	|	ISNULL(TTParametersOfEndArm.Recipient, TTBalance.Recipient),
	|	ISNULL(TTParametersOfEndArm.RecipientPoint, TTBalance.RecipientPoint),
	|	ISNULL(TTParametersOfEndArm.Recipient_Area, TTBalance.Recipient_Area)";
	
	QueryBatch.Add(QueryTextDetailedBalance);
	
	QueryText = StrConcat(QueryBatch, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Parameters:
//  Rows - DynamicListRows
//  ThisIsListByGoods - Boolean
//  QueryText - String
//  Sender - CatalogRef.Warehouses
// 
// Returns:
//  Structure - Detailed Data Portions Of Rows:
//   * DetailedPortionLeftovers - See DetailedPortionLeftovers
//   * DesignStatus - See PortionDesignStatus
//
&AtServerNoContext
Function DetailedDataPortionsOfRows(Rows, ThisIsListByGoods, QueryText, Sender)
	
	DispositionsOfPortionOfLines = New Array; // Array of DefinedType.DeliveryReferenceOrder25
	ItemOfPortionOfLines = New Array; // Array of CatalogRef.Products
	
	For Each ListLine In Rows Do
		
		ListLineData = DeliverListLineData(ListLine);
		
		If DispositionsOfPortionOfLines.Find(ListLineData.ReferenceOrder) = Undefined Then
			DispositionsOfPortionOfLines.Add(ListLineData.ReferenceOrder);
		EndIf;
		
		If ThisIsListByGoods Then
			
			If ItemOfPortionOfLines.Find(ListLineData.Products) = Undefined Then
				ItemOfPortionOfLines.Add(ListLineData.Products);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DispositionsOfPortionOfLines", DispositionsOfPortionOfLines);
	Query.SetParameter("Sender", Sender);
	If ThisIsListByGoods Then
		Query.SetParameter("ItemOfPortionOfLines", ItemOfPortionOfLines);
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	DetailedPortionLeftovers = DetailedPortionLeftovers(QueryResult);
	DesignStatus = PortionDesignStatus(QueryResult);
	
	Result = New Structure;
	Result.Insert("DetailedPortionLeftovers", DetailedPortionLeftovers);
	Result.Insert("DesignStatus", DesignStatus);
	
	Return Result;
	
EndFunction

// Returns:
// ValueTable:
//  * RowCode - Number
//  * Balance - Number
//
&AtServerNoContext
Function DetailedPortionLeftovers(QueryResult)
	
	Return QueryResult[QueryResult.UBound()].Unload();
	
EndFunction

// Returns:
// ValueTable:
//  * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//  * State - Number
//
&AtServerNoContext
Function PortionDesignStatus(QueryResult)
	
	Return QueryResult[QueryResult.UBound() - 1].Unload();
	
EndFunction

&AtServer
Function DataForFormattingBySelectedLines(DataForSelectedRows)
	
	Data_ForRegistration = NewDataForRegistration();
	
	For Each RowData In DataForSelectedRows Do
		
		DetailsOfLine = RowData.Detailing.Get(); // See DetailedPortionLeftovers
		
		For Each DetailOption In DetailsOfLine Do
			
			LineForRegistration = Data_ForRegistration.Add();
			FillPropertyValues(LineForRegistration, RowData);
			FillPropertyValues(LineForRegistration, DetailOption);
			
			LineForRegistration.DeliveryLineCode = DetailOption.RowCode;
			LineForRegistration.Count = DetailOption.Balance;
			LineForRegistration.NumberOfPackages = DetailOption.Balance;
			
		EndDo;
		
	EndDo;
	
	Return Data_ForRegistration;
	
EndFunction

&AtServerNoContext
Function NewDataForRegistration()
	
	Data_ForRegistration = New ValueTable();
	DeliveryMetadata = Metadata.AccumulationRegisters.Delivery;
	Data_ForRegistration.Columns.Add("ReferenceOrder", DeliveryMetadata.Dimensions.ReferenceOrder.Type);
	Data_ForRegistration.Columns.Add("DeliveryLineCode", DeliveryMetadata.Dimensions.RowCode.Type);
	Data_ForRegistration.Columns.Add("Products", DeliveryMetadata.Dimensions.Products.Type);
	Data_ForRegistration.Columns.Add("Characteristic", DeliveryMetadata.Dimensions.Characteristic.Type);
	Data_ForRegistration.Columns.Add("Series", DeliveryMetadata.Dimensions.Series.Type);
	Data_ForRegistration.Columns.Add("Package", DeliveryMetadata.Dimensions.Package.Type);
	Data_ForRegistration.Columns.Add("DateOfShipment", DeliveryMetadata.Dimensions.DateOfShipment.Type);
	Data_ForRegistration.Columns.Add("DeliveryMethod", DeliveryMetadata.Dimensions.DeliveryMethod.Type);
	Data_ForRegistration.Columns.Add("Sender", DeliveryMetadata.Dimensions.Sender.Type);
	Data_ForRegistration.Columns.Add("SenderPoint", DeliveryMetadata.Dimensions.SenderPoint.Type);
	Data_ForRegistration.Columns.Add("Sender_Area", DeliveryMetadata.Dimensions.Sender_Area.Type);
	Data_ForRegistration.Columns.Add("Recipient", DeliveryMetadata.Dimensions.Recipient.Type);
	Data_ForRegistration.Columns.Add("RecipientPoint", DeliveryMetadata.Dimensions.RecipientPoint.Type);
	Data_ForRegistration.Columns.Add("Recipient_Area", DeliveryMetadata.Dimensions.Recipient_Area.Type);
	Data_ForRegistration.Columns.Add("Carrier", DeliveryMetadata.Dimensions.Carrier.Type);
	Data_ForRegistration.Columns.Add("DeliveryMethodOfFinalShoulder", DeliveryMetadata.Dimensions.DeliveryMethod.Type);
	Data_ForRegistration.Columns.Add("RecipientOfFinalLeverage", DeliveryMetadata.Dimensions.Recipient.Type);
	Data_ForRegistration.Columns.Add("PointOfRecipientOfFinalLeverage", DeliveryMetadata.Dimensions.RecipientPoint.Type);
	Data_ForRegistration.Columns.Add("AreaOfRecipientOfFinalShoulder", DeliveryMetadata.Dimensions.Recipient_Area.Type);
	Data_ForRegistration.Columns.Add("CarrierOfEndArm", DeliveryMetadata.Dimensions.Carrier.Type);
	Data_ForRegistration.Columns.Add("Count", DeliveryMetadata.Resources.ToDeliver.Type);
	Data_ForRegistration.Columns.Add("NumberOfPackages", DeliveryMetadata.Resources.ToDeliver.Type);
	
	Return Data_ForRegistration;
	
EndFunction

&AtServer
Function ParametersForFillingInNewOrder(Data_ForRegistration)
	
	Result = New Structure;
	Result.Insert("ThereAreDifferencesInParameters", False);
	Result.Insert("Sender", Catalogs.Warehouses.EmptyRef());
	Result.Insert("SenderDeparturePoint", Catalogs.DeliveryPoints.EmptyRef());
	Result.Insert("DepartureArea", Catalogs.DeliveryZones.EmptyRef());
	Result.Insert("Recipient", Catalogs.Partners.EmptyRef());
	Result.Insert("DeliveryPointRecipient", Catalogs.DeliveryPoints.EmptyRef());
	Result.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	Result.Insert("DeliveryMethod", Enums.TransportMethods25.EmptyRef());
	Result.Insert("DeliveryToCarrier", False);
	Result.Insert("Carrier", Catalogs.Partners.EmptyRef());
	Result.Insert("CarrierDeliveryPoint", Catalogs.DeliveryPoints.EmptyRef());
	Result.Insert("CarrierSDeliveryArea", Catalogs.DeliveryZones.EmptyRef());
	Result.Insert("AddressGoodsTable", "");
	Result.Insert("Date", CurrentSessionDate());
	Result.Insert("Organization", Object.Organization);
	Result.Insert("DateOfShipment", '00010101');
	Result.Insert("DeliveryDirection", Object.Direction);
	Result.Insert("FillInDefaultAreaPoints", False);
	Result.Insert("UpdateAdditionalParameters", True);
	
	ParameterColumns = New Array; // Array of String
	ParameterColumns.Add("Sender");
	ParameterColumns.Add("SenderPoint");
	ParameterColumns.Add("Sender_Area");
	ParameterColumns.Add("Recipient");
	ParameterColumns.Add("RecipientPoint");
	ParameterColumns.Add("Recipient_Area");
	ParameterColumns.Add("DeliveryMethod");
	ParameterColumns.Add("Carrier");
	ParameterColumns.Add("RecipientOfFinalLeverage");
	ParameterColumns.Add("PointOfRecipientOfFinalLeverage");
	ParameterColumns.Add("AreaOfRecipientOfFinalShoulder");
	ParameterColumns.Add("CarrierOfEndArm");
	ParameterColumns.Add("DateOfShipment");
	
	ExceptionParameterColumns = New Array; // Array of String
	ExceptionParameterColumns.Add("DateOfShipment");
	
	UniqueParameterValues = NewUniqueParameterValues();
	
	For Each ParameterName In ParameterColumns Do
		
		ValuesOfParameter = TMCommonUse.UniqueValuesFromTableColumn(Data_ForRegistration, ParameterName);
		ValuesCount = ValuesOfParameter.Count();
		For ReverseIndex = 1 To ValuesCount Do
			
			IndexOf = ValuesCount - ReverseIndex;
			If Not ValueIsFilled(ValuesOfParameter[IndexOf]) Then
				ValuesOfParameter.Delete(IndexOf);
			EndIf;
			
		EndDo;
		
		UniqueParameterValues.Insert(ParameterName, ValuesOfParameter);
		
		If ExceptionParameterColumns.Find(ParameterName) = Undefined Then
			
			Result.ThereAreDifferencesInParameters = (Result.ThereAreDifferencesInParameters Or ValuesOfParameter.Count() > 1);
			
		EndIf;
		
	EndDo;
	
	Result.Sender = TotalValueOfParameter(UniqueParameterValues, "Sender");
	Result.SenderDeparturePoint = TotalValueOfParameter(UniqueParameterValues, "SenderPoint");
	Result.DepartureArea = TotalValueOfParameter(UniqueParameterValues, "Sender_Area");
	Result.DepartureArea = TotalValueOfParameter(UniqueParameterValues, "Sender_Area");
	Result.DateOfShipment = TotalValueOfParameter(UniqueParameterValues, "DateOfShipment");
	
	RecipientsDiffer = (UniqueParameterValues["Recipient"].Count() > 1);
	
	If RecipientsDiffer Then
		
		Result.Recipient = TotalValueOfParameter(UniqueParameterValues, "RecipientOfFinalLeverage");
		Result.DeliveryPointRecipient = TotalValueOfParameter(UniqueParameterValues, "PointOfRecipientOfFinalLeverage");
		Result.DeliveryZone = TotalValueOfParameter(UniqueParameterValues, "AreaOfRecipientOfFinalShoulder");
		Result.Carrier = TotalValueOfParameter(UniqueParameterValues, "Carrier");
		Result.DeliveryMethod = TotalValueOfParameter(UniqueParameterValues, "DeliveryMethod");
		Result.DeliveryToCarrier = False;
		
	Else
		
		Recipient = TotalValueOfParameter(UniqueParameterValues, "Recipient");
		RecipientOfFinalLeverage = TotalValueOfParameter(UniqueParameterValues, "RecipientOfFinalLeverage");
		
		If Recipient = RecipientOfFinalLeverage Then
			
			Result.Recipient = Recipient;
			Result.DeliveryPointRecipient = TotalValueOfParameter(UniqueParameterValues, "PointOfRecipientOfFinalLeverage");
			Result.DeliveryZone = TotalValueOfParameter(UniqueParameterValues, "AreaOfRecipientOfFinalShoulder");
			Result.Carrier = TotalValueOfParameter(UniqueParameterValues, "Carrier");
			Result.DeliveryMethod = TotalValueOfParameter(UniqueParameterValues, "DeliveryMethod");
			Result.DeliveryToCarrier = False;
			
		Else
			
			Result.Carrier = Recipient;
			Result.CarrierDeliveryPoint = TotalValueOfParameter(UniqueParameterValues, "RecipientPoint");
			Result.CarrierSDeliveryArea = TotalValueOfParameter(UniqueParameterValues, "Recipient_Area");
			
			Result.Recipient = RecipientOfFinalLeverage;
			Result.DeliveryPointRecipient = TotalValueOfParameter(UniqueParameterValues, "PointOfRecipientOfFinalLeverage");
			Result.DeliveryZone = TotalValueOfParameter(UniqueParameterValues, "AreaOfRecipientOfFinalShoulder");
			
			Result.DeliveryMethod = TotalValueOfParameter(UniqueParameterValues, "DeliveryMethod");
			Result.DeliveryToCarrier = True;
			
		EndIf;
		
	EndIf;
	
	CollapseDataForRegistration(Data_ForRegistration);
	PutToTempStorage(Data_ForRegistration, AddressDetailsForRegistration);
	Result.AddressGoodsTable = AddressDetailsForRegistration;
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - Unique Parameter Values:
//   * Sender - Array of CatalogRef.Warehouses
//   * SenderPoint - Array of CatalogRef.DeliveryPoints
//   * Sender_Area - Array of CatalogRef.DeliveryZones
//   * RecipientOfFinalLeverage - Array of CatalogRef.Partners
//   * PointOfRecipientOfFinalLeverage - Array of CatalogRef.DeliveryPoints
//   * AreaOfRecipientOfFinalShoulder - Array of CatalogRef.DeliveryZones
//   * Recipient - Array of CatalogRef.Partners
//   * Carrier - Array of CatalogRef.Partners
//   * DeliveryMethod - Array of EnumRef.TransportMethods25
//
&AtServer
Function NewUniqueParameterValues()
	
	UniqueParameterValues = New Structure;
	UniqueParameterValues.Insert("Sender", New Array);
	UniqueParameterValues.Insert("SenderPoint", New Array);
	UniqueParameterValues.Insert("Sender_Area", New Array);
	UniqueParameterValues.Insert("RecipientOfFinalLeverage", New Array);
	UniqueParameterValues.Insert("PointOfRecipientOfFinalLeverage", New Array);
	UniqueParameterValues.Insert("AreaOfRecipientOfFinalShoulder", New Array);
	UniqueParameterValues.Insert("Recipient", New Array);
	UniqueParameterValues.Insert("Carrier", New Array);
	UniqueParameterValues.Insert("DeliveryMethod", New Array);
	
	Return UniqueParameterValues;
	
EndFunction

&AtServer
Function TotalValueOfParameter(ParameterValues, ParameterName)
	
	Return ?(ParameterValues[ParameterName].Count() = 1, ParameterValues[ParameterName][0], Undefined);
	
EndFunction

&AtServer
Function ParametersForFillingInNewOrderUsingSelectedLines(Val DataForSelectedRows)
	
	Data_ForRegistration = DataForFormattingBySelectedLines(DataForSelectedRows);
	FillParameters = ParametersForFillingInNewOrder(Data_ForRegistration);
	Return FillParameters;
	
EndFunction

&AtClientAtServerNoContext
Function BalanceLists()
	
	BalanceLists = New Array; // Array of String
	BalanceLists.Add("ListByItem");
	BalanceLists.Add("ListByDocuments");
	
	Return BalanceLists;
	
EndFunction

&AtClientAtServerNoContext
Function AllLists()
	
	Lists = BalanceLists();
	Lists.Add("ListOfDeliveryOrders");
	Return Lists;
	
EndFunction

&AtClient
Procedure StartDragList(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Move;
	
	DataForSelectedRows = New Array; // Array of See DeliverListLineData
	For Each SelectedRow In Item.SelectedRows Do
		
		RowData = Item.RowData(SelectedRow); // See DeliverListLineData
		DataForSelectedRows.Add(RowData);
		
	EndDo;
	
	DragParameters.Value = DataForSelectedRows;
	
EndProcedure

// Parameters:
//  DeliveryOrderLink - DocumentRef.DeliveryOrder
//  DataForSelectedRows - Array of See DeliverListLineData
//
&AtServer
Procedure CompleteOrderATServer(Val DeliveryOrderLink, Val DataForSelectedRows)
	
	ObjectDeliveryOrder = DeliveryOrderLink.GetObject();
	ObjectDeliveryOrder.Lock();
	
	Data_ForRegistration = DataForFormattingBySelectedLines(DataForSelectedRows);
	CollapseDataForRegistration(Data_ForRegistration);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActionRecalculateNumberOfPackagingUnits = New Structure("RecalculateNumberOfPackages", Undefined);
	
	RowFilter = New Structure;
	RowFilter.Insert("ReferenceOrder", Undefined);
	RowFilter.Insert("DeliveryLineCode", 0);
	
	NewGoodsLines = New Array; // Array of LineOfATabularSection: See Document.DeliveryOrder.Goods
	
	For Each DataString1 In Data_ForRegistration Do
		
		FillPropertyValues(RowFilter, DataString1);
		ExistingRows = ObjectDeliveryOrder.Goods.FindRows(RowFilter);
		If ExistingRows.Count() > 0 Then
			
			TSRow = ExistingRows[0];
			TSRow.Count = TSRow.Count + DataString1.Count;
			TSRow.NumberOfPackages = TSRow.NumberOfPackages + DataString1.NumberOfPackages;
			
		Else
			
			TSRow = ObjectDeliveryOrder.Goods.Add();
			FillPropertyValues(TSRow, DataString1);
			NewGoodsLines.Add(TSRow);
			
		EndIf;
		
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesInTSLine(
			TSRow, StructureOfActionRecalculateNumberOfPackagingUnits, CachedValues);
		
	EndDo;
	
	Documents.DeliveryOrder.UpdateAdditionalParameters(ObjectDeliveryOrder, NewGoodsLines);
	
	If ObjectDeliveryOrder.Posted Then
		WriteMode = DocumentWriteMode.Posting;
	Else
		WriteMode = DocumentWriteMode.Write;
	EndIf;
	
	ObjectDeliveryOrder.Write(WriteMode);
	
EndProcedure

&AtServer
Procedure CollapseDataForRegistration(Data_ForRegistration)
	
	MetadataDetailsOfTS = Metadata.Documents.DeliveryOrder.TabularSections.Goods.Attributes;
	ColumnsCount = Data_ForRegistration.Columns.Count();
	For ReverseIndex = 1 To ColumnsCount Do
		
		IndexOf = ColumnsCount - ReverseIndex;
		ColumnName = Data_ForRegistration.Columns[IndexOf].Name;
		If MetadataDetailsOfTS.Find(ColumnName) = Undefined Then
			Data_ForRegistration.Columns.Delete(IndexOf);
		EndIf;
		
	EndDo;
	
	TotalingColumns = New Array; // Array of String
	TotalingColumns.Add(Data_ForRegistration.Columns.Count.Name);
	TotalingColumns.Add(Data_ForRegistration.Columns.NumberOfPackages.Name);
	
	GroupColumns = New Array; // Array of String
	For Each Column In Data_ForRegistration.Columns Do
		
		If TotalingColumns.Find(Column.Name) = Undefined Then
			GroupColumns.Add(Column.Name);
		EndIf;
		
	EndDo;
	
	RowGroupingColumns = StrConcat(GroupColumns, ",");
	RowSummationColumns = StrConcat(TotalingColumns, ",");
	
	Data_ForRegistration.GroupBy(RowGroupingColumns, RowSummationColumns);
	
EndProcedure

&AtServer
Procedure SubstituteExpressionsWeightVolume()
	
	QueryTextByGoods = ListByItem.QueryText;
	QueryTextByDocuments = ListByDocuments.QueryText;
	
	ExpressionPackagingUnitWeight = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByGoods = StrReplace(QueryTextByGoods, "&ExpressionPackagingUnitWeight", ExpressionPackagingUnitWeight);
	QueryTextByDocuments = StrReplace(QueryTextByDocuments, "&ExpressionPackagingUnitWeight", ExpressionPackagingUnitWeight);
	
	ExpressionPackagingUnitVolume = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"DeliveryTurnover.Products.UnitOfMeasure", "DeliveryTurnover.Products", False);
	QueryTextByGoods = StrReplace(QueryTextByGoods, "&ExpressionPackagingUnitVolume", ExpressionPackagingUnitVolume);
	QueryTextByDocuments = StrReplace(QueryTextByDocuments, "&ExpressionPackagingUnitVolume", ExpressionPackagingUnitVolume);
	
	ListByItem.QueryText = QueryTextByGoods;
	ListByDocuments.QueryText = QueryTextByDocuments;
	
EndProcedure

&AtClient
Procedure ListOfDocumentsUpdateAdditionalParameters()
	
	If Items.ListByDocuments.CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowData = Items.ListByDocuments.CurrentData; // See DeliverListLineData
	UpdateAdditionalParametersATServer(Items.ListByDocuments.Name, RowData);
	
EndProcedure

&AtClient
Procedure GoodsListUpdateAdditionalParameters()
	
	If Items.ListByItem.CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowData = Items.ListByItem.CurrentData; // See DeliverListLineData
	UpdateAdditionalParametersATServer(Items.ListByItem.Name, RowData);
	
EndProcedure

// Parameters:
//  TagName - String - 
//  RowData - See DeliverListLineData
//
&AtServer
Procedure UpdateAdditionalParametersATServer(Val TagName, Val RowData)
	
	If TagName = Items.ListByDocuments.Name Then
		
		ThisIsListByGoods = False;
		FieldsPrefix = "InformationOnDocuments";
		
	Else
		
		ThisIsListByGoods = True;
		FieldsPrefix = "InformationByGoods";
		
	EndIf;
	
	FilterParameters = SelectionOfDetailedBalances(ThisIsListByGoods);
	FillPropertyValues(FilterParameters, RowData);
	
	ReferenceOrder = RowData.ReferenceOrder;
	
	If TypeOf(ReferenceOrder) = Type("DocumentRef.SalesOrder") Then
		
		DeliverySpecificationMethod = Common.ObjectAttributeValue(ReferenceOrder, "DeliverySpecificationMethod");
		If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
			
			AddlParameters = GoodsDelivery.AdditionalParametersFromDocumentHeader(ReferenceOrder);
			
		Else
			
			DeliveryDocuments = CommonClientServer.ValueInArray(ReferenceOrder);
			AddlParameters = GoodsDelivery.MatchingAdditionalParametersFromDocumentStrings(
				DeliveryDocuments, FilterParameters, ThisIsListByGoods);
			
		EndIf;
		
	Else
		
		AddlParameters = GoodsDelivery.AdditionalParametersFromDocumentHeader(ReferenceOrder);
		
	EndIf;
	
	For Each ElementOfAdditionalParameters In AddlParameters Do
		
		If ElementOfAdditionalParameters.Key = "Match" Then
			Continue;
		EndIf;
		FieldName = FieldsPrefix + ElementOfAdditionalParameters.Key;
		CommonClientServer.SetFormAttributeByPath(ThisObject, FieldName, ElementOfAdditionalParameters.Value);
		
	EndDo;
	
	ElementsOfAdditionalParameters = New Array; // Array of String
	
	If ThisIsListByGoods Then
		
		InscriptionIsDifferentInformation = Items.InscriptionContainsInformationOnItems;
		
		ElementsOfAdditionalParameters.Add(Items.ItemInformationDeliveryTimeFrom.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnItemsDeliveryTimeBy.Name);
		ElementsOfAdditionalParameters.Add(Items.ItemInformationAdditionalDeliveryInformation.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnItemsSpecialConditionsOfCarriage.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnItemsSpecialConditionsOfCarriageDescription.Name);
		
	Else
		
		InscriptionIsDifferentInformation = Items.InscriptionDiffersInformationOnDocuments;
		
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsDeliveryTimeFrom.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsDeliveryTimeBy.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsAdditionalInformationOnDelivery.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsSpecialConditionsOfTransportation.Name);
		ElementsOfAdditionalParameters.Add(Items.InformationOnDocumentsSpecialConditionsOfCarriageDescription.Name);
		
	EndIf;
	
	If AddlParameters.Match Then
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ElementsOfAdditionalParameters, "Visible", True);
		InscriptionIsDifferentInformation.Visible = False;
		
	Else
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ElementsOfAdditionalParameters, "Visible", False);
		InscriptionIsDifferentInformation.Visible = True;
		
	EndIf;
	
EndProcedure

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetConditionalAppearanceOfRemainingUnfilledCarrier();
	SetConditionalAppearanceOfOrdersUnfilledCarrier();
	SetConditionalAppearanceBlankDeliveryPoint();
	SetConditionalAppearanceBlankDeliveryZone();
	SetConditionalAppearanceWeightVolumeNotUsed();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfRemainingUnfilledCarrier()
	
	#Region ListByGoodsCarrier_NotApplicable
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemCarrier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.Carrier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TransportMethods25.ByCarrier;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<неприменимо>';
													|vi = '<not applicable>';
													|en = '<not applicable>'; fa = '<not applicable>';
													|it = '<not applicable>';
													|pl = '<not applicable>';
													|tr = '<uygulanamaz>'"));
	#EndRegion
	
	#Region ListOfCarrierDocuments_NotApplicable
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsCarrier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.Carrier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TransportMethods25.ByCarrier;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<неприменимо>';
													|vi = '<not applicable>';
													|en = '<not applicable>'; fa = '<not applicable>';
													|it = '<not applicable>';
													|pl = '<not applicable>';
													|tr = '<uygulanamaz>'"));
	#EndRegion
	
	#Region ListOfGoodsCarrier_Not_Specified
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemCarrier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.Carrier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TransportMethods25.ByCarrier;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не указан>';
													|vi = '<not specified>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	#EndRegion
	
	#Region ListOfCarrierDocumentsIs_Not_Specified
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsCarrier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.Carrier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TransportMethods25.ByCarrier;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не указан>';
													|vi = '<not specified>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfOrdersUnfilledCarrier()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfDeliveryOrdersCarrier.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfDeliveryOrders.DeliveryMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TransportMethods25.ByCarrier;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<неприменимо>';
													|vi = '<not applicable>';
													|en = '<not applicable>'; fa = '<not applicable>';
													|it = '<not applicable>';
													|pl = '<not applicable>';
													|tr = '<uygulanamaz>'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceBlankDeliveryPoint()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemRecipientPoint.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.RecipientPoint");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не указана>';
													|vi = '<not specified>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsRecipientPoint.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.RecipientPoint");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не указана>';
													|vi = '<not specified>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceBlankDeliveryZone()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemRecipient_Area.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.Recipient_Area");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не указана>';
													|vi = '<not specified>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsRecipient_Area.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.Recipient_Area");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("ru = '<не указана>';
													|vi = '<not specified>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceWeightVolumeNotUsed()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByItemVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByItem.VolumeM3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.Weight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListByDocumentsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListByDocuments.VolumeM3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_ShipmentDateFrom" Then
		ShipmentDateFromOnChange(Items.ShipmentDateFrom);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
