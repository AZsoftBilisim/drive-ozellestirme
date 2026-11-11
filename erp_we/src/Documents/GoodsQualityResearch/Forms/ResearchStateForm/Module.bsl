#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	SetFilter(ThisObject, Parameters.RequestForControl);
	
EndProcedure

#EndRegion

#Region Private

#Region Filter

&AtClientAtServerNoContext
Procedure SetFilter(Form, RequestForControl)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"RequestForControl",
		RequestForControl,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(RequestForControl));
	
EndProcedure

#EndRegion

#Region OtherItems

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);

EndProcedure

#EndRegion

#EndRegion