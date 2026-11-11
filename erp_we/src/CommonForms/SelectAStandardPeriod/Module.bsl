#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.Repetition) Then
		If Parameters.Repetition <> Enums.Periodicity.Day Then
			Items.SelectDay.Visible = False;
		EndIf;
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters, "BeginOfPeriod,EndOfPeriod, LowLimit");
	
	// setting according to the transmitted parameters
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod  = EndOfMonth(CurrentSessionDate());
		BeginOfPeriod = BegOfMonth(EndOfPeriod);
	EndIf;
	
	If LowLimit > EndOfPeriod Then
		EndOfPeriod  = EndOfMonth(LowLimit);
		BeginOfPeriod = BegOfMonth(LowLimit);
	EndIf;
	
	YearStartDate = BegOfYear(EndOfPeriod);
	
	ToCustomizeTheFormByLimitingThePeriodOf(ThisObject);
	
	// Define the name of the active period
	If BegOfDay(BeginOfPeriod) = BegOfDay(EndOfPeriod) Then
		CurrentItemName = "SelectDay";
	ElsIf BegOfMonth(BeginOfPeriod) = BegOfMonth(EndOfPeriod) Then
		MonthNumber = Month(BeginOfPeriod);
		CurrentItemName = "SelectMonth" + MonthNumber;
	ElsIf BegOfQuarter(BeginOfPeriod) = BegOfQuarter(EndOfPeriod) Then
		MonthNumber = Month(BeginOfPeriod);
		QuarterNumber = Int((MonthNumber + 3) / 3);
		CurrentItemName = "SelectAQuarter" + QuarterNumber;
	ElsIf BegOfYear(BeginOfPeriod) = BegOfYear(EndOfPeriod) Then
		TheNumberOfTheMonthBeginning = Month(BeginOfPeriod);
		TheNumberOfTheMonthEnd  = Month(EndOfPeriod);
		If TheNumberOfTheMonthBeginning <= 3 And TheNumberOfTheMonthEnd <= 6 Then
			CurrentItemName = "SelectHalfYear";
		ElsIf TheNumberOfTheMonthBeginning <= 3 And TheNumberOfTheMonthEnd <= 9 Then
			CurrentItemName = "Select9Months";
		Else
			CurrentItemName = "SelectYear";
		EndIf;
	Else
		CurrentItemName = "SelectYear";
	EndIf;
	
	CurrentItem = Items[CurrentItemName];
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GotoPreviousYear(Command)
	
	YearStartDate = BegOfYear(YearStartDate - 1);
	
	ToCustomizeTheFormByLimitingThePeriodOf(ThisObject);
	
	CurrentItem = Items[CurrentItemName];
	
EndProcedure

&AtClient
Procedure GotoNextYear(Command)
	
	YearStartDate = EndOfYear(YearStartDate) + 1;
	
	ToCustomizeTheFormByLimitingThePeriodOf(ThisObject);
	
	CurrentItem = Items[CurrentItemName];
	
EndProcedure

&AtClient
Procedure SelectMonth1(Command)
	
	SelectMonth(1);
	
EndProcedure

&AtClient
Procedure SelectMonth2(Command)
	
	SelectMonth(2);
	
EndProcedure

&AtClient
Procedure SelectMonth3(Command)
	
	SelectMonth(3);
	
EndProcedure

&AtClient
Procedure SelectMonth4(Command)
	
	SelectMonth(4);
	
EndProcedure

&AtClient
Procedure SelectMonth5(Command)
	
	SelectMonth(5);
	
EndProcedure

&AtClient
Procedure SelectMonth6(Command)
	
	SelectMonth(6);
	
EndProcedure

&AtClient
Procedure SelectMonth7(Command)
	
	SelectMonth(7);
	
EndProcedure

&AtClient
Procedure SelectMonth8(Command)
	
	SelectMonth(8);
	
EndProcedure

&AtClient
Procedure SelectMonth9(Command)
	
	SelectMonth(9);
	
EndProcedure

&AtClient
Procedure SelectMonth10(Command)
	
	SelectMonth(10);
	
EndProcedure

&AtClient
Procedure SelectMonth11(Command)
	
	SelectMonth(11);
	
EndProcedure

&AtClient
Procedure SelectMonth12(Command)
	
	SelectMonth(12);
	
EndProcedure

&AtClient
Procedure SelectAQuarter1(Command)
	
	SelectAQuarter(1);
	
EndProcedure

&AtClient
Procedure SelectAQuarter2(Command)
	
	SelectAQuarter(2);
	
EndProcedure

&AtClient
Procedure SelectAQuarter3(Command)
	
	SelectAQuarter(3);
	
EndProcedure

&AtClient
Procedure SelectAQuarter4(Command)
	
	SelectAQuarter(4);
	
EndProcedure

&AtClient
Procedure SelectDay(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("BeginOfPeriod",    BeginOfPeriod);
	FormParameters.Insert("EndOfPeriod",     EndOfPeriod);
	FormParameters.Insert("LowLimit", LowLimit);
	
	CallbackDescription = New CallbackDescription("SelectDayCompletion", ThisObject);
	OpenForm(
		"CommonForm.SelectStandardPeriodDay", 
		FormParameters, 
		ThisObject,
		,
		,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectHalfYear(Command)
	
	BeginOfPeriod = YearStartDate;
	EndOfPeriod  = EndOfMonth(AddMonth(BeginOfPeriod, 5));
	ToCarryOutAPeriod();
	
EndProcedure

&AtClient
Procedure Select9Months(Command)

	BeginOfPeriod = YearStartDate;
	EndOfPeriod  = Date(Year(YearStartDate), 9 , 30);
	ToCarryOutAPeriod();
	
EndProcedure

&AtClient
Procedure SelectYear(Command)

	BeginOfPeriod = YearStartDate;
	EndOfPeriod  = EndOfYear(YearStartDate);
	ToCarryOutAPeriod();
	
EndProcedure

#EndRegion

#Region ServiceProceduresFunctions

&AtClient
Procedure ToCarryOutAPeriod()

	SelectionResult = New Structure("BeginOfPeriod,EndOfPeriod", BeginOfPeriod, EndOfDay(EndOfPeriod));
	Close(SelectionResult);
	
EndProcedure 

&AtClient
Procedure SelectMonth(MonthNumber)
	
	BeginOfPeriod = Date(Year(YearStartDate), MonthNumber, 1);
	EndOfPeriod  = EndOfMonth(BeginOfPeriod);
	
	ToCarryOutAPeriod();
	
EndProcedure

&AtClient
Procedure SelectAQuarter(QuarterNumber)
	
	BeginOfPeriod = Date(Year(YearStartDate), 1 + (QuarterNumber - 1) * 3, 1);
	
	EndOfPeriod  = EndOfQuarter(BeginOfPeriod);
	
	ToCarryOutAPeriod();
	
EndProcedure

&AtClient
Procedure SelectDayCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		BeginOfPeriod = Result.BeginOfPeriod;
		EndOfPeriod  = Result.EndOfPeriod;
		ToCarryOutAPeriod();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ToCustomizeTheFormByLimitingThePeriodOf(Form)
	
	If Not ValueIsFilled(Form.LowLimit) Then
		Return;
	EndIf;
	
	If Form.LowLimit < Form.YearStartDate
		And Not Form.SelectedYearLimited Then
		Return;
	EndIf;
	
	FirstYear = (BegOfYear(Form.LowLimit) = Form.YearStartDate);
	
	// Choosing the year
	Form.SelectedYearLimited = FirstYear;
	
	Form.Items.GoBackOneYearAvailable.Visible   = Not FirstYear;
	Form.Items.GoBackOneYearUnavailable.Visible = FirstYear; // The picture is selected by the standard period is not available by the button
	
	// Choosing a quarter
	TheMinimumQuarter = ?(Not FirstYear, 1, Month(EndOfQuarter(Form.LowLimit)) / 3);
	
	TheNamesOfTheQuartersCumulatively = New Map;
	TheNamesOfTheQuartersCumulatively.Insert(2, "SelectHalfYear");
	TheNamesOfTheQuartersCumulatively.Insert(3, "Select9Months");
	TheNamesOfTheQuartersCumulatively.Insert(4, "SelectYear");
	
	For QuarterNumber = 1 To 4 Do
		
		SelectQuarter = (QuarterNumber >= TheMinimumQuarter);
		
		FormItem = Form.Items["SelectAQuarter" + QuarterNumber]; // FormField, FormButton -
		FormItem.Enabled = SelectQuarter;
		
		NameCumulativeTotal = TheNamesOfTheQuartersCumulatively[QuarterNumber];
		If NameCumulativeTotal <> Undefined Then
			FormItem = Form.Items[NameCumulativeTotal]; // FormField, FormButton -
			FormItem.Enabled = SelectQuarter;
		EndIf;
		
	EndDo;
		
	// Choosing the month
	MinimumAMonth = ?(Not FirstYear, 1, Month(Form.LowLimit));
	For MonthNumber = 1 To 12 Do
		FormItem = Form.Items["SelectMonth" + MonthNumber]; // FormField, FormButton -
		FormItem.Enabled = (MonthNumber >= MinimumAMonth);
	EndDo;
	
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
