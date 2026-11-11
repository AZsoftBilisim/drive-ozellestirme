
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetFilter();
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure ByPerformerOnChange(Item)
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure ShowTasksOnChange(Item)
	
	SetFilter();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFilter()
	
	FilterParameters = New Map();
	FilterParameters.Insert("ByPerformer", ByPerformer);
	FilterParameters.Insert("ShowTasks", ShowTasks);
	SetListFilter(List, FilterParameters);
	
EndProcedure	

&AtServerNoContext
Procedure SetListFilter(List, FilterParameters)
	
	CommonClientServer.DeleteFilterItems(List.Filter, "Performer");
	If Not FilterParameters["ByPerformer"].IsEmpty() Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Performer", FilterParameters["ByPerformer"]);
	EndIf;
		
	CommonClientServer.DeleteFilterItems(List.Filter, "Executed");
	If FilterParameters["ShowTasks"] <> 0 Then 
		
		If FilterParameters["ShowTasks"] = 1 Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Executed", True);
		EndIf;
		
		If FilterParameters["ShowTasks"] = 2 Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Executed", False);
		EndIf;	
	
	EndIf;
	
EndProcedure

#EndRegion
