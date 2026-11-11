
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AttributesToSave  = Parameters.AttributesToSave;
	BusinessOperation = Parameters.BusinessOperation;
	Organization = Parameters.Organization;
	FixedAssetsLocation = Parameters.FixedAssetsLocation;
	RentalContract = Parameters.RentalContract;
	RecordInManAccounting = Parameters.RecordInManAccounting;
	RecordInLocalAccounting = Parameters.RecordInLocalAccounting;
	PostInAccounting = Parameters.PostInAccounting;
	RecordInTA = Parameters.RecordInTA;
	PostInFinancialAndTaxAccounting = Parameters.PostInFinancialAndTaxAccounting;
	RecordInOperationalAccounting = Parameters.RecordInOperationalAccounting;
	RecordInMA = Parameters.RecordInMA;
	Date = Parameters.Date;
	Ref = Parameters.Ref;
	ReadOnly = Parameters.ReadOnly;
	
	If Parameters.Property("AttributesValues") Then
		
		FillPropertyValues(ThisObject, Parameters.AttributesValues);
		
		RevaluationReserveReglAmount = ?(CostRevaluationReserveLocal < 0, -CostRevaluationReserveLocal, CostRevaluationReserveLocal);
		RevaluationReserveDepreciationReglAmount = ?(DepreciationRevaluationReserveLocal < 0, -DepreciationRevaluationReserveLocal, DepreciationRevaluationReserveLocal);
		RevaluationReserveComplSign = (CostRevaluationReserveLocal > 0);
		
		RevaluationReserveAmount = ?(CostRevaluationReserve < 0, -CostRevaluationReserve, CostRevaluationReserve);
		RevaluationReserveDepreciationAmount = ?(DepreciationRevaluationReserve < 0, -DepreciationRevaluationReserve, DepreciationRevaluationReserve);
		RevaluationReserveSign = (CostRevaluationReserve > 0);
		
		LeasedAssetCostAdjustmentTD = -LeasedAssetCostAdjustmentTA;
		
	EndIf;
	
	OnReadCreateAtServer();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit And Modified Then
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
				|ru = 'Данные были изменены. Сохранить изменения?';
				|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
				|it = 'I dati sono stati modificati. Salvare le modifiche?';
				|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
				|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"),
			QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, True);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
									ThisObject, AuxiliaryAttributes);
	
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckAnalystCompletion(ItemDetailsParameters, CheckedAttributes, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Assets" And Source = FixedAsset Then
		FillInFADetails();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region TheAccountingPage

&AtClient
Procedure FixedAssetOnChange(Item)

	MainRemedyWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DateOfRecognitionAccountingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If RecordInManAccounting 
		And AttributesValuesBeforeChange.DateOfRecognitionAccounting = AttributesValuesBeforeChange.DateOfRecognitionManagementAccounting Then
		DateOfRecognitionManagementAccounting = DateOfRecognitionAccounting;
	EndIf; 
	
	ConfigureDependentFormElements(Item);
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtClient
Procedure DateOfRecognitionManagementAccountingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElements(Item.Name);

	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtClient
Procedure AccountingProcedureACOnChange(Item)
	OrderOfAccountingForBUWhenChangingOnServer();
EndProcedure

&AtClient
Procedure AccountingProcedureMAOnChange(Item)
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingOrderOfAccountingUU_OS(ThisObject, AuxiliaryAttributes, True);
	
	ChangedBankingDetails = "AccountingProcedureMA" + ?(Not IsBlankString(ChangedBankingDetails), "," + ChangedBankingDetails, "");
	ConfigureDependentFormElements(ChangedBankingDetails);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure FinancialAccountingGroupOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);

EndProcedure

&AtClient
Procedure LocationAddressOnChange(Item)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

&AtClient
Procedure LocationAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NonCurrentAssetsClient.OpenAddressSelectionFormAndProcessResult(
		ThisObject, 
		Item,
		ThisObject,, 
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LocationAddressClearing(Item, StandardProcessing)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

#EndRegion

#Region CostPage

&AtClient
Procedure CurrentcCostFinAccOnChange(Item)
	
	If Items.CurrentcCostManAcc.Visible 
		And CurrencyOfMan = ComplCurrency
		And AttributesValuesBeforeChange.CurrentcCostFinAcc = AttributesValuesBeforeChange.CurrentcCostManAcc Then
		CurrentcCostManAcc = CurrentcCostFinAcc;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientLocalization.LineEditingFormOS_CurCostOfACWhenChanged(ThisObject);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure CurrentcCostManAccOnChange(Item)
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure AccumulatedDepreciationAccountingOnChange(Item)
	
	If (AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")) 
		And CurrencyOfMan = ComplCurrency
		And AttributesValuesBeforeChange.AccumulatedDepreciationAccounting = AttributesValuesBeforeChange.AccumulatedDepreciationManagementAccounting Then
			
		AccumulatedDepreciationManagementAccounting = AccumulatedDepreciationAccounting;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingOS_LineAccumulatedDepreciationOfACWhenChanging(ThisObject);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure AccumulatedDepreciationManagementAccountingOnChange(Item)
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure InitialCostMAOnChange(Item)
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure InitialCostIsDifferentOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure LeasedAssetCostAdjustmentTAOnChange(Item)
	
	LeasedAssetCostAdjustmentTD = -LeasedAssetCostAdjustmentTA;
	
EndProcedure

#EndRegion

#Region EventPage

&AtClient
Procedure ThereIsChangesOfDepreciationParametersAccountingOnChange(Item)

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure HasChangesInDepreciationParametersManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ThereIsRevaluationReserveLocalOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure RevaluationReserveReglAmountOnChange(Item)
	
	If CurrentcCostFinAcc <> 0 And RevaluationReserveReglAmount <> 0 Then
		CFMultiplier = ?(ApplicationOfTargetFinancing, 1, 0);
		RevaluationReserveDepreciationReglAmount = 
			(AccumulatedDepreciationAccounting + CFMultiplier * AccumulatedDepreciationAccountingTargetFinancing)
			* (RevaluationReserveReglAmount / (CurrentcCostFinAcc + CFMultiplier * CurrentcCostFinAcc));
	EndIf;

EndProcedure

&AtClient
Procedure ThereIsRevaluationReserveOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure RevaluationReserveAmountOnChange(Item)
	
	If CurrentcCostManAcc <> 0 And RevaluationReserveAmount <> 0 Then
		RevaluationReserveDepreciationAmount = 
			AccumulatedDepreciationManagementAccounting
			* (RevaluationReserveAmount / CurrentcCostManAcc);
	EndIf;
	
EndProcedure

&AtClient
Procedure RevaluationReserveReglAmount1OnChange(Item)
	
	If CurrentcCostFinAcc <> 0 And RevaluationReserveReglAmount <> 0 Then
		RevaluationReserveDepreciationReglAmount = 
			AccumulatedDepreciationAccounting
			* (RevaluationReserveReglAmount / CurrentcCostFinAcc);
	EndIf;
	
EndProcedure

#EndRegion

#Region DepreciationPage

&AtClient
Procedure DepreciationAccrualAccountingOnChange(Item)
	ConfigureDependentFormElements(Item.Name);
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)
	
	MethodOfCalculatingDepreciationOfBUWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeAccounting", False);
	
EndProcedure

&AtClient
Procedure ResidualUsefulLifeAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("ResidualUsefulLifeAccounting", False);
	
EndProcedure

&AtClient
Procedure UsefulLifeTaxAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeTaxAccounting", False);
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeManagementAccounting", False);
	
EndProcedure

&AtClient
Procedure ResidualUsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("ResidualUsefulLifeManagementAccounting", False);
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElements("DepreciationAccrualMethodManagementAccounting,AnnualDepreciationRate");
	
EndProcedure

&AtClient
Procedure RunningTimeValueOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

#EndRegion

#Region PageExpenseRecord

&AtClient
Procedure ExpenseItemAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
	
	If ValueIsFilled(ExpenseRecordMethodAC) Then
		ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodAC,ExpenseItemAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingOnChange(Item)
	
	If ValueIsFilled(ExpenseRecordMethodAC) Then
		ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodAC");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	
	If ValueIsFilled(MethodForReflectingMaExpenses) Then
		MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseRecordMethodACOnChange(Item)
	
	ChangedBankingDetails = "ExpenseRecordMethodAC,ExpenseItemAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		ExpenseRecordMethodAC, 
		ExpenseItemAccounting, 
		ExpensesDimensionAccounting, 
		DepartmentACC, 
		LineOfBusinessBookkeeping, 
		BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping);
	
	If ValueIsFilled(ExpenseRecordMethodAC) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure MethodForReflectingMaExpensesOnChange(Item)

	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		MethodForReflectingMaExpenses, 
		ExpenseItemManagementAccounting, 
		ExpensesDimensionManagementAccounting, 
		BusinessUnitManagementAccounting, 
		LineOfBusinessManagementAccounting, 
		BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting);
	
	If ValueIsFilled(MethodForReflectingMaExpenses) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	EndIf;
	
	ConfigureDependentFormElements("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");

EndProcedure

&AtClient
Procedure DepartmentACCOnChange(Item)
	
	If ValueIsFilled(ExpenseRecordMethodAC) Then
		ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodAC,DepartmentACC");
	
EndProcedure

&AtClient
Procedure LineOfBusinessBookkeepingOnChange(Item)
	
	If ValueIsFilled(ExpenseRecordMethodAC) Then
		ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,LineOfBusinessBookkeeping");

EndProcedure

&AtClient
Procedure BusinessUnitManagementAccountingOnChange(Item)
	
	If ValueIsFilled(MethodForReflectingMaExpenses) Then
		MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,BusinessUnitManagementAccounting");

EndProcedure

&AtClient
Procedure LineOfBusinessManagementAccountingOnChange(Item)
	
	If ValueIsFilled(MethodForReflectingMaExpenses) Then
		MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,LineOfBusinessManagementAccounting");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeepingOnChange(Item)
	
	If ValueIsFilled(ExpenseRecordMethodAC) Then
		ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccountingOnChange(Item)
	
	If ValueIsFilled(MethodForReflectingMaExpenses) Then
		MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");

EndProcedure

&AtClient
Procedure TransferExpensesToAnotherCompanyOnChange(Item)

	If Not TransferExpensesToAnotherCompany Then
		CompanyRecipientOfExpenses = PredefinedValue("Catalog.Companies.EmptyRef");;
	EndIf;

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingOS_LineWhenChangingProps(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	EntryOfCapitalAssetsBalanceClientLocalization.LineEditingFormOS_AutoSelection(
		Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	EntryOfCapitalAssetsBalanceClientLocalization.LineEditingFormOS_EndOfTextInput(
		Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)

	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingLineOS_StartSelection(
		Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowPD(Command)
	
	Items.FormShowPD.Check = Not Items.FormShowPD.Check;
	
	ConfigureDependentFormElements(Command.Name);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf;
	If NotificationParameters.ProcessingParameters.Property("Perform_RecalculateDependentAmounts") Then
		RecalculateDependentAmounts(ThisObject);
	EndIf;
	If NotificationParameters.ProcessingParameters.Property("Execute_WhenChangingPeriodOfUse", ActionParameters) Then
		WhenChangingPeriodOfUse(ActionParameters.AttributeName, ActionParameters.UpdateIfMatch);
	EndIf;

EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)

	Var ActionParameters;
	
	EntryOfCapitalAssetsBalanceLocalization.FormForEditingOS_LineWhenChangingProps(
		TagName, ThisObject, AdditionalParameters);

	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnServer(ActionParameters);
	EndIf;
	If AdditionalParameters.Property("Perform_RecalculateDependentAmounts") Then
		RecalculateDependentAmounts(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")

	Items = Form.Items;
	
	AuxiliaryAttributes = New Structure(Form.AuxiliaryAttributes);
	AuxiliaryAttributes.Insert("ShowPD", Items.FormShowPD.Check);
	
	OnChangeAttributes(Form, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ParametersForEnteringFABalances = NonCurrentAssetsClientServer.ParametersForEnteringFABalances(Form, AuxiliaryAttributes);

	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
									Form, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Form, ItemDetailsParameters);
		ChangedBankingDetails = NonCurrentAssetsClientServer.FillInDetailsDependingOnProperties_EnterBalances(
				Form, ItemDetailsParameters);
	EndIf;
	
	TypesOfContractsUnderFSB25 = LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts();
	TransferredToFinLease = (TypesOfContractsUnderFSB25.Find(AuxiliaryAttributes.TypeOfTransferContractForLease) <> Undefined);
	
	#Region TheAccountingPage
	
	If UpdateAll Then
		
		Items.LiquidationValueReglCurrency.Visible = Items.ResidualValueLocal.Visible;
		Items.LiquidationValueCurrency.Visible = Items.ResidualValueMan.Visible;
		
		If AuxiliaryAttributes.BUAccountingIsAvailable 
			And Not AuxiliaryAttributes.UUAccountingIsAvailable 
			And Not AuxiliaryAttributes.AccountingIsAvailableWELL Then
			
			Items.DateOfRecognitionAccounting.Title = NStr("vi = 'Đã nhận vào kế toán';
															|ru = 'Принят к учету';
															|en = 'Recognized'; fa = 'شناسایی‌شده';
															|it = 'Riconoscimento';
															|pl = 'Przyjęty do ewidencji';
															|tr = 'Tanındı'");
			Items.AccountingProcedureAC.Title = NStr("vi = 'Thứ tự ghi nhận';
													|ru = 'Порядок учета';
													|en = 'Accounting procedure'; fa = 'رویه حسابداری';
													|it = 'Ordine contabilità';
													|pl = 'Tryb ewidencji';
													|tr = 'Muhasebe prosedürü'");
			Items.TheGroupIsTheLatestUpgradeToRehl.Title = NStr("vi = 'Nâng cấp';
																|ru = 'Модернизация';
																|en = 'Appreciation'; fa = 'افزایش ارزش';
																|it = 'Modernizzazione';
																|pl = 'Appreciation';
																|tr = 'Modernizasyon'");
			Items.GroupReflectionOfDepreciationExpensesBU.Title = NStr("vi = 'Khấu hao';
																		|ru = 'Амортизация';
																		|en = 'Depreciation'; fa = 'استهلاک';
																		|it = 'Ammortamento';
																		|pl = 'Depreciation';
																		|tr = 'Amortisman'");
			Items.GroupAccountingPolicy.ShowTitle = False;
		EndIf;
			
		If AuxiliaryAttributes.UUAccountingIsAvailable 
			And Not AuxiliaryAttributes.BUAccountingIsAvailable 
			And Not AuxiliaryAttributes.AccountingIsAvailableWELL Then
			
			Items.DateOfRecognitionManagementAccounting.Title = NStr("vi = 'Đã nhận vào kế toán';
																	|ru = 'Принят к учету';
																	|en = 'Recognized'; fa = 'شناسایی‌شده';
																	|it = 'Riconoscimento';
																	|pl = 'Przyjęty do ewidencji';
																	|tr = 'Tanındı'");
			Items.AccountingProcedureMA.Title = NStr("vi = 'Thứ tự ghi nhận';
													|ru = 'Порядок учета';
													|en = 'Accounting procedure'; fa = 'رویه حسابداری';
													|it = 'Ordine contabilità';
													|pl = 'Tryb ewidencji';
													|tr = 'Muhasebe prosedürü'");
			Items.GroupLastModernizationOfTheUPR.Title = NStr("vi = 'Nâng cấp';
																|ru = 'Модернизация';
																|en = 'Appreciation'; fa = 'افزایش ارزش';
																|it = 'Modernizzazione';
																|pl = 'Appreciation';
																|tr = 'Modernizasyon'");
			Items.GroupReflectionOfDepreciationExpensesOfTheUU.Title = NStr("vi = 'Khấu hao';
																			|ru = 'Амортизация';
																			|en = 'Depreciation'; fa = 'استهلاک';
																			|it = 'Ammortamento';
																			|pl = 'Depreciation';
																			|tr = 'Amortisman'");
			Items.GroupAccountingPolicy.ShowTitle = False;
		EndIf;
		
		//
		ValueIsVisible = AuxiliaryAttributes.Date < AuxiliaryAttributes.AccountingStartDate;
			
		ValueToCheck = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued");
		
		NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
			Items.AccountingProcedureMA.ChoiceList, 
			ValueIsVisible, 
			ValueToCheck);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Form.ReglRecordsAreMaintained
			And Form.RecordInOperationalAccounting;
			
		Items.GroupWithAString.Visible = PropertyValue;
		Items.CodeByRNCFA.Visible = PropertyValue;
		Items.CodeByUFADR.Visible = PropertyValue;
		
	EndIf;
	
	#EndRegion
	
	#Region CostPage
	
	If UpdateAll Then
		
		Items.GroupCurrentValueHeading.Title       = NStr("vi = 'Số tiền:';
															|ru = 'Сумма:';
															|en = 'Amount:'; fa = 'مبلغ:';
															|it = 'Importo:';
															|pl = 'Amount:';
															|tr = 'Tutar:'");
		Items.GroupAccumulatedDepreciationHeading.Title = NStr("vi = 'Số tiền:';
																|ru = 'Сумма:';
																|en = 'Amount:'; fa = 'مبلغ:';
																|it = 'Importo:';
																|pl = 'Amount:';
																|tr = 'Tutar:'");
		Items.GroupResidualValueHeading.Title    = NStr("vi = 'Số tiền:';
														|ru = 'Сумма:';
														|en = 'Amount:'; fa = 'مبلغ:';
														|it = 'Importo:';
														|pl = 'Amount:';
														|tr = 'Tutar:'");
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or UpdateAll Then
		
		Items.NetBookValueMan.Visible = 
			Items.AccumulatedDepreciationManagementAccounting.Visible;
		
		Items.ACResidualValue.Visible = 
			Items.AccumulatedDepreciationAccounting.Visible
			Or Items.AccumulatedDepreciationAccountingTargetFinancing.Visible;
		
	EndIf;
	
	If UpdateAll
		Or StructureOfChangedProps.Property("CurrentcCostFinAcc")
		Or StructureOfChangedProps.Property("CurrentcCostManAcc")
		Or StructureOfChangedProps.Property("InitialCostLocalAccounting")
		Or StructureOfChangedProps.Property("AccumulatedDepreciationAccounting")
		Or StructureOfChangedProps.Property("AccumulatedDepreciationManagementAccounting")
		Or StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or EntryOfCapitalAssetsBalanceClientServerLocalization.FormEditStringOS_RequiredToRecalculateDependentAmounts(StructureOfChangedProps) Then
		
		RecalculateDependentAmounts(Form);
	EndIf; 
	
	If UpdateAll Then
		RecalculateTotals(Form);
	EndIf;
	
	Items.DecorationTitleUU.Visible = Items.CurrentcCostManAcc.Visible;
	
	Items.GroupAccumulatedDepreciationHeading.Visible = 
		Items.AccumulatedDepreciationManagementAccounting.Visible 
		Or Items.AccumulatedDepreciationAccounting.Visible;
		
	Items.GroupResidualValueHeading.Visible = 
		Items.NetBookValueMan.Visible 
		Or Items.ACResidualValue.Visible;
		
	Items.ImpairmentAC.Visible = Items.CurrentcCostFinAcc.Visible And Not TransferredToFinLease;
	Items.ImpairmentMA.Visible = Items.CurrentcCostManAcc.Visible And Not TransferredToFinLease;
	
	Items.DepreciationDecoration.Visible = 
		Items.ImpairmentAC.Visible
		Or Items.DepreciationWELL.Visible
		Or Items.ImpairmentOfPR.Visible
		Or Items.DepreciationOfBP.Visible
		Or Items.ImpairmentMA.Visible;
	
	#EndRegion
	
	#Region EventPage
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			Form.PostInAccounting 
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Not TransferredToFinLease;
		
		Items.RevaluationReserveComplSign.Visible = PropertyValue;
		Items.RevaluationReserveReglAmount.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmount.Visible = PropertyValue;
		Items.RevaluationReserveReglAmountCurrencyRegl.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmountCurrencyRegl.Visible = PropertyValue;
		
		//
		PropertyValue = 
			Form.PostInAccounting
			And Not AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Not TransferredToFinLease;
			
		Items.RevaluationReserveDepreciationReglAmount1.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmountCurrencyRegl1.Visible = PropertyValue;
		Items.RevaluationReserveReglAmount1.Visible = PropertyValue;
		Items.RevaluationReserveReglAmountCurrencyRegl1.Visible = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Items.RevaluationReserveSign.Visible = 
			Not TransferredToFinLease
			And (Form.RecordInManAccounting
					And Form.RecordInOperationalAccounting
				Or Not Form.RecordInOperationalAccounting
					And Form.RecordInMA);
		
		//
		PropertyValue =
			Not TransferredToFinLease
			And (Form.RecordInManAccounting
					And Form.RecordInOperationalAccounting
					And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
						Or Not AuxiliaryAttributes.CurrenciesDoNotMatch)
				Or Not Form.RecordInOperationalAccounting
					And Form.RecordInMA);
			
		Items.RevaluationReserveAmount.Visible = PropertyValue;
		Items.RevaluationReserveAmountCurrencyUpr.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationAmount.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationAmountCurrencyUpr.Visible = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("ThereIsRevaluationReserveLocal")
		Or UpdateAll Then
		
		PropertyValue = Not Form.ThereIsRevaluationReserveLocal;
		
		Items.RevaluationReserveComplSign.ReadOnly = PropertyValue; 
		Items.RevaluationReserveReglAmount.ReadOnly = PropertyValue; 
		Items.RevaluationReserveDepreciationReglAmount.ReadOnly = PropertyValue; 
			
	EndIf;
	
	If StructureOfChangedProps.Property("ThereIsRevaluationReserve")
		Or UpdateAll Then
		
		PropertyValue = Not Form.ThereIsRevaluationReserve;
		
		Items.RevaluationReserveSign.ReadOnly = PropertyValue; 
		Items.RevaluationReserveAmount.ReadOnly = PropertyValue; 
		Items.RevaluationReserveDepreciationAmount.ReadOnly = PropertyValue; 
		Items.RevaluationReserveReglAmount1.ReadOnly = PropertyValue; 
		Items.RevaluationReserveDepreciationReglAmount1.ReadOnly = PropertyValue; 
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		Items.ReglRevaluationGroup.Title = 
			?(Form.RecordInManAccounting,
				NStr("vi = 'Đánh giá lại (kế toán doanh nghiệp)';
					|ru = 'Переоценка (бухгалтерский учет)';
					|en = 'Revaluation (local accounting)'; fa = 'تجدید ارزیابی (حسابداری محلی)';
					|it = 'Rivalutazione (contabilità)';
					|pl = 'Przeszacowanie (ewidencja księgowa)';
					|tr = 'Yeniden değerleme (muhasebe)'"),
				NStr("vi = 'Đánh giá lại';
					|ru = 'Переоценка';
					|en = 'Revaluation'; fa = 'تجدید ارزیابی';
					|it = 'Rivalutazione';
					|pl = 'Revaluation';
					|tr = 'Yeniden değerleme'"));
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Items.RevaluationOfUprGroup.Title = 
			?(Form.RecordInLocalAccounting,
				NStr("vi = 'Đánh giá lại (kế toán quản trị)';
					|ru = 'Переоценка (управленческий учет)';
					|en = 'Revaluation (management accounting)'; fa = 'تجدید ارزیابی (حسابداری مدیریتی)';
					|it = 'Rivalutazione (constabilità gestionale)';
					|pl = 'Przeszacowanie (ewidencja zarządcza)';
					|tr = 'Yeniden değerlendirme (yönetim muhasebesi)'"),
				NStr("vi = 'Đánh giá lại';
					|ru = 'Переоценка';
					|en = 'Revaluation'; fa = 'تجدید ارزیابی';
					|it = 'Rivalutazione';
					|pl = 'Revaluation';
					|tr = 'Yeniden değerleme'"));
		
	EndIf;
	
	#EndRegion
	
	#Region DepreciationPage
	
	Items.UsefulLifeMAExplanation.Visible = Items.UsefulLifeManagementAccounting.Visible;
	Items.TermUseUrostomyTranscript.Visible = Items.ResidualUsefulLifeManagementAccounting.Visible;
	
	Items.ACUsefulLifeExplanation.Visible = Items.UsefulLifeAccounting.Visible;
	Items.TheTermOfUseIsSelfSufficientDecoding.Visible = Items.ResidualUsefulLifeAccounting.Visible;
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Form.UsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualUsefulLifeAccounting")
		Or UpdateAll Then
		
		Form.TheTermOfUseIsSelfSufficientDecoding = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Form.ResidualUsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Form.UsefulLifeManagementAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualUsefulLifeManagementAccounting")
		Or UpdateAll Then
		
		Form.TermUseUrostomyTranscript = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Form.ResidualUsefulLifeManagementAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ThereIsChangesOfDepreciationParametersAccounting") 
		Or StructureOfChangedProps.Property("ThereIsRevaluationReserveLocal") 
		Or UpdateAll Then
		
		If Form.ThereIsChangesOfDepreciationParametersAccounting And Form.ThereIsRevaluationReserveLocal Then
			Items.CostUsedToCalculateDepreciationInAccounting.ToolTip = NStr("vi = 'Giá trị còn lại sau khi Nâng cấp và đánh giá lại.';
																			|ru = 'Остаточная стоимость после модернизации и переоценки.';
																			|en = 'Net book value after appreciation and revaluation.'; fa = 'Net book value after appreciation and revaluation.';
																			|it = 'Prezzo residuo dopo l''ammodernamento e la rivalutazione.';
																			|pl = 'Wartość po umorzeniu po modernizacji i przeszacowaniu.';
																			|tr = 'Modernizasyon ve yeniden değerleme sonrası net defter değeri.'");
		ElsIf Form.ThereIsChangesOfDepreciationParametersAccounting Then
			Items.CostUsedToCalculateDepreciationInAccounting.ToolTip = NStr("vi = 'Giá trị còn lại tại ngày Nâng cấp cuối cùng.';
																			|ru = 'Остаточная стоимость на дату последней модернизации.';
																			|en = 'Net book value on the last appreciation date.'; fa = 'ارزش دفتری خالص در تاریخ آخرین افزایش ارزش.';
																			|it = 'Valore residuo alla data dell''ultimo aggiornamento.';
																			|pl = 'Wartość rezydualna na dzień ostatniej modernizacji.';
																			|tr = 'Son modernizasyon tarihinde net defter değeri.'");
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("HasChangesInDepreciationParametersManagementAccounting") 
		Or StructureOfChangedProps.Property("ThereIsRevaluationReserve") 
		Or UpdateAll Then
		
		If Form.HasChangesInDepreciationParametersManagementAccounting And Form.ThereIsRevaluationReserve Then
			Items.CostUsedToCalculateDepreciationInManagementAccounting.ToolTip = NStr("vi = 'Giá trị còn lại sau khi Nâng cấp và đánh giá lại.';
																						|ru = 'Остаточная стоимость после модернизации и переоценки.';
																						|en = 'Net book value after appreciation and revaluation.'; fa = 'Net book value after appreciation and revaluation.';
																						|it = 'Prezzo residuo dopo l''ammodernamento e la rivalutazione.';
																						|pl = 'Wartość po umorzeniu po modernizacji i przeszacowaniu.';
																						|tr = 'Modernizasyon ve yeniden değerleme sonrası net defter değeri.'");
		ElsIf Form.HasChangesInDepreciationParametersManagementAccounting Then
			Items.CostUsedToCalculateDepreciationInManagementAccounting.ToolTip = NStr("vi = 'Giá trị còn lại tại ngày Nâng cấp cuối cùng.';
																						|ru = 'Остаточная стоимость на дату последней модернизации.';
																						|en = 'Net book value on the last appreciation date.'; fa = 'ارزش دفتری خالص در تاریخ آخرین افزایش ارزش.';
																						|it = 'Valore residuo alla data dell''ultimo aggiornamento.';
																						|pl = 'Wartość rezydualna na dzień ostatniej modernizacji.';
																						|tr = 'Son modernizasyon tarihinde net defter değeri.'");
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("RunningTimeValue")
		Or UpdateAll Then
		If ValueIsFilled(Form.RunningTimeValue) Then
			Items.EstimatedRunningTime.ToolTip = UnitOfMeasurementOfOperatingTimeIndicator(Form.RunningTimeValue);
		Else
			Items.EstimatedRunningTime.ToolTip = "";
		EndIf; 
	EndIf;
	
	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodAC") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting") 
		Or UpdateAll Then
		
		If ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_ 
			Or ValueIsFilled(Form.ExpenseItemManagementAccounting) Then
			
			Items.MethodForReflectingMaExpenses.InputHint = "";
			Items.ExpenseItemManagementAccounting.InputHint = "";
			Items.ExpensesDimensionManagementAccounting.InputHint = "";
			Items.BusinessUnitManagementAccounting.InputHint = "";
			Items.LineOfBusinessManagementAccounting.InputHint = "";
			
		ElsIf Not ParametersForEnteringFABalances.ExpenseItemManagementAccountingRequired_ Then
			
			If ParametersForEnteringFABalances.AvailableReflectionOfBUExpenses Then
				ArticleInputPrompt = NStr("vi = 'trùng với kế toán doanh nghiệp';
											|ru = 'совпадает с бухгалтерским учетом';
											|en = 'matches local accounting'; fa = 'matches local accounting';
											|it = 'corrisponde alla contabilità';
											|pl = 'jest zgodne z ewidencją księgową';
											|tr = 'genel muhasebe ile örtüşmektedir'");
			Else
				ArticleInputPrompt = NStr("vi = 'trùng với kế toán thuế';
											|ru = 'совпадает с налоговым учетом';
											|en = 'matches tax accounting'; fa = 'matches tax accounting';
											|it = 'corrisponde alla contabilità fiscale';
											|pl = 'jest zgodne z ewidencją podatkową';
											|tr = 'vergi muhasebesi ile örtüşmektedir'");
			EndIf;
			
			Items.MethodForReflectingMaExpenses.InputHint = ArticleInputPrompt;
			Items.ExpenseItemManagementAccounting.InputHint = ArticleInputPrompt;
			Items.ExpensesDimensionManagementAccounting.InputHint = ArticleInputPrompt;
			Items.BusinessUnitManagementAccounting.InputHint = ArticleInputPrompt;
			Items.LineOfBusinessManagementAccounting.InputHint = ArticleInputPrompt;
			
		EndIf; 
		
	EndIf;
	
	If StructureOfChangedProps.Property("ExpenseRecordMethodAC") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Form.ExpenseRecordMethodAC, 
			Form,
			"ExpenseItemAccounting,ExpensesDimensionAccounting,DepartmentACC,LineOfBusinessBookkeeping,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
	EndIf;

	If StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Form.MethodForReflectingMaExpenses, 
			Form,
			"ExpenseItemManagementAccounting,ExpensesDimensionManagementAccounting,BusinessUnitManagementAccounting,LineOfBusinessManagementAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");
	
	EndIf;
	
	#EndRegion
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.FormEditStringOS_ConfigureDependentFormElements(
		Form, StructureOfChangedProps, ItemDetailsParameters);
	
	FillInDetailsValuesBeforeChange(Form);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, True);
	EndIf;
	
	If UpdateAll Then
		
		ReglRecordsAreMaintained = LocalAccntingServer.ReglRecordsAreMaintained(Date);

		Items.PageExpenseRecord.Title = NStr("vi = 'Phản ánh chi phí';
											|ru = 'Отражение расходов';
											|en = 'Expense parameters'; fa = 'پارامترهای هزینه';
											|it = 'Rilevazione delle spese';
											|pl = 'Odzwierciedlenie wydatków';
											|tr = 'Giderlerin kaydı'");
		
		Items.UuDepreciationGroup.ShowTitle = 
			PostInAccounting
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently 
			And RecordInManAccounting;
		
		If AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
			Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'QT (%1):';
															|ru = 'УУ (%1):';
															|en = 'MA (%1):'; fa = 'MA (%1):';
															|it = 'Contabilità Gestionale (%1):';
															|pl = 'EZ (%1):';
															|tr = 'Yönetim Muhasebesi(%1):'"), String(CurrencyOfMan));
			Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'KTDN (%1):';
																|ru = 'БУ (%1):';
																|en = 'LA (%1):'; fa = 'LA (%1):';
																|it = 'Contabilità (%1):';
																|pl = 'EK (%1):';
																|tr = 'Genel Muhasebe (%1):'"), String(ComplCurrency));
		Else
			Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
															|ru = 'Упр. (%1):';
															|en = 'Mgmt (%1):'; fa = 'Mgmt (%1):';
															|it = 'Gest. (%1):';
															|pl = 'Zarz. (%1):';
															|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
			Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'QT. (%1):';
																|ru = 'Регл. (%1):';
																|en = 'Local (%1):'; fa = 'Local (%1):';
																|it = 'Regol. (%1):';
																|pl = 'Reg. (%1):';
																|tr = 'Yerel (%1):'"), String(ComplCurrency));
		EndIf; 
		
		Items.GroupCurrentValueCFHeader.Visible = False;
		Items.GroupAccumulatedDepreciationHeadingCF.Visible = False;
		Items.GroupNetBookValueCFHeading.Visible = False;
		Items.AdjustmentOfTheCostOfLeasedPropertyBuzagolovok.Visible = False;
		Items.DecorationTitleVR.Visible = False;
		Items.DecorationTitlePR.Visible = False;
		Items.DecorationTitleWELL.Visible = False;
		Items.DecorationRateOfDepreciationBurien.Visible = False;
		Items.AmountOfExpensesTAAtINVCurrency.Visible = False;
		
		//
		FASelectionOptions = New Array;
		FilterValue = New Array;
		If RecordInOperationalAccounting Then
			FilterValue.Add(Enums.FixedAssetsStates.NotRecognized_);
			FilterValue.Add(Enums.FixedAssetsStates.TakenOffBooks);
		Else
			FilterValue.Add(Enums.FixedAssetsStates.Recognized_);
		EndIf; 
		FASelectionOptions.Add(New ChoiceParameter("Filter.State", FilterValue));
		FASelectionOptions.Add(New ChoiceParameter("Context", "ACC,MA"));
		
		FilterValue = New Array;
		FilterValue.Add(Enums.FATypes.Asset);
		FilterValue.Add(Enums.FATypes.GroupFA);
		FilterValue.Add(Enums.FATypes.CapitalExpenditureInLeasedAssets);
		FASelectionOptions.Add(New ChoiceParameter("Filter.OSType", FilterValue));

		Items.FixedAsset.ChoiceParameters = New FixedArray(FASelectionOptions);
		
		//
		If ReadOnly Then
			Items.FormWriteAndClose.Enabled = False;
		EndIf;
			
		//
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(
			ThisObject, Organization, EndOfMonth(Date) + 1);
			
	EndIf;
	
	EntryOfCapitalAssetsBalanceLocalization.FormEditStringOS_ConfigureDependentFormElements(
		ThisObject, StructureOfChangedProps);
	
	Items.Impairment.Visible = GetFunctionalOption("UseFixedAssetImpairment");
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

EndProcedure

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Form, ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	If AttributesList.Find("AccountingProcedureAC") <> Undefined Then
		
		If Form.AccountingProcedureAC <> PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual") Then
			
			Form.DepreciationMethodAccounting = Undefined;
			Form.AccelerationFactorAccounting = 0;
			Form.ExpenseItemAccounting = Undefined;
			Form.ExpensesDimensionAccounting = Undefined;
			
			AttributesList.Add("DepreciationMethodAccounting");
			
		EndIf;
		
		If Form.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.CostIsNotRedeemable")
			Or Form.AccountingProcedureAC = PredefinedValue("Enum.FARepaymentProcedure.IncludingInExpensesOnRecognition") Then
			
			Form.DepreciationAccrualAccounting = False;
			Form.UsefulLifeAccounting = 0;
			Form.AnnualDepreciationRate = 0;
			
			AttributesList.Add("DepreciationAccrualAccounting");
			
		EndIf;
		
	EndIf;
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.FormForEditingOS_LineWhenChangingBankingDetails(
		Form, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("FinancialAccountingGroup")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("Contract")
		Or EntryOfCapitalAssetsBalanceClientLocalization.FormEditStringOS_RequiresServerCallToConfigureFormElements(ThisObject, StructureOfChangedProps) Then
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtClient
Procedure WhenChangingPeriodOfUse(Var_AttributeName, UpdateIfMatch)

	AttributesList = Var_AttributeName;
	
	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingOS_StringWhenChangingUsagePeriod(
		ThisObject, Var_AttributeName, UpdateIfMatch, AttributesList);
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
	ConfigureDependentFormElements(AttributesList);		

EndProcedure

&AtServer
Procedure MainRemedyWhenChangingOnServer()

	EntryOfCapitalAssetsBalanceLocalization.FormForEditingOS_LineIsMainMeansWhenChanging(ThisObject);
	
	FillInFADetails();
	
	WhenYouChangeDetailsOfCompletionOnServer("FixedAsset", New Structure);
	
	ConfigureDependentFormElementsOnServer("FixedAsset");
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateDependentAmounts(Form)
	
	If Not Form.InitialCostIsDifferent Then
		
		Form.InitialCostMA = Form.CurrentcCostManAcc;
		Form.InitialCostLocalAccounting = Form.CurrentcCostFinAcc + Form.CurrentCostAccountingTargetFinancing;
		
	EndIf;
	
	If Not Form.AuxiliaryAttributes.ComplianceCAAccountingIsKept 
		And Form.ComplCurrency = Form.CurrencyOfMan Then
		Form.CurrentcCostManAcc = Form.CurrentcCostFinAcc;
		Form.InitialCostMA = Form.InitialCostLocalAccounting;
		Form.AccumulatedDepreciationManagementAccounting = Form.AccumulatedDepreciationAccounting;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.LineEditFormOS_RecalculateDependentAmounts(Form);
	
	RecalculateTotals(Form);
	
	FillInDetailsValuesBeforeChange(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateTotals(Form)

	// The residual value is not edited
	Form.NetBookValueMan = Form.CurrentcCostManAcc - Form.AccumulatedDepreciationManagementAccounting;
	
	If Not Form.AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
		Form.ACResidualValue = Form.CurrentcCostFinAcc - Form.AccumulatedDepreciationAccounting;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.LineEditingFormOS_RecalculateTotals(Form);
	
EndProcedure
 
&AtServer
Procedure FillInFADetails()

	If Not ValueIsFilled(FixedAsset) Then
		FAInformation = New FormattedString("");
		EntryOfCapitalAssetsBalanceLocalization.FormForEditingOSString_FillInFADetails(ThisObject);
		Return;
	EndIf; 
	
	ReceivedDetails = New Structure;
	ReceivedDetails.Insert("AssetID");
	FAAttributes = Common.ObjectAttributesValues(FixedAsset, ReceivedDetails);
	
	StringsList = New Array;
	
	StringsList.Add(NStr("vi = 'Số kiểm kê';
						|ru = 'Инв. №:';
						|en = 'Inv. No.'; fa = 'شماره اموال';
						|it = 'N. d''inventario:';
						|pl = 'Nr inwentarzowy:';
						|tr = 'Env. No.:'"));
	If ValueIsFilled(FAAttributes.AssetID) Then
		StringsList.Add(" ");
		StringsList.Add(TrimAll(FAAttributes.AssetID));
	Else	
		StringsList.Add(" ");
		RowData = New FormattedString(NStr("vi = 'chưa điền';
											|ru = 'не заполнен';
											|en = 'not filled in'; fa = 'not filled in';
											|it = 'non compilato';
											|pl = 'nie wypełniony';
											|tr = 'doldurulmadı'"),, StyleColors.GrayTextColor1);
		StringsList.Add(RowData);
	EndIf;	
	
	FAInformation = New FormattedString(StringsList);
	
	EntryOfCapitalAssetsBalanceLocalization.FormForEditingOSString_FillInFADetails(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsValuesBeforeChange(Form)

	AttributesList = 
	"DateOfRecognitionAccounting,DateOfRecognitionManagementAccounting,
	|UsefulLifeAccounting,UsefulLifeManagementAccounting,
	|CurrentcCostManAcc,AccumulatedDepreciationManagementAccounting,InitialCostMA,
	|CurrentcCostFinAcc,AccumulatedDepreciationAccounting,InitialCostLocalAccounting,
	|ExpenseItemAccounting,ExpensesDimensionAccounting";
	
	AttributesValuesBeforeChange = New Structure(AttributesList);
	FillPropertyValues(AttributesValuesBeforeChange, Form);
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.FormForEditingLineOS_SupplementValuesOfDetailsBeforeChange(
		Form, AttributesValuesBeforeChange);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServerNoContext
Function UnitOfMeasurementOfOperatingTimeIndicator(Val RunningTimeValue)

	Return Common.ObjectAttributeValue(RunningTimeValue, "UnitOfMeasure");

EndFunction

&AtClient
Procedure WhenChangingAddressPresentation(Item)

	NonCurrentAssetsClient.WhenChangingAddressPresentation(
		Item,
		LocationAddress,
		LocationAddressValue);

EndProcedure

&AtServer
Procedure OrderOfAccountingForBUWhenChangingOnServer()
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingAccountingOrderOfBU_OS(ThisObject, AuxiliaryAttributes);
	
	EntryOfCapitalAssetsBalanceLocalization.FormOfEditingLineOS_OrderOfAccountingForBUWhenChanging(ThisObject, ChangedBankingDetails);
	
	RecalculateDependentAmounts(ThisObject);

	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure MethodOfCalculatingDepreciationOfBUWhenChangingOnServer()
	
	EntryOfCapitalAssetsBalanceLocalization.FormForEditingLineOS_DepreciationMethodBUWhenChanging(ThisObject);
	
	ConfigureDependentFormElementsOnServer("DepreciationMethodAccounting");
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	If Parameters.NewRow And Not Parameters.Copy Then
		FillInDefaultValues();
	EndIf;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Items.LiquidationValueCurrency.Title = CurrencyOfMan;
	Items.LiquidationValueReglCurrency.Title = ComplCurrency;
	
	AccountingStartDate = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	
	Items.GroupLocation.Title = NStr("vi = 'Địa điểm';
									|ru = 'Местонахождение';
									|en = 'Location'; fa = 'مکان';
									|it = 'Ubicazione';
									|pl = 'Location';
									|tr = 'Yerleşim'");
	Items.FinanciallyLiablePerson.ToolTip = NStr("vi = 'Người chịu trách nhiệm về tài sản cố định.';
												|ru = 'Материально ответственное лицо за основное средство.';
												|en = 'Employee responsible for fixed asset.'; fa = 'کارمند مسئول دارایی ثابت.';
												|it = 'Responsabile finanziario per i capitali fissi.';
												|pl = 'Osoba odpowiedzialna materialnie za środek trwały.';
												|tr = 'Temel araçtan maddi olarak sorumlu kişi.'");
	
	EntryOfCapitalAssetsBalanceLocalization.FormForEditingOS_StringWhenReadingFileOnServer(ThisObject);
	
	FillInFADetails();
	
	ItemsAndDimensionsSelectionParameters = ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ConfigureDependentFormElementsOnServer();
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()

	ClearMessages();
	
	If Not CheckFilling() Then
		QueryText = NStr("vi = 'Chưa điền trường bắt buộc.
                             |Có thể kết thúc soạn hoặc tiếp tục soạn.';
                             |ru = 'Не заполнены обязательные поля.
                             |Можно завершить редактирование или продолжить редактирование.';
                             |en = 'Some of the required fields are not filled in.
                             |You can choose to finish editing or continue.'; fa = 'Some of the required fields are not filled in.
                             |You can choose to finish editing or continue.';
                             |it = 'I campi obbligatori non sono stati compilati. 
                             |E'' possibile terminare o continuare la compilazione.';
                             |pl = 'Nie wypełnione wymagane pola.
                             |Można zakończyć edycję lub kontynuować edycję.';
                             |tr = 'Gerekli alanlar doldurulmamıştır. 
                             |Düzenlemeyi bitirebilir veya düzenlemeye devam edebilirsiniz.'");
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Kết thúc soạn';
													|ru = 'Завершить редактирование';
													|en = 'Finish editing'; fa = 'پایان ویرایش';
													|it = 'Terminare la modifica';
													|pl = 'Zakończ edycję';
													|tr = 'Düzenlemeyi bitir'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Tiếp tục chỉnh sửa';
													|ru = 'Продолжить редактирование';
													|en = 'Continue editing'; fa = 'Continue editing';
													|it = 'Continuare le modifiche';
													|pl = 'Kontynuuj edycję';
													|tr = 'Düzenlemeye devam et'"));
		CallbackDescription = New CallbackDescription("CompleteEditingCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
	Else
		CompleteEditingCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 

EndProcedure

&AtClient
Procedure CompleteEditingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	EditResult = New Structure(AttributesToSave);
	FillPropertyValues(EditResult, ThisObject);
	
	RevaluationReserveMultiplier = ?(ThereIsRevaluationReserve, ?(RevaluationReserveSign, 1, -1), 0);
	EditResult.Insert("CostRevaluationReserve", RevaluationReserveMultiplier * RevaluationReserveAmount);
	EditResult.Insert("DepreciationRevaluationReserve", RevaluationReserveMultiplier * RevaluationReserveDepreciationAmount);
	
	RevaluationReserveMultiplier = ?(ThereIsRevaluationReserveLocal, ?(RevaluationReserveComplSign, 1, -1), 0);
	EditResult.Insert("CostRevaluationReserveLocal", RevaluationReserveMultiplier * RevaluationReserveReglAmount);
	EditResult.Insert("DepreciationRevaluationReserveLocal", RevaluationReserveMultiplier * RevaluationReserveDepreciationReglAmount);
	
	Modified = False;
	
	Close(EditResult);
	
EndProcedure

&AtServer
Procedure CheckAnalystCompletion(ItemDetailsParameters, CheckedAttributes, Cancel)

	ItemsAndDimensionsSelectionParameters = ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure FillInDefaultValues()

	AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, True);

	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
									ThisObject, AuxiliaryAttributes, "");
									
	Documents.EntryOfCapitalAssetsBalance2_4.FillInDetailsDependingOnProperties(
			ThisObject, AuxiliaryAttributes, ItemDetailsParameters);
										
	Documents.EntryOfCapitalAssetsBalance2_4.FillInDefaultValues(ThisObject, ThisObject);
	
EndProcedure

&AtServerNoContext
Function ItemsAndDimensionsSelectionParameters()
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	//
	EntryOfCapitalAssetsBalanceLocalization.FixedAssetsForm_AddParametersForSelectingArticlesAndAnalytics(ItemsAndDimensionsSelectionParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

&AtClient
Procedure InitialCostLocalAccountingOnChange(Item)
	
	If Items.InitialCostMA.Visible 
		And CurrencyOfMan = ComplCurrency
		And AttributesValuesBeforeChange.InitialCostLocalAccounting = AttributesValuesBeforeChange.InitialCostMA Then
		InitialCostMA = InitialCostLocalAccounting;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientLocalization.LineEditingFormOS_InitialCostOfACWhenChanged(ThisObject);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_DateOfRecognitionAccounting" Then
		DateOfRecognitionAccountingOnChange(Items.DateOfRecognitionAccounting);
	ElsIf Item.Name = "sh_ShamsiInput_F_DateOfRecognitionManagementAccounting" Then
		DateOfRecognitionManagementAccountingOnChange(Items.DateOfRecognitionManagementAccounting);
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
