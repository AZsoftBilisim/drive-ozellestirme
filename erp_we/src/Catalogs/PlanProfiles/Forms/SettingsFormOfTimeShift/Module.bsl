
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("SettingsStructure") Then
		
		FillPropertyValues(ThisObject, Parameters.SettingsStructure);
		
		FillPropertyValues(ThisObject, SettingsStructure);
		
		If PeriodOffset >= 0 Then
		
			OffsetDirection = 1;
			EditedOffset = PeriodOffset;
		
		Else
		
			OffsetDirection = -1;
			EditedOffset = OffsetDirection * PeriodOffset;
		
		EndIf; 
		
	EndIf;
	
	ThePlanPeriodPerformance = CreatePeriodPresentation(New Structure("Periodicity, BeginOfPeriod, PeriodEnding", 
		Periodicity, PeriodStartPlan, PeriodEndPlan));
	
	WhenOffsetChanges(ThisObject);
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure OffsetOfThePeriodWhenChanging(Item)
	
	UpdatePeriodWhenOffsetChanges(ThisObject);

EndProcedure

&AtClient
Procedure OffsetDirectionOnChange(Item)
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
EndProcedure

&AtClient
Procedure OptionPeriodOffsetWhenChanging(Item)
	
	WhenOffsetChanges(ThisObject);
	
	UpdatePeriodWhenOffsetChanges(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInAndClose(Command)
	
	PeriodOffset = OffsetDirection * EditedOffset;
	
	FillPropertyValues(SettingsStructure, ThisObject);
	
	ShouldSaveSettings();
	Close(SettingsStructure);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function CreatePeriodPresentation(Parameters) 

	Presentation = "";
	
	BeginOfPeriod 		= Parameters.BeginOfPeriod;
	PeriodEnding	= Parameters.PeriodEnding;
	Periodicity 		= Parameters.Periodicity;
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		CurrentSessionDate = CurrentSessionDate();
	#Else 
		CurrentSessionDate = CommonClient.SessionDate();
	#EndIf
		
	PlanningClientServer.SetStartEndOfPlanPeriod(Periodicity, BeginOfPeriod, PeriodEnding, CurrentSessionDate);
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		
		FormatPeriodicityMonth = NStr("vi = 'ДФ=''ММММ гггг''';
										|ru = 'ДФ=''ММММ гггг''';
										|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
										|it = 'DF=''MMMM yyyy''';
										|pl = 'DF=''MMMM yyyy''';
										|tr = 'DF=''MMMM yyyy'''");
		If BegOfMonth(BeginOfPeriod) = BegOfMonth(PeriodEnding) Then
			Presentation = Format(BeginOfPeriod, FormatPeriodicityMonth);
		Else
			Presentation = Format(BeginOfPeriod, FormatPeriodicityMonth) + " - " + Format(PeriodEnding, FormatPeriodicityMonth);
		EndIf;
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		FormatPeriodicityDay = "DLF=DD";
		If BegOfDay(BeginOfPeriod) = BegOfDay(PeriodEnding) Then
			Presentation = Format(BeginOfPeriod, FormatPeriodicityDay);
		Else
			Presentation = Format(BeginOfPeriod, FormatPeriodicityDay) + " - " + Format(PeriodEnding, FormatPeriodicityDay);
		EndIf;
		
	Else
		
		Presentation = Format(BeginOfPeriod, "DLF=DD") + " - " + Format(PeriodEnding, "DLF=DD");
		
	EndIf;
	
	Return Presentation;

EndFunction

&AtClientAtServerNoContext
Function RecalculateBeginningOfPeriod(BeginOfPeriod, Periodicity, Val Offset, Val OffsetDirection)
	
	Offset = OffsetDirection * Offset;
	
	Result = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, Offset);
	
	Result = PlanningClientServer.CalculateStartDateOfPeriod(Result + 1, Periodicity);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function RecalculateEndOfPeriod(BeginOfPeriod, Periodicity, Val Offset, Val OffsetDirection)
	
	Offset = OffsetDirection * Offset;
	
	Result = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, Offset);
	
	Result = PlanningClientServer.CalculatePeriodEndDate(Result + 1, Periodicity);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdatePeriodWhenOffsetChanges(Form) 

	Form.PeriodStartOffset = RecalculateBeginningOfPeriod(Form.PeriodStartPlan, Form.Periodicity, Form.EditedOffset, Form.OffsetDirection);
	Form.PeriodEndOffset = RecalculateEndOfPeriod(Form.PeriodEndPlan, Form.Periodicity, Form.EditedOffset, Form.OffsetDirection);
	
	SetPeriodInWords(Form.EditedOffset, Form.Periodicity, Form.PeriodicityPresentation);
	
	Form.PeriodOffsetView = CreatePeriodPresentation(New Structure("Periodicity, BeginOfPeriod, PeriodEnding", 
																Form.Periodicity, Form.PeriodStartOffset, Form.PeriodEndOffset));
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenOffsetChanges(Form)

	If Form.OffsetOption = "CustomValue" Then
		Form.Items.Offset.Enabled = True;
		Form.Items.OffsetDirection.Enabled = True;
	Else
		Form.Items.Offset.Enabled = False;
		Form.Items.OffsetDirection.Enabled = False;
	EndIf;
	
	If Form.OffsetOption = "PreviousPeriod_" Then
		Form.EditedOffset = 1;
		Form.OffsetDirection = -1;
	ElsIf Form.OffsetOption = "CurrentPeriod" Then
		Form.EditedOffset = 0;
		Form.OffsetDirection = -1;
	ElsIf Form.OffsetOption = "PreviousYear" Then
		
		Form.OffsetDirection = -1;
		
		If Form.Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
			Form.EditedOffset = 12;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
			Form.EditedOffset = DayOfYear(EndOfYear(Form.PeriodStartPlan));
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
			Form.EditedOffset = WeekOfYear(EndOfYear(Form.PeriodStartPlan)) - 1;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
			Form.EditedOffset = 36;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
			Form.EditedOffset = 4;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
			Form.EditedOffset = 2;
		ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			Form.EditedOffset = 1;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPeriodInWords(Offset, Periodicity, PeriodicityPresentation)

	PeriodicityPresentation = TargetValueMonitoringClientServer.PeriodInWords(Offset, Periodicity);

EndProcedure

&AtClient
Procedure ShouldSaveSettings()
	
	FillPropertyValues(SettingsStructure, ThisObject);
	SaveSettingsAtServer(SettingsStructure, PlanType);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsAtServer(SettingsStructure, PlanType)
	
	ObjectKey = "UserSettings_" + PlanType;
	Common.CommonSettingsStorageSave(ObjectKey, "SettingsStructure", SettingsStructure);
	
EndProcedure

#EndRegion