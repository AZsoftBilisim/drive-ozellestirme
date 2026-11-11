
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("StructureSelectionParameters_") Then
		
		If Parameters.StructureSelectionParameters_.Property("Status") Then
			
			NewElementOfSelection = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			NewElementOfSelection.LeftValue = New DataCompositionField("Status");
			NewElementOfSelection.ComparisonType = DataCompositionComparisonType.Equal;
			NewElementOfSelection.RightValue = Parameters.StructureSelectionParameters_.Status;
			NewElementOfSelection.Use = True;
			
		EndIf;
		
		If Parameters.StructureSelectionParameters_.Property("FiscalDevice") Then
			
			NewElementOfSelection = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			NewElementOfSelection.LeftValue = New DataCompositionField("FiscalDevice");
			NewElementOfSelection.ComparisonType = DataCompositionComparisonType.Equal;
			NewElementOfSelection.RightValue = Parameters.StructureSelectionParameters_.FiscalDevice;
			NewElementOfSelection.Use = True;
			
		EndIf;
		
	EndIf;
	
	If Parameters.Property("ResultStructure1") Then
		ResultStructure1 = Parameters.ResultStructure1;
	Else
		ResultStructure1 = Undefined;
	EndIf;
	
	If Parameters.Property("Title") Then
		If ValueIsFilled(Parameters.Title) Then
			AutoTitle = False;
			Title = Parameters.Title;
		EndIf;
	EndIf;
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	
	ProcessSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessSelection()
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If ResultStructure1 = Undefined Then
		
		NotifyChoice(Items.List.CurrentData.Ref);
		
	Else
		
		ReturnStructure = New Structure();
		
		For Each KeyAndValue In ResultStructure1 Do
			ReturnStructure.Insert(KeyAndValue.Key, Items.List.CurrentData[KeyAndValue.Value]);
		EndDo;
		
		Close(ReturnStructure);
		
	EndIf;
	
EndProcedure

#EndRegion
