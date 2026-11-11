#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
		
	UseCharacteristics = Constants.UseItemVariants.Get();
	KeepAccountingByBatch = Constants.UseItemsBatch.Get();
		   
	If Not KeepAccountingByBatch Then
		
		Items.SingleProductDescription.ChoiceList.Delete(2);
		Items.DecorationMonotonicityWithoutSeries.Visible = True;

		If Not UseCharacteristics Then
			Items.PagesSingleProductBinAndPickingPriority.CurrentPage = Items.PageWithoutMonotonicity;
		EndIf;
		
	Else
		
		If Not UseCharacteristics Then
			Items.SingleProductDescription.ChoiceList[2].Presentation = NStr("vi = 'theo mặt hàng và sê-ri';
																			|ru = 'по номенклатуре и серии';
																			|en = 'by items and batch'; fa = 'by items and batch';
																			|it = 'in base all''articolo e al numero di serie';
																			|pl = 'wg towaru i serii';
																			|tr = 'öğeye ve partiye göre'");
			Items.SingleProductDescription.ChoiceList.Delete(1);
			Items.DecorationMonotonicityWithoutSeries.Visible = True;
		EndIf;
		
	EndIf;
	
	If Object.StrictlySingleProductBins Then
		Allocate = "StrictlySingleProductBins";
	Else
		Allocate = "ByPriorities";
	EndIf;	
	
	ConfigureAvailabilityOfPlacementPriorities();
	
	If Not ValueIsFilled(Object.FrequencyOfBinInventoryRecount) Then
		Object.FrequencyOfBinInventoryRecount = Enums.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.DontUse;		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	Items.ControlQuantityOfAssignmentsInBins.Enabled = StorageType = "Detached";
		
	If Not AccessRight("Update",Metadata.Catalogs.StorageAreas) Then
		Items.ProductStorageGroup.Enabled = False;	
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Allocate = "ByPriorities" Then
		CurrentObject.StrictlySingleProductBins = False;
	Else
		CurrentObject.StrictlySingleProductBins = True;
	EndIf;	

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LongDescStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Object.LongDesc",
		NStr("vi = 'Mô tả';
			|ru = 'Описание';
			|en = 'Details'; fa = 'جزئیات';
			|it = 'Descrizione';
			|pl = 'Details';
			|tr = 'Ayrıntılar'"));
	
EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Owner))
EndProcedure

&AtClient
Procedure StorageTypeOnChange(Item)
	
	If StorageType = "Shared" Then
		Items.PagesStrategies.CurrentPage = Items.StrategiesAreAvailable;
		Items.ControlQuantityOfAssignmentsInBins.Enabled = False;
		Object.ControlQuantityOfAssignmentsInBins = False;
		Object.SeparateStorageArea = False;
	Else
		Items.PagesStrategies.CurrentPage = Items.StrategiesAreNotAvailable;
		Items.ControlQuantityOfAssignmentsInBins.Enabled = True;
		Object.SeparateStorageArea = True;
	EndIf;
	          	
EndProcedure

&AtClient
Procedure UsingTheFrequencyOfCellInventoryWhenChanging(Item)
	UsingPeriodicityOfCellInventoryWhenChangingOnServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.StorageAreas.Form.AttributeUnlocking",,,,,, 
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Owner));
	
	UseOrderSupplyWithAssignment = GetFormFunctionalOption("UseOrderSupplyWithAssignment");
	
	If GetFormFunctionalOption("UseOrderSupplyWithAssignment") 
		And Object.SeparateStorageArea Then
		StorageType = "Detached";
		Items.PagesStrategies.CurrentPage = Items.StrategiesAreNotAvailable;
	Else
		StorageType = "Shared";
		Items.PagesStrategies.CurrentPage = Items.StrategiesAreAvailable;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) And StorageType = "Detached" Then
		Object.ControlQuantityOfAssignmentsInBins = True;
	EndIf;
	
	Items.ExplanationOfSeparateStorage.Visible = UseOrderSupplyWithAssignment;
	Items.ExplanationOfSeparateStorage1.Visible = UseOrderSupplyWithAssignment;
	
	UsingPeriodicityOfCellInventoryWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfPlacementPriorities()
	
	If Allocate = "StrictlySingleProductBins" Then
		Items.PlacementPriorities.Enabled = False;
	Else
		Items.PlacementPriorities.Enabled = True;	
	EndIf;	
	
EndProcedure

&AtServer
Procedure UsingPeriodicityOfCellInventoryWhenChangingOnServer()
	
	If Object.FrequencyOfBinInventoryRecount 
			= Enums.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.UseStorageAreaSettings Then 
		Items.NumberOfDaysBetweenStocktakingsPages.CurrentPage = Items.GroupNumberOfDaysBetweenInventoriesAvailable;
	Else
		Object.NumberOfDaysOfPhysicalCountCycle = 0;
		Items.NumberOfDaysBetweenStocktakingsPages.CurrentPage = Items.TheGroupNumberOfDaysBetweenInventoriesIsNotAvailable;
	EndIf;
	
EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure PostOnChange(Item)
	
	ConfigureAvailabilityOfPlacementPriorities();	
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion
