
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AttributesValues = ParametersOfWorkCenterView(CommandParameter);
	
	If Not ValueIsFilled(CommandParameter) Or AttributesValues.IsFolder Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
								|ru = 'Команда не может быть выполнена для указанного объекта!';
								|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
								|it = 'Il comando non può essere eseguito per oggetto indicato!';
								|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
								|tr = 'Belirtilen nesne için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	
	If AttributesValues.UseAvailabilityAccordingToSchedule Then
		WorkMode = PredefinedValue("Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule");
	Else
		WorkMode = PredefinedValue("Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("WorkMode", WorkMode);
	FormParameters.Insert("WorkCenterType", CommandParameter);
	FormParameters.Insert("BeginOfPeriod", CommonClient.SessionDate());
	
	OpenForm(
		"DataProcessor.AvailabilityOfWorkCenterTypes.Form",
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

&AtServer
Function ParametersOfWorkCenterView(Ref)
	
	AttributesValues = Common.ObjectAttributesValues(Ref, "
				|IsFolder,
				|Presentation,
				|UseAvailabilityAccordingToSchedule,
				|PlanOperationsOfWorkCenters");

	Return AttributesValues;
	
EndFunction

#EndRegion
