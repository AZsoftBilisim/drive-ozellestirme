
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("ProductKind", ProductKind);
	Parameters.Property("LongDesc", LongDesc);
	
	FillInListOfSelectionsByProperties();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseOnClient", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectionByProperties

&AtClient
Procedure SelectionByPropertiesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionByPropertiesBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionByPropertiesBeforeRowChange(
		ThisForm,
		CurrentData,
		TableOfAvailableProperties,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure SelectionOfPropertiesPropertyIsWhenYouChange(Item)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionOfPropertiesPropertyIsWhenYouChange(
		ThisForm,
		CurrentData,
		TableOfAvailableProperties,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure TheSelectionOfThePropertiesSubjectToChange(Item)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.TheSelectionOfThePropertiesSubjectToChange(
		ThisForm,
		CurrentData,
		TableOfAvailableProperties,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure SelectionOfPropertiesTheConditionOfTheBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SelectionByProperties.CurrentData;

	ProductDataManagementClient.SelectionOfPropertiesTheConditionOfTheBeginningOfTheSelection(
		ThisForm,
		CurrentData,
		TableOfAvailableProperties,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure SelectionByPropertiesConditionCleaning(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SelectionByPropertiesValueIntervalWhenChanging(Item)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionByPropertiesValueIntervalWhenChanging(
		CurrentData,
		Item.Name);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveSetting(Command)
	
	WriteAndCloseOnClient(Undefined, Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductDataManagement.SetConditionalAppearanceOfSelectionTableByProperties(ConditionalAppearance);
	
EndProcedure

&AtServer
Procedure FillInListOfSelectionsByProperties()
	
	ConditionsStructure = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
	
	// Properties of the main product
	ListOfAllAvailableProperties = ProductDataManagement.GetPropertiesToSelectByProperties(ProductKind, Parameters.SettingKind);
		
	For Each DataProperty In ListOfAllAvailableProperties Do
		FillPropertyValues(TableOfAvailableProperties.Add(), DataProperty);
		Items.Property.ChoiceList.Add(DataProperty.Property, DataProperty.Presentation);
	EndDo;
	
	ProductDataManagement.FillInListOfSelectionsByProperties(SelectionByProperties, Parameters.SelectionByProperties);
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WriteAndCloseOnClient(Result, AdditionalParameters) Export 
	
	ClearMessages();
	
	HasErrors = False;
	SelectionByPropertiesResult = Undefined;
	
	SelectionByPropertiesResult = ProductDataManagementClient.SelectionByPropertiesPerformControlGenerateResultOfSetting(
		SelectionByProperties,
		TableOfAvailableProperties,
		HasErrors);
		
	If HasErrors Then
		Return;
	EndIf;
	
	Modified = False;
	
	Close(New Structure("SelectionByProperties,LongDesc",SelectionByPropertiesResult,LongDesc));
	
EndProcedure

#EndRegion