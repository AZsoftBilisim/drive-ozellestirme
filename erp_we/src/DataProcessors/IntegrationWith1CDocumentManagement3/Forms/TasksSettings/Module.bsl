#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DisplayingTaskCard = Parameters.DisplayingTaskCard;
	DynamicListPageSize = Parameters.DynamicListPageSize;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	Result = New Structure;
	Result.Insert("DisplayingTaskCard", DisplayingTaskCard);
	Result.Insert("DynamicListPageSize", Number(DynamicListPageSize));
	Close(Result);
	
EndProcedure

#EndRegion