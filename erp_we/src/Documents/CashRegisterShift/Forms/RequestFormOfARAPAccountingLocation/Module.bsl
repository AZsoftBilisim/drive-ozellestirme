
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelCommand(Command)
	
	Result = DataFromResultOfRequestForStoreSAddress();
	Close(Result);
	
EndProcedure

&AtClient
Procedure OkCommand(Command)
	
	Result = New Structure("Result,SettlementAddress,PlaceOfSettlement", DialogReturnCode.OK, TrimAll(SettlementAddress), TrimAll(PlaceOfSettlement));
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function DataFromResultOfRequestForStoreSAddress()
	Return New Structure("Result,StoreAddress,PlaceOfSettlement", DialogReturnCode.Cancel, Undefined, Undefined);
EndFunction
	
#EndRegion
