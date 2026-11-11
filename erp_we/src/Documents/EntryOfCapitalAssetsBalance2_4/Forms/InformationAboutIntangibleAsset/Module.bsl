
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AttributesToSave = Parameters.AttributesToSave;
	BusinessOperation = Parameters.BusinessOperation;
	Organization = Parameters.Organization;
	FixedAssetsLocation = Parameters.FixedAssetsLocation;
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
										
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(ThisObject, AuxiliaryAttributes);
	
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckAnalystCompletion(ItemDetailsParameters, CheckedAttributes, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_IntangibleAssets" And Source = IntangibleAsset Then
		FillInIAInformation();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region TheAccountingPage

&AtClient
Procedure IntangibleAssetOnChange(Item)
	
	IntangibleAssetWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure DateOfRecognitionAccountingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If RecordInManAccounting 
		And AttributesValuesBeforeChange.DateOfRecognitionAccounting = AttributesValuesBeforeChange.DateOfRecognitionManagementAccounting Then
		DateOfRecognitionManagementAccounting = DateOfRecognitionAccounting;
	EndIf; 
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure DateOfRecognitionManagementAccountingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInDetailsValuesBeforeChange(ThisObject);

EndProcedure

&AtClient
Procedure AccountingProcedureACOnChange(Item)

	ChangedBankingDetails = "AccountingProcedureAC";
	
	If AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition") Then
		
		InitialCostIsDifferent = True;
		ChangedBankingDetails = ChangedBankingDetails + ",InitialCostIsDifferent";
		
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure AccountingProcedureMAOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure FinancialAccountingGroupOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
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
	
	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingLineNMA_CurCostOfACWhenChanging(ThisObject);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure CurrentcCostManAccOnChange(Item)
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure AccumulatedDepreciationAccountingOnChange(Item)
	
	If Items.AccumulatedDepreciationManagementAccounting.Visible 
		And CurrencyOfMan = ComplCurrency
		And AttributesValuesBeforeChange.AccumulatedDepreciationAccounting = AttributesValuesBeforeChange.AccumulatedDepreciationManagementAccounting
		And (AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization")
			Or AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued")) Then
		AccumulatedDepreciationManagementAccounting = AccumulatedDepreciationAccounting;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientLocalization.LineEditingFormNMA_AccumulatedDepreciationOfACWhenChanging(ThisObject);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure AccumulatedDepreciationManagementAccountingOnChange(Item)
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure InitialCostLocalAccountingOnChange(Item)
	
	If Items.InitialCostMA.Visible 
		And CurrencyOfMan = ComplCurrency
		And AttributesValuesBeforeChange.InitialCostLocalAccounting = AttributesValuesBeforeChange.InitialCostMA Then
		InitialCostMA = InitialCostLocalAccounting;
	EndIf; 
	
	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingLineNMA_InitialCostOfACWhenChanging(ThisObject);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure InitialCostMAOnChange(Item)
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClient
Procedure InitialCostIsDifferentOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

#EndRegion

#Region EventPage

&AtClient
Procedure ThereIsAnIntangibleAssetImprovementAccOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure ThereIsAnIntangibleAssetImprovementManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure ThereIsRevaluationReserveLocalOnChange(Item)

	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure ThereIsRevaluationReserveOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure RevaluationReserveAmountOnChange(Item)
	
	If CurrentcCostManAcc <> 0 And RevaluationReserveAmount <> 0 Then
		RevaluationReserveDepreciationAmount = 
			AccumulatedDepreciationManagementAccounting
			* (RevaluationReserveAmount / CurrentcCostManAcc);
	EndIf;
	
EndProcedure

#EndRegion

#Region DepreciationPage

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)

	WhenChangingPeriodOfUse("UsefulLifeAccounting", True);
	
EndProcedure

&AtClient
Procedure ResidualUsefulLifeAccountingOnChange(Item)

	WhenChangingPeriodOfUse("ResidualUsefulLifeAccounting", True);
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeManagementAccounting", False);
	
EndProcedure

&AtClient
Procedure ResidualUsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("ResidualUsefulLifeManagementAccounting", True);
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingOnChange(Item)
	
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
	
	ConfigureDependentFormElements("ExpenseRecordMethodAC,ExpenseItemAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
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

	EntryOfCapitalAssetsBalanceClientLocalization.IALineEditingForm_OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)

	EntryOfCapitalAssetsBalanceClientLocalization.LineEditingFormNMA_StartOfSelection(
		Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	EntryOfCapitalAssetsBalanceClientLocalization.FormForEditingLineNMA_AutoSelection(
		Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	EntryOfCapitalAssetsBalanceClientLocalization.IALineEditingForm_EndOfTextInput(
		Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
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
	
	EntryOfCapitalAssetsBalanceLocalization.IALineEditingForm_OnChangeAttribute(
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
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)

	Items = Form.Items;

	AuxiliaryAttributes = New Structure(Form.AuxiliaryAttributes);
	AuxiliaryAttributes.Insert("ShowPD", Items.FormShowPD.Check);
	
	OnChangeAttributes(Form, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
									Form, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Form, ItemDetailsParameters);
		ChangedBankingDetails = NonCurrentAssetsClientServer.FillInDetailsDependingOnProperties_EnterBalances(
				Form, ItemDetailsParameters);
	EndIf;
	
	Items = Form.Items;
	
	ParametersForEnteringIAResidues = NonCurrentAssetsClientServer.ParametersForEnteringIAResidues(Form, Form.AuxiliaryAttributes);
	
	ThisIsRAndD = (Form.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset"));
	
	#Region AccountingParametersPage
	
	If UpdateAll Then
		Items.DateOfRecognitionManagementAccounting.Title = NStr("vi = 'Đã nhận vào kế toán';
																|ru = 'Принят к учету';
																|en = 'Recognized'; fa = 'شناسایی‌شده';
																|it = 'Riconoscimento';
																|pl = 'Przyjęty do ewidencji';
																|tr = 'Tanındı'");
		Items.LiquidationValueReglCurrency.Visible = Items.ResidualValueLocal.Visible;
		Items.LiquidationValueCurrency.Visible = Items.ResidualValueMan.Visible;
	EndIf;	
	
	If StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		If Form.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
			Items.AccountingProcedureAC.ChoiceList[0].Presentation = NStr("vi = 'Ghi giảm chi phí';
																			|ru = 'Списание расходов';
																			|en = 'Expense write-off'; fa = 'اسقاط هزینه';
																			|it = 'Storno delle spese';
																			|pl = 'Wyksięgowanie wydatków';
																			|tr = 'Gider yazılması'");
			Items.AccountingProcedureMA.ChoiceList[0].Presentation = NStr("vi = 'Ghi giảm chi phí';
																			|ru = 'Списание расходов';
																			|en = 'Expense write-off'; fa = 'اسقاط هزینه';
																			|it = 'Storno delle spese';
																			|pl = 'Wyksięgowanie wydatków';
																			|tr = 'Gider yazılması'");
		Else
			Items.AccountingProcedureAC.ChoiceList[0].Presentation = NStr("vi = 'Trích khấu hao';
																			|ru = 'Начислять амортизацию';
																			|en = 'Accrue amortization'; fa = 'Accrue amortization';
																			|it = 'Calcolare ammortamento';
																			|pl = 'Naliczać amortyzację';
																			|tr = 'Amortismanı tahakkuk ettir'");
			Items.AccountingProcedureMA.ChoiceList[0].Presentation = NStr("vi = 'Trích khấu hao';
																			|ru = 'Начислять амортизацию';
																			|en = 'Accrue amortization'; fa = 'Accrue amortization';
																			|it = 'Calcolare ammortamento';
																			|pl = 'Naliczać amortyzację';
																			|tr = 'Amortismanı tahakkuk ettir'");
		EndIf; 
		
	EndIf;	
	
	If UpdateAll Then
		
		If Form.RecordInLocalAccounting And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently Then
			Items.DateOfRecognitionAccounting.Title = NStr("vi = 'Tiếp nhận vào kế toán (doanh nghiệp)';
															|ru = 'Принят к учету (бух)';
															|en = 'Recognized (accounting)'; fa = 'شناسایی‌شده (حسابداری)';
															|it = 'Ricevuto in contabilità (cont.)';
															|pl = 'Przyjęty do ewidencji (księg.)';
															|tr = 'Muhasebeye kabul edildi (muhasebe)'");
			Items.DateOfRecognitionManagementAccounting.Title = NStr("vi = 'Đã tiếp nhận vào kế toán (quản trị)';
																	|ru = 'Принят к учету (упр)';
																	|en = 'Recognized (mgmt)'; fa = 'شناسایی‌شده (مدیریت)';
																	|it = 'Riconosciuto (gest.)';
																	|pl = 'Przyjęty doo ewidencji (zarz.)';
																	|tr = 'Muhasebeye kabul edildi (yönetimsel)'");
		Else
			Items.DateOfRecognitionAccounting.Title = NStr("vi = 'Đã nhận vào kế toán';
															|ru = 'Принят к учету';
															|en = 'Recognized'; fa = 'شناسایی‌شده';
															|it = 'Riconoscimento';
															|pl = 'Przyjęty do ewidencji';
															|tr = 'Tanındı'");
			Items.DateOfRecognitionManagementAccounting.Title = NStr("vi = 'Đã nhận vào kế toán';
																	|ru = 'Принят к учету';
																	|en = 'Recognized'; fa = 'شناسایی‌شده';
																	|it = 'Riconoscimento';
																	|pl = 'Przyjęty do ewidencji';
																	|tr = 'Tanındı'");
		EndIf;
		
	EndIf;	
	
	#EndRegion
	
	#Region CostPage
	
	If StructureOfChangedProps.Property("KindOfAccountingObject")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		Items.NetBookValueMan.Visible = Items.AccumulatedDepreciationManagementAccounting.Visible;
	EndIf;
	
	If UpdateAll
		Or StructureOfChangedProps.Property("CurrentcCostFinAcc")
		Or StructureOfChangedProps.Property("CurrentcCostManAcc")
		Or StructureOfChangedProps.Property("InitialCostLocalAccounting")
		Or StructureOfChangedProps.Property("AccumulatedDepreciationAccounting")
		Or StructureOfChangedProps.Property("AccumulatedDepreciationManagementAccounting")
		Or StructureOfChangedProps.Property("InitialCostIsDifferent")
		Or StructureOfChangedProps.Property("ApplicationOfTargetFinancing")
		Or EntryOfCapitalAssetsBalanceClientServerLocalization.Nma_LineEditingFormNeedsToRecalculateDependentAmounts(StructureOfChangedProps) Then
		
		RecalculateDependentAmounts(Form);
	EndIf; 
	
	Items.GroupAccumulatedDepreciationHeading.Visible = 
		Items.AccumulatedDepreciationAccounting.Visible
		Or Items.AccumulatedDepreciationManagementAccounting.Visible;
	
	Items.GroupResidualValueHeading.Visible = 
		Items.ACResidualValue.Visible
		Or Items.NetBookValueMan.Visible;
		
	Items.DecorationTitleUU.Visible = Items.CurrentcCostManAcc.Visible;
	
	Items.ImpairmentAC.Visible = Items.CurrentcCostFinAcc.Visible;
	Items.ImpairmentMA.Visible = Items.CurrentcCostManAcc.Visible;
	
	#EndRegion
	
	#Region EventPage
	
	If StructureOfChangedProps.Property("ThereIsRevaluationReserveLocal")
		Or UpdateAll Then
		
		PropertyValue = Not Form.ThereIsRevaluationReserveLocal;
		Items.RevaluationReserveComplSign.ReadOnly = PropertyValue; 
		Items.RevaluationReserveReglAmount.ReadOnly = PropertyValue; 
		Items.RevaluationReserveDepreciationReglAmount.ReadOnly = PropertyValue; 
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		PropertyValue = 
			Form.PostInAccounting 
			And Form.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
			And Form.AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		Items.RevaluationReserveComplSign.Visible = PropertyValue;
		Items.RevaluationReserveReglAmount.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmount.Visible = PropertyValue;
		Items.RevaluationReserveReglAmountCurrencyRegl.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmountCurrencyRegl.Visible = PropertyValue;
		
		//
		PropertyValue = 
			Form.PostInAccounting
			And Form.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
			And Not Form.AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
			
		Items.RevaluationReserveDepreciationReglAmount1.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmountCurrencyRegl1.Visible = PropertyValue;
		Items.RevaluationReserveReglAmount1.Visible = PropertyValue;
		Items.RevaluationReserveReglAmountCurrencyRegl1.Visible = PropertyValue;
		
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
		Or StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		PropertyValue = Form.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
							And Form.AuxiliaryAttributes.RecordInManAccounting;
		
		Items.RevaluationReserveSign.Visible = PropertyValue;
			
		//
		PropertyValue = Form.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
							And Form.AuxiliaryAttributes.RecordInManAccounting
							And (Form.AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
								Or Not Form.AuxiliaryAttributes.CurrenciesDoNotMatch);
		
		Items.RevaluationReserveAmount.Visible = PropertyValue;
		Items.RevaluationReserveAmountCurrencyUpr1.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationAmount.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationAmountCurrencyUpr.Visible = PropertyValue;
			
		//
		PropertyValue = Form.KindOfAccountingObject <> PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
							And Form.AuxiliaryAttributes.RecordInManAccounting
							And Not Form.AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
		
		Items.RevaluationReserveReglAmount1.Visible = PropertyValue;
		Items.RevaluationReserveDepreciationReglAmount1.Visible = PropertyValue;
			
	EndIf;
	
	#EndRegion
	
	#Region DepreciationPage
	
	If StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
			Items.DepreciationMethodAccounting.ChoiceList,
			Not Form.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses"),
			PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"),,
			1);
		
		If Form.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
			
			Items.DepreciationPage.Title = NStr("vi = 'Ghi giảm chi phí';
												|ru = 'Списание расходов';
												|en = 'Expense write-off'; fa = 'اسقاط هزینه';
												|it = 'Storno delle spese';
												|pl = 'Wyksięgowanie wydatków';
												|tr = 'Gider yazılması'");
			
			Items.DepreciationMethodAccounting.Title = NStr("vi = 'Phương thức ghi giảm';
															|ru = 'Способ списания';
															|en = 'Write-off method'; fa = 'روش اسقاط';
															|it = 'Metodo di storno';
															|pl = 'Sposób rozchodu';
															|tr = 'Muhasebe yöntemi'");
			Items.DepreciationAccrualMethodManagementAccounting.Title = NStr("vi = 'Phương thức ghi giảm';
																			|ru = 'Способ списания';
																			|en = 'Write-off method'; fa = 'روش اسقاط';
																			|it = 'Metodo di storno';
																			|pl = 'Sposób rozchodu';
																			|tr = 'Muhasebe yöntemi'");
			Items.UsefulLifeAccounting.Title = NStr("vi = 'Thời hạn ghi giảm';
													|ru = 'Срок списания';
													|en = 'Amortization period'; fa = 'Amortization period';
													|it = 'Termine di storno';
													|pl = 'Termin rozchodu';
													|tr = 'Yazılma süresi'");
			Items.UsefulLifeManagementAccounting.Title = NStr("vi = 'Thời hạn ghi giảm';
																|ru = 'Срок списания';
																|en = 'Amortization period'; fa = 'Amortization period';
																|it = 'Termine di storno';
																|pl = 'Termin rozchodu';
																|tr = 'Yazılma süresi'");

			If Form.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance") Then
				Form.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear");
			EndIf;
			
		Else
			
			Items.DepreciationPage.Title = NStr("vi = 'Khấu hao';
												|ru = 'Амортизация';
												|en = 'Amortization'; fa = 'استهلاک دارایی نامشهود';
												|it = 'Ammortamento';
												|pl = 'Amortization';
												|tr = 'Amortisman'");
			
			Items.DepreciationMethodAccounting.Title = NStr("vi = 'Phương pháp khấu hao';
															|ru = 'Метод начисления';
															|en = 'Depreciation method'; fa = 'روش استهلاک';
															|it = 'Metodo maturazione';
															|pl = 'Metoda naliczenia';
															|tr = 'Tahakkuk yöntemi'");
			Items.DepreciationAccrualMethodManagementAccounting.Title = NStr("vi = 'Phương pháp khấu hao';
																			|ru = 'Метод начисления';
																			|en = 'Depreciation method'; fa = 'روش استهلاک';
																			|it = 'Metodo maturazione';
																			|pl = 'Metoda naliczenia';
																			|tr = 'Tahakkuk yöntemi'");
			Items.UsefulLifeAccounting.Title = NStr("vi = 'Thời hạn sử dụng';
													|ru = 'Срок использования';
													|en = 'Useful life'; fa = 'عمر مفید';
													|it = 'Vita utile';
													|pl = 'Liczba miesięcy amortyzacji';
													|tr = 'Kullanım süresi'");
			Items.UsefulLifeManagementAccounting.Title = NStr("vi = 'Thời hạn sử dụng';
																|ru = 'Срок использования';
																|en = 'Useful life'; fa = 'عمر مفید';
																|it = 'Vita utile';
																|pl = 'Liczba miesięcy amortyzacji';
																|tr = 'Kullanım süresi'");

		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		If Form.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
			
			Items.DepreciationPage.Title = NStr("vi = 'Ghi giảm chi phí';
												|ru = 'Списание расходов';
												|en = 'Expense write-off'; fa = 'اسقاط هزینه';
												|it = 'Storno delle spese';
												|pl = 'Wyksięgowanie wydatków';
												|tr = 'Gider yazılması'");
			
			Items.DepreciationAccrualMethodManagementAccounting.Title = NStr("vi = 'Phương thức ghi giảm';
																			|ru = 'Способ списания';
																			|en = 'Write-off method'; fa = 'روش اسقاط';
																			|it = 'Metodo di storno';
																			|pl = 'Sposób rozchodu';
																			|tr = 'Muhasebe yöntemi'");
			Items.UsefulLifeManagementAccounting.Title = NStr("vi = 'Thời hạn ghi giảm';
																|ru = 'Срок списания';
																|en = 'Amortization period'; fa = 'Amortization period';
																|it = 'Termine di storno';
																|pl = 'Termin rozchodu';
																|tr = 'Yazılma süresi'");

		Else
			
			Items.DepreciationPage.Title = NStr("vi = 'Khấu hao';
												|ru = 'Амортизация';
												|en = 'Amortization'; fa = 'استهلاک دارایی نامشهود';
												|it = 'Ammortamento';
												|pl = 'Amortization';
												|tr = 'Amortisman'");
			
			Items.DepreciationAccrualMethodManagementAccounting.Title = NStr("vi = 'Phương pháp khấu hao';
																			|ru = 'Метод начисления';
																			|en = 'Depreciation method'; fa = 'روش استهلاک';
																			|it = 'Metodo maturazione';
																			|pl = 'Metoda naliczenia';
																			|tr = 'Tahakkuk yöntemi'");
			Items.UsefulLifeManagementAccounting.Title = NStr("vi = 'Thời hạn sử dụng';
																|ru = 'Срок использования';
																|en = 'Useful life'; fa = 'عمر مفید';
																|it = 'Vita utile';
																|pl = 'Liczba miesięcy amortyzacji';
																|tr = 'Kullanım süresi'");

		EndIf;
		
	EndIf;
	
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
	
	Items.ACUsefulLifeExplanation.Visible = Items.UsefulLifeAccounting.Visible;
	Items.TheTermOfUseIsSelfSufficientDecoding.Visible = Items.ResidualUsefulLifeAccounting.Visible;
	
	Items.UsefulLifeMAExplanation.Visible = Items.UsefulLifeManagementAccounting.Visible;
	Items.TermUseUrostomyTranscript.Visible = Items.ResidualUsefulLifeManagementAccounting.Visible;
	
	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("KindOfAccountingObject") 
		Or UpdateAll Then
		
		Items.ExpensesACGroup.Title = 
			?(ThisIsRAndD,
				NStr("vi = 'Ghi giảm chi phí (kế toán doanh nghiệp)';
					|ru = 'Списание расходов (бухгалтерский учет)';
					|en = 'Expense write-off (local accounting)'; fa = 'Expense write-off (local accounting)';
					|it = 'Storno spese (contabilità)';
					|pl = 'Spisanie rozchodów (ewidencja księgowa)';
					|tr = 'Giderlerin mahsuplaşması (muhasebe)'"),
				NStr("vi = 'Khấu hao (kế toán doanh nghiệp)';
					|ru = 'Амортизация (бухгалтерский учет)';
					|en = 'Amortization (local accounting)'; fa = 'استهلاک دارایی نامشهود (حسابداری محلی)';
					|it = 'Ammortamento (contabilità ordinaria)';
					|pl = 'Amortyzacja (ewidencja księgowa)';
					|tr = 'Amortisman (genel muhasebe)'"));
			
		Items.UUExpensesGroup.Title = 
			?(ThisIsRAndD,
				NStr("vi = 'Ghi giảm chi phí (kế toán quản trị)';
					|ru = 'Списание расходов (управленческий учет)';
					|en = 'Expense write-off (management accounting)'; fa = 'Expense write-off (management accounting)';
					|it = 'Storno spese (contabilità gestionale)';
					|pl = 'Spisanie rozchodów (ewidencja zarządcza)';
					|tr = 'Giderlerin mahsuplaşması (yönetim muhasebesi)'"),
				NStr("vi = 'Khấu hao (kế toán quản trị)';
					|ru = 'Амортизация (управленческий учет)';
					|en = 'Amortization (management accounting)'; fa = 'استهلاک دارایی نامشهود (حسابداری مدیریتی)';
					|it = 'Ammortamento (contabilità gestionale)';
					|pl = 'Amortyzacja (ewidencja administracyjna)';
					|tr = 'Amortisman (yönetim muhasebesi)'"));
		
	EndIf;
	
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
		
		If ParametersForEnteringIAResidues.ExpenseItemManagementAccountingRequired_ 
			Or ValueIsFilled(Form.ExpenseItemManagementAccounting) Then
				
			Items.MethodForReflectingMaExpenses.InputHint = "";
			Items.ExpenseItemManagementAccounting.InputHint = "";
			Items.ExpensesDimensionManagementAccounting.InputHint = "";
			Items.BusinessUnitManagementAccounting.InputHint = "";
			Items.LineOfBusinessManagementAccounting.InputHint = "";
			
		Else
			
			If ParametersForEnteringIAResidues.ACDepreciationParametersAreAvailable Then
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
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.FormEditStringNMA_ConfigureDependentFormElements(
		Form, 
		StructureOfChangedProps, 
		ParametersForEnteringIAResidues,
		ItemDetailsParameters);
	
	FillInDetailsValuesBeforeChange(Form);

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, True);
		
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
		
		If AuxiliaryAttributes.BUAccountingIsAvailable 
			And Not AuxiliaryAttributes.UUAccountingIsAvailable 
			And Not AuxiliaryAttributes.AccountingIsAvailableWELL Then
			Items.AccountingProcedureAC.Title = NStr("vi = 'Thứ tự ghi nhận';
													|ru = 'Порядок учета';
													|en = 'Accounting procedure'; fa = 'رویه حسابداری';
													|it = 'Ordine contabilità';
													|pl = 'Tryb ewidencji';
													|tr = 'Muhasebe prosedürü'");
			Items.GroupAccountingPolicy.ShowTitle = False;
		EndIf;
		
		If AuxiliaryAttributes.UUAccountingIsAvailable 
			And Not AuxiliaryAttributes.BUAccountingIsAvailable 
			And Not AuxiliaryAttributes.AccountingIsAvailableWELL Then
			Items.AccountingProcedureMA.Title = NStr("vi = 'Thứ tự ghi nhận';
													|ru = 'Порядок учета';
													|en = 'Accounting procedure'; fa = 'رویه حسابداری';
													|it = 'Ordine contabilità';
													|pl = 'Tryb ewidencji';
													|tr = 'Muhasebe prosedürü'");
			Items.GroupAccountingPolicy.ShowTitle = False;
		EndIf;
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(
			ThisObject, Organization, EndOfMonth(Date) + 1);
		
		IASelectionParameters = New Array;
		
		FilterState = New Array;
		If RecordInOperationalAccounting Then
			FilterState.Add(Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting);
		Else
			FilterState.Add(Enums.IntangibleAssetsStates.PostedInFinancialAccounting);
		EndIf; 
		IASelectionParameters.Add(New ChoiceParameter("Filter.State", FilterState));
		IASelectionParameters.Add(New ChoiceParameter("Context", "ACC,MA"));
		
		Items.IntangibleAsset.ChoiceParameters = New FixedArray(IASelectionParameters);
			
		// Hide localized elements
		Items.DecorationTitleVR.Visible = False;
		Items.DecorationTitlePR.Visible = False;
		Items.DecorationTitleWELL.Visible = False;
		Items.GroupNetBookValueCFHeading.Visible = False;
		Items.GroupAccumulatedDepreciationHeadingCF.Visible = False;
		Items.GroupCurrentValueCFHeader.Visible = False;
		Items.TheDecorationOfTheInitialValuePR.Visible = False;
		Items.DecorationInitialCostOfBP.Visible = False;
		Items.AmountOfExpensesTAAtINVCurrency.Visible = False;
		
		//
		If ReadOnly Then
			Items.FormWriteAndClose.Enabled = False;
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		ConfigureHFCSelectionParameters();
	EndIf; 
	
	EntryOfCapitalAssetsBalanceLocalization.FormEditStringNMA_ConfigureDependentFormElements(
		ThisObject, StructureOfChangedProps);
	
	Items.GroupImpairment.Visible = GetFunctionalOption("UseFixedAssetImpairment");
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("FinancialAccountingGroup") Then
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Form, ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
		
	EntryOfCapitalAssetsBalanceClientServerLocalization.IALineEditingForm_OnChangeAttributes(
		Form, AttributesList);
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

&AtClient
Procedure WhenChangingPeriodOfUse(Var_AttributeName, UpdateIfMatch)

	AttributesList = Var_AttributeName;
	
	If Var_AttributeName = "UsefulLifeAccounting"
		And RecordInManAccounting
		And (UsefulLifeManagementAccounting = 0
			Or UpdateIfMatch
				And AttributesValuesBeforeChange.UsefulLifeAccounting = AttributesValuesBeforeChange.UsefulLifeManagementAccounting) Then
		
		UsefulLifeManagementAccounting = UsefulLifeAccounting;
		AttributesList = AttributesList + ",UsefulLifeManagementAccounting";
		
	EndIf;
	
	EntryOfCapitalAssetsBalanceClientLocalization.IALineEditingForm_WhenChangingPeriodOfUse(
		ThisObject, Var_AttributeName, UpdateIfMatch, AttributesList);
	
	ConfigureDependentFormElements(AttributesList);		

EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsValuesBeforeChange(Form)

	AttributesList = 
	"DateOfRecognitionAccounting,DateOfRecognitionManagementAccounting,
	|UsefulLifeAccounting,UsefulLifeManagementAccounting,
	|CurrentcCostFinAcc,CurrentcCostManAcc,
	|AccumulatedDepreciationAccounting,AccumulatedDepreciationManagementAccounting,
	|InitialCostLocalAccounting,InitialCostMA,
	|ExpenseItemAccounting,ExpensesDimensionAccounting,
	|KindOfAccountingObject";
	
	AttributesValuesBeforeChange = New Structure(AttributesList);
	FillPropertyValues(AttributesValuesBeforeChange, Form);
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.FormForEditingLineNMA_SupplementValuesOfDetailsBeforeChange(
		Form, AttributesValuesBeforeChange);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServer
Procedure IntangibleAssetWhenModifiedOnServer()

	FillInIAInformation();
	
	FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(AssetKind);
	ChangedBankingDetails = "FinancialAccountingGroup";
	
	If AttributesValuesBeforeChange.KindOfAccountingObject <> KindOfAccountingObject Then
		ChangedBankingDetails = ChangedBankingDetails + ",KindOfAccountingObject";
	EndIf; 
	
	If KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		If DepreciationMethodAccounting = Enums.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance Then
			DepreciationMethodAccounting = Enums.AccrualMethodOfIntangibleAssetDepreciation.Linear;
			DepreciationAccrualFactor = 0;
			ChangedBankingDetails = ChangedBankingDetails + ",DepreciationMethodAccounting,DepreciationAccrualFactor";
		EndIf;
	EndIf; 
	
	WhenYouChangeDetailsOfCompletionOnServer("IntangibleAsset", New Structure);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
	RecalculateDependentAmounts(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateDependentAmounts(Form)
	
	If Not Form.InitialCostIsDifferent Then
		
		Form.InitialCostLocalAccounting = Form.CurrentcCostFinAcc;
		Form.InitialCostMA = Form.CurrentcCostManAcc;
		
	EndIf;
	
	// The residual value is not edited
	Form.NetBookValueMan = Form.CurrentcCostManAcc - Form.AccumulatedDepreciationManagementAccounting;
	Form.ACResidualValue = Form.CurrentcCostFinAcc - Form.AccumulatedDepreciationAccounting;
	
	EntryOfCapitalAssetsBalanceClientServerLocalization.RowEditFormNMA_RecalculateDependentAmounts(Form);
	
EndProcedure

&AtServer
Procedure ConfigureHFCSelectionParameters()
	
	ParametersArray = New Array;
	
	If KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset Then
		ParametersArray.Add(New ChoiceParameter("Filter.AssetKind", Enums.KindsOfNonCurrentAssets.IA));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.AssetKind", Enums.KindsOfNonCurrentAssets.RD));
	EndIf;
	
	Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(ParametersArray);
	
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
	
	AccountingStartDate = '000101010000';
	
	EntryOfCapitalAssetsBalanceLocalization.IALineEditingForm_WhenReadingDataOnServer(ThisObject);
	
	FillInIAInformation();
	
	ItemsAndDimensionsSelectionParameters = ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInIAInformation()

	If Not ValueIsFilled(IntangibleAsset)
		Or Not RecordInOperationalAccounting Then
		AssetKind = Enums.KindsOfNonCurrentAssets.IA;
		KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset;
		Items.IntangibleAsset.Title = NStr("vi = 'Tài sản cố định vô hình';
											|ru = 'Нематериальный актив';
											|en = 'Intangible asset'; fa = 'دارایی نامشهود';
											|it = 'Bene immateriale';
											|pl = 'Wartości niematerialne';
											|tr = 'Maddi olmayan varlık'");
		Items.IntangibleAssetsKind.Visible = False;
		EntryOfCapitalAssetsBalanceLocalization.FormForEditingLineNMA_FillInIADetails(ThisObject);
		Return;
	EndIf; 
	
	IAAttributes = Common.ObjectAttributesValues(IntangibleAsset, "DepreciationGroup,KindOfAccountingObject,IntangibleAssetsKind");
	
	KindOfAccountingObject = IAAttributes.KindOfAccountingObject; 
	
	AssetKind = ?(IAAttributes.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset, 
						Enums.KindsOfNonCurrentAssets.IA, 
						Enums.KindsOfNonCurrentAssets.RD);
	
	If KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		
		Title = NStr("vi = 'Thông tin về chi phí Chi phí nghiên cứu phát triển';
					|ru = 'Сведения о расходах на НИОКР';
					|en = 'R&D expense information'; fa = 'R&D expense information';
					|it = 'Informazioni sui costi di Ricerca e Sviluppo';
					|pl = 'Informacje o kosztach na R&D';
					|tr = 'Ar-Ge harcamalarına ilişkin bilgiler'");
		Items.IntangibleAsset.Title = NStr("vi = 'Chi phí nghiên cứu, triển khai';
											|ru = 'Расходы на НИОКР';
											|en = 'R&D expenses'; fa = 'هزینه‌های تحقیق و توسعه';
											|it = 'Spese per Ricerca e Sviluppo';
											|pl = 'Wydatki na R&D';
											|tr = 'Ar-Ge giderleri'");
		Items.IntangibleAssetsKind.Visible = False;
		
	Else
		
		Title = NStr("vi = 'Thông tin Tài sản cố định vô hình';
					|ru = 'Сведения о нематериальном активе';
					|en = 'Intangible asset information'; fa = 'اطلاعات دارایی نامشهود';
					|it = 'Informazioni circa il bene immateriale';
					|pl = 'Informacje o składniku aktywów niematerialnych';
					|tr = 'Maddi olmayan varlıklara ilişkin bilgiler'");
		Items.IntangibleAsset.Title = NStr("vi = 'Tài sản cố định vô hình';
											|ru = 'Нематериальный актив';
											|en = 'Intangible asset'; fa = 'دارایی نامشهود';
											|it = 'Bene immateriale';
											|pl = 'Wartości niematerialne';
											|tr = 'Maddi olmayan varlık'");
		Items.IntangibleAssetsKind.Visible = True;

		If ValueIsFilled(IAAttributes.IntangibleAssetsKind) Then
			IntangibleAssetsKind = New FormattedString(String(IAAttributes.IntangibleAssetsKind));
		Else
			IntangibleAssetsKind = New FormattedString(NStr("vi = 'chưa điền';
															|ru = 'не заполнен';
															|en = 'not filled in'; fa = 'not filled in';
															|it = 'non compilato';
															|pl = 'nie wypełniony';
															|tr = 'doldurulmadı'"),, StyleColors.UnavailableTextColor);
		EndIf; 
		
	EndIf; 
	
	EntryOfCapitalAssetsBalanceLocalization.FormForEditingLineNMA_FillInIADetails(ThisObject);
	
EndProcedure

&AtServer
Procedure CheckAnalystCompletion(ItemDetailsParameters, CheckedAttributes, Cancel)

	ItemsAndDimensionsSelectionParameters = ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);

EndProcedure

&AtServer
Procedure FillInDefaultValues()

	FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(AssetKind);
	
	EntryOfCapitalAssetsBalanceLocalization.LineEditingFormNMA_FillInDefaultValues(ThisObject);
	
	AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, True);
									
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
									ThisObject, AuxiliaryAttributes, "");
									
	Documents.EntryOfCapitalAssetsBalance2_4.FillInDetailsDependingOnProperties(
			ThisObject, AuxiliaryAttributes, ItemDetailsParameters);

	Documents.EntryOfCapitalAssetsBalance2_4.FillInDefaultValues(ThisObject, ThisObject);
			
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
	EntryOfCapitalAssetsBalanceLocalization.FormIntangibleAssets_SupplementParametersForSelectingArticlesAndAnalysts(ItemsAndDimensionsSelectionParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
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
