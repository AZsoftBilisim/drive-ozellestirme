#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	SelectionsWhenCreatedOnServer();
	
	#EndRegion
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	#Region IntegratedSubsystems
	
	SelectionsBeforeUploadingDataFromSettingsAtServer(Settings);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#Region IntegratedSubsystems
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	#Region IntegratedSubsystems
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	#Region IntegratedSubsystems
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(
				New CallbackDescription("NotificationProcessingCompletion",
					ThisObject,
					New Structure("EventName", EventName)),
				EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
			Return;
		EndIf;
	EndIf;
	// End Peripherals
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOnChange(Item)
	
	FilterValue = ThisObject[Item.Name];
	CommonClientServer.SetDynamicListFilterItem(List,
		Item.Name,
		FilterValue,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(FilterValue));
	
EndProcedure
	
&AtClient
Procedure FilterOpening(Item, StandardProcessing)
	
	// The platform Form does not clear messages when you click Ok.
	// If you select duplicate values in it, error messages will be duplicated when you repeatedly click "Ok".
	// Redefining Forms to view list values:
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	
	OpeningParameters.Insert("DocumentsArray",  ThisObject[Item.Name].UnloadValues());
	OpeningParameters.Insert("FormCaption", NStr("vi = 'Giá trị lọc';
												|ru = 'Значения отбора';
												|en = 'Filter values'; fa = 'مقادیر فیلتر';
												|it = 'Filter values';
												|pl = 'Filter values';
												|tr = 'Filtre değerleri'"));
	
	OpenForm("CommonForm.ListOfCustomObjectsERP",
		OpeningParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalListAppearanceClientServer.NewDesignElement(List,
		New Array,
		"TextColor",
		StyleColors.ClosedDocument,
		"Status",
		Enums.PurchaseRequestStatuses.FinalStatuses(),
		DataCompositionComparisonType.InList);
		
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
		
EndProcedure

#Region IntegratedSubsystems

#Region Filters

&AtServer
Procedure SelectionsWhenCreatedOnServer()
	
	QuickFilterStructure = Parameters.QuickFilterStructure;
	If Not ValueIsFilled(QuickFilterStructure) Then
		// Selections were not transferred.
		Return;
	EndIf;
	
	For Each KeyAndValue In QuickFilterStructure Do
		
		FilterFieldName = KeyAndValue.Key;
		FilterValue = KeyAndValue.Value;
		
		CommonClientServer.SupplementList(ThisObject[FilterFieldName], FilterValue);
		CommonClientServer.SetDynamicListFilterItem(
			List,
			FilterFieldName,
			FilterValue,
			DataCompositionComparisonType.InList,,
			ValueIsFilled(FilterValue));
			
	EndDo;
		
EndProcedure

&AtServer
Procedure SelectionsBeforeUploadingDataFromSettingsAtServer(Settings)
	
	SelectionsAreInitialized = ValueIsFilled(QuickFilterStructure);
	
	For Each KeyAndValue In Common.ObjectManagerByFullName(List.MainTable).NewListSelection() Do
		
		FilterFieldName = KeyAndValue.Key;
		FilterValue = Settings[KeyAndValue.Key];
		
		Settings.Delete(FilterFieldName);
		
		If SelectionsAreInitialized Then
			Continue; // The values are set from the parameters.
		EndIf;
		
		CommonClientServer.SupplementList(ThisObject[FilterFieldName], FilterValue);
		CommonClientServer.SetDynamicListFilterItem(
			List,
			FilterFieldName,
			FilterValue,
			DataCompositionComparisonType.InList,,
			ValueIsFilled(FilterValue));
		
	EndDo;
	
EndProcedure

#EndRegion

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
    AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
    ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
    AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
&AtClient
Procedure Attachable_UpdateCommands()
    AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region IntegrationWith1CDocumentManagementSubsystem

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(Val Notification, Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		ShowValue(New CallbackDescription("ProcessBarcodesCompletion", ThisObject, New Structure("Data, Notification", Data, Notification)), Ref);
		Return;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
	ProcessBarcodesFragment(Notification);
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array;
	Managers.Add(PredefinedValue("Document.ApplicationForCollateral.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodesCompletion(AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	ProcessBarcodesFragment(Notification);

EndProcedure

&AtClient
Procedure ProcessBarcodesFragment(Val Notification)

	RunCallback(Notification);

EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export

	EventName = AdditionalParameters.EventName;
	HandlingFragmentAlerts(EventName);

EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName)
	Return;
EndProcedure

#EndRegion

#EndRegion

#EndRegion

