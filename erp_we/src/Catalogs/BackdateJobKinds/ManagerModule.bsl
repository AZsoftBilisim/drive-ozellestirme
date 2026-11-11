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
//  Items   - ValueTable - fill-in data. The composition of the columns corresponds to the set of object details.
//  TabularSections - Structure - description of the table parts of the object, where:
//   * Key - String - name of the table part;
//   * Value - ValueTable - the tabular part in the form of a table of values, the structure of which
//                                  must be copied before filling in.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region ARAPAllocationByDueDates
	
	Item = Items.Add();
	Item.PredefinedDataName = "ARAPAllocationByDueDates";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Phân bổ hạch toán theo thời hạn';
		|ru = 'Распределение взаиморасчетов по срокам';
		|en = 'AR/AP allocation by due dates';
		|it = 'AR/AP allocation by due dates';
		|pl = 'AR/AP allocation by due dates';
		|tr = 'Karşılıklı mutabakatların süreye göre dağıtımı'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsForARAPAllocating");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Đang thực hiện phân bổ hạch toán theo nhiệm vụ hiện tại cần phân bổ trong biểu ghi ""Nhiệm vụ phân bổ hạch toán công nợ""';
		|ru = 'Выполняется распределение расчетов по текущим заданиям к распределению в регистре ""Задания к распределению взаиморасчетов""';
		|en = 'Allocating AR/AP to the current jobs for allocation in the ""Jobs for allocating AR/AP"" register';
		|it = 'Allocating AR/AP to the current jobs for allocation in the ""Jobs for allocating AR/AP"" register';
		|pl = 'Allocating AR/AP to the current jobs for allocation in the ""Jobs for allocating AR/AP"" register';
		|tr = 'Karşılıklı mutabakatlar, ""Alacak/Borç muhasebesi dağıtımı görevleri"" kayıt tablosundaki mevcut dağıtım görevlerine göre dağıtılmaktadır'",
		LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccounting");
	LineOfATabularSection = Item.RegistersToRead.Add(); 
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccounting");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingByDueDates");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingCashFlowPlan");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingPlannedShipments");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingByDueDates");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingCashFlowPlan");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingPlannedDeliveries");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //ARAPAllocationByDueDates

	#Region UpdateDocumentAmountsInAccountingCurrencies
	
	Item = Items.Add();
	Item.PredefinedDataName = "UpdateDocumentAmountsInAccountingCurrencies";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Cập nhật số tiền của chứng từ theo các loại tiền tệ hạch toán';
		|ru = 'Актуализация сумм документов в валютах учета';
		|en = 'Update document amounts in accounting currencies';
		|it = 'Update document amounts in accounting currencies';
		|pl = 'Update document amounts in accounting currencies';
		|tr = 'Muhasebe para birimleri cinsinden belge tutarlarının güncellenmesi'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Đang tính tổng tiền trong các chứng từ theo các loại tiền tệ hạch toán đối với những chứng từ chưa tính số tiền theo đơn vị tiền tệ của kế toán tài chính và kế toán quản trị, hoặc khi số tiền này khác với số tiền phát sinh của chứng từ theo biểu ghi tính toán.';
		|ru = 'Выполняется расчет сумм документов в валютах учета по тем документам, у которых не рассчитаны суммы в валютах регламентированного и управленческого учета или же они отличаются от сумм движений документа по регистрам расчетов.';
		|en = 'Calculating document amounts in accounting currencies for the documents that do not have calculated amounts in the local accounting currency and the management accounting currency, or that differ from the amounts of document records in calculation registers.';
		|it = 'Calculating document amounts in accounting currencies for the documents that do not have calculated amounts in the local accounting currency and the management accounting currency, or that differ from the amounts of document records in calculation registers.';
		|pl = 'Calculating document amounts in accounting currencies for the documents that do not have calculated amounts in the local accounting currency and the management accounting currency, or that differ from the amounts of document records in calculation registers.';
		|tr = 'Muhasebe para birimleri cinsinden belge tutarlarının hesaplanması, yerel ve yönetim muhasebesi para birimleri cinsinden tutarları hesaplanmamış olan veya hesaplama kayıt tablolarındaki belge kayıtlarının tutarlarından farklı olan belgeler için gerçekleştirilmektedir.'",
		LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.InformationRegisters.Find("DocumentAmountsInAccountingCurrency");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.InformationRegisters.Find("DocumentAmountsInAccountingCurrency");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("DiscountInterestExpense");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //UpdateDocumentAmountsInAccountingCurrencies
	
	#Region UpdateFinancialRegistersRecords
	
	Item = Items.Add();
	Item.PredefinedDataName = "UpdateFinancialRegistersRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi tài chính';
		|ru = 'Актуализация движений по финансовым регистрам';
		|en = 'Update records in financial registers';
		|it = 'Update records in financial registers';
		|pl = 'Update records in financial registers';
		|tr = 'Finansal kayıt tablolarındaki hareketlerin güncellenmesi'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Theo chứng từ đang thực hiện đồng bộ số tiền trong biểu ghi kế toán theo dữ liệu ""Số tiền trong chứng từ theo tiền tệ kế toán""';
		|ru = 'По документам выполняется синхронизация сумм в учетных регистрах по данным ""Суммы документов в валютах учета""';
		|en = 'Synchronizing document amounts in accounting registers by the ""Document amounts in accounting currencies"" data';
		|it = 'Synchronizing document amounts in accounting registers by the ""Document amounts in accounting currencies"" data';
		|pl = 'Synchronizing document amounts in accounting registers by the ""Document amounts in accounting currencies"" data';
		|tr = 'Muhasebe kayıt tablolarındaki tutarlar, ""Muhasebe para birimleri cinsinden belge tutarları"" verilerine göre belgeler tarafından senkronize edilmektedir'",
		LanguagesCodes); // @NStr-2
		
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.InformationRegisters.Find("DocumentAmountsInAccountingCurrency");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("VATInvoiced");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VATPrepaymentsToVendor");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VATPrepaymentsFromCustomer");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("LotsVATForAllocation");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VATRegisterRecords");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherIncome");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherExpenses");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("ItemisedExpensesLots");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RevenueServicesAndAssets");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("InventoryCost");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RevenueAndCOGS");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("Purchases");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherAssetsLiabilities");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCounterpartyIncomeExpenses");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCounterpartyCounterparty");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherAssetsAndLiabilitiesRecords");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("GoodsToBeRegisteredInReportsToConsignor");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("ServicesForRegistrationOfReportsToPrincipal");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("GoodsAndServicesToRegisterPurchasingReportsToConsignor");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	Register = Metadata.AccumulationRegisters.Find("LossAllowance");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("InvestmentInRent");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	
	
	
	#EndRegion
	
	#EndRegion //UpdateFinancialRegistersRecords
	
	#Region UpdateCashCounterpartyCustomersRegisterRecords
	
	Item = Items.Add();
	Item.PredefinedDataName = "UpdateCashCounterpartyCustomersRegisterRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi ""Bản ghi kết chuyển Vốn bằng tiền - Đối tác"" (khách hàng)';
		|ru = 'Актуализация движений по регистру ""Движения Денежные средства - Контрагент"" (клиенты)';
		|en = 'Update records in the ""Cash - Counterparty"" register (customers)';
		|it = 'Update records in the ""Cash - Counterparty"" register (customers)';
		|pl = 'Update records in the ""Cash - Counterparty"" register (customers)';
		|tr = '""Nakit akışı; Cari hesap"" (müşteriler) kayıt tablosundaki hareketlerin güncellenmesi'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Theo các chứng từ có tạo bản ghi kết chuyển trong biểu ghi ""Bản ghi kết chuyển Vốn bằng tiền - Đối tác"" theo khách hàng';
		|ru = 'По документам выполняется формирование движений в регистре ""Движения Денежные средства - Контрагент"" по клиентам';
		|en = 'For the documents, records are being generated in the ""Cash - Counterparty"" register';
		|it = 'For the documents, records are being generated in the ""Cash - Counterparty"" register';
		|pl = 'For the documents, records are being generated in the ""Cash - Counterparty"" register';
		|tr = 'Müşteriler kapsamında ""Nakit akışı; Cari hesap"" kayıt tablosundaki hareketler, belgelere göre düzenlenmektedir'",
		LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCashCounterparty");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCashCounterparty");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //UpdateCashCounterpartyCustomersRegisterRecords
	
	#Region UpdateCashCounterpartyVendorsRegisterRecords
	
	Item = Items.Add();
	Item.PredefinedDataName = "UpdateCashCounterpartyVendorsRegisterRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi ""Bản ghi kết chuyển Vốn bằng tiền - Đối tác"" (nhà cung cấp)';
		|ru = 'Актуализация движений по регистру ""Движения Денежные средства - Контрагент"" (поставщики)';
		|en = 'Update records in the ""Cash - Counterparty"" register (vendors)';
		|it = 'Update records in the ""Cash - Counterparty"" register (vendors)';
		|pl = 'Update records in the ""Cash - Counterparty"" register (vendors)';
		|tr = '""Nakit akışı; Cari hesap"" (tedarikçiler) kayıt tablosundaki hareketlerin güncellenmesi'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"ru = 'По документам выполняется формирование движений в регистре ""Движения Денежные средства - Контрагент"" по поставщикам';
		|vi = 'For the documents, records are being generated in the ""Cash - Counterparty"" register by vendor';
		|en = 'For the documents, records are being generated in the ""Cash - Counterparty"" register by vendor';
		|it = 'For the documents, records are being generated in the ""Cash - Counterparty"" register by vendor';
		|pl = 'For the documents, records are being generated in the ""Cash - Counterparty"" register by vendor';
		|tr = 'Tedarikçilere göre ""Nakit akışı - Cari hesap"" kayıt tablosunda kayıtlar belgeler bazında oluşturuluyor'",
		LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCashCounterparty");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCashCounterparty");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //UpdateCashCounterpartyVendorsRegisterRecords
	
	#Region UpdateCounterpartyCounterpartyRegisterRecords
	
	Item = Items.Add();
	Item.PredefinedDataName = "UpdateCounterpartyCounterpartyRegisterRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi ""Bản ghi kết chuyển Đối tác - Đối tác""';
		|ru = 'Актуализация движений по регистру ""Движения Контрагент - Контрагент""';
		|en = 'Update records in the ""Counterparty - Counterparty"" register';
		|it = 'Update records in the ""Counterparty - Counterparty"" register';
		|pl = 'Update records in the ""Counterparty - Counterparty"" register';
		|tr = '""Cari hesap akışı; Cari hesap"" kayıt tablosundaki hareketlerin güncellenmesi'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Theo các chứng từ, có tạo bản ghi kết chuyển trong biểu ghi ""Bản ghi kết chuyển Đối tác - Đối tác""';
		|ru = 'По документам выполняется формирование движений в регистре ""Движения Контрагент - Контрагент""';
		|en = 'For the documents, records are being generated in the ""Counterparty - Counterparty"" register';
		|it = 'For the documents, records are being generated in the ""Counterparty - Counterparty"" register';
		|pl = 'For the documents, records are being generated in the ""Counterparty - Counterparty"" register';
		|tr = '""Cari hesap akışı; Cari hesap"" kayıt tablosundaki hareketler, belgelere göre düzenlenmektedir'",
		LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCounterpartyCounterparty");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("DiscountInterestExpense");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("LossAllowance");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCounterpartyCounterparty");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //UpdateCounterpartyCounterpartyRegisterRecords
	
	#Region RecordBalanceSheetStatementRegisterRecords
	
	Item = Items.Add();
	Item.PredefinedDataName = "RecordBalanceSheetStatementRegisterRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Phản ánh các bản ghi kết chuyển trong bảng cân đối kế toán quản trị';
		|ru = 'Отражение движений по управленческому балансу';
		|en = 'Record balance sheet statement entries';
		|it = 'Record balance sheet statement entries';
		|pl = 'Record balance sheet statement entries';
		|tr = 'Yönetim bilançosuna göre hareketlerin yansıması'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Theo các chứng từ, có tạo bản ghi kết chuyển trong biểu ghi ""Tài sản và nguồn vốn""';
		|ru = 'По документам выполняется формирование движений в регистре ""Активы и пассивы""';
		|en = 'For the documents, records are being generated in the ""Assets and liabilities"" register';
		|it = 'For the documents, records are being generated in the ""Assets and liabilities"" register';
		|pl = 'For the documents, records are being generated in the ""Assets and liabilities"" register';
		|tr = '""Varlıklar ve yükümlülükler"" kayıt tablosundaki hareketler, belgelere göre düzenlenmektedir'", LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("BankAccountCash");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("CashAccountBalance");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("CashInCashRegistersCR");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("CashInTransit");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("AdvanceHolderCash");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	
	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccounting");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("CustomersARAPAccounting");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("VendorsARAPAccountingByDueDates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("FinancialInstrumentsARAP");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("GiftCertificates");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("TransferredReturnablePackaging");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("ReceivedReturnablePackaging");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherIncome");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherExpenses");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("InventoryCost");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("GoodsToBeRegisteredInReportsToConsignor");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("ServicesForRegistrationOfReportsToPrincipal");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("GoodsAndServicesToRegisterPurchasingReportsToConsignor");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	Register = Metadata.AccumulationRegisters.Find("WIPLaborCosts");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("FixedAssetsDepreciationCharge");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("FACost");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("IntangibleAssetsAmortizationCharge");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("IACost");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("ImpairmentFA");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherWorkInProgressExpenses");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("LossAllowance");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("InvestmentInRent");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("DiscountInterestExpense");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("GoodsCostVariances");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("OtherAssetsLiabilities");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RegisterRecordsByExcises");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("OtherAssetsLiabilities");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //RecordBalanceSheetStatementRegisterRecords
	
	
	#Region RecordInFinancialAccounting

	Item = Items.Add();
	Item.PredefinedDataName = "RecordInFinancialAccounting";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Phản ánh vào kế toán quốc tế (tham khảo)';
		|ru = 'Отражение в международном учете (справочно)';
		|en = 'General ledger posting (for reference)';
		|it = 'General ledger posting (for reference)';
		|pl = 'General ledger posting (for reference)';
		|tr = 'Genel muhasebe kaydı (bilgi amaçlı)'", LanguagesCodes); // @NStr-2

	QueueRegister = Metadata.InformationRegisters.Find("DocumentPostingInFinancialAccounting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());

	#Region RegistersToRead

	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();

	Register = Metadata.AccumulationRegisters.Find("RecordsCounterpartyCounterparty");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.InformationRegisters.Find("DocumentAmountsInAccountingCurrency");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("RegisterRecordsByExcises");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	Register = Metadata.AccumulationRegisters.Find("OtherAssetsAndLiabilitiesRecords");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	Register = Metadata.AccumulationRegisters.Find("RecordsCashCounterparty");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());

	#EndRegion

	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;

	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Phản ánh dữ liệu chứng từ vào kế toán quốc tế';
		|ru = 'Отражение данных документов в международном учете';
		|en = 'Record document data in financial accounting';
		|it = 'Record document data in financial accounting';
		|pl = 'Record document data in financial accounting';
		|tr = 'Genel muhasebede belge verilerinin kaydı'", LanguagesCodes); // @NStr-2

	#EndRegion //RecordInFinancialAccounting
	
	#Region CalculationOfExciseTaxAmounts
	
	Item = Items.Add();
	Item.PredefinedDataName = "RecordExciseRegisterRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Phản ánh biến động liên quan đến thuế TTĐB';
		|ru = 'Отражение движений по акцизам';
		|en = 'Record excise records';
		|it = 'Record excise records';
		|pl = 'Record excise records';
		|tr = 'Tüketim vergisi hareketlerinin yansıması'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Theo các chứng từ, có tạo bản ghi kết chuyển trong biểu ghi ""Biến động liên quan đến thuế TTĐB""';
		|ru = 'По документам выполняется формирование движений в регистре ""Движения по акцизам""';
		|en = 'For the documents, records are being generated in the ""Register records by excises"" register';
		|it = 'For the documents, records are being generated in the ""Register records by excises"" register';
		|pl = 'For the documents, records are being generated in the ""Register records by excises"" register';
		|tr = '""Tüketim vergisi hareketleri"" kayıt tablosundaki hareketler, belgelere göre düzenlenmektedir'",
		LanguagesCodes); // @NStr-2
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RegisterRecordsByExcises");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //CalculationOfExciseTaxAmounts
	
	#Region CalculationOfAssetsLiabilities
	
	Item = Items.Add();
	Item.PredefinedDataName = "RecordOfAssetsAndLiabilitiesRegisterRecords";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"vi = 'Phản ánh tài sản và nguồn vốn';
		|ru = 'Отражение по активам и пассивам';
		|en = 'Record of assets and liabilities';
		|it = 'Record of assets and liabilities';
		|pl = 'Record of assets and liabilities';
		|tr = 'Varlıklara ve yükümlülüklere göre yansıma'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"vi = 'Theo chứng từ ""Ghi giảm hàng thiếu"" và ""Tiêu dùng nội bộ""
		| đang tạo bản ghi kết chuyển trong biểu ghi ""Biến động Tài sản và nguồn vốn khác""';
		|ru = 'По документам ""Списание недостач товаров"" и ""Внутреннее потребление""
		|выполняется формирование движений в регистре ""Движения Прочие активы и пассивы""';
		|en = 'For the ""Stock shortage recognition"" and ""Inventory consumption""  documents,
		|records are being generated in the ""Flow of other assets and liabilities"" register';
		|it = 'For the ""Stock shortage recognition"" and ""Inventory consumption""  documents,
		|records are being generated in the ""Flow of other assets and liabilities"" register';
		|pl = 'For the ""Stock shortage recognition"" and ""Inventory consumption""  documents,
		|records are being generated in the ""Flow of other assets and liabilities"" register';
		|tr = '""Stok eksiği tahakkuku"" ve ""Stok tüketimi"" belgelerine göre,
		|""Diğer varlık ve yükümlülük hareketleri"" kaydında hareketlerin düzenlenmesi gerçekleştirilir'",
		LanguagesCodes); // @NStr-2
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("OtherAssetsAndLiabilitiesRecords");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //CalculationOfAssetsLiabilities
	
	#Region UpdatingOfElectronicTicketsAndOperations
	
	Item = Items.Add();
	Item.PredefinedDataName = "UpdatingOperationsAndStateOfElectronicTicket";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Актуализация операций и состояния электронного билета';
		|vi = 'Update transactions and state of electronic ticket';
		|en = 'Update transactions and state of electronic ticket';
		|it = 'Update transactions and state of electronic ticket';
		|pl = 'Update transactions and state of electronic ticket';
		|tr = 'Elektronik bilet işlemlerinin ve durumun güncellenmesi'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"ru = 'По документу ""Операция с электронным билетом""
		|выполняется актуализация операций и состояния электронного билета';
		|vi = 'For the ""Electronic ticket transaction"" document,
		|the transactions and state of electronic ticket are being updated';
		|en = 'For the ""Electronic ticket transaction"" document,
		|the transactions and state of electronic ticket are being updated';
		|it = 'For the ""Electronic ticket transaction"" document,
		|the transactions and state of electronic ticket are being updated';
		|pl = 'For the ""Electronic ticket transaction"" document,
		|the transactions and state of electronic ticket are being updated';
		|tr = '""Elektronik bilet işlemi""
		| belgesine göre elektronik bilet durum ve işlemlerinin güncellenmesi gerçekleştirilir'",
		LanguagesCodes); // @NStr-2
	
	#EndRegion //UpdatingOfElectronicTicketsAndOperations
	
	#Region DistributionOfSalesByLinesOfBusiness
	
	Item = Items.Add();
	Item.PredefinedDataName = "DistributionOfSalesByLinesOfBusiness";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Распределение продаж по направлениям деятельности';
		|vi = 'Sales allocation by lines of business';
		|en = 'Sales allocation by lines of business';
		|it = 'La distribuzione delle vendite per settore di attività';
		|pl = 'Dystrybucja sprzedaży według działalności';
		|tr = 'İş koluna göre satış dağıtımı'", LanguagesCodes); // @NStr-2
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	Item.Register = Common.MetadataObjectID(QueueRegister.FullName());
	Item.MaximumBatch = 100;
	Item.QueueNumber = 1;
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"ru = 'Распределение продаж в регистре ""Выручка и себестоимость продаж"" по направлениям деятельности.';
		|vi = 'Sales allocation in the ""Revenue and COGS"" register by line of business.';
		|en = 'Sales allocation in the ""Revenue and COGS"" register by line of business.';
		|it = 'Sales allocation in the ""Revenue and COGS"" register by line of business.';
		|pl = 'Sales allocation in the ""Revenue and COGS"" register by line of business.';
		|tr = '""Satış hasılatı ve maliyeti"" sicilindeki satışların faaliyet alanlarına göre dağıtımı.'",
		LanguagesCodes); // @NStr-2
	
	#Region RegistersToRead
	
	Item.RegistersToRead = TabularSections.RegistersToRead.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RevenueAndCOGS");
	LineOfATabularSection = Item.RegistersToRead.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#Region MutableRegisters
	
	Item.MutableRegisters = TabularSections.MutableRegisters.Copy();
	
	Register = Metadata.AccumulationRegisters.Find("RevenueAndCOGS");
	LineOfATabularSection = Item.MutableRegisters.Add();
	LineOfATabularSection.Register = Common.MetadataObjectID(Register.FullName());
	
	#EndRegion
	
	#EndRegion //DistributionOfSalesByLinesOfBusiness
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.BusinessTransactionsSettings - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	Return;
	
EndProcedure

#Region InterfaceImplementation

// CloudTechnology.ExportImportData

// Returns the directory details that form the natural key for the directory elements.
//
// Returns:
//  Array of String - the names of the Attributes that form the natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array;
	
	Result.Add("PredefinedDataName");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.BackdateJobKinds);
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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// Adds information security update procedures to the list for all supported library versions or configurations.
// 
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Assignment tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BackdateJobKinds.FillInPredefinedSettingsForTypesOfNonOperationalTasks";
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("cd45555d-f1f6-4a32-a02a-c00bf89351c1");
	Handler.Comment = NStr("vi = 'Cập nhật các mục tin của phần tử danh mục định trước ""Các dạng nhiệm vụ không hoạt động""';
							|ru = 'Обновляет реквизиты предопределенных элементов справочника  ""Виды неоперативных заданий""';
							|en = 'Updates attributes of predefined items of the ""Backdate job types"" catalog'; fa = 'Updates attributes of predefined items of the ""Backdate job types"" catalog';
							|it = 'Updates attributes of predefined items of the ""Backdate job types"" catalog';
							|pl = 'Updates attributes of predefined items of the ""Backdate job types"" catalog';
							|tr = '""Operasyonel olmayan görev türleri"" kataloğunun önceden tanımlanmış öğelerinin özniteliklerini günceller'");
	Handler.SharedData = True;
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BackdateJobKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

Procedure FillInPredefinedSettingsForTypesOfNonOperationalTasks(Parameters = Undefined) Export
	
	// 1. Deleting Catalog items that are not predefined.
	Query = New Query;
	Query.Text = "
	|SELECT
	|	BackdateJobKinds.Ref AS Ref
	|FROM
	|	Catalog.BackdateJobKinds AS BackdateJobKinds
	|WHERE
	|	NOT BackdateJobKinds.Predefined";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TypeOfNonOperationalTasksObject = Selection.Ref.GetObject();
		TypeOfNonOperationalTasksObject.DataExchange.Load = True;
		TypeOfNonOperationalTasksObject.Delete();
	EndDo;
	
	// 2. Processing of predefined types of non-operational tasks.
	ObjectMetadata = Metadata.Catalogs.BackdateJobKinds;
	SettingsOfUpdate = NationalLanguageSupportServer.SettingsPredefinedDataUpdate(ObjectMetadata);
	
	TabularSections = New Array;
	TabularSections.Add("RegistersToRead");
	TabularSections.Add("MutableRegisters");
	
	For Each ElementData In SettingsOfUpdate.PredefinedData Do
		
		ItemRef1 = Catalogs.BackdateJobKinds[ElementData.PredefinedDataName];
		ObjectElement = ItemRef1.GetObject();
		
		FillPropertyValues(ObjectElement, ElementData, ,
			"Ref, DeletionMark, MaximumBatch, QueueNumber");
		
		If Not ValueIsFilled(ObjectElement.MaximumBatch) Then
			ObjectElement.MaximumBatch = ElementData.MaximumBatch;
		EndIf;
		
		For Each TabularSectionName In TabularSections Do
			ObjectElement[TabularSectionName].Load(ElementData[TabularSectionName]);
		EndDo;
		
		If Common.DataSeparationEnabled() Then
			
			For Each ObjectAttributeToLocalize In SettingsOfUpdate.ObjectAttributesToLocalize Do
				Name = ObjectAttributeToLocalize.Key;
				ObjectElement[Name] = ElementData[Name + "_" + SettingsOfUpdate.DefaultLanguage];

				LanguagesInformationRecords = NationalLanguageSupportServer.LanguagesInfo();
				For Each IsLanguageUsed In LanguagesInformationRecords.Used Do
					If IsLanguageUsed.Value Then
						LanguageCode = LanguagesInformationRecords[IsLanguageUsed.Key];
						ObjectElement[Name + IsLanguageUsed.Key] = ElementData[Name + "_" + LanguageCode];
					EndIf;
				EndDo;
			EndDo;
			
		EndIf;
		
		ObjectElement.DataExchange.Load = True;
		ObjectElement.Write();
		
	EndDo;
	
	FillInQueueNumberForTypesOfNonOperationalTasks();

EndProcedure

Procedure FillInQueueNumberForTypesOfNonOperationalTasks()
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	RegistersToRead.Ref AS JobKind,
	|	RegistersToRead.Register AS RegisterReading
	|INTO TT_RegistersReading
	|FROM
	|	Catalog.BackdateJobKinds.RegistersToRead AS RegistersToRead
	|		LEFT JOIN Catalog.BackdateJobKinds.MutableRegisters AS MutableRegisters
	|		ON RegistersToRead.Ref = MutableRegisters.Ref
	|		AND MutableRegisters.Register = RegistersToRead.Register
	|WHERE
	|	MutableRegisters.Ref IS NULL
	|
	|INDEX BY
	|	RegisterReading,
	|	JobKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BackdateJobKindsMutableRegisters.Ref AS JobKind,
	|	BackdateJobKindsMutableRegisters.Register AS RegisterEntry
	|INTO VT_RegistersEntry
	|FROM
	|	Catalog.BackdateJobKinds.MutableRegisters AS BackdateJobKindsMutableRegisters
	|
	|INDEX BY
	|	RegisterEntry,
	|	JobKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RegistersReading.RegisterReading AS CaseReadingDepends,
	|	TT_RegistersReading.JobKind AS TaskTypeReading,
	|	VT_RegistersEntry.JobKind AS TypeOfTaskRecording
	|INTO VT_RegisterDependency
	|FROM
	|	TT_RegistersReading AS TT_RegistersReading
	|		INNER JOIN VT_RegistersEntry AS VT_RegistersEntry
	|		ON TT_RegistersReading.RegisterReading = VT_RegistersEntry.RegisterEntry
	|		AND VT_RegistersEntry.JobKind <> TT_RegistersReading.JobKind
	|
	|INDEX BY
	|	TaskTypeReading,
	|	TypeOfTaskRecording
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VT_RegisterDependency.TaskTypeReading AS TaskTypeReading,
	|	VT_RegisterDependency.TypeOfTaskRecording AS TypeOfTaskRecording
	|INTO TT_DependenceOfTypesOfTasks
	|FROM
	|	VT_RegisterDependency AS VT_RegisterDependency
	|
	|INDEX BY
	|	TaskTypeReading,
	|	TypeOfTaskRecording
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReadWriteDependency.TaskTypeReading.Description AS TaskTypeReading,
	|	ReadWriteDependency.TypeOfTaskRecording.Description AS TypeOfTaskRecording,
	|	WriteReadDependency.TaskTypeReading AS Conflict
	|FROM
	|	TT_DependenceOfTypesOfTasks AS WriteReadDependency
	|		INNER JOIN TT_DependenceOfTypesOfTasks AS ReadWriteDependency
	|		ON ReadWriteDependency.TypeOfTaskRecording = WriteReadDependency.TaskTypeReading
	|		AND ReadWriteDependency.TaskTypeReading = WriteReadDependency.TypeOfTaskRecording
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_DependenceOfTypesOfTasks.TaskTypeReading AS TaskTypeReading,
	|	TT_DependenceOfTypesOfTasks.TypeOfTaskRecording AS TypeOfTaskRecording
	|FROM
	|	TT_DependenceOfTypesOfTasks AS TT_DependenceOfTypesOfTasks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BackdateJobKinds.Ref AS Ref,
	|	BackdateJobKinds.QueueNumber AS QueueNumber
	|FROM
	|	Catalog.BackdateJobKinds AS BackdateJobKinds
	|WHERE
	|	NOT BackdateJobKinds.Ref IN (&ExcludedTypesOfTasks)";
	
	// Excluded types of tasks are listed in the Catalog for reference.
	// In the mechanism of a non-operational queue, tasks should not be registered and processed for them.
	ExcludedTypesOfTasks = New Array;
	
	
	ExcludedTypesOfTasks.Add(Catalogs.BackdateJobKinds.RecordInFinancialAccounting);
	Query.SetParameter("ExcludedTypesOfTasks", ExcludedTypesOfTasks);
	
	RequestPackages = Query.ExecuteBatch();
	
	CyclicDependence = RequestPackages[4].Unload();
	
	If CyclicDependence.Count() > 0 Then
		
		ListOfDescriptions = New Array;
		ListOfDescriptions.Add(NStr("vi = 'Khi xác định số thứ tự hàng đợi của các dạng nhiệm vụ, đã phát hiện ra các phụ thuộc tuần hoàn:';
									|ru = 'При определении номера очереди видов заданий обнаружены циклические зависимости:';
									|en = 'Circular dependencies are found when determining the job type queue number:'; fa = 'Circular dependencies are found when determining the job type queue number:';
									|it = 'Circular dependencies are found when determining the job type queue number:';
									|pl = 'Circular dependencies are found when determining the job type queue number:';
									|tr = 'Görev türlerinin kuyruk sayısının belirlenmesinde döngüsel bağımlılıklar bulunmuştur:'"));
		
		For Each Dependence In CyclicDependence Do
			
			ListOfDescriptions.Add(StrTemplate(NStr("vi = '- dạng nhiệm vụ ""%1"" phụ thuộc vào ""%2""';
													|ru = '- вид задания ""%1"" зависит от ""%2""';
													|en = '- the ""%1"" job type depends on ""%2""'; fa = '- the ""%1"" job type depends on ""%2""';
													|it = '- the ""%1"" job type depends on ""%2""';
													|pl = '- the ""%1"" job type depends on ""%2""';
													|tr = '- ""%1"" görev türü ""%2"" kapsamında bağlıdır'"),
				Dependence.TaskTypeReading, Dependence.TypeOfTaskRecording));
			
		EndDo;
		
		ExceptionText = StrConcat(ListOfDescriptions, Chars.LF);
		Raise ExceptionText;
		
	EndIf;
	
	DependenceOfTypesOfTasks = RequestPackages[5].Unload();
	DependenceOfTypesOfTasks.Indexes.Add("TaskTypeReading");

	ListOfTypesOfTasks = RequestPackages[6].Unload();
	
	OrderOfQueueTasks = New Map;
	
	// Initial filling of queue numbers for subsequent calculation
	For Each JobKind In ListOfTypesOfTasks Do
		OrderOfQueueTasks.Insert(JobKind.Ref, 1);
	EndDo;
	
	// Determining the queue number taking into account the dependence of the types of tasks
	For Each JobKind In ListOfTypesOfTasks Do
		DetermineTaskNumberByDependency(JobKind.Ref, DependenceOfTypesOfTasks, 0, OrderOfQueueTasks);
	EndDo;
	
	// The automatic calculation of the queue number for the task of the distribution of the direction of activity does not take into account
	// that it must be performed after the actualization of the movement to the financial registers, therefore we will set the queue number +1
	QueueNumberUpdatingRegisterRecordsOfFinancialRegisters = OrderOfQueueTasks[Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords];
	TypeOfTaskObject = Catalogs.BackdateJobKinds.DistributionOfSalesByLinesOfBusiness.GetObject();
	TypeOfTaskObject.QueueNumber = QueueNumberUpdatingRegisterRecordsOfFinancialRegisters + 1;
	TypeOfTaskObject.DataExchange.Load = True;
	TypeOfTaskObject.Write();
	
	NumberOfDocumentReflectionQueue = 0;
	For Each JobKind In ListOfTypesOfTasks Do
		QueueNumber = OrderOfQueueTasks.Get(JobKind.Ref);
		NumberOfDocumentReflectionQueue = Max(NumberOfDocumentReflectionQueue, QueueNumber);
		If Not QueueNumber = JobKind.QueueNumber Then
			TypeOfTaskObject = JobKind.Ref.GetObject();
			TypeOfTaskObject.QueueNumber = QueueNumber;
			TypeOfTaskObject.DataExchange.Load = True;
			TypeOfTaskObject.Write();
		EndIf;
	EndDo;
	
	
	// Reflection of documents in international accounting
	TypeOfTaskObject = Catalogs.BackdateJobKinds.RecordInFinancialAccounting.GetObject();
	TypeOfTaskObject.QueueNumber = NumberOfDocumentReflectionQueue + 1;
	TypeOfTaskObject.DataExchange.Load = True;
	TypeOfTaskObject.Write();
	
EndProcedure

Procedure DetermineTaskNumberByDependency(JobKind, DependenceOfTypesOfTasks, JobNumber, OrderOfQueueTasks) 
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("TaskTypeReading", JobKind);
	
	FoundDependence = DependenceOfTypesOfTasks.FindRows(FilterStructure1);
	If FoundDependence.Count() > 0 Then
		
		For Each CurrentAddiction In FoundDependence Do
			
			JobNumber = OrderOfQueueTasks.Get(CurrentAddiction.TypeOfTaskRecording);
			DetermineTaskNumberByDependency(CurrentAddiction.TypeOfTaskRecording, DependenceOfTypesOfTasks, JobNumber, OrderOfQueueTasks);
			OrderOfQueueTasks.Insert(CurrentAddiction.TypeOfTaskRecording, JobNumber);
			JobNumber = JobNumber + 1;
			
			If OrderOfQueueTasks.Get(JobKind) < JobNumber Then
				OrderOfQueueTasks.Insert(JobKind, JobNumber);
			EndIf;
			
		EndDo;
			
	Else
		
		JobNumber = 1;
		OrderOfQueueTasks.Insert(JobKind, JobNumber); 
		
	EndIf;
	
EndProcedure 

#EndRegion

#EndRegion

#EndIf

