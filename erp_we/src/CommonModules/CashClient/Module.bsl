
#Region Internal

// Creates a payment document for one or more requests for spending money.
//
// Parameters:
//	ReferencesArrray - Array of AnyRef - links to the selected objects that the command is running on.
//	DocumentName - String - name of the document in the metadata that will be created based on requests.
//
Procedure CreatePaymentDocumentBasedOnCashExpenseRequests(ReferencesArrray, DocumentName) Export
	
	PaymentMethod = "";
	If DocumentName = "BankAccountIssue" Then
		PaymentMethod = "BankAccountPayment";
	ElsIf DocumentName = "CashVoucher" Then
		PaymentMethod = "CashAccountPayment_";
	EndIf;
	
	ClearMessages();
	
	PaymentAllocation = Undefined;
	If CashServerCall.GeneratePaymentFillingData(ReferencesArrray, PaymentMethod, PaymentAllocation) Then
		
		If DocumentName = "PaymentCardTransaction" Then
			OpenForm("Document.PaymentCardTransaction.ObjectForm", New Structure("Basis", ReferencesArrray[0]));
		Else
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("DocumentBasis",                     ReferencesArrray);
			AdditionalParameters.Insert("MultipleSpendingRequests",  ReferencesArrray.Count() > 1);
			AdditionalParameters.Insert("DocumentName",                          DocumentName);
			AdditionalParameters.Insert("PaymentMethod",                           PaymentMethod);
			
			Notification = New CallbackDescription("ExecuteAfterSelectingCheckoutBankAccount", ThisObject, AdditionalParameters);
			
			If PaymentAllocation.Count() > 1 Then
				
				If DocumentName = "BankAccountIssue"
					And CashServerCall.ListOfIndividualsOnPaymentRequests(ReferencesArrray) Then
					RunCallback(Notification, New Structure("BankAccountCashAccount, Sum", Undefined, 0));
				Else
					AdditionalParameters.Insert("CloseOnChoice", True);
					OpenForm("Document.PaymentRequest.Form.PaymentAllocation", AdditionalParameters,,,,,
						Notification, FormWindowOpeningMode.LockOwnerWindow);
				EndIf;
			
			ElsIf PaymentAllocation.Count() = 1 Then
				RunCallback(Notification,
					New Structure("BankAccountCashAccount, Sum", PaymentAllocation[0].BankAccountCashAccount, PaymentAllocation[0].Sum));
			Else
				RunCallback(Notification, New Structure("BankAccountCashAccount, Sum", Undefined, 0));
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteAfterSelectingCheckoutBankAccount(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		FormName = "Document." + AdditionalParameters.DocumentName + ".ObjectForm";
		AdditionalParameters.Insert("BankAccountCashAccount", Result.BankAccountCashAccount);
		AdditionalParameters.Insert("Sum", Result.Sum);
		OpenForm(FormName, New Structure("Basis", AdditionalParameters));
	EndIf;
	
EndProcedure

// Creates payment documents based on the selected payment schedule lines
//
// Parameters:
//    FormItem - FormTable - Element with selected lines of the payment schedule
//    DocumentType - String - The type of document to create. If omitted, it is detected automatically.
//
Procedure PayChartLines(FormItem, DocumentType = "") Export
	
	GraphLines = FormItem.SelectedRows;
	If GraphLines.Count() Then
		Result = CashServerCall.PayChartLines(GraphLines, DocumentType);
		OpenPaymentResultsForChartLines(FormItem, Result);
	EndIf;
	
EndProcedure

// Opens the create assistant form if multiple documents have been created, or a single document form.
//
// Parameters:
//    FormItem - FormTable - Element with selected lines of the payment schedule
//    Result - Structure - The result is the creation of payment documents.
//
Procedure OpenPaymentResultsForChartLines(FormItem, Result) Export
	
	Notification = New CallbackDescription("PaymentForScheduleLinesCompletion", ThisObject, FormItem);
	
	If CashClientLocalization.OpenPaymentResultsForChartLines(FormItem, Result, Notification) Then
		Return;
	EndIf;
	
	If Result.OpenAssistantForm Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FormItem", FormItem);
		NotificationResult = New CallbackDescription("WhenCompletingCreationOfPaymentDocuments", ThisObject, AdditionalParameters);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
		IdleParameters.Insert("MessageText", NStr("vi = 'Tạo chứng từ thanh toán ...';
													|ru = 'Создание платежных документов...';
													|en = 'Create payment documents...'; fa = 'Create payment documents...';
													|it = 'Creazione dei documenti di pagamento...';
													|pl = 'Tworzenie dokumentów płatniczych...';
													|tr = 'Ödeme belgelerinin oluşturulması...'"));
		IdleParameters.Insert("OutputProgressBar", True);
		
		TimeConsumingOperationsClient.WaitCompletion(Result.TimeConsumingOperation, NotificationResult, IdleParameters);
	Else
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("Basis", Result.DocumentToCreate.FillingData);
		
		OpenForm("Document." + Result.DocumentToCreate.DocumentType + ".ObjectForm",
			ParametersStructure1,
			FormItem);
	EndIf;
	
EndProcedure

Procedure WhenCompletingCreationOfPaymentDocuments(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.MessageToUser(Result.BriefErrorDescription);
		Return;
	ElsIf Result.Status = "Completed2" Then
		OpenForm("CommonForm.PaymentDocumentGenerationWizard",,
			AdditionalParameters.FormItem,,,,
			New CallbackDescription("PaymentForScheduleLinesCompletion", ThisObject, AdditionalParameters.FormItem),
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

// Processing the completion of document generation for payment schedule lines
// 
//  Parameters:
//     Result - Boolean - Indicates successful completion on the server
//     FormItem - FormTable - The form element, which was initiated by the procedure of formation documents
//
Procedure PaymentForScheduleLinesCompletion(Result, FormItem) Export
	
	If Result <> Undefined And Result Then
		FormItem.Refresh();
		Notify("PaymentScheduleLinesPaid",, FormItem);
	EndIf;
	
EndProcedure

// Calculates the date of the advance report
//
// Parameters:
//    ExpenseReportPeriod - String, Date - User-selected method of determining the date
//    Date - Date - Date of advance payment
//
// Returns:
//    Date - Date of the advance report
//
Function RecalculateAdvanceReportDate(ExpenseReportPeriod, Date) Export
	
	ExpenseReportDate = Undefined;
	
	If ExpenseReportPeriod = NStr("vi = 'Trong một tuần';
									|ru = 'Через неделю';
									|en = 'In a week'; fa = 'In a week';
									|it = 'Tra una settimana';
									|pl = 'Za tydzień';
									|tr = 'Bir hafta sonra'") Then
		ExpenseReportDate = ?(ValueIsFilled(Date), Date, CurrentDate()) + 7 * 24 * 3600;
		
	ElsIf ExpenseReportPeriod = NStr("vi = 'Trong hai tuần';
									|ru = 'Через две недели';
									|en = 'In two weeks'; fa = 'In two weeks';
									|it = 'Tra due settimane';
									|pl = 'Za dwa tygodni';
									|tr = 'İki hafta sonra'") Then
		ExpenseReportDate = ?(ValueIsFilled(Date), Date, CurrentDate()) + 14 * 24 * 3600;
		
	ElsIf ExpenseReportPeriod = NStr("vi = 'Qua tháng';
									|ru = 'Через месяц';
									|en = 'In a month'; fa = 'In a month';
									|it = 'Tra un mese';
									|pl = 'Za miesiąc';
									|tr = 'Bir ay sonra'") Then
		ExpenseReportDate = ?(ValueIsFilled(Date), Date, CurrentDate()) + 30 * 24 * 3600;
		
	ElsIf TypeOf(ExpenseReportPeriod) = Type("Date") Then
		If ExpenseReportPeriod < Date Then
			ExpenseReportPeriod = Date;
		EndIf;
		
		ExpenseReportDate = ExpenseReportPeriod;
	EndIf;
	
	Return ExpenseReportDate;
	
EndFunction

Procedure ExpenseReportPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing, Form, Date, NotificationForms) Export
	
	If ValueSelected = "TillDate" Then
		
		StandardProcessing = False;
		Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisObject,
			New Structure("Form, Date, NotificationForms", Form, Date, NotificationForms));
		NoteText = NStr("vi = 'Chọn ngày của báo cáo về khoản tạm ứng đã chi';
						|ru = 'Выберите дату отчета по выдаваемому авансу';
						|en = 'Select a report date for the issued advance'; fa = 'Select a report date for the issued advance';
						|it = 'Selezionare la data del rendiconto per il pagamento anticipato';
						|pl = 'Wybierz datę raportu dla wypłacanej zaliczki.';
						|tr = 'Verilen avans raporunun tarihini seç'") + " ";
		OpenForm("CommonForm.SelectDate",
			New Structure("NoteText, InitialValue", NoteText),,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
			
	ElsIf TypeOf(ValueSelected) <> Type("Date") Then
		
		Item.TypeRestriction = New TypeDescription("String");
		Item.ChoiceButton = False;
		Item.TextEdit = False;
	EndIf;
	
EndProcedure

Procedure ExecuteAfterSelectingDate(SelectedDate, Parameters) Export
	
	Form = Parameters.Form; // ClientApplicationForm
	Object = Form.Object;
	Items = Form.Items;
	Date = Parameters.Date;
	
	If ValueIsFilled(SelectedDate) Then
		
		If SelectedDate < Date Then
			SelectedDate = Date;
		EndIf;
		
		Object.ExpenseReportDate = SelectedDate;
		Form.ExpenseReportPeriod = SelectedDate;
		
		Items.ExpenseReportPeriod.TypeRestriction = New TypeDescription("Date");
		Items.ExpenseReportPeriod.ChoiceButton = True;
		Items.ExpenseReportPeriod.TextEdit = True;
	Else
		
		If TypeOf(Form.ExpenseReportPeriod) = Type("Date") Then
			Return;
		EndIf;
		
		If Object.ExpenseReportDate = CurrentDate() + 7 * 24 * 3600 Then
			Form.ExpenseReportPeriod = NStr("vi = 'Trong một tuần';
											|ru = 'Через неделю';
											|en = 'In a week'; fa = 'In a week';
											|it = 'Tra una settimana';
											|pl = 'Za tydzień';
											|tr = 'Bir hafta sonra'");
		ElsIf Object.ExpenseReportDate = CurrentDate() + 14 * 24 * 3600 Then
			Form.ExpenseReportPeriod = NStr("vi = 'Trong hai tuần';
											|ru = 'Через две недели';
											|en = 'In two weeks'; fa = 'In two weeks';
											|it = 'Tra due settimane';
											|pl = 'Za dwa tygodni';
											|tr = 'İki hafta sonra'");
		ElsIf Object.ExpenseReportDate = AddMonth(CurrentDate(), 1) Then
			Form.ExpenseReportPeriod = NStr("vi = 'Trong một tháng';
											|ru = 'Через месяц';
											|en = 'In a month'; fa = 'In a month';
											|it = 'Tra un mese';
											|pl = 'Za miesiąc';
											|tr = 'Bir ay sonra'");
		EndIf;
	EndIf;
	
	RunCallback(Parameters.NotificationForms);
	
EndProcedure

// Sets the availability of editing the "Settlement amount" column in the "Payment Decryption" tabular part
// 
// Parameters:
//  Form - ClientApplicationForm - the form on which the "Settlement amount" column is located
//  DocumentCurrency - CatalogRef.Currencies - the current currency of the object
//
Procedure SetAvailabilityOfPaymentDecryptionItemAmountOfSettlements(Form, DocumentCurrency) Export

	TablePartCell = Form.Items.ARAPDetails.CurrentItem;
	
	If TablePartCell = Undefined Then
		Return;
	EndIf;
	
	If TablePartCell.Name <> "ARAPDetailsAmountARAP" Then
		Return;
	EndIf;
	
	LineOfATabularSection = Form.Items.ARAPDetails.CurrentData;
	
	If LineOfATabularSection <> Undefined Then
		TablePartCell.ReadOnly = LineOfATabularSection.ARAPCurrency = DocumentCurrency;
	EndIf;

EndProcedure

// Starts re-checking advance reports with incorrect advance offset rates
// 
// Parameters:
// 	Parameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
// Returns:
//	Boolean - to call a function using the Calculate method
Function Perform_VerificationOfCreditCoursesInAdvanceReports(Parameters) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompanyArray", Parameters.CompanyArray);
	ExecutionParameters.Insert("BeginOfPeriod", BegOfMonth(Parameters.Period));
	ExecutionParameters.Insert("EndOfPeriod", EndOfMonth(Parameters.Period));
	
	TimeConsumingOperation = CashServerCall.Perform_VerificationOfCreditCoursesInAdvanceReports(ExecutionParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	Notification = New CallbackDescription(
		"AtEndPerform_CheckOfCreditCoursesInAdvanceReports", ThisObject, Parameters.CompletionHandler);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification, IdleParameters);

	Return True;
	
EndFunction

Procedure AtEndPerform_CheckOfCreditCoursesInAdvanceReports(Result, AdditionalParameters) Export
	
	If Result = Undefined Then // The user canceled the task.
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If TypeOf(AdditionalParameters) = Type("CallbackDescription") Then
		RunCallback(AdditionalParameters);
	EndIf;
	
EndProcedure

// Returns a description of the notification after changing the mark for deleting a non-cash payment document for the list of non-cash payments.
// 
// Parameters:
//  Source - FormTable - event source.
// 
// Returns:
//  CallbackDescription - Notification to the list of non-cash payments after changing the deletion mark.
//
Function NotificationToListOfNonCashPaymentsAfterChangingDeletionMark(Source) Export

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Source", Source);
	
	Notification = New CallbackDescription(
		"ChangeDeletionMarkInListOfNonCashPaymentsEnd",
		ThisObject,
		AdditionalParameters);
	
	Return Notification;

EndFunction

// Performs an alert to the processing of the non-cash payment document log when the deletion mark of the payment document changes.
// 
// Parameters:
//  Result - DialogReturnCode - The result of the question.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure ChangeDeletionMarkInListOfNonCashPaymentsEnd(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		Notify("Write_DocumentPayments", , AdditionalParameters.Source);
	EndIf;

EndProcedure

// fills in the article of the cash Register Recorded in the tabular part of the document.
// 
// Parameters:
//  Form - ClientApplicationForm - the Cur Form of the document.
//  FormTable - FormTable - the Form element associated with the table part.
//  TabularSectionName - String - name of the table part.
//
Procedure FillInCashFlowItem(Form, FormTable, TabularSectionName) Export

	RowsSelected = FormTable.SelectedRows;
	
	If RowsSelected.Count() = 0 Then
		
		MessageText = StrTemplate(NStr("vi = 'Trong bảng ""%1"" chưa chọn bất kỳ dòng nào để điền ';
										|ru = 'В таблице ""%1"" не выбрано ни одной строки для заполнения';
										|en = 'In the ""%1"" table, no row is selected for filling'; fa = 'In the ""%1"" table, no row is selected for filling';
										|it = 'В таблице ""%1"" не выбрано ни одной строки для заполнения';
										|pl = 'In the ""%1"" table, no row is selected for filling';
										|tr = '""%1"" tablosunda doldurulacak hiç bir satır seçilmedi'"),
									FormTable.Title);
		CommonClient.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("BusinessOperation", Form.Object.BusinessOperation);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("CurrentRow", 0);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Form", Form);
	NotificationParameters.Insert("FormTable", FormTable);
	NotificationParameters.Insert("TabularSectionName", TabularSectionName);
	
	CallbackOnCompletion = New CallbackDescription("FillInCashFlowItemCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Catalog.CashFlowReportItems.ChoiceForm", FormParameters, Form, , , , CallbackOnCompletion);

EndProcedure

// fill in the cash RegisterRecorded item End.
// 
// Parameters:
//  ClosingResult - CatalogRef.CashFlowReportItems, Undefined - the result of selecting an article in the Catalog.
//  Parameters - Structure:
//   * Form - ClientApplicationForm - the Cur Form of the document.
//   * FormTable - FormTable - the Form element associated with the table part.
//   * TabularSectionName - String - name of the table part.
//
Procedure FillInCashFlowItemCompletion(ClosingResult, Parameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	RowsSelected = Parameters.FormTable.SelectedRows;
	
	For Each RowID In RowsSelected Do
		
		LineOfATabularSection = Parameters.Form.Object[Parameters.TabularSectionName].FindByID(RowID);
		LineOfATabularSection.CashFlowItem = ClosingResult;
		
	EndDo;

EndProcedure

// Sets the editing availability of the Contract cell in the "Payment Decryption" tabular section
//
// Parameters:
//  Form - ClientApplicationForm - The Form on which the tabular part "Decryption of payment" with the column "Contract" is located.
//
Procedure SetAvailabilityOfPaymentDecryptionContractElement(Form) Export

	Object = Form.Object; // FormDataStructure
	TablePartCell = Form.Items.ARAPDetails.CurrentItem;
	
	If TablePartCell = Undefined Then
		Return;
	EndIf;
	
	If TablePartCell.Name <> "ARAPDetailsContract" Then
		Return;
	EndIf;
	
	LineOfATabularSection = Form.Items.ARAPDetails.CurrentData;
	
	If LineOfATabularSection = Undefined Then
		Return;
	EndIf;
	
	TablePartCell.ReadOnly = True;

EndProcedure

// Opens the Form of a new refund Contract in the payment documents.
//
// Parameters:
//  Form  - ClientApplicationForm - The Form of the document in which the creation of the return Contract is performed.
//  CurrentItem - FormField - the field in which the Form for creating a refund Contract is opened.
//
Procedure OpenCreationOfRefundContract(Form, CurrentItem) Export

	Object = Form.Object; // FormDataStructure
	Items = Form.Items;
	
	Filter = New Structure;
		
	If ValueIsFilled(Items.ARAPDetails.CurrentData.ARAPCurrency) Then
		Filter.Insert("ARAPCurrency", Items.ARAPDetails.CurrentData.ARAPCurrency);
	EndIf;
	
	FormPath = "";
	
	If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany")
		Or Object.BusinessOperation = 
			PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Then
		
		FormPath = "Catalog.IntercompanyContracts.ObjectForm";
		
		If TypeOf(Object.Ref) = Type("DocumentRef.CashVoucher")
			Or TypeOf(Object.Ref) = Type("DocumentRef.BankAccountIssue")
			Or TypeOf(Object.Ref) = Type("DocumentRef.PaymentRequest") Then
			
			Filter.Insert("Organization", Object.Organization);
			
			If Object.Property("CompanyRecipient") Then
				Filter.Insert("CompanyRecipient", Object.CompanyRecipient);
			Else
				Filter.Insert("CompanyRecipient", Form.CompanyRecipient);
			EndIf;
			
		Else
			
			Filter.Insert("Organization", Form.CompanyPayer);
			Filter.Insert("CompanyRecipient", Object.Organization);
			
		EndIf;
		
	Else
		
		FormPath = "Catalog.CounterpartyContracts.ObjectForm";
		
		Filter.Insert("Organization", Object.Organization);
		Filter.Insert("Counterparty", Object.Counterparty);
		
		If ValueIsFilled(Items.ARAPDetails.CurrentData.Partner) Then
			Filter.Insert("Partner", Items.ARAPDetails.CurrentData.Partner);
		EndIf;
		
		If TypeOf(Object.Ref) = Type("DocumentRef.CashVoucher")
			Or TypeOf(Object.Ref) = Type("DocumentRef.BankAccountIssue")
			Or TypeOf(Object.Ref) = Type("DocumentRef.PaymentRequest") Then
			Filter.Insert(
				"DefaultBusinessTransaction",
				PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
		Else
			Filter.Insert(
				"DefaultBusinessTransaction",
				PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", Filter);
	FormParameters.Insert("VerificationWhenCreatingContract", True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DocumentObject", Object);
	
	CompletionHandler = New CallbackDescription(
		"OpenCreationOfRefundContractCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(FormPath, FormParameters, CurrentItem, , , , CompletionHandler);

EndProcedure

// Fills in the return Contract field in the Form where the Contract creation window was called.
//
// Parameters:
//  ClosingResult - Undefined - closing result
//  AdditionalParameters - Structure of KeyAndValue - closing parameters.
//
Procedure OpenCreationOfRefundContractCompletion(ClosingResult, AdditionalParameters) Export

	If AdditionalParameters.Property("Contract") Then
		
		Object = AdditionalParameters.DocumentObject;
		Object.Contract = AdditionalParameters.Contract;
		
	EndIf;

EndProcedure

#EndRegion
