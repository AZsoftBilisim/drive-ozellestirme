
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AttributesToEdit  = Parameters.AttributesToEdit;
	BusinessOperation = Parameters.BusinessOperation;
	Organization = Parameters.Organization;
	Partner = Parameters.Partner;
	Counterparty = Parameters.Counterparty;
	RecordInManAccounting = Parameters.RecordInManAccounting;
	RecordInLocalAccounting = Parameters.RecordInLocalAccounting;
	PostInAccounting = Parameters.PostInAccounting;
	RecordInTA = Parameters.RecordInTA;
	PostInFinancialAndTaxAccounting = Parameters.PostInFinancialAndTaxAccounting;
	RecordInOperationalAccounting = Parameters.RecordInOperationalAccounting;
	RecordInMA = Parameters.RecordInMA;
	Date = Parameters.Date;
	Ref = Parameters.Ref;
	AddressOfDataInLinkedTables = Parameters.AddressOfDataInLinkedTables;
	ReadOnly = Parameters.ReadOnly;
	
	If Parameters.Property("AttributesValues") Then
		FillPropertyValues(ThisObject, Parameters.AttributesValues);
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
	
	LeasedAssetAccounting.CheckSchedule(
		ServicePaymentSchedule, 
		"ServicePaymentSchedule", 
		"RentalService,DepositPayment,BuyoutValue", 
		Cancel);
		
	LeasedAssetAccounting.CheckSchedule(
		ServiceAccrualSchedule, 
		"ServiceAccrualSchedule", 
		"RentalService,DepositPayment,BuyoutValue", 
		Cancel);
	
	LeasedAssetAccounting.CheckSchedule(
		InterestAccrualSchedule, 
		"InterestAccrualSchedule", 
		"Interests", 
		Cancel);
	
	If Not RecordInOperationalAccounting
		Or Not AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed Then
		NotCheckedAttributeArray.Add("ServicePaymentSchedule");
		NotCheckedAttributeArray.Add("ServiceAccrualSchedule");
		NotCheckedAttributeArray.Add("InterestAccrualSchedule");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PaymentBalancesPage

&AtClient
Procedure ContractOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);

EndProcedure

&AtClient
Procedure LeaseObligationsBalanceOnChange(Item)
	
	If Items.LeaseLiabilityBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And LeaseLiabilityBalanceLocal = AttributesValuesBeforeChange.LeaseObligationsBalance Then
		LeaseLiabilityBalanceLocal = LeaseObligationsBalance;
	EndIf;
	
	If Items.LeaseLiabilityBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And LeaseLiabilityBalanceMan = AttributesValuesBeforeChange.LeaseObligationsBalance Then
		LeaseLiabilityBalanceMan = LeaseObligationsBalance;
	EndIf;

	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure LeaseLiabilityBalanceLocalOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure LeaseLiabilityBalanceManOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure RentalServiceBalanceOnChange(Item)
	
	If Items.RentalServiceBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And RentalServiceBalanceLocal = AttributesValuesBeforeChange.RentalServiceBalance Then
		RentalServiceBalanceLocal = RentalServiceBalance;
	EndIf;
	
	If Items.RentalServiceBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And RentalServiceBalanceMan = AttributesValuesBeforeChange.RentalServiceBalance Then
		RentalServiceBalanceMan = RentalServiceBalance;
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure RentalServiceBalanceLocalOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure RentalServiceBalanceManOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure BuyoutValueBalanceOnChange(Item)
	
	If Items.BuyoutValueBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And BuyoutValueBalanceLocal = AttributesValuesBeforeChange.BuyoutValueBalance Then
		BuyoutValueBalanceLocal = BuyoutValueBalance;
	EndIf;
	
	If Items.BuyoutValueBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And BuyoutValueBalanceMan = AttributesValuesBeforeChange.BuyoutValueBalance Then
		BuyoutValueBalanceMan = BuyoutValueBalance;
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure BuyoutValueBalanceLocalOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure BuyoutValueBalanceManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure VATBalanceOnChange(Item)
	
	If Items.VATBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And VATBalanceLocal = AttributesValuesBeforeChange.VATBalance Then
		VATBalanceLocal = VATBalance;
	EndIf;
	
	If Items.VATBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And VATBalanceMan = AttributesValuesBeforeChange.VATBalance Then
		VATBalanceMan = VATBalance;
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure VATBalanceLocalOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure VATBalanceManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure InterestsBalanceOnChange(Item)
	
	If Items.InterestBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And InterestBalanceLocal = AttributesValuesBeforeChange.InterestsBalance Then
		InterestBalanceLocal = InterestsBalance;
	EndIf;
	
	If Items.InterestBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And InterestBalanceMan = AttributesValuesBeforeChange.InterestsBalance Then
		InterestBalanceMan = InterestsBalance;
	EndIf;
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure InterestBalanceLocalOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure InterestBalanceManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

#EndRegion

#Region PagePaymentsUnderTheContract

&AtClient
Procedure RentalPeriodURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	
	LeasedAssetAccountingClient.EnterLeaseTerm(
		ThisObject, 
		ThisObject, 
		New CallbackDescription("EnterLeaseTermCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PaymentFrequencyOnChange(Item)
	
	If Not ValueIsFilled(PaymentFrequency) Then
		PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure AccrualFrequencyOnChange(Item)
	
	If Not ValueIsFilled(AccrualFrequency) Then
		AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

#EndRegion

#Region PaymentAndDeductionSchedules

&AtClient
Procedure ServicePaymentScheduleOnChange(Item)
	ConfigureDependentFormElements(Item);	
EndProcedure

&AtClient
Procedure ServiceAccrualScheduleOnChange(Item)
	ConfigureDependentFormElements(Item);	
EndProcedure

&AtClient
Procedure InterestAccrualScheduleOnChange(Item)
	ConfigureDependentFormElements(Item);	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersPrepaymentsUnderLeaseContracts

&AtClient
Procedure PrepaymentsUnderLeaseContractsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow 
		And Not Copy
		And AuxiliaryAttributes.ContractDetails_ <> Undefined Then
		
		CurrentData = Items.PrepaymentsUnderLeaseContracts.CurrentData;
		If AuxiliaryAttributes.ContractDetails_.HasSecurityDeposit Then
			CurrentData.PaymentType = PredefinedValue("Enum.TypesOfLeasePayments.DepositPayment");
		Else
			CurrentData.PaymentType = PredefinedValue("Enum.TypesOfLeasePayments.BuyoutValuePrepayment");
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
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

#EndRegion

#Region Private

#Region OnChangeAttributes

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
	AuxiliaryAttributes = Form.AuxiliaryAttributes;
	
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
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
							
	#Region PaymentBalancesPage
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
	
		Items.DecorationBalancesInTheContractCurrency.Visible = 
			Items.LeaseObligationsBalance.Visible
			Or Items.RentalServiceBalance.Visible
			Or Items.BuyoutValueBalance.Visible
			Or Items.VATBalance.Visible
			Or Items.InterestsBalance.Visible;
			
		Items.DecorationRemnantsOfRegl.Visible = 
			Items.LeaseLiabilityBalanceLocal.Visible
			Or Items.RentalServiceBalanceLocal.Visible
			Or Items.BuyoutValueBalanceLocal.Visible
			Or Items.VATBalanceLocal.Visible
			Or Items.InterestBalanceLocal.Visible;

		Items.DecorationRemainsOfUPR.Visible = 
			Items.LeaseLiabilityBalanceMan.Visible
			Or Items.RentalServiceBalanceMan.Visible
			Or Items.BuyoutValueBalanceMan.Visible
			Or Items.VATBalanceMan.Visible
			Or Items.InterestBalanceMan.Visible;

		//
		Items.LeaseObligationsBalanceDecoration.Visible =
			Items.LeaseObligationsBalance.Visible
			Or Items.LeaseLiabilityBalanceLocal.Visible
			Or Items.LeaseLiabilityBalanceMan.Visible;

		Items.ServiceRentalTheRestOfTheDecorations.Visible =
			Items.RentalServiceBalance.Visible
			Or Items.RentalServiceBalanceLocal.Visible
			Or Items.RentalServiceBalanceMan.Visible;

		Items.PurchasePriceBalanceDecoration.Visible =
			Items.BuyoutValueBalance.Visible
			Or Items.BuyoutValueBalanceLocal.Visible
			Or Items.BuyoutValueBalanceMan.Visible;

		Items.HastalikDecoration.Visible =
			Items.VATBalance.Visible
			Or Items.VATBalanceLocal.Visible
			Or Items.VATBalanceMan.Visible;

		Items.InterestTheRestOfTheDecorations.Visible =
			Items.InterestsBalance.Visible
			Or Items.InterestBalanceLocal.Visible
			Or Items.InterestBalanceMan.Visible;

		//
		Items.LeaseLiabilitiesDebitBalance.Visible = 
			Items.LeaseObligationsBalance.Visible
			Or Items.LeaseLiabilityBalanceLocal.Visible
			Or Items.LeaseLiabilityBalanceMan.Visible;
		
		Items.RentalServiceDebitBalance.Visible = 
			Items.RentalServiceBalance.Visible
			Or Items.RentalServiceBalanceLocal.Visible
			Or Items.RentalServiceBalanceMan.Visible;
		
		Items.BuyoutValueDebitBalance.Visible = 
			Items.BuyoutValueBalance.Visible
			Or Items.BuyoutValueBalanceLocal.Visible
			Or Items.BuyoutValueBalanceMan.Visible;

		Items.VATDebitBalance.Visible = 
			Items.VATBalance.Visible
			Or Items.VATBalanceLocal.Visible
			Or Items.VATBalanceMan.Visible;

		Items.InterestDebitBalance.Visible = 
			Items.InterestsBalance.Visible
			Or Items.InterestBalanceLocal.Visible
			Or Items.InterestBalanceMan.Visible;

		//
		Items.TheSceneryRemainsBalance.Visible = 
			Items.LeaseLiabilitiesDebitBalance.Visible
			Or Items.RentalServiceDebitBalance.Visible
			Or Items.BuyoutValueDebitBalance.Visible
			Or Items.VATDebitBalance.Visible
			Or Items.InterestDebitBalance.Visible;
		
	EndIf;
	
	If StructureOfChangedProps.Property("LeaseObligationsBalance")
		Or StructureOfChangedProps.Property("LeaseLiabilityBalanceLocal")
		Or StructureOfChangedProps.Property("LeaseLiabilityBalanceMan")
		Or StructureOfChangedProps.Property("RentalServiceBalance")
		Or StructureOfChangedProps.Property("RentalServiceBalanceLocal")
		Or StructureOfChangedProps.Property("RentalServiceBalanceMan")
		Or StructureOfChangedProps.Property("BuyoutValueBalance")
		Or StructureOfChangedProps.Property("BuyoutValueBalanceLocal")
		Or StructureOfChangedProps.Property("BuyoutValueBalanceMan")
		Or StructureOfChangedProps.Property("VATBalance")
		Or StructureOfChangedProps.Property("VATBalanceLocal")
		Or StructureOfChangedProps.Property("VATBalanceMan")
		Or StructureOfChangedProps.Property("InterestsBalance")
		Or StructureOfChangedProps.Property("InterestBalanceLocal")
		Or StructureOfChangedProps.Property("InterestBalanceMan") Then
			
		UpdateDetailsValuesBeforeChange(Form);
	EndIf;
	#EndRegion
	
	#Region TheAdvancesPage
	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		Items.PrepaymentsUnderLeaseContractsPaymentType.Visible = 
			ContractDetails_.HasSecurityDeposit
			And ContractDetails_.ThereIsPrepaymentOfBuyoutValue;
			
		Items.PrepaymentsUnderLeaseContracts.Visible = 
			ContractDetails_.HasSecurityDeposit
			Or ContractDetails_.ThereIsPrepaymentOfBuyoutValue;
			
		If ContractDetails_.HasSecurityDeposit
			And Not ContractDetails_.ThereIsPrepaymentOfBuyoutValue Then
			Items.TheAdvancesPage.Title = NStr("vi = 'Thanh toán đảm bảo';
												|ru = 'Обеспечительные платежи';
												|en = 'Security deposits'; fa = 'Security deposits';
												|it = 'Caparre';
												|pl = 'Płatności zabezpieczające';
												|tr = 'Güvenlik ödemeleri'");
		ElsIf ContractDetails_.ThereIsPrepaymentOfBuyoutValue
			And Not ContractDetails_.HasSecurityDeposit Then
			Items.TheAdvancesPage.Title = NStr("vi = 'Ứng trước tiền mua lại';
												|ru = 'Авансирование выкупной стоимости';
												|en = 'Buyout value prepayment'; fa = 'پیش‌پرداخت ارزش بازخرید';
												|it = 'Pagamento anticipato del valore di rimborso';
												|pl = 'Zaliczkowanie wartości wykupu';
												|tr = 'İtfa değerinin artırılması'");
		Else
			Items.TheAdvancesPage.Title = NStr("vi = 'Thanh toán trước';
												|ru = 'Авансовые платежи';
												|en = 'Advance payments'; fa = 'پیش‌پرداخت‌ها';
												|it = 'Pagamenti anticipati';
												|pl = 'Płatności zaliczkowe';
												|tr = 'Avans ödemeler'");
		EndIf;
		
	EndIf;
	#EndRegion
		
	#Region PagePaymentsUnderTheContract
	
	If UpdateAll Then
		
		Items.SecurityPaymentAmountCurrency.Visible = Items.SecurityDepositAmount.Visible;
		Items.AmountOfRentalServicesCurrency.Visible = Items.LeaseServicesAmount.Visible;
		Items.PurchaseAmountOfRentalItemsCurrency.Visible = Items.AmountOfLeaseAssetsByuout.Visible;
		Items.AmountOfPersonalIncomeTax.Visible = Items.VATAmount.Visible;
		Items.CostOfRentalItemsCurrency.Visible = Items.LeaseItemsCost.Visible;
		Items.DecorationInterestRate.Visible = Items.InterestRate.Visible;
		Items.InterestAmountCurrency.Visible = Items.InterestAmount.Visible;
		
	EndIf;
	
	If StructureOfChangedProps.Property("PaymentFrequency")
		Or StructureOfChangedProps.Property("AccrualFrequency")
		Or UpdateAll Then
			
		Items.PaymentForRentalServicesCurrency.Visible = Items.PaymentForLeaseService.Visible;
		Items.AccrualOfRentalServicesCurrency.Visible = Items.AccrualOfLeaseService.Visible;
	EndIf;
		
	If StructureOfChangedProps.Property("TermYears")
		Or StructureOfChangedProps.Property("TermMonths")
		Or StructureOfChangedProps.Property("TermDays")
		Or StructureOfChangedProps.Property("LeaseStartDate")
		Or UpdateAll Then

		Form.RentalPeriod = NonCurrentAssetsClientServer.PresentationWithFormattedString(
								Form.TermYears, 
								Form.TermMonths, 
								Form.TermDays, 
								Form.LeaseStartDate, 
								Form.ReadOnly);
		
	EndIf;
	
	#EndRegion
	
	#Region PaymentAndDeductionSchedules
	
	If UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.RecordInOperationalAccounting;
			
		Items.ServicePaymentSchedule.Visible = PropertyValue;
		Items.ServiceAccrualSchedule.Visible = PropertyValue;
			
	EndIf;

	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		If ContractDetails_.HasSecurityDeposit Then
			Items.ServiceAccrualScheduleGroup.ShowInHeader = True;
			Items.ServiceAccrualScheduleRentalService.Title = NStr("vi = 'Trong phần thanh toán tiền thuê';
																	|ru = 'В части арендного платежа';
																	|en = 'In part of rental payment'; fa = 'در بخش پرداخت اجاره';
																	|it = 'In termini di pagamento dell''affitto';
																	|pl = 'W części płatności dzierżawnej';
																	|tr = 'Kira ödemesinin bir bölümünde'");
			Items.ServiceAccrualScheduleDepositPayment.Visible = True;
		Else
			Items.ServiceAccrualScheduleGroup.ShowInHeader = False;
			Items.ServiceAccrualScheduleRentalService.Title = NStr("vi = 'Số tiền dịch vụ thuê';
																	|ru = 'Сумма начисления услуг по аренде';
																	|en = 'Amount of accrued rental services'; fa = 'مبلغ خدمات اجاره محاسبه‌شده';
																	|it = 'Importo della maturazione dei servizi relativi all''affitto';
																	|pl = 'Wartość naliczania usług dotyczących dzierżawy';
																	|tr = 'Kiralama hizmetlerinin tahakkuk tutarı'");
			Items.ServiceAccrualScheduleDepositPayment.Visible = False;
		EndIf;
		
		Items.ServicePaymentScheduleDepositPayment.Visible = ContractDetails_.HasSecurityDeposit;
		Items.ServicePaymentScheduleBuyoutValue.Visible = ContractDetails_.ThereIsPrepaymentOfBuyoutValue;

		//
		PropertyValue = 
			AuxiliaryAttributes.RecordInOperationalAccounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		Items.InterestAccrualSchedule.Visible = PropertyValue;

	EndIf;

	If StructureOfChangedProps.Property("ServicePaymentSchedule")
		Or UpdateAll Then
		Form.PaymentNumberOfLines = Form.ServicePaymentSchedule.Count();
	EndIf;
	
	If StructureOfChangedProps.Property("ServiceAccrualSchedule")
		Or UpdateAll Then
		Form.AccrualNumberOfLines = Form.ServiceAccrualSchedule.Count();
	EndIf;
	
	If StructureOfChangedProps.Property("InterestAccrualSchedule")
		Or UpdateAll Then
		Form.PercentagesNumberOfRows = Form.InterestAccrualSchedule.Count();
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, True);
		
		ContractCurrency = AuxiliaryAttributes.ContractDetails_.ARAPCurrency;
		Items.DecorationBalancesInTheContractCurrency.Title = String(ContractCurrency);
		
	EndIf;
	
	If UpdateAll Then
		
		Items.DecorationRemainsOfUPR.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
																|ru = 'Упр. (%1):';
																|en = 'Mgmt (%1):'; fa = 'Mgmt (%1):';
																|it = 'Gest. (%1):';
																|pl = 'Zarz. (%1):';
																|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
		Items.DecorationRemnantsOfRegl.Title = StrTemplate(NStr("vi = 'Reg. (%1):';
																|ru = 'Регл. (%1):';
																|en = 'Local (%1):'; fa = 'Local (%1):';
																|it = 'Regol. (%1):';
																|pl = 'Reg. (%1):';
																|tr = 'Yerel (%1):'"), String(ComplCurrency));
		
		//
		If ReadOnly Then
			Items.FormWriteAndClose.Enabled = False;
		EndIf;
		
	EndIf;	
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

EndProcedure

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Object, ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("FinancialAccountingGroup")
		Or StructureOfChangedProps.Property("Contract") Then
		Return True;
	EndIf; 
	
	Return False;

EndFunction

#EndRegion

#Region Schedules

&AtClient
Procedure ImportChart(ChartName)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartName", ChartName);
	FormParameters.Insert("UniqueOwnerID", UUID);
	FormParameters.Insert("HasSecurityDeposit", AuxiliaryAttributes.ContractDetails_.HasSecurityDeposit);
	FormParameters.Insert("ThereIsBuyoutOfLeasedAssets", ChartName = "ServicePaymentSchedule" And AuxiliaryAttributes.ContractDetails_.ThereIsPrepaymentOfBuyoutValue);
	
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
	
	ConfigureDependentFormElementsOnServer(ChartName);
	
EndProcedure

&AtClient
Procedure EnterLeaseTermCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;

	ConfigureDependentFormElements("LeaseStartDate,TermYears,TermMonths,TermDays");
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	GetDataFromLinkedTables();
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	UpdateDetailsValuesBeforeChange(ThisObject);
	
	ConfigureDependentFormElementsOnServer();

	If Parameters.NewRow And Not Parameters.Copy Then
		FillInDefaultValues();
	EndIf;
	
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
		QueryText = NStr("vi = 'Chưa điện trường bắt buộc.
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
	
	EditResult = New Structure(AttributesToEdit);
	FillPropertyValues(EditResult, ThisObject);
	
	PlaceDataFromRelatedTablesInTemporaryStorage();

	Modified = False;
	
	Close(EditResult);
	
EndProcedure

&AtServer
Procedure GetDataFromLinkedTables()

	If Not IsTempStorageURL(AddressOfDataInLinkedTables) Then
		Return;
	EndIf;
	
	TablesData = GetFromTempStorage(AddressOfDataInLinkedTables);
	
	If TablesData = Undefined Then
		Return;
	EndIf;
	
	ServicePaymentSchedule.Load(TablesData.ServicePaymentSchedule);
	ServiceAccrualSchedule.Load(TablesData.ServiceAccrualSchedule);
	InterestAccrualSchedule.Load(TablesData.InterestAccrualSchedule);
	PrepaymentsUnderLeaseContracts.Load(TablesData.PrepaymentsUnderLeaseContracts);
	
EndProcedure

&AtServer
Procedure PlaceDataFromRelatedTablesInTemporaryStorage()
	
	If Not AuxiliaryAttributes.ContractDetails_.HasSecurityDeposit
		And Not AuxiliaryAttributes.ContractDetails_.ThereIsPrepaymentOfBuyoutValue Then
		PrepaymentsUnderLeaseContracts.Clear();
	EndIf;
	
	TablesData = New Structure;
	TablesData.Insert("ServicePaymentSchedule", ServicePaymentSchedule.Unload());
	TablesData.Insert("ServiceAccrualSchedule", ServiceAccrualSchedule.Unload());
	TablesData.Insert("InterestAccrualSchedule", InterestAccrualSchedule.Unload());
	TablesData.Insert("PrepaymentsUnderLeaseContracts", PrepaymentsUnderLeaseContracts.Unload());
	
	PutToTempStorage(TablesData, AddressOfDataInLinkedTables);
	
EndProcedure

&AtServer
Procedure FillInDefaultValues()

	If Items.VATDebitBalance.Visible Then
		VATDebitBalance = True;
	EndIf;
	
	If Items.InterestDebitBalance.Visible Then
		InterestDebitBalance = True;
	EndIf;
		
	If Items.PaymentFrequency.Visible Then
		PaymentFrequency = Enums.ScheduleTimeFence.Custom;
	EndIf;
		
	If Items.AccrualFrequency.Visible Then
		AccrualFrequency = Enums.ScheduleTimeFence.Custom;
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDetailsValuesBeforeChange(Form)

	AttributesList = 
	"LeaseObligationsBalance,LeaseLiabilityBalanceLocal,LeaseLiabilityBalanceMan,
	|RentalServiceBalance,RentalServiceBalanceLocal,RentalServiceBalanceMan,
	|BuyoutValueBalance,BuyoutValueBalanceLocal,BuyoutValueBalanceMan,
	|VATBalance,VATBalanceLocal,VATBalanceMan,
	|InterestsBalance,InterestBalanceLocal,InterestBalanceMan";
	
	NewValues = New Structure(AttributesList);
	FillPropertyValues(NewValues, Form);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(NewValues);
	
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
