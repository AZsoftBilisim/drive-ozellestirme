	  
#Region FormEventHandlers
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ListOfIndividuals = Parameters.ListOfIndividuals;
	
	For Each CurrentValue In ListOfIndividuals Do
		
		NewRow = TableOfPersons.Add();
		
		NewRow.Individual = CurrentValue;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NoIsAnotherPerson(Command)

	Close(False);
	
EndProcedure

&AtClient
Procedure YesIsWhoINeed(Command)
	
	SelectSimilarPersonAndCloseForm();
	
EndProcedure

#EndRegion

#Region Private

 &AtClient
Procedure SelectSimilarPersonAndCloseForm()
	
	CurrentData = Items.TableOfPersons.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;	
	
	SelectionResult = New Structure("SimilarPerson", CurrentData.Individual);
	
	Close(SelectionResult);
	
EndProcedure

#EndRegion

