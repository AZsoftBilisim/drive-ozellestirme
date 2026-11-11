#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	OnlyNotCompleted = True;
	SetFilter();
	
	CommonClientServer.DeleteFilterItems(List.Filter, "Performer");
		CommonClientServer.SetDynamicListFilterItem(
			List, "Performer", Users.AuthorizedUser());
	
	NewTitle = "";
	AdditionalParameters = Parameters.AdditionalParameters; // Structure
	If TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("Title", NewTitle) Then
		AutoTitle = False;
		Title = NewTitle;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure OnlyNotCompletedOnChange(Item)
	
	SetFilter();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFilter()
	
	CommonClientServer.DeleteFilterItems(List.Filter, "Executed");
	
	If OnlyNotCompleted Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Executed", False);
	EndIf;
	
EndProcedure

#EndRegion
