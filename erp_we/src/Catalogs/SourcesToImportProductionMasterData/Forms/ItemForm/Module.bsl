
#Region Variables

&AtClient
Var LocationOfDataBeforeChange;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Parameters.Property("Mode", Mode);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Items.SwitchDisplayOfAttributes.Check = DisplayAllAttributes;
	
	ConfigureDependentFormElements(ThisObject, "DisplayAllAttributes");
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer(CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SaveSettingsOfCurrentUploadedData(CurrentObject);
	
	SaveSourceSettings(CurrentObject);
	
	CurrentObject.AdditionalProperties.Insert("DescriptionOfUploadedData", DescriptionOfUploadedData);
	
	If UseMonitoring <> GetFunctionalOption("UseMonitoringOfTheStateOfProductionMasterDataImport") Then
		WriteParameters.Insert("RefreshInterface");
		UseMonitoring = Not UseMonitoring;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If WriteParameters.Property("RefreshInterface") Then
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
	Notify("Record_DataSourcesOfProductionNSIDownload", Object.Ref);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetails();
	
	CustomizeFormElements();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SectionToBeProcessedOnChange(Item)
	
	SectionKey = Item.Name;
	
	If ThisObject[SectionKey] Then
		SectionsToBeProcessed.Insert(SectionKey);
	ElsIf SectionsToBeProcessed.Property(SectionKey) Then
		SectionsToBeProcessed.Delete(SectionKey);
	EndIf;
	
	SectionsToBeProcessedWhenChanged();
	
EndProcedure

&AtClient
Procedure ExchangeFormatOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "ExchangeFormat");
	
EndProcedure

&AtClient
Procedure LocationOfDataTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	LocationOfDataBeforeChange = LocationOfData;
	
EndProcedure

&AtClient
Procedure LocationOfDataOnChange(Item)
	
	Modified = True;
	
	UpdateRelocationDirectories(ActionsWithFiles, LocationOfDataBeforeChange, LocationOfData);
	
	ConfigureDependentFormElements(ThisObject, "ActionsWithFiles");
	
EndProcedure

&AtClient
Procedure LocationOfDataStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	ChoiceDialog.Multiselect = False;
	ChoiceDialog.Directory = LocationOfData;
	ChoiceDialog.Title = NStr("vi = 'Hãy chọn thư mục vị trí tệp có dữ liệu';
								|ru = 'Выберите каталог расположения файлов с данными';
								|en = 'Select a data file directory'; fa = 'Select a data file directory';
								|it = 'Выберите каталог расположения файлов с данными';
								|pl = 'Select a data file directory';
								|tr = 'Veri dosyalarının konum dizinini seçin'");
	CallbackDescription = New CallbackDescription("LocationOfDataStartChoiceCompletion", ThisObject);
	
	FileSystemClient.ShowSelectionDialog(CallbackDescription, ChoiceDialog);
	
EndProcedure

&AtClient
Procedure OptionForUpdatingObjectsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription(
		"EditOptionToUpdateObjectsEnd",
		ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("UpdatingObjects", UpdatingObjects);
	
	OpenForm("Catalog.SourcesToImportProductionMasterData.Form.FormUpdateExistingObjectVariant",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure HardwareLoadingOptionOnChange(Item)
	
	SectionsToBeProcessedWhenChanged();
	
EndProcedure

&AtClient
Procedure AutoimportIsUsedOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "Schedule");
	
EndProcedure

&AtClient
Procedure AlgorithmBeforeLoadingClick(Item)
	
	EditObjectProcessingAlgorithm(
		ProductDataManagementClientServer.NameOfEventBeforeLoadingObject());
	
EndProcedure

&AtClient
Procedure AlgorithmBeforeWriteClick(Item)
	
	EditObjectProcessingAlgorithm(
		ProductDataManagementClientServer.NameOfEventBeforeRecordingObject());
	
EndProcedure
&AtClient
Procedure ResolvingSearchConflictsClick(Item)
	
	EditConflictResolutionWhenSearching();
	
EndProcedure

&AtClient
Procedure ActionWithFilesPressing(Item)
	
	MatchingElements = MatchingStateOfFileActionElement(True);
	
	EditActionWithFiles(MatchingElements[Item.Name]);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDataToImport

&AtClient
Procedure DataToImportOnActivateRow(Item)
	
	CurrentData = Items.DataToImport.CurrentData;
	
	If CurrentData = Undefined
			Or CurrentData.KeyForDescriptionOfUploadedData= CurCurrentKeyForDescriptionOfUploadedData Then
		Return;
	EndIf;
	
	AttachIdleHandler("Attachable_DataToImportOnActivateRow", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingUpBankingDetails

&AtClient
Procedure SettingUpBankingDetailsMethodToSetValueOnChange(Item)
	
	CurrentData = Items.SettingUpBankingDetails.CurrentData;
	
	Value = ?(Not CurrentData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.DontUse")
					And TypeOf(CurrentData.Value) = Type("String"),
		CurrentData.Value,
		Undefined);
	CurrentData.Value = ConfigureParametersForSelectingValueByLine(ThisObject, CurrentData).AdjustValue(Value);
	
	CalculateActiveAttributeOfAttributeString(CurrentData);
	UpdateInformationAboutConfigurationErrors(ThisObject, CurCurrentKeyForDescriptionOfUploadedData);
	
	ConfigureDependentFormElements(ThisObject, "DisplayAllAttributes");
	
EndProcedure

&AtClient
Procedure SettingUpBankingDetailsMethodToSetValueClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SettingUpBankingDetailsMethodToSetValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	FillInListOfWaysToSetValueByLine(Items.SettingUpBankingDetails.CurrentData);
	
EndProcedure

&AtClient
Procedure SettingUpBankingDetailsValueOnChange(Item)
	
	UpdateInformationAboutConfigurationErrors(ThisObject, CurCurrentKeyForDescriptionOfUploadedData);
	
EndProcedure

&AtClient
Procedure SettingUpBankingDetailsBeforeRowChange(Item, Cancel)
	
	ConfigureParametersForSelectingValueByLine(ThisObject, Items.SettingUpBankingDetails.CurrentData);
	
EndProcedure

&AtClient
Procedure SettingUpBankingDetailsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.SettingUpBankingDetailsValueCalculationAlgorithm Then
		
		StandardProcessing = False;
		EditAlgorithmForSettingAttributeValue(RowSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingUpBankingDetailsFieldForSearchOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "DataToImport");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpSchedule(Command)
	
	Schedule = ?(AutoimportSchedule = Undefined,
		New JobSchedule(),
		AutoimportSchedule);
	
	CallbackDescription = New CallbackDescription("SetUpScheduleCompletion", ThisObject);
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	ScheduleDialog1.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SwitchDisplayOfAttributes(Command)
	
	DisplayAllAttributes = Not DisplayAllAttributes;
	
	Items.SwitchDisplayOfAttributes.Check = DisplayAllAttributes;
	
	ConfigureDependentFormElements(ThisObject, "DisplayAllAttributes");
	
EndProcedure

&AtClient
Procedure ResetUploadRulesSettings(Command)
	
	ShowQueryBox(New CallbackDescription("ResetUploadRulesSettingsCompletion", ThisObject),
		NStr("vi = 'Chú ý! Tất cả tùy chỉnh hiện tại của quy tắc kết nhập dữ liệu sẽ bị xóa. Tiếp tục?';
			|ru = 'Внимание! Все существующие настройки правил загрузки данных будут очищены. Продолжить?';
			|en = 'Important. All the current settings of data import rules will be cleared. Continue?'; fa = 'Important. All the current settings of data import rules will be cleared. Continue?';
			|it = 'Внимание! Все существующие настройки правил загрузки данных будут очищены. Продолжить?';
			|pl = 'Important. All the current settings of data import rules will be cleared. Continue?';
			|tr = 'Dikkat! Mevcut tüm veri yükleme kural ayarları temizlenecektir. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure CollapseUploadedData(Command)
	
	ConvolutionTypeTree(True);
	
EndProcedure

&AtClient
Procedure ExpandUploadedData(Command)
	
	ConvolutionTypeTree(False);
	
EndProcedure

&AtClient
Procedure MatchingObjects(Command)
	
	If Modified
		Or Not ValueIsFilled(Object.Ref) Then
		
		ShowQueryBox(New CallbackDescription("MatchingObjectsCompletion", ThisObject),
			NStr("vi = 'Để chuyển sang xem và chỉnh sửa các đối tượng so sánh, nguồn dữ liệu sẽ được ghi lại. Tiếp tục?';
				|ru = 'Для перехода к просмотру и редактированию сопоставленных объектов, источник данных будет записан. Продолжить?';
				|en = 'To view and edit mapped objects, the data source will be saved. Continue?'; fa = 'To view and edit mapped objects, the data source will be saved. Continue?';
				|it = 'Для перехода к просмотру и редактированию сопоставленных объектов, источник данных будет записан. Продолжить?';
				|pl = 'To view and edit mapped objects, the data source will be saved. Continue?';
				|tr = 'Eşleştirilen nesneleri görüntülemeye ve düzenlemeye geçmek için veri kaynağı kaydedilecektir. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
			
	Else
		
		OpenMatchingObjectsForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportStateMonitoring(Command)
	
	If Modified
		Or Not ValueIsFilled(Object.Ref) Then
		
		ShowQueryBox(
			New CallbackDescription("ImportStateMonitoringCompletion", ThisObject),
			NStr("vi = 'Để chuyển đến biểu mẫu màn hình theo dõi, nguồn dữ liệu sẽ được ghi lại. Tiếp tục?';
				|ru = 'Для перехода к форме мониторинга, источник данных будет записан. Продолжить?';
				|en = 'To go to the monitoring form, the data source will be saved. Continue?'; fa = 'To go to the monitoring form, the data source will be saved. Continue?';
				|it = 'Для перехода к форме мониторинга, источник данных будет записан. Продолжить?';
				|pl = 'To go to the monitoring form, the data source will be saved. Continue?';
				|tr = 'İzleme formuna geçmek için veri kaynağı kaydedilecektir. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
			
	Else
		
		OpenUploadStateMonitoringForm();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region SettingUpBankingDetails
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetails.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.DontUse;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetails.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.FieldForSearch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	#EndRegion
	
	#Region SettingUpBankingDetailsFieldForSearch
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsFieldForSearch.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DataToImport.SearchIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsFieldForSearch.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.SearchIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.DontUse;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MandatorySearch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region SettingUpBankingDetailsValue
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValue.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.ValueList(, "DontUse,CalculateByAlgorithm");
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValue.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.SetValueTo;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.IsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sẽ xóa giá trị>';
													|ru = '<значение будет очищено>';
													|en = '<the value will be cleared>'; fa = '<the value will be cleared>';
													|it = '<значение будет очищено>';
													|pl = '<the value will be cleared>';
													|tr = '<değer temizlenecektir>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.ValueList("DontUse,CalculateByAlgorithm");
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region SettingUpBankingDetailsValueCalculationAlgorithm
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValueCalculationAlgorithm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.ValueCalculationAlgorithm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", TextOfAlgorithmIsFilledIn());
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValueCalculationAlgorithm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.ValueCalculationAlgorithm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", TextOfAlgorithmIsNotFilledIn());
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SettingUpBankingDetailsValueCalculationAlgorithm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpBankingDetails.MethodToSetValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer(CurrentObject = Undefined)
	
	FillInSourceSettings(CurrentObject);
	
	FillInServiceDetails();
	
	FillInTreeOfUploadedData();
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	UseMonitoring = GetFunctionalOption("UseMonitoringOfTheStateOfProductionMasterDataImport");
	
	FillInDescriptionOfUploadedData();
	
EndProcedure

&AtServer
Procedure FillInDescriptionOfUploadedData()
	
	DescriptionOfUploadedData = ProductDataManagement.DescriptionOfUploadedData(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSourceSettings(CurrentObject)
	
	SourceSettings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettings(CurrentObject);
	FillPropertyValues(ThisObject, SourceSettings);
	
EndProcedure

&AtServer
Procedure SaveSourceSettings(CurrentObject)
	
	Settings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettingsConstructor(1);
	FillPropertyValues(Settings, ThisObject);
	Catalogs.SourcesToImportProductionMasterData.PutSettingsStructureInRepository(CurrentObject, Settings);
	
	Settings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettingsConstructor();
	FillPropertyValues(Settings, ThisObject);
	CurrentObject.AdditionalProperties.Insert("SourceSettings", Settings);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If Not IsBlankString(Mode) Then
		
		If Mode = "SettingBasicParameters" Then
			Items.GroupPages.CurrentPage = Items.GroupPageMain;
			Items.GroupPageSettingUpRules.Enabled = False;
		ElsIf Mode = "ConfiguringUploadRules" Then
			Items.GroupPages.CurrentPage = Items.GroupPageSettingUpRules;
			Items.GroupPageMain.Enabled = False;
		EndIf;
		
	EndIf;
	
	ConfigureElementsSectionsForProcessing();

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("SectionsToBeProcessed")
		Or Initialize Then
		
		Items.HardwareLoadingOptionGroup.Visible =
			Form.SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfProductionEquipmentSection());
		
	EndIf;
	
	If AttributesStructure1.Property("ExchangeFormat")
		Or Initialize Then
		
		Items.ExplanationExchangeFormat.Title = ExplanationOfExchangeFormat(Form, Object.ExchangeFormat);
		
	EndIf;
	
	If AttributesStructure1.Property("ActionsWithFiles")
		Or Initialize Then
		
		ConfigureActionElementsWithFiles(Form);
		
	EndIf;
	
	If AttributesStructure1.Property("Schedule")
		Or Initialize Then
			
		Items.AutoimportIsUsed.Enabled = ValueIsFilled(Object.Ref);
		Items.SetUpSchedule.Enabled = Form.AutoimportIsUsed;
		If Form.AutoimportSchedule <> Undefined Then
			Items.SetUpSchedule.Title = String(Form.AutoimportSchedule);
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("DisplayAllAttributes")
		Or Initialize Then
			
		If Form.DisplayAllAttributes Then
			RowFilter = New FixedStructure;
		Else
			RowFilter = New FixedStructure("Running", True);
		EndIf;
		Items.SettingUpBankingDetails.RowFilter = RowFilter;
		
	EndIf;
	
	If AttributesStructure1.Property("DataToImport")
		Or Initialize Then
		
		ConfigureElementsOfObjectProcessingAlgorithms(Form);
		
		ConfigureSearchConflictResolutionElement(Form);
		
	EndIf;
	
	If AttributesStructure1.Property("UpdatingObjects")
		Or Initialize Then
		
		ConfigureItemsUpdateObjects(Form);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureElementsOfObjectProcessingAlgorithms(Form)
	
	If Not ValueIsFilled(Form.CurCurrentKeyForDescriptionOfUploadedData) Then
		Form.Items.GroupSettingUpRulesAlgorithms.Visible = False;
		Return;
	EndIf;
	
	LongDesc = Form.DescriptionOfUploadedData[Form.CurCurrentKeyForDescriptionOfUploadedData]; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
	Form.Items.GroupSettingUpRulesAlgorithms.Visible = LongDesc.ObjectAlgorithmsAreAvailable;
	
	EventsStructure = New Structure;
	EventsStructure.Insert(ProductDataManagementClientServer.NameOfEventBeforeLoadingObject(), Form.Items.AlgorithmBeforeLoading.Name);
	EventsStructure.Insert(ProductDataManagementClientServer.NameOfEventBeforeRecordingObject(), Form.Items.AlgorithmBeforeWrite.Name);
	
	For Each KeyAndValue In EventsStructure Do
		AlgorithmKey = ProductDataManagementClientServer.KeyOfObjectProcessingAlgorithmWhenLoading(
			KeyAndValue.Key,
			LongDesc.MetadataObjectName,
			LongDesc.TSName);
		If Form.ObjectProcessingAlgorithms.Property(AlgorithmKey)
				And ValueIsFilled(Form.ObjectProcessingAlgorithms[AlgorithmKey]) Then
			Form.Items[KeyAndValue.Value].Title  = TextOfAlgorithmIsFilledIn();
			Form.Items[KeyAndValue.Value].TextColor = New Color();
		Else
			Form.Items[KeyAndValue.Value].Title  = TextOfAlgorithmIsNotFilledIn();
			Form.Items[KeyAndValue.Value].TextColor = WebColors.Gray;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureSearchConflictResolutionElement(Form)
	
	If Not ValueIsFilled(Form.CurCurrentKeyForDescriptionOfUploadedData) Then
		Form.Items.GroupResolvingSearchConflicts.Visible = False;
		Return;
	EndIf;
	
	LongDesc = Form.DescriptionOfUploadedData[Form.CurCurrentKeyForDescriptionOfUploadedData];
	Form.Items.GroupResolvingSearchConflicts.Visible = LongDesc.SearchIsAvailable;
	Form.Items.GroupResolvingSearchConflicts.Enabled = Form.SettingUpBankingDetails.FindRows(New Structure("FieldForSearch", True)).Count();
	
	Setting = Undefined;
	If Not Form.ResolvingSearchConflicts.Property(Form.CurCurrentKeyForDescriptionOfUploadedData, Setting) Then
		Setting = ProductDataManagementClientServer.DescriptionOfConflictResolutionSettingsForSearchConstructor();
	EndIf;
	
	If Setting.Rule = ProductDataManagementClientServer.RuleForResolvingConflictWhenSearchingLogError() Then
		RuleTitle = NStr("vi = 'Ghi nhận lỗi';
						|ru = 'Регистрировать ошибку';
						|en = 'Register an error'; fa = 'ثبت خطا';
						|it = 'Регистрировать ошибку';
						|pl = 'Register an error';
						|tr = 'Hatayı kaydet'");
		RuleColor = New Color();
	ElsIf Setting.Rule = ProductDataManagementClientServer.RuleForResolvingConflictsWhenSearchingSort() Then
		RuleTitle = StrTemplate(NStr("vi = 'Sắp xếp (%1)';
									|ru = 'Сортировать (%1)';
									|en = 'Sort (%1)'; fa = 'Sort (%1)';
									|it = 'Сортировать (%1)';
									|pl = 'Sort (%1)';
									|tr = 'Sırala (%1)'"), SortingView(LongDesc, Setting.SortingSettings));
		RuleColor = New Color();
	Else
		RuleTitle = NStr("vi = '<chưa đặt>';
						|ru = '<не задано>';
						|en = '<not set>'; fa = '<تنظیم نشده>';
						|it = '<non indicato>';
						|pl = '<nie określono>';
						|tr = '<belirtilmedi>'");
		RuleColor = WebColors.Gray;
	EndIf;
	
	Form.Items.ResolvingSearchConflicts.Title  = RuleTitle;
	Form.Items.ResolvingSearchConflicts.TextColor = RuleColor;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureActionElementsWithFiles(Form)
	
	LocationOfData = CommonClientServer.AddLastPathSeparator(Form.LocationOfData);
	MatchingElements = MatchingStateOfFileActionElement();
	
	For Each State In StrSplit("SuccessfullyCompleted,WasCompletedWithErrors,NotExecuted", ",") Do
		
		ActionElement = Form.Items[MatchingElements[State]];
		
		ActionDetails = Undefined;
		If Form.ActionsWithFiles.Property(State, ActionDetails) Then
			
			If ValueIsFilled(ActionDetails.Directory) Then
				If CommonClientServer.AddLastPathSeparator(ActionDetails.Directory) <> LocationOfData
						And StrFind(ActionDetails.Directory, LocationOfData) = 1 Then
					DirectoryPresentation = StrTemplate("...\%1", StrReplace(ActionDetails.Directory, LocationOfData, ""));
				Else
					DirectoryPresentation = ActionDetails.Directory;
				EndIf;
				ActionElement.Title = StrTemplate(NStr("vi = '%1 vào thư mục %2';
														|ru = '%1 в каталог %2';
														|en = '%1 to the %2 directory'; fa = '%1 to the %2 directory';
														|it = '%1 в каталог %2';
														|pl = '%1 to the %2 directory';
														|tr = '%2 dizinindeki %1'"), ActionDetails.Action, DirectoryPresentation);
			Else
				ActionElement.Title = ActionDetails.Action;
			EndIf;
			
			ActionElement.TextColor = New Color();
			
		Else
			
			ActionElement.Title  = NStr("vi = '<chưa xác định thao tác>';
										|ru = '<действие не задано>';
										|en = '<action is not specified>'; fa = '<action is not specified>';
										|it = '<действие не задано>';
										|pl = '<action is not specified>';
										|tr = '<eylem belirtilmedi>'");
			ActionElement.TextColor = WebColors.Gray;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConfigureElementsSectionsForProcessing()
	
	For Each KeyAndValue In SectionsToBeProcessed Do
		ThisObject[KeyAndValue.Key] = True;
	EndDo;
	
	ReplacementSectionKey = ProductDataManagementClientServer.KeyOfMaterialsReplacementSection();
	Items[ReplacementSectionKey].Enabled = GetFunctionalOption("UseAlternativeMaterials")
		Or SectionsToBeProcessed.Property(ReplacementSectionKey);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureItemsUpdateObjects(Form)
	
	Form.OptionForUpdatingObjects = Form.UpdatingObjects.UpdateOption;
	
EndProcedure

#Region BasicParametersPage

&AtClientAtServerNoContext
Function ExplanationOfExchangeFormat(Form, ExchangeFormat)
	
	RowsArray = New Array;
	
	If ValueIsFilled(ExchangeFormat) Then
		
		If ExchangeFormat = PredefinedValue("Enum.ImportMasterDataFormats.XLS") Then
			RowsArray.Add(
				NStr("vi = 'Tất cả các tệp được sắp xếp trong thư mục, được coi là dữ liệu để kết nhập và sẽ được xử lý theo trình tự sắp xếp theo bảng chữ cái.
				|Mỗi tệp cần có danh sách các tờ, với các tên gọi tiếp theo đối với mỗi dạng dữ liệu được kết nhập:';
				|ru = 'Все файлы, расположенные в каталоге, считаются данными для загрузки и будут обрабатываться в порядке сортировки по алфавиту.
				|Каждый файл должен содержать перечень листов, со следующими наименованиями для каждого типа загружаемых данных:';
				|en = 'All the files in the directory are considered data to import. They will be processed in an alphabetical order.
				|Each file must contain a list of sheets with the following names for each type of data to import:'; fa = 'All the files in the directory are considered data to import. They will be processed in an alphabetical order.
				|Each file must contain a list of sheets with the following names for each type of data to import:';
				|it = 'Все файлы, расположенные в каталоге, считаются данными для загрузки и будут обрабатываться в порядке сортировки по алфавиту.
				|Каждый файл должен содержать перечень листов, со следующими наименованиями для каждого типа загружаемых данных:';
				|pl = 'All the files in the directory are considered data to import. They will be processed in an alphabetical order.
				|Each file must contain a list of sheets with the following names for each type of data to import:';
				|tr = 'Dizinde bulunan tüm dosyalar indirme verileri olarak kabul edilir ve alfabetik sıraya göre işlenecektir.
				|Her dosya, yüklenen her veri türü için aşağıdaki tanımları içeren bir sayfa listesi içermelidir:'"));
			Extension = "";
		Else
			RowsArray.Add(
				NStr("vi = 'Các tệp của mỗi dạng dữ liệu kết nhập sẽ được xử lý theo trình tự liệt kê dưới đây và cần có định dạng tiếp theo của tên gọi:';
					|ru = 'Файлы каждого типа загружаемых данных будут обрабатываться в перечисленном ниже порядке и должны иметь следующий формат наименований:';
					|en = 'Files of each type of data to import will be processed in the order listed below. They must have the following name format:'; fa = 'Files of each type of data to import will be processed in the order listed below. They must have the following name format:';
					|it = 'Файлы каждого типа загружаемых данных будут обрабатываться в перечисленном ниже порядке и должны иметь следующий формат наименований:';
					|pl = 'Files of each type of data to import will be processed in the order listed below. They must have the following name format:';
					|tr = 'Yüklenen her veri türüne ait dosyalar aşağıda listelenen sırayla işlenecektir ve aşağıdaki tanım biçimine sahip olmalıdır:'"));
			Extension = StrTemplate("*.%1", Lower(ExchangeFormat));
		EndIf;
		
		IndexOf = 1;
		For Each SectionKey In ProductDataManagementClientServer.OrderOfProcessingSections() Do
			If Not Form.SectionsToBeProcessed.Property(SectionKey) Then
				Continue;
			EndIf;
			If SectionKey = ProductDataManagementClientServer.KeyOfProductsAndMaterialsSection() Then
				Explanation = NStr("vi = 'đối với sản phẩm và nguyên vật liệu';
									|ru = 'для изделий и материалов';
									|en = 'for finished products and materials'; fa = 'for finished products and materials';
									|it = 'для изделий и материалов';
									|pl = 'for finished products and materials';
									|tr = 'nihai ürünler ve malzemeler için'");
			ElsIf SectionKey = ProductDataManagementClientServer.KeyOfProductionEquipmentSection() Then
				Explanation = NStr("vi = 'đối với thiết bị';
									|ru = 'для оборудования';
									|en = 'for equipment'; fa = 'for equipment';
									|it = 'для оборудования';
									|pl = 'for equipment';
									|tr = 'ekipman için'");
			ElsIf SectionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection() Then
				Explanation = NStr("vi = 'đối với thành phần sản phẩm';
									|ru = 'для составов изделий';
									|en = 'for compositions of finished products'; fa = 'for compositions of finished products';
									|it = 'для составов изделий';
									|pl = 'for compositions of finished products';
									|tr = 'nihai ürün içeriği için'");
			ElsIf SectionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection() Then
				Explanation = NStr("vi = 'đối với công nghệ sản xuất';
									|ru = 'для технологии производства';
									|en = 'for manufacturing technology'; fa = 'for manufacturing technology';
									|it = 'для технологии производства';
									|pl = 'for manufacturing technology';
									|tr = 'üretim teknolojisi için'");
			ElsIf SectionKey = ProductDataManagementClientServer.KeyOfMaterialsReplacementSection() Then
				Explanation = NStr("vi = 'để thay thế nguyên vật liệu';
									|ru = 'для замен материалов';
									|en = 'for material replacements'; fa = 'for material replacements';
									|it = 'для замен материалов';
									|pl = 'for material replacements';
									|tr = 'malzeme değişimi için'");
			EndIf;
			RowsArray.Add(StrTemplate("%1 - %2%3 - %4;", IndexOf, SectionKey, Extension, Explanation));
			IndexOf = IndexOf + 1;
		EndDo;
		
	Else
		
		RowsArray.Add(NStr("vi = '<cần chọn định dạng trao đổi dữ liệu>';
							|ru = '<необходимо выбрать формат обмена данными>';
							|en = '<select a data exchange format>'; fa = '<select a data exchange format>';
							|it = '<необходимо выбрать формат обмена данными>';
							|pl = '<select a data exchange format>';
							|tr = '<veri değişimi formatının seçilmesi gerekmektedir>'"));
		
	EndIf;
	
	Return StrConcat(RowsArray, Chars.LF);
	
EndFunction

&AtClient
Procedure LocationOfDataStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		UpdateRelocationDirectories(ActionsWithFiles, LocationOfData, Result[0]);
		LocationOfData = Result[0];
		Modified = True;
		ConfigureDependentFormElements(ThisObject, "ActionsWithFiles");
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpScheduleCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AutoimportSchedule = Result;
		Modified = True;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Schedule");
	
EndProcedure

&AtClient
Procedure SectionsToBeProcessedWhenChanged()
	
	SectionsToBeProcessedWhenChangedOnServer();
	
	ConvolutionTypeTree(False);
	
EndProcedure

&AtServer
Procedure SectionsToBeProcessedWhenChangedOnServer()
	
	SaveSettingsOfCurrentUploadedData(Object);
	
	FillInDescriptionOfUploadedData();
	
	FillInTreeOfUploadedData();
	
	CurCurrentKeyForDescriptionOfUploadedData = "";
	
	ConfigureDependentFormElements(ThisObject, "SectionsToBeProcessed,ExchangeFormat");
	
EndProcedure

&AtClient
Procedure EditActionWithFiles(State_Description)
	
	NotificationParameters = New Structure;
	
	CallbackDescription = New CallbackDescription(
		"EditActionWithFilesCompletion",
		ThisObject,
		NotificationParameters);
		
	ActionDetails = Undefined;
	If Not ActionsWithFiles.Property(State_Description, ActionDetails) Then
		ActionDetails = ProductDataManagementClientServer.DescriptionOfActionWithConstructorFiles(State_Description);
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("ActionDetails",   ActionDetails);
	FormParameters.Insert("LocationOfData", LocationOfData);
	
	OpenForm("Catalog.SourcesToImportProductionMasterData.Form.ActionWithFilesAfterImport",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure EditActionWithFilesCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		State_Description = Result.State_Description;
		
		If Result.Action = PredefinedValue("Enum.ImportMasterDataActionsWithFiles.NotDefined") Then
			If ActionsWithFiles.Property(State_Description) Then
				ActionsWithFiles.Delete(State_Description);
			EndIf;
		Else
			ActionsWithFiles.Insert(State_Description, Result);
		EndIf;
		
		Modified = True;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ActionsWithFiles");
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateRelocationDirectories(ActionsWithFiles, LocationOfDataBeforeChange, LocationOfData)
	
	If IsBlankString(LocationOfData) Then
		Return;
	EndIf;
	
	LocationTo    = CommonClientServer.AddLastPathSeparator(LocationOfDataBeforeChange);
	LocationAfter = CommonClientServer.AddLastPathSeparator(LocationOfData);
	
	If LocationOfDataBeforeChange = LocationOfData Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ActionsWithFiles Do
		
		ActionDetails = KeyAndValue.Value;
		If ActionDetails.Action <> PredefinedValue("Enum.ImportMasterDataActionsWithFiles.MoveTo") Then
			Continue;
		EndIf;
		
		ActionCatalog = CommonClientServer.AddLastPathSeparator(ActionDetails.Directory);
		If ActionCatalog = LocationTo Then
			ActionDetails.Directory = LocationOfData;
		ElsIf StrFind(ActionCatalog, LocationTo) = 1 Then
			ActionDetails.Directory = StrReplace(ActionDetails.Directory, LocationTo, LocationAfter);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure EditOptionToUpdateObjectsEnd(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		UpdatingObjects = Result;
		
		Modified = True;
		
		ConfigureDependentFormElements(ThisObject, "UpdatingObjects");
		
	EndIf;
		
EndProcedure

#EndRegion

#Region PageConfiguringUploadRules

&AtClient
Procedure Attachable_DataToImportOnActivateRow()
	
	DownloadedDataWhenLineIsActivatedOnServer();
	
EndProcedure

&AtServer
Procedure DownloadedDataWhenLineIsActivatedOnServer()
	
	SaveSettingsOfCurrentUploadedData(Object);
	
	FillINAttributesOfUploadedData();
	
	ConfigureDependentFormElements(ThisObject, "DataToImport");
	
EndProcedure

&AtClient
Procedure ConvolutionTypeTree(GroupBy = True, Val RowsCollection = Undefined)
	
	If RowsCollection = Undefined Then
		RowsCollection = DataToImport;
	EndIf;
	
	For Each TreeRow In RowsCollection.GetItems() Do
		If GroupBy Then
			ConvolutionTypeTree(GroupBy, TreeRow);
			Items.DataToImport.Collapse(TreeRow.GetID());
		Else
			Items.DataToImport.Expand(TreeRow.GetID(), True);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Function AddRowToTreeOfUploadedData(MetadataObjectName, TSName = "", TreeRows = Undefined)
	
	KeyForDescriptionOfUploadedData = ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement(MetadataObjectName, TSName);
	
	LongDesc = DescriptionOfUploadedData[KeyForDescriptionOfUploadedData]; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
	
	If TreeRows = Undefined Then
		TreeRows = DataToImport.GetItems();
	EndIf;
	
	NewRow = TreeRows.Add();
	NewRow.KeyForDescriptionOfUploadedData = KeyForDescriptionOfUploadedData;
	NewRow.SearchIsAvailable = LongDesc.SearchIsAvailable;
	NewRow.Presentation = LongDesc.Presentation;
	
	NewRow.ImageDataType = ?(
			IsBlankString(LongDesc.TSName),
			PictureLib[StrSplit(LongDesc.FullName,".")[0]],
			PictureLib.NestedTable);
	
	Return NewRow;
	
EndFunction

&AtServer
Procedure FillInTreeOfUploadedData()
	
	DataToImport.GetItems().Clear();
	
	If SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfProductsAndMaterialsSection()) Then
		AddRowToTreeOfUploadedData("Products");
	EndIf;
	
	If SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfProductionEquipmentSection()) Then
		AddRowToTreeOfUploadedData(XMLString(HardwareLoadingOption));
	EndIf;
	
	If SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfProductCompositionsSection()) Then
		TreeRows = AddRowToTreeOfUploadedData("BillsOfMaterials").GetItems();
		AddRowToTreeOfUploadedData("BillsOfMaterials", "MaterialsAndServices", TreeRows);
	EndIf;
	
	If SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfProductionTechnologySection()) Then
		AddRowToTreeOfUploadedData("BillsOfMaterials", "LaborCosts", TreeRows);
		TreeRows = AddRowToTreeOfUploadedData("ProductionStages",, TreeRows).GetItems();
		AddRowToTreeOfUploadedData("ManufacturingOperations",, TreeRows);
		AddRowToTreeOfUploadedData("EmployeeWorkKinds");
	EndIf;
	
	If SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfMaterialsReplacementSection()) Then
		TreeRows = AddRowToTreeOfUploadedData("EngineeringChangeOrder").GetItems();
		AddRowToTreeOfUploadedData("EngineeringChangeOrder", "UsedMaterials", TreeRows);
	EndIf;
	
	UpdateInformationAboutConfigurationErrors(ThisObject);
	
EndProcedure

&AtClient
Procedure ResetUploadRulesSettingsCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
	
		ResetSettingsForDataUploadRules();
		FillINAttributesOfUploadedData();
		UpdateInformationAboutConfigurationErrors(ThisObject);
		
		ConfigureDependentFormElements(ThisObject);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateInformationAboutConfigurationErrors(Form, KeyForDescriptionOfUploadedData = "", TreeRows = Undefined)
	
	If TreeRows = Undefined Then
		TreeRows = Form.DataToImport.GetItems();
	EndIf;
	
	For Each String In TreeRows Do
		
		UpdateInformationAboutConfigurationErrors(Form, KeyForDescriptionOfUploadedData, String.GetItems());
		
		If ValueIsFilled(KeyForDescriptionOfUploadedData)
				And String.KeyForDescriptionOfUploadedData <> KeyForDescriptionOfUploadedData Then
			Continue;
		EndIf;
		
		HasErrors = False;
		
		RequiredAttributes = New Array;
		If String.KeyForDescriptionOfUploadedData = Form.CurCurrentKeyForDescriptionOfUploadedData Then
			TableRows = Form.SettingUpBankingDetails;
		Else
			LongDesc = Form.DescriptionOfUploadedData[String.KeyForDescriptionOfUploadedData];
			TableRows = Form.Object.AttributesDetails1.FindRows(LongDesc.FilterStructure1);
			For Each Item In LongDesc.RequiredAttributes Do
				RequiredAttributes.Add(Item);
			EndDo;
		EndIf;
		
		For Each TableRow In TableRows Do
			IndexOf = RequiredAttributes.Find(TableRow.AttributeName);
			If IndexOf <> Undefined Then
				RequiredAttributes.Delete(IndexOf);
			EndIf;
			If TableRow.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.DontUse") Then
				Continue;
			ElsIf TableRow.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm")
				And Not ValueIsFilled(TableRow.ValueCalculationAlgorithm) Then
				HasErrors = True;
				Break;
			ElsIf Not TableRow.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm")
				And Not TableRow.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.SetValueTo")
				And Not ValueIsFilled(TableRow.Value) Then
				HasErrors = True;
				Break;
			EndIf;
		EndDo;
		
		If RequiredAttributes.Count() > 0 Then
			HasErrors = True;
		EndIf;
		
		String.HasErrors = HasErrors;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure EditConflictResolutionWhenSearching()
	
	NotificationParameters = New Structure;
	
	CallbackDescription = New CallbackDescription(
		"EditConflictResolutionWhenSearchingCompletion",
		ThisObject,
		NotificationParameters);
		
	LongDesc = DescriptionOfUploadedData[CurCurrentKeyForDescriptionOfUploadedData];
		
	FormCaption = StrTemplate(NStr("vi = 'Cho phép xung đột khi tìm kiếm trong danh mục ""%1""';
									|ru = 'Разрешение конфликтов при поиске в справочнике ""%1""';
									|en = 'Resolve conflicts during the search in the %1 catalog'; fa = 'Resolve conflicts during the search in the %1 catalog';
									|it = 'Разрешение конфликтов при поиске в справочнике ""%1""';
									|pl = 'Resolve conflicts during the search in the %1 catalog';
									|tr = '""%1"" kataloğunda arama yaparken çakışma çözümü'"),
		LongDesc.Presentation);
	
	FormParameters = New Structure;
	FormParameters.Insert("Title", FormCaption);
	FormParameters.Insert("DescriptionOfUploadedDataElement", LongDesc);
	If ResolvingSearchConflicts.Property(CurCurrentKeyForDescriptionOfUploadedData) Then
		FormParameters.Insert("ConfiguringSearchConflictResolution", ResolvingSearchConflicts[CurCurrentKeyForDescriptionOfUploadedData]);
	EndIf;
	
	OpenForm("Catalog.SourcesToImportProductionMasterData.Form.FormResolveConflictsDuringSearch",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure EditConflictResolutionWhenSearchingCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		Setting = Undefined;
		If Result.Property("ConfiguringSearchConflictResolution", Setting) Then
			ResolvingSearchConflicts.Insert(CurCurrentKeyForDescriptionOfUploadedData, Setting);
		Else
			ResolvingSearchConflicts.Delete(CurCurrentKeyForDescriptionOfUploadedData);
		EndIf;
		
		ConfigureSearchConflictResolutionElement(ThisObject);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function SortingView(DescriptionOfUploadedDataElement, SortingSettings)
	
	If SortingSettings.UBound() = -1 Then
		Return NStr("vi = 'chưa đặt sắp xếp';
					|ru = 'сортировка не задана';
					|en = 'sort is not set'; fa = 'sort is not set';
					|it = 'сортировка не задана';
					|pl = 'sort is not set';
					|tr = 'sıralama belirtilmedi'");
	EndIf;
	
	PresentationsArray   = New Array;
	MaximumPresentations = 3;
	
	For Each SortingElement In SortingSettings Do // See ProductDataManagementClientServer.DescriptionOfSortingElementConstructor
		Presentation = TrimAll(SortingElement.AttributeName);
		For Each AttributeGroup In ProductDataManagementClientServer.GroupsOfAttributesForItemHeader() Do
			For Each KeyAndValue In DescriptionOfUploadedDataElement[AttributeGroup] Do
				If SortingElement.AttributeName = KeyAndValue.Key Then
					Presentation = TrimAll(KeyAndValue.Value.Presentation);
					Break;
				EndIf;
			EndDo;
		EndDo;
		PresentationsArray.Add(?(SortingElement.Direction = "Asc", Presentation, StrTemplate(NStr("vi = '%1 Giảm';
																									|ru = '%1 Убыв';
																									|en = '%1 Desc'; fa = '%1 Desc';
																									|it = '%1 Убыв';
																									|pl = '%1 Desc';
																									|tr = '%1 Azalan'"), Presentation)));
		If PresentationsArray.Count() = MaximumPresentations Then
			Break;
		EndIf;
	EndDo;
	
	Result = StrConcat(PresentationsArray, "; ");
	If SortingSettings.Count() > MaximumPresentations Then
		Result = StrTemplate(NStr("vi = '%1...(+ hơn nữa %2)';
									|ru = '%1...(+ еще %2)';
									|en = '%1...(+ %2 more)'; fa = '%1...(+ %2 more)';
									|it = '%1...(+ еще %2)';
									|pl = '%1...(+ %2 more)';
									|tr = '%1...(+ %2 daha)'"), Result, SortingSettings.Count() - MaximumPresentations);
	EndIf;
	
	Return Result;
	
EndFunction

#Region WorkingWITHAlgorithms

&AtClient
Procedure EditObjectProcessingAlgorithm(EventName)
	
	LongDesc = DescriptionOfUploadedData[CurCurrentKeyForDescriptionOfUploadedData];
	
	AlgorithmKey = ProductDataManagementClientServer.KeyOfObjectProcessingAlgorithmWhenLoading(
		EventName,
		LongDesc.MetadataObjectName,
		LongDesc.TSName);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("MetadataObject", LongDesc.MetadataObject);
	FilterParameters.Insert("ConnectionKey", ProductDataManagementClientServer.CommunicationKeyOfTypeOfObjectProcessingAlgorithm(EventName));
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("AlgorithmKey", AlgorithmKey);
	NotificationParameters.Insert("FilterParameters", FilterParameters);
	
	CallbackDescription = New CallbackDescription(
		"EditObjectProcessingAlgorithmCompletion",
		ThisObject,
		NotificationParameters);
		
	FormCaption = StrTemplate(NStr("vi = 'Thuật toán ""%1"" của danh mục ""%2""';
									|ru = 'Алгоритм ""%1"" справочника ""%2""';
									|en = 'The %1 algorithm of the %2 catalog'; fa = 'The %1 algorithm of the %2 catalog';
									|it = 'Алгоритм ""%1"" справочника ""%2""';
									|pl = 'The %1 algorithm of the %2 catalog';
									|tr = '""%2"" kataloğunun ""%1"" algoritması'"),
		ProductDataManagementClientServer.PresentationOfTypeOfObjectProcessingAlgorithm(EventName),
		LongDesc.Presentation);
	
	FormParameters = New Structure;
	FormParameters.Insert("Title", FormCaption);
	If ObjectProcessingAlgorithms.Property(AlgorithmKey) Then
		FormParameters.Insert("AlgorithmText", ObjectProcessingAlgorithms[AlgorithmKey]);
		FormParameters.Insert("AlgorithmParameters", GetAlgorithmParameters(ThisObject, FilterParameters));
	EndIf;
	
	OpenForm("Catalog.SourcesToImportProductionMasterData.Form.AlgorithmEditingForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure EditObjectProcessingAlgorithmCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		AlgorithmKey = AdditionalParameters.AlgorithmKey;
		
		If ValueIsFilled(Result.AlgorithmText) Then
			ObjectProcessingAlgorithms.Insert(AlgorithmKey, Result.AlgorithmText);
		Else
			ObjectProcessingAlgorithms.Delete(AlgorithmKey);
		EndIf;
		
		SaveAlgorithmParameters(ThisObject, AdditionalParameters.FilterParameters, Result.AlgorithmParameters);
		
		UpdateInformationAboutConfigurationErrors(ThisObject, CurCurrentKeyForDescriptionOfUploadedData);
		
		ConfigureElementsOfObjectProcessingAlgorithms(ThisObject);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditAlgorithmForSettingAttributeValue(RowID)
	
	RowData = SettingUpBankingDetails.FindByID(RowID);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ConnectionKey", RowData.ConnectionKey);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FilterParameters", FilterParameters);
	
	CallbackDescription = New CallbackDescription(
		"EditAlgorithmForSettingAttributeValueCompletion",
		ThisObject,
		NotificationParameters);
	
	FormCaption = StrTemplate(NStr("vi = 'Thuật toán tính giá trị mục tin ""%1""';
									|ru = 'Алгоритм расчета значения реквизита ""%1""';
									|en = 'An algorithm to calculate a value of the %1 attribute'; fa = 'An algorithm to calculate a value of the %1 attribute';
									|it = 'Алгоритм расчета значения реквизита ""%1""';
									|pl = 'An algorithm to calculate a value of the %1 attribute';
									|tr = '""%1"" özniteliğinin değer hesaplama algoritması'"), RowData.Presentation);
	
	FormParameters = New Structure;
	FormParameters.Insert("AlgorithmText", RowData.ValueCalculationAlgorithm);
	FormParameters.Insert("AlgorithmParameters", GetAlgorithmParameters(ThisObject, FilterParameters));
	FormParameters.Insert("Title", FormCaption);
	
	OpenForm("Catalog.SourcesToImportProductionMasterData.Form.AlgorithmEditingForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure EditAlgorithmForSettingAttributeValueCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		Items.SettingUpBankingDetails.CurrentData.ValueCalculationAlgorithm = Result.AlgorithmText;
		
		SaveAlgorithmParameters(ThisObject, AdditionalParameters.FilterParameters, Result.AlgorithmParameters);
		
		UpdateInformationAboutConfigurationErrors(ThisObject, CurCurrentKeyForDescriptionOfUploadedData);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GetAlgorithmParameters(Form, FilterParameters)
	
	ParametersArray = New Array;
	Table = Form.Object.AlgorithmsParameters;
	
	FoundRows = Table.FindRows(FilterParameters);
	For Each FoundRow In FoundRows Do
		ParametersArray.Add(New Structure("ParameterName,Value", FoundRow.ParameterName, FoundRow.Value));
	EndDo;
	
	Return ParametersArray;
	
EndFunction

&AtClientAtServerNoContext
Procedure SaveAlgorithmParameters(Form, FilterParameters, ParametersArray)
	
	Table = Form.Object.AlgorithmsParameters;
	
	FoundRows = Table.FindRows(FilterParameters);
	For Each FoundRow In FoundRows Do
		Table.Delete(FoundRow);
	EndDo;
	
	For Each Parameter In ParametersArray Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Parameter);
		FillPropertyValues(NewRow, FilterParameters);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function TextOfAlgorithmIsFilledIn()
	Return NStr("vi = '<đã đặt thuật toán>';
				|ru = '<алгоритм установлен>';
				|en = '<algorithm is set>'; fa = '<algorithm is set>';
				|it = '<алгоритм установлен>';
				|pl = '<algorithm is set>';
				|tr = '<algoritma yapılandırıldı>'");
EndFunction

&AtClientAtServerNoContext
Function TextOfAlgorithmIsNotFilledIn()
	Return NStr("vi = '<chưa đặt thuật toán>';
				|ru = '<алгоритм не установлен>';
				|en = '<algorithm is not set>'; fa = '<algorithm is not set>';
				|it = '<алгоритм не установлен>';
				|pl = '<algorithm is not set>';
				|tr = '<algoritma yapılandırılmadı>'");
EndFunction

#EndRegion

#Region WorkingWithAttributes

// Saves THE SETTING OF THE Attributes OF THE Cur TYPE OF uploaded data
// 
// Parameters:
//  CurrentObject - FormDataStructure, CatalogObject.SourcesToImportProductionMasterData - Current object
&AtServer
Procedure SaveSettingsOfCurrentUploadedData(CurrentObject)
	
	If Not ValueIsFilled(CurCurrentKeyForDescriptionOfUploadedData) Then
		Return;
	EndIf;
	
	LongDesc = DescriptionOfUploadedData[CurCurrentKeyForDescriptionOfUploadedData];
	
	For Each String In CurrentObject.AttributesDetails1.FindRows(LongDesc.FilterStructure1) Do
		CurrentObject.AttributesDetails1.Delete(String);
	EndDo;
	
	For Each String In SettingUpBankingDetails Do
		If String.MethodToSetValue = Enums.ImportMasterDataMethodsToSetAttributeValue.DontUse
				Or String.MethodToSetValue.IsEmpty() Then
			Continue;
		EndIf;
		NewRow = CurrentObject.AttributesDetails1.Add();
		FillPropertyValues(NewRow, String);
		NewRow.MetadataObject = LongDesc.MetadataObject;
		NewRow.TSName            = LongDesc.TSName;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillINAttributesOfUploadedData()
	
	SettingUpBankingDetails.Clear();
	
	CurrentData = DataToImport.FindByID(Items.DataToImport.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurCurrentKeyForDescriptionOfUploadedData = CurrentData.KeyForDescriptionOfUploadedData;
	LongDesc = DescriptionOfUploadedData[CurCurrentKeyForDescriptionOfUploadedData];
	
	SavedSettings = Object.AttributesDetails1.Unload(LongDesc.FilterStructure1);
	SavedSettings.Indexes.Add("AttributeName");
	
	AttributesTable = SettingUpBankingDetails.Unload();
	AttributesTable.Columns.Add("Order", New TypeDescription("Number"));
	
	For Each GroupOfAttribute In ProductDataManagementClientServer.AttributesGroups() Do
		For Each KeyAndValue In LongDesc[GroupOfAttribute] Do
			AttributeDetails = KeyAndValue.Value; // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
			NewRow = AttributesTable.Add();
			NewRow.AttributeName      = AttributeDetails.Name;
			NewRow.Presentation     = AttributeDetails.Presentation;
			NewRow.GroupOfAttribute   = GroupOfAttribute;
			NewRow.IsRequired      = AttributeDetails.IsRequired;
			NewRow.SearchIsAvailable     = SearchByAttributesISAVAILABLE(GroupOfAttribute);
			SavedSetting = SavedSettings.Find(KeyAndValue.Key, "AttributeName");
			If SavedSetting <> Undefined Then
				FillPropertyValues(NewRow, SavedSetting);
			Else
				Catalogs.SourcesToImportProductionMasterData.InitializeNewRowInAttributesTable(
					NewRow, AttributeDetails.IsRequired);
			EndIf;
			If AttributeDetails.MandatorySearch Then
				NewRow.FieldForSearch = True;
				NewRow.MandatorySearch = True;
			EndIf;
			SetOrderOfAttributeRow(NewRow);
			CalculateActiveAttributeOfAttributeString(NewRow);
			SetImageOfAttributeString(AttributeDetails, NewRow);
		EndDo;
	EndDo;
	
	AttributesTable.Sort("Order,Presentation");
	SettingUpBankingDetails.Load(AttributesTable);
	
EndProcedure

&AtServer
Procedure ResetSettingsForDataUploadRules()
	
	Object.AttributesDetails1.Clear();
	
	ObjectProcessingAlgorithms = New Structure;
	
EndProcedure

&AtServer
Procedure SetImageOfAttributeString(AttributeDetails, RowData)
	
	PictureIndex = 1;
	
	If RowData.GroupOfAttribute = "AttributesIds" Then
		PictureIndex = ?(RowData.IsRequired, 6, 7);
	ElsIf RowData.GroupOfAttribute = "AttributesStandard" Then
		PictureIndex = ?(RowData.IsRequired, 5, 2);
	ElsIf RowData.GroupOfAttribute = "AttributesApplication" Then
		PictureIndex = ?(RowData.IsRequired, 5, 2);
	ElsIf RowData.GroupOfAttribute = "ServiceDetails" Then
		PictureIndex = ?(RowData.IsRequired, 5, 2);
	ElsIf RowData.GroupOfAttribute = "AdditionalDetails_" Then
		PictureIndex = ?(AttributeDetails.PropertyDetails.PropertyIsAdditionalInformation, 4, 3);
	EndIf;
	
	RowData.PictureIndex = PictureIndex;
	
EndProcedure

&AtServer
Procedure SetOrderOfAttributeRow(RowData)
	
	If RowData.GroupOfAttribute = "AttributesIds" Then
		AdditionalOrdering = 0;
	ElsIf RowData.GroupOfAttribute = "AdditionalDetails_" Then
		AdditionalOrdering = 2;
	Else
		AdditionalOrdering = 1;
	EndIf;
	
	RowData.Order = 100 * ?(RowData.IsRequired, 0, 1) + 10 * AdditionalOrdering;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateActiveAttributeOfAttributeString(RowData)
	
	RowData.Running = ValueIsFilled(RowData.MethodToSetValue)
		And RowData.MethodToSetValue <> PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.DontUse");
	
EndProcedure

&AtClientAtServerNoContext
Function SearchByAttributesISAVAILABLE(GroupOfAttribute)
	
	Return GroupOfAttribute = "AttributesStandard"
				Or GroupOfAttribute = "AttributesApplication";
	
EndFunction

// Description OF THE Attribute by line.
// 
// Parameters:
//  Form - ClientApplicationForm
//  RowData - FormDataCollectionItem
// 
// Returns:
//  Structure - See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
//
&AtClientAtServerNoContext
Function DescriptionOfAttributeByLine(Form, RowData)
	
	AttributeDetails = Undefined;
	
	If Not IsBlankString(Form.CurCurrentKeyForDescriptionOfUploadedData) Then
		LongDesc          = Form.DescriptionOfUploadedData[Form.CurCurrentKeyForDescriptionOfUploadedData];
		AttributeDetails = LongDesc[RowData.GroupOfAttribute][RowData.AttributeName];
	EndIf;
	
	Return AttributeDetails;
	
EndFunction

&AtClient
Procedure FillInListOfWaysToSetValueByLine(RowData)
	
	ChoiceList = Items.SettingUpBankingDetailsMethodToSetValue.ChoiceList;
	ChoiceList.Clear();
	
	AttributeDetails = DescriptionOfAttributeByLine(ThisObject, RowData);
	If AttributeDetails <> Undefined Then
	
		If Not RowData.IsRequired Then
			ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.DontUse"));
		EndIf;
		
		ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.GetFromFile"));
		If RowData.GroupOfAttribute <> "AttributesIds" Then
			ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.SetValueTo"));
			ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm"));
		EndIf;
		
		If AttributeDetails.HasCode Then
			ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.FindByCode"));
		EndIf;
		If AttributeDetails.HasDescription Then
			ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.FindByDescription"));
		EndIf;
		If AttributeDetails.HasNumber Then
			ChoiceList.Add(PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.FindByNumber"));
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ConfigureParametersForSelectingValueByLine(Form, RowData)
	
	ValueType = Undefined;
	
	AttributeDetails = DescriptionOfAttributeByLine(Form, RowData); // See ProductDataManagement.DescriptionOfAttributesOfUploadedDataConstructor
	If AttributeDetails <> Undefined Then
	
		If RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.GetFromFile")
				Or RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.CalculateByAlgorithm")
				Or RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.FindByCode")
				Or RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.FindByDescription")
				Or RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.FindByNumber") Then
			
			ValueType = New TypeDescription("String");
			
		ElsIf RowData.MethodToSetValue = PredefinedValue("Enum.ImportMasterDataMethodsToSetAttributeValue.SetValueTo") Then
			
			ValueType = AttributeDetails.Type;
			
		Else
			
			ValueType = New TypeDescription();
			
		EndIf;
		
		If AttributeDetails.ReferentialType Then
			Form.Items.SettingUpBankingDetailsValue.ChoiceFoldersAndItems = AttributeDetails.ChoiceFoldersAndItems;
			Form.Items.SettingUpBankingDetailsValue.ChoiceParameters      = AttributeDetails.ChoiceParameters;
		EndIf;
		
		Form.Items.SettingUpBankingDetailsValue.TypeRestriction = ValueType;
		
	EndIf;
	
	Return ValueType;
	
EndFunction

#EndRegion

#EndRegion

#Region Other

&AtClient
Procedure MatchingObjectsCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Write();
		OpenMatchingObjectsForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenMatchingObjectsForm()
	
	OpenForm("DataProcessor.ImportProductionMasterData.Form.MatchingObjects",
		New Structure("DataSource", Object.Ref),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure ImportStateMonitoringCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Write();
		OpenUploadStateMonitoringForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenUploadStateMonitoringForm()
	
	OpenForm("DataProcessor.ImportProductionMasterData.Form.ImportStateMonitoring",
		New Structure("DataSource", Object.Ref),
		ThisObject,
		UUID);
	
EndProcedure

&AtClientAtServerNoContext
Function MatchingStateOfFileActionElement(Reverse_1 = False)
	
	Result = New Structure;
	
	Result.Insert("SuccessfullyCompleted",   "SceneryAction_CompletedSuccessfully");
	Result.Insert("WasCompletedWithErrors", "SceneryAction_CompletedWithErrors");
	Result.Insert("NotExecuted",        "SceneryAction_NotCompleted");
	
	If Reverse_1 Then
		For Each KeyAndValue In Result Do
			Result.Insert(KeyAndValue.Value, KeyAndValue.Key);
			Result.Delete(KeyAndValue.Key);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
