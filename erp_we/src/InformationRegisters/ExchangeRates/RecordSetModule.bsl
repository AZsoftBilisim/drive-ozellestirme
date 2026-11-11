///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ErrorInRateCalculationByFormula;
Var CurrencyCodes;

#EndRegion

#Region EventHandlers

// The dependent currency rates are controlled while writing.
//
Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DisableDependentCurrenciesControl") Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("DependentCurrencies", New Map);
	
	If Count() > 0 And Not Common.IsRecordSetDeletion(Replacing) Then
		UpdateSubordinateCurrenciesRates();
	Else
		DeleteRatesOfDependentCurrencies(Replacing);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Finds all dependent currencies and changes their rate.
//
Procedure UpdateSubordinateCurrenciesRates()
	
	SelectedCurrency = Undefined;
	AdditionalProperties.Property("UpdateSubordinateCurrencyRate", SelectedCurrency);
	
	For Each BaseCurrencyRecord In ThisObject Do
	
		If SelectedCurrency <> Undefined Then // Only the given currency's rate must be updated.
			BlockDependentCurrencyRate(SelectedCurrency, BaseCurrencyRecord.Period); 
		Else
			DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(BaseCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurrencies Do
				BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyRecord.Period); 
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each BaseCurrencyRecord In ThisObject Do

		If SelectedCurrency <> Undefined Then // Only the given currency's rate must be updated.
			UpdatedPeriods = Undefined;
			If Not AdditionalProperties.Property("UpdatedPeriods", UpdatedPeriods) Then
				UpdatedPeriods = New Map;
				AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			EndIf;
			// The rate is not updated more than once over the same period of time.
			If UpdatedPeriods[BaseCurrencyRecord.Period] = Undefined Then
				//@skip-check query-in-loop - batch processing of large amounts of data
				UpdateSubordinateCurrencyRate(SelectedCurrency, BaseCurrencyRecord); 
				UpdatedPeriods.Insert(BaseCurrencyRecord.Period, True);
			EndIf;
		Else	// Refresh the rate for all dependent currencies.
			DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(BaseCurrencyRecord.Currency, AdditionalProperties);
			For Each DependentCurrency In DependentCurrencies Do
				//@skip-check query-in-loop - batch processing of large amounts of data
				UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord); 
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BlockDependentCurrencyRate(DependentCurrency, BaseCurrencyPeriod)
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExchangeRates");
	LockItem.SetValue("Currency", DependentCurrency.Ref);
	If ValueIsFilled(BaseCurrencyPeriod) Then
		LockItem.SetValue("Period", BaseCurrencyPeriod);
	EndIf;
	Block.Lock();
	
EndProcedure
	
Procedure UpdateSubordinateCurrencyRate(DependentCurrency, BaseCurrencyRecord)
	
	RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(DependentCurrency.Ref, True);
	RecordSet.Filter.Period.Set(BaseCurrencyRecord.Period, True);
	
	WriteCurrencyRate = RecordSet.Add();
	WriteCurrencyRate.Currency = DependentCurrency.Ref;
	WriteCurrencyRate.Period = BaseCurrencyRecord.Period;
	If DependentCurrency.RateSource = Enums.RateSources.MarkupForOtherCurrencyRate Then
		WriteCurrencyRate.Rate = BaseCurrencyRecord.Rate + BaseCurrencyRecord.Rate * DependentCurrency.Markup / 100;
		WriteCurrencyRate.Repetition = BaseCurrencyRecord.Repetition;
	Else // Calculate by formula.
		Rate = CurrencyRateByFormula(DependentCurrency.Ref, DependentCurrency.RateCalculationFormula, BaseCurrencyRecord.Period);
		If Rate = Undefined Then
			If Not AdditionalProperties.Property("CurrenciesWithIncorrectFormula") Then
				AdditionalProperties.Insert("CurrenciesWithIncorrectFormula", New Map);
				AdditionalProperties.CurrenciesWithIncorrectFormula.Insert(DependentCurrency.Ref, True)
			EndIf;
		Else
			WriteCurrencyRate.Rate = Rate;
			WriteCurrencyRate.Repetition = 1;
		EndIf;
	EndIf;
		
	If WriteCurrencyRate.Rate = 0 Then
		Return;
	EndIf;
	
	RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExchangeRates");
	LockItem.SetValue("Currency", WriteCurrencyRate.Currency);
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

// Clears rates for dependent currencies.
//
Procedure DeleteRatesOfDependentCurrencies(Val ReplacementModeDeletion)
	
	If Common.IsRecordSetDeletion(ReplacementModeDeletion) Then
		DeleteRatesByRecordsSet(ReplacementModeDeletion);
	Else
		DeleteRatesByFilter();
	EndIf;
	
EndProcedure

Procedure DeleteRatesByFilter()
	
	CurrencyOwner = Filter.Currency.Value;
	Period = Filter.Period.Value;
	
	If AdditionalProperties.Property("UpdateSubordinateCurrencyRate") Then
		DependentCurrencies = CommonClientServer.ValueInArray(AdditionalProperties.UpdateSubordinateCurrencyRate);
	Else
		DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(CurrencyOwner, AdditionalProperties).UnloadColumn("Ref");
	EndIf;
	
	For Each DependentCurrency In DependentCurrencies Do
		BlockDependentCurrencyRate(DependentCurrency, Period); 
		DeleteCurrencyRates(DependentCurrency, Period);
	EndDo;
	
EndProcedure

Procedure DeleteRatesByRecordsSet(Val ReplacementModeDeletion)
	
	RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
	Block = New DataLock;
	
	For Each Record In ThisObject Do
		If AdditionalProperties.Property("UpdateSubordinateCurrencyRate") Then
			DependentCurrencies = CommonClientServer.ValueInArray(AdditionalProperties.UpdateSubordinateCurrencyRate);
		Else
			DependentCurrencies = CurrencyRateOperations.DependentCurrenciesList(Record.Currency, AdditionalProperties).UnloadColumn("Ref");
		EndIf;
		
		For Each DependentCurrency In DependentCurrencies Do
			For Each DependentCurrency In DependentCurrencies Do
				LockItem = Block.Add("InformationRegister.ExchangeRates");
				LockItem.SetValue("Currency", DependentCurrency);
				LockItem.SetValue("Period", Record.Period);
			EndDo;
			
			RecordToDelete = RecordSet.Add();
			RecordToDelete.Currency = DependentCurrency;
			RecordToDelete.Period = Record.Period;
		EndDo;
	EndDo;
	
	If RecordSet.Count() > 0 Then
		Block.Lock();
		RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
		RecordSet.Write(ReplacementModeDeletion);
	EndIf;
	
EndProcedure

Procedure DeleteCurrencyRates(CurrencyRef, Period)
	RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(CurrencyRef);
	RecordSet.Filter.Period.Set(Period);
	RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	RecordSet.Write();
EndProcedure

Function CurrencyRateByFormula(Currency, Formula, Period)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tính toán tỷ giá ""%1"" theo công thức ""%2"" cho kỳ ""%3""không thực hiện:';
																				|ru = 'Расчет курса валюты ""%1"" по формуле ""%2"" за период ""%3""не выполнен:';
																				|en = 'Cannot calculate the ""%1"" currency exchange rate using the ""%2"" formula for period ""%3"":'; fa = 'Cannot calculate the ""%1"" currency exchange rate using the ""%2"" formula for period ""%3"":';
																				|it = 'Calcolo del corso della valuta ""%1"" in base alla formula ""%2"" per il periodo ""%3"" non eseguito:';
																				|pl = 'Obliczenie kursu waluty ""%1"" według formuły ""%2"" za okres ""%3""nie zostało wykonane:';
																				|tr = '""%1"" döviz kurunun ""%2"" formülüyle ""%3"" dönemi için hesaplanması yapılmadı:'",
		Common.DefaultLanguageCode()), Currency, Formula, Period);
	
	Try
		Result = Catalogs.Currencies.CurrencyRateByFormula(Formula, Period, CurrencyCodes());
	Except
		If ErrorInRateCalculationByFormula = Undefined Then
			ErrorInRateCalculationByFormula = New Map;
		EndIf;
		If ErrorInRateCalculationByFormula[Currency] = Undefined Then
			ErrorInRateCalculationByFormula.Insert(Currency, True);
			ErrorInfo = ErrorInfo();
			
			Common.MessageToUser(ErrorText + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo), 
				Currency, "Object.RateCalculationFormula");
				
			If AdditionalProperties.Property("UpdateSubordinateCurrencyRate") Then
				Raise ErrorText + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
			EndIf;
			
			WriteLogEvent(NStr("vi = 'Tiền tệ.Kết nhập tỷ giá ngoại tệ';
								|ru = 'Валюты.Загрузка курсов валют';
								|en = 'Currencies.Import exchange rates'; fa = 'Currencies.Import exchange rates';
								|it = 'Valute.Download dei tassi di cambio';
								|pl = 'Waluta.Pobieranie kursów walut';
								|tr = 'Para birimi. Döviz kuru içe aktarımı'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Currency.Metadata(), Currency, 
				ErrorText + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo));
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
	
	Return CurrencyCodes;
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf