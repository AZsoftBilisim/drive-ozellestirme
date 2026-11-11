#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("ExpensesOccur");
	Result.Add("CostAllocationOptionManag");
	Result.Add("CostAllocationOptionLocal");
	Result.Add("CostAllocationOptionTax");
	Result.Add("ValueType; ValueType");
	Result.Add("ExpenseTypeCategory");
	Result.Add("SeparateVATAccountingOption");
	Result.Add("RecognizedInAITExpenses");
	
	ExpenseItemsLocalization.AddBlockedItemDetails(Result);
	
	Return Result;
	
EndFunction

// This function defines the details of the selected expense item.
//
// Parameters:
//  ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - Link to the item of expenditure.
//
// Returns:
//	Structure - Attributes of the expenditure item.
//
Function GetDetailsOfExpenseItem(Val ExpenseItem) Export
	
	Query = New Query("
	|SELECT
	|	ExpenseItems.MethodOfDistributionByAreasOfActivity AS LineOfBusinessAllocationMethod,
	|	ExpenseItems.ValueType AS ValueType,
	|	ExpenseItems.ExpenseItem AS ExpenseItem
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	ExpenseItems.Ref = &ExpenseItem
	|");
	
	Query.SetParameter("ExpenseItem", ExpenseItem);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		LineOfBusinessAllocationMethod = Selection.LineOfBusinessAllocationMethod;
		AllocationMethodIsRequired = Not Selection.ValueType.ContainsType(Type("CatalogRef.LinesOfBusiness"));
		ValueType = Selection.ValueType;
		ItemOfExpenditureDistribution = Selection.ExpenseItem;
	Else
		LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
		AllocationMethodIsRequired = False;
		ValueType = Undefined;
		ItemOfExpenditureDistribution = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure("LineOfBusinessAllocationMethod, AllocationMethodIsRequired, ValueType",
		LineOfBusinessAllocationMethod,
		AllocationMethodIsRequired,
		ValueType);
	AttributesStructure1.Insert("ExpenseItem", ItemOfExpenditureDistribution);
	
	Return AttributesStructure1;

EndFunction

// The function defines a distribution rule for the cost of goods for an expense item.
//
// Parameters:
//  ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - Link to the item of expenditure.
//
// Returns:
//	EnumRef.RulesOfAllocationForInventoryCost - the rule for the allocation of items of expenditure.
//
Function GetDistributionRule(ExpenseItem) Export
	
	Query = New Query("
	|SELECT
	|	ExpenseItems.CostAllocationRuleToProcuctCost AS AllocatedAccordingToRule
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	ExpenseItems.Ref = &ExpenseItem
	|	AND (ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|");
	
	Query.SetParameter("ExpenseItem", ExpenseItem);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		AllocatedAccordingToRule = Selection.AllocatedAccordingToRule;
	Else
		AllocatedAccordingToRule = Undefined;
	EndIf;
	
	Return AllocatedAccordingToRule;

EndFunction

// The procedure fills in the list of business operations that use
// the cost item selection restriction.
//
// Parameters:
//	TransactionList - ValueList - List of business operations and their representations.
//	CostAllocationOptionManag - EnumRef.CostAllocationOptions - distribution option in administrative accounting
//	CostAllocationOptionLocal - EnumRef.CostAllocationOptions - distribution option in regl. accounting
//
Procedure FillInListOfBusinessOperations(TransactionList, CostAllocationOptionManag = Undefined, CostAllocationOptionLocal = Undefined) Export
	
	TransactionList.Clear();
	TransactionList.Add(Enums.BusinessTransactions.ExpenseReport, NStr("vi = 'Chi phí khác của người nhận tạm ứng';
																		|ru = 'Прочие расходы подотчетного лица';
																		|en = 'Other expenses of advance holders'; fa = 'سایر هزینه‌های تنخواه‌گردان‌ها';
																		|it = 'Altre spese dell''ente subordinato';
																		|pl = 'Inne wydatki osoby odpowiedzialnej';
																		|tr = 'Sorumlu kişinin diğer giderleri'"));
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromSupplier, NStr("vi = 'Dịch vụ của bên thứ ba';
																				|ru = 'Услуги сторонних организаций';
																				|en = 'Third party services'; fa = 'Third party services';
																				|it = 'Servizi di terzi';
																				|pl = 'Usługi firm zewnętrznych';
																				|tr = 'Üçüncü taraf iş yerlerinin hizmetleri'"));
	TransactionList.Add(Enums.BusinessTransactions.OtherExpenses, NStr("vi = 'Chi tiền cho chi phí khác';
																		|ru = 'Выдача денежных средств на прочие расходы';
																		|en = 'Cash issue for other expenses'; fa = 'Cash issue for other expenses';
																		|it = 'Rilascio di mezzi monetari per altre spese';
																		|pl = 'Wydawanie środków pieniężnych na inne wydatki';
																		|tr = 'Diğer giderler için nakit para ihracı'"));
	
	If GetFunctionalOption("UseInventoryConsumption") Then
		TransactionList.Add(Enums.BusinessTransactions.GoodsConsumptionOnDemand, NStr("vi = 'Tiêu dùng hàng hóa nội bộ';
																						|ru = 'Внутреннее потребление товаров';
																						|en = 'Inventory consumption — Non-operational activities'; fa = 'مصرف موجودی — فعالیت‌های غیرعملیاتی';
																						|it = 'Consumo interno delle merci';
																						|pl = 'Spożycie wewnętrzne towarów';
																						|tr = 'Stok tüketimi - Operasyonel olmayan faaliyetler'"));
	EndIf;
	If GetFunctionalOption("UseGoodsQuality") Then
		TransactionList.Add(Enums.BusinessTransactions.GoodsDamage, NStr("vi = 'Thay đổi giá trị hàng hỏng';
																		|ru = 'Изменение стоимости испорченного товара';
																		|en = 'Change of the spoiled goods cost'; fa = 'Change of the spoiled goods cost';
																		|it = 'Modifica del valore delle merci danneggiate';
																		|pl = 'Zmiana wartości zepsutego towaru';
																		|tr = 'Bozulan ürünün fiyatının değiştirilmesi'"));
	EndIf;
	TransactionList.Add(Enums.BusinessTransactions.GoodsMisgrading, NStr("vi = 'Thay đổi giá trị khi chuyển tồn';
																		|ru = 'Изменение стоимости при пересортице';
																		|en = 'Cost change in case of stock reclass'; fa = 'Cost change in case of stock reclass';
																		|it = 'Modifica del valore durante la riclassificazione';
																		|pl = 'Zmiana wartości przy przeklasyfikowaniu';
																		|tr = 'Yeniden sınıflandırma sırasında fiyat değiştirilmesi'"));
	TransactionList.Add(Enums.BusinessTransactions.GoodsConsumption, NStr("vi = 'Ghi giảm hàng thiếu';
																			|ru = 'Списания недостач товаров';
																			|en = 'Inventory shortage write-offs'; fa = 'Inventory shortage write-offs';
																			|it = 'Le iscrizioni degli ammanchi dei prodotti';
																			|pl = 'Rozchód wewnętrzny';
																			|tr = 'Stok eksiği tahakkuku'"));
	
	TransactionList.Add(Enums.BusinessTransactions.SaleToCustomer, NStr("vi = 'Cung cấp dịch vụ và tài sản khác';
																		|ru = 'Реализация услуг и прочих активов';
																		|en = 'Customer invoice — Services and Assets'; fa = 'فاکتور مشتری — خدمات و دارایی‌ها';
																		|it = 'Vendita dei servizi e altri attivi';
																		|pl = 'Realizacja usług i innych aktywów';
																		|tr = 'Müşteri faturası - Hizmetler ve Varlıklar'"));
	
	If GetFunctionalOption("UseNonCurrentAssets2_2")
	 Or GetFunctionalOption("UseNonCurrentAssets2_4") Then
		TransactionList.Add(Enums.BusinessTransactions.FixedAssetsInitialRecognition, NStr("vi = 'Tiếp nhận TSCĐ hữu hình vào kế toán';
																							|ru = 'Принятие к учету ОС';
																							|en = 'Fixed assets — Initial recognition'; fa = 'دارایی‌های ثابت — شناسایی اولیه';
																							|it = 'Scrittura nei libri contabili Cespiti';
																							|pl = 'Przyjęcie do ewidencji środków trwałych';
																							|tr = 'Sabit kıymetler - İlk tahakkuk'"));
		TransactionList.Add(Enums.BusinessTransactions.FixedAssetDepreciationParameterChange, NStr("vi = 'Thay đổi tham số TSCĐ hữu hình';
																									|ru = 'Изменение параметров ОС';
																									|en = 'Adjust fixed asset financial details'; fa = 'تعدیل جزئیات مالی دارایی ثابت';
																									|it = 'Modifica dei parametri dei capitali fissi';
																									|pl = 'Zmiana parametrów środków trwałych';
																									|tr = 'Sabit kıymet finansal bilgi düzeltmesi'"));
		TransactionList.Add(Enums.BusinessTransactions.DisposeFixedAssets, NStr("vi = 'Ghi giảm TSCĐ hữu hình';
																				|ru = 'Списание ОС';
																				|en = 'Dispose fixed assets'; fa = 'واگذاری دارایی‌های ثابت';
																				|it = 'Cancellazione contabile capitale fisso';
																				|pl = 'Wyksięgowanie środków trwałych';
																				|tr = 'Sabit kıymetlerin tasfiyesi'"));
		TransactionList.Add(Enums.BusinessTransactions.IntangibleAssetsInitialRecognition, NStr("vi = 'Tiếp nhận TSCĐ vô hình vào kế toán';
																								|ru = 'Принятие к учету НМА';
																								|en = 'Intangible assets — Initial recognition'; fa = 'دارایی‌های نامشهود — شناسایی اولیه';
																								|it = 'Scrittura nei libri contabili dei beni immateriali';
																								|pl = 'Przyjęcie do ewidencji wartości niematerialnych';
																								|tr = 'Maddi olmayan varlıklar - İlk tahakkuk'"));
		TransactionList.Add(Enums.BusinessTransactions.IntangibleAssetAmortizationParameterChange, NStr("vi = 'Thay đổi tham số TSCĐ vô hình';
																										|ru = 'Изменение параметров НМА';
																										|en = 'Adjust intangible asset financial details'; fa = 'تعدیل جزئیات مالی دارایی نامشهود';
																										|it = 'Modifica dei parametri degli attivi immateriali';
																										|pl = 'Zmiana parametrów wartości niematerialnych';
																										|tr = 'Maddi olmayan varlık finansal bilgi düzeltmesi'"));
		TransactionList.Add(Enums.BusinessTransactions.DisposeIntangibleAssets, NStr("vi = 'Ghi giảm TSCĐ vô hình';
																					|ru = 'Списание НМА';
																					|en = 'Dispose intangible assets'; fa = 'واگذاری دارایی‌های نامشهود';
																					|it = 'Cancellazione degli attivi immateriali';
																					|pl = 'Wyksięgowanie wartości niematerialnych';
																					|tr = 'Maddi olmayan varlık gider yazma'"));
	EndIf;
	
	If CostAllocationOptionManag = Enums.CostAllocationOptions.ToLinesOfBusiness
	 Or CostAllocationOptionManag = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly
	 Or CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness
	 Or CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly Then
		TransactionList.Add(Enums.BusinessTransactions.ARWriteOff, NStr("vi = 'Ghi giảm công nợ của bạn hàng';
																		|ru = 'Списание задолженности партнеров';
																		|en = 'Partner AR/AP write-off'; fa = 'Partner AR/AP write-off';
																		|it = 'Storno dei debiti dei partner';
																		|pl = 'Spisanie zadłużenia partnerów';
																		|tr = 'İş ortağının Alacak/Borç gider yazma'"));
		If GetFunctionalOption("UsePaymentByCards") Then
			TransactionList.Add(Enums.BusinessTransactions.BankReportOnAcquiringTransactions, NStr("vi = 'Phí dịch vụ thẻ thanh toán';
																									|ru = 'Эквайринговая комиссия';
																									|en = 'Acquiring fee'; fa = 'کارمزد پذیرندگی';
																									|it = 'Commissione di acquisizione';
																									|pl = 'Komisja acquiringowa';
																									|tr = 'PoS komisyonu'"));
		EndIf;
	EndIf;
	
	If GetFunctionalOption("UseCustomerRebates") Then
		TransactionList.Add(Enums.BusinessTransactions.RecordCustomerBonusRebates, NStr("vi = 'Ghi nhận tiền thưởng cho khách hàng (thưởng lũy kế)';
																						|ru = 'Отражение премий клиентам (ретро-бонусы)';
																						|en = 'Record customer bonuses (rebates)'; fa = 'Record customer bonuses (rebates)';
																						|it = 'Отражение премий клиентам (ретро-бонусы)';
																						|pl = 'Record customer bonuses (rebates)';
																						|tr = 'Müşteri primin yansıması (retro bonus)'"));
	EndIf;
	
EndProcedure

// Checks filling in the details of the expense item analyst in the transferred object.
//
// Parameters:
// 		Object - CatalogObject, DocumentObject, FormDataStructure - An information security object intended for verification
// 		Attributes - String, Structure, Array - Details of expenditure items for verification
// 			<Line> Enumeration of pairs of details for verification in the format "Costarayment1, Costarayment1, Costarayment2, Costarayment2, ..."
// 				an Empty string is interpreted as " Costarayment1, Costarayment1"
// 			<Structure> Key: a String with the name of the table part; Value-a String in notation as for the <String>type parameter
// 			< Array> an Array whose elements are either structures in the notation as for a parameter with the <Structure> type, or strings in the <String>notation
// 		AttributesNotToCheck - Array - Array for accumulating non-verifiable details of the passed object
// 		Cancel - Boolean - Indicates whether there are errors in filling in the expense analysis of the passed object
// 		AdditionalParameters - Structure - If the "program Check" property is present, errors are written to this structure, but are not output to the user.
//
Procedure CheckAnalystCompletion(Object, Attributes = "", AttributesNotToCheck = Undefined, Cancel = False,
	AdditionalParameters = Undefined) Export
	
	Errors = New Structure;
	Errors.Insert("ErrorList", New Array);
	Errors.Insert("ErrorGroups", New Map);
	Errors.Insert("ObjectPrefix", ?(TypeOf(Object)=Type("ClientApplicationForm"), "", "Object."));
	
	ProcessingArray = New Array;
	If TypeOf(Attributes) = Type("Array") Then
		ProcessingArray = Attributes;
	Else
		ProcessingArray.Add(Attributes);
	EndIf;
	
	For Each ArrayElement In ProcessingArray Do
		
		If TypeOf(ArrayElement) = Type("Structure") Then
			CheckingFillingOfObjectSTSAnalyst(Object,
												ArrayElement,
												AttributesNotToCheck,
												Errors,
												AdditionalParameters);
		Else
			ThisIsObjectOnForm = False;
			If TypeOf(AdditionalParameters) = Type("Structure")
				And AdditionalParameters.Property("ThisIsObjectOnForm")Then
				ThisIsObjectOnForm = AdditionalParameters.ThisIsObjectOnForm;
			EndIf;
			CheckingContentOfObjectAnalytics(Object, ArrayElement, AttributesNotToCheck, Errors, ThisIsObjectOnForm);
		EndIf;
		
	EndDo;
	
	If TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("SoftwareVerification") Then
		AdditionalParameters.Insert("Errors", Errors);
	Else
		If Errors.ErrorList.Count() <> 0 Then
			CommonClientServer.ReportErrorsToUser(Errors, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

// Returns articles that require analytics to be filled in.
// 
// Parameters:
//  ArrayOfArticles - Array of ChartOfCharacteristicTypesRef.ExpenseItems - Array of articles.
// 
// Returns:
//  Array of ChartOfCharacteristicTypesRef.ExpenseItems - Articles that require filling in analytics.
Function ArticlesWithMandatoryAnalytics(ArrayOfArticles) Export
	
	Query = New Query(
	"SELECT
	|	ARTICLES__.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.Ref IN (&ArrayOfArticles)
	|	AND ARTICLES__.ControlDimensionFilling");
	
	Query.SetParameter("ArrayOfArticles", ArrayOfArticles);
	Result = Query.Execute();

	ListOfArticles = New Array;
	Selection = Result.Select();
	While Selection.Next() Do
		ListOfArticles.Add(Selection.Ref);
	EndDo;
	
	Return ListOfArticles;
	
EndFunction

// Returns items that are not allowed to be used
//
// Returns:
// 	ValueList - A list of blocked items of expenditure.
//
Function BlockedExpenditureItems() Export
	
	BlockedArticles = New ValueList;
	BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.SaleCost);
	If GetFunctionalOption("BaseVersion") Then
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.VATAccruedOnRepurchaseOfReusablePackage);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.CostCalculationError);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.GenerateLossAllowance);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent);
	EndIf;
	If GetFunctionalOption("TradeManagement") Then
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.AdditionalAccrualOfPropertyTaxesAndDepreciation);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.ProductionCostsReverseTransaction);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.FASellingExpenses);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetRetirement);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetSale);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.LongTermAssetsToBeSold);
	EndIf;
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses);
	EndIf;
	
	ExpenseItemsLocalization.AddBlockedArticlesToYourList(BlockedArticles);
	
	Return BlockedArticles;
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	#Region OutflowsOfGoodsInPastPeriods
	Item = Items.Add();
	Item.PredefinedDataName = "OutflowsOfGoodsInPastPeriods";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thanh lý hàng hóa trong kỳ trước';
																					|ru = 'Выбытия товаров в прошлых периодах';
																					|en = 'Outflows of goods in past periods';
																					|it = 'Ritiro delle merci nei periodi precedenti';
																					|pl = 'Wycofanie towarów w zeszłych okresach';
																					|tr = 'Ürünlerin geçmiş dönemlerde elden çıkarılması'", LanguagesCodes); // @NStr-2
	Item.Code = "000000012";
	Item.ValueType = New TypeDescription("CatalogRef.Products");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);
	#EndRegion
	
	#Region AdditionalAccrualOfPropertyTaxesAndDepreciation
	Item = Items.Add();
	Item.PredefinedDataName = "AdditionalAccrualOfPropertyTaxesAndDepreciation";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phí bổ sung thuế tài sản và khấu hao';
																					|ru = 'Доначисление имущественных налогов и амортизации';
																					|en = 'Additional accrual of property taxes and depreciation';
																					|it = 'Accantonamento delle imposte sugli immobili e degli ammortamenti';
																					|pl = 'Doliczenie podatków majątkowych i amortyzacji';
																					|tr = 'Emlak vergileri ve amortisman için ek ücret'", LanguagesCodes); // @NStr-2
	Item.Code = "000000011";
	Item.ValueType = New TypeDescription("CatalogRef.OtherExpenses");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);
	#EndRegion

	#Region ExchangeRateDifferences
	Item = Items.Add();
	Item.PredefinedDataName = "ExchangeRateDifferences";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch tỷ giá';
																					|ru = 'Курсовые разницы';
																					|en = 'Exchange differences';
																					|it = 'Differenze dei tassi di cambio';
																					|pl = 'Różnice kursowe';
																					|tr = 'Döviz kuru farkları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000003";
	Item.ValueType = New TypeDescription("EnumRef.ExchangeDifferencesDimension");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.OtherActivity;
	AddItemToExpenseItem(Item);
	#EndRegion

	#Region VATAccruedOnRepurchaseOfReusablePackage
	Item = Items.Add();
	Item.PredefinedDataName = "VATAccruedOnRepurchaseOfReusablePackage";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT đã tính khi mua lại bao bì luân chuyển';
																					|ru = 'Начисленный НДС при выкупе многооборотной тары';
																					|en = 'VAT accrued at the redemption of reusable packaging';
																					|it = 'IVA calcolata al riscatto dell''imballaggio riutilizzabile';
																					|pl = 'Naliczony VAT podczas wykupu tary wielokrotnego użytku';
																					|tr = 'Yeniden kullanılabilir ambalaj geri satın alımında KDV tahakkuku'", LanguagesCodes); // @NStr-2
	Item.Code = "000000005";
	Item.ExpensesOccur = Enums.ExpenseTypes.SalesOfGoods;
	Item.ValueType = New TypeDescription("CatalogRef.Partners");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region VATOfTaxAgent
	Item = Items.Add();
	Item.PredefinedDataName = "VATOfTaxAgent";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT của đại lý thuế';
																					|ru = 'НДС Налогового агента';
																					|en = 'Tax agent VAT';
																					|it = 'IVA del Sostituto d''imposta';
																					|pl = 'VAT agenta podatku';
																					|tr = 'Vergi memurunun KDV''si'", LanguagesCodes); // @NStr-2
	Item.Code = "000000009";
	Item.ExpensesOccur = Enums.ExpenseTypes.PurchaseOfGoods;
	Item.ValueType = New TypeDescription("DocumentRef.VendorInvoice");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost;
	Item.CostAllocationRuleToProcuctCost = Enums.RulesOfAllocationForInventoryCost.InProportionToProductCost;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region CostCalculationError
	Item = Items.Add();
	Item.PredefinedDataName = "CostCalculationError";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lỗi tính giá vốn';
																					|ru = 'Погрешность расчета себестоимости';
																					|en = 'Cost calculation error';
																					|it = 'Errore di calcolo dei costi ';
																					|pl = 'Błąd rozliczenia kosztów własnych';
																					|tr = 'Hesaplama yönteminde hata'", LanguagesCodes); // @NStr-2
	Item.Code = "000000002";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region ProfitLossOfPreviousYears
	Item = Items.Add();
	Item.PredefinedDataName = "ProfitLossOfPreviousYears";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi (lỗ) các năm trước';
																					|ru = 'Прибыль (убыток) прошлых лет';
																					|en = 'Previous years profit (loss)';
																					|it = 'Utile (perdita) degli anni passati';
																					|pl = 'Zysk (strata) z lat ubiegłych';
																					|tr = 'Geçmiş yıllardan gelen kâr (zarar)'", LanguagesCodes); // @NStr-2
	Item.Code = "000000007";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.OtherActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region DifferencesInCostOfReturnAndActualCostOfGoods
	Item = Items.Add();
	Item.PredefinedDataName = "DifferencesInCostOfReturnAndActualCostOfGoods";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch giá trị trả lại và giá trị thực tế của hàng hóa';
																					|ru = 'Разницы стоимости возврата и фактической стоимости товаров';
																					|en = 'Differences in the cost of return and the actual cost of goods';
																					|it = 'Differenze nel costo del reso e nel costo effettivo della merce';
																					|pl = 'Różnice wartości zwrotu i wartości faktycznej towarów';
																					|tr = 'İade fiyatı ile malların gerçek fiyatı arasındaki farklar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000004";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region ExpensesLeasePayments
	Item = Items.Add();
	Item.PredefinedDataName = "ExpensesLeasePayments";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí tiền thuê khấu trừ khấu hao';
																					|ru = 'Расходы по лизинговым платежам за вычетом сумм амортизации';
																					|en = 'Financial lease payment costs, net of depreciation';
																					|it = 'Spese relative ai pagamenti di leasing con la detrazione degli importi dell''ammortamento';
																					|pl = 'Rozchody wg płatności leasingowaych za wyjątkiem kwot amortyzacji';
																					|tr = 'Finansal kiralama ödemesi, amortisman tutarlarından düşüldükten sonra'", LanguagesCodes); // @NStr-2
	Item.Code = "000000015";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region ExpensesForPlato
	Item = Items.Add();
	Item.PredefinedDataName = "ExpensesForPlato";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí đối với ""Platon""';
																					|ru = 'Расходы на ""Платон""';
																					|en = 'Expenses for Platon';
																					|it = 'Spese di ""Platone""';
																					|pl = 'Rozchody na system ""Platon""';
																					|tr = '""Platon"" için harcamalar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000013";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region CurrencyConversionExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "CurrencyConversionExpenses";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí chuyển đổi tiền tệ';
																					|ru = 'Расходы при конвертации валюты';
																					|en = 'Currency conversion costs';
																					|it = 'Spese alla conversione della valuta';
																					|pl = 'Rozchody podczas wymiany waluty';
																					|tr = 'Para birimi dönüştürme giderleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000014";
	Item.ValueType = New TypeDescription("EnumRef.ExchangeDifferencesDimension");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.OtherActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region SaleCost
	Item = Items.Add();
	Item.PredefinedDataName = "SaleCost";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giá vốn hàng bán';
																					|ru = 'Себестоимость продаж';
																					|en = 'COGS';
																					|it = 'Costo di produzione delle vendite';
																					|pl = 'Koszty własne sprzedaży';
																					|tr = 'Satılan malların maliyeti'", LanguagesCodes); // @NStr-2
	Item.Code = "000000001";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region SalesCharge
	Item = Items.Add();
	Item.PredefinedDataName = "SalesCharge";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phí bán hàng';
																					|ru = 'Торговый сбор';
																					|en = 'Sales charge';
																					|it = 'Imposta sul commercio';
																					|pl = 'Opłata handlowa';
																					|tr = 'Ticaret ücreti'", LanguagesCodes); // @NStr-2
	Item.Code = "000000010";
	Item.ValueType = New TypeDescription("CatalogRef.Warehouses");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region GenerateLossAllowance
	Item = Items.Add();
	Item.PredefinedDataName = "GenerateLossAllowance";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lập dự phòng theo công nợ khó đòi';
																					|ru = 'Формирование резервов по сомнительным долгам';
																					|en = 'Generate loss allowance';
																					|it = 'Generare accantonamento per crediti di dubbia esigibilità';
																					|pl = 'Tworzenie rezerw wg wątpliwych długów';
																					|tr = 'Şüpheli borç rezervlerinin oluşturulması'", LanguagesCodes); // @NStr-2
	Item.Code = "000000008";
	Item.ValueType = New TypeDescription("CatalogRef.Companies");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region GoodsValueVariance
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsValueVariance";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch trong giá trị hàng hóa';
																					|ru = 'Отклонение в стоимости товаров';
																					|en = 'Goods cost variance';
																					|it = 'Variazione nel costo delle merci';
																					|pl = 'Odchylenie w wartości towarów';
																					|tr = 'Ürünlerin fiyatında sapma'", LanguagesCodes); // @NStr-2
	Item.Code = "000000016";
	Item.ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion
	
	#Region ProductionCostsReverseTransaction
	Item = Items.Add();
	Item.PredefinedDataName = "ProductionCostsReverseTransaction";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hoàn nhập chi phí sản xuất';
																					|ru = 'Сторно производственных затрат';
																					|en = 'Production costs storno';
																					|it = 'Storno delle spese di produzione';
																					|pl = 'Storno rozchodów produkcyjnych';
																					|tr = 'Üretim maliyetleri iptal'", LanguagesCodes); // @NStr-2
	Item.Code = "000000017";
	Item.ValueType = New TypeDescription("CatalogRef.Products");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	Item.ProductionCostType = Enums.ProductionCostType.Variables1;
	AddItemToExpenseItem(Item);
	#EndRegion
	
	#Region ProductionCostOfPreviousPeriods
	Item = Items.Add();
	Item.PredefinedDataName = "ProductionCostOfPreviousPeriods";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí sản xuất kỳ trước';
																					|ru = 'Производственные расходы прошлых периодов';
																					|en = 'Production costs in past periods';
																					|it = 'Spese di produzione dei periodi precedenti';
																					|pl = 'Rozchody produkcyjne zeszłych okresów';
																					|tr = 'Önceki dönemlerin üretim maliyetleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000018";
	Item.ValueType = New TypeDescription("CatalogRef.Products");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	Item.ProductionCostType = Enums.ProductionCostType.Variables1;
	AddItemToExpenseItem(Item);	
	#EndRegion
	
	#Region FAWriteOffExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "FAWriteOffExpenses";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí liên quan đến việc ghi giảm TSCĐ';
																					|ru = 'Расходы, связанные со списанием ОС';
																					|en = 'Fixed asset disposal expenses';
																					|it = 'Uscite collegate alla dismissione dell''Immobilizzazione';
																					|pl = 'Rozchody, związane ze rozchodem ŚT';
																					|tr = 'Sabit kıymet gider yazma ile ilgili giderler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000019";
	Item.ValueType = New TypeDescription("CatalogRef.Assets");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region TangibleAssetRetirement
	Item = Items.Add();
	Item.PredefinedDataName = "TangibleAssetRetirement";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thanh lý hàng tồn kho';
																					|ru = 'Выбытие материальных ценностей';
																					|en = 'Tangible asset retirement';
																					|it = 'Выбытие материальных ценностей';
																					|pl = 'Tangible asset retirement';
																					|tr = 'Maddi varlıkların elden çıkarılması'", LanguagesCodes); // @NStr-2
	Item.Code = "000000021";
	Item.ValueType = New TypeDescription("CatalogRef.Assets");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region TangibleAssetSale
	Item = Items.Add();
	Item.PredefinedDataName = "TangibleAssetSale";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bán hàng tồn kho';
																					|ru = 'Продажа материальных ценностей';
																					|en = 'Tangible asset sale';
																					|it = 'Продажа материальных ценностей';
																					|pl = 'Tangible asset sale';
																					|tr = 'Maddi varlıkların satışı'", LanguagesCodes); // @NStr-2
	Item.Code = "000000023";
	Item.ValueType = New TypeDescription("CatalogRef.Assets");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion

	#Region FASellingExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "FASellingExpenses";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí liên quan đến việc bán TSCĐ';
																					|ru = 'Расходы, связанные с продажей ОС';
																					|en = 'Fixed asset sale expenses';
																					|it = 'Uscite collegate alla vendita dell''Immobilizzazione';
																					|pl = 'Rozchody, związane ze sprzedażą ŚT';
																					|tr = 'Sabit kıymet satma ile ilgili giderler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000020";
	Item.ValueType = New TypeDescription("CatalogRef.Assets");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion
	
	#Region LongTermAssetsToBeSold
	Item = Items.Add();
	Item.PredefinedDataName = "LongTermAssetsToBeSold";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản dài hạn cần bán';
																					|ru = 'Долгосрочные активы к продаже';
																					|en = 'Long-term assets to be sold';
																					|it = 'Долгосрочные активы к продаже';
																					|pl = 'Long-term assets to be sold';
																					|tr = 'Satış amaçlı uzun vadeli varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000022";
	Item.ValueType = New TypeDescription("CatalogRef.Assets");
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.DoNotAllocate;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);	
	#EndRegion
	
	#Region Commission
	Item = Items.Add();
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hoa hồng ký gửi';
																					|ru = 'Комиссионное вознаграждение';
																					|en = 'Commission';
																					|it = 'Commissione';
																					|pl = 'Wynagrodzenie komisowe';
																					|tr = 'Komisyon ücretlendirmesi'", LanguagesCodes); // @NStr-2
	Item.Code = "000000024";
	Item.ExpensesOccur = Enums.ExpenseTypes.SalesOfGoods;
	Item.ValueType = New TypeDescription("CatalogRef.Partners");
	Item.CostAllocationRuleToCostOfGoodsSoldMan =
		Enums.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity;
	Item.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostOfGoodsSold;
	Item.CostAllocationRuleToCostOfGoodsSoldLocal =
		Enums.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity;
	Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostOfGoodsSold;
	Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
	AddItemToExpenseItem(Item);
	#EndRegion
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.ExpenseItems - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	If IsBlankString(Object.PredefinedDataName) Then
		Object.ValueType = Data.ValueType;
	EndIf;
	
EndProcedure

// Returns the correspondence of the articles for which the distribution option cannot be changed to the value of the distribution option.
// 
// Returns:
//	Map - values for articles
//		The key is the plan of the characteristicslink.Article of Expenditure - an article for which an immutable distribution option is used;
//		The value is the enumeration of the link.Cost-allocation variationis the distribution option that should be used for the article.
//
Function ComplianceOfArticlesWithDistributionOptions() Export
	
	ComplianceOfArticlesWithDistributionOptions = New Map;
	
	ListOfDistributionOptions = New ValueList;
	ListOfDistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	ListOfDistributionOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);

	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.ExchangeRateDifferences, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.VATAccruedOnRepurchaseOfReusablePackage, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.CostCalculationError, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.SaleCost, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.GenerateLossAllowance, ListOfDistributionOptions);
	
	ListOfDistributionOptions = New ValueList;
	ListOfDistributionOptions.Add(Enums.CostAllocationOptions.ToInventoryCost);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent, ListOfDistributionOptions);
	
	ListOfDistributionOptions = New ValueList;
	ListOfDistributionOptions.Add(Enums.CostAllocationOptions.DoNotAllocate);
	
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.FASellingExpenses, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetRetirement, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetSale, ListOfDistributionOptions);
	ComplianceOfArticlesWithDistributionOptions.Insert(ChartsOfCharacteristicTypes.ExpenseItems.LongTermAssetsToBeSold, ListOfDistributionOptions); 
	
	Return ComplianceOfArticlesWithDistributionOptions;
	
EndFunction

// Returns the correspondence of items for which the type of expenses cannot be changed to the corresponding value.
// 
// Returns:
//	Map:
//		The key is the plan of the characteristicslink.Expenditure item - an item for which an immutable type of expenditure is used;
//		The value is the enumeration of the link.Types of expenses - the type of expense that should be used for the article.
//
Function ComplianceOfItemsWithTypesOfExpenses() Export
	
	ComplianceOfItemsWithTypesOfExpenses = New Map;
	ComplianceOfItemsWithTypesOfExpenses.Insert(ChartsOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses, Enums.ExpenseTypes.OtherExpenses);
	ComplianceOfItemsWithTypesOfExpenses.Insert(ChartsOfCharacteristicTypes.ExpenseItems.FASellingExpenses, Enums.ExpenseTypes.OtherExpenses);
	ComplianceOfItemsWithTypesOfExpenses.Insert(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetRetirement, Enums.ExpenseTypes.OtherExpenses);
	ComplianceOfItemsWithTypesOfExpenses.Insert(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetSale, Enums.ExpenseTypes.OtherExpenses);
	ComplianceOfItemsWithTypesOfExpenses.Insert(ChartsOfCharacteristicTypes.ExpenseItems.LongTermAssetsToBeSold, Enums.ExpenseTypes.OtherExpenses);
	ComplianceOfItemsWithTypesOfExpenses.Insert(ChartsOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent, Enums.ExpenseTypes.PurchaseOfGoods);
	
	Return ComplianceOfItemsWithTypesOfExpenses;
	
EndFunction

// Returns the value types of the expense item allocated for sales. For the listed types
//	, these documents will be selected as the cost item analytics.
//
//	Returns:
//		TypeDescription - description of the type that will be assigned to such an article.
Function TypesOfDocumentsArticlesDistributedForSale() Export
	
	ArrayOfDocumentTypes_ = New Array;
	DocumentsArray = ListOfDocumentsForArticlesDistributedForSale().UnloadValues();
	For Each MetadataOfDocument In DocumentsArray Do
		ArrayOfDocumentTypes_.Add("DocumentRef." + MetadataOfDocument.Name);
	EndDo;
	
	TypesOfDocumentsByString = StrConcat(ArrayOfDocumentTypes_, ",");
	Return New TypeDescription(TypesOfDocumentsByString);
	
EndFunction

// Returns the identifiers of the metadata objects of the documents of the expense item allocated for sale.
// For the listed types, these documents will be selected as the cost item analytics.
//
//	Returns:
//		Array of CatalogRef.MetadataObjectIDs - documents that can be selected as an analysis
//	of an expense item allocated for sale.
Function IdentifiersOfDocumentsArticlesDistributedForSale() Export
	
	ArrayOfIdentifiers = New Array;
	For Each MetadataOfDocument In ListOfDocumentsForArticlesDistributedForSale() Do
		
		If Not AccessRight("Read", MetadataOfDocument.Value) Or Not MetadataOfDocument.Check Then
			Continue;
		EndIf;
		
		ArrayOfIdentifiers.Add(Common.MetadataObjectID(MetadataOfDocument.Value));
		
	EndDo;
	
	Return ArrayOfIdentifiers;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Fills in the selection in the parameters when processing the receipt of selection data and opening the selection form.
//
// Parameters:
// 		Parameters - Structure - The structure of parameters in the format of parameters of the selection form or the procedure "processing the selection data".
//
Procedure ProcessingSelectionParameters(Parameters) Export
	
	NonCurrentAssets.ProcessingParametersForSelectingExpenseItem(Parameters);

	InventoryInOperationServer.ProcessingParametersForSelectingExpenseItem(Parameters);
	
EndProcedure

// Fills in the details of the expense account settings that affect the setup
// 	with the corresponding names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.ExpenseTypeCategory = "ExpenseTypeCategory";
	MatchingNames.CostAllocationOptionLocal = "CostAllocationOptionLocal";
	MatchingNames.ExpensesOnAssets = "ExpensesOnAssets";
	MatchingNames.ExpensesOnConstructionObjects = "ExpensesOnConstructionObjects";
	MatchingNames.IntangibleAssetsAndRDExpenses = "IntangibleAssetsAndRDExpenses";
	ExpenseItemsLocalization.FillInMatchingAccountSettingsDetails(MatchingNames);
	
EndProcedure

// Gets a list of batches for a list of Attribute values
// Parameters:
//  Period - Date
//  AttributeName - String
//  Values - ValueList of CatalogRef
//  ByHierarchy - Boolean
// Returns:
//  ValueList of ChartOfCharacteristicTypesRef.ExpenseItems
// 
Function ListOfItemsByProps(Period, AttributeName, Val Values, ByHierarchy = False) Export
	Result = New ValueList;
	
	If Not TypeOf(Values) = Type("ValueList") Then
		Return Result;
	EndIf;
	
	QueryText = "SELECT
	|	ExpenseItems.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	NOT ExpenseItems.CostAllocationOptionLocal IN
	|	(VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|	AND ExpenseItems.Ref IN (&Values)
	|
	|UNION ALL
	|
	|SELECT
	|	ExpenseItems.Ref
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		INNER JOIN Catalog.ProductCostElements AS CatalogProductCostElements
	|		ON ExpenseItems.ProductCostElement = CatalogProductCostElements.Ref
	|WHERE
	|	ExpenseItems.CostAllocationOptionLocal IN
	|	(VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|	AND CatalogProductCostElements.Ref IN (&ValuesOfCalculationArticle)";
	
	QueryText = StrReplace(QueryText, "ExpenseItems.Ref IN (&Values)",
												"ExpenseItems." + AttributeName + " IN (&Values)");
	QueryText = StrReplace(QueryText, "CatalogProductCostElements.Ref IN (&ValuesOfCalculationArticle)",
												"CatalogProductCostElements." + AttributeName + " IN (&Values)");
	If ByHierarchy Then
		QueryText = StrReplace(QueryText, " IN (&Values)", " IN HIERARCHY (&Values)");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	Query.SetParameter("Values", Values);

	FoundItems1 = Query.Execute().Unload().UnloadColumn("Ref");
	Result.LoadValues(FoundItems1);
	
	Return Result;
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	IncomeAndExpensesServer.ProcessingReceiptOfSelectionDataForExpenseItem(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

#Region ServiceProceduresAndFunctionsForFillingInAnalytics

Function NamesOfArticleAndAnalyticsDetails(AttributesRow, AttributesNotToCheck = Undefined, TablePartPrefix = "")
	
	If IsBlankString(AttributesRow) Then
		If AttributesNotToCheck <> Undefined Then
			AttributesNotToCheck.Add(TablePartPrefix + "DimensionOfExpenses");
		EndIf;
		Return New Structure("ExpenseItem", "DimensionOfExpenses");
	EndIf;
	
	DataProcessorStructure = New Structure(AttributesRow);
	ReturnStructure = New Structure;
	PreviousKey = Undefined;
	For Each KeyAndValue In DataProcessorStructure Do
		If PreviousKey = Undefined Then
			PreviousKey = KeyAndValue.Key;
		Else
			ReturnStructure.Insert(PreviousKey, KeyAndValue.Key);
			PreviousKey = Undefined;
			If AttributesNotToCheck <> Undefined Then
				AttributesNotToCheck.Add(TablePartPrefix + KeyAndValue.Key);
			EndIf;
		EndIf;
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

Procedure CheckingContentOfObjectAnalytics(Object, Attributes, AttributesNotToCheck, Errors, ThisIsObjectOnForm)
	
	ObjectData		= Object;
	ArrayOfArticles		= New Array;
	AttributesStructure1	= NamesOfArticleAndAnalyticsDetails(Attributes, AttributesNotToCheck);
	
	If ThisIsObjectOnForm And TypeOf(Object) = Type("Structure")
		And CommonClientServer.HasAttributeOrObjectProperty(Object, "Object") Then
		
		ObjectData = Object.Object;
		
	EndIf;
	
	// Let's define a list of articles to control
	For Each KeyAndValue In AttributesStructure1 Do
		AssetRef = ObjectData[KeyAndValue.Key];
		
		If ValueIsFilled(AssetRef) Then
			ArrayOfArticles.Add(AssetRef);
		EndIf;
	EndDo;
	
	// Let's check the filling of the analytics
	MandatoryArticles = ArticlesWithMandatoryAnalytics(ArrayOfArticles);
	For Each KeyAndValue In AttributesStructure1 Do
		AssetRef		= ObjectData[KeyAndValue.Key];
		Dimension	= ObjectData[KeyAndValue.Value];
		
		If Not (MandatoryArticles.Find(AssetRef) = Undefined
			Or ValueIsFilled(Dimension)) Then
			
			CommonClientServer.AddUserError(
				Errors,
				Errors.ObjectPrefix + KeyAndValue.Value,
				NStr("vi = 'Chỉ số chi phí chưa điền';
					|ru = 'Аналитика расходов не заполнена';
					|en = 'Expense dimension is required'; fa = 'بُعد هزینه الزامی است';
					|it = 'Analitica delle spese non compilata';
					|pl = 'Nie wypełniono analityki kosztów';
					|tr = 'Gider boyutu doldurulmamış'"), "");
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckingFillingOfObjectSTSAnalyst(Object,
												Attributes,
												AttributesNotToCheck,
												Errors,
												AdditionalParameters = Undefined)
	
	// Let's define a list of articles to control
	GeneralArrayOfArticles = New Array;
	
	For Each DescriptionOfTS In Attributes Do
		TSName = DescriptionOfTS.Key;
		
		AttributesStructure1 = NamesOfArticleAndAnalyticsDetails(DescriptionOfTS.Value, AttributesNotToCheck, TSName + ".");
		
		For Each KeyAndValue In AttributesStructure1 Do
			ArrayOfArticles = Object[TSName].UnloadColumn(KeyAndValue.Key);
			
			
			For Each AssetRef In ArrayOfArticles Do
				GeneralArrayOfArticles.Add(AssetRef);
			EndDo;
		EndDo;
	EndDo;
	
	// Let's check the filling of the analytics
	MandatoryArticles = ArticlesWithMandatoryAnalytics(GeneralArrayOfArticles);
	
	For Each DescriptionOfTS In Attributes Do // Table parts
		TSName	= DescriptionOfTS.Key;
		TS		= Object[TSName];
		
		If TypeOf(TS) = Type("ValueTable")
			And TypeOf(AdditionalParameters) = Type("Structure") Then
			
			TabularSection = Undefined;
			
			PresentationOfTS			= AdditionalParameters.PresentationOfTS;
			DetailsPresentations	= AdditionalParameters.DetailsPresentations;
			
		Else
			ObjectMetadata	= Object.Metadata();
			TabularSection		= ObjectMetadata.TabularSections.Find(TSName);
			
			PresentationOfTS			= TabularSection.Synonym;
			DetailsPresentations	= Undefined;
		EndIf;
		
		AttributesStructure1 = NamesOfArticleAndAnalyticsDetails(DescriptionOfTS.Value, Undefined, TSName + ".");
		
		For IndexOf = 0 To TS.Count() - 1 Do // Table part rows
			TSRow = TS[IndexOf];
			
			For Each KeyAndValue In AttributesStructure1 Do
				If TabularSection = Undefined Then
					AttributeRepresentation = DetailsPresentations[KeyAndValue.Value];
				Else
					AttributeRepresentation = TabularSection.Attributes.Find(KeyAndValue.Value).Synonym;
				EndIf;
				
				AssetRef		= TSRow[KeyAndValue.Key];
				Dimension	= TSRow[KeyAndValue.Value];
				
				If Not (MandatoryArticles.Find(AssetRef) = Undefined
					Or ValueIsFilled(Dimension)) Then
					
					CommonClientServer.AddUserError(
						Errors,
						Errors.ObjectPrefix + TSName + "[%1]." + KeyAndValue.Value,
						StrTemplate(NStr("vi = 'Trường ""%1"" trong dòng %2 của danh sách ""%3"" không được điền';
										|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
										|en = '""%1"" in line %2 of list ""%3"" is required'; fa = '""%1"" in line %2 of list ""%3"" is required';
										|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""%3"" non è compilato';
										|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
										|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'"),
							AttributeRepresentation, TSRow.LineNumber, PresentationOfTS),
						TSName,
						IndexOf,
						StrTemplate(NStr("vi = 'Trường ""%1"" trong dòng %2 của danh sách ""%3"" không được điền';
										|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
										|en = '""%1"" in line %2 of list ""%3"" is required'; fa = '""%1"" in line %2 of list ""%3"" is required';
										|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""%3"" non è compilato';
										|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
										|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'"),
							AttributeRepresentation, TSRow.LineNumber, PresentationOfTS));
					
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

Procedure AddItemToExpenseItem(Item)
	
	If Not ValueIsFilled(Item.ExpensesOccur) Then
		
		Item.ExpensesOccur = Enums.ExpenseTypes.OtherExpenses;
		
	EndIf;
	
	If Not ValueIsFilled(Item.CostAllocationOptionManag) Then
		
		Item.CostAllocationOptionManag = Item.CostAllocationOptionLocal;
		
	EndIf;
	
	If Not ValueIsFilled(Item.CostAllocationOptionTax) Then
		
		Item.CostAllocationOptionTax = Item.CostAllocationOptionLocal;
		
	EndIf;
	
	// SeparateVATAccountingOption
	Item.SeparateVATAccountingOption = Enums.SeparateVATAccountingOptions.FromDocument;
	
	Item.EnteredInTaxAccounting = True;
	
	ExpenseItemsLocalization.OnInitialItemFilling(Item);
	
	SpecifyHFCOfPredefinedArticle(Item);
	FillInVATValueType(Item);
	
EndProcedure

Procedure FillInVATValueType(Item)
	
	// The fill-in condition must match the element's form condition.
	If Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost Then
		Item.VATAssetTaxClass = Enums.AssetKinds.Goods;
	ElsIf Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
		If Item.ValueType = "CatalogRef.Assets" Then
			Item.VATAssetTaxClass = Enums.AssetKinds.FA;
		ElsIf Item.ValueType = "CatalogRef.ConstructionObjects"
			Or Item.ValueType = "CatalogRef.ConstructionObjects22" Then
			Item.VATAssetTaxClass = Enums.AssetKinds.ConstructionInProgressObjects;
		ElsIf Item.ValueType = "CatalogRef.IntangibleAssets" 
			Or Item.ValueType = "CatalogRef.RDTopicsStages" Then
			Item.VATAssetTaxClass = Enums.AssetKinds.IA;
		EndIf;
	Else
		Item.VATAssetTaxClass = Enums.AssetKinds.OtherWorksAndServices;
	EndIf;
	
EndProcedure

Procedure SpecifyHFCOfPredefinedArticle(ExpenseItem)
	
	SpecifiedArticle = Undefined;
	
	If Not ExpenseItem.FinancialAccountingGroup.IsEmpty() Then
		SpecifiedArticle = ExpenseItem.FinancialAccountingGroup;
	EndIf;
	
	If Not ExpenseItem.FinancialAccountingGroupLocal.IsEmpty() Then
		SpecifiedArticle = ExpenseItem.FinancialAccountingGroupLocal;
	EndIf;
	
	
	If SpecifiedArticle = Undefined Then
		
		DescriptionTemplate = NStr("vi = 'Tùy chỉnh tài khoản đối với dạng chi phí ""%1""';
									|ru = 'Настройки счетов для статьи расходов ""%1""';
									|en = 'Set up accounts for expense item ""%1""'; fa = 'Set up accounts for expense item ""%1""';
									|it = 'Impostazioni conti per la voce di spesa ""%1""';
									|pl = 'Ustawienia kont dla pozycji rozchodów ""%1""';
									|tr = '""%1"" gider kalemi için hesap ayarları'");
		NameOfHFC = StrTemplate(DescriptionTemplate, ExpenseItem.Description);
		
		HFCLink = ChartsOfCharacteristicTypes.ExpenseItems.FindByDescription(NameOfHFC, True);
		
		If HFCLink.IsEmpty() Then
			// Let's create a HFC of income/expenses:
			
			FAG = Catalogs.IncomeExpensesAccountingGroups.CreateItem();
			
			HFCLink = Catalogs.IncomeExpensesAccountingGroups.GetRef();
			FAG.SetNewObjectRef(HFCLink);
			
			FAG.Description = NameOfHFC;
			FAG.Expenses = True;
			FAG.Income = False;
			
			TemplateOfDescription = NStr("vi = 'Nhóm hệ thống tùy chỉnh kế toán tài chính thu nhập/chi phí đối với tài khoản kế toán có dạng chi phí định trước ""%1""';
										|ru = 'Служебная группа настроек финансового учета доходов/расходов для счетов учета предопределенной статьи расходов ""%1""';
										|en = 'Internal income/expense accounting groups for ledger accounts of predefined expense item ""%1""'; fa = 'Internal income/expense accounting groups for ledger accounts of predefined expense item ""%1""';
										|it = 'Gruppo di impostazioni di servizio per contabilità finanziaria di entrate/uscite per conti di contabilità della voce di spesa predefinita ""%1""';
										|pl = 'Serwisowa grupa ustawień ewidencji finansowej dochodów/rozchodów dla kont księgowych predefiniowanej pozycji rozchodów ""%1""';
										|tr = '""%1"" önceden tanımlanmış gider kaleminin defterikebir hesapları için gelir/gider muhasebe grupları hizmeti'");
			FAG.LongDesc = StrTemplate(TemplateOfDescription, ExpenseItem.Description);
			
			FAG.DataExchange.Load = True;
			FAG.Write();
		EndIf;
		
		ExpenseItem.FinancialAccountingGroup = HFCLink;
		ExpenseItem.FinancialAccountingGroupLocal = HFCLink;
			
	Else
		// Fill in the unfilled HFCs according to the already specified:
		
		If ExpenseItem.FinancialAccountingGroup.IsEmpty() Then
			ExpenseItem.FinancialAccountingGroup = SpecifiedArticle;
		EndIf;
		
		If ExpenseItem.FinancialAccountingGroupLocal.IsEmpty() Then
			ExpenseItem.FinancialAccountingGroupLocal = SpecifiedArticle;
		EndIf;
		
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

#Region FillSeparatedDataHandlers

	Handler = Handlers.Add();
	Handler.Procedure = "ChartsOfCharacteristicTypes.ExpenseItems.FillSeparatedDataHandlers";
	Handler.Version = "11.5.26.36";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	Handler.Comment = "";

#EndRegion

	Handler = Handlers.Add();
	Handler.Version = "11.5.26.36";
	Handler.Procedure = "ChartsOfCharacteristicTypes.ExpenseItems.CheckAddArticleCommission";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("e9f91957-88a0-41bd-b5a0-bae0dd1d5b969");
	Handler.Comment = NStr("vi = 'Khi không có dạng chi phí với phương án phân bổ ""Vào giá vốn bán hàng"" và khi tắt kiểm soát việc điền đối tượng phân tích, hệ thống sẽ tạo một phần tử mới ""Hoa hồng ký gửi"".';
							|ru = 'При отсутствии статьи расходов с вариантом распределения ""На себестоимость продаж"" и отключенным контролем заполнения аналитики создает новый элемент ""Комиссионное вознаграждение"".';
							|en = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.'; fa = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.';
							|it = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.';
							|pl = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.';
							|tr = '""Satılan malların maliyeti"" dağıtım seçeneğine sahip bir gider kalemi yoksa ve analitik doldurma kontrolü devre dışı bırakılmışsa, yeni ""Komisyon ücreti"" kalemi oluşturulmaktadır.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Fills in the separated data handler.
//
// Parameters:
//   Parameters - Structure - structure of handler parameters:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined Then
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Version = "11.5.26.36";
		Handler.Procedure = "ChartsOfCharacteristicTypes.ExpenseItems.CheckAddArticleCommission";
		Handler.ExecutionMode = "Seamless";
		Handler.Id = New UUID("e9f91957-88a0-41bd-b5a0-bae0dd1d5b969");
		Handler.Comment = NStr("vi = 'Khi không có dạng chi phí với phương án phân bổ ""Vào giá vốn bán hàng"" và khi tắt kiểm soát việc điền đối tượng phân tích, hệ thống sẽ tạo một phần tử mới ""Hoa hồng ký gửi"".';
								|ru = 'При отсутствии статьи расходов с вариантом распределения ""На себестоимость продаж"" и отключенным контролем заполнения аналитики создает новый элемент ""Комиссионное вознаграждение"".';
								|en = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.'; fa = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.';
								|it = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.';
								|pl = 'If there is no expense item with the ""To cost of goods sold"" allocation option and disabled dimension population control, creates a new ""Commission"" item.';
								|tr = '""Satılan malların maliyeti"" dağıtım seçeneğine sahip bir gider kalemi yoksa ve analitik doldurma kontrolü devre dışı bırakılmışsa, yeni ""Komisyon ücreti"" kalemi oluşturulmaktadır.'");
		
		ItemsToRead = New Array;
		ItemsToRead.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.FullName());
		Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
		
		Editable1 = New Array;
		Editable1.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.FullName());
		Handler.ObjectsToChange = StrConcat(Editable1, ",");
	EndIf;
	
EndProcedure

Function ListOfDocumentsForArticlesDistributedForSale()
	
	ReturnList_ = New ValueList;
	
	ReturnList_.Add(Metadata.Documents.CustomerInvoice,, True);
	ReturnList_.Add(Metadata.Documents.CustomerInvoiceServices,, True);
	ReturnList_.Add(Metadata.Documents.GoodsShipmentToCustomer,, GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5"));
	ReturnList_.Add(Metadata.Documents.SalesOrder,, GetFunctionalOption("UseSalesOrders"));
	ReturnList_.Add(Metadata.Documents.MaterialProviderOrder2_5,, GetFunctionalOption("UseMaterialProviderOrder2_5"));
	Return ReturnList_;
	
EndFunction

// Adds a commission article if no article with the required settings is found.
//
// Parameters:
//   Parameters - Structure - structure of handler parameters:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure CheckAddArticleCommission(Parameters = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ExpenseItems.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|	AND ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|	AND ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|	AND NOT ExpenseItems.ControlDimensionFilling
	|	AND NOT ExpenseItems.DeletionMark";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Item = CreateItem();
		Item.Description = NStr("vi = 'Hoa hồng ký gửi';
								|ru = 'Комиссионное вознаграждение';
								|en = 'Commission'; fa = 'کارمزد';
								|it = 'Commissione';
								|pl = 'Wynagrodzenie komisowe';
								|tr = 'Komisyon ücretlendirmesi'");
		Item.ExpensesOccur = Enums.ExpenseTypes.SalesOfGoods;
		Item.ValueType = New TypeDescription("CatalogRef.Partners");
		Item.CostAllocationRuleToCostOfGoodsSoldMan =
			Enums.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity;
		Item.CostAllocationRuleToCostOfGoodsSoldLocal =
			Enums.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity;
		Item.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostOfGoodsSold;
		Item.ExpenseTypeCategory = Enums.ExpenseActivityTypes.CoreActivity;
		Item.SetNewCode();
		AddItemToExpenseItem(Item);
		InfobaseUpdate.WriteData(Item);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
