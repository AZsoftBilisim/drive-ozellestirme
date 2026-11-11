#Region Variables

&AtClient
Var AmountsOfPaymentsToBeUploaded;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BankAccount = Parameters.BankAccount;
	PaymentDocument = Parameters.PaymentDocument;
	
	FillInInitialValues(BankAccount, PaymentDocument);
	
	FillInPeriodSelectionList_();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateFormOfUploadingPaymentDocumentsListBankFeeds" Then
		
		UpdateListOfAccountsOnServer(False);
		UpgradeBasement();
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBankAccounts

&AtClient
Procedure BankAccountsCheckOnChange(Item)
	
	Object.AccountList.Clear();
	For Each CurLineIsBankAccounts In Object.BankAccounts Do   
		
		If CurLineIsBankAccounts.Check Then
			Object.AccountList.Add(CurLineIsBankAccounts.Ref);
		EndIf;	
		
	EndDo;	
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure BankAccountsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsToExport

&AtClient
Procedure DocumentsToExportSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Field.Name = "DocumentsToExportToExport"
		And Not Field.Name = "DocumentsToExportUploadFormat" Then
		StandardProcessing = False;
		ShowValue(Undefined, Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkAccounts(Command)
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		If Not Account.Downloading Then
			Account.Check = True;
			Object.AccountList.Add(Account.Ref);
		EndIf;
	EndDo;
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure ClearAccounts(Command)
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		If Not Account.Downloading Then
			Account.Check = False;
		EndIf;
	EndDo;
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfAccounts(Command)

	UpdateListOfAccountsOnServer();
	
EndProcedure

&AtClient
Procedure Unload(Command)                              
	
	InformationOnUploadDocuments = DocumentsToBeUploadedForUploading();

	ExportingParameters = New Structure();
	ExportingParameters.Insert("AddressDocumentsToBeUploaded", InformationOnUploadDocuments.AddressOfTableOfMarkedPayments);
	ExportingParameters.Insert("AddressBankAccounts", BankAccountsToDownload());
	ExportingParameters.Insert("UploadIsPerformedWhenSyncing", False);

	If InformationOnUploadDocuments.ListOfPreviouslySentPayments.Count() > 0 Then
		
		InformUserAboutPreviouslySentDocuments(
			InformationOnUploadDocuments.ListOfPreviouslySentPayments);
		
	EndIf;	

		If InformationOnUploadDocuments.ListOfMarkedPaymentsWithoutFormats.Count() > 0 Then
		
		InformUserAboutPaymentsWithoutFormats(
			InformationOnUploadDocuments.ListOfMarkedPaymentsWithoutFormats);
		
	EndIf;	
	
	ExchangeWithBankFeedsServiceClient.UploadPaymentDocuments(ExportingParameters, ThisObject);	                      

EndProcedure

&AtClient
Procedure Notice(Command)
	
	For Each DocumentLine In Object.DocumentsToExport Do
		DocumentLine.ToExport = True;
	EndDo;
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	For Each DocumentLine In Object.DocumentsToExport Do
		DocumentLine.ToExport = False;
	EndDo;
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdatePaymentList();
	UpgradeBasement();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function BankAccountsToDownload()
	
	TableOfMarkedBankAccounts = Object.BankAccounts.Unload(New Structure("Check", True));	
	
	Return PutToTempStorage(TableOfMarkedBankAccounts, UUID);
	
EndFunction

&AtClient
Procedure InformUserAboutPreviouslySentDocuments(ListOfPreviouslySentPayments)
	
	For Each CurrentValue In ListOfPreviouslySentPayments Do
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chứng từ %1 trước đây đã được kết xuất vào dịch vụ. Do đó sẽ không được kết xuất';
				|ru = 'Документ %1, ранее уже выгружался в сервис. Поэтому выгружаться не будет';
				|en = 'The %1 document will not be exported to the service as it was exported before.'; fa = 'The %1 document will not be exported to the service as it was exported before.';
				|it = 'Документ %1, ранее уже выгружался в сервис. Поэтому выгружаться не будет';
				|pl = 'The %1 document will not be exported to the service as it was exported before.';
				|tr = '%1 belgesi daha önce zaten hizmete yüklenmiştir. Bu nedenle dışa aktarılmayacaktır'"),
			CurrentValue.Value);
		CommonClient.MessageToUser(MessageText);
	
	EndDo;
	
EndProcedure 			

&AtClient
Procedure InformUserAboutPaymentsWithoutFormats(ListOfMarkedPaymentsWithoutFormats)
	
	For Each CurrentValue In ListOfMarkedPaymentsWithoutFormats Do
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1, chưa chỉ định mẫu thanh toán. Chứng từ sẽ không được kết xuất';
				|ru = 'У документа %1, не указан шаблон платежа. Документ выгружен не будет';
				|en = 'Payment template is not specified for the %1 document. The document will not be exported'; fa = 'Payment template is not specified for the %1 document. The document will not be exported';
				|it = 'У документа %1, не указан шаблон платежа. Документ выгружен не будет';
				|pl = 'Payment template is not specified for the %1 document. The document will not be exported';
				|tr = '%1 belgesinde ödeme şablonu belirtilmemiş. Belge indirilmeyecektir'"),
			CurrentValue.Value);
		CommonClient.MessageToUser(MessageText);
	
	EndDo;
	
EndProcedure 

&AtServer
Function DocumentsToBeUploadedForUploading()
	
	InformationOnUploadDocuments = New Structure("AddressOfTableOfMarkedPayments,ListOfPreviouslySentPayments,ListOfMarkedPaymentsWithoutFormats");
	
	TableOfMarkedPaymentOrders = Object.DocumentsToExport.Unload(New Structure("ToExport,UploadFormat",
												True, Enums.BankFeedsPaymentMethods.SEPA));	
												
	TableOfMarkedPaymentsWithoutFormats = Object.DocumentsToExport.Unload(New Structure("ToExport,UploadFormat",
												True, Enums.BankFeedsPaymentMethods.EmptyRef()));	
												
	ListOfPreviouslySubmittedDocuments = CheckTableForPreviouslySentDocuments(TableOfMarkedPaymentOrders);
	
	For Each CurrentValue In ListOfPreviouslySubmittedDocuments Do
		
	   TableOfMarkedPaymentOrders.Delete(
	   	TableOfMarkedPaymentOrders.Find(CurrentValue.Value, "Ref"));
		
	EndDo;
	
	InformationOnUploadDocuments.AddressOfTableOfMarkedPayments = 
		PutToTempStorage(TableOfMarkedPaymentOrders, ThisObject.UUID);
		
	InformationOnUploadDocuments.ListOfPreviouslySentPayments = ListOfPreviouslySubmittedDocuments;	
	
	ListOfMarkedPaymentsWithoutFormats = New ValueList(); 
	For Each CurrentValue In TableOfMarkedPaymentsWithoutFormats Do
		
		ListOfMarkedPaymentsWithoutFormats.Add(CurrentValue.Ref);
		
	EndDo;	
	
	InformationOnUploadDocuments.ListOfMarkedPaymentsWithoutFormats = ListOfMarkedPaymentsWithoutFormats;	
	
	Return InformationOnUploadDocuments;
	
EndFunction

&AtServer
Function CheckTableForPreviouslySentDocuments(TableOfMarkedPaymentOrders)
	
	DocumentsArray = New Array();
	For Each TableRow In TableOfMarkedPaymentOrders Do
		DocumentsArray.Add(TableRow.Ref);
	EndDo;	
	
	Query = New Query();
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.Text = 
	"SELECT
	|	BankFeedsTransactionStatuses.Object AS Object
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|WHERE
	|	BankFeedsTransactionStatuses.Object IN(&DocumentsArray)
	|	AND (BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.accepted)
	|			OR BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.processing)
	|			OR BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.unknown)
	|			OR BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.deleted))";
	
	DocumentsList = New ValueList();
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do
		
		DocumentsList.Add(Result.Object);
		
	EndDo;	
	
	Return DocumentsList;
EndFunction

&AtServer
Procedure FillInPeriodSelectionList_()
	
	PeriodSelectionList = Items.Period.ChoiceList;
	
	PeriodSelectionList.Add(NStr("vi = 'Toàn thời gian';
								|ru = 'Все время';
								|en = 'All time'; fa = 'همه زمان‌ها';
								|it = 'Все время';
								|pl = 'Cały czas';
								|tr = 'Tüm zamanlar'"),     NStr("vi = 'Toàn thời gian';
																|ru = 'Все время';
																|en = 'All time'; fa = 'همه زمان‌ها';
																|it = 'Все время';
																|pl = 'Cały czas';
																|tr = 'Tüm zamanlar'"));
	PeriodSelectionList.Add("Date_",                     NStr("vi = 'Ngày...';
																|ru = 'Дату...';
																|en = 'Date ...'; fa = 'Date ...';
																|it = 'Дату...';
																|pl = 'Date ...';
																|tr = 'Tarih...'"));
	PeriodSelectionList.Add(NStr("vi = 'Hôm nay';
								|ru = 'Сегодня';
								|en = 'Today'; fa = 'امروز';
								|it = 'Сегодня';
								|pl = 'Dzisiaj';
								|tr = 'Bugün'"),       NStr("vi = 'Hôm nay';
															|ru = 'Сегодня';
															|en = 'Today'; fa = 'امروز';
															|it = 'Сегодня';
															|pl = 'Dzisiaj';
															|tr = 'Bugün'"));
	PeriodSelectionList.Add(NStr("vi = 'Ba ngày';
								|ru = 'Три дня';
								|en = 'Three days'; fa = 'Three days';
								|it = 'Три дня';
								|pl = 'Trzy dni';
								|tr = 'Üç gün'"),       NStr("vi = 'Ba ngày';
																	|ru = 'Три дня';
																	|en = 'Three days'; fa = 'Three days';
																	|it = 'Три дня';
																	|pl = 'Trzy dni';
																	|tr = 'Üç gün'"));
	PeriodSelectionList.Add(NStr("vi = 'Một tuần';
								|ru = 'Неделю';
								|en = 'Week'; fa = 'هفته';
								|it = 'Неделю';
								|pl = 'Tygodniu';
								|tr = 'Hafta'"),        NStr("vi = 'Một tuần';
															|ru = 'Неделю';
															|en = 'Week'; fa = 'هفته';
															|it = 'Неделю';
															|pl = 'Tygodniu';
															|tr = 'Hafta'"));
	
	// Initial installations
	Period = NStr("vi = 'Toàn thời gian';
					|ru = 'Все время';
					|en = 'All time'; fa = 'همه زمان‌ها';
					|it = 'Все время';
					|pl = 'Cały czas';
					|tr = 'Tüm zamanlar'");
	Object.StartDate = '00010101';
	Object.EndDate = '00010101';
	
EndProcedure

&AtServer
Procedure UpdateListOfAccountsOnServer(FillOutBankAccounts = True)
	
	If FillOutBankAccounts Then
		FillOutBankAccounts();	
	EndIf;	
	
	Object.AccountList.Clear();
	For Each CurLineIsBankAccounts In Object.BankAccounts Do   
		
		If CurLineIsBankAccounts.Check Then
			Object.AccountList.Add(CurLineIsBankAccounts.Ref);
		EndIf;	
		
	EndDo;	
	
	UpdatePaymentList();
	
EndProcedure

&AtServer
Procedure UpdatePaymentList()
	
	FillInPaymentTable(DocumentsFilter);
	
EndProcedure

&AtServer
Procedure FillInInitialValues(BankAccount = Undefined, PaymentDocument = Undefined)
	
	FillOutBankAccounts();	
	
	If ValueIsFilled(BankAccount) Then
		Object.AccountList.Clear();
		
		For Each CurLineIsBankAccounts In Object.BankAccounts Do
			
			If CurLineIsBankAccounts.Ref = BankAccount Then  
				CurLineIsBankAccounts.Check = True;
				Object.AccountList.Add(CurLineIsBankAccounts.Ref);
				Break;
			EndIf;	
			
		EndDo;	
		
	EndIf;	

	UpdatePaymentList();
	
	If ValueIsFilled(PaymentDocument) Then
		
		For Each CurCurrentLineDocumentsToUpload In Object.DocumentsToExport Do
			
			If CurCurrentLineDocumentsToUpload.Ref = PaymentDocument Then  
				CurCurrentLineDocumentsToUpload.ToExport = True;
			EndIf;	
			
		EndDo;	
		
	EndIf;	
	
EndProcedure

&AtServer
Procedure FillInPaymentTable(DocumentsFilter = Undefined)
	
	DocumentsTable = DataProcessors.EDIWithBanksBankFeeds.TableOfDocumentsToUpload(Object.AccountList,
																		Object.StartDate,
																		Object.EndDate,
																		Object.NotExportedOnly);
																		
	FillInInformationAboutCounterparties(DocumentsTable);
	
	Object.DocumentsToExport.Load(DocumentsTable);
	Object.DocumentsToExport.Sort("Date");

	SepaFormatTable = Object.BankAccounts.Unload(New Structure("PaymentMethodByIBAN", 
															Enums.BankFeedsPaymentMethods.SEPA));	
	ListOfBankAccounts = New ValueList();
	For Each CurRowTableOfSepaFormat In SepaFormatTable Do
		
		ListOfBankAccounts.Add(CurRowTableOfSepaFormat.Ref);	
		
	EndDo;
	
	If DocumentsFilter <> Undefined Then
		For Each DocumentForExport In Object.DocumentsToExport Do
		
			Filter = New Structure("Ref", DocumentForExport.Ref);
			FoundRows = DocumentsFilter.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				DocumentForExport.ToExport = False;
			EndIf;

			If ListOfBankAccounts.FindByValue(DocumentForExport.BankAccount) <> Undefined Then	
				 DocumentForExport.UploadFormat = Enums.BankFeedsPaymentMethods.SEPA;
			EndIf;	 
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInInformationAboutCounterparties(PaymentTable_3)

	DocumentsArray = PaymentTable_3.UnloadColumn("Ref");
	CounterpartyData_ = CashServer.InformationAboutRecipientPayerAccordingToDocuments(DocumentsArray);
	
	For Each TableRow In PaymentTable_3 Do
		
		DataProcessors.EDIWithBanksBankFeeds.FillInCounterpartyDetails(CounterpartyData_,
														TableRow.CounterpartyName,
														TableRow.Ref,
														0);
		DataProcessors.EDIWithBanksBankFeeds.FillInCounterpartyDetails(CounterpartyData_,
														TableRow.RecipientCRTR,
														TableRow.Ref,
														1);
		
	EndDo;

EndProcedure

&AtServer
Procedure FillOutBankAccounts()

	Query = New Query();
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.Organization AS Organization,
	|	ConnectionsToBankFeedsBanks.Bank AS Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	CompaniesBankAccounts.Ref AS Ref,
	|	CompaniesBankAccounts.AccountNumber AS AccountNumber,
	|	CompaniesBankAccounts.Ref AS BankAccount,
	|	ConnectionsToBankFeedsBanks.PaymentMethodByIBAN AS PaymentMethodByIBAN,
	|	ConnectionsToBankFeedsBanks.PaymentMethodByBBAN AS PaymentMethodByBBAN
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Bank
	|		AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ConnectionsToBankFeedsBanks.Organization,
	|	ConnectionsToBankFeedsBanks.Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings,
	|	CompaniesBankAccounts.Ref,
	|	CompaniesBankAccounts.AccountNumber,
	|	CompaniesBankAccounts.Ref,
	|	ConnectionsToBankFeedsBanks.PaymentMethodByIBAN,
	|	ConnectionsToBankFeedsBanks.PaymentMethodByBBAN
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Ref
	|		AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"";
	
	ConnectedBankAccounts = Query.Execute().Unload();
	
	Object.BankAccounts.Load(ConnectedBankAccounts);
	
EndProcedure	

&AtClient
Procedure UpgradeBasement()
	
	AmountsOfPaymentsToBeUploaded.Clear();
	
	SelectingRowsToUpload = New Structure("ToExport", True);
	LinesToUpload = Object.DocumentsToExport.FindRows(SelectingRowsToUpload);
	
	QuantityToBeUnloaded = LinesToUpload.Count();
	
	For Each String In LinesToUpload Do
		AmountByPayments = AmountsOfPaymentsToBeUploaded.Get(String.Currency);
		If AmountByPayments = Undefined Then
			AmountsOfPaymentsToBeUploaded.Insert(String.Currency, String.Sum);
		Else
			AmountsOfPaymentsToBeUploaded.Insert(String.Currency, AmountByPayments + String.Sum);
		EndIf;
	EndDo;
	GenerateLineForAmountToUpload();
	
EndProcedure

&AtClient
Procedure GenerateLineForAmountToUpload()
	
	AmountToExport = "";
	If AmountsOfPaymentsToBeUploaded.Count() Then
		For Each AmountByPayments In AmountsOfPaymentsToBeUploaded Do
			If ValueIsFilled(AmountByPayments.Value) Then
				AmountToExport = AmountToExport + Format(AmountByPayments.Value, "NFD=2") + " " 
																			+ String(AmountByPayments.Key) + ", ";
			EndIf;
		EndDo;
		AmountToExport = Left(AmountToExport, StrLen(AmountToExport) - 2);
		AmountToExport = NStr("vi = 'Số tiền:';
								|ru = 'На сумму:';
								|en = 'Amount:'; fa = 'مبلغ:';
								|it = 'На сумму:';
								|pl = 'Na ilość:';
								|tr = 'Tutar:'") + " " + ?(AmountToExport = "", "-", AmountToExport);
	Else
		AmountToExport = NStr("vi = 'Số tiền: -';
								|ru = 'На сумму: -';
								|en = 'Amount:-'; fa = 'Amount:-';
								|it = 'На сумму: -';
								|pl = 'Na sumę: -';
								|tr = 'Tutar: -'")
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	LocalCurDate = ExchangeWithBankFeedsServiceServerCall.LocalCurDate();
	
	If Period = NStr("vi = 'Toàn thời gian';
					|ru = 'Все время';
					|en = 'All time'; fa = 'همه زمان‌ها';
					|it = 'Все время';
					|pl = 'Cały czas';
					|tr = 'Tüm zamanlar'") Then
		
		Object.StartDate  = '00010101';
		Object.EndDate   = '00010101';
		
	ElsIf Period = "PerDate" Then
		
		Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisForm, );
		ShowInputDate(Notification, LocalCurDate, NStr("vi = 'Ngày lọc thanh toán';
														|ru = 'Дата отбора платежей';
														|en = 'Payment filter date'; fa = 'Payment filter date';
														|it = 'Дата отбора платежей';
														|pl = 'Data wyboru płatności';
														|tr = 'Ödeme filtresi tarihi'"), DateFractions.Date);
		Return;
		
	ElsIf TypeOf(Period) = Type("Date") Then
		
		Object.StartDate  = Period;
		If ValueIsFilled(Period) Then
			Object.EndDate   = EndOfDay(Period);
		Else
			Object.EndDate   = Period;
		EndIf;
		
	ElsIf Period = NStr("vi = 'Hôm nay';
						|ru = 'Сегодня';
						|en = 'Today'; fa = 'امروز';
						|it = 'Сегодня';
						|pl = 'Dzisiaj';
						|tr = 'Bugün'") Then
		
		Object.StartDate  = LocalCurDate;
		Object.EndDate   = EndOfDay(LocalCurDate);
		
	ElsIf Period = NStr("vi = 'Ba ngày';
						|ru = 'Три дня';
						|en = 'Three days'; fa = 'Three days';
						|it = 'Три дня';
						|pl = 'Trzy dni';
						|tr = 'Üç gün'") Then
		
		Object.StartDate  = LocalCurDate - 3 * 24 * 3600;
		Object.EndDate   = EndOfDay(LocalCurDate);
		
	ElsIf Period = NStr("vi = 'Một tuần';
						|ru = 'Неделю';
						|en = 'Week'; fa = 'هفته';
						|it = 'Неделю';
						|pl = 'Tygodniu';
						|tr = 'Hafta'") Then
		
		Object.StartDate  = LocalCurDate - 7 * 24 * 3600;
		Object.EndDate   = EndOfDay(LocalCurDate);
		
	EndIf;
	
	PeriodForChangesOnServer();
	
	UpgradeBasement();
	
EndProcedure

&AtServer
Procedure PeriodForChangesOnServer()
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure PeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = "Date_" Then
		
		StandardProcessing = False;
		
		Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisObject);
		
		NoteText = NStr("vi = 'Chọn ngày của chứng từ được kết xuất';
						|ru = 'Выберите дату выгружаемых документов';
						|en = 'Select the date of exported documents'; fa = 'Select the date of exported documents';
						|it = 'Выберите дату выгружаемых документов';
						|pl = 'Wybierz datę przesyłania dokumentów';
						|tr = 'Dışa aktarılan belgelerin tarihini seçin'") + " ";
		OpenForm(
			"CommonForm.SelectDate",
			New Structure("NoteText, InitialValue", NoteText),
			,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
			
	ElsIf TypeOf(ValueSelected) <> Type("Date") Then
		
		Array = New Array;
		Array.Add(Type("String"));
		TypesDetailsDate = New TypeDescription(Array, , );
		
		Item.TypeRestriction = TypesDetailsDate;
		
		Item.ChoiceButton = False;
		Item.TextEdit = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotExportedOnlyOnChange(Item)
	
	Object.NotExportedOnly = (NotExportedOnly = 1);
	
	UpdatePaymentList();
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure DocumentsToExportToExportOnChange(Item)
	
	CurrentData = Items.DocumentsToExport.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Character = ?(CurrentData.ToExport, 1, -1);
	
	QuantityToBeUnloaded = QuantityToBeUnloaded + 1 * Character;
	
	AmountByPayments = AmountsOfPaymentsToBeUploaded.Get(CurrentData.Currency);
	If AmountByPayments = Undefined Then
		AmountsOfPaymentsToBeUploaded.Insert(CurrentData.Currency, CurrentData.Sum);
	Else
		AmountsOfPaymentsToBeUploaded.Insert(CurrentData.Currency, AmountByPayments + CurrentData.Sum * Character);
	EndIf;
	GenerateLineForAmountToUpload();
	
	Filter = New Structure("Ref", CurrentData.Ref);
	FoundRows = DocumentsFilter.FindRows(Filter);
	
	If CurrentData.ToExport And FoundRows.Count() = 0 Then
		NewLineOfDocument = DocumentsFilter.Add();
		NewLineOfDocument.Ref = CurrentData.Ref;
	ElsIf Not CurrentData.ToExport And Not FoundRows.Count() = 0 Then
		For Each FoundRow In FoundRows Do 
			DocumentsFilter.Delete(FoundRow);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClosingPaymentConfirmationFormInSaltEdge(Result, AdditionalParameters) Export
	
	ExchangeWithBankFeedsServiceClient.CheckStatusOfPaymentsAfterSending(ThisObject);	
	
EndProcedure	

&AtClient
Procedure ExecuteAfterSelectingDate(SelectedDate, Var_Parameters) Export
	
	LocalCurDate = ExchangeWithBankFeedsServiceServerCall.LocalCurDate();
	
	If ValueIsFilled(SelectedDate) Then
		
		Object.StartDate  = BegOfDay(SelectedDate);
		Object.EndDate   = EndOfDay(SelectedDate);
		Period = SelectedDate;
		
		Array = New Array;
		Array.Add(Type("Date"));
		TypesDetailsDate = New TypeDescription(Array, , );
		
		Items.Period.TypeRestriction = TypesDetailsDate;
		
		Items.Period.ChoiceButton = True;
		Items.Period.TextEdit = True;
	Else
		
		If TypeOf(Period) = Type("Date") Then
			Return;
		EndIf;
		
		If Object.StartDate  = '00010101' And Object.EndDate = '00010101' Then
			Period = NStr("vi = 'Toàn thời gian';
							|ru = 'Все время';
							|en = 'All time'; fa = 'همه زمان‌ها';
							|it = 'Все время';
							|pl = 'Cały czas';
							|tr = 'Tüm zamanlar'");
		ElsIf Object.StartDate = BegOfDay(LocalCurDate)
			And Object.EndDate = EndOfDay(LocalCurDate) Then
			Period = NStr("vi = 'Hôm nay';
							|ru = 'Сегодня';
							|en = 'Today'; fa = 'امروز';
							|it = 'Сегодня';
							|pl = 'Dzisiaj';
							|tr = 'Bugün'");
		ElsIf Object.StartDate = BegOfDay(LocalCurDate) - 3 * 24 * 3600
			And Object.DateEndDate = EndOfDay(LocalCurDate) Then
			Period = NStr("vi = 'Ba ngày';
							|ru = 'Три дня';
							|en = 'Three days'; fa = 'Three days';
							|it = 'Три дня';
							|pl = 'Trzy dni';
							|tr = 'Üç gün'");
		ElsIf Object.StartDate = BegOfDay(LocalCurDate) - 7 * 24 * 3600
			And Object.DateEndDate = EndOfDay(LocalCurDate) Then
			Period = NStr("vi = 'Một tuần';
							|ru = 'Неделю';
							|en = 'Week'; fa = 'هفته';
							|it = 'Неделю';
							|pl = 'Tygodniu';
							|tr = 'Hafta'");
		EndIf;
	EndIf;
	
	PeriodForChangesOnServer();
	
	UpgradeBasement();
	
EndProcedure


AmountsOfPaymentsToBeUploaded = New Map;

#EndRegion
