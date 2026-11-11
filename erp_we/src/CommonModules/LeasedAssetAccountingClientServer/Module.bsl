////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "FA lease".
// 
////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region DefiningPropertiesOfDependentPropsOfObject

// Configures the form elements associated with the lease.
// 
// Parameters:
// 	Form - ClientApplicationForm - Contains:
// 		* Items - FormAllItems - Contains:
// 			** CalculateTheBidOrCost - FormCommand -
// 			** BasementInformation - FormDecoration -
// 	AuxiliaryAttributes - Structure -
// 	ChangedBankingDetails - String - 
Procedure ConfigureDependentFormElements__(Val Form, Val AuxiliaryAttributes, Val ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object; // See DocumentObject.SigningOfLeaseContract 
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	ByActualCost = 
		(ContractDetails_.MethodForDeterminingCostOfAssets 
			= PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually"));
			
	WithoutDiscounting = (ContractDetails_.MethodForDeterminingCostOfAssets 
		= PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount"));
	
	AccountingForBalanceSheet = (ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor"));
	
	ChangingConditions = ThisIsChangeInTermsOfLease(Object);
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then

		If Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
				And Not TypeOf(Object.Ref) = Type("DocumentRef.OBEntryOfLeaseSettlements") Then
					
			ChoiceParameters = New Array;
			ChoiceParameters.Add(New ChoiceParameter("Filter.ContractType", PredefinedValue("Enum.TypesOfLeaseContracts.Leasing")));
			Items.Contract.ChoiceParameters = New FixedArray(ChoiceParameters);
			
		EndIf;
	EndIf;
	
	#EndRegion
	
	#Region PagePaymentsUnderTheContract
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
	
		Items.SecurityPaymentAmountCurrency.Visible = Items.SecurityDepositAmount.Visible;
		Items.AmountOfRentalServicesCurrency.Visible = Items.LeaseServicesAmount.Visible;
		Items.PurchaseAmountOfRentalItemsCurrency.Visible = Items.AmountOfLeaseAssetsByuout.Visible;
		
		Items.AmountOfVATRepurchaseOfRentalItemsCurrency.Visible = 
			Items.AmountOfVATRepurchaseOfRentalItems.Visible
			And FormServiceParameters.UseVATAccounting;
		
		Items.AmountOfPersonalIncomeTax.Visible = 
			Items.VATAmount.Visible
			And FormServiceParameters.UseVATAccounting;
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("PaymentFrequency")
		Or UpdateAll Then
		
		Items.PaymentForRentalServicesCurrency.Visible = Items.PaymentForLeaseService.Visible;
	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("AccrualFrequency")
		Or UpdateAll Then
		
		Items.AccrualOfRentalServicesCurrency.Visible = Items.AccrualOfLeaseService.Visible;
	EndIf;

	If StructureOfChangedProps.Property("PaymentFrequency")
		Or UpdateAll Then
		
		If Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Day") Then
			ToolTipText = NStr("vi = 'Số tiền thanh toán hàng ngày';
								|ru = 'Ежедневная сумма оплаты';
								|en = 'Daily payment amount'; fa = 'Daily payment amount';
								|it = 'Importo quotidiano di pagamento';
								|pl = 'Codzienna wartość płatności';
								|tr = 'Günlük ödeme tutarı'");
		ElsIf Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Week") Then
			ToolTipText = NStr("vi = 'Số tiền thanh toán hàng tuần';
								|ru = 'Еженедельная сумма оплаты';
								|en = 'Weekly payment amount'; fa = 'Weekly payment amount';
								|it = 'Importo settimanale di pagamento';
								|pl = 'Cotygodniowa wartość płatności';
								|tr = 'Haftalık ödeme tutarı'");
		ElsIf Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month") Then
			ToolTipText = NStr("vi = 'Số tiền thanh toán hàng tháng';
								|ru = 'Ежемесячная сумма оплаты';
								|en = 'Monthly payment amount'; fa = 'Monthly payment amount';
								|it = 'Importo mensile di pagamento';
								|pl = 'Comiesięczna wartość płatności';
								|tr = 'Aylık ödeme tutarı'");
		ElsIf Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Quarter") Then
			ToolTipText = NStr("vi = 'Số tiền thanh toán hàng quý';
								|ru = 'Ежеквартальная сумма оплаты';
								|en = 'Quarterly payment amount'; fa = 'Quarterly payment amount';
								|it = 'Importo trimestrale di pagamento';
								|pl = 'Cokwartalna wartość płatności';
								|tr = 'Üç aylık ödeme tutarı'");
		ElsIf Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.HalfYear") Then
			ToolTipText = NStr("vi = 'Số tiền thanh toán nửa năm';
								|ru = 'Полугодичная сумма оплаты';
								|en = 'Semiannual payment amount'; fa = 'Semiannual payment amount';
								|it = 'Importo semestrale di pagamento';
								|pl = 'Półroczna wartość płatności';
								|tr = 'Altı aylık ödeme tutarı'");
		ElsIf Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Year") Then
			ToolTipText = NStr("vi = 'Số tiền thanh toán hàng năm';
								|ru = 'Ежегодная сумма оплаты';
								|en = 'Annual payment amount'; fa = 'Annual payment amount';
								|it = 'Importo annuale di pagamento';
								|pl = 'Coroczna wartość płatności';
								|tr = 'Yıllık ödeme tutarı'");
		Else
			ToolTipText = "";
		EndIf;
		
		Items.PaymentForLeaseService.ToolTip = ToolTipText;
	
	EndIf;

	If StructureOfChangedProps.Property("AccrualFrequency")
		Or UpdateAll Then
		
		If Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Day") Then
			ToolTipText = NStr("vi = 'Số tiền tính lãi hàng ngày';
								|ru = 'Ежедневная сумма начислений';
								|en = 'Daily accrual amount'; fa = 'Daily accrual amount';
								|it = 'Importo quotidiano maturazioni';
								|pl = 'Codzienna wartość naliczeń';
								|tr = 'Günlük tutar tahakkuku'");
		ElsIf Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Week") Then
			ToolTipText = NStr("vi = 'Số tiền tính lãi hàng tuần';
								|ru = 'Еженедельная сумма начислений';
								|en = 'Weekly accrual amount'; fa = 'Weekly accrual amount';
								|it = 'Importo settimanale maturazioni';
								|pl = 'Cotygodniowa wartość naliczeń';
								|tr = 'Haftalık tutar tahakkuku'");
		ElsIf Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month") Then
			ToolTipText = NStr("vi = 'Số tiền tính lãi hàng tháng';
								|ru = 'Ежемесячная сумма начислений';
								|en = 'Monthly accrual amount'; fa = 'Monthly accrual amount';
								|it = 'Importo mensile maturazioni';
								|pl = 'Comiesięczna wartość naliczeń';
								|tr = 'Aylık tahakkuk tutarı'");
		ElsIf Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Quarter") Then
			ToolTipText = NStr("vi = 'Số tiền tính lãi hàng quý';
								|ru = 'Ежеквартальная сумма начислений';
								|en = 'Quarterly accrual amount'; fa = 'Quarterly accrual amount';
								|it = 'Importo trimestrale maturazioni';
								|pl = 'Cokwartalna wartość naliczeń';
								|tr = 'Üç aylık tahakkuk tutarı'");
		ElsIf Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.HalfYear") Then
			ToolTipText = NStr("vi = 'Số tiền tính lãi nửa năm';
								|ru = 'Полугодичная сумма начислений';
								|en = 'Semiannual accrual amount'; fa = 'Semiannual accrual amount';
								|it = 'Importo semestrale maturazioni';
								|pl = 'Półroczna wartość naliczeń';
								|tr = 'Altı aylık tahakkuk tutarı'");
		ElsIf Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Year") Then
			ToolTipText = NStr("vi = 'Số tiền tính lãi hàng năm';
								|ru = 'Ежегодная сумма начислений';
								|en = 'Annual accrual amount'; fa = 'Annual accrual amount';
								|it = 'Importo annuale maturazioni';
								|pl = 'Coroczna wartość naliczeń';
								|tr = 'Yıllık tahakkuk tutarı'");
		Else
			ToolTipText = "";
		EndIf;
		
		Items.AccrualOfLeaseService.ToolTip = ToolTipText;
	
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		
		Or StructureOfChangedProps.Property("SecurityDepositAmount")
		Or StructureOfChangedProps.Property("LeaseServicesAmount")
		Or StructureOfChangedProps.Property("AmountOfLeaseAssetsByuout")
		Or StructureOfChangedProps.Property("VATAmount")
		Or StructureOfChangedProps.Property("AmountOfVATRepurchaseOfRentalItems")
		Or StructureOfChangedProps.Property("VATRate")
		Or StructureOfChangedProps.Property("DateOfFirstSecurityPayment")
		Or StructureOfChangedProps.Property("DateOfFirstPayment")
		Or StructureOfChangedProps.Property("LeaseStartDate")
		
		Or StructureOfChangedProps.Property("PaymentFrequency")
		Or StructureOfChangedProps.Property("AccrualFrequency")
		Or StructureOfChangedProps.Property("PaymentForLeaseService")
		Or StructureOfChangedProps.Property("AccrualOfLeaseService")
		
		Or StructureOfChangedProps.Property("ServicePaymentSchedule")
		Or StructureOfChangedProps.Property("ServiceAccrualSchedule")
		Or StructureOfChangedProps.Property("InterestAccrualSchedule")
		
		Or StructureOfChangedProps.Property("DocumentVersion24")
		Or UpdateAll Then

		TitleLines = New Array;
		
		If AuxiliaryAttributes.RecordInOperationalAccounting
			And (FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet) Then
			
			CheckResult = CheckComplianceOfGraphs(
				Object, 
				ContractDetails_,
				FormServiceParameters.StartOfLeaseAccountingUnderFSB25_2018, 
				Form.DocumentCurrencyPresentation);
				
		Else
			CheckResult = Undefined;
		EndIf;
		
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.SecurityPaymentAmountIndicator,
			?(CheckResult <> Undefined, CheckResult.SecurityDepositAmount, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.AmountOfRentalServicesIndicator,
			?(CheckResult <> Undefined, CheckResult.LeaseServicesAmount, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.PurchaseAmountOfRentalItemsIndicator,
			?(CheckResult <> Undefined, CheckResult.AmountOfLeaseAssetsByuout, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.DateOfTheFirstSecurityPaymentIndicator,
			?(CheckResult <> Undefined, CheckResult.DateOfFirstSecurityPayment, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.FirstPaymentDateIndicator,
			?(CheckResult <> Undefined, CheckResult.DateOfFirstPayment, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.RedemptionDateIndicator,
			?(CheckResult <> Undefined, CheckResult.BuyoutDate, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.AmountOfNDSIndicator,
			?(CheckResult <> Undefined, CheckResult.VATAmount, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.AmountOfVATRepurchaseOfRentalItemsIndicator,
			?(CheckResult <> Undefined, CheckResult.AmountOfVATRepurchaseOfRentalItems, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.PaymentFrequencyIndicator,
			?(CheckResult <> Undefined, CheckResult.PaymentFrequency, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.PaymentForRentalServicesIndicator,
			?(CheckResult <> Undefined, CheckResult.PaymentForLeaseService, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.FrequencyOfAccrualsIndicator,
			?(CheckResult <> Undefined, CheckResult.AccrualFrequency, Undefined));
			
		SetVisibilityOfScheduleVerificationIdentifier(
			Items.AccrualOfRentalServicesIndicator,
			?(CheckResult <> Undefined, CheckResult.AccrualOfLeaseService, Undefined));
			
		If ChangingConditions Then
			SetVisibilityOfScheduleVerificationIdentifier(
				Items.OpenPaymentScheduleIndicator,
				?(CheckResult <> Undefined, CheckResult.ChartDiscrepancies, Undefined));
				
			SetVisibilityOfScheduleVerificationIdentifier(
				Items.OpenAccrualChartIndicator,
				?(CheckResult <> Undefined, CheckResult.ChartDiscrepancies, Undefined));
		EndIf;
			
		If CheckResult <> Undefined
			And CheckResult.ThereAreDiscrepancies Then
			
			TitleLines.Add(NStr("vi = 'Lịch biểu thanh toán và tính lãi không tương ứng với hạch toán theo hợp đồng';
								|ru = 'График оплат и начислений не соответствует расчетам по договору';
								|en = 'The schedule of payments and charges does not match the settlements under the contract'; fa = 'The schedule of payments and charges does not match the settlements under the contract';
								|it = 'Il grafico dei pagamenti e maturazioni non corrispondono ai conti in base all''accordo';
								|pl = 'Harmonogram płatności i naliczeń nie jest zgodny z obliczeniami w ramach umowy';
								|tr = 'Ödeme ve masraf çizelgesi sözleşmeye dayalı hesaplamalarla uyuşmamaktadır'"));
			
			If Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.PaymentFrequency)
				And Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.AccrualFrequency)
				And Not Form.ReadOnly Then
			
				TitleLines.Add(Chars.LF);
				LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu thanh toán và tính lãi';
													|ru = 'Заполнить график оплат и начислений';
													|en = 'Fill in the schedule of payments and charges'; fa = 'Fill in the schedule of payments and charges';
													|it = 'Compilare grafico dei pagamenti e maturazioni';
													|pl = 'Wypełnij harmonogram płatności i naliczeń';
													|tr = 'Ödeme ve tahakkuk çizelgesini doldurun'"),,,, "#FillInSchedule");
				TitleLines.Add(LabelText);
				TitleLines.Add(" / ");
				
			ElsIf Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.PaymentFrequency)
				And Not Form.ReadOnly Then
					
				TitleLines.Add(Chars.LF);
				LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu thanh toán';
													|ru = 'Заполнить график оплат';
													|en = 'Fill in the schedule of payments'; fa = 'Fill in the schedule of payments';
													|it = 'Compilare grafico dei pagamenti';
													|pl = 'Wypełnij harmonogram płatności';
													|tr = 'Ödeme grafini doldurun'"),,,, "#FillInSchedule");
				TitleLines.Add(LabelText);
				TitleLines.Add(" / ");

			ElsIf Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.AccrualFrequency)
				And Not Form.ReadOnly Then
				
				TitleLines.Add(Chars.LF);
				LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu tính lãi';
													|ru = 'Заполнить график начислений';
													|en = 'Fill in the schedule of accruals'; fa = 'Fill in the schedule of accruals';
													|it = 'Compilare grafico delle maturazioni';
													|pl = 'Wypełnij harmonogram naliczeń';
													|tr = 'Tahakkuk çizelgesini doldurun'"),,,, "#FillInSchedule");
				TitleLines.Add(LabelText);
				TitleLines.Add(" / ");
			
			EndIf;
			
			If Not Form.ReadOnly Then
				If TitleLines.Count() = 1 Then
					TitleLines.Add(Chars.LF);
				EndIf;
				
				LabelText = New FormattedString(NStr("vi = 'Điền lại hạch toán theo hợp đồng';
													|ru = 'Перезаполнить расчеты по договору';
													|en = 'Refill settlements under the contract'; fa = 'Refill settlements under the contract';
													|it = 'Ricompilare i calcoli in base all''accordo';
													|pl = 'Ponownie wypełnij rozliczenia z tytułu umowy';
													|tr = 'Sözleşmeye bağlı ödemeleri yenileyin'"),,,, "#FillInCalculationsAccordingToSchedule");
				TitleLines.Add(LabelText);
			EndIf;

			Items.BasementInformation.Title = New FormattedString(TitleLines);
		
		ElsIf Form.LeaseTermHasBeenChanged Then

			TitleLines.Add(NStr("vi = 'Đã thay đổi thời hạn thuê';
								|ru = 'Срок аренды изменен';
								|en = 'Rental period is changed'; fa = 'دوره اجاره تغییر کرده است';
								|it = 'Срок аренды изменен';
								|pl = 'Rental period is changed';
								|tr = 'Kira süresi değiştirildi'"));

			TitleLines.Add(Chars.LF);
			LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu thanh toán và tính lãi';
												|ru = 'Заполнить график оплат и начислений';
												|en = 'Fill in the schedule of payments and charges'; fa = 'Fill in the schedule of payments and charges';
												|it = 'Compilare grafico dei pagamenti e maturazioni';
												|pl = 'Wypełnij harmonogram płatności i naliczeń';
												|tr = 'Ödeme ve tahakkuk çizelgesini doldurun'"),,,, "#FillInSchedule");
			TitleLines.Add(LabelText);

			Items.BasementInformation.Title = New FormattedString(TitleLines);
		
		ElsIf Object.ServicePaymentSchedule.Count() = 0
			And Object.ServiceAccrualSchedule.Count() = 0
			And AuxiliaryAttributes.RecordInOperationalAccounting Then			
				
			TitleLines.Add(NStr("vi = 'Chưa điền lịch biểu thanh toán và tính lãi';
								|ru = 'График оплат и начислений не заполнен';
								|en = 'Schedule of payments and charges is not filled'; fa = 'Schedule of payments and charges is not filled';
								|it = 'Grafico dei pagamenti e maturazioni non compilato';
								|pl = 'Harmonogram płatności i naliczeń nie jest wypełniony';
								|tr = 'Ödeme ve tahakkuk çizelgesi doldurulmamış.'"));
			
			If Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.PaymentFrequency)
				And Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.AccrualFrequency)
				And Not Form.ReadOnly Then
				
				TitleLines.Add(Chars.LF);
				LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu thanh toán và tính lãi';
													|ru = 'Заполнить график оплат и начислений';
													|en = 'Fill in the schedule of payments and charges'; fa = 'Fill in the schedule of payments and charges';
													|it = 'Compilare grafico dei pagamenti e maturazioni';
													|pl = 'Wypełnij harmonogram płatności i naliczeń';
													|tr = 'Ödeme ve tahakkuk çizelgesini doldurun'"),,,, "#FillInSchedule");
				TitleLines.Add(LabelText);
			
			ElsIf Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.PaymentFrequency)
				And Not Form.ReadOnly Then
				
				TitleLines.Add(Chars.LF);
				LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu thanh toán';
													|ru = 'Заполнить график оплат';
													|en = 'Fill in the schedule of payments'; fa = 'Fill in the schedule of payments';
													|it = 'Compilare grafico dei pagamenti';
													|pl = 'Wypełnij harmonogram płatności';
													|tr = 'Ödeme grafini doldurun'"),,,, "#FillInSchedule");
				TitleLines.Add(LabelText);
				
			ElsIf Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
				And ValueIsFilled(Object.AccrualFrequency)
				And Not Form.ReadOnly Then
				
				TitleLines.Add(Chars.LF);
				LabelText = New FormattedString(NStr("vi = 'Điền lịch biểu tính lãi';
													|ru = 'Заполнить график начислений';
													|en = 'Fill in the schedule of accruals'; fa = 'Fill in the schedule of accruals';
													|it = 'Compilare grafico delle maturazioni';
													|pl = 'Wypełnij harmonogram naliczeń';
													|tr = 'Tahakkuk çizelgesini doldurun'"),,,, "#FillInSchedule");
				TitleLines.Add(LabelText);
				
			EndIf;
			
			Items.BasementInformation.Title = New FormattedString(TitleLines);

		EndIf;
		
		If AuxiliaryAttributes.DocumentVersion24 Then
			
			If TitleLines.Count() <> 0 Then
				TitleLines.Add(Chars.LF);
			EndIf;
			TitleLines.Add(NStr("vi = 'Đã tạo chứng từ trong phiên bản 2.4';
								|ru = 'Документ создан в версии 2.4';
								|en = 'Document has been created in version 2.4'; fa = 'Document has been created in version 2.4';
								|it = 'Documento creato nella versione 2.4';
								|pl = 'Dokument jest utworzony w wersji 2.4';
								|tr = 'Belge 2.4 sürümünde oluşturulmuştur'"));
			If Not Form.ReadOnly Then
				TitleLines.Add(" (");
				LabelText = New FormattedString(NStr("vi = 'thay đổi sang phiên bản 2.5';
													|ru = 'изменить на версию 2.5';
													|en = 'change for version 2.5'; fa = 'change for version 2.5';
													|it = 'modificare nella versione 2.5';
													|pl = 'zmień na wersję 2.5';
													|tr = 'sürüm 2.5''e değiştir'"),,,, "#ChangeDocumentVersion");
				TitleLines.Add(LabelText);
				TitleLines.Add(")");
			EndIf;
			
		EndIf;
			
		If TitleLines.Count() <> 0 Then
			Items.BasementIndicator.Visible = True;
			Items.BasementInformation.Visible = True;
			Items.BasementInformation.Title = New FormattedString(TitleLines);
		Else
			Items.BasementIndicator.Visible = False;
			Items.BasementInformation.Visible = False;
		EndIf;
		
	EndIf;

	If StructureOfChangedProps.Property("TermYears")
		Or StructureOfChangedProps.Property("TermMonths")
		Or StructureOfChangedProps.Property("TermDays")
		Or StructureOfChangedProps.Property("LeaseStartDate")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then

		Form.RentalPeriod = NonCurrentAssetsClientServer.PresentationWithFormattedString(
								Object.TermYears, 
								Object.TermMonths, 
								Object.TermDays, 
								Object.LeaseStartDate, 
								Form.ReadOnly);
		
	EndIf;
	
	#EndRegion
	
	#Region DiscountingPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not WithoutDiscounting
			And AuxiliaryAttributes.RecordInOperationalAccounting;
			
		Items.PresentValue.Visible = PropertyValue;
		Items.PresentValueCurrency.Visible = PropertyValue;
		Items.OpenTheInterestAccrualSchedule.Visible = PropertyValue;
		Items.CalculateTheBidOrCost.Visible = PropertyValue;
		
		//
		Items.InterestAmountCurrency.Visible = Items.InterestAmount.Visible;
		Items.DecorationInterestRate.Visible = Items.InterestRate.Visible;
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("TheInterestAccrualScheduleIsEnteredManually")
		Or UpdateAll Then

		If FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Then
			
			If ByActualCost Then
				Items.CalculateTheBidOrCost.Title =
					?(Object.TheInterestAccrualScheduleIsEnteredManually,
						NStr("vi = 'Tính thuế suất';
							|ru = 'Рассчитать ставку';
							|en = 'Calculate rate'; fa = 'Calculate rate';
							|it = 'Calcolare tariffa';
							|pl = 'Oblicz stawkę';
							|tr = 'Oranı hesaplayın'"),
						NStr("vi = 'Tính thuế suất và phần trăm';
							|ru = 'Рассчитать ставку и проценты';
							|en = 'Calculate rate and interest'; fa = 'محاسبه نرخ و سود';
							|it = 'Calcolare tasso e interessi';
							|pl = 'Oblicz stawkę i procenty';
							|tr = 'Oranı ve faizi hesaplayın'"));
			Else
				Items.CalculateTheBidOrCost.Title =
					?(Object.TheInterestAccrualScheduleIsEnteredManually,
						NStr("vi = 'Tính giá trị';
							|ru = 'Рассчитать стоимость';
							|en = 'Calculate cost'; fa = 'Calculate cost';
							|it = 'Calcolare prezzo';
							|pl = 'Oblicz wartość';
							|tr = 'Maliyeti hesaplayın'"),
						NStr("vi = 'Tính giá trị và phần trăm';
							|ru = 'Рассчитать стоимость и проценты';
							|en = 'Calculate cost and interest'; fa = 'Calculate cost and interest';
							|it = 'Calcolare costo e interessi';
							|pl = 'Oblicz wartość i procenty';
							|tr = 'Maliyet ve faizi hesaplayın'"));
			EndIf;
					
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region Other

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		Form.TheCostIsCalculatedAutomatically = 
			FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
			And ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
			Or ContractDetails_.MethodForDeterminingCostOfAssets =
				PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount");
	
	EndIf;
	
	#EndRegion
	
EndProcedure

// 
// Parameters:
//  Object - CatalogObject.LeaseContract, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - Contains Properties:
// 			* LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesForDependentDetails_LeaseAgreements(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ThisIsLeaseAgreement = (Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing"));
	
	ReflectServicesInExpenses =
		Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
		Or AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not Object.RecognizeLeasedItemsInLocalAccounting
		Or AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not Object.RecognizeLeasedAssetsInManagementAccounting;

	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ContractType", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;

	#EndRegion
	
	#Region ContractParametersPage
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or StructureOfChangedProps.Property("ContractType")
		Or StructureOfChangedProps.Property("AssetHolder")
		Or UpdateAll Then
		
		PropertyValue = 
			ThisIsLeaseAgreement
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
				Or Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder"));
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsBuyoutOfLeasedAssets", 
			"ThereIsBuyoutOfLeasedAssets", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ContractType")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"AssetHolder", 
			"ItemVisibility", 
			ThisIsLeaseAgreement, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ContractType")
		Or UpdateAll Then

		PropertyValue =
			Not ThisIsLeaseAgreement
			And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently;
			 
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OptionToReflectAllInAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OptionOfReflectionInReglAccounting", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OptionOfReflectionInTheAccountingOfUPR", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or StructureOfChangedProps.Property("ContractType")
		Or StructureOfChangedProps.Property("ThereIsBuyoutOfLeasedAssets")
		Or StructureOfChangedProps.Property("AssetHolder")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.ThereIsBuyoutOfLeasedAssets
			And ThisIsLeaseAgreement
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
				Or Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ThereIsPrepaymentOfBuyoutValue", 
			"ThereIsPrepaymentOfBuyoutValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("VATTaxation")
		Or UpdateAll Then 
		
		PropertyValue = Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AgencyAgreementKind", 
			"AgencyAgreementKind", 
			"MarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	#EndRegion
	
	#Region AccountInformationPage
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Status")
		Or StructureOfChangedProps.Property("AssetHolder")
		Or StructureOfChangedProps.Property("RecognizeLeasedItemsInLocalAccounting")
		Or StructureOfChangedProps.Property("RecognizeLeasedAssetsInManagementAccounting")
		Or UpdateAll Then
		
		ThisIsTaxAgent = Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent");
		PropertyValue = ReflectServicesInExpenses Or ThisIsTaxAgent;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemServices", 
			"ExpenseItemServices", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemServices", 
			"ExpenseItemServices", 
			"MarkIncomplete", 
			ThisIsTaxAgent, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionServices", 
			"ExpensesDimensionServices", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitServices", 
			"BusinessUnitServices", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitServices", 
			"BusinessUnitServices", 
			"MarkIncomplete", 
			ThisIsTaxAgent, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or StructureOfChangedProps.Property("Status")
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemInterest", 
			"ExpenseItemInterest", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionInterest", 
			"ExpensesDimensionInterest", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitInterest", 
			"BusinessUnitInterest", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue = 
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And (Object.Status = PredefinedValue("Enum.CounterpartyContractStatuses.Valid")
				Or Object.Status = PredefinedValue("Enum.CounterpartyContractStatuses.Closed"));
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemInterest", 
			"ExpenseItemInterest", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.VendorInvoiceLeasedAssets, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - Contains Properties:
// 			* LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// 	ChangedBankingDetails - String - List of changed Bank details.
// 			
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentDetails_RedemptionOfLeasedFA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	FARedemptionParameters = FARedemptionParameters(Object, AuxiliaryAttributes);
	
	ItemDetailsParameters = New Array;
	
	LeasedAssetAccountingClientServerLocalization.SupplementValuesOfPropertiesOfDependentDetails_PurchaseOfLeasedFA(
		Object, AuxiliaryAttributes, FARedemptionParameters, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.OBEntryOfLeaseSettlements - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentDetails_EnteringLeaseSettlementBalances(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	AccountingForBalanceSheet = 
		ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
		And Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;

	ByActualCost = (ContractDetails_.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually"));
	WithoutDiscounting = (ContractDetails_.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount"));

	#Region PaymentBalancesPage
	
	#Region LeaseObligations
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
		
		PropertyValue = 
			Not AccountingForBalanceSheet
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseObligationsBalance", 
			"LeaseObligationsBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseLiabilityBalanceLocal", 
			"LeaseLiabilityBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Not AccountingForBalanceSheet
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseLiabilityBalanceMan", 
			"LeaseLiabilityBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region RentalServices
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or UpdateAll Then
	
		PropertyValue = 
			(AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RentalServiceBalance", 
			"RentalServiceBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RentalServiceBalanceLocal", 
			"RentalServiceBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			(AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RentalServiceBalanceMan", 
			"RentalServiceBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	#EndRegion
	
	#Region BuyoutValue
	
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
			
		PropertyValue = 
			Not AccountingForBalanceSheet
			And ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutValueBalance", 
			"BuyoutValueBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutValueBalanceLocal", 
			"BuyoutValueBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Not AccountingForBalanceSheet
			And ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutValueBalanceMan", 
			"BuyoutValueBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	#EndRegion

	#Region VAT
	
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then

		PropertyValue = 
			Not AccountingForBalanceSheet
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATBalance", 
			"VATBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATBalanceLocal", 
			"VATBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Not AccountingForBalanceSheet
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATBalanceMan", 
			"VATBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	#EndRegion
	
	#Region Interests
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
	
		PropertyValue = 
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not WithoutDiscounting
			And (AuxiliaryAttributes.PostInFinancialAndTaxAccounting 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestsBalance", 
			"InterestsBalance", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestBalanceLocal", 
			"InterestBalanceLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not WithoutDiscounting
			And (AuxiliaryAttributes.RecordInMA 
				Or AuxiliaryAttributes.RecordInOperationalAccounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestBalanceMan", 
			"InterestBalanceMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	#EndRegion
	
	#EndRegion
	
	#Region DiscountingPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not WithoutDiscounting
			And Not (ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
					And ByActualCost);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Cost", 
			"Cost", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	#EndRegion
	
	AddPropertyValuesForDependentProps__(
		Object, 
		AuxiliaryAttributes, 
		StructureOfChangedProps, 
		ItemDetailsParameters);
	
	LeasedAssetAccountingClientServerLocalization.SupplementValuesOfPropertiesOfDependentDetails_EnterBalancesOfLeaseSettlements(
		Object, AuxiliaryAttributes, ChangedBankingDetails, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.EnterRentalInvestmentBalance, FormDataStructure -
//  AuxiliaryAttributes - Structure -  
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentDetails_InputOfBalancesOfInvestmentInRent(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;

	ItemDetailsParameters = New Array;

	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.ReturnAssetsFromLeasee2_4, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - Contains Properties:
// 			* LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_FARefundFromLease(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		 
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LeaseholderIntercompanyARAP", 
			"ItemVisibility", 
			PropertyValue,
			ItemDetailsParameters);
		
		//
		PropertyValue = AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Not AuxiliaryAttributes.ReturnFromFinarenda;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DepreciationAccrualLocalAccounting", 
			"ItemVisibility", 
			PropertyValue,
			ItemDetailsParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("LeaseholderIntercompanyARAP")
		Or UpdateAll Then
		
		LesseeOrganization = Object.LeaseholderIntercompanyARAP;
		
		CounterpartiesLinkType = New TypeDescription("CatalogRef.Counterparties");
		CompanyLinkType = New TypeDescription("CatalogRef.Companies");
		TenantType = ?(LesseeOrganization, CompanyLinkType, CounterpartiesLinkType);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Leaseholder", 
			"Leaseholder", 
			"TypeRestriction", 
			TenantType, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Contract", 
			"Contract", 
			"ItemVisibility", 
			Not LesseeOrganization,
			ItemDetailsParameters);
		
	EndIf;
		
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		PropertyValue = Not AuxiliaryAttributes.ReturnFromFinarenda;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMan", 
			"DepreciationAccrualMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualLocalAccounting", 
			"DepreciationAccrualLocalAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
				
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("DepreciationAccrualMan")
		Or UpdateAll Then
		
		PropertyValue = 
			Not AuxiliaryAttributes.ReturnFromFinarenda
			And Object.DepreciationAccrualMan = PredefinedValue("Enum.DepreciationAccrualChangeOptions.Valid");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("DepreciationAccrualLocalAccounting")
		Or UpdateAll Then
			
		PropertyValue = 
			Not AuxiliaryAttributes.ReturnFromFinarenda
			And Object.DepreciationAccrualLocalAccounting = PredefinedValue("Enum.DepreciationAccrualChangeOptions.Valid");
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"ExpenseItemAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionAccounting", 
			"ExpensesDimensionAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = AuxiliaryAttributes.ReturnFromFinarenda;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAGroupOfDirectionOfDisposal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAccrualLocalAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAccrualMan")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentDetails_ConclusionOfLeaseAgreement(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	AccountingForBalanceSheet = 
		ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
		And Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;

	CreatedForTransition = (EndOfDay(Object.Date) + 1 = AuxiliaryAttributes.StartOfLeaseAccountingUnderFSB25_2018);
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then

		PropertyValue = 
			Not AuxiliaryAttributes.VNAManagementIsUsed_2_4
			And AccountingForBalanceSheet;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"GLAccount", 
			"GLAccount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		PropertyValue = 
			AuxiliaryAttributes.VNAManagementIsUsed_2_4
			And AccountingForBalanceSheet;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialAccountingGroup", 
			"FinancialAccountingGroup", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		PropertyValue = CreatedForTransition;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeItem", 
			"IncomeItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfRevenue", 
			"DimensionOfRevenue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItem", 
			"ExpenseItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfExpenses", 
			"DimensionOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	#EndRegion
	
	#Region PagePaymentsUnderTheContract
	
	If StructureOfChangedProps.Property("VATTaxation")
		Or UpdateAll Then
	
		PropertyValue = 
			ValueIsFilled(Object.VATTaxation)
			And VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails().Find(Object.VATTaxation) <> Undefined;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATRate", 
			"VATRate", 
			"OnlyViewWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region FixedAssetsPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		PropertyValue =
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
			Or Not AccountingForBalanceSheet;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ExpenseItem", 
			"FAExpenseItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FADepartment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"SpokesdroneForBalance", 
			"Visible", 
			Not PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		PropertyValue = CreatedForTransition;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.NetBookValue", 
			"FANetBookValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	AddPropertyValuesForDependentProps__(
		Object, 
		AuxiliaryAttributes, 
		StructureOfChangedProps, 
		ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.LeaseTermAdjustment - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentDetails_ChangesInTermsOfLeaseAgreement(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	AccountingParametersForRentalItems = AccountingParametersForRentalItems(
		AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed, ContractDetails_);
	
	#Region PageGeneral
	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = (EndOfDay(Object.Date) = EndOfYear(Object.Date)
				And Object.PeriodAdjustment <> 0);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PeriodAdjustment", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	#EndRegion
		
	#Region OSPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		PropertyValue = AccountingParametersForRentalItems.ThereIsMaAccount;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.UsefulLifeManagementAccounting", 
			"FAUsefulLifeManagementAccounting", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	#EndRegion
	
	#Region PagePaymentsUnderTheContract

	If StructureOfChangedProps.Property("VATTaxation") 
		Or UpdateAll Then
		
		PropertyValue = 
			ValueIsFilled(ContractDetails_.VATTaxation)
			And VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails().Find(ContractDetails_.VATTaxation) <> Undefined
			And ContractDetails_.RegisterImportApplications;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATRate", 
			"VATRate", 
			"OnlyViewWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	#EndRegion
	
	AddPropertyValuesForDependentProps__(
		Object, 
		AuxiliaryAttributes, 
		StructureOfChangedProps, 
		ItemDetailsParameters);
	
	LeasedAssetAccountingClientServerLocalization.AddPropertyValuesForDependentDetails_ChangeLeaseTerms(
		Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.ChangeRentalTerms, FormDataStructure -
//  AuxiliaryAttributes - Structure -  
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentDetails_ChangesInTermsOfTransferForRent(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;

	ItemDetailsParameters = New Array;

	If StructureOfChangedProps.Property("Contract") Or UpdateAll Then
		
		PropertyValue = 
			ContractDetails_.ContractType = PredefinedValue("Enum.ContractTypes.Sublease");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DocumentBasis", 
			"DocumentBasis", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		PropertyValue = PropertyValue Or Not ValueIsFilled(Object.Contract);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"GeneratedDocument", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.ProvideAssetsToLeasee2_4, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - Contains Properties:
// 			* LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// 	ChangedBankingDetails - String - List of changed Bank details.
// 	
// Returns:
// 	Array of See TMCommonUseClientServer.NewParameterForObjectDetails 
Function PropertyValuesOfDependentProps_TransferToOSV(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		PropertyValue = Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		 
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LeaseholderIntercompanyARAP", 
			"ItemVisibility", 
			PropertyValue,
			ItemDetailsParameters);
		
		PropertyValue = AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			And Not AuxiliaryAttributes.TransferForLeaseUnderFAS25;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualLocalAccounting", 
			"DepreciationAccrualLocalAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("DepreciationAccrualLocalAccounting")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.DepreciationAccrualLocalAccounting = PredefinedValue("Enum.DepreciationAccrualChangeOptions.Valid")
			And Not AuxiliaryAttributes.TransferForLeaseUnderFAS25;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseRecordMethodAC", 
			"ExpenseRecordMethodAC", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ExpenseItemAccounting", 
			"ItemVisibility", 
			PropertyValue,
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ExpensesDimensionAccounting", 
			"ItemVisibility", 
			PropertyValue,
			ItemDetailsParameters);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("DepreciationAccrualMan")
		Or UpdateAll Then
			
		PropertyValue = 
			Object.DepreciationAccrualMan = PredefinedValue("Enum.DepreciationAccrualChangeOptions.Valid")
			And Not AuxiliaryAttributes.TransferForLeaseUnderFAS25;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"MethodForReflectingMaExpenses", 
			"MethodForReflectingMaExpenses", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemManagementAccounting", 
			"ExpenseItemManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesDimensionManagementAccounting", 
			"ExpensesDimensionManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting", 
			"Visible", 
			PropertyValue,
			ItemDetailsParameters);
				
	EndIf;

	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("LeaseholderIntercompanyARAP") 
		Or UpdateAll Then
		
		LesseeOrganization = 
			Object.LeaseholderIntercompanyARAP
			And Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		
		CounterpartiesLinkType = New TypeDescription("CatalogRef.Counterparties");
		CompanyLinkType = New TypeDescription("CatalogRef.Companies");
		TenantType = ?(LesseeOrganization, CompanyLinkType, CounterpartiesLinkType);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Leaseholder", 
			"Leaseholder", 
			"TypeRestriction", 
			TenantType, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseholderBusinessUnit", 
			"LeaseholderBusinessUnit", 
			"Visible", 
			LesseeOrganization, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseholderEmployeeInCharge", 
			"LeaseholderEmployeeInCharge", 
			"Visible", 
			LesseeOrganization, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LocationAddress", 
			"LocationAddress", 
			"Visible", 
			LesseeOrganization, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		PropertyValue = Not AuxiliaryAttributes.TransferForLeaseUnderFAS25;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.SecurityDepositValue", 
			"FASecurityDepositValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrualMan", 
			"DepreciationAccrualMan", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServicePaymentSchedule", 
			"", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServiceAccrualSchedule", 
			"", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = AuxiliaryAttributes.TransferForLeaseUnderFAS25;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ExpenseItem", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DimensionOfExpenses", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeItem", 
			"IncomeItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfRevenue", 
			"DimensionOfRevenue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AmountOfAdvancePayments", 
			"AmountOfAdvancePayments", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FillInAmountOfAdvancePayments", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.FairValueLocal", 
			"FAFairValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.FairValueManag", 
			"FAFairValueManag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.NonGuaranteedResidualValueLocal", 
			"FANonGuaranteedResidualValueLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.NonGuaranteedResidualValueManag", 
			"FANonGuaranteedResidualValueManag", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.RentalPayments", 
			"FARentalPayments", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.RateOfReturn", 
			"FARateOfReturn", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.ScheduleRef", 
			"FAScheduleRef", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAFillInCharts", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FACalculateRateOfReturn", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAReferenceCalculationOfAccrualOfInterest", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		PropertyValue = 
			Not AuxiliaryAttributes.ContractInLocalAccountingCurrency
			And AuxiliaryAttributes.TransferForLeaseUnderFAS25;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"AmountOfAdvancePaymentsLocal", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("FAFairValueLocal")
		Or StructureOfChangedProps.Property("FAFairValueManag")
		Or UpdateAll Then
			
		FairNetInitialCostLocalIsIndicated = 
			Object.FA.Total("FairValueLocal") > 0 
			Or Object.FA.Total("FairValueManag") > 0;
			
		PropertyValue = FairNetInitialCostLocalIsIndicated;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeItem", 
			"IncomeItem", 
			"Enabled", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"ExpenseItem", 
			"Enabled", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DimensionOfRevenue", 
			"Enabled", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DimensionOfExpenses", 
			"Enabled", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncomeItem", 
			"", 
			"OnlyViewWithoutBlankMark", 
			Not PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = 
			AuxiliaryAttributes.TransferForLeaseUnderFAS25
				And FairNetInitialCostLocalIsIndicated
			Or Not AuxiliaryAttributes.TransferForLeaseUnderFAS25
				And Object.DepreciationAccrualLocalAccounting = PredefinedValue("Enum.DepreciationAccrualChangeOptions.Valid");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItemAccounting", 
			"", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualLocalAccounting")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepartmentACC", 
			"DepartmentACC", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessBookkeeping", 
			"LineOfBusinessBookkeeping", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAccrualMan")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting")
		Or UpdateAll Then

		PropertyValue = 
			Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitManagementAccounting", 
			"BusinessUnitManagementAccounting", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LineOfBusinessManagementAccounting", 
			"LineOfBusinessManagementAccounting", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.ReceiveLeasedAssets, FormDataStructure - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters
Function PropertyValuesOfDependentProps_ReceiptOfLeasedFA(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"GLAccount", 
			"GLAccount", 
			"Visible", 
			Not AuxiliaryAttributes.CAAccounting24IsUsed, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FinancialAccountingGroup", 
			"FinancialAccountingGroup", 
			"Visible", 
			AuxiliaryAttributes.CAAccounting24IsUsed, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FINANCIALLYLIABLEPERSON", 
			"FINANCIALLYLIABLEPERSON", 
			"Visible", 
			AuxiliaryAttributes.CAAccounting24IsUsed, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Contract", 
			"Contract", 
			"Visible", 
			AuxiliaryAttributes.CAAccounting24IsUsed, 
			ItemDetailsParameters);
			
	EndIf;
	
	Return ItemDetailsParameters;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.ReceivingLeaseServices - 
// 	AuxiliaryAttributes - Structure - 
// 	ChangedBankingDetails - String - 
// Returns:
// 	Array of See TMCommonUseClientServer.AddItemDetailsParameters 
Function PropertyValuesOfDependentDetails_ReceiptOfRentalServices(Object, AuxiliaryAttributes, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		PropertyValue = 
			ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
			Or ContractDetails_.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Accruals.Department", 
			"AccrualsDepartment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Accruals.ExpenseItem", 
			"AccrualsExpenseItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Accruals.DimensionOfExpenses", 
			"AccrualsDimensionOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Accruals.AssetsLiabilitiesDimension", 
			"AccrualsAssetsLiabilitiesDimension", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Accruals.LineOfBusiness", 
			"AccrualsLineOfBusiness", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
			
	Return ItemDetailsParameters;

EndFunction

Function FARedemptionParameters(Object, AuxiliaryAttributes)

	FARedemptionParameters = New Structure;
	LeasedAssetAccountingClientServerLocalization.AddFARedemptionParameters(Object, AuxiliaryAttributes, FARedemptionParameters);
	
	Return FARedemptionParameters;
	
EndFunction

Procedure AddPropertyValuesForDependentProps__(Object, AuxiliaryAttributes, StructureOfChangedProps, ItemDetailsParameters)

	UpdateAll = StructureOfChangedProps.Count() = 0;

	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;

	ChangingConditions = ThisIsChangeInTermsOfLease(Object);
	
	AccountingForBalanceSheet = 
		ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
		And Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
	
	ByActualCost = (ContractDetails_.MethodForDeterminingCostOfAssets = 
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually"));
	
	Discounting = (ContractDetails_.MethodForDeterminingCostOfAssets = 
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Discounting"));
			
	WithoutDiscounting = (ContractDetails_.MethodForDeterminingCostOfAssets = 
		PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount"));
	
	PathToFACostDetails = 
		AuxiliaryAttributes.NameOfFATablePart 
		+ ?(ValueIsFilled(AuxiliaryAttributes.NameOfFATablePart), ".", "");
		
	PathToFACostItems = AuxiliaryAttributes.NameOfFATablePart;
	
	#Region PagePaymentsUnderTheContract
	If StructureOfChangedProps.Property("DocumentVersion24") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			Not AuxiliaryAttributes.DocumentVersion24
			And AuxiliaryAttributes.RecordInOperationalAccounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseStartDate", 
			"", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstPayment", 
			"DateOfFirstPayment", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutDate", 
			"BuyoutDate", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServicePaymentSchedule", 
			"", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServiceAccrualSchedule", 
			"", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);

		PropertyValue = 
			Not AuxiliaryAttributes.DocumentVersion24
			And Not ChangingConditions
			And AuxiliaryAttributes.RecordInOperationalAccounting;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseServicesAmount", 
			"LeaseServicesAmount", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"SecurityDepositAmount", 
			"SecurityDepositAmount", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstSecurityPayment", 
			"DateOfFirstSecurityPayment", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then

		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"LeaseServicesAmount", 
			"LeaseServicesAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstPayment", 
			"DateOfFirstPayment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATAmount", 
			"VATAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATRate", 
			"VATRate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"PaymentFrequency", 
			"PaymentFrequency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccrualFrequency", 
			"AccrualFrequency", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And ContractDetails_.HasSecurityDeposit
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
				
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SecurityDepositAmount", 
			"SecurityDepositAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DateOfFirstSecurityPayment", 
			"DateOfFirstSecurityPayment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And ContractDetails_.ThereIsBuyoutOfLeasedAssets
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AmountOfLeaseAssetsByuout", 
			"AmountOfLeaseAssetsByuout", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AmountOfVATRepurchaseOfRentalItems", 
			"AmountOfVATRepurchaseOfRentalItems", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		TMCommonUseClientServer.AddItemDetailsParameters(
			"BuyoutDate", 
			"BuyoutDate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("DocumentVersion24") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or UpdateAll Then
			
		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting 
			And Not AuxiliaryAttributes.DocumentVersion24
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATRate", 
			"VATRate", 
			"AutoMarkIncomplete", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("PaymentFrequency")
		Or StructureOfChangedProps.Property("ServicePaymentSchedule")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")		
		Or UpdateAll Then

		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
			And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.EmptyRef")
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PaymentForLeaseService", 
			"PaymentForLeaseService", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("AccrualFrequency")
		Or StructureOfChangedProps.Property("ServiceAccrualSchedule")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")		
		Or UpdateAll Then

		PropertyValue =
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
			And Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.EmptyRef")
			And (AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AccrualOfLeaseService", 
			"AccrualOfLeaseService", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("VATRate")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then

		TMCommonUseClientServer.AddItemDetailsParameters(
			"VATAmount", 
			"VATAmount", 
			"OnlyViewWithoutBlankMark", 
			AuxiliaryAttributes.InsignificantVATRate, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AmountOfVATRepurchaseOfRentalItems", 
			"AmountOfVATRepurchaseOfRentalItems", 
			"ReadOnly", 
			AuxiliaryAttributes.InsignificantVATRate, 
			ItemDetailsParameters);
		
		If Not AuxiliaryAttributes.InsignificantVATRate Then
			PropertyValue = Not ChangingConditions;
			TMCommonUseClientServer.AddItemDetailsParameters(
				"VATAmount", 
				"VATAmount", 
				"AutoMarkIncomplete", 
				PropertyValue, 
				ItemDetailsParameters);
		EndIf;
			
	EndIf;

	#EndRegion
	
	#Region FixedAssetsPage

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not WithoutDiscounting
			And ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
			And ByActualCost;
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			PathToFACostDetails + "NonGuaranteedFinalCost", 
			PathToFACostItems + "NonGuaranteedFinalCost", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And (ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
				Or (WithoutDiscounting And ValueIsFilled(PathToFACostDetails)));
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			PathToFACostDetails + "FairValue", 
			PathToFACostItems + "FairValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And (ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
				Or WithoutDiscounting);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			PathToFACostDetails + "Cost", 
			PathToFACostItems + "Cost", 
			"OnlyViewWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			PathToFACostDetails + "Cost", 
			PathToFACostItems + "Cost", 
			"AutoMarkIncomplete", 
			Not PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	#EndRegion
	
	#Region DiscountingPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Not WithoutDiscounting;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestAmount", 
			"InterestAmount", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestRate", 
			"InterestRate", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"PresentValue", 
			"PresentValue", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And ByActualCost
			And Not WithoutDiscounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestRate", 
			"InterestRate", 
			"OnlyViewWithoutClearing", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	#EndRegion
	
	#Region PaymentAndAccrualSchedule
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
	
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And ContractDetails_.HasSecurityDeposit;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServicePaymentSchedule.DepositPayment", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServiceAccrualSchedule.DepositPayment", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//	
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And ContractDetails_.ThereIsBuyoutOfLeasedAssets;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ServicePaymentSchedule.BuyoutValue", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And Not WithoutDiscounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"InterestAccrualSchedule", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

	EndIf;

	#EndRegion
	
EndProcedure

#EndRegion

#Region Other

// Determines which accounts are considered subjects of the lease.
// 
// Parameters:
// 	LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// 	ContractDetails_ - Structure - Contains Properties:
// 		* AssetHolder - EnumRef.LeasedAssetHolder -
// 		* RecognizeLeasedAssetsInManagementAccounting - Boolean -
// 		* RecognizeLeasedItemsInLocalAccounting - Boolean -
// 		
// Returns:
// 	Structure - LongDesc:
// 		* ThereIsMaAccount - Boolean - True if rental items are accounted for in the administrative accounting
// 		* ThereIsACAccounting - Boolean - True if the subjects of the lease are accounted for in the wham. accounting
// 		* ThereIsAccountingTa - Boolean - True if the subjects of the lease are recorded in the tax records
Function AccountingParametersForRentalItems(LeaseAccountingAccordingToFSB25_2018IsUsed, ContractDetails_) Export

	AccountingParametersForRentalItems = New Structure;
	
	ParameterValue = 
		Not LeaseAccountingAccordingToFSB25_2018IsUsed
			And ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder")
		Or LeaseAccountingAccordingToFSB25_2018IsUsed
			And ContractDetails_.RecognizeLeasedAssetsInManagementAccounting = True;
	AccountingParametersForRentalItems.Insert("ThereIsMaAccount", ParameterValue);
	
	ParameterValue = 
		Not LeaseAccountingAccordingToFSB25_2018IsUsed
			And ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder")
		Or LeaseAccountingAccordingToFSB25_2018IsUsed
			And ContractDetails_.RecognizeLeasedItemsInLocalAccounting = True;
	AccountingParametersForRentalItems.Insert("ThereIsACAccounting", ParameterValue);
	
	ParameterValue = 
		ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder")
		And ContractDetails_.RecognizeLeasedItemsInLocalAccounting = True;
	AccountingParametersForRentalItems.Insert("ThereIsAccountingTa", ParameterValue);
	
	Return AccountingParametersForRentalItems;
	
EndFunction

// Generates summary data for charts.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
// 	ContractDetails_ - Structure - 
// 	
// Returns:
// 	Structure - Contains Properties:
// 		* ServicePaymentSchedule - See ServicePaymentScheduleParameters
// 		* ServiceAccrualSchedule - See ParametersOfServiceAccrualSchedule
// 		* ChartsAreFilled - Boolean -
Function SchedulesData(Object, ContractDetails_) Export
	
	ChangingConditions = ThisIsChangeInTermsOfLease(Object);
	StartDate = ?(ChangingConditions, BegOfDay(Object.Date), Object.LeaseStartDate);
	
	ServicePaymentScheduleParameters = ServicePaymentScheduleParameters(Object.ServicePaymentSchedule, 
															StartDate);
	
	ParametersOfServiceAccrualSchedule = ParametersOfServiceAccrualSchedule(Object.ServiceAccrualSchedule, 
																		Object.AmountOfVATRepurchaseOfRentalItems,
																		StartDate);
	
	ChartsAreFilled = 
		Object.ServicePaymentSchedule.Count() <> 0
		Or Object.ServiceAccrualSchedule.Count() <> 0;
		
	SchedulesData = New Structure;
	SchedulesData.Insert("ServicePaymentSchedule", ServicePaymentScheduleParameters);
	SchedulesData.Insert("ServiceAccrualSchedule", ParametersOfServiceAccrualSchedule);
	SchedulesData.Insert("ChartsAreFilled", ChartsAreFilled);
		
	Return SchedulesData;
	
EndFunction

// Defines the parameters of the payment schedule for services.
// 
// Parameters:
//  ServicePaymentSchedule - DocumentTabularSection.SigningOfLeaseContract.ServicePaymentSchedule, DocumentTabularSection.LeaseTermAdjustment.ServicePaymentSchedule - Service payment schedule
//  StartDate - Date - Date of lease change.
// 
// Returns:
//  Structure - Service Payment Schedule Parameters:
// 		* TotalRentalService_ - Number -
// 		* TotalSecurityPayment - Number -
// 		* TotalRedemptionValue - Number -
// 		* TotalAmountOfVATPurchaseOfRentalItems - Number -
// 		* DateOfFirstSecurityPayment - Date -
// 		* DateOfFirstPayment - Date -
// 		* PaymentForLeaseService - Number -
// 		* Periodicity - Undefined -
Function ServicePaymentScheduleParameters(ServicePaymentSchedule, StartDate) Export

	ScheduleParameters = New Structure;
	ScheduleParameters.Insert("TotalRentalService_", 0);
	ScheduleParameters.Insert("TotalSecurityPayment", 0);
	ScheduleParameters.Insert("TotalRedemptionValue", 0);
	ScheduleParameters.Insert("TotalAmountOfVATPurchaseOfRentalItems", 0);
	ScheduleParameters.Insert("DateOfFirstSecurityPayment", '000101010000');
	ScheduleParameters.Insert("DateOfFirstPayment", '000101010000');
	ScheduleParameters.Insert("PaymentForLeaseService", 0);
	ScheduleParameters.Insert("PaymentOfRedemptionValue", 0);
	ScheduleParameters.Insert("Periodicity", Undefined);
	ScheduleParameters.Insert("SecurityPaymentAfterChanges", 0);
	ScheduleParameters.Insert("RentalServiceAfterChanges", 0);
	ScheduleParameters.Insert("RedemptionCostAfterChanges", 0);
	ScheduleParameters.Insert("VATAmountOfPurchaseOfRentalItemsAfterChanges", 0);

	PreviousDate = Undefined;
	
	For Each PlotLine In ServicePaymentSchedule Do
		
		// DateOfFirstSecurityPayment
		If ValueIsFilled(PlotLine.Date)
			And PlotLine.DepositPayment <> 0 Then
				
			ScheduleParameters.DateOfFirstSecurityPayment = 
				?(ScheduleParameters.DateOfFirstSecurityPayment <> '000101010000', 
					Min(PlotLine.Date, ScheduleParameters.DateOfFirstSecurityPayment), 
					PlotLine.Date);
					
		EndIf;
		
		// Totals
		ScheduleParameters.TotalRentalService_ = ScheduleParameters.TotalRentalService_ + PlotLine.RentalService;
		ScheduleParameters.TotalSecurityPayment = ScheduleParameters.TotalSecurityPayment + PlotLine.DepositPayment;
		ScheduleParameters.TotalRedemptionValue = ScheduleParameters.TotalRedemptionValue + PlotLine.BuyoutValue;
		ScheduleParameters.TotalAmountOfVATPurchaseOfRentalItems = ScheduleParameters.TotalAmountOfVATPurchaseOfRentalItems + PlotLine.BuyoutValueVAT;
		
		If PlotLine.Date >= StartDate Then
			
			ScheduleParameters.SecurityPaymentAfterChanges = ScheduleParameters.SecurityPaymentAfterChanges
				+ PlotLine.DepositPayment;
			ScheduleParameters.RentalServiceAfterChanges = ScheduleParameters.RentalServiceAfterChanges + PlotLine.RentalService;
			ScheduleParameters.RedemptionCostAfterChanges = ScheduleParameters.RedemptionCostAfterChanges + PlotLine.BuyoutValue;
			ScheduleParameters.VATAmountOfPurchaseOfRentalItemsAfterChanges = ScheduleParameters.VATAmountOfPurchaseOfRentalItemsAfterChanges + PlotLine.BuyoutValueVAT;
			
			// DateOfFirstPayment
			If ValueIsFilled(PlotLine.Date)
				And PlotLine.RentalService <> 0 Then

				ScheduleParameters.DateOfFirstPayment = 
				?(ScheduleParameters.DateOfFirstPayment <> '000101010000', 
				Min(PlotLine.Date, ScheduleParameters.DateOfFirstPayment), 
				PlotLine.Date);

			EndIf;

			// The periodic amount of payment for the amount of services
			If PlotLine.RentalService <> 0
				And ScheduleParameters.PaymentForLeaseService <> 0
				And ScheduleParameters.PaymentForLeaseService <> Undefined
				And ScheduleParameters.PaymentForLeaseService <> PlotLine.RentalService Then

				ScheduleParameters.PaymentForLeaseService = Undefined; // Arbitrary amounts

			ElsIf PlotLine.RentalService <> 0
				And ScheduleParameters.PaymentForLeaseService <> Undefined Then

				ScheduleParameters.PaymentForLeaseService = PlotLine.RentalService;		
			EndIf;

			// The periodic amount of the redemption payment
			If PlotLine.BuyoutValue <> 0
				And ScheduleParameters.PaymentOfRedemptionValue <> 0
				And ScheduleParameters.PaymentOfRedemptionValue <> Undefined
				And ScheduleParameters.PaymentOfRedemptionValue <> PlotLine.BuyoutValue Then

				ScheduleParameters.PaymentOfRedemptionValue = Undefined; // Arbitrary amounts

			ElsIf PlotLine.BuyoutValue <> 0
				And ScheduleParameters.PaymentOfRedemptionValue <> Undefined Then

				ScheduleParameters.PaymentOfRedemptionValue = PlotLine.BuyoutValue;		
			EndIf;

			// Periodicity
			If ScheduleParameters.PaymentForLeaseService <> Undefined
				And PlotLine.RentalService <> 0
				And ScheduleParameters.Periodicity <> PredefinedValue("Enum.ScheduleTimeFence.Custom") Then

				If PreviousDate <> Undefined Then

					Periodicity = ScheduleTimeFence(PreviousDate, PlotLine.Date);

					If ScheduleParameters.Periodicity = Undefined Then
						ScheduleParameters.Periodicity = Periodicity;
					ElsIf ScheduleParameters.Periodicity <> Periodicity Then
						ScheduleParameters.Periodicity = PredefinedValue("Enum.ScheduleTimeFence.Custom");
					EndIf;

				EndIf;

				PreviousDate = PlotLine.Date;

			ElsIf ScheduleParameters.PaymentForLeaseService = Undefined Then

				ScheduleParameters.Periodicity = PredefinedValue("Enum.ScheduleTimeFence.Custom");

			EndIf;
			
		EndIf;	

	EndDo;
	
	Return ScheduleParameters;
	
EndFunction

// Defines the parameters of the service accrual schedule.
// 
// Parameters:
//  ServiceAccrualSchedule - DocumentTabularSection.SigningOfLeaseContract.ServiceAccrualSchedule, DocumentTabularSection.LeaseTermAdjustment.ServiceAccrualSchedule - Service accrual schedule
//  AmountOfVATRepurchaseOfRentalItems - Number - 
//  StartDate - Date - Date of lease change.
// 
// Returns:
//  Structure - Service Payment Schedule Parameters:
// 		* TotalRentalService_ - Number -
// 		* TotalSecurityPayment - Number -
// 		* TotalAmountOfVAT_ - Number -
// 		* AccrualOfLeaseService - Number -
// 		* Periodicity - Undefined -
Function ParametersOfServiceAccrualSchedule(ServiceAccrualSchedule, AmountOfVATRepurchaseOfRentalItems, StartDate) Export
	
	ScheduleParameters = New Structure;
	ScheduleParameters.Insert("TotalRentalService_", 0);
	ScheduleParameters.Insert("TotalSecurityPayment", 0);
	ScheduleParameters.Insert("TotalAmountOfVAT_", 0);
	ScheduleParameters.Insert("AccrualOfLeaseService", 0);
	ScheduleParameters.Insert("Periodicity", Undefined);
	ScheduleParameters.Insert("SecurityPaymentAfterChanges", 0);
	ScheduleParameters.Insert("RentalServiceAfterChanges", 0);
	ScheduleParameters.Insert("VATAmountAfterChanges", 0);
	
	PreviousDate = Undefined;
	
	For Each PlotLine In ServiceAccrualSchedule Do
		
		ScheduleParameters.TotalRentalService_ = ScheduleParameters.TotalRentalService_ + PlotLine.RentalService;
		ScheduleParameters.TotalSecurityPayment = ScheduleParameters.TotalSecurityPayment + PlotLine.DepositPayment;
		ScheduleParameters.TotalAmountOfVAT_ = ScheduleParameters.TotalAmountOfVAT_ + PlotLine.RentalServiceVAT + PlotLine.SecurityPaymentVATAmount;
			
		If PlotLine.Date >= StartDate Then
			
			ScheduleParameters.SecurityPaymentAfterChanges = ScheduleParameters.SecurityPaymentAfterChanges
				+ PlotLine.DepositPayment;
			ScheduleParameters.RentalServiceAfterChanges = ScheduleParameters.RentalServiceAfterChanges + PlotLine.RentalService;
			ScheduleParameters.VATAmountAfterChanges = ScheduleParameters.VATAmountAfterChanges + PlotLine.RentalServiceVAT + PlotLine.SecurityPaymentVATAmount;
			
			// The periodic amount of payment for the amount of services
			If PlotLine.RentalService <> 0
				And ScheduleParameters.AccrualOfLeaseService <> 0
				And ScheduleParameters.AccrualOfLeaseService <> Undefined
				And ScheduleParameters.AccrualOfLeaseService <> PlotLine.RentalService Then

				ScheduleParameters.AccrualOfLeaseService = Undefined; // Arbitrary amounts

			ElsIf PlotLine.RentalService <> 0
				And ScheduleParameters.AccrualOfLeaseService <> Undefined Then

				ScheduleParameters.AccrualOfLeaseService = PlotLine.RentalService;
			EndIf;
			
			// Periodicity
			If ScheduleParameters.AccrualOfLeaseService <> Undefined
				And PlotLine.RentalService <> 0
				And ScheduleParameters.Periodicity <> PredefinedValue("Enum.ScheduleTimeFence.Custom") Then

				If PreviousDate <> Undefined Then

					Periodicity = ScheduleTimeFence(PreviousDate, PlotLine.Date);

					If ScheduleParameters.Periodicity = Undefined Then
						ScheduleParameters.Periodicity = Periodicity;
					ElsIf ScheduleParameters.Periodicity <> Periodicity Then
						ScheduleParameters.Periodicity = PredefinedValue("Enum.ScheduleTimeFence.Custom");
					EndIf;

				EndIf;

				PreviousDate = PlotLine.Date;

			ElsIf ScheduleParameters.AccrualOfLeaseService = Undefined Then

				ScheduleParameters.Periodicity = PredefinedValue("Enum.ScheduleTimeFence.Custom");

			EndIf;
			
		EndIf;

	EndDo;
	
	ScheduleParameters.TotalAmountOfVAT_ = ScheduleParameters.TotalAmountOfVAT_ + AmountOfVATRepurchaseOfRentalItems;
	ScheduleParameters.VATAmountAfterChanges = ScheduleParameters.VATAmountAfterChanges + AmountOfVATRepurchaseOfRentalItems;
	
	Return ScheduleParameters;
	
EndFunction

// Specifies the next date.
// 
// Parameters:
// 	CurrentDate - Date - 
// 	ScheduleTimeFence - EnumRef.ScheduleTimeFence -
// 	 
// Returns:
// 	Date - 
Function NextScheduleDate(CurrentDate, ScheduleTimeFence) Export
	
	If CurrentDate = BegOfMonth(CurrentDate) Then
		DateView = "BegOfMonth";
	ElsIf EndOfDay(CurrentDate) = EndOfMonth(CurrentDate) Then
		DateView = "EndOfMonth";
	Else
		DateView = "Day";
	EndIf;

	StartDate_Day = Day(CurrentDate);

	If ScheduleTimeFence = PredefinedValue("Enum.ScheduleTimeFence.Day") Then
		
		NextDate = BegOfDay(CurrentDate) + 86400;
		
	ElsIf ScheduleTimeFence = PredefinedValue("Enum.ScheduleTimeFence.Week") Then
		
		NextDate = BegOfDay(CurrentDate) + 604800;
	
	ElsIf ScheduleTimeFence = PredefinedValue("Enum.ScheduleTimeFence.Month") Then
		
		NextDate = AddMonth(BegOfMonth(CurrentDate), 1);
		
		If DateView = "EndOfMonth" Then
			NextDate = EndOfMonth(NextDate);
		ElsIf DateView = "Day" Then
			NextDate = NextDate + 86400 * (StartDate_Day - 1);
		EndIf;
		
		NextDate = BegOfDay(NextDate);
		
	ElsIf ScheduleTimeFence = PredefinedValue("Enum.ScheduleTimeFence.Quarter") Then
		
		NextDate = AddMonth(BegOfMonth(CurrentDate), 3);
	
		If DateView = "EndOfMonth" Then
			NextDate = EndOfMonth(NextDate);
		ElsIf DateView = "Day" Then
			NextDate = NextDate + 86400 * (StartDate_Day - 1);
		EndIf;

		NextDate = BegOfDay(NextDate);

	ElsIf ScheduleTimeFence = PredefinedValue("Enum.ScheduleTimeFence.HalfYear") Then

		NextDate = AddMonth(BegOfMonth(CurrentDate), 6);
	
		If DateView = "EndOfMonth" Then
			NextDate = EndOfMonth(NextDate);
		ElsIf DateView = "Day" Then
			NextDate = NextDate + 86400 * (StartDate_Day - 1);
		EndIf;

		NextDate = BegOfDay(NextDate);

	ElsIf ScheduleTimeFence = PredefinedValue("Enum.ScheduleTimeFence.Year") Then

		NextDate = AddMonth(BegOfMonth(CurrentDate), 12);
	
		If DateView = "EndOfMonth" Then
			NextDate = EndOfMonth(NextDate);
		ElsIf DateView = "Day" Then
			NextDate = NextDate + 86400 * (StartDate_Day - 1);
		EndIf;
		
		NextDate = BegOfDay(NextDate);

	Else
		
		NextDate = '000101010000';
		
	EndIf;
	
	Return NextDate;
	
EndFunction

// Checks the compliance of calculations and the schedule of payments and accruals.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
// 	ContractDetails_ - Structure -
// 	StartOfLeaseAccountingUnderFSB25_2018 - Date - 
// 	DocumentCurrencyPresentation - String -
// 	
// Returns:
// 	Structure - Contains Properties:
// 		* SecurityDepositAmount - String, Undefined -
// 		* LeaseServicesAmount - String, Undefined -
// 		* AmountOfLeaseAssetsByuout - String, Undefined -
// 		* VATAmount - String, Undefined -
// 		* DateOfFirstSecurityPayment - String, Undefined -
// 		* DateOfFirstPayment - String, Undefined -
// 		* PaymentFrequency - String, Undefined -
// 		* AccrualFrequency - String, Undefined -
// 		* PaymentForLeaseService - String, Undefined -
// 		* AccrualOfLeaseService - String, Undefined -
// 		* ThereAreDiscrepancies - Boolean -
Function CheckComplianceOfGraphs(Object, ContractDetails_, StartOfLeaseAccountingUnderFSB25_2018, 
										DocumentCurrencyPresentation) Export
	
	SchedulesData = SchedulesData(Object, ContractDetails_);
	ChangingConditions = LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object);
	CreatedForTransition = EndOfDay(Object.Date) + 1 = StartOfLeaseAccountingUnderFSB25_2018;
	
	CheckResult = New Structure;
	CheckResult.Insert("SecurityDepositAmount", Undefined);
	CheckResult.Insert("LeaseServicesAmount", Undefined);
	CheckResult.Insert("AmountOfLeaseAssetsByuout", Undefined);
	CheckResult.Insert("VATAmount", Undefined);
	CheckResult.Insert("AmountOfVATRepurchaseOfRentalItems", Undefined);
	CheckResult.Insert("DateOfFirstSecurityPayment", Undefined);
	CheckResult.Insert("DateOfFirstPayment", Undefined);
	CheckResult.Insert("BuyoutDate", Undefined);
	CheckResult.Insert("PaymentFrequency", Undefined);
	CheckResult.Insert("AccrualFrequency", Undefined);
	CheckResult.Insert("PaymentForLeaseService", Undefined);
	CheckResult.Insert("AccrualOfLeaseService", Undefined);
	CheckResult.Insert("ChartDiscrepancies", Undefined);
	CheckResult.Insert("ThereAreDiscrepancies", False);
	
	If Not SchedulesData.ChartsAreFilled Then
		Return CheckResult;
	EndIf;
	
	If Not ChangingConditions Then
		// SecurityDepositAmount
		CheckResult.SecurityDepositAmount = GenerateTextForCheckingAmountOfGraph(
		Object.SecurityDepositAmount, 
		SchedulesData.ServicePaymentSchedule.TotalSecurityPayment, 
		SchedulesData.ServiceAccrualSchedule.TotalSecurityPayment, 
		DocumentCurrencyPresentation);
		
		// LeaseServicesAmount 
		CheckResult.LeaseServicesAmount = GenerateTextForCheckingAmountOfGraph(
		Object.LeaseServicesAmount, 
		SchedulesData.ServicePaymentSchedule.TotalRentalService_, 
		SchedulesData.ServiceAccrualSchedule.TotalRentalService_, 
		DocumentCurrencyPresentation);
		
		// AmountOfLeaseAssetsByuout 
		CheckResult.AmountOfLeaseAssetsByuout = GenerateTextForCheckingAmountOfGraph(
		Object.AmountOfLeaseAssetsByuout, 
		SchedulesData.ServicePaymentSchedule.TotalRedemptionValue, 
		Object.AmountOfLeaseAssetsByuout, 
		DocumentCurrencyPresentation);
		
		// SummaNDS, summandswycupsreferences
		If ValueIsFilled(Object.VATRate) Then
			
			CheckResult.VATAmount = GenerateTextForCheckingAmountOfGraph(
				Object.VATAmount,
				Object.VATAmount,
				SchedulesData.ServiceAccrualSchedule.TotalAmountOfVAT_,
				DocumentCurrencyPresentation);
			
			CheckResult.AmountOfVATRepurchaseOfRentalItems = GenerateTextForCheckingAmountOfGraph(
				Object.AmountOfVATRepurchaseOfRentalItems,
				SchedulesData.ServicePaymentSchedule.TotalAmountOfVATPurchaseOfRentalItems,
				Object.AmountOfVATRepurchaseOfRentalItems,
				DocumentCurrencyPresentation);
			
		EndIf;
		
	Else
		
		//LeaseServicesAmount
		If Object.LeaseServicesAmount <> SchedulesData.ServiceAccrualSchedule.RentalServiceAfterChanges Then
			
			VerificationText = NStr("vi = 'Số tiền dịch vụ thuê không trùng với lịch biểu tính lãi:
			|  - số tiền theo lịch biểu tính là %1 %2';
			|ru = 'Сумма услуг по аренде не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|en = 'The rental service amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2'; fa = 'The rental service amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|it = 'Сумма услуг по аренде не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|pl = 'The rental service amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|tr = 'Kiralama hizmetlerinin tutarı tahakkuk planına uymuyor:
			| - tahakkuk planına göre tutar %1 %2'");
			VerificationText = StrTemplate(VerificationText, 
									Format(SchedulesData.ServiceAccrualSchedule.RentalServiceAfterChanges, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
			CheckResult.LeaseServicesAmount = VerificationText;
		EndIf;
		
		//The amount of services according to the schedules
		If SchedulesData.ServicePaymentSchedule.TotalRentalService_ <> SchedulesData.ServiceAccrualSchedule.TotalRentalService_ Then
			
			VerificationText = NStr("vi = 'Tổng số tiền dịch vụ theo lịch biểu thanh toán không trùng với lịch biểu tính lãi:
			|  - số tiền theo lịch biểu thanh toán là %1 %2
			|  - số tiền theo lịch biểu tính là %3 %4';
			|ru = 'Итоговая сумма услуг по графику оплат не совпадает с графиком начислений:
			|  - по графику оплат сумма %1 %2
			|  - по графику начислений сумма %3 %4';
			|en = 'The total service amount according to the payment schedule does not match the accruals schedule:
			| - according to the payment schedule, the amount is %1 %2
			| - according to the accruals schedule, the amount is %3 %4'; fa = 'The total service amount according to the payment schedule does not match the accruals schedule:
			| - according to the payment schedule, the amount is %1 %2
			| - according to the accruals schedule, the amount is %3 %4';
			|it = 'Итоговая сумма услуг по графику оплат не совпадает с графиком начислений:
			|  - по графику оплат сумма %1 %2
			|  - по графику начислений сумма %3 %4';
			|pl = 'The total service amount according to the payment schedule does not match the accruals schedule:
			| - according to the payment schedule, the amount is %1 %2
			| - according to the accruals schedule, the amount is %3 %4';
			|tr = 'Ödeme planına göre hizmetlerin toplam tutarı tahakkuk planına uymuyor:
			| - ödeme planına göre tutar %1 %2
			| - tahakkuk planına göre tutar 44'");
			VerificationText = StrTemplate(VerificationText,
									Format(SchedulesData.ServicePaymentSchedule.TotalRentalService_, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation,
									Format(SchedulesData.ServiceAccrualSchedule.TotalRentalService_, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
			CheckResult.ChartDiscrepancies = VerificationText;
			
		EndIf;
		
		//SecurityDepositAmount
		If Object.SecurityDepositAmount <> SchedulesData.ServiceAccrualSchedule.SecurityPaymentAfterChanges Then
			
			VerificationText = NStr("vi = 'Số tiền thanh toán đảm bảo không trùng với lịch biểu tính lãi:
			|  - số tiền theo lịch biểu tính là %1 %2';
			|ru = 'Сумма обеспечительного платежа не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|en = 'The security deposit amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2'; fa = 'The security deposit amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|it = 'Сумма обеспечительного платежа не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|pl = 'The security deposit amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|tr = 'Depozito tutarı tahakkuk planıyla örtüşmüyor:
			| - tahakkuk planına göre tutar %1 %2'");
			VerificationText = StrTemplate(VerificationText, 
									Format(SchedulesData.ServiceAccrualSchedule.SecurityPaymentAfterChanges, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
			CheckResult.SecurityDepositAmount = VerificationText;
		EndIf;
		
		//The amount of the security payment according to the schedules
		If SchedulesData.ServicePaymentSchedule.TotalSecurityPayment <> SchedulesData.ServiceAccrualSchedule.TotalSecurityPayment Then
			
			VerificationText = NStr("vi = 'Tổng số tiền thanh toán đảm bảo theo lịch biểu thanh toán không trùng với lịch biểu tính lãi:
			|  - số tiền theo lịch biểu thanh toán là %1 %2
			|  - số tiền theo lịch biểu tính là %3 %4';
			|ru = 'Итоговая сумма обеспечительного платежа по графику оплат не совпадает с графиком начислений:
			|  - по графику оплат сумма %1 %2
			|  - по графику начислений сумма %3 %4';
			|en = 'The total security deposit amount according to the payment schedule does not match the accruals schedule:
			| - according to the payment schedule, the amount is %1 %2
			| - according to the accruals schedule, the amount is %3 %4'; fa = 'The total security deposit amount according to the payment schedule does not match the accruals schedule:
			| - according to the payment schedule, the amount is %1 %2
			| - according to the accruals schedule, the amount is %3 %4';
			|it = 'Итоговая сумма обеспечительного платежа по графику оплат не совпадает с графиком начислений:
			|  - по графику оплат сумма %1 %2
			|  - по графику начислений сумма %3 %4';
			|pl = 'The total security deposit amount according to the payment schedule does not match the accruals schedule:
			| - according to the payment schedule, the amount is %1 %2
			| - according to the accruals schedule, the amount is %3 %4';
			|tr = 'Ödeme planına göre teminat ödemesinin nihai tutarı tahakkuk planına uymuyor:
			| - ödeme planına göre tutar %1 %2
			| - tahakkuk planına göre tutar %3 %4'");
			VerificationText = StrTemplate(VerificationText,
									Format(SchedulesData.ServicePaymentSchedule.TotalSecurityPayment, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation,
									Format(SchedulesData.ServiceAccrualSchedule.TotalSecurityPayment, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
			CheckResult.ChartDiscrepancies = VerificationText;
			
		EndIf;
		
		//SecurityDepositAmount
		If Object.AmountOfLeaseAssetsByuout <> SchedulesData.ServicePaymentSchedule.RedemptionCostAfterChanges Then
			
			VerificationText = NStr("vi = 'Số tiền mua lại không trùng với lịch biểu tính lãi:
			|  - số tiền theo lịch biểu tính là %1 %2';
			|ru = 'Сумма выкупа не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|en = 'The buyback amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2'; fa = 'The buyback amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|it = 'Сумма выкупа не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|pl = 'The buyback amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|tr = 'Fidye tutarı tahakkuk planına uymuyor:
			| - tahakkuk planına göre tutar %1 %2'");
			VerificationText = StrTemplate(VerificationText, 
									Format(SchedulesData.ServicePaymentSchedule.RedemptionCostAfterChanges, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
			CheckResult.AmountOfLeaseAssetsByuout = VerificationText;
		EndIf;
		
		If ValueIsFilled(Object.VATRate) Then
			
			//VATAmount
			If Object.VATAmount <> SchedulesData.ServiceAccrualSchedule.VATAmountAfterChanges Then
				
				VerificationText = NStr("vi = 'Số tiền thuế GTGT dịch vụ thuê không trùng với lịch biểu tính:
				|  - số tiền theo lịch biểu tính là %1 %2';
				|ru = 'Сумма НДС услуг по аренде не совпадает с графиком начислений:
				|  - по графику начислений сумма %1 %2';
				|en = 'The rental service VAT amount does not match the accruals schedule:
				| - according to the accruals schedule, the amount is %1 %2'; fa = 'The rental service VAT amount does not match the accruals schedule:
				| - according to the accruals schedule, the amount is %1 %2';
				|it = 'Сумма НДС услуг по аренде не совпадает с графиком начислений:
				|  - по графику начислений сумма %1 %2';
				|pl = 'The rental service VAT amount does not match the accruals schedule:
				| - according to the accruals schedule, the amount is %1 %2';
				|tr = 'Kiralama hizmetlerine ilişkin KDV tutarı tahakkuk planıyla örtüşmüyor:
				| - tahakkuk planına göre tutar %1 %2'");
				VerificationText = StrTemplate(VerificationText, 
				Format(SchedulesData.ServiceAccrualSchedule.VATAmountAfterChanges, "NFD=2; NZ=0;"),
				DocumentCurrencyPresentation);
				CheckResult.VATAmount = VerificationText;
			EndIf;
			
			//AmountOfVATRepurchaseOfRentalItems
			If Object.AmountOfVATRepurchaseOfRentalItems <> SchedulesData.ServicePaymentSchedule.VATAmountOfPurchaseOfRentalItemsAfterChanges Then
				
				VerificationText = NStr("vi = 'Số tiền thuế GTGT mua không trùng với lịch thanh toán:
				|  - số tiền theo lịch thanh toán là %1 %2';
				|ru = 'Сумма НДС выкупа не совпадает с графиком оплат:
				|  - по графику оплат сумма %1 %2';
				|en = 'The buyback VAT amount does not match the payment schedule:
				| - according to the payment schedule, the amount is %1 %2'; fa = 'The buyback VAT amount does not match the payment schedule:
				| - according to the payment schedule, the amount is %1 %2';
				|it = 'Сумма НДС выкупа не совпадает с графиком оплат:
				|  - по графику оплат сумма %1 %2';
				|pl = 'The buyback VAT amount does not match the payment schedule:
				| - according to the payment schedule, the amount is %1 %2';
				|tr = 'Geri ödemenin KDV tutarı, ödeme planıyla örtüşmüyor:
				| - tutarlar için ödeme planına göre 2'");
				VerificationText = StrTemplate(VerificationText, 
				Format(SchedulesData.ServicePaymentSchedule.VATAmountOfPurchaseOfRentalItemsAfterChanges, "NFD=2; NZ=0;"),
				DocumentCurrencyPresentation);
				CheckResult.AmountOfVATRepurchaseOfRentalItems = VerificationText;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// PaymentForLeaseService
	If ValueIsFilled(Object.PaymentFrequency)
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom") Then
			
		CheckResult.PaymentForLeaseService = GenerateTextForCheckingAmountOfGraph(
							Object.PaymentForLeaseService, 
							SchedulesData.ServicePaymentSchedule.PaymentForLeaseService, 
							Object.PaymentForLeaseService, 
							DocumentCurrencyPresentation);
	EndIf; 
	
	// AccrualOfLeaseService 
	If ValueIsFilled(Object.AccrualFrequency)
		And Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom") Then
			
		CheckResult.AccrualOfLeaseService = GenerateTextForCheckingAmountOfGraph(
							Object.AccrualOfLeaseService, 
							Object.AccrualOfLeaseService, 
							SchedulesData.ServiceAccrualSchedule.AccrualOfLeaseService, 
							DocumentCurrencyPresentation);
	EndIf; 
						
	// PaymentFrequency
	CheckResult.PaymentFrequency = GenerateTextToCheckFrequencyOfSchedule(
	Object.PaymentFrequency, SchedulesData.ServicePaymentSchedule.Periodicity);
	
	// AccrualFrequency
	CheckResult.AccrualFrequency = GenerateTextToCheckFrequencyOfSchedule(
	Object.AccrualFrequency, SchedulesData.ServiceAccrualSchedule.Periodicity);
	
	// DateOfFirstSecurityPayment
	If SchedulesData.ServicePaymentSchedule.DateOfFirstSecurityPayment <> Object.DateOfFirstSecurityPayment
		And SchedulesData.ServicePaymentSchedule.DateOfFirstSecurityPayment <> Undefined Then
			
		VerificationText = NStr("vi = 'Ngày không trùng với lịch biểu thanh toán:
		| - theo lịch biểu ngày %1';
		|ru = 'Дата не совпадает с графиком оплат:
		|  - по графику дата %1';
		|en = 'Date does not match the payment schedule: 
		| - according to the schedule, date is %1'; fa = 'Date does not match the payment schedule: 
		| - according to the schedule, date is %1';
		|it = 'La data non corrisponde al grafico dei pagamenti:
		| - in base al grafico data %1';
		|pl = 'Data nie jest zgodna z harmonogramem płatności:
		|  - wg harmonogramu data %1';
		|tr = 'Tarih ödeme çizelgesiyle örtüşmüyor:
		| - planlanan tarih %1'");
		VerificationText = StrTemplate(VerificationText, Format(SchedulesData.ServicePaymentSchedule.DateOfFirstSecurityPayment, "DLF=D;"));
								
		CheckResult.DateOfFirstSecurityPayment = VerificationText;
	EndIf; 
	
	// DateOfFirstSecurityPayment
	If SchedulesData.ServicePaymentSchedule.DateOfFirstPayment <> Object.DateOfFirstPayment
		And SchedulesData.ServicePaymentSchedule.DateOfFirstPayment <> Undefined Then
			
		VerificationText = NStr("vi = 'Ngày không trùng với lịch biểu thanh toán:
		| - theo lịch biểu ngày %1';
		|ru = 'Дата не совпадает с графиком оплат:
		|  - по графику дата %1';
		|en = 'Date does not match the payment schedule: 
		| - according to the schedule, date is %1'; fa = 'Date does not match the payment schedule: 
		| - according to the schedule, date is %1';
		|it = 'La data non corrisponde al grafico dei pagamenti:
		| - in base al grafico data %1';
		|pl = 'Data nie jest zgodna z harmonogramem płatności:
		|  - wg harmonogramu data %1';
		|tr = 'Tarih ödeme çizelgesiyle örtüşmüyor:
		| - planlanan tarih %1'");
		VerificationText = StrTemplate(VerificationText, Format(SchedulesData.ServicePaymentSchedule.DateOfFirstPayment, "DLF=D;"));
								
		CheckResult.DateOfFirstPayment = VerificationText;
	EndIf; 
	
	CheckResult.ThereAreDiscrepancies =
		CheckResult.SecurityDepositAmount <> Undefined
		Or CheckResult.LeaseServicesAmount <> Undefined
		Or CheckResult.AmountOfLeaseAssetsByuout <> Undefined
		Or CheckResult.VATAmount <> Undefined
		Or CheckResult.AmountOfVATRepurchaseOfRentalItems <> Undefined
		Or CheckResult.DateOfFirstSecurityPayment <> Undefined
		Or CheckResult.DateOfFirstPayment <> Undefined
		Or CheckResult.BuyoutDate <> Undefined
		Or CheckResult.PaymentFrequency <> Undefined
		Or CheckResult.AccrualFrequency <> Undefined
		Or CheckResult.PaymentForLeaseService <> Undefined
		Or CheckResult.AccrualOfLeaseService <> Undefined;
		
	Return CheckResult;
	
EndFunction

// Fills in the VAT amount in the lease document.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
Procedure RecalculateAmountOfNDSInLeaseDocument(Object) Export

	If Not ThisIsChangeInTermsOfLease(Object) Then 
		Object.VATAmount = AmountOfNDSVForRent(
		Object.ServiceAccrualSchedule,
		Object.LeaseServicesAmount, 
		Object.SecurityDepositAmount, 
		Object.AmountOfVATRepurchaseOfRentalItems, 
		Object.VATRate);
	Else
		StartDate = BegOfDay(Object.Date);
		Object.VATAmount = AmountOfNDSInDocumentIsChangeInTermsOfLease(
		Object.ServiceAccrualSchedule,
		Object.LeaseServicesAmount, 
		Object.SecurityDepositAmount, 
		Object.AmountOfVATRepurchaseOfRentalItems, 
		Object.VATRate,
		StartDate);
	EndIf;
	
EndProcedure

// Calculates the VAT amount according to the accrual schedule.
// 
// Parameters:
// 	ServiceAccrualSchedule - FormDataCollection -
// 	LeaseServicesAmount - Number -
// 	SecurityDepositAmount - Number -
// 	AmountOfVATRepurchaseOfRentalItems - Number
// 	VATRate - CatalogRef.VATRates -
// 	  
// Returns:
// 	Number - amount of VAT
Function AmountOfNDSVForRent(ServiceAccrualSchedule, LeaseServicesAmount, SecurityDepositAmount, AmountOfVATRepurchaseOfRentalItems, VATRate) Export

	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	
	If CurPercentVAT = 0 Then
		Return 0;
	EndIf;

	If ServiceAccrualSchedule = Undefined Then
		ServiceAccrualSchedule = ServiceAccrualSchedule;
	EndIf;
	
	VATAmount = 0;
	If ServiceAccrualSchedule.Count() <> 0 Then
		
		For Each PlotLine In ServiceAccrualSchedule Do
			VATAmount = VATAmount + PlotLine.RentalServiceVAT + PlotLine.SecurityPaymentVATAmount;
		EndDo;
		
	Else
	
		VATAmount = 
			VATAccountingERPClientServer.CalculateVATAmount(SecurityDepositAmount, CurPercentVAT, True)
			+ VATAccountingERPClientServer.CalculateVATAmount(LeaseServicesAmount, CurPercentVAT, True);
		
	EndIf;
	
	VATAmount = VATAmount + AmountOfVATRepurchaseOfRentalItems;
					
	Return VATAmount;
	
EndFunction

// Calculates the VAT amount according to the accrual schedule in the document changing the lease terms.
// 
// Parameters:
// 	ServiceAccrualSchedule - FormDataCollection -
// 	LeaseServicesAmount - Number -
// 	SecurityDepositAmount - Number -
// 	AmountOfVATRepurchaseOfRentalItems - Number
// 	VATRate - CatalogRef.VATRates -
// 	SettlementStartDate - Date -
// 	  
// Returns:
// 	Number - amount of VAT
Function AmountOfNDSInDocumentIsChangeInTermsOfLease(ServiceAccrualSchedule, LeaseServicesAmount, SecurityDepositAmount, AmountOfVATRepurchaseOfRentalItems, VATRate, SettlementStartDate) Export
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);

	If CurPercentVAT = 0 Then
		Return 0;
	EndIf;

	If ServiceAccrualSchedule = Undefined Then
		ServiceAccrualSchedule = ServiceAccrualSchedule;
	EndIf;

	VATAmount = 0;
	If ServiceAccrualSchedule.Count() <> 0 Then
		
		For Each PlotLine In ServiceAccrualSchedule Do
			If PlotLine.Date < SettlementStartDate Then
				Continue;
			EndIf;
			VATAmount = VATAmount + PlotLine.RentalServiceVAT + PlotLine.SecurityPaymentVATAmount;
		EndDo;

	Else

		VATAmount = VATAccountingERPClientServer.CalculateVATAmount(LeaseServicesAmount, CurPercentVAT, True)
			+ VATAccountingERPClientServer.CalculateVATAmount(SecurityDepositAmount, CurPercentVAT, True);

	EndIf;

	VATAmount = VATAmount + AmountOfVATRepurchaseOfRentalItems;

	Return VATAmount;

EndFunction

// Fills in the amount and VAT amount in the rental document.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
Procedure RecalculateAmountOfRentalDocument(Object) Export
	
	Object.Sum = 
		Object.LeaseServicesAmount
		+ Object.SecurityDepositAmount
		+ Object.AmountOfLeaseAssetsByuout;

	Object.AmountIncludingVAT = Object.Sum;

EndProcedure

// Calculates the present cost.
// 
// Parameters:
//  LeaseItemsCost - Number - Cost of rental items
//  ServicePaymentSchedule - ValueTable - Service payment schedule
//  LeaseStartDate - Date - Start date of the lease
// 
// Returns:
//  Number
Function PresentValue(LeaseItemsCost, ServicePaymentSchedule, LeaseStartDate) Export
	
	AdvancesBeforeStartOfLeaseWithoutVAT = 0;
		
	For Each PlotLine In ServicePaymentSchedule Do
		
		If PlotLine.Date >= LeaseStartDate Then
			Continue;
		EndIf;
		
		AdvancesBeforeStartOfLeaseWithoutVAT =
			AdvancesBeforeStartOfLeaseWithoutVAT 
			+ PlotLine.DepositPayment - PlotLine.SecurityPaymentVATAmount
			+ PlotLine.RentalService - PlotLine.RentalServiceVAT
			+ PlotLine.BuyoutValue - PlotLine.BuyoutValueVAT;
		
	EndDo;
	
	PresentValue = Max(LeaseItemsCost - AdvancesBeforeStartOfLeaseWithoutVAT, 0);
	
	Return PresentValue;
	
EndFunction

// Calculates the present cost when the terms of the lease Contract change
// 
// Parameters:
//  LeaseItemsCost - Number - Cost of rental items
//  ServicePaymentSchedule - ValueTable - Service payment schedule
//  InterestGraph  - ValueTable - Interest Graph
//  LeaseStartDate - Date - Start date of the lease Contract
//  DateOfLeaseChange - Date - Date of change of the lease Contract
// 
// Returns:
//  Number
Function PresentValueChangeOfConditions(LeaseItemsCost, ServicePaymentSchedule, InterestGraph, LeaseStartDate, DateOfLeaseChange) Export

	AmountOfPaymentsWithoutVAT = 0;
	
	AmountOfPayments = 0;

	For Each PlotLine In ServicePaymentSchedule Do

		If PlotLine.Date < LeaseStartDate Or PlotLine.Date >= DateOfLeaseChange Then
			Continue;
		EndIf;
		
		AmountOfPaymentsWithoutVAT =
			AmountOfPaymentsWithoutVAT 
			+ PlotLine.DepositPayment - PlotLine.SecurityPaymentVATAmount
			+ PlotLine.RentalService - PlotLine.RentalServiceVAT
			+ PlotLine.BuyoutValue - PlotLine.BuyoutValueVAT;

	EndDo; 
	
	InterestAmount = 0;
	
	For Each PlotLine In InterestGraph Do
		
		If PlotLine.Date < LeaseStartDate Or PlotLine.Date >= DateOfLeaseChange Then
			Continue;
		EndIf;
		
		InterestAmount = InterestAmount + PlotLine.Interests;
		
	EndDo;

	PresentValue = Max(LeaseItemsCost - AmountOfPaymentsWithoutVAT + InterestAmount, 0);

	Return PresentValue;

EndFunction

// Determines the cost of rental items.
// 
// Parameters:
//  Object - FormDataStructure
//  ContractDetails_ - See LeasedAssetAccounting.DetailsOfLeaseAgreement
//  NameOfFATablePart - String
// 
// Returns:
//  Number
Function LeaseItemsCost(Object, ContractDetails_, NameOfFATablePart) Export
	
	If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
		And ContractDetails_.MethodForDeterminingCostOfAssets =
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually") Then
		
		If ValueIsFilled(NameOfFATablePart) Then
			If Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
				LeaseItemsCost = Object[NameOfFATablePart].Total("FairValue")
						- Object[NameOfFATablePart].Total("NonGuaranteedFinalCost");
			Else
				LeaseItemsCost = 0;
				For Each FAString In Object[NameOfFATablePart] Do
					If FAString.ActionWithRentalObject = 
						PredefinedValue("Enum.ActionsWithRentalObjects.RentalTermination") Then
						Continue;
					EndIf;
					LeaseItemsCost = LeaseItemsCost + FAString.FairValue - FAString.NonGuaranteedFinalCost;
				EndDo;
			EndIf;
		Else
			LeaseItemsCost = Object.FairValue - Object.NonGuaranteedFinalCost;
		EndIf;
		
	Else
		
		If ValueIsFilled(NameOfFATablePart) Then
			If Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
				LeaseItemsCost = Object[NameOfFATablePart].Total("Cost");
			Else
				LeaseItemsCost = 0;
				For Each FAString In Object[NameOfFATablePart] Do
					If FAString.ActionWithRentalObject = 
						PredefinedValue("Enum.ActionsWithRentalObjects.EarlyRedemption")
							Or FAString.ActionWithRentalObject = 
								PredefinedValue("Enum.ActionsWithRentalObjects.RentalTermination") Then
						Continue;
					EndIf;
					LeaseItemsCost = LeaseItemsCost + FAString.Cost;
				EndDo;
			EndIf
		Else
			LeaseItemsCost = Object.Cost;
		EndIf;
		
	EndIf;

	Return LeaseItemsCost;
		
EndFunction

// Determines the distribution coefficient of the Balance of the present cost when excluding rental items from the Contract.
// 
// Parameters:
//  FATable - ValueTable - FA table
//  ContractDetails_ - See LeasedAssetAccounting.DetailsOfLeaseAgreement
// 
// Returns:
//  Number
Function CostSharingRatio(FATable, ContractDetails_) Export
	
	If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
		And ContractDetails_.MethodForDeterminingCostOfAssets
			= PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually") Then
		CalculationOfFairCost = True;
	Else
		CalculationOfFairCost = False;
	EndIf;
	
	TotalCost = 0;
	CostOfNonExclusiveFA = 0;
	For Each FAString In FATable Do
		
		If FAString.ActionWithRentalObject
			= PredefinedValue("Enum.ActionsWithRentalObjects.Rent") Then
			Continue;
		EndIf;
		
		If FAString.ActionWithRentalObject
			= PredefinedValue("Enum.ActionsWithRentalObjects.RentalTermsAdjustment") Then
			If CalculationOfFairCost Then
				CostOfNonExclusiveFA = CostOfNonExclusiveFA + FAString.FairValue - FAString.NonGuaranteedFinalCost;
			Else
				CostOfNonExclusiveFA = CostOfNonExclusiveFA + FAString.Cost;
			EndIf;
		EndIf;
		
		If CalculationOfFairCost Then
			TotalCost = TotalCost + FAString.FairValue - FAString.NonGuaranteedFinalCost;
		Else
			TotalCost = TotalCost + FAString.Cost;
		EndIf;
		
	EndDo;
	
	DistributionCoefficient = ?(TotalCost <> 0, CostOfNonExclusiveFA / TotalCost, 1);
	
	Return DistributionCoefficient;

EndFunction

// Determines the cost of added rental items
// 
// Parameters:
//  FATable - ValueTable -  FA table
// 
// Returns:
//  Number
Function CostOfAddedRentalItems(FATable) Export

	LeaseItemsCost = 0;
	
	For Each FAString In FATable Do
		
		If FAString.ActionWithRentalObject = 
			PredefinedValue("Enum.ActionsWithRentalObjects.Rent") Then
			LeaseItemsCost = LeaseItemsCost + FAString.Cost;
		EndIf;
		
	EndDo;
	
	Return LeaseItemsCost;

EndFunction

// Determines the amount of payments excluding VAT.
// 
// Parameters:
//  ServicePaymentSchedule - ValueTable - Service payment schedule
//  LeaseStartDate - Date - Start date of the lease Contract
//  VATRate - CatalogRef.VATRates - VAT rate
// 
// Returns:
//  Number
Function TotalPaymentsExcludingVAT(ServicePaymentSchedule, LeaseStartDate, VATRate) Export
	
	TotalPaymentsExcludingVAT = 0;
	VATPercentage = Undefined;
	
	For Each OriginalGraphLine In ServicePaymentSchedule Do		
		
		If OriginalGraphLine.Date < LeaseStartDate Then
			Continue;
		EndIf;
		
		If VATPercentage = Undefined Then
			VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
		EndIf;
		
		TotalPaymentsExcludingVAT =
			TotalPaymentsExcludingVAT 
			+ OriginalGraphLine.RentalService -  OriginalGraphLine.RentalServiceVAT
			+ OriginalGraphLine.DepositPayment - OriginalGraphLine.SecurityPaymentVATAmount
			+ OriginalGraphLine.BuyoutValue - OriginalGraphLine.BuyoutValueVAT;
			
	EndDo;
	
	Return TotalPaymentsExcludingVAT;
	
EndFunction

// Determines whether an item is associated with a change in the lease Contract
// 
// Parameters:
//  Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment, DocumentObject.OBEntryOfLeaseSettlements -
// 
// Returns:
//  Boolean
Function ThisIsChangeInTermsOfLease(Object) Export
	
	ThisIsChangeInTermsOfLease = False;
	
	If TypeOf(Object) = Type("FormDataStructure") Then 
		ThisIsChangeInTermsOfLease = TypeOf(Object.Ref) = Type("DocumentRef.LeaseTermAdjustment");
	ElsIf TypeOf(Object) = Type("DocumentObject.LeaseTermAdjustment")
		Or TypeOf(Object) = Type("DocumentRef.LeaseTermAdjustment") Then
		ThisIsChangeInTermsOfLease = True;
	EndIf;
	
	Return ThisIsChangeInTermsOfLease;
	
EndFunction

Procedure SetVisibilityOfScheduleVerificationIdentifier(IndicatorElement, CheckResult)
	
	If CheckResult = Undefined Then
		IndicatorElement.Visible = False;
		Return;
	EndIf;
	
	IndicatorElement.Visible = True;
	IndicatorElement.ToolTip = CheckResult;
	
EndProcedure

// Checks whether the payment or accrual schedule is completed.
// 
// Parameters:
//  FixedAsset - CatalogRef.Assets - The main means
//  PaymentSchedule - ValueTable - Payment schedule
//  ScheduleOfAccruals - ValueTable - Accrual schedule
// 
// Returns:
//  Boolean
Function ScheduleIsFull(FixedAsset, PaymentSchedule, ScheduleOfAccruals) Export
	
	FilterStructure1 = New Structure("FixedAsset", FixedAsset);
	If PaymentSchedule.FindRows(FilterStructure1).Count()
		Or ScheduleOfAccruals.FindRows(FilterStructure1).Count() Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function GenerateTextForCheckingAmountOfGraph(Sum, TotalScheduleOfPaymentsForServices, TotalScheduleOfAccrualOfServices, DocumentCurrencyPresentation)
	
	VerificationText = Undefined;
	
	If Sum <> TotalScheduleOfPaymentsForServices	
		And Sum <> TotalScheduleOfAccrualOfServices
		And TotalScheduleOfPaymentsForServices <> Undefined	
		And TotalScheduleOfAccrualOfServices <> Undefined Then
		
		VerificationText = NStr("vi = 'Số tiền không trùng với lịch biểu thanh toán và tính lãi:
		| - theo lịch biểu thanh toán số tiền %1 %2
		| - theo lịch biểu tính lãi số tiền %3 %4';
		|ru = 'Сумма не совпадает с графиком оплат и начислений:
		|  - по графику оплат сумма %1 %2
		|  - по графику начислений сумма %3 %4';
		|en = 'The amount does not match the schedule of payments and charges:
		| - according to the schedule of payments, amount is %1 %2
		| - according to the schedule of charges, amount is %3 %4'; fa = 'The amount does not match the schedule of payments and charges:
		| - according to the schedule of payments, amount is %1 %2
		| - according to the schedule of charges, amount is %3 %4';
		|it = 'L''importo non corrisponde al grafico dei pagamenti e maturazioni:
		| -in base al grafico pagamenti importo %1 %2
		| - in base al grafico maturazioni importo %3%4';
		|pl = 'Wartość nie odpowiada harmonogramowi płatności i naliczeń:
		|  - zgodnie z harmonogramem płatności wartość %1 %2
		|  - zgodnie z harmonogramem naliczeń wartość %3 %4';
		|tr = 'Tutar, ödeme ve tahakkuk planıyla örtüşmemektedir: 
		| - ödeme planına göre tutar %1 %2 
		| - tahakkuk planına göre tutar %3 %4'");
		VerificationText = StrTemplate(VerificationText, 
								Format(TotalScheduleOfPaymentsForServices, "NFD=2; NZ=0;"),
								DocumentCurrencyPresentation,
								Format(TotalScheduleOfAccrualOfServices, "NFD=2; NZ=0;"),
								DocumentCurrencyPresentation);
		
	ElsIf Sum <> TotalScheduleOfPaymentsForServices Then
		
		If TotalScheduleOfPaymentsForServices <> Undefined Then
			
			VerificationText = NStr("vi = 'Số tiền không trùng với lịch biểu thanh toán:
			| - theo lịch biểu thanh toán số tiền %1 %2';
			|ru = 'Сумма не совпадает с графиком оплат:
			|  - по графику оплат сумма %1 %2';
			|en = 'The amount does not match the payment schedule:
			| - according to the payment schedule, the amount is %1 %2'; fa = 'The amount does not match the payment schedule:
			| - according to the payment schedule, the amount is %1 %2';
			|it = 'L''importo non corrisponde al grafico dei pagamenti:
			| - in base al grafico pagamenti importo %1 %2';
			|pl = 'Wartość nie odpowiada harmonogramowi płatności:
			|  - wg harmonogramu płatności wartości wynosi %1 %2';
			|tr = 'Tutar ödeme planıyla örtüşmüyor: 
			| - ödeme planına göre, tutar%1%2'");
			
			VerificationText = StrTemplate(VerificationText, 
									Format(TotalScheduleOfPaymentsForServices, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
		Else
			
			VerificationText = NStr("vi = 'Số tiền không trùng với lịch biểu thanh toán:
			| - theo lịch biểu thanh toán số tiền tùy ý';
			|ru = 'Сумма не совпадает с графиком оплат:
			|  - по графику оплат сумма произвольная';
			|en = 'The amount does not match the payment schedule:
			| - according to the payment schedule, the amount is arbitrary'; fa = 'The amount does not match the payment schedule:
			| - according to the payment schedule, the amount is arbitrary';
			|it = 'L''importo non corrisponde al grafico dei pagamenti:
			| - in base al grafico dei pagamenti importo casuale';
			|pl = 'Wartość nie odpowiada harmonogramowi płatności:
			|  - wg harmonogramu płatności wartość jest dowolna';
			|tr = 'Tutar ödeme planıyla örtüşmüyor: 
			|- ödeme planına göre, tutar isteğe bağlıdır.'");
			
		EndIf;
		
	ElsIf Sum <> TotalScheduleOfAccrualOfServices Then
		
		If TotalScheduleOfAccrualOfServices <> Undefined Then
			
			VerificationText = NStr("vi = 'Số tiền không trùng với lịch biểu tính lãi:
			| - theo lịch biểu tính lãi số tiền %1 %2';
			|ru = 'Сумма не совпадает с графиком начислений:
			|  - по графику начислений сумма %1 %2';
			|en = 'The amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2'; fa = 'The amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is %1 %2';
			|it = 'L''importo non corrisponde al grafico delle maturazioni:
			| - in base al grafico importo maturazioni %1%2';
			|pl = 'Wartość nie odpowiada harmonogramowi naliczeń:
			| - wg harmonogramu naliczeń wartość %1 %2';
			|tr = 'Tutar tahakkuk takvimi ile örtüşmüyor: 
			|- tahakkuk çizelgesine göre tutar %1%2'");
			VerificationText = StrTemplate(VerificationText, 
									Format(TotalScheduleOfAccrualOfServices, "NFD=2; NZ=0;"),
									DocumentCurrencyPresentation);
		Else
		
			VerificationText = NStr("vi = 'Số tiền không trùng với lịch biểu tính lãi:
			| - theo lịch biểu tính lãi số tiền tùy ý';
			|ru = 'Сумма не совпадает с графиком начислений:
			|  - по графику начислений сумма произвольная';
			|en = 'The amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is arbitrary'; fa = 'The amount does not match the accruals schedule:
			| - according to the accruals schedule, the amount is arbitrary';
			|it = 'L''importo non corrisponde al grafico delle maturazioni:
			| - in base al grafico importo casuale maturazioni';
			|pl = 'Wartość nie odpowiada harmonogramowi naliczeń:
			| - wg harmonogramu naliczeń wartość jest dowolna';
			|tr = 'Tutar tahakkuk çizelgesiyle örtüşmüyor: 
			|- tahakkuk çizelgesine göre,  tutar keyfidir'");
			
		EndIf;
		
	EndIf;
	
	Return VerificationText;
	
EndFunction

Function GenerateTextToCheckFrequencyOfSchedule(Periodicity, FrequencyAccordingToSchedule)

	VerificationText = Undefined;
	
	If Periodicity <> FrequencyAccordingToSchedule
		And FrequencyAccordingToSchedule <> Undefined Then
		
		VerificationText = NStr("vi = 'Định kỳ không trùng với lịch biểu:
		|- theo lịch biểu định kỳ ""%1""';
		|ru = 'Периодичность не совпадает с графиком:
		|- по графику периодичность ""%1""';
		|en = 'The frequency does not match the schedule: 
		|- according to the schedule, the frequency is ""%1""'; fa = 'The frequency does not match the schedule: 
		|- according to the schedule, the frequency is ""%1""';
		|it = 'La periodicità non corrisponde al grafico:
		|- in base al grafico periodicità ""%1""';
		|pl = 'Okresowość nie odpowiada harmonogramowi:
		|- wg harmonogramu okresowość jest ""%1""';
		|tr = 'Periyodiklik programla çakışmaz:
		| - programa göre, periyodiklik ""%1""'");
		VerificationText = StrTemplate(VerificationText, String(FrequencyAccordingToSchedule));
		
	EndIf;
	
	Return VerificationText;
	
EndFunction

// Determines the time fence of the schedule.
// 
// Parameters:
//  PreviousDate - Date - 
//  CurrentDate - Date - 
// 
// Returns:
//  EnumRef.ScheduleTimeFence
Function ScheduleTimeFence(PreviousDate, CurrentDate) Export

	ListPeriodicity = New Array;
	ListPeriodicity.Add(PredefinedValue("Enum.ScheduleTimeFence.Day"));
	ListPeriodicity.Add(PredefinedValue("Enum.ScheduleTimeFence.Week"));
	ListPeriodicity.Add(PredefinedValue("Enum.ScheduleTimeFence.Month"));
	ListPeriodicity.Add(PredefinedValue("Enum.ScheduleTimeFence.Quarter"));
	ListPeriodicity.Add(PredefinedValue("Enum.ScheduleTimeFence.HalfYear"));
	ListPeriodicity.Add(PredefinedValue("Enum.ScheduleTimeFence.Year"));

	For Cnt = 0 To ListPeriodicity.UBound() Do
		
		Periodicity = ListPeriodicity[Cnt];
		
		If CurrentDate = NextScheduleDate(PreviousDate, Periodicity) Then
			Return Periodicity;
		EndIf;
		 
	EndDo;
	
	Return PredefinedValue("Enum.ScheduleTimeFence.Custom");
	
EndFunction

// Returns the types of profitable lease Contracts
// 
// Returns:
// Array of EnumRef.ContractTypes
Function TypesOfProfitableLeaseContracts() Export
	
	ArrayOfContractTypes = New Array;
	ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.TransferToRental"));
	ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.Sublease"));
		
	Return ArrayOfContractTypes;
	
EndFunction

#EndRegion

#EndRegion
