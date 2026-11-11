
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region ListFormTableEventHandlers

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	ListBeforeDeletingOnServer();
EndProcedure

&AtServer
Procedure ListBeforeDeletingOnServer()
	
	ListOfIndividuals.Clear();
	
	For Each CurrRow In Items.List.SelectedRows Do
		If ListOfIndividuals.FindByValue(CurrRow.Individual) = Undefined Then
			ListOfIndividuals.Add(CurrRow.Individual);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	NotificationParameter1 = New Structure("RegisterName", "FullNameOfPersons");
	
	For Each CurrRow In ListOfIndividuals Do
		Notify("PersonalDataChanged", NotificationParameter1, CurrRow.Value);
	EndDo;
	
EndProcedure

#EndRegion
