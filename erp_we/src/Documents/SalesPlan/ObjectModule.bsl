#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
Procedure FillInAccordingToTheFillingRule() Export 
	
	Parameters = New Structure("Ref, Scenario, CrossTable, ChangeResultTo, FilledAutomatically, RoundingPrecision, 
		|Department, Organization, Warehouse, Partner, Terms, Status, Periodicity, BeginOfPeriod, PeriodEnding, AllocateByWorkdays");
	
	FillPropertyValues(Parameters, ThisObject);
	
	Parameters.Insert("FillInRule", True);
	Parameters.Insert("FillingRule", FillingRule.Unload());
	Parameters.Insert("UserSettings", UserSettings.Get());
	
	PopulatedTS = Goods.Unload();
	If UpdateAdd = 0 Then
		PopulatedTS.Clear();
	EndIf;
	
	Parameters.Insert("PopulatedTS", PopulatedTS);
	
	StorageAddress = PutToTempStorage(Undefined);
	Documents.SalesPlan.FillInAccordingToTheFillingRule(Parameters, StorageAddress);
	
	PopulatedTS = GetFromTempStorage(StorageAddress);
	
	Goods.Load(PopulatedTS);
	
	FilledAutomatically = True;
	
EndProcedure

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	// Skip the processing to ensure that the shape of the object is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If CrossTable Then
		NotCheckedAttributeArray.Add("Goods");
		NotCheckedAttributeArray.Add("Goods.Products");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Goods.Count");
	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.CheckPossibilityOfRounding = False;
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	EndIf;
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",                    "Goods");
	CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Hàng hóa';
															|ru = 'Товары';
															|en = 'Goods'; fa = 'کالاها';
															|it = 'Merci';
															|pl = 'Towary';
															|tr = 'Ürünler'"));
	CheckParameters.Insert("Periodicity",            Periodicity);
	CheckParameters.Insert("StartDate",               BeginOfPeriod);
	CheckParameters.Insert("EndDate",            PeriodEnding);
	CheckParameters.Insert("NameOfPeriodDateField",       "DateOfShipment");
	CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày giao hàng';
															|ru = 'Дата отгрузки';
															|en = 'Shipment date'; fa = 'تاریخ ارسال';
															|it = 'Data di spedizione';
															|pl = 'Data wysyłki';
															|tr = 'Sevkiyat tarihi'"));
	
	If Not CrossTable Then
		PlanningClientServer.CheckDateOfTSPeriod(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	If CrossTable Then
		NotCheckedAttributeArray.Add("Goods.Characteristic");
	Else
		If Not FillInByServiceData Then
			ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
		EndIf;
	EndIf;
	
	If FillInByServiceData Then
		If Not CrossTable Then
			NotCheckedAttributeArray.Add("Goods.Characteristic");
			NotCheckedAttributeArray.Add("Goods.Partner");
		EndIf;
	EndIf;
	
	Planning.ProcessingFillVerificationByScenarioPlanType(ThisObject, Cancel, CheckedAttributes);
	
	If Not PlanByAmount 
		Or Not FillInPaymentPlan 
		Or Not ValueIsFilled(Terms) 
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	If FillInPaymentPlan Then
		
		AmountOfPaymentStages = 0;
		For Each PaymentStage In CashFlowPlan Do
			AmountOfPaymentStages = AmountOfPaymentStages + PaymentStage.PaymentAmount;
		EndDo;
	
		If DocumentAmount > 0 And CashFlowPlan.Count() = 0 Then
		
			Common.MessageToUser(
				NStr("vi = 'Cần điền kế hoạch thanh toán.';
					|ru = 'Необходимо заполнить план оплаты.';
					|en = 'Fill in payment plan.'; fa = 'Fill in payment plan.';
					|it = 'È necessario compilare il piano di pagamento.';
					|pl = 'Musisz wypełnić plan płatności.';
					|tr = 'Ödeme planını doldurmak şart.'"),
				ThisObject,
				"CashFlowPlan",
				, 
				Cancel);
			
		ElsIf DocumentAmount <> AmountOfPaymentStages Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Số tiền giao hàng chứng từ không trùng với số tiền thanh toán. Cần cập nhật sơ đồ thanh toán.';
					|ru = 'Сумма отгрузок по документу не совпадает с суммой оплат. Необходимо обновить план оплаты.';
					|en = 'Shipment amount against the document does not match the payment amount. Update the payment plan.'; fa = 'Shipment amount against the document does not match the payment amount. Update the payment plan.';
					|it = 'La somma delle spedizioni secondo il documento non coincide con la somma dei pagamenti. È necessario aggiornare il piano di pagamento.';
					|pl = 'Liczba przesyłek w dokumencie nie odpowiada ilości płatności. Musisz zaktualizować swój plan płatności.';
					|tr = 'Belgeye göre sevkiyat tutarı ile ödeme tutarı uyuşmuyor. Ödeme planını yenilemek gerekiyor.'"),
				ThisObject,
				"CashFlowPlan",
				, 
				Cancel);
				
		EndIf; 
		
	Else
		NotCheckedAttributeArray.Add("CashFlowPlan.DateOfShipment");
	EndIf;
	CheckCompletionOfForecastExchangeRates = False;
	CurrenciesForCheckingExchangeRates = New Array;
	
	If ValueIsFilled(BudgetingScenario) Then
		SetPrivilegedMode(True);
		CheckCompletionOfForecastExchangeRates = 
			Common.ObjectAttributeValue(BudgetingScenario, "RequireExchangeRatesSpecificationForEachPeriod");
		SetPrivilegedMode(False);
	EndIf;
	
	LocalAccountingCurrency = SettingsValueCached.DefaultBaseCurrency();
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	CurrenciesForCheckingExchangeRates = New Array;
	If Currency <> LocalAccountingCurrency Then
		CurrenciesForCheckingExchangeRates.Add(Currency);
	EndIf;
	If ManagementAccountingCurrency <> LocalAccountingCurrency Then
		CurrenciesForCheckingExchangeRates.Add(ManagementAccountingCurrency);
	EndIf;
	
	If CheckCompletionOfForecastExchangeRates And CurrenciesForCheckingExchangeRates.Count() <> 0 Then
		
		SetPrivilegedMode(True);
		RateTable = Catalogs.BudgetingScenarios.ScenarioCourseTable(
			BudgetingScenario, CurrenciesForCheckingExchangeRates, BeginOfPeriod, PeriodEnding);
		SetPrivilegedMode(False);
		
		TimeIntervals = BudgetReportingDisplayServer.BudgetReportPeriods(BeginOfPeriod, PeriodEnding, Periodicity);
		CoursesNotFound = RateTable.CopyColumns("Period, Currency");
		
		For Each Period In TimeIntervals Do
			For Each ExchangeRateCurrency In CurrenciesForCheckingExchangeRates Do
				TheStructureOfTheSearch = New Structure("Currency, Period", ExchangeRateCurrency, Period);
				If Not RateTable.FindRows(TheStructureOfTheSearch).Count() Then
					NewRow = CoursesNotFound.Add();
					FillPropertyValues(NewRow, TheStructureOfTheSearch);
				EndIf;
			EndDo;
		EndDo;
		
		If CoursesNotFound.Count() <> 0 Then
			RightToViewBudgetingScenarios = AccessRight("View", Metadata.Catalogs.BudgetingScenarios);
			SetPrivilegedMode(True);
			NameOfBudgetingScenario = Common.ObjectAttributeValue(BudgetingScenario, "Description");
			SetPrivilegedMode(False);

			CoursesNotFound.GroupBy("Currency");
			ArrayOfCurrencies = CoursesNotFound.UnloadColumn("Currency");
			MessageText = 
				NStr("vi = 'Kế hoạch bán hàng được phản ánh vào ngân sách. 
				|Cần thiết lập tỷ giá hối đoái dự báo %1 trong kịch bản ngân sách ""%2"" đối với mỗi kỳ kế hoạch %3.';
				|ru = 'План продаж отражается в бюджетировании. 
				|Необходимо установить прогнозные курсы валют %1 в сценарии бюджетирования ""%2"" для каждого периода плана%3.';
				|en = 'Sales forecast is recorded in budgeting.
				|Set forecasted exchange rates for %1 in the ""%2"" budgeting scenario for each period of %3 forecast.'; fa = 'Sales forecast is recorded in budgeting.
				|Set forecasted exchange rates for %1 in the ""%2"" budgeting scenario for each period of %3 forecast.';
				|it = 'Il piano delle vendite viene riflesso nella definizione del budget. 
				|È necessario inserire i corsi delle valute previste %1 nello scenario della definizione del budget ""%2"" per ogni periodo del piano%3.';
				|pl = 'Plan sprzedaży znajduje odzwierciedlenie w budżetowaniu. 
				|Konieczne jest ustawienie prognozowanych kursów walut %1 w scenariuszu budżetowym ""%2"" dla każdego okresu planu%3.';
				|tr = 'Satış planı bütçelemeye yansıtılıyor. 
				| Döviz kuru tahminlerini %1 bütçeleme senaryosunda ""%2"" her plan dönemi için kurmak şart%3.'");
			MessageText = 
				StringFunctionsClientServer.SubstituteParametersToString(
					MessageText, 
					StrConcat(ArrayOfCurrencies, ", "), 
					NameOfBudgetingScenario, ?(RightToViewBudgetingScenarios, "", NStr("vi = ', liên hệ với quản trị viên của bạn';
																						|ru = ', обратитесь к администратору';
																						|en = ', contact administrator'; fa = ', contact administrator';
																						|it = ', contattate l''amministratore';
																						|pl = ', skontaktuj się z administratorem';
																						|tr = ', yöneticiye başvurun'")));
			CommonClientServer.MessageToUser(MessageText, , , "Object.Scenario", Cancel);
		EndIf;
		
	EndIf;
	If Not CrossTable
		And ValueIsFilled(PlanProfile) Then
		
		DetailsTypeOfPlan = Common.ObjectAttributesValues(PlanProfile,"FillInAssignmentInTabularForm, FillInTermsOfSales, FillInWarehouse, FillInPartner");
		
		Query = New Query();
		Query.Text = 
		"SELECT
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Warehouse,
		|	GoodsTable.Partner,
		|	GoodsTable.Terms,
		|	GoodsTable.Purpose,
		|	GoodsTable.DateOfShipment,
		|	GoodsTable.Count
		|INTO Goods
		|FROM
		|	&GoodsTable AS GoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Warehouse,
		|	Goods.Partner,
		|	Goods.Terms,
		|	Goods.Purpose,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Products <> VALUE(Catalog.Products.EmptyRef)
		|	AND (NOT &FillInWarehouse OR Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef))
		|	AND (NOT &FillInPartner OR Goods.Partner <> VALUE(Catalog.Partners.EmptyRef))
		|	AND (NOT &FillInTermsOfSales OR Goods.Terms <> VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef))
		|
		|GROUP BY
		|	Goods.Products,
		|	Goods.Warehouse,
		|	Goods.Partner,
		|	Goods.Terms,
		|	Goods.Purpose,
		|	Goods.DateOfShipment,
		|	Goods.Characteristic
		|
		|HAVING
		|	SUM(Goods.Count) = 0";
		Query.SetParameter("GoodsTable", Goods.Unload());
		Query.SetParameter("FillInTermsOfSales", DetailsTypeOfPlan.FillInTermsOfSales);
		Query.SetParameter("FillInWarehouse", DetailsTypeOfPlan.FillInWarehouse);
		Query.SetParameter("FillInPartner", DetailsTypeOfPlan.FillInPartner);
		DetailsTypeOfPlan = Common.ObjectAttributesValues(PlanProfile,"FillInAssignmentInTabularForm, FillInTermsOfSales, FillInWarehouse, FillInPartner, FillInWarehouseInTabularForm, FillInAgreementInTabularForm, FillInPartnerInTabularForm");
		
		ErrorsTable = Query.Execute().Unload();
		
		DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
		TheStructureOfTheSearch = New Structure("Products,Characteristic,Purpose,Warehouse,Partner,Terms");
		
		For Each ErrorString In ErrorsTable Do
			
			MessageText = NStr("vi = 'Đối với các dòng kế hoạch với mặt hàng %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% không dự tính số lượng trong bất kỳ giai đoạn lập kế hoạch nào.';
								|ru = 'Для строк плана с номенклатурой %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% не запланировано количество ни в одном периоде планирования.';
								|en = 'Quantity is not planned in any planning period for lines of plan with the %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% items.'; fa = 'Quantity is not planned in any planning period for lines of plan with the %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% items.';
								|it = 'Per le righe del piano con elenco articoli %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% la quantità non è programmata in alcun periodo di pianificazione.';
								|pl = 'W przypadku wiersza planu z pozycją %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% ilość nie jest planowana w żadnym okresie planowania.';
								|tr = 'Ürünler ile satır planı için %Products%%Characteristic%%Purpose%%Warehouse%%Partner%%Terms% hiçbir planlama döneminde miktar programlanmadı.'");
			MessageText = StrReplace(MessageText, "%Products%", ErrorString.Products);
			MessageText = StrReplace(MessageText, "%Characteristic%", ?(ValueIsFilled(ErrorString.Characteristic), NStr("vi = ', đặc tính';
																														|ru = ', характеристикой';
																														|en = ', variants'; fa = ', variants';
																														|it = ', caratteristica';
																														|pl = ', charakterystyką';
																														|tr = ', özellik'") + " " + ErrorString.Characteristic, ""));
			MessageText = StrReplace(MessageText, "%Purpose%", ?(ValueIsFilled(ErrorString.Purpose)
				And DetailsTypeOfPlan.FillInAssignmentInTabularForm,
				NStr("vi = ', chỉ định';
					|ru = ', назначением';
					|en = ', assignment'; fa = ', assignment';
					|it = ', destinazione';
					|pl = ', przeznaczeniem';
					|tr = ', amaç'") + " " + ErrorString.Purpose, ""));
			MessageText = StrReplace(MessageText, "%Warehouse%", ?(ValueIsFilled(ErrorString.Warehouse)
				And DetailsTypeOfPlan.FillInWarehouseInTabularForm , NStr("vi = ', kho';
																			|ru = ', складом';
																			|en = ', warehouse'; fa = ', warehouse';
																			|it = ', magazzino';
																			|pl = ', magazynem';
																			|tr = ', ambar'") + " " + ErrorString.Warehouse, ""));
			MessageText = StrReplace(MessageText, "%Partner%", ?(ValueIsFilled(ErrorString.Partner)
				And DetailsTypeOfPlan.FillInPartnerInTabularForm, NStr("vi = ', đối tác';
																		|ru = ', партнером';
																		|en = ', partner'; fa = ', partner';
																		|it = ', partner';
																		|pl = ', partnerem';
																		|tr = ', iş ortağı'") + " " + ErrorString.Partner, ""));
			MessageText = StrReplace(MessageText, "%Terms%", ?(ValueIsFilled(ErrorString.Terms)
				And DetailsTypeOfPlan.FillInAgreementInTabularForm, NStr("vi = ', theo hợp đồng';
																		|ru = ', соглашением';
																		|en = ', agreement'; fa = ', agreement';
																		|it = ', accordo';
																		|pl = ', umową';
																		|tr = ', anlaşmalara'") + " " + ErrorString.Terms, ""));
			
			FillPropertyValues(TheStructureOfTheSearch, ErrorString);
			SearchString = Goods.FindRows(TheStructureOfTheSearch)[0];
			
			Field = CommonClientServer.PathToTabularSection("Goods", SearchString.LineNumber, "NumberOfPackages");
			
			CommonClientServer.MessageToUser(MessageText,DataKey, Field,"Object",Cancel);
			
		EndDo;
		
		GroupFields = "Products, Characteristic, Purpose, Package, Warehouse, Partner, Terms, DateOfShipment";
		Planning.HandlingStringDuplicationChecking(Goods, "Goods", GroupFields, Cancel);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode <> DocumentWriteMode.Write 
		And Not AdditionalProperties.Property("SkipPeriodClosingCheck") Then
		
		DataToCheck = PeriodClosingDates.DataToCheckTemplate();
		NewRow = DataToCheck.Add();
		NewRow.Date   = BeginOfPeriod;
		NewRow.Section = "Planning";
		NewRow.Object = Scenario;
		
		If ValueIsFilled(BudgetingScenario) Then
			NewRow = DataToCheck.Add();
			NewRow.Date   = BeginOfPeriod;
			NewRow.Section = "Budgeting";
			NewRow.Object = BudgetingScenario;
		EndIf;
		
		DataDetails = New Structure;
		DataDetails.Insert("NewVersion", True);
		DataDetails.Insert("Data",      Ref);
		
		ErrorDescription = "";
		If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, DataDetails, ErrorDescription) Then
			CommonClientServer.MessageToUser(
				ErrorDescription,
				ThisObject,
				, // Field
				, // DataPath
				Cancel);
		EndIf;
			
	EndIf;
	Planning.CheckIfBudgetIssueExists(Cancel, Ref, ThisObject);
	// Fill in the shipment dates
	If Not CrossTable Then
		For Each String In Goods Do
			If Not ValueIsFilled(String.DateOfShipment) Then
				String.DateOfShipment = BeginOfPeriod;
			EndIf;
		EndDo;
	EndIf;
	
	If Substitutional Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PlanSubstitution");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("PlanProfile", PlanProfile);
		Block.Lock();
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	Planning.CheckApprovedStatus(ThisObject, Cancel, WriteMode, Enums.TypesOfPlans.SalesPlan);
	
	DocumentAmount = 0;
	
	For Each TSRow In Goods Do
		If PlanByAmount Then
			
			If Not TSRow.Canceled Then
			
				DocumentAmount = DocumentAmount + TSRow.Sum + ?(PriceIncludesVAT, 0, TSRow.VATAmount);
			
			EndIf; 
			
		Else
			
			TSRow.Price = 0;
			TSRow.Sum = 0;
			
		EndIf; 
		
		If ValueIsFilled(Partner) Then
			TSRow.Partner = Partner;
		EndIf; 
		
		If ValueIsFilled(Terms) Then
			TSRow.Terms = Terms;
		EndIf; 
		
		If ValueIsFilled(Warehouse) Then
			TSRow.Warehouse = Warehouse;
		EndIf; 
		
	EndDo;
	
	If Not PlanByAmount Then
		FillInPaymentPlan = False;
	EndIf;
	If Not FillInPaymentPlan Then
		
		CashFlowPlan.Clear();
		
	EndIf; 
	
	If Substitutional 
		And Not IsNew()
		And Not Cancel Then
		SetPrivilegedMode(True);
		UpdatePlanReplacement(WriteMode);
		SetPrivilegedMode(False);
	EndIf;
	
	If Not Substitutional
		And Not IsNew()
		And Not Cancel
		And Planning.ThereIsSubstitutionPlan(Ref) Then
		RecordSet = InformationRegisters.PlanSubstitution.CreateRecordSet();
		RecordSet.Filter.SubstitutedPlan.Set(Ref);
		
		RecordSet.Write();
	EndIf;
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.AuthorizedUser();
	EndIf;
	
EndProcedure

Procedure UpdatePlanReplacement(WriteMode, IBUpdate = False) Export
	
	If WriteMode = DocumentWriteMode.UndoPosting
		Or (WriteMode = DocumentWriteMode.Write And Not Posted) Then
		
		For Each String In Goods Do
			String.Substituted = False;
			String.SubstitutedToOrder = False;
		EndDo;
		
		RecordSet = InformationRegisters.PlanSubstitution.CreateRecordSet();
		RecordSet.Filter.SubstitutedPlan.Set(Ref);
		
		RecordSet.Write();
		Return;
	EndIf;
		
	TimeIntervals = New ValueTable();
	TimeIntervals.Columns.Add("Period", New TypeDescription("Date"));
	
	AddingStartDate = BeginOfPeriod;
	While AddingStartDate < EndOfDay(PeriodEnding) Do
		NewRow = TimeIntervals.Add();
		NewRow.Period = AddingStartDate;
		
		EndDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Periodicity);
		AddingStartDate = EndDateOfPeriod+1;
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TimeIntervals.Period
	|INTO TimeIntervals
	|FROM
	|	&TimeIntervals AS TimeIntervals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesPlanSubstitute.Ref,
	|	SalesPlanSubstitute.PlanProfile,
	|	CASE
	|		WHEN &BeginOfPeriod > SalesPlanSubstitute.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE SalesPlanSubstitute.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < SalesPlanSubstitute.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE SalesPlanSubstitute.PeriodEnding
	|	END AS PeriodEnding,
	|	SalesPlanSubstitute.Status = VALUE(Enum.PlanStatuses.Upholded)
	|		AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS SubstitutedToOrder,
	|	SalesPlanSubstitute.Status.Order >= &StatusIndex
	|		OR SalesPlanSubstitute.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|			AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS Substituted,
	|	SalesPlanSubstitute.Status AS SubstitutionStatus
	|INTO ReplacementPlans
	|FROM
	|	Document.SalesPlan AS SalesPlanSubstitute
	|WHERE
	|	SalesPlanSubstitute.PeriodEnding >= &BeginOfPeriod
	|	AND SalesPlanSubstitute.BeginOfPeriod <= &PeriodEnding
	|	AND SalesPlanSubstitute.Ref <> &Ref
	|	AND SalesPlanSubstitute.Posted
	|	AND SalesPlanSubstitute.PlanProfile = &PlanProfile
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (SalesPlanSubstitute.Status.Order >= &StatusIndex
	|			OR SalesPlanSubstitute.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND SalesPlanSubstitute.Date > &Date
	|	AND SalesPlanSubstitute.Department = &Department
	|	AND SalesPlanSubstitute.Organization = &Organization
	|	AND SalesPlanSubstitute.Partner = &Partner
	|	AND SalesPlanSubstitute.Terms = &Terms
	|	AND SalesPlanSubstitute.Warehouse = &Warehouse
	|	AND SalesPlanSubstitute.Manager = &Manager
	|	AND SalesPlanSubstitute.StoreFormat = &StoreFormat
	|	AND SalesPlanSubstitute.Purpose = &Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
	|	TimeIntervals.Period AS SubstitutedPeriod,
	|	FALSE AS ForSubstitution,
	|	FALSE AS ForSubstitutionCancellation,
	|	ReplacementPlans.Ref AS SubstitutePlan,
	|	&Ref AS SubstitutedPlan,
	|	ReplacementPlans.SubstitutedToOrder AS SubstitutedToOrder,
	|	ReplacementPlans.Substituted AS Substituted,
	|	ReplacementPlans.SubstitutionStatus AS SubstitutionStatus
	|INTO PlanSubstitution
	|FROM
	|	ReplacementPlans AS ReplacementPlans
	|		LEFT JOIN TimeIntervals AS TimeIntervals
	|		ON ReplacementPlans.BeginOfPeriod <= TimeIntervals.Period
	|			AND ReplacementPlans.PeriodEnding >= TimeIntervals.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanProducts.DateOfShipment,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(SalesPlanProducts.DateOfShipment, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(SalesPlanProducts.DateOfShipment, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(SalesPlanProducts.DateOfShipment, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(SalesPlanProducts.DateOfShipment, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(SalesPlanProducts.DateOfShipment, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(SalesPlanProducts.DateOfShipment, YEAR)
	|		ELSE SalesPlanProducts.DateOfShipment
	|	END AS Period
	|INTO SalesPlanProducts
	|FROM
	|	&SalesPlanProducts AS SalesPlanProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanPaymentPlan.DateOfShipment,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(SalesPlanPaymentPlan.DateOfShipment, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(SalesPlanPaymentPlan.DateOfShipment, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(SalesPlanPaymentPlan.DateOfShipment, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(SalesPlanPaymentPlan.DateOfShipment, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(SalesPlanPaymentPlan.DateOfShipment, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(SalesPlanPaymentPlan.DateOfShipment, YEAR)
	|		ELSE SalesPlanPaymentPlan.DateOfShipment
	|	END AS Period
	|INTO SalesPlanPaymentPlan
	|FROM
	|	&SalesPlanPaymentPlan AS SalesPlanPaymentPlan
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanProducts.DateOfShipment,
	|	MAX(PlanSubstitution.SubstitutedToOrder) AS SubstitutedToOrder,
	|	MAX(PlanSubstitution.Substituted) AS Substituted
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|		INNER JOIN SalesPlanProducts AS SalesPlanProducts
	|		ON PlanSubstitution.SubstitutedPeriod = SalesPlanProducts.Period
	|
	|GROUP BY
	|	SalesPlanProducts.DateOfShipment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanPaymentPlan.DateOfShipment
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|		INNER JOIN SalesPlanPaymentPlan AS SalesPlanPaymentPlan
	|		ON PlanSubstitution.SubstitutedPeriod = SalesPlanPaymentPlan.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.PlanProfile,
	|	PlanSubstitution.SubstitutedPeriod,
	|	PlanSubstitution.ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation,
	|	PlanSubstitution.SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan,
	|	PlanSubstitution.SubstitutionStatus AS SubstitutionStatus
	|FROM
	|	PlanSubstitution AS PlanSubstitution";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Status));
	Query.SetParameter("Status", Status);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Department", Department);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("StoreFormat", StoreFormat);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("SalesPlanProducts", Goods.Unload());
	Query.SetParameter("SalesPlanPaymentPlan", CashFlowPlan.Unload());
	
	RequestPackage = Query.ExecuteBatch();
	Selection = RequestPackage[5].Select();
	SamplePaymentPlan = RequestPackage[6].Select();
	PlanReplacementTable = RequestPackage[7].Unload();
	
	For Each String In Goods Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	While Selection.Next() Do
		
		Filter = New Structure("DateOfShipment", Selection.DateOfShipment);
		ReplacementLines = Goods.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = Selection.Substituted;
			String.SubstitutedToOrder = Selection.SubstitutedToOrder;
		EndDo;
		
	EndDo;
	
	For Each String In CashFlowPlan Do
		String.Substituted = False;
	EndDo;
	
	While SamplePaymentPlan.Next() Do
		
		Filter = New Structure("DateOfShipment", SamplePaymentPlan.DateOfShipment);
		ReplacementLines = CashFlowPlan.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = True;
		EndDo;
		
	EndDo;
	
	RecordSet = InformationRegisters.PlanSubstitution.CreateRecordSet();
	RecordSet.Filter.SubstitutedPlan.Set(Ref);
		
	RecordSet.Load(PlanReplacementTable);
	
	If IBUpdate Then
		RecordSet.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", Undefined);
		RecordSet.DataExchange.Load = True;
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If Not Cancel
		And (Substitutional Or Planning.ThereIsSubstitutionPlan(Ref)) Then
		SetPrivilegedMode(True);
		UpdateSubstitutedPlans();
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure UpdateSubstitutedPlans()
	
	TimeIntervals = New ValueTable();
	TimeIntervals.Columns.Add("Period", New TypeDescription("Date"));
	
	AddingStartDate = BeginOfPeriod;
	While AddingStartDate < EndOfDay(PeriodEnding) Do
		NewRow = TimeIntervals.Add();
		NewRow.Period = AddingStartDate;
		
		EndDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Periodicity);
		AddingStartDate = EndDateOfPeriod+1;
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TimeIntervals.Period
	|INTO TimeIntervals
	|FROM
	|	&TimeIntervals AS TimeIntervals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesPlanSubstituted.Ref,
	|	SalesPlanSubstituted.PlanProfile,
	|	CASE
	|		WHEN SalesPlan.BeginOfPeriod > SalesPlanSubstituted.BeginOfPeriod
	|			THEN SalesPlan.BeginOfPeriod
	|		ELSE SalesPlanSubstituted.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN SalesPlan.PeriodEnding < SalesPlanSubstituted.PeriodEnding
	|			THEN SalesPlan.PeriodEnding
	|		ELSE SalesPlanSubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	SalesPlan.Status AS SubstitutionStatus
	|INTO SubstitutedPlans
	|FROM
	|	Document.SalesPlan AS SalesPlan
	|		INNER JOIN Document.SalesPlan AS SalesPlanSubstituted
	|		ON SalesPlan.PlanProfile = SalesPlanSubstituted.PlanProfile
	|			AND (SalesPlan.Status.Order >= SalesPlanSubstituted.Status.Order
	|				OR SalesPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|					AND SalesPlanSubstituted.Status = VALUE(Enum.PlanStatuses.Upholded))
	|			AND SalesPlanSubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|			AND SalesPlan.Date > SalesPlanSubstituted.Date
	|			AND SalesPlan.Department = SalesPlanSubstituted.Department
	|			AND SalesPlan.Organization = SalesPlanSubstituted.Organization
	|			AND SalesPlan.Partner = SalesPlanSubstituted.Partner
	|			AND SalesPlan.Terms = SalesPlanSubstituted.Terms
	|			AND SalesPlan.Warehouse = SalesPlanSubstituted.Warehouse
	|			AND SalesPlan.Manager = SalesPlanSubstituted.Manager
	|			AND SalesPlan.StoreFormat = SalesPlanSubstituted.StoreFormat
	|			AND SalesPlan.Purpose = SalesPlanSubstituted.Purpose
	|			AND SalesPlanSubstituted.Posted
	|			AND SalesPlanSubstituted.Substitutional
	|WHERE
	|	SalesPlanSubstituted.PeriodEnding >= SalesPlan.BeginOfPeriod
	|	AND SalesPlanSubstituted.BeginOfPeriod <= SalesPlan.PeriodEnding
	|	AND SalesPlan.Ref = &Ref
	|	AND SalesPlan.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
	|	TimeIntervals.Period AS SubstitutedPeriod,
	|	ReplacementPlans.Ref AS SubstitutedPlan,
	|	&Ref AS SubstitutePlan,
	|	ReplacementPlans.SubstitutionStatus AS SubstitutionStatus
	|INTO SubstitutedPlansByPeriod
	|FROM
	|	SubstitutedPlans AS ReplacementPlans
	|		LEFT JOIN TimeIntervals AS TimeIntervals
	|		ON ReplacementPlans.BeginOfPeriod <= TimeIntervals.Period
	|			AND ReplacementPlans.PeriodEnding >= TimeIntervals.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.SubstitutePlan AS SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan,
	|	PlanSubstitution.SubstitutedPeriod AS SubstitutedPeriod,
	|	PlanSubstitution.PlanProfile AS PlanProfile,
	|	CASE
	|		WHEN SubstitutedPlansByPeriod.SubstitutionStatus IS NULL
	|			THEN PlanSubstitution.SubstitutionStatus
	|		ELSE SubstitutedPlansByPeriod.SubstitutionStatus
	|	END AS SubstitutionStatus,
	|	PlanSubstitution.ForSubstitution AS ForSubstitution,
	|	CASE
	|		WHEN SubstitutedPlansByPeriod.SubstitutedPeriod IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ForSubstitutionCancellation
	|INTO SubstitutionOfPlansSumOfRegisteredRecords
	|FROM
	|	InformationRegister.PlanSubstitution AS PlanSubstitution
	|		LEFT JOIN SubstitutedPlansByPeriod AS SubstitutedPlansByPeriod
	|		ON PlanSubstitution.PlanProfile = SubstitutedPlansByPeriod.PlanProfile
	|			AND PlanSubstitution.SubstitutedPeriod = SubstitutedPlansByPeriod.SubstitutedPeriod
	|			AND PlanSubstitution.SubstitutePlan = SubstitutedPlansByPeriod.SubstitutePlan
	|			AND PlanSubstitution.SubstitutedPlan = SubstitutedPlansByPeriod.SubstitutedPlan
	|			AND PlanSubstitution.SubstitutionStatus = SubstitutedPlansByPeriod.SubstitutionStatus
	|WHERE
	|	&Ref = PlanSubstitution.SubstitutePlan
	|
	|UNION ALL
	|
	|SELECT
	|	SubstitutedPlansByPeriod.SubstitutePlan,
	|	SubstitutedPlansByPeriod.SubstitutedPlan,
	|	SubstitutedPlansByPeriod.SubstitutedPeriod,
	|	SubstitutedPlansByPeriod.PlanProfile,
	|	SubstitutedPlansByPeriod.SubstitutionStatus,
	|	TRUE,
	|	FALSE
	|FROM
	|	SubstitutedPlansByPeriod AS SubstitutedPlansByPeriod
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
	|		ON SubstitutedPlansByPeriod.PlanProfile = PlanSubstitution.PlanProfile
	|			AND SubstitutedPlansByPeriod.SubstitutedPeriod = PlanSubstitution.SubstitutedPeriod
	|			AND SubstitutedPlansByPeriod.SubstitutedPlan = PlanSubstitution.SubstitutedPlan
	|			AND SubstitutedPlansByPeriod.SubstitutePlan = PlanSubstitution.SubstitutePlan
	|			AND SubstitutedPlansByPeriod.SubstitutionStatus = PlanSubstitution.SubstitutionStatus
	|WHERE
	|	PlanSubstitution.SubstitutedPeriod IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutePlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod,
	|	SubstitutionOfPlansSumOfRegisteredRecords.PlanProfile,
	|	MIN(ISNULL(PlanSubstitution1.ForSubstitution, SubstitutionOfPlansSumOfRegisteredRecords.ForSubstitution)) AS ForSubstitution,
	|	MIN(SubstitutionOfPlansSumOfRegisteredRecords.ForSubstitutionCancellation) AS ForSubstitutionCancellation,
	|	MIN(ISNULL(PlanSubstitution.ForSubstitutionCancellation, TRUE)) AS PerformUndoSubstitution,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus
	|INTO PlanSubstitution
	|FROM
	|	SubstitutionOfPlansSumOfRegisteredRecords AS SubstitutionOfPlansSumOfRegisteredRecords
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
	|		ON SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan = PlanSubstitution.SubstitutedPlan
	|			AND SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod = PlanSubstitution.SubstitutedPeriod
	|			AND (NOT PlanSubstitution.ForSubstitutionCancellation)
	|			AND (&Ref <> PlanSubstitution.SubstitutePlan)
	|			AND (SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus = PlanSubstitution.SubstitutionStatus)
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution1
	|		ON SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan = PlanSubstitution1.SubstitutedPlan
	|			AND SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod = PlanSubstitution1.SubstitutedPeriod
	|			AND (NOT PlanSubstitution1.ForSubstitution)
	|			AND (SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus = PlanSubstitution1.SubstitutionStatus)
	|			AND (&Ref <> PlanSubstitution1.SubstitutePlan)
	|
	|GROUP BY
	|	SubstitutionOfPlansSumOfRegisteredRecords.PlanProfile,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutePlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan,
	|	PlanSubstitution.SubstitutedPeriod,
	|	PlanSubstitution.PlanProfile,
	|	PlanSubstitution.ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation,
	|	PlanSubstitution.PerformUndoSubstitution,
	|	PlanSubstitution.SubstitutionStatus
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|TOTALS BY
	|	SubstitutedPlan";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	
	RequestPackage = Query.ExecuteBatch(); 
	SampleSubstitutedPlan = RequestPackage[5].Select(QueryResultIteration.ByGroups);
	UpdatePlanReplacement = False;
	
	While SampleSubstitutedPlan.Next() Do
		
		QueueRecordset = InformationRegisters.PlanSubstitution.CreateRecordSet();
		QueueRecordset.Filter.SubstitutePlan.Set(Ref);
		QueueRecordset.Filter.SubstitutedPlan.Set(SampleSubstitutedPlan.SubstitutedPlan); 
		
		Selection = SampleSubstitutedPlan.Select(QueryResultIteration.ByGroups);
		While Selection.Next() Do
			
			If (Selection.ForSubstitution And Selection.ForSubstitutionCancellation)Then
				UpdatePlanReplacement = True;
			ElsIf Selection.ForSubstitutionCancellation And Not Selection.PerformUndoSubstitution Then
				Continue;
			ElsIf Selection.ForSubstitution Or Selection.ForSubstitutionCancellation Then
				UpdatePlanReplacement = True;
				QueueRecording = QueueRecordset.Add();
				FillPropertyValues(QueueRecording, Selection);
			ElsIf Posted Then
				QueueRecording = QueueRecordset.Add();
				FillPropertyValues(QueueRecording, Selection);
			EndIf;
			
		EndDo;
		
		QueueRecordset.Write();
		
	EndDo;
	
	If UpdatePlanReplacement Then
		Planning.StartingBackgroundExecutionOfPlan();
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Status = Metadata().Attributes.Status.FillValue;
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	FillInDetailsOfPlanForScenarioTypeOfPlan();
	For Each LineProducts_ In Goods Do

		LineProducts_.Canceled = False;

	EndDo;

	Author = Users.CurrentUser();

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If Not Cancel
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Not Cancel
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		Return;
	EndIf;
	
	Author = Users.CurrentUser();
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillingData.Property("Scenario", ThisObject.Scenario);
		FillingData.Property("PlanProfile", ThisObject.PlanProfile);
		FillingData.Property("BeginOfPeriod", ThisObject.BeginOfPeriod);
		FillingData.Property("PeriodEnding", ThisObject.PeriodEnding);
	Else
		FillInDefaultData();
	EndIf;
	
	FillInDetailsOfPlanForScenarioTypeOfPlan();
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
		
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
EndProcedure

// The procedure fills the division, scenario, plan view, and cross-table attribute in the document with the default value.
//
Procedure FillInDefaultData()
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	CASE
	|		WHEN BusinessStructure.DeletionMark
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE DocumentData.Department
	|	END AS Department,
	|	CASE
	|		WHEN Companies.DeletionMark
	|			THEN VALUE(Catalog.Companies.EmptyRef)
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	CASE
	|		WHEN SalesOperationsPlanningScenarios.DeletionMark
	|			THEN VALUE(Catalog.SalesOperationsPlanningScenarios.EmptyRef)
	|		ELSE DocumentData.Scenario
	|	END AS Scenario,
	|	CASE
	|		WHEN PlanProfiles.DeletionMark
	|			THEN VALUE(Catalog.PlanProfiles.EmptyRef)
	|		ELSE DocumentData.PlanProfile
	|	END AS PlanProfile,
	|	DocumentData.FillInUsingFormula AS FillInUsingFormula,
	|	DocumentData.CrossTable AS CrossTable,
	|	ISNULL(PlanProfiles.FillInPaymentPlan, FALSE) AS FillInPaymentPlan
	|FROM
	|	Document.SalesPlan AS DocumentData
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON DocumentData.PlanProfile = PlanProfiles.Ref
	|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|		ON DocumentData.Scenario = SalesOperationsPlanningScenarios.Ref
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON DocumentData.Department = BusinessStructure.Ref
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON DocumentData.Organization = Companies.Ref
	|WHERE
	|	DocumentData.EmployeeResponsible = &EmployeeResponsible
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	DocumentData.Date DESC");
	
	Query.SetParameter("EmployeeResponsible", EmployeeResponsible);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		FillPropertyValues(ThisObject, Selection);
		
	EndIf;
	
	Scenario = SettingsValueCached.GetDefaultScript(Enums.TypesOfPlans.SalesPlan, Scenario);
	
EndProcedure

Procedure FillInDetailsOfPlanForScenarioTypeOfPlan()
	
	ScriptDetails = "Periodicity, Currency, CreateSalesPlanByAmount";
	ScriptDetails = ScriptDetails + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, ScriptDetails);
	If Not ValueIsFilled(PlanProfile) Then
		PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.SalesPlan, Scenario);
	EndIf;
	FillPropertyValues(ThisObject, ScriptParameters_);
	PlanByAmount = ScriptParameters_.CreateSalesPlanByAmount;
	
	If ValueIsFilled(PlanProfile) Then
		Attributes = "FillInPaymentPlan,FillInUsingFormula,FillInByServiceData,Substitutional";
		
		PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
		StructureOfSettingsPlanView = Planning.GetDefaultSettings(Enums.TypesOfPlans.SalesPlan, PlanProfile);
		If StructureOfSettingsPlanView.Property("Formula") Then
			PlanViewParameters.Insert("SettingsStructure", StructureOfSettingsPlanView);
		EndIf;
		For Each Item In StructureOfSettingsPlanView Do
			PlanViewParameters.Insert(Item.Key, Item.Value);
		EndDo;
		
		FillPropertyValues(ThisObject, PlanViewParameters);
		ThisObject.SettingsStructure  = New ValueStorage(StructureOfSettingsPlanView);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
