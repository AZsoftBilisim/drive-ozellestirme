// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	// Getting parameters
	FillPropertyValues(ThisObject, Parameters,
		"FillingRuleAddress, CustomSettingsAddress, RoundingPrecision, ChangeResultTo, PlanProfile, BeginOfPeriod, PeriodEnding");
	
	If Parameters.Property("FilterPlan_") Then
		FilterPlan_ = Parameters.FilterPlan_;
	EndIf;
	
	DetailsOfPlanType = Common.ObjectAttributesValues(PlanProfile, "PlanType, Owner, NumberOfPeriods,
	|Periodicity, FillInPartnerInTabularForm, FillInAgreementInTabularForm, FillInWarehouseInTabularForm, FillInAssignmentInTabularForm");
	Scenario = DetailsOfPlanType.Owner;
	Periodicity = Common.ObjectAttributeValue(Scenario, "Periodicity");
	
	FillPropertyValues(ThisObject, DetailsOfPlanType, "PlanType, FillInPartnerInTabularForm, FillInAgreementInTabularForm, FillInWarehouseInTabularForm, FillInAssignmentInTabularForm");
	
	CrossTable = True;
	
	If Not ValueIsFilled(BeginOfPeriod) Or Not ValueIsFilled(PeriodEnding) Then
		PlanningClientServer.SetStartEndOfPlanPeriod(
					Periodicity,
					BeginOfPeriod,
					PeriodEnding,
					CurrentSessionDate(),
					DetailsOfPlanType.NumberOfPeriods);
	EndIf;
	
	Planning.CreatePeriodTable(ThisObject, "TimeIntervals");
	
	WhenChangingPeriodsOnServer();
	
	CopyToCrossTable();
	
	ConfigureDependentFormElements();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	FillInPreview();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	WhenChangingPeriodsOnServer();
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	WhenChangingPeriodsOnServer();
EndProcedure

&AtClient
Procedure RowsCountOnChange(Item)
	FillInPreview();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SwitchPeriodsToColumns(Command)
	SwitchPeriodsToColumnsOnServer();
EndProcedure

&AtClient
Procedure SwitchPeriodsToRows(Command)
	SwitchPeriodsToRowsOnServer();
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription(
		"SetDateIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		ThisObject, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "PeriodEnding"),
		Notification);
	
EndProcedure

&AtClient
Procedure UpdatePreview1(Command)
	FillInPreview();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "GoodsByPeriodProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "GoodsByPeriod.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "GoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Goods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																			"GoodsByPeriodCharacteristic",
																			"GoodsByPeriod.ItemVariantsAreUsed");

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																			"GoodsCharacteristic",
																			"Goods.ItemVariantsAreUsed");

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
																			"GoodsByPeriodPurpose",
																			"GoodsByPeriod.ItemsType",
																			False);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
																			"GoodsProductsUnitOfMeasure",
																			"Goods.ItemsType"
																			,False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByPeriodPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByPeriod.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<theo định kỳ>';
													|ru = '<периодическая>';
													|en = '<periodic>'; fa = '<periodic>';
													|it = '<периодическая>';
													|pl = '<periodic>';
													|tr = '<periyodik>'"));

	//

	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfItemTypeField = "Goods.ItemsType";
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	ConditionalDesignParameters.NameOfVTCHWarehouseField = "Goods.Warehouse";

	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.GoodsByPeriodWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "GoodsByPeriod.ItemsType";
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	ConditionalDesignParameters.NameOfVTCHWarehouseField = "GoodsByPeriod.Warehouse";
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsByPeriodWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsByPeriod.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

EndProcedure

&AtServer
Procedure ConfigureDependentFormElements(AttributesList = "")

	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Then
		
		TheseAreSalesByCategory = PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
		
		Items.GoodsProductCategory.Visible           = TheseAreSalesByCategory;
		Items.GoodsByPeriodProductCategory.Visible = TheseAreSalesByCategory;
		
		Items.GoodsProducts.Visible           = Not TheseAreSalesByCategory;
		Items.GoodsByPeriodProducts.Visible = Not TheseAreSalesByCategory;
		
		Items.GoodsCharacteristic.Visible           = Not TheseAreSalesByCategory;
		Items.GoodsByPeriodCharacteristic.Visible = Not TheseAreSalesByCategory;
		
		Items.GoodsPackagingUnitOfMeasure.Visible           = Not TheseAreSalesByCategory;
		Items.ProductsByPeriodPackageUnitOfMeasurement.Visible = Not TheseAreSalesByCategory;
		
		Items.GoodsWarehouse.Visible           = FillInWarehouseInTabularForm;
		Items.GoodsByPeriodWarehouse.Visible = FillInWarehouseInTabularForm;
		
		Items.GoodsPartner.Visible           = FillInPartnerInTabularForm;
		Items.GoodsByPeriodPartner.Visible = FillInPartnerInTabularForm;
		
		Items.GoodsPurpose.Visible           = FillInAssignmentInTabularForm;
		Items.GoodsByPeriodPurpose.Visible = FillInAssignmentInTabularForm;
		
		Items.GoodsTerms.Visible           = FillInAgreementInTabularForm;
		Items.GoodsByPeriodTerms.Visible = FillInAgreementInTabularForm;
		
		TheseAreLeftovers = PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
		
		Items.PeriodEnding.Visible = Not TheseAreLeftovers;
		
		Items.BeginOfPeriod.Title = ?(TheseAreLeftovers, NStr("vi = 'Ngày số dư dự tính';
																|ru = 'Плановая дата остатков';
																|en = 'Planned balance date'; fa = 'تاریخ مانده برنامه‌ریزی‌شده';
																|it = 'Data programmatica delle rimanenze';
																|pl = 'Planowana data pozostałości';
																|tr = 'Mal stokları için planlanan tarih'"), NStr("vi = 'Kỳ từ';
																									|ru = 'Период с';
																									|en = 'Period from'; fa = 'دوره از';
																									|it = 'Periodo dal';
																									|pl = 'Okres od';
																									|tr = 'Dönem başı'"));
		
		Items.FormGroupPeriods.Visible = Not TheseAreLeftovers;
		
		Items.SetDateInterval.Visible = Not TheseAreLeftovers;
		
		CrossTable = Not TheseAreLeftovers;
		
	EndIf;
	
	If AttributesStructure1.Property("CrossTable") Or Initialize Then
		Items.FormSwitchPeriodsToColumns.Check = CrossTable;
		Items.FormSwitchPeriodsToRows.Check = Not CrossTable;
		
		Items.GoodsByPeriod.Visible = CrossTable;
		Items.Goods.Visible = Not CrossTable;
		
		Items.SearchByPeriodGroup.Visible = CrossTable;
		Items.GroupSearch.Visible = Not CrossTable;
		
		If Not CrossTable Then
			
			PlanByAmount = False;
			If PlanType = Enums.TypesOfPlans.PurchasePlan Then
				PlanByAmount = Common.ObjectAttributeValue(Scenario, "CreatePurchasePlanByAmount")
			ElsIf PlanType = Enums.TypesOfPlans.SalesPlan Then
				PlanByAmount = Common.ObjectAttributeValue(Scenario, "CreateSalesPlanByAmount")
			EndIf;
			
			Items.GoodsPrice.Visible = PlanByAmount;
			Items.GoodsSum.Visible = PlanByAmount;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure SwitchPeriodsToColumnsOnServer()
	
	CrossTable = True;
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	UpdateCrossTableStructure(TablePeriods, True);
	CopyToCrossTable();
	ConfigureDependentFormElements("CrossTable");
	
EndProcedure

&AtServer
Procedure SwitchPeriodsToRowsOnServer()
	
	CrossTable = False;
	FillInServiceDetailsForProductInCollection();
	
	ConfigureDependentFormElements("CrossTable");
	
EndProcedure

&AtClient
Procedure FillInPreview()
	
	NotifyUserAboutStartOfFillingInData(); 
	
	StartWaiting = FillInPreviewOnServer();//Structure
	
	If StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("FillInPreviewCompletion", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		NotifyUserAboutFillingInData();
		
	EndIf;
EndProcedure

// fill in the preview End.
// 
// Parameters:
//  Result - Structure
//  AddlParameters - Structure
&AtClient
Procedure FillInPreviewCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		GetResultOfFillingOnServer(Result);
		
		NotifyUserAboutFillingInData();
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInPreviewOnServer()
	
	JobParameters = New Structure;
	
	PrepareParametersForFillingInPreview(JobParameters);
	
	JobDescription = NStr("vi = 'Điền xem trước quy tắc điền';
							|ru = 'Заполнение предпросмотра правила заполнения';
							|en = 'Fill autofill rule preview'; fa = 'Fill autofill rule preview';
							|it = 'Заполнение предпросмотра правила заполнения';
							|pl = 'Fill autofill rule preview';
							|tr = 'Doldurma kuralı önizlemesinin doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Catalogs.PlanningDataSources.FillInPreview",
		JobParameters,
		TimeConsumingOperations.BackgroundExecutionParameters(UUID));
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartWaiting = True;
		
	Else
		
		GetResultOfFillingOnServer(TimeConsumingOperation);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtServer
Procedure PrepareParametersForFillingInPreview(JobParameters)

	FillingRule = GetFromTempStorage(FillingRuleAddress);
	
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("Scenario",                Scenario);
	JobParameters.Insert("PlanProfile",                PlanProfile);
	JobParameters.Insert("PlanType",                PlanType);
	JobParameters.Insert("CrossTable",            CrossTable);
	JobParameters.Insert("ChangeResultTo",     ChangeResultTo);
	JobParameters.Insert("RoundingPrecision",      RoundingPrecision);
	JobParameters.Insert("Periodicity",           Periodicity);
	JobParameters.Insert("BeginOfPeriod",           BeginOfPeriod);
	JobParameters.Insert("PeriodEnding",        PeriodEnding);
	JobParameters.Insert("Top25",                RowsCount = 0);
	
	JobParameters.Insert("FillInRule",      True);
	JobParameters.Insert("GeneralSettingsKey",       "Catalog.PlanningDataSources.PreviewForm");
	If ValueIsFilled(FilterPlan_) Then
		JobParameters.Insert("Filter", FilterPlan_);
		If FilterPlan_.Property("Warehouse") Then
			JobParameters.Insert("Warehouse", FilterPlan_.Warehouse);
		EndIf;
	EndIf;
	
	Goods.Clear();
	PopulatedTS = Goods.Unload();
	
	Settings = New Structure;
	Settings.Insert("FillingRule", FillingRule);
	Settings.Insert("UserSettings", GetFromTempStorage(CustomSettingsAddress));
	Settings.Insert("PopulatedTS", PopulatedTS);
	Settings.Insert("TimeIntervals", ThisObject.TimeIntervals.Unload());
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
EndProcedure 

// Parameters:
//  Result - Structure - consists of:
//  *Status - String
//  *ResultAddress - String
//  *BriefErrorDescription - String
&AtServer
Procedure GetResultOfFillingOnServer(Result)
	
	If Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.PurchasePlan.Forms.DocumentForm.GetResultOfFillingOnServer");
	
	StorageAddress = Result.ResultAddress;
	
	Table = GetFromTempStorage(StorageAddress);// ValueTable
	
	ProcessedRowsCount = Table.Count();
	
	Goods.Load(Table);
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	UpdateCrossTableStructure(TablePeriods, False);
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement,
		GetAttributes("GoodsByPeriod").Count()/10,
		"UpdateCrossTableStructure");
	
	CopyToCrossTable();
	
	If Not CrossTable Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
			StructureOfActions.Insert("RecalculateAmount");
			
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
		EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedRowsCount);
	
EndProcedure

&AtClient
Procedure NotifyUserAboutStartOfFillingInData()
	
	Status(NStr("vi = 'Đang điền dữ liệu xem trước';
				|ru = 'Выполняется заполнение данных предпросмотра';
				|en = 'Filling preview data'; fa = 'Filling preview data';
				|it = 'Выполняется заполнение данных предпросмотра';
				|pl = 'Filling preview data';
				|tr = 'Önizleme verilerinin doldurulması gerçekleştirildi'"));
	
EndProcedure

&AtClient
Procedure NotifyUserAboutFillingInData()

	ShowUserNotification(
		NStr("vi = 'Đã hoàn thành điền dữ liệu xem trước';
			|ru = 'Заполнение данных предпросмотра завершено';
			|en = 'Preview data is filled'; fa = 'Preview data is filled';
			|it = 'Заполнение данных предпросмотра завершено';
			|pl = 'Preview data is filled';
			|tr = 'Önizleme verilerinin doldurulması tamamlandı'"),
		,
		,
		PictureLib.Information32);

EndProcedure

// Parameters:
//  Period - StandardPeriod
//  AdditionalParameters - Structure
&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export 
	WhenChangingPeriodsOnServer();
EndProcedure

&AtServer
Procedure WhenChangingPeriodsOnServer()
	
	If PlanType = Enums.TypesOfPlans.PlanOfGoodsStock Then
		PeriodEnding = BeginOfPeriod;
	EndIf;
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	Planning.FillInPeriodTable(TablePeriods, Periodicity, BeginOfPeriod, PeriodEnding);
	
	UpdateCrossTableStructure(TablePeriods, True);
	
EndProcedure

&AtServer
Procedure CopyToCrossTable()
	
	If CrossTable Then
		
		ConversionParameters = CrossTableConversionParameters();
		
		For Each TSRow In Goods Do
			If Not ValueIsFilled(TSRow.Date) Then
				TSRow.Date = BeginOfPeriod;
			EndIf;
		EndDo; 
		
		PlanningClientServer.FillInCrossTableFromTable(GoodsByPeriod, Goods, ConversionParameters);
		
		PlanningClientServer.CalculateCrossTableRowNumber(ThisObject, "GoodsByPeriod");
		
	EndIf;
	
	FillInServiceDetailsForProductInCollection();
	
EndProcedure

&AtServer
Function CrossTableConversionParameters()

	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	StructureOfPeriodDetails = New Structure("StartDate","Date");
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Count_","NumberOfPackages");
	AttributesStructure1.Insert("Price_","Price");
	AttributesStructure1.Insert("Sum_","Sum");
	
	GroupFields = ?(PlanType = Enums.TypesOfPlans.SalesPlanByCategories, "ProductCategory", "Products");
	
	GroupFields = GroupFields + ", Characteristic, Purpose, Package";
	
	If FillInWarehouseInTabularForm Then
		GroupFields = GroupFields + ", Warehouse";
	EndIf;
	If FillInAssignmentInTabularForm Then
		GroupFields = GroupFields + ", Purpose";
	EndIf;
	If FillInPartnerInTabularForm Then
		GroupFields = GroupFields + ", Partner";
	EndIf;
	If FillInAgreementInTabularForm Then
		GroupFields = GroupFields + ", Terms";
	EndIf;
	
	StructureOfFinalDetails = New Structure;
	StructureOfFinalDetails.Insert("NumberOfPackages", "NumberOfPackages");
	StructureOfFinalDetails.Insert("Sum", "Sum");
	
	ConversionParameters = New Structure;
	ConversionParameters.Insert("TablePeriods",              TablePeriods);
	ConversionParameters.Insert("Periodicity",               Periodicity);
	ConversionParameters.Insert("StructureOfPeriodDetails",  StructureOfPeriodDetails);
	ConversionParameters.Insert("AttributesStructure1",         AttributesStructure1);
	ConversionParameters.Insert("GroupFields",             GroupFields);
	ConversionParameters.Insert("StructureOfFinalDetails", StructureOfFinalDetails);
	
	Return ConversionParameters;

EndFunction

// Parameters:
// 	TablePeriods - See Planning.TablePeriods
// 	RecalculateTotals_ - Boolean - LongDesc
&AtServer
Procedure UpdateCrossTableStructure(TablePeriods, RecalculateTotals_ = True)
	
	NumberOfPeriods = TablePeriods.FindRows(New Structure("Active_", True)).Count();
	ThisIsOnePeriod = NumberOfPeriods = 1;
	
	Items.GoodsDate.ChoiceList.Clear();
	For Each Period In TablePeriods Do
		If Not Period.Active_ Then
			Continue;
		EndIf; 
		Items.GoodsDate.ChoiceList.Add(BegOfDay(Period.StartDate), Period.Title);
	EndDo; 
	
	PlanByAmount = False;
	If PlanType = Enums.TypesOfPlans.PurchasePlan Then
		PlanByAmount = Common.ObjectAttributeValue(Scenario, "CreatePurchasePlanByAmount")
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlan Then
		PlanByAmount = Common.ObjectAttributeValue(Scenario, "CreateSalesPlanByAmount")
	EndIf;
	
	Items.GoodsByPeriodPrice.Visible = PlanByAmount And Not ThisIsOnePeriod;
	Items.GoodsByPeriodSum.Visible = PlanByAmount And Not ThisIsOnePeriod;
	Items.GoodsByPeriodNumberOfPackages.Visible = Not ThisIsOnePeriod;
	
	If Not CrossTable
		Or ThisIsOnePeriod Then
		TotalByLineByColumn = "";
	EndIf;
	
	OutputParameters = New Structure;
	OutputParameters.Insert("NameOfCrossTableProps", "GoodsByPeriod");
	OutputParameters.Insert("CrossTableFormElement", "GoodsByPeriod");
	OutputParameters.Insert("PeriodsTable", TablePeriods);
	OutputParameters.Insert("Periodicity", Periodicity);
	OutputParameters.Insert("Fields", New Array());
	OutputParameters.Insert("CreatePeriodGroup", PlanByAmount And Not ThisIsOnePeriod);
	
	If Not ThisIsOnePeriod Then
		Planning.AddCrossTableFieldInCommentWithImage(OutputParameters);
	EndIf;
	
	Planning.AddQuantityCrossTableField(OutputParameters, True, Not ThisIsOnePeriod, PlanByAmount Or ThisIsOnePeriod);
	Planning.AddPriceCrossTableField(OutputParameters, PlanByAmount, False);
	ParametersOfAmountField = New Structure("Prefix, Title", "Sum_", NStr("vi = 'Số tiền';
																			|ru = 'Сумма';
																			|en = 'Amount'; fa = 'مبلغ';
																			|it = 'Amount';
																			|pl = 'Amount';
																			|tr = 'Tutar'"));
	Planning.AddAmountCrossTableField(OutputParameters, PlanByAmount And ThisIsOnePeriod, ParametersOfAmountField);
	
	Planning.UpdateCrosstabOutputStructure(ThisObject, OutputParameters);
	
	ValueToFormAttribute(TablePeriods, "TimeIntervals");
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductInCollection()
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
				New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
				New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		?(CrossTable, GoodsByPeriod, Goods), StructureOfActions);
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
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
