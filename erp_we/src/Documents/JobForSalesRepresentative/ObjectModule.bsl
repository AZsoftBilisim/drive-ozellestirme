#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds rows with descriptions of tasks that can be generated automatically to the table part of the Task.
//
Procedure AddAutomaticTasks() Export
	
	UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
	If UsingTasks = Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning Then
		
		// Adding an overdue payment control task
		If ARAPByOrders.Total("ForPaymentOverdue")>0 Then
			If Tasks.Find("Draw attention to1 overdue_3 payment_0", "TaskDetails1")= Undefined Then
				NewRow = Tasks.Add();
				NewRow.TaskDetails1 = NStr("vi = 'Chú ý đến khoản thanh toán quá hạn';
											|ru = 'Обратить внимание на просроченную оплату';
											|en = 'Pay attention to overdue payment'; fa = 'Pay attention to overdue payment';
											|it = 'Prestare attenzione al pagamento arretrato';
											|pl = 'Zwróć uwagę na zaległą płatność';
											|tr = 'Vadesi geçmiş ödemelere dikkat edin'");
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the product line based on sales history data.
//
// Parameters:
//  PeriodDetails - Structure - a structure containing the following elements:
//		* Period - String - detailing the grouping of information by period (Day, Week, Month)
//		* BeginOfPeriod - Date - the start date of the period for which the sales history is analyzed
//		* EndOfPeriod - Date - the end date of the period for which the sales history is analyzed
//  CharacteristicsDetails - Boolean - indicates whether the task should be detailed by characteristics.
//
Procedure FillInSalesHistory(PeriodDetails, CharacteristicsDetails=False) Export

	Period = PeriodDetails.Period;
	BeginOfPeriod = PeriodDetails.BeginOfPeriod;
	EndOfPeriod = PeriodDetails.EndOfPeriod;
	
	If ItemsDetails Then
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistory");
	Else
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistoryByAmount");
		CharacteristicsDetails=False;
	EndIf;

	CompositionSettings = CompositionSchema.DefaultSettings;	
	
	MobileApps.SetUseOfLayoutField(CompositionSettings, "Characteristic", CharacteristicsDetails);
	MobileApps.SetFilterItemValue(CompositionSettings.Filter, "Partner",, True, Partner);
	
	If ValueIsFilled(Counterparty) Then
		MobileApps.SetFilterItemValue(CompositionSettings.Filter, "Counterparty",, True, Counterparty);
	EndIf;
	
	MobileApps.SetValueOfSettingsParameter(CompositionSettings, "CharacteristicsDetails", CharacteristicsDetails);

	QueryResult = SalesRepresentativesServer.MakeRequestForSalesHistory(
		CompositionSettings, 
		BeginOfPeriod,
		EndOfPeriod,
		Period,
		ItemsDetails);

	QueryTable = QueryResult.Unload();
	
	If ItemsDetails Then
		
		Goods.Clear();
		For Each CurRow In QueryTable Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow,CurRow);
			NewRow.NumberOfPackagesPlan = NewRow.CountPlan;
		EndDo;
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		// The fill parameters
		FillingStructure = New Structure;
		FillingStructure.Insert("Date", Date);
		FillingStructure.Insert("Organization", Organization);
		FillingStructure.Insert("Currency", Currency);
		FillingStructure.Insert("Terms", Terms);
		FillingStructure.Insert("VATTaxation", VATTaxation);
		FillingStructure.Insert("ReturnReusablePackage", ToReturnReusablePackage);
		FillingStructure.Insert("PopulationFields", "Price, VATRate, PriceKind");
					
		StructureOfRecalculation = New Structure("Clear", False);
		
		// The structure of the action with the changed strings
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfRecalculation);
					
		EnterprisePricesFillingServer.FillInPrices(Goods, , FillingStructure, StructureOfActions);
		
	Else
		
		SumOfSalesHistory = QueryTable.Total("Sum");
		CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
		
		If Currency <> CurrencyOfManAccounting Then
			StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfManAccounting, Date);
			StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, Date);
			
			SumOfSalesHistory = ProcessingOfExchangeRatesTM.ConvertAtRate(SumOfSalesHistory,
                     StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		EndIf;
		
		SumPlan = SumOfSalesHistory;
		
	EndIf;

EndProcedure

// Fills in the task with information about the status of settlements with the client.
//
Procedure FillInDataOnAccountsReceivable() Export
	
	If ARAPByOrders.Count()>0 Then
		ARAPByOrders.Clear();
	EndIf;
	
	If ReceivablesDrillDownReport.Count()>0 Then
		ReceivablesDrillDownReport.Clear();
	EndIf;
	
	If ValueIsFilled(Partner) Then
		DebtDataStructure = SalesRepresentativesServer.GetDataOnPartnerAccountsReceivable(Partner, PlannedVisitDate);
		ARAPByOrders.Load(DebtDataStructure.TableOfDebts);
		ReceivablesDrillDownReport.Load(DebtDataStructure.RegisterRecordTable);
	EndIf;
	
EndProcedure

#Region SalesTermsAndConditions

// Fills in the sales terms in the sales representative task.
//
// Parameters:
//  SalesTermsAndConditions - Structure - a structure containing sales conditions data. Structure properties:
//  	* Currency - CatalogRef.Currencies - the currency used.
//  	* BusinessOperation - EnumRef.BusinessTransactions - economic operation.
//  	* PaymentSchedule - CatalogRef.PaymentSchedules - payment schedule.
//  	* PaymentMethod - EnumRef.PaymentForms - payment form.
//  	* PriceIncludesVAT - Boolean - indicates whether VAT is included.
//  	* VATTaxation - EnumRef.VATTaxationTypes - type of VAT taxation.
//  	* ReturnReusablePackage - Boolean - indicates whether a multi-turn container must be returned.
//  	* ReusablePackageReturnCycleLength - Number - the deadline for returning the container.
//  	* PackageDepositIsRequired - Boolean - indicates whether a deposit is required for the container.
//  	* Organization - CatalogRef.Companies - Organization.
//  	* Warehouse - CatalogRef.Warehouses - warehouse.
//  	* Counterparty - CatalogRef.Counterparties - Contractor.
//  	* Standard_ - Boolean - indicates that the agreement used is a standard agreement.
//
Procedure FillIn_TermsOfSales(SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	DocumentSales = ThisObject;
	
	DocumentSales.Currency = SalesTermsAndConditions.Currency;
	DocumentSales.BusinessOperation = SalesTermsAndConditions.BusinessOperation;
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
		DocumentSales.PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
	EndIf;
	
	DocumentSales.PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	DocumentSales.PriceIncludesVAT    = SalesTermsAndConditions.PriceIncludesVAT;
	DocumentSales.ToReturnReusablePackage = SalesTermsAndConditions.ReturnReusablePackage;
	DocumentSales.ReusablePackageReturnCycleLength = SalesTermsAndConditions.ReusablePackageReturnCycleLength;
	DocumentSales.PackageDepositIsRequired = SalesTermsAndConditions.PackageDepositIsRequired;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) Then
		DocumentSales.Organization = SalesTermsAndConditions.Organization;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		DocumentSales.Warehouse = SalesTermsAndConditions.Warehouse;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Counterparty) And Not ValueIsFilled(DocumentSales.Counterparty) Then
		If Not SalesTermsAndConditions.Standard_ Then
			DocumentSales.Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	Contract = SalesServer.GetDefaultContract(ThisObject, BusinessOperation, Currency);
	StartDate = ?(ValueIsFilled(DocumentSales.Date), DocumentSales.Date,
		Common.CurrentUserDate());
	
	If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays) Then
		DocumentSales.RequestShipmentOn = TMCommonUseClientServer.CalculatePeriodEndDate(StartDate,
			Enums.Periodicity.Day, SalesTermsAndConditions.DeliveryPeriodDays) + 1;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
EndProcedure

// Fills in the sales terms in the default sales representative task
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("OnlyUsedBySalesRepresentative", True);
		FilterParameters.Insert("SelectedAgreement", Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.JobForSalesRepresentative.EmptyRef());
					
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters);
			
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				
				FillParameters = Documents.JobForSalesRepresentative.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
				If ToUseTermsOfSales Then
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					// The fill parameters
					FillingStructure = New Structure;
					FillingStructure.Insert("Date", Date);
					FillingStructure.Insert("Organization", Organization);
					FillingStructure.Insert("Currency", Currency);
					FillingStructure.Insert("Terms", Terms);
					FillingStructure.Insert("VATTaxation", VATTaxation);
					FillingStructure.Insert("ReturnReusablePackage", ToReturnReusablePackage);
					FillingStructure.Insert("PopulationFields", "Price, VATRate, PriceKind");
							
					StructureOfRecalculation = New Structure("Clear", False);
					
					// The structure of the action with the changed strings
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfRecalculation);
						
					EnterprisePricesFillingServer.FillInPrices(Goods, , FillingStructure, StructureOfActions);
					
				EndIf;
			Else
				Terms = DefaultSalesTerms.Terms;
			EndIf;
			
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
		
	EndIf;

EndProcedure

// Fills in the terms of sales in the task to the sales representative under the agreement
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
	FillIn_TermsOfSales(SalesTermsAndConditions);

	FillParameters = Documents.JobForSalesRepresentative.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	// The fill parameters
	FillingStructure = New Structure;
	FillingStructure.Insert("Date", Date);
	FillingStructure.Insert("Organization", Organization);
	FillingStructure.Insert("Currency", Currency);
	FillingStructure.Insert("Terms", Terms);
	FillingStructure.Insert("VATTaxation", VATTaxation);
	FillingStructure.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FillingStructure.Insert("PopulationFields", "Price, VATRate, PriceKind");
			
	StructureOfRecalculation = New Structure("Clear", False);
	
	// The structure of the action with the changed strings		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount );
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfRecalculation);
		
	EnterprisePricesFillingServer.FillInPrices(Goods,	, FillingStructure, StructureOfActions);
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);

EndProcedure

// Fills in the terms of sales in the sales representative task for the agreement data
//
Procedure FillInDocumentAccordingToAgreement() Export
	
	StructureOfTermsOfAgreement = SalesServer.GetTermsAndConditionsOfSale(Terms);
	
	If ValueIsFilled(StructureOfTermsOfAgreement.Organization) Then
		Organization = StructureOfTermsOfAgreement.Organization;
	EndIf;
	
	Currency = StructureOfTermsOfAgreement.Currency;
	PriceIncludesVAT = StructureOfTermsOfAgreement.PriceIncludesVAT;
	PaymentSchedule = StructureOfTermsOfAgreement.PaymentSchedule;
	
	If ValueIsFilled(StructureOfTermsOfAgreement.Warehouse) Then
		Warehouse = StructureOfTermsOfAgreement.Warehouse;
	EndIf;
	
	If Not ValueIsFilled(Counterparty) Then
		DefaultCounterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner);
		If DefaultCounterparty <> Undefined Then
			Counterparty = DefaultCounterparty;
		EndIf;
	EndIf;
	
	FillParameters = Documents.JobForSalesRepresentative.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);

EndProcedure

#EndRegion

#Region ServiceTerms

// Fills in the terms of sale in the sales representative task for the terms of service.
//
Procedure FillInTermsOfSalesUnderTermsOfService() Export
	
	If Not ValueIsFilled(ServiceTerms) Then
		Return;
	EndIf;
	
	ConditionsStructure = SalesRepresentativesServer.GetTermsOfService(ServiceTerms);
	
	If GetFunctionalOption("ToUseTermsOfSales")
		And Terms <> ConditionsStructure.Terms And ValueIsFilled(ConditionsStructure.Terms) Then
		Terms = ConditionsStructure.Terms;
		FillInTermsOfSalesUnderAgreement();
	EndIf;
	
	If ValueIsFilled(ConditionsStructure.Supervisor_) Then
		Supervisor_ = ConditionsStructure.Supervisor_;
	EndIf;
	
	If ValueIsFilled(ConditionsStructure.SalesRepresentative) Then
		SalesRepresentative = ConditionsStructure.SalesRepresentative;
	EndIf;
	
	PlannedVisitDate = ConditionsStructure.PlannedVisitDate;
	BeginTime    = ConditionsStructure.BeginTime;
	EndTime = ConditionsStructure.EndTime;

EndProcedure

// Fills in the terms of sales in the task to the sales representative for the default terms of service.
//
Procedure FillInDefaultTermsOfService() Export
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
	
	UseAgreements = GetFunctionalOption("ToUseTermsOfSales");
	OldAgreement       = Terms;
	
	ConditionsStructure = SalesRepresentativesServer.GetDefaultTermsOfService(Partner);
	
	If ConditionsStructure <> Undefined Then
		
		ServiceTerms = ConditionsStructure.ServiceTerms;
		
		If UseAgreements And Terms <> ConditionsStructure.Terms Then
			Terms = ConditionsStructure.Terms;
		EndIf;
		
		If ValueIsFilled(ConditionsStructure.Supervisor_) Then
			Supervisor_ = ConditionsStructure.Supervisor_;
		EndIf;
		
		If ValueIsFilled(ConditionsStructure.SalesRepresentative) Then
			SalesRepresentative = ConditionsStructure.SalesRepresentative;
		EndIf;
	
		PlannedVisitDate = ConditionsStructure.PlannedVisitDate;
		BeginTime = ConditionsStructure.BeginTime;
		EndTime = ConditionsStructure.EndTime;
		
	EndIf;
	
	If UseAgreements Then
		If Not ValueIsFilled(Terms) Or ConditionsStructure = Undefined Then
			FillInDefaultSalesConditions();
		ElsIf OldAgreement <> Terms Then
			FillInTermsOfSalesUnderAgreement();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	ItemsDetails = Constants.ItemizeJobsForSalesRepresentatives.Get();
	
	If ValueIsFilled(FillingData) Then
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			If FillingData.Property("Partner") Then
				Partner = FillingData.Partner;
			EndIf;
			
			If FillingData.Property("ServiceTerms") Then
				ServiceTerms = FillingData.ServiceTerms;
				FillInTermsOfSalesUnderTermsOfService();
			EndIf;
			
			If FillingData.Property("Terms") Then
				Terms = FillingData.Terms;
			EndIf;
			
			If FillingData.Property("Counterparty") Then
				Counterparty = FillingData.Counterparty;
			EndIf;
			
			If FillingData.Property("SalesRepresentative") Then
				SalesRepresentative = FillingData.SalesRepresentative;
			EndIf;
			
			If FillingData.Property("PlannedVisitDate") Then
				PlannedVisitDate = FillingData.PlannedVisitDate;
			EndIf;
			
			If FillingData.Property("BusinessOperation") Then
				BusinessOperation = FillingData.BusinessOperation;
			EndIf;
			
		ElsIf TypeOf(FillingData) = Type("DocumentRef.JobForSalesRepresentative") 
			Or TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
			
			FillInOnTheBasis(FillingData);
		
		EndIf;
		
	EndIf;
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	InitializeSalesConditions();
	InitializeDocument(FillingData);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.SalesRepresentativeTaskStatuses.NotPrepared2;
	DocumentAmount = 0;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	PlannedVisitDate = '00010101';
	ActualVisitDate = '00010101';
	
	Tasks.Clear();
	
	For Each String In Goods Do
		String.Count = 0;
		String.NumberOfPackages = 0;
		String.Sum = 0;
		String.VATAmount = 0;
		String.Comment = "";
		String.PercentRateOfManualDiscount = 0;
		String.ManualDiscount = 0;
		String.CancellationReason = Catalogs.ReasonsForSaleOrderCancellation.EmptyRef();
	EndDo;

	For Each String In PaymentScheduleSteps Do
		String.PaymentDate = '00010101000000';
		String.PaymentAmount = 0;
		String.PackageDepositValue = 0;
	EndDo;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.FieldNamesWithSuffix.Insert("Count", "CountPlan");
	CheckParameters.FieldNamesWithSuffix.Insert("NumberOfPackages", "NumberOfPackagesPlan");
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	If Status <> Enums.SalesRepresentativeTaskStatuses.Processed_ Then
		NotCheckedAttributeArray.Add("ActualVisitDate");
	EndIf;
	
	If Status = Enums.SalesRepresentativeTaskStatuses.Canceled Then
		NotCheckedAttributeArray.Add("PlannedVisitDate");
	EndIf;
		
	If Status = Enums.SalesRepresentativeTaskStatuses.NotPrepared2 
		Or Status = Enums.SalesRepresentativeTaskStatuses.Canceled Then
		
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Currency");
		NotCheckedAttributeArray.Add("SalesRepresentative");
		NotCheckedAttributeArray.Add("Supervisor_");
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("BusinessOperation");
		
	EndIf;
	
	If Not ValueIsFilled(Terms)
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	If Status <> Enums.SalesRepresentativeTaskStatuses.Processed_ 
		Or Status <> Enums.SalesRepresentativeTaskStatuses.ToProcessing Then
		SalesServer.CheckCorrectnessOfSalesDocument(ThisObject,Cancel);
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckContentCompletion(ThisObject, Cancel, "Goods");
	CheckPossibilityOfUsingDataBySalesRepresentatives(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.FieldNameQuantitySuffix = "CountPlan";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	DocumentAmount = GetSumOfOrderedRows();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not ValueIsFilled(Supervisor_) Then
		Supervisor_ = Users.CurrentUser();
	EndIf;
	
	If ValueIsFilled(Partner) Then
		If Not ValueIsFilled(ServiceTerms) Then
			FillInDefaultTermsOfService();
		EndIf;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;

	FillParameters = Documents.JobForSalesRepresentative.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
EndProcedure

Procedure FillInOnTheBasis(DocumentBasis)
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.JobForSalesRepresentative")
		Or TypeOf(DocumentBasis) = Type("DocumentRef.SalesOrder") Then
		
		TheseGrounds = GetFoundationData(DocumentBasis);
		CompositionTable = TheseGrounds.Goods; // ValueTable
		
	Else
		Return;
	EndIf;
	
	FillInHeader_(DocumentBasis, TheseGrounds);
	Goods.Clear();
	PaymentScheduleSteps.Clear();
	
	If ItemsDetails Then
		CompositionTable.GroupBy("Products,Characteristic,Package,PriceKind,Price,VATRate","CountPlan, NumberOfPackagesPlan");
		Goods.Load(CompositionTable);
	EndIf;

EndProcedure

Procedure FillInHeader_(DocumentBasis, TheseGrounds)
	
	If Not ValueIsFilled(Partner) Then
		Partner = TheseGrounds.Partner;
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = TheseGrounds.Currency;
	EndIf;
	
	If Not ValueIsFilled(Terms) Then
		Terms = TheseGrounds.Terms;
	EndIf;

	If Not ValueIsFilled(Organization) Then
		Organization = TheseGrounds.Organization;
	EndIf;

	If Not ValueIsFilled(Counterparty) Then
		Counterparty = TheseGrounds.Counterparty;
	EndIf;

	If Not ValueIsFilled(PaymentSchedule) Then
		PaymentSchedule = TheseGrounds.PaymentSchedule;
	EndIf;

	If Not ValueIsFilled(Warehouse) Then
		Warehouse = TheseGrounds.Warehouse;
	EndIf;
	
	If Not ItemsDetails Then
		SumPlan = TheseGrounds.Sum;
	EndIf;

EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Calculates the amount of undelivered order lines
//
// Parameters:
//  OnlyDepositForContainer - Boolean- indication of payment only for containers.
//
// Returns:
//  Number - The sum of the ordered lines.
//
Function GetSumOfOrderedRows(OnlyDepositForContainer = False) Export
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT,
	|	Goods.CancellationReason AS CancellationReason
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	ISNULL(SUM(Goods.AmountIncludingVAT),0) AS AmountIncludingVAT
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.CancellationReason = VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef)
	|	AND ((Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT &OnlyDepositForContainer)
	|		OR (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT &ToReturnReusablePackage)
	|		OR (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND &OnlyDepositForContainer))
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT,CancellationReason"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("OnlyDepositForContainer", OnlyDepositForContainer);
	
	Upload0 = Query.Execute().Unload();
	SumOfOrderedRows = Upload0[0].AmountIncludingVAT;
	Return SumOfOrderedRows;
	
EndFunction

Function GetFoundationData(DocumentBasis)
	
	If TypeOf(DocumentBasis) = "DocumentRef.JobForSalesRepresentative" Then
		FieldAmount = "SumPlan";
		QuantityField = "CountPlan";
		NumberOfPackagesField = "NumberOfPackagesPlan";
	Else
		FieldAmount = "DocumentAmount";
		QuantityField = "Count";
		NumberOfPackagesField = "NumberOfPackages";
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	Basis.Partner AS Partner,
	|	Basis.Currency AS Currency,
	|	Basis.Terms AS Terms,
	|	Basis.Contract AS Contract,
	|	Basis.Organization AS Organization,
	|	Basis.Counterparty AS Counterparty,
	|	Basis.PaymentSchedule AS PaymentSchedule,
	|	Basis.Warehouse AS Warehouse,
	|	Basis." + FieldAmount + " AS Sum,
	|	Basis.Goods.(
	|   Products AS Products,
	|   Characteristic AS Characteristic,
	|   Package AS Package,
	|"+ QuantityField + " AS CountPlan,
	|"+ NumberOfPackagesField + " AS NumberOfPackagesPlan,
	|   PriceKind AS PriceKind,
	|   Price AS Price,
	|   VATRate AS VATRate,
	|) AS Goods
	|FROM Document." + DocumentBasis.Metadata().Name + " AS Basis
	|WHERE
	|	Basis.Ref = &DocumentBasis"
	;
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	StructureOfData = New Structure();
	StructureOfData.Insert("Partner");
	StructureOfData.Insert("Currency");
	StructureOfData.Insert("Terms");
	StructureOfData.Insert("Contract");
	StructureOfData.Insert("Organization");
	StructureOfData.Insert("Counterparty");
	StructureOfData.Insert("PaymentSchedule");
	StructureOfData.Insert("Warehouse");
	StructureOfData.Insert("Sum");
	
	FillPropertyValues(StructureOfData, Selection);
	
	StructureOfData.Insert("Goods", Selection.Goods.Unload());
	
	Return StructureOfData;
	
EndFunction

Procedure CheckPossibilityOfUsingDataBySalesRepresentatives(Cancel)
	
	If ValueIsFilled(Partner) Then
		
		If Not TMCommonUse.ValueOfBooleanObjectSProps(Partner, "ServedBySalesRepresentatives") Then
			MessageText = NStr("vi = 'Đối với bạn hàng đã chỉ ra chưa chỉ ra dấu hiệu phục vụ bởi đại diện thương mại';
								|ru = 'Для указанного партнера не указан признак обслуживания торговыми представителями';
								|en = 'Flag of sales representative service is not specified for the specified partner'; fa = 'Flag of sales representative service is not specified for the specified partner';
								|it = 'Per partner specificato non è indicato alcun criterio del servizio di assistenza da parte di agenti commerciali';
								|pl = 'Dla wybranego partnera nie wskazano oznaki obsługi przedstawicielami handlowymi';
								|tr = 'Belirtilen iş ortağı için herhangi bir satış temsilcisi hizmet göstergesi verilmemiştir'");
			CommonClientServer.MessageToUser(MessageText, ThisObject, "Partner");
			Cancel = True;
			Return;
		EndIf;
			
	EndIf;
	
	If GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms) Then
		
		If Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "UsedInSalesRepresentativesWork") Then
			MessageText = NStr("vi = 'Thỏa thuận đã chỉ ra không được sử dụng khi làm việc với đại diện thương mại';
								|ru = 'Указанное соглашение не используется в работе торговых представителей';
								|en = 'The specified agreement is not used by sales representatives'; fa = 'The specified agreement is not used by sales representatives';
								|it = 'Accordo specificato non viene utilizzato nel lavoro di agenti commerciali';
								|pl = 'Wskazana umowa nie jest używana podczas pracy przedstawicieli handlowych';
								|tr = 'Bu anlaşma satış temsilcileri tarafından kullanılmaz'");
			CommonClientServer.MessageToUser(MessageText, ThisObject, "Terms");
			Cancel = True;
			Return;
		EndIf;
			
	EndIf;
		
EndProcedure

#EndRegion

#EndRegion

#EndIf
