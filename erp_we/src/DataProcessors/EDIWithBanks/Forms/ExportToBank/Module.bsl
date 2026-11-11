
#Region Variables

&AtClient
Var AmountsOfPaymentsToBeUploaded;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // refund upon receipt of the form for analysis
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	
	FillInInvoiceTable();
	
	If Parameters.Property("BankAccount")
		And ValueIsFilled(Parameters.BankAccount) Then
		
		TableRows = Object.BankAccounts.FindRows(New Structure("Ref", Parameters.BankAccount));
		If TableRows.Count() Then
			TableRows[0].Check = True;
			Object.AccountList.Add(TableRows[0]["Ref"]);
			UpdatePaymentList();
			AccountLineIndex = Object.BankAccounts.IndexOf(TableRows[0]);
		EndIf;
		
	ElsIf Parameters.Property("AddressOfDocumentsToUpload")
		And ValueIsFilled(Parameters.AddressOfDocumentsToUpload) Then
		
		DocumentsFilter.Load(GetFromTempStorage(Parameters.AddressOfDocumentsToUpload));
		BankAccounts = DocumentsFilter.Unload(,"BankAccount").UnloadColumn("BankAccount");
		
		For Each BankAccount In BankAccounts Do 
			TableRows = Object.BankAccounts.FindRows(New Structure("Ref", BankAccount));
			If TableRows.Count() Then
				TableRows[0].Check = True;
				Object.AccountList.Add(TableRows[0]["Ref"]);
				UpdatePaymentList();
				AccountLineIndex = Object.BankAccounts.IndexOf(TableRows[0]);
			EndIf;
		EndDo;
		
	EndIf;
	
	FillInPeriodSelectionList_();
	
	SetUpSupportForBankingAndTreasurySupport();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Object.NotExportedOnly = (NotExportedOnly = 1);
	
	If Period = NStr("vi = 'Toàn bộ thời gian';
					|ru = 'Все время';
					|en = 'All time'; fa = 'همه زمان‌ها';
					|it = 'Все время';
					|pl = 'Cały czas';
					|tr = 'Her zaman'") Then
		Object.ExportStartDate  = '00010101';
		Object.ExportEndDate   = '00010101';
	ElsIf Period = "PerDate" Then
		Object.ExportStartDate  = BegOfDay(DateFilter);
		Object.ExportEndDate   = EndOfDay(DateFilter);
	ElsIf TypeOf(Period) = Type("Date") Then
		Object.ExportStartDate  = Period;
		Object.ExportEndDate   = EndOfDay(Period);
	ElsIf Period = NStr("vi = 'Hôm nay';
						|ru = 'Сегодня';
						|en = 'Today'; fa = 'امروز';
						|it = 'Сегодня';
						|pl = 'Dzisiaj';
						|tr = 'Bugün'") Then
		Object.ExportStartDate  = CurrentSessionDate();
		Object.ExportEndDate   = EndOfDay(CurrentSessionDate());
	ElsIf Period = NStr("vi = 'Ba ngày';
						|ru = 'Три дня';
						|en = 'Three days'; fa = 'Three days';
						|it = 'Три дня';
						|pl = 'Trzy dni';
						|tr = 'Üç gün'") Then
		Object.ExportStartDate  = CurrentSessionDate() - 3 * 24 * 3600;
		Object.ExportEndDate   = EndOfDay(CurrentSessionDate());
	ElsIf Period = NStr("vi = 'Một tuần';
						|ru = 'Неделю';
						|en = 'Week'; fa = 'هفته';
						|it = 'Неделю';
						|pl = 'Tygodniu';
						|tr = 'Hafta'") Then
		Object.ExportStartDate  = CurrentSessionDate() - 7 * 24 * 3600;
		Object.ExportEndDate   = EndOfDay(CurrentSessionDate());
	EndIf;
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpgradeBasement();
	
	If Object.AccountList.Count() = 1 Then
		BankAccount = Object.AccountList[0].Value;
		Items.BankAccounts.CurrentRow = AccountLineIndex;
	EndIf;
	
	If CommonClientServer.IsWebClient() Then
		AttachIdleHandler("Attachable_AttachFileSystemExtension", 0.1, True);
	Else
		AbilityToSelectFiles = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AttachFileSystemExtension() Export
	
	CallbackDescription = New CallbackDescription("AttachFileSystemExtensionCompletion", ThisObject);
	CommonClient.ShowFileSystemExtensionInstallationQuestion(CallbackDescription);
	
EndProcedure

&AtClient
Procedure AttachFileSystemExtensionCompletion(FileExtensionEnabled, AdditionalParameters) Export
	
	AbilityToSelectFiles = FileExtensionEnabled;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	If EventName = "Write_ConstantsSet" Then
		SetUpSupportForBankingAndTreasurySupport();
	EndIf;
	
	Return;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseWithoutConfirmation Then
		
		ThereAreUnloadedFiles = False;
		For Each Account In Object.BankAccounts Do
			If Account.Exported And Account.ExchangeThroughFile Then
				ThereAreUnloadedFiles = True;
				Break;
			EndIf;
		EndDo;
		
		If ThereAreUnloadedFiles Then
			StandardProcessing = False;
			Cancel = True;
			If Exit Then
				WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
									|ru = 'Данные были изменены. Все изменения будут потеряны.';
									|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
									|it = 'Данные были изменены. Все изменения будут потеряны.';
									|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
									|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
				Return;
			EndIf;
			
			Buttons = New ValueList();
			Buttons.Add(1, NStr("vi = 'Xóa tập tin và đóng';
								|ru = 'Удалить файлы и закрыть';
								|en = 'Delete files and close'; fa = 'حذف فایل‌ها و بستن';
								|it = 'Удалить файлы и закрыть';
								|pl = 'Usuń pliki i zamknij';
								|tr = 'Dosyaları sil ve kapat'"));
			Buttons.Add(2, NStr("vi = 'Đóng mà không xóa';
								|ru = 'Закрыть без удаления';
								|en = 'Close without deletion'; fa = 'Close without deletion';
								|it = 'Закрыть без удаления';
								|pl = 'Zamknij bez usuwania';
								|tr = 'Silmeden kapat'"));
			Buttons.Add(0, NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Отмена';
								|pl = 'Cancel';
								|tr = 'İptal'"));
			
			QueryText = NStr("vi = 'Có thể là không được phép thay đổi tệp đã kết xuất.
				|Nên xóa tệp trước khi đóng biểu mẫu.';
				|ru = 'Выгруженные файлы могут быть несанкционированно изменены.
				|Рекомендуется удалить файлы перед закрытием формы.';
				|en = 'Exported files can be changed without authorization.
				|Remove the files before closing the form.'; fa = 'Exported files can be changed without authorization.
				|Remove the files before closing the form.';
				|it = 'Выгруженные файлы могут быть несанкционированно изменены.
				|Рекомендуется удалить файлы перед закрытием формы.';
				|pl = 'Przesyłane pliki mogą być nieautoryzowanie zmienione.
				|Zaleca się usunięcie plików przed zamknięciem formularza.';
				|tr = 'Yüklenen dosyalar üzerinde sınırsız düzenlemeler yapılabilir.
				|Formu kapatmadan önce dosyaları silmeniz önerilmektedir.'");
			ShowQueryBox(
				New CallbackDescription("QuestionOfClosure", ThisObject),
				QueryText,
				Buttons,,
				1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionOfClosure(Response, AdditionalParameters) Export
	
	If Response <> Undefined Then
		If Response = 1 Then
			DeleteAndClose(Undefined);
		ElsIf Response = 2 Then
			CloseWithoutConfirmation = True;
			Close();
		EndIf;
	Else
		CloseWithoutConfirmation = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CatalogOfUploadingSupportingDocumentsStartChoice(Item, ChoiceData, StandardProcessing)

	Return;

EndProcedure


#EndRegion

#Region EventHandlersForBankAccountListItems

&AtClient
Procedure BankAccountsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.BankAccounts.CurrentData;
	
	If Field.Name = "BankAccountsRef" Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Ref);
		
	ElsIf Field.Name = "BankAccountsConfigureExchange" Then
		
			If CurrentData.Exporting Then
				StandardProcessing = False;
			EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsCheckOnChange(Item)
	
	AttachIdleHandler("ProcessInvoiceTagging", 0.1, True);
	
EndProcedure

&AtClient
Procedure BankAccountsConfigureExchangeStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If AbilityToSelectFiles Then
		CurrentData = Items.BankAccounts.CurrentData;
		ChoosingExchangeFileWithBank(CurrentData);
	Else
		AttachIdleHandler("Attachable_EnableFileWorkExtensionAndSelectFile", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsConfigureExchangeOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.BankAccounts.CurrentData;
	If ValueIsFilled(CurrentData.ConfigureExchange) Then
		FinancesClient.OpenFileForViewing(
			"Object.BankAccounts[" + String(Items.BankAccounts.CurrentRow) + "].ConfigureExchange",
			CurrentData.ConfigureExchange, CurrentData.Encoding, NStr("vi = 'Tệp kết xuất';
																		|ru = 'Файл выгрузки';
																		|en = 'Export file'; fa = 'فایل خروج';
																		|it = 'Файл выгрузки';
																		|pl = 'Plik przesyłania';
																		|tr = 'Dışa aktarma dosyası'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsConfigureExchangeOnChange(Item)
	
	CurrentData = Items.BankAccounts.CurrentData;
	CurrentData.RuleOfFileEDIWithBanks = CurrentData.ConfigureExchange;
	
EndProcedure

#EndRegion

#Region EventHandlersForPaymentListItems

&AtClient
Procedure PeriodOnChange(Item)
	
	LocalCurDate = LocalCurDate();
	
	If Period = NStr("vi = 'Toàn bộ thời gian';
					|ru = 'Все время';
					|en = 'All time'; fa = 'همه زمان‌ها';
					|it = 'Все время';
					|pl = 'Cały czas';
					|tr = 'Her zaman'") Then
		
		Object.ExportStartDate  = '00010101';
		Object.ExportEndDate   = '00010101';
		
	ElsIf Period = "PerDate" Then
		
		Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisForm, );
		ShowInputDate(Notification, LocalCurDate, NStr("vi = 'Ngày thanh toán';
														|ru = 'Дата отбора платежей';
														|en = 'Payment filter date'; fa = 'Payment filter date';
														|it = 'Дата отбора платежей';
														|pl = 'Data wyboru płatności';
														|tr = 'Ödeme filtre tarihi'"), DateFractions.Date);
		Return;
		
	ElsIf TypeOf(Period) = Type("Date") Then
		
		Object.ExportStartDate  = Period;
		If ValueIsFilled(Period) Then
			Object.ExportEndDate   = EndOfDay(Period);
		Else
			Object.ExportEndDate   = Period;
		EndIf;
		
	ElsIf Period = NStr("vi = 'Hôm nay';
						|ru = 'Сегодня';
						|en = 'Today'; fa = 'امروز';
						|it = 'Сегодня';
						|pl = 'Dzisiaj';
						|tr = 'Bugün'") Then
		
		Object.ExportStartDate  = LocalCurDate;
		Object.ExportEndDate   = EndOfDay(LocalCurDate);
		
	ElsIf Period = NStr("vi = 'Ba ngày';
						|ru = 'Три дня';
						|en = 'Three days'; fa = 'Three days';
						|it = 'Три дня';
						|pl = 'Trzy dni';
						|tr = 'Üç gün'") Then
		
		Object.ExportStartDate  = LocalCurDate - 3 * 24 * 3600;
		Object.ExportEndDate   = EndOfDay(LocalCurDate);
		
	ElsIf Period = NStr("vi = 'Một tuần';
						|ru = 'Неделю';
						|en = 'Week'; fa = 'هفته';
						|it = 'Неделю';
						|pl = 'Tygodniu';
						|tr = 'Hafta'") Then
		
		Object.ExportStartDate  = LocalCurDate - 7 * 24 * 3600;
		Object.ExportEndDate   = EndOfDay(LocalCurDate);
		
	EndIf;
	
	PeriodForChangesOnServer();
	
	UpgradeBasement();
	
EndProcedure

&AtServerNoContext
Function LocalCurDate()
	
	Return CurrentSessionDate();
	
EndFunction

&AtClient
Procedure PeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = "Date_" Then
		
		StandardProcessing = False;
		
		Notification = New CallbackDescription("ExecuteAfterSelectingDate", ThisObject);
		
		NoteText = NStr("vi = 'Chọn ngày của chứng từ được tải lên';
						|ru = 'Выберите дату выгружаемых документов';
						|en = 'Select the date of exported documents'; fa = 'Select the date of exported documents';
						|it = 'Выберите дату выгружаемых документов';
						|pl = 'Wybierz datę przesyłania dokumentów';
						|tr = 'Yüklenen belge tarihini seç'") + " ";
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
Procedure ExecuteAfterSelectingDate(SelectedDate, Var_Parameters) Export
	
	LocalCurDate = LocalCurDate();
	
	If ValueIsFilled(SelectedDate) Then
		
		Object.ExportStartDate  = BegOfDay(SelectedDate);
		Object.ExportEndDate   = EndOfDay(SelectedDate);
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
		
		If Object.ExportStartDate  = '00010101' And Object.ExportEndDate = '00010101' Then
			Period = NStr("vi = 'Toàn bộ thời gian';
							|ru = 'Все время';
							|en = 'All time'; fa = 'همه زمان‌ها';
							|it = 'Все время';
							|pl = 'Cały czas';
							|tr = 'Her zaman'");
		ElsIf Object.ExportStartDate = BegOfDay(LocalCurDate)
			And Object.ExportEndDate = EndOfDay(LocalCurDate) Then
			Period = NStr("vi = 'Hôm nay';
							|ru = 'Сегодня';
							|en = 'Today'; fa = 'امروز';
							|it = 'Сегодня';
							|pl = 'Dzisiaj';
							|tr = 'Bugün'");
		ElsIf Object.ExportStartDate = BegOfDay(LocalCurDate) - 3 * 24 * 3600
			And Object.ExportEndDate = EndOfDay(LocalCurDate) Then
			Period = NStr("vi = 'Ba ngày';
							|ru = 'Три дня';
							|en = 'Three days'; fa = 'Three days';
							|it = 'Три дня';
							|pl = 'Trzy dni';
							|tr = 'Üç gün'");
		ElsIf Object.ExportStartDate = BegOfDay(LocalCurDate) - 7 * 24 * 3600
			And Object.ExportEndDate = EndOfDay(LocalCurDate) Then
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

&AtServer
Procedure PeriodForChangesOnServer()
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure NotExportedOnlyOnChange(Item)
	
	Object.NotExportedOnly = (NotExportedOnly = 1);
	
	UpdatePaymentList();
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure DocumentsToExportSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Field.Name = "DocumentsToExportToExport" Then
		StandardProcessing = False;
		ShowValue(Undefined, Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadPaymentDocumentsWhenChangingThem(Item)
	
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
Procedure TextDirectBankHorizontallyURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkAccounts(Command)
	
	ClearMessages();
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		If Not Account.Exporting Then
			Account.Check = True;
			Object.AccountList.Add(Account.Ref);
		EndIf;
	EndDo;
	
	UpdatePaymentList();
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure ClearAccounts(Command)
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		If Not Account.Exporting Then
			Account.Check = False;
		EndIf;
	EndDo;
	
	Object.DocumentsToExport.Clear();
	
	UpgradeBasement();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfAccounts(Command)
	
	// If there are accounts that are being unloaded, we do not give them an update
	UnloadingIsPerformed = False;
	For Each Account In Object.BankAccounts Do
		If Account.Exporting Then
			UnloadingIsPerformed = True;
		EndIf;
	EndDo;
	
	If Not UnloadingIsPerformed Then
		UpdateListOfAccountsOnServer();
		UpgradeBasement();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateListOfAccountsOnServer()
	
	FillInInvoiceTable();
	
	// The marked accounts keep the mark
	ArrayOfFoundAccounts = New Array;
	For Each Account In Object.BankAccounts Do
		ListCount_ = Object.AccountList.FindByValue(Account.Ref);
		If ListCount_ <> Undefined Then
			Account.Check = True;
			ArrayOfFoundAccounts.Add(ListCount_);
		EndIf;
	EndDo;
	
	ArrayOfAccountsNotFound = New Array;
	For Each Account In Object.AccountList Do
		If ArrayOfFoundAccounts.Find(Account) = Undefined Then
			ArrayOfAccountsNotFound.Add(Account);
		EndIf;
	EndDo;
	
	For Each Account In ArrayOfAccountsNotFound Do
		Object.AccountList.Delete(Account);
	EndDo;
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Procedure SelectFile(Command)
	
	ClearMessages();
	CurrentData = Items.BankAccounts.CurrentData;
	If CurrentData <> Undefined Then
		If AbilityToSelectFiles Then
			ChoosingExchangeFileWithBank(CurrentData);
		Else
			AttachIdleHandler("Attachable_EnableFileWorkExtensionAndSelectFile", 0.1, True);
		EndIf;
	Else
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để chọn tệp, cần chọn dòng có tài khoản ngân hàng.
				|Nếu danh sách tài khoản ngân hàng trống, hãy chắc chắn rằng, trên thẻ tài khoản ngân hàng đã bật trao đổi với ngân hàng.';
				|ru = 'Для выбора файла должна быть выделена строка с банковским счетом.
				|Если список банковских счетов пуст, убедитесь, что в карточке банковского счета включен обмен с банком.';
				|en = 'To select a file, a line with the bank account must be selected.
				|If the bank account list is empty, make sure that EDI is enabled in the bank account card.'; fa = 'To select a file, a line with the bank account must be selected.
				|If the bank account list is empty, make sure that EDI is enabled in the bank account card.';
				|it = 'Для выбора файла должна быть выделена строка с банковским счетом.
				|Если список банковских счетов пуст, убедитесь, что в карточке банковского счета включен обмен с банком.';
				|pl = 'Aby wybrać plik, należy zaznaczyć wiersz z rachunkiem bankowym.
				|Jeśli lista rachunków bankowych jest pusta, upewnij się, że na rachunku bankowym włączona jest wymiana z bankiem.';
				|tr = 'Dosya seçmek için banka hesabı satırı seçilmelidir.
				|Banka hesapları listesi boşsa, banka hesabı kartında bankayla EDI etkinleştirildiğinden emin ol.'"),,
			"Items.BankAccountsRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFile(Command)
	
	ClearMessages();
	CurrentData = Items.BankAccounts.CurrentData;
	If CurrentData <> Undefined Then
		If Not CurrentData.DirectExchange And ValueIsFilled(CurrentData.ConfigureExchange) Then
			FinancesClient.OpenFileForViewing(
				"Object.BankAccounts[" + String(Items.BankAccounts.CurrentRow) + "].ConfigureExchange",
				CurrentData.ConfigureExchange, CurrentData.Encoding, NStr("vi = 'Tệp kết xuất';
																			|ru = 'Файл выгрузки';
																			|en = 'Export file'; fa = 'فایل خروج';
																			|it = 'Файл выгрузки';
																			|pl = 'Plik przesyłania';
																			|tr = 'Dışa aktarma dosyası'"));
		EndIf;
	EndIf;
	
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
	
	ClearMessages();
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

&AtClient
Procedure Unload(Command)
	
	ClearMessages();
	ArrayOfDocumentsDirectExchange = New Array;
	
	
	For Each Account In Object.BankAccounts Do
		
		If Not Account.Check Then
			Continue;
		EndIf;
		
			If Not ValueIsFilled(Account.ConfigureExchange) Then
				
				If AbilityToSelectFiles Then
					SelectingFileWhenUploading(Account);
				Else
					EnableFileExtensionAndSelectFileWhenUploading(Account);
				EndIf;
			EndIf;
	EndDo;
	
	
	UploadToServer();
	
	ProcessUploadCompletion();
	EnableWaitingForBackgroundTasks();
	
EndProcedure

&AtServer
Procedure UploadToServer()
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.ExportPayments(ThisForm.UUID);
	ValueToFormAttribute(DataProcessor, "Object");
	
EndProcedure

&AtClient
Procedure DeleteAndClose(Command)
	
	ClearMessages();
	DetachIdleHandler("Attachable_CheckUploadFiles");
	
	For Each Account In Object.BankAccounts Do
		If Account.Exported And Account.ExchangeThroughFile And ValueIsFilled(Account.ConfigureExchange) Then
			BeginDeletingFiles(New CallbackDescription("AfterDeletingFiles", ThisObject), Account.ConfigureExchange);
		EndIf;
	EndDo;
	
	CloseWithoutConfirmation = True;
	Close();
	
EndProcedure

&AtClient
Procedure AfterDeletingFiles(AdditionalParameters) Export
	
	Return;
	
EndProcedure

&AtClient
Procedure OutputReport(Command)
	
	RowIndexes = New Array;
	For Each SelectedRow In Items.BankAccounts.SelectedRows Do
		RowIndexes.Add(Object.BankAccounts.IndexOf(Items.BankAccounts.RowData(SelectedRow)));
	EndDo;
	
	UploadReportTable = DisplayReportOnServer(RowIndexes);
	
	If UploadReportTable <> Undefined Then
		UploadReportTable.ReadOnly = True;
		UploadReportTable.Show(NStr("vi = 'Báo cáo tải lên thanh toán';
									|ru = 'Отчет о выгрузке платежей';
									|en = 'Payment export report'; fa = 'Payment export report';
									|it = 'Отчет о выгрузке платежей';
									|pl = 'Raport z przesyłania płatności';
									|tr = 'Ödeme yükleme raporu'"));
	EndIf;
	
EndProcedure

&AtServer
Function DisplayReportOnServer(RowIndexes)
	
	DataProcessor = FormAttributeToValue("Object");
	Return DataProcessor.PrintingUploadReport(RowIndexes);
	
EndFunction

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	
	// The account data is being uploaded
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountsForExport.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BankAccounts.Exporting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Kết xuất ...';
													|ru = 'Выгружается...';
													|en = 'Exporting...'; fa = 'Exporting...';
													|it = 'Выгружается...';
													|pl = 'Exporting...';
													|tr = 'Dışa aktarılıyor...'"));
	
	// The document has not been uploaded to the bank before
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsToExportExportDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentsToExport.ExportDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Date("00010101");
	
	Item.Appearance.SetParameterValue("Text", "-");
	
	// There is an error preventing the document from being uploaded
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsToExport.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentsToExport.HasError");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	
	// Closed accounts in gray
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BankAccounts");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BankAccounts.Closed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	ThereArePaymentErrors = False;
	Filter = New Structure("HasError", True);
	FoundRows = Object.DocumentsToExport.FindRows(Filter);
	ThereArePaymentErrors = Boolean(FoundRows.Count());
	Items.DocumentsToUploadErrorDescription.Visible = ThereArePaymentErrors;
	
EndProcedure

&AtServer
Procedure FillInInvoiceTable()
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.FillInUploadInvoiceTable();
	ValueToFormAttribute(DataProcessor, "Object");
	
	ArrayOfAccounts_ = Object.BankAccounts.Unload().UnloadColumn("Ref");
	AddNumberOfDocumentsToUploadToInvoiceTable(ArrayOfAccounts_);
	
EndProcedure

&AtServer
Procedure AddNumberOfDocumentsToUploadToInvoiceTable(ArrayOfAccounts_)
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	DocumentData.BankAccount AS BankAccount,
	|	COUNT(DISTINCT DocumentData.Ref) AS Count
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND NOT DocumentData.ProcessedByBank
	|	AND DocumentData.PaymentDocumentType IN (
	|		VALUE(Enum.TypesOfPaymentDocuments.PaymentOrder)
	|	)
	|	AND DocumentData.BankAccount IN (&ArrayOfAccounts_)
	|	AND DocumentData.ExportDate = DATETIME(1,1,1)
	|	
	|GROUP BY
	|	DocumentData.BankAccount
	|	
	|UNION ALL
	|	
	|SELECT
	|	DocumentData.BankAccount AS BankAccount,
	|	COUNT(DISTINCT DocumentData.Ref) AS Count
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND NOT DocumentData.ProcessedByBank
	|	AND DocumentData.PaymentDocumentType = VALUE(Enum.TypesOfPaymentDocuments.PaymentDemand)
	|	AND DocumentData.BankAccount IN (&ArrayOfAccounts_)
	|	AND DocumentData.ExportDate = DATETIME(1,1,1)
	|	
	|GROUP BY
	|	DocumentData.BankAccount
	|";
	
	Query.SetParameter("ArrayOfAccounts_", ArrayOfAccounts_);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Table = Result.Unload();
	Table.GroupBy("BankAccount", "Count");
	
	For Each Account In Object.BankAccounts Do
		CountRow = Table.Find(Account.Ref, "BankAccount");
		If CountRow <> Undefined Then
			Account.ForExport = CountRow.Count;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdatePaymentList()
	
	DataProcessor = FormAttributeToValue("Object");
	If DocumentsFilter.Count() Then
		DataProcessor.FillInPaymentTable(DocumentsFilter);
	Else
		DataProcessor.FillInPaymentTable();
	EndIf;
	ValueToFormAttribute(DataProcessor, "Object");
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure FillInPeriodSelectionList_()
	
	PeriodSelectionList = Items.Period.ChoiceList;
	
	PeriodSelectionList.Add(NStr("vi = 'Toàn bộ thời gian';
								|ru = 'Все время';
								|en = 'All time'; fa = 'همه زمان‌ها';
								|it = 'Все время';
								|pl = 'Cały czas';
								|tr = 'Her zaman'"),     NStr("vi = 'Toàn bộ thời gian';
																|ru = 'Все время';
																|en = 'All time'; fa = 'همه زمان‌ها';
																|it = 'Все время';
																|pl = 'Cały czas';
																|tr = 'Her zaman'"));
	PeriodSelectionList.Add("Date_",                     NStr("vi = 'Ngày ...';
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
	Period = NStr("vi = 'Toàn bộ thời gian';
					|ru = 'Все время';
					|en = 'All time'; fa = 'همه زمان‌ها';
					|it = 'Все время';
					|pl = 'Cały czas';
					|tr = 'Her zaman'");
	Object.ExportStartDate = '00010101';
	Object.ExportEndDate = '00010101';
	
EndProcedure

&AtClient
Procedure ProcessInvoiceTagging()
	
	ProcessInvoiceTaggingServer();
	
	UpgradeBasement();

EndProcedure

&AtClient
Procedure ProcessUploadCompletion()
	
	ThereAreFilesToSave = False;
	ThereIsNeedToUpdateListOfPayments = False;
	ThereAreOutstandingTasks = False;
	
	For Each Account In Object.BankAccounts Do
		If Account.SaveFile Then
			ThereAreFilesToSave = True;
			If Account.Check Then
				ThereIsNeedToUpdateListOfPayments = True;
			EndIf;
		EndIf;
	EndDo;
	
	If ThereAreFilesToSave Then
		SaveFiles();
	EndIf;
	
	
	TotalFiles = 0;
	RulesForMergingFiles = New Array;
	For Each Account In Object.BankAccounts Do
		If Account.Exported And Account.ExchangeThroughFile Then
			If Account.ExchangeFormat <> PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
				Account.ExportFileTextAsAString = TextUploadedAsString(Account.FileStorageAddress);
			Else
				Account.ExportFileTextAsAString = TextOfUploadArchiveAsString(Account.FileStorageAddress);
			EndIf;
			If Not ValueIsFilled(Account.RuleOfFileEDIWithBanks) Then
				TotalFiles = TotalFiles + 1;
			Else
				If RulesForMergingFiles.Find(Account.RuleOfFileEDIWithBanks) = Undefined Then
					RulesForMergingFiles.Add(Account.RuleOfFileEDIWithBanks);
					TotalFiles = TotalFiles + 1;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	ProcessUploadCompletionOnServer(ThereIsNeedToUpdateListOfPayments, TotalFiles);
	
	If ThereIsNeedToUpdateListOfPayments Then
		UpgradeBasement();
	EndIf;
	
	CheckCounter = 0;
	Checking = True;
	AttachIdleHandler("Attachable_CheckUploadFiles", 1, True);
	
EndProcedure

&AtClient
Procedure EnableWaitingForBackgroundTasks();
	
	DischargeStreams = New Map;
	
	For Each Account In Object.BankAccounts Do
		
		If ValueIsFilled(Account.DataExportedID) Then
			
			Stream = DischargeStreams.Get(Account.DataExportedID); // Array
			
			If Stream = Undefined Then
				
				AccountList = New Array;
				AccountList.Add(Account);
				DischargeStreams.Insert(Account.DataExportedID, AccountList);
				
			Else
				Stream.Add(Account);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each CurrentThread In DischargeStreams Do
		
		Account = CurrentThread.Value[0];
		
		If ValueIsFilled(Account.UploadData_0)
			And IsTempStorageURL(Account.UploadData_0) Then
			
			BackgroundJob = GetFromTempStorage(Account.UploadData_0);
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = False;
			CallbackOnCompletion = New CallbackDescription("ProcessEndOfUploadNotification", ThisObject, CurrentThread.Value);
		
			TimeConsumingOperationsClient.WaitCompletion(
				BackgroundJob, CallbackOnCompletion, IdleParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessEndOfUploadNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		For Each Account In AdditionalParameters Do
			
			Account.Exporting = False;
			Account.SaveFile = True;
			Account.UploadData_0 = "";
			
		EndDo;
		
		ProcessUploadCompletion();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessUploadCompletionOnServer(ThereIsNeedToUpdateListOfPayments, TotalFiles)
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.RecordDatePaymentsWereUploaded();
	
	If ThereIsNeedToUpdateListOfPayments Then
		DataProcessor.FillInPaymentTable();
	EndIf;
	
	ValueToFormAttribute(DataProcessor, "Object");
	SetVisibility1();
	
	// Final procedures - clearing paths and report output
	FilterCheck = New Structure("Check", True);
	FilterExported = New Structure("Exported", True);
	
	Items.DecorationUploaded.Title = "";
	If TotalFiles > 0 Then
		
		DeclinationUnloaded = NStr("vi = 'Kết xuất, Kết xuất, Kết xuất';
									|ru = 'Выгружен, Выгружено, Выгружено';
									|en = 'Exported, Exported, Exported'; fa = 'Exported, Exported, Exported';
									|it = 'Выгружен, Выгружено, Выгружено';
									|pl = 'Rozładowany, rozładowano, rozładowano';
									|tr = 'Dışa aktarıldı, Dışa aktarıldı, Dışa aktarıldı'");
		WasExported = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(TotalFiles, DeclinationUnloaded);
		WasExported = TrimAll(StrReplace(WasExported, TotalFiles + " ", ""));
		
		DeclinationOfFiles = NStr("vi = 'tập tin, tập tin, tập tin';
									|ru = 'файл, файла, файлов';
									|en = 'file, file, files'; fa = 'file, file, files';
									|it = 'файл, файла, файлов';
									|pl = 'plik, pliku, plików';
									|tr = 'dosya, dosya, dosya'");
		Files_ = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(TotalFiles, DeclinationOfFiles);
		
		If AbilityToSelectFiles Then
			Items.DecorationUploaded.Title = WasExported + " " + Files_ + ". " +
				NStr("vi = 'Vì mục đích bảo mật khi tiến hành kiểm soát sự tương ứng của các tệp kết xuất và dữ liệu chương trình, nến biểu mẫu này đang mở. Khi đóng biểu mẫu này, các tệp sẽ bị xóa.
					|Hãy đảm bảo kiểm tra tính chính xác các mục tin thanh toán trong chương trình Client Bank.';
					|ru = 'В целях безопасности проводится контроль соответствия файлов выгрузки и данных программы, пока эта форма открыта. При закрытии этой формы файлы будут удалены.
					|Обязательно проверьте правильность платежных реквизитов в программе Клиент банка.';
					|en = 'For safety reasons, it is controlled whether export files correspond to the application data while this form is opened. When closing this form, the files will be deleted.
					|Check whether payment details in the Client Bank application are correct.'; fa = 'For safety reasons, it is controlled whether export files correspond to the application data while this form is opened. When closing this form, the files will be deleted.
					|Check whether payment details in the Client Bank application are correct.';
					|it = 'В целях безопасности проводится контроль соответствия файлов выгрузки и данных программы, пока эта форма открыта. При закрытии этой формы файлы будут удалены.
					|Обязательно проверьте правильность платежных реквизитов в программе Клиент банка.';
					|pl = 'Ze względów bezpieczeństwa zgodność plików do wysyłania i danych programu jest monitorowana, gdy ten formularz jest otwarty. Po zamknięciu tego formularza pliki zostaną usunięte.
					|Sprawdź dokładność szczegółów płatności w programie klienta banku.';
					|tr = 'Güvenlik amacıyla bu form açıkken yükleme dosyalarının ve program verilerinin uygunluğu kontrol edilir. Bu form kapatılırsa dosyalar silinecektir.
					|Bankanın İstemci programında ödeme detaylarının doğruluğunun kontrol edildiğinden emin ol.'");
		Else
			Items.DecorationUploaded.Title = WasExported + " " + Files_ + ". " +
				NStr("vi = 'Chưa tiến hành kiểm soát sự tương ứng giữa các tệp kết xuất và dữ liệu chương trình. Nhằm mục đích bảo mật, cần cài đặt phần mở rộng để làm việc với tệp.
					|Hãy kiểm tra tính chính xác của các mục tin thanh toán trong chương trình Client bank.';
					|ru = 'Контроль соответствия файлов выгрузки и данных программы не производится. В целях безопасности требуется установить расширение для работы с файлами.
					|Обязательно проверьте правильность платежных реквизитов в программе Клиент банка.';
					|en = 'It is not controlled whether export files correspond to the application data. For safety reasons, install 1C:Enterprise Extension.
					|Check whether payment details in the Client Bank application are correct.'; fa = 'It is not controlled whether export files correspond to the application data. For safety reasons, install 1C:Enterprise Extension.
					|Check whether payment details in the Client Bank application are correct.';
					|it = 'Контроль соответствия файлов выгрузки и данных программы не производится. В целях безопасности требуется установить расширение для работы с файлами.
					|Обязательно проверьте правильность платежных реквизитов в программе Клиент банка.';
					|pl = 'Kontrola zgodności plików przesyłania i danych programu nie jest wykonywana. Ze względów bezpieczeństwa musisz zainstalować rozszerzenie do pracy z plikami. 
					|Sprawdź szczegóły płatności w programie klienta banku.';
					|tr = 'Yükleme dosyalarının ve program verilerinin uyumluluğu üzerinde herhangi bir kontrol yoktur. Güvenlik nedeniyle dosyalarla çalışmak için bir uzantın yüklenmesi gerekmektedir.
					|Bankanın İstemci programında ödeme detaylarının doğruluğunun kontrol edilmesinden emin ol.'");
		EndIf;
	EndIf;
	
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
				AmountToExport = AmountToExport + Format(AmountByPayments.Value, "NFD=2") + " " + String(AmountByPayments.Key) + ", ";
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
Procedure SelectingFileWhenUploading(Account)
	
	FileDialog = New FileDialog(FileDialogMode.Save);
	If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
		FileDialog.Filter              = NStr("vi = 'Tệp XML (*.xml)|*.xml';
												|ru = 'XML файл (*.xml)|*.xml';
												|en = 'XML file (*.xml)|*.xml'; fa = 'XML file (*.xml)|*.xml';
												|it = 'XML файл (*.xml)|*.xml';
												|pl = 'Plik XML (*.xml)|*.xml';
												|tr = 'XML dosya (*.xml)|*.xml'");
		FileDialog.DefaultExt          = "xml";
	ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c")
		Or Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.MT940") Then
		FileDialog.Filter              = NStr("vi = 'Tệp văn bản (*.txt)|*.txt';
												|ru = 'Текстовый файл (*.txt)|*.txt';
												|en = 'Text file (*.txt)|*.txt'; fa = 'Text file (*.txt)|*.txt';
												|it = 'Текстовый файл (*.txt)|*.txt';
												|pl = 'Plik tekstowy (*.txt)|*.txt';
												|tr = 'Metin dosyası (*.txt)|*.txt'");
		FileDialog.DefaultExt          = "txt";
	ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
		FileDialog.Filter              = NStr("vi = 'Tệp nén zip (*.zip)|*.zip';
												|ru = 'Zip-архив (*.zip)|*.zip';
												|en = 'ZIP archive (*.zip)|*.zip'; fa = 'ZIP archive (*.zip)|*.zip';
												|it = 'Zip-архив (*.zip)|*.zip';
												|pl = 'Archiwum zip (*.zip)|*.zip';
												|tr = 'Zip-arşiv (*.zip)|*.zip'");
		FileDialog.DefaultExt          = "zip";
	EndIf;
	FileDialog.Title               =
		StrTemplate(NStr("vi = 'Chỉ định tên tệp để tải dữ liệu lên tài khoản %1';
						|ru = 'Укажите имя файла для выгрузки данных по счету %1';
						|en = 'Specify a file name for data export by %1 account'; fa = 'Specify a file name for data export by %1 account';
						|it = 'Укажите имя файла для выгрузки данных по счету %1';
						|pl = 'Podaj nazwę pliku do przesłania danych konta %1';
						|tr = '%1 hesabına veri yüklemek için dosya adı belirt'"), String(Account.Ref));
	FileDialog.Preview = False;
	FileDialog.FilterIndex           = 0;
	FileDialog.FullFileName          = StrReplace(String(New UUID), "-", "");
	FileDialog.CheckFileExistence = False;
	
	AddlParameters = New Structure;
	AddlParameters.Insert("AccountID", Account.GetID());
	
	CallbackDescription = New CallbackDescription("SelectingFileWhenUploadingCompletion", ThisForm, AddlParameters);
	FileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectingFileWhenUploadingCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And TypeOf(Result) = Type("Array")
		And Result.Count() > 0 Then
		
		FileName = Result[0];
		Account = Object.BankAccounts.FindByID(AdditionalParameters.AccountID);
		
		If Account <> Undefined Then
			Account.ConfigureExchange = FileName;
			UploadPaymentsAfterSelectingFile(AdditionalParameters.AccountID);
			ProcessUploadCompletion();
			EnableWaitingForBackgroundTasks();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoosingExchangeFileWithBank(CurrentData)
	
	If CurrentData.DirectExchange Then
		FileName = "";
	Else
		
		If CurrentData.ImportFromDirectory Then
			FileName = "";
		Else
			FileName = CurrentData.ConfigureExchange;
		EndIf;
		
	EndIf;
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	If CurrentData.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
		FileDialog.Filter              = NStr("vi = 'Tệp XML (*.xml)|*.xml';
												|ru = 'XML файл (*.xml)|*.xml';
												|en = 'XML file (*.xml)|*.xml'; fa = 'XML file (*.xml)|*.xml';
												|it = 'XML файл (*.xml)|*.xml';
												|pl = 'Plik XML (*.xml)|*.xml';
												|tr = 'XML dosya (*.xml)|*.xml'");
		FileDialog.DefaultExt          = "xml";
	ElsIf CurrentData.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
		FileDialog.Filter              = NStr("vi = 'Tệp nén zip (*.zip)|*.zip';
												|ru = 'Zip-архив (*.zip)|*.zip';
												|en = 'ZIP archive (*.zip)|*.zip'; fa = 'ZIP archive (*.zip)|*.zip';
												|it = 'Zip-архив (*.zip)|*.zip';
												|pl = 'Archiwum zip (*.zip)|*.zip';
												|tr = 'Zip-arşiv (*.zip)|*.zip'");
		FileDialog.DefaultExt          = "zip";
	Else
		FileDialog.Filter              = NStr("vi = 'Tệp văn bản (*.txt)|*.txt';
												|ru = 'Текстовый файл (*.txt)|*.txt';
												|en = 'Text file (*.txt)|*.txt'; fa = 'Text file (*.txt)|*.txt';
												|it = 'Текстовый файл (*.txt)|*.txt';
												|pl = 'Plik tekstowy (*.txt)|*.txt';
												|tr = 'Metin dosyası (*.txt)|*.txt'");
		FileDialog.DefaultExt          = "txt";
	EndIf;
	FileDialog.Title               = NStr("vi = 'Chỉ định tên tệp để tải lên dữ liệu';
											|ru = 'Укажите имя файла для выгрузки данных';
											|en = 'Specify a file name for data export'; fa = 'Specify a file name for data export';
											|it = 'Укажите имя файла для выгрузки данных';
											|pl = 'Określ nazwę pliku, aby przesłać dane';
											|tr = 'Veri indirimi için dosya adını belirt'");
	FileDialog.Preview = False;
	FileDialog.FilterIndex           = 0;
	FileDialog.FullFileName          =
		?(IsBlankString(FileName), StrReplace(String(New UUID), "-", ""), FileName);
	FileDialog.CheckFileExistence = False;
	
	CallbackDescription = New CallbackDescription(
		"SelectingFileCompletion",
		ThisObject,
		New Structure("CurrentData", CurrentData));
	
	FileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectingFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	Else
		AdditionalParameters.CurrentData.ConfigureExchange = SelectedFiles[0];
		AdditionalParameters.CurrentData.RuleOfFileEDIWithBanks = SelectedFiles[0];
		AdditionalParameters.CurrentData.DirectExchange = False;
		If Not AdditionalParameters.CurrentData.Check Then
			AttachIdleHandler("ProcessInvoiceTagging", 0.1, True);
		EndIf;
		AdditionalParameters.CurrentData.Check = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFiles()
	
	UnloadedInvoices = "";
	
	For Each Account In Object.BankAccounts Do
		
		If Account.SaveFile And IsTempStorageURL(Account.FileStorageAddress) Then
			
			UploadData_0 = GetFromTempStorage(Account.FileStorageAddress);
			If TypeOf(UploadData_0) = Type("BinaryData") Then
				
				If AbilityToSelectFiles Then
					
					UploadFileToClient(Account);
					
				Else // Web client without file extension
					
					Try
						If ValueIsFilled(Account.ConfigureExchange) Then
							GetFile(Account.FileStorageAddress, Account.ConfigureExchange, True);
						Else
							GetFile(Account.FileStorageAddress, StrReplace(String(New UUID), "-", ""), True);
						EndIf;
						Account.Exported = True;
						
					Except
						MessageTemplate = NStr("vi = 'Khi ghi lại tệp đã xảy ra lỗi
							|%1';
							|ru = 'При записи файла возникла ошибка
							|%1';
							|en = 'An error occurred when saving file 
							|%1'; fa = 'An error occurred when saving file 
							|%1';
							|it = 'При записи файла возникла ошибка
							|%1';
							|pl = 'Wystąpił błąd podczas zapisywania do pliku
							|%1';
							|tr = 'Dosya kaydı sırasında hata oluştu
							|%1'");
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
							BriefErrorDescription(ErrorInfo()));
						
						CommonClientServer.MessageToUser(MessageText);
					EndTry;
				EndIf;
				
				UnloadedInvoices = UnloadedInvoices + String(Account.Ref) + "
				|";
			EndIf;
			
			Account.SaveFile = False;
		EndIf;
	EndDo;
	
	If ValueIsFilled(UnloadedInvoices) Then
		ShowUserNotification(,, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã kết xuất vào tệp dữ liệu về hóa đơn
			|%1';
			|ru = 'Выгружены в файлы данные по счетам
			|%1';
			|en = 'Data on accounts
			|%1 are exported to files'; fa = 'Data on accounts
			|%1 are exported to files';
			|it = 'Выгружены в файлы данные по счетам
			|%1';
			|pl = 'Dane na kontach są przesyłane do plików
			|%1';
			|tr = 'Dosyalara yüklenen hesaplarla ilgili veriler
			|%1'"),
			UnloadedInvoices)
		);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadFileToClient(Account)
	
	AdditionalParameters = New Structure("Account", Account);
	CallbackDescription = New CallbackDescription("UploadFileToCreateFileClient", ThisObject, AdditionalParameters);
	
	File = New File();
	File.BeginInitialization(CallbackDescription, Account.ConfigureExchange);
	
EndProcedure

&AtClient
Procedure UploadFileToCreateFileClient(File, AdditionalParameters) Export
	
	AdditionalParameters.Insert("File", File);
	CallbackDescription = New CallbackDescription("UploadFileToClientExistenceCheck", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

&AtClient
Procedure UploadFileToClientExistenceCheck(Exists, AdditionalParameters) Export
	
	File = AdditionalParameters.File;
	AdditionalParameters.Insert("FileExists", Exists);
	CallbackDescription = New CallbackDescription("UploadFileOnClientCheckingForDirectory", ThisObject, AdditionalParameters);
	If Exists Then
		File.BeginCheckingIsDirectory(CallbackDescription);
	Else
		RunCallback(CallbackDescription, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadFileOnClientCheckingForDirectory(IsDirectory, AdditionalParameters) Export
	
	Account = AdditionalParameters.Account;
	
	FileName = Account.ConfigureExchange;
	
	If Right(TrimAll(Account.ConfigureExchange), 1) = "\"
		Or Right(TrimAll(Account.ConfigureExchange), 1) = "/"
		Or IsDirectory Then
		
		Extension = "";
		
		If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
			Extension = ".xml";
		ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
			Extension = ".txt";
		ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
			Extension = ".zip";
		EndIf;
		
		FileName = Account.ConfigureExchange
				+ ?(Right(TrimAll(Account.ConfigureExchange), 1) = "\" Or Right(TrimAll(Account.ConfigureExchange), 1) = "/", "", "\")
				+ StrReplace(String(New UUID), "-", "")
				+ Extension;
		
	EndIf;
	
	CallbackDescription = New CallbackDescription("UploadFileToClientCompletion", ThisObject, AdditionalParameters);
	FileSystemClient.SaveFile(CallbackDescription, Account.FileStorageAddress, FileName);
	
EndProcedure

&AtClient
Procedure UploadFileToClientCompletion(ObtainedFiles, AdditionalParameters) Export
	
	AdditionalParameters.Account.Exported = True;
	
	ProcessUploadCompletion();
	
EndProcedure

&AtServer
Procedure SetUpSupportForBankingAndTreasurySupport()

	SupportOfBankingAndTreasurySupport = GetFunctionalOption("SupportOfBankingAndTreasuryStateContracts");
	Items.GroupCatalogOfUploadingSupportingDocuments.Visible = SupportOfBankingAndTreasurySupport;


EndProcedure


#Region FilesOperations

&AtClient
Procedure Attachable_EnableFileWorkExtensionAndSelectFile()
	
	MessageText = NStr("vi = 'Để chọn một tệp, Cần cài đặt phần mở rộng tệp.';
						|ru = 'Для выбора файла необходимо установить расширение работы с файлами.';
						|en = 'To select a file, install 1C:Enterprise Extension.'; fa = 'To select a file, install 1C:Enterprise Extension.';
						|it = 'Для выбора файла необходимо установить расширение работы с файлами.';
						|pl = 'Aby wybrać plik, musisz zainstalować rozszerzenie obsługi plików.';
						|tr = 'Dosya seçimi için dosya yönetimi uzantısını yükle'");
	
	CallbackDescription = New CallbackDescription("SelectFileCompletion", ThisObject);
	CommonClient.ShowFileSystemExtensionInstallationQuestion(CallbackDescription, MessageText);
	
EndProcedure

&AtClient
Procedure SelectFileCompletion(Result, AdditionalParameters) Export
	
	AbilityToSelectFiles = Result;
	
	If AbilityToSelectFiles Then
		CurrentData = Items.BankAccounts.CurrentData;
		ChoosingExchangeFileWithBank(CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableFileExtensionAndSelectFileWhenUploading(Account)
	
	MessageText = NStr("vi = 'Để chỉ định tệp để tải lên thanh toán vào tài khoản %1, Cần cài đặt tiện ích mở rộng tệp.';
						|ru = 'Для указания файла выгрузки платежей по счету %1 необходимо установить расширение работы с файлами.';
						|en = 'To specify a payment export file for account %1, install 1C:Enterprise Extension.'; fa = 'To specify a payment export file for account %1, install 1C:Enterprise Extension.';
						|it = 'Для указания файла выгрузки платежей по счету %1 необходимо установить расширение работы с файлами.';
						|pl = 'Aby określić plik do pobrania płatności na koncie, %1 należy zainstalować pracę rozszerzenia z plikami.';
						|tr = '%1 hesabındaki ödemeleri yüklemek için dosyayı belirtmek üzere, dosyalarla çalışmak için uzantıyı yüklemeniz gerekir.'");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Account.Description);
	
	CallbackDescription = New CallbackDescription("SelectFileWhenUploadingEnd", ThisObject, Account);
	CommonClient.ShowFileSystemExtensionInstallationQuestion(CallbackDescription, MessageText, False);
	
EndProcedure

&AtClient
Procedure SelectFileWhenUploadingEnd(Result, AdditionalParameters) Export
	
	AbilityToSelectFiles = Result;
	
	If AbilityToSelectFiles Then
		SelectingFileWhenUploading(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadPaymentsAfterSelectingFile(AccountID)
	
	Account = Object.BankAccounts.FindByID(AccountID);
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.UnloadAccountPayments(Account, ThisForm.UUID);
	
EndProcedure

&AtServer
Procedure ProcessInvoiceTaggingServer()
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		If Account.Check Then
			Object.AccountList.Add(Account.Ref);
		EndIf;
	EndDo;
	
	UpdatePaymentList();
	
EndProcedure

&AtClient
Function TextUploadedAsString(Val SourceDataAddress)
	
	#If WebClient Or MobileClient Then
		Return "";
	#Else
		BinaryDataOfSourceFile = GetFromTempStorage(SourceDataAddress); // BinaryData
		TempFileName = GetTempFileName();
		BinaryDataOfSourceFile.Write(TempFileName);
		
		TextDocument = New TextDocument;
		TextDocument.Read(TempFileName);
		StringText_1 = TextDocument.GetText();
		BeginDeletingFiles(New CallbackDescription("AfterDeletingFiles", ThisObject), TempFileName);
		
		Return StringText_1;
	#EndIf
	
EndFunction

&AtClient
Function TextOfUploadArchiveAsString(Val SourceDataAddress)
	
	#If WebClient Or MobileClient Then
		Return "";
	#Else
		
		ExportFileTextAsAString = "";
		BinaryDataOfSourceFile = GetFromTempStorage(SourceDataAddress);
		ExportFileTextAsAString = Base64String(BinaryDataOfSourceFile);
		
		Return ExportFileTextAsAString;
	#EndIf
	
EndFunction

&AtClient
Procedure Attachable_CheckUploadFiles()
	
	For Each Account In Object.BankAccounts Do
		If Account.Exported And Account.ExchangeThroughFile And ValueIsFilled(Account.ConfigureExchange) Then
			CallbackDescription = New CallbackDescription("RunCheckAgain", ThisObject, Account);
			CheckFilesOnClient(Account, CallbackDescription);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure RunCheckAgain(Result, AdditionalParameters) Export
	
	If Not Checking Then
		Return;
	EndIf;
	
	CheckCounter = CheckCounter - 1;
	
	If Result = "VerificationCompletedSuccessfully" Then
		
		If CheckCounter = 0 Then
			#If WebClient Then
				Interval = 0.5;
			#Else
				RNG = New RandomNumberGenerator();
				Divisor = RNG.RandomNumber(1, 10);
				Interval = Round(2 / Divisor, 1);
			#EndIf
			AttachIdleHandler("Attachable_CheckUploadFiles", Interval, True);
		EndIf;
		
	ElsIf Result = "FilesAreChanged" Then
		
		Checking = False;
		CheckCounter = 0;
		DetachIdleHandler("Attachable_CheckUploadFiles");
		
		CheckParameters = New Structure;
		CheckParameters.Insert("Result", Result);
		
		OpenForm("DataProcessor.EDIWithBanks.Form.SecurityControlOfPaymentExportToBank",
			CheckParameters,
			ThisObject,
			"SecurityControlOfPaymentExportToBank",,,,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckFilesOnClient(Account, NotificationAfterVerification)
	
	CheckCounter = CheckCounter + 1;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationAfterVerification", NotificationAfterVerification);
	AdditionalParameters.Insert("Account", Account);
	
	CallbackDescription = New CallbackDescription("CheckFilesOnClientThisIsDirectory", ThisObject, AdditionalParameters);
	
	File = New File(Account.ConfigureExchange);
	File.BeginCheckingIsDirectory(CallbackDescription);
	
EndProcedure

&AtClient
Procedure CheckFilesOnClientThisIsDirectory(IsDirectory, AdditionalParameters) Export
	
	If Not IsDirectory Then
		CheckFileOnClient(AdditionalParameters.Account, AdditionalParameters.NotificationAfterVerification)
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckFileOnClient(Account, NotificationAfterVerification)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationAfterVerification", NotificationAfterVerification);
	AdditionalParameters.Insert("Account", Account);
	CallbackDescription = New CallbackDescription("CheckFileOnFileCreationClient", ThisObject, AdditionalParameters);
	
	File = New File();
	File.BeginInitialization(CallbackDescription, Account.ConfigureExchange);
	
EndProcedure

&AtClient
Procedure CheckFileOnFileCreationClient(File, AdditionalParameters) Export
	
	CallbackDescription = New CallbackDescription("CheckFileOnClientExistenceCheck", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

&AtClient
Procedure CheckFileOnClientExistenceCheck(Exists, AdditionalParameters) Export
	
	If Exists Then
		#If WebClient Or MobileClient Then
			CallbackDescription = AdditionalParameters.NotificationAfterVerification;
			RunCallback(CallbackDescription, "FilesDeleted");
		#Else
			If AdditionalParameters.Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
				BinaryData = New BinaryData(AdditionalParameters.Account.ConfigureExchange);
				FileData = Base64String(BinaryData);
				AdditionalParameters.Insert("ExtractTextDocument", FileData);
				CheckFileOnClientAfterReadingFile(AdditionalParameters);
			Else
				ExtractTextDocument = New TextDocument;
				AdditionalParameters.Insert("ExtractTextDocument", ExtractTextDocument);
				CallbackDescription = New CallbackDescription("CheckFileOnClientAfterReadingFile", ThisObject, AdditionalParameters);
				ExtractTextDocument.BeginReading(CallbackDescription, AdditionalParameters.Account.ConfigureExchange);
			EndIf;
		#EndIf
	Else
		CallbackDescription = AdditionalParameters.NotificationAfterVerification;
		RunCallback(CallbackDescription, "FilesDeleted");
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckFileOnClientAfterReadingFile(AdditionalParameters) Export
	
	If AdditionalParameters.Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
		TextOfFileBeingChecked = AdditionalParameters.ExtractTextDocument;
	Else
		TextOfFileBeingChecked = AdditionalParameters.ExtractTextDocument.GetText();
	EndIf;
	
	If CommonClientServer.IsWebClient() Then
		TextOfUnloadingSourceFileAsLine = TextUploadedAsString(AdditionalParameters.Account.FileStorageAddress);
	Else
		TextOfUnloadingSourceFileAsLine = AdditionalParameters.Account.ExportFileTextAsAString;
	EndIf;
	Result = ?(TextOfUnloadingSourceFileAsLine = TextOfFileBeingChecked, "VerificationCompletedSuccessfully", "FilesAreChanged");
	
	AdditionalParameters.Insert("ExtractTextDocument", Undefined);
	
	CallbackDescription = AdditionalParameters.NotificationAfterVerification;
	RunCallback(CallbackDescription, Result);
	
EndProcedure

#EndRegion

AmountsOfPaymentsToBeUploaded = New Map;

#EndRegion
