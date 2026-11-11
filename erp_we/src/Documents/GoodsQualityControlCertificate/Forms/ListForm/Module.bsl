
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, 
		"Warehouse", 
		WarehouseSelection, 
		QuickFilterStructure,
		Settings);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List,
		"Status",
		StatusFilter,
		QuickFilterStructure,
		Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Warehouse", WarehouseSelection, DataCompositionComparisonType.Equal, Undefined, ValueIsFilled(WarehouseSelection));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Status", StatusFilter, DataCompositionComparisonType.Equal, Undefined, ValueIsFilled(StatusFilter));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetStatus_InProgress(Command)
	
	SetStatus("InProgress", NStr("vi = 'Đang xử lý';
								|ru = 'В работе';
								|en = 'In progress'; fa = 'در حال انجام';
								|it = 'In esecuzione';
								|pl = 'Wykonuje się';
								|tr = 'İşleniyor'"));
	
EndProcedure

&AtClient
Procedure SetStatusAwaitingDecision(Command)
	
	SetStatus("AwaitingDecision", NStr("vi = 'Đang chờ quyết định';
										|ru = 'Ожидает решения';
										|en = 'Awaiting decision'; fa = 'در انتظار تصمیم';
										|it = 'Awaiting decision';
										|pl = 'Awaiting decision';
										|tr = 'Karar bekleniyor'"));
	
EndProcedure

&AtClient
Procedure SetStatusFulfilled(Command)
	
	SetStatus("IsProcessed", NStr("vi = 'Đã xử lý';
									|ru = 'Отработан';
									|en = 'Processed'; fa = 'پردازش‌شده';
									|it = 'Processed';
									|pl = 'Processed';
									|tr = 'İşlendi'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

&AtClient
Procedure SetStatus(StatusName, StatusPresentation)

	RowsSelected = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If RowsSelected.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(RowsSelected, StatusName);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List,
		ProcessedItemsCount, RowsSelected.Count(), StatusPresentation);
	
EndProcedure

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

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
