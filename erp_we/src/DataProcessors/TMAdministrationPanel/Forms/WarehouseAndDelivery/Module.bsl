#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Values of form details
	CompositionOfSetOfConstantsOfForm    = TMCommonUse.GetStructureOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = SystemSettingsCached.GetStructureOfParentConstants(CompositionOfSetOfConstantsOfForm);
	WorkMode = New Structure;
	
	ExternalParentConstants.Insert("UseObjectsVersioning");
	ExternalParentConstants.Insert("UseCustomerInvoiceIntercompany");
	ExternalParentConstants.Insert("UseInventoryConsumptionOrders");
	ExternalParentConstants.Insert("UseAssemblyDisassemblyOrders");
	ExternalParentConstants.Insert("UseTransferOrders");
	ExternalParentConstants.Insert("GenerateFinancialResult");
	
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm",    New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);
	Items.ReviewToUseASeparateSoftwareOrders.Visible = False;
	Items.CommentUseSeparateSecurityForUpOrders.Visible = True;
	// Updating the state of the elements
	SetAvailability();
	SetHeadingsAndToolTipsForUp();
	Items.GoodsIssueNoteGenerationMode.ToolTip =
		Enums.GoodsIssueNoteGenerationModes.FormationModeHint(ConstantsSet.GoodsIssueNoteGenerationMode);
	PurchasesServer.FillInAcceptanceOptionsSettings(Constants.GoodsReceiptOption.Get(),ExecutionOfAnOrder);
	PurchasesServer.FillInListOfAcceptanceOptions(Items.ExecutionOfAnOrder);
	
	DisableHeaders = New Array();
	DisableHeaders.Add(NStr("vi = 'Trước khi ngắt đảm bảo hàng đặt riêng, cần ngắt sử dụng:';
							|ru = 'Перед отключением обособленного обеспечения, необходимо отключить:';
							|en = 'Before disabling the assigned supply, the following features must be disabled:'; fa = 'Before disabling the assigned supply, the following features must be disabled:';
							|it = 'Prima dell''estinzione della garanzia separata, è necessario estinguere:';
							|pl = 'Przed wyłączeniem odosobnionego zabezpieczenia, należy wyłączyć:';
							|tr = 'Ayrıştırılmış tedariki devre dışı bırakmadan önce şunlar devre dışı bırakılmalı:'"));
	If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		DisableHeaders.Add(NStr("vi = '
			|– kế toán chi phí theo tất cả mảng hoạt động';
			|ru = '
			|– учет затрат по всем направлениям деятельности';
			|en = '
			|– cost accounting by lines of business'; fa = '
			|– cost accounting by lines of business';
			|it = '
			|- calcolo delle spese per tutte le aree di attività';
			|pl = '
			|– ewidencja rozchodów wg wszystkich rodzajów działalności';
			|tr = '
			|– tüm iş kollarına göre maliyet muhasebesi'"));
	EndIf;
	GiversAreIncluded = Constants.UseTollManufacturing2_5.Get();
	If GiversAreIncluded Then
		DisableHeaders.Add(NStr("vi = '
			|– sử dụng sản xuất từ nguyên vật liệu gia công (phân hệ ""Bán hàng - Sản xuất từ nguyên liệu gia công"")';
			|ru = '
			|– использование производства из давальческого сырья (раздел ""Продажи - Производство из давальческого сырья"")';
			|en = '
			|– use subcontracting (""Sales - Subcontracting"")'; fa = '
			|– use subcontracting (""Sales - Subcontracting"")';
			|it = '
			|– использование производства из давальческого сырья (раздел ""Продажи - Производство из давальческого сырья"")';
			|pl = '
			|– use subcontracting (""Sales - Subcontracting"")';
			|tr = '
			|– verilen fason hizmetlerinin kullanımı (""Satışlar - Verilen fason hizmetleri"" bölümü)'"));
	EndIf;
	
	If Constants.UseProduction.Get() Then
		DisableHeaders.Add(NStr("vi = '
			|– sử dụng sản xuất riêng (phân hệ ""Sản xuất"")';
			|ru = '
			|– использование собственного производства (раздел ""Производство"")';
			|en = '
			|– use in-house production (""Manufacturing"")'; fa = '
			|– use in-house production (""Manufacturing"")';
			|it = '
			|– использование собственного производства (раздел ""Производство"")';
			|pl = '
			|– use in-house production (""Manufacturing"")';
			|tr = '
			| - şirket içi üretiminin kullanımı (""Üretim"" bölümü)'"));
	EndIf;
	
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") 
			And Constants.OptionOfGoodsAssignmentInSales.Get()
				= Enums.OptionsOfGoodsAssignmentInSales.SalesOrder Then
		DisableHeaders.Add(NStr("vi = '
			| - phương án đặt riêng hàng hóa và dịch vụ theo sơ đồ đại lý ""theo đơn hàng"" (phân hệ ""Bán hàng - Cung cấp dịch vụ đại lý"")';
			|ru = '
			|– вариант обособления товаров и услуг по агентской схеме ""по заказам"" (раздел ""Продажи - Оказание агентских услуг"")';
			|en = '
			|– option of goods and services assignment on agency basis ""against orders"" (section ""Sales - Agent services delivery"")'; fa = '
			|– option of goods and services assignment on agency basis ""against orders"" (section ""Sales - Agent services delivery"")';
			|it = '
			|- variante di separazione articoli e servizi nel regime di agenzia ""per ordini"" (sezione ""Vendite - Fornitura servizi di agenzia"")';
			|pl = '
			|– wariant oddzielenia towarów i usług według schematu agencyjnego ""według zamówień"" (rozdział ""Sprzedaż - Świadczenie usług agencyjnych"")';
			|tr = '
			|– ""siparişlere göre"" acente şemasına göre ürün ve hizmet ayrıştırmasının bir çeşidi (""Satışlar - Acente hizmetlerinin sağlanması"" bölümü)'"));
	EndIf;
	Items.ReviewToUseASeparateSoftwareOrdersShutdown.Title = StrConcat(DisableHeaders);
	
	Items.DistributionCenterFulfillmentComment.Title =
		NStr("vi = 'Chức năng này khả dụng nếu được phép sử dụng ít nhất một trong các dạng chứng từ sau:
			|- Đơn hàng điều chuyển hàng hóa nội bộ (phân hệ ""Kho bãi và giao nhận"")';
			|ru = 'Этот функционал доступен, если разрешено использование хотя бы одного из следующих видов документов:
			|- Заказ на перемещение (раздел ""Склад и доставка"")';
			|en = 'This functionality is available if at least one of the following document kinds is allowed:
			|- Transfer order (section ""Warehouse and delivery"")'; fa = 'This functionality is available if at least one of the following document kinds is allowed:
			|- Transfer order (section ""Warehouse and delivery"")';
			|it = 'Questa funzione è disponibile se è consentito l''utilizzo di almeno uno dei seguenti tipi di documento:
			|- Ordine di spostamento (sezione ""Magazzino e consegna"")';
			|pl = 'Ta funkcja jest dostępna, jeśli dozwolone jest używanie chociażby jednego z następnych rodzajów dokumentów:
			|- Zamówienie na przesunięcie (rozdział ""Magazyn i dostawa"")';
			|tr = 'Bu işlevsellik, aşağıdaki belge türlerinden en az birine izin verildiğinde erişilebilir:
			|- Transfer emri (""Ambar ve teslimat"" bölümü)'");
	Items.DistributionCenterFulfillmentComment.Title = Items.DistributionCenterFulfillmentComment.Title
		+ NStr("vi = '
			|- Đơn đặt nguyên vật liệu vào sản xuất (phân hệ ""Sản xuất"" - ""Sử dụng sản xuất"")';
			|ru = '
			|- Заказ материалов в производство (раздел ""Производство"" — ""Использовать производство"")';
			|en = '
			|- Material order for shop floor stockroom (section ""Manufacturing"" — ""Use manufacturing"")'; fa = '
			|- Material order for shop floor stockroom (section ""Manufacturing"" — ""Use manufacturing"")';
			|it = '
			|- Ordine materiali in produzione (sezione ""Produzione"" - ""Utilizzare produzione"")';
			|pl = '
			|- Zamówienie materiałów do produkcji (rozdział ""Produkcja"" — ""Używaj produkcji"")';
			|tr = '
			|- Üretim için malzeme siparişi (""Üretim"" - ""Üretimi kullan"" bölümü)'");
	Items.CommentUseSeparateSecurityForUpOrders.Title = 
		NStr("vi = 'Chức năng này chỉ khả dụng, nếu được phép sử dụng một trong các dạng chứng từ sau:
				|- Đơn hàng tiêu dùng nội bộ (phân hệ ""Kho bãi và giao hàng"")
				|- Đơn hàng đóng bộ (phân hệ ""Kho bãi và giao hàng"")
				|- Đơn hàng của khách, chế độ ""từ kho và theo đơn hàng"" (phân hệ ""Bán hàng"")
				|- Đề nghị trả hàng, chế độ ""từ kho và theo đơn hàng"" (phân hệ ""Bán hàng"")
				|- Đơn hàng điều chuyển hàng hóa nội bộ (phân hệ ""Kho bãi và giao hàng"")
				|- Đơn hàng đặt gia công (phân hệ ""Sản xuất và sửa chữa"")
				|Và nếu có:
				|- Sử dụng sản xuất bằng các nguồn lực của doanh nghiệp bên ngoài (phân hệ ""Sản xuất - Gia công bên ngoài"")';
				|ru = 'Этот функционал доступен если разрешено использование хотя бы одного из следующих видов документов:
				|- Заказы на внутреннее потребление (раздел ""Склад и доставка"")
				|- Заказы на сборку (раздел ""Склад и доставка"")
				|- Заказы клиента, режим ""со склада и под заказ"" (раздел ""Продажи"")
				|- Заявки на возврат, режим ""со склада и под заказ"" (раздел ""Продажи"")
				|- Заказы на перемещение (раздел ""Склад и доставка"")
				|- Заказы переработчику (раздел ""Производство и ремонты"")
				|А также если:
				|- Используется производство силами сторонней организации (раздел ""Производство - Переработка на стороне"")';
				|en = 'This functionality is available if at least one of the following document kinds is allowed:
				|- Inventory consumption orders (section ""Warehouse and delivery"")
				|- Kitting orders (section ""Warehouse and delivery"")
				|- Sales orders, mode ""from warehouse and against order"" (section ""Sales"")
				|- Return requests, mode ""from warehouse and against order"" (section ""Sales"")
				|- Transfer orders (section ""Warehouse and delivery"")
				|- Subcontracting purchase orders (section ""Production and R&M"")
				|And if: 
				|- Manufacturing by third parties is used (section ""Manufacturing — Subcontracting"")'; fa = 'This functionality is available if at least one of the following document kinds is allowed:
				|- Inventory consumption orders (section ""Warehouse and delivery"")
				|- Kitting orders (section ""Warehouse and delivery"")
				|- Sales orders, mode ""from warehouse and against order"" (section ""Sales"")
				|- Return requests, mode ""from warehouse and against order"" (section ""Sales"")
				|- Transfer orders (section ""Warehouse and delivery"")
				|- Subcontracting purchase orders (section ""Production and R&M"")
				|And if: 
				|- Manufacturing by third parties is used (section ""Manufacturing — Subcontracting"")';
				|it = 'Questa funzione è disponibile in caso di concessione di utilizzo di almeno uno dei seguenti tipi di documento:
				|- Ordini per il consumo interno (sezione ""Magazzino e consegna"")
				|- Ordini di montaggio (sezione ""Magazzino e consegna"")
				|- Ordini cliente, modalità ""Dal magazzino e in ordine"" (sezione ""Vendite"")
				|- Richieste di reso, modalità ""Dal magazzino e in ordine"" (sezione ""Vendite"")
				|- Ordini di trasferimento (sezione ""Magazzino e consegna"")
				|- Ordini all''elaboratore (sezione ""Produzione e riparazione"")
				|Oppure se:
				|- Viene utilizzata la produzione di terze parti (sezione ""Produzione - Elaborazione da terzi"")';
				|pl = 'Ta funkcja jest dostępna jeśli dozwolone jest używanie przynajmniej jednego z następujących rodzajów dokumentów:
				|- Zamówienia na konsumpcję wewnętrzną (rozdział - ""Magazyn i dostawa"")
				|- Zamówienia na montaż (rozdział - ""Magazyn i dostawa"")
				|- Zamówienia klienta, tryb ""z magazynu i na zamówienie"" (rozdział - ""Sprzedaż"")
				|- Wnioski o zwrot, tryb ""z magazynu i na zamówienie"" (rozdział - ""Sprzedaż"")
				|- Zamówienia przemieszczenia (rozdział - ""Magazyn i dostawa"")
				|Zamówienie przetwórcom (""Rozdział ""Produkcja i naprawy"")
				|A także jeśli:
				|- jest używana produkcja w outsourcingu (rozdział ""Przetwarzanie w outsourcingu"")';
				|tr = 'Bu işlevsellik, aşağıdaki belge türlerinden en az birinin kullanımına izin veriliyorsa erişilebilir:
				|- İç tüketim siparişleri (""Ambar ve teslimat"" bölümü)
				|- Montaj emirleri (""Ambar ve teslimat"" bölümü)
				| - Satış siparişleri, ""stoktan ve sipariş üzerine"" modu (""Satışlar"" bölümü)
				|- İade talepleri, ""stoktan ve sipariş üzerine"" modu (""Satışlar"" bölümü)
				|- Transfer siparişleri (""Ambar ve teslimat"" bölümü) )
				| - Fason satın alma siparişi (""Üretim ve onarımlar"" bölümü)
				|Ayrıca:
				|- Üçüncü bir iş yerlerinin desteği ile üretim kullanılıyorsa (""Üretim - Fason üretim"" bölümü)'");
	Items.CommentUseSeparateSecurityForUpOrders.Title =
		Items.CommentUseSeparateSecurityForUpOrders.Title
			+ NStr("vi = '
				|- Sử dụng sản xuất (phân hệ ""Sản xuất"")
				|- Sử dụng quản lý sửa chữa (phân hệ ""Tài sản dài hạn - Quản lý sửa chữa"")';
				|ru = '
				|- Используется производство (раздел ""Производство"")
				|- Используется управление ремонтами (раздел ""Внеоборотные активы - Управление ремонтами"")';
				|en = '
				|- Manufacturing is used (section ""Manufacturing"")
				|- R&M management is used (section ""Asset management — R&M management"")'; fa = '
				|- Manufacturing is used (section ""Manufacturing"")
				|- R&M management is used (section ""Asset management — R&M management"")';
				|it = '
				|- Viene utilizzata la produzione (sezione ""Produzione"")
				|- Viene utilizzata la gestione delle riparazione (Sezione ""Attività non correnti - Gestione riparazioni"")';
				|pl = '
				|- Używana jest produkcja (rozdział ""Produkcja"")
				|- Używane jest zarządzanie naprawami (rozdział ""Aktywa stałe - Zarządzanie naprawami"")';
				|tr = '
				|- Üretim kullanılır (""Üretim"" bölümü)
				|- Onarım yönetimi kullanılır (""Duran varlıklar - Onarım yönetimi"" bölümü)'");
	SystemSettingsLocalization.WhenCreatedOnServer_WarehouseAndDelivery(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
// The alert handler of the form.
//
// Parameters:
//	Eventname - String - only the event record_setconstant generated by the administration panels is processed.
//	The parameter - Structure - contains the names of constants subordinate to the changed constant that "caused" the alert.
//	Source - String - the name of the changed constant that "caused" the alert.
//
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangelogStorageModeChanged" Then
		EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION();
	EndIf;
	
	If EventName = "BeginningOfTransitionToDelivery25" Then
		
		TransitionData = DeliveryTransitionStatusData25();
		TransitionData.TransitionIsRunning = True;
		TransitionData.DataProcessed = False;
		
		SetVisibilityOfTransitionElementsToDelivery25(False, TransitionData);
		
	EndIf;
	
	If EventName = "ProcessedDataForSwitchingToDelivery25" Then
		
		TransitionData = DeliveryTransitionStatusData25();
		TransitionData.TransitionIsRunning = True;
		TransitionData.DataProcessed = True;
		
		SetVisibilityOfTransitionElementsToDelivery25(False, TransitionData);
		
	EndIf;
	
	If EventName = "EndOfTransitionToDelivery25" Then
		
		SetAvailability();
		ShowNotificationAboutEndOfTransitionToDelivery25();
		
	EndIf;
	
	If EventName <> "Write_ConstantsSet" Then
		Return; // such events are not processed
	EndIf;
	
	// If it is a changed constant located in a different form and affecting the values of the constants of this form,
	// then we will read the values of the constants and update the elements of this form.
	If WorkMode.ExternalParentConstants.Property(Source)
	 Or (TypeOf(Parameter) = Type("Structure")
	 		And TMCommonUseClientServer.GetSharedKeysOfStructures(
	 			Parameter, WorkMode.ExternalParentConstants).Count() > 0) Then
		
		ThisForm.Read();
		SetAvailability();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OtherPostingOfGoodsInCaseOfChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseWarehouseManagementSystemOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseDeliveryManagementOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	
	NewSettingValue =  ConstantsSet.UseDeliveryManagement;
	If NewSettingValue = True Then
		
		SetVisibilityOfTransitionElementsToDelivery25();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditDeliveryAddressesOnlyInDialogBoxOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure LabelTemplateForDeliveryOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure UseGoodsQualityControlOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseGoodsQualityResearchOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure LabelTemplateForDeliveryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure(
		"Purpose",
		PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery"));
	
	LabelsTemplate = Undefined;
	
	OpenForm("Catalog.LabelAndPriceTagTemplates.ChoiceForm", New Structure("Filter", Filter),,,,, New CallbackDescription("LabelTemplateForDeliveryStartChoiceCompletion", ThisObject, New Structure("Item", Item)), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
// 	Result - CatalogRef.LabelAndPriceTagTemplates
// 	AdditionalParameters - Structure:
//		*Item - FormField
&AtClient
Procedure LabelTemplateForDeliveryStartChoiceCompletion(Result, AdditionalParameters) Export
    
    Item = AdditionalParameters.Item;
    
    
    LabelsTemplate =
    Result;
    If LabelsTemplate = Undefined Then
        Return;
    EndIf;
    
    ConstantsSet.LabelTemplateForDelivery = LabelsTemplate;
    
    Attachable_OnChangeAttribute(Item, False);

EndProcedure

&AtClient
Procedure DeliveryPlanningOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure DeliveryPlanningClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PackingListLabelTemplateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure(
		"Purpose",
		PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel"));
	
	LabelsTemplate = Undefined;

	
	OpenForm("Catalog.LabelAndPriceTagTemplates.ChoiceForm", New Structure("Filter", Filter),,,,, New CallbackDescription("PackingListLabelTemplateStartChoiceCompletion", ThisObject, New Structure("Item", Item)), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
// 	Result - CatalogRef.LabelAndPriceTagTemplates
// 	AdditionalParameters - Structure:
//		*Item - FormField
&AtClient
Procedure PackingListLabelTemplateStartChoiceCompletion(Result, AdditionalParameters) Export
    
    Item = AdditionalParameters.Item;
    
    
    LabelsTemplate =
    Result;
    If LabelsTemplate = Undefined Then
        Return;
    EndIf;
    
    ConstantsSet.PackingListLabelTemplate = LabelsTemplate;
    
    Attachable_OnChangeAttribute(Item, False);

EndProcedure

&AtClient
Procedure UseSeveralWarehousesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseGoodsTransferOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseTransferOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseTransferAgainstSeveralOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseGoodsTransferStatusesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseStatusesOfTransferOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseGoodsAssemblyStatusesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseStatusesOfAssemblyOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TransferGoodsOfOtherCompaniesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseInventoryConsumptionOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseInventoryConsumptionOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseStatusesOfInventoryConsumptionOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipmentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseProvisionRequestsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionOfGoodsAssignmentInInventoryConsumptionOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DoNotCloseTransferOrdersWithoutCompleteShipmentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionOfGoodslAssignmentInTransferOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseInventoryConsumptionForMultipleOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure AssemblyDisassemblyWhenChanging(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseAssemblyDisassemblyOrdersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DoNotCloseAssemblyOrdersWithoutCompleteShipmentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionOfGoodsAssignmentInAssemblyOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UsePackingListsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TheModesOfExecutionOverheadWhenChanging(Item)	
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OrderOfMRMKScanningOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure TheModeOfFormationOfTheReceiptsWhenYouChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	WhenChangingModeOfFormationOfIncomingOrdersOnServer();
	
EndProcedure

&AtServer
Procedure WhenChangingModeOfFormationOfIncomingOrdersOnServer()
	
	Items.GoodsIssueNoteGenerationMode.ToolTip =
		Enums.GoodsIssueNoteGenerationModes.FormationModeHint(ConstantsSet.GoodsIssueNoteGenerationMode);
EndProcedure

&AtClient
Procedure TheDesignModeOfOverheadClearance(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure OrderOfMRMKScanningClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure GoodsIssueNoteGenerationModeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseOrderSupplyWithAssignmentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure AllowAssignmentOfGoodsBeyondDemandOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure GenerateOrdersByDemandsSimplifiedOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure FormationOfOrdersForTheNeedsOfTheExtendedOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ShipmentsFromAWarehouseToRemoteWarehousesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ShipmentsFromRemoteWarehousesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionOfOrderingNeedsByPriorityAndDateOfShipmentOfOrderOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure OptionOfOrderingNeedsByPriorityAndDateOfDocumentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ControlBalanceOfGoodsToBeReservedUponReceiptOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ExecutionOfAnOrderOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ExecutionOfAnOrderClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SeparationOptionCleaningUp(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseCoordinationOfDomesticConsumptionOrdersWhenChanging(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DisplayLineOfBusinessOfIGCOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ProcedureOfInvoiceAndGoodsIssueNoteRegistrationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	ChangeIsAvailable = ChangesInOrderOfExecutionOfInvoicesAndOrdersAreAvailable(
		ConstantsSet.ProcedureOfInvoiceAndGoodsIssueNoteRegistration);
	
	If Not ChangeIsAvailable Then
		
		StandardProcessing = False;
		EstablishAvailabilityOfChangesInOrderOfExecutionOfInvoicesAndOrders();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers 

&AtClient
Procedure AppointThoseResponsibleForApprovingOrdersForDomesticConsumption(Command)
	OpenForm("InformationRegister.TaskPerformers.Form.PerformersOfRoleWithAddressingObject", 
	New Structure("MainAddressingObject,Role", 
		Undefined, 
		PredefinedValue("Catalog.PerformerRoles.ApproverInventoryConsumptionOrder")));
EndProcedure 

&AtClient
Procedure EnableVersioningOfOrdersForDomesticConsumption(Command)
	
	Result = New Structure;
	SaveAttributeValue("EnableVersioningOfOrdersForDomesticConsumption", Result);
	
	If Result.Property("VersioningOfOrdersForInternalConsumptionIsIncluded") Then
		
		If Result.VersioningOfOrdersForInternalConsumptionIsIncluded Then
			Explanation = NStr("vi = 'Đối với đơn hàng tiêu dùng nội bộ có đặt phương án quản lý phiên bản ""Đánh số phiên bản khi kết chuyển""';
								|ru = 'Для заказов на внутреннее потребление установлен вариант версионирования ""Версионировать при проведении""';
								|en = 'The ""Version on posting"" versioning option is set for inventory consumption orders'; fa = 'The ""Version on posting"" versioning option is set for inventory consumption orders';
								|it = 'Для заказов на внутреннее потребление установлен вариант версионирования ""Версионировать при проведении""';
								|pl = 'The ""Version on posting"" versioning option is set for inventory consumption orders';
								|tr = 'İç tüketime yönelik siparişler için sürüm oluşturma seçeneği ""Kaydetme sırasında sürüm oluştur"" olarak ayarlanmıştır.'");
		Else
			Explanation = NStr("vi = 'Đối với đơn hàng tiêu dùng nội bộ, đã bật quản lý phiên bản';
								|ru = 'Для заказов на внутреннее потребление версионирование уже было включено';
								|en = 'Versioning is already enabled for inventory consumption orders'; fa = 'Versioning is already enabled for inventory consumption orders';
								|it = 'Для заказов на внутреннее потребление версионирование уже было включено';
								|pl = 'Versioning is already enabled for inventory consumption orders';
								|tr = 'Sürüm oluşturma, stok tüketim siparişleri için zaten etkinleştirildi'");
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Đã bật sử dụng quản lý phiên bản';
									|ru = 'Версионирование включено';
									|en = 'Versioning enabled'; fa = 'Versioning enabled';
									|it = 'Il versionamento è abilitato';
									|pl = 'Wersjowanie włączone';
									|tr = 'Sürüm oluşturma etkin'"),, Explanation, PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure DisableMonitoringOfGoodsReservesOnOrders(Command)
	
	DisableMonitoringOfGoodsReservesOnOrdersServer();
	
EndProcedure

&AtClient
Async Procedure GoToDelivery25(Command)
	
	TransitionStatus = StatusOfTransitionToDelivery25();
	
	If TransitionStatus.TransitionIsComplete Then
		
		InformAboutCompletedTransitionToDelivery25();
		SetAvailability();
		
	ElsIf Not TransitionStatus.TransitionIsRunning Then 
		
		WarningButtons = New ValueList;
		WarningButtons.Add(DialogReturnCode.OK, "Continue");
		WarningButtons.Add(DialogReturnCode.Cancel);
		
		QueryText = TextOfWarningForStartOfTransitionToD25();
		
		Response = Await DoQueryBoxAsync(QueryText, WarningButtons,, DialogReturnCode.OK);
		If Response = DialogReturnCode.OK Then
			
			StartSwitchingToDelivery25AfterVerification();
			
		EndIf;
		
	ElsIf Not TransitionStatus.DataProcessed Then
		
		OpenForm("DataProcessor.WizardOfMigrationToDeliveryVersion25.Form");
		SetAvailability();
		
	Else
		
		InformAboutNeedToEndTransitionToDelivery25();
		SetAvailability();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckStateOfTransitionToDelivery25(Command)
	
	TransitionStatus = StatusOfTransitionToDelivery25();
	
	If TransitionStatus.TransitionIsComplete Then
		
		InformAboutCompletedTransitionToDelivery25();
		SetAvailability();
		
	ElsIf TransitionStatus.TransitionIsRunning
			And Not TransitionStatus.DataProcessed Then
		
		OpenForm("DataProcessor.WizardOfMigrationToDeliveryVersion25.Form");
		
	Else
		
		InformAboutNeedToEndTransitionToDelivery25();
		SetAvailability();
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CompleteTransitionToDelivery25(Command)
	
	TransitionStatus = StatusOfTransitionToDelivery25();
	
	If TransitionStatus.TransitionIsComplete Then
		
		InformAboutCompletedTransitionToDelivery25();
		
	ElsIf TransitionStatus.TransitionIsRunning
			And TransitionStatus.DataProcessed Then
		
		ConnectionsInformation = ConnectionsInformation();
		If ConnectionsInformation.HasActiveConnections Then
			
			MessageText = GoodsDeliveryClientServer.TextForCheckingActiveSessions();
			DoMessageBoxAsync(MessageText);
			
			Return;
			
		EndIf;
		
		CompleteTransition = Await GoodsDeliveryClient.CheckPossibilityOfSwitchingToDelivery25Async();
		
		If CompleteTransition Then
			
			CompleteTransitionToDelivery25AtServer();
			
			RefreshInterface = True;
			RefreshApplicationInterface();
			SetAvailability();
			ShowNotificationAboutEndOfTransitionToDelivery25();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
	SystemSettingsClientLocalization.WhenChangingBankDetails_WarehouseAndDelivery(Item, ThisObject);
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure StartSwitchingToDelivery25AfterVerification()
	
	BeginningOfTransitionIsAvailable = Await GoodsDeliveryClient.CheckPossibilityOfSwitchingToDelivery25Async();
	
	If BeginningOfTransitionIsAvailable Then
		
		QueryText = NStr("vi = 'Hệ thống sẽ bắt đầu quá trình chuyển đổi sang chức năng quản lý giao nhận phiên bản 2.5. Thời gian thực hiện phụ thuộc vào số lượng bạn hàng và kho đã khai báo địa chỉ, cũng như mức độ tải của thiết bị.
								  |Tiếp tục?';
								  |ru = 'Будет запущена операция перехода на управление доставкой версии 2.5. Длительность операции зависит от количества партнеров и складов с заполненными адресами, а также от загруженности оборудования.
								  |Продолжить?';
								  |en = 'Migration to delivery management version 2.5 will be launched. Its duration depends on the number of partners and warehouses with filled addresses, as well as on the equipment workload.
								  |Continue?'; fa = 'Migration to delivery management version 2.5 will be launched. Its duration depends on the number of partners and warehouses with filled addresses, as well as on the equipment workload.
								  |Continue?';
								  |it = 'Migration to delivery management version 2.5 will be launched. Its duration depends on the number of partners and warehouses with filled addresses, as well as on the equipment workload.
								  |Continue?';
								  |pl = 'Migration to delivery management version 2.5 will be launched. Its duration depends on the number of partners and warehouses with filled addresses, as well as on the equipment workload.
								  |Continue?';
								  |tr = 'Sürüm 2.5 teslimat yönetimine geçiş işlemi başlatılacaktır. İşlemin süresi, adresleri doldurulmuş iş ortaklarının ve ambarların sayısına ve donanım yüküne bağlıdır.
								  |Devam edilsin mi?'");
		
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
		If Response = DialogReturnCode.Yes Then
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("StartingTransition", True);
			
			OpenForm("DataProcessor.WizardOfMigrationToDeliveryVersion25.Form", OpeningParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateStatusOfTransitionToDelivery25()
	
	Status = StatusOfTransitionToDelivery25();
	
	If Status.TransitionIsComplete Then
		
		DetachIdleHandler("UpdateStatusOfTransitionToDelivery25");
		
		Read();
		SetAvailability();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InformAboutNeedToEndTransitionToDelivery25()
	
	MessageText = NStr("vi = 'Đã xử lý dữ liệu để chuyển sang quản lý giao nhận phiên bản 2.5.
								|Cần xác nhận để hoàn tất việc chuyển.';
								|ru = 'Данные для перехода на управление доставкой версии 2.5 обработаны.
								|Требуется подтверждение для завершения перехода.';
								|en = 'Data for migrating to delivery management version 2.5 is processed.
								|Confirmation is required to complete migration.'; fa = 'Data for migrating to delivery management version 2.5 is processed.
								|Confirmation is required to complete migration.';
								|it = 'Data for migrating to delivery management version 2.5 is processed.
								|Confirmation is required to complete migration.';
								|pl = 'Data for migrating to delivery management version 2.5 is processed.
								|Confirmation is required to complete migration.';
								|tr = 'Sürüm 2.5 teslimat yönetimine geçiş verileri işlendi.
								|Geçişi tamamlamak için onay gerekiyor.'");
	
	CommonClient.MessageToUser(MessageText,, Items.CompleteTransitionToDelivery25.Name);
	
EndProcedure

&AtClient
Procedure InformAboutCompletedTransitionToDelivery25()
	
	MessageText = NStr("vi = 'Đã chuyển sang quản lý giao nhận phiên bản 2.5.';
						|ru = 'Переход на управление доставкой версии 2.5 уже выполнен.';
						|en = 'Migration to delivery version 2.5 is already completed.'; fa = 'Migration to delivery version 2.5 is already completed.';
						|it = 'Migration to delivery version 2.5 is already completed.';
						|pl = 'Migration to delivery version 2.5 is already completed.';
						|tr = 'Sürüm 2.5 teslimat yönetimine geçiş zaten gerçekleştirildi.'");
	CommonClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure ShowNotificationAboutEndOfTransitionToDelivery25()
	
	MessageText = NStr("vi = 'Đã hoàn tất thành công chuyển sang giao nhận phiên bản 2.5';
						|ru = 'Переход на доставку версии 2.5 завершен успешно';
						|en = 'Migration to delivery version 2.5 completed successfully'; fa = 'Migration to delivery version 2.5 completed successfully';
						|it = 'Migration to delivery version 2.5 completed successfully';
						|pl = 'Migration to delivery version 2.5 completed successfully';
						|tr = 'Sürüm 2.5 teslimat yönetimine geçiş başarıyla tamamlandı'");
	ShowUserNotification(MessageText,,,, UserNotificationStatus.Information);
	
EndProcedure

&AtClient
Function TextOfWarningForStartOfTransitionToD25()
	
	Text = NStr("vi = 'Trong phiên bản Giao nhận 2.5:
		|- Chỉ hỗ trợ chức năng giao nhận đối với các chứng từ Đơn hàng của khách, Giao hàng và cung cấp dịch vụ, Giao hàng cho khách (giao hàng đi từ kho của doanh nghiệp).
		|- Không hỗ trợ làm việc với phiếu giao hàng cho bên vận chuyển.  
		|- Không hỗ trợ việc điền các thiết lập giao nhận khi xử lý đơn hàng từ các sàn thương mại điện tử.
		|- Đối với kho sử dụng sơ đồ hai pha, việc tập hợp hàng sau khi lập kế hoạch giao nhận chỉ được hỗ trợ khi trình tự lập hóa đơn và phiếu được thiết lập là ""Đầu tiên là đơn hàng, sau đó là phiếu kho và hóa đơn"".
		|
		|Trước khi chuyển sang phiên bản mới, nên thực hiện các bước sau:
		|- Hoàn tất việc giao nhận cho tất cả các lệnh giao hàng (khi chuyển sang ""Giao nhận 2.5"", hệ thống không chuyển dữ liệu về các kế hoạch giao nhận đã được lập từ phiên bản trước).
		|-Đối với các nhiệm vụ vận chuyển đã hoàn thành, đánh dấu ""Đã giao nhận tất cả hàng hóa"" tại từng điểm trên lộ trình.
		|- Giao tất cả hàng hóa từ kho có sử dụng sơ đồ hai pha với trình tự tập hợp ""Tập hợp hàng hóa theo thứ tự giao nhận"" theo lệnh có dự tính giao nhận.';
		|ru = 'В версии доставки 2.5:
		|- Поддерживается доставка только в документах Заказ клиента, Реализация товаров и услуг, Отгрузка товаров клиенту (исходящая доставка с нашего склада).
		|- Не поддерживается работа с поручениями экспедиторам.  
		|- Не поддерживается заполнение настроек доставки при обработке заказов торговых площадок.
		|- Сборка на ордерном складе после планирования доставки поддерживается, если порядок оформления накладных и ордеров ""Сначала заказы, затем ордера и накладные"".
		|
		|Перед переходом рекомендуется:
		|- Завершить доставку по всем распоряжениям (при переходе на версию ""Доставка 2.5"" не выполняется перенос данных по запланированной доставке из предыдущей версии).
		|- В завершенных заданиях на перевозку отметить ""Все товары доставлены"" по пунктам маршрута.
		|- Отгрузить все товары с ордерных складов с порядком сборки ""Собирать товары в порядке доставки"" по распоряжениям с запланированной доставкой.';
		|en = 'In delivery version 2.5:
		|- Delivery is supported only in the Sales order, Customer invoice, and Goods shipment to customer (delivery from our warehouse) documents.
		|- Delivery requests are not supported.
		|- Filling in the delivery settings when processing marketplace orders is not supported.
		|- Order picking after delivery planning is supported if the procedure of sales invoice and goods issue registration is ""Orders first, then goods issues and invoices"".
		|
		|Before migration:
		|- Complete the delivery under all references (when switching to Delivery 2.5, the planned delivery data is not transferred from the previous version).
		|- In completed itineraries, mark all goods as delivered at route points.
		|- Ship all goods from warehouses with the ""Pick goods according to the delivery procedure"" option for references with planned delivery.'; fa = 'In delivery version 2.5:
		|- Delivery is supported only in the Sales order, Customer invoice, and Goods shipment to customer (delivery from our warehouse) documents.
		|- Delivery requests are not supported.
		|- Filling in the delivery settings when processing marketplace orders is not supported.
		|- Order picking after delivery planning is supported if the procedure of sales invoice and goods issue registration is ""Orders first, then goods issues and invoices"".
		|
		|Before migration:
		|- Complete the delivery under all references (when switching to Delivery 2.5, the planned delivery data is not transferred from the previous version).
		|- In completed itineraries, mark all goods as delivered at route points.
		|- Ship all goods from warehouses with the ""Pick goods according to the delivery procedure"" option for references with planned delivery.';
		|it = 'In delivery version 2.5:
		|- Delivery is supported only in the Sales order, Customer invoice, and Goods shipment to customer (delivery from our warehouse) documents.
		|- Delivery requests are not supported.
		|- Filling in the delivery settings when processing marketplace orders is not supported.
		|- Order picking after delivery planning is supported if the procedure of sales invoice and goods issue registration is ""Orders first, then goods issues and invoices"".
		|
		|Before migration:
		|- Complete the delivery under all references (when switching to Delivery 2.5, the planned delivery data is not transferred from the previous version).
		|- In completed itineraries, mark all goods as delivered at route points.
		|- Ship all goods from warehouses with the ""Pick goods according to the delivery procedure"" option for references with planned delivery.';
		|pl = 'In delivery version 2.5:
		|- Delivery is supported only in the Sales order, Customer invoice, and Goods shipment to customer (delivery from our warehouse) documents.
		|- Delivery requests are not supported.
		|- Filling in the delivery settings when processing marketplace orders is not supported.
		|- Order picking after delivery planning is supported if the procedure of sales invoice and goods issue registration is ""Orders first, then goods issues and invoices"".
		|
		|Before migration:
		|- Complete the delivery under all references (when switching to Delivery 2.5, the planned delivery data is not transferred from the previous version).
		|- In completed itineraries, mark all goods as delivered at route points.
		|- Ship all goods from warehouses with the ""Pick goods according to the delivery procedure"" option for references with planned delivery.';
		|tr = 'Teslimat sürümü 2.5’te:
		|- Yalnızca Satış siparişi, Ürün ve hizmet satışı, Müşteriye ürün sevkiyatı (ambarımızdan giden teslimat) belgelerinde teslimat desteklenir. 
		| - Nakliyeci talimatlarıyla çalışma desteklenmez. 
		| - Pazaryerleri siparişlerinin işlenmesinde teslimat ayarlarının doldurulması desteklenmez. 
		| - İrsaliye ve sipariş fişlerinin düzenlenme sırası ""Önce siparişler, ardından emirler ve irsaliyeler"" ise, teslimat planlandıktan sonra emir ambarında toplama desteklenir. 
		|
		| Geçiş öncesinde aşağıdakiler önerilir: 
		| - Tüm talimatlardaki teslimatları tamamlayın (""Teslimat 2.5"" sürümüne geçişte, önceki sürümden planlanmış teslimat verileri aktarılmaz). 
		| - Tamamlanmış nakliye görevlerinde rota noktaları için ""Tüm ürünler teslim edildi"" seçeneğini işaretleyin. 
		| - Planlanan teslimat talimatlarına göre ""Ürünleri teslimat sırasına göre topla"" toplama sırasıyla tüm ürünleri emir ambarından sevk edin.'");
	
	Return Text;
	
EndFunction

#EndRegion

#Region ServerCall

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute, New Structure);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Function SaveAttributeValue(DataPathAttribute, Result)
	
	// Storing the values of the details that are not directly related to the constants (in a one-to-one relationship).
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	// Definition of the constant name.
	ConstantName = "";
	If StrStartsWith(Lower(DataPathAttribute), Lower("ConstantsSet.")) Then
		// If the path to the data of the props is specified through the "Setconstant".
		NameParts = StrSplit(DataPathAttribute, ".");
		ConstantName = NameParts[1];
	Else
		// Defining the name and recording the value of the props in the corresponding constant from the "Setconstant".
		// It is used for those form details that are directly related to constants (in a one-to-one relationship).
		If DataPathAttribute = "GenerationOfOrdersByDemands" Then
			
			ConstantsSet.UseAdvancedDemandFulfillment = GenerationOfOrdersByDemands = 1;
			ConstantName = "UseAdvancedDemandFulfillment";
			
		ElsIf DataPathAttribute = "DistributionCenterFulfillmentOption" Then
			
			ConstantsSet.OptimizeDistributionCenterInventory = DistributionCenterFulfillmentOption = 1;
			ConstantName = "OptimizeDistributionCenterInventory";
			
		ElsIf DataPathAttribute = "EnableVersioningOfOrdersForDomesticConsumption" Then
			
			ConstantsSet.UseObjectsVersioning = True;
			ConstantName = "UseObjectsVersioning";
			
		EndIf;
		
	EndIf;
		
	// Saving the value of a constant.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		
		If SystemSettingsCached.ThereAreSubordinateConstants(ConstantName, ConstantValue) Then
			ThisForm.Read();
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.GoodsIssueNoteGenerationMode" Then
		
		GoodsIssueNotesAreGeneratedByManager  = False;
		
		If ConstantsSet.GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.Automatically Then	
			Catalogs.Warehouses.EnableUseOfSpendingOrderStatuses();
			WarehousesServer.StartingQueueFormationAndReissuingSpendingOrders();	
		ElsIf ConstantsSet.GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.ByManager Then
			GoodsIssueNotesAreGeneratedByManager = True;	
		EndIf;
		
		If Constants.GoodsIssueNotesAreGeneratedByManager.Get() <> GoodsIssueNotesAreGeneratedByManager Then
			Constants.GoodsIssueNotesAreGeneratedByManager.Set(GoodsIssueNotesAreGeneratedByManager);
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.ProcedureOfInvoiceAndGoodsIssueNoteRegistration" Then
		If ConstantsSet.GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.Automatically Then	
			WarehousesServer.StartingQueueFormationAndReissuingSpendingOrders();	
		EndIf;
	EndIf;
	
	If DataPathAttribute = "ExecutionOfAnOrder" Then
		
		Constants.GoodsReceiptOption.Set(PurchasesServer.GetOptionsForAcceptanceBySettings(ExecutionOfAnOrder, "Divided"));
		
	EndIf;
	
	If DataPathAttribute = "EnableVersioningOfOrdersForDomesticConsumption" Then
		
		ObjectsForVersioning = New Map;
		If ConstantsSet.UseApprovalOfInventoryConsumptionOrders Then
			ObjectsForVersioning.Insert("Document.InventoryConsumptionOrder", "VersionizeOnPost");
		EndIf;
		
		Result.Insert("VersioningOfOrdersForInternalConsumptionIsIncluded",
			TMCommonUse.EnableObjectsVersioning(ObjectsForVersioning));
		
		EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION();
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.OptionOfOrderingDemandsByOrdersForSupply"
			Or DataPathAttribute = "ConstantsSet.ControlBalanceOfGoodsToBeReservedUponReceipt" Then
			
		// Switching these settings affects disabling the deferred provision of orders with the
		// "Reserve as received" action. It is necessary to bring the Registered Records of existing orders in line
		// with the Cur value of the setting.
		InventoryAllocation.LaunchBackgroundTaskToUpdateNeedsAlongProvisionBoundary();
		
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION()
	
	UseObjectVersioning = TMCommonUse.UseObjectVersioning("Document.InventoryConsumptionOrder");
	Items.EnableVersioningOfOrdersForDomesticConsumption.Enabled =
		ConstantsSet.UseApprovalOfInventoryConsumptionOrders
		And (Not ConstantsSet.UseObjectsVersioning
			Or Not UseObjectVersioning);
			
	If Not UseObjectVersioning Then
		Items.EnableVersioningOfOrdersForDomesticConsumption.Title = NStr("vi = 'Bật sử dụng quản lý phiên bản';
																			|ru = 'Включить версионирование';
																			|en = 'Track versions'; fa = 'پیگیری نسخه‌ها';
																			|it = 'Abilitare versionamento';
																			|pl = 'Włącz wersjonowanie';
																			|tr = 'Sürüm oluşturmayı etkinleştir'");
	ElsIf ConstantsSet.UseObjectsVersioning Then
		Items.EnableVersioningOfOrdersForDomesticConsumption.Title = NStr("vi = 'Đã bật sử dụng quản lý phiên bản';
																			|ru = 'Версионирование включено';
																			|en = 'Versioning enabled'; fa = 'Versioning enabled';
																			|it = 'Il versionamento è abilitato';
																			|pl = 'Wersjowanie włączone';
																			|tr = 'Sürüm oluşturma etkin'");
		Items.EnableVersioningOfOrdersForDomesticConsumption.Font = New Font();
	Else
		Items.EnableVersioningOfOrdersForDomesticConsumption.Title = NStr("vi = 'Bật sử dụng quản lý phiên bản (đã ngắt tùy chọn ""Lưu lịch sử thay đổi"")';
																			|ru = 'Включить версионирование (отключена опция ""Хранить историю изменений"")';
																			|en = 'Track versions (the ""Keep change history"" option is disabled)'; fa = 'Track versions (the ""Keep change history"" option is disabled)';
																			|it = 'Включить версионирование (отключена опция ""Хранить историю изменений"")';
																			|pl = 'Track versions (the ""Keep change history"" option is disabled)';
																			|tr = 'Sürüm oluşturmayı etkinleştir (""Değişiklik geçmişini sakla"" seçeneği devre dışı bırakıldı)'");
		Items.EnableVersioningOfOrdersForDomesticConsumption.Font = New Font();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "" Then
		
		UpdateLabelOfDisableMonitoringOfItemReservesForOrdersButton(
			SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
		
		YouCanUseSoftware =
			Constants.UseShipmentByRowsInSalesOrder.Get()
			Or Constants.UseInventoryConsumptionOrders.Get()
			Or Constants.UseTransferOrders.Get()
			Or Constants.UseAssemblyDisassemblyOrders.Get();
		YouCanUseSoftware = YouCanUseSoftware
			Or Constants.UseProduction.Get()
			Or Constants.UseSubcontractOrders2_5.Get()
			Or Constants.UseRMManagement.Get();
		ItIsForbiddenToDisableIsolation = Constants.UseOrderSupplyWithAssignment.Get()
										And (GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
											Or GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") 
												And Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
		ItIsForbiddenToDisableIsolation = Constants.UseOrderSupplyWithAssignment.Get()
										And (Constants.UseTollManufacturing2_5.Get()
											Or Constants.UseProduction.Get()
											Or GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
											Or GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") 
												And Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);											

		Items.UseOrderSupplyWithAssignment.Enabled							 = YouCanUseSoftware And Not ItIsForbiddenToDisableIsolation;
		Items.TheGroupCanUseSeparateOrderSecurity.Visible			 = Not YouCanUseSoftware And Not ItIsForbiddenToDisableIsolation;
		Items.GroupCommentUseSeparateOrderProvisioningDisable.Visible = ItIsForbiddenToDisableIsolation;
		
		// Updating the separation options
		AreasOfActivityAreUsed = ConstantsSet.GenerateFinancialResult
			And Not GetFunctionalOption("TradeManagement");
		
		// Move
		SelectionListItem = Items.OptionOfGoodslAssignmentInTransfer.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfGoodslAssignmentInTransfer.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfGoodslAssignmentInTransfer.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfGoodslAssignmentInTransfer.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfGoodslAssignmentInTransfer.ChoiceList.Delete(SelectionListItem);
		EndIf;
		
		// Assembly(disassembly)
		SelectionListItem = Items.OptionOfGoodsAssignmentInAssembly.ChoiceList.FindByValue(
			PredefinedValue("Enum.OptionsOfGoodsAssignmentInAssembly.LineOfBusiness"));
		
		If AreasOfActivityAreUsed And SelectionListItem = Undefined Then
			Items.OptionOfGoodsAssignmentInAssembly.ChoiceList.Insert(0,
				PredefinedValue("Enum.OptionsOfGoodsAssignmentInAssembly.LineOfBusiness"));
		ElsIf Not AreasOfActivityAreUsed And SelectionListItem <> Undefined Then
			Items.OptionOfGoodsAssignmentInAssembly.ChoiceList.Delete(SelectionListItem);
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseOrderSupplyWithAssignment" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseOrderSupplyWithAssignment;
		
		Items.AllowAssignmentOfGoodsBeyondDemand.Enabled = ConstantValue;
		
		Items.OptionOfGoodsAssignmentInInventoryConsumption.Visible = ConstantValue
			And Not GetFunctionalOption("TradeManagement");
		Items.OptionOfGoodslAssignmentInTransfer.Visible = ConstantValue;
		Items.OptionOfGoodsAssignmentInAssembly.Visible = ConstantValue;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseOrderSupplyWithAssignment, ConstantValue);
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseGoodsQualityControl" Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseGoodsQualityControl;
		Items.UseGoodsQualityResearch.Visible = Not (GetFunctionalOption(
			"TradeManagement") Or GetFunctionalOption("ComplexAutomation"));
		Items.UseGoodsQualityResearch.Enabled = ConstantValue;
		UseItemResearch = ConstantsSet.UseGoodsQualityResearch;
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseGoodsQualityResearch, UseItemResearch);
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseGoodsQualityControl, ConstantValue);
		
	EndIf;
	If DataPathAttribute = "ConstantsSet.UseGoodsQualityResearch" Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseGoodsQualityResearch;
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseGoodsQualityResearch, ConstantValue);
		
	EndIf;
	If DataPathAttribute = "ConstantsSet.UseSeveralWarehouses" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseSeveralWarehouses;
		
		If ConstantValue Then
			Items.TheWarehousesPageGroup.CurrentPage = Items.GroupExplanationMultipleWarehouses;
		Else
			Items.TheWarehousesPageGroup.CurrentPage = Items.GroupExplanationASingleWarehouse;
		EndIf;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseSeveralWarehouses, ConstantValue);
		
		Items.UseGoodsTransfer.Enabled 					= ConstantValue;
		Items.TransferGoodsOfOtherCompanies.Enabled 					= ConstantsSet.UseGoodsTransfer;
		Items.UseTransferOrders.Enabled 					= ConstantsSet.UseGoodsTransfer;
		Items.UseNonConformanceCertificatesFollowingTransfer.Enabled 		= ConstantsSet.UseGoodsTransfer;
		Items.UseGoodsTransferStatuses.Enabled 				= ConstantsSet.UseGoodsTransfer;
		Items.UseTransferAgainstSeveralOrders.Enabled 		= ConstantsSet.UseTransferOrders;
		Items.OptionOfGoodslAssignmentInTransfer.Enabled 				= ConstantsSet.UseTransferOrders;
		Items.DoNotCloseTransferOrdersWithoutCompleteShipment.Enabled 	= ConstantsSet.UseTransferOrders;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseWarehouseManagementSystem" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseWarehouseManagementSystem;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseWarehouseManagementSystem, ConstantValue);
		Items.UsePackingLists.Enabled = ConstantValue;
		
		UseItemsBatch = Constants.UseItemsBatch.Get();
		Items.GroupCommentSeriesInAdvancedWarehouse.Visible = Not ConstantValue And UseItemsBatch;
		
		Items.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Enabled = ConstantValue;
		Items.GoodsIssueNoteGenerationMode.Enabled = ConstantValue;
		Items.OrderOfMRMKScanning.Enabled = ConstantValue;
		
		UsedGoodsInTransit               = Constants.UseGoodsInTransitFromVendors.Get();
		UnfacturedDeliveriesAreUsed = Constants.UseUninvoicedDeliveries.Get();
		UseDeliveryManagement       = Constants.UseDeliveryManagement.Get();
		UsePurchaseOrders         = Constants.UsePurchaseOrders.Get();
		
		Items.ExecutionOfAnOrder.Enabled = ConstantValue
			Or UsedGoodsInTransit
			Or UnfacturedDeliveriesAreUsed
			Or (UseDeliveryManagement
				And UsePurchaseOrders);
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseDeliveryManagement" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseDeliveryManagement;
		
		UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
		DisplayWarning = ConstantValue
								 And UsedDelivery25;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseDeliveryManagement, DisplayWarning);
			
		Items.EditDeliveryAddressesOnlyInDialogBox.Enabled		             = ConstantValue;
		Items.LabelTemplateForDelivery.Enabled 						             = ConstantValue;
		Items.DeliveryPlanning.Enabled 						             = ConstantValue;
		Items.UseTransportationJobsForDeliveryAccountingByCarriers.Enabled = ConstantValue;
		
		If UsedDelivery25 Then
			
			Items.UseTransportationJobsForDeliveryAccountingByCarriers.Visible = False;
			Items.LabelTemplateForDelivery.Visible = False;
			
		EndIf;
		
		PropertySetParameters = PropertyManager.PropertySetParametersStructure();
		PropertySetParameters.Used = ConstantValue;
		PropertyManager.SetPropertySetParameters("Document_InstructionForShippingAgent", PropertySetParameters);
		
		UseWarehouseManagementSystem            = Constants.UseWarehouseManagementSystem.Get();
		UsedGoodsInTransit               = Constants.UseGoodsInTransitFromVendors.Get();
		UnfacturedDeliveriesAreUsed = Constants.UseUninvoicedDeliveries.Get();
		UsePurchaseOrders         = Constants.UsePurchaseOrders.Get();
		
		Items.ExecutionOfAnOrder.Enabled = UseWarehouseManagementSystem
			Or UsedGoodsInTransit
			Or UnfacturedDeliveriesAreUsed
			Or (ConstantValue
				And UsePurchaseOrders);
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTransportationJobsForDeliveryAccountingByCarriers" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseTransportationJobsForDeliveryAccountingByCarriers;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseTransportationJobsForDeliveryAccountingByCarriers, ConstantValue);
	EndIf;
	
	#Region InventoryConsumption
	
	If DataPathAttribute = "ConstantsSet.UseInventoryConsumption"
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseInventoryConsumption;
		Orders            = ConstantsSet.UseInventoryConsumptionOrders;
		OrderStatuses    = ConstantsSet.UseStatusesOfInventoryConsumptionOrders;
		UseOrderMatching = ConstantsSet.UseApprovalOfInventoryConsumptionOrders;
		
		Items.UseInventoryConsumptionOrders.Enabled                 = ConstantValue;
		Items.UseInventoryConsumptionForMultipleOrders.Enabled      = Orders;
		Items.UseStatusesOfInventoryConsumptionOrders.Enabled         = Orders;
		Items.OptionOfGoodsAssignmentInInventoryConsumption.Enabled          = Orders And ConstantsSet.GenerateFinancialResult;
		Items.DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment.Enabled = ConstantValue And OrderStatuses And Orders;
		Items.UseCoordinationOfDomesticConsumptionOrders.Enabled = ConstantValue And OrderStatuses And Orders;
		Items.AppointThoseResponsibleForApprovingOrdersForDomesticConsumption.Enabled = UseOrderMatching;
		
		EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseInventoryConsumptionOrders" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseInventoryConsumptionOrders;
		UseOrderMatching = ConstantsSet.UseApprovalOfInventoryConsumptionOrders;
		OrderStatuses = ConstantsSet.UseStatusesOfInventoryConsumptionOrders;
		
		Items.UseInventoryConsumptionForMultipleOrders.Enabled      = ConstantValue;
		Items.OptionOfGoodsAssignmentInInventoryConsumption.Enabled          = ConstantValue And ConstantsSet.GenerateFinancialResult;
		Items.DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment.Enabled = ConstantValue And OrderStatuses;
		Items.UseStatusesOfInventoryConsumptionOrders.Enabled         = ConstantValue;
		Items.UseCoordinationOfDomesticConsumptionOrders.Enabled     = ConstantValue And OrderStatuses;
		Items.AppointThoseResponsibleForApprovingOrdersForDomesticConsumption.Enabled = UseOrderMatching;
		
		Items.TheGroupCommentsNotToClosePartiallyShippedOrdersForDomesticConsumption.Visible = ConstantValue And Not OrderStatuses;
		
		EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseStatusesOfInventoryConsumptionOrders" Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseStatusesOfInventoryConsumptionOrders;
		ValueOfParentConstant = ConstantsSet.UseInventoryConsumptionOrders;
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseStatusesOfInventoryConsumptionOrders, ConstantValue);
		Items.DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment.Enabled = ConstantValue And ValueOfParentConstant;
		
		Items.UseCoordinationOfDomesticConsumptionOrders.Enabled    = ConstantValue;
		Items.AppointThoseResponsibleForApprovingOrdersForDomesticConsumption.Enabled = ConstantsSet.UseApprovalOfInventoryConsumptionOrders;
		
		Items.TheGroupCommentsNotToClosePartiallyShippedOrdersForDomesticConsumption.Visible = Not ConstantValue And ValueOfParentConstant;
		
		EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseApprovalOfInventoryConsumptionOrders"
		Or DataPathAttribute = "" Then
			
		ConstantValue = ConstantsSet.UseApprovalOfInventoryConsumptionOrders;

		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseCoordinationOfDomesticConsumptionOrders, ConstantValue);
		
		Items.AppointThoseResponsibleForApprovingOrdersForDomesticConsumption.Enabled = ConstantValue;
		EstablishAvailabilityOfVersioningOrdersForDOMESTICCONSUMPTION();

	EndIf;
	
	#EndRegion
	
	#Region Move
	
	If DataPathAttribute = "ConstantsSet.UseGoodsTransfer" Or DataPathAttribute = "" Then
		ConstantValue               = ConstantsSet.UseGoodsTransfer;
		TransfersBetweenOrganizations      = Constants.UseCustomerInvoiceIntercompany.Get();
		Orders                          = ConstantsSet.UseTransferOrders;
		OrderStatuses                  = ConstantsSet.UseStatusesOfTransferOrders;
		
		Items.UseTransferOrders.Enabled             = ConstantValue;
		Items.UseGoodsTransferStatuses.Enabled       = ConstantValue;
		Items.UseNonConformanceCertificatesFollowingTransfer.Enabled = ConstantValue;
		Items.UseTransferAgainstSeveralOrders.Enabled  = Orders;
		Items.OptionOfGoodslAssignmentInTransfer.Enabled       = Orders;
		
		Items.TransferGoodsOfOtherCompanies.Enabled 				  = ConstantValue And TransfersBetweenOrganizations;
		Items.GroupCommentMoveProductsFromOtherOrganizations.Visible =	Not TransfersBetweenOrganizations;
		Items.UseStatusesOfTransferOrders.Enabled          = Orders;
		Items.DoNotCloseTransferOrdersWithoutCompleteShipment.Enabled = ConstantValue And Orders And OrderStatuses;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseTransferOrders" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseTransferOrders;
		OrderStatuses                  = ConstantsSet.UseStatusesOfTransferOrders;
		
		Items.UseTransferAgainstSeveralOrders.Enabled      = ConstantValue;
		Items.OptionOfGoodslAssignmentInTransfer.Enabled           = ConstantValue;
		Items.UseStatusesOfTransferOrders.Enabled         = ConstantValue;
		Items.DoNotCloseTransferOrdersWithoutCompleteShipment.Enabled = ConstantValue And OrderStatuses;
		
		Items.GroupCommentDoNotClosePartiallyShippedTransferOrders.Visible = ConstantValue And Not OrderStatuses;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseStatusesOfTransferOrders" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseStatusesOfTransferOrders;
		ValueOfParentConstant = ConstantsSet.UseTransferOrders;
		Items.DoNotCloseTransferOrdersWithoutCompleteShipment.Enabled = ConstantValue And ValueOfParentConstant;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseStatusesOfTransferOrders, ConstantValue);
		
		Items.GroupCommentDoNotClosePartiallyShippedTransferOrders.Visible = Not ConstantValue And ValueOfParentConstant;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseGoodsTransferStatuses"
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseGoodsTransferStatuses;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseGoodsTransferStatuses, ConstantValue);
			
	EndIf;
	
	#EndRegion
	
	#Region AssemblyDisassembly
	
	If DataPathAttribute = "ConstantsSet.UseAssemblyDisassembly" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseAssemblyDisassembly;
		Orders            = ConstantsSet.UseAssemblyDisassemblyOrders;
		OrderStatuses    = ConstantsSet.UseStatusesOfAssemblyOrders;
		
		Items.UseAssemblyDisassemblyOrders.Enabled                 = ConstantValue;
		Items.UseGoodsAssemblyStatuses.Enabled           = ConstantValue;
		Items.OptionOfGoodsAssignmentInAssembly.Enabled           = Orders;
		Items.UseStatusesOfAssemblyOrders.Enabled         = Orders;
		Items.DoNotCloseAssemblyOrdersWithoutCompleteShipment.Enabled = ConstantValue And OrderStatuses And Orders;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseAssemblyDisassemblyOrders" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UseAssemblyDisassemblyOrders;
		OrderStatuses    = ConstantsSet.UseStatusesOfAssemblyOrders;
		
		Items.OptionOfGoodsAssignmentInAssembly.Enabled           = ConstantValue;
		Items.UseStatusesOfAssemblyOrders.Enabled         = ConstantValue;
		Items.DoNotCloseAssemblyOrdersWithoutCompleteShipment.Enabled = ConstantValue And OrderStatuses;
		
		Items.GroupReviewIsNotToCloseAPartiallyShippedOrdersForAssemblyAndDisassembly.Visible = ConstantValue And Not OrderStatuses;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseStatusesOfAssemblyOrders" Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseStatusesOfAssemblyOrders;
		ValueOfParentConstant = ConstantsSet.UseAssemblyDisassemblyOrders;
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseStatusesOfAssemblyOrders, ConstantValue);
		Items.DoNotCloseAssemblyOrdersWithoutCompleteShipment.Enabled = ConstantValue And ValueOfParentConstant;
		
		Items.GroupReviewIsNotToCloseAPartiallyShippedOrdersForAssemblyAndDisassembly.Visible = Not ConstantValue And ValueOfParentConstant;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseGoodsAssemblyStatuses" Or DataPathAttribute = "" Then
		
		ConstantValue = Constants.UseGoodsAssemblyStatuses.Get();
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseGoodsAssemblyStatuses, ConstantValue);
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseOrderSupplyWithAssignment"
		Or DataPathAttribute = "ConstantsSet.OptionOfGoodsAssignmentInAssembly" Or DataPathAttribute = "" Then
		
		Items.GroupCommentSeparationOfComponentsAccordingToThePurposeOfTheAssembledSet.Visible = ConstantsSet.UseOrderSupplyWithAssignment
			And ConstantsSet.OptionOfGoodsAssignmentInAssembly = PredefinedValue("Enum.OptionsOfGoodsAssignmentInAssembly.AssignmentOfAssembledKit");
		
	EndIf;
	
	#EndRegion
	
	If DataPathAttribute = "ConstantsSet.UsePackingLists" Or DataPathAttribute = "" Then
		ConstantValue = ConstantsSet.UsePackingLists;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UsePackingLists, ConstantValue);
		Items.PackingListLabelTemplate.Enabled = ConstantValue;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UsePurchaseOrders"
		Or DataPathAttribute = "ConstantsSet.UseTransferOrders"
		Or DataPathAttribute = "ConstantsSet.UseAssemblyDisassemblyOrders"
		Or DataPathAttribute = "ConstantsSet.UseProduction"
		Or DataPathAttribute = "" Then

		SetAvailabilityFormationOfOrdersByNeeds();

	EndIf;
	
	If DataPathAttribute = "GenerationOfOrdersByDemands"
		Or DataPathAttribute = "ConstantsSet.UseSeveralWarehouses"
		Or DataPathAttribute = "ConstantsSet.UseGoodsTransfer"
		Or DataPathAttribute = "ConstantsSet.UseTransferOrders"
		Or DataPathAttribute = "" Then
		
		Items.RCGroup.Enabled = ConstantsSet.UseAdvancedDemandFulfillment
			And (ConstantsSet.UseTransferOrders Or ConstantsSet.UseProduction);
		
		DistributionCenterFulfillmentOption = ?(Items.RCGroup.Enabled, ConstantsSet.OptimizeDistributionCenterInventory, 2);
		
		ThereAreOrdersOfMaterials = False;
		ThereAreOrdersOfMaterials = ConstantsSet.UseMaterialOrdersForShopFloorStockroom;
 		Items.GroupCommentProvidingRC.Visible = ConstantsSet.UseAdvancedDemandFulfillment
			And Not (ConstantsSet.UseTransferOrders Or ThereAreOrdersOfMaterials);
		
	EndIf;
	
	SetVisibilityOfTransitionElementsToDelivery25();
	SetDeliveryControlPromptText();
	EstablishAvailabilityOfChangesInOrderOfExecutionOfInvoicesAndOrders();
	
	SystemSettingsLocalization.SetAvailability_WarehouseAndDelivery(DataPathAttribute, ThisObject);
	DataExchangeTMERP.SetAvailabilityOfInformationBaseNodeSettings(ThisForm);
	WarningOnEditRepresentation(DataPathAttribute);
	
EndProcedure

&AtServer
Procedure WarningOnEditRepresentation(DataPathAttribute)
	
	StructureOfConstants = New Structure(
		"UseGoodsTransferStatuses,
		|UseGoodsAssemblyStatuses,
		|AllowAssignmentOfGoodsBeyondDemand");
	
	For Each KeyAndValue In StructureOfConstants Do
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items[KeyAndValue.Key],
			ConstantsSet[KeyAndValue.Key]);
	EndDo;
	
EndProcedure

&AtClient
Procedure GoodsIssueNoteGenerationModeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenForm("Enum.GoodsIssueNoteGenerationModes.Form.SelectGenerationMode",
				New Structure("GoodsIssueNoteGenerationMode", ConstantsSet.GoodsIssueNoteGenerationMode),
				Item,
				,
				,
				,
				,
				FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure UseNonConformanceCertificatesFollowingTransferOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtServer
Procedure SetAvailabilityFormationOfOrdersByNeeds()

	Items.GroupCreatingOrdersBasedOnNeeds.Visible = True;
	
	If Not DataProcessors.DemandFulfillment.FormationOfSupportingDocumentsIsUsed() Then
		
		Items.GroupCreatingOrdersBasedOnNeeds.Enabled = False;
		
		Items.TheCommentGroupCanBeUsedToGenerateOrdersBasedOnNeeds.Visible = True;
		Items.CommentAdvancedOrderGenerationBasedOnNeeds.Visible = True;
		Items.CommentSimplifiedOrderGenerationBasedOnNeeds.Visible  = False;
		
		GenerationOfOrdersByDemands = 2;
		
	ElsIf Not ConstantsSet.UsePurchaseOrders Then
		
		Items.GroupCreatingOrdersBasedOnNeeds.Enabled = True;
		Items.GroupCreatingOrdersBasedOnNeedsSimplified.Enabled = False;
		Items.FormationOfOrdersForTheNeedsOfTheExtended.Enabled = False;
		
		Items.TheCommentGroupCanBeUsedToGenerateOrdersBasedOnNeeds.Visible = True;
		Items.CommentAdvancedOrderGenerationBasedOnNeeds.Visible = False;
		Items.CommentSimplifiedOrderGenerationBasedOnNeeds.Visible  = True;
		
		GenerationOfOrdersByDemands = 1;
		
	Else
		
		Items.GroupCreatingOrdersBasedOnNeeds.Enabled = True;
		
		Items.TheCommentGroupCanBeUsedToGenerateOrdersBasedOnNeeds.Visible = False;
		
		GenerationOfOrdersByDemands = GetFunctionalOption("UseAdvancedDemandFulfillment");
		
	EndIf;

EndProcedure
&AtServer
Procedure SetHeadingsAndToolTipsForUp()
	
	Items.CommentAdvancedOrderGenerationBasedOnNeeds.Title = 
		NStr("vi = 'Chức năng này khả dụng, nếu sử dụng quản lý sản xuất (phân hệ ""Danh mục và quản trị"" - ""Sản xuất"")
		|hoặc cho phép sử dụng ít nhất một trong các dạng văn bản sau:
		|- Đơn hàng đặt nhà cung cấp (phân hệ ""Danh mục và quản trị"" - ""Mua hàng"")
		|- Đơn hàng đóng bộ (phân hệ ""Danh mục và quản trị"" - ""Kho bãi và giao nhận"")
		|- Đơn hàng điều chuyển nội bộ (phân hệ ""Danh mục và quản trị"" - ""Kho bãi và giao nhận"")
		|- Đơn hàng đặt gia công (phân hệ ""Danh mục và quản trị"" - ""Sản xuất"")';
		|ru = 'Этот функционал доступен, если используется управление производством (раздел ""НСИ и администрирование"" — ""Производство"")
		|или разрешено использование хотя бы одного из следующих видов документов:
		|– Заказы поставщикам (раздел ""НСИ и администрирование"" — ""Закупки"")
		|– Заказы на сборку (раздел ""НСИ и администрирование"" — ""Склад и доставка"")
		|– Заказы на перемещение (раздел ""НСИ и администрирование"" — ""Склад и доставка"")
		|– Заказы переработчику (раздел ""НСИ и администрирование"" — ""Производство"")';
		|en = 'This functionality is available if production management is used (""Master data and settings — Production"" section)
		|or if using at least one of the following document kinds is allowed:
		|– Purchase orders (""Master data and settings — Purchases"" section)
		|– Kitting orders (""Master data and settings — Warehouse and delivery"" section)
		|– Transfer orders (""Master data and settings — Warehouse and delivery"" section)
		|– Subcontracting purchase orders (""Master data and settings — Production"" section)'; fa = 'This functionality is available if production management is used (""Master data and settings — Production"" section)
		|or if using at least one of the following document kinds is allowed:
		|– Purchase orders (""Master data and settings — Purchases"" section)
		|– Kitting orders (""Master data and settings — Warehouse and delivery"" section)
		|– Transfer orders (""Master data and settings — Warehouse and delivery"" section)
		|– Subcontracting purchase orders (""Master data and settings — Production"" section)';
		|it = 'Questa funzionalità è disponibile se viene utilizzata la gestione della produzione (sezione ""Informazione normativa di riferimento e amministrazione"" - ""Produzione"")
		|oppure è consentito l''utilizzo di almeno uno dei seguenti tipi di documenti:
		|- Ordini ai fornitori (sezione ""Informazione normativa di riferimento e amministrazione"" - ""Acquisti"")
		|- Ordini di assemblaggio (sezione ""Informazione normativa di riferimento e amministrazione"" - ""Magazzino e consegna"")
		|- Ordini di trasferimento (sezione ""Informazione normativa di riferimento e amministrazione"" - ""Magazzino e consegna"")
		|- Ordini all''elaboratore (sezione ""Informazione normativa di riferimento e amministrazione"" - ""Produzione"")';
		|pl = 'Ta funkcja jest dostępna, jeśli używane jest zarządzanie produkcją (sekcja ""Ustawienia"" — ""Produkcja"")
		|lub co najmniej jeden z następujących rodzajów dokumentów:
		|- Zamówienia dostawcom (rozdział ""Ustawienia"" — ""Zakup"")
		| — Zamówienia na montaż (rozdział ""Ustawienia"" — ""Magazyn i dostawa"")
		| — Zamówienia na przesunięcie (rozdział ""Ustawienia"" — ""Magazyn i dostawa"")
		|— Zamówienia przetwórcy (rozdział ""Ustawienia"" — ""Produkcja"")';
		|tr = 'Bu işlevsellik, üretim yönetimi kullanılıyorsa kullanılabilir (""Master veri ve yönetim"" - ""Üretim"" bölümü)
		|veya aşağıdaki belge türlerinden en az birinin kullanımına izin verilir:
		|– Satın alma siparişleri (""Master veri ve yönetim"" — ""Satın almalar"" bölümü )
		|– Montaj emirleri (""Master veri ve yönetim"" — ""Ambar ve teslimat"" bölümü)
		|— Transfer emirleri (""Master veri ve yönetim"" — ""Ambar ve teslimat"" bölümü)
		|— Fason satın alma siparişi (""Master veri ve yönetim"" — ""Üretim"" bölümü)'");
	
EndProcedure
&AtClient
Procedure UseTransportationJobsForDeliveryAccountingByCarriersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtServer
Procedure DisableMonitoringOfGoodsReservesOnOrdersServer()
	
	SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders = Not SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders;
	
	UpdateLabelOfDisableMonitoringOfItemReservesForOrdersButton(SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
	
	If SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders Then
		MessageText = NStr("vi = 'Người dùng %UserName% trong khuôn khổ phiên của mình, đã tắt kiểm soát dự phòng theo đơn hàng.';
							|ru = 'Пользователем %UserName% в рамках своего сеанса выключен контроль резервов по заказам.';
							|en = 'Control of reserves under orders is disabled by the %UserName% user during their session.'; fa = 'Control of reserves under orders is disabled by the %UserName% user during their session.';
							|it = 'Пользователем %UserName% в рамках своего сеанса выключен контроль резервов по заказам.';
							|pl = 'Control of reserves under orders is disabled by the %UserName% user during their session.';
							|tr = '%UserName% kullanıcısı, oturumu kapsamında sipariş rezervi kontrolünü devre dışı bıraktı.'",
			Common.DefaultLanguageCode());
	Else
		MessageText = NStr("vi = 'Đã khôi phục kiểm soát dự phòng theo đơn hàng bởi người sử dụng %UserName%.';
							|ru = 'Пользователем %UserName% возобновлен контроль резервов по заказам.';
							|en = 'Control of reserves under orders is resumed by the %UserName% user.'; fa = 'Control of reserves under orders is resumed by the %UserName% user.';
							|it = 'Пользователем %UserName% возобновлен контроль резервов по заказам.';
							|pl = 'Control of reserves under orders is resumed by the %UserName% user.';
							|tr = '%UserName% kullanıcısı, sipariş rezervi kontrolüne yeniden başladı.'",
			Common.DefaultLanguageCode());
	EndIf;
	MessageText = StrReplace(MessageText, "%UserName%", Users.CurrentUser());
	
	WriteLogEvent(ProvisionInDocumentsServer.EventNameMonitoringOfItemReservesForOrdersIsDisabled(),
		EventLogLevel.Warning, , , MessageText);
	
EndProcedure

&AtServer
Procedure UpdateLabelOfDisableMonitoringOfItemReservesForOrdersButton(ControlDisabled)
	
	If ControlDisabled Then
		Items.DisableMonitoringOfGoodsReservesOnOrders.Title = NStr("vi = 'Khôi phục kiểm soát dự phòng';
																	|ru = 'Возобновить контроль резервов';
																	|en = 'Resume reserve control'; fa = 'Resume reserve control';
																	|it = 'Возобновить контроль резервов';
																	|pl = 'Resume reserve control';
																	|tr = 'Rezerv kontrolünü yeniden yürüt'");
		Items.DisableMonitoringOfGoodsReservesOnOrders.ExtendedTooltip.Title
			= NStr("vi = 'Khôi phục quyền kiểm soát dự phòng hàng hóa theo các đơn hàng đối với người sử dụng hiện tại mà đã tắt sử dụng trong suốt thời gian của phiên.';
					|ru = 'Восстановление контроля резервов товаров по заказам для текущего пользователя, ранее выключенных на время сеанса.';
					|en = 'Resume the control of reserves under orders previously disabled for the session time for the current user.'; fa = 'Resume the control of reserves under orders previously disabled for the session time for the current user.';
					|it = 'Восстановление контроля резервов товаров по заказам для текущего пользователя, ранее выключенных на время сеанса.';
					|pl = 'Resume the control of reserves under orders previously disabled for the session time for the current user.';
					|tr = 'Oturum süresince daha önce devre dışı bırakılan mevcut kullanıcı için siparişlere göre ürün rezervleri üzerindeki kontrolün yeniden sağlanması.'");
	Else
		Items.DisableMonitoringOfGoodsReservesOnOrders.Title = NStr("vi = 'Ngắt kiểm soát dự phòng (vào thời gian của phiên)';
																	|ru = 'Отключить контроль резервов (на время сеанса)';
																	|en = 'Disable reserve control (for the session time)'; fa = 'غیرفعال کردن کنترل رزرو (برای مدت جلسه)';
																	|it = 'Отключить контроль резервов (на время сеанса)';
																	|pl = 'Disable reserve control (for the session time)';
																	|tr = 'Rezerv kontrolünü devre dışı bırak (oturum süresince)'");
		Items.DisableMonitoringOfGoodsReservesOnOrders.ExtendedTooltip.Title
			= NStr("vi = 'Tắt quyền kiểm soát hàng hóa trong doanh nghiệp đối với người sử dụng hiện tại trong phiên làm việc. Có thể thiết lập trong ""Danh mục và quản trị"" - ""Tùy chỉnh cá nhân"".';
					|ru = 'Выключение контроля резервов товаров по заказам для текущего пользователя на время сеанса работы. Возможность также доступна в ""НСИ и администрирование"" - ""Персональные настройки"".';
					|en = 'Disable the control of reserves under orders for the current user for the operation session time. The feature is also available in ""Master data and settings"" — ""Personal settings"".'; fa = 'Disable the control of reserves under orders for the current user for the operation session time. The feature is also available in ""Master data and settings"" — ""Personal settings"".';
					|it = 'Выключение контроля резервов товаров по заказам для текущего пользователя на время сеанса работы. Возможность также доступна в ""НСИ и администрирование"" - ""Персональные настройки"".';
					|pl = 'Disable the control of reserves under orders for the current user for the operation session time. The feature is also available in ""Master data and settings"" — ""Personal settings"".';
					|tr = 'Oturum süresince mevcut kullanıcı için siparişlere göre ürün rezervlerinin kontrolünün devre dışı bırakılması. Bu seçenek ""Master veri ve yönetim""; ""Kişisel ayarlar"" bölümünde de mevcuttur.'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StatusOfTransitionToDelivery25()
	
	StatusData = DeliveryTransitionStatusData25();
	StatusData.Insert("TransitionIsRunning", False);
	StatusData.Insert("DataProcessed", False);
	StatusData.Insert("TransitionIsComplete", False);
	
	TransitionStatus = GoodsDelivery.StatusOfTransitionToDelivery25();
	FillPropertyValues(StatusData, TransitionStatus);
	
	Return StatusData;
	
EndFunction

&AtClientAtServerNoContext
Function DeliveryTransitionStatusData25()
	
	StatusData = New Structure;
	StatusData.Insert("TransitionIsRunning", False);
	StatusData.Insert("DataProcessed", False);
	StatusData.Insert("TransitionIsComplete", False);
	
	Return StatusData;
	
EndFunction

&AtServer
Procedure SetVisibilityOfTransitionElementsToDelivery25(Val UsedDelivery25 = Undefined, Val TransitionStatus = Undefined)
	
	UsedDelivery = ConstantsSet.UseDeliveryManagement;
	If UsedDelivery25 = Undefined Then
		
		UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
		
	EndIf;
	
	GroupVisibility = UsedDelivery And (Not UsedDelivery25);
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GroupDeliveryManagement25",
		"Visible",
		GroupVisibility);
	
	If GroupVisibility Then
		
		If TransitionStatus = Undefined Then
			
			TransitionStatus = StatusOfTransitionToDelivery25();
			
		EndIf;
		
		DisplayStartupCommands = Not TransitionStatus.TransitionIsRunning;
		DisplayStatusCommand = TransitionStatus.TransitionIsRunning And (Not TransitionStatus.DataProcessed);
		DisplayEndCommands = TransitionStatus.DataProcessed;
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"GoToDelivery25",
			"Visible",
			DisplayStartupCommands);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"CheckStateOfTransitionToDelivery25",
			"Visible",
			DisplayStatusCommand);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"CompleteTransitionToDelivery25",
			"Visible",
			DisplayEndCommands);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishAvailabilityOfChangesInOrderOfExecutionOfInvoicesAndOrders()
	
	ChangeIsAvailable = ChangesInOrderOfExecutionOfInvoicesAndOrdersAreAvailable(
		ConstantsSet.ProcedureOfInvoiceAndGoodsIssueNoteRegistration);
	
	Items.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Enabled = ChangeIsAvailable;
	Items.GroupCommentProcedureForIssuingSpendingOrders.Visible = Not ChangeIsAvailable;
	
EndProcedure

&AtServerNoContext
Procedure CompleteTransitionToDelivery25AtServer()
	
	GoodsDelivery.CompleteTransitionToDelivery25();
	
EndProcedure

&AtServer
Procedure SetDeliveryControlPromptText()
	
	ToolTipText20 = NStr("vi = 'Tính năng chỉ ra các mục tin giao nhận, sử dụng khu vực giao nhận, tạo nhiệm vụ vận chuyển.';
						|ru = 'Возможность указывать реквизиты доставки, использовать зоны доставки, формировать задания на перевозку.';
						|en = 'Select to enable delivery details, delivery zones, and create itineraries.'; fa = 'برای فعال‌سازی جزئیات تحویل، مناطق تحویل و ایجاد مسیرها انتخاب کنید.';
						|it = 'Possibilità di specificare i requisiti di consegna, utilizzare le zone di consegna, creare processi di trasporto.';
						|pl = 'Możliwość wskazania atrybutów dostawy, używania strefy dostawy, tworzenia zadań przewozu.';
						|tr = 'Teslimat özniteliklerini belirleme, teslimat bölgelerini kullanma, taşıma planı oluşturma imkanı.'");
	ToolTipText25 = NStr("vi = 'Có thể lập kế hoạch giao nhận trong các chứng từ, lập chuyển hàng.';
						|ru = 'Возможность планировать доставку в документах, формировать рейсы.';
						|en = 'Allows you to plan delivery in documents, create trips.'; fa = 'Allows you to plan delivery in documents, create trips.';
						|it = 'Allows you to plan delivery in documents, create trips.';
						|pl = 'Allows you to plan delivery in documents, create trips.';
						|tr = 'Belgelerde teslimatı planlama ve seferleri oluşturma imkanı.'");
	
	UsedDelivery = GoodsDeliveryClientServer.UsedDelivery();
	
	If UsedDelivery Then
		
		If GoodsDeliveryClientServer.UsedDelivery20() Then
			
			ToolTipText = ToolTipText20;
			
		Else
			
			ToolTipText = ToolTipText25;
			
		EndIf;
		
	ElsIf GoodsDelivery.Delivery25WasUsed() Then
		
		ToolTipText = ToolTipText25;
		
	Else
		
		ToolTipText = ToolTipText20;
		
	EndIf;
	
	Items.UseDeliveryManagement.ExtendedTooltip.Title = ToolTipText;
	
EndProcedure

&AtServerNoContext
Function ConnectionsInformation()
	
	Information = IBConnections.ConnectionsInformation();
	Return Information;
	
EndFunction

&AtServerNoContext
Function ChangesInOrderOfExecutionOfInvoicesAndOrdersAreAvailable(Val RegistrationProcedure)
	
	UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
	BlockSettings =
		(UsedDelivery25
			And RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst
			And GoodsDelivery.ThereAreWarehousesWithKitsForPostDelivery());
	
	Return Not BlockSettings;
	
EndFunction

#EndRegion

#EndRegion
