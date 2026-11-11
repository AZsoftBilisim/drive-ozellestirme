#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tham số lập kế hoạch làm việc cho nguồn lực sản xuất có dạng ""%1""';
							|ru = 'Параметры планирования работы рабочих центров вида РЦ ""%1""';
							|en = 'Parameters of work center operation planning of the ""%1"" work center type'; fa = 'Parameters of work center operation planning of the ""%1"" work center type';
							|it = 'Parametri di pianificazione del lavoro dei centri di lavoro del tipo RC ""%1""';
							|pl = 'Parametry planowania pracy centrów pracy rodzaju CP ""%1""';
							|tr = 'İM ""%1"" türünün iş planlama parametreleri'"),
						Parameters.ObjectData.NameOfTypeOfRC);
	
	FillPropertyValues(Object, Parameters.ObjectData);
	
	ChangeoverTime = Parameters.ObjectData.ChangeoverTime;
	ParallelLoad = Number(Parameters.ObjectData.ParallelLoad);
	
	FillInLoadUnitSelection();
	
	OperationTimeInputControl(ThisForm);
	AvailabilityControl(ThisForm);
	
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

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If ParallelLoad = 1 Then
		
		If Not ValueIsFilled(Object.UnitOfMeasureOfLoad) Then
			MessageText = NStr("vi = 'Chưa điền trường ""Đơn vị tính kết nhập"".';
								|ru = 'Поле ""Единица измерения загрузки"" не заполнено.';
								|en = '""Load unit of measure"" is required.'; fa = '""Load unit of measure"" is required.';
								|it = 'Il campo ""Unità di misura del carico"" non è compilato.';
								|pl = 'Nie wypełniono pola ""Jednostka miary obciążenia"".';
								|tr = '""Çalışma Yükü Ölçü Birimi"" alanı doldurulmadı.'");
   			CommonClientServer.MessageToUser(MessageText,, "UnitOfMeasureOfLoad", "Object", Cancel);
		EndIf; 
		
		If Object.ImportOption = Enums.WorkCenterLoadOptions.Synchronous 
			And Not Object.SetupSettingsAreUsed Then
			
			If Not ValueIsFilled(Object.OperationTime) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Thời gian làm việc"".';
									|ru = 'Поле ""Время работы"" не заполнено.';
									|en = '""Working time"" is required.'; fa = '""Working time"" is required.';
									|it = 'Il campo ""Tempo di lavoro"" non è compilato.';
									|pl = 'Nie wypełniono pola ""Rodzaj pracy"".';
									|tr = '""Çalışma Süresi"" alanı doldurulmadı.'");
	   			CommonClientServer.MessageToUser(MessageText,, "OperationTime", "Object", Cancel);
			EndIf; 
			If Not ValueIsFilled(Object.UnitOfMeasure) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Đơn vị thời gian"".';
									|ru = 'Поле ""Единица измерения времени"" не заполнено.';
									|en = '""Time unit of measure"" is required.'; fa = '""Time unit of measure"" is required.';
									|it = 'Il campo ""Unità di misura del tempo"" non è compilato.';
									|pl = 'Nie wypełniono pola ""Jednostka miary czasu"".';
									|tr = '""Zaman Ölçü Birimi"" alanı doldurulmadı.'");
	   			CommonClientServer.MessageToUser(MessageText,, "UnitOfMeasure", "Object", Cancel);
			EndIf; 
			
		EndIf; 
		
	EndIf; 
	
	If Object.SetupSettingsAreUsed Then
		
		If Not ValueIsFilled(Object.ChangeoverTimeUnit) Then
			MessageText = NStr("vi = 'Chưa điền trường ""Đơn vị thời gian chuyển đổi"".';
								|ru = 'Поле ""Единица времени переналадки"" не заполнено.';
								|en = '""Changeover time unit"" is required.'; fa = '""Changeover time unit"" is required.';
								|it = 'Il campo ""Unità del tempo di riconfigurazione"" non è compilato.';
								|pl = 'Nie wypełniono pola ""Jednostka czasu rekonfiguracji"".';
								|tr = '""Değiştirme Zamanı Birimi"" alanı doldurulmadı.'");
   			CommonClientServer.MessageToUser(MessageText,, "UnitOfMeasureOfLoad", "Object", Cancel);
		EndIf; 
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SetupSettingsAreUsedOnChange(Item)
	
	AdjustmentOptionsAreUsedWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ParallelLoadOnChange(Item)
	
	If ParallelLoad = 1
		And Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.EmptyRef") Then
		Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.Asynchronous");
	ElsIf ParallelLoad = 0
		And Object.ImportOption <> PredefinedValue("Enum.WorkCenterLoadOptions.EmptyRef") Then
		Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.EmptyRef");
	EndIf;
	
	OperationTimeInputControl(ThisForm);
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure AsynchronousLoadingOptionOnChange(Item)
	
	OperationTimeInputControl(ThisForm);
	
EndProcedure

&AtClient
Procedure DownloadOptionSynchronous2OnChange(Item)
	
	OperationTimeInputControl(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingCommand(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

#Region Changeover

&AtServer
Procedure AdjustmentOptionsAreUsedWhenChangingOnServer()

	If Object.SetupSettingsAreUsed And Object.ChangeoverTimeUnit.IsEmpty() Then
		Object.ChangeoverTimeUnit = Enums.TimeMeasureUnits.Minute;
	ElsIf Not Object.SetupSettingsAreUsed And Not Object.ChangeoverTimeUnit.IsEmpty() Then
		Object.ChangeoverTimeUnit = Enums.TimeMeasureUnits.EmptyRef();
	EndIf; 
	
	OperationTimeInputControl(ThisForm);
	AvailabilityControl(ThisForm);
	
EndProcedure

#EndRegion

#Region ParallelLoad

&AtClientAtServerNoContext
Procedure OperationTimeInputControl(Form)
	
	If Form.ParallelLoad = 1
		And Form.Object.SetupSettingsAreUsed Then
		CurrentPage = Form.Items.PageSynchronousLoadWithoutWorkTime;
	Else
		CurrentPage = Form.Items.PageSynchronousLoadWithWorkTime;
	EndIf; 

	Form.Items.PagesSynchronousLoad.CurrentPage = CurrentPage;
	
	SynchronousLoad = (Form.Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.Synchronous"));
	Form.Items.OperationTime.Enabled = SynchronousLoad;
	Form.Items.UnitOfMeasure.Enabled = SynchronousLoad;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// The mark is not filled in for readjustment
	#Region ChangeoverMark
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ChangeoverTimeUnit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetupSettingsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion

	// The mark of the filled for the unit of loading
	#Region EdEdMark
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnitOfMeasureOfLoad.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ParallelLoad");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	// The mark of the filled in for the working time
	#Region WorkingTimeMark
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperationTime.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ImportOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.WorkCenterLoadOptions.Synchronous;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure FillInLoadUnitSelection()
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	UnitsOfMeasurement.Description AS Description
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS UnitsOfMeasurement
	|WHERE
	|	NOT UnitsOfMeasurement.DeletionMark
	|	AND UnitsOfMeasurement.Owner = VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|
	|ORDER BY
	|	Description";
	
	Result = Query.Execute().Unload().UnloadColumn("Description");
	Items.UnitOfMeasureOfLoad.ChoiceList.LoadValues(Result);
	
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
	
	SettingsResult = New Structure("UnitOfMeasureOfLoad,ImportOption,
										|OperationTime,UnitOfMeasure,ChangeoverTimeUnit,
										|SetupSettingsAreUsed");
	
	FillPropertyValues(SettingsResult, Object);
	
	SettingsResult.Insert("ParallelLoad", Boolean(ParallelLoad));
	SettingsResult.Insert("ChangeoverTime", ChangeoverTime);
	
	Modified = False;
	
	Close(SettingsResult);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	ParallelLoadingIsAvailable = (Form.ParallelLoad = 1);
	
	Form.Items.ChangeoverTime.Enabled = Form.Object.SetupSettingsAreUsed;
	Form.Items.ChangeoverTimeUnit.Enabled  = Form.Object.SetupSettingsAreUsed;;
	Form.Items.UnitOfMeasureOfLoad.Enabled = ParallelLoadingIsAvailable; 
	Form.Items.AsynchronousLoadingOption.Enabled = ParallelLoadingIsAvailable;
	Form.Items.DownloadOptionSynchronous1.Enabled = ParallelLoadingIsAvailable; 
	Form.Items.DownloadOptionSynchronous2.Enabled = ParallelLoadingIsAvailable;
														
EndProcedure

#EndRegion

#EndRegion
