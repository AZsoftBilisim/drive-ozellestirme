
#Region Public

// The procedure is received by the Bank at the specified BIC or correspondent account.
//
// Parameters:
//	Form - ClientApplicationForm - Current form
//	Item - FormField - Field where the value is selected.
//	Value - String - The value selected in the field.
//	ListOfBanks - ValueList - List of found banks
//	Bank - CatalogRef.BankClassifier - Value of the field for specifying the Bank.
//
Procedure GetBankDetails(Form, Item, Value, ListOfBanks, Bank) Export

	// If a list of banks is returned, we will select a bank from the list.
	If ListOfBanks.Count() > 1 Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("Bank", Bank);
		DescriptionOfSelectionNotificationFromList = New CallbackDescription("SelectingBankFromEndList", ThisObject, AdditionalParameters);
		Form.ShowChooseFromList(DescriptionOfSelectionNotificationFromList, ListOfBanks, Item);
		
	ElsIf ListOfBanks.Count() = 0 Then
		
		If Not IsBlankString(Value) Then
			
			ListOfAnswersToQuestion = New ValueList;
			ListOfAnswersToQuestion.Add("ChooseFromList", NStr("vi = 'Chọn từ danh sách';
																|ru = 'Выбрать из списка';
																|en = 'Select from list'; fa = 'Select from list';
																|it = 'Selezionare dall''elenco';
																|pl = 'Wybierz z listy';
																|tr = 'Listeden seç'"));
			ListOfAnswersToQuestion.Add("CancelInput", NStr("vi = 'Hủy bỏ việc nhập';
															|ru = 'Отменить ввод';
															|en = 'Cancel input'; fa = 'Cancel input';
															|it = 'Annullare l''immissione';
															|pl = 'Anuluj wprowadzanie';
															|tr = 'Girişi iptal et'"));
			
			QueryText = NStr("vi = 'Không tìm thấy ngân hàng có mã ngân hàng %Value% trong phân loại ngân hàng.';
							|ru = 'Банк с БИК %Value% не найден в классификаторе банков.';
							|en = 'Bank with bank code %Value% is not found in the bank classifier.'; fa = 'Bank with bank code %Value% is not found in the bank classifier.';
							|it = 'Banca con BIC %Value% non trovato nel classificatore delle banche.';
							|pl = 'Bank z BIC %Value% nie został znaleziony w klasyfikatorze banków.';
							|tr = 'Banka BIC %Value% banka sınıflandırıcısında bulunmadı.'");
			QueryText = StrReplace(QueryText,"%Value%", Value);
			
			CallbackDescription = New CallbackDescription(
				"GetBankDetailsCompletion",
				ThisObject,
				New Structure("FormItem, Form", Item, Form));
			ShowQueryBox(CallbackDescription, QueryText, ListOfAnswersToQuestion, 0, , NStr("vi = 'Lựa chọn ngân hàng trong bảng mã hiệu';
																							|ru = 'Выбор банка из классификатора';
																							|en = 'Select bank from classifier'; fa = 'Select bank from classifier';
																							|it = 'Scelta della banca dal classificatore';
																							|pl = 'Wybór banku z klasyfikatora';
																							|tr = 'Sınıflandırıcıdan banka seçimi'"));
			
		Else
			Result = "ChooseFromList";
			GetBankDetailsCompletion(Result, New Structure("FormItem, Form", Item, Form));
		EndIf;
	EndIf;
	
EndProcedure

Procedure SelectingBankFromEndList(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		AdditionalParameters.Bank = SelectedElement.Value;
	EndIf;
	
EndProcedure

Procedure GetBankDetailsCompletion(QuestionResult, AdditionalParameters) Export

	Item = AdditionalParameters.FormItem;
	Form = AdditionalParameters.Form;
	
	Response = QuestionResult;
	
	If Response = "CancelInput" Then
		Form[Item.Name] = "";
	ElsIf Response = "ChooseFromList" Then
		ParametersStructure = New Structure;
		OpenForm("Catalog.BankClassifier.Form.ChoiceForm", , Item);
	EndIf;

EndProcedure

// The procedure outputs messages to the user if the filling on the basis
// was not completed.
//
// Parameters:
//	Object - FormDataCollection - Current object
//	Basis - DocumentRef - document Foundation.
//
Procedure CheckDocumentCompletionBasedOn(Object, Basis) Export
	
	If ValueIsFilled(Basis) And Object.DocumentAmount = 0 Then
		
		Text = "";
		BasisType = TypeOf(Basis);
		If BasisType = Type("DocumentRef.CustomerCommercialInvoice") Then
			Text = NStr("vi = 'Số dư công nợ theo tài khoản ""%1"" bằng 0. Hãy chỉ ra số tiền trong chứng từ một cách thủ công';
						|ru = 'Остаток задолженности по счету ""%1"" равен 0. Укажите сумму документа вручную';
						|en = 'Remaining debt of the ""%1"" account is equal to 0. Specify the document amount manually'; fa = 'Remaining debt of the ""%1"" account is equal to 0. Specify the document amount manually';
						|it = 'Saldo del debito per il conto ""%1"" uguale a 0. Indicare l''importo del documento manualmente';
						|pl = 'Saldo konta ""%1"" wynosi 0. Określ ręcznie ilość dokumentów';
						|tr = '""%1"" hesabındaki borç bakiyesi 0''dır. Belge tutarını manuel olarak belirt'");
			
		ElsIf BasisType = Type("DocumentRef.PaymentRequest") Then
			Text = NStr("vi = 'Số dư theo đề nghị ""%1"" bằng 0. Hãy chọn đề nghị chưa thực hiện';
						|ru = 'Остаток по заявке ""%1"" равен 0. Выберите неоплаченную заявку';
						|en = '""%1"" request balance is equal to 0. Select an unpaid request'; fa = '""%1"" request balance is equal to 0. Select an unpaid request';
						|it = 'Saldo per domanda ""%1"" uguale a 0. Selezionare la domanda non pagata';
						|pl = 'Saldo w aplikacji ""%1"" wynosi 0. Wybierz niezapłaconą aplikację';
						|tr = '""%1"" talep bakiyesi 0''dır. Ödenmemiş talebi seç'");
			
		ElsIf BasisType = Type("DocumentRef.CashTransferReferenceOrder") Then
			Text = NStr("vi = 'Số dư theo lệnh ""%1"" bằng 0. Hãy chọn lệnh chưa thanh toán';
						|ru = 'Остаток по распоряжению ""%1"" равен 0. Выберите неоплаченное распоряжение';
						|en = '""%1"" reference balance is equal to 0. Select an unpaid reference'; fa = '""%1"" reference balance is equal to 0. Select an unpaid reference';
						|it = 'Saldo per riferimento ""%1"" uguale a 0. Sezionare il riferimento non pagato';
						|pl = 'Saldo zlecenia ""%1"" wynosi 0. Wybierz zamówienie oczekujące';
						|tr = '""%1"" siparişinin bakiyesi 0''dır. Ödenmemiş siparişi seç'");
			
		ElsIf BasisType = Type("DocumentRef.CashVoucher") Then
			Text = NStr("vi = 'Số dư tiền mặt để tiếp nhận theo chứng từ ""%1"" bằng 0. Hãy chỉ ra số tiền trong chứng từ một cách thủ công';
						|ru = 'Остаток денежных средств к поступлению по документу ""%1"" равен 0. Укажите сумму документа вручную';
						|en = 'Cash balance for receipt against the ""%1"" document is equal to 0. Specify the document amount manually'; fa = 'Cash balance for receipt against the ""%1"" document is equal to 0. Specify the document amount manually';
						|it = 'Saldo di cassa in versamento per il documento ""%1"" uguale a 0. Indicare l''importo del documento manualmente';
						|pl = 'Saldo gotówkowe za otrzymanie dokumentu ""%1"" wynosi 0. Określ ręcznie wartość dokumentu';
						|tr = '""%1"" belgesi altındaki nakit alacak bakiyesi 0''dır. Belge tutarını manuel olarak belirt'");
			
		Else
			Text = NStr("vi = 'Số dư công nợ theo chứng từ ""%1"" bằng 0. Hãy chỉ ra số tiền trong chứng từ một cách thủ công';
						|ru = 'Остаток задолженности по документу ""%1"" равен 0. Укажите сумму документа вручную';
						|en = 'Remaining debt against the ""%1"" document is equal to 0. Specify the document amount manually'; fa = 'Remaining debt against the ""%1"" document is equal to 0. Specify the document amount manually';
						|it = 'Saldo del debito pe ril documento ""%1"" uguale a 0. Indicare l''importo del documento manualmente';
						|pl = 'Saldo zadłużenia dokumentu ""%1"" wynosi 0. Określ kwotę dokumentu ręcznie';
						|tr = '""%1"" belgesinin borç bakiyesi 0''dır. Belge tutarını manuel olarak belirt'");
		EndIf;
		
		If Not IsBlankString(Text) Then
			CommonClientServer.MessageToUser(StrTemplate(Text, Basis),, "Object.DocumentAmount");
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the document amounts need to be converted from currency to currency
//
// Parameters:
//	Object - FormDataStructure - Current document
//	CurrentCurrency - CatalogRef.Currencies - Current currency
//	NewCurrency - CatalogRef.Currencies - New currency.
//
// Returns:
//	Boolean - True if the amounts need to be recalculated.
//
Function CurrencyConversionRequired(Object, CurrentCurrency, NewCurrency) Export
	
	RecalculationIsRequired = False;
	
	If ValueIsFilled(CurrentCurrency)
	 And ValueIsFilled(NewCurrency)
	 And CurrentCurrency <> NewCurrency Then
	
		ArrayOfTabularParts = New Array;
		ArrayOfTabularParts.Add("ARAPDetails");
		ArrayOfTabularParts.Add("AccountsReceivable");
		ArrayOfTabularParts.Add("AccountsPayable");
		
		If Object.DocumentAmount <> 0 Then
			RecalculationIsRequired = True;
		Else
			For Each TabularSection In ArrayOfTabularParts Do
				
				If Object.Property(TabularSection)
				 And Object[TabularSection].Total("Sum") <> 0 Then
					RecalculationIsRequired = True;
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
	EndIf;
	
	Return RecalculationIsRequired;
	
EndFunction

// If necessary, the procedure clears the settlement amount in the table part "payment Description".
//
// Parameters:
//	Object - FormDataStructure - Current document.
//
Procedure ClearAmountOfSettlementsPaymentDecryption(Object) Export
	
	NotEmptyAmount = False;
	
	For Each TableRow In Object.ARAPDetails Do
		If TableRow.AmountARAP > 0
			And TableRow.ARAPCurrency <> Object.Currency Then
			NotEmptyAmount = True;
			Break;
		EndIf;
	EndDo;
	
	If NotEmptyAmount Then
		QueryText = NStr("vi = 'Xóa số tiền hạch toán công nợ theo diễn giải thanh toán?';
						|ru = 'Очистить сумму взаиморасчетов в расшифровке платежа?';
						|en = 'Clear AR/AP amount in payment details?'; fa = 'Clear AR/AP amount in payment details?';
						|it = 'Cancellare l''importo di regolamenti reciproci nella decodifica del pagamento?';
						|pl = 'Oczyścić kwotę rozliczeń wzajemnych w szczegółach płatności?';
						|tr = 'Ödeme detayında mutabakatların miktarını temizle?'");
		
		AddlParameters = New Structure;
		AddlParameters.Insert("Object", Object);
		
		CallbackDescription = New CallbackDescription("ClearAmountOfSettlementsCompletion", ThisObject, AddlParameters);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

Procedure ClearAmountOfSettlementsCompletion(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		Object = AdditionalParameters.Object;
		
		For Each TableRow In Object.ARAPDetails Do
			If TableRow.AmountARAP > 0
				And TableRow.ARAPCurrency <> Object.Currency Then
					TableRow.AmountARAP = 0;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The procedure clears the amount of settlements and the currency of settlements in the table part "payment Decryption".
//
// Parameters:
//	Object - FormDataStructure - Current document.
//
Procedure ClearAmountAndCurrencyOfSettlementsPaymentDecryption(Object) Export
	
	NotEmptyCurrencyOrAmount = False;
	
	For Each TableRow In Object.ARAPDetails Do
		If ValueIsFilled(TableRow.ARAPCurrency) Or TableRow.AmountARAP > 0 Then
			NotEmptyCurrencyOrAmount = True;
			Break;
		EndIf;
	EndDo;
	
	If NotEmptyCurrencyOrAmount Then
		QueryText = NStr("vi = 'Xóa số tiền và tiền tệ hạch toán công nợ theo diễn giải thanh toán?';
						|ru = 'Очистить сумму и валюту взаиморасчетов в расшифровке платежа?';
						|en = 'Clear AR/AP amount and currency in payment details?'; fa = 'Clear AR/AP amount and currency in payment details?';
						|it = 'Cancellare l''importo e la valuta di regolamenti reciproci nella decodifica del pagamento?';
						|pl = 'Oczyścić kwotę i walutę rozliczeń wzajemnych w szczegółach płatności?';
						|tr = 'Ödeme detayında mutabakatların miktarı ve para birimini temizle?'");
		
		AddlParameters = New Structure;
		AddlParameters.Insert("Object", Object);
		
		CallbackDescription = New CallbackDescription("ClearAmountAndCurrencyOfSettlementsEnd", ThisObject, AddlParameters);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

Procedure ClearAmountAndCurrencyOfSettlementsEnd(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		Object = AdditionalParameters.Object;
		
		For Each TableRow In Object.ARAPDetails Do
			If ValueIsFilled(TableRow.ARAPObject) Then
				If TableRow.ARAPCurrency = Object.Currency Then
					TableRow.AmountARAP = 0;
				EndIf;
			Else
				TableRow.ARAPCurrency = Undefined;
				TableRow.AmountARAP = 0;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Opens the form for viewing/editing document inventory types.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the client application.
//	OptionsForEditingInventoryTypes - See InventoriesServer.PutGoodsAndStockTypesInStorage
//
Procedure OpenInventoryKinds(Form, OptionsForEditingInventoryTypes) Export
	
	InputFormParameters = New Structure("OptionsForEditingInventoryTypes", OptionsForEditingInventoryTypes);
	
	InputForm = OpenForm("Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm", InputFormParameters, Form);
	
	If OptionsForEditingInventoryTypes.EditInventoryKinds
		And InputForm.EditInventoryKinds Then
		
		Form.LockFormDataForEdit();
		
	EndIf;
	
EndProcedure

// Determines whether the business transaction of the document is related to settlements with customers.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
//	Boolean - A business transaction refers to settlements with customers.
//
Function TheseAreSettlementsWithCustomers(BusinessOperation) Export
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer")
	 Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer") Then
		TheseAreSettlementsWithCustomers = True;
	Else
		TheseAreSettlementsWithCustomers = False;
	EndIf;
	
	Return TheseAreSettlementsWithCustomers;
	
EndFunction

// Gets an empty link to the customer's order or to the supplier's order.
//
// Parameters:
//	OrderDocument - DocumentRef - OrderDocument
//	TheseAreSettlementsWithCustomers - Boolean - Indicates whether payments to clients are reflected.
//
Procedure SetEmptyLinkToOrder(OrderDocument, TheseAreSettlementsWithCustomers) Export
	
	If OrderDocument = Undefined Then
		If TheseAreSettlementsWithCustomers Then
			OrderDocument = PredefinedValue("Document.SalesOrder.EmptyRef");
		Else
			OrderDocument = PredefinedValue("Document.PurchaseOrder.EmptyRef");
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates the amount in the document header if it differs from the amounts in the table part.
//
// Parameters:
//    Form - ClientApplicationForm - The form from which multi-turn packaging is selected
//    CallbackDescription - CallbackDescription - Description of the document form notification
//    TabularSectionName - String - Name of the table part containing the payment transcript.
//
Procedure RecalculateAmountOfDocumentBasedOnPaymentDecryption(
	Val Form,
	CallbackDescription,
	Val TabularSectionName = "") Export
	
	If Not ValueIsFilled(TabularSectionName) Then
		TabularSection = Form.Object.ARAPDetails;
	Else
		TabularSection = Form.Object[TabularSectionName];
	EndIf;
	
	If TabularSection.Count() > 0
		And Form.Object.DocumentAmount <> TabularSection.Total("Sum") Then
		
		QueryText = NStr("vi = 'Số tiền theo dòng trong phần bảng không bằng số tiền trong chứng từ, tính lại số tiền trong chứng từ?';
						|ru = 'Сумма по строкам в табличной части не равна сумме документа, пересчитать сумму документа?';
						|en = 'Total amount in the table rows is not equal to the document amount. Recalculate the document amount?'; fa = 'Total amount in the table rows is not equal to the document amount. Recalculate the document amount?';
						|it = 'Importo per riga della parte tabulare non corrispondente all''importo del documento, ricalcolare l''importo del documento?';
						|pl = 'Wartość w wierszach w części tabelarycznej nie jest równa ilości dokumentu, ponownie obliczyć kwotę dokumentu?';
						|tr = 'Tablo bölümündeki satırların toplamı belge tutarına eşit değil, belge tutarını yeniden hesapla?'");
		
		AddlParameters = New Structure;
		AddlParameters.Insert("Form", Form);
		AddlParameters.Insert("CallbackDescription", CallbackDescription);
		AddlParameters.Insert("TabularSectionName", TabularSectionName);
		
		CallbackDescription = New CallbackDescription("RecalculateAmountOfDocumentBasedOnPaymentDecryptionCompletion", FinancesClient, AddlParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		RunCallback(CallbackDescription, True);
	EndIf;
	
EndProcedure

Procedure RecalculateAmountOfDocumentBasedOnPaymentDecryptionCompletion(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		If AdditionalParameters.Property("TabularSectionName")
			And ValueIsFilled(AdditionalParameters.TabularSectionName) Then
			TabularSection = AdditionalParameters.Form.Object[AdditionalParameters.TabularSectionName];
		Else
			TabularSection = AdditionalParameters.Form.Object.ARAPDetails;
		EndIf;
		
		AdditionalParameters.Form.Object.DocumentAmount = TabularSection.Total("Sum");
		RunCallback(AdditionalParameters.CallbackDescription, True);
	Else
		
		RunCallback(AdditionalParameters.CallbackDescription, False);
	EndIf;
	
EndProcedure

// Opens the file for viewing
//
// Parameters:
//    AnchorElement - String - A message will be linked to the specified element in case of an error
//    FileName - String - Full file name
//    Encoding - String - "DOS" or " Windows"
//    Title - String - The title of the form in which the file will be opened.
//
Procedure OpenFileForViewing(AnchorElement, FileName, Encoding, Title) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FileName",        FileName);
	AdditionalParameters.Insert("Encoding",       Encoding);
	AdditionalParameters.Insert("FileTitle",  Title);
	AdditionalParameters.Insert("AnchorElement", AnchorElement);
	
	CallbackDescription = New CallbackDescription("OpenFileToViewCreateFile", ThisObject, AdditionalParameters);
	
	File = New File();
	File.BeginInitialization(CallbackDescription, AdditionalParameters.FileName);
	
EndProcedure

Procedure OpenFileToViewCreateFile(File, AdditionalParameters) Export
	
	If File.Extension = ".zip" Then
	
		MessageText = StrTemplate(NStr("vi = 'Tệp %1 là tệp nén zip và không thể mở dưới dạng tệp văn bản.';
										|ru = 'Файл %1 является пакетом zip и не может быть открыт в виде текстового файла.';
										|en = 'The %1 file is a ZIP package. You cannot open the file as a text file.'; fa = 'The %1 file is a ZIP package. You cannot open the file as a text file.';
										|it = 'Il file %1 è in formato zip e non può essere aperto come un file di testo.';
										|pl = 'Plik %1 jest pakietem zip i nie może być otwarty jako plik tekstowy.';
										|tr = '%1 dosyası zip paketidir ve metin dosyası olarak açılamaz.'"),
							File.Name);
		CommonClientServer.MessageToUser(MessageText, , AdditionalParameters.AnchorElement);
		Return;
	
	EndIf;
	
	AdditionalParameters.Insert("File", File);
	CallbackDescription = New CallbackDescription("OpenFileForViewingExistenceCheck", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

Procedure OpenFileForViewingExistenceCheck(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa tìm thấy %1';
				|ru = '%1 не обнаружен';
				|en = '%1 is not found'; fa = '%1 is not found';
				|it = '%1 non rilevato';
				|pl = '%1 nie wykryto';
				|tr = '%1 bulunmadı'"), AdditionalParameters.FileTitle);
		CommonClientServer.MessageToUser(
			MessageText
			,, AdditionalParameters.AnchorElement);
		
		Return;
	EndIf;
	
	File = AdditionalParameters.File;
	CallbackDescription = New CallbackDescription("OpenFileToViewCheckingForDirectory", ThisObject, AdditionalParameters);
	File.BeginCheckingIsDirectory(CallbackDescription);
	
EndProcedure

Procedure OpenFileToViewCheckingForDirectory(IsDirectory, AdditionalParameters) Export
	
	If IsDirectory Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 không đúng - đã chọn ""thư mục"".
			|Hãy chọn %1';
			|ru = '%1 не корректен - выбран ""каталог"".
			|Выберите %1';
			|en = '%1 is incorrect – ""directory"" is selected.
			|Select %1'; fa = '%1 is incorrect – ""directory"" is selected.
			|Select %1';
			|it = '%1 non corretto - selezionato ""catalogo"".
			| Selezionare %1';
			|pl = '%1 niepoprawny - wybrany ""katalog"".
			|Wybierz %1';
			|tr = '%1 doğru değil - ""klasör"" seçili.
			|Seç%1'"), AdditionalParameters.FileTitle);
		CommonClientServer.MessageToUser(
			MessageText
			,, AdditionalParameters.AnchorElement);
		
		Return;
	EndIf;
	
	Files = New Array;
	Files.Add(New TransferableFileDescription(AdditionalParameters.FileName));
	
	PlacingFilesCompletion = New CallbackDescription("OpenFileToViewRoomCompletion", ThisObject, AdditionalParameters);
	BeginPuttingFiles(PlacingFilesCompletion, Files,, False, );
	
EndProcedure

Procedure OpenFileToViewRoomCompletion(PlacedFiles, AdditionalParameters) Export
	
	If PlacedFiles <> Undefined And PlacedFiles.Count() > 0 Then
		FilesDetails = PlacedFiles.Get(0);
		FileAddress     = FilesDetails.Location;
		
		If FileAddress = Undefined Then
			Return;
		EndIf;
		
		Text = CashServerCall.TextDocumentFromTemporaryFileStorage(FileAddress, AdditionalParameters.Encoding);
		Text.Show(AdditionalParameters.FileTitle, AdditionalParameters.FileName);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Procedure for processing the event "Initialedaction" of the table part "payment Decryption".
//
Procedure ARAPDetailsOnStartEdit(Object, Partner, CounterpartyContract, TableRow, NewRow, Copy, CashFlowItem = Undefined) Export
	
	// It is necessary to set an empty link in the base of the payment so that a search by line is available
	If TableRow <> Undefined And TableRow.Property("PaymentPurpose") Then
		TheseAreSettlementsWithCustomers = TheseAreSettlementsWithCustomers(Object.BusinessOperation);
		SetEmptyLinkToOrder(TableRow.PaymentPurpose, TheseAreSettlementsWithCustomers);
	EndIf;
	
	If NewRow Then
		
		If Copy Then
			
			SumBalance = Object.DocumentAmount
				- Object.ARAPDetails.Total("Sum")
				+ Object.ARAPDetails[Object.ARAPDetails.Count()-1].Sum;
		Else
			
			SumBalance = Object.DocumentAmount - Object.ARAPDetails.Total("Sum");
			
			If ValueIsFilled(Partner) Then
				TableRow.Partner = Partner;
			EndIf;
			
			If ValueIsFilled(CounterpartyContract) Then
				If TableRow.Property("PaymentPurpose") Then
					TableRow.PaymentPurpose = CounterpartyContract;
				EndIf;
				If ValueIsFilled(CashFlowItem) Then
					TableRow.CashFlowItem = CashFlowItem;
				EndIf;
			EndIf;
		EndIf;
		
		TableRow.Sum = SumBalance;
	EndIf;
	
EndProcedure

#EndRegion
