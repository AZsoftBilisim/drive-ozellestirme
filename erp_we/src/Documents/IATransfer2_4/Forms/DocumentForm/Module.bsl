
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_IATransfer2_4", WriteParameters, Object.Ref);
	Notify("RecordDocumentBasedOnInventory");
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
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
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice") Then
		
		If Object.Organization = Object.CompanyRecipient Then
			Object.CompanyRecipient = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf;
		
		If ValueIsFilled(Object.Organization)
			And Not NonCurrentAssetsServerCall.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization) Then
			Object.Organization = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf; 
	
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure DeliveryCompanyOnChange(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice")
		And ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.CompanyRecipient) Then
		If Not NonCurrentAssetsServerCall.OrganizationsAreInterconnectedByOrganizationalStructure(Object.CompanyRecipient, Object.Organization) Then
			Object.CompanyRecipient = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)

	SetSelectionOfCGUByOrganization();

EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice") Then
			If ValueIsFilled(Object.CompanyRecipient) Then
				ListFilter.Insert("Organization", Object.CompanyRecipient);
			EndIf;
		Else
			If ValueIsFilled(Object.Organization) Then
				ListFilter.Insert("Organization", Object.Organization);
			EndIf;
		EndIf; 
		
		If ValueIsFilled(Object.ReceivingBusinessUnit) Then
			ListFilter.Insert("Department", Object.ReceivingBusinessUnit);
		EndIf;
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		OpenForm("Document.IntangibleAssetsPhysicalCount.ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	Else
		
		Object.DocumentBasis = Undefined;
		
	EndIf; 
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected).Count() <> 0 Then
		WhenChangingIAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure IAIntangibleAssetOnChange(Item)
	
	WhenChangingIAOnServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisForm);
	OpenForm(
		"Catalog.IntangibleAssets.ChoiceForm",
		PickingParameters,
		Items.IA,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#Region AttachableCommands

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region Private

// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ConfigureDependentFormElementsOnServer();

	SetSelectionOfCGUByOrganization();
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;

	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__IA(
									Form.Object, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "IA");
	EndIf;

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	
	ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;

	If UpdateAll Then
		
		NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
			Items.BusinessOperation.ChoiceList,
			GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets"),
			Enums.BusinessTransactions.TransferIntangibleAssetsToBranchOffice,
			NStr("vi = 'Điều chuyển đến bộ phận trên bảng cân đối kế toán riêng';
				|ru = 'Перемещение в подразделение на отдельном балансе';
				|en = 'Transfer to business unit on a separate balance sheet'; fa = 'انتقال به واحد تجاری با ترازنامه جداگانه';
				|it = 'Transfer to business unit on a separate balance sheet';
				|pl = 'Transfer to business unit on a separate balance sheet';
				|tr = 'Ayrı bilançodaki departmana transfer'"));
		
		Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingIAOnServer()
	
	FillInHeaderForSelectedIA();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedIA()

	NonCurrentAssetsInternal.FillInHeaderForSelectedIA("Organization,Department", Object.IA, Object);
	ConfigureDependentFormElements(ThisObject, "Organization,Department");
	
EndProcedure

&AtServer
Procedure SetSelectionOfCGUByOrganization()

	ImpairmentFAServer.SetCGUSelectionParameters(Items.CGURecipient, Object);

EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo kiểm kê?';
						|ru = 'Заполнить документ по инвентаризации?';
						|en = 'Fill in the physical inventory count document?'; fa = 'Fill in the physical inventory count document?';
						|it = 'Fill in the physical inventory count document?';
						|pl = 'Fill in the physical inventory count document?';
						|tr = 'Belge stok sayımına göre doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToBaseDataOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccordingToBaseDataOnServer()
	
	Object.IA.Clear();
	
	Documents.IATransfer2_4.FillInBasedOnInventory(Object, True);
	
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
