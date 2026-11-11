#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Values of form details
	CompositionOfSetOfConstantsOfForm    = TMCommonUse.GetStructureOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = SystemSettingsCached.GetStructureOfParentConstants(CompositionOfSetOfConstantsOfForm);
	
	ExternalParentConstants.Insert("UseOrderSupplyWithAssignment");
	ExternalParentConstants.Insert("NewOnlineARAPAccounting");
	ExternalParentConstants.Insert("GenerateFinancialResult");
	
	WorkMode = New Structure;
	
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm",    New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
		
	Items.OperationAsOutputReference.Visible = False;
	Items.OperationAsOutputReference.Visible = ProductionStagesWereUsedEarlier();
	
	UpdateSettingsOfRoutineTaskCalculationOfProductionSchedule();
	UpdateSettingsForUsingOperationAsOrder();
	
	VariantOfStructureOfProductionOrder = Number(ConstantsSet.DynamicStructureOfProductionOrders);
	SetFormItemsVisibility();
	ConfigureDependentFormElements();
	SystemSettingsLocalization.WhenCreatedOnServer_Production(ThisForm);
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return; // such events are not processed
	EndIf;
	
	// If it is a changed constant located in a different form and affecting the values of the constants of this form,
	// then we will read the values of the constants and update the elements of this form.
	If WorkMode.ExternalParentConstants.Property(Source)
		
		Or (TypeOf(Parameter) = Type("Structure")
			And TMCommonUseClientServer.GetSharedKeysOfStructures(
				Parameter, WorkMode.ExternalParentConstants).Count() > 0)
				
		Or (TypeOf(Source) = Type("String")
			And Find(Source, "UseProductionManagement") > 0)
		
		Or (TypeOf(Source) = Type("String")
			And Find(Source, "UseBatchAccounting") > 0)
		
		Or (TypeOf(Source) = Type("String")
			And Find(Source, "BatchAccountingVersion22") > 0)
			
		Or (TypeOf(Source) = Type("String")
			And Find(Source, "UseSeveralPriceTypes") > 0)
		Or (TypeOf(Source) = Type("String")
			And Find(Source, "UseRouteSheets") > 0)
		Or (TypeOf(Source) = Type("String")
			And Find(Source, "UseAdditionalAttributesAndInfo") > 0) Then
		
		ThisForm.Read();
		ConfigureDependentFormElements();
		UpdateSettingsOfRoutineTaskCalculationOfProductionSchedule();
	EndIf;
	
	If Source = ThisForm Then
		If Parameter.Property("Item") Then
			Attachable_OnChangeAttribute(Parameter.Item, True, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DefaultValues = New Structure(
		"ProductionManagementMethod,OptionOfMaterialAssignmentInProduction,DynamicStructureOfProductionOrders");
	SystemSettingsLocalization.WhenReadingOnServer_Production(ThisForm);
	
	TMCommonUseClientServer.SaveValuesBeforeChanging(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionManagementMethodOnChange(Item)
	If ConstantsSet.ProductionManagementMethod.IsEmpty() Then
		TMCommonUseClientServer.RestoreValuesBeforeChange(ThisForm, "ProductionManagementMethod");
		Return;
	EndIf;
	TMCommonUseClientServer.SaveValuesBeforeChanging(ThisForm, "ProductionManagementMethod");
	If ConstantsSet.DynamicStructureOfProductionOrders
		And ConstantsSet.ProductionManagementMethod = PredefinedValue("Enum.ProductionManagementMethod.WithoutCalculationOfProductionSchedule") Then
		// Processing of existing tasks for calculating the structure and schedule of orders
		StartCalculationOfOrderStructure();
	EndIf;
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure DoNotCloseProductionOrdersWithoutFullProcessingOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure UsePlanningIntervalHourOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure UseBOMAssignmentParametersOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure UseAlternativeMaterialsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseApprovalOfEngineeringChangeOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseStatusesOfInternalWorksAcceptanceOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure UseStatusesOfProductsAndMaterialsMovementsOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure TheCalculationOfScheduleProductionUseOnChange(Item)
	SetScheduledJobUsage();
	Return;
	
EndProcedure

&AtClient
Procedure TheOptionOfSeparationIfYouChange(Item)
	Attachable_OnChangeAttribute(Item, True);
EndProcedure

&AtClient
Procedure SeparationOptionCleaningUp(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure CurrencyOfActivityKindRatesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TypeOfPriceOfThePlannedCostOfExpensesWhenChanging(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseKindsOfSpecificTechnologicalOperationsOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, True);
	
EndProcedure

&AtClient
Procedure UseOperationExecutionControlOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, True);
	
EndProcedure

&AtClient
Procedure ControlOperationCompletionWhenClosingProductionStagesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure OperationAsOutputReferenceOnChange(Item)
	SetOperationAsProductionOrder(UseProductionOperationsAsReferencesForOutput);
	Return;
	
EndProcedure

&AtClient
Procedure AccountingForLaborCostsByEmployeesOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure StartDateOfRecordKeepingOfLaborCostsForEmployeesOnChange(Item)
	
	ConstantsSet.StartDateOfRecordKeepingOfLaborCostsForEmployees = BegOfMonth(ConstantsSet.StartDateOfRecordKeepingOfLaborCostsForEmployees);
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure OptionForStoringOperationsHandlingNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("DataProcessor.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.Form.Form");
	
EndProcedure

&AtClient
Procedure AnalyticalAccountingByProductsGroupsOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseKitsInProductionOnChange(Item)
	
	ConstantsSet.SourceOfCompositionOfSetsInProduction = ?(UseKitsInProduction,
		Items.SourceOfCompositionOfSetsInProduction.ChoiceList[0].Value,
		PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.DontUse"));
	
	Attachable_OnChangeAttribute(Items.SourceOfCompositionOfSetsInProduction);
	
EndProcedure

&AtClient
Procedure SourceOfCompositionOfSetsInProductionOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure SourceOfCompositionOfSetsInProductionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	If ConstantsSet.SourceOfCompositionOfSetsInProduction = PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.Specifications") Then
		QueryText = Items.SourceOfCompositionOfSetsInProduction.WarningOnEdit + NStr("vi = '
		|Tiếp tục chỉnh sửa?';
		|ru = '
		|Продолжить редактирование?';
		|en = '
		|Continue editing?'; fa = '
		|Continue editing?';
		|it = '
		|Continuare la modifica?';
		|pl = '
		|Kontynuować edycję?';
		|tr = '
		|Düzenlemeye devam et?'");
		ShowQueryBox(
			New CallbackDescription("SourceOfCompositionOfSetsInProductionStartChoiceCompletion", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
	Else
		SourceOfCompositionOfSetsInProductionSelectValue();
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure VariantOfStructureOfProductionOrderWhenChanging(Item)
	ListOfParametersToChange = New Structure;
	NeedDialogue = False;
	
	If Boolean(VariantOfStructureOfProductionOrder) Then
		
		If ConstantsSet.ProductionManagementMethod = PredefinedValue("Enum.ProductionManagementMethod.DemandPlanningForMaterials") Then
			ListOfParametersToChange.Insert("ProductionManagementMethod", PredefinedValue("Enum.ProductionManagementMethod.SchedulingOfResourcesForProduction"));
		EndIf;

		If ConstantsSet.OptionOfMaterialAssignmentInProduction = PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.ProductionStage") Then
			NeedDialogue = True;
			ListOfParametersToChange.Insert("OptionOfMaterialAssignmentInProduction", PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder"));
		EndIf;
		
	EndIf;
	
	If NeedDialogue Then
		
		AdditionalParameters = New Structure("Item, ListOfParametersToChange", Item, ListOfParametersToChange);
		CallbackDescription = New CallbackDescription("QuestionSetAssociatedSettingsWhenChangingVariantOfProductionOrderStructure", ThisObject, AdditionalParameters);
		QueryText = NStr("vi = 'Để bật sử dụng cấu trúc đơn hàng ""động"", cần thiết lập phương án đặt riêng trong đơn hàng sản xuất với giá trị ""Theo đơn hàng sản xuất"". Đặt và tiếp tục?';
						|ru = 'Для включения ""динамической"" структуры заказа требуется установить вариант обособления при заказе в производство в значение ""По заказам на производство"". Установить и продолжить?';
						|en = 'To enable the dynamic structure of the order, the assignment option for a production order must have the ""By production orders"" value. Do you want to set the value and continue?'; fa = 'To enable the dynamic structure of the order, the assignment option for a production order must have the ""By production orders"" value. Do you want to set the value and continue?';
						|it = 'Для включения ""динамической"" структуры заказа требуется установить вариант обособления при заказе в производство в значение ""По заказам на производство"". Установить и продолжить?';
						|pl = 'To enable the dynamic structure of the order, the assignment option for a production order must have the ""By production orders"" value. Do you want to set the value and continue?';
						|tr = '""Dinamik"" bir sipariş yapısını etkinleştirmek için, üretime sipariş verirken ilişkilendirme seçeneğini ""Üretim emirlerine göre"" olarak ayarlanması gerekir. Ayarlansın ve devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	SetAssociatedSettingsWhenChangingVariantOfProductionOrderStructure(ListOfParametersToChange);
	Attachable_OnChangeAttribute(Item);
	TMCommonUseClientServer.SaveValuesBeforeChanging(ThisForm, "DynamicStructureOfProductionOrders");
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateProductionScheduleTimetable(Command)
	If CreateProductionScheduleTimetable = Undefined Then
		CreateProductionScheduleTimetable = New JobSchedule;
	EndIf;
	CallbackDescription = New CallbackDescription("CreateProductionScheduleTimetableCompletion", ThisObject);
	ScheduleDialog1 = New ScheduledJobDialog(CreateProductionScheduleTimetable);
	ScheduleDialog1.Show(CallbackDescription);
	Return;
	
EndProcedure

&AtClient
Procedure CreateProductionScheduleTimetableCompletion(Schedule, AdditionalParameters = Undefined) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	CreateProductionScheduleTimetable = Schedule;
	
	SetJobSchedule();
	
EndProcedure

&AtClient
Procedure UseTheOptionsOnTheDestinationSpecificationsSetting(Command)
	OpenForm("DataProcessor.BOMAssignmentParameters.Form.FormSettings");
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure CalculationSettingsForProductionOrderStructure(Command)
	OpenForm("CommonForm.CalculationSettingsForProductionOrderStructure");
	Return; // in UT and KA the handler is empty

EndProcedure

&AtClient
Procedure AssignThoseResponsibleForApprovingPermitsForReplacementOfMaterials(Command)
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
		New Structure("MainAddressingObject, Role",
			Undefined, 
			PredefinedValue("Catalog.PerformerRoles.ApprovingPermitsForReplacementOfMaterials")));
	Return; // in UT and KA the handler is empty

EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True, ExternalUpdate = False)
	
	If Not ExternalUpdate Then
		SystemSettingsClientLocalization.WhenChangingProps__(
			Item,
			ThisForm);
	EndIf;
	TagName = Item.Name;
	If ValueIsFilled(TagName) Then
		ConstantName = OnChangeAttributeServer(TagName);
		
		If ShouldRefreshInterface Then
			RefreshInterface = True;
			AttachIdleHandler("RefreshApplicationInterface", 2, True);
		EndIf;
		
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

#EndRegion

#Region ServerCall

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute);
	
	ConfigureDependentFormElements(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	// Storing the values of the details that are not directly related to the constants (in a one-to-one relationship).
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	// Definition of the constant name.
	ConstantName = "";
	If StrStartsWith(Lower(DataPathAttribute), Lower("ConstantsSet.")) Then
		// If the path to the data of the props is specified through the "Setconstant".
		NameParts = StrSplit(DataPathAttribute, ".");
		ConstantName = NameParts[1];		
	ElsIf DataPathAttribute = "VariantOfStructureOfProductionOrder" Then
		ConstantsSet.DynamicStructureOfProductionOrders = Boolean(VariantOfStructureOfProductionOrder);
		ConstantName = "DynamicStructureOfProductionOrders";
	EndIf;
		
	If DataPathAttribute = "AccountingForLaborCostsByEmployees" Then
		ConstantName = "StartDateOfRecordKeepingOfLaborCostsForEmployees";
	EndIf;
	If ConstantName = "UseProductionManagement" Then
		ConstantValue = ConstantsSet[ConstantName];
		If ConstantValue Then
			ProductDataManagement.SetAssignmentParametersByDivisionDispatcher();
		EndIf;
	EndIf;
	
	If ConstantName = "DynamicStructureOfProductionOrders"
		Or ConstantName = "ProductionManagementMethod" Then
		Constants.StandardOrderStructureScheduleIsUsed.Set(ConstantsSet.DynamicStructureOfProductionOrders
			And ConstantsSet.ProductionManagementMethod = Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule);
	EndIf;
	
	If DataPathAttribute = "UseAdditionalSectionOfTariffGrid" Then
		ConstantName = "AdditionalSectionOfTariffGrid"
	EndIf;
	
	If ConstantName = "RationingAndPricingOfWorksOnTariffGrids" 
		And Not ConstantsSet[ConstantName] Then
		UseAdditionalSectionOfTariffGrid = False;
	EndIf;
	
	// Saving the value of a constant.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		If ConstantName = "DynamicStructureOfProductionOrders" And ConstantValue Then
			InformationRegisters.ItemLinksByChangeOrders.RunFullCalculationInBackground();
		EndIf;
		If SystemSettingsCached.ThereAreSubordinateConstants(ConstantName, ConstantValue)
			Or StrFind(ConstantName, "UseProduction") > 0
			Or StrFind(ConstantName, "UseProductionManagement") > 0
			Or ConstantName = "DynamicStructureOfProductionOrders"
			Or ConstantName = "UseSubcontractOrders2_5" Then
			ThisForm.Read();
		EndIf;
		
	EndIf;
	
	SystemSettingsLocalization.SaveValueOfProps__(ConstantName, ConstantValue, ThisForm);
	
	Return ConstantName
	
EndFunction

#EndRegion

#Region Constants

&AtServer
Function ProductionIsUsed()
	
	Return ConstantsSet.UseProduction;
	
EndFunction

&AtServer
Function ProductionIsUsed22()
	
	Return ConstantsSet.UseProductionManagement2_2;
	
EndFunction

&AtServer
Function ProductionIsUsed21()
	
	Return ConstantsSet.UseProductionManagement;
	
EndFunction

&AtServer
Function OnlyProduction21IsUsed()
	
	Return ConstantsSet.UseProductionManagement
			And Not ConstantsSet.UseProductionManagement2_2;
	
EndFunction

&AtServer
Function OnlyProduction22IsUsed()
	
	Return ConstantsSet.UseProductionManagement2_2
			And Not ConstantsSet.UseProductionManagement;
	
EndFunction

&AtServer
Function ProductionIsUsed21_22()
	
	Return ProductionIsUsed21() And ProductionIsUsed22();
	
EndFunction

#EndRegion

#Region ConfiguringElements

&AtServer
Procedure SetFormItemsVisibility()
	
	EnterpriseManagement = GetFunctionalOption("EnterpriseManagement");
	
	Items.ProductionOrdersGroup.Visible = EnterpriseManagement;
	Items.SeparationOfMaterialsInTheProductionOfSPACECRAFT.Visible = Not EnterpriseManagement;
	Items.SeparationOfMaterialsInTheProductionOfUp.Visible = EnterpriseManagement;
	Items.TheGroupUseTheParametersOfTheAssignmentSpecifications.Visible = EnterpriseManagement;
	Items.GroupUseKitsInProduction.Visible = EnterpriseManagement;
	Items.GroupUseMaterialAnalogues.Visible = EnterpriseManagement;
	Items.OperationsGroup.Visible = EnterpriseManagement;
	Items.GroupUseMaterialAnalogues.Visible = EnterpriseManagement;
	Items.TheGroupUseTheParametersOfTheAssignmentSpecifications.Visible = EnterpriseManagement;
	Items.GroupUseKitsInProduction.Visible = EnterpriseManagement And GetFunctionalOption("UseSets");
	Items.GroupStorageOptionForTechnologicalOperations.Visible = False;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElements(DataPathAttribute = "")
	
	// Use production, use production management
	If DataPathAttribute = "" 
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0 Then
		
		UseOrderSupplyWithAssignment = Constants.UseOrderSupplyWithAssignment.Get();
		Items.OptionOfSeparationOfMaterialsInTheProductionOfSPACECRAFT.Visible = UseOrderSupplyWithAssignment;
		Items.GroupSeparationOfMaterialsFromProcessor2_5.Visible = UseOrderSupplyWithAssignment;
		
		Items.CostAccountingGroup.Enabled = ProductionIsUsed();
		
		Items.OptionOfSeparationOfMaterialsInTheProductionOfSPACECRAFT.Enabled = ConstantsSet.UseProduction;
		
		BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22();
		Items.UseProduction22.Enabled = BatchAccountingVersion22;
		
		Items.GroupWarningProductionUse22.Visible =
			Not ProductionIsUsed22() And Not BatchAccountingVersion22;
			
		Items.UseBOMAssignmentParameters.Enabled = False;
		
		Items.UseStatusesOfInternalWorksAcceptance.Visible = ProductionIsUsed22();
		Items.UseStatusesOfProductsAndMaterialsMovements.Visible = ProductionIsUsed22();
		Items.GroupOptionForSeparatingMaterialsInProduction.Visible = ProductionIsUsed22();
		Items.GroupOptionForSeparatingMaterialsWhenTransferringToTheStoreroom.Visible = ProductionIsUsed22();
		Items.GroupOptionForSeparatingMaterialsInProduction21.Visible = OnlyProduction21IsUsed();
		Items.GroupOptionToSeparateMaterialsWhenTransferringToProduction.Visible = OnlyProduction21IsUsed();
		Items.OperationsGroup.Visible = ProductionIsUsed22();
		
		Items.LocalizationGroupUseReleaseBySeveralReferences.Enabled = ProductionIsUsed();
		Items.TheGroupUseTheParametersOfTheAssignmentSpecifications.Enabled = ProductionIsUsed();
		Items.GroupUseMaterialAnalogues.Enabled = ProductionIsUsed();
		Items.GroupUseKitsInProduction.Enabled = ProductionIsUsed();

		Items.SeparationOfMaterialsInTheProductionOfUp.Visible = UseOrderSupplyWithAssignment;
		
		Items.UseBOMAssignmentParameters.Enabled = OnlyProduction22IsUsed();
	EndIf;
	If DataPathAttribute = "ConstantsSet.OptionOfMaterialAssignmentInProduction" Or DataPathAttribute = "" Then
		
		Items.GroupCommentRestrictionOfSeparationInProduction21.Visible = ProductionIsUsed21_22()
			And (ConstantsSet.OptionOfMaterialAssignmentInProduction = PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder")
				Or ConstantsSet.OptionOfMaterialAssignmentInProduction = PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.ProductionStage"));
		
	EndIf;
	If DataPathAttribute = ""
		Or DataPathAttribute = "ConstantsSet.UseBOMAssignmentParameters"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0 Then
		Items.UseTheOptionsOnTheDestinationSpecificationsSetting.Enabled = ConstantsSet.UseBOMAssignmentParameters;
	EndIf;
	// Inter-shop management
	If DataPathAttribute = ""
		Or DataPathAttribute = "ConstantsSet.DynamicStructureOfProductionOrders"
		Or DataPathAttribute = "ConstantsSet.ProductionManagementMethod"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0 
		Or StrFind(DataPathAttribute, "VariantOfStructureOfProductionOrder") > 0 Then
		
		Items.ProductionOrdersGroup.Visible = ProductionIsUsed();
		
		Items.CalculationSettingsForProductionOrderStructure.Enabled = OnlyProduction22IsUsed() And ConstantsSet.DynamicStructureOfProductionOrders;
		
		GraphIsUsed = ConstantsSet.UseProductionManagement
			Or Not ConstantsSet.ProductionManagementMethod = Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule;
			

		FieldSelectionList = Items.ProductionManagementMethod.ChoiceList;
		FieldSelectionList.Clear();
		FieldSelectionList.Add(Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule,
			?(ConstantsSet.DynamicStructureOfProductionOrders,
				NStr("vi = 'Lập kế hoạch theo thời lượng chuẩn';
					|ru = 'Планирование по нормативным длительностям';
					|en = 'Planning by standard duration'; fa = 'Planning by standard duration';
					|it = 'Планирование по нормативным длительностям';
					|pl = 'Planning by standard duration';
					|tr = 'Standart sürelere göre planlama'"),
				NStr("vi = 'Không có kế hoạch tiến độ sản xuất';
					|ru = 'Без планирования графика производства';
					|en = 'Without creating production schedule'; fa = 'بدون ایجاد برنامه تولید';
					|it = 'Без планирования графика производства';
					|pl = 'Bez planowania harmonogramu produkcji';
					|tr = 'Planlama olmadan üretim programı'")));
		If Not ConstantsSet.DynamicStructureOfProductionOrders Then
			FieldSelectionList.Add(Enums.ProductionManagementMethod.DemandPlanningForMaterials);
		EndIf;
		FieldSelectionList.Add(Enums.ProductionManagementMethod.SchedulingOfResourcesForProduction,
			?(ConstantsSet.DynamicStructureOfProductionOrders,
				NStr("vi = 'Lập kế hoạch có hạn chế về nguồn lực';
					|ru = 'Планирование с учетом ресурсных ограничений';
					|en = 'Planning based on resource limitations'; fa = 'Planning based on resource limitations';
					|it = 'Планирование с учетом ресурсных ограничений';
					|pl = 'Planning based on resource limitations';
					|tr = 'Kısıtlama kaynakları muhasebesi planlaması'"),
				NStr("vi = 'Nguyên liệu và kế hoạch sản xuất';
					|ru = 'Планирование по материальным и производственным ресурсам';
					|en = 'Planning by material and production resources'; fa = 'برنامه‌ریزی بر اساس منابع مادی و تولیدی';
					|it = 'Планирование по материальным и производственным ресурсам';
					|pl = 'Planowanie zasobów materiałowych i produkcyjnych';
					|tr = 'Maddi ve üretim kaynaklara göre planlama'")));
		FieldSelectionList = Undefined;
		
		Items.TooltipProductionManagementMethod.ToolTip = MethodHint(ConstantsSet.ProductionManagementMethod, ConstantsSet.DynamicStructureOfProductionOrders);
		
		If Not GraphIsUsed And TheCalculationOfScheduleProductionUse Then
			TheCalculationOfScheduleProductionUse = False;
			SetScheduledJobUsage();
		EndIf;
		
		Items.GroupRoutineTaskCalculationOfTheProductionSchedule.Visible = GraphIsUsed;
		Items.UsePlanningIntervalHour.Visible = GraphIsUsed;

		
		Items.GroupScheduleCalculationProcedure.Enabled = ProductionIsUsed22();
		
	EndIf;
	
	If DataPathAttribute = ""
		Or DataPathAttribute = "ConstantsSet.ProductionManagementMethod"
		Or DataPathAttribute = "ConstantsSet.OptionOfMaterialAssignmentInProduction"
		Or DataPathAttribute = "ConstantsSet.UseProductionByThirdParty2_5"
		Or DataPathAttribute = "ConstantsSet.DynamicStructureOfProductionOrders"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Or StrFind(DataPathAttribute, "VariantOfStructureOfProductionOrder") > 0 Then
		
		Items.GroupOptionsForStructureOfProductionOrder.Enabled = 
			(ConstantsSet.DynamicStructureOfProductionOrders Or ProductionIsUsed22());
		
		Items.GroupSemiFinishedProductsWithinOrderToProduceSeparately.Visible = ConstantsSet.DynamicStructureOfProductionOrders;
	
	EndIf;
	// Updating the separation options
	If DataPathAttribute = ""
		Or DataPathAttribute = "ConstantsSet.DynamicStructureOfProductionOrders"
		Or StrFind(DataPathAttribute, "VariantOfStructureOfProductionOrder") > 0 Then
		
		AreasOfActivityAreUsed = Constants.GenerateFinancialResult.Get();
		
		// production 2.2
		SelectionListItem = Items.OptionOfMaterialAssignmentInProduction.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfMaterialAssignmentInProduction.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfMaterialAssignmentInProduction.ChoiceList.Delete(SelectionListItem);
		EndIf;

		SelectionListItem = Items.OptionOfMaterialAssignmentInProduction.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.ProductionStage"));
		
		If ConstantsSet.DynamicStructureOfProductionOrders And SelectionListItem <> Undefined Then
			Items.OptionOfMaterialAssignmentInProduction.ChoiceList.Delete(SelectionListItem);
		ElsIf Not ConstantsSet.DynamicStructureOfProductionOrders And SelectionListItem = Undefined Then
			Items.OptionOfMaterialAssignmentInProduction.ChoiceList.Add(
				PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.ProductionStage"));
		EndIf;
		
		SelectionListItem = Items.OptionOfMaterialPeggingWhenTransferringToStoreroom.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfMaterialAssignmentWhenTransferringToProduction.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfMaterialPeggingWhenTransferringToStoreroom.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfMaterialAssignmentWhenTransferringToProduction.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfMaterialPeggingWhenTransferringToStoreroom.ChoiceList.Delete(SelectionListItem);
		EndIf;
		
		// Production 2.1
		SelectionListItem = Items.OptionOfMaterialAssignmentInProduction21.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfMaterialAssignmentInProduction21.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfMaterialAssignmentInProduction21.ChoiceList.Delete(SelectionListItem);
		EndIf;
		
		SelectionListItem = Items.OptionOfMaterialAssignmentWhenTransferringToProduction.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfMaterialAssignmentWhenTransferringToProduction.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfMaterialAssignmentWhenTransferringToProduction.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfMaterialAssignmentWhenTransferringToProduction.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfMaterialAssignmentWhenTransferringToProduction.ChoiceList.Delete(SelectionListItem);
		EndIf;
		
		// Processing on the side
		SelectionListItem = Items.OptionOfAssignmentAtTransferToSubcontractor2_5.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfAssignmentDuringTransferToProcessing.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfAssignmentAtTransferToSubcontractor2_5.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfAssignmentDuringTransferToProcessing.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfAssignmentAtTransferToSubcontractor2_5.ChoiceList.Delete(SelectionListItem);
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "" 
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Then
		
		ConstantAvailable = ConstantsSet.UseAdditionalAttributesAndInfo
			And ProductionIsUsed22();
		
		Items.UseKindsOfSpecificTechnologicalOperations.Enabled = ConstantAvailable;
		Items.GroupCommentRestrictionTypesOfTechnologicalOperations.Visible = Not ConstantAvailable;
		
	EndIf;
	
	If DataPathAttribute = ""
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Or StrFind(DataPathAttribute, "UseRouteSheets") > 0
		Or StrFind(DataPathAttribute, "StoreOperationsInBillsOfMaterials") > 0
		Then
	
		Items.GroupStorageOptionForTechnologicalOperations.Visible = OnlyProduction22IsUsed()
			And ConstantsSet.UseRouteSheets
			And Not ConstantsSet.StoreOperationsInBillsOfMaterials;
			
	EndIf;
	
	If DataPathAttribute = ""
		Or StrFind(DataPathAttribute, "SourceOfCompositionOfSetsInProduction")
		Then
		
		Enums.SourcesOfCompositionOfSetsInProduction.FillInListOfSelectionOfSourcesOfCompositionOfSets(
			Items.SourceOfCompositionOfSetsInProduction.ChoiceList);
		
		UseKitsInProduction = ValueIsFilled(ConstantsSet.SourceOfCompositionOfSetsInProduction)
			And Not (ConstantsSet.SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.DontUse);
		
		Items.GroupUseKitsInProductionComposition.Visible = UseKitsInProduction
			And OnlyProduction22IsUsed();
		
		ToolTipText = Enums.SourcesOfCompositionOfSetsInProduction.HintOnSourceOfCompositionOfSets(
			ConstantsSet.SourceOfCompositionOfSetsInProduction);
		Items.GroupIsSourceOfCompositionOfSetsInProduction.ToolTip = ToolTipText;
		
		Items.UseKitsInProduction.WarningOnEditRepresentation = ?(
			UseKitsInProduction,
			WarningOnEditRepresentation.Show,
			WarningOnEditRepresentation.DontShow);
		
	EndIf;

	//CurrencyOfActivityKindRates
	If DataPathAttribute = "ConstantsSet.CurrencyOfActivityKindRates" Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.CurrencyOfActivityKindRates, ValueIsFilled(ConstantsSet.CurrencyOfActivityKindRates));
	EndIf;
	
	// planned types of prices
	If StrFind(DataPathAttribute, "UseSeveralPriceTypes") > 0
		Or DataPathAttribute = "" Then
		
		Items.GroupExplanationOfThePlannedTypeOfPrice.Visible = Not ConstantsSet.UseSeveralPriceTypes;
		Items.PlannedPricesOfMaterialsWorks.Enabled = ConstantsSet.UseSeveralPriceTypes;
		
	EndIf;
	
	If DataPathAttribute = "" 
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseSeveralPriceTypes") > 0 Then
		Items.GroupPlannedValueCurrency.Visible = 
			ConstantsSet.UseProduction And ConstantsSet.UseSeveralPriceTypes;
	EndIf;
	
	//PlannedPriceCurrencyOfProductsMaterialsAndLabor
	If DataPathAttribute = "ConstantsSet.PlannedPriceCurrencyOfProductsMaterialsAndLabor" Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.CurrencyOfPlannedProductionCost, ValueIsFilled(ConstantsSet.PlannedPriceCurrencyOfProductsMaterialsAndLabor));
	EndIf;
	
	// AnalyticalAccountingByProductsGroups
	If DataPathAttribute = "ConstantsSet.AnalyticalAccountingByProductsGroups"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.AnalyticalAccountingByProductsGroups;
		TMCommonUseClientServer.WarningOnEditRepresentation(Items.AnalyticalAccountingByProductsGroups, ConstantValue);
		
		Items.GroupAnalyticalAccountingByProductGroups.Enabled = ProductionIsUsed();
		Items.GroupCommentTypesOfProducts.Visible = Not ProductionIsUsed();
		
	EndIf;
	If DataPathAttribute = "ConstantsSet.UseAlternativeMaterials" 
	 Or DataPathAttribute = "ConstantsSet.UseApprovalOfEngineeringChangeOrders" 
	 Or DataPathAttribute = "" Then
		
		Items.UseApprovalOfEngineeringChangeOrders.Enabled = ConstantsSet.UseAlternativeMaterials;
		Items.AssignThoseResponsibleForApprovingPermitsForReplacementOfMaterials.Enabled = ConstantsSet.UseAlternativeMaterials
			And ConstantsSet.UseApprovalOfEngineeringChangeOrders;
		
	EndIf;
	#Region ProductionByThirdParty
	
	If DataPathAttribute = "ConstantsSet.UseProductionByThirdParty2_5"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Or DataPathAttribute = "ConstantsSet.NewOnlineARAPAccounting"
		Or DataPathAttribute = "" Then
			
		BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22();
		Items.UseProductionByThirdParty2_5.Enabled =
			BatchAccountingVersion22
			And ConstantsSet.NewOnlineARAPAccounting;
		
		Items.CommentGroupUseProductionOnSide2_5.Visible =
			Not BatchAccountingVersion22
			Or Not ConstantsSet.NewOnlineARAPAccounting;
		
		If Not BatchAccountingVersion22
			Or Not ConstantsSet.NewOnlineARAPAccounting Then
			
			TitleTemplate1 = NStr("vi = 'Để sử dụng sản xuất bên ngoài, cần bật sử dụng tùy chọn:
									|%1';
									|ru = 'Для использования производства на стороне необходимо включить опции:
									|%1';
									|en = 'To use production by third party, enable the following options:
									|%1'; fa = 'برای استفاده از تولید توسط اشخاص ثالث، گزینه‌های زیر را فعال کنید:
									|%1';
									|it = 'Для использования производства на стороне необходимо включить опции:
									|%1';
									|pl = 'To use production by third party, enable the following options:
									|%1';
									|tr = 'Fason üretimi kullanmak için şu seçenekleri etkinleştirmeniz gerekmektedir:
									|%1'");
			
			Options = New Array;
			If Not BatchAccountingVersion22 Then
				Options.Add(NStr("vi = '- ""Kế toán theo lô, phiên bản 2.2"" trong phân hệ ""Danh mục và quản trị"" - ""Kết quả tài chính và kiểm soát"".';
								|ru = '- ""Партионный учет версии 2.2"" в разделе ""НСИ и администрирование"" - ""Финансовый результат и контроллинг"".';
								|en = '- Lot accounting 2.2 in Master data and settings - Profitability & cost.'; fa = '- Lot accounting 2.2 in Master data and settings - Profitability & cost.';
								|it = '- ""Партионный учет версии 2.2"" в разделе ""НСИ и администрирование"" - ""Финансовый результат и контроллинг"".';
								|pl = '- Lot accounting 2.2 in Master data and settings - Profitability & cost.';
								|tr = '- ""Master veri ve yönetim"" ; ""Finansal sonuç ve kontrol"" bölümündeki ""Lot muhasebesi sürüm 2.2"".'"));
			EndIf;
			
			If Not ConstantsSet.NewOnlineARAPAccounting Then
				Options.Add(NStr("vi = '- ""Hạch toán:Online"" trong phân hệ ""Danh mục và quản trị"" - ""Ngân quỹ và hạch toán"".';
								|ru = '- ""Взаиморасчеты: Онлайн"" в разделе ""НСИ и администрирование"" - ""Казначейство и взаиморасчеты"".';
								|en = '- AR/AP accounting: Online in Master data and settings - Treasury and AR/AP accounting.'; fa = '- AR/AP accounting: Online in Master data and settings - Treasury and AR/AP accounting.';
								|it = '- ""Взаиморасчеты: Онлайн"" в разделе ""НСИ и администрирование"" - ""Казначейство и взаиморасчеты"".';
								|pl = '- AR/AP accounting: Online in Master data and settings - Treasury and AR/AP accounting.';
								|tr = '- ""Master veri ve yönetim""; ""Hazine ve alacak/borç muhasebesi"" bölümündeki ""Alacak/borç muhasebesi: Çevrimiçi"".'"));
			EndIf;
			
			Items.CommentUseProductionOnSide2_5.Title =
					StrTemplate(TitleTemplate1, StrConcat(Options, Chars.LF));
			
		EndIf;
		
		Items.GroupWarningProductionUse22.Visible =
			Not ConstantsSet.UseProductionByThirdParty2_5
			And Not BatchAccountingVersion22;
		
		Items.UseSubcontractOrders2_5.Enabled =
			ConstantsSet.UseProductionByThirdParty2_5;
		
		Items.UseDiscrepancyReportFollowingShipmentByTransfersToSubcontractor2_5.Enabled =
			ConstantsSet.UseProductionByThirdParty2_5;
		
		Items.UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5.Enabled =
			ConstantsSet.UseProductionByThirdParty2_5;
		
		Items.SubcontractorOptionOfAssignment2_5.Enabled =
			ConstantsSet.UseProductionByThirdParty2_5;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseProductionByThirdParty2_5,
			ConstantsSet.UseProductionByThirdParty2_5);
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseProductionByThirdParty2_5"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Or DataPathAttribute = "ConstantsSet.UseSubcontractOrders2_5"
		Or DataPathAttribute = "ConstantsSet.NewOnlineARAPAccounting"
		Or DataPathAttribute = "" Then
		
		Items.UseSubcontractOrders2_5.Enabled =
			Not ConstantsSet.UseProduction
			And Not ConstantsSet.UseProductionManagement2_2 And
			ConstantsSet.UseProductionByThirdParty2_5;
		
		Items.UseTollingOrderStatuses2_5.Enabled =
			Not ConstantsSet.UseProduction
			And Not ConstantsSet.UseProductionManagement2_2 And
			ConstantsSet.UseSubcontractOrders2_5;
		
		Items.TheCommentGroupUsesOrderStatusesForProcessors2_5.Visible =
			ConstantsSet.UseProductionByThirdParty2_5
			And (ConstantsSet.UseProduction
				Or ConstantsSet.UseProductionManagement2_2) Or
			False;
		
		Items.OptionOfAssignmentAtTransferToSubcontractor2_5.Enabled =
			ConstantsSet.UseSubcontractOrders2_5;
		
		Items.SubcontractorOptionOfAssignment2_5.Enabled =
			ConstantsSet.UseSubcontractOrders2_5;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseProductionByThirdParty2_5"
		Or StrFind(DataPathAttribute, "UseProduction") > 0
		Or StrFind(DataPathAttribute, "UseProductionManagement") > 0
		Or DataPathAttribute = "ConstantsSet.UseSubcontractOrders2_5"
		Or DataPathAttribute = "ConstantsSet.UseTollingOrderStatuses2_5"
		Or DataPathAttribute = "ConstantsSet.NewOnlineARAPAccounting"
		Or DataPathAttribute = "" Then
		
		Items.DoNotCloseTollingOrdersWithoutCompleteFulfillment2_5.Enabled =
			ConstantsSet.UseTollingOrderStatuses2_5;
		
		Items.DoNotCloseTollingOrdersWithoutCompletePayment2_5.Enabled =
			ConstantsSet.UseTollingOrderStatuses2_5;
		
		Items.TheGroupCanControlTheClosingOfOrdersToProcessors2_5.Visible =
			Not ConstantsSet.UseTollingOrderStatuses2_5;
		
	EndIf;
	
	#EndRegion
	
	SystemSettingsLocalization.SetAvailability_Production(DataPathAttribute, ThisForm);
	
	WarningOnEditRepresentation(DataPathAttribute);
	
EndProcedure

&AtServer
Procedure WarningOnEditRepresentation(DataPathAttribute)
	
	StructureOfConstants = New Structure(
		"
		|UseSubcontractOrders2_5,
		|UseStatusesOfInternalWorksAcceptance,
		|UseStatusesOfProductsAndMaterialsMovements,
		|UseTollingOrderStatuses2_5,
		|UseBOMAssignmentParameters,
		|UseAlternativeMaterials,
		|AnalyticalAccountingByProductsGroups");
		
	SystemSettingsLocalization.DisplayingWarningWhenEditing__(StructureOfConstants);
	
	For Each KeyAndValue In StructureOfConstants Do
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items[KeyAndValue.Key],
			ConstantsSet[KeyAndValue.Key]);
	EndDo;
	
EndProcedure

#EndRegion
#Region RoutineAssignment_CalculationOfProductionSchedule

&AtServer
Procedure UpdateSettingsOfRoutineTaskCalculationOfProductionSchedule()
	
	CheckSystemAdministrationRights = True;
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		CheckSystemAdministrationRights = False;
	EndIf;
	
	If Users.IsFullUser(, CheckSystemAdministrationRights) Then
		Job = ProductionPlanning.TaskCalculationOfProductionSchedule();
		If Job <> Undefined Then
			CalculateTheScheduleForTheProductionID = Job.UUID;
			TheCalculationOfScheduleProductionUse = Job.Use;
			CreateProductionScheduleTimetable    = Job.Schedule;
		EndIf;
	EndIf;
	
	RefreshSchedulePresentation();
	
EndProcedure

&AtServer
Procedure RefreshSchedulePresentation()
	
	If TheCalculationOfScheduleProductionUse And Not DataSeparationEnabled Then
		
		SchedulePresentation = String(CreateProductionScheduleTimetable);
		If SchedulePresentation = String(New JobSchedule) Then
			 SchedulePresentation = NStr("vi = 'Chưa đặt lịch biểu';
										|ru = 'Расписание не задано';
										|en = 'Schedule is not set'; fa = 'Schedule is not set';
										|it = 'Orario non è impostato';
										|pl = 'Harmonogram nie jest zadany';
										|tr = 'Plan ayarlanmadı'");
		EndIf;
		Items.CreateProductionScheduleTimetable.Title = SchedulePresentation;
		
		Items.CreateProductionScheduleTimetable.Enabled = True;
	Else
		
		Items.CreateProductionScheduleTimetable.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetScheduledJobUsage()
	
	JobParameters = New Structure;
	
	JobParameters.Insert("Use", TheCalculationOfScheduleProductionUse);
	
	If TheCalculationOfScheduleProductionUse And DataSeparationEnabled Then
		
		CreateProductionScheduleTimetable = ProductionPlanning.PredefinedSchedule();
		
		JobParameters.Insert("Schedule", CreateProductionScheduleTimetable);
		
	EndIf;
	
	If ValueIsFilled(CalculateTheScheduleForTheProductionID) Then
		ScheduledJobsServer.ChangeJob(CalculateTheScheduleForTheProductionID, JobParameters);
	Else
	
		MetadataCalculationOfProductionSchedule = Metadata.ScheduledJobs.Find("CreateProductionSchedule");
		If MetadataCalculationOfProductionSchedule <> Undefined Then
			
			PopulationFields = New Array;
			PopulationFields.Add("RestartIntervalOnFailure");
			PopulationFields.Add("RestartCountOnFailure");
			
			JobParameters.Insert("Metadata", MetadataCalculationOfProductionSchedule);
			For Each Field In PopulationFields Do
				JobParameters.Insert(Field);
			EndDo;
			FillPropertyValues(JobParameters, JobParameters.Metadata, StrConcat(PopulationFields, ","));
			
			Job = ScheduledJobsServer.AddJob(JobParameters);
			CalculateTheScheduleForTheProductionID = ScheduledJobsServer.UUID(Job);
			TheCalculationOfScheduleProductionUse = Job.Use;
			CreateProductionScheduleTimetable    = Job.Schedule;
		
		EndIf;
		
	EndIf;
	
	RefreshSchedulePresentation();
	
EndProcedure

&AtServer
Procedure SetJobSchedule()
	
	JobParameters = New Structure("Schedule", CreateProductionScheduleTimetable);
	
	If ValueIsFilled(CalculateTheScheduleForTheProductionID) Then
		ScheduledJobsServer.ChangeJob(CalculateTheScheduleForTheProductionID, JobParameters);
	Else
	
		MetadataCalculationOfProductionSchedule = Metadata.ScheduledJobs.Find("CreateProductionSchedule");
		If MetadataCalculationOfProductionSchedule <> Undefined Then
			
			PopulationFields = New Array;
			PopulationFields.Add("RestartIntervalOnFailure");
			PopulationFields.Add("RestartCountOnFailure");
			
			JobParameters.Insert("Metadata", MetadataCalculationOfProductionSchedule);
			For Each Field In PopulationFields Do
				JobParameters.Insert(Field);
			EndDo;
			FillPropertyValues(JobParameters, JobParameters.Metadata, StrConcat(PopulationFields, ","));
			
			Job = ScheduledJobsServer.AddJob(JobParameters);
			CalculateTheScheduleForTheProductionID = ScheduledJobsServer.UUID(Job);
			TheCalculationOfScheduleProductionUse = Job.Use;
			CreateProductionScheduleTimetable    = Job.Schedule;
		
		EndIf;
		
	EndIf;
	
	RefreshSchedulePresentation();
	
EndProcedure

#EndRegion
#Region OperationAsOutputReference

&AtServerNoContext
Function ProductionStagesWereUsedEarlier()
	
	Query = New Query("
	|SELECT TOP 1
	|	ProductionStage.Ref AS Ref
	|FROM 
	|	Document.ProductionStage2_2 AS ProductionStage
	|WHERE 
	|	NOT ProductionStage.OperationAsOutputReference
	|	AND NOT ProductionStage.DeletionMark");
	
	SetPrivilegedMode(True);
	Result = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

&AtServer
Procedure UpdateSettingsForUsingOperationAsOrder()
	
	UseProductionOperationsAsReferencesForOutput = 
		ValueIsFilled(Constants.StartDateOfAccountingForOutputByOperations.Get());
	
EndProcedure

&AtServerNoContext
Procedure SetOperationAsProductionOrder(UseProductionOperationsAsReferencesForOutput)
	
	If UseProductionOperationsAsReferencesForOutput Then
		Date = CurrentSessionDate();
	Else
		Date = Undefined;
	EndIf;
	
	Constants.StartDateOfAccountingForOutputByOperations.Set(Date);
	
EndProcedure

#EndRegion
#Region DynamicStructure

&AtClient
Procedure QuestionSetAssociatedSettingsWhenChangingVariantOfProductionOrderStructure(UserAnswer, AdditionalParameters) Export

	If UserAnswer = DialogReturnCode.No Then
		TMCommonUseClientServer.RestoreValuesBeforeChange(ThisForm, "DynamicStructureOfProductionOrders");
		VariantOfStructureOfProductionOrder = Number(ConstantsSet.DynamicStructureOfProductionOrders);
		Return;
	EndIf;
	
	SetAssociatedSettingsWhenChangingVariantOfProductionOrderStructure(AdditionalParameters.ListOfParametersToChange);
	
	Attachable_OnChangeAttribute(AdditionalParameters.Item);
	TMCommonUseClientServer.SaveValuesBeforeChanging(ThisForm, "DynamicStructureOfProductionOrders");

EndProcedure

&AtServer
Procedure SetAssociatedSettingsWhenChangingVariantOfProductionOrderStructure(ListOfParametersToChange)
	
	For Each KeyAndValue In ListOfParametersToChange Do
		Constants[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo;

EndProcedure

&AtServerNoContext
Procedure StartCalculationOfOrderStructure()
	
	OrderStructure.StartCalculation();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure SourceOfCompositionOfSetsInProductionStartChoiceCompletion(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.Yes Then
		SourceOfCompositionOfSetsInProductionSelectValue();
	EndIf;
EndProcedure

&AtClient
Procedure SourceOfCompositionOfSetsInProductionSelectValue()
	
	OpenForm(
		"Enum.SourcesOfCompositionOfSetsInProduction.Form.SelectSourceOfKitsInProduction",
		New Structure("SourceOfKitCompositionInProduction", ConstantsSet.SourceOfCompositionOfSetsInProduction),
		Items.SourceOfCompositionOfSetsInProduction,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServerNoContext
Function MethodHint(Methodology, DynamicStructure)
	
	Text = "";
	
	If Methodology = Enums.ProductionManagementMethod.SchedulingOfResourcesForProduction Then
		
		Text = NStr("vi = 'Lịch biểu sản xuất được tính toán dựa trên mức độ khả dụng của các dạng nguồn lực sản xuất và nhu cầu nguyên vật liệu. Thời hạn thực hiện được ấn định cho các công đoạn.';
					|ru = 'График производства рассчитывается на основе доступности видов рабочих центров и потребности в материалах. Этапам назначаются сроки выполнения.';
					|en = 'Production schedule is calculated based on capacity of work center types and demand for materials. Execution dates are assigned to stages.'; fa = 'Production schedule is calculated based on capacity of work center types and demand for materials. Execution dates are assigned to stages.';
					|it = 'График производства рассчитывается на основе доступности видов рабочих центров и потребности в материалах. Этапам назначаются сроки выполнения.';
					|pl = 'Harmonogram produkcji jest obliczany na podstawie dostępności typów stanowisk pracy i zapotrzebowania na materiały. Do etapów przeznaczany są terminy wykonania.';
					|tr = 'Üretim programı, iş merkezi türleri kapasitelerin girişine ve malzeme gereksinimlerine göre hesaplanır. Aşamalara bitiş tarihleri atanır.'");
		
	ElsIf Methodology = Enums.ProductionManagementMethod.DemandPlanningForMaterials Then
		
		Text = NStr("vi = 'Việc tính toán tiến độ sản xuất được thực hiện có tính đến nhu cầu nguyên Nguyên vật liệu. Dạng trung tâm làm việc không được sử dụng trong việc tính toán lịch trình. Các mốc được chỉ định thời hạn.';
					|ru = 'Расчет графика производства выполняется с учетом потребности в материалах. Виды рабочих центров не используются при расчете графика. Этапам назначаются сроки выполнения.';
					|en = 'Production schedule is calculated considering demand for materials. Work center type is not used while calculating the schedule. Execution dates are assigned to stages.'; fa = 'Production schedule is calculated considering demand for materials. Work center type is not used while calculating the schedule. Execution dates are assigned to stages.';
					|it = 'Расчет графика производства выполняется с учетом потребности в материалах. Виды рабочих центров не используются при расчете графика. Этапам назначаются сроки выполнения.';
					|pl = 'Harmonogram produkcji jest obliczany z uwzględnieniem zapotrzebowania na materiały. Typy stanowisk pracy nie są używane przy obliczaniu harmonogramu. Do etapów przeznaczany są terminy wykonania.';
					|tr = 'Üretim programının hesaplanması, malzeme gereksinimi dikkate alınarak gerçekleştirilir. İş merkezi türleri program hesaplamasında kullanılmaz. Aşamalara bitiş tarihleri atanır.'");
		
	Else
		
		If DynamicStructure Then
		
			Text = NStr("vi = 'Việc tính toán lịch biểu sản xuất được thực hiện theo chu kỳ sản xuất từ ngày xuất xưởng mong muốn. Các thời hạn thực hiện định mức được ấn định cho các giai đoạn.';
						|ru = 'Расчет графика производства выполняется по производственным циклам от желаемых дат выпуска. Этапам назначаются нормативные сроки выполнения.';
						|en = 'Production schedule is calculated by production cycles from the requested release dates. Standard due dates are assigned to stages.'; fa = 'Production schedule is calculated by production cycles from the requested release dates. Standard due dates are assigned to stages.';
						|it = 'Расчет графика производства выполняется по производственным циклам от желаемых дат выпуска. Этапам назначаются нормативные сроки выполнения.';
						|pl = 'Production schedule is calculated by production cycles from the requested release dates. Standard due dates are assigned to stages.';
						|tr = 'Üretim programı, arzulanan çıkış tarihleri itibarıyla üretim döngülerine göre hesaplanır. Aşamalara standart teslim tarihleri atanır.'");
		
		Else
			
			Text = NStr("vi = 'Lịch biểu sản xuất không được tính toán. Thời hạn cho các giai đoạn không được chỉ định, các giai đoạn được thực hiện theo hàng đợi.';
						|ru = 'График производства не рассчитывается. Сроки выполнения этапов не назначаются, этапы выполняются согласно очереди.';
						|en = 'Production schedule is not calculated. Stage execution dates are not assigned, stages are executed according to the order.'; fa = 'Production schedule is not calculated. Stage execution dates are not assigned, stages are executed according to the order.';
						|it = 'График производства не рассчитывается. Сроки выполнения этапов не назначаются, этапы выполняются согласно очереди.';
						|pl = 'Harmonogram produkcji nie jest obliczany. Terminy wykonania etapów nie są wyznaczane, etapy są wykonywane zgodnie z kolejnością.';
						|tr = 'Üretim programı hesaplanmamaktadır. Aşamaların gerçekleştirilme tarihleri atanmaz, aşamalar kuyruğa göre gerçekleştirilir.'");
		
		EndIf;
		
	EndIf;
	
	Return Text;
	
EndFunction

#EndRegion

#EndRegion
