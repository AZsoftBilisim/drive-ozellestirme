#Region Private

// Opens a form to enter the term of the lease, after you enter sets the date in the object.
// 
// Parameters:
// 	Form - ClientApplicationForm - shape.
// 	Object - FormDataStructure - Object.
// 	CompletionHandler - Undefined - The form handler that should be invoked after the entry deadline.
Procedure EnterLeaseTerm(Form, Object, CompletionHandler = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("LeaseStartDate", Object.LeaseStartDate);
	FormParameters.Insert("TermYears", Object.TermYears);
	FormParameters.Insert("TermMonths", Object.TermMonths);
	FormParameters.Insert("TermDays", Object.TermDays);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	OpenForm("Catalog.LeaseContract.Form.EnteringLeaseTerm",
			FormParameters,,,,, 
			New CallbackDescription("EnterLeaseTermCompletion", ThisObject, AdditionalParameters), 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure EnterLeaseTermCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined 
		Or TypeOf(ClosingResult) <> Type("Structure") Then
		Return;
	EndIf;
	
	Object = AdditionalParameters.Object;
	
	If Object.LeaseStartDate <> ClosingResult.LeaseStartDate
		Or Object.TermYears <> ClosingResult.TermYears
		Or Object.TermMonths <> ClosingResult.TermMonths
		Or Object.TermDays <> ClosingResult.TermDays Then
			
		AdditionalParameters.Form.LeaseTermHasBeenChanged = True;
		
		Object.LeaseStartDate = ClosingResult.LeaseStartDate;
		Object.TermYears = ClosingResult.TermYears;
		Object.TermMonths = ClosingResult.TermMonths;
		Object.TermDays = ClosingResult.TermDays;
		
		AdditionalParameters.Form.Modified = True;
		
		If AdditionalParameters.CompletionHandler <> Undefined Then
			RunCallback(AdditionalParameters.CompletionHandler, ClosingResult);
		EndIf;
	
	EndIf;
	
EndProcedure

// Checks whether the payment and accrual schedule can be filled in according to the "Calculations" section"
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment -
//  ContractDetails_ - Structure -
//  
// Returns:
// 	Boolean - True, if you can fill in
Function CheckAbilityToFillInScheduleByCalculations(Object, ContractDetails_) Export
	
	ClearMessages();
	
	HasErrors = False;
	
	EndDate = NonCurrentAssetsClientServer.EndDateByDeadline(
						Object.LeaseStartDate, Object.TermYears, Object.TermMonths, Object.TermDays, True);
	
	ThisIsChangeInTermsOfLease = LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object);
	
	If Not ValueIsFilled(Object.Contract) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Hợp đồng""';
							|ru = 'Поле ""Договор"" не заполнено';
							|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
							|it = 'Il campo ""Accordo"" non è compilato';
							|pl = 'Pole ""Umowa"" nie jest wypełnione';
							|tr = '""Sözleşme"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "Contract", "Object", HasErrors);
	EndIf;
	
	//
	If ContractDetails_.HasSecurityDeposit
		And Not ThisIsChangeInTermsOfLease		
		And Not ValueIsFilled(Object.SecurityDepositAmount) Then
			
		MessageText = NStr("vi = 'Chưa điền trường ""Số tiền khoản thanh toán đảm bảo""';
							|ru = 'Поле ""Сумма обеспечительного платежа"" не заполнено';
							|en = 'The ""Security deposit amount"" field is not filled in'; fa = 'The ""Security deposit amount"" field is not filled in';
							|it = 'Campo ""Importo deposito cauzionale"" non compilato';
							|pl = 'Pole ""Wartość płatności zabezpieczającej"" nie jest wypełniona';
							|tr = '""Teminat ödemesi tutarı"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "SecurityDepositAmount", "Object", HasErrors);
	EndIf;

	If ContractDetails_.HasSecurityDeposit
		And Not ValueIsFilled(Object.DateOfFirstSecurityPayment) Then
			
		MessageText = NStr("vi = 'Chưa điền trường ""Ngày thanh toán đảm bảo đầu tiên""';
							|ru = 'Поле ""Дата первого обеспечительного платежа"" не заполнено';
							|en = 'The ""First security deposit date"" field is not filled in'; fa = 'The ""First security deposit date"" field is not filled in';
							|it = 'Campo ""Data primo deposito cauzionale"" non compilato';
							|pl = 'Pole ""Data pierwszej płatności zabezpieczającej"" nie jest wypełnione';
							|tr = '""İlk teminat ödeme tarihi"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "DateOfFirstSecurityPayment", "Object", HasErrors);
	EndIf;

	//
	If Not ValueIsFilled(Object.DateOfFirstPayment)
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And ValueIsFilled(Object.PaymentFrequency) Then
			
		MessageText = NStr("vi = 'Chưa điền trường ""Ngày thanh toán đầu tiên cho dịch vụ thuê""';
							|ru = 'Поле ""Дата первого платежа за услуги по аренде"" не заполнено';
							|en = 'The ""Date of the first payment for rental services"" field is not filled in'; fa = 'The ""Date of the first payment for rental services"" field is not filled in';
							|it = 'Campo ""Data primo pagamento per i servizi relativi all''affitto"" non compilato';
							|pl = 'Pole ""Data pierwszej płatności za usługi dotyczące dzierżawy"" nie jest wypełnione';
							|tr = '""Kiralama hizmetleri için ilk ödeme tarihi"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "DateOfFirstPayment", "Object", HasErrors);
	EndIf;

	//
	If Object.LeaseStartDate = '000101010000'
		Or Object.TermYears = 0 And Object.TermMonths = 0 And Object.TermDays = 0 Then
			
		MessageText = NStr("vi = 'Chưa điền trường ""Thời hạn thuê""';
							|ru = 'Поле ""Срок аренды"" не заполнено';
							|en = 'The ""Rental period"" field is not filled in'; fa = 'The ""Rental period"" field is not filled in';
							|it = 'Campo ""Periodo di affitto"" non compilato';
							|pl = 'Pole ""Okres dzierżawy"" nie jest wypełnione';
							|tr = '""Kira dönemi"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "RentalPeriod", , HasErrors);
	EndIf;

	//
	If Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And ValueIsFilled(Object.PaymentFrequency)
		And Not ValueIsFilled(Object.PaymentForLeaseService) Then
			
		MessageText = NStr("vi = 'Chưa điền trường ""Thanh toán dịch vụ thuê""';
							|ru = 'Поле ""Платеж за услуги по аренде"" не заполнено';
							|en = 'The ""Payment for rental services"" field is not filled in'; fa = 'The ""Payment for rental services"" field is not filled in';
							|it = 'Campo ""Pagamento per i servizi relativi all''affitto"" non compilato';
							|pl = 'Pole ""Płatność za usługi dotyczące dzierżawy"" nie jest wypełnione';
							|tr = '""Kiralama hizmetleri için ödeme"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "PaymentForLeaseService", "Object", HasErrors);
	EndIf;

	If Object.AccrualFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And ValueIsFilled(Object.AccrualFrequency)
		And Not ValueIsFilled(Object.AccrualOfLeaseService) Then
			
		MessageText = NStr("vi = 'Chưa điền trường ""Tính lãi dịch vụ thuê""';
							|ru = 'Поле ""Начисление услуги по аренде"" не заполнено';
							|en = 'The ""Accrual of rental services"" field is not filled in'; fa = 'The ""Accrual of rental services"" field is not filled in';
							|it = 'Campo ""Maturazione servizi relativi all''affitto"" non compilato';
							|pl = 'Pole ""Naliczanie usługi dotyczącej dzierżawy"" nie jest wypełnione';
							|tr = '""Kira hizmet tahakkuku"" alanı doldurulmamış'");
		CommonClient.MessageToUser(MessageText,, "AccrualOfLeaseService", "Object", HasErrors);
	EndIf;

	//
	If ContractDetails_.HasSecurityDeposit
		And Object.DateOfFirstSecurityPayment > EndDate
		And Object.DateOfFirstSecurityPayment <> '000101010000'
		And EndDate <> '000101010000' Then
			
		MessageText = NStr("vi = 'Khoản thanh toán đảm bảo không được muộn hơn so với cuối kỳ thuê';
							|ru = 'Обеспечительный платеж должен быть не позже окончания срока аренды';
							|en = 'The security deposit must be no later than the end of the rental term'; fa = 'The security deposit must be no later than the end of the rental term';
							|it = 'Il deposito cauzionale deve essere entro e non oltre la fine del periodo di noleggio';
							|pl = 'Płatność zabezpieczająca powinna być nie później zakończenia okresu dzierżawy';
							|tr = 'Teminat ödemesi en geç kira süresinin sonuna kadar yapılmalıdır'");
		CommonClient.MessageToUser(MessageText,, "DateOfFirstSecurityPayment", "Object", HasErrors);
	EndIf;

	//
	If Object.DateOfFirstPayment < Object.LeaseStartDate
		And Object.DateOfFirstPayment <> '000101010000'
		And Object.LeaseStartDate <> '000101010000' Then
			
		MessageText = NStr("vi = 'Khoản thanh toán đầu tiên không được sớm hơn ngày bắt đầu thuê';
							|ru = 'Первый платеж должен быть не раньше даты начала аренды';
							|en = 'The first payment must not be earlier than the rental start date'; fa = 'The first payment must not be earlier than the rental start date';
							|it = 'Il primo pagamento non deve essere precedente alla data di inizio dell''affitto';
							|pl = 'Pierwsza płatność powinna być nie wcześniej niż data początku dzierżawy';
							|tr = 'İlk ödeme, kira sözleşmesinin başlangıç tarihinden daha erken olmamalıdır'");
		CommonClient.MessageToUser(MessageText,, "DateOfFirstPayment", "Object", HasErrors);
	EndIf;

	Return Not HasErrors;
	
EndFunction

// Checks whether the bid or cost can be calculated.
// 
// Parameters:
// 	Object - DocumentObject.SigningOfLeaseContract, DocumentObject.LeaseTermAdjustment, DocumentObject.OBEntryOfLeaseSettlements -
// 	ContractDetails_ - Structure -
// 	NameOfFATablePart - String -
// 	ReportErrors - Boolean -
// 	PreviousConditions - Undefined, Structure - See LeasedAssetAccounting.CostAccordingToPreviousConditions
// 	
// Returns:
// 	Boolean - 
Function YouCanCalculateRateOrCost(Object, ContractDetails_, NameOfFATablePart, ReportErrors = True, PreviousConditions = Undefined) Export
	
	ClearMessages();
	
	HasErrors = False;
	
	ByActualCost = (ContractDetails_.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually"));
	
	ErrorList = New Array;
	
	If ByActualCost Then
		
		If NameOfFATablePart <> "" Then
			
			If Object.FA.Count() = 0 Then
				MessageText = NStr("vi = 'Cần điền danh sách đối tượng thuê và giá trị thuê';
									|ru = 'Необходимо заполнить список предметов аренды и их стоимость';
									|en = 'Fill in the list of rental objects and their cost'; fa = 'Fill in the list of rental objects and their cost';
									|it = 'È necessario compilare l''elenco degli elementi di affitto e il loro costo';
									|pl = 'Należy wypełnić listę przedmiotów dzierżawy i ich wartość';
									|tr = 'Kiralama kalemlerinin ve maliyetlerinin bir listesi doldurulmalıdır'");
				NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, "FA", "Object", HasErrors);
			EndIf;
			
			For Each RowData In Object.FA Do
				
				If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
					And RowData.FairValue = 0 Then
					
					MessageText = StrTemplate(NStr("vi = 'Trong dòng %1 cần điền giá trị hợp lý';
													|ru = 'В строке %1 необходимо заполнить справедливую стоимость';
													|en = 'Fill in the fair value in line %1'; fa = 'Fill in the fair value in line %1';
													|it = 'Nella riga %1 è necessario compilare il valore equo';
													|pl = 'W wierszu %1 należy wypełnić sprawiedliwą wartość';
													|tr = '%1 satırı gerçeğe uygun maliyet ile doldurulmalıdır'"), Format(RowData.LineNumber, "NG=;"));
					Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FairValue");
					NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, Field, "Object", HasErrors);
					
				ElsIf ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing")
					And RowData.Cost = 0 Then
					
					MessageText = StrTemplate(NStr("vi = 'Trong dòng %1 cần điền giá trị';
													|ru = 'В строке %1 необходимо заполнить стоимость';
													|en = 'Fill in the cost in line %1'; fa = 'Fill in the cost in line %1';
													|it = 'Nella riga %1 è necessario compilare il costo';
													|pl = 'W wierszu %1 należy wypełnić wartość';
													|tr = '%1 satırında maliyeti doldurmanız gerekir'"), Format(RowData.LineNumber, "NG=;"));
					Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "Cost");
					NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, Field, "Object", HasErrors);
					
				EndIf;
				
			EndDo;
			
		Else 
			
			If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
				And Object.FairValue = 0 Then
				
				MessageText = NStr("vi = 'Cần điền giá trị hợp lý';
									|ru = 'Необходимо заполнить справедливую стоимость';
									|en = 'Fill in the fair value'; fa = 'Fill in the fair value';
									|it = 'È necessario compilare il fair value';
									|pl = 'Należy wypełnić sprawiedliwą wartość';
									|tr = 'Rayiç değerin doldurulması gerekiyor'");
				NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, "FairValue", "Object", HasErrors);
				
			ElsIf ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing")
				And Object.Cost = 0 Then
				
				MessageText = NStr("vi = 'Cần điền giá trị';
									|ru = 'Необходимо заполнить стоимость';
									|en = 'Fill in the cost'; fa = 'Fill in the cost';
									|it = 'È necessario compilare il prezzo';
									|pl = 'Należy wypełnić wartość';
									|tr = 'Maliyetin doldurulması gerekiyor'");
				NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, "Cost", "Object", HasErrors);
				
			EndIf;
			
		EndIf;
		
		If Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
			LeaseStartDate = Object.LeaseStartDate;
			LeaseItemsCost =
				LeasedAssetAccountingClientServer.LeaseItemsCost(Object, ContractDetails_, NameOfFATablePart);
			PresentValue = LeasedAssetAccountingClientServer.PresentValue(
				LeaseItemsCost,
				Object.ServicePaymentSchedule, 
				Object.LeaseStartDate);
		Else
			LeaseStartDate = BegOfDay(Object.Date);
			DistributionCoefficient =
				LeasedAssetAccountingClientServer.CostSharingRatio(Object.FA, ContractDetails_);
			
			CostOfAddedRentalItems =
				LeasedAssetAccountingClientServer.CostOfAddedRentalItems(Object.FA);
			
			PresentValue = 
				PreviousConditions.PresentValue
				* DistributionCoefficient
				+ CostOfAddedRentalItems;
				
		EndIf;
		
		TotalPaymentsExcludingVAT = LeasedAssetAccountingClientServer.TotalPaymentsExcludingVAT(
									Object.ServicePaymentSchedule, LeaseStartDate, Object.VATRate);
		
		If PresentValue > TotalPaymentsExcludingVAT And TotalPaymentsExcludingVAT > 0 Then
			 
			Object.PresentValue = PresentValue;
			Object.InterestRate = 0;
			Object.InterestAmount = 0;
			
			If Not LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
				If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing") Then
					MessageText = NStr("vi = 'Số tiền đầu tư của bên cho thuê (%1) cần nhỏ hơn số tiền thanh toán không thuế GTGT (%2)';
										|ru = 'Сумма вложений лизингодателя (%1) должна быть меньше суммы платежей без НДС (%2)';
										|en = 'The amount of the lessor''s investments (%1) must be less than the amount of payments excluding VAT (%2)'; fa = 'The amount of the lessor''s investments (%1) must be less than the amount of payments excluding VAT (%2)';
										|it = 'Сумма вложений лизингодателя (%1) должна быть меньше суммы платежей без НДС (%2)';
										|pl = 'The amount of the lessor''s investments (%1) must be less than the amount of payments excluding VAT (%2)';
										|tr = 'Kiraya verenin yatırım tutarı (%1), KDV hariç ödeme tutarından az olmalıdır (%2)'");
				Else
					MessageText = NStr("vi = 'Giá trị đối tượng thuê (%1) phải nhỏ hơn số tiền thanh toán không gồm thuế GTGT (%2)';
										|ru = 'Стоимость предметов аренды (%1) должна быть меньше суммы платежей без НДС (%2)';
										|en = 'The cost of rental objects (%1) must be less than the amount of payments excluding VAT (%2)'; fa = 'The cost of rental objects (%1) must be less than the amount of payments excluding VAT (%2)';
										|it = 'Стоимость предметов аренды (%1) должна быть меньше суммы платежей без НДС (%2)';
										|pl = 'The cost of rental objects (%1) must be less than the amount of payments excluding VAT (%2)';
										|tr = 'Kiralanan nesnenin tutarı (%1), KDV hariç ödeme tutarından az olmalıdır (%2)'");
				EndIf;
			Else
				MessageText = NStr("vi = 'Giá trị nhập (%1) cần nhỏ hơn số tiền thanh toán trong tương lai không bao gồm VAT (%2)';
									|ru = 'Приведенная стоимость (%1) должна быть меньше суммы будущих платежей без НДС (%2)';
									|en = 'The present value (%1) must be less than the amount of future payments excluding VAT (%2)'; fa = 'The present value (%1) must be less than the amount of future payments excluding VAT (%2)';
									|it = 'Приведенная стоимость (%1) должна быть меньше суммы будущих платежей без НДС (%2)';
									|pl = 'The present value (%1) must be less than the amount of future payments excluding VAT (%2)';
									|tr = 'Bugünkü değeri (%1), KDV hariç gelecekteki ödemelerin tutarından (%2) daha az olmalıdır'");
			EndIf;
			
			MessageText = StrTemplate(MessageText, Format(PresentValue, "NFD=2"), Format(TotalPaymentsExcludingVAT, "NFD=2"));

			NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, "InterestRate",, HasErrors);
			
		EndIf;
		
	EndIf;
	
	If Object.DateOfFirstPayment < Object.LeaseStartDate
		And Object.DateOfFirstPayment <> '000101010000'
		And Object.LeaseStartDate <> '000101010000' Then
			
		MessageText = NStr("vi = 'Khoản thanh toán đầu tiên không được sớm hơn ngày bắt đầu thuê (%1)';
							|ru = 'Первый платеж должен быть не раньше даты начала аренды (%1)';
							|en = 'The first payment must not be earlier than the rental start date (%1)'; fa = 'The first payment must not be earlier than the rental start date (%1)';
							|it = 'Il primo pagamento non deve essere precedente alla data di inizio dell''affitto (%1)';
							|pl = 'Pierwsza płatność powinna być nie wcześniej niż data początku dzierżawy (%1)';
							|tr = 'İlk ödeme, kiralamanın başlangıç tarihinden önce olmamalıdır (%1)'");
		MessageText = StrTemplate(MessageText, Format(Object.LeaseStartDate,"DLF=D;"));
		
		NonCurrentAssetsClientServer.AddErrorDescription(ErrorList, MessageText, "DateOfFirstPayment", "Object", HasErrors);
		
	EndIf;
	
	DateRentalService = '000101010000';
	DateRedemptionValue = '000101010000';
	DateSecurityPayment = '000101010000';
	For Each OriginalGraphLine In Object.ServicePaymentSchedule Do		
		
		If OriginalGraphLine.RentalService <> 0 
			And OriginalGraphLine.Date <> '000101010000' Then
			DateRentalService = ?(
				DateRentalService <> '000101010000', 
				Min(DateRentalService, OriginalGraphLine.Date), 
				OriginalGraphLine.Date);
		EndIf;
		
		If OriginalGraphLine.BuyoutValue <> 0 
			And OriginalGraphLine.Date <> '000101010000' Then
			DateRedemptionValue = ?(
				DateRedemptionValue <> '000101010000', 
				Min(DateRedemptionValue, OriginalGraphLine.Date), 
				OriginalGraphLine.Date);
		EndIf;
		
		If OriginalGraphLine.DepositPayment <> 0 
			And OriginalGraphLine.Date <> '000101010000' Then
			DateSecurityPayment = ?(
				DateSecurityPayment <> '000101010000', 
				Min(DateSecurityPayment, OriginalGraphLine.Date), 
				OriginalGraphLine.Date);
		EndIf;
		
	EndDo;
	
	If ReportErrors Then
		For Each ErrorDescription In ErrorList Do
			CommonClient.MessageToUser(
				ErrorDescription.MessageText,, ErrorDescription.Field, ErrorDescription.DataPath);
		EndDo;
	EndIf;
	
	Return Not HasErrors;
	
EndFunction

Procedure OpenPaymentAndAccrualSchedule(Object, Form, AddressOfGraphs, CallbackDescription, ChartName) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartName", ChartName);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("ReadOnly", Form.ReadOnly);
	FormParameters.Insert("FormServiceParameters", Form.FormServiceParameters);
	FormParameters.Insert("InterestRate", Object.InterestRate);
	FormParameters.Insert("VATRate", Object.VATRate);
	FormParameters.Insert("LeaseStartDate", Object.LeaseStartDate);
	FormParameters.Insert("AmountOfLeaseAssetsByuout", Object.AmountOfLeaseAssetsByuout);
	FormParameters.Insert("AmountOfVATRepurchaseOfRentalItems", Object.AmountOfVATRepurchaseOfRentalItems);
	FormParameters.Insert("PresentValue", Object.PresentValue);
	FormParameters.Insert("DocumentCurrencyPresentation", Form.DocumentCurrencyPresentation);
	FormParameters.Insert("TheInterestAccrualScheduleIsEnteredManually", Object.TheInterestAccrualScheduleIsEnteredManually);
	FormParameters.Insert("ContractSchedules", AddressOfGraphs);
	If LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object) Then
		FormParameters.Insert("DateOfLeaseChange", BegOfDay(Object.Date));
	Else
		FormParameters.Insert("DateOfLeaseChange", '00010101');
	EndIf;
	
	OpenForm("Catalog.LeaseContract.Form.PaymentAndAccrualSchedule", FormParameters,,,,, CallbackDescription);
	
EndProcedure

Procedure OpenIncomeRentalCharts(Object, Form, FixedAsset, AddressOfGraphs, CallbackDescription) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Leaseholder", Object.Leaseholder);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("FixedAsset", FixedAsset);
	FormParameters.Insert("ReadOnly", Form.ReadOnly);
	FormParameters.Insert("FormServiceParameters", Form.FormServiceParameters);
	FormParameters.Insert("ContractSchedules", AddressOfGraphs);
	FormParameters.Insert("LeaseStartDate", BegOfDay(Object.Date));
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("DisplayGraphOfPercentagesFromRegister", Form.DisplayGraphOfPercentagesFromRegister);
	
	OpenForm("CommonForm.IncomeRentalSchedules", FormParameters, Form,,,, CallbackDescription);
	
EndProcedure

Procedure OpenFillingInRentalIncomeSchedules(Object, Form, SelectedFA, AddressOfGraphs, CallbackDescription) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Leaseholder", Object.Leaseholder);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("SelectedFA", SelectedFA);
	FormParameters.Insert("ReadOnly", Form.ReadOnly);
	FormParameters.Insert("FormServiceParameters", Form.FormServiceParameters);
	FormParameters.Insert("ContractSchedules", AddressOfGraphs);
	FormParameters.Insert("LeaseStartDate", BegOfDay(Object.Date));
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("DisplayGraphOfPercentagesFromRegister", Form.DisplayGraphOfPercentagesFromRegister);
	
	OpenForm("CommonForm.FillIncomeRentalSchedules", FormParameters, Form,,,, CallbackDescription);
	
EndProcedure

// Generates a printed form of Reference-calculation of interest accrual
//
// Parameters:
//  Form - See Document.ProvideAssetsToLeasee2_4.Form.DocumentForm
//
Procedure ReferenceCalculationOfAccrualOfInterest(Form) Export
	
	Object = Form.Object;
	Items = Form.Items;
	
	ClearMessages();
	
	// Check the document before printing.
	
	ErrorsArray = New Array;
	
	If Not Object.Posted Then 
		ErrorsArray.Add(NStr("vi = 'Chưa kết chuyển chứng từ';
							|ru = 'Документ не проведен';
							|en = 'Document is not posted'; fa = 'Document is not posted';
							|it = 'Документ не проведен';
							|pl = 'Document is not posted';
							|tr = 'Belge kaydedilmedi'"));
	EndIf;
	
	If Object.FA.Count() = 0 Then
		ErrorsArray.Add(NStr("vi = 'Trong chứng từ, không có một tài sản cố định';
							|ru = 'В документе нет ни одного основного средства';
							|en = 'There are no fixed assets in the document'; fa = 'There are no fixed assets in the document';
							|it = 'В документе нет ни одного основного средства';
							|pl = 'There are no fixed assets in the document';
							|tr = 'Belgede herhangi bir sabit kıymet bulunmamaktadır'"));
	EndIf;
	
	If Object.ServicePaymentSchedule.Count() = 0 Then
		ErrorsArray.Add(NStr("vi = 'Chưa điền lịch biểu thanh toán';
							|ru = 'Не заполнен график оплат';
							|en = 'The payment schedule is not filled'; fa = 'The payment schedule is not filled';
							|it = 'Не заполнен график оплат';
							|pl = 'The payment schedule is not filled';
							|tr = 'Ödeme planı doldurulmadı'"));
	EndIf;
	
	If Object.InterestAccrualSchedule.Count() = 0 Then
		ErrorsArray.Add(NStr("vi = 'Chưa điền lịch biểu tính toán phần trăm';
							|ru = 'Не заполнен график начисления процентов';
							|en = 'The interest charge schedule is not filled'; fa = 'The interest charge schedule is not filled';
							|it = 'Не заполнен график начисления процентов';
							|pl = 'The interest charge schedule is not filled';
							|tr = 'Faiz tahakkuk planı doldurulmadı'"));
	EndIf;
	
	If ErrorsArray.Count() > 0 Then
		MessageText = StrConcat(ErrorsArray, Chars.LF);
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	// We print help-calculations on the selected lines.
	DataForPrint = New Array;
	LineForReference = New Structure;
	LineForReference.Insert("FixedAsset", PredefinedValue("Catalog.Assets.EmptyRef"));
	LineForReference.Insert("RateOfReturn", 0);
	LineForReference.Insert("AdvancePayments", 0);
	LineForReference.Insert("PresentValue", 0);
	LineForReference.Insert("NGLV", 0);
	
	For Each SelectedRow In Items.FA.SelectedRows Do
		
		CurrentData = Items.FA.RowData(SelectedRow);
		
		CurrentLineIsForReference = LineForReference;
		CurrentLineIsForReference.FixedAsset     = CurrentData.FixedAsset;
		CurrentLineIsForReference.RateOfReturn     = CurrentData.RateOfReturn;
		CurrentLineIsForReference.AdvancePayments     = 0;
		CurrentLineIsForReference.PresentValue = CurrentData.PresentValue;
		CurrentLineIsForReference.NGLV                 = CurrentData.NGLV;
		
		DataForPrint.Add(CurrentLineIsForReference);
		
	EndDo;
	
	TemplateName = "ReferenceCalculationOfAccrualOfInterest";
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataForPrint",DataForPrint);
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	PrintManagementClient.ExecutePrintCommand(
					"DataProcessor.PrintSheetOfChargedInterestOnLeasedFixedAssets",
					TemplateName,
					Object.Ref,
					ThisObject,
					PrintParameters);
					
EndProcedure

// Removes fixed asset from document graphs
//
// Parameters:
//  Object - See Document.ProvideAssetsToLeasee2_4
//  FixedAsset - CatalogRef.Assets
//
Procedure RemoveFAFromCharts(Object, FixedAsset) Export
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	PaymentSchedule = Object.ServicePaymentSchedule;
	ScheduleOfAccruals = Object.ServiceAccrualSchedule;
	InterestGraph = Object.InterestAccrualSchedule;
	
	FilterStructure1 = New Structure("FixedAsset", FixedAsset);
	
	PaymentRows = PaymentSchedule.FindRows(FilterStructure1);
	For Each PaymentLine_ In PaymentRows Do
		PaymentSchedule.Delete(PaymentLine_);
	EndDo;
	
	AccrualLines = ScheduleOfAccruals.FindRows(FilterStructure1);
	For Each AccrualsLine In AccrualLines Do
		ScheduleOfAccruals.Delete(AccrualsLine);
	EndDo;
	
	PercentageLines = InterestGraph.FindRows(FilterStructure1);
	For Each InterestLine In PercentageLines Do
		InterestGraph.Delete(InterestLine);
	EndDo;
	
EndProcedure

#EndRegion
