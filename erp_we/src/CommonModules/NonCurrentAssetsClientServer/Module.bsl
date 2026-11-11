////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates a representation of the number of months as a string "X years X months".
//
// Parameters:
//  NumberOfMonths	- Number		- Number of months.
//  EncloseInBrackets	- Boolean	- True if the term must be enclosed in parentheses.
// 
// Returns:
//  String - decoding the useful life in years and months.
//
Function PresentationOfNumberOfMonthsByString(NumberOfMonths, EncloseInBrackets = True) Export

	If Not ValueIsFilled(NumberOfMonths) Then
		Return "";
	EndIf;
	
	NumberOfYears_ = Int(NumberOfMonths / 12);
	CountOfMonths = (NumberOfMonths % 12);
	
	UsefulLifeExplanation = "";
	
	If NumberOfYears_ <> 0 Then
		UsefulLifeExplanation =
			StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 năm;;%1 năm;%1 năm;%1 năm';
																			|ru = ';%1 год;;%1 года;%1 лет;%1 года';
																			|en = ';%1 year;;%1 years;%1 years;%1 years'; fa = ';%1 year;;%1 years;%1 years;%1 years';
																			|it = ',%1 anno;;%1 anni;%1 anni;%1 anni';
																			|pl = ';%1 rok;;%1 lata;%1 lat;%1 lata';
																			|tr = ';%1 yıl;;%1 yıl;%1 yıl;%1 yıl'"), NumberOfYears_);
	EndIf;
	
	If CountOfMonths <> 0 Then
		UsefulLifeExplanation =
			UsefulLifeExplanation
			+ ?(NumberOfYears_ <> 0, " ", "")
			+ StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 tháng;;%1 tháng;%1 tháng;%1 tháng';
																				|ru = ';%1 месяц;;%1 месяца;%1 месяцев;%1 месяца';
																				|en = ';%1 month;;%1 month;%1 months;%1 months'; fa = ';%1 month;;%1 month;%1 months;%1 months';
																				|it = ';%1 mese;;%1 mesi;%1 mesi;%1 mesi';
																				|pl = ';%1 miesiąc;;%1 miesiąca;%1 miesięcy;%1 miesiąca';
																				|tr = ';%1 ay;;%1 ay;%1 ay;%1 ay'"), CountOfMonths);
	EndIf;
	
	If EncloseInBrackets Then
		UsefulLifeExplanation = "(" + UsefulLifeExplanation + ")";
	EndIf;
		
	Return UsefulLifeExplanation;
	
EndFunction

// Forms a representation of the term as a string "X years X months X days".
// 
// Parameters:
// 	NumberOfYears - Number -
// 	NumberOfMonths - Number -
// 	DaysCount - Number -
// Returns:
// 	String - 
Function StringTermPresentation(Val NumberOfYears, Val NumberOfMonths, Val DaysCount) Export

	If NumberOfYears + NumberOfMonths + DaysCount = 0 Then
		Return "";
	EndIf;
	
	UsefulLifeExplanation =
		?(NumberOfYears <> 0, StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 năm;;%1 năm;%1 năm;%1 năm';
																								|ru = ';%1 год;;%1 года;%1 лет;%1 года';
																								|en = ';%1 year;;%1 years;%1 years;%1 years'; fa = ';%1 year;;%1 years;%1 years;%1 years';
																								|it = ';%1 anno;;%1 anni;%1 anni;%1 anni';
																								|pl = ';%1 rok;;%1 lata;%1 lat;%1 lata';
																								|tr = ';%1 yıl;;%1 yıl;%1 yıl;%1 yıl'"), NumberOfYears), "")
		+ ?(NumberOfYears <> 0 And NumberOfMonths <> 0, " ", "")
		+ ?(NumberOfMonths <> 0, StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 tháng;;%1 tháng;%1 tháng;%1 tháng';
																								|ru = ';%1 месяц;;%1 месяца;%1 месяцев;%1 месяца';
																								|en = ';%1 month;;%1 month;%1 months;%1 months'; fa = ';%1 month;;%1 month;%1 months;%1 months';
																								|it = ';%1 mese;;%1 mesi;%1 mesi;%1 mesi';
																								|pl = ';%1 miesiąc;;%1 miesiąca;%1 miesięcy;%1 miesiąca';
																								|tr = ';%1 ay;;%1 ay;%1 ay;%1 ay'"), NumberOfMonths), "")
		+ ?(NumberOfYears + NumberOfMonths <> 0 And DaysCount <> 0, " ", "")
		+ ?(DaysCount <> 0, StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 ngày;;%1 ngày;%1 ngày;%1 ngày';
																							|ru = ';%1 день;;%1 дня;%1 дней;%1 дня';
																							|en = ';%1 day;;%1 day;%1 days;%1 day'; fa = ';%1 day;;%1 day;%1 days;%1 day';
																							|it = ';%1 giorno;;%1 giorno;%1 giorni;%1 giorno';
																							|pl = ';%1 dzień;;%1 dnia;%1 dni;%1 dnia';
																							|tr = ';%1 gün;;%1 gün;%1 gün;%1 gün'"), DaysCount), "");
	
	Return UsefulLifeExplanation;

EndFunction

// Forms a representation of the term as a string "from 01.01.2020 to 31.12.2020 (X years X months X days)".
// 
// Parameters:
// 	NumberOfYears - Number -
// 	NumberOfMonths - Number -
// 	DaysCount - Number -
// 	StartDate - Date -
// 	ReadOnly - Boolean - 
// Returns:
// 	FormattedString - 
Function PresentationWithFormattedString(Val NumberOfYears, Val NumberOfMonths, Val DaysCount, Val StartDate, Val ReadOnly) Export
	
	TermHeaderLines = New Array;
	
	If NumberOfYears + NumberOfMonths + DaysCount = 0
		And Not ValueIsFilled(StartDate) Then
		
		TermHeaderLines.Add(NStr("vi = '<chưa chỉ ra>';
								|ru = '<не указан>';
								|en = '<not specified>'; fa = '<مشخص نشده>';
								|it = '<non specificato>';
								|pl = '<nie określono>';
								|tr = '<belirtilmedi>'"));
	
	ElsIf NumberOfYears + NumberOfMonths + DaysCount > 0 Then
		
		EndDate = EndDateByDeadline(StartDate, NumberOfYears, NumberOfMonths, DaysCount);
					 
		TitleText = StrTemplate(NStr("vi = 'từ %1 đến %2';
									|ru = 'с %1 по %2';
									|en = 'from %1 to %2'; fa = 'from %1 to %2';
									|it = 'da %1 fino a %2';
									|pl = 'od %1 do %2';
									|tr = '%1 itibaren %2 kadar'"), Format(StartDate, "DLF=D;"), Format(EndDate, "DLF=D;"));
		TermHeaderLines.Add(TitleText);
				
		TitleText = StringTermPresentation(
							NumberOfYears,
							NumberOfMonths,
							DaysCount);
							
		TermHeaderLines.Add(" (");
		TermHeaderLines.Add(TitleText);
		TermHeaderLines.Add(")");
			
	Else
		
		TitleText = StrTemplate(NStr("vi = 'từ %1';
									|ru = 'с %1';
									|en = 'from %1'; fa = 'from %1';
									|it = 'da %1';
									|pl = 'od %1';
									|tr = '%1 itibarıyla'"), Format(StartDate, "DLF=D;"));
		TermHeaderLines.Add(TitleText);
		
	EndIf;
	
	HyperlinkAnchorText = ?(Not ReadOnly, "#Edit", "");
	
	Return  New FormattedString(TermHeaderLines,,,, HyperlinkAnchorText);
	
EndFunction

// Calculates the end date by date.
// 
// Parameters:
// 	StartDate - Date - 
// 	TermYears - Number - 
// 	TermMonths - Number - 
// 	TermDays - Number - 
// 	CheckDeadline - Boolean -
// 	
// Returns:
// 	Date - Expiry date.
Function EndDateByDeadline(StartDate, TermYears, TermMonths, TermDays, CheckDeadline = False) Export
	
	If Not ValueIsFilled(StartDate)
		Or CheckDeadline And TermYears = 0 And TermMonths = 0 And TermDays = 0 Then
		Return '000101010000';
	EndIf;
	
	EndDate = BegOfDay(StartDate);
	
	If TermYears <> 0 Then
		EndDate = AddMonth(StartDate, TermYears * 12);
		If StartDate = EndOfMonth(StartDate) Then
			EndDate = EndOfMonth(EndDate);
		EndIf;
	EndIf;
	
	If TermMonths <> 0 Then
		EndDate = AddMonth(EndDate, TermMonths);
		If StartDate = EndOfMonth(StartDate) Then
			EndDate = EndOfMonth(EndDate);
		EndIf;
	EndIf;
	
	If TermDays <> 0 Then
		EndDate = EndDate + 86400 * TermDays;
	EndIf;
	
	EndDate = Max(EndDate - 86400, StartDate);
	
	Return EndDate;
	
EndFunction

// Calculates the term by period.
// It is considered that between 01.01.2021 and 02.01.2021 the period is equal to two days.
// 
// Parameters:
// 	StartDate - Date - 
// 	EndDate - Date - 
// 	TermYears - Number - 
// 	TermMonths - Number - 
// 	TermDays - Number -
// 
Procedure CalculateTermByPeriod(StartDate, EndDate, TermYears, TermMonths, TermDays) Export
	
	If Not ValueIsFilled(StartDate) 
		Or Not ValueIsFilled(EndDate)
		Or StartDate > EndDate Then
		Return;
	EndIf;
	
	TermYears = 0;
	StartOfNextDate = AddMonth(StartDate, 12) - 86400;
	While StartOfNextDate <= EndDate Do
		TermYears = TermYears + 1;
		StartOfNextDate = AddMonth(StartOfNextDate, 12);
	EndDo;
	
	TermMonths = 0;
	StartOfNextDate = AddMonth(StartDate, 12 * TermYears + 1) - 86400;
	ItSEndOfMonth = (EndOfDay(StartOfNextDate) = EndOfMonth(StartOfNextDate));
	While StartOfNextDate <= EndDate Do
		TermMonths = TermMonths + 1;
		StartOfNextDate = AddMonth(StartOfNextDate, 1);
		If ItSEndOfMonth Then
			StartOfNextDate = BegOfDay(EndOfMonth(StartOfNextDate));
		EndIf;
	EndDo;
	
	TermDays = 0;
	StartOfNextDate = AddMonth(StartDate, 12 * TermYears + TermMonths);
	While StartOfNextDate <= EndDate Do
		TermDays = TermDays + 1;
		StartOfNextDate = StartOfNextDate + 86400;
	EndDo;
	
EndProcedure

// Formats the string according to the specified template.
// Possible tag values in the template:
// - <b> Line </b> - highlights the line in bold.
// - <a href = "Link"> Line </a> - adds a hyperlink.
// For example, "The minimum version of the program is <b>1.1</b>. <a href = "Update">Update </a> program.".
//
// Parameters:
//  StringWithTags - String - a string containing formatting tags.
//
// Returns:
//  FormattedString - converted string.
//
Function FormattedString(Val StringWithTags) Export
	
	RowsSet = New Array;
	
	CurrentFont  = Undefined;
	CurrentColor   = Undefined;
	CurrentBackground    = Undefined;
	CurrentRef = Undefined;
	
	ParticlesStrings = StrSplit(StringWithTags, "<", True);
	For Each Particle In ParticlesStrings Do
		
		StringBody = "";
		PositionTag = StrFind(Particle, ">");
		
		If PositionTag = 0 Then
			StringBody = Particle;
			
		ElsIf StrStartsWith(Particle, "/") Then
			StringBody = Mid(Particle, PositionTag + 1);
			
			CurrentFont  = Undefined;
			CurrentColor   = Undefined;
			CurrentBackground    = Undefined;
			CurrentRef = Undefined;
			
		Else
			
			TagDetails = Left(Particle, PositionTag - 1);
			FirstSpase = StrFind(TagDetails, " ");
			
			If FirstSpase > 0 Then
				NameTag = TrimAll(Left(TagDetails, FirstSpase));
				
				AttributesDetails = Mid(TagDetails, FirstSpase + 1);
				AttributesDetails = StrReplace(AttributesDetails , """", "'");
				
				PositionEqual = StrFind(AttributesDetails, "=");
				While PositionEqual > 0 Do
					
					AttributeName = TrimAll(Left(AttributesDetails, PositionEqual - 1));
					PositionFirstQuote = StrFind(AttributesDetails, "'",, PositionEqual + 1);
					If PositionFirstQuote = 0 Then
						PositionFirstQuote = PositionEqual;
					EndIf;
					PositionSecondQuote = StrFind(AttributesDetails, "'",, PositionFirstQuote + 1);
					If PositionSecondQuote = 0 Then
						PositionSecondQuote = StrLen(AttributesDetails) + 1;
					EndIf;
					AttributeValue  = TrimAll(Mid(AttributesDetails, PositionFirstQuote + 1,  PositionSecondQuote - PositionFirstQuote - 1));
					
					If StrCompare(AttributeName, "href") = 0 And StrCompare(NameTag, "a") = 0 Then
						CurrentRef = AttributeValue;
					ElsIf StrCompare(AttributeName, "src") = 0 And StrCompare(NameTag, "img") = 0 Then
						RowsSet.Add(New FormattedString(PictureLib[AttributeValue], CurrentFont, CurrentColor, CurrentBackground, CurrentRef));
					EndIf;
					
					AttributesDetails = Mid(AttributesDetails, PositionSecondQuote + 1);
					PositionEqual = StrFind(AttributesDetails, "=");
					
				EndDo;
			Else
				NameTag = TagDetails;
			EndIf;
			
			If NameTag = "b" Then
				CurrentFont = New Font(,, True,,,,);
			EndIf;
			
			StringBody = Mid(Particle, PositionTag + 1);
			
		EndIf;
		
		StringBody = StrReplace(StringBody, "&lt;", "<");
		If StrLen(StringBody) > 0 Then
			RowsSet.Add(New FormattedString(StringBody, CurrentFont, CurrentColor, CurrentBackground, CurrentRef));
		EndIf;
		
	EndDo;
	
	Return New FormattedString(RowsSet);
	
EndFunction

// Determines the available options for allocating expenses based on the accounting procedure.
// If all options are available, an empty array is returned.
// 
// Parameters:
//  AccountingProcedure - EnumRef.FARepaymentProcedure,
//  			Link enumeration.The order of accounting for the value of non-current assets	 is the accounting procedure.
// 
// Returns:
//  Array of EnumRef.CostAllocationOptions - Available Cost Sharing Options
Function AvailableCostSharingOptions(AccountingProcedure) Export
	
	ProcedureForDebiting = New Array;
	ProcedureForDebiting.Add(PredefinedValue("Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses"));
	ProcedureForDebiting.Add(PredefinedValue("Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition"));
	ProcedureForDebiting.Add(PredefinedValue("Enum.FARepaymentProcedure.IncludingInExpensesOnRecognition"));
	ProcedureForDebiting.Add(PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition"));
	ProcedureForDebiting.Add(PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition"));
	ProcedureForDebiting.Add(PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses"));
	
	
	CostAllocationOptions = New Array;
	
	If ProcedureForDebiting.Find(AccountingProcedure) <> Undefined Then
		
		CommonClientServer.SupplementArray(
			CostAllocationOptions,
			AvailableOptionsForAllocatingExpensesWhenDebiting());
		
	EndIf; 
	
	Return CostAllocationOptions;
	
EndFunction

// Available options for allocating expenses when debiting.
// 
// Returns:
//  Array of EnumRef.CostAllocationOptions -  Available Options For Allocating Expenses When Debiting
Function AvailableOptionsForAllocatingExpensesWhenDebiting() Export
	
	CostAllocationOptions = New Array;
	
	CostAllocationOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToLinesOfBusiness"));
	CostAllocationOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly"));
	CostAllocationOptions.Add(PredefinedValue("Enum.CostAllocationOptions.DoNotAllocate"));
	CostAllocationOptions.Add(PredefinedValue("Enum.CostAllocationOptions.ToNonCurrentAssetCost"));
	
	Return CostAllocationOptions;
	
EndFunction

// Fills in the Attributes according to the method of reflecting expenses.
// 
// Parameters:
//  ExpensesPostingMethod - CatalogRef.WaysToReflectExpenses - The way expenses are reflected
// 	ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - AssetRef
// 	DimensionOfExpenses - AnyRef - Dimension
// 	Department - CatalogRef.BusinessStructure - Department
// 	LineOfBusiness - CatalogRef.LinesOfBusiness -Direction of activity
// 	BusinessUnitAndLineOfBusinessMatchAccountingData - Boolean
// 
Procedure FillInAccordingToMethodOfReflectingExpenses(ExpensesPostingMethod, ExpenseItem, DimensionOfExpenses, Department, LineOfBusiness, BusinessUnitAndLineOfBusinessMatchAccountingData) Export

	If Not ValueIsFilled(ExpensesPostingMethod) Then
		Return;
	EndIf;
	
	ParametersOfExpenseReflectionMethod = NonCurrentAssetsServerCall.ParametersOfExpenseReflectionMethod(ExpensesPostingMethod);
	
	ExpenseItem = ParametersOfExpenseReflectionMethod.ExpenseItem;
	DimensionOfExpenses = ParametersOfExpenseReflectionMethod.DimensionOfExpenses;
	Department = ParametersOfExpenseReflectionMethod.Department;
	LineOfBusiness = ParametersOfExpenseReflectionMethod.LineOfBusiness;
	BusinessUnitAndLineOfBusinessMatchAccountingData = ParametersOfExpenseReflectionMethod.BusinessUnitAndLineOfBusinessMatchAccountingData;
	
EndProcedure

// Adjusts form elements according to the way expenses are reflected.
// 
// Parameters:
//  ExpensesPostingMethod - CatalogRef.WaysToReflectExpenses - The way expenses are reflected
// 	Form - ClientApplicationForm - Form
// 	FieldsNames - Array of String - Field names
// 
Procedure CustomizeItemsAccordingToWayExpensesAreReflected(ExpensesPostingMethod, Form, Val FieldsNames) Export

	If ValueIsFilled(ExpensesPostingMethod) Then
		WarningText = NStr("vi = 'Khi thay đổi sẽ xóa phương pháp phản ánh chi phí';
							|ru = 'При изменении будет очищен способ отражения расходов';
							|en = 'If you change it, the expense record method will be cleared'; fa = 'If you change it, the expense record method will be cleared';
							|it = 'При изменении будет очищен способ отражения расходов';
							|pl = 'If you change it, the expense record method will be cleared';
							|tr = 'Değişiklik yapılırken giderlerin yansıtılma yöntemi netleşecek'");
		DisplayingWarning = WarningOnEditRepresentation.Show;
	Else
		WarningText = "";
		DisplayingWarning = WarningOnEditRepresentation.DontShow;
	EndIf;

	FieldsNames = StrReplace(FieldsNames, " ", "");
	FieldsNames = StrReplace(FieldsNames, Chars.LF, "");
	FieldList = StrSplit(FieldsNames, ",");
	For Each FieldName In FieldList Do
		FormField = Form.Items[FieldName];
		FormField.WarningOnEdit = WarningText;
		FormField.WarningOnEditRepresentation = DisplayingWarning;
	EndDo;
	
EndProcedure

#EndRegion

#Region Internal

// Fills in the element header or hides the element if the header is empty.
// 
// Parameters:
// 	FormItem - FormDecoration - form element.
// 	ItemTitle - Array, Undefined - Array of strings for forming the element header.
Procedure FillInItemDetails_(FormItem, ItemTitle) Export

	If ItemTitle <> Undefined And ItemTitle.Count() <> 0 Then
		FormItem.Title = New FormattedString(ItemTitle);
		FormItem.Visible = True;
	Else
		FormItem.Visible = False;
	EndIf; 

EndProcedure

// Adds a table of the selected fixed asset / intangible asset.
//
// Parameters:
//  TabularSection		 - FormDataCollection	 - Table part of fixed assets.
//  AttributeName		 - String				 - Name of the table part details.
//  ValueSelected	 - Array				 - Selected fixed assets (parameter of the selection Processing event).
// 
// Returns:
//  Array - List of added rows.
//
Function ProcessingElementSelection(TabularSection, AttributeName, ValueSelected) Export

	If ValueSelected.Count() = 0 Then
		Return New Array;
	EndIf;
	
	AddedRows = New Array;
	For Each ArrayElement In ValueSelected Do
		TheStructureOfTheSearch = New Structure(AttributeName, ArrayElement);
		StringsList = TabularSection.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			NewRow = TabularSection.Add();
			NewRow[AttributeName] = ArrayElement;
			AddedRows.Add(NewRow);
		EndIf;
	EndDo;
	
	Return AddedRows;

EndFunction

Function ObjectPropsPropertyValue(AttributeName, Property, ItemDetailsParameters) Export

	For Each AttributeParameters In ItemDetailsParameters Do
		If AttributeParameters.AttributeName = AttributeName And AttributeParameters.Property = Property Then
			Return AttributeParameters.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Adds or removes a value from the list.
// 
// Parameters:
// 	ChoiceList - ValueList of Arbitrary - The "List Selection" property of the form element.
// 	Visible - Boolean - True if the value should be visible.
// 	Value - Arbitrary - The value of the list to show or hide.
// 	Presentation - String - representation of the value.
// 	Position - Number, Undefined - Position in the selection list.
Procedure SetVisibilityOfSelectionListValue(ChoiceList, Visible, Value, Presentation= "", Position = Undefined) Export

	ListItem = ChoiceList.FindByValue(Value);
	
	If Visible Then
		
		If ListItem = Undefined Then
			If Position <> Undefined Then
				ChoiceList.Insert(Position, Value, Presentation);
			Else
				ChoiceList.Add(Value, Presentation);
			EndIf;
		Else
			ListItem.Presentation = Presentation;
		EndIf;
		 
	ElsIf ListItem <> Undefined Then
		
		ChoiceList.Delete(ListItem);
		
	EndIf; 

EndProcedure

Procedure SetValuePresentationOfSelectionList(ChoiceList, ElementValue, ItemPresentation) Export
	
	ListItem = ChoiceList.FindByValue(ElementValue);
	If ListItem <> Undefined Then
		ListItem.Presentation = ItemPresentation;
	EndIf;
	
EndProcedure

// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
//  AuxiliaryAttributes - Structure - 
// 
// Returns:
//  Structure - 
//
Function FAAcceptanceParameters(Object, AuxiliaryAttributes) Export

	FAAcceptanceParameters = ParametersForAcceptingBalanceEntryAxisForAccounting(Object, AuxiliaryAttributes);	

	//
	ActualCost =
		Object.DimensionKindExpenseCapitalization =  PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject")
		And Object.PartialCommissioning 
		Or Object.PostInAccounting
			And Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued")
		Or Object.RecordInManAccounting
			And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
		Or Not AuxiliaryAttributes.ThereIsCostAccounting
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount");

	//
	ACCostIsAvailable = 
		Object.PostInAccounting
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.CostIsNotRedeemable")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.EmptyRef"));
	
	//
	CostOfMaIsAvailable = 
		Object.RecordInManAccounting
		And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			Or Not AuxiliaryAttributes.CurrenciesDoNotMatch)
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
			
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems"),
			AuxiliaryAttributes.AccountPolicySettings.LeasedFixedAssetDepreciationChargeProcedureLocal = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting"),
			AuxiliaryAttributes.AccountPolicySettings.ProcedureOfFixedAssetDepreciationChargeLocal = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting"));
		
	CostIsRequiredToCalculateDepreciationOfAC = 
		Object.PostInAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost;
	
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems"),
			AuxiliaryAttributes.AccountPolicySettings.LeasedAssetDepreciationChargeProcedureManag = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting"),
			AuxiliaryAttributes.AccountPolicySettings.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting"));
		
	CostIsRequiredToCalculateDepreciationOfMA = 
		Object.RecordInManAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost;
	
	//
	FAAcceptanceParameters.Insert("ActualCost", ActualCost);
	FAAcceptanceParameters.Insert("CostOfMaIsAvailable", CostOfMaIsAvailable);
	FAAcceptanceParameters.Insert("ACCostIsAvailable", ACCostIsAvailable);
	FAAcceptanceParameters.Insert("CostIsRequiredToCalculateDepreciationOfAC", CostIsRequiredToCalculateDepreciationOfAC);
	FAAcceptanceParameters.Insert("CostIsRequiredToCalculateDepreciationOfMA", CostIsRequiredToCalculateDepreciationOfMA);
	FAAcceptanceParameters.Insert("CostIsRequiredToCalculateTax", False);
	
	FixedAssetsInitialRecognitionClientServerLocalization.AddFAAcceptanceParameters(
		Object, AuxiliaryAttributes, FAAcceptanceParameters);
	
	Return FAAcceptanceParameters;
	
EndFunction

Function ParametersForTakingIntoAccountComponentsOfDepreciationComponents(Object, AuxiliaryAttributes) Export
	
	ACDepreciationParametersAreAvailable = 
		(Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.EmptyRef"))
		And AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
	AvailableMaDepreciationParameters = 
		(Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"))
			And AuxiliaryAttributes.RecordInManAccounting;
	
	AvailableReflectionOfMaExpenses = 
		AuxiliaryAttributes.RecordInManAccounting
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition"));
			
	AvailableReflectionOfBUExpenses = 
		AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.EmptyRef"));
			
	ACDepreciationIsAvailable = 
		Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
		And AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
	MaDepreciationIsAvailable = 
		(Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition"))
			And AuxiliaryAttributes.RecordInManAccounting;
	
	ByAssetActivity = 
		Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
		Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction");
		
	AccountingAcceptanceParameters = New Structure;
	AccountingAcceptanceParameters.Insert("ACDepreciationParametersAreAvailable", ACDepreciationParametersAreAvailable);
	AccountingAcceptanceParameters.Insert("AvailableMaDepreciationParameters", AvailableMaDepreciationParameters);
	AccountingAcceptanceParameters.Insert("AvailableReflectionOfMaExpenses", AvailableReflectionOfMaExpenses);
	AccountingAcceptanceParameters.Insert("AvailableReflectionOfBUExpenses", AvailableReflectionOfBUExpenses);
	AccountingAcceptanceParameters.Insert("MaDepreciationIsAvailable", MaDepreciationIsAvailable);
	AccountingAcceptanceParameters.Insert("ACDepreciationIsAvailable", ACDepreciationIsAvailable);
	AccountingAcceptanceParameters.Insert("ByAssetActivity", ByAssetActivity);
	
	ACCostIsAvailable = Object.RecordInLocalAccounting;

	CostOfMaIsAvailable = 
		Object.RecordInManAccounting 
		And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
			Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
	AccountingAcceptanceParameters.Insert("CostOfMaIsAvailable", CostOfMaIsAvailable);
	AccountingAcceptanceParameters.Insert("ACCostIsAvailable", ACCostIsAvailable);
	
	Return AccountingAcceptanceParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsInitialRecognition2_4 - 
//  AuxiliaryAttributes - Structure - 
// 
// Returns:
//  Structure - 
// 
Function IAAcceptanceParameters(Object, AuxiliaryAttributes) Export

	AccountingAcceptanceParameters = ParametersOfAcceptanceForAccountingOfNMAIInputOfBalances(Object, AuxiliaryAttributes);	

	//
	ActualCost =
		Object.PostInAccounting
			And Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
		Or Object.RecordInManAccounting
			And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
		Or Not AuxiliaryAttributes.ThereIsCostAccounting
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount");
		
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfIntangibleAssetAmortizationChargeLocal = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfAC = 
		Object.PostInAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost;
	
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfIntangibleAssetAmortizationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfMA = 
		Object.RecordInManAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost;
					
	AccountingAcceptanceParameters.Insert("ByInventory", False);
	AccountingAcceptanceParameters.Insert("ActualCost", ActualCost);
	AccountingAcceptanceParameters.Insert("CostIsRequiredToCalculateDepreciationOfAC", CostIsRequiredToCalculateDepreciationOfAC);
	AccountingAcceptanceParameters.Insert("CostIsRequiredToCalculateDepreciationOfMA", CostIsRequiredToCalculateDepreciationOfMA);
	
	IntangibleAssetsInitialRecognitionClientServerLocalization.SupplementAcceptanceParametersForAccountingIA(Object, AuxiliaryAttributes, AccountingAcceptanceParameters);
	
	Return AccountingAcceptanceParameters;

EndFunction

Function ParametersForEnteringFABalances(Object, AuxiliaryAttributes) Export

	ParametersForEnteringBalances = ParametersForAcceptingBalanceEntryAxisForAccounting(Object, AuxiliaryAttributes);
	
	ParametersForEnteringBalances.Insert("AccountingParametersAvailable", AuxiliaryAttributes.RecordInOperationalAccounting);
	ParametersForEnteringBalances.Insert("DepreciationAccrualIsValid", False);
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.AddParametersForEnteringFABalances(
		Object, AuxiliaryAttributes, ParametersForEnteringBalances);

	Return ParametersForEnteringBalances;

EndFunction

Function ParametersForEnteringIAResidues(Object, AuxiliaryAttributes) Export
	
	ParametersForEnteringBalances = ParametersOfAcceptanceForAccountingOfNMAIInputOfBalances(Object, AuxiliaryAttributes);
	
	ParametersForEnteringBalances.Insert("AccountingParametersAvailable", AuxiliaryAttributes.RecordInOperationalAccounting);

	EntryOfCapitalAssetsBalanceClientServerLocalization.SupplementParametersForEnteringIAResidues(
		Object, AuxiliaryAttributes, ParametersForEnteringBalances);
	
	Return ParametersForEnteringBalances;

EndFunction

Function FAPoolingOptions(Object, AuxiliaryAttributes) Export

	FAPoolingOptions = ParametersForAcceptingBalanceEntryAxisForAccounting(Object, AuxiliaryAttributes);	
	
	Return FAPoolingOptions;
	
EndFunction

Function FAUpgradeOptions(Object, AuxiliaryAttributes) Export
	
	DocumentParameters = New Structure();
	
	ActualCost =
		Object.DimensionKindExpenseCapitalization =  PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject")
		And Object.FixedAssetCostAdditionsPartial;
		
	// 
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfFixedAssetDepreciationChargeLocal = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfAC = 
		Object.PostInAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost
		And Not Object.WriteOffAppreciationCosts;
	
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfMA = 
		Object.RecordInManAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost
		And Not Object.WriteOffAppreciationCosts;
	
	//
	CostIsRequiredToCalculateTax = False;
	
		
	DocumentParameters.Insert("ActualCost", ActualCost);
	DocumentParameters.Insert("CostIsRequiredToCalculateDepreciationOfAC", CostIsRequiredToCalculateDepreciationOfAC);
	DocumentParameters.Insert("CostIsRequiredToCalculateDepreciationOfMA", CostIsRequiredToCalculateDepreciationOfMA);
	DocumentParameters.Insert("CostIsRequiredToCalculateTax", CostIsRequiredToCalculateTax);
	
	Return DocumentParameters;
	
EndFunction

Function ParametersForAttributingDeviationsToCostOfFA(Object, AuxiliaryAttributes) Export
	
	DocumentParameters = New Structure();
	
	ActualCost = False;
		
	// 
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfFixedAssetDepreciationChargeLocal = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfAC = 
		Object.PostInAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost
		And Not Object.WriteOffVariancesAsExpenses;
	
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfMA = 
		Object.RecordInManAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting
		And Not ActualCost
		And Not Object.WriteOffVariancesAsExpenses;
	
	//
	CostIsRequiredToCalculateTax = False;
	
		
	DocumentParameters.Insert("ActualCost", ActualCost);
	DocumentParameters.Insert("CostIsRequiredToCalculateDepreciationOfAC", CostIsRequiredToCalculateDepreciationOfAC);
	DocumentParameters.Insert("CostIsRequiredToCalculateDepreciationOfMA", CostIsRequiredToCalculateDepreciationOfMA);
	DocumentParameters.Insert("CostIsRequiredToCalculateTax", CostIsRequiredToCalculateTax);
	
	Return DocumentParameters;
	
EndFunction

Function IAImprovementParameters(Object, AuxiliaryAttributes) Export
	
	DocumentParameters = New Structure();
	
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfIntangibleAssetAmortizationChargeLocal = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfAC = 
		Object.RecordInLocalAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting;
	
	//
	DepreciationIsAccruedFromDateOfAcceptanceForAccounting = 
		AuxiliaryAttributes.AccountPolicySettings.ProcedureOfIntangibleAssetAmortizationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
	CostIsRequiredToCalculateDepreciationOfMA = 
		Object.RecordInManAccounting
		And DepreciationIsAccruedFromDateOfAcceptanceForAccounting;
	
	DocumentParameters.Insert("CostIsRequiredToCalculateDepreciationOfAC", CostIsRequiredToCalculateDepreciationOfAC);
	DocumentParameters.Insert("CostIsRequiredToCalculateDepreciationOfMA", CostIsRequiredToCalculateDepreciationOfMA);
	
	Return DocumentParameters;
	
EndFunction

Function FillInDetailsDependingOnProperties__FA_(Object, ItemDetailsParameters) Export

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.AttributeName)
			Or StrSplit(AttributeParameters.AttributeName, ".").UBound() <> 0 Then
			Continue;
		EndIf;
		
		Action = ClearOrFill(Object, AttributeParameters);
		
		If Not ValueIsFilled(Action) Then
			Continue;
		EndIf;
		
		#Region TheAccountingPage
		
		If AttributeParameters.AttributeName = "DepreciationAccrualManagementAccounting" Then
			Object[AttributeParameters.AttributeName] = ?(Action = "Fill", True, False);
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "AccountingProcedureMA"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		#EndRegion
		
		#Region PageExpenseRecord
		
		If AttributeParameters.AttributeName = "ExpenseItemManagementAccounting" Then
			If Action = "Clear" Then
				Object.ExpenseItemManagementAccounting = Undefined;
				Object.ExpensesDimensionManagementAccounting = Undefined;
				ChangedBankingDetails.Add("ExpenseItemManagementAccounting");
				ChangedBankingDetails.Add("ExpensesDimensionManagementAccounting");
			EndIf;
		EndIf;
		
		#EndRegion
		
		NonCurrentAssetsClientServerLocalization.FillInDetailsDependingOnProperties__FA_(
			Object, AttributeParameters, Action, ChangedBankingDetails);
		
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

// Sets the visibility of the element.
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	TagName - String -
// 	BankingDetailsNamesDataFlag - Structure -
// 	TSName - String -
// 	StructureOfChangedProps- Structure - 
Procedure SetVisibilityOfCurParameterValueWhenParametersChange(Form, TagName, BankingDetailsNamesDataFlag, TSName, StructureOfChangedProps) Export

	If StructureOfChangedProps.Count() = 0 
		Or StructureOfChangedProps.Property("ShowTheCurrentValues") 
		Or StructureOfChangedProps.Property(BankingDetailsNamesDataFlag.AttributeNameFlag) Then
			
		FormItem = Form.Items[?(TagName = Undefined, TSName + BankingDetailsNamesDataFlag.AttributeName, TagName)];
		FormItem.Visible = Form.Object[BankingDetailsNamesDataFlag.AttributeNameFlag] And Form.ShowTheCurrentValues;
			
	EndIf;

EndProcedure

Function BankingDetailsNamesDataFlag(AttributeName, AttributeNameFlag) Export
	
	NameAndDetailsDataFlag = New Structure;
	NameAndDetailsDataFlag.Insert("AttributeName", AttributeName);
	NameAndDetailsDataFlag.Insert("AttributeNameFlag", AttributeNameFlag);
	
	Return NameAndDetailsDataFlag; 
	
EndFunction

// Copies the structure property.
// 
// Parameters:
//  Source - Structure - Source
//  Receiver - Structure, FixedStructure - Receiver
//  PropertyName - String - property name
//  DefaultValue - Undefined - Default value (if not specified, the field will not be added if it is not in the source)
Procedure CopyStructureProperty(Source, Receiver, PropertyName, DefaultValue = Undefined) Export
	
	PathToParameter = StrSplit(PropertyName, ".");
	If PathToParameter.Count() = 3 Then
		PropertyValue = CommonClientServer.StructureProperty(Source, PathToParameter[2], DefaultValue);
	ElsIf PathToParameter.Count() = 2 Then
		PropertyValue = CommonClientServer.StructureProperty(Source, PathToParameter[1], DefaultValue);
	Else
		PropertyValue = CommonClientServer.StructureProperty(Source, PropertyName, DefaultValue);
	EndIf;
	
	If PropertyValue = Undefined
		And DefaultValue = Undefined Then
		Return;
	EndIf;
	
	SetStructureProperty(PropertyName, PropertyValue, Receiver);
	
EndProcedure

// Copies the structure property.
// 
// Parameters:
//  PropertyName - String - property name
//  PropertyValue - Arbitrary - Property value
//  Receiver - Structure, FixedStructure - Receiver
Procedure SetStructureProperty(PropertyName, PropertyValue, Receiver) Export

	PathToProperty = StrSplit(PropertyName, ".");
	
	If TypeOf(Receiver) = Type("FixedStructure")
		Or Receiver = Undefined Then
		
		NewProperties = New Structure(Receiver);

		If PathToProperty.Count() = 3 Then
			NewProperties[PathToProperty[0]][PathToProperty[1]].Insert(PathToProperty[2], PropertyValue);
		ElsIf PathToProperty.Count() = 2 Then
			NewProperties[PathToProperty[0]].Insert(PathToProperty[1], PropertyValue);
		Else
			NewProperties.Insert(PropertyName, PropertyValue);
		EndIf;
		
		Receiver = New FixedStructure(NewProperties);
		
	Else

		If PathToProperty.Count() = 3 Then
			Receiver[PathToProperty[0]][PathToProperty[1]].Insert(PathToProperty[2], PropertyValue);
		ElsIf PathToProperty.Count() = 2 Then
			Receiver[PathToProperty[0]].Insert(PathToProperty[1], PropertyValue);
		Else
			Receiver.Insert(PropertyName, PropertyValue);
		EndIf;

	EndIf;
	
EndProcedure

// Generates a list of table column values.
// 
// Parameters:
//  Table - ValueTable, FormDataCollection - Table
//  ColumnName - String - column name
// 
// Returns:
//  Array -
//
Function TableColumnValues(Table, ColumnName) Export
	
	Result = New Array();
	
	For Each Item In Table Do
		If ValueIsFilled(Item[ColumnName]) Then
			Result.Add(Item[ColumnName]);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#Region DefiningPropertiesOfDependentPropsOfObject

// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	FAAcceptanceParameters = FAAcceptanceParameters(Object, AuxiliaryAttributes);
	
	FixedAssetsInitialRecognitionClientServerLocalization.AddPropertyValuesForDependentProps(
		Object, AuxiliaryAttributes, FAAcceptanceParameters, StructureOfChangedProps, ItemDetailsParameters);
	
	DocumentDate = Object.Date;
	
	#Region IsMain
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognition")
			And AuxiliaryAttributes.UseConstructionObjects;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionKindExpenseCapitalization", 
			"TypeOfExpenseAnalysisFixedAssets", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionKindExpenseCapitalization", 
			"TypeOfCostAnalysisConstructionObjects", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ConstructionObject", 
			"ConstructionObject", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PartialCommissioning", 
			"PartialCommissioning", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems");
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Contract", 
			"Contract", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
		//
		PropertyValue = 
			(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DocumentBasis", 
			"DocumentBasis", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"GeneratedDocument", 
			"GeneratedDocument", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognition")
			Or Object.DimensionKindExpenseCapitalization <> PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PartialCommissioning", 
			"PartialCommissioning", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.DimensionKindExpenseCapitalization <> PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ConstructionObject", 
			"ConstructionObject", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("TargetFinancingApplicationOption")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"AutoMarkIncomplete", 
			FAAcceptanceParameters.LineOfBusinessIsMandatory, 
			ItemDetailsParameters);
		
	EndIf; 
	
	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or UpdateAll Then
		
		PropertyValue = Object.AdjustmentModeFromPreviousDate;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAdjustmentOption", 
			"DepreciationAdjustmentOption", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = Not Object.AdjustmentModeFromPreviousDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognition", 
			"DateOfRecognition", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	#Region FA
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = FAAcceptanceParameters.ACCostIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ResidualValueLocal", 
			"FAResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = FAAcceptanceParameters.CostOfMaIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ResidualValueMan", 
			"FAResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
				
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.RunningTimeValue", 
			"FARunningTimeValue", 
			"Visible", 
			FAAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FARunningTimeValueUnitOfMeasure", 
			"Visible", 
			FAAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.EstimatedRunningTime", 
			"FAEstimatedRunningTime", 
			"Visible", 
			FAAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("OSGroup")
		Or StructureOfChangedProps.Property("DepreciationGroup")
		Or StructureOfChangedProps.Property("RealEstate")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("AccrueAdditionalDepreciationForPreviousPeriod")
		Or StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or StructureOfChangedProps.Property("PartialCommissioning")
		Or UpdateAll Then

		PropertyValue = 
			FAAcceptanceParameters.ACCostIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInAccounting", 
			"FACostInAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			FAAcceptanceParameters.ACCostIsAvailable
			And (FAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or FAAcceptanceParameters.ActualCost
				Or Object.AdjustmentModeFromPreviousDate
				Or FAAcceptanceParameters.CostIsRequiredToCalculateTax
					And (AuxiliaryAttributes.PropertyTaxAdvancesArePaid
							And EndOfMonth(DocumentDate) = EndOfQuarter(DocumentDate)
						Or EndOfMonth(DocumentDate) = EndOfYear(DocumentDate)));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInAccounting", 
			"FACostInAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			FAAcceptanceParameters.CostOfMaIsAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInManagementAccounting", 
			"FACostInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			FAAcceptanceParameters.CostOfMaIsAvailable
			And (FAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfMA
				Or FAAcceptanceParameters.ActualCost
				Or Object.AdjustmentModeFromPreviousDate);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInManagementAccounting", 
			"FACostInManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region AccountingParameters
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			FAAcceptanceParameters.ACDepreciationParametersAreAvailable, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ACUsefulLifeExplanation", 
			"Visible", 
			FAAcceptanceParameters.ACDepreciationParametersAreAvailable, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting", 
			"Visible", 
			FAAcceptanceParameters.ACDepreciationParametersAreAvailable,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			FAAcceptanceParameters.ACDepreciationParametersAreAvailable, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.BySumOfUsefulLifeYearNumbers"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting",
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue =
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				And FAAcceptanceParameters.ACDepreciationParametersAreAvailable);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			FAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			FAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"Visible", 
			FAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			FAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue = FAAcceptanceParameters.AvailableMaDepreciationParameters
							And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
								Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = (FAAcceptanceParameters.AvailableMaDepreciationParameters
							And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
		
	#EndRegion
	
	#Region RecordExpenses
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = 
			FAAcceptanceParameters.AvailableReflectionOfBUExpenses
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			(FAAcceptanceParameters.AvailableReflectionOfMaExpenses
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = FAAcceptanceParameters.ExpenseItemManagementAccountingRequired_;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			(FAAcceptanceParameters.AvailableReflectionOfMaExpenses
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses"))
			And FAAcceptanceParameters.ExpenseItemManagementAccountingRequired_;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting")
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		PropertyName = ?( 
			Not PropertyValue
			And Not FAAcceptanceParameters.ExpenseItemManagementAccountingRequired_,
			"ReadOnly",
			"OnlyViewWithoutBlankMark");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			PropertyName, 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.ThereAreRelatedCompanies 
			And (FAAcceptanceParameters.AvailableReflectionOfBUExpenses 
				Or FAAcceptanceParameters.ExpenseReflectionIsAvailable
				Or FAAcceptanceParameters.AvailableReflectionOfMaExpenses);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"TransferExpensesToAnotherCompany",
			"TransferExpensesToAnotherCompany", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("TransferExpensesToAnotherCompany") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses",
			"CompanyRecipientOfExpenses", 
			"OnlyViewWithoutBlankMark", 
			Not Object.TransferExpensesToAnotherCompany, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
		
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.RecognizeSubAssetsComponentsOfDepreciation, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	AccountingAcceptanceParameters = ParametersForTakingIntoAccountComponentsOfDepreciationComponents(Object, AuxiliaryAttributes);
	
	If UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"AutoMarkIncomplete", 
			False, 
			ItemDetailsParameters);
		
	EndIf; 

	#Region DepreciationComponents
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingAcceptanceParameters.ACCostIsAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationComponents.CostInAccounting", 
			"DepreciationComponentsCostInAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationComponents.ResidualValueLocal", 
			"DepreciationComponentsResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingAcceptanceParameters.CostOfMaIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationComponents.CostInManagementAccounting", 
			"DepreciationComponentsCostInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationComponents.ResidualValueMan", 
			"DepreciationComponentsResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationComponents.RunningTimeValue", 
			"DepreciationComponentsRunningTimeValue", 
			"Visible", 
			AccountingAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationComponentsRunningTimeValueUnitOfMeasure", 
			"Visible", 
			AccountingAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationComponents.EstimatedRunningTime", 
			"DepreciationComponentsEstimatedRunningTime", 
			"Visible", 
			AccountingAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region AccountingParametersOfBU
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInLocalAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue = AccountingAcceptanceParameters.ACDepreciationParametersAreAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ACUsefulLifeExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue =
			(Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				And AccountingAcceptanceParameters.ACDepreciationParametersAreAvailable);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInLocalAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.BySumOfUsefulLifeYearNumbers"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting",
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region UUAccountingParameters
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = AccountingAcceptanceParameters.AvailableMaDepreciationParameters;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingAcceptanceParameters.AvailableMaDepreciationParameters
			And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingAcceptanceParameters.AvailableMaDepreciationParameters
			And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance");
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
		
	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingAcceptanceParameters.AvailableReflectionOfBUExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingAcceptanceParameters.AvailableReflectionOfMaExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(
		Object, AuxiliaryAttributes, AccountingAcceptanceParameters, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.DisposeFixedAssets2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesForDependentBankDetails_FADebiting(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("ExpenseItem")
		Or StructureOfChangedProps.Property("DimensionCorrespondsToFAToWriteOff")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.DimensionCorrespondsToFAToWriteOff;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfExpenses", 
			"DimensionOfExpenses", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("ExpenseItem")
		Or UpdateAll Then
			
		PropertyValue = 
			TypeOf(Object.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.ExpenseItems")
			And ValueIsFilled(Object.ExpenseItem);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionCorrespondsToFAToWriteOff", 
			"DimensionCorrespondsToFAToWriteOff", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;

	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ChargeAmountAccounting", 
			"FAChargeAmountAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal")
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.AmountManagementAccounting", 
			"FAAmountManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		PropertyValue = Object.FA.Count() > 1;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RecordedAsReceivedTangibleAssetsFixedAsset", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordedAsReceivedTangibleAssets.FixedAsset", 
			"RecordedAsReceivedTangibleAssetsFixedAsset", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or UpdateAll Then
			
		PropertyValue = 
			Object.PostInAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ResidualValueLocal", 
			"FAResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or UpdateAll Then
			
		PropertyValue = 
			Object.RecordInManAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal")
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ResidualValueMan", 
			"FAResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
			
		PropertyValue = Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AdjustmentModeFromPreviousDate", 
			"AdjustmentModeFromPreviousDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfDeduction", 
			"DateOfDeduction", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or UpdateAll Then
		
		PropertyValue = Not Object.AdjustmentModeFromPreviousDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfDeduction", 
			"DateOfDeduction", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesBusinessUnit", 
			"ExpensesBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseLineOfBusiness", 
			"ExpenseLineOfBusiness", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	NonCurrentAssetsClientServerLocalization.AddPropertyValuesForDependentDetails_WriteOffFA(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.ChangeFixedAssetFinancialDetails2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_ChangeFAParameters(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	#Region IsMain
	
	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or UpdateAll Then
		
		PropertyValue = Not Object.AdjustmentModeFromPreviousDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ValidOnDate", 
			"ValidOnDate", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
		
	#Region AccountingOfBU
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccountingFlag", 
			"DepreciationAccrualAccountingFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccountingFlag", 
			"DepreciationMethodAccountingFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccountingFlag", 
			"UsefulLifeAccountingFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"ACUsefulLifeExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SpecifiedRemainingUsefulLifeAC", 
			"SpecifiedRemainingUsefulLifeAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccountingFlag", 
			"AccelerationFactorAccountingFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
			
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationAccrualAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting",
			"ReadOnly", 
			Not Object.DepreciationAccrualAccountingFlag, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting",
			"OnlyViewWithoutBlankMark", 
			Not Object.DepreciationMethodAccountingFlag, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccelerationFactorAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.AccelerationFactorAccountingFlag, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("UsefulLifeAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.UsefulLifeAccountingFlag, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SpecifiedRemainingUsefulLifeAC", 
			"SpecifiedRemainingUsefulLifeAC", 
			"ReadOnly", 
			Not Object.UsefulLifeAccountingFlag, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	#Region UUAccounting
	
	If StructureOfChangedProps.Property("DepreciationAccrualManagementAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"ReadOnly", 
			Not Object.DepreciationAccrualManagementAccountingFlag, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccountingFlag",
			"DepreciationAccrualManagementAccountingFlag",
			"Visible",
			Object.RecordInManAccounting,
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.DepreciationAccrualMethodManagementAccountingFlag, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccountingFlag", 
			"DepreciationAccrualMethodManagementAccountingFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.UsefulLifeManagementAccountingFlag, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccountingFlag", 
			"UsefulLifeManagementAccountingFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SpecifiedRemainingUsefulLifeMA", 
			"SpecifiedRemainingUsefulLifeMA", 
			"ReadOnly", 
			Not Object.UsefulLifeManagementAccountingFlag, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SpecifiedRemainingUsefulLifeMA", 
			"SpecifiedRemainingUsefulLifeMA", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccelerationFactorManagementAccountingFlag")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"ReadOnly", 
			Not Object.AccelerationFactorManagementAccountingFlag, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccountingFlag", 
			"AccelerationFactorManagementAccountingFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = Object.RecordInManAccounting Or Object.PostInAccounting;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValue", 
			"RunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValueFlag", 
			"RunningTimeValueFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTimeFlag", 
			"EstimatedRunningTimeFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("FinancialAccountingGroupFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialAccountingGroup", 
			"FinancialAccountingGroup", 
			"OnlyViewWithoutBlankMark", 
			Not Object.FinancialAccountingGroupFlag, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("LineOfBusinessFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness",
			"LineOfBusiness",
			"ReadOnly", 
			Not Object.LineOfBusinessFlag,
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RunningTimeValueFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValue",
			"RunningTimeValue",
			"OnlyViewWithoutBlankMark",
			Not Object.RunningTimeValueFlag,
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("EstimatedRunningTimeFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime",
			"EstimatedRunningTime",
			"OnlyViewWithoutBlankMark",
			Not Object.EstimatedRunningTimeFlag, 
			ItemDetailsParameters);
		
	EndIf;
	
	// If you change the parameters only in tax accounting, changing the CGU does not make sense.
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		If (Object.PostInAccounting = False And Object.RecordInManAccounting = False)
			And (Object.RecordInTA And Object.RecordInLocalAccounting) Then // Changing parameters only in tax accounting.
			VisibilityOfCGU = False;
		Else 														// All other options for changing parameters.
			VisibilityOfCGU = True;
		EndIf;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"CGU",
			"CGU",
			"Visible",
			VisibilityOfCGU,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CGUFlag",
			"CGUFlag",
			"Visible",
			VisibilityOfCGU,
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region AccountingGeneral
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueMan", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueManFlag", 
			"ResidualValueManFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualValueManFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueMan", 
			"ResidualValueMan", 
			"OnlyViewWithoutBlankMark", 
			Not Object.ResidualValueManFlag, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or UpdateAll Then
		
		PropertyValue = Object.PostInAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocalFlag", 
			"ResidualValueLocalFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualValueLocalFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"OnlyViewWithoutBlankMark", 
			Not Object.ResidualValueLocalFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region Depreciation
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or UpdateAll Then
	
		PropertyValue = Not Object.DepreciationExpenseRecordingIsChanged;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Depreciation",
			"Depreciation",
			"OnlyViewWithoutBlankMark",
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesPostingMethod",
			"ExpensesPostingMethod",
			"ReadOnly",
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"DepreciationIsExpenseItemWithoutDivision",
			"OnlyViewWithoutBlankMark",
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"SwitchDepreciationWithoutSplitting",
			"ReadOnly",
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or StructureOfChangedProps.Property("SwitchDepreciationWithoutSplitting")
		Or StructureOfChangedProps.Property("DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision")
		Or UpdateAll Then

		PropertyValue = 
			Object.Depreciation.Count() = 0
			Or Object.Depreciation[0].BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationDivisionWithoutDivision", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationLineOfBusinessWithoutDivision", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or StructureOfChangedProps.Property("SwitchDepreciationWithoutSplitting")
		Or StructureOfChangedProps.Property("DepreciationTransferExpensesToAnotherCompanyWithoutSplitting")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.Depreciation.Count() = 0
			Or Not Object.Depreciation[0].TransferExpensesToAnotherCompany;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"DepreciationCompanyRecipientOfExpensesWithoutDivision",
			"OnlyViewWithoutBlankMark",
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
		
	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_ChangeFAParameters(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;

EndFunction

// 
// Parameters:
//  Object - DocumentObject.FixedAssetsCostAdditions2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps__FA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	DocumentDate = Object.Date;
	
	FAUpgradeOptions = FAUpgradeOptions(Object, AuxiliaryAttributes);

	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps__FA(
		Object, AuxiliaryAttributes, FAUpgradeOptions, StructureOfChangedProps, ItemDetailsParameters);
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or UpdateAll Then
	
		PropertyValue = 
			Not Object.WriteOffAppreciationCosts;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AdjustmentModeFromPreviousDate", 
			"AdjustmentModeFromPreviousDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RenovationDate", 
			"RenovationDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or UpdateAll Then
		
		PropertyValue = Not Object.AdjustmentModeFromPreviousDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RenovationDate", 
			"RenovationDate", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.AdjustmentModeFromPreviousDate
			And Not Object.WriteOffAppreciationCosts;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAdjustmentOption", 
			"DepreciationAdjustmentOption", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or UpdateAll Then
		
		PropertyValue = (Object.DimensionKindExpenseCapitalization <> PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ConstructionObject", 
			"ConstructionObject", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FixedAssetCostAdditionsPartial", 
			"FixedAssetCostAdditionsPartial", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.UseConstructionObjects;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionKindExpenseCapitalization", 
			"TypeOfExpenseAnalysisFixedAssets", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionKindExpenseCapitalization", 
			"TypeOfCostAnalysisConstructionObjects", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ConstructionObject", 
			"ConstructionObject", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FixedAssetCostAdditionsPartial", 
			"FixedAssetCostAdditionsPartial", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region FixedAssetsPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or StructureOfChangedProps.Property("FixedAssetCostAdditionsPartial")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FA")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInAccounting", 
			"FACostInAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue = 
			Object.PostInAccounting
			And (FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfAC
				Or FAUpgradeOptions.ActualCost
				Or Object.AdjustmentModeFromPreviousDate
				Or FAUpgradeOptions.CostIsRequiredToCalculateTax
					And (AuxiliaryAttributes.PropertyTaxAdvancesArePaid
							And EndOfMonth(DocumentDate) = EndOfQuarter(DocumentDate)
						Or EndOfMonth(DocumentDate) = EndOfYear(DocumentDate)));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInAccounting", 
			"FACostInAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue = 
			Object.RecordInManAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInManagementAccounting", 
			"FACostInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.RecordInManAccounting
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
					And FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfMA
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch
					And FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfAC
				Or FAUpgradeOptions.ActualCost
				Or Object.AdjustmentModeFromPreviousDate);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInManagementAccounting", 
			"FACostInManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
		
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or UpdateAll Then
		
		PropertyValue = Object.WriteOffAppreciationCosts;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemWriteOffCosts", 
			"ExpenseItemWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseDimensionWriteOffCosts", 
			"ExpenseDimensionWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitWriteOffCosts", 
			"BusinessUnitWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessWriteOffCosts", 
			"LineOfBusinessWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts")
		Or StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitWriteOffCosts", 
			"BusinessUnitWriteOffCosts", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessWriteOffCosts", 
			"LineOfBusinessWriteOffCosts", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region AdditionalPage
	
	If StructureOfChangedProps.Property("TargetFinancingApplicationOption")
		Or StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"Visible", 
			AuxiliaryAttributes.LineOfBusinessIsMandatory, 
			ItemDetailsParameters);
		
	EndIf; 
	
	#EndRegion
	
	Return ItemDetailsParameters;

EndFunction

// 
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_AttributionOfDeviationsToCostOfFA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	DocumentParameters = ParametersForAttributingDeviationsToCostOfFA(Object, AuxiliaryAttributes);

	NonCurrentAssetsClientServerLocalization.AddPropertyValuesForDependentProps_AttributionOfDeviationsToCostOfFA(
		Object, AuxiliaryAttributes, DocumentParameters, StructureOfChangedProps, ItemDetailsParameters);
	
	#Region PageGeneral
	
	If UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.UseConstructionObjects;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionKindExpenseCapitalization", 
			"TypeOfExpenseAnalysisFixedAssets", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionKindExpenseCapitalization", 
			"TypeOfCostAnalysisConstructionObjects", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ConstructionObject", 
			"ConstructionObject", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or UpdateAll Then
		
		PropertyValue = (Object.DimensionKindExpenseCapitalization <> PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ConstructionObject", 
			"ConstructionObject", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.WriteOffVariancesAsExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAdjustmentOption", 
			"DepreciationAdjustmentOption", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region FixedAssetsPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting
			And Not Object.WriteOffVariancesAsExpenses;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.AmountAccounting", 
			"FAAmountAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = 
			Object.RecordInManAccounting
			And Not Object.WriteOffVariancesAsExpenses
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.AmountOfUU", 
			"FAAmountOfUU", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or UpdateAll Then
		
		PropertyValue = Object.WriteOffVariancesAsExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemWriteOffCosts", 
			"ExpenseItemWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseDimensionWriteOffCosts", 
			"ExpenseDimensionWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitWriteOffCosts", 
			"BusinessUnitWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessWriteOffCosts", 
			"LineOfBusinessWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts")
		Or StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCosts;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitWriteOffCosts", 
			"BusinessUnitWriteOffCosts", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessWriteOffCosts", 
			"LineOfBusinessWriteOffCosts", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region AdditionalPage
	
	If StructureOfChangedProps.Property("TargetFinancingApplicationOption")
		Or StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"Visible", 
			AuxiliaryAttributes.LineOfBusinessIsMandatory, 
			ItemDetailsParameters);
		
	EndIf; 
	
	#EndRegion
	
	Return ItemDetailsParameters;

EndFunction

// 
// Parameters:
//  Object - DocumentObject.FARevaluation2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_RevaluationOfFA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInManagementAccounting", 
			"FACostInManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInAccounting", 
			"FACostInAccounting", 
			"Visible", 
			Object.RecordInLocalAccounting, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesBusinessUnit", 
			"ExpensesBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseLineOfBusiness", 
			"ExpenseLineOfBusiness", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("IncomeBusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeBusinessUnit", 
			"IncomeBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessIncome", 
			"LineOfBusinessIncome", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.SplitFixedAssets, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_FADisassembly(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	#Region BUParameters
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostInAccounting", 
			"CostInAccounting", 
			"Visible", 
			AuxiliaryAttributes.RecordInLocalAccounting, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue = 
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Not AuxiliaryAttributes.FSB6IsApplied
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationSchedule", 
			"DepreciationSchedule", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation")
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ACUsefulLifeExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation")
			And Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance");
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting",
			"AccelerationFactorAccounting",
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
	EndIf;
	
	#EndRegion
	
	#Region MaParameters
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting 
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostInManagementAccounting", 
			"CostInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.RecordInManAccounting
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation")
			And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation")
			And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance");
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting",
			"AccelerationFactorManagementAccounting",
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
	EndIf;

	#EndRegion
	
	#Region CommonParameters
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
			
		PropertyValue = Not AuxiliaryAttributes.CurrenciesDoNotMatch And AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.RecordInManAccounting
			Or AuxiliaryAttributes.RecordInManAccounting And Not AuxiliaryAttributes.RecordInLocalAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		PropertyValue = AuxiliaryAttributes.RecordInLocalAccounting And AuxiliaryAttributes.RecordInManAccounting
			Or AuxiliaryAttributes.RecordInLocalAccounting And Not AuxiliaryAttributes.RecordInManAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting") 
		Or UpdateAll Then
		
		PropertyValue =
			Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
			Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
			And AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValue", 
			"RunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
	
	If UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialAccountingGroup",
			"FinancialAccountingGroup",
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
	EndIf;
	
	#EndRegion

	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_FADisassembly(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_EnteringBalances(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	ItemDetailsParameters = Undefined;
	
	If AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryFixedAssets")
		Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty")
		Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut")
		Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets") Then
		
		ItemDetailsParameters = PropertyValuesOfDependentProps_EnteringBalances__(Object, AuxiliaryAttributes, ChangedBankingDetails);
		
	ElsIf AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets") Then
		
		ItemDetailsParameters = PropertyValuesOfDependentProps_EnteringResidues_NMA(Object, AuxiliaryAttributes, ChangedBankingDetails);
		
	ElsIf AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryLeaseContractsARAP") Then
		
		ItemDetailsParameters = PropertyValuesOfDependentDetails_EnteringBalances_LeaseCalculations(Object, AuxiliaryAttributes, ChangedBankingDetails);
		
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsInitialRecognition2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_AcceptanceForAccountingByIA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	IAAcceptanceParameters = IAAcceptanceParameters(Object, AuxiliaryAttributes);
		
	IntangibleAssetsInitialRecognitionClientServerLocalization.AddPropertyValuesForDependentProps(
		Object, IAAcceptanceParameters, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	#Region IsMain
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then

		PropertyValue = 
			IAAcceptanceParameters.ACCostIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			IAAcceptanceParameters.ACCostIsAvailable
			And (IAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or IAAcceptanceParameters.ActualCost);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			IAAcceptanceParameters.CostOfMaIsAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		PropertyValue = 
			IAAcceptanceParameters.CostOfMaIsAvailable
			And (IAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfMA
				Or IAAcceptanceParameters.ActualCost);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = IAAcceptanceParameters.ACCostIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = IAAcceptanceParameters.CostOfMaIsAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueMan", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("TargetFinancingApplicationOption") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"AutoMarkIncomplete", 
			IAAcceptanceParameters.LineOfBusinessIsMandatory, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region AccountingParametersOfBU
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ACUsefulLifeExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting",
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			And Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualFactor", 
			"DepreciationAccrualFactor", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region UUAccountingParameters
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then
		
		PropertyValue = Object.RecordInManAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			IAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			IAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			IAAcceptanceParameters.AvailableMaDepreciationParameters, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			IAAcceptanceParameters.AvailableMaDepreciationParameters
			And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear")
				Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
		//
		PropertyValue = Object.RecordInManAccounting
			And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			And Object.DepreciationAccrualMethodManagementAccounting =
				PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			IAAcceptanceParameters.ByAssetActivity, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region ReflectionOfBUExpenses
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And IAAcceptanceParameters.AvailableReflectionOfBUExpenses;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region ReflectionOfExpensesOfUU
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		PropertyValue = IAAcceptanceParameters.AvailableReflectionOfMaExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting 
			And IAAcceptanceParameters.ExpenseItemManagementAccountingRequired_;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			IAAcceptanceParameters.AvailableReflectionOfMaExpenses
			And IAAcceptanceParameters.ExpenseItemManagementAccountingRequired_;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting")
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		PropertyName = ?( 
			Not PropertyValue
			And Not IAAcceptanceParameters.ExpenseItemManagementAccountingRequired_,
			"ReadOnly",
			"OnlyViewWithoutBlankMark");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			PropertyName, 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	#Region ReflectionOfExpensesOther
	
	If StructureOfChangedProps.Property("TransferExpensesToAnotherCompany") 
		Or UpdateAll Then
		
		PropertyValue = Object.TransferExpensesToAnotherCompany;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses", 
			"Enabled", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses", 
			"ReadOnly", 
			Not PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.ThereAreRelatedCompanies;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"TransferExpensesToAnotherCompany", 
			"TransferExpensesToAnotherCompany",
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses",
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	#EndRegion
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.DisposeIntangibleAssets2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesForDependentDetails_WriteOffIA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("ExpenseItem")
		Or StructureOfChangedProps.Property("DimensionCorrespondsToIAToWriteOff")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.DimensionCorrespondsToIAToWriteOff;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfExpenses", 
			"DimensionOfExpenses", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;

	If StructureOfChangedProps.Property("ExpenseItem")
		Or UpdateAll Then
			
		PropertyValue = 
			TypeOf(Object.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.ExpenseItems")
			And ValueIsFilled(Object.ExpenseItem);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionCorrespondsToIAToWriteOff", 
			"DimensionCorrespondsToIAToWriteOff", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;

	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialIntangibleAssetsDisposal")
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.AmountManagementAccounting", 
			"IAAmountManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialIntangibleAssetsDisposal");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.ChargeAmountAccounting", 
			"IAChargeAmountAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or UpdateAll Then
			
		PropertyValue = 
			Object.PostInAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialIntangibleAssetsDisposal");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.ResidualValueLocal", 
			"IAResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("PostInAccounting") 
		Or UpdateAll Then
			
		PropertyValue = 
			Object.RecordInManAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialIntangibleAssetsDisposal")
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.ResidualValueMan", 
			"IAResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesBusinessUnit", 
			"ExpensesBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseLineOfBusiness", 
			"ExpenseLineOfBusiness", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	NonCurrentAssetsClientServerLocalization.AddPropertyValuesForDependentDetails_WriteOffIA(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.IARevaluation2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_RevaluationOfIa(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostInManagementAccounting", 
			"IACostInManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostInAccounting", 
			"IACostInAccounting", 
			"Visible", 
			Object.RecordInLocalAccounting, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesBusinessUnit", 
			"ExpensesBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseLineOfBusiness", 
			"ExpenseLineOfBusiness", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("IncomeBusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeBusinessUnit", 
			"IncomeBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessIncome", 
			"LineOfBusinessIncome", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.IATransfer2_4 - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps__IA(Object, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or UpdateAll Then
			
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"Organization", 
			"ItemVisibility", 
			Not PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DeliveryCompany", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipient", 
			"CompanyRecipient", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.ChangeIntangibleAssetFinancialDetails2_4 - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_ChangingIAParameters(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	#Region PageGeneral
	
	If UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DocumentBasis", 
			"DocumentBasis", 
			"Visible", 
			ValueIsFilled(Object.DocumentBasis), 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region BUParameters
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		// AccountingProcedureAC
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureACFlag", 
			"AccountingProcedureACFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		// DepreciationMethodAccounting
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccountingFlag", 
			"DepreciationMethodAccountingFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		// UsefulLifeAccounting
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccountingFlag", 
			"UsefulLifeAccountingFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ACUsefulLifeExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		// DepreciationAccrualFactor
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualFactor", 
			"DepreciationAccrualFactor", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualFactorFlag", 
			"DepreciationAccrualFactorFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureACFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"OnlyViewWithoutBlankMark", 
			Not Object.AccountingProcedureACFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccountingFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.DepreciationMethodAccountingFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeAccountingFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.UsefulLifeAccountingFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualFactorFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualFactor", 
			"DepreciationAccrualFactor", 
			"OnlyViewWithoutBlankMark", 
			Not Object.DepreciationAccrualFactorFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region MaParameters
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMAFlag", 
			"AccountingProcedureMAFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("AccountingProcedureMAFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"OnlyViewWithoutBlankMark", 
			Not Object.AccountingProcedureMAFlag, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccountingFlag", 
			"DepreciationAccrualMethodManagementAccountingFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccountingFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.DepreciationAccrualMethodManagementAccountingFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then

		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccountingFlag", 
			"UsefulLifeManagementAccountingFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
			
		//
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccountingFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.UsefulLifeManagementAccountingFlag, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then

		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccountingFlag", 
			"AccelerationFactorManagementAccountingFlag", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("AccelerationFactorManagementAccountingFlag") 
		Or UpdateAll Then

		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.AccelerationFactorManagementAccountingFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region CommonParameters
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or UpdateAll Then
		
		PropertyValue = Object.RecordInManAccounting Or Object.PostInAccounting;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTimeFlag", 
			"EstimatedRunningTimeFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("FinancialAccountingGroupFlag")
		Or UpdateAll Then

		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialAccountingGroup",
			"FinancialAccountingGroup",
			"OnlyViewWithoutBlankMark",
			Not Object.FinancialAccountingGroupFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("EstimatedRunningTimeFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime",
			"EstimatedRunningTime",
			"OnlyViewWithoutBlankMark",
			Not Object.EstimatedRunningTimeFlag,
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("LineOfBusinessFlag")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness",
			"LineOfBusiness",
			"ReadOnly",
			Not Object.LineOfBusinessFlag,
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueMan", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueManFlag", 
			"ResidualValueManFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualValueManFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueMan", 
			"ResidualValueMan", 
			"OnlyViewWithoutBlankMark", 
			Not Object.ResidualValueManFlag, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or UpdateAll Then
		
		PropertyValue = Object.PostInAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocalFlag", 
			"ResidualValueLocalFlag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualValueLocalFlag") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"OnlyViewWithoutBlankMark", 
			Not Object.ResidualValueLocalFlag, 
			ItemDetailsParameters);
			
	EndIf;
	
	// If you change the parameters only in tax accounting, changing the CGU does not make sense.
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		If (Object.PostInAccounting = False And Object.RecordInManAccounting = False)
			 And (Object.RecordInTA And Object.RecordInLocalAccounting) Then // Changing parameters only in tax accounting.
			 	VisibilityOfCGU = False;
		Else 														// All other options for changing parameters.
				VisibilityOfCGU = True;
		EndIf;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"CGU",
			"CGU",
			"Visible",
			VisibilityOfCGU,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CGUFlag",
			"CGUFlag",
			"Visible",
			VisibilityOfCGU,
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region Depreciation
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or UpdateAll Then
	
		PropertyValue = Not Object.DepreciationExpenseRecordingIsChanged;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Depreciation", 
			"Depreciation", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesPostingMethod",
			"ExpensesPostingMethod",
			"ReadOnly",
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"DepreciationIsExpenseItemWithoutDivision",
			"OnlyViewWithoutBlankMark",
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"SwitchDepreciationWithoutSplitting",
			"ReadOnly",
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or StructureOfChangedProps.Property("SwitchDepreciationWithoutSplitting")
		Or StructureOfChangedProps.Property("DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision")
		Or UpdateAll Then

		PropertyValue = 
			Object.Depreciation.Count() = 0
			Or Object.Depreciation[0].BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationDivisionWithoutDivision", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationLineOfBusinessWithoutDivision", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or StructureOfChangedProps.Property("SwitchDepreciationWithoutSplitting")
		Or StructureOfChangedProps.Property("DepreciationTransferExpensesToAnotherCompanyWithoutSplitting")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.Depreciation.Count() = 0
			Or Not Object.Depreciation[0].TransferExpensesToAnotherCompany;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"DepreciationCompanyRecipientOfExpensesWithoutDivision",
			"OnlyViewWithoutBlankMark",
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_ChangeParametersOfIA(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
		
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.CustomerInvoiceServicesAndAssets, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentDetails_SaleOfServicesOfOtherAssets(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	ItemDetailsParameters = New Array;
	
	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentDetails_SaleOfServicesOfOtherAssets(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	If StructureOfChangedProps.Property("BusinessOperation") Then
		
		PropertyValue = (Object.BusinessOperation 
								= PredefinedValue("Enum.BusinessTransactions.RenderRentalServices"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Income.RentalComponentOfContract", 
			"IncomeRentalComponentOfContract", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Income.RentalObject", 
			"IncomeRentalObject", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	EndIf;
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.MergeOfFixedAssets - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_FAUnion(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	FAPoolingOptions = FAPoolingOptions(Object, AuxiliaryAttributes);
	
	#Region IsMain
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		PropertyValue = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets"));
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MergeOfSimilarFixedAssets", 
			"MergeOfSimilarFixedAssets", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region AccountingParametersOfBU
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently 
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept 
			And Not Object.MergeOfSimilarFixedAssets;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently 
			And FAPoolingOptions.ACDepreciationParametersAreAvailable
			And Not Object.MergeOfSimilarFixedAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ACUsefulLifeExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue =
			Object.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently 
			And Not Object.MergeOfSimilarFixedAssets 
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.BySumOfUsefulLifeYearNumbers"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting",
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
			
		PropertyValue =
			Object.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently 
			And Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
			And FAPoolingOptions.ACDepreciationParametersAreAvailable
			And Not Object.MergeOfSimilarFixedAssets;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or UpdateAll Then
		    
		PropertyValue = 
			Object.RecordInLocalAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And (Not Object.MergeOfSimilarFixedAssets 
					And FAPoolingOptions.ACDepreciationParametersAreAvailable
					And (Object.DepreciationMethodAccounting <> PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
						Or Object.DepreciationMethodAccounting <> PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage"))
				Or Object.MergeOfSimilarFixedAssets
					And Not AuxiliaryAttributes.AccordingToOperatingTimeOfAC
					And AuxiliaryAttributes.ACDepreciationParametersAreAvailable);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualUsefulLifeAccounting_",
			"",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
			
	    //
		PropertyValue = 
			Object.RecordInLocalAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Not Object.MergeOfSimilarFixedAssets 
			And FAPoolingOptions.ACDepreciationParametersAreAvailable
			And (Object.DepreciationMethodAccounting <> PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
					Or Object.DepreciationMethodAccounting <> PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage"));
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"ResidualUsefulLifeAccounting_",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TermUseResidualBorschagovka",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
	    //
		PropertyValue = 
			Object.RecordInLocalAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Object.MergeOfSimilarFixedAssets 
			And AuxiliaryAttributes.ACDepreciationParametersAreAvailable
			And Not AuxiliaryAttributes.AccordingToOperatingTimeOfAC
			And AuxiliaryAttributes.ACDepreciationParametersAreAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TermOfUseRemainingUsedCombiningTheSameTypeOfOS",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TermUseResidualBorschagovkaAssociationOfSimilarOS",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
	EndIf;
	
	#EndRegion
	
	#Region UUAccountingParameters
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting 
			And Not Object.MergeOfSimilarFixedAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		PropertyValue = 
			FAPoolingOptions.AvailableMaDepreciationParameters 
			And Not Object.MergeOfSimilarFixedAssets;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"UsefulLifeMAExplanation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		PropertyValue = FAPoolingOptions.AvailableMaDepreciationParameters
							And Not Object.MergeOfSimilarFixedAssets
							And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
								Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		PropertyValue = FAPoolingOptions.AvailableMaDepreciationParameters
							And Not Object.MergeOfSimilarFixedAssets
							And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance");
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		    
		PropertyValue = 
			Object.RecordInManAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And (Not Object.MergeOfSimilarFixedAssets 
					And FAPoolingOptions.AvailableMaDepreciationParameters
					And Object.DepreciationAccrualMethodManagementAccounting <> PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
				Or Object.MergeOfSimilarFixedAssets
					And Not AuxiliaryAttributes.AccordingToMaOperatingTime
					And AuxiliaryAttributes.AvailableMaDepreciationParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualUsefulLifeManagementAccounting_",
			"",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Not Object.MergeOfSimilarFixedAssets 
			And FAPoolingOptions.AvailableMaDepreciationParameters
			And Object.DepreciationAccrualMethodManagementAccounting <> PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"ResidualUsefulLifeManagementAccounting_",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TermOfUseResidualUurasshifrovka",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Object.MergeOfSimilarFixedAssets 
			And AuxiliaryAttributes.AvailableMaDepreciationParameters
			And Not AuxiliaryAttributes.AccordingToMaOperatingTime;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TermOfUseResidualYYCombiningTheSameTypeOfOS",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TermOfUseResidualUurasshifrovkaAssociationOfTheSameTypeOfOS",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
	EndIf;
	
	#EndRegion
	
	#Region GeneralAccountingParameters
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets") 
			And Not Object.MergeOfSimilarFixedAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialAccountingGroup", 
			"FinancialAccountingGroup", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Not Object.MergeOfSimilarFixedAssets
			And Not AuxiliaryAttributes.CurrenciesDoNotMatch;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LiquidationValueCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
			
		PropertyValue =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets") 
			And Not Object.MergeOfSimilarFixedAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LiquidationValueReglCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And (Not Object.MergeOfSimilarFixedAssets 
					And FAPoolingOptions.ByAssetActivity
					And (FAPoolingOptions.AvailableMaDepreciationParameters Or FAPoolingOptions.ACDepreciationParametersAreAvailable)
				Or Object.MergeOfSimilarFixedAssets
					And (AuxiliaryAttributes.AvailableMaDepreciationParameters Or AuxiliaryAttributes.ACDepreciationParametersAreAvailable)
					And (AuxiliaryAttributes.AccordingToMaOperatingTime Or AuxiliaryAttributes.AccordingToOperatingTimeOfAC));
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualEstimatedRunningTime",
			"",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
		//
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Not Object.MergeOfSimilarFixedAssets 
			And (FAPoolingOptions.AvailableMaDepreciationParameters Or FAPoolingOptions.ACDepreciationParametersAreAvailable)
			And FAPoolingOptions.ByAssetActivity;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"ResidualEstimatedRunningTime",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
	
		//
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And Object.MergeOfSimilarFixedAssets 
			And (AuxiliaryAttributes.AvailableMaDepreciationParameters Or AuxiliaryAttributes.ACDepreciationParametersAreAvailable)
			And (AuxiliaryAttributes.AccordingToMaOperatingTime Or AuxiliaryAttributes.AccordingToOperatingTimeOfAC);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"TheAmountOfOperatingTimeRemainingCombiningTheSameTypeOfOperatingSystems",
			"Visible",
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = FAPoolingOptions.ByAssetActivity
							And Not Object.MergeOfSimilarFixedAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValue", 
			"RunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RunningTimeValueUnitOfMeasure", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"Visible", 
			Not Object.MergeOfSimilarFixedAssets, 
			ItemDetailsParameters);
		
	EndIf;

	If UpdateAll Then
		
		If Not AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
			TMCommonUseClientServer.AddItemDetailsParameters(
				"LineOfBusiness", 
				"LineOfBusiness", 
				"AutoMarkIncomplete", 
				False, 
				ItemDetailsParameters);
		EndIf; 
		
	EndIf;
	
	#EndRegion
	
	#Region RecordExpenses
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently 
			And Not Object.MergeOfSimilarFixedAssets
			And (FAPoolingOptions.AvailableReflectionOfBUExpenses 
				Or FAPoolingOptions.ExpenseReflectionIsAvailable);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue =
			Object.RecordInManAccounting 
			And FAPoolingOptions.AvailableReflectionOfMaExpenses
			And Not Object.MergeOfSimilarFixedAssets;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			FAPoolingOptions.ExpenseItemManagementAccountingRequired_
			And Not Object.MergeOfSimilarFixedAssets;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			FAPoolingOptions.AvailableReflectionOfMaExpenses
			And FAPoolingOptions.ExpenseItemManagementAccountingRequired_;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting")
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		PropertyName = ?( 
			Not PropertyValue
			And Not FAPoolingOptions.ExpenseItemManagementAccountingRequired_,
			"ReadOnly",
			"OnlyViewWithoutBlankMark");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			PropertyName, 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInLocalAccounting
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets")
			And AuxiliaryAttributes.UsedByCF;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeItem", 
			"IncomeItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfRevenue", 
			"DimensionOfRevenue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.ThereAreRelatedCompanies 
			And Not Object.MergeOfSimilarFixedAssets
			And (FAPoolingOptions.AvailableReflectionOfBUExpenses 
				Or FAPoolingOptions.ExpenseReflectionIsAvailable
				Or FAPoolingOptions.AvailableReflectionOfMaExpenses);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"TransferExpensesToAnotherCompany",
			"TransferExpensesToAnotherCompany", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("TransferExpensesToAnotherCompany") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.TransferExpensesToAnotherCompany 
			And Not Object.MergeOfSimilarFixedAssets;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses",
			"CompanyRecipientOfExpenses", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_FAUnion(
		Object, AuxiliaryAttributes, FAPoolingOptions, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function ValuesOfPropertiesOfDependentProps_AdjustmentOfCostAndDepreciationOfFA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If Object.FinancialDetailsForThePeriod.Count() <> 0 Then
		DepreciationAccrualMethodManagementAccounting = Object.FinancialDetailsForThePeriod[0].DepreciationAccrualMethodManagementAccounting;
	Else
		DepreciationAccrualMethodManagementAccounting = Undefined;
	EndIf;
	
	ThisIsAdjustmentForBeginningOfYear = 
		BegOfDay(Object.Date) = BegOfYear(Object.Date)
		And Not Object.IncludesDepreciationOfCurrentMonth;
	
	AvailableParametersForPeriod = 
		Object.AdjustmentModeFromPreviousDate
		And Object.FixedAssetKind <> PredefinedValue("Enum.PropertyKinds.Leased");
	
	AvailableManAmount =
		AuxiliaryAttributes.ComplianceCAAccountingIsKept
		Or Not AuxiliaryAttributes.CurrenciesDoNotMatch;
			
	LocalAmountAvailable =
		Not AuxiliaryAttributes.ReglVNAAccountingIsConductedIndependently_ForPeriod
		Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
		
	ACCostAdjustment = 
		Object.PostInAccounting
		And Object.CostAdjustment
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
		
	MACostAdjustment =
		Object.RecordInManAccounting
		And Object.CostAdjustment
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
	
	CostAdjustmentTA = 
		Object.RecordInTA
		And Object.CostAdjustment
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
		
	MADepreciationAdjustment =
		Object.RecordInManAccounting
		And Object.DepreciationAdjustment
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept
				And Not AuxiliaryAttributes.CurrenciesDoNotMatch);
	
	ACDepreciationAdjustment =
		Object.PostInAccounting
		And Object.DepreciationAdjustment
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
	
	DepreciationAdjustmentTA =
		Object.RecordInTA
		And Object.DepreciationAdjustment
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
	
	AdjustmentOfInitialCostOfAC = 
		Object.PostInAccounting
		And Object.AdjustmentOfInitialCost
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
		
	AdjustmentOfInitialCostOfMA = 
		Object.RecordInManAccounting
		And Object.AdjustmentOfInitialCost
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own");
		
	AdjustmentOfACDepreciationCalculationParameters = 
		Object.PostInAccounting
		And Object.AdjustmentOfDepreciationCalculationParameters
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And AuxiliaryAttributes.ComplianceCAAccountingIsKept
		And Not AuxiliaryAttributes.FSB6IsApplied;
		
	AdjustmentOfMADepreciationCalculationParameters = 
		Object.RecordInManAccounting
		And Object.AdjustmentOfDepreciationCalculationParameters
		And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
		And AuxiliaryAttributes.ComplianceCAAccountingIsKept
		And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards");
		
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("FinancialDetailsForThePeriod")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("BeginOfPeriod")
		Or UpdateAll Then
		
		ThereIsMethodProportionalToVolumeOfBU = False;
		ThereIsMethodOfReducingRemainderOfBU = False;
		
		For Each RowData In Object.FinancialDetailsForThePeriodAC Do
			
			If RowData.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction") Then
				ThereIsMethodProportionalToVolumeOfBU = True;
			ElsIf RowData.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance") Then
				ThereIsMethodOfReducingRemainderOfBU = True;
			EndIf;
			
		EndDo;
		
	EndIf;
		
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
		
		PropertyValue = Object.FixedAssetKind <> PredefinedValue("Enum.PropertyKinds.Leased");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AdjustmentModeFromPreviousDate", 
			"AdjustmentModeFromPreviousDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BeginOfPeriod", 
			"BeginOfPeriod", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BeginOfPeriod", 
			"BeginOfPeriod", 
			"OnlyViewWithoutBlankMark", 
			Not Object.AdjustmentModeFromPreviousDate, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("CostAdjustment")
		Or UpdateAll Then
		
		PropertyValue =
			Object.CostAdjustment;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostIncreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostDecreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or UpdateAll Then
		
		PropertyValue =
			Object.CostAdjustment
			And Object.CostDecreaseRecording;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordCostDecreaseByReversal", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or UpdateAll Then
		
		PropertyValue = Object.DepreciationAdjustment;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationIncreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationDecreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncludesDepreciationOfCurrentMonth", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("PeriodAdjustment")
		Or UpdateAll Then
			
		PropertyValue =
			Object.DepreciationAdjustment
			And Not Object.PeriodAdjustment;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("SeparateAdjustmentOfCurrentAndPreviousPeriods")
		Or StructureOfChangedProps.Property("PeriodAdjustment")
		Or UpdateAll Then
		
		PropertyValue =
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods
			And Not Object.PeriodAdjustment;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordThisYearDepreciationDecreaseAsStorno", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
			And (EndOfDay(Object.Date) = EndOfYear(Object.Date)
				Or Object.PeriodAdjustment <> 0);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PeriodAdjustment", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	#EndRegion
		
	#Region OSPage
	
	#Region ACC
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentOfInitialCost")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentOfDepreciationCalculationParameters")
		Or StructureOfChangedProps.Property("SeparateAdjustmentOfCurrentAndPreviousPeriods")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentForPeriod")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInAccounting", 
			"", 
			"Visible", 
			ACCostAdjustment, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ACDepreciationAdjustment 
			And Not Object.DepreciationAdjustmentForPeriod
			And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
				Or Not ThisIsAdjustmentForBeginningOfYear);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.DepreciationInAccounting", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.InitialCostLocalAccounting", 
			"", 
			"Visible", 
			AdjustmentOfInitialCostOfAC, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ACDepreciationAdjustment 
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods
			And Not Object.DepreciationAdjustmentForPeriod;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.DepreciationAsOfTheYearStartBookkeeping", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostUsedToCalculateDepreciationInAccounting", 
			"FACostUsedToCalculateDepreciationInAccounting", 
			"Visible", 
			AdjustmentOfACDepreciationCalculationParameters And Not AuxiliaryAttributes.FSB6IsApplied, 
			ItemDetailsParameters);
			
		//
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FACostInAccounting", 
			"MarkIncomplete", 
			Not AuxiliaryAttributes.ComplianceCAAccountingIsKept And ACCostAdjustment, 
			ItemDetailsParameters);
			
		//
		ShowFieldSeparately = 
			Not AuxiliaryAttributes.IncomeTaxPayer
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FACostInAccounting", 
			"Visible", 
			ACCostAdjustment And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			ACDepreciationAdjustment
			And Not Object.DepreciationAdjustmentForPeriod 
			And Not ShowFieldSeparately 
			And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
				Or Not ThisIsAdjustmentForBeginningOfYear);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepreciationInAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			ACDepreciationAdjustment 
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
			And Not Object.DepreciationAdjustmentForPeriod
			And Not ShowFieldSeparately;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepreciationAsOfTheYearStartBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAInitialCostLocalAccounting", 
			"Visible", 
			AdjustmentOfInitialCostOfAC And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OsstoimostUsedSeparately", 
			"Visible", 
			ACCostAdjustment And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ACDepreciationAdjustment
			And Not Object.DepreciationAdjustmentForPeriod
			And ShowFieldSeparately 
			And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
					Or Not ThisIsAdjustmentForBeginningOfYear);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OsamortizatsiyaUsedSeparately", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ACCostAdjustment
			And Not Object.DepreciationAdjustmentForPeriod 
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
			And ShowFieldSeparately;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepreciationAtBeginningOfYearAC_Separately", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OpenvanillaTheValueOfBFromA", 
			"Visible", 
			AdjustmentOfInitialCostOfAC And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FACostInAccounting", 
			"MarkIncomplete", 
			Not AuxiliaryAttributes.ComplianceCAAccountingIsKept And ACCostAdjustment, 
			ItemDetailsParameters);
			
	EndIf;

	#EndRegion
	
	#Region MA
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentOfInitialCost")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentOfDepreciationCalculationParameters")
		Or StructureOfChangedProps.Property("SeparateAdjustmentOfCurrentAndPreviousPeriods")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentForPeriod")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostInManagementAccounting", 
			"", 
			"Visible", 
			MACostAdjustment, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			MADepreciationAdjustment 
			And Not Object.DepreciationAdjustmentForPeriod
			And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
				Or Not ThisIsAdjustmentForBeginningOfYear);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.DepreciationManagementAccounting", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue =
			MADepreciationAdjustment 
			And Not Object.DepreciationAdjustmentForPeriod
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.DepreciationAtBeginningOfYearMa", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.InitialCostMA", 
			"", 
			"Visible", 
			AdjustmentOfInitialCostOfMA, 
			ItemDetailsParameters);
			
		//
		ShowFieldSeparately = 
			Not Object.RecordInLocalAccounting
			Or Not AuxiliaryAttributes.IncomeTaxPayer
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FACostInManagementAccounting", 
			"Visible", 
			MACostAdjustment And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			MADepreciationAdjustment
			And Not Object.DepreciationAdjustmentForPeriod 
			And Not ShowFieldSeparately 
			And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
				Or Not ThisIsAdjustmentForBeginningOfYear);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepreciationManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue =
			MADepreciationAdjustment 
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
			And Not Object.DepreciationAdjustmentForPeriod 
			And Not ShowFieldSeparately;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepreciationAtBeginningOfYearMa", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAInitialCostMA", 
			"Visible", 
			AdjustmentOfInitialCostOfMA And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OsstoimostUUSeparately", 
			"Visible", 
			MACostAdjustment And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			MADepreciationAdjustment 
			And Not Object.DepreciationAdjustmentForPeriod 
			And ShowFieldSeparately 
			And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
					Or Not ThisIsAdjustmentForBeginningOfYear);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OsamortizatsiyaUUSeparately", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			MADepreciationAdjustment 
			And Not Object.DepreciationAdjustmentForPeriod 
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods 
			And ShowFieldSeparately;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepreciationAtBeginningOfYearUU_Separately", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"InitialCostOfYYSeparately", 
			"Visible", 
			AdjustmentOfInitialCostOfMA And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AdjustmentOfMADepreciationCalculationParameters 
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards")
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostUsedToCalculateDepreciationInManagementAccounting", 
			"FACostUsedToCalculateDepreciationInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
						
	EndIf;
	
	#EndRegion
		
	#EndRegion

	#Region BUParameters
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.ReglVNAAccountingIsConductedIndependently_ForPeriod
			And AvailableParametersForPeriod;
								
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialDetailsForThePeriodAC", 
			"FinancialDetailsForThePeriodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
						
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResultIsACDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineDepreciationACCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineDepreciationPD", 
			"Visible", 
			PropertyValue And AuxiliaryAttributes.ComplianceCAAccountingIsKept, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineDepreciationPDCurrency", 
			"Visible", 
			PropertyValue And AuxiliaryAttributes.ComplianceCAAccountingIsKept, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And AvailableParametersForPeriod;
					
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"CommissioningDateAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or StructureOfChangedProps.Property("ApplicationOfTargetFinancing")
		Or UpdateAll Then

		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And AvailableParametersForPeriod
			And Object.ApplicationOfTargetFinancing;
					
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"TargetFundsInDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationOfCFAtBeginningOfPeriodCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"PermanentDifferencesOfTargetFundsInDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationOfPRTFAtBeginningOfPeriodCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACFixedAssetDepreciationTargetFinancing", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACCostTargetFinancing", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACCostTargetFinancingPD", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACFixedAssetDepreciationTargetFinancingUpdate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACDepreciationTargetFinancingPDUpdate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("BeginOfPeriod")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.PostInAccounting
			And AvailableParametersForPeriod
			And Not AuxiliaryAttributes.FSB6_IsAppliedForPeriod;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACCostUsedToCalculateDepreciationInAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACPermanentDifferencesUsedToCalculateDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.PostInAccounting
			And AvailableParametersForPeriod
			And AuxiliaryAttributes.FSB6_IsAppliedForPeriod
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"FinancialDetailsForThePeriodACResidualValueMan", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"FinancialDetailsForThePeriodACDateOfDepreciationParametersChangeAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("FinancialDetailsForThePeriod")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("BeginOfPeriod")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And AvailableParametersForPeriod
			And ThereIsMethodOfReducingRemainderOfBU;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACAccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.PostInAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And AvailableParametersForPeriod
			And ThereIsMethodProportionalToVolumeOfBU;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACOutputAtBeginningOfMonth", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACOutputVolume", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACVolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodACRunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	#EndRegion
		
	#Region MaParameters
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.RecordInManAccounting
			And AvailableParametersForPeriod;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialDetailsForThePeriod", 
			"FinancialDetailsForThePeriod", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CommissioningDateMA", 
			"CommissioningDateMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineDepreciationMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineDepreciationMACurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And AvailableParametersForPeriod
			And AvailableManAmount;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAsOfThePeriodStart", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAtBeginningOfPeriodCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodCost", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And AvailableParametersForPeriod
			And LocalAmountAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodLocalCost", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And AvailableParametersForPeriod
			And AvailableManAmount
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodCostUsedToCalculateDepreciationManag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And AvailableParametersForPeriod
			And LocalAmountAvailable
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodCostUsedToCalculateDepreciationLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.RecordInManAccounting
			And AvailableParametersForPeriod
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodDateOfDepreciationParametersChangeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("FinancialDetailsForThePeriod")
		Or UpdateAll Then
		
		ThereIsMethodOfReducingRemainderOfBU = False;
		ThereIsMethodForOperatingTime = False;
		For Each RowData In Object.FinancialDetailsForThePeriod Do
			
			If RowData.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance") Then
				ThereIsMethodOfReducingRemainderOfBU = True;
			EndIf;
			
			If RowData.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction") Then
				ThereIsMethodForOperatingTime = True;
			EndIf;

			If ThereIsMethodOfReducingRemainderOfBU And ThereIsMethodForOperatingTime Then
				Break;
			EndIf;
			
		EndDo;
		
		PropertyValue = 
			ThereIsMethodOfReducingRemainderOfBU
			And AvailableParametersForPeriod;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodAccelerationFactor", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			ThereIsMethodOfReducingRemainderOfBU
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards")
			And AvailableParametersForPeriod
			And LocalAmountAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LocalCostAtBeginningOfYearMa", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LocalValueAtBeginningOfYearMaCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LocalDepreciationAtBeginningOfYearMa", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationLocalAtBeginningOfYearMaCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = 
			ThereIsMethodOfReducingRemainderOfBU
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards") 
			And AvailableParametersForPeriod
			And AvailableManAmount;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"CostAtBeginningOfYearMa", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"CostAtBeginningOfYearMaCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAtBeginningOfYearMa", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAtBeginningOfYearMaCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = ThereIsMethodForOperatingTime;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodOutputVolume", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodOutputAtBeginningOfMonth", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodVolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodRunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If UpdateAll Then
		
		PropertyValue = LocalAmountAvailable;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodDepreciationLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodDepreciationLocalUpdate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = AvailableManAmount;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FinancialDetailsForThePeriodDepreciationUpdate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region DepreciationAsOfThePeriodStart
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
			
		PropertyValue =
			Object.RecordInManAccounting 
			And AvailableParametersForPeriod
			And AvailableManAmount;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAsOfThePeriodStart", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAtBeginningOfPeriodCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
			
		PropertyValue =
			Object.PostInAccounting 
			And AvailableParametersForPeriod;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LocalDepreciationAtBeginningOfPeriod", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LocalDepreciationAtBeginningOfPeriodCurrency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region ExpensesAndIncomePage
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostIncreaseRecording")
		Or StructureOfChangedProps.Property("RecordCostChangeInTADueToPD")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue =
			(ACCostAdjustment 
				Or CostAdjustmentTA
					And Not Object.RecordCostChangeInTADueToPD 
				Or MACostAdjustment)
			And Object.CostIncreaseRecording;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostIncrease", 
			"BusinessUnitCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostIncrease", 
			"LineOfBusinessCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or StructureOfChangedProps.Property("RecordCostChangeInTADueToPD")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue =
			(ACCostAdjustment 
				Or CostAdjustmentTA 
					And Not Object.RecordCostChangeInTADueToPD 
				Or MACostAdjustment)
			And Object.CostDecreaseRecording;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodCostDecrease", 
			"ExpenseRecordMethodCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostDecrease", 
			"BusinessUnitCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostDecrease", 
			"LineOfBusinessCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationCostReduction", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationIncreaseRecording")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue =
			Object.DepreciationAdjustment
			And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
			And Object.DepreciationIncreaseRecording;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodDepreciationIncrease", 
			"ExpenseRecordMethodDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationIncrease", 
			"BusinessUnitDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationIncrease", 
			"LineOfBusinessDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationIncreasedDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("RecordThisYearDepreciationDecreaseAsStorno")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue =
			Object.DepreciationAdjustment
			And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
			And Object.DepreciationDecreaseRecording
			And Object.RecordThisYearDepreciationDecreaseAsStorno;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodCurrentYearDepreciationDecrease", 
			"ExpenseRecordMethodCurrentYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitThisYearDepreciationDecrease", 
			"BusinessUnitThisYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessThisYearDepreciationDecrease", 
			"LineOfBusinessThisYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationReductionOfDepreciationOfCurrentYear", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue =
			Object.DepreciationAdjustment
			And Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
			And Object.DepreciationDecreaseRecording;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationDecrease", 
			"BusinessUnitDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationDecrease", 
			"LineOfBusinessDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationReductionOfDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostIncreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		PropertyValue = 
			Object.CostAdjustment
			And Object.CostIncreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostIncrease", 
			"BusinessUnitCostIncrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostIncrease", 
			"LineOfBusinessCostIncrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.CostAdjustment
			And Object.CostDecreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostDecrease", 
			"BusinessUnitCostDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostDecrease", 
			"LineOfBusinessCostDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationIncreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAdjustment
			And Object.DepreciationIncreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationIncrease", 
			"BusinessUnitDepreciationIncrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationIncrease", 
			"LineOfBusinessDepreciationIncrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitThisYearDepreciationDecrease", 
			"BusinessUnitThisYearDepreciationDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessThisYearDepreciationDecrease", 
			"LineOfBusinessThisYearDepreciationDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationDecrease", 
			"BusinessUnitDepreciationDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationDecrease", 
			"LineOfBusinessDepreciationDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("RecordInTA")
		Or StructureOfChangedProps.Property("BonusDepreciationAdjustment")
		Or StructureOfChangedProps.Property("BonusDepreciationIncreaseRecording")
		Or StructureOfChangedProps.Property("RecordingOfBonusDepreciationDecreaseStorno")
		Or StructureOfChangedProps.Property("ExpenseParametersMatchAccountingDataBonusDepreciation")
		Or UpdateAll Then

		PropertyValue =
			Object.RecordInTA 
			And Object.BonusDepreciationAdjustment
			And Object.ExpenseParametersMatchAccountingDataBonusDepreciation;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"Business_UnitBonusDepreciation", 
			"Business_UnitBonusDepreciation", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness_BonusDepreciation", 
			"LineOfBusiness_BonusDepreciation", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("RecordInTA")
		Or StructureOfChangedProps.Property("BonusDepreciationAdjustment")
		Or StructureOfChangedProps.Property("BonusDepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("RecordingOfBonusDepreciationDecreaseStorno")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.RecordInTA 
			And Object.BonusDepreciationAdjustment
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitBonusDepreciationDecrease", 
			"BusinessUnitBonusDepreciationDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBonusDepreciationDecrease", 
			"LineOfBusinessBonusDepreciationDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	FixedAssetCostAndDepreciationAdjustmentClientServerLocalization.AddPropertyValuesForDependentProps(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;

EndFunction

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsCostAndAmortizationAdjustment - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function ValuesOfPropertiesOfDependentDetails_AdjustmentOfCostAndDepreciationOfIa(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ThisIsIA = (Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset"));
	
	ThisIsAdjustmentForBeginningOfYear = (BegOfDay(Object.Date) = BegOfYear(Object.Date));
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("DocumentBasis")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DocumentBasis", 
			"DocumentBasis", 
			"Visible", 
			ValueIsFilled(Object.DocumentBasis), 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAdjustment", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset")
			And (EndOfDay(Object.Date) = EndOfYear(Object.Date)
				And Object.PeriodAdjustment);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PeriodAdjustment", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("CostAdjustment")
		Or UpdateAll Then
		
		PropertyValue =
			Object.CostAdjustment;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostIncreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostDecreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or UpdateAll Then
		
		PropertyValue =
			Object.CostAdjustment
			And Object.CostDecreaseRecording;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordCostDecreaseByReversal", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or UpdateAll Then
		
		PropertyValue = Object.DepreciationAdjustment;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationIncreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationDecreaseRecording", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.DepreciationAdjustment
			Or Object.CostAdjustment
				And Not ThisIsIA;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncludesDepreciationOfCurrentMonth", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("PeriodAdjustment")
		Or UpdateAll Then
			
		PropertyValue =
			Object.DepreciationAdjustment
			And Not Object.PeriodAdjustment;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("SeparateAdjustmentOfCurrentAndPreviousPeriods")
		Or StructureOfChangedProps.Property("PeriodAdjustment")
		Or UpdateAll Then
		
		PropertyValue =
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods
			And Not Object.PeriodAdjustment;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordThisYearDepreciationDecreaseAsStorno", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
		
	#Region NMAPage
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentOfInitialCost")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or UpdateAll Then
		
		#Region MA
		
		PropertyValue = 
			Object.CostAdjustment 
			And Object.RecordInManAccounting 
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept
					And Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		ShowFieldSeparately = 
			Not Object.RecordInLocalAccounting
			Or Not AuxiliaryAttributes.IncomeTaxPayer
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostInManagementAccounting", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IACostInManagementAccounting", 
			"Visible", 
			PropertyValue And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"NmastoimostYYSeparately", 
			"Visible", 
			PropertyValue And ShowFieldSeparately, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.AdjustmentOfInitialCost 
			And Object.RecordInManAccounting 
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept
					And Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.InitialCostMA", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IAInitialCostMA", 
			"Visible", 
			PropertyValue And Not ShowFieldSeparately, 
			ItemDetailsParameters);
					
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"NmaprivalCostYYSeparately", 
			"Visible", 
			PropertyValue And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.DepreciationAdjustment
			And ThisIsIA 
			And Object.RecordInManAccounting 
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept
					And Not AuxiliaryAttributes.CurrenciesDoNotMatch);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.DepreciationManagementAccounting", 
			"", 
			"Visible", 
			PropertyValue And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods Or Not ThisIsAdjustmentForBeginningOfYear), 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IADepreciationManagementAccounting", 
			"Visible", 
			PropertyValue And Not ShowFieldSeparately And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods Or Not ThisIsAdjustmentForBeginningOfYear), 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"NmaamortisationOfUUSeparately", 
			"Visible", 
			PropertyValue And ShowFieldSeparately And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods Or Not ThisIsAdjustmentForBeginningOfYear), 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.DepreciationAtBeginningOfYearMa", 
			"", 
			"Visible", 
			PropertyValue And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IADepreciationAtBeginningOfYearMa", 
			"Visible", 
			PropertyValue And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IADepreciationAtBeginningOfYearUU_Separately", 
			"Visible", 
			PropertyValue And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		#EndRegion
		
		#Region ACC
		
		ShowFieldSeparately = 
			Not AuxiliaryAttributes.IncomeTaxPayer
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
			
		PropertyValue = 
			Object.CostAdjustment
			And Object.PostInAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostInAccounting", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IACostInAccounting", 
			"MarkIncomplete", 
			Not AuxiliaryAttributes.ComplianceCAAccountingIsKept And PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IACostInAccounting", 
			"Visible", 
			PropertyValue And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"NmastoimostUsedSeparately", 
			"Visible", 
			PropertyValue And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.AdjustmentOfInitialCost
			And Object.PostInAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.InitialCostLocalAccounting", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IAInitialCostLocalAccounting", 
			"Visible", 
			PropertyValue And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"NmapfirstCostUsedSeparately", 
			"Visible", 
			PropertyValue And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.DepreciationAdjustment
			And ThisIsIA
			And Object.PostInAccounting;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.DepreciationInAccounting", 
			"", 
			"Visible", 
			PropertyValue And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods Or Not ThisIsAdjustmentForBeginningOfYear), 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IADepreciationInAccounting", 
			"Visible", 
			PropertyValue And Not ShowFieldSeparately And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods Or Not ThisIsAdjustmentForBeginningOfYear), 
			ItemDetailsParameters);
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"NmaamortisationUsedSeparately", 
			"Visible", 
			PropertyValue And ShowFieldSeparately And (Not Object.SeparateAdjustmentOfCurrentAndPreviousPeriods Or Not ThisIsAdjustmentForBeginningOfYear), 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.DepreciationAsOfTheYearStartBookkeeping", 
			"", 
			"Visible", 
			PropertyValue And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IADepreciationAsOfTheYearStartBookkeeping", 
			"Visible", 
			PropertyValue And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods And Not ShowFieldSeparately, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IADepreciationAtBeginningOfYearAC_Separately", 
			"Visible", 
			PropertyValue And Object.SeparateAdjustmentOfCurrentAndPreviousPeriods And ShowFieldSeparately, 
			ItemDetailsParameters);
			
		#EndRegion
			
	EndIf;
	
	#EndRegion
		
	#Region ExpensesAndIncomePage
	
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostIncreaseRecording")
		Or UpdateAll Then

		PropertyValue =
			Object.CostAdjustment
			And Object.CostIncreaseRecording;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostIncrease", 
			"BusinessUnitCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostIncrease", 
			"LineOfBusinessCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationCostIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or UpdateAll Then

		PropertyValue =
			Object.CostAdjustment
			And Object.CostDecreaseRecording;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodCostDecrease", 
			"ExpenseRecordMethodCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostDecrease", 
			"BusinessUnitCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostDecrease", 
			"LineOfBusinessCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationCostReduction", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationIncreaseRecording")
		Or UpdateAll Then

		PropertyValue =
			Object.DepreciationAdjustment
			And Object.DepreciationIncreaseRecording;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodDepreciationIncrease", 
			"ExpenseRecordMethodDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationIncrease", 
			"BusinessUnitDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationIncrease", 
			"LineOfBusinessDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationIncreasedDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("RecordThisYearDepreciationDecreaseAsStorno")
		Or UpdateAll Then

		PropertyValue =
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.RecordThisYearDepreciationDecreaseAsStorno;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodCurrentYearDepreciationDecrease", 
			"ExpenseRecordMethodCurrentYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitThisYearDepreciationDecrease", 
			"BusinessUnitThisYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessThisYearDepreciationDecrease", 
			"LineOfBusinessThisYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationReductionOfDepreciationOfCurrentYear", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or UpdateAll Then

		PropertyValue =
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationDecrease", 
			"BusinessUnitDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationDecrease", 
			"LineOfBusinessDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DecorationReductionOfDepreciation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostIncreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.CostAdjustment
			And Object.CostIncreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostIncrease", 
			"BusinessUnitCostIncrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostIncrease", 
			"LineOfBusinessCostIncrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.CostAdjustment
			And Object.CostDecreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitCostDecrease", 
			"BusinessUnitCostDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessCostDecrease", 
			"LineOfBusinessCostDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationIncreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAdjustment
			And Object.DepreciationIncreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationIncrease", 
			"BusinessUnitDepreciationIncrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationIncrease", 
			"LineOfBusinessDepreciationIncrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitThisYearDepreciationDecrease", 
			"BusinessUnitThisYearDepreciationDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessThisYearDepreciationDecrease", 
			"LineOfBusinessThisYearDepreciationDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAdjustment
			And Object.DepreciationDecreaseRecording
			And Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitDepreciationDecrease", 
			"BusinessUnitDepreciationDecrease", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessDepreciationDecrease", 
			"LineOfBusinessDepreciationDecrease", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
		
	IntangibleAssetsCostAndAmortizationAdjustmentClientServerLocalization.AddPropertyValuesForDependentProps(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;

EndFunction

Function FillInDetailsDependingOnProperties_ChangeFAParameters(Object, ItemDetailsParameters) Export

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If AttributeParameters.Property = "Visible" And AttributeParameters.Value = False
			Or AttributeParameters.Property = "ReadOnly" And AttributeParameters.Value = True
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMark" And AttributeParameters.Value = True Then
			Action = "Clear";
		ElsIf AttributeParameters.Property = "Visible" And AttributeParameters.Value = True
			Or AttributeParameters.Property = "ReadOnly" And AttributeParameters.Value = False
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMark" And AttributeParameters.Value = False Then
			Action = "Fill";
		Else
			Continue;
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationExpenseRecordingIsChanged" Then
			If Action = "Clear" Then
				Object.Depreciation.Clear();
				ChangedBankingDetails.Add("Depreciation");
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "BonusDepreciationRecordingIsChanged" Then
			If Action = "Clear" Then
				Object.DepreciationAllowance.Clear();
				ChangedBankingDetails.Add("DepreciationAllowance");
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "ReflectionOfPropertyTaxes" Then
			If Action = "Clear" Then
				Object.PropertyTaxes.Clear();
				ChangedBankingDetails.Add("PropertyTaxes");
			EndIf;
		EndIf;
		
	EndDo;
	
	Return StrConcat(ChangedBankingDetails, ",");

EndFunction

Function FillInDetailsDependingOnProperties__FA(Object, ItemDetailsParameters) Export

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If AttributeParameters.Property = "Visible" And AttributeParameters.Value = False
			Or AttributeParameters.Property = "ReadOnly" And AttributeParameters.Value = True
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMark" And AttributeParameters.Value = True Then
			Action = "Clear";
		ElsIf AttributeParameters.Property = "Visible" And AttributeParameters.Value = True
			Or AttributeParameters.Property = "ReadOnly" And AttributeParameters.Value = False
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMark" And AttributeParameters.Value = False Then
			Action = "Fill";
		Else
			Continue;
		EndIf;
		
		If AttributeParameters.AttributeName = "LineOfBusiness" Then
			
			If Action = "Clear" Then
				Object[AttributeParameters.AttributeName] = Undefined;
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf;
			
		EndIf; 
		
	EndDo;
	
	Return StrConcat(ChangedBankingDetails, ",");

EndFunction

// 
// Parameters:
// 	Object - CatalogObject.Assets - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentProps_ObjectsOfOperation(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	NonCurrentAssetsClientServerLocalization.AddPropertyValuesForDependentProps_ObjectsOfOperation(
		Object, StructureOfChangedProps, ItemDetailsParameters);
	
	If StructureOfChangedProps.Property("OSType")
		Or UpdateAll Then

		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			Or Object.OSType = PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets");

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfLastEdit", 
			"DateOfLastEdit", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Placement", 
			"Placement", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"OperatingBusinessUnit", 
			"OperatingBusinessUnit", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CodeByUFADR", 
			"CodeByUFADR", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			Or Object.OSType = PredefinedValue("Enum.FATypes.Node");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfProduction", 
			"DateOfProduction", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ManufaturerNumber", 
			"ManufaturerNumber", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Manufacturer_", 
			"Manufacturer_", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Class", 
			"Class", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Model", 
			"Model", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PassportNumber", 
			"PassportNumber", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RMBusinessUnit", 
			"RMBusinessUnit", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SerialNumber", 
			"SerialNumber", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PayrollExpensesPostingMethod", 
			"PayrollExpensesPostingMethod", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItem", 
			"ExpenseItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.OSType <> PredefinedValue("Enum.FATypes.GroupFA");

		TMCommonUseClientServer.AddItemDetailsParameters(
			"AssetID", 
			"AssetID", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			And AuxiliaryAttributes.UseAccountingOfPreciousMaterial;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"PreciousMetalsAndStones", 
			"PreciousMetalsAndStones", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);		
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ClassificationDM4", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);		
		
		//
		PropertyValue = 
			(Object.OSType = PredefinedValue("Enum.FATypes.Asset")
				Or Object.OSType = PredefinedValue("Enum.FATypes.Node"))
			And AuxiliaryAttributes.UseRMManagement;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"Status", 
			"Status", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);		
		
		//
		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			And AuxiliaryAttributes.UseRMManagement
			And AuxiliaryAttributes.UseProduction;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"WorkCenters", 
			"WorkCenters", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Class")
		Or StructureOfChangedProps.Property("OSType")
		Or UpdateAll Then

		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			And AuxiliaryAttributes.UseOfSubclasses;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"Subclass", 
			"Subclass", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - CatalogObject.WaysToReflectExpenses - 
// 	ChangedBankingDetails - String - 
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentAttributes_WaysToReflectExpenses(Object, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"Department", 
			"Department", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusiness", 
			"LineOfBusiness", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.IntangibleAssetImprovement - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentAttributes_IAImprovement(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;

	IAImprovementParameters = IAImprovementParameters(Object, AuxiliaryAttributes);

	#Region NMAPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.PostInAccounting
			And (IAImprovementParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or Not AuxiliaryAttributes.ThereIsCostAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostInAccounting", 
			"IACostInAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue = 
			Object.RecordInManAccounting
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
					And IAImprovementParameters.CostIsRequiredToCalculateDepreciationOfMA
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch
					And IAImprovementParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or Not AuxiliaryAttributes.ThereIsCostAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostInManagementAccounting", 
			"IACostInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
			
	#EndRegion

	NonCurrentAssetsClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_IAImprovement(
		Object, AuxiliaryAttributes, IAImprovementParameters, StructureOfChangedProps, ItemDetailsParameters);
			
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.FixedAssetsPhysicalCount - 
// 	ChangedBankingDetails - String - 
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function ValuesOfPropertiesOfDependentAttributes_FixedAssetPhysicalInventory(Object, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsPhysicalCount");
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FINANCIALLYLIABLEPERSON", 
			"FINANCIALLYLIABLEPERSON", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.FINANCIALLYLIABLEPERSON", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.LAAction", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.TAAction", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.MAAction", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAActionPresentation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("FINANCIALLYLIABLEPERSON")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsPhysicalCount")
			And Not ValueIsFilled(Object.FinanciallyLiablePerson);
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAFINANCIALLYLIABLEPERSON", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInTA")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostByAccountingDataMA", 
			"FACostByAccountingDataMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostActualMan", 
			"FACostActualMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostIsActualMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostAccordingToMAAccountingData", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.PostInAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostByAccountingDataLA", 
			"FACostByAccountingDataLA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ActualCostAC", 
			"FAActualCostAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostIsActualAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResultIsCostAccordingToACAccountingData", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.RecordInTA;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.CostByAccountingDataTA", 
			"FACostByAccountingDataTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ActualCostTA", 
			"FAActualCostTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineActualCostIsTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostAccordingToAccountingDataIsTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	Return ItemDetailsParameters;

EndFunction

// 
// Parameters:
// 	Object - DocumentObject.IntangibleAssetsPhysicalCount - 
// 	ChangedBankingDetails - String - 
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function ValuesOfPropertiesOfDependentDetailsOf_NMAIntangibleSAssetPhysicalInventory(Object, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
		
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInTA")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.RecordInManAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostByAccountingDataMA", 
			"IACostByAccountingDataMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostActualMan", 
			"IACostActualMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostIsActualMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostAccordingToMAAccountingData", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.PostInAccounting;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostByAccountingDataLA", 
			"IACostByAccountingDataLA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.ActualCostAC", 
			"IAActualCostAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostIsActualAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResultIsCostAccordingToACAccountingData", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.RecordInTA;
										
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.CostByAccountingDataTA", 
			"IACostByAccountingDataTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IA.ActualCostTA", 
			"IAActualCostTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineActualCostIsTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"BottomLineCostAccordingToAccountingDataIsTA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	Return ItemDetailsParameters;

EndFunction

#EndRegion

#Region Taxes

Function MinimumRegistrationDate(Object) Export

	RegistrationDate = '000101010000';
	
	For Each RowData In Object.FA Do
		If RowData.RegistrationDate = '000101010000' Then
			RegistrationDate = ?(RegistrationDate <> '000101010000', Min(Object.Date, RegistrationDate), Object.Date);
		Else
			RegistrationDate = ?(RegistrationDate <> '000101010000', Min(RowData.RegistrationDate, RegistrationDate), RowData.RegistrationDate);
		EndIf;
	EndDo; 
	
	If RegistrationDate = '000101010000' Then
		RegistrationDate = Object.Date;
	EndIf; 

	Return RegistrationDate;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ActionsPerformedWhenChangingBankingDetails

Procedure WhenChangingBankingDetails_AcceptanceForAccountingByFA(Object, AuxiliaryAttributes, ChangedBankingDetails) Export

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	// IMPORTANT: Order matters!
	
	If AttributesList.Find("Organization") <> Undefined Then
		If Not AuxiliaryAttributes.FALocalAccountingIsConductedIndependently Then
			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			AttributesList.Add("RecordInLocalAccounting");
			AttributesList.Add("RecordInManAccounting");
		EndIf;
	EndIf;
	
	If AttributesList.Find("BusinessOperation") <> Undefined
		Or AttributesList.Find("DimensionKindExpenseCapitalization") <> Undefined Then
	
		If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognition")
			Or Object.DimensionKindExpenseCapitalization <> PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject") Then
			Object.PartialCommissioning = False;
			AttributesList.Add("PartialCommissioning");
		EndIf;
		
	EndIf;
	
	If AttributesList.Find("BusinessOperation") <> Undefined Then
		
		If Object.PartialCommissioning
			And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems")) Then
			Object.PartialCommissioning = False;
			AttributesList.Add("PartialCommissioning");
		EndIf;
		
		If Object.DimensionKindExpenseCapitalization = PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject")
			And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems")) Then
			Object.DimensionKindExpenseCapitalization = PredefinedValue("Enum.KindsOfExpenseCapitalizationDimension.FixedAssets");
			AttributesList.Add("DimensionKindExpenseCapitalization");
		EndIf;
		
	EndIf;
	
	If AttributesList.Find("RecordInLocalAccounting") <> Undefined
		And AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
		
		Object.DepreciationAccrualAccounting = 
			Object.PostInAccounting
			And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
		
		AttributesList.Add("DepreciationAccrualAccounting");
	EndIf;
	
	If AttributesList.Find("RecordInManAccounting") <> Undefined Then
		Object.DepreciationAccrualManagementAccounting = Object.RecordInManAccounting;
		AttributesList.Add("DepreciationAccrualManagementAccounting");
	EndIf;
	
	If AttributesList.Find("RecordInLocalAccounting") <> Undefined And Not Object.RecordInLocalAccounting
		Or AttributesList.Find("RecordInManAccounting") <> Undefined And Not Object.RecordInManAccounting Then
		
		For Each TableRow In Object.FA Do
			If Not Object.RecordInLocalAccounting Then
				TableRow.CostInAccounting = 0;
				TableRow.CostInTaxAccounting = 0;
				TableRow.CostPermanentDifference = 0;
			EndIf; 
			If Not Object.RecordInManAccounting Then
				TableRow.CostInManagementAccounting = 0;
				TableRow.ResidualValueMan = 0;
			EndIf; 
		EndDo; 
	EndIf; 
	
	FixedAssetsInitialRecognitionClientServerLocalization.OnChangeAttributes(Object, AuxiliaryAttributes, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

Procedure WhenChangingDetails_AcceptanceOfDepreciationComponentsForAccountingUnits(Object, AuxiliaryAttributes, ChangedBankingDetails) Export

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	// IMPORTANT: Order matters!
	
	If AttributesList.Find("RecordInLocalAccounting") <> Undefined
		And AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
		
		Object.DepreciationAccrualAccounting = Object.RecordInLocalAccounting;
		AttributesList.Add("DepreciationAccrualAccounting");
	EndIf;
	
	If AttributesList.Find("RecordInManAccounting") <> Undefined Then
		Object.DepreciationAccrualManagementAccounting = Object.RecordInManAccounting;
		AttributesList.Add("DepreciationAccrualManagementAccounting");
	EndIf;
	
	If AttributesList.Find("RecordInLocalAccounting") <> Undefined And Not Object.RecordInLocalAccounting
		Or AttributesList.Find("RecordInManAccounting") <> Undefined And Not Object.RecordInManAccounting Then
		
		For Each TableRow In Object.DepreciationComponents Do
			If Not Object.RecordInLocalAccounting Then
				TableRow.CostInAccounting = 0;
			EndIf; 
			If Not Object.RecordInManAccounting Then
				TableRow.CostInManagementAccounting = 0;
				TableRow.ResidualValueMan = 0;
			EndIf; 
		EndDo; 
	EndIf; 
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

Procedure WhenChangingBankingDetails_UpgradeFA(Object, AuxiliaryAttributes, ChangedBankingDetails) Export

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	NonCurrentAssetsClientServerLocalization.WhenChangingBankingDetails_UpgradeFA(Object, AuxiliaryAttributes, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

Procedure OnChangeOfBankingDetails_AttributionOfDeviationsToCostOfFA(Object, AuxiliaryAttributes, ChangedBankingDetails) Export

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	NonCurrentAssetsClientServerLocalization.OnChangeOfBankingDetails_AttributionOfDeviationsToCostOfFA(Object, AuxiliaryAttributes, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

Procedure WhenChangingBankingDetails_MergeFA(Object, AuxiliaryAttributes, ChangedBankingDetails) Export

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	// IMPORTANT: Order matters!
	
	If AttributesList.Find("BusinessOperation") <> Undefined Then
	
		If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset") Then
			Object.MergeOfSimilarFixedAssets = True;
			AttributesList.Add("MergeOfSimilarFixedAssets");
		EndIf;
		
	EndIf;
	
	If AttributesList.Find("RecordInLocalAccounting") <> Undefined
		And AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
		
		Object.DepreciationAccrualAccounting = Object.RecordInLocalAccounting;
		Object.DepreciationAccrualTaxAccounting = Object.RecordInLocalAccounting;
		AttributesList.Add("DepreciationAccrualAccounting");
		AttributesList.Add("DepreciationAccrualTaxAccounting");
	EndIf;
	
	If AttributesList.Find("RecordInManAccounting") <> Undefined Then
		Object.DepreciationAccrualManagementAccounting = Object.RecordInManAccounting;
		AttributesList.Add("DepreciationAccrualManagementAccounting");
	EndIf;
	
	MergeOfFixedAssetsClientServerLocalization.OnChangeAttributes(Object, AuxiliaryAttributes, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

Procedure WhenChangingDetails_AdjustmentOfCostAndDepreciationOfFA(Form, AuxiliaryAttributes, ChangedBankingDetails) Export

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf;
	
	Object = Form.Object;

	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	If AttributesList.Find("RecordInLocalAccounting") <> Undefined
		Or AttributesList.Find("RecordInManAccounting") <> Undefined
		Or AttributesList.Find("FixedAssetKind") <> Undefined Then
	
		If Object.RecordInLocalAccounting
			And Not Object.RecordInManAccounting Then
			
			Form.CurrentParameters = "ACC";
			AttributesList.Add("CurrentParameters");
			
		ElsIf Object.RecordInManAccounting
			And Not Object.RecordInLocalAccounting Then
				
			Form.CurrentParameters = "MA";
			AttributesList.Add("CurrentParameters");
			
		EndIf;
		
	EndIf;
	
	FixedAssetCostAndDepreciationAdjustmentClientServerLocalization.OnChangeAttributes(Form, AuxiliaryAttributes, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure
 
Function FillInDetailsDependingOnProperties_EnterBalances(Object, ItemDetailsParameters) Export

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		Action = ClearOrFill(Object, AttributeParameters);
		
		If Not ValueIsFilled(Action) Then
			Continue;
		EndIf;
		
		#Region DepreciationPage
		
		If AttributeParameters.AttributeName = "DepreciationAccrualAccounting"
			Or AttributeParameters.AttributeName = "DepreciationAccrualTaxAccounting"
			Or AttributeParameters.AttributeName = "DepreciationAccrualManagementAccounting" Then
				Object[AttributeParameters.AttributeName] = ?(Action = "Fill", True, False);
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationSchedule" Then
			If Action = "Clear" Then
				Object[AttributeParameters.AttributeName] = Undefined;
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf; 
		EndIf;
		
		If AttributeParameters.AttributeName = "ToIncludeDepreciationAllowanceInExpenses" Then
			If Action = "Clear" Then
				Object.ToIncludeDepreciationAllowanceInExpenses = False;
				Object.AmountOfBonusDepreciationTaxAccounting = 0;
				ChangedBankingDetails.Add("ToIncludeDepreciationAllowanceInExpenses");
				ChangedBankingDetails.Add("AmountOfBonusDepreciationTaxAccounting");
			EndIf; 
		EndIf;
		
		#EndRegion
		
		#Region CostPage
		If Action = "Clear" 
			And (AttributeParameters.AttributeName = "CurrentcCostFinAcc"
				Or AttributeParameters.AttributeName = "CurrentCostTaxAccounting"
				Or AttributeParameters.AttributeName = "CurrentcCostPD"
				Or AttributeParameters.AttributeName = "CurrentCostTD"
				Or AttributeParameters.AttributeName = "CurrentcCostManAcc"
			
				Or AttributeParameters.AttributeName = "CurrentCostAccountingTargetFinancing"
				Or AttributeParameters.AttributeName = "CurrentCostTaxAccountingTargetFinancing"
				Or AttributeParameters.AttributeName = "CurrentCostTargetFinancingPD"
				Or AttributeParameters.AttributeName = "CurrentValueOfTheGRCF"
				
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationAccounting"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationTaxAccounting"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationTD"
				Or AttributeParameters.AttributeName = "PermanentDifferenceInEvaluationOfAccumulatedDepreciation"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationManagementAccounting"
				
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationAccountingTargetFinancing"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationTaxAccountingTargetFinancing"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationTargetFinancingPD"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationTDSPF") Then

			Object[AttributeParameters.AttributeName] = 0;
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);

		EndIf;
		
		#EndRegion
		
		#Region PageExpenseRecord
		
		If AttributeParameters.AttributeName = "ExpenseItemAccounting" Then
			If Action = "Clear" Then
				Object.ExpenseItemAccounting = Undefined;
				Object.ExpensesDimensionAccounting = Undefined;
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "ExpenseItemManagementAccounting" Then
			If Action = "Clear" Then
				Object.ExpenseItemManagementAccounting = Undefined;
				Object.ExpensesDimensionManagementAccounting = Undefined;
				ChangedBankingDetails.Add("ExpenseItemManagementAccounting");
				ChangedBankingDetails.Add("ExpensesDimensionManagementAccounting");
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "ExpenseItemForTax" Then
			If Action = "Clear" Then
				Object.ExpenseItemForTax = Undefined;
				Object.ExpensesDimensionTax = Undefined;
				ChangedBankingDetails.Add("ExpenseItemForTax");
				ChangedBankingDetails.Add("ExpensesDimensionTax");
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "IncomeItem" Then
			If Action = "Clear" Then
				Object.IncomeItem = Undefined;
				Object.DimensionOfRevenue = Undefined;
				ChangedBankingDetails.Add("IncomeItem");
				ChangedBankingDetails.Add("DimensionOfRevenue");
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "ExpenseItemOfDepreciationAllowance" Then
			If Action = "Clear" Then
				Object.ExpenseItemOfDepreciationAllowance = Undefined;
				Object.DepreciationAllowanceExpensesDimension = Undefined;
				ChangedBankingDetails.Add("ExpenseItemOfDepreciationAllowance");
				ChangedBankingDetails.Add("DepreciationAllowanceExpensesDimension");
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "TransferExpensesToAnotherCompany" Then
			If Action = "Clear" Then
				Object.TransferExpensesToAnotherCompany = False;
				Object.CompanyRecipientOfExpenses = Undefined;
				ChangedBankingDetails.Add("TransferExpensesToAnotherCompany");
				ChangedBankingDetails.Add("CompanyRecipientOfExpenses");
			EndIf;
		EndIf;
		
		#EndRegion
		
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

Function ClearOrFill(Object, AttributeParameters) Export

	If Not ValueIsFilled(AttributeParameters.AttributeName) Then
		Return "";
	EndIf;
	
	ThisIsBoolean = TypeOf(Object[AttributeParameters.AttributeName]) = Type("Boolean");
	
	Action = "";
	
	If ((AttributeParameters.Property = "Visible" Or AttributeParameters.Property = "ItemVisibility") And AttributeParameters.Value = False
			Or (AttributeParameters.Property = "ReadOnly" Or AttributeParameters.Property = "OnlyViewWithoutBlankMark")
					And AttributeParameters.Value = True)
		And (Not ThisIsBoolean And ValueIsFilled(Object[AttributeParameters.AttributeName]) 
			Or ThisIsBoolean And Object[AttributeParameters.AttributeName] = True) Then
		
		Action = "Clear";
	ElsIf ((AttributeParameters.Property = "Visible" Or AttributeParameters.Property = "ItemVisibility") And AttributeParameters.Value = True
				Or (AttributeParameters.Property = "ReadOnly" Or AttributeParameters.Property = "OnlyViewWithoutBlankMark")
						And AttributeParameters.Value = False)
			And (Not ThisIsBoolean And Not ValueIsFilled(Object[AttributeParameters.AttributeName])
				Or ThisIsBoolean And Object[AttributeParameters.AttributeName] = False) Then
			
		Action = "Fill";
	EndIf;

	Return Action;
	
EndFunction

Function WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters = Undefined, ThereIsAccountingProcedureWELL = True) Export

	ChangedBankingDetails = "AccountingProcedureAC";
	
	If Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual") Then
		
		If Not ValueIsFilled(Object.DepreciationMethodAccounting) Then
			Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear");
			ChangedBankingDetails = ChangedBankingDetails + ",DepreciationMethodAccounting";
		EndIf;
		 
	EndIf; 
	
	If Object.AccountingProcedureAC <> PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued") 
		And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued") Then
			
		Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
		ChangedBankingDetails = ChangedBankingDetails + ",AccountingProcedureMA";
	
	ElsIf Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued") 
		And Object.AccountingProcedureMA <> PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued") Then
			
		Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued");
		ChangedBankingDetails = ChangedBankingDetails + ",AccountingProcedureMA";
	EndIf;
	
	ChangedBankingDetails = 
		ChangedBankingDetails
		+ NonCurrentAssetsClientServerLocalization.WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters, ThereIsAccountingProcedureWELL);
	
	Return ChangedBankingDetails;
	
EndFunction

Function WhenChangingOrderOfAccountingUU_OS(Object, FormServiceParameters = Undefined, ThereIsAccountingProcedureWELL = True) Export

	ChangedBankingDetails = "";
	
	If Object.AccountingProcedureMA <> PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued") 
		And Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued") Then
			
		Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual");
		ChangedBankingDetails = WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters, ThereIsAccountingProcedureWELL) + "," + ChangedBankingDetails;
		
	ElsIf Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued") 
		And Object.AccountingProcedureAC <> PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued") Then
			
		Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued");
		ChangedBankingDetails = WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters, ThereIsAccountingProcedureWELL) + "," + ChangedBankingDetails;
		
	EndIf;
	
	Return ChangedBankingDetails;
	
EndFunction
 
Function WhenChangingAccountingProcedureBU_NMA(Object, FormServiceParameters = Undefined, ThereIsAccountingProcedureWELL = True) Export

	ChangedBankingDetails = "AccountingProcedureAC";
	
	If Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization") Then
		
		If Not ValueIsFilled(Object.DepreciationMethodAccounting) Then
			Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear");
			ChangedBankingDetails = ChangedBankingDetails + ",DepreciationMethodAccounting";
		EndIf;
		 
	EndIf; 
	
	Return ChangedBankingDetails;
	
EndFunction

Function WhenChangingOrderOfAccountingUU_NMA(Object, FormServiceParameters = Undefined, ThereIsAccountingProcedureWELL = True) Export

	ChangedBankingDetails = "AccountingProcedureMA";
	
	If Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization") Then
		
		If Not ValueIsFilled(Object.DepreciationMethodAccounting) Then
			Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear");
			ChangedBankingDetails = ChangedBankingDetails + ",DepreciationAccrualMethodManagementAccounting";
		EndIf;
		 
	EndIf; 
	
	Return ChangedBankingDetails;
	
EndFunction

#EndRegion

#Region DefiningPropertiesOfDependentPropsOfObject

Function PropertyValuesOfDependentProps_EnteringBalances__(Object, AuxiliaryAttributes, ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ParametersForEnteringFABalances = ParametersForEnteringFABalances(Object, AuxiliaryAttributes);
	
	AccordingToMaOperatingTime = (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction"));
	
	TypesOfContractsUnderFSB25 = LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts();
	TransferredToFinLease = (TypesOfContractsUnderFSB25.Find(AuxiliaryAttributes.TypeOfTransferContractForLease) <> Undefined);
	
	ACCostIsAvailable = (Object.AccountingProcedureAC <> PredefinedValue("Enum.FARepaymentProcedure.IncludingInExpensesOnRecognition"));

	ItSLease =	
		AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets")
		Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut");
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") Then
		StructureOfChangedProps.Insert("AccountingParametersAvailable");
	EndIf;
	
	#Region AccountingParameters
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("LeaseholderIntercompanyARAP")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			(AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty")
				Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut"))
			And AuxiliaryAttributes.LeaseholderIntercompanyARAP
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseholderBusinessUnit", 
			"LeaseholderBusinessUnit", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseholderEmployeeInCharge", 
			"LeaseholderEmployeeInCharge", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("LeaseholderIntercompanyARAP")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = (AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty")
								Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut"))
							And (AuxiliaryAttributes.LeaseholderIntercompanyARAP
								Or AuxiliaryAttributes.Date < AuxiliaryAttributes.AccountingStartDate);
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SecurityDepositValue", 
			"SecurityDepositValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = (AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty")
								Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut"))
							And AuxiliaryAttributes.LeaseholderIntercompanyARAP
							And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SecurityDepositValue", 
			"SecurityDepositValue", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		// To support data migration
		PropertyValue = 
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings <> Undefined
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings.SeparateFAAccountingByVATTaxation;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateVATAccountingOption", 
			"", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings <> Undefined
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings.SeparateFAAccountingByVATTaxation;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateVATAccountingOption", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf; 
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognitionAccounting", 
			"DateOfRecognitionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognitionManagementAccounting", 
			"DateOfRecognitionManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue =
			ParametersForEnteringFABalances.AccountingParametersAvailable 
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FINANCIALLYLIABLEPERSON", 
			"FINANCIALLYLIABLEPERSON", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LocationAddress", 
			"LocationAddress", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If UpdateAll Then
		
		If Not AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
			
			TMCommonUseClientServer.AddItemDetailsParameters(
				"LineOfBusiness", 
				"LineOfBusiness", 
				"AutoMarkIncomplete", 
				False, 
				ItemDetailsParameters);
				
		EndIf; 
		
	EndIf;
		
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue =
			ItSLease
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Contract", 
			"Contract", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
			
		PropertyValue = 
			AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty")
				Or AuxiliaryAttributes.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut");
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Department", 
			"Department", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region Cost
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or StructureOfChangedProps.Property("RentalContract")
		Or StructureOfChangedProps.Property("ApplicationOfTargetFinancing")
		Or UpdateAll Then
			
		PropertyValue =
			(TransferredToFinLease Or Not ACCostIsAvailable)
			And (AuxiliaryAttributes.PostInAccounting
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostFinAcc", 
			"CurrentcCostFinAcc", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationAccounting", 
			"AccumulatedDepreciationAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue =
			TransferredToFinLease
			And AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationManagementAccounting", 
			"AccumulatedDepreciationManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostFinAcc", 
			"CurrentcCostFinAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ParametersForEnteringFABalances.AccountingParametersAvailable
			And (AuxiliaryAttributes.PostInAccounting
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.RecordInManAccounting
			And Not TransferredToFinLease
			And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationManagementAccounting", 
			"AccumulatedDepreciationManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.PostInAccounting;
						
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationAccounting", 
			"AccumulatedDepreciationAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostIsDifferent", 
			"InitialCostIsDifferent", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or UpdateAll Then
		
		PropertyValue = Not Object.InitialCostIsDifferent;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"OnlyViewWithoutBlankMarkWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"OnlyViewWithoutBlankMarkWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.InitialCostIsDifferent
			And AuxiliaryAttributes.RecordInManAccounting 
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region Events
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And Not TransferredToFinLease;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsChangesOfDepreciationParametersAccounting", 
			"ThereIsChangesOfDepreciationParametersAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfDepreciationParametersChangeAccounting", 
			"DateOfDepreciationParametersChangeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("ThereIsChangesOfDepreciationParametersAccounting")
		Or UpdateAll Then
		
		PropertyValue = Not Object.ThereIsChangesOfDepreciationParametersAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfDepreciationParametersChangeAccounting", 
			"DateOfDepreciationParametersChangeAccounting", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And Not TransferredToFinLease;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"HasChangesInDepreciationParametersManagementAccounting", 
			"HasChangesInDepreciationParametersManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfDepreciationParametersChangeManagementAccounting", 
			"DateOfDepreciationParametersChangeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("HasChangesInDepreciationParametersManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			Object.HasChangesInDepreciationParametersManagementAccounting 
			And AuxiliaryAttributes.RecordInManAccounting
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards")
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostUsedToCalculateDepreciationInManagementAccounting", 
			"CostUsedToCalculateDepreciationInManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("HasChangesInDepreciationParametersManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue = Not Object.HasChangesInDepreciationParametersManagementAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfDepreciationParametersChangeManagementAccounting", 
			"DateOfDepreciationParametersChangeManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Not TransferredToFinLease;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsRevaluationReserveLocal", 
			"ThereIsRevaluationReserveLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationRevaluationReserveLocal", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostRevaluationReserveLocal", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			Not TransferredToFinLease
			And (AuxiliaryAttributes.RecordInManAccounting
					And ParametersForEnteringFABalances.AccountingParametersAvailable
				Or Not ParametersForEnteringFABalances.AccountingParametersAvailable
					And AuxiliaryAttributes.RecordInMA);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsRevaluationReserve", 
			"ThereIsRevaluationReserve", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RevaluationReserveSign", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationRevaluationReserve", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostRevaluationReserve", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And (AuxiliaryAttributes.Date < AuxiliaryAttributes.AccountingStartDate);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CommissioningDocumentMA", 
			"CommissioningDocumentMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ThereIsChangesOfDepreciationParametersAccounting")
		Or StructureOfChangedProps.Property("HasChangesInDepreciationParametersManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.ThereIsChangesOfDepreciationParametersAccounting
			And Not Object.HasChangesInDepreciationParametersManagementAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EventModernization", 
			"EventModernization", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"EventRecognition", 
			"EventRecognition", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EventModernization", 
			"EventModernization", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region DepreciationInAccounting
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("ThereIsChangesOfDepreciationParametersAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AccountingParametersAvailable
			And (ParametersForEnteringFABalances.ACDepreciationParametersAreAvailable 
				Or ParametersForEnteringFABalances.DepreciationAccrualIsValid);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("ThereIsChangesOfDepreciationParametersAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.ThereIsChangesOfDepreciationParametersAccounting 
			And Not ParametersForEnteringFABalances.ByAssetActivity
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualUsefulLifeAccounting", 
			"ResidualUsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.ThereIsChangesOfDepreciationParametersAccounting 
			And ParametersForEnteringFABalances.ByAssetActivity
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualEstimatedRunningTimeAccounting", 
			"ResidualEstimatedRunningTimeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			Object.ThereIsChangesOfDepreciationParametersAccounting 
			And ParametersForEnteringFABalances.ByAssetActivity
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualEstimatedRunningTimeAccounting", 
			"ResidualEstimatedRunningTimeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.ACDepreciationParametersAreAvailable
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue =
			Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
			And ParametersForEnteringFABalances.ACDepreciationParametersAreAvailable
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue =
		 	AuxiliaryAttributes.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.BySumOfUsefulLifeYearNumbers"))
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region DepreciationManagementAccounting
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("HasChangesInDepreciationParametersManagementAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters 
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And Object.HasChangesInDepreciationParametersManagementAccounting 
			And Not AccordingToMaOperatingTime;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualUsefulLifeManagementAccounting", 
			"ResidualUsefulLifeManagementAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters 
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And Object.HasChangesInDepreciationParametersManagementAccounting 
			And AccordingToMaOperatingTime
			And AuxiliaryAttributes.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualEstimatedRunningTimeManagementAccounting", 
			"ResidualEstimatedRunningTimeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
					Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance");
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	#EndRegion
	
	#Region DepreciationGeneral
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.ByAssetActivity
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValue", 
			"RunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region RecordExpenses
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AccountingParametersAvailable
			And ParametersForEnteringFABalances.AvailableReflectionOfBUExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableReflectionOfBUExpenses
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableReflectionOfMaExpenses
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_
			And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableReflectionOfMaExpenses
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting")
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		PropertyName = ?( 
			Not PropertyValue
			And Not(ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_
				And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
				And ParametersForEnteringFABalances.AccountingParametersAvailable),
			"ReadOnly",
			"OnlyViewWithoutBlankMark");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			PropertyName, 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.ThereAreRelatedCompanies 
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And (ParametersForEnteringFABalances.AvailableReflectionOfBUExpenses
					Or ParametersForEnteringFABalances.ExpenseReflectionIsAvailable
					Or ParametersForEnteringFABalances.AvailableReflectionOfMaExpenses);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"TransferExpensesToAnotherCompany", 
			"TransferExpensesToAnotherCompany", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("TransferExpensesToAnotherCompany") 
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses",
			"CompanyRecipientOfExpenses", 
			"OnlyViewWithoutBlankMark", 
			Not Object.TransferExpensesToAnotherCompany,
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.PaddingPropertyValuesOfDependentProps_EnteringResidues__(
		Object, AuxiliaryAttributes, ParametersForEnteringFABalances, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

Function PropertyValuesOfDependentProps_EnteringResidues_NMA(Object, AuxiliaryAttributes, ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ParametersForEnteringIAResidues = ParametersForEnteringIAResidues(Object, AuxiliaryAttributes);
	ParametersForEnteringIAResidues.Insert("AccountingParametersAvailable", AuxiliaryAttributes.RecordInOperationalAccounting);
	
	MaDepreciationIsAvailable = 
		AuxiliaryAttributes.RecordInManAccounting
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
			
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") Then
		StructureOfChangedProps.Insert("AccountingParametersAvailable");
	EndIf;

	#Region AccountingParametersOfBU
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognitionAccounting", 
			"DateOfRecognitionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
	EndIf;
	
	#EndRegion
				
	#Region UUAccountingParameters
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognitionManagementAccounting", 
			"DateOfRecognitionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
	EndIf;

	#EndRegion

	#Region GeneralAccountingParameters
	
	If UpdateAll Then
		
		If Not AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
			
			TMCommonUseClientServer.AddItemDetailsParameters(
				"LineOfBusiness", 
				"LineOfBusiness", 
				"AutoMarkIncomplete", 
				False, 
				ItemDetailsParameters);
				
		EndIf; 
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringIAResidues.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PurchaseDate", 
			"PurchaseDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = ParametersForEnteringIAResidues.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueLocal", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue =
			ParametersForEnteringIAResidues.AccountingParametersAvailable 
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualValueMan", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		// To support data migration
		PropertyValue = 
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings <> Undefined
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings.SeparateFAAccountingByVATTaxation;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateVATAccountingOption", 
			"", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			AuxiliaryAttributes.RecordInLocalAccounting
			And AuxiliaryAttributes.ComplianceCAAccountingIsKept
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings <> Undefined
			And AuxiliaryAttributes.AccountingPolicySettingsVATAccountingSettings.SeparateFAAccountingByVATTaxation;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateVATAccountingOption", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf; 
	
	#EndRegion
										
	#Region Cost
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.PostInAccounting
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostFinAcc", 
			"CurrentcCostFinAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			ParametersForEnteringIAResidues.AccountingParametersAvailable
			And (AuxiliaryAttributes.PostInAccounting
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("KindOfAccountingObject")
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept 
					And ParametersForEnteringIAResidues.ACDepreciationIsAvailable
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept 
					And MaDepreciationIsAvailable);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationAccounting", 
			"AccumulatedDepreciationAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		EndIf;
		
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("KindOfAccountingObject")
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			(Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
					And MaDepreciationIsAvailable
				Or Not ParametersForEnteringIAResidues.AccountingParametersAvailable
					And AuxiliaryAttributes.RecordInManAccounting)
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationManagementAccounting", 
			"AccumulatedDepreciationManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"OnlyViewWithoutBlankMark", 
			Not Object.InitialCostIsDifferent, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"OnlyViewWithoutBlankMark", 
			Not Object.InitialCostIsDifferent, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostFinAcc", 
			"CurrentcCostFinAcc", 
			"AutoMarkIncomplete", 
			Not Object.InitialCostIsDifferent And Not Object.ApplicationOfTargetFinancing, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		PropertyValue =
			Not Object.InitialCostIsDifferent
			And AuxiliaryAttributes.RecordInManAccounting
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			Object.InitialCostIsDifferent
			And AuxiliaryAttributes.RecordInManAccounting
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringIAResidues.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostIsDifferent", 
			"InitialCostIsDifferent", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region ACEvents
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or StructureOfChangedProps.Property("KindOfAccountingObject")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting 
			And AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses");
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsAnIntangibleAssetImprovementAcc", 
			"ThereIsAnIntangibleAssetImprovementAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LastImprovementDateAcc", 
			"LastImprovementDateAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses");
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsRevaluationReserveLocal", 
			"ThereIsRevaluationReserveLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RevaluationReserveComplSign", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RevaluationReserveReglAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RevaluationReserveDepreciationReglAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationRevaluationReserveLocal", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostRevaluationReserveLocal", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ThereIsAnIntangibleAssetImprovementAcc")
		Or UpdateAll Then
		
		PropertyValue = Not Object.ThereIsAnIntangibleAssetImprovementAcc;
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LastImprovementDateAcc", 
			"LastImprovementDateAcc", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
	EndIf;

	#EndRegion
	
	#Region MAEvents
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
			And AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.RecordInManAccounting;
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsAnIntangibleAssetImprovementMan", 
			"ThereIsAnIntangibleAssetImprovementMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LastImprovementDateMan", 
			"LastImprovementDateMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue = 
			Object.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
			And AuxiliaryAttributes.RecordInManAccounting;
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsRevaluationReserve", 
			"ThereIsRevaluationReserve", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationRevaluationReserve", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostRevaluationReserve", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And (AuxiliaryAttributes.Date < AuxiliaryAttributes.AccountingStartDate);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DocumentOfRecognitionManagementAccounting", 
			"DocumentOfRecognitionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ThereIsAnIntangibleAssetImprovementMan")
		Or UpdateAll Then
		
		PropertyValue = Not Object.ThereIsAnIntangibleAssetImprovementMan;
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LastImprovementDateMan", 
			"LastImprovementDateMan", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region DepreciationInAccounting
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringIAResidues.ACDepreciationParametersAreAvailable
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("ThereIsAnIntangibleAssetImprovementAcc") 
		Or UpdateAll Then

		PropertyValue = 
			ParametersForEnteringIAResidues.ACDepreciationParametersAreAvailable
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And Object.ThereIsAnIntangibleAssetImprovementAcc;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualUsefulLifeAccounting", 
			"ResidualUsefulLifeAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			(Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting",
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance")
			And ParametersForEnteringIAResidues.ACDepreciationParametersAreAvailable
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualFactor", 
			"DepreciationAccrualFactor", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region DepreciationManagementAccounting
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringIAResidues.AvailableMaDepreciationParameters
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("ThereIsAnIntangibleAssetImprovementMan") 
		Or UpdateAll Then

		PropertyValue = 
			ParametersForEnteringIAResidues.ACDepreciationParametersAreAvailable
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And Object.ThereIsAnIntangibleAssetImprovementMan;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ResidualUsefulLifeManagementAccounting", 
			"ResidualUsefulLifeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringIAResidues.AvailableMaDepreciationParameters
							And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear")
								Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance")
			And ParametersForEnteringIAResidues.AvailableMaDepreciationParameters
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
	
	#Region DepreciationOther
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringIAResidues.ByAssetActivity
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	#EndRegion
	
	#Region RecordIncomeAndExpenses
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringIAResidues.AvailableReflectionOfBUExpenses
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		// To support data migration
		PropertyValue = 
			ParametersForEnteringIAResidues.AvailableReflectionOfBUExpenses
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
	
		PropertyValue = 
			ParametersForEnteringIAResidues.AvailableMaDepreciationParameters
			And ParametersForEnteringIAResidues.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting 
			And ParametersForEnteringIAResidues.ExpenseItemManagementAccountingRequired_;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			ParametersForEnteringIAResidues.AvailableReflectionOfMaExpenses
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And ParametersForEnteringIAResidues.ExpenseItemManagementAccountingRequired_;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting")
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		PropertyName = ?( 
			Not PropertyValue
			And Not(ParametersForEnteringIAResidues.ExpenseItemManagementAccountingRequired_
				And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
				And ParametersForEnteringIAResidues.AccountingParametersAvailable),
			"ReadOnly",
			"OnlyViewWithoutBlankMark");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			PropertyName, 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.ThereAreRelatedCompanies 
			And ParametersForEnteringIAResidues.AccountingParametersAvailable
			And (ParametersForEnteringIAResidues.AvailableReflectionOfBUExpenses 
				Or ParametersForEnteringIAResidues.ExpenseReflectionIsAvailable 
				Or ParametersForEnteringIAResidues.AvailableReflectionOfMaExpenses);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"TransferExpensesToAnotherCompany", 
			"TransferExpensesToAnotherCompany", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses", 
			"CompanyRecipientOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("TransferExpensesToAnotherCompany") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.ThereAreRelatedCompanies
			And Object.TransferExpensesToAnotherCompany
			And (ParametersForEnteringIAResidues.AvailableReflectionOfBUExpenses 
				Or ParametersForEnteringIAResidues.ExpenseReflectionIsAvailable 
				Or ParametersForEnteringIAResidues.AvailableReflectionOfMaExpenses);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipientOfExpenses",
			"CompanyRecipientOfExpenses", 
			"OnlyViewWithoutBlankMark", 
			Not PropertyValue, ItemDetailsParameters);
		
	EndIf;
		
	#EndRegion
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.SupplementValuesOfPropertiesOfDependentProps_EnterResidues_NM(
		Object, AuxiliaryAttributes, ParametersForEnteringIAResidues, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;

EndFunction

Function PropertyValuesOfDependentDetails_EnteringBalances_LeaseCalculations(Object, AuxiliaryAttributes, ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	AccountingOnBalanceSheet = 
		AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
		Or ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder")
		Or Not ValueIsFilled(Object.Contract);
	
	#Region PaymentBalancesPage
	
	#Region LeaseObligations
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
		
		PropertyValue = 
			AccountingOnBalanceSheet
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseObligationsBalance", 
			"LeaseObligationsBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseLiabilityBalanceLocal", 
			"LeaseLiabilityBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AccountingOnBalanceSheet
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseLiabilityBalanceMan", 
			"LeaseLiabilityBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region RentalServices
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or UpdateAll Then
	
		PropertyValue = 
			(AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RentalServiceBalance", 
			"RentalServiceBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RentalServiceBalanceLocal", 
			"RentalServiceBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			(AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RentalServiceBalanceMan", 
			"RentalServiceBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	#EndRegion
	
	#Region BuyoutValue
	
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
			
		PropertyValue = 
			AccountingOnBalanceSheet
			And ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutValueBalance", 
			"BuyoutValueBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutValueBalanceLocal", 
			"BuyoutValueBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AccountingOnBalanceSheet
			And ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutValueBalanceMan", 
			"BuyoutValueBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	#EndRegion

	#Region VAT
	
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then

		PropertyValue = 
			AccountingOnBalanceSheet
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATBalance", 
			"VATBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATBalanceLocal", 
			"VATBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AccountingOnBalanceSheet
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATBalanceMan", 
			"VATBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	#EndRegion
	
	#Region Interests
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
	
		PropertyValue = 
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestsBalance", 
			"InterestsBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestBalanceLocal", 
			"InterestBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestBalanceMan", 
			"InterestBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	#EndRegion
	
	#EndRegion
	
	#Region PagePaymentsUnderTheContract
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or UpdateAll Then
			
		PropertyValue = AuxiliaryAttributes.RecordInOperationalAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseServicesAmount", 
			"LeaseServicesAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATAmount", 
			"VATAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstPayment", 
			"DateOfFirstPayment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATRate", 
			"VATRate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PaymentFrequency", 
			"PaymentFrequency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccrualFrequency", 
			"AccrualFrequency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"AmountOfRentalServicesCurrency", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"AmountOfPersonalIncomeTax", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"RentalPeriod", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseStartDate", 
			"", 
			"MarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
			
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
			
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.ContractDetails_.HasSecurityDeposit;
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SecurityDepositAmount", 
			"SecurityDepositAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstSecurityPayment", 
			"DateOfFirstSecurityPayment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"SecurityPaymentAmountCurrency", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.ContractDetails_.ThereIsBuyoutOfLeasedAssets;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AmountOfLeaseAssetsByuout", 
			"AmountOfLeaseAssetsByuout", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutDate", 
			"BuyoutDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"PurchaseAmountOfRentalItemsCurrency", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("PaymentFrequency") 
		Or UpdateAll Then
			
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PaymentForLeaseService", 
			"PaymentForLeaseService", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"PaymentForRentalServicesCurrency", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("AccrualFrequency") 
		Or UpdateAll Then
			
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccrualOfLeaseService", 
			"AccrualOfLeaseService", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"AccrualOfRentalServicesCurrency", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or UpdateAll Then
			
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseServicesAmount", 
			"LeaseServicesAmount", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstPayment", 
			"DateOfFirstPayment", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATRate", 
			"VATRate", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServicePaymentSchedule", 
			"ServicePaymentSchedule", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ServiceAccrualSchedule", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestAmount", 
			"InterestAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"InterestAccrualSchedule", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseItemsCost", 
			"LeaseItemsCost", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestRate", 
			"InterestRate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
			
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.ContractDetails_.HasSecurityDeposit
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SecurityDepositAmount", 
			"SecurityDepositAmount", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstSecurityPayment", 
			"DateOfFirstSecurityPayment", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AmountOfLeaseAssetsByuout", 
			"AmountOfLeaseAssetsByuout", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutDate", 
			"BuyoutDate", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("PaymentFrequency") 
		Or UpdateAll Then
	
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PaymentForLeaseService", 
			"PaymentForLeaseService", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("AccrualOfLeaseService") 
		Or UpdateAll Then
	
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Object.AccrualOfLeaseService <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccrualOfLeaseService", 
			"AccrualOfLeaseService", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
		
	Return ItemDetailsParameters;
	
EndFunction

Function PropertyValuesOfDependentProps_OBEntry_NodesComponents(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ParametersForEnteringFABalances = ParametersForEnteringFABalances(Object, AuxiliaryAttributes);
	
	AccordingToMaOperatingTime = (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction"));
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting") Then
		StructureOfChangedProps.Insert("AccountingParametersAvailable");
	EndIf;
	
	#Region AccountingParameters
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognitionAccounting", 
			"DateOfRecognitionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureAC", 
			"AccountingProcedureAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccountingProcedureMA", 
			"AccountingProcedureMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfRecognitionManagementAccounting", 
			"DateOfRecognitionManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue =
			ParametersForEnteringFABalances.AccountingParametersAvailable 
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ResidualValueMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If UpdateAll Then
		
		If Not AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
			
			TMCommonUseClientServer.AddItemDetailsParameters(
				"LineOfBusiness", 
				"LineOfBusiness", 
				"AutoMarkIncomplete", 
				False, 
				ItemDetailsParameters);
				
		EndIf; 
		
	EndIf;
		
	#EndRegion
	
	#Region Cost
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.PostInAccounting
			Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostFinAcc", 
			"CurrentcCostFinAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ParametersForEnteringFABalances.AccountingParametersAvailable
			And (AuxiliaryAttributes.PostInAccounting
				Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CurrentcCostManAcc", 
			"CurrentcCostManAcc", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInManAccounting
			And (AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or Not AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationManagementAccounting", 
			"AccumulatedDepreciationManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.PostInAccounting;
						
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccumulatedDepreciationAccounting", 
			"AccumulatedDepreciationAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostIsDifferent", 
			"InitialCostIsDifferent", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or UpdateAll Then
		
		PropertyValue = Not Object.InitialCostIsDifferent;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"OnlyViewWithoutBlankMarkWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostLocalAccounting", 
			"InitialCostLocalAccounting", 
			"OnlyViewWithoutBlankMarkWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			Object.InitialCostIsDifferent
			And AuxiliaryAttributes.RecordInManAccounting 
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InitialCostMA", 
			"InitialCostMA", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region Events
	
	If StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = ParametersForEnteringFABalances.AccountingParametersAvailable;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"EventRecognition", 
			"EventRecognition", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region DepreciationInAccounting
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("ThereIsChangesOfDepreciationParametersAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AccountingParametersAvailable
			And (ParametersForEnteringFABalances.ACDepreciationParametersAreAvailable 
				Or ParametersForEnteringFABalances.DepreciationAccrualIsValid);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.ACDepreciationParametersAreAvailable
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualAccounting", 
			"DepreciationAccrualAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationMethodAccounting", 
			"DepreciationMethodAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue =
			Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
			And ParametersForEnteringFABalances.ACDepreciationParametersAreAvailable
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorAccounting", 
			"AccelerationFactorAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationMethodAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		PropertyValue =
		 	AuxiliaryAttributes.PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And (Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance")
				Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.BySumOfUsefulLifeYearNumbers"))
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeAccounting", 
			"UsefulLifeAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region DepreciationManagementAccounting
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And (Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear")
					Or Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance"));
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"UsefulLifeManagementAccounting", 
			"UsefulLifeManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualManagementAccounting", 
			"DepreciationAccrualManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMethodManagementAccounting", 
			"DepreciationAccrualMethodManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable")
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableMaDepreciationParameters
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance");
							
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccelerationFactorManagementAccounting", 
			"AccelerationFactorManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
											
	EndIf;
	
	#EndRegion
	
	#Region DepreciationGeneral
	
	If StructureOfChangedProps.Property("DepreciationMethodAccounting") 
		Or StructureOfChangedProps.Property("DepreciationAccrualMethodManagementAccounting") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.ByAssetActivity
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RunningTimeValue", 
			"RunningTimeValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"EstimatedRunningTime", 
			"EstimatedRunningTime", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region RecordExpenses
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AccountingParametersAvailable
			And ParametersForEnteringFABalances.AvailableReflectionOfBUExpenses;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableReflectionOfBUExpenses
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableReflectionOfMaExpenses
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("AccountingParametersAvailable") 
		Or UpdateAll Then
		
		PropertyValue = 
			ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_
			And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
			And ParametersForEnteringFABalances.AccountingParametersAvailable;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			ParametersForEnteringFABalances.AvailableReflectionOfMaExpenses
			And ParametersForEnteringFABalances.AccountingParametersAvailable
			And ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting")
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		PropertyName = ?( 
			Not PropertyValue
			And Not(ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_
				And (AuxiliaryAttributes.Date >= AuxiliaryAttributes.AccountingStartDate)
				And ParametersForEnteringFABalances.AccountingParametersAvailable),
			"ReadOnly",
			"OnlyViewWithoutBlankMark");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			PropertyName, 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.AddPropertyValuesForDependentProps_OBEntry_NodesComponents(
		Object, AuxiliaryAttributes, ParametersForEnteringFABalances, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

#EndRegion

#Region Inventory_

Procedure FillInAccountingDataInLineOfPhysicalInventoryCountOfFA(RowData, DataOfAccounting, PhysicalInventoryCountParameters, ThisIsReadingObject, FillInServiceDetails, VNAManagementIsUsed_2_4) Export

	If DataOfAccounting <> Undefined Then
		
		If Not ThisIsReadingObject Then
			
			If DataOfAccounting.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress") Then
				
				RowData.AvailabilityByAccountingData = True;
			
			ElsIf DataOfAccounting.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfCIPAssets") Then
				
				RowData.AvailabilityByAccountingData = True;
				
			Else
				
				RowData.AvailabilityByAccountingData = 
					ValueIsFilled(DataOfAccounting.OrganizationBasedOnAccountingData)
					And DataOfAccounting.OrganizationBasedOnAccountingData = PhysicalInventoryCountParameters.Organization
					And DataOfAccounting.AccountingDataDivision = PhysicalInventoryCountParameters.Department
					And (Not ValueIsFilled(PhysicalInventoryCountParameters.FinanciallyLiablePerson)
							And (DataOfAccounting.TheySAYAccordingToAccountingData = RowData.FinanciallyLiablePerson
								Or Not ValueIsFilled(RowData.FinanciallyLiablePerson))
						Or ValueIsFilled(PhysicalInventoryCountParameters.FinanciallyLiablePerson)
							And DataOfAccounting.TheySAYAccordingToAccountingData = PhysicalInventoryCountParameters.FinanciallyLiablePerson);
							
			EndIf; 
			
			If RowData.AvailabilityByAccountingData Then
				RowData.CostByAccountingDataLA = DataOfAccounting.CostByAccountingDataLA;
				RowData.CostByAccountingDataTA = DataOfAccounting.CostByAccountingDataTA;
				RowData.CostByAccountingDataMA = DataOfAccounting.CostByAccountingDataMA;
			Else
				RowData.CostByAccountingDataLA = 0;
				RowData.CostByAccountingDataTA = 0;
				RowData.CostByAccountingDataMA = 0;
			EndIf;
			
		EndIf; 
		
		If FillInServiceDetails Then
			RowData.OrganizationBasedOnAccountingData = DataOfAccounting.OrganizationBasedOnAccountingData;
			RowData.AccountingDataDivision = DataOfAccounting.AccountingDataDivision;
			RowData.TheySAYAccordingToAccountingData = DataOfAccounting.TheySAYAccordingToAccountingData;
			RowData.CompaniesAreInterconnected = DataOfAccounting.CompaniesAreInterconnected;
			RowData.Received_ForRent = DataOfAccounting.Received_ForRent;
			RowData.Contract = DataOfAccounting.Contract;
			RowData.AssetID = DataOfAccounting.AssetID;
			RowData.Code = DataOfAccounting.Code;
		EndIf; 
		
	Else
		
		If Not ThisIsReadingObject Then
			RowData.AvailabilityByAccountingData = False;
			RowData.CostByAccountingDataLA = 0;
			RowData.CostByAccountingDataTA = 0;
			RowData.CostByAccountingDataMA = 0;
		EndIf; 
		
		If FillInServiceDetails Then
			RowData.OrganizationBasedOnAccountingData = Undefined;
			RowData.AccountingDataDivision = Undefined;
			RowData.TheySAYAccordingToAccountingData = Undefined;
			RowData.CompaniesAreInterconnected = False;
			RowData.Received_ForRent = False;
			RowData.Contract = Undefined;
			RowData.AssetID = "";
			RowData.Code = "";
		EndIf; 
		
	EndIf; 
	
EndProcedure

Procedure FillInAccountingDataInLineOfInventoryOfIntangibleAssetPhysicalInventory(RowData, DataOfAccounting, PhysicalInventoryCountParameters) Export

	RowData.AvailabilityByAccountingData = False;

	If DataOfAccounting <> Undefined Then
		
		RowData.AvailabilityByAccountingData = 
			ValueIsFilled(DataOfAccounting.Organization)
			And DataOfAccounting.Organization = PhysicalInventoryCountParameters.Organization
			And DataOfAccounting.Department = PhysicalInventoryCountParameters.Department;
		
		If RowData.AvailabilityByAccountingData Then
			RowData.CostByAccountingDataLA = DataOfAccounting.CostByAccountingDataLA;
			RowData.CostByAccountingDataTA = DataOfAccounting.CostByAccountingDataTA;
			RowData.CostByAccountingDataMA = DataOfAccounting.CostByAccountingDataMA;
		EndIf;
			
	EndIf; 
	
	If Not RowData.AvailabilityByAccountingData Then
		RowData.CostByAccountingDataLA = 0;
		RowData.CostByAccountingDataTA = 0;
		RowData.CostByAccountingDataMA = 0;
	EndIf; 
	
EndProcedure

Procedure FillInActionBasedOnFixedAssetPhysicalInventory(RowData, Object, UsedInNA24) Export
	
	RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");
	RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");
	RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");

	If RowData.AvailabilityByAccountingData 
		And Not RowData.AvailabilityActual Then
		
		If RowData.Received_ForRent Then
			
			If TypeOf(RowData.Contract) = Type("CatalogRef.LeaseContract") Then
				
				If Object.PostInAccounting Then
					RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination");
				EndIf;
				
				If Object.RecordInTA Then
					RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination");
				EndIf;
				
				If Object.RecordInManAccounting Then
					RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination");
				EndIf;
				
			Else
				
				RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets");
				
			EndIf;
		
		Else
		
			If Object.PostInAccounting Then
				RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
			EndIf;
			
			If Object.RecordInTA Then
				RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
			EndIf;
			
			If Object.RecordInManAccounting Then
				RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
			EndIf;
			
		EndIf;
		
	ElsIf RowData.AvailabilityByAccountingData 
		And RowData.AvailabilityActual Then
			
		If RowData.CostByAccountingDataLA <> RowData.ActualCostAC
			And RowData.CostByAccountingDataLA <> 0
			And RowData.ActualCostAC <> 0
			And Not RowData.Received_ForRent Then
		
			RowData.LAAction = 
				?(UsedInNA24, 
				PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation"),
				PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff"));
		
		ElsIf RowData.ActualCostAC = 0
			And RowData.CostByAccountingDataLA <> 0
			And Object.PostInAccounting
			And (Object.RecordInTA Or Object.RecordInManAccounting)
			And Not RowData.Received_ForRent
			And UsedInNA24 Then
		
			RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.ActualCostAC <> 0
			And RowData.CostByAccountingDataLA = 0
			And RowData.OrganizationBasedOnAccountingData = Object.Organization
			And Object.PostInAccounting
			And UsedInNA24 Then
		
			RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
		
		EndIf;
		
		If RowData.CostByAccountingDataTA <> RowData.ActualCostTA
			And RowData.CostByAccountingDataTA <> 0
			And RowData.ActualCostTA <> 0
			And Not UsedInNA24
			And Not RowData.Received_ForRent Then
		
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.ActualCostTA = 0
			And RowData.CostByAccountingDataTA <> 0
			And Object.RecordInTA
			And (Object.PostInAccounting Or Object.RecordInManAccounting)
			And Not RowData.Received_ForRent
			And UsedInNA24 Then
		
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.ActualCostTA <> 0
			And RowData.CostByAccountingDataTA = 0
			And RowData.OrganizationBasedOnAccountingData = Object.Organization
			And Object.RecordInTA
			And UsedInNA24 Then
		
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
		
		EndIf;
		
		If RowData.CostByAccountingDataMA <> RowData.CostActualMan
			And RowData.CostByAccountingDataMA <> 0
			And RowData.CostActualMan <> 0
			And Not RowData.Received_ForRent Then
		
			RowData.MAAction = 
				?(UsedInNA24, 
				PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation"),
				PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff"));
		
		ElsIf RowData.CostActualMan = 0
			And RowData.CostByAccountingDataMA <> 0
			And Object.RecordInManAccounting
			And (Object.PostInAccounting Or Object.RecordInTA)
			And Not RowData.Received_ForRent
			And UsedInNA24 Then
		
			RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.CostActualMan <> 0
			And RowData.CostByAccountingDataMA = 0
			And RowData.OrganizationBasedOnAccountingData = Object.Organization
			And Object.RecordInManAccounting
			And UsedInNA24 Then
		
			RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
		
		EndIf;
		
	ElsIf Not RowData.AvailabilityByAccountingData
		And RowData.AvailabilityActual Then
		
		If Not ValueIsFilled(RowData.OrganizationBasedOnAccountingData) Then
			
			If Object.PostInAccounting Then
				RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
			EndIf;
			
			If Object.RecordInTA Then
				RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
			EndIf;
			
			If Object.RecordInManAccounting Then
				RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
			EndIf;
			
		Else
			
			If RowData.OrganizationBasedOnAccountingData <> Object.Organization
				Or RowData.AccountingDataDivision <> Object.Department
				Or Not ValueIsFilled(Object.FinanciallyLiablePerson)
					And RowData.TheySAYAccordingToAccountingData <> RowData.FinanciallyLiablePerson
					And ValueIsFilled(RowData.FinanciallyLiablePerson)
				Or ValueIsFilled(Object.FinanciallyLiablePerson)
					And RowData.TheySAYAccordingToAccountingData <> Object.FinanciallyLiablePerson Then
			
				If Object.PostInAccounting Then
					RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move");
				EndIf;
				
				If Object.RecordInTA <> 0 Then
					RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move");
				EndIf;
				
				If Object.RecordInManAccounting <> 0 Then
					RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move");
				EndIf;
			
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInActionBasedOnIntangibleAssetPhysicalInventory(RowData, Object, DataOfAccounting) Export
	
	RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");
	RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");
	RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.EmptyRef");

	If RowData.AvailabilityByAccountingData 
		And Not RowData.AvailabilityActual Then
		
		If Object.PostInAccounting Then
			RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		EndIf;
		
		If Object.RecordInTA Then
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		EndIf;
		
		If Object.RecordInManAccounting Then
			RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		EndIf;
		
	ElsIf RowData.AvailabilityByAccountingData 
		And RowData.AvailabilityActual Then
			
		If RowData.CostByAccountingDataLA <> RowData.ActualCostAC
			And RowData.CostByAccountingDataLA <> 0
			And RowData.ActualCostAC <> 0 Then
		
			RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation");
		
		ElsIf RowData.ActualCostAC = 0
			And RowData.CostByAccountingDataLA <> 0
			And Object.PostInAccounting
			And (Object.RecordInTA Or Object.RecordInManAccounting) Then
		
			RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.ActualCostAC <> 0
			And RowData.CostByAccountingDataLA = 0
			And DataOfAccounting <> Undefined
			And DataOfAccounting.Organization = Object.Organization
			And Object.PostInAccounting Then
		
			RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
		
		EndIf;
		
		If RowData.CostByAccountingDataTA <> RowData.ActualCostTA
			And RowData.CostByAccountingDataTA <> 0
			And RowData.ActualCostTA <> 0 Then
		
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.ActualCostTA = 0
			And Object.RecordInTA
			And (Object.PostInAccounting Or Object.RecordInManAccounting) Then
		
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.ActualCostTA <> 0
			And RowData.CostByAccountingDataTA = 0
			And DataOfAccounting <> Undefined
			And DataOfAccounting.Organization = Object.Organization Then
		
			RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
		
		EndIf;
		
		If RowData.CostByAccountingDataMA <> RowData.CostActualMan
			And RowData.CostByAccountingDataMA <> 0
			And RowData.CostActualMan <> 0 Then
		
			RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation");
		
		ElsIf RowData.CostActualMan = 0
			And RowData.CostByAccountingDataMA <> 0
			And Object.RecordInManAccounting
			And (Object.PostInAccounting Or Object.RecordInTA) Then
		
			RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff");
		
		ElsIf RowData.CostActualMan <> 0
			And RowData.CostByAccountingDataMA = 0
			And DataOfAccounting <> Undefined
			And DataOfAccounting.Organization = Object.Organization Then
		
			RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
		
		EndIf;
		
	ElsIf Not RowData.AvailabilityByAccountingData
		And RowData.AvailabilityActual Then
		
		If DataOfAccounting = Undefined
			Or Not ValueIsFilled(DataOfAccounting.Organization) Then
			
			If Object.PostInAccounting Then
				RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
			EndIf;
			
			If Object.RecordInTA Then
				RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
			EndIf;
			
			If Object.RecordInManAccounting Then
				RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition");
			EndIf;
			
		Else
			
			If DataOfAccounting <> Undefined
				And (DataOfAccounting.Organization <> Object.Organization
					Or DataOfAccounting.Department <> Object.Department) Then
			
				If Object.PostInAccounting Then
					RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move");
				EndIf;
				
				If Object.RecordInTA <> 0 Then
					RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move");
				EndIf;
				
				If Object.RecordInManAccounting <> 0 Then
					RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move");
				EndIf;
			
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

Procedure FillInPresentationOfAction(RowData, Form) Export
	
	Object = Form.Object;

	RowData.ActionPresentation = "";
	
	If (Not ValueIsFilled(RowData.LAAction)
			Or Not Object.PostInAccounting)
		And (Not ValueIsFilled(RowData.TAAction)
			Or Not Object.RecordInTA)
		And (Not ValueIsFilled(RowData.MAAction)
			Or Not Object.RecordInManAccounting) Then
			
		Return;
	EndIf;
	
	ActionPresentation = "";
	
	If (ValueIsFilled(RowData.DocumentBasedOnAC)
			Or Not ValueIsFilled(RowData.LAAction))
		And (ValueIsFilled(RowData.DocumentBasedOnTA)
			Or Not ValueIsFilled(RowData.TAAction))
		And (ValueIsFilled(RowData.DocumentBasedOnMA)
			Or Not ValueIsFilled(RowData.MAAction)) Then
		
		GeneralDocument = GeneralDocument(RowData);
		
		If GeneralDocument <> Undefined Then
			
			ActionPresentation = String(GeneralDocument);
			
		Else	
			
			ActionPresentation = NStr("vi = 'Tất cả các chứng từ đã được lập';
										|ru = 'Все документы оформлены';
										|en = 'All documents are registered'; fa = 'All documents are registered';
										|it = 'All documents are registered';
										|pl = 'All documents are registered';
										|tr = 'Tüm belgeler oluşturuldu'");
			
		EndIf;
		
	ElsIf ValueIsFilled(RowData.DocumentBasedOnAC)
		Or ValueIsFilled(RowData.DocumentBasedOnTA)
		Or ValueIsFilled(RowData.DocumentBasedOnMA) Then
			
		ActionPresentation = NStr("vi = 'Các chứng từ đã được lập một phần';
									|ru = 'Документы оформлены частично';
									|en = 'The documents are partially registered'; fa = 'The documents are partially registered';
									|it = 'The documents are partially registered';
									|pl = 'The documents are partially registered';
									|tr = 'Belgeler kısmen oluşturuldu'");
			 	
	ElsIf ValueIsFilled(RowData.LAAction)
		Or ValueIsFilled(RowData.TAAction)
		Or ValueIsFilled(RowData.MAAction) Then
			
		Action = GeneralAction(RowData);
		
		If Action <> Undefined Then
			
			ActionPresentation = String(Action);
			
		Else	
			
			ActionPresentation = NStr("vi = 'Các chứng từ chưa được lập';
										|ru = 'Документы не оформлены';
										|en = 'The documents are not registered'; fa = 'The documents are not registered';
										|it = 'The documents are not registered';
										|pl = 'The documents are not registered';
										|tr = 'Belgeler oluşturulmadı'");
			
		EndIf;
			 	
	EndIf;
	
	RowData.ActionPresentation = ActionPresentation;
	
EndProcedure

Function GeneralAction(RowData)
	
	Action = Undefined;
	
	If ValueIsFilled(RowData.LAAction) Then
		
		ActionIsGeneral = FirstValueIsGeneral(
			RowData.LAAction, 
			RowData.TAAction, 
			RowData.MAAction, 
			ValueIsFilled(RowData.LAAction), 
			ValueIsFilled(RowData.TAAction), 
			ValueIsFilled(RowData.MAAction));
				
		If ActionIsGeneral Then
			Action = RowData.LAAction;
		EndIf;
		
	ElsIf ValueIsFilled(RowData.TAAction) Then
		
		ActionIsGeneral = FirstValueIsGeneral(
			RowData.TAAction, 
			RowData.LAAction, 
			RowData.MAAction, 
			ValueIsFilled(RowData.TAAction), 
			ValueIsFilled(RowData.LAAction), 
			ValueIsFilled(RowData.MAAction));
		
		If ActionIsGeneral Then
			Action = RowData.TAAction;
		EndIf;

	ElsIf ValueIsFilled(RowData.MAAction) Then
		
		ActionIsGeneral = FirstValueIsGeneral(
			RowData.MAAction, 
			RowData.LAAction, 
			RowData.TAAction, 
			ValueIsFilled(RowData.MAAction), 
			ValueIsFilled(RowData.LAAction), 
			ValueIsFilled(RowData.TAAction));

		If ActionIsGeneral Then
			Action = RowData.MAAction;
		EndIf;
		
	EndIf;
	
	Return Action;
	
EndFunction

Function GeneralDocument(RowData)
	
	GeneratedDocument = Undefined;
	
	If ValueIsFilled(RowData.DocumentBasedOnAC) Then
		
		DocumentShared = FirstValueIsGeneral(
			RowData.DocumentBasedOnAC, 
			RowData.DocumentBasedOnTA, 
			RowData.DocumentBasedOnMA, 
			ValueIsFilled(RowData.LAAction), 
			ValueIsFilled(RowData.TAAction), 
			ValueIsFilled(RowData.MAAction));
				
		If DocumentShared Then
			GeneratedDocument = RowData.DocumentBasedOnAC;
		EndIf;
		
	ElsIf ValueIsFilled(RowData.DocumentBasedOnTA) Then
		
		DocumentShared = FirstValueIsGeneral(
			RowData.DocumentBasedOnTA, 
			RowData.DocumentBasedOnAC, 
			RowData.DocumentBasedOnMA, 
			ValueIsFilled(RowData.TAAction), 
			ValueIsFilled(RowData.LAAction), 
			ValueIsFilled(RowData.MAAction));
		
		If DocumentShared Then
			GeneratedDocument = RowData.DocumentBasedOnTA;
		EndIf;

	ElsIf ValueIsFilled(RowData.DocumentBasedOnMA) Then
		
		DocumentShared = FirstValueIsGeneral(
			RowData.DocumentBasedOnMA, 
			RowData.DocumentBasedOnAC, 
			RowData.DocumentBasedOnTA, 
			ValueIsFilled(RowData.MAAction), 
			ValueIsFilled(RowData.LAAction), 
			ValueIsFilled(RowData.TAAction));

		If DocumentShared Then
			GeneratedDocument = RowData.DocumentBasedOnMA;
		EndIf;
		
	EndIf;
	
	Return GeneratedDocument;
	
EndFunction

Function FirstValueIsGeneral(Value1, Value2, Value3, UseValue1, UseValue2, UseValue3)
	
	If Not ValueIsFilled(Value1)
		And Not ValueIsFilled(Value2)
		And Not ValueIsFilled(Value3) Then
		
		Return True;
	EndIf;

	Result =
		ValueIsFilled(Value1)
		And UseValue1
		And (Value1 = Value2
				And Value1 = Value3
			Or Value1 = Value2
				And (Not UseValue3
					Or Not ValueIsFilled(Value3))
			Or Value1 = Value3
				And (Not UseValue2
					Or Not ValueIsFilled(Value2))
			Or Not UseValue2
				And Not UseValue3
			Or Not ValueIsFilled(Value2)
				And Not ValueIsFilled(Value3));
				
	Return Result;
		
EndFunction

#EndRegion

#Region Other

Function ParametersForAcceptingBalanceEntryAxisForAccounting(Object, AuxiliaryAttributes)

	ACDepreciationParametersAreAvailable = 
		(Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.EmptyRef"))
		And AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
	//
	AvailableMaDepreciationParameters = 
		(Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"))
			And AuxiliaryAttributes.RecordInManAccounting;
	//								
	AvailableReflectionOfBUExpenses = 
		AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.EmptyRef"));
			
	//		
	AvailableReflectionOfMaExpenses = 
		AuxiliaryAttributes.RecordInManAccounting
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
			
	//
	MaDepreciationIsAvailable = 
		(Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
				Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition"))
			And AuxiliaryAttributes.RecordInManAccounting;
							
	//		
	ACDepreciationIsAvailable = 
		(Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.AccrueWearAsPerUFADR")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition"))
		And AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
	
	//
	ByAssetActivity = 
		Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
		Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction")
		Or Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage");
		
	//
	ExpenseItemManagementAccountingRequired_ = 
		AuxiliaryAttributes.RecordInManAccounting 
		And (Not AvailableReflectionOfBUExpenses 
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses")
			Or ValueIsFilled(Object.ExpenseItemManagementAccounting)
			Or ValueIsFilled(Object.ExpensesDimensionManagementAccounting)
			Or ValueIsFilled(Object.BusinessUnitManagementAccounting)
			Or ValueIsFilled(Object.LineOfBusinessManagementAccounting));
		
	//
	FAAcceptanceParameters = New Structure;
	FAAcceptanceParameters.Insert("ACDepreciationParametersAreAvailable", ACDepreciationParametersAreAvailable);
	FAAcceptanceParameters.Insert("AvailableMaDepreciationParameters", AvailableMaDepreciationParameters);
	FAAcceptanceParameters.Insert("AvailableReflectionOfBUExpenses", AvailableReflectionOfBUExpenses);
	FAAcceptanceParameters.Insert("AvailableReflectionOfMaExpenses", AvailableReflectionOfMaExpenses);
	FAAcceptanceParameters.Insert("ExpenseReflectionIsAvailable", False);
	FAAcceptanceParameters.Insert("MaDepreciationIsAvailable", MaDepreciationIsAvailable);
	FAAcceptanceParameters.Insert("ACDepreciationIsAvailable", ACDepreciationIsAvailable);
	FAAcceptanceParameters.Insert("ByAssetActivity", ByAssetActivity);
	FAAcceptanceParameters.Insert("LineOfBusinessIsMandatory", False);
	FAAcceptanceParameters.Insert("ExpenseItemManagementAccountingRequired_", ExpenseItemManagementAccountingRequired_);
	
	NonCurrentAssetsClientServerLocalization.AddAcceptanceParametersToAccountingOfBalanceInputAxis(
		Object, AuxiliaryAttributes, FAAcceptanceParameters);
	
	Return FAAcceptanceParameters;

EndFunction

Function ParametersOfAcceptanceForAccountingOfNMAIInputOfBalances(Object, AuxiliaryAttributes)
	
	//
	ACDepreciationParametersAreAvailable = 
		AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
		
	AvailableMaDepreciationParameters = 
		AuxiliaryAttributes.RecordInManAccounting
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
									
	AvailableReflectionOfBUExpenses = 
		AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
	
	AvailableReflectionOfMaExpenses = 
		AuxiliaryAttributes.RecordInManAccounting
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
									
	ByAssetActivity = 
		AuxiliaryAttributes.RecordInManAccounting
			And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			And Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction")
		Or AuxiliaryAttributes.PostInAccounting
			And Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			And Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction");
				
	ACCostIsAvailable = 
		AuxiliaryAttributes.PostInAccounting
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
	
	//
	CostOfMaIsAvailable = 
		AuxiliaryAttributes.RecordInManAccounting
		And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			Or Not AuxiliaryAttributes.CurrenciesDoNotMatch)
		And (Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrWriteOffAsExpenses")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
				
	ACDepreciationIsAvailable = 
		AuxiliaryAttributes.PostInAccounting
		And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
		And (Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureTA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or Object.AccountingProcedureTA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.EmptyRef"));
			
	ExpenseItemManagementAccountingRequired_ = 
		AuxiliaryAttributes.RecordInManAccounting 
		And (Not AvailableReflectionOfBUExpenses
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses")
			Or ValueIsFilled(Object.ExpenseItemManagementAccounting)
			Or ValueIsFilled(Object.ExpensesDimensionManagementAccounting)
			Or ValueIsFilled(Object.BusinessUnitManagementAccounting)
			Or ValueIsFilled(Object.LineOfBusinessManagementAccounting));
	
	IAAcceptanceParameters = New Structure;
	IAAcceptanceParameters.Insert("ACDepreciationParametersAreAvailable", ACDepreciationParametersAreAvailable);
	IAAcceptanceParameters.Insert("AvailableMaDepreciationParameters", AvailableMaDepreciationParameters);
	IAAcceptanceParameters.Insert("AvailableReflectionOfBUExpenses", AvailableReflectionOfBUExpenses);
	IAAcceptanceParameters.Insert("AvailableReflectionOfMaExpenses", AvailableReflectionOfMaExpenses);
	IAAcceptanceParameters.Insert("ACDepreciationIsAvailable", ACDepreciationIsAvailable);
	IAAcceptanceParameters.Insert("ExpenseItemManagementAccountingRequired_", ExpenseItemManagementAccountingRequired_);
	IAAcceptanceParameters.Insert("ByAssetActivity", ByAssetActivity);
	IAAcceptanceParameters.Insert("LineOfBusinessIsMandatory", False);
	IAAcceptanceParameters.Insert("CostOfMaIsAvailable", CostOfMaIsAvailable);
	IAAcceptanceParameters.Insert("ACCostIsAvailable", ACCostIsAvailable);

	NonCurrentAssetsClientServerLocalization.ToSupplementParametersOfAcceptanceToAccountingOfNMAIInputBalances(
		Object, AuxiliaryAttributes, IAAcceptanceParameters);

	Return IAAcceptanceParameters;
		
EndFunction

// Adds a description of the error.
// 
// Parameters:
//  ErrorList - Array of Structure - List of errors
//  MessageText - String - Message text
//  Field - String - Field
//  DataPath - String - Data path
//	HasErrors - Boolean -
Procedure AddErrorDescription(ErrorList, MessageText, Field = Undefined, DataPath = Undefined, HasErrors = False) Export
	
	HasErrors = True;
	
	ErrorDescription = New Structure;
	ErrorDescription.Insert("MessageText", MessageText);
	ErrorDescription.Insert("Field", Field);
	ErrorDescription.Insert("DataPath", DataPath);

	ErrorList.Add(ErrorDescription);
	
EndProcedure

// Adds the currency name to the line.
// 
// Parameters:
// 	InitialString - String -
// 	CurrencyPresentation - String -
// 	
// Returns:
// 	String - The line with the currency.
Function AddCurrencyToLine(InitialString, CurrencyPresentation) Export
	Return ?(ValueIsFilled(CurrencyPresentation), StrTemplate(InitialString + " (%1)", CurrencyPresentation), InitialString);
EndFunction

// Presentation of the currency field.
// 
// Parameters:
//  PresentationWithoutConsideration - String - 
//  Presentation - String - 
//  FALocalAccountingIsConductedIndependently - Boolean - 
//  CurrenciesDoNotMatch - Boolean - 
//  CurrencyPresentation - String - 
// 
// Returns:
//  String - Presentation of the currency field
Function PresentationOfCurrencyField(PresentationWithoutConsideration, Presentation, FALocalAccountingIsConductedIndependently, CurrenciesDoNotMatch, CurrencyPresentation) Export
	
	If Not FALocalAccountingIsConductedIndependently
		And CurrenciesDoNotMatch Then
			
		PresentationOfCurrencyField = PresentationWithoutConsideration;
		
	Else
		
		PresentationOfCurrencyField = AddCurrencyToLine(Presentation, CurrencyPresentation);
			
	EndIf; 
	
	Return PresentationOfCurrencyField;
	
EndFunction

#EndRegion

#EndRegion
