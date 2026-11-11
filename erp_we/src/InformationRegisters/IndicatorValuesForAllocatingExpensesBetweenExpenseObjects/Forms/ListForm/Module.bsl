
#Region FormHeaderItemsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MonthEndTransactionsServer.SetSelectionsInRegisterListForm(ThisObject, List);
	
EndProcedure

#EndRegion