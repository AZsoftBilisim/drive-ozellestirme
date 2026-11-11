//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CustomizeFormElements();
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	Result = New Array; // Array of String
	If AllowToChangeProperty Then
		Result.Add("ProductItemProperty");
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	RebateKindIsUsed = Parameters.RebateKindIsUsed;
	Items.DecorationRecommendation.Visible = Parameters.RebateKindIsUsed;
	IsFullUser = Users.IsFullUser(Undefined, True);
	
	If RebateKindIsUsed
	   And Not IsFullUser Then
		
		ItemArray = New Array; // Array of String
		ItemArray.Add("EnableEdit");
		ItemArray.Add("AllowToChangeProperty");
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
		
	EndIf;
	
EndProcedure

#EndRegion
