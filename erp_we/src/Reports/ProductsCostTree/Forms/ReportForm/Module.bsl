#Region Variables

&AtClient
Var HandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Definition of the key parameters of the report.
	DetailsMode = (Parameters.Property("Details") And Parameters.Details <> Undefined);
	ReportObject = FormAttributeToValue("Report");
	ReportMetadata = ReportObject.Metadata();
	ReportFullName  = ReportMetadata.FullName();
	CompositionSchema = ReportObject.DataCompositionSchema;
	CostStructure.AdaptDCSRequest(CompositionSchema, False, False, Undefined);
	SchemaURL = PutToTempStorage(CompositionSchema, UUID);
	
	PredefinedOptions = New ValueList;
	For Each Variant In CompositionSchema.SettingVariants Do
		PredefinedOptions.Add(Variant.Name, Variant.Presentation);
	EndDo;
	
	PanelOptionsCurrentOptionKey = " - ";
	If ValueIsFilled(Parameters.VariantKey) Then
		CurrentVariantKey = Parameters.VariantKey;
	Else
		CurrentVariantKey = Common.SystemSettingsStorageLoad(ReportFullName + "/CurrentVariantKey", "");
	EndIf;
	If Not ValueIsFilled(CurrentVariantKey) And PredefinedOptions.Count() > 0 Then
		CurrentVariantKey = PredefinedOptions[0].Value;
	EndIf;
	
	// Pre-initialization of the linker (if required).
	SchemaURL = CommonClientServer.StructureProperty(Parameters, "SchemaURL");
	If DetailsMode Then
		NewDCSettings = GetFromTempStorage(Parameters.Details.Data).Settings;
		SchemaURL = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "SchemaURL");
	EndIf;
	If TypeOf(SchemaURL) = Type("String") And IsTempStorageURL(SchemaURL) Then
		CompositionSchema = GetFromTempStorage(SchemaURL);
		If TypeOf(CompositionSchema) = Type("DataCompositionSchema") Then
			SchemaURL = PutToTempStorage(CompositionSchema, UUID);
			Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		Else
			SchemaURL = PutToTempStorage(CompositionSchema, UUID);
		EndIf;
	Else
		SchemaURL = PutToTempStorage(CompositionSchema, UUID);
	EndIf;
	
	// Saving the form opening parameters.
	SaveFormParameters();
	
	// Defining report settings.
	ReportByStringType = ReportsOptions.ReportByStringType(Parameters.Report);
	If ReportByStringType = Undefined Then
		Information      = ReportsOptions.ReportInformation(ReportFullName, True);
		Parameters.Report = Information.Report;
	EndIf;
	
	SetCurrentOptionKey(ReportFullName, ReportObject);
	ParametersForm.InitialOptionKey = CurrentVariantKey;
	
	If Parameters.Property("CommandParameter") Then
		If TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionOrder2_2") Then
			EstablishSelectionByProductionOrder(ParametersForm.Filter, Parameters.CommandParameter);
		ElsIf TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionStage2_2") Then
			
			ListOfBankingDetails = "ProductionLot, ProductionByThirdParty, ProductionProcessType, ReferenceOrder";
			StageDetails = Common.ObjectAttributesValues(Parameters.CommandParameter, ListOfBankingDetails);
			
			If Not StageDetails = Undefined
				And StageDetails.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials 
				And Not StageDetails.ProductionByThirdParty Then
				EstablishSelectionByProductionOrder(ParametersForm.Filter, StageDetails.ReferenceOrder);
			ElsIf Not StageDetails = Undefined
				And StageDetails.ProductionByThirdParty Then
				SetSelectionBasedOnProcessorReports(ParametersForm.Filter, Parameters.CommandParameter);
			Else
				ParametersForm.Filter.Insert("ProductsBatch", Parameters.CommandParameter);
			EndIf;
			
		Else
			ParametersForm.Filter.Insert("ProductsBatch", Parameters.CommandParameter);
		EndIf;
	EndIf;
	
	// Local variables.
	OutputParameters = New Structure;
	OutputParameters.Insert("UnitOfMeasure");
	OutputParameters.Insert("AccuracyOfUnitOfMeasure");
	OutputParameters.Insert("DisplayCostType");
	OutputParameters.Insert("DisplayCompany");
	OutputParameters.Insert("DisplayTheCostDivision");
	OutputParameters.Insert("ItemizeTheCostToTheComponents");
	OutputParameters.Insert("DisplayPRVR");
	
	// Defining report settings.
	ReportSettings1 = CostStructure.InitializeReportSettings(
		Parameters.Report, CurrentVariantKey, ReportObject);
	ReportSettings1.OptionSelectionAllowed = True;
	ReportSettings1.SchemaModified = False;
	ReportSettings1.PredefinedOptions = PredefinedOptions;
	ReportSettings1.SchemaURL = SchemaURL;
	ReportSettings1.SchemaKey = "";
	ReportSettings1.Contextual = TypeOf(ParametersForm.Filter) = Type("Structure") And ParametersForm.Filter.Count() > 0;
	ReportSettings1.FullName = ReportFullName;
	ReportSettings1.Description = TrimAll(ReportMetadata.Presentation());
	ReportSettings1.ReportRef = Parameters.Report;
	ReportSettings1.External = TypeOf(ReportSettings1.ReportRef) = Type("String");
	ReportSettings1.Safe= SafeMode() <> False;
	
	ReportSettings1.ReadCreateFromUserSettingsImmediatelyCheckBox = True;
	If Parameters.Property("GenerateOnOpen") And Parameters.GenerateOnOpen = True Then
		Parameters.GenerateOnOpen = False;
		Items.GenerateImmediately.Check = True;
		ReportSettings1.ReadCreateFromUserSettingsImmediatelyCheckBox = False;
	EndIf;
		
	If Parameters.Property("GenerateOnOpen")
		And Not Parameters.GenerateOnOpen = Undefined Then
		ReportSettings1.GenerateImmediately = Parameters.GenerateOnOpen;
	EndIf;
	
	// Hiding option commands.
	ReportOptionsCommandsVisibility = CommonClientServer.StructureProperty(Parameters, "ReportOptionsCommandsVisibility");	
	
	If ReportOptionsCommandsVisibility = False Then
		ReportSettings1.EditOptionsAllowed = False;
		ReportSettings1.OptionSelectionAllowed = False;
		If IsBlankString(PurposeUseKey) Then
			PurposeUseKey = Parameters.VariantKey;
			ParametersForm.PurposeUseKey = PurposeUseKey;
		EndIf;
	EndIf;
	If ReportSettings1.EditOptionsAllowed And Not ReportsOptionsCached.InsertRight1() Then
		ReportSettings1.EditOptionsAllowed = False;
	EndIf;
	
	SelectAndEditOptionsWithoutSavingAllowed = CommonClientServer.StructureProperty(
		ReportSettings1, "SelectAndEditOptionsWithoutSavingAllowed", False);
	
	If SelectAndEditOptionsWithoutSavingAllowed Then
		ReportSettings1.EditOptionsAllowed = True;
		ReportSettings1.OptionSelectionAllowed = True;
		VariantModified                      = False;
		If IsBlankString(PurposeUseKey) Then
			PurposeUseKey = Parameters.VariantKey;
			ParametersForm.PurposeUseKey = PurposeUseKey;
		EndIf;
	EndIf;
	
	ReportSettings = ReportSettings1;
	UpdateInfoOnReportOption();
	
	// Registration of commands and form details that are not deleted when the quick settings are restarted.
	AttributesSet = GetAttributes();
	For Each Attribute In AttributesSet Do
		FullAttributeName = Attribute.Name + ?(IsBlankString(Attribute.Path), "", "." + Attribute.Path);
		ConstantAttributes.Add(FullAttributeName);
	EndDo;
	For Each Command In Commands Do
		ConstantCommands.Add(Command.Name);
	EndDo;
	
	// Bringing the dependent elements of the form to the condition.
	SetVisibilityAvailability();
	
	ReportsOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ReportSettings.Contextual Then
		FillParameters = ReportsClientServer.ReportFormUpdateParameters("DefaultSettings");
		
		If VariantModified Then
			FillParameters.ClearOptionSettings = True;
			FillParameters.VariantModified      = False;
		EndIf;
		FillParameters.ResetCustomSettings = True;
		FillParameters.UserSettingsModified = True;
		
		If ReportSettings.GenerateImmediately Then
			FillParameters.Regenerate = True;
		EndIf;
		
		UpdateSettingsFormItems(FillParameters);
				
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(Result, SubordinateForm)
	ResultProcessed = False;
	
	// Acceptance of the result from standard forms.
	If TypeOf(SubordinateForm) = Type("ClientApplicationForm") Then
		SubordinateFormName1 = SubordinateForm.FormName;
		If SubordinateFormName1 = "SettingsStorage.ReportsVariantsStorage.Form.ReportSettings"
			Or SubordinateForm.CallbackDescriptionOnClose <> Undefined Then
			ResultProcessed = True; // See AllSettingsCompletion.
		ElsIf TypeOf(Result) = Type("Structure") Then
			PointPosition = StrLen(SubordinateFormName1);
			While CharCode(SubordinateFormName1, PointPosition) <> 46 Do // Not a dot.
				PointPosition = PointPosition - 1;
			EndDo;
			SourceFormSuffix = Upper(Mid(SubordinateFormName1, PointPosition + 1));
			If SourceFormSuffix = Upper("ReportSettingsForm")
				Or SourceFormSuffix = Upper("SettingsForm")
				Or SourceFormSuffix = Upper("ReportVariantForm")
				Or SourceFormSuffix = Upper("VariantForm") Then
				
				UpdateSettingsFormItems(Result);
				ResultProcessed = True;
			EndIf;
		EndIf;
	EndIf;
	
	ReportsClientOverridable.ChoiceProcessing(ThisObject, Result, SubordinateForm, ResultProcessed);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	NotificationProcessed = False;
	If EventName = ReportsOptionsClient.EventNameChangingOption()
		Or EventName = "Write_ConstantsSet" Then
		NotificationProcessed = True;
		AttachIdleHandler("VisibilityAvailabilityIfRequired", 0.1, True);
	EndIf;
	ReportsClientOverridable.NotificationProcessing(ThisObject, EventName, Parameter, Source, NotificationProcessed);
EndProcedure

&AtServer
Procedure OnLoadVariantAtServer(NewDCSettings)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If DetailsMode Then
		ReportCurrentOptionDescription = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "DescriptionOption");
		If Parameters <> Undefined And Parameters.Property("Details") Then
			Report.SettingsComposer.LoadFixedSettings(Parameters.Details.UsedSettings);
			Report.SettingsComposer.FixedSettings.AdditionalProperties.Insert("DetailsMode", True);
		EndIf;
		If CurrentVariantKey = Undefined Then
			CurrentVariantKey = CommonClientServer.StructureProperty(NewDCSettings.AdditionalProperties, "VariantKey");
		EndIf;
	Else
		Report.SettingsComposer.Settings.AdditionalProperties.Insert("DescriptionOption", ReportCurrentOptionDescription);
	EndIf;
	
	// The installation of fixed selections is performed through the linker, because it has the most complete collection of settings.
	// In preloading, the parameters may be missing those parameters whose settings have not been overridden.
	If TypeOf(ParametersForm.Filter) = Type("Structure") Then
		SetFixedFilters(ParametersForm.Filter, Report.SettingsComposer.Settings, ReportSettings);
	EndIf;
	
	// Updating the report variant link.
	If PanelOptionsCurrentOptionKey <> CurrentVariantKey Then
		UpdateInfoOnReportOption();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	If Parameters.Property("AutoTest_2")
		Or Not ReportOptionMode() Then
		Return;
	EndIf;
	
	SettingsKey = ReportOptionSettingsKey(ReportSettings.FullName, CurrentVariantKey);
	RestoreTheSelectedGroupingLevel(SettingsKey, SelectedGroupsLevel, DetailsMode);
	
	If Not ReportsOptionsInternalClientServer.ReportOptionMode(CurrentVariantKey) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Not VariantModified Then 
		RestoreTheStateOfTheOutputSettingsHeadersOption(SettingsKey, OutputSettingsTitles, DetailsMode);
	EndIf;
	
	ParametersOfUpdate = ReportsClientServer.ReportFormUpdateParameters("OnUpdateUserSettingSetAtServer");
 	UpdateSettingsFormItemsAtServer(ParametersOfUpdate);
	SetVisibilityHeaders();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	SettingsItems = Report.SettingsComposer.UserSettings.Items;
	For Each SettingItem In SettingsItems Do
		If TypeOf(SettingItem) <> Type("DataCompositionSettingsParameterValue")
			Or TypeOf(SettingItem.Value) <> Type("StandardPeriod")
			Or Not SettingItem.Use Then
			Continue;
		EndIf;
		
		NameTemplate = "SettingsComposerUserSettingsItem" + SettingsItems.IndexOf(SettingItem);
		
		StartDate = Items.Find(NameTemplate + "StartDate");
		EndDate = Items.Find(NameTemplate + "EndDate");
		If StartDate = Undefined Or EndDate = Undefined Then 
			Continue;
		EndIf;
		
		Value = SettingItem.Value; // StandardPeriod - 
		If StartDate.AutoMarkIncomplete = True
			And Not ValueIsFilled(Value.StartDate)
			And Not ValueIsFilled(Value.EndDate) Then
			ErrorText = NStr("vi = 'Chưa chỉ ra kỳ';
							|ru = 'Не указан период';
							|en = 'Period is not specified'; fa = 'Period is not specified';
							|it = 'Periodo non indicato';
							|pl = 'Nie podano okresu';
							|tr = 'Dönem belirtilmedi'");
			DataPath = StartDate.DataPath;
		ElsIf Value.StartDate > Value.EndDate Then
			ErrorText = NStr("vi = 'Cuối kỳ cần lớn hơn đầu kỳ';
							|ru = 'Конец периода должен быть больше начала';
							|en = 'Period end should be later than its start'; fa = 'Period end should be later than its start';
							|it = 'La fine del periodo deve essere successiva all''inizio';
							|pl = 'Koniec tego okresu musi być większy, niż początek';
							|tr = 'Dönem sonu, başlangıcından sonra olmalıdır'");
			DataPath = EndDate.DataPath;
		Else
			Continue;
		EndIf;
		
		Common.MessageToUser(ErrorText,, DataPath,, Cancel);
	EndDo;
	
EndProcedure

&AtServer
Procedure OnSaveVariantAtServer(DCSettings)
	NewDCSettings = Report.SettingsComposer.GetSettings();
	ReportsClientServer.LoadSettings(Report.SettingsComposer, NewDCSettings);
	DCSettings.AdditionalProperties.Insert("Address", PutToTempStorage(NewDCSettings));
	DCSettings = NewDCSettings;
	PanelOptionsCurrentOptionKey = " - ";
	UpdateInfoOnReportOption();
	SetVisibilityAvailability(False);
EndProcedure

&AtServer
Procedure OnSaveUserSettingsAtServer(DCUserSettings)
	
	ReportsOptions.OnSaveUserSettingsAtServer(ThisObject, DCUserSettings);
	FillOutOptionSelectionCommands();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadVariantAtServer(NewDCSettings)	 
	
	// Do nothing if the report is not on the SKD and no settings are loaded.
	If NewDCSettings = Undefined Or Not ReportsOptionsInternalClientServer.ReportOptionMode(
		CurrentVariantKey) Then

		Return;
	EndIf;

	AdditionalProperties = NewDCSettings.AdditionalProperties;

	If PanelOptionsCurrentOptionKey <> CurrentVariantKey Then
		AdditionalProperties.Delete("VariantKey");
		AdditionalProperties.Delete("PredefinedOptionKey");
		AdditionalProperties.Delete("OptionContext");
		AdditionalProperties.Delete("FormParametersSelection");
		AdditionalProperties.Delete("DescriptionOption");
	EndIf;

	If DetailsMode Then
		If TypeOf(Parameters.Details) = Type("DataCompositionDetailsProcessDescription") Then
			ReportsOptionsInternal.PrepareReportSettingsToDecipherByDetailedRecords(
				ThisObject, NewDCSettings, Parameters.Details.UsedSettings);
		EndIf;

		If ValueIsFilled(CurrentVariantKey) Then
			AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
		EndIf;
	EndIf;

	SSLSubsystemsIntegration.BeforeLoadVariantAtServer(ThisObject, NewDCSettings);
	ReportsOverridable.BeforeLoadVariantAtServer(ThisObject, NewDCSettings);
	If ReportSettings.Events.BeforeLoadVariantAtServer Then
		ReportObject = FormAttributeToValue("Report");
		ReportObject.BeforeLoadVariantAtServer(ThisObject, NewDCSettings);
	EndIf;
	
	// Preparing to trigger a reinitialization event.
	If ReportSettings.Events.BeforeImportSettingsToComposer Then
		Try
			NewXMLSettings = Common.ValueToXMLString(NewDCSettings);
		Except
			NewXMLSettings = Undefined;
		EndTry;
		ReportSettings.NewXMLSettings = NewXMLSettings;
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region EventHandlersForFormHeaderElementsEnabled

// Enabled period selection command.
// Parameters:
//	Command - FormCommand - field to change.
&AtClient
Procedure Attachable_SelectPeriod(Command)
	ReportsClient.SelectPeriod(ThisObject, Command.Name);
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	GenerateReport();
EndProcedure

&AtClient
Procedure Print(Command)
	
	BackgroundJobStartResult = BackgroundJobRun(True);
	
	If BackgroundJobStartResult.JobStarted Then
	
		Notification = New CallbackDescription(
			"PrintingAfterFormingTree",
			ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);	
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundJobStartResult.BackgroundJobResult,
			Notification,
			IdleParameters);

	Else
		If BackgroundJobStartResult.BackgroundJobResult.Status = "Completed2" Then
			PrintCostTree(BackgroundJobStartResult.BackgroundJobResult.ResultAddress);
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure AllSettings(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Report.ProductsCostTree.Form.ReportForm.Command.AllSettings");
	// End StandardSubsystems.PerformanceMeasurement
	
	Name = ReportSettings.FullName + ".SettingsForm";
	
	FormParameters = New Structure;
	CommonClientServer.SupplementStructure(FormParameters, ParametersForm, True);
	FormParameters.Insert("VariantKey",              String(CurrentVariantKey));
	FormParameters.Insert("Variant",                   Report.SettingsComposer.Settings);
	FormParameters.Insert("UserSettings", Report.SettingsComposer.UserSettings);
	FormParameters.Insert("ReportSettings",     ReportSettings);
	FormParameters.Insert("DescriptionOption", String(ReportCurrentOptionDescription));
	
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	Handler = New CallbackDescription("AllSettingsCompletion", ThisObject);
	
	OpenForm(Name, FormParameters, ThisObject, , , , Handler, Mode);
	
EndProcedure

&AtClient
Procedure AllSettingsCompletion(Result, ExecutionParameters) Export
	If Result = Undefined Or TypeOf(Result) = Type("Boolean") Then
		Return;
	EndIf;
	UpdateSettingsFormItems(Result);
EndProcedure

&AtClient
Procedure DefaultSettings(Command)
	
	FillParameters = ReportsClientServer.ReportFormUpdateParameters("DefaultSettings");
	If VariantModified Then
		FillParameters.ClearOptionSettings = True;
		FillParameters.VariantModified = False;
	EndIf;
	FillParameters.UserSettingsModified = True;
	
	UpdateSettingsFormItems(FillParameters);
	
EndProcedure

&AtClient
Procedure GenerateImmediately(Command)
	
	GenerateImmediately = Not Items.GenerateImmediately.Check;
	Items.GenerateImmediately.Check = GenerateImmediately;
	
	Report.SettingsComposer.UserSettings.AdditionalProperties.Insert("GenerateImmediately", GenerateImmediately);
	UserSettingsModified = True;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	TreeRows = FullCostTree.GetItems();
	If TreeRows.Count() = 0 Then
		Return;
	EndIf;
	
	UTurnIDs = New Array;
	For Each TreeRow In TreeRows Do
		
		SubordinateRows = TreeRow.GetItems();
		SubordinateRows.Clear();
		
		UTurnIDs.Add(TreeRow.GetID());
		
	EndDo;
	
	ExpandTreeOnServer(UTurnIDs);
	
	For Each RowID In UTurnIDs Do
		Items.FullCostTree.Expand(RowID, True);
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	TreeRows = FullCostTree.GetItems();
	For Each TreeRow In TreeRows Do
		Items.FullCostTree.Collapse(TreeRow.GetID());
	EndDo;
	
EndProcedure

#Region FormCommandHandlersPluggable

// Custom command to connect.
// Parameters:
//	Command - FormCommand - field to change.
&AtClient
Procedure Attachable_Command(Command)
	ConstantCommand = ConstantCommands.FindByValue(Command.Name);
	If ConstantCommand <> Undefined And ValueIsFilled(ConstantCommand.Presentation) Then
		SubstringsArray = StrSplit(ConstantCommand.Presentation, ".");
		ModuleClient = CommonClient.CommonModule(SubstringsArray[0]);
		Handler = New CallbackDescription(SubstringsArray[1], ModuleClient, Command);
		RunCallback(Handler, ThisObject);
	Else
		ReportsClientOverridable.HandlerCommands(ThisObject, Command, False);
	EndIf;
EndProcedure

// Plug-in download version of the report.
// Parameters:
//	Command - FormCommand - field to change.
&AtClient
Procedure Attachable_ImportReportOption(Command)
	FoundItems = AddedOptions.FindRows(New Structure("CommandName", Command.Name));
	If FoundItems.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không tìm thấy phương án báo cáo.';
								|ru = 'Вариант отчета не найден.';
								|en = 'Report option was not found.'; fa = 'Report option was not found.';
								|it = 'Variante del report non trovata.';
								|pl = 'Nie znaleziono wariantu raportu.';
								|tr = 'Rapor seçeneği bulunmadı.'"));
		Return;
	EndIf;
	
	FormOption = FoundItems[0];
	
	LoadVariant(FormOption.VariantKey);
	
	UniqueKey = ReportsClientServer.UniqueKey(ReportSettings.FullName, FormOption.VariantKey);
	
	If Items.GenerateImmediately.Check Then
		AttachIdleHandler("GenerateReport", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure EditFiltersConditions(Command)
	FormParameters = New Structure;
	FormParameters.Insert("ReportSettings", ReportSettings);
	FormParameters.Insert("SettingsComposer", Report.SettingsComposer);
	FormParameters.Insert("OnlyFastOnes", True);
	Handler = New CallbackDescription("EditFiltersConditionsCompletion", ThisObject);
	OpenForm("SettingsStorage.ReportsVariantsStorage.Form.ReportFiltersConditions", FormParameters, ThisObject, True, , , Handler);
EndProcedure

&AtClient
Procedure EditFiltersConditionsCompletion(UserSelection, Context) Export
	If UserSelection = Undefined
		Or UserSelection = DialogReturnCode.Cancel
		Or UserSelection.Count() = 0 Then
		Return;
	EndIf;
	FillParameters = ReportsClientServer.ReportFormUpdateParameters("EditFiltersConditions");;
	FillParameters.UserSettingsModified = True;
	FillParameters.FiltersConditions = UserSelection;
	UpdateSettingsFormItems(FillParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlersFullCostTree

&AtClient
Procedure FullCostTreeBeforeExpand(Item, String, Cancel)
	
	CurrentData = FullCostTree.FindByID(String);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SubordinateRows = CurrentData.GetItems();
	If SubordinateRows.Count() > 1 Then
		Return;
	ElsIf SubordinateRows.Count() = 1 Then
	
		
		SubordinateRow = SubordinateRows[0]; // FormDataTreeItem
		IDOfSubordinateLine = SubordinateRow.GetID();
		If ValueIsFilled(FullCostTree.FindByID(IDOfSubordinateLine).Id) Then
			Return;
		EndIf;
		
	EndIf;
	
	FullCostTreeBeforeExpandServer(String);
	
EndProcedure

&AtClient
Procedure FullCostTreeBeforeCollapse(Item, String, Cancel)
	
	CurrentData = FullCostTree.FindByID(String);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SubordinateRows = CurrentData.GetItems();
	SubordinateRows.Clear();
	SubordinateRows.Add();
		
EndProcedure

&AtClient
Procedure FullCostTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = FullCostTree.FindByID(RowSelected);
	FieldName = StrReplace(Field.Name, "FullCostTree", "");

	If ValueIsFilled(CurrentData[FieldName]) Then
		ShowValue(, CurrentData[FieldName]);
	Else
		UserMessage = NStr("vi = 'Chưa điền giá trị';
							|ru = 'Значение не заполнено';
							|en = 'Value is not filled in'; fa = 'Value is not filled in';
							|it = 'Значение не заполнено';
							|pl = 'Value is not filled in';
							|tr = 'Değer doldurulmadı'"); 
		ShowValue(, UserMessage);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateSettingsFormItems(ParametersOfUpdate)
	UpdateSettingsFormItemsAtServer(ParametersOfUpdate);
	
	If CommonClientServer.StructureProperty(ParametersOfUpdate, "Regenerate", False) Then
		ClearMessages();
		GenerateReport();
	EndIf;
EndProcedure

&AtServer
Procedure UpdateSettingsFormItemsAtServer(ParametersOfUpdate = Undefined)
	ImportSettingsToComposer(ParametersOfUpdate);
	
	ReportsServer.UpdateSettingsFormItems(
		ThisObject, Items.SettingsComposerUserSettings, ParametersOfUpdate);
	
	// The standard dialog is not shown if the user is forbidden to change the variants of this report.
	If Not ReportSettings.EditOptionsAllowed Then
		VariantModified = False;
	EndIf;
	
	SetVisibilityAvailability();
EndProcedure

&AtServer
Procedure ImportSettingsToComposer(ImportParameters)
	CheckImportParameters(ImportParameters);
	
	ReportObject = FormAttributeToValue("Report");
	If ReportSettings.Events.BeforeFillQuickSettingsBar Then
		ReportObject.BeforeFillQuickSettingsBar(ThisObject, ImportParameters);
	EndIf;
	
	AvailableSettings = ReportsServer.AvailableSettings(ImportParameters, ReportSettings);
	
	ClearOptionSettings = CommonClientServer.StructureProperty(
		ImportParameters, "ClearOptionSettings", False);
	If ClearOptionSettings Then
		LoadVariant(CurrentVariantKey, False);
	EndIf;
	
	ReportsServer.ResetCustomSettings(AvailableSettings, ImportParameters);
	
	ReportsServer.FillinAdditionalProperties(ReportObject,
		AvailableSettings.Settings,
		CurrentVariantKey,
		ReportSettings.PredefinedOptionKey,
		?(ParametersForm.InitialOptionKey = CurrentVariantKey, OptionContext, ""),
		?(ParametersForm.InitialOptionKey = CurrentVariantKey, ParametersForm.Filter, Undefined));
	
	If AvailableSettings.Settings <> Undefined And ReportSettings.Events.BeforeImportSettingsToComposer Then 
		ReportObject.BeforeImportSettingsToComposer(
			ThisObject,
			ReportSettings.SchemaKey,
			CurrentVariantKey,
			AvailableSettings.Settings,
			AvailableSettings.UserSettings);
	EndIf;
	
	SettingsImported = ReportsClientServer.LoadSettings(
		Report.SettingsComposer,
		AvailableSettings.Settings,
		AvailableSettings.UserSettings,
		AvailableSettings.FixedSettings);
	
	// The installation of fixed selections is performed through the linker, because it has the most complete collection of settings.
	// In preloading, the parameters may be missing those parameters whose settings have not been overridden.
	If SettingsImported
	   And ParametersForm.InitialOptionKey = CurrentVariantKey
	   And TypeOf(ParametersForm.Filter) = Type("Structure") Then
		
		ReportsServer.SetFixedFilters(ParametersForm.Filter, Report.SettingsComposer.Settings, ReportSettings);
	EndIf;
	
	ParametersForm.FixedSettings = Report.SettingsComposer.FixedSettings;
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("DescriptionOption", ReportCurrentOptionDescription);
	
	ReportObject = FormAttributeToValue("Report");
	If ReportSettings.Events.AfterLoadSettingsInLinker Then
		ReportObject.AfterLoadSettingsInLinker(New Structure);
	EndIf;
	If Not ReportSettings.Custom Then
		ReportObject.SettingsComposer.Settings.AdditionalProperties.Property(
			"DescriptionOption", ReportCurrentOptionDescription);
	EndIf;
	
	ReportsServer.SetAvailableValues(ReportObject, ThisObject);
	ReportsServer.InitializePredefinedOutputParameters(
		ReportSettings,
		Report.SettingsComposer.Settings,
		ReportsServer.ItIsRequiredToResetThePredefinedOutputParameters(ImportParameters));
	
	If ImportParameters.VariantModified Then
		VariantModified = True;
	EndIf;
	
	If ImportParameters.UserSettingsModified Then
		UserSettingsModified = True;
	EndIf;
	
	AdditionalProperties = Report.SettingsComposer.Settings.AdditionalProperties;
	AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
	AdditionalProperties.Insert("DescriptionOption", ReportCurrentOptionDescription);
	AdditionalProperties.Insert("OptionContext", OptionContext);
	
	// Preparation for pre-initialization of the linker (used during decryption).
	If ReportSettings.SchemaModified Then
		AdditionalProperties.Insert("SchemaURL", ReportSettings.SchemaURL);
	EndIf;
	
	If ImportParameters.Property("SettingsFormAdvancedMode") Then
		ReportSettings.SettingsFormAdvancedMode = ImportParameters.SettingsFormAdvancedMode;
	EndIf;
	
	If ImportParameters.Property("SettingsFormPageName") Then
		ReportSettings.SettingsFormPageName = ImportParameters.SettingsFormPageName;
	EndIf;
	
	ReportsServer.SetFiltersConditions(ImportParameters, Report.SettingsComposer);
	
	If ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox Then
		ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox = False;
		Items.GenerateImmediately.Check = CommonClientServer.StructureProperty(
			Report.SettingsComposer.UserSettings.AdditionalProperties,
			"GenerateImmediately",
			ReportSettings.GenerateImmediately);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckImportParameters(ImportParameters)
	
	If ImportParameters = Undefined Then
		ImportParameters = ReportsClientServer.ReportFormUpdateParameters("");
	EndIf;
	
	ImportParameters.VariantModified                    = VariantModified;
	ImportParameters.UserSettingsModified = UserSettingsModified;
	ImportParameters.ReportObjectOrFullName                 = ReportSettings.FullName;
	
EndProcedure

&AtServer
Procedure SetVisibilityHeaders()
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("UnitOfMeasure",						Undefined);
	ParametersStructure.Insert("AccuracyOfUnitOfMeasure",				2);
	ParametersStructure.Insert("DisplayCostType",						False);
	ParametersStructure.Insert("DisplayCompany",					False);
	ParametersStructure.Insert("DisplayTheCostDivision",			False);
	ParametersStructure.Insert("ItemizeTheCostToTheComponents",	False);
	ParametersStructure.Insert("Cost_Data",					1);
	ParametersStructure.Insert("DisplayPRVR",							False);
	GetCDSettingsValues(ParametersStructure);
	
	#Region AmountHeaders
	PropertyValue = ParametersStructure.UnitOfMeasure;
	
	If ParametersStructure.UnitOfMeasure <> 3 Or ParametersStructure.UnitOfMeasure <> 6 Then
		ParametersStructure.UnitOfMeasure = 0;
	EndIf;
	
	FormatTemplate = "NS=%1; ND=19; NFD=%2";
	FormatLine = StrTemplate(FormatTemplate, 
		Format(ParametersStructure.UnitOfMeasure, "NZ=0; NG=0"), 
		Format(ParametersStructure.AccuracyOfUnitOfMeasure, "NZ=0; NG=0"));
		
	Items.FullCostTreeSum.Format = FormatLine;
	Items.FullCostTreeOffBalanceSheetAmount.Format = FormatLine;
	Items.FullCostTreeMaterial_.Format = FormatLine;
	Items.FullCostTreeLaborCosts.Format = FormatLine;
	Items.FullCostTreeItemizedFixed.Format = FormatLine;
	Items.FullCostTreeItemizedVariable.Format = FormatLine;
	Items.FullCostTreeAddExpensesForGoods.Format = FormatLine;
	Items.FullCostTreeTaxAccounting.Format = FormatLine;
	Items.FullCostTreePermanentDifference.Format = FormatLine;
	Items.FullCostTreeCostTD.Format = FormatLine;
	Items.FullCostTreeAIT.Format = FormatLine;
	
	#EndRegion
	
	PropertyValue = ParametersStructure.DisplayCompany;
	Items.FullCostTreeOrganization.Visible = PropertyValue;
	
	PropertyValue = ParametersStructure.DisplayTheCostDivision;
	Items.FullCostTreeDepartment.Visible = PropertyValue;
	
	PropertyValue = ParametersStructure.DisplayCostType;
	Items.FullCostTreeExpenseType.Visible = PropertyValue;
	
	PropertyValue = ParametersStructure.ItemizeTheCostToTheComponents;
	Items.FullCostTreeMaterial_.Visible	= PropertyValue;
	Items.FullCostTreeLaborCosts.Visible	= PropertyValue;
	Items.FullCostTreeAddExpensesForGoods.Visible		= PropertyValue;
	Items.FullCostTreeItemizedVariable.Visible = PropertyValue;
	Items.FullCostTreeItemizedFixed.Visible = PropertyValue;
	
	PropertyValue = CalculationOfCostLocalization.GetFunctionalOptionAITAccounting();
	Items.FullCostTreeAIT.Visible = PropertyValue;
	
	Items.FullCostTreeTaxAccounting.Visible = GetFunctionalOption("UseLocal")
		And ParametersStructure.Cost_Data = 4;
	Items.FullCostTreePermanentDifference.Visible = ParametersStructure.DisplayPRVR
		And GetFunctionalOption("UseLocal")
		And ParametersStructure.Cost_Data = 4;
	Items.FullCostTreeCostTD.Visible = ParametersStructure.DisplayPRVR
		And GetFunctionalOption("UseLocal")
		And ParametersStructure.Cost_Data = 4;
	
EndProcedure

&AtServer
Procedure EstablishSelectionByProductionOrder(Filters, ProductionOrder)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductionStage2_2.Ref AS Stage
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.ReferenceOrder = &OrderDocument
	|
	|GROUP BY
	|	ProductionStage2_2.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ProcessorReports.Ref AS Stage
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|	
	|	INNER JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS ProcessorReports
	|	ON ProcessorReports.ProductionStage = ProductionStage2_2.Ref
	|
	|WHERE
	|	ProductionStage2_2.ReferenceOrder = &OrderDocument
	|
	|GROUP BY
	|	ProcessorReports.Ref
	|";
	
	Query.SetParameter("OrderDocument", ProductionOrder);
	Stages = Query.Execute().Unload();
	
	If Not Stages.Count() = 0 Then
		Filters.Insert("ProductsBatch", Stages.UnloadColumn("Stage"));
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionBasedOnProcessorReports(Filters, ProductionStage)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProcessorReports.Ref AS Stage
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS ProcessorReports
	|
	|WHERE
	|	ProcessorReports.ProductionStage = &ProductionStage
	|
	|GROUP BY
	|	ProcessorReports.Ref
	|";
	
	Query.SetParameter("ProductionStage", ProductionStage);
	Stages = Query.Execute().Unload();
	
	If Not Stages.Count() = 0 Then
		Filters.Insert("ProductsBatch", Stages.UnloadColumn("Stage"));
	Else
		Filters.Insert("ProductsBatch", ProductionStage);
	EndIf;
	
EndProcedure
&AtServer
Procedure GetCDSettingsValues(ParametersStructure)
	
	DCSettingsComposer = Report.SettingsComposer;
	For Each CurParameter In ParametersStructure Do
		DCParameter = DataCompositionClientServer.GetParameter(DCSettingsComposer.Settings, CurParameter.Key);
		SettingID = DCParameter.UserSettingID;
		DCUserSetting = DCSettingsComposer.UserSettings.Items.Find(SettingID);
		
		If Not DCUserSetting = Undefined Then
			ParametersStructure[CurParameter.Key] = DCUserSetting.Value;
		Else
			ParametersStructure[CurParameter.Key] = DCParameter.Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure VisibilityAvailabilityIfRequired()
	If PanelOptionsCurrentOptionKey <> " - " Then // The changes have already been applied
		Return;
	EndIf;
	SetVisibilityAvailability();
EndProcedure

&AtServer
Procedure SetVisibilityAvailability(OnSaveOption = False)
	
	ShowOptionsSelectionCommands = ReportOptionMode() And ReportSettings.OptionSelectionAllowed;
	
	If Not OnSaveOption Then
		ShowOptionChangingCommands = ShowOptionsSelectionCommands And ReportSettings.EditOptionsAllowed;
		SelectAndEditOptionsWithoutSavingAllowed = CommonClientServer.StructureProperty(
			ReportSettings, "SelectAndEditOptionsWithoutSavingAllowed", False);
		CountOfAvailableSettings = ReportsServer.CountOfAvailableSettings(Report.SettingsComposer);
		
		Items.AllSettings.Visible = ShowOptionChangingCommands Or CountOfAvailableSettings.Typical > 0;
		Items.ReportOptionsGroup.Visible = ShowOptionsSelectionCommands;
		
		SaveOptionAllowed = ShowOptionChangingCommands
			And Not SelectAndEditOptionsWithoutSavingAllowed;
		CommonClientServer.SetFormItemProperty(
			Items, "SaveVariant", "Visible", SaveOptionAllowed);
		CommonClientServer.SetFormItemProperty(
			Items, "SaveOptionMore", "Visible", SaveOptionAllowed);
		
		Items.SelectOption.Visible = ShowOptionsSelectionCommands;
		
		UseSettingsAllowed = ShowOptionsSelectionCommands And CountOfAvailableSettings.Total > 0;
		CommonClientServer.SetFormItemProperty(
			Items, "SelectSettings", "Visible", UseSettingsAllowed);
		CommonClientServer.SetFormItemProperty(
			Items, "ShouldSaveSettings", "Visible", UseSettingsAllowed);
		
		Items.EditFiltersConditions.Visible = CountOfAvailableSettings.Total > 0 And ReportOptionMode();
		
		If SelectAndEditOptionsWithoutSavingAllowed Then
			VariantModified = False;
		EndIf;
	EndIf;
	
	// Option selection commands.
	If PanelOptionsCurrentOptionKey <> CurrentVariantKey Then
		PanelOptionsCurrentOptionKey = CurrentVariantKey;
		
		If ShowOptionsSelectionCommands Then
			FillOutOptionSelectionCommands();
		EndIf;
				
		URL = "";
		If ValueIsFilled(ReportSettings.OptionRef)
			And Not ReportSettings.External
			And Not ReportSettings.Contextual Then
			URL = GetURL(ReportSettings.OptionRef);
		EndIf;
	EndIf;
	
	ReportObject = FormAttributeToValue("Report");
	EmptySettings = CostStructure.InitializeReportSettings(
		Report, CurrentVariantKey, ReportObject);
		
	FillPropertyValues(EmptySettings, ReportSettings);
	CommonClientServer.SupplementStructure(EmptySettings, ReportSettings, False);
	// Heading.
	ReportCurrentOptionDescription = TrimAll(ReportCurrentOptionDescription);
	If ValueIsFilled(ReportCurrentOptionDescription) Then
		Title = ReportCurrentOptionDescription;
	Else
		Title = EmptySettings.Description;
	EndIf;
	
	If DetailsMode Then
		Title = Title + " (" + NStr("vi = 'Diễn giải';
									|ru = 'Расшифровка';
									|en = 'Drill-down'; fa = 'جزئیات بیشتر';
									|it = 'Decrittazione';
									|pl = 'Szczegóły płatności';
									|tr = 'Detaylandırma'") + ")";
	EndIf;
	
EndProcedure

&AtClient
Function FindCustomSettingOfItem(ElementNameOrID) Export
	// For user settings, data layout identifiers are stored,
	//  since they cannot be stored by reference (the value is copied).
	If StrLen(ElementNameOrID) = 32 Then
		ItemID = ElementNameOrID;
	Else
		ItemID = Right(ElementNameOrID, 32);
	EndIf;
	DCID = QuickSearchOfCustomSettings.Get(ItemID);
	If DCID = Undefined Then
		Return Undefined;
	Else
		Return Report.SettingsComposer.UserSettings.GetObjectByID(DCID);
	EndIf;
EndFunction

&AtClient
Function FindAdditionalItemSettings(ItemID) Export
	// For user settings, data layout identifiers are stored,
	//  since they cannot be stored by reference (the value is copied).
	AllAdditionalSettings = CommonClientServer.StructureProperty(
		Report.SettingsComposer.UserSettings.AdditionalProperties, "FormItems");
	If AllAdditionalSettings = Undefined Then
		Return Undefined;
	Else
		Return AllAdditionalSettings[ItemID];
	EndIf;
EndFunction

&AtServer
Procedure ShowGenerationErrors(ErrorInfo)
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		ErrorDescription = BriefErrorDescription(ErrorInfo);
		DetailErrorDescription = NStr("vi = 'Lỗi khi lập báo cáo:';
										|ru = 'Ошибка при формировании:';
										|en = 'Generation error:'; fa = 'Generation error:';
										|it = 'Errore durante la generazione:';
										|pl = 'Błąd podczas tworzenia:';
										|tr = 'Düzenleme hatası:'") + Chars.LF + DetailErrorDescription(ErrorInfo);
		If IsBlankString(ErrorDescription) Then
			ErrorDescription = DetailErrorDescription;
		EndIf;
	Else
		ErrorDescription = ErrorInfo;
		DetailErrorDescription = "";
	EndIf;
	
	CommonClientServer.MessageToUser(ErrorDescription);
	
	If Not IsBlankString(DetailErrorDescription) Then
		ReportsOptions.WriteToLog(EventLogLevel.Warning, DetailErrorDescription, ReportSettings.OptionRef);
	EndIf;
	
EndProcedure

#Region Print

&AtClient
Procedure PrintingAfterFormingTree(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And Result.Status = "Completed2"
		Then
		PrintCostTree(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintCostTree(AddressOfTreeInRepository)
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.Products.EmptyRef"));
	
	TemplatesNames = "CostPriceTree";
	PrintParameters = CostTreePrintingOptions();
	PrintParameters.Insert("AddressOfTreeInRepository", AddressOfTreeInRepository);
	
	PrintManagementClient.ExecutePrintCommand(
		"Report.ProductsCostTree",
		TemplatesNames,
		CommandParameter,
		ThisObject,
		PrintParameters);
	
EndProcedure

&AtServer
Function CostTreePrintingOptions()
	
	PrintParameters = New Structure;
	
	DCSettings = Report.SettingsComposer.GetSettings();
	PrintParameters.Insert("ReportParameters", GetReportParameters(DCSettings));
	PrintParameters.Insert("AddressOfSelectionInRepository", PutToTempStorage(DCSettings.Filter,
		UUID));
	
	Return PrintParameters;
	
EndFunction

&AtServer
Function GetReportParameters(DCSettings)
	
	ParametersStructure = New Structure();
	
	DataParameters = DCSettings.DataParameters;
	PeriodParameter = DataParameters.FindParameterValue(New DataCompositionParameter("Period"));
	ParameterDetailCostToComponents = DataParameters.FindParameterValue(New DataCompositionParameter("ItemizeTheCostToTheComponents"));
	ParameterCostData = DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data"));
	DisplayPRVRParameter = DataParameters.FindParameterValue(New DataCompositionParameter("DisplayPRVR"));
	
	ParametersStructure.Insert("ItemizeTheCostToTheComponents", ParameterDetailCostToComponents.Value);
	ParametersStructure.Insert("Cost_Data", ParameterCostData.Value);
	ParametersStructure.Insert("DisplayPRVR", DisplayPRVRParameter.Value);
	
	If Not PeriodParameter.Use Or Not ValueIsFilled(PeriodParameter.Value) Then
		ParametersStructure.Insert("Period", New StandardPeriod());
	Else
		ParametersStructure.Insert("Period", PeriodParameter.Value);
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region FillingCostTree

&AtClient
Procedure GenerateReport()
	ReportCreated = False;
	FullCostTree.GetItems().Clear();
	BackgroundJobStartResult = BackgroundJobRun();
	If BackgroundJobStartResult.JobStarted Then
		TimeConsumingOperationsClient.InitIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobCheckOnClient", 1, True);
	Else
		AfterGenerationOnClient();
	EndIf;
EndProcedure

&AtServer
Function BackgroundJobRun(FormationForPrintedForm = False)
	
	Result = New Structure("JobStarted,BackgroundJobResult", False, Undefined);
	
	If IDBackgroundJob <> Undefined Then
		CancelBackgroundTask(IDBackgroundJob);
		IDBackgroundJob = Undefined;
	EndIf;
	
	If Not CheckFilling() Then
		ErrorText = "";
		Messages = GetUserMessages(True);
		For Each Message In Messages Do
			ErrorText = ErrorText + ?(ErrorText = "", "", ";" + Chars.LF + Chars.LF) + Message.Text;
		EndDo;
		ShowGenerationErrors(ErrorText);
		Return Result;
	EndIf;
	
	// Starting a background task
	DCSchema		= GetFromTempStorage(ReportSettings.SchemaURL);
	DCSettings	= Report.SettingsComposer.GetSettings();
	
	DataCompositionClientServer.SetParameter(DCSettings, "ManagementAccountingCurrency",
										SettingsValueCached.ManagementAccountingCurrency()); 
	
	TreeParameters = CostStructure.CostTreeParameters();
	TreeParameters.DynamicReading = Not FormationForPrintedForm;
	TreeParameters.ResultTypeValueTree = True;
	TreeParameters.DCSchema = DCSchema;
	TreeParameters.DCSettings = DCSettings;
	TreeParameters.InteractiveSetup = True;
	TreeParameters.ReportParameters.Cost_Data = DataCompositionClientServer.GetParameter(
		Report.SettingsComposer, "Cost_Data").Value;
	
	ReportGenerationParameters = New Structure;
	ReportGenerationParameters.Insert("TreeParameters", TreeParameters);
	
	ReportName = StrSplit(ReportSettings.FullName, ".")[1];
	
	StartupParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartupParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lập báo cáo: %1';
			|ru = 'Построение отчета: %1';
			|en = 'Creating report: %1'; fa = 'Creating report: %1';
			|it = 'Creazione report: %1';
			|pl = 'Budowanie raportu: %1';
			|tr = 'Raporun oluşturulması: %1'"),
		ReportName);
	StartupParameters.WaitCompletion	= False;
	StartupParameters.RunNotInBackground1	= False;
	BackgroundJobResult = TimeConsumingOperations.ExecuteInBackground(
		"CostStructure.BuildCostTreeInBackground",
		ReportGenerationParameters,
		StartupParameters);
	
	If BackgroundJobResult.Status = "Error" Then
		ShowGenerationErrors(BackgroundJobResult.BriefErrorDescription);
		Return Result;
	EndIf;
	
	IDBackgroundJob  = BackgroundJobResult.JobID;
	BackgroundJobStorageAddress = BackgroundJobResult.ResultAddress;
	
	If BackgroundJobResult.Status = "Completed2" Then
		If Not FormationForPrintedForm Then
			BackgroundTaskLoadResult();
		EndIf;
	Else
		If Not FormationForPrintedForm Then
			Items.Print.Enabled = False;
			Items.TheReportGroupIsBeingGenerated.Visible = True;
			Items.FullCostTree.Visible = False;
		EndIf;
		Result.JobStarted = True;
	EndIf;
	
	// Additional verification of accounting settings
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(Report.SettingsComposer, "Period");
	StdPeriod = ReportPeriodParameter.Value; // StandardPeriod
	BeginOfPeriod = ?(ReportPeriodParameter.Use, StdPeriod.StartDate, BegOfYear(CurrentSessionDate()));
	EndOfPeriod = ?(ReportPeriodParameter.Use, StdPeriod.EndDate, CurrentSessionDate());
	
	WarningText = CostCalculationAppliedAlgorithms.WarningTextUnsupportedOrganizations(BeginOfPeriod, EndOfPeriod, Report.SettingsComposer);
	If Not IsBlankString(WarningText) Then
		CommonClientServer.MessageToUser(WarningText);
	EndIf;
	
	Result.Insert("BackgroundJobResult", BackgroundJobResult);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure CancelBackgroundTask(IDBackgroundJob)
	TimeConsumingOperations.CancelJobExecution(IDBackgroundJob);
EndProcedure

&AtClient
Procedure BackgroundJobCheckOnClient()
	Job = BackgroundTaskCheckOnServer();
	If Job.Running Then
		TimeConsumingOperationsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("BackgroundJobCheckOnClient", HandlerParameters.CurrentInterval, True);
	Else
		If ReportCreated Then
			ShowUserNotification(NStr("vi = 'Báo cáo đã lập';
										|ru = 'Отчет сформирован';
										|en = 'Report is generated'; fa = 'گزارش ایجاد شد';
										|it = 'Il report è stato generato';
										|pl = 'Raport wygenerowany';
										|tr = 'Rapor oluşturuldu'"), , Title);
		Else
			ShowUserNotification(NStr("vi = 'Chưa lập báo cáo';
										|ru = 'Отчет не сформирован';
										|en = 'Report is not generated'; fa = 'Report is not generated';
										|it = 'Il report non è stato generato';
										|pl = 'Raport nie wygenerowany';
										|tr = 'Rapor düzenlenmedi'"), , Title);
		EndIf;
		AfterGenerationOnClient();
	EndIf;
EndProcedure

&AtServer
Function BackgroundTaskCheckOnServer()
	Job = FindJobInternal(IDBackgroundJob);
	If Not Job.Running Then
		If Job.Success Then
			BackgroundTaskLoadResult();
		Else
			ShowGenerationErrors(Job.Error);
		EndIf;
	EndIf;
	Job.Delete("Error");
	Return Job;
EndFunction

&AtServer
Procedure BackgroundTaskLoadResult()
	
	ResultOfFormation = GetFromTempStorage(BackgroundJobStorageAddress);
	
	DeleteFromTempStorage(BackgroundJobStorageAddress);
	BackgroundJobStorageAddress = Undefined;
	IDBackgroundJob = Undefined;
	
	ValueToFormAttribute(ResultOfFormation.CostPriceTree, "FullCostTree");
	SetVisibilityHeaders();
	
	ReportCreated = True;
	
EndProcedure

&AtServer
Function FindJobInternal(Val Id)
	Result = New Structure("Running, Success, Error", False, False, Undefined);
	If Id = Undefined Then
		Return Result;
	EndIf;
	Job = BackgroundJobs.FindByUUID(Id);
	If Job = Undefined Then
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Active Then
		Result.Running = True;
	Else
		Result.Running = False;
		If Job.State = BackgroundJobState.Completed Then
			Result.Success = True;
		Else
			Result.Success = False;
			Result.Error = Job.ErrorInfo;
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Procedure AfterGenerationOnClient()
	//Disable the Wait handler("Background Task Check the client");
	//Show the result of filling in the settings();
	//
	Items.Print.Enabled = True;
	Items.TheReportGroupIsBeingGenerated.Visible = False;
	Items.FullCostTree.Visible = True;
	//
	//Update the display of the data();
EndProcedure

&AtServer
Procedure ExpandTreeOnServer(UTurnIDs)
	
	CostPriceTree = FormAttributeToValue("FullCostTree");
	
	TreeParameters = PrepareTreeParameters();
	For Each RowID In UTurnIDs Do
		CurrentData = FullCostTree.FindByID(RowID);
		TreeRow = CostPriceTree.Rows.Find(CurrentData.Id, "Id", True);
		
		If CurrentData.Count = 0 Then //checking for a suspended issue in the selected period
			Continue;
		EndIf;
		// Comment 1442.
		// During dynamic reading, an
		// empty line was added to the lines of the current line of the tree in order to be able to click on +
		// and get the location for the selected position.
		// When untangling, the subordinate rows must first be cleared.
		TreeRow.Rows.Clear();
		AddSelectionStringToTreeParameters(TreeParameters, CurrentData, TreeRow, True);
	EndDo;
	
	CostStructure.LoadNodeSelectionTableIntoTempTable(TreeParameters);
	CostStructure.CostTreeBeforeDeployment(TreeParameters);
	
	For Each RowID In UTurnIDs Do
		CurrentData = FullCostTree.FindByID(RowID);
		
		If CurrentData.Count = 0 Then //checking for a suspended issue in the selected period
			Continue;
		EndIf;
		
		TreeRow = CostPriceTree.Rows.Find(CurrentData.Id, "Id", True);
		OutputNewCostTreeElements(CurrentData, TreeRow);
	EndDo;
	
EndProcedure

&AtServer
Function PrepareTreeParameters()
	
	TreeParameters = CostStructure.CostTreeParameters();
	TreeParameters.ResultTypeValueTree = True;
	
	#Region CostTreeForReport
	CostStructure.FillInParametersOfCostTree(TreeParameters);
	
	TreeParameters.ResultTypeValueTree = True;
	TreeParameters.ReportParameters.Cost_Data = DataCompositionClientServer.GetParameter(
		Report.SettingsComposer, "Cost_Data").Value;
	TreeParameters.ReportParameters.EndDate = DataCompositionClientServer.GetParameter(
		Report.SettingsComposer, "EndDate").Value;
	TreeParameters.ReportParameters.ManagementAccountingCurrency = DataCompositionClientServer.GetParameter(
		Report.SettingsComposer, "ManagementAccountingCurrency").Value;
	
	TreeParameters.ReportParameters.ForTheWholePeriod = Not (ValueIsFilled(TreeParameters.ReportParameters.StartDate)
												Or ValueIsFilled(TreeParameters.ReportParameters.EndDate));
	TreeParameters.ReportParameters.ByAllCompanies = Not ValueIsFilled(TreeParameters.ReportParameters.Companies);
	TreeParameters.ReportParameters.ByAllBusinessUnits = Not ValueIsFilled(TreeParameters.ReportParameters.Departments);
	TreeParameters.ReportParameters.DecryptionOfDocumentRegisteredRecords = ValueIsFilled(TreeParameters.ReportParameters.Recorders);
	
	#EndRegion
	
	Return TreeParameters;
	
EndFunction

&AtServer
Procedure AddSelectionStringToTreeParameters(TreeParameters, CurrentData, TreeRow, WithSubordinates)

	NewSelectionLine = TreeParameters.NodeSelectionTable.Add();
	FillPropertyValues(NewSelectionLine, CurrentData);
	NewSelectionLine.NodeID = String(New UUID());
	NewSelectionLine.IdOfFirstLevelNode = NewSelectionLine.NodeID;
	TreeParameters.DynamicReading = Not WithSubordinates;
	TreeParameters.MapOfNodes.Insert(NewSelectionLine.IdOfFirstLevelNode, TreeRow);
	If WithSubordinates Then
		HigherLevelNodes = New Array();
		TreeParameters.HigherLevelNodes.Insert(NewSelectionLine.IdOfFirstLevelNode, HigherLevelNodes);
	EndIf;
	
	NewSelectionLine.NodeOfFirstLevel_AnalyticsOfManufacturedProductAccounting = CurrentData.ProductsAccountingDimension;
	NewSelectionLine.ExpenseAccountingAnalytics = CurrentData.ProductsAccountingDimension;
	NewSelectionLine.NodeOfFirstLevel_LotReferenceOfManufacturedProducts = CurrentData.ProductsBatch;
	NewSelectionLine.NodeOfFirstLevelIs_BatchAccountingAnalysisOfManufacturedProductsLotsVendorAttributes = CurrentData.ProductBatchAccountingDimension;
	NewSelectionLine.ExpenseAccountingAnalytics = CurrentData.CostAccountingDimension;
	NewSelectionLine.Level = TreeParameters.NodeLevel;
	
	NewSelectionLine.ForAllProducts = Not ValueIsFilled(CurrentData.Products);
	NewSelectionLine.ManufacturedProduct = CurrentData.Products;
	NewSelectionLine.ForAllParties = Not ValueIsFilled(CurrentData.Lot);
	NewSelectionLine.ProductsBatch = CurrentData.Lot;
	NewSelectionLine.AccordingToAllCharacteristics = Not ValueIsFilled(CurrentData.Characteristic);
	NewSelectionLine.ItemVariant = CurrentData.Characteristic;
	// If there is a selection according to the batch accounting Lot's:vendor attribute, selection by series does not make sense, because the Lot:vendor attribute of the batch accounting determines the line of output.
	// 
	NewSelectionLine.ForAllSeries = Not ValueIsFilled(CurrentData.Series)
		Or ValueIsFilled(CurrentData.LotVendorAttributes);
	NewSelectionLine.ProductionSeries_ = CurrentData.Series;
	// When sorting out a batch of products, we take into account the selection for the intended purpose.
	// When uncoupling semi-finished products, selection for the intended purpose is not necessary,
	// because the semi-finished product can be released without an appointment or
	// with an indication of another appointment.
	If CurrentData.LineKind = Enums.KindsOfCostTreeRows.ProductsBatch Then
		NewSelectionLine.ForAllAppointments = Not ValueIsFilled(CurrentData.Purpose);
	Else
		NewSelectionLine.ForAllAppointments = True;
	EndIf;
	NewSelectionLine.AssignmentOfProducts = CurrentData.Purpose;
		
	NewSelectionLine.AccordingToAllPartyAnalysts = Not ValueIsFilled(CurrentData.LotVendorAttributes);
	NewSelectionLine.ProductBatchAccountingDimension = CurrentData.LotVendorAttributes;
	NewSelectionLine.Denominator = Max(-CurrentData.Denominator, CurrentData.Denominator);
	NewSelectionLine.ProductsQuantity = Max(-CurrentData.Count, CurrentData.Count);

	NewSelectionLine.OriginalBatchDate = CurrentData.OriginalBatchDate;
	NewSelectionLine.DateOfOriginalLotReference_BeginningOfMonth = BegOfMonth(NewSelectionLine.OriginalBatchDate);
	NewSelectionLine.DateOfOriginalLotReference_EndOfMonth = EndOfMonth(NewSelectionLine.OriginalBatchDate);
	NewSelectionLine.DeployAdditionalCosts = TreeParameters.ReportParameters.DeployAdditionalCosts;
	
	CostStructure.SetOptionsForConnectionConditionsByNodeParameters(TreeParameters);

EndProcedure

&AtServer
Procedure FullCostTreeBeforeExpandServer(RowID)
	
	CostPriceTree = FormAttributeToValue("FullCostTree");
	CurrentData = FullCostTree.FindByID(RowID);
	TreeRow = CostPriceTree.Rows.Find(CurrentData.Id, "Id", True);
	
	If CurrentData.Count = 0 Then //checking for a suspended issue in the selected period
		Return;
	EndIf;
	
	// See comment 1442.
	TreeRow.Rows.Clear();
	
	#Region PreparingTreeForFormation
	TreeParameters = PrepareTreeParameters();
	AddSelectionStringToTreeParameters(TreeParameters, CurrentData, TreeRow, False);
	CostStructure.LoadNodeSelectionTableIntoTempTable(TreeParameters);
	#EndRegion
	
	CostStructure.CostTreeBeforeDeployment(TreeParameters);
	OutputNewCostTreeElements(CurrentData, TreeRow);
	
EndProcedure

&AtServer
Procedure OutputNewCostTreeElements(CurrentData, Result)
	
	SubordinateItems = CurrentData.GetItems();
	SubordinateItems.Clear();
	
	For Each CurRow In Result.Rows Do
		If ValueIsFilled(CurRow.CostAccountingDimension)
			And CurRow.Sum = 0
			And CurRow.OffBalanceSheetAmount = 0
			And CurRow.TaxAccounting = 0
			And CurRow.AIT = 0
			And CurRow.Count = 0 Then
				
			Continue;
		EndIf;
		
		NewRow = SubordinateItems.Add();
		FillPropertyValues(NewRow, CurRow);
		OutputNewCostTreeElements(NewRow, CurRow);
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Function ReportOptionMode()
	Return TypeOf(CurrentVariantKey) = Type("String") And Not IsBlankString(CurrentVariantKey);
EndFunction

#Region GroupingLevels

&AtServerNoContext
Procedure SaveTheSelectedGroupingLevel(ValueStorageKey, SelectedGroupsLevel, DetailsMode)
	
	If DetailsMode Then 
		Return;
	EndIf;
	
	Common.FormDataSettingsStorageSave(
		ValueStorageKey, "SelectedGroupsLevel", SelectedGroupsLevel);
	
EndProcedure

&AtServerNoContext
Procedure RestoreTheSelectedGroupingLevel(ValueStorageKey, SelectedGroupsLevel, DetailsMode)
	
	If DetailsMode Then 
		Return;
	EndIf;
	
	SavedValue = Common.FormDataSettingsStorageLoad(
		ValueStorageKey, "SelectedGroupsLevel");
	
	If ValueIsFilled(SavedValue) Then 
		SelectedGroupsLevel = SavedValue;
	Else
		SelectedGroupsLevel = UndefinedLevelOfGroupings();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function UndefinedLevelOfGroupings()
	Return 999;
EndFunction

#EndRegion

#Region OutputOfSettingsHeaders

&AtServerNoContext
Procedure SaveTheStateOfTheOptionOutputSettingsHeaders(ValueStorageKey, OutputSettingsTitles, DetailsMode)
	
	If DetailsMode Then 
		Return;
	EndIf;
	
	Common.FormDataSettingsStorageSave(
		ValueStorageKey, "OutputSettingsTitles", OutputSettingsTitles);
	
EndProcedure

&AtServerNoContext
Procedure RestoreTheStateOfTheOutputSettingsHeadersOption(ValueStorageKey, OutputSettingsTitles, DetailsMode)
	
	If DetailsMode Then 
		Return;
	EndIf;
	
	SavedValue = Common.FormDataSettingsStorageLoad(
		ValueStorageKey, "OutputSettingsTitles");
	
	OutputSettingsTitles = SavedValue = Undefined Or SavedValue = True;
	
EndProcedure

#EndRegion

#Region FillingOptions_

&AtServer
Procedure UpdateInfoOnReportOption()
	Report.SettingsComposer.Settings.AdditionalProperties.Insert("VariantKey", CurrentVariantKey);
	Report.SettingsComposer.Settings.AdditionalProperties.Insert("DescriptionOption", ReportCurrentOptionDescription);
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	ReportsOptions.Ref AS OptionRef,
	|	ReportsOptions.PredefinedOption AS PredefinedRef,
	|	CASE
	|		WHEN ReportsOptions.Custom
	|				OR ReportsOptions.Parent.VariantKey IS NULL 
	|			THEN ReportsOptions.VariantKey
	|		ELSE ReportsOptions.Parent.VariantKey
	|	END AS OriginalOptionName,
	|	ReportsOptions.Custom AS Custom
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Report = &Report
	|	AND ReportsOptions.VariantKey = &VariantKey";
	Query.SetParameter("Report", ReportSettings.ReportRef);
	Query.SetParameter("VariantKey", CurrentVariantKey);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ReportSettings.Insert("OptionRef",          Selection.OptionRef);
		ReportSettings.Insert("PredefinedRef", Selection.PredefinedRef);
		ReportSettings.Insert("OriginalOptionName",   ?(Selection.Custom, Selection.OriginalOptionName, CurrentVariantKey));
		ReportSettings.Insert("Custom",       Selection.Custom);
	Else
		ReportSettings.Insert("OptionRef",          Undefined);
		ReportSettings.Insert("PredefinedRef", Undefined);
		ReportSettings.Insert("OriginalOptionName",   Undefined);
		ReportSettings.Insert("Custom",       False);
	EndIf;
EndProcedure

&AtServer
Procedure LoadVariant(VariantKey, ClearStackSettings = True)
	If Not DetailsMode And Not VariantModified Then
		ObjectKey = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1/%2/%3';
				|ru = '%1/%2/%3';
				|en = '%1/%2/%3'; fa = '%1/%2/%3';
				|it = '%1/%2/%3';
				|pl = '%1/%2/%3';
				|tr = '%1/%2/%3'"),
			ReportSettings.FullName,
			CurrentVariantKey,
			"CurrentUserSettings");
		
		Common.SystemSettingsStorageSave(
			ObjectKey, "", Report.SettingsComposer.UserSettings);
	EndIf;
	
	SaveDataInSettingsOnServer();
	
	DetailsMode = False;
	VariantModified = False;
	UserSettingsModified = False;
	ReportSettings.ReadCreateFromUserSettingsImmediatelyCheckBox = True;
	
	PutToTempStorage(Undefined, ReportSettings.ResultProperties.AddressOfTheReportStructureIndex);
	
	If ClearStackSettings Then 
		StackSettings.Clear();
	EndIf;
	
	SetCurrentVariant(VariantKey);
	ReportsClientServer.DisplayReportState(
		ThisObject,
		NStr("vi = 'Đã chọn phương án báo cáo khác. Hãy nhấn ""Lập báo cáo"" để nhận báo cáo.';
			|ru = 'Выбран другой вариант отчета. Нажмите ""Сформировать"" для получения отчета.';
			|en = 'Another report option is selected. To generate the report, click ""Generate"".'; fa = 'Another report option is selected. To generate the report, click ""Generate"".';
			|it = 'È stata selezionata una variante del report diversa. Fai clic su ""Genera"" per generare un report.';
			|pl = 'Wybrano inną opcję raportu. Kliknij ""Generuj"", aby wygenerować raport.';
			|tr = 'Başka bir rapor seçeneği seçildi. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'"),
		PictureLib.Information32);
EndProcedure

&AtServer
Procedure FillOutOptionSelectionCommands()
	FormOptions = FormAttributeToValue("AddedOptions");
	FormOptions.Columns.Add("Found", New TypeDescription("Boolean"));
	AuthorizedUser = Users.AuthorizedUser();
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Reports", CommonClientServer.ValueInArray(ReportSettings.ReportRef));
	SearchParameters.Insert("DeletionMark", False);
	SearchParameters.Insert("GetSummaryTable", True);
	VariantsTable = ReportsOptions.ReportOptionTable(SearchParameters);
	If ReportSettings.External Then // Add predefined external report options to the options table.
		For Each ListItem In ReportSettings.PredefinedOptions Do
			TableRow = VariantsTable.Add();
			TableRow.Description = ListItem.Presentation;
			TableRow.VariantKey = ListItem.Value;
		EndDo;
	EndIf;
	VariantsTable.GroupBy("Ref, VariantKey, Description, Author, AuthorOnly");
	VariantsTable.Sort("Description Asc, VariantKey Asc");
	
	Var_Group = Items.ReportOptions;
	LastIndex = FormOptions.Count() - 1;
	For Each TableRow In VariantsTable Do
		If TableRow.AuthorOnly = True
			And TableRow.Author <> AuthorizedUser Then
			Continue;
		EndIf;
		FoundItems = FormOptions.FindRows(New Structure("VariantKey, Found", TableRow.VariantKey, False));
		If FoundItems.Count() = 1 Then
			FormOption = FoundItems[0];
			FormOption.Found = True;
			Button = Items.Find(FormOption.CommandName);
			Button.Visible = True;
			Button.Title = TableRow.Description;
			Items.Move(Button, Var_Group);
		Else
			LastIndex = LastIndex + 1;
			FormOption = FormOptions.Add();
			FillPropertyValues(FormOption, TableRow);
			FormOption.Found = True;
			FormOption.CommandName = "SelectOption_" + Format(LastIndex, "NZ=0; NG=");
			
			Command = Commands.Add(FormOption.CommandName);
			Command.Action = "Attachable_ImportReportOption";
			
			Button = Items.Add(FormOption.CommandName, Type("FormButton"), Var_Group);
			Button.Type = FormButtonType.CommandBarButton;
			Button.CommandName = FormOption.CommandName;
			Button.Title = TableRow.Description;
			
			ConstantCommands.Add(FormOption.CommandName);
		EndIf;
		Button.Check = (CurrentVariantKey = TableRow.VariantKey);
	EndDo;
	
	FoundItems = FormOptions.FindRows(New Structure("Found", False));
	For Each FormOption In FoundItems Do
		Button = Items.Find(FormOption.CommandName);
		Button.Visible = False;
	EndDo;
	
	FormOptions.Columns.Delete("Found");
	ValueToFormAttribute(FormOptions, "AddedOptions");
EndProcedure

&AtServer
Procedure SaveFormParameters()
	
	ParametersForm = ReportsOptions.StoredReportFormParameters(Parameters);
	ParametersForm.PurposeUseKey = PurposeUseKey;
	
EndProcedure

&AtServer
Procedure SetCurrentOptionKey(ReportFullName, ReportObject)
	PanelOptionsCurrentOptionKey = BlankOptionKey();
	
	Details = CommonClientServer.StructureProperty(Parameters, "Details");
	CurrentVariantKeyDetail = "";
	If TypeOf(Details) = Type("DataCompositionDetailsProcessDescription") Then
		Settings = GetFromTempStorage(Details.Data).Settings;
		CurrentVariantKeyDetail = CommonClientServer.StructureProperty(Settings.AdditionalProperties, "VariantKey", "");
	EndIf;
	
	If ValueIsFilled(CurrentVariantKeyDetail) Then
		CurrentVariantKey = CurrentVariantKeyDetail;
		If Not ValueIsFilled(PurposeUseKey) Then
			PurposeUseKey = "Details";
		EndIf;
	Else
		If ValueIsFilled(PurposeUseKey) Then 
			ObjectKey = ReportFullName + "/" + PurposeUseKey + "/CurrentVariantKey";
		Else
			ObjectKey = ReportFullName + "/CurrentVariantKey";
		EndIf;
		
		CurrentVariantKey = Common.SystemSettingsStorageLoad(ObjectKey, "");
	EndIf;
	
	If Not ValueIsFilled(CurrentVariantKey)
		Or (ValueIsFilled(Parameters.VariantKey) And CurrentVariantKey <> Parameters.VariantKey) Then 
		
		If ValueIsFilled(Parameters.VariantKey) Then 
			CurrentVariantKey = Parameters.VariantKey;
			
		ElsIf ReportObject.DataCompositionSchema <> Undefined Then
			For Each Variant In ReportObject.DataCompositionSchema.SettingVariants Do
				CurrentVariantKey = Variant.Name;
				Break;
			EndDo;
		EndIf;
		
	EndIf;
	
	// The key of the contextual options is saved, which is usually excluded from the interface,
	//  i.e. included is false (See Catalog.PredefinedReportsOptions.
// .
	//
	If ValueIsFilled(OptionContext) Then 
		ContextOption = ?(ValueIsFilled(Parameters.VariantKey), Parameters.VariantKey, CurrentVariantKey);
		ContextOptions.Add(ContextOption);
	EndIf;
	
	If ValueIsFilled(OptionContext)
		And ValueIsFilled(Parameters.VariantKey)
		And Parameters.VariantKey <> CurrentVariantKey Then 
		
		// Management is transferred to the platform -
		// the option key will be restored from the standard storage.
		Parameters.VariantKey = Undefined;
	EndIf;
EndProcedure

#EndRegion

#Region EventsSettings

&AtClientAtServerNoContext
Function BlankOptionKey()
	Return " - ";
EndFunction

&AtClientAtServerNoContext
Function ReportOptionSettingsKey(FullReportName, VariantKey)
	
	Return StringFunctionsClientServer.SubstituteParametersToString("%1/%2", FullReportName, VariantKey);
	
EndFunction

&AtServer
Procedure SaveDataInSettingsOnServer(Settings = Undefined)
	
	SettingsKey = ReportOptionSettingsKey(ReportSettings.FullName, CurrentVariantKey);
	SaveTheSelectedGroupingLevel(SettingsKey, SelectedGroupsLevel, DetailsMode);
	SaveTheStateOfTheOptionOutputSettingsHeaders(SettingsKey, OutputSettingsTitles, DetailsMode);
	
	If TypeOf(Settings) = Type("Map") Then
		Settings["SettingsFormAdvancedMode"] = ReportSettings.SettingsFormAdvancedMode;
	EndIf;
	
EndProcedure

#EndRegion

#Region GeneralBSPMethods

&AtServer
Procedure SetFixedFilters(FiltersStructure, DCSettings, ReportSettings)
	If TypeOf(DCSettings) <> Type("DataCompositionSettings")
		Or FiltersStructure = Undefined
		Or FiltersStructure.Count() = 0 Then
		Return;
	EndIf;
	DCParameters = DCSettings.DataParameters;
	DCFilters = DCSettings.Filter;
	Inaccessible = DataCompositionSettingsItemViewMode.Inaccessible;
	For Each KeyAndValue In FiltersStructure Do
		Name = KeyAndValue.Key;
		Value = KeyAndValue.Value;
		If TypeOf(Value) = Type("FixedArray") Then
			Value = New Array(Value);
		EndIf;
		If TypeOf(Value) = Type("Array") Then
			List = New ValueList;
			List.LoadValues(Value);
			Value = List;
		EndIf;
		DCParameter = DCParameters.FindParameterValue(New DataCompositionParameter(Name));
		If TypeOf(DCParameter) = Type("DataCompositionSettingsParameterValue") Then
			DCParameter.UserSettingID = "";
			DCParameter.Use    = True;
			DCParameter.ViewMode = Inaccessible;
			DCParameter.Value         = Value;
			Continue;
		EndIf;
		If TypeOf(Value) = Type("ValueList") Then
			DCComparisonType = DataCompositionComparisonType.InList;
		Else
			DCComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		CommonClientServer.SetFilterItem(DCFilters, Name, Value, DCComparisonType, , True, Inaccessible, "");
	EndDo;
EndProcedure

#EndRegion

#EndRegion
