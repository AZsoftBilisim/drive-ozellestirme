
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DescriptionOfImplementationDocumentTypes = Metadata.Documents.SaleAdjustment.TabularSections.ARAPAdjustment.Attributes.DocumentSalesOfGoodsAndServices.Type;
	MatchingMetadataObjectIdentifiers = Common.MetadataObjectIDs(DescriptionOfImplementationDocumentTypes.Types());
	
	ListOfMetadataObjectIDs = New ValueList();
	For Each KeyAndValue In MatchingMetadataObjectIdentifiers Do
		ListOfMetadataObjectIDs.Add(KeyAndValue.Value);
	EndDo;
	
	CloseOnChoice = False;
	
	SelectedDocuments.LoadValues(Parameters.SelectedDocuments);
	
	CommonClientServer.SetDynamicListParameter(
		List, "MetadataObjectIDs", ListOfMetadataObjectIDs);
	CommonClientServer.SetDynamicListParameter(
		List, "SelectedDocuments", SelectedDocuments);
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Parameters.Organization);
	CommonClientServer.SetDynamicListFilterItem(
		List, "Partner", Parameters.Partner);
	CommonClientServer.SetDynamicListFilterItem(
		List, "Counterparty", Parameters.Counterparty);
	CommonClientServer.SetDynamicListFilterItem(
		List, "Currency", Parameters.Currency);
	CommonClientServer.SetDynamicListParameter(
		List, "ARAPCurrency", Parameters.ARAPCurrency);
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.List.CurrentData;
	NotifyChoice(CurrentRow.Ref);
	
	SelectedDocuments.Add(CurrentRow.Ref);
	CommonClientServer.SetDynamicListParameter(
		List, "SelectedDocuments", SelectedDocuments);
		
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	Cancel = True;
	CurrentRow = Items.List.CurrentData;
	ShowValue(, CurrentRow.Ref);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If Items.List.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfSelected = New Array;
	For Each CurrentRow In Items.List.SelectedRows Do
		ArrayOfSelected.Add(Items.List.RowData(CurrentRow).Ref);
	EndDo;
	
	If ArrayOfSelected.Count() > 0 Then
		NotifyChoice(ArrayOfSelected);
		CommonClientServer.SupplementArray(SelectedDocuments, ArrayOfSelected);
		CommonClientServer.SetDynamicListParameter(
			List, "SelectedDocuments", SelectedDocuments);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenDocument(Command)
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow <> Undefined Then
		ShowValue(Undefined, CurrentRow.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "ListDate");
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
EndProcedure

#EndRegion