// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		Items.List.ChangeRowSet = False;
	EndIf;
	
	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtServer
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array(); // Array of DocumentManager
	Managers.Add(Documents.SalesOrder);
	
	Return BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanTripEndTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày về ngày kết thúc dự kiến ​​ngày hôm nay: ""09:46""';
							|ru = 'Представление плановой даты окончания сегодня: ""09:46""';
							|en = 'Planned end date presentation today: ""09:46""'; fa = 'Planned end date presentation today: ""09:46""';
							|it = 'Представление плановой даты окончания сегодня: ""09:46""';
							|pl = 'Przedstawienie planowanej daty zakończenia dzisiaj: ""09:46""';
							|tr = 'Bugünkü planlanan bitiş tarihinin görünümü: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.PlanTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.PlanTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.PlanTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
	// Representation of the actual flight end date today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualTripEndTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày ngày kết thúc hôm nay: ""09:46""';
							|ru = 'Представление даты окончания сегодня: ""09:46""';
							|en = 'End date presentation today: ""09:46""'; fa = 'End date presentation today: ""09:46""';
							|it = 'Представление даты окончания сегодня: ""09:46""';
							|pl = 'End date presentation today: ""09:46""';
							|tr = 'Bugünkü bitiş tarihinin görünümü: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.ActualTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.ActualTripEndTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.ActualTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
	// Presentation of the planned start date of the flight today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanTripStartTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày ngày dự tính bắt đầu hôm nay: ""09:46""';
							|ru = 'Представление плановой даты начала сегодня: ""09:46""';
							|en = 'Planned start date presentation today: ""09:46""'; fa = 'Planned start date presentation today: ""09:46""';
							|it = 'Представление плановой даты начала сегодня: ""09:46""';
							|pl = 'Planned start date presentation today: ""09:46""';
							|tr = 'Bugünkü planlanan başlangıç tarihinin görünümü: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.PlanTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.PlanTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
	// Presentation of the planned start date of the flight today: "09:46"
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualTripStartTime.Name);
	
	ItemPresentation = NStr("vi = 'Trình bày ngày bắt đầu hôm nay: ""09:46""';
							|ru = 'Представление даты начала сегодня: ""09:46""';
							|en = 'Start date presentation today: ""09:46""'; fa = 'Start date presentation today: ""09:46""';
							|it = 'Представление даты начала сегодня: ""09:46""';
							|pl = 'Start date presentation today: ""09:46""';
							|tr = 'Bugünkü başlangıç tarihinin görünümü: ""09:46""'");
	ConditionalAppearanceItem.Presentation = ItemPresentation;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.ActualTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("List.ActualTripStartTime");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DF=HH:mm");
	
EndProcedure

#EndRegion
