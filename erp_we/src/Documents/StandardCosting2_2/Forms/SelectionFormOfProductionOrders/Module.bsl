
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	List.Parameters.SetParameterValue("Products", Parameters.Products);
	List.Parameters.SetParameterValue("Characteristic", Parameters.Characteristic);
	List.Parameters.SetParameterValue("Purpose", Parameters.Purpose);
	List.Parameters.SetParameterValue("ForAllAppointments", Not ValueIsFilled(Parameters.Purpose));
	List.Parameters.SetParameterValue("Department", Parameters.Department);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");
	
EndProcedure

#EndRegion
