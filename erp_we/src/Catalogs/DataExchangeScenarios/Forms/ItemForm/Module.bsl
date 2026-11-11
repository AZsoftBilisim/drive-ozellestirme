///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var NumberOfRowToProcess;

&AtClient
Var RowsCount;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	IsNew = (Object.Ref.IsEmpty());
	
	InfobaseNode = Undefined;
	
	If IsNew
		And Parameters.Property("InfobaseNode", InfobaseNode)
		And InfobaseNode <> Undefined Then
		
		Catalogs.DataExchangeScenarios.AddImportToDataExchangeScenarios(Object, InfobaseNode);
		Catalogs.DataExchangeScenarios.AddExportToDataExchangeScenarios(Object, InfobaseNode);
		
		Description = NStr("vi = 'Kịch bản đồng bộ đối với %1';
							|ru = 'Сценарий синхронизации для %1';
							|en = 'Synchronization scenario for %1'; fa = 'Synchronization scenario for %1';
							|it = 'Scenario di sincronizzazione per %1';
							|pl = 'Scenariusz synchronizacji dla %1';
							|tr = '%1 için senkronizasyon senaryosu'");
		Object.Description = StringFunctionsClientServer.SubstituteParametersToString(Description, String(InfobaseNode));
		
		JobSchedule = Catalogs.DataExchangeScenarios.DefaultJobSchedule();
		
		Object.UseScheduledJob = True;
	Else
		// Get the schedule from the job. If it's not set, set it to "Undefined".
		// In this case, it's created on the client side when the user sets the schedule.
		JobSchedule = Catalogs.DataExchangeScenarios.GetDataExchangeExecutionSchedule(Object.Ref);
	EndIf;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	If DataSeparationEnabled Then
		
		ToolTipText = NStr("vi = 'Khoảng tối thiểu không cần nhỏ hơn 15 phút (900 giây).
                              |Thời gian thực hiện chính xác của kịch bản phụ thuộc vào mức tải của chương trình.';
                              |ru = 'Минимальный интервал не должен быть меньше 15 минут (900 секунд).
                              |Точное время выполнения сценария зависит от загруженности программы.';
                              |en = 'Minimum interval must be over 15 minutes (900 seconds).
                              |The exact scenario execution time depends on the application workload.'; fa = 'Minimum interval must be over 15 minutes (900 seconds).
                              |The exact scenario execution time depends on the application workload.';
                              |it = 'L''intervallo minimo non deve essere inferiore a 15 minuti (900 secondi).
                              |Il tempo esatto di esecuzione dello scenario dipende dal carico di lavoro del programma.';
                              |pl = 'Minimalny odstęp nie powinien być mniejszy niż 15 minut (900 sekund).
                              |Dokładny czas wykonania scenariusza zależy obciążenia programu.';
                              |tr = 'Minimum aralık 15 dakikadan (900 saniye) kısa olamaz.
                              |Komut dosyasının tam yürütme süresi program yüküne bağlıdır.'");
		
		Items.ConfigureJobSchedule.ExtendedTooltip.Title = ToolTipText;
		Items.ConfigureJobSchedule.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		
		Items.ExchangeSettingsTransportID.Visible = False;
		
		Items.ExchangeSettingsInfobaseNode.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		Items.ExchangeSettingsInfobaseNode.DropListButton = False;
		Items.GroupConfigurationInformationInSameDatabase.Visible = True;
		Items.ScriptGroupIsDisabled.Visible = Object.IsAutoDisabled;
		Items.ExecuteExchange.Visible = False;
		
	EndIf;
		
	If Not IsNew Then
		RefreshDataExchangesStates();
	EndIf;
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	For Each ExchangePlanName In SSLExchangePlans Do
		ExchangeNodesList.Add(Type("ExchangePlanRef." + ExchangePlanName));
	EndDo;
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshSchedulePresentation();
	
	SetScheduleSetupHyperlinkAvailability();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject)
	
	ValidateExchangeSettingInService(Cancel);
		
	Catalogs.DataExchangeScenarios.UpdateScheduledJobData(Cancel, JobSchedule, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_DataExchangeScenarios", WriteParameters, Object.Ref);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseScheduledJobOnChange(Item)
	
	SetScheduleSetupHyperlinkAvailability();
	
EndProcedure

&AtClient
Procedure ExchangeSettingsInfobaseNodeOnChange(Item)
	
	If DataSeparationEnabled Then
		Items.ScheduleComposition.CurrentData.TransportID = "WS";
	Else	
		Items.ScheduleComposition.CurrentData.TransportID = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeSettingsInfobaseNodeStartChoice(Item, ChoiceData, StandardProcessing)
	
	If DataSeparationEnabled Then
		
		ChoiceInitialValue = Items.ScheduleComposition.CurrentData.InfobaseNode;
		FormParameters = New Structure("ChoiceInitialValue", ChoiceInitialValue);
		
		StandardProcessing = False;
		OpenForm("Catalog.DataExchangeScenarios.Form.SelectExchangePlanNode", FormParameters, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExchangeSettings

&AtClient
Procedure ExchangeSettingsInfobaseNodeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("Type") And ExchangeNodesList.FindByValue(ValueSelected) = Undefined Then
		MessageText = NStr("vi = 'Không thể sử dụng dữ liệu có kiểu đã chọn trong biểu mẫu này.
			|Hãy chọn kiểu dữ liệu khác.';
			|ru = 'Данные выбранного типа не могут быть использованы в этой форме.
			|Выберите другой тип данных.';
			|en = 'Cannot use data of this type in this form.
			|Please select another data type.'; fa = 'Cannot use data of this type in this form.
			|Please select another data type.';
			|it = 'I dati del tipo selezionato non possono essere utilizzati in questo form.
			|Selezionate un altro tipo di dati.';
			|pl = 'Dane wybranego typu nie mogą być używane w tym formularzu.
			|Wybierz inny typ danych.';
			|tr = 'Seçilmiş veri türleri bu şekilde kullanılamaz. 
			| Başka veri türünü seçin.'");
		Field = StringFunctionsClientServer.SubstituteParametersToString("ExchangeSettings[%1].InfobaseNode", Items.ScheduleComposition.CurrentData.LineNumber-1);
		CommonClient.MessageToUser(MessageText, , Field, "Object");
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeSettingsTransportIDStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	If Items.ScheduleComposition.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillExchangeTransportKindChoiceList(
		Item.ChoiceList, 
		Items.ScheduleComposition.CurrentData.InfobaseNode);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteExchange(Command)
	
	IsNew = (Object.Ref.IsEmpty());
	
	If Modified Or IsNew Then
		
		If Not Write() Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	NumberOfRowToProcess     = 1;
	RowsCount = Object.ExchangeSettings.Count();
	
	Items.ScheduleComposition.ReadOnly = True;
	
	AttachIdleHandler("ExecuteDataExchangeAtClient", 0.1, True);
	
EndProcedure

&AtClient
Procedure ConfigureJobSchedule(Command)
	
	EditScheduledJobSchedule();
	
	RefreshSchedulePresentation();
	
EndProcedure

&AtClient
Procedure TransportSettings(Command)
	
	CurrentData = Items.ScheduleComposition.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	ElsIf Not ValueIsFilled(CurrentData.InfobaseNode) Then
		Return;
	EndIf;
	
	FormOpenParameters = TransportFormOpeningParameters(CurrentData.InfobaseNode);
	
	If FormOpenParameters = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("TransportSettings", FormOpenParameters.TransportSettings);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Peer", CurrentData.InfobaseNode);
	AdditionalParameters.Insert("TransportID", FormOpenParameters.TransportID);
	
	Notification = New CallbackDescription("SaveTransportSettings", ThisObject, AdditionalParameters);
	
	OpenForm(FormOpenParameters.FullNameOfConfigurationForm, FormParameters,,,,, 
		Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	
	CurrentData = Items.ScheduleComposition.CurrentData;
	
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.InfobaseNode) Then
		Return;
	EndIf;
	
	DataExchangeClient.GoToDataEventLogModally(CurrentData.InfobaseNode,
																	ThisObject,
																	CurrentData.CurrentAction);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EditScheduledJobSchedule()
	
	// Creating a new schedule if it is not initialized in a form on the server.
	If JobSchedule = Undefined Then
		
		JobSchedule = New JobSchedule;
		
	EndIf;
	
	Dialog = New ScheduledJobDialog(JobSchedule);
	
	// Opening a dialog box for editing the schedule.
	CallbackDescription = New CallbackDescription("EditScheduledJobScheduleCompletion", ThisObject);
	Dialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure EditScheduledJobScheduleCompletion(Schedule, AdditionalParameters) Export
		
	If Schedule <> Undefined Then
		
		If DataSeparationEnabled 
			And Schedule.RepeatPeriodInDay <> 0
			And Schedule.RepeatPeriodInDay < 15 * 60 Then
			
			Schedule.RepeatPeriodInDay = 15 * 60;
			WarningText = NStr("vi = 'Khoảng tối thiểu không cần nhỏ hơn 15 phút (900 giây).';
								|ru = 'Минимальный интервал не должен быть меньше 15 минут (900 секунд).';
								|en = 'Minimum interval must be over 15 minutes (900 seconds).'; fa = 'Minimum interval must be over 15 minutes (900 seconds).';
								|it = 'L''intervallo minimo non deve essere inferiore a 15 minuti (900 secondi).';
								|pl = 'Minimalny odstęp nie powinien być mniejszy niż 15 minut (900 sekund).';
								|tr = 'Minimum aralık 15 dakikadan (900 saniye) az olmamalıdır.'");
			ShowMessageBox(, WarningText);
			
		EndIf;
		
		JobSchedule = Schedule;
		RefreshSchedulePresentation();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshSchedulePresentation()
	
	SchedulePresentation = String(JobSchedule);
	
	If SchedulePresentation = String(New JobSchedule) Then
		
		SchedulePresentation = NStr("vi = 'Chưa đặt lịch biểu';
									|ru = 'Расписание не задано';
									|en = 'No schedule'; fa = 'No schedule';
									|it = 'Orario non è impostato';
									|pl = 'Harmonogram nie jest zadany';
									|tr = 'Plan ayarlanmadı'");
		
	EndIf;
	
	Items.ConfigureJobSchedule.Title = SchedulePresentation;
	
EndProcedure

&AtClient
Procedure SetScheduleSetupHyperlinkAvailability()
	
	Items.ConfigureJobSchedule.Enabled = Object.UseScheduledJob;
	
EndProcedure

&AtClient
Procedure ExecuteDataExchangeAtClient()
	
	If NumberOfRowToProcess > RowsCount Then // Exit from the recursion.
		
		OutputState = (RowsCount > 1);
		Status(NStr("vi = 'Đã đồng bộ dữ liệu.';
					|ru = 'Данные синхронизированы.';
					|en = 'Data is synchronized.'; fa = 'Data is synchronized.';
					|it = 'Dati sincronizzati.';
					|pl = 'Dane zostały zsynchronizowane.';
					|tr = 'Senkronizasyon tamamlandı.'"), ?(OutputState, 100, Undefined));
		
		Items.ScheduleComposition.ReadOnly = False;
		
		Return; // Exit.
		
	EndIf;
	
	CurrentData = Object.ExchangeSettings[NumberOfRowToProcess - 1];
	
	OutputState = (RowsCount > 1);
	
	MessageString = "";
	If CurrentData.CurrentAction = PredefinedValue("Enum.ActionsOnExchange.DataImport") Then
		MessageString = NStr("vi = 'Đang nhận dữ liệu từ ""%1"".';
							|ru = 'Выполняется получение данных из ""%1"".';
							|en = 'Receiving data from %1.'; fa = 'Receiving data from %1.';
							|it = 'Acquisizione dati da ""%1"" in corso.';
							|pl = 'Trwa pobieranie danych z ""%1"".';
							|tr = 'Veriler şuradan alınıyor ""%1"".'");
	ElsIf CurrentData.CurrentAction = PredefinedValue("Enum.ActionsOnExchange.DataExport") Then
		MessageString = NStr("vi = 'Đang gửi dữ liệu đến ""%1"".';
							|ru = 'Выполняется отправка данных в ""%1"".';
							|en = 'Sending data to %1.'; fa = 'Sending data to %1.';
							|it = 'Invio dati a ""%1"" in corso.';
							|pl = 'Trwa wysyłanie danych w ""%1"".';
							|tr = 'Veri gönderme ""%1"".'");
	EndIf;
	
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, 
		CurrentData.InfobaseNode);
	
	Progress = Round(100 * (NumberOfRowToProcess -1) / ?(RowsCount = 0, 1, RowsCount));
	Status(MessageString, ?(OutputState, Progress, Undefined));
	
	// Starting data exchange by setting string.
	ExecuteDataExchangeBySettingString(NumberOfRowToProcess);
	
	UserInterruptProcessing();
	
	NumberOfRowToProcess = NumberOfRowToProcess + 1;
	
	// Calling this procedure recursively.
	AttachIdleHandler("ExecuteDataExchangeAtClient", 0.1, True);
	
EndProcedure

&AtServer
Procedure RefreshDataExchangesStates()
	
	SetPrivilegedMode(True);
	
	QueryText = 
		"SELECT
		|	DataExchangeScenariosExchangeSettings.InfobaseNode AS InfobaseNode,
		|	DataExchangeScenariosExchangeSettings.DeleteExchangeTransportKind AS DeleteExchangeTransportKind,
		|	DataExchangeScenariosExchangeSettings.TransportID AS TransportID,
		|	DataExchangeScenariosExchangeSettings.CurrentAction AS CurrentAction,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult IS NULL
		|			THEN 0
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
		|			THEN 0
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|FROM
		|	Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenariosExchangeSettings
		|		LEFT JOIN InformationRegister.DataExchangesStates AS DataExchangesStates
		|		ON (DataExchangesStates.InfobaseNode = DataExchangeScenariosExchangeSettings.InfobaseNode)
		|			AND (DataExchangesStates.ActionOnExchange = DataExchangeScenariosExchangeSettings.CurrentAction)
		|WHERE
		|	DataExchangeScenariosExchangeSettings.Ref = &Ref
		|
		|ORDER BY
		|	DataExchangeScenariosExchangeSettings.LineNumber";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Object.Ref);
	
	Object.ExchangeSettings.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure ExecuteDataExchangeBySettingString(Val IndexOf)
	
	Cancel = False;
	
	// Starting data exchange.
	DataExchangeServer.ExecuteDataExchangeByDataExchangeScenario(Cancel, Object.Ref, IndexOf);
	
	// Updating tabular section data of the data exchange scenario.
	RefreshDataExchangesStates();
	
EndProcedure

&AtClient
Procedure FillExchangeTransportKindChoiceList(ChoiceList, InfobaseNode)
	
	ChoiceList.Clear();
	
	If ValueIsFilled(InfobaseNode) Then
		
		For Each Item In ConfiguredTransportTypes(InfobaseNode) Do
			ChoiceList.Add(Item.Key, Item.Value);
		EndDo;
		
	EndIf;
		
EndProcedure

&AtServerNoContext
Function ConfiguredTransportTypes(Val InfobaseNode)
	
	Result = New Structure;
	TransportTable = ExchangeMessagesTransport.ConfiguredTransportTypes(InfobaseNode);
	
	For Each String In TransportTable Do
		Alias = ExchangeMessagesTransport.TransportParameter(String.TransportID, "Alias");
		Result.Insert(String.TransportID, Alias);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ValidateExchangeSettingInService(Cancel)
	
	If DataSeparationEnabled Then
		
		ExchangeSettings = Object.ExchangeSettings.Unload();
		ExchangeSettings.GroupBy("InfobaseNode,TransportID,CurrentAction");
		Object.ExchangeSettings.Load(ExchangeSettings);
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	ExchangeSettings.InfobaseNode AS InfobaseNode,
			|	ExchangeSettings.CurrentAction AS CurrentAction
			|INTO TT_ExchangeSettings
			|FROM
			|	&ExchangeSettings AS ExchangeSettings
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TT_ExchangeSettings.InfobaseNode AS InfobaseNode
			|INTO TT_Load
			|FROM
			|	TT_ExchangeSettings AS TT_ExchangeSettings
			|WHERE
			|	TT_ExchangeSettings.CurrentAction = VALUE(Enum.ActionsOnExchange.DataImport)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TT_ExchangeSettings.InfobaseNode AS InfobaseNode
			|INTO TT_Upload0
			|FROM
			|	TT_ExchangeSettings AS TT_ExchangeSettings
			|WHERE
			|	TT_ExchangeSettings.CurrentAction = VALUE(Enum.ActionsOnExchange.DataExport)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(TT_Upload0.InfobaseNode, TT_Load.InfobaseNode) AS InfobaseNode,
			|	CASE
			|		WHEN TT_Upload0.InfobaseNode IS NULL
			|			THEN 1
			|		WHEN TT_Load.InfobaseNode IS NULL
			|			THEN 2
			|	END AS MissingAction
			|FROM
			|	TT_Load AS TT_Load
			|		FULL JOIN TT_Upload0 AS TT_Upload0
			|		ON TT_Load.InfobaseNode = TT_Upload0.InfobaseNode
			|WHERE
			|	(TT_Upload0.InfobaseNode IS NULL
			|			OR TT_Load.InfobaseNode IS NULL)";
		
		Query.SetParameter("ExchangeSettings", ExchangeSettings);
		
		Result = Query.Execute();
		
		If Not Result.IsEmpty() Then
			
			Cancel = True;
			
			Selection = Result.Select();
			
			While Selection.Next() Do
				
				If Selection.MissingAction = 1 Then
					MessageTemplate = NStr("vi = 'Đối với cơ sở thông tin ""%1"" không đủ thao tác gửi dữ liệu';
											|ru = 'Для информационной базы ""%1"" не хватает действия по отправке данных';
											|en = 'An action to send data is missing for infobase ""%1""'; fa = 'An action to send data is missing for infobase ""%1""';
											|it = 'Per l''infobase ""%1"" manca l''azione di invio dati';
											|pl = 'Dla bazy informacyjnej ""%1"" nie wystarcza czynności do wysyłki danych';
											|tr = '""%1"" Infobase''i için veri gönderimi işlemi eksik'");
				Else
					MessageTemplate = NStr("vi = 'Đối với cơ sở thông tin ""%1"" không đủ thao tác nhận dữ liệu';
											|ru = 'Для информационной базы ""%1"" не хватает действия по получению данных';
											|en = 'An action to receive data is missing for infobase ""%1""'; fa = 'An action to receive data is missing for infobase ""%1""';
											|it = 'Per l''infobase ""%1"" manca l''azione di ricezione dati';
											|pl = 'Dla bazy informacyjnej  ""%1"" nie wystarcza czynności do otrzymania danych';
											|tr = '""%1"" Infobase''i için veri alımı işlemi eksik'");
				EndIf;
				
				MessageText = StrTemplate(MessageTemplate, Selection.InfobaseNode);
				
				Common.MessageToUser(MessageText);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
		
	For Each Transport In ExchangeMessagesTransport.TableOfTransportParameters() Do
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("ExchangeSettingsTransportID");
			
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ExchangeSettings.TransportID");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Transport.TransportID;
		
		Item.Appearance.SetParameterValue("Text", Transport.Alias);
		
	EndDo;
		
EndProcedure

&AtServer
Function TransportFormOpeningParameters(Node)

	TransportID = ExchangeMessagesTransport.DefaultTransport(Node);
	
	If Not ValueIsFilled(TransportID) Then
		Return Undefined;
	EndIf;
	
	FullNameOfConfigurationForm = ExchangeMessagesTransport.FullNameOfConfigurationForm(TransportID);
	TransportSettings = ExchangeMessagesTransport.TransportSettings(Node, TransportID);
	
	Result = New Structure;
	Result.Insert("TransportID", TransportID);
	Result.Insert("FullNameOfConfigurationForm", FullNameOfConfigurationForm);
	Result.Insert("TransportSettings", TransportSettings);
	
	Return Result;

EndFunction

&AtClient
Procedure SaveTransportSettings(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ExchangeMessageTransportServerCall.SaveTransportSettings(
		AdditionalParameters.Peer,
		AdditionalParameters.TransportID,
		Result);
	
EndProcedure

#EndRegion
