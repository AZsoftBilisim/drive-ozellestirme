///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If RateSource = Enums.RateSources.CalculationByFormula Then
		QueryText =
		"SELECT
		|	Currencies.Description AS AlphabeticCode
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	Currencies.RateSource = VALUE(Enum.RateSources.MarkupForOtherCurrencyRate)
		|
		|UNION ALL
		|
		|SELECT
		|	Currencies.Description
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	Currencies.RateSource = VALUE(Enum.RateSources.CalculationByFormula)";

		Query = New Query(QueryText);
		DependentCurrencies = Query.Execute().Unload().UnloadColumn("AlphabeticCode");

		For Each Currency In DependentCurrencies Do
			If StrFind(RateCalculationFormula, Currency) > 0 Then
				Cancel = True;
			EndIf;
		EndDo;
	EndIf;

	If ValueIsFilled(Common.ObjectAttributeValue(MainCurrency, "MainCurrency")) Then
		Cancel = True;
	EndIf;

	If Cancel Then
		Common.MessageToUser(
			NStr("vi = 'Tỷ giá ngoại tệ chỉ có thể liên kết với tỷ giá của tiền tệ không phụ thuộc.';
				|ru = 'Курс валюты можно связать только с курсом независимой валюты.';
				|en = 'An exchange rate can only depend on an independent exchange rate.'; fa = 'An exchange rate can only depend on an independent exchange rate.';
				|it = 'Il corso valutario può essere associato solo al corso di una valuta indipendente.';
				|pl = 'Kurs waluty można powiązać tylko z kursem waluty niezależnej.';
				|tr = 'Döviz kuru yalnızca bağımsız döviz kuruna bağlanabilir.'"));
	EndIf;

	If RateSource <> Enums.RateSources.MarkupForOtherCurrencyRate Then
		AttributesToExclude = New Array;
		AttributesToExclude.Add("MainCurrency");
		AttributesToExclude.Add("Markup");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	EndIf;

	If RateSource <> Enums.RateSources.CalculationByFormula Then
		AttributesToExclude = New Array;
		AttributesToExclude.Add("RateCalculationFormula");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	EndIf;

	If Not IsNew() And RateSource = Enums.RateSources.MarkupForOtherCurrencyRate
		And CurrencyRateOperations.DependentCurrenciesList(Ref).Count() > 0 Then
		Common.MessageToUser(
			NStr("vi = 'Tiền tệ không thể là trực thuộc bởi vì nó là chính đối với các loại tiền tệ khác.';
				|ru = 'Валюта не может быть подчиненной, так как она является основной для других валют.';
				|en = 'The currency cannot be subordinate because it is used as the base currency for other currencies.'; fa = 'The currency cannot be subordinate because it is used as the base currency for other currencies.';
				|it = 'La valuta non può essere subordinata poiché risulta principale per altre valute.';
				|pl = 'Waluta nie może być podporządkowana, ponieważ jest to waluta główna dla innych walut.';
				|tr = 'Para birimi, diğer para birimleri için ana birim olduğundan dolayı ikincil olamaz.'"));
		Cancel = True;
	EndIf;
	
	If Not IsNew() And RateSource = Enums.RateSources.MarkupForOtherCurrencyRate Then
		BaseCurrencies = ProcessingOfExchangeRatesTM.BaseCurrencies();
		If BaseCurrencies.Find(Ref) <> Undefined Then
			Common.MessageToUser(
				NStr("ru = 'Курс валюты не может быть связан с курсом другой валюты, так как она является базовой или валютой регламентированного учета.';
					|vi = 'The exchange rate cannot be based on another currency exchange rate, as it is the base currency or the local accounting currency.';
					|en = 'The exchange rate cannot be based on another currency exchange rate, as it is the base currency or the local accounting currency.'; fa = 'The exchange rate cannot be based on another currency exchange rate, as it is the base currency or the local accounting currency.';
					|it = 'The exchange rate cannot be based on another currency exchange rate, as it is the base currency or the local accounting currency.';
					|pl = 'The exchange rate cannot be based on another currency exchange rate, as it is the base currency or the local accounting currency.';
					|tr = 'Para birimi kuru, temel para birimi veya yasal muhasebe para birimi olduğu için başka bir para birimi kuruna bağlanamaz.'"));
			Cancel = True;
		EndIf;
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	RateImportedFromInternet = RateSource = Enums.RateSources.DownloadFromInternet;
	RateDependsOnOtherCurrency = RateSource = Enums.RateSources.MarkupForOtherCurrencyRate;
	RateCalculatedByFormula = RateSource = Enums.RateSources.CalculationByFormula;

	If IsNew() Then
		If RateDependsOnOtherCurrency Or RateCalculatedByFormula Then
			AdditionalProperties.Insert("UpdateRates");
		EndIf;
		AdditionalProperties.Insert("IsNew");
		AdditionalProperties.Insert("ScheduleCopyCurrencyRates");
	Else
		PreviousValues = Common.ObjectAttributesValues(Ref,
			"Code,RateSource,MainCurrency,Markup,RateCalculationFormula");

		RateSourceChanged = PreviousValues.RateSource <> RateSource;
		CurrencyCodeChanged = PreviousValues.Code <> Code;
		BaseCurrencyChanged = PreviousValues.MainCurrency <> MainCurrency;
		IncreaseByValueChanged = PreviousValues.Markup <> Markup;
		FormulaChanged = PreviousValues.RateCalculationFormula <> RateCalculationFormula;

		If (RateDependsOnOtherCurrency And (BaseCurrencyChanged Or IncreaseByValueChanged Or RateSourceChanged)) 
			Or (RateCalculatedByFormula And (FormulaChanged Or RateSourceChanged)) Then
			AdditionalProperties.Insert("UpdateRates");
		EndIf;

		If RateImportedFromInternet And (RateSourceChanged Or CurrencyCodeChanged) Then
			AdditionalProperties.Insert("ScheduleCopyCurrencyRates");
		EndIf;
	EndIf;

	If RateSource <> Enums.RateSources.MarkupForOtherCurrencyRate Then
		MainCurrency = Catalogs.Currencies.EmptyRef();
		Markup = 0;
	EndIf;

	If RateSource <> Enums.RateSources.CalculationByFormula Then
		RateCalculationFormula = "";
	EndIf;
	
	If ValueIsFilled(RateCalculationFormula) Then
		Try
			CheckFormula(RateCalculationFormula);
		Except
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
				NStr("vi = 'Không thể tính toán tỷ giá tiền tệ theo công thức:';
					|ru = 'Не удалось вычислить курс валюты по формуле:';
					|en = 'Failed to calculate the exchange rate using the formula:'; fa = 'Failed to calculate the exchange rate using the formula:';
					|it = 'Не удалось вычислить курс валюты по формуле:';
					|pl = 'Failed to calculate the exchange rate using the formula:';
					|tr = 'Döviz kuru formül ile hesaplanamadı:'"));
			Raise(Refinement.Text, Refinement.Category, , , ErrorInfo);
		EndTry;
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	UpdateRates = AdditionalProperties.Property("UpdateRates");
	IsNew = AdditionalProperties.Property("IsNew");
	ShouldWriteExchangeRates = UpdateRates Or IsNew;
	IsBackgroundCurrencyExchangeRatesRecalculationRunning = IsBackgroundCurrencyExchangeRatesRecalculationRunning();
	
	If ShouldWriteExchangeRates And IsBackgroundCurrencyExchangeRatesRecalculationRunning Then
		Raise NStr("vi = 'Không thể ghi lại tiền tệ vì quá trình tính lại tỷ giá trên nền vẫn chưa kết thúc.
							   |Hãy thử ghi lại tiền tệ sau.';
							   |ru = 'Не удалось записать валюту, так как еще не завершился фоновый пересчет курсов.
							   |Попробуйте записать валюту позже.';
							   |en = 'Couldn''t save the currency because the background calculation of exchange rates is running.
							   |Try to save the currency later.'; fa = 'Couldn''t save the currency because the background calculation of exchange rates is running.
							   |Try to save the currency later.';
							   |it = 'Non è possibile registrare la valuta, poiché il tasso di cambio di background non è ancora completato.
							   | Provare a registrare la valuta più tardi.';
							   |pl = 'Nie można zapisać waluty, ponieważ kurs wymiany w tle nie został jeszcze ukończony.
							   | Spróbuj zapisać walutę później.';
							   |tr = 'Arka planda döviz kuru hesaplaması devam ettiği için para birimi kaydedilemedi.
							   | Para birimini daha sonra kaydetmeyi deneyin.'");
	EndIf;

	If UpdateRates Then
		StartBackgroundCurrencyExchangeRatesUpdate();
	ElsIf Not IsBackgroundCurrencyExchangeRatesRecalculationRunning Then
		CurrencyRateOperations.CheckCurrencyRateAvailabilityFor01011980(Ref);
	EndIf;

	If AdditionalProperties.Property("ScheduleCopyCurrencyRates") Then
		ScheduleCopyCurrencyRates();
	EndIf;

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = Undefined Then
		RateSource = Enums.RateSources.ManualInput;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function IsBackgroundCurrencyExchangeRatesRecalculationRunning()

	JobParameters = New Structure;
	JobParameters.Insert("Description", "CurrencyRateOperations.UpdateCurrencyRate");
	JobParameters.Insert("State", BackgroundJobState.Active);

	Return Common.FileInfobase() 
		And BackgroundJobs.GetBackgroundJobs(JobParameters).Count() > 0;

EndFunction

Procedure StartBackgroundCurrencyExchangeRatesUpdate()

	CurrencyParameters = New Structure;
	CurrencyParameters.Insert("MainCurrency");
	CurrencyParameters.Insert("Ref");
	CurrencyParameters.Insert("Markup");
	CurrencyParameters.Insert("AdditionalProperties");
	CurrencyParameters.Insert("RateCalculationFormula");
	CurrencyParameters.Insert("RateSource");
	CurrencyParameters.Insert("CurrenciesUsedInCalculatingTheExchangeRate", CurrenciesUsedInCalculatingTheExchangeRate());
	FillPropertyValues(CurrencyParameters, ThisObject);

	JobParameters = New Structure;
	JobParameters.Insert("Currency", CurrencyParameters);
	JobParameters.Insert("CurrencyCodes", Catalogs.Currencies.CurrencyCodes());

	If InfobaseUpdate.InfobaseUpdateRequired() Then
		CurrencyRateOperations.UpdateCurrencyRate(JobParameters, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.WaitCompletion = 0;

	Result = TimeConsumingOperations.ExecuteInBackground("CurrencyRateOperations.UpdateCurrencyRate", JobParameters,
		ExecutionParameters);
	
	If Result.Status = "Error" Then
		Refinement = CommonClientServer.ExceptionClarification(Result.ErrorInfo,
			NStr("vi = 'Không thể khởi động cập nhật tỷ giá tiền tệ theo nguyên nhân:';
				|ru = 'Не удалось запустить обновление курсов валюты по причине:';
				|en = 'Couldn''t update exchange rates due to:'; fa = 'Couldn''t update exchange rates due to:';
				|it = 'Не удалось запустить обновление курсов валюты по причине:';
				|pl = 'Couldn''t update exchange rates due to:';
				|tr = 'Döviz kurlarının güncellenmesi şu nedenlerden dolayı başarısız oldu:'"));
		Raise(Refinement.Text, Refinement.Category,,, Result.ErrorInfo);
	EndIf;

EndProcedure

Procedure ScheduleCopyCurrencyRates()

	If Common.DataSeparationEnabled() And Common.SubsystemExists("StandardSubsystems.Currencies") Then
		ModuleCurrencyExchangeRatesInternal = Common.CommonModule("CurrencyRateOperationsInternal");
		ModuleCurrencyExchangeRatesInternal.ScheduleCopyCurrencyRates(ThisObject);
	EndIf;

EndProcedure

Function CurrenciesUsedInCalculatingTheExchangeRate()

	If RateSource = Enums.RateSources.MarkupForOtherCurrencyRate Then
		Return CommonClientServer.ValueInArray(MainCurrency);
	EndIf;

	If RateSource <> Enums.RateSources.CalculationByFormula Then
		Return New Array;
	EndIf;

	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	&RateCalculationFormula LIKE ""%"" + Currencies.Description + ""%"" ESCAPE ""~""
	|	AND Currencies.Description <> """"";

	Query = New Query(QueryText);
	Query.SetParameter("RateCalculationFormula", RateCalculationFormula);
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
		ErrorText = NStr("vi = 'Trong công thức cần sử dụng ít nhất một tiền tệ cơ sở.';
						|ru = 'В формуле должна быть использована хотя бы одна основная валюта.';
						|en = 'The formula must include at least one base currency.'; fa = 'The formula must include at least one base currency.';
						|it = 'Nella formula deve essere usata almeno una valuta principale.';
						|pl = 'W formule powinna być stosowana przynajmniej jedna podstawowa waluta.';
						|tr = 'Formülde en az bir ana para birimi kullanılacaktır.'");
		Common.MessageToUser(ErrorText,, "Object.RateCalculationFormula");
		Raise ErrorText;
	EndIf;

	Return QueryResult.Unload().UnloadColumn("Ref");

EndFunction

Procedure CheckFormula(Formula) Export
	
	CurrencyCodes = Catalogs.Currencies.CurrencyCodes();
	Expression = Catalogs.Currencies.FormatNumbers(Formula);
	
	For Each Currency In CurrencyCodes Do
		Expression = StrReplace(Expression, Currency.AlphabeticCode, "1");
	EndDo;
	
	Common.CalculateInSafeMode(Expression);
	
EndProcedure

#EndRegion

#Else
	Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
				|ru = 'Недопустимый вызов объекта на клиенте.';
				|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
				|it = 'Chiamata di oggetto non valida sul client.';
				|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
				|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf