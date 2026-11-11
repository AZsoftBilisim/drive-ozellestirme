#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters = Undefined Then
		Cancel = True;
	Else
		Department = Parameters.Department;
		Factor = Parameters.Factor;
		IndicatorValue = Parameters.IndicatorValue;
		Period = Parameters.ValidFrom;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ValidFromStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	TMCommonUseClient.StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, Period, ThisForm, Notification);
	
EndProcedure

// Continuation of the procedure is valid at the beginning of the election, see above
//
&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidFromTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing, Period, MonthLine);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	If RecordSettingsForMetricValues() Then
		
		Notify("Setting_SettingMetricValuesForCostAllocation");
		
		DisplayValues = New Structure();
		DisplayValues.Insert("Department",      Department);
		DisplayValues.Insert("Factor",         Factor);
		DisplayValues.Insert("IndicatorValue", IndicatorValue);
		DisplayValues.Insert("Period",             Period);
		
		Close(DisplayValues);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function RecordSettingsForMetricValues()
	
	Try
		RecordManager = InformationRegisters.IndicatorValuesToAllocateCosts.CreateRecordManager();
		RecordManager.Period = Period;
		RecordManager.Department = Department;
		RecordManager.Factor = Factor;
		RecordManager.IndicatorValue = IndicatorValue;
		RecordManager.Write();
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion






