#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BaseCurrency = Catalogs.Currencies.FindByCode("978");
	If Not ValueIsFilled(BaseCurrency) Then
		Common.MessageToUser(
			NStr("vi = 'Để sử dụng kết nhập tỷ giá từ Website Ngân hàng trung ương Châu Âu, trong danh mục ""Tiền tệ"" cần nhập tiền tệ Euro (EUR) có mã 978';
				|ru = 'Для использования загрузки курсов с сайта ЕЦБ, в справочнике ""Валюты"" необходимо завести валюту Евро (EUR) с кодом 978';
				|en = 'To use exchange rate import from the ECB website, enter Euro (EUR) currency with code 978 in the ""Currencies"" catalog'; fa = 'To use exchange rate import from the ECB website, enter Euro (EUR) currency with code 978 in the ""Currencies"" catalog';
				|it = 'Per poter scaricare i tassi di cambio dal sito della BCE, nel catalogo ""Valute"" è necessario inserire la valuta Euro (EUR) con codice 978';
				|pl = 'Aby używać pobierania kursów walut ze strony EBC, w katalogu ""Waluty"" należy dodać walutę Euro (EUR) z kodem 978';
				|tr = 'AMB web sitesinden kur indirmeyi kullanmak için, ""Para Birimleri"" kataloğunda 978 koduyla Euro (EUR) para birimi girilmeli'"));
		Cancel = True;
		Return;
	EndIf;

	SetConditionalAppearance();
	
	If Not Parameters.Property("OpeningFromList") Then
		If ProcessingOfExchangeRatesTM.RelativeCoursesAreRelevant(BaseCurrency) Then
			InformThatTheCoursesAreUpToDate = True;
			Return;
		EndIf;
	EndIf;
	
	FillInCurrency();
	
	// The beginning and end of the course loading period.
	Object.ImportPeriodEnd = BegOfDay(CurrentSessionDate());
	Object.StartOfUploadingPeriod = Object.ImportPeriodEnd;
	MinDate = BegOfYear(Object.ImportPeriodEnd);
	For Each Currency In Object.ListOfCurrencies Do
		If ValueIsFilled(Currency.DateOfCourse) And Currency.DateOfCourse < Object.StartOfUploadingPeriod Then
			If Currency.DateOfCourse < MinDate Then
				Object.StartOfUploadingPeriod = MinDate;
				Break;
			EndIf;
			Object.StartOfUploadingPeriod = Currency.DateOfCourse;
		EndIf;
	EndDo;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If InformThatTheCoursesAreUpToDate Then
		ProcessingOfExchangeRatesTMClient.NotifyRatesUpToDate();
		Cancel = True;
		Return;
	EndIf;
	
	AttachIdleHandler("CheckListOfDownloadedCurrencies", 0.1, True);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfCurrencies

&AtClient
Procedure ListOfCurrenciesSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SwitchDownloads();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportCurrenciesRates(Command)
	StartLoadingCurrencyExchangeRates();
EndProcedure

&AtClient
Procedure SelectAllCurrencies(Command)
	SetSelection_(True);
	SetItemsAvailability();
EndProcedure

&AtClient
Procedure RemoveTheSelection(Command)
	SetSelection_(False);
	SetItemsAvailability();
EndProcedure

&AtClient
Procedure ToImportOnChange(Item)
	SetItemsAvailability();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfCourse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ListOfCurrencies.DateOfCourse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New StandardBeginningDate(Date('19800101000000'));

	Item.Appearance.SetParameterValue("Text", "");

EndProcedure

&AtClient
Procedure SetSelection_(Selection)
	For Each Currency In Object.ListOfCurrencies Do
		Currency.ToImport = Selection;
	EndDo;
EndProcedure

&AtServer
Procedure FillInCurrency()
	
	// Filling in the tabular part with a list of currencies whose exchange rate does not depend on the exchange rate of other currencies.
	ListOfCurrencies = Object.ListOfCurrencies;
	ListOfCurrencies.Clear();
	
	CurrenciesToImport = ProcessingOfExchangeRatesTM.CurrenciesToImport();
	
	For Each CurrencyElement In CurrenciesToImport Do
		AddCurrencyToList(CurrencyElement);
	EndDo;
	
EndProcedure

&AtServer
Procedure AddCurrencyToList(Currency)
	
	// Adding an entry to the list of currencies.
	NewRow = Object.ListOfCurrencies.Add();
	
	// Filling in information about the exchange rate based on the currency reference.
	FillInTableRowDataBasedOnCurrency(NewRow, Currency);
	
	NewRow.ToImport = True;
	
EndProcedure

&AtServer
Procedure UpdateInformationInListOfCurrencies()
	
	For Each DataString1 In Object.ListOfCurrencies Do
		CurrencyReference = DataString1.Currency;
		FillInTableRowDataBasedOnCurrency(DataString1, CurrencyReference);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTableRowDataBasedOnCurrency(TableRow, Currency);
	
	CurrencyInformation = Common.ObjectAttributesValues(Currency, "DescriptionFull,Code,Description");
	
	TableRow.Currency = Currency;
	TableRow.CurrencyCode_ = CurrencyInformation.Code;
	TableRow.AlphabeticCode = CurrencyInformation.Description;
	TableRow.Presentation = CurrencyInformation.DescriptionFull;
	
	RateData = ProcessingOfExchangeRatesTM.FillInECBRateDataForCurrency(Currency, BaseCurrency);
	
	If TypeOf(RateData) = Type ("Structure") Then
		TableRow.DateOfCourse       = RateData.DateOfCourse;
		TableRow.CourseNumerator   = RateData.CourseNumerator;
		TableRow.CourseDenominator = RateData.CourseDenominator;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckListOfDownloadedCurrencies()
	If Object.ListOfCurrencies.Count() = 0 Then
		CallbackDescription = New CallbackDescription("CheckListOfDownloadedCurrenciesCompletion", ThisObject);
		WarningText = NStr("vi = 'Trong danh sách tiền tệ không có tiền tệ mà có thể kết nhập tỷ giá từ mạng Internet.';
							|ru = 'В справочнике валют отсутствуют валюты, курсы которых можно загружать из сети Интернет.';
							|en = 'The list of currencies contains no currencies whose exchange rates are imported from the internet.'; fa = 'The list of currencies contains no currencies whose exchange rates are imported from the internet.';
							|it = 'Nel catalogo delle valute mancano le valute per le quali è possibile scaricare i tassi di cambio da Internet.';
							|pl = 'W katalogu walut nie ma walut, których kursy można pobierać z sieci Internet.';
							|tr = 'Para birimleri listesi, döviz kurları internetten alınan para birimleri içermiyor.'");
		ShowMessageBox(CallbackDescription, WarningText);
	EndIf;
EndProcedure

&AtClient
Procedure CheckListOfDownloadedCurrenciesCompletion(AdditionalParameters) Export
	Close();
EndProcedure

&AtClient
Procedure SetItemsAvailability()
	
	ThereAreSelectedCurrencies = Object.ListOfCurrencies.FindRows(New Structure("ToImport", True)).Count() > 0;
	Items.FormImportCurrenciesRates.Enabled = ThereAreSelectedCurrencies;
	
EndProcedure

&AtClient
Procedure DisableDownloadingTheExchangeRateOfTheSelectedCurrencyFromTheInternet(Command)
	CurrentData = Items.ListOfCurrencies.CurrentData;
	UncheckDownloadFromInternet(CurrentData.Currency);
	Object.ListOfCurrencies.Delete(CurrentData);
EndProcedure

&AtServer
Procedure UncheckDownloadFromInternet(CurrencyRef)
	BeginTransaction();
	Try
		LockDataForEdit(CurrencyRef);
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.Currencies");
		LockItem.SetValue("Ref", CurrencyRef);
		Block.Lock();
		
		CurrencyObject = CurrencyRef.GetObject();
		CurrencyObject.RateSource = Enums.RateSources.ManualInput;
		CurrencyObject.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

&AtClient
Procedure SwitchDownloads()
	Items.ListOfCurrencies.CurrentData.ToImport = Not Items.ListOfCurrencies.CurrentData.ToImport;
	SetItemsAvailability();
EndProcedure

&AtServer
Function DownloadCourses()
	
	SetPrivilegedMode(True);
	
	ScheduledJob = Metadata.ScheduledJobs.DownloadingECBExchangeRates;
	
	BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Khởi động thủ công: %1';
																							|ru = 'Запуск вручную: %1';
																							|en = 'Manual start: %1'; fa = 'Manual start: %1';
																							|it = 'Avviamento manuale: %1';
																							|pl = 'Ręczne uruchomienie: %1';
																							|tr = 'Manuel başlatma:%1'"),
		ScheduledJob.Synonym);
	
	ImportParameters = New Structure;
	ImportParameters.Insert("BeginOfPeriod", Object.StartOfUploadingPeriod);
	ImportParameters.Insert("EndOfPeriod", Object.ImportPeriodEnd);
	ImportParameters.Insert("ListOfCurrencies", Common.ValueTableToArray(Object.ListOfCurrencies.Unload(
		Object.ListOfCurrencies.FindRows(New Structure("ToImport", True)), "CurrencyCode_,Currency")));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = BackgroundJobDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground(ScheduledJob.MethodName, ImportParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure WhenCourseDownloadIsComplete(Result, AdditionalParameters) Export
	
	Items.Pages.CurrentPage = Items.CurrencyListPage;
	Items.CommandBar.Enabled = True;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription + Chars.LF + NStr("vi = 'Chi tiết xem trong nhật ký sự kiện.';
															|ru = 'Подробности см. в журнале регистрации.';
															|en = 'See the event log for details.'; fa = 'See the event log for details.';
															|it = 'Vedere il registro per i dettagli.';
															|pl = 'Szczegóły zob. w dzienniku rejestracji.';
															|tr = 'Ayrıntılar için olay günlüğüne bakın.'");
	EndIf;
	
	ProcessUploadResult(GetFromTempStorage(Result.ResultAddress));
	
EndProcedure

&AtClient
Procedure ProcessUploadResult(ImportResult1)
	
	ThereAreSuccessfullyUploadedCourses = False;
	WithoutErrors = True;
	
	ErrorsCount = 0;
	
	ErrorList = New Array;
	For Each ImportState In ImportResult1 Do
		If ImportState.OperationStatus Then
			ThereAreSuccessfullyUploadedCourses = True;
		Else
			WithoutErrors = False;
			ErrorsCount = ErrorsCount + 1;
			ErrorList.Add(TrimAll(ImportState.Message) + Chars.LF);
		EndIf;
	EndDo;
	
	If ThereAreSuccessfullyUploadedCourses Then
		UpdateInformationInListOfCurrencies();
		WriteParameters = Undefined;
		ArrayOfCurrenciesToUpdate = New Array;
		For Each TableRow In Object.ListOfCurrencies Do
			ArrayOfCurrenciesToUpdate.Add(TableRow.Currency);
		EndDo;
		Notify("Record_LoadRelativeExchangeRates", WriteParameters, ArrayOfCurrenciesToUpdate);
		ProcessingOfExchangeRatesTMClient.NotifyRatesAreUpdated();
	EndIf;
	
	If WithoutErrors Then
		Close();
		Return;
	EndIf;
	
	ErrorPresentation = TrimAll(StrConcat(ErrorList, Chars.LF));
	If ErrorsCount > 1 Then
		Buttons = New ValueList;
		Buttons.Add("MoreDetails", NStr("vi = 'Chi tiết...';
										|ru = 'Подробнее...';
										|en = 'More...'; fa = 'More...';
										|it = 'Dettagliatamente...';
										|pl = 'More...';
										|tr = 'Ayrıntılar...'"));
		Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Continue';
									|tr = 'Devam et'"));
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể kết nhập tỷ giá tiền tệ từ Ngân hàng trung ương Châu Âu (%1).';
																					|ru = 'Не удалось загрузить курсы валют ЕЦБ (%1).';
																					|en = 'Cannot import currency ECB exchange rates (%1).'; fa = 'Cannot import currency ECB exchange rates (%1).';
																					|it = 'Download dei tassi di cambio delle valute della BCE fallito (%1).';
																					|pl = 'Nie udało się pobrać kursów walut EBC (%1).';
																					|tr = 'AMB döviz kurları yüklenemedi (%1).'"), ErrorsCount);
		CallbackDescription = New CallbackDescription("ProcessUploadResultWhenAnsweringQuestion", ThisObject, ErrorPresentation);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	Else
		ShowMessageBox(, ErrorPresentation);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessUploadResultWhenAnsweringQuestion(QuestionResult, ErrorPresentation) Export
	If QuestionResult <> "MoreDetails" Then
		Return;
	EndIf;
	
	OpenForm("DataProcessor.DownloadingECBExchangeRates.Form.ErrorsMessages", New Structure("Text", ErrorPresentation));	
EndProcedure

&AtClient
Procedure StartLoadingCurrencyExchangeRates()
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.StartOfUploadingPeriod) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa đặt ngày đầu kỳ kết nhập.';
				|ru = 'Не задана дата начала периода загрузки.';
				|en = 'Please specify the start date of the import period.'; fa = 'Please specify the start date of the import period.';
				|it = 'Non è indicata la data di inizio del periodo di download.';
				|pl = 'Nie zadano daty rozpoczęcia okresu pobierania.';
				|tr = 'Lütfen, içe aktarma döneminin başlangıç tarihini belirt.'"),
			,
			"Object.StartOfUploadingPeriod");
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.ImportPeriodEnd) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa đặt ngày cuối kỳ kết nhập.';
				|ru = 'Не задана дата окончания периода загрузки.';
				|en = 'Import period end date is not set.'; fa = 'Import period end date is not set.';
				|it = 'Non è indicata la data di fine del periodo di download.';
				|pl = 'Nie zadano daty zakończenia okresu pobierania.';
				|tr = 'Lütfen içe aktarma döneminin bitiş tarihini belirt.'"),
			,
			"Object.ImportPeriodEnd");
		Return;
	EndIf;
	
	CourseLoadingOperation = DownloadCourses();
	
	Items.Pages.CurrentPage = Items.ThePageIsLoadingCourses;
	Items.CommandBar.Enabled = False;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("WhenCourseDownloadIsComplete", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(CourseLoadingOperation, CallbackDescription, IdleParameters);
	
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
