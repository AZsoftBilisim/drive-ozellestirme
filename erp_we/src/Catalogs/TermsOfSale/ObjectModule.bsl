#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sale in the agreement with the client.
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	ARAPCurrency = SalesTermsAndConditions.ARAPCurrency;
	Currency = SalesTermsAndConditions.Currency;
	
	If ValueIsFilled(SalesTermsAndConditions.BusinessOperation) Then
		BusinessOperation = SalesTermsAndConditions.BusinessOperation;
		ARAPObjectSettings       = SalesTermsAndConditions.ARAPObjectSettings;
		PriceIncludesVAT       = SalesTermsAndConditions.PriceIncludesVAT;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
		PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Calendar) Then
		Calendar = SalesTermsAndConditions.Calendar;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.ForeignCurrencyTransaction) Then
		ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.CashFlowItem) Then
		CashFlowItem = SalesTermsAndConditions.CashFlowItem;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays) Then
		DeliveryPeriodDays = SalesTermsAndConditions.DeliveryPeriodDays;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.PricesKind) Then
		PricesKind = SalesTermsAndConditions.PricesKind;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) Then
		
		Organization = SalesTermsAndConditions.Organization;
		
	EndIf;
	
	DocumentAmount = SalesTermsAndConditions.DocumentAmount;
	Frequent     = SalesTermsAndConditions.Frequent;
	
	If ValueIsFilled(SalesTermsAndConditions.Period) Then
		Period = SalesTermsAndConditions.Period;
	EndIf;
	
	NumberOfPeriods = SalesTermsAndConditions.NumberOfPeriods;
	
	CurrentDate = CurrentSessionDate();
	If ValueIsFilled(SalesTermsAndConditions.ValidityStartDate) Then
		ValidityStartDate = ?(SalesTermsAndConditions.ValidityStartDate < CurrentDate, CurrentDate, SalesTermsAndConditions.ValidityStartDate);
	EndIf;
	If ValueIsFilled(SalesTermsAndConditions.ValidityEndDate) Then
		ValidityEndDate = ?(SalesTermsAndConditions.ValidityEndDate >= CurrentDate, SalesTermsAndConditions.ValidityEndDate, Undefined);;
	EndIf;
		
	If Frequent And ValueIsFilled (Period) And
		ValueIsFilled (NumberOfPeriods) Then
		
		If Not ValueIsFilled(ValidityStartDate) Then
			ValidityStartDate = Date;
		EndIf;

		If ValueIsFilled(ValidityStartDate) Then
			ValidityEndDate = TMCommonUseClientServer.CalculatePeriodEndDate(ValidityStartDate, Period, NumberOfPeriods);
		EndIf;
		
	EndIf;
	
	UsedInSalesRepresentativesWork = SalesTermsAndConditions.UsedInSalesRepresentativesWork;
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Warehouse = SalesTermsAndConditions.Warehouse;
	EndIf;
	
	ProductSegment = SalesTermsAndConditions.ProductSegment;
	
	LimitDiscountAdjustments  = SalesTermsAndConditions.LimitDiscountAdjustments;
	PercentRateOfManualDiscount  = SalesTermsAndConditions.PercentRateOfManualDiscount;
	MaximumPercentageForManualMarkup = SalesTermsAndConditions.MaximumPercentageForManualMarkup;
	
	If ValueIsFilled(SalesTermsAndConditions.CommissionFeeCalculationMethod) Then
		CommissionFeeCalculationMethod = SalesTermsAndConditions.CommissionFeeCalculationMethod;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.RemunerationPercentage) Then
		RemunerationPercentage = SalesTermsAndConditions.RemunerationPercentage;
	EndIf;
	
	KeepCommissionFee                        = SalesTermsAndConditions.KeepCommissionFee;
	ContractsAreUsed              = SalesTermsAndConditions.ContractsAreUsed;
	AvailableToExternalUsers                  = SalesTermsAndConditions.AvailableToExternalUsers;
	SaleWithDeferredTransferOfTitleIsAllowed = SalesTermsAndConditions.SaleWithDeferredTransferOfTitleIsAllowed;
	
	ReturnReusablePackage                  = SalesTermsAndConditions.ReturnReusablePackage;
	ReusablePackageReturnCycleLength                = SalesTermsAndConditions.ReusablePackageReturnCycleLength;
	CalculatePackageReturnDateAccordingToCalendar       = SalesTermsAndConditions.CalculatePackageReturnDateAccordingToCalendar;
	PackageDepositIsRequired                          = SalesTermsAndConditions.PackageDepositIsRequired;
	ScheduleOfPackageReturn                         = SalesTermsAndConditions.ScheduleOfPackageReturn;
	EnableAssigmentSupplyForOrders                 = SalesTermsAndConditions.EnableAssigmentSupplyForOrders;
	MinimumOrderAmount                        = SalesTermsAndConditions.MinimumOrderAmount;
	DeadlineOfTransferOfTitleToGoods                = SalesTermsAndConditions.DeadlineOfTransferOfTitleToGoods;
	OrderFrequency                                 = SalesTermsAndConditions.OrderFrequency;
	CommissionAgentUsesInventoryAccountingByProductBatchID                    = SalesTermsAndConditions.CommissionAgentUsesInventoryAccountingByProductBatchID;
	
EndProcedure

// Fills in the default sales terms in the commercial offer.
//
Procedure FillInDefaultSalesConditions() Export
	
	ClearAgreement = True;
	
	If ValueIsFilled(Partner) Then
	
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			New Structure(
				"OnlyStandard,
				|ConsiderWarehouseGroups, SelectedAgreement",
				True,
				True,
				Catalogs.TermsOfSale.EmptyRef()));
		
		If DefaultSalesTerms <> Undefined Then
			
			ClearAgreement = False;
			
			If DefaultSalesTerms.Terms <> Terms Then
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				FillInTabularPartsByAgreement(Terms);
			EndIf;
			
		EndIf;
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	EndIf;
	
	If ClearAgreement Then
		Terms = Catalogs.TermsOfSale.EmptyRef();
	EndIf;
	
EndProcedure

// Fills in the terms of sales for the agreement in the agreement.
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	FillInTabularPartsByAgreement(Terms);
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

// Fills in discounts and mark-UPS for the agreement in the agreement.
//
Procedure FillInDiscountsAndSurchargesByAgreement() Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		RecordSet = InformationRegisters.ValidityOfDiscountsMarkups.CreateRecordSet();
		RecordSet.Filter.Source.Set(ThisObject.Ref);
		RecordSet.Read();
		RecordSet.Clear();
		RecordSet.Write(True);
	
		AgreementLink = Terms;
		DiscountsMarkupsServer.WhenRecordingOnServerOfSourcesOfValidityOfDiscountsMargins(ThisObject, AgreementLink);

		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
	EndTry;
	
	SetPrivilegedMode(False);
		
EndProcedure

// Fills in the option for calculating prices based on the agreement parameters.
//
Procedure FillInPriceCalculationOption() Export
	
	PriceViewFilledIn = ValueIsFilled(PricesKind); 
	
	ThereAreTwoPriceGroups = (PriceGroups.Count() > 0);
	ThereArePriceLines = False;
	ThereAreDifferentKindsOfPrices = False;
	
	// PM Analysis of Goods.
	If Goods.Count()>0 Then
		ThereAreRows = True;
		
		If Goods.Find(Catalogs.TypesOfPrices.EmptyRef(),"PriceKind") <> Undefined Then
			ThereArePriceLines = True;
		EndIf;
		
		If Goods.Find(0,"Price") <> Undefined Then
			ThereAreDifferentKindsOfPrices = True;
		EndIf;
	Else
		ThereAreRows = False;
	EndIf;
	
	If PriceViewFilledIn Then
		If ThereAreTwoPriceGroups Then
			If ThereAreRows Then
				If ThereArePriceLines And ThereAreDifferentKindsOfPrices Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderPricesKindsByPriceGroupsAndPricesKindsByItemsRefined;
				ElsIf ThereArePriceLines Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderPricesKindsByPriceGroupsAndAdjustedPricesByItems;
				Else
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderPricesKindsByPriceGroupsAndPricesKindsByItems;
				EndIf;
			Else
				PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderAndPricesKindsByPriceGroups;
			EndIf;
		Else
			If ThereAreRows Then
				If ThereArePriceLines And ThereAreDifferentKindsOfPrices Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderPricesKindsByItemsAndAdjustedPricesByItems;
				ElsIf  ThereArePriceLines Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderAndAdjustedPricesByItems;
				Else
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypeInHeaderAndPriceTypesByItems;
				EndIf;
			Else
				PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeader;
			EndIf;
		EndIf;
	Else
		If ThereAreTwoPriceGroups Then
			If ThereAreRows Then
				If ThereArePriceLines And ThereAreDifferentKindsOfPrices Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypesByPriceGroupsPriceTypesByItemsAndAdjustedPricesByItems;
				ElsIf ThereArePriceLines Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypesByPriceGroupsAndAdjustedPricesByItems;
				Else
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypesByPriceGroupsAndPriceTypesByItems;
				EndIf;
			Else
				PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypesByPriceGroups;
			EndIf;
		Else
			If ThereAreRows Then
				If ThereArePriceLines And ThereAreDifferentKindsOfPrices Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypesByItemsAndAdjustedPricesByItems;
				ElsIf ThereArePriceLines Then
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.OnlySpecifiedPricesOfItems;
				Else
					PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PriceTypesByItems;
				EndIf;
			Else
				PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.WithoutPrices;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
		
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Counterparties") Then
		FillInDocumentBasedOnCounterparty(FillingData);
	EndIf;

	InitializeCatalog();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Catalogs.TermsOfSale.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If Standard_ Then
		
		// In a standard agreement, you do not need to fill in the details "Partner", "Agreement"
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Terms");
		
	EndIf;
	
	// In individual agreements, provided that only they are used
	// and provided that they are shared with standard ones, but with the right to deviate from the terms of sale
	// , the agreement does not need to be filled in.
	UseStandardTermsOfSalesWithCustomers        = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales = GetFunctionalOption("UseCustomerTermsOfSales");
	
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales;
	VarianceFromSalesTermsAndConditions = UserRightsCached.VarianceFromSalesTermsAndConditions();
	
	If Not Standard_ 
		And (OnlyPersonal 
		Or Not UseCustomerTermsOfSales
		Or (UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales And VarianceFromSalesTermsAndConditions))Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	NotCheckedAttributeArray.Add("PaymentScheduleSteps.PackageDepositPercentage");
	UsePaymentSchedules = GetFunctionalOption("UsePaymentSchedules");
	NumberOfStages = PaymentScheduleSteps.Count();
	
	If ContractsAreUsed Then
		
		NotCheckedAttributeArray.Add("ARAPCurrency");
		
	EndIf;
	
	If Not AvailableToExternalUsers Then
		
		// In the agreement, it is not necessary for external users to fill in the "View Price", "Payment schedule", "Payment stages", "Organization".
		NotCheckedAttributeArray.Add("Organization");
		NotCheckedAttributeArray.Add("PricesKind");
		NotCheckedAttributeArray.Add("PlanProfile");
		NotCheckedAttributeArray.Add("PaymentSchedule");
		NotCheckedAttributeArray.Add("PaymentScheduleSteps");
		
	Else
		
		NotCheckedAttributeArray.Add("PaymentScheduleSteps");
		
		If Not UsePaymentSchedules
			And NumberOfStages = 0 Then
			
			ErrorText = NStr("vi = 'Cần điền các giai đoạn trong lịch thanh toán';
							|ru = 'Необходимо заполнить этапы графика оплаты';
							|en = 'Payment milestones required'; fa = 'Payment milestones required';
							|it = 'È necessario compilare le fasi del programma di pagamento';
							|pl = 'Należy wypełnić etapy harmonogramu płatności';
							|tr = 'Ödeme planı aşamalarını doldurmanız gerekmektedir'");
			CommonClientServer.MessageToUser(ErrorText, , "TheLabelPayment", ,Cancel);
			
		EndIf;
		
	EndIf;
	
	If Not UsePaymentSchedules
		Or NumberOfStages > 0 Then
		
		NotCheckedAttributeArray.Add("PaymentSchedule");
		
		If PackageDepositIsRequired Then
			NotCheckedAttributeArray.Add("PaymentScheduleSteps.PaymentPercentage");
			For Each PaymentStage In PaymentScheduleSteps Do
				If Not ValueIsFilled(PaymentStage.PaymentPercentage) And Not ValueIsFilled(PaymentStage.PackageDepositPercentage) Then
					ErrorText = NStr("vi = 'Đối với giai đoạn này cần chỉ ra phần trăm thanh toán hoặc phần trăm ký cược bao bì tại dòng %LineNumber%trong danh sách ""Giai đoạn trong lịch thanh toán""';
									|ru = 'Для этапа должен быть указан процент платежа или процент залога за тару в строке %LineNumber% списка ""Этапы графика оплаты""';
									|en = 'Line #%LineNumber%, Payment milestones list. Percent is required.'; fa = 'Line #%LineNumber%, Payment milestones list. Percent is required.';
									|it = 'Per la fase, la percentuale di pagamento o la percentuale di deposito per il contenitore deve essere indicata nella riga %LineNumber% della lista ""Fasi del programma di pagamento""';
									|pl = 'Dla etapu należy wskazać procent płatności lub procent kaucji za tarę w wierszu %LineNumber% listy ""Etapy harmonogramu płatności""';
									|tr = 'Ödeme yüzdesi veya dara depozitosunun yüzdesi, ""ödeme planının aşamaları"" listenin %LineNumber% satırında aşama için belirtilmelidir'");
					ErrorText = StrReplace(ErrorText, "%LineNumber%", PaymentStage.LineNumber);
					CommonClientServer.MessageToUser(
												ErrorText,
												ThisObject,
												CommonClientServer.PathToTabularSection("PaymentScheduleSteps", PaymentStage.LineNumber, "PaymentPercentage"),
												,
												Cancel);
				EndIf;
			EndDo;
			
			If PaymentScheduleSteps.Total("PackageDepositPercentage") <> 100 And PaymentScheduleSteps.Count() > 0 Then	
				ErrorText = NStr("vi = 'Tỷ lệ ký cược bao bì theo tất cả các giai đoạn thanh toán phải bằng 100%';
								|ru = 'Процент залога за тару по всем этапам оплаты должен быть равен 100%';
								|en = 'Percentage of the packaging deposit at all stages of payment should be equal to 100%'; fa = 'Percentage of the packaging deposit at all stages of payment should be equal to 100%';
								|it = 'La percentuale del deposito per l''imballaggio deve essere pari al 100% in tutte le fasi';
								|pl = 'Procent kaucji za opakowanie dla wszystkich etapów płatności powinien wynosić 100%';
								|tr = 'Tüm ödeme aşamaları için dara depozitosunun yüzdesi 100% olmalıdır'");
				ErrorAddress = "TheLabelPayment";
				CommonClientServer.MessageToUser(ErrorText, , ErrorAddress, , Cancel);
			EndIf;
			
		EndIf;
	EndIf;
	
	// The start date of the agreement must be no less than the date of the document.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityStartDate) Then
		
		If BegOfDay(Date) > ValidityStartDate Then
			
			ErrorText = NStr("vi = 'Ngày bắt đầu hiệu lực của thỏa thuận không được nhỏ hơn ngày thỏa thuận';
							|ru = 'Дата начала действия соглашения должна быть не меньше даты соглашения';
							|en = 'Agreement effective date cannot be less than the agreement date'; fa = 'Agreement effective date cannot be less than the agreement date';
							|it = 'La data di entrata in vigore dell''accordo non deve essere inferiore la data dell''accordo';
							|pl = 'Data wejścia w życie porozumienia nie może być wcześniejsza od daty porozumienia';
							|tr = 'Anlaşmanın başlangıç tarihi, anlaşma tarihinden daha önce olmamalıdır'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityStartDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// The expiration date of the agreement must be no less than the date of the document.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityEndDate) Then
		
		If BegOfDay(Date) > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày kết thúc hiệu lực của thỏa thuận không được nhỏ hơn ngày thỏa thuận';
							|ru = 'Дата окончания действия соглашения должна быть не меньше даты соглашения';
							|en = 'Agreement expiration date cannot be less than agreement date'; fa = 'Agreement expiration date cannot be less than agreement date';
							|it = 'La data di fine dell''accordo non deve essere inferiore la data dell''accordo';
							|pl = 'Data wygaśnięcia porozumienia nie może być wcześniejsza od daty porozumienia';
							|tr = 'Anlaşmanın sona erme tarihi, anlaşma tarihinden önce olmamalıdır'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// The expiration date of the agreement must not be less than the start date of the agreement.
	If ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then
		
		If ValidityStartDate > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày kết thúc hiệu lực của thỏa thuận không được nhỏ hơn ngày bắt đầu hiệu lực';
							|ru = 'Дата окончания действия соглашения должна быть не меньше даты начала действия';
							|en = 'Agreement expiration date cannot be less than effective date'; fa = 'Agreement expiration date cannot be less than effective date';
							|it = 'La data di scadenza dell''accordo non deve essere inferiore della data di entrata in vigore';
							|pl = 'Data wygaśnięcia porozumienia nie może być wcześniejsza od daty wejścia w życie';
							|tr = 'Anlaşmanın sona erme tarihi, anlaşmanın başlangıç tarihinden önce olmamalıdır'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// When transferring to a commission or for storage, you can specify only a schedule with credit stages of payment.
	If (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale)
		And ValueIsFilled(PaymentSchedule)
		And Not Common.ObjectAttributeValue(PaymentSchedule, "OnlyCreditSteps") Then
		
		ErrorText = NStr("vi = 'Cần chỉ ra lịch thanh toán chỉ có các giai đoạn trả sau';
						|ru = 'Необходимо указать график оплаты, содержащий только кредитные этапы';
						|en = 'Specify payment schedule which contains only credit steps'; fa = 'Specify payment schedule which contains only credit steps';
						|it = 'È necessario specificare un piano di pagamento che contiene solo fasi di credito';
						|pl = 'Należy wskazać harmonogram płatności, zawierający tylko etapy kredytowe';
						|tr = 'Sadece kredi aşamalarını içeren bir ödeme planı belirtmeniz gerekmektedir'");
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"PaymentSchedule",
			,
			Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray.Add("ValidityStartDate");
	NotCheckedAttributeArray.Add("DocumentAmount");
	NotCheckedAttributeArray.Add("NumberOfPeriods");
	NotCheckedAttributeArray.Add("Period");
	
	If Frequent Then
		
		// The regular agreement must specify the amount, frequency, number of periods, and start date.
		
		If Not ValueIsFilled(ValidityStartDate) Then
			
			ErrorText = NStr("vi = 'Trong thỏa thuận cần điền trường ""Ngày bắt đầu hiệu lực""';
							|ru = 'В регулярном соглашении необходимо заполнить поле ""Дата начала действия""';
							|en = 'Field ""Effective date"" is required in the regular agreement'; fa = 'Field ""Effective date"" is required in the regular agreement';
							|it = 'Nell''accordo regolare è necessario compilare il campo ""Data di entrata in vigore""';
							|pl = 'W regularnym porozumieniu należy wypełnić pole ""Data wejścia w życie""';
							|tr = 'Düzenli sözleşmede, ""Geçerlilik Başlangıç Tarihi"" alanını doldurmanız gerekmektedir'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityStartDate",
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(DocumentAmount) Then
			
			ErrorText = NStr("vi = 'Trong thỏa thuận thường xuyên, cần điền trường ""Số tiền""';
							|ru = 'В регулярном соглашении необходимо заполнить поле ""Сумма""';
							|en = 'Populate the Amount field in the regular agreement'; fa = 'Populate the Amount field in the regular agreement';
							|it = 'Nell''accordo regolare è necessario compilare il campo ""Somma""';
							|pl = 'W regularnym porozumieniu należy wypełnić pole ""Wartość""';
							|tr = 'Düzenli sözleşmede ""Tutar"" alanını doldurmanız gerekmektedir'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"DocumentAmount",
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(NumberOfPeriods) Then
			
			ErrorText = NStr("vi = 'Trong thỏa thuận thường xuyên, cần điền trường ""Số lượng kỳ""';
							|ru = 'В регулярном соглашении необходимо заполнить поле ""Количество периодов""';
							|en = 'Field ""Number of periods"" is required in the regular agreement'; fa = 'Field ""Number of periods"" is required in the regular agreement';
							|it = 'Nell''accordo regolare è necessario compilare il campo ""Quanità dei periodi""';
							|pl = 'W regularnym porozumieniu należy wypełnić pole ""Ilość okresów""';
							|tr = 'Düzenli sözleşmede ""Dönem Sayısı"" alanını doldurmanız gerekmektedir'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"NumberOfPeriods",
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Period) Then
			
			ErrorText = NStr("vi = 'Trong thỏa thuận thường xuyên, cần điền trường ""Kỳ""';
							|ru = 'В регулярном соглашении необходимо заполнить поле ""Период""';
							|en = 'Field ""Period"" is required in the regular agreement'; fa = 'Field ""Period"" is required in the regular agreement';
							|it = 'Nell''accordo regolare è necessario compilare il campo ""Periodo""';
							|pl = 'W regularnym porozumieniu należy wypełnić pole ""Okres""';
							|tr = 'Düzenli sözleşmede ""Dönem"" alanını doldurmanız gerekmektedir'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"Period",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	If CalculatePackageReturnDateAccordingToCalendar And ReturnReusablePackage And Not ValueIsFilled(ScheduleOfPackageReturn) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra lịch để ghi nhận việc trả lại bao bì theo ngày làm việc.';
						|ru = 'Не указан календарь для учета возврата тары по рабочим дням.';
						|en = 'Calendar for package return tracking by workdays is not specified.'; fa = 'Calendar for package return tracking by workdays is not specified.';
						|it = 'Nessun calendario è specificato per tenere conto della restituzione della confezione nei giorni lavorativi.';
						|pl = 'Nie wskazano kalendarza do ewidencji zwrotu tary w dni robocze.';
						|tr = 'İş gününe göre dara iadelerini hesaba katmak için herhangi bir takvim belirtilmemiştir.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			"Object.ScheduleOfPackageReturn",
			,
			Cancel);
		
	EndIf;
	
	// The expiration date of the agreement must not be less than the end date of the specified number of periods.
	If Frequent And ValueIsFilled(Period) And ValueIsFilled(NumberOfPeriods) And
		ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then
		
		StartDateOfNearestPeriod =  TMCommonUseClientServer.CalculateStartDateOfNearestPeriod(ValidityStartDate, Period);
		EndingDateOfPeriod = TMCommonUseClientServer.CalculatePeriodEndDate(StartDateOfNearestPeriod, Period, NumberOfPeriods);
		
		If EndingDateOfPeriod > EndOfDay(ValidityEndDate) Then
			
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của thỏa thuận không được nhỏ hơn ngày kết thúc số lượng kỳ đã chọn ""%EndingDateOfPeriod%""';
							|ru = 'Дата окончания действия соглашения не должна быть меньше, чем дата окончания указанного количества периодов ""%EndingDateOfPeriod%""';
							|en = 'The agreement expiration date cannot be earlier than the expiration date of the specified period quantity ""%EndingDateOfPeriod%""'; fa = 'The agreement expiration date cannot be earlier than the expiration date of the specified period quantity ""%EndingDateOfPeriod%""';
							|it = 'La data di scadenza dell''accordo non deve essere inferiore la data di scadenza del numero di periodi specificato ""%EndingDateOfPeriod%""';
							|pl = 'Data wygaśnięcia porozumienia nie może być wcześniejsza od daty zakończenia określonej ilości okresów ""%EndingDateOfPeriod%""';
							|tr = 'Anlaşmanın geçerlilik bitiş tarihi, belirtilen ""%EndingDateOfPeriod%"" dönem sayısının bitiş tarihinden önce olmamalıdır.'");
			ErrorText = StrReplace(ErrorText, "%EndingDateOfPeriod%", Format(EndingDateOfPeriod,"DLF=DD"));
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// In the tabular part of the Goods, the type of prices or fixed price should be filled in
	NotCheckedAttributeArray.Add("Goods.PriceKind");
	NotCheckedAttributeArray.Add("Goods.Price");
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		CurLineProducts = Goods[CurIndex__]; // LineOfATabularSection
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", CurLineProducts.LineNumber);
		
		If Not ValueIsFilled(CurLineProducts.PriceKind) And
			Not ValueIsFilled(CurLineProducts.Price) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Dạng giá"" hoặc cột ""Đơn giá""';
							|ru = 'Не заполнена колонка ""Вид цены"" или колонка ""Цена""';
							|en = '""Price type"" or ""Price"" column is not filled in'; fa = '""Price type"" or ""Price"" column is not filled in';
							|it = 'Non è compilata la colonna ""Il tipo di prezzo"" o la colonna ""Prezzo""';
							|pl = 'Nie wypełniono kolumny ""Rodzaje ceny"" lub kolumny ""Cena""';
							|tr = '""Fiyat Türü"" sütunu veya ""Fiyat"" sütunu doldurulmadı'");
			CommonClientServer.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurLineProducts.LineNumber, "PriceKind"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	If GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales")
		And (BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
			Or BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale) Then
		
		NotCheckedAttributeArray.Add("PriceGroups.PricesKind");
		
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	If ContractsAreUsed Then
		NotCheckedAttributeArray.Add("ARAPObjectSettings");
	EndIf;
	
	If Not ValueIsFilled(PlanningScenario) Then
		NotCheckedAttributeArray.Add("PlanProfile");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
	If WarehouseGroup_ And (UsedInSalesRepresentativesWork) Then
		
		ErrorText = NStr("vi = 'Cấm chọn nhóm kho bãi, nếu thỏa thuận được dùng trong công việc của đại diện thương mại';
						|ru = 'Запрещено выбирать группу складов, если соглашение используется в работе торговых представителей';
						|en = 'You cannot select a warehouse group if the agreement is used in the sales representative activity'; fa = 'You cannot select a warehouse group if the agreement is used in the sales representative activity';
						|it = 'È vietato scegliere un gruppo di magazzini, se l''accordo è utilizzato nel lavoro dei rappresentanti di vendita';
						|pl = 'Wybór grupy magazynów jest zabroniony, jeśli porozumienie jest używane w pracy przedstawicieli handlowych';
						|tr = 'Satış temsilcilerinin işlerinde anlaşma kullanılması durumunda ambar grubu seçimi yapılması yasaktır'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"Warehouse",
			,
			Cancel);
		
	EndIf;
	
	If Not Standard_ And OnlyPersonal And Not VarianceFromSalesTermsAndConditions And 
		Not Approved And Status <> Enums.StatusesOfTermsOfSales.NotApproved Then
		
		ErrorText = NStr("vi = 'Cấm thay đổi trạng thái thỏa thuận chưa thống nhất, nếu không có quyền thiết lập chênh lệch so với các điều kiện bán hàng. Cần thống nhất.';
						|ru = 'Запрещено изменять статус несогласованного соглашения, если нет прав на отклонение от условий продаж. Необходимо согласование.';
						|en = 'You cannot change the status of the unapproved agreement if you do not have rights to deviate from sales terms and conditions. Approval is required.'; fa = 'You cannot change the status of the unapproved agreement if you do not have rights to deviate from sales terms and conditions. Approval is required.';
						|it = 'È vietato modificare lo stato di un accordo non coordinato se non si ha il diritto di discostarsi dalle condizioni di vendita. È richiesto un coordinamento.';
						|pl = 'Zmiana statusu nieuzgodnionego porozumienia jest zabroniona, jeśli brak praw do odstępstwo od warunków sprzedaży. Jest konieczne uzgodnienie.';
						|tr = 'Satış şartlarından sapma hakkı yoksa, mutabık kalınmamış bir anlaşmanın durumunu değiştirmek yasaktır. Mutabakat gerekmektedir.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"Status",
			,
			Cancel);
		
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		If Not ContractsAreUsed Then
			
			ErrorText = NStr("vi = 'Khi sử dụng ""Giao hàng ủy thác"", cần sử dụng hợp đồng với các đối tác.';
							|ru = 'При использовании ""Поставки под принципала"" необходимо использовать договор с контрагентами.';
							|en = 'When using ""Procurement outsourcing"" you should use contract with counterparties.'; fa = 'When using ""Procurement outsourcing"" you should use contract with counterparties.';
							|it = 'Quando si usano ""Forniture conto mandante"" è necessario usare il contratto con controparti.';
							|pl = 'Przy użyciu ""Dostawy wg zleceniodawcy"" należy używać umowy z kontrahentami.';
							|tr = '""Tedarik dış kaynak kullanımı"" kullanılırken, cari hesap sözleşmesi kullanmanız gerekmektedir.'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				"Object.ContractsAreUsed",
				,
				Cancel);
		EndIf;
		If Not EnableAssigmentSupplyForOrders Then
			ErrorText = NStr("vi = 'Khi sử dụng ""Giao hàng ủy thác"", cần sử dụng đảm bảo riêng.';
							|ru = 'При использовании ""Поставки под принципала"" необходимо использовать обособленное обеспечение.';
							|en = 'When using ""Procurement outsourcing"" you should use an assigned fulfillment.'; fa = 'When using ""Procurement outsourcing"" you should use an assigned fulfillment.';
							|it = 'Quando si usano ""Forniture conto mandante"" è necessario usare l''approvvigionamento separato.';
							|pl = 'Przy użyciu ""Dostawy wg zleceniodawcy"" należy używać oddzelne zaopatrzenie.';
							|tr = '""Tedarik dış kaynak kullanımı"" kullanılırken, atanmış sipariş karşılama kullanmanız gerekmektedir.'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"EnableAssigmentSupplyForOrders",
				,
				Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.ChangeCatalogConsistencyFlag(
		ThisObject,
		Enums.StatusesOfTermsOfSales.NotApproved);
	
	If Standard_ Then
		Terms = Catalogs.TermsOfSale.EmptyRef();
		Partner    = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
	Else
		PartnersSegment = Catalogs.PartnersSegments.EmptyRef();
	EndIf;
	
	SalesSettingsForUsersServer.ClearUnusedSalesRules(ThisObject);
	
	If ContractsAreUsed Then
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
	EndIf;
	
	FillInPriceCalculationOption();
	
	If BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		ReturnReusablePackage = False;
		PackageDepositIsRequired         = False;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			  And ConsignmentSales25 Then
		ReturnReusablePackage   = False;
		ReusablePackageReturnCycleLength = 0;
		PackageDepositIsRequired           = False;
	EndIf;	
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Catalogs.TermsOfSale.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If PlanningScenario.IsEmpty()
		And Not PlanProfile.IsEmpty() Then
		PlanProfile = Catalogs.PlanProfiles.EmptyRef();
	EndIf;
	
	FillInServiceDetailsToRestrictAccess();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status                  = Enums.StatusesOfTermsOfSales.NotApproved;
	Approved              = False;
	ValidityStartDate      = '00010101';
	ValidityEndDate   = '00010101';
	SpecialPriceType   = Catalogs.TypesOfPrices.EmptyRef();
	
	InitializeCatalog(False);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export

	If ValueIsFilled(Partner) Then
		TabRow = Table.Add();
		TabRow.AccessValue = Partner;
	EndIf;

	If ValueIsFilled(Organization) Then
		TabRow = Table.Add();
		TabRow.AccessValue = Organization;
	EndIf;

	If ValueIsFilled(Warehouse) Then
		TabRow = Table.Add();
		TabRow.AccessValue = Warehouse;
	EndIf;

	If Table.Count() = 0 Then
		TabRow = Table.Add();
		TabRow.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
	EndIf;
	
EndProcedure

#Region InitializationAndFilling

Procedure FillInTabularPartsByAgreement(Val CustomerTermsOfSales)
	
	If CustomerTermsOfSales <> PredefinedValue("Catalog.TermsOfSale.EmptyRef") Then
		Query = New Query(
		"SELECT
		|	TermsOfSale.Goods.(
		|		Ref,
		|		LineNumber,
		|		Products,
		|		Characteristic,
		|		Package,
		|		PriceKind,
		|		Price,
		|		DeliveryPeriodDays
		|	) AS Goods,
		|	TermsOfSale.PriceGroups.(
		|		Ref,
		|		LineNumber,
		|		PriceGroup,
		|		PricesKind,
		|		DeliveryPeriodDays,
		|		PercentRateOfManualDiscount,
		|		MaximumPercentageForManualMarkup
		|	) AS PriceGroups,
		|	TermsOfSale.PaymentScheduleSteps.(
		|		Ref,
		|		LineNumber,
		|		PaymentOption,
		|		CalculateFrom,
		|		Move,
		|		PaymentPercentage
		|	) AS PaymentScheduleSteps
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|WHERE
		|	TermsOfSale.Ref = &CustomerTermsOfSales");
		
		Query.SetParameter("CustomerTermsOfSales", CustomerTermsOfSales);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		Goods.Load(Selection.Goods.Unload());
		PriceGroups.Load(Selection.PriceGroups.Unload());
		PaymentScheduleSteps.Load(Selection.PaymentScheduleSteps.Unload());
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnPartner(Val Basis)
	
	Partner = Basis;
	SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
	FillInDefaultSalesConditions();
	
EndProcedure

Procedure FillInDocumentBasedOnCounterparty(Val Basis)
	
	Partner = Basis.Partner;
	SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
	FillInDefaultSalesConditions();
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
		FillInDefaultSalesConditions();
		
	ElsIf FillingData.Property("PartnerSelection_") Then
		
		Partner = FillingData.PartnerSelection_;
		SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
		FillInDefaultSalesConditions();
		
	EndIf;
	
	If FillingData.Property("Organization") Then
		Organization = FillingData.Organization;
	EndIf;
	
	If FillingData.Property("BusinessOperation") Then
		BusinessOperation = FillingData.BusinessOperation;
		
		If BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
			ContractsAreUsed = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure InitializeCatalog(FillInAllDetails = True)

	Manager = Users.CurrentUser();
	If Not GetFunctionalOption("UseApprovalOfTermsOfSales")
	 Or UserRightsCached.VarianceFromSalesTermsAndConditions() Then
		Status = Enums.StatusesOfTermsOfSales.Valid;
	Else
		Status = Enums.StatusesOfTermsOfSales.NotApproved;
	EndIf;
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	EndIf;
	
	If FillInAllDetails Then
		
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		ARAPCurrency = Currency;
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse, GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"));
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
		FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation);
	
		Attributes = New Structure("ContractsAreUsed,ARAPObjectSettings");
		ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, Attributes);
		
	EndIf;
	
EndProcedure

Procedure FillInServiceDetailsToRestrictAccess() Export
	
	If Standard_ Then
		AgreementKindToLimitReadAccess    = Enums.KindOfTermsOfSalesToRestrictReadAccess.Standard3;
		AgreementKindToLimitEditAccess = Enums.KindOfTermsOfSalesToRestrictEditAccess.Standard3;
	Else
		AgreementKindToLimitReadAccess    = Enums.KindOfTermsOfSalesToRestrictReadAccess.SpecialTerms;
		AgreementKindToLimitEditAccess = Enums.KindOfTermsOfSalesToRestrictEditAccess.SpecialTerms;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
