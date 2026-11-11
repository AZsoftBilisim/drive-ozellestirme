
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
	
	If Partner = Undefined Or Partner.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	TheContactPersonList.Parameters.SetParameterValue("CurrentDate", BegOfDay(CurrentSessionDate()));
	
	CommonClientServer.SetDynamicListFilterItem(TheContactPersonList,
	                                                    "Owner",
	                                                    Partner,
	                                                    DataCompositionComparisonType.Equal,,True);
	
EndProcedure

&AtClient
Procedure ContactPersonsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	If Copy Then
		Return;
	EndIf;
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues",New Structure("Owner", Partner));
	OpenForm("Catalog.ContactPersonsForPartners.Form.ItemForm", FormParameters, ThisForm, UUID);
	
EndProcedure

#EndRegion
