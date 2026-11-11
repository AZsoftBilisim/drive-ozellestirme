
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject, Parameters, "BeginOfPeriod, EndOfPeriod, QuarterSelection, LowLimit");
	
	Items.GroupQuarters.Visible = QuarterSelection;
	
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
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetActivePeriod();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GotoPreviousYear(Command)
	
	YearStartDate = BegOfYear(YearStartDate - 1);
	
	ToCustomizeTheFormByLimitingThePeriodOf(ThisObject);
	
	SetActivePeriod();
	
EndProcedure

&AtClient
Procedure GotoNextYear(Command)
	
	YearStartDate = EndOfYear(YearStartDate) + 1;
	
	ToCustomizeTheFormByLimitingThePeriodOf(ThisObject);
	
	SetActivePeriod();
	
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

#EndRegion

#Region Private

&AtClient
Procedure SetActivePeriod()
	
	If BegOfMonth(BeginOfPeriod) = BegOfMonth(EndOfPeriod) Then
		MonthNumber = Month(BeginOfPeriod);
		CurrentItem = Items["SelectMonth" + MonthNumber];
	ElsIf QuarterSelection
		And BegOfQuarter(BeginOfPeriod) = BegOfQuarter(EndOfPeriod) Then
		QuarterNumber = Month(EndOfQuarter(BeginOfPeriod))/3;
		CurrentItem = Items["SelectAQuarter" + QuarterNumber];
	EndIf;

EndProcedure

&AtClient
Procedure ToCarryOutAPeriod()

	SelectionResult = New Structure("BeginOfPeriod,EndOfPeriod", BeginOfPeriod, EndOfDay(EndOfPeriod));
	NotifyChoice(SelectionResult);

EndProcedure 

&AtClient
Procedure SelectMonth(MonthNumber)
	
	BeginOfPeriod = Date(Year(YearStartDate), MonthNumber, 1);
	EndOfPeriod  = EndOfMonth(BeginOfPeriod);
	
	ToCarryOutAPeriod();
	
EndProcedure

&AtClient
Procedure SelectAQuarter(QuarterNumber)
	
	BeginningOfQuarterPeriod = Date(Year(YearStartDate), QuarterNumber * 3 - 2, 1);
	BeginOfPeriod = BeginningOfQuarterPeriod;
	EndOfPeriod = EndOfQuarter(BeginningOfQuarterPeriod);
	
	ToCarryOutAPeriod();
	
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
	If Form.QuarterSelection Then
		
		TheMinimumQuarter = ?(Not FirstYear, 1, Month(EndOfQuarter(Form.LowLimit)) / 3);
		
		For QuarterNumber = 1 To 4 Do
			FormItem = Form.Items["SelectAQuarter" + QuarterNumber]; // FormField, FormButton -
			FormItem.Enabled = (QuarterNumber >= TheMinimumQuarter);
		EndDo;
		
	EndIf;
	
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
