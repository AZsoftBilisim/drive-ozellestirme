
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Cache = Undefined;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillType = False;
	If Parameters.Property("FillType") Then
		FillType = Parameters.FillType;
	EndIf;
	
	ItemsTree = GetFromTempStorage(Parameters.AddressOfReportItems);
	TreeRow = FinancialReportingServer.SubordinateItem(ItemsTree,
		"AddressOfItemStructure", Parameters.ItemAddressInStorage);
	ListOfAvailableItems = BudgetReportingCacheCalculationServer.SourcesOfElementValues(Cache, TreeRow, FillType);
	
	TableOfPreviousSources = TableOfPreviousSources(Parameters.ValueSources);
	SourceTree_ = FormAttributeToValue("ValueSources");
	
	NewRow = Undefined;
	For Each RowOfAvailableItems In ListOfAvailableItems Do
		Item = RowOfAvailableItems.Item;
		If ValueIsFilled(RowOfAvailableItems.Parent) Then
			PlaceAdded = SourceTree_.Rows.Find(RowOfAvailableItems.Parent, "Source", True);
		Else
			PlaceAdded = SourceTree_;
		EndIf;
		NewRow = PlaceAdded.Rows.Add();
		NewRow.Source = Item;
		If TypeOf(Item) = Type("String") Then
			ObjectAttributes = GetFromTempStorage(Item);
		Else
			ObjectAttributes = New Structure("Ref", Item);
		EndIf;
		NewRow.ItemKind = RowOfAvailableItems.ItemKind;
		NewRow.Presentation = RowOfAvailableItems.Description;
		NewRow.CustomPicture = FinancialReportingCached.CustomPicture(NewRow.ItemKind);
		For Each ElementString In TableOfPreviousSources Do
			If ElementString["Source"] = ObjectAttributes.Ref Or ElementString["Source"] = Item Then
				NewRow.Use = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	FillInFlagsOnSlaveElementsOnServer(FinancialReportingServer.SubordinateRows(SourceTree_));
	
	ValueToFormAttribute(SourceTree_, "ValueSources");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(ValueSources);
	For Each SubordinateRow In SubordinateRows Do
		Items.ValueSources.Expand(SubordinateRow.GetID(), True);
	EndDo;
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure ValueSourcesUseOnChange(Item)
	
	CurrentData = Items.ValueSources.CurrentData;
	If CurrentData.Use = 2 Then
		CurrentData.Use = 0;
	EndIf;
	
	FillInFlagsOfSubordinateRows(FinancialReportingClient.SubordinateLinesOfFormElement(CurrentData),
		CurrentData.Use);
	
	Parent = FinancialReportingClientServer.RowParent(CurrentData);
	While Parent <> Undefined Do
		SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(Parent);
		Parent.Use = FillInFlagsOnSubordinateElements(SubordinateRows, False);
		Parent = FinancialReportingClientServer.RowParent(Parent);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(GetChoiceResult());
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	FillInFlagsOfSubordinateRows(FinancialReportingClient.SubordinateLinesOfFormElement(ValueSources), 1);
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	FillInFlagsOfSubordinateRows(FinancialReportingClient.SubordinateLinesOfFormElement(ValueSources), 0);
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)

	SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(ValueSources);
	For Each SubordinateRow In SubordinateRows Do
		Items.ValueSources.Expand(SubordinateRow.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)

	SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(ValueSources);
	CollapseLine(SubordinateRows);
	
EndProcedure

#EndRegion

#Region Private


// Returns the source table with the selection.
// 
// Parameters:
// 	TableOfSources - ValueTable -:
// 	 *Source - CatalogRef.FinancialReportItems -
// 	 *AddedDocumentValues - Boolean -
// Returns:
// 	ValueTable -:
// 	 *Source - CatalogRef.FinancialReportItems -
// 	 *AddedDocumentValues - Boolean -
&AtServer
Function TableOfPreviousSources(TableOfSources)
	Return TableOfSources.Unload(New Structure("AddedDocumentValues", False));
EndFunction

&AtClient
Procedure FillInFlagsOfSubordinateRows(Rows, Flag)
	
	For Each String In Rows Do
		String.Use = Flag;
		SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(String);
		FillInFlagsOfSubordinateRows(SubordinateRows, Flag);
	EndDo;
	
EndProcedure

&AtServer
Function GetChoiceResult()
	
	Result = New Array;
	FoundRows = FormAttributeToValue("ValueSources").Rows.FindRows(New Structure("Use", 1), True);
	ArrayOfAvailableViews = New Array;
	ArrayOfAvailableViews.Add(Enums.FinancialReportItemKinds.BudgetFlowItem);
	ArrayOfAvailableViews.Add(Enums.FinancialReportItemKinds.BudgetBalanceItem);
	ArrayOfAvailableViews.Add(Enums.FinancialReportItemKinds.NonFinancialItem);
	
	For Each FoundRow In FoundRows Do
		If FoundRow.Rows.Count() Then
			// The sources are located at the "lower" level of the tree
			Continue;
		EndIf;
		If ArrayOfAvailableViews.Find(FoundRow.ItemKind) = Undefined Then
			Continue;
		EndIf;
		Result.Add(FoundRow.Source);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function FillInFlagsOnSubordinateElements(TreeRows, IncludingSubordinates = True)
	
	ArrayOfCurLevelFlags = New Array;
	For Each String In TreeRows Do
		
		If IncludingSubordinates Then
			SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(String);
		EndIf;
		If IncludingSubordinates And SubordinateRows.Count() Then
			String.Use = FillInFlagsOnSubordinateElements(SubordinateRows);
		EndIf;
		ArrayOfCurLevelFlags.Add(String.Use);
		
	EndDo;
	
	Result = CommonClientServer.CollapseArray(ArrayOfCurLevelFlags);
	If Result.Count() = 2 Then
		Return 2;
	ElsIf Result.Count() Then
		Return Result[0];
	EndIf;
	
EndFunction

&AtServer
Function FillInFlagsOnSlaveElementsOnServer(TreeRows, IncludingSubordinates = True)
	
	ArrayOfCurLevelFlags = New Array;
	For Each String In TreeRows Do
		
		If IncludingSubordinates Then
			SubordinateRows = FinancialReportingServer.SubordinateRows(String);
		EndIf;
		If IncludingSubordinates And SubordinateRows.Count() Then
			String.Use = FillInFlagsOnSlaveElementsOnServer(SubordinateRows);
		EndIf;
		ArrayOfCurLevelFlags.Add(String.Use);
		
	EndDo;
	
	Result = CommonClientServer.CollapseArray(ArrayOfCurLevelFlags);
	If Result.Count() = 2 Then
		Return 2;
	ElsIf Result.Count() Then
		Return Result[0];
	EndIf;
	
EndFunction

&AtClient
Procedure CollapseLine(TreeRows)
	
	For Each String In TreeRows Do
		SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(String);
		CollapseLine(SubordinateRows);
		Items.ValueSources.Collapse(String.GetID());
	EndDo;
	
EndProcedure

#EndRegion
