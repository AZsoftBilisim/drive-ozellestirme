#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	SetDynamicListParameters();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Metadata.ChartsOfAccounts.Find("SelfSupporting") <> Undefined Then
		Items.OffsettingAccount.Visible = False;
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.ChartsOfCharacteristicTypes.ExpenseItems);
	Items.FormChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	GenerateFinancialResult = GetFunctionalOption("GenerateFinancialResult");
		
	ThisIsUTBasic = GetFunctionalOption("BaseVersion");
	If ThisIsUTBasic Then
		Items.CostAllocationOptionLocal.Title = NStr("vi = 'Phương án phân bổ';
													|ru = 'Вариант распределения';
													|en = 'Allocation option'; fa = 'گزینه تسهیم';
													|it = 'Opzione di ripartizione';
													|pl = 'Wersja pakietów instalacyjnych';
													|tr = 'Dağıtım seçeneği'");
		Items.CostAllocationOptionManag.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Item = List.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValueType.Name);

	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("DimensionOfExpensesOrderImplementation");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đơn hàng / Giao hàng';
													|ru = 'Заказ / Реализация';
													|en = 'Order / Sale'; fa = 'سفارش / فروش';
													|it = 'Ordine / Vendita';
													|pl = 'Zamówienie / Sprzedaż';
													|tr = 'Sipariş / Satış'"));
	
EndProcedure

&AtServer
Procedure SetDynamicListParameters()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref",
		ChartsOfCharacteristicTypes.ExpenseItems.BlockedExpenditureItems(),
		DataCompositionComparisonType.NotInList);

	
EndProcedure

#EndRegion
