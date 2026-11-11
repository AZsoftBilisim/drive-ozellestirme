#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ListOfProperties = "CrossTable,Periodicity,NameOfPeriodDateField,NumberOfPeriods,Preview";
	FillPropertyValues(ThisForm, Parameters, ListOfProperties);
	
	Items.CrossTableParametersGroup.Enabled = CrossTable;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)

	Result = New Structure();
	
	Result.Insert("CrossTable", CrossTable);
	Result.Insert("Periodicity", Periodicity);
	Result.Insert("NameOfPeriodDateField", NameOfPeriodDateField);
	Result.Insert("NumberOfPeriods", NumberOfPeriods);
	Result.Insert("Preview", Preview);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure UseCrossTableWhenChanging(Item)
	
	Items.CrossTableParametersGroup.Enabled = CrossTable;
	
EndProcedure

#EndRegion