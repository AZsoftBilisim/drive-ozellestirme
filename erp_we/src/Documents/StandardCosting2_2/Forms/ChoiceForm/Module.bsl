#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	#Region Filters
	
	QuickFilterStructure = Undefined;
	FilterStructure1 = Undefined;
	Parameters.Property("FilterStructure1", FilterStructure1);
	
	If FilterStructure1 <> Undefined Then
		
		UseCompanySelection = ValueIsFilled(FilterStructure1.Organization);
		UseSelectionDivisionDispatcher = ValueIsFilled(FilterStructure1.ProductionDispatcherBusinessUnit);
		UseSelectionMaximumDateOfPlannedCalculations = ValueIsFilled(
			FilterStructure1.Date);
		ShowOnlyLatestProductStandardCostEstimates = ValueIsFilled(FilterStructure1.Date);
		DisableSelectionByCostObjects = FilterStructure1.Property("DisableSelectionByCostObjects")
			And FilterStructure1.DisableSelectionByCostObjects;
		UseSelectionCalculationObjects = Not DisableSelectionByCostObjects
			And FilterStructure1.CostObjects.Count() > 0;
		UseSelectionOfManufacturedProductsOrSemiFinishedProducts = ValueIsFilled(FilterStructure1.Product);
		UseSelectionCharacteristic = ValueIsFilled(FilterStructure1.Characteristic);
		
		// Selection by destination is not enabled by default, but we fill in the selection field
		Purpose = FilterStructure1.Purpose;
		
		// Setting selections
		Organization = FilterStructure1.Organization;
		CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,
			DataCompositionComparisonType.Equal,, ValueIsFilled(Organization) And UseCompanySelection);
		
		ProductionDispatcherBusinessUnit = FilterStructure1.ProductionDispatcherBusinessUnit;
		CommonClientServer.SetDynamicListFilterItem(List, "ProductionDispatcherBusinessUnit",
			ProductionDispatcherBusinessUnit, DataCompositionComparisonType.Equal,,
			ValueIsFilled(ProductionDispatcherBusinessUnit) And UseSelectionDivisionDispatcher);
		
		MaximumDateOfPlannedCalculations = FilterStructure1.Date;
		CommonClientServer.SetDynamicListFilterItem(List,
			"Date", EndOfDay(MaximumDateOfPlannedCalculations),
			DataCompositionComparisonType.LessOrEqual,,
			ValueIsFilled(MaximumDateOfPlannedCalculations) And UseSelectionMaximumDateOfPlannedCalculations);
		
		CostObjects.LoadValues(FilterStructure1.CostObjects);
		CommonClientServer.SetDynamicListFilterItem(List,
			"CostObjects.Object", CostObjects, DataCompositionComparisonType.InList,,
			ValueIsFilled(CostObjects) And UseSelectionCalculationObjects);
			
		// Setting the parameters
		ManufacturedProductsOrSemiFinishedProducts = FilterStructure1.Product;
		CommonClientServer.SetDynamicListFilterItem(List,
			"ProductSelection_4_", True, DataCompositionComparisonType.Equal,,
			ValueIsFilled(ManufacturedProductsOrSemiFinishedProducts) And UseSelectionOfManufacturedProductsOrSemiFinishedProducts);
			
		CommonClientServer.SetDynamicListParameter(List,
			"Product", ManufacturedProductsOrSemiFinishedProducts,
			ValueIsFilled(ManufacturedProductsOrSemiFinishedProducts) And UseSelectionOfManufacturedProductsOrSemiFinishedProducts);
			
		Characteristic = FilterStructure1.Characteristic;
		CommonClientServer.SetDynamicListFilterItem(List,
			"FeatureSelection", True, DataCompositionComparisonType.Equal,,
			ValueIsFilled(Characteristic) And UseSelectionCharacteristic);
			
		CommonClientServer.SetDynamicListParameter(List,
			"Characteristic", Characteristic,
			ValueIsFilled(Characteristic) And UseSelectionCharacteristic);
			
		CalculatedOnly = True;
		CommonClientServer.SetDynamicListFilterItem(List,
			"Posted", CalculatedOnly,
			DataCompositionComparisonType.Equal,
			CalculatedOnly);
		CommonClientServer.SetDynamicListFilterItem(List,
			"CalculatedSelection", CalculatedOnly,
			DataCompositionComparisonType.Equal,,
			CalculatedOnly);
	EndIf;
	
	#EndRegion
	
	#Region UniversalMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ToDoListOverridable.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Var FiltersStructure;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("ProductionDispatcherBusinessUnit") Then
			Settings.Insert("ProductionDispatcherBusinessUnit", FiltersStructure.ProductionDispatcherBusinessUnit)
		EndIf;
		
		If FiltersStructure.Property("Organization") Then
			Settings.Insert("Organization", FiltersStructure.Organization)
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DivisionManagerSelectionOnChange(Item)	
	If Item.Name = "DepartmentFilter" And ValueIsFilled(ProductionDispatcherBusinessUnit) Then
		UseSelectionDivisionDispatcher = True;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "ProductionDispatcherBusinessUnit",
		ProductionDispatcherBusinessUnit, DataCompositionComparisonType.Equal,,
		ValueIsFilled(ProductionDispatcherBusinessUnit) And UseSelectionDivisionDispatcher);
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	If Item.Name = "CompanyFilter" And ValueIsFilled(Organization) Then
		UseCompanySelection = True;
	EndIf;
		
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,
		DataCompositionComparisonType.Equal,, ValueIsFilled(Organization) And UseCompanySelection);
EndProcedure

&AtClient
Procedure CostObjectsOnChange(Item)
	If Item.Name = "CostObjects" And CostObjects.Count() > 0 Then
		UseSelectionCalculationObjects = True;
	EndIf;
		
	CommonClientServer.SetDynamicListFilterItem(List,
		"CostObjects.Object", CostObjects, DataCompositionComparisonType.InList,,
		ValueIsFilled(CostObjects) And UseSelectionCalculationObjects);
EndProcedure

&AtClient
Procedure ManufacturedProductsOrSemiFinishedProductsOnChange(Item)
	If Item.Name = "ManufacturedProductsOrSemiFinishedProducts" And ValueIsFilled(ManufacturedProductsOrSemiFinishedProducts) Then
		UseSelectionOfManufacturedProductsOrSemiFinishedProducts = True;
	EndIf;
		
	CommonClientServer.SetDynamicListFilterItem(List,
		"ProductSelection_4_", True, DataCompositionComparisonType.Equal,,
		ValueIsFilled(ManufacturedProductsOrSemiFinishedProducts) And UseSelectionOfManufacturedProductsOrSemiFinishedProducts);
		
	CommonClientServer.SetDynamicListParameter(List,
		"Product", ManufacturedProductsOrSemiFinishedProducts,
		ValueIsFilled(ManufacturedProductsOrSemiFinishedProducts) And UseSelectionOfManufacturedProductsOrSemiFinishedProducts);
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	If Item.Name = "Characteristic" And ValueIsFilled(Characteristic) Then
		UseSelectionCharacteristic = True;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"FeatureSelection", True, DataCompositionComparisonType.Equal,,
		ValueIsFilled(Characteristic) And UseSelectionCharacteristic);
		
	CommonClientServer.SetDynamicListParameter(List,
		"Characteristic", Characteristic,
		ValueIsFilled(Characteristic) And UseSelectionCharacteristic);
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	If Item.Name = "Purpose" And ValueIsFilled(Purpose) Then
		UseSelectionAssignment = True;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"CostObjects.Purpose", Purpose, DataCompositionComparisonType.Equal,,
		ValueIsFilled(Purpose) And UseSelectionAssignment);
EndProcedure

&AtClient
Procedure MaximumDateOfPlannedCalculationsOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If Item.Name = "MaximumDateOfPlannedCalculations" And ValueIsFilled(MaximumDateOfPlannedCalculations) Then
		UseSelectionMaximumDateOfPlannedCalculations = True;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Date", EndOfDay(MaximumDateOfPlannedCalculations),
		DataCompositionComparisonType.LessOrEqual,,
		ValueIsFilled(MaximumDateOfPlannedCalculations) And UseSelectionMaximumDateOfPlannedCalculations);
EndProcedure

&AtClient
Procedure CalculatedOnlyOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List,
		"Posted",
		CalculatedOnly,
		DataCompositionComparisonType.Equal,
		Undefined,
		CalculatedOnly);
	CommonClientServer.SetDynamicListFilterItem(List,
		"CalculatedSelection",
		CalculatedOnly,
		DataCompositionComparisonType.Equal,
		Undefined,
		CalculatedOnly);
EndProcedure

#EndRegion

#Region ListEventHandlers

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Universal_

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

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");

EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_MaximumDateOfPlannedCalculations" Then
		MaximumDateOfPlannedCalculationsOnChange(Items.MaximumDateOfPlannedCalculations);
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
