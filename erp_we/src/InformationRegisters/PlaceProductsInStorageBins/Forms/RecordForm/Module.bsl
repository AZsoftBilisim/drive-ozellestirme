
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If ValueIsFilled(Record.Premise)
		And Not ValueIsFilled(Record.Warehouse) Then
			
		Record.Warehouse = Common.ObjectAttributeValue(Record.Premise, "Owner");
		
	EndIf;
	
	If Record.SourceRecordKey.IsEmpty() Then
		SetFormFunctionalOptionParameters(New Structure("Warehouse", Record.Warehouse));
	EndIf;
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	SetFormFunctionalOptionParameters(New Structure("Warehouse", Record.Warehouse));
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Record.Warehouse));
EndProcedure

#EndRegion
