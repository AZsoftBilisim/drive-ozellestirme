
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Document processing processsreferences
	If Common.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = Common.CommonModule("DocumentProcessingProcessesSalary");
		ModuleDocumentProcessingProcessesSalary.OnCreateAtServer(ThisObject, Object);
	EndIf;
	// End Document processing processsreferences
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// Document processing processsreferences
	If Common.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = Common.CommonModule("DocumentProcessingProcessesSalary");
		ModuleDocumentProcessingProcessesSalary.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End Document processing processsreferences
	
	OnReadCreateAtServer();
	
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
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// Document processing processsreferences
	If Common.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = Common.CommonModule("DocumentProcessingProcessesSalary");
		ModuleDocumentProcessingProcessesSalary.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters, Cancel);
	EndIf;
	// End Document processing processsreferences
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	
	Notify("Write_BankConfirmationAboutCashReceiptOnEmployeeAccount", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Document processing processsreferences
	If Common.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = Common.CommonModule("DocumentProcessingProcessesSalary");
		ModuleDocumentProcessingProcessesSalary.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;	
	// End Document processing processsreferences
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
	// Document processing processsreferences
	If CommonClient.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = 
			CommonClient.CommonModule("DocumentProcessingProcessesSalaryClient");
		ModuleDocumentProcessingProcessesSalary.BeforeClose(
			ThisObject,
			Object,
			Cancel,
			Exit,
			WarningText,
			StandardProcessing);
	EndIf;
	// End Document processing processsreferences
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SourceDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	SourceDocumentStartChoiceServer();
	
EndProcedure

&AtServer
Procedure SourceDocumentStartChoiceServer()

	TypesOfOperation = New Array;
	TypesOfOperation.Add(Type("DocumentRef.BankAccountIssue"));
	
	Items.SourceDocument.TypeRestriction = New TypeDescription(TypesOfOperation);

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)

	BusinessOperationWhenChangingOnServer();

EndProcedure

&AtClient
Procedure SourceDocumentOnChange(Item)
	
	PrimaryDocumentWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure PrimaryDocumentWhenChangedOnServer()
	
	Object.EmployeesHR.Clear();
	
	DocumentObject = FormAttributeToValue("Object");
	FillingData = New Structure("BusinessOperation, Organization");
	
	
	If Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And ValueIsFilled(Object.SourceDocument) Then
		DocumentObject.GetDataOfFillingOutPaymentToAccountable(Object.SourceDocument, FillingData);
	EndIf;
	
	ValueToFormAttribute(DocumentObject, "Object");
	FillPropertyValues(Object, FillingData, , "BusinessOperation, Organization");
	
	
	Object.DocumentAmount = Object.EmployeesHR.Total("Sum");
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionParameters();
	
EndProcedure

&AtClient
Procedure PayrollCardProgramOnChange(Item)

	Return;

EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	Return;

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

#Region FormTableItemsEventHandlersEmployeesHR

&AtClient
Procedure Employees_SumOnChange(Item)
	
	Object.DocumentAmount = Object.EmployeesHR.Total("Sum");
	
EndProcedure

&AtClient
Procedure EmployeesHROnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		Item.CurrentData.CashFlowItem = CashFlowItem;
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeesHROnChange(Item)
	
	Object.DocumentAmount = Object.EmployeesHR.Total("Sum");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInCashFlowItem(Command)

	CashClient.FillInCashFlowItem(
		ThisObject, Items.EmployeesHR, "EmployeesHR");

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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#Region EventHandlersDocumentProcessingProcesses

&AtClient
Procedure Attachable_CompleteDocumentProcessingTask(Command)
	// Document processing processsreferences
	If CommonClient.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = 
			CommonClient.CommonModule("DocumentProcessingProcessesSalaryClient");
		ModuleDocumentProcessingProcessesSalary.ExecuteTask(ThisObject, Command, Object);
	EndIf;
	// End Document processing processsreferences
EndProcedure

&AtClient
Procedure Attachable_CompleteTaskOfProcessingNotificationDocument(Context, AdditionalParameters) Export
	PerformDocumentProcessingTaskOnServer(Context);
	RunCallback(AdditionalParameters, Context);
EndProcedure

&AtServer
Procedure PerformDocumentProcessingTaskOnServer(Context)
	// Document processing processsreferences
	If Common.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = Common.CommonModule("DocumentProcessingProcessesSalary");
		ModuleDocumentProcessingProcessesSalary.ExecuteTask(ThisObject, Context, Object);
	EndIf;
	// End Document processing processsreferences
EndProcedure

&AtClient
Procedure Attachable_CommentByPersonWhoDirectedDiscovery(Item, StandardProcessing)
	// Document processing processsreferences
	If CommonClient.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary =
			CommonClient.CommonModule("DocumentProcessingProcessesSalaryClient");
		ModuleDocumentProcessingProcessesSalary.CommentByPersonWhoDirectedDiscovery(ThisObject, Item, StandardProcessing);
	EndIf;
	// End Document processing processsreferences
EndProcedure

&AtClient
Procedure Attachable_CommentToFollowingBeginningOfSelection(Item, ChoiceData, StandardProcessing)
	// Document processing processsreferences
	If CommonClient.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = 
			CommonClient.CommonModule("DocumentProcessingProcessesSalaryClient");
		ModuleDocumentProcessingProcessesSalary.CommentToFollowingBeginningOfSelection(ThisObject, Item, ChoiceData, StandardProcessing);
	EndIf;		
	// End Document processing processsreferences
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)

	TMCommonUseClient.Post(ThisObject, True);

EndProcedure

&AtClient
Procedure WriteDocument(Command)

	TMCommonUseClient.Write(ThisObject, True);

EndProcedure

&AtClient
Procedure PostAndClose(Command)

	TMCommonUseClient.PostAndClose(ThisObject, True);

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
    FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

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
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure


&AtServer
Procedure OnReadCreateAtServer()

	UsePayroll = GetFunctionalOption("UsePayrollTM");
	
	CashFlowItem = SettingsValueCached.GetCashFlowItem(Object.BusinessOperation);
	
	FillInListOfBusinessOperations();
	
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	SetSelectionParameters();
	
	ConfigureDependentFormElementsOnServer();

EndProcedure

&AtServer
Procedure FillInListOfBusinessOperations()

	AvailableTransactions = Items.BusinessOperation.ChoiceList;
	AvailableTransactions.Clear();
	
	Operations = Enums.BusinessTransactions;
	AvailableTransactions.Add(Operations.IssueCashToAdvanceHolder);
	

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UsePayroll");
	FormAttributes.Insert("PayrollCardProgramSupportsWaysOfCreditingPayments");
	FormAttributes.Insert("CreditingByAccountNumberIsSupported");
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	CashFlowItem = SettingsValueCached.GetCashFlowItem(Object.BusinessOperation);
	
	If ValueIsFilled(Object.SourceDocument)
		And Common.ObjectAttributeValue(Object.SourceDocument, "BusinessOperation") <> Object.BusinessOperation Then
		
		Object.SourceDocument = Undefined;
		PrimaryDocumentWhenChangedOnServer();
		
	EndIf;
	
	SetPrimaryDocumentSelectionParameters();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure SetSelectionParameters()

	
	SetPrimaryDocumentSelectionParameters();

EndProcedure


&AtServer
Procedure SetPrimaryDocumentSelectionParameters()

	PrimaryDocumentSelectionParameters = New Array;
	
	ChoiceParameterOrganization = New ChoiceParameter("Filter.Organization", Object.Organization);
	PrimaryDocumentSelectionParameters.Add(ChoiceParameterOrganization);
	
	SelectionParameterForBusinessTransaction = New ChoiceParameter("Filter.BusinessOperation", Object.BusinessOperation);
	PrimaryDocumentSelectionParameters.Add(SelectionParameterForBusinessTransaction);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
	
		ListSelectionParameter = New ChoiceParameter("Filter.PersonsList", True);
		PrimaryDocumentSelectionParameters.Add(ListSelectionParameter);
	
	EndIf;
	
	Items.SourceDocument.ChoiceParameters = New FixedArray(PrimaryDocumentSelectionParameters);

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
