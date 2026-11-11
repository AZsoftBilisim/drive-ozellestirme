
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ValueToFormData(GetFromTempStorage(Parameters.EventKinds),EventKinds);
	ComposerOfFilterByUsers = Parameters.CompositionSetup;
	CallingFormUID               = Parameters.UID_OfCallingForm;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEventKinds
&AtClient
Procedure EventKindsCheckOnChange(Item)
	
	CurrentRow = EventKinds.FindByID(Items.EventKinds.CurrentRow);
	If CurrentRow.Check = 2 Then
		CurrentRow.Check = 0;
	EndIf;
	
	Parent = CurrentRow.GetParent();
	If Parent = Undefined Then
		
		For Each SubordinateItem In CurrentRow.GetItems() Do
			
			If CurrentRow.Check <> SubordinateItem.Check Then
				SubordinateItem.Check = CurrentRow.Check;
			EndIf;
			
		EndDo;
		
	Else
		
		ValueOfPreviousElement = 2;
		
		For Each SubordinateItem In Parent.GetItems() Do
			
			If ValueOfPreviousElement <> 2 And (SubordinateItem.Check <> ValueOfPreviousElement) Then
				Parent.Check = 2;
				Return;
			ElsIf Parent.Check <> SubordinateItem.Check Then
				Parent.Check = SubordinateItem.Check;
			EndIf;
			
			ValueOfPreviousElement =  SubordinateItem.Check;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EventTypesIncludeAll(Command)
	
	SetIncludeFlagValue(True,EventKinds);
	
EndProcedure

&AtClient
Procedure EventTypesExcludeAll(Command)
	
	SetIncludeFlagValue(False,EventKinds);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	Close(StructureOfSelectionParameters());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetIncludeFlagValue(CheckValue,Parent)
	
	For Each Item In Parent.GetItems() Do
	
		Item.Check = CheckValue;
		SetIncludeFlagValue(CheckValue,Item);
	
	EndDo;
	
EndProcedure

&AtServer
Function StructureOfSelectionParameters()

	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("SettingsComposer",ComposerOfFilterByUsers);
	ChoiceParameters.Insert("EventKinds",TemporaryStorageOfSettingsOnServer());
	Return ChoiceParameters;

EndFunction

&AtServer
Function TemporaryStorageOfSettingsOnServer()
	
	Return PutToTempStorage(FormAttributeToValue("EventKinds"),CallingFormUID);
	
EndFunction

#EndRegion
