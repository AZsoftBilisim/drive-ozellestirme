#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases);
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases);
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases);
	Items.BaseOfAllocationByLots.ChoiceList.Add(
		Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases);		
	ItemsAndDimensionsSelectionParameters = Catalogs.CostAllocationRules.ItemsAndDimensionsSelectionParameters(
		Object.AssignRule);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Catalogs.CostAllocationRules.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	If Object.Ref.IsEmpty() Then
		InitializeTheForm();
	EndIf;
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	InitializeTheForm();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	

	Object.BaseOfAllocationByBusinessUnits = Undefined;
	Object.BusinessUnitsAreSpecifiedManually = False;
	
	If MethodOfDivisionDistribution = "ByIndicator" Then
		If ValueIsFilled(Object.Factor) Then
			Object.BaseOfAllocationByBusinessUnits = 
				GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Factor, "AllocationBase");
		Else
			Object.BaseOfAllocationByBusinessUnits = PredefinedValue("Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis");
		EndIf;
	ElsIf MethodOfDivisionDistribution = "Manually" Then
		Object.BusinessUnitsAreSpecifiedManually = True;
	ElsIf ValueIsFilled(MethodOfDivisionDistribution) Then
		
		Base = PredefinedValue("Enum.TypesOfCostAllocatingBase." + MethodOfDivisionDistribution);
		Object.BaseOfAllocationByBusinessUnits = Base;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	If Object.SettingsOfBaseOfAllocationByLotsChanged Then
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(
			SettingsOfBaseOfAllocationByLots.GetSettings());
	Else
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(Undefined);
	EndIf;

	If Object.AllocationDirectionSettingsChanged Then
		CurrentObject.AllocationDirectionSettings = New ValueStorage(
			AllocationDirectionSettings.GetSettings());
	Else
		CurrentObject.AllocationDirectionSettings = New ValueStorage(Undefined);
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	SetItemsAvailability(ThisForm);
	SetItemsVisibility(ThisForm);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region EventHandlersDistributionRules

&AtClient
Procedure AllocateByLotsOnChange(Item)
	
	If Not Object.AllocateByLots Then
		SpecifyChangingBankingDetails("AllocateByLots");
	Else
		ProcessChangeDistributeItInBatches();
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsAreSpecifiedInDocumentOnChange(Item)
	
	SpecifyChangingBankingDetails("LotsAreSpecifiedInDocument")
	
EndProcedure

&AtClient
Procedure AllocateToExpenseItemsOnChange(Item)
	
	If Not Object.AllocateToExpenseItems Then
		SpecifyChangingBankingDetails("AllocateToExpenseItems");
	Else
		ProcessChangeDistributeToArticles();
	EndIf;
	
EndProcedure

&AtClient
Procedure CostShareForProductionOnChange(Item)
	
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtClient
Procedure AllocationDirectionOnChange(Item)
	
	HandleChangeOfDistributionDirection();
	
EndProcedure

&AtClient
Procedure MethodOfDivisionDistributionOnChange(Item)
	
	HandleChangingDistributionMethod();
	
EndProcedure

&AtClient
Procedure UseAllocationByDepartmentsOnChange(Item)
	
	ProcessChangeUseDivisionAllocation();
	
EndProcedure

&AtClient
Procedure BaseOfAllocationByLotsOnChange(Item)
	
	ProcessChangeInDistributionBaseByBatch();
	
EndProcedure

&AtClient
Procedure TextAddEditSelectionOfTheBatchDistributionDatabaseClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.BaseOfAllocationByLots.ChoiceList.FindByValue(Object.BaseOfAllocationByLots) = Undefined Then 
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
		
		OpenSelectionSettingsForm(OpeningParameters, NStr("vi = 'Tùy chỉnh bộ lọc cơ sở phân bổ';
															|ru = 'Настройка отбора базы распределения';
															|en = 'Allocation base filter settings'; fa = 'Allocation base filter settings';
															|it = 'Impostare la selezione della base di ripartizione';
															|pl = 'Ustawienie wyboru podstawy podziału';
															|tr = 'Tahsisat tabanının filtre ayarı'"));

EndProcedure

&AtClient
Procedure TextAddEditSelectionDistributionDirectionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
		OpeningParameters = ParametersForOpeningSelectionSettings();
		OpeningParameters.SchemaName = "AllocationDirection";
		OpeningParameters.NameOfComposerSettings = "AllocationDirectionSettings";
		
		OpenSelectionSettingsForm(OpeningParameters, NStr("vi = 'Tùy chỉnh lọc bộ phận';
															|ru = 'Настройка отбора подразделений';
															|en = 'Operating units filter settings'; fa = 'Operating units filter settings';
															|it = 'Impostazione della selezione di reparti';
															|pl = 'Ustawienie wyboru działów';
															|tr = 'Departman filtre ayarı'"));
	
EndProcedure

&AtClient
Procedure TextAddChangeFilterByManufacturedProductsBatchesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepartments

&AtClient
Procedure DepartmentsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		UpdateCostShares(ThisForm);
	EndIf;

EndProcedure

&AtClient
Procedure DepartmentsAfterDeleteRow(Item)
	
	UpdateCostShares(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWriteOff

&AtClient
Procedure WriteOffExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WriteOffExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure WriteOffSelection(Item, RowSelected, Field, StandardProcessing)
	
	// Setting up accounting accounts.
	If Field = Items.WriteOffTransactionRecordingPresentation Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	EndIf;
EndProcedure

&AtClient
Procedure WriteOffOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.WriteOff.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.WriteOff");
	
	If NewRow And Copy Then
		// Setting up accounting accounts.
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteOffOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		UpdateCostShares(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteOffAfterDeleteRow(Item)
	
	UpdateCostShares(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure WriteOffDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
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

#Region DetailsChangeHandlers

&AtClient
Procedure ProcessChangeDistributeItInBatches()
	
	If Not Object.AllocateByLots Then
		ClearDependentProps("AllocateByLots");
	Else
		CustomizeFieldDesign(ThisForm);
	EndIf;
	
	SetItemsAvailability(ThisForm, "AllocateByLots");
	
EndProcedure

&AtClient
Procedure ProcessChangeToRefineBatchInDocument()
	
	ClearDependentProps("LotsAreSpecifiedInDocument");
	
	SetItemsAvailability(ThisForm, "LotsAreSpecifiedInDocument");
	EstablishAvailabilityOfShareOfCostOfProduction(ThisForm);
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtClient
Procedure ProcessChangeUseDivisionAllocation()

	Object.AllocateToBusinessUnits = Not IsBlankString(UseAllocationByDepartments);
	If Not Object.AllocateToBusinessUnits Then
		ClearDependentProps("UseAllocationByDepartments");
	EndIf;
	
	CustomizeFieldDesign(ThisForm);
	SetItemsAvailability(ThisForm, "UseAllocationByDepartments");
		
EndProcedure

&AtClient
Procedure ProcessChangeDistributeToArticles()
	
	If Not Object.AllocateToExpenseItems Then
		ClearDependentProps("AllocateToExpenseItems");
	EndIf;
	
	SetItemsAvailability(ThisForm, "AllocateToExpenseItems");
	EstablishAvailabilityOfShareOfCostOfProduction(ThisForm);
	CustomizeFieldDesign(ThisForm);
	
EndProcedure

&AtClient
Procedure HandleChangeOfDistributionDirection()
	
	ClearDependentProps("AllocationDirection");
	
	If (Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit")
		Or Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Superior"))
		And Object.AllocateToBusinessUnits Then
		
		UseAllocationByDepartments = "";
		ProcessChangeUseDivisionAllocation();
		
	EndIf;
	
	SetItemsAvailability(ThisForm, "AllocationDirection");
	SetItemsVisibility(ThisForm, "AllocationDirection");
	
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

&AtServer
Procedure HandleChangesToDistributionDirectionSettings()
	
		Object.AllocationDirectionSettingsChanged = FilterIs_Specified(
			AllocationDirectionSettings);
	Modified = Max(Modified, Object.AllocationDirectionSettingsChanged);

	ConfigureFieldHeaders(ThisForm, "SelectionOfDistributionDirection");

EndProcedure


&AtClient
Procedure HandleChangingDistributionMethod()
	
	Object.BusinessUnitsAreSpecifiedManually = MethodOfDivisionDistribution = "Manually";
	
	ClearDependentProps("MethodOfDivisionDistribution");
	
	SetItemsVisibility(ThisForm, "MethodOfDivisionDistribution");
	SetItemsAvailability(ThisForm, "MethodOfDivisionDistribution");
	SetPageVisibility(ThisForm, "MethodOfDivisionDistribution");
	CustomizeFieldDesign(ThisForm);
		
EndProcedure

#EndRegion

#Region FormControl

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
			
EndProcedure

&AtClientAtServerNoContext
Procedure SetPageVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	
	// Divisions.
	If AttributeName = Undefined Or AttributeName = "MethodOfDivisionDistribution" Then
		Items.ByDepartmentsManually.Visible = Form.MethodOfDivisionDistribution = "Manually";
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form, AttributeName = Undefined)
	
	Items = Form.Items;

	If AttributeName = "MethodOfDivisionDistribution" Or AttributeName = Undefined Then
		Items.Factor.Visible = Form.MethodOfDivisionDistribution = "ByIndicator";
		If ValueIsFilled(Form.Object.Ref) Then
			Items.Factor.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByFO()
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Form, AttributeName = Undefined)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If AttributeName = Undefined Or AttributeName = "AllocateByLots" Then
		
		Items.PageOnTheParty.Enabled = Object.AllocateByLots;
		Items.LotsAreSpecifiedInDocument.Enabled = Object.AllocateByLots;
		
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "LotsAreSpecifiedInDocument" Then
		Items.PageOnTheParty.Enabled = Object.AllocateByLots And Not Object.LotsAreSpecifiedInDocument;
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "UseAllocationByDepartments" Then
		Items.MethodOfDivisionDistribution.ReadOnly = 
			Not Object.AllocateToBusinessUnits;
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "MethodOfDivisionDistribution" Then
		Items.Factor.Enabled = ValueIsFilled(Object.Ref);
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "AllocationDirection" Then
		
		Items.UseAllocationByDepartments.ReadOnly = 
			Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit")
			Or Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Superior");
		
	EndIf;
	
	// Other articles.
	If AttributeName = Undefined Or AttributeName = "AllocateToExpenseItems" Then
		Items.ToOtherItems.Enabled = Object.AllocateToExpenseItems;
	EndIf;
	
	EstablishAvailabilityOfShareOfCostOfProduction(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfShareOfCostOfProduction(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Object.AllocateByLots 
		And Object.AllocateToExpenseItems
		And Not (Form.MethodOfDivisionDistribution = "Manually" Or Object.LotsAreSpecifiedInDocument) Then
		Items.CostShareForProduction.ReadOnly = False;
	Else
		Items.CostShareForProduction.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeFieldDesign(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.BaseOfAllocationByLots.MarkIncomplete = Object.AllocateByLots 
		And Not Object.LotsAreSpecifiedInDocument And Not ValueIsFilled(Object.BaseOfAllocationByLots);
		
	Items.MethodOfDivisionDistribution.MarkIncomplete = Object.AllocateToBusinessUnits 
		And Not ValueIsFilled(Form.MethodOfDivisionDistribution);
				
	Items.CostShareForProduction.MarkIncomplete = Not Items.CostShareForProduction.ReadOnly
		And Not ValueIsFilled(Object.CostShareForProduction);
		
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
	
	If AttributeName = "SelectionOfDistributionDirection" 
		Or AttributeName = Undefined Then
		If Object.AllocationDirection = PredefinedValue("Enum.AllocationDirectionByBusinessUnits.Specified") Then
			Form.TextAddEditSelectionDistributionDirection = 
				PresentationOfHyperlinks.Get(Object.AllocationDirectionSettingsChanged);
		Else
			Form.TextAddEditSelectionDistributionDirection = "";
		EndIf;
	EndIf;
	
	If AttributeName = "SelectionOfDistributionBaseByParty" 
		Or AttributeName = Undefined Then
		
			Form.TextAddEditSelectionOfTheBatchDistributionDatabase = 
				PresentationOfHyperlinks.Get(Object.SettingsOfBaseOfAllocationByLotsChanged);
			
	EndIf;

	
EndProcedure

#EndRegion

#Region InitializeForm

&AtServer
Procedure InitializeTheForm()
	
	FillInServiceDetailsOfForm();
	
	SetPageVisibility(ThisForm);
	SetVisibilityOfElementsByFO();
	SetItemsVisibility(ThisForm);
	SetItemsAvailability(ThisForm);
	CustomizeFieldDesign(ThisForm);
	ConfigureFieldHeaders(ThisForm);
	
	ItemsAndDimensionsSelectionParameters = Catalogs.CostAllocationRules.ItemsAndDimensionsSelectionParameters(
		Object.AssignRule);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Catalogs.CostAllocationRules.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	If Object.BusinessUnitsAreSpecifiedManually Then
		MethodOfDivisionDistribution = "Manually";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis
		Or Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand Then
		MethodOfDivisionDistribution = "ByIndicator";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount Then
		MethodOfDivisionDistribution = "MaterialCostsAmount";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses Then
		MethodOfDivisionDistribution = "TotalPayrollExpenses";
	ElsIf Object.BaseOfAllocationByBusinessUnits = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts Then
		MethodOfDivisionDistribution = "AmountOfMaterialAndLaborCosts";
	EndIf;
	
	If Object.AllocateToBusinessUnits Then
		UseAllocationByDepartments = "UseDifferentBases";
	EndIf;
	
	BatchAccounting21 = Not CalculationOfCostCached.BatchAccountingVersion22();
	CacheBaseOfAllocationByBatches = Object.BaseOfAllocationByLots;
	LoadBasicComposerSettings();
	
	DocumentObject = FormAttributeToValue("Object");
	RestoreComposerSettings("SettingsOfBaseOfAllocationByLots", DocumentObject);
	RestoreComposerSettings("AllocationDirectionSettings", DocumentObject);
	
EndProcedure

#EndRegion

#Region Filters


// Creates a structure with parameters for opening the configure selection of the distribution database form.
// Returns:
//	Structure - parameters for opening the selection form.
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
	If Var_Parameters.SchemaName = "AllocationDirection" Then
		Schema = Catalogs.CostAllocationRules.GetTemplate(Var_Parameters.SchemaName);
	Else
		Schema = Enums.TypesOfCostAllocatingBase.GetTemplate(Var_Parameters.SchemaName);
	EndIf;
	
	If Not GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
		
		ProductGroupField = Schema.DataSets[0].Fields.Find("ProductsGroup"); // DataCompositionSchemaDataSetField
		If Not ProductGroupField = Undefined Then
			
			ProductGroupField.UseRestriction.Condition = True;
			ProductGroupField.AttributeUseRestriction.Condition = True;
			
		EndIf;
		
	EndIf;
	
	Addresses.DataCompositionSchema = PutToTempStorage(Schema, UUID);
	
	Settings = ThisForm[Var_Parameters.NameOfComposerSettings].GetSettings();
	If ValueIsFilled(Settings) Then
		Addresses.DataCompositionSettings = PutToTempStorage(Settings, UUID);
	EndIf;
	
	Return Addresses;
	
EndFunction

&AtServer
Procedure LoadBasicComposerSettings(Var_AttributeName = "")
	
	If Var_AttributeName = "AllocationDirectionSettings" 
		Or Var_AttributeName = "" Then
		
		CompositionSchema = Catalogs.CostAllocationRules.GetTemplate("AllocationDirection");
		AllocationDirectionSettings.LoadSettings(CompositionSchema.DefaultSettings);
	
	EndIf;
	
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
	
	SettingsModifier = StrTemplate("%1Changed", PropsNameWithSettings);
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
	
	For Each DataParameter In ComposerSettings.DataParameters.Items Do
		
		If (TypeOf(DataParameter.Value) = Type("Boolean") 
			And DataParameter.Value) Or FilterIs_Specified Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return FilterIs_Specified;
	
EndFunction

#EndRegion

#Region UserInteraction

&AtClient
Procedure SpecifyChangingBankingDetails(Var_AttributeName, NeedToAskQuestion = False)
	
	If Not NeedToAskQuestion Then
		
		// The parameter is not passed. So you need to determine whether you need to ask a question or not.
		
		StructureOfDependentProps = DependentDetails(Var_AttributeName);
		
		For Each FormAttribute In StructureOfDependentProps.FormAttributes Do
			
			If TypeOf(ThisForm[FormAttribute]) = Type("Boolean") And ThisForm[FormAttribute] = True
				Or Not TypeOf(ThisForm[FormAttribute]) = Type("Boolean") And ValueIsFilled(ThisForm[FormAttribute]) Then
				
				NeedToAskQuestion = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If Not NeedToAskQuestion Then
			For Each ObjectAttribute In StructureOfDependentProps.ObjectAttributes Do
				
				If TypeOf(Object[ObjectAttribute]) = Type("Boolean") And Object[ObjectAttribute] = True
					Or Not TypeOf(Object[ObjectAttribute]) = Type("Boolean") And ValueIsFilled(Object[ObjectAttribute]) Then
					
					NeedToAskQuestion = True;
					Break;
					
				EndIf;
				
			EndDo;
		EndIf;
				
	EndIf;
	
	If NeedToAskQuestion Then
		
		If Var_AttributeName = "AllocateToBusinessUnits" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ đơn vị sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения по подразделениям будут очищены. Продолжить?';
							|en = 'Settings of allocation to business units will be cleared. Continue?'; fa = 'Settings of allocation to business units will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione per reparto verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia według działów zostaną wyczyszczone. Kontynuować?';
							|tr = 'Departmanlara göre dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		ElsIf Var_AttributeName = "AllocateByLots" Or Var_AttributeName = "LotsAreSpecifiedInDocument" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения будут очищены. Продолжить?';
							|en = 'Allocation settings will be cleared. Continue?'; fa = 'Allocation settings will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia zostaną wyczyszczone. Kontynuować?';
							|tr = 'Dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		ElsIf Var_AttributeName = "AllocateToExpenseItems" Then
			QueryText = NStr("vi = 'Cài đặt phân bổ cho các dạng khác sẽ bị xóa. Tiếp tục?';
							|ru = 'Настройки распределения на другие статьи будут очищены. Продолжить?';
							|en = 'Settings of allocation to other items will be cleared. Continue?'; fa = 'Settings of allocation to other items will be cleared. Continue?';
							|it = 'Le impostazioni di ripartizione su altri articoli verranno cancellate. Continuare?';
							|pl = 'Ustawienia przydzielenia na inne pozycje zostaną wyczyszczone. Kontynuować?';
							|tr = 'Diğer kalemlere dağıtım ayarları temizlenecektir. Devam edilsin mi?'");
		EndIf;
		
		NotificationParameters = New Structure("AttributeName", Var_AttributeName);
		
		ShowQueryBox(New CallbackDescription("SpecifyChangingBankingDetailsCompletion", ThisForm, NotificationParameters),
						QueryText,
						QuestionDialogMode.YesNo);
						
		Return;
		
	EndIf;
		
	ProcessChangesToBankingDetails(Var_AttributeName);
	
EndProcedure

&AtClient
Procedure SpecifyChangingBankingDetailsCompletion(QuestionResult, AdditionalParameters) Export
	
	AttributeName = AdditionalParameters.AttributeName;
	
	If QuestionResult = DialogReturnCode.Yes Then
		ProcessChangesToBankingDetails(AttributeName);
	Else
		If AttributeName = "AllocateByLots"
			Or AttributeName = "AllocateToExpenseItems"
			Or AttributeName = "LotsAreSpecifiedInDocument" Then
			Object[AttributeName] = Not Object[AttributeName];
		EndIf;
	EndIf;
	
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
		
	ElsIf Group = "ManufacturedProduct" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCost"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantity"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeight"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolume"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases"));
		
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
	ElsIf Not TypesOfDistributionBasesByGroup("ManufacturedProduct").Find(AllocationBase) = Undefined Then
		Return "ManufacturedProduct";
	ElsIf Not TypesOfDistributionBasesByGroup("MaterialAndLaborCosts").Find(AllocationBase) = Undefined Then
		Return "MaterialAndLaborCosts";
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure UpdateCostShares(Form)
	
	Object = Form.Object;
	
	If Object.BusinessUnitsAreSpecifiedManually Then
		Object.CostShareForProduction = Object.Departments.Total("CostShare");
	EndIf;
	
	Object.CostShareToExpenseItems = Object.WriteOff.Total("CostShare");
	
EndProcedure

&AtClient
Procedure ProcessChangesToBankingDetails(Var_AttributeName)
	
	If Var_AttributeName = "UseAllocationByDepartments" Then
		ProcessChangeUseDivisionAllocation();
	ElsIf Var_AttributeName = "AllocateByLots" Then
		ProcessChangeDistributeItInBatches();
	ElsIf Var_AttributeName = "LotsAreSpecifiedInDocument" Then
		ProcessChangeToRefineBatchInDocument();
	ElsIf Var_AttributeName = "AllocateToExpenseItems" Then
		ProcessChangeDistributeToArticles();
	ElsIf Var_AttributeName = "AllocationDirection" Then
		HandleChangeOfDistributionDirection();
	ElsIf Var_AttributeName = "MethodOfDivisionDistribution" Then
		HandleChangingDistributionMethod();
	ElsIf Var_AttributeName = "SettingsOfBaseOfAllocationByLots" Then
		ProcessChangesToDistributionDatabaseSettingsByBatch();
	ElsIf Var_AttributeName = "AllocationDirectionSettings" Then
		HandleChangesToDistributionDirectionSettings();
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
		
		FormAttributes.Add("AllocationDirectionSettings");
		
	ElsIf Attribute = "LotsAreSpecifiedInDocument" Then
		
		ObjectAttributes.Add("BaseOfAllocationByLots");
		ObjectAttributes.Add("AllocationDirection");
		FormAttributes.Add("UseAllocationByDepartments");
		
	ElsIf Attribute = "BaseOfAllocationByLots" Then
		
		FormAttributes.Add("SettingsOfBaseOfAllocationByLots");
		
	ElsIf Attribute = "AllocateByLots" Then
		
		ObjectAttributes.Add("LotsAreSpecifiedInDocument");
		
	ElsIf Attribute = "AllocateToExpenseItems" Then
		
		If Not (Object.AllocateToExpenseItems Or Object.BusinessUnitsAreSpecifiedManually) Then
			ObjectAttributes.Add("CostShareForProduction");
		EndIf;
		
		ObjectAttributes.Add("WriteOff");
		ObjectAttributes.Add("CostShareToExpenseItems");
		
	ElsIf Attribute = "UseAllocationByDepartments" Then
		
		ObjectAttributes.Add("AllocateToBusinessUnits");
		FormAttributes.Add("MethodOfDivisionDistribution");
		
	ElsIf Attribute = "MethodOfDivisionDistribution" Then
		
		ObjectAttributes.Add("Factor");
		ObjectAttributes.Add("Departments");
		ObjectAttributes.Add("CostShareForProduction");
	
	EndIf;
	
	Return New Structure("FormAttributes, ObjectAttributes", FormAttributes, ObjectAttributes);
		
EndFunction

#EndRegion

#EndRegion
