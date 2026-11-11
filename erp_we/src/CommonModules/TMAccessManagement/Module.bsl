#Region Public

#Region OverridableAccessControlFunctions

// See AccessManagementOverridable.OnFillAccessKinds.
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "Departments";
	AccessKind.Presentation    = NStr("vi = 'Bộ phận';
										|ru = 'Подразделения';
										|en = 'Business units'; fa = 'واحدهای تجاری';
										|it = 'Reparti';
										|pl = 'Business units';
										|tr = 'Departmanlar'");
	AccessKind.ValuesType      = Type("CatalogRef.BusinessStructure");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "Warehouses";
	AccessKind.Presentation    = NStr("vi = 'Kho bãi';
										|ru = 'Склады';
										|en = 'Warehouses'; fa = 'انبارها';
										|it = 'Magazzini';
										|pl = 'Warehouses';
										|tr = 'Ambarlar'");
	AccessKind.ValuesType      = Type("CatalogRef.Warehouses");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "CashAccounts";
	AccessKind.Presentation    = NStr("vi = 'Quỹ tiền mặt';
										|ru = 'Кассы';
										|en = 'Cash accounts'; fa = 'صندوق‌ها';
										|it = 'Casse';
										|pl = 'Kasy';
										|tr = 'Kasalar'");
	AccessKind.ValuesType      = Type("CatalogRef.CashAccounts");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "CashRegisters";
	AccessKind.Presentation    = NStr("vi = 'Quầy thu ngân';
										|ru = 'Кассы ККМ';
										|en = 'Cash registers'; fa = 'صندوق‌های فروش';
										|it = 'Cassa fiscale';
										|pl = 'Kasy';
										|tr = 'Yazar kasalar'");
	AccessKind.ValuesType      = Type("CatalogRef.CashRegisters");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "POSTerminals";
	AccessKind.Presentation    = NStr("vi = 'Thiết bị thanh toán thẻ';
										|ru = 'Эквайринговые терминалы';
										|en = 'POS terminals'; fa = 'پایانه‌های فروش (POS)';
										|it = 'Terminali di pagamento POS';
										|pl = 'Terminale acquiringowe';
										|tr = 'PoS terminalleri'");
	AccessKind.ValuesType      = Type("CatalogRef.POSTerminals");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "TypesOfPrices";
	AccessKind.Presentation    = NStr("vi = 'Dạng giá';
										|ru = 'Виды цен';
										|en = 'Price types'; fa = 'انواع قیمت';
										|it = 'Tipi di prezzi';
										|pl = 'Rodzaje cen';
										|tr = 'Fiyat türleri'");
	AccessKind.ValuesType      = Type("CatalogRef.TypesOfPrices");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "BusinessTransactions";
	AccessKind.Presentation = NStr("vi = 'Giao dịch kinh tế';
									|ru = 'Хозяйственные операции';
									|en = 'Business transactions'; fa = 'عملیات تجاری';
									|it = 'Operazioni economiche';
									|pl = 'Operacje gospodarcze';
									|tr = 'Ticari işlemler'");
	AccessKind.ValuesType   = Type("EnumRef.BusinessTransactions");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "CustomerAgreementsReading";
	AccessKind.Presentation = NStr("vi = 'Dạng thỏa thuận với khách hàng (đọc)';
									|ru = 'Виды соглашений с клиентами (чтение)';
									|en = 'Kinds of terms of sales (reading)'; fa = 'Kinds of terms of sales (reading)';
									|it = 'Tipi di accordi con i clienti (lettura)';
									|pl = 'Rodzaje umów z klientami (odczyt)';
									|tr = 'Müşterilerle anlaşma türleri (okuma)'");
	AccessKind.ValuesType   = Type("EnumRef.KindOfTermsOfSalesToRestrictReadAccess");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "TermsOfSaleUpdate";
	AccessKind.Presentation = NStr("vi = 'Dạng thỏa thuận với khách hàng (thay đổi)';
									|ru = 'Виды соглашений с клиентами (изменение)';
									|en = 'Kinds of terms of sales (change)'; fa = 'Kinds of terms of sales (change)';
									|it = 'Tipi di accordi con i clienti (modifica)';
									|pl = 'Rodzaje umów z klientami (zmiana)';
									|tr = 'Müşterilerle anlaşma türleri (değişim)'");
	AccessKind.ValuesType   = Type("EnumRef.KindOfTermsOfSalesToRestrictEditAccess");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "ProductGroups";
	AccessKind.Presentation    = NStr("vi = 'Nhóm mặt hàng';
										|ru = 'Группы номенклатуры';
										|en = 'Item groups'; fa = 'گروه‌های قلم';
										|it = 'Gruppi degli articoli';
										|pl = 'Grupy nomenklatury';
										|tr = 'Ürün grupları'");
	AccessKind.ValuesType      = Type("CatalogRef.Products");
	AccessKind.ValuesGroupsType = Type("CatalogRef.ItemAccessGroups");
	AccessManagement.AddExtraAccessKindTypes(AccessKind,
		Type("CatalogRef.ItemKinds"),
		Type("CatalogRef.ItemAccessGroups"));
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "PartnerGroups";
	AccessKind.Presentation    = NStr("vi = 'Nhóm đối tác';
										|ru = 'Группы партнеров';
										|en = 'Partner groups'; fa = 'Partner groups';
										|it = 'Gruppi di partner';
										|pl = 'Grupy partnerów';
										|tr = 'İş ortağı grupları'");
	AccessKind.ValuesType      = Type("CatalogRef.Partners");
	AccessKind.ValuesGroupsType = Type("CatalogRef.PartnerAccessGroups");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "GroupsOfIndividuals";
	AccessKind.Presentation    = NStr("vi = 'Nhóm cá nhân';
										|ru = 'Группы физических лиц';
										|en = 'Persons'' group'; fa = 'گروه اشخاص';
										|it = 'Gruppi di persone fisiche';
										|pl = 'Grupy osób fizycznych';
										|tr = 'Gerçek kişi grupları'");
	AccessKind.ValuesType      = Type("CatalogRef.Persons");
	AccessKind.ValuesGroupsType = Type("CatalogRef.AccessGroupsOfPersons");
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "GroupsOfBudgetTypes";
	AccessKind.Presentation    = NStr("vi = 'Nhóm các loại ngân sách';
										|ru = 'Группы видов бюджетов';
										|en = 'Groups of budget profiles'; fa = 'Groups of budget profiles';
										|it = 'Gruppi di tipi di bilancio';
										|pl = 'Grupy rodzajów budżetów';
										|tr = 'Bütçe türü grupları'");
	AccessKind.ValuesType      = Type("CatalogRef.BudgetProfiles");
	AccessKind.ValuesGroupsType = Type("CatalogRef.BudgetProfileAccessGroups");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "GroupsOfBudgetItemsAndIndicators";
	AccessKind.Presentation    = NStr("vi = 'Nhóm dạng và chỉ tiêu ngân sách';
										|ru = 'Группы статей и показателей бюджетов';
										|en = 'Groups of budget flow items and indicators'; fa = 'Groups of budget flow items and indicators';
										|it = 'Gruppi di voci e indicatori di bilancio';
										|pl = 'Grupy artykułów i wyników budżetów';
										|tr = 'Kalem ve bütçe gösterge grupları'");
	AccessKind.ValuesType      = Type("CatalogRef.BudgetFlowItems");
	AccessKind.ValuesGroupsType = Type("CatalogRef.AccessGroupsOfBudgetFlowItemsAndIndicators");
	AccessManagement.AddExtraAccessKindTypes(AccessKind,
		Type("CatalogRef.BudgetBalanceItems"),
		Type("CatalogRef.AccessGroupsOfBudgetFlowItemsAndIndicators"));
	AccessManagement.AddExtraAccessKindTypes(AccessKind,
		Type("CatalogRef.NonFinancialItemsOfBudgets"),
		Type("CatalogRef.AccessGroupsOfBudgetFlowItemsAndIndicators"));
		
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "BudgetingScenarios";
	AccessKind.Presentation    = NStr("vi = 'Kịch bản';
										|ru = 'Сценарии';
										|en = 'Scenarios'; fa = 'سناریوها';
										|it = 'Scenari';
										|pl = 'Scenarios';
										|tr = 'Senaryolar'");
	AccessKind.ValuesType      = Type("CatalogRef.BudgetingScenarios");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "StatusesOfInternalAcceptanceCertificate";
	AccessKind.Presentation = NStr("vi = 'Trạng thái biên bản bàn giao công việc nội bộ';
									|ru = 'Статусы актов выполненных внутренних работ';
									|en = 'Statuses of internal works acceptance'; fa = 'وضعیت‌های پذیرش کار داخلی';
									|it = 'Statuses of internal works acceptance';
									|pl = 'Statuses of internal works acceptance';
									|tr = 'Tamamlanan dahili iş tutanaklarının durumları'");
	AccessKind.ValuesType   = Type("EnumRef.StatusesOfInternalAcceptanceCertificate");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "StatusesOfRegisteredRecordsOfProductsAndMaterials";
	AccessKind.Presentation = NStr("vi = 'Trạng thái lưu chuyển sản phẩm và nguyên vật liệu';
									|ru = 'Статусы движений продукции и материалов';
									|en = 'Statuses of product and material transfers'; fa = 'Statuses of product and material transfers';
									|it = 'Stati del movimento di prodotti e materiali';
									|pl = 'Statusy ruchów produkcji i materiałów';
									|tr = 'İmal edilen ürün ve malzeme hareket durumları'");
	AccessKind.ValuesType   = Type("EnumRef.StatusesOfProductsAndMaterialMovement");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "TypesOfGroundsForActOfDiscrepancies";
	AccessKind.Presentation = NStr("vi = 'Kiểu cơ sở biên bản chênh lệch';
									|ru = 'Типы оснований акта о расхождениях';
									|en = 'Types of base documents for discrepancy reports'; fa = 'انواع اسناد مبنا برای گزارش‌های مغایرت';
									|it = 'Tipi di causale dell''atto sulle discrepanze';
									|pl = 'Rodzaje podstaw protokołu o odchyleniu';
									|tr = 'Tutarsızlık raporu gerekçe tipleri'");
	AccessKind.ValuesType   = Type("EnumRef.TypesOfBaseDocumentsForDiscrepancyReport");

	AccessKind = AccessKinds.Add();
	AccessKind.Name = "KindsOfARAPSettlements";
	AccessKind.Presentation = NStr("vi = 'Dạng giao dịch khấu trừ công nợ';
									|ru = 'Виды операций взаимозачета задолженности';
									|en = 'Kinds of AR/AP offsets'; fa = 'Kinds of AR/AP offsets';
									|it = 'Tipi di operazioni della compensazione del debito';
									|pl = 'Rodzaj operacji kompensata zobowiązania';
									|tr = 'Alacak/Borç mahsubu işlem türleri'");
	AccessKind.ValuesType   = Type("EnumRef.KindsOfARAPSettlements");

	AccessKind = AccessKinds.Add();
	AccessKind.Name = "Companies";
	AccessKind.Presentation = NStr("vi = 'Doanh nghiệp';
									|ru = 'Организации';
									|en = 'Companies'; fa = 'شرکت‌ها';
									|it = 'Aziende';
									|pl = 'Companies';
									|tr = 'İş yerleri'");
	AccessKind.ValuesType   = Type("CatalogRef.Companies");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "SalesOperationsPlanningScenarios";
	AccessKind.Presentation = NStr("vi = 'Kịch bản kế hoạch sản phẩm';
									|ru = 'Сценарии товарного планирования';
									|en = 'Sales & operations planning scenarios'; fa = 'سناریوهای برنامه‌ریزی فروش و عملیات';
									|it = 'Scenari di pianificazione merceologica';
									|pl = 'Scenariusze planowania towarowego';
									|tr = 'Ticari planlama senaryosu'");
	AccessKind.ValuesType   = Type("CatalogRef.SalesOperationsPlanningScenarios");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "PlanProfiles";
	AccessKind.Presentation = NStr("vi = 'Dạng kế hoạch';
									|ru = 'Виды планов';
									|en = 'Plan profiles'; fa = 'پروفایل‌های برنامه';
									|it = 'Tipi di piani';
									|pl = 'Rodzaje planów';
									|tr = 'Plan türleri'");
	AccessKind.ValuesType   = Type("CatalogRef.PlanProfiles");
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	// Redefining the restriction of the Property subsystem lists.
	Lists.Insert(Metadata.Catalogs.AdditionalAttributesAndInfoSets, False);
	
	// Redefining the restriction of the Interaction subsystem lists.
	Lists.Insert(Metadata.Documents.Meeting, False);
	Lists.Insert(Metadata.Documents.PlannedInteraction, False);
	Lists.Insert(Metadata.Documents.SMSMessage, False);
	Lists.Insert(Metadata.Documents.PhoneCall, False);
	Lists.Insert(Metadata.Documents.IncomingEmail, False);
	Lists.Insert(Metadata.Documents.OutgoingEmail, False);
	
	// Redefining the restriction of the lists of the subsystem of the commercial offer to the client.
	If Common.SubsystemExists(
		"ElectronicInteraction.CommercialProposals.CommercialProposalsDocuments.CommercialProposalForCustomer") Then
		
		SubsystemModule = Common.CommonModule("Documents.CommercialProposalForCustomer");
		SubsystemModule.OnFillListsWithAccessRestriction(Lists);
		
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles.
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export

	// The "Sales" profile folder.
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "Sales";
	FolderDescription_.Id = "05de7c45-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Bán hàng';
			|ru = 'Продажи';
			|en = 'Sales'; fa = 'فروش';
			|it = 'Vendite';
			|pl = 'Sales';
			|tr = 'Satış'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	// Profile folder "Finance".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "Finances";
	FolderDescription_.Id = "be8dcb8a-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Tài chính';
			|ru = 'Финансы';
			|en = 'Finance'; fa = 'Finance';
			|it = 'Finanze';
			|pl = 'Finance';
			|tr = 'Finans'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	// The "Planning" profile folder.
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "Planning";
	FolderDescription_.Id = "05de7c3d-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Lập kế hoạch';
			|ru = 'Планирование';
			|en = 'Planning'; fa = 'برنامه‌ریزی';
			|it = 'Pianificazione';
			|pl = 'Planning';
			|tr = 'Planlama'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	// The profile folder "Purchases and stocks".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "ProcurementAndInventory";
	FolderDescription_.Id = "05de7c27-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Mua hàng và vật tư';
			|ru = 'Закупки и запасы';
			|en = 'Purchase and inventory'; fa = 'Purchase and inventory';
			|it = 'Acquisti e scorte';
			|pl = 'Zakupy i zapasy';
			|tr = 'Satın alma ve stoklar'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);

	// The folder of profiles "Administration and NSI".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "MasterDataAndSettings";
	FolderDescription_.Id = "05de7c19-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Quản trị và danh mục';
			|ru = 'Администрирование и НСИ';
			|en = 'Control and reference data'; fa = 'Control and reference data';
			|it = 'Amministrazione Informazioni sulle normative di riferimento';
			|pl = 'Ustawienia';
			|tr = 'Yönetim ve Master Veri'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	// Profile folder "Other".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "Other";
	FolderDescription_.Id = "be8dcb7f-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Khác';
			|ru = 'Прочее';
			|en = 'Other'; fa = 'سایر';
			|it = 'Altro';
			|pl = 'Other';
			|tr = 'Diğer'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
#Region Profile_Description_SalesRepresentativeSupervisor
	
	// Profile "Supervisor of sales representatives".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SalesRepresentativeSupervisor";
	ProfileDetails.Id = "ef2371ca-1f4a-4480-be8c-fcb685871343";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Người giám sát đại diện thương mại';
										|ru = 'Супервайзер торговых представителей';
										|en = 'Sales representative supervisor'; fa = 'Sales representative supervisor';
										|it = 'Supervisore dei rappresentanti alle vendite';
										|pl = 'Kierownik przedstawicieli handlowych';
										|tr = 'Satış temsilcilerinin yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading. 
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadAssignments"); 
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadBookingDocuments");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsTransfer");
	ProfileDetails.Roles.Add("ReadInventoryConsumption");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	ProfileDetails.Roles.Add("ReadOtherGoodsRecordingAsReceived");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadCustomsImportDeclarations");
	// Addendum.
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingShipmentBySales");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingReceiptByReturnFromCustomer");
	ProfileDetails.Roles.Add("AddEditCustomerInvoices");
	ProfileDetails.Roles.Add("CreatingReportsOfCompletedWorkWithoutOrder");
	ProfileDetails.Roles.Add("AddEditJobsToSalesRepresentatives");
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	ProfileDetails.Roles.Add("AddEditSettingsOfDataExchangeWithPocketPCs");
	ProfileDetails.Roles.Add("AddEditCustomerTermsOfSales");
	ProfileDetails.Roles.Add("AddEditAccountSalesFromCommissionAgents");
	ProfileDetails.Roles.Add("AddEditCustomerInvoice");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("CreateCustomerInvoicesWithoutReferenceToOrder");
	ProfileDetails.Roles.Add("AddEditReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("AddEditRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("AddEditCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("AddEditCustomerComplaints");
	ProfileDetails.Roles.Add("AddEditCreditNotes");
	ProfileDetails.Roles.Add("AddEditReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("SalesInExcessOfOrder");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedByCustodian");
	ProfileDetails.Roles.Add("AddEditOfGoodsTransferToBailee");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsRegrading");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsDamage");
	ProfileDetails.Roles.Add("AddEditUninvoicedReceiptFromCustodian");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("AddEditStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("AddEditShippedGoodsWriteOffs");
	
	// Directories, adding changes.
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	// Approval of the sale.
	ProfileDetails.Roles.Add("AddEditSaleApproval");
	ProfileDetails.Roles.Add("SaleConditionApprovalParticipantsReportsAndDataProcessors");
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions","Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies", "Predefined");
	ProfileDetails.AccessKinds.Add("TermsOfSaleUpdate", "Predefined");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("QualityControlSubsystem");
	ProfileDetails.Roles.Add("SalesSectionSalesRepresentativeManagement");
	ProfileDetails.Roles.Add("SalesSectionSalesOrderManagement");
	ProfileDetails.Roles.Add("SalesSectionSalesAndReturns");
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SectionTreasuryCash");
	ProfileDetails.Roles.Add("MasterDataSection");
	// Reports, processing.
	ProfileDetails.Roles.Add("SalesRepresentativeSupervisorSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewReportFulfillmentOfRegularConditionsOfTermsOfSales");
	ProfileDetails.Roles.Add("SaleRepresentativeSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UsingCommissionAgentsReportsDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalInvoicesForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalReturnsForRegistrationDataProcessor");
	// Additional Rule
	ProfileDetails.Roles.Add("ChangeSaleDocumentRate");
	
	// H.O. for cash orders, non-cash ds. and contracts of counterparties
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PaymentToVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashReceiptFromCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SaleToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.IssueCashToAdvanceHolder");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfGoodsByCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffOfShippedGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsShipmentToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfTitleToGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsReceiptFromCustomer");
	
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DamageAtCustodian");
	
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DamageAtCustodian");
	
	// Access values by types of grounds for acts of discrepancies
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer");
	
	// Access values by type of agreements with clients
	ProfileDetails.AccessValues.Add("TermsOfSaleUpdate", "Enum.KindOfTermsOfSalesToRestrictEditAccess.SpecialTerms");
	
	AccessManagementLocalization.AddSupervisorSalesRepRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện trao đổi dữ liệu với PDA, tạo
	                                      |nhiệm vụ cho đại diện thương mại, ghi nhận các điều kiện
	                                      |phục vụ khách hàng, phân tích công việc của đại diện thương mại,
	                                      |cũng như thực hiện đồng bộ dữ liệu với ứng dụng di động ""1C:Đơn hàng"".';
	                                      |ru = 'Под профилем осуществляется обмен данными с КПК, формируются
	                                      |задания торговым представителям, регистрируются условия
	                                      |обслуживания клиентов, анализируется работа торговых представителей,
	                                      |а также осуществляется синхронизация данных с мобильным приложением ""1С:Заказы"".';
	                                      |en = 'Use this profile to exchange data with mobile devices, create sales representative tasks,
	                                      |register customer service terms,
	                                      |analyze sales representative work,
	                                      |and synchronize data with mobile application 1C:Orders.'; fa = 'Use this profile to exchange data with mobile devices, create sales representative tasks,
	                                      |register customer service terms,
	                                      |analyze sales representative work,
	                                      |and synchronize data with mobile application 1C:Orders.';
	                                      |it = 'Sotto tale profilo viene effettuato lo scambio dati con KPK, viene creato
	                                      | il task per i rappresentanti commerciali, vengono registrate le condizioni
	                                      | di servizio ai clienti, viene analizzato il lavoro dei rappresentanti commerciali, 
	                                      |avviene la sincronizzazione dei dati con l''app mobile ""1C:Orders""';
	                                      |pl = 'Pod profilem odbywa się wymiana danych z PDA, formują się
	                                      |zadania dla przedstawicieli handlowych, rejestrowane są warunki
	                                      |obsługi klienta, analizuje się praca przedstawicieli handlowych,
	                                      |a także odbywa się synchronizacja danych z aplikacją mobilną ""1C:Orders"".';
	                                      |tr = 'Profil altında MB ile veri alışverişi gerçekleştirilir,
	                                      |satış temsilcileri için görevler oluşturulur, müşteri hizmetleri koşulları
	                                      |kaydedilir, satış temsilcilerinin çalışmaları
	                                      |analiz edilir ve mobil uygulama ""1C:Orders"" ile veri senkronizasyonu da gerçekleştirilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_SalesRepresentative
	// Profile "Sales representative".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SalesRepresentative";
	ProfileDetails.Id = "3afd420c-f9e9-4a88-975e-2e31547ee74c";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Đại diện thương mại';
										|ru = 'Торговый представитель';
										|en = 'Sales representative'; fa = 'نماینده فروش';
										|it = 'Rappresentante commerciale';
										|pl = 'Przedstawiciel handlowy';
										|tr = 'Satış temsilcisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadSettingsOfExchangingDataWithPocketPC");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Create
	ProfileDetails.Roles.Add("AddEditJobsToSalesRepresentatives");
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices","AllAllowedByDefault");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("SalesSectionSalesRepresentativeManagement");
	ProfileDetails.Roles.Add("SalesSectionSalesOrderManagement");
	// Reports, processing.
	ProfileDetails.Roles.Add("SaleRepresentativeSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện đăng nhập vào CSDL của đại diện thương mại,
	                                      |thực hiện trao đổi dữ liệu với thiết bị di động,
	                                      |cũng như thực hiện đồng bộ hóa dữ liệu với ứng dụng di động ""1C:Đơn hàng"".';
	                                      |ru = 'Под профилем осуществляется доступ в ИБ торгового представителя,
	                                      |осуществляется обмен данными с мобильными устройствами,
	                                      |а также осуществляется синхронизация данных с мобильным приложением ""1С:Заказы"".';
	                                      |en = 'Use this profile to access the sales representative infobase,
	                                      |exchange data with mobile devices,
	                                      |and synchronize data with mobile application 1C:Orders.'; fa = 'Use this profile to access the sales representative infobase,
	                                      |exchange data with mobile devices,
	                                      |and synchronize data with mobile application 1C:Orders.';
	                                      |it = 'Sotto il profilo, si accede al database informatico del rappresentante di vendita,
	                                      | i dati vengono scambiati con i dispositivi mobili
	                                      | e sincronizzati con l''applicazione mobile ""1C: Orders"".';
	                                      |pl = 'Pod profilem odbywa się dostęp do BI przedstawiciela handlowego,
	                                      |odbywa się wymiana danych z urządzeniami mobilnymi,
	                                      |a także odbywa się synchronizacja danych z aplikacją mobilną ""1C:Orders"".';
	                                      |tr = 'Profil, satış temsilcisinin Infobase''e erişim,
	                                      |mobil cihazlarla veri alışverişi
	                                      |ve ""1C:Orders"" mobil uygulaması ile veri senkronizasyonu sağlar.'");
	
	AccessManagementLocalization.AddSalesRepresentativeRoles(ProfileDetails);
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_MarketingAssociate
	// Profile "Marketer".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "MarketingAssociate";
	ProfileDetails.Id = "806daef6-c289-49e0-9652-38dcf3fa7677";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Chuyên gia Marketing';
										|ru = 'Маркетолог';
										|en = 'Marketing associate'; fa = 'Marketing associate';
										|it = 'Venditore';
										|pl = 'Marketing associate';
										|tr = 'Pazarlamacı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadInformationAboutMailoutsAndNotificationsToCustomers");
	
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditPaymentRules");
	ProfileDetails.Roles.Add("AddEditProjectTasks");
	ProfileDetails.Roles.Add("AddEditProductSegments");
	ProfileDetails.Roles.Add("AddEditPartnerSegments");
	ProfileDetails.Roles.Add("AddEditStandardTermsOfSalesWithCustomers");
	ProfileDetails.Roles.Add("AddEditPricingRules");
	ProfileDetails.Roles.Add("AddEditMarketingActivities");
	ProfileDetails.Roles.Add("AddEditTermsOfPurchases");
	ProfileDetails.Roles.Add("AddEditPartnerPrices");
	ProfileDetails.Roles.Add("AddEditPartnerItems");
	ProfileDetails.Roles.Add("AddEditCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("AddEditLoyaltyCardKinds");
	ProfileDetails.Roles.Add("AddEditLoyaltyCards");
	ProfileDetails.Roles.Add("AddEditSalesSettingsForUsers");
	ProfileDetails.Roles.Add("AddEditSaleApproval");
	ProfileDetails.Roles.Add("AddEditLoyaltyPrograms");
	ProfileDetails.Roles.Add("AddEditCustomerNotificationKinds");
	ProfileDetails.Roles.Add("AddEditMailoutAndNotificationGroups");
	ProfileDetails.Roles.Add("AddEditSubscriptionsToMailoutsAndNotificationsToCustomers");
	ProfileDetails.Roles.Add("AddEditMailoutsToCustomers");
	ProfileDetails.Roles.Add("AddEditGiftCardKinds");
	ProfileDetails.Roles.Add("AddEditMessageTemplates");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfTransferOrders");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfAssemblyOrders");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadRemainingReceivedReturnablePackaging");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	
	//Surveys
	ProfileDetails.Roles.Add("AddEditPolls");
	ProfileDetails.Roles.Add("AddEditQuestionnairesTemplates");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");

	// Registers, adding change.
	ProfileDetails.Roles.Add("AddEditABCXYZClassificationOfCustomers");
	ProfileDetails.Roles.Add("AddEditABCXYZInventoryClassification");
	ProfileDetails.Roles.Add("AddEditLogisticParameters");
	
	// Documents, adding changes.
	ProfileDetails.Roles.Add("AddEditItemPrices");
	ProfileDetails.Roles.Add("PriceSetupWithoutApproval");
	ProfileDetails.Roles.Add("AddEditProductRange");
	ProfileDetails.Roles.Add("AddEditPurchaseOrders");
	ProfileDetails.Roles.Add("AddEditPurchaseRequests");
	ProfileDetails.Roles.Add("AddEditProvisionRequests");
	ProfileDetails.Roles.Add("AddEditInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("AddEditTransferOrders");
	ProfileDetails.Roles.Add("AddEditMailoutsToCustomers");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	
	// Reports and processing
	ProfileDetails.Roles.Add("ViewReportGoodsSupplySchemes");
	ProfileDetails.Roles.Add("UseCommandABCXYZInventoryClassification");
	ProfileDetails.Roles.Add("UseCommandABCXYZCustomerClassification");
	ProfileDetails.Roles.Add("MarketingAssociateSReports");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Price coordination.
	ProfileDetails.Roles.Add("AddEditApprovalOfItemPrices");
	
	// Coordination of Orders for DOMESTIC CONSUMPTION.
	ProfileDetails.Roles.Add("AddEditApprovalOfInventoryConsumptionOrders");
	
	// Seasonal coefficients
	ProfileDetails.Roles.Add("AddEditSeasonalFactors");
	ProfileDetails.Roles.Add("ReadSeasonalIndexes");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TermsOfSaleUpdate", "Predefined");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingSegmentation");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingCompetitiveIntelligence");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingSalesRules");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingPriceManagementSystem");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingMarketingActivities");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingProductRange");
	ProfileDetails.Roles.Add("SectionMarketingPlanning");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingQuestionnaires");
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("MasterDataSection");
	
	// Access values by type of agreements with clients
	ProfileDetails.AccessValues.Add("TermsOfSaleUpdate", "Enum.KindOfTermsOfSalesToRestrictEditAccess.Standard3");
	
	AccessManagementLocalization.AddMarketerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện ghi nhận đơn giá của đối thủ cạnh tranh,
	                                      |phân tích và phân loại khách hàng và mặt hàng,
	                                      |thiết lập các quy tắc bán hàng và quản lý
	                                      |các chương trình Marketing.';
	                                      |ru = 'Под этим профилем осуществляется регистрация цен конкурентов,
	                                      |проводится анализ и классификация клиентов и номенклатуры,
	                                      |настраиваются правила продаж и происходит управление
	                                      |маркетинговыми мероприятиями.';
	                                      |en = 'Use this profile to register competitor prices,
	                                      |analyze and classify customers and products,
	                                      |set up sales rules, and manage
	                                      |marketing activities.'; fa = 'Use this profile to register competitor prices,
	                                      |analyze and classify customers and products,
	                                      |set up sales rules, and manage
	                                      |marketing activities.';
	                                      |it = 'Sotto questo profilo, viene effettuata la registrazione dei prezzi dei concorrenti,
	                                      | vengono eseguite analisi e classificazioni dei clienti e degli articoli,
	                                      | vengono stabilite le regole di vendita e vengono gestite
	                                      | le attività di marketing.';
	                                      |pl = 'Pod tym profilem odbywa się rejestracja cen konkurentów,
	                                      |analiza i klasyfikacja klientów i nomenklatury,
	                                      |konfiguracja zasady sprzedaży i zarządzanie
	                                      |marketingowymi działaniami.';
	                                      |tr = 'Bu profil altında rakiplerin fiyatları kaydedilir,
	                                      |müşteriler ve öğe analiz edilir ve sınıflandırılır,
	                                      |satış kuralları oluşturulur ve
	                                      |pazarlama faaliyetleri yönetilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region _profileDescription_ApprovalOfPriceTypes

	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "PriceTypeApproval";
	ProfileDetails.Id = "1c6b17c5-3640-11f0-bd09-e89c25df8ebe";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Xác nhận dạng giá (bổ sung)';
										|ru = 'Утверждение видов цен (дополнительный)';
										|en = 'Price type approval (additional)'; fa = 'Price type approval (additional)';
										|it = 'Price type approval (additional)';
										|pl = 'Price type approval (additional)';
										|tr = 'Fiyat türlerinin onayı (ek)'");
	
	ProfileDetails.Roles.Add("PriceTypeApproval");
	
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_SalesDirector
	// DOES ALL THE AGREEMENTS.
	// Profile "Head of sales department".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SalesDirector";
	ProfileDetails.Id = "ae883b07-11cf-4bea-9bce-46473350db16";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Trưởng phòng bán hàng';
										|ru = 'Руководитель отдела продаж';
										|en = 'Sales Director'; fa = 'Sales Director';
										|it = 'Responsabile della sezione vendita';
										|pl = 'Kierownik działu sprzedaży';
										|tr = 'Satış bölümü müdürü'");
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadMessageTemplates");
	ProfileDetails.Roles.Add("ReadLeaseContracts");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadBookingDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsIssues");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadInventoryAssignmentAdjustingEntries");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");
	ProfileDetails.Roles.Add("ReadRetailSalesReports");	
	ProfileDetails.Roles.Add("ReadJobsToSalesRepresentatives");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets"); 
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfSurplusesAndShortages");
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadingTrips");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("ReadDepositCashWithdrawalByCashRegister");
	ProfileDetails.Roles.Add("ReadCashRegisterReceipts");
	ProfileDetails.Roles.Add("ReadCashReceiptsOfAdjustment");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	ProfileDetails.Roles.Add("ReadInvoicesForLeaseServices");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditVehicles");
	ProfileDetails.Roles.Add("AddEditPaymentRules");
	ProfileDetails.Roles.Add("AddEditOpportunityProcessingRules");
	ProfileDetails.Roles.Add("AddEditOpportunities");
	ProfileDetails.Roles.Add("AddEditProjectTasks");
	ProfileDetails.Roles.Add("AddEditStandardTermsOfSalesWithCustomers");
	ProfileDetails.Roles.Add("AddEditCustomerTermsOfSales");
	ProfileDetails.Roles.Add("AddEditCustomerComplaints");
	ProfileDetails.Roles.Add("AddEditRulesForCustomerComplaintProcessing");
	ProfileDetails.Roles.Add("AddEditCounterpartyContracts");
	ProfileDetails.Roles.Add("AddEditLoyaltyCards");
	ProfileDetails.Roles.Add("AddEditSalesSettingsForUsers");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	
	// Documents, adding changes.
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingShipmentBySales");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingReceiptByReturnFromCustomer");
	ProfileDetails.Roles.Add("AddEditCustomerInvoice");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("CreateCustomerInvoicesWithoutReferenceToOrder");
	ProfileDetails.Roles.Add("AddEditReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	ProfileDetails.Roles.Add("AddEditInventoryAssignmentAdjustmentEntries");
	ProfileDetails.Roles.Add("AdditionalOperationsOfInventoryAssignmentAdjustment");
	ProfileDetails.Roles.Add("AddEditRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditARAPReconciliation");
	ProfileDetails.Roles.Add("AddEditCustomerInvoices");
	ProfileDetails.Roles.Add("CreatingReportsOfCompletedWorkWithoutOrder");
	ProfileDetails.Roles.Add("AddEditCreditNotes");
	ProfileDetails.Roles.Add("AddEditReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("SalesInExcessOfOrder");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocumentsPaymentOffset");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedByCustodian");
	ProfileDetails.Roles.Add("AddEditOfGoodsTransferToBailee");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsRegrading");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsDamage");
	ProfileDetails.Roles.Add("AddEditUninvoicedReceiptFromCustodian");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("AddEditStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("AddEditShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("AddEditAccountSalesFromCommissionAgents");
	ProfileDetails.Roles.Add("AddEditSourceDocuments");
	ProfileDetails.Roles.Add("AddEditARAPAccountingScheduleAdjustment");
	ProfileDetails.Roles.Add("AddAndEditDeliveryOrders");
	
	// Approval of the sale.
	ProfileDetails.Roles.Add("AddEditSaleApproval");
	ProfileDetails.Roles.Add("SaleConditionApprovalParticipantsReportsAndDataProcessors");
	ProfileDetails.Roles.Add("VarianceFromSalesTermsAndConditions");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalanceOfAdvanceHolders");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingOpportunityProcessing");
	ProfileDetails.Roles.Add("SalesSectionSalesRepresentativeManagement");
	ProfileDetails.Roles.Add("SalesSectionSalesOrderManagement");
	ProfileDetails.Roles.Add("SalesSectionSalesAndReturns");
	ProfileDetails.Roles.Add("SectionSalesControlOfCustomersARAPAccounting");
	ProfileDetails.Roles.Add("SalesSectionConsignmentSales");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingSalesRules");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingPriceManagementSystem");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingMarketingActivities");
	ProfileDetails.Roles.Add("SectionMarketingPlanning");
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("SalesSectionRetailSales");
	ProfileDetails.Roles.Add("QualityControlSubsystem");
	
	// Reports, processing
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("SalesDirectorReports");
	ProfileDetails.Roles.Add("ViewSalesProfitabilityAssessmentReport");
	ProfileDetails.Roles.Add("ViewConsignmentSalesStockReport");
	ProfileDetails.Roles.Add("ViewReportFulfillmentOfRegularConditionsOfTermsOfSales");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalInvoicesForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalReturnsForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");	
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Additional rights
	ProfileDetails.Roles.Add("ChangeSaleDocumentRate");
	ProfileDetails.Roles.Add("ReadInformationOnFixedAssets");
	// Types of access
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("CashAccounts", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies", "Predefined");
	ProfileDetails.AccessKinds.Add("TermsOfSaleUpdate", "Predefined");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", "Predefined");
	
	// H.O. for cash orders, applications, non-cash ds. and contracts of counterparties
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashReceiptFromCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.IssueCashToAdvanceHolder");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SaleToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfGoodsByCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffOfShippedGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DamageAtCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SalesViaCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsShipmentToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfTitleToGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsReceiptFromCustomer");
	
	// Access values by types of grounds for acts of discrepancies
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer");
	
	// Access values by type of agreements with clients
	ProfileDetails.AccessValues.Add("TermsOfSaleUpdate", "Enum.KindOfTermsOfSalesToRestrictEditAccess.Standard3");
	ProfileDetails.AccessValues.Add("TermsOfSaleUpdate", "Enum.KindOfTermsOfSalesToRestrictEditAccess.SpecialTerms");
	// Access values by types of debt offset operations
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty");
	
	AccessManagementLocalization.AddSalesManagerRoles_(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thiết lập quy tắc tiến hành vụ việc trong
	                                      |doanh nghiệp, phân tích hiệu quả vụ việc.';
	                                      |ru = 'Под профилем настраиваются правила ведения сделок на
	                                      |предприятии, анализируется эффективность сделок.';
	                                      |en = 'Use this profile to set up sales opportunity processing rules in the 
	                                      |enterprise and analyze opportunity efficiency.'; fa = 'Use this profile to set up sales opportunity processing rules in the 
	                                      |enterprise and analyze opportunity efficiency.';
	                                      |it = 'Sotto questo profilo vengono stabilite le regole di gestione delle transazioni 
	                                      |nell''impresa e viene analizzata l''efficacia delle transazioni stesse.';
	                                      |pl = 'Pod profilem konfigurują się zasady prowadzenia transakcji w
	                                      |firmie, analizuje skuteczność transakcji.';
	                                      |tr = 'Profil altında, işletmedeki işlemlerin yürütülmesine ilişkin kurallar
	                                      |ayarlanır ve işlemlerin verimliliği analiz edilir.'", Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_SalesManager
	// Profile "Sales Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SalesManager";
	ProfileDetails.Id = "44d4fd93-99ca-40e7-be0a-3b0321a39d3b";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Bộ quản lý theo bán hàng';
										|ru = 'Менеджер по продажам';
										|en = 'Sales manager'; fa = 'Sales manager';
										|it = 'Manager per le vendite';
										|pl = 'Kierownik sprzedaży';
										|tr = 'Satış müdürü'");
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadSeasonalIndexes");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadMessageTemplates");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");	
	ProfileDetails.Roles.Add("ReadRetailSalesReports");
	ProfileDetails.Roles.Add("ReadJobsToSalesRepresentatives");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadingTrips");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadCashRegisterReceipts");
	ProfileDetails.Roles.Add("ReadCashReceiptsOfAdjustment");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	ProfileDetails.Roles.Add("ReadPeriodEndTransactions");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditOpportunities");
	ProfileDetails.Roles.Add("AddEditProjectTasks");
	ProfileDetails.Roles.Add("AddEditVehicles");
	ProfileDetails.Roles.Add("AddEditCustomerComplaints");
	ProfileDetails.Roles.Add("AddEditCounterpartyContracts");
	ProfileDetails.Roles.Add("AddEditLoyaltyCards");
	ProfileDetails.Roles.Add("AddEditCashRegisterShift");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("AddEditCounterpartiesItemsEDL");
	
	// Documents, adding changes.
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingShipmentBySales");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingReceiptByReturnFromCustomer");
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	ProfileDetails.Roles.Add("AddEditAccountSalesFromCommissionAgents");
	ProfileDetails.Roles.Add("AddEditCustomerInvoice");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("CreateCustomerInvoicesWithoutReferenceToOrder");
	ProfileDetails.Roles.Add("AddEditPurchasingReportsToConsignor");
	ProfileDetails.Roles.Add("AddEditCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("AddEditReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("AddEditRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("AddEditCustomerTermsOfSales");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditARAPReconciliation");
	ProfileDetails.Roles.Add("AddEditCustomerInvoices");
	ProfileDetails.Roles.Add("CreatingReportsOfCompletedWorkWithoutOrder");
	ProfileDetails.Roles.Add("AddEditCreditNotes");
	ProfileDetails.Roles.Add("AddEditReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("SalesInExcessOfOrder");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocumentsPaymentOffset");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedByCustodian");
	ProfileDetails.Roles.Add("AddEditOfGoodsTransferToBailee");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsRegrading");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsDamage");
	ProfileDetails.Roles.Add("AddEditUninvoicedReceiptFromCustodian");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("AddEditStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("AddEditShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("AddEditIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("AddEditSourceDocuments");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("AddEditARAPAccountingScheduleAdjustment");
	ProfileDetails.Roles.Add("AddAndEditDeliveryOrders");
	
	// Approval of the sale.
	ProfileDetails.Roles.Add("AddEditSaleApproval");
	ProfileDetails.Roles.Add("SaleConditionApprovalParticipantsReportsAndDataProcessors");
	
	// Reports and processing
	ProfileDetails.Roles.Add("WarehouseSectionReports");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("SalesRepresentativeReports");
	ProfileDetails.Roles.Add("ViewPOSShiftStateReport");
	ProfileDetails.Roles.Add("ViewSalesProfitabilityAssessmentReport");
	ProfileDetails.Roles.Add("ViewConsignmentSalesStockReport");
	ProfileDetails.Roles.Add("ViewReportFulfillmentOfRegularConditionsOfTermsOfSales");
	ProfileDetails.Roles.Add("ViewTransferredReturnablePackagingReports");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("UseSalesWizard");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UsingCommissionAgentsReportsDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalInvoicesForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalReturnsForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorManagementOfTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	ProfileDetails.Roles.Add("UseSourceDocumentOriginalsRecordKeepingLogProcessing");
	ProfileDetails.Roles.Add("UsingReportsToConsignorsDocumentJournalDataProcessor");
	
	// Additional rights.
	ProfileDetails.Roles.Add("VarianceFromSalesTermsAndConditions");
	ProfileDetails.Roles.Add("AddEditObjectPrintSettings");
	ProfileDetails.Roles.Add("SaveObjectPrintSettingsByDefault");
	ProfileDetails.Roles.Add("ChangeSaleDocumentRate");
	ProfileDetails.Roles.Add("ReadInformationOnFixedAssets");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);

	// Types of access
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies", "Predefined");
	ProfileDetails.AccessKinds.Add("TermsOfSaleUpdate", "Predefined");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", "Predefined");
	
	// H.O. for cash orders and contracts with counterparties
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashReceiptFromCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SaleToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PaymentToVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundFromVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfGoodsByCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DeliveryForPrincipal");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffOfShippedGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DamageAtCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SalesViaCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsShipmentToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfTitleToGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsReceiptFromCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnOfGoodsFromCustomer");
	
	// Access values by types of grounds for acts of discrepancies
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer");
	
	// Access values by type of agreements with clients
	ProfileDetails.AccessValues.Add("TermsOfSaleUpdate", "Enum.KindOfTermsOfSalesToRestrictEditAccess.SpecialTerms");
	// Access values by types of debt offset operations
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	ProfileDetails.Roles.Add("SectionCRMAndMarketingOpportunityProcessing");
	ProfileDetails.Roles.Add("SectionMarketingPlanning");
	ProfileDetails.Roles.Add("QualityControlSubsystem");

	AccessManagementLocalization.AddSalesManagerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện quản lý vụ việc, giao
	                                      |hàng hóa và dịch vụ, trả lại hàng hóa, kiểm soát người nhận ký gửi,
	                                      |thực hiện đồng bộ dữ liệu với ứng dụng di động ""1C:Đơn hàng"".';
	                                      |ru = 'Под профилем осуществляется управление сделками, реализация
	                                      |товаров и услуг, возвраты товара, контролируются комиссионеры,
	                                      |а также осуществляется синхронизация данных с мобильным приложением ""1С:Заказы"".';
	                                      |en = 'Use this profile to manage sales opportunities, sell
	                                      |goods and services, return goods, control consignees,
	                                      |and synchronize data with mobile application 1C:Orders.'; fa = 'Use this profile to manage sales opportunities, sell
	                                      |goods and services, return goods, control consignees,
	                                      |and synchronize data with mobile application 1C:Orders.';
	                                      |it = 'Sotto questo profilo viene effettuata la gestione delle transazioni, la vendita
	                                      | di merci e servizi, la restituzione della merce, la verifica degli agenti in conto vendita,
	                                      | la sincronizzazione dei dati con l''app ""1C:Orders"".';
	                                      |pl = 'Pod profilem odbywa się zarządzanie umowami, realizacja
	                                      |towarów i usług, zwroty towaru, są kontrolowani komisanci,,
	                                      |a także odbywa się synchronizacja danych z aplikacją mobilną ""1C:Orders"".';
	                                      |tr = 'Profil altında işlemleri, ürün ve hizmet satışlarını,
	                                      |iadeleri yönetilebilir, konsinyeleri kontrol edilebilir ve
	                                      |verileri mobil uygulama ""1C:Orders"" ile senkronize edilebilinir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_Cashier
	// Profile "Cashier".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Cashier";
	ProfileDetails.Id = "1167e360-4f81-4114-968e-c4264a06baa0";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Thu ngân';
										|ru = 'Кассир';
										|en = 'Cashier'; fa = 'صندوق‌دار';
										|it = 'Cassiere';
										|pl = 'Cashier';
										|tr = 'Kasiyer'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadLoanAndDepositContracts");
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadDepositCashWithdrawalByCashRegister");//
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadLeaseContracts");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadPurchasingReportsToConsignor");
	ProfileDetails.Roles.Add("ReadApplicationsForBusinessTrip");
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsByCustodian");
	ProfileDetails.Roles.Add("ReadStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("ReadMisgradingOfGoodsAtCustodian");
	ProfileDetails.Roles.Add("ReadDamageAtCustodian");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadPlannedCashInflow");
	ProfileDetails.Roles.Add("ReadCashTransferOrders");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadInformationOnFixedAssets");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	ProfileDetails.Roles.Add("ReadFinancialInstrumentsARAP");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("ReadCustomsImportDeclarations");
	
	// Documents, creation.
	ProfileDetails.Roles.Add("AddEditPaymentCardTransactions");
	ProfileDetails.Roles.Add("AddEditCashAccountDocuments");
	ProfileDetails.Roles.Add("AddEditCashRegisterShift");
	
	// Registers reading
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Registers of advanced cash analytics
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalanceOfAdvanceHolders");
	ProfileDetails.Roles.Add("ReadCashBalance");
	ProfileDetails.Roles.Add("ReadRecordsCashIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCashCounterparty");
	ProfileDetails.Roles.Add("ReadCashTransfers");
	ProfileDetails.Roles.Add("ReadPaymentSchedule");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SectionTreasuryAcquiring");
	ProfileDetails.Roles.Add("SectionTreasuryCash");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("SectionTreasuryCashForecasting");
	
	// Reports and processing
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("CashierSReports");
	ProfileDetails.Roles.Add("ViewPOSShiftStateReport");
	ProfileDetails.Roles.Add("AddEditLoyaltyServer");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("CashAccounts", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("POSTerminals", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddCashierRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ này, sẽ tạo các giao dịch tiền mặt.';
									|ru = 'Под профилем происходит оформление кассовых операций.';
									|en = 'Use this profile to register cash transactions.'; fa = 'Use this profile to register cash transactions.';
									|it = 'Sotto questo profilo vengono eseguite le operazioni di cassa.';
									|pl = 'Pod profilem odbywa się dokonywanie operacji kasowych.';
									|tr = 'Profil altında nakit işlemleri kaydedilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Create_profile_SellerCashierCashRegister
	// Profile "Seller-cashier of KKM".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SellerCashierOfCashRegister";
	ProfileDetails.Id = "b93bb8a1-04fa-4c1a-ac3c-75fb05366782";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Nhân viên bán hàng kiêm thu ngân';
										|ru = 'Продавец-кассир ККМ';
										|en = 'Seller/Cashier'; fa = 'Seller/Cashier';
										|it = 'Cassiere';
										|pl = 'Sprzedawca-kasjer KF';
										|tr = 'YK satıcı-kasiyer'", Common.DefaultLanguageCode());
	
	TMAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadMessageTemplates");

	// Documents, reading.
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("SalesSectionRetailSales");
	// Documents, creation.
	ProfileDetails.Roles.Add("AddEditCashRegisterReceipts");
	ProfileDetails.Roles.Add("AddEditOfCashRegisterReceiptAdjustment");
	ProfileDetails.Roles.Add("AddingChangingReportsOnRetailReturns");	
	ProfileDetails.Roles.Add("AddEditRetailSalesReports");
	ProfileDetails.Roles.Add("AddEditDepositCashWithdrawalByCashRegister");
	ProfileDetails.Roles.Add("AddEditCashRegisterShift");
	ProfileDetails.Roles.Add("AddEditSaleReturnOfGiftCard");
	// Directories, adding changes.
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadCashBalanceInCashRegister");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing
	ProfileDetails.Roles.Add("CashRegisterCashierReports");
	ProfileDetails.Roles.Add("ViewPOSShiftStateReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, có thực hiện các công việc với MTT trong ngày và đóng
	                                      |phiên thu ngân.';
	                                      |ru = 'Под профилем происходит работа с ККМ в течение дня и закрытие
	                                      |кассовой смены.';
	                                      |en = 'Use this profile to operate with cash registers during the day and close
	                                      |POS shifts.'; fa = 'Use this profile to operate with cash registers during the day and close
	                                      |POS shifts.';
	                                      |it = 'Sotto il profilo, il lavoro con il registratore di cassa si svolge durante il giorno e la chiusura
	                                      | del turno di cassa.';
	                                      |pl = 'Pod profilem wakonywane jest praca z KF w ciągu dnia i zamknięcie 
	                                      |kasowej zmiany.';
	                                      |tr = 'Profil altında gün boyunca YK ile çalışılır ve
	                                      |kasa vardiyası kapatılır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Create_profile_RetailManager
	// Profile "Retail Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "RetailManager";
	ProfileDetails.Id = "4c72e308-ff96-40b3-b066-f2dfda73d323";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Người quản lý bán lẻ';
										|ru = 'Менеджер по розничной торговле';
										|en = 'Retail manager'; fa = 'Retail manager';
										|it = 'Retail manager';
										|pl = 'Menadżer ds handlu detalicznego';
										|tr = 'Perakende ticaret yöneticisi'", Common.DefaultLanguageCode());
	
	TMAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadMessageTemplates");
	
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddEditOfflinePeripherals");
	ProfileDetails.Roles.Add("AddEditLoyaltyCards");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	
	// Documents, reading.

	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadCashRegisterReceipts");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("AddEditRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("AddEditCashRegisterShift");
	ProfileDetails.Roles.Add("AddEditOfCashRegisterReceiptAdjustment");
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("SalesSectionRetailSales");
	ProfileDetails.Roles.Add("SalesSectionSalesAndReturns");
	ProfileDetails.Roles.Add("MasterDataSection");
	// Documents, creation.
	ProfileDetails.Roles.Add("AddingChangingReportsOnRetailReturns");	
	ProfileDetails.Roles.Add("AddEditRetailSalesReports");
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceInCashRegister");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("RetailSaleManagerSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewPOSShiftStateReport");
	ProfileDetails.Roles.Add("ViewReportInventorySchedule");
	ProfileDetails.Roles.Add("WarehouseSectionReports");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("CashAccounts", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("CashRegisters", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("POSTerminals", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "Predefined");
	// Access values.
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashIssueToCashRegister");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashReceiptFromCashRegister");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SaleToCustomer");
	
	AccessManagementLocalization.AddRetailManagerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện ghi nhận bán hàng thông qua MTT,
	                                      |in nhãn giá và nhãn tem, lập bảng kê bán lẻ.';
	                                      |ru = 'Под профилем осуществляется регистрация продаж через ККМ,
	                                      |печатаются ценники и этикетки, формируется отчетность розничной торговли.';
	                                      |en = 'Use this profile to register sales via cash registers, 
	                                      |print price tags and labels, generate retail reporting.'; fa = 'Use this profile to register sales via cash registers, 
	                                      |print price tags and labels, generate retail reporting.';
	                                      |it = 'Sotto il profilo le vendite vengono registrate tramite registratore di cassa
	                                      |, i cartellini dei prezzi e le etichette vengono stampate, vengono generati i rapporti di commercio al dettaglio.';
	                                      |pl = 'Pod profilem odbywa się rejestracja sprzedaży przez KF,
	                                      |drukowanie metek i etykiet, powstaje raportowanie sprzedaży detalicznej.';
	                                      |tr = 'Profil altında YK
	                                      |aracılığıyla satışları kaydedebilir, fiyat etiketleri ve etiketler yazdırabilir ve perakende raporları oluşturulabilinir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_Accountant
	// Profile "Accountant".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Accountant";
	ProfileDetails.Id = "84acd69c-4114-4d0a-82b2-226033948e12";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Kế toán viên';
										|ru = 'Бухгалтер';
										|en = 'Accountant'; fa = 'حسابدار';
										|it = 'Contabile';
										|pl = 'Accountant';
										|tr = 'Muhasebeci'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	AddAccountantLocalAccountingRolesToRead(ProfileDetails);
	AddAccountantRolesLocalAccountingRolesForChange(ProfileDetails);
		
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");

	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện lập bảng kê bán
	                                      |lẻ, phản ánh kiểm kê hàng hóa, tính
	                                      |giá vốn, phân bổ lợi nhuận theo mảng
	                                      |hoạt động, lập các chứng từ bán hàng trong nội bộ doanh nghiệp.';
	                                      |ru = 'Под профилем происходит формирование отчетности розничной
	                                      |торговли, отражается инвентаризация товаров, рассчитывается
	                                      |себестоимость, распределяется прибыль по направлениям
	                                      |деятельности, оформляются внутрифирменные продажи.';
	                                      |en = 'Use this profile to generate retail reporting,
	                                      |record physical inventory count of goods, calculate
	                                      |cost, allocate profit by lines
	                                      |of business, and register intracompany sales.'; fa = 'Use this profile to generate retail reporting,
	                                      |record physical inventory count of goods, calculate
	                                      |cost, allocate profit by lines
	                                      |of business, and register intracompany sales.';
	                                      |it = 'Sotto questo profilo vengono creati i report per il commercio
	                                      | al dettagli, viene riflessa l''inventario delle merci, viene calcolato il costo di produzione
	                                      |, viene distribuito l''utile per direzioni
	                                      | di attività, vengono effettuate vendite intra-aziendali.';
	                                      |pl = 'Pod profilem odbywa się tworzenie raportów sprzedaży
	                                      |detalicznej, odzwierciedla się inwentaryzacja towarów, oblicza się
	                                      |koszty własne, rozdziela się zysk po kierunkach
	                                      |działalności, są wystawiane sprzedaże wewnątrz firmy.';
	                                      |tr = 'Profil, perakende
	                                      |ticaret satış raporları oluşturmak, fiziksel stok sayımını yansıtmak, satışların maliyetini
	                                      |hesaplamak, kârları iş kollarına
	                                      |göre dağıtmak ve şirketler arası satışları işlemek için kullanılır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_Treasurer
	// Profile "Treasurer".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Treasurer";
	ProfileDetails.Id = "9f46c8c7-1a0c-4ecb-aea8-0be64724b259";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Thủ quỹ';
										|ru = 'Казначей';
										|en = 'Treasurer'; fa = 'Treasurer';
										|it = 'Tesoriere';
										|pl = 'Treasurer';
										|tr = 'Hazinedar'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Master data
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadAssignments"); 
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadDepositCashWithdrawalByCashRegister");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadLeaseContracts");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	// Reports and processing
	ProfileDetails.Roles.Add("TreasurerSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("UseLoanAndDepositRegistry");
	ProfileDetails.Roles.Add("UseSalesVarianceOfFinancialInstruments");
	ProfileDetails.Roles.Add("UseLoanAndDepositItemsAnalysis");
	ProfileDetails.Roles.Add("ViewCashFlowStatements");
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
		
	//Pricesreferences
	ProfileDetails.Roles.Add("ReadItemsPrices"); 
	
	// Documents reading
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsIssue");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadBookingDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadExpenseReports");
	ProfileDetails.Roles.Add("ReadAdjustmentsOfARAPAccountingForAdvanceHolders");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadApplicationsForBusinessTrip");
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsByCustodian");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("ReadMisgradingOfGoodsAtCustodian");
	ProfileDetails.Roles.Add("ReadDamageAtCustodian");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");	
	ProfileDetails.Roles.Add("ReadRetailSalesReports");
	ProfileDetails.Roles.Add("ReadMerchantStatements");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadPlannedCashInflow");
	ProfileDetails.Roles.Add("ReadCashTransferOrders");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadInventoryRecounts");
	ProfileDetails.Roles.Add("ReadNotesForRecordingSurplusesShortagesDamage");
	ProfileDetails.Roles.Add("ReadVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	ProfileDetails.Roles.Add("ReadCashBook");
	ProfileDetails.Roles.Add("ReadCustomsImportDeclarations");

	// Adding directories.
	ProfileDetails.Roles.Add("AddEditBanks");
	ProfileDetails.Roles.Add("AddEditLoansAndDepositsContracts");
	ProfileDetails.Roles.Add("AddEditCashFlowClassifiersAndSettings");
	// Adding documents.
	ProfileDetails.Roles.Add("AddEditBankDocuments");
	ProfileDetails.Roles.Add("AddEditPlannedCashReceipt");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("AddEditPaymentRequests");
	ProfileDetails.Roles.Add("AddEditCashTransferOrders");
	ProfileDetails.Roles.Add("ApproveApplicationsForBusinessTrip");
	ProfileDetails.Roles.Add("PaymentRequestsApproval");
	ProfileDetails.Roles.Add("ApproveCashTransferOrders");
	ProfileDetails.Roles.Add("ApprovalOfPaymentRequestsForPayment");
	ProfileDetails.Roles.Add("ApprovalOfCashTransferReferencesForPayment");
	ProfileDetails.Roles.Add("AddEditAccrualsForLoansAndDeposits");
	ProfileDetails.Roles.Add("AddEditIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("WriteIssuedAuthorizationLetterInItsFinalStatus");
	ProfileDetails.Roles.Add("AddEditDocumentsRecordingCashCollectionDiscrepancies");
	ProfileDetails.Roles.Add("AddEditPettyCashAudits");
	ProfileDetails.Roles.Add("AddEditDocumentsOfDepositsWithdrawalsByLineOfBusiness");
	ProfileDetails.Roles.Add("AddEditARAPAccountingScheduleAdjustment");
	
	// Registers
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadFinancialInstrumentsARAP");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Registers of advanced settlement analytics
	ProfileDetails.Roles.Add("ReadRecordsCounterpartyIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCounterpartyCounterparty");
	
	// Registers of advanced cost analysis of goods
	ProfileDetails.Roles.Add("ReadInventoryCost");

	// DataProcessors
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseIntercompanyDocumentJournalDataProcessor");
	
	// Registers of advanced cash analytics
	ProfileDetails.Roles.Add("ReadCashBalance");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalanceInCashRegister");
	ProfileDetails.Roles.Add("ReadBankAccountBalance");
	ProfileDetails.Roles.Add("ReadCashBalanceOfAdvanceHolders");
	ProfileDetails.Roles.Add("ReadRecordsCashIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCashCounterparty");
	ProfileDetails.Roles.Add("ReadCashTransfers");
	ProfileDetails.Roles.Add("ReadPaymentSchedule");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", "AllAllowedByDefault");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SectionTreasuryAcquiring");
	ProfileDetails.Roles.Add("SectionTreasuryCash");
	ProfileDetails.Roles.Add("SectionTreasuryDimensionConfiguration");
	ProfileDetails.Roles.Add("SectionTreasuryCashForecasting");
	ProfileDetails.Roles.Add("SectionTreasuryARAPAdjustment");
	ProfileDetails.Roles.Add("SectionTreasuryLoansAndDeposits");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	ProfileDetails.Roles.Add("SectionSales");
	
	//++ WE
	// BankFeeds
	ProfileDetails.Roles.Add("AddEditBankFeeds");
	ProfileDetails.Roles.Add("UseDataProcessorBankFeedsClientBank");
	//-- WE
	
	AccessManagementLocalization.AddTreasurerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có tiến hành quản lý lịch thanh toán,
	                                      |thực hiện giao dịch với ngân hàng, hạch toán với người nhận tạm ứng.';
	                                      |ru = 'Под профилем происходит управление платежным календарем,
	                                      |ведутся операций по банку, осуществляются расчеты с подотчетными лицами.';
	                                      |en = 'Use this profile to manage the cash forecast,
	                                      |effect bank transactions, and carry out advance holder statement.'; fa = 'Use this profile to manage the cash forecast,
	                                      |effect bank transactions, and carry out advance holder statement.';
	                                      |it = 'Sotto questo profilo avviene la gestione del calendario dei pagamenti, 
	                                      |vengono eseguite le operazioni bancarie ed effettuati i calcoli con i responsabili.';
	                                      |pl = 'Pod profilem odbywa się zarządzanie kalendarzem płatności,
	                                      |prowadzone są operacje po banku, dokonywane są rozliczenia z zaliczobiorcami.';
	                                      |tr = 'Profil altında nakit takvimi yönetilir,
	                                      |banka işlemleri gerçekleştirilir ve sorumlu kişilerle mutabakatlar yapılır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_ProcurementManager
	// Profile "Needs Assurance Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ProcurementManager";
	ProfileDetails.Id = "e5d97caa-7019-44d2-b36e-7b71f6133219";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Người quản lý đảm bảo nhu cầu';
										|ru = 'Менеджер по обеспечению потребностей';
										|en = 'Supply officer'; fa = 'Supply officer';
										|it = 'Responsabile dell''approvvigionamento';
										|pl = 'Kierownik ds. potrzeb';
										|tr = 'Talebi karşılama yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Master data
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadIntangibleAssets");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadConstructionObjects");
	ProfileDetails.Roles.Add("ReadExpenseRecordMethods");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("AddEditProductionSupplySchemes");
	ProfileDetails.Roles.Add("ReadResearchAndDevelopmentStagesTopics");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("AddEditLogisticParameters");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("ChangeWarehouseSupplySettings");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadWriteOffsOfDiscrepanciesBetweenReceiptAndPurchase");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadOperationCategories");
	ProfileDetails.Roles.Add("ReadInventoryInOperation");
	// Terms1
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	// Prices
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadProductRange");
	
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	
	// Settlements with customers and suppliers
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	// Orders to suppliers
	ProfileDetails.Roles.Add("AddEditPurchaseOrders");
	ProfileDetails.Roles.Add("AddEditPurchaseRequests");
	ProfileDetails.Roles.Add("AddEditProvisionRequests");
	// Sales order
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	ProfileDetails.Roles.Add("AddEditVehicles");
	ProfileDetails.Roles.Add("AddEditRequestsForReturnOfGoodsFromCustomer");
	// Internal orders
	ProfileDetails.Roles.Add("AddEditTransferOrders");
	ProfileDetails.Roles.Add("AddEditAssemblyOrders");
	ProfileDetails.Roles.Add("AddEditInventoryAssignmentAdjustmentEntries");
	ProfileDetails.Roles.Add("AddEditOtherGoodsReceipt");
	ProfileDetails.Roles.Add("AddEditInventoryConsumption");
	ProfileDetails.Roles.Add("InventoryConsumptionInExcessOfOrder");
	ProfileDetails.Roles.Add("AddEditGoodsTransfers");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingTransfer");
	ProfileDetails.Roles.Add("AddEditGoodsAssemblies");
	ProfileDetails.Roles.Add("AddEditInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("ReadInventoryAssignmentAdjustingEntries");
	
	// Coordination of Orders for DOMESTIC CONSUMPTION.
	ProfileDetails.Roles.Add("AddEditApprovalOfInventoryConsumptionOrders");

	// Warehouse and delivery
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	
	// Production
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfOrderOnTransferToProductionAccordingToPlan");
	ProfileDetails.Roles.Add("AddEditTollingOrders2_5");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadProductionLots");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("AddEditMovementsOfProductsAndMaterials");
	ProfileDetails.Roles.Add("AddEditOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadProductsAndSemiFinishedProductsInProduction");
	ProfileDetails.Roles.Add("AddEditProductionOrders2_2");
	ProfileDetails.Roles.Add("ChangeProductionStages2_2");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("UseProductionDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadSubAssets");
	ProfileDetails.Roles.Add("ReadRMOrders");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");

	// Planning
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfPurchaseOrdersAccordingToPlan");
	ProfileDetails.Roles.Add("UseGeneratePurchaseRequestsByPlanDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfOrdersOnAssemblyDisassemblyAccordingToPlan");
	ProfileDetails.Roles.Add("ReadOfPlansOfGoodsStock");
	ProfileDetails.Roles.Add("ReadPurchasePlans");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	
	// Seasonal coefficients
	ProfileDetails.Roles.Add("AddEditSeasonalFactors");
	ProfileDetails.Roles.Add("ReadSeasonalIndexes");
	
	// Adjustments to separate accounting of goods
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	
	// Reports and processing
	ProfileDetails.Roles.Add("ViewReportGoodsSupplySchemes");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("UseCommandABCXYZInventoryClassification");
	ProfileDetails.Roles.Add("SupplyOfficerSReports");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("ViewReportInventorySchedule");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UseOfDemandFulfillment");
	ProfileDetails.Roles.Add("UsePurchaseOrderGeneration");
	ProfileDetails.Roles.Add("UseDemandFulfillmentParameters");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferDocumentsForRegistration");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UsageOfManageTransferOfGoodsAssigned");
	ProfileDetails.Roles.Add("UseGenerationOfOrdersForMaterialsAsRequired");
	ProfileDetails.Roles.Add("ViewOfOrdersGenerationByPlansDistributionAndTransfer");
	ProfileDetails.Roles.Add("ViewOfStepsOfPaymentToVendor");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	
	// Registers
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadBalancesOfTransferOrders");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadRMActivities");
	ProfileDetails.Roles.Add("ReadBalanceOrdersOfMaterialsInProduction");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	

	ProfileDetails.Roles.Add("ReadBalancesOfAssemblyOrders");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRemainingReceivedReturnablePackaging");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	ProfileDetails.Roles.Add("SectionMarketingPlanning");
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	ProfileDetails.Roles.Add("SalesSectionReceiptForTolling");
	ProfileDetails.Roles.Add("QualityControlSubsystem");

	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadOBEntryInventoryInOperation");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	AccessManagementLocalization.AddNeedsManagerRoles(ProfileDetails);
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có tiến hành xác định quy tắc quản lý và
	                                      |bổ sung vật tư, xử lý các đơn hàng tiêu dùng nội bộ.';
	                                      |ru = 'Под профилем происходит определение правил управления и
	                                      |пополнения запасов, обрабатываются внутренние заказы.';
	                                      |en = 'Use this profile to determine rules of inventory management and
	                                      |replenishment, and process internal orders.'; fa = 'Use this profile to determine rules of inventory management and
	                                      |replenishment, and process internal orders.';
	                                      |it = 'Sotto questo profilo vengono definite le regole di gestione,
	                                      | il rifornimento delle scorte e la elaborazione degli ordini interni.';
	                                      |pl = 'Pod profilem odbywa się określenie zasad zarządzania i
	                                      | uzupełnienia zapasów, są przetwarzane wewnętrzne zamówienia.';
	                                      |tr = 'Profil altında, yönetim ve
	                                      |stok doldurma kuralları tanımlanır ve iç siparişler işlenir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_FinancialAnalyst
	// Profile "Financial analyst".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "FinancialAnalyst";
	ProfileDetails.Id = "485d23db-673c-446b-adab-8fd27de6e0e5";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Phân tích kết quả kinh doanh';
										|ru = 'Финансовый аналитик';
										|en = 'Financial analyst'; fa = 'Financial analyst';
										|it = 'Analista finanziario';
										|pl = 'Analityk finansowy';
										|tr = 'Finansal boyut'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Applied roles
	ProfileDetails.Roles.Add("UseLoanAndDepositItemsAnalysis");
	ProfileDetails.Roles.Add("UseLoanAndDepositRegistry");
	ProfileDetails.Roles.Add("UseSalesVarianceOfFinancialInstruments");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadPersons");
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadLoanAndDepositContracts");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadLeaseContracts");
	ProfileDetails.Roles.Add("ReadProductionLots");
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadFinancialResults");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadCashBalanceInCashRegister");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalance");
	ProfileDetails.Roles.Add("ReadBankAccountBalance");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadFinancialInstrumentsARAP");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadCashBalanceOfAdvanceHolders");
	ProfileDetails.Roles.Add("ReadRemainingReceivedReturnablePackaging");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	
	// Registers of advanced settlement analytics
	ProfileDetails.Roles.Add("ReadRecordsCounterpartyIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCounterpartyCounterparty");
	
	ProfileDetails.Roles.Add("ReadInventoryCost");
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	ProfileDetails.Roles.Add("ReadRecordsIncomeExpensesOtherAssetsLiabilities");
	
	// Registers of advanced cash analytics
	ProfileDetails.Roles.Add("ReadCashBalance");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalanceInCashRegister");
	ProfileDetails.Roles.Add("ReadBankAccountBalance");
	ProfileDetails.Roles.Add("ReadCashBalanceOfAdvanceHolders");
	ProfileDetails.Roles.Add("ReadRecordsCashIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCashCounterparty");
	ProfileDetails.Roles.Add("ReadCashTransfers");
	ProfileDetails.Roles.Add("ReadPaymentSchedule");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	// Documents, reading
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadBookingDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadExpenseReports");
	ProfileDetails.Roles.Add("ReadAdjustmentsOfARAPAccountingForAdvanceHolders");
	ProfileDetails.Roles.Add("ReadApplicationsForBusinessTrip");
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsByCustodian");
	ProfileDetails.Roles.Add("ReadStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("ReadMisgradingOfGoodsAtCustodian");
	ProfileDetails.Roles.Add("ReadDamageAtCustodian");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadIntercompanyConsumptionReportsSubcontractingServicesDelivered");
	ProfileDetails.Roles.Add("ReadLeaseContractsSigning");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadOtherCostAllocation");
	ProfileDetails.Roles.Add("ReadDeferredExpenseAllocations");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");	
	ProfileDetails.Roles.Add("ReadRetailSalesReports");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadMerchantStatements");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadPlannedCashInflow");
	ProfileDetails.Roles.Add("ReadCashTransferOrders");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets"); 
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadReceivedTaxInvoicesPrepayment");
	ProfileDetails.Roles.Add("ReadReceivedTaxInvoicesPrepayment");
	ProfileDetails.Roles.Add("ReadPeriodEndTransactions");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditDocumentsOfDepositsWithdrawalsByLineOfBusiness");
	// Reports and processing
	ProfileDetails.Roles.Add("FinancialAnalystReports");
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseIntercompanyDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SubsystemFinancialResultAndControlling");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SectionTreasuryCashForecasting");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	
	AccessManagementLocalization.AddFinancialAnalystRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ này có lập báo cáo tài chính và thực hiện phân tích tài chính.';
									|ru = 'Под профилем формируется финансовая отчетность и выполняется финансовый анализ.';
									|en = 'Use this profile to generate financial accounting and carry out financial analysis.'; fa = 'Use this profile to generate financial accounting and carry out financial analysis.';
									|it = 'Sotto questo profilo viene creata la rendicontazione finanziaria e vengono effettuate analisi finanziarie.';
									|pl = 'Pod profilem formuje się sprawozdawczość finansowa i wykonywana jest analiza finansowa.';
									|tr = 'Profil kapsamında finansal tablolar oluşturulur ve finansal analizler gerçekleştirilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_Warehouseman
	// The Storekeeper profile.
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Warehouseman";
	ProfileDetails.Id = "28f1fe22-299d-4135-ac9f-fe338ce51571";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Thủ kho';
										|ru = 'Кладовщик';
										|en = 'Warehouse keeper'; fa = 'انباردار';
										|it = 'Magazziniere';
										|pl = 'Warehouse keeper';
										|tr = 'Ambar sorumlusu'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddAndEditGoodsLockReasons");
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadMessageTemplates");
	ProfileDetails.Roles.Add("ReadControlledLot");
	
	// Goods Research
	ProfileDetails.Roles.Add("ReadGoodsQualityResearch");
	ProfileDetails.Roles.Add("ReadProductResearchCards");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	// Documents, reading
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsByCustodian");
	ProfileDetails.Roles.Add("ReadStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("ReadMisgradingOfGoodsAtCustodian");
	ProfileDetails.Roles.Add("ReadDamageAtCustodian");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsTransfer");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsReceipt");
	ProfileDetails.Roles.Add("ReadInventoryConsumption");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	ProfileDetails.Roles.Add("ReadOtherGoodsRecordingAsReceived");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");
	ProfileDetails.Roles.Add("ReadRetailSalesReports");
	ProfileDetails.Roles.Add("ReadWarehouseActs");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadDeliveryOrders");
	ProfileDetails.Roles.Add("ReadingTrips");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadCashRegisterReceipts");
	ProfileDetails.Roles.Add("ReadCustomsImportDeclarations");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");

	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");

	// Registers, reading.
	ProfileDetails.Roles.Add("ReadStorageBinLocks");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadBalancesOfAssemblyOrders");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfSurplusesAndShortages");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfImportDocuments");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadBalanceOrdersOfMaterialsInProduction");
	ProfileDetails.Roles.Add("ReadInventoryInOperation");

	// Customization.
	ProfileDetails.Roles.Add("ConfigureWarehouseTopology");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("AddEditClassifiersOfProductsWarehouseAccounting");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditStorageBinLocksSetting");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditGoodsPlacementPicking");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptNotes");
	ProfileDetails.Roles.Add("AddEditPackingLists");
	ProfileDetails.Roles.Add("AddEditGoodsTransferNotes");
	ProfileDetails.Roles.Add("AddEditInventoryRecounts");
	ProfileDetails.Roles.Add("AddEditSurplusesShortagesDamageNotes");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("AddEditRecordsOfGoodsNoteCheckResults");
	ProfileDetails.Roles.Add("AddEditInventoryAssignmentAdjustmentEntries");
	ProfileDetails.Roles.Add("AddAndEditRequestsForQualityControl");
	
	// Documents, conducting.
	ProfileDetails.Roles.Add("PutGoodsIssueNoteIntoOperation");
	
	// Reports and processing.
	ProfileDetails.Roles.Add("WarehousemanSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseCheckingOfNumberOfGoodsInDocument");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferDocumentsForRegistration");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	
	//KI
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("SectionOrganizer");
	ProfileDetails.Roles.Add("MasterDataSection");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	AccessManagementLocalization.AddStorekeeperRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có tiến hành tùy chỉnh sơ đồ kho, thực hiện
	                                      |lệnh tiếp nhận, giao hàng và đóng bộ hàng hóa. Thực hiện
	                                      |ghi nhận thông tin thực hiện lệnh, phản ánh
	                                      |hàng thừa và hàng thiếu. Hồ sơ cho phép soạn
										  |thông tin mặt hàng liên quan đến kho bãi.';
										  |ru = 'Под профилем происходит настройка топологии склада, выполнение
										  |распоряжений о приеме, выдаче и сборке товаров. Осуществляется
										  |регистрация информации о выполнении распоряжений, отражаются
										  |излишки и недостачи товара. Так же профиль позволяет редактировать
										  |складскую информацию по номенклатуре.';
										  |en = 'Use this profile to configure warehouse topology, process
										  |references for receipt, issue, and assembly of goods. Information
										  |about reference execution is registered, goods
										  |surpluses and shortages is recorded. You can also edit
										  |the warehouse information on products under this profile.'; fa = 'Use this profile to configure warehouse topology, process
	                                      |references for receipt, issue, and assembly of goods. Information
	                                      |about reference execution is registered, goods
	                                      |surpluses and shortages is recorded. You can also edit
	                                      |the warehouse information on products under this profile.';
										  |it = 'Sotto questo profilo viene impostata la topologia del magazzino,
										  | l''esecuzione degli ordini di ricezione, l''emissione e l''assemblaggio delle merci.
										  | Viene effettuata inoltre la registrazione delle informazioni sull''esecuzione degli ordini e vengono
										  | riflesse eccedenze e mancanze di merci. Inoltre, il profilo consente di modificare le informazioni si 
										  |stoccaggio per gli articoli.';
										  |pl = 'Pod profilem odbywa się konfiguracja topologii magazynu, wykonywanie
										  | zamówień dotyczących przyjmowania, wydawania i montażu towarów. Odbywa się
										  |rejestracja informacji o realizacji zamówień, odzwierciedlają się
										  |nadmiar i niedobór towaru. Również profil pozwala edytować
										  |informacje z magazynu dotyczące pozycji.';
										  |tr = 'Profil altında, ambar yapısı ayarlanır ve ürünlerin alınması, verilmesi ve toplanması için siparişler
										  |yürütülür. Siparişlerin yerine getirilmesine
										  |ilişkin bilgiler kaydedilir ve ürün
										  |fazlalıkları ve eksiklikleri yansıtılır. Profil ayrıca öğeye göre ambar
										  |bilgilerini düzenlenmesine de olanak tanır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_PurchasesManager
	// Profile "Purchasing Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "PurchasesManager";
	ProfileDetails.Id = "12bb4321-60bb-4bbd-a1fc-4c84fb3c1133";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Quản lý mua hàng';
										|ru = 'Менеджер по закупкам';
										|en = 'Chief procurement officer'; fa = 'مدیر ارشد تدارکات';
										|it = 'Manager per gli acquisti';
										|pl = 'Kierownik ds. zakupów';
										|tr = 'Satın alma yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddEditCCDNumbers");
	ProfileDetails.Roles.Add("AddEditTermsOfPurchases");
	ProfileDetails.Roles.Add("AddEditPartnerPrices");
	ProfileDetails.Roles.Add("AddEditPartnerItems");
	ProfileDetails.Roles.Add("AddEditCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("AddEditCounterpartyContracts");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	ProfileDetails.Roles.Add("AddEditCustomerComplaints");
	
	// Documents, reading.

	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadBookingDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadVendorInvoiceServicesAndAssets"); 
	ProfileDetails.Roles.Add("ReadDeferredExpenseAllocations");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadPurchasingReportsToConsignor");
	ProfileDetails.Roles.Add("ReadPeriodEndTransactions");
	ProfileDetails.Roles.Add("ReadWriteOffsOfDiscrepanciesBetweenReceiptAndPurchase");
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditReportsToConsignor");
	ProfileDetails.Roles.Add("AddEditPurchaseOrders");
	ProfileDetails.Roles.Add("AddEditPurchaseRequests");
	ProfileDetails.Roles.Add("AddEditProvisionRequests");
	ProfileDetails.Roles.Add("AddEditCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("AddEditUninvoicedReceiptToWarehouse");
	ProfileDetails.Roles.Add("AddEditReceiptsOfServicesToBusinessUnit");
	ProfileDetails.Roles.Add("AddEditWriteOffsOfDiscrepanciesBetweenReceiptAndPurchase");
	ProfileDetails.Roles.Add("AddEditVendorInvoiceGoodsReturn");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("AddEditReportsOnWriteOffOfGoodsAcceptedForStorage");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditARAPReconciliation");
	ProfileDetails.Roles.Add("AddEditDebitNotes");
	ProfileDetails.Roles.Add("AddEditReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditPackingLists");
	ProfileDetails.Roles.Add("AddEditIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingShipmentByReturn");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingReceipt");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocumentsPaymentOffset");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("AddEditCustomsImportDeclarations");
	ProfileDetails.Roles.Add("AddEditApplicationsForGoodsImport");
	ProfileDetails.Roles.Add("AddEditSourceDocuments");
	ProfileDetails.Roles.Add("AddEditARAPAccountingScheduleAdjustment");
	ProfileDetails.Roles.Add("AddEditPolls");

	// Registers are read.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");	
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRemainingReceivedReturnablePackaging");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfImportDocuments");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	ProfileDetails.Roles.Add("UseIntercompanyDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadProductsAndSemiFinishedProductsInProduction");
	// Harmonization of procurement
	ProfileDetails.Roles.Add("AddEditPurchaseApproval");
	ProfileDetails.Roles.Add("PurchaseConditionApprovalParticipantsReportsAndDataProcessors");
	
	// Planning
	ProfileDetails.Roles.Add("ReadOfPlansOfGoodsStock");
	ProfileDetails.Roles.Add("ReadPurchasePlans");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfPurchaseOrdersAccordingToPlan");
	ProfileDetails.Roles.Add("UseGeneratePurchaseRequestsByPlanDataProcessor");
	
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	
	// Reports and processing.
	ProfileDetails.Roles.Add("WarehouseSectionReports");
	ProfileDetails.Roles.Add("ChiefProcurementOfficerSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewReportInventorySchedule");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("UseOfDemandFulfillment");
	ProfileDetails.Roles.Add("UseDemandFulfillmentParameters");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseIntercompanyDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UseOfProcessingProcessingOfDocumentsAccordingToAccrualMethod");
	
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfGoodsHandoversAndRedemptions");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseDataProcessorManagementOfReceivedReturnablePackaging");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	ProfileDetails.Roles.Add("UseSourceDocumentOriginalsRecordKeepingLogProcessing");
	ProfileDetails.Roles.Add("UsingReportsToConsignorsDocumentJournalDataProcessor");

	// Additional rights.
	ProfileDetails.Roles.Add("VarianceFromPurchaseConditions");
	ProfileDetails.Roles.Add("ChangePurchaseDocumentRate");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);
		
	//KI
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	ProfileDetails.Roles.Add("SectionMarketingPlanning");
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	ProfileDetails.Roles.Add("QualityControlSubsystem");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions","Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies", "Predefined");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", "Predefined");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	// H.O. for cash orders, non-cash ds.
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PaymentToVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundFromVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CustomsPayment");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PurchaseFromSupplier");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ConsignmentProcurement");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashReceiptFromCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PurchaseByImport");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportGoodsInTransit");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportFromEAEU");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfGoodsFromStorage");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReceiptFromToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromProcessingCompany2_5");
	// Access values by types of grounds for acts of discrepancies
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor");
	// Access values by types of debt offset operations
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty");
	
	AccessManagementLocalization.AddPurchasingManagerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện ký kết các thỏa thuận với nhà cung cấp,
	                                      |quản lý đơn hàng, ghi nhận mua hàng và trả lại,
	                                      |kiểm soát hạch toán với nhà cung cấp.';
	                                      |ru = 'Под профилем происходит заключение соглашений с поставщиками,
	                                      |управление заказами, регистрируются закупки и возвраты,
	                                      |контролируются расчеты с поставщиками.';
	                                      |en = 'Use this profile to accept terms of purchase,
	                                      |manage orders, register purchases and returns,
	                                      |and control vendor AR/AP.'; fa = 'Use this profile to accept terms of purchase,
	                                      |manage orders, register purchases and returns,
	                                      |and control vendor AR/AP.';
	                                      |it = 'Sotto questo profilo vengono siglati gli accordi con i fornitori, 
	                                      | avviene la gestione degli ordini, la registrazione degli acquisti e delle restituzioni e 
	                                      |la verifica dei conti con i fornitori.';
	                                      |pl = 'Pod profilem odbywa się zawarcie umów z dostawcami,
	                                      |zarządzanie zamówieniami, rejestrowane są zakupy i zwroty,
	                                      |kontrolowane zobowiązania.';
	                                      |tr = 'Profil kapsamında tedarikçilerle anlaşmalar yapılır,
	                                      |siparişler yönetilir, satın almalar ve iadeler kaydedilir ve
	                                      |tedarikçilerle yapılan ödemeler kontrol edilir.'");
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_ParticipantInApprovalOfProcurementConditions
	// Description for filling out the profile "Approval of procurement conditions".
	// The profile is designed to provide access to approval objects and reports.
	// Profile "Participant in the approval of procurement conditions (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantInApprovalOfProcurementConditions";
	ProfileDetails.Id = "19037231-7da0-406f-a223-28687ce22545";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia thống nhất điều kiện mua hàng (bổ sung)';
										|ru = 'Участник согласования условий закупок (дополнительный)';
										|en = 'Employee approving purchasing conditions (additional)'; fa = 'Employee approving purchasing conditions (additional)';
										|it = 'Partecipante all''accordo sui termini di acquisto (aggiuntivo)';
										|pl = 'Uczestnik negocjacji warunków zakupów (dodatkowy)';
										|tr = 'Satın alma onay katılımcısı (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("AddEditPurchaseApproval");
	ProfileDetails.Roles.Add("ApprovePurchaseRequests");// Reading rights are not granted, because they are needed to change
	ProfileDetails.Roles.Add("ApproveProvisionRequests"); // Reading rights are not granted, because they are needed to change
	ProfileDetails.Roles.Add("PurchaseConditionApprovalParticipantsReportsAndDataProcessors");
	// Applied rights.
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.AccessKinds.Add("Warehouses","AllAllowedByDefault"); // For orders.
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault"); // For orders.
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault"); // For orders.
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault"); // For applications
	// Description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ này có tiến hành thống nhất đơn hàng đặt nhà cung cấp.';
									|ru = 'Под профилем происходит согласование заказов поставщикам.';
									|en = 'Use this profile to approve purchase orders.'; fa = 'Use this profile to approve purchase orders.';
									|it = 'Sotto questo profilo vengono coordinati gli accordi degli ordini ai fornitori.';
									|pl = 'Pod profilem odbywa się koordynacja zamówień do dostawców.';
									|tr = 'Profil altında, satın alma siparişleri onaylanır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_Client
	// Description for filling
	// in the "Client" profile The profile is designed to provide access to the objects of the "Customer Self-service" subsystem for the client-external user.
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Client";
	ProfileDetails.Id = "8ed11273-0914-4acb-8359-f95ff3e43bc6";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Purpose = CommonClientServer.ValueInArray(Metadata.DefinedTypes.ExternalUser.Type);
	ProfileDetails.Description  = NStr("vi = 'Khách hàng có quyền truy cập vào hệ thống con tự phục vụ';
										|ru = 'Клиент, имеющий доступ к подсистеме самообслуживания';
										|en = 'Customer who has access to Self-Service Workplace'; fa = 'Customer who has access to Self-Service Workplace';
										|it = 'Cliente con accesso al sottosistema di autogestione';
										|pl = 'Klient mający dostęp do podsystemu samoobsługowego';
										|tr = 'Self-servis alt sistemine erişimi olan müşteri'", Common.DefaultLanguageCode());
	
	// Using 1C:Enterprises.
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("SaveUserData");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("PrintShippingDocuments");
	// Using the program.
	ProfileDetails.Roles.Add("BasicAccessExternalUserSSL"); 
	
	// The main features of the profile.
	ProfileDetails.Roles.Add("BasicAccessExternalUserTM");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserBasicAccess");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserReadMasterData");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserCreateSalesProfiles");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserEditSubscriptionsAndNotifications");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserEdutCustomerContactDetails");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserEditContactPersons");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserEditCounterparties");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserCreateCustomerComplaints");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserViewSalesTermsAndConditions");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserCreateGoodsReceiptNotes");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserCreatePurchaseOrders");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserCreatePurchaseReturnOrders");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserCreateConsignmentReports");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserViewARAPBalanceReport");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserEditBankAccounts");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserReadARAPData");
	ProfileDetails.Roles.Add("ReadObjectVersions");
	// Viewing real balances
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserViewSupplyForecast");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserViewAvailableInventoryReport");
	// Access to the Calendar Schedules register to display the planned delivery date in the provision state.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	
	// Types of profile access restrictions.
	ProfileDetails.AccessKinds.Add("ExternalUsers", "Predefined");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "Predefined");
	ProfileDetails.AccessKinds.Add("Warehouses",              "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices",             "AllAllowedByDefault");
	
	AccessManagementLocalization.AddExternalClientRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ dành cho khách hàng-người mua truy cập đến hệ thống thông qua giao diện
	                                      |Web. Theo hồ sơ có tiến hành tự lập 
	                                      |đơn hàng của khách mà đã được ghi nhận bởi người sử dụng ngoài.';
	                                      |ru = 'Профиль для доступа клиентов-покупателей к системе через веб-
	                                      |интерфейс. Под профилем происходит самостоятельное оформление 
	                                      |заказов клиентами, которые зарегистрированы в качестве внешних пользователей.';
	                                      |en = 'Profile for the customer access to the application via the web
	                                      |interface. Registration of orders by customers
	                                      |registered as external users is performed under the profile.'; fa = 'Profile for the customer access to the application via the web
	                                      |interface. Registration of orders by customers
	                                      |registered as external users is performed under the profile.';
	                                      |it = 'Profilo per l''accesso dei clienti-acquirenti al sistema tramite
	                                      |interfaccia web. Sotto questo profilo vengono eseguiti autonomamente gli 
	                                      |ordini ai clienti registrati come utenti esterni.';
	                                      |pl = 'Profil dostępu klientów-nabywców do systemu przez interfejs
	                                      |internetowy. Pod profilem odbywa się samodzielne dokonywanie 
	                                      | zamówień przez klientów, którzy są zarejestrowani jako użytkownicy z zewnątrz.';
	                                      |tr = 'Müşteri-alıcılar tarafından web-
	                                      |arayüzü üzerinden sisteme erişim için bir profil. Profil altında, harici kullanıcı olarak kayıtlı müşteriler bağımsız olarak
	                                      |sipariş verebilirler.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_Respondent

	// Description for filling out the profile "Respondent"
	// The profile is designed to provide access to the respondent of an external user to fill out questionnaires intended for him.
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Respondent";
	ProfileDetails.Id = "c86c8305-df47-4bb0-a51d-af325c38670f";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Purpose = CommonClientServer.ValueInArray(Metadata.DefinedTypes.ExternalUser.Type);
	ProfileDetails.Description  = NStr("vi = 'Người trả lời tham gia điều tra ';
										|ru = 'Респондент, участвующий в опросах';
										|en = 'Respondent taking part in surveys'; fa = 'Respondent taking part in surveys';
										|it = 'Rispondente ai sondaggi';
										|pl = 'Respondent biorący udział w ankietach';
										|tr = 'Anketlere katılan yanıtlayan'", Common.DefaultLanguageCode());
	
	// Using 1C:Enterprises.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	// Using the program.
	ProfileDetails.Roles.Add("BasicAccessExternalUserSSL");
	// The main features of the profile.
	ProfileDetails.Roles.Add("BasicAccessExternalUserTM");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	ProfileDetails.Roles.Add("AddEditQuestionnaireQuestionsAnswers");
	ProfileDetails.Roles.Add("SelfServiceWorkplaceExternalUserNavigateToQuestionnaireList");
	// Types of profile access restrictions.
	ProfileDetails.AccessKinds.Add("ExternalUsers", "Predefined");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ dành cho những người trả lời khảo sát truy cập đến hệ thống thông qua giao diện
	                                      |Web. Theo hồ sơ này, người trả lời khảo sát được phép truy cập đến danh sách các cuộc khảo sát 
	                                      |dành cho người đó và tính năng điền bảng câu hỏi.';
	                                      |ru = 'Профиль для доступа респондентов опросов к системе через веб-
	                                      |интерфейс. Под данным профилем респонденту доступен список, предназначенных 
	                                      |ему опросов и возможность заполнить анкеты.';
	                                      |en = 'Profile for the survey respondent access to the application via the web
	                                      |interface. Under the profile the respondent can see the list of available
	                                      |surveys and fill in questionnaires.'; fa = 'Profile for the survey respondent access to the application via the web
	                                      |interface. Under the profile the respondent can see the list of available
	                                      |surveys and fill in questionnaires.';
	                                      |it = 'Profilo per l''accesso dei rispondenti ai sondaggi sul sistema tramite interfaccia 
	                                      |web. Sotto questo profilo per il rispondente è accessibile un elenco
	                                      | di sondaggi a lui assegnati per la compilazione.';
	                                      |pl = 'Profil dostępu respondentów do ankiet do systemu przez interfejs
	                                      |internetowy. Pod tym profilem respondentowi jest dostępna lista przeznaczonych 
	                                      |mu ankiet i możliwość wypełnić ankiety.';
	                                      |tr = 'Anket yanıtlayanların web-
	                                      |arayüzü üzerinden sisteme erişebilmeleri için profil. Bu profil altında, yanıtlayan bir 
	                                      |anket listesine erişebilir ve soru formları doldurabilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_SalesTermsAndConditionsApproval
	// The profile is designed to provide access to approval objects and reports.
	// Profile "Participant in the agreement of terms of sale (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantInAgreementOfTermsOfSale";
	ProfileDetails.Id = "6c5ff2cf-6901-4412-a930-fa04bad5cf0b";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia thống nhất điều kiện bán hàng (bổ sung)';
										|ru = 'Участник согласования условий продаж (дополнительный)';
										|en = 'Employee approving sales terms and conditions (additional)'; fa = 'Employee approving sales terms and conditions (additional)';
										|it = 'Partecipante all''accordo sui termini di vendita (aggiuntivo)';
										|pl = 'Uczestnik negocjacji warunków sprzedaży (dodatkowy)';
										|tr = 'Satış onay şartlarının katılımcısı (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("AddEditSaleApproval");
	ProfileDetails.Roles.Add("SaleConditionApprovalParticipantsReportsAndDataProcessors");
	// Applied rights.
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.AccessKinds.Add("Warehouses","AllAllowedByDefault"); // For orders.
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault"); // For orders.
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault"); // For orders.
	// Description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có tiến hành ký kết thỏa thuận với khách hàng,
	                                      |lập báo giá, ghi nhận và xử lý
	                                      |đơn hàng của khách và đề nghị trả hàng.';
	                                      |ru = 'Под профилем происходит заключение соглашений с клиентами,
	                                      |формирование коммерческих предложений, регистрация и отработка
	                                      |заказов клиентов и заявок на возврат.';
	                                      |en = 'Use this profile to conclude agreements with customers,
	                                      |generate sales quotations, register and process
	                                      |sales orders and return requests.'; fa = 'Use this profile to conclude agreements with customers,
	                                      |generate sales quotations, register and process
	                                      |sales orders and return requests.';
	                                      |it = 'Sotto il profilo vengono siglati gli accordi con i clienti, 
	                                      | vengono eseguite le proposte commerciali, la registrazione e l''elaborazione
	                                      |degli ordini dei clienti e le domande di restituzione.';
	                                      |pl = 'Pod profilem odbywa się zawieranie umów z klientami,
	                                      | tworzenie ofert handlowych, rejestracja i odpracowywanie
	                                      |zamówień klientów i wniosków o zwrot.';
	                                      |tr = 'Profil altında müşterilerle anlaşmalar yapılır,
	                                      |satış teklifleri oluşturulur,
	                                      |müşteri siparişleri ve iade siparişleri kaydedilir ve işlenir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_MemberApprovalOfItemsPrices
	
	// Profile "Participant in the price coordination of the nomenclature (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "MemberApprovalOfItemsPrices";
	ProfileDetails.Id = "9838ae68-ebd3-4e82-b62c-d39c379a928b";
	ProfileDetails.Parent      = "Sales";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia thống nhất bảng giá (bổ sung)';
										|ru = 'Участник согласования цен номенклатуры (дополнительный)';
										|en = 'Employee approving item prices (additional)'; fa = 'Employee approving item prices (additional)';
										|it = 'Partecipante all''accordo sul prezzo dell''articolo (aggiuntivo)';
										|pl = 'Uczestnik negocjacji cen nomenklatury (dodatkowy)';
										|tr = 'Ürün fiyatı onayının katılımcısı (ek)'", Common.DefaultLanguageCode());
	
	// Reading.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("AddEditApprovalOfItemPrices");
	ProfileDetails.Roles.Add("ReadProductRange");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("TypesOfPrices","AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện thống nhất đơn giá mặt hàng
	                                      |vào thời điểm thiết lập đơn giá.';
	                                      |ru = 'Под профилем происходит согласование цен номенклатуры
	                                      |в момент их установки.';
	                                      |en = 'Use this profile to approve item prices
	                                      |while they are being set.'; fa = 'Use this profile to approve item prices
	                                      |while they are being set.';
	                                      |it = 'Sotto questo profilo viene siglato l''accordo dei prezzi dell''articolo 
	                                      |al momento della loro decisione.';
	                                      |pl = 'Pod profilem odbywa się negocjowanie cen nomenklatury
	                                      |w momencie ich ustawienia.';
	                                      |tr = 'Profilde,
	                                      |ürün fiyatını ayarlama sırasında onaylaması yapılır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_AssigneeForMaintainingOfPartnersCatalog
	// Profile "Responsible for managing partners (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssigneeForMaintainingOfPartnersCatalog";
	ProfileDetails.Id = "932c3320-f64e-4f35-a8a0-47e9727c0b2c";
	ProfileDetails.Parent      = "MasterDataAndSettings";
	ProfileDetails.Description  = NStr("vi = 'Người chịu trách nhiệm quản lý bạn hàng (bổ sung)';
										|ru = 'Ответственный за ведение партнеров (дополнительный)';
										|en = 'Employee responsible for partners (additional)'; fa = 'Employee responsible for partners (additional)';
										|it = 'Responsabile per i rapporti con i partner (aggiuntivo)';
										|pl = 'Osoba odpowiedzialna za prowadzenie partnerów (dodatkowa)';
										|tr = 'İş ortağı yönetiminden sorumlu (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("MasterDataSection");
	// Applied rights.
	ProfileDetails.Roles.Add("AddEditPartnerClassifiersAndSettings");
	ProfileDetails.Roles.Add("AddEditInformationAboutPartners");
	ProfileDetails.Roles.Add("AddAndEditDeliveryPoints");
	ProfileDetails.Roles.Add("AddEditCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadInformationAboutMailoutsAndNotificationsToCustomers");
	ProfileDetails.Roles.Add("ReportsOfAssigneeForMaintainingOfPartnersCatalog");
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault");
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được ấn định cho người sử dụng để nhập
	                                      |danh sách bạn hàng, đối tác, cá nhân.';
	                                      |ru = 'Дополнительный профиль, назначается пользователям, ведущим
	                                      |список партнеров, контрагентов, контактных лиц.';
	                                      |en = 'Additional profile is assigned to users keeping
	                                      |a list of partners, counterparties and contact persons.'; fa = 'Additional profile is assigned to users keeping
	                                      |a list of partners, counterparties and contact persons.';
	                                      |it = 'Profilo aggiuntivo per gli utenti che gestiscono 
	                                      |l''elenco dei partner, controparti e contatti.';
	                                      |pl = 'Dodatkowy profil, przypisywany użytkownikom, prowadzącym
	                                      |listę partnerów; kontrahentów, osób do kontaktu.';
	                                      |tr = 'İş ortaklarının, cari hesapların, irtibat kişilerinin listesini
	                                      |tutan ek profil kullanıcılar tarafından atanıyor.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_AssigneeForMaintainingOfPersonsCatalog
	// Profile "Responsible for managing individuals (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssigneeForMaintainingOfPersonsCatalog";
	ProfileDetails.Id = "6100e47d-25bf-4fe2-a7e5-9e357fd3bee9";
	ProfileDetails.Parent      = "MasterDataAndSettings";
	ProfileDetails.Description  = NStr("vi = 'Người chịu trách nhiệm quản lý cá nhân (bổ sung)';
										|ru = 'Ответственный за ведение физлиц (дополнительный)';
										|en = 'Employee responsible for persons (additional)'; fa = 'Employee responsible for persons (additional)';
										|it = 'Responsabile per i rapporti con le persone fisiche (aggiuntivo)';
										|pl = 'Osoba odpowiedzialna za prowadzenie osób fizycznych (dodatkowa)';
										|tr = 'Gerçek kişilerin kaydından sorumlu (ek)'", Common.DefaultLanguageCode());
	
	// Applied rights.
	ProfileDetails.Roles.Add("AddEditPersons");
	ProfileDetails.Roles.Add("AddEditCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("AddEditPersonsClassifiersAndSettings");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được chỉ định bởi người sử dụng, quản lý danh sách cá nhân.';
									|ru = 'Дополнительный профиль, назначается пользователям, ведущим список физлиц.';
									|en = 'Additional profile is assigned to users keeping a list of persons.'; fa = 'Additional profile is assigned to users keeping a list of persons.';
									|it = 'Profilo aggiuntivo per gli utenti che gestiscono l''elenco delle persone fisiche.';
									|pl = 'Dodatkowy profil, przypisywany użytkownikom, prowadzącym listę osób fizycznych.';
									|tr = 'Gerçek kişilerin listesini tutan ek profil kullanıcılar tarafından atanıyor.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_AssigneeForMaintainingOfItemsCatalog
	
	// Profile "Responsible for maintaining the nomenclature (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssigneeForMaintainingOfItemsCatalog";
	ProfileDetails.Id = "101d8475-84ef-4d02-b6d1-b026baba0ccc";
	ProfileDetails.Parent      = "MasterDataAndSettings";
	ProfileDetails.Description  = NStr("vi = 'Người chịu trách nhiệm quản lý mặt hàng (bổ sung)';
										|ru = 'Ответственный за ведение номенклатуры (дополнительный)';
										|en = 'Employee responsible for products (additional)'; fa = 'Employee responsible for products (additional)';
										|it = 'Responsabile per la gestione degli articoli (aggiuntivo)';
										|pl = 'Osoba odpowiedzialna za prowadzenie nomenklatury (dodatkowa)';
										|tr = 'Öğe kaydından sorumlu (ek)'", Common.DefaultLanguageCode());
	
	// Applied rights.
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("AddEditItems");
	ProfileDetails.Roles.Add("AddEditQualityCertificates");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	ProfileDetails.Roles.Add("AddEditItemsClassifiersAndSettings");
	ProfileDetails.Roles.Add("AddEditClassifiersOfProductsWarehouseAccounting");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("AddEditAnalyticalInventoryGroups");
	ProfileDetails.Roles.Add("AddEditAdditionalAttributesAndInfo");
	ProfileDetails.Roles.Add("AddEditLabelsTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("AddEditExcisableGoodsCategories");
	
	// Reports and processing
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được ấn định cho người sử dụng để nhập
	                                      |danh mục ""Mặt hàng"".';
	                                      |ru = 'Дополнительный профиль, назначается пользователям, ведущим
	                                      |справочник ""Номенклатура"".';
	                                      |en = 'Additional profile is assigned to users keeping
	                                      |the ""Items"" catalog.'; fa = 'Additional profile is assigned to users keeping
	                                      |the ""Items"" catalog.';
	                                      |it = 'Profilo aggiuntivo per gli utenti che gestiscono
	                                      | la query ""Articoli""';
	                                      |pl = 'Dodatkowy profil, przypisywany użytkownikom, prowadzącym
	                                      | poradnik ""nomenklatura"".';
	                                      |tr = '""Ürünler""
	                                      |kataloğunu tutan ek profil kullanıcılar tarafından atanıyor.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_AssigneeForInteractions
	// Profile "Responsible for conducting interactions (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssigneeForInteractions";
	ProfileDetails.Id = "6797cdb5-c0f0-4814-8b18-3a6ef417dd52";
	ProfileDetails.Parent      = "Other";
	ProfileDetails.Description  = NStr("vi = 'Người chịu trách nhiệm quản lý giao tiếp (bổ sung)';
										|ru = 'Ответственный за ведение взаимодействий (дополнительный)';
										|en = 'Employee responsible for interactions (additional)'; fa = 'Employee responsible for interactions (additional)';
										|it = 'Responsabile per i rapporti';
										|pl = 'Osoba odpowiedzialna za prowadzenie interakcji (dodatkowa)';
										|tr = 'Etkileşimleri sürdürmekten sorumlu (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("SectionOrganizer");
	
	// Applied rights.
	ProfileDetails.Roles.Add("AddEditInteractions");
	ProfileDetails.Roles.Add("AddEditEmailAccounts");
	ProfileDetails.Roles.Add("AddEditReportBulkEmails");
	ProfileDetails.Roles.Add("AddEditMessageTemplates");
	ProfileDetails.Roles.Add("AddEditPersonalMessageTemplates");
	ProfileDetails.Roles.Add("ViewInteractionsOnCustomerMailout");
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("EmailAccounts","AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện kết nhập E-mail đến và lập
	                                      |E-mail đi, ghi nhận cuộc gọi đến và
	                                      |cuộc gọi đi, lập kế hoạch và xử lý giao tiếp,
	                                      |lập kế hoạch và ghi nhận cuộc họp.';
	                                      |ru = 'Под профилем осуществляется загрузка входящих и формирование
	                                      |исходящих писем электронной почты, регистрация входящих и
	                                      |исходящих звонков, планирование и обработка взаимодействий, 
	                                      |планирование и регистрация встреч.';
	                                      |en = 'Use this profile to download incoming emails, generate
	                                      |outgoing emails, register incoming and
	                                      |outgoing calls, plan and process interactions,
	                                      |plan and register meetings.'; fa = 'Use this profile to download incoming emails, generate
	                                      |outgoing emails, register incoming and
	                                      |outgoing calls, plan and process interactions,
	                                      |plan and register meetings.';
	                                      |it = 'Sotto questo profilo viene effettuato il download delle mail in arrivo e la creazione
	                                      | di quelle in uscita, la registrazione delle chiamate
	                                      | in entrata e in uscita, la pianificazione ed elaborazione dei rapporti, 
	                                      | la pianificazione e la registrazione degli incontri.';
	                                      |pl = 'Pod profilem pobierane są przychodzące i formowane
	                                      |wychodzące wiadomości e-mail, rejestracja połączeń przychodzących i
	                                      |wychodzących, planowanie i przetwarzanie interakcji, 
	                                      |planowanie i rejestracja spotkań.';
	                                      |tr = 'Profil altında gelen e-postalar yüklenebilinir ve oluşturabilinir,
	                                      |gelen ve
	                                      |giden aramaları kaydedilebilinir, etkileşimler 
	                                      | planlanabilinir ve işlenebilinir, randevular planlanabilinir ve kaydedilebilinir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_ParticipantInIntercompanyARAP
	// Profile "Participant of settlements between organizations (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantInIntercompanyARAP";
	ProfileDetails.Id = "4e46851a-0ff9-47dd-bfad-0ee5abf864f2";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia hạch toán giữa các doanh nghiệp (bổ sung)';
										|ru = 'Участник расчетов между организациями (дополнительный)';
										|en = 'Participant of company settlements (additional)'; fa = 'Participant of company settlements (additional)';
										|it = 'Partecipante ai calcoli tra aziende (aggiuntivo)';
										|pl = 'Uczestnik rozliczeń między firmami (dodatkowy)';
										|tr = 'İş yerleri arasındaki hesaplamaların katılımcısı (ek)'", Common.DefaultLanguageCode());
	
	// Applied rights.
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Cho phép tùy chỉnh truy cập riêng đến doanh nghiệp
	                                      |và tài khoản ngân hàng của doanh nghiệp theo dạng truy cập ""Doanh nghiệp"".';
	                                      |ru = 'Позволяет отдельно настраивать доступ к организациям
	                                      |и банковским счетам организаций по виду доступа ""Организации"".';
	                                      |en = 'Allows you to separately set up access to companies
	                                      |and company bank accounts by the Companies access type.'; fa = 'Allows you to separately set up access to companies
	                                      |and company bank accounts by the Companies access type.';
	                                      |it = 'Permette di impostare individualmente l''accesso alle aziende 
	                                      | e ai conti bancari delle aziende per tipo di accesso ""Aziende"".';
	                                      |pl = 'Pozwala dostosować osobno dostęp do firm
	                                      |oraz rachunków bankowych firm zgodnie profilu ""Firmy"".';
	                                      |tr = '""İş yerleri"" erişim türüne göre iş yerlerine
	                                      |ve iş yerlerinin banka hesaplarına erişimi ayrı ayrı ayarlanmasına olanak tanır.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion
#Region Profile_Description_MonitoringAndAnalysisOfIndicatorsParticipant
	// Profile "Member of the management by goals (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "MemberOfManagementByGoals";
	ProfileDetails.Id = "81868489-66a6-40bd-bf4d-243b38003e13";
	ProfileDetails.Parent      = "Other";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia quản lý theo mục đích (bổ sung)';
										|ru = 'Участник управления по целям (дополнительный)';
										|en = 'Participant of management by targets (additional)'; fa = 'Participant of management by targets (additional)';
										|it = 'Partecipante alla gestione per obiettivi (aggiuntivo)';
										|pl = 'Uczestnik zarządzania po celach (dodatkowy)';
										|tr = 'Hedeflere göre yönetim katılımcısı (ek)'");
	
	// Reading.
	ProfileDetails.Roles.Add("TargetValuesSection");
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có tiến hành kiểm soát các chỉ tiêu chính
	                                      |có xác định chênh lệch so với các giá trị đích hoặc khoảng giá trị,
	                                      |cũng như phân tích nguyên nhân xuất hiện chênh lệch.';
	                                      |ru = 'Под профилем происходит контроль целевых показателей
	                                      |с точки зрения выявления отклонений от целевых значений или диапазонов,
	                                      |а также анализ причин выявленных отклонений.';
	                                      |en = 'Use this profile to control target values
	                                      |to find out variances from target values or ranges,
	                                      |and analyze reasons for detected variances.'; fa = 'Use this profile to control target values
	                                      |to find out variances from target values or ranges,
	                                      |and analyze reasons for detected variances.';
	                                      |it = 'Sotto questo profilo viene effettuata la verifica degli indicatori mirati 
	                                      |in termini di identificazione delle deviazioni dai valori o intervalli mirati,
	                                      | nonché l''analisi delle cause delle deviazioni identificate.';
	                                      |pl = 'Pod profilem odbywa się kontrola docelowych wskaźników
	                                      |z punktu widzenia identyfikacji odchyleń od wartości docelowych lub zakresów,
	                                      |a także analizę przyczyn stwierdzonych nieprawidłowości.';
	                                      |tr = 'Profil kapsamında hedef değerler,
	                                      |hedef değerlerden veya aralıklardan sapmaların belirlenmesi ve belirlenen sapmaların nedenlerinin
	                                      |analiz edilmesi açısından kontrol edilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion
#Region Profile_Description_WarehouseWorker
	// Profile "Warehouse worker".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "WarehouseWorker";
	ProfileDetails.Id = "d709cde6-925c-4497-997f-f3dd0870ffee";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Nhân viên kho';
										|ru = 'Работник склада';
										|en = 'Warehouse worker'; fa = 'Warehouse worker';
										|it = 'Lavoratore di magazzino';
										|pl = 'Pracownik magazynu';
										|tr = 'Ambar çalışanı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadReasonsForLockingGoods");
	ProfileDetails.Roles.Add("ReadStorageBinLocks");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadOperationCategories");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadMasterData"); 
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsIssues");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadInventoryInOperation");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfSurplusesAndShortages");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadPersons");
	

	// Addendum.
	ProfileDetails.Roles.Add("AddEditGoodsPlacementPicking");
	ProfileDetails.Roles.Add("AddAndEditRequestsForQualityControl");
	ProfileDetails.Roles.Add("AddEditInventoryRecounts");
	ProfileDetails.Roles.Add("AddEditStorageBinLocksSetting");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptNotes");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("CheckOnlyYourNotes");
	ProfileDetails.Roles.Add("CheckOnlyOtherNotes");
	ProfileDetails.Roles.Add("AddEditPackingLists");
	ProfileDetails.Roles.Add("AddEditRecordsOfGoodsNoteCheckResults");
	ProfileDetails.Roles.Add("AddEditPeripherals");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	
	// Documents, reading.
	
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadRecyclableWasteAllocation");
	ProfileDetails.Roles.Add("ReadManufacturingCostAllocation");
	ProfileDetails.Roles.Add("ReadBackflushProduction");
	ProfileDetails.Roles.Add("ReadMovementsInOperation");
	
	
	
	ProfileDetails.Roles.Add("ReadRMOrders"); 
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	
	
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsTransfer");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsReceiptOfCustomerReturn");
	ProfileDetails.Roles.Add("ReadInventoryConsumption");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadInventoryAssignmentAdjustingEntries");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsIssues");
	ProfileDetails.Roles.Add("ReadNotesForRecordingSurplusesShortagesDamage");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadOtherGoodsRecordingAsReceived");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	ProfileDetails.Roles.Add("ReadWarehouseActs");
	ProfileDetails.Roles.Add("ReadPackingLists");
	
	// Reading registers
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	
	// Documents, conducting.
	ProfileDetails.Roles.Add("PutGoodsIssueNoteIntoOperation");
	
	// Using.
	ProfileDetails.Roles.Add("UseWorkplaceOfWarehouseWorker");
	ProfileDetails.Roles.Add("UseCheckingOfNumberOfGoodsInDocument");
	ProfileDetails.Roles.Add("UseWarehouseKeeperWorkplace");
	
	// Reports.
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	
	ProfileDetails.Roles.Add("StartMobileClient");
	
	ProfileDetails.AccessKinds.Add("Users","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có tiến hành công việc của chỗ làm việc di động 
	                                      |của nhân viên kho';
	                                      |ru = 'Под профилем осуществляется работа мобильного рабочего 
	                                      |места работника склада';
	                                      |en = 'Use this profile for mobile workplace
	                                      |of a warehouse worker.'; fa = 'Use this profile for mobile workplace
	                                      |of a warehouse worker.';
	                                      |it = 'Sotto questo profilo viene effettuato il lavoro del dipendente di 
	                                      |magazzino';
	                                      |pl = 'Pod profilem odbywa się praca mobilnego pracownika 
	                                      |miejsca pracownika magazynu';
	                                      |tr = 'Profil kapsamında, ambar çalışanının mobil 
	                                      |işyeri çalışması gerçekleştirilir'");
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region DescriptionOf_profile_QualityManager
	// Profile "Quality Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "QualityManager";
	ProfileDetails.Id = "cd600ab3-e9f6-4934-ba87-d76e7a47878d";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("ru = 'Менеджер по качеству';
										|vi = 'Quality manager';
										|en = 'Quality manager'; fa = 'Quality manager';
										|it = 'Quality manager';
										|pl = 'Quality manager';
										|tr = 'Kalite Yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData"); 
	ProfileDetails.Roles.Add("ReadInformationAboutItems"); 
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadReasonsForLockingGoods");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	// for the report, the Review report analyzes the passage of quality control of goods
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	// to open document forms
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddAndEditRequestsForQualityControl");
	ProfileDetails.Roles.Add("AddAndEditQualityControlCertificates");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsIssues");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadOtherGoodsRecordingAsReceived");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	
	// Goods Research
	ProfileDetails.Roles.Add("ReadGoodsQualityResearch");
	ProfileDetails.Roles.Add("AddAndEditGoodsResearchSheets");
	
	// Using.
	ProfileDetails.Roles.Add("UseGoodsUnderQualityControlDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Reports.
	ProfileDetails.Roles.Add("ViewProductQualityControlAnalysisReport");
	
	//KI
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("ru = 'Под профилем осуществляется работа менеджера по качеству, осуществляющего контроль качества поступивших товаров и материалов';
									|vi = 'Use this profile for a quality manager who monitors the quality of incoming goods and materials';
									|en = 'Use this profile for a quality manager who monitors the quality of incoming goods and materials'; fa = 'Use this profile for a quality manager who monitors the quality of incoming goods and materials';
									|it = 'Use this profile for a quality manager who monitors the quality of incoming goods and materials';
									|pl = 'Use this profile for a quality manager who monitors the quality of incoming goods and materials';
									|tr = 'Profil altında, gelen ürün ve malzemelerin kalite kontrolünü yapan kalite yöneticisinin işlemleri gerçekleştirilir'");
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region _profileDescription_Controller
	// The "Controller" profile.
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Inspector";
	ProfileDetails.Id = "714f8b64-dba6-4c5f-9a48-c1c18db2247f";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("ru = 'Контролер';
										|vi = 'Inspector';
										|en = 'Inspector'; fa = 'بازرس';
										|it = 'Inspector';
										|pl = 'Inspector';
										|tr = 'Kontrolör'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadReasonsForLockingGoods");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadRequestsForQualityControl");
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");

	// Documents, appendix.
	ProfileDetails.Roles.Add("AddAndEditGoodsQualityResearch");
	ProfileDetails.Roles.Add("ReadProductResearchCards");
	//KI
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("ru = 'Под профилем происходит проведение исследования товаров
	                                      |выдача заключения о количестве и качестве товаров партии по результатам исследования.';
	                                      |vi = 'Under the profile, goods research is carried out,
	                                      |and a conclusion on the quantity and quality of lot goods based on the research results is issued.';
	                                      |en = 'Under the profile, goods research is carried out,
	                                      |and a conclusion on the quantity and quality of lot goods based on the research results is issued.'; fa = 'Under the profile, goods research is carried out,
	                                      |and a conclusion on the quantity and quality of lot goods based on the research results is issued.';
	                                      |it = 'Under the profile, goods research is carried out,
	                                      |and a conclusion on the quantity and quality of lot goods based on the research results is issued.';
	                                      |pl = 'Under the profile, goods research is carried out,
	                                      |and a conclusion on the quantity and quality of lot goods based on the research results is issued.';
	                                      |tr = 'Bu profil altında, ürün incelemesi yapılır 
	                                      | inceleme sonuçlarına göre ürün lotlarının miktar ve kalitesi hakkında rapor verilir.'");
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_AssemblyAndCourierDeliveryManager
	// Profile "Assembly and Courier Delivery Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssemblyAndCourierDeliveryManager";
	ProfileDetails.Id = "730363cf-396d-11eb-8105-4cedfb412fb8";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Điều phối tập hợp và giao hàng cho đơn vị vận chuyển';
										|ru = 'Диспетчер сборки и курьерской доставки';
										|en = 'Assembly and courier delivery dispatch'; fa = 'Assembly and courier delivery dispatch';
										|it = 'Coordinatore di composizione e consegna tramite corriere';
										|pl = 'Dyspozytor kompletacji i dostawy kurierskiej';
										|tr = 'Montaj ve kurye teslimat sevkiyat görevlisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadMessageTemplates");
		ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");	
	ProfileDetails.Roles.Add("ReadRetailSalesReports");
	ProfileDetails.Roles.Add("ReadJobsToSalesRepresentatives");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets"); 
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadCashRegisterReceipts");
	ProfileDetails.Roles.Add("ReadCashReceiptsOfAdjustment");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Using.
	ProfileDetails.Roles.Add("UseOfAssemblyAndCourierDeliveryDispatchWorkspace");
	
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditCounterpartyContracts");
	ProfileDetails.Roles.Add("AddEditLoyaltyCards");
	ProfileDetails.Roles.Add("AddEditCashRegisterShift");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	// Documents, adding changes.
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	ProfileDetails.Roles.Add("AddEditCustomerInvoice");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("CreateCustomerInvoicesWithoutReferenceToOrder");
	ProfileDetails.Roles.Add("AddEditCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("AddEditReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("AddEditRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("AddEditCustomerTermsOfSales");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditCustomerInvoices");
	ProfileDetails.Roles.Add("CreatingReportsOfCompletedWorkWithoutOrder");
	ProfileDetails.Roles.Add("AddEditCreditNotes");
	ProfileDetails.Roles.Add("SalesInExcessOfOrder");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocumentsPaymentOffset");
	
	// Approval of the sale.
	ProfileDetails.Roles.Add("AddEditSaleApproval");
	ProfileDetails.Roles.Add("SaleConditionApprovalParticipantsReportsAndDataProcessors");
	
	// Reports and processing
	ProfileDetails.Roles.Add("WarehouseSectionReports");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("SalesRepresentativeReports");
	ProfileDetails.Roles.Add("ViewPOSShiftStateReport");
	ProfileDetails.Roles.Add("ViewSalesProfitabilityAssessmentReport");
	ProfileDetails.Roles.Add("ViewConsignmentSalesStockReport");
	ProfileDetails.Roles.Add("ViewReportFulfillmentOfRegularConditionsOfTermsOfSales");
	ProfileDetails.Roles.Add("ViewTransferredReturnablePackagingReports");
	ProfileDetails.Roles.Add("UseSalesWizard");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalInvoicesForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UseOfSalesDocumentJournalReturnsForRegistrationDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorManagementOfTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("UseSourceDocumentOriginalsRecordKeepingLogProcessing");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Additional rights.
	ProfileDetails.Roles.Add("VarianceFromSalesTermsAndConditions");
	ProfileDetails.Roles.Add("AddEditObjectPrintSettings");
	ProfileDetails.Roles.Add("SaveObjectPrintSettingsByDefault");
	ProfileDetails.Roles.Add("ChangeSaleDocumentRate");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);
	// Types of access
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies", "Predefined");
	ProfileDetails.AccessKinds.Add("TermsOfSaleUpdate", "Predefined");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", "Predefined");
	// H.O. for cash orders and contracts with counterparties
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.CashReceiptFromCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SaleToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToCommissionAgent");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PaymentToVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RefundFromVendor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfGoodsByCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DeliveryForPrincipal");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromCustodian");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.WriteOffOfShippedGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsShipmentToCustomer");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfTitleToGoods");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsReceiptFromCustomer");
	
	// Access values by types of grounds for acts of discrepancies
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.EmptyRef");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer");
	
	// Access values by type of agreements with clients
	ProfileDetails.AccessValues.Add("TermsOfSaleUpdate", "Enum.KindOfTermsOfSalesToRestrictEditAccess.SpecialTerms");
	// Access values by types of debt offset operations
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty");
	ProfileDetails.AccessValues.Add("KindsOfARAPSettlements", "Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty");
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("SubsystemCRMAndMarketing");
	AccessManagementLocalization.AddSalesManagerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện công việc điều phối tập hợp và giao hàng cho đơn vị vận chuyển
	                                      |tại chỗ làm việc của chuyên gia';
	                                      |ru = 'Под профилем осуществляется работа диспетчера сборки и курьерской доставки
	                                      |в специализированном рабочем месте';
	                                      |en = 'This profile is used to perform kitting and courier delivery dispatch functions
	                                      |in a specialized workplace'; fa = 'This profile is used to perform kitting and courier delivery dispatch functions
	                                      |in a specialized workplace';
	                                      |it = 'Con questo account si eseguono le funzioni del coordinatore di composizione e consegna tramite corriere
	                                      |nella postazione di lavoro specializzata';
	                                      |pl = 'W profilu jest wykonywana praca dyspozytora kompletacji i dostawy kurierskiej
	                                      |w specjalizowanym miejscu pracy';
	                                      |tr = 'Profilin altında, uzmanlaşmış çalışma alanında montaj ve kurye teslimat
	                                      |çalışması sevkiyat görevlisi yer almaktadır'");
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_UserOfMobileWorkplaceAssemblyAndCourierDelivery
	// Profile "User of the mobile workplace of assembly and courier delivery".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "UserOfMobileWorkplaceAssemblyAndCourierDelivery";
	ProfileDetails.Id = "730363ce-396d-11eb-8105-4cedfb412fb8";
	ProfileDetails.Parent      = "ProcurementAndInventory";
	ProfileDetails.Description  = NStr("vi = 'Người sử dụng có chỗ làm việc di động tập hợp và giao hàng cho đơn vị vận chuyển';
										|ru = 'Пользователь мобильного рабочего места сборки и курьерской доставки';
										|en = 'Mobile assembly and courier delivery computer user'; fa = 'Mobile assembly and courier delivery computer user';
										|it = 'Utente della postazione di lavoro mobile di assemblaggio e consegna tramite corriere';
										|pl = 'Użytkownik mobilnego miejsca pracy kompletacji i dostawy kurierskiej';
										|tr = 'Mobil montaj ve kurye teslimat çalışma alanı kullanıcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyPrograms");
	
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadPersons");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalance");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	
	// Using.
	ProfileDetails.Roles.Add("UseOfAssemblyAndCourierDeliveryWorkspace");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Documents, adding changes.
	ProfileDetails.Roles.Add("AddEditSalesOrders");
	ProfileDetails.Roles.Add("AddEditCustomerInvoice");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentsToCustomers");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện công việc từ ứng dụng di động 
										|của nhà phân phối đơn hàng, người thu thập đơn hàng và đơn vị vận chuyển';
										|ru = 'Под профилем осуществляется работа из мобильного клиента 
										|диспетчера заказов, сборщика заказов и курьера';
										|en = 'This profile is used to work with mobile client
										| of order dispatcher, order picker and courier'; fa = 'This profile is used to work with mobile client
										| of order dispatcher, order picker and courier';
										|it = 'Con questo account si eseguono le funzioni dal client mobile 
										|di chi coordina ordini, compone ordini e del corriere';
										|pl = 'W profilu jest wykonywana praca z klienta mobilnego 
										|dyspozytora zamówień, zbieracza zamówień i kuriera';
										|tr = 'Profil altında mobil istemciden sipariş 
										|sevkiyat görevlisi, sipariş montajcı ve kurye olarak çalıştırılır'");
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_BusinessTripApplicationsInitiator

	// Profile "Initiator of business trip applications".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "BusinessTripApplicationsInitiator";
	ProfileDetails.Id = "222924b1-1d8a-4431-85d8-41c037100823";
	ProfileDetails.Parent      = "Other";
	ProfileDetails.Description  = NStr("vi = 'Người lập giấy đề nghị đi công tác';
										|ru = 'Инициатор заявок на командировку';
										|en = 'Business trip applications initiator'; fa = 'Business trip applications initiator';
										|it = 'Iniziatore delle richieste di viaggio di lavoro';
										|pl = 'Inicjator zgłoszeń na podróż służbową';
										|tr = 'İş gezisi taleplerinin başlatıcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	//KI
	ProfileDetails.Roles.Add("SubsystemTreasury");
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadPersons");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadApplicationsForBusinessTrip");
	
	// Addendum.
	ProfileDetails.Roles.Add("AddEditApplicationsForBusinessTrip");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashFlowLimits");
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users", "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có nhập và theo dõi đề nghị đi công tác';
									|ru = 'Под профилем вводятся и отслеживаются заявки на командировку';
									|en = 'Use this profile to enter and track travel requests'; fa = 'Use this profile to enter and track travel requests';
									|it = 'Sotto questo profilo vengono inserite e tracciate le domande di viaggi di lavoro';
									|pl = 'Pod profilem są wprowadzane i śledzone zgłoszenia na podróż służbową';
									|tr = 'İş gezisi talepleri profil altında girilir ve takip edilir'");
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_PaymentRequestInitiator

	// Profile "Initiator of applications for spending funds".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "PaymentRequestInitiator";
	ProfileDetails.Id = "66db1fed-b624-44eb-b74e-4884f543838d";
	ProfileDetails.Parent      = "Finances";
	ProfileDetails.Description  = NStr("vi = 'Khởi xướng giấy đề nghị thanh toán';
										|ru = 'Инициатор заявок на расходование денежных средств';
										|en = 'Payment request initiator'; fa = 'Payment request initiator';
										|it = 'Iniziatore delle domande di prelievo di contanti';
										|pl = 'Inicjator wniosków o wydatkowanie środków pieniężnych';
										|tr = 'Ödeme talebi başlatıcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	//KI
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SectionTreasuryCashForecasting");
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadPersons");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	
	// Addendum.
	ProfileDetails.Roles.Add("AddEditPaymentRequests");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashFlowLimits");
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có nhập và theo dõi giấy đề nghị thanh toán';
									|ru = 'Под профилем вводятся и отслеживаются заявки на расходование денежных средств';
									|en = 'Use this profile to enter and track payment requests'; fa = 'Use this profile to enter and track payment requests';
									|it = 'Sotto questo profilo vengono inserite e tracciate le domande di spesa';
									|pl = 'Pod profilem są wprowadzane i śledzone wnioski o wydatkowanie środków pieniężnych';
									|tr = 'Ödeme talepleri profil altında girilir ve takip edilir'");
	
	ProfilesDetails.Add(ProfileDetails);

#EndRegion

#Region Profile_Description_ParticipantOfSalePlanning
	// Profile "Sales planning participant".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantOfSalePlanning";
	ProfileDetails.Id = "bccb7814-f58a-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia lập kế hoạch bán hàng';
										|ru = 'Участник планирования продаж';
										|en = 'Participant of sale planning'; fa = 'Participant of sale planning';
										|it = 'Partecipante della pianificazione delle vendite';
										|pl = 'Uczestnik planowania sprzedaży';
										|tr = 'Satış planlama katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("AddEditAllocationBase");
	ProfileDetails.Roles.Add("ReadAllocationBase");
	ProfileDetails.Roles.Add("ReadProductRange");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadSalesPlans");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditSalesPlan");
	ProfileDetails.Roles.Add("ApprovalOfSalesPlans");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorPlanningProcessManagement");
	ProfileDetails.Roles.Add("ViewReportPlansEquilibriumCheck");
	ProfileDetails.Roles.Add("ViewReportSalesPlanFulfillment");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	// Additional roles for reading the feasibility report
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	
	// Additional rights.
	
	// Seasonal coefficients
	ProfileDetails.Roles.Add("AddEditSeasonalFactors");
	ProfileDetails.Roles.Add("ReadSeasonalIndexes");
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddSalesPlanningParticipantRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, sẽ tạo kế hoạch bán hàng và kiểm soát việc thực hiện chúng.';
									|ru = 'Под профилем происходит формирование планов продаж и контроль их исполнения.';
									|en = 'Generation of sale plans and control of their execution is occurred under the profile.'; fa = 'Generation of sale plans and control of their execution is occurred under the profile.';
									|it = 'Sotto il profilo avviene la generazione dei piani delle vendite e il controllo della loro esecuzione.';
									|pl = 'Dla profilu trwa utworzenie planów sprzedaży i kontrola ich wykonania.';
									|tr = 'Profilin altında satış tahminin oluşturulması ve bunların yürütülmesinin kontrolü yer almaktadır.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_ParticipantOfSalePlanningByCategories
	// Profile "Participant of sales planning by category".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantOfSalePlanningByCategories";
	ProfileDetails.Id = "bccb7813-f58a-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia lập kế hoạch bán hàng theo danh mục';
										|ru = 'Участник планирования продаж по категориям';
										|en = 'Participant of sale planning by categories'; fa = 'Participant of sale planning by categories';
										|it = 'Partecipante alla pianificazione delle vendite per categorie';
										|pl = 'Uczestnik planowania sprzedaży wg kategorii';
										|tr = 'Satışları kategorilere göre planlama katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("AddEditAllocationBase");
	ProfileDetails.Roles.Add("ReadAllocationBase");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadSalesPlansByCategories");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditSalesPlanByCategories");
	ProfileDetails.Roles.Add("ApprovalOfSalesPlansByCategories");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Additional rights.

	// Seasonal coefficients
	ProfileDetails.Roles.Add("AddEditSeasonalFactors");
	ProfileDetails.Roles.Add("ReadSeasonalIndexes");
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, sẽ tạo kế hoạch bán hàng theo thể loại.';
									|ru = 'Под профилем происходит формирование планов продаж по категориям.';
									|en = 'Generation of sale plans by categories is occurred under the profile.'; fa = 'Generation of sale plans by categories is occurred under the profile.';
									|it = 'Sotto il profilo avviene la generazione dei piani di vendite per categorie.';
									|pl = 'Dla profilu trwa utworzenie planów sprzedaży wg kategorii.';
									|tr = 'Profil altında, satış planları kategoriye göre oluşturulur.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_SalesForecastingUsingServiceParticipant
	// Profile "Participant of sales forecasting using the service".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantInSalesPlanningUsingService";
	ProfileDetails.Id = "b0cb7814-f58a-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia lập kế hoạch bán hàng thông qua dịch vụ dự báo bán hàng';
										|ru = 'Участник планирования продаж при помощи сервиса прогнозирования продаж';
										|en = 'Sales planning party using the sales forecasting service'; fa = 'Sales planning party using the sales forecasting service';
										|it = 'Partecipante alla pianificazione delle vendite che utilizza il servizio di previsione delle vendite';
										|pl = 'Uczestnik planowania sprzedaży za pomocą serwisu prognozowania sprzedaży';
										|tr = 'Satış tahmin hizmeti yardımıyla satış planlaması katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadProductRange");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadSalesPlans");
	ProfileDetails.Roles.Add("ReadSalesPlansByCategories");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditSalesPlan");
	ProfileDetails.Roles.Add("AddEditSalesPlanByCategories");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");

	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Additional roles for reading the feasibility report
	
	// Additional rights.
	ProfileDetails.Roles.Add("AddEditPlanningScenarios");
	ProfileDetails.Roles.Add("AddEditInventoryConsumptionPlans");
	
	// Seasonal coefficients
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddSalesForecastingParticipantRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện truy vấn kế hoạch bán hàng trong dịch vụ dự báo và xem kế hoạch.';
									|ru = 'Под профилем происходит запрос планов продаж у сервиса прогнозирования и их просмотр.';
									|en = 'Use this profile to request and view sales forecasts from the sales forecasting service.'; fa = 'Use this profile to request and view sales forecasts from the sales forecasting service.';
									|it = 'Sotto il profilo viene eseguita la richiesta di piani di vendita del servizio di previsione e loro visualizzazione.';
									|pl = 'Pod profilem jest wykonywane zapytanie planów sprzedaży od serwisu prognozowania i ich przegląd. ';
									|tr = 'Profil altında, satış planları satış tahmin hizmetinden talep edilir ve görüntülenir.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_SalesForecastingAdministratorUsingService
	// Profile "Sales forecasting administrator using the service".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SalesForecastingServiceAdministrator";
	ProfileDetails.Id = "b1cb7814-f58a-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Người quản trị dịch vụ dự báo bán hàng';
										|ru = 'Администратор сервиса прогнозирования продаж';
										|en = 'Sales forecasting service administrator'; fa = 'Sales forecasting service administrator';
										|it = 'Amministratore del servizio di previsione delle vendite';
										|pl = 'Administrator serwisu prognozowania sprzedaży';
										|tr = 'Satış tahmini hizmeti yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadAllocationBase");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadProductRange");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadSalesPlans");
	ProfileDetails.Roles.Add("ReadSalesPlansByCategories");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditSalesPlan");
	ProfileDetails.Roles.Add("AddEditSalesPlanByCategories");
	ProfileDetails.Roles.Add("ApprovalOfSalesPlans");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");

	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Additional roles for reading the feasibility report
	
	// Additional rights.
	ProfileDetails.Roles.Add("AddEditPlanningScenarios");
	ProfileDetails.Roles.Add("AddEditInventoryConsumptionPlans");
	
	// Seasonal coefficients
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddSalesForecastingAdministratorRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện tùy chỉnh dịch vụ dự báo bán hàng và sử dụng dịch vụ.';
									|ru = 'Под профилем происходит настройка сервиса прогнозирования продаж и его использование.';
									|en = 'Use this profile to set up and utilize the sales forecasting service.'; fa = 'Use this profile to set up and utilize the sales forecasting service.';
									|it = 'Sotto il profilo viene impostato il servizio di previsione delle vendite e il suo utilizzo.';
									|pl = 'Pod profilem jest wykonywane ustawienie serwisu prognozowania sprzedaży i jego użycie.';
									|tr = 'Profil altında, satış tahmin hizmeti ayarlanır ve kullanılır.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_ParticipantOfPurchasePlanning
	// Profile "Procurement planning participant".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ParticipantOfPurchasePlanning";
	ProfileDetails.Id = "bccb7812-f58a-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia lập kế hoạch mua hàng';
										|ru = 'Участник планирования закупок';
										|en = 'Participant of purchase planning'; fa = 'Participant of purchase planning';
										|it = 'Partecipante di pianificazione degli acquisti';
										|pl = 'Uczestnik planowania zakupów';
										|tr = 'Satın alma planlama katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadPurchasePlans");
	ProfileDetails.Roles.Add("ReadOfPlansOfGoodsStock");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditPurchasePlans");
	ProfileDetails.Roles.Add("ApprovalOfPurchasePlans");
	ProfileDetails.Roles.Add("AddEditPlanOfGoodsStock");
	ProfileDetails.Roles.Add("ApprovalOfPlansOfGoodsStock");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorPlanningProcessManagement");
	ProfileDetails.Roles.Add("ViewReportPlansEquilibriumCheck");
	ProfileDetails.Roles.Add("ViewReportPurchasePlanFulfillment");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	// Additional roles for reading the feasibility report
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	
	// Additional rights.
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, sẽ lập kế hoạch mua hàng và kiểm soát việc thực hiện các kế hoạch đó.';
									|ru = 'Под профилем происходит формирование планов закупок и контроль их исполнения.';
									|en = 'Generation of purchase plans and control of their execution is occurred under the profile'; fa = 'Generation of purchase plans and control of their execution is occurred under the profile';
									|it = 'Sotto il profilo avviene la generazione dei piani degli acquisti e controllo sulla loro esecuzione.';
									|pl = 'Dla profilu trwa utworzenie planów zakupów i kontrola ich wykonania.';
									|tr = 'Profil kapsamında satın alma planları oluşturulur ve bunların yürütülmesi kontrol edilir.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_AssemblyDisassemblyPlanningParticipant
	// Profile "Participant of assembly planning (disassembly)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssemblyDisassemblyPlanningParticipant";
	ProfileDetails.Id = "bccb7811-f58a-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Thành viên kế hoạch đóng bộ (dỡ bộ)';
										|ru = 'Участник планирования сборок (разборок)';
										|en = 'Participant of assembly scheduling (disassembly)'; fa = 'Participant of assembly scheduling (disassembly)';
										|it = 'Partecipante alla pianificazione di assemblaggi (disassemblaggi)';
										|pl = 'Uczestnik planowania montażu (demontażu)';
										|tr = 'Montaj (demontaj) planlama katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadAssemblyDisassemblyPlans");
	ProfileDetails.Roles.Add("ReadOfPlansOfGoodsStock");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditAssemblyDisassemblyPlans");
	ProfileDetails.Roles.Add("ApprovalOfAssemblyDisassemblyPlans");
	ProfileDetails.Roles.Add("AddEditPlanOfGoodsStock");
	ProfileDetails.Roles.Add("ApprovalOfPlansOfGoodsStock");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorPlanningProcessManagement");
	ProfileDetails.Roles.Add("ViewReportPlansEquilibriumCheck");
	ProfileDetails.Roles.Add("ViewReportAssemblyDisassemblyPlanFulfillment");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	// Additional roles for reading the feasibility report
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	
	// Additional rights.
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có lập các kế hoạch đóng bộ (tách bộ) và kiểm soát việc thực hiện chúng.';
									|ru = 'Под профилем происходит формирование планов сборки (разборки) и контроль их исполнения.';
									|en = 'Generation of kitting plans and control of their execution occurs under the profile.'; fa = 'Generation of kitting plans and control of their execution occurs under the profile.';
									|it = 'Sotto questo profilo avviene la generazione dei piani di assemblaggio (disassemblaggio) e controllo sulla loro esecuzione.';
									|pl = 'Dla profilu trwa utworzenie planów montażu (demontażu) i kontrola ich wykonania.';
									|tr = 'Profilin altında montaj (demontaj) programının oluşturulması ve bunların yürütülmesinin kontrolü yapılıyor.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_PlanningParticipantOfInternalConsumption
	// Profile "Sales planning participant".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "PlanningParticipantOfInternalConsumption";
	ProfileDetails.Id = "bccb7814-f58a-11e9-8805-1831bf523f06";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia lập kế hoạch tiêu dùng nội bộ';
										|ru = 'Участник планирования внутренних потреблений';
										|en = 'Participant of inventory consumption planning'; fa = 'Participant of inventory consumption planning';
										|it = 'Partecipante alla pianificazione di consumi interni';
										|pl = 'Uczestnik planowania konsumpcji wewnętrznych';
										|tr = 'İç tüketim planlama katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadInventoryConsumptionPlans");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditInventoryConsumptionPlans");
	ProfileDetails.Roles.Add("ApprovalOfInventoryConsumptionPlan");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorPlanningProcessManagement");
	ProfileDetails.Roles.Add("ViewReportPlansEquilibriumCheck");
	ProfileDetails.Roles.Add("ViewReportFulfillmentOfInventoryConsumptionPlan");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	// Additional roles for reading the feasibility report
	
	// Additional rights.
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, tiến hành tạo các kế hoạch tiêu thụ nội bộ và kiểm soát việc thực hiện chúng.';
									|ru = 'Под профилем происходит формирование планов внутренних потреблений и контроль их исполнения.';
									|en = 'Generation of inventory consumption plans and control of their execution is occurred under the profile.'; fa = 'Generation of inventory consumption plans and control of their execution is occurred under the profile.';
									|it = 'Sotto il profilo avviene la generazione dei piani di consumi interni e controllo sulla loro esecuzione.';
									|pl = 'Dla profilu trwa utworzenie planów konsumpcji wewnętrznych i kontrola ich wykonania.';
									|tr = 'Profil altında, stok tüketim planları oluşturulur ve bunların yürütülmesi kontrol edilir.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_PlanningAdministrator
	
	// Profile "Planning Administrator".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "PlanningAdministrator";
	ProfileDetails.Id = "00437d66-f57b-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Quản trị viên lập kế hoạch';
										|ru = 'Администратор планирования';
										|en = 'Planning administrator'; fa = 'Planning administrator';
										|it = 'Amministratore della pianificazione';
										|pl = 'Administrator planowania';
										|tr = 'Planlmaa yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
		
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsByCustodian");
	ProfileDetails.Roles.Add("ReadStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("ReadShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadMisgradingOfGoodsAtCustodian");
	ProfileDetails.Roles.Add("ReadDamageAtCustodian");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddEditPlanningDataSources");
	ProfileDetails.Roles.Add("AddEditPlanningScenarios");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadPlanRegisters");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadBudgetingData");
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadBudgetingSettings");
	// Reports and processing.
	
	// Additional rights.
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	
	AccessManagementLocalization.AddSchedulingAdministratorRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, sẽ tiến hành tạo và tùy chỉnh kịch bản lập kế hoạch hàng hóa và quy tắc điền kế hoạch.';
									|ru = 'Под профилем происходит создание и настройка сценариев товарного планирования и правил его заполнения.';
									|en = 'Creation and setting of scenarios of sales and operations planning and rules if its filling is occurred under the profile.'; fa = 'Creation and setting of scenarios of sales and operations planning and rules if its filling is occurred under the profile.';
									|it = 'Sotto questo profilo avviene la generazione e la configurazione degli scenari di pianificazione merceologica e delle regole di sua compilazione.';
									|pl = 'Dla profilu trwa utworzenie i ustawienie scenariuszy planowania towarowego i zasad jego wypełnienia.';
									|tr = 'Profil altında, ürün planlama senaryoları ve bunları doldurmak için kurallar oluşturulur ve ayarlanır.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion

#Region Profile_Description_SendingPrintedFormsAndReports
	
	// Profile "Sending printed forms and reports".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "SendingPrintedFormsAndReports";
	ProfileDetails.Id = "6297f216-b33f-4db0-b40d-08b80e8d4ca3";
	ProfileDetails.Parent      = "Other";
	ProfileDetails.Description  = NStr("vi = 'Gửi mẫu in và báo cáo (bổ sung)';
										|ru = 'Отправка печатных форм и отчетов (дополнительный)';
										|en = 'Send print forms and reports (additional)'; fa = 'Send print forms and reports (additional)';
										|it = 'Отправка печатных форм и отчетов (дополнительный)';
										|pl = 'Send print forms and reports (additional)';
										|tr = 'Rapor ve yazdırma formu gönderimi (ek)'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);

	// Additional rights.
	ProfileDetails.Roles.Add("ReadEmailAccounts");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("EmailAccounts", "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ cấp quyền gửi báo cáo và thư mà không cần quyền thêm và thay đổi tài khoản E-mail, cũng như xem lịch sử gửi thư.';
									|ru = 'Профиль дает права на отправку отчетов и писем без права добавления и изменения учетных записей электронной почты, а так же просмотра истории отправки писем.';
									|en = 'The profile authorizes you to send reports and emails without the right to add and change email accounts or to view the history of sent emails.'; fa = 'The profile authorizes you to send reports and emails without the right to add and change email accounts or to view the history of sent emails.';
									|it = 'Профиль дает права на отправку отчетов и писем без права добавления и изменения учетных записей электронной почты, а так же просмотра истории отправки писем.';
									|pl = 'The profile authorizes you to send reports and emails without the right to add and change email accounts or to view the history of sent emails.';
									|tr = 'Profil, e-posta hesapları ekle ve düzenle hakkı olmaksızın rapor ve e-posta gönderme ve e-posta gönderme geçmişini görüntüleme hakları tanır.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
#EndRegion
	
	GoodsDelivery.AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	RebatesServer.AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	AccessManagementLocalization.AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);

EndProcedure

// See AccessManagementOverridable.OnFillAccessRightsDependencies.
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	
	
	
EndProcedure

// See AccessManagementOverridable.OnFillAvailableRightsForObjectsRightsSettings.
Procedure OnFillAvailableRightsForObjectsRightsSettings(AvailableRights) Export
	
EndProcedure

// See AccessManagementOverridable.OnDefineAccessSettingInterface.
Procedure OnDefineAccessSettingInterface(SimplifiedInterface) Export
	
	SimplifiedInterface = GetFunctionalOption("BaseVersion");
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKindUsage.
Procedure OnFillAccessKindUsage(AccessKind, Use) Export
	
	SetPrivilegedMode(True);
	
	If AccessKind = "ProductGroups" Then
		
		Use = Constants.UseItemAccessGroups.Get();
		
	ElsIf AccessKind = "PartnerGroups" Then
		
		Use = Constants.UsePartnerAccessGroups.Get();
		
	ElsIf AccessKind = "GroupsOfIndividuals" Then
		
		Use = False;
	ElsIf AccessKind = "GroupsOfBudgetTypes" Then
		
		Use = Constants.UseAccessGroupsOfItemKindsAndBudgetBalanceItems.Get();
		
	ElsIf AccessKind = "GroupsOfBudgetItemsAndIndicators" Then
		
		Use = Constants.UseAccessGroupsOfItemKindsAndBudgetBalanceItems.Get();
		
	ElsIf AccessKind = "StatusesOfInternalAcceptanceCertificate" Then
		
		Use = Constants.UseStatusesOfInternalWorksAcceptance.Get();
		
	ElsIf AccessKind = "StatusesOfRegisteredRecordsOfProductsAndMaterials" Then
		
		Use = Constants.UseStatusesOfProductsAndMaterialsMovements.Get();
	ElsIf AccessKind = "BusinessTransactions"
	 Or AccessKind = "CustomerAgreementsReading"
	  Or AccessKind = "TermsOfSaleUpdate" Then
		
		Use = True;
		
	EndIf;
	
	AccessManagementLocalization.FillInUseOfAccessType(AccessKind, Use);
	
	SetPrivilegedMode(False);
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessRestriction.
Procedure OnFillAccessRestriction(List, Restriction) Export
	
	If List = Metadata.Catalogs.AdditionalAttributesAndInfoSets Then
		
		Restriction.Text =
		"AttachAdditionalTables
		|ThisList AS ThisList
		|
		|LEFT JOIN Catalog.ItemKinds AS TypesOfPropertySetProducts 
		|ON TypesOfPropertySetProducts.PropertiesSet = ThisList.Ref
		|
		|LEFT JOIN Catalog.ItemKinds AS TypesOfProductSetsOfPropertiesCharacteristics
		|ON TypesOfProductSetsOfPropertiesCharacteristics.CharacteristicsPropertySet = ThisList.Ref
		|;
		|AllowRead
		|WHERE TRUE
		|;
		|AllowUpdateIfReadingAllowed
		|WHERE
		|	IsFolder
		|	OR ValueAllowed(TypesOfPropertySetProducts.Ref)
		|	OR ValueAllowed(TypesOfProductSetsOfPropertiesCharacteristics.Ref)";
		
	ElsIf List = Metadata.Documents.Meeting
	      Or List = Metadata.Documents.PlannedInteraction Then
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
		|	OR ValueAllowed(Author, Disabled AS FALSE)
		|	OR ValueAllowed(Attendees.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(Attendees.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)";
		
	ElsIf List = Metadata.Documents.SMSMessage Then
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
		|	OR ValueAllowed(Author, Disabled AS FALSE)
		|	OR ValueAllowed(Recipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(Recipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)";
		
	ElsIf List = Metadata.Documents.PhoneCall Then
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
		|	OR ValueAllowed(Author, Disabled AS FALSE)
		|	OR ValueAllowed(SubscriberContact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(SubscriberContact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)";
		
	ElsIf List = Metadata.Documents.IncomingEmail Then
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
		|	OR ValueAllowed(Account, Disabled AS FALSE)
		|	OR ValueAllowed(EmailRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(EmailRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)
		|	OR ValueAllowed(CCRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(CCRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)
		|	OR ValueAllowed(ReplyRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(ReplyRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)";
		
	ElsIf List = Metadata.Documents.OutgoingEmail Then
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
		|	OR ValueAllowed(Author, Disabled AS FALSE)
		|	OR ValueAllowed(Account, Disabled AS FALSE)
		|	OR ValueAllowed(EmailRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(EmailRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)
		|	OR ValueAllowed(CCRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(CCRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)
		|	OR ValueAllowed(ReplyRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(ReplyRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)
		|	OR ValueAllowed(BccRecipients.Contact ONLY Catalog.Partners, Disabled AS FALSE)
		|	OR ValueAllowed(CAST(BccRecipients.Contact AS Catalog.ContactPersonsForPartners).Owner, Disabled AS FALSE)";
		
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnChangeAccessValuesSets.
Procedure OnChangeAccessValuesSets(Ref, RefsToDependentObjects) Export
	
	
	
EndProcedure

// See SaaSOperationsCTLOverridable.SetDefaultRights
//
Procedure SetDefaultRights(User, AccessAllowed) Export

	If AccessAllowed Then
		SalesProfileProperties = ProfileSalesManager();
		AddUserToGroupWithSpecifiedProfile(User, SalesProfileProperties);
	EndIf;

EndProcedure

// See SaaSOperationsCTLOverridable.SetAccessToThisDataArea
//
Procedure SetAccessToThisDataArea(User, AccessAllowed) Export

	AccessManagementLocalization.SetAccessToThisDataArea(User, AccessAllowed);

EndProcedure

#EndRegion

#Region AccessToDetailsOfMetadataObjects

// Checks whether the details of an existing directory element can be changed before recording.
//
// Parameters:
//		Object - CatalogObject - object of any reference list
//		AttributesNotToCheck - String - list of Bank details that don't need to be changed
//		Cancel - Boolean - indicates that the recording was rejected.
// 
// Returns:
//  Boolean - Flag of the permissibility of changing the details of the directory
Function CheckWhetherCatalogDetailsCanBeChanged(Object, AttributesNotToCheck = "", Cancel = False) Export
	
	If Object.IsNew() Then
		Return True; // for new items there is no need to check
	EndIf;
	
	IsFolder = (Object.Metadata().Hierarchical And Object.IsFolder);
	UnavailableBankingDetails = SettingsValueCached.DetailsOfBusinessCatalogThatCanTBeEdited(Object.Metadata().Name, IsFolder, AttributesNotToCheck);
	
	If IsBlankString(UnavailableBankingDetails) Then
		Return True; // there are no details unavailable for editing
	EndIf;
	
	MistakenlyChangedBankingDetails = "";
	
	ObjectAttributes = New Structure(UnavailableBankingDetails);
	FillPropertyValues(ObjectAttributes, Object);
	
	LinkDetails_ = Common.ObjectAttributesValues(Object.Ref, UnavailableBankingDetails);
	
	For Each KeyAndValue In ObjectAttributes Do
		If KeyAndValue.Value <> LinkDetails_[KeyAndValue.Key] Then
			MistakenlyChangedBankingDetails =
				MistakenlyChangedBankingDetails + ?(IsBlankString(MistakenlyChangedBankingDetails), "", ", ") + """" + KeyAndValue.Key + """";
		EndIf;
	EndDo;
	
	If IsBlankString(MistakenlyChangedBankingDetails) Then
		Return True; // there are rights to all the changed details
	EndIf;
	
	ErrorMessage = NStr("vi = 'Không đủ quyền để thay đổi mục tin %1 %2';
						|ru = 'Недостаточно прав на изменение реквизит%1 %2';
						|en = 'Insufficient rights to change attribute%1 %2'; fa = 'Insufficient rights to change attribute%1 %2';
						|it = 'Diritti insufficienti per la modifica dei requisiti %1%2';
						|pl = 'Nie masz wystarczających uprawnień do zmiany rekwizytu%1 %2';
						|tr = 'Öznitelik değişimi yetkisi eksik%1 %2'");
	ErrorMessage =
		StringFunctionsClientServer.SubstituteParametersToString(
			ErrorMessage,
			?(Find(MistakenlyChangedBankingDetails, ",") > 0, "ov:", "a"),
			MistakenlyChangedBankingDetails);
	
	CommonClientServer.MessageToUser(ErrorMessage,,,, Cancel);
	
	Return False;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Utility function. Made export for ease of implementation.
//
// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles.
//
Procedure AddRequiredRolesToYourProfile(ProfileDetails) Export

	// Launching 1C:Enterprises
	ProfileDetails.Roles.Add("StartThinClient");
	If Not Common.DataSeparationEnabled() Then
		ProfileDetails.Roles.Add("StartThickClient");
	EndIf;
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("SaveUserData");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	
	// Basic right
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessTM");
	
	// Tasks and tasks
	ProfileDetails.Roles.Add("AddEditJobs");
	ProfileDetails.Roles.Add("EditCompleteTask");
	ProfileDetails.AccessKinds.Add("Users","AllAllowedByDefault");
	
	// Notes and reminders
	ProfileDetails.Roles.Add("AddEditNotes");
	ProfileDetails.Roles.Add("AddEditNotifications");
	
	//Incidents
	ProfileDetails.Roles.Add("AddEditIncidents");
	
	// Electronic signature
	ProfileDetails.Roles.Add("AddEditDigitalSignatures");
	ProfileDetails.Roles.Add("AddEditDigitalSignatureAndEncryptionKeyCertificates");
	ProfileDetails.Roles.Add("EncryptAndDecryptData");
	ProfileDetails.Roles.Add("ReadPersonalElectronicSignatureAndEncryptionKeyCertificates");
	
	// Files and File folders
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	
	// Print subsystem
	ProfileDetails.Roles.Add("PrintFormsEdit");
	
	// The subsystem organizer
	ProfileDetails.Roles.Add("SectionOrganizer");
	
	// Additional information
	ProfileDetails.Roles.Add("EditAdditionalInfo");
	
	// Edit the details of the facilities
	ProfileDetails.Roles.Add("EditObjectAttributes");
	
	// Using additional reports and treatments
	ProfileDetails.Roles.Add("ReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("UseAdditionalTMReportsAndDataProcessors");
	
	// Report options
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	
	// The connected equipment
	ProfileDetails.Roles.Add("UsePeripheralsUsing");
	
	// Current Affairs
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	
	// Basic NSI
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("ReadRelativeExchangeRates");
	ProfileDetails.Roles.Add("ViewCurrencies");
	
	// System health checks
	ProfileDetails.Roles.Add("ReadSystemStateChecks");
	ProfileDetails.Roles.Add("ReadAccountingCheckResults");
	
	// Document reversal
	ProfileDetails.Roles.Add("AddEditReverseTransaction");
	
	// Description of Processes
	DemoScenarios.AddRolesReadingSubsystemObjectsDescribingProcesses(ProfileDetails);
	
	AccessManagementLocalization.AddRequiredRolesToYourProfile(ProfileDetails);
	
EndProcedure

// Service function. Made export-friendly to avoid duplication.

// It is used when forming the MFP Accountant profile.

//
Procedure AddAccountantLocalAccountingRolesToRead(ProfileDetails) Export
	NonCurrentAssets.AddRolesForReadAccessToVNASubsystem(ProfileDetails);
	LeasedAssetAccounting.AddRolesForReadAccessToVNASubsystem(ProfileDetails);
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadLoyaltyCardKinds");
	ProfileDetails.Roles.Add("ReadAnalyticalItemsGroups");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadLoanAndDepositContracts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadLoyaltyCards");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadClassifiersOfIncomeExpensesSettings");
	ProfileDetails.Roles.Add("ReadClassifiersAndSettingsOfOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadCostAllocationSettings");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");	
	ProfileDetails.Roles.Add("ReadCCDNumbers");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCustomerComplaints");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadLeaseContracts");
	ProfileDetails.Roles.Add("ReadIndicatorValuesToAllocateCosts");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadItemizedExpenseAllocationSettings");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadConstructionObjects");
	ProfileDetails.Roles.Add("ReadAccountingObjectsOfFutureExpenseCommitments");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadExpenseRecordMethods");
	ProfileDetails.Roles.Add("ReadProductionLots");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("ReadSubAssets");
	ProfileDetails.Roles.Add("ReadRulesForAccrualOfInventoryImpairmentProvision");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	// Documents reading
	ProfileDetails.Roles.Add("ReadExpenseReports");
	ProfileDetails.Roles.Add("ReadAdjustmentsOfARAPAccountingForAdvanceHolders");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServices");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsIssue");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsReceipt");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsReceiptOfCustomerReturn");
	ProfileDetails.Roles.Add("ReadDiscrepancyReportsByGoodsTransfer");
	ProfileDetails.Roles.Add("ReadCustomerBonusCertificate");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadInventoryConsumption");
	ProfileDetails.Roles.Add("ReadReturnsOfGoodsFromCustomers");
	ProfileDetails.Roles.Add("ReadIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsByCustomers");
	ProfileDetails.Roles.Add("ReadReturnablePackagingRedemptionsFromVendors");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsByCustodian");
	ProfileDetails.Roles.Add("ReadCashAccountAuditDocuments");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadBankDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfRecordingOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadDocumentsOfOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadDocumentsRecordingCashCollectionDiscrepancies");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadTransferOrders");
	ProfileDetails.Roles.Add("ReadAssemblyOrders");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadInventoryAssignmentAdjustingEntries");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadDebitNotes");
	ProfileDetails.Roles.Add("ReadCreditNotes");
	ProfileDetails.Roles.Add("ReadCostAllocationSettings");
	ProfileDetails.Roles.Add("ReadLoanAndDepositAccruals");
	ProfileDetails.Roles.Add("ReadPlannedCashInflow");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	ProfileDetails.Roles.Add("ReadStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("ReadNotesForRecordingSurplusesShortagesDamage");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsIssues");
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadMerchantStatements");
	ProfileDetails.Roles.Add("ReadCommissionAgentsReports");
	ProfileDetails.Roles.Add("ReadReportsToConsignor");
	ProfileDetails.Roles.Add("ReadPurchasingReportsToConsignor");
	ProfileDetails.Roles.Add("ReadRetailReturnsReport");	
	ProfileDetails.Roles.Add("ReadRetailSalesReports");
	ProfileDetails.Roles.Add("ReadShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadInventoryRecounts");
	ProfileDetails.Roles.Add("ReadInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadReceiptsOfServicesToBusinessUnit");
	ProfileDetails.Roles.Add("ReadGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("ReadVendorInvoicesReturnsToVendors");
	ProfileDetails.Roles.Add("ReadVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadOtherGoodsRecordingAsReceived");
	ProfileDetails.Roles.Add("ReadDeferredExpenseAllocations");
	ProfileDetails.Roles.Add("ReadOtherCostAllocation");
	ProfileDetails.Roles.Add("ReadCustomerInvoices");
	ProfileDetails.Roles.Add("ReadGoodsShipmentsToCustomers");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadPeriodEndTransactions");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	ProfileDetails.Roles.Add("ReadARAPReconciliation");
	ProfileDetails.Roles.Add("ReadWarehouseActs");
	ProfileDetails.Roles.Add("ReadWriteOffsOfDiscrepanciesBetweenReceiptAndPurchase");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadCustomerCommercialInvoices");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadIssuedTaxInvoicesPrepayment");
	ProfileDetails.Roles.Add("ReadGoodsImportApplications");
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	
	//++ WE
	// BankFeeds
	ProfileDetails.Roles.Add("ReadBankFeeds");
	//-- WE
	ProfileDetails.Roles.Add("ReadInternalAcceptanceCertificate");
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");
	ProfileDetails.Roles.Add("ReadAssetActivityRecords");
	ProfileDetails.Roles.Add("ReadAccrualOrWriteOffOfLossAllowance");
	ProfileDetails.Roles.Add("ReadFutureExpenseCommitmentsAccrualWriteOff");
	ProfileDetails.Roles.Add("ReadBackflushProduction");
	ProfileDetails.Roles.Add("ReadRecyclableWasteAllocation");
	ProfileDetails.Roles.Add("ReadManufacturingCostAllocation");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadRMOrders");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadInitialWIPBalancesByProductionLots");
	ProfileDetails.Roles.Add("ReadIntercompanyConsumptionReportsSubcontractingServicesDelivered");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadCashTransferOrders");
	// Reading registers.
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfTransferOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfAssemblyOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadRemainingReceivedReturnablePackaging");
	ProfileDetails.Roles.Add("ReadAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadDiscountInterestExpense");
	ProfileDetails.Roles.Add("ReadFinancialInstrumentsARAP");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfSurplusesAndShortages");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadFinancialResults");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadingCELRegisters");
	ProfileDetails.Roles.Add("ReadBalanceOrdersOfMaterialsInProduction");
	ProfileDetails.Roles.Add("ReadOtherWIPExpenses");
	ProfileDetails.Roles.Add("ReadRMActivities");


	// Registers of advanced settlement analytics
	ProfileDetails.Roles.Add("ReadRecordsCounterpartyIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCounterpartyCounterparty");
	
	// Registers of advanced cost analysis of goods
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	
	// Registers
	ProfileDetails.Roles.Add("ReadWIPLaborCosts");
	ProfileDetails.Roles.Add("ReadOtherWIPExpenses");
	// Registers of advanced cash analytics
	ProfileDetails.Roles.Add("ReadCashTransfers");
	ProfileDetails.Roles.Add("ReadRecordsCashIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsCashCounterparty");
	ProfileDetails.Roles.Add("ReadPaymentSchedule");
	ProfileDetails.Roles.Add("ReadBankAccountBalance");
	ProfileDetails.Roles.Add("ReadCashBalanceInCashRegister");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadCashBalanceOfAdvanceHolders");
	ProfileDetails.Roles.Add("ReadCashBalance");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	//
	// Reports and processing.
	ProfileDetails.Roles.Add("UseLoanAndDepositItemsAnalysis");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferDocumentsForRegistration");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UsePurchaseDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseIntercompanyDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseSalesDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseTransactionOfMonthEndClosingDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfGoodsHandoversAndRedemptions");
	ProfileDetails.Roles.Add("UseCounterpartyCheckIssue");
	ProfileDetails.Roles.Add("AccountantSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewConsignmentSalesStockReport");
	ProfileDetails.Roles.Add("ReportsOnSettlementsBetweenOrganizations");
	ProfileDetails.Roles.Add("ViewReportsVATFromPrepayments");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("ViewCashFlowStatements");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("FAAccountantSReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewingReportsOnInventoryImpairmentProvision");
	ProfileDetails.Roles.Add("UseSalesVarianceOfFinancialInstruments");
	ProfileDetails.Roles.Add("UseLoanAndDepositRegistry");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	
	// Subsystems of the global command interface
	ProfileDetails.Roles.Add("PurchaseSection");
	ProfileDetails.Roles.Add("PurchasingVendorRebates");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("SubsystemTreasury");
	ProfileDetails.Roles.Add("SubsystemFinancialResultAndControlling");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	// Excises
	ProfileDetails.Roles.Add("ReadExciseRecords");
	ProfileDetails.Roles.Add("ViewAccruedExciseAmountsReport");
	
	// Read access to VAT accounting
	ProfileDetails.Roles.Add("ReadVATRegisters");

	ProfileDetails.Roles.Add("ReadReceivedTaxInvoicesPrepayment");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfImportDocuments");
	ProfileDetails.Roles.Add("ReadVATAccountingDocuments");
	
	ProfileDetails.Roles.Add("ReadOperationCategories");
	ProfileDetails.Roles.Add("ReadMovementsInOperation");
	ProfileDetails.Roles.Add("ReadWriteOffsInOperation");
	ProfileDetails.Roles.Add("ReadReceiptsOfInventoryInOperation");
	ProfileDetails.Roles.Add("ReadPhysicalCountsOfInventoryInOperation");
	ProfileDetails.Roles.Add("ReadInventoryInOperation");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentJournalInventoryInOperation");
	
	ProfileDetails.AccessKinds.Add("StatusesOfInternalAcceptanceCertificate", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	AccessManagementLocalization.AddAccountantLocalAccountingRolesToRead(ProfileDetails);
	
EndProcedure

// Service function. Made export-friendly to avoid duplication.
//
Procedure AddAccountantRolesLocalAccountingRolesForChange(ProfileDetails) Export
	NonCurrentAssets.AddRolesToAccessSubsystemInResponseToChange(ProfileDetails);
	LeasedAssetAccounting.AddRolesToAccessSubsystemInResponseToChange(ProfileDetails);
	InventoryInOperationServer.AddRolesToAccessSubsystemForModification(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddEditAnalyticalInventoryGroups");
	ProfileDetails.Roles.Add("ChangeOfFinancialAccountingGroupForItems");
	ProfileDetails.Roles.Add("AddEditIncomeExpensesClassifiersAndSettings");
	ProfileDetails.Roles.Add("AddEditOtherAssetsAndLiabilitiesClassifiersAndSettings");
	ProfileDetails.Roles.Add("AddEditCCDNumbers");
	ProfileDetails.Roles.Add("AddEditLabelsTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("AddEditAssets");
	ProfileDetails.Roles.Add("AddEditConstructionObjects");
	ProfileDetails.Roles.Add("AddEditExpenseRecordMethods");
	ProfileDetails.Roles.Add("AddEditSubAssets");
	ProfileDetails.Roles.Add("AddEditRunningTimeValues");
	ProfileDetails.Roles.Add("AddEditTypesOfProvisions");
	ProfileDetails.Roles.Add("AddEditAccountingObjectsOfFutureExpenseCommitments");
	ProfileDetails.Roles.Add("AddEditOfRulesForCalculationOfInventoryImpairmentProvision");
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("InventoryConsumptionInExcessOfOrder");
	ProfileDetails.Roles.Add("AddEditExpenseReports");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportsFollowingTransfer");
	ProfileDetails.Roles.Add("AddEditOBEntryARAP");
	ProfileDetails.Roles.Add("AddEditOBEntryCash");
	ProfileDetails.Roles.Add("AddEditOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("AddEditOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("AddEditOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("AddEditOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("AddEditOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("AddEditOBEntryARAPAdvanceHolders");
	ProfileDetails.Roles.Add("AddEditOBEntryGoods");
	ProfileDetails.Roles.Add("AddEditInventoryConsumption");
	ProfileDetails.Roles.Add("AddEditIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("AddEditInternalGoodsTransferDocuments");
	ProfileDetails.Roles.Add("AddEditOtherAssetsAndLiabilitiesDocuments");
	ProfileDetails.Roles.Add("AddEditOtherIncomeAndExpensesDocuments");
	ProfileDetails.Roles.Add("AddEditDocumentsRecordingCashCollectionDiscrepancies");
	ProfileDetails.Roles.Add("AddEditInventoryAssignmentAdjustmentEntries");
	ProfileDetails.Roles.Add("AddEditAdjustmentsOfInventoryAssignmentAccounting");
	ProfileDetails.Roles.Add("AddEditDebitNotes");
	ProfileDetails.Roles.Add("AddEditAdjustmentsOfARAPAccountingForAdvanceHolders");
	ProfileDetails.Roles.Add("AddEditCreditNotes");
	ProfileDetails.Roles.Add("AddEditCostAllocationSettings");
	ProfileDetails.Roles.Add("AddEditAccrualsForLoansAndDeposits");
	ProfileDetails.Roles.Add("AddEditGoodsTransfers");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("AddEditCustomerComplaints");
	ProfileDetails.Roles.Add("AddEditVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("AddEditOtherGoodsReceipt");
	ProfileDetails.Roles.Add("AddEditDeferredExpenseAllocation");
	ProfileDetails.Roles.Add("AddEditOtherCostAllocation");
	ProfileDetails.Roles.Add("AddEditCustomerInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("AddEditPeriodEndTransactions");
	ProfileDetails.Roles.Add("AddEditGoodsAssemblies");
	ProfileDetails.Roles.Add("AddEditARAPReconciliation");
	ProfileDetails.Roles.Add("AddEditWarehouseGoodsIssueReceipt");
	ProfileDetails.Roles.Add("AddEditWriteOffsOfDiscrepanciesBetweenReceiptAndPurchase");
	ProfileDetails.Roles.Add("AddEditPurchaseRequests");
	ProfileDetails.Roles.Add("AddEditProvisionRequests");
	ProfileDetails.Roles.Add("AddEditReportsOnWriteOffOfGoodsAcceptedForStorage");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditIssuedTaxInvoicesForPrepayment");
	ProfileDetails.Roles.Add("AddEditVATAccountingDocuments");
	ProfileDetails.Roles.Add("AddEditMovementsOfProductsAndMaterials");
	ProfileDetails.Roles.Add("AddEditAssetActivityRecords");
	ProfileDetails.Roles.Add("AddEditAccrualOrWriteOffOfLossAllowance");
	ProfileDetails.Roles.Add("AddEditFutureExpenseCommitmentsAccrualWriteOff");
	ProfileDetails.Roles.Add("AddEditProductionCostsCostAllocation");
	ProfileDetails.Roles.Add("AddEditOfProductCostElements");
	ProfileDetails.Roles.Add("AddEditSettingsOfLockFromChanges");
	
	
	ProfileDetails.Roles.Add("AddEditWIPOpeningBalancesByProductionLots");
	ProfileDetails.Roles.Add("AddEditIntercompanyConsumptionReportsSubcontractingServicesDelivered");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	
	ProfileDetails.Roles.Add("AddEditApplicationsForGoodsImport");
	
	ProfileDetails.Roles.Add("AddEditTaxInvoiceReceivedForAdvance");
	
	ProfileDetails.Roles.Add("AddEditARAPAccountingScheduleAdjustment");
	
	// Additional rights.
	ProfileDetails.Roles.Add("ChangePurchaseDocumentRate");
	ProfileDetails.Roles.Add("ChangeSaleDocumentRate");
	
	AccessManagementLocalization.AddAccountantRolesLocalAccountingRolesForChange(ProfileDetails);
	
EndProcedure


#Region InfobaseUpdate

// See InfobaseUpdateOverridable.OnInitialItemsFilling
Procedure SetNameOfAccessGroupProfileGroups(Items) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AccessGroupProfiles.PredefinedDataName AS PredefinedDataName
		|FROM
		|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
		|WHERE
		|	AccessGroupProfiles.IsFolder
		|	AND AccessGroupProfiles.Predefined";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	PredefinedGroups = QueryResult.Unload().UnloadColumn("PredefinedDataName");
	
	If PredefinedGroups.Find("MasterDataAndSettings") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "MasterDataAndSettings";
		Item.Description = NStr("vi = 'Quản trị và thông tin tra cứu';
								|ru = 'Администрирование и НСИ';
								|en = 'Control and reference data'; fa = 'Control and reference data';
								|it = 'Amministrazione Informazioni sulle normative di riferimento';
								|pl = 'Ustawienia';
								|tr = 'Yönetim ve Master Veri'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("Budgeting") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "Budgeting";
		Item.Description = NStr("vi = 'Lập ngân sách';
								|ru = 'Бюджетирование';
								|en = 'Budgeting'; fa = 'بودجه‌بندی';
								|it = 'Budgeting';
								|pl = 'Budgeting';
								|tr = 'Bütçeleme'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("GovernmentInformationSystems") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "GovernmentInformationSystems";
		Item.Description = NStr("vi = 'Hệ thống thông tin quốc gia';
								|ru = 'Государственные информационные системы';
								|en = 'State information systems'; fa = 'State information systems';
								|it = 'Sistemi informativi statali';
								|pl = 'Państwowe systemy informacyjne';
								|tr = 'Devlet bilgi sistemleri'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("ProcurementAndInventory") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "ProcurementAndInventory";
		Item.Description = NStr("vi = 'Mua hàng và vật tư';
								|ru = 'Закупки и запасы';
								|en = 'Purchase and inventory'; fa = 'Purchase and inventory';
								|it = 'Acquisti e scorte';
								|pl = 'Zakupy i zapasy';
								|tr = 'Satın alma ve stoklar'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("SalaryAndPersonnel") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "SalaryAndPersonnel";
		Item.Description = NStr("vi = 'Tiền lương và nhân sự';
								|ru = 'Зарплата и кадры';
								|en = 'HR & Payroll'; fa = 'HR & Payroll';
								|it = 'Stipendio e personale';
								|pl = 'Wynagrodzenie i kadry';
								|tr = 'Bordro ve personeller'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("InternationalFinancialAccounting") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "InternationalFinancialAccounting";
		Item.Description = NStr("vi = 'Kế toán IFRS';
								|ru = 'Международный финансовый учет';
								|en = 'General ledger'; fa = 'دفتر کل';
								|it = 'Rilevazione contabilità internazionale';
								|pl = 'Międzynarodowa ewidencja finansowa';
								|tr = 'Genel muhasebe'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("Planning") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "Planning";
		Item.Description = NStr("vi = 'Lập kế hoạch';
								|ru = 'Планирование';
								|en = 'Planning'; fa = 'برنامه‌ریزی';
								|it = 'Pianificazione';
								|pl = 'Planning';
								|tr = 'Planlama'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("Sales") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "Sales";
		Item.Description = NStr("vi = 'Bán hàng';
								|ru = 'Продажи';
								|en = 'Sales'; fa = 'فروش';
								|it = 'Vendite';
								|pl = 'Sprzedaż';
								|tr = 'Satış'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("Production") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "Production";
		Item.Description = NStr("vi = 'Sản xuất';
								|ru = 'Производство';
								|en = 'Production'; fa = 'تولید';
								|it = 'Produzione';
								|pl = 'Produkcja';
								|tr = 'Üretim'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("Other") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "Other";
		Item.Description = NStr("vi = 'Dạng khác';
								|ru = 'Прочее';
								|en = 'Other'; fa = 'سایر';
								|it = 'Altro';
								|pl = 'Other';
								|tr = 'Diğer'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("RMManagement") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "RMManagement";
		Item.Description = NStr("vi = 'Quản lý sửa chữa';
								|ru = 'Управление ремонтами';
								|en = 'R&M management'; fa = 'R&M management';
								|it = 'Gestione delle riparazioni';
								|pl = 'Zarządzanie remontami';
								|tr = 'Bakım-onarım yönetimi'", Common.DefaultLanguageCode());
	EndIf;
	
	If PredefinedGroups.Find("Finances") <> Undefined Then
		Item = Items.Add();
		Item.PredefinedDataName = "Finances";
		Item.Description = NStr("vi = 'Tài chính';
								|ru = 'Финансы';
								|en = 'Finances'; fa = 'Finances';
								|it = 'Finanze';
								|pl = 'Finances';
								|tr = 'Finans'", Common.DefaultLanguageCode());
	EndIf;
	
EndProcedure


#EndRegion

// Returns properties of the "Managerproducts" profile
// 
// Returns:
// 	Structure - LongDesc:
// 	* UID - UUID - unique profile ID
// 	* Description - String - name of the access groups profile
// 	* Id - String - string Presentation of the identifier
// 	* Name - String - profile name
//
Function ProfileSalesManager()
	
	SalesManager = New Structure;
	SalesManager.Insert("Name", "SalesManager");
	SalesManager.Insert("Description", NStr("vi = 'Bộ quản lý theo bán hàng';
											|ru = 'Менеджеры по продажам';
											|en = 'Sales representatives'; fa = 'نمایندگان فروش';
											|it = 'Менеджеры по продажам';
											|pl = 'Sales representatives';
											|tr = 'Satış müdürleri'"));
	SalesManager.Insert("Id", "50ef1c86-a324-11ef-8cb7-3c7c3fc28e23");
	SalesManager.Insert("UID", New UUID("50ef1c86-a324-11ef-8cb7-3c7c3fc28e23"));

	Return SalesManager;
	
EndFunction

// Adds a user to the group with the specified profile with the largest number of users, provided
// that he does not belong to any other groups.
// 
// Parameters:
// 	User - CatalogRef.Users - the user to add to the group,
// 	ProfileProperties - See ProfileSalesManager.
//
Procedure AddUserToGroupWithSpecifiedProfile(User, ProfileProperties)

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	AccessGroups_Users.Ref
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups_Users
	|WHERE
	|	AccessGroups_Users.User = &User
	|	AND NOT AccessGroups_Users.Ref.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	AccessGroups.Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	NOT AccessGroups.Ref.DeletionMark
	|	AND AccessGroups.Ref.Profile.SuppliedDataID = &IdOfGroupProfile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	AccessGroups_Users.Ref
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups_Users
	|WHERE
	|	NOT AccessGroups_Users.Ref.DeletionMark
	|	AND AccessGroups_Users.Ref.Profile.SuppliedDataID = &IdOfGroupProfile
	|ORDER BY
	|	AccessGroups_Users.LineNumber DESC";

	Query.SetParameter("User", User);
	Query.SetParameter("IdOfGroupProfile", ProfileProperties.UID);

	QueryResults = Query.ExecuteBatch();
	If Not QueryResults[0].IsEmpty() Then
		UserIsAlreadyInAccessGroup = StrTemplate(NStr("vi = 'Nhóm truy cập đã gồm người sử dụng %1.';
														|ru = 'Пользователь %1 уже состоит в группе доступа.';
														|en = 'User %1 is already included in the access group.'; fa = 'User %1 is already included in the access group.';
														|it = 'Пользователь %1 уже состоит в группе доступа.';
														|pl = 'User %1 is already included in the access group.';
														|tr = '%1 kullanıcısı zaten erişim grubunun bir parçasıdır.'"),
			User);
		FunctionName = "TMAccessManagement.AddUserToGroupWithSpecifiedProfile";
		WriteLogEvent(StrTemplate(NStr("vi = '%1';
										|ru = '%1';
										|en = '%1'; fa = '%1';
										|it = '%1';
										|pl = '%1';
										|tr = '%1'",
			Common.DefaultLanguageCode()),FunctionName), EventLogLevel.Warning,
			Metadata.Catalogs.Users, , UserIsAlreadyInAccessGroup);
		Return;
	EndIf;

	If QueryResults[1].IsEmpty() Then
		
		BeginTransaction();
		Try
			
			GroupObject = Catalogs.AccessGroups.CreateItem();
			GroupObject.Description = ProfileProperties.Description;
			GroupObject.Profile = Catalogs.AccessGroupProfiles.GetRef(ProfileProperties.UID);
			GroupObject.Users.Add().User = User;
			
			GroupObject.Write();
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể tạo nhóm truy cập do:
				 |%1';
				 |ru = 'Не удалось создать группу доступа по причине:
				 |%1';
				 |en = 'Cannot create an access group due to:
				 |%1'; fa = 'Cannot create an access group due to:
				 |%1';
				 |it = 'Не удалось создать группу доступа по причине:
				 |%1';
				 |pl = 'Cannot create an access group due to:
				 |%1';
				 |tr = 'Erişim grubu şu nedenle oluşturulamadı:
				 |%1'"), ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			FunctionName = "TMAccessManagement.AddUserToGroupWithSpecifiedProfile";
			WriteLogEvent(StrTemplate(NStr(
					"vi = '%1';
					|ru = '%1';
					|en = '%1'; fa = '%1';
					|it = '%1';
					|pl = '%1';
					|tr = '%1'",
				Common.DefaultLanguageCode()),FunctionName), EventLogLevel.Error,
				Metadata.Catalogs.Users, , ErrorMessage);
			
		EndTry;
		
		Return;
		
	EndIf;

	If QueryResults[2].IsEmpty() Then
		Selection = QueryResults[1].Select();
	Else
		Selection = QueryResults[2].Select();
	EndIf;

	If Selection.Next() Then
		BeginTransaction();
		Try
			GroupObject = Selection.Ref.GetObject();
			GroupObject.Lock();
			NewLineUsers = GroupObject.Users.Add();
			NewLineUsers.User = User;
			GroupObject.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể thêm người sử dụng ""%1"" vào nhóm truy cập ""%2"" do nguyên nhân:
				 |%3';
				 |ru = 'Не удалось добавить пользователя ""%1"" в группу доступа ""%2"" по причине:
				 |%3';
				 |en = 'Cannot add user %1 to the %2 access group. Reason:
				 |%3'; fa = 'Cannot add user %1 to the %2 access group. Reason:
				 |%3';
				 |it = 'Не удалось добавить пользователя ""%1"" в группу доступа ""%2"" по причине:
				 |%3';
				 |pl = 'Cannot add user %1 to the %2 access group. Reason:
				 |%3';
				 |tr = '""%2"" erişim grubuna ""%1"" kullanıcısı şu nedenle eklenemedi:
				 |%3'"), User, Selection.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			FunctionName = "TMAccessManagement.AddUserToGroupWithSpecifiedProfile";
			WriteLogEvent(StrTemplate(NStr(
					"vi = '%1';
					|ru = '%1';
					|en = '%1'; fa = '%1';
					|it = '%1';
					|pl = '%1';
					|tr = '%1'",
				Common.DefaultLanguageCode()),FunctionName), EventLogLevel.Error,
				Metadata.Catalogs.Users, , ErrorMessage);
		EndTry;
	EndIf;

EndProcedure

#EndRegion
