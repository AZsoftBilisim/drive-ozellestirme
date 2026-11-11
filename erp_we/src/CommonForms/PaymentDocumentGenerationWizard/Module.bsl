#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
		UploadCreatedDocuments();
	
	CreatedDocuments.Parameters.SetParameterValue("IDOfTheObjectReceiptOfNonCashDS",
		Common.MetadataObjectID("Document.BankAccountReceiptNote"));
	CreatedDocuments.Parameters.SetParameterValue("TheObjectIDOfTheNonCashWriteOffOfDS",
		Common.MetadataObjectID("Document.BankAccountIssue"));
	CreatedDocuments.Parameters.SetParameterValue("IDOfThePKOObject",
		Common.MetadataObjectID("Document.CashAccountReceiptNote"));
	CreatedDocuments.Parameters.SetParameterValue("IDOfTheRKOObject",
		Common.MetadataObjectID("Document.CashVoucher"));
	CreatedDocuments.Parameters.SetParameterValue("TheObjectIDOfTheApplication",
		Common.MetadataObjectID("Document.PaymentRequest"));
	
	FormItemsManagement();
	
	// StandardSubsystems.AttachableCommands
	TypesList = CreatedDocuments.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.DocumentListCommandGroup;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_PaymentCardTransaction" Then
		
		Items.CreatedDocuments.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseWithoutConfirmation Then
		StandardProcessing = False;
		Cancel = True;
		If Exit Then
			WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			Return;
		EndIf;
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Đóng';
												|ru = 'Закрыть';
												|en = 'Close'; fa = 'بستن';
												|it = 'Chiudere';
												|pl = 'Zamknij';
												|tr = 'Kapat'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		QueryText = NStr("vi = 'Công việc tạo chứng từ chưa được hoàn thành. Đóng biểu mẫu?';
						|ru = 'Работа по созданию документов не была завершена. Закрыть форму?';
						|en = 'Document creation was not completed. Close the form?'; fa = 'Document creation was not completed. Close the form?';
						|it = 'Il lavoro per la creazione di documenti non è stato completato. Chiudere il modulo?';
						|pl = 'Praca nad tworzeniem dokumentów nie została zakończona. Zamknąć formularz?';
						|tr = 'Belge oluşturma çalışmaları tamamlanmadı. Formu kapat?'");
		ShowQueryBox(New CallbackDescription("QuestionOfClosure", ThisObject), QueryText, Buttons);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Post(Command)
	
	TMCommonUseClient.PostDocuments(Items.CreatedDocuments, Title);
	
EndProcedure

&AtClient
Procedure CancelAndDelete(Command)
	
	TimeConsumingOperation = StartDeletingCreatedDocuments();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Insert("MessageText", NStr("vi = 'Xóa chứng từ thanh toán ...';
												|ru = 'Удаление платежных документов...';
												|en = 'Delete payment documents...'; fa = 'Delete payment documents...';
												|it = 'Eliminazione dei documenti di pagamento...';
												|pl = 'Usuwanie dokumentów płatniczych...';
												|tr = 'Ödeme belgelerinin silinmesi...'"));
	CallbackDescription = New CallbackDescription("WhenYouFinishDeletingCreatedDocuments", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure AcceptAndClose(Command)
	
	QuestionUnverifiedDocuments();
	
EndProcedure

&AtClient
Procedure AcceptAndExport(Command)
	
	QuestionUnverifiedDocuments(True);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each Request In Requests Do
		Request.Check = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	For Each Request In Requests Do
		Request.Check = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectionBasedOnControlResultsOnChange(Item)
	
	PickRequests = Undefined;
	If SelectionBasedOnControlResults = 0 Then
		PickRequests = New FixedStructure("ControlPassed", False);
	ElsIf SelectionBasedOnControlResults = 1 Then
		PickRequests = New FixedStructure("ControlPassed", True);
	EndIf;
	
	Items.Requests.RowFilter = PickRequests;
	
EndProcedure

&AtClient
Procedure GeneratePayments(Command)
	
	TimeConsumingOperation = GeneratePaymentsOnServer();
	
	CallbackDescription = New CallbackDescription("WhenCompletingCreationOfPaymentDocuments", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
	IdleParameters.Insert("MessageText", NStr("vi = 'Tạo chứng từ thanh toán ...';
												|ru = 'Создание платежных документов...';
												|en = 'Create payment documents...'; fa = 'Create payment documents...';
												|it = 'Creazione dei documenti di pagamento...';
												|pl = 'Tworzenie dokumentów płatniczych...';
												|tr = 'Ödeme belgelerinin oluşturulması...'"));
	IdleParameters.Insert("OutputProgressBar", True);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtServer
Function GeneratePaymentsOnServer()
	
	DocumentsToCreate = New Array;
	
	LinesForPayment = Requests.FindRows(New Structure("Check", True));
	DocumentsTable = Requests.Unload(LinesForPayment);
	
	For Each DocumentLine In DocumentsTable Do
		
		If TypeOf(DocumentLine.Ref) = Type("DocumentRef.PaymentRequest") Then
			FillingData = New Structure;
			FillingData.Insert("DocumentBasis", DocumentLine.Ref);
			FillingData.Insert("MultipleSpendingRequests", True);
			FillingData.Insert("BankAccountCashAccount", DocumentLine.BankAccount);
			FillingData.Insert("PayerBeneficiary", DocumentLine.PayerBeneficiary);
			FillingData.Insert("BusinessOperation", DocumentLine.BusinessOperation);
			FillingData.Insert("Sum", DocumentLine.AmountToPay);
			FillingData.Insert("Currency", DocumentLine.Currency);
		Else
			FillingData = DocumentLine.Ref;
		EndIf;
		
		DocumentToCreate = New Structure;
		DocumentToCreate.Insert("DocumentType", "BankAccountIssue");
		DocumentToCreate.Insert("FillingData", FillingData);
		DocumentsToCreate.Add(DocumentToCreate);
	EndDo;
	
	JobDescription = NStr("vi = 'Lập chứng từ thanh toán';
							|ru = 'Формирование платежных документов';
							|en = 'Generate payment documents'; fa = 'Generate payment documents';
							|it = 'Creazione dei documenti di pagamento';
							|pl = 'Tworzenie dokumentów płatniczych';
							|tr = 'Ödeme belgelerinin oluşturulması'");
	MethodToExecute = "CashServer.CreatePayments";
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DocumentsToCreate", DocumentsToCreate);
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, ParametersStructure, ExecutionParameters);
	
EndFunction

&AtClient
Procedure WhenCompletingCreationOfPaymentDocuments(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.MessageToUser(Result.BriefErrorDescription);
		Return;
	ElsIf Result.Status = "Completed2" Then
		WhenCompletingCreationOfPaymentDocumentsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenCompletingCreationOfPaymentDocumentsOnServer()
	
	UploadCreatedDocuments();
	FormItemsManagement();
	
EndProcedure


&AtClient
Procedure SynchronizeWithBank(Command)
	
	Return;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.CreatedDocuments);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.CreatedDocuments, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.CreatedDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure RequestsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, Items.Requests.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure RequestsOnActivateRow(Item)
	
	If Item.CurrentData <> Undefined Then
		Items.ControlResults.RowFilter = New FixedStructure("Ref", Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreatedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure CreatedDocumentsOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ResultsOfDocumentControlSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, Items.ControlResults.CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CreatedDocuments.Date", "CreatedDocumentsDate");
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	ControlStage = (Items.GroupPages.CurrentPage = Items.PageControl);
	
	Items.Close.Visible = ControlStage;
	Items.CancelAndDelete.Visible = Not ControlStage;
	Items.GeneratePayments.Visible = ControlStage;
	Items.AcceptAndClose.Visible = Not ControlStage;
	Items.AcceptAndExport.Visible = Not ControlStage And ThereArePaymentOrders;
	
	If Not ControlStage And ThereArePaymentOrders Then
		Items.AcceptAndExport.DefaultButton = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadList()
	
	CommonClientServer.SetDynamicListFilterItem(
		CreatedDocuments,
		"Ref",
		DocumentsList,
		DataCompositionComparisonType.InList,,
		True);
		
	MetadataObjects = New Array;
	For Each CurRow In DocumentsList Do
		MetadataObject = Metadata.FindByType(TypeOf(CurRow.Value));
		If MetadataObject = Metadata.Documents.BankAccountIssue Then
			ThereArePaymentOrders = True;
		EndIf;
		MetadataObjects.Add(MetadataObject);
	EndDo;
	MetadataObjects = CommonClientServer.CollapseArray(MetadataObjects);
	
	If MetadataObjects.Find(Metadata.Documents.CashAccountReceiptNote) <> Undefined
		Or MetadataObjects.Find(Metadata.Documents.CashVoucher) <> Undefined Then
		PaymentInCash = True;
	EndIf;
	
	If MetadataObjects.Find(Metadata.Documents.CashAccountReceiptNote) <> Undefined
		Or MetadataObjects.Find(Metadata.Documents.BankAccountReceiptNote) <> Undefined Then
		ReceiptDocuments = True;
	EndIf;
	
EndProcedure

&AtServer
Function StartDeletingCreatedDocuments()
	
	MethodToExecute = "CashServer.DeletePayments";
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	Return TimeConsumingOperations.ExecuteInBackground(MethodToExecute, DocumentsList.UnloadValues(), ExecutionParameters);
	
EndFunction

&AtClient
Procedure WhenYouFinishDeletingCreatedDocuments(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.MessageToUser(Result.BriefErrorDescription);
		Return;
	EndIf;
	
	ErrorList = GetFromTempStorage(Result.ResultAddress);
	If ValueIsFilled(ErrorList) Then
		CommonClientServer.ReportErrorsToUser(ErrorList);
		Items.CreatedDocuments.Refresh();
	Else
		CloseWithoutConfirmation = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionUnverifiedDocuments(ExportToBank = False)
	
	If HasUnpostedDocuments() Then
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes);
		Buttons.Add(DialogReturnCode.No);
		QueryText = NStr("vi = 'Một số chứng từ đã không được kết chuyển. Bạn có chắc chắn muốn để lại các chứng từ chưa kết chuyển?';
						|ru = 'Некоторые документы не были проведены. Вы уверены, что хотите оставить документы непроведенными?';
						|en = 'Some documents were not posted. Are you sure you want to leave the documents unposted?'; fa = 'Some documents were not posted. Are you sure you want to leave the documents unposted?';
						|it = 'Alcuni documenti non sono stati registrati. Siete sicuri di voler lasciare i documenti non registrati?';
						|pl = 'Niektóre dokumenty nie zostały zaksięgowane. Czy na pewno chcesz zostawić dokumenty bez zaksięgowania?';
						|tr = 'Bazı belgeler yerine getirilmemiştir. Belgeleri kaydetmeden bırakmak istediğinizden emin misiniz?'");
		CallbackDescription = New CallbackDescription("QuestionAboutClosingUnverifiedDocuments", ThisObject, ExportToBank);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	Else
		If ExportToBank Then
			BankClientParameters = New Structure("AddressOfDocumentsToUpload", AddressOfDocumentsToUpload());
			OpenForm("DataProcessor.EDIWithBanks.Form.ExportToBank",
				BankClientParameters,
				ThisForm.FormOwner,,,,,
				FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		CloseWithoutConfirmation = True;
		Close(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionAboutClosingUnverifiedDocuments(QuestionResult, ExportToBank) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Response = DialogReturnCode.Yes Then
		If ExportToBank Then
			BankClientParameters = New Structure("AddressOfDocumentsToUpload", AddressOfDocumentsToUpload());
			OpenForm("DataProcessor.EDIWithBanks.Form.ExportToBank",
				BankClientParameters,
				ThisForm.FormOwner,,,,,
				FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		CloseWithoutConfirmation = True;
		Close(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionOfClosure(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Cancel Then
		Return;
	ElsIf Response = DialogReturnCode.OK Then
		CloseWithoutConfirmation = True;
		Close(True);
	EndIf;
	
EndProcedure

&AtServer
Function HasUnpostedDocuments()
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	1
	|FROM
	|	InformationRegister.DocumentsRegistry AS Payments_2
	|WHERE
	|	NOT Payments_2.Posted
	|	AND Payments_2.Ref IN (&DocumentsList)
	|");
	
	Query.SetParameter("DocumentsList", DocumentsList);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Function AddressOfDocumentsToUpload()
	
	DCS = Items.CreatedDocuments.GetPerformingDataCompositionScheme();
	Settings = Items.CreatedDocuments.GetPerformingDataCompositionSettings();
	Settings.Structure.Clear();
	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField")).Field = New DataCompositionField("Ref");
	DetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField")).Field = New DataCompositionField("BankAccount");
	DCSResult = FinancialReportingServer.UploadDCSResults(DCS, Settings);
	
	Return PutToTempStorage(DCSResult, UUID);
	
EndFunction

&AtServerNoContext
Function ReadDataFromSecureStorage()
	
	Owner = Users.AuthorizedUser();
	SetPrivilegedMode(True);
	ProtectedData = Common.ReadDataFromSecureStorage(Owner, "PaymentDocumentGenerationWizard");
	SetPrivilegedMode(False);
	
	Return ProtectedData;
	
EndFunction

&AtServerNoContext
Procedure DeleteDataFromSecureStorage()
	
	Owner = Users.AuthorizedUser();
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Owner, "PaymentDocumentGenerationWizard");
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure SetColumnTitleAndListDocuments()
	
	DocumentsCount = DocumentsList.Count();
	
	DocumentsCreated = 0; ValuesOfListToDelete = New Array;
	For Each ListLine In DocumentsList Do
		If ValueIsFilled(ListLine.Value) Then
			DocumentsCreated = DocumentsCreated + 1;
		Else
			ValuesOfListToDelete.Add(ListLine);
		EndIf;
	EndDo;
	
	For Each ValueOfListToDelete In ValuesOfListToDelete Do
		DocumentsList.Delete(ValueOfListToDelete);
	EndDo;
	
	DeclensionIsCreated = NStr("vi = 'Đã tạo mới, Đã tạo mới, Đã tạo mới';
								|ru = 'Создан, Создано, Создано';
								|en = 'Created, Created, Created'; fa = 'Created, Created, Created';
								|it = 'Creato, Creato, Creato';
								|pl = 'Utworzony, Utworzono, Utworzono';
								|tr = 'Oluşturuldu, Oluşturuldu, Oluşturuldu'");
	CreatedOn = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(DocumentsCount, DeclensionIsCreated);
	CreatedOn = StrReplace(CreatedOn, DocumentsCount + " ", "");
	
	DeclinationOfDocuments = NStr("vi = 'chứng từ, chứng từ, chứng từ';
									|ru = 'документ, документа, документов';
									|en = 'document, document, documents'; fa = 'document, document, documents';
									|it = 'documento, documento, documenti';
									|pl = 'dokument, dokumentu, dokumentów';
									|tr = 'belge, belgenin, belgeler'");
	Var_Documents = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(DocumentsCount, DeclinationOfDocuments);
	
	If DocumentsCreated = DocumentsCount Then
		Title = CreatedOn + " " + Var_Documents;
	Else
		Title = CreatedOn + " " + DocumentsCreated + " " + NStr("vi = 'từ';
																|ru = 'из';
																|en = 'from'; fa = 'از';
																|it = 'из';
																|pl = 'from';
																|tr = '-den/dan'") + " " + Var_Documents;
	EndIf;
	
	If ReceiptDocuments Then
		Items.CreatedDocumentsRecipientPayer.Title = NStr("vi = 'Người nộp';
															|ru = 'Плательщик';
															|en = 'Payer'; fa = 'پرداخت‌کننده';
															|it = 'Плательщик';
															|pl = 'Płatnik';
															|tr = 'Ödeyen'");
	Else
		Items.CreatedDocumentsRecipientPayer.Title = NStr("vi = 'Người nhận';
															|ru = 'Получатель';
															|en = 'Payee'; fa = 'ذی‌نفع';
															|it = 'Получатель';
															|pl = 'Odbiorca';
															|tr = 'Alıcı'");
	EndIf;
	
	If PaymentInCash Then
		Items.CreatedDocumentsBankAccountCashAccount.Title = NStr("vi = 'Quỹ tiền mặt';
																	|ru = 'Касса';
																	|en = 'Cash account'; fa = 'صندوق';
																	|it = 'Касса';
																	|pl = 'Kasa';
																	|tr = 'Kasa hesabı'");
	Else
		Items.CreatedDocumentsBankAccountCashAccount.Title = NStr("vi = 'Tài khoản ngân hàng';
																	|ru = 'Банковский счет';
																	|en = 'Bank account'; fa = 'حساب بانکی';
																	|it = 'Conto corrente bancario';
																	|pl = 'Rachunek bankowy';
																	|tr = 'Banka hesabı'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadCreatedDocuments()
	
	AddressOfDocuments = ReadDataFromSecureStorage();
	If ValueIsFilled(AddressOfDocuments) Then
		DeleteDataFromSecureStorage();
	Else
		Raise NStr("vi = 'Một ngoại lệ xảy ra trong khi tạo chứng từ. Liên hệ với quản trị viên hệ thống của bạn.';
					|ru = 'При создании документов произошла исключительная ситуация. Обратитесь к администратору системы.';
					|en = 'An exception is thrown when creating documents. Contact system administrator.'; fa = 'An exception is thrown when creating documents. Contact system administrator.';
					|it = 'Si è verificata una situazione inattesa durante la creazione dei documenti. Rivolgersi all''amministratore di sistema.';
					|pl = 'Podczas tworzenia dokumentów zaistniała wyjątkowa sytuacja. Skontaktuj się z administratorem systemu.';
					|tr = 'Belgeler oluşturulurken istisna oluştu. Sistem yöneticinize başvur.'");
		Return;
	EndIf;
	DocumentsList.LoadValues(GetFromTempStorage(AddressOfDocuments));
	Items.GroupPages.CurrentPage = Items.PageCreatedDocuments;
	LoadList();
	SetColumnTitleAndListDocuments();
	
EndProcedure


#EndRegion
