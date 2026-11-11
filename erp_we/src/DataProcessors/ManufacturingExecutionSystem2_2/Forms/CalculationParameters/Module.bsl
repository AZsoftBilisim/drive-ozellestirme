
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("UUID") Then
		CalledFormID = Parameters.UUID;
	Else
		CalledFormID = New UUID;
	EndIf;
	
	RestoreFormSettings();
	
	If Parameters.Property("Department") Then
		Department = Parameters.Department;
	EndIf;
	If Parameters.Property("References") Then
		References = Parameters.References;
	EndIf;
	If Parameters.Property("ProductionStages") Then
		ProductionStages = Parameters.ProductionStages;
	EndIf;
	
	UpdatePresentationOfPlanningModels();
	ManagingVisibilityOfPlanningMoment(ThisObject);
	FillInTimeForRegistration(ThisObject);
	
	Items.PlanningModelsPresentation.InputHint = Reports.OperationTimetableChart2_2.PresentationOfEmptyModel();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheTimeOfPlanningTheOptionsWhenYouChange(Item)
	
	SaveFormSettings();
	ManagingVisibilityOfPlanningMoment(ThisObject);
	
EndProcedure

&AtClient
Procedure PlanningModelsPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription("EditingPlanningModelsCompletion", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("UUID", ThisObject.UUID);
	FormParameters.Insert("AddressOfPlanningModel", PlacePlanningModelsInRepository());
	
	OpenForm("DataProcessor.ManufacturingExecutionSystem2_2.Form.SelectPlanningModels",
		FormParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PlanningModelsPresentationClearing(Item, StandardProcessing)
	
	PlanningModels.Clear();
	SaveFormSettings();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInTimeForRegistration(ThisObject);
	
EndProcedure

&AtClient
Procedure PlanningHorizonOnChange(Item)
	
	SaveFormSettings();
	
EndProcedure

&AtClient
Procedure PlanningTimepointOnChange(Item)
	
	SaveFormSettings();
	
EndProcedure

&AtClient
Procedure ReferencesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;	
	If Not CheckFilling() Then	
		Return;	
	EndIf;
	
	CallbackDescription = New CallbackDescription("ReferencesStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("References", References.UnloadValues());
	
	OpenForm("DataProcessor.ManufacturingExecutionSystem2_2.Form.SelectReferences",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ReferencesStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	If Not ClosingResult = Undefined Then
		
		ProductionStages.Clear();
		References.LoadValues(ClosingResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("StagesStartOfSelectionCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("References", References.UnloadValues());
	FormParameters.Insert("Stages", ProductionStages.UnloadValues());
	
	OpenForm("DataProcessor.ManufacturingExecutionSystem2_2.Form.SelectStages",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
	
&AtClient
Procedure StagesStartOfSelectionCompletion(ClosingResult, AdditionalParameters) Export
	
	If Not ClosingResult = Undefined Then
		
		ProductionStages.LoadValues(ClosingResult);
				
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CalculateASchedule(Command)
	
	Cancel = False;
	CheckParametersBeforeCalculation(Cancel);
	
	If Not Cancel Then
		Result = CalculationParameters();
		Close (Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RestoreFormSettings()
	
	FormSettings = FormDataSettingsStorage.Load(ObjectKeyFormSettings(), "FormSettings");
	If ValueIsFilled(FormSettings) And TypeOf(FormSettings) = Type("Structure") Then
		For Each Setting In FormSettings Do
			If Setting.Key = "PlanningModels" Then
				PlanningModels.Load(Setting.Value);
			Else
				ThisObject[Setting.Key] = Setting.Value;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	SettingsStructure = SavingSettings();
	
	FillPropertyValues(SettingsStructure, ThisForm);
	If SettingsStructure.Property("PlanningModels") Then
		SettingsStructure.Insert("PlanningModels", PlanningModels.Unload());
	EndIf;
	
	FormDataSettingsStorage.Save(ObjectKeyFormSettings(), "FormSettings", SettingsStructure);
	
EndProcedure

&AtServer
Function ObjectKeyFormSettings()
	
	Return "PostoperativePlanningCalculationParameters";
	
EndFunction

&AtServer
Function SavingSettings()
	
	Result = New Structure;
	Result.Insert("PlanningHorizon");
	Result.Insert("PlanningModels");
	Result.Insert("PlanningTimepoint");
	Result.Insert("MomentOfPlanningOption");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure ManagingVisibilityOfPlanningMoment(Form)
	
	If Form.MomentOfPlanningOption = 0 Then
		#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
			CurDateTime = CurrentSessionDate();
		#Else
			CurDateTime = CommonClient.SessionDate();
		#EndIf
		
		FormatDateTime = "DLF=DT";
		Form.Items.TheTimeOfPlanningTheCurrentTime.Title = Format(CurDateTime, FormatDateTime);
	EndIf;
	
	Form.Items.TheTimeOfPlanningTheCurrentTime.Visible = (Form.MomentOfPlanningOption = 0);
	Form.Items.PlanningTimepoint.Visible = Not (Form.MomentOfPlanningOption = 0);
	
EndProcedure

&AtClient
Procedure EditingPlanningModelsCompletion(ClosingResult, AdditionalParameters) Export
	
	EditingSchedulingModelsCompletionOnServer(ClosingResult);
	
EndProcedure

&AtServer
Procedure EditingSchedulingModelsCompletionOnServer(ClosingResult) 
	
	If IsTempStorageURL(ClosingResult) Then
		ResultFromRepository = GetFromTempStorage(ClosingResult);
		If TypeOf(ResultFromRepository) = Type("ValueTable") Then
			
			PlanningModels.Load(ResultFromRepository);
			SaveFormSettings();
			
			UpdatePresentationOfPlanningModels();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationOfPlanningModels()
	
	If ValueIsFilled(PlanningModels) Then
		
		Presentation = "";
		For Each String In PlanningModels Do
			
			If String.UseAvailabilityReserve Then
				ReservePresentation = NStr("vi = 'có dự trữ';
											|ru = 'с резервом';
											|en = 'with reserve'; fa = 'with reserve';
											|it = 'con le scorte';
											|pl = 'z rezerwą';
											|tr = 'rezervli'");
			Else
				ReservePresentation = NStr("vi = 'không có dự phòng';
											|ru = 'без резерва';
											|en = 'no reserve'; fa = 'no reserve';
											|it = 'senza scorte';
											|pl = 'bez rezerwy';
											|tr = 'rezervsiz'");
			EndIf;
			ScriptPresentation = ?(ValueIsFilled(String.PlanningScenario), String.PlanningScenario, "");
			
			Presentation = Presentation
				+ ?(ValueIsFilled(Presentation), "; ", "")
				+ String.PlanningModel
				+ " ("
				+ ScriptPresentation
				+ ?(ValueIsFilled(ScriptPresentation), ",", "")
				+ ReservePresentation
				+ ")";
			
		EndDo;
		
	Else
		Presentation = "";
	EndIf;
	
	PlanningModelsPresentation = Presentation;
	
EndProcedure

&AtServer
Function CalculationParameters()
	
	CalculationParameters = DataProcessors.ManufacturingExecutionSystem2_2.ParametersForCalculatingOperationalSchedule();
	
	FillPropertyValues(CalculationParameters, Object);
	FillPropertyValues(CalculationParameters, ThisObject);
	
	FillInCalculationParametersDeadlines(CalculationParameters);
	FillInCalculationParametersSession(CalculationParameters);
	
	For Each Parameter In CalculationParameters Do
		If TypeOf(Parameter.Value) = Type("FormDataCollection") Then
			CalculationParameters.Insert(Parameter.Key, Parameter.Value.Unload());
		EndIf;
	EndDo;
	
	Result = PutToTempStorage(CalculationParameters, CalledFormID);
	Return Result;
	
EndFunction

&AtServer
Procedure FillInCalculationParametersDeadlines(CalculationParameters)
	
	If MomentOfPlanningOption = 0 Then
		CalculationParameters.Insert("PlanningTimepoint", CurrentSessionDate());
		CalculationParameters.Insert("OperationalCalculation", True);
	Else
		CalculationParameters.Insert("PlanningTimepoint", PlanningTimepoint.Date);
	EndIf;
	
	If ValueIsFilled(StandardTimeToRegisterOperationExecution)
		And ValueIsFilled(StandardTimeToRegisterOperationExecutionUnit) Then
		TimeToRegisterSeconds = 
			StandardTimeToRegisterOperationExecution * UnitOfTimeInSeconds(StandardTimeToRegisterOperationExecutionUnit);
		CalculationParameters.Insert("StandardTimeToRegisterOperationExecution", TimeToRegisterSeconds);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCalculationParametersSession(CalculationParameters)
	
	CalculationParameters.Insert("SessionNumber", InfoBaseSessionNumber());
	CalculationParameters.Insert("SessionStarted", SessionStarted());
	CalculationParameters.Insert("CurrentUser", Users.CurrentUser());
	
EndProcedure

Function SessionStarted()
	
	SessionNumber = InfoBaseSessionNumber();
	SessionStarted = '00010101';
	
	SetPrivilegedMode(True);
	Sessions = GetInfoBaseSessions();
	SetPrivilegedMode(False);
	
	For Each Session In Sessions Do
		If Session.SessionNumber = SessionNumber Then
			SessionStarted = Session.SessionStarted;
		EndIf;
	EndDo;
	
	Return SessionStarted;
	
EndFunction

&AtServer
Function PlacePlanningModelsInRepository()
	
	ModelTable = PlanningModels.Unload();
	Result = PutToTempStorage(ModelTable);
	Return Result;
	
EndFunction

&AtClient
Procedure CheckParametersBeforeCalculation(Cancel)
	
	CheckInstalledSelections(Cancel);
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckInstalledSelections(Cancel)
	
	SelectionIsNotEstablished = ValueIsFilled(References);
	SelectionStagesAreSet = ValueIsFilled(ProductionStages);
	ScenariosAreUsed = ScenariosAreUsed();
	
	Errors = Undefined;
	
	If SelectionIsNotEstablished And ScenariosAreUsed Then
		
		FieldPresentation = NStr("vi = 'Lệnh';
								|ru = 'Распоряжения';
								|en = 'References'; fa = 'مراجع';
								|it = 'Disposizioni';
								|pl = 'Zamówienia';
								|tr = 'Talimatlar'");
		MessageText = NStr("vi = 'Để khấu trừ bằng cách sử dụng các kịch bản quy hoạch, lựa chọn không thể được thiết lập.';
							|ru = 'При расчете с использованием сценариев планирования отбор не может быть установлен.';
							|en = 'Filter cannot be set while calculating using planning scenarios.'; fa = 'Filter cannot be set while calculating using planning scenarios.';
							|it = 'Durante il calcolo con l''utilizzo di scenari della pianificazione la selezione non può essere impostata.';
							|pl = 'Przy obliczeniach z wykorzystaniem scenariuszy planowania dobór nie może być ustawiony.';
							|tr = 'Planlama senaryoları kullanılarak hesaplama yapılırken herhangi bir filtre yapılandırılamaz.'");
		ErrorText = CommonClientServer.FillingErrorText(
			"Field", "Correctness", FieldPresentation,,, MessageText);
		
		Field = "References";
		CommonClientServer.AddUserError(
			Errors, Field, ErrorText, Undefined);
		
	EndIf;
	
	If SelectionStagesAreSet And ScenariosAreUsed Then
		
		FieldPresentation = NStr("vi = 'Công đoạn sản xuất';
								|ru = 'Этапы производства';
								|en = 'Production stages'; fa = 'مراحل تولید';
								|it = 'Fasi di produzione';
								|pl = 'Etapy produkcji';
								|tr = 'Üretim aşamaları'");
		MessageText = NStr("vi = 'Để khấu trừ bằng cách sử dụng các kịch bản quy hoạch, lựa chọn không thể được thiết lập.';
							|ru = 'При расчете с использованием сценариев планирования отбор не может быть установлен.';
							|en = 'Filter cannot be set while calculating using planning scenarios.'; fa = 'Filter cannot be set while calculating using planning scenarios.';
							|it = 'Durante il calcolo con l''utilizzo di scenari della pianificazione la selezione non può essere impostata.';
							|pl = 'Przy obliczeniach z wykorzystaniem scenariuszy planowania dobór nie może być ustawiony.';
							|tr = 'Planlama senaryoları kullanılarak hesaplama yapılırken herhangi bir filtre yapılandırılamaz.'");
		ErrorText = CommonClientServer.FillingErrorText(
			"Field", "Correctness", FieldPresentation,,, MessageText);
		
		Field = "ProductionStages";
		CommonClientServer.AddUserError(
			Errors, Field, ErrorText, Undefined);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

&AtClient
Function ScenariosAreUsed()
	
	Result = False;
	
	For Each String In PlanningModels Do
		If ValueIsFilled(String.PlanningScenario) Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function FreeTimeForRegistration(Department)
	
	Return Common.ObjectAttributesValues(
		Department, "StandardTimeToRegisterOperationExecution, StandardTimeToRegisterOperationExecutionUnit");
	
EndFunction

&AtServer
Function UnitOfTimeInSeconds(Ed)
	
	If ValueIsFilled(Ed) Then
		If Ed = Enums.TimeMeasureUnits.Second Then
			Result = 1;
		ElsIf Ed = Enums.TimeMeasureUnits.Minute Then
			Result = 60;
		ElsIf Ed = Enums.TimeMeasureUnits.Hour Then
			Result = 3600;
		ElsIf Ed = Enums.TimeMeasureUnits.Day
			Or Ed = Enums.TimeMeasureUnits.Days1 Then
			Result = 86400;
		ElsIf Ed = Enums.TimeMeasureUnits.Month Then
			Result = 86400 * 30;
		ElsIf Ed = Enums.TimeMeasureUnits.Year Then
			Result = 86400 * 365;
		Else
			Result = 0;
		EndIf;
	Else
		Result = 1;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInTimeForRegistration(Form)
	
	If ValueIsFilled(Form.Department) Then
		FillingValues = FreeTimeForRegistration(Form.Department);
		FillPropertyValues(Form, FillingValues);
	Else
		Form.StandardTimeToRegisterOperationExecution = 0;
	EndIf;
	
EndProcedure

#EndRegion
