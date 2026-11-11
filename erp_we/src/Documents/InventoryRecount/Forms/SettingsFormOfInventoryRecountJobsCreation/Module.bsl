
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Warehouse = Parameters.Warehouse;
	Premise = Parameters.Premise;
	
	// filling in the details according to the routine task
	ScheduledJobAction = "";
	Parameters.Property("ScheduledJobAction", ScheduledJobAction);
	If ValueIsFilled(ScheduledJobAction) Then
		
		FillPropertyValues(ThisObject, Parameters, "ScheduledJobDescription,JobSchedule,
			|IfThereAreErrorsRepeatTheRoutineTask,IfThereAreErrorsRepeatThroughTheRoutineTask");
			
		FillPropertyValues(ThisObject, Parameters.SettingsForCreatingRecalculations, 
			"RecountByFilling,RecountBySpecialConditions, DoubtfulBinRecount,
			|RecountByFrequencySettings,RecalculationByCellsWithNegativeResiduals,
			|SplitByWorkArea, SplitByNumberOfCells, NumberOfCellsInTheTask");

		Filter_Settings = Undefined;
		Parameters.SettingsForCreatingRecalculations.Property("Filter_Settings", Filter_Settings);
		InitializeDataLayout(True, Filter_Settings);
	Else
		InitializeDataLayout(False);
	EndIf;
	//
	
	If Not ValueIsFilled(RecountByFilling) Then
		RecountByFilling = "OnlyCellsWithLeftovers";
	EndIf;
	
	If Not ValueIsFilled(RecountBySpecialConditions) Then
		RecountBySpecialConditions = "All";
	EndIf;
	
	If SplitByNumberOfCells Then
		Items.GroupNumberOfPageCells.CurrentPage = Items.GroupBinQuantityAvailable;
	Else
		Items.GroupNumberOfPageCells.CurrentPage = Items.GroupNumberOfCellsNotAvailable;
	EndIf;
	
	Items.GroupSpecialConditionsIndent.Enabled = (RecountBySpecialConditions = "ByCondition");
	
	RoutineTaskEditingMode = ValueIsFilled(ScheduledJobAction);
	Items.GroupParametersOfARoutineTask.Visible = RoutineTaskEditingMode;
	Items.CreateJobs.Title = ?(RoutineTaskEditingMode,
		NStr("vi = 'Đóng và lưu lại nhiệm vụ thường kỳ';
			|ru = 'Закрыть и сохранить регламентное задание';
			|en = 'Close and save the scheduled job'; fa = 'بستن و ذخیره وظیفه زمان‌بندی‌شده';
			|it = 'Chiudere e salvare il task di routine';
			|pl = 'Zamknij i zapisz zadanie regulaminowe';
			|tr = 'Programlı işleri kapat ve kaydet'"),
		NStr("vi = 'Tạo nhiệm vụ';
			|ru = 'Создать задания';
			|en = 'Create jobs'; fa = 'ایجاد کارها';
			|it = 'Creare i task';
			|pl = 'Utwórz zadania';
			|tr = 'Görev oluştur'"));
	Items.CustomizeAutomaticRecountCreation.Visible = Not RoutineTaskEditingMode;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SplitByNumberOfCellsOnChange(Item)
	
	If SplitByNumberOfCells Then
		Items.GroupNumberOfPageCells.CurrentPage = Items.GroupBinQuantityAvailable;
	Else
		NumberOfCellsInTheTask = 0;
		Items.GroupNumberOfPageCells.CurrentPage = Items.GroupNumberOfCellsNotAvailable;
	EndIf;
	
EndProcedure

&AtClient
Procedure RecountBySpecialConditionsOnChange(Item)
	Items.GroupSpecialConditionsIndent.Enabled = (RecountBySpecialConditions = "ByCondition");
	If RecountBySpecialConditions = "All" Then
		DoubtfulBinRecount				  = False;
		RecountByFrequencySettings 		  = False;
		RecalculationByCellsWithNegativeResiduals = False;
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateJobs(Command)
	ClearMessages();
	If Not CheckFilling() Then 
		Return
	EndIf;
	
	If ValueIsFilled(ScheduledJobAction) Then
		
		Result = New Structure("ScheduledJobAction,ScheduledJobDescription,IfThereAreErrorsRepeatTheRoutineTask,
						|IfThereAreErrorsRepeatThroughTheRoutineTask,JobSchedule");
		FillPropertyValues(Result,ThisObject);
		Result.Insert("Action","CloseAndSaveTheScheduledJob");
		
		GenerationParameters_ = New Structure;
		GenerationParameters_.Insert("NumberOfCellsInTheTask",				NumberOfCellsInTheTask);
		GenerationParameters_.Insert("Filter_Settings",						RecountFilter.Settings);
		GenerationParameters_.Insert("RecountByFilling",				RecountByFilling);
		GenerationParameters_.Insert("RecountByFrequencySettings",	RecountByFrequencySettings);
		GenerationParameters_.Insert("RecalculationByCellsWithNegativeResiduals",RecalculationByCellsWithNegativeResiduals);
		GenerationParameters_.Insert("DoubtfulBinRecount",			DoubtfulBinRecount);
		GenerationParameters_.Insert("SplitByNumberOfCells",			SplitByNumberOfCells);
		GenerationParameters_.Insert("SplitByWorkArea",			SplitByWorkArea);
		GenerationParameters_.Insert("RecountBySpecialConditions",				RecountBySpecialConditions);
		
		Result.Insert("SettingsForCreatingRecalculations", GenerationParameters_);
		Close(Result);
	Else
		GenerationParameters_ = New Structure;
		GenerationParameters_.Insert("NumberOfCellsInTheTask",				NumberOfCellsInTheTask);
		GenerationParameters_.Insert("Filter_Settings",						RecountFilter.Settings);
		GenerationParameters_.Insert("RecountByFilling",				RecountByFilling);
		GenerationParameters_.Insert("RecountByFrequencySettings",	RecountByFrequencySettings);
		GenerationParameters_.Insert("RecalculationByCellsWithNegativeResiduals",RecalculationByCellsWithNegativeResiduals);
		GenerationParameters_.Insert("DoubtfulBinRecount",			DoubtfulBinRecount);
		GenerationParameters_.Insert("SplitByNumberOfCells",			SplitByNumberOfCells);
		GenerationParameters_.Insert("SplitByWorkArea",			SplitByWorkArea);
		GenerationParameters_.Insert("Premise",	Premise);
		GenerationParameters_.Insert("Warehouse",		Warehouse);
		GenerationParameters_.Insert("RecountBySpecialConditions",				RecountBySpecialConditions);			
		
		Result = CreateTasksOnServer(GenerationParameters_);
		ShowUserNotification(NStr("vi = 'Nhiệm vụ kiểm đếm';
									|ru = 'Задания на пересчет';
									|en = 'Recount jobs'; fa = 'کارهای شمارش مجدد';
									|it = 'Task di ricalcolo';
									|pl = 'Zadania do ponownego obliczenia';
									|tr = 'Yeniden hesaplama için görev'"),, Result.MessageString);
			
		If Result.NumberOfTasksCreated > 0 Then
			Notify("Write_InventoryRecount",,ThisForm);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(New Structure("Action","Cancel"));
EndProcedure

&AtClient
Procedure CustomizeAutomaticRecountCreation(Command)
	FormParameters = New Structure("Key,OnOpeningClickTab",
		KeyForRecordingSettingsForAutomaticallyCreatingRecalculations(),"SettingsForCreatingProductRecalculations");
	OpenForm("InformationRegister.SettingsOfBinLocationWarehouses.RecordForm", FormParameters, ThisForm,,);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function CreateTasksOnServer(GenerationParameters_)
	
	Result = New Structure;
	Result.Insert("NumberOfTasksCreated", Documents.InventoryRecount.CreateJobs(GenerationParameters_));
	
	RowOfWarehousesWithQuantity = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(
		Result.NumberOfTasksCreated, 
		"job,jobs,oftasks");
	Result.Insert("MessageString", NStr("vi = 'Đã tạo %RowOfWarehousesWithQuantity% kiểm đếm.';
										|ru = 'Создано %RowOfWarehousesWithQuantity% на пересчет.';
										|en = '%RowOfWarehousesWithQuantity% is created for recount.'; fa = '%RowOfWarehousesWithQuantity% is created for recount.';
										|it = 'Generati %RowOfWarehousesWithQuantity% per il ricalcolo.';
										|pl = 'Utworzono %RowOfWarehousesWithQuantity% do ponownego przeliczenia.';
										|tr = 'Yeniden hesaplama %RowOfWarehousesWithQuantity% için oluşturuldu.'"));
	Result.MessageString = StrReplace(Result.MessageString, "%RowOfWarehousesWithQuantity%", RowOfWarehousesWithQuantity);
		
	Return Result;
	
EndFunction

#Region DataCompositionSettings

&AtServer
Procedure InitializeDataLayout(Val UseDefaultSettings, Val Settings = Undefined)
	
	DataCompositionSchema = Documents.InventoryRecount.GetTemplate("RecountFilterGroupCreation");

	URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
	
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	
	RecountFilter.Initialize(SettingsSource);
	
	If UseDefaultSettings And ValueIsFilled(Settings) Then 
		RecountFilter.LoadSettings(Settings);
	Else
		RecountFilter.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	RecountFilter.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	SetValueOfSettingsParameter(RecountFilter.Settings, "Warehouse" , Warehouse);
	SetValueOfSettingsParameter(RecountFilter.Settings, "Premise", Premise);
	
EndProcedure

&AtServer
Procedure SetValueOfSettingsParameter(Settings, ParameterName, Value)
	
	Parameter = Settings.DataParameters.Items.Find(ParameterName);
	
	If Parameter <> Undefined Then
		Parameter.Value = Value;
		Parameter.Use = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function KeyForRecordingSettingsForAutomaticallyCreatingRecalculations()
	DimensionStructure = New Structure;
	DimensionStructure.Insert("Warehouse", Warehouse);
	DimensionStructure.Insert("Premise", Premise);
	
	Return InformationRegisters.SettingsOfBinLocationWarehouses.CreateRecordKey(DimensionStructure);
EndFunction

&AtClient
Procedure JobScheduleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ScheduleDialog1 = New ScheduledJobDialog(JobSchedule);
	Notification = New CallbackDescription("JobScheduleClickCompletion", ThisForm);
	ScheduleDialog1.Show(Notification);
	
EndProcedure

&AtClient
Procedure JobScheduleClickCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Or Not TypeOf(Schedule) = Type("JobSchedule") Then
		Return;
	EndIf;
	
	JobSchedule = Schedule;
	Modified = True;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not SplitByNumberOfCells Then
		NotCheckedAttributeArray.Add("NumberOfCellsInTheTask");	
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndRegion