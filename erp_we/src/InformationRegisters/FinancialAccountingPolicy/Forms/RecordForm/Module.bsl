#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BatchAccountingIsEnabled = CalculationOfCostCached.BatchAccountingIsEnabled();
	BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22();
	BaseVersion = GetFunctionalOption("BaseVersion");
	UseLocal = GetFunctionalOption("UseLocal");
	UseMFPs = False;
	UseMFPs = GetFunctionalOption("UseFinancialAccounting");
	AccountingForProvisionsAndContingentLiabilities = False;
	AccountingForProvisionsAndContingentLiabilities = GetFunctionalOption("GenerateFutureExpenseCommitments");
	TransferToRentalSubleaseBasedOnRussianGAAPFSBU25 = False;
	TransferToRentalSubleaseBasedOnRussianGAAPFSBU25 = GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25");
	Items.GroupArticleInterestAnalyticsFinRent.Visible = TransferToRentalSubleaseBasedOnRussianGAAPFSBU25;

	RecordKey = Undefined;
	RegisterName = Metadata.InformationRegisters.FinancialAccountingPolicy.Name;
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.FinancialAccountingPolicy);
	
	Organization = Parameters.Organization;
	Items.Organization.Visible = Not ValueIsFilled(Organization);
	Title = Title + " " + String(Organization);
	
	ThisIsARecordForm = Parameters.Property("Key", RecordKey);
	If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
		CopyRegisterEntry(Parameters.CopyingValue);
	Else
		ReadRegisterEntry(RecordKey);
	EndIf;
	
	MonthNumber = 1;
	While MonthNumber <= 12 Do
		Items.MonthOfFiscalYearBeginning.ChoiceList.Add(
			MonthNumber,
			InformationRegisters.FinancialAccountingPolicy.PresentationOfBeginningOfFinancialYear(MonthNumber));
		MonthNumber = MonthNumber + 1;
	EndDo;
	Items.MonthOfFiscalYearBeginning.Visible = Not GetFunctionalOption("LocalizationRFService");
	
	AccualInventoryImpairmentProvision = False;
	AccualInventoryImpairmentProvision = GetFunctionalOption("AccualInventoryImpairmentProvision");
	Items.OptionOfReflectingReservesForImpairmentOfInventoriesWhenWritingOffInventoriesForExpenses.Visible = AccualInventoryImpairmentProvision;
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	Items.ExciseTaxesGroup.Visible = UseExcisableGoods;
	
	UseProductionManagement2_2 = False;
	UseProductionManagement2_2 = GetFunctionalOption("UseProductionManagement2_2");
	Items.GroupProductionOfExcisableGoods.Visible = UseProductionManagement2_2;
	
	UseImport = GetFunctionalOption("UseImports")
		Or GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	Items.ImportOfExcisableGoodsGroup.Visible = UseImport;
	
	If Not AccountingForProvisionsAndContingentLiabilities Then
		Items.GroupDiscountingProvisionsAndContingentLiabilities.Visible = False;
	EndIf;

	ItemsAndDimensionsSelectionParameters = InformationRegisters.FinancialAccountingPolicy.ItemsAndDimensionsSelectionParameters(
		Record.RecognizeResearchExpensesInCurrentPeriod, 
		Record.AccountingForDiscountedAccountsPayableToVendors, 
		Record.AccountForDiscountingOfProvisionsAndContingentLiabilities,
		Record.AccountingForRentAccordingToFSB252018 And TransferToRentalSubleaseBasedOnRussianGAAPFSBU25);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ConfigureNonCurrentAssetsWhenCreatingForm();
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	ReadDiscountRates();
	ManagingCostDetailSettings();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ListOfCheckedRegisterFields = CheckedRegisterFields();
	ArrayOfFieldsToCheck = ListOfCheckedRegisterFields.UnloadValues();
	
	ItemsAndDimensionsSelectionParameters = InformationRegisters.FinancialAccountingPolicy.ItemsAndDimensionsSelectionParameters(
		Record.RecognizeResearchExpensesInCurrentPeriod,
		Record.AccountingForDiscountedAccountsPayableToVendors,
		Record.AccountForDiscountingOfProvisionsAndContingentLiabilities,
		Record.AccountingForRentAccordingToFSB252018 And TransferToRentalSubleaseBasedOnRussianGAAPFSBU25);
	IncomeAndExpensesServer.FillCheckProcessing(Record, Cancel, ArrayOfFieldsToCheck, ItemsAndDimensionsSelectionParameters);
	
	For Each AttributeToCheck In ArrayOfFieldsToCheck Do
		If Not ValueIsFilled(Record[AttributeToCheck]) Then
			ListItem = ListOfCheckedRegisterFields.FindByValue(AttributeToCheck);
			MessageText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
											|ru = 'Поле ""%1"" не заполнено';
											|en = 'Field %1 is required'; fa = 'Field %1 is required';
											|it = 'Il campo ""%1"" non è compilato';
											|pl = 'Pole ""%1"" nie jest wypełnione';
											|tr = '""%1"" alanı doldurulmadı'"), ListItem.Presentation);
			Common.MessageToUser(MessageText, , "Record." + AttributeToCheck, , Cancel);
		EndIf;
	EndDo;
	
	CheckChangeInAccountingSettingsForCalculatingCost(Cancel);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	RDExpensesAccountingClient.SetParametersForSelectingExpenseItem(Items.ExpenseItemForRD);
	SetAvailabilityOfDiscountDetails();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("InformationRegister.DiscountRates.Form.EditDiscountRates") Then
		ValuesOfDiscountRates.Clear();
		For Each BidLine In ValueSelected Do
			NewRow = ValuesOfDiscountRates.Add();
			FillPropertyValues(NewRow, BidLine);
		EndDo;
		CreateLabelDiscountRate();
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InventoryValuationMethodOnChange(Item)

	MediumSlipIsUsed = (Record.InventoryValuationMethod = PredefinedValue("Enum.InventoryValuationMethods.MovingAverage"));
	
	If MediumSlipIsUsed And OptionOfGoodsCostAccounting <> "AccordingToPlanned" Then
		
		OptionOfGoodsCostAccounting = "AccordingToPlanned";
		Record.ProductCostingByPlannedCost = True;
		OptionOfReflectingDeviationsInCostOfProducts = "WriteOffCostOfGoodsSelling";
		Record.WriteOffProductCostVariancesToCostOfGoodsSold = True;
		
		CommonClient.MessageToUser(
			NStr("vi = 'Với phương pháp đánh giá giá trị ""Bình quân gia quyền liên hoàn"", nên tiến hành kế toán xuất xưởng thành phẩm theo giá trị dự tính.';
				|ru = 'При методе оценки стоимости ""Среднескользящая"" используется ведение учета выпуска продукции по плановой стоимости.';
				|en = 'If you use the ""Moving average"" cost evaluation method, records of product release are kept at the standard cost.'; fa = 'If you use the ""Moving average"" cost evaluation method, records of product release are kept at the standard cost.';
				|it = 'If you use the ""Moving average"" cost evaluation method, records of product release are kept at the standard cost.';
				|pl = 'If you use the ""Moving average"" cost evaluation method, records of product release are kept at the standard cost.';
				|tr = '""Orta kayan"" maliyet yönteminde, planlanan maliyetle çıktı kayıtlarının tutulması kullanılır.'"));
		
	EndIf;
	
	If MediumSlipIsUsed And AllocateARAPInBackgroundJob() Then
		CommonClient.MessageToUser(
			NStr("vi = 'Khi áp dụng phương pháp đánh giá giá trị ""Bình quân trượt"" nên tắt hằng ""Phân bổ hạch toán công nợ bằng nhiệm vụ nền"".';
				|ru = 'При методе оценки стоимости ""Среднескользящая"" рекомендуется отключить константу ""Распределять взаиморасчеты фоновым заданием"".';
				|en = 'If you use the ""Moving average"" cost evaluation method, we recommend that you disable the ""Allocate AR/AP in background job"" constant.'; fa = 'If you use the ""Moving average"" cost evaluation method, we recommend that you disable the ""Allocate AR/AP in background job"" constant.';
				|it = 'If you use the ""Moving average"" cost evaluation method, we recommend that you disable the ""Allocate AR/AP in background job"" constant.';
				|pl = 'If you use the ""Moving average"" cost evaluation method, we recommend that you disable the ""Allocate AR/AP in background job"" constant.';
				|tr = '""Orta kaymalı"" maliyet tahmin yöntemi için ""Alacak/Borç muhasebesini arka plan işi olarak dağıt"" sabitinin devre dışı bırakılması önerilmektedir.'"));
	EndIf;
	
	SetItemsVisibility(ThisObject);
	ManagingCostDetailSettings();
	
EndProcedure

&AtClient
Procedure ItemizeMaterialAndItemizedExpensesInInventoryCostOnChange(Item)
	SetItemsVisibility(ThisObject);
EndProcedure

&AtClient
Procedure OptionOfGoodsCostAccountingOnChange(Item)
	Record.ProductCostingByPlannedCost = OptionOfGoodsCostAccounting = "AccordingToPlanned";
	If OptionOfGoodsCostAccounting = "AccordingToPlanned" Then
		OptionOfReflectingDeviationsInCostOfProducts = "WriteOffCostOfGoodsSelling";
		Record.WriteOffProductCostVariancesToCostOfGoodsSold = True;
	EndIf;
	SetItemsVisibility(ThisObject);
EndProcedure

&AtClient
Procedure OptionOfReflectingDeviationsInCostOfProductsOnChange(Item)
	Record.WriteOffProductCostVariancesToCostOfGoodsSold = 
		(OptionOfReflectingDeviationsInCostOfProducts = "WriteOffCostOfGoodsSelling");
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	Organization = Record.Organization;
	ReadRegisterEntryWhenChangingProps_(,ChangeDate);
EndProcedure

&AtClient
Procedure ChangeDateOnChange(Item)
	QueryText = NStr("vi = 'Tạo chính sách kế toán mới trên %1?';
					|ru = 'Создать новую учетную политику на %1?';
					|en = 'Create a new accounting policy on the %1?'; fa = 'Create a new accounting policy on the %1?';
					|it = 'Creare una nuova politica contabile per %1?';
					|pl = 'Utworzyć nową politykę rachunkowości na %1?';
					|tr = '%1 için yeni muhasebe politikası oluştur?'");
	QueryText = StrTemplate(QueryText, Format(BegOfMonth(ChangeDate),"DLF=D"));
	ShowQueryBox(New CallbackDescription("ChangeDateOnChangeCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure ChangeDateOnChangeCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReadRegisterEntryWhenChangingProps_(,ChangeDate);
	ElsIf Response = DialogReturnCode.Yes Then
		ReadRegisterEntryWhenChangingProps_(,ChangeDate, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure HistoryDescriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "ChangeHistory" Then
		If Modified Then
			AskQuestionFormModified("OpenChangeHistory_Continued");
		Else
			OpenChangeHistory_();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OptionOfReflectingReservesForImpairmentOfInventoriesWhenWritingOffInventoriesForExpensesOnChange(Item)
	Record.ReverseProvisionWhenWritingOffInventoryToExpenses = 
		OptionOfReflectingReservesForImpairmentOfInventoriesWhenWritingOffInventoriesForExpenses = "ToRestoreReserve";
EndProcedure

&AtClient
Procedure OptionOfAllocatingExpensesForDisposalsInPastPeriodsOnChange(Item)
	Record.AllocateVariancesInPreviousPeriods = 
		OptionOfAllocatingExpensesForDisposalsInPastPeriods = "Full";
EndProcedure

&AtClient
Procedure DivisionIntoShortTermLongTermAssetsAndLiabilitiesOnChange(Item)

	UseAllocationOfLongTermAssetsLiabilitiesWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure UseAllocationOfLongTermAssetsLiabilitiesWhenChangingOnServer()
	
	If Record.DivisionIntoShortTermLongTermAssetsAndLiabilities
		And Not ValueIsFilled(Record.DurationOfCompanyOperatingCycle) Then
			Record.DurationOfCompanyOperatingCycle = 12;
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountRateClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenDiscountRates();
EndProcedure

&AtClient
Procedure RecordAccountingForDiscountedAccountsPayableToVendorsOnChange(Item)
	
	SetAvailabilityOfDiscountDetails();
	UpdateArticleAndAnalyticsSettingsOnServer();
	
EndProcedure

&AtClient
Procedure InterestExpenseWriteOffItemOnChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure InterestExpenseWriteOffItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WriteOffsDimensionOfInterestExpenseAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WriteOffsDimensionOfInterestExpenseTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WriteOffsDimensionOfInterestExpenseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

#Region NonCurrentAssets

&AtClient
Procedure RecordTheOrderOfAccountingInAccordanceWithTheStandardsOfMUOnChange(Item)
	
	If Record.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards") Then
		
		Record.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.StartingNextMonth");
		Record.LeasedAssetDepreciationChargeProcedureManag = PredefinedValue("Enum.DepreciationProcedure.StartingNextMonth");
		Record.ProcedureOfIntangibleAssetAmortizationCharge = PredefinedValue("Enum.DepreciationProcedure.StartingNextMonth");
		
		Record.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.EmptyRef");
		Record.IntangibleAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.EmptyRef");
		
	Else

		Record.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		Record.LeasedAssetDepreciationChargeProcedureManag = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		Record.ProcedureOfIntangibleAssetAmortizationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		
		Record.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod");
		Record.IntangibleAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod");
		
	EndIf;
	
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfFixedAssetDepreciationChargeLocal = Record.ProcedureOfFixedAssetDepreciationCharge;
		Record.LeasedFixedAssetDepreciationChargeProcedureLocal = Record.LeasedAssetDepreciationChargeProcedureManag;
		Record.ProcedureOfIntangibleAssetAmortizationChargeLocal = Record.ProcedureOfIntangibleAssetAmortizationCharge;
	EndIf;
	
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure EntryAccountingProcedureInAccordanceWithTheReglStandardsOnChange(Item)
	If Record.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards") Then
		Record.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.StartingNextMonth");
		Record.LeasedAssetDepreciationChargeProcedureManag = PredefinedValue("Enum.DepreciationProcedure.StartingNextMonth");
		Record.ProcedureOfIntangibleAssetAmortizationCharge = PredefinedValue("Enum.DepreciationProcedure.StartingNextMonth");
	Else
		Record.ProcedureOfFixedAssetDepreciationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		Record.LeasedAssetDepreciationChargeProcedureManag = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
		Record.ProcedureOfIntangibleAssetAmortizationCharge = PredefinedValue("Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting");
	EndIf;
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfFixedAssetDepreciationChargeLocal = Record.ProcedureOfFixedAssetDepreciationCharge;
		Record.LeasedFixedAssetDepreciationChargeProcedureLocal = Record.LeasedAssetDepreciationChargeProcedureManag;
		Record.ProcedureOfIntangibleAssetAmortizationChargeLocal = Record.ProcedureOfIntangibleAssetAmortizationCharge;
	EndIf;
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure RecordProcedureForCalculatingDepreciationFromDateOfAcceptanceForAccountingOnChange(Item)
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfFixedAssetDepreciationChargeLocal = Record.ProcedureOfFixedAssetDepreciationCharge;
	EndIf;
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure RecordOrderOfDepreciationFromNextMonthOnChange(Item)
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfFixedAssetDepreciationChargeLocal = Record.ProcedureOfFixedAssetDepreciationCharge;
	EndIf;
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure RecordProcedureForCalculatingDepreciationOfNMASDateOfAcceptanceForAccountingOnChange(Item)
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfIntangibleAssetAmortizationChargeLocal = Record.ProcedureOfIntangibleAssetAmortizationCharge;
	EndIf;
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure RecordProcedureForCalculatingDepreciationOfIAFromNextMonthOnChange(Item)
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfIntangibleAssetAmortizationChargeLocal = Record.ProcedureOfIntangibleAssetAmortizationCharge;
	EndIf;
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure RecordFALocalAccountingProcedureCoincidesWithLocalAccountingOnChange(Item)
	If Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting") Then
		Record.ProcedureOfFixedAssetDepreciationChargeLocal = Record.ProcedureOfFixedAssetDepreciationCharge;
		Record.LeasedFixedAssetDepreciationChargeProcedureLocal = Record.LeasedAssetDepreciationChargeProcedureManag;
		Record.ProcedureOfIntangibleAssetAmortizationChargeLocal = Record.ProcedureOfIntangibleAssetAmortizationCharge;
	EndIf;
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure RecordFALocalAccountingProcedureIndependentOnChange(Item)
	
	SetItemsVisibility(ThisObject);

EndProcedure

&AtClient
Procedure TheEntryItemOfExpenditureOnResearchWhenYouChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure ToGenerateLossAllowanceOnChange(Item)
	SetItemsVisibility(ThisObject);
EndProcedure

&AtClient
Procedure RecordExpensesForResearchBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure RecordAnalysisOfResearchExpensesAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ResearchExpenseAnalystEntryEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EntryIsAnalyticsOfExpensesForResearchBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure RecordRecognizeResearchExpensesInCurrentPeriodOnChange(Item)
	
	UpdateArticleAndAnalyticsSettingsOnServer();
	
EndProcedure

&AtClient
Procedure RecordAccountForDiscountingOfProvisionsAndContingentLiabilitiesOnChange(Item)
	
	UpdateArticleAndAnalyticsSettingsOnServer();
	
EndProcedure

&AtClient
Procedure RecordAccountingForRentAccordingToFSB252018OnChange(Item)
	
	UpdateArticleAndAnalyticsSettingsOnServer();
	
EndProcedure

&AtClient
Procedure ItemOfWriteOffOfInterestExpensesDiscountingReservesInCaseOfChanges(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure ItemOfWritingOffInterestExpensesDiscountingReservesBeginningOfChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AnalyticsOfWritingOffInterestExpensesDiscountingReservesAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AnalyticsOfWritingOffInterestExpensesDiscountingReservesEndOfTextInput(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AnalyticsOfWritingOffInterestExpensesDiscountingReservesBeginningOfChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ItemOfInterestIncomeOfFinanceLeasesInCaseOfChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure InterestIncomeItemOfFinanceLeaseIsBeginningOfChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemForFinanceLeaseServicesInCaseOfChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure IncomeItemForFinanceLeaseServicesBeginningOfChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	If WriteChanges(True) Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Write(Command)
	WriteChanges();
EndProcedure

&AtClient
Procedure ConfigureProcedureForDebtAssessment(Command)

	OpenForm("InformationRegister.FinancialAccountingPolicy.Form.SetUpDebtEvaluationProcedure",
		New Structure("DebtAssessmentAddress", DebtAssessmentAddress), ThisObject,,,,
		New CallbackDescription("ConfigureProcedureForDebtAssessmentResultProcessing", ThisObject));
		
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetAccountingPolicyParameters(RecordPeriod = Undefined)
	
	If Not ValueIsFilled(RecordPeriod) Then  
		RecordPeriod = ChangeDate;
	EndIf;
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"VATAccountingSettings",
			Organization,
			ChangeDate,
			True);
	If AccountingPolicyParameters <> Undefined Then
		SeparateAccountingOfGoodsByVATTaxation = AccountingPolicyParameters.SeparateAccountingOfGoodsByVATTaxation;
	Else
		SeparateAccountingOfGoodsByVATTaxation = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadRegisterEntry(RecordKey = Undefined, RecordPeriod = Undefined, CreateANewOne = False)
	
	AddAttributes = New Structure("DebtEvaluationProcedure", Undefined);
	AccountingPoliciesTaxSettings.ReadRegisterEntry(ThisObject, 
		RegisterName,
		Organization,
		CreateANewOne,
		RecordKey,
		RecordPeriod,
		AddAttributes);
	
	RepositoryProcedureForDebtAssessment	= AddAttributes.DebtEvaluationProcedure; //ValueStorage
	If ValueIsFilled(RepositoryProcedureForDebtAssessment) Then
		DebtEvaluationProcedure = RepositoryProcedureForDebtAssessment.Get();
		DebtAssessmentAddress = PutToTempStorage(DebtEvaluationProcedure, UUID);
	Else
		DebtAssessmentAddress = Undefined;
	EndIf;
		
	OptionOfGoodsCostAccounting = ?(Record.ProductCostingByPlannedCost, "AccordingToPlanned", "ByActual");
	If Record.WriteOffProductCostVariancesToCostOfGoodsSold Then
		OptionOfReflectingDeviationsInCostOfProducts = "WriteOffCostOfGoodsSelling";
	Else
		OptionOfReflectingDeviationsInCostOfProducts = "IncludeInCost";
	EndIf;
	OptionOfReflectingReservesForImpairmentOfInventoriesWhenWritingOffInventoriesForExpenses =
		?(Record.ReverseProvisionWhenWritingOffInventoryToExpenses, "ToRestoreReserve", "ReduceCosts");
	OptionOfAllocatingExpensesForDisposalsInPastPeriods =
		?(Record.AllocateVariancesInPreviousPeriods, "Full", "Simplified");
	AccountingPoliciesTaxSettingsLocalization.ReadRegisterEntry_AccountingPolicyOfFinAccounting(ThisObject);
	
	BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22(Record.Period);
	
	GetAccountingPolicyParameters(RecordPeriod);
	
	SetItemsVisibility(ThisObject);
	
	UpdateArticleAndAnalyticsSettingsOnServer();
	
	If Not CreateANewOne Then
		ReadDiscountRates();
	EndIf;
	ManagingCostDetailSettings();
	
EndProcedure

&AtClient
Procedure ReadRegisterEntryWhenChangingProps_(RecordKey = Undefined, RecordPeriod = Undefined, CreateANewOne = False)
	If Not Copy Then
		ReadRegisterEntry(RecordKey, RecordPeriod, CreateANewOne);
	EndIf;
	SetAvailabilityOfDiscountDetails();
EndProcedure

&AtServer
Procedure CopyRegisterEntry(CopyingValue)
	AccountingPoliciesTaxSettings.CopyAccountingPolicy(ThisObject, CopyingValue, RegisterName);
	DebtEvaluationProcedure = InformationRegisters.FinancialAccountingPolicy.DebtEvaluationProcedure(
		CopyingValue.Organization, CopyingValue.Period);
	DebtAssessmentAddress = PutToTempStorage(DebtEvaluationProcedure, UUID);
	GetAccountingPolicyParameters();
	SetItemsVisibility(ThisObject);
	Copy = True;
	Modified = True;
	
	UpdateArticleAndAnalyticsSettingsOnServer();
	
	CreateLabelDiscountRate();
	
EndProcedure

&AtClient
Procedure NotifyAfterRecording()
	
	NotificationParameters = New Structure("Organization, Period", Record.Organization, Record.Period);
	EventName = "Record_" + RegisterName;
	Notify(EventName, NotificationParameters);
	
EndProcedure

&AtServer
Function WriteChangesAtServer(Close = False)

	Record.DrillDownProductCostToInitialCostsResourceIsProcessed = True; // For new records, the update handler should not be executed to detail the cost of the productionand the cost of the output

	AddAttributes = New Structure("DebtEvaluationProcedure", New ValueStorage(GetFromTempStorage(DebtAssessmentAddress)));
	RecordingSuccessful = AccountingPoliciesTaxSettings.RecordChangingRegisterEntries(ThisObject, Close, AddAttributes);
	If RecordingSuccessful Then
		RecordDiscountRates();
	EndIf;

	Return RecordingSuccessful;
	
EndFunction

&AtServer
Procedure CheckChangeInAccountingSettingsForCalculatingCost(Cancel)
	
	MediumSlipIsUsed = (Record.InventoryValuationMethod = Enums.InventoryValuationMethods.MovingAverage);

	Query = New Query(InformationRegisters.FinancialAccountingPolicy.QueryTextCurrentTaxAccountingPolicySettings());
	Query.TempTablesManager = New TempTablesManager;
	Companies = CommonClientServer.ValueInArray(Record.Organization);
	AccountingPoliciesTaxSettings.AddParentOrganizationsToTemporaryTableManager(Query.TempTablesManager, Companies);
	Query.SetParameter("Period", Record.Period);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If MediumSlipIsUsed Then
			
			If Not Selection.AccountingPoliciesExist
			 Or Selection.InventoryValuationMethod <> Enums.InventoryValuationMethods.MovingAverage Then
				
				// The inclusion of a medium-slip is possible in a period in which there are no Registered Recorded at cost
				Query = New Query;
				Query.SetParameter("Period", BegOfMonth(Record.Period));
				Query.SetParameter("Organization", Record.Organization);
				
				Query.Text =
				"SELECT TOP 1
				|	T.Period AS Period
				|FROM
				|	AccumulationRegister.InventoryCost AS T
				|WHERE
				|	T.Period >= &Period
				|	AND T.Organization = &Organization";
				
				If Not Query.Execute().IsEmpty() Then
					Common.MessageToUser(
						NStr("vi = 'Việc thiết lập phương pháp đánh giá giá trị ""Trung bình liên hoàn"" có thể chỉ từ tháng mà không có bản ghi kết chuyển trong biểu ghi tích lũy ""Giá vốn hàng hóa""';
							|ru = 'Установка метода оценки стоимости ""Среднескользящая"" возможно только с месяца, начиная с которого нет движений в регистре накопления ""Себестоимость товаров""';
							|en = 'You can set the ""Moving average"" cost evaluation method only from the month starting from which there are no records in the ""Inventory cost"" accumulation register.'; fa = 'You can set the ""Moving average"" cost evaluation method only from the month starting from which there are no records in the ""Inventory cost"" accumulation register.';
							|it = 'Установка метода оценки стоимости ""Среднескользящая"" возможно только с месяца, начиная с которого нет движений в регистре накопления ""Себестоимость товаров""';
							|pl = 'You can set the ""Moving average"" cost evaluation method only from the month starting from which there are no records in the ""Inventory cost"" accumulation register.';
							|tr = '“Kayan ortalama” maliyetlendirme yöntemini yalnızca ‘Malların maliyeti’ birikim kaydında herhangi bir hareketin olmadığı aydan itibaren ayarlamak mümkündür'"),
						,
						"Record.InventoryValuationMethod",
						,
						Cancel);
					
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		// If there is an accounting policy record, then you need to check the change in cost accounting settings.
		If Selection.AccountingPoliciesExist Then
			
			If Selection.MonthOfFiscalYearBeginning											<> Record.MonthOfFiscalYearBeginning
			 Or Selection.InventoryValuationMethod										<> Record.InventoryValuationMethod
			 Or Selection.ItemizeMaterialAndItemizedExpensesInInventoryCost	<> Record.ItemizeMaterialAndItemizedExpensesInInventoryCost
			 Or Selection.DrillDownProductCostToInitialCosts				<> Record.DrillDownProductCostToInitialCosts
			 Or Selection.ItemizeVariancesByLinesOfBusiness					<> Record.ItemizeVariancesByLinesOfBusiness
			 Or Selection.ItemizeVariancesByBusinessUnits							<> Record.ItemizeVariancesByBusinessUnits
			 Or Selection.ItemizeVariancesByWarehousesStorageLocations									<> Record.ItemizeVariancesByWarehousesStorageLocations
			 Or Selection.ProductCostingByPlannedCost							<> Record.ProductCostingByPlannedCost
			 Or Selection.WriteOffProductCostVariancesToCostOfGoodsSold		<> Record.WriteOffProductCostVariancesToCostOfGoodsSold
			 Or Selection.ReverseProvisionWhenWritingOffInventoryToExpenses					<> Record.ReverseProvisionWhenWritingOffInventoryToExpenses
			 Or Selection.DoNotBreakDownToReceiptDocuments							<> Record.DoNotBreakDownToReceiptDocuments Then
			
				InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(
					Record.Period,
					,
					Record.Organization);
				
			EndIf;
			
		EndIf;
	// If there were no accounting policy entries before, then we will create tasks without conditions.
	Else
		InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(
			Record.Period,
			,
			Record.Organization);
	EndIf;
	
EndProcedure

&AtClient
Function WriteChanges(Close = False)
	ClearMessages();
	RecordingSuccessful = WriteChangesAtServer(Close);
	If RecordingSuccessful Then
		NotifyAfterRecording();
	EndIf;
	Return RecordingSuccessful;
EndFunction

&AtClient
Procedure AskQuestionFormModified(NameOfAlert)
	
	QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
					|ru = 'Данные были изменены. Сохранить изменения?';
					|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
					|it = 'I dati sono stati modificati. Salvare le modifiche?';
					|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
					|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin?'");
	Notification = New CallbackDescription(NameOfAlert, ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNoCancel);
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		
		Modified = False;
		Close();
		
	ElsIf Result = DialogReturnCode.Yes Then
		If Not WriteChanges(True) Then
			Return;
		EndIf;
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenChangeHistory_()
	OpenForm("InformationRegister.FinancialAccountingPolicy.Form.EditHistory",
		New Structure("ReadOnly, Organization", ReadOnly, Organization),
		ThisObject,,,,
		New CallbackDescription("OpenChangeHistory_Completion", ThisObject));
EndProcedure

&AtClient
Procedure OpenChangeHistory_Continued(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.No Then
		OpenChangeHistory_();
	ElsIf Result = DialogReturnCode.Yes Then
		If Not WriteChanges(False) Then
			Return;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OpenChangeHistory_Completion(Result, AdditionalParameters) Export
	If ValueIsFilled(Result) Then
		ReadRegisterEntry(Result);
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form)
	
	Items = Form.Items;
	Record = Form.Record;
	
	If Form.BaseVersion Then
		Items.InventoryValuationMethod.Type = FormFieldType.LabelField;
	ElsIf Not Form.BatchAccountingIsEnabled Then
		ListItem = Items.InventoryValuationMethod.ChoiceList.FindByValue(
						PredefinedValue("Enum.InventoryValuationMethods.FIFORollingValuation"));
		If ListItem <> Undefined Then
			Items.InventoryValuationMethod.ChoiceList.Delete(ListItem);
		EndIf;
	// When using batch accounting version 2.2, the choice of the "FIFO (weighted assessment)" evaluation method will not be available.
	// The "FIFO (weighted assessment)" evaluation method is outdated. Its use is not recommended.
	ElsIf Form.BatchAccountingVersion22
	 And Form.Record.InventoryValuationMethod <> PredefinedValue("Enum.InventoryValuationMethods.FIFOWeightedEstimate") Then
		FIFOElementWeightedScore = Items.InventoryValuationMethod.ChoiceList.FindByValue(
			PredefinedValue("Enum.InventoryValuationMethods.FIFOWeightedEstimate"));
		If FIFOElementWeightedScore <> Undefined Then
			Items.InventoryValuationMethod.ChoiceList.Delete(FIFOElementWeightedScore);
		EndIf;
		FIFOElementMovingEstimate = Items.InventoryValuationMethod.ChoiceList.FindByValue(
			PredefinedValue("Enum.InventoryValuationMethods.FIFORollingValuation"));
		FIFOElementMovingEstimate.Presentation = NStr("vi = 'Nhập trước, xuất trước (FIFO)';
														|ru = 'ФИФО';
														|en = 'FIFO'; fa = 'FIFO';
														|it = 'FIFO';
														|pl = 'FIFO';
														|tr = 'FIFO'");
	EndIf;
	
	If Not MediumSlipIsSupported() And Not Form.BaseVersion Then
		ListItem = Items.InventoryValuationMethod.ChoiceList.FindByValue(
						PredefinedValue("Enum.InventoryValuationMethods.MovingAverage"));
		If ListItem <> Undefined Then
			Items.InventoryValuationMethod.ChoiceList.Delete(ListItem);
		EndIf;
	ElsIf Not Form.BaseVersion Then
		ListItem = Items.InventoryValuationMethod.ChoiceList.FindByValue(
						PredefinedValue("Enum.InventoryValuationMethods.MovingAverage"));
		If Not Form.BatchAccountingVersion22
		 Or Form.STSIsApplied
		 Or Form.STSIsAppliedIncomeMinusExpenses Then
			If ListItem <> Undefined Then
				Items.InventoryValuationMethod.ChoiceList.Delete(ListItem);
			EndIf;
		Else
			If ListItem = Undefined Then
				Items.InventoryValuationMethod.ChoiceList.Add(
					PredefinedValue("Enum.InventoryValuationMethods.MovingAverage"));
			EndIf;
		EndIf;
	EndIf;
	
	Items.GroupMakesProvisionsForDoubtfulDebts.Visible = False;
	Items.GroupWarningEvaluationMethod.Visible = Form.STSIsApplied
		And Form.STSIsAppliedIncomeMinusExpenses 
		And Form.BatchAccountingIsEnabled
		And Form.Record.InventoryValuationMethod 
			<> PredefinedValue("Enum.InventoryValuationMethods.FIFORollingValuation");
			
	Items.DrillDownProductCostToInitialCosts.Visible = 
		(Form.SeparateAccountingOfGoodsByVATTaxation
		Or Record.ItemizeMaterialAndItemizedExpensesInInventoryCost)
		And Form.BatchAccountingVersion22;
	
	CostEstimationMethodMediumSlip = (Record.InventoryValuationMethod
		= PredefinedValue("Enum.InventoryValuationMethods.MovingAverage"));
	Items.CostDeviationGroup.Visible = CostEstimationMethodMediumSlip;
	
	Items.OptionOfGoodsCostAccounting.Enabled = Not CostEstimationMethodMediumSlip; 
	
	Items.OptionOfReflectingDeviationsInCostOfProducts.Visible = Record.ProductCostingByPlannedCost
		And Form.BatchAccountingVersion22;
	
	ListItem = Items.OptionOfReflectingDeviationsInCostOfProducts.ChoiceList.FindByValue("IncludeInCost");
	If CostEstimationMethodMediumSlip Then
		ListItem.Presentation = NStr("vi = 'Phân bổ theo hướng thanh lý sản phẩm';
									|ru = 'Распределять по направлениям выбытия продукции';
									|en = 'Allocate to product outflow lines'; fa = 'Allocate to product outflow lines';
									|it = 'Allocate to product outflow lines';
									|pl = 'Allocate to product outflow lines';
									|tr = 'Ürün imhalarını varış yerine göre dağıt'");
	Else
		ListItem.Presentation = NStr("vi = 'Tính vào giá thành (để đạt đến giá thực tế)';
									|ru = 'Включать в стоимость (доводя до фактической)';
									|en = 'Include in cost (bringing to actual cost)'; fa = 'Include in cost (bringing to actual cost)';
									|it = 'Include in cost (bringing to actual cost)';
									|pl = 'Include in cost (bringing to actual cost)';
									|tr = 'Maliyete ekle (güncel hale getir)'");
	EndIf;
	
	Items.OptionOfReflectingReservesForImpairmentOfInventoriesWhenWritingOffInventoriesForExpenses.Visible = Form.BatchAccountingVersion22;
	Items.OptionOfAllocatingExpensesForDisposalsInPastPeriods.Visible = Form.BatchAccountingVersion22;
	
	Form.ReadOnly = (Form.ReadOnly Or Form.BranchOffice);
	
	Items.GroupTheDurationOfTheOperatingCycle.Visible = Form.UseLocal Or Form.UseMFPs;
	Items.FrequencyOfLossAllowance.Enabled = Form.Record.ToGenerateLossAllowance;
	Items.ConfigureProcedureForDebtAssessment.Enabled = Form.Record.ToGenerateLossAllowance;
	
	PropertyValue = 
		Record.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards")
		Or Form.ReadOnly;
	
	Items.RecordingMethodOfFA1Revaluation.ReadOnly = PropertyValue;
	Items.RecordingMethodOfFA2Revaluation.ReadOnly = PropertyValue;
	Items.RecordingMethodOfIA1Revaluation.ReadOnly = PropertyValue;
	Items.RecordingMethodOfIA2Revaluation.ReadOnly = PropertyValue;
	Items.RecordOrderOfDepreciationOfOSSDateOfAcceptanceForAccounting.ReadOnly = PropertyValue;
	Items.RecordOrderOfDepreciationFAFromNextMonth.ReadOnly = PropertyValue;
	Items.RecordProcedureForCalculatingDepreciationLeaseFromDateOfAcceptanceForAccounting.ReadOnly = PropertyValue;
	Items.RecordProcedureForCalculatingDepreciationRentFromNextMonth.ReadOnly = PropertyValue;
	Items.RecordProcedureForCalculatingDepreciationOfNMASDateOfAcceptanceForAccounting.ReadOnly = PropertyValue;
	Items.RecordProcedureForCalculatingDepreciationOfIAFromNextMonth.ReadOnly = PropertyValue;
	
	PropertyValue = 
		Record.FixedAssetAccountingProcedureInLocalAccounting = PredefinedValue("Enum.FixedAssetAccountingProcedureInLocalAccounting.MatchesManagementAccounting")
		Or Record.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards")
		Or Form.ReadOnly;
		
	Items.RecordOrderOfDepreciationFALocalFromDateOfAcceptanceForAccounting.ReadOnly = PropertyValue;
	Items.RecordOrderOfDepreciationFALocalFromNextMonth.ReadOnly = PropertyValue;
	
	Items.RecordProcedureForCalculatingDepreciationLocalLeaseFromDateOfAcceptanceForAccounting.ReadOnly = PropertyValue;
	Items.RecordOrderOfDepreciationLocalRentFromNextMonth.ReadOnly = PropertyValue;

	Items.RecordProcedureForCalculatingDepreciationOfIALocalFromDateOfAcceptanceForAccounting.ReadOnly = PropertyValue;
	Items.RecordProcedureForCalculatingDepreciationOfIALocalFromNextMonth.ReadOnly = PropertyValue;

	If Form.Record.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards") Then
		Items.OptionOfImpairmentTransactions.Enabled = True;
	Else
		Items.OptionOfImpairmentTransactions.Enabled = False;
	EndIf;
	
	Items.GroupMakesProvisionsForDoubtfulDebts.Visible = True;
	
EndProcedure

&AtServer
Procedure UpdateArticleAndAnalyticsSettingsOnServer()
		
	ItemsAndDimensionsSelectionParameters = InformationRegisters.FinancialAccountingPolicy.ItemsAndDimensionsSelectionParameters(
		Record.RecognizeResearchExpensesInCurrentPeriod,
		Record.AccountingForDiscountedAccountsPayableToVendors,
		Record.AccountForDiscountingOfProvisionsAndContingentLiabilities,
		Record.AccountingForRentAccordingToFSB252018 And TransferToRentalSubleaseBasedOnRussianGAAPFSBU25);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Function CheckedRegisterFields()
	
	ListOfFieldsToCheck = New ValueList;
	
	RegisterMetadata = Metadata.InformationRegisters.FinancialAccountingPolicy;

	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.ExpenseItemForRD.Name,
		RegisterMetadata.Resources.ExpenseItemForRD.Synonym);

	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.ExpensesDimensionResearchExpenses.Name,
		RegisterMetadata.Resources.ExpensesDimensionResearchExpenses.Synonym);
	
	If Record.DivisionIntoShortTermLongTermAssetsAndLiabilities Then
		ListOfFieldsToCheck.Add(
			RegisterMetadata.Resources.DurationOfCompanyOperatingCycle.Name,
			RegisterMetadata.Resources.DurationOfCompanyOperatingCycle.Synonym);
	EndIf;
	
	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.WriteOffsDimensionOfInterestExpense.Name,
		RegisterMetadata.Resources.WriteOffsDimensionOfInterestExpense.Synonym);
	
	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.InterestExpenseWriteOffItem.Name,
		RegisterMetadata.Resources.InterestExpenseWriteOffItem.Synonym);
	
	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting.Name,
		RegisterMetadata.Resources.AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting.Synonym);
	
	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.ItemOfInterestExpenseWriteOffOfProvisionDiscounting.Name,
		RegisterMetadata.Resources.ItemOfInterestExpenseWriteOffOfProvisionDiscounting.Synonym);
	
	ListOfFieldsToCheck.Add(
		RegisterMetadata.Resources.MonthOfFiscalYearBeginning.Name,
		RegisterMetadata.Resources.MonthOfFiscalYearBeginning.Synonym);
	
	Return ListOfFieldsToCheck;
	
EndFunction

&AtServer
Procedure CreateLabelDiscountRate()
	
	If ValuesOfDiscountRates.Count() Then 
		DiscountRate = NStr("vi = 'Tỷ lệ tính chiết khấu';
							|ru = 'Ставки дисконтирования';
							|en = 'Discounting rates'; fa = 'نرخ‌های تنزیل';
							|it = 'Aliquote di sconto';
							|pl = 'Stawki dyskontowania';
							|tr = 'İskonto oranları'");
	Else
		DiscountRate = NStr("vi = 'Chưa chỉ ra tỷ lệ';
							|ru = 'Ставки не указаны';
							|en = 'Rates are not specified'; fa = 'Rates are not specified';
							|it = 'Aliquote non indicate';
							|pl = 'Stawki nie są podane';
							|tr = 'Oranlar belirtilmedi'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenDiscountRates()
	
	OpeningParameters = New Structure();
	OpeningParameters.Insert("Period", ChangeDate);
	OpeningParameters.Insert("Organization", Record.Organization);
	OpeningParameters.Insert("ValuesOfDiscountRates", New Array);
	
	For Each BidLine In ValuesOfDiscountRates Do
		NewRow = New Structure("Currency, DiscountRate");
		FillPropertyValues(NewRow, BidLine);
		OpeningParameters.ValuesOfDiscountRates.Add(NewRow);
	EndDo;
	
	OpenForm("InformationRegister.DiscountRates.Form.EditDiscountRates", 
		OpeningParameters, 
		ThisObject,,,,, 
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure SetAvailabilityOfDiscountDetails()
	
	Items.GroupDiscountingVertical.Visible = Not BaseVersion;
	Items.RecordAccountingForDiscountedAccountsPayableToVendors.Enabled = NewOnlineARAPAccounting;
	AvailableDetailsForDiscounting = Record.AccountingForDiscountedAccountsPayableToVendors And NewOnlineARAPAccounting;
	Items.DiscountRate.Enabled = AvailableDetailsForDiscounting;
	If Not AvailableDetailsForDiscounting Then
		Items.DiscountRate.Visible = ValuesOfDiscountRates.Count() > 0;
	Else
		Items.DiscountRate.Visible = True;
	EndIf;
	If NewOnlineARAPAccounting Then 
		Items.GroupDiscountingVertical.ToolTipRepresentation = ToolTipRepresentation.None;
	Else 
		Items.GroupDiscountingVertical.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	Items.RecordApplicationDiscountingPeriod.Enabled = AvailableDetailsForDiscounting;
	Items.DaysDecoration.Enabled = AvailableDetailsForDiscounting;
	
EndProcedure 

&AtServer
Procedure ReadDiscountRates()
	
	ValuesOfDiscountRates.Clear();
	
	Selection = InformationRegisters.DiscountRates.Select(
		Record.Period, 
		Record.Period, 
		New Structure("Organization", Record.Organization));
	
	While Selection.Next() Do
		NewRow = ValuesOfDiscountRates.Add();
		FillPropertyValues(NewRow, Selection);
	EndDo;
	
	Try
		For Each BidLine In ValuesOfDiscountRates Do
			Filter = New Structure;
			Filter.Insert("Period", Record.Period);
			Filter.Insert("Organization", Record.Organization);
			Filter.Insert("Currency", BidLine.Currency);
			RecordKey = InformationRegisters.DiscountRates.CreateRecordKey(Filter);
			LockDataForEdit(RecordKey,, UUID);
		EndDo;
	Except
		
		ErrorText = NStr("vi = 'Không thể phong tỏa tỷ lệ tính chiết khấu. %ErrorDescription%';
						|ru = 'Не удалось заблокировать ставки дисконтирования. %ErrorDescription%';
						|en = 'Cannot lock the discounting rates. %ErrorDescription%'; fa = 'Cannot lock the discounting rates. %ErrorDescription%';
						|it = 'Non è stato possibile bloccare le aliquote di sconto. %ErrorDescription%';
						|pl = 'Nie udało się zablokować stawek dyskontowania. %ErrorDescription%';
						|tr = 'İndirim oranları kilitlenemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		Common.MessageToUser(ErrorText);
		Raise ErrorText;
		
	EndTry;
	
	CreateLabelDiscountRate();
	
EndProcedure

&AtServer
Procedure RecordDiscountRates()
	
	If Record.Period <> ChangeDate Then
		RecordSet = InformationRegisters.DiscountRates.CreateRecordSet();
		RecordSet.Filter.Period.Set(Record.Period);
		RecordSet.Filter.Organization.Set(Record.Organization);
		RecordSet.Write();
	EndIf;
	
	RecordSet = InformationRegisters.DiscountRates.CreateRecordSet();
	RecordSet.Filter.Period.Set(ChangeDate); 
	RecordSet.Filter.Organization.Set(Record.Organization);
	
	For Each BidLine In ValuesOfDiscountRates Do
		NewRecord = RecordSet.Add();
		NewRecord.Period 					= ChangeDate;
		NewRecord.Organization 			= Record.Organization;
		NewRecord.Currency 					= BidLine.Currency;
		NewRecord.DiscountRate 	= BidLine.DiscountRate;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

&AtServer	
Procedure ManagingCostDetailSettings()
	
	LotAccountingOfVersion22IsBeingConducted = CalculationOfCostCached.BatchAccountingVersion22(Record.Period);
			
	If Record.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation Then
		Items.ItemizeMaterialAndItemizedExpensesInInventoryCost.Enabled = True;
		Items.DoNotBreakDownToReceiptDocuments.Enabled = True;
		Items.DrillDownProductCostToInitialCosts.Enabled = False;
		Record.DrillDownProductCostToInitialCosts = LotAccountingOfVersion22IsBeingConducted;
	Else
		Items.ItemizeMaterialAndItemizedExpensesInInventoryCost.Enabled = False;
		Items.DrillDownProductCostToInitialCosts.Enabled = LotAccountingOfVersion22IsBeingConducted;
		If Not LotAccountingOfVersion22IsBeingConducted Then
			Record.DrillDownProductCostToInitialCosts = False;
		EndIf;
		Items.DoNotBreakDownToReceiptDocuments.Enabled = False;
		
		If Record.ItemizeMaterialAndItemizedExpensesInInventoryCost Then
			Record.ItemizeMaterialAndItemizedExpensesInInventoryCost = False;
		EndIf;
		
		If Record.DoNotBreakDownToReceiptDocuments Then
			Record.DoNotBreakDownToReceiptDocuments = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureProcedureForDebtAssessmentResultProcessing(Result, AdditionalParameters) Export
	If Result = True Then
		Modified = True;
	EndIf;
EndProcedure

&AtServer
Procedure ConfigureNonCurrentAssetsWhenCreatingForm()
	
	VNASettingIsAvailable = False;
	LocalFAAccounting = False;
	VNASettingIsAvailable = GetFunctionalOption("UseNonCurrentAssets2_4");
	LocalFAAccounting = GetFunctionalOption("LocalFAAccounting");
	If VNASettingIsAvailable Then
		
		If LocalFAAccounting Then
			
			Items.DecorationFAAccountingProcedureLocal.Visible = False;
			Items.RecordFALocalAccountingProcedureCoincidesWithLocalAccounting.Visible = False;
			Items.RecordFALocalAccountingProcedureIndependent.Visible = False;
			
			Items.DecorationProcedureForCalculatingDepreciationFALocal.Visible = False;
			Items.RecordOrderOfDepreciationFALocalFromDateOfAcceptanceForAccounting.Visible = False;
			Items.RecordOrderOfDepreciationFALocalFromNextMonth.Visible = False;
			
			Items.DecorationDepreciationCalculationProcedureLocalLease.Visible = False;
			Items.RecordProcedureForCalculatingDepreciationLocalLeaseFromDateOfAcceptanceForAccounting.Visible = False;
			Items.RecordOrderOfDepreciationLocalRentFromNextMonth.Visible = False;
			
			Items.DecorationIADepreciationProcedureLocal.Visible = False;
			Items.RecordProcedureForCalculatingDepreciationOfIALocalFromDateOfAcceptanceForAccounting.Visible = False;
			Items.RecordProcedureForCalculatingDepreciationOfIALocalFromNextMonth.Visible = False;
			
		Else
			
			Items.DecorationOrderOfAccountingOfVNA.Visible = False;
			Items.RecordTheOrderOfAccountingInAccordanceWithTheStandardsOfMU.Visible = False;
			Items.EntryAccountingProcedureInAccordanceWithTheReglStandards.Visible = False;
			Items.IndentationIsMethodOfFAReevaluation.Visible = False;
			Items.IndentationMethodOfRevaluationOfIA.Visible = False;
			
		EndIf;
		
	Else
		
		Items.DecorationOrderOfAccountingOfVNA.Visible = False;
		Items.RecordTheOrderOfAccountingInAccordanceWithTheStandardsOfMU.Visible = False;
		Items.EntryAccountingProcedureInAccordanceWithTheReglStandards.Visible = False;
		
		Items.DecorationProcedureForCalculatingDepreciationFA.Visible = False;
		Items.RecordOrderOfDepreciationOfOSSDateOfAcceptanceForAccounting.Visible = False;
		Items.RecordOrderOfDepreciationFAFromNextMonth.Visible = False;
		
		Items.DecorationIADepreciationCalculationProcedure.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationOfNMASDateOfAcceptanceForAccounting.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationOfIAFromNextMonth.Visible = False;
		
		Items.DecorationFAAccountingProcedureLocal.Visible = False;
		Items.RecordFALocalAccountingProcedureCoincidesWithLocalAccounting.Visible = False;
		Items.RecordFALocalAccountingProcedureIndependent.Visible = False;
		
		Items.DecorationProcedureForCalculatingDepreciationFALocal.Visible = False;
		Items.RecordOrderOfDepreciationFALocalFromDateOfAcceptanceForAccounting.Visible = False;
		Items.RecordOrderOfDepreciationFALocalFromNextMonth.Visible = False;
		
		Items.DecorationDepreciationCalculationProcedureRent.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationLeaseFromDateOfAcceptanceForAccounting.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationRentFromNextMonth.Visible = False;

		Items.DecorationDepreciationCalculationProcedureLocalLease.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationLocalLeaseFromDateOfAcceptanceForAccounting.Visible = False;
		Items.RecordOrderOfDepreciationLocalRentFromNextMonth.Visible = False;
		
		Items.DecorationIADepreciationProcedureLocal.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationOfIALocalFromDateOfAcceptanceForAccounting.Visible = False;
		Items.RecordProcedureForCalculatingDepreciationOfIALocalFromNextMonth.Visible = False;

		Items.OptionOfImpairmentTransactions.Visible = False;
		Items.RecordAccountingForRentAccordingToFSB252018.Visible = False;

		Items.DecorationIndentFinRent.Visible = False;
		Items.RecordInterestIncomeItemOfFinancialLease.Visible = False;
		Items.RecordInterestIncomeDimensionOfFinancialLease.Visible = False;
		Items.RecordIncomeItemForFinancialLeaseServices.Visible = False;
		Items.RecordIncomeDimensionForFinancialLeaseServices.Visible = False;

		Items.IndentationIsMethodOfFAReevaluation.Visible = False;
		Items.IndentationMethodOfRevaluationOfIA.Visible = False;
		
	EndIf;
	
	ImpairmentIncluded = False;
	
	ImpairmentIncluded = 
		GetFunctionalOption("UseNonCurrentAssets2_4")
		 And GetFunctionalOption("UseFixedAssetImpairment");
	If Not ImpairmentIncluded Then
		Items.OptionOfImpairmentTransactions.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function MediumSlipIsSupported()
	Return True;
EndFunction
 
&AtServerNoContext
Function AllocateARAPInBackgroundJob()
	SetPrivilegedMode(True);
	Return Constants.AllocateARAPInBackgroundJob.Get();
EndFunction
 
#EndRegion
