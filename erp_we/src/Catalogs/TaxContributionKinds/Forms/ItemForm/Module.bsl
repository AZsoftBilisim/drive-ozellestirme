
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	Items.PayerGroupCode.Visible = Not GetFunctionalOption("LocalizationRFService");
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	TaxPayer = ?(Object.DeductedFromEmployeeWages, "Employee", "Organization");
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TaxPayerOnChange(Item)
	Object.DeductedFromEmployeeWages = TaxPayer = "Employee";
EndProcedure

// Parameters:
//  Item - FormField
//  StandardProcessing - Boolean
&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

#EndRegion
