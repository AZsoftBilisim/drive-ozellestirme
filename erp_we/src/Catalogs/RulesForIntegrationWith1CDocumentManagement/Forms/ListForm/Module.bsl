#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AbbreviatedNameOfConfiguration = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.ObjectPresentationIS.Title
			= StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong %1';
					|ru = 'В %1';
					|en = 'In %1'; fa = 'In %1';
					|it = 'In %1';
					|pl = 'W %1';
					|tr = '%1''de'"), AbbreviatedNameOfConfiguration);
	EndIf;
			
	If ValueIsFilled(Parameters.ObjectTypeIS) Then
		ObjectTypeIS = Parameters.ObjectTypeIS;
		CommonClientServer.SetDynamicListFilterItem(List,
			"ObjectTypeIS",
			ObjectTypeIS,
			DataCompositionComparisonType.Equal);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.ShowDeletedItems.Check = ShowDeleted;
	CommonClientServer.SetDynamicListFilterItem(List,
		"DeletionMark",
		False,
		DataCompositionComparisonType.Equal,,
		Not ShowDeleted,
		DataCompositionSettingsItemViewMode.Inaccessible);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	FormParameters = New Structure;
	If ValueIsFilled(ObjectTypeIS) Then
		FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	EndIf;
	If Copy Then
		FormParameters.Insert("CopyingValue", Items.List.CurrentRow);
	EndIf;
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ItemForm",
		FormParameters,
		Items.List);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowDeletedItems(Command)
	
	ShowDeleted = Not ShowDeleted;
	Items.ShowDeletedItems.Check = ShowDeleted;
	CommonClientServer.SetDynamicListFilterItem(List,
		"DeletionMark",
		False,
		DataCompositionComparisonType.Equal,,
		Not ShowDeleted,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

#EndRegion