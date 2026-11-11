
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FilterStructure1 = New Structure();
	
	If Parameters.Property("Filter", FilterStructure1) And TypeOf(FilterStructure1) = Type("Structure") Then
		
		If FilterStructure1.Property("Organization") Then
			CommonClientServer.SetDynamicListFilterItem(
			List, "Organization", FilterStructure1.Organization);
		EndIf;
		
		If FilterStructure1.Property("Department") Then
			CommonClientServer.SetDynamicListFilterItem(
			List, "Department", FilterStructure1.PaymentMethodHR);
		EndIf;
		
		If FilterStructure1.Property("PaymentMethodHR") Then
			CommonClientServer.SetDynamicListFilterItem(
			List, "PaymentMethodHR", FilterStructure1.PaymentMethodHR);
		EndIf;
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

