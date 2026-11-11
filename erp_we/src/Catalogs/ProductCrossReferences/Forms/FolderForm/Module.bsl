
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		// Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not ValueIsFilled(Object.Ref) Then
		
		If Parameters.Property("Owner") Then
			Object.Owner = Parameters.Owner;
		EndIf;
		
	EndIf;
	
	SetPropertiesOfRedefinedFormElements();

	ProductCrossReferencesMappingOverridable.WhenCreatingCounterpartyProductGroupFormOnServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	PartnersProductsClient.Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(ThisObject, Command);
EndProcedure
#EndRegion


#Region Private

&AtServer
Procedure SetPropertiesOfRedefinedFormElements()

	MappingMetadata = ProductCrossReferencesMappingInternal.ProductMappingMetadata();
	
	Title = MappingMetadata.ItemProductsAndPresentation;
	
	Items.Owner.Title = MappingMetadata.OwnerOfProductItemPresentation;
	
EndProcedure

#EndRegion


