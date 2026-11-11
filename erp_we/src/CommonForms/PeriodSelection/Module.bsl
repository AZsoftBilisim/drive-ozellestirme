
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("Value", SelectedPeriod);
	
	SelectPeriodKind = CommonClientServer.StructureProperty(Parameters, "SelectPeriodKind", False);
	If SelectPeriodKind Then
		KindsOfSelectedPeriods = New FixedArray(CommonClientServer.StructureProperty(Parameters, "KindsOfSelectedPeriods"));
	EndIf;
	
	WindowOptionsKey = CommonClientServer.StructureProperty(Parameters, "WindowOptionsKey", "OnePeriod");
	
	If Not ValueIsFilled(SelectedPeriod) Then
		SelectedPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	If Not Parameters.Property("RequestPeriodSelectionModeFromOwner", RequestPeriodSelectionModeFromOwner) Then
		RequestPeriodSelectionModeFromOwner = False;
	EndIf;
	
	SetPeriodSelectionMode(ThisObject, Parameters.PeriodSelectionMode);
	
	ButtonBackgroundColorOfTheSelectedPeriod = StyleColors.MarkedButtonBackgroundColor;
	ButtonBackColor = StyleColors.ButtonBackColor;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateDisplay();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectedPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	YearChanged = True;
	MarkedPeriod = Undefined;
	SetSelectablePeriod(Year(SelectedPeriod), Month(SelectedPeriod));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TeamMonth01(Command)
	SetSelectableMonth(1);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth02(Command)
	SetSelectableMonth(2);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth03(Command)
	SetSelectableMonth(3);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth04(Command)
	SetSelectableMonth(4);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth05(Command)
	SetSelectableMonth(5);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth06(Command)
	SetSelectableMonth(6);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth07(Command)
	SetSelectableMonth(7);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth08(Command)
	SetSelectableMonth(8);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth09(Command)
	SetSelectableMonth(9);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth10(Command)
	SetSelectableMonth(10);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth11(Command)
	SetSelectableMonth(11);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamMonth12(Command)
	SetSelectableMonth(12);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamQuarter1(Command)
	SetQuarterYouChoose(1);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamQuarter2(Command)
	SetQuarterYouChoose(2);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamQuarter3(Command)
	SetQuarterYouChoose(3);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamQuarter4(Command)
	SetQuarterYouChoose(4);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamHalfYear1(Command)
	SetSelectableHalfYear(1);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure TeamHalfYear2(Command)
	SetSelectableHalfYear(2);
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure CommandYear(Command)
	SetSelectableYear();
	MarkedPeriod = SelectedPeriod;
EndProcedure

&AtClient
Procedure SelectCommand(Command)
	ExecuteSelection();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

&AtClient
Procedure TeamCycleThroughTheYearInTheNegative(Command)
	
	SelectableYear = Year(SelectedPeriod) - 1;
	MarkedPeriod = Undefined;
	SetSelectablePeriod(SelectableYear, Month(SelectedPeriod));
	
EndProcedure

&AtClient
Procedure TheScrollThroughYearPlusCommand(Command)
	
	SelectableYear = Year(SelectedPeriod) + 1;
	MarkedPeriod = Undefined;
	SetSelectablePeriod(SelectableYear, Month(SelectedPeriod));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetSelectableMonth(MonthNumber)
	SetSelectablePeriod(Year(SelectedPeriod), MonthNumber, "MONTH");
EndProcedure

&AtClient
Procedure SetQuarterYouChoose(QuarterNumber)
	SetSelectablePeriod(Year(SelectedPeriod), ((QuarterNumber - 1) * 3) + 1, "QUARTER");
EndProcedure

&AtClient
Procedure SetSelectableHalfYear(HalfYearNumber)
	SetSelectablePeriod(Year(SelectedPeriod), ((HalfYearNumber - 1) * 6) + 1, "HALFYEAR");
EndProcedure

&AtClient
Procedure SetSelectableYear()
	SetSelectablePeriod(Year(SelectedPeriod), 1, "YEAR");
EndProcedure

&AtClient
Procedure CheckPeriodSelectionMode()
	
	If RequestPeriodSelectionModeFromOwner Then
		SetPeriodSelectionMode(ThisObject, FormOwner.PeriodSelectionMode(SelectedPeriod));
	EndIf;
	
EndProcedure
	
&AtClientAtServerNoContext
Procedure SetPeriodSelectionMode(Form, Val ChoiceMode)
	
	If Not ValueIsFilled(ChoiceMode) Then
		ChoiceMode = "Month";
	EndIf; 
	
	If Form.PeriodSelectionMode = Upper(ChoiceMode) Then
		Return;
	EndIf; 
	
	Form.PeriodSelectionMode = Upper(ChoiceMode);
	
	If Form.SelectPeriodKind Then
		GroupMonthsVisibility = Form.KindsOfSelectedPeriods.Find("MONTH") <> Undefined;
		GroupQuartersVisibility = Form.KindsOfSelectedPeriods.Find("QUARTER") <> Undefined;
		GroupHalfYearVisibility = Form.KindsOfSelectedPeriods.Find("HALFYEAR") <> Undefined;
		TeamVisibilityYear = Form.KindsOfSelectedPeriods.Find("YEAR") <> Undefined;
	Else
		
		GroupMonthsVisibility = False;
		GroupQuartersVisibility = False;
		GroupHalfYearVisibility = False;
		TeamVisibilityYear = False;
		
		If Form.PeriodSelectionMode = "MONTH" Then
			
			GroupMonthsVisibility = True;
			Form.SelectedPeriod = BegOfMonth(Form.SelectedPeriod);
			
		ElsIf Form.PeriodSelectionMode = "QUARTER" Then
			
			GroupQuartersVisibility = True;
			QuarterNumber = Int((Month(Form.SelectedPeriod) - 1) / 3 + 1);
			Form.SelectedPeriod = Date(Year(Form.SelectedPeriod), (QuarterNumber - 1) * 3 + 1, 1);
			
		ElsIf Form.PeriodSelectionMode = "HALFYEAR" Then
			
			GroupHalfYearVisibility = True;
			Form.SelectedPeriod = Date(Year(Form.SelectedPeriod), ?(Month(Form.SelectedPeriod) < 7, 1, 7), 1);
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"MonthsGroup",
		"Visible",
		GroupMonthsVisibility);
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"GroupQuarters",
		"Visible",
		GroupQuartersVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"HalfYearGroup",
		"Visible",
		GroupHalfYearVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"SelectedPeriod",
		"Visible",
		Not TeamVisibilityYear);
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"CommandYear",
		"Visible",
		TeamVisibilityYear);
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetTitleToYear(Form)

	If Not Form.SelectPeriodKind
		Or Form.KindsOfSelectedPeriods.Find("YEAR") = Undefined Then
		Return;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"CommandYear",
		"Title",
		Format(Form.SelectedPeriod, NStr("vi = 'ДФ=''гггг''';
										|ru = 'ДФ=''гггг''';
										|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
										|it = 'ДФ=''гггг''';
										|pl = 'DF=''yyyy''';
										|tr = 'ДФ=''гггг'''")));

EndProcedure

&AtClient
Procedure SetUnselectedButtonColor()

	If PeriodSelectionMode = "MONTH" Then
		NumberOfButtons_ = 12;
		CommandPrefix = "TeamMonth";
	ElsIf PeriodSelectionMode = "QUARTER" Then
		NumberOfButtons_ = 4;
		CommandPrefix = "TeamQuarter";
	ElsIf PeriodSelectionMode = "HALFYEAR" Then
		NumberOfButtons_ = 2;
		CommandPrefix = "TeamHalfYear";
	Else
		NumberOfButtons_ = 1;
		CommandPrefix = "CommandYear";
	EndIf;

	For SerialNumber = 1 To NumberOfButtons_ Do
		If PeriodSelectionMode = "YEAR" Then
			ButtonElement = Items[CommandPrefix]; // FormButton - 
		Else
			FormatString = ?(PeriodSelectionMode = "MONTH", "ND=2; NLZ=", "ND=1");
			ButtonElement = Items[CommandPrefix + Format(SerialNumber, FormatString)];
		EndIf;
		
		If ButtonElement.BackColor <> ButtonBackColor Then
			ButtonElement.BackColor = ButtonBackColor;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateDisplay()
	
	CheckPeriodSelectionMode();
	
	If PeriodSelectionMode = "MONTH" Then
		
		MonthButton = Items["TeamMonth" + Format(Month(SelectedPeriod), "ND=2; NLZ=")]; // FormButton - 
		If MonthButton.BackColor <> ButtonBackgroundColorOfTheSelectedPeriod Then
			MonthButton.BackColor = ButtonBackgroundColorOfTheSelectedPeriod;
		EndIf;
		
		CurrentItem = MonthButton;
		PeriodAsString = Format(SelectedPeriod, NStr("vi = 'ДФ=''ММММ гггг''';
													|ru = 'ДФ=''ММММ гггг''';
													|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
													|it = 'ДФ=''ММММ гггг''';
													|pl = 'DF=''MMMM yyyy''';
													|tr = 'DF=''MMMM yyyy'''"))
		
	ElsIf PeriodSelectionMode = "QUARTER" Then
		
		QuarterOfMonth = (Month(SelectedPeriod) - 1) / 3 + 1;
		QuarterButton = Items["TeamQuarter" + Format(QuarterOfMonth, "ND=1")]; // FormButton - 
		
		If QuarterButton.BackColor <> ButtonBackgroundColorOfTheSelectedPeriod Then
			QuarterButton.BackColor = ButtonBackgroundColorOfTheSelectedPeriod;
		EndIf;
		
		CurrentItem = QuarterButton;
		PeriodAsString = Format(QuarterOfMonth, "ND=1") + " " + NStr("vi = 'quý';
																	|ru = 'квартал';
																	|en = 'quarter'; fa = 'quarter';
																	|it = 'trimestre';
																	|pl = 'kwartał';
																	|tr = 'çeyrek'") + " " + Format(SelectedPeriod,"DF=yyyy");
		
	ElsIf PeriodSelectionMode = "HALFYEAR" Then
		
		If Month(SelectedPeriod) = 1 Then
			Items.TeamHalfYear1.BackColor = ButtonBackgroundColorOfTheSelectedPeriod;
			PeriodAsString = NStr("vi = 'nửa năm đầu';
									|ru = '1 полугодие';
									|en = 'Half-year I'; fa = 'نیم‌سال اول';
									|it = '1 semestre';
									|pl = '1 półrocze';
									|tr = '1. yarıyıl'") + " " + Format(SelectedPeriod,"DF=yyyy");
		Else
			Items.TeamHalfYear2.BackColor = ButtonBackgroundColorOfTheSelectedPeriod;
			PeriodAsString = NStr("vi = 'nửa năm cuối';
									|ru = '2 полугодие';
									|en = 'Half-year II'; fa = 'نیم‌سال دوم';
									|it = '2 semestre';
									|pl = '2 półrocze';
									|tr = '2. yarıyıl'") + " " + Format(SelectedPeriod,"DF=yyyy");
		EndIf;
		
	Else
		Items.CommandYear.BackColor = ButtonBackgroundColorOfTheSelectedPeriod;
		PeriodAsString = Format(SelectedPeriod, NStr("vi = 'ДФ=''гггг''';
													|ru = 'ДФ=''гггг''';
													|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
													|it = 'ДФ=''гггг''';
													|pl = 'DF=''yyyy''';
													|tr = 'DF=''yyyy'''"))
	EndIf;
	
	SetTitleToYear(ThisObject);
	
EndProcedure

&AtClient
Procedure SetSelectablePeriod(Year, Month, ChoiceMode = "")
	
	If MarkedPeriod = Date(Year, Month, 1)
		And Not YearChanged 
		And PeriodSelectionMode = ChoiceMode Then
		
		ExecuteSelection();
	EndIf; 
	
	If ValueIsFilled(ChoiceMode) Then
		SetUnselectedButtonColor();
		PeriodSelectionMode = ChoiceMode;
	EndIf;
	
	If Year < 1 Then
		Year = 1;
	EndIf; 
	
	YearChanged = False;
	SelectedPeriod = Date(Year, Month, 1);
	
	UpdateDisplay();
	
EndProcedure

&AtClient
Procedure ExecuteSelection()
	
	If SelectPeriodKind Then
		ThickDate = New Structure("Period, Horizon", SelectedPeriod, PeriodSelectionMode);
		Close(ThickDate);
	Else
		Close(SelectedPeriod);
	EndIf;
	
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
	If Item.Name = "sh_ShamsiInput_F_SelectedPeriod" Then
		SelectedPeriodOnChange(Items.SelectedPeriod);
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
