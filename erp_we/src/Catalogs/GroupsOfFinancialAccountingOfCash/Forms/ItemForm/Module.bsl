
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	Items.GroupRecordInInternationalAccounting.Visible = False;
	GetStateOfAccountingInvoiceRefinement();
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "AccountRefinementSettingsChanged" Then
		GetStateOfAccountingInvoiceRefinement();
	EndIf;
	Return; // in UT11, the handler is empty

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetStateOfAccountingInvoiceRefinement()
	
	FinancialAccountingOfGeneralPurpose.SetVisibilityOfMFPSettings(
		Object.Ref,
		Items.GroupRecordInInternationalAccounting,
		Items.Find("ToConfigureAccountSpecification"));// for limited users, the element is cut from the form
	
EndProcedure
#EndRegion
