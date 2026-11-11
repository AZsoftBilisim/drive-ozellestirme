
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	Items.SelectGroup.ChoiceList.Clear();
	Items.SelectGroup.ChoiceList.Add(Enums.SelectWarehouseGroup.Disable);
	
	If (Not GetFunctionalOption("UseSalesOrders")
		And Not GetFunctionalOption("UsePurchaseOrders")) Then
		
		Items.SelectGroup.ChoiceList.Add(Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices, NStr("vi = 'Cho phép trong các hóa đơn';
																									|ru = 'Разрешить в накладных';
																									|en = 'Allow in invoices'; fa = 'Allow in invoices';
																									|it = 'Permettere nelle bolle';
																									|pl = 'Zezwól w fakturach';
																									|tr = 'Faturalarda izin ver'"));
		
	Else
		
		Items.SelectGroup.ChoiceList.Add(Enums.SelectWarehouseGroup.AllowInOrders);
		Items.SelectGroup.ChoiceList.Add(Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices);
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.Warehouses.Form.UnlockGroupAttributes",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
