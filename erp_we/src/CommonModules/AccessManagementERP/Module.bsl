
#Region Public

// Fills an array of structures that will be used for initial filling and restoring the initial filling of profiles.
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

	RMManagement.FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	
#Region Profiles_Description_Accounting_Of_Production
	AddMasterDispatcherProfile(ProfilesDetails);
	AddProductionManagerProfile(ProfilesDetails);
	AddProfileOfManagerForProcessingTollFreeRawMaterials(ProfilesDetails);
	AddOTCControllerProfile(ProfilesDetails);
	AddApprovalOfMaterialReplacementPermits(ProfilesDetails);
#EndRegion
#Region Create_profile_InternationalAccounting
	// Profile folder "International Financial Accounting".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "InternationalFinancialAccounting";
	FolderDescription_.Id = "05de7c39-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Kế toán tài chính quốc tế';
			|ru = 'Международный финансовый учет';
			|en = 'General ledger'; fa = 'دفتر کل';
			|it = 'Rilevazione contabilità internazionale';
			|pl = 'Międzynarodowa ewidencja finansowa';
			|tr = 'Genel muhasebe'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);

	AddInternationalAccountingAnalystProfile(ProfilesDetails);
	AddInternationalAccountingAccountantProfile(ProfilesDetails);
	AddProfileUserReportingInternationalAccounting(ProfilesDetails);
#EndRegion
	AccessManagementLocalization.AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);

EndProcedure

// Complements the profile with required roles.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRequiredRolesToYourProfile(ProfileDetails) Export
	
	CAAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	
EndProcedure

#EndRegion

#Region Private
#Region FinancialAccounting

Procedure AddInternationalAccountingAnalystProfile(ProfilesDetails)
	
	// Profile "International Accounting Analyst (additional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "FinancialAccountingAnalyst";
	ProfileDetails.Id = "a710f198-2e62-4a11-9b0e-40b79ca97aec";
	ProfileDetails.Parent      = "InternationalFinancialAccounting";
	ProfileDetails.Description  = NStr("vi = 'Chỉ số kế toán quốc tế (không bắt buộc)';
										|ru = 'Аналитик международного учета (дополнительный)';
										|en = 'Financial accounting analyst (additional)'; fa = 'Financial accounting analyst (additional)';
										|it = 'Analista di contabilità internazionale (aggiuntivo)';
										|pl = 'Międzynarodowy analityk rachunkowości (dodatkowy)';
										|tr = 'Uluslararası muhasebe boyutu (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("AddEditFinancialAccountingGroups");
	ProfileDetails.Roles.Add("AddEditAnalyticalInventoryGroups");
	ProfileDetails.Roles.Add("SubsystemFinancialAccounting");
	ProfileDetails.Roles.Add("AddEditConfigureFinancialAccounting");
	ProfileDetails.Roles.Add("ReadFinancialAccounting");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	
	AccessManagementLocalization.CompleteInternationalAccountingAnalystProfile(ProfileDetails);
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được ấn định cho người sử dụng để thực hiện các nhiệm vụ sau:
						|1. Tùy chỉnh kế toán quốc tế.
						|2. Tùy chỉnh phản ánh chứng từ vào kế toán quốc tế.
						|3. Nhận báo cáo về dữ liệu kế toán quốc tế.';
						|ru = 'Дополнительный профиль, назначаемый пользователям для выполнения задач:
						|1. Настройка международного учета.
						|2. Настройка отражения документов в международном учете.
						|3. Получение отчетов по данным международного учета.';
						|en = 'Additional profile assigned to users to perform the following tasks:
						|1. Configure financial accounting.
						|2. Configure financial accounting posting.
						|3. Receive reports on financial accounting data.'; fa = 'Additional profile assigned to users to perform the following tasks:
						|1. Configure financial accounting.
						|2. Configure financial accounting posting.
						|3. Receive reports on financial accounting data.';
						|it = 'Profilo aggiuntivo assegnato agli utenti per l''esecuzione dei compiti: 
						| 1. impostazioni della contabilità internazionale. 
						|2. Impostazione di riflessione dei documenti nella contabilità internazionale.
						| 3. Ricezione di report in base ai dati della contabilità internazionale.';
						|pl = 'Dodatkowy profil, możliwość przypisania użytkowników do wykonywania zadań:
						|1. Konfiguracja międzynarodowej ewidencji rachunkowości.
						|2. Regulacja odbicia dokumentów w międzynarodowej ewidencji rachunkowości.
						|3. Uzyskiwanie raportów według danych międzynarodowej ewidencji rachunkowości.';
						|tr = 'Görevlerin gerçekleştirilmesi için kullanıcılara atanan ek profil:
						|1. Uluslararası muhasebe ayarı.
						|2. Belgelerin uluslararası muhasebeye yansıma ayarı.
						|3. Uluslararası muhasebe verilerine göre raporların alınması.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddInternationalAccountingAccountantProfile(ProfilesDetails)
	
	// Profile "Accountant of international accounting".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "FinancialAccountingAccountant";
	ProfileDetails.Id = "55e653bc-b975-48bc-beb5-aa97125cd1ff";
	ProfileDetails.Parent      = "InternationalFinancialAccounting";
	ProfileDetails.Description  = NStr("vi = 'Kế toán quốc tế';
										|ru = 'Бухгалтер международного учета';
										|en = 'Financial accounting accountant'; fa = 'Financial accounting accountant';
										|it = 'Contabile di contabilità internazionale';
										|pl = 'Księgowy międzynarodowej rachunkowości';
										|tr = 'Uluslararası muhasebeci'", Common.DefaultLanguageCode());
	
	TMAccessManagement.AddRequiredRolesToYourProfile(ProfileDetails);
	TMAccessManagement.AddAccountantLocalAccountingRolesToRead(ProfileDetails);
	
	// Visible subsystems of CI
	ProfileDetails.Roles.Add("SubsystemFinancialAccounting");
	
	// International accounting
	ProfileDetails.Roles.Add("AddEditFinancialAccounting");
	ProfileDetails.Roles.Add("ReadFinancialAccountingSetting");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	ProfileDetails.Roles.Add("UseTransactionOfMonthEndClosingDataProcessor");
	ProfileDetails.Roles.Add("ViewOperationalAccountingEntryAnalysisReport");
	
	// Reference books, appendix.
	ProfileDetails.Roles.Add("AddEditFAGroupsInternationalAccounting");
	
	AccessManagementLocalization.CompleteInternationalAccountingAccountantProfile(ProfileDetails);
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ có thực hiện các nhiệm vụ sau:
						|1. Tiến hành kế toán quốc tế.
						|2. Nhận báo cáo về dữ liệu kế toán quốc tế.';
						|ru = 'Под профилем выполняются задачи:
						|1. Ведение международного учета.
						|2. Получение отчетов по данным международного учета.';
						|en = 'The following tasks are performed under the profile:
						|1. Financial accounting.
						|2. Receipt of reports according to the financial accounting data.'; fa = 'The following tasks are performed under the profile:
						|1. Financial accounting.
						|2. Receipt of reports according to the financial accounting data.';
						|it = 'Sotto il profilo vengono eseguiti i task:
						|1. Esecuzione della contabilità internazionale.
						| 2. ricezione di report in base ai dati della contabilità internazionale.';
						|pl = 'W ramach profilu wykonywane są zadania:
						|1. Prowadzenie międzynarodowej ewidencji księgowości.
						|2. Otrzymanie raportów na temat międzynarodowych danych ewidencji księgowych.';
						|tr = 'Profil altında gerçekleştirilen görevler:
						|1. Uluslararası muhasebe kayıtlarının tutulması.
						|2. Uluslararası muhasebe verilerine göre raporların alınması.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileUserReportingInternationalAccounting(ProfilesDetails)
	
	// Profile "International Accounting Reporting User (optional)".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "UserOfFinancialAccountingReports";
	ProfileDetails.Id = "8d2d58eb-0619-4bb9-8f8d-119e01c112ad";
	ProfileDetails.Parent      = "InternationalFinancialAccounting";
	ProfileDetails.Description  = NStr("vi = 'Người dùng IFRS (Tùy chọn)';
										|ru = 'Пользователь отчетности международного учета (дополнительный)';
										|en = 'User of financial accounting reporting (additional)'; fa = 'User of financial accounting reporting (additional)';
										|it = 'Utente della rendicontazione di contabilità internazionale (aggiuntivo)';
										|pl = 'Użytkownik ewidencji międzynarodowej księgowości (dodatkowy)';
										|tr = 'Uluslararası muhasebe raporlama kullanıcısı (ek)'", Common.DefaultLanguageCode());
	
	ProfileDetails.Roles.Add("SubsystemFinancialAccounting");
	ProfileDetails.Roles.Add("ReadFinancialAccounting");
	ProfileDetails.Roles.Add("ReadFinancialAccountingSetting");
	ProfileDetails.Roles.Add("ReadOtherTransactionsGLAccountsSettings");
	
	AccessManagementLocalization.CompleteUserProfileOfInternationalAccountingReporting(ProfileDetails);
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Hồ sơ bổ sung được chỉ định cho người dùng để nhận báo cáo về dữ liệu kế toán quốc tế.';
									|ru = 'Дополнительный профиль, назначаемый пользователям для получения отчетов по данным международного учета.';
									|en = 'Additional profile assigned to users for receipt of reports on financial accounting data.'; fa = 'Additional profile assigned to users for receipt of reports on financial accounting data.';
									|it = 'Profilo aggiuntivo assegnato agli utenti per la ricezione di report in base ai dati della contabilità internazionale.';
									|pl = 'Dodatkowy profil, przypisany użytkownikom do otrzymywania raportów z międzynarodowych danych księgowych.';
									|tr = 'Uluslararası muhasebe verilerine göre rapor alınmasına yönelik kullanıcılara atanan ek profil.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion
#Region ProductionAccounting

Procedure AddMasterDispatcherProfile(ProfilesDetails)
	
	// Description for filling out the profile "Chief Production Manager".
	// Profile "Chief Production Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ChiefDispatcher";
	ProfileDetails.Id = "90a9321f-a088-47f1-afd4-47b8f052ebc1";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Trưởng phòng kế hoạch sản xuất';
										|ru = 'Главный диспетчер производства';
										|en = 'Chief production scheduler'; fa = 'Chief production scheduler';
										|it = 'Il controllore capo della produzione';
										|pl = 'Główny dyspozytor produkcji';
										|tr = 'Üretim baş sevkiyatçısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Roles to elementary functions.
	
	CAAccessManagement.AddLocalDispatcherRoles(ProfileDetails);
	
	ProfileDetails.Roles.Add("ManagementOfProductionOrderQueue");
	ProfileDetails.Roles.Add("ProductionSchedulePlanning2_2");
	ProfileDetails.Roles.Add("SelectArbitraryAssignmentsInProductionStage");
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadItemsOfPartners");
	ProfileDetails.Roles.Add("ReadProductionLots");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryCash");
	ProfileDetails.Roles.Add("ReadOBEntrySalesForPastPeriods");
	ProfileDetails.Roles.Add("ReadOBEntryFinancialInstruments");
	ProfileDetails.Roles.Add("ReadOBEntryOtherExpenses");
	ProfileDetails.Roles.Add("ReadOBEntryOtherAssetsAndLiabilities");
	ProfileDetails.Roles.Add("ReadOBEntryAcquiringContractARAP");
	ProfileDetails.Roles.Add("ReadOBEntryARAPAdvanceHolders");

	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadWorkOutput");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadSalesOrdersRequestsForReturnOfGoodsFromCustomer");
	ProfileDetails.Roles.Add("ReadOfStandardCostEstimates");
	
	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditInternalAcceptanceCertificates");
	ProfileDetails.Roles.Add("AddEditProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("AddEditStandardCostEstimates");
	ProfileDetails.Roles.Add("AddEditBackflushProduction");
	ProfileDetails.Roles.Add("AddEditEngineeringChangeOrders");
	ProfileDetails.Roles.Add("AddEditRecyclableWasteAllocation");
	ProfileDetails.Roles.Add("AddEditProductionCostsCostAllocation");
	ProfileDetails.Roles.Add("AddEditOtherCostAllocation");
	ProfileDetails.Roles.Add("AddEditInventoryAssignmentAdjustmentEntries");
	ProfileDetails.Roles.Add("AdditionalOperationsOfInventoryAssignmentAdjustment");
	ProfileDetails.Roles.Add("AddEditCostStandards");
	
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditEmployeesActivityKinds");
	ProfileDetails.Roles.Add("AddEditBillOfMaterials");
	ProfileDetails.Roles.Add("AddEditWorkCenterStructures");
	ProfileDetails.Roles.Add("AddEditCalendars");
	ProfileDetails.Roles.Add("AddEditPriorities");
	ProfileDetails.Roles.Add("AddEditProductionSites");
	ProfileDetails.Roles.Add("AddEditLogisticParameters");
	ProfileDetails.Roles.Add("AddAndEditProductionStages");
	
	// Registers, adding change.
	ProfileDetails.Roles.Add("AddEditRatesForEmployeeActivities");
	ProfileDetails.Roles.Add("AddEditMainRouteSheets");
	ProfileDetails.Roles.Add("AddEditTechnologicalProcesses");
	ProfileDetails.Roles.Add("AddEditModelsOfCostCreation");
	ProfileDetails.Roles.Add("AddEditProductionStageSchedule2_2");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadWIPLaborCosts");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadInventoryCost");
	ProfileDetails.Roles.Add("ReadItemizedExpenseAllocationSettings");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	
	// Processing, reports.
	ProfileDetails.Roles.Add("AddEditOfAccessibilityForProductionSchedule");
	ProfileDetails.Roles.Add("ChiefDispatcherReports");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UseOfDemandFulfillment");
	ProfileDetails.Roles.Add("UseGenerationOfOrdersForMaterialsAsRequired");
	ProfileDetails.Roles.Add("UseOfProductionWithoutOrdersRegistration");
	ProfileDetails.Roles.Add("UseBOMsTree");
	ProfileDetails.Roles.Add("ViewPlannedDemandReports");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("ViewReportsStageProductionSchedule");
	ProfileDetails.Roles.Add("ViewEventLog");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Planning
	ProfileDetails.Roles.Add("ReadSalesPlans");
	ProfileDetails.Roles.Add("ReadProductionPlans");
	ProfileDetails.Roles.Add("ReadPlanningScenarios");
	ProfileDetails.Roles.Add("UseDataProcessorGenerationOfOrdersOnProductionAccordingToPlan");
	
	// KI
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	
	ProfileDetails.AccessKinds.Add("Companies","AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfInternalAcceptanceCertificate", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddMainDispatcherRoles(ProfileDetails);
	
	ProfileDetails.LongDesc = NStr("vi = 'Trách nhiệm - tổng hợp các đơn hàng sản xuất,
											|quản lý tất cả vòng đời sản xuất nói chung.
											|Theo hồ sơ có thực hiện các nhiệm vụ sau:
											|1. lập đơn hàng sản xuất theo trình tự;
											|2. tạo lịch biểu thực hiện đơn hàng;
											|3. điều chỉnh các công đoạn sản xuất và nhu cầu về các nguồn lực theo đơn hàng;
											|4. tạo lịch biểu nhu cầu về các nguồn lực và phân tích đảm bảo sản xuất nguyên vật liệu;
											|5. phân tích trạng thái và kết nhâpọ thiết bị;
											|6. quản lý chênh lệch toàn cục, phân công lịch biểu sản xuất;
											|7. tạo bảng kê chi tiết có tính đến lô hàng xuất xưởng;
											|8. kiểm soát lập đơn hàng cung cấp dịch vụ giữa các phân xưởng;
											|9. kiểm soát yêu cầu và khiếu nại liên quan trong các bộ phận của doanh nghiệp.';
											|ru = 'Зона ответственности - производственные заказы в совокупности,
											|управление всеми производственными циклами в целом.
											|Под профилем выполняются задачи:
											|1. формирование очереди заказов на производство;
											|2. формирование графика выполнения заказов;
											|3. корректировка производственных этапов и потребностей в ресурсах по заказу;
											|4. формирование графика потребности в ресурсах и анализ обеспечения производства ТМЦ;
											|5. анализ состояния и загрузки оборудования;
											|6. управление глобальными отклонениями,оперативное диспетчирование графика производства;
											|7. формирование ресурсных спецификаций с учетом партий запуска;
											|8. контроль за оформлением заказов по оказанию межцеховых услуг;
											|9. контроль выполнения взаимных требований и претензий подразделений предприятия.';
											|en = 'Area of responsibility – production orders in total,
											|all production cycles management in total.
											|Tasks completed by the account:
											|1. Schedule production order queue
											|2. Schedule order fulfillment
											|3. Adjust production stages and resource demands by orders
											|4. Schedule resource demands and performing inventory fulfillment analysis
											|5. Analyze equipment state and load
											|6. Global variance management, operational production scheduling
											|7. Develop resource BOMs considering starting lots
											|8. Control registration of intershop service orders
											|9. Control fulfillment of mutual requirements and complaints of company business units.'; fa = 'Area of responsibility – production orders in total,
											|all production cycles management in total.
											|Tasks completed by the account:
											|1. Schedule production order queue
											|2. Schedule order fulfillment
											|3. Adjust production stages and resource demands by orders
											|4. Schedule resource demands and performing inventory fulfillment analysis
											|5. Analyze equipment state and load
											|6. Global variance management, operational production scheduling
											|7. Develop resource BOMs considering starting lots
											|8. Control registration of intershop service orders
											|9. Control fulfillment of mutual requirements and complaints of company business units.';
											|it = 'Area di responsabilità - ordini di produzione nel complesso,
											|gestione di tutti i cicli della produzione in generale.
											|Sotto il profilo vengono eseguiti gli obiettivi:
											|1. generazione di fila ordini per la produzione;
											|2. elaborazione del grafico di espletamento ordini;
											|3. rettifica delle fasi di produzione e dei fabbisogni di risorse per l''ordine;
											|4. elaborazione del piano di fabbisogni delle risorse e analisi di approvvigionamento della produzione con i beni e materiali;
											|5. analisi di stato e carico dell''impianto,
											|6. gestione delle deviazioni globali, controllo operativo del piano di produzione;
											|7. elaborazione delle specifiche delle scorte tenendo conto dei lotti di avviamento;
											|8. controllo della formalizzazione ordini per i servizi tra i reparti;
											|9. controllo di adempimento delle reciproche richieste e dei reclami di reparti della società.';
											|pl = 'Zakres odpowiedzialności - zlecenia produkcyjne łącznie,
											|zarządzanie wszystkimi cyklami produkcyjnymi w ogóle. 
											|Pod profilem są wykonywane zadania:
											|1. tworzenie kolejki zleceń produkcyjnych;
											|2. tworzenie harmonogramu realizacji zleceń;
											|3. zapis korygujący etapów produkcyjnych i potrzeb w zasobach według zamówienia;
											|4. tworzenie harmonogramu potrzeb w zasobach i analiza zaopatrzenia produkcji;
											|5. analiza statusu i załadowania urządzeń;
											|6. zarządzanie globalnymi odchyleniami,szybkie dyspozytorowanie harmonogramu produkcji;
											|7. tworzenie specyfikacji materiałowych z uwzględnieniem uruchomionych partii;
											|8. kontrola nad sporządzaniem zamówień na świadczenie usług między warsztatami;
											|9. kontrola wykonywania wzajemnych należności i roszczeń działów firmy.';
											|tr = 'Sorumluluk alanı; toplu olarak üretim siparişleri,
											|tüm üretim döngülerinin bir bütün olarak yönetimi.
											|Profil altında gerçekleştirilen görevler:
											|1. Üretim emri kuyruğunun oluşturulması;
											|2. Siparişlerin gerçekleştirme programının oluşturulması;
											|3. Sipariş üzerine üretim aşamalarının ve kaynak gereksinimlerinin düzenlenmesi;
											|4. Kaynak gereksinimi programının oluşturulması ve üretim stoku temininin analizi;
											|5. Ekipman durumunun ve yükünün analizi;
											|6. Küresel sapmaların yönetimi, üretim programının operasyonel sevkiyatı;
											|7. Başlangıç lotlarına göre ürün reçetelerinin oluşturulması;
											|8. Üretimhaneler arası hizmetlerin sağlanmasına yönelik siparişlerin düzenlenmesinin kontrolü;
											|9. İşletme departmanlarının karşılıklı gereksinimlerinin ve taleplerinin yerine getirilmesinin kontrolü.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProductionManagerProfile(ProfilesDetails)
	
	// Profile "Production Manager".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ProductionManager";
	ProfileDetails.Id = "a90d907c-a823-454b-8bc0-5e5f1807c835";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Quản lý sản xuất';
										|ru = 'Менеджер производства';
										|en = 'Production manager'; fa = 'Production manager';
										|it = 'Manager di produzione';
										|pl = 'Kierownik produkcji';
										|tr = 'Üretim yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ProductionUseInProductsNavigationPanel");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadTechnologicalProcesses");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForProductionStagesExecutionDelays");
	ProfileDetails.Roles.Add("ReadReasonsForProductionCancellation");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadProductionLots");
	
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	ProfileDetails.Roles.Add("ReadDefects");
	ProfileDetails.Roles.Add("ReadAttachedFilesRMDocuments");
	
	// Directories, adding changes.
	ProfileDetails.Roles.Add("AddEditTeam");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadEmployeeActivityRates");
	ProfileDetails.Roles.Add("ReadManufacturingLaborCosts");
	ProfileDetails.Roles.Add("ReadCostAllocationSettings");
	ProfileDetails.Roles.Add("ReadProductCostElements");	
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	ProfileDetails.Roles.Add("ReadProductionCostLots");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadIndicatorValuesToAllocateCosts");
	ProfileDetails.Roles.Add("ReadOtherIncomeAndExpenses");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfTransferOrders");
	ProfileDetails.Roles.Add("ReadBalancesOfAssemblyOrders");
	ProfileDetails.Roles.Add("ReadBalanceOrdersOfMaterialsInProduction");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadWorkCenterRMActivities");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("ReadProductsAndSemiFinishedProductsInProduction");
	
	ProfileDetails.Roles.Add("ReadInventoryCost");
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadInternalAcceptanceCertificate");
	ProfileDetails.Roles.Add("ReadMaterialProviderOrder2_5");
	ProfileDetails.Roles.Add("ReadReportToMaterialProvider2_5");
	ProfileDetails.Roles.Add("ReadProductAndMaterialMovement");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	ProfileDetails.Roles.Add("ReadRMOrders");
	ProfileDetails.Roles.Add("ReadConsignmentNotes");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadBackflushProduction");
	ProfileDetails.Roles.Add("ReadShiftTasks");
	ProfileDetails.Roles.Add("ReadOrdersForMaterialsForProduction");

	// Documents, appendix.
	ProfileDetails.Roles.Add("AddEditWorkOutput");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("AddEditProductionOperations2_2");
	ProfileDetails.Roles.Add("AddEditMovementsOfProductsAndMaterials");
	
	// Processing, reports.
	ProfileDetails.Roles.Add("ProductionManagerReports");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UseDemandFulfillmentParameters");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("ViewReportsOnWorkCenterLoad");
	ProfileDetails.Roles.Add("UseOfOperationsExecution");	
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// Registers, adding change.
	
	// shapes.
	
	// KI.
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfInternalAcceptanceCertificate", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("StatusesOfRegisteredRecordsOfProductsAndMaterials", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddProductionManagerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Trách nhiệm - một hoặc nhiều khu vực sản xuất.
											|Theo hồ sơ có thực hiện các nhiệm vụ sau:
											|1. lập chứng từ xuất xưởng sản phẩm và công việc;
											|2. nhận nguyên vật liệu vào sản xuất;
											|3. tạo sản lượng cho nhân viên theo công việc đã thực hiện;
											|4. phản ánh tiến độ thực hiện lịch biểu sản xuất.';
											|ru = 'Зона ответственности - один или несколько производственных участков.
											|Под профилем выполняются задачи:
											|1. оформление выпуска продукции и работ;
											|2. получение материалов в производстве;
											|3. оформление выработки сотрудников по выполненным работам;
											|4. отражение хода выполнения пооперационного расписания производства.';
											|en = 'Area of responsibility – one or several production sites.
											|Tasks completed by the account:
											|1. Register product and labor release
											|2. Receive materials in production;
											|3. Register timesheets charge by performed works
											|4. Record progress of production operation timetable.'; fa = 'Area of responsibility – one or several production sites.
											|Tasks completed by the account:
											|1. Register product and labor release
											|2. Receive materials in production;
											|3. Register timesheets charge by performed works
											|4. Record progress of production operation timetable.';
											|it = 'Area di responsabilità - uno o più settori di produzione.
											|Sotto il profilo vengono eseguiti gli obiettivi:
											| 1. formalizzazione dell''emissione dei prodotti e lavori;
											|2. ricezione dei materiali in produzione;
											|3. formalizzazione della produttività dei dipendenti per i lavori effettuati;
											|4. proiezione di espletamento della programmazione operativa della produzione.';
											|pl = 'Zakres odpowiedzialności - jeden lub kilka odcinków produkcyjnych. 
											|Pod profilem są wykonywane zadania:
											|1. odprawa produkcji i robót;
											|2. uzyskanie materiałów w produkcji;
											|3. sporządzenie urobku pracowników zgodnie z wykonanymi pracami;
											|4. odzwierciedlenia postępu pooperacyjnego harmonogramu produkcji.';
											|tr = 'Sorumluluk alanı; bir veya daha fazla üretim alanı.
											|Profil altında gerçekleştirilen görevler:
											|1. İmal edilen ürün ve iş çıktısının düzenlenmesi;
											|2. Üretimde malzemelerin alınması;
											|3. Yapılan iş için zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi;
											|4. Üretim yürütme sistemindeki ilerlemenin yansıması.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileOfManagerForProcessingTollFreeRawMaterials(ProfilesDetails)
	
	// Profile "Manager for processing of tolling raw materials".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "ProvidedMaterialProcessingOfficer";
	ProfileDetails.Id = "7387da79-e932-11e2-a832-c86000df10d3";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Quản lý hợp đồng thầu phụ';
										|ru = 'Менеджер по переработке давальческого сырья';
										|en = 'Subcontracting officer'; fa = 'Subcontracting officer';
										|it = 'Manager della trasformazione di materia prima del committente';
										|pl = 'Kierownik działu przetwórstwa materiałów w przerobie zewnętrznym';
										|tr = 'Tedarikçi hammaddeleri işlenme yöneticisi'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	///////////////////////////////////////////////////////////////////////
	// Basic rights.
	ProfileDetails.Roles.Add("BasicAccessTM");
	
	///////////////////////////////////////////////////////////////////////
	// Reference books, reading.
	
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadTechnologicalProcesses");
	ProfileDetails.Roles.Add("ReadTermsOfSales");
	ProfileDetails.Roles.Add("ReadTermsOfPurchases");
	ProfileDetails.Roles.Add("ReadCounterpartyContracts");
	ProfileDetails.Roles.Add("ReadInformationAboutPartners");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCounterpartyBankAccounts");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ProductionUseInProductsNavigationPanel");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadOfflinePeripherals");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadProductCostElements");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonForCancellationOfClientsOrders");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadCounterpartiesItemsEDL");
	
	///////////////////////////////////////////////////////////////////////
	// Directories, adding changes.
	
	ProfileDetails.Roles.Add("AddEditCounterpartyContracts");
	ProfileDetails.Roles.Add("AddEditPartnerItems");
	ProfileDetails.Roles.Add("AddEditCounterpartiesItemsEDL");
	ProfileDetails.Roles.Add("AddEditOpportunities");
	ProfileDetails.Roles.Add("AddEditVehicles");
	ProfileDetails.Roles.Add("ChangeWarehouseInformationOfProducts");
	ProfileDetails.Roles.Add("RegisterProductsBarcodes");
	
	///////////////////////////////////////////////////////////////////////
	// Registers, reading.
	
	ProfileDetails.Roles.Add("ReadPartnerPrices");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadCompanyGoods");
	ProfileDetails.Roles.Add("ReadCustomersARAP");
	ProfileDetails.Roles.Add("ReadVendorsARAPAccounting");	
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadRemainingMaterialsAndWorksInProduction");
	ProfileDetails.Roles.Add("ReadBalancesOfPurchaseOrders");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadCashBalanceForExpense");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfImportDocuments");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadDeliveryStates");
	ProfileDetails.Roles.Add("ReadStatesOfSalesOrder");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");
	ProfileDetails.Roles.Add("ReadRemainingSalesOrdersReturnRequests");
	ProfileDetails.Roles.Add("ReadPurchaseOrders");
	ProfileDetails.Roles.Add("ReadPurchaseRequests");
	ProfileDetails.Roles.Add("ReadProvisionRequests");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadGoodsForRegistrationOfImportDocuments");
	
	ProfileDetails.Roles.Add("ReadInventoryCost");
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	
	///////////////////////////////////////////////////////////////////////
	// Documents, reading.
	
	ProfileDetails.Roles.Add("ReadGoodsQualityControlCertificates");
	ProfileDetails.Roles.Add("ReadVendorBonusCertificate");
	ProfileDetails.Roles.Add("ReadOBEntryARAP");
	ProfileDetails.Roles.Add("ReadOBEntryGoods");
	ProfileDetails.Roles.Add("ReadSourceDocuments");
	ProfileDetails.Roles.Add("ReadCashAccountIssueNoteOrCashReceipts");
	ProfileDetails.Roles.Add("ReadGoodsTransfers");
	ProfileDetails.Roles.Add("ReadGoodsAssemblies");
	ProfileDetails.Roles.Add("ReadOtherGoodsRecordingAsReceived");
	ProfileDetails.Roles.Add("ReadPaymentCardTransactions");
	ProfileDetails.Roles.Add("ReadARAPAdjustmentDocuments");
	ProfileDetails.Roles.Add("ReadDocumentsOfBankAccountReceiptIssue");
	ProfileDetails.Roles.Add("ReadGoodsAssignmentAdjustments");
	ProfileDetails.Roles.Add("ReadCustomerInvoiceServicesAndAssets"); 
	ProfileDetails.Roles.Add("ReadTransportationJobs");
	ProfileDetails.Roles.Add("ReadPackingLists");
	ProfileDetails.Roles.Add("ReadTransactionsWithGiftCards");
	ProfileDetails.Roles.Add("ReadCashRegisterReceipts");
	
	// Reading data for input based on the processor's documents
	ProfileDetails.Roles.Add("ReadSubcontractOrders2_5");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadGoodsTransferToBailee");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	
	///////////////////////////////////////////////////////////////////////
	// Documents, adding changes.
	
	ProfileDetails.Roles.Add("AddEditMaterialProviderOrders2_5");
	ProfileDetails.Roles.Add("AddEditGoodsReceiptForStorage");
	ProfileDetails.Roles.Add("AddEditGoodsShipmentFromStorage");
	ProfileDetails.Roles.Add("AddEditReportsOnWriteOffOfGoodsAcceptedForStorage");
	ProfileDetails.Roles.Add("AddEditRedemptionsOfGoodsReceivedForStorage");
	ProfileDetails.Roles.Add("AddEditReportsToMaterialProviders2_5");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditARAPAdjustmentDocumentsPaymentOffset");
	ProfileDetails.Roles.Add("AddEditInstructionsForShippingAgents");
	ProfileDetails.Roles.Add("PaymentSettlement");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportFollowingReceiptFromMaterialProvider");
	ProfileDetails.Roles.Add("AddEditDiscrepancyReportFollowingShipmentToMaterialProvider");
	ProfileDetails.Roles.Add("AddEditCreditNotes");
	
	///////////////////////////////////////////////////////////////////////
	// Processing, reports.
	
	ProfileDetails.Roles.Add("TollManufacturingReports2_5");
	ProfileDetails.Roles.Add("SalesRepresentativeReports");
	ProfileDetails.Roles.Add("ViewReportStockAvailability");
	ProfileDetails.Roles.Add("ViewDocumentStatusReport");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("ViewOfStepsOfPaymentByClient");
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UsingDataProcessorTransferToProcessingDocumentJournal2_5");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentsOfReceiptForTollingAll2_5");
	ProfileDetails.Roles.Add("UsageOfManageTransferOfGoodsAssigned");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("UsePrintPriceTagsAndLabelsDataProcessor");
	ProfileDetails.Roles.Add("UsingOrderSupplyForecastDataProcessor");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	ProfileDetails.Roles.Add("UseSourceDocumentOriginalsRecordKeepingLogProcessing");
	///////////////////////////////////////////////////////////////////////
	// Visible subsystems of CI
	
	ProfileDetails.Roles.Add("SectionSales");
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("WarehouseSubsystem");
	ProfileDetails.Roles.Add("SalesSectionReceiptForTolling");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	ProfileDetails.Roles.Add("MasterDataSection");
	ProfileDetails.Roles.Add("QualityControlSubsystem");
	
	///////////////////////////////////////////////////////////////////////
	// Types of access
	
	ProfileDetails.AccessKinds.Add("TypesOfPrices",									"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("PartnerGroups",							"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("GroupsOfIndividuals",						"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("ProductGroups",						"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Companies",								"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Warehouses",									"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("TypesOfPrices",									"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Departments",							"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("KindsOfARAPSettlements", 	"AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("BusinessTransactions",					"Predefined");
	ProfileDetails.AccessKinds.Add("TypesOfGroundsForActOfDiscrepancies",			"Predefined");
	
	///////////////////////////////////////////////////////////////////////
	// Access Values
	
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TollManufacturing2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.Subcontracting2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReturnToMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ReportToMaterialProvider2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.RedemptionOfProviderGoods");
	
	
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProductionByToller2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5");
	ProfileDetails.AccessValues.Add("BusinessTransactions", "Enum.BusinessTransactions.TransferToToller2_5");
	
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider");
	ProfileDetails.AccessValues.Add("TypesOfGroundsForActOfDiscrepancies", "Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider");
	
	///////////////////////////////////////////////////////////////////////
	// Additional rights.
	
	ProfileDetails.Roles.Add("AddEditObjectPrintSettings");
	ProfileDetails.Roles.Add("SaveObjectPrintSettingsByDefault");
	ProfileDetails.Roles.Add("ChangeSaleDocumentRate");
	
	ProfileDetails.Roles.Add("VarianceFromSalesTermsAndConditions");
	
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);
	
	AccessManagementLocalization.AddRolesOfManagerForProcessingTollFreeRawMaterials(ProfileDetails);
	
	///////////////////////////////////////////////////////////////////////
	// description of the supplied profile.
	
	ProfileDetails.LongDesc =
		NStr("vi = 'Theo hồ sơ có các nhiệm vụ sau được thực hiện:
					|1. Lập đơn hàng của người thuê gia công;
					|2. Phản ánh việc tiếp nhận từ người thuê gia công và chuyển giao cho người thuê gia công;
					|3. Lập bảng kê dành cho người thuê gia công về việc thực hiện dịch vụ gia công.';
					|ru = 'Под профилем выполняются задачи:
					|1. Оформление заказов давальцев;
					|2. Отражения поступлений от давальцев и передач давальцам;
					|3. Оформление отчетов давальцам о выполнении услуг по переработке.';
					|en = 'The following tasks are completed under the profile:
					|1. Registration of subcontracting sales orders
					|2. Recording of receipts from material providers and ""Goods issue — Subcontracting services delivered""
					|3. Registration of ""Consumption reports — Subcontracting services delivered"" on provision of the processing services.'; fa = 'The following tasks are completed under the profile:
					|1. Registration of subcontracting sales orders
					|2. Recording of receipts from material providers and ""Goods issue — Subcontracting services delivered""
					|3. Registration of ""Consumption reports — Subcontracting services delivered"" on provision of the processing services.';
					|it = 'Sotto il profilo vengono eseguiti gli obiettivi:
					|1. Formalizzazione degli ordini dei prestatori;
					|2. Proiezione degli arrivi dai prestatori e delle consegne ai prestatori;
					|3. Formalizzazione dei report ai prestatori sull''espletamento dei servizi di trasformazione.';
					|pl = 'Pod profilem są wykonywane zadania: 
					|1. Składanie zamówień dla dawców; 
					|2. Odzwierciedlenie wpłat i wysyłek od dawców;
					|3. Sporządzenie raportów dawcom o wykonaniu usług na przetwórstwo.';
					|tr = 'Profil altında gerçekleştirilen görevler:
					|1. Tedarikçi siparişlerinin düzenlenmesi;
					|2. Tedarikçilerden girişlerin ve tedarikçilere transfer edilenlerin yansıması;
					|3. Tedarikçilere, işleme hizmetlerinin performansına ilişkin raporların hazırlanması.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddOTCControllerProfile(ProfilesDetails)
	
	// Profile "OTC Controller".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "OTCController";
	ProfileDetails.Id = "7c667f4f-4836-416e-b6ef-62ac6ffe7a14";
	ProfileDetails.Description  = NStr("vi = 'Bộ kiểm soát OTK';
										|ru = 'Контролер ОТК';
										|en = 'Quality control department inspector'; fa = 'Quality control department inspector';
										|it = 'Controllore OTK';
										|pl = 'Kontroler jakości';
										|tr = 'OTC kontrolörü'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reference books, reading.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ProductionUseInProductsNavigationPanel");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadControlledLot");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadTechnologicalProcesses");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadCalendars");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadReasonsForProductionStagesExecutionDelays");
	ProfileDetails.Roles.Add("ReadReasonsForProductionCancellation");
	ProfileDetails.Roles.Add("ReadReasonsForCancellingPurchaseOrders");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadProductionLots");
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadEmployeeActivityRates");
	ProfileDetails.Roles.Add("ReadManufacturingLaborCosts");
	ProfileDetails.Roles.Add("ReadProductCostElements");	
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadProductionIssueRegister");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductionCosts");
	ProfileDetails.Roles.Add("ReadProductionCostLots");
	ProfileDetails.Roles.Add("ReadItemsPrices");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadWorkCenterRMActivities");
	ProfileDetails.Roles.Add("ReadAlternativeMaterials");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	ProfileDetails.Roles.Add("ReadProductionStageSchedule2_2");
	ProfileDetails.Roles.Add("ReadProductsAndSemiFinishedProductsInProduction");
	
	ProfileDetails.Roles.Add("ReadInventoryCost");
	// Registers of advanced management accounting analytics
	ProfileDetails.Roles.Add("ReadSalesRevenue");
	ProfileDetails.Roles.Add("ReadRecordsItemsCounterparty");
	ProfileDetails.Roles.Add("ReadRecordsItemsIncomeExpenses");
	ProfileDetails.Roles.Add("ReadRecordsItemsItems");
	
	// Documents, reading.
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadProductionStages2_2");
	ProfileDetails.Roles.Add("ReadBackflushProduction");
	ProfileDetails.Roles.Add("ReadShiftTasks");
	ProfileDetails.Roles.Add("ReadProductionOperations2_2");
	
	// Processing, reports.
	ProfileDetails.Roles.Add("ViewReportsOnWorkCenterLoad");
	ProfileDetails.Roles.Add("UseOfOperationsExecution");
	
	// Control
	ProfileDetails.Roles.Add("OperationExecutionControl");
	
	// KI.
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	AccessManagementLocalization.AddOTCControllerRoles(ProfileDetails);
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Theo hồ sơ đang thực hiện nhiệm vụ kiểm soát thực hiện các giao dịch sản xuất.';
									|ru = 'Под профилем выполняются задачи контроля выполнения производственных операций.';
									|en = 'Use the profile to execute routing operation control tasks.'; fa = 'Use the profile to execute routing operation control tasks.';
									|it = 'Nel profilo vengono eseguiti i compiti di controllo di esecuzione delle operazioni di produzione.';
									|pl = 'Pod profilem są wykonywane zadania kontroli wykonania operacji produkcyjnych.';
									|tr = 'Profil altında, rota işlemlerinin yürütülmesini kontrol etme görevleri gerçekleştirilmektedir.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddApprovalOfMaterialReplacementPermits(ProfilesDetails)
	
	// Profile "Approval of permits for the replacement of materials."
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "MemberOfApprovalOfPermitsForReplacementOfMaterials";
	ProfileDetails.Id = "a1c153b5-46e5-45e2-90b7-70bdaff48980";
	ProfileDetails.Parent      = "Production";
	ProfileDetails.Description  = NStr("vi = 'Người tham gia thống nhất cho phép thay thế nguyên vật liệu';
										|ru = 'Участник согласования разрешений на замену материалов';
										|en = 'Participant of approval of engineering change orders'; fa = 'Participant of approval of engineering change orders';
										|it = 'Participant of approval of engineering change orders';
										|pl = 'Participant of approval of engineering change orders';
										|tr = 'Mühendislik değişiklik emirleri onay katılımcısı'", Common.DefaultLanguageCode());
	
	AddRequiredRolesToYourProfile(ProfileDetails);
		
	ProfileDetails.Roles.Add("ReadEngineeringChangeOrders");
	ProfileDetails.Roles.Add("AddAndEditApprovalOfEngineeringChangeOrders");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr("vi = 'Sẽ thống nhất cho phép thay thế vật liệu theo hồ sơ của người dùng.';
									|ru = 'Под профилем происходит согласование разрешений на замену материалов.';
									|en = 'Use this profile to approve engineering change orders.'; fa = 'Use this profile to approve engineering change orders.';
									|it = 'Use this profile to approve engineering change orders.';
									|pl = 'Use this profile to approve engineering change orders.';
									|tr = 'Profil kapsamında mühendislik değişiklik emirleri onaylanır.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion

#EndRegion