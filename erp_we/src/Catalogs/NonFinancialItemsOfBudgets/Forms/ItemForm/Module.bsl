
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Items.ByCompanies.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.ByBusinessUnits.Visible = GetFunctionalOption("UseBusinessUnits");
	
	UnitOfMeasureIsDeterminedByDimension = Object.UnitOfMeasureIsDeterminedByDimension;
	CurrencyIsDeterminedByDimension = Object.CurrencyIsDeterminedByDimension;
	ImportFromOtherSubsystems = Object.ImportFromOtherSubsystems;
	SetAValueForEachPeriod = Object.SetAValueForEachPeriod;
	
	Attributes = Common.ObjectAttributesValues(Object.Ref, "StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	StorageOfDataCompositionSettings = PutToTempStorage(?(Attributes.StorageOfDataCompositionSettings
		= Undefined, Undefined, Attributes.StorageOfDataCompositionSettings), UUID);
	StorageOfDataCompositionSchema = PutToTempStorage(?(Attributes.StorageOfDataCompositionSchema
		= Undefined, Undefined, Attributes.StorageOfDataCompositionSchema), UUID);
	
	FillInListOfDataLayoutSchemes();
	
	InitializeSettingsComposer();
	FillInAnalyticsSettings();
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormControl();
	CustomizeNavigationAndActionBar();
	
	SetSubperiods();
	
	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.StorageOfDataCompositionSettings = Undefined;
	CurrentObject.StorageOfDataCompositionSchema    = Undefined;
	
	If IsTempStorageURL(StorageOfDataCompositionSettings) Then
		CurrentObject.StorageOfDataCompositionSettings = GetFromTempStorage(StorageOfDataCompositionSettings);
	EndIf;
	If IsTempStorageURL(StorageOfDataCompositionSchema) Then
		CurrentObject.StorageOfDataCompositionSchema    = GetFromTempStorage(StorageOfDataCompositionSchema);
	EndIf;
	
	BudgetingServer.PutAnalyticsFillingSettingsInRule(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormControl();
	CustomizeNavigationAndActionBar();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_NonFinancialItemsOfBudgets", Object.Description, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BudgetingServer.ProcessingVerificationOfAnalyticsFillingSettings(DimensionPopulationSettings, Cancel, Object.AdvancedModeOfDimensionFillSetting);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DefineTheUnitOfMeasurementWhenChanging(Item)
	
	Object.UnitOfMeasureIsDeterminedByDimension = UnitOfMeasureIsDeterminedByDimension;
	FormControl();
	
EndProcedure

&AtClient
Procedure ByScenariosOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure ByPeriodsOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure DimensionKindOnChange(Item)
	
	TypeOfAnalyticsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure IndicatorKindOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure DataCompositionSchemaOnChange(Item)
	
	InitializeSettingsComposer();
	
EndProcedure

&AtClient
Procedure ImportFromOtherSubsystemsOnChange(Item)
	
	ImportFromOtherSubsystemsOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyIsDeterminedByDimensionOnChange(Item)
	
	Object.CurrencyIsDeterminedByDimension = CurrencyIsDeterminedByDimension;
	FormControl();
	
EndProcedure

&AtClient
Procedure ValidUntilANewOneIsInstalledOnChange(Item)
	
	Object.SetAValueForEachPeriod = SetAValueForEachPeriod;
	FormControl();
	
EndProcedure

&AtClient
Procedure SetForEachPeriodOnChange(Item)
	
	Object.SetAValueForEachPeriod = SetAValueForEachPeriod;
	FormControl();
	
EndProcedure

&AtClient
Procedure PeriodFrequencyOnChange(Item)
	
	SetSubperiods();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDimensionPopulationSettings

&AtClient
Procedure AnalyticsFillInSettingsAnalyticsFillInExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.DimensionPopulationSettings.CurrentData;
	DataSourceSection = PredefinedValue("Enum.SectionsOfBudgetingDataSources.CustomQuery");
	
	FormParameters = New Structure;
	FormParameters.Insert("DimensionKind",               CurrentData.DimensionKind);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("DataSourceSection",      DataSourceSection);
	FormParameters.Insert("CurrentExpression",           CurrentData.DimensionPopulationExpression);
	
	OpenForm("CommonForm.SelectDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure AnalyticsFillInSettingsAnalyticsFillInExpressionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.DimensionPopulationSettings.CurrentData;
	CurrentData.DimensionPopulationExpression = ValueSelected;
	
	ExpressionFillingAnalyticsSelectionProcessingServer(CurrentData.GetID());
	Modified = True;
	Items.DimensionPopulationSettings.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure AnalyticsFillInSettingsAnalyticsFillInExpressionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DimensionPopulationSettingsOnActivateRow(Item)
	
	ParametersForSelectingAnalyticsValue = New Array;
	
	CurrentData = Items.DimensionPopulationSettings.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.AdditionalProperty) Then
		NewChoiceParameter = New ChoiceParameter("Filter.Owner", CurrentData.AdditionalProperty);
		ParametersForSelectingAnalyticsValue.Add(NewChoiceParameter);
	EndIf;
	
	Items.DimensionPopulationSettingsDimensionValue.ChoiceParameters = New FixedArray(ParametersForSelectingAnalyticsValue);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpDataReceiptScheme(Command)
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Thiết lập lược đồ thành phần dữ liệu cho số liệu phi tài chính ""%1""';
													|ru = 'Настройка схемы компоновки данных для нефинансового показателя ""%1""';
													|en = 'Set up data composition schema for the ""%1"" non-financial item'; fa = 'Set up data composition schema for the ""%1"" non-financial item';
													|it = 'Impostazione dello schema di composizione dei dati per gli indicatori non finanziari ""%1""';
													|pl = 'Ustawienia schematu układu danych dla wskaźnika niefinansowego ""%1""';
													|tr = '""%1"" finansal olmayan öğesi için veri inşa edilme şeması ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", Object.Description);
	
	Addresses = BudgetingServerCall.GetAddressesOfDataLayoutSchemeInTemporaryStorage(
				Object.DataCompositionSchema, StorageOfDataCompositionSchema, 
				StorageOfDataCompositionSettings, UUID);
				
	CallbackDescription = New CallbackDescription("WhenYouFinishConfiguringDataLayoutScheme", ThisObject, Addresses);
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("NotEditDataCompositionSchema", False);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", False);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureSettings", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema", 
		FormParameters, 
		ThisObject, 
		, 
		, 
		, 
		CallbackDescription, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInTheAnalyticsSettingsBasedOnTheSourceData(Command)
	
	FillInTheAnalyticsSettingsBasedOnTheSourceDataServer();
	
EndProcedure

&AtClient
Procedure EnableAdvancedSetupModeOfDimensionPopulation(Command)
	
	EnableAdvancedConfigurationModeForFillingInAnalyticsServer();
	
EndProcedure

&AtClient
Procedure DisableAdvancedSetupModeOfDimensionPopulation(Command)
	
	DisableAdvancedSetupModeOfDimensionPopulationServer();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	BudgetingServer.SetConditionalSettingsForFillingInAnalytics(ConditionalAppearance, "DimensionPopulationSettings");
	
EndProcedure

&AtServer
Procedure InitializeSettingsComposer() 
	
	If ValueIsFilled(Object.DataCompositionSchema) Then
		DataCompositionSchema = 
			Catalogs.NonFinancialItemsOfBudgets.PredefinedDataAcquisitionScheme(Object.DataCompositionSchema);
	ElsIf IsTempStorageURL(StorageOfDataCompositionSchema) Then
		ValueStorage = GetFromTempStorage(StorageOfDataCompositionSchema);
		If TypeOf(ValueStorage) = Type("ValueStorage") Then
			DataCompositionSchema = ValueStorage.Get();
		EndIf;
	EndIf;
	
	If DataCompositionSchema = Undefined Then
		DataCompositionSchema = DataCompositionServer.EmptyCircuit();
		DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema);
		DataSet.Query = 
			"SELECT
			|*";
	EndIf;
	
	Rule = New Structure;
	Rule.Insert("DataSourceSection", Enums.SectionsOfBudgetingDataSources.CustomQuery);
	Rule.Insert("CachingOfRuleResults", False);
	BudgetingServer.SetFieldPropertiesForRuleSettings(DataCompositionSchema, Rule);
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, True);
	
EndProcedure

&AtServer
Procedure FillInListOfDataLayoutSchemes()

	// Filling in the list of data layout schemes
	For Each Template In Metadata.FindByType(TypeOf(Object.Ref)).Templates Do
		If Template.TemplateType = Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			If Template.Name = "ItemsPrices2_5" Then
				
				Continue;
				
			EndIf;
			
			Items.DataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
			
		EndIf;
	EndDo;
	
	PresentationOfArbitraryCircuit = NStr("vi = 'Tùy ý';
											|ru = 'Произвольный';
											|en = 'Arbitrary'; fa = 'دلخواه';
											|it = 'Libero';
											|pl = 'Dowolny';
											|tr = 'İsteğe bağlı'");
	Items.DataCompositionSchema .ChoiceList.Add("", PresentationOfArbitraryCircuit);
	
EndProcedure

&AtServer
Procedure FormControl()
	
	ChoiceList = Items.ImportFromOtherSubsystems.ChoiceList;
	If Object.ByScenarios Then
		ChoiceList[0].Presentation = NStr("vi = 'Dữ liệu theo kế hoạch và thực tế được thiết lập bởi tài liệu và được lưu trữ trong hệ thống con ""Ngân sách""';
											|ru = 'Плановые и фактические данные устанавливаются документом и хранятся в подсистеме ""Бюджетирование и планирование""';
											|en = 'Planned and actual data is set by the document and stored in the ""Budgeting and Planning"" subsystem'; fa = 'Planned and actual data is set by the document and stored in the ""Budgeting and Planning"" subsystem';
											|it = 'I dati pianificati e reali sono impostati dal documento e memorizzati nel sottosistema ""Budgeting e pianificazione""';
											|pl = 'Dane planowe i faktyczne są ustawiane przy pomocy dokumentu i przechowywane w podsystemie ""Budżetowanie i planowanie""';
											|tr = 'Planlanan ve gerçek veriler belgede ayarlanır ve ""Bütçelendirme ve planlama"" alt sisteminde kaydedilir'");
		ChoiceList[1].Presentation = NStr("vi = 'Dữ liệu theo kế hoạch được thiết lập bởi tài liệu, dữ liệu thực tế được tải xuống từ các hệ thống con khác';
											|ru = 'Плановые данные устанавливаются документом, фактические загружаются из других подсистем';
											|en = 'Planned data is set by the document, actual data is imported from other subsystems'; fa = 'داده‌های برنامه‌ریزی‌شده توسط سند تعیین شده و داده‌های واقعی از سایر زیرسیستم‌ها وارد می‌شوند';
											|it = 'I dati pianificati sono impostati dal documento, i dati effettivi vengono caricati da altri sottosistemi.';
											|pl = 'Dane planowe są ustawiane przy pomocy dokumentu, dane faktyczne są pobierane z innych podsystemów';
											|tr = 'Veri planları belgede ayarlanır ve bilgileri diğer alt sistemlerden indirilir'");
	Else
		ChoiceList[0].Presentation = NStr("vi = 'Các giá trị được thiết lập bởi chứng từ.';
											|ru = 'Значения устанавливаются документом';
											|en = 'Values are set by document'; fa = 'Values are set by document';
											|it = 'I valori vengono impostati dal documento';
											|pl = 'Wartości są ustawiane przy pomocy dokumentu';
											|tr = 'Değerler belge tarafından ayarlanır'");
		ChoiceList[1].Presentation = NStr("vi = 'Các giá trị được tải từ các hệ thống con khác';
											|ru = 'Значения загружаются из других подсистем';
											|en = 'Values are imported from other subsystems'; fa = 'Values are imported from other subsystems';
											|it = 'I valori vengono caricati da altri sottosistemi';
											|pl = 'Wartości są pobierane z innych podsystemów';
											|tr = 'Değerler diğer alt sistemlerden yüklenir'");
	EndIf;
	
	Items.ActualDataGroup.Visible = Object.ImportFromOtherSubsystems;
	
	If Object.ByScenarios
		And Object.ImportFromOtherSubsystems Then
		Items.ReceiveSettingsGroup.Title = NStr("vi = 'Dữ liệu thực tế';
												|ru = 'Фактические данные';
												|en = 'Actual data'; fa = 'داده‌های واقعی';
												|it = 'Dati effettivi';
												|pl = 'Dane faktyczne';
												|tr = 'Gerçek veriler'");
	Else 
		Items.ReceiveSettingsGroup.Title = NStr("vi = 'Lấy dữ liệu từ các hệ thống con khác';
												|ru = 'Получение данных из других подсистем';
												|en = 'Receive data from other subsystems'; fa = 'Receive data from other subsystems';
												|it = 'Acquisizione dei dati da altri sottosistemi';
												|pl = 'Pobieranie danych z innych podsystemów';
												|tr = 'Diğer alt sistemlerden veri alımı'");
	EndIf;
	
	Items.Periodicity.Visible = Not Object.ByPeriods;
	If Items.DimensionKind1.Enabled Then
		Items.Periodicity.Enabled = SetAValueForEachPeriod;
	EndIf;
	
	If Object.IndicatorKind = Enums.NonFinancialItemKinds.Cash_ Then
		Items.IndicatorKindPages.CurrentPage = Items.CurrencyAttributesGroup;
	ElsIf Object.IndicatorKind = Enums.NonFinancialItemKinds.Quantitative Then
		Items.IndicatorKindPages.CurrentPage = Items.GroupQuantityFlags;
	Else
		Items.IndicatorKindPages.CurrentPage = Items.ZoomRatio;
	EndIf;
	
	OnlyViewAccountingAttributes = Items.DimensionKind1.ReadOnly;
	Items.UnitOfMeasure.ReadOnly 						= OnlyViewAccountingAttributes;
	Items.DimensionUnitsOfMeasurement.ReadOnly 				= OnlyViewAccountingAttributes;
	Items.DimensionCurrencies.ReadOnly 						= OnlyViewAccountingAttributes;
	Items.PeriodFrequency.ReadOnly 					= OnlyViewAccountingAttributes;
	Items.SubperiodFrequency.ReadOnly 				= OnlyViewAccountingAttributes;
	Items.CurrencyIsDeterminedByDimension.ReadOnly 			= OnlyViewAccountingAttributes;
	Items.CurrencyIsSpecifiedInTheData.ReadOnly 				= OnlyViewAccountingAttributes;
	Items.SpecifiedUnitOfMeasure.ReadOnly 				= OnlyViewAccountingAttributes;
	Items.UnitOfMeasureIsDeterminedByDimension.ReadOnly 	= OnlyViewAccountingAttributes;
	
	Items.UnitOfMeasure.Enabled = Not UnitOfMeasureIsDeterminedByDimension;
	Items.DimensionUnitsOfMeasurement.Enabled = UnitOfMeasureIsDeterminedByDimension;
	Items.DimensionCurrencies.Enabled = CurrencyIsDeterminedByDimension;
	Items.PeriodFrequency.Enabled = Object.ByPeriods;
	Items.SubperiodFrequency.Enabled = Object.ByPeriods;
	
	Items.ValidUntilANewOneIsInstalled.ReadOnly = Items.DimensionKind1.ReadOnly;
	Items.SetForEachPeriod.ReadOnly = Items.DimensionKind1.ReadOnly;
	Items.ImportFromOtherSubsystems.ReadOnly = Items.DimensionKind1.ReadOnly;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	Array = New Array;
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		Array.Add(Object["DimensionKind" + Cnt]);
	EndDo;
	
	AnalyticsSelectionOptions = Items.DimensionUnitsOfMeasurement.ChoiceParameters;
	ChoiceArray = New Array(AnalyticsSelectionOptions);
	ChoiceArray[1] = 
		New ChoiceParameter("Filter.Ref", New FixedArray(Array));
	Items.DimensionUnitsOfMeasurement.ChoiceParameters = New FixedArray(ChoiceArray);
	
	AnalyticsSelectionOptions = Items.DimensionCurrencies.ChoiceParameters;
	ChoiceArray = New Array(AnalyticsSelectionOptions);
	ChoiceArray[1] = 
		New ChoiceParameter("Filter.Ref", New FixedArray(Array));
	Items.DimensionCurrencies.ChoiceParameters = New FixedArray(ChoiceArray);
	
	Items.GroupSettingUpFillingInAnalytics.Visible = Object.ImportFromOtherSubsystems;
	
	Items.EnableAdvancedConfigurationModeForFillingInAnalytics.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	Items.GroupSetUpDimensionPopulationExplanation.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	
	Items.DisableAdvancedSetupModeOfDimensionPopulation.Visible = Object.AdvancedModeOfDimensionFillSetting;
	Items.DimensionPopulationSettings.Visible = Object.AdvancedModeOfDimensionFillSetting;
	
EndProcedure

&AtClient
Procedure WhenYouFinishConfiguringDataLayoutScheme(AddressInTempStorage, Addresses) Export
	
	If ValueIsFilled(AddressInTempStorage) Then
		ApplyResultOfDataLayoutSchemaConfigurationServer(AddressInTempStorage, Addresses);
	EndIf;
	
EndProcedure

&AtServer
Procedure ApplyResultOfDataLayoutSchemaConfigurationServer(AddressInTempStorage, Addresses)
	
	ReflectionResult = 
			BudgetingServerCall.ApplyChangesToDataLayoutScheme(
			Object.DataCompositionSchema, 
			Addresses.DataCompositionSchema, 
			AddressInTempStorage, 
			True);
	
	Object.DataCompositionSchema = ReflectionResult.DataCompositionSchema;
	StorageOfDataCompositionSchema = ReflectionResult.StorageOfDataCompositionSchema;
	StorageOfDataCompositionSettings = ReflectionResult.StorageOfDataCompositionSettings;
	InitializeSettingsComposer();
	Modified = True;
	
EndProcedure

&AtServer
Procedure SetRelatedParameters()
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	Array = New Array;
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		Array.Add(Object["DimensionKind" + Cnt]);
	EndDo;
	
	If Array.Find(Object.DimensionCurrencies) = Undefined Then
		Object.DimensionCurrencies = Undefined;
	EndIf;
	
	If Array.Find(Object.DimensionUnitsOfMeasurement) = Undefined Then
		Object.DimensionUnitsOfMeasurement = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure TypeOfAnalyticsWhenChangingOnServer()
	
	FormControl();
	SetRelatedParameters();
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtServer
Procedure SetSubperiods()
	
	Periodicity_ = Enums.Periodicity.OrderedPeriodicities();
	IndexOf = Periodicity_.Find(Object.Periodicity);
	Items.SubperiodFrequency.ChoiceList.Clear();
	
	For Cnt = 0 To IndexOf - 1 Do
		If Not ValueIsFilled(Periodicity_[Cnt]) Then
			Continue;
		EndIf;
		Items.SubperiodFrequency.ChoiceList.Add(Periodicity_[Cnt]);
	EndDo;
	
	SubperiodIndex = Periodicity_.Find(Object.SubperiodFrequency);
	If SubperiodIndex >= IndexOf And IndexOf > 0 Then
		Object.SubperiodFrequency = Periodicity_[IndexOf - 1];
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportFromOtherSubsystemsOnChangeServer()
	
	Object.ImportFromOtherSubsystems = ImportFromOtherSubsystems;
	If Not ImportFromOtherSubsystems Then
		Object.AdvancedModeOfDimensionFillSetting = False;
		FillInAnalyticsSettings();
	EndIf;
	FormControl();
	
EndProcedure

&AtServer
Procedure FillInAnalyticsSettings()
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	DimensionKinds = New Structure;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		DimensionKinds.Insert("DimensionKind" + DimensionNumber, Object["DimensionKind" + DimensionNumber]);
	EndDo;
	BudgetingServer.FillInSettingsForFillingInAnalyticsByRule(ThisObject, Object, DimensionKinds);
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure EnableAdvancedConfigurationModeForFillingInAnalyticsServer()
	
	Object.AdvancedModeOfDimensionFillSetting = True;
	FillInAnalyticsSettings();
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject, "DimensionPopulationSettings");
	FormControl();
	
EndProcedure

&AtServer
Procedure DisableAdvancedSetupModeOfDimensionPopulationServer()
	
	Object.AdvancedModeOfDimensionFillSetting = False;
	FillInAnalyticsSettings();
	FormControl();
	
EndProcedure

&AtServer
Procedure FillInTheAnalyticsSettingsBasedOnTheSourceDataServer()
	
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject, "DimensionPopulationSettings");
	
EndProcedure

&AtServer
Procedure ExpressionFillingAnalyticsSelectionProcessingServer(RowID) 
	
	BudgetingServer.CheckAnalyticsFillExpressionAfterSelection(ThisObject, RowID, "DimensionPopulationSettings");
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	FormControl();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure CustomizeNavigationAndActionBar()

	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseSetNonFinancialBudgetBalanceItem", Not Object.ImportFromOtherSubsystems);
	
	TMCommonUse.ConfigureFormByParameters(ThisObject, SettingsStructure);

EndProcedure

#EndRegion