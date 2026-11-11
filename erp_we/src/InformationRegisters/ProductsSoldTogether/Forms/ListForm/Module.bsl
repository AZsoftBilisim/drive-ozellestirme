
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.SearchForAssociations.Visible  = AccessRight("Update", Metadata.InformationRegisters.ProductsSoldTogether);
	Items.SettingOfAssociationSearch.Visible = AccessRight("Update", Metadata.InformationRegisters.ProductsSoldTogether);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	OptionToAddSelection = Settings.Get("OptionToAddSelection");
	AnalysisOptionSelection = Settings.Get("AnalysisOptionSelection");
	
	CommonClientServer.SetDynamicListFilterItem(List, "AnalysisOption", AnalysisOptionSelection, DataCompositionComparisonType.Equal,, ValueIsFilled(AnalysisOptionSelection));
	If OptionToAddSelection = "" Then
		CommonClientServer.SetDynamicListFilterItem(List, "AddedAutomatically", Undefined, DataCompositionComparisonType.Equal,, False);
	ElsIf OptionToAddSelection = "AddedAutomatically" Then
		CommonClientServer.SetDynamicListFilterItem(List, "AddedAutomatically", True, DataCompositionComparisonType.Equal,, True);
	ElsIf OptionToAddSelection = "AddedToManual" Then
		CommonClientServer.SetDynamicListFilterItem(List, "AddedAutomatically", False, DataCompositionComparisonType.Equal,, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Customize(Command)
	
	OpenForm("InformationRegister.ProductsSoldTogether.Form.SettingOfAssociationSearch", Undefined);
	
EndProcedure

&AtClient
Procedure SearchForAssociations(Command)
	
	UpdateDataOnProductsSoldJointly();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AddingOptionOnChange(Item)
	
	If OptionToAddSelection = "" Then
		CommonClientServer.SetDynamicListFilterItem(List, "AddedAutomatically", Undefined, DataCompositionComparisonType.Equal,, False);
	ElsIf OptionToAddSelection = "AddedAutomatically" Then
		CommonClientServer.SetDynamicListFilterItem(List, "AddedAutomatically", True, DataCompositionComparisonType.Equal,, True);
	ElsIf OptionToAddSelection = "AddedToManual" Then
		CommonClientServer.SetDynamicListFilterItem(List, "AddedAutomatically", False, DataCompositionComparisonType.Equal,, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AnalysisOptionSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "AnalysisOption", AnalysisOptionSelection, DataCompositionComparisonType.Equal,, ValueIsFilled(AnalysisOptionSelection));
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure UpdateDataOnProductsSoldJointly()
	
	ProductsSoldTogether.UpdateDataOnProductsSoldJointly();
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#EndRegion
