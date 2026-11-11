#Region Public

// Fills an array of structures that will be used for initial filling and
// restoring initial filling of profiles.
//
// Parameters:
//  ProfilesDetails - Array of See AccessManagement.NewAccessGroupProfileDescription
//  ParametersOfUpdate - Structure:
//   * UpdateModifiedProfiles - Boolean - the initial value is True.
//   * DenyProfilesChange - Boolean - the initial value is True.
//       If set to False, then the supplied profiles can not only be viewed, but also edited.
//   * UpdatingAccessGroups     - Boolean - the initial value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean - the initial value is False.
//       If set to True, the value settings made by the administrator for
//       the type of access that was removed from the profile will also be removed from the access groups.
Procedure FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export

	NonCurrentAssets.FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	
#Region Profiles_Description_Accounting_Of_Production
	// Profile folder "Production".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "Production";
	FolderDescription_.Id = "be8dcb77-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Sản xuất';
			|ru = 'Производство';
			|en = 'Production'; fa = 'تولید';
			|it = 'Produzione';
			|pl = 'Production';
			|tr = 'Üretim'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	AddLocalDispatcherProfile(ProfilesDetails);
	AddProfileTechnologist(ProfilesDetails);
	AddProductionEconomistProfile(ProfilesDetails);
	AddProductionManagerProfileOnSide(ProfilesDetails);
	AddProductionPlanningParticipantProfile(ProfilesDetails);
#EndRegion
#Region Profiles_Description_Budgeting
	// The "Budgeting" profile folder.
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "Budgeting";
	FolderDescription_.Id = "05de7c1f-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Lập ngân sách';
			|ru = 'Бюджетирование';
			|en = 'Budgeting'; fa = 'بودجه‌بندی';
			|it = 'Budgeting';
			|pl = 'Budgeting';
			|tr = 'Bütçeleme'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);

	AddBudgetModelAdministratorProfile(ProfilesDetails);
	AddBudgetProcessExecutorProfile(ProfilesDetails);
	AddBudgetingControllerProfile(ProfilesDetails);
	AddBudgetingCoordinatorProfile(ProfilesDetails);
	AddProfileManageLimitsBasedOnBudgetingData(ProfilesDetails);
#EndRegion
	AddProfileCheckingFinancialDocuments(ProfilesDetails);
	AddProfileSettingUpVerificationOfFinancialDocuments(ProfilesDetails);
	
	AccessManagementLocalization.AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);

EndProcedure

#EndRegion

#Region Private

#Region Overall

// Utility function. Made export for the convenience of implementers.
//
Procedure AddRequiredRolesToYourProfile(ProfileDetails) Export
	
	TMAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	
EndProcedure

#EndRegion

#Region ProductionAccounting

Procedure AddLocalDispatcherProfile(ProfilesDetails)

	// Profile "Local Production Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "LocalDispatcher";
	ProfileDetails.Id = "2c1871fb-5fef-408d-adf8-4edcb6ab6c5c";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Giám đốc sản xuất địa phương';
										|ru = 'Локальный диспетчер производства';
										|en = 'Local production dispatcher'; fa = 'Local production dispatcher';
										|it = 'Controllore locale di produzione';
										|pl = 'Lokalny menedżer produkcji';
										|tr = 'Yerel üretim planlayıcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Roles to elementary functions.
	AddLocalDispatcherRoles(ProfileDetails);
	
	// KI
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Vùng trách nhiệm là một hoặc một số công đoạn sản xuất.
											|Theo hồ sơ, cần thực hiện các nhiệm vụ sau:
											|1. lập các tờ lộ trình theo lịch biểu sản xuất;
											|2. quản lý các sai lệch nhỏ trong một công đoạn;
											|3. điều chỉnh thành phần của các thao tác kỹ thuật trong một công đoạn;
											|4. điều chỉnh các tài nguyên được sử dụng trong công đoạn;
											|5. phân tích trực tuyến mức tải thiết bị và khả năng sẵn có của các nguồn lực khi thực hiện một công đoạn;
											|6. phân tích sự sẵn có của hàng hóa và vật tư trong kho trung tâm và trong kho phân xưởng;
											|7. lập giấy đề nghị điều chuyển từ kho trung tâm;
											|8. nhập dữ liệu kiểm kê SXDD;
											|9. thông báo cho Điều phối viên chính về sự xuất hiện của các sai lệch toàn cục.';
											|ru = 'Зона ответственности - один или несколько этапов производства.
											|Под профилем выполняются задачи:
											|1. формирование маршрутных листов по графику производства;
											|2. управление незначительными отклонениями внутри этапа;
											|3. корректировка состава технологических операций внутри этапа;
											|4. корректировка используемых ресурсов внутри этапа;
											|5. оперативный анализ загрузки оборудования и наличия ресурсов при выполнении этапа;
											|6. анализ наличия ТМЦ на центральных складах и в цеховой кладовой;
											|7. формирование заявок на перемещение с центральных складов;
											|8. ввод данных инвентаризации НЗП;
											|9. уведомление Главного диспетчера о возникновении глобальных отклонений.';
											|en = 'Responsibility area — one or several production stages. 
											|Use this profile to:
											|1. Generate operation sheets according to the production schedule; 
											|2. Manage minor variances within the stage; 
											|3. Adjust manufacturing operations within the stage; 
											|4. Adjust resource usage within the stage; 
											|5. Perform real-time analysis of equipment load and resource availability during stage execution; 
											|6. Perform analysis of inventory availability in the central warehouses and in the shop floor stockroom; 
											|7. Generate requests for transfer from the central warehouses; 
											|8. Enter WIP inventory count data; 
											|9. Notify the Chief Production Scheduler of global variances.'; fa = 'Responsibility area — one or several production stages. 
											|Use this profile to:
											|1. Generate operation sheets according to the production schedule; 
											|2. Manage minor variances within the stage; 
											|3. Adjust manufacturing operations within the stage; 
											|4. Adjust resource usage within the stage; 
											|5. Perform real-time analysis of equipment load and resource availability during stage execution; 
											|6. Perform analysis of inventory availability in the central warehouses and in the shop floor stockroom; 
											|7. Generate requests for transfer from the central warehouses; 
											|8. Enter WIP inventory count data; 
											|9. Notify the Chief Production Scheduler of global variances.';
											|it = 'Area di responsabilità: una o più fasi di produzione.
											| Sotto il profilo vengono eseguite le attività: 
											|1. formazione di fogli di lavorazione del programma di produzione;
											| 2. gestione delle deviazioni minori all''interno della fase;
											|3. adeguamento della composizione delle operazioni tecnologiche all''interno della fase;
											| 4. adeguamento delle risorse utilizzate durante la fase;
											| 5. analisi operativa del carico di attrezzature e della disponibilità di risorse durante l''esecuzione della fase;
											| 6. analisi della presenza di merci e materiali nei magazzini centrali e altri;
											| 7. Formazione di domande di trasferimento dai magazzini centrali;
											| 8. inserimento dei dati di inventario dei lavori in corso;
											| 9. notifica al capo controllore circa il verificarsi di deviazioni globali.';
											|pl = 'Zakres odpowiedzialności - jeden lub kilka etapów produkcji.
											|Pod profilem wykonywane są zadania:
											|1. kształtowanie listów przewozowych zgodnie z harmonogramem produkcji;
											|2. zarządzanie niewielkim odchyleniem w środku etapu;
											|3. korekta składu operacji technologicznych wewnątrz etapu;
											|4. dostosowanie wykorzystywanych zasobów wewnątrz etapu;
											|5. analizy operacyjna, załadunek sprzętu i dostępności zasobów w kroku;
											|6. analiza dostępności majątku materiału w centralnych magazynach i w magazynach spiżarni;
											|7. tworzenie wniosków o przeniesienie z centralnych magazynów;
											|8. wprowadzanie danych inwentaryzacyjnych RWT;
											|9. powiadomienie Głównego menedżera o wystąpieniu globalnych odchyleń.';
											|tr = 'Sorumluluk alanı - üretimin bir veya daha fazla aşaması.
											|Profil altında aşağıdaki görevler gerçekleştirilir:
											|1. üretim programına göre işlem listelerinin oluşturulması;
											|2. aşama içindeki küçük sapmaların yönetilmesi;
											|3. aşama içindeki teknolojik operasyonların bileşiminin düzeltilmesi;
											|4. aşamada kullanılan kaynakların düzeltilmesi;
											|5. aşamanın gerçekleştirilmesi sırasında ekipman kullanımının ve kaynak kullanılabilirliğinin operasyonel analizleri;
											|6. merkezi ambarlarda ve atölye deposundaki stok mevcudiyetinin analiz edilmesi;
											|7. merkezi ambarlardan hareket için siparişlerin oluşturulması;
											|8. TMÜ fiziksel stok sayımları verilerinin girişi;
											|9. küresel sapmaların meydana geldiğinin baş sevkiyat görevlisine bildirilmesi.'");

	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileTechnologist(ProfilesDetails)
	
	// Profile "Technologist".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Technologist";
	ProfileDetails.Id = "fd7b587b-ad0a-486e-9512-ad99447c8b89";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Công nghệ';
										|ru = 'Технолог';
										|en = 'Technologist'; fa = 'Technologist';
										|it = 'Tecnologo';
										|pl = 'Technologist';
										|tr = 'Teknoloji uzmanı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ProductionUseInProductsNavigationPanel");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadTeams");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSites");
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditRouteSheets");
	ProfileDetails.Roles.Add("AddEditTechnologicalProcesses");
	ProfileDetails.Roles.Add("AddEditBillOfMaterials");
	ProfileDetails.Roles.Add("AddEditItems");
	ProfileDetails.Roles.Add("AddEditItemsClassifiersAndSettings");
	ProfileDetails.Roles.Add("AddEditLabelsTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("AddEditAdditionalAttributesAndInfo");

	// Documents, reading.
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");

	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditEngineeringChangeOrders");
	ProfileDetails.Roles.Add("AddAndEditApprovalOfEngineeringChangeOrders");
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");


	// Registers, adding change.
	ProfileDetails.Roles.Add("AddEditMainRouteSheets");
	// Processing, reports.
	ProfileDetails.Roles.Add("UseBOMsTree");

	// KI
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");

	AccessManagementLocalization.AddTechnologistRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Trong hồ sơ có các nhiệm vụ sau được thực hiện:
	|1. phân tích các quy trình công nghệ đang có, hoàn thiện và phát triển các quy trình công nghệ mới;
	|2. tính toán tiêu hao nguyên vật liệu;
	|3. phát triển các tài liệu kỹ thuật (tiêu chuẩn, hướng dẫn, tờ lộ trình kỹ thuật...);
	|4. phát triển các nhiệm vụ kỹ thuật để thiết kế và sản xuất thiết bị;
	|5. tiến hành thử nghiệm các quy trình công nghệ mới;
	|6. xác định những khiếm khuyết, bất thường khi thiết bị làm việc trên dây chuyền công nghệ (mới và có sẵn), phân tích nguyên nhân và khắc phục;
	|7. kiểm soát việc tuân thủ công nghệ trong quy trình sản xuất và vận hành máy móc.';
	|ru = 'Под профилем выполняются задачи:
	|1. анализ существующих, доработка и разработка новых технологических процессов;
	|2. расчет расходования сырья и материалов;
	|3. разработка технологической документации (технологических нормативов, инструкций, маршрутных карт и др.);
	|4. разработка технических заданий на проектирование и производство оборудования;
	|5. проведение экспериментальных работ по освоению новых технологических процессов;
	|6. выявление брака, нарушений при работе оборудования на технологических линиях (новых и существующих), анализ причин и их устранение;
	|7. контроль соблюдения технологии производственного процесса и эксплуатации оборудования.';
	|en = 'Use this profile to:
	|1. Develop, analyze, and enhance the technological processes; 
	|2. Calculate consumption of raw and consumable materials; 
	|3. Develop technological documentation (standards, instructions, route sheets, etc.); 
	|4. Develop statements of work for equipment design and manufacturing; 
	|5. Carry out experimental works on developing new technological processes; 
	|6. Identify nonconformities, production line equipment failures (both new and prior), analyze and eliminate their causes; 
	|7. Control compliance of the production process technology and equipment operation.'; fa = 'Use this profile to:
	|1. Develop, analyze, and enhance the technological processes; 
	|2. Calculate consumption of raw and consumable materials; 
	|3. Develop technological documentation (standards, instructions, route sheets, etc.); 
	|4. Develop statements of work for equipment design and manufacturing; 
	|5. Carry out experimental works on developing new technological processes; 
	|6. Identify nonconformities, production line equipment failures (both new and prior), analyze and eliminate their causes; 
	|7. Control compliance of the production process technology and equipment operation.';
	|it = 'Sotto il profilo vengono eseguite le attività:
	| 1. analisi delllr, delle risorse esistenti, perfezionamento e sviluppo di nuovi processi tecnologici;
	| 2. calcolo del consumo di materie prime e materiali;
	| 3. sviluppo della documentazione tecnologica (standard tecnologici, istruzioni, carte di lavorazione, ecc.);
	| 4. sviluppo di specifiche tecniche per la progettazione e la fabbricazione di apparecchiature;
	| 5. conduzione di lavori sperimentali sullo sviluppo di nuovi processi tecnologici;
	| 6. individuazione di difetti, violazioni nel funzionamento di apparecchiature su linee tecnologiche (nuove ed esistenti), analisi delle cause e loro eliminazione;
	| 7. controllo del rispetto della tecnologia del processo di produzione e del funzionamento delle apparecchiature.';
	|pl = 'Pod profilem wykonywane są zadania:
	|1. analiza istniejących, modernizacja i rozwój nowych procesów technologicznych;
	|2. obliczenie zużycia surowców i materiałów;
	|3. opracowanie dokumentacji technologicznej (technologiczne, normy, instrukcje, karty technologiczne, itp.);
	|4. opracowanie technicznych zadań na projektowanie i produkcja sprzętu;
	|5. przeprowadzenie eksperymentalnych prac w zakresie rozwoju nowych procesów technologicznych;
	|6. określenie wad, nieprawidłowości w pracy urządzeń na liniach technologicznych (nowych i istniejących), analiza przyczyn i ich rozwiązywanie;
	|7. kontrola przestrzegania technologii procesu produkcji i obsługi sprzętu.';
	|tr = 'Profil altında aşağıdaki görevler gerçekleştirilir:
	|1. mevcut teknolojik süreçlerin analiz edilmesi, işlenmesi ve yeni teknolojik süreçlerin geliştirilmesi;
	|2. hammadde ve sarf malzeme giderlerinin hesaplanması;
	|3. teknolojik dokümantasyonun geliştirilmesi (teknolojik standartlar, talimatlar, rotalar, vb;);
	|4. ekipman tasarımı ve üretimi için teknik görevlerin geliştirilmesi;
	|5. yeni teknolojik süreçlerin geliştirilmesi üzerine deneysel çalışmalar yürütmek;
	|6. teknolojik hatlardaki (yeni ve mevcut) ekipmanın çalışmasındaki kusurların, düzensizliklerin belirlenmesi, nedenlerinin analizi ve ortadan kaldırılması;
	|7. üretim süreci teknolojisine ve ekipman işletimine uyum kontrolü.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProductionManagerProfileOnSide(ProfilesDetails)
	
	// Profile "Production Manager on the side".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ManagerResponsibleForThirdPartyProduction";
	ProfileDetails.Id = "7387da7a-e932-11e2-a832-c86000df10d3";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Giám đốc sản xuất gia công';
										|ru = 'Менеджер по производству на стороне';
										|en = 'Third party production officer'; fa = 'Third party production officer';
										|it = 'Manager di produzione esterna';
										|pl = 'Kierownik ds produkcji na stronie';
										|tr = 'Fason üretim yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	///////////////////////////////////////////////////////////////////////
	// Reference books, reading.
	
	ProfileDetails.Roles.Add("ReadOpportunities");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadProductionLots");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadReasonsForProductionCancellation");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadTechnologicalProcesses");
	///////////////////////////////////////////////////////////////////////
	// Directories, adding changes.
	
	ProfileDetails.Roles.Add("AddEditVehicles");
	ProfileDetails.Roles.Add("AddEditCounterpartyContracts");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	
	///////////////////////////////////////////////////////////////////////
	// Registers, reading.
	
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadRemainingTransferredReturnablePackaging");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfImportDocuments");
	ProfileDetails.Roles.Add("ReadBalanceOrdersOfMaterialsInProduction");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");
	ProfileDetails.Roles.Add("ReadPlannedCosts");
	///////////////////////////////////////////////////////////////////////
	// Documents, reading.
	
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadBookingDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadPaymentRequests");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceIntercompanyDocuments");
	ProfileDetails.Roles.Add("ReadIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadVendorInvoiceServicesAndAssets");
	ProfileDetails.Roles.Add("ReadDeferredExpenseAllocations");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadOfStandardCostEstimates");
	// Reading data for input based on the giver's documents
	ProfileDetails.Roles.Add("ReadGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("ReadReportsOnWriteOffOfVMI");
	ProfileDetails.Roles.Add("ReadRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	
	///////////////////////////////////////////////////////////////////////
	// Documents, adding changes.
	
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportAfterTransferToSubcontractor");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportAfterReceiptFromSubcontractor");
	ProfileDetails.Roles.Add("AddEditIssuedLettersOfAuthority");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedByCustodian");
	ProfileDetails.Roles.Add("AddEditTollingOrders2_5");
	ProfileDetails.Roles.Add("AddEditDebitNotes");
	ProfileDetails.Roles.Add("AddEditStockSurplusOfShippedGoods");
	ProfileDetails.Roles.Add("AddEditShippedGoodsWriteOffs");
	ProfileDetails.Roles.Add("AddEditSubcontractorReports2_5");
	ProfileDetails.Roles.Add("AddEditOfGoodsTransferToBailee");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsRegrading");
	ProfileDetails.Roles.Add("AddEditCustodianGoodsDamage");
	ProfileDetails.Roles.Add("AddEditUninvoicedReceiptFromCustodian");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditProductionStages2_2");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditApplicationsForGoodsImport");
	
	///////////////////////////////////////////////////////////////////////
	// Processing, reports.
	ProfileDetails.Roles.Add("UseOfDemandFulfillment");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("ReportsOfProductionByThirdParty2_5");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewOfStepsOfPaymentToVendor");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseWorkplaceTollingOrders");
	///////////////////////////////////////////////////////////////////////
	// Visible subsystems of CI
	
	ProfileDetails.Roles.Add("SubsystemSales");
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SalesSectionReceiptForTolling");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	ProfileDetails.Roles.Add("QualityControlSubsystem");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	
	///////////////////////////////////////////////////////////////////////
	// Types of access
	
	ProfileDetails.AccessKinds.Add("TypesOfPrices",							"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups",					"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals",				"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups",				"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies",						"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses",							"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices",							"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments",					"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions",			"Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies",	"Predefined");
	
	// H.O. of the transmission documents for the response. storage, contracts of counterparties
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromProcessingCompany2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfGoodsByToller");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.SubcontractorReportAdjustment");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.MisgradingOfGoodsAtToller");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.DamageAtToller");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReceiptFromToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProductionByToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.GoodsWriteOffAtToller");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TollManufacturing2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.Subcontracting2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnToMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReportToMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfProviderGoods");
	// Access values by types of grounds for acts of discrepancies
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor");
	
	///////////////////////////////////////////////////////////////////////
	// Additional rights.
	
	ProfileDetails.Roles.Add("VarianceFromSalesTermsAndConditions");
	ProfileDetails.Roles.Add("VarianceFromPurchaseConditions");
	ProfileDetails.Roles.Add("AddEditObjectPrintSettings");
	ProfileDetails.Roles.Add("SaveObjectPrintSettingsByDefault");
	ProfileDetails.Roles.Add("ChangePurchaseDocumentRate");
	
	AccessManagementLocalization.AddProductionManagerRolesOnSide(ProfileDetails);
	
	///////////////////////////////////////////////////////////////////////
	// description of the supplied profile.
	
	ProfileDetails.LongDesc =
		NStr("vi = 'Theo hồ sơ có các nhiệm vụ sau được thực hiện:
					|1. Lập đơn hàng dành cho người nhận gia công;
					|2. Phản ánh việc tiếp nhận từ người nhận gia công và chuyển giao cho người nhận gia công;
					|3. Lập bảng kê của người nhận gia công về việc thực hiện dịch vụ gia công.';
					|ru = 'Под профилем выполняются задачи:
					|1. Оформление заказов переработчикам;
					|2. Отражения поступлений от переработчиков и передач переработчикам;
					|3. Оформление отчетов переработчиков о выполнении услуг по переработке.';
					|en = 'The following tasks are performed under the profile:
					|1. Generation of subcontracting purchase orders.
					|2. Recording of subcontractor receipts and transfers.
					|3. Generation of ""Subcontracting services notifications received"" on tolling service provision.'; fa = 'The following tasks are performed under the profile:
					|1. Generation of subcontracting purchase orders.
					|2. Recording of subcontractor receipts and transfers.
					|3. Generation of ""Subcontracting services notifications received"" on tolling service provision.';
					|it = 'Sotto il profilo vengono eseguite le attivita: 
					|1. Formalizzazione degli ordini ai processori; 
					|2. Proiezione delle entrate dai processori e dei trasferimenti ai processori; 
					|3. Formalizzazione dei report dei processori circa l''esecuzione dei servizi di elaborazione';
					|pl = 'Pod profilem wykonywane są zadania:
					|1. Dokonywanie zamówień do przetwórców;
					|2. Odbicia wpływów od podmiotów zajmujących się przetwórstwem i przekazów przetwórcom;
					|3. Sporządzenie raportów przetwórców o wykonywaniu usług przetwórstwa.';
					|tr = 'Profil altında aşağıdaki görevler gerçekleştirilir:
					|1. Alınan fason satın alma siparişinin düzenlenmesi;
					|2. Alınan fason makbuzların ve fasonlara yapılan transferlerin yansımaları;
					|3. Fason hizmetlerinin performansına ilişkin ""Alınan fason üretici hizmetleri bildirimi""ni oluşturma.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddLocalDispatcherRoles(ProfileDetails) Export
	ProfileDetails.Roles.Add("StageDispatching");
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ProductionUseInProductsNavigationPanel");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadTeams");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadProductionLots");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonForCancellationOfClientsOrders");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ReadMESParameters");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadTechnologicalProcesses");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	ProfileDetails.Roles.Add("ReadDefects");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadAttachedFilesRMDocuments");
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadManufacturingLaborCosts");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadCostAllocationSettings");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("ReadWorkCenterRMActivities");
	ProfileDetails.Roles.Add("ReadProductionCostLots");
	ProfileDetails.Roles.Add("ReadRMActivities");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfTransferOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfAssemblyOrders");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadIndicatorValuesToAllocateCosts");
	ProfileDetails.Roles.Add("ReadEmployeeActivityRates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadBalanceOrdersOfMaterialsInProduction");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadPlannedCosts");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadWorkCenterAvailability");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");

	// Documents, reading.
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5WithoutViewing");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5WithoutViewing");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsFromCustodian");
	ProfileDetails.Roles.Add("ReadGoodsReceiptsFromCustomers");
	ProfileDetails.Roles.Add("ReadOfStandardCostEstimates");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadRMOrders");
	ProfileDetails.Roles.Add("ReadRMOrders");
	ProfileDetails.Roles.Add("ReadWorkCenterSchedules");
	
	ProfileDetails.Roles.Add("ReadEngineeringChangeOrders");

	// Reference books, appendix.
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("AddEditReasonsForProductionStageExecutionDelays");
	ProfileDetails.Roles.Add("AddEditReasonsForProductionCancellation");
	ProfileDetails.Roles.Add("AddEditMESParameters");
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditWorkOutput");
	ProfileDetails.Roles.Add("AddEditInternalAcceptanceCertificates");
	ProfileDetails.Roles.Add("AddEditMovementsOfProductsAndMaterials");
	ProfileDetails.Roles.Add("AddEditBackflushProduction");
	ProfileDetails.Roles.Add("AddEditRecyclableWasteAllocation");
	ProfileDetails.Roles.Add("AddEditOrdersForMaterialsForProduction");
	
	ProfileDetails.Roles.Add("AddEditProductionStages2_2");
	ProfileDetails.Roles.Add("AddEditProductionOperations2_2");
	ProfileDetails.Roles.Add("AddEditShiftTasks");
	
	// Registers, adding change.
	ProfileDetails.Roles.Add("AddEditProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("AddEditOfAccessibilityForWorkSchedule");
	// Processing, reports.
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("LocalDispatcherSReports");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("UseDemandFulfillmentParameters");
	ProfileDetails.Roles.Add("UseProductionDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseOfProductionWithoutOrdersRegistration");
	ProfileDetails.Roles.Add("ViewOfOrdersGenerationByPlansDistributionAndTransfer");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfOrderOnTransferToProductionAccordingToPlan");
	ProfileDetails.Roles.Add("UseDataProcessorGenerateProductionStages");
	ProfileDetails.Roles.Add("UseDataProcessorGenerateProductionOrderTransfers");
	ProfileDetails.Roles.Add("UseExecuteProductionStages");
	ProductionManagementWhenPlanningServer.AddLocalDispatcherRoles(ProfileDetails);
	///////////////////////////////////////////////////////////////////////
	// Types of access
	ProfileDetails.AccessKinds.Add("StatusesOfInternalAcceptanceCertificate", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "Predefined");
	
	// H.O. of the transmission documents for the response. storage, contracts of counterparties
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnFromProcessingCompany2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReceiptFromToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProductionByToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5");

	// H.O. of the document movementproduction of materials
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfSemiFinishedProducts");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfProductsFromStoreroom");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfMaterialsToStoreroom");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferOfProductsFromProduction");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.MaterialTransferToProduction");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnOfMaterialsFromProduction");
	AccessManagementLocalization.AddLocalDispatcherRoles(ProfileDetails);
	
EndProcedure

Procedure AddProductionEconomistProfile(ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ManufacturingEconomist";
	ProfileDetails.Id = "86f1e49f-7c35-11e7-9719-708bcd551b9e";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Chuyên gia kinh tế sản xuất';
										|ru = 'Экономист производства';
										|en = 'Manufacturing economist'; fa = 'Manufacturing economist';
										|it = 'Economista di produzione';
										|pl = 'Ekonomista produkcji';
										|tr = 'Üretim ekonomisti'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ProductionUseInProductsNavigationPanel");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadTeams");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadProductionLots");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadIntangibleAssets");
	ProfileDetails.Roles.Add("ReadResearchAndDevelopmentStagesTopics");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadTechnologicalProcesses");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	ProfileDetails.Roles.Add("ReadDefects");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadAttachedFilesRMDocuments");
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadWorkCenterSchedules");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadRMOrders");
	ProfileDetails.Roles.Add("ReadInternalAcceptanceCertificate");
	ProfileDetails.Roles.Add("ReadBackflushProduction");
	ProfileDetails.Roles.Add("ReadRecyclableWasteAllocation");
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
	ProfileDetails.Roles.Add("ReadWorkOutput");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadManufacturingCostAllocation");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	ProfileDetails.Roles.Add("ReadReceiptOfGoodsToWarehouse");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("ReadOfStandardCostEstimates");
	ProfileDetails.Roles.Add("AddEditCostStandards");
	ProfileDetails.Roles.Add("AddEditIntercompanyConsumptionReportsSubcontractingServicesDelivered");
	ProfileDetails.Roles.Add("AddEditStandardCostEstimates");
	ProfileDetails.Roles.Add("AddEditInternalAcceptanceCertificates");
	ProfileDetails.Roles.Add("AddEditBackflushProduction");
	ProfileDetails.Roles.Add("AddEditRecyclableWasteAllocation");
	ProfileDetails.Roles.Add("AddEditOtherCostAllocation");
	ProfileDetails.Roles.Add("AddEditProductionCostsCostAllocation");
	
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditCostAllocationSettings");
	ProfileDetails.Roles.Add("AddEditOfProductCostElements");
	ProfileDetails.Roles.Add("AddEditIncomeExpensesClassifiersAndSettings");
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadWIPLaborCosts");
	ProfileDetails.Roles.Add("ReadOtherWIPExpenses");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	ProfileDetails.Roles.Add("ReadEmployeeActivityRates");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadManufacturingLaborCosts");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadWorkCenterRMActivities");
	ProfileDetails.Roles.Add("ReadProductionCostLots");
	ProfileDetails.Roles.Add("ReadRMActivities");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadIndicatorValuesToAllocateCosts");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	ProfileDetails.Roles.Add("ReadInventoryInOperation");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadWorkCenterAvailability");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("ReadPlannedCosts");
	ProfileDetails.Roles.Add("AddEditPlannedCosts");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");

	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	
	// Registers, adding change.
	ProfileDetails.Roles.Add("AddSettingsOfItemizedExpensesAllocation");
	ProfileDetails.Roles.Add("AddEditValuesOfCostAllocationIndicators");
	ProfileDetails.Roles.Add("AddEditModelsOfCostCreation");
	
	// Processing, reports.
	ProfileDetails.Roles.Add("ProductionEconomistReports");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UseIntercompanyDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseProductionDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseOfProductionWithoutOrdersRegistration");
	ProfileDetails.Roles.Add("ViewPlannedDemandReports");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UseBOMsTree");
	ProfileDetails.Roles.Add("ViewEventLog");
	ProfileDetails.Roles.Add("UseExecuteProductionStages");

	// KI
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SubsystemFinancialResultAndControlling");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfInternalAcceptanceCertificate", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddEconomistProductionRoles(ProfileDetails);
	
	ProfileDetails.LongDesc = NStr("vi = 'Vùng trách nhiệm - lập kế hoạch và phân tích hoạt động sản xuất.
											|Theo hồ sơ cần thực hiện các nhiệm vụ sau:
											|1. quản lý phân bổ chi phí cho giá thành sản phẩm;
											|2. lập và kiểm soát việc thực hiện kế hoạch sản xuất;
											|3. phân tích kế hoạch và thực tế hoạt động sản xuất;
											|4. phân tích giá thành thành phẩm.';
											|ru = 'Зона ответственности - планирование и анализ производственной деятельности.
											|Под профилем выполняются задачи:
											|1. управление распределением расходов на себестоимость продукции;
											|2. формирование и контроль исполнения планов производства;
											|3. план-фактный анализ производственной деятельности;
											|4. анализ себестоимости произведенной продукции.';
											|en = 'Area of responsibility – planning and analysis of production activity.
											|Use this profile to:
											|1. Manage expense allocation on production costs
											|2. Generate and control production plan fulfillment
											|3. Variance analysis of production activity
											|4. Analyze manufactured product cost.'; fa = 'Area of responsibility – planning and analysis of production activity.
											|Use this profile to:
											|1. Manage expense allocation on production costs
											|2. Generate and control production plan fulfillment
											|3. Variance analysis of production activity
											|4. Analyze manufactured product cost.';
											|it = 'Area di responsabilità: pianificazione e analisi delle attività di produzione.
											| Sotto il profilo vengono eseguite le attività:
											| 1. gestire l''allocazione dei costi al costo di produzione;
											| 2. la formazione e il controllo dell''esecuzione dei piani di produzione;
											| 3. analisi del piano reale delle attività produttive; 
											|4. analisi del costo di produzione.';
											|pl = 'Zakres odpowiedzialności - planowanie i analiza działalności produkcyjnej.
											|Pod profilem wykonywane są zadania:
											|1. zarządzanie planowaniem wydatków na koszty własne produkcji;
											|2. tworzenie i kontrola wykonania planów produkcji;
											|3. plan-faktu analiza działalności produkcyjnej;
											|4. analiza kosztów produkcji.';
											|tr = 'Sorumluluk alanı - üretim faaliyetlerinin planlanması ve analizi.
											|Profil altında aşağıdaki görevler gerçekleştirilir:
											|1. maliyetlerin üretim maliyetine dağıtımına yönetmek;
											|2. üretim planlarının oluşturulması ve uygulanması üzerinde kontrol;
											|3. üretim faaliyetlerinin plan-gerçek analizi;
											|4. imal edilen ürünlerin maliyetinin analizi.'");
	
	ProfilesDetails.Add(ProfileDetails);
		
EndProcedure

Procedure AddProductionPlanningParticipantProfile(ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ProductionPlanningParticipant";
	ProfileDetails.Id = "47c3f3e8-f57c-11e9-8805-1831bf523f09";
	ProfileDetails.Parent      = "Planning";
	ProfileDetails.Description  = NStr("vi = 'Thành viên kế hoạch sản xuất';
										|ru = 'Участник планирования производства';
										|en = 'Production planning participant'; fa = 'Production planning participant';
										|it = 'Partecipante della pianificazione di produzione';
										|pl = 'Uczestnik planowania produkcji';
										|tr = 'Üretim planlamasında katılımcı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadProductionPlans");
	ProfileDetails.Roles.Add("ReadOfPlansOfGoodsStock");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditProductionPlans");
	ProfileDetails.Roles.Add("ApprovalOfProductionPlans");
	ProfileDetails.Roles.Add("AddEditPlanOfGoodsStock");
	ProfileDetails.Roles.Add("ApprovalOfPlansOfGoodsStock");
	
	// Registers are read.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	// Reports and processing.
	ProfileDetails.Roles.Add("UseDataProcessorPlanningProcessManagement");
	ProfileDetails.Roles.Add("ViewReportPlansEquilibriumCheck");
	ProfileDetails.Roles.Add("ViewReportProductionPlanFulfillment");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	// Additional roles for reading the feasibility report
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadSubcontractorReports2_5");
	// Additional rights.
	
	//KI
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("SalesOperationsPlanningScenarios", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PlanProfiles","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddRolesForProductionPlanning(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ, tiến hành tạo kế hoạch sản xuất và kiểm soát thực hiện chúng.';
									|ru = 'Под профилем происходит формирование планов производства и контроль их исполнения.';
									|en = 'Generation of production plans and control of their execution is occurred under the profile.'; fa = 'Generation of production plans and control of their execution is occurred under the profile.';
									|it = 'Sotto il profilo avviene la generazione dei piani di produzione e il controllo della loro esecuzione.';
									|pl = 'Dla profilu trwa utworzenie planów produkcji i kontrola ich wykonania.';
									|tr = 'Profilin altında üretim planlarının oluşturulması ve bunların yürütülmesinin kontrolü yer almaktadır.'",
		 Common.DefaultLanguageCode());
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion
#Region Budgeting

Procedure AddBudgetModelAdministratorProfile(ProfilesDetails)
	
	// Profile "Budget Model Administrator".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "BudgetModelAdministrator";
	ProfileDetails.Id = "932703ca-6520-11e6-84c0-c860008a2a34";
	ProfileDetails.Parent      = "Budgeting";
	
	ProfileDetails.Description  = NStr("vi = 'Quản trị viên mô hình ngân sách (tùy chọn)';
										|ru = 'Администратор бюджетной модели (дополнительный)';
										|en = 'Budget model administrator (additional)'; fa = 'Budget model administrator (additional)';
										|it = 'Amministratore del modello di bilancio (aggiuntivo)';
										|pl = 'Administrator budżetowego modelu (dodatkowy)';
										|tr = 'Bütçe modeli yöneticisi (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("ReadBudgetingSettings");
	ProfileDetails.Roles.Add("AddEditBudgetingSettings");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetProcessSettings");
	ProfileDetails.Roles.Add("AddEditBudgetProcessSettings");
	// KI.
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies",   "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users",  "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetTypes",              "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetItemsAndIndicators", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("BudgetingScenarios",  "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung mà được ấn định cho người sử dụng, 
								|thực hiện chỉnh sửa danh mục ngân sách và tùy chỉnh quy trình ngân sách.';
								|ru = 'Дополнительный профиль, который назначается пользователям, 
								|выполняющим редактирование НСИ бюджетов и настроек бюджетного процесса.';
								|en = 'Additional profile assigned to users
								|editing master data of budgets and budget process settings.'; fa = 'Additional profile assigned to users
								|editing master data of budgets and budget process settings.';
								|it = 'Profilo aggiuntivo assegnato agli utenti, 
								|che eseguono la modifica dei dati anagrafici dei bilanci e le impostazioni del processo di bilancio.';
								|pl = 'Dodatkowy profil przypisany użytkownikom, 
								| edytującym normatywne informacje budżetów i ustawień procesu budżetowego.';
								|tr = 'Master Veri bütçelerini ve bütçe süreci ayarlarını 
								|düzenleyen kullanıcılara atanan ek bir profil.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddBudgetProcessExecutorProfile(ProfilesDetails)
	
	// Profile "Executor of the budget process (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "BudgetProcessAssignee";
	ProfileDetails.Id = "932703c8-6520-11e6-84c0-c860008a2a34";
	ProfileDetails.Parent      = "Budgeting";
	ProfileDetails.Description  = NStr("vi = 'Người thực hiện quy trình ngân sách (không bắt buộc)';
										|ru = 'Исполнитель бюджетного процесса (дополнительный)';
										|en = 'Budget executor (additional)'; fa = 'Budget executor (additional)';
										|it = 'Esecutore del processo di bilancio (aggiuntivo)';
										|pl = 'Wykonawca budżetowego modelu (dodatkowy)';
										|tr = 'Bütçe sürecinin yürütücüsü (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("ReadBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetingSettings");
	ProfileDetails.Roles.Add("AddEditBudgets");
	ProfileDetails.Roles.Add("AddAndEditBalanceOfEstimates");
	ProfileDetails.Roles.Add("ApprovalOfBudgets");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetProcessSettings");
	ProfileDetails.Roles.Add("ReadPerformBudgetTasks");
	ProfileDetails.Roles.Add("ReadJobsForPostingInBudgeting");
	ProfileDetails.Roles.Add("ReadBudgetingProcesses");
	ProfileDetails.Roles.Add("ReadActualBudgetingData");
	// KI.
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	//Pricesreferences
	 ProfileDetails.Roles.Add("ReadItemsPrices");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies",   "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users",  "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetTypes",              "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetItemsAndIndicators", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("BudgetingScenarios",  "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được ấn định cho người sử dụng thực hiện nhiệm vụ nhập dữ liệu lập ngân sách. 
								|Khi thay đổi và nhập ngân sách, sẽ phân tích có nhiệm vụ ngân sách, nếu bật quản lý quy trình ngân sách.';
								|ru = 'Дополнительный профиль, который назначается пользователям, выполняющим задачи ввода данных бюджетирования. 
								|При изменении и вводе бюджетов, анализируется наличие бюджетных задач, если включено управление бюджетным процессом.';
								|en = 'Additional profile assigned to users performing tasks of budgeting data input. 
								|Presence of budget tasks is analyzed during budget change or input if budget process management is enabled.'; fa = 'Additional profile assigned to users performing tasks of budgeting data input. 
								|Presence of budget tasks is analyzed during budget change or input if budget process management is enabled.';
								|it = 'Profilo aggiuntivo assegnato agli utenti che eseguono il task di inserimento dei dati di budgeting. 
								| Durante le modifiche e l''inserimento dei bilanci, viene analizzata la presenza di task di bilancio, se la gestione del processo di bilancio è inclusa.';
								|pl = 'Dodatkowy profil, który jest przypisany do użytkowników, którzy realizują zadania wprowadzania danych budżetowania. 
								|Po zmianie i wprowadzania budżetów, analizowany pod kątem budżetowych zadań, jeśli jest włączone zarządzanie procesem budżetowym.';
								|tr = 'Bütçeleme veri girişi görevlerini gerçekleştiren kullanıcılara atanan ek bir profil. 
								|Bütçeler değiştirildiğinde ve girildiğinde, bütçe yönetimi etkinleştirilmişse bütçe görevlerinin kullanılabilirliği analiz edilir.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddBudgetingControllerProfile(ProfilesDetails)
	
	// Profile "Budgeting Controller (optional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "BudgetController";
	ProfileDetails.Id = "932703c7-6520-11e6-84c0-c860008a2a34";
	ProfileDetails.Parent      = "Budgeting";
	ProfileDetails.Description  = NStr("vi = 'Kiểm soát ngân sách (tùy chọn)';
										|ru = 'Контролер бюджетирования (дополнительный)';
										|en = 'Budget controller (additional)'; fa = 'Budget controller (additional)';
										|it = 'Controllore budgeting (aggiuntivo)';
										|pl = 'Kontroler budżetowania (dodatkowy)';
										|tr = 'Bütçeleme kontrolörü (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("ReadBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetingSettings");
	ProfileDetails.Roles.Add("GenerateBudgetReports");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetProcessSettings");
	ProfileDetails.Roles.Add("AddEditExecuteBudgetTasks");
	ProfileDetails.Roles.Add("ReadJobsForPostingInBudgeting");
	ProfileDetails.Roles.Add("ReadBudgetingProcesses");
	ProfileDetails.Roles.Add("ReadActualBudgetingData");
	// KI.
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies",   "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users",  "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetTypes",              "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetItemsAndIndicators", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("BudgetingScenarios",  "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung mà được chỉ định cho người dùng để xem ngân sách và tạo báo cáo.';
									|ru = 'Дополнительный профиль, который назначается пользователям для просмотра бюджетов и формирования отчетов.';
									|en = 'Additional profile assigned to users to view budgets and generate reports.'; fa = 'Additional profile assigned to users to view budgets and generate reports.';
									|it = 'Profilo aggiuntivo assegnato agli utente per la visualizzazione dei bilanci e la creazione di report.';
									|pl = 'Dodatkowy profil, który jest przypisany użytkownikom, celem podglądu budżetów i tworzenia raportów.';
									|tr = 'Bütçeleri görüntülemek ve raporlar oluşturmak için kullanıcılara atanan isteğe bağlı ek profil.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddBudgetingCoordinatorProfile(ProfilesDetails)
	
	// Profile "Budgeting Coordinator (optional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "BudgetingCoordinator";
	ProfileDetails.Id = "932703c9-6520-11e6-84c0-c860008a2a34";
	ProfileDetails.Parent      = "Budgeting";
	ProfileDetails.Description  = NStr("vi = 'Điều phối viên ngân sách (không bắt buộc)';
										|ru = 'Координатор бюджетирования (дополнительный)';
										|en = 'Budget coordinator (additional)'; fa = 'Budget coordinator (additional)';
										|it = 'Coordiatore di budgeting (aggiuntivo)';
										|pl = 'Koordynator budżetowania (dodatkowy)';
										|tr = 'Bütçe koordinatörü (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("ReadBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetingSettings");
	ProfileDetails.Roles.Add("AddEditBudgets");
	ProfileDetails.Roles.Add("AddEditNonFinancialItemValues");
	ProfileDetails.Roles.Add("AddAndEditBalanceOfEstimates");
	ProfileDetails.Roles.Add("ApprovalOfBudgets");
	ProfileDetails.Roles.Add("EditingBudgetingDataOutsideClosingDates");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetProcessSettings");
	ProfileDetails.Roles.Add("AddEditExecuteBudgetTasks");
	ProfileDetails.Roles.Add("ViewReportExecutionOfJobsOfBudgetProcess");
	ProfileDetails.Roles.Add("ViewReportBudgetingProcessChart");
	ProfileDetails.Roles.Add("ReadJobsForPostingInBudgeting");
	ProfileDetails.Roles.Add("AddEditBudgetingProcesses");
	ProfileDetails.Roles.Add("ReadActualBudgetingData");
	ProfileDetails.Roles.Add("EditingBudgetingDataOutsideProcesses");
	ProfileDetails.Roles.Add("EditingBudgetTasksOutsideProcesses");
	// KI.
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies",   "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users",  "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetTypes",              "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetItemsAndIndicators", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("BudgetingScenarios",  "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được ấn định cho người sử dụng thực hiện nhiệm vụ nhập dữ liệu lập ngân sách 
								|và quản lý quy trình ngân sách. Có thể thay đổi ngân sách mà không cần nhiệm vụ ngân sách và không tính đến ngày cấm thay đổi ngân sách';
								|ru = 'Дополнительный профиль, который назначается пользователям, выполняющим задачи ввода данных бюджетирования 
								|и управления бюджетным процессом. Изменения бюджетов возможны без наличия бюджетных задач и без учета дат запрета изменения данных';
								|en = 'Additional profile assigned to users performing tasks of budgeting data input
								|and budget process management. Budgets can be changed without budget tasks and without taking into account period-end closing dates'; fa = 'Additional profile assigned to users performing tasks of budgeting data input
								|and budget process management. Budgets can be changed without budget tasks and without taking into account period-end closing dates';
								|it = 'Profilo aggiuntivo assegnato agli utenti che eseguono task di inserimento di dati di budgeting
								| e gestione del processo di bilancio. Le modifiche di bilancio sono possibili senza la presenza di task di bilancio e indipendentemente dalle date di divieto di modifica dei dati';
								|pl = 'Dodatkowy profil, który jest przypisany do użytkowników, którzy realizują zadania wprowadzania danych, budżetowania 
								|i zarządzania procesem budżetowym. Zmiany budżetów możliwe bez posiadania budżetowych zadań i bez uwzględnienia dat zakazu zmiany danych';
								|tr = 'Bütçeleme ve bütçe yönetimi veri girişi görevlerini yerine getiren kullanıcılara atanan ek bir profil. Bütçeler, bütçe görevleri olmadan 
								|ve veri değişikliği yasağı tarihleri dikkate alınmadan değiştirilebilir'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileManageLimitsBasedOnBudgetingData(ProfilesDetails)
	
	// Profile "Managing limits based on budgeting data (optional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ManagingLimitsBasedOnBudgetingData";
	ProfileDetails.Id = "17e62c67-8973-11e6-b5a9-c860008a2a34";
	ProfileDetails.Parent      = "Budgeting";
	ProfileDetails.Description  = NStr("vi = 'Quản lý hạn mức ngân sách (tùy chọn)';
										|ru = 'Управление лимитами по данным бюджетирования (дополнительный)';
										|en = 'Management of limits for budgeting data (additional)'; fa = 'Management of limits for budgeting data (additional)';
										|it = 'Gestione dei limiti per dati di budgeting (aggiuntivo)';
										|pl = 'Zarządzanie limitami według danych budżetowania (dodatkowy)';
										|tr = 'Bütçeleme verilerine dayalı limitlerin yönetimi (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("ReadBudgetingSettings");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	ProfileDetails.Roles.Add("AddEditLimitsForBudgetingData");
	ProfileDetails.Roles.Add("ReadBudgetProcessSettings");
	// KI.
	ProfileDetails.Roles.Add("SubsystemBudgetingAndPlanning");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies",   "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users",  "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetTypes",              "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfBudgetItemsAndIndicators", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("BudgetingScenarios",  "AllDeniedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được gán cho người dùng thực hiện nhiệm vụ đặt quy tắc hạn mức theo dữ liệu ngân sách';
									|ru = 'Дополнительный профиль, который назначается пользователям, выполняющим задачу настройки правил лимитов по данным бюджетирования';
									|en = 'Additional profile assigned to users performing the task of setting up rules for budgeting limits'; fa = 'Additional profile assigned to users performing the task of setting up rules for budgeting limits';
									|it = 'Profilo aggiuntivo assegnato agli utenti che eseguono task di impostazione delle regole dei limiti in base ai dati di budgeting';
									|pl = 'Dodatkowy profil, który jest przypisany do użytkowników, którzy realizują zadania konfigurowania reguł limitów według budżetowania';
									|tr = 'Bütçeleme verileri üzerinde limit kurallarını ayarlama görevini yerine getiren kullanıcılara atanan ek profil'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion
Procedure AddProfileCheckingFinancialDocuments(ProfilesDetails)

	// Profile "Verification of financial documents".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = "a2b75ba9-b01d-11ec-8c70-3c7c3fc28e23";
	ProfileDetails.Name = "VerifyFinancialDocuments";
	ProfileDetails.Description  =
		NStr("vi = 'Kiểm tra chứng từ tài chính (bổ sung)';
			|ru = 'Проверка финансовых документов (дополнительный)';
			|en = 'Check financial documents (additional)'; fa = 'Check financial documents (additional)';
			|it = 'Verifica documenti finanziari (aggiuntivo)';
			|pl = 'Sprawdzenie dokumentów finansowych (dodatkowy)';
			|tr = 'Finansal belgelerin kontrolü (ek)'",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ bổ sung được ấn định cho người sử dụng là người chịu trách nhiệm kiểm tra chứng từ kế toán tài chính.';
			|ru = 'Дополнительный профиль назначается пользователям ответственным за проверку документов финансового учета.';
			|en = 'An additional profile is assigned to users responsible for checking financial accounting documents.'; fa = 'An additional profile is assigned to users responsible for checking financial accounting documents.';
			|it = 'Дополнительный профиль назначается пользователям ответственным за проверку документов финансового учета.';
			|pl = 'An additional profile is assigned to users responsible for checking financial accounting documents.';
			|tr = 'Finansal muhasebe belgelerinin kontrolünden sorumlu kullanıcılara ek profil atanmaktadır.'");
	ProfileDetails.Roles.Add("RightOfChangingDocumentCheckStatuses");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");

	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung đối với hồ sơ ""Kế toán viên""';
									|ru = 'Дополнительный профиль к профилю ""Бухгалтер""';
									|en = 'Additional profile to the ""Accountant"" profile'; fa = 'Additional profile to the ""Accountant"" profile';
									|it = 'Profilo aggiuntivo al profilo ""Contabile""';
									|pl = 'Dodatkowy profil do profilu ""Księgowy""';
									|tr = '""Muhasebeci"" profiline ek profil'");
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileSettingUpVerificationOfFinancialDocuments(ProfilesDetails)

	// Profile "Setting up verification of financial documents".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = "a2b75ba9-b01d-11ec-8c70-3c7c3fc28e24";
	ProfileDetails.Name = "SettingUpVerificationOfFinancialDocuments";
	ProfileDetails.Description  =
		NStr("vi = 'Tùy chỉnh kiểm tra các chứng từ tài chính (bổ sung)';
			|ru = 'Настройка проверки финансовых документов (дополнительный)';
			|en = 'Set up financial document check (additional)'; fa = 'Set up financial document check (additional)';
			|it = 'Настройка проверки финансовых документов (дополнительный)';
			|pl = 'Set up financial document check (additional)';
			|tr = 'Finansal belgelerin kontrol ayarı (ek)'",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("vi = 'Hồ sơ bổ sung được gán cho người sử dụng chịu trách nhiệm tùy chỉnh kiểm tra chứng từ kế toán tài chính.';
			|ru = 'Дополнительный профиль назначается пользователям ответственным за настройку проверки документов финансового учета.';
			|en = 'An additional profile is assigned to users responsible for setting up the financial accounting document check.'; fa = 'An additional profile is assigned to users responsible for setting up the financial accounting document check.';
			|it = 'Дополнительный профиль назначается пользователям ответственным за настройку проверки документов финансового учета.';
			|pl = 'An additional profile is assigned to users responsible for setting up the financial accounting document check.';
			|tr = 'Finansal muhasebe belgelerinin kontrol ayarından sorumlu kullanıcılara ek profil atanmaktadır.'");
	ProfileDetails.Roles.Add("AddEditSettingsOfDocumentCheckExceptions");

	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung cho hồ sơ ""Kế toán viên""';
									|ru = 'Дополнительный профиль к профилю ""Бухгалтер""';
									|en = 'Additional profile to the ""Accountant"" profile'; fa = 'Additional profile to the ""Accountant"" profile';
									|it = 'Profilo aggiuntivo al profilo ""Contabile""';
									|pl = 'Dodatkowy profil do profilu ""Księgowy""';
									|tr = '""Muhasebeci"" profiline ek profil'");
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion
