
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtServer
Procedure OnSaveUserSettingsAtServer(Settings)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtServer
Procedure OnLoadUserSettingsAtServer(Settings, StandardSettingsUsed)
	
	If StandardSettingsUsed Then
		Return;
	EndIf;
	
	If Not ComposerHasBeenInitialized Then
		UserSettings = PutToTempStorage(Settings, UUID);
	EndIf;
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadVariantAtServer(Settings)
	
	FillInByDefaultSettings(New Structure("Indicators, Group", True, True));
	
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	DataCompositionField = New DataCompositionField("Organization");
	
	For Each SettingItem In Report.SettingsComposer.Settings.Filter.Items Do
		If TypeOf(SettingItem) = Type("DataCompositionFilterItem")
			And SettingItem.LeftValue = DataCompositionField Then
			SettingItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure BeforeLoadVariantAtServer(Settings)
	
	DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Settings, "Organization");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region Period

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

#EndRegion

#Region Organization

&AtClient
Procedure OrganizationField_OnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationField_Opening(Item, StandardProcessing)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure OrganizationField_ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Return; // WE have an empty handler.
	
EndProcedure

#EndRegion

#Region Result

&AtClient
Procedure ResultOnActivate(Item)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure ResultAdditionalDetailProcessing(Item, Details, StandardProcessing)

	// We will not process clicking on the right mouse button.
	// Let's show the standard context menu of a tabular document cell.
	Details = Undefined;

EndProcedure

&AtClient
Procedure ResultOnChange(Item)
	
	ManualAdjustment = True;
	
EndProcedure

#EndRegion

#Region Indicators

&AtClient
Procedure IndicatorQuantityInExcisableCategoryUOMOnChange(Item)

	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure IndicatorQuantityOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure IndicatorExciseAmountLocalOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure IndicatorExciseAmountMgmtOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

#EndRegion

#Region Appearance

&AtClient
Procedure AppearanceTemplateOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure TitleOutputOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputTheBasementOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputUnitOfMeasurementOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure AdditionalFieldsLocationOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGroup

&AtClient
Procedure GroupOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure GroupBeforeRowChange(Item, Cancel)
	
	Return; // WE have an empty handler.
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilters

&AtClient
Procedure FiltersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure FiltersBeforeRowChange(Item, Cancel)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure FiltersOnChange(Item)
	
	Return; // WE have an empty handler.
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdditionalFields

&AtClient
Procedure AdditionalFieldsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure AdditionalFieldsBeforeRowChange(Item, Cancel)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure AdditionalFieldsOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectPeriod(Command)
	
	ChoiceParameters = New Structure("BeginOfPeriod, EndOfPeriod", Report.BeginOfPeriod, Report.EndOfPeriod);
	CallbackDescription = New CallbackDescription("SelectPeriodCompletion", ThisObject);
	PeriodChoiceForm = "CommonForm.SelectAStandardPeriod";
	OpenForm(PeriodChoiceForm, ChoiceParameters, Items.SelectPeriod, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure GroupingUncheckBoxes(Command)
	
	For Each TableRow In Report.Group Do
		TableRow.Use = False;
	EndDo;
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupingCheckBoxes(Command)
	
	For Each TableRow In Report.Group Do
		TableRow.Use = True;
	EndDo;
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalFieldsUncheck(Command)
	
	For Each TableRow In Report.AdditionalFields Do
		TableRow.Use = False;
	EndDo;
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalFieldsCheckBoxes(Command)
	
	For Each TableRow In Report.AdditionalFields Do
		TableRow.Use = True;
	EndDo;
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure Unload(Command)
	
	If Items.Result.StatePresentation.Visible Then
		
		CurrentItem = Items.Generate;
		WarningText = NStr("vi = 'Nhấn nút ""Lập báo cáo"" để nhận báo cáo';
							|ru = 'Нажмите ""Сформировать"" для получения отчета';
							|en = 'Click ""Generate"" to get the report'; fa = 'Click ""Generate"" to get the report';
							|it = 'Click ""Generate"" to get the report';
							|pl = 'Click ""Generate"" to get the report';
							|tr = 'Raporu oluşturmak için ""Oluştur"" butonuna tıklayın'");
		ShowMessageBox( , WarningText,, NStr("vi = 'Chưa lập báo cáo';
											|ru = 'Отчет не сформирован';
											|en = 'Report is not generated'; fa = 'Report is not generated';
											|it = 'Il report non è stato generato';
											|pl = 'Raport nie wygenerowany';
											|tr = 'Rapor düzenlenmedi'"));
		Return;
		
	EndIf;
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Result",     Result);
	ReportParameters.Insert("Organization",   Report.Organization);
	ReportParameters.Insert("IncludingBranchOffices", Report.IncludingBranchOffices);
	ReportParameters.Insert("BeginOfPeriod", Report.BeginOfPeriod);
	ReportParameters.Insert("EndOfPeriod",  Report.EndOfPeriod);
	ReportParameters.Insert("ManualAdjustment", ManualAdjustment);
	
	Close(ReportParameters);
	
EndProcedure

&AtClient
Procedure GenerateReport(Command)
	
	StartReportGeneration();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure Close_Settings(Command)
	
	ActionButton = ?(Items.Unload.Visible, Items.Unload, Items.Generate);
	ActionButton.DefaultButton = True;
	HideSettings();
	
EndProcedure

&AtClient
Procedure ShowSettings(Command)
	
	Return; // WE have an empty handler.
	
EndProcedure

&AtClient
Procedure SimpleSetup(Command)
	
	FillInByDefaultSettings(SimpleSettings());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartReportGeneration()
	
	ClearMessages();
	
	ExecutionResult = GenerateReportOnServer();
	If ExecutionResult.Status <> "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("GenerateAlertReport", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			ExecutionResult, CallbackOnCompletion, IdleParameters);
		
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ProgressIndicator,
			"ReportGeneration");
		
	EndIf;
	
	HideSettings();
	
	ManualAdjustment = False;
	
EndProcedure

&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	FillPropertyValues(Report, SelectionResult, "BeginOfPeriod,EndOfPeriod");
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtServer
Function GenerateReportOnServer() Export
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("Status", "Completed2");
	
	Return ExecutionResult;
	
EndFunction

&AtServer
Procedure FillInByDefaultSettings(SettingsToFillIn) Export
	
	Var FillingInCollection;
	
	If SettingsToFillIn.Property("Indicators", FillingInCollection) And FillingInCollection Then
		// Performance management.
		Report.IndicatorQuantityInExcisableCategoryUOM = True;
		Report.IndicatorQuantity       = True;
		Report.IndicatorExciseAmountLocal  = True;
		Report.IndicatorExciseAmountMgmt   = True;
	EndIf;
	
	If SettingsToFillIn.Property("Group", FillingInCollection) And FillingInCollection Then
		
		Report.Group.Clear();
		
		NewRow = Report.Group.Add();
		NewRow.Field           = "Organization";
		NewRow.Use  = True;
		NewRow.Presentation  = "Organization";
		NewRow.GroupType = 0;
		
		NewRow = Report.Group.Add();
		NewRow.Field           = "ExcisePaymentBusinessUnit";
		NewRow.Use  = True;
		NewRow.Presentation  = "ExcisePaymentBusinessUnit";
		NewRow.GroupType = 0;
		
		NewRow = Report.Group.Add();
		NewRow.Field           = "KindOfTransactionWithExcisableGoods";
		NewRow.Use  = True;
		NewRow.Presentation  = "KindOfTransactionWithExcisableGoods";
		NewRow.GroupType = 0;
		
		NewRow = Report.Group.Add();
		NewRow.Field           = "ExcisableGoodsCategory";
		NewRow.Use  = True;
		NewRow.Presentation  = "ExcisableGoodsCategory";
		NewRow.GroupType = 0;
		
		NewRow = Report.Group.Add();
		NewRow.Field           = "Products";
		NewRow.Use  = True;
		NewRow.Presentation  = "Products";
		NewRow.GroupType = 0;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadPreparedData()
	
	ExecutionResult = GetFromTempStorage(StorageAddress);
	Result         = ExecutionResult.Result;
	DetailsData = ExecutionResult.DetailsData;
	
	JobID = Undefined;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	
EndProcedure

&AtClient
Procedure GenerateAlertReport(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	Try
		LoadPreparedData();
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	Except
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
EndProcedure

&AtClient
Procedure HideSettings()
	
	Items.ReportSections.CurrentPage = Items.Report;
	
EndProcedure

&AtClientAtServerNoContext
Function SimpleSettings()
	
	Settings = New Structure();
	
	Settings.Insert("Indicators",			True);
	Settings.Insert("Group",			False);
	Settings.Insert("Filter",					True);
	Settings.Insert("AdditionalFields",	True);
	Settings.Insert("ConditionalAppearance",	True);
	
	Return Settings;
	
EndFunction

#EndRegion
