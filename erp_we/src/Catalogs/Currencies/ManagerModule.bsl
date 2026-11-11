///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("RateSource");
	Result.Add("Markup");
	Result.Add("MainCurrency");
	Result.Add("RateCalculationFormula");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

// The procedure populates the currency reference list with default values.
//
Procedure FillInDefaultCurrency_() Export
	
	CurrencyCode_ = SystemSettingsLocalization.DefaultCurrencyCode();
	
	Codes = New Array;
	Codes.Add(CurrencyCode_);
	CurrencyRateOperations.AddCurrenciesByCode(Codes);
	
EndProcedure

// Returns the number of elements of the Currency reference list.
// Takes into account all elements.
//
// Returns:
//     Number - the number of currencies.
//
Function NumberOfCurrencies() Export
	
	SetPrivilegedMode(True);
	
	Count = 0;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	Catalog.Currencies AS Currencies";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Count = Selection.Count;
	EndIf;
		
	Return Count;
	
EndFunction

// Returns the default currency.
// If there is only one currency in the IB, a link to it will be returned, otherwise an empty link will be returned.
//
// Returns:
//     CatalogRef.Currencies - link to the currency.
//
Function GetDefaultCurrency() Export
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 2
		|	Currencies.Ref AS Currency
		|FROM
		|	Catalog.Currencies AS Currencies";
	
	Selection = Query.Execute().Select();
		
	If Selection.Next() And Selection.Count() = 1 Then
		Currency = Selection.Currency;
	Else
		Currency = Catalogs.Currencies.EmptyRef();
	EndIf;
	
	Return Currency;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	If Parameters.Property("InvoiceBaseCurrency") Then
		
		StandardProcessing = False;
		
		LocalAccountingCurrency = Constants.LocalAccountingCurrency.Get();
		
		ChoiceData = New ValueList;
		ChoiceData.Add(LocalAccountingCurrency);
		
		If ValueIsFilled(Parameters.InvoiceBaseCurrency)
		 And Parameters.InvoiceBaseCurrency <> LocalAccountingCurrency Then
			ChoiceData.Add(Parameters.InvoiceBaseCurrency);
		EndIf;
		
	EndIf;
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If FormType = "ListForm" And Not GetFunctionalOption("UseMultipleCurrencies")
	And NumberOfCurrencies() = 1 Then
		
		Parameters.Insert("Key", IncomeAndExpensesServer.GetCurrencyOfManagementAccounting());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
		
	EndIf;
EndProcedure

#EndRegion

#Region Private

Function CurrencyCodes() Export
	
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.Description AS AlphabeticCode,
	|	Currencies.DescriptionFull AS Presentation
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource <> VALUE(Enum.RateSources.MarkupForOtherCurrencyRate)
	|	AND Currencies.RateSource <> VALUE(Enum.RateSources.CalculationByFormula)";
	
	Query = New Query(QueryText);
	
	Currencies = Query.Execute().Unload();
	RowsToCopy = New Array;
	
	For Each Currency In Currencies Do
		// A currency is included in the formula if its char code contains letters.
		If ValueIsFilled(StrConcat(StrSplit(Currency.AlphabeticCode, "0123456789", False), "")) Then
			RowsToCopy.Add(Currency);
		EndIf;
	EndDo;
	
	Result = Currencies.Copy(RowsToCopy);
	Result.Indexes.Add("Ref");
	
	Return Result;
	
EndFunction

Function CurrencyRateByFormula(Formula, Period, CurrencyCodes = Undefined) Export
	
	If CurrencyCodes = Undefined Then
		CurrencyCodes = Catalogs.Currencies.CurrencyCodes();
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
	|		WHEN ISNULL(CurrencyRatesCut.Repetition, 1) > 0
	|			THEN ISNULL(CurrencyRatesCut.Rate, 1) / ISNULL(CurrencyRatesCut.Repetition, 1)
	|		ELSE 1
	|	END AS Rate
	|FROM
	|	Currencies AS Currencies
	|		LEFT JOIN InformationRegister.ExchangeRates.SliceLast(&Period, ) AS CurrencyRatesCut
	|		ON (CurrencyRatesCut.Currency = Currencies.Ref)";
	
	Query = New Query(QueryText);
	Query.SetParameter("CurrencyCodes", CurrencyCodes);
	Query.SetParameter("Period", Period);

	Expression = FormatNumbers(Formula);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Expression = StrReplace(Expression, Selection.AlphabeticCode, Format(Selection.Rate, "NDS=.; NG=0"));
	EndDo;
	
	Return Common.CalculateInSafeMode(Expression);
	
EndFunction

Function FormatNumbers(String) Export
	
	Result = "";
	Number = "";
	IsDelimiterInNumber = False;
	PreviousChar = "";
	
	StringLength = StrLen(String);
	For IndexOf = 1 To StringLength Do
		If IndexOf < StringLength Then
			NextChar = Mid(String, IndexOf + 1, 1);
		Else
			NextChar = "";
		EndIf;
		Char = Mid(String, IndexOf, 1);
		
		PreviousCharacterThisDelimiter = PreviousChar = "" Or StrFind("()[]/*-+%=<>, ", PreviousChar) > 0;
		
		If IsDigit(Char) And (PreviousCharacterThisDelimiter Or IsDigit(PreviousChar) And ValueIsFilled(Number)) Then
			Number = Number + Char;
		ElsIf Not IsDelimiterInNumber And (Char = "," Or Char = ".") And IsDigit(NextChar)
			And (IsDigit(PreviousChar) Or PreviousCharacterThisDelimiter) And ValueIsFilled(Number) Then
			Number = Number + ".";
			IsDelimiterInNumber = True;
		Else
			Result = Result + Number + Char;
			Number = "";
			IsDelimiterInNumber = False;
		EndIf;
		
		PreviousChar = Char;
		Char = "";
	EndDo;
	
	Result = Result + Number + Char;
	Return Result;
	
EndFunction

Function IsDigit(Char)
	
	Return StrFind("1234567890", Char) > 0;
	
EndFunction

// Returns:
//  Array of CatalogRef.Currencies
//
Function CurrenciesImportedFromInternet() Export
	
	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref,
	|	Currencies.Code AS Code
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	NOT Currencies.DeletionMark
	|	AND Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)";
	
	Query = New Query(QueryText);
	Currencies = Query.Execute().Unload();
	
	CurrenciesImportedFromInternetCodes = Currencies.UnloadColumn("Code");
	CurrencyRateOperationsLocalization.OnDefineCurrencyCodesImportedFromInternet(CurrenciesImportedFromInternetCodes);
	
	Result = New Array;
	
	For Each Currency In Currencies Do
		If CurrenciesImportedFromInternetCodes.Find(Currency.Code) <> Undefined Then
			Result.Add(Currency.Ref);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf