
#Region FormEventHandlers

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Filter.Property("Partner") Then
		Items.CustomerSupplier.Visible = False;
		Return;
	EndIf;

	Partner = Settings.Get("Partner");
	CommonClientServer.SetDynamicListFilterItem(List, "Partner",Partner, DataCompositionComparisonType.Equal,, ValueIsFilled(Partner));
	
	EmployeeResponsible  = Settings.Get("EmployeeResponsible");
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));

	Status = Settings.Get("Status");
	If Status = "New_Items" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",Enums.CustomerComplaintStatuses.Registered1,DataCompositionComparisonType.Equal,True);
	ElsIf Status = "InProcessing" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",Enums.CustomerComplaintStatuses.InProcessing,DataCompositionComparisonType.Equal,True);
	ElsIf Status = "Fulfilled" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",Enums.CustomerComplaintStatuses.Fulfilled_,DataCompositionComparisonType.Equal,True);
	ElsIf Status = "NotFulfilled" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",Enums.CustomerComplaintStatuses.NotFulfilled_,DataCompositionComparisonType.Equal,True);
	ElsIf Status = "Finished" Then
		StatusesList = New ValueList;
		StatusesList.Add(Enums.CustomerComplaintStatuses.Fulfilled_);
		StatusesList.Add(Enums.CustomerComplaintStatuses.NotFulfilled_);
		CommonClientServer.SetDynamicListFilterItem(List,"Status",StatusesList,DataCompositionComparisonType.InList,True); 
	ElsIf Status = "NotFinished" Then
		StatusesList = New ValueList;
		StatusesList.Add(Enums.CustomerComplaintStatuses.Fulfilled_);
		StatusesList.Add(Enums.CustomerComplaintStatuses.NotFulfilled_);
		CommonClientServer.SetDynamicListFilterItem(List,"Status",StatusesList,DataCompositionComparisonType.NotInList,True);
	EndIf;
	
	If IsBlankString(Status) Then
		Status = "All";
		Settings.Delete("Status");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Status = "All";
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure 

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ClientOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, ValueIsFilled(Partner));
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Completed");
	CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Status");
	
	If Status = "New_Items" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",PredefinedValue("Enum.CustomerComplaintStatuses.Registered1"),DataCompositionComparisonType.Equal,True);
	ElsIf Status = "InProcessing" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",PredefinedValue("Enum.CustomerComplaintStatuses.InProcessing"),DataCompositionComparisonType.Equal,True);
	ElsIf Status = "Fulfilled" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",PredefinedValue("Enum.CustomerComplaintStatuses.Fulfilled_"),DataCompositionComparisonType.Equal,True);
	ElsIf Status = "NotFulfilled" Then
		CommonClientServer.SetDynamicListFilterItem(List,"Status",PredefinedValue("Enum.CustomerComplaintStatuses.NotFulfilled_"),DataCompositionComparisonType.Equal,True);
	ElsIf Status = "Finished" Then
		StatusesList = New ValueList;
		StatusesList.Add(PredefinedValue("Enum.CustomerComplaintStatuses.Fulfilled_"));
		StatusesList.Add(PredefinedValue("Enum.CustomerComplaintStatuses.NotFulfilled_"));
		CommonClientServer.SetDynamicListFilterItem(List,"Status",StatusesList,DataCompositionComparisonType.InList,True);
	ElsIf Status = "NotFinished" Then
		StatusesList = New ValueList;
		StatusesList.Add(PredefinedValue("Enum.CustomerComplaintStatuses.Fulfilled_"));
		StatusesList.Add(PredefinedValue("Enum.CustomerComplaintStatuses.NotFulfilled_"));
		CommonClientServer.SetDynamicListFilterItem(List,"Status",StatusesList,DataCompositionComparisonType.NotInList,True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusFilterClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Status = "All";
	StatusFilterOnChange(Item);
	
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

#Region FormControlEventHandlers

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDragCheck(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	// StandardSubsystems.Interactions
	InteractionsClient.ListSubjectDrag(Item, DragParameters, StandardProcessing, String, Field);
	// End StandardSubsystems.Interactions

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Catalog.Complaints.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

// StandardSubsystems.AttachableCommands
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

#EndRegion
