#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RecordManager = FormAttributeToValue("Record");
	Query = RecordManager.Query.Get();
	
EndProcedure

#EndRegion