
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
	
	List.Parameters.SetParameterValue("Partner",Partner);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	If Copy Then
		Return;
	EndIf;
	StructureOfFillValue = New Structure("Partner",Partner);
	
	OpenForm("Catalog.Counterparties.Form.ItemForm",
	             New Structure("FillingValues", StructureOfFillValue),
	             ThisForm);
	
EndProcedure

#EndRegion
