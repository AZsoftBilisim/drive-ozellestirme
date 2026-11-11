#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If Parameters.Property("GetData") Then
		ScheduleParameters = GetScheduleData();
	Else
		ScheduleParameters = Parameters;
	EndIf;
	
	HasSecurityDeposit = ScheduleParameters.FormServiceParameters.ContractDetails_.HasSecurityDeposit;
	ThereIsBuyoutOfLeasedAssets = ScheduleParameters.FormServiceParameters.ContractDetails_.ThereIsBuyoutOfLeasedAssets;
	WithoutDiscounting = 
		(ScheduleParameters.FormServiceParameters.ContractDetails_.MethodForDeterminingCostOfAssets = 
			Enums.MethodsOfDeterminingLeasedAssetCost.ByContractAmount);
	InterestRate = ScheduleParameters.InterestRate;
	PresentValue = ScheduleParameters.PresentValue;
	AmountOfLeaseAssetsByuout = ScheduleParameters.AmountOfLeaseAssetsByuout;
	AmountOfVATRepurchaseOfRentalItems = ScheduleParameters.AmountOfVATRepurchaseOfRentalItems;
	DocumentCurrencyPresentation = ScheduleParameters.DocumentCurrencyPresentation;
	TheInterestAccrualScheduleIsEnteredManually = ScheduleParameters.TheInterestAccrualScheduleIsEnteredManually;
	VATRate = ScheduleParameters.VATRate;
	LeaseStartDate = ScheduleParameters.LeaseStartDate;
	DateOfLeaseChange = ScheduleParameters.DateOfLeaseChange;
	Contract = ScheduleParameters.Contract;
	
	If ScheduleParameters.Property("ReadOnly") 
		And ScheduleParameters.ReadOnly Then
		ReadOnly = True;
		Items.MoveToDocument.Enabled = False;
	EndIf;

	ContractSchedules = GetFromTempStorage(ScheduleParameters.ContractSchedules);

	ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);

	If Parameters.ChartName = "ServiceAccrualSchedule" Then
		Items.GraphicsPages.CurrentPage = Items.PageScheduleOfCharges;
	ElsIf Parameters.ChartName = "InterestAccrualSchedule" Then
		Items.GraphicsPages.CurrentPage = Items.PercentageChartPage;
	Else
		Items.GraphicsPages.CurrentPage = Items.PaymentSchedulePage;
	EndIf;

	If Not ScheduleParameters.FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Or WithoutDiscounting Then
		Items.InterestAccrualSchedule.Visible = False;
		Items.TheInterestAccrualScheduleIsEnteredManually.Visible = False;
	EndIf;
	
	If Not HasSecurityDeposit Then
		
		Items.ServicePaymentScheduleDepositPayment.Visible = False;
		Items.ServicePaymentScheduleSecurityPaymentVATAmount.Visible = False;
		Items.ServiceAccrualScheduleDepositPayment.Visible = False;
		Items.ServiceAccrualScheduleSecurityPaymentVATAmount.Visible = False;
		
		Items.Payment_DepositPayment_InTotal.Visible = False;
		Items.PaymentSecurityPaymentTotalCurrency.Visible = False;
		Items.Accrual_DepositPayment_InTotal.Visible = False;
		Items.AccrualSecurityPaymentTotalCurrency.Visible = False;
		
	EndIf;
	
	If Not ThereIsBuyoutOfLeasedAssets Then
		
		Items.ServicePaymentScheduleBuyoutValue.Visible = False;
		Items.ServicePaymentScheduleBuyoutValueVAT.Visible = False;
		
		Items.PaymentOfTheRedemptionValueTotal.Visible = False;
		Items.PaymentPurchasePriceTotalCurrency.Visible = False;
		Items.TheCalculationOfTheRedemptionValueTotal.Visible = False;
		Items.TheCalculationOfTheRedemptionValueTotalCurrency.Visible = False;
		
	EndIf;
	
	If Not HasSecurityDeposit And Not ThereIsBuyoutOfLeasedAssets Then
		Items.ServicePaymentScheduleRentalService.AutoMarkIncomplete = True;
		Items.ServiceAccrualScheduleRentalService.AutoMarkIncomplete = True;
	EndIf;

	If VATAccountingERP.InsignificantRate(VATRate)
		Or Not ValueIsFilled(VATRate) Then
		
		Items.ServicePaymentScheduleRentalServiceVAT.Visible = False;
		Items.ServicePaymentScheduleSecurityPaymentVATAmount.Visible = False;
		Items.ServicePaymentScheduleBuyoutValueVAT.Visible = False;
		
		Items.ServiceAccrualScheduleRentalServiceVAT.Visible = False;
		Items.ServiceAccrualScheduleSecurityPaymentVATAmount.Visible = False;
		
		Items.Payment_NDS_Total.Visible = False;
		Items.Payment_NDS_TotalCurrency.Visible = False;
		Items.Accrual_NDS_Total.Visible = False;
		Items.Accrual_NDS_TotalCurrency.Visible = False;
		
	EndIf;
	
	If Not ValueIsFilled(DateOfLeaseChange) Then
		Items.FillIn_PaymentScheduleAccordingToPreviousConditions.Visible = False;
		Items.FillIn_AccrualScheduleAccordingToPreviousConditions.Visible = False;
	Else
		Items.ServicePaymentScheduleDepositPayment.ReadOnly = True;
		Items.ServicePaymentScheduleSecurityPaymentVATAmount.ReadOnly = True;
	EndIf;
	
	// Hiding a group of columns and changing the header
	If Not Items.ServicePaymentScheduleRentalServiceVAT.Visible Then
		Items.ScheduleOfPaymentsForServicesGroupRentalServices.ShowInHeader = False;
		Items.ServicePaymentScheduleRentalService.Title = NStr("vi = 'Số tiền dịch vụ thuê';
																|ru = 'Сумма услуги по аренде';
																|en = 'Rental service amount'; fa = 'Rental service amount';
																|it = 'Importo servizio di affitto';
																|pl = 'Wartość usługi dot. dzierżawy';
																|tr = 'Kiralama hizmetlerinin tutarı'");
	EndIf;
	
	If Not Items.ServicePaymentScheduleSecurityPaymentVATAmount.Visible Then
		Items.ScheduleOfPaymentsForServicesGroupSecurityPayment.ShowInHeader = False;
		Items.ServicePaymentScheduleDepositPayment.Title = NStr("vi = 'Số tiền thanh toán đảm bảo';
																|ru = 'Сумма обеспечительного платежа';
																|en = 'Security deposit amount'; fa = 'مبلغ سپرده تضمین';
																|it = 'Importo del deposito cauzionale';
																|pl = 'Wartość płatności zabezpieczającej';
																|tr = 'Teminat miktarı'");
	EndIf;
	
	If Not Items.ServicePaymentScheduleBuyoutValueVAT.Visible Then
		Items.ScheduleOfPaymentsForServicesGroupRedemptionValue.ShowInHeader = False;
		Items.ServicePaymentScheduleBuyoutValue.Title = NStr("vi = 'Số tiền mua lại';
															|ru = 'Сумма выкупной стоимости';
															|en = 'Buyout value amount'; fa = 'Buyout value amount';
															|it = 'Importo valore di rimborso';
															|pl = 'Kwota w wartości wykupu';
															|tr = 'İtfa değerinin tutarı'");
	EndIf;
	
	If Not Items.ServiceAccrualScheduleRentalServiceVAT.Visible Then
		Items.ScheduleOfAccrualOfServicesGroupRentalServices.ShowInHeader = False;
		Items.ServiceAccrualScheduleRentalService.Title = NStr("vi = 'Số tiền dịch vụ thuê theo từng khoản thanh toán thuê';
																|ru = 'Сумма услуги по аренде в части арендного платежа';
																|en = 'Rental service amount in part of rental payment'; fa = 'Rental service amount in part of rental payment';
																|it = 'Importo del servizio di affitto in qualità di pagamento affitto';
																|pl = 'Kwota usługi dot. dzierżawy w części płatności za wynajem';
																|tr = 'Kira ödemeleri kapsamında kiralama hizmeti tutarı'");
	EndIf;
	
	If Not Items.ServiceAccrualScheduleSecurityPaymentVATAmount.Visible Then
		Items.ScheduleOfAccrualOfServicesGroupSecurityPayment.ShowInHeader = False;
		Items.ServiceAccrualScheduleDepositPayment.Title = NStr("vi = 'Số tiền dịch vụ thuê trong phần khấu trừ khoản thanh toán đảm bảo';
																|ru = 'Сумма услуги по аренде в части зачета обеспечительного платежа';
																|en = 'Rental service amount in part of security deposit offset'; fa = 'Rental service amount in part of security deposit offset';
																|it = 'Importo del servizio di affitto in qualità di compensazione del pagamento cauzionale';
																|pl = 'Wartość usługa dotycząca dzierżawy w części zaliczania płatności zabezpieczającej';
																|tr = 'Depozitonun mahsubuna ilişkin kira hizmeti tutarı'");
	EndIf;
	
	If Not HasSecurityDeposit Then
		Items.ScheduleOfAccrualOfServicesGroupRentalServices.Title = NStr("vi = 'Dịch vụ thuê';
																			|ru = 'Услуга по аренде';
																			|en = 'Rental service'; fa = 'خدمات اجاره';
																			|it = 'Servizio relativo all''affitto';
																			|pl = 'Usługa dotycząca dzierżawy';
																			|tr = 'Kiralama hizmeti'");
	EndIf;
	
	Title = StrTemplate(NStr("vi = 'Lịch biểu thanh toán và tính lãi theo hợp đồng ""%1""';
							|ru = 'График оплат и начислений по договору ""%1""';
							|en = 'Schedule of payments and charges under contract ""%1""'; fa = 'Schedule of payments and charges under contract ""%1""';
							|it = 'Grafico dei pagamenti e maturazioni in base all''accordo ""%1""';
							|pl = 'Harmonogram płatności i naliczeń w ramach umowy ""%1""';
							|tr = 'Sözleşme kapsamındaki ödemeler ve tahakkuklar çizelgesi ''''%1'''''"), String(Parameters.Contract));
	
	UpdateBasementOfServicePaymentSchedule(ThisObject);
	UpdateBasementOfServiceAccrualSchedule(ThisObject);
	UpdateTotals(ThisObject);

	ConfigureDependentFormElementsOnClientOnServer(ThisObject);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ShowFormClosingConfirmationCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	LeasedAssetAccounting.CheckSchedule(
		ServicePaymentSchedule, 
		"ServicePaymentSchedule", 
		"RentalService,DepositPayment,BuyoutValue", 
		Cancel);
		
	LeasedAssetAccounting.CheckSchedule(
		ServiceAccrualSchedule, 
		"ServiceAccrualSchedule", 
		"RentalService,DepositPayment", 
		Cancel);

	LeasedAssetAccounting.CheckSchedule(
		InterestAccrualSchedule, 
		"InterestAccrualSchedule", 
		"Interests", 
		Cancel);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheInterestAccrualScheduleIsEnteredManuallyOnChange(Item)

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServicePaymentSchedule

&AtClient
Procedure ServicePaymentScheduleOnChange(Item)
	
	UpdateBasementOfServicePaymentSchedule(ThisObject);
	UpdateTotals(ThisObject);

EndProcedure

&AtClient
Procedure ServicePaymentScheduleRentalServiceOnChange(Item)
	
	CurrentData = Items.ServicePaymentSchedule.CurrentData;
	CurrentData.RentalServiceVAT = CalculateVATAmount(CurrentData.RentalService);
	
EndProcedure

&AtClient
Procedure ServicePaymentScheduleDepositPaymentOnChange(Item)
	
	CurrentData = Items.ServicePaymentSchedule.CurrentData;
	CurrentData.SecurityPaymentVATAmount = CalculateVATAmount(CurrentData.DepositPayment);

EndProcedure

&AtClient
Procedure ServicePaymentScheduleBuyoutValueOnChange(Item)
	
	CurrentData = Items.ServicePaymentSchedule.CurrentData;
	CurrentData.BuyoutValueVAT = CalculateVATAmount(CurrentData.BuyoutValue);

EndProcedure

&AtClient
Procedure ServicePaymentScheduleBeforeDeleteRow(Item, Cancel)

	ScheduleBeforeDeletion(Item, Cancel);

EndProcedure

&AtClient
Procedure ServicePaymentScheduleDateOnChange(Item)
	
	WhenScheduleDateChanges("ServicePaymentSchedule");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServiceAccrualSchedule

&AtClient
Procedure ServiceAccrualScheduleOnChange(Item)
	
	UpdateBasementOfServiceAccrualSchedule(ThisObject);
	UpdateTotals(ThisObject);

EndProcedure

&AtClient
Procedure ServiceAccrualScheduleRentalServiceOnChange(Item)
	
	CurrentData = Items.ServiceAccrualSchedule.CurrentData;
	CurrentData.RentalServiceVAT = CalculateVATAmount(CurrentData.RentalService);

EndProcedure

&AtClient
Procedure ServiceAccrualScheduleDepositPaymentOnChange(Item)
	
	CurrentData = Items.ServiceAccrualSchedule.CurrentData;
	CurrentData.SecurityPaymentVATAmount = CalculateVATAmount(CurrentData.DepositPayment);

EndProcedure

&AtClient
Procedure ServiceAccrualScheduleBeforeDeleteRow(Item, Cancel)

	ScheduleBeforeDeletion(Item, Cancel);

EndProcedure

&AtClient
Procedure ServiceAccrualScheduleDateOnChange(Item)
	
	WhenScheduleDateChanges("ServiceAccrualSchedule");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInterestAccrualSchedule

&AtClient
Procedure InterestAccrualScheduleBeforeDeleteRow(Item, Cancel)
	
	ScheduleBeforeDeletion(Item, Cancel);

EndProcedure

&AtClient
Procedure InterestAccrualScheduleDateOnChange(Item)
	
	WhenScheduleDateChanges("InterestAccrualSchedule");
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	CompleteEditing();

EndProcedure

&AtClient
Procedure ImportSchedulePaymentSchedule(Command)
	
	ImportChart("ServicePaymentSchedule");

EndProcedure

&AtClient
Procedure ImportScheduleAccrualSchedule(Command)
	
	ImportChart("ServiceAccrualSchedule");

EndProcedure

&AtClient
Procedure DownloadAGraphAGraphOfPercentages(Command)
	
	ImportChart("InterestAccrualSchedule");

EndProcedure

&AtClient
Procedure FillInAmounts_PaymentSchedule(Command)
	
	FillInAmountsInChart("ServicePaymentSchedule");
	
EndProcedure

&AtClient
Procedure FillInAmounts_AccrualSchedule(Command)
	
	FillInAmountsInChart("ServiceAccrualSchedule");
	
EndProcedure

&AtClient
Procedure FillIn_AccrualScheduleAccordingToPreviousConditions(Command)
	
	FillInPreviousConditions("ServiceAccrualSchedule");
	
EndProcedure

&AtClient
Procedure FillIn_PaymentScheduleAccordingToPreviousConditions(Command)
	
	FillInPreviousConditions("ServicePaymentSchedule");
	
EndProcedure
#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	#Region RentalService
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentForServicesRentalTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualRentalServiceTotal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentForServicesRentalTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AccrualRentalServiceTotal");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion
	
	#Region DepositPayment
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Payment_DepositPayment_InTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Accrual_DepositPayment_InTotal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Payment_DepositPayment_InTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Accrual_DepositPayment_InTotal");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion
	
	#Region BuyoutValue
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentOfTheRedemptionValueTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheCalculationOfTheRedemptionValueTotal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Payment_RedemptionCost_AfterChanges");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AmountOfLeaseAssetsByuout");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion

	#Region VAT
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Payment_NDS_Total.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Accrual_NDS_Total.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Payment_NDS_Total");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Accrual_NDS_Total");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion
	
	#Region PaymentSchedule
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicePaymentSchedule.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicePaymentSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("DateOfLeaseChange");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicePaymentSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region ScheduleOfAccruals
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServiceAccrualSchedule.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServiceAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("DateOfLeaseChange");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServiceAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region InterestGraph
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InterestAccrualSchedule.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InterestAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("DateOfLeaseChange");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InterestAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
EndProcedure

&AtClient
Procedure ImportChart(ChartName)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartName", ChartName);
	FormParameters.Insert("UniqueOwnerID", UUID);
	FormParameters.Insert("HasSecurityDeposit", HasSecurityDeposit);
	FormParameters.Insert("ThereIsBuyoutOfLeasedAssets", ChartName = "ServicePaymentSchedule" And ThereIsBuyoutOfLeasedAssets);
	
	OpenForm("Catalog.LeaseContract.Form.ImportingPaymentsAndAccrualsSchedule",
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("ImportChartCompletion", ThisObject, ChartName),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ImportChartCompletion(ClosingResult, ChartName) Export
	
	If TypeOf(ClosingResult) = Type("String") 
		And IsTempStorageURL(ClosingResult) Then
			
		UploadCompletionScheduleToServer(ClosingResult, ChartName);
	EndIf;

EndProcedure

&AtServer
Procedure UploadCompletionScheduleToServer(Val ResultAddress, Val ChartName)
	
	ChartTable = GetFromTempStorage(ResultAddress);
	
	If ChartName = "ServicePaymentSchedule" Then
		DestinationTable = ServicePaymentSchedule;
	ElsIf ChartName = "ServiceAccrualSchedule" Then
		DestinationTable = ServiceAccrualSchedule;
	ElsIf ChartName = "InterestAccrualSchedule" Then
		DestinationTable = InterestAccrualSchedule;
	EndIf;

	DestinationTable.Load(ChartTable);
	DestinationTable.Sort("Date");
	
	If ValueIsFilled(DateOfLeaseChange) Then
		FillInPreviousConditionsOnServer(ChartName, False, False);
	EndIf;
	
	LeasedAssetAccounting.FillInAmountsOfNDSInGraphs(ServicePaymentSchedule, ServiceAccrualSchedule, VATRate, DateOfLeaseChange);
	
	If ChartName = "ServicePaymentSchedule" Then
		UpdateBasementOfServicePaymentSchedule(ThisObject);
	ElsIf ChartName = "ServiceAccrualSchedule" Then
		UpdateBasementOfServiceAccrualSchedule(ThisObject);
	EndIf;

	UpdateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ShowFormClosingConfirmationCompletion(Result, AdditionalParameters) Export
	
	CompleteEditing();
	
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

	Modified = False;

	Close(PutChartsInStorage());
	
EndProcedure

&AtServer
Function PutChartsInStorage()
	
	ServiceAccrualSchedule.Sort("Date");
	ServicePaymentSchedule.Sort("Date");
	InterestAccrualSchedule.Sort("Date");

	ContractSchedules = New Structure;
	ContractSchedules.Insert("TheInterestAccrualScheduleIsEnteredManually", TheInterestAccrualScheduleIsEnteredManually);
	ContractSchedules.Insert("ServiceAccrualSchedule", ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", InterestAccrualSchedule.Unload());
	
	InterestAmount = 0;
	For Each LinePercentages In InterestAccrualSchedule Do
		If LinePercentages.Date < DateOfLeaseChange Then
			Continue;
		EndIf;
		InterestAmount = InterestAmount + LinePercentages.Interests;
	EndDo;
	ContractSchedules.Insert("InterestAmount", InterestAmount);
	
	Return PutToTempStorage(ContractSchedules, UUID);
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateBasementOfServicePaymentSchedule(Form)
	
	StartDate = ?(ValueIsFilled(Form.DateOfLeaseChange), Form.DateOfLeaseChange, Form.LeaseStartDate);
	ScheduleParameters = LeasedAssetAccountingClientServer.ServicePaymentScheduleParameters(Form.ServicePaymentSchedule, StartDate);
	
	Form.Items.DecorationServicePaymentScheduleBasement.Title = 
		StrTemplate(NStr("vi = 'Tính định kỳ: %1';
						|ru = 'Периодичность: %1';
						|en = 'Frequency: %1'; fa = 'Frequency: %1';
						|it = 'Periodicità: %1';
						|pl = 'Częstotliwość: %1';
						|tr = 'Sıklık: %1'"), ScheduleParameters.Periodicity);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateBasementOfServiceAccrualSchedule(Form)
	
	StartDate = ?(ValueIsFilled(Form.DateOfLeaseChange), Form.DateOfLeaseChange, Form.LeaseStartDate);
	ScheduleParameters = LeasedAssetAccountingClientServer.ParametersOfServiceAccrualSchedule(
							Form.ServiceAccrualSchedule, Form.AmountOfVATRepurchaseOfRentalItems, StartDate);
	
	Form.Items.DecorationScheduleOfAccrualOfServices.Title = 
		StrTemplate(NStr("vi = 'Tính định kỳ: %1';
						|ru = 'Периодичность: %1';
						|en = 'Frequency: %1'; fa = 'Frequency: %1';
						|it = 'Periodicità: %1';
						|pl = 'Częstotliwość: %1';
						|tr = 'Sıklık: %1'"), ScheduleParameters.Periodicity);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTotals(Form)
	
	// Results according to the accrual schedule
	AccrualOfRentalServiceAfterChanges = 0;
	AccrualSecurityPaymentAfterChanges = 0;
	AccrualOfVATRentalServiceAfterChanges = 0;
	AccrualOfSecurityPaymentOfVATAfterChanges = 0;
	AccrualSecurityPaymentBeforeChanges = 0;
	AccrualSecurityPaymentOfVATBeforeChanges = 0;

	For Each PlotLine In Form.ServiceAccrualSchedule Do

		If PlotLine.Date >= Form.DateOfLeaseChange Then
			AccrualOfRentalServiceAfterChanges = AccrualOfRentalServiceAfterChanges + PlotLine.RentalService;
			AccrualSecurityPaymentAfterChanges = AccrualSecurityPaymentAfterChanges + PlotLine.DepositPayment;
			AccrualOfVATRentalServiceAfterChanges = AccrualOfVATRentalServiceAfterChanges + PlotLine.RentalServiceVAT;
			AccrualOfSecurityPaymentOfVATAfterChanges = AccrualOfSecurityPaymentOfVATAfterChanges + PlotLine.SecurityPaymentVATAmount;
		Else
			AccrualSecurityPaymentBeforeChanges = AccrualSecurityPaymentBeforeChanges + PlotLine.DepositPayment;
			AccrualSecurityPaymentOfVATBeforeChanges = AccrualSecurityPaymentOfVATBeforeChanges + PlotLine.SecurityPaymentVATAmount;
		EndIf;

	EndDo;

	Form.Accrual_RentalService_AfterChanges = AccrualOfRentalServiceAfterChanges;
	Form.Accrual_SecurityPayment_AfterChanges = AccrualSecurityPaymentAfterChanges;

	Form.AccrualOf_NDS_AfterChanges =
	+ Form.AmountOfVATRepurchaseOfRentalItems
	+ AccrualOfVATRentalServiceAfterChanges
	+ AccrualOfSecurityPaymentOfVATAfterChanges;

	// Results on the payment schedule
	PaymentRentalServiceAfterChanges = 0;
	PaymentSecurityPaymentAfterChanges = 0;
	PaymentRedemptionCostAfterChanges = 0;
	PaymentRentalServiceVATAfterChanges = 0;
	PaymentSecurityPaymentOfVATAfterChanges = 0;
	PaymentRedemptionCostOfVATAfterChanges = 0;

	For Each PlotLine In Form.ServicePaymentSchedule Do

		If PlotLine.Date >= Form.DateOfLeaseChange Then
			PaymentRentalServiceAfterChanges = PaymentRentalServiceAfterChanges + PlotLine.RentalService;
			PaymentRedemptionCostAfterChanges = PaymentRedemptionCostAfterChanges + PlotLine.BuyoutValue;
			PaymentRentalServiceVATAfterChanges = PaymentRentalServiceVATAfterChanges + PlotLine.RentalServiceVAT;
			PaymentRedemptionCostOfVATAfterChanges = PaymentRedemptionCostOfVATAfterChanges + PlotLine.BuyoutValueVAT;
		EndIf; 
		PaymentSecurityPaymentAfterChanges = PaymentSecurityPaymentAfterChanges + PlotLine.DepositPayment;
		PaymentSecurityPaymentOfVATAfterChanges = PaymentSecurityPaymentOfVATAfterChanges + PlotLine.SecurityPaymentVATAmount;

	EndDo;

	Form.Payment_RentalService_AfterChanges = PaymentRentalServiceAfterChanges;
	Form.Payment_SecurityPayment_AfterChanges = PaymentSecurityPaymentAfterChanges - AccrualSecurityPaymentBeforeChanges;
	Form.Payment_RedemptionCost_AfterChanges = PaymentRedemptionCostAfterChanges;

	Form.Payment_VAT_AfterChanges = 
	PaymentRentalServiceVATAfterChanges
	+ PaymentSecurityPaymentOfVATAfterChanges
	+ PaymentRedemptionCostOfVATAfterChanges
	- AccrualSecurityPaymentOfVATBeforeChanges;

	Form.PaymentNumberOfLines = Form.ServicePaymentSchedule.Count();
	Form.AccrualNumberOfLines = Form.ServiceAccrualSchedule.Count();
	Form.PercentagesNumberOfRows = Form.InterestAccrualSchedule.Count();

	Accrual_AfterChanges = 
	Form.AmountOfLeaseAssetsByuout
	+ Form.Accrual_SecurityPayment_AfterChanges
	+ Form.Accrual_RentalService_AfterChanges;

	Payment_AfterChanges = 
	Form.Payment_RedemptionCost_AfterChanges
	+ Form.Payment_SecurityPayment_AfterChanges
	+ Form.Payment_RentalService_AfterChanges;

	Form.Accrual_AfterChanges = ?(Accrual_AfterChanges <> 0, String(Accrual_AfterChanges) + " (" + Form.DocumentCurrencyPresentation + ")", "");
	Form.Payment_AfterChanges = ?(Payment_AfterChanges <> 0, String(Payment_AfterChanges) + " (" + Form.DocumentCurrencyPresentation + ")", "");
	
	Form.Accrual_DepositPayment_InTotal = Form.ServiceAccrualSchedule.Total("DepositPayment");
	Form.AccrualRentalServiceTotal = Form.ServiceAccrualSchedule.Total("RentalService");
	
	Form.Accrual_NDS_Total =
		+ Form.ServicePaymentSchedule.Total("BuyoutValueVAT")
		+ Form.ServiceAccrualSchedule.Total("RentalServiceVAT")
		+ Form.ServiceAccrualSchedule.Total("SecurityPaymentVATAmount");
	
	Form.PaymentOfTheRedemptionValueTotal = Form.ServicePaymentSchedule.Total("BuyoutValue");
	Form.Payment_DepositPayment_InTotal = Form.ServicePaymentSchedule.Total("DepositPayment");
	Form.PaymentForServicesRentalTotal = Form.ServicePaymentSchedule.Total("RentalService");
	
	Form.Payment_NDS_Total = 
		Form.ServicePaymentSchedule.Total("RentalServiceVAT")
		+ Form.ServicePaymentSchedule.Total("SecurityPaymentVATAmount")
		+ Form.ServicePaymentSchedule.Total("BuyoutValueVAT");
	
EndProcedure

&AtServer
Function GetScheduleData()

	QueryText = 
	"SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &Contract) AS TermsOfLeaseContracts
	|INDEX BY
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually
	|FROM
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	InformationRegister.LeaseServicesAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN (SELECT T.EffectiveContractTerms FROM TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Contract = &Contract
	|	AND ScheduleData.Active
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.RentalService AS RentalService,
	|	ScheduleData.RentalServiceVAT AS RentalServiceVAT,
	|	ScheduleData.DepositPayment AS DepositPayment,
	|	ScheduleData.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ScheduleData.BuyoutValue + ScheduleData.BuyoutValuePrepayment AS BuyoutValue,
	|	ScheduleData.BuyoutValueVAT AS BuyoutValueVAT
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN (SELECT T.EffectiveContractTerms FROM TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Contract = &Contract
	|	AND ScheduleData.Active
	|
	|ORDER BY
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Date AS Date,
	|	ScheduleData.Interests AS Interests
	|FROM
	|	InformationRegister.LeaseInterestAccrualSchedule AS ScheduleData
	|WHERE
	|	ScheduleData.EffectiveContractTerms IN (SELECT T.EffectiveContractTerms FROM TTTermsOfLeaseAgreements AS T)
	|	AND ScheduleData.Contract = &Contract
	|	AND ScheduleData.Active
	|
	|ORDER BY
	|	Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("Contract", Parameters.Contract);
	
	Result = Query.ExecuteBatch();
	
	AttributesList = "Organization,ARAPCurrency,ContractType,AssetHolder,ValidityStartDate,
	|ARAPCurrency,MethodForDeterminingCostOfAssets,
	|HasSecurityDeposit,ThereIsBuyoutOfLeasedAssets";
	ContractDetails_ = Common.ObjectAttributesValues(Parameters.Contract, AttributesList);
	
	FormServiceParameters = New Structure;
	FormServiceParameters.Insert("ContractDetails_", ContractDetails_);
	FormServiceParameters.Insert(
		"LeaseAccountingAccordingToFSB25_2018IsUsed",
		LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(ContractDetails_.Organization));
	
	ScheduleParameters = New Structure;
	
	ScheduleParameters.Insert("ReadOnly", True);
	ScheduleParameters.Insert("FormServiceParameters", FormServiceParameters);
	ScheduleParameters.Insert("DocumentCurrencyPresentation", String(ContractDetails_.ARAPCurrency));
	ScheduleParameters.Insert("InterestRate", 0);
	ScheduleParameters.Insert("PresentValue", 0);
	ScheduleParameters.Insert("LeaseStartDate", '000101010000');
	ScheduleParameters.Insert("DateOfLeaseChange", '000101010000');
	ScheduleParameters.Insert("Contract", Parameters.Contract);
	
	Selection = Result[Result.UBound() - 3].Select();
	If Selection.Next() Then
		ScheduleParameters.Insert("VATRate", Selection.VATRate);
		ScheduleParameters.Insert("TheInterestAccrualScheduleIsEnteredManually", Selection.TheInterestAccrualScheduleIsEnteredManually);
	Else
		ScheduleParameters.Insert("VATRate", Catalogs.VATRates.EmptyRef());
		ScheduleParameters.Insert("TheInterestAccrualScheduleIsEnteredManually", False);
	EndIf;
	
	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", Result[Result.UBound() - 2].Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", Result[Result.UBound() - 1].Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", Result[Result.UBound()].Unload());
	ScheduleParameters.Insert("ContractSchedules", PutToTempStorage(ContractSchedules, UUID));
	
	ScheduleParameters.Insert("AmountOfLeaseAssetsByuout", ContractSchedules.ServiceAccrualSchedule.Total("BuyoutValue"));
	ScheduleParameters.Insert("AmountOfVATRepurchaseOfRentalItems", ContractSchedules.ServiceAccrualSchedule.Total("BuyoutValueVAT"));

	Return ScheduleParameters;
	
EndFunction

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Items = Form.Items;
	
	If StructureOfChangedProps.Property("TheInterestAccrualScheduleIsEnteredManually")
		Or UpdateAll Then
		
		GraphEditingIsAvailable = 
			Form.TheInterestAccrualScheduleIsEnteredManually
			And Not Form.ReadOnly;
		
		Items.InterestAccrualSchedule.ChangeRowSet = GraphEditingIsAvailable;
		Items.InterestAccrualScheduleAdd.Enabled = GraphEditingIsAvailable;
		Items.InterestAccrualScheduleDownloadAGraphAGraphOfPercentages.Enabled = GraphEditingIsAvailable;
		
	EndIf;
	
EndProcedure

&AtClient
Function CalculateVATAmount(AmountIncludingVAT)
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	Return VATAccountingERPClientServer.CalculateVATAmount(AmountIncludingVAT, CurPercentVAT, True);
	
EndFunction

&AtClient
Procedure FillInPreviousConditionsEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInPreviousConditionsOnServer(AdditionalParameters.TableName);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPreviousConditionsOnServer(ChartName, Refill = True, UpdateResults = True)
	
	QueryTexts = New Array;
	
	ConditionText = 
		"SELECT
		|	TermsOfLeaseContractsSliceLast.EffectiveContractTerms AS EffectiveContractTerms
		|INTO TTContractTermsAndConditions
		|FROM
		|	InformationRegister.TermsOfLeaseContracts.SliceLast(&PeriodBoundary, Contract = &Contract) AS TermsOfLeaseContractsSliceLast";
	
	If ChartName = "ServiceAccrualSchedule" Then
		
		TextOfGraph = "SELECT
		|	LeaseServicesAccrualSchedule.Date AS Date,
		|	LeaseServicesAccrualSchedule.RentalService AS RentalService,
		|	LeaseServicesAccrualSchedule.RentalServiceVAT AS RentalServiceVAT,
		|	LeaseServicesAccrualSchedule.DepositPayment AS DepositPayment,
		|	LeaseServicesAccrualSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount
		|FROM
		|	InformationRegister.LeaseServicesAccrualSchedule AS LeaseServicesAccrualSchedule
		|WHERE
		|	LeaseServicesAccrualSchedule.EffectiveContractTerms IN
		|			(SELECT
		|				TTContractTermsAndConditions.EffectiveContractTerms AS EffectiveContractTerms
		|			FROM
		|				TTContractTermsAndConditions AS TTContractTermsAndConditions)
		|	AND LeaseServicesAccrualSchedule.RentalService + LeaseServicesAccrualSchedule.DepositPayment <> 0";
		
		If Not Refill Then
			TextOfGraph = TextOfGraph + "
				|	AND LeaseServicesAccrualSchedule.Date < &Period";
		EndIf;
		
	ElsIf ChartName = "ServicePaymentSchedule" Then
		
		TextOfGraph = "SELECT
		|	LeaseServicesPaymentSchedule.Date AS Date,
		|	LeaseServicesPaymentSchedule.RentalService AS RentalService,
		|	LeaseServicesPaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
		|	LeaseServicesPaymentSchedule.DepositPayment AS DepositPayment,
		|	LeaseServicesPaymentSchedule.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
		|	LeaseServicesPaymentSchedule.BuyoutValue + LeaseServicesPaymentSchedule.BuyoutValuePrepayment AS BuyoutValue,
		|	LeaseServicesPaymentSchedule.BuyoutValueVAT AS BuyoutValueVAT
		|FROM
		|	InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
		|WHERE
		|	LeaseServicesPaymentSchedule.EffectiveContractTerms IN
		|			(SELECT
		|				TTContractTermsAndConditions.EffectiveContractTerms AS EffectiveContractTerms
		|			FROM
		|				TTContractTermsAndConditions AS TTContractTermsAndConditions)
		|	AND LeaseServicesPaymentSchedule.RentalService + LeaseServicesPaymentSchedule.DepositPayment
		|		+ LeaseServicesPaymentSchedule.BuyoutValue + LeaseServicesPaymentSchedule.BuyoutValuePrepayment <> 0";
		
		If Not Refill Then
			TextOfGraph = TextOfGraph + "
				|	AND LeaseServicesPaymentSchedule.Date < &Period";
		EndIf;
	
	ElsIf ChartName = "InterestAccrualSchedule" Then

		TextOfGraph = "SELECT
		|	LeaseInterestAccrualSchedule.Date AS Date,
		|	LeaseInterestAccrualSchedule.Interests AS Interests
		|FROM
		|	InformationRegister.LeaseInterestAccrualSchedule AS LeaseInterestAccrualSchedule
		|WHERE
		|	LeaseInterestAccrualSchedule.EffectiveContractTerms IN
		|			(SELECT
		|				TTContractTermsAndConditions.EffectiveContractTerms AS EffectiveContractTerms
		|			FROM
		|				TTContractTermsAndConditions AS TTContractTermsAndConditions)
		|	AND LeaseInterestAccrualSchedule.Interests <> 0";

		If Not Refill Then
			TextOfGraph = TextOfGraph + "
			|	AND LeaseInterestAccrualSchedule.Date < &Period";
		EndIf;
		
	EndIf;
	
	QueryTexts.Add(ConditionText);
	QueryTexts.Add(TextOfGraph);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("PeriodBoundary", New Boundary(DateOfLeaseChange, BoundaryType.Excluding));
	Query.SetParameter("Period", DateOfLeaseChange);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	ScheduleData = ThisObject[ChartName];
	
	If Refill Then
		ScheduleData.Clear();
	Else
		ArrayOfRowsToDelete_1 = New Array;
		For Each PlotLine In ThisObject[ChartName] Do
			If PlotLine.Date < DateOfLeaseChange Then
				ArrayOfRowsToDelete_1.Add(PlotLine);
			EndIf;
		EndDo;
		TMCommonUse.DeleteTableRows(ScheduleData, ArrayOfRowsToDelete_1);
	EndIf;
	
	While Selection.Next() Do
		PlotLine = ThisObject[ChartName].Add();
		FillPropertyValues(PlotLine, Selection);
	EndDo;
	
	ScheduleData.Sort("Date");
	
	If UpdateResults Then
		If ChartName = "ServicePaymentSchedule" Then
			UpdateBasementOfServicePaymentSchedule(ThisObject);
		ElsIf ChartName = "ServiceAccrualSchedule" Then
			UpdateBasementOfServiceAccrualSchedule(ThisObject);
		EndIf;
		UpdateTotals(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAmountsInChartCompletion(Value, AdditionalParameters) Export
	
	If Value <> Undefined Then
		
		TableName = AdditionalParameters.TableName;
		NameOfAmountColumn = AdditionalParameters.NameOfAmountColumn;
		VATColumnName = AdditionalParameters.VATColumnName;
		CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
		
		For Each HighlightedServicesLine In Items[TableName].SelectedRows Do
			ServiceLine_ = ThisObject[TableName].FindByID(HighlightedServicesLine);
			If ServiceLine_.Date < DateOfLeaseChange Then
				Continue;
			EndIf;
			ServiceLine_[NameOfAmountColumn] = Value;
			ServiceLine_[VATColumnName] = VATAccountingERPClientServer.CalculateVATAmount(Value, CurPercentVAT, True);
			Modified = True;
		EndDo;
		
		If Modified Then 
			If TableName = "ServicePaymentSchedule" Then
				UpdateBasementOfServicePaymentSchedule(ThisObject)
			ElsIf TableName = "ServiceAccrualSchedule" Then
				 UpdateBasementOfServiceAccrualSchedule(ThisObject)
			EndIf;
			UpdateTotals(ThisObject);
		EndIf;

	EndIf;
	
EndProcedure

&AtServer
Function StructureOfFormColumnDetails(TableName, NameOfFormColumn)

	NameOfAmountDetails = StrReplace(Items[NameOfFormColumn].DataPath, TableName + ".", "");
	VATDetailsName = NameOfAmountDetails + "VAT";
	Return New Structure("Sum, VAT", NameOfAmountDetails, VATDetailsName);

EndFunction

&AtClient
Procedure ScheduleBeforeDeletion(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Date)
		And CurrentData.Date < DateOfLeaseChange Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenScheduleDateChanges(ChartName)

	CurrentData = Items[ChartName].CurrentData;
	
	ClearMessages();
	
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Date)
		And CurrentData.Date < DateOfLeaseChange Then
		WarningText = 
			StrTemplate(NStr("vi = 'Ngày lịch biểu ​​không được nhỏ hơn ngày thay đổi hợp đồng thuê: %1.';
							|ru = 'Дата графика не должна быть меньше даты изменения договора аренды: %1.';
							|en = 'The schedule date cannot be earlier than the date of the rental contract change: %1.'; fa = 'The schedule date cannot be earlier than the date of the rental contract change: %1.';
							|it = 'Дата графика не должна быть меньше даты изменения договора аренды: %1.';
							|pl = 'The schedule date cannot be earlier than the date of the rental contract change: %1.';
							|tr = 'Program tarihi, kira sözleşmesi değişikliği tarihinden daha önce olmamalıdır: %1.'"),
				Format(DateOfLeaseChange, "DLF=D"));
		CommonClient.MessageToUser(WarningText,, ChartName);
		CurrentData.Date = '00010101';
	EndIf;

EndProcedure

&AtClient
Procedure FillInAmountsInChart(TableName)
	
	ThisIsChangeOfConditions = ValueIsFilled(DateOfLeaseChange);
	
	ArrayOfAvailableColumns = New Array; // - Array of FormField
	
	If TableName = "ServicePaymentSchedule" Then
		
		ArrayOfAvailableColumns.Add(Items.ServicePaymentScheduleRentalService);
		If HasSecurityDeposit And Not ThisIsChangeOfConditions Then
			ArrayOfAvailableColumns.Add(Items.ServicePaymentScheduleDepositPayment);
		EndIf;
		If ThereIsBuyoutOfLeasedAssets Then
			ArrayOfAvailableColumns.Add(Items.ServicePaymentScheduleBuyoutValue);
		EndIf;
		
	ElsIf TableName = "ServiceAccrualSchedule" Then
		
		ArrayOfAvailableColumns.Add(Items.ServiceAccrualScheduleRentalService);
		If HasSecurityDeposit Then
			ArrayOfAvailableColumns.Add(Items.ServiceAccrualScheduleDepositPayment);
		EndIf;
		
	EndIf;
	
	CurrentColumn = Items[TableName].CurrentItem;

	If ArrayOfAvailableColumns.Find(CurrentColumn) = Undefined Then
		
		ArrayOfColumnHeaders = New Array;
		For Each AvailableColumn In ArrayOfAvailableColumns Do
			ColumnTitle = StrTemplate("«%1 / %2»", AvailableColumn.Parent.Title, AvailableColumn.Title);
			ArrayOfColumnHeaders.Add(ColumnTitle);
		EndDo;
		
		ColumnText = StrConcat(ArrayOfColumnHeaders, ", ");
		WarningText =
			StrTemplate(NStr("vi = 'Không thể điền cột đã chọn. Được phép điền cột: %1.';
							|ru = 'Невозможно заполнить выбранную колонку. Доступно заполнение колонок: %1.';
							|en = 'Cannot fill the selected column. You can fill the following columns: %1.'; fa = 'Cannot fill the selected column. You can fill the following columns: %1.';
							|it = 'Невозможно заполнить выбранную колонку. Доступно заполнение колонок: %1.';
							|pl = 'Cannot fill the selected column. You can fill the following columns: %1.';
							|tr = 'Seçili sütun doldurulamıyor. Doldurulabilecek sütunlar: %1.'"), ColumnText);
		CommonClient.MessageToUser(WarningText,, CurrentColumn.Name);
		Return;
		
	EndIf;
	
	ColumnDetailsNames = StructureOfFormColumnDetails(TableName, CurrentColumn.Name);

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TableName", TableName);
	AdditionalParameters.Insert("NameOfAmountColumn", ColumnDetailsNames.Sum);
	AdditionalParameters.Insert("VATColumnName", ColumnDetailsNames.VAT);
	
	CallbackDescription = New CallbackDescription("FillInAmountsInChartCompletion", ThisObject, AdditionalParameters);
	
	CurrentRow = Items[TableName].CurrentData;
	AmountOfFilling = ?(CurrentRow = Undefined, 0, CurrentRow[ColumnDetailsNames.Sum]);

	ToolTipText = NStr("vi = 'Hãy nhập giá trị số tiền';
						|ru = 'Введите значение суммы';
						|en = 'Enter the amount'; fa = 'Enter the amount';
						|it = 'Введите значение суммы';
						|pl = 'Enter the amount';
						|tr = 'Tutar değerini girin'");
	TypeDescription = New TypeDescription("Number", New NumberQualifiers(15, 2, AllowedSign.Nonnegative));
	
	ShowInputValue(CallbackDescription, AmountOfFilling, ToolTipText, TypeDescription);
	
EndProcedure

&AtClient
Procedure FillInPreviousConditions(TableName)
	
	If ThisObject[TableName].Count() <> 0 Then
		QueryText = NStr("vi = 'Sẽ điền lại lịch biểu theo điều kiện ban đầu. Tiếp tục?';
						|ru = 'График будет перезаполнен по исходным условиям. Продолжить?';
						|en = 'The schedule will be refilled based on the initial terms. Continue?'; fa = 'The schedule will be refilled based on the initial terms. Continue?';
						|it = 'График будет перезаполнен по исходным условиям. Продолжить?';
						|pl = 'The schedule will be refilled based on the initial terms. Continue?';
						|tr = 'Program başlangıç koşullarına göre yeniden doldurulacaktır. Devam edilsin mi?'");
		AdditionalParameters = New Structure("TableName", TableName);
		CallbackDescription = New CallbackDescription("FillInPreviousConditionsEnd", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInPreviousConditionsOnServer(TableName);
	EndIf;
	
EndProcedure

#EndRegion