
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject, Parameters, "BeginOfPeriod, EndOfPeriod, MinimumPeriod, RunningTotal");
	
	If RunningTotal Then
		Items.ChoosingAQuarter.Visible = False;
		Items.SelectingAQuarterOnAnAccrualBasis.Representation = UsualGroupRepresentation.None;
	EndIf;
	
	YearStartDate = ?(ValueIsFilled(EndOfPeriod), BegOfYear(EndOfPeriod), BegOfYear(CurrentSessionDate()));
	
	MinimumAMonth  = Month(BegOfQuarter(MinimumPeriod));
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

&AtClient
Procedure SelectHalfYear1(Command)
	
	SelectHalfYear(1);
	
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

#Region Private

&AtClient
Procedure SetActivePeriod()

	If BegOfQuarter(BeginOfPeriod) = BegOfQuarter(EndOfPeriod) 
		And Not RunningTotal Then
		QuarterNumber = Month(EndOfQuarter(EndOfPeriod)) / 3;
		CurrentItem = Items["SelectAQuarter" + QuarterNumber];
	ElsIf BegOfYear(BeginOfPeriod) = BegOfYear(EndOfPeriod) Then
		TheNumberOfTheMonthBeginning = Month(BeginOfPeriod);
		TheNumberOfTheMonthEnd  = Month(EndOfPeriod);
		If TheNumberOfTheMonthBeginning <= 3 And TheNumberOfTheMonthEnd <= 6 Then
			CurrentItem = Items["SelectHalfYear1"];
		ElsIf TheNumberOfTheMonthBeginning <= 3 And TheNumberOfTheMonthEnd <= 9 Then
			CurrentItem = Items["Select9Months"];
		Else
			CurrentItem = Items["SelectYear"];
		EndIf;
	Else
		CurrentItem = Items["SelectYear"];
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	LastYearIsAvailable = Form.YearStartDate > Form.MinimumPeriod;
	
	Items.GotoPreviousYear.Visible           = LastYearIsAvailable;
	Items.GoBackOneYearUnavailable.Visible = Not LastYearIsAvailable;
	
	If Not LastYearIsAvailable And Form.MinimumAMonth <> 1 Then
		
		// Let's set the availability of a choice of quarters
		Items.SelectAQuarter1.Enabled = False;
		Items.SelectAQuarter2.Enabled = Form.MinimumAMonth < 7;
		Items.SelectAQuarter3.Enabled = Form.MinimumAMonth < 10;
		
		Items.Quarter.Enabled           = False;
		Items.SelectHalfYear1.Enabled = Form.MinimumAMonth < 7;
		Items.Select9Months.Enabled   = Form.MinimumAMonth < 10;
		
	Else
		
		Items.SelectAQuarter1.Enabled = True;
		Items.SelectAQuarter2.Enabled = True;
		Items.SelectAQuarter3.Enabled = True;
		
		Items.Quarter.Enabled           = True;
		Items.SelectHalfYear1.Enabled = True;
		Items.Select9Months.Enabled   = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToCarryOutAPeriod()

	SelectionResult = New Structure("BeginOfPeriod,EndOfPeriod", BeginOfPeriod, EndOfDay(EndOfPeriod));
	NotifyChoice(SelectionResult);

EndProcedure 

&AtClient
Procedure SelectAQuarter(QuarterNumber)
	
	BeginOfPeriod = Date(Year(YearStartDate), 1 + (QuarterNumber - 1) * 3, 1);
	
	EndOfPeriod  = EndOfQuarter(BeginOfPeriod);
	
	ToCarryOutAPeriod();
	
EndProcedure

&AtClient
Procedure SelectHalfYear(HalfYearNumber)

	BeginOfPeriod = Date(Year(YearStartDate), 1 + (HalfYearNumber - 1) * 6, 1);
	EndOfPeriod  = EndOfMonth(AddMonth(BeginOfPeriod, 5));
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
