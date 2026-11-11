
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Items.State.Visible = GetFunctionalOption("UseApprovalOfItemPrices");
	
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EmployeeResponsible",
		EmployeeResponsible,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(EmployeeResponsible));
		
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	
	If Parameters.Property("MarketingActivity") Then
		CommonClientServer.SetDynamicListFilterItem(List, "MarketingActivity",	Parameters.MarketingActivity, DataCompositionComparisonType.Equal, , True);
	EndIf;
	
	FieldsForRestriction = New Array();
	FieldsForRestriction.Add("TypesOfPrices");
	FieldsForRestriction.Add("PriceKind");
	
	List.SetRestrictionsForUseInGroup(FieldsForRestriction);
	List.SetRestrictionsForUseInFilter(FieldsForRestriction);
	List.SetRestrictionsForUseInOrder(FieldsForRestriction);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	PriceManagementSystemServerCall.SetPropertiesOfSceneryInformingAboutRemovalOfPricingVersion20(Items);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	State     = Settings.Get("State");
	EmployeeResponsible = Settings.Get("EmployeeResponsible");
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	CommonClientServer.SetDynamicListFilterItem(List, "Status", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,, ValueIsFilled(State));	
	SetSelectionByTypeOfPrices();
	
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, Undefined, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure FilterPriceKindOnChange(Item)
	
	SetSelectionByTypeOfPrices();
	
EndProcedure

&AtClient
Procedure FilterDueDate_2OnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterDueDate_2.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterDueDate_2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterDueDate_2",
		"EventDate");
	
EndProcedure

&AtClient
Procedure FilterCompletionDateCleaningUp(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


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

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.PriceSetup.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Keys = Rows.GetKeys();
	ListLine = Rows.Get(Keys[0]);
	If Not ListLine.Data.Property("TypesOfPrices") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	    "SELECT
	    |	PriceSetupTypesOfPrices.Ref,
	    |	PriceSetupTypesOfPrices.PriceKind.Presentation AS PriceKindPresentation
	    |FROM
	    |	Document.PriceSetup.TypesOfPrices AS PriceSetupTypesOfPrices
	    |WHERE
	    |	PriceSetupTypesOfPrices.Ref IN (&Documents)";
	Query.SetParameter("Documents", Keys);
	
	DocumentReference = Undefined;
	ListLine	= Undefined;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If DocumentReference = Selection.Ref Then
			
			ListLine.Data["TypesOfPrices"] = ListLine.Data["TypesOfPrices"] + ", " + Selection.PriceKindPresentation;
			
		Else
			
			DocumentReference = Selection.Ref;
			
			ListLine = Rows[Selection.Ref];
			ListLine.Data["TypesOfPrices"] = Selection.PriceKindPresentation;
			
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure DisableUnavailableSelections(Collection, FilterAvailableFields = Undefined)
	
	ItemsToRemove = New Array;
	
	For Each CurrentData In Collection Do
		
		If TypeOf(CurrentData) = Type("DataCompositionFilter") Then
			
			DisableUnavailableSelections(CurrentData.Items, CurrentData.FilterAvailableFields);
			
		ElsIf TypeOf(CurrentData) = Type("DataCompositionFilterItemGroup") Then
			
			DisableUnavailableSelections(CurrentData.Items, FilterAvailableFields);
			
		ElsIf TypeOf(CurrentData) = Type("DataCompositionFilterItem") Then
			
			If Not CurrentData.Use Then
				Continue;
			EndIf;
			
			For Each PropertyName In StrSplit("LeftValue,RightValue",",") Do
				
				CurrentField = CurrentData[PropertyName];
				If TypeOf(CurrentField) = Type("DataCompositionField") 
					And FilterAvailableFields.FindField(CurrentField) = Undefined Then
					
					ItemsToRemove.Add(CurrentData);
					Break;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	For Each ItemToRemove In ItemsToRemove Do
		Collection.Delete(ItemToRemove);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSelectionByTypeOfPrices()

	If ValueIsFilled(PriceKind) Then
		 
		FieldsForRestriction = New Array();
		FieldsForRestriction.Add("TypesOfPrices");
		List.SetRestrictionsForUseInFilter(FieldsForRestriction);
		
		CommonClientServer.SetDynamicListFilterItem(List, "PriceKind", PriceKind, DataCompositionComparisonType.Equal,, ValueIsFilled(PriceKind));
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(List, "PriceKind", PriceKind, DataCompositionComparisonType.Equal,, ValueIsFilled(PriceKind));

		FieldsForRestriction = New Array();
		FieldsForRestriction.Add("TypesOfPrices");
		FieldsForRestriction.Add("PriceKind");
		List.SetRestrictionsForUseInFilter(FieldsForRestriction);
		
		DisableUnavailableSelections(List.SettingsComposer.UserSettings.Items);
		
	EndIf;
	
EndProcedure

#EndRegion
