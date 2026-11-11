
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	
	UseMultipleBankAccounts	= GetFunctionalOption("UseMultipleBankAccounts");
	UseMultipleCashAccounts				= GetFunctionalOption("UseMultipleCashAccounts");
	FormItemsManagement();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization = Settings.Get("Organization");
	PayDate = Settings.Get("PayDate");
	Status = Settings.Get("Status");
	SetDynamicListSelection_();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	SetDynamicListSelection_();
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	SetDynamicListSelection_();
	
EndProcedure

&AtClient
Procedure PaymentDateSelectionOnChange(Item)
	
	SetDynamicListSelection_();
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateInpaymentFromBank(Command)
	
	CreateOrderToMoveFunds(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromBank"));
	
EndProcedure

&AtClient
Procedure CreateCashPaymentToAnotherCashAccount(Command)
	
	CreateOrderToMoveFunds(PredefinedValue("Enum.BusinessTransactions.CashIssueToAnotherCashAccount"));
	
EndProcedure

&AtClient
Procedure CreateATransferOfFundsToAnotherAccount(Command)
	
	CreateOrderToMoveFunds(PredefinedValue("Enum.BusinessTransactions.TransferCashToAnotherAccount"));
	
EndProcedure

&AtClient
Procedure CreateCashCollectionToTheBank(Command)
	
	CreateOrderToMoveFunds(PredefinedValue("Enum.BusinessTransactions.CashCollectionToBank"));
	
EndProcedure

&AtClient
Procedure CreateACashCollectionFromTheBank(Command)
	
	CreateOrderToMoveFunds(PredefinedValue("Enum.BusinessTransactions.WithdrawalFromBankAccount"));
	
EndProcedure

// This function is used in the AutoTest of the sales process.
//
&AtClient
Procedure AutoTestSetTheStatusToBePaid(Command) Export
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn từ danh sách lệnh sẽ đặt trạng thái ""Cần thanh toán"". Tiếp tục?';
					|ru = 'У выделенных в списке распоряжений будет установлен статус ""К оплате"". Продолжить?';
					|en = 'Status of the references selected in the list will be set to ""For payment"". Continue?'; fa = 'Status of the references selected in the list will be set to ""For payment"". Continue?';
					|it = 'Alle disposizioni evidenziate nell''elenco verrà assegnato lo stato ""Da pagare"". Continuare?';
					|pl = 'Dla dokumentów zaznaczonych na liście zamówień zostanie ustawiony status ""Do płatności"". Kontynuować?';
					|tr = 'Listede seçilen siparişler ""Ödenecek"" durumuna sahip olacaktır. Devam et?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("AutoTestSetTheStatusToBePaidCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AutoTestSetTheStatusToBePaidCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "AmountDue");
    
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần thanh toán';
																												|ru = 'К оплате';
																												|en = 'Amount due'; fa = 'مبلغ سررسیدشده';
																												|it = 'Da pagare';
																												|pl = 'Do płatności';
																												|tr = 'Ödenecek'"));

EndProcedure

&AtClient
Procedure SetTheAgreedStatus(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các lệnh được chọn trong danh sách sẽ có trạng thái ""Đã thống nhất"". Tiếp tục?';
					|ru = 'У выделенных в списке распоряжений будет установлен статус ""Согласовано"". Продолжить?';
					|en = 'Status of the references selected in the list will be set to Approved. Continue?'; fa = 'Status of the references selected in the list will be set to Approved. Continue?';
					|it = 'Alle disposizioni evidenziate dell''elenco verrà assegnato lo stato ""Concordato"". Continuare?';
					|pl = 'Dla dokumentów zaznaczonych na liście zamówień zostanie ustawiony status ""Uzgodniony"". Kontynuować?';
					|tr = 'Listede seçilen emirler için ""Onaylandı"" durumu ayarlanacaktır. Devam et?'");
	Response = Undefined;
	
	ShowQueryBox(New CallbackDescription("SetTheAgreedStatusCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheAgreedStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Approved");
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã thống nhất';
																	|ru = 'Согласовано';
																	|en = 'Approved'; fa = 'تأییدشده';
																	|it = 'Concordato';
																	|pl = 'Approved';
																	|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreed(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các lệnh đã chọn trong danh sách sẽ đặt trạng thái ""Không thống nhất"". Tiếp tục?';
					|ru = 'У выделенных в списке распоряжений будет установлен статус ""Не согласовано"". Продолжить?';
					|en = 'Status of the references selected in the list will be set to ""Not approved"". Continue?'; fa = 'Status of the references selected in the list will be set to ""Not approved"". Continue?';
					|it = 'Alle disposizioni evidenziate dell''elenco verrà assegnato lo stato ""Non concordato"". Continuare?';
					|pl = 'Dla dokumentów zaznaczonych na liście zamówień zostanie ustawiony status ""Nie uzgodniono"". Kontynuować?';
					|tr = 'Listede seçilen emirler için ""Onaylanmadı"" durumu ayarlanacaktır. Devam et?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusNotAgreedCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreedCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "NotApproved");
    
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Không thống nhất';
																												|ru = 'Не согласовано';
																												|en = 'Not approved'; fa = 'تأییدنشده';
																												|it = 'Non concordato';
																												|pl = 'Nie uzgodniono';
																												|tr = 'Onaylanmadı'"));

EndProcedure

&AtClient
Procedure SetTheRejectedStatus(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách lệnh sẽ đặt trạng thái ""Đã hủy bỏ"". Tiếp tục?';
					|ru = 'У выделенных в списке распоряжений будет установлен статус ""Отклонено"". Продолжить?';
					|en = 'Status of the references selected in the list will be set to ""Rejected"". Continue?'; fa = 'Status of the references selected in the list will be set to ""Rejected"". Continue?';
					|it = 'Alle disposizioni evidenziati dell''elenco verrà assegnato lo stato ""Respinto"". Continuare?';
					|pl = 'Dla dokumentów zaznaczonych na liście zamówień zostanie ustawiony status ""Odrzucono"". Kontynuować?';
					|tr = 'Listede seçilen emirler için ""Reddedildi"" durumu ayarlanacaktır. Devam et?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheRejectedStatusCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheRejectedStatusCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "TurnDown");
    
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Chênh lệch';
																												|ru = 'Отклонено';
																												|en = 'Rejected'; fa = 'ردشده';
																												|it = 'Respinto';
																												|pl = 'Rejected';
																												|tr = 'Reddedildi'"));

EndProcedure

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

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Items.ListCreateATransferOfFundsToAnotherAccount.Visible = UseMultipleBankAccounts;
	Items.ListCreateCashPaymentToAnotherCashAccount.Visible = UseMultipleCashAccounts;
	
	Items.ListCreateCashPaymentToAnotherCashAccount1.Visible = UseMultipleBankAccounts;
	Items.ListCreateATransferOfFundsToAnotherAccount1.Visible = UseMultipleCashAccounts;
	
EndProcedure

&AtServer
Procedure SetVisibilityListOfOrganizations()
	
	Items.ListOrganization.Visible = Not ValueIsFilled(Organization);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection_()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"PaymentDate",
		PaymentDate.Date,
		DataCompositionComparisonType.LessOrEqual,, ValueIsFilled(PaymentDate.Date));
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
	SetVisibilityListOfOrganizations();
	
EndProcedure

#EndRegion

#Region CreatingDocuments

&AtClient
Procedure CreateOrderToMoveFunds(BusinessOperation)

	StructureBase = New Structure("BusinessOperation, Organization", BusinessOperation, Organization);
	ParametersStructure1 = New Structure("Basis", StructureBase);
	OpenForm("Document.CashTransferReferenceOrder.ObjectForm", ParametersStructure1, Items.List);
	
EndProcedure

#EndRegion

#Region Other

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion
