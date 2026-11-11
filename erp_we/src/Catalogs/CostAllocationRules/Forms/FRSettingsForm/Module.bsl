#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Items.AllocationIndicator.ChoiceList.Clear();
	Items.AllocationIndicator.ChoiceList.Add("SalesRevenue", NStr("vi = 'Doanh thu bán hàng';
																	|ru = 'Выручка от продаж';
																	|en = 'Sales revenue'; fa = 'درآمد فروش';
																	|it = 'Ricavo dalle vendite';
																	|pl = 'Przychód ze sprzedaży';
																	|tr = 'Satış geliri'"));
	Items.AllocationIndicator.ChoiceList.Add("SaleCost", NStr("vi = 'Giá vốn hàng bán';
																|ru = 'Себестоимость продаж';
																|en = 'COGS'; fa = 'بهای تمام‌شده کالای فروش‌رفته';
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
	If Object.Ref.IsEmpty() Then
		Object.BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.SalesRevenue;
	EndIf;
	
	FillInServiceDetailsOfForm();
	
	SwitchPage(ThisForm);
	SetPageVisibility(ThisForm);
	SetItemsVisibility(ThisForm);
	ConfigureFieldHeaders(ThisForm);
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
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
	If ValueIsFilled(AllocationIndicator)Then
		DatabaseTypeTemplate = "Enum.TypesOfCostAllocatingBase.%1";
		Object.BaseOfAllocationByLots = PredefinedValue(StrTemplate(DatabaseTypeTemplate, AllocationIndicator));
	EndIf;
	
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
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region EventHandlersDistributionRules

&AtClient
Procedure AllocationDirectionOnChange(Item)
	
	HandleChangeOfDistributionDirection();
	
EndProcedure

&AtClient
Procedure AllocationIndicatorOnChange(Item)
	
	ProcessChangeOfDistributionIndicator();
	
EndProcedure

&AtClient
Procedure BaseOfAllocationByLotsOnChange(Item)
	ProcessChangeInDistributionBaseByBatch();
	//the UT has an empty handler.
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
		If OpeningParameters.SchemaName = "MaterialCosts" Then
			OpeningParameters.DoNotConfigureSettings = False;
		EndIf;
	
		OpenSelectionSettingsForm(OpeningParameters, NStr("vi = 'Tùy chỉnh bộ lọc cơ sở phân bổ';
															|ru = 'Настройка отбора базы распределения';
															|en = 'Allocation base filter settings'; fa = 'Allocation base filter settings';
															|it = 'Impostare la selezione della base di ripartizione';
															|pl = 'Ustawienie wyboru podstawy podziału';
															|tr = 'Tahsisat tabanının filtre ayarı'"));

	//the UT has an empty handler.
	Return;

EndProcedure

&AtClient
Procedure TextAddChangeFilterByManufacturedProductsBatchesClick(Item, StandardProcessing)
	StandardProcessing = False;

	//the UT has an empty handler.
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

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
	SwitchPage(ThisForm, "AllocationDirection");
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
			
	Items.PresentationOfTheSpecifiedAreasOfActivity.Title = 
		GenerateFilterPresentation("LinesOfBusiness", Form.FilterByLinesOfBusiness.UnloadValues(), 
			NStr("vi = 'lĩnh vực hoạt động, lĩnh vực hoạt động, lĩnh vực hoạt động';
				|ru = 'направление деятельности, направления деятельности, направлений деятельности';
				|en = 'line of business, lines of business, of lines of business'; fa = 'line of business, lines of business, of lines of business';
				|it = 'settore di attività, settori di attività, dei settori di attività';
				|pl = 'rodzaj działalności, rodzaju działalności, rodzajów działalności';
				|tr = 'iş kolu, iş kolu, iş kolu'"));
		
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
	
	If PropsNameWithSettings = "SettingsOfBaseOfAllocationByLots" Then
		SettingsModifier = "SettingsOfBaseOfAllocationByLotsChanged";
	ElsIf PropsNameWithSettings = "AllocationDirectionSettings" Then
		SettingsModifier = "AllocationDirectionSettingsChanged";
	EndIf;
	
	If Not Object[SettingsModifier] Then
		Return;
	EndIf;

	If DocObject = Undefined Then
		DocObject = FormAttributeToValue("Object");
	EndIf;

	AttributesForComposerSettings = DocObject[PropsNameWithSettings]; // ValueStorage
	ComposerSettings = AttributesForComposerSettings.Get(); // DataCompositionSettings
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

#Region FormControl

&AtClientAtServerNoContext
Procedure SetPageVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	// Divisions.
	If AttributeName = Undefined Or AttributeName = "MethodOfDivisionDistribution"
		Or AttributeName = "AllocationDirection" Then
		Items.Manually.Visible = 
			(Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.ByRates"));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SwitchPage(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Or AttributeName = "AllocationDirection" Then
		
		If Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.ByRates") Then
			Items.GroupPages.CurrentPage = Items.Manually;
		Else
			Items.GroupPages.CurrentPage = Items.Rules;
		EndIf;
		
	EndIf;
	
EndProcedure		

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = "AllocationDirection" Or AttributeName = Undefined Then
		Items.PresentationOfTheSpecifiedAreasOfActivity.Visible = 
			Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Specified");
	EndIf;
	
	If AttributeName = "AllocationIndicator" Or AttributeName = Undefined Then
		Items.GroupBaseDistributionByBatch.Visible = (Form.AllocationIndicator = "DirectCosts");
		Items.DataSource.Visible = Form.AllocationIndicator <> "DirectCosts" And Form.AllocationIndicator <> "";
		If Form.AllocationIndicator <> "DirectCosts" And Form.AllocationIndicator <> "" And Not ValueIsFilled(Object.DataSource) Then
			Object.DataSource = PredefinedValue("Enum.DataSourcesForExpenseAllocation.RevenueAndCOGS");
		EndIf;
	EndIf;
	
EndProcedure


&AtClientAtServerNoContext
Procedure CustomizeFieldDesign(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.BaseOfAllocationByLots.MarkIncomplete = (Form.AllocationIndicator = "DirectCosts")
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
		
		Form.TextAddEditSelectionOfTheBatchDistributionDatabase = NStr("vi = 'Bộ lọc không sử dụng được.';
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
Procedure FillInServiceDetailsOfForm()
	BatchAccounting21 = Not CalculationOfCostCached.BatchAccountingVersion22();
	CacheBaseOfAllocationByBatches = Object.BaseOfAllocationByLots;
	LoadBasicComposerSettings();
	
	
	DocumentObject = FormAttributeToValue("Object");
	RestoreComposerSettings("SettingsOfBaseOfAllocationByLots", DocumentObject);
	FilterByLinesOfBusiness.LoadValues(
		Object.FilterByLinesOfBusiness.Unload(, "LineOfBusiness").UnloadColumn("LineOfBusiness"));
	ProcessSelectionChangesByAreasOfActivity(ThisForm);
	
	AllocationIndicator = DetermineValueOfDistributionIndicator(Object.BaseOfAllocationByLots);
		
EndProcedure

#EndRegion

#Region WorkingWithDatabaseTypes

&AtClientAtServerNoContext
Function TypesOfDistributionBasesByGroup(Group)
	
	TypesOfBases = New Array;
	If Group = "UsedMaterials" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.MaterialCostsAmount"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials"));
		
	ElsIf Group = "LaborCosts" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds"));
		
	ElsIf Group = "MaterialAndLaborCosts" Then
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts"));
	EndIf;
	
	Return TypesOfBases;
	
EndFunction

&AtClientAtServerNoContext
Function NameOfDistributionBaseSchema(AllocationBase)
	
	If Not TypesOfDistributionBasesByGroup("UsedMaterials").Find(AllocationBase) = Undefined Then
		Return "MaterialCosts";
	ElsIf Not TypesOfDistributionBasesByGroup("LaborCosts").Find(AllocationBase) = Undefined Then
		Return "LaborCosts";
	ElsIf Not TypesOfDistributionBasesByGroup("MaterialAndLaborCosts").Find(AllocationBase) = Undefined Then
		Return "MaterialAndLaborCosts";
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure ProcessChangesToBankingDetails(Var_AttributeName)
	
	If Var_AttributeName = "AllocationDirection" Then
		HandleChangeOfDistributionDirection();
	ElsIf Var_AttributeName = "AllocationIndicator" Then
		ProcessChangeOfDistributionIndicator();
	ElsIf Var_AttributeName = "FilterByLinesOfBusiness" Then
		ProcessSelectionChangesByAreasOfActivity(ThisForm);
	ElsIf Var_AttributeName = "SettingsOfBaseOfAllocationByLots" Then
		ProcessChangesToDistributionDatabaseSettingsByBatch();
	ElsIf Var_AttributeName = "BaseOfAllocationByLots" Then
		ProcessChangeInDistributionBaseByBatch();
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

// Returns the first level of dependent details from the passed one.
// Parameters:
//	Attribute - String - name of the Bank account to get dependent Bank details for.
// Returns:
//	Structure - Dependent Details:
//		* FormAttributes - Array - contains the names of dependent Attributes of the form (string).
//		* ObjectAttributes - Array - contains the names of the dependent Attributes of the object (string).
//
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
	ElsIf Attribute = "BaseOfAllocationByLots" Then
		
		FormAttributes.Add("SettingsOfBaseOfAllocationByLots");
	ElsIf Attribute = "AllocationIndicator" Then
		ObjectAttributes.Add("BaseOfAllocationByLots");
	EndIf;
	
	Return New Structure("FormAttributes, ObjectAttributes", FormAttributes, ObjectAttributes);
		
EndFunction

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

#EndRegion

#EndRegion
