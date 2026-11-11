#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a table of used Analytics
//  
// Returns:
//  ValueTable - table of used analytics:
//		* Ref - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Link to Analytics.
//      * Presentation - String - The Analytics view.
//		* RecordByQuantity - Boolean- Indicates whether the quantity is accounted for.
//
Function TypesOfAnalytics()Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	BudgetFlowItemDimensions.Ref                AS Ref,
	|	BudgetFlowItemDimensions.Presentation         AS Presentation,
	|	BudgetFlowItemDimensions.RecordByQuantity AS RecordByQuantity
	|FROM
	|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions";
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns an indication of the use of analytics in budget items
//
// Parameters:
//  BudgetFlowItemsDimension - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Analytics for verification.
//  
// Returns:
//  Boolean - signs of use.
//
Function UsedInBudgetItems(BudgetFlowItemsDimension) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	BudgetFlowItems.Ref
	|FROM
	|	Catalog.BudgetFlowItems AS BudgetFlowItems
	|WHERE
	|	&SearchTextByTypeOfAnalytics";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	SearchTextByTypeOfAnalytics = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		SearchTextByTypeOfAnalytics = SearchTextByTypeOfAnalytics + ?(SearchTextByTypeOfAnalytics = "", "", "
		|	OR ") + StringFunctionsClientServer.SubstituteParametersToString(
			"BudgetFlowItems.DimensionKind%1 = &BudgetFlowItemsDimension", 
			DimensionNumber);
	EndDo;
	Query.Text = StrReplace(Query.Text, "&SearchTextByTypeOfAnalytics", SearchTextByTypeOfAnalytics);
	Query.SetParameter("BudgetFlowItemsDimension", BudgetFlowItemsDimension);
	
	Result = Not Query.Execute().IsEmpty();
	
	Return Result;
	
EndFunction

// Returns types of analytics values
//
// Parameters:
//  BudgetFlowItemsDimension - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions  - the value of analytics.
//  
// Returns:
//  Map of KeyAndValue:
//   *Key - Type -  Type of the Analytics value.
//   *Value - String - full name of the metadata object.
//        
Function AvailableTypesOfBudgetItemAnalytics(BudgetFlowItemsDimension) Export
	
	AvailableTypes = New Map;
	
	For Each Type In Common.ObjectAttributeValue(BudgetFlowItemsDimension, "ValueType").Types() Do
		AvailableTypes.Insert(Type, Metadata.FindByType(Type).FullName());
	EndDo;
	
	Return AvailableTypes;
	
EndFunction

// Returns a sign of hierarchy support for this analytics value
//
// Parameters:
//  BudgetFlowItemsDimension - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - the value of analytics.
//  HierarchyOfItems - Boolean - the need to clarify that a hierarchy of elements is used for analytics
//  
// Returns: 
//  Boolean:
//   True - hierarchy is used, False - hierarchy is not used
//
Function HierarchyOfAnalyticsValuesIsUsed(BudgetFlowItemsDimension, HierarchyOfItems = False) Export
	
	HierarchyIsUsed = False;
	ThereIsHierarchyOfGroupsAndElements = False;
	ThereIsHierarchyOfElements = False;
	
	If ValueIsFilled(BudgetFlowItemsDimension) Then
		AvailableTypesOfAnalyticsValues = AvailableTypesOfBudgetItemAnalytics(BudgetFlowItemsDimension);
		For Each TypeOfAnalyticsValue In AvailableTypesOfAnalyticsValues Do
			ObjectMetadata = Metadata.FindByType(TypeOfAnalyticsValue.Key);
			MetadataObjectName = TypeOfAnalyticsValue.Value;
			If (StrFind(MetadataObjectName, "Catalog.") > 0
				Or StrFind(MetadataObjectName, "ChartOfCharacteristicTypes.") > 0)
				And ObjectMetadata.Hierarchical Then
				HierarchyIsUsed = True;
				If StrFind(MetadataObjectName, "Catalog.") > 0
					And ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyOfItems Then
					ThereIsHierarchyOfElements = True;
				Else
					ThereIsHierarchyOfGroupsAndElements = True;
				EndIf;
			Else
				// If the hierarchy is not used for at least one type, then the hierarchy output for the analytics type is not available
				HierarchyIsUsed = False;
				Break;
			EndIf;
		EndDo;
		If HierarchyIsUsed And HierarchyOfItems Then
			HierarchyIsUsed = ThereIsHierarchyOfElements And Not ThereIsHierarchyOfGroupsAndElements;
		EndIf;
	EndIf;
	
	Return HierarchyIsUsed;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("ValueType");
	Result.Add("Id");
	Result.Add("CurrencyPresentation");
	Result.Add("UnitOfMeasurePresentation");
	Result.Add("RecordByCurrency");
	Result.Add("RecordByQuantity");
	
	Return Result;
	
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
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of details
//                                 of the plan and types of characteristics.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	DefaultLanguageCode = Common.DefaultLanguageCode();

	#Region ItemKinds
	Item = Items.Add();
	Item.PredefinedDataName = "ItemKinds";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ItemKinds"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng mặt hàng';
																					|ru = 'Виды номенклатуры';
																					|en = 'Item kinds';
																					|it = 'Tipi di articoli';
																					|pl = 'Rodzaje produktów';
																					|tr = 'Öğe türleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000016";
	Item.UnitOfMeasureFilling = StrTemplate(NStr("vi = '%1';
												|ru = '%1';
												|en = '%1'; fa = '%1';
												|it = '%1';
												|pl = '%1';
												|tr = '%1'", DefaultLanguageCode), "UnitOfMeasure");
	Item.UnitOfMeasurePresentation = NStr("vi = '[Единица хранения]';
											|ru = '[Единица хранения]';
											|en = '[Stock UOM]'; fa = '[Stock UOM]';
											|it = '[Unità di stoccaggio]';
											|pl = '[Единица хранения]';
											|tr = '[Stok ölçü birimi]'", DefaultLanguageCode);
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = True;
	Item.PresentationValueType = NStr("vi = 'Dạng mặt hàng';
										|ru = 'Вид номенклатуры';
										|en = 'Item kind'; fa = 'نوع قلم';
										|it = 'Tipo di articolo';
										|pl = 'Rodzaj pozycji';
										|tr = 'Ürün türü'", DefaultLanguageCode);
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
																					|tr = 'Boyut stok grubu'", LanguagesCodes); // @NStr-2
	Item.Code = "000000034";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhóm kế toán phân tích mặt hàng';
										|ru = 'Группа аналитического учета номенклатуры';
										|en = 'Analytical inventory group'; fa = 'گروه تحلیلی موجودی';
										|it = 'Gruppo di contabilità analitica di articoli';
										|pl = 'Grupa ewidencji analitycznej towarów';
										|tr = 'Boyut stok grubu'", DefaultLanguageCode);
	#EndRegion

	#Region IntangibleAssetsGroups
	Item = Items.Add();
	Item.PredefinedDataName = "IntangibleAssetsGroups";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.IntangibleAssetsGroups"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Các nhóm TSCĐVH';
																					|ru = 'Группы НМА';
																					|en = 'Intangible assets groups';
																					|it = 'Gruppi Atti Normativi';
																					|pl = 'Grupy aktywów niematerialnych';
																					|tr = 'Maddi olmayan varlık grupları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000039";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhóm TSCĐ vô hình';
										|ru = 'Группа НМА';
										|en = 'Intangible assets group'; fa = 'گروه دارایی‌های نامشهود';
										|it = 'Группа НМА';
										|pl = 'Intangible assets group';
										|tr = 'Maddi olmayan varlıklar grubu'", DefaultLanguageCode);
	#EndRegion

	#Region FAGroups
	Item = Items.Add();
	Item.PredefinedDataName = "FAGroups";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhóm TSCĐ hữu hình';
																					|ru = 'Группы ОС';
																					|en = 'Fixed assets groups';
																					|it = 'Gruppi Immobilizzazioni';
																					|pl = 'Grupy środków trwałych';
																					|tr = 'Sabit kıymet grupları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000038";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhóm TSCĐ hữu hình';
										|ru = 'Группа ОС';
										|en = 'Fixed assets group'; fa = 'گروه دارایی‌های ثابت';
										|it = 'Gruppo dei cespiti';
										|pl = 'Grupa środków trwałych';
										|tr = 'Sabit kıymet grubu'", DefaultLanguageCode);
	#EndRegion

	#Region BudgetingFunds
	Item = Items.Add();
	Item.PredefinedDataName = "BudgetingFunds";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CashRegisters"));
	TypesArray.Add(Type("CatalogRef.CompaniesBankAccounts"));
	TypesArray.Add(Type("CatalogRef.CashAccounts"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tiền mặt, tiền gửi';
																					|ru = 'Денежные средства';
																					|en = 'Cash';
																					|it = 'Fondi monetari';
																					|pl = 'Środki pieniężne';
																					|tr = 'Nakit'", LanguagesCodes); // @NStr-2
	Item.Code = "000000011";
	Item.CurrencyFilling = StrTemplate(NStr("vi = '%1';
											|ru = '%1';
											|en = '%1'; fa = '%1';
											|it = '%1';
											|pl = '%1';
											|tr = '%1'", DefaultLanguageCode), "CashCurrency");
	Item.CurrencyPresentation = NStr("vi = '[Валюта денежных средств]';
									|ru = '[Валюта денежных средств]';
									|en = '[Currency of cash]'; fa = '[Currency of cash]';
									|it = '[Valuta dei mezzi finanziari]';
									|pl = '[Waluta środków pieniężnych]';
									|tr = '[Nakit para birimi]'", DefaultLanguageCode);
	Item.RecordByCurrency = True;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Quầy thu ngân, Tài khoản ngân hàng doanh nghiệp, Quỹ tiền mặt';
										|ru = 'Кассы ККМ, Банковский счет организации, Касса';
										|en = 'Cash register, Company bank account, Cash account'; fa = 'Cash register, Company bank account, Cash account';
										|it = 'Casse di registro Conto bancario dell''azienda, Cassa';
										|pl = 'Kasy fiskalne, Rachunek bankowy firmy, Kasa';
										|tr = 'Yazar kasa, İş yerinin banka hesabı, Kasa hesabı'", DefaultLanguageCode);
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
	Item.Code = "000000001";
	Item.CurrencyFilling = StrTemplate(NStr("vi = '%1';
											|ru = '%1';
											|en = '%1'; fa = '%1';
											|it = '%1';
											|pl = '%1';
											|tr = '%1'", DefaultLanguageCode), "ARAPCurrency");
	Item.CurrencyPresentation = NStr("vi = '[Валюта взаиморасчетов]';
									|ru = '[Валюта взаиморасчетов]';
									|en = '[AR/AP currency]'; fa = '[AR/AP currency]';
									|it = '[Valuta di regolamento dei conti]';
									|pl = '[Waluta rozliczeń wzajemnych]';
									|tr = '[Alacak/borç hesabı para birimi]'", DefaultLanguageCode);
	Item.RecordByCurrency = True;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Hợp đồng giữa các doanh nghiệp, Hợp đồng với đối tác, Hợp đồng tiết kiệm (vay nợ), Hợp đồng thuê';
										|ru = 'Договор между организациями, Договор с контрагентом, Договор кредита (депозита), Договор аренды';
										|en = 'Intercompany contract, Contract with counterparty, Loan (deposit) contract, Rental contract'; fa = 'Intercompany contract, Contract with counterparty, Loan (deposit) contract, Rental contract';
										|it = 'Accordo tra organizzazioni, Accordo con la controparte, Accordo di credito (deposito), Contratto di affitto';
										|pl = 'Umowa między firmami, Umowa z kontrahentem, Umowa kredytowa (depozytowa), Umowa dzierżawy';
										|tr = 'Şirketler arası sözleşme, Cari hesap sözleşmesi, Alacak (mevduat) sözleşmesi, Kira sözleşmeleri'", DefaultLanguageCode);
	#EndRegion

	#Region Orders
	Item = Items.Add();
	Item.PredefinedDataName = "Orders";
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.PurchaseOrder"));
	TypesArray.Add(Type("DocumentRef.SubcontractOrder2_5"));
	TypesArray.Add(Type("DocumentRef.ByAssemblyDisassemblyOrder"));
	TypesArray.Add(Type("DocumentRef.SalesOrder"));
	TypesArray.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	TypesArray.Add(Type("DocumentRef.ProductionOrder2_2"));
	TypesArray.Add(Type("DocumentRef.RMOrder"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đơn hàng';
																					|ru = 'Заказы';
																					|en = 'Orders';
																					|it = 'Ordini';
																					|pl = 'Orders';
																					|tr = 'Siparişler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000036";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Đơn hàng đặt nhà cung cấp, Đơn hàng sản xuất (2.1), Đơn đặt hàng gia công, Đơn hàng đóng bộ (tách bộ), Đơn đặt hàng sửa chữa, Đơn hàng của khách, Đơn đặt hàng của bên thuê gia công, Đơn hàng sản xuất';
										|ru = 'Заказ поставщику, Заказ на производство (2.1), Заказ переработчику, Заказ на сборку (разборку), Заказ на ремонт, Заказ клиента, Заказ давальца, Заказ на производство';
										|en = 'Purchase order, Production order (2.1), Subcontracting purchase order, Kitting order, R&M order, Sales order, Subcontracting sales order, Production order'; fa = 'Purchase order, Production order (2.1), Subcontracting purchase order, Kitting order, R&M order, Sales order, Subcontracting sales order, Production order';
										|it = 'Ordine al fornitore, Ordine di produzione (2.1), Ordine al processore, Ordine di montaggio (smontaggio), Ordine di riparazione, Ordine del cliente, Ordine del contraente, Ordine di produzione';
										|pl = 'Zamówienie do dostawcy, Zamówienie na produkcję (2.1), Zamówienie do przetwórcy, Zamówienie na montaż (demontaż), Zamówienie na naprawę, Zamówienie klienta, Zamówienie właścicielowi surowców, Zamówienie na produkcję';
										|tr = 'Satın alma siparişi, Üretim emri (2.1), Fason satın alma siparişi, Montaj emri (demontaj), Onarım siparişi, Müşteri siparişi, Talep sahibinin siparişi, Üretim emri'", DefaultLanguageCode);
	#EndRegion

	#Region MaintenanceSchemes
	Item = Items.Add();
	Item.PredefinedDataName = "MaintenanceSchemes";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.MaintenanceSchemes"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phân loại đối tượng vận hành';
																					|ru = 'Классы объектов эксплуатации';
																					|en = 'Maintenance schemes';
																					|it = 'Классы объектов эксплуатации';
																					|pl = 'Klasy obiektów eksploatacji';
																					|tr = 'Bakım planı'", LanguagesCodes); // @NStr-2
	Item.Code = "000000043";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Loại đối tượng vận hành';
										|ru = 'Класс объектов эксплуатации';
										|en = 'Maintenance scheme'; fa = 'طرح نگهداری';
										|it = 'Класс объектов эксплуатации';
										|pl = 'Klasa obiektów eksploatacji';
										|tr = 'bakım planı'", DefaultLanguageCode);
	#EndRegion

	#Region ItemsCollections
	Item = Items.Add();
	Item.PredefinedDataName = "ItemsCollections";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ItemsCollections"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bộ sưu tập';
																					|ru = 'Коллекции';
																					|en = 'Collections';
																					|it = 'Collezioni';
																					|pl = 'Collections';
																					|tr = 'Koleksiyonlar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000033";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Bộ sưu tập (thời vụ)';
										|ru = 'Коллекция (сезон)';
										|en = 'Collection (season)'; fa = 'کلکسیون (فصل)';
										|it = 'Collezione (stagione)';
										|pl = 'Kolekcja (sezon)';
										|tr = 'Koleksiyon (sezon)'", DefaultLanguageCode);
	#EndRegion

	#Region Counterparties
	Item = Items.Add();
	Item.PredefinedDataName = "Counterparties";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Counterparties"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đối tác';
																					|ru = 'Контрагенты';
																					|en = 'Counterparties';
																					|it = 'Controparti';
																					|pl = 'Kontrahenci';
																					|tr = 'Cari hesaplar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000002";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Đối tác';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Controparte';
										|pl = 'Kontrahent';
										|tr = 'Cari hesap'", DefaultLanguageCode);
	#EndRegion

	#Region Brands
	Item = Items.Add();
	Item.PredefinedDataName = "Brands";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Brands"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhãn hiệu (thương hiệu)';
																					|ru = 'Марки (бренды)';
																					|en = 'Brands';
																					|it = 'Marchi (brand)';
																					|pl = 'Marki (brandy)';
																					|tr = 'Markalar (markalar)'", LanguagesCodes); // @NStr-2
	Item.Code = "000000028";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhãn hiệu (thương hiệu)';
										|ru = 'Марка (бренд)';
										|en = 'Brand'; fa = 'برند';
										|it = 'Marchio';
										|pl = 'Marka (brand)';
										|tr = 'Marka (marka)'", DefaultLanguageCode);
	#EndRegion

	#Region LinesOfBusiness
	Item = Items.Add();
	Item.PredefinedDataName = "LinesOfBusiness";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.LinesOfBusiness"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lĩnh vực hoạt động';
																					|ru = 'Направления деятельности';
																					|en = 'Lines of business';
																					|it = 'Settori di attività';
																					|pl = 'Rodzaje działalności';
																					|tr = 'İş kolları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000015";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Lĩnh vực hoạt động';
										|ru = 'Направление деятельности';
										|en = 'Line of business'; fa = 'خط کسب‌وکار';
										|it = 'Settore di attività';
										|pl = 'Rodzaj działalności';
										|tr = 'Faaliyet alanı'", DefaultLanguageCode);
	#EndRegion

	#Region IntangibleAssets
	Item = Items.Add();
	Item.PredefinedDataName = "IntangibleAssets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.IntangibleAssets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản cố định vô hình và chi phí nghiên cứu phát triển';
																					|ru = 'Нематериальные активы и расходы на НИОКР';
																					|en = 'Intangible assets and R&D expenses';
																					|it = 'Beni immateriali e spese in Ricerca&Sviluppo';
																					|pl = 'Aktywa niematerialne i wydatki na prace naukowo-badawcze i doświadczalno-konstrukcyjne';
																					|tr = 'Bilimsel araştırma ve geliştirme çalışmalarında maddi olmayan duran varlıklar ve harcamalar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000018";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Tài sản cố định vô hình và Chi phí nghiên cứu phát triển';
										|ru = 'Нематериальные активы и расходы на НИОКР';
										|en = 'Intangible assets and R&D expenses'; fa = 'دارایی‌های نامشهود و هزینه‌های تحقیق و توسعه';
										|it = 'Beni immateriali e spese in Ricerca&Sviluppo';
										|pl = 'Aktywa niematerialne i wydatki na prace naukowo-badawcze i doświadczalno-konstrukcyjne';
										|tr = 'Bilimsel araştırma ve geliştirme çalışmalarında maddi olmayan duran varlıklar ve harcamalar'", DefaultLanguageCode);
	#EndRegion

	#Region BudgetingItems
	Item = Items.Add();
	Item.PredefinedDataName = "BudgetingItems";
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
	Item.Code = "000000003";
	Item.UnitOfMeasureFilling = StrTemplate(NStr("vi = '%1';
												|ru = '%1';
												|en = '%1'; fa = '%1';
												|it = '%1';
												|pl = '%1';
												|tr = '%1'", DefaultLanguageCode), "UnitOfMeasure");
	Item.UnitOfMeasurePresentation = NStr("vi = '[Единица хранения]';
											|ru = '[Единица хранения]';
											|en = '[Stock UOM]'; fa = '[Stock UOM]';
											|it = '[Unità di stoccaggio]';
											|pl = '[Единица хранения]';
											|tr = '[Stok ölçü birimi]'", DefaultLanguageCode);
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = True;
	Item.PresentationValueType = NStr("vi = 'Mặt hàng';
										|ru = 'Номенклатура';
										|en = 'Items'; fa = 'اقلام';
										|it = 'Articolo';
										|pl = 'Items';
										|tr = 'Ürün'", DefaultLanguageCode);
	#EndRegion

	#Region ARAPObjects
	Item = Items.Add();
	Item.PredefinedDataName = "ARAPObjects";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ARAPObjects"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đối tượng khấu trừ';
																					|ru = 'Объекты расчетов';
																					|en = 'AR/AP objects';
																					|it = 'Oggetti di regolamenti';
																					|pl = 'Obiekty rozliczeń';
																					|tr = 'Alacak/Borç nesneleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000037";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Đối tượng tính toán';
										|ru = 'Объект расчетов';
										|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
										|it = 'Oggetto di regolamenti';
										|pl = 'Obiekt rozliczeń';
										|tr = 'Alacak/Borç nesnesi'", DefaultLanguageCode);
	#EndRegion

	#Region ConstructionObjects
	Item = Items.Add();
	Item.PredefinedDataName = "ConstructionObjects";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ConstructionObjects"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đối tượng xây dựng cơ bản';
																					|ru = 'Объекты строительства';
																					|en = 'Assets under construction';
																					|it = 'Oggetti di costruzione';
																					|pl = 'Obiekty budowy';
																					|tr = 'Yapım aşamasındaki varlıklar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000035";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Đối tượng xây dựng cơ bản';
										|ru = 'Объект строительства';
										|en = 'Assets under construction'; fa = 'دارایی‌های در جریان ساخت';
										|it = 'Oggetto di costruzione';
										|pl = 'Obiekt budownictwa';
										|tr = 'İnşaat nesnesi'", DefaultLanguageCode);
	#EndRegion

	#Region Assets
	Item = Items.Add();
	Item.PredefinedDataName = "Assets";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản đang vận hành';
																					|ru = 'Объекты эксплуатации';
																					|en = 'Assets';
																					|it = 'Oggetti in uso';
																					|pl = 'Obiekty eksploatacji';
																					|tr = 'İşlem nesneleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000017";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Tài sản đang vận hành';
										|ru = 'Объект эксплуатации';
										|en = 'Asset'; fa = 'دارایی';
										|it = 'Oggetto di esercizio';
										|pl = 'Obiekt eksploatacji';
										|tr = 'Varlık'", DefaultLanguageCode);
	#EndRegion

	#Region Companies
	Item = Items.Add();
	Item.PredefinedDataName = "Companies";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Doanh nghiệp';
																					|ru = 'Организации';
																					|en = 'Companies';
																					|it = 'Aziende';
																					|pl = 'Organizacje';
																					|tr = 'İş yerleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000023";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", DefaultLanguageCode);
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
	Item.Code = "000000024";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Bạn hàng';
										|ru = 'Партнер';
										|en = 'Partner'; fa = 'شریک تجاری';
										|it = 'Partner';
										|pl = 'Partner';
										|tr = 'İş ortağı'", DefaultLanguageCode);
	#EndRegion

	#Region Departments
	Item = Items.Add();
	Item.PredefinedDataName = "Departments";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bộ phận';
																					|ru = 'Подразделения';
																					|en = 'Business units';
																					|it = 'Reparti';
																					|pl = 'Działu';
																					|tr = 'Departman'", LanguagesCodes); // @NStr-2
	Item.Code = "000000014";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Bộ phận';
										|ru = 'Подразделение';
										|en = 'Business unit'; fa = 'Business unit';
										|it = 'Reparto';
										|pl = 'Dział';
										|tr = 'Departman'", DefaultLanguageCode);
	#EndRegion

	#Region Projects
	Item = Items.Add();
	Item.PredefinedDataName = "Projects";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Projects"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dự án';
																					|ru = 'Проекты';
																					|en = 'Projects';
																					|it = 'Progetti';
																					|pl = 'Projekty';
																					|tr = 'Projeler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000004";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dự án';
										|ru = 'Проект';
										|en = 'Project'; fa = 'پروژه';
										|it = 'Progetto';
										|pl = 'Projekt';
										|tr = 'Proje'", DefaultLanguageCode);
	#EndRegion

	#Region Manufacturers
	Item = Items.Add();
	Item.PredefinedDataName = "Manufacturers";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Manufacturers"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhà sản xuất';
																					|ru = 'Производители';
																					|en = 'Manufacturers';
																					|it = 'Produttori';
																					|pl = 'Manufacturers';
																					|tr = 'Üreticiler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000027";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhà sản xuất';
										|ru = 'Производитель';
										|en = 'Manufacturer'; fa = 'تولیدکننده';
										|it = 'Produttore';
										|pl = 'Manufacturer';
										|tr = 'Üretici'", DefaultLanguageCode);
	#EndRegion

	#Region OtherExpenses
	Item = Items.Add();
	Item.PredefinedDataName = "OtherExpenses";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.OtherExpenses"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí khác';
																					|ru = 'Прочие расходы';
																					|en = 'Other expenses';
																					|it = 'Altre spese';
																					|pl = 'Inne rozchody';
																					|tr = 'Diğer giderler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000020";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Chi phí khác';
										|ru = 'Прочие расходы';
										|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
										|it = 'Altre spese';
										|pl = 'Inne rozchody';
										|tr = 'Diğer giderler'", DefaultLanguageCode);
	#EndRegion

	#Region SalesOpportunities
	Item = Items.Add();
	Item.PredefinedDataName = "SalesOpportunities";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.SalesOpportunitiesToCustomer"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Vụ việc';
																					|ru = 'Сделки';
																					|en = 'Sales opportunities';
																					|it = 'Сделки';
																					|pl = 'Sales opportunities';
																					|tr = 'Satış fırsatları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000042";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Vụ việc';
										|ru = 'Сделка';
										|en = 'Sales opportunity'; fa = 'فرصت فروش';
										|it = 'Сделка';
										|pl = 'Sales opportunity';
										|tr = 'Satış fırsatı'", DefaultLanguageCode);
	#EndRegion

	#Region SeasonalGroups
	Item = Items.Add();
	Item.PredefinedDataName = "SeasonalGroups";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.SeasonalGroups"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhóm thời vụ';
																					|ru = 'Сезонные группы';
																					|en = 'Seasonal groups';
																					|it = 'Gruppi stagionali';
																					|pl = 'Grupy sezonowe';
																					|tr = 'Mevsimsel gruplar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000031";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhóm mặt hàng theo mùa';
										|ru = 'Сезонные группы номенклатуры';
										|en = 'Seasonal item groups'; fa = 'گروه‌های فصلی اقلام';
										|it = 'Gruppo stagionale di articoli';
										|pl = 'Sezonowe grupy produktów';
										|tr = 'Öğe mevsimsel grupları'", DefaultLanguageCode);
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
	Item.Code = "000000005";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Kho bãi';
										|ru = 'Склад (складская территория)';
										|en = 'Warehouse (warehouse area)'; fa = 'انبار (ناحیه انبار)';
										|it = 'Magazzino (area di stoccaggio)';
										|pl = 'Magazyn (powierzchnia magazynowa)';
										|tr = 'Ambar (ambar alanı)'", DefaultLanguageCode);
	#EndRegion

	#Region Terms1
	Item = Items.Add();
	Item.PredefinedDataName = "Terms1";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.TermsOfSale"));
	TypesArray.Add(Type("CatalogRef.TermsOfPurchaseFromVendors"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thỏa thuận';
																					|ru = 'Соглашения';
																					|en = 'Agreements';
																					|it = 'Соглашения';
																					|pl = 'Agreements';
																					|tr = 'Anlaşmalar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000041";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Thỏa thuận';
										|ru = 'Соглашение';
										|en = 'Agreement'; fa = 'توافق‌نامه';
										|it = 'Соглашение';
										|pl = 'Agreement';
										|tr = 'Anlaşma'", DefaultLanguageCode);
	#EndRegion

	#Region EmployeesHR
	Item = Items.Add();
	Item.PredefinedDataName = "EmployeesHR";
	TypesArray = New Array;
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhân viên';
																					|ru = 'Сотрудники';
																					|en = 'Employees';
																					|it = 'Dipendenti';
																					|pl = 'Employees';
																					|tr = 'Çalışanlar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000006";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhân viên';
										|ru = 'Сотрудник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Employee';
										|tr = 'Çalışan'", DefaultLanguageCode);
	#EndRegion

	#Region AssetAndLiabilityItems
	Item = Items.Add();
	Item.PredefinedDataName = "AssetAndLiabilityItems";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Tài sản và nguồn vốn khác';
																					|ru = 'Прочие активы и пассивы';
																					|en = 'Other assets and liabilities';
																					|it = 'Altre attività e passività';
																					|pl = 'Inne aktywa i pasywa';
																					|tr = 'Diğer varlıklar ve yükümlülükler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000019";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dạng tài sản/nguồn vốn';
										|ru = 'Статья актива/пассива';
										|en = 'Asset/liability item'; fa = 'قلم دارایی/بدهی';
										|it = 'Voce attività/passività';
										|pl = 'Artykuł aktywów/zobowiązań';
										|tr = 'Varlık/yükümlülük kalemi'", DefaultLanguageCode);
	#EndRegion

	#Region AssetLiabilityItems
	Item = Items.Add();
	Item.PredefinedDataName = "AssetLiabilityItems";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng tài sản và nguồn vốn';
																					|ru = 'Статьи активов и пассивов';
																					|en = 'Asset and liability items';
																					|it = 'Voci attività e passività';
																					|pl = 'Pozycje aktywów i pasywów';
																					|tr = 'Varlıklar ve yükümlülükler kalemleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000022";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dạng tài sản/nguồn vốn';
										|ru = 'Статья актива/пассива';
										|en = 'Asset/liability item'; fa = 'قلم دارایی/بدهی';
										|it = 'Voce attività/passività';
										|pl = 'Artykuł aktywów/zobowiązań';
										|tr = 'Varlık/yükümlülük kalemi'", DefaultLanguageCode);
	#EndRegion

	#Region CashFlowReportItems
	Item = Items.Add();
	Item.PredefinedDataName = "CashFlowReportItems";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CashFlowReportItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Dạng lưu chuyển tiền tệ';
																					|ru = 'Статьи ДДС';
																					|en = 'Cash flow items';
																					|it = 'Voci del flusso di cassa';
																					|pl = 'Pozycje ruchu środków pieniężnych';
																					|tr = 'Nakit akış tablosu maddeleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000007";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dạng lưu chuyển tiền tệ';
										|ru = 'Статья движения денежных средств';
										|en = 'Cash flow item'; fa = 'قلم جریان وجوه نقد';
										|it = 'Voce flussi di denaro';
										|pl = 'Kierunek ruchu środków pieniężnych';
										|tr = 'Nakit akışı öğesi'", DefaultLanguageCode);
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
	Item.Code = "000000009";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dạng thu nhập';
										|ru = 'Статьи доходов';
										|en = 'Income items'; fa = 'اقلام درآمد';
										|it = 'Voci di entrate';
										|pl = 'Pozycje przychodów';
										|tr = 'Gelir kalemleri'", DefaultLanguageCode);
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
	Item.Code = "000000008";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dạng tính giá thành';
										|ru = 'Статьи калькуляции';
										|en = 'Product cost elements'; fa = 'عناصر بهای تمام‌شده محصول';
										|it = 'Articoli di calcolo';
										|pl = 'Pozycje kalkulacji';
										|tr = 'Ürün maliyet kalemleri'", DefaultLanguageCode);
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
	Item.Code = "000000010";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Dạng chi phí';
										|ru = 'Статья расходов';
										|en = 'Expense item'; fa = 'قلم هزینه';
										|it = 'Voce di spese';
										|pl = 'Rodzaj kosztu';
										|tr = 'Gider kalemi'", DefaultLanguageCode);
	#EndRegion

	#Region CashTypes
	Item = Items.Add();
	Item.PredefinedDataName = "CashTypes";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.CashTypes"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Kiểu vốn bằng tiền';
																					|ru = 'Типы денежных средств';
																					|en = 'Cash types';
																					|it = 'Tipi di fondi monetari';
																					|pl = 'Rodzaje środków pieniężnych';
																					|tr = 'Nakit türleri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000012";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Kiểu vốn bằng tiền';
										|ru = 'Типы денежных средств';
										|en = 'Cash types'; fa = 'انواع وجه نقد';
										|it = 'Tipi di fondi monetari';
										|pl = 'Rodzaje środków pieniężnych';
										|tr = 'Nakit türleri'", DefaultLanguageCode);
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
	Item.Code = "000000013";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Kiểu mặt hàng';
										|ru = 'Типы номенклатуры';
										|en = 'Item types'; fa = 'انواع قلم';
										|it = 'Tipi di articoli';
										|pl = 'Typy produktów';
										|tr = 'Ürünlerin türleri'", DefaultLanguageCode);
	#EndRegion

	#Region ProductCategories
	Item = Items.Add();
	Item.PredefinedDataName = "ProductCategories";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ProductCategories"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thể loại hàng hóa';
																					|ru = 'Товарные категории';
																					|en = 'Product categories';
																					|it = 'Categorie di merci';
																					|pl = 'Kategorie towarowe';
																					|tr = 'Ürün kategorileri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000030";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Thể loại hàng hóa';
										|ru = 'Товарные категории';
										|en = 'Product categories'; fa = 'دسته‌های محصول';
										|it = 'Categorie di merci';
										|pl = 'Kategorie towarowe';
										|tr = 'Ürün kategorileri'", DefaultLanguageCode);
	#EndRegion

	#Region Persons
	Item = Items.Add();
	Item.PredefinedDataName = "Persons";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Persons"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Cá nhân';
																					|ru = 'Физические лица';
																					|en = 'Persons';
																					|it = 'Persone fisiche';
																					|pl = 'Osoby fizyczne';
																					|tr = 'Gerçek kişiler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000021";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Cá nhân';
										|ru = 'Физическое лицо';
										|en = 'Person'; fa = 'شخص';
										|it = 'Persona fisica';
										|pl = 'Osoba fizyczna';
										|tr = 'Gerçek kişi'", DefaultLanguageCode);
	#EndRegion

	#Region StoreFormats
	Item = Items.Add();
	Item.PredefinedDataName = "StoreFormats";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.StoreFormats"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Khuôn dạng cửa hàng';
																					|ru = 'Форматы магазинов';
																					|en = 'Retail formats';
																					|it = 'Formati dei negozi';
																					|pl = 'Formaty sklepów';
																					|tr = 'Mağaza formatları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000032";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Khuôn dạng cửa hàng';
										|ru = 'Форматы магазинов';
										|en = 'Retail formats'; fa = 'قالب‌های خرده‌فروشی';
										|it = 'Formati dei negozi';
										|pl = 'Formaty sklepów';
										|tr = 'Mağaza formatları'", DefaultLanguageCode);
	#EndRegion

	#Region ItemsCharacteristics
	Item = Items.Add();
	Item.PredefinedDataName = "ItemsCharacteristics";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.ItemsCharacteristics"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đặc tính mặt hàng';
																					|ru = 'Характеристики номенклатуры';
																					|en = 'Item variants';
																					|it = 'Caratteristiche dell''articolo';
																					|pl = 'Charakterystyki produktów';
																					|tr = 'Ürün varyantları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000040";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = True;
	Item.PresentationValueType = NStr("vi = 'Đặc tính mặt hàng';
										|ru = 'Характеристика номенклатуры';
										|en = 'Item variant'; fa = 'گونه قلم';
										|it = 'Caratteristica dell''articolo';
										|pl = 'Charakterystyka produktu';
										|tr = 'Ürün varyantları'", DefaultLanguageCode);
	#EndRegion

	#Region PriceGroups
	Item = Items.Add();
	Item.PredefinedDataName = "PriceGroups";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.PriceGroups"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Nhóm giá';
																					|ru = 'Ценовые группы';
																					|en = 'Price groups';
																					|it = 'Gruppi prezzi';
																					|pl = 'Grupy cenowe';
																					|tr = 'Fiyat grupları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000029";
	Item.RecordByCurrency = False;
	Item.RecordByQuantity = False;
	Item.PresentationValueType = NStr("vi = 'Nhóm giá';
										|ru = 'Ценовая группа';
										|en = 'Price group'; fa = 'گروه قیمت';
										|it = 'Gruppo dei prezzi';
										|pl = 'Grupa cenowa';
										|tr = 'Fiyat grubu'", DefaultLanguageCode);
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.BudgetFlowItemDimensions - the object to fill in.
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

#EndRegion

#Region Private

// Fills in predefined elements
//
Procedure FillInPredefinedBudgetItemAnalytics() Export
	
	CCTObject = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.BudgetingItems.GetObject();
	CCTObject.RecordByQuantity = True;
	CCTObject.UnitOfMeasureFilling = "UnitOfMeasure";
	CCTObject.UnitOfMeasurePresentation = NStr("vi = '[Единица хранения]';
												|ru = '[Единица хранения]';
												|en = '[Stock UOM]'; fa = '[Stock UOM]';
												|it = '[Unità di stoccaggio]';
												|pl = '[Единица хранения]';
												|tr = '[Stok ölçü birimi]'");
	InfobaseUpdate.WriteData(CCTObject);
	
	CCTObject = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.ItemKinds.GetObject();
	CCTObject.RecordByQuantity = True;
	CCTObject.UnitOfMeasureFilling = "UnitOfMeasure";
	CCTObject.UnitOfMeasurePresentation = NStr("vi = '[Единица хранения]';
												|ru = '[Единица хранения]';
												|en = '[Stock UOM]'; fa = '[Stock UOM]';
												|it = '[Unità di stoccaggio]';
												|pl = '[Единица хранения]';
												|tr = '[Stok ölçü birimi]'");
	InfobaseUpdate.WriteData(CCTObject);
	
	CCTObject = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.BudgetingFunds.GetObject();
	CCTObject.RecordByCurrency = True;
	CCTObject.CurrencyFilling = "CashCurrency";
	CCTObject.CurrencyPresentation = NStr("vi = '[Валюта денежных средств]';
											|ru = '[Валюта денежных средств]';
											|en = '[Currency of cash]'; fa = '[Currency of cash]';
											|it = '[Valuta dei mezzi finanziari]';
											|pl = '[Waluta środków pieniężnych]';
											|tr = '[Nakit para birimi]'");
	InfobaseUpdate.WriteData(CCTObject);
	
	CCTObject = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Contracts.GetObject();
	CCTObject.RecordByCurrency = True;
	CCTObject.CurrencyFilling = "ARAPCurrency";
	CCTObject.CurrencyPresentation = NStr("vi = '[Валюта взаиморасчетов]';
											|ru = '[Валюта взаиморасчетов]';
											|en = '[AR/AP currency]'; fa = '[AR/AP currency]';
											|it = '[Valuta di regolamento dei conti]';
											|pl = '[Waluta rozliczeń wzajemnych]';
											|tr = '[Alacak/borç hesabı para birimi]'");
	InfobaseUpdate.WriteData(CCTObject);
	
	TableOfReservedNames = TableOfReservedAnalystViewNames();
	
	Selection = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Select();
	While Selection.Next() Do
		CCTObject = Selection.GetObject();
		CCTObject.PresentationValueType = String(CCTObject.ValueType);
		If IsBlankString(CCTObject.Id) Then
			CCTObject.Id = UniqueIdentifierByName(CCTObject.Description, TableOfReservedNames);
		EndIf;
		InfobaseUpdate.WriteData(CCTObject);
	EndDo;
	
EndProcedure

Function TableOfReservedAnalystViewNames()
	// Specifying identifiers for types of analytics, taking into account the uniqueness of the identifiers.
	// The identifiers must not match the reserved parameters for substitution in the text fields of budget
	// reports.
	// If 2 characteristics have a name difference that is not reflected in the identifier,
	// a sequence number will be added to the identifier.
	ReservedVariables = BudgetReportingClientServer.OrderedVariablesOfBudgetReports();
	TableOfReservedNames = New ValueTable();
	TableOfReservedNames.Columns.Add("Id", New TypeDescription("String",, New StringQualifiers(100, AllowedLength.Variable)));
	For Each ParameterNameAndPresentation In ReservedVariables Do
		ParameterString = TableOfReservedNames.Add();
		ParameterString.Id = ParameterNameAndPresentation.Name;
	EndDo;
	Query = New Query;
	Query.Text =
	"SELECT
	|	BudgetFlowItemDimensions.Id AS Id
	|FROM
	|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions
	|WHERE
	|	BudgetFlowItemDimensions.Id <> """"";
	SelectionOfPreviouslyProcessedData = Query.Execute().Select();
	While SelectionOfPreviouslyProcessedData.Next() Do
		ParameterString = TableOfReservedNames.Add();
		ParameterString.Id = SelectionOfPreviouslyProcessedData.Id;
	EndDo;
	TableOfReservedNames.Indexes.Add("Id");
	
	Return TableOfReservedNames;
EndFunction

Function UniqueIdentifierByName(Description, TableOfReservedNames)
	Id = TMCommonUseClientServer.GetID(Description);
	IDToCheck = Id;
	ValueIsUnique = False;
	Counter = 1;
	While Not ValueIsUnique Do
		If TableOfReservedNames.Find(IDToCheck) = Undefined Then
			ValueIsUnique = True;
			Id = IDToCheck;
			Break;
		Else
			IDToCheck = Id + Format(Counter, "NG=0;");
			Counter = Counter + 1;
		EndIf;
	EndDo;
	
	ParameterString = TableOfReservedNames.Add();
	ParameterString.Id = Id;
	
	Return Id;
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

#Region FillSeparatedDataHandlers

	Handler = Handlers.Add();
	Handler.Procedure = "ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FillSeparatedDataHandlers";
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	Handler.Comment = "";

#EndRegion

#Region FillInPredefinedBudgetItemAnalytics

	Handler = Handlers.Add();
	Handler.Procedure = "ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FillInPredefinedBudgetItemAnalytics";
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("65996490-3fcf-47c3-8b17-0305f2909d57");
	Handler.Comment = NStr("vi = 'Cập nhật mục tin phần tử định trước hệ thống dạng đặc tính ""Đối tượng phân tích của khoản mục ngân sách"".';
							|ru = 'Обновляет реквизиты предопределенных элементов ПВХ ""Аналитики статей бюджетов"".';
							|en = 'Updates attributes of predefined items of the ""Budget flow item dimensions"" chart of characteristic types.'; fa = 'Updates attributes of predefined items of the ""Budget flow item dimensions"" chart of characteristic types.';
							|it = 'Обновляет реквизиты предопределенных элементов ПВХ ""Аналитики статей бюджетов"".';
							|pl = 'Updates attributes of predefined items of the ""Budget flow item dimensions"" chart of characteristic types.';
							|tr = 'Önceden tanımlanan ÖTP ""Bütçe kalemleri boyutları"" öğelerinin özniteliklerini günceller.'");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

#EndRegion

EndProcedure

// Fills in the split data handler that depends on changes to the undivided data.
//
// Parameters:
//   Parameters - Structure - structure of handler parameters:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined Then
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Procedure = "ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FillInPredefinedBudgetItemAnalytics";
		Handler.Version = "*";
		Handler.ExecutionMode = "Seamless";
		Handler.Id = New UUID("65996490-3fcf-47c3-8b17-0305f2909d57");
		Handler.Comment = NStr("vi = 'Cập nhật mục tin phần tử định trước hệ thống dạng đặc tính ""Đối tượng phân tích của khoản mục ngân sách"".';
								|ru = 'Обновляет реквизиты предопределенных элементов ПВХ ""Аналитики статей бюджетов"".';
								|en = 'Updates attributes of predefined items of the ""Budget flow item dimensions"" chart of characteristic types.'; fa = 'Updates attributes of predefined items of the ""Budget flow item dimensions"" chart of characteristic types.';
								|it = 'Обновляет реквизиты предопределенных элементов ПВХ ""Аналитики статей бюджетов"".';
								|pl = 'Updates attributes of predefined items of the ""Budget flow item dimensions"" chart of characteristic types.';
								|tr = 'Önceden tanımlanan ÖTP ""Bütçe kalemleri boyutları"" öğelerinin özniteliklerini günceller.'");
		
		Editable1 = New Array;
		Editable1.Add(Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FullName());
		Handler.ObjectsToChange = StrConcat(Editable1, ",");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions);
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
