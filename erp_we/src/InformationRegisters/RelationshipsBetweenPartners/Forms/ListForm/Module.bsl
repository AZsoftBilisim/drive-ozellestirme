
#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)

	If Not Copy Then
		// cancel the standard processing and parameterize the form of the new
		Cancel = True;
		NewPratner = Undefined;

		OpenForm("InformationRegister.RelationshipsBetweenPartners.RecordForm",
		New Structure("Partner", Partner),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

#EndRegion
