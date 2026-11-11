
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	RequestsIsAvailable = AccessRight("Edit", Metadata.Documents.PaymentRequest);
	
	If Not RequestsIsAvailable Then
		Items.List.Visible = False;
		Items.RequestGroup.Visible = False;
	Else
		StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	EndIf;
	
	SetListParameters();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.GroupRequestsCommands;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.OrderListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_PaymentRequest" Then
		Items.OrderList.Refresh();
	EndIf;
	
	// Subsystem "Electronic documents"
	If EventName = "UpdateEdState" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization = Settings.Get("Organization");
	DisplayOrders = Settings.Get("DisplayOrders");
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(OrderList, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
	DisplayOrdersOnChangeServer();
	
	DisplayRequests = Settings.Get("DisplayRequests");
	DisplayRequestsOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)

	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(OrderList, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure PaymentDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetListParameters();
	
EndProcedure

&AtClient
Procedure DisplayOrdersOnChange(Item)

	DisplayOrdersOnChangeServer();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrderList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.OrderList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure DisplayRequestsOnChange(Item)
	
	DisplayRequestsOnChangeServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "OrderList.Date", Items.ListDate.Name);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtServer
Procedure SetListParameters()
	
	PaymentDateBorder = New Boundary(EndOfDay(PaymentDate), BoundaryType.Including);
	OrderList.Parameters.SetParameterValue("PaymentDate", ?(ValueIsFilled(PaymentDate), PaymentDateBorder, Date('22990101')));
	
	List.Parameters.SetParameterValue(
		"UsePaymentsToSelfEmployedPersons",
		GetFunctionalOption("UsePaymentsToSelfEmployedPersons"));
	
EndProcedure

&AtServer
Procedure DisplayOrdersOnChangeServer()

	If DisplayOrders = 0 Then
		CommonClientServer.SetDynamicListFilterItem(
			OrderList, "YouNeedToCreateARequest", False, DataCompositionComparisonType.Equal,, False);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			OrderList, "YouNeedToCreateARequest", True, DataCompositionComparisonType.Equal,, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayRequestsOnChangeServer()

	If DisplayRequests = 0 Then // All
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RequestIsPaid",
			False,
			DataCompositionComparisonType.Equal,	,
			False);
		
	ElsIf DisplayRequests = 1 Then // Unpaid
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RequestIsPaid",
			False,
			DataCompositionComparisonType.Equal,,
			True);
		
	ElsIf DisplayRequests = 2 Then // Paid_
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RequestIsPaid",
			True,
			DataCompositionComparisonType.Equal,,
			True);
	EndIf;
	
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
	If Item.Name = "sh_ShamsiInput_F_PaymentDate" Then
		PaymentDateOnChange(Items.PaymentDate);
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
