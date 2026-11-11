#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SeparationDisabled = Not Common.DataSeparationEnabled();
	Items.List.ChangeRowSet = SeparationDisabled
EndProcedure

#EndRegion