#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	FillingRuleAddress = PutToTempStorage(
		CurrentObject.FillingRule.Unload(),
		UUID);
	
	OnReadCreateAtServer();
	
	If ValueIsFilled(CurrentObject.Ref) Then
		ObjectSettingsStructure = CurrentObject.SettingsStructure.Get();
	EndIf;
	
	If TypeOf(ObjectSettingsStructure) = Type("Structure") Then
		FillPropertyValues(SettingsStructure, ObjectSettingsStructure);
	EndIf; 
	
	If TypeOf(ObjectSettingsStructure) = Type("Structure") And ObjectSettingsStructure.Property("UserSettings") Then
		CustomSettingsAddress = PutToTempStorage(ObjectSettingsStructure.UserSettings, UUID);
	Else
		CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
	EndIf;
	
	If TypeOf(ObjectSettingsStructure) = Type("Structure")
		And ObjectSettingsStructure.Property("SelectionOfProductsSettings")
		And ValueIsFilled(String(ObjectSettingsStructure.SelectionOfProductsSettings.Filter)) Then
		FilterOfProductItem.LoadSettings(ObjectSettingsStructure.SelectionOfProductsSettings);
	EndIf;
	CreatePresentationOfProductSelection();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateItemAvailability();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	If Not CurrentObject.FillInByServiceData Then
		CurrentObject.FillInPartner = FillInPartner And (CurrentObject.FillInUsingFormula Or Not CurrentObject.FillInPartnerInTabularForm);
		CurrentObject.FillInPartnerInTabularForm = FillInPartner And CurrentObject.FillInPartnerInTabularForm And Not CurrentObject.FillInUsingFormula;
		CurrentObject.FillInTermsOfSales = FillInPartner And FillInTermsOfSales 
			And (CurrentObject.FillInUsingFormula Or Not CurrentObject.FillInAgreementInTabularForm);
		CurrentObject.FillInAgreementInTabularForm = FillInPartner And FillInTermsOfSales 
			And (CurrentObject.FillInAgreementInTabularForm Or CurrentObject.FillInPartnerInTabularForm) And Not CurrentObject.FillInUsingFormula;
	EndIf;
	CurrentObject.FillInBOMByPeriods = FillInBOMByPeriods = "ByPeriods";
	CurrentObject.TransferDemandOfBusinesUnitsThroughTransfers = Not StopCalculationOfNeedsOnMovements;
	If IsTempStorageURL(FillingRuleAddress) Then
		CurrentObject.FillingRule.Load(GetFromTempStorage(FillingRuleAddress));
	EndIf;
	
	If Object.FillInByShortage
		Or Object.FillInByServiceData Then
		SettingsStructure.SelectionOfProductsSettings = FilterOfProductItem.GetSettings();
	EndIf;
	
	If IsTempStorageURL(CustomSettingsAddress) Then
		SettingsStructure.Insert("UserSettings",GetFromTempStorage(CustomSettingsAddress));
		CurrentObject.SettingsStructure = New ValueStorage(SettingsStructure);
		SettingsStructure.Insert("UserSettings",Undefined);
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInPartner 	= Object.FillInPartner Or Object.FillInPartnerInTabularForm;
	FillInTermsOfSales = Object.FillInTermsOfSales Or Object.FillInAgreementInTabularForm;
	FillInWarehouse 		= Object.FillInWarehouse Or Object.FillInWarehouseInTabularForm;
	
	If RecalculateShortages Then
		Planning.StartingBackgroundRecalculationOfDeficitInStages(Object.Owner);
	EndIf;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	UpdateItemAvailability();
	
	Notify("Catalog.PlanProfiles.Update", Object.Owner, ThisObject);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	Attributes = GetServerOwnerDetails(Object.Owner);
	FillPropertyValues(ThisForm, Attributes);
	Items.ProductionProcessType.ChoiceList.Clear();
	Items.ProductionProcessType.ChoiceList.Add(PredefinedValue("Enum.ProductionProcessTypes.Assembly"));
	Items.ProductionProcessType.ChoiceList.Add(PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	If DynamicStructureOfProductionOrders And Not PlanningProcessManagement Then
		Items.ProductionProcessType.ChoiceList.Add(PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
	Else
		Items.ProductionProcessType.ChoiceList.Add(PredefinedValue("Enum.ProductionProcessTypes.Repair"));
	EndIf;
	SetVisibility1(ThisForm);
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure PlanTypeOnChange(Item)
	
	If Not ValueIsFilled(Object.PlanType) Then
		Items.FillingRule.Enabled = False;
	EndIf;
		
	If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan") Then
		If Not ToUseTermsOfSales Then
			
			FillInTermsOfSales = False;
			Object.FillInTermsOfSales = False;
			Object.FillInAgreementInTabularForm = False;
			
		EndIf;
		If Not CreateSalesPlanByAmount Then
			Object.FillInPaymentPlan = False;
		EndIf;
		
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan") Then
		
		FillInPartner = False;
		FillInTermsOfSales = False;
		Object.FillInCompany = False;
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
		Object.FillInPaymentPlan = False;
		Object.FillInManager = False;
		Object.FillInStoreFormat = False;
		
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan") Then
		
		If Not CreatePurchasePlanByAmount Then
			Object.FillInPaymentPlan = False;
		EndIf;
		Object.FillInManager = False;
		Object.FillInStoreFormat = False;
		
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.PlanOfGoodsStock") Then
		
		FillInPartner = False;
		FillInTermsOfSales = False;
		Object.FillInCompany = False;
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
		Object.FillInWarehouseInTabularForm = False;
		Object.FillInPaymentPlan = False;
		Object.FillInManager = False;
		
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan") Then
		
		FillInPartner = False;
		FillInTermsOfSales = False;
		Object.FillInCompany = False;
		Object.FillInBusinessUnit = False;
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
		Object.FillInPaymentPlan = False;
		Object.FillInManager = False;
		Object.FillInStoreFormat = False;
		
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories") Then
		
		FillInPartner = False;
		FillInTermsOfSales = False;
		Object.FillInCompany = False;
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
		Object.FillInWarehouseInTabularForm = False;
		Object.FillInPaymentPlan = False;
		Object.FillInManager = False;
		
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan") Then
		
		If ComplexAutomation Then
			Object.FillInBusinessUnit = False;
		EndIf;
		
		FillInPartner = False;
		FillInTermsOfSales = False;
		FillInWarehouse = False;
		Object.FillInCompany = False;
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
		Object.FillInWarehouse = False;
		Object.FillInWarehouseInTabularForm = False;
		Object.FillInPaymentPlan = False;
		Object.FillInManager = False;
		Object.FillInStoreFormat = False;
	EndIf;
	
	If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan") Then
		If Object.BusinessOperation.IsEmpty() Then
			Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
		EndIf;
	ElsIf Not Object.BusinessOperation.IsEmpty() Then
		Object.BusinessOperation = Undefined;
	EndIf;
	If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan") Then
		If Object.ProductionProcessType.IsEmpty() Then
			Object.ProductionProcessType = Items.ProductionProcessType.ChoiceList[0].Value;
		EndIf;
	ElsIf Not Object.ProductionProcessType.IsEmpty() Then
		Object.ProductionProcessType = Undefined;
	EndIf;
	SetVisibility1(ThisForm);
	
	UpdateItemAvailability();
	
	InitializeFormulaFillingSettings();
	InitializeFillingModeSettingsForDeficits();
	InitializeSettingsStructure();

	Object.ContentFillingVariant = Items.ContentFillingVariant.ChoiceList[0].Value;
	
	TMCommonUseClient.AllowObjectAttributeEditCompletion(True, New Structure("Form", ThisForm));
	
EndProcedure

&AtClient
Procedure FillInPartnerOnChange(Item)
	
	If FillInPartner And Object.FillInPartnerInTabularForm Then
		Object.FillInPartner = False;
		If FillInTermsOfSales Then
			Object.FillInTermsOfSales = False;
			Object.FillInAgreementInTabularForm = True;
		EndIf; 
	ElsIf FillInPartner And Not Object.FillInPartnerInTabularForm Then
		Object.FillInPartner = True;
	Else
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		
		FillInTermsOfSales = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
	EndIf; 
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillInTheWchpPartnerWhenChanging(Item)
	
	If FillInPartner And Object.FillInPartnerInTabularForm Then
		Object.FillInPartner = False;
		If FillInTermsOfSales Then
			Object.FillInAgreementInTabularForm = True;
		EndIf; 
		Object.FillInTermsOfSales = False; 
		Object.FillInPaymentPlan = False;
	ElsIf FillInPartner And Not Object.FillInPartnerInTabularForm Then
		Object.FillInPartner = True;
	Else
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
	EndIf;
	
	If Object.FillInByServiceData Then
		Object.FillInPartner = Not Object.FillInPartnerInTabularForm;
	EndIf;
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillInTermsOfSalesOnChange(Item)
	
	If FillInTermsOfSales And (Object.FillInPartnerInTabularForm Or Object.FillInAgreementInTabularForm) Then
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = True;
	ElsIf FillInTermsOfSales And Not Object.FillInAgreementInTabularForm Then
		Object.FillInTermsOfSales = True;
	Else
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
	EndIf;
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillOutTheHhtaAgreementWhenChanging(Item)
	
	If Object.FillInAgreementInTabularForm Then
		Object.FillInTermsOfSales = False;
		If Not Object.FillInPartner Then
			Object.FillInPartnerInTabularForm = True;
		EndIf;
		Object.FillInPaymentPlan = False;
	EndIf;
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillInWarehouseOnChange(Item)
	
	If FillInWarehouse Then
		Object.FillInWarehouse = True;
		Object.FillInWarehouseInTabularForm = False;
		Object.FillInStoreFormat = False;
		FillOptionWarehouseStoreFormat = 1;
	Else
		Object.FillInWarehouse = False;
		Object.FillInWarehouseInTabularForm = False;
		FillOptionWarehouseStoreFormat = 0;
	EndIf;
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillInWarehouseInTabularFormOnChange(Item)
	
	If Object.FillInWarehouseInTabularForm Then
		Object.FillInWarehouse = False;
		FillOptionWarehouseStoreFormat = 1;
	ElsIf FillInWarehouse Then
		Object.FillInWarehouse = True;
		FillOptionWarehouseStoreFormat = 1;
	EndIf;
	
	If Object.FillInByServiceData Then
		Object.FillInWarehouse = Not Object.FillInWarehouseInTabularForm;
	EndIf;
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillInUsingFormulaOnChange(Item)
	
	FillInAccordingToFormulaWhenChangingFragment();
	
EndProcedure

&AtClient
Procedure FillInAccordingToForecastFormulaOnChange(Item)
	
	FillInAccordingToFormulaWhenChangingFragment();
	
EndProcedure

&AtClient
Procedure FillInByShortageOnChange(Item)
	
	Object.FillInByShortage = FillInByShortage;
	RecalculateShortages = True;
	
	Object.Substitutional = False;
	Substitutional = 0;
	
	FillInDetailsUsingFormula(ThisForm);
	Object.FillInUsingFormula = Not FillInByShortage And Not Object.FillInByServiceData;
	
	If FillInByShortage Then
		Object.FillInBusinessUnit = False;
		Object.FillInCompany = False;
		Object.FillInPartner = False;
		Object.FillInPartnerInTabularForm = False;
		FillInPartner = False;
		Object.FillInTermsOfSales = False;
		Object.FillInAgreementInTabularForm = False;
		FillInTermsOfSales = False;
		Object.FillInManager = False;
		Object.FillInStoreFormat = False;
		Object.FillInWarehouse = False;
		Object.FillInWarehouseInTabularForm = False;
		FillInWarehouse = False;
		FillOptionWarehouseStoreFormat = 0;
		Object.FillInAssignmentInTabularForm = PlanningByAssignments;
		Object.PlanSemiFinishedProductsAutomatically = Not FillInByShortage;
	EndIf;
	
	SetVisibility1(ThisObject);
	
	UpdateItemAvailability();
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SubstitutionalOnChange(Item)
	
	Object.Substitutional = Substitutional;
	
	Modified = True;
	
	ChangeBlankMark(ThisForm, Object.NumberOfPeriods, Object.Substitutional);
	
EndProcedure

&AtClient
Procedure NumberOfPeriodsOnChange(Item)
	ChangeBlankMark(ThisForm, Object.NumberOfPeriods, Object.Substitutional);
EndProcedure

&AtClient
Procedure FillInThePaymentPlanWhenChanging(Item)
	UpdateItemAvailability();
	Return; // In UT 11.1, the code of this handler is empty
	
EndProcedure

&AtClient
Procedure FillOptionWarehouseStoreFormatOnChange(Item)
	
	If FillOptionWarehouseStoreFormat = 1 Then
		Object.FillInStoreFormat = False;
		FillInWarehouse = True;
		Object.FillInWarehouse = True;
		Object.FillInWarehouseInTabularForm = False;
	ElsIf FillOptionWarehouseStoreFormat = 2 Then
		Object.FillInStoreFormat = True;
		FillInWarehouse = False;
		Object.FillInWarehouse = False;
		Object.FillInWarehouseInTabularForm = False;
	Else
		Object.FillInStoreFormat = False;
		FillInWarehouse = False;
		Object.FillInWarehouse = False;
		Object.FillInWarehouseInTabularForm = False;
	EndIf;
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure FillInStoreFormatOnChange(Item)
	
	If Object.FillInStoreFormat Then
		FillInWarehouse = False;
		Object.FillInWarehouse = False;
		Object.FillInWarehouseInTabularForm = False;
		FillOptionWarehouseStoreFormat = 2;
	EndIf; 
	
	UpdateItemAvailability();
	
EndProcedure

&AtClient
Procedure ProductionProcessTypeOnChange(Item)
	
	RecalculateShortages = True;
	Object.PlanSemiFinishedProductsAutomatically = False;
	
	SetVisibility1(ThisObject);
	InitializeFillingModeSettingsForDeficits();
	
EndProcedure

&AtClient
Procedure ContentFillingVariantOnChange(Item)
	RecalculateShortages = True;
EndProcedure

&AtClient
Procedure ParentOnChange(Item)
	
	GenerateListOfPlanTypesByPlanningStage();
	InitializeFillingModeSettingsForDeficits();
	Object.ContentFillingVariant = Items.ContentFillingVariant.ChoiceList[0].Value;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	InitializeFillingModeSettingsForDeficits();
EndProcedure

&AtClient
Procedure UsePriceTypeOnChange(Item)
	If UsePriceType Then
		Items.PriceKind.Enabled = True;
	Else
		Items.PriceKind.Enabled = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure FillingRule(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf; 
	
	If Modified Or Not ValueIsFilled(Object.Ref) Then
	
		Notification = New CallbackDescription("RuleForFillingOutQuestionRecordCompletion", ThisObject);
		
		QueryText = NStr("vi = 'Đã thay đổi tùy chỉnh dạng kế hoạch. Ghi lại?';
						|ru = 'Настройки вида плана были изменены. Записать?';
						|en = 'Settings of the plan profile were changed. Do you want to save them?'; fa = 'Settings of the plan profile were changed. Do you want to save them?';
						|it = 'Le impostazioni del tipo di piano sono state modificate. Registrare?';
						|pl = 'Ustawienia rodzaju planu zostaną zmienione. Zapisać?';
						|tr = 'Plan profili ayarları değiştirildi. Kaydedilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại';
												|ru = 'Записать';
												|en = 'Save'; fa = 'ذخیره';
												|it = 'Salvare';
												|pl = 'Save';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		ShowQueryBox(Notification, QueryText, Buttons);
		Return;
		
	EndIf; 
	
	FormParameters = New Structure;
	
	FormParameters.Insert("EditMode");
	FormParameters.Insert("UpdateAdd",      			SettingsStructure.UpdateAdd);
	FormParameters.Insert("FillingRuleAddress", 			FillingRuleAddress);
	FormParameters.Insert("ChangeResultTo",    			SettingsStructure.ChangeResultTo);
	FormParameters.Insert("RoundingPrecision",     			SettingsStructure.RoundingPrecision);
	FormParameters.Insert("Periodicity",            		Periodicity);
	If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan") Then
		FormParameters.Insert("PlanByAmount", 			CreatePurchasePlanByAmount);
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan") Then
		FormParameters.Insert("PlanByAmount",			CreateSalesPlanByAmount);
	Else
		FormParameters.Insert("PlanByAmount",          	False);
	EndIf;
	FormParameters.Insert("PlanProfile",                         Object.Ref);
	FormParameters.Insert("CustomSettingsAddress",    CustomSettingsAddress);
	FormParameters.Insert("ReadOnly",                   ThisForm.ReadOnly);
	FormParameters.Insert("NumberOfPeriods",               Object.NumberOfPeriods);

	Notification = New CallbackDescription("FillingRuleCompletion", ThisObject);
	
	OpenForm("Catalog.PlanningDataSources.Form.FormFilling", 
		FormParameters, 
		ThisForm, 
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// Forecasting service.
&AtClient
Procedure PredictionFilters(Command)
	
	StandardProcessing = False;
	
		
EndProcedure

&AtClient
Procedure PredictionSettings(Command)
	
	StandardProcessing = False;
	
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	If Items.PlanType.ChoiceList.Count() = 0 Then
		If GetFunctionalOption("UsePurchasePlanning") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.PurchasePlan,NStr("vi = 'Kế hoạch mua hàng';
																				|ru = 'Плана закупок';
																				|en = 'Purchase plan'; fa = 'برنامه خرید';
																				|it = 'Del piano di acquisti';
																				|pl = 'Planu zakupów';
																				|tr = 'Satın alma planı'"));
		EndIf;
		If GetFunctionalOption("UsePlanningOfGoodsStock") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.PlanOfGoodsStock, NStr("vi = 'Kế hoạch số dư';
																					|ru = 'Плана остатков';
																					|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
																					|it = 'Del piano di giacenze';
																					|pl = 'Planu ostatków';
																					|tr = 'Mal stok planı'"));
		EndIf;
		If GetFunctionalOption("UseSalesPlansByCategories") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.SalesPlanByCategories, 
				NStr("vi = 'Kế hoạch bán hàng theo thể loại';
					|ru = 'Плана продаж по категориям';
					|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
					|it = 'Del piano delle vendite per categorie';
					|pl = 'Planu sprzedaży wg kategorii';
					|tr = 'Kategorilere göre satış tahmini'"));
		EndIf;
		If GetFunctionalOption("UseSalesPlans") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.SalesPlan, NStr("vi = 'Kế hoạch bán hàng';
																			|ru = 'Плана продаж';
																			|en = 'Sales forecast'; fa = 'پیش‌بینی فروش';
																			|it = 'Del piano delle vendite';
																			|pl = 'Planu sprzedaży';
																			|tr = 'Satış tahmini'"));
		EndIf;
		If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.AssemblyDisassemblyPlan, 
				NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
					|ru = 'Плана сборки (разборки)';
					|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
					|it = 'Del piano di assemblaggio (disassemblaggio)';
					|pl = 'Planu montażu (demontażu)';
					|tr = 'Montaj planı (demontaj)'"));
		EndIf; 
		If GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.InventoryConsumptionPlan, 
				NStr("vi = 'Kế hoạch nhu cầu nội bộ';
					|ru = 'Плана внутренних потреблений';
					|en = 'Inventory consumption plan'; fa = 'برنامه مصرف موجودی';
					|it = 'Del piano di consumi interni';
					|pl = 'Planu konsumpcji wewnętrznych';
					|tr = 'İç tüketim planı'"));
		EndIf;
		If GetFunctionalOption("UseProductionPlanning") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.ProductionPlan, 
				NStr("vi = 'Kế hoạch sản xuất';
					|ru = 'Плана производства';
					|en = 'Production plan'; fa = 'برنامه تولید';
					|it = 'Del piano di produzione';
					|pl = 'Planu produkcji';
					|tr = 'Üretim planı'"));
		EndIf;
	EndIf;
	
	ComplexAutomation = GetFunctionalOption("ComplexAutomation");
	DynamicStructureOfProductionOrders = GetFunctionalOption("DynamicStructureOfProductionOrders");
	If ValueIsFilled(Object.PlanType) And ValueIsFilled(Object.Ref) Then
		Items.PlanType.ReadOnly = True;
	EndIf;
	
	UseStoreFormats = GetFunctionalOption("UseStoreFormats");
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	
	ToUseTermsOfSales    = GetFunctionalOption("ToUseTermsOfSales");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	TradeManagement = GetFunctionalOption("TradeManagement");
	DescriptionOfManufacturingProcessTypeIsAvailable = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	If DescriptionOfManufacturingProcessTypeIsAvailable Then
		TypesToExclude = New Array;
		TypesToExclude.Add(Enums.ProductionProcessTypes.WithoutBillsOfMaterials);
		If PlanningProcessManagement Then
			TypesToExclude.Add(Enums.ProductionProcessTypes.PerformRM);
		EndIf;
		ProductionServer.FillInListOfProductionProcessTypes(Items.ProductionProcessType, TypesToExclude);
	EndIf;
	Attributes = GetServerOwnerDetails(Object.Owner);
	FillPropertyValues(ThisForm, Attributes);
	
	InitializeSettingsStructure();
	
	If Not ValueIsFilled(Object.Ref) Then
		If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan")
			And Object.ProductionProcessType.IsEmpty() Then
			Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly");
		EndIf;
		StopCalculationOfNeedsOnMovements = Not DynamicStructureOfProductionOrders;
	EndIf;
	If Not IsTempStorageURL(FillingRuleAddress) Then		
		// By copying
		If ValueIsFilled(Parameters.CopyingValue) Then
			FillingRuleAddress = PutToTempStorage(
				Parameters.CopyingValue.FillingRule.Unload(),
				UUID);
		Else
			ScenarioObject = FormAttributeToValue("Object");
			
			FillingRuleAddress = PutToTempStorage(
				ScenarioObject.FillingRule.Unload(),
				UUID);
		EndIf;
	EndIf;
	
	If Not IsTempStorageURL(CustomSettingsAddress) Then
		// By copying
		If ValueIsFilled(Parameters.CopyingValue) Then
			
			StructureOfCopySettings = Parameters.CopyingValue.SettingsStructure.Get();
			If TypeOf(StructureOfCopySettings) = Type("Structure") Then
				FillPropertyValues(SettingsStructure, StructureOfCopySettings);
			EndIf;
			If TypeOf(StructureOfCopySettings) = Type("Structure") And StructureOfCopySettings.Property("UserSettings") Then
				CustomSettingsAddress = PutToTempStorage(StructureOfCopySettings.UserSettings, UUID);
			Else
				CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
			EndIf; 
		Else
			CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
		EndIf;
	EndIf;
	
	FillInPartner   = Object.FillInPartner Or Object.FillInPartnerInTabularForm;
	FillInTermsOfSales = Object.FillInTermsOfSales Or Object.FillInAgreementInTabularForm;
	FillInWarehouse      = Object.FillInWarehouse Or Object.FillInWarehouseInTabularForm;
	Substitutional          = Object.Substitutional;
	FillInByShortage = Object.FillInByShortage;
	
	If Object.FillInByServiceData Then
		FillInUsingFormula = 2;
	Else
		FillInUsingFormula = ?(Object.FillInUsingFormula, 1, 0);
	EndIf;
	If Object.FillInBOMByPeriods Then
		FillInBOMByPeriods = "ByPeriods";
	Else
		FillInBOMByPeriods = "BeginOfPeriod";
	EndIf;
	
	StopCalculationOfNeedsOnMovements = Not Object.TransferDemandOfBusinesUnitsThroughTransfers;
	If FillInWarehouse Then
		FillOptionWarehouseStoreFormat = 1;
	ElsIf Object.FillInStoreFormat Then
		FillOptionWarehouseStoreFormat = 2;
	Else
		FillOptionWarehouseStoreFormat = 0;
	EndIf; 
	
	ChangeBlankMark(ThisForm, Object.NumberOfPeriods, Object.Substitutional);
	
	GenerateListOfPlanTypesByPlanningStage();
	
	SetVisibility1(ThisForm);
	
	InitializeFillingModeSettingsForDeficits();
	
	If Not ValueIsFilled(Object.ContentFillingVariant) Then
		Object.ContentFillingVariant = Items.ContentFillingVariant.ChoiceList[0].Value;
	EndIf;
	
	UsePriceType = ValueIsFilled(Object.PriceKind);
	
	DefineDataLayoutScheme();
	
EndProcedure 

&AtServer
Procedure InitializeSettingsStructure()
	
	SettingsStructure = New Structure();
	
	SettingsStructure.Insert("UpdateAdd", 0);
	SettingsStructure.Insert("ChangeResultTo", 0);
	SettingsStructure.Insert("RoundingPrecision", 0);
	
	SettingsStructure.Insert("ContentFillingVariant", "Filter");
	
	If Object.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock Then
		SettingsStructure.Insert("OffsetOption", "CustomValue");
		SettingsStructure.Insert("PeriodOffset", 0);
	Else
		SettingsStructure.Insert("OffsetOption", "PreviousPeriod_");
		SettingsStructure.Insert("PeriodOffset", -1);
	EndIf;
	
	If Object.PlanType = Enums.TypesOfPlans.PurchasePlan
		Or Object.PlanType = Enums.TypesOfPlans.SalesPlan Then 
		SettingsStructure.Insert("PricePopulationOption", "ItemsPrices");
		SettingsStructure.Insert("PriceKind",);
		SettingsStructure.Insert("UsePriceType", False);
	EndIf;
	
	If Object.PlanType = Enums.TypesOfPlans.PurchasePlan Then
		SettingsStructure.Insert("Formula","[PurchasePlans] * (1.5)");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch mua hàng của kỳ trước lên 15%';
															|ru = 'Увеличение планов закупок прошлых периодов на 15%';
															|en = 'Increase purchase plans of previous periods by 15%'; fa = 'Increase purchase plans of previous periods by 15%';
															|it = 'Aumento del 15% dei piani di acquisti nei periodi precedenti';
															|pl = '15% wzrost zakupu okresów poprzednich';
															|tr = 'Önceki dönemlerin satın alma planlarının yüzde 15 artırılması'"));
	ElsIf Object.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock Then
		SettingsStructure.Insert("Formula","[PlannedStartBalance]");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Số dư đầu kế hoạch';
															|ru = 'Планируемый начальный остаток';
															|en = 'Planned opening balance'; fa = 'مانده افتتاحیه برنامه‌ریزی‌شده';
															|it = 'Rimanenze pianificate iniziali';
															|pl = 'Planowane początkowe resztę pozostałości';
															|tr = 'Planlanan başlangıç bakiyesi'"));
	ElsIf Object.PlanType = Enums.TypesOfPlans.SalesPlan Then
		SettingsStructure.Insert("Formula","[SalesPlans] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch bán hàng của kỳ trước lên 15%';
															|ru = 'Увеличение планов продаж прошлых периодов на 15%';
															|en = 'Increase of sales forecasts of previous periods by 15%'; fa = 'Increase of sales forecasts of previous periods by 15%';
															|it = 'Aumento del 15% dei piani vendita nei periodi precedenti';
															|pl = 'Zwiększenie planów sprzedaży z poprzednich okresów o 15%';
															|tr = 'Önceki dönemlerin satış planlarının yüzde 15 artırılması'"));
	ElsIf Object.PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
		SettingsStructure.Insert("Formula","[SalesPlansByCategories] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch bán hàng của kỳ trước lên 15%';
															|ru = 'Увеличение планов продаж прошлых периодов на 15%';
															|en = 'Increase of sales forecasts of previous periods by 15%'; fa = 'Increase of sales forecasts of previous periods by 15%';
															|it = 'Aumento del 15% dei piani vendita nei periodi precedenti';
															|pl = 'Zwiększenie planów sprzedaży z poprzednich okresów o 15%';
															|tr = 'Önceki dönemlerin satış planlarının yüzde 15 artırılması'"));
	ElsIf Object.PlanType = Enums.TypesOfPlans.ProductionPlan Then
		SettingsStructure.Insert("Formula","[ProductionPlans] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch sản xuất của kỳ trước lên 15%';
															|ru = 'Увеличение планов производства прошлых периодов на 15%';
															|en = 'Increase the production plans of the previous periods by 15%'; fa = 'Increase the production plans of the previous periods by 15%';
															|it = 'Aumento del 15% dei piani di produzione dei periodi precedenti';
															|pl = '15% wzrost w poprzednich planach produkcyjnych';
															|tr = 'Önceki dönemlerin üretim planlarının yüzde 15 artırılması'"));
	ElsIf Object.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		SettingsStructure.Insert("Formula","[AssemblyPlansKits] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",NStr("vi = 'Tăng kế hoạch đóng bộ của kỳ trước lên 15%';
															|ru = 'Увеличение планов сборки прошлых периодов на 15%';
															|en = 'Previous period kitting plan increase by 15%'; fa = 'Previous period kitting plan increase by 15%';
															|it = 'Aumento del 15% dei piani di assemblaggio nei periodi precedenti';
															|pl = 'Zwiększenie wcześniejszych planów montażu o 15%';
															|tr = 'Önceki dönemlerin montaj planlarının yüzde 15 artırılması'"));
	ElsIf Object.PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan Then
		SettingsStructure.Insert("Formula","[InventoryConsumptionPlans] * 1.15");
		SettingsStructure.Insert("FormulaPresentation",
			NStr("vi = 'Tăng 15% trong kế hoạch tiêu thụ trong quá khứ';
				|ru = 'Увеличение планов внутренних потреблений прошлых периодов на 15%';
				|en = 'Previous period inventory consumption plans increase by 15%'; fa = 'Previous period inventory consumption plans increase by 15%';
				|it = 'Aumento del 15% dei piani di consumi interni per i periodi scorsi';
				|pl = 'Zwiększenie planów konsumpcji wewnętrznych wcześniejszych okresów o 15%';
				|tr = 'Önceki dönemlerin stok tüketim planlarının yüzde 15 artırılması'"));
	EndIf;
	
	SettingsStructure.Insert("SelectionOfProductsSettings", New DataCompositionSettings);
	SettingsStructure.Insert("FilterEmptyLines", False);
	SettingsStructure.Insert("FilterByAvailabilityOfBOM", False);
	
EndProcedure

&AtClient
Procedure UpdateItemAvailability()
	
	Items.FillInUsingFormula.Enabled = Not Object.FillInByShortage;
	Items.FillInAccordingToForecastFormula.Enabled = Not Object.FillInByShortage;
	Items.ReplacementSummingGroup.Enabled = Not Object.FillInByShortage;
	
	Items.FillInBusinessUnit.Enabled = Not Object.FillInByShortage;
	Items.FillInTheProductionDivision.Enabled = Not  Object.FillInByShortage;
	Items.FillInCompany.Enabled = Not Object.FillInByShortage;
	Items.FillInTheSalesPartner.Enabled = Not  Object.FillInByShortage;
	Items.FillInThePurchasePartner.Enabled = Not  Object.FillInByShortage;
	Items.FillInPartner.Enabled = Not  Object.FillInByShortage;
	Items.FillInTermsOfSales.Enabled = FillInPartner And Not Object.FillInByShortage;
	Items.FillInWarehouse.Enabled = Not  Object.FillInByShortage;
	
	Items.FillPartnerStopredeye.Enabled = FillInPartner And Not FillInUsingFormula;
	Items.FillOutTheWCHPurchasePartner.Enabled = FillInPartner And Not FillInUsingFormula;
	Items.FillOutTheVTSalesAgreement.Enabled = FillInPartner And FillInTermsOfSales And Not FillInUsingFormula;
	Items.FillOutTheWCHPurchaseAgreement.Enabled = FillInPartner And FillInTermsOfSales And Not FillInUsingFormula;
	Items.FillInWarehouseInTabularForm.Enabled = FillInWarehouse And Not FillInUsingFormula;
	Items.FillInAssignmentInTabularForm.Enabled = PlanningByAssignments And Not Object.FillInByShortage;
	
	Items.FillOutASalesPaymentPlan.Enabled = CreateSalesPlanByAmount And Not Object.FillInPartnerInTabularForm;
	Items.FillOutThePurchasePaymentPlan.Enabled = CreatePurchasePlanByAmount And Not Object.FillInPartnerInTabularForm;
	Items.PlanSemiFinishedProductsAutomatically.Enabled = Not Object.FillInByShortage;
	If UsePriceType Then
		Items.PriceKind.Enabled = True;
	Else
		Items.PriceKind.Enabled = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetServerOwnerDetails(Val Scenario)
	
	Attributes = "Periodicity, CreatePurchasePlanByAmount, CreateSalesPlanByAmount, PlanningByAssignments, PlanningProcessManagement";
	Attributes = Attributes + ", UseForMaterialsPlanning, DemandForMaterials, Calendar";
	AttributesValues = Common.ObjectAttributesValues(Scenario, Attributes);
	
	Return AttributesValues;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetVisibility1(Form)
	
	PlanType = Form.Object.PlanType;
	ThisIsProcurementPlan = PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan");
	ThisIsTheRemainderPlan = PlanType = PredefinedValue("Enum.TypesOfPlans.PlanOfGoodsStock");
	ThisIsASalesPlan = PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan");
	ThisIsASalesPlanByCategory = PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories");
	ThisIsTheProductionPlan = False;
	ThisIsTheProductionPlan = PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan");
	ThisIsAnAssemblyDisassemblyPlan = PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan");
	ThisIsADomesticConsumptionPlan = PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan");
	
	SelectWarehouse = Form.UseSeveralWarehouses And Not Form.UseStoreFormats;
	FormatSelection = Form.UseStoreFormats And Not Form.UseSeveralWarehouses;
	ChoosingByWarehouseOrFormats = Form.UseSeveralWarehouses And Form.UseStoreFormats;
	
	Form.Items.FillInBusinessUnit.Visible = ThisIsProcurementPlan 
		Or ThisIsASalesPlan Or ThisIsASalesPlanByCategory Or ThisIsADomesticConsumptionPlan;
	Form.Items.FillInTheProductionDivision.Visible = ThisIsTheProductionPlan And Not Form.ComplexAutomation;
	Form.Items.FillInCompany.Visible = ThisIsProcurementPlan Or ThisIsASalesPlan;
	Form.Items.UseMaterialPlansGroup.Visible = ThisIsTheProductionPlan And Form.UseForMaterialsPlanning;
	
	Form.Items.PlanSemiFinishedProductsAutomatically.Visible = False;
	Form.Items.ProductionProcessType.Visible = False;
	Form.Items.StopCalculationOfNeedsOnMovements.Visible = False;
	Form.Items.PlanSemiFinishedProductsAutomatically.Visible = 
		ThisIsTheProductionPlan
		And Form.UseForMaterialsPlanning
		And (Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
			Or Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair"));
	Form.Items.ProductionProcessType.Visible = ThisIsTheProductionPlan
		And Form.DescriptionOfManufacturingProcessTypeIsAvailable;
	Form.Items.StopCalculationOfNeedsOnMovements.Visible = ThisIsTheProductionPlan
		And Form.UseForMaterialsPlanning;
	Form.Items.BusinessOperation.Visible = ThisIsAnAssemblyDisassemblyPlan;
	Form.Items.FillInTheSalesPartner.Visible = ThisIsASalesPlan;
	Form.Items.FillInThePurchasePartner.Visible = ThisIsProcurementPlan;
	Form.Items.GroupFillInTheWHPartner.Visible = (ThisIsProcurementPlan Or ThisIsASalesPlan);
	Form.Items.FillPartnerStopredeye.Visible = ThisIsASalesPlan;
	Form.Items.GroupTooltipTSClient.Visible = (Form.FillInUsingFormula Or Form.FillInByShortage) And ThisIsASalesPlan;
	Form.Items.FillOutTheWCHPurchasePartner.Visible = ThisIsProcurementPlan;
	Form.Items.GroupTooltipTSSupplier.Visible = (Form.FillInUsingFormula Or Form.FillInByShortage) And ThisIsProcurementPlan;
	Form.Items.FillInTermsOfSales.Visible = ThisIsProcurementPlan And Form.UseTermsOfPurchases Or ThisIsASalesPlan And Form.ToUseTermsOfSales;
	Form.Items.GroupFillOutTheWHAgreement.Visible = (ThisIsProcurementPlan And Form.UseTermsOfPurchases Or ThisIsASalesPlan And Form.ToUseTermsOfSales);
	Form.Items.FillOutTheVTSalesAgreement.Visible = ThisIsASalesPlan And Form.ToUseTermsOfSales;
	Form.Items.FillOutTheWCHPurchaseAgreement.Visible = ThisIsProcurementPlan And Form.UseTermsOfPurchases;
	Form.Items.GroupTooltipTSAgreement.Visible = (Form.FillInUsingFormula Or Form.FillInByShortage) And
		((ThisIsASalesPlan And Form.ToUseTermsOfSales) Or (ThisIsProcurementPlan And Form.UseTermsOfPurchases));
	Form.Items.FillInManager.Visible = ThisIsASalesPlan;
	Form.Items.FillInStoreFormat.Visible = FormatSelection And (ThisIsASalesPlan Or ThisIsASalesPlanByCategory);
	Form.Items.FillInWarehouse.Visible = ThisIsProcurementPlan Or ThisIsTheRemainderPlan Or ThisIsAnAssemblyDisassemblyPlan 
		Or ThisIsADomesticConsumptionPlan Or SelectWarehouse And (ThisIsASalesPlan Or ThisIsASalesPlanByCategory);
	Form.Items.GroupFillInWarehouseInTS.Visible = (SelectWarehouse Or ChoosingByWarehouseOrFormats)
		And (ThisIsProcurementPlan Or ThisIsTheRemainderPlan Or ThisIsAnAssemblyDisassemblyPlan 
		Or ThisIsADomesticConsumptionPlan Or ThisIsASalesPlan  Or ThisIsASalesPlanByCategory);
	Form.Items.GroupTooltipWarehouseInTS.Visible = (Form.FillInUsingFormula Or Form.FillInByShortage)
		And (SelectWarehouse Or ChoosingByWarehouseOrFormats) 
		And (ThisIsProcurementPlan Or ThisIsTheRemainderPlan Or ThisIsAnAssemblyDisassemblyPlan
		Or ThisIsADomesticConsumptionPlan Or ThisIsASalesPlan Or ThisIsASalesPlanByCategory);
	Form.Items.FillOptionWarehouseStoreFormat.Visible = ChoosingByWarehouseOrFormats And (ThisIsASalesPlan Or ThisIsASalesPlanByCategory);
	Form.Items.FillOutASalesPaymentPlan.Visible = ThisIsASalesPlan;
	Form.Items.FillOutThePurchasePaymentPlan.Visible = ThisIsProcurementPlan;
	Form.Items.ToFillTheAppointment.Visible = Form.UseOrderSupplyWithAssignment;
	Form.Items.FillInAssignmentInTabularForm.Visible = Form.PlanningByAssignments And Form.UseOrderSupplyWithAssignment;
	Form.Items.GroupFillInTheWHAssignment.Visible = Form.PlanningByAssignments And Form.UseOrderSupplyWithAssignment;
	
	Form.Items.DecorationDetailExplanationOfThePurchase.Visible = ThisIsProcurementPlan;
	Form.Items.DecorationDetailExplanationLeftovers.Visible = ThisIsTheRemainderPlan;
	Form.Items.DecorationDetailExplanationOfTheSale.Visible = ThisIsASalesPlan;
	Form.Items.DecorationDetailExplanationOfSalesByCategory.Visible = ThisIsASalesPlanByCategory;
	Form.Items.DecorationDetailingExplanationProduction.Visible = ThisIsTheProductionPlan;
	Form.Items.DecorationDetailingExplanationAssembly.Visible = ThisIsAnAssemblyDisassemblyPlan;
	Form.Items.DecorationDetailExplanationInternalConsumption.Visible = ThisIsADomesticConsumptionPlan;
	
	Form.Items.DecorationSimpleExplanationOfOptionSale.Visible = Form.Object.FillInUsingFormula And Not Form.Object.FillInByShortage;
	Form.Items.DecorationAdvancedFillingOption.Visible = Not Form.Object.FillInUsingFormula And Not Form.Object.FillInByShortage;
	
	Form.Items.FillInUsingFormula.Visible = Not Form.Object.FillInByShortage;
		
	Form.Items.SourceRuleGroup.Visible = Not Form.Object.FillInUsingFormula And Not Form.Object.FillInByShortage;
	Form.Items.FormulaSetupGroup.Visible = Form.Object.FillInUsingFormula And Not Form.Object.FillInByShortage;
	Form.Items.GroupOptionForFillingInTheComposition.Visible = Form.Object.FillInByShortage;
	
	Form.Items.AutoFill.Visible = Form.Object.FillInByShortage;
	
	Form.Items.NumberOfPeriods.Visible = Not ThisIsTheRemainderPlan;
	
	Form.Items.GroupTypeOfPurchasePrice.Visible = Form.CreatePurchasePlanByAmount And ThisIsProcurementPlan And Form.FillInByShortage;
	
	// Forecasting service.
	If Form.FillInUsingFormula = 2 Then
		
		Form.Items.DetailGroup.Visible = False;
		Form.Items.OptionSelectionGroupExplanation.Visible = False;
		Form.Items.SourceRuleGroup.Visible = False;
		Form.Items.FormulaSetupGroup.Visible = False;
		Form.Items.GroupOptionForFillingInTheComposition.Visible = False;
		Form.Items.GroupNumberOfPeriods.Visible = False;
		Form.Items.ForecastingSetupGroup.Visible = True;
		Form.Items.ReplacementSummingGroup.Visible = False;
		Form.Items.FillOutASalesPaymentPlan.Visible = False;
		Form.Items.GroupTypeOfSalesForecastingPrices.Visible = True;
		
		If ThisIsASalesPlanByCategory Then
			Form.Items.ForecastingDetailGroup.Visible = False;
			Form.Items.GroupDetailsForecastingByCategory.Visible = True;
			Form.Items.GroupForSettingUpForecastingFilters.Visible = False;
		Else
			Form.Items.ForecastingDetailGroup.Visible = True;
			Form.Items.GroupDetailsForecastingByCategory.Visible = False;
			Form.Items.GroupForSettingUpForecastingFilters.Visible = True;
		EndIf;
		
	Else
		
		Form.Items.DetailGroup.Visible = True;
		Form.Items.OptionSelectionGroupExplanation.Visible = True;
		Form.Items.GroupOptionForFillingInTheComposition.Visible = Form.Object.FillInByShortage;
		Form.Items.GroupNumberOfPeriods.Visible = True;
		Form.Items.ForecastingDetailGroup.Visible = False;
		Form.Items.GroupDetailsForecastingByCategory.Visible = False;
		Form.Items.ForecastingSetupGroup.Visible = False;
		Form.Items.ReplacementSummingGroup.Visible = True;
		Form.Items.FillOutASalesPaymentPlan.Visible = ThisIsASalesPlan;
		Form.Items.GroupTypeOfSalesForecastingPrices.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFillingModeSettingsForDeficits()
	
	If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.PlanOfGoodsStock") Then
		Object.DemandPlanning = False;
		Object.PlanningOfGoodsStock = True;
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan")
		Or Object.PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan")
		And (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
		Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly"))
		Or Object.PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan")
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
		Object.DemandPlanning = False;
		Object.PlanningOfGoodsStock = False;
	Else
		Object.DemandPlanning = True;
		Object.PlanningOfGoodsStock = False;
	EndIf;
	
	If Not PlanningProcessManagement 
		Or Object.PlanningOfGoodsStock
		Or Object.DemandPlanning Then
		Object.FillInByShortage = False;
		Items.FillInByShortage.Visible = False;
		Items.DecorationExplanationFillingInTheDeficit.Visible = False;
		Return;
	Else
		Items.FillInByShortage.Visible = True;
		Items.DecorationExplanationFillingInTheDeficit.Visible = True;
	EndIf;
	
	OptionsForFillingComposition = New Array;
	
	If Object.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "Kits";
		Variant.Presentation = NStr("vi = 'bộ lắp ráp';
									|ru = 'собираемые комплекты';
									|en = 'assembled sets'; fa = 'assembled sets';
									|it = 'set raccolti';
									|pl = 'zbierane zestawy';
									|tr = 'toplanan ürün setleri'");
		Variant.LongDesc = NStr("vi = 'Mặt hàng mà đã tạo ít nhất một phương án đóng bộ.';
								|ru = 'Номенклатура, для которой создан хотя бы один вариант комплектации.';
								|en = 'Items that have one or more product kit configurations created.'; fa = 'Items that have one or more product kit configurations created.';
								|it = 'La nomenclatura per la quale è stata creata almeno una versione di configurazione.';
								|pl = 'Towary, dla których utworzono chociażby jeden wariant kompletacji.';
								|tr = 'Kendisi için en az bir set konfigürasyonu oluşturulan öğe.'");
		OptionsForFillingComposition.Add(Variant);
	ElsIf Object.PlanType = Enums.TypesOfPlans.ProductionPlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "ProductsAndSemiFinishedProducts";
		Variant.Presentation = NStr("vi = 'sản phẩm và bán thành phẩm';
									|ru = 'продукция и полуфабрикаты';
									|en = 'manufactured products and semi-finished products'; fa = 'manufactured products and semi-finished products';
									|it = 'Prodotto e semilavorati';
									|pl = 'produkcja i półprodukty';
									|tr = 'imal edilen ürünler ve yarı mamul ürünler'");
		Variant.LongDesc = NStr("vi = 'Mặt hàng có ít nhất một bảng kê chi tiết.';
								|ru = 'Номенклатура, которая имеет хотя бы одну спецификацию.';
								|en = 'Items which have at least one bill of materials.'; fa = 'Items which have at least one bill of materials.';
								|it = 'Nomenclatura che ha almeno una specifica.';
								|pl = 'Towary, które posiadają chociażby jedną certyfikację.';
								|tr = 'En az bir ürün reçetesine sahip olan ürünler.'");
		OptionsForFillingComposition.Add(Variant);
	ElsIf Object.PlanType = Enums.TypesOfPlans.PurchasePlan Then
		
		Variant = New Structure("Source, Presentation, LongDesc");
		Variant.Source = "GoodsAndMaterials";
		Variant.Presentation = NStr("vi = 'hàng hóa và nguyên vật liệu';
									|ru = 'товары и материалы';
									|en = 'products and materials'; fa = 'products and materials';
									|it = 'merci e materiali';
									|pl = 'towary i materiały';
									|tr = 'ürünler ve materyaller'");
		Variant.LongDesc = NStr("vi = 'Mặt hàng mà chỉ có thể được cung cấp thông qua mua hàng.';
								|ru = 'Номенклатура, которая может быть обеспечена только за счет закупки.';
								|en = 'Items that could be supplied only through purchasing.'; fa = 'Items that could be supplied only through purchasing.';
								|it = 'Articoli che possono essere forniti solo per acquisto.';
								|pl = 'Nomenklatura, która może być zaopatrzona tylko na koszt zakupu.';
								|tr = 'Sadece satın alım faturasına göre teminatlı olabilen ürünler.'");
		OptionsForFillingComposition.Add(Variant);
		
	EndIf;
	
	Items.ContentFillingVariant.ChoiceList.Clear();
	
	IndexOf = 1;
	For Each Variant In OptionsForFillingComposition Do
	
		Items.ContentFillingVariant.ChoiceList.Add(Variant.Source, Variant.Presentation);
		ElementOptionForFillingComposition = Items["OptionOfFillingInCompositionExplanation"+IndexOf]; // FormField - 
		Variant.Property("LongDesc", ElementOptionForFillingComposition.Title);
		IndexOf = IndexOf + 1;
	EndDo;
	
	While IndexOf <= 5 Do
	
		Items["OptionOfFillingInCompositionExplanation"+IndexOf].Visible = False;
		IndexOf = IndexOf + 1;
	
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeBlankMark(Form, NumberOfPeriods, Substitutional)
	Form.Items.NumberOfPeriods.MarkIncomplete = Not ValueIsFilled(NumberOfPeriods) And Substitutional;
EndProcedure

&AtServer
Procedure GenerateListOfPlanTypesByPlanningStage()
	
	Items.PlanType.ChoiceList.Clear();
	Items.ProductionProcessType.ChoiceList.Clear();
	Items.BusinessOperation.ChoiceList.Clear();
	
	If Not ValueIsFilled(Object.Parent) Then
		
		If GetFunctionalOption("UsePurchasePlanning") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.PurchasePlan, NStr("vi = 'Kế hoạch mua hàng';
																				|ru = 'Плана закупок';
																				|en = 'Purchase plan'; fa = 'برنامه خرید';
																				|it = 'Del piano di acquisti';
																				|pl = 'Planu zakupów';
																				|tr = 'Satın alma planı'"));
		EndIf;
		If GetFunctionalOption("UsePlanningOfGoodsStock") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.PlanOfGoodsStock, NStr("vi = 'Kế hoạch số dư';
																					|ru = 'Плана остатков';
																					|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
																					|it = 'Del piano di giacenze';
																					|pl = 'Planu ostatków';
																					|tr = 'Mal stok planı'"));
		EndIf;
		If GetFunctionalOption("UseSalesPlansByCategories") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.SalesPlanByCategories, NStr("vi = 'Kế hoạch bán hàng theo thể loại';
																						|ru = 'Плана продаж по категориям';
																						|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
																						|it = 'Del piano delle vendite per categorie';
																						|pl = 'Planu sprzedaży wg kategorii';
																						|tr = 'Kategorilere göre satış tahmini'"));
		EndIf;
		If GetFunctionalOption("UseSalesPlans") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.SalesPlan, NStr("vi = 'Kế hoạch bán hàng';
																			|ru = 'Плана продаж';
																			|en = 'Sales forecast'; fa = 'پیش‌بینی فروش';
																			|it = 'Del piano delle vendite';
																			|pl = 'Planu sprzedaży';
																			|tr = 'Satış tahmini'"));
		EndIf;
		If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.AssemblyDisassemblyPlan, NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
																							|ru = 'Плана сборки (разборки)';
																							|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
																							|it = 'Del piano di assemblaggio (disassemblaggio)';
																							|pl = 'Planu montażu (demontażu)';
																							|tr = 'Montaj planı (demontaj)'"));
			
			Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.AssemblyFromComponents);
			Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.DisassemblyIntoComponents);
		EndIf; 
		If GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.InventoryConsumptionPlan, 
				NStr("vi = 'Kế hoạch nhu cầu nội bộ';
					|ru = 'Плана внутренних потреблений';
					|en = 'Inventory consumption plan'; fa = 'برنامه مصرف موجودی';
					|it = 'Del piano di consumi interni';
					|pl = 'Planu konsumpcji wewnętrznych';
					|tr = 'İç tüketim planı'"));
		EndIf;
		If GetFunctionalOption("UseProductionPlanning") Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.ProductionPlan, NStr("vi = 'Kế hoạch sản xuất';
																					|ru = 'Плана производства';
																					|en = 'Production plan'; fa = 'برنامه تولید';
																					|it = 'Del piano di produzione';
																					|pl = 'Planu produkcji';
																					|tr = 'Üretim planı'"));
			
			Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.Assembly);
			If DynamicStructureOfProductionOrders Then
				If Not PlanningProcessManagement Then
					Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.PerformRM);
				EndIf;
			Else
				Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.Repair);
			EndIf;
			Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.Disassembly);
		EndIf;
	Else
		StageDetails = Common.ObjectAttributesValues(Object.Parent, "DemandPlanning, PlanningOfGoodsStock");
		FillPropertyValues(Object, StageDetails);
		
		If StageDetails.DemandPlanning Then
			If GetFunctionalOption("UseSalesPlans") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.SalesPlan, NStr("vi = 'Kế hoạch bán hàng';
																				|ru = 'Плана продаж';
																				|en = 'Sales forecast'; fa = 'پیش‌بینی فروش';
																				|it = 'Del piano delle vendite';
																				|pl = 'Planu sprzedaży';
																				|tr = 'Satış tahmini'"));
			EndIf;
			If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.AssemblyDisassemblyPlan, NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
																								|ru = 'Плана сборки (разборки)';
																								|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
																								|it = 'Del piano di assemblaggio (disassemblaggio)';
																								|pl = 'Planu montażu (demontażu)';
																								|tr = 'Montaj planı (demontaj)'"));
				
				Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.DisassemblyIntoComponents);
			EndIf;
			If GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.InventoryConsumptionPlan, 
					NStr("vi = 'Kế hoạch nhu cầu nội bộ';
						|ru = 'Плана внутренних потреблений';
						|en = 'Inventory consumption plan'; fa = 'برنامه مصرف موجودی';
						|it = 'Del piano di consumi interni';
						|pl = 'Planu konsumpcji wewnętrznych';
						|tr = 'İç tüketim planı'"));
			EndIf;
			If GetFunctionalOption("UseProductionPlanning")
				And DescriptionOfManufacturingProcessTypeIsAvailable Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.ProductionPlan, NStr("vi = 'Kế hoạch sản xuất';
																						|ru = 'Плана производства';
																						|en = 'Production plan'; fa = 'برنامه تولید';
																						|it = 'Del piano di produzione';
																						|pl = 'Planu produkcji';
																						|tr = 'Üretim planı'"));
				
				Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.Disassembly);
			EndIf;
			If GetFunctionalOption("UseSalesPlansByCategories") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.SalesPlanByCategories, NStr("vi = 'Kế hoạch bán hàng theo thể loại';
																							|ru = 'Плана продаж по категориям';
																							|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
																							|it = 'Del piano delle vendite per categorie';
																							|pl = 'Planu sprzedaży wg kategorii';
																							|tr = 'Kategorilere göre satış tahmini'"));
			EndIf;
		ElsIf StageDetails.PlanningOfGoodsStock Then
			Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.PlanOfGoodsStock, NStr("vi = 'Kế hoạch số dư';
																					|ru = 'Плана остатков';
																					|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
																					|it = 'Del piano di giacenze';
																					|pl = 'Planu ostatków';
																					|tr = 'Mal stok planı'"));
			Object.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
			
			RecalculateShortages = True;
			SetVisibility1(ThisObject);
		Else
			If GetFunctionalOption("UsePurchasePlanning") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.PurchasePlan, NStr("vi = 'Kế hoạch mua hàng';
																					|ru = 'Плана закупок';
																					|en = 'Purchase plan'; fa = 'برنامه خرید';
																					|it = 'Del piano di acquisti';
																					|pl = 'Planu zakupów';
																					|tr = 'Satın alma planı'"));
			EndIf;
			If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.AssemblyDisassemblyPlan, NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
																								|ru = 'Плана сборки (разборки)';
																								|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
																								|it = 'Del piano di assemblaggio (disassemblaggio)';
																								|pl = 'Planu montażu (demontażu)';
																								|tr = 'Montaj planı (demontaj)'"));
				
				Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.AssemblyFromComponents);
			EndIf; 
			If GetFunctionalOption("UseProductionPlanning") Then
				Items.PlanType.ChoiceList.Add(Enums.TypesOfPlans.ProductionPlan, NStr("vi = 'Kế hoạch sản xuất';
																						|ru = 'Плана производства';
																						|en = 'Production plan'; fa = 'برنامه تولید';
																						|it = 'Del piano di produzione';
																						|pl = 'Planu produkcji';
																						|tr = 'Üretim planı'"));
				
				Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.Assembly);
				If DynamicStructureOfProductionOrders Then
					If Not PlanningProcessManagement Then
						Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.PerformRM);
					EndIf;
				Else
					Items.ProductionProcessType.ChoiceList.Add(Enums.ProductionProcessTypes.Repair);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If Items.PlanType.ChoiceList.FindByValue(Object.PlanType) = Undefined Then
		If Items.PlanType.ChoiceList.Count() > 0 Then
			Object.PlanType = Items.PlanType.ChoiceList[0].Value;
		EndIf;
	EndIf;
	If Items.ProductionProcessType.ChoiceList.FindByValue(Object.ProductionProcessType) = Undefined Then
		Object.ProductionProcessType = Enums.ProductionProcessTypes.EmptyRef();
	EndIf;
	If Items.BusinessOperation.ChoiceList.FindByValue(Object.BusinessOperation) = Undefined Then
		Object.BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsUsingFormula(Form)
	Form.FillInUsingFormula = 0;
	If Form.Object.FillInUsingFormula Then
		Form.FillInUsingFormula = 1;
	ElsIf Form.Object.FillInByServiceData Then
		Form.FillInUsingFormula = 2;
	EndIf;
EndProcedure

&AtServer
Procedure FillInFormulaWhenChangingOnServer()
	DefineDataLayoutScheme();
	CreatePresentationOfProductSelection();
EndProcedure

&AtServer
Procedure DefineDataLayoutScheme()
	
	If Object.FillInByServiceData Then
	Else
		DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate("Template");
	EndIf;
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	FilterOfProductItem.Initialize(SettingsSource);
	FilterOfProductItem.LoadSettings(DataCompositionSchema.DefaultSettings);
	
EndProcedure

&AtClient
Procedure FillInAccordingToFormulaWhenChangingFragment()
	
	Object.FillInUsingFormula = (FillInUsingFormula = 1);
	Object.FillInByServiceData = (FillInUsingFormula = 2);
	
	If Object.FillInUsingFormula Then
		If Object.FillInWarehouseInTabularForm Then
			Object.FillInWarehouse = True;
			Object.FillInWarehouseInTabularForm = False;
		EndIf;
		If Object.FillInPartnerInTabularForm Then
			Object.FillInPartner = True;
			Object.FillInPartnerInTabularForm = False;
		EndIf;
		If Object.FillInAgreementInTabularForm Then
			Object.FillInTermsOfSales = True;
			Object.FillInAgreementInTabularForm = False;
		EndIf;
	EndIf;
	
	
	SetVisibility1(ThisObject);
	
	UpdateItemAvailability();
	
	FillInFormulaWhenChangingOnServer();
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FillingAndSelectionSettings

&AtClient
Procedure FillingRuleCompletion(Settings, AdditionalParameters) Export 
	
	If TypeOf(Settings) = Type("Structure") Then
		
		Modified = True;
		
		FillPropertyValues(SettingsStructure, Settings, "UpdateAdd,ChangeResultTo,RoundingPrecision");
		
		ShowUserNotification(
			NStr("vi = 'Đã kết thúc lưu tùy chỉnh dưới dạng kế hoạch';
				|ru = 'Сохранение настроек в виде плана завершено';
				|en = 'Settings are saved as a plan'; fa = 'Settings are saved as a plan';
				|it = 'Salvataggio delle impostazioni come piano è completato';
				|pl = 'Zapis ustawień w rodzaju planu został zakończony';
				|tr = 'Plan profilinde ayarların kaydedilmesi tamamlandı'"),
			,
			,
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RuleForFillingOutQuestionRecordCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		If Write() Then
			FillingRule(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingFormula(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf; 
	
	InitializeFormulaFillingSettings();
	
	If Modified Or Not ValueIsFilled(Object.Ref) Then
	
		Notification = New CallbackDescription("FillingFormulaQuestionRecordCompletion", ThisObject);
		
		QueryText = NStr("vi = 'Đã thay đổi tùy chỉnh dạng kế hoạch. Ghi lại?';
						|ru = 'Настройки вида плана были изменены. Записать?';
						|en = 'Settings of the plan profile were changed. Do you want to save them?'; fa = 'Settings of the plan profile were changed. Do you want to save them?';
						|it = 'Le impostazioni del tipo di piano sono state modificate. Registrare?';
						|pl = 'Ustawienia rodzaju planu zostaną zmienione. Zapisać?';
						|tr = 'Plan profili ayarları değiştirildi. Kaydedilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại';
												|ru = 'Записать';
												|en = 'Save'; fa = 'ذخیره';
												|it = 'Salvare';
												|pl = 'Save';
												|tr = 'Kaydet'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		ShowQueryBox(Notification, QueryText, Buttons);
		Return;
		
	EndIf; 
	
	FormParameters = New Structure;
	
	FormParameters.Insert("EditMode");
	FormParameters.Insert("PlanType",      			 Object.PlanType);
	FormParameters.Insert("Periodicity", 			 Periodicity);
	FormParameters.Insert("FillInPartner",    	 Object.FillInPartner);
	FormParameters.Insert("FillInTermsOfSales",    	 Object.FillInTermsOfSales);
	FormParameters.Insert("SettingsStructure",    	 SettingsStructure);
	FormParameters.Insert("OperatorsTreeStorageAddress",  OperatorsTreeStorageAddress);
	FormParameters.Insert("AdditionalFields",  AdditionalFields);
	FormParameters.Insert("Owner", 				Object.Ref);
	FormParameters.Insert("Filter", 					New Structure());
	FormParameters.Insert("FillInByShortage", 		Object.FillInByShortage);
	FormParameters.Insert("NumberOfPeriods", 		Object.NumberOfPeriods);
	
	If Object.PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan") Then
		FormParameters.Insert("PlanByAmount", 			CreatePurchasePlanByAmount);
	ElsIf Object.PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan") Then
		FormParameters.Insert("PlanByAmount",			CreateSalesPlanByAmount);
	Else
		FormParameters.Insert("PlanByAmount",          	False);
	EndIf;
	
	Notification = New CallbackDescription("FillingFormulaCompletion", ThisObject);
			
	OpenForm("Catalog.PlanProfiles.Form.SettingsForm", 
		New Structure("SettingsStructure",FormParameters), 
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure FillingFormulaQuestionRecordCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		If Write() Then
			FillingFormula(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingFormulaCompletion(Settings, AdditionalParameters) Export 
	
	If TypeOf(Settings) = Type("Structure") Then
		
		Modified = True;
		
		FillPropertyValues(SettingsStructure, Settings);
		
		ShowUserNotification(
			NStr("vi = 'Đã kết thúc lưu tùy chỉnh dưới dạng kế hoạch';
				|ru = 'Сохранение настроек в виде плана завершено';
				|en = 'Settings are saved as a plan'; fa = 'Settings are saved as a plan';
				|it = 'Salvataggio delle impostazioni come piano è completato';
				|pl = 'Zapis ustawień w rodzaju planu został zakończony';
				|tr = 'Plan profilinde ayarların kaydedilmesi tamamlandı'"),
			,
			,
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormulaFillingSettings()
	
	If Not ValueIsFilled(Object.Owner) Then
		Return;
	EndIf;
	
	Tree = ProcessingOfFormulas.GetEmptyOperatorsTree();
	Planning.InitializeOperatorTrees(Tree);
	
	OperatorsTreeStorageAddress = PutToTempStorage(Tree, UUID);
	
	ScenarioDetails = Planning.ScriptParameters_(Object.Owner);
	
	TypeOfPlanDetails = New Structure("PlanType, FillInPartner, FillInTermsOfSales, FillInWarehouse, FillInBusinessUnit, FillInCompany, FillInManager,
		|FillInStoreFormat, FillInAssignmentInTabularForm");
		FillPropertyValues(TypeOfPlanDetails, Object);
	
	FieldParameters_ = New Structure();
	FieldParameters_.Insert("AttributePath1", 					"");
	FieldParameters_.Insert("TableFormElement_", 				Undefined);
	FieldParameters_.Insert("ScenarioDetails", 				ScenarioDetails);
	FieldParameters_.Insert("TypeOfPlanDetails", 				TypeOfPlanDetails);
	FieldParameters_.Insert("CreateFormElements", 			False);
	FieldParameters_.Insert("ProductionProcessType", 	Object.ProductionProcessType);
	
	If TypeOfPlanDetails.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		FieldParameters_.Insert("BusinessOperation", Enums.BusinessTransactions.AssemblyFromComponents);
	EndIf;
	
	AdditionalParameters = Planning.AdditionalParametersForFormulaCalculation(FieldParameters_);
	
	ArrayOfOperands = New Array(); // Array of See Planning.FieldStructure - 
	For Each Field In AdditionalParameters Do
		If Field.Value.CreateOperand Then
			ArrayOfOperands.Add(Field.Value);
		EndIf;
	EndDo;
	AdditionalFields.Clear();
	
	For Each Item In ArrayOfOperands Do
		NewRow = AdditionalFields.Add();
		NewRow.Id 	= Item.Name;
		NewRow.DeletionMark = False;
		NewRow.Presentation 	= Item.OperandHeader;
		Item.Property("IncludedInOperand", NewRow.IncludedInOperand);
	EndDo; 
	
EndProcedure

&AtClient
Procedure DecorationItemSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.ContentFillingVariant = "Filter";
	
	Notification = New CallbackDescription("DecorationItemSelectionURLProcessingCompletion", ThisForm);
		
	EditingFormParameters = New Structure("SettingsAddress,NameAddressOfTheLayout",
			 SelectionOfProductsSettings(),
			"DataProcessor.GoodsSelectionByPicking.Template");
	
	OpenForm("CommonForm.EditDataCompositionSettings",
		EditingFormParameters,
		ThisForm,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtServer
Function SelectionOfProductsSettings()
	Return PutToTempStorage(FilterOfProductItem.GetSettings());
EndFunction

&AtClient
Procedure DecorationItemSelectionURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or Not IsTempStorageURL(Result) Then
		Return;
	EndIf;
	ProcessProductSelectionChanges(Result);
	
EndProcedure

&AtServer
Procedure ProcessProductSelectionChanges(FilterAddress)
	
	SelectionOfProductsSetting = GetFromTempStorage(FilterAddress);
	DeleteFromTempStorage(FilterAddress);
	
	FilterOfProductItem.LoadSettings(SelectionOfProductsSetting);
	CreatePresentationOfProductSelection();
	
EndProcedure

&AtServer
Procedure CreatePresentationOfProductSelection()
	
	FilterElement_ = Items.DecorationOptionForFillingInTheCompositionSelection;
	
	If FillInUsingFormula = 2 Then
		FilterElement_ = Items.PredictionFilters;
	EndIf;
	
	FilterPresentation = String(FilterOfProductItem.Settings.Filter);
	If ValueIsFilled(FilterPresentation) Then
		FilterElement_.Title = New FormattedString(NStr("vi = 'thay đổi';
														|ru = 'изменить';
														|en = 'edit'; fa = 'edit';
														|it = 'modificare';
														|pl = 'edit';
														|tr = 'değiştir'"),,,,"Filter");
	Else
		FilterElement_.Title = New FormattedString(NStr("vi = 'chưa đặt';
														|ru = 'не установлен';
														|en = 'not set'; fa = 'not set';
														|it = 'non impostato';
														|pl = 'nie ustawiono';
														|tr = 'kurulmamış'"),,,,"Filter");
	EndIf;
	
EndProcedure


#EndRegion
