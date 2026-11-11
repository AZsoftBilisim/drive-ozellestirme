
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
	
	Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner);
	
	List.Parameters.SetParameterValue("Owner",Counterparty);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	StructureOfFillValue = New Structure("Owner",Counterparty);
	OpenForm("Catalog.CounterpartyBankAccounts.Form.ItemForm",
	             New Structure("FillingValues", StructureOfFillValue),
	             ThisForm);
	
EndProcedure

#EndRegion
