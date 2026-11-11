#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	CheckFillInLaborInput();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckFillInLaborInput()
	
	AutocompleteOptions = Catalogs.EmployeeWorkKinds.AutoCompletionParametersForLaborInput(ThisObject);
	If ValueIsFilled(AutocompleteOptions) Then
		FillPropertyValues(ThisObject, AutocompleteOptions);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf