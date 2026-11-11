#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tham số lập kế hoạch làm việc trong lịch biểu sản xuất dạng nguồn lực sản xuất ""%1""';
							|ru = 'Параметры планирования работы в графике производства вида РЦ ""%1""';
							|en = 'Parameters of work planning in the production schedule of the ""%1"" work center type'; fa = 'Parameters of work planning in the production schedule of the ""%1"" work center type';
							|it = 'Parametri di pianificazione del lavoro nel grafico di produzione del tipo RC (Centro di lavoro) ""%1""';
							|pl = 'Parametry planowania pracy w harmonogramie produkcji rodzaju CP ""%1""';
							|tr = 'İM ""%1"" türünün üretim programındaki iş planlama parametreleri'"),
						Parameters.ObjectData.NameOfTypeOfRC);
	
	FillPropertyValues(Object, Parameters.ObjectData);
	
	PlanningInterval = Parameters.ObjectData.PlanningInterval;
	AvailabilityControl = Number(Parameters.ObjectData.UseAvailabilityAccordingToSchedule);
	EnterAvailabilityForWorkCenterType = Number(Parameters.ObjectData.EnterAvailabilityForWorkCenterType);
	
	MinimumSignificantBufferInTheAbsenceOfAvailabilityControl = Parameters.ObjectData.MinimumSignificantBuffer;
	
	WhenChangingAvailabilityControl(ThisForm);
	AvailabilityControl(ThisForm);
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour
		Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Items.AvailabilityInputMethodSummary.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		StandardProcessing = False;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		CommonClient.ShowFormClosingConfirmation(ClosingNotification_, Cancel, Exit, QueryText,
			WarningText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AvailabilityControl1OnChange(Item)
	
	WhenChangingAvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure AvailabilityControl2OnChange(Item)
	
	WhenChangingAvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure HowToEnterAvailabilityByWorkCentersOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure AvailabilityInputMethodSummaryOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingCommand(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure WhenChangingAvailabilityControl(Form)

	If Form.AvailabilityControl = 1 Then
		Form.Items.PagesParametersRelatedToAvailability.CurrentPage = Form.Items.PageParametersAvailabilityIsControlled;
	Else
		Form.Items.PagesParametersRelatedToAvailability.CurrentPage = Form.Items.PageParametersAvailabilityIsNotControlled;
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	AccessibilityIsIntroducedInSummary = (Form.EnterAvailabilityForWorkCenterType = 1);
	
	Form.Items.NumberOfWorkCenters.Enabled = AccessibilityIsIntroducedInSummary;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()

	ClearMessages();
	
	If Not CheckFilling() Then
		Return
	EndIf;
	
	SettingsResult = New Structure("NumberOfWorkCenters, AvailabilityControl, MinimumSignificantBuffer");
	FillPropertyValues(SettingsResult, Object);
	
	SettingsResult.Insert("UseAvailabilityAccordingToSchedule", Boolean(AvailabilityControl));
	SettingsResult.Insert("EnterAvailabilityForWorkCenterType", Boolean(EnterAvailabilityForWorkCenterType));
	
	If AvailabilityControl = 0 Then
		SettingsResult.Insert("MinimumSignificantBuffer", MinimumSignificantBufferInTheAbsenceOfAvailabilityControl);
	EndIf; 
	
	Modified = False;
	
	Close(SettingsResult);
	
EndProcedure

#EndRegion
