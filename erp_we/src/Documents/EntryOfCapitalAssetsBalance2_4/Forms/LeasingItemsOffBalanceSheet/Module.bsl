
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	InitializationDuringCreationOnServer();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_EntryOfCapitalAssetsBalance2_4", WriteParameters, Object.Ref);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations
#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure LeasedAssetChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.LeasedAsset, "FixedAsset", ValueSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	FASelectionParameters = TMCommonUseClientServer.PickingParameters(Items.LeasedAssetFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					FASelectionParameters, Items.LeasedAsset,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	EntryOfCapitalAssetsBalanceClientLocalization.FormLeasingItemsForBalance_WhenExecutingCommand(Command, ThisForm);

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#Region AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)

	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	StartDateOfCapitalAssetsAccounting24 = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	
	Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	Items.Counterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	Items.LeasedAssetContract.TypeRestriction = New TypeDescription("CatalogRef.LeaseContract");
	
	RefreshFormTitle();
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtServer
Procedure InitializationDuringCreationOnServer()

	If Parameters.Property("ActivateLine") Then
		ActivateLine = Parameters.ActivateLine;
		If ActivateLine <= Object.LeasedAsset.Count() And ActivateLine > 0 Then
			Items.GroupPages.CurrentPage = Items.OSPage;
			Items.LeasedAsset.CurrentRow = ActivateLine - 1;
		EndIf;
	EndIf; 

EndProcedure

&AtServer
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		Items.PictureDocumentOfMigrationTo24.Visible = False;
		Items.DecorationForSwitchingTo24.Visible = False;
		Items.EnterBalanceBy.Visible = False;
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		Items.LeasedAssetDateOfRecognition.Visible = Object.RecordInOperationalAccounting;
		
		FASelectionOptions = New Array;
		
		FilterState = New Array;
		If Object.RecordInOperationalAccounting Then
			FilterState.Add(Enums.FixedAssetsStates.NotRecognized_);
			FilterState.Add(Enums.FixedAssetsStates.TakenOffBooks);
		Else
			FilterState.Add(Enums.FixedAssetsStates.EnteredInOffBalanceAccounting);
		EndIf; 
		FASelectionOptions.Add(New ChoiceParameter("Filter.State", FilterState));
		FASelectionOptions.Add(New ChoiceParameter("Context", "ACC,MA"));
		
		Items.LeasedAssetFixedAsset.ChoiceParameters = New FixedArray(FASelectionOptions);
		
	EndIf;
	
	EntryOfCapitalAssetsBalanceLocalization.FormLeaseItemsOnBalance_ConfigureDependentFormItems(
		ThisForm, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	Title = NonCurrentAssetsServerCall.PresentationOfInputBalances(Object);

EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)
	
	EntryOfCapitalAssetsBalanceLocalization.FormLeasingItemsForBalance_WhenExecutingCommand(CommandName, ThisObject);
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
