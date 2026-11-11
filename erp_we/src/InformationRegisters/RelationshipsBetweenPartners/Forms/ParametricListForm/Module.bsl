
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not Parameters.Property("Partner") Then
		Return;
	EndIf;
	
	Partner = Parameters.Partner;
	List.Parameters.SetParameterValue("Partner", Partner);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	               ThisObject, "ListPartner", NStr("vi = 'Đối tác';
													|ru = 'Контрагент';
													|en = 'Counterparty'; fa = 'طرف حساب';
													|it = 'Controparte';
													|pl = 'Counterparty';
													|tr = 'Cari hesap'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		// cancel the standard processing and parameterize the form of the new
		Cancel = True;
		OpenForm("InformationRegister.RelationshipsBetweenPartners.RecordForm",New Structure("Partner", Partner),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

#EndRegion
