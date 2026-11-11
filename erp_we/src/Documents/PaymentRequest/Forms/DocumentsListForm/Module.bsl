
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Items.ListToCreateLoansToTheEmployee.Visible = False;
	Items.ListCreateAPaymentToTheLandlord.Visible = False;
	Items.ListToCreateLoansToTheEmployee.Visible = True;
	Items.ListCreateAPaymentToTheLandlord.Visible = True;
	Items.CreatePaymentToTheCustoms.Visible = False;
	
	InsertRight1 = AccessRight("Insert", Metadata.Documents.PaymentRequest);
	
	ApprovalRight = UserRightsCached.PaymentRequestsApproval();
	ConfirmationRight = UserRightsCached.ApprovalOfPaymentRequestsForPayment();
	
	Items.GroupCreate.Enabled = InsertRight1;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_PaymentRequest" Then
		Items.List.Refresh();
		SetVisibilityOfStatuses();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Applicant = Settings.Get("Applicant");
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Applicant",
		Applicant,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Applicant));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheApplicantSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Applicant",
		Applicant,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Applicant));
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "HasFiles" Then
		StandardProcessing = False;
		ListLine = Items.List.CurrentData;
		If ListLine <> Undefined Then
			FilesOperationsClient.OpenFileListForm(ListLine.Ref,, ThisObject);
		EndIf;
	EndIf;
	
	If Field = Items.EDIState Then
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetVisibilityOfStatuses();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure CreateRefundToCustomer()
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.RefundToCustomer"));
	
EndProcedure

&AtClient
Procedure CreateCashPaymentToAdvanceHolder()
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.IssueCashToAdvanceHolder"));
	
EndProcedure

&AtClient
Procedure ToCreateAPaymentToAnotherOrganization(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.CashPaymentToAnotherCompany"));
	
EndProcedure

&AtClient
Procedure CreateReturnToAnotherCompany(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany"));
	
EndProcedure

&AtClient
Procedure CreateCashTransferToTheBudget(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.TransferOfTaxesAndContributions"));
	
EndProcedure

&AtClient
Procedure CreateOtherCashPayment(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.OtherCashIssue"));
	
EndProcedure

&AtClient
Procedure CreateInternalCashTransfer(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices"));
	
EndProcedure

&AtClient
Procedure CreatePaymentToTheCustoms(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.CustomsPayment"));
	
EndProcedure

&AtClient
Procedure CreateCurrencyConversion(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.CurrencyConversion"));
	
EndProcedure

&AtClient
Procedure CreateSalaryPayment(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PayrollTransaction",
		PredefinedValue("Enum.BusinessTransactions.SalaryPaymentToBankAccounts"));
	AdditionalParameters.Insert("PaymentMethodOfPaymentRequest", PredefinedValue("Enum.PaymentForms.BankAccountPayment"));
	
	CreateRequestForSpendingMoney(
		PredefinedValue("Enum.BusinessTransactions.SalaryPayment"), AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CreateALoanRequest(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived"));
	
EndProcedure

&AtClient
Procedure CreateADepositRequest(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.TransferToDeposits"));
	
EndProcedure

&AtClient
Procedure CreateARequestForLoansToACounterparty(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToCounterparty"));
	
EndProcedure

&AtClient
Procedure CreateALoanRequestForAnEmployee(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToEmployee"));
	
EndProcedure

&AtClient
Procedure CreateAPaymentToTheLandlord(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.PaymentToLessor"));
	
EndProcedure

&AtClient
Procedure CreateARefundToYourPaymentCard(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.RefundAcquiringPayment"));
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreed_3(Command)
	
	SetStatus("NotAgreedUpon", NStr("vi = 'Không thống nhất';
									|ru = 'Не согласована';
									|en = 'Opened'; fa = 'بازشده';
									|it = 'Non concordata';
									|pl = 'Nie uzgodnionoa';
									|tr = 'Beklemede'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusOfTheAgreed(Command)
	
	SetStatus("AgreedUpon", NStr("vi = 'Đã thống nhất';
								|ru = 'Согласована';
								|en = 'Approved'; fa = 'تأییدشده';
								|it = 'Accordato';
								|pl = 'Approved';
								|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusToBePaid(Command)
	
	SetStatus("AmountDue", NStr("vi = 'Cần thanh toán';
								|ru = 'К оплате';
								|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
								|it = 'Da pagare';
								|pl = 'Do płatności';
								|tr = 'Borçlu'"));
	
EndProcedure

&AtClient
Procedure ToSetTheStatusToRejected(Command)
	
	SetStatus("IsRejected", NStr("vi = 'Bị từ chối';
								|ru = 'Отклонена';
								|en = 'Rejected'; fa = 'ردشده';
								|it = 'Respinta';
								|pl = 'Rejected';
								|tr = 'Reddedildi'"));
	
EndProcedure

&AtClient
Procedure SetStatus(Status, StatusName)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = StrTemplate(NStr("vi = 'Các đơn hàng được chọn trong danh sách sẽ có trạng thái ""%1"". Tiếp tục?';
								|ru = 'У выделенных в списке заявок будет установлен статус ""%1"". Продолжить?';
								|en = 'Status ""%1"" will be set for the requests selected in the list. Continue?'; fa = 'Status ""%1"" will be set for the requests selected in the list. Continue?';
								|it = 'Per le domande selezionate nell''elenco sarà impostato lo stato ""%1Continuare?';
								|pl = 'Dla wybranych na liście zleceń będzie ustawiony status ""%1"". Kontynuować?';
								|tr = 'Başvuru listesinde seçilenlerin durumu ""%1"" olarak ayarlanacaktır. Devam edilsin mi?'"), StatusName);
	Notification = New CallbackDescription("SetStatusCompletion", ThisObject,
		New Structure("SelectedRows, Status, StatusName", SelectedRows, Status, StatusName));
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	Status           = AdditionalParameters.Status;
	StatusName       = AdditionalParameters.StatusName;
	
	Response = Result;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, Status);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		Items.List, ProcessedItemsCount, SelectedRows.Count(), StatusName);
	SetVisibilityOfStatuses();
	
EndProcedure

&AtClient
Procedure CloseApplications(Command)
	
	SelectedApplications = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedApplications.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessedItemsCount = CloseApplicationsOnServer(SelectedApplications);
	
	ClearMessages();
	
	If ProcessedItemsCount > 0 Then
		Items.List.Refresh();
		SetVisibilityOfStatuses();
		MessageText = NStr("vi = 'Đã đóng %1 trong số %2 giấy đề nghị đã chọn.';
							|ru = 'Закрыто %1 из %2 выделенных заявок.';
							|en = 'Closed %1 out of %2 selected requests.'; fa = 'Closed %1 out of %2 selected requests.';
							|it = 'Chiuse %1 di %2 richieste evidenziate.';
							|pl = 'Zamknięto %1 z %2 wybranych zleceń.';
							|tr = '%2 tahsisli başvurudan %1 kapatıldı.'");
		ShowUserNotification(StrTemplate(MessageText, ProcessedItemsCount, SelectedApplications.Count()));
	Else
		ShowUserNotification(NStr("vi = 'Không cần đóng các giấy đề nghị đã chọn.';
									|ru = 'Выбранные заявки не нуждаются в закрытии.';
									|en = 'The selected requests do not need to be closed.'; fa = 'The selected requests do not need to be closed.';
									|it = 'Le richieste selezionate non devono essere chiuse.';
									|pl = 'Wybrane zlecenia nie wymagają zamknięcia.';
									|tr = 'Seçilen başvuruların kapatılmasına gerek yoktur.'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CloseApplicationsOnServer(SelectedApplications)
	
	Return Documents.PaymentRequest.CloseApplications(SelectedApplications);
	
EndFunction

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure



#EndRegion

#Region Private

&AtClient
Procedure CreateRequestForSpendingMoney(BusinessOperation, AdditionalParameters = Undefined)
	
	Basis = New Structure("BusinessOperation", BusinessOperation);
	
	If AdditionalParameters <> Undefined And TypeOf(AdditionalParameters) = Type("Structure") Then
		For Each AddnlParameter_ In AdditionalParameters Do
			Basis.Insert(AddnlParameter_.Key, AddnlParameter_.Value)
		EndDo;
	EndIf;
	
	ParametersStructure1 = New Structure("Basis", Basis);
	
	OpenForm("Document.PaymentRequest.ObjectForm", ParametersStructure1, Items.List);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.PaymentRequest.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ClearMessages();
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		ShowValue(Undefined, Ref);
	Else
		
		Notification = New CallbackDescription("ProcessBarcodesCompletion", ThisObject, Data.Barcode);
		
		If ConnectedHandlersLocalization Then
			CashClientLocalization.BeforeProcessingBarcodeOfPaymentLink(ThisObject, Data.Barcode, Notification);
		Else
			RunCallback(Notification, Data.Barcode);
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion


&AtClient
Procedure SetVisibilityOfStatuses()
	
	If Items.List.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	SelectedRows = New Array;
	
	For Each RowSelected In Items.List.SelectedRows Do
		
		If TypeOf(RowSelected) <> Type("DynamicListGroupRow") Then
			SelectedRows.Add(RowSelected);
		EndIf;
		
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		
		VisibilityIsDeclined = False;
		VisibilityIsConsistent = False;
		VisibilityIsNotConsistent = False;
		VisibilityAmountDue = False;
		VisibilityCloseApplications = False;
		
	Else
		
		VisibilityIsDeclined = True;
		VisibilityIsConsistent = ApprovalRight;
		VisibilityIsNotConsistent = True;
		VisibilityAmountDue = ConfirmationRight;
		VisibilityCloseApplications = True;
		
		For Each ListLine In SelectedRows Do
			
			ApplicationRequestData = Items.List.RowData(ListLine);
			
			If ApplicationRequestData = Undefined Then
				Continue;
			EndIf;
			
			VisibilityIsConsistent = Not ApplicationRequestData.Closed_;
			VisibilityAmountDue = Not ApplicationRequestData.Closed_;
			VisibilityIsDeclined = Not ApplicationRequestData.Closed_;
			
			If ApplicationRequestData.Status = PredefinedValue("Enum.StatusesOfPaymentRequests.NotAgreedUpon") Then
				
				VisibilityIsNotConsistent = False;
				VisibilityCloseApplications = ApplicationRequestData.Posted And Not ApplicationRequestData.RequestIsPaid And Not ApplicationRequestData.Closed_;
				
			ElsIf ApplicationRequestData.Status = PredefinedValue("Enum.StatusesOfPaymentRequests.AgreedUpon") Then
				
				VisibilityIsNotConsistent = False;
				VisibilityIsConsistent = False;
				VisibilityCloseApplications = ApplicationRequestData.Posted And Not ApplicationRequestData.Closed_;
				
			ElsIf ApplicationRequestData.Status = PredefinedValue("Enum.StatusesOfPaymentRequests.AmountDue") Then
				
				VisibilityIsConsistent = False;
				VisibilityIsNotConsistent = False;
				VisibilityAmountDue = False;
				VisibilityIsDeclined = ConfirmationRight And Not ApplicationRequestData.Closed_;
				VisibilityCloseApplications = ConfirmationRight And ApplicationRequestData.Posted And Not ApplicationRequestData.RequestIsPaid And Not ApplicationRequestData.Closed_;
				
			ElsIf ApplicationRequestData.Status = PredefinedValue("Enum.StatusesOfPaymentRequests.IsRejected") Then
				
				VisibilityIsConsistent = False;
				VisibilityAmountDue = False;
				VisibilityIsDeclined = False;
				VisibilityIsNotConsistent = VisibilityIsNotConsistent And Not ApplicationRequestData.Closed_ And True;
				VisibilityCloseApplications = False;
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Items.ListSetTheStatusNotAgreed_3.Visible = True;
	Items.ListSetTheStatusOfTheAgreed.Visible = ApprovalRight;
	Items.TheListSetTheStatusToApproved.Visible = ConfirmationRight;
	Items.ListToSetTheStatusToRejected.Visible = True;
	Items.ListCloseApplications.Visible = True;
	
	If Not VisibilityIsConsistent
		And Not VisibilityAmountDue
		And Not VisibilityIsNotConsistent
		And Not VisibilityIsDeclined
		And Not VisibilityCloseApplications Then
		Items.GroupSetStatus.Enabled = False;
	Else
		
		Items.GroupSetStatus.Enabled = True;
		
		Items.ListSetTheStatusNotAgreed_3.Visible = VisibilityIsNotConsistent;
		Items.ListSetTheStatusOfTheAgreed.Visible = VisibilityIsConsistent;
		Items.TheListSetTheStatusToApproved.Visible = VisibilityAmountDue;
		Items.ListToSetTheStatusToRejected.Visible = VisibilityIsDeclined;
		Items.ListCloseApplications.Visible = VisibilityCloseApplications;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBarcodesCompletion(Barcode, AdditionalParameters) Export

	BarcodingOfPrintFormsClient.ObjectIsNotFound(Barcode);

EndProcedure

#EndRegion

