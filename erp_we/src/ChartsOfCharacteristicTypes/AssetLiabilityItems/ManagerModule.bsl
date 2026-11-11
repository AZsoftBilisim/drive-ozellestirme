#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of the blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("AssetLiability; AssetLiability");
	Result.Add("ValueType; ValueType");
	Result.Add("Dimension; Dimension");
	Result.Add("LedgerAccountsInEntrySettings; LedgerAccountsInEntrySettings");
	Result.Add("Kind; Kind");
	Result.Add("AllocationOfLongTermAssetsAndLiabilities; AllocationOfLongTermAssetsAndLiabilities");
	Result.Add("NotOwnedControlledValues; NotOwnedControlledValues");
	Result.Add("CurrencyAccounting; CurrencyAccounting");
	Result.Add("QuantitativeAccounting; QuantitativeAccounting");
	Result.Add("DataSource; DataSourcePresentation");
	Result.Add("Filterdata_; DataSourceSettingsSelection");
	Result.Add("SettingObjectSource; PresentationOfCustomizationObjects");
	Result.Add("SelectingConfigurationObjects; ObjectSettingsSettingsSelection");
	Result.Add("DetailedSettingsSource; PresentationOfDetailedSettings");
	Result.Add("FunctionalOptionLinks; UsageSettingsSelection");
	Result.Add("LocalResources; LocalResources");
	Result.Add("ManResources; ManResources");
	Result.Add("ShaftResources; ShaftResources");
	Result.Add("ResourcesQuantity; ResourcesQuantity");
	Result.Add("PathsToExtdimensionData; PathsToExtdimensionData");
	
	Return Result;
	
EndFunction

// The function defines the asset and liability analysis for substituting in the document for the item of assets and liabilities.
//
// Parameters:
//  AssetAndLiabilityItem - ChartOfCharacteristicTypesRef.AssetLiabilityItems - Link to the article assets and liabilities
//	Object - FormDataStructure - the current object.
//
// Returns:
//	CatalogRef - the default analytics value for assets and liabilities.
//
Function GetDefaultAssetLiabilityAnalytics(AssetAndLiabilityItem, Object) Export
	
	Article_ValueType = Common.ObjectAttributeValue(AssetAndLiabilityItem, "ValueType");
	
	TypeDescription = New TypeDescription(Article_ValueType);
	AssetsLiabilitiesDimension = TypeDescription.AdjustValue();
	
	If Article_ValueType = New TypeDescription("CatalogRef.Warehouses")
		And Object.Property("Warehouse") Then
	
		AssetsLiabilitiesDimension = Object.Warehouse;
	
	ElsIf Article_ValueType = New TypeDescription("CatalogRef.Partners")
		And Object.Property("Partner") Then
		
		AssetsLiabilitiesDimension = Object.Partner;
		
	ElsIf Article_ValueType = New TypeDescription("CatalogRef.Counterparties")
		And Object.Property("Counterparty") Then
		
		AssetsLiabilitiesDimension = Object.Counterparty;
		
	ElsIf Article_ValueType = New TypeDescription("CatalogRef.BusinessStructure")
		And Object.Property("Department") Then
		
		AssetsLiabilitiesDimension = Object.Department;
		
	ElsIf Article_ValueType = New TypeDescription("CatalogRef.BusinessStructure")
		And Object.Property("EnterpriseDivision") Then
		
		AssetsLiabilitiesDimension = Object.EnterpriseDivision;
		
	ElsIf Article_ValueType = New TypeDescription("CatalogRef.Companies")
		And Object.Property("Organization") Then
	
		AssetsLiabilitiesDimension = Object.Organization;
		
	ElsIf Article_ValueType = New TypeDescription("CatalogRef.Persons")
		And Object.Property("Individual") Then
	
		AssetsLiabilitiesDimension = Object.Individual;
		
	EndIf;
	
	Return AssetsLiabilitiesDimension;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.TrialBalanceOfAssetsAndLiabilities.AddAssetLiabilityCardCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm";
	EndIf;
	
EndProcedure

// Returns items of assets / liabilities that are not allowed to be used
//
// Returns:
// 	ValueList - List of blocked items of assets/liabilities.
//
Function BlockedItemsOfAssetsLiabilities() Export
	
	BlockedArticles = New ValueList;
	
	Return BlockedArticles;
	
EndFunction

// Called when pre-defined elements are initially filled in
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of reference book details.
//  TabularSections - Structure of KeyAndValue - data for filling in table parts.
//                                                The composition of columns corresponds to the set of details of table parts.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	MetaReferenceBooks = Metadata.Catalogs;
	MetaEnumerations = Metadata.Enums;
	MetaAccumulationRegisters = Metadata.AccumulationRegisters;
	MetaFunctionalOptions = Metadata.FunctionalOptions;
	
	AccountingDataTypes = Enums.AccountingDataTypes;
	IndicatorsOfAnalyticalRegisters = Enums.IndicatorsOfAnalyticalRegisters;
	
	FinancialExtraDimensionTypes = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes;
	
	#Region DescriptionOfManagementBalanceSheetItems

	#Region ManagementBalanceSheetItems
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManagementBalanceSheetItems";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng bảng cân đối kế toán quản trị';
																					|ru = 'Статьи управленческого баланса';
																					|en = 'Balance sheet statement items';
																					|it = 'Статьи управленческого баланса';
																					|pl = 'Balance sheet statement items';
																					|tr = 'Yönetim bakiyesi kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000067";
	Item.AddlOrderingAttribute = -1;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceNonCurrentAssets
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceNonCurrentAssets";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản dài hạn';
																					|ru = 'Внеоборотные активы';
																					|en = 'Fixed and intangible assets';
																					|it = 'Внеоборотные активы';
																					|pl = 'Środki trwałe';
																					|tr = 'Duran varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000039";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 39;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ManBalanceGroupOtherAssets
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceGroupOtherAssets";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản khác';
																					|ru = 'Прочие активы';
																					|en = 'Other assets';
																					|it = 'Прочие активы';
																					|pl = 'Inne aktywa';
																					|tr = 'Diğer varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000047";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 45;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceGroupOtherLiabilities
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceGroupOtherLiabilities";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguồn vốn khác';
																					|ru = 'Прочие пассивы';
																					|en = 'Other liabilities';
																					|it = 'Прочие пассивы';
																					|pl = 'Inne pasywa';
																					|tr = 'Diğer yükümlülükler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000048";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 47;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceAccountsReceivable
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceAccountsReceivable";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Công nợ phải thu';
																					|ru = 'Дебиторская задолженность';
																					|en = 'Accounts receivable';
																					|it = 'Дебиторская задолженность';
																					|pl = 'Wierzytelność';
																					|tr = 'Alacaklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000023";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 21;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceCash
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceCash";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền mặt, tiền gửi';
																					|ru = 'Денежные средства';
																					|en = 'Cash and bank account';
																					|it = 'Денежные средства';
																					|pl = 'Środki pieniężne';
																					|tr = 'Nakit'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 13;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceCurrentPeriodIncome
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCurrentPeriodIncome";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thu nhập của giai đoạn hiện tại';
																					|ru = 'Доходы текущего периода';
																					|en = 'Current period income';
																					|it = 'Доходы текущего периода';
																					|pl = 'Dochody bieżącego okresu';
																					|tr = 'Mevcut dönem gelirleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000042";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "CurrentPeriodIncome";
	Item.AddlOrderingAttribute = 37;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceSourcesOfFinancing
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceSourcesOfFinancing";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguồn tài chính';
																					|ru = 'Источники финансирования';
																					|en = 'Funding sources';
																					|it = 'Источники финансирования';
																					|pl = 'Źródła finansowania';
																					|tr = 'Finansman kaynakları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000038";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 1;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceAccountsPayable
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceAccountsPayable";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Công nợ phải trả';
																					|ru = 'Кредиторская задолженность';
																					|en = 'Accounts payable';
																					|it = 'Кредиторская задолженность';
																					|pl = 'Zobowiązania';
																					|tr = 'Borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000024";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 8;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceWorkInProgress
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceWorkInProgress";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Sản xuất kinh doanh chính';
																					|ru = 'Незавершенное производство';
																					|en = 'Work-in-progress';
																					|it = 'Незавершенное производство';
																					|pl = 'Produkcja niezakończona';
																					|tr = 'Devam eden imalat'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000029";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "WorkInProgress";
	Item.AddlOrderingAttribute = 34;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ProfitAndLoss
	Item = Items.Add();
	Item.PredefinedDataName = "ProfitAndLoss";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi và lỗ';
																					|ru = 'Прибыли и убытки';
																					|en = 'Profit and loss';
																					|it = 'Прибыли и убытки';
																					|pl = 'Zyski i straty';
																					|tr = 'Kâr-zarar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000016";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "ProfitAndLoss";
	Item.AddlOrderingAttribute = 38;
	Item.OutputTurnover = True;
	Item.ItemDebitPresentation = NStr("vi = 'Giá vốn và chi phí khác';
										|ru = 'Себестоимость и прочие расходы';
										|en = 'Cost and other expenses'; fa = 'Cost and other expenses';
										|it = 'Себестоимость и прочие расходы';
										|pl = 'Koszty własne i inne koszty';
										|tr = 'Maliyet ve diğer giderler'", LanguagesCodes);
	Item.PresentationOfCrBalanceOfAssetAndLiabilityItems = NStr("vi = 'Doanh thu và thu nhập khác';
																|ru = 'Выручка и прочие доходы';
																|en = 'Revenue and income'; fa = 'Revenue and income';
																|it = 'Выручка и прочие доходы';
																|pl = 'Utarg i inne dochody';
																|tr = 'Gelir ve diğer giderler'", LanguagesCodes);
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceDeferredExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceDeferredExpenses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí trả trước';
																					|ru = 'Расходы будущих периодов';
																					|en = 'Deferred expenses';
																					|it = 'Расходы будущих периодов';
																					|pl = 'Nakłady przyszłych okresów';
																					|tr = 'Gelecek dönemlerin giderleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000015";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "DeferredExpenses";
	Item.AddlOrderingAttribute = 35;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceCurrentPeriodExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCurrentPeriodExpenses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí của giai đoạn hiện tại';
																					|ru = 'Расходы текущего периода';
																					|en = 'Current period expenses';
																					|it = 'Расходы текущего периода';
																					|pl = 'Koszty bieżącego okresu';
																					|tr = 'Mevcut dönemin giderleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000014";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CurrentPeriodExpenses";
	Item.AddlOrderingAttribute = 36;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceGoods
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceGoods";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa';
																					|ru = 'Товары';
																					|en = 'Goods';
																					|it = 'Товары';
																					|pl = 'Goods';
																					|tr = 'Ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000027";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AddlOrderingAttribute = 26;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ManBalanceGoodsToBeRegisteredInReportsToConsignor
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceGoodsToBeRegisteredInReportsToConsignor";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa cần lập bảng kê dành cho người đặt ký gửi (bán hàng)';
																					|ru = 'Товары к оформлению отчетов комитенту (продажи)';
																					|en = 'Goods for consignment notifications issue (sales)';
																					|it = 'Товары к оформлению отчетов комитенту (продажи)';
																					|pl = 'Towary do sporządzenia raportów do komitenta (sprzedaż)';
																					|tr = 'Konsinye bildiriminin düzenleneceği ürünler (satışlar)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000043";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "GoodsToBeRegisteredInReportsToConsignor";
	Item.AddlOrderingAttribute = 32;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceServicesForRegistrationOfReportsToPrincipal
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceServicesForRegistrationOfReportsToPrincipal";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dịch vụ cần lập bảng kê dành cho đại lý (bán hàng)';
																					|ru = 'Услуги к оформлению отчетов принципалу (продажи)';
																					|en = 'Services to register the reports to principal (sales)';
																					|it = 'Услуги к оформлению отчетов принципалу (продажи)';
																					|pl = 'Usługi do sporządzenia raportów do zleceniodawcy (sprzedaż)';
																					|tr = 'Yöneticiye rapor düzenleme hizmetleri (satışlar)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000055";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "ServicesForRegistrationOfReportsToPrincipal";
	Item.AddlOrderingAttribute = 33;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion
	
	#Region ManBalanceTheGoodsOfWorkForPreparationOfReportsToCommitee
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceTheGoodsOfWorkForPreparationOfReportsToCommitee";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và công việc cần lập bảng kê dành cho người đặt ký gửi (mua hàng)';
																					|ru = 'Товары и работы к оформлению отчетов комитенту (закупки)';
																					|en = 'Goods and labor for consignment notifications issue (purchasing)';
																					|it = 'Товары и работы к оформлению отчетов комитенту (закупки)';
																					|pl = 'Towary i pracy do sporządzenia raportów do komitenta (zakupy)';
																					|tr = 'Konsinye bildiriminin düzenleneceği ürünler ve işler (satın almalar)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000057";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManagementBalanceSheetItems;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "TheGoodsOfWorkForPreparationOfReportsToCommitee";
	Item.AddlOrderingAttribute = 53;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion
	
	#Region ManBalanceCapitalizationOfIntangibleAssetsAndRD
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCapitalizationOfIntangibleAssetsAndRD";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.IntangibleAssets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vốn hóa TSDH và Nghiên cứu phát triển';
																					|ru = 'Капитализация НМА и НИОКР';
																					|en = 'Capitalization of intangible assets and R&D';
																					|it = 'Капитализация НМА и НИОКР';
																					|pl = 'Kapitalizacja wartości niematerialnych i prawnych oraz wydatków na R&D';
																					|tr = 'Maddi olmayan varlıkların ve Ar-Ge''nin sermayeleştirilmesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000051";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceNonCurrentAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CapitalizationOfIntangibleAssetsAndRD";
	Item.AddlOrderingAttribute = 44;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceCapitalizationOfConstructionObjects
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCapitalizationOfConstructionObjects";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ConstructionObjects"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguồn vốn các đối tượng xây dựng';
																					|ru = 'Капитализация объектов строительства';
																					|en = 'Capitalization of assets under construction';
																					|it = 'Капитализация объектов строительства';
																					|pl = 'Kapitalizacja obiektów budownictwa';
																					|tr = 'Yapım aşamasındaki varlıkların sermayeleştirilmesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000052";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceNonCurrentAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CapitalizationOfConstructionObjects";
	Item.AddlOrderingAttribute = 43;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceFixedAssetsCapitalization
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceFixedAssetsCapitalization";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vốn hóa TSCĐ hữu hình';
																					|ru = 'Капитализация ОС';
																					|en = 'Fixed assets capitalization';
																					|it = 'Капитализация ОС';
																					|pl = 'Kapitalizacja ŚT';
																					|tr = 'Sabit değerin sermayeleştirilmesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000050";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceNonCurrentAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "FixedAssetsCapitalization";
	Item.AddlOrderingAttribute = 42;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceIntangibleAssets
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceIntangibleAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.IntangibleAssets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'TSCĐ vô hình và chi phí nghiên cứu, triển khai';
																					|ru = 'Нематериальные активы и НИОКР';
																					|en = 'Intangible assets and R&D';
																					|it = 'Нематериальные активы и НИОКР';
																					|pl = 'Aktywa niematerialne i B+R';
																					|tr = 'Maddi olmayan varlıklar ve Ar-Ge'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000046";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceNonCurrentAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "IntangibleAssets";
	Item.AddlOrderingAttribute = 41;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceFixedAssets
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceFixedAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản cố định';
																					|ru = 'Основные средства';
																					|en = 'Fixed assets';
																					|it = 'Основные средства';
																					|pl = 'Środki trwałe';
																					|tr = 'Sabit kıymetler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000045";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceNonCurrentAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "FixedAssets";
	Item.AddlOrderingAttribute = 40;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ManBalanceImpairmentFA
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceImpairmentFA";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giảm giá TSCĐ hữu hình';
																					|ru = 'Обесценение ОС';
																					|en = 'Fixed asset impairment';
																					|it = 'Обесценение ОС';
																					|pl = 'Utrata wartości ŚT';
																					|tr = 'SK değer kaybı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000064";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceNonCurrentAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "ImpairmentFA";
	Item.AddlOrderingAttribute = 60;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ManBalancePrepaymentsToVendor_
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalancePrepaymentsToVendor_";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tạm ứng';
																					|ru = 'Выданные авансы';
																					|en = 'Prepayments to vendor';
																					|it = 'Выданные авансы';
																					|pl = 'Wydane zaliczki';
																					|tr = 'Verilen avanslar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000001";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsReceivable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "PrepaymentsToVendor_";
	Item.AddlOrderingAttribute = 23;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceCustomersAccountsReceivable
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCustomersAccountsReceivable";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Công nợ của khách hàng';
																					|ru = 'Задолженность клиентов';
																					|en = 'Customer AR/AP open items';
																					|it = 'Задолженность клиентов';
																					|pl = 'Zadłużenie klientów';
																					|tr = 'Müşteri borçları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000002";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsReceivable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CustomersAccountsReceivable";
	Item.AddlOrderingAttribute = 22;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceOwnCompaniesARAP
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceOwnCompaniesARAP";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ của các doanh nghiệp riêng';
																					|ru = 'Задолженность собственных организаций';
																					|en = 'Own companies AR/AP';
																					|it = 'Задолженность собственных организаций';
																					|pl = 'Zobowiązania własnych firm';
																					|tr = 'Kendi iş yerlerinin borçları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000006";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsReceivable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "OwnCompaniesARAP";
	Item.AddlOrderingAttribute = 25;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region IssuedBorrowings
	Item = Items.Add();
	Item.PredefinedDataName = "IssuedBorrowings";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Cho vay';
																					|ru = 'Займы выданные';
																					|en = 'Issued loans';
																					|it = 'Займы выданные';
																					|pl = 'Wyemitowane pożyczki';
																					|tr = 'Verilen borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000019";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsReceivable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "IssuedBorrowings";
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 24;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion

	#Region ManBalanceInvestmentInRent
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceInvestmentInRent";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đầu tư cho thuê';
																					|ru = 'Инвестиции в аренду';
																					|en = 'Rental investments';
																					|it = 'Инвестиции в аренду';
																					|pl = 'Rental investments';
																					|tr = 'Kiralama yatırımları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000066";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsReceivable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetLiability;
	Item.NameOfBudgetDataSource = "InvestmentInRent";
	Item.AddlOrderingAttribute = 62;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceCashEquivalents
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCashEquivalents";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chứng từ tài chính';
																					|ru = 'Денежные документы';
																					|en = 'Monetary documents';
																					|it = 'Денежные документы';
																					|pl = 'Pieniężne dokumenty';
																					|tr = 'Nakit belgeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000049";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CashEquivalents";
	Item.AddlOrderingAttribute = 18;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceBankAccountCash
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceBankAccountCash";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền mặt (không dùng tiền mặt)';
																					|ru = 'Денежные средства (безналичные)';
																					|en = 'Bank account';
																					|it = 'Денежные средства (безналичные)';
																					|pl = 'Środki pieniężne (bezgotówkowe)';
																					|tr = 'Banka hesabı (gayri nakdi)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000003";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "BankAccountCash";
	Item.AddlOrderingAttribute = 14;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceCashInTransit
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCashInTransit";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền đang chuyển';
																					|ru = 'Денежные средства в пути';
																					|en = 'Cash-in-transit';
																					|it = 'Денежные средства в пути';
																					|pl = 'Środki pieniężne w drodze';
																					|tr = 'Nakil halindeki para'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000028";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CashInTransit";
	Item.AddlOrderingAttribute = 20;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceCashAccountBalance
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCashAccountBalance";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vốn bằng tiền (tiền mặt)';
																					|ru = 'Денежные средства (наличные)';
																					|en = 'Cash';
																					|it = 'Денежные средства (наличные)';
																					|pl = 'Środki pieniężne (gotówka)';
																					|tr = 'Nakit varlıklar (nakit)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000004";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CashAccountBalance";
	Item.AddlOrderingAttribute = 15;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceCashLineOfBusiness
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceCashLineOfBusiness";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vốn bằng tiền (theo mảng)';
																					|ru = 'Денежные средства (в направлениях)';
																					|en = 'Cash (in directions)';
																					|it = 'Денежные средства (в направлениях)';
																					|pl = 'Środki pieniężne (w kierunkach)';
																					|tr = 'Nakit varlıklar (yönlerdeki)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000044";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "CashLineOfBusiness";
	Item.AddlOrderingAttribute = 16;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceAdvanceHolderCash
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceAdvanceHolderCash";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền ở chỗ người nhận tạm ứng';
																					|ru = 'Денежные средства (у подотчетных лиц)';
																					|en = 'Cash (of advance holders)';
																					|it = 'Денежные средства (у подотчетных лиц)';
																					|pl = 'Środki pieniężne (u osób odpowiedzialnych)';
																					|tr = 'Nakit (sorumlu kişilerdeki)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000005";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "AdvanceHolderCash";
	Item.AddlOrderingAttribute = 17;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceDepositsInBanks
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceDepositsInBanks";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền gửi (deposit) tại ngân hàng';
																					|ru = 'Депозиты в банках';
																					|en = 'Deposits in banks';
																					|it = 'Депозиты в банках';
																					|pl = 'Depozyty w bankach';
																					|tr = 'Bankalarda mevduatlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000018";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCash;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "DepositsInBanks";
	Item.AddlOrderingAttribute = 19;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceLoansPayables
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceLoansPayables";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lập tài chính cho các khoản vay và tiết kiệm';
																					|ru = 'Финансирование за счет кредитов и займов';
																					|en = 'Financing from loans';
																					|it = 'Финансирование за счет кредитов и займов';
																					|pl = 'Finansowanie kosztem kredytów i pożyczek';
																					|tr = 'Krediler ve borçlanma aracılığıyla finansman'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000017";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceSourcesOfFinancing;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "LoansPayables";
	Item.AddlOrderingAttribute = 3;
	Item.OutputTurnover = True;
	Item.ItemDebitPresentation = NStr("vi = 'Trả lại khoản vay và lãi vay';
										|ru = 'Возврат кредита и процентов';
										|en = 'Repayment of credit and interest'; fa = 'Repayment of credit and interest';
										|it = 'Возврат кредита и процентов';
										|pl = 'Spłata kredytu i odsetek';
										|tr = 'Kredi ve faiz iadesi'", LanguagesCodes);
	Item.PresentationOfCrBalanceOfAssetAndLiabilityItems = NStr("vi = 'Tín dụng và lãi suất';
																|ru = 'Кредит и начисления процентов';
																|en = 'Credit and interest accrual'; fa = 'Credit and interest accrual';
																|it = 'Кредит и начисления процентов';
																|pl = 'Kredyt i naliczenia odsetek';
																|tr = 'Kredi ve faiz tahakkuku'", LanguagesCodes);
	Item.WithoutDimension = True;
	#EndRegion
	
	#Region ManBalanceLeasing
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceLeasing";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.LeaseContract"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuê tài chính';
																					|ru = 'Лизинг';
																					|en = 'Financial lease';
																					|it = 'Лизинг';
																					|pl = 'Financial lease';
																					|tr = 'Finansal kiralama'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000033";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceSourcesOfFinancing;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetLiability;
	Item.NameOfBudgetDataSource = "Leasing";
	Item.AddlOrderingAttribute = 4;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ManBalanceOwnFunds
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ManBalanceOwnFunds";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vốn riêng';
																					|ru = 'Собственные средства';
																					|en = 'Own funds';
																					|it = 'Собственные средства';
																					|pl = 'Środki własne';
																					|tr = 'Öz kaynaklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000037";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceSourcesOfFinancing;
	Item.AddlOrderingAttribute = 5;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceTargetFinancing
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceTargetFinancing";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Mục tiêu tài chính';
																					|ru = 'Целевое финансирование';
																					|en = 'Target financing';
																					|it = 'Целевое финансирование';
																					|pl = 'Finansowanie celowe';
																					|tr = 'Hedef finansman'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000036";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceSourcesOfFinancing;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "TargetFinancing";
	Item.AddlOrderingAttribute = 2;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceVendorAccountsReceivable
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceVendorAccountsReceivable";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ phải trả nhà cung cấp';
																					|ru = 'Задолженность перед поставщиками';
																					|en = 'Debt owed to vendors';
																					|it = 'Задолженность перед поставщиками';
																					|pl = 'Zadłużenie wobec dostawców';
																					|tr = 'Tedarikçi üzerindeki borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000009";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "VendorAccountsReceivable";
	Item.AddlOrderingAttribute = 10;
	Item.OutputTurnover = True;
	Item.ItemDebitPresentation = NStr("vi = 'Thanh toán và đối trừ công nợ';
										|ru = 'Оплата и прочие взаиморасчеты';
										|en = 'Cash and AR/AP accounting'; fa = 'Cash and AR/AP accounting';
										|it = 'Оплата и прочие взаиморасчеты';
										|pl = 'Płatność i inne rozliczenia wzajemne';
										|tr = 'Ödeme ve diğer mutabakatlar'", LanguagesCodes);
	Item.PresentationOfCrBalanceOfAssetAndLiabilityItems = NStr("vi = 'Có';
																|ru = 'Кредит';
																|en = 'Credit'; fa = 'بستانکار';
																|it = 'Кредит';
																|pl = 'Credit';
																|tr = 'Alacak'", LanguagesCodes);
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceUninvoicedDeliveries
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceUninvoicedDeliveries";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giao hàng chưa có hóa đơn';
																					|ru = 'Неотфактурованные поставки';
																					|en = 'Goods received not invoiced';
																					|it = 'Неотфактурованные поставки';
																					|pl = 'Dostawy niefakturowane';
																					|tr = 'Faturasız teslimat'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000053";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "UninvoicedDeliveries";
	Item.AddlOrderingAttribute = 12;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceAccountsPayblesIntercompnay
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceAccountsPayblesIntercompnay";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ phải trả cho doanh nghiệp';
																					|ru = 'Обязательства перед собственными организациями';
																					|en = 'Intercompany liabilities';
																					|it = 'Обязательства перед собственными организациями';
																					|pl = 'Obowiązki wobec własnych firm';
																					|tr = 'Kendi iş yerlerinin üzerindeki yükümlülükler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000011";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "AccountsPayblesIntercompnay";
	Item.AddlOrderingAttribute = 11;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalancePrepaymentsFromCustomerLayout
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalancePrepaymentsFromCustomerLayout";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Ứng trước đã nhận';
																					|ru = 'Полученные авансы';
																					|en = 'Prepayments from customer';
																					|it = 'Полученные авансы';
																					|pl = 'Otrzymane zaliczki';
																					|tr = 'Alınan avanslar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "PrepaymentsFromCustomerLayout";
	Item.AddlOrderingAttribute = 9;
	Item.OutputTurnover = True;
	Item.ItemDebitPresentation = NStr("vi = 'Khấu trừ ứng trước';
										|ru = 'Зачет авансов';
										|en = 'Applying prepayments'; fa = 'اعمال پیش‌پرداخت‌ها';
										|it = 'Зачет авансов';
										|pl = 'Zaliczenie zaliczek';
										|tr = 'Avansların mahsup edilmesi'", LanguagesCodes);
	Item.PresentationOfCrBalanceOfAssetAndLiabilityItems = NStr("vi = 'Tạm ứng';
																|ru = 'Авансы';
																|en = 'Advance payments'; fa = 'پیش‌پرداخت‌ها';
																|it = 'Авансы';
																|pl = 'Advance payments';
																|tr = 'Avanslar'", LanguagesCodes);
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceDiscountingExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceDiscountingExpenses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí tính chiết khấu';
																					|ru = 'Расходы дисконтирования';
																					|en = 'Discounting expenses';
																					|it = 'Расходы дисконтирования';
																					|pl = 'Koszty dyskontowania';
																					|tr = 'İndirim giderleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000063";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayable;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "DiscountingExpenses";
	Item.AddlOrderingAttribute = 59;
	Item.OutputTurnover = True;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceOtherAssets
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceOtherAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.OtherAssetsLiabilities"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản khác';
																					|ru = 'Прочие активы';
																					|en = 'Other assets';
																					|it = 'Прочие активы';
																					|pl = 'Inne aktywa';
																					|tr = 'Diğer varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000012";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGroupOtherAssets;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "OtherAssets";
	Item.AddlOrderingAttribute = 46;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region ManBalanceDepositedSalary
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceDepositedSalary";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Persons"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền lương ký quỹ';
																					|ru = 'Депонированная зарплата';
																					|en = 'Deposited salary';
																					|it = 'Депонированная зарплата';
																					|pl = 'Wynagrodzenie zdeponowane';
																					|tr = 'Yatırılmış ücret'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000032";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGroupOtherLiabilities;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "DepositedSalary";
	Item.AddlOrderingAttribute = 50;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion

	#Region Taxes
	Item = Items.Add();
	Item.PredefinedDataName = "Taxes";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.TaxContributionKinds"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế';
																					|ru = 'Налоги';
																					|en = 'Taxes';
																					|it = 'Налоги';
																					|pl = 'Taxes';
																					|tr = 'Vergiler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000035";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGroupOtherLiabilities;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetLiability;
	Item.NameOfBudgetDataSource = "Taxes";
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = MetaReferenceBooks.TaxContributionKinds.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 49;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.Taxes);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion

	#Region Payroll
	Item = Items.Add();
	Item.PredefinedDataName = "Payroll";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả tiền lương';
																					|ru = 'Оплата труда';
																					|en = 'Payroll';
																					|it = 'Оплата труда';
																					|pl = 'Wynagrodzenie';
																					|tr = 'Aylık maaş'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGroupOtherLiabilities;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "Payroll";
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 51;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.Payroll);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	
	//++ WE
	
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.DoNotUsePayrollAndHumanResources.Name);
	FillInLinksOfFunctionalOptions(Item);
	
	//-- WE
	
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion

	#Region ManBalanceOtherLiabilities
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceOtherLiabilities";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.OtherAssetsLiabilities"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguồn vốn khác';
																					|ru = 'Прочие пассивы';
																					|en = 'Other liabilities';
																					|it = 'Прочие пассивы';
																					|pl = 'Inne pasywa';
																					|tr = 'Diğer yükümlülükler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000013";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGroupOtherLiabilities;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "OtherLiabilities";
	Item.AddlOrderingAttribute = 48;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ManBalanceLossAllowance
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceLossAllowance";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng nợ xấu';
																					|ru = 'Резервы по сомнительным долгам';
																					|en = 'Loss allowance';
																					|it = 'Резервы по сомнительным долгам';
																					|pl = 'Rezerwy z tytułu wątpliwych długów';
																					|tr = 'Şüpheli borç karşılığı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000056";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGroupOtherLiabilities;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "LossAllowance";
	Item.AddlOrderingAttribute = 52;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion
	
	#Region ManBalanceOwnFundsInvestments
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceOwnFundsInvestments";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đầu tư quỹ riêng';
																					|ru = 'Вложения собственных средств';
																					|en = 'Own funds investments';
																					|it = 'Вложения собственных средств';
																					|pl = 'Wkład środków własnych';
																					|tr = 'Öz sermaye yatırımları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFunds;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	Item.NameOfBudgetDataSource = "OwnFundsInvestments";
	Item.AddlOrderingAttribute = 6;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceOwnFundsWithdrawals
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceOwnFundsWithdrawals";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Rút quỹ riêng';
																					|ru = 'Вывод собственных средств';
																					|en = 'Own funds withdrawals';
																					|it = 'Вывод собственных средств';
																					|pl = 'Wycofanie środków własnych';
																					|tr = 'Öz sermaye çıkışı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000041";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFunds;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "OwnFundsWithdrawals";
	Item.AddlOrderingAttribute = 7;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceGoodsInTransit
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceGoodsInTransit";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng đi đường';
																					|ru = 'Товары в пути';
																					|en = 'Goods in transit';
																					|it = 'Товары в пути';
																					|pl = 'Wiersze pozycji w drodze';
																					|tr = 'Transit mallar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000054";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoods;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "GoodsInTransit";
	Item.AddlOrderingAttribute = 28;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceGoodsInRetailSales
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceGoodsInRetailSales";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Sản phẩm bán lẻ';
																					|ru = 'Товары в рознице';
																					|en = 'Retail goods';
																					|it = 'Товары в рознице';
																					|pl = 'Wiersze pozycji detaliczne';
																					|tr = 'Perakendede ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000025";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoods;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "GoodsInRetailSales";
	Item.AddlOrderingAttribute = 29;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceGoodsAtWholesaleWarehouses
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceGoodsAtWholesaleWarehouses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa trong kho sỉ';
																					|ru = 'Товары на оптовых складах';
																					|en = 'Goods at wholesale warehouses';
																					|it = 'Товары на оптовых складах';
																					|pl = 'Wiersze pozycji w hurtowniach';
																					|tr = 'Toptancı ambarlarında ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000007";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoods;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "GoodsAtWholesaleWarehouses";
	Item.AddlOrderingAttribute = 27;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceGoodsTransferredToTolling
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceGoodsTransferredToTolling";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa đã chuyển giao đi gia công';
																					|ru = 'Товары, переданные в переработку';
																					|en = 'Goods transferred to tolling';
																					|it = 'Товары, переданные в переработку';
																					|pl = 'Wiersze pozycji wydane do przeróbki';
																					|tr = 'İşlenme için transfer edilen ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000026";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoods;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "GoodsTransferredToTolling";
	Item.AddlOrderingAttribute = 31;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#Region ManBalanceGoodsTransferredToCommissionAgent
	Item = Items.Add();
	Item.PredefinedDataName = "ManBalanceGoodsTransferredToCommissionAgent";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa chuyển giao ký gửi';
																					|ru = 'Товары, переданные на комиссию';
																					|en = 'Consignment sales stock';
																					|it = 'Товары, переданные на комиссию';
																					|pl = 'Wiersze pozycji, przekazane do przeceny';
																					|tr = 'Konsinyeye transfer edilen ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000008";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoods;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.NameOfBudgetDataSource = "GoodsTransferredToCommissionAgent";
	Item.AddlOrderingAttribute = 30;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	#EndRegion

	#EndRegion // #Scope of descriptionstatecontrolling balance

	#Region DescriptionOfFinancialAccountingItems
	
	#Region FixedAssets
	#Region TheGroupSPrincipalFunds
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "FixedAssets";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản cố định';
																					|ru = 'Основные средства';
																					|en = 'Fixed assets';
																					|it = 'Основные средства';
																					|pl = 'Środki trwałe';
																					|tr = 'Sabit kıymetler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000500";
	Item.AddlOrderingAttribute = 500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	TypesOfVNA = New Array();
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.FixedAsset);
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.InvestmentProperty);
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.NonCurrentAssetsAccountingGroups.Attributes.AssetKind.Name,
		TypesOfVNA);
	
	#Region FACost
	Item = Items.Add();
	Item.PredefinedDataName = "FACost";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giá trị TSCĐ hữu hình';
																					|ru = 'Стоимость ОС';
																					|en = 'Fixed assets cost';
																					|it = 'Стоимость ОС';
																					|pl = 'Wartość środki trwałe';
																					|tr = 'Sabit kıymet maliyeti'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FixedAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FACost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "Cost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost,CostTargetFinancing", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	
	#Region FixedAssetsDepreciationCharge
	Item = Items.Add();
	Item.PredefinedDataName = "FixedAssetsDepreciationCharge";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khấu hao TSCĐ hữu hình';
																					|ru = 'Амортизация ОС';
																					|en = 'Fixed assets — Depreciation charge';
																					|it = 'Амортизация ОС';
																					|pl = 'Amortyzacja środków trwałych';
																					|tr = 'Amortisman SV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FixedAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FixedAssetsDepreciationCharge.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "Depreciation");
	AddResources(Item.LocalResources, "DepreciationLocal,FixedAssetDepreciationTargetFinancing");
	#EndRegion
	
	#Region FAImpairment
	Item = Items.Add();
	Item.PredefinedDataName = "FAImpairment";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giảm giá TSCĐ hữu hình';
																					|ru = 'Обесценение ОС';
																					|en = 'Fixed asset impairment';
																					|it = 'Обесценение ОС';
																					|pl = 'Utrata wartości ŚT';
																					|tr = 'SK değer kaybı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FixedAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.ImpairmentFA.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection("FinancialAccountingGroup.AssetKind", TypesOfVNA);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseFixedAssetImpairment.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "ImpairmenMan");
	AddResources(Item.LocalResources, "ImpairmentLocalAssets");
	#EndRegion
	
	#Region RevaluationReserveForFixedAssets
	Item = Items.Add();
	Item.PredefinedDataName = "RevaluationReserveForFixedAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng đánh giá lại giá trị TSCĐ';
																					|ru = 'Резерв переоценки стоимости ОС';
																					|en = 'Revaluation reserve of fixed assets cost';
																					|it = 'Резерв переоценки стоимости ОС';
																					|pl = 'Rezerwa przeszacowania wartości środków trwałych';
																					|tr = 'Sabit kıymet yeniden değerlemesi değer rezervi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000000540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FixedAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FACost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "CostGainMA");
	AddResources(Item.LocalResources, "CostGainLocal");
	#EndRegion
	#EndRegion
	
	#Region IntangibleAssets
	#Region GroupIntangibleAssets
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "IntangibleAssets";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản cố định vô hình';
																					|ru = 'Нематериальные активы';
																					|en = 'Intangible assets';
																					|it = 'Нематериальные активы';
																					|pl = 'Wartości niematerialne';
																					|tr = 'Maddi olmayan varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001000";
	Item.AddlOrderingAttribute = 1000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	TypesOfVNA = New Array();
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.IA);
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.RD);
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.NonCurrentAssetsAccountingGroups.Attributes.AssetKind.Name,
		TypesOfVNA);
	
	#Region IACost
	Item = Items.Add();
	Item.PredefinedDataName = "IACost";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí tài sản cố định vô hình';
																					|ru = 'Стоимость НМА';
																					|en = 'Intangible assets cost';
																					|it = 'Стоимость НМА';
																					|pl = 'Koszt wartości niematerialnych';
																					|tr = 'Maliyet GMA'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.IACost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "Cost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost,CostTargetFinancing", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	
	#Region IntangibleAssetsAmortizationCharge
	Item = Items.Add();
	Item.PredefinedDataName = "IntangibleAssetsAmortizationCharge";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khấu hao TSCĐ vô hình';
																					|ru = 'Амортизация НМА';
																					|en = 'Intangible assets — Amortization charge';
																					|it = 'Амортизация НМА';
																					|pl = 'Amortyzacja wartości niematerialnych';
																					|tr = 'Maddi olmayan varlıklar - Amortisman gideri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.IntangibleAssetsAmortizationCharge.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "Depreciation");
	AddResources(Item.LocalResources, "DepreciationLocal,FixedAssetDepreciationTargetFinancing");
	#EndRegion
	
	#Region ImpairmentIA
	Item = Items.Add();
	Item.PredefinedDataName = "ImpairmentIA";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giảm giá TSCĐ vô hình';
																					|ru = 'Обесценение НМА';
																					|en = 'Intangible asset impairment';
																					|it = 'Обесценение НМА';
																					|pl = 'Utrata wartości aktywów niematerialnych';
																					|tr = 'Maddi olmayan varlıkların değer kaybı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.ImpairmentFA.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection("FinancialAccountingGroup.AssetKind", TypesOfVNA);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseFixedAssetImpairment.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "ImpairmenMan");
	AddResources(Item.LocalResources, "ImpairmentLocalAssets");
	#EndRegion
	
	#Region RevaluationReserveForIA
	Item = Items.Add();
	Item.PredefinedDataName = "RevaluationReserveForIA";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng đánh giá lại giá trị TSCĐ vô hình';
																					|ru = 'Резерв переоценки стоимости НМА';
																					|en = 'Revaluation reserve of intangible assets cost';
																					|it = 'Резерв переоценки стоимости НМА';
																					|pl = 'Rezerwa przeszacowania kosztów wartości niematerialnych';
																					|tr = 'Maddi olmayan varlıkların yeniden değerlemesi değer rezervi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.IACost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1040;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "CostGainMA");
	AddResources(Item.LocalResources, "CostGainLocal");
	#EndRegion
	#EndRegion
	
	#Region ProvisionsForImpairment
	#Region GroupReservesForImpairment
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ProvisionsForImpairment";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng giảm giá';
																					|ru = 'Резервы под обесценение';
																					|en = 'Provisions for impairment';
																					|it = 'Резервы под обесценение';
																					|pl = 'Rezerwy pod utratę wartości';
																					|tr = 'Değer kaybının altında rezervler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001500";
	Item.AddlOrderingAttribute = 1500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ProvisionsForImpairmentOfInventory
	Item = Items.Add();
	Item.PredefinedDataName = "ProvisionsForImpairmentOfInventory";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng giảm giá vật tư';
																					|ru = 'Резервы под обесценение запасов';
																					|en = 'Provisions for impairment of inventory';
																					|it = 'Резервы под обесценение запасов';
																					|pl = 'Rezerwa pod utratę wartości zapasów';
																					|tr = 'Stok değer düşüklüğü rezervi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProvisionsForImpairment;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductStock);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransit);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.AccualInventoryImpairmentProvision.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "ProvisionForImpairmentMan");
	AddResources(Item.LocalResources, "ProvisionForImpairmentLocal");
	#EndRegion
	
	#Region ProvisionsForImpairmentOfInventoryInShopPantry
	Item = Items.Add();
	Item.PredefinedDataName = "ProvisionsForImpairmentOfInventoryInShopPantry";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng giảm giá vật tư trong kho xưởng';
																					|ru = 'Резервы под обесценение запасов в цеховой кладовой';
																					|en = 'Provisions for impairment of inventory in shop floor stockrooms';
																					|it = 'Резервы под обесценение запасов в цеховой кладовой';
																					|pl = 'Rezerwy pod utratę wartości w magazynie spiżarni';
																					|tr = 'Atölye deposunda stok değer düşüklüğü rezervi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProvisionsForImpairment;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.AccualInventoryImpairmentProvision.Name);
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "ProvisionForImpairmentMan");
	AddResources(Item.LocalResources, "ProvisionForImpairmentLocal");
	#EndRegion
	
	#Region ProvisionsForImpairmentOfWorkInProgress
	Item = Items.Add();
	Item.PredefinedDataName = "ProvisionsForImpairmentOfWorkInProgress";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng giảm giá trong sản xuất dở dang';
																					|ru = 'Резервы под обесценение незавершенного производства';
																					|en = 'Provisions for impairment of work-in-progress';
																					|it = 'Резервы под обесценение незавершенного производства';
																					|pl = 'Provisions for impairment of work-in-progress';
																					|tr = 'Devam eden imalatların değer düşüşü rezervleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProvisionsForImpairment;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	DescriptionOfDataSelection = NewDataLayoutSelection();
	OrGroup = NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		DataCompositionFilterItemsGroupType.OrGroup);
	NewDataLayoutSelectionElement(OrGroup,
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.WorkInProgress);
	AndGroup = NewDataLayoutSelectionElement(OrGroup,
		DataCompositionFilterItemsGroupType.AndGroup);
	NewDataLayoutSelectionElement(AndGroup,
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(AndGroup,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.AccualInventoryImpairmentProvision.Name);
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "ProvisionForImpairmentMan");
	AddResources(Item.LocalResources, "ProvisionForImpairmentLocal");
	#EndRegion
	
	#Region ProvisionsForImpairmentOfInventoriesTransferred
	Item = Items.Add();
	Item.PredefinedDataName = "ProvisionsForImpairmentOfInventoriesTransferred";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng giảm giá vật tư đã chuyển giao';
																					|ru = 'Резервы под обесценение запасов переданных';
																					|en = 'Provisions for impairment of transferred inventory';
																					|it = 'Резервы под обесценение запасов переданных';
																					|pl = 'Rezerwa pod utratę wartości zapasów przekazanych';
																					|tr = 'Transfer edilen stok değer düşüklüğü rezervi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000001540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProvisionsForImpairment;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 1540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToToller);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.AccualInventoryImpairmentProvision.Name);
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProductionByThirdParty2_5.Name);
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTransferToCustodyWithRightOfSale.Name);
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseSalesCommission.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "ProvisionForImpairmentMan");
	AddResources(Item.LocalResources, "ProvisionForImpairmentLocal");
	#EndRegion
	#EndRegion
	
	#Region WorkInProgress
	#Region WorkInProgressGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "WorkInProgress";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Sản xuất kinh doanh chính';
																					|ru = 'Незавершенное производство';
																					|en = 'Work-in-progress';
																					|it = 'Незавершенное производство';
																					|pl = 'Produkcja niezakończona';
																					|tr = 'Devam eden imalat'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002000";
	Item.AddlOrderingAttribute = 2000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region MaterialsInShopStorerooms
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsInShopStorerooms";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu trong kho xưởng';
																					|ru = 'Материалы в цеховых кладовых';
																					|en = 'Materials in shop floor stockrooms';
																					|it = 'Материалы в цеховых кладовых';
																					|pl = 'Materials in shop floor stockrooms';
																					|tr = 'Atölye depolarındaki malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.WorkInProgress;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region MaterialsAndWorkInBusinessUnit
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsAndWorkInBusinessUnit";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu và nhân công trong bộ phận';
																					|ru = 'Материалы и работы в подразделении';
																					|en = 'Materials and works in business unit';
																					|it = 'Materials and works in business unit';
																					|pl = 'Materials and works in business unit';
																					|tr = 'Departmandaki malzemeler ve işler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.WorkInProgress;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region MaterialsOfWorkInProgress
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsOfWorkInProgress";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu và nhân công trong sản xuất dở dang';
																					|ru = 'Материалы и работы в незавершенном производстве';
																					|en = 'Materials and works in work-in-progress';
																					|it = 'Материалы и работы в незавершенном производстве';
																					|pl = 'Materiały i prace w niezakończonej produkcji';
																					|tr = 'Devam eden imalattaki malzemeler ve işler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.WorkInProgress;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.WorkInProgress);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region LaborCostsInWorkInProgress
	Item = Items.Add();
	Item.PredefinedDataName = "LaborCostsInWorkInProgress";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí nhân công sản xuất dở dang';
																					|ru = 'Трудозатраты в незавершенном производстве';
																					|en = 'WIP labor costs';
																					|it = 'Трудозатраты в незавершенном производстве';
																					|pl = 'Nakłady pracy w niezakończonej produkcji';
																					|tr = 'Devam eden imalatta iş gücü maliyetleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.WorkInProgress;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.WIPLaborCosts.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2040;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "Cost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	
	#Region ItemizedCostsInWorkInProgress
	Item = Items.Add();
	Item.PredefinedDataName = "ItemizedCostsInWorkInProgress";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng chi phí sản xuất dở dang';
																					|ru = 'Постатейные затраты в незавершенном производстве';
																					|en = 'Itemized costs in work-in-progress';
																					|it = 'Постатейные затраты в незавершенном производстве';
																					|pl = 'Koszty według pozycji w niezakończonej produkcji';
																					|tr = 'Devam eden imalatta listelenmiş maliyetler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002050";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.WorkInProgress;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherWorkInProgressExpenses.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2050;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	#EndRegion
	
	#Region OwnInventory
	#Region OwnInventoryGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "OwnInventory";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vật tư sở hữu';
																					|ru = 'Запасы собственные';
																					|en = 'Own inventory';
																					|it = 'Запасы собственные';
																					|pl = 'Own inventory';
																					|tr = 'Yerel stoklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002500";
	Item.AddlOrderingAttribute = 2500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ProductsRelease
	Item = Items.Add();
	Item.PredefinedDataName = "ProductsRelease";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Xuất xưởng thành phẩm';
																					|ru = 'Выпуск продукции';
																					|en = 'Product release';
																					|it = 'Выпуск продукции';
																					|pl = 'Wyprodukowanie';
																					|tr = 'Ürün sürümü'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.ProductsRelease);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProduction.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region GoodsAndMaterialsInWarehouses
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsAndMaterialsInWarehouses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu trong kho';
																					|ru = 'Товары и материалы на складах';
																					|en = 'Goods and materials in warehouses';
																					|it = 'Товары и материалы на складах';
																					|pl = 'Goods and materials in warehouses';
																					|tr = 'Ambarlardaki ürünler ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.ProductStock);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region MaterialsTransferredForRecycling
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsTransferredForRecycling";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu được chuyển vào gia công';
																					|ru = 'Материалы переданные в переработку';
																					|en = 'Materials transferred to tolling';
																					|it = 'Материалы переданные в переработку';
																					|pl = 'Materials transferred to tolling';
																					|tr = 'Geri dönüşüme gönderilen malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToToller);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseProductionByThirdParty2_5.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region GoodsAndMaterialsInTransitFromSuppliers
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsAndMaterialsInTransitFromSuppliers";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu đi đường từ nhà cung cấp';
																					|ru = 'Товары и материалы в пути от поставщиков';
																					|en = 'Goods and materials in transit from vendors';
																					|it = 'Товары и материалы в пути от поставщиков';
																					|pl = 'Goods and materials in transit from vendors';
																					|tr = 'Tedarikçiden transit halinde mallar ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region VATOnPurchasedCommodities
	Item = Items.Add();
	Item.PredefinedDataName = "VATOnPurchasedCommodities";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT theo giá trị mua sắm';
																					|ru = 'НДС по приобретенным ценностям';
																					|en = 'VAT on acquired assets';
																					|it = 'НДС по приобретенным ценностям';
																					|pl = 'VAT on acquired assets';
																					|tr = 'Satın alınan varlıklar için KDV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002550";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VATInvoiced.Name;
	Item.SettingObjectSource = MetaEnumerations.VATTaxationTypes.FullName();
	Item.DetailedSettingsSource = MetaEnumerations.AssetKinds.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2550;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.VAT;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection("Ref", VATAccountingERP.VATActivities());
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VAT", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region ShippedGoods_
	Item = Items.Add();
	Item.PredefinedDataName = "ShippedGoods_";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng gửi đi bán';
																					|ru = 'Товары отгруженные';
																					|en = 'Shipped goods';
																					|it = 'Товары отгруженные';
																					|pl = 'Wiersze pozycji w drodze';
																					|tr = 'Sevk edilmiş mallar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002560";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2560;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransit);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "ItemsLocationAttributes.Counterparty");
	
	#EndRegion
	
	#Region GoodsMaterialsTransferredForStorage
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsMaterialsTransferredForStorage";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu được chuyển vào lưu kho';
																					|ru = 'Товары и материалы переданные на хранение';
																					|en = 'Goods and materials transferred for VMI';
																					|it = 'Товары и материалы переданные на хранение';
																					|pl = 'Goods and materials transferred for VMI';
																					|tr = 'VMI transferi halinde mallar ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002570";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2570;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTransferToCustodyWithRightOfSale.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region GoodsTransferredToCommissionAgent
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsTransferredToCommissionAgent";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa chuyển giao ký gửi';
																					|ru = 'Товары, переданные на комиссию';
																					|en = 'Consignment sales stock';
																					|it = 'Товары, переданные на комиссию';
																					|pl = 'Wiersze pozycji, przekazane do przeceny';
																					|tr = 'Konsinyeye transfer edilen ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002580";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2580;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseSalesCommission.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "ItemsLocationAttributes.Counterparty");
	
	#EndRegion
	
	#Region FixedAssetSaleWithDeferredTransferOfTitleIs
	Item = Items.Add();
	Item.PredefinedDataName = "FixedAssetSaleWithDeferredTransferOfTitleIs";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'TSCĐ đã giao';
																					|ru = 'Отгруженные ОС';
																					|en = 'Shipped fixed assets';
																					|it = 'Отгруженные ОС';
																					|pl = 'Shipped fixed assets';
																					|tr = 'Sabit Kıymet gönderimi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002590";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2590;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.FixedAssetSaleWithDeferredTransferOfTitleIs);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseNonCurrentAssets2_4.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.FixedAssets, "Dimension");
	
	#EndRegion
	
	#Region DeviationsInValueOfInventory
	Item = Items.Add();
	Item.PredefinedDataName = "DeviationsInValueOfInventory";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch trong giá trị vật tư';
																					|ru = 'Отклонения в стоимости запасов';
																					|en = 'Inventory cost variance';
																					|it = 'Отклонения в стоимости запасов';
																					|pl = 'Inventory cost variance';
																					|tr = 'Stok maliyeti farkları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002600";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.GoodsCostVariances.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2600;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	
	
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostVariancesMgmt,AddExpensesMan", 1, IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources, "CostVariancesLocal,AddExpensesLocal", 1, IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VATLocal", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddAdditionalIndicatorsOfDeviationsInCost(Item.AdditionalIndicators);
	#EndRegion
	
	#Region TransferredReturnablePackaging
	Item = Items.Add();
	Item.PredefinedDataName = "TransferredReturnablePackaging";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bao bì luân chuyển đã chuyển giao';
																					|ru = 'Переданная возвратная тара';
																					|en = 'Transferred returnable packaging';
																					|it = 'Переданная возвратная тара';
																					|pl = 'Przekazana tara zwrotna';
																					|tr = 'Transfer edilen iade edilebilir ambalaj'", LanguagesCodes); // @NStr-2
	Item.Code = "00000002610";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.OwnInventory;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.TransferredReturnablePackaging.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 2610;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ShaftResources, "Sum", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	#EndRegion
	
	#Region Cash
	#Region Group_Cash
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "Cash";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền mặt, tiền gửi';
																					|ru = 'Денежные средства';
																					|en = 'Cash and bank account';
																					|it = 'Денежные средства';
																					|pl = 'Środki pieniężne';
																					|tr = 'Nakit'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003000";
	Item.AddlOrderingAttribute = 3000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region CashInCashRegisters
	Item = Items.Add();
	Item.PredefinedDataName = "CashInCashRegisters";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền trong quỹ tiền mặt';
																					|ru = 'Денежные средства в кассах';
																					|en = 'Cash in cash accounts';
																					|it = 'Денежные средства в кассах';
																					|pl = 'Środki pieniężne-gotówka w kasach';
																					|tr = 'Kasalardaki nakit'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Cash;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.CashAccountBalance.Name;
	Item.SettingObjectSource = MetaReferenceBooks.GroupsOfFinancialAccountingOfCash.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Cash;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.GroupsOfFinancialAccountingOfCash.Attributes.CashType.Name,
		Enums.CashTypes.CashPayment);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region CashInCashRegistersCR
	Item = Items.Add();
	Item.PredefinedDataName = "CashInCashRegistersCR";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền tại quầy thu ngân';
																					|ru = 'Денежные средства в кассах ККМ';
																					|en = 'Cash in cash registers';
																					|it = 'Денежные средства в кассах ККМ';
																					|pl = 'Środki pieniężne-gotówka w kasach';
																					|tr = 'Yazar kasalardaki nakit'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Cash;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.CashInCashRegistersCR.Name;
	Item.SettingObjectSource = MetaReferenceBooks.GroupsOfFinancialAccountingOfCash.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Cash;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.GroupsOfFinancialAccountingOfCash.Attributes.CashType.Name,
		Enums.CashTypes.InCashRegisters);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseRetailSales.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	
	#Region BankAccountBalance
	Item = Items.Add();
	Item.PredefinedDataName = "BankAccountBalance";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền trong tài khoản';
																					|ru = 'Денежные средства на счетах';
																					|en = 'Bank account balance';
																					|it = 'Денежные средства на счетах';
																					|pl = 'Środki pieniężne na kontach';
																					|tr = 'Hesaplardaki nakit'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Cash;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.BankAccountCash.Name;
	Item.SettingObjectSource = MetaReferenceBooks.GroupsOfFinancialAccountingOfCash.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3040;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Cash;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.GroupsOfFinancialAccountingOfCash.Attributes.CashType.Name,
		Enums.CashTypes.BankAccountPayments_);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region CashInTransit
	Item = Items.Add();
	Item.PredefinedDataName = "CashInTransit";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền đang chuyển';
																					|ru = 'Денежные средства в пути';
																					|en = 'Cash-in-transit';
																					|it = 'Денежные средства в пути';
																					|pl = 'Środki pieniężne w drodze';
																					|tr = 'Nakil halindeki para'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003050";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Cash;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.CashInTransit.Name;
	Item.SettingObjectSource = MetaEnumerations.CashTransferKinds.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3050;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Cash;
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	#EndRegion
	
	#Region DepositsLoansLoansIssued
	#Region GroupDepositsLoansLoansIssued
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "DepositsLoansLoansIssued";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khoản tiền gửi, tín dụng và vay nợ đã chi';
																					|ru = 'Депозиты, кредиты и займы выданные';
																					|en = 'Deposits, credits and loans issued';
																					|it = 'Депозиты, кредиты и займы выданные';
																					|pl = 'Depozyty, kredyty i pożyczki wydane';
																					|tr = 'Mevduatlar, krediler ve verilen borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003500";
	Item.AddlOrderingAttribute = 3500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	NatureOfContracts = New Array();
	NatureOfContracts.Add(Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	NatureOfContracts.Add(Enums.ContractKindsOfFinancialInstruments.Deposit);
	
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.FinancialAccountingGroupsOfARAP.Attributes.DebtorsARAPAccounting.Name,
		True);
	
	#Region DepositsLoansLoansIssuedDebt
	Item = Items.Add();
	Item.PredefinedDataName = "DepositsLoansLoansIssuedDebt";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ gốc theo tiền gửi, các khoản tín dụng và khoản cho vay';
																					|ru = 'Основной долг по депозитам, кредитам и займам выданным';
																					|en = 'Principal debt on deposits, credits, and loans issued';
																					|it = 'Основной долг по депозитам, кредитам и займам выданным';
																					|pl = 'Principal debt on deposits, credits, and loans issued';
																					|tr = 'Krediler ve verilen borçlara ilişkin ana para borcu'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssued;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection("Contract.ContractKind", NatureOfContracts);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseLoanAndDepositContracts.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region DepositsLoansLoansIssuedInterest
	Item = Items.Add();
	Item.PredefinedDataName = "DepositsLoansLoansIssuedInterest";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi suất theo tiền gửi, tín dụng và các khoản cho vay';
																					|ru = 'Проценты по депозитам, кредитам и займам выданным';
																					|en = 'Interest on deposits, credits, and loans issued';
																					|it = 'Проценты по депозитам, кредитам и займам выданным';
																					|pl = 'Interest on deposits, credits, and loans issued';
																					|tr = 'Mevduat, krediler ve verilen kredilerin faizi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssued;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection("Contract.ContractKind", NatureOfContracts);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.LoanAndDepositScheduleAmountTypes.Interests);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseLoanAndDepositContracts.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region DepositsLoansLoansIssuedFee
	Item = Items.Add();
	Item.PredefinedDataName = "DepositsLoansLoansIssuedFee";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi suất theo tiền gửi, tín dụng và các khoản cho vay';
																					|ru = 'Комиссия по депозитам, кредитам и займам выданным';
																					|en = 'Commission on deposits, credits, and loans issued';
																					|it = 'Комиссия по депозитам, кредитам и займам выданным';
																					|pl = 'Commission on deposits, credits, and loans issued';
																					|tr = 'Mevduatlar, alacaklar ve borçlar için tahsil edilen komisyonlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000003530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssued;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 3530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection("Contract.ContractKind", NatureOfContracts);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.LoanAndDepositScheduleAmountTypes.Fee);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseLoanAndDepositContracts.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	#EndRegion
	
	#Region TransferToFinanceLease
	#Region GroupTransfersToFinanceLeases
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "TransferToFinanceLease";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chuyển giao cho thuê tài chính';
																					|ru = 'Передача в финансовую аренду';
																					|en = 'Transfer to financial lease';
																					|it = 'Передача в финансовую аренду';
																					|pl = 'Transfer to financial lease';
																					|tr = 'Finansal kiralamaya transfer'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004000";
	Item.AddlOrderingAttribute = 4000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	TypesOfVNA = New Array();
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.FixedAsset);
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.InvestmentProperty);
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.FixedAssetsProvidedToLessee);
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.NonCurrentAssetsAccountingGroups.Attributes.AssetKind.Name,
		TypesOfVNA);
	
	#Region RentalPayments
	Item = Items.Add();
	Item.PredefinedDataName = "RentalPayments";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thanh toán tiền thuê (thuê tài chính)';
																					|ru = 'Арендные платежи (финансовая аренда)';
																					|en = 'Rental payments (financial lease)';
																					|it = 'Арендные платежи (финансовая аренда)';
																					|pl = 'Rental payments (financial lease)';
																					|tr = 'Kira ödemeleri (finansal kiralama)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.TransferToFinanceLease;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InvestmentInRent.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "RentalPaymentsManag");
	AddResources(Item.LocalResources, "RentalPaymentsLocal");
	AddResources(Item.ShaftResources, "RentalPayments");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "Contract.Counterparty");
	
	#EndRegion
	
	#Region NonGuaranteedResidualValueFinancialLease
	Item = Items.Add();
	Item.PredefinedDataName = "NonGuaranteedResidualValueFinancialLease";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giá trị thanh lý không được đảm bảo (thuê tài chính)';
																					|ru = 'Негарантированная ликвидационная стоимость (финансовая аренда)';
																					|en = 'Non-guaranteed residual value (financial lease)';
																					|it = 'Негарантированная ликвидационная стоимость (финансовая аренда)';
																					|pl = 'Non-guaranteed residual value (financial lease)';
																					|tr = 'Garantisiz artık değer (finansal kiralama)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.TransferToFinanceLease;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InvestmentInRent.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "NonGuaranteedResidualValueManag");
	AddResources(Item.LocalResources, "NonGuaranteedResidualValueLocal");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "Contract.Counterparty");
	
	#EndRegion
	
	#Region InterestOnDiscountingRentalPaymentsFinancialLease
	Item = Items.Add();
	Item.PredefinedDataName = "InterestOnDiscountingRentalPaymentsFinancialLease";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phần trăm chiết khấu thanh toán tiền thuê (thuê tài chính)';
																					|ru = 'Проценты дисконтирования арендных платежей (финансовая аренда)';
																					|en = 'Interest on discounting rental payments (financial lease)';
																					|it = 'Проценты дисконтирования арендных платежей (финансовая аренда)';
																					|pl = 'Interest on discounting rental payments (financial lease)';
																					|tr = 'Kira ödemelerinin iskonto yüzdeleri (finansal kiralama)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.TransferToFinanceLease;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InvestmentInRent.Name;
	Item.SettingObjectSource = MetaReferenceBooks.NonCurrentAssetsAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "InterestDiscountMan");
	AddResources(Item.LocalResources, "InterestDiscountLocal");
	AddResources(Item.ShaftResources, "InterestDiscount");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "Contract.Counterparty");
	
	#EndRegion
	#EndRegion
	
	#Region VendorsARAPAccounting
	#Region GroupSettlementsWithSuppliers
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "VendorsARAPAccounting";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán với nhà cung cấp';
																					|ru = 'Расчеты с поставщиками';
																					|en = 'Vendor AR/AP';
																					|it = 'Расчеты с поставщиками';
																					|pl = 'Rozliczenia z dostawcami';
																					|tr = 'Tedarikçi mutabakatı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004500";
	Item.AddlOrderingAttribute = 4500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	DetailsOfHFCCalculations = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.Attributes;
	AttributesForSelectingCustomizationItems = New Array();
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.VendorsARAPAccounting.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.ConsignorsARAPAccounting.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.CommissionAgentsARAPAccounting.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.SettlementsWithSubcontractor.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.ProvidersARAP.Name);
	DescriptionOfSelectionOfObjectsForSettingUpCalculations = NewDataLayoutSelection();
	OrGroup = NewDataLayoutSelectionElement(
		DescriptionOfSelectionOfObjectsForSettingUpCalculations,
		DataCompositionFilterItemsGroupType.OrGroup);
	For Each AttributeForSelectingCustomizationItems In AttributesForSelectingCustomizationItems Do
		NewDataLayoutSelectionElement(OrGroup, AttributeForSelectingCustomizationItems, True);
	EndDo;
	
	#Region VendorAccountsReceivable
	Item = Items.Add();
	Item.PredefinedDataName = "VendorAccountsReceivable";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ phải trả nhà cung cấp';
																					|ru = 'Задолженность перед поставщиками';
																					|en = 'Debt owed to vendors';
																					|it = 'Задолженность перед поставщиками';
																					|pl = 'Zadłużenie wobec dostawców';
																					|tr = 'Tedarikçi üzerindeki borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VendorsARAPAccountingByDueDates.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"ARAPObject.FinancialAccountingGroup.BookingARAPAccounting",
		True,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsForSettingUpCalculations);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "ARAPMan", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.LocalResources, "DebtLocal", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.ShaftResources, "Debt", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	#EndRegion
	
	#Region PrepaymentsToVendors
	Item = Items.Add();
	Item.PredefinedDataName = "PrepaymentsToVendors";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Ứng trước cho nhà cung cấp';
																					|ru = 'Авансы, выданные поставщикам';
																					|en = 'Advances paid to vendors';
																					|it = 'Авансы, выданные поставщикам';
																					|pl = 'Zaliczki, wypłacone dostawcom';
																					|tr = 'Tedarikçilere verilen avanslar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VendorsARAPAccountingByDueDates.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"ARAPObject.FinancialAccountingGroup.BookingARAPAccounting",
		True,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsForSettingUpCalculations);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "PrepaymentMan", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	AddResources(Item.LocalResources, "PrepaymentLocal", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	AddResources(Item.ShaftResources, "Prepayment", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	#EndRegion
	
	#Region LiabilitiesForGoodsReceivedNotInvoiced
	Item = Items.Add();
	Item.PredefinedDataName = "LiabilitiesForGoodsReceivedNotInvoiced";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Công nợ theo giao dịch giao hàng không có hóa đơn (giá trị)';
																					|ru = 'Обязательства по неотфактурованным поставкам (стоимость)';
																					|en = 'Liabilities for goods received not invoiced (cost)';
																					|it = 'Обязательства по неотфактурованным поставкам (стоимость)';
																					|pl = 'Liabilities for goods received not invoiced (cost)';
																					|tr = 'Sevk edilmiş ama faturalanmamış mallar için borçlar (maliyet)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseUninvoicedDeliveries.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region LiabilitiesForUnpaidVAT
	Item = Items.Add();
	Item.PredefinedDataName = "LiabilitiesForUnpaidVAT";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Công nợ theo giao dịch giao hàng không có hóa đơn (Thuế GTGT)';
																					|ru = 'Обязательства по неотфактурованным поставкам (НДС)';
																					|en = 'Liabilities for goods received not invoiced (VAT)';
																					|it = 'Обязательства по неотфактурованным поставкам (НДС)';
																					|pl = 'Liabilities for goods received not invoiced (VAT)';
																					|tr = 'Sevk edilmiş ama faturalanmamış mallar için borçlar (KDV)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VATInvoiced.Name;
	Item.SettingObjectSource = MetaEnumerations.VATTaxationTypes.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.VAT;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.VATInvoiced.Dimensions.AssetTaxClass.Name,
		Enums.AssetKinds.UninvoicedVAT);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection("Ref", VATAccountingERP.VATActivities());
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseUninvoicedDeliveries.Name);
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VAT", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.ResourcesQuantity, "0", 0, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region TicketsBooking
	Item = Items.Add();
	Item.PredefinedDataName = "TicketsBooking";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vé và đặt chỗ';
																					|ru = 'Билеты и бронирование';
																					|en = 'Tickets and booking';
																					|it = 'Билеты и бронирование';
																					|pl = 'Bilety i rezerwacja';
																					|tr = 'Biletler ve rezervasyon'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004550";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VendorsARAPAccountingByDueDates.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4550;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"ARAPObject.FinancialAccountingGroup.BookingARAPAccounting",
		True);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		DetailsOfHFCCalculations.BookingARAPAccounting.Name,
		True);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "ARAPMan", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.LocalResources, "DebtLocal", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.ShaftResources, "Debt", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.ManResources, "PrepaymentMan", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	AddResources(Item.LocalResources, "PrepaymentLocal", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	AddResources(Item.ShaftResources, "Prepayment", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	#EndRegion
	
	#Region VATFromPrepaymentsToVendor
	Item = Items.Add();
	Item.PredefinedDataName = "VATFromPrepaymentsToVendor";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT từ khoản ứng trước đã chi';
																					|ru = 'НДС с авансов выданных';
																					|en = 'VAT from prepayments to vendor';
																					|it = 'НДС с авансов выданных';
																					|pl = 'VAT z zaliczek wydanych';
																					|tr = 'Verilen avanslara ilişkin KDV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004560";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VATPrepaymentsToVendor.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4560;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.VAT;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VAT", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region PercentagesOfDiscountingSettlements
	Item = Items.Add();
	Item.PredefinedDataName = "PercentagesOfDiscountingSettlements";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tỷ lệ phần trăm chiết khấu hạch toán';
																					|ru = 'Проценты дисконтирования расчетов';
																					|en = 'AR/AP discounting interest';
																					|it = 'Проценты дисконтирования расчетов';
																					|pl = 'AR/AP discounting interest';
																					|tr = 'Diskonto hesaplamalarının yüzdesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004570";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.DiscountInterestExpense.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4570;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsForSettingUpCalculations);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "DiscountingAmountMan");
	AddResources(Item.LocalResources, "DiscountingAmountCompl");
	AddResources(Item.ShaftResources, "DiscountingAmount");
	#EndRegion
	
	#Region ObligationsToCommiteeForGoodsSold
	Item = Items.Add();
	Item.PredefinedDataName = "ObligationsToCommiteeForGoodsSold";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ phải trả người đặt ký gửi theo dữ liệu bán hàng';
																					|ru = 'Обязательства перед комитентом по реализованным товарам';
																					|en = 'Liabilities to vendor for goods sold';
																					|it = 'Обязательства перед комитентом по реализованным товарам';
																					|pl = 'Zobowiązania przed komitentem według realizowanych towarów';
																					|tr = 'Uygulanmış ürünlere ilişkin göndericiye karşı sorumluluklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004580";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4580;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UsePurchaseCommission.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "0", 0);
	AddResources(Item.ManResources, "RevenueAmountMan");
	AddResources(Item.LocalResources, "0", 0);
	AddResources(Item.LocalResources, "RevenueAmountExclVATLocal");
	AddResources(Item.ShaftResources, "RevenueAmount");
	AddResources(Item.ResourcesQuantity, "Count");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	
	#EndRegion
	
	#Region ObligationsToPrincipalForServicesProvided
	Item = Items.Add();
	Item.PredefinedDataName = "ObligationsToPrincipalForServicesProvided";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ phải trả các chi nhánh cho dịch vụ được cung cấp';
																					|ru = 'Обязательства перед принципалом по реализованным услугам';
																					|en = 'Liabilities to principal for services provided';
																					|it = 'Обязательства перед принципалом по реализованным услугам';
																					|pl = 'Zobowiązania przed zleceniodawcami według realizowanych usług';
																					|tr = 'Uygulanmış ürünlere ilişkin müdüre karşı sorumluluklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000004590";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.VendorsARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 4590;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseAgentServiceSale.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "0", 0);
	AddResources(Item.ManResources, "RevenueAmountMan");
	AddResources(Item.LocalResources, "0", 0);
	AddResources(Item.LocalResources, "RevenueAmountExclVATLocal");
	AddResources(Item.ShaftResources, "RevenueAmount");
	AddResources(Item.ResourcesQuantity, "Count");
	#EndRegion
	#EndRegion
	
	#Region CustomersARAPAccounting
	#Region CustomerSettlementsGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "CustomersARAPAccounting";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán với khách hàng';
																					|ru = 'Расчеты с клиентами';
																					|en = 'Customer AR/AP';
																					|it = 'Расчеты с клиентами';
																					|pl = 'Rozliczenia z klientami';
																					|tr = 'Müşterilerle mutabakat'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005000";
	Item.AddlOrderingAttribute = 5000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	DetailsOfHFCCalculations = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.Attributes;
	AttributesForSelectingCustomizationItems = New Array();
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.CustomersARAPAccounting.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.CommissionAgentsARAPAccounting.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.PurchaseSettlementsWithConsignors.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.ConsignorsARAPAccounting.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.SettlementsWithSubcontractor.Name);
	AttributesForSelectingCustomizationItems.Add(DetailsOfHFCCalculations.ProvidersARAP.Name);
	DescriptionOfSelectionOfObjectsForSettingUpCalculations = NewDataLayoutSelection();
	OrGroup = NewDataLayoutSelectionElement(
		DescriptionOfSelectionOfObjectsForSettingUpCalculations,
		DataCompositionFilterItemsGroupType.OrGroup);
	For Each AttributeForSelectingCustomizationItems In AttributesForSelectingCustomizationItems Do
		NewDataLayoutSelectionElement(OrGroup, AttributeForSelectingCustomizationItems, True);
	EndDo;
	
	#Region CustomersAccountsReceivable
	Item = Items.Add();
	Item.PredefinedDataName = "CustomersAccountsReceivable";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Công nợ của khách hàng';
																					|ru = 'Задолженность клиентов';
																					|en = 'Customer AR/AP open items';
																					|it = 'Задолженность клиентов';
																					|pl = 'Zadłużenie klientów';
																					|tr = 'Müşteri borçları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.CustomersARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.CustomersARAPAccountingByDueDates.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 5010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsForSettingUpCalculations);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "ARAPMan", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.LocalResources, "DebtLocal", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	AddResources(Item.ShaftResources, "Debt", 1, IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
	#EndRegion
	
	#Region PrepaymentsFromCustomers
	Item = Items.Add();
	Item.PredefinedDataName = "PrepaymentsFromCustomers";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhận ứng trước từ khách hàng';
																					|ru = 'Авансы, полученные от клиентов';
																					|en = 'Advances received from customers';
																					|it = 'Авансы, полученные от клиентов';
																					|pl = 'Zaliczki, otrzymane od klientów';
																					|tr = 'Müşterilerden alınan avanslar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.CustomersARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.CustomersARAPAccountingByDueDates.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 5020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsForSettingUpCalculations);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "PrepaymentMan", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	AddResources(Item.LocalResources, "PrepaymentLocal", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	AddResources(Item.ShaftResources, "Prepayment", 1, IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
	#EndRegion
	
	#Region GiftCertificates
	Item = Items.Add();
	Item.PredefinedDataName = "GiftCertificates";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phiếu quà tặng';
																					|ru = 'Подарочные сертификаты';
																					|en = 'Gift cards';
																					|it = 'Подарочные сертификаты';
																					|pl = 'Certyfikaty podarunkowe';
																					|tr = 'Hediye kartları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.CustomersARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.GiftCertificates.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 5030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.LocalResources, "0", 0);
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region VATFromPrepaymentsFromCustomer
	Item = Items.Add();
	Item.PredefinedDataName = "VATFromPrepaymentsFromCustomer";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT từ khoản ứng trước đã nhận';
																					|ru = 'НДС с авансов полученных';
																					|en = 'VAT from prepayments from customer';
																					|it = 'НДС с авансов полученных';
																					|pl = 'VAT z zaliczek otrzymanych';
																					|tr = 'Alınan avanslara ilişkin KDV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.CustomersARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VATPrepaymentsFromCustomer.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 5040;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.VAT;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VAT", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region ObligationsToProcurementCommittee
	Item = Items.Add();
	Item.PredefinedDataName = "ObligationsToProcurementCommittee";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ phải trả người đặt ký gửi theo dữ liệu mua hàng';
																					|ru = 'Обязательства перед комитентом по закупкам';
																					|en = 'Liabilities to vendor for purchasing';
																					|it = 'Обязательства перед комитентом по закупкам';
																					|pl = 'Zobowiązania przed komitentem według zakupów';
																					|tr = 'Satın almaya ilişkin göndericiye karşı sorumluluklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005050";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.CustomersARAPAccounting;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 5050;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.ProvideAgentServicesOnPurchaseToPrincipals.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "0", 0);
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "0", 0);
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "AmountIncludingVAT");
	AddResources(Item.ResourcesQuantity, "Count");
	#EndRegion
	#EndRegion
	
	#Region LossAllowance
	#Region LossAllowancesForDoubtfulDebtsOfGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "LossAllowancesForDoubtfulDebtsOfGroup";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng nợ xấu';
																					|ru = 'Резервы по сомнительным долгам';
																					|en = 'Loss allowance';
																					|it = 'Резервы по сомнительным долгам';
																					|pl = 'Rezerwy z tytułu wątpliwych długów';
																					|tr = 'Şüpheli borç karşılığı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005500";
	Item.AddlOrderingAttribute = 5500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region LossAllowanceElement
	Item = Items.Add();
	Item.PredefinedDataName = "LossAllowance";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng nợ xấu';
																					|ru = 'Резервы по сомнительным долгам';
																					|en = 'Loss allowance';
																					|it = 'Резервы по сомнительным долгам';
																					|pl = 'Rezerwy z tytułu wątpliwych długów';
																					|tr = 'Şüpheli borç karşılığı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000005510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LossAllowancesForDoubtfulDebtsOfGroup;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.LossAllowance.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 5510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.ToGenerateLossAllowance.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	#EndRegion
	
	#Region LoansLoansReceived
	#Region GroupLoansLoansReceived
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "LoansLoansReceived";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khoản tín dụng và vay nợ đã nhận';
																					|ru = 'Кредиты и займы полученные';
																					|en = 'Received credits and loans';
																					|it = 'Кредиты и займы полученные';
																					|pl = 'Otrzymane kredyty i pożyczki';
																					|tr = 'Krediler ve alınan borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006000";
	Item.AddlOrderingAttribute = 6000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.FinancialAccountingGroupsOfARAP.Attributes.CreditorsARAPAccounting.Name,
		True);
	
	#Region LoansAndBorrowingsReceivedDebt
	Item = Items.Add();
	Item.PredefinedDataName = "LoansAndBorrowingsReceivedDebt";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nợ gốc về các khoản tín dụng và khoản vay';
																					|ru = 'Основной долг по кредитам и займам полученным';
																					|en = 'Principal debt on received credits and loans';
																					|it = 'Основной долг по кредитам и займам полученным';
																					|pl = 'Podstawowy dług dla otrzymanych kredytów i pożyczek';
																					|tr = 'Krediler ve alınan borçlara ilişkin anapara borcu'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LoansLoansReceived;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 6010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseLoanAndDepositContracts.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region LoansAndBorrowingsInterestReceived
	Item = Items.Add();
	Item.PredefinedDataName = "LoansAndBorrowingsInterestReceived";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi suất các khoản tín dụng và khoản vay';
																					|ru = 'Проценты по кредитам и займам полученным';
																					|en = 'Interest on received credits and loans';
																					|it = 'Проценты по кредитам и займам полученным';
																					|pl = 'Odsetki z otrzymanych kredytów i pożyczek';
																					|tr = 'Krediler ve alınan borçlara ilişkin yüzdeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LoansLoansReceived;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 6020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.LoanAndDepositScheduleAmountTypes.Interests);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseLoanAndDepositContracts.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region LoansAndBorrowingsReceivedFee
	Item = Items.Add();
	Item.PredefinedDataName = "LoansAndBorrowingsReceivedFee";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phí ngân hàng theo lãi suất và khoản vay';
																					|ru = 'Комиссия по процентам и займам полученным';
																					|en = 'Commission on received interest and loans';
																					|it = 'Комиссия по процентам и займам полученным';
																					|pl = 'Prowizja z odsetek i otrzymanych pożyczek';
																					|tr = 'Yüzde ve alınan borçlara ilişkin komisyon'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LoansLoansReceived;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 6030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.LoanAndDepositScheduleAmountTypes.Fee);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseLoanAndDepositContracts.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	#EndRegion
	
	#Region FiscalSettlements
	#Region GroupTaxCalculations
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "FiscalSettlements";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán theo thuế GTGT';
																					|ru = 'Расчеты по налогам';
																					|en = 'Tax AR/AP accounting';
																					|it = 'Расчеты по налогам';
																					|pl = 'Tax AR/AP accounting';
																					|tr = 'Vergi alacak/borç muhasebesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006500";
	Item.AddlOrderingAttribute = 6500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region VATAccountsPayable
	Item = Items.Add();
	Item.PredefinedDataName = "VATAccountsPayable";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán theo thuế GTGT';
																					|ru = 'Расчеты по НДС';
																					|en = 'VAT AR/AP accounting';
																					|it = 'Расчеты по НДС';
																					|pl = 'Rozliczenia z tytułu VAT';
																					|tr = 'KDV''ye ilişkin hesaplamalar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FiscalSettlements;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.VATRegisterRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 6510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.VAT;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VAT", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region ARAPAccountingByExcises
	Item = Items.Add();
	Item.PredefinedDataName = "ARAPAccountingByExcises";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán theo thuế tiêu thụ đặc biệt';
																					|ru = 'Расчеты по акцизам';
																					|en = 'AR/AP accounting by excises';
																					|it = 'AR/AP accounting by excises';
																					|pl = 'AR/AP accounting by excises';
																					|tr = 'Tüketim vergisi hesaplamaları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000006520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FiscalSettlements;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RegisterRecordsByExcises.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 6520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseExcisableGoods.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "ExciseAmountInCurrencyMgmt", 1, IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources, "ExciseAmountInCurrencyLocal", 1, IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddAdditionalIndicatorsForExciseCalculations(Item.AdditionalIndicators);
	#EndRegion
	#EndRegion
	
	#Region SettlementsWithEmployees
	#Region GroupSettlementsWithEmployees
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "SettlementsWithEmployees";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán với nhân viên';
																					|ru = 'Расчеты с сотрудниками';
																					|en = 'AR/AP accounting for employees';
																					|it = 'Расчеты с сотрудниками';
																					|pl = 'Rozliczenia z pracownikami';
																					|tr = 'Çalışanlar ile mutabakat'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007000";
	Item.AddlOrderingAttribute = 7000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	//++ WE
	
	#Region Payroll_
	Item = Items.Add();
	Item.PredefinedDataName = "Payroll_";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả tiền lương';
																					|ru = 'Оплата труда';
																					|en = 'Payroll';
																					|it = 'Оплата труда';
																					|pl = 'Wynagrodzenie';
																					|tr = 'Aylık maaş'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.SettlementsWithEmployees;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.PayrollCalculationsHR.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.PayrollAndHumanResourcesWE.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion
	
	//-- WE
	
	#Region AdvanceHoldersARAPAccounting
	Item = Items.Add();
	Item.PredefinedDataName = "AdvanceHoldersARAPAccounting";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán với người nhận tạm ứng';
																					|ru = 'Расчеты с подотчетными лицами';
																					|en = 'AR/AP accounting for advance holders';
																					|it = 'Расчеты с подотчетными лицами';
																					|pl = 'Rozliczenia z zaliczkobiorcami';
																					|tr = 'Sorumlu kişilere ilişkin hesaplamalar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.SettlementsWithEmployees;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.AdvanceHolderCash.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Cash;
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	#EndRegion
	
	#Region LeaseContractARAPWithLessors
	#Region GroupSettlementsWithLessors
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "LeaseContractARAPWithLessors";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán với bên cho thuê';
																					|ru = 'Расчеты с арендодателями';
																					|en = 'Lessors AR/AP';
																					|it = 'Расчеты с арендодателями';
																					|pl = 'Rozliczenia z wynajemcami';
																					|tr = 'Mülk sahipleriyle mutabakat'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007500";
	Item.AddlOrderingAttribute = 7500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.FinancialAccountingGroupsOfARAP.Attributes.LeaseContractARAPWithLessors.Name,
		True);
	
	#Region LeaseObligations
	Item = Items.Add();
	Item.PredefinedDataName = "LeaseObligations";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nghĩa vụ cho thuê';
																					|ru = 'Арендные обязательства';
																					|en = 'Rental obligations';
																					|it = 'Арендные обязательства';
																					|pl = 'Zobowiązania dzierżawne';
																					|tr = 'Kiralama yükümlülükleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.LeaseObligations);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region RentalServices
	Item = Items.Add();
	Item.PredefinedDataName = "RentalServices";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dịch vụ thuê';
																					|ru = 'Услуги по аренде';
																					|en = 'Rental services';
																					|it = 'Услуги по аренде';
																					|pl = 'Usługi dotyczące dzierżawy';
																					|tr = 'Kiralama hizmetleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.RentalService);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region AdvancePaymentForRentalServices
	Item = Items.Add();
	Item.PredefinedDataName = "AdvancePaymentForRentalServices";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trả trước tiền thuê dịch vụ';
																					|ru = 'Аванс за услуги по аренде';
																					|en = 'Prepayment for rental services';
																					|it = 'Аванс за услуги по аренде';
																					|pl = 'Prepayment for rental services';
																					|tr = 'Kira hizmet ön ödemesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.RentalServicePrepayment);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region SecurityPaymentForLease
	Item = Items.Add();
	Item.PredefinedDataName = "SecurityPaymentForLease";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thanh toán đảm bảo tiền thuê';
																					|ru = 'Обеспечительный платеж по аренде';
																					|en = 'Rental security deposit';
																					|it = 'Обеспечительный платеж по аренде';
																					|pl = 'Płatność zabezpieczająca z tytułu dzierżawy';
																					|tr = 'Kira güvence ödemesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.DepositPayment);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region RedemptionOfRentalItem
	Item = Items.Add();
	Item.PredefinedDataName = "RedemptionOfRentalItem";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Mua lại đối tượng thuê';
																					|ru = 'Выкуп предмета аренды';
																					|en = 'Rental object redemption';
																					|it = 'Выкуп предмета аренды';
																					|pl = 'Wykup przedmiotu dzierżawy';
																					|tr = 'Kiralanan varlığın itfası'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007550";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7550;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.BuyoutValue);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region AdvancePaymentForPurchaseOfRentalItem
	Item = Items.Add();
	Item.PredefinedDataName = "AdvancePaymentForPurchaseOfRentalItem";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Ứng trước để mua lại đối tượng thuê';
																					|ru = 'Аванс за выкуп предмета аренды';
																					|en = 'Prepayment for rental object redemption';
																					|it = 'Аванс за выкуп предмета аренды';
																					|pl = 'Zaliczka za wykup przedmiotu dzierżawy';
																					|tr = 'Kiralanan varlığı satın almanın avansı'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007560";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7560;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region RentalInterest
	Item = Items.Add();
	Item.PredefinedDataName = "RentalInterest";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi tiền thuê';
																					|ru = 'Проценты по аренде';
																					|en = 'Rental interest';
																					|it = 'Проценты по аренде';
																					|pl = 'Odsetki z tytułu dzierżawy';
																					|tr = 'Kiraya ilişkin yüzde'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007570";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7570;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.Interests);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	AddResources(Item.ShaftResources, "Sum");
	#EndRegion
	
	#Region VATForLease
	Item = Items.Add();
	Item.PredefinedDataName = "VATForLease";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT tiền thuê';
																					|ru = 'НДС по аренде';
																					|en = 'Rental VAT';
																					|it = 'НДС по аренде';
																					|pl = 'VAT z dzierżawy';
																					|tr = 'Kiraya ilişkin KDV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000007580";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.LeaseContractARAPWithLessors;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = True;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FinancialInstrumentsARAP.Name;
	Item.SettingObjectSource = MetaReferenceBooks.FinancialAccountingGroupsOfARAP.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 7580;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		"Contract.ContractKind",
		Enums.ContractKindsOfFinancialInstruments.Lease);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.FinancialInstrumentsARAP.Dimensions.AmountType.Name,
		Enums.TypesOfLeasePayments.VAT);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	AddResources(Item.ManResources, "SumMan", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "SumCompl", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.ShaftResources, "Sum", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	#EndRegion
	
	#Region BranchOfficeAccounting
	#Region OnFarmSettlementsGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "BranchOfficeAccounting";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán nội bộ';
																					|ru = 'Внутрихозяйственные расчеты';
																					|en = 'Interbranch AR/AP';
																					|it = 'Внутрихозяйственные расчеты';
																					|pl = 'Rozliczenia wewnątrzgospodarcze';
																					|tr = 'İç ticaret hesapları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008000";
	Item.AddlOrderingAttribute = 8000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region BranchOfficeAssetsARAPAccounting
	Item = Items.Add();
	Item.PredefinedDataName = "BranchOfficeAssetsARAPAccounting";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán nội bộ theo tài sản được chọn';
																					|ru = 'Внутрихозяйственные расчеты по выделенному имуществу';
																					|en = 'Interbranch AR/AP for allocated property';
																					|it = 'Внутрихозяйственные расчеты по выделенному имуществу';
																					|pl = 'Rozliczenia wewnątrzgospodarcze według wydzielonego majątku';
																					|tr = 'Seçili mülke ilişkin iç ticaret hesapları'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAccounting;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetLiability;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseBranchOfficesWithSeparateBalanceSheets.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "Dimension");
	
	#EndRegion
	
	#Region BranchOfficeARAPAccounting
	Item = Items.Add();
	Item.PredefinedDataName = "BranchOfficeARAPAccounting";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán nội bộ theo các giao dịch hiện tại';
																					|ru = 'Внутрихозяйственные расчеты по текущим операциям';
																					|en = 'Interbranch AR/AP for current transactions';
																					|it = 'Внутрихозяйственные расчеты по текущим операциям';
																					|pl = 'Interbranch AR/AP for current transactions';
																					|tr = 'Mevcut işlemler için şubeler arası Alacak/Borçlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAccounting;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetLiability;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseBranchOfficesWithSeparateBalanceSheets.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "Dimension");
	
	#EndRegion
	#EndRegion
	
	#Region Sales
	#Region SalesGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "Sales";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bán hàng';
																					|ru = 'Продажи';
																					|en = 'Sales';
																					|it = 'Продажи';
																					|pl = 'Sales';
																					|tr = 'Satışlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008500";
	Item.AddlOrderingAttribute = 8500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	ExcludedTypesOfStocks = New Array();
	ExcludedTypesOfStocks.Add(Enums.InventoryTypes.ConsignedGoods);
	ExcludedTypesOfStocks.Add(Enums.InventoryTypes.AgentService);
	
	#Region SalesRevenue
	Item = Items.Add();
	Item.PredefinedDataName = "SalesRevenue";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Doanh thu bán hàng';
																					|ru = 'Выручка от продаж';
																					|en = 'Sales revenue';
																					|it = 'Выручка от продаж';
																					|pl = 'Przychód ze sprzedaży';
																					|tr = 'Satış geliri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Income_2;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueAndCOGS.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.RevenueAndCOGS.Dimensions.InventoryType.Name,
		ExcludedTypesOfStocks,
		DataCompositionComparisonType.NotInList);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "RevenueAmountExcludingVAT", 1, IndicatorsOfAnalyticalRegisters.AmountExcludingVAT);
	AddResources(Item.LocalResources, "RevenueAmountExclVATLocal", 1, IndicatorsOfAnalyticalRegisters.AmountExcludingVAT);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.AmountExcludingVAT);
	#EndRegion
	
	#Region RevenueFromSalesWithVAT
	Item = Items.Add();
	Item.PredefinedDataName = "RevenueFromSalesWithVAT";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Doanh thu bán hàng gồm thuế GTGT';
																					|ru = 'Выручка от продаж с НДС';
																					|en = 'Sales revenue incl VAT';
																					|it = 'Выручка от продаж с НДС';
																					|pl = 'Przychód ze sprzedaży';
																					|tr = 'KDV''li satış geliri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Income_2;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueAndCOGS.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.RevenueAndCOGS.Dimensions.InventoryType.Name,
		ExcludedTypesOfStocks,
		DataCompositionComparisonType.NotInList);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "RevenueAmount", 1, IndicatorsOfAnalyticalRegisters.AmountIncludingVAT);
	AddResources(Item.LocalResources, "RevenueAmountIncludingVATLocal", 1, IndicatorsOfAnalyticalRegisters.AmountIncludingVAT);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.AmountIncludingVAT);
	#EndRegion
	
	#Region SaleCost
	Item = Items.Add();
	Item.PredefinedDataName = "SaleCost";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giá vốn hàng bán';
																					|ru = 'Себестоимость продаж';
																					|en = 'Cost of goods sold';
																					|it = 'Себестоимость продаж';
																					|pl = 'Koszty własne sprzedaży';
																					|tr = 'Satılan malların maliyeti'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueAndCOGS.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.RevenueAndCOGS.Dimensions.InventoryType.Name,
		ExcludedTypesOfStocks,
		DataCompositionComparisonType.NotInList);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	Item.AdditionalIndicators = TabularSections.AdditionalIndicators.Copy();
	AddResources(Item.ManResources, "CostMan", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "LocalCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ManResources,
		"AddExpensesMan,LaborCostsMan,ItemizedFixedCostsManag,ItemizedVariableCostsManag", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.LocalResources,
		"AddExpensesLocal,LaborCostsLocal,ItemizedFixedCostsCompl,ItemizedVariableCostsCompl", 1,
		IndicatorsOfAnalyticalRegisters.AdditExpenseAmount);
	AddResources(Item.ManResources, "ProvisionForImpairmentMan", 1, IndicatorsOfAnalyticalRegisters.ProvisionForImpairment);
	AddResources(Item.LocalResources, "ProvisionForImpairmentLocal", 1, IndicatorsOfAnalyticalRegisters.ProvisionForImpairment);
	AddAdditionalCostIndicators(Item.AdditionalIndicators);
	#EndRegion
	
	#Region SellingExpenses_
	Item = Items.Add();
	Item.PredefinedDataName = "SellingExpenses_";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí bán hàng';
																					|ru = 'Расходы на продажу';
																					|en = 'Sales expenses';
																					|it = 'Spese di vendita';
																					|pl = 'Rozchody na sprzedaż';
																					|tr = 'Satış giderleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueAndCOGS.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "SellingExpensesMan");
	AddResources(Item.LocalResources, "SellingExpensesLocal");
	#EndRegion
	
	#Region VATFromSales
	Item = Items.Add();
	Item.PredefinedDataName = "VATFromSales";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT từ bán hàng';
																					|ru = 'НДС с продаж';
																					|en = 'VAT on sales';
																					|it = 'НДС с продаж';
																					|pl = 'VAT od sprzedaży';
																					|tr = 'Satış KDV''si'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008550";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueAndCOGS.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8550;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.RevenueAndCOGS.Dimensions.InventoryType.Name,
		ExcludedTypesOfStocks,
		DataCompositionComparisonType.NotInList);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "RevenueAmount", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.ManResources, "RevenueAmountExcludingVAT", -1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "RevenueAmountIncludingVATLocal", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "RevenueAmountExclVATLocal", -1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region SalesExcise
	Item = Items.Add();
	Item.PredefinedDataName = "SalesExcise";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế tiêu thụ đặc biệt từ bán hàng';
																					|ru = 'Акциз с продаж';
																					|en = 'Sales excise';
																					|it = 'Sales excise';
																					|pl = 'Sales excise';
																					|tr = 'Satışlarda tüketim vergisi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008560";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueAndCOGS.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8560;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.RevenueAndCOGS.Dimensions.InventoryType.Name,
		ExcludedTypesOfStocks,
		DataCompositionComparisonType.NotInList);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseExcisableGoods.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "ExciseAmountInCurrencyMgmt");
	AddResources(Item.LocalResources, "ExciseAmountInCurrencyLocal");
	#EndRegion
	
	#Region RevenueServicesAndAssets
	Item = Items.Add();
	Item.PredefinedDataName = "RevenueServicesAndAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Doanh thu khác';
																					|ru = 'Прочая выручка';
																					|en = 'Revenue — Services and Assets';
																					|it = 'Прочая выручка';
																					|pl = 'Utarg pozostały';
																					|tr = 'Diğer gelir'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008570";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Income_2;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueServicesAndAssets.Name;
	Item.SettingObjectSource = MetaReferenceBooks.IncomeExpensesAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8570;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.IncomeExpensesAccountingGroups.Attributes.Income.Name,
		True);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "RevenueExcludingVATManag", 1, IndicatorsOfAnalyticalRegisters.AmountExcludingVAT);
	AddResources(Item.LocalResources, "RevenueExcludingVATLocal", 1, IndicatorsOfAnalyticalRegisters.AmountExcludingVAT);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.AmountExcludingVAT);
	#EndRegion
	
	#Region OtherRevenueWithVAT
	Item = Items.Add();
	Item.PredefinedDataName = "OtherRevenueWithVAT";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Doanh thu khác gồm thuế GTGT';
																					|ru = 'Прочая выручка с НДС';
																					|en = 'Other revenue including VAT';
																					|it = 'Прочая выручка с НДС';
																					|pl = 'Utarg pozostały';
																					|tr = 'Diğer KDV dahil gelir'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008580";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Income_2;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueServicesAndAssets.Name;
	Item.SettingObjectSource = MetaReferenceBooks.IncomeExpensesAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8580;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.IncomeExpensesAccountingGroups.Attributes.Income.Name,
		True);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "RevenueExcludingVATManag,VATManag", 1, IndicatorsOfAnalyticalRegisters.AmountIncludingVAT);
	AddResources(Item.LocalResources, "RevenueExcludingVATLocal,VATLocal", 1, IndicatorsOfAnalyticalRegisters.AmountIncludingVAT);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.AmountIncludingVAT);
	#EndRegion
	
	#Region NDSSOfOtherSales
	Item = Items.Add();
	Item.PredefinedDataName = "NDSSOfOtherSales";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT từ doanh thu khác';
																					|ru = 'НДС с прочих продаж';
																					|en = 'VAT on other sales';
																					|it = 'НДС с прочих продаж';
																					|pl = 'VAT od pozostałych operacji sprzedaży';
																					|tr = 'Diğer satışlardan KDV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008590";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.RevenueServicesAndAssets.Name;
	Item.SettingObjectSource = MetaReferenceBooks.IncomeExpensesAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8590;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.IncomeExpensesAccountingGroups.Attributes.Income.Name,
		True);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "VATManag", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "VATLocal", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	#EndRegion
	
	#Region VATForShipmentsWithDeferredTransferOfTitle
	Item = Items.Add();
	Item.PredefinedDataName = "VATForShipmentsWithDeferredTransferOfTitle";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypesArray.Add(Type("CatalogRef.Counterparties"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thuế GTGT giao hàng mà chưa chuyển giao quyền sở hữu';
																					|ru = 'НДС по отгрузкам без перехода права собственности';
																					|en = 'VAT on shipment with deferred transfer of title of goods';
																					|it = 'НДС по отгрузкам без перехода права собственности';
																					|pl = 'VAT z wysyłek bez przeniesienia praw własności';
																					|tr = 'Mülkiyet hakkı devri olmadan sevkiyatlara ilişkin KDV'", LanguagesCodes); // @NStr-2
	Item.Code = "00000008600";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.Sales;
	Item.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 8600;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseVATAccounting.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	AddResources(Item.LocalResources, "SumCompl", 1, IndicatorsOfAnalyticalRegisters.VATAmount);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "Dimension");
	
	#EndRegion
	#EndRegion
	
	#Region IncomeExpenses
	#Region GroupIncomeExpenses
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "IncomeExpenses";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thu nhập và chi phí';
																					|ru = 'Доходы и расходы';
																					|en = 'Income and expenses';
																					|it = 'Доходы и расходы';
																					|pl = 'Dochody i rozchody';
																					|tr = 'Gelir ve giderler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000009000";
	Item.AddlOrderingAttribute = 9000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region OtherIncome
	Item = Items.Add();
	Item.PredefinedDataName = "OtherIncome";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thu nhập khác';
																					|ru = 'Прочие доходы';
																					|en = 'Income';
																					|it = 'Прочие доходы';
																					|pl = 'Inne dochody';
																					|tr = 'Diğer gelirler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000009010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IncomeExpenses;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Income_2;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherIncome.Name;
	Item.SettingObjectSource = MetaReferenceBooks.IncomeExpensesAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 9010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.IncomeExpensesAccountingGroups.Attributes.Income.Name,
		True);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion
	
	#Region OtherExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "OtherExpenses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí khác';
																					|ru = 'Прочие расходы';
																					|en = 'Other expenses';
																					|it = 'Прочие расходы';
																					|pl = 'Inne rozchody';
																					|tr = 'Diğer giderler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000009020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IncomeExpenses;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherExpenses.Name;
	Item.SettingObjectSource = MetaReferenceBooks.IncomeExpensesAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 9020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfSelectionOfObjectsSettings = NewDataLayoutSelection(
		MetaReferenceBooks.IncomeExpensesAccountingGroups.Attributes.Expenses.Name,
		True);
	FillInSelectionOfObjectsSettings(Item, DescriptionOfSelectionOfObjectsSettings);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion
	
	#Region ContinuingOperationIncomeClosing
	Item = Items.Add();
	Item.PredefinedDataName = "ContinuingOperationIncomeClosing";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đóng thu nhập từ hoạt động liên tục';
																					|ru = 'Закрытие доходов от продолжающихся операций';
																					|en = 'Continuing operation income closing';
																					|it = 'Закрытие доходов от продолжающихся операций';
																					|pl = 'Zamknięcie dochodów od kontynuowanych operacji';
																					|tr = 'Devam edem işlemlerden gelir kapatılması'", LanguagesCodes); // @NStr-2
	Item.Code = "00000009030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IncomeExpenses;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Income_2;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 9030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.DebitCredit.Name,
		Enums.RecordKindsOfOtherAssetsAndLiabilities.Credit);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion
	
	#Region ContinuingOperationExpenseClosing
	Item = Items.Add();
	Item.PredefinedDataName = "ContinuingOperationExpenseClosing";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đóng chi phí từ hoạt động liên tục';
																					|ru = 'Закрытие расходов от продолжающихся операций';
																					|en = 'Continuing operation expense closing';
																					|it = 'Закрытие расходов от продолжающихся операций';
																					|pl = 'Zamknięcie rozchodów od kontynuowanych operacji';
																					|tr = 'Devam eden işlemlerden gider kapatılması'", LanguagesCodes); // @NStr-2
	Item.Code = "00000009040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.IncomeExpenses;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.Expense;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 9040;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.IncomeExpenses;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.AssetRef.Name,
		ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions.DebitCredit.Name,
		Enums.RecordKindsOfOtherAssetsAndLiabilities.Debit);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion
	#EndRegion
	
	
	#Region FutureExpenseCommitments
	#Region GroupHasProvisionsAndContingentLiabilities
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "FutureExpenseCommitments";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng chi phí trả trước';
																					|ru = 'Резервы предстоящих расходов';
																					|en = 'Provisions and contingent liabilities';
																					|it = 'Резервы предстоящих расходов';
																					|pl = 'Rezerwy przyszłych wydatków';
																					|tr = 'Karşılıklar ve şarta bağlı yükümlülükler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010000";
	Item.AddlOrderingAttribute = 10000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region ProvisionsEstimatedLiabilities
	Item = Items.Add();
	Item.PredefinedDataName = "ProvisionsEstimatedLiabilities";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự phòng (đánh giá nợ phải trả)';
																					|ru = 'Резервы (оценочные обязательства)';
																					|en = 'Provisions';
																					|it = 'Резервы (оценочные обязательства)';
																					|pl = 'Rezerwy (szacowane zobowiązania)';
																					|tr = 'Yedekler (tahmini yükümlülükler)'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FutureExpenseCommitments;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FutureExpenseCommitments.Name;
	Item.SettingObjectSource = MetaReferenceBooks.Reserves.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.GenerateFutureExpenseCommitments.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "SumMan");
	AddResources(Item.LocalResources, "SumCompl");
	#EndRegion
	
	#Region ProvisionDiscountingInterest
	Item = Items.Add();
	Item.PredefinedDataName = "ProvisionDiscountingInterest";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tỷ lệ phần trăm chiết khấu dự phòng';
																					|ru = 'Проценты дисконтирования резервов';
																					|en = 'Provision discounting interest';
																					|it = 'Проценты дисконтирования резервов';
																					|pl = 'Provision discounting interest';
																					|tr = 'İskonto rezervlerinin yüzdesi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.FutureExpenseCommitments;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.FutureExpenseCommitments.Name;
	Item.SettingObjectSource = MetaReferenceBooks.Reserves.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.OtherAssetsLiabilities;
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.GenerateFutureExpenseCommitments.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	AddResources(Item.ManResources, "DiscountingAmountMan");
	AddResources(Item.LocalResources, "DiscountingAmountCompl");
	#EndRegion
	#EndRegion
	
	#Region InventoryAccepted
	#Region GroupInventoryAccepted
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "InventoryAccepted";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vật tư đã tiếp nhận';
																					|ru = 'Запасы принятые';
																					|en = 'Accepted inventory';
																					|it = 'Запасы принятые';
																					|pl = 'Accepted inventory';
																					|tr = 'Stoklar kabul edildi'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010500";
	Item.AddlOrderingAttribute = 10500;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region GoodsMaterialsAcceptedForStorageInWarehouses
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsMaterialsAcceptedForStorageInWarehouses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu đã tiếp nhận để lưu trong kho';
																					|ru = 'Товары и материалы принятые на хранение на складах';
																					|en = 'Vendor-managed inventory and materials in warehouses';
																					|it = 'Товары и материалы принятые на хранение на складах';
																					|pl = 'Vendor-managed inventory and materials in warehouses';
																					|tr = 'Ambarlardaki satıcı tarafından yönetilen stok ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010510";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10510;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection();
	OrGroup = NewDataLayoutSelectionElement(DescriptionOfDataSelection, DataCompositionFilterItemsGroupType.OrGroup);
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff);
	NewDataLayoutSelectionElement(OrGroup,
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	AndGroup = NewDataLayoutSelectionElement(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
	NewDataLayoutSelectionElement(AndGroup,
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(AndGroup,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	NewDataLayoutSelectionElement(AndGroup,
		"ItemsLocationAttributes.StorageLocation.ShopFloorStockroom",
		False);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseCustodyDuringPurchase.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	
	#EndRegion
	
	#Region GoodsMaterialsAcceptedForStorageInShopStorerooms
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsMaterialsAcceptedForStorageInShopStorerooms";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu đã tiếp nhận để lưu trong kho xưởng';
																					|ru = 'Товары и материалы принятые на хранение в цеховых кладовых';
																					|en = 'Vendor-managed inventory and materials in shop floor stockrooms';
																					|it = 'Товары и материалы принятые на хранение в цеховых кладовых';
																					|pl = 'Vendor-managed inventory and materials in shop floor stockrooms';
																					|tr = 'Atölye depolarındaki satıcı tarafından yönetilen stok ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010520";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10520;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageLocation.ShopFloorStockroom",
		True);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseCustodyDuringPurchase.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	
	#EndRegion
	
	#Region GoodsMaterialsAcceptedForStorageInProduction
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsMaterialsAcceptedForStorageInProduction";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu đã tiếp nhận để lưu trong sản xuất';
																					|ru = 'Товары и материалы принятые на хранение в производстве';
																					|en = 'Vendor-managed inventory and materials in production';
																					|it = 'Товары и материалы принятые на хранение в производстве';
																					|pl = 'Vendor-managed inventory and materials in production';
																					|tr = 'Üretim halinde satıcı tarafından yönetilen stok ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010530";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10530;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseCustodyDuringPurchase.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	
	#EndRegion
	
	#Region GoodsMaterialsAcceptedForStorageTransferredToPartners
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsMaterialsAcceptedForStorageTransferredToPartners";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa và nguyên vật liệu đã tiếp nhận để lưu được chuyển cho bạn hàng';
																					|ru = 'Товары и материалы принятые на хранение переданные партнерам';
																					|en = 'Vendor-managed inventory and materials transferred to partners';
																					|it = 'Товары и материалы принятые на хранение переданные партнерам';
																					|pl = 'Vendor-managed inventory and materials transferred to partners';
																					|tr = 'İş ortaklarına transfer edilmiş satıcı tarafından yönetilen stok ve malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010540";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10540;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners);
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		AccountingSections);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseCustodyDuringPurchase.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	
	#EndRegion
	
	#Region MaterialsAcceptedForProcessingInWarehouses
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsAcceptedForProcessingInWarehouses";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu đã tiếp nhận tại kho để gia công';
																					|ru = 'Материалы принятые в переработку на складах';
																					|en = 'Materials received for subcontracting at warehouses';
																					|it = 'Материалы принятые в переработку на складах';
																					|pl = 'Materials received for subcontracting at warehouses';
																					|tr = 'Ambarlarda işlenmesi için alınan malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010550";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10550;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection();
	OrGroup = NewDataLayoutSelectionElement(DescriptionOfDataSelection, DataCompositionFilterItemsGroupType.OrGroup);
	NewDataLayoutSelectionElement(OrGroup,
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingToRegisterWriteOff);
	AndGroup = NewDataLayoutSelectionElement(OrGroup, DataCompositionFilterItemsGroupType.AndGroup);
	NewDataLayoutSelectionElement(AndGroup,
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
	NewDataLayoutSelectionElement(AndGroup,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	NewDataLayoutSelectionElement(AndGroup,
		"ItemsLocationAttributes.StorageLocation.ShopFloorStockroom",
		False);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	
	#EndRegion
	
	#Region MaterialsAcceptedForProcessingInShopStorerooms
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsAcceptedForProcessingInShopStorerooms";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu được tiếp nhận vào gia công tại kho xưởng';
																					|ru = 'Материалы принятые в переработку в цеховых кладовых';
																					|en = 'Materials received for subcontracting in shop floor stockrooms';
																					|it = 'Материалы принятые в переработку в цеховых кладовых';
																					|pl = 'Materials received for subcontracting in shop floor stockrooms';
																					|tr = 'Atölye depolarındaki fason üretim için alınan malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010560";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.Warehouses.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10560;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageLocation.ShopFloorStockroom",
		True);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	#EndRegion
	
	#Region MaterialsAcceptedForProcessingInProduction
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsAcceptedForProcessingInProduction";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu được tiếp nhận vào gia công trong sản xuất';
																					|ru = 'Материалы принятые в переработку в производстве';
																					|en = 'Materials accepted for processing in production';
																					|it = 'Материалы принятые в переработку в производстве';
																					|pl = 'Materials accepted for processing in production';
																					|tr = 'Üretim halinde fason üretim için alınan malzemeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010570";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.AnalyticalInventoryGroups.FullName();
	Item.DetailedSettingsSource = MetaReferenceBooks.BusinessStructure.FullName();
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10570;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	#EndRegion
	
	#Region MaterialsReceivedForSubcontractingTransferredToPartners
	Item = Items.Add();
	Item.PredefinedDataName = "MaterialsReceivedForSubcontractingTransferredToPartners";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nguyên vật liệu tiếp nhận vào gia công đã chuyển giao cho bạn hàng';
																					|ru = 'Материалы принятые в переработку переданные партнерам';
																					|en = 'Materials received for subcontracting transferred to partners';
																					|it = 'Материалы принятые в переработку переданные партнерам';
																					|pl = 'Materiały przyjęte do przetwarzania przekazane partnerom';
																					|tr = 'İşlenmek üzere kabul edilen malzemeler iş ortaklarına transfer edilenler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010580";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10580;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	
	
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseTollManufacturing2_5.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	#EndRegion
	
	#Region GoodsReceivedByCommissionAgent
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsReceivedByCommissionAgent";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa đã tiếp nhận để bán ký gửi';
																					|ru = 'Товары принятые на комиссию';
																					|en = 'Goods received by consignee';
																					|it = 'Товары принятые на комиссию';
																					|pl = 'Goods received by consignee';
																					|tr = 'Konsinye kabul edilen ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010590";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10590;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseSalesCommission.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	
	#Region GoodsSubmittedToSubCommission
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsSubmittedToSubCommission";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hàng hóa được chuyển giao đi ký gửi';
																					|ru = 'Товары переданные на субкомиссию';
																					|en = 'Sub-consignment sales stock';
																					|it = 'Товары переданные на субкомиссию';
																					|pl = 'Sub-consignment sales stock';
																					|tr = 'Konsinyeye transfer edilen ürünler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010600";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = MetaAccumulationRegisters.InventoryCost.Name;
	Item.SettingObjectSource = MetaReferenceBooks.InventoryAccountingGroups.FullName();
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10600;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	DescriptionOfDataSelection = NewDataLayoutSelection(
		MetaAccumulationRegisters.InventoryCost.Dimensions.AccountingSection.Name,
		Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent);
	NewDataLayoutSelectionElement(DescriptionOfDataSelection,
		"ItemsLocationAttributes.StorageType",
		Enums.StorageLocationTypes.Warehouse,
		DataCompositionComparisonType.NotEqual);
	FillInDataSourceSelection(Item, DescriptionOfDataSelection);
	Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();
	AddFunctionalOption(Item.FunctionalOptions, MetaFunctionalOptions.UseSalesCommission.Name);
	FillInLinksOfFunctionalOptions(Item);
	Item.ManResources = TabularSections.ManResources.Copy();
	Item.LocalResources = TabularSections.LocalResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ManResources, "OffBalanceCost", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.LocalResources, "OffBalanceCostLocal", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	
	Item.PathsToExtdimensionData = TabularSections.PathsToExtdimensionData.Copy();
	AddPathToExtDimensionData(Item.PathsToExtdimensionData, FinancialExtraDimensionTypes.Counterparties, "ItemsLocationAttributes.StorageLocation");
	
	#EndRegion
	
	#Region ReceivedReturnablePackaging
	Item = Items.Add();
	Item.PredefinedDataName = "ReceivedReturnablePackaging";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bao bì luân chuyển đã tiếp nhận';
																					|ru = 'Принятая возвратная тара';
																					|en = 'Received returnable packaging';
																					|it = 'Принятая возвратная тара';
																					|pl = 'Przyjęta tara zwrotna';
																					|tr = 'İade edilebilir ambalajların kabulü'", LanguagesCodes); // @NStr-2
	Item.Code = "00000010610";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.InventoryAccepted;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = MetaAccumulationRegisters.ReceivedReturnablePackaging.Name;
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 10610;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Products;
	Item.ShaftResources = TabularSections.ShaftResources.Copy();
	Item.ResourcesQuantity = TabularSections.ResourcesQuantity.Copy();
	AddResources(Item.ShaftResources, "Sum", 1, IndicatorsOfAnalyticalRegisters.Cost);
	AddResources(Item.ResourcesQuantity, "Count", 1, IndicatorsOfAnalyticalRegisters.Cost);
	#EndRegion
	#EndRegion
	
	#Region ServiceArticles
	#Region ServiceArticlesGroup
	Item = Items.Add();
	Item.IsFolder = True;
	Item.PredefinedDataName = "ServiceArticles";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng hệ thống';
																					|ru = 'Служебные статьи';
																					|en = 'Internal items';
																					|it = 'Служебные статьи';
																					|pl = 'Internal items';
																					|tr = 'Hizmet kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00000011000";
	Item.AddlOrderingAttribute = 11000;
	Item.OutputTurnover = False;
	Item.WithoutDimension = False;
	#EndRegion
	
	#Region OBEntry
	Item = Items.Add();
	Item.PredefinedDataName = "OBEntry";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhập số dư';
																					|ru = 'Ввод остатков';
																					|en = 'Balance entry';
																					|it = 'Ввод остатков';
																					|pl = 'Wpisanie zapasów';
																					|tr = 'Bakiyeyi gir'", LanguagesCodes); // @NStr-2
	Item.Code = "00000011010";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ServiceArticles;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = "";
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 11010;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.EmptyRef();
	Item.LongDesc = NStr("vi = 'Dạng được sử dụng để tạo bản ghi kép với dạng bất kỳ mà theo đó tiến hành nhập số dư đầu bằng các chứng từ nhập số dư';
						|ru = 'Статья используется для формирования двойной записи с любой статьей, по которой производится ввод начальных остатков документами ввода остатков';
						|en = 'The item is used to generate a double entry with any item for which the opening balance is entered using the balance entry documents'; fa = 'The item is used to generate a double entry with any item for which the opening balance is entered using the balance entry documents';
						|it = 'Статья используется для формирования двойной записи с любой статьей, по которой производится ввод начальных остатков документами ввода остатков';
						|pl = 'The item is used to generate a double entry with any item for which the opening balance is entered using the balance entry documents';
						|tr = 'Bu kalem, bakiye giriş belgeleri kullanılarak açılış bakiyesi girilen herhangi bir kalemle çift kayıt oluşturmak için kullanılır.'");
	#EndRegion
	
	#Region RetailCustomerAccountsReceivables
	Item = Items.Add();
	Item.PredefinedDataName = "RetailCustomerAccountsReceivables";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán công nợ với khách lẻ';
																					|ru = 'Расчеты с розничными покупателями';
																					|en = 'AR/AP accounting for retail customers';
																					|it = 'Расчеты с розничными покупателями';
																					|pl = 'Rozliczenia z nabywcami detalicznymi';
																					|tr = 'Perakende müşterilere ilişkin hesaplamalar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000011020";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ServiceArticles;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = "";
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 11020;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	Item.LongDesc = NStr("vi = 'Dạng trung gian để tạo bản ghi kép có dạng ghi nhận doanh thu và thanh toán trong các chứng từ bán lẻ và trả lại';
						|ru = 'Транзитная статья для формирования двойной записи со статьями учета выручки и оплат в документах розничных продаж и возвратов';
						|en = 'A transit item to generate a double entry with revenue and payment accounting items in retail and goods return documents'; fa = 'A transit item to generate a double entry with revenue and payment accounting items in retail and goods return documents';
						|it = 'Транзитная статья для формирования двойной записи со статьями учета выручки и оплат в документах розничных продаж и возвратов';
						|pl = 'A transit item to generate a double entry with revenue and payment accounting items in retail and goods return documents';
						|tr = 'Perakende satış ve mal iade belgelerinde gelir ve ödeme muhasebe kalemleriyle çift kayıt oluşturmak için bir transit kalemi'");
	#EndRegion
	
	#Region ARAPSettlements
	Item = Items.Add();
	Item.PredefinedDataName = "ARAPSettlements";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hạch toán đối trừ công nợ';
																					|ru = 'Расчеты по взаимозачетам задолженности';
																					|en = 'AR/AP accounting for AR/AP offset';
																					|it = 'Расчеты по взаимозачетам задолженности';
																					|pl = 'Rozliczenia według rozliczeń wzajemnych zadłużenia';
																					|tr = 'Alacak/Borç mahsubuna ilişkin hesaplamalar'", LanguagesCodes); // @NStr-2
	Item.Code = "00000011030";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ServiceArticles;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = False;
	Item.DataSource = "";
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = True;
	Item.AddlOrderingAttribute = 11030;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.Counterparties;
	Item.LongDesc = NStr("vi = 'Dạng trung gian để tạo bản ghi kép có dạng ghi nhận hạch toán trong các chứng từ hạch toán công nợ';
						|ru = 'Транзитная статья для формирования двойной записи со статьями учета расчетов в документах взаимозачета задолженности';
						|en = 'A transit item to generate a double entry with AR/AP items in AR/AP offset documents'; fa = 'A transit item to generate a double entry with AR/AP items in AR/AP offset documents';
						|it = 'Транзитная статья для формирования двойной записи со статьями учета расчетов в документах взаимозачета задолженности';
						|pl = 'A transit item to generate a double entry with AR/AP items in AR/AP offset documents';
						|tr = 'Alacak/Borç mahsubu belgelerinde Alacak/Borç muhasebe kalemleriyle çift kayıt oluşturmak için bir transit kalemi'");
	#EndRegion
	
	#Region ImproperValues
	Item = Items.Add();
	Item.PredefinedDataName = "ImproperValues";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giá trị không thuộc sở hữu';
																					|ru = 'Несобственные ценности';
																					|en = 'Not owned values';
																					|it = 'Несобственные ценности';
																					|pl = 'Niewłasne wartości';
																					|tr = 'Sahip olunmayan değerler'", LanguagesCodes); // @NStr-2
	Item.Code = "00000011040";
	Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ServiceArticles;
	Item.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
	Item.AllocationOfLongTermAssetsAndLiabilities = False;
	Item.NotOwnedControlledValues = True;
	Item.DataSource = "";
	Item.SettingObjectSource = "";
	Item.DetailedSettingsSource = "";
	Item.LedgerAccountsInEntrySettings = False;
	Item.AddlOrderingAttribute = 11040;
	Item.OutputTurnover = False;
	Item.WithoutDimension = True;
	Item.TypeOfAccountingData = AccountingDataTypes.EmptyRef();
	Item.LongDesc = NStr("vi = 'Dạng hệ thống để đảm bảo làm việc với các dạng ghi nhận hàng hóa và nguyên vật liệu đã tiếp nhận';
						|ru = 'Служебная статья для обеспечения работы со статьями учета принятых товаров и материалов';
						|en = 'Internal item to ensure operations with items of accepted goods and materials'; fa = 'Internal item to ensure operations with items of accepted goods and materials';
						|it = 'Служебная статья для обеспечения работы со статьями учета принятых товаров и материалов';
						|pl = 'Internal item to ensure operations with items of accepted goods and materials';
						|tr = 'Kabul edilen mal ve malzemelerle ilgili işlemlerin yürütülmesini sağlamak için dahili kalem'");
	#EndRegion
	#EndRegion
	
	#EndRegion // #Scope of the description of the Financial account
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.AssetLiabilityItems - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns data sources for items of assets and liabilities that are objects of financial accounting.
// 
// Parameters:
//  AccountingSettings - See FinancialAccounting_Settings
//  ArticleSelectionSettings - See SettingsForSelectingItemsOfAssetsLiabilities
// 
// Returns:
//  Array of String - names of Accumulation registers - data sources
//
Function DataSourcesOfAccountingObjects(AccountingSettings, ArticleSelectionSettings = Undefined) Export
	
	If ArticleSelectionSettings = Undefined Then
		ArticleSelectionSettings = SettingsForSelectingItemsOfAssetsLiabilities();
	EndIf;
	
	ArticleSelectionSettings.ThereIsDataSource = True;
	
	RequestingAccountingObjects = RequestForFinancialAccountingObjects(AccountingSettings, ArticleSelectionSettings);
	
	QueriesTexts = New Array();
	QueriesTexts.Add(Left(RequestingAccountingObjects.Text, StrFind(RequestingAccountingObjects.Text, ";")));
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	AttributesOfArticles.DataSource AS DataSource
	|FROM
	|	TTItemsOfAssetsLiabilities AS AssetLiabilityItems
	|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AttributesOfArticles
	|	ON AssetLiabilityItems.Ref = AttributesOfArticles.Ref
	|");
	
	RequestingAccountingObjects.Text = StrConcat(QueriesTexts);
	Result = RequestingAccountingObjects.Execute();
	Selection = Result.Select();
	
	DataSources = New Array();
	
	While Selection.Next() Do
		If ValueIsFilled(Selection.DataSource) Then
			DataSources.Add(Selection.DataSource);
		EndIf;
	EndDo;
	
	Return DataSources;
	
EndFunction

// Returns a structure with properties that affect the composition of the financial accounting objects used
//
// Returns:
//  Structure:
//  * FormationOfCorrespondence - Boolean - According to the data of accounting objects, Entries with correspondence are formed
//  * AccountingForImproperValues - Boolean - Accounting of improper controlled values is used
//  * RevenueAccountingExcludingVAT - Boolean - Accounting of revenue from sales excluding VAT is used
//  * RevenueAccountingWithVAT - Boolean - Accounting of revenue from sales including VAT is used
//
Function FinancialAccounting_Settings() Export
	
	AccountingSettings = New Structure();
	AccountingSettings.Insert("FormationOfCorrespondence", True);
	AccountingSettings.Insert("AccountingForImproperValues", True);
	AccountingSettings.Insert("RevenueAccountingExcludingVAT", False);
	AccountingSettings.Insert("RevenueAccountingWithVAT", True);
	
	Return AccountingSettings;
	
EndFunction

// Returns a structure with properties that control the selection of financial accounting objects when their properties are obtained
//
// Returns:
//  Structure:
//  * Kind - Undefined, EnumRef.AssetAndLiabilityItemKinds, Array of EnumRef.AssetAndLiabilityItemKinds - selection of articles by type. Everything is uncertain.
//  * Ref - Undefined, ChartOfCharacteristicTypesRef.AssetLiabilityItems, Array of ChartOfCharacteristicTypesRef.AssetLiabilityItems - articles for selection. Everything is uncertain.
//  * TypeOfAccountingData - Undefined, EnumRef.AccountingDataTypes, Array of EnumRef.AccountingDataTypes - selection of articles by data types. Everything is uncertain.
//  * ThereIsDataSource - Undefined, Boolean - selection of articles based on the availability of data sources. Everything is uncertain.
//  * LedgerAccountsInEntrySettings - Undefined, Boolean - selection of articles based on the indication of accounting accounts in the transaction settings. Everything is uncertain.
//
Function SettingsForSelectingItemsOfAssetsLiabilities() Export
	
	Filter_Settings = New Structure();
	Filter_Settings.Insert("Kind", Undefined);
	Filter_Settings.Insert("Ref", Undefined);
	Filter_Settings.Insert("TypeOfAccountingData", Undefined);
	Filter_Settings.Insert("ThereIsDataSource", Undefined);
	Filter_Settings.Insert("LedgerAccountsInEntrySettings", Undefined);
	
	Return Filter_Settings;
	
EndFunction

// Returns a table of financial accounting objects with properties for setting up accounts and retrieving data.
// If any parameter is an expression of the query language, then the field descriptions in it must contain
// the alias of the data source obtained through the function of the financial accounting data of the balance registers.The data source alias is silent().
// If the parameter is only a field name, including a dereference separated by a dot, it can be specified without an alias of the data source.
// It is allowed to use request parameters from the function of the International accounting data of financial registers.Financial Register data requests().
// It is allowed to use string templates from the International Financial Register Data collection function.Request textsrecording registers().
// 
// Parameters:
//  AccountingSettings - See FinancialAccounting_Settings
//  ArticleSelectionSettings - See SettingsForSelectingItemsOfAssetsLiabilities
// 
// Returns:
//  See NewTableOfFinancialAccountingObjects
// 
Function DescriptionOfFinancialAccountingObjects(AccountingSettings, ArticleSelectionSettings = Undefined) Export
	
	Query = RequestForFinancialAccountingObjects(AccountingSettings, ArticleSelectionSettings);
	
	AdditionalSelectionFields = "
	|	AttributesOfArticles.Filterdata_ AS Filterdata_,
	|	AttributesOfArticles.PathsToExtdimensionData.(ExtDimensionType,DataPath) AS PathsToExtdimensionData,
	|	AttributesOfArticles.ManResources.(ResourceName,ZoomRatio,Factor) AS ManResources,
	|	AttributesOfArticles.LocalResources.(ResourceName,ZoomRatio,Factor) AS LocalResources,
	|	AttributesOfArticles.ShaftResources.(ResourceName,ZoomRatio,Factor) AS ShaftResources,
	|	AttributesOfArticles.ResourcesQuantity.(ResourceName,ZoomRatio,Factor) AS ResourcesQuantity,
	|	AttributesOfArticles.AdditionalIndicators.(Factor,ResourceGroup,ResourceName,ZoomRatio) AS AdditionalIndicators";
	
	Query.Text = StrReplace(Query.Text, "&AdditionalSelectionFields", AdditionalSelectionFields);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DescriptionOfAccountingObjects = NewTableOfFinancialAccountingObjects();
	RegisteredRecordsOtherAssetsLiabilities = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	CheckUseOfArticleByFunctionalOptions = Selection.Count() > 1;
		
	While Selection.Next() Do
		If CheckUseOfArticleByFunctionalOptions
		And Not UsingArticleOnFunctionalOptions(Selection) Then
			Continue;
		EndIf;
		
		NewRow = DescriptionOfAccountingObjects.Add();
		NewRow.AccountingObject = Selection.AccountingObject;
		NewRow.Presentation = Selection.AccountingObjectPresentation;
		NewRow.DataSource = Selection.DataSource;
		NewRow.Filterdata_ = SelectingLayoutFromSettingsStore(Selection.Filterdata_);
		NewRow.ImproperValues = Selection.ImproperValues;
		NewRow.AllocationOfLongTermAssetsAndLiabilities = Selection.AllocationOfLongTermAssetsAndLiabilities;
		NewRow.LedgerAccountsInEntrySettings = Selection.LedgerAccountsInEntrySettings;
		NewRow.DescriptionOfTheConfigurationObjectTypes = DescriptionOfTypesByFullNameOfObject(Selection.SettingObjectSource);
		NewRow.DescriptionOfTypesOfDetailedSettings = DescriptionOfTypesByFullNameOfObject(Selection.DetailedSettingsSource);
		NewRow.SelectingConfigurationObjects = SelectingLayoutFromSettingsStore(Selection.SelectingConfigurationObjects);
		NewRow.PathsToExtdimensionData = Selection.PathsToExtdimensionData.Unload();
		
		FillInResourceTables(NewRow, Selection);
		FillInIndicatorDescriptions(NewRow, Selection);
		
		If NewRow.DataSource = RegisteredRecordsOtherAssetsLiabilities Then
			FillInPropertiesOfOtherAssetsLiabilities(NewRow);
		EndIf;
	EndDo;
	
	DescriptionOfAccountingObjects.Indexes.Add("AccountingObject");
	DescriptionOfAccountingObjects.Indexes.Add("DataSource");
	
	AddDescriptionOfAccountingObjectsToGetData(AccountingSettings, DescriptionOfAccountingObjects);
	
	Return DescriptionOfAccountingObjects;
	
EndFunction

// Returns a structure with the properties of the passed financial accounting object. The list of properties and their filling
// is similar to the table from the New tableobjects of Financial accounting.
// 
// Parameters:
//  AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems - Object Of Financial Accounting
//  TransferToClient - Boolean - the resulting properties can be transferred from the server to the client
// 
// Returns:
//  Undefined - accounting object not found,
//  Structure:
//  * AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems - Reference of the financial accounting object
//  * Presentation - String - Name of the financial accounting object
//  * DataSource - String - The name of the Accumulation register that keeps records of the fin object.accounting
//  * Filterdata_ - DataCompositionFilter - Selection of Accumulation register data for the fin object.accounting
//  * DebitCondition - String - A condition in the query language for determining the debit RegisteredRecords attribute.
//  * ConditionCredit - String - A condition in the query language for determining the credit RegisteredRecorded attribute.
//  * InversionOfRegisteredRecords - Boolean - Only for Balance registers. Matching the register data for the fin object.according to the rule, Receipt = Credit, Expense = Debit. Only the True value is taken into account.
//  * DataPathConfigurationObject - String - The path of the register data selection corresponding to the settings objects, in the context of which the accounting accounts are specified.
//  * PathToDataLineOfBusiness - String - The path of fetching the activity direction value from the register data.
//  * DataPathRecordFinID - String - The path of fetching the register record ID value.
//  * DataPathSettingUpHouseholdOperations - String - The path of fetching the setting value of a business transaction.
//  * DataPathRowId - String - The path of fetching the value of the register string identifier.
//  * PathsToExtdimensionData - Map of KeyAndValue - Refinement of sub-konto sampling paths. Specified in the case of an incorrect result of selecting the value of the sub-konto from the sources of the sub-konto register:
//   ** Key - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - Extra dimension type
//   ** Value - String - The path of selecting the subconto value
//  * ManResources - See NewResourceTable
//  * LocalResources - See NewResourceTable
//  * ShaftResources - See NewResourceTable
//  * ResourcesQuantity - See NewResourceTable
//  * Indicators - Map of KeyAndValue - LongDesc:
//   ** Key - EnumRef.IndicatorsOfAnalyticalRegisters - Indicator value
//   ** Value - See NewDescriptionOfIndicator
//  * CorDataSources - Array of String - An array of rows with the names of the accumulation registers in which the corresponding accounting objects are recorded. Used for the Revenue register.
//  * ImproperValues - Boolean - A sign of accounting for improper controlled values in an object
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean - The data of the accounting object is divided into short-term and long-term, the attribute is translated from the data source.
//  * LedgerAccountsInEntrySettings - Boolean - Whether to specify accounting accounts in the transaction settings
//  * DescriptionOfTheConfigurationObjectTypes - TypeDescription - description of the types of the configuration object
//  * DescriptionOfTypesOfDetailedSettings - TypeDescription - description of the types of the detailed configuration object
//  * SelectingConfigurationObjects - DataCompositionFilter - selecting configuration objects
//  * SignsOfCorrespondenceAccounting - See NewTableSignsOfCorrespondenceAccounting
//
Function DescriptionOfFinancialAccountingObject(AccountingObject, TransferToClient = False) Export
	
	If Not ValueIsFilled(AccountingObject) Then
		Return Undefined;
	EndIf;
	
	AccountingSettings = FinancialAccounting_Settings();
	For Each KeyAndValue In AccountingSettings Do
		AccountingSettings[KeyAndValue.Key] = True;
	EndDo;
	
	Filter_Settings = SettingsForSelectingItemsOfAssetsLiabilities();
	Filter_Settings.Ref = AccountingObject;
	
	DescriptionOfAccountingObjects = DescriptionOfFinancialAccountingObjects(AccountingSettings, Filter_Settings);
	
	If DescriptionOfAccountingObjects.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DescriptionOfAccountingObject_ = New Structure();
	
	For Each Column In DescriptionOfAccountingObjects.Columns Do
		PropertyName = Column.Name;
		PropertyValue = DescriptionOfAccountingObjects[0][PropertyName];
		If PropertyName = "PathsToExtdimensionData" Then
			PathsToExtdimensionData = New Map();
			For Each TableRow In PropertyValue Do
				PathsToExtdimensionData.Insert(TableRow.ExtDimensionType, TableRow.DataPath);
			EndDo;
			DescriptionOfAccountingObject_.Insert(PropertyName, PathsToExtdimensionData);
		ElsIf TransferToClient And PropertyName = "Indicators" Then
			Indicators = New Map();
			For Each KeyAndValue In PropertyValue Do
				DescriptionIndicator = Common.CopyRecursive(KeyAndValue.Value);
				ResourceTableNames = ResourceTableNames();
				For Each TableName In ResourceTableNames Do
					DescriptionIndicator.Insert(TableName, Common.ValueTableToArray(DescriptionIndicator[TableName]));
				EndDo;
				Indicators.Insert(KeyAndValue.Key, DescriptionIndicator);
			EndDo;
			DescriptionOfAccountingObject_.Insert(PropertyName, Indicators);
		ElsIf TransferToClient And Column.ValueType.ContainsType(Type("ValueTable")) Then
			DescriptionOfAccountingObject_.Insert(PropertyName, Common.ValueTableToArray(PropertyValue));
		Else
			DescriptionOfAccountingObject_.Insert(PropertyName, PropertyValue);
		EndIf;
	EndDo;
	
	Return DescriptionOfAccountingObject_;
	
EndFunction

// Returns a tree of financial accounting objects with properties for Presentation in forms. The composition
// of accounting objects is controlled by the transmitted accounting settings and the indication of the presence of accounts in the settings.
// 
// Parameters:
//  AccountingSettings - See FinancialAccounting_Settings
//  ArticleSelectionSettings - See SettingsForSelectingItemsOfAssetsLiabilities
// 
// Returns:
//  See NewTreeOfFinancialAccountingObjects
//
Function TreeOfFinancialAccountingObjects(AccountingSettings, ArticleSelectionSettings = Undefined) Export
	
	Query = RequestForFinancialAccountingObjects(AccountingSettings, ArticleSelectionSettings);
	Query.Text = StrReplace(Query.Text, "&AdditionalSelectionFields", "TRUE");
	Query.Text = Query.Text + "
	|TOTALS
	|	MIN(ImproperValues)
	|BY
	|	Parent
	|";
	
	Result = Query.Execute();
	ParentSelection = Result.Select(QueryResultIteration.ByGroups);
	
	TreeOfAccountingObjects = NewTreeOfFinancialAccountingObjects();
	TreeRowsToDelete = New Array;
	
	While ParentSelection.Next() Do
		NewFolder = TreeOfAccountingObjects.Rows.Add();
		NewFolder.IsFolder = True;
		NewFolder.AccountingObject = ParentSelection.Parent;
		NewFolder.ImproperValues = ParentSelection.ImproperValues;
		
		Selection = ParentSelection.Select();
		While Selection.Next() Do
			If UsingArticleOnFunctionalOptions(Selection) Then
				If IsBlankString(NewFolder.Presentation) Then
					NewFolder.Presentation = Selection.ParentPresentation;
				EndIf;
				
				NewRow = NewFolder.Rows.Add();
				NewRow.AccountingObject = Selection.AccountingObject;
				NewRow.Presentation = Selection.AccountingObjectPresentation;
				NewRow.DataSource = Selection.DataSource;
				NewRow.ImproperValues = Selection.ImproperValues;
				NewRow.AllocationOfLongTermAssetsAndLiabilities = Selection.AllocationOfLongTermAssetsAndLiabilities;
				NewRow.DescriptionOfTheConfigurationObjectTypes = DescriptionOfTypesByFullNameOfObject(Selection.SettingObjectSource);
				NewRow.DescriptionOfTypesOfDetailedSettings = DescriptionOfTypesByFullNameOfObject(Selection.DetailedSettingsSource);
				NewRow.SelectingConfigurationObjects = SelectingLayoutFromSettingsStore(Selection.SelectingConfigurationObjects);
			EndIf;
		EndDo;
		
		If IsBlankString(NewFolder.Presentation) Then
			TreeRowsToDelete.Add(NewFolder);
		EndIf;
	EndDo;
	
	For Each TreeRow In TreeRowsToDelete Do
		TreeOfAccountingObjects.Rows.Delete(TreeRow);
	EndDo;
	
	Return TreeOfAccountingObjects;
	
EndFunction

// Returns a Presentation of an object based on the passed type description
// 
// Parameters:
//  ObjectTypesDetails - TypeDescription - description of object types
// 
// Returns:
//  String - object description based on metadata views
//
Function ItemTitleByTypeDescription(ObjectTypesDetails) Export
	
	ObjectViews = New Array();
	
	For Each Type In ObjectTypesDetails.Types() Do
		ObjectMetadata =  Metadata.FindByType(Type); 
		If Common.IsCatalog(ObjectMetadata) And ObjectMetadata.ObjectPresentation <> "" Then
			ObjectViews.Add(ObjectMetadata.ObjectPresentation);
		ElsIf Common.IsChartOfCharacteristicTypes(ObjectMetadata) And ObjectMetadata.ObjectPresentation <> "" Then
			ObjectViews.Add(ObjectMetadata.ObjectPresentation);
		ElsIf ObjectMetadata <> Undefined Then
			ObjectViews.Add(ObjectMetadata.Presentation());
		EndIf;
	EndDo;
	
	Return StrConcat(ObjectViews, ",");
	
EndFunction

// Initializes the settings Composer with a request to the data source.
// 
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - 
//  DataSource - String - name of the accumulation register
//  AccountingReflectionParameters - See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//  FormIdentifier - UUID, String - unique form ID or address in temporary storage.
//  	A unique identifier is passed when the Set-up linker is a form detail.
//  	The address in the temporary storage is passed to the Configuration linker and the address of the data layout scheme are the details of the form.
//
Procedure InitializeSettingsComposerWithDataSource(SettingsComposer,
	DataSource, AccountingReflectionParameters = Undefined, FormIdentifier = Undefined) Export
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	
	If Not IsBlankString(DataSource) Then
		If AccountingReflectionParameters = Undefined Then
			RegisterManager = AccumulationRegisters[DataSource]; // AccumulationRegisterManager -
			AccountingReflectionParameters = RegisterManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting();
			
			If GetFunctionalOption("UseFinancialAccounting")
				And GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
				AccountingReflectionParameters =
					FinancialAccountingByFinancialRegisterData.ParametersOfRegisteringRecordedMovementsInInternationalAccounting(DataSource);
			EndIf;
		EndIf;
		
		DimensionsDetails = AccountingReflectionParameters.DimensionsDetails;
		AttributesDetails1 = AccountingReflectionParameters.AttributesDetails1;
		DescriptionOfPrimitiveTypes = FinancialAccountingByBalanceSheetRegisterData.DescriptionOfPrimitiveTypes();
		
		SelectionFields1 = New Array();
		FilterFields = New Array();
		
		For Each KeyAndValue In DimensionsDetails Do
			FieldName = KeyAndValue.Key;
			FieldDetails = KeyAndValue.Value; 
			SelectionFields1.Add(FieldDetails.DataPath + " AS " + FieldName); //@query-part
			TypePrimitive = DescriptionOfPrimitiveTypes.ContainsType(FieldDetails.Type.Types()[0]);
			FilterFields.Add(FieldDetails.DataPath + ?(TypePrimitive, "", ".*") + " AS " + FieldName); //@query-part
		EndDo;
		
		For Each KeyAndValue In AttributesDetails1 Do
			FieldName = KeyAndValue.Key;
			FieldDetails = KeyAndValue.Value; 
			TypePrimitive = DescriptionOfPrimitiveTypes.ContainsType(FieldDetails.Type.Types()[0]);
			FilterFields.Add(FieldDetails.DataPath + ?(TypePrimitive, "", ".*") + " AS " + FieldName); //@query-part
		EndDo;
		
		QueryText = "
		|SELECT
		|	&SelectionFields1
		|FROM
		|	&RegisterTableName AS RegisterTable
		|{WHERE
		|	&FilterFields
		|}";
		
		Separator = "," + Chars.LF +Chars.Tab;
		QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, Separator));
		QueryText = StrReplace(QueryText, "&FilterFields", StrConcat(FilterFields, Separator));
		QueryText = StrReplace(QueryText, "&RegisterTableName", "AccumulationRegister." + DataSource);
		
		DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema);
		DataSet.Query = QueryText;
		
		For Each KeyAndValue In DimensionsDetails Do
			FieldName = KeyAndValue.Key;
			FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.
			FinancialReportingServer.NewSetField(DataSet, FieldName, FieldName, FieldDetails.Title, FieldDetails.Type);
		EndDo;
		
		For Each KeyAndValue In AttributesDetails1 Do
			FieldName = KeyAndValue.Key;
			FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.
			FinancialReportingServer.NewSetField(DataSet, FieldName, FieldName, FieldDetails.Title, FieldDetails.Type);
		EndDo;
	EndIf;
	
	If FormIdentifier = Undefined Then
		AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	Else
		AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, FormIdentifier);
		AvailableSettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema);
	EndIf;
	
	SettingsComposer.Initialize(AvailableSettingsSource);
	
EndProcedure

// Initializes the settings Composer with a request to the source of the configuration objects.
// 
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - 
//  FullNameOfConfigurationObject - String - full name of the source of the configuration objects
//  MetadataOfConfigurationObject - MetadataObject - metadata of the source of configuration objects
//  FormIdentifier - UUID, String - unique form ID or address in temporary storage.
//  	A unique identifier is passed when the Set-up linker is a form detail.
//  	The address in the temporary storage is passed to the Configuration linker and the address of the data layout scheme are the details of the form.
//
Procedure InitializeSettingsComposerWithSettingsObject(SettingsComposer,
	FullNameOfConfigurationObject, MetadataOfConfigurationObject = Undefined, FormIdentifier = Undefined) Export
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	
	If Not IsBlankString(FullNameOfConfigurationObject) Then
		If MetadataOfConfigurationObject = Undefined Then
			MetadataOfConfigurationObject = Metadata.FindByFullName(FullNameOfConfigurationObject);
		EndIf;
		
		IsRefTypeObject = Common.IsRefTypeObject(MetadataOfConfigurationObject);
		DescriptionOfPrimitiveTypes = FinancialAccountingByBalanceSheetRegisterData.DescriptionOfPrimitiveTypes();
		
		SelectionFields1 = New Array();
		FilterFields = New Array();
		
		For Each Attribute In MetadataOfConfigurationObject.StandardAttributes Do
			FieldName = Attribute.Name;
			FieldType = Attribute.Type; 
			TypePrimitive = DescriptionOfPrimitiveTypes.ContainsType(FieldType.Types()[0]);
			SelectionFields1.Add(FieldName + " AS " + FieldName); //@query-part
			FilterFields.Add(FieldName + ?(TypePrimitive, "", ".*") + " AS " + FieldName); //@query-part
		EndDo;
		
		If IsRefTypeObject Then
			For Each Attribute In MetadataOfConfigurationObject.Attributes Do
				FieldName = Attribute.Name;
				FieldType = Attribute.Type; 
				TypePrimitive = DescriptionOfPrimitiveTypes.ContainsType(FieldType.Types()[0]);
				SelectionFields1.Add(FieldName + " AS " + FieldName); //@query-part
				FilterFields.Add(FieldName + ?(TypePrimitive, "", ".*") + " AS " + FieldName); //@query-part
			EndDo;
		EndIf;
		
		QueryText = "
		|SELECT
		|	&SelectionFields1
		|FROM
		|	&ObjectTableName AS ObjectTable
		|{WHERE
		|	&FilterFields
		|}";
		
		Separator = "," + Chars.LF +Chars.Tab;
		QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, Separator));
		QueryText = StrReplace(QueryText, "&FilterFields", StrConcat(FilterFields, Separator));
		QueryText = StrReplace(QueryText, "&ObjectTableName", FullNameOfConfigurationObject);
		
		DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema);
		DataSet.Query = QueryText;
		
		For Each Attribute In MetadataOfConfigurationObject.StandardAttributes Do
			FieldName = Attribute.Name;
			FieldTitle = Attribute.Synonym;
			FieldType = Attribute.Type;
			FinancialReportingServer.NewSetField(DataSet, FieldName, FieldName, FieldTitle, FieldType);
		EndDo;
		
		If IsRefTypeObject Then
			For Each Attribute In MetadataOfConfigurationObject.Attributes Do
				FieldName = Attribute.Name;
				FieldTitle = Attribute.Synonym;
				FieldType = Attribute.Type;
				FinancialReportingServer.NewSetField(DataSet, FieldName, FieldName, FieldTitle, FieldType);
			EndDo;
		EndIf;
	EndIf;
	
	If FormIdentifier = Undefined Then
		AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	Else
		AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, FormIdentifier);
		AvailableSettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema);
	EndIf;
	
	SettingsComposer.Initialize(AvailableSettingsSource);
	
EndProcedure

// Returns a description of budgeting indicators for the transferred assets and liabilities item
// 
// Parameters:
//  AssetAndLiabilityItem - ChartOfCharacteristicTypesRef.AssetLiabilityItems - assets and liabilities item
// 
// Returns:
//  Map of KeyAndValue - LongDesc:
//  * Key - EnumRef.IndicatorsOfAnalyticalRegisters - budgeting indicator for the transferred item
//  * Value - See NewDescriptionOfIndicator
//
Function IndicatorsOfArticleOfAssetsLiabilities(AssetAndLiabilityItem) Export
	
	Query = New Query();
	Query.SetParameter("AssetAndLiabilityItem", AssetAndLiabilityItem);
	Query.SetParameter("ManResources", ManagementAccountingResourcesGroup());
	Query.SetParameter("LocalResources", RegulatedAccountingResourcesGroup());
	Query.SetParameter("ShaftResources", CurrencyAccountingResourcesGroup());
	Query.SetParameter("ResourcesQuantity", QuantitativeAccountingResourcesGroup());
	
	MetaDataSourceOfOtherAssetsLiabilities = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	ResourcesOfSourceOfOtherAssetsLiabilities = MetaDataSourceOfOtherAssetsLiabilities.Resources;
	
	Query.SetParameter("NameOfManResource", ResourcesOfSourceOfOtherAssetsLiabilities.SumMan.Name);
	Query.SetParameter("LocalResourceName", ResourcesOfSourceOfOtherAssetsLiabilities.SumCompl.Name);
	
	Query.Text = "
	|SELECT
	|	ManResources.Factor AS Factor,
	|	&ManResources AS ResourceGroup,
	|	ManResources.ResourceName AS ResourceName,
	|	ManResources.ZoomRatio AS ZoomRatio
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.ManResources AS ManResources
	|WHERE
	|	ManResources.Ref = &AssetAndLiabilityItem
	|
	|UNION ALL
	|
	|SELECT
	|	LocalResources.Factor AS Factor,
	|	&LocalResources AS ResourceGroup,
	|	LocalResources.ResourceName AS ResourceName,
	|	LocalResources.ZoomRatio AS ZoomRatio
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.LocalResources AS LocalResources
	|WHERE
	|	LocalResources.Ref = &AssetAndLiabilityItem
	|
	|UNION ALL
	|
	|SELECT
	|	ShaftResources.Factor AS Factor,
	|	&ShaftResources AS ResourceGroup,
	|	ShaftResources.ResourceName AS ResourceName,
	|	ShaftResources.ZoomRatio AS ZoomRatio
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.ShaftResources AS ShaftResources
	|WHERE
	|	ShaftResources.Ref = &AssetAndLiabilityItem
	|
	|UNION ALL
	|
	|SELECT
	|	ResourcesQuantity.Factor AS Factor,
	|	&ResourcesQuantity AS ResourceGroup,
	|	ResourcesQuantity.ResourceName AS ResourceName,
	|	ResourcesQuantity.ZoomRatio AS ZoomRatio
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.ResourcesQuantity AS ResourcesQuantity
	|WHERE
	|	ResourcesQuantity.Ref = &AssetAndLiabilityItem
	|
	|UNION ALL
	|
	|SELECT
	|	AdditionalIndicators.Factor AS Factor,
	|	AdditionalIndicators.ResourceGroup AS ResourceGroup,
	|	AdditionalIndicators.ResourceName AS ResourceName,
	|	AdditionalIndicators.ZoomRatio AS ZoomRatio
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems.AdditionalIndicators AS AdditionalIndicators
	|WHERE
	|	AdditionalIndicators.Ref = &AssetAndLiabilityItem
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.Sum) AS Factor,
	|	ResourcesOfSourceOfOtherAssetsLiabilities.ResourceGroup AS ResourceGroup,
	|	ResourcesOfSourceOfOtherAssetsLiabilities.ResourceName AS ResourceName,
	|	1 AS ZoomRatio
	|FROM
	|	(SELECT
	|		&ManResources AS ResourceGroup,
	|		&NameOfManResource AS ResourceName
	|	UNION ALL
	|	SELECT
	|		&LocalResources AS ResourceGroup,
	|		&LocalResourceName AS ResourceName
	|	) AS ResourcesOfSourceOfOtherAssetsLiabilities
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|		WHERE
	|			NOT AssetLiabilityItems.Predefined
	|			AND AssetLiabilityItems.Ref = &AssetAndLiabilityItem
	|		)
	|";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ArticleIndicators = New Map();
	ResourceTableNames = ResourceTableNames();
	
	While Selection.Next() Do
		If ResourceTableNames.Find(Selection.ResourceGroup) = Undefined Then
			Continue;
		EndIf;
		
		If ArticleIndicators[Selection.Factor] = Undefined Then
			DescriptionIndicator = NewDescriptionOfIndicator();
			ArticleIndicators.Insert(Selection.Factor, DescriptionIndicator);
		EndIf;
		
		ResourceTable = ArticleIndicators[Selection.Factor][Selection.ResourceGroup]; // ValueTable -
		FillPropertyValues(ResourceTable.Add(), Selection);
	EndDo;
	
	Return ArticleIndicators;
	
EndFunction

// Returns the structure of the tables of the Accumulation Register resource composition for calculating the indicator value 
// in the currencies of Upr. and Local accounting, currency amount and quantity.
// 
// Returns:
//  Structure - LongDesc:
//   * Key - String - The name of the resource table from the resource nameablessources
//   * Value - See NewResourceTable
//
Function NewDescriptionOfIndicator() Export
	
	DescriptionIndicator = New Structure();
	ResourceTableNames = ResourceTableNames();
	
	For Each TableName In ResourceTableNames Do
		DescriptionIndicator.Insert(TableName, NewResourceTable());
	EndDo;
	
	Return DescriptionIndicator;
	
EndFunction

// Returns the name of the management accounting resource group for naming tables and structure properties
// in resource and metric descriptions.
// 
// Returns:
//  String
//
Function ManagementAccountingResourcesGroup() Export
	
	Return "ManResources";
	
EndFunction

// Returns the name of the regulated accounting resource group for naming tables and structure properties
// in resource and metric descriptions.
// 
// Returns:
//  String
//
Function RegulatedAccountingResourcesGroup() Export
	
	Return "LocalResources";
	
EndFunction

// Returns the name of the currency accounting resource group for naming tables and structure properties
// in resource descriptions and indicators.
// 
// Returns:
//  String
//
Function CurrencyAccountingResourcesGroup() Export
	
	Return "ShaftResources";
	
EndFunction

// Returns the name of the quantitative accounting resource group for naming tables and structure properties
// in resource and metric descriptions.
// 
// Returns:
//  String
//
Function QuantitativeAccountingResourcesGroup() Export
	
	Return "ResourcesQuantity";
	
EndFunction

// Returns an indication that the indicator data for the asset liability item in the register matches the rule Receipt = Credit, Expense = Debit.
// Parameters:
//  DescriptionOfAssetsLiabilitiesItem - See DescriptionOfFinancialAccountingObject
//  Factor - EnumRef.IndicatorsOfAnalyticalRegisters - budgeting indicator of the asset liability item
// 
// Returns:
//  Boolean - True if the indicator data in the register has an inverse logic
//
Function InversionOfArticleSRegisteredRecordsByIndicator(DescriptionOfAssetsLiabilitiesItem, Factor) Export
	
	If DescriptionOfAssetsLiabilitiesItem.AccountingObject = ChartsOfCharacteristicTypes.AssetLiabilityItems.TicketsBooking Then
		Return Factor = Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount;
	Else
		Return DescriptionOfAssetsLiabilitiesItem.InversionOfRegisteredRecords;
	EndIf;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
			If ThisIsObjectOfFinancialAccounting(Parameters.Key) Then
				StandardProcessing = False;
				SelectedForm = "AccountingObjectForm";
			EndIf;
		EndIf;
	ElsIf FormType = "ChoiceForm" Then
		If Parameters.Property("FinancialAccountingObjects") And Parameters.FinancialAccountingObjects = True Then
			StandardProcessing = False;
			SelectedForm = "AccountingObjectChoiceForm";
		EndIf;
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	IncomeAndExpensesServer.ProcessingOfObtainingDataOnSelectionOfMainItemOfAssetsLiabilities(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Initializes the settings Composer with a request to the names of functional options.
// 
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - 
//  FunctionalOptions - ValueTable, TabularSection, FormDataCollection - list of functional options that affect the use of the article:
//   * FunctionalOptionName - String - Name of the function option
//  FormIdentifier - UUID - unique form ID. Passed when the set-up linker is a form Attribute
//
Procedure InitializeSettingsComposerWithFunctionalOptions(SettingsComposer,
	FunctionalOptions, FormIdentifier = Undefined) Export
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	
	If ValueIsFilled(FunctionalOptions) Then
		MetaFunctionalOptions = Metadata.FunctionalOptions;
		
		SelectionFields1 = New Array();
		
		For Each OptionString In FunctionalOptions Do
			FieldName = OptionString.FunctionalOptionName;
			SelectionFields1.Add("TRUE AS " + FieldName); //@query-part
		EndDo;
		
		QueryText = "
		|SELECT
		|	&SelectionFields1
		|{WHERE
		|	&SelectionFields1
		|}";
		
		Separator = "," + Chars.LF + Chars.Tab;
		QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, Separator));
		
		DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema);
		DataSet.Query = QueryText;
		
		For Each OptionString In FunctionalOptions Do
			FieldName = OptionString.FunctionalOptionName;
			FieldTitle = MetaFunctionalOptions[OptionString.FunctionalOptionName].Synonym;
			FinancialReportingServer.NewSetField(DataSet, FieldName, FieldName, FieldTitle);
		EndDo;
	EndIf;
	
	If FormIdentifier = Undefined Then
		AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	Else
		AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, FormIdentifier);
		AvailableSettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema);
	EndIf;
	
	SettingsComposer.Initialize(AvailableSettingsSource);
	
EndProcedure

Function ThisIsCustomArticle(AssetAndLiabilityItem) Export
	
	If TypeOf(AssetAndLiabilityItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		AttributesValues = Common.ObjectAttributesValues(
			AssetAndLiabilityItem, "Predefined");
	Else
		AttributesValues = AssetAndLiabilityItem;
	EndIf;
	
	Return Not AttributesValues.Predefined;
	
EndFunction

Function ThisIsItemOfManagementBalanceSheet(AssetAndLiabilityItem) Export
	
	If TypeOf(AssetAndLiabilityItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		AttributesValues = Common.ObjectAttributesValues(
			AssetAndLiabilityItem, "AssetLiability,Kind,PredefinedDataName,Predefined");
	Else
		AttributesValues = AssetAndLiabilityItem;
	EndIf;
	
	If AttributesValues.PredefinedDataName = "IssuedBorrowings"
	 Or AttributesValues.PredefinedDataName = "Taxes"
	 Or AttributesValues.PredefinedDataName = "Payroll" Then
		Return True;
	Else
		Return AttributesValues.Predefined
			And Not ValueIsFilled(AttributesValues.Kind)
			And ValueIsFilled(AttributesValues.AssetLiability);
	EndIf;
	
EndFunction

Function ThisIsObjectOfFinancialAccounting(AssetAndLiabilityItem) Export
	
	If TypeOf(AssetAndLiabilityItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		AttributesValues = Common.ObjectAttributesValues(
			AssetAndLiabilityItem, "AssetLiability,Kind,PredefinedDataName,Predefined");
	Else
		AttributesValues = AssetAndLiabilityItem;
	EndIf;
	
	If AttributesValues.PredefinedDataName = "BranchOfficeAssetsARAPAccounting"
	 Or AttributesValues.PredefinedDataName = "BranchOfficeARAPAccounting"
	 Or AttributesValues.PredefinedDataName = "VATForShipmentsWithDeferredTransferOfTitle"
	 Or AttributesValues.PredefinedDataName = "RemunerationProvisions"
	 Or AttributesValues.PredefinedDataName = "ProvisionsForInsurancePremiums" Then
		Return True;
	Else
		Return AttributesValues.Predefined
			And ValueIsFilled(AttributesValues.Kind)
			And Not ValueIsFilled(AttributesValues.AssetLiability);
	EndIf;
	
EndFunction

Function UsingArticleOnFunctionalOptions(AssetAndLiabilityItem, SettingsComposer = Undefined) Export
	
	If TypeOf(AssetAndLiabilityItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		ArticleDetails_1 = New Array();
		ArticleDetails_1.Add("FunctionalOptions");
		If SettingsComposer = Undefined Then
			ArticleDetails_1.Add("FunctionalOptionLinks");
		EndIf;
		AttributesValues = Common.ObjectAttributesValues(
			AssetAndLiabilityItem, StrConcat(ArticleDetails_1, ","));
		FunctionalOptions = AttributesValues.FunctionalOptions.Unload();
		If SettingsComposer = Undefined Then
			FunctionalOptionLinks = AttributesValues.FunctionalOptionLinks;
		EndIf;
	ElsIf TypeOf(AssetAndLiabilityItem) = Type("QueryResultSelection") Then
		FunctionalOptions = AssetAndLiabilityItem.FunctionalOptions.Unload();
		FunctionalOptionLinks = AssetAndLiabilityItem.FunctionalOptionLinks;
	Else
		FunctionalOptions = AssetAndLiabilityItem.FunctionalOptions;
		If SettingsComposer = Undefined Then
			FunctionalOptionLinks = Common.ObjectAttributeValue(
				AssetAndLiabilityItem.Ref, "FunctionalOptionLinks");
		EndIf;
	EndIf;
	
	If FunctionalOptions.Count() = 0 Then
		Return True;
	EndIf;
	
	If SettingsComposer = Undefined Then
		SettingsComposer = New DataCompositionSettingsComposer();
		InitializeSettingsComposerWithFunctionalOptions(SettingsComposer, FunctionalOptions);
		CommunicationSettingsForFunctionalOptions = FunctionalOptionLinks.Get();
		If TypeOf(CommunicationSettingsForFunctionalOptions) = Type("DataCompositionSettings") Then
			SettingsComposer.LoadSettings(CommunicationSettingsForFunctionalOptions);
		EndIf;
	EndIf;
	
	Return UsingAccountingSectionForFunctionalOptions(SettingsComposer.Settings.Filter);
	
EndFunction

#EndRegion

#Region Private

#Region FillingElementsWithInitialData

Function NewDataLayoutSelection(Field = Undefined, Value = Undefined, Var_ComparisonType = Undefined)
	
	DataCompositionFilter = New DataCompositionFilter();
	
	If Field <> Undefined Then
		NewDataLayoutSelectionElement(DataCompositionFilter, Field, Value, Var_ComparisonType);
	EndIf;
	
	Return DataCompositionFilter;
	
	If Field <> Undefined Then
		NewDataLayoutSelectionElement(DataCompositionFilter, Field, Value, Var_ComparisonType);
	EndIf;
	
	Return DataCompositionFilter;
	
EndFunction

Function NewDataLayoutSelectionElement(CollectionOfFilter, Field, Value = Undefined, Var_ComparisonType = Undefined)
	
	If TypeOf(Field) = Type("DataCompositionFilterItemsGroupType") Then
		NewItem = DataCompositionClientServer.AddSelectionGroup(CollectionOfFilter.Items, Field);
	ElsIf TypeOf(Field) = Type("String") Then
		FilterField = New DataCompositionField(Field);
		
		If TypeOf(Value) = Type("Array") Then
			FilterValue = New ValueList();
			FilterValue.LoadValues(Value);
		Else
			FilterValue = Value;
		EndIf;
		
		If Var_ComparisonType <> Undefined Then
			TypeOfSelectionComparison = Var_ComparisonType;
		ElsIf TypeOf(FilterValue) = Type("ValueList") Then
			TypeOfSelectionComparison = DataCompositionComparisonType.InList;
		Else
			TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
		EndIf;
		
		NewItem = DataCompositionClientServer.AddFilter(CollectionOfFilter, FilterField, FilterValue, TypeOfSelectionComparison);
	Else
		NewItem = Undefined;
	EndIf;
	
	Return NewItem;
	
EndFunction

Procedure FillInDataSourceSelection(Item, FilterDetails)
	
	If Not (ValueIsFilled(Item.DataSource) And FilterDetails.Items.Count() > 0) Then
		Item.Filterdata_ = Undefined;
		Return;
	EndIf;
	
	SettingsComposer = New DataCompositionSettingsComposer();
	InitializeSettingsComposerWithDataSource(SettingsComposer, Item.DataSource);
	DataCompositionClientServer.CopyElements(SettingsComposer.Settings.Filter, FilterDetails);
	
	Item.Filterdata_ = New ValueStorage(SettingsComposer.Settings);
	
EndProcedure

Procedure FillInSelectionOfObjectsSettings(Item, FilterDetails)
	
	If Not (ValueIsFilled(Item.SettingObjectSource) And FilterDetails.Items.Count() > 0) Then
		Item.SelectingConfigurationObjects = Undefined;
		Return;
	EndIf;
	
	SettingsComposer = New DataCompositionSettingsComposer();
	InitializeSettingsComposerWithSettingsObject(SettingsComposer, Item.SettingObjectSource);
	DataCompositionClientServer.CopyElements(SettingsComposer.Settings.Filter, FilterDetails);
	
	Item.SelectingConfigurationObjects = New ValueStorage(SettingsComposer.Settings);
	
EndProcedure

Procedure AddFunctionalOption(OptionsTable, FunctionalOptionName)
	
	NewRow = OptionsTable.Add();
	NewRow.FunctionalOptionName = FunctionalOptionName;
	
EndProcedure

Procedure FillInLinksOfFunctionalOptions(Item)
	
	If Not ValueIsFilled(Item.FunctionalOptions) Or Item.FunctionalOptions.Count() = 0 Then
		Item.FunctionalOptionLinks = Undefined;
		Return;
	EndIf;
	
	SettingsComposer = New DataCompositionSettingsComposer();
	InitializeSettingsComposerWithFunctionalOptions(SettingsComposer, Item.FunctionalOptions);
	Filter_Settings = SettingsComposer.Settings.Filter;
	
	If Item.FunctionalOptions.Count() = 1 Then
		FunctionalOptionName = Item.FunctionalOptions[0].FunctionalOptionName;
		DataCompositionClientServer.AddFilter(Filter_Settings, FunctionalOptionName, True);
	
	ElsIf Item.Parent = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProvisionsForImpairment Then
		SelectionGroupAnd = DataCompositionClientServer.AddSelectionGroup(Filter_Settings.Items, DataCompositionFilterItemsGroupType.AndGroup);
		If Item.FunctionalOptions.Count() = 2 Then
			For Each TSRow In Item.FunctionalOptions Do
				DataCompositionClientServer.AddFilter(SelectionGroupAnd, TSRow.FunctionalOptionName, True);
			EndDo;
		Else
			SelectionGroupOr = DataCompositionClientServer.AddSelectionGroup(SelectionGroupAnd.Items, DataCompositionFilterItemsGroupType.OrGroup);
			OptionNameProvisionsForImpairment = Metadata.FunctionalOptions.AccualInventoryImpairmentProvision.Name;
			For Each TSRow In Item.FunctionalOptions Do
				If TSRow.FunctionalOptionName = OptionNameProvisionsForImpairment Then
					DataCompositionClientServer.AddFilter(SelectionGroupAnd, TSRow.FunctionalOptionName, True);
				Else
					DataCompositionClientServer.AddFilter(SelectionGroupOr, TSRow.FunctionalOptionName, True);
				EndIf;
			EndDo;
		EndIf;
	
	ElsIf Item.PredefinedDataName = "LiabilitiesForUnpaidVAT" Then
		SelectionGroupAnd = DataCompositionClientServer.AddSelectionGroup(Filter_Settings.Items, DataCompositionFilterItemsGroupType.AndGroup);
		For Each TSRow In Item.FunctionalOptions Do
			DataCompositionClientServer.AddFilter(SelectionGroupAnd, TSRow.FunctionalOptionName, True);
		EndDo;
	Else
		SelectionGroupOr = DataCompositionClientServer.AddSelectionGroup(Filter_Settings.Items, DataCompositionFilterItemsGroupType.OrGroup);
		For Each TSRow In Item.FunctionalOptions Do
			DataCompositionClientServer.AddFilter(SelectionGroupOr, TSRow.FunctionalOptionName, True);
		EndDo;
	EndIf;
	
	Item.FunctionalOptionLinks = New ValueStorage(SettingsComposer.Settings);
	
EndProcedure

Procedure AddResources(ResourceTable, ResourceNames, ZoomRatio = 1, Factor = Undefined)
	
	ArrayOfResourceNames = ArrayOfObjectNames(ResourceNames);
	FillInIndicator = ResourceTable.Columns.Find("Factor") <> Undefined;
	
	If FillInIndicator And Factor = Undefined Then
		Factor = Enums.IndicatorsOfAnalyticalRegisters.Sum;
	EndIf;
	
	For Each ResourceName In ArrayOfResourceNames Do
		NewRow = ResourceTable.Add();
		NewRow.ResourceName = ResourceName;
		NewRow.ZoomRatio = ZoomRatio;
		If FillInIndicator Then
			NewRow.Factor = Factor;
		EndIf;
	EndDo;
	
EndProcedure

Procedure DeleteResources(ResourceTable, ResourceNames)
	
	ArrayOfResourceNames = ArrayOfObjectNames(ResourceNames);
	
	For Each ResourceName In ArrayOfResourceNames Do
		LinesToDelete = ResourceTable.FindRows(New Structure("ResourceName", ResourceName));
		For Each RowToDelete In LinesToDelete Do
			ResourceTable.Delete(RowToDelete);
		EndDo;;
	EndDo;
	
EndProcedure

Procedure AddAdditionalCostIndicators(TableOfIndicators)
	
	IndicatorsOfAnalyticalRegisters = Enums.IndicatorsOfAnalyticalRegisters;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.CostExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "CostExcludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.CostExcludingVAT;
	NewRow.ResourceGroup = QuantitativeAccountingResourcesGroup();
	NewRow.ResourceName = "Count";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.VATCostAmount;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "Cost";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.VATCostAmount;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "CostExcludingVAT";
	NewRow.ZoomRatio = -1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "AdditionalExpensesExcludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "LaborCosts";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ItemizedFixedCostsExcludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ItemizedVariableCostsExcludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "AddExpensesForGoods";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ItemizedFixedCostsIncludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ItemizedVariableCostsIncludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "AdditionalExpensesExcludingVAT";
	NewRow.ZoomRatio = -1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ItemizedFixedCostsExcludingVAT";
	NewRow.ZoomRatio = -1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ItemizedVariableCostsExcludingVAT";
	NewRow.ZoomRatio = -1;
	
EndProcedure

Procedure AddAdditionalIndicatorsOfDeviationsInCost(TableOfIndicators)
	
	IndicatorsOfAnalyticalRegisters = Enums.IndicatorsOfAnalyticalRegisters;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "AdditionalExpensesExcludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "CostVariancesExcludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "AdditionalExpensesIncludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "CostVariancesIncludingVAT";
	NewRow.ZoomRatio = 1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "AdditionalExpensesExcludingVAT";
	NewRow.ZoomRatio = -1;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "CostVariancesExcludingVAT";
	NewRow.ZoomRatio = -1;
	
EndProcedure

Procedure AddAdditionalIndicatorsForExciseCalculations(TableOfIndicators)
	
	IndicatorsOfAnalyticalRegisters = Enums.IndicatorsOfAnalyticalRegisters;
	
	NewRow = TableOfIndicators.Add();
	NewRow.Factor = IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT;
	NewRow.ResourceGroup = ManagementAccountingResourcesGroup();
	NewRow.ResourceName = "ExciseAmountInCurrencyMgmt";
	NewRow.ZoomRatio = 1;
	
EndProcedure

Procedure AddPathToExtDimensionData(ExtDimensionPathTable, ExtDimensionType, DataPath)
	
	NewRow = ExtDimensionPathTable.Add();
	NewRow.ExtDimensionType = ExtDimensionType;
	NewRow.DataPath = DataPath;
	
EndProcedure

#EndRegion

#Region AccessToObjectsOfFinancialAccounting

// Returns a request to get a list and properties of financial accounting objects for setting up accounts.
// 
// Parameters:
//  AccountingSettings - See FinancialAccounting_Settings
//  ArticleSelectionSettings - See SettingsForSelectingItemsOfAssetsLiabilities
// 
// Returns:
//  Query
// 
Function RequestForFinancialAccountingObjects(AccountingSettings, ArticleSelectionSettings)
	
	QueryText = "
	|SELECT
	|	AssetLiabilityItems.Ref AS Ref,
	|	CASE
	|		WHEN NOT AssetLiabilityItems.Predefined
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		WHEN AssetLiabilityItems.Ref = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.SettlementsWithEmployees)
	|		WHEN AssetLiabilityItems.Ref = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.SettlementsWithEmployees)
	|		WHEN AssetLiabilityItems.Ref = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.FiscalSettlements)
	|		ELSE AssetLiabilityItems.Parent
	|	END AS Parent
	|INTO TTItemsOfAssetsLiabilities
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|WHERE
	|	NOT AssetLiabilityItems.DeletionMark
	|	AND &ConditionsForAccountingSettings
	|	AND &ConditionsForSelectionSettings
	|INDEX BY
	|	Ref,
	|	Parent
	|
	|;
	|
	|SELECT
	|	AssetLiabilityItems.Ref AS AccountingObject,
	|	AssetLiabilityItems.Parent AS Parent,
	|	PRESENTATION(AssetLiabilityItems.Ref) AS AccountingObjectPresentation,
	|	PRESENTATION(CASE
	|		WHEN AssetLiabilityItems.Parent = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN &OtherAssetsLiabilitiesPresentation
	|		ELSE AssetLiabilityItems.Parent
	|	END) AS ParentPresentation,
	|	CASE
	|		WHEN AssetLiabilityItems.Parent = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN &OtherAssetsLiabilitiesOrder + AttributesOfArticles.AddlOrderingAttribute
	|		WHEN AssetLiabilityItems.Parent <> AttributesOfArticles.Parent
	|			THEN ParentsAttributes.AddlOrderingAttribute + AttributesOfArticles.AddlOrderingAttribute
	|		ELSE AttributesOfArticles.AddlOrderingAttribute
	|	END AS Order,
	|	AttributesOfArticles.DataSource AS DataSource,
	|	AttributesOfArticles.NotOwnedControlledValues AS ImproperValues,
	|	AttributesOfArticles.AllocationOfLongTermAssetsAndLiabilities AS AllocationOfLongTermAssetsAndLiabilities,
	|	AttributesOfArticles.LedgerAccountsInEntrySettings AS LedgerAccountsInEntrySettings,
	|	AttributesOfArticles.SettingObjectSource AS SettingObjectSource,
	|	AttributesOfArticles.SelectingConfigurationObjects AS SelectingConfigurationObjects,
	|	AttributesOfArticles.DetailedSettingsSource AS DetailedSettingsSource,
	|	AttributesOfArticles.FunctionalOptions AS FunctionalOptions,
	|	AttributesOfArticles.FunctionalOptionLinks AS FunctionalOptionLinks,
	|	&AdditionalSelectionFields
	|FROM
	|	TTItemsOfAssetsLiabilities AS AssetLiabilityItems
	|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AttributesOfArticles
	|	ON AssetLiabilityItems.Ref = AttributesOfArticles.Ref
	|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS ParentsAttributes
	|	ON AssetLiabilityItems.Parent = ParentsAttributes.Ref
	|ORDER BY
	|	Order
	|";
	
	ConditionLinesForAccountingSettings = New Array();
	SelectionConditionsAndSettingsLines = New Array();
	
	If Not AccountingSettings.RevenueAccountingWithVAT
	 Or Not AccountingSettings.RevenueAccountingExcludingVAT
	 Or Not AccountingSettings.FormationOfCorrespondence Then
		RowsOfExcludedValues = New Array();
		LineSplitter = "," + Chars.LF + Chars.Tab;
		
		If Not AccountingSettings.FormationOfCorrespondence Then
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RetailCustomerAccountsReceivables)");
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ARAPSettlements)");
		EndIf;
		
		If Not AccountingSettings.RevenueAccountingExcludingVAT Then
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.SalesRevenue)");
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RevenueServicesAndAssets)");
		EndIf;
		
		If Not AccountingSettings.RevenueAccountingWithVAT Then
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RevenueFromSalesWithVAT)");
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OtherRevenueWithVAT)");
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATFromSales)");
			RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.NDSSOfOtherSales)");
		EndIf;
		
		ConditionLinesForAccountingSettings.Add("NOT AssetLiabilityItems.Ref IN (
			|	" + StrConcat(RowsOfExcludedValues, LineSplitter) + ")");
	EndIf;
	
	If Not AccountingSettings.AccountingForImproperValues Then
		ConditionLinesForAccountingSettings.Add("NOT AssetLiabilityItems.NotOwnedControlledValues");
	EndIf;
	
	If ArticleSelectionSettings = Undefined Then
		SelectionConditionsAndSettingsLines.Add("AssetLiabilityItems.Kind <> VALUE(Enum.AssetAndLiabilityItemKinds.EmptyRef)");
	Else
		If ValueIsFilled(ArticleSelectionSettings.Kind) Then
			SelectionConditionsAndSettingsLines.Add("AssetLiabilityItems.Kind IN (&ArticlesKinds)");
		Else
			SelectionConditionsAndSettingsLines.Add("AssetLiabilityItems.Kind <> VALUE(Enum.AssetAndLiabilityItemKinds.EmptyRef)");
		EndIf;
		
		If ValueIsFilled(ArticleSelectionSettings.Ref) Then
			SelectionConditionsAndSettingsLines.Add("AssetLiabilityItems.Ref IN (&Objects_Accounting)");
		EndIf;
		
		If ValueIsFilled(ArticleSelectionSettings.TypeOfAccountingData) Then
			SelectionConditionsAndSettingsLines.Add("AssetLiabilityItems.TypeOfAccountingData IN (&AccountingDataTypes)");
		EndIf;
		
		If ArticleSelectionSettings.ThereIsDataSource <> Undefined Then
			SelectionConditionsAndSettingsLines.Add(
				?(ArticleSelectionSettings.ThereIsDataSource = True, "NOT ", "")
				+ "AssetLiabilityItems.DataSource = """"");
		EndIf;
		
		If ArticleSelectionSettings.LedgerAccountsInEntrySettings <> Undefined Then
			SelectionConditionsAndSettingsLines.Add(
				?(ArticleSelectionSettings.LedgerAccountsInEntrySettings = True, "", "NOT ")
				+ "AssetLiabilityItems.LedgerAccountsInEntrySettings");
		EndIf;
	EndIf;
	
	LineSplitter = Chars.LF + Chars.Tab + "And ";
	
	If ConditionLinesForAccountingSettings.Count() > 0 Then
		ConditionsForAccountingSettings = StrConcat(ConditionLinesForAccountingSettings, LineSplitter);
	Else
		ConditionsForAccountingSettings = "TRUE";
	EndIf;
	
	If SelectionConditionsAndSettingsLines.Count() > 0 Then
		ConditionsForSelectionSettings = StrConcat(SelectionConditionsAndSettingsLines, LineSplitter);
	Else
		ConditionsForSelectionSettings = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionsForAccountingSettings", ConditionsForAccountingSettings);
	QueryText = StrReplace(QueryText, "&ConditionsForSelectionSettings", ConditionsForSelectionSettings);
	
	Query = New Query(QueryText);
	Query.SetParameter("OtherAssetsLiabilitiesOrder", 999999);
	Query.SetParameter("OtherAssetsLiabilitiesPresentation", NStr("vi = 'Tài sản và nợ phải trả khác';
																	|ru = 'Прочие активы и обязательства';
																	|en = 'Other assets and liabilities'; fa = 'سایر دارایی‌ها و بدهی‌ها';
																	|it = 'Прочие активы и обязательства';
																	|pl = 'Pozostałe aktywa i zobowiązania';
																	|tr = 'Diğer varlıklar ve yükümlülükler'"));
	
	If ArticleSelectionSettings <> Undefined Then
		Query.SetParameter("ArticlesKinds", TMCommonUseClientServer.Array(ArticleSelectionSettings.Kind));
		Query.SetParameter("Objects_Accounting", TMCommonUseClientServer.Array(ArticleSelectionSettings.Ref));
		Query.SetParameter("AccountingDataTypes", TMCommonUseClientServer.Array(ArticleSelectionSettings.TypeOfAccountingData));
	EndIf;
	
	Return Query;
	
EndFunction

// Supplements the table of financial accounting objects with properties for accessing data.
// If any parameter is an expression of the query language, then the field descriptions in it must contain
// the alias of the data source obtained through the function of the financial accounting data of the balance registers.The data source alias is silent().
// If the parameter is only a field name, including a dereference separated by a dot, it can be specified without an alias of the data source.
// It is allowed to use request parameters from the function of the International accounting data of financial registers.Financial Register data requests().
// It is allowed to use string templates from the International Financial Register Data collection function.Request textsrecording registers().
// 
// Parameters:
//  AccountingSettings - See FinancialAccounting_Settings
//  DescriptionOfAccountingObjects - See NewTableOfFinancialAccountingObjects
// 
Procedure AddDescriptionOfAccountingObjectsToGetData(AccountingSettings, DescriptionOfAccountingObjects)
	
	MetaAccumulationRegisters = Metadata.AccumulationRegisters;
	IndicatorsOfAnalyticalRegisters = Enums.IndicatorsOfAnalyticalRegisters;
	AddDescriptionOfServiceObjects = DescriptionOfAccountingObjects.Count() > 1;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(ProvisionsForImpairmentOfWorkInProgress, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "FinancialAccountingDimension";
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(MaterialsAndWorkInBusinessUnit, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "FinancialAccountingDimension";
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(MaterialsOfWorkInProgress, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "FinancialAccountingDimension";
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(GoodsMaterialsAcceptedForStorageInProduction, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "FinancialAccountingDimension";
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(MaterialsAcceptedForProcessingInProduction, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "FinancialAccountingDimension";
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(LiabilitiesForGoodsReceivedNotInvoiced, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "UNDEFINED";
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(LiabilitiesForUnpaidVAT, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathRecordFinID = "&IDOfUnusedFinRecord";
		If AddDescriptionOfServiceObjects Then
			SuppressSourceDataWithoutSelection(DescriptionOfAccountingObject_);
		EndIf;
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(PrepaymentsToVendors, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DebitCondition = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		DescriptionOfAccountingObject_.ConditionCredit = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(VendorAccountsReceivable, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.InversionOfRegisteredRecords = True;
		DescriptionOfAccountingObject_.DebitCondition = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		DescriptionOfAccountingObject_.ConditionCredit = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(PrepaymentsFromCustomers, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.InversionOfRegisteredRecords = True;
		DescriptionOfAccountingObject_.DebitCondition = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		DescriptionOfAccountingObject_.ConditionCredit = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(CustomersAccountsReceivable, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DebitCondition = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		DescriptionOfAccountingObject_.ConditionCredit = StrReplace(
			"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(Taxes, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "Dimension";
	EndIf;
	
	
	If AddDescriptionOfServiceObjects Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(TicketsBooking, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			CopyOfDescriptionOfAccountingObject = CopyOfDescriptionOfAccountingObject(DescriptionOfAccountingObject_);
			DeleteResources(CopyOfDescriptionOfAccountingObject.ManResources, "PrepaymentMan");
			DeleteResources(CopyOfDescriptionOfAccountingObject.LocalResources, "PrepaymentLocal");
			DeleteResources(CopyOfDescriptionOfAccountingObject.ShaftResources, "Prepayment");
			CopyOfDescriptionOfAccountingObject.Indicators.Delete(IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
			CopyOfDescriptionOfAccountingObject.InversionOfRegisteredRecords = True;
			CopyOfDescriptionOfAccountingObject.DebitCondition = StrReplace(
				"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			CopyOfDescriptionOfAccountingObject.ConditionCredit = StrReplace(
				"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			
			DeleteResources(DescriptionOfAccountingObject_.ManResources, "ARAPMan");
			DeleteResources(DescriptionOfAccountingObject_.LocalResources, "DebtLocal");
			DeleteResources(DescriptionOfAccountingObject_.ShaftResources, "Debt");
			DescriptionOfAccountingObject_.Indicators.Delete(IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
			DescriptionOfAccountingObject_.DebitCondition = StrReplace(
				"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.ConditionCredit = StrReplace(
				"DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		EndIf;
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(VATAccountsPayable, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		If AccountingSettings.RevenueAccountingWithVAT And AccountingSettings.RevenueAccountingExcludingVAT Then
			If AddDescriptionOfServiceObjects Then
				CopyOfDescriptionOfAccountingObject = CopyOfDescriptionOfAccountingObject(DescriptionOfAccountingObject_);
				CopyOfDescriptionOfAccountingObject.DataPathRecordFinID = StrReplace(
					"CASE
					|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
					|			THEN DataSourceAlias.ARAPObject.UUID
					|		WHEN VALUETYPE(DataSourceAlias.Recorder) IN (&TypesOfRetailSalesDocuments)
					|		  OR VALUETYPE(DataSourceAlias.Recorder) IN (&TypesOfRetailReturnsDocuments)
					|			THEN SUBSTRING(DataSourceAlias.FinRecordID, 29, 8) +
					|				  SUBSTRING(DataSourceAlias.FinRecordID, 9, 20) +
					|				  SUBSTRING(DataSourceAlias.FinRecordID, 1, 8)
					|		ELSE &IDOfUnusedFinRecord
					|	END",
					"DataSourceAlias",
					FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
				CopyOfDescriptionOfAccountingObject.DataPathRowId = "FinRecordID";
				AddResources(CopyOfDescriptionOfAccountingObject.ResourcesQuantity, "0", 0, IndicatorsOfAnalyticalRegisters.VATAmount);
				FillInSignsOfCorrespondenceAccounting(CopyOfDescriptionOfAccountingObject, "RevenueExcludingVAT", True);
			EndIf;
		ElsIf AccountingSettings.RevenueAccountingExcludingVAT Then
			DescriptionOfAccountingObject_.DataPathRecordFinID = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|			THEN DataSourceAlias.ARAPObject.UUID
				|		ELSE DataSourceAlias.FinRecordID
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.DataPathRowId = "FinRecordID";
		EndIf;
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(VATForShipmentsWithDeferredTransferOfTitle, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		If AccountingSettings.RevenueAccountingWithVAT And AccountingSettings.RevenueAccountingExcludingVAT Then
			If AddDescriptionOfServiceObjects Then
				CopyOfDescriptionOfAccountingObject = CopyOfDescriptionOfAccountingObject(DescriptionOfAccountingObject_);
				CopyOfDescriptionOfAccountingObject.DataPathRecordFinID = StrReplace(
					"CASE
					|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
					|			THEN DataSourceAlias.ARAPObject.UUID
					|		ELSE &IDOfUnusedFinRecord
					|	END",
					"DataSourceAlias",
					FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
				CopyOfDescriptionOfAccountingObject.DataPathSettingUpHouseholdOperations = StrReplace(
					"CASE
					|		WHEN DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
					|			THEN DataSourceAlias.BusinessTransactionSetting
					|		WHEN VALUETYPE(DataSourceAlias.Recorder) = TYPE(Document.CustomerInvoiceServicesAndAssets)
					|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit)
					|		ELSE DataSourceAlias.BusinessTransactionSetting
					|	END",
					"DataSourceAlias",
					FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
				AddResources(CopyOfDescriptionOfAccountingObject.ResourcesQuantity, "0", 0, IndicatorsOfAnalyticalRegisters.VATAmount);
				FillInSignsOfCorrespondenceAccounting(CopyOfDescriptionOfAccountingObject, "RevenueExcludingVAT", True);
				SuppressSourceDataWithoutSelection(CopyOfDescriptionOfAccountingObject);
			EndIf;
		ElsIf AccountingSettings.RevenueAccountingExcludingVAT Then
			DescriptionOfAccountingObject_.DataPathRecordFinID = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|			THEN DataSourceAlias.ARAPObject.UUID
				|		ELSE DataSourceAlias.FinRecordID
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.DataPathSettingUpHouseholdOperations = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
				|			THEN DataSourceAlias.BusinessTransactionSetting
				|		WHEN VALUETYPE(DataSourceAlias.Recorder) = TYPE(Document.CustomerInvoiceServicesAndAssets)
				|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit)
				|		ELSE DataSourceAlias.BusinessTransactionSetting
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		EndIf;
	EndIf;
	
	If AccountingSettings.RevenueAccountingWithVAT Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(RevenueFromSalesWithVAT, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			DescriptionOfAccountingObject_.DebitCondition = "FALSE";
			DescriptionOfAccountingObject_.ConditionCredit = "TRUE";
			DescriptionOfAccountingObject_.DataPathRecordFinID = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|			THEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup.UUID
				|		ELSE DataSourceAlias.FinRecordID
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.DataPathRowId = "FinRecordID";
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
			If AccountingSettings.RevenueAccountingExcludingVAT Then
				FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, "RevenueExcludingVAT", False);
			EndIf;
		EndIf;
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(OtherRevenueWithVAT, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			DescriptionOfAccountingObject_.DebitCondition = "FALSE";
			DescriptionOfAccountingObject_.ConditionCredit = "TRUE";
			DescriptionOfAccountingObject_.DataPathRecordFinID = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|			THEN DataSourceAlias.ARAPObject.UUID
				|		ELSE DataSourceAlias.FinRecordID
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.DataPathRowId = "FinRecordID";
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.FinancialInstrumentsARAP.Name);
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
			If AccountingSettings.RevenueAccountingExcludingVAT Then
				FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, "RevenueExcludingVAT", False);
			EndIf;
		EndIf;
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(VATFromSales, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			DescriptionOfAccountingObject_.DebitCondition = "TRUE";
			DescriptionOfAccountingObject_.ConditionCredit = "FALSE";
			DescriptionOfAccountingObject_.DataPathConfigurationObject = "ItemsLocationAttributes.Products.FinancialAccountingGroup";
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.VATRegisterRecords.Name);
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
			If VATAccountingERP.AccountingSettings().DateWhenRefundsAreReflectedInCorrectiveSF > '00010101' Then
				DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.VATInvoiced.Name);
			EndIf;
			If AccountingSettings.RevenueAccountingExcludingVAT Then
				FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, "RevenueExcludingVAT", False);
			EndIf;
		EndIf;
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(NDSSOfOtherSales, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			DescriptionOfAccountingObject_.DebitCondition = "TRUE";
			DescriptionOfAccountingObject_.ConditionCredit = "FALSE";
			DescriptionOfAccountingObject_.DataPathConfigurationObject = "IncomeItem.FinancialAccountingGroup";
			If AccountingSettings.RevenueAccountingExcludingVAT Then
				FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, "RevenueExcludingVAT", False);
			EndIf;
		EndIf;
	EndIf;
	
	If AccountingSettings.RevenueAccountingExcludingVAT Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(SalesRevenue, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			DescriptionOfAccountingObject_.DebitCondition = "FALSE";
			DescriptionOfAccountingObject_.ConditionCredit = "TRUE";
			DescriptionOfAccountingObject_.DataPathRecordFinID = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|			THEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup.UUID
				|		ELSE DataSourceAlias.FinRecordID
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.DataPathRowId = "FinRecordID";
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
			If AccountingSettings.RevenueAccountingWithVAT Then
				FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, "RevenueExcludingVAT", True);
			EndIf;
		EndIf;
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(RevenueServicesAndAssets, "AccountingObject");
		If DescriptionOfAccountingObject_ <> Undefined Then
			DescriptionOfAccountingObject_.DebitCondition = "FALSE";
			DescriptionOfAccountingObject_.ConditionCredit = "TRUE";
			DescriptionOfAccountingObject_.DataPathRecordFinID = StrReplace(
				"CASE
				|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
				|			THEN DataSourceAlias.ARAPObject.UUID
				|		ELSE DataSourceAlias.FinRecordID
				|	END",
				"DataSourceAlias",
				FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
			DescriptionOfAccountingObject_.DataPathRowId = "FinRecordID";
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.FinancialInstrumentsARAP.Name);
			DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
			If AccountingSettings.RevenueAccountingWithVAT Then
				FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, "RevenueExcludingVAT", True);
			EndIf;
		EndIf;
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(SaleCost, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DebitCondition = "TRUE";
		DescriptionOfAccountingObject_.ConditionCredit = "FALSE";
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.InventoryCost.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.GoodsCostVariances.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.OtherExpenses.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.VATInvoiced.Name);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(SellingExpenses_, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DebitCondition = "TRUE";
		DescriptionOfAccountingObject_.ConditionCredit = "FALSE";
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.InventoryCost.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.GoodsCostVariances.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.OtherExpenses.Name);
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.VATInvoiced.Name);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(SalesExcise, "AccountingObject");
	If DescriptionOfAccountingObject_ <> Undefined Then
		DescriptionOfAccountingObject_.DebitCondition = "TRUE";
		DescriptionOfAccountingObject_.ConditionCredit = "FALSE";
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "ItemsLocationAttributes.Products.FinancialAccountingGroup";
		DescriptionOfAccountingObject_.CorDataSources.Add(MetaAccumulationRegisters.RegisterRecordsByExcises.Name);
	EndIf;
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("DataSource", MetaAccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	TheStructureOfTheSearch.Insert("LedgerAccountsInEntrySettings", False);
	LinesOfOtherAssetsLiabilities = DescriptionOfAccountingObjects.FindRows(TheStructureOfTheSearch);
	For Each DescriptionOfAccountingObject_ In LinesOfOtherAssetsLiabilities Do
		DescriptionOfAccountingObject_.DataPathConfigurationObject = "GLAccountSettings";
	EndDo;
	
EndProcedure

// Returns a table of financial accounting objects with properties for setting up accounts and accessing data.
// The parameters of the same name as the parameters for reflecting the Registered Records of Accumulation registers in financial accounting
// are indicated if the value for the accounting object differs from the value for the Accumulation register as a whole
// or there is no value for the Accumulation register.
// 
// Returns:
//  ValueTable:
//  * AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems - Reference of the financial accounting object
//  * Presentation - String - Name of the financial accounting object
//  * DataSource - String - The name of the Accumulation register that keeps records of the fin object.accounting
//  * Filterdata_ - DataCompositionFilter - Selecting register data for the fin object.accounting
//  * DebitCondition - String - A condition in the query language for determining the debit RegisteredRecords attribute.
//  * ConditionCredit - String - A condition in the query language for determining the credit RegisteredRecorded attribute.
//  * InversionOfRegisteredRecords - Boolean - Only for Balance registers. Matching the register data for the fin object.according to the rule, Receipt = Credit, Expense = Debit. Only the True value is taken into account.
//  * DataPathConfigurationObject - String - The path of the register data selection corresponding to the settings objects, in the context of which the accounting accounts are specified.
//  * PathToDataLineOfBusiness - String - The path of fetching the activity direction value from the register data.
//  * DataPathRecordFinID - String - The path of fetching the register record ID value.
//  * DataPathSettingUpHouseholdOperations - String - The path of fetching the setting value of a business transaction.
//  * DataPathRowId - String - The path of fetching the value of the register string identifier.
//  * PathsToExtdimensionData - ValueTable - Refinement of sub-konto sampling paths. Specified in the case of an incorrect result of selecting the value of the sub-konto from the sources of the sub-konto register:
//   ** ExtDimensionType - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - Extra dimension type
//   ** DataPath - String - The path of selecting the subconto value
//  * ManResources - See NewResourceTable
//  * LocalResources - See NewResourceTable
//  * ShaftResources - See NewResourceTable
//  * ResourcesQuantity - See NewResourceTable
//  * Indicators - Map of KeyAndValue - LongDesc:
//   ** Key - EnumRef.IndicatorsOfAnalyticalRegisters - Indicator value
//   ** Value - See NewDescriptionOfIndicator
//  * CorDataSources - Array of String - An array of strings with the names of Accumulation registers in which the corresponding accounting objects are recorded. Used for revenue registers.
//  * ImproperValues - Boolean - A sign of accounting for improper controlled values in an object
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean - The data of the accounting object is divided into short-term and long-term, the attribute is translated from the data source.
//  * LedgerAccountsInEntrySettings - Boolean - Whether to specify accounting accounts in the transaction settings
//  * DescriptionOfTheConfigurationObjectTypes - TypeDescription - description of the types of the configuration object
//  * DescriptionOfTypesOfDetailedSettings - TypeDescription - description of the types of the detailed configuration object
//  * SelectingConfigurationObjects - DataCompositionFilter - selecting configuration objects
//  * SignsOfCorrespondenceAccounting - See NewTableSignsOfCorrespondenceAccounting
// 
Function NewTableOfFinancialAccountingObjects()
	
	TableOfAccountingObjects = New ValueTable();
	TableOfAccountingObjects.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	TableOfAccountingObjects.Columns.Add("Presentation", Common.StringTypeDetails(150));
	TableOfAccountingObjects.Columns.Add("DataSource", Common.StringTypeDetails(150));
	TableOfAccountingObjects.Columns.Add("Filterdata_", New TypeDescription("DataCompositionFilter"));
	TableOfAccountingObjects.Columns.Add("DebitCondition", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("ConditionCredit", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("InversionOfRegisteredRecords", New TypeDescription("Boolean"));
	TableOfAccountingObjects.Columns.Add("DataPathConfigurationObject", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("PathToDataLineOfBusiness", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("DataPathRecordFinID", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("DataPathSettingUpHouseholdOperations", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("DataPathRowId", Common.StringTypeDetails(1000));
	TableOfAccountingObjects.Columns.Add("PathsToExtdimensionData", New TypeDescription("ValueTable"));
	TableOfAccountingObjects.Columns.Add("ManResources", New TypeDescription("ValueTable"));
	TableOfAccountingObjects.Columns.Add("LocalResources", New TypeDescription("ValueTable"));
	TableOfAccountingObjects.Columns.Add("ShaftResources", New TypeDescription("ValueTable"));
	TableOfAccountingObjects.Columns.Add("ResourcesQuantity", New TypeDescription("ValueTable"));
	TableOfAccountingObjects.Columns.Add("Indicators", New TypeDescription("Map"));
	TableOfAccountingObjects.Columns.Add("CorDataSources", New TypeDescription("Array"));
	TableOfAccountingObjects.Columns.Add("ImproperValues", New TypeDescription("Boolean"));
	TableOfAccountingObjects.Columns.Add("AllocationOfLongTermAssetsAndLiabilities", New TypeDescription("Boolean"));
	TableOfAccountingObjects.Columns.Add("LedgerAccountsInEntrySettings", New TypeDescription("Boolean"));
	TableOfAccountingObjects.Columns.Add("DescriptionOfTheConfigurationObjectTypes", New TypeDescription("TypeDescription"));
	TableOfAccountingObjects.Columns.Add("DescriptionOfTypesOfDetailedSettings", New TypeDescription("TypeDescription"));
	TableOfAccountingObjects.Columns.Add("SelectingConfigurationObjects", New TypeDescription("DataCompositionFilter"));
	TableOfAccountingObjects.Columns.Add("SignsOfCorrespondenceAccounting", New TypeDescription("ValueTable"));
	
	Return TableOfAccountingObjects;
	
EndFunction

// Returns a tree of financial accounting objects with properties for Presentation in forms.
// 
// Returns:
//  ValueTree:
//  * IsFolder - Boolean -
//  * AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems -
//  * Presentation - String -
//  * DataSource - String -
//  * ImproperValues - Boolean -
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean -
//  * DescriptionOfTheConfigurationObjectTypes - TypeDescription -
//  * DescriptionOfTypesOfDetailedSettings - TypeDescription -
//  * SelectingConfigurationObjects - DataCompositionFilter -
//
Function NewTreeOfFinancialAccountingObjects()
	
	TreeOfAccountingObjects = New ValueTree();
	TreeOfAccountingObjects.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	TreeOfAccountingObjects.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	TreeOfAccountingObjects.Columns.Add("Presentation", New TypeDescription("String"));
	TreeOfAccountingObjects.Columns.Add("DataSource", New TypeDescription("String"));
	TreeOfAccountingObjects.Columns.Add("ImproperValues", New TypeDescription("Boolean"));
	TreeOfAccountingObjects.Columns.Add("DescriptionOfTheConfigurationObjectTypes", New TypeDescription("TypeDescription"));
	TreeOfAccountingObjects.Columns.Add("DescriptionOfTypesOfDetailedSettings", New TypeDescription("TypeDescription"));
	TreeOfAccountingObjects.Columns.Add("SelectingConfigurationObjects", New TypeDescription("DataCompositionFilter"));
	TreeOfAccountingObjects.Columns.Add("AllocationOfLongTermAssetsAndLiabilities", New TypeDescription("Boolean"));
	
	Return TreeOfAccountingObjects;
	
EndFunction

// Returns a table of the composition of Accumulation Register resources for calculating amounts in the currencies of Upr. and Local accounting,
// the currency amount and the number and coefficients of these resources.
// 
// Returns:
//  ValueTable:
//   * ResourceName - String - Accumulation Register resource name
//   * ZoomRatio - Number - Accumulation register resource factor
//
Function NewResourceTable()
	
	ResourceTable = New ValueTable();
	ResourceTable.Columns.Add("ResourceName", Common.StringTypeDetails(150));
	ResourceTable.Columns.Add("ZoomRatio", Common.TypeDescriptionNumber(3));
	
	Return ResourceTable;
	
EndFunction

// Returns a table describing the correspondence of a financial accounting object with other objects
// that are possible if certain conditions are met.
// 
// Returns:
//  ValueTable:
//   * AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems - Corresponding object of financial accounting
//   * AccountingFlag - String - Name of the accounting feature that manages the correspondence of fin objects.accounting
//   * Value - Boolean - The value of the accounting attribute that allows correspondence of FIN objects.accounting
//
Function NewTableSignsOfCorrespondenceAccounting()
	
	SignsOfCorrespondenceAccounting = New ValueTable();
	SignsOfCorrespondenceAccounting.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	SignsOfCorrespondenceAccounting.Columns.Add("AccountingFlag", Common.StringTypeDetails(150));
	SignsOfCorrespondenceAccounting.Columns.Add("Value", New TypeDescription("Boolean"));
	
	Return SignsOfCorrespondenceAccounting;
	
EndFunction

Function UsingAccountingSectionForFunctionalOptions(FilterElement)
	
	TypeOfSelectionElement = TypeOf(FilterElement);
	
	ThisIsLogicalAddition = TypeOfSelectionElement = Type("DataCompositionFilterItemGroup")
		And FilterElement.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ThisIsLogicalMultiplication = TypeOfSelectionElement = Type("DataCompositionFilter")
		Or (TypeOfSelectionElement = Type("DataCompositionFilterItemGroup")
		And FilterElement.GroupType = DataCompositionFilterItemsGroupType.AndGroup);
	
	If ThisIsLogicalMultiplication Then
		AccountingSectionIsUsed = True;
		For Each SubordinateItem In FilterElement.Items Do
			If Not UsingAccountingSectionForFunctionalOptions(SubordinateItem) Then
				AccountingSectionIsUsed = False;
				Break;
			EndIf;
		EndDo;
	ElsIf ThisIsLogicalAddition Then
		AccountingSectionIsUsed = False;
		For Each SubordinateItem In FilterElement.Items Do
			If UsingAccountingSectionForFunctionalOptions(SubordinateItem) Then
				AccountingSectionIsUsed = True;
				Break;
			EndIf;
		EndDo;
	ElsIf TypeOfSelectionElement = Type("DataCompositionFilterItem") Then
		AccountingSectionIsUsed = GetFunctionalOption(String(FilterElement.LeftValue));
		FilterElement.RightValue = AccountingSectionIsUsed;
	Else
		AccountingSectionIsUsed = True;
	EndIf;
	
	Return AccountingSectionIsUsed;
	
EndFunction

Function ResourceTableNames()
	
	ResourceTableNames = New Array();
	ResourceTableNames.Add(ManagementAccountingResourcesGroup());
	ResourceTableNames.Add(RegulatedAccountingResourcesGroup());
	ResourceTableNames.Add(CurrencyAccountingResourcesGroup());
	ResourceTableNames.Add(QuantitativeAccountingResourcesGroup());
	
	Return ResourceTableNames;
	
EndFunction

Procedure FillInResourceTables(DescriptionOfAccountingObject_, SelectingRequestForAccountingObjects)
	
	ResourceTableNames = ResourceTableNames();
	
	For Each TableName In ResourceTableNames Do
		ResourceRequestResult = SelectingRequestForAccountingObjects[TableName]; // QueryResult -
		SelectionOfResources = ResourceRequestResult.Select();
		ResourceTable = NewResourceTable();
		
		While SelectionOfResources.Next() Do
			FillPropertyValues(ResourceTable.Add(), SelectionOfResources);
		EndDo;
		
		ResourceTable.Sort("ResourceName");
		DescriptionOfAccountingObject_[TableName] = ResourceTable;
	EndDo;
	
EndProcedure

Procedure FillInIndicatorDescriptions(DescriptionOfAccountingObject_, SelectingRequestForAccountingObjects)
	
	ResourceTableNames = ResourceTableNames();
	
	For Each TableName In ResourceTableNames Do
		ResourceRequestResult = SelectingRequestForAccountingObjects[TableName]; // QueryResult -
		SelectionOfResources = ResourceRequestResult.Select();
		
		While SelectionOfResources.Next() Do
			If DescriptionOfAccountingObject_.Indicators[SelectionOfResources.Factor] = Undefined Then
				DescriptionIndicator = NewDescriptionOfIndicator();
				DescriptionOfAccountingObject_.Indicators.Insert(SelectionOfResources.Factor, DescriptionIndicator);
			EndIf;
			
			ResourceTable = DescriptionOfAccountingObject_.Indicators[SelectionOfResources.Factor][TableName];
			FillPropertyValues(ResourceTable.Add(), SelectionOfResources);
		EndDo;
	EndDo;
	
	ResultOfMetricsRequest = SelectingRequestForAccountingObjects.AdditionalIndicators; // QueryResult -
	SelectionOfIndicators = ResultOfMetricsRequest.Select();
	
	While SelectionOfIndicators.Next() Do
		If ResourceTableNames.Find(SelectionOfIndicators.ResourceGroup) = Undefined Then
			Continue;
		EndIf;
		
		If DescriptionOfAccountingObject_.Indicators[SelectionOfIndicators.Factor] = Undefined Then
			DescriptionIndicator = NewDescriptionOfIndicator();
			DescriptionOfAccountingObject_.Indicators.Insert(SelectionOfIndicators.Factor, DescriptionIndicator);
		EndIf;
		
		ResourceTable = DescriptionOfAccountingObject_.Indicators[SelectionOfIndicators.Factor][SelectionOfIndicators.ResourceGroup];
		FillPropertyValues(ResourceTable.Add(), SelectionOfIndicators);
	EndDo;
	
EndProcedure

Procedure FillInPropertiesOfOtherAssetsLiabilities(DescriptionOfAccountingObject_)
	
	If DescriptionOfAccountingObject_.Filterdata_.Items.Count() = 0 Then
		NewItem = DescriptionOfAccountingObject_.Filterdata_.Items.Add(Type("DataCompositionFilterItem"));
		NewItem.LeftValue = New DataCompositionField("AssetRef");
		NewItem.ComparisonType = DataCompositionComparisonType.Equal;
		NewItem.RightValue = DescriptionOfAccountingObject_.AccountingObject;
	EndIf;
	
	MetaDataSourceOfOtherAssetsLiabilities = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	ResourcesOfSourceOfOtherAssetsLiabilities = MetaDataSourceOfOtherAssetsLiabilities.Resources;
	
	If DescriptionOfAccountingObject_.ManResources.Count() = 0 Then
		AddResources(DescriptionOfAccountingObject_.ManResources, ResourcesOfSourceOfOtherAssetsLiabilities.SumMan.Name);
	EndIf;
	
	If DescriptionOfAccountingObject_.LocalResources.Count() = 0 Then
		AddResources(DescriptionOfAccountingObject_.LocalResources, ResourcesOfSourceOfOtherAssetsLiabilities.SumCompl.Name);
	EndIf;
	
	If DescriptionOfAccountingObject_.Indicators.Count() = 0 Then
		DescriptionIndicator = NewDescriptionOfIndicator();
		AddResources(DescriptionIndicator.ManResources, ResourcesOfSourceOfOtherAssetsLiabilities.SumMan.Name);
		AddResources(DescriptionIndicator.LocalResources, ResourcesOfSourceOfOtherAssetsLiabilities.SumCompl.Name);
		DescriptionOfAccountingObject_.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, DescriptionIndicator);
	EndIf;
	
EndProcedure

Function CopyOfDescriptionOfAccountingObject(DescriptionOfAccountingObject_)
	
	DescriptionOfAccountingObjects = DescriptionOfAccountingObject_.Owner();
	CopyOfDescriptionOfAccountingObject = DescriptionOfAccountingObjects.Add();
	
	TabularSectionNames = ResourceTableNames();
	TabularSectionNames.Add("PathsToExtdimensionData");
	
	PropertiesToExclude = StrConcat(TabularSectionNames, ",");
	PropertiesToExclude = PropertiesToExclude + ",Indicators";
	
	FillPropertyValues(CopyOfDescriptionOfAccountingObject, DescriptionOfAccountingObject_,, PropertiesToExclude);
	
	For Each TabularSectionName In TabularSectionNames Do
		CopyOfDescriptionOfAccountingObject[TabularSectionName] = DescriptionOfAccountingObject_[TabularSectionName].Copy();
	EndDo;
	
	CopyOfDescriptionOfAccountingObject.Indicators = Common.CopyRecursive(DescriptionOfAccountingObject_.Indicators);
	
	Return CopyOfDescriptionOfAccountingObject;
	
EndFunction

Procedure SuppressSourceDataWithoutSelection(DescriptionOfAccountingObject_)
	
	DescriptionOfAccountingObjects = DescriptionOfAccountingObject_.Owner();
	
	UnusedData = DescriptionOfAccountingObjects.Add();
	UnusedData.AccountingObject = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef();
	UnusedData.DataSource = DescriptionOfAccountingObject_.DataSource;
	UnusedData.DataPathRecordFinID = "&IDOfUnusedFinRecord";
	
	ResourceTableNames = ResourceTableNames();
	
	For Each TableName In ResourceTableNames Do
		UnusedData[TableName] = DescriptionOfAccountingObject_[TableName].Copy();
	EndDo;
	
	UnusedData.PathsToExtdimensionData = DescriptionOfAccountingObject_.PathsToExtdimensionData.CopyColumns();
	
EndProcedure

Procedure FillInSignsOfCorrespondenceAccounting(DescriptionOfAccountingObject_, AccountingFlag, Value)
	
	SignsOfCorrespondenceAccounting = NewTableSignsOfCorrespondenceAccounting();
	
	If DescriptionOfAccountingObject_.AccountingObject = SalesRevenue
	 Or DescriptionOfAccountingObject_.AccountingObject = RevenueFromSalesWithVAT
	 Or DescriptionOfAccountingObject_.AccountingObject = VATAccountsPayable
	 Or DescriptionOfAccountingObject_.AccountingObject = VATForShipmentsWithDeferredTransferOfTitle Then
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = CustomersAccountsReceivable;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = PrepaymentsFromCustomers;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = RetailCustomerAccountsReceivables;
	EndIf;
	
	If DescriptionOfAccountingObject_.AccountingObject = RevenueServicesAndAssets
	 Or DescriptionOfAccountingObject_.AccountingObject = OtherRevenueWithVAT Then
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = CustomersAccountsReceivable;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = PrepaymentsFromCustomers;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = IssuedBorrowings;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = DepositsLoansLoansIssuedFee;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = DepositsLoansLoansIssuedInterest;
	EndIf;
	
	If DescriptionOfAccountingObject_.AccountingObject = VATFromSales
	 Or DescriptionOfAccountingObject_.AccountingObject = NDSSOfOtherSales Then
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = VATAccountsPayable;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = VATForShipmentsWithDeferredTransferOfTitle;
	EndIf;
	
	SignsOfCorrespondenceAccounting.FillValues(AccountingFlag, "AccountingFlag");
	SignsOfCorrespondenceAccounting.FillValues(Value, "Value");
	
	DescriptionOfAccountingObject_.SignsOfCorrespondenceAccounting = SignsOfCorrespondenceAccounting;
	
EndProcedure

#EndRegion

Function ArrayOfObjectNames(ObjectsNames)
	
	If TypeOf(ObjectsNames) = Type("String") Then
		Return StrSplit(ObjectsNames, ",");
	Else
		Return TMCommonUseClientServer.Array(ObjectsNames);
	EndIf;
	
EndFunction

Function DescriptionOfTypesByFullNameOfObject(FullObjectName)
	
	If IsBlankString(FullObjectName) Then
		Return New TypeDescription();
	EndIf;
	
	ObjectManager = Common.ObjectManagerByFullName(FullObjectName);
	EmptyRef = ObjectManager.EmptyRef();
	
	Return TMCommonUse.DescriptionOfTypesByType(TypeOf(EmptyRef));
	
EndFunction

Function SelectingLayoutFromSettingsStore(SettingsStorage)
	
	DataCompositionFilter = New DataCompositionFilter();
	
	DataCompositionSettings = SettingsStorage.Get();
	If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings") Then
		DataCompositionClientServer.CopyElements(DataCompositionFilter, DataCompositionSettings.Filter);
	EndIf;
	
	Return DataCompositionFilter;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "ChartsOfCharacteristicTypes.AssetLiabilityItems.FillItemsWithInitialData";
	Handler.Version = "*";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("c2228d01-4a2a-44ca-891a-e621c2762e30");
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.UpdateDataFillingProcedure = "ChartsOfCharacteristicTypes.AssetLiabilityItems.RegisterPredefinedItemsToUpdate";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật các mục tin của phần tử định trước trong hệ thống dạng đặc tính ""Dạng tài sản và nguồn vốn"" theo các cài đặt do các nhà phát triển chỉ định.';
							|ru = 'Обновляет реквизиты предопределенных элементов плана видов характеристик ""Статьи активов и пассивов"" согласно заданным разработчиками настройкам.';
							|en = 'Updates attributes of the predefined items of the ""Asset and liability items"" chart of characteristic types according to the settings set by developers.'; fa = 'Updates attributes of the predefined items of the ""Asset and liability items"" chart of characteristic types according to the settings set by developers.';
							|it = 'Обновляет реквизиты предопределенных элементов плана видов характеристик ""Статьи активов и пассивов"" согласно заданным разработчиками настройкам.';
							|pl = 'Updates attributes of the predefined items of the ""Asset and liability items"" chart of characteristic types according to the settings set by developers.';
							|tr = '""Varlıklar ve yükümlülükler kalemleri"" özellik türü listesindeki önceden tanımlanmış kalemlerin özelliklerini geliştiriciler tarafından belirlenen ayarlara göre günceller.'");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

EndProcedure

Procedure RegisterPredefinedItemsToUpdate(Parameters) Export
	
	InfobaseUpdate.RegisterPredefinedItemsToUpdate(
		Parameters, Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems);
	
EndProcedure

Procedure FillItemsWithInitialData(Parameters) Export
	
	PopulationSettings = InfobaseUpdate.PopulationSettings();
	InfobaseUpdate.FillItemsWithInitialData(Parameters, 
		Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems, PopulationSettings);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
