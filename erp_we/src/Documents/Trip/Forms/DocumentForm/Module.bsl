// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsNew = Parameters.Key.IsEmpty();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	TimeFillingItems = New Array; // Array of FormField
	TimeFillingItems.Add(Items.RouteDeliveryTimeFrom);
	TimeFillingItems.Add(Items.RouteDeliveryTimeTo);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(TimeFillingItems);
	
	Address_Content = PutToTempStorage(Undefined, UUID);
	
	SetConditionalAppearance();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnCreatReadAtServer();
	ConfigureAvailabilityOfFieldsByStatus();
	SetUseOfTripStateHyperlink();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// The end of the standard subsystem.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	SetAvailabilityOfSelectionCommands();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	WriteParameters.Insert("WritingNewDocument", IsNew);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_Trip", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IsNew = False;
	
	UpdateTripState();
	ConfigureAvailabilityOfFieldsByStatus();
	SetUseOfTripStateHyperlink();
	CurrentStatus = CurrentObject.Status;
	
	SetAvailabilityOfSelectionCommands();
	FillInAdditionalRouteFields();
	
	If WriteParameters.WritingNewDocument Then
		
		SetSelectionOfOrders();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	
	// End StandardSubsystems.FilesOperations
	
EndProcedure

// Parameters:
//  ValueSelected - Structure, Arbitrary -
//  ChoiceSource - ClientApplicationForm -
//
&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.PickGoodsToDeliveryDocument.Form.PickForm" Then
		
		Modified = True;
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Async Procedure DeliveryMethodOnChange(Item)
	
	Result = DialogReturnCode.Yes;
	
	// There are lines beyond the initial
	If Object.Route.Count() > 1 Then
		
		If Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.ByCarrier") Then
		
			QueryText = NStr("vi = 'Khi giao hàng bằng phương tiện của bên vận chuyển, các điểm giao hàng trên lộ trình sẽ được lên kế hoạch lại cho người nhận. Tiếp tục?';
							|ru = 'При доставке силами перевозчика пункты доставки маршрута будут перепланированы на получателя. Продолжить?';
							|en = 'Upon delivery by carrier, the route delivery points will be rescheduled for the recipient. Continue?'; fa = 'Upon delivery by carrier, the route delivery points will be rescheduled for the recipient. Continue?';
							|it = 'Upon delivery by carrier, the route delivery points will be rescheduled for the recipient. Continue?';
							|pl = 'Upon delivery by carrier, the route delivery points will be rescheduled for the recipient. Continue?';
							|tr = 'Taşıyıcı tarafından gerçekleştirilen teslimatta rotanın teslimat noktaları alıcıya göre yeniden planlanacaktır. Devam edilsin mi?'");
			Result = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Result = DialogReturnCode.No Then
				Object.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OwnDelivery");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Result = DialogReturnCode.Yes Then
		DeliveryMethodOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	CarrierOnChangeServer();
	
EndProcedure

&AtClient
Async Procedure DepartureWarehouseOnChange(Item)
	
	DepartureWarehouseChanged = (Object.DepartureWarehouse <> CurrentDepartureWarehouse);
	
	If DepartureWarehouseChanged
		And RouteIsFull() Then
		
		Response = Await ShowQuestionAboutClearingRoutePoints(); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			
			Object.DepartureWarehouse = CurrentDepartureWarehouse;
			Object.DeparturePoint_ = CurrentPointOfDeparture;
			DepartureWarehouseChanged = False;
			
		EndIf;
		
	EndIf;
	
	If DepartureWarehouseChanged Then
		
		ClearRoutePoints();
		CurrentDepartureWarehouse = Object.DepartureWarehouse;
		DepartureWarehouseOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeparturePoint_OnChange(Item)
	
	DeparturePoint_OnChangeServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusBeforeChange = CurrentStatus;
	CurrentStatus = Object.Status;
	If Object.Status <> PredefinedValue("Enum.TripStatuses.RolledBack_")
		Or AllContentLinesAreCanceled() Then
		
		StatusOnChangeServer();
		
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
		
	Else
		
		ChoiceNotification1 = New CallbackDescription("FinishSelectingReasonForCancellation", ThisObject, StatusBeforeChange);
		OpenForm("Document.Trip.Form.CancellationReasonChoiceForm",
			,
			ThisObject,
			UUID,
			,
			,
			ChoiceNotification1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DepartureAreaOnChange(Item)
	
	DepartureAreaOnChangeServer();
	
EndProcedure

&AtClient
Procedure StatusClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Async Procedure OrganizationOnChange(Item)
	
	OrganizationChanged_1 = (Object.Organization <> CurrentCompany);
	
	If OrganizationChanged_1
	   And RouteIsFull() Then
		
		Response = Await ShowQuestionAboutClearingRoutePoints(); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			
			Object.Organization = CurrentCompany;
			Object.Contract = CurContract;
			OrganizationChanged_1 = False;
			
		EndIf;
		
	EndIf;
	
	If OrganizationChanged_1 Then
		
		ClearRoutePoints();
		CurrentCompany = Object.Organization;
		CurContract = Object.Contract;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	CurContract = Object.Contract;
	
EndProcedure

&AtClient
Procedure SceneryStateOfFlightClick(Item)
	
	ReportVariant = VersionOfReportKitsAccordingToTripOrders(Object.Ref);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CommandParameter", Object.Ref);
	OpeningParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	If ValueIsFilled(ReportVariant) Then
		
		ReportsOptionsClient.OpenReportForm(ThisObject, ReportVariant, OpeningParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRoute

&AtClient
Procedure RouteBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure RouteBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Route.CurrentData;
	If CurrentData.ConnectionKey = RouteStartLinkKey Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure RouteOnActivateRow(Item)
	
	If Items.Route.CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttachIdleHandler("SetAvailabilityOfCommandsInRoutesTable", 0.1, True);
	
EndProcedure

// Parameters:
//  Item - FormTable -
//  RowSelected - Number -
//  Field - FormField -
//  StandardProcessing - Boolean -
//
&AtClient
Procedure RouteSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.RouteContent
	   And Object.Route.FindByID(RowSelected).ConnectionKey <> RouteStartLinkKey Then
		
		OpenContentsOfRouteLine(RowSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RouteAfterDeleteRow(Item)
	
	RouteAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure RouteDragStart(Item, DragParameters, Perform)
	
	CurrentData = Items.Route.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ConnectionKey = RouteStartLinkKey Then
		Perform = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RouteDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	If String = Undefined Then
		Return;
	EndIf;
	
	If Object.Route.FindByID(String).ConnectionKey = RouteStartLinkKey Then
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
	EndIf;
	
EndProcedure

&AtClient
Procedure RouteDeliveryPointOnChange(Item)
	
	CurrentData = Items.Route.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DeliveryPoint = CurrentData.DeliveryPoint;
	
	If DeliveryPoint.IsEmpty() Then
		NewDeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
	Else
		NewDeliveryZone = DeliveryPointArea(DeliveryPoint);
	EndIf;
	CurrentData.DeliveryZone = NewDeliveryZone;
	
EndProcedure

&AtClient
Procedure RouteDeliveryTimeFromOnChange(Item)
	
	FillInAdditionalRouteFields();
	
EndProcedure

&AtClient
Procedure RouteDeliveryTimeToOnChange(Item)
	
	FillInAdditionalRouteFields();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Async Procedure PickUpData(Command)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	ClearMessages();
	Cancel = False;
	CheckContentBeforeSelection(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	If Modified
		Or IsNew Then
		
		RecordingResult = Await ResultOfRecordingDocumentBeforeSelection();
		
		If Not RecordingResult Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		PerformanceMonitorClient.TimeMeasurement("Document.Trip.DocumentForm.Command.PickUpData");
		OpenDataSelection();
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure UpdateShipmentDateOfOrders(Command)
	
	ClearMessages();
	
	If Modified Then
		
		WarningText = NStr("vi = 'Trước khi thực hiện lệnh, cần ghi lại chứng từ';
							|ru = 'Перед выполнение команды требуется записать документ';
							|en = 'Before performing the command, save the document'; fa = 'Before performing the command, save the document';
							|it = 'Before performing the command, save the document';
							|pl = 'Before performing the command, save the document';
							|tr = 'Komutu uygulamadan önce belgenin yazılması gerekir'");
		ShowMessageBox(, WarningText);
		
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(Object.DateOfDeparture) Then
		
		FieldName = NStr("vi = 'Ngày xuất phát';
						|ru = 'Дата выезда';
						|en = 'Departure date'; fa = 'تاریخ حرکت';
						|it = 'Departure date';
						|pl = 'Departure date';
						|tr = 'Çıkış tarihi'");
		ErrorText = CommonClientServer.FillingErrorText(,, FieldName);
		CommonClient.MessageToUser(
			ErrorText,, "Object.DateOfDeparture");
		
		Return;
		
	EndIf;
	
	Orders_ToBeProcessed = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.OrdersList);
	If Orders_ToBeProcessed.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionTemplate = NStr("vi = 'Thiết lập ngày xuất hàng theo ngày xuất phát %1 trên các dòng đã chọn?';
							|ru = 'Установить дату отгрузки по дате выезда %1 в выделенных строках?';
							|en = 'Set the shipment date by departure date (%1) in the selected lines?'; fa = 'Set the shipment date by departure date (%1) in the selected lines?';
							|it = 'Set the shipment date by departure date (%1) in the selected lines?';
							|pl = 'Set the shipment date by departure date (%1) in the selected lines?';
							|tr = 'Seçilen satırlardaki sevkiyat tarihi %1 çıkış tarihine göre ayarlansın mı?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		QuestionTemplate,
		Format(Object.DateOfDeparture, "DLF=D"));
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	
	If Response = DialogReturnCode.Yes Then
		
		ActionCompleted = False;
		UpdateShipmentDateOfOrdersServer(Orders_ToBeProcessed, ActionCompleted);
		
		If ActionCompleted Then
			NotifyChanged(Type("DocumentRef.GoodsIssueNote"));
		EndIf;
		
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure RouteMoveUp(Command)
	
	SelectedRows = Items.Route.SelectedRows;
	If SelectedRows.Count() = 0
		Or SelectedRows.Count() = Object.Route.Count() Then
		
		Return;
		
	EndIf;
	
	LineNumbers = NumbersOfSelectedRouteLines();
	
	NotMoved = New Array; // Array of Number
	
	For Each LineNumber In LineNumbers Do
		
		If LineNumber <> 1 Then
			
			LineNumberBefore = LineNumber - 1;
			CurrentRowIndex = LineNumber - 1;
			IndexOfRowBefore = LineNumberBefore - 1;
			Line_Before = Object.Route[IndexOfRowBefore];
			
			If NotMoved.Find(LineNumberBefore) = Undefined
				And Not ThisIsStartLineOfRoute(Line_Before) Then
				
				Object.Route.Move(CurrentRowIndex, -1);
				
			Else
				
				NotMoved.Add(LineNumber);
				
			EndIf;
			
		Else
			
			NotMoved.Add(LineNumber);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RouteMoveDown(Command)
	
	SelectedRows = Items.Route.SelectedRows;
	If SelectedRows.Count() = 0
		Or SelectedRows.Count() = Object.Route.Count() Then
		
		Return;
		
	EndIf;
	
	LineNumbers = NumbersOfSelectedRouteLines(False);
	
	NotMoved = New Array; // Array of Number
	
	For Each LineNumber In LineNumbers Do
		
		If LineNumber <> Object.Route.Count() Then
			
			DateNumberAfter = LineNumber + 1;
			CurrentRowIndex = LineNumber - 1;
			IndexOfRowAfter = DateNumberAfter - 1;
			LineAfter = Object.Route[IndexOfRowAfter];
			
			If NotMoved.Find(DateNumberAfter) = Undefined
				And Not ThisIsStartLineOfRoute(LineAfter) Then
				
				Object.Route.Move(CurrentRowIndex, 1);
				
			Else
				
				NotMoved.Add(LineNumber);
				
			EndIf;
			
		Else
			
			NotMoved.Add(LineNumber);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	CurrentCarrier = Object.Carrier;
	CurrentDepartureWarehouse = Object.DepartureWarehouse;
	CurrentPointOfDeparture = Object.DeparturePoint_;
	CurrentDepartureArea = Object.DepartureArea;
	CurrentStatus = Object.Status;
	CurrentCompany = Object.Organization;
	CurContract = Object.Contract;
	
	UpdateRouteStartLinkKey();
	UpdateTripState();
	
	ConfigureVisibilityAvailabilityOfFields();
	FillInAdditionalRouteFields();
	
	FillInShipmentSignAfterFormationOfFlight();
	UpdateAvailabilityOfCommandsInOrderList();
	UpdateDisplayOfListOfOrders();
	SetSelectionOfOrders();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Text color of the route start line item
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RoutePoint.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("RouteStartLinkKey");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// Restriction of editing the fields of the route start line
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RoutePoint.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteDeliveryPoint.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteOperation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteDeliveryZone.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteDeliveryTimeFrom.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteDeliveryTimeTo.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteContent.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteCanceled.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("RouteStartLinkKey");
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Hyperlink text of the route content
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteContent.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.ConnectionKey");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("RouteStartLinkKey");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nội dung';
													|ru = 'Содержимое';
													|en = 'Content'; fa = 'محتوا';
													|it = 'Content';
													|pl = 'Content';
													|tr = 'İçerik'"));
	
	// Time Field Separator
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteTimeDivider.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.DeliveryTimeFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.DeliveryTimeTo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	SetConditionalAppearanceOfCancellationGroup();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfCancellationGroup()
	
	// Output of the partial cancellation flag
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RoutePartiallyCanceledInscription.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.PartiallyCancelled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	DesignText = NStr("vi = 'Một phần';
						|ru = 'Частично';
						|en = 'Partially'; fa = 'Partially';
						|it = 'Partially';
						|pl = 'Partially';
						|tr = 'Kısmen'");
	Item.Appearance.SetParameterValue("Text", DesignText);
	
	// Hiding the partial cancellation feature
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteCanceled.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.PartiallyCancelled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Hiding the sign of complete cancellation
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RoutePartiallyCanceledInscription.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Route.PartiallyCancelled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityAvailabilityOfFields()
	
	Items.Carrier.Visible = (Object.DeliveryMethod = Enums.TransportMethods25.ByCarrier);
	Items.Contract.Visible = (Object.DeliveryMethod = Enums.TransportMethods25.ByCarrier);
	
	StatusIsGenerated = (Object.Status = Enums.TripStatuses.Prepared);
	
	Items.Driver.AutoMarkIncomplete = Not StatusIsGenerated;
	
	If StatusIsGenerated Then
		
		Items.Driver.MarkIncomplete = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfFieldsByStatus()
	
	If ReadOnly Then
		Return;
	EndIf;
	
	FieldsToBlock = New Array; // Array of String
	FieldsToBlock.Add(Items.DepartureWarehouse.Name);
	FieldsToBlock.Add(Items.DeparturePoint_.Name);
	FieldsToBlock.Add(Items.DepartureArea.Name);
	FieldsToBlock.Add(Items.DeliveryMethod.Name);
	FieldsToBlock.Add(Items.Carrier.Name);
	FieldsToBlock.Add(Items.Contract.Name);
	FieldsToBlock.Add(Items.Organization.Name);
	FieldsToBlock.Add(Items.DateOfDeparture.Name);
	FieldsToBlock.Add(Items.DepartureTime.Name);
	FieldsToBlock.Add(Items.Vehicle_.Name);
	FieldsToBlock.Add(Items.Driver.Name);
	FieldsToBlock.Add(Items.RoutePickUpData.Name);
	FieldsToBlock.Add(Items.RouteDeliveryZone.Name);
	FieldsToBlock.Add(Items.RouteDeliveryPoint.Name);
	
	BlockedFields = New Array; // Array of String
	
	If Object.Status = Enums.TripStatuses.Generated1
	 Or Object.Status = Enums.TripStatuses.RolledBack_ Then
		
		BlockedFields.Add(Items.RoutePickUpData.Name);
		
	ElsIf Object.Status = Enums.TripStatuses.Shipped_5 Then 
		
		BlockedFields.Add(Items.DepartureWarehouse.Name);
		BlockedFields.Add(Items.DeliveryMethod.Name);
		BlockedFields.Add(Items.Carrier.Name);
		BlockedFields.Add(Items.Contract.Name);
		BlockedFields.Add(Items.Organization.Name);
		BlockedFields.Add(Items.RoutePickUpData.Name);
		
	ElsIf Object.Status = Enums.TripStatuses.Completed Then
		
		BlockedFields = Common.CopyRecursive(FieldsToBlock);
		
	EndIf;
	
	NonBlockingFields = CommonClientServer.ArraysDifference(FieldsToBlock, BlockedFields);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, BlockedFields, "ReadOnly", True);
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, NonBlockingFields, "ReadOnly", False);
	
	Items.Route.ChangeRowSet = RouteCompositionCanBeChanged();
	
EndProcedure

&AtServer
Procedure DeliveryMethodOnChangeServer()
	
	If Object.DeliveryMethod = Enums.TransportMethods25.OwnDelivery Then
		
		Object.Carrier = Catalogs.Partners.EmptyRef();
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		CurContract = Object.Contract;
		
	Else
		
		Endpoints = New Array; // Array of CatalogRef.DeliveryPoints
		For Each RowWithContent In Object.Content Do
			
			If RowWithContent.FinalDeliveryPoint.IsEmpty() Then
				Continue;
			EndIf;
			
			Endpoints.Add(RowWithContent.FinalDeliveryPoint);
			
		EndDo;
		
		PointOwners = Common.ObjectsAttributeValue(Endpoints, "Owner");
		
		For Each RowWithContent In Object.Content Do
			
			If RowWithContent.FinalDeliveryPoint.IsEmpty() Then
				
				Continue;
				
			Else
				
				EndpointOwner = PointOwners[RowWithContent.FinalDeliveryPoint];
				
				RouteSelectionParameters = New Structure;
				RouteSelectionParameters.Insert("Point", EndpointOwner);
				RouteSelectionParameters.Insert("DeliveryPoint", RowWithContent.FinalDeliveryPoint);
				RouteSelectionParameters.Insert("Operation", Enums.TripOperations.Unloading);
				RouteLinesByParameters = Object.Route.FindRows(RouteSelectionParameters);
				If RouteLinesByParameters.Count() > 0 Then
					
					RouteLinkKey = RouteLinesByParameters[0].ConnectionKey;
					
				Else
					
					RouteLinkKey = New UUID();
					
					NewRouteLine = Object.Route.Add();
					NewRouteLine.ConnectionKey = RouteLinkKey;
					NewRouteLine.Operation = Enums.TripOperations.Unloading;
					NewRouteLine.Point = EndpointOwner;
					NewRouteLine.DeliveryPoint = RowWithContent.FinalDeliveryPoint;
					NewRouteLine.DeliveryZone = RowWithContent.FinalDeliveryArea;
					NewRouteLine.DeliveryTimeFrom = RowWithContent.DeliveryTimeFrom;
					NewRouteLine.DeliveryTimeTo = RowWithContent.DeliveryTimeTo;
					
				EndIf;
				
				RowWithContent.ConnectionKey = RouteLinkKey;
				RowWithContent.FinalDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
				RowWithContent.FinalDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
				
			EndIf;
			
		EndDo;
		
		LinesToDelete = New Array; // Array of FormDataCollectionItem
		For Each RouteString In Object.Route Do
			
			If RouteString.ConnectionKey = RouteStartLinkKey Then
				Continue;
			EndIf;
			
			ContentSelectionParameters = New Structure;
			ContentSelectionParameters.Insert("ConnectionKey", RouteString.ConnectionKey);
			ContentRows = Object.Content.FindRows(ContentSelectionParameters);
			If ContentRows.Count() = 0 Then
				LinesToDelete.Add(RouteString);
			EndIf;
			
		EndDo;
		TMCommonUse.DeleteTableRows(Object.Route, LinesToDelete);
		
		FillInAdditionalRouteFields(True);
		
	EndIf;
	
	ConfigureVisibilityAvailabilityOfFields();
	
EndProcedure

&AtServer
Procedure CarrierOnChangeServer()
	
	If Object.Carrier = CurrentCarrier Then
		Return;
	EndIf;
	
	CurrentCarrier = Object.Carrier;
	
	ConfigureVisibilityAvailabilityOfFields();
	
EndProcedure

&AtServer
Procedure DepartureWarehouseOnChangeServer()
	
	TripObject = FormAttributeToValue("Object");
	
	OldRouteStartLine = TripObject.Route.Find(RouteStartLinkKey, "ConnectionKey");
	If OldRouteStartLine <> Undefined Then
		
		TripObject.Route.Delete(OldRouteStartLine);
		
	EndIf;
	
	SenderSPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.DepartureWarehouse);
	TripObject.DeparturePoint_ = SenderSPointData.DeliveryPoint;
	TripObject.DepartureArea = SenderSPointData.DeliveryZone;
	
	TripObject.AddStartLineOfRoute();
	
	ValueToFormAttribute(TripObject, "Object");
	
	UpdateRouteStartLinkKey();
	
	FillInShipmentSignAfterFormationOfFlight();
	UpdateDisplayOfListOfOrders();
	SetSelectionOfOrders();
	
EndProcedure

&AtServer
Procedure DeparturePoint_OnChangeServer()
	
	If Object.DeparturePoint_ = CurrentPointOfDeparture Then
		Return;
	EndIf;
	
	CurrentPointOfDeparture = Object.DeparturePoint_;
	
	TripObject = FormAttributeToValue("Object");
	
	If ValueIsFilled(TripObject.DeparturePoint_) Then
		
		TripObject.DepartureArea = DeliveryPointArea(TripObject.DeparturePoint_);
		
	Else
		
		TripObject.DepartureArea = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	RouteStartLine = TripObject.Route.Find(RouteStartLinkKey, "ConnectionKey");
	If RouteStartLine = Undefined Then
		
		TripObject.AddStartLineOfRoute();
		RouteStartLine = TripObject.Route[0];
		
	EndIf;
	
	RouteStartLine.DeliveryPoint = TripObject.DeparturePoint_;
	RouteStartLine.DeliveryZone = TripObject.DepartureArea;
	
	ValueToFormAttribute(TripObject, "Object");
	
	UpdateRouteStartLinkKey();
	
EndProcedure

&AtServer
Procedure DepartureAreaOnChangeServer()
	
	If Object.DepartureArea = CurrentDepartureArea Then
		Return;
	EndIf;
	
	CurrentDepartureArea = Object.DepartureArea;
	
	TripObject = FormAttributeToValue("Object");
	
	RouteStartLine = TripObject.Route.Find(RouteStartLinkKey, "ConnectionKey");
	If RouteStartLine = Undefined Then
		
		TripObject.AddStartLineOfRoute();
		RouteStartLine = TripObject.Route[0];
		
	EndIf;
	
	RouteStartLine.DeliveryPoint = TripObject.DeparturePoint_;
	RouteStartLine.DeliveryZone = TripObject.DepartureArea;
	
	ValueToFormAttribute(TripObject, "Object");
	
	UpdateRouteStartLinkKey();
	
EndProcedure

&AtClient
Procedure OpenContentsOfRouteLine(RowSelected)
	
	RowData = Object.Route.FindByID(RowSelected);
	PlaceContentsInTemporaryStorage(RowData.ConnectionKey);
	
	FormParameters = New Structure();
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("Recipient", RowData.Point);
	FormParameters.Insert("DeliveryPoint", RowData.DeliveryPoint);
	FormParameters.Insert("DeliveryZone", RowData.DeliveryZone);
	FormParameters.Insert("Address_Content", Address_Content);
	FormParameters.Insert("ConnectionKey", RowData.ConnectionKey);
	FormParameters.Insert("Operation", RowData.Operation);
	FormParameters.Insert("Warehouse", Object.DepartureWarehouse);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("DeliveryMethod", Object.DeliveryMethod);
	FormParameters.Insert("Carrier", Object.Carrier);
	FormParameters.Insert("DateOfDeparture", Object.DateOfDeparture);
	FormParameters.Insert("Status", CurrentStatus);
	FormParameters.Insert("FlightHasBeenCompleted", Object.Posted);
	FormParameters.Insert("FlightLink", Object.Ref);
	FlightModified = (Modified Or IsNew);
	FormParameters.Insert("FlightModified", FlightModified);
	
	Notification = New CallbackDescription("OpenContentsOfRouteLineCompletion", ThisObject);
	
	OpenForm("Document.Trip.Form.ContentForm",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		Notification);
	
EndProcedure

&AtServer
Procedure PlaceContentsInTemporaryStorage(Val ConnectionKey = Undefined)
	
	RowFilter = New Structure;
	If ValueIsFilled(ConnectionKey) Then
		RowFilter.Insert("ConnectionKey", ConnectionKey);
	EndIf;
	TableContents = Object.Content.Unload(RowFilter);
	
	TypeDeliveryPoint = New TypeDescription("CatalogRef.DeliveryPoints");
	TypeOfDeliveryZone = New TypeDescription("CatalogRef.DeliveryZones");
	
	TableContents.Columns.Add("DeliveryPoint", TypeDeliveryPoint);
	TableContents.Columns.Add("DeliveryZone", TypeOfDeliveryZone);
	
	Address_Content = PutToTempStorage(TableContents, Address_Content);
	
EndProcedure

// Parameters:
//  Result - Structure:
//   * ConnectionKey - UUID
//   * AddressDeliveredGoods - String
//   * AddressDeliveredGoodsChanges - String
//   * Modified - Boolean
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OpenContentsOfRouteLineCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And Result.Modified Then
		
		TransferContentToObject(Result);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TransferContentToObject(Val Result)
	
	// Update the data on the item
	TableContents = GetFromTempStorage(Result.AddressDeliveredGoods); // ValueTable
	DeleteFromTempStorage(Result.AddressDeliveredGoods);
	TableContents.FillValues(Result.ConnectionKey, "ConnectionKey");
	
	RowFilter = New Structure("ConnectionKey", Result.ConnectionKey);
	OldContentLines = Object.Content.FindRows(RowFilter);
	TMCommonUse.DeleteTableRows(Object.Content, OldContentLines);
	
	If TableContents.Count() > 0 Then
		
		CommonClientServer.SupplementTable(TableContents, Object.Content);
		
	Else
		
		StringsByLinkKey = Object.Route.FindRows(RowFilter);
		TMCommonUse.DeleteTableRows(Object.Route, StringsByLinkKey);
		
	EndIf;
	
	// We will distribute the changes to other points
	ChangesTable1 = GetFromTempStorage(Result.AddressDeliveredGoodsChanges); // ValueTable
	DeleteFromTempStorage(Result.AddressDeliveredGoodsChanges);
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Point", Undefined);
	TheStructureOfTheSearch.Insert("DeliveryPoint", Catalogs.DeliveryPoints.EmptyRef());
	TheStructureOfTheSearch.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	
	For Each StringOfChange In ChangesTable1 Do
		
		DeliveryToCarrier = False;
		If StringOfChange.Carrier.IsEmpty() Then
			
			TheStructureOfTheSearch.Point = StringOfChange.FinalDestination;
			TheStructureOfTheSearch.DeliveryPoint = StringOfChange.FinalDeliveryPoint;
			TheStructureOfTheSearch.DeliveryZone = StringOfChange.FinalDeliveryArea;
			
		Else
			
			DeliveryToCarrier = True;
			
			TheStructureOfTheSearch.Point = StringOfChange.Carrier;
			TheStructureOfTheSearch.DeliveryPoint = StringOfChange.DeliveryPoint;
			TheStructureOfTheSearch.DeliveryZone = StringOfChange.DeliveryZone;
			
		EndIf;
		
		RouteRows = Object.Route.FindRows(TheStructureOfTheSearch);
		If RouteRows.Count() > 0 Then
			
			// Only the first match is analyzed, because otherwise it is only if there is an error
			RouteString = RouteRows[0];
			
		Else
			
			RouteString = Object.Route.Add();
			RouteString.Operation = Enums.TripOperations.Unloading;
			RouteString.ConnectionKey = New UUID();
			
			FillPropertyValues(RouteString, TheStructureOfTheSearch);
			
		EndIf;
		
		RowWithContent = Object.Content.Add();
		RowWithContent.ConnectionKey = RouteString.ConnectionKey;
		RowWithContent.ReferenceOrder = StringOfChange.ReferenceOrder;
		RowWithContent.PlanningDocument = StringOfChange.PlanningDocument;
		RowWithContent.RowCode = StringOfChange.RowCode;
		RowWithContent.Products = StringOfChange.Products;
		RowWithContent.Characteristic = StringOfChange.Characteristic;
		RowWithContent.Series = StringOfChange.Series;
		RowWithContent.Count = StringOfChange.Count;
		RowWithContent.NumberOfPackages = StringOfChange.NumberOfPackages;
		RowWithContent.Package = StringOfChange.Package;
		RowWithContent.Net_Weight = StringOfChange.Net_Weight;
		RowWithContent.Weight = StringOfChange.Weight;
		RowWithContent.VolumeM3 = StringOfChange.VolumeM3;
		RowWithContent.DeliveryTimeFrom = StringOfChange.DeliveryTimeFrom;
		RowWithContent.DeliveryTimeTo = StringOfChange.DeliveryTimeTo;
		RowWithContent.AdditionalDeliveryInformation = StringOfChange.AdditionalDeliveryInformation;
		RowWithContent.SpecialTransportationConditions = StringOfChange.SpecialTransportationConditions;
		RowWithContent.SpecialTransportationConditionsDescription = StringOfChange.SpecialTransportationConditionsDescription;
		RowWithContent.Canceled = StringOfChange.Canceled;
		RowWithContent.CancellationReason = StringOfChange.CancellationReason;
		
		If DeliveryToCarrier Then
			
			RowWithContent.FinalDeliveryPoint = StringOfChange.FinalDeliveryPoint;
			RowWithContent.FinalDeliveryArea = StringOfChange.FinalDeliveryArea;
			
		Else
			
			RowWithContent.FinalDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
			RowWithContent.FinalDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
			
		EndIf;
		
	EndDo;
	
	FillInAdditionalRouteFields(True, True);
	
EndProcedure

&AtServer
Procedure RouteAfterDeleteRowServer()
	
	Filter = New Structure;
	Filter.Insert("ConnectionKey", RouteStartLinkKey);
	
	RestoreBeginningOfRoute = (Object.Route.FindRows(Filter).Count() = 0);
	
	TripObject = FormAttributeToValue("Object");
	TripObject.DeleteIrrelevantContentLines();
	
	If RestoreBeginningOfRoute Then
		
		TripObject.AddStartLineOfRoute();
		If TripObject.Route.Count() > 0 Then
			
			TripObject.Route[0].ConnectionKey = RouteStartLinkKey;
			
		EndIf;
		
	EndIf;
	
	ValueToFormAttribute(TripObject, "Object");
	
EndProcedure

&AtServer
Procedure UpdateRouteStartLinkKey()
	
	Filter = New Structure;
	Filter.Insert("Point", Object.DepartureWarehouse);
	Filter.Insert("DeliveryPoint", Object.DeparturePoint_);
	Filter.Insert("Operation", Enums.TripOperations.Loading);
	Rows = Object.Route.FindRows(Filter);
	
	If Rows.Count() > 0 Then
		RouteStartLinkKey = Rows[0].ConnectionKey;
	Else
		RouteStartLinkKey = CommonClientServer.BlankUUID();
	EndIf;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	ConfigureVisibilityAvailabilityOfFields();
	
	If Object.Status = Enums.TripStatuses.RolledBack_ Then
		
		FillInAdditionalRouteFields(True);
		
	EndIf;
	
	UpdateAvailabilityOfCommandsInOrderList();
	
EndProcedure

&AtClient
Procedure OpenDataSelection()
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Warehouse", Object.DepartureWarehouse);
	FormParameters.Insert("DeliveryMethod", Object.DeliveryMethod);
	FormParameters.Insert("Carrier", Object.Carrier);
	FormParameters.Insert("DateOfShipment", Object.DateOfDeparture);
	FormParameters.Insert("ConsiderQuantityInDocument", Not Object.Posted);
	FormParameters.Insert("DocumentDeliveries", Object.Ref);
	
	OpenForm("DataProcessor.PickGoodsToDeliveryDocument.Form.PickForm",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

// Parameters:
//  ValueSelected - Structure:
//   * AddressOfSelectedItems - String
//
&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(Val ValueSelected)
	
	SelectedGoods = SelectedGoods(ValueSelected);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	FilterContent = New Structure;
	FilterContent.Insert("ReferenceOrder", Undefined);
	FilterContent.Insert("PlanningDocument", Undefined);
	FilterContent.Insert("RowCode", 0);
	FilterContent.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	FilterContent.Insert("Canceled", False);
	
	FilterRoute = New Structure;
	FilterRoute.Insert("Point", Undefined);
	FilterRoute.Insert("DeliveryPoint", Catalogs.DeliveryPoints.EmptyRef());
	FilterRoute.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	
	SelectionByCommunicationKey = New Structure;
	SelectionByCommunicationKey.Insert("ConnectionKey", CommonClientServer.BlankUUID());
	
	ModifiedRows = New Array; // Array of FormDataCollectionItem
	
	For Each StringMatched In SelectedGoods Do
		
		FillPropertyValues(FilterContent, StringMatched);
		ContentLinesByGoods = Object.Content.FindRows(FilterContent);
		
		If StringMatched.DeliveryType = Enums.DeliveryTypes.OutgoingInfo Then
			
			Operation = Enums.TripOperations.Unloading;
			
		Else
			
			Operation = Enums.TripOperations.Loading;
			
		EndIf;
		
		Point = StringMatched.DeliveryTo;
		SuitableContentLine = Undefined;
		AppropriateRouteLine = Undefined;
		
		For Each ContentLineForGoods In ContentLinesByGoods Do
			
			SelectionByCommunicationKey.ConnectionKey = ContentLineForGoods.ConnectionKey;
			RouteLines = Object.Route.FindRows(SelectionByCommunicationKey);
			RouteString = RouteLines[0];
			
			If RouteString.Point = Point
				And RouteString.DeliveryPoint = StringMatched.DeliveryPoint
				And RouteString.DeliveryZone = StringMatched.DeliveryZone Then
				
				AppropriateRouteLine = RouteString;
				SuitableContentLine = ContentLineForGoods;
				Break;
				
			EndIf;
			
		EndDo;
		
		If AppropriateRouteLine = Undefined Then
			
			FillPropertyValues(FilterRoute, StringMatched);
			FilterRoute.Point = Point;
			
			RouteLines = Object.Route.FindRows(FilterRoute);
			If RouteLines.Count() > 0 Then
				AppropriateRouteLine = RouteLines[0];
			EndIf;
			
		EndIf;
		
		If AppropriateRouteLine = Undefined Then
			
			AppropriateRouteLine = Object.Route.Add();
			FillPropertyValues(AppropriateRouteLine, StringMatched);
			AppropriateRouteLine.Point = Point;
			AppropriateRouteLine.ConnectionKey = New UUID();
			AppropriateRouteLine.Operation = Operation;
			
		EndIf;
		
		If SuitableContentLine = Undefined Then
			
			SuitableContentLine = Object.Content.Add();
			FillPropertyValues(SuitableContentLine, StringMatched);
			SuitableContentLine.ConnectionKey = AppropriateRouteLine.ConnectionKey;
			
		Else
			
			SuitableContentLine.Count = SuitableContentLine.Count + StringMatched.Count;
			
		EndIf;
		
		ActionStructure = New Structure("RecalculateNumberOfPackages", Undefined);
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesInTSLine(
			SuitableContentLine, ActionStructure, CachedValues);
		
		ModifiedRows.Add(SuitableContentLine);
		
	EndDo;
	
	FillInWeightVolumeOfGoodsLines(ModifiedRows);
	
	Documents.Trip.FillInAdditionalContentParameters(ModifiedRows);
	
	FillInAdditionalRouteFields(, True);
	
EndProcedure

&AtServer
Procedure FillInWeightVolumeOfGoodsLines(ModifiedRows)
	
	CopyOfGoods = Object.Content.Unload(
		ModifiedRows, "LineNumber, Products, Count, NumberOfPackages, Package, Net_Weight, Weight, VolumeM3");
	CopyOfGoods.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	CopyOfGoods.Columns.Add("PackageWeight", Common.TypeDescriptionNumber(15, 3));
	CopyOfGoods.Columns.Add("PackageVolume", Common.TypeDescriptionNumber(15, 3));
	CopyOfGoods.Columns.Add("UnitOfMeasureForWeight", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	CopyOfGoods.Columns.Add("UnitOfMeasureForVolume", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	CopyOfGoods.Columns.Add("NetWeightUnits", Common.TypeDescriptionNumber(15, 3));
	
	CopyOfGoods.Columns.Find("LineNumber").Name = "OriginalLineNumber";
	TMCommonUse.NumberValueTable(CopyOfGoods, "LineNumber");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	StructureOfActions.Insert("FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	StructureOfActions.Insert("FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	StructureOfActions.Insert("FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(CopyOfGoods, StructureOfActions);
	
	RowFilter = New Structure;
	RowFilter.Insert("LineNumber", 0);
	
	For Each RowFromCopy In CopyOfGoods Do
		
		EmptyPackaging = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		ProductData_1 = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(
			EmptyPackaging, RowFromCopy.Products,, False);
		RowFromCopy.NetWeightUnits = ProductData_1.Net_Weight; // Number
		UnitVolume = ProductData_1.VolumeM3; // Number
		MeasuringUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(RowFromCopy.Package);
		
		// volume in cubic meters
		If MeasuringUnit Then
			RowFromCopy.VolumeM3 = RowFromCopy.Count * UnitVolume;
		Else
			RowFromCopy.VolumeM3 = RowFromCopy.NumberOfPackages * RowFromCopy.PackageVolume;
		EndIf;
		
		// Net weight in kg
		RowFromCopy.Net_Weight = RowFromCopy.Count * RowFromCopy.NetWeightUnits;
		
		// gross weight in kg
		If MeasuringUnit Then
			RowFromCopy.Weight = RowFromCopy.Net_Weight;
		Else
			RowFromCopy.Weight = RowFromCopy.NumberOfPackages * RowFromCopy.PackageWeight;
		EndIf;
		
		RowFilter.LineNumber = RowFromCopy.OriginalLineNumber;
		OriginalLinesOfTS = Object.Content.FindRows(RowFilter);
		FillPropertyValues(OriginalLinesOfTS[0], RowFromCopy, "NumberOfPackages, Net_Weight, Weight, VolumeM3");
		
	EndDo;
	
EndProcedure

// Parameters:
//  ValueSelected - Structure - selected value:
// * AddressOfSelectedItems - String - 
// 
// Returns:
//  ValueTable - Table of selected products:
//  * DeliveryTo - CatalogRef.Partners
//  * DeliveryPoint - CatalogRef.DeliveryPoints
//  * DeliveryZone - CatalogRef.DeliveryZones
//  * Count - Number
//  * DeliveryType - EnumRef.DeliveryTypes
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure
//
&AtServer
Function SelectedGoods(ValueSelected)
	
	SelectedGoods = GetFromTempStorage(ValueSelected.AddressOfSelectedItems); // ValueTable
	DeleteFromTempStorage(ValueSelected.AddressOfSelectedItems);
	Return SelectedGoods;
	
EndFunction

&AtServer
Procedure UpdateTripState()
	
	Items.SceneryStateOfFlight.Visible = Object.Posted;
	
	If Object.Posted Then
		Items.SceneryStateOfFlight.Title = Documents.Trip.TripState(Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckContentBeforeSelection(Cancel)
	
	If Not ValueIsFilled(Object.Organization) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText,, "Organization", "Object", Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.DepartureWarehouse) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
						|ru = 'Поле ""Склад"" не заполнено';
						|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
						|it = 'Il campo ""Magazzino"" non è compilato';
						|pl = 'Nie wypełniono pola ""Magazyn""';
						|tr = '""Ambar"" alanı doldurulmamış'");
		CommonClient.MessageToUser(ErrorText,, "DepartureWarehouse", "Object", Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.DeliveryMethod) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Phương thức giao hàng""';
						|ru = 'Поле ""Способ доставки"" не заполнено';
						|en = 'The ""Delivery method"" field is not filled'; fa = 'The ""Delivery method"" field is not filled';
						|it = 'Поле ""Способ доставки"" не заполнено';
						|pl = 'The ""Delivery method"" field is not filled';
						|tr = '""Transfer yöntemi"" alanı doldurulmamış'");
		CommonClient.MessageToUser(ErrorText,, "DeliveryMethod", "Object", Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Async Function ResultOfRecordingDocumentBeforeSelection()
	
	RecordingResult = False;
	
	If Object.Posted Then
		QueryText = NStr("vi = 'Chứng từ đã bị thay đổi. Kết chuyển?';
						|ru = 'Документ был изменен. Провести?';
						|en = 'The document was changed. Post it?'; fa = 'The document was changed. Post it?';
						|it = 'The document was changed. Post it?';
						|pl = 'The document was changed. Post it?';
						|tr = 'Belge değiştirildi. Kaydedilsin mi?'");
	Else
		QueryText = NStr("vi = 'Chứng từ đã bị thay đổi. Lưu lại?';
						|ru = 'Документ был изменен. Записать?';
						|en = 'The document was changed. Save it?'; fa = 'The document was changed. Save it?';
						|it = 'The document was changed. Save it?';
						|pl = 'The document was changed. Save it?';
						|tr = 'Belge değiştirildi. Yazılsın mı?'");
	EndIf;
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	
	If Response <> DialogReturnCode.Yes Then
		Return RecordingResult;
	EndIf;
	
	If Object.Posted Then
		
		ClearMessages();
		If CheckFilling() Then
			RecordingResult = Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		EndIf;
		
	Else
		
		RecordingResult = Write(New Structure("WriteMode", DocumentWriteMode.Write));
		
	EndIf;
	
	Return RecordingResult;
	
EndFunction

&AtServerNoContext
Function DeliveryPointArea(Val DeliveryPoint)
	
	Return Common.ObjectAttributeValue(DeliveryPoint, "DeliveryZone");
	
EndFunction

&AtServer
Procedure SetAvailabilityOfSelectionCommands()
	
	If ReadOnly Then
		
		Items.RoutePickUpData.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtClient
Function RouteIsFull()
	
	RouteIsEmpty = Object.Route.Count() = 0
				Or (Object.Route.Count() = 1
					And ValueIsFilled(RouteStartLinkKey));
	
	Return Not RouteIsEmpty;
	
EndFunction

&AtClient
Procedure ClearRoutePoints()
	
	If Not RouteIsFull() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(RouteStartLinkKey) Then
		
		Object.Route.Clear();
		
	Else
		
		LinesToDelete = New Array; // Array of LineOfATabularSection
		For Each CurrentRow In Object.Route Do
			
			If CurrentRow.ConnectionKey <> RouteStartLinkKey Then
				
				LinesToDelete.Add(CurrentRow);
				
			EndIf;
			
		EndDo;
		
		For Each TSRow In LinesToDelete Do
			
			Object.Route.Delete(TSRow);
			
		EndDo;
		
	EndIf;
	
	RouteAfterDeleteRowServer();
	
EndProcedure

&AtClient
Async Function ShowQuestionAboutClearingRoutePoints()
	
	QueryText = NStr("vi = 'Danh sách các điểm trên lộ trình sẽ bị xóa. Tiếp tục?';
					|ru = 'Список пунктов маршрута будет очищен. Продолжить?';
					|en = 'The route point list will be cleared. Continue?'; fa = 'The route point list will be cleared. Continue?';
					|it = 'The route point list will be cleared. Continue?';
					|pl = 'The route point list will be cleared. Continue?';
					|tr = 'Rota noktaları listesi temizlenecek. Devam edilsin mi?'");
	Promise = DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
	
	Return Promise;
	
EndFunction

&AtServerNoContext
Function VersionOfReportKitsAccordingToTripOrders(Val Trip)
	
	Variant = Reports.PickingUnderTrip.VersionOfFlightReport(Trip);
	Return Variant;
	
EndFunction

&AtServer
Procedure SetUseOfTripStateHyperlink()
	
	ReportVariantParameters = Reports.PickingUnderTrip.ParametersOfTripReportOption(Object.Ref);
	Items.SceneryStateOfFlight.Hyperlink = ReportVariantParameters.WarehouseUsesOrderScheme;
	
EndProcedure

&AtServer
Procedure FillInAdditionalRouteFields(Val UpdateCancelFlag = False, Val UpdateDeliveryTime = False)
	
	AuxiliaryDataCache = New Map;
	
	For Each RowWithContent In Object.Content Do
		
		AuxiliaryData = AuxiliaryDataCache[RowWithContent.ConnectionKey];
		
		If AuxiliaryData = Undefined Then
			
			If RowWithContent.Canceled Then
				RowsCountCanceled = 1;
			Else
				RowsCountCanceled = 0;
			EndIf;
			
			AuxiliaryData = New Structure;
			AuxiliaryData.Insert("NumberOfRowsTotal", 1);
			AuxiliaryData.Insert("RowsCountCanceled", RowsCountCanceled);
			AuxiliaryData.Insert("DeliveryTimeFrom", RowWithContent.DeliveryTimeFrom);
			AuxiliaryData.Insert("DeliveryTimeTo", RowWithContent.DeliveryTimeTo);
			AuxiliaryData.Insert("DeliveryTimeIsDifferent", False);
			
		Else
			
			AuxiliaryData.NumberOfRowsTotal = AuxiliaryData.NumberOfRowsTotal + 1;
			If RowWithContent.Canceled Then
				AuxiliaryData.RowsCountCanceled = AuxiliaryData.RowsCountCanceled + 1;
			EndIf;
			
			If RowWithContent.DeliveryTimeFrom > AuxiliaryData.DeliveryTimeFrom Then
				
				If ValueIsFilled(AuxiliaryData.DeliveryTimeFrom) Then
					AuxiliaryData.DeliveryTimeIsDifferent = True;
				EndIf;
				AuxiliaryData.DeliveryTimeFrom = RowWithContent.DeliveryTimeFrom;
				
			EndIf;
			
			If RowWithContent.DeliveryTimeTo < AuxiliaryData.DeliveryTimeTo
				And ValueIsFilled(RowWithContent.DeliveryTimeTo) Then
				
				AuxiliaryData.DeliveryTimeIsDifferent = True;
				AuxiliaryData.DeliveryTimeTo = RowWithContent.DeliveryTimeTo;
				
			EndIf;
			
			If Not ValueIsFilled(AuxiliaryData.DeliveryTimeTo)
				And ValueIsFilled(RowWithContent.DeliveryTimeTo) Then
				
				AuxiliaryData.DeliveryTimeTo = RowWithContent.DeliveryTimeTo;
				
			EndIf;
			
			If ValueIsFilled(RowWithContent.DeliveryTimeFrom)
				And ValueIsFilled(AuxiliaryData.DeliveryTimeFrom)
				And RowWithContent.DeliveryTimeFrom <> AuxiliaryData.DeliveryTimeFrom Then
				
				AuxiliaryData.DeliveryTimeIsDifferent = True;
				
			EndIf;
			
			If ValueIsFilled(RowWithContent.DeliveryTimeTo)
				And ValueIsFilled(AuxiliaryData.DeliveryTimeTo)
				And RowWithContent.DeliveryTimeTo <> AuxiliaryData.DeliveryTimeTo Then
				
				AuxiliaryData.DeliveryTimeIsDifferent = True;
				
			EndIf;
			
		EndIf;
		
		AuxiliaryDataCache[RowWithContent.ConnectionKey] = AuxiliaryData;
		
	EndDo;
	
	For Each RouteString In Object.Route Do
		
		AuxiliaryData = AuxiliaryDataCache[RouteString.ConnectionKey];
		
		RouteString.PartiallyCancelled = False;
		
		If AuxiliaryData = Undefined Then
			Continue;
		EndIf;
		
		RouteLineCanceled = False;
		
		If AuxiliaryData.RowsCountCanceled > 0 Then
			
			If AuxiliaryData.NumberOfRowsTotal <> AuxiliaryData.RowsCountCanceled Then
				
				RouteString.PartiallyCancelled = True;
				
			Else
				
				RouteLineCanceled = True;
				
			EndIf;
			
		EndIf;
		
		If UpdateCancelFlag Then
			RouteString.Canceled = RouteLineCanceled;
		EndIf;
		
		If AuxiliaryData.DeliveryTimeFrom > AuxiliaryData.DeliveryTimeTo Then
			
			EmptyTime = '00010101';
			AuxiliaryData.DeliveryTimeFrom = EmptyTime;
			AuxiliaryData.DeliveryTimeTo = EmptyTime;
			AuxiliaryData.DeliveryTimeIsDifferent = False;
			
		EndIf;
		
		If UpdateDeliveryTime
			And Not ValueIsFilled(RouteString.DeliveryTimeFrom)
			And Not ValueIsFilled(RouteString.DeliveryTimeTo) Then
			
			RouteString.DeliveryTimeFrom = AuxiliaryData.DeliveryTimeFrom;
			RouteString.DeliveryTimeTo = AuxiliaryData.DeliveryTimeTo;
			
		EndIf;
		
		If ValueIsFilled(RouteString.DeliveryTimeFrom)
			And ValueIsFilled(AuxiliaryData.DeliveryTimeFrom)
			And RouteString.DeliveryTimeFrom <> AuxiliaryData.DeliveryTimeFrom Then
			
			AuxiliaryData.DeliveryTimeIsDifferent = True;
			
		EndIf;
		
		If ValueIsFilled(RouteString.DeliveryTimeTo)
			And ValueIsFilled(AuxiliaryData.DeliveryTimeTo)
			And RouteString.DeliveryTimeTo <> AuxiliaryData.DeliveryTimeTo Then
			
			AuxiliaryData.DeliveryTimeIsDifferent = True;
			
		EndIf;
		
		RouteString.DeliveryTimeIsDifferent = AuxiliaryData.DeliveryTimeIsDifferent;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UndoContentLines(CancellationReason)
	
	For Each ItemLine In Object.Content Do
		
		If ItemLine.ConnectionKey <> RouteStartLinkKey
		   And Not ValueIsFilled(ItemLine.CancellationReason) Then
			
			ItemLine.Canceled = True;
			ItemLine.CancellationReason = CancellationReason;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function AllContentLinesAreCanceled()
	
	AllLinesAreCanceled = True;
	
	For Each ItemLine In Object.Content Do
		
		If ItemLine.ConnectionKey <> RouteStartLinkKey
		   And Not ValueIsFilled(ItemLine.CancellationReason) Then
			
			AllLinesAreCanceled = False;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return AllLinesAreCanceled;
	
EndFunction

// Parameters:
//  ClosingResult - CatalogRef.DeliveryCancellationReasons, Undefined - 
//  AdditionalParameters - EnumRef.TripStatuses -
//
&AtClient
Procedure FinishSelectingReasonForCancellation(ClosingResult, AdditionalParameters) Export
	
	If ValueIsFilled(ClosingResult) Then
		
		UndoContentLines(ClosingResult);
		StatusOnChangeServer();
		
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
		
	Else
		
		StatusBeforeChange = AdditionalParameters;
		CurrentStatus = StatusBeforeChange;
		Object.Status = StatusBeforeChange;
		
	EndIf;
	
EndProcedure

&AtClient
Function ThisIsStartLineOfRoute(RowData)
	
	ThisIsBeginningOfRoute = (RowData.ConnectionKey = RouteStartLinkKey);
	Return ThisIsBeginningOfRoute;
	
EndFunction

// Parameters:
//  MovingUp - Boolean -
// 
// Returns:
//  Array of Number -
//
&AtClient
Function NumbersOfSelectedRouteLines(MovingUp = True)
	
	RowsIDs = Items.Route.SelectedRows;
	RowsData = New Array; // Array of Structure
	LineNumbers = New Array; // Array of Number
	
	For Each Id In RowsIDs Do
		
		RowData = Object.Route.FindByID(Id);
		If Not ThisIsStartLineOfRoute(RowData) Then
			
			LineNumber = RowData.LineNumber;
			LineNumbers.Add(LineNumber);
			
			TheseNumbers = New Structure;
			TheseNumbers.Insert("Id", Id);
			TheseNumbers.Insert("LineNumber", LineNumber);
			RowsData.Add(TheseNumbers);
			
		EndIf;
		
	EndDo;
	
	If MovingUp Then
		
		LineNumbers = TMCommonUseClientServer.Sorted_Array(LineNumbers, SortDirection.Asc);
		
	Else
		
		LineNumbers = TMCommonUseClientServer.Sorted_Array(LineNumbers, SortDirection.Desc);
		
	EndIf;
	
	Return LineNumbers;
	
EndFunction

&AtClient
Procedure SetAvailabilityOfCommandsInRoutesTable()
	
	ThisIsInitialLineOfRoute = ThisIsStartLineOfRoute(Items.Route.CurrentData);
	SetAvailabilityOfCommandsInRoutesTableServer(ThisIsInitialLineOfRoute);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfCommandsInRoutesTableServer(Val InitialLineOfRoute)
	
	LinesCanBeChanged = RouteCompositionCanBeChanged();
	
	Items.Route.ChangeRowOrder = Not InitialLineOfRoute;
	Items.Route.ChangeRowSet =
		(Not InitialLineOfRoute
			And LinesCanBeChanged);
	Items.Route.EnableStartDrag = Not InitialLineOfRoute;
	
	ElementsOfMovement = New Array; // Array of String
	ElementsOfMovement.Add(Items.RouteMoveUp.Name);
	ElementsOfMovement.Add(Items.RouteMoveDown.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ElementsOfMovement,
		"Enabled",
		Not InitialLineOfRoute);
	
EndProcedure

&AtServer
Function RouteCompositionCanBeChanged()
	
	Result =
		Not (Object.Status = Enums.TripStatuses.Generated1
			Or Object.Status = Enums.TripStatuses.Shipped_5
			Or Object.Status = Enums.TripStatuses.Completed);

	Return Result;
	
EndFunction

&AtServer
Procedure FillInShipmentSignAfterFormationOfFlight()
	
	ShipmentAfterFormationOfFlight = False;
	If Not Object.DepartureWarehouse.IsEmpty() Then
		
		ShipmentAfterFormationOfFlight = WarehousesServer.StartShipmentOnceDeliveryOrderIsCreated(Object.DepartureWarehouse);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfCommandsInOrderList()
	
	OrdersUnchanged =
		(Object.Status = Enums.TripStatuses.Shipped_5
			Or Object.Status = Enums.TripStatuses.Completed
			Or Object.Status = Enums.TripStatuses.RolledBack_);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"OrdersListUpdateShipmentDateOfOrders",
		"Enabled",
		Not OrdersUnchanged And Not ReadOnly);
	
EndProcedure

&AtServer
Procedure UpdateDisplayOfListOfOrders()
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"OrdersList",
		"Visible",
		ShipmentAfterFormationOfFlight);
	
EndProcedure

&AtServer
Procedure SetSelectionOfOrders()
	
	If ShipmentAfterFormationOfFlight
		And Not Object.Ref.IsEmpty() Then
		
		CommonClientServer.SetDynamicListFilterItem(
			OrdersList, "TransportationJob", Object.Ref,,, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateShipmentDateOfOrdersServer(Val Orders_ToBeProcessed, ActionCompleted)
	
	MessageTemplate = NStr("vi = 'Không thể xử lý %1 do nguyên nhân: %2';
							|ru = 'Не удалось обработать %1 по причине: %2';
							|en = 'Cannot process %1 due to: %2'; fa = 'Cannot process %1 due to: %2';
							|it = 'Cannot process %1 due to: %2';
							|pl = 'Cannot process %1 due to: %2';
							|tr = '%1 işlenemedi, sebep: %2'");
	
	Query = New Query;
	QueryText =
	"SELECT
	|	ExpenseOrder.Ref AS Ref,
	|	ExpenseOrder.Presentation AS Presentation
	|FROM
	|	Document.GoodsIssueNote AS ExpenseOrder
	|WHERE
	|	ExpenseOrder.Ref IN(&Orders_ToBeProcessed)
	|	AND ExpenseOrder.Status = VALUE(Enum.GoodsIssueNoteStatuses.Prepared)
	|	AND (ExpenseOrder.DateOfShipment < &BeginningOfDayOfDeparture
	|			OR ExpenseOrder.DateOfShipment > &EndOfDepartureDay)
	|	AND ExpenseOrder.ShipmentUnderTransportationJob
	|	AND ExpenseOrder.TransportationJob = &Trip
	|	AND NOT ExpenseOrder.DeletionMark";
	Query.Text = QueryText;
	
	Query.SetParameter("Orders_ToBeProcessed", Orders_ToBeProcessed);
	Query.SetParameter("Trip", Object.Ref);
	Query.SetParameter("BeginningOfDayOfDeparture", BegOfDay(Object.DateOfDeparture));
	Query.SetParameter("EndOfDepartureDay", EndOfDay(Object.DateOfDeparture));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DocumentPresentation = Selection.Presentation; // String
		SpendingOrderLink = Selection.Ref; // DocumentRef.GoodsIssueNote
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("Document.GoodsIssueNote");
			LockItem.SetValue("Ref", SpendingOrderLink);
			Block.Lock();
			
			SpendingOrderObject = SpendingOrderLink.GetObject();
			
			SpendingOrderObject.DateOfShipment = Object.DateOfDeparture;
			
			SpendingOrderObject.DateOfShipment = Object.DateOfDeparture;
			
			ChangeBanLine = "";
			ChangesAreDisabled = PeriodClosingDates.DataChangesDenied(SpendingOrderObject, SpendingOrderLink, ChangeBanLine);
			
			If ChangesAreDisabled Then
				
				RollbackTransaction();
				
				Common.MessageToUser(ChangeBanLine);
				Continue;
				
			EndIf;
			
			If SpendingOrderObject.Posted Then
				SpendingOrderObject.Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
			Else
				SpendingOrderObject.Write(DocumentWriteMode.Write);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			Cause = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				DocumentPresentation,
				Cause);
				
			Common.MessageToUser(MessageText);
			
			Continue;
			
		EndTry;
		
		ActionCompleted = True;
		
	EndDo;
	
EndProcedure

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

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
