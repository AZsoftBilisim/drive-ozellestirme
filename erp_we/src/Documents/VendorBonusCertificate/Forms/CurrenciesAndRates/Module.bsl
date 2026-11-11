// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = Parameters.ReadOnly;
	
	BonusesCurrency = Parameters.BonusesCurrency;
	ARAPCurrency = Parameters.ARAPCurrency;
	CurrencyOfMutualSettlementsAtOpening = Parameters.ARAPCurrency;
	CurrencyOfComplianceAccounting = Parameters.CurrencyOfComplianceAccounting;
	ExchangeRateNumeratorOfMutualSettlements = Parameters.ExchangeRateNumeratorOfMutualSettlements;
	TheExchangeRateIsTheDenominatorOfMutualSettlements = Parameters.TheExchangeRateIsTheDenominatorOfMutualSettlements;
	DateOfCurrencyExchangeRate = Parameters.DateOfCurrencyExchangeRate;
	Contract = Parameters.Contract;
	If Not Contract.IsEmpty() Then
		ContractRateOption = Common.ObjectAttributeValue(Contract, "ContractRateOption");
	EndIf;
	
	RateVisibility = Parameters.RateVisibility;
	GenerateCurrencyLabels(ThisObject);
	
	Items.ARAPCurrency.ReadOnly = Parameters.CurrencyChangeBan;
	
	SetCourseVisibility(ThisObject);
	FillInListOfExchangeRates();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	GenerateCurrencyLabels(ThisObject);
	SetCourseVisibility(ThisObject);
	FillInListOfExchangeRates(True);
	
EndProcedure

&AtClient
Procedure ExchangeRateNumeratorOfMutualSettlementsOnChange(Item)
	
	ClearMessages();
	
EndProcedure

&AtClient
Procedure ExchangeRateNumeratorOfMutualSettlementsChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	ProcessSelectionOfCourseFields(ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TheExchangeRateIsTheDenominatorOfMutualSettlementsChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	ProcessSelectionOfCourseFields(ValueSelected, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	ReturnedData = RebatesClientServer.EndParametersForSpecifyingExchangeRateCurrency();
	ReturnedData.ARAPCurrency = ARAPCurrency;
	
	ReturnedData.CourseNumerator = ExchangeRateNumeratorOfMutualSettlements;
	ReturnedData.CourseDenominator = TheExchangeRateIsTheDenominatorOfMutualSettlements;
	
	Close(ReturnedData);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetCourseVisibility(Form)
	
	If Form.ARAPCurrency.IsEmpty()
	 Or Form.ARAPCurrency = Form.BonusesCurrency
	 Or Form.CurrencyOfComplianceAccounting.IsEmpty() Then
		
		Form.Items.GroupExchangeRateARAPAccounting.Visible = False;
		
	Else
		
		Form.Items.GroupExchangeRateARAPAccounting.Visible = Form.RateVisibility;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ValueSelected - Number - Requesting a course date
//  				  - Structure:
//  				  	* CourseNumerator - Number -
//  				  	* CourseDenominator - Number -
//  StandardProcessing - Boolean - Standard treatment
//
&AtClient
Procedure ProcessSelectionOfCourseFields(ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = 0 Then
		
		TitleText = NStr("vi = 'Hãy chỉ ra ngày của tỷ giá hối đoái';
						|ru = 'Укажите дату курса валюты';
						|en = 'Specify the exchange rate date'; fa = 'Specify the exchange rate date';
						|it = 'Укажите дату курса валюты';
						|pl = 'Wskaż datę kursu waluty';
						|tr = 'Döviz kuru tarihi seç'");
		OnCloseNotifyHandler = New CallbackDescription("ExchangeRateOfSettlementsProcessingSelectionCompletion", ThisObject);
		ShowInputDate(
			OnCloseNotifyHandler,
			DateOfCurrencyExchangeRate,
			TitleText,
			DateFractions.Date);
		
	Else
		
		ExchangeRateNumeratorOfMutualSettlements = ValueSelected.CourseNumerator;
		TheExchangeRateIsTheDenominatorOfMutualSettlements = ValueSelected.CourseDenominator;
		ClearMessages();
		
	EndIf;
	
EndProcedure

// Parameters:
//  DateOfCourse - Undefined, Date -
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure ExchangeRateOfSettlementsProcessingSelectionCompletion(DateOfCourse, AdditionalParameters) Export
	
	If DateOfCourse <> Undefined Then
		ExchangeRateOfSettlementsProcessingSelectionOnServer(DateOfCourse);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExchangeRateOfSettlementsProcessingSelectionOnServer(Val DateOfCourse)
	
	If BonusesCurrency = CurrencyOfComplianceAccounting Then
		
		CourseAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
		ExchangeRateNumeratorOfMutualSettlements = CourseAsOfDate.CourseNumerator;
		TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAsOfDate.CourseDenominator;
		
	Else
		
		ExchangeRateOfBonusesOnDate = GetCurrencyRate(BonusesCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
		ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
		ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(ExchangeRateOfBonusesOnDate, ExchangeRateOfSettlementsAsOfDate);
		
		ExchangeRateNumeratorOfMutualSettlements = ConversionRate_1.CourseNumerator;
		TheExchangeRateIsTheDenominatorOfMutualSettlements = ConversionRate_1.CourseDenominator;
		
	EndIf;
	
	If Not CourseIsOnList(Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements) Then
			
		If DateOfCourse > CurrentSessionDate() Then
			
			AddCourseToChoiceList(
				ARAPCurrency,
				Undefined,
				CurrencyOfComplianceAccounting,
				Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList,
				CourseAsOfDate);
			AddCourseToChoiceList(
				ARAPCurrency,
				Undefined,
				CurrencyOfComplianceAccounting,
				Items.TheExchangeRateIsTheDenominatorOfMutualSettlements.ChoiceList,
				CourseAsOfDate);
			
		Else
			
			AddCourseToChoiceList(
				ARAPCurrency,
				DateOfCourse,
				CurrencyOfComplianceAccounting,
				Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList,
				CourseAsOfDate);
			AddCourseToChoiceList(
				ARAPCurrency,
				DateOfCourse,
				CurrencyOfComplianceAccounting,
				Items.TheExchangeRateIsTheDenominatorOfMutualSettlements.ChoiceList,
				CourseAsOfDate);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfExchangeRates(Val CurrencyChanged_ = False)
	
	ListOfExchangeRates = New ValueList; // ValueList of Number
	ArrayOfDaysForSelectionList = New Array; // Array of Date
	
	If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		
		ArrayOfDaysForSelectionList = GetDatesOfContractCurrencyExchangeRate();
		
	Else
		
		For DayMinus = 1 To 5 Do
			
			DateOfCourse = DateOfCurrencyExchangeRate - (DayMinus * 86400);
			ArrayOfDaysForSelectionList.Add(DateOfCourse);
			
		EndDo;
		
	EndIf; 
	
	If BonusesCurrency = CurrencyOfComplianceAccounting Then
		
		CourseAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCurrencyExchangeRate, CurrencyOfComplianceAccounting);
		If Not ValueIsFilled(ExchangeRateNumeratorOfMutualSettlements)
		 Or CurrencyChanged_ Then
			
			ExchangeRateNumeratorOfMutualSettlements = CourseAsOfDate.CourseNumerator;
			TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAsOfDate.CourseDenominator;
			
		EndIf;
		
		AddCourseToChoiceList(ARAPCurrency, DateOfCurrencyExchangeRate, CurrencyOfComplianceAccounting, ListOfExchangeRates, CourseAsOfDate);
			
		For Each DateOfCourse In ArrayOfDaysForSelectionList Do
			
			AddCourseToChoiceList(ARAPCurrency, DateOfCourse, CurrencyOfComplianceAccounting, ListOfExchangeRates);
			
		EndDo;
		ListOfExchangeRates.Add(0, NStr("vi = '<Chọn ngày khác>';
										|ru = '<Выбрать другую дату>';
										|en = '<Select another date>'; fa = '<Select another date>';
										|it = '<Выбрать другую дату>';
										|pl = '<Wybierz inną datę>';
										|tr = '<Başka bir tarih seç>'"));
		
		Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList.Clear();
		Items.TheExchangeRateIsTheDenominatorOfMutualSettlements.ChoiceList.Clear();
		
	ElsIf ValueIsFilled(BonusesCurrency)
			And ValueIsFilled(ARAPCurrency) Then
		
		ExchangeRateOfBonusesOnDate = GetCurrencyRate(BonusesCurrency, DateOfCurrencyExchangeRate, CurrencyOfComplianceAccounting);
		ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCurrencyExchangeRate, CurrencyOfComplianceAccounting);
		
		ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(ExchangeRateOfBonusesOnDate, ExchangeRateOfSettlementsAsOfDate);
		
		If CurrencyChanged_
		 Or ExchangeRateNumeratorOfMutualSettlements = 0 Then
			
			ExchangeRateNumeratorOfMutualSettlements = ConversionRate_1.CourseNumerator;
			TheExchangeRateIsTheDenominatorOfMutualSettlements = ConversionRate_1.CourseDenominator;
			
		EndIf;
		
		AddCourseToChoiceList(BonusesCurrency, DateOfCurrencyExchangeRate, ARAPCurrency, ListOfExchangeRates, ConversionRate_1);
		
		For Each DateOfCourse In ArrayOfDaysForSelectionList Do
			
			ExchangeRateOfBonusesOnDate = GetCurrencyRate(BonusesCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
			ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
			ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(
				ExchangeRateOfBonusesOnDate, ExchangeRateOfSettlementsAsOfDate);
			AddCourseToChoiceList(
				BonusesCurrency,
				DateOfCourse,
				ARAPCurrency,
				ListOfExchangeRates,
				ConversionRate_1);
			
		EndDo;
		
		ListOfExchangeRates.Add(0, NStr("vi = '<Chọn ngày khác>';
										|ru = '<Выбрать другую дату>';
										|en = '<Select another date>'; fa = '<Select another date>';
										|it = '<Выбрать другую дату>';
										|pl = '<Wybierz inną datę>';
										|tr = '<Başka bir tarih seç>'"));
		
	EndIf;
	
	Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList.Clear();
	Items.TheExchangeRateIsTheDenominatorOfMutualSettlements.ChoiceList.Clear();
	
	For Each CourseAsOfDate In ListOfExchangeRates Do
		
		Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
		Items.TheExchangeRateIsTheDenominatorOfMutualSettlements.ChoiceList.Add(CourseAsOfDate.Value, CourseAsOfDate.Presentation);
		
	EndDo;
	
	If Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList.Count() > 0
	   And ValueIsFilled(ExchangeRateNumeratorOfMutualSettlements) Then
		
		If Not CourseIsOnList(Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements) Then
			
			ExchangeRateOfBonusesOnDate = GetCurrencyRate(BonusesCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
			ExchangeRateOfSettlementsAsOfDate = GetCurrencyRate(ARAPCurrency, DateOfCourse, CurrencyOfComplianceAccounting);
			ConversionRate_1 = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(
				ExchangeRateOfBonusesOnDate, ExchangeRateOfSettlementsAsOfDate);
			
			AddCourseToChoiceList(
				BonusesCurrency,
				DateOfCourse,
				ARAPCurrency,
				Items.ExchangeRateNumeratorOfMutualSettlements.ChoiceList,
				ConversionRate_1);
			
			AddCourseToChoiceList(
				BonusesCurrency,
				DateOfCourse,
				ARAPCurrency,
				Items.TheExchangeRateIsTheDenominatorOfMutualSettlements.ChoiceList,
				ConversionRate_1);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetDatesOfContractCurrencyExchangeRate()
	
	Query = New Query;
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("DateOfCurrencyExchangeRate", DateOfCurrencyExchangeRate);
	
	Query.Text =
	"SELECT TOP 5
	|	ARAPAccountingExchangeRatesForContracts.Period AS Period
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts AS ARAPAccountingExchangeRatesForContracts
	|WHERE
	|	ARAPAccountingExchangeRatesForContracts.Contract = &Contract
	|	AND ARAPAccountingExchangeRatesForContracts.Period < &DateOfCurrencyExchangeRate
	|	AND ARAPAccountingExchangeRatesForContracts.Period > DATETIME(1980, 1, 1)
	|
	|ORDER BY
	|	Period DESC";
	
	Return Query.Execute().Unload().UnloadColumn("Period");
	
EndFunction

&AtServer
Function GetCurrencyRate(Currency, Date, BaseCurrency)
	
	If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		
		Result = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, Date);
		Result.Insert("Currency", BonusesCurrency);
		Result.Insert("BaseCurrency", BaseCurrency);
		If Result.Property("CourseIsNotSet")
		   And Result.CourseIsNotSet Then
			Result = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date, BaseCurrency)
		EndIf;
		
	Else
		
		Result = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date, BaseCurrency)
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function CourseIsOnList(List, CourseNumerator, CourseDenominator)
	
	CourseFound = False;
	For Each ChoiceItem In List Do
		
		ElementValue = ChoiceItem.Value;
		If TypeOf(ElementValue) = Type("Structure") Then
			 
			If CourseNumerator = ElementValue.CourseNumerator
			   And CourseDenominator = ElementValue.CourseDenominator Then
				
				CourseFound = True;
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return CourseFound;
	
EndFunction

// Parameters:
//  Currency - CatalogRef.Currencies
//  Date - Date, Undefined -
//  BaseCurrency  - CatalogRef.Currencies
//  ChoiceList - ValueList of Structure
//  RateStructure - See ProcessingOfExchangeRatesTM.GetCurrencyRate 
//
&AtServer
Procedure AddCourseToChoiceList(Currency, Date, BaseCurrency, ChoiceList, RateStructure = Undefined)
	
	If RateStructure = Undefined Then
		RateStructure = GetCurrencyRate(Currency, Date, BaseCurrency);
	EndIf;
	
	PresentationTemplateWithDate = NStr("vi = '%1 %2 = %3 %4 (cho %5)';
										|ru = '%1 %2 = %3 %4 (на %5)';
										|en = '%1 %2 = %3 %4 (as of %5)'; fa = '%1 %2 = %3 %4 (as of %5)';
										|it = '%1 %2 = %3 %4 (на %5)';
										|pl = '%1 %2 = %3 %4 (as of %5)';
										|tr = '%1 %2 = %3 %4 (%5 konumunda)'");;
	PresentationTemplateWithoutDate = NStr("vi = '%1 %2 = %3 %4';
											|ru = '%1 %2 = %3 %4';
											|en = '%1 %2 = %3 %4'; fa = '%1 %2 = %3 %4';
											|it = '%1 %2 = %3 %4';
											|pl = '%1 %2 = %3 %4';
											|tr = '%1 %2 = %3 %4'");;
	
	If Date = Undefined Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			PresentationTemplateWithoutDate,
			Format(RateStructure.CourseNumerator, "NFD=4"),
			String(BaseCurrency),
			Format(RateStructure.CourseDenominator, "NFD=4"),
			String(Currency));
		
	Else
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			PresentationTemplateWithDate,
			Format(RateStructure.CourseNumerator, "NFD=4"),
			String(BaseCurrency),
			Format(RateStructure.CourseDenominator, "NFD=4"),
			String(Currency),
			Format(Date, "DLF = D"));
		
	EndIf;
	
	ChoiceList.Add(RateStructure, Presentation);
	
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateCurrencyLabels(Form)
	
	If Form.BonusesCurrency = Form.CurrencyOfComplianceAccounting Then
		
		Form.ExchangeRateNumeratorOfMutualSettlementsInscription = String(Form.BonusesCurrency) + " =";
		Form.CourseDenominatorOfMutualSettlementsInscription = String(Form.ARAPCurrency);
		
	Else
		
		Form.ExchangeRateNumeratorOfMutualSettlementsInscription = String(Form.ARAPCurrency) + " =";
		Form.CourseDenominatorOfMutualSettlementsInscription = String(Form.BonusesCurrency);
		
	EndIf;
	
EndProcedure

#EndRegion