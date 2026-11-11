
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	FillInSelectionListOfDistributionBasesByBatch();
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	If EventName = "ChangedSettingsForDistributionOfItemByItemExpenses" Then
		CNumberOfSettingsByOrganizationDivision = NumberOfSettingsByOrganizationsDepartments;
		UpdateNumberOfSettingsForOrganizationsDivisions();
		If CNumberOfSettingsByOrganizationDivision <> NumberOfSettingsByOrganizationsDepartments Then
			UpdateLabelNumberOfSettingsByOrganizationDivision();
			DetermineUseOfFullCapabilities();
			FormItemsManagement();
		EndIf;
	EndIf;
	// Working out the visibility of form elements that are not directly related to the FO
	If EventName = "Write_ConstantsSet" Then
		FormItemsManagement();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();

	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
// End StandardSubsystems.Properties
	UpdateLabelNumberOfSettingsByOrganizationDivision();
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If Not FullFunctionality Then
		Object.CostAllocationOptionLocal = Object.CostAllocationOptionManag;
		Object.CostAllocationRuleLocal = Object.CostAllocationRuleManag;
		Object.CostAllocationOptionTax = Object.CostAllocationOptionManag;
		Object.CostAllocationRuleTax = Object.CostAllocationRuleManag;
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	If Not IsBlankString(ValueType) Then
		If ValueType = "DocumentRef.SalesOrder"
			Or ValueType = "DocumentRef.CustomerInvoice"
		Then
			CurrentObject.DimensionOfExpensesOrderImplementation = True;
			CurrentObject.ValueType = ChartsOfCharacteristicTypes.ExpenseItems.TypesOfDocumentsArticlesDistributedForSale();
		ElsIf ValueType = "CatalogRef.ConstructionObjects22" Then
			CurrentObject.DimensionOfExpensesOrderImplementation = False;
			CurrentObject.ValueType = New TypeDescription("CatalogRef.Assets");
		Else
			CurrentObject.DimensionOfExpensesOrderImplementation = False;
			CurrentObject.ValueType = New TypeDescription(ValueType);
		EndIf;
	EndIf;
	
	CurrentObject.AvailableBusinessTransactions.Clear();
	For Each ListItem In AvailableBusinessTransactions Do
		If ListItem.Check Then
			NewRow = CurrentObject.AvailableBusinessTransactions.Add();
			NewRow.BusinessOperation = ListItem.Value;
		EndIf;
	EndDo;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	If Not FullFunctionality Then
		SetOfSettings = InformationRegisters.SettingsOfItemizedExpensesAllocation.CreateRecordSet();
		SetOfSettings.Filter.ExpenseItem.Set(Object.Ref);
		SetOfSettings.Write();
	EndIf;
	Items.LabelSetUpDistributionRules.Enabled = ValueIsFilled(Object.Ref);
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ValueTypeField_ = Items.ValueType;
	If ValueTypeField_.ChoiceList.FindByValue(ValueType) = Undefined
		And Not Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.OnOtherAssets
		And Not ValueType = "CatalogRef.OtherAssetsLiabilities" Then
		MessageText = NStr("vi = 'Tại trường ""Chỉ số chi phí"" chưa chọn dạng chỉ số nào';
							|ru = 'В поле ""Аналитика расходов"" не выбрано ни одного вида аналитики';
							|en = 'No dimension kind is selected in the ""Expense dimension"" field'; fa = 'No dimension kind is selected in the ""Expense dimension"" field';
							|it = 'Nel campo ""Analitica dei costi"" non è selezionato nemmeno un tipo di analitica';
							|pl = 'W polu ""Analityka kosztów"" nie wybrano żadnego rodzaju analityki';
							|tr = '""Gelir boyutu"" alanında herhangi bir boyut türü seçilmemiş'");
		CommonClientServer.MessageToUser(
			MessageText,
			, // Data key
			"ValueType",
			, // Data path
			Cancel);
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

	NotCheckedAttributeArray = New Array;
	If Not Object.RestrictUsageInBusinessTransactions Then
		NotCheckedAttributeArray.Add("AvailableBusinessTransactions");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_ExpenseItem", WriteParameters, Object.Ref);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExpenseTypeCategoryOnChange(Item)
	
	ExpenseTypeCategoryOnChangeServer(Item.Name);
	ExpenseItemsClientLocalization.OnChangeAttribute(Item.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure OptionOfDistributionOfExpensesOfUprFullOnChange(Item)
	
	CostAllocationOptionManagOnChangeServer();

	AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics();
	FormItemsManagement();
	
EndProcedure


&AtClient
Procedure ReglFullCostAllocationOptionOnChange(Item)
	
	CostAllocationOptionLocalOnChangeServer();
	
	If Object.CostAllocationOptionTax.IsEmpty() Then
		Object.CostAllocationOptionTax = Object.CostAllocationOptionLocal;
		AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics();
		CostSharingOptionNUPolnyeOnChange(Items.CostSharingOptionNUPolnye);
	Else
		DirectIndirectByAttributionSettings();
		AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics();
		FormItemsManagement();
	EndIf;
	
EndProcedure


&AtClient
Procedure CostSharingOptionNUPolnyeOnChange(Item)
	
	DirectIndirectByAttributionSettings();
	AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CostSharingOptionGeneralOnChange(Item)

	BringOptionsAndRulesToManSettings();
	CostAllocationOptionLocalOnChangeServer();
	AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics();
	FormItemsManagement();

EndProcedure

&AtClient
Procedure TheRuleOfAllocationOfCommonCostsOnChange(Item)

	BringOptionsAndRulesToManSettings();

EndProcedure

&AtClient
Procedure TheRuleOfDistributionOfExpensesOfTheUprIsCompleteOnChange(Item)
	CostAllocationRuleOfUprIsCompleteWhenChangingOnServer();
EndProcedure

&AtClient
Procedure ExpensesOccurOnChange(Item)
	
	ExpensesOccurOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure ValueTypeOnChange(Item)
	
	ValueTypeOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure LabelSetUpDistributionRulesClick(Item)
	If Modified Then
		ShowMessageBox(, NStr("vi = 'Đã có thay đổi trong dữ liệu. Cần ghi lại đối tượng trước khi tùy chỉnh quy tắc.';
								|ru = 'В данные были внесены изменения. Объект следует записать перед настройкой правил.';
								|en = 'Data was edited. Save the object before setting up rules.'; fa = 'Data was edited. Save the object before setting up rules.';
								|it = 'Nei dati sono state inserite delle modifiche. L''oggetto deve essere registrato prima dell''impostazione delle regole.';
								|pl = 'Do danych zostały wprowadzone zmiany. Przed ustawieniem reguł należy zapisać obiekt.';
								|tr = 'Verilerde değişiklikler yapıldı. Kurallar ayarlanmadan önce nesne kaydedilmelidir.'"));
	Else
		OpenForm("InformationRegister.SettingsOfItemizedExpensesAllocation.Form.ListForm", New Structure("ExpenseItem", Object.Ref), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	Return; // in ut empty
	
EndProcedure

&AtClient
Procedure RestrictUsageInBusinessTransactionsOnChange(Item)
	
	Items.AvailableBusinessTransactions.Enabled = Object.RestrictUsageInBusinessTransactions;
	
	If Not Object.RestrictUsageInBusinessTransactions Then
		For Each ListItem In AvailableBusinessTransactions Do
			If ListItem.Check Then
				ListItem.Check = False;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingLocalizationAttribute(Item)
	
	ExpenseItemsClientLocalization.OnChangeAttribute(Item.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, Var_Parameters = Undefined) Export
	
	If Var_Parameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationLimitOnServer(TagName);
	EndIf;
	
EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationLimitOnServer(TagName)
	
	ExpenseItemsLocalization.OnChangeAttribute(TagName, ThisForm);
	
EndProcedure

&AtClient
Procedure SwitchToUseFullFeaturesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	FullFunctionality = True;
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure SwitchToDisableFullFeaturesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	FullFunctionality = False;
	CallbackDescription = New CallbackDescription("SwitchDisableFullAlertCapabilities", ThisObject);
	ShowQueryBox(CallbackDescription, 
		StrTemplate(NStr("vi = 'Khi ngắt sử dụng tính năng đầy đủ, tất cả tùy chỉnh đều bằng với giá trị tùy chỉnh kế toán quản trị.%1 
		|Sẽ xóa tùy chỉnh quy tắc phân bổ đối với các doanh nghiệp/bộ phận riêng.%1 
		|Tiếp tục?';
		|ru = 'При отключении полных возможностей все настройки приравниваются к значению настроек упр. учета.%1 
		|Настройки правил распределения для отдельных организаций/подразделений будут очищены.%1 
		|Продолжить?';
		|en = 'If you disable full functionality, all settings become equal to those of management accounting values. %1
		|Allocation rule settings will be cleared for certain companies/business units.%1
		|Continue?'; fa = 'If you disable full functionality, all settings become equal to those of management accounting values. %1
		|Allocation rule settings will be cleared for certain companies/business units.%1
		|Continue?';
		|it = 'Alla disattivazione delle possibilità complete, tutte le impostazioni saranno equiparate al valore delle impostazioni di contabilità gest.%1 
		|Le impostazioni delle regole di distribuzione per le singole aziende/reparti saranno cancellate.%1 
		|Continuare?';
		|pl = 'Przy wyłączeniu pełnych możliwości wszystkie ustawienia są przyrównywane do wartości ustawień ewidencji zarządczej.%1 
		|Ustawienia reguł przydzielenia dla oddzielnych firm/działów zostaną wyczyszczone.%1 
		|Kontynuowane?';
		|tr = 'Tüm özellikler devre dışı bırakıldığında, tüm ayarlar yönetim muhasebe ayarlarının değerine eşittir.%1
		|Bireysel iş yerleri/departmanlar için dağıtım kuralı ayarları temizlenecektir.%1
		|Devam edilsin mi?'"), Chars.CR), QuestionDialogMode.YesNoCancel);
EndProcedure
&AtClient
Procedure SwitchDisableFullAlertCapabilities(QuestionResult, AdditionalParameters) Export
	
	If (QuestionResult = DialogReturnCode.Yes) Then
		BringOptionsAndRulesToManSettings();
		FormItemsManagement();
		If NumberOfSettingsByOrganizationsDepartments > 0 Then
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure
&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure RecognizedInAITExpensesOnChange(Item)
	FormItemsManagement();
EndProcedure

&AtClient
Procedure FinancialAccountingGroupMABeginningOfChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	FinancialAccountingGroupBeginningOfChoice(Item, "CostAllocationOptionManag");
EndProcedure

&AtClient
Procedure FinancialAccountingGroupLocalStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	FinancialAccountingGroupBeginningOfChoice(Item, "CostAllocationOptionLocal");
EndProcedure

&AtClient
Procedure FinancialAccountingGroupTaxStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	FinancialAccountingGroupBeginningOfChoice(Item, "CostAllocationOptionTax");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		FormParameters = New Structure("ExpenseItem", Object.Ref);
		FormParameters.Insert("ExpenseTypeCategory", Object.ExpenseTypeCategory);
		FormParameters.Insert("CostAllocationOptionTax", Object.CostAllocationOptionTax);
		FormParameters.Insert("CostAllocationOptionManag", Object.CostAllocationOptionManag);
		FormParameters.Insert("CostAllocationOptionLocal", Object.CostAllocationOptionLocal);
		FormParameters.Insert("Predefined", Object.Predefined);
	
		OpenForm("ChartOfCharacteristicTypes.ExpenseItems.Form.AttributeUnlocking", FormParameters,,,,, New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
	EndIf;
	
EndProcedure

// Procedure-handler for executing the command.
//
// Parameters:
//	Command - FormCommand - form command.
//
&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	ExpenseItemsClientLocalization.ExecuteCommand(Command.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, Var_Parameters) Export
	
	If Var_Parameters.ServerCallRequired_ Then
		RunLocalizationCommandOnServer(CommandName);
	EndIf;
	
EndProcedure

&AtServer
Procedure RunLocalizationCommandOnServer(CommandName)
	
	ExpenseItemsLocalization.ExecuteCommand(CommandName, ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private
// StandardSubsystems.Properties

&AtClient
Procedure FinancialAccountingGroupBeginningOfChoice(Item, AllocationOption)
	
	FormParameters = New Structure;
	Filter = New Structure;
	Filter.Insert("Expenses", True);
	If Object[AllocationOption] = PredefinedValue("Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly") Then
		Filter.Insert("DistributableExpenses", False);
	Else
		Filter.Insert("DistributableExpenses", True);
	EndIf;
	FormParameters.Insert("Filter", Filter);
	
	OpenForm("Catalog.IncomeExpensesAccountingGroups.Form.ChoiceForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure DirectIndirectByAttributionSettings()

	Object.ClassifiedAsIndirectCostsByTaxAccounting = Object.CostAllocationOptionTax = Enums.CostAllocationOptions.ToLinesOfBusiness;

EndProcedure

&AtClient
Procedure HyperlinkDirectIndirectClick(Item)

	FullFunctionality = True;
	FormItemsManagement();
	ThisForm.CurrentItem = Items.CostSharingOptionNUPolnye;
	Items.GroupPages.CurrentPage = Items.GroupPageMain; 
	 
EndProcedure


&AtServer
Procedure ExpenseTypeCategoryOnChangeServer(TagName)
	
	ExpenseItemsLocalization.ExpenseTypeCategoryOnChange(ThisForm);
	
EndProcedure



&AtServer
Procedure CostAllocationRuleOfUprIsCompleteWhenChangingOnServer()
	If (Object.CostAllocationOptionLocal = Object.CostAllocationOptionManag) And Not ValueIsFilled(Object.CostAllocationRuleLocal) Then
		Object.CostAllocationRuleLocal = Object.CostAllocationRuleManag;
	EndIf;
EndProcedure


&AtServer
Procedure ExpensesOccurOnChangeServer(TagName)
	
	ValueTypeChanged =						False;
	OptionOfAllocatingManSExpensesHasChanged =	False;
	LocalCostAllocationOptionHasChanged =	False;
	
	If Items.ValueType.ChoiceList.FindByValue(ValueType) = Undefined Or Not ValueIsFilled(Object.CostAllocationOptionManag) Then
			ValueTypeChanged = 						True;
			If Object.ExpensesOccur = Enums.ExpenseTypes.PurchaseOfGoods Then
			ValueType = "DocumentRef.VendorInvoice";
			Variant = Enums.CostAllocationOptions.ToInventoryCost;
			Object.CostAllocationOptionManag =	Variant;
			Object.CostAllocationRuleToProcuctCost = Enums.RulesOfAllocationForInventoryCost.InProportionToProductQuantity;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		ElsIf Object.ExpensesOccur = Enums.ExpenseTypes.WarehouseStorage Then
			ValueType = "CatalogRef.Warehouses";
			Variant = Enums.CostAllocationOptions.ToInventoryCost;
			Object.CostAllocationOptionManag =	Variant;
			Object.CostAllocationRuleToProcuctCost = Enums.RulesOfAllocationForInventoryCost.InProportionToProductQuantity;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		ElsIf Object.ExpensesOccur = Enums.ExpenseTypes.SalesOfGoods Then
			ValueType = "CatalogRef.Partners";
			Variant = Enums.CostAllocationOptions.ToCostOfGoodsSold;
			Object.CostAllocationOptionManag =	Variant;
			Object.CostAllocationRuleToCostOfGoodsSoldMan = Enums.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		ElsIf Object.ExpensesOccur = Enums.ExpenseTypes.OtherExpenses Then
			ValueType = "CatalogRef.BusinessStructure";
			Variant = Enums.CostAllocationOptions.ToLinesOfBusiness;
			Variant = Enums.CostAllocationOptions.ToProductionCosts;
			Object.CostAllocationOptionManag =	Variant;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		ElsIf Object.ExpensesOccur = Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue Then
			ValueType = "CatalogRef.Assets";
			Variant = Enums.CostAllocationOptions.ToNonCurrentAssetCost;
			Object.CostAllocationOptionManag =	Variant;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		ElsIf Object.ExpensesOccur = Enums.ExpenseTypes.ManufactureOfProducts Then
			ValueType = "CatalogRef.ProductionLots";
			Variant = Enums.CostAllocationOptions.ToProductionCostDirect;
			Object.CostAllocationOptionManag =	Variant;
			Object.BaseOfAllocationByLots =			Enums.TypesOfCostAllocatingBase.ProductsQuantity;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		ElsIf Object.ExpensesOccur = Enums.ExpenseTypes.ExpenseToCostCenters Then
			ValueType = "CatalogRef.CostCenters";
			Variant = Enums.CostAllocationOptions.ToCostCenters;
			Object.CostAllocationOptionManag =	Variant;
			OptionOfAllocatingManSExpensesHasChanged =	True;
		EndIf;
	EndIf;
	
	If (OptionOfAllocatingManSExpensesHasChanged ) Then
		BringOptionsAndRulesToManSettings();
		LocalCostAllocationOptionHasChanged = True;
	EndIf;
	
	If ValueTypeChanged Then
		FillInVATValueType();
		ExpenseItemsLocalization.ValueTypeOnChangeServer(ThisForm);
	EndIf;
	
	If LocalCostAllocationOptionHasChanged Then
		ExpenseItemsLocalization.CostAllocationOptionLocalOnChangeServer(ThisForm);
	EndIf;
	
	If Not Object.ControlDimensionFilling And 
		(Object.ExpensesOccur = Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue
			Or Object.ExpensesOccur = Enums.ExpenseTypes.ExpenseToCostCenters
			Or Object.ExpensesOccur = Enums.ExpenseTypes.ManufactureOfProducts) 
	Then
		Object.ControlDimensionFilling = True;
	EndIf;
		
	FillInListOfTypesOfExpenseAnalytics();
	
	ClearInaccessibleBusinessTransactions();
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure ValueTypeOnChangeServer(TagName)
	
	If Not IsBlankString(ValueType) Then
		If ValueType = "DocumentRef.SalesOrder"
			Or ValueType = "DocumentRef.CustomerInvoice"
		Then
			Object.DimensionOfExpensesOrderImplementation = True;
			Object.ValueType = ChartsOfCharacteristicTypes.ExpenseItems.TypesOfDocumentsArticlesDistributedForSale();
		ElsIf ValueType = "CatalogRef.ConstructionObjects22" Then
			Object.DimensionOfExpensesOrderImplementation = False;
			Object.ValueType = New TypeDescription("CatalogRef.Assets");
		ElsIf ValueType = "CatalogRef.ProductionLots" And Object.ExpensesOccur = Enums.ExpenseTypes.ManufactureOfProducts Then
			Object.BaseOfAllocationByLots = Enums.TypesOfCostAllocatingBase.ProductsQuantity;
		Else
			Object.DimensionOfExpensesOrderImplementation = False;
			Object.ValueType = New TypeDescription(ValueType);
		EndIf;
	EndIf;
	Object.IntangibleAssetsAndRDExpenses = False;
	Object.ExpensesOnConstructionObjects = False;
	Object.ExpensesOnAssets = False;
	Object.ResearchAndDevelopmentExpenses = False;
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
		If ValueType = "CatalogRef.Assets" Then
			Object.ExpensesOnAssets = True;
		ElsIf ValueType = "CatalogRef.ConstructionObjects"
		 Or ValueType = "CatalogRef.ConstructionObjects22" Then
			Object.ExpensesOnConstructionObjects = True;
		ElsIf ValueType = "CatalogRef.IntangibleAssets" Then
			Object.IntangibleAssetsAndRDExpenses = True;
		ElsIf ValueType = "CatalogRef.RDTopicsStages" Then
			Object.ResearchAndDevelopmentExpenses = True;
		EndIf;
	EndIf;
	FillInVATValueType();
	
	FormItemsManagement();
	
	ExpenseItemsLocalization.ValueTypeOnChangeServer(ThisForm);
	
EndProcedure

&AtServer
Procedure CostAllocationOptionLocalOnChangeServer()
	AvailabilityOfAnalystFillControl = True;
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
		Object.ExpensesOnConstructionObjects = False;
		Object.ExpensesOnAssets = False;
		Object.IntangibleAssetsAndRDExpenses = False;
		If ValueType = "CatalogRef.Assets" Then
			Object.ExpensesOnAssets = True;
		ElsIf ValueType = "CatalogRef.ConstructionObjects" Or ValueType = "CatalogRef.ConstructionObjects22" Then
			Object.ExpensesOnConstructionObjects = True;
		ElsIf ValueType = "CatalogRef.IntangibleAssets" Then
			Object.IntangibleAssetsAndRDExpenses = True;
		ElsIf ValueType = "CatalogRef.RDTopicsStages" Then
				Object.ResearchAndDevelopmentExpenses = True;
		EndIf;
	EndIf;
	ClearInaccessibleBusinessTransactions();
	
	FillInVATValueType();
	
	ExpenseItemsLocalization.CostAllocationOptionLocalOnChange(ThisForm);
	
EndProcedure

&AtServer
Procedure CostAllocationOptionManagOnChangeServer()
	
	ClearInaccessibleBusinessTransactions();
	
EndProcedure

#EndRegion


#Region Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure DetermineUseOfFullCapabilities()
	
	FullFunctionality = False;
	
	If BaseVersion Then
		Return
	EndIf;
	
	FullFunctionality = (Object.CostAllocationOptionManag <> Object.CostAllocationOptionLocal);
	If FullFunctionality Then
		Return;
	EndIf;
	FullFunctionality = FullFunctionality Or (Object.CostAllocationOptionLocal <> Object.CostAllocationOptionTax);
	FullFunctionality = FullFunctionality Or (Object.CostAllocationOptionManag <> Object.CostAllocationOptionTax);
	If FullFunctionality Then
		Return;
	EndIf;
	Rules = New Map();
	If Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToInventoryCost 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToLinesOfBusiness 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToDeferredExpenses 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCosts
	Then
		Rules.Insert(Object.CostAllocationRuleManag);
	ElsIf Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostOfGoodsSold 
	Then
		Rules.Insert(Object.CostAllocationRuleToCostOfGoodsSoldMan);
	EndIf;
	
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts
	Then
		Rules.Insert(Object.CostAllocationRuleLocal);
	ElsIf Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostOfGoodsSold 
	Then
		Rules.Insert(Object.CostAllocationRuleToCostOfGoodsSoldLocal);
	EndIf;
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses 
	Then
		Rules.Insert(Object.CostAllocationRuleTax);
	EndIf;
	FullFunctionality = FullFunctionality Or Rules.Count() > 1;
	FullFunctionality = FullFunctionality Or NumberOfSettingsByOrganizationsDepartments > 0;
EndProcedure
&AtServer
Procedure FillInSelectionListOfDistributionBasesByBatch()
	SupportedTypes = Enums.TypesOfCostAllocatingBase.TypesOfDirectCostAllocationBases();
	Items.TheBaseOfDistributionByParty.ChoiceList.LoadValues(SupportedTypes);
	Items.DistributionBaseByBatchUprComplete.ChoiceList.LoadValues(SupportedTypes);
	Items.DatabaseOfDistributionByBatchReglComplete.ChoiceList.LoadValues(SupportedTypes);
EndProcedure
&AtServer
Procedure FormItemsManagement()
	
	ExpenseItemsServer.FormItemsManagement(ThisForm);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfAnalyticsValueTypes()
	
	ListOfExcludedTypes = New ValueList;
	
	If Not GetFunctionalOption("UseSalesOrders") Then
		ListOfExcludedTypes.Add("DocumentRef.SalesOrder");
	EndIf;
		
	If Not GetFunctionalOption("UsePurchaseOrders") Then
		ListOfExcludedTypes.Add("DocumentRef.PurchaseOrder");
	EndIf;
	
	If Not GetFunctionalOption("UseTransferOrders") Then
		ListOfExcludedTypes.Add("DocumentRef.TransferOrder");
	EndIf;
	
	If Not GetFunctionalOption("UseSalesOpportunitiesToCustomer") Then
		ListOfExcludedTypes.Add("CatalogRef.SalesOpportunitiesToCustomer");
	EndIf;
	
	If Not GetFunctionalOption("UsePaymentByCards") Then
		ListOfExcludedTypes.Add("CatalogRef.POSTerminals");
	EndIf;
	
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		ListOfExcludedTypes.Add("DocumentRef.CustomerInvoiceIntercompany");
	EndIf;
	
	If Not GetFunctionalOption("RecordComplaints") Then
		ListOfExcludedTypes.Add("CatalogRef.Complaints");
	EndIf;
	
	If Not GetFunctionalOption("UseMarketingActivities") Then
		ListOfExcludedTypes.Add("CatalogRef.MarketingActivities");
	EndIf;
	
	If Not GetFunctionalOption("UseGoodsTransfer") Then
		ListOfExcludedTypes.Add("DocumentRef.InventoryTransfer");
	EndIf;
	
	If Not GetFunctionalOption("GenerateFinancialResult")
	 Or GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
		And Not Object.ValueType.ContainsType(Type("CatalogRef.LinesOfBusiness")) Then
		ListOfExcludedTypes.Add("CatalogRef.LinesOfBusiness");
	EndIf;
	
	If Not GetFunctionalOption("UseProjects") Then
		ListOfExcludedTypes.Add("CatalogRef.Projects");
	EndIf;
	If Not GetFunctionalOption("UseNonCurrentAssets2_2")
		And Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		ListOfExcludedTypes.Add("CatalogRef.Assets");
		ListOfExcludedTypes.Add("CatalogRef.IntangibleAssets");
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Then
		ExpenseItemsLocalization.AddSalaryAccountingAnalystsToListOfTypes(ListOfExcludedTypes);
	EndIf;
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		ListOfExcludedTypes.Add("EnumRef.ExchangeDifferencesDimension");
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		ListOfExcludedTypes.Add("CatalogRef.BusinessStructure");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		ListOfExcludedTypes.Add("CatalogRef.Companies");
	EndIf;
	
	If Not GetFunctionalOption("UseLoanAndDepositContracts") Then
		ListOfExcludedTypes.Add("CatalogRef.LoanAndDepositContracts");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCashAccounts") Then
		ListOfExcludedTypes.Add("CatalogRef.CashAccounts");
	EndIf;
	
	If Not GetFunctionalOption("UseAssemblyDisassemblyOrders") Then
		ListOfExcludedTypes.Add("DocumentRef.ByAssemblyDisassemblyOrder");
	EndIf;
	
	If Not GetFunctionalOption("UseAssemblyDisassembly") Then
		ListOfExcludedTypes.Add("DocumentRef.AssemblyFromComponents");
	EndIf;
	
	If Not GetFunctionalOption("UseImports") Then
		ListOfExcludedTypes.Add("DocumentRef.CCDImport");
	EndIf;
	If Not GetFunctionalOption("UseNonCurrentAssets2_2") Then
		ListOfExcludedTypes.Add("CatalogRef.ConstructionObjects22");
	EndIf;
	
	If Not GetFunctionalOption("UseConstructionObjects") Then
		ListOfExcludedTypes.Add("CatalogRef.ConstructionObjects");
	EndIf;
	
	If Not GetFunctionalOption("GenerateFutureExpenseCommitments") Then
		ListOfExcludedTypes.Add("CatalogRef.AccountingObjectsOfFutureExpenseCommitments");
	EndIf;
	
	If Not GetFunctionalOption("UseProductionByThirdParty2_5") Then
		ListOfExcludedTypes.Add("DocumentRef.SubcontractorReport2_5");
	EndIf;
	
	If Not GetFunctionalOption("UseProductionManagement2_2") Then
		ListOfExcludedTypes.Add("DocumentRef.BackflushProduction");
	EndIf;
	

	
	If Not GetFunctionalOption("UseProductionManagement2_2") Then
		ListOfExcludedTypes.Add("DocumentRef.ProductionOrder2_2");
		ListOfExcludedTypes.Add("DocumentRef.ProductionStage2_2");
	EndIf;
	If Not GetFunctionalOption("UseUninvoicedDeliveries")
	 And Not GetFunctionalOption("UseGoodsInTransitFromVendors") Then
		ListOfExcludedTypes.Add("DocumentRef.ReceiptOfGoodsToWarehouse");
	EndIf;
	If Not GetFunctionalOption("UseRMManagement") Then
		ListOfExcludedTypes.Add("DocumentRef.RMOrder");
	EndIf;
	
	If Not GetFunctionalOption("UseTollManufacturing2_5") Then
		ListOfExcludedTypes.Add("DocumentRef.ReportToMaterialProvider2_5");
	EndIf;
	
	If Not GetFunctionalOption("UseInternalSubcontracting") Then
		ListOfExcludedTypes.Add("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	EndIf;
	If Not GetFunctionalOption("UseCustodyDuringPurchase") Then
		ListOfExcludedTypes.Add("DocumentRef.RedemptionOfGoodsFromStorage");
	EndIf;
	
	Field = Items.ValueType;
	For Each Item In ListOfExcludedTypes Do
		ListItem = Field.ChoiceList.FindByValue(Item.Value);
		If ListItem <> Undefined And ValueType <> Item.Value Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndDo;
		
EndProcedure
&AtServer
Procedure UpdateNumberOfSettingsForOrganizationsDivisions()
	NumberOfSettingsByOrganizationsDepartments = 
		InformationRegisters.SettingsOfItemizedExpensesAllocation.GetNumberOfSettingsForArticle(Object.Ref);
EndProcedure
&AtClient
Procedure UpdateLabelNumberOfSettingsByOrganizationDivision()
	Items.LabelSetUpDistributionRules.Title = 
		GetLabelNumberOfSettingsByOrganizationDivision();
EndProcedure
&AtServer
Function GetLabelNumberOfSettingsByOrganizationDivision()
	If NumberOfSettingsByOrganizationsDepartments > 0 Then
		If CurrentLanguage().LanguageCode = "ru" Then
			Result = StrTemplate(
					NStr("vi = '%1 %2 phân bổ theo doanh nghiệp và bộ phận';
						|ru = '%1 %2 распределения по организациям и подразделениям';
						|en = '%1 %2 allocations by companies and business units'; fa = '%1 %2 allocations by companies and business units';
						|it = '%1 %2 распределения по организациям и подразделениям';
						|pl = '%1 %2 allocations by companies and business units';
						|tr = 'İş yerleri ve departmanlar için dağıtım %2 %1'"),
					?(NumberOfSettingsByOrganizationsDepartments % 10 = 1 
						And NumberOfSettingsByOrganizationsDepartments % 100 <> 11,
						NStr("vi = 'Đã xác định';
							|ru = 'Задано';
							|en = 'Specified'; fa = 'مشخص‌شده';
							|it = 'Задано';
							|pl = 'Specified';
							|tr = 'Belirtildi'"), 
						NStr("vi = 'Đã xác định';
							|ru = 'Задано';
							|en = 'Specified'; fa = 'مشخص‌شده';
							|it = 'Задано';
							|pl = 'Specified';
							|tr = 'Belirtildi'")),
					GetStringDeclensionsByNumber(NStr("vi = 'Tùy chỉnh';
														|ru = 'настройка';
														|en = 'setting'; fa = 'setting';
														|it = 'настройка';
														|pl = 'setting';
														|tr = 'ayarı'"), NumberOfSettingsByOrganizationsDepartments,,"L=ru_RU;")[0]);
		Else
			Result = StrTemplate(
					NStr("vi = 'Đã đặt tùy chỉnh phân bổ theo doanh nghiệp và bộ phận: %1';
						|ru = 'Задано настроек распределения по организациям и подразделениям: %1';
						|en = 'Allocation settings by companies and business units specified: %1'; fa = 'Allocation settings by companies and business units specified: %1';
						|it = 'Impostazioni di distribuzione impostate per aziende e sezioni: %1';
						|pl = 'Zadano ustawień przydzielenia wg firm i działów: %1';
						|tr = 'İş yerleri ve departmanlar için dağıtım ayarları belirlendi: %1'"), 
						NumberOfSettingsByOrganizationsDepartments);
		EndIf;
	Else
		Result = NStr("vi = 'Tùy chỉnh quy tắc phân bổ theo các doanh nghiệp và bộ phận';
						|ru = 'Настроить правила распределения по организациям и подразделениям';
						|en = 'Set up allocation rules by companies and business units'; fa = 'تنظیم قواعد تسهیم بر اساس شرکت‌ها و واحدهای تجاری';
						|it = 'Configurare le regole di allocazione delle organizzazioni e dei dipartimenti';
						|pl = 'Ustaw zasady podziału wg firm i działów';
						|tr = 'İş yerleri ve departmanlar için dağıtım kuralları ayarla'");
	EndIf;
	Return Result;
EndFunction
#EndRegion

#Region Other

&AtServer
Procedure BringOptionsAndRulesToManSettings()
	
	Object.CostAllocationOptionLocal = Object.CostAllocationOptionManag; 
	Object.CostAllocationRuleLocal = Object.CostAllocationRuleManag;
	Object.CostAllocationRuleToCostOfGoodsSoldLocal = Object.CostAllocationRuleToCostOfGoodsSoldMan;
	

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ThisIsUT = GetFunctionalOption("TradeManagement");
	BaseVersion = GetFunctionalOption("BaseVersion");
	ComplAccountingIsUsed = GetFunctionalOption("UseLocal");
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	Items.GroupPageReglAccounting.Title = NStr("vi = 'Kế toán doanh nghiệp và thuế';
												|ru = 'Бухгалтерский учет и налоги';
												|en = 'Local accounting and taxes'; fa = 'حسابداری محلی و مالیات‌ها';
												|it = 'Contabilità e imposte';
												|pl = 'Ewidencja księgowa i podatki';
												|tr = 'Muhasebe ve vergiler'");
	Items.LabelSetUpDistributionRules.Visible = 
		AccessRight("Update", Metadata.InformationRegisters.SettingsOfItemizedExpensesAllocation);
	Items.LabelSetUpDistributionRules.Enabled = ValueIsFilled(Object.Ref);
	If Not (ComplAccountingIsUsed 
		Or GetFunctionalOption("UseFinancialAccounting")
		)
	Then
		Items.GroupPageReglAccounting.Visible = False;
	EndIf;
	
	// The "Financial Accounting Group" field in the WE version is displayed on the "Main" tab, 
	// because in the WE version the "Accounting and Taxes" tab does not make sense.
	Items.IFIsFinancialAccountingGroup.Visible = Not LocalizationRFService;
	Items.FinancialAccountingGroup.Visible = LocalizationRFService;
	
	Items.CorrespondingAccountGroup.Visible = False;
	If ThisIsUT Or Not ComplAccountingIsUsed Or Not LocalizationRFService Then
		Items.CorrespondingAccountGroup.Visible = True;
		Items.OffsettingAccount.Mask = DataExchangeEventsTMERP.AccountMask();
		If Not LocalizationRFService Then
			Items.OffsettingAccount.DropListButton = False;
		EndIf;
	EndIf;
	
	If ThisIsUT Then
		ListItem = Items.ExpenseTypeCategory.ChoiceList.FindByValue(Enums.ExpenseActivityTypes.CoreAndOtherActivity); 
		If ListItem <> Undefined Then
			Items.ExpenseTypeCategory.ChoiceList.Delete(ListItem);
		EndIf;
		Items.SwitchToUseFullFeatures.Visible = Not BaseVersion;
		Items.LabelSetUpDistributionRules.Visible = False;
	EndIf;
	UpdateNumberOfSettingsForOrganizationsDivisions();
	DetermineUseOfFullCapabilities();

	GenerateFinancialResult = GetFunctionalOption("GenerateFinancialResult");
	
	FillInListOfTypesOfExpenseAnalytics();
	SetValueType(Object.ValueType);
	FormItemsManagement();
	FillInListOfAvailableBusinessOperations();
	
	ExpenseItemsLocalization.OnReadCreateAtServer(ThisForm);
	
EndProcedure

&AtServer
Procedure SetValueType(SelectedValueType)
	
	If SelectedValueType = Undefined Then
		If GetFunctionalOption("BaseVersion") Then
			SelectedValueType = New TypeDescription("CatalogRef.Warehouses");
		Else
			SelectedValueType = New TypeDescription("CatalogRef.Companies");
		EndIf;
	EndIf;
	
	TypesToExclude = New Array;
	// Auxiliary type for displaying in the form of an expense item of the analytics type "Construction sites (2.2)".
	// There is no such type in metadata.
	TypesToExclude.Add("CatalogRef.ConstructionObjects22");
	ListOfValueTypes = Items.ValueType.ChoiceList;
	For Each ListItem In ListOfValueTypes Do
		If TypesToExclude.Find(ListItem.Value) <> Undefined Then
			Continue;
		EndIf;
		If SelectedValueType.ContainsType(Type(ListItem.Value)) Then
			ValueType = ListItem.Value;
			If ListItem.Value = "CatalogRef.Assets"
			 And Object.VATAssetTaxClass = Enums.AssetKinds.ConstructionInProgressObjects Then
				ValueType = "CatalogRef.ConstructionObjects22";
			EndIf;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearInaccessibleBusinessTransactions()
	
	CurAvailableBusinessOperations = Common.CopyRecursive(AvailableBusinessTransactions);
	
	ChartsOfCharacteristicTypes.ExpenseItems.FillInListOfBusinessOperations(
		AvailableBusinessTransactions,
		Object.CostAllocationOptionManag,
		Object.CostAllocationOptionLocal);
		
	For Each CurListItem In CurAvailableBusinessOperations Do
		If Not CurListItem.Check Then
			Continue;
		EndIf;
		ListItem = AvailableBusinessTransactions.FindByValue(CurListItem.Value);
		If ListItem <> Undefined Then
			ListItem.Check = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInListOfAvailableBusinessOperations()
	
	ChartsOfCharacteristicTypes.ExpenseItems.FillInListOfBusinessOperations(
		AvailableBusinessTransactions,
		Object.CostAllocationOptionManag,
		Object.CostAllocationOptionLocal);
	
	For Each TableRow In Object.AvailableBusinessTransactions Do
		ListItem = AvailableBusinessTransactions.FindByValue(TableRow.BusinessOperation);
		If ListItem <> Undefined Then
			ListItem.Check = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInListOfTypesOfExpenseAnalytics()
	
	ChoiceList = Items.ValueType.ChoiceList;
	ChoiceList.Clear();
	
	If False Then
	ElsIf Object.Ref = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods") Then
		ChoiceList.Add("CatalogRef.Products", 		NStr("vi = 'Mặt hàng';
															|ru = 'Номенклатура';
															|en = 'Item'; fa = 'قلم';
															|it = 'Articolo';
															|pl = 'Item';
															|tr = 'Öğe'"));
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.PurchaseOfGoods") Then
		ChoiceList.Add("DocumentRef.PurchaseOrder", 					NStr("vi = 'Đơn hàng đặt nhà cung cấp';
																			|ru = 'Заказ поставщику';
																			|en = 'Purchase order'; fa = 'سفارش خرید';
																			|it = 'Ordine al fornitore';
																			|pl = 'Zamówienie do dostawcy';
																			|tr = 'Satın alma siparişi'"));
		ChoiceList.Add("DocumentRef.VendorInvoice", 			NStr("vi = 'Mua hàng hóa và dịch vụ';
																	|ru = 'Приобретение товаров и услуг';
																	|en = 'Vendor invoice'; fa = 'فاکتور تأمین‌کننده';
																	|it = 'Acquisti di beni e servizi';
																	|pl = 'Nabycie towarów i usług';
																	|tr = 'Satın alma faturası'"));
		ChoiceList.Add("DocumentRef.ReceiptOfGoodsToWarehouse", 					NStr("vi = 'Tiếp nhận hàng hóa';
																						|ru = 'Поступление товаров';
																						|en = 'Receipt of goods'; fa = 'رسید کالا';
																						|it = 'Arrivo delle merci';
																						|pl = 'Wpływ towarów';
																						|tr = 'İrsaliye'"));
		If ThereIsInputOfRemnantsOfOldSample() Then
			ChoiceList.Add("DocumentRef.OBEntry", 						NStr("vi = 'Nhập số dư đầu kỳ';
																				|ru = 'Ввод остатков';
																				|en = 'OB entry'; fa = 'OB entry';
																				|it = 'Inserimento dei saldi';
																				|pl = 'Wpisanie zapasów';
																				|tr = 'Bakiyeyi gir'"));
			ChoiceList.Add("DocumentRef.OBEntryGoods", 				NStr("vi = 'Nhập số dư (2.5)';
																			|ru = 'Ввод остатков (2.5)';
																			|en = 'Enter balance by (2.5)'; fa = 'Enter balance by (2.5)';
																			|it = 'Inserimento saldi (2.5)';
																			|pl = 'Wprowadzenie sald (2.5)';
																			|tr = 'Bakiye girişi (2.5)'"));
		Else
			ChoiceList.Add("DocumentRef.OBEntryGoods", 				NStr("vi = 'Nhập số dư đầu kỳ';
																			|ru = 'Ввод остатков';
																			|en = 'OB entry'; fa = 'OB entry';
																			|it = 'Inserimento dei saldi';
																			|pl = 'Wpisanie zapasów';
																			|tr = 'Bakiyeyi gir'"));
		EndIf;
		ChoiceList.Add("DocumentRef.CustomerInvoiceIntercompany", 	NStr("vi = 'Chuyển giao hàng hóa giữa các doanh nghiệp';
																			|ru = 'Передача товаров между организациями';
																			|en = 'Customer invoice — Intercompany'; fa = 'فاکتور مشتری — بین‌شرکتی';
																			|it = 'Trasferimento delle merci tra le organizzazioni';
																			|pl = 'Przekazanie towarów pomiędzy firmami';
																			|tr = 'İş yerleri arasında ürünler transferi'"));
		ChoiceList.Add("DocumentRef.CCDImport", 			NStr("vi = 'Tờ khai hải quan';
																|ru = 'Таможенная декларация';
																|en = 'Customs declaration'; fa = 'اظهارنامه گمرکی';
																|it = 'Dichiarazione doganale';
																|pl = 'Deklaracja celna';
																|tr = 'Gümrük beyannamesi'"));
		If GetFunctionalOption("UseCustodyDuringPurchase") Then
			ChoiceList.Add("DocumentRef.RedemptionOfGoodsFromStorage", 			NStr("vi = 'Mua lại hàng hóa từ kho cất giữ';
																						|ru = 'Выкуп товаров с хранения';
																						|en = 'Purchase invoice — VMI'; fa = 'فاکتور خرید — VMI';
																						|it = 'Riscatto delle merci dal deposito';
																						|pl = 'Wykup towarów z depozytu';
																						|tr = 'Satın alma faturası - VMI'"));
		EndIf;
		
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.WarehouseStorage") Then
		ChoiceList.Add("CatalogRef.Warehouses", 			NStr("vi = 'Kho bãi (Vị trí lưu trữ)';
																|ru = 'Склад (Место хранения)';
																|en = 'Warehouse (Storage location)'; fa = 'Warehouse (Storage location)';
																|it = 'Magazzino (luogo di stoccaggio)';
																|pl = 'Magazyn (Miejsce przechowywania)';
																|tr = 'Ambar (Depolama yeri)'"));
		ChoiceList.Add("CatalogRef.Products", 		NStr("vi = 'Mặt hàng';
															|ru = 'Номенклатура';
															|en = 'Item'; fa = 'قلم';
															|it = 'Articolo';
															|pl = 'Item';
															|tr = 'Öğe'"));
		ChoiceList.Add("DocumentRef.TransferOrder", 	NStr("vi = 'Đơn hàng điều chuyển nội bộ';
															|ru = 'Заказ на перемещение';
															|en = 'Transfer order'; fa = 'سفارش انتقال';
															|it = 'Ordine di trasferimento';
															|pl = 'Zamówienie na przesunięcie';
															|tr = 'Transfer emri'"));
		ChoiceList.Add("DocumentRef.InventoryTransfer", 	NStr("vi = 'Điều chuyển hàng hóa nội bộ';
																|ru = 'Перемещение товаров';
																|en = 'Goods transfer'; fa = 'انتقال کالا';
																|it = 'Trasferimento delle merci';
																|pl = 'Przemieszczenie towarów';
																|tr = 'Mal transferi'"));
		ChoiceList.Add("DocumentRef.ByAssemblyDisassemblyOrder", 		NStr("vi = 'Đơn hàng đóng bộ (tách bộ)';
																				|ru = 'Заказ на сборку (разборку)';
																				|en = 'Kitting order'; fa = 'سفارش کیت‌سازی';
																				|it = 'Ordine di assemblaggio/disassemblaggio';
																				|pl = 'Zamówienie na montaż';
																				|tr = 'Montaj (demontaj) emri'"));
		ChoiceList.Add("DocumentRef.AssemblyFromComponents", 		NStr("vi = 'Đóng bộ (tách bộ) hàng hóa';
																			|ru = 'Сборка (разборка) товаров';
																			|en = 'Product kitting'; fa = 'کیت‌سازی محصول';
																			|it = 'Assemblaggio (disassemblaggio) di merci';
																			|pl = 'Montaż (demontaż) towarów';
																			|tr = 'Ürünlerin montajı (demontajı)'"));
		ChoiceList.Add("DocumentRef.OtherGoodsRecordingAsReceived", 	NStr("vi = 'Thu nhập khác';
																			|ru = 'Прочее оприходование';
																			|en = 'Other recording as received'; fa = 'Other recording as received';
																			|it = 'Altro registrazione in contabilità';
																			|pl = 'Inne zaprzychodowanie';
																			|tr = 'Diğer envantere giriş'"));
		ChoiceList.Add("DocumentRef.BackflushProduction", 		NStr("vi = 'Sản xuất không theo đơn đặt hàng';
																		|ru = 'Производство без заказа';
																		|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
																		|it = 'Produzione senza ordine';
																		|pl = 'Produkcja bez zamówień';
																		|tr = 'Geriye dönük üretim'"));
		
		UseProductionByThirdParty2_5 = GetFunctionalOption("UseProductionByThirdParty2_5");
		UseTransferToCustodyWithRightOfSale = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
		UseTollManufacturing2_5 = GetFunctionalOption("UseTollManufacturing2_5");
		If UseProductionByThirdParty2_5 And UseTransferToCustodyWithRightOfSale Then
			StringProcessorKeeper = NStr("vi = 'Bên nhận gia công/bên bảo quản';
										|ru = 'Переработчик/хранитель';
										|en = 'Subcontractor/custodian'; fa = 'Subcontractor/custodian';
										|it = 'Elaboratore/magazzino';
										|pl = 'Przetwórca/opiekun';
										|tr = 'Fason üretici/Emanetçi'");
			StringContractProcessorKeeper = NStr("vi = 'Hợp đồng với bên nhận gia công/bên bảo quản';
												|ru = 'Договор с переработчиком/хранителем';
												|en = 'Contract with subcontractor/custodian'; fa = 'Contract with subcontractor/custodian';
												|it = 'Accordo con elaboratore/magazzino';
												|pl = 'Umowa z przetwórcą/opiekunem';
												|tr = 'Fason üretici/emanetçi sözleşmesi'");
			StringReceiptFromProcessorKeeper = NStr("vi = 'Tiếp nhận từ bên nhận gia công/bên bảo quản';
													|ru = 'Поступление от переработчика/хранителя';
													|en = 'Receipt from subcontractor/custodian'; fa = 'Receipt from subcontractor/custodian';
													|it = 'Ricezione dall''elaboratore/magazzino';
													|pl = 'Wpływ od przetwórcy/opiekuna';
													|tr = 'Fason üretici/emanetçiden alınan'");
		ElsIf UseProductionByThirdParty2_5 Then
			StringProcessorKeeper = NStr("vi = 'Bên nhận gia công';
										|ru = 'Переработчик';
										|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
										|it = 'Subfornitore';
										|pl = 'Przetwórca';
										|tr = 'Fason üretici'");
			StringContractProcessorKeeper = NStr("vi = 'Hợp đồng với bên nhận gia công';
												|ru = 'Договор с переработчиком';
												|en = 'Contract with subcontractor'; fa = 'Contract with subcontractor';
												|it = 'Accordo con il subfornitore';
												|pl = 'Umowa z przetwórcą';
												|tr = 'Fason üretici sözleşmesi'");
			StringReceiptFromProcessorKeeper = NStr("vi = 'Tiếp nhận từ người nhận gia công';
													|ru = 'Поступление от переработчика';
													|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
													|it = 'Ricezione dal subfornitore';
													|pl = 'Wpływ od przetwórcy';
													|tr = 'Fason üreticiden alınan'");
		ElsIf UseTransferToCustodyWithRightOfSale Then
			StringProcessorKeeper = NStr("vi = 'Bên bảo quản';
										|ru = 'Хранитель';
										|en = 'Custodian'; fa = 'امین';
										|it = 'Depositario';
										|pl = 'Przechowywujący';
										|tr = 'Emanetçi'");
			StringContractProcessorKeeper = NStr("vi = 'Hợp đồng với bên bảo quản';
												|ru = 'Договор с хранителем';
												|en = 'Custodian contract'; fa = 'Custodian contract';
												|it = 'Accordo con il custode';
												|pl = 'Umowa powiernicza';
												|tr = 'Emanetçi sözleşmesi'");
			StringReceiptFromProcessorKeeper = NStr("vi = 'Tiếp nhận từ bên bảo quản';
													|ru = 'Поступление от хранителя';
													|en = 'Receipt from the custodian'; fa = 'Receipt from the custodian';
													|it = 'Consegne dal depositario';
													|pl = 'Wpływ do depozytariusza';
													|tr = 'Emanetçiden alınan'");
		Else
			StringProcessorKeeper = "";
			StringContractProcessorKeeper = "";
			StringReceiptFromProcessorKeeper = "";
		EndIf;
		
		If UseProductionByThirdParty2_5 Or UseTransferToCustodyWithRightOfSale Then
			ChoiceList.Add("CatalogRef.Partners",					StringProcessorKeeper);
			ChoiceList.Add("CatalogRef.CounterpartyContracts",		StringContractProcessorKeeper);
		EndIf;
		
		
		If StringReceiptFromProcessorKeeper <> "" Then
			ChoiceList.Add("DocumentRef.ReceiptOfGoodsFromCustodian", 	StringReceiptFromProcessorKeeper);
		EndIf;
		
		If UseProductionByThirdParty2_5 Then
			ChoiceList.Add("DocumentRef.SubcontractorReport2_5", 	NStr("vi = 'Bảng kê hàng hóa của bên nhận gia công';
																			|ru = 'Отчет переработчика';
																			|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
																			|it = 'Report subfornitore';
																			|pl = 'Raport przetwórcy';
																			|tr = 'Alınan fason üretici hizmetleri bildirimi'"));
		EndIf;
		ChoiceList.Add("DocumentRef.ProductionStage2_2", 		NStr("vi = 'Công đoạn sản xuất';
																		|ru = 'Этап производства';
																		|en = 'Production stage'; fa = 'مرحله تولید';
																		|it = 'Fase di produzione';
																		|pl = 'Etap produkcji';
																		|tr = 'Üretim aşaması'"));
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.SalesOfGoods") Then
		ChoiceList.Add("CatalogRef.Partners",					NStr("vi = 'Khách hàng';
																		|ru = 'Клиент';
																		|en = 'Customer'; fa = 'مشتری';
																		|it = 'Cliente';
																		|pl = 'Klient';
																		|tr = 'Müşteri'"));
		ChoiceList.Add("CatalogRef.SalesOpportunitiesToCustomer",			NStr("vi = 'Vụ việc';
																					|ru = 'Сделка';
																					|en = 'Sales opportunity'; fa = 'فرصت فروش';
																					|it = 'Transazione';
																					|pl = 'Umowa';
																					|tr = 'Satış fırsatı'"));
		If GetFunctionalOption("UseSalesOrders") Then
			ChoiceList.Add("DocumentRef.SalesOrder",			NStr("vi = 'Đơn hàng / Giao hàng';
																	|ru = 'Заказ / Реализация';
																	|en = 'Order / Sale'; fa = 'سفارش / فروش';
																	|it = 'Ordine / Vendita';
																	|pl = 'Zamówienie / Sprzedaż';
																	|tr = 'Sipariş / Satış'"));
		Else
			ChoiceList.Add("DocumentRef.CustomerInvoice",	NStr("vi = 'Giao hàng và cung cấp dịch vụ';
																	|ru = 'Реализация товаров и услуг';
																	|en = 'Customer invoice'; fa = 'فاکتور مشتری';
																	|it = 'Realizzo di beni e servizi';
																	|pl = 'Sprzedaż towarów i usług';
																	|tr = 'Müşteri faturası'"));
		EndIf;
		If GetFunctionalOption("UseTollManufacturing2_5") Then
			ChoiceList.Add("DocumentRef.ReportToMaterialProvider2_5",		NStr("vi = 'Bảng kê dành cho bên đặt gia công';
																					|ru = 'Отчет давальцу';
																					|en = 'Consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف — خدمات پیمانکاری فرعی ارائه‌شده';
																					|it = 'Report al committente di materie prime';
																					|pl = 'Raport dla właściciela surowców';
																					|tr = 'Tüketim raporu-Verilen fason hizmetleri'"));
		EndIf;
		
		If GetFunctionalOption("UseInternalSubcontracting") Then
			ChoiceList.Add("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany", NStr("vi = 'Báo cáo dành cho người đặt gia công giữa các doanh nghiệp';
																											|ru = 'Отчет давальцу между организациями';
																											|en = 'Intercompany consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف بین‌شرکتی — خدمات پیمانکاری فرعی ارائه‌شده';
																											|it = 'Отчет давальцу между организациями';
																											|pl = 'Intercompany consumption report — Subcontracting services delivered';
																											|tr = 'İş yerleri arası Tüketim raporu-Verilen fason hizmetleri'"));
		EndIf;
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.ManufactureOfProducts") Then
		ChoiceList.Add("DocumentRef.ProductionOrder2_2",						NStr("vi = 'Đơn hàng sản xuất';
																					|ru = 'Заказ на производство';
																					|en = 'Production order'; fa = 'سفارش تولید';
																					|it = 'Ordine di produzione';
																					|pl = 'Zlecenie produkcyjne';
																					|tr = 'Üretim emri'"));
		ChoiceList.Add("CatalogRef.ProductionLots",						NStr("vi = 'Lô sản xuất';
																				|ru = 'Партия производства';
																				|en = 'Production lot'; fa = 'بچ تولید';
																				|it = 'Lotto di produzione';
																				|pl = 'Partia produkcji';
																				|tr = 'Üretim lotu'"));
		ChoiceList.Add("CatalogRef.Products",								NStr("vi = 'Sản phẩm';
																					|ru = 'Продукция';
																					|en = 'Manufactured products'; fa = 'محصولات تولیدی';
																					|it = 'Prodotti';
																					|pl = 'Manufactured products';
																					|tr = 'İmal edilen ürünler'"));
		If GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
			ChoiceList.Add("CatalogRef.AnalyticalInventoryGroups",		NStr("vi = 'Nhóm sản phẩm';
																				|ru = 'Группа продукции';
																				|en = 'Inventory group'; fa = 'گروه موجودی';
																				|it = 'Gruppo prodotto';
																				|pl = 'Grupa produkcji';
																				|tr = 'Grup imal edilen ürünler'"));
		EndIf;
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.TypeOfExpensesProduction") Then
			ChoiceList.Add("DocumentRef.ProductionOrder2_2", 	NStr("vi = 'Đơn hàng sản xuất';
																		|ru = 'Заказ на производство';
																		|en = 'Production order'; fa = 'سفارش تولید';
																		|it = 'Ordine di produzione';
																		|pl = 'Zlecenie produkcyjne';
																		|tr = 'Üretim emri'"));
		ExpenseItemsLocalization.SupplementListOfTypesWithProductionAnalysts21(ChoiceList);
		
		ChoiceList.Add("DocumentRef.RMOrder",				NStr("vi = 'Lệnh sửa chữa';
																	|ru = 'Заказ на ремонт';
																	|en = 'R&&M order'; fa = 'R&&M order';
																	|it = 'Ordine di manutenzione';
																	|pl = 'Zamówienie naprawy';
																	|tr = 'Onarım siparişi'"));
		ChoiceList.Add("CatalogRef.BusinessStructure", 		NStr("vi = 'Bộ phận';
																	|ru = 'Подразделение';
																	|en = 'Business unit'; fa = 'Business unit';
																	|it = 'Reparto';
																	|pl = 'Dział';
																	|tr = 'Departman'"));
		ChoiceList.Add("CatalogRef.OtherExpenses", 			NStr("vi = 'Chi phí khác';
																	|ru = 'Прочие расходы';
																	|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
																	|it = 'Altre spese';
																	|pl = 'Inne rozchody';
																	|tr = 'Diğer giderler'"));
		ChoiceList.Add("CatalogRef.Assets", 		NStr("vi = 'Tài sản đang vận hành';
														|ru = 'Объекты эксплуатации';
														|en = 'Asset'; fa = 'دارایی';
														|it = 'Oggetti in uso';
														|pl = 'Obiekty eksploatacji';
														|tr = 'Varlıklar'"));
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue") Then
		ChoiceList.Add("CatalogRef.Assets", 		NStr("vi = 'Tài sản cố định';
														|ru = 'Основные средства';
														|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
														|it = 'Capitali fissi';
														|pl = 'Środki trwałe';
														|tr = 'Sabit kıymetler'"));
		If GetFunctionalOption("UseNonCurrentAssets2_4") And Not GetFunctionalOption("UseNonCurrentAssets2_2") Then
			ChoiceList.Add("CatalogRef.ConstructionObjects",	NStr("vi = 'Đối tượng xây dựng cơ bản';
																	|ru = 'Объекты строительства';
																	|en = 'Assets under construction'; fa = 'دارایی‌های در جریان ساخت';
																	|it = 'Oggetti di costruzione';
																	|pl = 'Obiekty budowy';
																	|tr = 'Yapım aşamasındaki varlıklar'"));
		EndIf;
		ExpenseItemsLocalization.CompleteSelectionListFormationOfVNACost(ChoiceList);
		ChoiceList.Add("CatalogRef.IntangibleAssets", 				NStr("vi = 'TSCĐ vô hình / Chi phí nghiên cứu, triển khai';
																			|ru = 'НМА / НИОКР';
																			|en = 'Intangible asset / R&&D'; fa = 'Intangible asset / R&&D';
																			|it = 'Beni immateriali/Ricerca e sviluppo';
																			|pl = 'Aktywa niematerialne / prace naukowo-badawcze i doświadczalno-konstrukcyjne';
																			|tr = 'MOG / Ar-Ge'"));
		ChoiceList.Add("CatalogRef.RDTopicsStages", 	NStr("vi = 'Nghiên cứu và phát triển';
															|ru = 'Исследования и разработки';
															|en = 'Research and development'; fa = 'Research and development';
															|it = 'Ricerche e sviluppi';
															|pl = 'Badania i opracowania';
															|tr = 'Araştırma ve geliştirme'"));
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.OtherExpenses") Then
		ChoiceList.Add("CatalogRef.BusinessStructure", 		NStr("vi = 'Bộ phận';
																	|ru = 'Подразделение';
																	|en = 'Business unit'; fa = 'Business unit';
																	|it = 'Reparto';
																	|pl = 'Dział';
																	|tr = 'Departman'"));
		ChoiceList.Add("CatalogRef.Companies", 				NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
		ChoiceList.Add("EnumRef.ExchangeDifferencesDimension", NStr("vi = 'Dạng chênh lệch tỷ giá';
																	|ru = 'Виды курсовых разниц';
																	|en = 'Exchange difference types'; fa = 'Exchange difference types';
																	|it = 'Tipi delle differenze di cambio';
																	|pl = 'Rodzaje różnic kursowych';
																	|tr = 'Kur farkları türleri'"));
		ChoiceList.Add("CatalogRef.CashAccounts", 					NStr("vi = 'Quỹ tiền mặt';
																			|ru = 'Касса';
																			|en = 'Cash account'; fa = 'صندوق';
																			|it = 'Cassa';
																			|pl = 'Cash account';
																			|tr = 'Kasa hesabı'"));
		ChoiceList.Add("CatalogRef.Persons", 			NStr("vi = 'Cá nhân';
																|ru = 'Физическое лицо';
																|en = 'Person'; fa = 'شخص';
																|it = 'Persona fisica';
																|pl = 'Osoba fizyczna';
																|tr = 'Gerçek kişi'"));
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			ChoiceList.Add("CatalogRef.LinesOfBusiness",	NStr("vi = '(không được sử dụng) Lĩnh vực hoạt động';
																|ru = '(не используется) Направление деятельности';
																|en = '(not used) Line of business'; fa = '(استفاده نمی‌شود) خط کسب‌وکار';
																|it = '(non si utilizza) linea di business';
																|pl = '(nie używane) Rodzaj działalności';
																|tr = '(kullanılmayan) İş kolu'"));
		Else
			ChoiceList.Add("CatalogRef.LinesOfBusiness",	NStr("vi = 'Lĩnh vực hoạt động';
																|ru = 'Направление деятельности';
																|en = 'Line of business'; fa = 'خط کسب‌وکار';
																|it = 'Settore di attività';
																|pl = 'Rodzaj działalności';
																|tr = 'İş kolu'"));
		EndIf;
		ChoiceList.Add("CatalogRef.LoanAndDepositContracts",NStr("vi = 'Hợp đồng tín dụng (tiền gửi)';
																|ru = 'Договор кредита (депозита)';
																|en = 'Loan (deposit) contract'; fa = 'قرارداد وام (سپرده)';
																|it = 'Contratto di credito (deposito)';
																|pl = 'Umowa pożyczki (lokaty)';
																|tr = 'Kredi (mevduat) sözleşmesi'"));
		ChoiceList.Add("CatalogRef.MarketingActivities", 	NStr("vi = 'Hoạt động Marketing';
																	|ru = 'Маркетинговое мероприятие';
																	|en = 'Marketing activity'; fa = 'فعالیت بازاریابی';
																	|it = 'Evento di marketing';
																	|pl = 'Impreza marketingowa';
																	|tr = 'Pazarlama faaliyeti'"));
		ChoiceList.Add("CatalogRef.Complaints", 		        NStr("vi = 'Khiếu nại của khách hàng';
																	|ru = 'Претензия клиента';
																	|en = 'Customer complaint'; fa = 'شکایت مشتری';
																	|it = 'Reclamo del cliente';
																	|pl = 'Reklamacje klienta';
																	|tr = 'Müşteri şikayeti'"));
		ChoiceList.Add("CatalogRef.Projects", 					NStr("vi = 'Dự án';
																		|ru = 'Проект';
																		|en = 'Project'; fa = 'پروژه';
																		|it = 'Progetto';
																		|pl = 'Project';
																		|tr = 'Proje'"));
		ChoiceList.Add("CatalogRef.Assets", 		NStr("vi = 'Tài sản đang vận hành';
														|ru = 'Объекты эксплуатации';
														|en = 'Asset'; fa = 'دارایی';
														|it = 'Oggetti in uso';
														|pl = 'Obiekty eksploatacji';
														|tr = 'Varlıklar'"));
		ChoiceList.Add("CatalogRef.IntangibleAssets", 				NStr("vi = 'TSCĐ vô hình / Chi phí nghiên cứu, triển khai';
																			|ru = 'НМА / НИОКР';
																			|en = 'Intangible asset / R&&D'; fa = 'Intangible asset / R&&D';
																			|it = 'Beni immateriali/Ricerca e sviluppo';
																			|pl = 'Aktywa niematerialne / prace naukowo-badawcze i doświadczalno-konstrukcyjne';
																			|tr = 'MOG / Ar-Ge'"));
		ChoiceList.Add("CatalogRef.RDTopicsStages", 	NStr("vi = 'Nghiên cứu và phát triển';
															|ru = 'Исследования и разработки';
															|en = 'Research and development'; fa = 'Research and development';
															|it = 'Ricerche e sviluppi';
															|pl = 'Badania i opracowania';
															|tr = 'Araştırma ve geliştirme'"));
		ChoiceList.Add("CatalogRef.Warehouses", 					NStr("vi = 'Kho bãi (Vị trí lưu trữ)';
																		|ru = 'Склад (Место хранения)';
																		|en = 'Warehouse (Storage location)'; fa = 'Warehouse (Storage location)';
																		|it = 'Magazzino (luogo di stoccaggio)';
																		|pl = 'Magazyn (Miejsce przechowywania)';
																		|tr = 'Ambar (Depolama yeri)'"));
		ChoiceList.Add("CatalogRef.Products", 				NStr("vi = 'Mặt hàng';
																	|ru = 'Номенклатура';
																	|en = 'Item'; fa = 'قلم';
																	|it = 'Articolo';
																	|pl = 'Item';
																	|tr = 'Öğe'"));
		ChoiceList.Add("CatalogRef.OtherExpenses", 			NStr("vi = 'Chi phí khác';
																	|ru = 'Прочие расходы';
																	|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
																	|it = 'Altre spese';
																	|pl = 'Inne rozchody';
																	|tr = 'Diğer giderler'"));
		ChoiceList.Add("DocumentRef.RMOrder",				NStr("vi = 'Lệnh sửa chữa';
																	|ru = 'Заказ на ремонт';
																	|en = 'R&&M order'; fa = 'R&&M order';
																	|it = 'Ordine di manutenzione';
																	|pl = 'Zamówienie naprawy';
																	|tr = 'Onarım siparişi'"));
		ExpenseItemsLocalization.AddSalaryAccountingAnalystsToListOfTypes(ChoiceList);
	ElsIf Object.ExpensesOccur = PredefinedValue("Enum.ExpenseTypes.ExpenseToCostCenters") Then
		ChoiceList.Add("CatalogRef.CostCenters", 		NStr("vi = 'Đối tượng phát sinh chi phí';
																|ru = 'Объекты возникновения затрат';
																|en = 'Cost centers'; fa = 'مراکز هزینه';
																|it = 'Centri di costo';
																|pl = 'Obiekty tworzenia się rozchodów';
																|tr = 'Maliyet nesneleri'"));
	EndIf;
	
	SetVisibilityOfAnalyticsValueTypes();
	AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics();
		
EndProcedure

&AtServer
Procedure AddElementsDependentOnDistributionOptionsToListOfTypesOfCostAnalytics()
	ListOfTypesToAdd = New ValueList;
	ListOfExcludedTypes = New ValueList;
	If GetFunctionalOption("GenerateFutureExpenseCommitments")
		And (Object.ExpensesOccur = Enums.ExpenseTypes.TypeOfExpensesProduction
			Or Object.ExpensesOccur = Enums.ExpenseTypes.OtherExpenses)
		And (Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness
		Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly
		Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts) Then
			ListOfTypesToAdd.Add("CatalogRef.AccountingObjectsOfFutureExpenseCommitments", NStr("vi = 'Đối tượng kế toán dự phòng';
																								|ru = 'Объекты учета резервов';
																								|en = 'Provision objects'; fa = 'موضوعات ذخیره';
																								|it = 'Oggetti di contabilità delle riserve';
																								|pl = 'Obiekty ewidencji rezerw';
																								|tr = 'Rezerv muhasebesi nesneleri'"));
	Else
			ListOfExcludedTypes.Add("CatalogRef.AccountingObjectsOfFutureExpenseCommitments");
	EndIf;
	Field = Items.ValueType;
	For Each Item In ListOfExcludedTypes Do
		ListItem = Field.ChoiceList.FindByValue(Item.Value);
		If ListItem <> Undefined And ValueType <> Item.Value Then
			Field.ChoiceList.Delete(ListItem);
		EndIf;
	EndDo;
	For Each Item In ListOfTypesToAdd Do
		ListItem = Field.ChoiceList.FindByValue(Item.Value);
		If ListItem = Undefined Then
			Field.ChoiceList.Add(Item.Value, Item.Presentation);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillInVATValueType()
	
	// The filling condition must match the condition in the manager module.
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost Then
		Object.VATAssetTaxClass = Enums.AssetKinds.Goods;
	ElsIf Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
		If ValueType = "CatalogRef.Assets" Then
			Object.VATAssetTaxClass = Enums.AssetKinds.FA;
		ElsIf ValueType = "CatalogRef.ConstructionObjects"
			Or ValueType = "CatalogRef.ConstructionObjects22" Then
			Object.VATAssetTaxClass = Enums.AssetKinds.ConstructionInProgressObjects;
		ElsIf ValueType = "CatalogRef.IntangibleAssets" 
			Or ValueType = "CatalogRef.RDTopicsStages" Then
			Object.VATAssetTaxClass = Enums.AssetKinds.IA;
		EndIf;
	Else
		Object.VATAssetTaxClass = Enums.AssetKinds.OtherWorksAndServices;
	EndIf;
	
EndProcedure

&AtServer
Function ThereIsInputOfRemnantsOfOldSample()
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT TOP 1
	|	EnteringProductBalances.Ref
	|FROM
	|	Document.OBEntry.Goods AS EnteringProductBalances
	|WHERE
	|	EnteringProductBalances.Ref.Posted");
	Result = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	
	Return Result.Next();
	
EndFunction

#EndRegion

#EndRegion
