
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInHeader();
	
	AttachableCommands.OnCreateAtServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.CommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FilterEmployeeResponsible = Settings.Get("FilterEmployeeResponsible");
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "EmployeeResponsible", FilterEmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterEmployeeResponsible));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "EmployeeResponsible", FilterEmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterEmployeeResponsible));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


#Region StandardCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "List.Date", Items.Date.Name);
	
	
EndProcedure

&AtServer
Procedure FillInHeader()
	
	Parameter = NStr("vi = 'khách hàng';
					|ru = 'клиентов';
					|en = 'customers'; fa = 'مشتریان';
					|it = 'customers';
					|pl = 'customers';
					|tr = 'müşteriler'");
	
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		
		Parameter = Parameter
			+ " / "
			+ NStr("vi = 'Bên bảo quản';
					|ru = 'хранителей';
					|en = 'custodians'; fa = 'custodians';
					|it = 'custodians';
					|pl = 'custodians';
					|tr = 'Emanetçiler'");
		
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission") Then
		
		Parameter = Parameter
			+ " / "
			+ NStr("vi = 'người nhận ký gửi';
					|ru = 'комиссионеров';
					|en = 'consignees'; fa = 'consignees';
					|it = 'consignees';
					|pl = 'consignees';
					|tr = 'konsinyeler'");
		
	EndIf;
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
		
		Parameter = Parameter
			+ ", "
			+ NStr("vi = 'ghi tăng hàng thừa đã giao';
					|ru = 'оприходования излишков отгруженных товаров';
					|en = 'stock surpluses of shipped goods'; fa = 'stock surpluses of shipped goods';
					|it = 'stock surpluses of shipped goods';
					|pl = 'stock surpluses of shipped goods';
					|tr = 'sevk edilen fazladan ürünlerin kabulü'");
		
	EndIf;
	
	Title = StrTemplate(NStr("vi = 'Ghi tăng hàng thừa của %1';
							|ru = 'Оприходования излишков товаров у %1';
							|en = 'Stock surplus recognition at %1'; fa = 'Stock surplus recognition at %1';
							|it = 'Accettazione eccedenze articoli presso %1';
							|pl = 'Rejestracja nadwyżek towarów u %1';
							|tr = '%1 tarafında stok fazlası tahakkuku'"), Parameter);
	
EndProcedure

#Region StandardCommands

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

#EndRegion

#EndRegion
