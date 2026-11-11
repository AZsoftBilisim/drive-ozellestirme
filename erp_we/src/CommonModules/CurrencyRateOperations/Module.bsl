///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Adds the given currencies from the classifier to the currency catalog.
// Intended to be invoked from initial population handlers.
//
// If no classifier is found, the added currencies have the name "Currency"
// and the code that matches its numeric code.
//
// Parameters:
//   CurrencyCodes - Array of String - Numeric codes for the currencies to be added.
//
// Returns:
//   Array of CatalogRef.Currencies
//
Function AddCurrenciesByCode(Val CurrencyCodes) Export
	
	Result = New Array;
	StandardProcessing = True;
	CurrencyRateOperationsLocalization.OnAddCurrenciesByCode(CurrencyCodes, Result, StandardProcessing);
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	For Each CurrencyCode_ In CurrencyCodes Do
		CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode_);
		If CurrencyRef.IsEmpty() Then
			CurrencyObject = Catalogs.Currencies.CreateItem();
			CurrencyObject.Code = CurrencyCode_;
			CurrencyObject.Description = CurrencyCode_;
			CurrencyObject.DescriptionFull = NStr("vi = 'Tiền tệ';
													|ru = 'Валюта';
													|en = 'Currency'; fa = 'ارز';
													|it = 'Valuta';
													|pl = 'Currency';
													|tr = 'Para birimi'");
			CurrencyObject.RateSource = Enums.RateSources.ManualInput;
			CurrencyObject.Write();
			CurrencyRef = CurrencyObject.Ref;
		EndIf;
		Result.Add(CurrencyRef);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a currency rate for a specific date.
//
// Parameters:
//   Currency    - CatalogRef.Currencies - the currency, for which the exchange rate is calculated.
//   DateOfCourse - Date - the date the exchange rate is calculated for.
//
// Returns: 
//   Structure:
//    * Rate      - Number - the currency rate as of the specified date.
//    * Repetition - Number - the currency rate multiplier as of the specified date.
//    * Currency    - CatalogRef.Currencies - the reference to the currency.
//    * DateOfCourse - Date - the exchange rate date.
//
Function GetCurrencyRate(Currency, DateOfCourse) Export
	
	Result = InformationRegisters.ExchangeRates.GetLast(DateOfCourse, New Structure("Currency", Currency));
	
	Result.Insert("Currency",    Currency);
	Result.Insert("DateOfCourse", DateOfCourse);
	
	Return Result;
	
EndFunction

// Generates a presentation of an amount of a given currency in words.
//
// Parameters:
//   AmountAsNumber - Number - the amount to be presented in words.
//   Currency - CatalogRef.Currencies - the currency the amount must be presented in.
//   OmitFractionalPart - Boolean - specify as True if a sum should be presented without a fractional part (kopeks, cents, etc.).
//   LanguageCode - String - a language in which the amount in words needs to be displayed.
//                       Consists of the ISO 639-1 language code and the ISO 3166-1 country code (optional)
//                       separated by the underscore character. Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//                       The default value is the configuration language.
//   IsFractionalPartInWords - Boolean
//
// Returns:
//   String - the amount in words.
//
Function GenerateAmountInWords(AmountAsNumber, Currency, OmitFractionalPart = False, Val LanguageCode = Undefined, IsFractionalPartInWords = False) Export
	
	AmountInWordsParameters = Common.ObjectAttributeValue(Currency, "AmountInWordsParameters", , LanguageCode);
	
	If Not ValueIsFilled(LanguageCode) Then
		LanguageCode = Common.DefaultLanguageCode();
	EndIf;
	
	Sum = ?(AmountAsNumber < 0, -AmountAsNumber, AmountAsNumber);
	Format = StrTemplate("L=%1;DE=%2", LanguageCode, ?(IsFractionalPartInWords, "True", "False"));
	Result = NumberInWords(Sum, Format, AmountInWordsParameters); // ACC:1297 ACC:1357
	If OmitFractionalPart And Int(Sum) = Sum Then
		Result = Left(Result, StrFind(Result, "0") - 1);
	EndIf;
	
	Return Result;
	
EndFunction

// Converts an amount from one currency to another.
//
// Parameters:
//  Sum          - Number - the source amount.
//  SourceCurrency - CatalogRef.Currencies - the source currency.
//  NewCurrency    - CatalogRef.Currencies - the new currency.
//  Date           - Date - the exchange rate date.
//
// Returns:
//  Number - the converted amount.
//
Function ConvertToCurrency(Sum, SourceCurrency, NewCurrency, Date) Export
	
	Return CurrencyRateOperationsClientServer.ConvertAtRate(Sum,
		GetCurrencyRate(SourceCurrency, Date),
		GetCurrencyRate(NewCurrency, Date));
		
EndFunction

// Used in constructor of the Number for money fields type.
//
// Parameters:
//  AllowedSignOfField - AllowedSign - indicates the allowed sign of a number. Value by default - AllowedSign.Any.
// 
// Returns:
//  TypeDescription - type of a value for a money field.
//
Function MoneyFieldTypeDescription(Val AllowedSignOfField = Undefined) Export
	
	If AllowedSignOfField = Undefined Then
		AllowedSignOfField = AllowedSign.Any;
	EndIf;
	
	If AllowedSignOfField = AllowedSign.Any Then
		Return Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type;
	EndIf;
	
	Return Metadata.DefinedTypes.MonetaryAmountNonNegative.Type;
	
EndFunction

// Allows to output numeric attributes in words on print forms.
// Called from PrintManagementOverridable.OnPrintDataSourcesDefine.
// 
// Parameters:
//  PrintDataSources - See PrintManagementOverridable.OnDefinePrintDataSources.PrintDataSources
//  FieldSourceName - String - Full name of the metadata object used to calculate currency fields for spelled-out amounts.
//                               If not specified, add the default field and the first currency attribute in the list of print object metadata.
//                               
//
Procedure ConnectPrintDataSourceNumberWritten(PrintDataSources, FieldSourceName = "") Export
	
	CompositionSchema = SchemaDataPrintAmountWords(FieldSourceName);
	If CompositionSchema <> Undefined Then
		PrintDataSources.Add(CompositionSchema, "DataPrintAmountWords");
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not IsCurrencyRatesImportAvailable() Then
		Return;
	EndIf;

	CurrencyRateOperationsLocalization.OnFillToDoList(ToDoList);
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Import to the currency classifier is denied.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.Currencies.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.Currencies.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
Procedure OnDefineScheduledJobSettings(Settings) Export
	CurrencyRateOperationsLocalization.OnDefineScheduledJobSettings(Settings);
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment.
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.ReadCurrencyRates.Name);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	ShouldNotifyWhenExchageRatesOutdated = ShouldNotifyWhenExchageRatesOutdated();
	
	Parameters.Insert("Currencies", New FixedStructure("ExchangeRatesUpdateRequired",
		ShouldNotifyWhenExchageRatesOutdated And Not RatesUpToDate()));
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.ExchangeRates.FullName());
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	CurrencyRateOperationsLocalization.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	CurrencyRateOperationsLocalization.OnAddUpdateHandlers(Handlers);
	
EndProcedure

// See the Internet user support is undetectable.When changing the data of the identification of the Internet support.
Procedure OnChangeOnlineSupportAuthenticationData(UserData) Export
	
	CurrencyRateOperationsLocalization.OnChangeOnlineSupportAuthenticationData(UserData);
	
EndProcedure

// Checks whether the exchange rate and multiplier as of January 1, 1980, are available.
// If they are not available, sets them both to one.
//
// Parameters:
//  Currency - a reference to a Currencies catalog item.
//
Procedure CheckCurrencyRateAvailabilityFor01011980(Currency) Export
	
	DateOfCourse = Date("19800101");
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExchangeRates");
	LockItem.SetValue("Currency", Currency);
	LockItem.SetValue("Period", DateOfCourse);
	
	BeginTransaction();
	Try
		Block.Lock();
		RateStructure = InformationRegisters.ExchangeRates.GetLast(DateOfCourse, New Structure("Currency", Currency));
		
		If (RateStructure.Rate = 0) Or (RateStructure.Repetition = 0) Then
			RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
			RecordSet.Filter.Currency.Set(Currency);
			RecordSet.Filter.Period.Set(DateOfCourse);
			Record = RecordSet.Add();
			Record.Currency = Currency;
			Record.Period = DateOfCourse;
			Record.Rate = 1;
			Record.Repetition = 1;
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// See PrintManagementOverridable.WhenPreparingPrintData
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, DataCompositionSchemaId, LanguageCode,
	AdditionalParameters) Export
	
	If DataCompositionSchemaId = "DataPrintAmountWords" Then
		ExternalDataSets.Insert("Data", 
			DataPrintAmountWords(AdditionalParameters.DataSourceDescriptions, LanguageCode));
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns:
//  Boolean
//
Function IsCurrencyRatesImportAvailable() Export

	Result = False;
	CurrencyRateOperationsLocalization.OnDefineImportAvailabilityOfCurrencyRates(Result);
	Return Result;

EndFunction

#Region ExportServiceProceduresAndFunctions

// Returns an array of currencies whose exchange rates are imported from external resources.
//
Function CurrenciesToImport() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND NOT Currencies.DeletionMark
	|
	|ORDER BY
	|	Currencies.DescriptionFull";

	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function FillCurrencyRateData(SelectedCurrency) Export
	
	RateData = New Structure("DateOfCourse, Rate, Repetition");
	
	Query = New Query;
	
	Query.Text = "SELECT RegRates.Period, RegRates.Rate, RegRates.Repetition
	              | FROM InformationRegister.ExchangeRates.SliceLast(&ImportPeriodEnd, Currency = &SelectedCurrency) AS RegRates";
	Query.SetParameter("SelectedCurrency", SelectedCurrency);
	Query.SetParameter("ImportPeriodEnd", CurrentSessionDate());
	
	SelectionRate = Query.Execute().Select();
	SelectionRate.Next();
	
	RateData.DateOfCourse = SelectionRate.Period;
	RateData.Rate      = SelectionRate.Rate;
	RateData.Repetition = SelectionRate.Repetition;
	
	Return RateData;
	
EndFunction

Function DependentCurrenciesList(BaseCurrency, AdditionalProperties = Undefined) Export
	
	Cached = (TypeOf(AdditionalProperties) = Type("Structure"));
	
	If Cached Then
		
		DependentCurrencies = AdditionalProperties.DependentCurrencies.Get(BaseCurrency);
		
		If TypeOf(DependentCurrencies) = Type("ValueTable") Then
			Return DependentCurrencies;
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CatCurrencies.Ref,
	|	CatCurrencies.Markup,
	|	CatCurrencies.RateSource,
	|	CatCurrencies.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CatCurrencies
	|WHERE
	|	CatCurrencies.MainCurrency = &BaseCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	CatCurrencies.Ref,
	|	CatCurrencies.Markup,
	|	CatCurrencies.RateSource,
	|	CatCurrencies.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CatCurrencies
	|WHERE
	|	CatCurrencies.RateCalculationFormula LIKE &AlphabeticCode ESCAPE ""~""";
	
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("AlphabeticCode", "%" +  Common.GenerateSearchQueryString(BaseCurrency) + "%");
	DependentCurrencies = Query.Execute().Unload();	
	If Cached Then		
		AdditionalProperties.DependentCurrencies.Insert(BaseCurrency, DependentCurrencies);		
	EndIf;
	
	Return DependentCurrencies;
	
EndFunction

Procedure UpdateCurrencyRate(Parameters, ResultAddress) Export
	
	DependentCurrency = Parameters.Currency;
	ListOfCurrencies = Parameters.Currency.CurrenciesUsedInCalculatingTheExchangeRate;
	
	QueryText =
	"SELECT
	|	ExchangeRates.Period AS Period,
	|	ExchangeRates.Currency AS Currency
	|FROM
	|	InformationRegister.ExchangeRates AS ExchangeRates
	|WHERE
	|	ExchangeRates.Currency IN(&Currency)
	|
	|GROUP BY
	|	ExchangeRates.Period,
	|	ExchangeRates.Currency
	|
	|ORDER BY
	|	Period";
	
	Query = New Query(QueryText);
	Query.SetParameter("Currency", ListOfCurrencies);
	
	Selection = Query.Execute().Select();
	
	UpdatedPeriods = New Map;
	While Selection.Next() Do
		If UpdatedPeriods[Selection.Period] <> Undefined Then 
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			For Each Currency In ListOfCurrencies Do
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.ExchangeRates");
				LockItem.SetValue("Currency", Currency);
				LockItem.SetValue("Period", Selection.Period);
			EndDo;
			Block.Lock();
			
			RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
			RecordSet.Filter.Currency.Set(Selection.Currency);
			RecordSet.Filter.Period.Set(Selection.Period);
			RecordSet.Read();
			RecordSet.AdditionalProperties.Insert("UpdateSubordinateCurrencyRate", DependentCurrency);
			RecordSet.AdditionalProperties.Insert("CurrencyCodes", Parameters.CurrencyCodes);
			RecordSet.AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			RecordSet.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		UpdatedPeriods.Insert(Selection.Period, True);
	EndDo;
	
EndProcedure

#EndRegion

#Region ExchangeRateUpdate

// Checks whether all currency rates are up-to-date.
//
Function RatesUpToDate() Export
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref
	|INTO ttCurrencies
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND Currencies.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	ttCurrencies AS Currencies
	|		LEFT JOIN InformationRegister.ExchangeRates AS ExchangeRates
	|		ON Currencies.Ref = ExchangeRates.Currency
	|			AND (ExchangeRates.Period = &CurrentDate)
	|WHERE
	|	ExchangeRates.Currency IS NULL ";
	
	Query = New Query;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.Text = QueryText;
	
	Return Query.Execute().IsEmpty();
EndFunction

// Intended for procedure OnAddClientParametersOnStart
//
Function ShouldNotifyWhenExchageRatesOutdated()
	
	// Auto-updates in SaaS.
	If Common.DataSeparationEnabled() Or Common.IsStandaloneWorkplace() 
		Or Not CurrencyRateOperationsInternal.HasRightToChangeExchangeRates() Then
		Return False;
	EndIf;
	
	EnableNotifications = Not Common.SubsystemExists("StandardSubsystems.ToDoList");
	CurrencyRateOperationsOverridable.OnDetermineWhetherCurrencyRateUpdateWarningRequired(EnableNotifications);
	
	Return EnableNotifications;
	
EndFunction

#EndRegion

#Region Print

Function SchemaDataPrintAmountWords(FieldSourceName)
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		
		Return Undefined;
		
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	
	FieldList = ModulePrintManager.PrintDataFieldTable();
	
	Field = FieldList.Add();
	Field.Id = "Ref";
	Field.Presentation = NStr("vi = 'Tham chiếu';
								|ru = 'Ссылка';
								|en = 'Ref'; fa = 'مرجع';
								|it = 'Collegamento';
								|pl = 'Odnośnik';
								|tr = 'Bağlantı'");
	Field.ValueType = New TypeDescription();
	
	Field = FieldList.Add();
	Field.Id = "Currency";
	Field.Presentation = NStr("ru = 'Валюта по умолчанию';
								|vi = 'Default value';
								|en = 'Default value'; fa = 'مقدار پیش‌فرض';
								|it = 'Valuta da impostazione predefinita';
								|pl = 'Waluta domyślna';
								|tr = 'Varsayılan para birimi'");
	Field.ValueType = New TypeDescription();
	
	Field = FieldList.Add();
	Field.Id = "NumberInWords";
	Field.Presentation = NStr("ru = 'Прописью (с валютой по умолчанию)';
								|vi = 'In words (with default value)';
								|en = 'In words (with default value)'; fa = 'In words (with default value)';
								|it = 'In words (with default value)';
								|pl = 'In words (with default value)';
								|tr = 'Yazıyla (varsayılan para birimi ile)'");
	Field.ValueType = New TypeDescription("String");
	
	If Not IsBlankString(FieldSourceName) Then
		
		SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FieldSourceName, ".");
		TwoStringsArray = 2;
		
		If SubstringsArray.Count() >= TwoStringsArray Then
			
			ObjectNameSubstringsArray = New Array;
			ObjectNameSubstringsArray.Add(SubstringsArray[0]);
			ObjectNameSubstringsArray.Add(SubstringsArray[1]);
			ObjectName = StrConcat(ObjectNameSubstringsArray, ".");
			MetadataObject = Common.MetadataObjectByFullName(ObjectName);
			
			If MetadataObject <> Undefined Then
				
				CurrencyAttributesTable = ObjectCurrencyAttributesTable(MetadataObject);
				ObjectType = StandardSubsystemsServer.MetadataObjectReferenceOrMetadataObjectRecordKeyType(MetadataObject);
				DefaultCurrencyData = CurrencyData();
				GetDefaultCurrencyFieldForObject(ObjectType, CurrencyAttributesTable, DefaultCurrencyData);
				
				If Not IsBlankString(DefaultCurrencyData.FieldPresentation)
				   And DefaultCurrencyData.IsOverridden Then
					
					FieldPresentation = DefaultCurrencyData.FieldPresentation;
					TableRow = FieldList.Find("Currency", "Id");
					TableRow.Presentation = TableRow.Presentation + " (" + FieldPresentation + ")";
					
				EndIf;
				
				For Each Attribute In CurrencyAttributesTable Do
					
					Id = NumberInWordsFieldID(Attribute.Id);
					If FieldList.Find(Id, "Id") = Undefined Then
						
						Field = FieldList.Add();
						Field.Id = Id;
						Field.Presentation = NumberInWordsFieldPresentation(Attribute.Presentation);
						Field.ValueType = New TypeDescription("String");
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ModulePrintManager.SchemaCompositionDataPrint(FieldList);
	
EndFunction

Function DataPrintAmountWords(DataSourceDescriptions, LanguageCode)
	
	PrintData = New ValueTable();
	PrintData.Columns.Add("Ref");
	PrintData.Columns.Add("Currency");
	PrintData.Columns.Add("NumberInWords");
	
	Result = DataSourcesDescriptionsByMetadata(DataSourceDescriptions);
	MetadataObjects = Result.MetadataObjects;
	MetadataLinks = Result.MetadataLinks;
	
	MetadataObjects = CommonClientServer.CollapseArray(MetadataObjects);
	
	For Each MetadataObject In MetadataObjects Do
		
		ObjectType = StandardSubsystemsServer.MetadataObjectReferenceOrMetadataObjectRecordKeyType(MetadataObject);
		CurrencyAttributesTable = ObjectCurrencyAttributesTable(MetadataObject);
		
		For Each Attribute In CurrencyAttributesTable Do
			
			ColumnName = NumberInWordsFieldID(Attribute.Id);
			If PrintData.Columns.Find(ColumnName) = Undefined Then
				PrintData.Columns.Add(ColumnName);
			EndIf;
			
		EndDo;
		
		ReferencesArrray = CommonClientServer.CollapseArray(MetadataLinks[MetadataObject]);
		FieldArray = CurrencyAttributesTable.UnloadColumn("Id");
		CurrencyAttributesValues = New Map;
		If FieldArray.Count() > 0 Then
			CurrencyAttributesValues = Common.ObjectsAttributesValues(ReferencesArrray, FieldArray);
		EndIf;
		
		DefaultCurrencyData = CurrencyData();
		GetDefaultCurrencyFieldForObject(ObjectType, CurrencyAttributesTable, DefaultCurrencyData, True);
		
		For Each CurrentRef In ReferencesArrray Do
			
			LinkCurrencyAttributeValues = CurrencyAttributesValues[CurrentRef];
			If Not IsBlankString(DefaultCurrencyData.FieldName)
			   And Not ValueIsFilled(DefaultCurrencyData.CurrencyValue) Then
				
				FieldName = DefaultCurrencyData.FieldName;
				If LinkCurrencyAttributeValues.Property(FieldName) Then
					DefaultCurrencyData.CurrencyValue = LinkCurrencyAttributeValues[FieldName];
				EndIf;
				
			EndIf;
			
			Filter = New Structure;
			Filter.Insert("Owner", CurrentRef);
			DataSourcesDescriptionsByLink = DataSourceDescriptions.FindRows(Filter);
			
			ParametersForCurrencyFilling = New Structure;
			ParametersForCurrencyFilling.Insert("CurrencyAttributesTable", CurrencyAttributesTable);
			ParametersForCurrencyFilling.Insert("LinkCurrencyAttributeValues", LinkCurrencyAttributeValues);
			ParametersForCurrencyFilling.Insert("DefaultCurrency", DefaultCurrencyData);
			
			FillFieldsWithAmountInWords(
				DataSourcesDescriptionsByLink,
				PrintData,
				ParametersForCurrencyFilling,
				LanguageCode);
			
		EndDo;
		
	EndDo;
	
	Return PrintData;
	
EndFunction

// Parameters:
//  DataSourceDescriptions - ValueTable:
//  * Owner - AnyRef
//  * Name - String
//  * Value - Arbitrary 
// 
// Returns:
//  Structure:
//  * MetadataObjects - Array of MetadataObject
//  * MetadataLinks - Map of KeyAndValue:
//   ** Key - MetadataObject
//   ** Value - AnyRef  
//
Function DataSourcesDescriptionsByMetadata(Val DataSourceDescriptions)
	
	MetadataObjects = New Array; // Array of MetadataObject
	MetadataLinks = New Map;
	
	For Each SourceDetails In DataSourceDescriptions Do
		
		If Common.IsReference(TypeOf(SourceDetails.Owner)) Then
			
			MetadataObject = Metadata.FindByType(TypeOf(SourceDetails.Owner));
			
			If MetadataObjects.Find(MetadataObject) = Undefined Then
				
				ReferencesArrray = New Array; // Array of AnyRef
				MetadataLinks.Insert(MetadataObject, ReferencesArrray);
				
			EndIf;
			
			MetadataLinks[MetadataObject].Add(SourceDetails.Owner);
			MetadataObjects.Add(MetadataObject);
			
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("MetadataObjects", MetadataObjects);
	Result.Insert("MetadataLinks", MetadataLinks);
	
	Return Result;
	
EndFunction

Procedure GetDefaultCurrencyFieldForObject(ObjectType, CurrencyAttributesTable, DefaultCurrencyData, PrintData = False)
	
	FullPathToCurrencyField = "";
	NameOfCurrenciesField = "";
	IsCurrencyFieldDefined = False;
	
	If CurrencyAttributesTable.Count() > 0 Then
		
		FullPathToCurrencyField = CurrencyAttributesTable[0].Id;
		
	EndIf;
	
	FullPathToCurrencyOld = FullPathToCurrencyField;
	CurrencyRateOperationsOverridable.OnDefineObjectDefaultCurrency(ObjectType, FullPathToCurrencyField);
	SubstringsArray = New Array; // Array of String
	If Not IsBlankString(FullPathToCurrencyField) Then
		
		SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullPathToCurrencyField, ".");
		NameOfCurrenciesField = SubstringsArray[SubstringsArray.UBound()];
		
	EndIf;
	
	// If SubstringsArray contains more than one string, pass the name of the common list field as the field name
	SubstringsMaxCount = 2;
	PathToCommonField = "CommonField";
	If SubstringsArray.Count() = 1 Then
		
		TableRow = CurrencyAttributesTable.Find(NameOfCurrenciesField, "Id");
		If TableRow <> Undefined Then
			
			DefaultCurrencyData.FieldName = NameOfCurrenciesField;
			DefaultCurrencyData.FieldPresentation = TableRow.Presentation;
			DefaultCurrencyData.IsOverridden = (FullPathToCurrencyOld <> NameOfCurrenciesField);
			IsCurrencyFieldDefined = True;
			
		EndIf;
		
	ElsIf SubstringsArray.Count() = SubstringsMaxCount
	   And SubstringsArray[0] = PathToCommonField 
	   And Common.SubsystemExists("StandardSubsystems.Print") Then
		
		CommonFieldsTable = CommonFieldsTableForPrint();
		ModulePrintManagerOverridable = Common.CommonModule("PrintManagementOverridable");
		ModulePrintManagerOverridable.OnFillListOfCommonFields(ObjectType, CommonFieldsTable);
		TableRow = CommonFieldsTable.Find(NameOfCurrenciesField, "Id");
		
		If TableRow <> Undefined Then
			
			DefaultCurrencyData.FieldName = NameOfCurrenciesField;
			DefaultCurrencyData.FieldPresentation = TableRow.Presentation;
			DefaultCurrencyData.CurrencyValue = TableRow.Value;
			DefaultCurrencyData.IsOverridden = True;
			IsCurrencyFieldDefined = True;
			
		EndIf;
		
	EndIf;
	
	If Not IsCurrencyFieldDefined
	   And Not IsBlankString(FullPathToCurrencyField)
	   And PrintData Then
		
		MessageTemplate = NStr("ru = 'Для типа объекта ""%1"" неверно указано имя поля ""%2"" для определения валюты по умолчанию';
								|vi = 'The ""%2"" field name for the object type ""%1"" for determining the default currency is incorrect.';
								|en = 'The ""%2"" field name for the object type ""%1"" for determining the default currency is incorrect.'; fa = 'The ""%2"" field name for the object type ""%1"" for determining the default currency is incorrect.';
								|it = 'The ""%2"" field name for the object type ""%1"" for determining the default currency is incorrect.';
								|pl = 'The ""%2"" field name for the object type ""%1"" for determining the default currency is incorrect.';
								|tr = '""%1"" nesne türü için varsayılan para birimini belirleyecek ""%2"" alan adı yanlış belirtilmiş'");
		MessagesText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			String(ObjectType),
		FullPathToCurrencyField);
		Common.MessageToUser(MessagesText);
		
	EndIf;
	
EndProcedure

Procedure FillFieldsWithAmountInWords(DataSourceDescriptions, PrintData, ParametersForCurrencyFilling, LanguageCode)
	
	CurrencyAttributesTable = ParametersForCurrencyFilling.CurrencyAttributesTable;
	LinkCurrencyAttributeValues = ParametersForCurrencyFilling.LinkCurrencyAttributeValues;
	DefaultCurrency = ParametersForCurrencyFilling.DefaultCurrency;
	
	If IsBlankString(DefaultCurrency.FieldPresentation)
	   And LinkCurrencyAttributeValues = Undefined Then
		Return;
	EndIf;
	
	For Each SourceDetails In DataSourceDescriptions Do
		
		TableRow = PrintData.Add();
		TableRow.Ref = SourceDetails.Value;
		
		IsDefaultCurrencyAdded =
			AddDefaultCurrency(TableRow, DefaultCurrency, SourceDetails, LanguageCode);
		
		If LinkCurrencyAttributeValues = Undefined Then
			Continue;
		EndIf;
		
		AttributesCounter = 0;
		For Each Attribute In CurrencyAttributesTable Do
			
			AttributesCounter = AttributesCounter + 1;
			Currency = LinkCurrencyAttributeValues[Attribute.Id];
			
			If Not ValueIsFilled(Currency) Then
				Continue;
			EndIf;
			
			If AttributesCounter = 1
			   And Not IsDefaultCurrencyAdded  Then
				
				TableRow.Currency = Currency;
				TableRow.NumberInWords =
					GenerateAmountInWords(SourceDetails.Value, Currency,, LanguageCode);
				
			EndIf;
			
			ColumnName = NumberInWordsFieldID(Attribute.Id);
			TableRow[ColumnName] = GenerateAmountInWords(SourceDetails.Value, Currency,, LanguageCode);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function AddDefaultCurrency(TableRow, DefaultCurrency, SourceDetails, LanguageCode)
	
	IsDefaultCurrencyAdded = False;
	
	If Not IsBlankString(DefaultCurrency.FieldPresentation) Then
		
		IsDefaultCurrencyAdded = True;
		
		If ValueIsFilled(DefaultCurrency.CurrencyValue) Then
			
			TableRow.Currency = DefaultCurrency.CurrencyValue;
			TableRow.NumberInWords = 
				GenerateAmountInWords(SourceDetails.Value, DefaultCurrency.CurrencyValue,, LanguageCode);
			
		EndIf;
		
	EndIf;
	
	Return IsDefaultCurrencyAdded;
	
EndFunction

Function ObjectCurrencyAttributesTable(MetadataObject)
	
	CurrenciesFieldsTable = CurrencyFieldsTableForPrint();
	
	For Each Attribute In MetadataObject.Attributes Do
		
		If Attribute.Type.ContainsType(Type("CatalogRef.Currencies")) Then
			
			NewRow = CurrenciesFieldsTable.Add();
			NewRow.Id = Attribute.Name;
			NewRow.Presentation = Attribute.Synonym;
			
		EndIf;
		
	EndDo;
	
	Return CurrenciesFieldsTable;
	
EndFunction

// Returns:
//  Structure - Default currency data:
// * CurrencyValue - CatalogRef.Currencies 
// * FieldName - String 
// * FieldPresentation - String
// * IsOverridden - Boolean
//
Function CurrencyData()
	
	CurrencyData = New Structure;
	CurrencyData.Insert("CurrencyValue", Catalogs.Currencies.EmptyRef());
	CurrencyData.Insert("FieldName", "");
	CurrencyData.Insert("FieldPresentation", "");
	CurrencyData.Insert("IsOverridden", False);
	
	Return CurrencyData;
	
EndFunction

// Returns:
//  ValueTable - Table with currency to print out:
// * Id - String
// * Presentation - String
//
Function CurrencyFieldsTableForPrint()
	
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Id", New TypeDescription("String"));
	ValueTable.Columns.Add("Presentation", New TypeDescription("String"));
	
	Return ValueTable;
	
EndFunction

// Returns:
//  ValueTable - New table with common fields:
// * Id - String
// * Presentation - String
// * Value -AnyRef
// 
Function CommonFieldsTableForPrint()
	
	CommonFieldsTable = New ValueTable;
	CommonFieldsTable.Columns.Add("Id", New TypeDescription("String"));
	CommonFieldsTable.Columns.Add("Presentation", New TypeDescription("String"));
	CommonFieldsTable.Columns.Add("Value");
	
	Return CommonFieldsTable;
	
EndFunction

Function NumberInWordsFieldID(Id)
	
	Return "NumberInWords" + "_" + StrReplace(Id, ".", "_");
	
EndFunction

Function NumberInWordsFieldPresentation(Presentation)
	
	Return NStr("ru = 'Прописью';
				|vi = 'In words';
				|en = 'In words'; fa = 'به حروف';
				|it = 'In words';
				|pl = 'In words';
				|tr = 'Yazıyla'" )  + " (" + Presentation + ")";
	
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateCurrencyRate", True);
	
EndProcedure

#EndRegion