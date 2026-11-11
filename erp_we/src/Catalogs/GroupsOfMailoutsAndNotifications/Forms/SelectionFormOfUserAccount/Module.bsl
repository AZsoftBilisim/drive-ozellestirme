
#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelection();
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessSelection();
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Close();
	Else
		
		ReturnStructure = New Structure;
		ReturnStructure.Insert("Account", CurrentData.Account);
		ReturnStructure.Insert("DeleteAfterSend", CurrentData.DeleteAfterSend);
		NotifyChoice(ReturnStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

