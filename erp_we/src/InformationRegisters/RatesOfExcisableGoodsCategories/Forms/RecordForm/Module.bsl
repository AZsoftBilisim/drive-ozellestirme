#Region FormEventHandlers

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Recording_RateOfExciseCategory", WriteParameters, Record.ExcisableGoodsCategory);
	
EndProcedure

#EndRegion
