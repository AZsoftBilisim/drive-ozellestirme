#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of details
//                                 of the plan and types of characteristics.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	#Region BankAccounts
	Item = Items.Add();
	Item.PredefinedDataName = "BankAccounts";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CounterpartyBankAccounts"));
	TypesArray.Add(Type("CatalogRef.CompaniesBankAccounts"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài khoản ngân hàng';
																					|ru = 'Банковские счета';
																					|en = 'Bank accounts';
																					|it = 'Conti bancari';
																					|pl = 'Rachunki bankowe';
																					|tr = 'Banka hesapları'", LanguagesCodes); // @NStr-2
	Item.Code = "00001";
	#EndRegion
	
	#Region Booking
	Item = Items.Add();
	Item.PredefinedDataName = "Booking";
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.ElectronicTicketTransaction"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giao dịch với vé điện tử';
																					|ru = 'Операция с электронным билетом';
																					|en = 'Electronic ticket transaction';
																					|it = 'Electronic ticket transaction';
																					|pl = 'Electronic ticket transaction';
																					|tr = 'Elektronik bilet işlemi'", LanguagesCodes); // @NStr-2
	Item.Code = "00029";
	#EndRegion

	#Region KindsOfAssetsAndLiabilities
	Item = Items.Add();
	Item.PredefinedDataName = "KindsOfAssetsAndLiabilities";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.KindsOfAssetsAndLiabilities"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng tài sản và nợ phải trả';
																					|ru = 'Виды активов и обязательств';
																					|en = 'Kinds of assets and liabilities';
																					|it = 'Tipi di attivi e di obbligazioni';
																					|pl = 'Rodzaje aktywów i zobowiązań';
																					|tr = 'Varlık ve yükümlülük türleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00002";
	#EndRegion

	#Region SalaryTransactionKinds
	Item = Items.Add();
	Item.PredefinedDataName = "SalaryTransactionKinds";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng hoạt động tiền lương';
																					|ru = 'Виды операций по зарплате';
																					|en = 'Salary transaction types';
																					|it = 'Tipi di operazioni sullo stipendio';
																					|pl = 'Rodzaj operacji dla wynagrodzenia';
																					|tr = 'Ücrete ilişkin işlem türleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00003";
	#EndRegion

	#Region AnalyticalInventoryGroups
	Item = Items.Add();
	Item.PredefinedDataName = "AnalyticalInventoryGroups";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.AnalyticalInventoryGroups"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhóm kế toán phân tích mặt hàng';
																					|ru = 'Группы аналитического учета номенклатуры';
																					|en = 'Analytical inventory groups';
																					|it = 'Gruppo di contabilità analitica di articoli';
																					|pl = 'Grupy ewidencji analitycznej towarów';
																					|tr = 'Analitik stok muhasebesi grupları'", LanguagesCodes); // @NStr-2
	Item.Code = "00004";
	#EndRegion

	#Region CashEquivalents
	Item = Items.Add();
	Item.PredefinedDataName = "CashEquivalents";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chứng từ tài chính';
																					|ru = 'Денежные документы';
																					|en = 'Monetary documents';
																					|it = 'Reversali';
																					|pl = 'Pieniężne dokumenty';
																					|tr = 'Nakit belgeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00005";
	#EndRegion

	#Region Contracts
	Item = Items.Add();
	Item.PredefinedDataName = "Contracts";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.IntercompanyContracts"));
	TypesArray.Add(Type("CatalogRef.CounterpartyContracts"));
	TypesArray.Add(Type("CatalogRef.LoanAndDepositContracts"));
	TypesArray.Add(Type("CatalogRef.LeaseContract"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hợp đồng';
																					|ru = 'Договоры';
																					|en = 'Contracts';
																					|it = 'Contratti';
																					|pl = 'Contracts';
																					|tr = 'Sözleşmeler'", LanguagesCodes); // @NStr-2
	Item.Code = "00006";
	#EndRegion
	
	#Region AcquiringContracts
	Item = Items.Add();
	Item.PredefinedDataName = "AcquiringContracts";
	Item.ValueType = New TypeDescription("CatalogRef.AcquiringContracts");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Hợp đồng kết nối đến hệ thống thanh toán';
																					|ru = 'Договоры подключения к платежным системам';
																					|en = 'Payment system contracts';
																					|it = 'Contratti di connessione ai sistemi di pagamento';
																					|pl = 'Umowy o podłączenie do systemów płatniczych';
																					|tr = 'Ödeme sistemlerine bağlama sözleşmeleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00028";
	#EndRegion
	
	#Region CashAccounts
	Item = Items.Add();
	Item.PredefinedDataName = "CashAccounts";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CashAccounts"));
	TypesArray.Add(Type("CatalogRef.CashRegisters"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Quỹ tiền mặt';
																					|ru = 'Кассы';
																					|en = 'Cash accounts';
																					|it = 'Кассы';
																					|pl = 'Cash accounts';
																					|tr = 'Kasa hesapları'", LanguagesCodes); // @NStr-2
	Item.Code = "00031";
	#EndRegion

	#Region Counterparties
	Item = Items.Add();
	Item.PredefinedDataName = "Counterparties";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypesArray.Add(Type("CatalogRef.Counterparties"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đối tác';
																					|ru = 'Контрагенты';
																					|en = 'Counterparties';
																					|it = 'Controparti';
																					|pl = 'Counterparties';
																					|tr = 'Cari hesaplar'", LanguagesCodes); // @NStr-2
	Item.Code = "00007";
	#EndRegion

	#Region IntangibleAssets
	Item = Items.Add();
	Item.PredefinedDataName = "IntangibleAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.IntangibleAssets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản cố định vô hình';
																					|ru = 'Нематериальные активы';
																					|en = 'Intangible assets';
																					|it = 'Beni immateriali';
																					|pl = 'Wartości niematerialne';
																					|tr = 'Maddi olmayan varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00008";
	#EndRegion

	#Region Products
	Item = Items.Add();
	Item.PredefinedDataName = "Products";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Products"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Mặt hàng';
																					|ru = 'Номенклатура';
																					|en = 'Items';
																					|it = 'Articolo';
																					|pl = 'Items';
																					|tr = 'Ürün'", LanguagesCodes); // @NStr-2
	Item.Code = "00009";
	#EndRegion

	#Region ProductRangeGroups
	Item = Items.Add();
	Item.PredefinedDataName = "ProductRangeGroups";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.InventoryAccountingGroups"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhóm sản phẩm';
																					|ru = 'Номенклатурные группы';
																					|en = 'Item categories';
																					|it = 'Categorie dell''articolo';
																					|pl = 'Kategorie produktów';
																					|tr = 'Ürün kategorileri'", LanguagesCodes); // @NStr-2
	Item.Code = "00010";
	#EndRegion

	#Region SeparateBusinessUnits
	Item = Items.Add();
	Item.PredefinedDataName = "SeparateBusinessUnits";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi nhánh, văn phòng đại diện';
																					|ru = 'Обособленные подразделения';
																					|en = 'Branch offices';
																					|it = 'Reparti esterni';
																					|pl = 'Oddzielne działy';
																					|tr = 'Ayrı departmanlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00011";
	#EndRegion

	#Region CostCenters
	Item = Items.Add();
	Item.PredefinedDataName = "CostCenters";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CostCenters"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đối tượng phát sinh chi phí';
																					|ru = 'Объекты возникновения затрат';
																					|en = 'Cost centers';
																					|it = 'Centri di costo';
																					|pl = 'Obiekty tworzenia się rozchodów';
																					|tr = 'Maliyet nesneleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00030";
	#EndRegion

	#Region ConstructionObjects
	Item = Items.Add();
	Item.PredefinedDataName = "ConstructionObjects";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypesArray.Add(Type("CatalogRef.ConstructionObjects"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đối tượng xây dựng cơ bản';
																					|ru = 'Объекты строительства';
																					|en = 'Assets under construction';
																					|it = 'Oggetti di costruzione';
																					|pl = 'Obiekty budowy';
																					|tr = 'Yapım aşamasındaki varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "00026";
	#EndRegion

	#Region FixedAssets
	Item = Items.Add();
	Item.PredefinedDataName = "FixedAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản cố định';
																					|ru = 'Основные средства';
																					|en = 'Fixed assets';
																					|it = 'Capitali fissi';
																					|pl = 'Środki trwałe';
																					|tr = 'Sabit kıymetler'", LanguagesCodes); // @NStr-2
	Item.Code = "00012";
	#EndRegion

	#Region Partners
	Item = Items.Add();
	Item.PredefinedDataName = "Partners";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Partners"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bạn hàng';
																					|ru = 'Партнеры';
																					|en = 'Partners';
																					|it = 'Partner';
																					|pl = 'Partners';
																					|tr = 'İş ortakları'", LanguagesCodes); // @NStr-2
	Item.Code = "00014";
	#EndRegion

	#Region OtherAssetsLiabilities
	Item = Items.Add();
	Item.PredefinedDataName = "OtherAssetsLiabilities";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.OtherAssetsLiabilities"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản và nguồn vốn khác';
																					|ru = 'Прочие активы и пассивы';
																					|en = 'Other assets and liabilities';
																					|it = 'Altre attività e passività';
																					|pl = 'Inne aktywa i pasywa';
																					|tr = 'Diğer varlıklar ve yükümlülükler'", LanguagesCodes); // @NStr-2
	Item.Code = "00015";
	#EndRegion

	#Region CompanyEmployees
	Item = Items.Add();
	Item.PredefinedDataName = "CompanyEmployees";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Persons"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhân viên của doanh nghiệp';
																					|ru = 'Работники организаций';
																					|en = 'Company employees';
																					|it = 'Lavoratori delle organizzazioni';
																					|pl = 'Pracownicy firm';
																					|tr = 'İş yeri çalışanları'", LanguagesCodes); // @NStr-2
	Item.Code = "00016";
	#EndRegion

	#Region Reserves
	Item = Items.Add();
	Item.PredefinedDataName = "Reserves";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Reserves"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đánh giá nợ phải trả và dự phòng';
																					|ru = 'Оценочные обязательства и резервы';
																					|en = 'Provisions';
																					|it = 'Accantonamenti e riserve';
																					|pl = 'Szacunkowe zobowiązania i rezerwy';
																					|tr = 'Tahmini yükümlülükler ve rezervler'", LanguagesCodes); // @NStr-2
	Item.Code = "00013";
	#EndRegion

	#Region Warehouses
	Item = Items.Add();
	Item.PredefinedDataName = "Warehouses";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Warehouses"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Kho bãi';
																					|ru = 'Склады';
																					|en = 'Warehouses';
																					|it = 'Magazzini';
																					|pl = 'Warehouses';
																					|tr = 'Ambarlar'", LanguagesCodes); // @NStr-2
	Item.Code = "00017";
	#EndRegion

	#Region CashFlowReportItems
	Item = Items.Add();
	Item.PredefinedDataName = "CashFlowReportItems";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CashFlowReportItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng lưu chuyển tiền tệ';
																					|ru = 'Статьи движения денежных средств';
																					|en = 'Cash flow items';
																					|it = 'Voci flusso di denaro';
																					|pl = 'Pozycje przepływów środków pieniężnych';
																					|tr = 'Nakit akışı öğeleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00018";
	#EndRegion

	#Region IncomeItems
	Item = Items.Add();
	Item.PredefinedDataName = "IncomeItems";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.IncomeItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng thu nhập';
																					|ru = 'Статьи доходов';
																					|en = 'Income items';
																					|it = 'Voci di entrate';
																					|pl = 'Pozycje przychodów';
																					|tr = 'Gelir kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00019";
	#EndRegion

	#Region CostItems
	Item = Items.Add();
	Item.PredefinedDataName = "CostItems";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypesArray.Add(Type("CatalogRef.EmployeeWorkKinds"));
	TypesArray.Add(Type("CatalogRef.InventoryAccountingGroups"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng chi phí';
																					|ru = 'Статьи затрат';
																					|en = 'Cost elements';
																					|it = 'Voci di uscite';
																					|pl = 'Pozycje kosztów';
																					|tr = 'Gider kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00020";
	#EndRegion

	#Region ProductCostElements
	Item = Items.Add();
	Item.PredefinedDataName = "ProductCostElements";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ProductCostElements"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng tính giá thành';
																					|ru = 'Статьи калькуляции';
																					|en = 'Product cost elements';
																					|it = 'Articoli di calcolo';
																					|pl = 'Pozycje kalkulacji';
																					|tr = 'Ürün maliyet kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00021";
	#EndRegion

	#Region ExpenseItems
	Item = Items.Add();
	Item.PredefinedDataName = "ExpenseItems";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng chi phí';
																					|ru = 'Статьи расходов';
																					|en = 'Expense items';
																					|it = 'Voci di spese';
																					|pl = 'Pozycje rozchodów';
																					|tr = 'Gider kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00022";
	#EndRegion

	#Region ItemsTypes
	Item = Items.Add();
	Item.PredefinedDataName = "ItemsTypes";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.ItemsTypes"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Kiểu mặt hàng';
																					|ru = 'Типы номенклатуры';
																					|en = 'Item types';
																					|it = 'Tipi di articoli';
																					|pl = 'Typy produktów';
																					|tr = 'Ürünlerin türleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00023";
	#EndRegion

	#Region BudgetLevels
	Item = Items.Add();
	Item.PredefinedDataName = "BudgetLevels";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Các mức ngân sách';
																					|ru = 'Уровни бюджетов';
																					|en = 'Budget levels';
																					|it = 'Livelli dei Budget';
																					|pl = 'Poziomy budżetów';
																					|tr = 'Bütçe seviyeleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00024";
	#EndRegion

	#Region Securities
	Item = Items.Add();
	Item.PredefinedDataName = "Securities";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chứng khoán';
																					|ru = 'Ценные бумаги';
																					|en = 'Securities';
																					|it = 'Valori mobiliari';
																					|pl = 'Papiery wartościowe';
																					|tr = 'Menkul kıymetler'", LanguagesCodes); // @NStr-2
	Item.Code = "00025";
	#EndRegion
	
	#Region Securities
	Item = Items.Add();
	Item.PredefinedDataName = "RDExpenses";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.RDTopicsStages"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí nghiên cứu, triển khai';
																					|ru = 'Расходы на НИОКР';
																					|en = 'R&D expenses';
																					|it = 'Spese per Ricerca e Sviluppo';
																					|pl = 'Wydatki na R&D';
																					|tr = 'Ar-Ge giderleri'", LanguagesCodes); // @NStr-2
	Item.Code = "00027";
	#EndRegion
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.FinancialExtraDimensionTypes - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes);
	// End StandardSubsystems.Core
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
