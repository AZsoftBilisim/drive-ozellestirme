
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	IndicatorTreeAddressInTemporaryStorage = Parameters.SettingsTree;
	
	GenerateSettingsTree(GetFromTempStorage(IndicatorTreeAddressInTemporaryStorage));
	DisplayCharts                = Parameters.DisplayCharts;
	DisplayLegend                  = Parameters.DisplayLegend;
	DisplayTables                  = Parameters.DisplayTables;
	InterestRate                 = Parameters.InterestRate;
	ComposerOfFilterByUsers = Parameters.CompositionSetup;
	CallingFormUID = Parameters.UID_OfCallingForm;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsTree

&AtClient
Procedure SettingsTreeIncludeOnChange(Item)
	
	CurrentRow = SettingsTree.FindByID(Items.SettingsTree.CurrentRow);
	If CurrentRow.Include = 2 Then
		CurrentRow.Include = 0;
	EndIf;
	
	Parent = CurrentRow.GetParent();
	If Parent = Undefined Then
		
		For Each SubordinateItem In CurrentRow.GetItems() Do
			
			If CurrentRow.Include <> SubordinateItem.Include Then
				SubordinateItem.Include = CurrentRow.Include;
			EndIf;
			
		EndDo;
		
	Else
		
		ValueOfPreviousElement = 2;
		
		For Each SubordinateItem In Parent.GetItems() Do
			
			If ValueOfPreviousElement <> 2 And (SubordinateItem.Include <> ValueOfPreviousElement) Then
				Parent.Include = 2;
				Return;
			ElsIf Parent.Include <> SubordinateItem.Include Then
				Parent.Include = SubordinateItem.Include;
			EndIf;
			
			ValueOfPreviousElement =  SubordinateItem.Include;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(StructureOfSelectionParameters());
	
EndProcedure

&AtClient
Procedure DatasetsSelectAll(Command)
	
	SetIncludeFlagValue(True,SettingsTree);
	
EndProcedure

&AtClient
Procedure DataSetsExcludeAll(Command)
	
	SetIncludeFlagValue(False,SettingsTree);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateSettingsTree(TreeOfValues)
	
	For Each TreeRow In TreeOfValues.Rows Do
		
		If TreeRow.AvailabilityAccordingToFS Then
			AddedRow = NewRowOfMetricsTree(SettingsTree,TreeRow);
			For Each SubordinateRow In TreeRow.Rows Do
				If SubordinateRow.AvailabilityAccordingToFS Then
					 NewRowOfMetricsTree(AddedRow,SubordinateRow);
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function NewRowOfMetricsTree (Parent,IndicatorTreeRow)

	NewRow = Parent.GetItems().Add();
		FillPropertyValues(NewRow,IndicatorTreeRow);
	Return NewRow;

EndFunction

&AtClient
Procedure SetIncludeFlagValue(CheckValue,Parent)
	
	For Each Item In Parent.GetItems() Do
	
		Item.Include = CheckValue;
		SetIncludeFlagValue(CheckValue,Item);
	
	EndDo;
	
EndProcedure

&AtServer
Function IndicatorTree()
	
	TreeOfValues = GetFromTempStorage(IndicatorTreeAddressInTemporaryStorage);
	
	For Each GroupTreeString In SettingsTree.GetItems() Do
		
		FoundRow = TreeOfValues.Rows.Find(GroupTreeString.Name,"Name",True);
		If FoundRow <> Undefined Then
			FoundRow.Include = GroupTreeString.Include;
		EndIf;
		
		For Each TreeLineIndicator In GroupTreeString.GetItems() Do
			
			FoundRow = TreeOfValues.Rows.Find(TreeLineIndicator.Name,"Name",True);
			If FoundRow <> Undefined Then
				FoundRow.Include = TreeLineIndicator.Include;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return PutToTempStorage(TreeOfValues,CallingFormUID);
	
EndFunction

&AtServer
Function StructureOfSelectionParameters()

	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("DisplayCharts",DisplayCharts);
	ChoiceParameters.Insert("DisplayTables",DisplayTables);
	ChoiceParameters.Insert("DisplayLegend",DisplayLegend);
	ChoiceParameters.Insert("InterestRate",InterestRate);
	ChoiceParameters.Insert("Indicators",IndicatorTree());
	ChoiceParameters.Insert("CompositionSettings",ComposerOfFilterByUsers);
	
	Return ChoiceParameters;

EndFunction

#EndRegion
