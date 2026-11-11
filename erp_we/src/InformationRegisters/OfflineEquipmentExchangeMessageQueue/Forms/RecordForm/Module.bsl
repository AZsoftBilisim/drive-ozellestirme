
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RecordValue = FormAttributeToValue("Record");
	
	PackageData = RecordValue.PackageData.Get();
	
EndProcedure

#EndRegion