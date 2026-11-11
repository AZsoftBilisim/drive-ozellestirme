#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Dashboard = Undefined;
	Parameters.Property("Dashboard", Dashboard);
	UpdatingServerSettingsStructure(Dashboard);
	
	CurrentVersionOfClientApplicationInterface = ClientApplication.CurrentInterfaceVariant();
	CurrentUser = Users.CurrentUser();
	
	Dashboards.Parameters.SetParameterValue("CurrentUser", CurrentUser);
	
	If Not IsBlankString(Parameters.IDOfTheAnalysisOption) Then
		AnalysisModeOfTheRelated = True;
		
		// Let's set the title
		AnalysisOption = TargetValueMonitoringServerCall.GetPropertiesOfAnalysisVariantById(
			Parameters.IDOfTheAnalysisOption);
		VariantAnalysisLink = AnalysisOption.Ref; // CatalogRef.AnalysisOptionsOfTargetValues - 
		NameOfAnalysisOption = VariantAnalysisLink.Description;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chỉ số được phân tích ""%1""';
				|ru = 'Анализируемый показатель ""%1""';
				|en = 'Analyzed indicator ""%1""'; fa = 'Analyzed indicator ""%1""';
				|it = 'Indice analizzato ""%1""';
				|pl = 'Analizowany wskaźnik ""%1""';
				|tr = 'Analiz edilen gösterge ""%1""'"),
			NameOfAnalysisOption);
		AutoTitle = Not AnalysisModeOfTheRelated;
		
		Parameters.Property("DemoMode", DemoMode);
		
		MonitorCompositionTable = FormDataToValue(Parameters.MonitorContent, Type("ValueTable"));
		DynamicParameterAddresses = New ValueStorage(MonitorCompositionTable);
	EndIf;
	
	RegisterPersistentCommands();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	#If MobileClient Then
	Items.DashboardsGroup.Visible = False;
	#Else
	Items.Dashboards.CurrentRow = SettingsStructure.Dashboard;
	#EndIf
	InitializeAutoUpdateHandler();
	InitializeFirstRunHandler();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		SaveDefaultDashboard(SettingsStructure.Dashboard);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Entry_MCPDashboard" Then
		CurrentData = Items.Dashboards.CurrentData;
		If CurrentData <> Undefined
			And CurrentData.Ref = Source Then
			UpdatingServerSettingsStructure(Source);
			InitializeAutoUpdateHandler();
			UpdateMonitorCompositionClient(True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeDisplaySettings()
	If SettingsStructure.AutomaticCalculationOfNumberOfColumns Then
		SettingsStructure.Insert("NumberOfIndicatorMonitorColumns",
			CalculateNumberOfColumnsOfIndicatorMonitor());
	EndIf;
	UpdateMonitorCompositionClient();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStatusOnChange(Item)
	SetCustomParameter(ThisObject, "FilterStatus", FilterStatus);
	
	// It is necessary to update the number of displayed columns by setting up the dashboard,
	// since the selection of indicators can adjust the number of displayed columns
	UpdatingServerSettingsStructure(SettingsStructure.Dashboard);
	
	UpdateMonitorCompositionClient();
EndProcedure

&AtClient
Procedure ControlCycleOnChange(Item)
	SetCustomParameter(ThisObject, "ControlCycle", ControlCycle);
	
	// It is necessary to update the number of displayed columns by setting up the dashboard,
	// since the selection of indicators can adjust the number of displayed columns
	UpdatingServerSettingsStructure(SettingsStructure.Dashboard);
	
	UpdateMonitorCompositionClient();
EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Item - FormField - 
// 	StandardProcessing - Boolean - 
&AtClient
Procedure Attachable_OpenIndicatorAnalysisByClicking(Item, StandardProcessing)
	StandardProcessing = False;
	
	IDOfTheAnalysisOption = GetElementIDByNameWithoutPosition(Item.Name);
	
	AnalysisOption = TargetValueMonitoringServerCall.GetReferenceToCatalogById(
		"AnalysisOptionsOfTargetValues", IDOfTheAnalysisOption);

	Filter = New Structure("AnalysisOptionFilter, DemoMode", AnalysisOption, DemoMode);
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("GenerateOnOpen", True);
		
	OpenForm("Report.PerformanceDashboard.Form.AnalysisOptionPrintForm",
		FormParameters, 
		ThisObject, 
		New UUID());
EndProcedure

#EndRegion
 
#Region FormTableItemsEventHandlersDashboards

&AtClient
Procedure DashboardsSelection(Item, RowSelected, Field, StandardProcessing)
	
	AttachIdleHandler("Attachable_DashboardsSelection", 0.5, True);
	
EndProcedure

&AtClient
Procedure DashboardsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	OpenForm("Catalog.PerformanceDashboards.ObjectForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure DashboardsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtServerNoContext
Procedure DashboardsOnGetDataAtServer(TagName, Settings, Rows)
	
	ImageMarkedForDeletion = PutToTempStorage(PictureLib.ItemMarkedForDeletion);
	
	For Each String In Rows Do
		ListLine = String.Value.Data;
		If ListLine.DeletionMark Then
			ListLine.Icon = ImageMarkedForDeletion;
		Else
			ListLine.Icon = GetURL(String.Key, "Icon");
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Change(Command)

	CurrentData = Items.Dashboards.CurrentData;
	If CurrentData <> Undefined Then
		OpenForm("Catalog.PerformanceDashboards.ObjectForm", New Structure("Key", CurrentData.Ref), ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	InitializeAutoUpdateHandler();
	
	UpdateMonitorCompositionClient(True);
EndProcedure

&AtClient
Procedure SaveReportSnapshot(Command)

	If ValueIsFilled(SettingsStructure.Dashboard) Then
		SaveUserReportSnapshot();
	EndIf;

EndProcedure

&AtClient
Procedure UpdateReportsSnapshots(Command)
	
	TimeConsumingOperation = UpdateUserReportsSnapshots();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AfterReportsSnapshotsUpdated", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure AfterReportsSnapshotsUpdated(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = NStr("vi = 'Đã xảy ra lỗi cập nhật ảnh chụp nhanh báo cáo:';
							|ru = 'Произошла ошибка обновления снимков отчетов:';
							|en = 'An error occurred when updating the report snapshots:'; fa = 'An error occurred when updating the report snapshots:';
							|it = 'Произошла ошибка обновления снимков отчетов:';
							|pl = 'An error occurred when updating the report snapshots:';
							|tr = 'Raporun anlık görüntüleri güncellenirken hata oluştu:'") + Chars.LF
			+ Result.BriefErrorDescription;
	Else
		MessageText = NStr("vi = 'Đã cập nhật ảnh chụp nhanh báo cáo của người sử dụng.';
							|ru = 'Снимки отчетов пользователя актуализированы.';
							|en = 'User report snapshots are updated.'; fa = 'User report snapshots are updated.';
							|it = 'Снимки отчетов пользователя актуализированы.';
							|pl = 'User report snapshots are updated.';
							|tr = 'Kullanıcı raporlarının anlık görüntüleri güncellendi.'");
	EndIf;
	
	CommonClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure ReportsSnapshots(Command)

	OpenForm("InformationRegister.ReportsSnapshots.ListForm",
		New Structure("User, CatalogNameReportOptions", UsersClient.CurrentUser(),
		"PerformanceDashboards"));

EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_AnalysisOfInterrelatedAnalysisOptions(Command)
	CommandName = Command.Name;
	
	IDOfTheAnalysisOption = GetElementIDByNameWithoutPosition(CommandName);
	CleanCommandName = GetCleanCommandName(CommandName);
	
	FormParameters = New Structure;
	FormParameters.Insert("IDOfTheAnalysisOption");
	FormParameters.Insert("SearchType");
	FormParameters.Insert("ForceDataUpdates");
	FormParameters.Insert("MonitorContent");
	FormParameters.Insert("DemoMode");
	FormParameters.Insert("IDOfTheAnalysisOption", IDOfTheAnalysisOption);
	FormParameters.Insert("SearchType", CleanCommandName);
	FormParameters.Insert("ForceDataUpdates", True);
	FormParameters.Insert("MonitorContent", MonitorContent);
	FormParameters.Insert("DemoMode", DemoMode);
		
	OpenForm("Report.PerformanceDashboard.Form.PerformanceDashboardForm", FormParameters, ThisObject,
		IDOfTheAnalysisOption);
EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient 
Procedure Attachable_ChangeChartAnalysisObject(Command)
	If Not Items[Command.Name].Check Then
		MetricIdentifier = GetElementIDByNameWithoutPosition(Command.Name);
		
		AnalysisOption = TargetValueMonitoringServerCall.GetReferenceToCatalogById(
			"AnalysisOptionsOfTargetValues", MetricIdentifier);
		
		IDOfAnalysisObject = GetIDOfDynamicParameter(Command.Name);
		
		DataSourceParameters = New Structure("AnalysisObject", IDOfAnalysisObject);
		
		// Let's put the dynamic parameters in temporary storage
		PlaceUpdateDynamicParametersInTemporaryStorage(AnalysisOption,
			MetricIdentifier,
			DataSourceParameters);
		
		ChangeDynamicParameterForChart(AnalysisOption, DataSourceParameters, MetricIdentifier);
		
		// Let's change the button markings
		Items[Command.Name].Check = True;
		ButtonsForAnalysisObjects = Items["AnalysisObjects__" + MetricIdentifier].ChildItems;
		
		For Each AnalysisObjectButton In ButtonsForAnalysisObjects Do 
			If Not AnalysisObjectButton = Items[Command.Name] Then
				AnalysisObjectButton.Check = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient 
Procedure Attachable_ChangeTableAnalysisObject(Command)
	If Not Items[Command.Name].Check Then
		MetricIdentifier = GetElementIDByNameWithoutPosition(Command.Name);
		
		AnalysisOption = TargetValueMonitoringServerCall.GetReferenceToCatalogById(
			"AnalysisOptionsOfTargetValues", MetricIdentifier);
		
		IDOfAnalysisObject = GetIDOfDynamicParameter(Command.Name);
		
		DataSourceParameters = New Structure("AnalysisObject", IDOfAnalysisObject);
		
		// Let's put the dynamic parameters in temporary storage
		PlaceUpdateDynamicParametersInTemporaryStorage(AnalysisOption,
			MetricIdentifier, DataSourceParameters);
		
		ChangeDynamicParameterForTable(AnalysisOption, DataSourceParameters, MetricIdentifier);
		
		// Let's change the button markings
		Items[Command.Name].Check = True;
		ButtonsForAnalysisObjects = Items["AnalysisObjects__" + MetricIdentifier].ChildItems;
		
		For Each AnalysisObjectButton In ButtonsForAnalysisObjects Do 
			If Not AnalysisObjectButton = Items[Command.Name] Then
				AnalysisObjectButton.Check = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient 
Procedure Attachable_ChangeTimeFence(Command)
	If Not Items[Command.Name].Check Then
		MetricIdentifier = GetElementIDByNameWithoutPosition(Command.Name);
		
		AnalysisOption = TargetValueMonitoringServerCall.GetReferenceToCatalogById(
			"AnalysisOptionsOfTargetValues", MetricIdentifier);
		
		PeriodicityID = GetIDOfDynamicParameter(Command.Name);
		
		DataSourceParameters = New Structure;
		DataSourceParameters.Insert("IndicatorCalculationFrequency",
			GetEnumerationLinkById("Periodicity", PeriodicityID));
		
		// Let's put the dynamic parameters in temporary storage
		PlaceUpdateDynamicParametersInTemporaryStorage(AnalysisOption,
			MetricIdentifier, DataSourceParameters);
		
		ChangeDynamicParameterForChart(AnalysisOption, DataSourceParameters, MetricIdentifier);
		
		// Let's change the button markings
		Items[Command.Name].Check = True;
		ButtonsForAnalysisObjects = Items["Periodicity__" + MetricIdentifier].ChildItems;
		
		For Each AnalysisObjectButton In ButtonsForAnalysisObjects Do 
			If Not AnalysisObjectButton = Items[Command.Name] Then
				AnalysisObjectButton.Check = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_OpenIndicatorAnalysis(Command)
	MetricIdentifier = GetElementIDByNameWithoutPosition(Command.Name);
	
	AnalysisOption = TargetValueMonitoringServerCall.GetReferenceToCatalogById(
		"AnalysisOptionsOfTargetValues", MetricIdentifier);
	
	Filter = New Structure("AnalysisOptionFilter, DemoMode", AnalysisOption, DemoMode);
	FormParameters = New Structure("Filter, UserSettings, GenerateOnOpen", 
		Filter,
		Report.SettingsComposer.UserSettings,
		True);
		
	OpenForm("Report.PerformanceDashboard.Form.AnalysisOptionPrintForm", 
		FormParameters, 
		ThisObject, 
		New UUID());
EndProcedure

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_OpenReport(Command)
	IDOfTheAnalysisOption = GetElementIDByNameWithoutPosition(Command.Name);
	PropertiesOfAnalysisVariant = TargetValueMonitoringServerCall.GetPropertiesOfAnalysisVariantById(
		IDOfTheAnalysisOption);
	
	IDOfReportVariant = GetReportVariantID(Command.Name);
	ReportVariant = GetVersionOfReportById(IDOfReportVariant);
	ReportOptionProperties = GetReportVariantProperties(ReportVariant);
	
	ReportOptionSettings = TargetValueMonitoringServerCall.GenerateReportVariantSettings(
		PropertiesOfAnalysisVariant, ReportOptionProperties);
	
	If ReportOptionSettings = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Không tìm thấy báo cáo đã chọn trong hệ thống';
										|ru = 'Выбранный отчет не найден в системе';
										|en = 'The selected report is not found in the application'; fa = 'The selected report is not found in the application';
										|it = 'Il report selezionato non è stato trovato nel sistema';
										|pl = 'Wybrany raport nie został znaleziony w systemie';
										|tr = 'Seçilen rapor sistemde bulunmadı'"));
	Else
		ReportParameters = New Structure;
		ReportParameters.Insert("UserSettingsKey");
		ReportParameters.Insert("UserSettings");
		ReportParameters.Insert("FixedSettings");
		ReportParameters.Insert("VariantKey");
		ReportParameters.Insert("PurposeUseKey");
		ReportParameters.Insert("GenerateOnOpen");
		ReportParameters.Insert("UserSettingsKey", Command.Name);
		ReportParameters.Insert("UserSettings", ReportOptionSettings.UserSettings);
		ReportParameters.Insert("FixedSettings", ReportOptionSettings.FixedSettings);
		ReportParameters.Insert("VariantKey", ReportOptionProperties.VariantKey);
		ReportParameters.Insert("PurposeUseKey", Command.Name);
		ReportParameters.Insert("GenerateOnOpen", True);
		
		OpenForm(ReportOptionProperties.ObjectKey + ".Form", ReportParameters, PropertiesOfAnalysisVariant.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure Print(Command)
	If MonitorContentIsNotDefined Then
		WarningText = NStr("vi = 'Không thể lập báo cáo tổng hợp vì chưa cài đặt màn hình chỉ số';
							|ru = 'Сформировать сводный отчет невозможно, т.к. монитор показателей не настроен.';
							|en = 'Cannot generate a summary report as the indicator monitor is not set up.'; fa = 'Cannot generate a summary report as the indicator monitor is not set up.';
							|it = 'È impossibile generare un report di riepilogo, perché La scorecard non è configurata.';
							|pl = 'Niemożliwe jest wygenerowanie raportu podsumowującego, ponieważ monitor wyników nie jest skonfigurowany.';
							|tr = 'Gösterge paneli ayarlanmadığı için özet rapor oluşturmak mümkün değildir.'");
		TitleText = NStr("vi = 'Lỗi lập báo cáo tổng hợp';
						|ru = 'Ошибка формирования сводного отчета';
						|en = 'An error occurred while generating the summary report'; fa = 'An error occurred while generating the summary report';
						|it = 'Errore durante la generazione di un report di riepilogo';
						|pl = 'Błąd generowania skonsolidowanego raportu';
						|tr = 'Özet raporu oluşturma hatası'");
		ShowMessageBox(Undefined, WarningText,, TitleText);
	ElsIf MonitorContentEmptyByFilter Then
		WarningText = NStr("vi = 'Không thể lập báo cáo tổng hợp vì trong bộ lọc hiện tại không có chỉ số nào.';
							|ru = 'Сформировать сводный отчет невозможно, т.к. в текущий отбор не входит ни один показатель.';
							|en = 'Cannot generate a summary report as the current filter does not include any indicator.'; fa = 'Cannot generate a summary report as the current filter does not include any indicator.';
							|it = 'È impossibile generare un report di riepilogo, perché nella selezione corrente non è incluso alcun indicatore.';
							|pl = 'Niemożliwe jest wygenerowanie raportu podsumowującego, ponieważ w obecnym wyborze brak żadnego wskaźnika.';
							|tr = 'Mevcut filtre herhangi bir gösterge içermediğinden özet rapor oluşturmak mümkün değildir.'");
		TitleText = NStr("vi = 'Lỗi lập báo cáo tổng hợp';
						|ru = 'Ошибка формирования сводного отчета';
						|en = 'An error occurred while generating the summary report'; fa = 'An error occurred while generating the summary report';
						|it = 'Errore durante la generazione di un report di riepilogo';
						|pl = 'Błąd generowania skonsolidowanego raportu';
						|tr = 'Özet raporu oluşturma hatası'");
		ShowMessageBox(Undefined, WarningText,, TitleText);
	Else 
		DataCompositionClientServer.SetParameter(Report.SettingsComposer.UserSettings, 
			"IndicatorGroupingOption", 
			SettingsStructure.IndicatorGroupingOption);
		DataCompositionClientServer.SetParameter(Report.SettingsComposer.UserSettings, 
			"NumberOfIndicatorMonitorColumns", 
			SettingsStructure.NumberOfIndicatorMonitorColumns);
		Report.SettingsComposer.UserSettings.AdditionalProperties.Insert("Dashboard",
			SettingsStructure.Dashboard);
		
		Filter = New Structure("DemoMode", DemoMode);
		FormParameters = New Structure("Filter, UserSettings, GenerateOnOpen", 
			Filter,
			Report.SettingsComposer.UserSettings,
			True);
			
		OpenForm("Report.PerformanceDashboard.Form.AnalysisOptionPrintForm", 
			FormParameters, 
			ThisObject, 
			New UUID());
	EndIf;
EndProcedure

&AtClient
Procedure MoveElementUpDown(Command)
	CurrentData = Items.Dashboards.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	MoveItem(CurrentData.Ref, ?(Command.Name = "MoveItemUp", True, False));
	Items.Dashboards.Refresh();
EndProcedure

#EndRegion

#Region Private

#Region StylesForDisplayingMetrics

&AtServer
Function MetricDisplayStyleBasic()
	// The style of diagrams, tables, and text representations
	Style = New Structure;

	Style.Insert("Width", CalculateWidthOfElement(SettingsStructure.NumberOfIndicatorMonitorColumns));
	Style.Insert("TitleLocation", FormItemTitleLocation.None);
	Style.Insert("HorizontalStretch", False);

	Return Style;
EndFunction

&AtServer
Function IndicatorElementGroupStyle()
	Style = New Structure;

	Style.Insert("Compositor", FormGroupType.UsualGroup);
	Style.Insert("Group", ChildFormItemsGroup.Vertical);
	Style.Insert("Representation", UsualGroupRepresentation.NormalSeparation);
	Style.Insert("ShowTitle", False);
	Style.Insert("VerticalStretch", False);
	Style.Insert("HorizontalStretch", False);

	Return Style;
EndFunction

&AtServer
Function TextDisplayStyle()
	// Refined style of text representations
	Style = Common.CopyRecursive(MetricDisplayStyleBasic());

	Style.Insert("FieldKind", FormFieldType.LabelField);

	Style.Insert("Height", 4);
	Style.Insert("HorizontalAlign", ItemHorizontalLocation.Center);
	Style.Insert("VerticalAlign", ItemVerticalAlign.Center);
	Style.Insert("BackColor", WebColors.White);
	Style.Insert("Border", New Border(ControlBorderType.Single, 1));

	Return Style;
EndFunction

&AtServer
Function StyleOfReferenceInformation()
	// Refined style of text representations
	Style = Common.CopyRecursive(MetricDisplayStyleBasic());

	Style.Insert("FieldKind", FormFieldType.LabelField);
	Style.Insert("TitleLocation", FormItemTitleLocation.Left);
	Style.Insert("Height", 1);
	Style.Insert("TitleHeight", 1);
	Style.Insert("VerticalStretch", False);
	Style.Insert("TextColor", StyleColors.NoteText);

	Return Style;
EndFunction

&AtServer
Function ChartDisplayStyle()
	// Refined chart style
	Style = Common.CopyRecursive(MetricDisplayStyleBasic());

	Style.Insert("FieldKind", FormFieldType.ChartField);
	Style.Insert("Height", 8 * SettingsStructure.ArbitraryScale / 100);

	Return Style;
EndFunction

&AtServer
Function TableDisplayStyle()
	// Refined table style
	Style = Common.CopyRecursive(MetricDisplayStyleBasic());

	Style.Insert("Height", 6 * SettingsStructure.ArbitraryScale / 100);
	Style.Insert("CommandBarLocation", FormItemCommandBarLabelLocation.None);
	Style.Insert("ReadOnly", True);
	Style.Insert("Header", False);
	Style.Insert("Footer", False);
	Style.Insert("HorizontalLines", False);
	Style.Insert("VerticalLines", False);
	Style.Insert("MultipleChoice", False);
	Style.Insert("UseAlternationRowColor", True);

	Return Style;
EndFunction

&AtServer
Function StyleOfMetricsCommandPanels()
	Style = New Structure;

	Style.Insert("Compositor", FormGroupType.CommandBar);

	Style.Insert("HorizontalStretch", True);
	Style.Insert("HorizontalAlign", ItemHorizontalLocation.Right);
	Style.Insert("HorizontalAlignInGroup", ItemHorizontalLocation.Right);

	Return Style;
EndFunction

&AtServer
Function HeaderElementGroupStyle()
	Style = New Structure;

	Return Style;
EndFunction

&AtServer
Function HeaderStyle()
	Style = New Structure;

	Style.Insert("FieldKind", FormFieldType.LabelField);

	Style.Insert("Height", 1);
	Style.Insert("VerticalStretch", False);
	Style.Insert("VerticalAlign", ItemVerticalAlign.Top);
	Style.Insert("TitleLocation", FormItemTitleLocation.None);

	Return Style;
EndFunction

&AtServer
Function MetricGroupStyle()
	Style = New Structure;

	Style.Insert("ShowTitle", True);
	Style.Insert("Representation", UsualGroupRepresentation.NormalSeparation);
	Style.Insert("TitleFont", IndicatorGroupFont());
	Style.Insert("TitleTextColor", IndicatorGroupColor());
	Style.Insert("ThroughAlign", ThroughAlign.Use);

	Return Style;
EndFunction

&AtServer
Function MetricsColumnGroupStyle()
	Style = New Structure;

	Style.Insert("United", False);

	Return Style;
EndFunction

&AtServer
Function IndicatorGroupStyleGoalAchieved()
	Style = Common.CopyRecursive(MetricGroupStyle());
	Style.Insert("TitleTextColor",	WebColors.Seagreen);
	
	Return Style;
EndFunction

&AtServer
Function IndicatorGroupStyleAcceptableState()
	Style = Common.CopyRecursive(MetricGroupStyle());
	Style.Insert("TitleTextColor",	WebColors.DarkOrange);
	
	Return Style;
EndFunction

&AtServer
Function IndicatorGroupStyleUnacceptableState()
	Style = Common.CopyRecursive(MetricGroupStyle());
	Style.Insert("TitleTextColor",	WebColors.FireBrick);
	
	Return Style;
EndFunction

&AtServer 
Function GroupStyleByState(State)
	If State = "UnacceptableState" 
		Or State = "CalculatedWithErrors" Then
		Return IndicatorGroupStyleUnacceptableState();
	ElsIf State = "AcceptableState" Then
		Return IndicatorGroupStyleAcceptableState();
	ElsIf State = "TheGoalIsAchieved" Then
		Return IndicatorGroupStyleGoalAchieved();
	Else
		Return MetricGroupStyle();
	EndIf;
EndFunction

&AtServer
Function BasicTextScale()
	Return Max(100, 100 + 30*(SettingsStructure.ArbitraryScale / 100-1));
EndFunction

&AtServer
Function IndexDetailsFont()
	Return New Font(,,       ,,,, 40 + BasicTextScale());
EndFunction

&AtServer
Function FontOfIndicatorValue()
	Return New Font(,, True,,,, 120 + BasicTextScale());
EndFunction

&AtServer
Function FontImportant()
	Return New Font(,, True);
EndFunction

&AtServer
Function FontOfIndicatorHeaderIsImportant()
	Return New Font(,, True,,,, BasicTextScale());
EndFunction

&AtServer
Function IndicatorGroupColor()
	// Settings of wrapper groups for indicators
	If CurrentVersionOfClientApplicationInterface = ClientApplicationInterfaceVariant.Version8_2 Then
		IndicatorGroupColor = StyleColors.ReportsOptionsGroupColor82;
	Else // Taxi.
		IndicatorGroupColor = StyleColors.ReportsOptionsGroupColor;
	EndIf;
	
	Return IndicatorGroupColor;
EndFunction

&AtServer
Function IndicatorGroupFont()
	// Settings of wrapper groups for indicators
	If CurrentVersionOfClientApplicationInterface = ClientApplicationInterfaceVariant.Version8_2 Then
		IndicatorGroupFont = New Font("MS Shell Dlg", 10, True, False, False, False, 100);
	Else // Taxi.
		IndicatorGroupFont = New Font("Arial", 12, True, False, False, False, 100);
	EndIf;
	
	Return IndicatorGroupFont;
EndFunction

#EndRegion 

#Region CreatingFormElements

&AtServer
Function VerticalGroup(Name, Var_Title, ParentGroup2 = Undefined)
	GroupStringOfElements = Items.Add(Name, Type("FormGroup"), ParentGroup2);
	GroupStringOfElements.Type = FormGroupType.UsualGroup;
	GroupStringOfElements.Group = ChildFormItemsGroup.Vertical;
	GroupStringOfElements.Representation = UsualGroupRepresentation.None;
	GroupStringOfElements.Title = Var_Title;
	GroupStringOfElements.EnableContentChange = False;
	GroupStringOfElements.ShowTitle = False;
	
	Return GroupStringOfElements;
EndFunction

&AtServer
Function HorizontalGroup(Name, Var_Title, ParentGroup2 = Undefined)
	GroupStringOfElements = Items.Add(Name, Type("FormGroup"), ParentGroup2);
	GroupStringOfElements.Type = FormGroupType.UsualGroup;
	GroupStringOfElements.Representation = UsualGroupRepresentation.None;
	GroupStringOfElements.Group = ChildFormItemsGroup.Horizontal;
	GroupStringOfElements.Title = Var_Title;
	GroupStringOfElements.ShowTitle = False;
	
	Return GroupStringOfElements;
EndFunction

// Adds vertical groups of form elements, which 
// will then contain the elements of the metrics form.
// 
// Parameters:
//	ParentGroup2 - FormGroup
//	OptionForDisplayingLineMetrics - EnumRef.DisplayOptionsOfAnalysisOptions, Undefined - indicates a short display or as a chart / table
//	Unique group key-String - a unique identifier of the group based on the name of the attention zone.
//
&AtServer 
Procedure AddGroupsColumnsOfItems(ParentGroup2, GroupUniquenessKey, OptionForDisplayingLineMetrics = Undefined)
	DisplayOptionsOfAnalysisOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	If OptionForDisplayingLineMetrics = DisplayOptionsOfAnalysisOptions.Brief1 Then
		For ColumnNumber = 1 To SettingsStructure.NumberOfIndicatorMonitorColumns Do
			ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cột số %1';
					|ru = 'Колонка №%1';
					|en = 'Column #%1'; fa = 'Column #%1';
					|it = 'Colonna №%1';
					|pl = 'Kolumna №%1';
					|tr = 'Sütun №%1'"),
				ColumnNumber);
			GroupColumnElements = VerticalGroup(
				"GroupColumnElements" + "Brief1" + GroupUniquenessKey + "__" + ColumnNumber,
				ItemTitle,
				ParentGroup2);
			FillPropertyValues(GroupColumnElements, MetricsColumnGroupStyle());
		EndDo;
	Else
		If Items.Find("GroupColumnElements" + "More" + GroupUniquenessKey) = Undefined Then
			For ColumnNumber = 1 To SettingsStructure.NumberOfIndicatorMonitorColumns Do
				ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cột số %1';
						|ru = 'Колонка №%1';
						|en = 'Column #%1'; fa = 'Column #%1';
						|it = 'Colonna №%1';
						|pl = 'Kolumna №%1';
						|tr = 'Sütun №%1'"),
					ColumnNumber);
				GroupColumnElements = VerticalGroup(
					"GroupColumnElements" + "More" + GroupUniquenessKey + "__" + ColumnNumber,
					ItemTitle,
					ParentGroup2);
				FillPropertyValues(GroupColumnElements, MetricsColumnGroupStyle());
			EndDo;
		EndIf;
	EndIf;
EndProcedure

// Adds the commands available for the specified analysis option.
// Possible commands: "Influencing indicators", "Dependent indicators", "Frequency", "object of analysis", "Reports",
// "indicator Analysis".
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - the option for which commands are added.
//	Items_Group - FormGroup - the command panel to add buttons to.
//	IDOfFormElement - String - a string containing the unique ID of the form element.
//	ViewOption - EnumRef.DisplayOptionsOfAnalysisOptions - indicates a short display or as a chart / table.
//
&AtServer
Procedure AddAnalysisOptionsCommands(AnalysisOption, Items_Group, IDOfFormElement, ViewOption)
	DisplayOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	ParametersForAvailabilityOfAnalysisOfInterrelated =
		TargetValueMonitoring.GetParametersForAvailabilityOfAnalysisOfInterrelated(AnalysisOption);
	
	DataOfAnalysisVariant = Common.ObjectAttributesValues(AnalysisOption, "AnalysisType, ComponentWiseComparisonMode");
	AddRelationshipsSubmenu = True;
	AddSubmenusForAnalysisObjects = Not DemoMode
		And ((DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		Or DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends)
		And DataOfAnalysisVariant.ComponentWiseComparisonMode = 0);
	AddPeriodicitySubmenu = Not DemoMode
		And (DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends
		Or DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends);
	
	IndicatorCommandPanel = Items.Add(
		"IndicatorCommandPanel__" + IDOfFormElement,
		Type("FormGroup"),
		Items["Title__" + IDOfFormElement]); // FormGroup
	IndicatorCommandPanel.Title = NStr("vi = 'Thanh lệnh chỉ số';
										|ru = 'Команды показателя';
										|en = 'Indicator commands'; fa = 'Indicator commands';
										|it = 'Comandi indicatore';
										|pl = 'Polecenia wskaźnika';
										|tr = 'Gösterge komutları'");
	Style = StyleOfMetricsCommandPanels();
	IndicatorCommandPanel.Type = Style.Compositor;
	FillPropertyValues(IndicatorCommandPanel, Style);
	
	// Add the "All actions" submenu
	SubmenuAllActions = Items.Add("AllActions__" + IDOfFormElement,
		Type("FormGroup"),
		IndicatorCommandPanel);
	SubmenuAllActions.Type = FormGroupType.Popup;
	SubmenuAllActions.Representation = ButtonRepresentation.Text;
	SubmenuAllActions.Title = " ";
	
	// Add the form details
	
	If AddRelationshipsSubmenu
		And Not (ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreDependentsAvailable
			Or ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreInfluencersAvailable) Then
		EmptyCommand = Commands.Add("EmptyCommand__" + IDOfFormElement);
		EmptyCommand.Title = NStr("vi = 'không có kết nối';
									|ru = 'Взаимосвязей нет';
									|en = 'No connections'; fa = 'No connections';
									|it = 'Nessuna relazione';
									|pl = 'Relacji brak';
									|tr = 'İş ilişkisi yok'");
		EmptyCommand.Picture = PictureLib.IconAllIndicators;
	EndIf;
	
	If AddRelationshipsSubmenu
		And ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreDependentsAvailable Then
		LinkSearchCommand = Commands.Add("DependentIndicators__" + IDOfFormElement);
		LinkSearchCommand.Title = NStr("vi = 'Các chỉ tiêu phụ thuộc';
										|ru = 'Зависимые показатели';
										|en = 'Dependent indicators'; fa = 'شاخص‌های وابسته';
										|it = 'Indicatori dipendenti';
										|pl = 'Wskaźniki zależne';
										|tr = 'Bağımlı göstergeler'");
		LinkSearchCommand.Action = "Attachable_AnalysisOfInterrelatedAnalysisOptions";
		LinkSearchCommand.Picture = PictureLib.IconDependentIndicators;
	EndIf;
	
	If AddRelationshipsSubmenu
		And ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreInfluencersAvailable Then
		LinkSearchCommand = Commands.Add("InfluencingIndicators__" + IDOfFormElement);
		LinkSearchCommand.Title = NStr("vi = 'Chỉ số ảnh hưởng';
										|ru = 'Влияющие показатели';
										|en = 'Influencing indicators'; fa = 'شاخص‌های تأثیرگذار';
										|it = 'Indicatori di influenza';
										|pl = 'Wskaźniki wpływające';
										|tr = 'Etkileyen göstergeler'");
		LinkSearchCommand.Action = "Attachable_AnalysisOfInterrelatedAnalysisOptions";
		LinkSearchCommand.Picture = PictureLib.IconRelatedIndicators;
	EndIf;
	
	TeamIndicatorAnalysis = Commands.Add("OpenIndicatorAnalysis__" + IDOfFormElement);
	TeamIndicatorAnalysis.Title = NStr("vi = 'Phân tích chỉ số';
										|ru = 'Анализ показателя';
										|en = 'Indicator analysis'; fa = 'Indicator analysis';
										|it = 'Analisi indicatore';
										|pl = 'Analiza wskaźnika';
										|tr = 'Gösterge analizi'");
	TeamIndicatorAnalysis.Action = "Attachable_OpenIndicatorAnalysis";
	TeamIndicatorAnalysis.Picture = PictureLib.Reports;
	
	// We get the number of report options for the indicator
	Recordsreferences = GetReportOptions(AnalysisOption);
	NumberOfReportOptions = Recordsreferences.Count();
	
	If ViewOption = DisplayOptions.Chart 
		Or ViewOption = DisplayOptions.Table Then
		
		DataOfAnalysisVariant = Common.ObjectAttributesValues(AnalysisOption,
			"Owner, AnalysisObject, IndicatorCalculationFrequency");
		
		// Let's add a menu for the objects of analysis
		AvailableAnalysisObjects = Catalogs.StructureOfTargets.AvailableAnalysisObjects(DataOfAnalysisVariant.Owner);
		DefaultAnalysisObject = DataOfAnalysisVariant.AnalysisObject.Get();
		
		If AddSubmenusForAnalysisObjects And AvailableAnalysisObjects.Count() > 1 Then
			For Each AnalysisObject In AvailableAnalysisObjects Do
				CommandName = "ChangeAnalysisObject__" + IDOfFormElement
					+ "__" + String(AnalysisObject.Value);
				CommandToChangeAnalysisObject = Commands.Add(CommandName);
				CommandToChangeAnalysisObject.Title = AnalysisObject.Presentation;
				If ViewOption = DisplayOptions.Chart Then
					CommandToChangeAnalysisObject.Action = "Attachable_ChangeChartAnalysisObject";
				Else
					CommandToChangeAnalysisObject.Action = "Attachable_ChangeTableAnalysisObject";
				EndIf;
			EndDo;
		EndIf;
		
		// Let's add a periodicity menu
		// We get the address of the dynamic parameters.
		SelectionByAnalysisOption = New Structure("AnalysisOption", AnalysisOption);
		FoundMonitorComponents = MonitorContent.FindRows(SelectionByAnalysisOption);
		If FoundMonitorComponents.Count() > 0 Then
			DynamicParameterAddress = FoundMonitorComponents[0].DynamicParameterAddress;
			
			If Not IsBlankString(DynamicParameterAddress) Then
				DynamicParameters = GetFromTempStorage(DynamicParameterAddress);
				
				If DynamicParameters.Property("IndicatorCalculationFrequency") Then
					DefaultPeriodicity = DynamicParameters.IndicatorCalculationFrequency;
				Else
					DefaultPeriodicity = DataOfAnalysisVariant.IndicatorCalculationFrequency;
				EndIf;
			Else
				DefaultPeriodicity = DataOfAnalysisVariant.IndicatorCalculationFrequency;
			EndIf;
		EndIf;
		
		If AddPeriodicitySubmenu Then
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Day";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Ngày';
													|ru = 'День';
													|en = 'Day'; fa = 'روز';
													|it = 'Giorno';
													|pl = 'Dzień';
													|tr = 'Gün'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
			
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Week";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Tuần';
													|ru = 'Неделя';
													|en = 'Week'; fa = 'هفته';
													|it = 'Settimana';
													|pl = 'Tydzień';
													|tr = 'Hafta'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
			
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "TenDays";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Mười ngày';
													|ru = 'Декада';
													|en = 'Ten-day period'; fa = 'دوره ده‌روزه';
													|it = 'Decade';
													|pl = 'Ten-day period';
													|tr = '10 günlük süre'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
			
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Month";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Tháng';
													|ru = 'Месяц';
													|en = 'Month'; fa = 'ماه';
													|it = 'Mese';
													|pl = 'Miesiąc';
													|tr = 'Ay'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
			
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Quarter";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Quý';
													|ru = 'Квартал';
													|en = 'Quarter'; fa = 'فصل';
													|it = 'Trimestre';
													|pl = 'Kwartał';
													|tr = 'Çeyrek'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
			
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "HalfYear";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Nửa năm';
													|ru = 'Полугодие';
													|en = 'Half-year'; fa = 'نیم‌سال';
													|it = 'Semestre';
													|pl = 'Half-year';
													|tr = 'Yarıyıl'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
			
			CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Year";
			PeriodicityChangeCommand = Commands.Add(CommandName);
			PeriodicityChangeCommand.Title = NStr("vi = 'Năm';
													|ru = 'Год';
													|en = 'Year'; fa = 'سال';
													|it = 'Anno';
													|pl = 'Year';
													|tr = 'yıl'");
			PeriodicityChangeCommand.Action = "Attachable_ChangeTimeFence";
		EndIf;
		
		// Adding form elements
		// Adding a submenu of links
		If AddRelationshipsSubmenu Then
			If ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreDependentsAvailable
			 Or ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreInfluencersAvailable Then	
				DependenciesSubmenu = Items.Add("DependenciesOfIndicators__" + IDOfFormElement,
					Type("FormGroup"),
					SubmenuAllActions);
				DependenciesSubmenu.Type = FormGroupType.Popup;
				DependenciesSubmenu.Title = NStr("vi = 'Kết nối';
												|ru = 'Взаимосвязи';
												|en = 'Relationships'; fa = 'Relationships';
												|it = 'Relazione';
												|pl = 'Relationships';
												|tr = 'İş ilişkileri'");
				DependenciesSubmenu.Picture = PictureLib.IconAllIndicators;
			Else
				LinkSearchButton = Items.Add("DependenciesOfIndicators__" + IDOfFormElement,
					Type("FormButton"),
					SubmenuAllActions);
				LinkSearchButton.CommandName = "EmptyCommand__" + IDOfFormElement;
				LinkSearchButton.Enabled = False;
			EndIf;
		EndIf;
		
		If AddRelationshipsSubmenu And ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreDependentsAvailable Then
			LinkSearchButton = Items.Add("FormDependentIndicators__" + IDOfFormElement,
				Type("FormButton"),
				DependenciesSubmenu);
			LinkSearchButton.CommandName = "DependentIndicators__" + IDOfFormElement;
		EndIf;
		
		If AddRelationshipsSubmenu And ParametersForAvailabilityOfAnalysisOfInterrelated.ThereAreInfluencersAvailable Then
			LinkSearchButton =Items.Add("FormInfluencingIndicators__" + IDOfFormElement,
				Type("FormButton"),
				DependenciesSubmenu);
			LinkSearchButton.CommandName = "InfluencingIndicators__" + IDOfFormElement;
		EndIf;
		
		If AddSubmenusForAnalysisObjects And AvailableAnalysisObjects.Count() > 1 Then
			AnalysisObjectsSubmenu = Items.Add("AnalysisObjects__" + IDOfFormElement,
				Type("FormGroup"),
				SubmenuAllActions);
			AnalysisObjectsSubmenu.Type = FormGroupType.Popup;
			AnalysisObjectsSubmenu.Title = NStr("vi = 'Đối tượng phân tích';
												|ru = 'Объекты анализа';
												|en = 'Analysis objects'; fa = 'موضوعات تحلیل';
												|it = 'Oggetti dell''analisi';
												|pl = 'Obiekty analizy';
												|tr = 'Analiz nesneleri'");
			
			For Each AnalysisObject In AvailableAnalysisObjects Do
				AnalysisObjectButton = Items.Add(
					"ChangeAnalysisObject__" + IDOfFormElement + "__" + String(AnalysisObject.Value),
					Type("FormButton"),
					AnalysisObjectsSubmenu);
				AnalysisObjectButton.CommandName = "ChangeAnalysisObject__" + IDOfFormElement
					+ "__" + String(AnalysisObject.Value);
				If AnalysisObject.Value = DefaultAnalysisObject Then
					AnalysisObjectButton.Check = True;
				EndIf;
			EndDo;
		EndIf;
		
		If AddPeriodicitySubmenu Then
			DefaultPeriodicityName = TargetValueMonitoring.GetNameOfEnumerationValue(
				DefaultPeriodicity);
			
			PeriodicitySubmenu = Items.Add("Periodicity__" + IDOfFormElement,
				Type("FormGroup"),
				SubmenuAllActions);
			PeriodicitySubmenu.Type = FormGroupType.Popup;
			PeriodicitySubmenu.Title = NStr("vi = 'Tính định kỳ';
											|ru = 'Периодичность';
											|en = 'Frequency'; fa = 'تناوب';
											|it = 'Periodicità';
											|pl = 'Frequency';
											|tr = 'Sıklık'");
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "Day",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Day";
			If DefaultPeriodicityName = "Day" Then
				PeriodicityButton.Check = True;
			EndIf;
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "Week",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Week";
			If DefaultPeriodicityName = "Week" Then
				PeriodicityButton.Check = True;
			EndIf;
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "TenDays",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "TenDays";
			If DefaultPeriodicityName = "TenDays" Then
				PeriodicityButton.Check = True;
			EndIf;
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "Month",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Month";
			If DefaultPeriodicityName = "Month" Then
				PeriodicityButton.Check = True;
			EndIf;
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "Quarter",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Quarter";
			If DefaultPeriodicityName = "Quarter" Then
				PeriodicityButton.Check = True;
			EndIf;
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "HalfYear",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement
				+ "__" + "HalfYear";
			If DefaultPeriodicityName = "HalfYear" Then
				PeriodicityButton.Check = True;
			EndIf;
			
			PeriodicityButton = Items.Add(
				"ChangeFrequency__" + IDOfFormElement + "__" + "Year",
				Type("FormButton"),
				PeriodicitySubmenu);
			PeriodicityButton.CommandName = "ChangeFrequency__" + IDOfFormElement + "__" + "Year";
			If DefaultPeriodicityName = "Year" Then
				PeriodicityButton.Check = True;
			EndIf;
		EndIf;
	EndIf;
	
	If NumberOfReportOptions Then
		For Each VersionOfIndicatorReport In Recordsreferences Do 
			OptionID1 = VersionOfIndicatorReport.Value;
			OptionDescription = VersionOfIndicatorReport.Presentation;
			
			CommandName = "OpenReport__" + IDOfFormElement + "__" + OptionID1;
			OpenReportCommand = Commands.Add(CommandName);
			OpenReportCommand.Title = OptionDescription;
			OpenReportCommand.Action = "Attachable_OpenReport";
			OpenReportCommand.Picture = PictureLib.Report;
		EndDo;
		
		ReportsSubmenu = Items.Add("Reports__" + IDOfFormElement,
			Type("FormGroup"),
			SubmenuAllActions);
		ReportsSubmenu.Type = FormGroupType.Popup;
		ReportsSubmenu.Title = NStr("vi = 'Báo cáo';
									|ru = 'Отчеты';
									|en = 'Reports'; fa = 'گزارش‌ها';
									|it = 'Report';
									|pl = 'Reports';
									|tr = 'Raporlar'");
		ReportsSubmenu.Picture = PictureLib.Report;
		
		For Each VersionOfIndicatorReport In Recordsreferences Do 
			OptionID1 = VersionOfIndicatorReport.Value;
			
			ReportButton = Items.Add(
				"OpenReportForm__" + IDOfFormElement + "__" + OptionID1,
				Type("FormButton"),
				ReportsSubmenu);
			ReportButton.CommandName = "OpenReport__" + IDOfFormElement + "__" + OptionID1;
		EndDo;
	EndIf;
	
	// Add analysis, decryption and configuration commands
	IndicatorAnalysisButton = Items.Add("OpenIndicatorAnalysisForm__" + IDOfFormElement,
		Type("FormButton"),
		SubmenuAllActions);
	IndicatorAnalysisButton.CommandName = "OpenIndicatorAnalysis__" + IDOfFormElement;
EndProcedure

// Caches properties of the analyzed monitor composition
// The number of data sources is analyzed: 
//	- for which you need to output detailed information
//	- for which you want to display the table total
//	- for which a cumulative status analysis is required.
// 
// Parameters:
//	AnalyzedCompositionOfMonitor - Structure - contains a set of data sources and generalized information about the sources
//	DynamicParameterAddresses - ValueTable, Undefined - contains the analysis option and the DIN address. settings in temporary storage.
//
&AtServer 
Procedure FillInSummaryInformationOnDataSources(AnalyzedCompositionOfMonitor, DynamicParameterAddresses = Undefined)
	SetOfDataSources = AnalyzedCompositionOfMonitor.SetOfDataSources;
	
	If Not AnalyzedCompositionOfMonitor.IsEmpty Then 
		AnalysisOptionWithDetails.Clear();
		SelectionByDetailed = New Structure("DisplayDetails", True);
		FoundAnalysisOptions = SetOfDataSources.FindRows(SelectionByDetailed);
		For Each FoundVersionOfAnalysis In FoundAnalysisOptions Do 
			AnalysisOptionWithDetails.Add(FoundVersionOfAnalysis.AnalysisOption);
		EndDo;
		
		TabularAnalysisOptionsWithResults.Clear();
		TabularSelectionWithTotals = New Structure("DisplayTableTotal", True);
		FoundAnalysisOptions = SetOfDataSources.FindRows(TabularSelectionWithTotals);
		For Each FoundVersionOfAnalysis In FoundAnalysisOptions Do 
			TabularAnalysisOptionsWithResults.Add(FoundVersionOfAnalysis.AnalysisOption);
		EndDo;
		
		AnalysisOptionWithCumulativeTotal.Clear();
		CumulativeSelection = New Structure("StateByCumulativeTotal", True);
		FoundAnalysisOptions = SetOfDataSources.FindRows(CumulativeSelection);
		For Each FoundVersionOfAnalysis In FoundAnalysisOptions Do 
			AnalysisOptionWithCumulativeTotal.Add(FoundVersionOfAnalysis.AnalysisOption);
		EndDo;
		
		ColumnsNames = "AnalysisOption, CalculationError, PaymentsAreIrrelevant, IsEmpty, StateByCumulativeTotal";
		ColumnsNames = ColumnsNames + ", DisplayTableTotal, DisplayDetails, Group, AreaOfInterest, InterestAreaProcedure";
		CompositeObject_ = SetOfDataSources.Copy(, ColumnsNames); // ValueTable - 
		CompositeObject_.Columns.Add("DynamicParameterAddress");
		
		// Fill in the passed addresses of dynamic parameters
		If Not DynamicParameterAddresses = Undefined Then
			For Each MonitorCompositionElement In CompositeObject_ Do 
				SelectionByAnalysisOption = New Structure("AnalysisOption", MonitorCompositionElement.AnalysisOption);
				FoundMonitorComponents = DynamicParameterAddresses.FindRows(SelectionByAnalysisOption);
				If FoundMonitorComponents.Count() > 0 Then
					MonitorCompositionElement.DynamicParameterAddress = FoundMonitorComponents[0].DynamicParameterAddress;
				EndIf;
			EndDo;
		EndIf;
		
		ValueToFormData(CompositeObject_, MonitorContent);
	Else
		AnalysisOptionWithDetails.Clear();
		TabularAnalysisOptionsWithResults.Clear();
		AnalysisOptionWithCumulativeTotal.Clear();
		MonitorContent.Clear();
	EndIf;
EndProcedure

// Recalculates the data source for the transmitted version of the analysis if you change the object of analysis, or periodicity.
// Updating the chart of variant analysis.
// 
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - the option for which the DIN parameter was changed
//	DataSourceParameters - Structure - contains the state of the dynamic parameters of the analysis option
//	IDOfFormElement - String - unique ID(name) of the chart being updated.
//
&AtServer 
Procedure ChangeDynamicParameterForChart(AnalysisOption, DataSourceParameters, IDOfFormElement)
	ForcedUpdate = False;
	
	If DataSourceParameters.Property("AnalysisObject") Then
		If String(AnalysisOption.AnalysisObject.Get()) = DataSourceParameters.AnalysisObject Then
			ForcedUpdate = ForcedUpdate Or False;
		Else
			ForcedUpdate = ForcedUpdate Or True;
		EndIf;
	EndIf;
	If DataSourceParameters.Property("IndicatorCalculationFrequency") Then	
		If AnalysisOption.IndicatorCalculationFrequency = DataSourceParameters.IndicatorCalculationFrequency Then
			ForcedUpdate = ForcedUpdate Or False;
		Else
			ForcedUpdate = ForcedUpdate Or True;
		EndIf;
	EndIf;
	
	DataSource = TargetValueMonitoring.GetAnalysisVariantDataSource(AnalysisOption, 
		Enums.DisplayOptionsOfAnalysisOptions.Chart, 
		ForcedUpdate, 
		DataSourceParameters);
	
	EmptyDataSource = DataSource.IsEmpty;
	CalculationError = DataSource.CalculationError;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		ThisObject["Chart__" + IDOfFormElement].DataSource = New ValueTable;
		ThisObject["Chart__" + IDOfFormElement].DataSource = Undefined;
		
		Chart = TargetValueMonitoring.FillInChartForMonitor(
			ThisObject["Chart__" + IDOfFormElement],
			AnalysisOption,
			DataSource);
		ThisObject["Chart__" + IDOfFormElement] = Chart;
	Else
		Chart = ThisObject["Chart__" + IDOfFormElement];
		
		If DataSource.Property("ErrorDescription") Then
			ErrorDescription = DataSource.ErrorDescription;
		Else
			ErrorDescription = NStr("vi = 'Lỗi tính toán chỉ số';
									|ru = 'Ошибка расчета показателя';
									|en = 'Indicator calculation error'; fa = 'Indicator calculation error';
									|it = 'Errore di calcolo';
									|pl = 'Błąd obliczenia wskaźnika';
									|tr = 'Gösterge hesaplama hatası'");
		EndIf;

		Chart = TargetValueMonitoring.GetChartForCalculationErrors(Chart, ErrorDescription);
	EndIf;
	
	// Let's set a new name for the chart
	SetNameOfIndicator(AnalysisOption, IDOfFormElement, DataSource, True);
EndProcedure

// Recalculates the data source for the transmitted version of the analysis if you change the object of analysis, or periodicity.
// Updates the analysis option table.
// 
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - the option for which the DIN parameter was changed
//	DataSourceParameters - Structure - contains the state of the dynamic parameters of the analysis option
//	IDOfFormElement - String - unique ID(name) of the table being updated.
//
&AtServer 
Procedure ChangeDynamicParameterForTable(AnalysisOption, DataSourceParameters, IDOfFormElement)
	If DataSourceParameters.Property("AnalysisObject") Then
		If String(AnalysisOption.AnalysisObject.Get()) = DataSourceParameters.AnalysisObject Then
			ForcedUpdate = False;
		Else
			ForcedUpdate = True;
		EndIf;
	ElsIf DataSourceParameters.Property("IndicatorCalculationFrequency") Then	
		If AnalysisOption.IndicatorCalculationFrequency = DataSourceParameters.IndicatorCalculationFrequency Then
			ForcedUpdate = False;
		Else
			ForcedUpdate = True;
		EndIf;
	EndIf;
	
	DataSourceOfAnalysisVariant = TargetValueMonitoring.GetAnalysisVariantDataSource(
		AnalysisOption,
		Enums.DisplayOptionsOfAnalysisOptions.Chart,
		ForcedUpdate,DataSourceParameters);
	
	If Not DataSourceOfAnalysisVariant.IsEmpty Then
		DynamicPropertiesOfAnalysisVariant = DataSourceOfAnalysisVariant.DynamicPropertiesOfAnalysisVariant;
		DisplayTotalInTable = (Not TabularAnalysisOptionsWithResults.FindByValue(AnalysisOption) = Undefined);
		
		If DisplayTotalInTable Then 
			ValueMultiplier			= AnalysisOption.ValueMultiplier;
			FractionalPartCalculationAccuracy = AnalysisOption.FractionalPartCalculationAccuracy;
			Dimensions					= TrimAll(String(DynamicPropertiesOfAnalysisVariant.Dimensions));
			
			Value_Number = DataSourceOfAnalysisVariant.Data.Total(
				DataSourceOfAnalysisVariant.DynamicPropertiesOfAnalysisVariant.AnalysisValue);
			NumberPresentation = TargetValueMonitoring.GetAbbreviatedPresentationOfNumber(
				Value_Number,
				FractionalPartCalculationAccuracy,
				ValueMultiplier);
			NumberPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 %2';
					|ru = '%1 %2';
					|en = '%1 %2'; fa = '%1 %2';
					|it = '%1 %2';
					|pl = '%1 %2';
					|tr = '%1 %2'"),
				NumberPresentation,
				Dimensions);
			ThisObject["SummaryTableOfValues__" + IDOfFormElement] = NumberPresentation;
			
		EndIf;
		
		TargetValueMonitoring.FillInTableForMonitor(
			ThisObject["ValueTable__" + IDOfFormElement],
			IDOfFormElement,
			AnalysisOption,
			DataSourceOfAnalysisVariant);
	Else
		If Not DataSourceOfAnalysisVariant.CalculationsAreRelevant Then
			ErrorText = NStr("vi = 'Chưa cập nhật dữ liệu.';
							|ru = 'Данные неактуальны.';
							|en = 'Data is irrelevant.'; fa = 'Data is irrelevant.';
							|it = 'I dati non sono più utilizzabili';
							|pl = 'Dane nie są aktualne.';
							|tr = 'Veriler güncel değil.'");
			Chart = TargetValueMonitoring.GetChartForCalculationErrors(
				ThisObject["Chart__" + IDOfFormElement],
				ErrorText);
			ThisObject["Chart__" + IDOfFormElement] = Chart;
		ElsIf DataSourceOfAnalysisVariant.CalculationError Then
			ErrorText = NStr("vi = 'Lỗi khi tính giá trị chỉ số.';
							|ru = 'Ошибка при расчете значений показателя.';
							|en = 'An error occurred while calculating the indicator values.'; fa = 'An error occurred while calculating the indicator values.';
							|it = 'Errore nel calcolo dei valori dell''indicatore.';
							|pl = 'Błąd przy obliczaniu wartości wskaźnika.';
							|tr = 'Gösterge değerlerinin hesaplanmasında hata.'");
			Chart = TargetValueMonitoring.GetChartForCalculationErrors(
				ThisObject["Chart__" + IDOfFormElement],
				ErrorText);
			ThisObject["Chart__" + IDOfFormElement] = Chart;
		Else
			ErrorText = NStr("vi = 'Thiếu dữ liệu để tính chỉ số.';
							|ru = 'Недостаточно данных для расчета показателя.';
							|en = 'Not enough data to calculate indicator.'; fa = 'Not enough data to calculate indicator.';
							|it = 'Dati insufficienti per calcolare l''indicatore';
							|pl = 'Za mało danych do obliczenia wskaźnika.';
							|tr = 'Göstergeyi hesaplamak için yeterli veri yok.'");
			Chart = TargetValueMonitoring.GetChartForCalculationErrors(
				ThisObject["Chart__" + IDOfFormElement],
				ErrorText);
			ThisObject["Chart__" + IDOfFormElement] = Chart;
		EndIf;
	EndIf;
EndProcedure

// Adds form elements for the "Chart" display type"
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues -
//	DataSource - Structure - contains calculation results for the analysis option
//	Items_Group - FormGroup - the forms group to which you want to add form elements
//	IDOfFormElement - String - a string containing the unique ID of the form element.
//
&AtServer
Procedure DrawDiagram(AnalysisOption, DataSource, Items_Group, IDOfFormElement)
	
	EmptyDataSource = DataSource.IsEmpty;
	CalculationError = DataSource.CalculationError;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	
	AttributesArray = New Array;
	
	TypesArray = New Array;
	TypesArray.Add(Type("Chart"));
	TypeDescription = New TypeDescription(TypesArray);
	
	PropsHeader = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Biểu đồ cho %1';
			|ru = 'Диаграмма для %1';
			|en = 'Chart for %1'; fa = 'Chart for %1';
			|it = 'Diagramma per %1';
			|pl = 'Diagram dla %1';
			|tr = '%1 için grafik'"),
		AnalysisOption);
	Attribute = New FormAttribute("Chart__" + IDOfFormElement,
			TypeDescription,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	// Adding string props
	TypesArray = New Array;
	TypesArray.Add(Type("FormattedString"));
	TypeDescription = New TypeDescription(TypesArray);
	
	PropsHeader = NStr("vi = 'Tên chỉ số';
						|ru = 'Наименование показателя';
						|en = 'Indicator name'; fa = 'نام شاخص';
						|it = 'Nome dell''indice';
						|pl = 'Nazwa wskaźnika';
						|tr = 'Gösterge adı'");
	Attribute = New FormAttribute("IndicatorName__" + IDOfFormElement,
			TypeDescription,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	ChangeAttributes(AttributesArray);
	
	// Adding the form fields
	ItemTitle = NStr("vi = 'Trạng thái';
					|ru = 'Статусы';
					|en = 'Statuses'; fa = 'وضعیت‌ها';
					|it = 'Stati';
					|pl = 'Statusy';
					|tr = 'Durumlar'");
	GroupIndicatorHeader = HorizontalGroup("Title__" + IDOfFormElement,
			ItemTitle,
			Items_Group);
	FillPropertyValues(GroupIndicatorHeader, HeaderElementGroupStyle());
	
	NameField_1 = Items.Insert("IndicatorName__" + IDOfFormElement,
		Type("FormField"), GroupIndicatorHeader); // FormField
	NameField_1.DataPath = "IndicatorName__" + IDOfFormElement;
	NameField_1.ToolTip = ThisObject["IndicatorName__" + IDOfFormElement];
	Style = HeaderStyle();
	NameField_1.Type = Style.FieldKind;
	FillPropertyValues(NameField_1, Style);
	
	ChartField = Items.Insert("Chart__" + IDOfFormElement, Type("FormField"), Items_Group); // FormField
	ChartField.DataPath = "Chart__" + IDOfFormElement;
	Style = ChartDisplayStyle();
	ChartField.Type = Style.FieldKind;
	FillPropertyValues(ChartField, Style);
	
	SetNameOfIndicator(AnalysisOption, IDOfFormElement, DataSource);
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		Chart = ThisObject["Chart__" + IDOfFormElement];
		Chart = TargetValueMonitoring.FillInChartForMonitor(Chart,
			AnalysisOption, DataSource);
	Else
		Chart = ThisObject["Chart__" + IDOfFormElement];
		
		If DataSource.Property("ErrorDescription") Then
			ErrorDescription = DataSource.ErrorDescription;
		Else
			ErrorDescription = NStr("vi = 'Lỗi tính toán chỉ số';
									|ru = 'Ошибка расчета показателя';
									|en = 'Indicator calculation error'; fa = 'Indicator calculation error';
									|it = 'Errore di calcolo';
									|pl = 'Błąd obliczenia wskaźnika';
									|tr = 'Gösterge hesaplama hatası'");
		EndIf;
		
		Chart = TargetValueMonitoring.GetChartForCalculationErrors(Chart, ErrorDescription);
	EndIf;
EndProcedure

// Adds form elements for the table view"
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - 
//	DataSource - Structure - contains the calculation results for the analysis option.
//	Items_Group - FormGroup - Group forms to which you want to add the form elements.
//	IDOfFormElement - String - a string containing the unique ID of the form element.
//
&AtServer
Procedure DrawTable(AnalysisOption, DataSource, Items_Group, IDOfFormElement)
	DisplayTotalInTable = (Not TabularAnalysisOptionsWithResults.FindByValue(AnalysisOption) = Undefined);
	
	EmptyDataSource = DataSource.IsEmpty;
	CalculationError = DataSource.CalculationError;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	
	AttributesArray = New Array;
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant Then
		TypesArray = New Array;
		TypesArray.Add(Type("ValueTable"));
		TypeDescription = New TypeDescription(TypesArray);
		
		PropsHeader = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Bảng cho %1';
				|ru = 'Таблица для %1';
				|en = 'Table for %1'; fa = 'Table for %1';
				|it = 'Tabella per %1';
				|pl = 'Tabela dla %1';
				|tr = '%1 için tablo'"),
			AnalysisOption);
		Attribute = New FormAttribute("ValueTable__" + IDOfFormElement,
				TypeDescription,
				"",
				PropsHeader);
		AttributesArray.Add(Attribute);
	Else
		TypesArray = New Array;
		TypesArray.Add(Type("Chart"));
		TypeDescription = New TypeDescription(TypesArray);
		
		PropsHeader = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Biểu đồ cho %1';
				|ru = 'Диаграмма для %1';
				|en = 'Chart for %1'; fa = 'Chart for %1';
				|it = 'Diagramma per %1';
				|pl = 'Diagram dla %1';
				|tr = '%1 için grafik'"),
			AnalysisOption);
		Attribute = New FormAttribute("Chart__" + IDOfFormElement,
				TypeDescription,
				"",
				PropsHeader);
		AttributesArray.Add(Attribute);
	EndIf;
	
	// Adding string props
	TypesArray = New Array;
	TypesArray.Add(Type("FormattedString"));
	DescriptionOfFormattedStringTypes = New TypeDescription(TypesArray);
	
	PropsHeader = NStr("vi = 'Tên chỉ số';
						|ru = 'Наименование показателя';
						|en = 'Indicator name'; fa = 'نام شاخص';
						|it = 'Nome dell''indice';
						|pl = 'Nazwa wskaźnika';
						|tr = 'Gösterge adı'");
	Attribute = New FormAttribute("IndicatorName__" + IDOfFormElement,
			DescriptionOfFormattedStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	DescriptionOfStringTypes = New TypeDescription(TypesArray);
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant Then
		PropsHeader = DataSource.DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation;
		Attribute = New FormAttribute("ColumnObjectOfAnalysis" + "__" + IDOfFormElement,
				DescriptionOfStringTypes,
				"ValueTable__" + IDOfFormElement,
				PropsHeader);
		AttributesArray.Add(Attribute);
		
		PropsHeader = DataSource.DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation;
		Attribute = New FormAttribute("ColumnAnalysisValue" + "__" + IDOfFormElement,
				DescriptionOfStringTypes,
				"ValueTable__" + IDOfFormElement,
				PropsHeader);
		AttributesArray.Add(Attribute);
		
		If DisplayTotalInTable Then
			Attribute = New FormAttribute("SummaryTableOfValues__" + IDOfFormElement, DescriptionOfStringTypes);
			AttributesArray.Add(Attribute);
		EndIf;
	EndIf;
	
	ChangeAttributes(AttributesArray);
	
	// Fill in the details of the form details
	SetNameOfIndicator(AnalysisOption, IDOfFormElement, DataSource);
	
	// Adding the form fields
	ItemTitle = NStr("vi = 'Tiêu đề chỉ tiêu';
					|ru = 'Заголовок показателя';
					|en = 'Indicator title'; fa = 'عنوان شاخص';
					|it = 'Titolo dell''indice';
					|pl = 'Nagłówek wskaźnika';
					|tr = 'Gösterge başlığı'");
	GroupIndicatorHeader = HorizontalGroup("Title__" + IDOfFormElement,
		ItemTitle, Items_Group);
	FillPropertyValues(GroupIndicatorHeader, HeaderElementGroupStyle());
	
	NameField_1 = Items.Insert("IndicatorName__" + IDOfFormElement,
		Type("FormField"), GroupIndicatorHeader); // FormField
	NameField_1.DataPath = "IndicatorName__" + IDOfFormElement;
	NameField_1.ToolTip = ThisObject["IndicatorName__" + IDOfFormElement];
	Style = HeaderStyle();
	NameField_1.Type = Style.FieldKind;
	FillPropertyValues(NameField_1, Style);
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		TableField = Items.Insert("ValueTable__" + IDOfFormElement,
			Type("FormTable"), Items_Group);
		TableField.DataPath = "ValueTable__" + IDOfFormElement;
		FillPropertyValues(TableField, TableDisplayStyle());
		
		TableField.Footer = DisplayTotalInTable;
		TableField.ContextMenu.Enabled = False;
		
		TableFieldField = Items.Insert("ColumnObjectOfAnalysis" + "__" + IDOfFormElement,
			Type("FormField"), TableField);
		TableFieldField.Type = FormFieldType.InputField;
		TableFieldField.AutoCellHeight = True;
		TableFieldField.DataPath = "ValueTable__" + IDOfFormElement + "." + "ColumnObjectOfAnalysis"
			+ "__" + IDOfFormElement;
		TableFieldField.ShowInFooter = False;
		
		TableFieldField = Items.Insert("ColumnAnalysisValue" + "__" + IDOfFormElement,
			Type("FormField"), TableField);
		TableFieldField.Type = FormFieldType.InputField;
		TableFieldField.HorizontalAlign = ItemHorizontalLocation.Right;
		TableFieldField.DataPath = "ValueTable__" + IDOfFormElement + "." + "ColumnAnalysisValue"
			+ "__" + IDOfFormElement;
		
		If DisplayTotalInTable Then 
			TableFieldField.FooterDataPath = "SummaryTableOfValues__" + IDOfFormElement;
			TableFieldField.FooterHorizontalAlign = ItemHorizontalLocation.Right;
			TableFieldField.FooterFont = FontImportant();
			
			Value_Number = DataSource.Data.Total(
				DataSource.DynamicPropertiesOfAnalysisVariant.AnalysisValue);
			ThisObject["SummaryTableOfValues__" + IDOfFormElement] = Value_Number;
		EndIf;
		
		TargetValueMonitoring.FillInTableForMonitor(
			ThisObject["ValueTable__" + IDOfFormElement],
			IDOfFormElement,
			AnalysisOption,
			DataSource);
		
	Else
		ChartField = Items.Insert("Chart__" + IDOfFormElement, Type("FormField"), Items_Group); // FormField
		ChartField.DataPath = "Chart__" + IDOfFormElement;
		Style = ChartDisplayStyle();
		ChartField.Type = Style.FieldKind;
		FillPropertyValues(ChartField, Style);
		
		Chart = ThisObject["Chart__" + IDOfFormElement];
		
		If DataSource.Property("ErrorDescription") Then
			ErrorDescription = DataSource.ErrorDescription;
		Else
			ErrorDescription = NStr("vi = 'Lỗi tính toán chỉ số';
									|ru = 'Ошибка расчета показателя';
									|en = 'Indicator calculation error'; fa = 'Indicator calculation error';
									|it = 'Errore di calcolo';
									|pl = 'Błąd obliczenia wskaźnika';
									|tr = 'Gösterge hesaplama hatası'");
		EndIf;
		
		Chart = TargetValueMonitoring.GetChartForCalculationErrors(Chart, ErrorDescription);
	EndIf;
EndProcedure

// Adds form elements for the "Brief" display type"
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues -
//	DataSource - Structure - contains the calculation results for the analysis option.
//	Items_Group - FormGroup - Group forms to which you want to add the form elements.
//	IDOfFormElement - String - a string containing the unique ID of the form element.
//
&AtServer
Procedure DrawBriefly(AnalysisOption, DataSource, Items_Group, IDOfFormElement)
	AttributesArray = New Array;
	
	ShowCurValueAndMetricDetails = (Not AnalysisOptionWithDetails.FindByValue(AnalysisOption) = Undefined);
	
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	
	EmptyDataSource = DataSource.IsEmpty;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	CalculationError = DataSource.CalculationError;
	
	TypesArray = New Array;
	TypesArray.Add(Type("FormattedString"));
	DescriptionOfFormattedStringTypes = New TypeDescription(TypesArray);
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant Then
		PropsHeader = NStr("vi = 'Giá trị chỉ tiêu';
							|ru = 'Значение показателя';
							|en = 'Indicator value'; fa = 'مقدار شاخص';
							|it = 'Valore dell''indicatore';
							|pl = 'Wartość wskaźnika';
							|tr = 'Gösterge değeri'");
		Attribute = New FormAttribute("Value__" + IDOfFormElement,
				DescriptionOfFormattedStringTypes,
				"",
				PropsHeader);
		AttributesArray.Add(Attribute);
	Else
		TypesArray = New Array;
		TypesArray.Add(Type("Chart"));
		TypeDescription = New TypeDescription(TypesArray);
		
		PropsHeader = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Biểu đồ cho %1';
				|ru = 'Диаграмма для %1';
				|en = 'Chart for %1'; fa = 'Chart for %1';
				|it = 'Diagramma per %1';
				|pl = 'Diagram dla %1';
				|tr = '%1 için grafik'"),
			AnalysisOption);
		Attribute = New FormAttribute("Chart__" + IDOfFormElement,
				TypeDescription,
				"",
				PropsHeader);
		AttributesArray.Add(Attribute);
	EndIf;
	
	PropsHeader = NStr("vi = 'Tên chỉ số';
						|ru = 'Наименование показателя';
						|en = 'Indicator name'; fa = 'نام شاخص';
						|it = 'Nome dell''indice';
						|pl = 'Nazwa wskaźnika';
						|tr = 'Gösterge adı'");
	Attribute = New FormAttribute("IndicatorName__" + IDOfFormElement,
			DescriptionOfFormattedStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	ChangeAttributes(AttributesArray);
	
	ItemTitle = NStr("vi = 'Tiêu đề chỉ tiêu';
					|ru = 'Заголовок показателя';
					|en = 'Indicator title'; fa = 'عنوان شاخص';
					|it = 'Titolo dell''indice';
					|pl = 'Nagłówek wskaźnika';
					|tr = 'Gösterge başlığı'");
	GroupIndicatorHeader = HorizontalGroup("Title__" + IDOfFormElement,
		ItemTitle, Items_Group);
	FillPropertyValues(GroupIndicatorHeader, HeaderElementGroupStyle());
	
	// Adding form elements
	NameField_1 = Items.Insert("IndicatorName__" + IDOfFormElement,
		Type("FormField"), GroupIndicatorHeader); // FormField
	NameField_1.DataPath = "IndicatorName__" + IDOfFormElement;
	NameField_1.ToolTip = ThisObject["IndicatorName__" + IDOfFormElement];
	Style = HeaderStyle();
	NameField_1.Type = Style.FieldKind;
	FillPropertyValues(NameField_1, Style);
	
	AttributesOfAnalysisOption = Common.ObjectAttributesValues(AnalysisOption,
		"ValueMultiplier, FractionalPartCalculationAccuracy");
	ValueMultiplier = AttributesOfAnalysisOption.ValueMultiplier;
	FractionalPartCalculationAccuracy = AttributesOfAnalysisOption.FractionalPartCalculationAccuracy;
	
	SetNameOfIndicator(AnalysisOption, IDOfFormElement, DataSource);
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		ValueField = Items.Insert("Value__" + IDOfFormElement, Type("FormField"), Items_Group); // FormField
		ValueField.DataPath = "Value__" + IDOfFormElement;
		Style = TextDisplayStyle();
		ValueField.Type = Style.FieldKind;
		FillPropertyValues(ValueField, Style);
		
		ValueField.SetAction("Click", "Attachable_OpenIndicatorAnalysisByClicking");
	
		LastValue = Round(DataSource.PropertiesOfDataByPeriod.LastValue, FractionalPartCalculationAccuracy);
		DisplayedValue_ = LastValue;
		
		Dimensionality = TrimAll(String(DynamicPropertiesOfAnalysisVariant.Dimensions));
		
		If ValueIsFilled(Dimensionality) Then
			DimensionString_ = " " + Dimensionality;
		Else
			DimensionString_ = "";
		EndIf;
		If ShowCurValueAndMetricDetails Then
			DetailsOfIndicatorLine = "";
			If Not EmptyDataSource And Not PaymentsAreIrrelevant Then
				PenultimateValue = Round(DataSource.PropertiesOfDataByPeriod.PenultimateValue,
					FractionalPartCalculationAccuracy);
			Else
				PenultimateValue = 0;
			EndIf;
			
			If Not PenultimateValue = 0 Then
				RelativeUpdate = Round(100 * (LastValue - PenultimateValue) / PenultimateValue,
					FractionalPartCalculationAccuracy);
				
				If RelativeUpdate > 0 Then
					SignOfChange = "▲";
				ElsIf RelativeUpdate = 0 Then
					SignOfChange = "";
				ElsIf RelativeUpdate < 0 Then
					SignOfChange = "▼";
				EndIf;
				
				DetailsOfIndicatorLine = DetailsOfIndicatorLine + SignOfChange + Chars.NBSp
					+ RelativeUpdate + " %";
			EndIf;
			
			AbsoluteUpdate = LastValue - PenultimateValue;
			
			If AbsoluteUpdate > 0 Then
				SignOfChange = "▲";
			ElsIf AbsoluteUpdate = 0 Then
				SignOfChange = "";
			ElsIf AbsoluteUpdate < 0 Then
				SignOfChange = "▼";
			EndIf;
			
			NumberPresentation = TargetValueMonitoring.GetAbbreviatedPresentationOfNumber(
				AbsoluteUpdate, FractionalPartCalculationAccuracy, ValueMultiplier);
			DetailsOfIndicatorLine = DetailsOfIndicatorLine + 
				?(ValueIsFilled(DetailsOfIndicatorLine), " / ", SignOfChange + Chars.NBSp)
					+ NumberPresentation + DimensionString_;
		EndIf;
		
		StateAndTrendColors = TargetValueMonitoring.GetStateAndTrendIndicatorColors(
			AnalysisOption, DataSource);
		
		StringValue1 = New FormattedString(
			TrimAll(TargetValueMonitoring.GetAbbreviatedPresentationOfNumber(
				DisplayedValue_, 
				FractionalPartCalculationAccuracy, 
				ValueMultiplier) + DimensionString_), 
			FontOfIndicatorValue(),
			StateAndTrendColors.StateColor);
		
		DetailsOfIndicatorLine = New FormattedString(
			?(DetailsOfIndicatorLine = Undefined, "", DetailsOfIndicatorLine), 
			IndexDetailsFont(), 
			StateAndTrendColors.TrendColor);
		
		ThisObject["Value__" + IDOfFormElement] = New FormattedString(
			StringValue1, 
			?(ShowCurValueAndMetricDetails, Chars.LF, ""),
			DetailsOfIndicatorLine);
	Else 
		ChartField = Items.Insert("Chart__" + IDOfFormElement,
			Type("FormField"),
			Items_Group); // FormField
		ChartField.DataPath = "Chart__" + IDOfFormElement;
		Style = ChartDisplayStyle();
		ChartField.Type = Style.FieldKind;
		FillPropertyValues(ChartField, Style);
		FillPropertyValues(ChartField, TextDisplayStyle(), "Height");
		
		ChartField.Height = 3;
		
		Chart = ThisObject["Chart__" + IDOfFormElement];
		
		If DataSource.Property("ErrorDescription") Then
			ErrorDescription = DataSource.ErrorDescription;
		Else
			ErrorDescription = NStr("vi = 'Lỗi tính toán chỉ số';
									|ru = 'Ошибка расчета показателя';
									|en = 'Indicator calculation error'; fa = 'Indicator calculation error';
									|it = 'Errore di calcolo';
									|pl = 'Błąd obliczenia wskaźnika';
									|tr = 'Gösterge hesaplama hatası'");
		EndIf;
		
		Chart = TargetValueMonitoring.GetChartForCalculationErrors(Chart, ErrorDescription);
	EndIf;
EndProcedure

// Adds elements of the indicator reference information form for analyzing related data.
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - 
//	DataSource - Structure - contains the calculation results for the analysis option.
//	Items_Group - FormGroup - Group forms to which you want to add the form elements.
//	IDOfFormElement - String - a string containing the unique ID of the form element.
//
&AtServer
Procedure DrawIndicatorHelpFields(AnalysisOption, DataSource, Items_Group, IDOfFormElement)
	AttributesArray = New Array;
	
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	
	EmptyDataSource = DataSource.IsEmpty;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	CalculationError = DataSource.CalculationError;
	
	// Adding the string details of the form
	DescriptionOfStringTypes = TargetValueMonitoring.GetDescriptionOfStringTypes(0);
	
	PropsHeader = NStr("vi = 'Mục tiêu';
						|ru = 'Цель';
						|en = 'Target'; fa = 'هدف';
						|it = 'Obiettivo';
						|pl = 'Cel';
						|tr = 'Hedef'");
	Attribute = New FormAttribute("GoalValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Xu hướng mục tiêu';
						|ru = 'Целевой тренд';
						|en = 'Target trend'; fa = 'روند هدف';
						|it = 'Tendenza obiettivo';
						|pl = 'Trend docelowy';
						|tr = 'Hedef eğilim'");
	Attribute = New FormAttribute("TargetTrendValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Giá trị mục tiêu';
						|ru = 'Целевые значения';
						|en = 'Target values'; fa = 'مقادیر هدف';
						|it = 'Valori obiettivo';
						|pl = 'Wartości docelowe';
						|tr = 'Hedef değerler'");
	Attribute = New FormAttribute("TargetValuesValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Trạng thái';
						|ru = 'Состояние';
						|en = 'State'; fa = 'وضعیت';
						|it = 'Stato';
						|pl = 'Status';
						|tr = 'Durum'");
	Attribute = New FormAttribute("ActualStateValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Xu hướng';
						|ru = 'Тренд';
						|en = 'Trend'; fa = 'Trend';
						|it = 'Trend';
						|pl = 'Trend';
						|tr = 'Eğilim'");
	Attribute = New FormAttribute("ActualTrendValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Giá trị';
						|ru = 'Значение';
						|en = 'Value'; fa = 'مقدار';
						|it = 'Valore';
						|pl = 'Wartość';
						|tr = 'Değer'");
	Attribute = New FormAttribute("ActualValueValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Người chịu trách nhiệm';
						|ru = 'Ответственный';
						|en = 'Person responsible'; fa = 'شخص مسئول';
						|it = 'Responsabile';
						|pl = 'Autor';
						|tr = 'Sorumlu'");
	Attribute = New FormAttribute("ResponsiblePersonValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	PropsHeader = NStr("vi = 'Công thức';
						|ru = 'Формула';
						|en = 'Formula'; fa = 'فرمول';
						|it = 'Formula';
						|pl = 'Wzór';
						|tr = 'Formül'");
	Attribute = New FormAttribute("FormulaValue__" + IDOfFormElement,
			DescriptionOfStringTypes,
			"",
			PropsHeader);
	AttributesArray.Add(Attribute);
	
	ChangeAttributes(AttributesArray);
	
	ValueField = Items.Insert("GoalValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "GoalValue__" + IDOfFormElement;
	Style = StyleOfReferenceInformation();
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	ValueField = Items.Insert("TargetTrendValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "TargetTrendValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	ValueField = Items.Insert("TargetValuesValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "TargetValuesValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	ValueField = Items.Insert("ActualStateValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "ActualStateValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	ValueField = Items.Insert("ActualTrendValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "ActualTrendValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	ValueField = Items.Insert("ActualValueValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "ActualValueValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		ValueField.TextColor = StyleColors.NoteText;
	Else
		ValueField.TextColor = StyleColors.ErrorNoteText;
	EndIf;
	
	ValueField = Items.Insert("ResponsiblePersonValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "ResponsiblePersonValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	ValueField = Items.Insert("FormulaValue__" + IDOfFormElement,
		Type("FormField"), Items_Group); // FormField
	ValueField.DataPath = "FormulaValue__" + IDOfFormElement;
	ValueField.Type = Style.FieldKind;
	FillPropertyValues(ValueField, Style);
	
	DataOfAnalysisVariant = Common.ObjectAttributesValues(AnalysisOption,
		"Owner, ValueMultiplier, FractionalPartCalculationAccuracy, EmployeeResponsible");
	TargetData = Common.ObjectAttributesValues(DataOfAnalysisVariant.Owner,
		"TargetTrend, CalculationFormula");
	
	// Fill in the values of the created fields
	PropertiesOfAnalysisVariant = TargetValueMonitoring.GetPropertiesOfAnalysisVariant(AnalysisOption,
		DataSource);
	ThisObject["GoalValue__" + IDOfFormElement] = DataOfAnalysisVariant.Owner;
	ThisObject["TargetTrendValue__" + IDOfFormElement] = TargetData.TargetTrend;
	ThisObject["TargetValuesValue__" + IDOfFormElement] = PropertiesOfAnalysisVariant.TargetValuesRanges;
	
	ValueMultiplier = DataOfAnalysisVariant.ValueMultiplier;
	FractionalPartCalculationAccuracy = DataOfAnalysisVariant.FractionalPartCalculationAccuracy;
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		LastValue = Round(DataSource.PropertiesOfDataByPeriod.LastValue, FractionalPartCalculationAccuracy);
		DisplayedValue_ = LastValue;
	Else 
		LastValue = 0;
		DisplayedValue_ = 0;
	EndIf;
	
	Dimensionality = TrimAll(String(DynamicPropertiesOfAnalysisVariant.Dimensions));
	
	If ValueIsFilled(Dimensionality) Then
		DimensionString_ = " " + Dimensionality;
	Else
		DimensionString_ = "";
	EndIf;
	
	ListOfProperties = DataSource.PropertiesOfAnalysisAndTrendZone;
	ThisObject["ActualStateValue__" + IDOfFormElement] = ListOfProperties.ExplanationOfTheStatus;
	ThisObject["ActualTrendValue__" + IDOfFormElement] = ListOfProperties.ExplanationOfTheTrend;
	
	FormAttributeName = "ActualValueValue__" + IDOfFormElement;
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		NumberPresentation = TargetValueMonitoring.GetAbbreviatedPresentationOfNumber(DisplayedValue_,
			FractionalPartCalculationAccuracy, ValueMultiplier);
		ThisObject[FormAttributeName] = TrimAll(NumberPresentation + DimensionString_);
	Else
		ThisObject[FormAttributeName] = DataSource.ErrorDescription;
	EndIf;
	
	ThisObject["FormulaValue__" + IDOfFormElement]	= TargetData.CalculationFormula;
	ThisObject["ResponsiblePersonValue__" + IDOfFormElement]	= DataOfAnalysisVariant.EmployeeResponsible;
EndProcedure

// Adds a group of form elements of the specified width and height that contains an empty image.
// Is used to align elements of the monitor.
// 
// Parameters:
//	Items_Group - FormGroup - group, in cat. an element is added
//	IDOfFormElement - String - unique ID of the element to add
//	ElementStyle - Structure - structure containing modifiable properties of the form element
//		Key-String - name of the property to be modified
//		Value-String - value of the property to be modified.
//
&AtServer 
Procedure DrawEmptyElement(Items_Group, IDOfFormElement, ElementStyle)
	// Let's add the decoration of the form
	DecorationField = Items.Insert("LevellingItem__" + IDOfFormElement,
		Type("FormDecoration"), Items_Group);
	DecorationField.Type = FormDecorationType.Picture;
	DecorationField.Picture = New Picture;
	DecorationField.Title = NStr("vi = 'Phần tử so sánh';
								|ru = 'Выравнивающий элемент';
								|en = 'Levelling item'; fa = 'Levelling item';
								|it = 'Elemento di livellamento';
								|pl = 'Element wyrównujący';
								|tr = 'Dengeleme öğesi'");
	DecorationField.Enabled = False;
	
	FillPropertyValues(DecorationField, ElementStyle);
EndProcedure

// Calls the procedures for adding monitor form elements-summary view, charts, and tables.
// 
// Parameters:
//	MonitorContent - Structure - contains a set of data sources and generalized information about the sources.
//
&AtServer
Procedure DrawMonitorElements(MonitorContent)
	OutputStructure = TargetValueMonitoring.OutputStructure(MonitorContent);
	
	NumberOfIndicators = CalculateNumberOfIndicatorsByOutputStructure(OutputStructure);
	If NumberOfIndicators < SettingsStructure.NumberOfIndicatorMonitorColumns Then
		SettingsStructure.Insert("NumberOfIndicatorMonitorColumns", NumberOfIndicators);
	EndIf;
	
	ColumnWidth_ = 0;

	CreateBasicStructureOfFormElements(MonitorContent, OutputStructure);
	
	If AnalysisModeOfTheRelated Then
		// Let's create form elements for the analyzed indicator
		For Each OutputItem In OutputStructure.OutputOrder Do
			If OutputItem = "Analyzed" Then
				ViewSearchRelated = Enums.KindsOfAssociatedIndicatorSearch.EmptyRef();
			ElsIf OutputItem = "DependentItems" Then
				ViewSearchRelated = Enums.KindsOfAssociatedIndicatorSearch.DependentIndicators;
			ElsIf OutputItem = "Influencers" Then
				ViewSearchRelated = Enums.KindsOfAssociatedIndicatorSearch.InfluencingIndicators;
			EndIf;
			If OutputStructure[OutputItem].Count() > 0 Then
				DrawMonitorElementsTakingIntoAccountTypeOfAnalysisOfInterrelated(OutputStructure[OutputItem],
					ViewSearchRelated);
			EndIf;
		EndDo;
	Else 
		If SettingsStructure.IndicatorGroupingOption = "ByState" Then
			For Each OutputItem In OutputStructure.OutputOrder Do
				State = StrReplace(StrReplace(StrReplace(OutputItem, "Indicators", ""), "Brief1", ""), "More", "");
				If OutputStructure[OutputItem].Count() > 0 Then
					DrawMonitorElementsBasedOnState(OutputStructure[OutputItem], State);
				EndIf;
			EndDo;
		ElsIf SettingsStructure.IndicatorGroupingOption = "ByGoalCategory" Then
			For Each OutputItem In OutputStructure.OutputOrder Do
				Id = StrReplace(StrReplace(StrReplace(OutputItem, "Indicators", ""), "Brief1", ""), "More", "");
				If OutputStructure[OutputItem].Count() > 0 Then
					DrawMonitorElementsWithGroupsInMind(OutputStructure[OutputItem], Id);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

// Calls procedures for adding monitor form elements in the related analysis mode.
// 
// Parameters:
//	CollectionOfAnalysisOptions - ValueTable - contains data sources and their properties
//	ViewSearchRelated - EnumRef.KindsOfAssociatedIndicatorSearch - the dependent variable, impact, connected, everything.
//
&AtServer 
Procedure DrawMonitorElementsTakingIntoAccountTypeOfAnalysisOfInterrelated(CollectionOfAnalysisOptions, ViewSearchRelated)
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	DisplayOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	If Not ViewSearchRelated = Enums.KindsOfAssociatedIndicatorSearch.EmptyRef() Then
		SearchTypeName = TargetValueMonitoring.GetNameOfEnumerationValue(ViewSearchRelated);
	Else
		SearchTypeName = "AnalyzedIndicator";
	EndIf;
	
	For Each MonitorElement In CollectionOfAnalysisOptions Do 
		AnalysisOption = MonitorElement.AnalysisOption;
		DataSourceStorage = MonitorElement.DataSource; // ValueStorage
		DataSource = DataSourceStorage.Get();
		DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
		ViewOption = DisplayOptions.Chart;
		TypeOfPresentationOfNumbers = AnalysisOption.ValueMultiplier;
		IDOfFormElement = StrReplace(String(AnalysisOption.UUID()),"-","_");
		
		GroupColumnElements = Items["GroupColumnElements" + SearchTypeName + "__" + "1"];
		FillPropertyValues(GroupColumnElements, MetricsColumnGroupStyle());
		
		GroupElement = Items.Add("ElementDiagram__" + IDOfFormElement,
			Type("FormGroup"), GroupColumnElements);
		GroupElement.Type = FormGroupType.UsualGroup;
		GroupElement.Representation = UsualGroupRepresentation.NormalSeparation;
		GroupElement.ShowTitle = False;
		
		If TypeOfPresentationOfNumbers = NumberPresentationKinds.Unchanged Then
			GroupElement.Title = AnalysisOption.Owner.ShortNameOfTargetValue
				+ ?(Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions),
						" (" + DynamicPropertiesOfAnalysisVariant.Dimensions + ")", "");
		Else
			GroupElement.Title = AnalysisOption.Owner.ShortNameOfTargetValue
				+ " (" + TargetValueMonitoring.GetNumberPresentationString(AnalysisOption)
				+ ?(Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions),
						" " + DynamicPropertiesOfAnalysisVariant.Dimensions, "") + ")";
		EndIf;
		
		GroupElement.VerticalStretch = False;
		
		// Let's fill the element with content based on the templates of options
		DrawMetricElements(AnalysisOption,
				DataSource,
				ViewOption,
				GroupElement,
				IDOfFormElement);
		
		// Fill in the reference information about the indicator
		GroupColumnElements = Items["GroupColumnElements" + SearchTypeName + "__" + "2"];
		FillPropertyValues(GroupColumnElements, MetricsColumnGroupStyle());
		
		HelpGroup = Items.Add("IndicatorHelpElement__" + IDOfFormElement,
			Type("FormGroup"), GroupColumnElements);
		HelpGroup.Type = FormGroupType.UsualGroup;
		HelpGroup.Representation = UsualGroupRepresentation.NormalSeparation;
		HelpGroup.Title = NStr("vi = 'Thông tin về chỉ số';
								|ru = 'Справка о показателе';
								|en = 'Certificate of target'; fa = 'Certificate of target';
								|it = 'Informazioni circa l''indicatore';
								|pl = 'Informacja o wskaźniku';
								|tr = 'Gösterge raporu'");
		HelpGroup.TitleFont = FontImportant();
		
		// Let's fill the element with content based on the templates of options
		DrawIndicatorHelpFields(AnalysisOption, DataSource, HelpGroup, IDOfFormElement);
	EndDo;
EndProcedure

// Calls procedures for adding monitor form elements to a group in importance output mode.
// 
// Parameters:
//	CollectionOfAnalysisOptions - ValueTable - contains data sources and their properties
//	State - String - status of the indicator. It can take the following values: whole Reached, acceptable State, unacceptable State, state Undefined, calculated Error.
//
&AtServer 
Procedure DrawMonitorElementsBasedOnState(CollectionOfAnalysisOptions, State)
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	DisplayOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	CounterOfLineElements = 1;
	NumberOfMetricsInCollection = CollectionOfAnalysisOptions.Count();
	NumberOfUnchartedIndicators = NumberOfMetricsInCollection;
	
	For Each MonitorElement In CollectionOfAnalysisOptions Do 
		AnalysisOption = MonitorElement.AnalysisOption;
		DataSourceStorage = MonitorElement.DataSource; // ValueStorage
		DataSource = DataSourceStorage.Get();
		DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
		ViewOption = MonitorElement.ViewOption;
		TypeOfPresentationOfNumbers = AnalysisOption.ValueMultiplier;
		IDOfFormElement = StrReplace(String(AnalysisOption.UUID()),"-","_");
		
		If ViewOption = DisplayOptions.Brief1 Then
			GroupNameSuffix = "Brief1";
		Else
			GroupNameSuffix = "More";
		EndIf;
		
		GroupColumnElements = Items["GroupColumnElements" + GroupNameSuffix + State + "__"
			+ CounterOfLineElements];
		
		GroupOfIndicatorElements = Items.Add("Item__" + IDOfFormElement,
			Type("FormGroup"), GroupColumnElements); // FormGroup
		Style = IndicatorElementGroupStyle();
		GroupOfIndicatorElements.Type = Style.Compositor;
		FillPropertyValues(GroupOfIndicatorElements, Style);
		
		If TypeOfPresentationOfNumbers = NumberPresentationKinds.Unchanged Then
			GroupOfIndicatorElements.Title = AnalysisOption.Description 
				+ ?(Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions),
						" (" + DynamicPropertiesOfAnalysisVariant.Dimensions + ")", "");
		Else
			GroupOfIndicatorElements.Title = AnalysisOption.Description 
				+ " (" + TargetValueMonitoring.GetNumberPresentationString(AnalysisOption)
				+ ?(Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions),
						" " + DynamicPropertiesOfAnalysisVariant.Dimensions, "") + ")";
		EndIf;
		
		// Let's fill the element with content based on the templates of options
		DrawMetricElements(AnalysisOption,
				DataSource,
				ViewOption,
				GroupOfIndicatorElements,
				IDOfFormElement);
		
		NumberOfUnchartedIndicators = NumberOfUnchartedIndicators - 1;
		
		If NumberOfUnchartedIndicators = 0
		   And CounterOfLineElements < SettingsStructure.NumberOfIndicatorMonitorColumns Then
			
			NeedToAddElements = SettingsStructure.NumberOfIndicatorMonitorColumns - CounterOfLineElements;
			For CountAlignmentElements = 1 To NeedToAddElements Do
				TagName = "GroupColumnElements" + GroupNameSuffix + State + "__"
					+ (CounterOfLineElements + CountAlignmentElements);
				GroupColumnElements = Items[TagName];
				
				TagName = "LevellingItemContainer" + IDOfFormElement + "__"
					+ CountAlignmentElements;
				GroupOfIndicatorElements = Items.Add(TagName, Type("FormGroup"), GroupColumnElements); // FormGroup
				Style = IndicatorElementGroupStyle();
				GroupOfIndicatorElements.Type = Style.Compositor;
				FillPropertyValues(GroupOfIndicatorElements, Style);
				
				GroupOfIndicatorElements.Title = NStr("vi = 'Kho chứa yếu tố ngang bằng';
														|ru = 'Контейнер выравнивающего элемента';
														|en = 'Levelling item container'; fa = 'Levelling item container';
														|it = 'Contenitore elemento di allineamento';
														|pl = 'Kontener wyrównującego elementu';
														|tr = 'Dengeleme öğesi konteyneri'");
				
				TagName = IDOfFormElement + "__" + CountAlignmentElements;
				DrawEmptyElement(GroupOfIndicatorElements,
						TagName,
						MetricDisplayStyleBasic());
			EndDo;
		EndIf;
		
		CounterOfLineElements = CounterOfLineElements + 1;
		
		If CounterOfLineElements > SettingsStructure.NumberOfIndicatorMonitorColumns Then
			CounterOfLineElements = 1;
		EndIf;
	EndDo;
EndProcedure

// Calls procedures for adding monitor form elements to a group in output mode by goal category.
// 
// Parameters:
//	CollectionOfAnalysisOptions - ValueTable - contains data sources and their properties
//	GroupID - String - ID of the group to add form elements to.
//
&AtServer 
Procedure DrawMonitorElementsWithGroupsInMind(CollectionOfAnalysisOptions, GroupID)
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	DisplayOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	CounterOfLineElements = 1;
	NumberOfMetricsInCollection = CollectionOfAnalysisOptions.Count();
	NumberOfUnchartedIndicators = NumberOfMetricsInCollection;
	
	For Each MonitorElement In CollectionOfAnalysisOptions Do 
		AnalysisOption = MonitorElement.AnalysisOption;
		DataSourceStorage = MonitorElement.DataSource; // ValueStorage
		DataSource = DataSourceStorage.Get();
		DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
		ViewOption = MonitorElement.ViewOption;
		TypeOfPresentationOfNumbers = AnalysisOption.ValueMultiplier;
		IDOfFormElement = StrReplace(String(AnalysisOption.UUID()),"-","_");
		
		If ViewOption = DisplayOptions.Brief1 Then
			GroupNameSuffix = "Brief1";
		Else
			GroupNameSuffix = "More";
		EndIf;
		
		TagName = "GroupColumnElements" + GroupNameSuffix + GroupID + "__"
			+ CounterOfLineElements;
		GroupColumnElements = Items[TagName];
		
		GroupOfIndicatorElements = Items.Add("Item__" + IDOfFormElement,
			Type("FormGroup"), GroupColumnElements); // FormGroup
		Style = IndicatorElementGroupStyle();
		GroupOfIndicatorElements.Type = Style.Compositor;
		FillPropertyValues(GroupOfIndicatorElements, Style);
		
		If TypeOfPresentationOfNumbers = NumberPresentationKinds.Unchanged Then
			GroupOfIndicatorElements.Title = AnalysisOption.Owner.ShortNameOfTargetValue
				+ " (" + DynamicPropertiesOfAnalysisVariant.Dimensions + ")";
		Else
			GroupOfIndicatorElements.Title = AnalysisOption.Owner.ShortNameOfTargetValue
				+ " (" + TargetValueMonitoring.GetNumberPresentationString(AnalysisOption)
				+ " " + DynamicPropertiesOfAnalysisVariant.Dimensions + ")";
		EndIf;
		
		// Let's fill the element with content based on the templates of options
		DrawMetricElements(AnalysisOption,
				DataSource,
				ViewOption,
				GroupOfIndicatorElements,
				IDOfFormElement);
		
		NumberOfUnchartedIndicators = NumberOfUnchartedIndicators - 1;
		
		If NumberOfUnchartedIndicators = 0
			And CounterOfLineElements < SettingsStructure.NumberOfIndicatorMonitorColumns Then
			
			NeedToAddElements = SettingsStructure.NumberOfIndicatorMonitorColumns - CounterOfLineElements;
			For CountAlignmentElements = 1 To NeedToAddElements Do
				TagName = "GroupColumnElements" + GroupNameSuffix + GroupID + "__"
					+ (CounterOfLineElements + CountAlignmentElements);
				GroupColumnElements = Items[TagName];
				
				TagName = "LevellingItemContainer" + IDOfFormElement + "__"
					+ CountAlignmentElements;
				GroupOfIndicatorElements = Items.Add(TagName, Type("FormGroup"), GroupColumnElements); // FormGroup
				Style = IndicatorElementGroupStyle();
				GroupOfIndicatorElements.Type = Style.Compositor;
				FillPropertyValues(GroupOfIndicatorElements, Style);
				
				GroupOfIndicatorElements.Title = NStr("vi = 'Kho chứa yếu tố ngang bằng';
														|ru = 'Контейнер выравнивающего элемента';
														|en = 'Levelling item container'; fa = 'Levelling item container';
														|it = 'Contenitore elemento di allineamento';
														|pl = 'Kontener wyrównującego elementu';
														|tr = 'Dengeleme öğesi konteyneri'");
				
				TagName = IDOfFormElement + "__" + CountAlignmentElements;
				DrawEmptyElement(GroupOfIndicatorElements,
						TagName,
						MetricDisplayStyleBasic());
			EndDo;
		EndIf;
		
		CounterOfLineElements = CounterOfLineElements + 1;
		
		If CounterOfLineElements > SettingsStructure.NumberOfIndicatorMonitorColumns Then
			CounterOfLineElements = 1;
		EndIf;
	EndDo;
EndProcedure

// Calls procedures for adding form elements for the passed analysis option
// 
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - option to create form elements for
//	DataSource - Structure - contains calculation results for the analysis option
//	ViewOption - EnumRef.DisplayOptionsOfAnalysisOptions - brief, chart, table
//	Items_Group - FormGroup - group to add items to
//	IDOfFormElement - String - string GUID of the analysis option ("- "replaced with"_").
//
&AtServer
Procedure DrawMetricElements(AnalysisOption, DataSource, ViewOption, Items_Group, IDOfFormElement)
	If ViewOption = Enums.DisplayOptionsOfAnalysisOptions.Chart Then
		
		DrawDiagram(AnalysisOption, DataSource, Items_Group, IDOfFormElement);
		
	ElsIf ViewOption = Enums.DisplayOptionsOfAnalysisOptions.Brief1 Then
		
		DrawBriefly(AnalysisOption, DataSource, Items_Group, IDOfFormElement);
		
	ElsIf ViewOption = Enums.DisplayOptionsOfAnalysisOptions.Table Then
		
		DrawTable(AnalysisOption, DataSource, Items_Group, IDOfFormElement);
		
	EndIf;
	
	AddAnalysisOptionsCommands(AnalysisOption, Items_Group, IDOfFormElement, ViewOption);
EndProcedure

// Creates a group form for the subsequent adding of form elements of the options analysis.
// 
// Parameters:
//	MonitorContent - Structure - contains a set of data sources and generalized information about the sources.
//
&AtServer
Procedure CreateBasicStructureOfFormElements(MonitorContent, OutputStructure)
	SetOfDataSources = MonitorContent.SetOfDataSources;
	
	DisplayOptionsOfAnalysisOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	ItemTitle = NStr("vi = 'Chỉ tiêu';
					|ru = 'Показатели';
					|en = 'Indicators'; fa = 'شاخص‌ها';
					|it = 'Indici';
					|pl = 'Wskaźniki';
					|tr = 'Göstergeler'");
	GroupIndicators = VerticalGroup("GroupIndicators",
			ItemTitle,
			Items.MainMonitorPage);
	
	If AnalysisModeOfTheRelated Then
		AnalysisOption = TargetValueMonitoringServerCall.GetPropertiesOfAnalysisVariantById(
			Parameters.IDOfTheAnalysisOption);
		VariantAnalysisLink = AnalysisOption.Ref; // CatalogRef.AnalysisOptionsOfTargetValues - 
		NameOfAnalysisOption = VariantAnalysisLink.Description;
		
		ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chỉ số được phân tích ""%1""';
				|ru = 'Анализируемый показатель ""%1""';
				|en = 'Analyzed indicator ""%1""'; fa = 'Analyzed indicator ""%1""';
				|it = 'Indice analizzato ""%1""';
				|pl = 'Analizowany wskaźnik ""%1""';
				|tr = 'Analiz edilen gösterge ""%1""'",),
			NameOfAnalysisOption);
		GroupAnalyzedIndicator = HorizontalGroup("GroupAnalyzedIndicator",
				ItemTitle,
				GroupIndicators);
		FillPropertyValues(GroupAnalyzedIndicator, MetricGroupStyle());
		
		// There are always 2 columns in the relationship analysis mode - a diagram, a reference about indicators.
		For Cnt = 1 To 2 Do
			TagName = "GroupColumnElements" + "AnalyzedIndicator" + "__" + Cnt;
			ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cột số %1';
					|ru = 'Колонка №%1';
					|en = 'Column #%1'; fa = 'Column #%1';
					|it = 'Colonna №%1';
					|pl = 'Kolumna №%1';
					|tr = 'Sütun №%1'"),
				Cnt);
			VerticalGroup(TagName,
					ItemTitle,
					GroupAnalyzedIndicator);
		EndDo;
		
		SelectionOfDependents = New Structure("Group", Enums.KindsOfAssociatedIndicatorSearch.DependentIndicators);
		DependentItems = SetOfDataSources.FindRows(SelectionOfDependents);
		
		If DependentItems.Count() > 0 Then
			SearchTypeName = TargetValueMonitoring.GetNameOfEnumerationValue(
				Enums.KindsOfAssociatedIndicatorSearch.DependentIndicators);
			
			ItemTitle = NStr("vi = 'Các chỉ tiêu phụ thuộc';
							|ru = 'Зависимые показатели';
							|en = 'Dependent indicators'; fa = 'شاخص‌های وابسته';
							|it = 'Indicatori dipendenti';
							|pl = 'Wskaźniki zależne';
							|tr = 'Bağımlı göstergeler'");
			DependentGroup = HorizontalGroup("Group" + SearchTypeName,
					ItemTitle,
					GroupIndicators);
			FillPropertyValues(DependentGroup, MetricGroupStyle());
			
			// There are always 2 columns in the relationship analysis mode - a diagram, a reference about indicators.
			For Cnt = 1 To 2 Do
				TagName = "GroupColumnElements" + SearchTypeName + "__" + Cnt;
				ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cột số %1';
						|ru = 'Колонка №%1';
						|en = 'Column #%1'; fa = 'Column #%1';
						|it = 'Colonna №%1';
						|pl = 'Kolumna №%1';
						|tr = 'Sütun №%1'"),
					Cnt);
				VerticalGroup(TagName,
						ItemTitle,
						DependentGroup);
			EndDo;
		EndIf;
		
		SelectionOfInfluencers = New Structure("Group", Enums.KindsOfAssociatedIndicatorSearch.InfluencingIndicators);
		Influencers  = SetOfDataSources.FindRows(SelectionOfInfluencers);
		
		If Influencers.Count() > 0 Then
			SearchTypeName = TargetValueMonitoring.GetNameOfEnumerationValue(
				Enums.KindsOfAssociatedIndicatorSearch.InfluencingIndicators);
			
			ItemTitle = NStr("vi = 'Chỉ số ảnh hưởng';
							|ru = 'Влияющие показатели';
							|en = 'Influencing indicators'; fa = 'شاخص‌های تأثیرگذار';
							|it = 'Indicatori di influenza';
							|pl = 'Wskaźniki wpływające';
							|tr = 'Etkileyen göstergeler'");
			InfluencersGroup = HorizontalGroup("Group" + SearchTypeName,
					ItemTitle,
					GroupIndicators);
			FillPropertyValues(InfluencersGroup, MetricGroupStyle());
			
			// There are always 2 columns in the relationship analysis mode - a diagram, a reference about indicators.
			For Cnt = 1 To 2 Do
				TagName = "GroupColumnElements" + SearchTypeName + "__" + Cnt;
				ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cột số %1';
						|ru = 'Колонка №%1';
						|en = 'Column #%1'; fa = 'Column #%1';
						|it = 'Colonna №%1';
						|pl = 'Kolumna №%1';
						|tr = 'Sütun №%1'"),
					Cnt);
				VerticalGroup(TagName,
						ItemTitle,
						InfluencersGroup);
			EndDo;
		EndIf;
	Else
		ItemTitle = NStr("vi = 'Chỉ tiêu (ngắn gọn)';
						|ru = 'Показатели (кратко)';
						|en = 'Indicators (briefly)'; fa = 'Indicators (briefly)';
						|it = 'Indicatori (in breve)';
						|pl = 'Wskaźniki (krótko)';
						|tr = 'Göstergeler (kısaca)'");
		GroupIndicatorsBriefly = VerticalGroup("GroupIndicatorsBriefly",
				ItemTitle,
				GroupIndicators);
		
		ItemTitle = NStr("vi = 'Chỉ tiêu (chi tiết)';
						|ru = 'Показатели (подробно)';
						|en = 'Indicators (detailed)'; fa = 'Indicators (detailed)';
						|it = 'Indicatori (approfonditamente)';
						|pl = 'Wskaźniki (szczegółowo)';
						|tr = 'Göstergeler (ayrıntılı)'");
		GroupIndicatorsInDetail = VerticalGroup("GroupIndicatorsInDetail",
				ItemTitle,
				GroupIndicators);
		
		If SettingsStructure.IndicatorGroupingOption = "ByState" Then
			For Each OutputItem In OutputStructure.OutputOrder Do
				StateForGroup = StrReplace(OutputItem, "Indicators", "");
				State = StrReplace(StrReplace(StrReplace(OutputItem, "Indicators", ""), "Brief1", ""), "More", "");
				If OutputStructure[OutputItem].Count() > 0 Then
					IndicatorGroup_ = HorizontalGroup("Group" + StateForGroup,
						TargetValueMonitoring.StatusPresentation(State),
						GroupIndicatorsBriefly);
					FillPropertyValues(IndicatorGroup_, GroupStyleByState(State));
					
					If StrFind(OutputItem, "Brief1") > 0 Then
						AddGroupsColumnsOfItems(IndicatorGroup_,
								State,
								DisplayOptionsOfAnalysisOptions.Brief1);
					Else
						AddGroupsColumnsOfItems(IndicatorGroup_,
								State);
					EndIf;
				EndIf;
			EndDo;
		ElsIf SettingsStructure.IndicatorGroupingOption = "ByGoalCategory" Then
			For Each OutputItem In OutputStructure.OutputOrder Do
				Id = StrReplace(StrReplace(StrReplace(OutputItem, "Indicators", ""), "Brief1", ""), "More", "");
				GoalCategoryID = TargetValueMonitoring.StringInUniqueIdentifier(Id);
				TargetCategory = Catalogs.GoalCategory.GetRef(GoalCategoryID);
				If OutputStructure[OutputItem].Count() > 0 Then
					GroupPresentation = Common.ObjectAttributeValue(TargetCategory, "Description");
					
					If StrFind(OutputItem, "Brief1") > 0 Then
						TagName = "GroupTextHeader__" + Id;
						GroupTextHeader = HorizontalGroup(TagName,
								GroupPresentation,
								GroupIndicatorsBriefly);
					Else
						TagName = "TabularAndDiagrammaticGroup__" + Id;
						GroupTextHeader = HorizontalGroup(TagName,
								GroupPresentation,
								GroupIndicatorsInDetail);
					EndIf;
					
					FillPropertyValues(GroupTextHeader, MetricGroupStyle());
					GroupTextHeader.Group = ChildFormItemsGroup.AlwaysHorizontal;
					
					If StrFind(OutputItem, "Brief1") > 0 Then
						AddGroupsColumnsOfItems(GroupTextHeader,
								Id,
								DisplayOptionsOfAnalysisOptions.Brief1);
					Else
						AddGroupsColumnsOfItems(GroupTextHeader,
								Id);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function CalculateNumberOfIndicatorsByOutputStructure(OutputStructure)
	
	NumberOfIndicators = 1;
	
	For Each StructureItem In OutputStructure Do
		If Left(StructureItem.Key, 10) = "Indicators" Then
			NumberOfIndicators = Max(NumberOfIndicators, StructureItem.Value.Count());
		EndIf;
	EndDo;
	
	Return NumberOfIndicators;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure Attachable_DashboardsSelection()

	CurrentData = Items.Dashboards.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Ref = SettingsStructure.Dashboard Then
		Return;
	EndIf;
	
	UpdatingServerSettingsStructure(CurrentData.Ref);
	InitializeAutoUpdateHandler();
	UpdateMonitorCompositionClient(True);
	
EndProcedure

&AtServer
Procedure SetNameOfIndicator(AnalysisOption, IDOfFormElement, DataSource, DynamicChange = False)
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	
	TextPresentationOfPeriod = TargetValueMonitoring.PresentationOfAnalysisVariantPeriod(DataSource);
	StateAndTrendColors = TargetValueMonitoring.GetStateAndTrendIndicatorColors(AnalysisOption,
		DataSource);
	
	TrafficLightMarker = New FormattedString("●" + Chars.NBSp, FontOfIndicatorHeaderIsImportant(),
		StateAndTrendColors.StateColor);
	ModificationMarker = " * ";
	LineSplitter = " / ";
	
	NameOfAnalysisOption = New FormattedString(AnalysisOption.Description,
		FontOfIndicatorHeaderIsImportant());
	Periodicity_String = New FormattedString(
		String(DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency),
		FontOfIndicatorHeaderIsImportant());
	If ValueIsFilled(DynamicPropertiesOfAnalysisVariant.AnalysisObject) Then
		ObjectOfAnalysisString = New FormattedString(
			DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation,
			FontOfIndicatorHeaderIsImportant());
	Else
		ObjectOfAnalysisString = "";
	EndIf;
	
	ArrayOfNameStrings = New Array;
	If DataSource.PropertiesOfAnalysisAndTrendZone.Status = "UnacceptableState"
		Or DataSource.PropertiesOfAnalysisAndTrendZone.Status = "AcceptableState"
		Or DataSource.PropertiesOfAnalysisAndTrendZone.Status = "TheGoalIsAchieved" Then
		
		ArrayOfNameStrings.Add(TrafficLightMarker);
	EndIf;
	ArrayOfNameStrings.Add(NameOfAnalysisOption);
	If DynamicChange Then
		ArrayOfNameStrings.Add(ModificationMarker);
		If Not AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends Then
			ArrayOfNameStrings.Add(ObjectOfAnalysisString);
			ArrayOfNameStrings.Add(LineSplitter);
		EndIf;
		ArrayOfNameStrings.Add(Periodicity_String);
	EndIf;
	If Not AnalysisOption.ValueMultiplier = NumberPresentationKinds.Unchanged Then
		ArrayOfNameStrings.Add(LineSplitter);
		ArrayOfNameStrings.Add(TargetValueMonitoring.GetNumberPresentationString(AnalysisOption));
	EndIf;
	If Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions) Then
		ArrayOfNameStrings.Add(LineSplitter);
		ArrayOfNameStrings.Add(String(DynamicPropertiesOfAnalysisVariant.Dimensions));
	EndIf;
	ArrayOfNameStrings.Add(LineSplitter);
	ArrayOfNameStrings.Add(TextPresentationOfPeriod);
	
	ThisObject["IndicatorName__" + IDOfFormElement] = New FormattedString(ArrayOfNameStrings);
EndProcedure

&AtClient
Procedure PlaceUpdateDynamicParametersInTemporaryStorage(Val AnalysisOption, Val MetricIdentifier, Val DataSourceParameters)
	Var DynamicParameterAddress, DynamicParameters, FoundMonitorComponents, NewAddress, SelectionByAnalysisOption;
	
	SelectionByAnalysisOption = New Structure("AnalysisOption", AnalysisOption);
	FoundMonitorComponents = MonitorContent.FindRows(SelectionByAnalysisOption);
	
	DynamicParameterAddress = "";
	If FoundMonitorComponents.Count() > 0 Then
		If ValueIsFilled(FoundMonitorComponents[0].DynamicParameterAddress) Then
			DynamicParameterAddress = FoundMonitorComponents[0].DynamicParameterAddress;
			DynamicParameters = GetFromTempStorage(DynamicParameterAddress);
			CommonClientServer.SupplementStructure(DataSourceParameters, DynamicParameters, False);
		EndIf;
	EndIf;
	
	If ValueIsFilled(DynamicParameterAddress) Then
		DynamicParameterAddress = PutToTempStorage(DataSourceParameters, 
		DynamicParameterAddress);
	Else
		DynamicParameterAddress = PutToTempStorage(DataSourceParameters, 
		New UUID(StrReplace(MetricIdentifier,"_","-")));
	EndIf;
	
	If FoundMonitorComponents.Count() > 0 Then
		FoundMonitorComponents[0].DynamicParameterAddress = DynamicParameterAddress;
	Else
		NewAddress = MonitorContent.Add();
		NewAddress.AnalysisOption = AnalysisOption;
		NewAddress.DynamicParameterAddress = DynamicParameterAddress;
	EndIf;
EndProcedure

&AtClient
Procedure InitializeAutoUpdateHandler(AutoRefreshPeriod = Undefined)
	If AutoRefreshPeriod = Undefined Then
		AutoRefreshPeriod = SettingsStructure.AutoRefreshPeriod * 60;
	EndIf;
	
	If AutoRefreshPeriod > 0 Then
		DetachIdleHandler("WaitHandler_UpdateMonitorCompositionClient");
		AttachIdleHandler("WaitHandler_UpdateMonitorCompositionClient", AutoRefreshPeriod);
	EndIf;
EndProcedure

&AtClient
Procedure InitializeFirstRunHandler()
	FirstLaunchPeriod = 0.1;
	
	AttachIdleHandler("WaitHandler_UpdateMonitorCompositionClient", FirstLaunchPeriod, True);
EndProcedure

&AtServer 
Procedure UpdatingServerSettingsStructure(Dashboard)

	SettingsStructure = TargetValueMonitoring.GetGoalMonitorSettings(Dashboard);
	If SettingsStructure.NumberOfIndicatorMonitorColumns = 0 Then
		SettingsStructure.Insert("NumberOfIndicatorMonitorColumns",
			CalculateNumberOfColumnsOfIndicatorMonitor());
	EndIf;
	
	Items.QuickFiltersGroup.Visible = SettingsStructure.DisplayIndicatorFilter;
	If Not SettingsStructure.DisplayIndicatorFilter Then
		FilterStatus = Undefined;
		ControlCycle = Undefined;
		SetCustomParameter(ThisObject, "FilterStatus", FilterStatus, False);
		SetCustomParameter(ThisObject, "ControlCycle", ControlCycle, False);
	EndIf;

EndProcedure

&AtServer
Procedure ProcessTakingIntoAccountNeedForRemoval(ArrayOfExistingProps)
	NonErasableDetails = New Array;
	NonErasableDetails.Add("AnalysisOptionsForPrinting");
	NonErasableDetails.Add("AnalysisOptionWithCumulativeTotal");
	NonErasableDetails.Add("AnalysisOptionWithDetails");
	NonErasableDetails.Add("DemoMode");
	NonErasableDetails.Add("AvailableReports");
	NonErasableDetails.Add("FilterStatus");
	NonErasableDetails.Add("ControlCycle");
	NonErasableDetails.Add("CurrentUser");
	NonErasableDetails.Add("AnalysisModeOfTheRelated");
	NonErasableDetails.Add("MonitorContent");
	NonErasableDetails.Add("MonitorContentIsNotDefined");
	NonErasableDetails.Add("MonitorContentEmptyByFilter");
	NonErasableDetails.Add("Dashboards");
	NonErasableDetails.Add("ColumnWidth_");
	NonErasableDetails.Add("SettingsStructure");
	NonErasableDetails.Add("TabularAnalysisOptionsWithResults");
	NonErasableDetails.Add("CurrentVersionOfClientApplicationInterface");
	// Long-term operations
	NonErasableDetails.Add("StorageAddress");
	NonErasableDetails.Add("DynamicParameterAddresses");
	NonErasableDetails.Add("Report");
	NonErasableDetails.Add("ConstantCommands");
	
	For Each NonRemovableProps In NonErasableDetails Do 
		For Each ExistingProps In ArrayOfExistingProps Do 
			If ExistingProps.Name = NonRemovableProps Then
				IndexOf = ArrayOfExistingProps.Find(ExistingProps);
				Break;
			Else
				IndexOf = Undefined;
			EndIf;
		EndDo;
		If IndexOf <> Undefined Then
			ArrayOfExistingProps.Delete(IndexOf);
		EndIf;
	EndDo;
EndProcedure

&AtClient 
Procedure WaitHandler_UpdateMonitorCompositionClient()
	UpdateMonitorCompositionClient();
EndProcedure

&AtServer 
Procedure UpdateMonitorComposition(MonitorContent)
	Items.GroupExplanationAtStartup.Visible = False;
	
	// Let's delete the previously programmatically created form elements
	GroupIndicators = Items.Find("GroupIndicators");
	If Not GroupIndicators = Undefined Then
		Items.Delete(GroupIndicators);
	EndIf;
	
	// We will delete the previously created programmatically details
	ArrayOfExistingProps = GetAttributes();
	
	ProcessTakingIntoAccountNeedForRemoval(ArrayOfExistingProps);
	
	If ArrayOfExistingProps.Count() > 0 Then
		ArrayOfPathsForDetailsToDelete = New Array;
		
		For Each ExistingProps In ArrayOfExistingProps Do 
			ArrayOfPathsForDetailsToDelete.Add(ExistingProps.Name);
		EndDo;
		
		ChangeAttributes(, ArrayOfPathsForDetailsToDelete);
	EndIf;
	
	// Delete previously created programmatically commands
	ArrayOfCommandsToDelete = New Array;
	For Each Command In Commands Do 
		CommandName = Command.Name;
		
		If ConstantCommands.FindByValue(CommandName) <> Undefined Then
			Continue;
		EndIf;
		
		ArrayOfCommandsToDelete.Add(CommandName);
	EndDo;
	
	For Each CommandToDelete In ArrayOfCommandsToDelete Do
		Commands.Delete(Commands.Find(CommandToDelete));
	EndDo;
	
	// Get a list of monitor composition (indicator, type, position)
	If AnalysisModeOfTheRelated Then
		StorageOfAddressesOfDynamicParameters = DynamicParameterAddresses; // ValueStorage
		DynamicParameterAddress = StorageOfAddressesOfDynamicParameters.Get();
	EndIf;
	
	FillInSummaryInformationOnDataSources(MonitorContent, DynamicParameterAddress);
	
	MonitorContentIsNotDefined = (MonitorContent.SetOfDataSources = Undefined);
	MonitorContentEmptyByFilter = (MonitorContent.IsEmpty And Not MonitorContentIsNotDefined);
	
	SetVisibilityOfAddMetricsToMonitorOffer(MonitorContentIsNotDefined);
	SetVisibilityOfMessageEmptySelectionResult(MonitorContentEmptyByFilter);
	
	If Not MonitorContentIsNotDefined And Not MonitorContentEmptyByFilter Then
		// Create Attributes of the form based on the composition of the monitor
		// The string "__"+ID is added to the name of the elements_An element where
		// ID_Element = The indicator.Unique Identifier()
		DrawMonitorElements(MonitorContent);
	EndIf;
	
	AvailableReports.Clear();
EndProcedure

&AtServer
Function GetVersionOfReportById(Id)
	Var ReportVariant;
	
	ReportVariant = TargetValueMonitoringServerCall.GetReferenceToCatalogById(
		"ReportsOptions", Id);
	
	Return ReportVariant;
EndFunction

&AtServer 
Function RequestTextForReportOptions()
	QueryText =
	"SELECT
	|	MetadataIDs.Ref AS Ref
	|INTO MetadataIDs
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataIDs
	|WHERE
	|	MetadataIDs.Ref IN(&AvailableReportsOptions)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AnalysisOptionsReports.ReportVariant AS Ref,
	|	ReportsOptions.Description AS Description
	|FROM
	|	Catalog.AnalysisOptionsOfTargetValues.ReportsToDrillDown AS AnalysisOptionsReports
	|		INNER JOIN Catalog.ReportsOptions AS ReportsOptions
	|		ON AnalysisOptionsReports.ReportVariant = ReportsOptions.Ref
	|		INNER JOIN MetadataIDs AS MetadataIDs
	|		ON (ReportsOptions.Report = MetadataIDs.Ref)
	|WHERE
	|	AnalysisOptionsReports.Ref = &AnalysisOption
	|	AND NOT ReportsOptions.DeletionMark
	|
	|ORDER BY
	|	ReportsOptions.Description";
	
	Return QueryText;
EndFunction

&AtServer
Function GetReportOptions(AnalysisOption)
	Var Recordsreferences;
	
	Recordsreferences = New ValueList;
	
	If AvailableReports.Count() = 0 Then
		AvailableReports.LoadValues(New Array(ReportsOptionsCached.AvailableReports()));
	EndIf;
	
	Query = New Query;
	Query.Text = RequestTextForReportOptions();
	Query.SetParameter("AvailableReportsOptions", AvailableReports);
	Query.SetParameter("AnalysisOption", AnalysisOption);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not QueryResult.IsEmpty() Then
		SelectionOfOptions = QueryResult.Select();
		While SelectionOfOptions.Next() Do
			Recordsreferences.Add(
				StrReplace(SelectionOfOptions.Ref.UUID(), "-", "_"),
				SelectionOfOptions.Description);
		EndDo;
	EndIf;
	
	Return Recordsreferences;
EndFunction

&AtClient
Function GetReportVariantID(TagName)
	Var Id;
	
	Id = "";
	
	TwoIdentifiers = Right(TagName, StrLen(TagName) - StrFind(TagName, "__") - 1);
	Id = Right(TwoIdentifiers, StrFind(TwoIdentifiers, "__") - 1);
	
	Return Id;
EndFunction

&AtClient
Function GetIDOfDynamicParameter(TagName)
	Var Id;
	
	Id = "";
	
	TwoIdentifiers = Right(TagName, StrLen(TagName) - StrFind(TagName, "__") - 1);
	Id = Right(TwoIdentifiers, StrLen(TwoIdentifiers) - StrFind(TwoIdentifiers, "__") - 1);
	
	Return Id;
EndFunction

&AtClient
Function GetElementIDByNameWithoutPosition(TagName)
	Var Id;
	
	Id = "";
	
	IDWithPosition = Right(TagName, StrLen(TagName) - StrFind(TagName, "__") - 1);
	If StrFind(IDWithPosition, "__") > 0 Then
		Id = Left(IDWithPosition, StrFind(IDWithPosition, "__") - 1);
	Else
		Id = IDWithPosition
	EndIf;
	
	Return Id;
EndFunction

&AtServer
Function GetReportVariantProperties(ReportVariant)
	ReportOptionProperties = Undefined;
	
	SetPrivilegedMode(True);
	ReportOptionProperties = Common.ObjectAttributesValues(ReportVariant, "VariantKey, Report");
	ReportOptionProperties.Insert("ObjectKey", Common.ObjectAttributeValue(
		ReportOptionProperties.Report, "FullName"));
	SetPrivilegedMode(False);
	
	Return ReportOptionProperties;
EndFunction

&AtServer
Function GetEnumerationLinkById(ObjectName, Id)
	Var LinkYouAreLookingFor;
	
	LinkYouAreLookingFor = Enums[ObjectName][Id];
	
	Return LinkYouAreLookingFor;
EndFunction

&AtClient
Function GetCleanCommandName(CommandName)
	Var CleanCommandName;
	
	CleanCommandName = Left(CommandName, StrFind(CommandName, "__") - 1);
	
	Return CleanCommandName;
EndFunction

&AtServer 
Procedure SetVisibilityOfAddMetricsToMonitorOffer(Visible)
	Items.GroupWhenTheMonitorIsEmpty.Visible = Visible;
	ConstantPart = NStr("vi = 'Không có một phương án phân tích nào có thể hiển thị.';
						|ru = 'Нет ни одного доступного для отображения варианта анализа.';
						|en = 'No analysis option available for display.'; fa = 'هیچ گزینه تحلیلی برای نمایش در دسترس نیست.';
						|it = 'Non esiste nessuna versione di analisi disponibile per la visualizzazione.';
						|pl = 'Brak żadnej dostępnej do wyświetlania opcji analizy.';
						|tr = 'Görüntülenebilecek herhangi bir analiz seçeneği mevcut değil.'"); 
	If AccessRight("Update", Metadata.Catalogs.AnalysisOptionsOfTargetValues) Then
		Items.ExplanationIfTheMonitorIsNotConfigured.Title = ConstantPart + Chars.LF
			+ NStr("vi = 'Để cài đặt, hãy sử dụng ""Kết quả kinh doanh và kiểm soát"" - ""Cài đặt các phương án phân tích"".';
					|ru = 'Для настройки используйте рабочее место ""Финансовый результат и контроллинг"" - ""Настройка доступности вариантов анализа"".';
					|en = 'To configure, use the workplace ""Profitability & cost"" - ""Set up availability of analysis options"".'; fa = 'To configure, use the workplace ""Profitability & cost"" - ""Set up availability of analysis options"".';
					|it = 'Per configurare, utilizzare il luogo di lavoro ""Risultato finanziario e controllo"" - ""Impostazione della disponibilità delle opzioni di analisi"".';
					|pl = 'W celu skonfigurowania, użyj miejsca pracy ""Wynik finansowy i kontrolowanie"" – ""Ustawienie dostępności wariantów analizy"".';
					|tr = 'Ayarlar için ""Finansal sonuçlar ve kontrol"" çalışma alanını kullan- ""Analiz seçeneklerinin erişilebilirliği ayarları"".'");
	Else
		Items.ExplanationIfTheMonitorIsNotConfigured.Title = ConstantPart + Chars.LF
			+ NStr("vi = 'Liên hệ với quản trị viên hệ thống của bạn để cài đặt sẵn có của các tùy chọn phân tích.';
					|ru = 'Обратитесь к админитратору системы для настройки доступности вариантов анализа.';
					|en = 'Contact system administrator to configure availability of analysis options.'; fa = 'Contact system administrator to configure availability of analysis options.';
					|it = 'Contattare l''amministratore di sistema per configurare la disponibilità delle opzioni di analisi.';
					|pl = 'Skontaktuj się z administratorem systemu, aby skonfigurować dostępność opcji analizy.';
					|tr = 'Analiz seçeneklerinin erişilebilirliğini ayarlamak için sistem yöneticisine başvur.'");
	EndIf;
	Items.Print.Enabled = Not Visible;
EndProcedure

&AtServer 
Procedure SetVisibilityOfMessageEmptySelectionResult(Visible)
	Items.GroupWithAnEmptySelectionResult.Visible = Visible;
EndProcedure

&AtServer 
Procedure RegisterPersistentCommands()
	ConstantCommands.Add("EnableDisableDemoMode");
	ConstantCommands.Add("Change");
	ConstantCommands.Add("Refresh");
	ConstantCommands.Add("Print");
	ConstantCommands.Add("SaveReportSnapshot");
	ConstantCommands.Add("UpdateReportsSnapshots");
	ConstantCommands.Add("ReportsSnapshots");
	ConstantCommands.Add("MoveItemUp");
	ConstantCommands.Add("MoveItemDown");
EndProcedure

&AtClientAtServerNoContext 
Procedure SetCustomParameter(Form, ParameterName, ParameterValue, UsingOfParameter = True)

	DataCompositionClientServer.SetParameter(Form.Report.SettingsComposer.UserSettings, ParameterName, ParameterValue, UsingOfParameter);

EndProcedure

&AtServerNoContext
Procedure SaveDefaultDashboard(Dashboard)

	Common.CommonSettingsStorageSave("GoalMonitorSettings", "DefaultDashboard",
		Dashboard, , UserName());

EndProcedure

&AtServer
Function CalculateWidthOfElement(ColumnsCount)

	If ColumnWidth_ <> 0 Then
		Return ColumnWidth_;
	EndIf;
	
	DisplayParameters1 = CommonClientServer.DeviceDisplayParameters();
	
	ColumnWidth_ = Max(30, Int(DisplayParameters1.Width / (16 * ColumnsCount)));
	
	Return ColumnWidth_;
	
EndFunction

&AtServerNoContext
Function CalculateNumberOfColumnsOfIndicatorMonitor()

	ItemWidth = 30;
	
	DisplayParameters1 = CommonClientServer.DeviceDisplayParameters();
	
	Return Int(DisplayParameters1.Width / ItemWidth / 16);
	
EndFunction

&AtServerNoContext
Procedure MoveItem(ObjectReference, Up)
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	PerformanceDashboards.Ref AS Ref,
	|	CASE
	|		WHEN &Up
	|			THEN -PerformanceDashboards.AddlOrderingAttribute
	|		ELSE PerformanceDashboards.AddlOrderingAttribute
	|	END AS AddlOrderingAttribute
	|FROM
	|	Catalog.PerformanceDashboards AS PerformanceDashboards
	|WHERE
	|	CASE
	|			WHEN &Up
	|				THEN PerformanceDashboards.AddlOrderingAttribute < &AddlOrderingAttribute
	|			ELSE PerformanceDashboards.AddlOrderingAttribute > &AddlOrderingAttribute
	|		END
	|
	|ORDER BY
	|	AddlOrderingAttribute");
	
	Query.SetParameter("Up", Up);
	Query.SetParameter("AddlOrderingAttribute", Common.ObjectAttributeValue(ObjectReference, "AddlOrderingAttribute"));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	BeginTransaction();

	Try
		
		LockDataForEdit(ObjectReference);
		LockDataForEdit(Selection.Ref);
		
		ItemToMove = ObjectReference.GetObject(); // CatalogObject.PerformanceDashboards - 
		AdjacentElement = Selection.Ref.GetObject(); // CatalogObject.PerformanceDashboards -
		
		ItemToMove.AddlOrderingAttribute = ItemToMove.AddlOrderingAttribute + AdjacentElement.AddlOrderingAttribute;
		AdjacentElement.AddlOrderingAttribute     = ItemToMove.AddlOrderingAttribute - AdjacentElement.AddlOrderingAttribute;
		ItemToMove.AddlOrderingAttribute = ItemToMove.AddlOrderingAttribute - AdjacentElement.AddlOrderingAttribute;
	
		SetPrivilegedMode(True);
	
		ItemToMove.Write();
		AdjacentElement.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region TimeConsumingOperations

&AtClient
Procedure UpdateMonitorCompositionClient(ForceUpdateData = False)
	
	MonitorCompositionParameters = TargetValueMonitoringClientServer.InitializingMonitorCompositionParameters();
	
	If AnalysisModeOfTheRelated Then
		MonitorCompositionParameters.AnalysisModeOfTheRelated  = AnalysisModeOfTheRelated;
		MonitorCompositionParameters.SearchType 					  = Parameters.SearchType;
		MonitorCompositionParameters.PropertiesOfAnalysisVariant 	  = Parameters.IDOfTheAnalysisOption;
		MonitorCompositionParameters.DynamicParameterAddresses = DynamicParameterAddresses;	
		MonitorCompositionParameters.FilterStatus 			      = FilterStatus;
		MonitorCompositionParameters.ControlCycle 		  = ControlCycle;
		MonitorCompositionParameters.ConsiderDisplayOptions = True;
	Else
		MonitorCompositionParameters.AnalysisModeOfTheRelated  = AnalysisModeOfTheRelated;
		MonitorCompositionParameters.AnalysisOptionFilter 		  = Undefined;
		MonitorCompositionParameters.ForceUpdateData  = ForceUpdateData;
		MonitorCompositionParameters.SettingsStructure 			  = SettingsStructure;
		MonitorCompositionParameters.FilterStatus 			      = FilterStatus;
		MonitorCompositionParameters.ControlCycle 		  = ControlCycle;
		MonitorCompositionParameters.ConsiderDisplayOptions = True;
	EndIf;
	
	MonitorCompositionParameters.DemoMode			  = DemoMode;
	
	Result = FillInReportOnServer(MonitorCompositionParameters);
	If Not Result.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateCompositionOfMonitorAlert", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			Result, CallbackOnCompletion, IdleParameters);
			
	EndIf;
	
EndProcedure

&AtServer
Function FillInReportOnServer(MonitorCompositionParameters)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền báo cáo ""Màn hình chỉ số mục tiêu""';
														|ru = 'Заполнение отчета ""Монитор целевых показателей""';
														|en = 'Fill in the ""Performance dashboard"" report'; fa = 'Fill in the ""Performance dashboard"" report';
														|it = 'Completamento del report ""Target Monitor""';
														|pl = 'Zakończenie raportu ""Monitor wskaźników celowych""';
														|tr = '""Performans gösterge paneli"" raporunun doldurulması'");
	
	TaskStartResult = TimeConsumingOperations.ExecuteInBackground(
		"TargetValueMonitoring.PrepareDataForFilling",
		MonitorCompositionParameters,
		ExecutionParameters);
		
	StorageAddress = TaskStartResult.ResultAddress;
	
	If TaskStartResult.Status = "Completed2" Then
		LoadPreparedData();
	EndIf;
	
	Return TaskStartResult;
	
EndFunction

&AtClient
Procedure UpdateCompositionOfMonitorAlert(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		LoadPreparedData();
	EndIf;
		
EndProcedure

&AtServer
Procedure LoadPreparedData()
	Result = GetFromTempStorage(StorageAddress);
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Result.Property("Monitor") Then
		FormedComposition = Result.Monitor;
		UpdateMonitorComposition(FormedComposition);
	EndIf;
EndProcedure

&AtClient
Procedure EnableDisableDemoMode(Command)
	Items[Command.Name].Check = Not Items[Command.Name].Check;
	DemoMode = Not DemoMode;
	
	If Items[Command.Name].Check Then
		Title = NStr("vi = 'Chế độ minh họa';
					|ru = 'Демонстрационный режим';
					|en = 'Demo mode'; fa = 'حالت نمایشی';
					|it = 'Modalità dimostrativa';
					|pl = 'Tryb demonstracyjny';
					|tr = 'Demo modu'");
	Else
		Title = "";
	EndIf;
	
	UpdateMonitorCompositionClient();
EndProcedure

&AtServer
Procedure SaveUserReportSnapshot()

	ReportObject = FormAttributeToValue("Report");
	ReportObject.SettingsComposer.UserSettings.AdditionalProperties.Insert("Dashboard",
		SettingsStructure.Dashboard);

	ReportSettings = New Structure;
	ReportSettings.Insert("ReportRef", Common.MetadataObjectID(
		Metadata.Reports.PerformanceDashboard));
	ReportSettings.Insert("OptionRef", SettingsStructure.Dashboard);
	ReportSettings.Insert("ResultProperties", New Structure("SettingsComposer",
		ReportObject.SettingsComposer));

	ReportResult = New SpreadsheetDocument;
	ReportObject.ComposeResult(ReportResult);

	InformationRegisters.ReportsSnapshots.SaveUserReportSnapshot(ReportResult, ReportSettings);

EndProcedure

&AtServer
Function UpdateUserReportsSnapshots()
	
	FillParameters = New Structure;
	FillParameters.Insert("User", Users.CurrentUser());
	FillParameters.Insert("CatalogNameReportOptions", "PerformanceDashboards");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật ảnh chụp báo cáo của người sử dụng';
														|ru = 'Обновление снимков отчетов пользователя';
														|en = 'Update user report snapshots'; fa = 'Update user report snapshots';
														|it = 'Обновление снимков отчетов пользователя';
														|pl = 'Update user report snapshots';
														|tr = 'Kullanıcı raporlarının anlık görüntülerinin güncellenmesi'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.ReportsSnapshots.UpdateUserReportsSnapshots",
		FillParameters, ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction	

#EndRegion

#EndRegion