#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ErrorInRateCalculationByFormula;
Var CurrencyCodes;

#EndRegion


#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("UploadingCurrencyExchangeRatesToRegionForEntirePeriod") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DisableDependentCurrenciesControl") Then
		Return;
	EndIf;
	
	For Each Record In ThisObject Do
		If Record.Currency = Record.BaseCurrency
			And (Record.CourseNumerator <> 1 Or Record.CourseDenominator <> 1) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trường tiền tệ và tiền tệ cơ sở đã chọn giá trị giống nhau %1.
					|Trong các trường Tỷ giá (Tử số) và Tỷ giá (Mẫu số) phải chỉ ra giá trị ""1""';
					|ru = 'В поле валюта и базовая валюта выбрано одинаковое значение %1.
					|В поля Курс (Числитель) и Курс (Знаменатель) необходимо указать значение ""1""';
					|en = 'The same value %1 is selected in the currency and base currency fields.
					|Specify ""1"" in the Rate (Numerator) and Rate (Denominator) fields'; fa = 'The same value %1 is selected in the currency and base currency fields.
					|Specify ""1"" in the Rate (Numerator) and Rate (Denominator) fields';
					|it = 'Nel campo di valuta e valuta di riferimento è stato selezionato il valore univoco %1.
					|Nei campi Tasso di cambio (numeratore) e Tasso di cambio (Denominatore) è necessario indicare il valore ""1""';
					|pl = 'W polu waluta i waluta podstawowa wybrano jednakowe wartości %1.
					|W polach Kurs (Licznik) и Kurs (Mianownik) należy wpisać wartość ""1""';
					|tr = 'Para birimi ve temel para birimi alanlarında aynı değer %1 seçilir.
					|Kur (Pay) ve Kur (Payda) alanlarında ""1"" değeri belirtilmelidir'"),
					Record.Currency);
			Common.MessageToUser(ErrorText,,,,Cancel);
		EndIf;
	EndDo;
	
EndProcedure

// When recording, the exchange rates of subordinate currencies are monitored.
//
Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DisableDependentCurrenciesControl") Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("DependentCurrencies", New Map);
	
	If Count() > 0 Then
		UpdateSubordinateCurrenciesRates();
	Else
		DeleteDependentCurrencyRates();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Finds all dependent currencies and changes their exchange rate.
//
Procedure UpdateSubordinateCurrenciesRates()
	
	SelectedCurrency = Undefined;
	AdditionalProperties.Property("UpdateSubordinateCurrencyRate", SelectedCurrency);
	
	For Each BaseCurrencyRecord In ThisObject Do
	
		If SelectedCurrency <> Undefined Then // You need to update the exchange rate of only the specified currency.
			BlockDependentCurrencyRate(SelectedCurrency, BaseCurrencyRecord.BaseCurrency, BaseCurrencyRecord.Period);
		Else
			DependentCurrencies = ProcessingOfExchangeRatesTM.DependentCurrenciesList(BaseCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurrencies Do
				BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyRecord.BaseCurrency, BaseCurrencyRecord.Period);
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each BaseCurrencyRecord In ThisObject Do

		If SelectedCurrency <> Undefined Then // You need to update the exchange rate of only the specified currency.
			UpdatedPeriods = Undefined;
			If Not AdditionalProperties.Property("UpdatedPeriods", UpdatedPeriods) Then
				UpdatedPeriods = New Map;
				AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			EndIf;
			// We do not update the course repeatedly for the same period.
			If UpdatedPeriods[BaseCurrencyRecord.Period] = Undefined Then
				UpdateSubordinateCurrencyRate(SelectedCurrency, BaseCurrencyRecord);
				UpdatedPeriods.Insert(BaseCurrencyRecord.Period, True);
			EndIf;
		Else	// Update the exchange rate of all dependent currencies.
			DependentCurrencies = ProcessingOfExchangeRatesTM.DependentCurrenciesList(BaseCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurrencies Do
				UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord); 
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BlockDependentCurrencyRate(DependentCurrency, BaseCurrency, BaseCurrencyPeriod)
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.RelativeExchangeRates");
	LockItem.SetValue("Currency", DependentCurrency.Ref);
	LockItem.SetValue("BaseCurrency", BaseCurrency);
	If ValueIsFilled(BaseCurrencyPeriod) Then
		LockItem.SetValue("Period", BaseCurrencyPeriod);
	EndIf;
	Block.Lock();
	
EndProcedure
	
Procedure UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord)
	
	RecordSet = InformationRegisters.RelativeExchangeRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(DependentCurrency.Ref);
	RecordSet.Filter.BaseCurrency.Set(BaseCurrencyRecord.BaseCurrency);
	RecordSet.Filter.Period.Set(BaseCurrencyRecord.Period);
	
	WriteCurrencyRate = RecordSet.Add();
	WriteCurrencyRate.Currency = DependentCurrency.Ref;
	WriteCurrencyRate.BaseCurrency = BaseCurrencyRecord.BaseCurrency;
	WriteCurrencyRate.Period = BaseCurrencyRecord.Period;
	If DependentCurrency.RateSource = Enums.RateSources.MarkupForOtherCurrencyRate Then
		
		CourseAccuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
		MarginFactor = 1 + DependentCurrency.Markup / 100;
	
		If BaseCurrencyRecord.CourseNumerator = 1 Then
			WriteCurrencyRate.CourseNumerator = 1;
			WriteCurrencyRate.CourseDenominator = Round(BaseCurrencyRecord.CourseDenominator / MarginFactor, CourseAccuracy);
		Else
			WriteCurrencyRate.CourseNumerator = Round(BaseCurrencyRecord.CourseNumerator * MarginFactor, CourseAccuracy);
			WriteCurrencyRate.CourseDenominator = BaseCurrencyRecord.CourseDenominator;
		EndIf;
		
	Else // according to the formula
		DependentCurrencyRate = CurrencyRateByFormula(DependentCurrency.Ref, DependentCurrency.RateCalculationFormula, BaseCurrencyRecord.BaseCurrency, BaseCurrencyRecord.Period);
		If DependentCurrencyRate <> Undefined Then
			If BaseCurrencyRecord.CourseDenominator > BaseCurrencyRecord.CourseNumerator Then
				WriteCurrencyRate.CourseNumerator = 1;
				WriteCurrencyRate.CourseDenominator = DependentCurrencyRate;
			Else
				WriteCurrencyRate.CourseNumerator = DependentCurrencyRate;
				WriteCurrencyRate.CourseDenominator = 1;
			EndIf;
		EndIf;
	EndIf;
	
	If WriteCurrencyRate.CourseNumerator = 0 Or WriteCurrencyRate.CourseDenominator = 0 Then
		Return;
	EndIf;
	
	RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.RelativeExchangeRates");
	LockItem.SetValue("Currency", WriteCurrencyRate.Currency);
	LockItem.SetValue("BaseCurrency", WriteCurrencyRate.BaseCurrency);
	LockItem.SetValue("Period", WriteCurrencyRate.Period);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Clears the exchange rates of dependent currencies.
//
Procedure DeleteDependentCurrencyRates()
	
	CurrencyOwner = Filter.Currency.Value;
	BaseCurrencyOwner = Filter.BaseCurrency.Value;
	Period = Filter.Period.Value;
	
	DependentCurrency = Undefined;
	If AdditionalProperties.Property("UpdateSubordinateCurrencyRate", DependentCurrency) Then
		BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyOwner, Period);
		DeleteCurrencyRates(DependentCurrency, BaseCurrencyOwner, Period);
	Else
		DependentCurrencies = ProcessingOfExchangeRatesTM.DependentCurrenciesList(CurrencyOwner, AdditionalProperties);
		For Each DependentCurrency In DependentCurrencies Do
			BlockDependentCurrencyRate(DependentCurrency.Ref, BaseCurrencyOwner, Period); 
		EndDo;
		For Each DependentCurrency In DependentCurrencies Do
			DeleteCurrencyRates(DependentCurrency.Ref, BaseCurrencyOwner, Period);
		EndDo;
	EndIf;
		
EndProcedure

Procedure DeleteCurrencyRates(CurrencyRef, BaseCurrency, Period)
	RecordSet = InformationRegisters.RelativeExchangeRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(CurrencyRef);
	RecordSet.Filter.BaseCurrency.Set(BaseCurrency);
	RecordSet.Filter.Period.Set(Period);
	RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	RecordSet.Write();
EndProcedure
	
Function CurrencyRateByFormula(Currency, Formula, BaseCurrency, Period)
	
	If CurrencyCodes = Undefined Then
		CurrencyCodes = CurrencyCodes();
	EndIf;
	
	QueryText = 
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.AlphabeticCode AS AlphabeticCode
	|INTO Currencies
	|FROM
	|	&CurrencyCodes AS Currencies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Currencies.AlphabeticCode AS AlphabeticCode,
	|	CASE
	|		WHEN ISNULL(CurrencyRatesCut.CourseDenominator, 1) > ISNULL(CurrencyRatesCut.CourseNumerator, 1)
	|			THEN ISNULL(CurrencyRatesCut.CourseDenominator, 1) / ISNULL(CurrencyRatesCut.CourseNumerator, 1)
	|		ELSE ISNULL(CurrencyRatesCut.CourseNumerator, 1) / ISNULL(CurrencyRatesCut.CourseDenominator, 1)
	|	END AS Rate
	|FROM
	|	Currencies AS Currencies
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
	|		ON (CurrencyRatesCut.Currency = Currencies.Ref)";
	
	Query = New Query(QueryText);
	Query.SetParameter("CurrencyCodes", CurrencyCodes);
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("Period", Period);
	
	Expression = Formula;
	If StrFind(Expression, ".") = 0 Then
		Expression = StrReplace(Expression, ",", ".");
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Expression = StrReplace(Expression, Selection.AlphabeticCode, Format(Selection.Rate, "NDS=.; NG=0"));
	EndDo;
	
	Try
		Result = Common.CalculateInSafeMode(Expression);
	Except
		If ErrorInRateCalculationByFormula = Undefined Then
			ErrorInRateCalculationByFormula = New Map;
		EndIf;
		If ErrorInRateCalculationByFormula[Currency] = Undefined Then
			ErrorInRateCalculationByFormula.Insert(Currency, True);
			ErrorInfo = ErrorInfo();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa tính tỷ giá hối đoái ""%1"" theo công thức ""%2"" trong kỳ ""%3"":';
																						|ru = 'Расчет курса валюты ""%1"" по формуле ""%2"" за период ""%3""не выполнен:';
																						|en = 'Cannot calculate the ""%1"" exchange rate using formula ""%2"" for the ""%3"" period:'; fa = 'Cannot calculate the ""%1"" exchange rate using formula ""%2"" for the ""%3"" period:';
																						|it = 'Calcolo del corso della valuta ""%1"" in base alla formula ""%2"" per il periodo ""%3"" non eseguito:';
																						|pl = 'Obliczenie kursu waluty ""%1"" według formuły ""%2"" za okres ""%3""nie zostało wykonane:';
																						|tr = '""%1"" döviz kurunun ""%2"" formülüyle ""%3"" dönemi için hesaplanması yapılmadı:'",
				Common.DefaultLanguageCode()), Currency, Formula, Period);
				
			Common.MessageToUser(ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo), 
				Currency, "Object.RateCalculationFormula");
				
			If AdditionalProperties.Property("UpdateSubordinateCurrencyRate") Then
				Raise ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo);
			EndIf;
			
			WriteLogEvent(NStr("vi = 'Kết nhập tỷ giá hối đoái từ Ngân hàng trung ương châu Âu';
								|ru = 'Загрузка курсов валют ЕЦБ';
								|en = 'Import ECB exchange rates'; fa = 'ورود نرخ‌های ارز ECB';
								|it = 'Download dei tassi di cambio delle valute della BCE';
								|pl = 'Pobieranie kursów walut EBC';
								|tr = 'Avrupa Merkez Bankası döviz kurlarını yükleme'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Currency.Metadata(), Currency, 
				ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo));
		EndIf;
		Result = Undefined;
	EndTry;
	
	Return Result;
EndFunction

Function CurrencyCodes()
	
	CurrencyCodes = Undefined;
	AdditionalProperties.Property("CurrencyCodes", CurrencyCodes);
	If CurrencyCodes = Undefined Then
		CurrencyCodes = Catalogs.Currencies.CurrencyCodes();
	EndIf;
	
	Result = New ValueTable;
	Result.Columns.Add("Ref", New TypeDescription("CatalogRef.Currencies"));
	Result.Columns.Add("AlphabeticCode", New TypeDescription("String", , , , New StringQualifiers(Metadata.Catalogs.Currencies.DescriptionLength, AllowedLength.Variable)));
	
	For Each CurrencyDescription In CurrencyCodes Do
		// The currency participates in the formula if the character code contains letters.
		If ValueIsFilled(StrConcat(StrSplit(CurrencyDescription.AlphabeticCode, "0123456789", False), "")) Then
			FillPropertyValues(Result.Add(), CurrencyDescription);
		EndIf;
	EndDo;
	
	Result.Indexes.Add("Ref");
	
	Return Result;
	
EndFunction

#EndRegion

#Region Initialize

ErrorInRateCalculationByFormula = Undefined;
CurrencyCodes = Undefined;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf