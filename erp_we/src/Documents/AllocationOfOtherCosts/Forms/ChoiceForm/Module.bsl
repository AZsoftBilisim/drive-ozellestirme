#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If Parameters.Property("Filter") Then
		AssignRule = Undefined;
		If Parameters.Filter.Property("AssignRule", AssignRule) Then
			If ValueIsFilled(AssignRule) Then
				CommonClientServer.SetDynamicListFilterItem(
					List,
					"AssignAllocationSetting",
					AssignRule,
					DataCompositionComparisonType.Equal,,
					True);
			EndIf;
			Parameters.Filter.Delete("AssignRule");
		EndIf;
	EndIf;
	
	SetConditionalAppearanceOfExpenditureItemField();


	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearanceOfExpenditureItemField()
	
	ConditionalAppearanceOfList = List.ConditionalAppearance;
	
	AppearanceItem = ConditionalAppearanceOfList.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '< tất cả trong khuôn khổ SXDD >';
															|ru = '< все в рамках ОВЗ >';
															|en = '< all within cost centers >'; fa = '< all within cost centers >';
															|it = '< все в рамках ОВЗ >';
															|pl = '< all within cost centers >';
															|tr = '< tümü Gider Oluşum Nesneleri çerçevesinde >'"));
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("ExpenseItem");
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = FormattedField.Field;
	FilterElement.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
EndProcedure


#EndRegion

