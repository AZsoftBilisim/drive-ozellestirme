////////////////////////////////////////////////////////////////////////////////
// Report Options - UT Report Form (Server call, redefined)
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called from module Thatyesterday"
//
// Parameters:
// 	ReportOptionProperties - Structure -:
// 	 *ObjectKey - String - 
// 	 *VariantKey - String - 
// Returns:
// 	DataCompositionSettingsComposer, Undefined - LongDesc
Function ReportVariantSettingsComposer(ReportOptionProperties) Export
	
	DCSReport = Common.ObjectManagerByFullName(ReportOptionProperties.ObjectKey).GetTemplate("MainDataCompositionSchema");
	RequiredVersionOfReport = DCSReport.SettingVariants.Find(ReportOptionProperties.VariantKey);
	
	If RequiredVersionOfReport <> Undefined Then
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.LoadSettings(RequiredVersionOfReport.Settings);
		Return SettingsComposer;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Generates decryption parameters for the report 'Products with existing certificates'.
// 
// Parameters:
//	Details - Arbitrary - the value of the decoding point, series, or chart value.
//	ExplanationAddress - String - Decryption address
//
// Returns:
//	Structure - Generate Decryption Data:
//		* ProductKind - CatalogRef.ItemKinds - the value of the item type.
//		* Products - CatalogRef.Products - the value of the item field.
//		* Characteristic - CatalogRef.ItemsCharacteristics - the value of the item characteristics field.
//		* Series - CatalogRef.ItemsBatches - the value of the item batch field.
//		* CertificateType - String - the value of the certificate type.
//
Function GenerateDecryptionData(Details, ExplanationAddress) Export
	
	DetailsData = GetFromTempStorage(ExplanationAddress); // DataCompositionDetailsData -
	
	DetailsParameters = New Structure;
	DetailsParameters.Insert("ProductKind",	Catalogs.ItemKinds.EmptyRef());
	DetailsParameters.Insert("Products",		Catalogs.Products.EmptyRef());
	DetailsParameters.Insert("Characteristic",		Catalogs.ItemsCharacteristics.EmptyRef());
	DetailsParameters.Insert("Series",				Catalogs.ItemsBatches.EmptyRef());
	DetailsParameters.Insert("CertificateType",		"");
	
	GetFieldValues(DetailsParameters, DetailsData.Items, Details);
	
	SelectedField = DetailsData.Items[Details];
	
	If TypeOf(SelectedField) <> Type("DataCompositionGroupDetailsItem") Then
		For Each Field In SelectedField.GetFields() Do
			If TypeOf(Field) = Type("DataCompositionDetailsFieldValue") Then
				DetailsParameters.Insert(StrReplace(Field.Field, ".", ""), Field.Value);
				
				If Field.Field = "Series" Then
					GetFieldValue(DetailsParameters, DetailsData.Items[Details - 1]);
				ElsIf Field.Field = "Characteristic" Then
					GetFieldValue(DetailsParameters, DetailsData.Items[Details +1 ]);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(DetailsParameters.Products) Then
		DetailsParameters.ProductKind = Common.ObjectAttributeValue(
												DetailsParameters.Products,
												"ProductKind");
	EndIf;
	
	Return DetailsParameters;
	
EndFunction

// Called for the "Management Balance" report returns parameters for opening the context menu
// with a list of transcript reports
// 
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer
//  Details - DataCompositionDetailsData
//  ExplanationAddress - String
// 
// Returns:
//  Structure - Settings For Decoding An Asset Liability Article:
// * Factor - ChartOfCharacteristicTypesRef.AssetLiabilityItems
// * TrialBalanceOfAssetsAndLiabilities - Structure -:
// ** DCSParameters - Structure -:
// *** ReportPeriod - Date
// *** ReportCurrency  - CatalogRef.Currencies
// ** Filter - Structure -
// * ReportMenu - ValueList - list of settings for opening contextual reports
//
Function SettingsForDecodingAssetLiabilityArticle(SettingsComposer, Details, ExplanationAddress) Export
	
	DetailsData = GetFromTempStorage(ExplanationAddress); // DataCompositionDetailsData -
	
	DecryptionFields = New Structure;
	DecryptionFields.Insert("Factor", ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef());
	GetFieldValues(DecryptionFields, DetailsData.Items, Details);
	
	SelectedField = DetailsData.Items[Details]; 
	If TypeOf(SelectedField) <> Type("DataCompositionGroupDetailsItem") Then
		For Each Field In SelectedField.GetFields() Do
			If TypeOf(Field) = Type("DataCompositionDetailsFieldValue") Then
				DecryptionFields.Insert(StrReplace(Field.Field,".",""), Field.Value);
			EndIf;
		EndDo;
	EndIf;
	
	ReportSettings = SettingsComposer.GetSettings();

	ReportsList = New ValueList;
	#Region CommonParameters
	ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "ReportCurrency").Value;
	DCSParameters = New Structure("ReportCurrency", ReportCurrency);
	Filter = New Structure;
	DecryptionReportParameters = New Structure("DCSParameters, Filter", DCSParameters, Filter);
	DCSParameters = DecryptionReportParameters.DCSParameters;
	
	ReportPeriod = DataCompositionClientServer.GetParameter(ReportSettings, "ReportPeriod").Value;
	If DecryptionFields.Property("DynamicPeriod") Then
		Periodicity = DataCompositionClientServer.GetParameter(ReportSettings, "Periodicity").Value;
		ReportPeriod = New StandardPeriod;
		ReportPeriod.Variant = StandardPeriodVariant.Custom;
		ReportPeriod.StartDate = FinancialReportingServer.BeginOfPeriod(DecryptionFields.DynamicPeriod, Periodicity);
		ReportPeriod.EndDate = FinancialReportingServer.EndOfPeriod(DecryptionFields.DynamicPeriod, Periodicity);
	EndIf;
	NameOfPeriodParameter = "Period";
	#EndRegion

	#Region GeneralSelection
	Filter = DecryptionReportParameters.Filter;
	If DecryptionFields.Property("LineOfBusiness") Then
		FilterElement = NewElementOfSelection();
		FilterElement.LeftValue = New DataCompositionField("LineOfBusiness");
		FilterElement.RightValue = DecryptionFields.LineOfBusiness;
		Filter.Insert("LineOfBusiness", FilterElement);
		If Not ValueIsFilled(Filter.LineOfBusiness.RightValue) Then
			Filter.LineOfBusiness.ComparisonType = DataCompositionComparisonType.NotFilled;
		EndIf;
	EndIf;
	If DecryptionFields.Property("Organization") Then
		FilterElement = NewElementOfSelection();
		FilterElement.LeftValue = New DataCompositionField("Organization");
		FilterElement.RightValue = DecryptionFields.Organization;
		Filter.Insert("Organization", FilterElement);
	EndIf;
	
	FindAndAddSelection(ReportSettings.Filter, "Organization", Filter);
	FindAndAddSelection(ReportSettings.Filter, "LineOfBusiness", Filter);
	FindAndAddSelection(ReportSettings.Filter, "Department", Filter);
	SelectionOfAssetsLiabilities = Common.CopyRecursive(Filter);
	#EndRegion

#Region IndividualParametersAndSelections

	If DecryptionFields.Property("Factor") And DecryptionFields.Count() = 1 Then
		ReportsList.Add("OpenValue", NStr("vi = 'Mở giá trị';
											|ru = 'Открыть значение';
											|en = 'Open value'; fa = 'باز کردن مقدار';
											|it = 'Aprire valore';
											|pl = 'Otwórz wartość';
											|tr = 'Değeri aç'"));
		DecryptionReportParameters.Insert("ReportName", "OpenValue");
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalancePrepaymentsFromCustomerLayout")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCustomersAccountsReceivable") Then
		
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			ReportsList.Add("CustomersARAPStatement", NStr("vi = 'Bảng kê hạch toán với khách hàng';
															|ru = 'Ведомость расчетов с клиентами';
															|en = 'Customer AR/AP roll forward'; fa = 'گردش دریافتنی/پرداختنی مشتری';
															|it = 'Inventario dei conti con i clienti';
															|pl = 'Zestawienie rozliczeń z klientami';
															|tr = 'Müşterilerle mutabakat beyanı'"));
			DecryptionReportParameters.Insert("ReportName", "CustomersARAPStatement");
			DecryptionReportParameters.Insert("VariantKey", "Statement");
			// parameters of the current report
			DCSParameters.Insert("ReportData", ValueOfCalculationDataParameter(ReportCurrency));
			
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("ARAPObject.Department");
			EndIf;
			
		Else
			ReportsList.Add("CustomersARAPAccounting", NStr("vi = 'Bảng kê hạch toán với khách hàng';
															|ru = 'Ведомость расчетов с клиентами';
															|en = 'Customer AR/AP roll forward'; fa = 'گردش دریافتنی/پرداختنی مشتری';
															|it = 'Inventario dei conti con i clienti';
															|pl = 'Zestawienie rozliczeń z klientami';
															|tr = 'Müşterilerle mutabakat beyanı'"));
			DecryptionReportParameters.Insert("ReportName", "CustomersARAPAccounting");
			DecryptionReportParameters.Insert("VariantKey", "CustomersARAPAccounting");
			// parameters of the current report
			DCSParameters.Insert("SettlementsData", ValueOfCalculationDataParameter(ReportCurrency));
		
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("OrderDocument.Department");
			EndIf;
			
		EndIf;
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalancePrepaymentsToVendor_")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceVendorAccountsReceivable") Then
		
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			ReportsList.Add("VendorsARAPStatement", NStr("vi = 'Bảng kê hạch toán với nhà cung cấp';
														|ru = 'Ведомость расчетов с поставщиками';
														|en = 'Statement of vendor AR/AP'; fa = 'صورت دریافتنی/پرداختنی تأمین‌کننده';
														|it = 'Inventario dei conti con i fornitori';
														|pl = 'Zestawienie rozliczeń z dostawcami';
														|tr = 'Tedarikçilerle mutabakat beyanı'"));
			DecryptionReportParameters.Insert("ReportName", "VendorsARAPStatement");
			DecryptionReportParameters.Insert("VariantKey", "Statement");
			// parameters of the current report
			DCSParameters.Insert("ReportData", ValueOfCalculationDataParameter(ReportCurrency));
			
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("ARAPObject.Department");
			EndIf;
			
		Else
			ReportsList.Add("VendorsARAPAccounting", NStr("vi = 'Bảng kê hạch toán với nhà cung cấp';
															|ru = 'Ведомость расчетов с поставщиками';
															|en = 'Statement of vendor AR/AP'; fa = 'صورت دریافتنی/پرداختنی تأمین‌کننده';
															|it = 'Inventario dei conti con i fornitori';
															|pl = 'Zestawienie rozliczeń z dostawcami';
															|tr = 'Tedarikçilerle mutabakat beyanı'"));
			DecryptionReportParameters.Insert("ReportName", "VendorsARAPAccounting");
			DecryptionReportParameters.Insert("VariantKey", "VendorsARAPAccounting");
			// parameters of the current report
			DCSParameters.Insert("SettlementsData", ValueOfCalculationDataParameter(ReportCurrency));
			
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("OrderDocument.Department");
			EndIf;
			
		EndIf;
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceOwnCompaniesARAP") Then
		
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			ReportsList.Add("AccountsPayablesAndReceivablesByIntercompany", NStr("vi = 'Công nợ giữa các doanh nghiệp (theo bán hàng)';
																				|ru = 'Расчеты между организациями (по продажам)';
																				|en = 'Intercompany AR/AP open items (on sales)'; fa = 'اقلام باز دریافتنی/پرداختنی درون‌گروهی (در فروش)';
																				|it = 'Regolamenti tra le organizzazioni (vendite)';
																				|pl = 'Rozliczenia pomiędzy firmami (na podstawie sprzedaży)';
																				|tr = 'İş yerleri arasındaki mutabakatlar (satışlara göre)'"));
			DecryptionReportParameters.Insert("ReportName", "AccountsPayablesAndReceivablesByIntercompany");
			DecryptionReportParameters.Insert("VariantKey", "SalesPayments");
			// parameters of the current report
			DCSParameters.Insert("SettlementsData", ValueOfCalculationDataParameter(ReportCurrency));
			
			// selecting the current report
			If Filter.Property("Organization") Then
				Filter.Organization.LeftValue = New DataCompositionField("Seller");
			EndIf;
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("ARAPObject.Department");
			EndIf;
			
		Else
			ReportsList.Add("IntercompanyARAP", NStr("vi = 'Công nợ giữa các doanh nghiệp';
													|ru = 'Расчеты между организациями';
													|en = 'Intercompany AR/AP open items'; fa = 'اقلام باز دریافتنی/پرداختنی بین‌شرکتی';
													|it = 'Regolazioni dei conti tra le società';
													|pl = 'Rozliczenia między firmami';
													|tr = 'İş yerleri arasındaki ödemeler'"));
			DecryptionReportParameters.Insert("ReportName", "IntercompanyARAP");
			DecryptionReportParameters.Insert("VariantKey", "SalesPayments");
			// parameters of the current report
			DCSParameters.Insert("SettlementsData", ValueOfCalculationDataParameter(ReportCurrency));
			
			// selecting the current report
			If Filter.Property("Organization") Then
				Filter.Organization.LeftValue = New DataCompositionField("Seller");
			EndIf;
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("DocumentOfARAPAccounting.Department");
			EndIf;
		EndIf;
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceAccountsPayblesIntercompnay") Then
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			ReportsList.Add("AccountsPayablesAndReceivablesByIntercompany", NStr("vi = 'Công nợ giữa các doanh nghiệp';
																				|ru = 'Расчеты между организациями';
																				|en = 'Intercompany AR/AP open items'; fa = 'اقلام باز دریافتنی/پرداختنی بین‌شرکتی';
																				|it = 'Regolazioni dei conti tra le società';
																				|pl = 'Rozliczenia między firmami';
																				|tr = 'İş yerleri arasındaki ödemeler'"));
			DecryptionReportParameters.Insert("ReportName", "AccountsPayablesAndReceivablesByIntercompany");
			DecryptionReportParameters.Insert("VariantKey", "ProcurementPayments");
			// parameters of the current report
			DCSParameters.Insert("SettlementsData", ValueOfCalculationDataParameter(ReportCurrency));
			
			// selecting the current report
			If Filter.Property("Organization") Then
				Filter.Organization.LeftValue = New DataCompositionField("Customer");
			EndIf;
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("ARAPObject.Department");
			EndIf;
			
		Else
			ReportsList.Add("IntercompanyARAP", NStr("vi = 'Công nợ giữa các doanh nghiệp';
													|ru = 'Расчеты между организациями';
													|en = 'Intercompany AR/AP open items'; fa = 'اقلام باز دریافتنی/پرداختنی بین‌شرکتی';
													|it = 'Regolazioni dei conti tra le società';
													|pl = 'Rozliczenia między firmami';
													|tr = 'İş yerleri arasındaki ödemeler'"));
			DecryptionReportParameters.Insert("ReportName", "IntercompanyARAP");
			DecryptionReportParameters.Insert("VariantKey", "ProcurementPayments");
			// parameters of the current report
			DCSParameters.Insert("SettlementsData", ValueOfCalculationDataParameter(ReportCurrency));
			
			// selecting the current report
			If Filter.Property("Organization") Then
				Filter.Organization.LeftValue = New DataCompositionField("Customer");
			EndIf;
			If Filter.Property("Department") Then
				Filter.Department.LeftValue = New DataCompositionField("DocumentOfARAPAccounting.Department");
			EndIf;
		EndIf;
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceBankAccountCash")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCashAccountBalance")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCashInTransit") Then
		ReportsList.Add("CashStatement", NStr("vi = 'Bảng kê tiền mặt';
												|ru = 'Ведомость по денежным средствам';
												|en = 'Cash statement'; fa = 'صورت وضعیت وجه نقد';
												|it = 'Registro mezzi monetari';
												|pl = 'Zestawienie według środków pieniężnych';
												|tr = 'Nakit ekstresi'"));
		DecryptionReportParameters.Insert("ReportName", "CashStatement");
		DecryptionReportParameters.Insert("VariantKey", "CashStatement");
		NameOfPeriodParameter = "ReportPeriod";
		// parameters of the current report
		DCSParameters.Insert("ReportData", ValueOfCalculationDataParameter(ReportCurrency));
		
		// selecting the current report
		If Filter.Property("LineOfBusiness") Then
			Filter.LineOfBusiness.LeftValue = New DataCompositionField("CashStorageLocation.LineOfBusiness");
		EndIf;
		CashType_ = NewElementOfSelection();
		CashType_.LeftValue = New DataCompositionField("CashType");
		If DecryptionFields.Factor = AssetLiabilityItem("ManBalanceBankAccountCash") Then
			CashType_.RightValue = Enums.CashTypes.BankAccountPayments_;
		ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCashAccountBalance") Then
			CashType_.RightValue = Enums.CashTypes.CashPayment;
		ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCashInTransit") Then
			CashType_.RightValue = Enums.CashTypes.CashInTransit;
		EndIf;
		Filter.Insert("CashType", CashType_);
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceAdvanceHolderCash") Then
		ReportsList.Add("CashPaysheetAtAdvanceHolder",
			NStr("vi = 'Bảng kê các khoản tạm ứng';
				|ru = 'Ведомость по денежным средствам у подотчетных лиц';
				|en = 'Cash paysheet at advance holder'; fa = 'لیست پرداخت نقدی نزد تنخواه‌گردان';
				|it = 'Distinta per denaro presso soggetti responsabili';
				|pl = 'Rejestr środków pieniężnych znajdujących się u osób odpowiedzialnych';
				|tr = 'Sorumlu kişilerde nakit ekstresi'"));
		DecryptionReportParameters.Insert("ReportName", "CashPaysheetAtAdvanceHolder");
		DecryptionReportParameters.Insert("VariantKey", "CashPaysheetAtAdvanceHolder");
		NameOfPeriodParameter = "ReportPeriod";
		// parameters of the current report
		DCSParameters.Insert("ReportData", ValueOfCalculationDataParameter(ReportCurrency));
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceLoansPayables")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceDepositsInBanks")
		Or DecryptionFields.Factor = AssetLiabilityItem("IssuedBorrowings") Then
		ReportsList.Add("FinancialInstrumentsARAPStatement", NStr("vi = 'Bảng kê hạch toán các công cụ tài chính';
																	|ru = 'Ведомость расчетов по финансовым инструментам';
																	|en = 'Financial instruments AR/AP'; fa = 'دریافتنی/پرداختنی ابزارهای مالی';
																	|it = 'Inventario relativo agli strumenti finanziari';
																	|pl = 'Zestawienie obliczeń wg instrumentów finansowych';
																	|tr = 'Finansal araçlar mutabakat tablosu'"));
		DecryptionReportParameters.Insert("ReportName", "FinancialInstrumentsARAPStatement");
		DecryptionReportParameters.Insert("VariantKey", "FinancialInstrumentsARAPStatement");
		NameOfPeriodParameter = "ReportPeriod";
		If Filter.Property("LineOfBusiness") Then
			Filter.LineOfBusiness.LeftValue = New DataCompositionField("Contract.LineOfBusiness");
		EndIf;
		ContractKind = NewElementOfSelection();
		ContractKind.LeftValue = New DataCompositionField("Contract.ContractKind");
		If DecryptionFields.Factor = AssetLiabilityItem("ManBalanceLoansPayables") Then
			ContractKind.RightValue = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing;
		ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceDepositsInBanks") Then
			ContractKind.RightValue = Enums.ContractKindsOfFinancialInstruments.Deposit;
		ElsIf DecryptionFields.Factor = AssetLiabilityItem("IssuedBorrowings") Then
			ContractKind.RightValue = Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing;
		EndIf;
		Filter.Insert("ContractKind", ContractKind);
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsAtWholesaleWarehouses")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsInRetailSales")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsTransferredToCommissionAgent")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsTransferredToTolling") Then
		
		ReportsList.Add("LotList", NStr("vi = 'Giá vốn hàng hóa';
										|ru = 'Себестоимость товаров';
										|en = 'Inventory cost'; fa = 'بهای موجودی';
										|it = 'Costo di produzione dei prodotti';
										|pl = 'Koszty własne towarów';
										|tr = 'Stok maliyeti'"));
		DecryptionReportParameters.Insert("ReportName", "LotList");
		DecryptionReportParameters.Insert("VariantKey", "EnterpriseBatchList");
		// parameters of the current report
		DCSParameters.Insert("ReportData", 1);// Currency of upr. accounting with VAT
		
		// selecting the current report
		If Filter.Property("LineOfBusiness") Then
			Filter.LineOfBusiness.LeftValue = New DataCompositionField("DimensionOfProductItem.LineOfBusiness");
		EndIf;
		FilterInventoryType = NewElementOfSelection();
		FilterInventoryType.LeftValue = New DataCompositionField("InventoryOwnerAttribute.InventoryType");
		If DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsAtWholesaleWarehouses") Then
			FilterInventoryType.RightValue = Enums.InventoryTypes.OwnGoods;
			
		ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsTransferredToCommissionAgent") Then
			FilterInventoryType.RightValue = Enums.InventoryTypes.ConsignedGoods;
			
		ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsTransferredToTolling") Then
			
			FilterAccountingSection = NewElementOfSelection();
			FilterAccountingSection.LeftValue = New DataCompositionField("AccountingSection");
			FilterAccountingSection.RightValue = Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToToller;
			Filter.Insert("AccountingSection", FilterAccountingSection);
			
		EndIf;
		Filter.Insert("InventoryType", FilterInventoryType);
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceGoodsToBeRegisteredInReportsToConsignor") Then
		ReportsList.Add("StateOfSettlementsWithConsignors", NStr("vi = 'Trạng thái hạch toán với người đặt ký gửi';
																|ru = 'Состояние расчетов с комитентами';
																|en = 'Consignor AR/AP'; fa = 'دریافتنی/پرداختنی امانت‌گذار';
																|it = 'Stato dei regolamenti con i committenti';
																|pl = 'Stan rozliczeń z komitentami';
																|tr = 'Göndericiler ile uzlaşmaların durumu'"));
		DecryptionReportParameters.Insert("ReportName", "StateOfSettlementsWithConsignors");
		DecryptionReportParameters.Insert("VariantKey", "StateOfSettlementsWithConsignors");
		
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceWorkInProgress") Then
		If GetFunctionalOption("UseProductionManagement2_2") Then
			ReportsList.Add("ProductionCostsByProductionLots",
				NStr("vi = 'Chi phí theo lô hàng sản xuất';
					|ru = 'Затраты по партиям производства';
					|en = 'Costs by production lots'; fa = 'هزینه‌ها بر اساس لات‌های تولید';
					|it = 'Spese per lotti di produzione';
					|pl = 'Koszty według partii produkcji';
					|tr = 'Üretim lotlarına göre giderler'"));
			DecryptionReportParameters.Insert("ReportName", "ProductionCostsByProductionLots");
			DecryptionReportParameters.Insert("VariantKey", "DistributionOfCostsForProductionBatchesByEnterprise");
			// parameters of the current report
			DCSParameters.Insert("Cost_Data", ValueOfCalculationDataParameter(ReportCurrency));
		Else
			ReportsList.Add("CostAnalysis_", NStr("vi = 'Chi phí sản xuất';
													|ru = 'Производственные затраты';
													|en = 'Production costs'; fa = 'هزینه‌های تولید';
													|it = 'Mezzi di produzione';
													|pl = 'Koszty produkcyjne';
													|tr = 'Üretim maliyetleri'"));
			DecryptionReportParameters.Insert("ReportName", "CostAnalysis_");
			DecryptionReportParameters.Insert("VariantKey", "AnalysisOfProductionCosts");
			// parameters of the current report
			DCSParameters.Insert("ReportData", ValueOfCalculationDataParameter(ReportCurrency));
		EndIf;
	ElsIf DecryptionFields.Factor = AssetLiabilityItem("ManBalanceDeferredExpenses")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCurrentPeriodIncome")
		Or DecryptionFields.Factor = AssetLiabilityItem("ManBalanceCurrentPeriodExpenses") Then
		ReportsList.Add("ReceiptsAndExpendituresAnalysis", NStr("vi = 'Thu nhập và chi phí';
																|ru = 'Доходы и расходы';
																|en = 'Income and expenses'; fa = 'درآمدها و هزینه‌ها';
																|it = 'Ricavi e spese';
																|pl = 'Dochody i rozchody';
																|tr = 'Gelir ve giderler'"));
		DecryptionReportParameters.Insert("ReportName", "ReceiptsAndExpendituresAnalysis");
		DecryptionReportParameters.Insert("VariantKey", "IncomeAndExpensesOfEnterprise");
		
	ElsIf DecryptionFields.Factor = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef() Then
		ReportsList.Add("BalanceSheetStatementControl", NStr("vi = 'Kiểm soát bảng cân đối';
															|ru = 'Контроль баланса';
															|en = 'Balance control'; fa = 'کنترل مانده';
															|it = 'Controllo del bilancio';
															|pl = 'Kontrola bilansu';
															|tr = 'Bakiye kontrolü'"));
		DecryptionReportParameters.Insert("ReportName", "BalanceSheetStatementControl");
		DecryptionReportParameters.Insert("VariantKey", "BalanceControlContext");
		// parameters of the current report
		NameOfPeriodParameter = "ReportPeriod";
		
	Else
		ReportsList.Add("TrialBalanceOfAssetsAndLiabilities", NStr("vi = 'Thẻ tài sản/nguồn vốn';
																	|ru = 'Карточка актива/пассива';
																	|en = 'Card of asset/liability'; fa = 'کارت دارایی/بدهی';
																	|it = 'Scheda attività/passività';
																	|pl = 'Karta aktywów/zobowiązań';
																	|tr = 'Aktif/pasif kartı'"));
		FillInParametersOfAssetLiabilityCard(DecryptionReportParameters, DecryptionFields.Factor);
		NameOfPeriodParameter = "ReportPeriod";
		
	EndIf;
#EndRegion

	DCSParameters.Insert(NameOfPeriodParameter, ReportPeriod);
	DecryptionReportParameters.Insert("SettingsComposer", SettingsComposer);
	
	DecryptionReports = New Structure("Factor", DecryptionFields.Factor);
	DecryptionReports.Insert(ReportsList[0].Value, DecryptionReportParameters);
	If DecryptionReportParameters.ReportName <> "OpenValue" Then
		
		SettingsKey = "DecodingManagementBalanceSheet";
		DecryptionReportSettings = ConfigureDecryptionReport(DecryptionReportParameters);
		FillInParametersOfReportForm(DecryptionReportSettings, DecryptionReportParameters, SettingsKey);
		
		If Not (DecryptionReportParameters.ReportName = "TrialBalanceOfAssetsAndLiabilities"
			Or DecryptionReportParameters.ReportName = "BalanceSheetStatementControl") Then
			ReportsList.Add("TrialBalanceOfAssetsAndLiabilities", NStr("vi = 'Thẻ tài sản/nguồn vốn';
																		|ru = 'Карточка актива/пассива';
																		|en = 'Card of asset/liability'; fa = 'کارت دارایی/بدهی';
																		|it = 'Scheda attività/passività';
																		|pl = 'Karta aktywów/zobowiązań';
																		|tr = 'Aktif/pasif kartı'"));
			
			DCSParameters = New Structure("ReportPeriod, ReportCurrency", ReportPeriod, ReportCurrency);
			ParametersOfAssetLiabilityCard = New Structure("DCSParameters, Filter", DCSParameters, SelectionOfAssetsLiabilities);
			ParametersOfAssetLiabilityCard.Insert("SettingsComposer", SettingsComposer);
			FillInParametersOfAssetLiabilityCard(ParametersOfAssetLiabilityCard, DecryptionFields.Factor);
			
			AssetLiabilityCardSettings = ConfigureDecryptionReport(ParametersOfAssetLiabilityCard);
			FillInParametersOfReportForm(AssetLiabilityCardSettings, ParametersOfAssetLiabilityCard, SettingsKey);
			
			DecryptionReports.Insert("TrialBalanceOfAssetsAndLiabilities", ParametersOfAssetLiabilityCard);
			
		EndIf;
	EndIf;
	
	DecryptionReports.Insert("ReportMenu", ReportsList);
	Return DecryptionReports;
	
EndFunction

// Called for the reports "Application of the nomenclature series" and "Structure of the Nomenclature series"
// 
// Parameters:
//  Details - DataCompositionDetailsData
//  ExplanationAddress - String
//  
// Returns:
//  Structure - structure of decryption fields:
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * Series - CatalogRef.ItemsBatches
//
Function ParametersForDecodingReportBySeries(Details, ExplanationAddress) Export

	DetailsData = GetFromTempStorage(ExplanationAddress); // DataCompositionDetailsData -
		
	DetailsParameters = New Structure;
	DetailsParameters.Insert("Products",		Catalogs.Products.EmptyRef());
	DetailsParameters.Insert("Characteristic",		Catalogs.ItemsCharacteristics.EmptyRef());
	DetailsParameters.Insert("Series",				Catalogs.ItemsBatches.EmptyRef());
	
	NamesOfDecryptionFields = New Array;
	NamesOfDecryptionFields.Add("Products");
	NamesOfDecryptionFields.Add("Characteristic");
	NamesOfDecryptionFields.Add("Series");
	
	SelectedField = DetailsData.Items[Details];
	Id = Details;
	Boundary = DetailsData.Items.Count();
	
	While Id <> 0 Do
	
		SelectedField = DetailsData.Items[Id];
			
		If TypeOf(SelectedField) = Type("DataCompositionGroupDetailsItem") Then
			Break;
		EndIf;
		
		Id = Id - 1;
	
	EndDo;
		
	Id = Id + 1;
	
	While True Do
	
		SelectedField = DetailsData.Items[Id];
		
		If TypeOf(SelectedField) = Type("DataCompositionGroupDetailsItem") Then
			Break;
		EndIf;
		
		If TypeOf(SelectedField) = Type("DataCompositionFieldDetailsItem") Then
		
			Fields = SelectedField.GetFields();
			
			For Each Item In Fields Do
			
				If NamesOfDecryptionFields.Find(Item.Field) <> Undefined Then
					DetailsParameters.Insert(Item.Field, Item.Value);
				EndIf;
			
			EndDo;
		
		EndIf;
		
		Id = Id + 1;
		
		If Id = Boundary Then
			Break;
		EndIf;
	
	EndDo;
	
	Return DetailsParameters;

EndFunction

// This function transfers the settings of the calling report to the settings of the decryption report
//
// Parameters:
//  Parameters - Structure - containing keys:
//   *ReportName - String - Name of the decryption report metadata
//   *VariantKey - String - Name of the transcript report option
//   *SettingsComposer - DataCompositionSettingsComposer - configured linker for the calling report
//   *DCSParameters - Structure - The key - name parameter; Value - the parameter value
//   *Filter - Structure - Key - field Name; Value-element of the data collection Or structure with the same fields
//   *DecryptionFields - Structure - Key - field Name; Value - the Current value of the selected decryption field.
//
// Returns:
//   DataCompositionSettingsComposer - configured decryption report linker.
//
Function ConfigureDecryptionReport(Val Parameters) Export
	
	// Calling Report Settings
	ReportSettings = Parameters.SettingsComposer.GetSettings();
	CustomReportSettings = Parameters.SettingsComposer.UserSettings;
	
	// Settings for the decryption report
	DecryptionSettingsComposer = New DataCompositionSettingsComposer;
	SchemaName = Metadata.Reports[Parameters.ReportName].MainDataCompositionSchema.Name;
	DecryptionScheme = Reports[Parameters.ReportName].GetTemplate(SchemaName);
	OptionSettings = DecryptionScheme.SettingVariants[Parameters.VariantKey].Settings;
	DecryptionSettingsComposer.LoadSettings(OptionSettings);
	CustomDecryptionSettings = DecryptionSettingsComposer.UserSettings;
	CustomDecryptionSelection = DecryptionSettingsComposer.FixedSettings.Filter;
	For Each Item In CustomDecryptionSettings.Items Do
		If TypeOf(Item) = Type("DataCompositionFilter") Then
			CustomDecryptionSelection = Item;
		EndIf;
	EndDo;
	
	// Moving the parameters of the calling report
	For Each Item In CustomReportSettings.Items Do
		If TypeOf(Item) = Type("DataCompositionSettingsParameterValue") Then
			ParameterKey =  String(Item.Parameter);
			ParameterValue = Item.Value;
			Use = Item.Use;
			
			DecryptionReportParameter = DataCompositionClientServer.GetParameter(CustomDecryptionSettings, ParameterKey);
			If Not DecryptionReportParameter = Undefined Then
				DataCompositionClientServer.SetParameter(
					CustomDecryptionSettings, ParameterKey, ParameterValue, Use);
			EndIf;
		EndIf;// this is a parameter of the report
	EndDo;// by user settings of the calling report
	
	// Set the passed parameters
	If Parameters.Property("DCSParameters") Then
		For Each Parameter In Parameters.DCSParameters Do
			DecryptionReportParameter = DataCompositionClientServer.GetParameter(CustomDecryptionSettings, Parameter.Key);
			If Not DecryptionReportParameter = Undefined And DecryptionReportParameter.Use Then
				DataCompositionClientServer.SetParameter(CustomDecryptionSettings, Parameter.Key, Parameter.Value);
			EndIf;
		EndDo;
	EndIf;
	
	// We will transfer the selections of the calling report, except for the transmitted ones and selections by decryption fields.
	ExceptionFields = New Structure;
	// We will set the transmitted selections
	If Parameters.Property("Filter") Then
		For Each Filter In Parameters.Filter Do
			ExceptionFields.Insert(Filter.Key);
			NewFilter = CustomDecryptionSelection.Items.Add(Type("DataCompositionFilterItem"));
			FillPropertyValues(NewFilter, Filter.Value);
		EndDo;
	EndIf;
	If Parameters.Property("DecryptionFields") And ValueIsFilled(Parameters.DecryptionFields) Then
		CommonClientServer.SupplementStructure(ExceptionFields, Parameters.DecryptionFields);
	EndIf;
	FinancialReportingServer.CopyFilter(
			ReportSettings.Filter, // Source
			CustomDecryptionSelection, // Receiver
			True, // Only used
			ExceptionFields); // Exception fields
	
	// Add selections by decryption fields
	If Parameters.Property("DecryptionFields") And ValueIsFilled(Parameters.DecryptionFields) Then
		For Each Field In Parameters.DecryptionFields Do
			NewFilter = CustomDecryptionSelection.Items.Add(Type("DataCompositionFilterItem"));
			NewFilter.LeftValue = New DataCompositionField(Field.Key);
			NewFilter.RightValue = Field.Value;
		EndDo;
	EndIf;
	
	Return DecryptionSettingsComposer;
	
EndFunction

// Gets the values of all higher-level groupings
//
// Parameters:
//		FieldList - Structure - Key field name, value - value of the report grouping field-parameter to put the list of found values in
//		ItemsCollection - DataCompositionDetailsItems - collection of report decryption elements (decryption Data.Elements)
//		Id - DataCompositionDetailsID - ID of the field to decrypt.
//
Procedure GetFieldValues(FieldList, ItemsCollection, Id) Export
	
	DetailsItem = ItemsCollection[Id]; // DataCompositionFieldDetailsItem -
	ParentTranscripts = ArrayOfParentDecryptionElements(DetailsItem);
	For Each Parent In ParentTranscripts Do
		GetFieldValues(FieldList, ItemsCollection, Parent["Id"]);
		GetFieldValue(FieldList, Parent);
	EndDo;
	
EndProcedure

// Retrieves the field values of the current decryption element
//
// Parameters:
//		FieldList - Structure - Key field name, value - value of the report grouping field-parameter to put the list of found values in
//		SelectedField - DataCompositionFieldDetailsItem - the decryption element of the field you want to get.
//
Procedure GetFieldValue(FieldList, SelectedField) Export
	
	If TypeOf(SelectedField) <> Type("DataCompositionGroupDetailsItem") Then
		For Each Field In SelectedField.GetFields() Do
			If TypeOf(Field) = Type("DataCompositionDetailsFieldValue") Then
				FieldList.Insert(StrReplace(Field.Field,".",""), Field.Value);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Checks the status of the specified background task.
// 
// Parameters:
//  JobKey - String - task key
// 
// Returns:
//  Structure - Check The Background Task:
// * CancelledOrNotFound - Boolean - Flag indicating that the background task was canceled or not found by the key.
// * CompletedSuccessfully1 - Boolean - The background task has been completed successfully.
// * StillRunning - Boolean - The task is still in progress.
// * DoneWithErrors - Boolean - The task was completed with oshiki.
// * ErrorText - String - Detailed description of the background task execution error.
Function CheckBackgroundTask(Val JobKey) Export
	Result = New Structure("CancelledOrNotFound, CompletedSuccessfully1, StillRunning, DoneWithErrors, ErrorText");
	Result.Insert("CancelledOrNotFound",	False);
	Result.Insert("CompletedSuccessfully1",		False);
	Result.Insert("StillRunning",		False);
	Result.Insert("DoneWithErrors",	False);
	Result.Insert("ErrorText",			"");
	
	Filter = New Structure();
	Filter.Insert("Key", JobKey);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If ActiveTasks.Count() = 0 Then
		Result.CancelledOrNotFound = True;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Active Then
		Result.StillRunning = True;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Completed Then
		Result.CompletedSuccessfully1 = True;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Failed Then
		Result.DoneWithErrors = True;
		Result.ErrorText = DetailErrorDescription(ActiveTasks[0].ErrorInfo);
	ElsIf ActiveTasks[0].State = BackgroundJobState.Canceled Then
		Result.CancelledOrNotFound = True;
	EndIf;
	
	Return Result;
EndFunction

// Returns whether the batch calculation started when generating the report is completed.
//
// Parameters:
//	FormParameters - Structure - parameters for starting batch calculation;
//		For structure keys, see Update reportpartiesfor reports and reportclientdetermined.Restore Offline accounts.
// Returns:
//	Boolean - the sign of the end of the calculation.
Function BatchesUpdatedForReports(Val FormParameters) Export
	
	Return CostCalculationAppliedAlgorithms.BatchesUpdatedForReports(FormParameters);
	
EndFunction

// Returns the border where settlements are updated.

// The beginning of the distribution of mutual settlements.
// 
// Parameters:
//  CalculationEnd - Date
//  ArrayOfPartnerKeys - Array - Array of partner keys
//  CalculationName - String - Calculation name
//  JobNumber - Number - Task number
// 
// Returns:
//  See ARAPAllocationServerCall.StartOfCalculations
Function BeginningOfDistributionOfMutualSettlements(CalculationEnd, ArrayOfPartnerKeys, CalculationName, JobNumber) Export
	CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
	CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfPartnerKeys;
	Return ARAPAllocationServerCall.StartOfCalculations(CalculationEnd, CalculationAnalysts, CalculationName, JobNumber);
EndFunction

// Returns an array of business operations that are used in analytical registers.
//
// Parameters:
//  RegisterName  - String - the name of the register as specified in the metadata.
//
// Returns:
//   Array   - array of relevant business operations.
//
Function BusinessOperationsOfAnalyticalRegisters(RegisterName) Export
	Return DataSourcesCached.BusinessOperationsOfAnalyticalRegisters(RegisterName);
EndFunction

// Called for the report "Document formalizationmovement"
// 
// Returns:
//  Undefined, CatalogRef.MetadataObjectIDs, Arbitrary, Null, CatalogRef.ExtensionObjectIDs - The identifier of the movement of products and materials
Function IDMovementOfProductsAndMaterials() Export
	Return Common.MetadataObjectID(Type("DocumentRef.MovementOfProductsAndMaterials"));
	Return Undefined;
	
EndFunction

// Called for the report "Document formalizationmovement"
//
Procedure FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
	DecryptionProcessingParameters, FillMode, Val FiltersToGenerateControlReport = Undefined) Export
	
	ControlReport = Reports.ControlOfInventoryTransferDocumentRegistration.Create();
	ControlReport.SettingsComposer.LoadSettings(
		ControlReport.DataCompositionSchema.SettingVariants.DetailedRecords.Settings);
	SettingsComposer = ControlReport.SettingsComposer;
	DataCompositionClientServer.AddFilter(
		SettingsComposer,
		"OperationKind",
		DecryptionProcessingParameters.OperationKind,
		DataCompositionComparisonType.Equal);
	DataCompositionClientServer.AddFilter(
		SettingsComposer,
		"Recommendation",
		DecryptionProcessingParameters.Recommendation,
		DataCompositionComparisonType.Equal);
	DataCompositionClientServer.AddFilter(
		SettingsComposer,
		"Warehouse",
		DecryptionProcessingParameters.Warehouse,
		DataCompositionComparisonType.Equal);
	
	If TMCommonUse.PlatformVersionNotLowerThanSpecified("8.3.18.1208") Then
		If ValueIsFilled(FiltersToGenerateControlReport)
			And FiltersToGenerateControlReport.Count() > 0 Then
			
			AddressOfSelectionTable = PutToTempStorage(FiltersToGenerateControlReport.Unload());
			
			DataCompositionClientServer.SetParameter(ControlReport.SettingsComposer,
															"AddressOfSelectionTable",
															AddressOfSelectionTable);
			
		EndIf;
	Else
		If ValueIsFilled(FiltersToGenerateControlReport) Then
			OrGroup = DataCompositionClientServer.AddSelectionGroup(
							SettingsComposer.Settings.Filter.Items,
							DataCompositionFilterItemsGroupType.OrGroup);
			For Each Page1 In FiltersToGenerateControlReport Do
				AndGroup = DataCompositionClientServer.AddSelectionGroup(
							OrGroup.Items,
							DataCompositionFilterItemsGroupType.AndGroup);
				
				DataCompositionClientServer.AddFilter(
					AndGroup,
					"Products",
					Page1.Products,
					DataCompositionComparisonType.Equal);
				DataCompositionClientServer.AddFilter(
					AndGroup,
					"Characteristic",
					Page1.Characteristic,
					DataCompositionComparisonType.Equal);
				DataCompositionClientServer.AddFilter(
					AndGroup,
					"Series",
					Page1.Series,
					DataCompositionComparisonType.Equal);
				DataCompositionClientServer.AddFilter(
					AndGroup,
					"Warehouse",
					Page1.Warehouse,
					DataCompositionComparisonType.Equal);
				DataCompositionClientServer.AddFilter(
					AndGroup,
					"Purpose",
					Page1.Purpose,
					DataCompositionComparisonType.Equal);
			EndDo;
		EndIf;
	EndIf;
	
	If FillMode = "References" Then
		DecryptionProcessingParameters.Insert("References", ControlReport.InstructionsForRegistrationOfDocuments());
	ElsIf FillMode = "ProductAndCharacteristics" Then
		Structure = ControlReport.ProductsAndCharacteristicsForRegistrationOfDocuments();
		DecryptionProcessingParameters.Insert("ItemList", Structure.ItemList);
		DecryptionProcessingParameters.Insert("ListOfCharacteristics", Structure.ListOfCharacteristics);
	EndIf;
	
EndProcedure

// Called for the report "Document formalizationmovement"
//
// Parameters:
//     Details - String
// 
// Returns:
//     DataCompositionDetailsProcessDescription 
//
Function ParametersOfProcessingOfDecryptionControlOfRegistrationOfDocumentsOfCommodityMovement(Details) Export
	
	DecryptionProcessingParameters = Common.ValueFromXMLString(Details);
	DecryptionProcessingParameters.Insert(
		"StructureOfRecommendations", 
		Reports.ControlOfInventoryTransferDocumentRegistration.StructureOfRecommendations(DecryptionProcessingParameters.Recommendation));
	Return DecryptionProcessingParameters;

EndFunction

// Called for the "Reconciliationcounts" report
// 
// Parameters:
//  Address - String
//  Details - DataCompositionDetailsFieldValue 
// 
// Returns:
//  Structure - Get The Report Decryption Parameters:
// * OpenObject - Boolean 
// * Value - Arbitrary
//
Function GetReportDecryptionParameters(Address, Details) Export
	
	DetailsParameters = New Structure;
	ObjectData = GetFromTempStorage(Address);
	DetailsData = ObjectData.DetailsData;//DataCompositionDetailsData
	DecryptionFields = DetailsData.Items[Details].GetFields();
	If DecryptionFields.Count() > 0 And ValueIsFilled(DecryptionFields[0].Value) Then
		DetailsParameters.Insert("OpenObject", True);
		DetailsParameters.Insert("Value", DecryptionFields[0].Value);
	EndIf;
	
	Return DetailsParameters;

EndFunction

#EndRegion

#Region Private

// Returns an array of parent elements of the layout decryption.
// 
// Parameters:
// 	DetailsItem - DataCompositionFieldDetailsItem -
// 						- DataCompositionGroupDetailsItem - 
// Returns:
// 	Array of DataCompositionFieldDetailsItem, DataCompositionGroupDetailsItem -
Function ArrayOfParentDecryptionElements(DetailsItem)
	Return DetailsItem.GetParents();
EndFunction

Function NewElementOfSelection()
	
	FilterElement = New Structure("LeftValue,RightValue");
	FilterElement.Insert("Use", True);
	FilterElement.Insert("ComparisonType", DataCompositionComparisonType.Equal);
	Return FilterElement;
	
EndFunction

#Region DecryptionOfAssetLiabilityArticle

Procedure FindAndAddSelection(FilterReport_, FilterFieldName, FilterItems1)
	
	FilterElement = FinancialReportingServer.FindSelectionElement(FilterReport_, FilterFieldName);
	If FilterElement <> Undefined And FilterElement.Use Then
		NewElementOfSelection = NewElementOfSelection();
		FillPropertyValues(NewElementOfSelection, FilterElement);
		FilterItems1.Insert(FilterFieldName, NewElementOfSelection);
	EndIf;
	
EndProcedure

Function AssetLiabilityItem(ArticleName)
	
	Return ChartsOfCharacteristicTypes.AssetLiabilityItems[ArticleName];
	
EndFunction

Function ValueOfCalculationDataParameter(ReportCurrency)
	
	// parameters of the current report
	CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
	CurrencyOfComplianceAccounting = Constants.LocalAccountingCurrency.Get();
	PaymentData = ?(ReportCurrency = CurrencyOfManAccounting, 2,?(ReportCurrency = CurrencyOfComplianceAccounting, 3,1));
	Return PaymentData;
	
EndFunction

Procedure FillInParametersOfReportForm(ReportSettings, ReportParameters, SettingsKey)
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", ReportParameters.VariantKey);
	FormParameters.Insert("PurposeUseKey", SettingsKey);
	FormParameters.Insert("UserSettingsKey", SettingsKey);
	FormParameters.Insert("UserSettings", ReportSettings.UserSettings);
	FormParameters.Insert("FixedSettings", ReportSettings.FixedSettings);
	FormParameters.Insert("GenerateOnOpen", True);
	
	ReportParameters.Insert("FormParameters", FormParameters);
	
EndProcedure

Procedure FillInParametersOfAssetLiabilityCard(ReportParameters, Factor)
	
	ReportParameters.Insert("ReportName", "TrialBalanceOfAssetsAndLiabilities");
	ReportParameters.Insert("VariantKey", "AssetLiabilityCard");
	
	// selecting the current report
	FilterElement = NewElementOfSelection();
	FilterElement.LeftValue = New DataCompositionField("AssetRef");
	FilterElement.RightValue = Factor;
	If Common.ObjectAttributesValues(Factor, "IsFolder").IsFolder Then
		FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy;
	EndIf;
	ReportParameters.Filter.Insert("AssetRef", FilterElement);
	
EndProcedure

#EndRegion

#EndRegion