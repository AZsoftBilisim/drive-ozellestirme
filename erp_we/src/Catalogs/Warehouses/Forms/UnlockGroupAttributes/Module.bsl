
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.GroupSelectAWarehouseGroup.Visible = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments")
		Or GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments");
	
	AllowEditingSelectingAWarehouseGroup = True;
	AllowEditingParent  = True;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure // Joining the Server()

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	
	If AllowEditingSelectingAWarehouseGroup Then
		Result.Add("SelectGroup");
	EndIf;
	
	If AllowEditingParent Then
		Result.Add("Parent");
	EndIf;
	
	Close(Result);

EndProcedure // Allow Editing()

#EndRegion

#EndRegion
