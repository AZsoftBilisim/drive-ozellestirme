#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var AttributeCache;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Items.AllocationIndicator.ChoiceList.Clear();
	Items.AllocationIndicator.ChoiceList.Add("SalesRevenue", NStr("vi = 'Doanh thu bán hàng';
																	|ru = 'Выручка от продаж';
																	|en = 'Sales revenue'; fa = 'درآمد فروش';
																	|it = 'Ricavo dalle vendite';
																	|pl = 'Przychód ze sprzedaży';
																	|tr = 'Satış geliri'"));
	Items.AllocationIndicator.ChoiceList.Add("SaleCost", NStr("vi = 'Giá vốn hàng bán';
																|ru = 'Себестоимость продаж';
																|en = 'Cost of goods sold'; fa = 'بهای تمام‌شده کالای فروش‌رفته';
																|it = 'Costo di produzione delle vendite';
																|pl = 'Koszty własne sprzedaży';
																|tr = 'Satılan malların maliyeti'"));
	Items.AllocationIndicator.ChoiceList.Add("GrossProfit", NStr("vi = 'Lợi nhuận gộp';
																|ru = 'Валовая прибыль';
																|en = 'Gross profit'; fa = 'سود ناخالص';
																|it = 'Profitto lordo';
																|pl = 'Dochód brutto';
																|tr = 'Brüt kâr'"));
	Items.AllocationIndicator.ChoiceList.Add("DirectCosts", NStr("vi = 'Chi phí sản xuất trực tiếp';
																|ru = 'Прямые производственные затраты';
																|en = 'Direct production costs'; fa = 'هزینه‌های مستقیم تولید';
																|it = 'Spese dirette di produzione';
																|pl = 'Bezpośrednie wydatki produkcyjne';
																|tr = 'Direkt üretim giderleri'"));
	Utbazovaya = GetFunctionalOption("BaseVersion");
	
	If Not ValueIsFilled(Object.Ref) Then
		If Object.LocalAccounting Then
			SynchronizeTypesOfAccountingBUAndTa("LocalAccounting");
		ElsIf Object.TaxAccounting Then
			SynchronizeTypesOfAccountingBUAndTa("TaxAccounting");
		EndIf;
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfForm();
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If Object.SettingsOfBaseOfAllocationByLotsChanged Then
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(
			SettingsOfBaseOfAllocationByLots.GetSettings());
	Else
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(Undefined);
	EndIf;
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCaptionPeriod();
	
	AttributeCache = New Structure;
	AttributeCache.Insert("ManagementAccounting", Object.ManagementAccounting);
	AttributeCache.Insert("LocalAccounting", Object.LocalAccounting);

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	FiltersAttributes = New Array;
	FiltersAttributes.Add(New Structure("FilterByLinesOfBusiness", "LineOfBusiness"));

	For Each PropsWithSelection In FiltersAttributes Do
		
		For Each KeyAndValue In PropsWithSelection Do
			
			Object[KeyAndValue.Key].Clear();
			For Each Item In ThisForm[KeyAndValue.Key] Do 
				
				NewRow = Object[KeyAndValue.Key].Add();
				NewRow[KeyAndValue.Value] = Item.Value;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	If AllocationIndicator = "DirectCosts" Then
		Return;
	EndIf;
	DatabaseTypeTemplate = "Enum.TypesOfCostAllocatingBase.%1";
	BaseTypeValue = StrTemplate(DatabaseTypeTemplate, 
		?(AllocationIndicator="","EmptyRef",AllocationIndicator));
	Object.BaseOfAllocationByLots = PredefinedValue(BaseTypeValue);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	TransferParameters = New Structure;
	TransferParameters.Insert("Organization", Object.Organization);
	TransferParameters.Insert("Department", Object.Department);
	TransferParameters.Insert("ExpenseItem", Object.ExpenseItem);
	TransferParameters.Insert("DimensionOfExpenses", Object.DimensionOfExpenses);
	TransferParameters.Insert("LineOfBusiness", Object.LineOfBusiness);

	If Object.Posted Then

		DocumentTransfers_ = Object.Ref;
		State = PredefinedValue("Enum.CostAllocationStates.ReadyForAllocation");

	Else

		DocumentTransfers_ = Undefined;
		State = PredefinedValue(
			"Enum.CostAllocationStates.DocumentGenerationIsRequired");

	EndIf;

	If Object.ManagementAccounting Or AttributeCache.ManagementAccounting Then

		If Not Object.ManagementAccounting And AttributeCache.ManagementAccounting Then

			TransferParameters.Insert("DocumentMan", Undefined);
			TransferParameters.Insert("UPRStatus", PredefinedValue(
				"Enum.CostAllocationStates.DocumentGenerationIsRequired"));

		Else

			TransferParameters.Insert("DocumentMan", DocumentTransfers_);
			TransferParameters.Insert("UPRStatus", State);

		EndIf;

	EndIf;

	If Object.LocalAccounting Or AttributeCache.LocalAccounting Then

		If Not Object.LocalAccounting And AttributeCache.LocalAccounting Then

			TransferParameters.Insert("DocumentCompl", Undefined);
			TransferParameters.Insert("ReglStatus", PredefinedValue(
				"Enum.CostAllocationStates.DocumentGenerationIsRequired"));

		Else

			TransferParameters.Insert("DocumentCompl", DocumentTransfers_);
			TransferParameters.Insert("ReglStatus", State);

		EndIf;

	EndIf;
		

	Notify("Write_AllocationOfOtherCosts", TransferParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateCaptionPeriod();
	
EndProcedure

&AtClient
Procedure TypeOfAccountingForChanges(Item)
	SetAvailabilityOfAccountingTypes();
EndProcedure

#EndRegion

#Region EventHandlersDistributionRules

&AtClient
Procedure AllocationIndicatorOnChange(Item)
	
	ProcessChangeOfDistributionIndicator();
	
EndProcedure

&AtClient
Procedure AllocationDirectionOnChange(Item)
	
	HandleChangeOfDistributionDirection();
	
EndProcedure

&AtClient
Procedure BaseOfAllocationByLotsOnChange(Item)
	ProcessChangeInDistributionBaseByBatch();
	// In the UT, the handler is empty.
	Return;
	
EndProcedure

&AtClient
Procedure URLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "LinesOfBusiness" Then
		
		FilterParameters = New Structure("ArrayOfActivities", FilterByLinesOfBusiness.UnloadValues());
		AdditionalSelectionParameter = "FilterByLinesOfBusiness";

		OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
				FilterParameters,
				ThisForm,,,, 
				New CallbackDescription("CompleteSelectionSelection", ThisObject, AdditionalSelectionParameter), 
				FormWindowOpeningMode.LockOwnerWindow);
				
	EndIf;	
	
EndProcedure

&AtClient
Procedure TextAddEditSelectionOfTheBatchDistributionDatabaseClick(Item, StandardProcessing)
	StandardProcessing = False;
	If Not ValueIsFilled(Object.BaseOfAllocationByLots) Then
		CommonClient.MessageToUser(NStr("vi = 'Trước khi thêm bộ lọc, cần chọn cơ sở phân bổ.';
										|ru = 'Перед добавлением отбора необходимо выбрать базу распределения.';
										|en = 'Select allocation base before adding a filter.'; fa = 'Select allocation base before adding a filter.';
										|it = 'Prima di aggiungere la selezione è necessario scegliere la base di ripartizione.';
										|pl = 'Przed dodaniem wyboru należy wybrać podstawę podziału.';
										|tr = 'Filtre eklemeden önce tahsisat tabanını seçmeniz gerekmektedir.'"),,
			"Object.BaseOfAllocationByLots");
		Return;
	EndIf;
		OpeningParameters = ParametersForOpeningSelectionSettings();
		OpeningParameters.SchemaName = NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots);
		OpeningParameters.NameOfComposerSettings = "SettingsOfBaseOfAllocationByLots";
		If OpeningParameters.SchemaName = "MaterialCosts"
			Or OpeningParameters.SchemaName = "MaterialAndLaborCosts" Then
				OpeningParameters.DoNotConfigureSettings = False;
		EndIf;
	
		OpenSelectionSettingsForm(OpeningParameters, NStr("vi = 'Tùy chỉnh lọc cơ sở phân bổ';
															|ru = 'Настройка отбора базы распределения';
															|en = 'Allocation base filter settings'; fa = 'Allocation base filter settings';
															|it = 'Impostare la selezione della base di ripartizione';
															|pl = 'Ustawienie wyboru podstawy podziału';
															|tr = 'Tahsisat tabanının filtre ayarı'"));

	// the UT has an empty handler.
	Return;

EndProcedure

&AtClient
Procedure TextAddChangeFilterByManufacturedProductsBatchesClick(Item, StandardProcessing)
	StandardProcessing = False;

	// the UT has an empty handler.
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLinesOfBusiness

&AtClient
Procedure LinesOfBusinessLineOfBusinessStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CompositionSettings = New DataCompositionSettings;
	
	FilterGroup = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	SelectionGroupStartDateOfActivity = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupStartDateOfActivity.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterElement = SelectionGroupStartDateOfActivity.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue    = New DataCompositionField("StartDateOfActivity");
	FilterElement.ComparisonType     = DataCompositionComparisonType.LessOrEqual;
	FilterElement.Use    = True;
	FilterElement.RightValue   = EndOfMonth(Object.Date);

	FilterElement = SelectionGroupStartDateOfActivity.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue    = New DataCompositionField("StartDateOfActivity");
	FilterElement.ComparisonType     = DataCompositionComparisonType.Equal;
	FilterElement.Use    = True;
	FilterElement.RightValue   = '00010101';

	SelectionGroupEndDateOfActivity = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupEndDateOfActivity.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterElement = SelectionGroupEndDateOfActivity.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue    = New DataCompositionField("EndDateOfActivity");
	FilterElement.ComparisonType     = DataCompositionComparisonType.GreaterOrEqual;
	FilterElement.Use    = True;
	FilterElement.RightValue   = BegOfMonth(Object.Date);
	
	FilterElement = SelectionGroupEndDateOfActivity.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue    = New DataCompositionField("EndDateOfActivity");
	FilterElement.ComparisonType     = DataCompositionComparisonType.Equal;
	FilterElement.Use    = True;
	FilterElement.RightValue   = '00010101';

	FormParameters = New Structure;
	FormParameters.Insert("FixedSettings", CompositionSettings);
	FormParameters.Insert("ChoiceMode",            True);
	FormParameters.Insert("MultipleChoice",     False);
	
	CallbackDescription = New CallbackDescription("LinesOfBusinessLineOfBusinessEndOfChoice", ThisObject);
	OpenForm("Catalog.LinesOfBusiness.ChoiceForm", FormParameters, ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure LinesOfBusinessLineOfBusinessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	If StrLen(Text) > 2 Then
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(ListOfSimilarRelevantLinesOfBusiness(Text, Object.Date));
	EndIf;
	
EndProcedure

&AtClient
Procedure LinesOfBusinessLineOfBusinessOnChange(Item)
	
	CurrentData = Items.LinesOfBusiness.CurrentData;
	
	LineOfBusinessIsRelevant = LineOfBusinessIsRelevant(CurrentData.LineOfBusiness, Object.Date);
	If Not LineOfBusinessIsRelevant Then
		CommonClient.MessageToUser(NStr("vi = 'Chỉ có thể chọn các lĩnh vực hoạt động có hiệu lực, 
			|đang hoạt động trong kỳ được chọn.';
			|ru = 'К выбору доступны только актуальные направления деятельности, 
			|которые действуют в выбранном периоде.';
			|en = 'You can select only relevant lines of business 
			|that are valid in the selected period.'; fa = 'You can select only relevant lines of business 
			|that are valid in the selected period.';
			|it = 'К выбору доступны только актуальные направления деятельности, 
			|которые действуют в выбранном периоде.';
			|pl = 'You can select only relevant lines of business 
			|that are valid in the selected period.';
			|tr = 'Yalnızca seçilen dönemde faaliyet gösteren mevcut faaliyet alanları seçilebilir.'"),,
			Item);
		CurrentData.LineOfBusiness = EmptyLineOfBusiness();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

#Region BSP

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Pickup

&AtClient
Procedure CompleteSelectionSelection(Result, AdditionalParameters) Export
	
	If Not TypeOf(Result) = Type("Array") Then
		Return;
	EndIf;
	
	Modified = True;
	
	If AdditionalParameters = "FilterByLinesOfBusiness" Then
		
		FilterByLinesOfBusiness.LoadValues(Result);
		ProcessSelectionChangesByAreasOfActivity(ThisForm);
	EndIf;

EndProcedure

#EndRegion

#Region DetailsChangeHandlers

&AtClient
Procedure HandleChangeOfDistributionDirection()
	
	ClearDependentProps("AllocationDirection");
	
	SetPageVisibility(ThisForm, "AllocationDirection");
	SetItemsAvailability(ThisForm, "AllocationDirection");
	SetItemsVisibility(ThisForm, "AllocationDirection");
	
EndProcedure

&AtClient
Procedure ProcessChangeOfDistributionIndicator()
	
	ClearDependentProps("AllocationIndicator");		
	SetItemsVisibility(ThisForm, "AllocationIndicator");	
	
EndProcedure

&AtClient
Procedure ProcessChangeInDistributionBaseByBatch()
	
	If Not NameOfDistributionBaseSchema(CacheBaseOfAllocationByBatches) = 
		NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots) Then
		ClearDependentProps("BaseOfAllocationByLots");
	Else
		ConfigureFieldHeaders(ThisForm);
	EndIf;
	
	CacheBaseOfAllocationByBatches = Object.BaseOfAllocationByLots;
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtServer
Procedure ProcessChangesToDistributionDatabaseSettingsByBatch()

		Object.SettingsOfBaseOfAllocationByLotsChanged = FilterIs_Specified(
			SettingsOfBaseOfAllocationByLots);
	Modified = Max(Modified, Object.SettingsOfBaseOfAllocationByLotsChanged);
	ConfigureFieldHeaders(ThisForm, "SelectionOfDistributionBaseByParty");
	
EndProcedure


&AtClientAtServerNoContext
Procedure ProcessSelectionChangesByAreasOfActivity(Form)
	
	Items = Form.Items;
			
	Items.SubmissionOfTheSpecifiedTaxReturns.Title = 
		GenerateFilterPresentation("LinesOfBusiness", Form.FilterByLinesOfBusiness.UnloadValues(), 
			NStr("vi = 'lĩnh vực hoạt động, lĩnh vực hoạt động, lĩnh vực hoạt động';
				|ru = 'направление деятельности, направления деятельности, направлений деятельности';
				|en = 'line of business, lines of business, of lines of business'; fa = 'line of business, lines of business, of lines of business';
				|it = 'settore di attività, settori di attività, dei settori di attività';
				|pl = 'rodzaj działalności, rodzaju działalności, rodzajów działalności';
				|tr = 'iş kolu, iş kolu, iş kolu'"));
		
EndProcedure

&AtClient
Procedure LinesOfBusinessLineOfBusinessEndOfChoice(Result, AdditionalParameters) Export
	
	CurrentData = Items.LinesOfBusiness.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result)
		And TypeOf(Result) = Type("CatalogRef.LinesOfBusiness") Then
		
		CurrentData.LineOfBusiness = Result;
		Modified = True;
		
	EndIf;
	
EndProcedure


#EndRegion

#Region Filters

&AtClientAtServerNoContext
Function GenerateFilterPresentation(Hyperlink, FilterList, SubjectOfCalculus = Undefined, TextSpecifyEmptyValue = "")
	
	If FilterList.Count() = 0 Then
		
		If IsBlankString(TextSpecifyEmptyValue) Then
			SpecifyText = NStr("vi = 'Chỉ ra';
								|ru = 'Указать';
								|en = 'Specify'; fa = 'تعیین';
								|it = 'Specificare';
								|pl = 'Wskaż';
								|tr = 'Belirt'");
		Else
			SpecifyText = TextSpecifyEmptyValue;
		EndIf;
		
		Return New FormattedString(SpecifyText,,,, Hyperlink);
		
	EndIf;	
	
	Return FilterPresentation(FilterList, SubjectOfCalculus, Hyperlink);
	
EndFunction

&AtServerNoContext
Function FilterPresentation(FilterList, SubjectOfCalculus, Hyperlink)
	
	If FilterList.Count() = 0 Then
		Return "";
	EndIf;
	
	If FilterList.Count() = 1 Then
		FilterPresentation = TrimAll(FilterList[0]);
	Else
		
		NumberOfRows = FilterList.Count() - 1;
		ForDeclension = NumberInWords(NumberOfRows, , SubjectOfCalculus);
		
		BeginningOfSubject = StrFind(ForDeclension, Left(SubjectOfCalculus, 3));
		BowedSubject = Mid(ForDeclension, BeginningOfSubject, StrFind(ForDeclension, " ",, BeginningOfSubject) - BeginningOfSubject);
		
		Presentation = NStr("vi = '%1 và hơn nữa %2 %3';
							|ru = '%1 и еще %2 %3';
							|en = '%1 and also %2 %3'; fa = '%1 and also %2 %3';
							|it = '%1 e anche %2 %3';
							|pl = '%1 i jeszcze %2 %3';
							|tr = '%1 ve %2 %3 daha'");
		
		FilterPresentation = StringFunctionsClientServer.SubstituteParametersToString(Presentation, 
			TrimAll(FilterList[0]), NumberOfRows, 
			BowedSubject);
			
	EndIf;
	
	FormattedSelectionPresentation = New FormattedString(FilterPresentation,, StyleColors.NoteText);
	SubstringEdit = New FormattedString(NStr("vi = '(Thay đổi)';
											|ru = '(Изменить)';
											|en = '(Change)'; fa = '(Change)';
											|it = '(Modificare)';
											|pl = '(Zmień)';
											|tr = '(Değiştir)'"),,,, Hyperlink);
	
	Return New FormattedString(FormattedSelectionPresentation,
		?(IsBlankString(FormattedSelectionPresentation), "", " "),
		SubstringEdit);
	
EndFunction

&AtServer
Procedure LoadBasicComposerSettings(Var_AttributeName = "")
	
	If Var_AttributeName = "SettingsOfBaseOfAllocationByLots" 
		Or Var_AttributeName = "" Then
		
		SchemaName = Enums.TypesOfCostAllocatingBase.NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots);
		
		If Not IsBlankString(SchemaName) Then
			
			CompositionSchema = Enums.TypesOfCostAllocatingBase.GetTemplate(SchemaName);
			SettingsOfBaseOfAllocationByLots.LoadSettings(CompositionSchema.DefaultSettings);
			
		EndIf;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure RestoreComposerSettings(PropsNameWithSettings, DocObject = Undefined)
	
	If DocObject = Undefined Then
		DocObject = FormAttributeToValue("Object");
	EndIf;

	AttributesWithComposerSettings = DocObject[PropsNameWithSettings]; // ValueStorage
	ComposerSettings = AttributesWithComposerSettings.Get();
	If Not ComposerSettings = Undefined Then
		ThisForm[PropsNameWithSettings].LoadSettings(ComposerSettings);		
	EndIf;

EndProcedure

&AtClient
Function ParametersForOpeningSelectionSettings()
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("SchemaName", "");
	OpeningParameters.Insert("NameOfComposerSettings", "");
	OpeningParameters.Insert("DoNotConfigureSettings", True);
	
	Return OpeningParameters;
	
EndFunction

// Opens the selection settings form.
// Parameters:
//	OpeningParameters - Structure - Description of the structure in the parametersoptionsadjustmentsreferences
&AtClient
Procedure OpenSelectionSettingsForm(OpeningParameters, FormCaption = "")

	Addresses = GetAddressesOfDataLayoutSchemeInTemporaryStorage(OpeningParameters);
		
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", True);
	FormParameters.Insert("DoNotConfigureSettings", OpeningParameters.DoNotConfigureSettings);
	FormParameters.Insert("NotEditDataCompositionSchema", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormParameters.Insert("Title", FormCaption);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("EditDataCompositionSchemaCompletion",
			ThisObject,
			OpeningParameters),
		FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtServer
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(Var_Parameters)
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings");
	Schema = Enums.TypesOfCostAllocatingBase.GetTemplate(Var_Parameters.SchemaName);
	
	If Not GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
		
		ProductGroupField = Schema.DataSets[0].Fields.Find("ProductsGroup"); // DataCompositionSchemaDataSetField
		If Not ProductGroupField = Undefined Then
			
			ProductGroupField.UseRestriction.Condition = True;
			ProductGroupField.AttributeUseRestriction.Condition = True;
			
		EndIf;
		
	EndIf;
	
	FieldOfActivity = Schema.DataSets[0].Fields.Find("LineOfBusiness"); // DataCompositionSchemaDataSetField
	If Not FieldOfActivity = Undefined Then
		
		FieldOfActivity.UseRestriction.Condition = True;
		FieldOfActivity.AttributeUseRestriction.Condition = True;
		
	EndIf;

	Addresses.DataCompositionSchema = PutToTempStorage(Schema, UUID);
	
	Settings = ThisForm[Var_Parameters.NameOfComposerSettings].GetSettings();
	If ValueIsFilled(Settings) Then
		Addresses.DataCompositionSettings = PutToTempStorage(Settings, UUID);
	EndIf;
	
	Return Addresses;
	
EndFunction

&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export

	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ThisForm[AdditionalParameters.NameOfComposerSettings].LoadSettings(
		GetFromTempStorage(Result));
	
	ProcessChangesToBankingDetails(AdditionalParameters.NameOfComposerSettings);

EndProcedure

&AtServerNoContext
Function FilterIs_Specified(NewSettings1)
	
	FilterIs_Specified = False;
	ComposerSettings = NewSettings1.GetSettings();
	For Each FilterElement In ComposerSettings.Filter.Items Do
		If FilterElement.Use Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
	EndDo;
	
	Return FilterIs_Specified;
	
EndFunction
#EndRegion

#Region BSP

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

#EndRegion

#Region FormControl

&AtClientAtServerNoContext
Procedure SetPageVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Or AttributeName = "AllocationDirection" Then
		
		Items.DescriptionOfTheRuleForTheFinancialResult.Visible = 
			Not Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.ByRates")
			And Not Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit");
			
		Items.LinesOfBusinessPage.Visible = 
			Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.ByRates");
			
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = "AllocationDirection" Or AttributeName = Undefined Then
		Items.SubmissionOfTheSpecifiedTaxReturns.Visible = 
			Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Specified");
	EndIf;
	
	If AttributeName = "AllocationIndicator" Or AttributeName = Undefined Then
		Items.GroupAllocationBaseForFR.Visible = Form.AllocationIndicator = "DirectCosts";
		Items.DataSource.Visible = Form.AllocationIndicator <> "DirectCosts" And Form.AllocationIndicator <> "";
		If Form.AllocationIndicator <> "DirectCosts" And Form.AllocationIndicator <> "" And Not ValueIsFilled(Object.DataSource) Then
			Object.DataSource = PredefinedValue("Enum.DataSourcesForExpenseAllocation.RevenueAndCOGS");
		EndIf;
	EndIf;
	
	If AttributeName = Undefined Then
		
		Items.GroupAccountingKinds.Visible = Not Form.Utbazovaya;
		Items.AllocationSettingIsNotRequired.Visible = 
			Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit");
		Items.GroupWhereToDistribute.Visible = Not Items.AllocationSettingIsNotRequired.Visible;
			
		Items.GroupExpenseByItem.Visible = Not Form.CostAllocationFromCostCenter;
		Items.LineOfBusiness.Visible = Not Form.CostAllocationFromCostCenter;
		Items.GroupHIAExpense.Visible = Form.CostAllocationFromCostCenter;
		Items.AreaOfActivityForHIA.Visible = Form.CostAllocationFromCostCenter;

		Items.AllocationIndicator.Visible = Object.ManagementAccounting Or Object.LocalAccounting;
	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Then
		
		Items.TheDirectionOfDistributionBetweenTheND.Enabled = 
			Not Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfAccountingTypes()
	
	Documents.AllocationOfOtherCosts.SetAvailabilityOfAccountingTypes(ThisForm);
	
EndProcedure

&AtServer
Procedure SynchronizeTypesOfAccountingBUAndTa(AccountingKind)
	
	Documents.AllocationOfOtherCosts.SynchronizeTypesOfAccountingBUAndTa(ThisForm, AccountingKind);
	
EndProcedure


&AtClientAtServerNoContext
Procedure CustomizeFieldDesign(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.DistributionBaseOnTheFR.MarkIncomplete = Form.AllocationIndicator = "DirectCosts" 
		And Not ValueIsFilled(Object.BaseOfAllocationByLots);
		
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFieldHeaders(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	PresentationOfHyperlinks = New Map();
	PresentationOfHyperlinks.Insert(True, NStr("vi = 'Đã đặt bộ lọc, thay đổi';
												|ru = 'Отбор установлен, изменить';
												|en = 'Filter is set, change'; fa = 'Filter is set, change';
												|it = 'Selezione impostata, modificare';
												|pl = 'Ustawiono filtr, zmień';
												|tr = 'Filtre ayarlandı, değiştir'"));
	PresentationOfHyperlinks.Insert(False, NStr("vi = 'Chưa đặt lọc, thêm';
												|ru = 'Отбор не установлен, добавить';
												|en = 'Filter not set, add'; fa = 'Filter not set, add';
												|it = 'La selezione non è impostata, aggiungere';
												|pl = 'Nie ustawiono filtru, dodaj';
												|tr = 'Filtre ayarlanmadı, ekle'"));
	
	If AttributeName = "SelectionOfDistributionBaseByParty" 
		Or AttributeName = Undefined Then
		
		Items.TextAddEditSelectionOfTheBatchDistributionDatabase.Hyperlink = True;
		Items.TextAddEditSelectionOfTheBatchDistributionDatabase.TextColor = New Color();
		
			Form.TextAddEditSelectionOfTheBatchDistributionDatabase = 
				PresentationOfHyperlinks.Get(Object.SettingsOfBaseOfAllocationByLotsChanged);
		
	EndIf;
		
	
	If Not ValueIsFilled(Object.BaseOfAllocationByLots)
		Or Object.BaseOfAllocationByLots = PredefinedValue("Enum.TypesOfCostAllocatingBase.SalesRevenue")
		Or Object.BaseOfAllocationByLots = PredefinedValue("Enum.TypesOfCostAllocatingBase.SaleCost")
		Or Object.BaseOfAllocationByLots = PredefinedValue("Enum.TypesOfCostAllocatingBase.GrossProfit") Then
		
		Form.TextAddEditSelectionOfTheBatchDistributionDatabase = NStr("vi = 'Bộ lọc không hợp lệ.';
																		|ru = 'Отбор недоступен.';
																		|en = 'Filter is unavailable.'; fa = 'Filter is unavailable.';
																		|it = 'Selezione non disponibile.';
																		|pl = 'Filtr jest niedostępny.';
																		|tr = 'Filtre mevcut değil.'");
		Items.TextAddEditSelectionOfTheBatchDistributionDatabase.Hyperlink = False;
		Items.TextAddEditSelectionOfTheBatchDistributionDatabase.TextColor = WebColors.DarkGray;
		
	EndIf;

EndProcedure


#EndRegion

#Region InitializeForm

&AtServer
Procedure OnReadCreateAtServer()

	CostAllocationFromCostCenter = Not ValueIsFilled(Object.ExpenseItem);

	DetermineVisibilityAndAmountOfExpensesForArticle();
	
	FillInServiceDetailsOfForm();
	
	SetPageVisibility(ThisForm);
	SetItemsVisibility(ThisForm);
	SetItemsAvailability(ThisForm);
	CustomizeFieldDesign(ThisForm);
	ConfigureFieldHeaders(ThisForm);
	SetAvailabilityOfAccountingTypes();
		
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	SetFormHeader();
	CacheBaseOfAllocationByBatches = Object.BaseOfAllocationByLots;
	LoadBasicComposerSettings();
	BatchAccounting21 = Not CalculationOfCostCached.BatchAccountingVersion22(Object.Date);
	
	ComposerSettings = Undefined;
	If Parameters.Property("Basis") And TypeOf(Parameters.Basis) = Type("Structure")
		And Parameters.Basis.Property("SettingsOfBaseOfAllocationByLots", ComposerSettings)
		And Not ComposerSettings = Undefined Then
		SettingsOfBaseOfAllocationByLots.LoadSettings(ComposerSettings);
	EndIf;
	
	DocumentObject = FormAttributeToValue("Object");
	RestoreComposerSettings("SettingsOfBaseOfAllocationByLots", DocumentObject);


	FilterByLinesOfBusiness.LoadValues(
		Object.FilterByLinesOfBusiness.Unload(, "LineOfBusiness").UnloadColumn("LineOfBusiness"));
	ProcessSelectionChangesByAreasOfActivity(ThisForm);
	
	AllocationIndicator = DetermineValueOfDistributionIndicator(Object.BaseOfAllocationByLots);
	Items.AllocationIndicator.ReadOnly = Not Users.RolesAvailable("AddEditOtherCostAllocation");
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	ObjectPresentation = Metadata.Documents.AllocationOfOtherCosts.Synonym;
	ObjectPresentationClarification = NStr("vi = 'giữa các hoạt động';
											|ru = 'между направлениями деятельности';
											|en = 'between lines of business'; fa = 'between lines of business';
											|it = 'tra i settori di attività';
											|pl = 'między kierunkami działalności';
											|tr = 'iş kolları arasında'");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		TitleTemplate1 = NStr("vi = '%1 %2 (tạo)';
								|ru = '%1 %2 (создание)';
								|en = '%1 %2 (generation)'; fa = '%1 %2 (generation)';
								|it = '%1 %2 (сreazione)';
								|pl = '%1 %2 (tworzenie)';
								|tr = '%1 %2 (oluşturma)'");
		Title = StrTemplate(TitleTemplate1, ObjectPresentation, ObjectPresentationClarification);
		
	Else
		
		TitleTemplate1 = NStr("vi = '%1 %2 số %3 ngày %4';
								|ru = '%1 %2 №%3 от %4';
								|en = '%1 %2 No.%3 dated %4'; fa = '%1 %2 No.%3 dated %4';
								|it = '%1 %2 n.%3 del %4';
								|pl = '%1 %2 Nr%3 od %4';
								|tr = '%4 itibarıyla %3 numaralı %2 %1'");
		Title = StrTemplate(TitleTemplate1, ObjectPresentation, 
								ObjectPresentationClarification,
								Object.Number,
								Format(Object.Date, "DLF=DT"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCaptionPeriod()

	LabelPeriod = PeriodPresentation(BegOfMonth(Object.Date), EndOfMonth(Object.Date), "DLF=D");
	
EndProcedure

#EndRegion
#Region WorkingWithDatabaseTypes

&AtClientAtServerNoContext
Function NameOfDistributionBaseSchema(AllocationBase)
	
	DistributionBasesByGroups = DistributionBasesByGroups();
	
	If Not DistributionBasesByGroups.UsedMaterials.Find(AllocationBase) = Undefined Then
		Return "MaterialCosts";
	ElsIf Not DistributionBasesByGroups.LaborCosts.Find(AllocationBase) = Undefined Then
		Return "LaborCosts";
	ElsIf Not DistributionBasesByGroups.MaterialAndLaborCosts.Find(AllocationBase) = Undefined Then
		Return "MaterialAndLaborCosts";
	EndIf;
	
	Return "";
	
EndFunction

&AtClientAtServerNoContext
Function DistributionBasesByGroups()
	
	UsedMaterials = New Array;
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.MaterialCostsAmount"));
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials"));
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials"));
	UsedMaterials.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials"));
	
	LaborCosts = New Array;
	LaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses"));
	LaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel"));
	LaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds"));
	
	MaterialAndLaborCosts = New Array;
	MaterialAndLaborCosts.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts"));

	DatabaseGroups = New Structure;
	DatabaseGroups.Insert("UsedMaterials", UsedMaterials);
	DatabaseGroups.Insert("LaborCosts", LaborCosts);
	DatabaseGroups.Insert("MaterialAndLaborCosts", MaterialAndLaborCosts);
	
	Return DatabaseGroups;
	
EndFunction

#EndRegion
#Region ControlOfChangesInBankingDetails

&AtClient
Procedure ProcessChangesToBankingDetails(Var_AttributeName)
	
	If Var_AttributeName = "AllocationIndicator" Then
		ProcessChangeOfDistributionIndicator();
	ElsIf Var_AttributeName = "AllocationDirection" Then
		HandleChangeOfDistributionDirection();
	ElsIf Var_AttributeName = "SettingsOfBaseOfAllocationByLots" Then
		ProcessChangesToDistributionDatabaseSettingsByBatch();
	EndIf;
	
EndProcedure

&AtClient
Function ClearDependentProps(Var_AttributeName)
	
	StructureOfDependentProps = DependentDetails(Var_AttributeName);
	
	For Each FormAttribute In StructureOfDependentProps.FormAttributes Do
		
		If TypeOf(ThisForm[FormAttribute]) = Type("FormDataCollection") Then
			ThisForm[FormAttribute].Clear();
		ElsIf TypeOf(ThisForm[FormAttribute]) = Type("DataCompositionSettingsComposer") Then
			LoadBasicComposerSettings(FormAttribute);
		Else
			ThisForm[FormAttribute] = Undefined;
		EndIf;
		
		ProcessChangesToBankingDetails(FormAttribute);
		
	EndDo;
	
	For Each ObjectAttribute In StructureOfDependentProps.ObjectAttributes Do
		
		If TypeOf(Object[ObjectAttribute]) = Type("FormDataCollection") Then
			Object[ObjectAttribute].Clear();
		Else
			Object[ObjectAttribute] = Undefined;
		EndIf;
		
		ProcessChangesToBankingDetails(ObjectAttribute);
		
	EndDo;
	
	Return StructureOfDependentProps;
	
EndFunction

&AtClient
Function DependentDetails(Attribute)
	
	FormAttributes = New Array;
	ObjectAttributes = New Array;
	
	If Attribute = "AllocationDirection" Then
		
		FormAttributes.Add("FilterByLinesOfBusiness");
		ObjectAttributes.Add("LinesOfBusiness");
		
		If Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.ByRates") Then
			FormAttributes.Add("AllocationIndicator");
		EndIf;
		
	ElsIf Attribute = "AllocationIndicator" Then
		

		ObjectAttributes.Add("BaseOfAllocationByLots");
	ElsIf Attribute = "BaseOfAllocationByLots" Then
		
		FormAttributes.Add("SettingsOfBaseOfAllocationByLots");
	EndIf;
	
	Return New Structure("FormAttributes, ObjectAttributes", FormAttributes, ObjectAttributes);
		
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure DetermineVisibilityAndAmountOfExpensesForArticle()
	
	Query = New Query("
		|SELECT TOP 1
		|	*
		|FROM
		|	AccumulationRegister.RegisterRecordsProductsIncomeExpenses.Turnovers(
		|			&StartDate,
		|			&EndDate,
		|			,
		|			IncomeAndExpenseItem = &AssetRef
		|				AND DimensionOfExpenses = &Dimension) AS RegisterRecords");
	
	Query.SetParameter("AssetRef", Object.ExpenseItem);
	Query.SetParameter("Dimension", Object.DimensionOfExpenses);
	Query.SetParameter("StartDate", BegOfMonth(Object.Date));
	Query.SetParameter("EndDate", EndOfMonth(Object.Date));
	
	SetPrivilegedMode(True);
	
	ThereAreRevolutionsOnArticle = Not Query.Execute().IsEmpty();
	If Not ThereAreRevolutionsOnArticle Then
		Items.AmountsGroup.Visible = True;
		Items.GroupWithoutAmounts.Visible = False;
	Else
		Items.AmountsGroup.Visible = False;
		Items.GroupWithoutAmounts.Visible = True;
	EndIf;
	
	If ThereAreRevolutionsOnArticle Then
		Return;
	EndIf;
	
	SupportedDistributionOptions = New Array();
	SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
	SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	
	Query = New Query;
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextReceivedOtherExpenses() + "
		|SELECT
		|	T.Sum,
		|	T.SumCompl,
		|	T.CostTD
		|FROM
		|	ExpenseForAllocation AS T
		|WHERE
		|	T.ExpenseItem = &AssetRef
		|	AND T.DimensionOfExpenses = &Dimension
		|	AND T.LineOfBusiness = &LineOfBusiness";
	
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Object.Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Object.Date));
	Query.SetParameter("BorderEndOfPeriod", New Boundary(EndOfMonth(Object.Date), BoundaryType.Including));
	Query.SetParameter("CompanyArray", Object.Organization);
	Query.SetParameter("DepartmentList", Object.Department);
	Query.SetParameter("ByAllCompanies", False);
	Query.SetParameter("ByAllBusinessUnits", False);
	Query.SetParameter("AssetRef", Object.ExpenseItem);
	Query.SetParameter("Dimension", Object.DimensionOfExpenses);
	Query.SetParameter("LineOfBusiness", Object.LineOfBusiness);
	Query.SetParameter("CostAllocationOptions", SupportedDistributionOptions);
	
	
	Selection = Query.Execute().Select();
	
	TemplateOfPresentation = NStr("vi = '%1 (%2)';
									|ru = '%1 (%2)';
									|en = '%1 (%2)'; fa = '%1 (%2)';
									|it = '%1 (%2)';
									|pl = '%1 (%2)';
									|tr = '%1 (%2)'");
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Sum = 0;
	SumCompl = 0;
	CostTD = 0;
	
	If Selection.Next() Then
		Sum = Selection.Sum;
		SumCompl = Selection.SumCompl;
		CostTD = Selection.CostTD;
	EndIf;
	
	Items.Sum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation,
		Sum,
		CurrencyOfMan);
	Items.SumCompl.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation,
		SumCompl,
		ComplCurrency);
	Items.AmountTemporaryDifferences.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfPresentation,
		CostTD,
		ComplCurrency);

	Items.ReglGroup.Visible = (Not SumCompl = 0);
	Items.BPGroup.Visible = 
		AccountingPoliciesTaxSettingsLocalization.CalculationOfPermanentAndTemporaryDifferencesIsKept(Object.Organization, Object.Date)
		And Not CostTD = 0;
EndProcedure

&AtServerNoContext
Function DetermineValueOfDistributionIndicator(Base)
	
	If Base = Enums.TypesOfCostAllocatingBase.GrossProfit Then
		Return "GrossProfit";
	EndIf;
	
	If Base = Enums.TypesOfCostAllocatingBase.SaleCost Then
		Return "SaleCost";
	EndIf;
	
	If Base = Enums.TypesOfCostAllocatingBase.SalesRevenue Then
		Return "SalesRevenue";
	EndIf;
	If ValueIsFilled(Base) Then
		Return "DirectCosts";
	EndIf;
	Return "";
	
EndFunction

&AtServerNoContext
Function ListOfSimilarRelevantLinesOfBusiness(Text, DocumentDate)
	
	Query = New Query;
	
	Query.SetParameter("Description", Text + "%");
	Query.SetParameter("BeginOfPeriod", BegOfMonth(DocumentDate));
	Query.SetParameter("EndOfPeriod",  EndOfMonth(DocumentDate));
	
	Query.Text = "SELECT ALLOWED TOP 7
	|	LinesOfBusiness.Ref
	|FROM
	|	Catalog.LinesOfBusiness AS LinesOfBusiness
	|WHERE
	|	((LinesOfBusiness.StartDateOfActivity <= &EndOfPeriod
	|		OR LinesOfBusiness.StartDateOfActivity = DATETIME(1, 1, 1))
	|	AND (LinesOfBusiness.EndDateOfActivity >= &BeginOfPeriod
	|		OR LinesOfBusiness.EndDateOfActivity = DATETIME(1, 1, 1))
	|	AND LinesOfBusiness.Description LIKE &Description)";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtServerNoContext
Function LineOfBusinessIsRelevant(LineOfBusiness, DocumentDate)
	
	Query = New Query;
	
	Query.SetParameter("Ref", LineOfBusiness);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(DocumentDate));
	Query.SetParameter("EndOfPeriod",  EndOfMonth(DocumentDate));
	
	Query.Text = "SELECT ALLOWED
	|	LinesOfBusiness.Ref
	|FROM
	|	Catalog.LinesOfBusiness AS LinesOfBusiness
	|WHERE
	|	((LinesOfBusiness.StartDateOfActivity <= &EndOfPeriod
	|		OR LinesOfBusiness.StartDateOfActivity = DATETIME(1, 1, 1))
	|	AND (LinesOfBusiness.EndDateOfActivity >= &BeginOfPeriod
	|		OR LinesOfBusiness.EndDateOfActivity = DATETIME(1, 1, 1))
	|	AND LinesOfBusiness.Ref = &Ref)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServerNoContext
Function EmptyLineOfBusiness()
	Return Catalogs.LinesOfBusiness.EmptyRef();
EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.DateByDatabase);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
