
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillInServiceDetails();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = ProductDataManagementClientServer.EventNameLoadingEnd() Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	KeysList = Rows.GetKeys();
	
	If KeysList.Count() > 0 Then
		
		ImportState = InformationRegisters.MasterDataImportSettings.ImportState(KeysList);
		
		For Each RowState In ImportState Do
			
			ListLine = Rows[RowState.DataSource];
			
			FieldUsed_            = ListLine.Appearance["Used"];
			ScheduleFieldPresentation = ListLine.Appearance["SchedulePresentation"];
			
			If RowState.AutoimportIsUsed Then
				If RowState.AutoimportSchedule <> Undefined Then
					ScheduleFieldPresentation.SetParameterValue("Text", String(RowState.AutoimportSchedule));
				Else
					ScheduleFieldPresentation.SetParameterValue("Text", NStr("vi = '<chưa tùy chỉnh lịch biểu>';
																			|ru = '<расписание не настроено>';
																			|en = '<schedule is not configured>'; fa = '<schedule is not configured>';
																			|it = '<расписание не настроено>';
																			|pl = '<schedule is not configured>';
																			|tr = '<çizelge ayarlanmadı>'"));
					ScheduleFieldPresentation.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
				EndIf;
				FieldUsed_.SetParameterValue("Show", True);
			Else
				ScheduleFieldPresentation.SetParameterValue("Text", NStr("vi = '<không sử dụng kết nhập theo lịch biểu>';
																		|ru = '<загрузка по расписанию не используется>';
																		|en = '<scheduled import is not used>'; fa = '<scheduled import is not used>';
																		|it = '<загрузка по расписанию не используется>';
																		|pl = '<scheduled import is not used>';
																		|tr = '<çizelgeye göre yükleme kullanılmamaktadır>'"));
				ScheduleFieldPresentation.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
				FieldUsed_.SetParameterValue("Show", False);
			EndIf;
			
			If ValueIsFilled(ListLine.Data.ExecutionDate) Then
				
				StateProperties = Enums.ImportMasterDataStates.LoadingStateProperties(RowState.State);
				
				FieldText = String(StateProperties.State);
				If Not StateProperties.State = Enums.ImportMasterDataStates.SuccessfullyCompleted
						And Not StateProperties.State = Enums.ImportMasterDataStates.NoData1
						And Not StateProperties.State = Enums.ImportMasterDataStates.DoNotPerformed Then
					FieldText = StrTemplate(NStr("vi = '%1. Lỗi khi thực hiện lần cuối: %2';
												|ru = '%1. Ошибок при последнем выполнении: %2';
												|en = '%1. Errors upon the last execution: %2'; fa = '%1. Errors upon the last execution: %2';
												|it = '%1. Ошибок при последнем выполнении: %2';
												|pl = '%1. Errors upon the last execution: %2';
												|tr = '%1. Son gerçekleştirmedeki hatalar: %2'"), FieldText, RowState.ErrorsCount);
				EndIf;
				
				If RowState.StateIsProblematic Then
					FieldStatePresentation = ListLine.Appearance["StatePresentationOfProblem"];
				Else
					FieldStatePresentation = ListLine.Appearance["StatePresentation"];
				EndIf;
				FieldStatePresentation.SetParameterValue("Text", FieldText);
				FieldStatePresentation.SetParameterValue("TextColor", StyleColors[StateProperties.Color]);
				
			EndIf;
			
		EndDo;
		
		DataProcessors.ImportProductionMasterData.SetDateLayoutInList(Rows, "ExecutionDate");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatePresentationOfProblem Then
		
		StandardProcessing = False;
		OpenSourceMonitoring(Items.List.CurrentRow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Enable(Command)
	
	SetUsedFlag(True);
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	
	SetUsedFlag(False);
	
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StartupSettings = StartupSettings();
	If StartupSettings.AutoimportSchedule = Undefined Then
		Schedule = New JobSchedule();
	Else
		Schedule = StartupSettings.AutoimportSchedule;
	EndIf;
	
	CallbackDescription = New CallbackDescription("SetUpScheduleCompletion", ThisObject, StartupSettings);
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	ScheduleDialog1.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure ExecuteImport(Command)
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StartDownloadingData(Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure MatchingObjects(Command)
	
	OpenMatchingObjectsBySource(Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure ImportStateMonitoring(Command)
	
	OpenSourceMonitoring(Items.List.CurrentRow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ExecutionDate.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StatePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ExecutionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa thực hiện kết nhập>';
													|ru = '<загрузка не выполнялась>';
													|en = '<import was not performed>'; fa = '<import was not performed>';
													|it = '<загрузка не выполнялась>';
													|pl = '<import was not performed>';
													|tr = '<yükleme gerçekleştirilemedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	//
	ProblematicStates = Enums.ImportMasterDataStates.ProblematicStates();
	
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StatePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProblematicStates;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.StatePresentationOfProblem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ProblematicStates;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	LongTermOperationsStructure = New Structure("DataImport");
	
EndProcedure

&AtClient
Procedure SetUsedFlag(Used)
	
	SetFlagUsedOnServer(Used);
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetFlagUsedOnServer(Used)
	
	Settings = New Structure("AutoimportIsUsed", Used);
	
	For Each DataSource In Items.List.SelectedRows Do
		
		InformationRegisters.MasterDataImportSettings.RecordSourceSettings(DataSource, Settings, True);
		
	EndDo;
	
EndProcedure

&AtServer
Function StartupSettings()
	
	StartupSettings = New Structure("AutoimportIsUsed,AutoimportSchedule");
	FillPropertyValues(StartupSettings, Catalogs.SourcesToImportProductionMasterData.DataSourceSettings(Items.List.CurrentRow));
	
	Return StartupSettings;
	
EndFunction

&AtClient
Procedure SetUpScheduleCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AdditionalParameters.AutoimportSchedule = Result;
		SetScheduleOnServer(AdditionalParameters);
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetScheduleOnServer(StartupSettings)
	
	StartupSettings.AutoimportIsUsed = True;
	InformationRegisters.MasterDataImportSettings.RecordSourceSettings(Items.List.CurrentRow, StartupSettings, True);
	
EndProcedure

&AtClient
Procedure OpenMatchingObjectsBySource(DataSource)
	
	OpenForm("DataProcessor.ImportProductionMasterData.Form.MatchingObjects",
		New Structure("DataSource", DataSource),,
		DataSource);
	
EndProcedure

&AtClient
Procedure OpenSourceMonitoring(DataSource)
	
	OpenForm("DataProcessor.ImportProductionMasterData.Form.ImportStateMonitoring",
		New Structure("DataSource", DataSource),
		ThisObject,
		DataSource);
	
EndProcedure

#Region DataImport

&AtClient
Procedure StartDownloadingData(DataSource)
	
	If LongTermOperationsStructure.DataImport <> Undefined Then
		Return;
	EndIf;
	
	StartUploadingDataToServer(DataSource);
	
	If LongTermOperationsStructure.DataImport <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"DataImportCompletion", ThisObject, New Structure("DataSource", DataSource));
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = StrTemplate(NStr("vi = 'Đang kết nhập dữ liệu từ nguồn ""%1""';
														|ru = 'Выполняется загрузка данных из источника ""%1""';
														|en = 'Importing data from the ""%1"" source'; fa = 'Importing data from the ""%1"" source';
														|it = 'Выполняется загрузка данных из источника ""%1""';
														|pl = 'Importing data from the ""%1"" source';
														|tr = '""%1"" kaynağı üzerinden veriler yükleniyor'"), DataSource);
		TimeConsumingOperationsClient.WaitCompletion(
			LongTermOperationsStructure.DataImport,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartUploadingDataToServer(DataSource)
	
	ActionName = DataProcessors.ImportProductionMasterData.UploadDataAction();
	
	If DataProcessors.ImportProductionMasterData.ActionIsAlreadyInProgress(DataSource, ActionName) Then
		Common.MessageToUser(StrTemplate(NStr("vi = 'Đang kết nhập dữ liệu từ nguồn ""%1""';
												|ru = 'Загрузка данных из источника ""%1"" уже выполняется';
												|en = 'Data from the ""%1"" source is already being imported'; fa = 'Data from the ""%1"" source is already being imported';
												|it = 'Загрузка данных из источника ""%1"" уже выполняется';
												|pl = 'Data from the ""%1"" source is already being imported';
												|tr = '""%1"" kaynağı üzerinden veri yükleme zaten gerçekleştiriliyor'"), DataSource));
		Return;
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobKey         = DataProcessors.ImportProductionMasterData.KeyForPerformingActionInBackground(DataSource, ActionName);
	ExecutionParameters.BackgroundJobDescription = DataProcessors.ImportProductionMasterData.NameOfActionInBackground(ActionName);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ActionName",    ActionName);
	ProcedureParameters.Insert("DataSource", DataSource);
	
	LongTermOperationsStructure.DataImport = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ImportProductionMasterData.PerformActionInBackground",
		ProcedureParameters, ExecutionParameters);
		
EndProcedure

&AtClient
Procedure DataImportCompletion(TimeConsumingOperation, AdditionalParameters) Export
	
	LongTermOperationsStructure.DataImport = Undefined;
	
	If TimeConsumingOperation <> Undefined Then
		
		TextTitle_ = NStr("vi = 'Kết nhập dữ liệu';
							|ru = 'Загрузка данных';
							|en = 'Data import'; fa = 'ورود داده';
							|it = 'Download dei dati';
							|pl = 'Pobieranie danych';
							|tr = 'Veri yükleme'");
		MessageText = "";
		Picture       = Undefined;
		
		If TimeConsumingOperation.Status = "Error" Then
			
			MessageText = StrTemplate(NStr("vi = 'Đã hoàn tất kết nhập dữ liệu thất bại.
					|%1
					|Chi tiết xem tại chỗ làm việc ""Màn hình theo dõi trạng thái kết nhập"" hoặc trong nhật ký sự kiện.';
					|ru = 'Загрузка данных завершилась неудачно.
					|%1
					|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
					|en = 'Data is not imported.
					|%1
					|For more information, see the ""Import state monitoring"" workspace or the event log.'; fa = 'Data is not imported.
					|%1
					|For more information, see the ""Import state monitoring"" workspace or the event log.';
					|it = 'Загрузка данных завершилась неудачно.
					|%1
					|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
					|pl = 'Data is not imported.
					|%1
					|For more information, see the ""Import state monitoring"" workspace or the event log.';
					|tr = 'Veri yüklemesi başarısız oldu.
					|%1
					|Ayrıntılar için çalışma alanında ""Yükleme Durumunu İzleme""ye veya olay günlüğüne bakın.'"),
				TimeConsumingOperation.BriefErrorDescription);
			Picture = PictureLib.Error32;
			
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			ShowUserNotification(TextTitle_,,MessageText, Picture);
		EndIf;
		
	EndIf;
	
	Notify(
		ProductDataManagementClientServer.EventNameLoadingEnd(),,
		AdditionalParameters.DataSource);
	
EndProcedure

#EndRegion

#EndRegion