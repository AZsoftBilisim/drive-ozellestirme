
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject, Parameters, "BeginOfPeriod, EndOfPeriod, MinimumPeriod");
	YearStartDate = ?(ValueIsFilled(EndOfPeriod), BegOfYear(EndOfPeriod), BegOfYear(CurrentSessionDate()));
	
	MinimumAMonth = Month(BegOfQuarter(MinimumPeriod));
	MinimumPeriod = BegOfYear(MinimumPeriod);
	
	If YearStartDate < MinimumPeriod Then
		Cancel = True;
		Raise NStr("vi = 'Tùy chọn lựa chọn thời gian không hợp lệ';
					|ru = 'Неверные параметры выбора периода';
					|en = 'Incorrect period selection parameters'; fa = 'Incorrect period selection parameters';
					|it = 'Parametri di selezione del periodo errati';
					|pl = 'Nieprawidłowe parametry wyboru okresu';
					|tr = 'Yanlış dönem seçim seçenekleri'");
	EndIf;
	
	RunningTotal = Parameters.Property("RunningTotal") And Parameters.RunningTotal;
	
	Items.GroupOnAnAccrualBasis.Visible = RunningTotal;
	Items.GroupQuarters.Visible          = Not RunningTotal;
	
	FormControl(ThisObject);
	
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
	
	SetActivePeriod();
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure GotoNextYear(Command)
	
	YearStartDate = EndOfYear(YearStartDate) + 1;
	
	SetActivePeriod();
	
	FormControl(ThisObject);
	
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

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	LastYearIsAvailable = Form.YearStartDate > Form.MinimumPeriod;
	
	Items.GotoPreviousYear.Visible           = LastYearIsAvailable;
	Items.GoBackOneYearUnavailable.Visible = Not LastYearIsAvailable;
	
	SuffixPeriodType = ?(Form.RunningTotal, "Growing", "");
	
	If Not LastYearIsAvailable And Form.MinimumAMonth <> 1 Then
		
		// Let's set the availability of a choice of quarters
		FormItem = Items["SelectAQuarter1" + SuffixPeriodType]; // FormField, FormButton -
		FormItem.Enabled = False;
		FormItem = Items["SelectAQuarter2" + SuffixPeriodType]; // FormField, FormButton -
		FormItem.Enabled = Form.MinimumAMonth < 7;
		FormItem = Items["SelectAQuarter3" + SuffixPeriodType]; // FormField, FormButton -
		FormItem.Enabled = Form.MinimumAMonth < 10;
	Else
		FormItem = Items["SelectAQuarter1" + SuffixPeriodType]; // FormField, FormButton -
		FormItem.Enabled = True;
		FormItem = Items["SelectAQuarter2" + SuffixPeriodType]; // FormField, FormButton -
		FormItem.Enabled = True;
		FormItem = Items["SelectAQuarter3" + SuffixPeriodType]; // FormField, FormButton -
		FormItem.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetActivePeriod()
	
	If RunningTotal Then
		QuarterNumber = Month(EndOfQuarter(EndOfPeriod)) / 3;
		CurrentItem = Items["SelectAQuarter" + QuarterNumber + "Growing"];
	Else
		If BegOfQuarter(BeginOfPeriod) = BegOfQuarter(EndOfPeriod) Then
			QuarterNumber = Month(EndOfQuarter(BeginOfPeriod)) / 3;
			CurrentItem = Items["SelectAQuarter" + QuarterNumber];
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ToCarryOutAPeriod()
	
	SelectionResult = New Structure("BeginOfPeriod, EndOfPeriod", BeginOfPeriod, EndOfDay(EndOfPeriod));
	NotifyChoice(SelectionResult);
	
EndProcedure

&AtClient
Procedure SelectAQuarter(QuarterNumber)
	
	BeginningOfQuarterPeriod = Date(Year(YearStartDate), QuarterNumber * 3 - 2, 1);
	EndOfPeriod = EndOfQuarter(BeginningOfQuarterPeriod);
	If RunningTotal Then
		BeginOfPeriod = YearStartDate;
	Else
		BeginOfPeriod = BeginningOfQuarterPeriod;
	EndIf;
	
	ToCarryOutAPeriod();
	
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
