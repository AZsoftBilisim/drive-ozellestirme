
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
	
	If Not AccessRight("View", Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation) Then
		Items.FormOpenJobsToCalculateDepreciation.Visible = False;
	EndIf; 
	
	#Region UniversalMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	FixedAssetsDepreciationChargeLocalization.OnCreateAtServer(ThisObject);
	
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
Procedure OnOpen(Cancel)
	
	RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting 
		And Not Object.DeletionMark Then
		Cancel = True;
		StartCalculatingDepreciation();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();

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

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	If Not ValueIsFilled(Object.PackageNumber) 
		And ValueIsFilled(Object.Organization) Then
		Object.PackageNumber = DefaultPackageNumber(Object.Organization);
	EndIf;
	
EndProcedure

&AtClient
Procedure PackageNumberStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterParameters = New Structure("Organization", Object.Organization);
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm("InformationRegister.FixedAssetDepreciationPackages.Form.SelectPackage", FormParameters, Item);

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	
	PeriodSelectionFormParameters = New Structure("Value, PeriodSelectionMode", Object.Date, "MONTH");
	OpenForm("CommonForm.PeriodSelection",
		PeriodSelectionFormParameters, 
		ThisObject, 
		UUID,,, 
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	Modified = True;
	
	RegistrationPeriod = BegOfMonth(Object.Date);
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction,
		StandardProcessing,
		RegistrationPeriod,
		RegistrationPeriodPresentation);
		
	Object.Date = RegistrationPeriod;
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	ClearMessages();

	ActionAfterCalculation = "CloseForm";
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);

	Write(WriteParameters);
	
EndProcedure

&AtClient
Procedure OpenJobsToCalculateDepreciation(Command)
	
	FilterParameters = New Structure;
	If ValueIsFilled(Object.Organization) Then
		FilterParameters.Insert("Organization", Object.Organization);
	EndIf; 
	If ValueIsFilled(Object.PackageNumber) Then
		FilterParameters.Insert("PackageNumber", Object.PackageNumber);
	EndIf; 
	FormParameters = New Structure("Filter", FilterParameters);
	OpenForm("InformationRegister.JobsForCalculatingFixedAssetDepreciation.ListForm", FormParameters);
	
EndProcedure

&AtClient
Procedure AccountingTransactions(Command)
	If Modified Or Not ValueIsFilled(Object.Ref) Then
		RecordAndPerformAction(NStr("vi = 'Bút toán kế toán quốc tế';
									|ru = 'Проводки международного учета';
									|en = 'Financial accounting entries'; fa = 'ثبت‌های حسابداری مالی';
									|it = 'Registrazioni nella contabilità internazionale';
									|pl = 'Księgowanie ewidencji międzynarodowej';
									|tr = 'Uluslararası muhasebe girişleri'"), "OpenInternationalAccountingTransactions");
	Else
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Object.Ref);
	EndIf; 
	Return;
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	NonCurrentAssetsClientLocalization.OnExecuteCommand(Command, ThisObject);

EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
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
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);

EndProcedure
 
&AtServer
Function CalculateDepreciationOnServer()
	
	CalculationIsRunning = True;
	
	CalculationParameters = FixedAssetDepreciationCalculation.ExecutionParameters();
	CalculationParameters.Period = Object.Date;
	CalculationParameters.CompaniesList = CommonClientServer.ValueInArray(Object.Organization);
	
	// To fill in the created document
	CalculationParameters.Ref        = Object.Ref;
	CalculationParameters.PackageNumber   = Object.PackageNumber;
	CalculationParameters.EmployeeResponsible = Object.EmployeeResponsible;
	CalculationParameters.Comment   = Object.Comment;
	
	NewPackage = CalculationParameters.DepreciationPackages.Add();
	NewPackage.Organization = Object.Organization;
	NewPackage.PackageNumber = Object.PackageNumber;
	
	TimeConsumingOperation = FixedAssetDepreciationCalculation.RunDepreciationCalculationInBackground(CalculationParameters, UUID);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure StartCalculatingDepreciation()

	If Not CheckFilling() Then
		Return;
	EndIf;
	
	TimeConsumingOperation = CalculateDepreciationOnServer();
	
	CallbackOnCompletion = New CallbackDescription("AfterCalculatingDepreciation", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtClient
Procedure AfterCalculatingDepreciation(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	CalculationResult2 = AfterCalculatingDepreciationOnServer(Result);

	Notify("Write_FixedAssetsDepreciationCharge2_4");
	NotifyChanged(Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutDepreciationCalculation(CalculationResult2, Object.Date);
	
	If CalculationResult2 <> Undefined And Not CalculationResult2.HasErrors Then
		PerformActionAfterCalculation();
	EndIf; 
	
EndProcedure

&AtClient
Procedure PerformActionAfterCalculation()

	If ActionAfterCalculation = "CloseForm" Then
		Close();
	ElsIf ActionAfterCalculation = "OpenInternationalAccountingTransactions" Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Object.Ref);
	Else
		NonCurrentAssetsClientLocalization.PerformActionAfterCalculation(ThisObject, ActionAfterCalculation);
	EndIf; 
	
	ActionAfterCalculation = "";

EndProcedure

&AtServer
Function AfterCalculatingDepreciationOnServer(Val Result)

	CalculationIsRunning = False;
	
	CalculationResult2 = GetFromTempStorage(Result.ResultAddress);
	
	If CalculationResult2 <> Undefined
		And Not CalculationResult2.HasErrors Then
		
		If Not ValueIsFilled(Object.Ref) Then
			ReadRecordedDocument();
		Else	
			Read();
			Modified = False;
		EndIf;
		
	EndIf; 
							
	Return CalculationResult2;
	
EndFunction

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Modified = True;
		Object.Date = EndOfMonth(SelectedPeriod);
		RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordAndPerformAction(ActionHeader_, ActionAfterCalculation)
	
	AdditionalQuestionParameters = New Structure("ActionAfterCalculation", ActionAfterCalculation);

	If Not ValueIsFilled(Object.Ref) Then
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
	                         |Chỉ có thể thực hiện thao tác ""%1"" sau khi ghi lại dữ liệu.
	                         |Dữ liệu sẽ được ghi lại.';
	                         |ru = 'Данные еще не записаны.
	                         |Выполнение действия ""%1"" возможно только после записи данных.
	                         |Данные будут записаны.';
	                         |en = 'Data is not saved.
	                         |You can run ""%1"" only for saved data.
	                         |Data will be saved.'; fa = 'Data is not saved.
	                         |You can run ""%1"" only for saved data.
	                         |Data will be saved.';
	                         |it = 'I dati non sono ancora registrati. 
	                         | L''esecuzione dell''operazione ""%1"" è possibile solamente dopo la registrazione dei dati.
	                         | I dati saranno registrati.';
	                         |pl = 'Dane jeszcze nie są zapisane.
	                         |Wykonanie czynności ""%1"" jest możliwe tylko po wykonaniu zapisu danych.
	                         |Dane będą zapisane.';
	                         |tr = 'Veri hala kaydedilmiyor. 
	                         |İşlemin yürütülmesi ""%1"" sadece veriler kaydedildikten sonra mümkündür. 
	                         |Veri yazılacak.'");
		
		QueryText = StrTemplate(QueryText, ActionHeader_);
		
		CallbackDescription = New CallbackDescription("RecordAndPerformActionCompletion", ThisObject, AdditionalQuestionParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel); 
	Else
		RecordAndPerformActionCompletion(DialogReturnCode.OK, AdditionalQuestionParameters);
	EndIf;

EndProcedure

&AtClient
Procedure RecordAndPerformActionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		ActionAfterCalculation = AdditionalParameters.ActionAfterCalculation;
		Write();
		If Not Object.Posted Then
			PerformActionAfterCalculation();
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DefaultPackageNumber(Val Organization)

	Return Documents.FixedAssetsDepreciationCharge2_4.DefaultPackageNumber(Organization);

EndFunction 

&AtServer
Procedure ReadRecordedDocument()

	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge2_4.Ref AS Ref
	|FROM
	|	Document.FixedAssetsDepreciationCharge2_4 AS FixedAssetsDepreciationCharge2_4
	|WHERE
	|	FixedAssetsDepreciationCharge2_4.Posted
	|	AND FixedAssetsDepreciationCharge2_4.Organization = &Organization
	|	AND FixedAssetsDepreciationCharge2_4.PackageNumber = &PackageNumber
	|	AND FixedAssetsDepreciationCharge2_4.Date = &Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("PackageNumber", Object.PackageNumber);
	Query.SetParameter("Date", EndOfMonth(Object.Date));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		DocumentObject = Selection.Ref.GetObject();
		ValueToFormAttribute(DocumentObject, "Object");
		Modified = False;
	EndIf;

EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	Var ActionParameters;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_WriteAndPerformAction", ActionParameters) Then
		RecordAndPerformAction(ActionParameters.ActionHeader_, ActionParameters.ActionAfterCalculation);
	EndIf; 
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion
