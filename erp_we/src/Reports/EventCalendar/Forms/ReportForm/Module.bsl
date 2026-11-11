
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillInEventTree();
	
	FormationPeriod = Items.FormationPeriod.ChoiceList[0];
	Items.UpdateCalculations.Visible = Not GetFunctionalOption("NewOnlineARAPAccounting");
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Settings = New Structure;
	Settings.Insert("Filter_Settings",Report.SettingsComposer.GetSettings());
	
	Common.CommonSettingsStorageSave("Report.EventCalendar", "ReportForm", Settings);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	TreeTypesOfConfigurationEvents = Settings.Get("EventKinds");
	If TreeTypesOfConfigurationEvents <> Undefined Then
		
		TreeTypesOfEventsForm = FormAttributeToValue("EventKinds");
		For Each ConfigurationTreeLine In TreeTypesOfConfigurationEvents.Rows Do
			
			If ConfigurationTreeLine.Check > 0 Then
				
				FoundRow = TreeTypesOfEventsForm.Rows.Find(ConfigurationTreeLine.EventKind, "EventKind",False);
				If FoundRow <> Undefined Then
					FoundRow.Check = ConfigurationTreeLine.Check;
				EndIf;
				
			EndIf;
			
			For Each SubordinateLineOfConfigurationTree In ConfigurationTreeLine.Rows Do
				
				If SubordinateLineOfConfigurationTree.Check > 0 Then
					
					FoundRow = TreeTypesOfEventsForm.Rows.Find(SubordinateLineOfConfigurationTree.EventKind, "EventKind",True);
					If FoundRow <> Undefined Then
						FoundRow.Check = SubordinateLineOfConfigurationTree.Check;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		Settings.Delete("EventKinds");
		ValueToFormAttribute(TreeTypesOfEventsForm,"EventKinds");
		
		For Each GroupOfEventTypes In EventKinds.GetItems() Do
			
			TaggedItemsInGroup = 0;
			
			For Each EventKind In GroupOfEventTypes.GetItems() Do
			
				If EventKind.Check = 1 Then
					TaggedItemsInGroup = TaggedItemsInGroup + 1;
				EndIf;
			
			EndDo;
			
			If TaggedItemsInGroup = 0 Then
				GroupOfEventTypes.Check = 0 ;
			ElsIf TaggedItemsInGroup <> GroupOfEventTypes.GetItems().Count() Then
				GroupOfEventTypes.Check = 2 ;
			Else
				GroupOfEventTypes.Check = 1 ;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	SetStateReportNotGenerated();
	AvailabilityControl();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure OnLoadVariantAtServer(Settings)
	
	SchemeForFilter = FormAttributeToValue("Report").GetTemplate("SchemeFilters");
	SchemaURL = PutToTempStorage(SchemeForFilter,UUID);
	Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL)); 
	
	SettingsValue = Common.CommonSettingsStorageLoad("Report.EventCalendar","ReportForm");
	
	If SettingsValue <> Undefined And SettingsValue.Filter_Settings <> Undefined Then
		Report.SettingsComposer.LoadSettings(SettingsValue.Filter_Settings);
		Report.SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
EndProcedure

&AtClient
Procedure FormationPeriodOnChange(Item)

	SetStateReportNotGenerated();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	
	ClearMessages();

	If ReportSettingsAreNotFilledInCorrectly() Then
		Return;
	EndIf;
	GenerateReportServer();
	
	AvailabilityControl()
	
EndProcedure

&AtClient
Procedure Settings(Command)
	
	ParametersForSettingsForm = StructureOfSettingsForm();
	OpenForm("Report.EventCalendar.Form.SettingsForm",ParametersForSettingsForm,ThisForm,,,, 
		New CallbackDescription("SettingsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingsCompletion(Result, AdditionalParameters) Export
    
    If Result <> Undefined Then
        
        ProcessResultOnServer(Result.EventKinds);
        Report.SettingsComposer = Result.SettingsComposer;
        SettingsChanged = True;
        SetStateReportNotGenerated();
        
    EndIf;

EndProcedure

&AtClient
Procedure UpdateCalculations(Command)
	
	If ReportSettingsAreNotFilledInCorrectly() Then
		Return;
	EndIf;
	
	ResponseCode = Undefined;

	
	ShowQueryBox(New CallbackDescription("UpdateCalculationsCompletion", ThisObject), NStr("vi = 'Cập nhật công nợ với khách hàng?';
																							|ru = 'Актуализировать расчеты с клиентами?';
																							|en = 'Update customer AR/AP?'; fa = 'Update customer AR/AP?';
																							|it = 'Aggiornare i regolamenti con clienti?';
																							|pl = 'Chcesz zaktualizować rozliczenia z klientami?';
																							|tr = 'İstemcilerle mutabakatları güncelle?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure UpdateCalculationsCompletion(QuestionResult, AdditionalParameters) Export
    
    ResponseCode = QuestionResult;
    If ResponseCode = DialogReturnCode.Yes Then
        
        UpdateCalculationsUpdateReport();
        ShowUserNotification(
        NStr("vi = 'Thiết thực hóa công nợ';
			|ru = 'Расчеты актуализированы';
			|en = 'Settlements are updated'; fa = 'Settlements are updated';
			|it = 'Pagamenti aggiornati';
			|pl = 'Rozliczenia są zaktualizowane';
			|tr = 'Mutabakatlar güncellendi'"),
        , // URL
        NStr("vi = 'Đã cập nhật hạch toán với khách hàng';
			|ru = 'Расчеты с клиентами актуализированы';
			|en = 'Customer AR/AP are updated'; fa = 'Customer AR/AP are updated';
			|it = 'Regolamenti con clienti aggiornati';
			|pl = 'Rozliczenia z klientami zaktualizowane';
			|tr = 'İstemcilerle mutabakatlar güncellendi'"));
        
    EndIf;
    
    AvailabilityControl();

EndProcedure 

#EndRegion

#Region Private

&AtClient
Function ReportSettingsAreNotFilledInCorrectly()

	For Each GroupOfEventTypes In EventKinds.GetItems() Do
	
		For Each TypeOfEvents In GroupOfEventTypes.GetItems() Do
		
			If TypeOfEvents.Check = 1 Then
				Return False;
			EndIf;
		
		EndDo;
	
	EndDo;
	
	CommonClientServer.MessageToUser(NStr("vi = 'Cần chọn ít nhất một dạng sự kiện trong tùy chỉnh';
											|ru = 'Необходимо выбрать хотя бы один вид событий в настройках';
											|en = 'Select at least one event kind in the settings'; fa = 'Select at least one event kind in the settings';
											|it = 'È necessario selezionare almeno un tipo di evento nelle impostazioni';
											|pl = 'Musisz wybrać przynajmniej jeden typ zdarzenia w ustawieniach.';
											|tr = 'Ayarlarda en az bir etkinlik türü seçilmeli'"));
	Return True;

EndFunction

&AtServer
Function StructureOfSettingsForm()

	ParametersForSettingsForm = New Structure();
	ParametersForSettingsForm.Insert("EventKinds",TemporaryStorageOfSettingsOnServer());
	ParametersForSettingsForm.Insert("CompositionSetup",Report.SettingsComposer);
	ParametersForSettingsForm.Insert("UID_OfCallingForm",UUID);
	
	Return  ParametersForSettingsForm;

EndFunction

&AtServer
Function TemporaryStorageOfSettingsOnServer()
	
	Return PutToTempStorage(FormAttributeToValue("EventKinds"),UUID);
	
EndFunction

&AtServer
Procedure ProcessResultOnServer(AddressOfMetricsTree)
	
	ValueToFormData(GetFromTempStorage(AddressOfMetricsTree),EventKinds);
	
EndProcedure

&AtServer
Procedure GenerateReportServer()

	ReportTable.Clear();
	ObjectReport = FormAttributeToValue("Report");
	
	ObjectReport.GenerateReport(ReportTable,StructureReportGenerationParameters());
	ValueToFormAttribute(ObjectReport,"Report");
	Items.Result.StatePresentation.Visible = False;
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;

EndProcedure 

&AtServer
Function StructureReportGenerationParameters()

	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("EventKinds",FormAttributeToValue("EventKinds"));
	ParametersStructure.Insert("FormationPeriod", FormationPeriod);
	ParametersStructure.Insert("ThereIsAProjectTaskRight", ThereIsAProjectTaskRight);
	ParametersStructure.Insert("UseBusinessProcessesAndTasks", UseBusinessProcessesAndTasks);
	ParametersStructure.Insert("ThereIsAnAssigneeTaskRight", ThereIsAnAssigneeTaskRight);
	ParametersStructure.Insert("ThereIsAnAssigneeRoleRight", ThereIsAnAssigneeRoleRight);
	
	Return ParametersStructure;

EndFunction

&AtClient
Procedure SetIncludeFlagValue(CheckValue,Parent)
	
	For Each Item In Parent.GetItems() Do
	
		Item.Check = CheckValue;
		SetIncludeFlagValue(CheckValue,Item);
	
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInEventTree()
	
	RecordCustomerClaims                    = GetFunctionalOption("RecordComplaints");
	UseEmailClient                      = GetFunctionalOption("UseEmailClient");
	UseOtherInteractions                = GetFunctionalOption("UseOtherInteractions");
	UseOpportunityManagement                  = GetFunctionalOption("UseOpportunityManagement");
	UseTermsOfPurchases             = GetFunctionalOption("UseTermsOfPurchases");
	ToUseTermsOfSales                = GetFunctionalOption("ToUseTermsOfSales");
	UseSalesOrders                      = GetFunctionalOption("UseSalesOrders");
	UsePurchaseOrders                   = GetFunctionalOption("UsePurchaseOrders");
	UseRequestsForReturnOfGoodsFromCustomers    = GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	UseInventoryConsumptionOrders       = GetFunctionalOption("UseInventoryConsumptionOrders");
	UseInventoryConsumption               = GetFunctionalOption("UseInventoryConsumption");
	UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	UseBusinessProcessesAndTasks               = GetFunctionalOption("UseBusinessProcessesAndTasks");
	UseReportsOfDiscrepanciesAfterShipment        = GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment");
	
	ThereAreRightsToPartners                  = AccessRight("Read",Metadata.Catalogs.Partners);
	ThereAreRightsToIndividuals                     = AccessRight("Read",Metadata.Catalogs.Persons);
	ThereAreRightsToContracts                   = AccessRight("Read",Metadata.Catalogs.CounterpartyContracts);
	ThereAreRightsToMarketingActivities   = AccessRight("Read",Metadata.Catalogs.MarketingActivities);
	ThereAreRightsToProjects                    = AccessRight("Read",Metadata.Catalogs.Projects);
	ThereAreRightsToTransactions                     = AccessRight("Read",Metadata.Catalogs.SalesOpportunitiesToCustomer);
	ThereIsRightOfAgreementWithClients         = AccessRight("Read",Metadata.Catalogs.TermsOfSale);
	ThereIsRightOfAgreementWithSuppliers      = AccessRight("Read",Metadata.Catalogs.TermsOfPurchaseFromVendors);
	ThereIsAProjectTaskRight               = AccessRight("Read",Metadata.Catalogs.ProjectTasks);
	ThereIsRightToSetPrices                 = AccessRight("Read",Metadata.Documents.PriceSetup);
	ThereAreRightCustomerOrders               = AccessRight("Read",Metadata.Documents.SalesOrder);
	ThereIsRightAboutDiscrepanciesAfterShipment   = AccessRight("Read",Metadata.Documents.DiscrepancyReportFollowingShipment);
	HaveRightToSendOrdersToSupplier             = AccessRight("Read",Metadata.Documents.PurchaseOrder);
	YouHaveRightToRefundSupplier           = AccessRight("Read",Metadata.Documents.ReturnOfGoodsToVendor);
	ThereIsRightOfApplicationForRefund              = AccessRight("Read",Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	ThereIsRightSaleOfGoodsServices       = AccessRight("Read",Metadata.Documents.CustomerInvoice);
	HaveRightPowerOfAttorneyToReceiveGoods = AccessRight("Read",Metadata.Documents.IssuedLetterOfAuthority);
	ThereIsRightToDomesticConsumption   = AccessRight("Read",Metadata.Documents.InventoryConsumptionOrder);
	ThereIsRightRegisterInternalConsumption = AccessRight("Read",Metadata.AccumulationRegisters.InventoryConsumptionOrders);
	ThereIsRightOfInternalConsumption        = AccessRight("Read",Metadata.Documents.InventoryConsumption);
	ThereIsRightApplicationForSpendingCash       = AccessRight("Read",Metadata.Documents.PaymentRequest);
	ThereIsRightReconciliationOfMutualSettlements         = AccessRight("Read",Metadata.Documents.ARAPReconciliation2_4);
	ThereIsRightReconciliationOfMutualSettlements2_5_11   = AccessRight("Read",Metadata.Documents.ARAPReconciliation2_5_11);
	ThereIsAnAssigneeTaskRight            = AccessRight("Read",Metadata.Tasks.PerformerTask);
	ThereIsAnAssigneeRoleRight             = AccessRight("View",Metadata.InformationRegisters.TaskPerformers);
	ThereIsRightToRegisterRequestForRefund       = AccessRight("Read",Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
	HaveRightToRegisterGoodsForShipment       = AccessRight("Read",Metadata.AccumulationRegisters.GoodsForIssue);
	ThereIsRightToRegisterPayments   = AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments);
	ThereIsRightToRegisterPaymentsByClients      = AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments);
	HaveRightToOrderMaterials              = AccessRight("Read",Metadata.Documents.OrderOfMaterialsForProduction);
	ThereIsRightRegisterOfMaterialOrders      = AccessRight("Read",Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction);
	ThereAreRightsForInteraction = AccessRight("Read",Metadata.Documents.Meeting)
	                            And AccessRight("Read",Metadata.Documents.PhoneCall)
	                            And AccessRight("Read",Metadata.Documents.IncomingEmail)
	                            And AccessRight("Read",Metadata.Documents.OutgoingEmail);
	
	TreeNode = EventViewAddedToTree(EventKinds,"Marketing", NStr("vi = 'Marketing';
																|ru = 'Маркетинг';
																|en = 'Marketing'; fa = 'بازاریابی';
																|it = 'Marketing';
																|pl = 'Marketing';
																|tr = 'Pazarlama'"));
	If ThereAreRightsToMarketingActivities Then
		EventViewAddedToTree(TreeNode, "MarketingActivities",NStr("vi = 'Hoạt động Marketing';
																	|ru = 'Маркетинговые мероприятия';
																	|en = 'Marketing activities'; fa = 'فعالیت‌های بازاریابی';
																	|it = 'Azioni di marketing';
																	|pl = 'Wydarzenia marketingowe';
																	|tr = 'Pazarlama faaliyetleri'"));
	EndIf;
	If ThereIsRightToSetPrices Then
		EventViewAddedToTree(TreeNode, "SettingPrices", NStr("vi = 'Định giá mặt hàng';
															|ru = 'Установки цен номенклатуры';
															|en = 'Product pricing'; fa = 'Product pricing';
															|it = 'Impostazione dei prezzi degli articoli';
															|pl = 'Ustawianie cen nomenklatury';
															|tr = 'Ürün fiyatı ayarlamaları'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);
	
	TreeNode = EventViewAddedToTree(EventKinds,"Sales", NStr("vi = 'Bán hàng';
															|ru = 'Продажи';
															|en = 'Sales'; fa = 'فروش';
															|it = 'Vendite';
															|pl = 'Sprzedaż';
															|tr = 'Satış'"));
	If ThereIsRightOfAgreementWithClients And ToUseTermsOfSales Then
		EventViewAddedToTree(TreeNode, "AgreementsWithClients", NStr("vi = 'Thỏa thuận với khách hàng';
																	|ru = 'Соглашения с клиентами';
																	|en = 'Terms of sales'; fa = 'شرایط فروش';
																	|it = 'Accordi con clienti';
																	|pl = 'Porozumienia z klientami';
																	|tr = 'Satış koşulları'"));
	EndIf;
	If ThereAreRightCustomerOrders And UseSalesOrders And ThereAreRightsToContracts And ThereIsRightToRegisterPaymentsByClients  Then
		EventViewAddedToTree(TreeNode, "SalesOrders", NStr("vi = 'Đơn hàng của khách';
															|ru = 'Заказы клиентов';
															|en = 'Sales orders'; fa = 'سفارش‌های فروش';
															|it = 'Ordini dei clienti';
															|pl = 'Zamówienia od klientów';
															|tr = 'Satış siparişleri'"));
	EndIf;
	If ThereIsRightOfApplicationForRefund And UseRequestsForReturnOfGoodsFromCustomers And ThereIsRightToRegisterRequestForRefund And ThereIsRightToRegisterPaymentsByClients  Then
		EventViewAddedToTree(TreeNode, "RequestsForReturn", NStr("vi = 'Giấy đề nghị trả hàng';
																|ru = 'Заявки на возврат';
																|en = 'Return requests'; fa = 'درخواست‌های برگشت';
																|it = 'Richieste di reso';
																|pl = 'Zgłoszenia do zwrotu';
																|tr = 'İade talepleri'"));
	EndIf;
	If UseOpportunityManagement And ThereAreRightsToTransactions Then
		EventViewAddedToTree(TreeNode, "SalesOpportunities", NStr("vi = 'Vụ việc';
																	|ru = 'Сделки';
																	|en = 'Sales opportunities'; fa = 'فرصت‌های فروش';
																	|it = 'Transazioni';
																	|pl = 'Sales opportunities';
																	|tr = 'Satış fırsatları'"));
	EndIf;
	If ThereIsRightSaleOfGoodsServices And ThereIsRightToRegisterPaymentsByClients Then
		EventViewAddedToTree(TreeNode, "SalesOfGoodsAndServices_", NStr("vi = 'Hoá đơn bán hàng';
																		|ru = 'Реализации товаров и услуг';
																		|en = 'Customer invoice'; fa = 'فاکتور مشتری';
																		|it = 'Vendite di merci e servizi';
																		|pl = 'Sprzedaż towarów i usług';
																		|tr = 'Ürün ve hizmet satışları'"));
	EndIf;
	If ThereIsRightAboutDiscrepanciesAfterShipment And UseReportsOfDiscrepanciesAfterShipment Then
		EventViewAddedToTree(TreeNode, "CustomerAcceptanceCertificates", NStr("vi = 'Biên bản chênh lệch sau khi bán';
																				|ru = 'Акты о расхождениях после реализации';
																				|en = 'Sales invoice disputes'; fa = 'Sales invoice disputes';
																				|it = 'Atti sulle discrepanze dopo il realizzo';
																				|pl = 'Protokoły o odchyleniu po sprzedaży';
																				|tr = 'Satış faturası uyuşmazlığı'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);

	If ThereAreRightsForInteraction And UseEmailClient Then
		
		TreeNode = EventViewAddedToTree(EventKinds,"Interactions", NStr("vi = 'Giao tiếp';
																		|ru = 'Взаимодействия';
																		|en = 'Interactions'; fa = 'تعاملات';
																		|it = 'Interazioni';
																		|pl = 'Współdziałania';
																		|tr = 'İş etkileşimleri'"));
		
		EventViewAddedToTree(TreeNode, "IncomingMessages",NStr("vi = 'E-mail đến';
																|ru = 'Входящие письма';
																|en = 'Incoming mail'; fa = 'ایمیل ورودی';
																|it = 'Mail in entrata';
																|pl = 'Wiadomości e-mail przychodzące';
																|tr = 'Gelen e-posta'"));
		EventViewAddedToTree(TreeNode, "OutgoingMessages", NStr("vi = 'E-mail đi';
																|ru = 'Исходящие письма';
																|en = 'Outgoing emails'; fa = 'Outgoing emails';
																|it = 'Lettere in uscita';
																|pl = 'Wiadomości wychodzące';
																|tr = 'Giden e-posta'"));
		If UseOtherInteractions Then
			EventViewAddedToTree(TreeNode, "Meetings", NStr("vi = 'Cuộc gặp';
															|ru = 'Встречи';
															|en = 'Meetings'; fa = 'Meetings';
															|it = 'Incontri';
															|pl = 'Spotkania';
															|tr = 'Randevular'"));
			EventViewAddedToTree(TreeNode, "PhoneCalls", NStr("vi = 'Cuộc gọi điện thoại';
																|ru = 'Телефонные звонки';
																|en = 'Phone calls'; fa = 'تماس‌های تلفنی';
																|it = 'Telefonate';
																|pl = 'Połączenia telefoniczne';
																|tr = 'Telefon görüşmeleri'"));
			EventViewAddedToTree(TreeNode, "PlannedInteractions",NStr("vi = 'Giao tiếp dự tính';
																		|ru = 'Запланированные взаимодействия';
																		|en = 'Scheduled interactions'; fa = 'تعاملات زمان‌بندی‌شده';
																		|it = 'Interazioni pianificate';
																		|pl = 'Interakcje zaplanowane';
																		|tr = 'Planlı etkileşimler'"));
		EndIf;
		
		CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
		
	EndIf;
	
	TreeNode = EventViewAddedToTree(EventKinds,"Purchases", NStr("vi = 'Mua hàng';
																|ru = 'Закупки';
																|en = 'Purchases'; fa = 'خریدها';
																|it = 'Acquisti';
																|pl = 'Zakup';
																|tr = 'Satın alma'"));
	If ThereIsRightOfAgreementWithSuppliers And UseTermsOfPurchases Then
		EventViewAddedToTree(TreeNode, "TermsOfPurchaseFromVendors", NStr("vi = 'Thỏa thuận với nhà cung cấp';
																			|ru = 'Соглашения с поставщиками';
																			|en = 'Terms of purchase'; fa = 'شرایط خرید';
																			|it = 'Accordi con fornitori';
																			|pl = 'Zamówienie do dostawców';
																			|tr = 'Satın alma koşulları'"));
	EndIf;
	If UsePurchaseOrders And HaveRightToSendOrdersToSupplier And ThereAreRightsToContracts And ThereIsRightToRegisterPayments Then
		EventViewAddedToTree(TreeNode, "PurchaseOrders", NStr("vi = 'Đơn hàng đặt nhà cung cấp';
																|ru = 'Заказы поставщикам';
																|en = 'Purchase orders'; fa = 'سفارش‌های خرید';
																|it = 'Ordini ai fornitori';
																|pl = 'Zamówienia do dostawcy';
																|tr = 'Satın alma siparişleri'"));
	EndIf;
	If YouHaveRightToRefundSupplier And HaveRightToRegisterGoodsForShipment And ThereIsRightToRegisterPayments Then
		EventViewAddedToTree(TreeNode, "RefundsToSupplier", NStr("vi = 'Trả lại hàng cho nhà cung cấp';
																|ru = 'Возвраты товаров поставщику';
																|en = 'Returns of goods to vendor'; fa = 'Returns of goods to vendor';
																|it = 'Restituzioni delle merci al fornitore';
																|pl = 'Zwroty towarów do dostawcy';
																|tr = 'Tedarikçiye ürün iadesi'"));
	EndIf;
	If HaveRightPowerOfAttorneyToReceiveGoods Then
		EventViewAddedToTree(TreeNode, "PowerOfAttorneyReceiptOfGoods", NStr("vi = 'Giấy giới thiệu để nhận hàng hóa';
																			|ru = 'Доверенности на получение товаров';
																			|en = 'Authorization letters for goods receipt'; fa = 'وکالت‌نامه‌های دریافت کالا';
																			|it = 'Deleghe per il ritiro merci';
																			|pl = 'Pełnomocnictwa do odbioru towarów';
																			|tr = 'Malların kabulüne ilişkin vekaletnameler'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);
	
	TreeNode = EventViewAddedToTree(EventKinds,"Finances", NStr("vi = 'Tài chính';
																|ru = 'Финансы';
																|en = 'Finances'; fa = 'Finances';
																|it = 'Finanze';
																|pl = 'Finanse';
																|tr = 'Finans'"));
	If ThereIsRightApplicationForSpendingCash And UsePaymentRequests Then
		EventViewAddedToTree(TreeNode, "PaymentRequest", NStr("vi = 'Giấy đề nghị thanh toán';
																|ru = 'Заявки на расходование денежных средств';
																|en = 'Payment requests'; fa = 'درخواست‌های پرداخت';
																|it = 'Richieste per la spesa';
																|pl = 'Wnioski o wydatkowanie środków pieniężnych';
																|tr = 'Ödeme talepleri'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);
	
	TreeNode = EventViewAddedToTree(EventKinds,"InternalInventoryTransfers", NStr("vi = 'Điều chuyển hàng hóa nội bộ';
																					|ru = 'Внутреннее товародвижение';
																					|en = 'Internal inventory transfers'; fa = 'انتقالات داخلی موجودی';
																					|it = 'Flusso di prodotti interno';
																					|pl = 'Wewnętrzny ruch towarów';
																					|tr = 'Dahili stok transferleri'"));
	If ThereIsRightToDomesticConsumption And UseInventoryConsumptionOrders And ThereIsRightRegisterInternalConsumption Then
		EventViewAddedToTree(TreeNode, "InventoryConsumptionOrder", NStr("vi = 'Đơn hàng tiêu dùng nội bộ';
																		|ru = 'Заказы на внутреннее потребление';
																		|en = 'Inventory consumption orders'; fa = 'سفارش‌های مصرف موجودی';
																		|it = 'Ordini per il consumo interno';
																		|pl = 'Zamówienia na konsumpcję wewnętrzną';
																		|tr = 'İç tüketim için siparişler'"));
	EndIf;
	If ThereIsRightOfInternalConsumption And UseInventoryConsumption Then
		EventViewAddedToTree(TreeNode, "InventoryConsumption", NStr("vi = 'Tiêu dùng hàng hóa nội bộ';
																	|ru = 'Внутреннее потребление';
																	|en = 'Inventory consumption'; fa = 'مصرف موجودی';
																	|it = 'Consumo interno';
																	|pl = 'Konsumpcja wewnętrzna';
																	|tr = 'Stok tüketimi'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);
	
	TreeNode = EventViewAddedToTree(EventKinds,"Other", NStr("vi = 'Dạng khác';
															|ru = 'Прочее';
															|en = 'Other'; fa = 'سایر';
															|it = 'Altro';
															|pl = 'Inne';
															|tr = 'Diğer'"));
	If ThereAreRightsToPartners And ThereAreRightsToIndividuals Then
		EventViewAddedToTree(TreeNode, "BirthdaysOfContactPersons", NStr("vi = 'Ngày sinh của người liên hệ';
																		|ru = 'Дни рождения контактных лиц';
																		|en = 'Contact persons'' birthdays'; fa = 'Contact persons'' birthdays';
																		|it = 'Compleanni delle persone di contatto';
																		|pl = 'Urodziny osób kontaktowych';
																		|tr = 'İrtibat kişileri doğum günleri'"));
	EndIf;
	If ThereIsRightReconciliationOfMutualSettlements Then
		EventViewAddedToTree(TreeNode, "ARAPReconciliation2_4", NStr("vi = 'Đối chiếu công nợ (2.4)';
																	|ru = 'Сверки взаиморасчетов (2.4)';
																	|en = 'AR/AP reconciliations (2.4)'; fa = 'تطبیق‌های دریافتنی/پرداختنی (2.4)';
																	|it = 'Сверки взаиморасчетов (2.4)';
																	|pl = 'AR/AP reconciliations (2.4)';
																	|tr = 'Alacak/Borç mutabakatı (2.4)'"));
	EndIf;
	If ThereIsRightReconciliationOfMutualSettlements2_5_11 Then
		EventViewAddedToTree(TreeNode, "ARAPReconciliation2_5_11", NStr("vi = 'Đối chiếu công nợ';
																		|ru = 'Сверки взаиморасчетов';
																		|en = 'AR/AP reconciliations'; fa = 'تطبیق‌های دریافتنی/پرداختنی';
																		|it = 'Verifiche dei pagamenti reciproci';
																		|pl = 'Porównanie rozliczeń wzajemnych';
																		|tr = 'Alacak/ borç mutabakatları'"));
	EndIf;
	If ThereAreRightsToContracts Then
		EventViewAddedToTree(TreeNode, "CounterpartyAgreements", NStr("vi = 'Hợp đồng đối tác';
																		|ru = 'Договоры контрагентов';
																		|en = 'Counterparty contracts'; fa = 'قراردادهای طرف حساب';
																		|it = 'Contratti delle controparti';
																		|pl = 'Kontrakty kontrahentów';
																		|tr = 'Cari hesap sözleşmeleri'"));
	EndIf;
	If ThereAreRightsToProjects Then
		EventViewAddedToTree(TreeNode, "Projects", NStr("vi = 'Dự án';
														|ru = 'Проекты';
														|en = 'Projects'; fa = 'پروژه‌ها';
														|it = 'Progetti';
														|pl = 'Projects';
														|tr = 'Projeler'"));
	EndIf;
	If UseBusinessProcessesAndTasks And ThereIsAnAssigneeTaskRight Then
		EventViewAddedToTree(TreeNode, "PerformerTask", NStr("vi = 'Nhiệm vụ khác của người thực hiện';
															|ru = 'Прочие задачи исполнителя';
															|en = 'Other assignee tasks'; fa = 'Other assignee tasks';
															|it = 'Altri obiettivi dell''esecutore';
															|pl = 'Inne zadania wykonawcy';
															|tr = 'Diğer atanan görevleri'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);
	TreeNode = EventViewAddedToTree(EventKinds,"ExecutionOfProductionSchedule", NStr("vi = 'Lịch trình thực hiện';
																					|ru = 'Выполнение графика';
																					|en = 'Schedule execution'; fa = 'Schedule execution';
																					|it = 'Esecuzione del grafico';
																					|pl = 'Wykonanie harmonogramu';
																					|tr = 'Programın gerçekleştirilmesi'"));
	If HaveRightToOrderMaterials And ThereIsRightRegisterOfMaterialOrders Then
		EventViewAddedToTree(TreeNode, "OrderOfMaterialsForProduction", NStr("vi = 'Đơn đề nghị xuất nguyên vật liệu vào sản xuất';
																			|ru = 'Заказы материалов в производство';
																			|en = 'Material orders for shop floor stockroom'; fa = 'سفارش‌های مواد برای انبار کارگاه';
																			|it = 'Ordini dei materiali per la produzione';
																			|pl = 'Zamówienia materiałów na produkcje';
																			|tr = 'Üretimdeki malzemelerin siparişleri'"));
	EndIf;
	CRMLocalization.AddEventTreeToEventCalendarReport(TreeNode);
	DeleteParentTreeNodeIfEmpty(TreeNode);
EndProcedure

&AtServer
Procedure DeleteParentTreeNodeIfEmpty(TreeNode)

	If TreeNode.GetItems().Count() = 0 Then
		EventKinds.GetItems().Delete(TreeNode);
	EndIf;

EndProcedure 

&AtServer
Function EventViewAddedToTree(ParentRow, EventKind, Presentation)

	NewRow = ParentRow.GetItems().Add();
	NewRow.EventKind = EventKind;
	NewRow.Presentation = Presentation;
	Return NewRow

EndFunction

&AtClient
Procedure SetStateReportNotGenerated()
	
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Items.Result.StatePresentation.Text = NStr("vi = 'Chưa lập báo cáo. Hãy nhấn nút ""Lập báo cáo"" để nhận báo cáo.';
												|ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.';
												|en = 'Report is not generated. To generate the report, click ""Generate"".'; fa = 'Report is not generated. To generate the report, click ""Generate"".';
												|it = 'Il report non è stato creato. Fate clic su ""Crea"" per ricevere il rapporto.';
												|pl = 'Raport nie został wygenerowany. Kliknij ""Utwórz"", aby wygenerować raport.';
												|tr = 'Rapor oluşturulmadı. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");
	Items.Result.StatePresentation.Visible = True;
	
EndProcedure

&AtServer
Procedure UpdateCalculationsUpdateReport()
	
	If Report.ThereAreCustomersARAPRequireUpdate Or Report.ThereAreVendorsARAPRequireUpdate Then
		ArrayOfAnalyticsToUpdate = AnalyticsForUpdatingCalculations();
	EndIf;
	
	If Report.ThereAreCustomersARAPRequireUpdate And ArrayOfAnalyticsToUpdate.Count() > 0 Then
		CalculationEnd = EndOfMonth(CurrentSessionDate()) + 1;
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAnalyticsToUpdate;
		ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(CalculationEnd, CalculationAnalysts);
		Report.ThereAreCustomersARAPRequireUpdate = False;
	EndIf;
	
	If Report.ThereAreVendorsARAPRequireUpdate And ArrayOfAnalyticsToUpdate.Count() > 0 Then
		CalculationEnd = EndOfMonth(CurrentSessionDate()) + 1;
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAnalyticsToUpdate;
		ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(CalculationEnd, CalculationAnalysts);
		Report.ThereAreVendorsARAPRequireUpdate = False;
	EndIf;
	
	GenerateReportServer();
	
EndProcedure

&AtServer
Function AnalyticsForUpdatingCalculations()

	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	|	AccountingDimensionByPartners.DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Partner IN(&ArrayOfPartners)";
	
	Query.SetParameter("ArrayOfPartners", Report.PartnersARAPRequireUpdate.UnloadValues());
	
	Return Query.Execute().Unload().UnloadColumn("DimensionKey");
	
EndFunction

&AtClient
Procedure AvailabilityControl()

	Items.UpdateCalculations.Enabled = Report.ThereAreCustomersARAPRequireUpdate Or Report.ThereAreVendorsARAPRequireUpdate;

EndProcedure

#EndRegion
