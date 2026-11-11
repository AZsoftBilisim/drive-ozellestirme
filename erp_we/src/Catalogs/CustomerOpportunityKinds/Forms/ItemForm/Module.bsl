
#Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	AvailabilityControl();
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	For Each EnumerationValue In Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities.Metadata().EnumValues Do
		
		SalesOpportunityType = Enums.TypesOfCustomerOpportunities[EnumerationValue.Name];
		
		If Not  Enums.TypesOfCustomerOpportunities.TypeOfTransactionIsAvailableByFunctionalOptions(SalesOpportunityType) Then
			Continue;
		EndIf;
		
		Items.SalesOpportunityType.ChoiceList.Add(SalesOpportunityType)
		
	EndDo;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SalesOpportunityTypeOnChange(Item)

	If ValueIsFilled(Object.SalesOpportunityType) Then
		FormStagesAndName();
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSalesOpportunityStages

&AtClient
Procedure SalesOpportunityStagesOnEditEnd(Item, NewRow, CancelEdit)

	SortStages();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// Command of the subsystem " Prohibit editing details"
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		OpenForm("Catalog.CustomerOpportunityKinds.Form.AttributeUnlocking",,,,,, 
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

#Region Private

&AtServer
Procedure SortStages()

	// get a list of stages ordered by the "Ordering Prop"
	Query = New Query(
		"SELECT
		|	ProcessesStates.Ref AS SaleProcessStage
		|FROM
		|	Catalog.ProcessesStates AS ProcessesStates
		|WHERE
		|	ProcessesStates.Ref IN(&Stages)
		|
		|ORDER BY
		|	ProcessesStates.AddlOrderingAttribute");
	Query.SetParameter("Stages",Object.SalesOpportunityStages.Unload(,"SaleProcessStage"));

	// upload an ordered list
	Object.SalesOpportunityStages.Load(Query.Execute().Unload());

EndProcedure

&AtServer
Procedure FormStagesAndName()

	Object.SalesOpportunityStages.Clear();

	If Not Object.SalesOpportunityType = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement
		And Not Object.SalesOpportunityType = Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities Then
		
		// for transactions with business process management, fill in the name and set of stages
		TypeDetails = SalesOpportunitiesServer.GetDescriptionOfTransactionType(Object.SalesOpportunityType);
		If IsBlankString(Object.Description) Then
			Object.Description = TypeDetails.Presentation;
		EndIf;
		ProcessSteps = BusinessProcesses[TypeDetails.Name].StageList();
		For Each ProcessStep In ProcessSteps Do
			Stage = Object.SalesOpportunityStages.Add();
			Stage.SaleProcessStage = ProcessStep;
		EndDo;
		
	EndIf;

	AvailabilityControl();

EndProcedure

&AtServer
Procedure AvailabilityControl()

	Items.StagesGroup.ReadOnly = 
		(Object.SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement);
	Items.StagesGroup.Visible = 
		(Object.SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities);

EndProcedure

#EndRegion
