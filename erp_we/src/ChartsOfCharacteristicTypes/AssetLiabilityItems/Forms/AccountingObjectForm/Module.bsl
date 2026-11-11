
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ReadOnly = True;
	
	SetConditionalAppearance();
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	InitializeFormAttributeValues();
	
	ManagingVisibilityOfFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Indicators.Count() = 1 Then
		CreatePresentationsOfIndicatorResources(Indicators[0].Factor);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// StandardSubsystems.Properties 

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIndicators

&AtClient
Procedure IndicatorsOnActivateRow(Item)
	
	CurrentData = Items.Indicators.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CreatePresentationsOfIndicatorResources(CurrentData.Factor);
	
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		FullFormName = "ChartOfCharacteristicTypes.AssetLiabilityItems.Form.AttributeUnlocking";
		FormParameters = New Structure();
		FormParameters.Insert("ThisIsObjectOfFinancialAccounting", True);
		CallbackDescription = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject);
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
		OpenForm(FullFormName, FormParameters,,,,, CallbackDescription, WindowOpeningMode);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
	EndIf;

EndProcedure

&AtClient
Procedure OpenSettingsObjects(Command)
	
	FullFormName = Object.SettingObjectSource + "." + "ListForm";
	FormParameters = New Structure();
	FormParameters.Insert("FixedSettings", ComposerForSettingsOfConfigurationObjects.Settings);
	
	OpenForm(FullFormName, FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenDetailedSettingsObjects(Command)
	
	FullFormName = Object.DetailedSettingsSource + "." + "ListForm";
	
	OpenForm(FullFormName,, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageSettingsSelectionPresentation.Name);
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("UsageSettingsComposer.Settings.Filter.LeftValue");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("UsageSettingsComposer.Settings.Filter.ComparisonType");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("UsageSettingsComposer.Settings.Filter.GroupType");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tùy chọn chức năng';
													|ru = 'Функциональные опции';
													|en = 'Functional options'; fa = 'گزینه‌های کاربردی';
													|it = 'Функциональные опции';
													|pl = 'Opcje funkcjonalne';
													|tr = 'İşlevsel opsiyonlar'"));
	
	//
	
EndProcedure

&AtServer
Procedure InitializeFormAttributeValues()
	
	ValuesStorages = Common.ObjectAttributesValues(Object.Ref,
		"Filterdata_,SelectingConfigurationObjects,FunctionalOptionLinks");
	
	If ValueIsFilled(Object.DataSource) Then
		SourceMetadata = Metadata.AccumulationRegisters[Object.DataSource];
		DataSourcePresentation = SourceMetadata.Synonym;
		
		ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithDataSource(
			DataSourceSettingsComposer, Object.DataSource,, UUID);
		
		DataSelectionSettings = ValuesStorages.Filterdata_.Get();
		If TypeOf(DataSelectionSettings) = Type("DataCompositionSettings") Then
			DataSourceSettingsComposer.LoadSettings(DataSelectionSettings);
		EndIf;
		
		Items.GroupDataSelection.Title = FilterPresentation(DataSourceSettingsComposer);
		
		FillInResourceTable("ManResources", SourceMetadata);
		FillInResourceTable("LocalResources", SourceMetadata);
		FillInResourceTable("ShaftResources", SourceMetadata);
		FillInResourceTable("ResourcesQuantity", SourceMetadata);
		
		CurrencyAccounting = DetermineUseOfAccounting("ShaftResources");
		QuantitativeAccounting = DetermineUseOfAccounting("ResourcesQuantity");
		
		Items.ManResourcesGroup.Title = PresentationOfResources("ManResources");
		Items.LocalResourcesGroup.Title = PresentationOfResources("LocalResources");
		
		If CurrencyAccounting Then
			Items.GroupResourcesVal.Title = PresentationOfResources("ShaftResources");
		EndIf;
		
		If QuantitativeAccounting Then
			Items.GroupResourcesQuantity.Title = PresentationOfResources("ResourcesQuantity");
		EndIf;
		
		For Each ExtDimensionPathString In Object.PathsToExtdimensionData Do
			ExtDimensionSelectionField = New DataCompositionField(ExtDimensionPathString.DataPath);
			AvailableSelectionField = DataSourceSettingsComposer.Settings.SelectionAvailableFields.FindField(ExtDimensionSelectionField);
			If AvailableSelectionField <> Undefined Then
				ExtDimensionPathString.FieldPresentation = AvailableSelectionField.Title;
			EndIf;
		EndDo;
		
		FillInTablesOfIndicators(SourceMetadata);
		
		If Indicators.Count() = 1 Then
			HeadlineOfMetricsGroup = NStr("vi = 'Chỉ tiêu';
											|ru = 'Показатель';
											|en = 'Indicator'; fa = 'شاخص';
											|it = 'Indicator';
											|pl = 'Indicator';
											|tr = 'Gösterge'");
		Else
			HeadlineOfMetricsGroup = NStr("vi = 'Chỉ tiêu';
											|ru = 'Показатели';
											|en = 'Indicators'; fa = 'شاخص‌ها';
											|it = 'Indicators';
											|pl = 'Indicators';
											|tr = 'Göstergeler'");
		EndIf;
		
		Items.GroupIndicators.Title = HeadlineOfMetricsGroup;
		
	Else
		DataSourcePresentation = NStr("vi = 'Dạng sử dụng dữ liệu của các dạng tương ứng';
										|ru = 'Статья использует данные корреспондирующих статей';
										|en = 'The item uses data of corresponding items'; fa = 'The item uses data of corresponding items';
										|it = 'Статья использует данные корреспондирующих статей';
										|pl = 'The item uses data of corresponding items';
										|tr = 'Kalem, karşılık gelen kalemlerin verilerini kullanır.'");
	EndIf;
	
	If Object.FunctionalOptions.Count() > 0 Then
		ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithFunctionalOptions(
			UsageSettingsComposer, Object.FunctionalOptions, UUID);
		
		Usage_Settings = ValuesStorages.FunctionalOptionLinks.Get();
		If TypeOf(Usage_Settings) = Type("DataCompositionSettings") Then
			UsageSettingsComposer.LoadSettings(Usage_Settings);
		EndIf;
		
		ArticleIsUsed = ChartsOfCharacteristicTypes.AssetLiabilityItems.UsingArticleOnFunctionalOptions(
			Object, UsageSettingsComposer);
		
		If ArticleIsUsed Then
			PresentationOfUsageRestrictions = NStr("vi = 'Dạng được sử dụng theo tùy chỉnh kế toán';
													|ru = 'Статья используется согласно настроек учета';
													|en = 'The item is used according to the accounting settings'; fa = 'The item is used according to the accounting settings';
													|it = 'Статья используется согласно настроек учета';
													|pl = 'The item is used according to the accounting settings';
													|tr = 'Kalem, muhasebe ayarlarına göre kullanılır.'");
		Else
			PresentationOfUsageRestrictions = NStr("vi = 'Dạng không được sử dụng theo tùy chỉnh kế toán';
													|ru = 'Статья не используется согласно настроек учета';
													|en = 'The item is not used according to the accounting settings'; fa = 'The item is not used according to the accounting settings';
													|it = 'Статья не используется согласно настроек учета';
													|pl = 'The item is not used according to the accounting settings';
													|tr = 'Kalem, muhasebe ayarlarına göre kullanılmaz.'");
		EndIf;
	Else
		PresentationOfUsageRestrictions = NStr("vi = 'Dạng luôn được sử dụng';
												|ru = 'Статья используется всегда';
												|en = 'The item is always used'; fa = 'The item is always used';
												|it = 'Статья используется всегда';
												|pl = 'The item is always used';
												|tr = 'Kalem her zaman kullanılır'");
	EndIf;
	
	If ValueIsFilled(Object.SettingObjectSource) Then
		MetadataOfConfigurationObject = Metadata.FindByFullName(Object.SettingObjectSource);
		PresentationOfCustomizationObjects = MetadataOfConfigurationObject.Synonym;
		
		ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithSettingsObject(
			ComposerForSettingsOfConfigurationObjects, Object.SettingObjectSource,
			MetadataOfConfigurationObject, UUID);
		
		ObjectSelectionSettingsSettings = ValuesStorages.SelectingConfigurationObjects.Get();
		If TypeOf(ObjectSelectionSettingsSettings) = Type("DataCompositionSettings") Then
			ComposerForSettingsOfConfigurationObjects.LoadSettings(ObjectSelectionSettingsSettings);
		EndIf;
		
		Items.GroupSelectionOfObjectsSettings.Title = FilterPresentation(ComposerForSettingsOfConfigurationObjects);
	Else
		PresentationOfCustomizationObjects = NStr("vi = 'Cài đặt phản ánh dữ liệu được thực hiện cho toàn bộ dạng';
													|ru = 'Настройка отражения данных выполняется для статьи в целом';
													|en = 'Data recording is configured for each item'; fa = 'Data recording is configured for each item';
													|it = 'Настройка отражения данных выполняется для статьи в целом';
													|pl = 'Data recording is configured for each item';
													|tr = 'Veri kaydı her bir kalem için yapılandırılır'");
	EndIf;
	
	If ValueIsFilled(Object.DetailedSettingsSource) Then
		MetadataOfDetailedSettings = Metadata.FindByFullName(Object.DetailedSettingsSource);
		PresentationOfDetailedSettings = MetadataOfDetailedSettings.Synonym;
	EndIf;
	
EndProcedure

&AtServer
Procedure ManagingVisibilityOfFormElements()
	
	If ValueIsFilled(Object.LongDesc) Then
		Items.LongDesc.Visible = True;
	Else
		Items.LongDesc.Visible = False;
	EndIf;
	
	Items.SectionsSettingsPage.Visible = False;
	Items.ExtDimensionPageIsFilledIn.Visible = False;
	Items.BudgetingMetricsPage.Visible = False;
	
	If GetFunctionalOption("SettingOfPostingByAccountingObjects") = True Then
		Items.SectionsSettingsPage.Visible = True;
	EndIf;
	
	If ValueIsFilled(Object.DataSource) Then
		Items.DataSourcePresentation.Type = FormFieldType.InputField;
		Items.DataSourcePresentation.TitleLocation = FormItemTitleLocation.Left;
		
		Items.AvailableDataSourceFieldsGroup.Visible = True;
		Items.GroupDataSelection.Visible = True;
		Items.GroupCompositionOfResources.Visible = True;
		
		ThereAreManagementAccountingResources = DetermineUseOfAccounting("ManResources");
		Items.ManResourcesGroup.Visible = ThereAreManagementAccountingResources;
		Items.LabelManResourcesAreMissing.Visible = Not ThereAreManagementAccountingResources;
		
		ThereAreRegulatedAccountingResources = DetermineUseOfAccounting("LocalResources");
		Items.LocalResourcesGroup.Visible = ThereAreRegulatedAccountingResources;
		Items.LocalResourcesLabelIsMissing.Visible = Not ThereAreRegulatedAccountingResources;
		
		Items.LabelResourcesShaft.Visible = CurrencyAccounting;
		Items.GroupResourcesVal.Visible = CurrencyAccounting;
		
		Items.LabelResourcesQuantity.Visible = QuantitativeAccounting;
		Items.GroupResourcesQuantity.Visible = QuantitativeAccounting;
		
		If GetFunctionalOption("SettingOfPostingByAccountingObjects") = True Then
			Items.ExtDimensionPageIsFilledIn.Visible = True;
		EndIf;
		
		If GetFunctionalOption("UseBudgeting") = True Then
			Items.BudgetingMetricsPage.Visible = True;
		EndIf;
		
	Else
		Items.DataSourcePresentation.Type = FormFieldType.LabelField;
		Items.DataSourcePresentation.TitleLocation = FormItemTitleLocation.None;
		
		Items.AvailableDataSourceFieldsGroup.Visible = False;
		Items.GroupDataSelection.Visible = False;
		Items.GroupCompositionOfResources.Visible = False;
	EndIf;
	
	If Object.FunctionalOptions.Count() > 0 Then
		Items.UsageSettingsSelection.Visible = True;
		Items.UsageSettingsSelectionTypeOfComparison.Visible = False;
		Items.UsageSettingsSelectionUsage.Visible = False;
	Else
		Items.UsageSettingsSelection.Visible = False;
	EndIf;
	
	If Items.SectionsSettingsPage.Visible Then
		If ValueIsFilled(Object.SettingObjectSource) Then
			Items.PresentationOfCustomizationObjects.Type = FormFieldType.InputField;
			Items.PresentationOfCustomizationObjects.TitleLocation = FormItemTitleLocation.Left;
			Items.PresentationOfCustomizationObjects.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
			Items.OpenSettingsObjects.Visible = True;
			Items.GroupSelectionOfObjectsSettings.Visible = True;
		Else
			Items.PresentationOfCustomizationObjects.Type = FormFieldType.LabelField;
			Items.PresentationOfCustomizationObjects.TitleLocation = FormItemTitleLocation.None;
			Items.PresentationOfCustomizationObjects.ToolTipRepresentation = ToolTipRepresentation.None;
			Items.PresentationOfCustomizationObjects.AutoMaxWidth = False;
			Items.OpenSettingsObjects.Visible = False;
			Items.GroupSelectionOfObjectsSettings.Visible = False;
		EndIf;
		
		If ValueIsFilled(Object.DetailedSettingsSource) Then
			Items.DetailedSettingsGroup.Visible = True;
		Else
			Items.DetailedSettingsGroup.Visible = False;
		EndIf;
	EndIf;
	
	If Items.ExtDimensionPageIsFilledIn.Visible Then
		If Object.PathsToExtdimensionData.Count() > 0 Then
			Items.PathsToExtdimensionData.Visible = True;
			Items.PresentationOfExtDimensionFilling.Visible = False;
		Else
			Items.PathsToExtdimensionData.Visible = False;
			Items.PresentationOfExtDimensionFilling.Visible = True;
		EndIf;
	EndIf;
	
	If Items.BudgetingMetricsPage.Visible Then
		Items.GroupCompositionOfIndicators.Visible = True;
		If Indicators.Count() = 1 Then
			Items.OneIndicator.Visible = True;
			Items.Indicators.Visible = False;
		Else
			Items.OneIndicator.Visible = False;
			Items.Indicators.Visible = True;
		EndIf;
	Else
		Items.GroupCompositionOfIndicators.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInResourceTable(NameOfResourceTable, SourceMetadata)
	
	SourceResources = SourceMetadata.Resources;
	SourceAttributes = SourceMetadata.Attributes;
	ResourceTable = ThisObject[NameOfResourceTable]; // FormDataCollection
	
	For Each ResourceString In Object[NameOfResourceTable] Do
		If ResourceString.ZoomRatio <> 0 Then
			Resource = SourceResources.Find(ResourceString.ResourceName);
			If Resource = Undefined Then
				Resource = SourceAttributes.Find(ResourceString.ResourceName);
			EndIf;
			If Resource <> Undefined Then
				NewRow = ResourceTable.Add();
				NewRow.ResourcePresentation = Resource.Synonym;
				NewRow.ZoomRatio = ResourceString.ZoomRatio;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function DetermineUseOfAccounting(NameOfResourceTable)
	
	ResourceTable = ThisObject[NameOfResourceTable]; // FormDataCollection
	
	Return ResourceTable.Count() > 0;
	
EndFunction

&AtServer
Function FilterPresentation(SettingsComposer)
	
	FilterPresentation = String(SettingsComposer.Settings.Filter);
	
	If IsBlankString(FilterPresentation) Then
		FilterPresentation = NStr("vi = 'Không có lọc bổ sung';
									|ru = 'Без дополнительного отбора';
									|en = 'Without additional filter'; fa = 'بدون فیلتر تکمیلی';
									|it = 'Без дополнительного отбора';
									|pl = 'Bez dodatkowego filtru';
									|tr = 'Ek filtre olmadan'");
	EndIf;
	
	Return FilterPresentation;
	
EndFunction

&AtServer
Function PresentationOfResources(NameOfResourceTable)
	
	ResourceTable = ThisObject[NameOfResourceTable]; // FormDataCollection
	NumberOfResources = ResourceTable.Count();
	
	PresentationOfResources = "";
	ResourcesInPresentation = 3;
	ResourceIndex = 0;
	
	While ResourceIndex < ResourcesInPresentation And ResourceIndex < NumberOfResources Do
		ResourceString = ResourceTable[ResourceIndex];
		
		Separator = ?(PresentationOfResources = "", "", ", ");
		Separator = Separator + ?(ResourceString.ZoomRatio < 0, "- ", "");
		
		PresentationOfResources = PresentationOfResources + Separator + ResourceString.ResourcePresentation;
		ResourceIndex = ResourceIndex + 1;
	EndDo;
	
	If NumberOfResources > ResourceIndex Then
		Separator = NStr("vi = 'và hơn nữa';
						|ru = 'и еще';
						|en = 'and'; fa = 'و';
						|it = 'и еще';
						|pl = 'i jeszcze';
						|tr = 've daha'");
		Separator = " " + Separator + " ";
		PresentationOfResources = PresentationOfResources + Separator + String(NumberOfResources - ResourceIndex);
	EndIf;
	
	Return PresentationOfResources;
	
EndFunction

&AtServer
Procedure FillInTablesOfIndicators(SourceMetadata)
	
	DescriptionIndicator = ChartsOfCharacteristicTypes.AssetLiabilityItems.NewDescriptionOfIndicator();
	
	For Each KeyAndValue In DescriptionIndicator Do
		NameOfResourceTable = KeyAndValue.Key;
		FillInIndicatorsForResourcesTable(NameOfResourceTable, SourceMetadata);
	EndDo;
	
	FillInAdditionalIndicators(SourceMetadata);
	
	TableOfIndicators = ResourcesOfIndicators.Unload(, "Factor");
	TableOfIndicators.GroupBy("Factor");
	
	For Each IndicatorLine_1 In TableOfIndicators Do
		FillPropertyValues(Indicators.Add(), IndicatorLine_1);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInIndicatorsForResourcesTable(NameOfResourceTable, SourceMetadata)
	
	SourceResources = SourceMetadata.Resources;
	SourceAttributes = SourceMetadata.Attributes;
	
	For Each ResourceString In Object[NameOfResourceTable] Do
		If ResourceString.ZoomRatio <> 0 Then
			Resource = SourceResources.Find(ResourceString.ResourceName);
			If Resource = Undefined Then
				Resource = SourceAttributes.Find(ResourceString.ResourceName);
			EndIf;
			If Resource <> Undefined Then
				AddResourceToIndicator(ResourceString, Resource, NameOfResourceTable);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAdditionalIndicators(SourceMetadata)
	
	SourceResources = SourceMetadata.Resources;
	SourceAttributes = SourceMetadata.Attributes;
	
	For Each IndicatorLine_1 In Object.AdditionalIndicators Do
		If IndicatorLine_1.ZoomRatio <> 0 Then
			Resource = SourceResources.Find(IndicatorLine_1.ResourceName);
			If Resource = Undefined Then
				Resource = SourceAttributes.Find(IndicatorLine_1.ResourceName);
			EndIf;
			If Resource <> Undefined Then
				NameOfResourceTable = IndicatorLine_1.ResourceGroup;
				AddResourceToIndicator(IndicatorLine_1, Resource, NameOfResourceTable);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddResourceToIndicator(IndicatorLine_1, Resource, NameOfResourceTable)
	
	ResourceColumnsNames = ColumnNamesOfMetricResource(NameOfResourceTable);
	
	TheStructureOfTheSearch = New Structure("Factor", IndicatorLine_1.Factor);
	IndicatorResources = ResourcesOfIndicators.FindRows(TheStructureOfTheSearch);
	ResourceIndicationString = Undefined;
	
	For Each IndicatorResourceLine In IndicatorResources Do
		If IsBlankString(IndicatorResourceLine[ResourceColumnsNames.Presentation]) Then
			ResourceIndicationString = IndicatorResourceLine;
			Break;
		EndIf;
	EndDo;
	
	If ResourceIndicationString = Undefined Then
		ResourceIndicationString = ResourcesOfIndicators.Add();
		ResourceIndicationString.Factor = IndicatorLine_1.Factor;
	EndIf;
	
	ResourceIndicationString[ResourceColumnsNames.Presentation] = Resource.Synonym;
	ResourceIndicationString[ResourceColumnsNames.ZoomRatio] = IndicatorLine_1.ZoomRatio;
	
EndProcedure

&AtClientAtServerNoContext
Function ColumnNamesOfMetricResource(NameOfResourceTable)
	
	If NameOfResourceTable = "ManResources" Then
		ColumnNamePresentation = "PresentationOfManResource";
		ColumnNameCoefficient = "ManSCoefficient";
	ElsIf NameOfResourceTable = "LocalResources" Then
		ColumnNamePresentation = "PresentationOfLocalResource";
		ColumnNameCoefficient = "LocalCoefficient";
	ElsIf NameOfResourceTable = "ShaftResources" Then
		ColumnNamePresentation = "PresentationOfShaftResource";
		ColumnNameCoefficient = "ShaftRatio";
	Else
		ColumnNamePresentation = "PresentationOfResourceQuantity";
		ColumnNameCoefficient = "FactorQuantity";
	EndIf;
	
	ColumnsNames = New Structure();
	ColumnsNames.Insert("Presentation", ColumnNamePresentation);
	ColumnsNames.Insert("ZoomRatio", ColumnNameCoefficient);
	
	Return ColumnsNames;
	
EndFunction

&AtClient
Procedure CreatePresentationsOfIndicatorResources(Factor)
	
	SelectingRowsByIndicator = New FixedStructure("Factor", Factor);
	
	Items.ManIndicatorResources.RowFilter = SelectingRowsByIndicator;
	Items.LocalIndicatorResources.RowFilter = SelectingRowsByIndicator;
	Items.ValIndicatorResources.RowFilter = SelectingRowsByIndicator;
	Items.ResourcesOfQuantityIndicator.RowFilter = SelectingRowsByIndicator;
	
	PresentationOfManSResources = PresentationOfIndicatorResources(Factor, "ManResources");
	LocalResourcePresentation = PresentationOfIndicatorResources(Factor, "LocalResources");
	PresentationOfShaftResources = PresentationOfIndicatorResources(Factor, "ShaftResources");
	PresentationOfResourcesQuantity = PresentationOfIndicatorResources(Factor, "ResourcesQuantity");
	
	ThereAreResourcesMan = Not IsBlankString(PresentationOfManSResources);
	ThereAreLocalResources = Not IsBlankString(LocalResourcePresentation);
	ThereAreResources = Not IsBlankString(PresentationOfShaftResources);
	ThereAreResourcesQuantity = Not IsBlankString(PresentationOfResourcesQuantity);
	
	Items.ManIndicatorResourcesLabel.Visible = ThereAreResourcesMan;
	Items.ManIndicatorResourcesGroup.Visible = ThereAreResourcesMan;
	Items.ManIndicatorResourcesGroup.Title = PresentationOfManSResources;
	
	Items.LocalIndicatorResourcesLabel.Visible = ThereAreLocalResources;
	Items.LocalIndicatorResourcesGroup.Visible = ThereAreLocalResources;
	Items.LocalIndicatorResourcesGroup.Title = LocalResourcePresentation;
	
	Items.InscriptionResourcesOfValIndicator.Visible = ThereAreResources;
	Items.GroupResourcesOfValIndicator.Visible = ThereAreResources;
	Items.GroupResourcesOfValIndicator.Title = PresentationOfShaftResources;
	
	Items.LabelResourcesOfQuantityIndicator.Visible = ThereAreResourcesQuantity;
	Items.GroupResourcesOfQuantityIndicator.Visible = ThereAreResourcesQuantity;
	Items.GroupResourcesOfQuantityIndicator.Title = PresentationOfResourcesQuantity;
	
EndProcedure

&AtClient
Function PresentationOfIndicatorResources(Factor, NameOfResourceTable)
	
	PresentationOfResources = "";
	ResourcesInPresentation = 2;
	NumberOfResources = 0;
	
	ResourceColumnsNames = ColumnNamesOfMetricResource(NameOfResourceTable);
	
	TheStructureOfTheSearch = New Structure("Factor", Factor);
	IndicatorResources = ResourcesOfIndicators.FindRows(TheStructureOfTheSearch);
	
	For Each IndicatorResourceLine In IndicatorResources Do
		If Not IsBlankString(IndicatorResourceLine[ResourceColumnsNames.Presentation]) Then
			NumberOfResources = NumberOfResources + 1;
			If NumberOfResources <= ResourcesInPresentation Then
				Separator = ?(PresentationOfResources = "", "", ", ");
				Separator = Separator + ?(IndicatorResourceLine[ResourceColumnsNames.ZoomRatio] < 0, "- ", "");
				PresentationOfResources = PresentationOfResources + Separator + IndicatorResourceLine[ResourceColumnsNames.Presentation];
			EndIf;
		EndIf;
	EndDo;
	
	If NumberOfResources > ResourcesInPresentation Then
		Separator = NStr("vi = 'và hơn nữa';
						|ru = 'и еще';
						|en = 'and'; fa = 'و';
						|it = 'e anche';
						|pl = 'i jeszcze';
						|tr = 've daha'");
		Separator = " " + Separator + " ";
		PresentationOfResources = PresentationOfResources + Separator + String(NumberOfResources - ResourcesInPresentation);
	EndIf;
	
	Return PresentationOfResources;
	
EndFunction

#EndRegion