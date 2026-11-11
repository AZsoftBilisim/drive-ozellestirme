
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var FilterStorageArea;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	RestoreSettings(Parameters);
	
	If ValueIsFilled(FilterStorageArea) Then
		
		FilterWarehouse = FilterStorageArea.Owner;
		FilterPremise = FilterStorageArea.Premise;
		
	ElsIf ValueIsFilled(FilterPremise) Then
		
		FilterWarehouse = Common.ObjectAttributeValue(FilterPremise, "Owner");
		
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", FilterWarehouse));
	SetSelectionsInList();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterWarehouseOnChange(Item)
	FilterWarehouseOnChangeServer();
EndProcedure

&AtClient
Procedure FilterPremiseOnChange(Item)
	SetSelectionsInList();
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetSelectionsInList()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Warehouse", FilterWarehouse, DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(List, "Premise", FilterPremise, DataCompositionComparisonType.Equal,,True);
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure FilterWarehouseOnChangeServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", FilterWarehouse));
	SetSelectionsInList();
	
EndProcedure

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	If Var_Parameters.Filter.Count() > 0 Then
		Var_Parameters.Filter.Property("Warehouse",			FilterWarehouse);
		Var_Parameters.Filter.Property("Premise",		FilterPremise);
		Var_Parameters.Filter.Property("StorageArea",	FilterStorageArea);
	Else
		SettingsKey = "FormSelections";
		ObjectKey  = "InformationRegister.RulesForPlacingProductsInCell.Form.ListForm";
		Settings    = Common.CommonSettingsStorageLoad(ObjectKey, SettingsKey);
		
		If TypeOf(Settings) = Type("Structure") Then
			FillPropertyValues(ThisObject, Settings);
			TMCommonUse.ClearFormSettingsOrDetailsFromNonexistentLinks(Settings, ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	SettingsKey = "FormSelections";
	ObjectKey  = "InformationRegister.RulesForPlacingProductsInCell.Form.ListForm";
	
	Settings = New Structure("FilterWarehouse, FilterPremise, FilterStorageArea");
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings);
	
EndProcedure

#EndRegion

#EndRegion
