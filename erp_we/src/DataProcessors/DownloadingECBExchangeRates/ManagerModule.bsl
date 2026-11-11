#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure ImportActualRate(ImportParameters = Undefined, ResultAddress = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DownloadingECBExchangeRates);
	
	EventName = EventLogEventName();
	
	WriteLogEvent(EventName, EventLogLevel.Information, , ,
		NStr("vi = 'Bắt đầu kết nhập thường kỳ tỷ giá hối đoái từ Ngân hàng trung ương Châu Âu';
			|ru = 'Начата регламентная загрузка курсов валют ЕЦБ';
			|en = 'Scheduled import of ECB exchange rates is started'; fa = 'Scheduled import of ECB exchange rates is started';
			|it = 'Download periodico dei tassi di cambio delle valute della BCE avviato';
			|pl = 'Rozpoczęto pobieranie kursów walut EBC';
			|tr = 'AMB döviz kurları programlı indirilmesi başlandı'"));
		
	BaseCurrency = Catalogs.Currencies.FindByCode("978");
	If Not ValueIsFilled(BaseCurrency) Then
		WriteLogEvent(EventName, EventLogLevel.Error,,,
		NStr("vi = 'Khi kết nhập thường kỳ tỷ giá hối đoái từ Ngân hàng trung ương Châu Âu, đã xảy ra lỗi. Trong danh mục ""Tiền tệ"" không có Euro (EUR).';
			|ru = 'Во время регламентной загрузки курсов валют ЕЦБ возникли ошибки. В справочнике ""Валюты"" отсутсвует Евро (EUR).';
			|en = 'Errors occurred while running scheduled import of ECB exchange rates. There is no Euro (EUR) in the ""Currencies"" catalog.'; fa = 'Errors occurred while running scheduled import of ECB exchange rates. There is no Euro (EUR) in the ""Currencies"" catalog.';
			|it = 'Durante il download periodico dei tassi di cambio delle valute della BCE si è verificato un errore. Nel catalogo ""Valute"" manca Euro (EUR).';
			|pl = 'Podczas reglamentowanego pobierania kursów walut EBC wystąpiły błędy. W katalogu ""Waluty"" nie ma Euro (EUR).';
			|tr = 'AMB döviz kurlarının programlı yüklenmesi sırasında hatalar oluştu. ""Para Birimleri"" kataloğunda Euro (EUR) eksik.'"));
		If ImportParameters = Undefined Then 
			Raise NStr("vi = 'Chưa thực hiện kết nhập tỷ giá từ Ngân hàng trung ương Châu Âu. Trong danh mục ""Tiền tệ"" không có Euro (EUR).';
						|ru = 'Загрузка курсов ЕЦБ не выполнена. В справочнике ""Валюты"" отсутсвует Евро (EUR).';
						|en = 'The ECB exchange rates are not imported. There is no Euro (EUR) in the ""Currencies"" catalog.'; fa = 'The ECB exchange rates are not imported. There is no Euro (EUR) in the ""Currencies"" catalog.';
						|it = 'Download dei tassi di cambio della BCE non eseguito. Nel catalogo ""Valute"" manca Euro (EUR).';
						|pl = 'Pobieranie kursów EBC nie zostało wykonane. W katalogu ""Waluty"" nie ma Euro (EUR).';
						|tr = 'AMB döviz kurları yüklemesi gerçekleştirilmedi. ""Para Birimleri"" kataloğunda Euro (EUR) bulunmamaktadır.'");
		EndIf;
	EndIf;
	
	CurrentDate = CurrentSessionDate();
	
	ErrorsOccurredWhenLoading = False;
	
	If ImportParameters = Undefined Then
		QueryText = 
		"SELECT
		|	ExchangeRates.Currency AS Currency,
		|	MAX(ExchangeRates.Period) AS DateOfCourse
		|INTO TT_ExRates
		|FROM
		|	InformationRegister.RelativeExchangeRates AS ExchangeRates
		|WHERE
		|	ExchangeRates.Currency.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
		|	AND ExchangeRates.Currency.DeletionMark = FALSE
		|	AND ExchangeRates.BaseCurrency = &BaseCurrency
		|	AND ExchangeRates.Currency <> ExchangeRates.BaseCurrency
		|
		|GROUP BY
		|	ExchangeRates.Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Currencies.Ref AS Currency,
		|	Currencies.Code AS Code,
		|	ISNULL(TT_ExRates.DateOfCourse, DATETIME(1980, 1, 1)) AS DateOfCourse
		|FROM
		|	Catalog.Currencies AS Currencies
		|		LEFT JOIN TT_ExRates AS TT_ExRates
		|		ON Currencies.Ref = TT_ExRates.Currency
		|WHERE
		|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
		|	AND Currencies.DeletionMark = FALSE
		|	AND Currencies.Ref <> &BaseCurrency";
		
		Query = New Query(QueryText);
		Query.SetParameter("BaseCurrency", BaseCurrency);
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			
			Selection = Query.Execute().Select();
			
			EndOfPeriod = CurrentDate;
			BeginOfPeriod = EndOfPeriod;
			While Selection.Next() Do
				BeginOfPeriod = Min(BeginOfPeriod, ?(Selection.DateOfCourse = '198001010000', BegOfYear(AddMonth(CurrentDate, -12)), Selection.DateOfCourse + 60*60*24));
				ListOfCurrencies = CommonClientServer.ValueInArray(Selection);
				LoadExchangeRatesByParameters(ListOfCurrencies, BeginOfPeriod, EndOfPeriod, BaseCurrency, ErrorsOccurredWhenLoading, True);
			EndDo;
			
		EndIf;
	Else
		Result = LoadExchangeRatesByParameters(ImportParameters.ListOfCurrencies,
			ImportParameters.BeginOfPeriod, ImportParameters.EndOfPeriod, BaseCurrency, ErrorsOccurredWhenLoading);
	EndIf;
		
	If ResultAddress <> Undefined Then
		PutToTempStorage(Result, ResultAddress);
	EndIf;

	If ErrorsOccurredWhenLoading Then
		WriteLogEvent(EventName, EventLogLevel.Error,,,
			NStr("vi = 'Khi kết nhập thường kỳ tỷ giá hối đoái Ngân hàng trung ương Châu Âu, đã xảy ra lỗi';
				|ru = 'Во время регламентной загрузки курсов валют ЕЦБ возникли ошибки';
				|en = 'Errors occurred while running scheduled import of ECB currency rates.'; fa = 'Errors occurred while running scheduled import of ECB currency rates.';
				|it = 'Durante il download periodico dei tassi di cambio delle valute della BCE si è verificato un errore';
				|pl = 'Podczas reglamentowanego pobierania kursów walut EBC wystąpiły błędy';
				|tr = 'AMB döviz kurlarının programlı indirilmesi sırasında hatalar oluştu'"));
		If ImportParameters = Undefined Then
			Raise NStr("vi = 'Chưa thực hiện kết nhập tỷ giá từ Ngân hàng trung ương Châu Âu.';
						|ru = 'Загрузка курсов ЕЦБ не выполнена.';
						|en = 'The ECB exchange rates are not imported.'; fa = 'The ECB exchange rates are not imported.';
						|it = 'Download dei tassi di cambio della BCE non eseguito.';
						|pl = 'Nie wykonano pobierania kursów EBC.';
						|tr = 'ECB döviz kurları yüklemesi gerçekleştirilmedi.'");
		EndIf;
	Else
		WriteLogEvent(EventName, EventLogLevel.Information,,,
			NStr("vi = 'Đã hoàn thành kết nhập thường kỳ tỷ giá tiền tệ từ Ngân hàng trung ương Châu Âu.';
				|ru = 'Завершена регламентная загрузка курсов валют ЕЦБ.';
				|en = 'Scheduled import of ECB exchange rates is completed.'; fa = 'Scheduled import of ECB exchange rates is completed.';
				|it = 'Download periodico dei tassi di cambio delle valute della BCE eseguito.';
				|pl = 'Zakończono pobieranie kursów walut EBC.';
				|tr = 'ECB döviz kurlarının programlı indirilmesi tamamlandı.'"));
	EndIf;
	
EndProcedure

Procedure FillInAppropriateField(Map, DateOfCourse, ListOfXDTOCourses, ArrayOfCurrenciesToLoad, Val FractionalPartSeparator)
	
	CoursesDay = New Map;
	
	For Each Rate In ListOfXDTOCourses Do
		
		DownloadableCurrency = Catalogs.Currencies.FindByDescription(TrimAll(Rate.currency));
		
		If ArrayOfCurrenciesToLoad.Find(DownloadableCurrency) <> Undefined Then
			CoursesDay.Insert(DownloadableCurrency, TextToNumber(Rate.rate, FractionalPartSeparator));
		EndIf;
		
	EndDo;
	
	Map.Insert(DateOfCourse, CoursesDay);
	
EndProcedure

Function GetCourseData(XDTO, StartOfUploadingPeriod, ImportPeriodEnd, ArrayOfCurrenciesToLoad, Val FractionalPartSeparator)
	
	If TypeOf(XDTO) = Type("XDTODataObject") And XDTO.Properties().Get("time") <> Undefined Then
		
		Map = New Map;
		
		DateOfCourse = Date(StrReplace(XDTO["time"], "-", ""));
		
		If DateOfCourse <= ImportPeriodEnd And DateOfCourse >= StartOfUploadingPeriod Then 
			FillInAppropriateField(Map, DateOfCourse, XDTO["Cube"], ArrayOfCurrenciesToLoad, FractionalPartSeparator);
		Else
			Map.Insert(DateOfCourse, Undefined);
		EndIf;
			
		Return Map;
		
	ElsIf TypeOf(XDTO) = Type("XDTOList") Then
		
		Map = New Map;
		
		For Each ListOfDates In XDTO Do
			
			DateOfCourse = Date(StrReplace(ListOfDates.time, "-", ""));
			
			If DateOfCourse > ImportPeriodEnd Then
				Continue;
			EndIf;
			
			If DateOfCourse < StartOfUploadingPeriod Then 
				Break;
			EndIf;
			
			FillInAppropriateField(Map, DateOfCourse, ListOfDates.Cube, ArrayOfCurrenciesToLoad, FractionalPartSeparator);
			
		EndDo;
		
		Return Map;
		
	Else
		Return	GetCourseData(XDTO.Cube, StartOfUploadingPeriod, ImportPeriodEnd, ArrayOfCurrenciesToLoad, FractionalPartSeparator);
	EndIf;
	
EndFunction

Function ReadCoursesFile(File, StartOfUploadingPeriod, ImportPeriodEnd, ArrayOfCurrenciesToLoad, Val FractionalPartSeparator)
	
	Text = New TextDocument();
	Text.Read(File.Path, TextEncoding.UTF8);
	
	Read = New XMLReader;
	Read.SetString(Text.GetText());
	
	Factory = XDTOFactory.ReadXML(Read);
	
	CourseData = GetCourseData(Factory, StartOfUploadingPeriod, ImportPeriodEnd, ArrayOfCurrenciesToLoad, FractionalPartSeparator);
	
	If IsTempStorageURL(File.Path) Then
		DeleteFromTempStorage(File.Path);
	EndIf;
	
	DeleteFiles(File.Path);

	Return CourseData;
	
EndFunction

Function LoadExchangeRatesByParameters(Val Currencies, Val StartOfUploadingPeriod, Val ImportPeriodEnd, BaseCurrency, ErrorsOccurredWhenLoading = False, DateOfCurrencyExchangeRateInCollection = False)
	
	ImportState = New Array;
	
	DownloadDateDifference = (ImportPeriodEnd - StartOfUploadingPeriod)/86400; 
	TemplateServerSource = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-%1.xml";
	If DownloadDateDifference = 1 And BegOfDay(ImportPeriodEnd) = BegOfDay(CurrentSessionDate()) Then
		FileOnWebServer = StringFunctionsClientServer.SubstituteParametersToString(TemplateServerSource, "daily");
	ElsIf DownloadDateDifference < 89 Then
		FileOnWebServer = StringFunctionsClientServer.SubstituteParametersToString(TemplateServerSource, "hist-90d");
	Else
		FileOnWebServer = StringFunctionsClientServer.SubstituteParametersToString(TemplateServerSource, "hist");
	EndIf;

	Result = GetFilesFromInternet.DownloadFileAtServer(FileOnWebServer);
	If Result.Status Then
		CurrenciesImportedFromInternet = CurrenciesImportedFromInternet();
		FractionalPartSeparator = LocalFractionalPartSeparator();
		CourseData = ReadCoursesFile(Result, StartOfUploadingPeriod, ImportPeriodEnd, CurrenciesImportedFromInternet, FractionalPartSeparator);
	Else
		ExplanatoryMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận tệp dữ liệu có tỷ giá hối đoái từ Ngân hàng trung ương Châu Âu.
				|Có thể là không đủ quyền truy cập đến Website có tỷ giá hối đoái. Mã trạng thái %1';
				|ru = 'Невозможно получить файл данных с курсами валют ЕЦБ.
				|Возможно, нет доступа к веб-сайту с курсами валют. Код состояния %1';
				|en = 'Cannot import a file with the ECB exchange rates.
				|The exchange rate website might not be available. Status code %1'; fa = 'Cannot import a file with the ECB exchange rates.
				|The exchange rate website might not be available. Status code %1';
				|it = 'Impossibile ricevere il file dei dati con i tassi di cambio delle valute della BCE.
				|Potrebbe non esserci accesso al sito web contenente i tassi di cambio delle valute. Codice stato %1';
				|pl = 'Nie można otrzymać pliku danych z kursami walut EBC.
				|Możliwe, że nie ma dostępu do strony internetowej z kursami walut. Kod statusu %1';
				|tr = 'AMB döviz kuru veri dosyası alınamıyor.
				|Büyük olasılıkla döviz kuru web sitesine erişilemiyor. Durum kodu %1'"),
				Result.StatusCode);
		ErrorsOccurredWhenLoading = True;
		ImportState.Add(New Structure("Operation,OperationStatus,Message", NStr("vi = 'Quét tệp dữ liệu';
																				|ru = 'Скачивание файла данных';
																				|en = 'Download data file'; fa = 'Download data file';
																				|it = 'Download file dati';
																				|pl = 'Pobieranie pliku danych';
																				|tr = 'Veri dosyası indirme'"), False, ExplanatoryMessage));
		
		Return ImportState;
		
	EndIf;
	
	If DateOfCurrencyExchangeRateInCollection = False Then
		ArrayOfUploadDates = TMCommonUse.ArrayOfDatesFromPeriod(StartOfUploadingPeriod, ImportPeriodEnd);
	EndIf;
		
	For Each Currency In Currencies Do
		If CurrenciesImportedFromInternet.Find(Currency.Currency) = Undefined Then
			ErrorsOccurredWhenLoading = True;
			OperationStatus = False;
			ExplanatoryMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận tệp dữ liệu có tỷ giá hối đoái %2 (mã %1):
					|Tỷ giá tiền tệ này không có sẵn.';
					|ru = 'Невозможно получить файл данных с курсами валюты %2 (код %1):
					|Курсы данной валюты не предоставляются.';
					|en = 'Failed to import file with %2 (%1) exchange rates.
					|The currency exchange rates are not provided.'; fa = 'Failed to import file with %2 (%1) exchange rates.
					|The currency exchange rates are not provided.';
					|it = 'Impossibile ricevere il file dei dati con i tassi di cambio della valuta %2 (codice %1):
					|Non sono forniti i tassi di cambio di questa valuta.';
					|pl = 'Nie można pobrać pliku danych z kursami walut %2 (kod %1):
					|Kursy tej waluty nie są udzielane.';
					|tr = 'Döviz kurları %2 (kod %1) ile veri dosyası alınamıyor:
					|Bu para biriminin kurları sağlanmıyor.'"),
				Currency.CurrencyCode_,
				Currency.Currency);
				
			WriteLogEvent(EventLogEventName(), EventLogLevel.Error, , , ExplanatoryMessage);
		Else
			If DateOfCurrencyExchangeRateInCollection Then
				ArrayOfUploadDates = TMCommonUse.ArrayOfDatesFromPeriod(Currency.DateOfCourse, ImportPeriodEnd);
			EndIf;
			ExplanatoryMessage = DownloadCurrencyExchangeRate(Currency.Currency, CourseData, ArrayOfUploadDates, BaseCurrency) + Chars.LF;
			OperationStatus = IsBlankString(ExplanatoryMessage);
		EndIf;
		ImportState.Add(New Structure("Currency,OperationStatus,Message", Currency.Currency, OperationStatus, ExplanatoryMessage));
	EndDo;
			
	Return ImportState;
	
EndFunction

Function DownloadCurrencyExchangeRate(Val Currency, Val CourseData, Val ArrayOfUploadDates, Val BaseCurrency)
	
	ErrorList = New Array;
	
	For Each DateOfCourse In ArrayOfUploadDates Do
		
		DataAsOfTheDate = CourseData.Get(DateOfCourse); //Map
		If DataAsOfTheDate = Undefined Then
			ErrorList.Add(StrTemplate(NStr("vi = 'Đối với tiền tệ %1 sang %2 trên máy chủ không có dữ liệu để kết nhập';
											|ru = 'Для валюты %1 на %2 на сервере нет данных для загрузки';
											|en = 'There is no data to import on the server for the %1 currency as of %2'; fa = 'There is no data to import on the server for the %1 currency as of %2';
											|it = 'Для валюты %1 на %2 на сервере нет данных для загрузки';
											|pl = 'There is no data to import on the server for the %1 currency as of %2';
											|tr = '%1 ila %2 para birimi için sunucuya yüklenecek veri yok'"), String(Currency), Format(DateOfCourse, "DLF=DD")));
			Continue;
		EndIf;
		
		Rate = DataAsOfTheDate.Get(Currency);
		If Not ValueIsFilled(Rate) Then
			ErrorList.Add(StrTemplate(NStr("vi = 'Đối với tiền tệ %1 sang %2 trên máy chủ không có dữ liệu để kết nhập';
											|ru = 'Для валюты %1 на %2 на сервере нет данных для загрузки';
											|en = 'There is no data to import on the server for the %1 currency as of %2'; fa = 'There is no data to import on the server for the %1 currency as of %2';
											|it = 'Для валюты %1 на %2 на сервере нет данных для загрузки';
											|pl = 'There is no data to import on the server for the %1 currency as of %2';
											|tr = '%1 ila %2 para birimi için sunucuya yüklenecek veri yok'"), String(Currency),  Format(DateOfCourse, "DLF=DD")));
			Continue;
		EndIf;
		
		RecordSet = InformationRegisters.RelativeExchangeRates.CreateRecordSet();
		RecordSet.Filter.Currency.Set(Currency);
		RecordSet.Filter.BaseCurrency.Set(BaseCurrency);
		RecordSet.Filter.Period.Set(DateOfCourse);
		Record = RecordSet.Add();
		Record.Currency = Currency;
		Record.BaseCurrency = BaseCurrency;
		Record.Period = DateOfCourse;
		Record.CourseNumerator = 1;
		Record.CourseDenominator = Rate;
		
		RecordSet.Write();
		
	EndDo;
	
	UserMessages = GetUserMessages(True);
	For Each UserMessage In UserMessages Do
		ErrorList.Add(UserMessage.Text);
	EndDo;
	ErrorList = CommonClientServer.CollapseArray(ErrorList);
	
	Return StrConcat(ErrorList, Chars.LF);
	
EndFunction

Function CurrenciesImportedFromInternet()
	
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	NOT Currencies.DeletionMark
	|	AND Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)";
	
	Query = New Query(QueryText);
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

Function EventLogEventName()
	Return NStr("vi = 'Kết nhập tỷ giá tiền tệ từ Ngân hàng trung ương châu Âu';
				|ru = 'Загрузка курсов валют ЕЦБ';
				|en = 'Import ECB exchange rates'; fa = 'ورود نرخ‌های ارز ECB';
				|it = 'Download dei tassi di cambio delle valute della BCE';
				|pl = 'Pobieranie kursów walut EBC';
				|tr = 'Avrupa Merkez Bankası döviz kurlarını yükleme'", Common.DefaultLanguageCode());
EndFunction

Function LocalFractionalPartSeparator()
	
	VerificationNumber = 1.5;
	StringVerificationNumber = String(VerificationNumber);
	Return Mid(StringVerificationNumber, 2, 1);
	
EndFunction

Function TextToNumber(Val StringValue, Val FractionalPartSeparator)
	
	Result = Undefined;
	
	StringValue = StrReplace(StringValue, ".", FractionalPartSeparator);
	
    Result = Number(StringValue);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
