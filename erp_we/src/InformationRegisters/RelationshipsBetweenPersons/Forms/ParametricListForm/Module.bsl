
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Parameters.Property("Person", Person);
	List.Parameters.SetParameterValue("Person", Person);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		// cancel the standard processing and parameterize the form of the new
		Cancel = True;
		OpenForm("InformationRegister.RelationshipsBetweenPersons.RecordForm",New Structure("Person", Person),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

#EndRegion
