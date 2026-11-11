#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	Close(DataToManage);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Initialize(Data = "") Export
	
	DataToManage = Data;
	
EndProcedure

#EndRegion
