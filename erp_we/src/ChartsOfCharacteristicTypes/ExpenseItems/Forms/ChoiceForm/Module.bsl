
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	SetDynamicListParameters();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	ChartsOfCharacteristicTypes.ExpenseItems.ProcessingSelectionParameters(Parameters);
	BusinessOperation = Undefined;
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("BusinessOperation") Then
			
			If ValueIsFilled(Parameters.Filter.BusinessOperation) Then
				BusinessOperation = Parameters.Filter.BusinessOperation;
			EndIf;
			Parameters.Filter.Delete("BusinessOperation");
			
		EndIf;
		
		CostAllocationOption = Undefined;
		If Parameters.Filter.Property("CostAllocationOption", CostAllocationOption) Then
			If ValueIsFilled(CostAllocationOption) Then
				CommonClientServer.SetDynamicListFilterItem(
					List,
					"CostAllocationOptionManag",
					CostAllocationOption,
					DataCompositionComparisonType.InList,,
					True);
				CommonClientServer.SetDynamicListFilterItem(
					List,
					"CostAllocationOptionLocal",
					CostAllocationOption,
					DataCompositionComparisonType.InList,,
					True);
				DistributionOptions = New Array();
				DistributionOptions.Add(CostAllocationOption);
				DistributionOptions.Add(Enums.CostAllocationOptions.EmptyRef());
				CommonClientServer.SetDynamicListFilterItem(
					List,
					"CostAllocationOptionTax",
					DistributionOptions,
					DataCompositionComparisonType.InList,,
					True);	
			EndIf;
			Parameters.Filter.Delete("CostAllocationOption");
		EndIf;
		
		If Parameters.Filter.Property("CostSharingOptionOr", CostAllocationOption) Then
			If ValueIsFilled(CostAllocationOption) Then
				FilterGroup = CommonClientServer.CreateFilterItemGroup(
					List.SettingsComposer.FixedSettings.Filter.Items,
					NStr("vi = 'Phương án phân bổ chi phí';
						|ru = 'Варианты распределения расходов';
						|en = 'Expense allocation options'; fa = 'گزینه‌های تسهیم هزینه';
						|it = 'Variante di allocazione delle spese';
						|pl = 'Warianty przydziału kosztów';
						|tr = 'Gider dağıtım seçenekleri'"), 
					DataCompositionFilterItemsGroupType.OrGroup);
				CommonClientServer.SetFilterItem(
					FilterGroup,
					"CostAllocationOptionManag",
					CostAllocationOption, 
					DataCompositionComparisonType.InList,
					"CostAllocationOptionManag",
					True);
				CommonClientServer.SetFilterItem(
					FilterGroup,
					"CostAllocationOptionLocal",
					CostAllocationOption, 
					DataCompositionComparisonType.InList,
					"CostAllocationOptionLocal",
					True);
			EndIf;
			Parameters.Filter.Delete("CostSharingOptionOr");
		EndIf;
		
		ActivityTypeForTaxAccountingOfCosts = Undefined;
		If Parameters.Filter.Property("ActivityTypeForTaxAccountingOfCosts", ActivityTypeForTaxAccountingOfCosts) Then
			If ValueIsFilled(ActivityTypeForTaxAccountingOfCosts) Then
				CommonClientServer.SetDynamicListFilterItem(
					List,
					"ActivityTypeForTaxAccountingOfCosts",
					ActivityTypeForTaxAccountingOfCosts,
					DataCompositionComparisonType.InList,,
					True);
				EndIf;
			Parameters.Filter.Delete("ActivityTypeForTaxAccountingOfCosts");
		EndIf;
	
	EndIf;
	If Parameters.Filter.Property("RepairCosts") Then
		
		FilterGroup = CommonClientServer.CreateFilterItemGroup(
			List.SettingsComposer.FixedSettings.Filter.Items,
			NStr("vi = 'Chi phí sửa chữa';
				|ru = 'Расходы на ремонт';
				|en = 'R&M costs'; fa = 'R&M costs';
				|it = 'Spese di riparazione';
				|pl = 'Rozchody na remont';
				|tr = 'Bakım-onarım giderleri'"), 
			DataCompositionFilterItemsGroupType.OrGroup);
			
		CommonClientServer.SetFilterItem(
			FilterGroup,
			"ExpensesOnAssets",
			True, 
			DataCompositionComparisonType.Equal,
			"ExpensesOnAssets",
			True);
			
		CommonClientServer.SetFilterItem(
			FilterGroup,
			"RMOrderExpenses",
			True, 
			DataCompositionComparisonType.Equal,
			"RMOrderExpenses",
			True);
			
		Parameters.Filter.Delete("RepairCosts");
		
	EndIf;
	List.Parameters.SetParameterValue("BusinessOperation", BusinessOperation);
	List.Parameters.SetParameterValue("WithoutRestrictionOfUse", Not ValueIsFilled(BusinessOperation));
	
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
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
