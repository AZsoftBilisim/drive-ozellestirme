#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	MonthByString = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Month);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement	
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = Constants.CurrencyOfActivityKindRates.Get();
	EndIf;
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);

	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.WorkOutput.Form.SelectByReferences" Then
		
		ProcessingOrderSelection(ValueSelected.AddressInStorage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_WorkOutput", WriteParameters, Object.Ref);
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	
	DocumentCorrectionClient.AfterWrite(Object);
	
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
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure TeamOnChange(Item)
	
	If ValueIsFilled(Object.Team) Then
		BrigadeWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkOrderKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StoredValues = Object.WorkOrderKind;
	
EndProcedure

&AtClient
Procedure WorkOrderKindOnChange(Item)
	
	If StoredValues = Object.WorkOrderKind Then
		Return;
	EndIf;
	
	If Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.Personal") Then
		Object.Employees.Clear();
		Object.Team = Undefined;
	EndIf;
	
	Object.AutoAllocation = False;
	
	SetVisibilityAndAvailability();
	
EndProcedure

&AtClient
Procedure UseLPROnChange(Item)
	
	If Object.UseLPR Then
		For Each String In Object.Employees Do
			String.LPR = 1;
		EndDo;
	EndIf;
	
	DistributeAmountToParticipantsOnServer();
	
EndProcedure

&AtClient
Procedure UseHoursWorkedOnChange(Item)
	
	If Not Object.UseHoursWorked Then
		Object.UseTariffRates = False;
	EndIf;
	
	ConfigureFormBasedOnPersonnelDataUsed(ThisForm);
	
	DistributeAmountToParticipantsOnServer();
	
EndProcedure

&AtClient
Procedure UseTariffRatesOnChange(Item)
	DistributeAmountToParticipantsOnServer();
EndProcedure

&AtClient
Procedure AutoAllocationOnChange(Item)
	SetVisibilityAndAvailability();
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#Region EditingMonthByLine

&AtClient
Procedure MonthByStringStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("EnteringMonthBeginningOfSelectionCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("Value", EndOfMonth(Object.Month));
	FormParameters.Insert("PeriodSelectionMode", "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters,
		ThisObject,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthByStringTuning(Item, Direction, StandardProcessing)
	
	Object.Month = AddMonth(Object.Month, Direction);
	
	MonthByString = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Month);
	
	Modified = True;

EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersActivityKinds

&AtClient
Procedure ActivityKindsWorkKindOnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillInPriceOnServer(CurrentData.GetID());
	
	CurrentData.Sum = CurrentData.AmountDueForPayment * CurrentData.Rate_;
	
EndProcedure

&AtClient
Procedure ActivityKindsAssigneeQualificationOnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillInPriceOnServer(CurrentData.GetID());
	
	CurrentData.Sum = CurrentData.AmountDueForPayment * CurrentData.Rate_;
	
EndProcedure

&AtClient
Procedure ActivityKindsAmountDueForPaymentOnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	If CurrentData.AmountDueForPayment > CurrentData.QuantityToRegister Then
		
		CurrentData.AmountDueForPayment = CurrentData.QuantityToRegister;
		
	EndIf;
	
	CurrentData.Sum = CurrentData.AmountDueForPayment * CurrentData.Rate_;
	
EndProcedure

&AtClient
Procedure ActivityKindsQuantityToRegisterOnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	If CurrentData.AmountDueForPayment > CurrentData.QuantityToRegister Then
		
		CurrentData.AmountDueForPayment = CurrentData.QuantityToRegister;
		
	EndIf;
	
	CurrentData.Sum = CurrentData.AmountDueForPayment * CurrentData.Rate_;
EndProcedure


&AtClient
Procedure ActivityKindsRate_OnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	CurrentData.Sum = CurrentData.AmountDueForPayment * CurrentData.Rate_;
	
EndProcedure

&AtClient
Procedure ActivityKindsSumOnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	If CurrentData.Rate_ > 0 Then
		CurrentData.AmountDueForPayment = CurrentData.Sum / CurrentData.Rate_;
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivityKindsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	If CurrentData <> Undefined And Field = Items.ActivityKindsReferenceOrder Then
		If ValueIsFilled(CurrentData.ReferenceOrder) Then
			ShowValue(Undefined, CurrentData.ReferenceOrder);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivityKindsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamKind")
		Or Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.Personal")
		Or Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.Repair")
		Or Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamByOrder21") Then
		
		Cancel = True;
		
		FillParameters = FillParameters();
		
		If FillParameters = Undefined Then
			Return;
		EndIf;
		
		FormParameters = New Structure("FilterStructure1", FillParameters);
		FormParameters.Insert("AddressInStorage", PutWorkTypesInStorage());
		OpenForm("Document.WorkOutput.Form.SelectByReferences", FormParameters, ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivityKindsOnChange(Item)
	
	If (Object.UseLPR
		Or Object.UseTariffRates
		Or Object.UseHoursWorked
		Or Object.AutoAllocation) And Object.Employees.Count() > 0 Then
		DistributeAmountToParticipantsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure TypesOfWorkEmployeeOnChange(Item)
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	FillInEmployeeData(CurrentData.GetID());
	
EndProcedure

&AtClient
Procedure TypesOfWorkEmployeeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.ActivityKinds.CurrentData;
	
	CallbackDescription = New CallbackDescription("TypesOfWorkEmployeeStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		Object.Department,
		CurrentData.Employee,
		CurrentData.WorkExecutionDate,
		True,
		CallbackDescription);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployeesHR

&AtClient
Procedure EmployeesOnChange(Item)
	If Object.UseLPR Or Object.UseHoursWorked Or Object.UseTariffRates Or Object.AutoAllocation Then
		DistributeAmountToParticipantsOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure EmployeesHROnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Employees.CurrentData;
	
	If NewRow And Object.UseLPR Then
		CurrentData.LPR = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeesEmployeeOnChange(Item)
	
	If UsePayroll And
		(Object.UseTariffRates
			Or Object.UseHoursWorked) Then
		SelectedRow = Items.Employees.CurrentRow;
		FillInPersonnelDataOnServer(CommonClientServer.ValueInArray(SelectedRow));
	EndIf;
	
EndProcedure

&AtClient
Procedure Employees_SumOnChange(Item)
	AmountIsAllocated = Object.ActivityKinds.Total("Sum") = Object.Employees.Total("Sum");
EndProcedure

&AtClient
Procedure EmployeesWorkerOnChange(Item)
	Items.Employees.CurrentData.Employee_ = GetIndividualByEmployee(Items.Employees.CurrentData.Employee);
	
	If UsePayroll And
		(Object.UseTariffRates
			Or Object.UseHoursWorked) Then
		SelectedRow = Items.Employees.CurrentRow;
		FillInPersonnelDataOnServer(CommonClientServer.ValueInArray(SelectedRow));
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeesWorkerStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.Employees.CurrentData;
	
	CallbackDescription = New CallbackDescription("EmployeesWorkerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		Object.Department,
		CurrentData.Employee,
		EndOfMonth(Object.Month),
		True,
		CallbackDescription);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

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


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInDocument(Command)
	
	VerificationDetails_ = New Array;
	
	If UsePayroll
		And Object.UseHoursWorked
		And Object.WorkOrderKind <> PredefinedValue("Enum.TeamWorkOrderKinds.Personal") Then
		VerificationDetails_.Add("BeginOfPeriod");
		VerificationDetails_.Add("EndOfPeriod");
	EndIf;
	
	FillParameters = FillParameters(VerificationDetails_);
	
	If FillParameters = Undefined Then
		Return;
	EndIf;
	
	QueryText = Undefined;
	
	If Object.ActivityKinds.Count() > 0 And Object.Employees.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách các tác phẩm và người thực hiện sẽ được bổ sung. Tiếp tục?';
						|ru = 'Списки работ и исполнителей будут перезаполнены. Продолжить?';
						|en = 'Lists of works and assignees will be overwritten. Continue?'; fa = 'Lists of works and assignees will be overwritten. Continue?';
						|it = 'Gli elenchi dei lavori e degli esecutori verranno ricompilati. Continuare?';
						|pl = 'Listy prac i wykonawców prac będą wypełnione ponownie. Kontynuować?';
						|tr = 'İş ve atanan listeleri yeniden doldurulacaktır. Devam edilsin mi?'");
	ElsIf  Object.ActivityKinds.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách các công việc hoàn thành sẽ được bổ sung. Tiếp tục?';
						|ru = 'Список выполненных работ будет перезаполнен. Продолжить?';
						|en = 'Completed work list will be refilled. Continue?'; fa = 'Completed work list will be refilled. Continue?';
						|it = 'Elenco dei lavori effettuati verrà ricompilato. Continuare?';
						|pl = 'LIsta wykonanych prac będzie wypełniona ponownie. Kontynuować?';
						|tr = 'Gerçekleştirilen işlerin listesin yeniden doldurulacaktır. Devam edilsin mi?'");
	ElsIf  Object.Employees.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách nhân viên sẽ được bổ sung. Tiếp tục?';
						|ru = 'Список работников будет перезаполнен. Продолжить?';
						|en = 'Employee list will be overwritten. Continue?'; fa = 'Employee list will be overwritten. Continue?';
						|it = 'Elenco dei dipendenti verrà ricompilato. Continuare?';
						|pl = 'Lista pracowników będzie wypełniona ponownie. Kontynuować?';
						|tr = 'Çalışanların listesi yeniden doldurulacaktır. Devam edilsin mi?'");
	EndIf;
	
	If QueryText <> Undefined Then
		CallbackDescription = New CallbackDescription("FillInDocumentOnClient", ThisObject, FillParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInDocumentOnClient(DialogReturnCode.Yes, FillParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDocumentOnClient(UserAnswer, Var_Parameters) Export
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillInDocumentOnServer(Var_Parameters);
	
EndProcedure

&AtClient
Procedure FillInTheTypesOfWork(Command)
	
	FillParameters = FillParameters();
	
	If FillParameters = Undefined Then
		Return;
	EndIf;
	
	QueryText = Undefined;
	
	If Object.ActivityKinds.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách người lao động sẽ điền lại. Tiếp tục?';
						|ru = 'Список работ будет перезаполнен. Продолжить?';
						|en = 'Work list will be overwritten. Continue?'; fa = 'Work list will be overwritten. Continue?';
						|it = 'Elenco dei lavori verrà ricompilato. Continuare?';
						|pl = 'Lista prac będzie wypełniona ponownie. Kontynuować?';
						|tr = 'İşlerin listesi yeniden doldurulacaktır. Devam edilsin mi?'");
	EndIf;
	
	If QueryText <> Undefined Then
		CallbackDescription = New CallbackDescription("FillInTypesOfWorkOnClient", ThisObject, FillParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInTypesOfWorkOnClient(DialogReturnCode.Yes, FillParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTypesOfWorkOnClient(UserAnswer, Var_Parameters) Export
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillInTypesOfWorkOnServer(Var_Parameters);
	
EndProcedure

&AtClient
Procedure SelectByReferences(Command)
	
	FillParameters = FillParameters();
	
	If FillParameters = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("FilterStructure1", FillParameters);
	FormParameters.Insert("AddressInStorage", PutWorkTypesInStorage());
	OpenForm("Document.WorkOutput.Form.SelectByReferences", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ShowDeviations(Command)
	
	If Not ShowVariances Then
		
		For Each String In Object.ActivityKinds Do
			String.ThereIsAVarience = String.QuantityToRegister <> String.AmountDueForPayment;
		EndDo;
		
		Items.ActivityKinds.RowFilter = New FixedStructure("ThereIsAVarience", True);
		
	Else
		Items.ActivityKinds.RowFilter = Undefined;
	EndIf;
	
	ShowVariances = Not ShowVariances;
	
	Items.ShowDeviations.Check = ShowVariances;
	
EndProcedure

&AtClient
Procedure FillInTheCostingItem(Command)
	
	If Items.ActivityKinds.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền dạng tính giá thành.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	CostTypes = New Array;
	CostTypes.Add(PredefinedValue("Enum.CostTypes.Payroll"));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ExpenseType", CostTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisForm);
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowID In Items.ActivityKinds.SelectedRows Do
		RowData = Object.ActivityKinds.FindByID(RowID);
		RowData.ProductCostElement = Result;
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInEmployees(Command)
	
	VerificationDetails_ = New Array;
	VerificationDetails_.Add("Team");
	
	Cancel = False;
	CheckAttributesFilling(VerificationDetails_, Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	QueryText = Undefined;
	
	If Object.Employees.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách nhân viên sẽ được bổ sung. Tiếp tục?';
						|ru = 'Список работников будет перезаполнен. Продолжить?';
						|en = 'Employee list will be overwritten. Continue?'; fa = 'Employee list will be overwritten. Continue?';
						|it = 'Elenco dei dipendenti verrà ricompilato. Continuare?';
						|pl = 'Lista pracowników będzie wypełniona ponownie. Kontynuować?';
						|tr = 'Çalışanların listesi yeniden doldurulacaktır. Devam edilsin mi?'");
	EndIf;
	
	If QueryText <> Undefined Then
		CallbackDescription = New CallbackDescription("FillEmployeesOnClient", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillEmployeesOnClient(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillEmployeesOnClient(UserAnswer, Var_Parameters) Export
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillInWorkersOnServer();
	
	If Object.Employees.Count() = 0 Then
		MessageText = NStr("vi = 'Không có chứng từ phát triển được tìm thấy để lấp đầy lữ đoàn. Điền vào lữ đoàn bằng tay.';
							|ru = 'Документы выработки для заполнения состава бригады не найдены. Заполните состав бригады вручную.';
							|en = 'Output documents were not found to fill in the work team members. Specify the work team members manually.'; fa = 'Output documents were not found to fill in the work team members. Specify the work team members manually.';
							|it = 'Nessun documento sulla produttività per compilare i componenti della squadra è stato trovato. Compilare i componenti della squadra manualmente.';
							|pl = 'Nie znaleziono dokumentów wydajności do wypełnienia składu brygady. Wypełnij skład brygady ręcznie.';
							|tr = 'Çalışma ekibi içeriğinin doldurulması için çıktı belgeleri bulunamadı. Çalışma ekibi içeriğini manuel olarak doldurun.'");
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeesFillInThePersonnelData(Command)
	
	VerificationDetails_ = New Array;
	
	If UsePayroll
		And Object.UseHoursWorked
		And Object.WorkOrderKind <> PredefinedValue("Enum.TeamWorkOrderKinds.Personal") Then
		VerificationDetails_.Add("BeginOfPeriod");
		VerificationDetails_.Add("EndOfPeriod");
	EndIf;
	
	VerificationDetails_.Add("Organization");
	
	Cancel = False;
	CheckAttributesFilling(VerificationDetails_, Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	SelectedRows = Items.Employees.SelectedRows;
	
	FillInPersonnelDataOnServer(SelectedRows);
	
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

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure SelectPeriod(Command)
	
	TMCommonUseClient.EditPeriod(Object,
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));
	
EndProcedure

&AtClient
Procedure WorkersUploadFromFile(Command)
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert("UseLPR",               Object.UseLPR);
	AdditionalParameters.Insert("UseHoursWorked", Object.UseHoursWorked);
	AdditionalParameters.Insert("UseTariffRates",    Object.UseTariffRates);
	
	If Not Object.Employees.Count() = 0 Then
		
		QueryText = NStr("vi = 'Bảng %1 sẽ được điền lại. Tiếp tục?';
						|ru = 'Таблица %1 будет перезаполнена. Продолжить?';
						|en = 'The table %1 will be refilled. Continue?'; fa = 'The table %1 will be refilled. Continue?';
						|it = 'La tаbellа %1 verrà precompilata. Continuare?';
						|pl = 'Tabela %1 zostanie uzupełniona ponownie. Kontynuować?';
						|tr = '%1 tablosu yeniden doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrTemplate(QueryText, NStr("vi = 'Người lao động';
												|ru = 'Работники';
												|en = 'Employees'; fa = 'کارکنان';
												|it = 'Lavoratori';
												|pl = 'Pracownicy';
												|tr = 'Çalışanlar'"));
		
		Notification = New CallbackDescription("LoadFromFileCompletion", ThisForm, AdditionalParameters);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		ShowUploadFormFromFile(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUploadFormFromFile(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// if the KTU is not used, the column is not displayed
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheStaffOfCTS.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseLPR");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AutoAllocation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// if the tariff rates are not used, the column is not displayed
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeesTariffRate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseTariffRates");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// if the time worked is not used, the column is not displayed
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeesWorkedOut.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseHoursWorked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// the amount for employees is viewable only if auto-distribution is used
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EmployeesHRSum.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseLPR");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseTariffRates");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UseHoursWorked");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// highlighting in red if the amount is not distributed
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Allocated.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountIsAllocated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	// the order is drawn up in color as a hyperlink
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActivityKindsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ActivityKinds.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// the order is only for viewing, if filled in
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActivityKindsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ActivityKinds.ReferenceRowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	// the qualification of the contractor, if it corresponds to the type of work
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActivityKindsAssigneeQualification.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ActivityKinds.AssigneeQualification");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tương ứng với loại công việc>';
													|ru = '<соответствует виду работ>';
													|en = '<corresponds to activity kind>'; fa = '<corresponds to activity kind>';
													|it = '<corrisponde al tipo di lavoro>';
													|pl = '<odpowiada rodzajowi prac>';
													|tr = '<işin türüne uygundur>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SetCompositionOfOperations();
	
	If ValueIsFilled(Object.Currency) Then
		Items.ActivityKindsRate_.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Giá, %1';
																										|ru = 'Расценка, %1';
																										|en = 'Rate, %1'; fa = 'Rate, %1';
																										|it = 'Tariffa, %1';
																										|pl = 'Wycena, %1';
																										|tr = 'Ücret tarifesi, %1'"), Object.Currency);
	Else
		Items.WarningGroup.Visible = True;
	EndIf;
	
	SetVisibilityAndAvailability();
	
	ConfigureFormBasedOnPersonnelDataUsed(ThisForm);
	
	UsePayroll = GetFunctionalOption("UsePayroll");
	
	AmountIsAllocated = Object.ActivityKinds.Total("Sum") = Object.Employees.Total("Sum");
	
	
EndProcedure

&AtServer
Procedure SetVisibilityAndAvailability()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.WorkOutput.NamesOfPropsByTypeOfOutfit(
		Object,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.FormFillInDocument.Enabled = Not ReadOnly;
	Items.ActivityKindsSelectWorkKinds.Enabled = Not ReadOnly;
	Items.ShowDeviations.Enabled = Not ReadOnly;
	Items.EmployeesFillInThePersonnelData.Enabled = Not ReadOnly;
	
	// If backflushed production with physical. if the person corrects the document with the employee, then the verification of filling in the Employee field is disabled
	If Object.AccountingForLaborCostsByEmployees And ArrayOfOperationDetails.Find("ActivityKinds.Employee") <> Undefined
		And ArrayOfOperationDetails.Find("ActivityKinds.Employee_") <> Undefined Then
		Items.ActivityKindsEmployee.AutoMarkIncomplete = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFormBasedOnPersonnelDataUsed(Form)
	
	Form.Items.UseTariffRates.Enabled = Form.Object.UseHoursWorked;
	
	If Form.Object.UseTariffRates And Form.Object.UseHoursWorked Then
		Form.Items.EmployeesFillInThePersonnelData.Title = NStr("vi = 'Tỷ lệ và giờ làm việc';
																|ru = 'Ставки и отработанное время';
																|en = 'Rates and hours worked'; fa = 'نرخ‌ها و ساعات کارکرد';
																|it = 'Tariffe e ore lavorate';
																|pl = 'Stawki i przepracowany czas';
																|tr = 'Oranlar ve çalışılan zaman'");
		Form.Items.EmployeesFillInThePersonnelData.Visible = True;
	ElsIf Form.Object.UseTariffRates Then
		Form.Items.EmployeesFillInThePersonnelData.Title = NStr("vi = 'Giá cước';
																|ru = 'Тарифные ставки';
																|en = 'Tariff rates'; fa = 'نرخ‌های تعرفه';
																|it = 'Tassi tariffari';
																|pl = 'Stawki taryfowe';
																|tr = 'Tarife oranları'");
		Form.Items.EmployeesFillInThePersonnelData.Visible = True;
	ElsIf Form.Object.UseHoursWorked Then
		Form.Items.EmployeesFillInThePersonnelData.Title = NStr("vi = 'Thời gian xử lý';
																|ru = 'Отработанное время';
																|en = 'Hours worked'; fa = 'ساعات کارکرد';
																|it = 'Tempo lavorato';
																|pl = 'Odpracowany czas';
																|tr = 'Çalışılan zaman'");
		Form.Items.EmployeesFillInThePersonnelData.Visible = True;
	Else
		Form.Items.EmployeesFillInThePersonnelData.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPriceOnServer(Id)
	
	RowData = Object.ActivityKinds.FindByID(Id);
	
	RowData.Rate_ = Catalogs.EmployeeWorkKinds.CurrentRateOfTypeOfWork(RowData.WorkKind,
		Object.EndOfPeriod,
		RowData.AssigneeQualification,
		Object.Department,
		Object.Organization);
	
EndProcedure

&AtServer
Procedure FillInWorkersOnServer()
	
	If Object.Ref.IsEmpty() Then
		DateOfComposition = CurrentSessionDate();
	Else
		DateOfComposition = Object.Date;
	EndIf;
	
	Documents.WorkOutput.FillWorkers(Object, DateOfComposition);
	
	AmountIsAllocated = Object.ActivityKinds.Total("Sum") = Object.Employees.Total("Sum");
	
EndProcedure

&AtServer
Procedure FillInPersonnelDataOnServer(SelectedRows)
	
	If SelectedRows.Count() > 0 Then
		
		RowsArray = New Array;
		
		For Each String In SelectedRows Do
			RowsArray.Add(Object.Employees.FindByID(String));
		EndDo;
		
	Else
		RowsArray = Undefined;
	EndIf;
	
	FieldsToFillIn_ = BSKIntegration.EmployeePersonnelDataFieldsToFillIn();
	FieldsToFillIn_.TariffRate	= Object.UseTariffRates;
	FieldsToFillIn_.HoursWorked	= Object.UseHoursWorked;
	
	BSKIntegration.FillInPersonnelDataOfEmployees(
		Object,
		"Employees",
		FieldsToFillIn_,
		RowsArray);
		
	Documents.WorkOutput.DistributeAmountToParticipants(Object);
	AmountIsAllocated = Object.ActivityKinds.Total("Sum") = Object.Employees.Total("Sum");
	
EndProcedure

&AtServer
Procedure DistributeAmountToParticipantsOnServer()
	Documents.WorkOutput.DistributeAmountToParticipants(Object);
	AmountIsAllocated = Object.ActivityKinds.Total("Sum") = Object.Employees.Total("Sum");
EndProcedure

&AtClient
Function FillParameters(VerificationDetails_ = Undefined)
	
	If VerificationDetails_ = Undefined Then
		VerificationDetails_ = New Array;
	EndIf;
	
	VerificationDetails_.Add("Organization");
	VerificationDetails_.Add("WorkOrderKind");
	VerificationDetails_.Add("Department");
	If Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamKind") Or
		Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamByOrder21") Then
		VerificationDetails_.Add("Team");
	EndIf;
	
	Cancel = False;
	CheckAttributesFilling(VerificationDetails_, Cancel);
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("Organization");
	FillParameters.Insert("Department");
	FillParameters.Insert("WorkOrderKind");
	FillParameters.Insert("BeginOfPeriod");
	FillParameters.Insert("EndOfPeriod");
	If Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamKind")
		Or Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.Repair")
		Or Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamWithoutOrder21")
		Or Object.WorkOrderKind = PredefinedValue("Enum.TeamWorkOrderKinds.TeamByOrder21") Then
		FillParameters.Insert("Team");
	EndIf;
	
	FillPropertyValues(FillParameters, Object);
	
	FillParameters.BeginOfPeriod = BegOfDay(FillParameters.BeginOfPeriod);
	FillParameters.EndOfPeriod = ?(ValueIsFilled(FillParameters.EndOfPeriod), EndOfDay(FillParameters.EndOfPeriod), FillParameters.EndOfPeriod);
	
	FillParameters.Insert("DocumentException", Object.Ref);
	
	Return FillParameters;
	
EndFunction

&AtServer
Function PutWorkTypesInStorage()
	
	Return PutToTempStorage(Object.ActivityKinds.Unload(,"ReferenceOrder,ReferenceRowCode,QuantityToRegister,AmountDueForPayment"));
	
EndFunction

&AtServer
Procedure FillInTypesOfWorkOnServer(FillParameters)
	
	Documents.WorkOutput.FillOutTypesOfWorkOnBalances(Object, FillParameters);
	

	SetVisibilityAndAvailability();
	
EndProcedure

&AtServer
Procedure FillInDocumentOnServer(FillParameters)
	
	FillInTypesOfWorkOnServer(FillParameters);
	
	If Object.WorkOrderKind <> Enums.TeamWorkOrderKinds.Personal Then
		Documents.WorkOutput.FillWorkers(Object);
	EndIf;
	
EndProcedure


&AtServer
Procedure DivisionWhenChangedOnServer()
	
	Attributes = Common.ObjectAttributesValues(Object.Department, "UseLPR,UseTariffRates,UseHoursWorked");
	
	FillPropertyValues(Object, Attributes);
	
	ConfigureFormBasedOnPersonnelDataUsed(ThisForm);
	
	If (Object.UseLPR
		Or Object.UseTariffRates
		Or Object.UseHoursWorked) And Object.Employees.Count() > 0 Then
		DistributeAmountToParticipantsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure BrigadeWhenChangingOnServer()
	
	Attributes = Common.ObjectAttributesValues(Object.Team, "Department, Organization");
	
	Object.Department = Attributes.Department;
	Object.Organization = Attributes.Organization;
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure FillInEmployeeData(Id)
	
	RowData = Object.ActivityKinds.FindByID(Id);
	
	RowData.Employee_ = GetIndividualByEmployee(RowData.Employee);
	
	
EndProcedure

&AtClient
Procedure CheckAttributesFilling(AttributesStructure1, Cancel = False)
	
	ClearMessages();
	
	MessageTemplate = NStr("vi = 'Trường ""%1"" chưa điền';
							|ru = 'Поле ""%1"" не заполнено';
							|en = '""%1"" is required'; fa = '""%1"" is required';
							|it = 'Il campo ""%1"" non è compilato';
							|pl = 'Pole ""%1"" nie jest wypełnione';
							|tr = '""%1"" alanı doldurulmadı'");
	
	For Each Attribute In AttributesStructure1 Do
		
		If Not ValueIsFilled(Object[Attribute]) Then
			Item = Items[Attribute]; // FormField
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Item.Title);
			CommonClientServer.MessageToUser(MessageText, , Attribute, "Object", Cancel);
			Cancel = True;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessingOrderSelection(AddressInStorage)
	
	Table = GetFromTempStorage(AddressInStorage);
	
	For Each String In Table Do
		NewRow = Object.ActivityKinds.Add();
		FillPropertyValues(NewRow, String);
		NewRow.WorkExecutionDate = String.Date;
	EndDo;
	
	
	If (Object.UseLPR
		Or Object.UseTariffRates
		Or Object.UseHoursWorked) And Object.Employees.Count() > 0 Then
		DistributeAmountToParticipantsOnServer();
	EndIf;
	
	SetVisibilityAndAvailability();
	
EndProcedure

&AtServer
Procedure SetCompositionOfOperations()
	
	Field = Items.WorkOrderKind;
	Field.ChoiceList.Clear();
	
	// If the type of outfit is for work or Repair, then changing the type of outfit is not available, these are outdated types of outfits.
	If Object.WorkOrderKind = Enums.TeamWorkOrderKinds.OtherActivities Then
		Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.OtherActivities, NStr("vi = 'Công việc khác';
																			|ru = 'Прочим работам';
																			|en = 'Other works'; fa = 'سایر کارها';
																			|it = 'Altri lavori';
																			|pl = 'Innych prac';
																			|tr = 'Diğer işlere'"));
	ElsIf  Object.WorkOrderKind = Enums.TeamWorkOrderKinds.Repair Then
		Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.Repair, NStr("vi = 'Sửa chữa';
																	|ru = 'Ремонтам';
																	|en = 'R&M'; fa = 'تعمیر و نگهداری';
																	|it = 'Alle riparazioni';
																	|pl = 'Remontów';
																	|tr = 'Bakım-onarıma'"));
	// otherwise, only the current types of outfits are available in the document
	Else
		// if production 2.2 is used, then we add new types of outfits
		If GetFunctionalOption("UseProductionManagement2_2") Then
			Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamKind, NStr("vi = 'Đội lao động';
																		|ru = 'Бригаде';
																		|en = 'Work team'; fa = 'تیم کاری';
																		|it = 'Alla squadra';
																		|pl = 'Brygady';
																		|tr = 'Çalışma ekibine'"));
			Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.Personal, NStr("vi = 'Để nhân viên';
																		|ru = 'Работникам';
																		|en = 'Employees'; fa = 'کارکنان';
																		|it = 'Ai dipendenti';
																		|pl = 'Pracowników';
																		|tr = 'Çalışanlara'"));
		EndIf;
		
		// If production 2.1 is used, then we add a type of production order without orders.
		If GetFunctionalOption("UseProductionManagement") Then
			If GetFunctionalOption("ComplexAutomation") Then
				Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamWithoutOrder21, NStr("vi = 'Sản xuất';
																						|ru = 'Производству';
																						|en = 'Production'; fa = 'تولید';
																						|it = 'Produzione';
																						|pl = 'Production';
																						|tr = 'Üretime'"));
			ElsIf GetFunctionalOption("UseProductionManagement2_2") Then
				Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamByOrder21, NStr("vi = 'Lệnh sản xuất (2.1)';
																					|ru = 'Заказу на производство (2.1)';
																					|en = 'Order for production (2.1)'; fa = 'سفارش برای تولید (2.1)';
																					|it = 'Ordine di produzione (2.1)';
																					|pl = 'Zlecenia produkcyjnego (2.1)';
																					|tr = 'Üretim emrine (2.1)'"));
				Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamWithoutOrder21, NStr("vi = 'Sản xuất không theo đơn hàng (2.1)';
																						|ru = 'Производству без заказа (2.1)';
																						|en = 'Backflush production (2.1)'; fa = 'تولید با کسر خودکار (2.1)';
																						|it = 'Produzione senza ordine (2.1)';
																						|pl = 'Produkcji bez zamówienia (2.1)';
																						|tr = 'Geriye dönük üretime (2.1)'"));
			Else
				Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamByOrder21, NStr("vi = 'Lệnh sản xuất';
																					|ru = 'Заказу на производство';
																					|en = 'To production order'; fa = 'به سفارش تولید';
																					|it = 'Ordine di produzione';
																					|pl = 'Zlecenia produkcyjnego';
																					|tr = 'Üretim emrine'"));
				Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamWithoutOrder21, NStr("vi = 'Sản xuất không theo đơn hàng';
																						|ru = 'Производству без заказа';
																						|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
																						|it = 'Produzione senza ordine';
																						|pl = 'Produkcji bez zamówienia';
																						|tr = 'Geriye dönük üretime'"));
			EndIf;
		EndIf;
	EndIf;
	
	// adding types of attire corresponding to the disabled production scheme
	If Object.WorkOrderKind = Enums.TeamWorkOrderKinds.TeamByOrder21
		And Field.ChoiceList.FindByValue(Enums.TeamWorkOrderKinds.TeamByOrder21) = Undefined Then
		Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamByOrder21, NStr("vi = 'Lệnh sản xuất (2.1)';
																			|ru = 'Заказу на производство (2.1)';
																			|en = 'Order for production (2.1)'; fa = 'سفارش برای تولید (2.1)';
																			|it = 'Ordine di produzione (2.1)';
																			|pl = 'Zlecenia produkcyjnego (2.1)';
																			|tr = 'Üretim emrine (2.1)'"));
	EndIf;
	If Object.WorkOrderKind = Enums.TeamWorkOrderKinds.TeamWithoutOrder21
		And Field.ChoiceList.FindByValue(Enums.TeamWorkOrderKinds.TeamWithoutOrder21) = Undefined Then
		Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamWithoutOrder21, NStr("vi = 'Sản xuất không theo đơn hàng (2.1)';
																				|ru = 'Производству без заказа (2.1)';
																				|en = 'Backflush production (2.1)'; fa = 'تولید با کسر خودکار (2.1)';
																				|it = 'Produzione senza ordine (2.1)';
																				|pl = 'Produkcji bez zamówienia (2.1)';
																				|tr = 'Geriye dönük üretime (2.1)'"));
	EndIf;
	
	If Object.WorkOrderKind = Enums.TeamWorkOrderKinds.TeamKind
		And Field.ChoiceList.FindByValue(Enums.TeamWorkOrderKinds.TeamKind) = Undefined Then
		Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.TeamKind, NStr("vi = 'Đội lao động';
																	|ru = 'Бригаде';
																	|en = 'Work team'; fa = 'تیم کاری';
																	|it = 'Alla squadra';
																	|pl = 'Brygady';
																	|tr = 'Çalışma ekibine'"));
	EndIf;
	
	If Object.WorkOrderKind = Enums.TeamWorkOrderKinds.Personal
		And Field.ChoiceList.FindByValue(Enums.TeamWorkOrderKinds.Personal) = Undefined Then
		Field.ChoiceList.Add(Enums.TeamWorkOrderKinds.Personal, NStr("vi = 'Để nhân viên';
																	|ru = 'Работникам';
																	|en = 'Employees'; fa = 'کارکنان';
																	|it = 'Ai dipendenti';
																	|pl = 'Pracowników';
																	|tr = 'Çalışanlara'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetIndividualByEmployee(Employee)
	Return Common.ObjectAttributeValue(Employee, "Individual");
EndFunction


&AtClient
Procedure TypesOfWorkEmployeeStartChoiceCompletion(Result, Var_Parameters) Export
	
	CurrentData = Items.ActivityKinds.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		
		CurrentData.Employee = Result;
		FillInEmployeeData(CurrentData.GetID());
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeesWorkerStartChoiceCompletion(Result, Var_Parameters) Export
	
	CurrentData = Items.Employees.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result)
		And TypeOf(Result) = Type("CatalogRef.EmployeesHR") Then
		
		CurrentData.Employee = Result;
		CurrentData.Employee_ = GetIndividualByEmployee(Result);
		Modified = True;
		
		If UsePayroll And
			(Object.UseTariffRates
				Or Object.UseHoursWorked) Then
			SelectedRow = Items.Employees.CurrentRow;
			FillInPersonnelDataOnServer(CommonClientServer.ValueInArray(SelectedRow));
		EndIf;
		
		If Object.UseLPR Or Object.UseHoursWorked Or Object.UseTariffRates Or Object.AutoAllocation Then
			DistributeAmountToParticipantsOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EnteringMonthBeginningOfSelectionCompletion(Result, Var_Parameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	Object.Month = BegOfMonth(Result);
	MonthByString = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Result);
	Modified = True;
EndProcedure

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

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "WorkOutput.Employees";
	ImportParameters.Title               = NStr("vi = 'Kết nhập bảng ""Người lao động"" từ tệp';
												|ru = 'Загрузка таблицы ""Работники"" из файла';
												|en = 'Import the ""Employees"" table from file'; fa = 'Import the ""Employees"" table from file';
												|it = 'Caricamento della tabella ""Dipendenti"" dal file';
												|pl = 'Pobieranie tabeli ""Pracownicy"" z pliku';
												|tr = 'Dosyadan ""Çalışanlar"" tablosunun yüklenmesi'");
	ImportParameters.AdditionalParameters = AdditionalParameters;
	ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsToLoad();
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject, AdditionalParameters);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters);
	
EndProcedure

&AtClient
Function DescriptionOfTemplateColumnsToLoad();
	
	TemplateColumns = New Array;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("EmployeeCode", New TypeDescription("String",, New StringQualifiers(11)), NStr("vi = 'Mã người lao động';
																																				|ru = 'Код работника';
																																				|en = 'Employee code'; fa = 'Employee code';
																																				|it = 'Codice del dipendente';
																																				|pl = 'Kod pracownika';
																																				|tr = 'Çalışan kodu'"), 15);
	Column.Position = 1;
	Column.Parent = "Employee_";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Employee_", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Người lao động';
																																				|ru = 'Работник';
																																				|en = 'Employee'; fa = 'کارمند';
																																				|it = 'Dipendente';
																																				|pl = 'Pracownik';
																																				|tr = 'Çalışan'"), 30);
	Column.Position = 2;
	TemplateColumns.Add(Column);
	
	Position = 2;
	
	If Object.UseLPR Then
		Position = Position + 1;
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("LPR", New TypeDescription("Number",, New NumberQualifiers(15, 2)), NStr("vi = 'Hiệu suất công việc';
																																				|ru = 'КТУ';
																																				|en = 'LPR'; fa = 'LPR';
																																				|it = 'Coefficiente di partecipazione all''esecuzione dei lavori';
																																				|pl = 'Wskaźnik uczestnictwa w pracy';
																																				|tr = 'İşe katılım katsayısı'"), 6);
		Column.Position = Position;
		TemplateColumns.Add(Column);
	EndIf;
	
	If Object.UseTariffRates Then
		Position = Position + 1;
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("TariffRate", New TypeDescription("Number",, New NumberQualifiers(15, 2)), NStr("vi = 'Mức lương';
																																						|ru = 'Тарифная ставка';
																																						|en = 'Tariff rate'; fa = 'نرخ تعرفه';
																																						|it = 'Aliquota tariffaria';
																																						|pl = 'Stawka taryfowa';
																																						|tr = 'Tarife oranı'"), 15);
		Column.Position = Position;
		TemplateColumns.Add(Column);
	EndIf;
	
	If Object.UseHoursWorked Then
		Position = Position + 1;
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("HoursWorked", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Đã làm việc, giờ';
																																						|ru = 'Отработано часов';
																																						|en = 'Hours worked'; fa = 'ساعات کارکرد';
																																						|it = 'Ore di lavoro';
																																						|pl = 'Odpracowano godzin';
																																						|tr = 'Çalışılan saatler'"), 15);
		Column.Position = Position;
		TemplateColumns.Add(Column);
	EndIf;
	
	Return TemplateColumns;
	
EndFunction

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	Object.Employees.Load(ImportedData);
	
	If Object.UseLPR Or Object.UseHoursWorked Or Object.UseTariffRates Or Object.AutoAllocation Then
		DistributeAmountToParticipantsOnServer();
	EndIf;
	
EndProcedure

#EndRegion

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
